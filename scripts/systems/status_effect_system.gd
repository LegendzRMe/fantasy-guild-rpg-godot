extends RefCounted

const PREVENTED_BY_UNSTOPPABLE := ["stun", "root", "silence", "fear", "slow", "displacement"]

static func control_profile(unit:Dictionary)->Dictionary:
	var ordinary := {
		"stun_multiplier":1.0, "root_multiplier":1.0, "silence_multiplier":1.0,
		"fear_multiplier":1.0,
		"slow_multiplier":1.0, "attack_speed_multiplier":1.0,
		"blind_duration_multiplier":1.0, "blind_immune":false,
		"displacement":true, "interruptible":true, "stagger_multiplier":1.0
	}
	if bool(unit.get("boss", false)):
		ordinary.merge({"stun_multiplier":0.0, "slow_multiplier":0.5,
			"fear_multiplier":0.0,
			"attack_speed_multiplier":0.5, "blind_duration_multiplier":0.0,
			"blind_immune":true, "displacement":false}, true)
	ordinary.merge(unit.get("control_profile", {}), true)
	return ordinary

static func has_effect(unit:Dictionary,effect_id:String)->bool:
	return unit.get("active_effects", []).any(func(effect):
		return str(effect.get("id", "")) == effect_id and float(effect.get("remaining_duration", 0.0)) > 0.0)

static func is_blinded(unit:Dictionary)->bool:
	return has_effect(unit, "blind")

static func is_unstoppable(unit:Dictionary)->bool:
	return has_effect(unit, "unstoppable")

static func has_control(unit:Dictionary,control_type:String)->bool:
	return unit.get("active_effects", []).any(func(effect):
		return str(effect.get("control_type", "")) == control_type and float(effect.get("remaining_duration", 0.0)) > 0.0)

static func is_silenced(unit:Dictionary)->bool:
	return has_control(unit, "silence")

static func is_feared(unit:Dictionary)->bool:
	return has_control(unit, "fear")

static func remove_removable_controls(unit:Dictionary)->Array:
	var removed:Array = []
	var retained:Array = []
	for effect in unit.get("active_effects", []):
		if str(effect.get("control_type", "")) in PREVENTED_BY_UNSTOPPABLE:
			removed.append(str(effect.get("control_type", "")))
		else:
			retained.append(effect)
	unit["active_effects"] = retained
	return removed

static func apply_unstoppable(unit:Dictionary,duration:float)->Dictionary:
	var removed := remove_removable_controls(unit)
	unit["active_effects"] = strongest_refresh(unit.get("active_effects", []), {
		"id":"unstoppable", "remaining_duration":maxf(0.0, duration)
	})
	return {"applied":duration > 0.0, "duration":maxf(0.0, duration), "removed":removed}

static func strongest_refresh(active_effects:Array,effect:Dictionary)->Array:
	var next := active_effects.duplicate(true)
	var effect_id := str(effect.get("id", ""))
	for index in next.size():
		if str(next[index].get("id", "")) != effect_id:
			continue
		var current_strength := float(next[index].get("amount", 0.0))
		var incoming_strength := float(effect.get("amount", 0.0))
		if incoming_strength > current_strength:
			next[index] = effect.duplicate(true)
		else:
			next[index]["remaining_duration"] = maxf(
				float(next[index].get("remaining_duration", 0.0)),
				float(effect.get("remaining_duration", effect.get("duration", 0.0))))
		return next
	next.append(effect.duplicate(true))
	return next

static func apply_blind(unit:Dictionary,duration:float)->Dictionary:
	var profile := control_profile(unit)
	if bool(profile.get("blind_immune", false)):
		return {"applied":false, "resisted":true, "duration":0.0, "reason":"immune"}
	var resolved := maxf(0.0, duration * float(profile.get("blind_duration_multiplier", 1.0)))
	if resolved <= 0.0:
		return {"applied":false, "resisted":true, "duration":0.0, "reason":"duration"}
	unit["active_effects"] = strongest_refresh(unit.get("active_effects", []), {
		"id":"blind", "amount":1.0, "remaining_duration":resolved
	})
	return {"applied":true, "resisted":false, "duration":resolved, "reason":""}

static func apply_control(unit:Dictionary,control_type:String,duration:float,magnitude:float=0.0)->Dictionary:
	if is_unstoppable(unit) and control_type in PREVENTED_BY_UNSTOPPABLE:
		return {"applied":false, "resisted":true, "duration":0.0, "magnitude":0.0, "reason":"unstoppable"}
	var profile := control_profile(unit)
	if control_type == "displacement" and not bool(profile.get("displacement", true)):
		return {"applied":false, "resisted":true, "duration":0.0, "magnitude":0.0, "reason":"immune"}
	var multiplier := float(profile.get("%s_multiplier" % control_type, profile.get("slow_multiplier", 1.0)))
	var personal_multiplier:=float(unit.get("control_duration_multipliers",{}).get(control_type,1.0))
	var resolved_duration := maxf(0.0, duration * multiplier * personal_multiplier)
	var resolved_magnitude := magnitude * multiplier
	if resolved_duration <= 0.0:
		return {"applied":false, "resisted":true, "duration":0.0, "magnitude":0.0, "reason":"duration"}
	unit["active_effects"] = strongest_refresh(unit.get("active_effects", []), {
		"id":"control_%s" % control_type, "control_type":control_type,
		"amount":resolved_magnitude, "remaining_duration":resolved_duration
	})
	if control_type in ["stun","root","silence"] and "cleric_l30_2" in unit.get("selected_talents",{}).values() and unit.get("cleric_runtime",{}).get("serpents",[]).size()>=2:
		unit["active_effects"]=strongest_refresh(unit.active_effects,{"id":"shake_it_off_armor","amount":35.0,"remaining_duration":resolved_duration+2.0})
	return {"applied":true, "resisted":false, "duration":resolved_duration, "magnitude":resolved_magnitude, "reason":""}
