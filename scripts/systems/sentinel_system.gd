extends RefCounted

const SentinelData=preload("res://scripts/data/sentinel_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const ArmorReductionSystem=preload("res://scripts/systems/armor_reduction_system.gd")
const StealthDetectionSystem=preload("res://scripts/systems/stealth_detection_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func ability_amount(unit:Dictionary,value:float)->float:
	var expected:=maxf(.001,SentinelData.scaled(float(SentinelData.VALUES.basic_attack_damage),int(unit.get("level",1))))
	var result:=SentinelData.scaled(value,int(unit.get("level",1)))*maxf(0.0,float(unit.get("power",expected)))/expected
	for effect in unit.get("active_effects",[]):result*=1.0+float(effect.get("ability_power_bonus",0.0))/100.0
	return result
static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_hits","basic_damage","basic_threat","self_healing","q_casts","q_effective_healing","q_overhealing","q_recharge_reduction","w_casts","w_hits","w_damage","w_distance_bonus","w_death_resets","e_casts","e_hits","e_damage","e_quest_stacks","d_casts","d_self_healing","r1_casts","r1_healing","r2_casts","r2_damage","trueshot_casts"]:result[key]=0.0
	return result
static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	unit["sentinel_runtime"]={"q_slot":AbilitySlotSystem.create(2,float(SentinelData.VALUES.q_cooldown),AbilitySlotSystem.RechargeMode.FULL_REFILL),"w_slot":AbilitySlotSystem.create(2 if has_talent(unit,"sentinel_l30_1") else 1,w_cooldown(unit),AbilitySlotSystem.RechargeMode.INDEPENDENT),"d_cooldown":0.0,"trueshot_cooldown":0.0,"marked_target_id":"","mark_remaining":0.0,"w_projectiles":[],"w_reveals":{},"pending_flares":[],"starfalls":[],"shadowstalk":{},"e_quest_stacks":0,"e_recent_hits":{},"basic_counter":0,"overflow_bank":0.0,"elune_chosen":{"target_id":"","remaining":0.0,"cooldown":0.0},"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry(),"encounter_id":encounter_id}
static func telemetry_add(unit:Dictionary,key:String,value=1)->void:
	var runtime:Dictionary=unit.get("sentinel_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value
static func w_cooldown(unit:Dictionary)->float:return float(SentinelData.VALUES.w_cooldown)-(3.0 if has_talent(unit,"sentinel_l24_2") else 0.0)
static func q_ui(unit:Dictionary)->Dictionary:return AbilitySlotSystem.ui_state(unit.sentinel_runtime.q_slot)
static func mark_range(unit:Dictionary)->float:return float(SentinelData.SPACE.d_range)*(1.25 if has_talent(unit,"sentinel_l18_3") else 1.0)
static func mark_duration(unit:Dictionary)->float:return float(SentinelData.VALUES.d_duration)+(1.0 if has_talent(unit,"sentinel_l18_3") else 0.0)
static func e_range(unit:Dictionary)->float:return float(SentinelData.SPACE.e_range)*(1.30 if int(unit.get("sentinel_runtime",{}).get("e_quest_stacks",0))>=10 else 1.0)
static func e_multiplier(unit:Dictionary)->float:return 1.0+minf(float(SentinelData.VALUES.e_bonus_cap),float(unit.get("sentinel_runtime",{}).get("e_quest_stacks",0))*float(SentinelData.VALUES.e_stack_bonus))
static func select_lowest(allies:Array,origin:Vector2,max_range:float,exclude_id:String=""):
	var chosen=null;var best_ratio:=INF;var best_order:=999999;var best_id:=""
	for i in allies.size():
		var ally:Dictionary=allies[i];if ally.hp<=0.0 or str(ally.get("combat_id",""))==exclude_id or origin.distance_to(ally.pos)>max_range:continue
		var ratio:=float(ally.hp)/maxf(1.0,float(ally.max_hp));var cid:=str(ally.get("combat_id",""))
		if ratio<best_ratio or is_equal_approx(ratio,best_ratio) and (i<best_order or i==best_order and cid<best_id):chosen=ally;best_ratio=ratio;best_order=i;best_id=cid
	return chosen
static func spend_q(unit:Dictionary)->bool:return AbilitySlotSystem.spend(unit.sentinel_runtime.q_slot,float(SentinelData.VALUES.q_intercast))
static func reduce_q(unit:Dictionary,seconds:float)->float:
	var reduced:=AbilitySlotSystem.reduce_active_recharge(unit.sentinel_runtime.q_slot,seconds);telemetry_add(unit,"q_recharge_reduction",reduced);return reduced
static func apply_mark(unit:Dictionary,target:Dictionary,consume_cooldown:bool=true)->bool:
	var runtime:Dictionary=unit.sentinel_runtime
	if consume_cooldown and float(runtime.d_cooldown)>0.0:return false
	runtime.marked_target_id=str(target.combat_id);runtime.mark_remaining=mark_duration(unit);ArmorReductionSystem.apply(target,"sentinel_mark:%s"%str(unit.combat_id),float(SentinelData.VALUES.d_armor_reduction),runtime.mark_remaining);StealthDetectionSystem.reveal(target,runtime.mark_remaining)
	if consume_cooldown:runtime.d_cooldown=float(SentinelData.VALUES.d_cooldown);telemetry_add(unit,"d_casts")
	return true
static func note_basic_attack(unit:Dictionary,target:Dictionary,resolved_damage:float)->Dictionary:
	if resolved_damage<=0.0:return {"self_heal_fraction":0.0,"auto_flare":false}
	var runtime:Dictionary=unit.sentinel_runtime;runtime.basic_counter=int(runtime.basic_counter)+1;reduce_q(unit,float(SentinelData.VALUES.q_basic_cdr)+(0.5 if has_talent(unit,"sentinel_l9_2") else 0.0));telemetry_add(unit,"basic_hits");telemetry_add(unit,"basic_damage",resolved_damage)
	var own_mark:bool=str(runtime.marked_target_id)==str(target.combat_id) and float(runtime.mark_remaining)>0.0
	if has_talent(unit,"sentinel_l9_3"):runtime.d_cooldown=maxf(0.0,float(runtime.d_cooldown)-2.0);if own_mark:unit.ability_cds[2]=maxf(0.0,float(unit.ability_cds[2])-4.0)
	return {"self_heal_fraction":float(SentinelData.VALUES.d_marked_self_heal if own_mark else SentinelData.VALUES.d_self_heal),"own_mark":own_mark,"auto_flare":int(runtime.basic_counter)%8==0 and int(runtime.e_quest_stacks)>=40}
static func note_e_hit(unit:Dictionary,target:Dictionary,automatic:bool=false)->void:
	if automatic:return
	if TargetCategorySystem.qualifies_quest(target):unit.sentinel_runtime.e_quest_stacks=mini(84,int(unit.sentinel_runtime.e_quest_stacks)+1);unit.sentinel_runtime.e_recent_hits[str(target.combat_id)]=float(SentinelData.VALUES.e_death_window);telemetry_add(unit,"e_quest_stacks")
static func note_defeat(unit:Dictionary,target:Dictionary)->void:
	var id:=str(target.get("combat_id",""));if float(unit.get("sentinel_runtime",{}).get("e_recent_hits",{}).get(id,0.0))>0.0:unit.sentinel_runtime.e_quest_stacks=mini(84,int(unit.sentinel_runtime.e_quest_stacks)+1);telemetry_add(unit,"e_quest_stacks")
static func update(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.get("sentinel_runtime",{});if runtime.is_empty():return {}
	var before:=int(runtime.q_slot.current_charges);AbilitySlotSystem.update(runtime.q_slot,delta);AbilitySlotSystem.update(runtime.w_slot,delta);var refilled:bool=before<int(runtime.q_slot.max_charges) and int(runtime.q_slot.current_charges)==int(runtime.q_slot.max_charges)
	runtime.d_cooldown=maxf(0.0,float(runtime.d_cooldown)-delta);runtime.trueshot_cooldown=maxf(0.0,float(runtime.trueshot_cooldown)-delta);runtime.mark_remaining=maxf(0.0,float(runtime.mark_remaining)-delta)
	if float(runtime.mark_remaining)<=0.0:runtime.marked_target_id=""
	for id in runtime.e_recent_hits.keys():runtime.e_recent_hits[id]=float(runtime.e_recent_hits[id])-delta;if float(runtime.e_recent_hits[id])<=0.0:runtime.e_recent_hits.erase(id)
	unit.ability_cds[0]=float(AbilitySlotSystem.ui_state(runtime.q_slot).recharge);unit.ability_cds[1]=float(AbilitySlotSystem.ui_state(runtime.w_slot).recharge)
	unit.range=float(SentinelData.SPACE.basic_range)+(float(SentinelData.SPACE.source_to_world) if int(runtime.e_quest_stacks)>=40 else 0.0)
	return {"q_full_refill":refilled}
