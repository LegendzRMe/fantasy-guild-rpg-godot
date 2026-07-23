extends RefCounted

const WarlockData = preload("res://scripts/data/warlock_data.gd")
const AbilityPowerSystem = preload("res://scripts/systems/ability_power_system.gd")
const PeriodicStatusSystem = preload("res://scripts/systems/periodic_status_system.gd")

static func has_talent(unit:Dictionary, talent_id:String) -> bool:
	return talent_id in unit.get("selected_talents", {}).values()

static func default_telemetry() -> Dictionary:
	return {
		"life_tap_attempts":0, "life_tap_successes":0, "life_tap_invalid":{},
		"health_spent":0.0, "free_life_taps":0, "cooldown_reduction":{}, "cooldown_waste":0.0,
		"passive_health_loss":0.0, "passive_tap_equivalents":0.0,
		"q_casts":0, "q_hits":0, "q_distinct_hits":0, "pursuit_progress":0,
		"w_started":0, "w_completed":0, "w_target_deaths":0, "w_interruptions":{},
		"w_ticks":0, "w_damage":0.0, "w_raw_healing":0.0, "w_actual_healing":0.0, "w_overhealing":0.0,
		"e_casts":0, "e_forward_hits":0, "e_reverse_hits":0, "e_applications":0,
		"e_ticks":0, "e_damage":0.0, "e_mythic_healing":0.0,
		"horrify_casts":0, "horrify_hits":0, "successful_fears":0, "fear_immune":0,
		"rain_casts":0, "rain_meteors":0, "rain_targeted":0, "rain_random":0, "rain_hits":0,
		"demonic_circle_triggers":0, "demonic_circle_prevented":0.0,
		"dark_ritual_reduction":0.0, "soul_conduit_foreground":0
	}

static func initialize_runtime(unit:Dictionary, telemetry_enabled:bool=false) -> void:
	var max_health_before:=maxf(1.0, float(unit.get("max_hp", WarlockData.VALUES.health)))
	if has_talent(unit, "warlock_l21_3") and not bool(unit.get("dark_bargain_applied", false)):
		var ratio:=float(unit.get("hp", max_health_before)) / max_health_before
		unit.max_hp=max_health_before * float(WarlockData.VALUES.dark_bargain_health_multiplier)
		unit.hp=float(unit.max_hp) * ratio
		unit.dark_bargain_applied=true
	unit["warlock_runtime"]={
		"life_tap_lockout":0.0, "internal_cooldowns":{
			"consume_soul":{"remaining":0.0,"modified_base":modified_internal_base(unit,"consume_soul"),"life_tap_reducible":true,"health_loss_reducible":true,"chaotic_energy_reducible":true},
			"demonic_circle":{"remaining":0.0,"modified_base":float(WarlockData.VALUES.demonic_circle_cooldown),"life_tap_reducible":false,"health_loss_reducible":false,"chaotic_energy_reducible":false}
		},
		"periodic_effects":[], "delayed_effects":[], "rain_effects":[],
		"next_cast_id":1, "pursuit_progress":0, "pursuit_complete":false,
		"chaotic_progress":0, "chaotic_complete":false,
		"echoed_progress":0, "echoed_complete":false, "echoed_mythic":false,
		"rampant_stacks":0, "rampant_remaining":0.0,
		"fel_armor_stacks":0, "fel_armor_remaining":0.0,
		"darkness_progress":0.0, "darkness_armed":false, "darkness_power_remaining":0.0,
		"banished_remaining":0.0, "foreground_action_active":false,
		"telemetry_enabled":telemetry_enabled, "telemetry":default_telemetry()
	}
	refresh_modifiers(unit)

static func telemetry_add(unit:Dictionary, key:String, value=1) -> void:
	var runtime:Dictionary=unit.get("warlock_runtime", {})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled", false)):
		return
	runtime.telemetry[key]=runtime.telemetry.get(key, 0) + value

static func telemetry_reason(unit:Dictionary, key:String, reason:String) -> void:
	var runtime:Dictionary=unit.get("warlock_runtime", {})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled", false)):
		return
	var reasons:Dictionary=runtime.telemetry.get(key, {})
	reasons[reason]=int(reasons.get(reason, 0)) + 1
	runtime.telemetry[key]=reasons

static func cooldown_multiplier(unit:Dictionary) -> float:
	return float(WarlockData.VALUES.dark_bargain_cooldown_multiplier) if has_talent(unit, "warlock_l21_3") else 1.0

static func modified_base_cooldown(unit:Dictionary, slot:int) -> float:
	var bases:Array=[WarlockData.VALUES.q_cooldown, WarlockData.VALUES.w_cooldown, WarlockData.VALUES.e_cooldown,
		WarlockData.VALUES.r1_cooldown if str(unit.get("selected_heroic_id", ""))=="warlock_l15_r1" else WarlockData.VALUES.r2_cooldown]
	return float(bases[clampi(slot, 0, 3)]) * cooldown_multiplier(unit)

static func modified_internal_base(unit:Dictionary, cooldown_id:String) -> float:
	if cooldown_id=="consume_soul":
		return float(WarlockData.VALUES.consume_soul_internal_cooldown) * cooldown_multiplier(unit)
	return float(WarlockData.VALUES.demonic_circle_cooldown)

static func refresh_modifiers(unit:Dictionary) -> void:
	var runtime:Dictionary=unit.get("warlock_runtime", {})
	if runtime.is_empty():
		return
	var sources:Dictionary={}
	var base:=float(unit.get("base_ability_power_percent", unit.get("stats", {}).get("ability_power_percent", 0.0)))
	if base!=0.0:
		sources["base_and_items"]=base
	if float(runtime.darkness_power_remaining)>0.0:
		sources["darkness_within"]=float(WarlockData.VALUES.darkness_power_percent)
	unit.ability_power_sources=sources
	unit.ability_power_percent=sources.values().reduce(func(total, value): return float(total)+float(value), 0.0)
	unit.damage_multiplier=float(unit.get("base_damage_multiplier", 1.0)) * (1.15 if has_talent(unit, "warlock_l18_3") else 1.0)
	unit.healing_taken_multiplier=float(unit.get("base_healing_taken_multiplier", 1.0)) * (0.75 if has_talent(unit, "warlock_l18_3") else 1.0)
	unit.damage_taken_multiplier=float(unit.get("base_damage_taken_multiplier", 1.0)) * (1.15 if has_talent(unit, "warlock_l18_3") else 1.0)

static func scaled_amount(unit:Dictionary, level_one_amount:float, q_scaling:bool=false, qwe_power:bool=true) -> float:
	var level:=int(unit.get("level", 1))
	var growth:=pow(1.044921875 if q_scaling else WarlockData.SCALE_PER_LEVEL, maxi(0, level-1))
	var expected_power:=maxf(0.001, WarlockData.scaled(float(WarlockData.VALUES.basic_attack_damage), level))
	var raw_power_ratio:=maxf(0.0, float(unit.get("power", expected_power))) / expected_power
	var result:=level_one_amount * growth * raw_power_ratio
	if qwe_power:
		result=AbilityPowerSystem.apply(result, unit)
	return result

static func life_tap_cost(unit:Dictionary) -> float:
	return float(unit.get("max_hp", 0.0)) * float(WarlockData.VALUES.life_tap_health_cost_ratio)

static func eligible_reduction_exists(unit:Dictionary) -> bool:
	for slot in 3:
		if float(unit.get("ability_cds", [0,0,0])[slot])>0.0:
			return true
	for entry in unit.get("warlock_runtime", {}).get("internal_cooldowns", {}).values():
		if bool(entry.get("life_tap_reducible", false)) and float(entry.get("remaining", 0.0))>0.0:
			return true
	if has_talent(unit, "warlock_l30_2") and float(unit.get("ability_cds", [0,0,0,0])[3])>0.0:
		return true
	return bool(unit.get("warlock_runtime", {}).get("darkness_armed", false))

static func validate_life_tap(unit:Dictionary) -> Dictionary:
	if unit.get("warlock_runtime", {}).is_empty():
		return {"valid":false,"reason":"runtime"}
	if float(unit.warlock_runtime.life_tap_lockout)>0.0:
		return {"valid":false,"reason":"lockout"}
	if not eligible_reduction_exists(unit):
		return {"valid":false,"reason":"no_benefit"}
	var free:=bool(unit.warlock_runtime.darkness_armed)
	var cost:=0.0 if free else life_tap_cost(unit)
	if not free and float(unit.get("hp", 0.0))<=cost:
		return {"valid":false,"reason":"lethal","cost":cost}
	return {"valid":true,"reason":"","cost":cost,"free":free}

static func reduce_eligible_cooldowns(unit:Dictionary, ratio:float, source:String, include_heroic:bool=false) -> Dictionary:
	var result:={"by_slot":{},"by_internal":{},"heroic":0.0,"waste":0.0}
	for slot in 3:
		var requested:=modified_base_cooldown(unit, slot) * ratio
		var before:=float(unit.ability_cds[slot]);var applied:=minf(before, requested)
		unit.ability_cds[slot]=before-applied;result.by_slot[slot]=applied;result.waste=float(result.waste)+requested-applied
	for cooldown_id in unit.warlock_runtime.internal_cooldowns:
		var entry:Dictionary=unit.warlock_runtime.internal_cooldowns[cooldown_id]
		var tag:="life_tap_reducible" if source=="life_tap" else "health_loss_reducible" if source=="health_loss" else "chaotic_energy_reducible"
		if not bool(entry.get(tag, false)):
			continue
		var requested:=float(entry.modified_base)*ratio;var before:=float(entry.remaining);var applied:=minf(before, requested)
		entry.remaining=before-applied;result.by_internal[cooldown_id]=applied;result.waste=float(result.waste)+requested-applied
	if include_heroic and float(unit.ability_cds[3])>0.0:
		var requested:=modified_base_cooldown(unit, 3)*float(WarlockData.VALUES.dark_ritual_heroic_reduction_percent)
		result.heroic=minf(float(unit.ability_cds[3]), requested);unit.ability_cds[3]=float(unit.ability_cds[3])-float(result.heroic)
	telemetry_add(unit, "cooldown_waste", float(result.waste))
	return result

static func use_life_tap(unit:Dictionary) -> Dictionary:
	telemetry_add(unit, "life_tap_attempts")
	var validation:=validate_life_tap(unit)
	if not bool(validation.valid):
		telemetry_reason(unit, "life_tap_invalid", str(validation.reason));return validation
	var free:=bool(validation.free);var cost:=float(validation.cost)
	if not free:
		unit.hp=float(unit.hp)-cost;telemetry_add(unit, "health_spent", cost)
	else:
		telemetry_add(unit, "free_life_taps")
	var ratio:=float(WarlockData.VALUES.life_tap_improved_reduction_ratio if has_talent(unit, "warlock_l12_2") else WarlockData.VALUES.life_tap_base_reduction_ratio)
	var reductions:=reduce_eligible_cooldowns(unit, ratio, "life_tap", has_talent(unit, "warlock_l30_2"))
	if has_talent(unit, "warlock_l30_2"):
		telemetry_add(unit, "dark_ritual_reduction", float(reductions.heroic))
	if free:
		unit.warlock_runtime.darkness_armed=false;unit.warlock_runtime.darkness_progress=0.0
		unit.warlock_runtime.darkness_power_remaining=float(WarlockData.VALUES.darkness_duration)
		refresh_modifiers(unit)
	unit.warlock_runtime.life_tap_lockout=float(WarlockData.VALUES.life_tap_input_lockout)
	telemetry_add(unit, "life_tap_successes")
	return {"valid":true,"cost":cost,"free":free,"reductions":reductions}

static func convert_health_loss(unit:Dictionary, actual_health_lost:float, context:Dictionary={}) -> Dictionary:
	if actual_health_lost<=0.0 or bool(context.get("exclude_health_loss_cooldown_conversion", false)):
		return {"tap_equivalent":0.0,"reductions":{}}
	var denominator:=maxf(0.001, float(unit.get("max_hp", 0.0))*float(WarlockData.VALUES.life_tap_health_cost_ratio))
	var equivalent:=actual_health_lost/denominator
	var reductions:=reduce_eligible_cooldowns(unit, float(WarlockData.VALUES.life_tap_base_reduction_ratio)*equivalent, "health_loss", false)
	telemetry_add(unit, "passive_health_loss", actual_health_lost);telemetry_add(unit, "passive_tap_equivalents", equivalent)
	return {"tap_equivalent":equivalent,"reductions":reductions}

static func qualifying_target(target:Dictionary) -> bool:
	var tags:Array=target.get("combat_tags", [])
	if float(target.get("hp", 0.0))<=0.0 or bool(target.get("object", false)):
		return false
	if tags.any(func(tag): return tag in ["non_qualifying","scenery","damageable_object","destructible_wall","harmless_summon","trivial_swarm","noncombat"]):
		return false
	if bool(target.get("summoned_unit", false)) and not tags.any(func(tag): return tag in ["qualifying_enemy","eligible_hostile_summon"]):
		return false
	return true

static func apply_corruption(unit:Dictionary, target:Dictionary, cast_id:String) -> Dictionary:
	var instance:=PeriodicStatusSystem.make_instance("warlock_corruption", str(unit.get("combat_id", "")), str(target.get("combat_id", "")), float(WarlockData.VALUES.e_duration), float(WarlockData.VALUES.e_tick_interval), {
		"family":"corruption", "cast_id":cast_id, "max_stacks":int(WarlockData.VALUES.e_max_stacks),
		"icon_id":"warlock_corruption", "color":Color("9a4cc7"), "priority":40, "dispellable":true
	})
	unit.warlock_runtime.periodic_effects=PeriodicStatusSystem.add_stack(unit.warlock_runtime.periodic_effects, instance, int(WarlockData.VALUES.e_max_stacks))
	return instance

static func record_owned_damage(unit:Dictionary, actual_damage:float) -> void:
	if actual_damage<=0.0 or not has_talent(unit, "warlock_l24_3") or bool(unit.warlock_runtime.darkness_armed):
		return
	unit.warlock_runtime.darkness_progress=minf(float(WarlockData.VALUES.darkness_damage_requirement), float(unit.warlock_runtime.darkness_progress)+actual_damage)
	if float(unit.warlock_runtime.darkness_progress)>=float(WarlockData.VALUES.darkness_damage_requirement):
		unit.warlock_runtime.darkness_armed=true

static func try_demonic_circle(unit:Dictionary, incoming_health_damage:float, context:Dictionary={}) -> Dictionary:
	if not has_talent(unit, "warlock_l30_1") or incoming_health_damage<float(unit.get("hp", 0.0)):
		return {"triggered":false,"prevented":0.0}
	if bool(context.get("health_cost", false)) or bool(context.get("scripted_lethal", false)):
		return {"triggered":false,"prevented":0.0}
	var entry:Dictionary=unit.get("warlock_runtime", {}).get("internal_cooldowns", {}).get("demonic_circle", {})
	if float(entry.get("remaining", 0.0))>0.0:
		return {"triggered":false,"prevented":0.0}
	entry.remaining=float(WarlockData.VALUES.demonic_circle_cooldown)
	unit.warlock_runtime.banished_remaining=float(WarlockData.VALUES.demonic_circle_banish_duration)
	unit.hp=maxf(float(unit.hp), float(unit.max_hp)*float(WarlockData.VALUES.demonic_circle_return_health_percent))
	telemetry_add(unit, "demonic_circle_triggers");telemetry_add(unit, "demonic_circle_prevented", incoming_health_damage)
	return {"triggered":true,"prevented":incoming_health_damage,"banish_duration":unit.warlock_runtime.banished_remaining}

static func update(unit:Dictionary, delta:float) -> void:
	var runtime:Dictionary=unit.get("warlock_runtime", {})
	if runtime.is_empty():
		return
	runtime.life_tap_lockout=maxf(0.0, float(runtime.life_tap_lockout)-delta)
	runtime.rampant_remaining=maxf(0.0, float(runtime.rampant_remaining)-delta)
	if float(runtime.rampant_remaining)<=0.0:
		runtime.rampant_stacks=0
	runtime.fel_armor_remaining=maxf(0.0, float(runtime.fel_armor_remaining)-delta)
	if float(runtime.fel_armor_remaining)<=0.0:
		runtime.fel_armor_stacks=0
	runtime.darkness_power_remaining=maxf(0.0, float(runtime.darkness_power_remaining)-delta)
	runtime.banished_remaining=maxf(0.0, float(runtime.banished_remaining)-delta)
	for entry in runtime.internal_cooldowns.values():
		entry.remaining=maxf(0.0, float(entry.remaining)-delta)
	refresh_modifiers(unit)

static func fel_armor(unit:Dictionary) -> float:
	return int(unit.get("warlock_runtime", {}).get("fel_armor_stacks", 0))*float(WarlockData.VALUES.fel_armor_per_target)

static func slot_state(unit:Dictionary) -> Dictionary:
	var runtime:Dictionary=unit.get("warlock_runtime", {})
	return {
		"ready":not runtime.is_empty() and float(runtime.get("life_tap_lockout", 0.0))<=0.0,
		"can_benefit":eligible_reduction_exists(unit) if not runtime.is_empty() else false,
		"cost_percent":int(WarlockData.VALUES.life_tap_tooltip_percent),
		"darkness_armed":bool(runtime.get("darkness_armed", false)),
		"darkness_progress":float(runtime.get("darkness_progress", 0.0)),
		"darkness_required":float(WarlockData.VALUES.darkness_damage_requirement)
	}
