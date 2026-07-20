extends RefCounted

const AshwoodData = preload("res://scripts/data/ashwood_data.gd")
const AshwoodManager = preload("res://scripts/systems/ashwood_manager.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var progress:=AshwoodManager.default_progress()
	TestSupport.check(errors,AshwoodData.MANDATORY_ORDER.size()==7 and AshwoodData.OPTIONAL_ORDER.size()==2,"Ashwood should define seven mandatory and two optional encounters.")
	var opening:Dictionary=AshwoodData.ENCOUNTERS.first_battle
	var opening_roles:Array=[]
	for wave in opening.waves:opening_roles.append_array(wave)
	TestSupport.check(errors,opening_roles.size()>=13,"The first Ashwood battle should use a larger enemy count to encourage movement without making each regular attacker disposable.")
	TestSupport.check(errors,opening_roles.find("Swift") in [2,3],"The Swift should be the third or fourth enemy in the first Ashwood battle.")
	TestSupport.check(errors,opening_roles.count("Swift")==2 and float(opening.enemy_health_overrides.Swift)==GameData.CLASSES.Guardian.base_power*GameData.CLASSES.Guardian.basic_action_power_coefficient*2.0,"Encounter 1 should contain two Swifts that fall to two founding-Guardian hits.")
	TestSupport.check(errors,float(opening.enemy_health_overrides.Raider)==GameData.CLASSES.Guardian.base_power*GameData.CLASSES.Guardian.basic_action_power_coefficient*5.0 and float(opening.enemy_health_overrides.Archer)==GameData.CLASSES.Guardian.base_power*GameData.CLASSES.Guardian.basic_action_power_coefficient*5.0,"Regular Encounter 1 enemies should take about five founding-Guardian hits.")
	TestSupport.check(errors,opening_roles.count("Stalker")==1 and float(opening.enemy_health_overrides.Stalker)<=GameData.CLASSES.Guardian.base_power*GameData.CLASSES.Guardian.basic_action_power_coefficient,"Encounter 1 should introduce exactly one very weak Tank-ignoring Stalker.")
	TestSupport.check(errors,bool(GameData.ENEMIES.Swift.prefers_backline) and not bool(GameData.ENEMIES.Swift.get("ignores_tank_aggro",false)),"Swifts should enter toward the backline while remaining responsive to Tank aggro.")
	TestSupport.check(errors,bool(GameData.ENEMIES.Stalker.prefers_backline) and bool(GameData.ENEMIES.Stalker.ignores_tank_aggro) and float(GameData.ENEMIES.Stalker.base_power)<16.0,"Stalkers should use the distinct backline Fixate behavior that ignores Tank aggro while remaining a weak attacker.")
	TestSupport.check(errors,opening.waves[-1].count("Brute")>=1,"Encounter 1 should finish with stronger enemies that encourage ability use.")
	TestSupport.check(errors,bool(opening.spawn_all_sides),"Encounter 1 should bring enemies in around the battlefield to encourage movement.")
	TestSupport.check(errors,float(opening.spawn_interval)>=1.5,"Encounter 1 enemies should enter with enough spacing to make each attacker readable within its wave.")
	TestSupport.check(errors,float(opening.enemy_health_multiplier)<1.0,"The opening battle should retain its reduced enemy health.")
	for encounter_id in AshwoodData.MANDATORY_ORDER:
		if encounter_id=="first_battle":continue
		TestSupport.check(errors,int(opening.first_rewards.gold)<int(AshwoodData.ENCOUNTERS[encounter_id].first_rewards.gold) and int(opening.first_rewards.xp)<int(AshwoodData.ENCOUNTERS[encounter_id].first_rewards.xp),"The opening battle should award less XP and gold than %s."%encounter_id)
	for encounter_id in AshwoodData.all_encounter_ids():
		var encounter:=AshwoodData.encounter(encounter_id,progress)
		TestSupport.check(errors,encounter.has_all(["id","display_name","map_position","scenario","objective","waves","first_rewards","repeat_rewards"]),"%s should keep its runtime content configurable in Ashwood data."%encounter_id)
		TestSupport.check(errors,str(encounter.get("replay_scenario",""))!="" and str(encounter.replay_scenario)!=str(encounter.scenario),"%s should frame repeat battles as a related aftermath rather than replaying the original story."%encounter_id)
	TestSupport.check(errors,AshwoodData.ENCOUNTERS.raider_cache.story_moments.size()>=2 and AshwoodData.ENCOUNTERS.second_recruit.story_moments.size()>=1 and AshwoodData.ENCOUNTERS.crossing.story_moments.size()>=1,"Mandatory encounters should foreshadow all three lost-party survivors before the permanent choice.")
	var visual_identities:={}
	for candidate in AshwoodData.SPECIAL_HEROES.values():visual_identities[candidate.visual_identity]=true
	TestSupport.check(errors,visual_identities.size()==3,"Special Hero candidates should define distinct visual identities.")
	TestSupport.check(errors,AshwoodManager.encounter_is_unlocked(progress,"first_battle"),"The first Ashwood encounter should begin unlocked.")
	for encounter_id in AshwoodData.all_encounter_ids():
		if encounter_id!="first_battle":TestSupport.check(errors,not AshwoodManager.encounter_is_unlocked(progress,encounter_id),"%s should begin hidden."%encounter_id)
	var decision:=AshwoodManager.apply_decision(progress,"first_battle","rogue_path")
	TestSupport.check(errors,progress.first_recruit_choice=="rogue" and AshwoodManager.encounter_is_unlocked(progress,"first_recruit"),"The first narrative decision should save its recruit path and reveal Encounter 2.")
	TestSupport.check(errors,str(decision.consequence)!="","Narrative decisions should provide consequence text from data.")
	AshwoodManager.mark_victory(progress,"first_battle")
	TestSupport.check(errors,AshwoodManager.encounter_is_completed(progress,"first_battle") and progress.encounters.first_battle.replay_count==1,"Victories should make encounters replayable and count clears.")
	AshwoodManager.mark_victory(progress,"first_battle")
	TestSupport.check(errors,progress.encounters.first_battle.replay_count==2,"Replays should increase without resetting story progress.")
	progress.optional_available=true
	TestSupport.check(errors,AshwoodManager.discover_optional_branch(progress) and AshwoodManager.encounter_is_unlocked(progress,"ruined_chapel"),"The optional branch should reveal only after discovery.")
	AshwoodManager.mark_victory(progress,"ruined_chapel")
	TestSupport.check(errors,AshwoodManager.encounter_is_unlocked(progress,"rune_servant"),"The chapel clear should reveal its optional mini-boss.")
	var testing:=AshwoodManager.testing_progress()
	for encounter_id in AshwoodData.all_encounter_ids():TestSupport.check(errors,AshwoodManager.encounter_is_completed(testing,encounter_id),"Testing progress should complete %s."%encounter_id)
	return errors
