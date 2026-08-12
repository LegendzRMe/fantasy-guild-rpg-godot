extends RefCounted

const HuntsmanData = preload("res://scripts/data/huntsman_data.gd")
const AlternateActionSetSystem = preload("res://scripts/systems/alternate_action_set_system.gd")
const ArmorReductionSystem = preload("res://scripts/systems/armor_reduction_system.gd")
const StealthDetectionSystem = preload("res://scripts/systems/stealth_detection_system.gd")

static func has_talent(unit:Dictionary, talent_id:String) -> bool:
	return talent_id in unit.get("selected_talents", {}).values()

static func ability_amount(unit:Dictionary, value:float) -> float:
	var level := int(unit.get("level", 1))
	var expected := maxf(0.001, HuntsmanData.scaled(float(HuntsmanData.VALUES.basic_attack_damage), level))
	var result := HuntsmanData.scaled(value, level) * maxf(0.0, float(unit.get("power", expected))) / expected
	for effect in unit.get("active_effects", []):
		result *= 1.0 + float(effect.get("ability_power_bonus", 0.0)) / 100.0
	return result

static func default_telemetry() -> Dictionary:
	var result:Dictionary = {}
	for key in ["basic_hits","human_basic_damage","worgen_basic_damage","self_healing","cocktail_casts","cocktail_impact_damage","cocktail_explosion_damage","swipe_casts","swipe_damage","inner_beast_casts","inner_beast_refreshes","darkflight_casts","darkflight_damage","disengage_casts","form_changes","r1_casts","r1_damage","r1_resets","r2_casts","r2_damage","mark_stacks","percentage_damage","splash_damage","cleave_damage"]:
		result[key] = 0.0
	return result

static func initialize_runtime(unit:Dictionary, telemetry_enabled:bool=false, encounter_id:String="") -> void:
	unit["huntsman_base_armor"] = float(unit.get("armor", 0.0))
	unit["huntsman_runtime"] = {
		"form":"human", "human_q_cooldown":0.0, "worgen_q_cooldown":0.0, "shared_e_cooldown":0.0,
		"inner_beast_remaining":0.0, "inner_beast_elapsed":0.0, "projectiles":[], "pending_swipes":[],
		"r1_repeat_remaining":0.0, "r1_repeat_available":false, "r1_last_target_id":"",
		"marked_target_id":"", "mark_target_ref":null, "mark_remaining":0.0, "mark_stacks":0, "marked_reactivation":false,
		"cocktail_quest_stacks":0, "wizened_attacks":0, "wizened_remaining":0.0, "lord_bonus_remaining":0.0,
		"telemetry_enabled":telemetry_enabled, "telemetry":default_telemetry(), "encounter_id":encounter_id,
		"form_events":[], "cast_sequence":0
	}
	AlternateActionSetSystem.initialize(unit, {
		"human":{0:"huntsman_cocktail",1:"huntsman_inner_beast",2:"huntsman_darkflight"},
		"worgen":{0:"huntsman_swipe",1:"huntsman_inner_beast",2:"huntsman_disengage"}
	}, "human")
	apply_form_stats(unit)

static func telemetry_add(unit:Dictionary, key:String, value=1.0) -> void:
	var runtime:Dictionary = unit.get("huntsman_runtime", {})
	if runtime.is_empty() or not bool(runtime.get("telemetry_enabled", false)): return
	runtime.telemetry[key] = float(runtime.telemetry.get(key, 0.0)) + float(value)

static func is_worgen(unit:Dictionary) -> bool:
	return str(unit.get("huntsman_runtime", {}).get("form", "human")) == "worgen"

static func form_armor(unit:Dictionary) -> float:
	if not is_worgen(unit): return 0.0
	var base := 15.0 if has_talent(unit, "huntsman_l9_1") else float(HuntsmanData.VALUES.worgen_armor)
	return HuntsmanData.scaled(base, int(unit.get("level", 1)))

static func apply_form_stats(unit:Dictionary) -> void:
	var human_range := float(HuntsmanData.SPACE.human_basic_range)
	if has_talent(unit, "huntsman_l18_1"): human_range += 1.1 * float(HuntsmanData.SPACE.source_to_world)
	unit.range = float(HuntsmanData.SPACE.worgen_basic_range) if is_worgen(unit) else human_range
	unit.armor = float(unit.get("huntsman_base_armor", 0.0)) + form_armor(unit)

static func change_form(unit:Dictionary, new_form:String, source:String, now:float=0.0) -> bool:
	if new_form not in ["human", "worgen"]: return false
	var runtime:Dictionary = unit.huntsman_runtime
	var previous := str(runtime.form)
	if previous == new_form: return false
	runtime.form = new_form
	AlternateActionSetSystem.activate(unit, new_form)
	apply_form_stats(unit)
	runtime.cast_sequence = int(runtime.cast_sequence) + 1
	runtime.form_events.append({"previous_form":previous,"new_form":new_form,"source":source,"cast_id":"huntsman:%s:%d" % [str(unit.get("combat_id", "unit")), int(runtime.cast_sequence)],"time":now,"combat_id":str(unit.get("combat_id", ""))})
	if has_talent(unit, "huntsman_l30_3"):
		runtime.wizened_attacks = int(HuntsmanData.VALUES.wizened_attacks)
		runtime.wizened_remaining = float(HuntsmanData.VALUES.wizened_duration)
	telemetry_add(unit, "form_changes")
	return true

static func q_cooldown(unit:Dictionary, form:String="") -> float:
	var resolved_form := form if form != "" else str(unit.huntsman_runtime.form)
	if resolved_form == "worgen": return float(HuntsmanData.VALUES.swipe_cooldown)
	var reduction := 0.0
	if has_talent(unit, "huntsman_l18_2"):
		reduction = 5.0 if int(unit.huntsman_runtime.cocktail_quest_stacks) >= 15 else 2.0
	return maxf(1.0, float(HuntsmanData.VALUES.cocktail_cooldown) - reduction)

static func e_cooldown(unit:Dictionary) -> float:
	return float(HuntsmanData.VALUES.e_cooldown) - (1.0 if has_talent(unit, "huntsman_l21_1") else 0.0)

static func e_range(unit:Dictionary, form:String="") -> float:
	var resolved_form := form if form != "" else str(unit.huntsman_runtime.form)
	var base := float(HuntsmanData.SPACE.disengage_range if resolved_form == "worgen" else HuntsmanData.SPACE.darkflight_range)
	return base * (1.35 if has_talent(unit, "huntsman_l21_1") else 1.0)

static func inner_beast_duration(unit:Dictionary) -> float:
	return 4.0 if has_talent(unit, "huntsman_l9_3") else float(HuntsmanData.VALUES.inner_beast_duration)

static func activate_inner_beast(unit:Dictionary) -> void:
	unit.huntsman_runtime.inner_beast_remaining = inner_beast_duration(unit)
	unit.huntsman_runtime.inner_beast_elapsed = 0.0
	telemetry_add(unit, "inner_beast_casts")

static func refresh_inner_beast(unit:Dictionary, from_ability:bool=false) -> bool:
	if float(unit.huntsman_runtime.inner_beast_remaining) <= 0.0: return false
	if from_ability and not has_talent(unit, "huntsman_l9_3"): return false
	unit.huntsman_runtime.inner_beast_remaining = inner_beast_duration(unit)
	unit.huntsman_runtime.inner_beast_elapsed = 0.0
	telemetry_add(unit, "inner_beast_refreshes")
	return true

static func basic_attack_interval_multiplier(unit:Dictionary) -> float:
	if float(unit.get("huntsman_runtime", {}).get("inner_beast_remaining", 0.0)) <= 0.0: return 1.0
	var speed_bonus := float(HuntsmanData.VALUES.inner_beast_attack_speed)
	if has_talent(unit, "huntsman_l24_1") and float(unit.huntsman_runtime.inner_beast_elapsed) >= 4.0: speed_bonus += 0.40
	return 1.0 / (1.0 + speed_bonus)

static func movement_multiplier(unit:Dictionary) -> float:
	return 1.30 if has_talent(unit, "huntsman_l21_3") and float(unit.get("huntsman_runtime", {}).get("inner_beast_elapsed", 0.0)) >= 3.0 else 1.0

static func target_is_controlled(target:Dictionary) -> bool:
	return target.get("active_effects", []).any(func(effect):
		return str(effect.get("control_type", "")) in ["stun", "stagger", "slow", "root"] and float(effect.get("remaining_duration", 0.0)) > 0.0 and float(effect.get("delay", 0.0)) <= 0.0
	)

static func prepare_basic_attack(unit:Dictionary, target:Dictionary) -> Dictionary:
	var runtime:Dictionary = unit.huntsman_runtime
	var multiplier := 1.0 + (float(HuntsmanData.VALUES.worgen_basic_bonus) if is_worgen(unit) else 0.0)
	if int(runtime.wizened_attacks) > 0 and float(runtime.wizened_remaining) > 0.0: multiplier += float(HuntsmanData.VALUES.wizened_bonus)
	if float(runtime.lord_bonus_remaining) > 0.0: multiplier += 0.50 if is_worgen(unit) else 0.25
	if has_talent(unit, "huntsman_l24_2") and target_is_controlled(target): runtime.lord_bonus_remaining = 3.0
	return {"multiplier":multiplier,"worgen":is_worgen(unit),"wizened":int(runtime.wizened_attacks)>0 and float(runtime.wizened_remaining)>0.0}

static func resolve_basic_attack(unit:Dictionary, resolved_damage:float, was_wizened:bool) -> void:
	if resolved_damage <= 0.0: return
	var runtime:Dictionary = unit.huntsman_runtime
	refresh_inner_beast(unit, false)
	unit.ability_cds[1] = maxf(0.0, float(unit.ability_cds[1]) - (1.2 if has_talent(unit, "huntsman_l9_1") else float(HuntsmanData.VALUES.inner_beast_basic_cdr)))
	if is_worgen(unit) and has_talent(unit, "huntsman_l21_2"): runtime.worgen_q_cooldown = maxf(0.0, float(runtime.worgen_q_cooldown) - 1.5)
	if was_wizened: runtime.wizened_attacks = maxi(0, int(runtime.wizened_attacks) - 1)
	telemetry_add(unit, "basic_hits")
	telemetry_add(unit, "worgen_basic_damage" if is_worgen(unit) else "human_basic_damage", resolved_damage)

static func mark_stack_amount(unit:Dictionary) -> float:
	return HuntsmanData.scaled(float(HuntsmanData.VALUES.mark_stack_reduction), int(unit.get("level", 1)))

static func apply_mark(unit:Dictionary, target:Dictionary) -> void:
	clear_mark(unit)
	var runtime:Dictionary = unit.huntsman_runtime
	runtime.marked_target_id = str(target.get("combat_id", ""))
	runtime.mark_target_ref = target
	runtime.mark_remaining = float(HuntsmanData.VALUES.roulette_duration if has_talent(unit, "huntsman_l27_r2") else HuntsmanData.VALUES.mark_duration)
	runtime.mark_stacks = 1
	runtime.marked_reactivation = true
	refresh_mark_source(unit, target)
	StealthDetectionSystem.reveal(target, float(runtime.mark_remaining))

static func add_mark_stack(unit:Dictionary, target:Dictionary) -> bool:
	var runtime:Dictionary = unit.huntsman_runtime
	if str(runtime.marked_target_id) != str(target.get("combat_id", "")) or float(runtime.mark_remaining) <= 0.0: return false
	var cap := 2147483647 if has_talent(unit, "huntsman_l27_r2") else int(HuntsmanData.VALUES.mark_stack_cap)
	runtime.mark_stacks = mini(cap, int(runtime.mark_stacks) + 1)
	runtime.mark_remaining = float(HuntsmanData.VALUES.roulette_duration if has_talent(unit, "huntsman_l27_r2") else HuntsmanData.VALUES.mark_duration)
	refresh_mark_source(unit, target)
	StealthDetectionSystem.reveal(target, float(runtime.mark_remaining))
	telemetry_add(unit, "mark_stacks")
	return true

static func refresh_mark_source(unit:Dictionary, target:Dictionary) -> void:
	var reduction := mark_stack_amount(unit) * float(unit.huntsman_runtime.mark_stacks)
	ArmorReductionSystem.apply(target, "huntsman_mark:%s" % str(unit.get("combat_id", "")), reduction, float(unit.huntsman_runtime.mark_remaining))

static func clear_mark(unit:Dictionary) -> void:
	var runtime:Dictionary = unit.get("huntsman_runtime", {})
	if runtime.is_empty(): return
	var marked_target = runtime.get("mark_target_ref", null)
	if marked_target is Dictionary:
		var source_id := "huntsman_mark:%s" % str(unit.get("combat_id", ""))
		marked_target.armor_reduction_sources = marked_target.get("armor_reduction_sources", []).filter(func(source): return str(source.get("source_id", "")) != source_id)
	runtime.marked_target_id = ""
	runtime.mark_target_ref = null
	runtime.mark_remaining = 0.0
	runtime.mark_stacks = 0
	runtime.marked_reactivation = false

static func update(unit:Dictionary, delta:float, q_rate:float=1.0, e_rate:float=1.0) -> void:
	var runtime:Dictionary = unit.get("huntsman_runtime", {})
	if runtime.is_empty(): return
	runtime.human_q_cooldown = maxf(0.0, float(runtime.human_q_cooldown) - delta * q_rate)
	runtime.worgen_q_cooldown = maxf(0.0, float(runtime.worgen_q_cooldown) - delta * q_rate)
	runtime.shared_e_cooldown = maxf(0.0, float(runtime.shared_e_cooldown) - delta * e_rate)
	runtime.r1_repeat_remaining = maxf(0.0, float(runtime.r1_repeat_remaining) - delta)
	if float(runtime.r1_repeat_remaining) <= 0.0: runtime.r1_repeat_available = false
	if float(runtime.inner_beast_remaining) > 0.0:
		runtime.inner_beast_remaining = maxf(0.0, float(runtime.inner_beast_remaining) - delta)
		runtime.inner_beast_elapsed += delta
	else: runtime.inner_beast_elapsed = 0.0
	runtime.wizened_remaining = maxf(0.0, float(runtime.wizened_remaining) - delta)
	if float(runtime.wizened_remaining) <= 0.0: runtime.wizened_attacks = 0
	runtime.lord_bonus_remaining = maxf(0.0, float(runtime.lord_bonus_remaining) - delta)
	runtime.mark_remaining = maxf(0.0, float(runtime.mark_remaining) - delta)
	if float(runtime.mark_remaining) <= 0.0: clear_mark(unit)
	unit.ability_cds[0] = float(runtime.worgen_q_cooldown if is_worgen(unit) else runtime.human_q_cooldown)
	unit.ability_cds[2] = float(runtime.shared_e_cooldown)
	apply_form_stats(unit)
