extends RefCounted

const TemplarData=preload("res://scripts/data/templar_data.gd")
const ProgressionScopeSystem=preload("res://scripts/systems/progression_scope_system.gd")
const CombatTargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")
const QuestProgressModifierSystem=preload("res://scripts/systems/quest_progress_modifier_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func ability_amount(unit:Dictionary,value:float)->float:
	var expected:=maxf(0.001,TemplarData.scaled(float(TemplarData.VALUES.basic_attack_damage),int(unit.get("level",1))))
	return TemplarData.scaled(value,int(unit.get("level",1)))*maxf(0.0,float(unit.get("power",expected)))/expected

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_hits","q_casts","q_out_hits","q_return_hits","q_cooldown_reduced","w_casts","w_strikes","crosscut_strikes","e_casts","e_targets","e_depletions","linked_damage","linked_threat","trait_activations","trait_shield","trait_cdr","r1_casts","r1_hits","r2_casts","r2_ticks","protector_stacks","give_twenty_progress"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	unit["templar_runtime"]={"trait_cooldown":0.0,"trait_active":false,"trait_after_armor":0.0,"blade_dashes":[],"pending_w_strikes":[],"shield_links":[],"beams":[],"crosscut_remaining":0.0,"final_cut_remaining":0.0,"protector_stacks":0,"give_twenty_depletions":0,"give_twenty_bonus":0.0,"together_bucket":0.0,"r1_charges":2 if has_talent(unit,"templar_l27_r1") else 1,"r1_recharge":[],"r1_interuse":0.0,"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()}
	ProgressionScopeSystem.begin_encounter(unit.templar_runtime,encounter_id if encounter_id!="" else ProgressionScopeSystem.new_encounter_id("templar"))

static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("templar_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func q_contact_reduction(target:Dictionary)->float:
	return float(TemplarData.VALUES.q_priority_reduction if CombatTargetCategorySystem.category(target) in ["elite","named","boss","enemy_hero"] else TemplarData.VALUES.q_standard_reduction)

static func e_shield_amount(unit:Dictionary)->float:
	return ability_amount(unit,float(TemplarData.VALUES.e_shield))+minf(float(TemplarData.VALUES.give_twenty_cap),float(unit.get("templar_runtime",{}).get("give_twenty_bonus",0.0)))

static func e_cooldown(unit:Dictionary)->float:
	return float(TemplarData.VALUES.give_twenty_cooldown if has_talent(unit,"templar_l12_1") and int(unit.get("templar_runtime",{}).get("give_twenty_depletions",0))>=int(TemplarData.VALUES.give_twenty_goal) else TemplarData.VALUES.e_cooldown)

static func trait_cooldown_max(unit:Dictionary)->float:
	return maxf(1.0,float(TemplarData.VALUES.trait_cooldown)-(float(TemplarData.VALUES.shield_battery_cooldown_reduction) if has_talent(unit,"templar_l12_2") else 0.0))

static func trait_shield_amount(unit:Dictionary)->float:
	var amount:=ability_amount(unit,float(TemplarData.VALUES.trait_shield))
	if has_talent(unit,"templar_l12_3") and float(unit.get("hp",0.0))/maxf(1.0,float(unit.get("max_hp",1.0)))<0.25:amount*=1.0+float(TemplarData.VALUES.shield_surge_bonus)
	return amount

static func try_activate_trait_after_damage(unit:Dictionary,resolved_damage:float)->Dictionary:
	if resolved_damage<=0.0 or unit.get("templar_runtime",{}).is_empty() or float(unit.templar_runtime.trait_cooldown)>0.0:return {}
	if float(unit.get("hp",0.0))/maxf(1.0,float(unit.get("max_hp",1.0)))>=float(TemplarData.VALUES.trait_threshold):return {}
	unit.templar_runtime.trait_cooldown=trait_cooldown_max(unit);unit.templar_runtime.trait_active=true
	telemetry_add(unit,"trait_activations");return {"amount":trait_shield_amount(unit),"duration":float(TemplarData.VALUES.trait_duration),"source_id":"templar_shield_overload"}

static func reduce_trait_cooldown(unit:Dictionary,amount:float)->float:
	var before:=float(unit.templar_runtime.trait_cooldown);unit.templar_runtime.trait_cooldown=maxf(0.0,before-maxf(0.0,amount));var reduced:=before-float(unit.templar_runtime.trait_cooldown);telemetry_add(unit,"trait_cdr",reduced);return reduced

static func note_successful_basic_attack(unit:Dictionary,target:Dictionary,is_w_strike:bool=false)->void:
	reduce_trait_cooldown(unit,float(TemplarData.VALUES.trait_attack_reduction))
	if has_talent(unit,"templar_l9_3") and CombatTargetCategorySystem.qualifies_quest(target):var progress:=QuestProgressModifierSystem.amount(unit,1);unit.templar_runtime.protector_stacks=int(unit.templar_runtime.protector_stacks)+progress;telemetry_add(unit,"protector_stacks",progress)
	if has_talent(unit,"templar_l9_1") and is_w_strike:unit["templar_block"]={"charges":mini(int(TemplarData.VALUES.reactive_parry_charges),int(unit.get("templar_block",{}).get("charges",0))+1),"maximum":int(TemplarData.VALUES.reactive_parry_charges)}

static func basic_attack_multiplier(unit:Dictionary)->float:return 1.0+int(unit.get("templar_runtime",{}).get("protector_stacks",0))*float(TemplarData.VALUES.protector_per_hit)
static func titan_bonus(unit:Dictionary,is_w_strike:bool)->float:
	if not has_talent(unit,"templar_l24_1"):return 0.0
	var basis:=float(unit.get("max_hp",0.0));if bool(unit.get("templar_runtime",{}).get("trait_active",false)):basis+=named_shield_amount(unit,"templar_shield_overload")
	return basis*float(TemplarData.VALUES.titan_w if is_w_strike else TemplarData.VALUES.titan_normal)

static func named_shield_amount(unit:Dictionary,source_id:String)->float:
	var total:=0.0
	for source in unit.get("shield_sources",[]):if str(source.get("source_id",""))==source_id:total+=float(source.get("amount",0.0))
	return total

static func note_e_depletion(unit:Dictionary)->void:
	if not has_talent(unit,"templar_l12_1"):return
	unit.templar_runtime.give_twenty_depletions=int(unit.templar_runtime.give_twenty_depletions)+1;unit.templar_runtime.give_twenty_bonus=minf(float(TemplarData.VALUES.give_twenty_cap),float(unit.templar_runtime.give_twenty_bonus)+float(TemplarData.VALUES.give_twenty_increment));telemetry_add(unit,"e_depletions");telemetry_add(unit,"give_twenty_progress")

static func update(unit:Dictionary,delta:float,trait_shield_remaining:float)->void:
	var runtime:Dictionary=unit.get("templar_runtime",{});if runtime.is_empty():return
	var rate:=1.0+(float(TemplarData.VALUES.shield_battery_recharge_bonus) if has_talent(unit,"templar_l12_2") and trait_shield_remaining>0.0 else 0.0)
	runtime.trait_cooldown=maxf(0.0,float(runtime.trait_cooldown)-delta*rate);runtime.r1_interuse=maxf(0.0,float(runtime.r1_interuse)-delta);runtime.crosscut_remaining=maxf(0.0,float(runtime.crosscut_remaining)-delta);runtime.final_cut_remaining=maxf(0.0,float(runtime.final_cut_remaining)-delta)
	if trait_shield_remaining<=0.0 and bool(runtime.trait_active):runtime.trait_active=false;runtime.trait_after_armor=float(TemplarData.VALUES.phase_bulwark_after)
	runtime.trait_after_armor=maxf(0.0,float(runtime.trait_after_armor)-delta)
	for i in range(runtime.r1_recharge.size()-1,-1,-1):runtime.r1_recharge[i]=float(runtime.r1_recharge[i])-delta;if runtime.r1_recharge[i]<=0.0:runtime.r1_recharge.remove_at(i);runtime.r1_charges=mini(2,int(runtime.r1_charges)+1)
