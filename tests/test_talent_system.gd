extends RefCounted

const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:Array=[]
	var definition:={"heroic_option_ids":["heroic_a","heroic_b"],"talent_tier_definitions":[
		{"tier_id":"tier_1","option_ids":["talent_a","talent_b"]},
		{"tier_id":"tier_3","option_ids":[]},
		{"tier_id":"tier_7","option_ids":[],"heroic_requirements":{}}
	]}
	var hero:={"level":9,"selected_talents":{},"planned_talents":{},"selected_heroic_id":""}
	var planned:=TalentSystem.plan_option(hero,definition,"tier_1","talent_a")
	planned=TalentSystem.plan_option(planned,definition,"tier_1","talent_b")
	TestSupport.check(errors,planned.planned_talents=={"tier_1":"talent_b"} and hero.planned_talents.is_empty(),"A Hero should have one freely replaceable planned talent per tier without mutating the source hero.")
	var selected:=TalentSystem.select_option(planned,definition,"tier_1","talent_a")
	TestSupport.check(errors,selected.success and selected.hero.selected_talents.tier_1=="talent_a" and not selected.hero.planned_talents.has("tier_1"),"Selecting a talent should clear that Hero's obsolete heart for the tier.")
	TestSupport.check(errors,not TalentSystem.validate_selection({"level":8},definition,"tier_1","talent_a").valid,"Talent choices should validate their level milestone.")
	var heroic_hero:={"level":27,"selected_talents":{},"planned_talents":{},"selected_heroic_id":"heroic_a"}
	TestSupport.check(errors,TalentSystem.validate_selection(heroic_hero,definition,"tier_7","heroic_a_upgrade").valid and not TalentSystem.validate_selection(heroic_hero,definition,"tier_7","heroic_b_upgrade").valid,"Level 27 upgrades should correspond to the selected Level 15 Heroic.")
	var cleared:=TalentSystem.clear_all(selected.hero)
	TestSupport.check(errors,cleared.selected_talents.is_empty() and cleared.selected_heroic_id=="","Talent selections should clear without corrupting the source Hero.")
	var discovery:=TalentSystem.record_class_discovery({},"guardian",27)
	discovery=TalentSystem.record_class_discovery(discovery,"guardian",3)
	TestSupport.check(errors,discovery.guardian==27 and TalentSystem.tier_is_revealed(discovery,"guardian","tier_7") and not TalentSystem.tier_is_revealed(discovery,"cleric","tier_1"),"Talent discovery should be permanent, guild-wide, and isolated by class.")
	TestSupport.check(errors,TalentSystem.ability_is_unlocked(1,0) and not TalentSystem.ability_is_unlocked(2,1) and TalentSystem.ability_is_unlocked(3,1) and TalentSystem.ability_is_unlocked(6,2) and TalentSystem.ability_is_unlocked(15,3),"Q, W, E, and Heroic availability should follow Levels 1, 3, 6, and 15.")
	return errors
