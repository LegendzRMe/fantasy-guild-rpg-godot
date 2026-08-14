extends RefCounted

const WarriorData=preload("res://scripts/data/warrior_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")
const ProgressionScopeSystem=preload("res://scripts/systems/progression_scope_system.gd")
const HealingReceivedModifierSystem=preload("res://scripts/systems/healing_received_modifier_system.gd")
const ArmorEffectivenessSystem=preload("res://scripts/systems/armor_effectiveness_system.gd")
const SummonLifetimeSystem=preload("res://scripts/systems/summon_lifetime_system.gd")
const QuestProgressModifierSystem=preload("res://scripts/systems/quest_progress_modifier_system.gd")
const CombatBalanceData=preload("res://scripts/data/combat_balance_data.gd")
const CombatSystem=preload("res://scripts/systems/combat_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float)->float:return WarriorData.scaled(value,int(unit.get("level",1)))
static func successful(result:Dictionary)->bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0
static func specialization(unit:Dictionary)->String:return str(unit.get("selected_heroic_id",""))
static func effective_role(unit:Dictionary)->String:return "Tank" if specialization(unit)=="warrior_l12_r1" else "Melee DPS"

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["basic_attempts","basic_hits","basic_damage","crits","heroic_strikes","heroic_strike_damage","heroic_strike_cdr","twin_cdr","twin_move_time","q_casts","q_contacts","q_damage","q_healing","q_boss_healing","q_summon_healing","lions_maw_progress","endurance_events","w_casts","w_charges","basic_attacks_prevented","parry_prevented","overpower_triggers","protected_prevented","vigilance_reductions","e_enemy_casts","e_ally_casts","e_damage","e_slows","anti_summon_hits","weapon_progress","honors_progress","endurance_progress","high_objectives","high_completed","shared_progress","taunt_casts","taunt_uptime","boss_taunts","colossus_casts","colossus_damage","colossus_armor","twin_attacks","second_wind_triggers","second_wind_healing","victory_triggers","victory_healing","victory_death_cdr","summon_percent_damage","summon_lifetime_removed","mortal_applications","shattering_casts","shield_damage","shields_broken","banner_activations","banner_ally_seconds","stormwind_uptime","ironforge_armor","dalaran_uptime","demoralizing_applications"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	var shield_wall:=has_talent(unit,"warrior_l18_1")
	unit["warrior_runtime"]={
		"heroic_strike_cooldown":float(WarriorData.VALUES.heroic_strike_cooldown),"overpower_armed":false,"parry_remaining":0.0,
		"w_slot":AbilitySlotSystem.create(int(WarriorData.VALUES.shield_wall_charges if shield_wall else WarriorData.VALUES.w_charges),float(WarriorData.VALUES.shield_wall_recharge if shield_wall else WarriorData.VALUES.w_recharge)),
		"taunt_cooldown":0.0,"current_taunt_target":"","twin_move_remaining":0.0,"victory_cooldown":float(WarriorData.VALUES.victory_cooldown),
		"shattering_cooldown":0.0,"banner_remaining":0.0,"banner_cooldown":0.0,"banner_type":"","banner_activation_serial":0,
		"lions_maw":0,"damage_participation":{},"recent_second_wind":0.0,"recent_summon_lifetime_before":-1.0,"recent_summon_lifetime_after":-1.0,
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	ProgressionScopeSystem.begin_encounter(unit.warrior_runtime,encounter_id if encounter_id!="" else ProgressionScopeSystem.new_encounter_id("warrior"))
	apply_specialization(unit)

static func telemetry_add(unit:Dictionary,key:String,value=1.0)->void:
	var runtime:Dictionary=unit.get("warrior_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=float(runtime.telemetry.get(key,0.0))+float(value)

static func apply_specialization(unit:Dictionary)->void:
	var spec:=specialization(unit);var runtime:Dictionary=unit.get("warrior_runtime",{})
	unit["effective_role"]=effective_role(unit);unit["threat_modifier"]=float(CombatBalanceData.TANK_THREAT_MODIFIER) if spec=="warrior_l12_r1" else 1.0
	unit["positive_armor_effectiveness_sources"]=unit.get("positive_armor_effectiveness_sources",[]).filter(func(source):return str(source.get("source_id",""))!="warrior_taunt_specialization")
	HealingReceivedModifierSystem.remove(unit,"warrior_taunt_specialization")
	if spec=="warrior_l12_r1":
		unit.positive_armor_effectiveness_sources=[{"source_id":"warrior_taunt_specialization","amount":float(WarriorData.VALUES.taunt_armor_effectiveness),"remaining":INF}]
		HealingReceivedModifierSystem.apply(unit,"warrior_taunt_specialization",float(WarriorData.VALUES.taunt_healing_received),INF,str(unit.get("combat_id","")))
	var base_max_health:=float(unit.get("warrior_base_max_hp",unit.get("max_hp",1.0)));unit["warrior_base_max_hp"]=base_max_health;var ratio:=float(unit.get("hp",0.0))/maxf(1.0,float(unit.get("max_hp",1.0)));unit.max_hp=base_max_health*(float(WarriorData.VALUES.colossus_health) if spec=="warrior_l12_r2" else 1.0);unit.hp=minf(float(unit.max_hp),float(unit.max_hp)*ratio);runtime["colossus_health_applied"]=spec=="warrior_l12_r2"
	unit["basic_attack_interval"]=attack_interval(unit);unit["damage"]=basic_attack_amount(unit);unit["basic_action_amount"]=unit.damage

static func attack_interval(unit:Dictionary)->float:
	var base:=float(unit.get("base_basic_action_interval",WarriorData.VALUES.basic_attack_interval));return base/(1.0+float(WarriorData.VALUES.twin_speed)) if specialization(unit)=="warrior_l12_r3" else base
static func high_progress(unit:Dictionary,key:String)->int:return int(unit.get("warrior_runtime",{}).get("encounter_progress",{}).get(key,0))
static func high_completed_count(unit:Dictionary)->int:
	var count:=0
	if high_progress(unit,"high_weapon")>=int(WarriorData.VALUES.high_weapon_goal):count+=1
	if high_progress(unit,"high_honors")>=int(WarriorData.VALUES.high_honors_goal):count+=1
	if high_progress(unit,"high_endurance")>=int(WarriorData.VALUES.high_endurance_goal):count+=1
	return count
static func high_reward_level_one(unit:Dictionary)->float:
	if not has_talent(unit,"warrior_l9_3"):return 0.0
	var completed:=high_completed_count(unit);return completed*float(WarriorData.VALUES.high_objective_reward)+(float(WarriorData.VALUES.high_final_reward) if completed==3 else 0.0)
static func basic_attack_amount(unit:Dictionary)->float:
	var amount:=scaled(unit,float(WarriorData.VALUES.basic_attack_damage)+high_reward_level_one(unit))
	if specialization(unit)=="warrior_l12_r2":amount*=float(WarriorData.VALUES.colossus_basic)
	elif specialization(unit)=="warrior_l12_r3":amount*=float(WarriorData.VALUES.twin_basic)
	return amount
static func heroic_strike_damage(unit:Dictionary)->float:
	var multiplier:=1.0
	if bool(unit.get("warrior_runtime",{}).get("overpower_armed",false)):multiplier+=float(WarriorData.VALUES.overpower_bonus)
	if has_talent(unit,"warrior_l27_r3"):multiplier+=float(WarriorData.VALUES.frenzy_damage)
	return scaled(unit,float(WarriorData.VALUES.heroic_strike_damage))*multiplier

static func add_progress(unit:Dictionary,key:String,amount:int=1)->int:
	var applied:=QuestProgressModifierSystem.amount(unit,amount);var value:=ProgressionScopeSystem.add_encounter_progress(unit.warrior_runtime,key,applied)
	if applied>amount:telemetry_add(unit,"shared_progress",applied-amount)
	telemetry_add(unit,{"high_weapon":"weapon_progress","high_honors":"honors_progress","high_endurance":"endurance_progress","lions_maw":"lions_maw_progress"}.get(key,key),applied)
	return value

static func note_primary_basic_attack(unit:Dictionary,target:Dictionary,result:Dictionary,heroic_was_ready:bool)->Dictionary:
	telemetry_add(unit,"basic_attempts");if not successful(result):return {"successful":false,"heroic_strike":false,"victory":false}
	telemetry_add(unit,"basic_hits");telemetry_add(unit,"basic_damage",float(result.resolved_damage));if bool(result.get("critical",false)):telemetry_add(unit,"crits")
	var runtime:Dictionary=unit.warrior_runtime;var output:={"successful":true,"heroic_strike":heroic_was_ready,"heroic_damage":0.0,"second_wind":0.0,"victory":false,"victory_heal":0.0}
	if heroic_was_ready:
		output.heroic_damage=heroic_strike_damage(unit);runtime.heroic_strike_cooldown=float(WarriorData.VALUES.heroic_strike_cooldown);runtime.overpower_armed=false;telemetry_add(unit,"heroic_strikes")
		if has_talent(unit,"warrior_l15_2"):output.second_wind=float(unit.max_hp)*float(WarriorData.VALUES.second_wind);telemetry_add(unit,"second_wind_triggers")
	var cdr:=float(WarriorData.VALUES.twin_cdr if specialization(unit)=="warrior_l12_r3" else WarriorData.VALUES.heroic_strike_cdr)
	runtime.heroic_strike_cooldown=maxf(0.0,float(runtime.heroic_strike_cooldown)-cdr);telemetry_add(unit,"twin_cdr" if specialization(unit)=="warrior_l12_r3" else "heroic_strike_cdr",cdr)
	if specialization(unit)=="warrior_l12_r3":runtime.twin_move_remaining=float(WarriorData.VALUES.twin_move_duration);telemetry_add(unit,"twin_attacks")
	if has_talent(unit,"warrior_l15_3") and float(runtime.victory_cooldown)<=0.0:output.victory=true;output.victory_heal=scaled(unit,float(WarriorData.VALUES.victory_heal));runtime.victory_cooldown=float(WarriorData.VALUES.victory_cooldown);telemetry_add(unit,"victory_triggers")
	if has_talent(unit,"warrior_l9_3") and TargetCategorySystem.qualifies_quest(target):add_progress(unit,"high_weapon",1)
	return output

static func note_parry_contact(unit:Dictionary)->Dictionary:
	var runtime:Dictionary=unit.get("warrior_runtime",{});if runtime.is_empty():return {"prevented":false}
	var active:=float(runtime.parry_remaining)>0.0
	if active:telemetry_add(unit,"basic_attacks_prevented");if has_talent(unit,"warrior_l9_2"):runtime.heroic_strike_cooldown=0.0;runtime.overpower_armed=true;telemetry_add(unit,"overpower_triggers")
	if has_talent(unit,"warrior_l27_r1"):var reduced:=minf(float(runtime.taunt_cooldown),float(WarriorData.VALUES.vigilance_cdr));runtime.taunt_cooldown=maxf(0.0,float(runtime.taunt_cooldown)-reduced);telemetry_add(unit,"vigilance_reductions",reduced)
	return {"prevented":active,"shield_wall":active and has_talent(unit,"warrior_l18_1")}

static func cast_parry(unit:Dictionary)->bool:
	var runtime:Dictionary=unit.warrior_runtime;if not AbilitySlotSystem.can_activate(runtime.w_slot):return false
	AbilitySlotSystem.spend(runtime.w_slot);runtime.parry_remaining=float(WarriorData.VALUES.w_duration);telemetry_add(unit,"w_casts");telemetry_add(unit,"w_charges")
	if has_talent(unit,"warrior_l18_1"):unit.active_effects=unit.get("active_effects",[]).filter(func(effect):return str(effect.get("id",""))!="warrior_shield_wall");unit.active_effects.append({"id":"protected","source_id":"warrior_shield_wall","owner_id":str(unit.get("combat_id","")),"remaining_duration":float(WarriorData.VALUES.w_duration)})
	return true

static func lions_fang_plan(unit:Dictionary,targets:Array)->Dictionary:
	var unique:Dictionary={};var quest_contacts:=0;var healing:=0.0;var boss_healing:=0.0;var summon_healing:=0.0
	for target in targets:
		var id:=str(target.get("combat_id",""));if unique.has(id):continue
		unique[id]=true;var category:=TargetCategorySystem.category(target)
		if TargetCategorySystem.qualifies_quest(target) and quest_contacts<5:quest_contacts+=1
		if category=="boss":var amount:=scaled(unit,float(WarriorData.VALUES.q_boss_heal))*float(WarriorData.VALUES.lionheart_boss if has_talent(unit,"warrior_l15_1") else 1.0);healing+=amount;boss_healing+=amount
		elif TargetCategorySystem.qualifies_quest(target):healing+=scaled(unit,float(WarriorData.VALUES.q_heal))
		elif category=="summon" and has_talent(unit,"warrior_l15_1"):var amount:=scaled(unit,float(WarriorData.VALUES.q_heal));healing+=amount;summon_healing+=amount
	var damage:=scaled(unit,float(WarriorData.VALUES.q_damage)+minf(float(WarriorData.VALUES.lions_maw_cap),float(unit.warrior_runtime.lions_maw)*float(WarriorData.VALUES.lions_maw_per)))
	return {"damage":damage,"healing":healing,"boss_healing":boss_healing,"summon_healing":summon_healing,"quest_contacts":quest_contacts,"slow":float(WarriorData.VALUES.lions_maw_slow if int(unit.warrior_runtime.lions_maw)>=int(WarriorData.VALUES.lions_maw_goal) else WarriorData.VALUES.q_slow),"slow_duration":float(WarriorData.VALUES.lions_maw_duration if int(unit.warrior_runtime.lions_maw)>=int(WarriorData.VALUES.lions_maw_goal) else WarriorData.VALUES.q_slow_duration)}
static func note_lions_fang_cast(unit:Dictionary,plan:Dictionary)->void:
	telemetry_add(unit,"q_casts");telemetry_add(unit,"q_contacts",int(plan.quest_contacts));telemetry_add(unit,"q_boss_healing",float(plan.boss_healing));telemetry_add(unit,"q_summon_healing",float(plan.summon_healing))
	if has_talent(unit,"warrior_l9_1"):unit.warrior_runtime.lions_maw=mini(int(WarriorData.VALUES.lions_maw_goal),int(unit.warrior_runtime.lions_maw)+QuestProgressModifierSystem.amount(unit,int(plan.quest_contacts)));telemetry_add(unit,"lions_maw_progress",int(plan.quest_contacts))
	if has_talent(unit,"warrior_l9_3") and float(plan.healing)>0.0:add_progress(unit,"high_endurance",1);telemetry_add(unit,"endurance_events")

static func note_damage_participation(unit:Dictionary,target:Dictionary,damage:float)->void:
	if damage>0.0:unit.warrior_runtime.damage_participation[str(target.get("combat_id",""))]=5.0
static func note_enemy_defeat(unit:Dictionary,target:Dictionary,distance:float)->void:
	var runtime:Dictionary=unit.warrior_runtime;var id:=str(target.get("combat_id",""))
	if has_talent(unit,"warrior_l9_3") and TargetCategorySystem.qualifies_quest(target) and float(runtime.damage_participation.get(id,0.0))>0.0:add_progress(unit,"high_honors",1)
	if has_talent(unit,"warrior_l15_3") and distance<=float(WarriorData.SPACE.victory_radius):var reduced:=minf(float(runtime.victory_cooldown),float(WarriorData.VALUES.victory_death_cdr));runtime.victory_cooldown=maxf(0.0,float(runtime.victory_cooldown)-reduced);telemetry_add(unit,"victory_death_cdr",reduced)
	runtime.damage_participation.erase(id)

static func anti_summon(unit:Dictionary,target:Dictionary)->Dictionary:
	if not has_talent(unit,"warrior_l21_1") or not SummonLifetimeSystem.is_summon(target) or TargetCategorySystem.category(target)=="boss":return {"damage":0.0,"removed":0.0,"despawned":false}
	var damage:=float(target.get("max_hp",0.0))*float(WarriorData.VALUES.summon_percent);var before:=SummonLifetimeSystem.remaining_lifetime(target);var lifetime:=SummonLifetimeSystem.reduce(target,float(WarriorData.VALUES.summon_lifetime));unit.warrior_runtime.recent_summon_lifetime_before=before;unit.warrior_runtime.recent_summon_lifetime_after=SummonLifetimeSystem.remaining_lifetime(target);telemetry_add(unit,"anti_summon_hits");telemetry_add(unit,"summon_percent_damage",damage);telemetry_add(unit,"summon_lifetime_removed",float(lifetime.removed));return {"damage":damage,"removed":float(lifetime.removed),"despawned":bool(lifetime.despawned)}

static func shield_only_damage(target:Dictionary,amount:float)->float:
	var applied:=minf(maxf(0.0,float(target.get("shield",0.0))),maxf(0.0,amount));if applied<=0.0:return 0.0
	CombatSystem._consume_shield_sources(target,applied);target.shield=maxf(0.0,float(target.shield)-applied);return applied

static func banner_type(unit:Dictionary)->String:
	if has_talent(unit,"warrior_l24_1"):return "stormwind"
	if has_talent(unit,"warrior_l24_2"):return "ironforge"
	if has_talent(unit,"warrior_l24_3"):return "dalaran"
	return ""
static func begin_banner(unit:Dictionary)->bool:
	var kind:=banner_type(unit);if kind=="":return false
	unit.warrior_runtime.banner_type=kind;unit.warrior_runtime.banner_remaining=float(WarriorData.VALUES.banner_duration);unit.warrior_runtime.banner_cooldown=float(WarriorData.VALUES.banner_cooldown);unit.warrior_runtime.banner_activation_serial=int(unit.warrior_runtime.banner_activation_serial)+1;telemetry_add(unit,"banner_activations");return true
static func in_banner(unit:Dictionary,ally:Dictionary)->bool:return float(unit.get("warrior_runtime",{}).get("banner_remaining",0.0))>0.0 and float(ally.get("hp",0.0))>0.0 and Vector2(unit.get("pos",Vector2.ZERO)).distance_to(Vector2(ally.get("pos",Vector2.ZERO)))<=float(WarriorData.SPACE.banner_radius)

static func update(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.get("warrior_runtime",{});if runtime.is_empty():return {"banner_activated":false}
	runtime.heroic_strike_cooldown=maxf(0.0,float(runtime.heroic_strike_cooldown)-delta);runtime.parry_remaining=maxf(0.0,float(runtime.parry_remaining)-delta);runtime.taunt_cooldown=maxf(0.0,float(runtime.taunt_cooldown)-delta);runtime.twin_move_remaining=maxf(0.0,float(runtime.twin_move_remaining)-delta);runtime.victory_cooldown=maxf(0.0,float(runtime.victory_cooldown)-delta);runtime.shattering_cooldown=maxf(0.0,float(runtime.shattering_cooldown)-delta)
	for id in runtime.damage_participation.keys():runtime.damage_participation[id]=float(runtime.damage_participation[id])-delta;if float(runtime.damage_participation[id])<=0.0:runtime.damage_participation.erase(id)
	AbilitySlotSystem.update(runtime.w_slot,delta);var activated:=false
	if banner_type(unit)!="":
		if float(runtime.banner_remaining)>0.0:runtime.banner_remaining=maxf(0.0,float(runtime.banner_remaining)-delta)
		runtime.banner_cooldown=maxf(0.0,float(runtime.banner_cooldown)-delta)
		if float(runtime.banner_cooldown)<=0.0 and float(unit.get("hp",0.0))>0.0:activated=begin_banner(unit)
	if float(runtime.twin_move_remaining)>0.0:telemetry_add(unit,"twin_move_time",delta)
	return {"banner_activated":activated}

static func reset_encounter(unit:Dictionary,new_encounter_id:String="")->void:
	var telemetry_enabled:=bool(unit.get("warrior_runtime",{}).get("telemetry_enabled",false));initialize_runtime(unit,telemetry_enabled,new_encounter_id)
