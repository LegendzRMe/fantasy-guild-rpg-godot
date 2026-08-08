extends RefCounted

const EntitySchema = preload("res://scripts/systems/entity_schema.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var state:=SaveManager.testing_state()
	TestSupport.check(errors,state.heroes.all(func(hero):return EntitySchema.hero_errors(hero).is_empty()),"Canonical guild Heroes should satisfy their entity schema.")
	TestSupport.check(errors,state.item_instances.all(func(item):return EntitySchema.inventory_entry_errors(item).is_empty()),"Canonical equipment instances should satisfy their entity schema.")
	TestSupport.check(errors,not EntitySchema.hero_errors({"hero_id":"","level":0}).is_empty(),"Malformed Hero records should produce focused schema errors.")
	TestSupport.check(errors,not EntitySchema.inventory_entry_errors({"instance_id":"","is_material":true,"quantity":0}).is_empty(),"Malformed material records should produce focused schema errors.")
	var source:={"combat_id":"hero:1","hp":100.0,"max_hp":100.0,"pos":Vector2.ZERO}
	var target:={"combat_id":"enemy:1","hp":80.0,"max_hp":100.0,"pos":Vector2.ONE}
	var event:=CombatSystem.create_event("damage_dealt",source,target,{"resolved_damage":20.0,"source_action":"basic_attack","result_category":"damage"})
	TestSupport.check(errors,EntitySchema.combat_unit_errors(source).is_empty() and EntitySchema.combat_event_errors(event).is_empty(),"Canonical combat units and events should satisfy reusable runtime schemas.")
	TestSupport.check(errors,not EntitySchema.combat_event_errors({}).is_empty(),"Malformed combat events should produce focused schema errors.")
	return errors
