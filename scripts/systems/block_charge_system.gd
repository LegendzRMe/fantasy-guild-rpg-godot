extends RefCounted

static func initialize(unit:Dictionary,state_key:String="block_state",maximum:int=0) -> void:
	if not unit.get(state_key) is Dictionary:
		unit[state_key] = {"charges":0,"maximum":maxi(0,maximum)}
	else:
		unit[state_key]["maximum"] = maxi(0,maximum)
		unit[state_key]["charges"] = clampi(int(unit[state_key].get("charges",0)),0,maximum)

static func grant(unit:Dictionary,amount:int,maximum:int,state_key:String="block_state") -> int:
	initialize(unit,state_key,maximum)
	var before := int(unit[state_key].charges)
	unit[state_key].charges = mini(maximum,before+maxi(0,amount))
	return int(unit[state_key].charges)-before

static func charges(unit:Dictionary,state_key:String="block_state") -> int:
	return int(unit.get(state_key,{}).get("charges",0))

static func armor_source(unit:Dictionary,armor:float,source_id:String,state_key:String="block_state",physical_only:bool=false) -> Dictionary:
	if charges(unit,state_key) <= 0:
		return {}
	var result := {"id":source_id,"armor":armor,"source_action":"basic_attack","remaining":1.0}
	if physical_only:
		result["damage_type"] = "physical"
	return result

static func consume(unit:Dictionary,source_action:String,resolved_damage:float,evaded:bool=false,state_key:String="block_state") -> bool:
	if source_action != "basic_attack" or resolved_damage <= 0.0 or evaded or charges(unit,state_key) <= 0:
		return false
	unit[state_key].charges = int(unit[state_key].charges)-1
	return true

# Compatibility bridge for converted classes whose UI/tests still read the
# original integer field. Rules remain owned here while the legacy mirror is
# kept synchronized until those presentation consumers can migrate safely.
static func initialize_legacy(container:Dictionary,maximum:int,legacy_key:String="block_charges",state_key:String="block_state") -> void:
	var legacy:=clampi(int(container.get(legacy_key,0)),0,maximum)
	initialize(container,state_key,maximum);container[state_key].charges=legacy;container[legacy_key]=legacy

static func grant_legacy(container:Dictionary,amount:int,maximum:int,legacy_key:String="block_charges",state_key:String="block_state") -> int:
	initialize_legacy(container,maximum,legacy_key,state_key);var gained:=grant(container,amount,maximum,state_key);container[legacy_key]=charges(container,state_key);return gained

static func charges_legacy(container:Dictionary,maximum:int,legacy_key:String="block_charges",state_key:String="block_state") -> int:
	initialize_legacy(container,maximum,legacy_key,state_key);return charges(container,state_key)

static func armor_source_legacy(container:Dictionary,maximum:int,armor:float,source_id:String,legacy_key:String="block_charges",state_key:String="block_state",physical_only:bool=false) -> Dictionary:
	initialize_legacy(container,maximum,legacy_key,state_key);return armor_source(container,armor,source_id,state_key,physical_only)

static func consume_legacy(container:Dictionary,maximum:int,source_action:String,resolved_damage:float,evaded:bool=false,legacy_key:String="block_charges",state_key:String="block_state") -> bool:
	initialize_legacy(container,maximum,legacy_key,state_key);var consumed:=consume(container,source_action,resolved_damage,evaded,state_key);container[legacy_key]=charges(container,state_key);return consumed
