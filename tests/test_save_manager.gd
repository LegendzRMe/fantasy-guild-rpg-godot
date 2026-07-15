extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var live:=SaveManager.fresh_state()
	TestSupport.check(errors,live.guild_name=="","Live saves should start without a guild name.")
	TestSupport.check(errors,live.gold==0,"Live saves should start with zero gold.")
	TestSupport.check(errors,live.tutorial_complete==false,"Live saves should enter the tutorial.")
	TestSupport.check(errors,live.major_systems_unlocked==false,"Live saves should begin with major guild systems locked.")
	TestSupport.check(errors,live.seen_page_intros.is_empty(),"New guilds should begin with no Guild Hall page introductions dismissed.")
	TestSupport.check(errors,live.heroes.size()==2,"Live saves should start with two heroes.")
	TestSupport.check(errors,live.heroes[0].name=="Brann" and live.heroes[1].name=="Sera","Live saves should start with Brann and Sera.")
	TestSupport.check(errors,live.selected_team==[0,1] and live.active_team==[0,1],"Live saves should start with the two founding heroes selected.")
	TestSupport.check(errors,live.zone0.encounters.first_battle.unlocked and not live.zone0.encounters.first_recruit.unlocked,"A live Ashwood save should reveal only its first encounter.")

	var testing:=SaveManager.testing_state()
	TestSupport.check(errors,testing.guild_name=="Testing Guild","The testing slot should have a stable guild name.")
	TestSupport.check(errors,testing.tutorial_complete==true,"The testing slot should skip the tutorial.")
	TestSupport.check(errors,testing.major_systems_unlocked==true,"The testing slot should keep major guild systems unlocked.")
	TestSupport.check(errors,testing.heroes.size()==9,"The testing slot should include all current normal recruits and Special Hero candidates.")
	TestSupport.check(errors,testing.heroes.slice(0,4).map(func(hero):return hero["class"])==["Guardian","Cleric","Ranger","Mage"],"The testing slot should preserve its established active testing party.")
	TestSupport.check(errors,testing.selected_team==[0,1,2,3] and testing.active_team==[0,1,2,3],"The testing slot should select all four heroes.")
	TestSupport.check(errors,testing.zone0.zone0_boss_defeated and testing.zone0.party_management_unlocked,"The testing slot should include completed Ashwood progression.")
	TestSupport.check(errors,testing.zone_progress==[10,10] and testing.zone_branches==[[true,true],[true,true]],"The testing slot should unlock current zone progression.")
	TestSupport.check(errors,testing.unlocked_dungeon==1 and testing.vault_level==6 and testing.vault_limit==180,"The testing slot should unlock current dungeon and storage gates.")
	TestSupport.check(errors,SaveManager.save_slot_path(3)=="user://guild_save_4.json","The testing slot should use the independent fourth save path.")

	testing.casting_settings.pc.ground="confirm"
	TestSupport.check(errors,live.casting_settings.pc.ground=="cursor","Fresh save dictionaries should not share casting settings.")

	var legacy:=SaveManager.fresh_state()
	legacy.guild_name="Legacy Guild"
	legacy.erase("active_team")
	legacy.erase("saved_teams")
	legacy.erase("team_names")
	legacy.erase("zone_progress")
	legacy.erase("zone_branches")
	legacy.erase("guild_prestige_rank")
	legacy.erase("guild_renown")
	legacy.erase("faction")
	legacy.erase("major_systems_unlocked")
	legacy.erase("seen_page_intros")
	legacy.erase("casting_settings")
	for hero in legacy.heroes:
		hero.erase("member_type")
		hero.erase("is_special_hero")
		hero.erase("legacy_rank")
	var migrated:=SaveManager.migrate_state(legacy,false)
	TestSupport.check(errors,migrated.tutorial_complete==true,"Guild saves without a tutorial field should retain legacy completion behavior.")
	TestSupport.check(errors,migrated.zone0.heroes_unlocked,"Completed legacy tutorials should unlock Heroes.")
	TestSupport.check(errors,migrated.active_team==migrated.selected_team,"Legacy saves should receive an active team.")
	TestSupport.check(errors,migrated.saved_teams.size()==5 and migrated.team_names.size()==5,"Legacy saves should receive saved-team defaults.")
	TestSupport.check(errors,migrated.has("casting_settings"),"Legacy saves should receive casting defaults.")
	TestSupport.check(errors,migrated.major_systems_unlocked==false,"Legacy two-hero live saves should use the current locked progression state.")
	TestSupport.check(errors,migrated.seen_page_intros.is_empty(),"Legacy saves should receive compatible first-visit page-introduction tracking.")
	TestSupport.check(errors,migrated.heroes[0].has("member_type") and migrated.heroes[0].has("is_special_hero") and migrated.heroes[0].has("legacy_rank"),"Legacy heroes should receive compatibility fields.")
	var legacy_testing:=SaveManager.testing_state()
	legacy_testing.erase("major_systems_unlocked")
	legacy_testing=SaveManager.migrate_state(legacy_testing,true)
	TestSupport.check(errors,legacy_testing.major_systems_unlocked==true,"Legacy four-hero testing saves should remain fully usable.")

	if OS.get_environment("WOW_BATTLEHEART_TEST_MODE")=="1":
		var live_test_slot:=98
		var testing_test_slot:=99
		live.guild_name="Persistence Test"
		testing.casting_settings.pc.ground="release"
		SaveManager.save_state(live_test_slot,live)
		SaveManager.save_state(testing_test_slot,testing)
		TestSupport.check(errors,SaveManager.load_state(live_test_slot).guild_name=="Persistence Test","Live save persistence should round-trip.")
		TestSupport.check(errors,SaveManager.load_state(testing_test_slot).casting_settings.pc.ground=="release","Casting preferences should persist per save.")
		SaveManager.delete_slot(live_test_slot)
		SaveManager.delete_slot(testing_test_slot)
		TestSupport.check(errors,not FileAccess.file_exists(SaveManager.save_slot_path(live_test_slot)) and not FileAccess.file_exists(SaveManager.save_slot_path(testing_test_slot)),"Test saves should delete cleanly.")
	else:
		errors.append("Save persistence tests require WOW_BATTLEHEART_TEST_MODE=1 and isolated APPDATA.")
	return errors
