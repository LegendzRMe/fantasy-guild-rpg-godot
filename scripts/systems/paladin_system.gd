extends RefCounted
const PaladinData=preload("res://scripts/data/paladin_data.gd")
const ChargedCastSystem=preload("res://scripts/systems/charged_cast_system.gd")
const HealingDoneModifierSystem=preload("res://scripts/systems/healing_done_modifier_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func telemetry_default()->Dictionary:
	var r:={};for key in ["q_starts","w_starts","e_starts","charge_releases","manual_cancels","interruptions","maximum_casts","partial_casts","divine_purpose_activations","d_empowered_casts","d_interruption_cdr","charge_time","basic_casts","self_healing","party_healing","armor_applications","cleanse_events","shield_applications","shield_amount","hammer_hits","w_stuns","avenging_hits","holy_avenger_procs","sacred_casts","sacred_ticks","sacred_damage","sacred_relocations","judgment_applications","holy_wrath_damage"]:r[key]=0.0
	return r
static func add(unit:Dictionary,key:String,amount:float=1.0)->void:
	if bool(unit.get("paladin_runtime",{}).get("telemetry_enabled",false)):unit.paladin_runtime.telemetry[key]=float(unit.paladin_runtime.telemetry.get(key,0.0))+amount
static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false)->void:
	unit["paladin_runtime"]={"charge":ChargedCastSystem.create(float(PaladinData.VALUES.charge_time)),"divine_purpose_primed":false,"hand_icd":0.0,"maraad_primed":false,"holy_wrath_primed":false,"velen_stacks":0,"velen_remaining":0.0,"ardent_remaining":0.0,"sacred":{},"sacred_tick":1.0,"beacon_icd":0.0,"judgments":{},"seraphim_remaining":0.0,"latest_cast":{},"dauntless_recipients":[],"telemetry_enabled":telemetry_enabled,"telemetry":telemetry_default()}
	unit["base_basic_action_interval"]=float(PaladinData.VALUES.basic_attack_interval);unit["basic_attack_interval"]=float(PaladinData.VALUES.basic_attack_interval);unit["range"]=float(PaladinData.SPACE.basic_range);unit["healing_done_sources"]=[]
static func vindication_radius(unit:Dictionary)->float:return float(PaladinData.SPACE.vindication_radius)*(1.0+float(PaladinData.VALUES.karabor_radius) if has_talent(unit,"paladin_l9_1") else 1.0)
static func charge_movement_multiplier(unit:Dictionary)->float:
	var passive:=float(PaladinData.VALUES.momentum_passive) if has_talent(unit,"paladin_l18_1") else 0.0
	if not bool(unit.get("paladin_runtime",{}).get("charge",{}).get("active",false)):return 1.0+passive
	if int(unit.paladin_runtime.charge.slot)==1 and has_talent(unit,"paladin_l18_1"):return 1.0+float(PaladinData.VALUES.momentum_w)
	return (1.0+passive)*(1.0-float(PaladinData.VALUES.charge_move_penalty))
static func start_charge(unit:Dictionary,slot:int,aim:Vector2,input_mode:String="release",device:String="pc")->bool:
	if slot not in [0,1,2] or float(unit.ability_cds[slot])>0.0:return false
	var instant:=bool(unit.paladin_runtime.divine_purpose_primed);var ok:=ChargedCastSystem.start(unit.paladin_runtime.charge,slot,aim,instant,input_mode,device)
	if ok:add(unit,["q_starts","w_starts","e_starts"][slot])
	return ok
static func commit_charge(unit:Dictionary)->Dictionary:
	var hallowed_started_inside:=bool(unit.paladin_runtime.charge.get("hallowed_started_inside",false))
	var result:=ChargedCastSystem.commit(unit.paladin_runtime.charge)
	if not bool(result.get("cast",false)):return result
	var slot:=int(result.slot);unit.ability_cds[slot]=float([PaladinData.VALUES.q_cooldown,PaladinData.VALUES.w_cooldown,PaladinData.VALUES.e_cooldown][slot]);result["divine_purpose"]=bool(unit.paladin_runtime.divine_purpose_primed);result["hallowed_started_inside"]=hallowed_started_inside
	if bool(result.divine_purpose):unit.paladin_runtime.divine_purpose_primed=false;add(unit,"d_empowered_casts")
	add(unit,"charge_releases");add(unit,"maximum_casts" if bool(result.maximum_charge) else "partial_casts");add(unit,"basic_casts");unit.paladin_runtime.latest_cast=result.duplicate(true);return result
static func manual_cancel(unit:Dictionary)->bool:
	var ok:=ChargedCastSystem.cancel(unit.paladin_runtime.charge)
	if ok:add(unit,"manual_cancels")
	return ok
static func external_interrupt(unit:Dictionary,reason:String)->bool:
	var ok:=ChargedCastSystem.interrupt(unit.paladin_runtime.charge,reason)
	if ok:unit.ability_cds[4]=maxf(0.0,float(unit.ability_cds[4])-float(PaladinData.VALUES.interrupt_d_cdr));add(unit,"interruptions");add(unit,"d_interruption_cdr",float(PaladinData.VALUES.interrupt_d_cdr))
	return ok
static func activate_divine_purpose(unit:Dictionary)->bool:
	if float(unit.ability_cds[4])>0.0:return false
	unit.ability_cds[4]=float(PaladinData.VALUES.d_cooldown);unit.paladin_runtime.divine_purpose_primed=true;add(unit,"divine_purpose_activations");return true
static func endpoint_value(minimum:float,maximum:float,maximum_charge:bool)->float:return maximum if maximum_charge else minimum
static func q_values(unit:Dictionary,maximum_charge:bool,enemy_hits:int)->Dictionary:
	var heal:=endpoint_value(float(PaladinData.VALUES.q_heal_min),float(PaladinData.VALUES.q_heal_max),maximum_charge)
	if has_talent(unit,"paladin_l9_1") and enemy_hits>0:heal*=1.0+float(PaladinData.VALUES.karabor_many if enemy_hits>1 else PaladinData.VALUES.karabor_one)
	return {"damage":PaladinData.scaled(endpoint_value(float(PaladinData.VALUES.q_damage_min),float(PaladinData.VALUES.q_damage_max),maximum_charge),int(unit.level)),"healing":PaladinData.scaled(heal,int(unit.level))}
static func w_values(unit:Dictionary,maximum_charge:bool,hit_count:int)->Dictionary:
	return {"damage":PaladinData.scaled(endpoint_value(float(PaladinData.VALUES.w_damage_min),float(PaladinData.VALUES.w_damage_max),maximum_charge),int(unit.level)),"knockback":endpoint_value(float(PaladinData.SPACE.hammer_knockback_min),float(PaladinData.SPACE.hammer_knockback_max),maximum_charge),"stun":float(PaladinData.VALUES.w_stun) if maximum_charge else 0.0,"armor_reduction":PaladinData.scaled(float(PaladinData.VALUES.verdict_per_hit)*mini(hit_count,int(PaladinData.VALUES.verdict_hit_cap)),int(unit.level)) if has_talent(unit,"paladin_l24_1") else 0.0}
static func e_values(unit:Dictionary,percentage:float,maximum_charge:bool,hit_count:int)->Dictionary:
	var distance:=lerpf(float(PaladinData.SPACE.avenging_min),float(PaladinData.SPACE.avenging_max),clampf(percentage,0.0,1.0));var damage:=PaladinData.scaled(float(PaladinData.VALUES.e_damage),int(unit.level));var holy:=maximum_charge and hit_count>0 and has_talent(unit,"paladin_l18_2");if holy:damage*=1.0+float(PaladinData.VALUES.holy_avenger_bonus)
	return {"range":distance,"damage":damage,"slow":float(PaladinData.VALUES.e_slow)+(float(PaladinData.VALUES.repentance_slow_bonus) if has_talent(unit,"paladin_l21_2") else 0.0),"slow_duration":float(PaladinData.VALUES.e_slow_duration)+(float(PaladinData.VALUES.repentance_duration_bonus) if has_talent(unit,"paladin_l21_2") else 0.0),"holy_avenger":holy}
static func after_basic_cast(unit:Dictionary,maximum_charge:bool,damaged_ids:Array)->Dictionary:
	if has_talent(unit,"paladin_l24_2"):unit.ability_cds[4]=maxf(0.0,float(unit.ability_cds[4])-float(PaladinData.VALUES.divine_favor_cdr))
	if has_talent(unit,"paladin_l9_3") and not damaged_ids.is_empty():unit.paladin_runtime.maraad_primed=true
	if has_talent(unit,"paladin_l24_3"):unit.paladin_runtime.holy_wrath_primed=true
	if maximum_charge and not damaged_ids.is_empty() and has_talent(unit,"paladin_l21_3"):unit.paladin_runtime.velen_stacks=mini(int(PaladinData.VALUES.velen_max),int(unit.paladin_runtime.velen_stacks)+1);unit.paladin_runtime.velen_remaining=float(PaladinData.VALUES.velen_duration);HealingDoneModifierSystem.apply(unit,"paladin_velen:%s"%str(unit.combat_id),float(unit.paladin_runtime.velen_stacks)*float(PaladinData.VALUES.velen_per_stack),float(PaladinData.VALUES.velen_duration))
	if maximum_charge and has_talent(unit,"paladin_l30_2"):for id in damaged_ids:unit.paladin_runtime.judgments[id]=float(PaladinData.VALUES.judgment_duration);add(unit,"judgment_applications",damaged_ids.size())
	return {"beacon":maximum_charge and has_talent(unit,"paladin_l30_1") and float(unit.paladin_runtime.beacon_icd)<=0.0,"dauntless":has_talent(unit,"paladin_l9_2")}
static func judgment_multiplier(unit:Dictionary,target_id:String)->float:return 1.0+float(PaladinData.VALUES.judgment_bonus) if float(unit.get("paladin_runtime",{}).get("judgments",{}).get(target_id,0.0))>0.0 else 1.0
static func start_ardent(unit:Dictionary)->bool:
	if str(unit.selected_heroic_id)!="paladin_l15_r1" or float(unit.ability_cds[3])>0.0:return false
	unit.ability_cds[3]=float(PaladinData.VALUES.ardent_cooldown);unit.paladin_runtime.ardent_remaining=float(PaladinData.VALUES.ardent_duration);return true
static func ardent_conversion(unit:Dictionary)->float:return float(PaladinData.VALUES.word_conversion if has_talent(unit,"paladin_l27_r1") else PaladinData.VALUES.ardent_conversion)
static func start_sacred(unit:Dictionary,center:Vector2)->bool:
	if str(unit.selected_heroic_id)!="paladin_l15_r2" or float(unit.ability_cds[3])>0.0:return false
	unit.ability_cds[3]=float(PaladinData.VALUES.sacred_cooldown);unit.paladin_runtime.sacred={"center":center,"remaining":float(PaladinData.VALUES.sacred_duration),"relocations":0,"lifetime":0.0};unit.paladin_runtime.sacred_tick=1.0;add(unit,"sacred_casts");return true
static func relocate_sacred(unit:Dictionary,center:Vector2)->bool:
	if unit.paladin_runtime.sacred.is_empty() or not has_talent(unit,"paladin_l27_r2"):return false
	unit.paladin_runtime.sacred.center=center;unit.paladin_runtime.sacred.remaining=float(PaladinData.VALUES.sacred_duration);unit.paladin_runtime.sacred.relocations=int(unit.paladin_runtime.sacred.relocations)+1;add(unit,"sacred_relocations");return true
static func advance(unit:Dictionary,delta:float)->void:
	var rt:Dictionary=unit.paladin_runtime;if bool(rt.charge.active):ChargedCastSystem.update(rt.charge,delta);add(unit,"charge_time",delta)
	rt.hand_icd=maxf(0.0,float(rt.hand_icd)-delta);rt.beacon_icd=maxf(0.0,float(rt.beacon_icd)-delta);rt.velen_remaining=maxf(0.0,float(rt.velen_remaining)-delta);rt.ardent_remaining=maxf(0.0,float(rt.ardent_remaining)-delta);rt.seraphim_remaining=maxf(0.0,float(rt.seraphim_remaining)-delta);HealingDoneModifierSystem.update(unit,delta)
	if float(rt.velen_remaining)<=0.0:rt.velen_stacks=0
	for id in rt.judgments.keys():
		rt.judgments[id]=maxf(0.0,float(rt.judgments[id])-delta)
		if float(rt.judgments[id])<=0.0:rt.judgments.erase(id)
	if not rt.sacred.is_empty():rt.sacred.remaining=maxf(0.0,float(rt.sacred.remaining)-delta);rt.sacred.lifetime=float(rt.sacred.lifetime)+delta;if float(rt.sacred.remaining)<=0.0:rt.sacred={}
