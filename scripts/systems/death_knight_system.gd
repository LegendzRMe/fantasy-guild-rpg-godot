extends RefCounted

const DeathKnightData=preload("res://scripts/data/death_knight_data.gd")
const AbilitySlotSystem=preload("res://scripts/systems/ability_slot_system.gd")
const TargetCategorySystem=preload("res://scripts/systems/combat_target_category_system.gd")
const ProgressionScopeSystem=preload("res://scripts/systems/progression_scope_system.gd")
const QuestProgressModifierSystem=preload("res://scripts/systems/quest_progress_modifier_system.gd")
const HealingReceivedModifierSystem=preload("res://scripts/systems/healing_received_modifier_system.gd")
const IncomingDamageReductionSystem=preload("res://scripts/systems/incoming_damage_reduction_system.gd")
const ToggleStanceSystem=preload("res://scripts/systems/toggle_stance_system.gd")
const StatusEffectSystem=preload("res://scripts/systems/status_effect_system.gd")
const SummonLifetimeSystem=preload("res://scripts/systems/summon_lifetime_system.gd")

static func has_talent(unit:Dictionary,id:String)->bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float)->float:return DeathKnightData.scaled(value,int(unit.get("level",1)))
static func successful(result:Dictionary)->bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0
static func mastery_progress(unit:Dictionary)->int:return maxi(0,int(unit.get("death_knight_runtime",{}).get("mastery",{}).get("death_knight_l9_1",0)))
static func frost_presence_mastered(unit:Dictionary)->bool:return mastery_progress(unit)>=int(DeathKnightData.VALUES.frost_presence_mastery)
static func frost_presence_progress(unit:Dictionary)->int:return int(unit.get("death_knight_runtime",{}).get("encounter_progress",{}).get("frost_presence",0))
static func frost_presence_reward(unit:Dictionary,milestone:int)->bool:return frost_presence_mastered(unit) or frost_presence_progress(unit)>=milestone
static func controlled(unit:Dictionary)->bool:return ["slow","root","stun"].any(func(kind):return StatusEffectSystem.has_control(unit,kind))

static func default_telemetry()->Dictionary:
	var result:Dictionary={}
	for key in ["d_activations","d_attacks","d_invalid","d_bonus_damage","frostmourne_stacks","death_pact_start","death_pact_doubled","frost_strike_hits","frost_strike_damage","q_enemy","q_self","q_damage","q_healing","q_overhealing","immortal_healing","healing_reductions","deathlord_coils","frost_presence_slows","dominion_25","dominion_40","dominion_refresh","w_casts","w_path_hits","w_final_hits","w_unique_hits","w_damage","w_roots","w_resists","control_extensions","control_duration_added","icebound_stuns","icebound_slows","icebound_cdr","deathchill_damage","tempest_activations","tempest_deactivations","tempest_duration","tempest_ticks","tempest_damage","tempest_targets","icy_stacks","rune_stacks","biting_ramp","remorseless_roots","frost_presence_contacts","frost_presence_progress","frost_presence_15","frost_presence_30","frost_presence_50","frost_presence_mastery","shared_progress","army_charge_generation","army_death_cdr","army_casts","army_charges_used","ghouls_created","ghoul_attacks","ghoul_damage","ghoul_deaths","ghoul_expirations","legion_ghouls","sindragosa_casts","sindragosa_hits","sindragosa_damage","sindragosa_slows","sindragosa_blinds","absolute_roots"]:result[key]=0.0
	return result

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false,mastery:Dictionary={},encounter_id:String="")->void:
	var army_cooldown:=float(DeathKnightData.VALUES.army_charge_cooldown)-(float(DeathKnightData.VALUES.legion_cdr) if has_talent(unit,"death_knight_l27_r1") else 0.0)
	unit["death_knight_runtime"]={
		"frostmourne_stacks":int(DeathKnightData.VALUES.death_pact_start) if has_talent(unit,"death_knight_l30_1") else 0,"frostmourne_primed":false,"frostmourne_cooldown":0.0,
		"tempest":ToggleStanceSystem.create(tempest_cooldown(unit),[0,1,3,4]),"tempest_tick_remaining":float(DeathKnightData.VALUES.tempest_tick),"suppression":{},"icy_talons":0.0,
		"rune_attack_counter":0,"rune_stacks":0,"biting":{},"remorseless":{},"army_slot":AbilitySlotSystem.create(int(DeathKnightData.VALUES.army_max_charges),army_cooldown),"army_cast_serial":0,"ghouls":[],
		"mastery":mastery.duplicate(true),"howling_cast_serial":0,"recent_dominion":{},"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	ProgressionScopeSystem.begin_encounter(unit.death_knight_runtime,encounter_id if encounter_id!="" else ProgressionScopeSystem.new_encounter_id("death_knight"))
	if has_talent(unit,"death_knight_l30_1"):telemetry_add(unit,"death_pact_start",int(DeathKnightData.VALUES.death_pact_start))
	apply_passives(unit)

static func apply_passives(unit:Dictionary)->void:
	HealingReceivedModifierSystem.remove(unit,"death_knight_rune_tap_passive")
	if has_talent(unit,"death_knight_l18_2"):HealingReceivedModifierSystem.apply(unit,"death_knight_rune_tap_passive",float(DeathKnightData.VALUES.rune_passive),INF,str(unit.get("combat_id","")))
	var duration_sources:Dictionary=unit.get("control_duration_multipliers",{}).duplicate(true)
	for kind in ["stun","root","slow"]:duration_sources.erase(kind)
	if has_talent(unit,"death_knight_l24_3"):for kind in ["stun","root","slow"]:duration_sources[kind]=float(DeathKnightData.VALUES.anti_magic_duration_multiplier)
	unit.control_duration_multipliers=duration_sources
	var profile:Dictionary=unit.get("control_profile",{}).duplicate(true);profile.erase("blind_immune")
	if has_talent(unit,"death_knight_l24_3"):profile.blind_immune=true
	unit.control_profile=profile

static func telemetry_add(unit:Dictionary,key:String,value=1.0)->void:
	var runtime:Dictionary=unit.get("death_knight_runtime",{});if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=float(runtime.telemetry.get(key,0.0))+float(value)

static func basic_attack_amount(unit:Dictionary)->float:return scaled(unit,float(DeathKnightData.VALUES.basic_attack_damage)+float(unit.get("death_knight_runtime",{}).get("frostmourne_stacks",0))*float(DeathKnightData.VALUES.frostmourne_basic_per_stack))
static func frostmourne_bonus(unit:Dictionary)->float:return scaled(unit,float(DeathKnightData.VALUES.frostmourne_damage)+float(unit.get("death_knight_runtime",{}).get("frostmourne_stacks",0))*float(DeathKnightData.VALUES.frostmourne_damage_per_stack))
static func frostmourne_cooldown(unit:Dictionary)->float:return float(DeathKnightData.VALUES.frostmourne_cooldown)-(float(DeathKnightData.VALUES.feeds_cdr) if has_talent(unit,"death_knight_l24_2") else 0.0)
static func tempest_cooldown(unit:Dictionary)->float:return float(DeathKnightData.VALUES.tempest_cooldown)-(float(DeathKnightData.VALUES.borean_cooldown) if has_talent(unit,"death_knight_l9_2") else 0.0)
static func tempest_linger(unit:Dictionary)->float:return float(DeathKnightData.VALUES.tempest_linger)+(float(DeathKnightData.VALUES.borean_linger) if has_talent(unit,"death_knight_l9_2") else 0.0)
static func tempest_increment(unit:Dictionary)->float:return float(DeathKnightData.VALUES.eternal_increment if has_talent(unit,"death_knight_l30_2") else DeathKnightData.VALUES.tempest_increment)
static func action_allowed(unit:Dictionary,slot:int)->bool:return ToggleStanceSystem.action_allowed(unit.death_knight_runtime.tempest,slot)
static func locked_slots(unit:Dictionary)->Array:return [] if not bool(unit.get("death_knight_runtime",{}).get("tempest",{}).get("active",false)) or has_talent(unit,"death_knight_l30_2") else [0,1,3,4]

static func activate_frostmourne(unit:Dictionary,has_target:bool)->bool:
	var runtime:Dictionary=unit.get("death_knight_runtime",{});if runtime.is_empty() or float(runtime.frostmourne_cooldown)>0.0 or bool(runtime.frostmourne_primed) or not action_allowed(unit,4):telemetry_add(unit,"d_invalid");return false
	runtime.frostmourne_primed=true;telemetry_add(unit,"d_activations");return true

static func frostmourne_attack_plan(unit:Dictionary,target:Dictionary)->Dictionary:
	if not bool(unit.get("death_knight_runtime",{}).get("frostmourne_primed",false)):return {"triggered":false}
	var was_controlled:=controlled(target);return {"triggered":true,"bonus_damage":frostmourne_bonus(unit),"frost_strike":scaled(unit,float(DeathKnightData.VALUES.frost_strike_damage)) if has_talent(unit,"death_knight_l12_3") else 0.0,"was_controlled":was_controlled}

static func resolve_frostmourne_attack(unit:Dictionary,target:Dictionary,result:Dictionary,defeated:bool=false,target_was_controlled:bool=false)->int:
	var runtime:Dictionary=unit.death_knight_runtime;if not bool(runtime.frostmourne_primed):return 0
	runtime.frostmourne_primed=false;var cooldown:=frostmourne_cooldown(unit)
	if has_talent(unit,"death_knight_l24_2") and target_was_controlled:cooldown=maxf(0.0,cooldown-float(DeathKnightData.VALUES.feeds_control_cdr))
	runtime.frostmourne_cooldown=cooldown;telemetry_add(unit,"d_attacks")
	if not successful(result):return 0
	var category:=TargetCategorySystem.category(target);var qualifies:=category=="standard" and defeated or category in ["elite","named","boss","enemy_hero"]
	if not qualifies:return 0
	var gained:=int(DeathKnightData.VALUES.death_pact_gain) if has_talent(unit,"death_knight_l30_1") else 1;runtime.frostmourne_stacks=int(runtime.frostmourne_stacks)+gained;telemetry_add(unit,"frostmourne_stacks",gained);if gained>1:telemetry_add(unit,"death_pact_doubled",gained-1)
	return gained

static func toggle_tempest(unit:Dictionary)->Dictionary:
	var state:Dictionary=unit.death_knight_runtime.tempest
	if bool(state.active):
		var duration:=float(state.active_duration);ToggleStanceSystem.deactivate(state,tempest_cooldown(unit));reset_tempest_bonuses(unit);telemetry_add(unit,"tempest_deactivations");telemetry_add(unit,"tempest_duration",duration);return {"changed":true,"active":false,"cooldown":float(state.cooldown)}
	if not ToggleStanceSystem.activate(state):return {"changed":false,"active":false}
	state.lock_bypassed=has_talent(unit,"death_knight_l30_2");unit.death_knight_runtime.tempest_tick_remaining=float(DeathKnightData.VALUES.tempest_tick);telemetry_add(unit,"tempest_activations");return {"changed":true,"active":true}

static func reset_tempest_bonuses(unit:Dictionary)->void:
	var runtime:Dictionary=unit.death_knight_runtime;runtime.icy_talons=0.0;runtime.rune_attack_counter=0;runtime.rune_stacks=0;runtime.suppression={};runtime.biting={};runtime.remorseless={}
	unit.basic_attack_interval=float(unit.get("base_basic_action_interval",DeathKnightData.VALUES.basic_attack_interval))

static func tempest_tick_plan(unit:Dictionary,target:Dictionary)->Dictionary:
	var runtime:Dictionary=unit.death_knight_runtime;var id:=str(target.get("combat_id",""));var exposure:Dictionary=runtime.suppression.get(id,{"stacks":0.0,"linger":0.0,"continuous":0.0})
	exposure.stacks=minf(float(DeathKnightData.VALUES.tempest_cap),float(exposure.stacks)+tempest_increment(unit));exposure.linger=tempest_linger(unit);exposure.continuous=float(exposure.continuous)+float(DeathKnightData.VALUES.tempest_tick);runtime.suppression[id]=exposure
	var biting_bonus:=0.0
	if has_talent(unit,"death_knight_l21_3"):biting_bonus=minf(float(DeathKnightData.VALUES.biting_cap),maxf(0.0,float(exposure.continuous)-1.0)*float(DeathKnightData.VALUES.biting_per_tick));runtime.biting[id]=biting_bonus;telemetry_add(unit,"biting_ramp",biting_bonus)
	var root:=false
	if has_talent(unit,"death_knight_l24_1"):
		var rem:Dictionary=runtime.remorseless.get(id,{"exposure":0.0,"cooldown":0.0});rem.exposure=float(exposure.continuous);if float(rem.cooldown)<=0.0 and float(rem.exposure)>=float(DeathKnightData.VALUES.remorseless_exposure):root=true;rem.cooldown=float(DeathKnightData.VALUES.remorseless_icd);runtime.remorseless[id]=rem
	return {"damage":scaled(unit,float(DeathKnightData.VALUES.tempest_damage))*(1.0+biting_bonus),"suppression":float(exposure.stacks),"root":root}

static func note_tempest_contacts(unit:Dictionary,unique_count:int)->void:
	if has_talent(unit,"death_knight_l12_2"):var count:=mini(int(DeathKnightData.VALUES.icy_contact_cap),maxi(0,unique_count));unit.death_knight_runtime.icy_talons=minf(float(DeathKnightData.VALUES.icy_cap),float(unit.death_knight_runtime.icy_talons)+count*float(DeathKnightData.VALUES.icy_per_contact));telemetry_add(unit,"icy_stacks",count)
	unit.basic_attack_interval=float(unit.get("base_basic_action_interval",DeathKnightData.VALUES.basic_attack_interval))/maxf(0.1,1.0+float(unit.death_knight_runtime.icy_talons))

static func note_primary_basic_attack(unit:Dictionary,result:Dictionary)->Dictionary:
	if not successful(result) or not bool(unit.get("death_knight_runtime",{}).get("tempest",{}).get("active",false)) or not has_talent(unit,"death_knight_l18_2"):return {"rune_stack":false}
	var runtime:Dictionary=unit.death_knight_runtime;runtime.rune_attack_counter=int(runtime.rune_attack_counter)+1
	if int(runtime.rune_attack_counter)<int(DeathKnightData.VALUES.rune_attacks):return {"rune_stack":false}
	runtime.rune_attack_counter=0;var before:=int(runtime.rune_stacks);runtime.rune_stacks=mini(int(DeathKnightData.VALUES.rune_max),before+1);telemetry_add(unit,"rune_stacks",int(runtime.rune_stacks)-before);return {"rune_stack":int(runtime.rune_stacks)>before}
static func rune_aura_bonus(unit:Dictionary)->float:return float(unit.get("death_knight_runtime",{}).get("rune_stacks",0))*float(DeathKnightData.VALUES.rune_per_stack) if has_talent(unit,"death_knight_l18_2") else 0.0

static func add_frost_presence_progress(unit:Dictionary,target_ids:Array)->int:
	if not has_talent(unit,"death_knight_l9_1") or frost_presence_mastered(unit):return frost_presence_progress(unit)
	var unique:Dictionary={};for id in target_ids:unique[str(id)]=true
	var base:=mini(int(DeathKnightData.VALUES.frost_presence_cast_cap),unique.size());var amount:=QuestProgressModifierSystem.amount(unit,base);var before:=frost_presence_progress(unit);var progress:=mini(int(DeathKnightData.VALUES.frost_presence_mastery),ProgressionScopeSystem.add_encounter_progress(unit.death_knight_runtime,"frost_presence",amount));unit.death_knight_runtime.encounter_progress.frost_presence=progress
	telemetry_add(unit,"frost_presence_contacts",base);telemetry_add(unit,"frost_presence_progress",progress-before);if amount>base:telemetry_add(unit,"shared_progress",amount-base)
	for milestone in [15,30,50]:if before<milestone and progress>=milestone:telemetry_add(unit,"frost_presence_%d"%milestone)
	if progress>=int(DeathKnightData.VALUES.frost_presence_mastery):unit.death_knight_runtime.mastery["death_knight_l9_1"]=int(DeathKnightData.VALUES.frost_presence_mastery);telemetry_add(unit,"frost_presence_mastery")
	return progress

static func howling_radius(unit:Dictionary)->float:return float(DeathKnightData.SPACE.howling_radius)*(1.0+float(DeathKnightData.VALUES.frost_presence_radius) if has_talent(unit,"death_knight_l9_1") else 1.0)
static func howling_range(unit:Dictionary)->float:return float(DeathKnightData.SPACE.howling_range)*(1.0+float(DeathKnightData.VALUES.frost_presence_range) if has_talent(unit,"death_knight_l9_1") and frost_presence_reward(unit,int(DeathKnightData.VALUES.frost_presence_first)) else 1.0)
static func howling_damage(unit:Dictionary)->float:
	var amount:=float(DeathKnightData.VALUES.howling_damage)
	if has_talent(unit,"death_knight_l21_2"):amount+=float(unit.death_knight_runtime.frostmourne_stacks)*float(DeathKnightData.VALUES.deathchill_per_stack)
	return scaled(unit,amount)
static func howling_root(unit:Dictionary)->float:return float(DeathKnightData.VALUES.howling_root)+(float(DeathKnightData.VALUES.deathchill_root) if has_talent(unit,"death_knight_l21_2") else 0.0)
static func extend_preexisting_controls(unit:Dictionary,target:Dictionary)->Dictionary:return StatusEffectSystem.extend_controls(target,["slow","root","stun"],1.0+float(DeathKnightData.VALUES.control_extension)) if has_talent(unit,"death_knight_l12_1") else {}

static func death_coil_damage(unit:Dictionary)->float:
	var multiplier:=1.0
	if has_talent(unit,"death_knight_l21_1"):multiplier+=clampf(1.0-float(unit.get("hp",0.0))/maxf(1.0,float(unit.get("max_hp",1.0))),0.0,1.0)*float(DeathKnightData.VALUES.deathlord_max_bonus)
	return scaled(unit,float(DeathKnightData.VALUES.death_coil_damage))*multiplier
static func death_coil_heal(unit:Dictionary,self_cast:bool)->float:return scaled(unit,float(DeathKnightData.VALUES.death_coil_heal))*(1.0+float(DeathKnightData.VALUES.immortal_self_bonus) if self_cast and has_talent(unit,"death_knight_l18_1") else 1.0)
static func death_coil_cooldown(unit:Dictionary,self_cast:bool)->float:return float(DeathKnightData.VALUES.death_coil_cooldown)-(float(DeathKnightData.VALUES.immortal_self_cdr) if self_cast and has_talent(unit,"death_knight_l18_1") else 0.0)
static func dominion_amount(unit:Dictionary,target_was_controlled:bool)->float:return float(DeathKnightData.VALUES.dominion_controlled if target_was_controlled else DeathKnightData.VALUES.dominion_normal) if has_talent(unit,"death_knight_l30_3") else 0.0

static func create_ghoul(unit:Dictionary,index:int)->Dictionary:
	var cast_id:="death_knight_army:%s:%d"%[str(unit.get("combat_id","dk")),int(unit.death_knight_runtime.army_cast_serial)];var summon_id:="%s:%d"%[cast_id,index]
	return {"combat_id":summon_id,"cast_id":cast_id,"owner_id":str(unit.get("combat_id","")),"source_id":summon_id,"source":"death_knight_army","team":"player","combat_team":"player","combat_affiliation":"player","target_category":"summon","combat_tags":["summon"],"summoned_unit":true,"original_lifetime":float(DeathKnightData.VALUES.ghoul_lifetime),"remaining_lifetime":float(DeathKnightData.VALUES.ghoul_lifetime),"hp":scaled(unit,float(DeathKnightData.VALUES.ghoul_health)),"max_hp":scaled(unit,float(DeathKnightData.VALUES.ghoul_health)),"damage":scaled(unit,float(DeathKnightData.VALUES.ghoul_damage)),"attack_interval":float(DeathKnightData.VALUES.ghoul_interval),"attack_cooldown":0.0,"movement_speed":float(DeathKnightData.VALUES.ghoul_speed),"range":1.0*float(DeathKnightData.SPACE.source_to_world),"combat_radius":.6875*float(DeathKnightData.SPACE.source_to_world),"target_id":"","active_effects":[],"threat":{},"pos":Vector2(unit.get("pos",Vector2.ZERO))+Vector2.from_angle(index*TAU/12.0)*50.0}
static func cast_army(unit:Dictionary)->Array:
	var runtime:Dictionary=unit.death_knight_runtime;var charges:=int(runtime.army_slot.current_charges);if charges<=0:return []
	runtime.army_cast_serial=int(runtime.army_cast_serial)+1
	var multiplier:=2 if has_talent(unit,"death_knight_l27_r1") else 1;var created:Array=[]
	for _spent in charges:
		AbilitySlotSystem.spend(runtime.army_slot)
		for _copy in multiplier:created.append(create_ghoul(unit,created.size()))
	runtime.ghouls.append_array(created)
	telemetry_add(unit,"army_casts")
	telemetry_add(unit,"army_charges_used",charges)
	telemetry_add(unit,"ghouls_created",created.size())
	if multiplier==2:telemetry_add(unit,"legion_ghouls",created.size()-charges)
	return created
static func note_nearby_enemy_death(unit:Dictionary,distance:float)->float:
	if str(unit.get("selected_heroic_id",""))!="death_knight_l15_r1" or distance>float(DeathKnightData.SPACE.army_death_radius):return 0.0
	var reduced:=AbilitySlotSystem.reduce_active_recharge(unit.death_knight_runtime.army_slot,float(DeathKnightData.VALUES.army_death_cdr));telemetry_add(unit,"army_death_cdr",reduced);return reduced

static func update(unit:Dictionary,delta:float)->Dictionary:
	var runtime:Dictionary=unit.get("death_knight_runtime",{});if runtime.is_empty():return {"tempest_tick":false}
	runtime.frostmourne_cooldown=maxf(0.0,float(runtime.frostmourne_cooldown)-delta);ToggleStanceSystem.update(runtime.tempest,delta);var army_before:=int(runtime.army_slot.current_charges);AbilitySlotSystem.update(runtime.army_slot,delta);telemetry_add(unit,"army_charge_generation",int(runtime.army_slot.current_charges)-army_before)
	var tick:=false
	if bool(runtime.tempest.active):runtime.tempest_tick_remaining=float(runtime.tempest_tick_remaining)-delta;if float(runtime.tempest_tick_remaining)<=0.0:runtime.tempest_tick_remaining+=float(DeathKnightData.VALUES.tempest_tick);tick=true
	for id in runtime.suppression.keys():runtime.suppression[id].linger=float(runtime.suppression[id].linger)-delta;if float(runtime.suppression[id].linger)<=0.0:runtime.suppression.erase(id);runtime.biting.erase(id);runtime.remorseless.erase(id)
	for id in runtime.remorseless.keys():runtime.remorseless[id].cooldown=maxf(0.0,float(runtime.remorseless[id].cooldown)-delta)
	for ghoul in runtime.ghouls:SummonLifetimeSystem.update(ghoul,delta);ghoul.attack_cooldown=maxf(0.0,float(ghoul.attack_cooldown)-delta)
	var deaths:int=runtime.ghouls.filter(func(ghoul):return float(ghoul.hp)<=0.0).size();var expirations:int=runtime.ghouls.filter(func(ghoul):return float(ghoul.hp)>0.0 and float(ghoul.remaining_lifetime)<=0.0).size();telemetry_add(unit,"ghoul_deaths",deaths);telemetry_add(unit,"ghoul_expirations",expirations);runtime.ghouls=runtime.ghouls.filter(func(ghoul):return float(ghoul.remaining_lifetime)>0.0 and float(ghoul.hp)>0.0)
	return {"tempest_tick":tick}

static func defeat(unit:Dictionary)->void:
	if bool(unit.get("death_knight_runtime",{}).get("tempest",{}).get("active",false)):ToggleStanceSystem.deactivate(unit.death_knight_runtime.tempest,tempest_cooldown(unit));reset_tempest_bonuses(unit)
static func reset_encounter(unit:Dictionary,new_encounter_id:String="")->void:
	var mastery:Dictionary=unit.get("death_knight_runtime",{}).get("mastery",{}).duplicate(true);var telemetry_enabled:=bool(unit.get("death_knight_runtime",{}).get("telemetry_enabled",false));initialize_runtime(unit,telemetry_enabled,mastery,new_encounter_id)
