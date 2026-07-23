extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run() -> Array:
	var errors:=[]
	var live:=SaveManager.fresh_state()
	TestSupport.check(errors,live.guild_name=="","Live saves should start without a guild name.")
	TestSupport.check(errors,live.gold==0,"Live saves should start with zero gold.")
	TestSupport.check(errors,live.prestige_tokens==0 and not live.has("tokens"),"Guild saves should expose only Gold and Prestige Tokens as currencies.")
	TestSupport.check(errors,live.tutorial_complete==false,"Live saves should enter the tutorial.")
	TestSupport.check(errors,live.major_systems_unlocked==false,"Live saves should begin with major guild systems locked.")
	TestSupport.check(errors,live.seen_page_intros.is_empty(),"New guilds should begin with no Guild Hall page introductions dismissed.")
	TestSupport.check(errors,live.heroes.size()==2,"Live saves should start with two heroes.")
	TestSupport.check(errors,live.heroes[0].name=="Brann" and live.heroes[1].name=="Sera","Live saves should start with Brann and Sera.")
	TestSupport.check(errors,live.heroes.all(func(hero):return hero.identity_type=="standard" and hero.can_edit_name and hero.can_edit_appearance),"Founding Standard Heroes should have editable identities.")
	TestSupport.check(errors,live.selected_team==[0,1] and live.active_team==[0,1],"Live saves should start with the two founding heroes selected.")
	TestSupport.check(errors,live.zone0.encounters.first_battle.unlocked and not live.zone0.encounters.first_recruit.unlocked,"A live Ashwood save should reveal only its first encounter.")

	var testing:=SaveManager.testing_state()
	TestSupport.check(errors,testing.guild_name=="Testing Guild","The testing slot should have a stable guild name.")
	TestSupport.check(errors,testing.tutorial_complete==true,"The testing slot should skip the tutorial.")
	TestSupport.check(errors,testing.major_systems_unlocked==true,"The testing slot should keep major guild systems unlocked.")
	TestSupport.check(errors,testing.heroes.size()==9,"The testing slot should include all current normal recruits and Special Hero candidates.")
	TestSupport.check(errors,GameData.CLASSES.keys().all(func(hero_class):return testing.heroes.any(func(hero):return str(hero.get("class",""))==str(hero_class))),"The testing slot should include at least one hero for every registered class.")
	TestSupport.check(errors,testing.heroes.slice(0,6).all(func(hero):return hero.prestige_rank==0) and testing.heroes.slice(6).all(func(hero):return hero.prestige_rank==1),"Normal heroes should begin at Prestige 0 while current Special Heroes begin at Prestige 1.")
	TestSupport.check(errors,testing.heroes.slice(6).all(func(hero):return hero.identity_type=="special" and not hero.can_edit_name and not hero.can_edit_appearance),"Special Heroes should preserve authored, non-editable identities.")
	TestSupport.check(errors,testing.class_talent_discovery.values().all(func(level):return int(level)==30),"The testing guild should reveal every current class talent tree.")
	TestSupport.check(errors,testing.heroes.slice(0,4).map(func(hero):return hero["class"])==["Guardian","Cleric","Ranger","Mage"],"The testing slot should preserve its established active testing party.")
	TestSupport.check(errors,testing.selected_team==[0,1,2,3] and testing.active_team==[0,1,2,3],"The testing slot should select all four heroes.")
	TestSupport.check(errors,testing.zone0.zone0_boss_defeated and testing.zone0.party_management_unlocked,"The testing slot should include completed Ashwood progression.")
	TestSupport.check(errors,testing.zone_progress==[10,10] and testing.zone_branches==[[true,true],[true,true]],"The testing slot should unlock current zone progression.")
	TestSupport.check(errors,testing.unlocked_dungeon==1 and testing.vault_level==6 and testing.vault_limit==180,"The testing slot should unlock current dungeon and storage gates.")
	TestSupport.check(errors,testing.item_instances.size()==10 and testing.item_instances.all(func(item):return item.testing_only and item.owner_state=="vault" and item.equipped_hero_index==-1) and testing.heroes.all(func(hero):return hero.equipment_slots.values().all(func(value):return value==null)),"The testing guild should seed the ten Legendary test items without auto-equipping them.")
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
	legacy["tokens"]=37
	legacy.erase("prestige_tokens")
	legacy.erase("class_talent_discovery")
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
	TestSupport.check(errors,migrated.prestige_tokens==0 and not migrated.has("tokens"),"Legacy generic tokens should be discarded rather than converted into a real currency.")
	TestSupport.check(errors,migrated.major_systems_unlocked==false,"Legacy two-hero live saves should use the current locked progression state.")
	TestSupport.check(errors,migrated.seen_page_intros.is_empty(),"Legacy saves should receive compatible first-visit page-introduction tracking.")
	TestSupport.check(errors,migrated.heroes[0].has("hero_id") and migrated.heroes[0].has("class_id") and migrated.heroes[0].has("selected_talents") and migrated.heroes[0].has("planned_talents") and migrated.heroes[0].has("prestige_reward_history") and migrated.heroes[0].has("profession_progress") and migrated.heroes[0].has("pvp_progress"),"Legacy Heroes should receive identity, talent, Prestige, profession, and PvP foundation fields.")
	var malformed:=SaveManager.fresh_state();malformed.heroes="invalid";malformed.selected_team={};malformed.casting_settings=[];malformed.zone0="invalid"
	var repaired:=SaveManager.migrate_state(malformed,true)
	TestSupport.check(errors,repaired.heroes is Array and repaired.heroes.size()==2 and repaired.selected_team is Array and repaired.casting_settings is Dictionary and repaired.zone0 is Dictionary,"Migration should repair valid JSON containing invalid core field types.")
	var legacy_testing:=SaveManager.testing_state()
	legacy_testing.erase("major_systems_unlocked")
	legacy_testing.heroes=legacy_testing.heroes.filter(func(hero):return str(hero.get("class",""))!="Warlock" and str(hero.get("name",""))!="Ilyra Voss")
	legacy_testing.item_instances.append({"instance_id":"test_ashwood_bulwark","definition_id":"ashwood_bulwark","owner_state":"equipped","equipped_hero_index":0})
	legacy_testing.heroes[0].equipment_slots.chest="test_ashwood_bulwark"
	legacy_testing=SaveManager.migrate_state(legacy_testing,true)
	TestSupport.check(errors,legacy_testing.major_systems_unlocked==true,"Legacy four-hero testing saves should remain fully usable.")
	TestSupport.check(errors,legacy_testing.heroes.size()==9 and legacy_testing.heroes.any(func(hero):return str(hero.get("class",""))=="Warlock") and legacy_testing.heroes.any(func(hero):return str(hero.get("name",""))=="Ilyra Voss"),"Legacy testing saves should automatically receive every current testing hero and class without duplicating existing heroes.")
	TestSupport.check(errors,legacy_testing.item_instances.size()==10 and legacy_testing.item_instances.all(func(item):return item.definition_id in ItemData.TESTING_DEFINITION_IDS),"Legacy testing saves should replace obsolete prototype items with exactly the current ten Legendary definitions.")
	TestSupport.check(errors,legacy_testing.heroes[0].equipment_slots.chest==null,"Removing an obsolete testing item should safely clear its old equipment reference.")

	if OS.get_environment("WOW_BATTLEHEART_TEST_MODE")=="1":
		var live_test_slot:=98
		var testing_test_slot:=99
		live.guild_name="Persistence Test"
		testing.casting_settings.pc.ground="release"
		SaveManager.save_state(live_test_slot,live)
		live.guild_name="Persistence Test Updated"
		SaveManager.save_state(live_test_slot,live)
		var live_file:=FileAccess.open(SaveManager.save_slot_path(live_test_slot),FileAccess.WRITE);live_file.store_string("{broken json");live_file.close()
		TestSupport.check(errors,SaveManager.load_state(live_test_slot).guild_name=="Persistence Test","A malformed live save should recover from the last verified backup.")
		SaveManager.save_state(testing_test_slot,testing)
		TestSupport.check(errors,SaveManager.load_state(testing_test_slot).casting_settings.pc.ground=="release","Casting preferences should persist per save.")
		TestSupport.check(errors,SaveManager.load_state(testing_test_slot).item_instances.size()==10 and SaveManager.load_state(testing_test_slot).heroes[0].equipment_slots.values().all(func(value):return value==null),"Testing item instances and unequipped ownership should round-trip through JSON saves.")
		SaveManager.delete_slot(live_test_slot)
		SaveManager.delete_slot(testing_test_slot)
		TestSupport.check(errors,not FileAccess.file_exists(SaveManager.save_slot_path(live_test_slot)) and not FileAccess.file_exists(SaveManager.save_slot_path(testing_test_slot)),"Test saves should delete cleanly.")
	else:
		errors.append("Save persistence tests require WOW_BATTLEHEART_TEST_MODE=1 and isolated APPDATA.")
	return errors
