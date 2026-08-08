extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	main.show_hall();await main.get_tree().process_frame
	main.guild_hall_debug_open=true;main.show_hall();await main.get_tree().process_frame
	var build_metadata:Label=main.ui.find_child("BuildMetadataLabel",true,false)
	var performance_snapshot:Label=main.ui.find_child("PerformanceSnapshotLabel",true,false)
	TestSupport.check(errors,build_metadata!=null and "Version" in build_metadata.text and "Build" in build_metadata.text,"Testing tools should identify the running project version and build.")
	TestSupport.check(errors,performance_snapshot!=null and "FPS" in performance_snapshot.text and "Objects" in performance_snapshot.text and "Draw calls" in performance_snapshot.text,"Testing tools should expose a lightweight runtime performance snapshot.")
	main.guild_hall_debug_open=false
	main.show_roster();await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingHeroLevel",true,false)!=null,"The testing Hero Roster should expose the hero level picker.")
	main.set_testing_hero_level(0,12.0)
	TestSupport.check(errors,int(main.state.heroes[0].level)==12,"The testing hero level picker should persist the selected level.")
	main.current_save_slot=0;main.set_testing_hero_level(0,20.0)
	TestSupport.check(errors,int(main.state.heroes[0].level)==12,"Live save slots must not be able to invoke the testing level tool directly.")
	main.show_roster();await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingHeroLevel",true,false)==null,"The hero level picker must remain hidden in live save slots.")
	main.show_dungeons();await main.get_tree().process_frame
	TestSupport.check(errors,main.ui.find_child("TestingResetStoryButton",true,false)==null,"The story reset tool must remain hidden in live save slots.")
	main.current_save_slot=3
	InventorySystem.add_equipment(main.state,ItemData.create_instance("pinewatch_bow","testing_preserved_item"))
	main.state.zone0.next_item_id=42
	var testing_gold_before:int=int(main.state.gold)
	var testing_roster_size_before:int=main.state.heroes.size()
	main.reset_testing_ashwood_story()
	TestSupport.check(errors,main.screen=="zone_map" and main.state.zone0.encounters.first_battle.unlocked,"Reset Story should return to a fresh Ashwood map with the opening battle available.")
	TestSupport.check(errors,not main.state.zone0.zone0_boss_defeated and str(main.state.zone0.first_recruit_choice)=="" and not main.state.zone0.encounters.first_recruit.unlocked,"Reset Story should clear boss completion, decisions, and later encounter unlocks.")
	TestSupport.check(errors,not InventorySystem.entry_by_id(main.state,"testing_preserved_item").is_empty() and main.state.zone0.inventory.is_empty() and int(main.state.zone0.next_item_id)==42,"Reset Story should preserve unified Item Storage and the Ashwood item identifier sequence without restoring the retired inventory list.")
	TestSupport.check(errors,main.state.heroes.size()==testing_roster_size_before and int(main.state.heroes[0].level)==12 and int(main.state.gold)==testing_gold_before,"Reset Story should preserve testing heroes, chosen levels, and guild resources.")
	TestSupport.check(errors,main.state.selected_team==[0,1] and main.state.active_team==[0,1],"Reset Story should restore Brann and Sera as the story-testing party.")
	TestSupport.check(errors,FileAccess.file_exists(SaveManager.save_slot_path(3)),"Opening the testing slot should persist it independently.")
	SaveManager.delete_slot(3)
	TestSupport.check(errors,not FileAccess.file_exists(SaveManager.save_slot_path(3)),"The testing slot should delete independently.")
	return errors
