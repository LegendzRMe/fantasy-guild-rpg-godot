extends RefCounted

const SlayerData = preload("res://scripts/data/slayer_data.gd")
const AbilitySlotSystem = preload("res://scripts/systems/ability_slot_system.gd")
const EvasionSystem = preload("res://scripts/systems/evasion_system.gd")
const BlockChargeSystem = preload("res://scripts/systems/block_charge_system.gd")
const TargetCategorySystem = preload("res://scripts/systems/combat_target_category_system.gd")

static func has_talent(unit:Dictionary,id:String) -> bool:return id in unit.get("selected_talents",{}).values()
static func scaled(unit:Dictionary,value:float) -> float:return SlayerData.scaled(value,int(unit.get("level",1)))
static func successful(result:Dictionary) -> bool:return not bool(result.get("evaded",false)) and not bool(result.get("immune",false)) and float(result.get("resolved_damage",0.0))>0.0

static func default_telemetry() -> Dictionary:
	return {"basic_attacks":0,"trait_healing":0.0,"trait_overhealing":0.0,"cooldown_reduction":0.0,"dives":0,"dive_invalid":0,"rapid_recasts":0,"sweeps":0,"sweep_contacts":0,"evasion_casts":0,"evaded_attacks":0,"metamorphosis_casts":0,"metamorphosis_contacts":0,"hunt_casts":0,"hunt_kills":0,"immolation_damage":0.0,"unending_hatred":0,"unbound_progress":0,"block_gained":0,"block_consumed":0,"hunter_healing":0.0,"elusive_reduction":0.0,"marked_activations":0,"fiery_brand_activations":0,"blades_activations":0,"unending_thirst_created":0.0,"unending_thirst_decayed":0.0,"thrill_casts":0}

static func initialize_runtime(unit:Dictionary,telemetry_enabled:bool=false) -> void:
	var w_max := 2 if has_talent(unit,"slayer_l12_3") and bool(unit.get("slayer_unbound_complete",false)) else 1
	unit["slayer_runtime"] = {
		"w_slot":AbilitySlotSystem.create(w_max,float(SlayerData.VALUES.w_cooldown)),
		"rapid_remaining":0.0,"rapid_first_target":"","rapid_recast_available":false,"movement_buff_remaining":0.0,
		"sweep_bonus_remaining":0.0,"sweep_bonus":0.0,"immolation_remaining":0.0,"immolation_tick":0.0,
		"unending_hatred_stacks":0,"unending_hatred_participation":{},"unbound_progress":0,"unbound_complete":false,
		"temporary_armor_sources":[],"marked_targets":{},"blades_stacks":0,"blades_remaining":0.0,
		"fiery_target":"","fiery_count":0,"fiery_expires":0.0,"metamorphosis_remaining":0.0,"metamorphosis_health_bonus":0.0,
		"unending_thirst_shield":0.0,"unending_thirst_grace":0.0,"unending_thirst_decay_accumulator":0.0,
		"telemetry_enabled":telemetry_enabled,"telemetry":default_telemetry()
	}
	EvasionSystem.initialize(unit);BlockChargeSystem.initialize(unit,"slayer_block",int(SlayerData.VALUES.reflexive_block_max))
	unit["control_duration_multipliers"]={"stun":float(SlayerData.VALUES.demonic_stun_root_duration_multiplier),"root":float(SlayerData.VALUES.demonic_stun_root_duration_multiplier)} if has_talent(unit,"slayer_l27_r1") else {}

static func telemetry_add(unit:Dictionary,key:String,value=1) -> void:
	var runtime:Dictionary=unit.get("slayer_runtime",{})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled",false)):return
	runtime.telemetry[key]=runtime.telemetry.get(key,0)+value

static func basic_attack_bonus(unit:Dictionary) -> float:
	var runtime:Dictionary=unit.get("slayer_runtime",{});var bonus:=0.0
	if float(runtime.get("sweep_bonus_remaining",0.0))>0.0:bonus+=float(runtime.get("sweep_bonus",0.0))
	if float(runtime.get("blades_remaining",0.0))>0.0:bonus+=float(SlayerData.VALUES.blades_bonus)
	if has_talent(unit,"slayer_l30_1"):bonus+=float(SlayerData.VALUES.nexus_bonus)
	return bonus

static func unending_hatred_bonus(unit:Dictionary) -> float:
	var stacks:=int(unit.get("slayer_runtime",{}).get("unending_hatred_stacks",0));var bonus:=scaled(unit,float(SlayerData.VALUES.unending_hatred_per_defeat))*stacks
	if stacks>=int(SlayerData.VALUES.unending_hatred_milestone):bonus+=scaled(unit,float(SlayerData.VALUES.unending_hatred_reward))
	return bonus

static func attack_interval(unit:Dictionary) -> float:
	var speed:=float(SlayerData.VALUES.demonic_attack_speed) if has_talent(unit,"slayer_l27_r1") else 0.0
	return float(unit.get("base_basic_action_interval",SlayerData.CLASS_DEFINITION.basic_action_interval))/maxf(0.1,1.0+speed)

static func movement_multiplier(unit:Dictionary) -> float:
	return 1.0+float(SlayerData.VALUES.rapid_chase_speed) if float(unit.get("slayer_runtime",{}).get("movement_buff_remaining",0.0))>0.0 else 1.0

static func reduce_trait_cooldowns(unit:Dictionary) -> float:
	var reduced:=0.0
	for slot in [0,2,3]:
		var before:=float(unit.ability_cds[slot]);unit.ability_cds[slot]=maxf(0.0,before-float(SlayerData.VALUES.trait_cooldown_reduction));reduced+=before-float(unit.ability_cds[slot])
	var runtime:Dictionary=unit.slayer_runtime
	if float(runtime.rapid_remaining)<=0.0:reduced+=AbilitySlotSystem.reduce_active_recharge(runtime.w_slot,float(SlayerData.VALUES.trait_cooldown_reduction))
	telemetry_add(unit,"cooldown_reduction",reduced);return reduced

static func prepare_basic_attack(unit:Dictionary,target:Dictionary) -> bool:
	if not has_talent(unit,"slayer_l24_2"):return false
	var target_id:=str(target.get("combat_id",""))
	if str(unit.slayer_runtime.fiery_target)!=target_id:unit.slayer_runtime.fiery_target=target_id;unit.slayer_runtime.fiery_count=0
	unit.slayer_runtime.fiery_count=int(unit.slayer_runtime.fiery_count)+1;unit.slayer_runtime.fiery_expires=float(SlayerData.VALUES.fiery_brand_lifetime)
	if int(unit.slayer_runtime.fiery_count)<int(SlayerData.VALUES.fiery_brand_goal):return false
	unit.slayer_runtime.fiery_count=0;telemetry_add(unit,"fiery_brand_activations");return true

static func note_basic_attack(unit:Dictionary,_target:Dictionary,result:Dictionary) -> Dictionary:
	if not successful(result):return {"raw_healing":0.0,"overhealing":0.0}
	telemetry_add(unit,"basic_attacks");unit.slayer_runtime.unending_thirst_grace=float(SlayerData.VALUES.unending_thirst_grace)
	var rate:=float(SlayerData.VALUES.thirsting_blade_healing) if has_talent(unit,"slayer_l18_2") and float(unit.slayer_runtime.sweep_bonus_remaining)>0.0 else float(SlayerData.VALUES.trait_healing)
	var raw:=float(result.resolved_damage)*rate;var missing:=maxf(0.0,float(unit.max_hp)-float(unit.hp));var effective:=minf(missing,raw);var overhealing:=maxf(0.0,raw-effective)
	reduce_trait_cooldowns(unit);telemetry_add(unit,"trait_healing",effective);telemetry_add(unit,"trait_overhealing",overhealing)
	return {"raw_healing":raw,"overhealing":overhealing}

static func note_damage_participation(unit:Dictionary,target:Dictionary,amount:float) -> void:
	if amount<=0.0 or not has_talent(unit,"slayer_l9_3"):return
	unit.slayer_runtime.unending_hatred_participation[str(target.get("combat_id",""))]=true

static func process_defeat(unit:Dictionary,target:Dictionary) -> bool:
	var target_id:=str(target.get("combat_id",""));var participated:=bool(unit.slayer_runtime.unending_hatred_participation.get(target_id,false));unit.slayer_runtime.unending_hatred_participation.erase(target_id)
	if not has_talent(unit,"slayer_l9_3") or not participated or not TargetCategorySystem.qualifies_quest(target):return false
	unit.slayer_runtime.unending_hatred_stacks=int(unit.slayer_runtime.unending_hatred_stacks)+1;telemetry_add(unit,"unending_hatred");return true

static func marked_bonus(unit:Dictionary,target:Dictionary) -> bool:
	var target_id:=str(target.get("combat_id",""));return has_talent(unit,"slayer_l24_1") and float(unit.slayer_runtime.marked_targets.get(target_id,0.0))>0.0

static func note_dive(unit:Dictionary,target:Dictionary) -> void:
	unit.slayer_runtime.marked_targets[str(target.get("combat_id",""))]=float(SlayerData.VALUES.marked_duration);telemetry_add(unit,"dives")

static func add_unending_thirst(unit:Dictionary,overhealing:float) -> float:
	if not has_talent(unit,"slayer_l30_3") or overhealing<=0.0:return 0.0
	var cap:=float(unit.max_hp)*float(SlayerData.VALUES.unending_thirst_cap);var before:=float(unit.slayer_runtime.unending_thirst_shield);unit.slayer_runtime.unending_thirst_shield=minf(cap,before+overhealing);var gained:=float(unit.slayer_runtime.unending_thirst_shield)-before;telemetry_add(unit,"unending_thirst_created",gained);return gained

static func begin_rapid_chase(unit:Dictionary,target_id:String) -> void:
	if not has_talent(unit,"slayer_l12_1"):unit.ability_cds[0]=float(SlayerData.VALUES.q_cooldown);return
	unit.slayer_runtime.rapid_remaining=float(SlayerData.VALUES.rapid_chase_duration);unit.slayer_runtime.rapid_first_target=target_id;unit.slayer_runtime.rapid_recast_available=true;unit.slayer_runtime.movement_buff_remaining=float(SlayerData.VALUES.rapid_chase_duration);unit.ability_cds[0]=0.0

static func rapid_target_valid(unit:Dictionary,target_id:String) -> bool:
	return float(unit.slayer_runtime.rapid_remaining)>0.0 and bool(unit.slayer_runtime.rapid_recast_available) and str(unit.slayer_runtime.rapid_first_target)!=target_id

static func consume_rapid_recast(unit:Dictionary) -> void:
	unit.slayer_runtime.rapid_recast_available=false;unit.slayer_runtime.movement_buff_remaining=float(SlayerData.VALUES.rapid_chase_duration);telemetry_add(unit,"rapid_recasts")

static func grant_dive_block(unit:Dictionary) -> void:
	if not has_talent(unit,"slayer_l18_1"):return
	var gained:=BlockChargeSystem.grant(unit,int(SlayerData.VALUES.reflexive_block_grant),int(SlayerData.VALUES.reflexive_block_max),"slayer_block");telemetry_add(unit,"block_gained",gained)

static func note_sweep(unit:Dictionary,targets:Array) -> void:
	var count:=targets.size();telemetry_add(unit,"sweeps");telemetry_add(unit,"sweep_contacts",count)
	if count<=0:return
	unit.slayer_runtime.sweep_bonus_remaining=float(SlayerData.VALUES.battered_duration if has_talent(unit,"slayer_l9_2") else SlayerData.VALUES.w_buff_duration)
	unit.slayer_runtime.sweep_bonus=float(SlayerData.VALUES.battered_bonus) if has_talent(unit,"slayer_l9_2") and count>=2 else float(SlayerData.VALUES.w_attack_bonus)
	if has_talent(unit,"slayer_l9_1"):unit.slayer_runtime.immolation_remaining=float(SlayerData.VALUES.immolation_duration);unit.slayer_runtime.immolation_tick=0.0
	if has_talent(unit,"slayer_l21_1"):
		unit.slayer_runtime.temporary_armor_sources=unit.slayer_runtime.temporary_armor_sources.filter(func(source):return str(source.get("id",""))!="nimble_defender")
		unit.slayer_runtime.temporary_armor_sources.append({"id":"nimble_defender","armor":scaled(unit,float(SlayerData.VALUES.nimble_armor)),"remaining":float(SlayerData.VALUES.nimble_duration)})
	if has_talent(unit,"slayer_l21_2"):
		var amount:=float(SlayerData.VALUES.elusive_reduction)*count;unit.ability_cds[2]=maxf(0.0,float(unit.ability_cds[2])-amount);telemetry_add(unit,"elusive_reduction",amount)
	if has_talent(unit,"slayer_l12_3") and not bool(unit.slayer_runtime.unbound_complete):
		var qualifying:=targets.filter(func(target):return TargetCategorySystem.qualifies_quest(target)).size();unit.slayer_runtime.unbound_progress+=qualifying;telemetry_add(unit,"unbound_progress",qualifying)
		if int(unit.slayer_runtime.unbound_progress)>=int(SlayerData.VALUES.unbound_goal):unit.slayer_runtime.unbound_complete=true;unit.slayer_runtime.w_slot.max_charges=2;unit.slayer_runtime.w_slot.current_charges=mini(2,int(unit.slayer_runtime.w_slot.current_charges)+1)
	if has_talent(unit,"slayer_l24_3"):
		unit.slayer_runtime.blades_stacks+=targets.filter(func(target):return TargetCategorySystem.qualifies_quest(target)).size()
		while int(unit.slayer_runtime.blades_stacks)>=int(SlayerData.VALUES.blades_goal):unit.slayer_runtime.blades_stacks-=int(SlayerData.VALUES.blades_goal);unit.slayer_runtime.blades_remaining=float(SlayerData.VALUES.blades_duration);telemetry_add(unit,"blades_activations")

static func begin_metamorphosis(unit:Dictionary,contacts:int) -> float:
	end_metamorphosis(unit)
	var count:=mini(int(SlayerData.VALUES.r1_target_cap),maxi(0,contacts));var bonus:=scaled(unit,float(SlayerData.VALUES.r1_health_per_target))*count
	unit.slayer_runtime.metamorphosis_remaining=float(SlayerData.VALUES.r1_duration);unit.slayer_runtime.metamorphosis_health_bonus=bonus;unit.max_hp+=bonus;unit.hp+=bonus;telemetry_add(unit,"metamorphosis_casts");telemetry_add(unit,"metamorphosis_contacts",count);return bonus

static func end_metamorphosis(unit:Dictionary) -> void:
	if unit.get("slayer_runtime",{}).is_empty():return
	var bonus:=float(unit.slayer_runtime.get("metamorphosis_health_bonus",0.0));unit.max_hp=maxf(1.0,float(unit.max_hp)-bonus);unit.hp=maxf(0.0,minf(float(unit.hp),float(unit.max_hp)));unit.slayer_runtime.metamorphosis_health_bonus=0.0;unit.slayer_runtime.metamorphosis_remaining=0.0
	if has_talent(unit,"slayer_l30_3"):
		var cap:=float(unit.max_hp)*float(SlayerData.VALUES.unending_thirst_cap);var source_total:=0.0
		for source in unit.get("shield_sources",[]):
			if str(source.get("source_id",""))=="slayer_unending_thirst":source_total+=float(source.get("amount",0.0))
		var excess:=maxf(0.0,source_total-cap)
		for index in range(unit.get("shield_sources",[]).size()-1,-1,-1):
			if excess<=0.0:break
			if str(unit.shield_sources[index].get("source_id",""))!="slayer_unending_thirst":continue
			var removed:=minf(excess,float(unit.shield_sources[index].get("amount",0.0)));unit.shield_sources[index].amount=float(unit.shield_sources[index].amount)-removed;unit.shield=maxf(0.0,float(unit.get("shield",0.0))-removed);excess-=removed
			if float(unit.shield_sources[index].amount)<=0.0001:unit.shield_sources.remove_at(index)
		unit.slayer_runtime.unending_thirst_shield=minf(source_total,cap)

static func update(unit:Dictionary,delta:float,w_rate:float=1.0) -> Dictionary:
	var runtime:Dictionary=unit.get("slayer_runtime",{});var output:={"immolation_tick":false,"metamorphosis_ended":false,"thirst_decay":0.0}
	if runtime.is_empty():return output
	EvasionSystem.update(unit,delta);AbilitySlotSystem.update(runtime.w_slot,delta,w_rate);unit.basic_attack_interval=attack_interval(unit)
	for key in ["movement_buff_remaining","sweep_bonus_remaining","immolation_remaining","blades_remaining","fiery_expires"]:runtime[key]=maxf(0.0,float(runtime.get(key,0.0))-delta)
	for target_id in runtime.marked_targets.keys():runtime.marked_targets[target_id]=maxf(0.0,float(runtime.marked_targets[target_id])-delta);if float(runtime.marked_targets[target_id])<=0.0:runtime.marked_targets.erase(target_id)
	for source in runtime.temporary_armor_sources:source.remaining=maxf(0.0,float(source.remaining)-delta)
	runtime.temporary_armor_sources=runtime.temporary_armor_sources.filter(func(source):return float(source.remaining)>0.0)
	if float(runtime.rapid_remaining)>0.0:
		runtime.rapid_remaining=maxf(0.0,float(runtime.rapid_remaining)-delta)
		if float(runtime.rapid_remaining)<=0.0:runtime.rapid_recast_available=false;unit.ability_cds[0]=float(SlayerData.VALUES.q_cooldown)
	if float(runtime.immolation_remaining)>0.0:
		runtime.immolation_tick-=delta
		if float(runtime.immolation_tick)<=0.0:runtime.immolation_tick+=float(SlayerData.VALUES.immolation_tick);output.immolation_tick=true
	if float(runtime.metamorphosis_remaining)>0.0:
		runtime.metamorphosis_remaining=maxf(0.0,float(runtime.metamorphosis_remaining)-delta)
		if float(runtime.metamorphosis_remaining)<=0.0:end_metamorphosis(unit);output.metamorphosis_ended=true
	if float(runtime.fiery_expires)<=0.0:runtime.fiery_target="";runtime.fiery_count=0
	if has_talent(unit,"slayer_l30_3") and float(runtime.unending_thirst_shield)>0.0:
		runtime.unending_thirst_grace=maxf(0.0,float(runtime.unending_thirst_grace)-delta)
		if float(runtime.unending_thirst_grace)<=0.0:
			var decay:=float(unit.max_hp)*float(SlayerData.VALUES.unending_thirst_decay)*delta;var actual:=minf(decay,float(runtime.unending_thirst_shield));runtime.unending_thirst_shield-=actual;output.thirst_decay=actual;telemetry_add(unit,"unending_thirst_decayed",actual)
	return output

static func reset_encounter(unit:Dictionary) -> void:
	if unit.get("slayer_runtime",{}).is_empty():return
	end_metamorphosis(unit);initialize_runtime(unit,bool(unit.slayer_runtime.get("telemetry_enabled",false)))
