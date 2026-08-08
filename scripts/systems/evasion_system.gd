extends RefCounted

const STATE_KEY := "evasion_state"

static func initialize(unit:Dictionary) -> void:
	if not unit.get(STATE_KEY) is Dictionary:
		unit[STATE_KEY] = {"remaining":0.0,"source_id":""}

static func activate(unit:Dictionary,duration:float,source_id:String="evasion") -> bool:
	initialize(unit)
	if duration <= 0.0:
		return false
	unit[STATE_KEY] = {"remaining":duration,"source_id":source_id}
	return true

static func update(unit:Dictionary,delta:float) -> void:
	initialize(unit)
	unit[STATE_KEY]["remaining"] = maxf(0.0,float(unit[STATE_KEY].get("remaining",0.0))-maxf(0.0,delta))

static func is_active(unit:Dictionary) -> bool:
	return unit.get(STATE_KEY) is Dictionary and float(unit[STATE_KEY].get("remaining",0.0)) > 0.0

static func should_evade(target:Dictionary,source_action:String,hostile:bool=true,bypass:bool=false) -> bool:
	return hostile and not bypass and source_action == "basic_attack" and is_active(target)

static func miss_result(source_action:String="basic_attack",damage_type:String="physical") -> Dictionary:
	return {"amount":0.0,"raw_amount":0.0,"resolved_damage":0.0,"health_damage":0.0,"temporary_hp_damage":0.0,"shield_damage":0.0,"shield_absorptions":[],"overkill":0.0,"critical":false,"critical_multiplier":1.0,"damage_type":damage_type,"source_action":source_action,"result_category":"damage","armor":0.0,"armor_reduction":0.0,"armor_prevented":0.0,"defeated":false,"evaded":true}
