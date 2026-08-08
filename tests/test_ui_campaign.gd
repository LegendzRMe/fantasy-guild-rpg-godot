extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node)->Array:
	var errors:Array=[];main.current_save_slot=3;main.state=SaveManager.testing_state();main.show_campaign_region("greyhaven_reach");await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="campaign_region" and main.ui.find_children("CampaignLocation_*","Button",true,false).size()==9,"A campaign regional map should render all nine permanent locations.")
	main.show_combat_hall();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="combat_hall" and main.ui.find_child("CombatHall4v4Start",true,false)!=null and main.ui.find_child("CombatHall8v8Start",true,false)!=null and main.ui.find_child("TestingDummyRangeStart",true,false)!=null and main.ui.find_child("TestingPriestRangeStart",true,false)!=null and main.ui.find_child("TestingEndlessStart",true,false)!=null,"The Combat Hall should collect raid, 4v4, 8v8, Priest Range, dummy-range, and Endless Arena practice modes.")
	var gold_before:=int(main.state.gold);var renown_before:=int(main.state.guild_renown);var items_before:int=main.state.item_instances.size()
	main.start_campaign_encounter("grand_corruption_front","gateway_site","raid_test");await main.get_tree().process_frame
	var raid_positions:Dictionary={};for hero in main.heroes:raid_positions[str(hero.pos)]=true
	TestSupport.check(errors,main.screen=="combat" and main.heroes.size()==8 and main.battle_hero_indices.size()==8 and raid_positions.size()==8 and main.total_waves==4,"The Raid Test should instantiate eight controlled heroes at distinct positions and configure multiple waves.")
	var key_eight:=InputEventKey.new();key_eight.keycode=KEY_8;key_eight.pressed=true;main.handle_combat_key_pressed(key_eight)
	TestSupport.check(errors,main.selected==7,"Number key 8 should select the eighth controlled hero.")
	main.finish_battle(false);await main.get_tree().process_frame
	TestSupport.check(errors,int(main.state.gold)==gold_before and int(main.state.guild_renown)==renown_before and main.state.item_instances.size()==items_before and main.ui.find_child("CombatHallReport",true,false)!=null,"Ending the Raid Test should restore all campaign currencies and item ownership before showing its report.")
	main.current_campaign_battle={};main.show_combat_hall();main.start_campaign_encounter("grand_corruption_front","gateway_site","scrimmage_4_test");await main.get_tree().process_frame
	var four_ids:Dictionary={};for enemy in main.enemies:four_ids[str(enemy.get("sparring_guildmate_id",""))]=true
	TestSupport.check(errors,main.heroes.size()==4 and main.enemies.size()==4 and main.enemies.all(func(enemy):return str(enemy.get("sparring_guildmate_id",""))!="" and str(enemy.get("display_name",""))!="") and four_ids.size()==4,"The 4v4 scrimmage should pit the active party against four named members of its own guild.")
	main.finish_battle(false);await main.get_tree().process_frame
	main.current_campaign_battle={};main.show_combat_hall();main.start_campaign_encounter("grand_corruption_front","gateway_site","scrimmage_test");await main.get_tree().process_frame
	var rival_positions:Dictionary={};for enemy in main.enemies:rival_positions[str(enemy.pos)]=true
	TestSupport.check(errors,main.heroes.size()==8 and main.enemies.size()==8 and rival_positions.size()==8 and main.enemies.all(func(enemy):return str(enemy.type).begins_with("Controlled ") and str(enemy.get("sparring_guildmate_id",""))!=""),"The 8v8 scrimmage should instantiate eight distinct opponents drawn from the guild roster.")
	main.finish_battle(false);await main.get_tree().process_frame
	main.current_campaign_battle={};main.state=SaveManager.testing_state();var vault_before:int=main.state.item_instances.size();main.start_campaign_encounter("greyhaven_reach","forest_road","campaign");await main.get_tree().process_frame
	TestSupport.check(errors,main.heroes.size()==4 and main.current_campaign_battle.kind=="campaign","Ordinary campaign combat should preserve the standard four-hero party limit.")
	main.finish_battle(true);await main.get_tree().process_frame
	TestSupport.check(errors,bool(main.state.campaign.regions.greyhaven_reach.locations.forest_road.campaign_completed) and main.state.item_instances.size()==vault_before+1,"A real regional victory should complete its one-time location state and add campaign equipment to the Vault.")
	main.current_campaign_battle={};main.show_hall();await main.get_tree().process_frame
	return errors
