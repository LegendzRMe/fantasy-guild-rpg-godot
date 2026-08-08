extends RefCounted

const EntitySchema = preload("res://scripts/systems/entity_schema.gd")

const ARRAY_FIELDS := [
	"heroes","selected_team","active_team","saved_teams","team_names",
	"zone_progress","zone_branches","item_instances","material_stacks"
]
const DICTIONARY_FIELDS := [
	"component_versions","seen_page_intros","codex_seen_entries",
	"casting_settings","zone0","campaign","class_talent_discovery","tavern_facility","cooking","tavern_management"
]
const NON_NEGATIVE_INTEGER_FIELDS := [
	"gold","prestige_tokens","guild_renown","next_item_instance_id",
	"next_material_stack_id","next_profession_order_id"
]

static func repair_root(state:Dictionary,defaults:Dictionary)->void:
	for key in ARRAY_FIELDS:
		if not state.get(key) is Array:state[key]=defaults[key].duplicate(true)
	for key in DICTIONARY_FIELDS:
		if not state.get(key) is Dictionary:state[key]=defaults[key].duplicate(true)
	for key in NON_NEGATIVE_INTEGER_FIELDS:
		state[key]=maxi(0,int(state.get(key,defaults.get(key,0))))
	state["guild_name"]=str(state.get("guild_name",defaults.guild_name))

static func validation_errors(state:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	for key in ARRAY_FIELDS:
		if not state.get(key) is Array:errors.append("%s must be an Array."%key)
	for key in DICTIONARY_FIELDS:
		if not state.get(key) is Dictionary:errors.append("%s must be a Dictionary."%key)
	for key in ["heroes","item_instances","material_stacks"]:
		if state.get(key) is Array and not state[key].all(func(entry):return entry is Dictionary):errors.append("%s contains a non-Dictionary record."%key)
	if str(state.get("guild_name",""))!=state.get("guild_name",""):errors.append("guild_name must be a String.")
	for index in state.get("heroes",[]).size():
		for message in EntitySchema.hero_errors(state.heroes[index]):errors.append("heroes[%d]: %s"%[index,message])
	for key in ["item_instances","material_stacks"]:
		for index in state.get(key,[]).size():
			for message in EntitySchema.inventory_entry_errors(state[key][index]):errors.append("%s[%d]: %s"%[key,index,message])
	for index in state.get("profession_orders",[]).size():
		for message in EntitySchema.profession_order_errors(state.profession_orders[index]):errors.append("profession_orders[%d]: %s"%[index,message])
	if state.get("recruitment") is Dictionary:
		for index in state.recruitment.get("candidates",[]).size():
			for message in EntitySchema.recruitment_candidate_errors(state.recruitment.candidates[index]):errors.append("recruitment.candidates[%d]: %s"%[index,message])
	return errors
