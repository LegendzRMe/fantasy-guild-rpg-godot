extends RefCounted

const ClericData = preload("res://scripts/data/cleric_data.gd")
const ClericSystem = preload("res://scripts/systems/cleric_system.gd")
const ClericAbilityPresenter = preload("res://scripts/data/cleric_ability_presenter.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func cleric(talents:Array=[])->Dictionary:
	var selected:Dictionary={}
	for index in talents.size():selected["tier_%d"%(index+1)]=talents[index]
	var hero:={"class":"Cleric","level":1,"power":60.0,"hp":1500.0,"max_hp":1500.0,"selected_talents":selected,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"active_effects":[]}
	ClericSystem.initialize_runtime(hero,true)
	return hero

static func run()->Array:
	var errors:=[];var definition:Dictionary=ClericData.CLASS_DEFINITION
	TestSupport.check(errors,definition.base_health==1500.0 and definition.base_power==60.0 and definition.basic_action_interval==0.8 and definition.basic_action_type=="heal","Cleric V1 should expose the locked Level 1 healer chassis and 1.25 actions-per-second cadence.")
	var tier_three:=TalentSystem.tier_definition(definition,"tier_3");var tier_seven:=TalentSystem.tier_definition(definition,"tier_7")
	TestSupport.check(errors,tier_three.option_ids==["cleric_l15_r1","cleric_l15_r2"] and tier_seven.heroic_requirements.cleric_l27_r2=="cleric_l15_r2","Cleric Heroics and matching Level 27 upgrades should remain data-driven.")
	var selection_hero:={"level":30,"selected_talents":{},"selected_heroic_id":"","planned_talents":{}};var heroic_selection:=TalentSystem.select_option(selection_hero,definition,"tier_3","cleric_l15_r2");var legal_upgrade:=TalentSystem.select_option(heroic_selection.hero,definition,"tier_7","cleric_l27_r2");var illegal_upgrade:=TalentSystem.validate_selection(heroic_selection.hero,definition,"tier_7","cleric_l27_r1")
	TestSupport.check(errors,heroic_selection.success and legal_upgrade.success and not illegal_upgrade.valid and ClericData.ACTION_KEYS==["D","Q","W","E","R"],"Cleric talent selection should enforce matching Heroic upgrades without creating extra combat inputs.")
	var hero:=cleric();ClericSystem.note_hostile_damage(hero,10.0)
	TestSupport.check(errors,ClericSystem.fast_feet_active(hero) and ClericSystem.movement_multiplier(hero)==1.10 and ClericSystem.qwe_cooldown_rate(hero)==1.5,"Positive hostile damage should activate baseline Fast Feet.")
	ClericSystem.update_timers(hero,1.1)
	TestSupport.check(errors,not ClericSystem.fast_feet_active(hero),"Fast Feet should expire through pause-safe simulation delta updates.")
	var eager:=cleric(["cleric_l9_3"]);ClericSystem.note_hostile_damage(eager,1.0);ClericSystem.update_timers(eager,2.0)
	TestSupport.check(errors,ClericSystem.fast_feet_active(eager),"Eager Adventurer should extend Fast Feet to 2.5 seconds.")
	var hustle:=cleric(["cleric_l9_2","cleric_l12_1","cleric_r1","cleric_l18_1","cleric_l21_1","cleric_l24_1","cleric_l27_r1","cleric_l30_3"]);ClericSystem.trigger_fast_feet(hustle)
	TestSupport.check(errors,ClericSystem.qwe_cooldown_rate(hustle)==3.0 and ClericSystem.w_cooldown_rate(hustle)==3.75,"Kung Fu Hustle and Serpent Sidekick should use the specified non-stacking cooldown rates.")
	var allies:=[{"hp":40.0,"max_hp":100.0,"pos":Vector2(10,0),"combat_id":"b"},{"hp":40.0,"max_hp":100.0,"pos":Vector2(10,0),"combat_id":"a"},{"hp":100.0,"max_hp":100.0,"pos":Vector2.ZERO,"combat_id":"c"}]
	TestSupport.check(errors,ClericSystem.lowest_wounded_indices(allies,2,Vector2.ZERO,100.0)==[1,0],"Automatic Cleric targeting should deterministically break equal Health and distance ties by stable combat ID.")
	var details:=ClericAbilityPresenter.details(hero,"E")
	TestSupport.check(errors,str(details.description).contains("133") and not str(details.description).contains("133."),"Cleric roster details should show current whole-number damage without decimal noise.")
	var safety:=cleric(["cleric_l9_1","cleric_l12_2"]);var lets_go:=cleric(["cleric_l9_1","cleric_l12_3"])
	TestSupport.check(errors,ClericAbilityPresenter.details(safety,"D").title=="Safety Sprint" and ClericAbilityPresenter.details(lets_go,"D").title=="Let's Go!","The roster should present the selected Level 12 Trait action in D without adding a new slot.")
	var marker_cleric:=cleric();marker_cleric.combat_id="cleric:marker";marker_cleric.cleric_runtime.serpents=[{"host_id":"hero:host","remaining":8.0},{"host_id":"hero:host","remaining":4.0},{"host_id":"hero:other","remaining":8.0},{"host_id":"hero:host","remaining":0.0}]
	TestSupport.check(errors,ClericSystem.active_serpent_count([marker_cleric],"hero:host")==2,"Cloud Serpent presentation should count only currently active Serpents attached to the displayed ally.")
	return errors
