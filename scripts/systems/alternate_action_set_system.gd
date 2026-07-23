extends RefCounted

static func initialize(owner:Dictionary, sets:Dictionary, default_set:String="normal") -> void:
	owner["action_sets"]=sets.duplicate(true);owner["active_action_set"]=default_set
	owner["alternate_cooldowns"]=owner.get("alternate_cooldowns",{}).duplicate(true)

static func activate(owner:Dictionary, set_id:String) -> bool:
	if not owner.get("action_sets",{}).has(set_id):return false
	owner.active_action_set=set_id;return true

static func ability_id(owner:Dictionary, slot:int) -> String:
	var mapping:Dictionary=owner.get("action_sets",{}).get(str(owner.get("active_action_set","normal")),{})
	return str(mapping.get(slot,mapping.get(str(slot),"")))

static func update_hidden_cooldowns(owner:Dictionary,delta:float) -> void:
	for key in owner.get("alternate_cooldowns",{}):owner.alternate_cooldowns[key]=maxf(0.0,float(owner.alternate_cooldowns[key])-delta)
