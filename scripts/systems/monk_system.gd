extends RefCounted

const MonkData=preload("res://scripts/data/monk_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values() or str(unit.get("selected_heroic_id",""))==id
static func owner_id(unit:Dictionary)->String:return str(unit.get("combat_id","monk"))
static func successful(result:Dictionary)->bool:return float(result.get("resolved_damage",result.get("health_damage",0.0)))>0.0 and not bool(result.get("evaded",false)) and not bool(result.get("immune",false))
static func telemetry_default()->Dictionary:
	var result:={}
	for key in ["dash_casts","ally_dashes","enemy_dashes","breath_triggering_dashes","breath_unavailable_dashes","reach_triggering_dashes","reach_unavailable_dashes","dash_attacks","q_spent","q_restored","epiphany_procs","third_hits","transcendence_healing","iron_damage","insight_progress","insight_complete","insight_cdr_events","cooldown_reduced","fists_half_effects","ally_casts","ally_destroyed","spirit_healing","earth_recipients","air_recipients","ally_dashes_to_own","breath_casts","breath_healing","heavenly_bonus","cleanses","stuns_removed","roots_removed","breath_armor","protected_applications","echo_healing","storm_shields","palm_casts","palm_triggers","palm_expired","seven_casts","seven_strikes","seven_normal_damage","seven_boss_damage","reach_activations","reach_attacks","controlled_damage","hundred_strikes"]:result[key]=0.0
	return result
static func telemetry_add(unit:Dictionary,key:String,value=1.0)->void:
	var rt:Dictionary=unit.get("monk_runtime",{});if rt.is_empty() or not bool(rt.get("telemetry_enabled",false)):return
	rt.telemetry[key]=float(rt.telemetry.get(key,0.0))+float(value)

static func q_max(unit:Dictionary)->int:return int(MonkData.VALUES.blinding_charges if has_talent(unit,"monk_l18_1") else MonkData.VALUES.q_charges)
static func q_recharge(unit:Dictionary)->float:return float(MonkData.VALUES.blinding_recharge if has_talent(unit,"monk_l18_1") else MonkData.VALUES.q_recharge)
static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,encounter_id:String="")->void:
	unit["monk_runtime"]={"encounter_id":encounter_id,"q_slot":AbilitySlotSystem.create(q_max(unit),q_recharge(unit),AbilitySlotSystem.RechargeMode.SEQUENTIAL),"breath_cooldown":0.0,"reach_cooldown":0.0,"reach_remaining":0.0,"third_counter":0,"insight_progress":0,"insight_complete":false,"trait_speed_remaining":0.0,"ally":{},"ally_cooldown":0.0,"ally_tick":1.0,"ally_aura_recipients":[],"echoes":[],"palm":{},"seven":{},"storm_icd":0.0,"epiphany_icd":0.0,"latest_dash":"","latest_dash_target_id":"","telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit["base_basic_action_interval"]=float(MonkData.VALUES.basic_attack_interval);unit["basic_attack_interval"]=float(MonkData.VALUES.basic_attack_interval);unit["range"]=float(MonkData.SPACE.basic_range)

static func q_state(unit:Dictionary)->Dictionary:return AbilitySlotSystem.ui_state(unit.monk_runtime.q_slot)
static func ally_kind(unit:Dictionary)->String:
	if has_talent(unit,"monk_l12_1"):return "spirit"
	if has_talent(unit,"monk_l12_2"):return "earth"
	if has_talent(unit,"monk_l12_3"):return "air"
	return ""
static func is_major_companion(target:Dictionary)->bool:return bool(target.get("permanent_companion",false)) and bool(target.get("ordinary_heal_eligible",false))
static func valid_ally_anchor(unit:Dictionary,target:Dictionary)->bool:
	if target.is_empty() or float(target.get("hp",0.0))<=0.0:return false
	if target==unit or str(target.get("combat_id",""))==str(unit.get("combat_id","")):return false
	if str(target.get("monk_ally_owner_id",""))==owner_id(unit):return true
	if bool(target.get("summoned_unit",false)):return is_major_companion(target)
	return str(target.get("combat_affiliation",target.get("combat_team","")))==str(unit.get("combat_affiliation",unit.get("combat_team","player")))
static func valid_enemy_anchor(unit:Dictionary,target:Dictionary)->bool:
	return not target.is_empty() and float(target.get("hp",0.0))>0.0 and str(target.get("combat_affiliation",target.get("combat_team","")))!=str(unit.get("combat_affiliation",unit.get("combat_team","player"))) and not ("training" in target.get("combat_tags",[]) and not bool(target.get("passive_test_enemy",false)))
static func valid_palm_target(unit:Dictionary,target:Dictionary)->bool:
	if target.is_empty() or float(target.get("hp",0.0))<=0.0:return false
	if bool(target.get("summoned_unit",false)) and not is_major_companion(target):return false
	return target==unit or str(target.get("combat_affiliation",target.get("combat_team","player")))==str(unit.get("combat_affiliation",unit.get("combat_team","player")))

static func spend_dash(unit:Dictionary,target:Dictionary)->Dictionary:
	var allied:=valid_ally_anchor(unit,target);var enemy:=valid_enemy_anchor(unit,target)
	if not allied and not enemy or not AbilitySlotSystem.spend(unit.monk_runtime.q_slot,float(MonkData.VALUES.q_intercast)):return {"cast":false}
	telemetry_add(unit,"dash_casts");telemetry_add(unit,"q_spent");unit.monk_runtime.latest_dash="ally" if allied else "enemy";unit.monk_runtime.latest_dash_target_id=str(target.get("combat_id",""));telemetry_add(unit,"ally_dashes" if allied else "enemy_dashes")
	var epiphany:=false
	if int(unit.monk_runtime.q_slot.current_charges)==0 and has_talent(unit,"monk_l30_3") and float(unit.monk_runtime.epiphany_icd)<=0.0:
		unit.monk_runtime.q_slot.current_charges=int(unit.monk_runtime.q_slot.max_charges);unit.monk_runtime.q_slot.timers=[];unit.monk_runtime.epiphany_icd=float(MonkData.VALUES.epiphany_icd);epiphany=true;telemetry_add(unit,"epiphany_procs");telemetry_add(unit,"q_restored",int(unit.monk_runtime.q_slot.max_charges))
	return {"cast":true,"allied":allied,"enemy":enemy,"epiphany":epiphany}

static func activate_reach(unit:Dictionary)->bool:
	if float(unit.monk_runtime.reach_cooldown)>0.0:return false
	unit.monk_runtime.reach_cooldown=float(MonkData.VALUES.deadly_cooldown);unit.monk_runtime.reach_remaining=float(MonkData.VALUES.deadly_duration)*(float(MonkData.VALUES.blazing_duration_multiplier) if has_talent(unit,"monk_l18_3") else 1.0);telemetry_add(unit,"reach_activations");return true
static func reach_active(unit:Dictionary)->bool:return float(unit.get("monk_runtime",{}).get("reach_remaining",0.0))>0.0
static func controlled_multiplier(unit:Dictionary,target:Dictionary)->float:
	return 1.0+float(MonkData.VALUES.controlled_bonus) if has_talent(unit,"monk_l21_3") and reach_active(unit) and (StatusEffectSystem.has_control(target,"stun") or StatusEffectSystem.has_control(target,"root")) else 1.0

static func create_ally(unit:Dictionary,kind:String,point:Vector2)->Dictionary:
	var base_hp:=float({"spirit":MonkData.VALUES.spirit_health,"earth":MonkData.VALUES.earth_health,"air":MonkData.VALUES.air_health}[kind]);var maximum:=MonkData.scaled(base_hp,int(unit.get("level",1)));var id:="%s:%s_ally"%[owner_id(unit),kind]
	return {"combat_id":id,"owner_id":owner_id(unit),"monk_ally_owner_id":owner_id(unit),"source_id":"monk_%s_ally"%kind,"source":"monk_%s_ally"%kind,"team":"player","combat_team":"player","combat_affiliation":"player","target_category":"temporary_combat","combat_tags":["summon","monk_ally",kind],"summoned_unit":true,"temporary_combat":true,"ordinary_heal_eligible":false,"radiant_dash_anchor":true,"ally_kind":kind,"hp":maximum,"max_hp":maximum,"remaining_duration":float(MonkData.VALUES.ally_duration),"combat_radius":float(MonkData.SPACE.ally_radius),"active_effects":[],"shield":0.0,"shield_sources":[],"temporary_armor_sources":[],"pos":point}
static func cast_ally(unit:Dictionary,point:Vector2)->Dictionary:
	var kind:=ally_kind(unit);if kind=="" or float(unit.monk_runtime.ally_cooldown)>0.0:return {"cast":false}
	unit.monk_runtime.ally=create_ally(unit,kind,point);unit.monk_runtime.ally_cooldown=float(MonkData.VALUES.ally_cooldown);unit.monk_runtime.ally_tick=1.0;telemetry_add(unit,"ally_casts");return {"cast":true,"ally":unit.monk_runtime.ally}

static func reduce_basic_cooldowns(unit:Dictionary,seconds:float)->float:
	var total:=AbilitySlotSystem.reduce_active_recharge(unit.monk_runtime.q_slot,seconds);var before:=float(unit.monk_runtime.breath_cooldown);unit.monk_runtime.breath_cooldown=maxf(0.0,before-seconds);total+=before-float(unit.monk_runtime.breath_cooldown);before=float(unit.monk_runtime.reach_cooldown);unit.monk_runtime.reach_cooldown=maxf(0.0,before-seconds);total+=before-float(unit.monk_runtime.reach_cooldown);telemetry_add(unit,"insight_cdr_events");telemetry_add(unit,"cooldown_reduced",total);return total
static func note_basic_attack(unit:Dictionary,result:Dictionary)->Dictionary:
	if not successful(result):return {"triggered":false}
	unit.monk_runtime.third_counter=(int(unit.monk_runtime.third_counter)+1)%3
	if int(unit.monk_runtime.third_counter)!=0:return {"triggered":false}
	telemetry_add(unit,"third_hits");unit.monk_runtime.trait_speed_remaining=float(MonkData.VALUES.trait_speed_duration)
	var selected:=str(unit.get("selected_talents",{}).get("tier_1",""));var fists:=has_talent(unit,"monk_l30_1");var heal_fraction:=1.0 if selected=="monk_l9_1" else .5 if fists else 0.0;var damage_fraction:=1.0 if selected=="monk_l9_2" else .5 if fists else 0.0;var cdr:=0.0;var insight_was_complete:=bool(unit.monk_runtime.insight_complete)
	if selected=="monk_l9_3":
		if not bool(unit.monk_runtime.insight_complete):unit.monk_runtime.insight_progress=mini(int(MonkData.VALUES.insight_goal),int(unit.monk_runtime.insight_progress)+1);telemetry_add(unit,"insight_progress");if int(unit.monk_runtime.insight_progress)>=int(MonkData.VALUES.insight_goal):unit.monk_runtime.insight_complete=true;telemetry_add(unit,"insight_complete")
		if insight_was_complete:cdr=float(MonkData.VALUES.insight_cdr)
	elif fists:cdr=float(MonkData.VALUES.insight_cdr)*.5
	if cdr>0.0:reduce_basic_cooldowns(unit,cdr)
	if fists:telemetry_add(unit,"fists_half_effects")
	if has_talent(unit,"monk_l18_3"):unit.monk_runtime.reach_cooldown=maxf(0.0,float(unit.monk_runtime.reach_cooldown)-float(MonkData.VALUES.blazing_cdr))
	return {"triggered":true,"healing":MonkData.scaled(float(MonkData.VALUES.trait_heal),int(unit.level))*heal_fraction,"bonus_damage":float(result.get("raw_amount",result.get("resolved_damage",0.0)))*float(MonkData.VALUES.trait_bonus)*damage_fraction,"cdr":cdr}

static func start_palm(unit:Dictionary,target:Dictionary)->bool:
	if str(unit.get("selected_heroic_id",""))!="monk_l15_r1" or float(unit.ability_cds[3])>0.0 or not valid_palm_target(unit,target):return false
	unit.ability_cds[3]=float(MonkData.VALUES.palm_cooldown);unit.monk_runtime.palm={"target_id":str(target.combat_id),"remaining":float(MonkData.VALUES.palm_duration)};telemetry_add(unit,"palm_casts");return true
static func palm_heal(unit:Dictionary)->float:return MonkData.scaled(float(MonkData.VALUES.palm_heal),int(unit.level))*(float(MonkData.VALUES.peaceful_multiplier) if has_talent(unit,"monk_l27_r1") else 1.0)
static func consume_palm_for(unit:Dictionary,target_id:String)->float:
	if str(unit.get("monk_runtime",{}).get("palm",{}).get("target_id",""))!=target_id or float(unit.monk_runtime.palm.get("remaining",0.0))<=0.0:return 0.0
	unit.monk_runtime.palm={};telemetry_add(unit,"palm_triggers");return palm_heal(unit)
static func start_seven(unit:Dictionary)->bool:
	if str(unit.get("selected_heroic_id",""))!="monk_l15_r2" or float(unit.ability_cds[3])>0.0:return false
	var count:=int(MonkData.VALUES.seven_strikes)+(int(MonkData.VALUES.transgression_strikes) if has_talent(unit,"monk_l27_r2") else 0);unit.ability_cds[3]=float(MonkData.VALUES.seven_cooldown);unit.monk_runtime.seven={"remaining":float(MonkData.VALUES.seven_duration),"tick":0.0,"strikes_left":count,"strike_number":0,"target_id":""};telemetry_add(unit,"seven_casts");return true

static func advance(unit:Dictionary,delta:float)->void:
	var rt:Dictionary=unit.monk_runtime;AbilitySlotSystem.update(rt.q_slot,delta);rt.breath_cooldown=maxf(0.0,float(rt.breath_cooldown)-delta);rt.reach_cooldown=maxf(0.0,float(rt.reach_cooldown)-delta);rt.reach_remaining=maxf(0.0,float(rt.reach_remaining)-delta);rt.trait_speed_remaining=maxf(0.0,float(rt.trait_speed_remaining)-delta);rt.ally_cooldown=maxf(0.0,float(rt.ally_cooldown)-delta);rt.storm_icd=maxf(0.0,float(rt.storm_icd)-delta);rt.epiphany_icd=maxf(0.0,float(rt.epiphany_icd)-delta)
	if not rt.palm.is_empty():rt.palm.remaining=maxf(0.0,float(rt.palm.remaining)-delta);if float(rt.palm.remaining)<=0.0:rt.palm={};telemetry_add(unit,"palm_expired");if has_talent(unit,"monk_l27_r1"):unit.ability_cds[3]=minf(float(unit.ability_cds[3]),float(MonkData.VALUES.peaceful_failed_cooldown))
	if not rt.ally.is_empty():rt.ally.remaining_duration=maxf(0.0,float(rt.ally.remaining_duration)-delta);if float(rt.ally.get("hp",0.0))<=0.0 or float(rt.ally.remaining_duration)<=0.0:rt.ally={};rt.ally_aura_recipients=[];telemetry_add(unit,"ally_destroyed")
static func reset_encounter(unit:Dictionary,new_encounter_id:String="")->void:initialize_runtime(unit,bool(unit.get("monk_runtime",{}).get("telemetry_enabled",false)),new_encounter_id)
