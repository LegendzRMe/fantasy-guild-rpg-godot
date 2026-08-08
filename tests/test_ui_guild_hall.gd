extends RefCounted

const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	var save_cards:=[]
	for candidate in main.ui.find_children("*","Button",true,false):
		if is_equal_approx(candidate.custom_minimum_size.y,210.0):save_cards.append(candidate)
	TestSupport.check(errors,save_cards.size()==4,"The save menu should render three live slots and one testing slot.")
	TestSupport.check(errors,save_cards.any(func(card):return card.text.begins_with("SAVE 1")),"The first live save card should remain available.")
	TestSupport.check(errors,save_cards.any(func(card):return card.text.begins_with("TESTING")),"The testing save card should remain available.")
	TestSupport.check(errors,main.tutorial_movement_target_reached(Vector2.ZERO,Vector2(70,0)),"Tutorial movement should accept a fair overlap around the marker.")
	TestSupport.check(errors,not main.tutorial_movement_target_reached(Vector2.ZERO,Vector2(74,0)),"Tutorial movement should still reject positions outside the forgiving marker area.")
	var four_hero_left:Vector2=main.centered_victory_position(0,4,125.0,445.0)
	var four_hero_right:Vector2=main.centered_victory_position(3,4,125.0,445.0)
	TestSupport.check(errors,is_equal_approx((four_hero_left.x+four_hero_right.x)*.5,main.W*.5),"A four-hero victory lineup should be centered on the screen rather than shifted right.")
	main.heroes=[{"pos":Vector2(417,465)},{"pos":Vector2(522,465)}]
	TestSupport.check(errors,main.victory_progress_center(0).x==417 and main.victory_progress_center(1).x==522 and main.victory_continue_prompt()=="CLICK TO CONTINUE","Victory XP bars should inherit each displayed Hero's exact center and use one uppercase continuation prompt.")
	main.heroes.clear();main.state=SaveManager.fresh_state();main.state.guild_name="Live Guild";main.state.tutorial_complete=true;main.show_hall()
	await main.get_tree().process_frame
	var hall_scroll:ScrollContainer=main.ui.find_child("GuildHallScroll",true,false)
	var floor_plan:Control=main.ui.find_child("GuildHallFloorPlan",true,false)
	TestSupport.check(errors,hall_scroll!=null and floor_plan!=null and floor_plan.size.x>main.W,"The Guild Hall should be a horizontally scrollable landscape floor plan wider than the viewport.")
	TestSupport.check(errors,hall_scroll.scroll_horizontal>0,"The Guild Hall should initially frame the central guild rooms instead of the far-left entrance.")
	var hall_top_bar:PanelContainer=main.ui.find_child("GuildHallTopBar",true,false)
	var top_bar_buttons:=hall_top_bar.find_children("*","Button",true,false) if hall_top_bar!=null else []
	TestSupport.check(errors,top_bar_buttons.size()==1 and top_bar_buttons[0].name=="GuildHallMenuButton" and main.ui.find_child("GuildClockLabel",true,false)==null and main.ui.find_child("GuildClockTestControls",true,false)==null and not bool(main.state.game_clock.paused) and int(main.state.game_clock.speed)==1,"A regular Guild Hall should show only its Menu button, omit day/time and simulation controls, and run at normal speed.")
	main.current_save_slot=main.TESTING_SAVE_SLOT;main.show_hall();await main.get_tree().process_frame;await main.get_tree().process_frame
	var testing_button_texts:Array=main.ui.find_children("*","Button",true,false).map(func(control):return str(control.text));var testing_label_texts:Array=main.ui.find_children("*","Label",true,false).map(func(control):return str(control.text))
	TestSupport.check(errors,("Pause" in testing_button_texts or "Resume" in testing_button_texts) and ["1x","2x","4x"].all(func(speed):return speed in testing_button_texts) and not testing_label_texts.any(func(value):return value.begins_with("DAY ")),"The testing save should retain Pause and 1x/2x/4x controls without displaying a day or clock.")
	main.current_save_slot=0;main.show_hall();await main.get_tree().process_frame
	hall_scroll=main.ui.find_child("GuildHallScroll",true,false);floor_plan=main.ui.find_child("GuildHallFloorPlan",true,false)
	var front_gate_room:Button=main.ui.find_child("GuildRoom_front_gate",true,false)
	var great_hall_room:Button=main.ui.find_child("GuildRoom_great_hall",true,false)
	TestSupport.check(errors,front_gate_room!=null and great_hall_room!=null and front_gate_room.position.y<great_hall_room.position.y,"The Front Gate / Battle room should anchor the top of the core guild wing.")
	var combined_menu:Button=main.ui.find_child("GuildHallMenuButton",true,false);combined_menu.pressed.emit();await main.get_tree().process_frame
	var menu_dismiss:Button=main.ui.find_child("GuildHallMenuDismissLayer",true,false);TestSupport.check(errors,menu_dismiss!=null,"The combined Guild Menu should provide a click- and tap-outside dismissal layer.")
	if menu_dismiss!=null:menu_dismiss.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,not main.guild_hall_menu_open and main.ui.find_child("GuildHallMenuPanel",true,false)==null,"Clicking or tapping outside the combined Guild Menu should close it without choosing an entry.")
	combined_menu=main.ui.find_child("GuildHallMenuButton",true,false);combined_menu.pressed.emit();await main.get_tree().process_frame
	var codex_menu_entry:Button=main.ui.find_child("GuildCodexMenuEntry",true,false);TestSupport.check(errors,codex_menu_entry!=null,"The combined Guild Menu should provide access to the Guild Codex.")
	if codex_menu_entry!=null:codex_menu_entry.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="codex" and main.ui.find_child("CodexSearch",true,false)!=null and main.ui.find_children("CodexCategory_*","Button",true,false).size()==7,"The Guild Codex should open with search and its seven reference categories, including Tavern content.")
	var guide_entry:Button=main.ui.find_child("CodexEntry_guide_guild_vault",true,false);TestSupport.check(errors,guide_entry!=null and not guide_entry.disabled and "Guild Vault" in guide_entry.text,"The Codex Guide should immediately explain the Guild Vault safety boundary.")
	main.show_hall();await main.get_tree().process_frame
	for room_id in ["great_hall","command_table","infirmary","front_gate","guild_storage","combat_hall"]:
		var starting_room:Button=main.ui.find_child("GuildRoom_%s"%room_id,true,false);TestSupport.check(errors,starting_room!=null and starting_room.find_child("LockOverlay",true,false)==null,"%s should be an unlocked starting Guild Hall room."%room_id)
	for room_id in ["tavern","trading_post","workshop","council_chamber","lower_locked_3","lower_locked_4"]:
		var locked_room:Button=main.ui.find_child("GuildRoom_%s"%room_id,true,false);TestSupport.check(errors,locked_room!=null and locked_room.find_child("LockOverlay",true,false)!=null,"%s should visibly use the locked room state for a new live guild."%room_id)
	main.current_save_slot=97
	var great_hall:Button=main.ui.find_child("GuildRoom_great_hall",true,false);great_hall.pressed.emit();await main.get_tree().process_frame
	var first_page_intro:AcceptDialog=main.ui.find_child("GuildPageIntro",true,false)
	TestSupport.check(errors,main.screen=="roster" and first_page_intro!=null and "complete member directory" in first_page_intro.dialog_text,"The first visit to a newly available Guild Hall page should show its broad purpose over that page.")
	TestSupport.check(errors,bool(main.state.seen_page_intros.get("heroes",false)),"Showing a page introduction should persist its first-visit state in the guild save.")
	if first_page_intro!=null:first_page_intro.hide();first_page_intro.queue_free()
	main.show_hall();await main.get_tree().process_frame
	var repeat_heroes_button:Button=main.ui.find_child("GuildRoom_great_hall",true,false);repeat_heroes_button.pressed.emit();await main.get_tree().process_frame
	TestSupport.check(errors,main.screen=="roster" and main.ui.find_child("GuildPageIntro",true,false)==null,"Later visits should open the Guild Hall page directly without repeating its introduction.")
	main.current_team_slot=-1
	return errors
