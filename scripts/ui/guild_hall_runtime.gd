extends "res://scripts/runtime/app_interaction_runtime.gd"

func request_battle_menu()->void:
	InventorySystem.ensure_storage_state(state)
	if InventorySystem.empty_slots(state)>0:show_dungeons();return
	var dialog:=ConfirmationDialog.new();dialog.name="VaultFullBattleWarning";dialog.title="VAULT FULL";dialog.dialog_text="The Guild Vault has no empty slots for new equipment.\n\nRaw materials will still enter the Materials Depot, but equipment rewards cannot be stored until Vault space is available.";dialog.ok_button_text="Continue Anyway";dialog.cancel_button_text="Cancel"
	dialog.add_button("Manage Vault",false,"manage_vault");dialog.custom_action.connect(func(action):if action=="manage_vault":dialog.hide();show_vault());dialog.confirmed.connect(show_dungeons);ui.add_child(dialog);dialog.popup_centered(Vector2i(570,300))

func guild_hall_room_is_unlocked(room_id:String) -> bool:
	GuildHallData.ensure_state(state)
	if state.guild_hall_room_unlocks.has(room_id):return bool(state.guild_hall_room_unlocks[room_id])
	if bool(state.get("major_systems_unlocked",false)) and room_id in ["tavern","trading_post","workshop"]:return true
	return room_id in GuildHallData.STARTING_UNLOCKED_ROOMS

func guild_hall_room_is_new(room_id:String) -> bool:
	return room_id in state.get("guild_hall_new_rooms",[])

func guild_hall_tutorial_target() -> String:
	match int(state.get("guild_hall_tutorial_step",0)):
		1:return "command_table"
		2:return "front_gate"
		3:return "tavern"
	return ""

func guild_hall_room_style(zone:String,unlocked:bool,highlighted:bool,hovered:bool=false) -> StyleBoxFlat:
	var colors:={"public":Color("312a24"),"core":Color("1b2f48"),"production":Color("242c35"),"expansion":Color("191d24")}
	var base:Color=colors.get(zone,Color("202936"))
	if not unlocked:base=Color("11151c")
	elif hovered:base=base.lightened(.12)
	var border:=C_GOLD if highlighted else Color("748096") if unlocked else Color("363d49")
	return ui_box(base,4,border,3 if highlighted else 2)

func make_guild_hall_room(room:Dictionary) -> Button:
	var room_id:=str(room.id);var unlocked:=guild_hall_room_is_unlocked(room_id);var is_new:=guild_hall_room_is_new(room_id);var highlighted:=guild_hall_tutorial_target()==room_id or is_new
	var room_button:=Button.new();room_button.name="GuildRoom_%s"%room_id;room_button.position=room.position;room_button.size=room.size;room_button.custom_minimum_size=room.size
	room_button.text="%s\n%s\n%s"%[str(room.icon),str(room.name),str(room.description)];room_button.tooltip_text=str(room.description) if unlocked else "Locked — %s"%str(room.description);room_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;room_button.add_theme_font_size_override("font_size",20 if room_id in ["great_hall","workshop"] else 16);room_button.add_theme_color_override("font_color",C_GOLD if unlocked else Color("737b88"));room_button.add_theme_color_override("font_hover_color",Color.WHITE)
	room_button.add_theme_stylebox_override("normal",guild_hall_room_style(str(room.zone),unlocked,highlighted));room_button.add_theme_stylebox_override("hover",guild_hall_room_style(str(room.zone),unlocked,true,true));room_button.add_theme_stylebox_override("pressed",guild_hall_room_style(str(room.zone),unlocked,true))
	room_button.pressed.connect(func():activate_guild_hall_room(room_id))
	if room_id=="workshop":
		for station_index in 3:
			var station:=Label.new();station.text="EMPTY STATION";station.position=Vector2(55+station_index*225,310);station.size=Vector2(190,42);station.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;station.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;station.add_theme_font_size_override("font_size",12);station.add_theme_color_override("font_color",Color("8290a4"));station.add_theme_stylebox_override("normal",ui_box(Color("151b22"),2,Color("4b5665"),1));station.mouse_filter=Control.MOUSE_FILTER_IGNORE;room_button.add_child(station)
	if not unlocked:
		var lock_overlay:=LockOverlay.new();lock_overlay.name="LockOverlay";lock_overlay.position=(room.size-Vector2(112,92))*.5;lock_overlay.size=Vector2(112,92);room_button.add_child(lock_overlay)
	if is_new:
		var marker:=Label.new();marker.name="NewRoomMarker";marker.text="NEW";marker.position=Vector2(room.size.x-58,8);marker.size=Vector2(48,24);marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;marker.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;marker.add_theme_font_size_override("font_size",11);marker.add_theme_color_override("font_color",Color("101827"));marker.add_theme_stylebox_override("normal",ui_box(C_GOLD,8));marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;room_button.add_child(marker)
	return room_button

func remember_guild_hall_scroll(save_now:bool=false) -> void:
	if guild_hall_scroll==null or not is_instance_valid(guild_hall_scroll):return
	state.guild_hall_scroll_position=float(guild_hall_scroll.scroll_horizontal)
	if save_now:save_game()

func restore_guild_hall_scroll() -> void:
	if guild_hall_scroll!=null and is_instance_valid(guild_hall_scroll):guild_hall_scroll.scroll_horizontal=int(state.get("guild_hall_scroll_position",GuildHallData.DEFAULT_SCROLL_POSITION))

func dismiss_guild_hall_scroll_hint() -> void:
	if bool(state.get("guild_hall_scroll_hint_dismissed",false)):return
	state.guild_hall_scroll_hint_dismissed=true
	if guild_hall_scroll_hint!=null and is_instance_valid(guild_hall_scroll_hint):guild_hall_scroll_hint.queue_free()
	guild_hall_scroll_hint=null

func handle_guild_hall_input(event:InputEvent) -> bool:
	if guild_hall_scroll==null or not is_instance_valid(guild_hall_scroll):return false
	var hall_rect:=Rect2(guild_hall_scroll.global_position,guild_hall_scroll.size)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and hall_rect.has_point(event.position):guild_hall_dragging=true;guild_hall_drag_moved=false;guild_hall_drag_start=event.position;guild_hall_drag_scroll_start=guild_hall_scroll.scroll_horizontal
		elif not event.pressed and guild_hall_dragging:
			guild_hall_dragging=false
			if guild_hall_drag_moved:remember_guild_hall_scroll(true);return true
	elif event is InputEventMouseMotion and guild_hall_dragging:
		var mouse_delta:float=event.position.x-guild_hall_drag_start.x
		if absf(mouse_delta)>8.0:guild_hall_drag_moved=true;dismiss_guild_hall_scroll_hint();guild_hall_scroll.scroll_horizontal=guild_hall_drag_scroll_start-int(mouse_delta);get_viewport().set_input_as_handled();return true
	elif event is InputEventScreenTouch:
		if event.pressed and hall_rect.has_point(event.position):guild_hall_dragging=true;guild_hall_drag_moved=false;guild_hall_drag_start=event.position;guild_hall_drag_scroll_start=guild_hall_scroll.scroll_horizontal
		elif not event.pressed and guild_hall_dragging:
			guild_hall_dragging=false
			if guild_hall_drag_moved:remember_guild_hall_scroll(true);return true
	elif event is InputEventScreenDrag and guild_hall_dragging:
		var touch_delta:float=event.position.x-guild_hall_drag_start.x
		if absf(touch_delta)>8.0:guild_hall_drag_moved=true;dismiss_guild_hall_scroll_hint();guild_hall_scroll.scroll_horizontal=guild_hall_drag_scroll_start-int(touch_delta);get_viewport().set_input_as_handled();return true
	return false

func advance_guild_hall_tutorial(room_id:String) -> void:
	var step:=int(state.get("guild_hall_tutorial_step",0))
	if step==1 and room_id=="command_table":state.guild_hall_tutorial_step=2
	elif step==2 and room_id=="front_gate":state.guild_hall_tutorial_step=3;if "tavern" not in state.guild_hall_new_rooms:state.guild_hall_new_rooms.append("tavern")

func show_infirmary() -> void:
	screen="infirmary";var root:=base_screen("Infirmary","RECOVERY  •  REMEDIES  •  MEMBER WELLBEING")
	var overview:=PanelContainer.new();overview.name="InfirmaryOverview";overview.add_theme_stylebox_override("panel",ui_box(Color("172536"),8,Color("4b6079"),1));root.add_child(overview)
	var overview_content:=VBoxContainer.new();overview_content.add_theme_constant_override("separation",6);overview.add_child(overview_content);overview_content.add_child(label("ALL MEMBERS FIT FOR DUTY",22,C_GREEN));overview_content.add_child(label("No guild members currently require persistent treatment. Injuries and recovery time are not active in this build.",15,C_MUTED))
	var services:=HBoxContainer.new();services.add_theme_constant_override("separation",12);services.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(services)
	for service in [["RECOVERY WARD","Rest injured members and shorten expedition recovery."],["APOTHECARY","Use remedies to remove lasting conditions and afflictions."],["SANCTUARY","Assign rest, morale, and wellbeing support to guild members."]]:
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(380,230);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",ui_box(Color("151f30"),8,Color("394a61"),1));services.add_child(card)
		var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",12);card.add_child(content);content.add_child(label(str(service[0]),20,C_GOLD));var description:=label(str(service[1]),15,C_TEXT);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size.y=80;content.add_child(description);content.add_child(label("PLANNED SYSTEM",13,C_MUTED))
	var roster_summary:=label("%d members currently available."%state.get("heroes",[]).size(),16,C_TEXT);roster_summary.name="InfirmaryMemberSummary";root.add_child(roster_summary)

func activate_guild_hall_room(room_id:String) -> void:
	remember_guild_hall_scroll()
	if not guild_hall_room_is_unlocked(room_id):flash("Complete a future Guild Hall milestone to restore this room.");return
	if room_id in state.guild_hall_new_rooms:state.guild_hall_new_rooms.erase(room_id)
	advance_guild_hall_tutorial(room_id);save_game()
	match room_id:
		"great_hall":open_guild_page("heroes",show_roster)
		"command_table":open_guild_page("command",show_command_table)
		"infirmary":show_council_chamber()
		"front_gate":request_battle_menu()
		"guild_storage":open_guild_page("vault",func():show_guild_storage(guild_storage_tab))
		"guild_vault":open_guild_page("vault",func():show_guild_storage("vault"))
		"trading_post":open_guild_page("merchant",show_market)
		"materials_depot":show_guild_storage("depot")
		"workshop":open_guild_page("workshop",show_crafting)
		"tavern":open_guild_page("tavern",show_tavern)
		"council_chamber":flash("This room's purpose has not been determined yet.")
		"combat_hall":show_combat_hall()
		"public_entrance":flash("Visitors, recruits, traders, and merchants will enter here.")
		_:flash("Unavailable in this prototype.")

func set_guild_hall_room_unlock(room_id:String,unlocked:bool,newly_available:bool=true) -> void:
	state.guild_hall_room_unlocks[room_id]=unlocked
	state.guild_hall_new_rooms.erase(room_id)
	if unlocked and newly_available:state.guild_hall_new_rooms.append(room_id)
	save_game();show_hall()

func unlock_all_guild_hall_rooms() -> void:
	for room in GuildHallData.room_definitions():state.guild_hall_room_unlocks[str(room.id)]=true
	state.guild_hall_new_rooms=[];save_game();show_hall()

func lock_optional_guild_hall_rooms() -> void:
	for room_id in GuildHallData.OPTIONAL_ROOM_IDS:state.guild_hall_room_unlocks[room_id]=false
	state.guild_hall_new_rooms=[];save_game();show_hall()

func reset_guild_hall_layout_state() -> void:
	state.guild_hall_room_unlocks=GuildHallData.default_room_unlocks();state.guild_hall_new_rooms=[];state.guild_hall_scroll_position=GuildHallData.DEFAULT_SCROLL_POSITION;state.guild_hall_tutorial_step=0;state.guild_hall_tutorial_complete=false;state.guild_hall_scroll_hint_dismissed=false;save_game();show_hall()

func start_guild_hall_tutorial() -> void:
	state.guild_hall_tutorial_step=1;state.guild_hall_tutorial_complete=false;save_game();show_hall()

func skip_guild_hall_tutorial() -> void:
	state.guild_hall_tutorial_step=0;state.guild_hall_tutorial_complete=true;save_game();show_hall()

func restore_tavern_tutorial_room() -> void:
	state.guild_hall_room_unlocks.tavern=true
	if "tavern" not in state.guild_hall_new_rooms:state.guild_hall_new_rooms.append("tavern")
	state.guild_hall_tutorial_step=0;state.guild_hall_tutorial_complete=true;save_game();show_hall()

func guild_hall_tutorial_prompt() -> String:
	match int(state.get("guild_hall_tutorial_step",0)):
		1:return "Hall Tour 1/3  •  Open the highlighted Command Table."
		2:return "Hall Tour 2/3  •  Use the Front Gate to prepare a battle."
		3:return "Hall Tour 3/3  •  The Tavern is ready to restore."
	return ""

func add_guild_hall_tutorial_bar() -> void:
	var step:=int(state.get("guild_hall_tutorial_step",0));if step<=0:return
	var bar:=PanelContainer.new();bar.name="GuildHallTutorialBar";bar.position=Vector2(310,650);bar.size=Vector2(660,58);bar.add_theme_stylebox_override("panel",ui_box(Color("111923e8"),5,C_GOLD,2));ui.add_child(bar)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);bar.add_child(row);var prompt:=label(guild_hall_tutorial_prompt(),15,C_TEXT);prompt.size_flags_horizontal=Control.SIZE_EXPAND_FILL;prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(prompt)
	if step==3:var restore:=button("Restore Tavern",restore_tavern_tutorial_room,150);restore.custom_minimum_size.y=36;row.add_child(restore)
	var skip:=button("Skip",skip_guild_hall_tutorial,70);skip.custom_minimum_size.y=36;row.add_child(skip)

func add_guild_hall_dismiss_layer(layer_name:String,close_action:Callable) -> void:
	var dismiss_layer:=Button.new();dismiss_layer.name=layer_name;dismiss_layer.position=Vector2.ZERO;dismiss_layer.size=Vector2(W,H);dismiss_layer.flat=true;dismiss_layer.focus_mode=Control.FOCUS_NONE;dismiss_layer.mouse_default_cursor_shape=Control.CURSOR_ARROW;dismiss_layer.pressed.connect(close_action);ui.add_child(dismiss_layer)

func close_guild_hall_debug_panel() -> void:
	if not guild_hall_debug_open:return
	guild_hall_debug_open=false;show_hall()

func close_guild_hall_menu() -> void:
	if not guild_hall_menu_open:return
	guild_hall_menu_open=false;show_hall()

func add_guild_hall_debug_panel() -> void:
	if not is_testing_save() or not guild_hall_debug_open:return
	add_guild_hall_dismiss_layer("GuildHallDebugDismissLayer",close_guild_hall_debug_panel)
	var debug_panel:=PanelContainer.new();debug_panel.name="GuildHallDebugPanel";debug_panel.position=Vector2(972,84);debug_panel.size=Vector2(294,420);debug_panel.add_theme_stylebox_override("panel",ui_box(Color("111923f2"),4,C_GOLD,1));ui.add_child(debug_panel)
	var controls:=VBoxContainer.new();controls.add_theme_constant_override("separation",5);debug_panel.add_child(controls);controls.add_child(label("GUILD HALL TESTS",16,C_GOLD))
	var version:=str(ProjectSettings.get_setting("application/config/version","development"));var build_id:=OS.get_environment("WOW_BATTLEHEART_BUILD_ID").strip_edges()
	if build_id.is_empty():build_id=str(ProjectSettings.get_setting("application/config/build_id","development"))
	var build_label:=label("Version %s  |  Build %s"%[version,build_id],11,C_MUTED);build_label.name="BuildMetadataLabel";controls.add_child(build_label)
	var performance_label:=label("FPS %d  |  Objects %d  |  Draw calls %d"%[int(Performance.get_monitor(Performance.TIME_FPS)),int(Performance.get_monitor(Performance.OBJECT_COUNT)),int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))],11,C_MUTED);performance_label.name="PerformanceSnapshotLabel";controls.add_child(performance_label)
	for entry in [["Unlock Tavern","tavern"],["Unlock Trading Post","trading_post"],["Unlock Workshop","workshop"]]:
		var unlock_button:=button(str(entry[0]),func(id=str(entry[1])):set_guild_hall_room_unlock(id,true),250);unlock_button.custom_minimum_size.y=34;controls.add_child(unlock_button)
	for entry in [["Unlock All Rooms",unlock_all_guild_hall_rooms],["Lock Optional Rooms",lock_optional_guild_hall_rooms],["Reset Hall State",reset_guild_hall_layout_state]]:
		var action_button:=button(str(entry[0]),entry[1],250);action_button.custom_minimum_size.y=34;controls.add_child(action_button)

func toggle_guild_hall_menu() -> void:
	guild_hall_menu_open=not guild_hall_menu_open;show_hall()

func open_guild_hall_settings() -> void:
	guild_hall_menu_open=false;show_settings()

func open_guild_hall_save_menu() -> void:
	remember_guild_hall_scroll(true);guild_hall_menu_open=false;show_menu()

func open_guild_codex() -> void:
	guild_hall_menu_open=false;show_codex()

func toggle_guild_hall_debug_panel() -> void:
	guild_hall_debug_open=not guild_hall_debug_open;guild_hall_menu_open=false;show_hall()

func add_guild_hall_menu_panel() -> void:
	if not guild_hall_menu_open:return
	add_guild_hall_dismiss_layer("GuildHallMenuDismissLayer",close_guild_hall_menu)
	var menu_panel:=PanelContainer.new();menu_panel.name="GuildHallMenuPanel";menu_panel.position=Vector2(1000,78);menu_panel.size=Vector2(266,300 if is_testing_save() else 255);menu_panel.add_theme_stylebox_override("panel",ui_box(Color("111923f2"),4,C_GOLD,1));ui.add_child(menu_panel)
	var controls:=VBoxContainer.new();controls.add_theme_constant_override("separation",7);menu_panel.add_child(controls);controls.add_child(label("GUILD MENU",16,C_GOLD))
	var codex_button:=button("Guild Codex",open_guild_codex,230);codex_button.name="GuildCodexMenuEntry";codex_button.custom_minimum_size.y=38;controls.add_child(codex_button)
	if not bool(state.get("guild_hall_tutorial_complete",false)) or int(state.get("guild_hall_tutorial_step",0))>0:
		var tour_button:=button("Start / Restart Hall Tour",func():guild_hall_menu_open=false;start_guild_hall_tutorial(),230);tour_button.custom_minimum_size.y=38;controls.add_child(tour_button)
	var settings_button:=button("Settings",open_guild_hall_settings,230);settings_button.custom_minimum_size.y=38;controls.add_child(settings_button)
	var saves_button:=button("Save Slots",open_guild_hall_save_menu,230);saves_button.custom_minimum_size.y=38;controls.add_child(saves_button)
	if is_testing_save():var test_button:=button("Guild Hall Test Controls",toggle_guild_hall_debug_panel,230);test_button.custom_minimum_size.y=38;controls.add_child(test_button)

func set_codex_category(category:String)->void:
	codex_category=category;show_codex()

func view_codex_entry(entry_data:Dictionary)->void:
	state.codex_seen_entries[str(entry_data.id)]=true;save_game()
	var dialog:=AcceptDialog.new();dialog.name="CodexEntryDialog";dialog.title=str(entry_data.title);dialog.dialog_text=str(entry_data.details);dialog.ok_button_text="Return to Codex";dialog.min_size=Vector2i(650,430);ui.add_child(dialog);dialog.popup_centered(Vector2i(650,430))

func populate_codex_entries(container:VBoxContainer)->void:
	for child in container.get_children():child.queue_free()
	var search:=codex_search.strip_edges().to_lower();var visible_count:=0
	for entry_data in GuildCodexData.all_entries(state):
		if str(entry_data.category)!=codex_category:continue
		var discovered:=bool(entry_data.discovered);var display_title:=str(entry_data.title) if discovered else "???";var display_summary:=str(entry_data.summary) if discovered else "Undiscovered — continue exploring to reveal this entry."
		if search!="" and search not in (display_title+" "+display_summary).to_lower():continue
		var entry_button:=Button.new();entry_button.name="CodexEntry_%s"%str(entry_data.id).replace(":","_");entry_button.custom_minimum_size=Vector2(1080,82);entry_button.text="%s%s\n%s"%["NEW  •  " if discovered and not bool(state.codex_seen_entries.get(str(entry_data.id),false)) else "",display_title,display_summary];entry_button.alignment=HORIZONTAL_ALIGNMENT_LEFT;entry_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;entry_button.add_theme_font_size_override("font_size",16);entry_button.disabled=not discovered
		if discovered:entry_button.pressed.connect(func(data=entry_data):view_codex_entry(data))
		container.add_child(entry_button);visible_count+=1
	if visible_count==0:
		var empty:=label("No Codex entries match this search yet.",18,C_MUTED);empty.custom_minimum_size.y=100;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;container.add_child(empty)

func show_codex()->void:
	if codex_category not in GuildCodexData.CATEGORIES:codex_category="Guide"
	screen="codex";var root:=base_screen("Guild Codex","DISCOVERED KNOWLEDGE  •  GUILD REFERENCE")
	var categories:=HBoxContainer.new();categories.name="CodexCategories";categories.alignment=BoxContainer.ALIGNMENT_CENTER;categories.add_theme_constant_override("separation",6);root.add_child(categories)
	for category in GuildCodexData.CATEGORIES:
		var category_button:=compact_button(str(category),func(value=str(category)):set_codex_category(value),165);category_button.name="CodexCategory_%s"%str(category).to_snake_case()
		if str(category)==codex_category:category_button.add_theme_stylebox_override("normal",ui_box(Color("2b3b52"),5,C_GOLD,2));category_button.add_theme_color_override("font_color",C_GOLD)
		categories.add_child(category_button)
	var search_row:=HBoxContainer.new();search_row.add_theme_constant_override("separation",10);root.add_child(search_row);var search_input:=LineEdit.new();search_input.name="CodexSearch";search_input.placeholder_text="Search discovered entries";search_input.text=codex_search;search_input.custom_minimum_size=Vector2(520,42);search_input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search_row.add_child(search_input);var clear_search:=compact_button("Clear",func():codex_search="";show_codex(),90);search_row.add_child(clear_search)
	var scroll:=ScrollContainer.new();scroll.name="CodexResultsScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll);var results:=VBoxContainer.new();results.name="CodexResults";results.add_theme_constant_override("separation",8);results.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(results)
	search_input.text_changed.connect(func(value):codex_search=str(value);populate_codex_entries(results));populate_codex_entries(results)

func add_guild_hall_top_bar() -> void:
	GameClockSystem.ensure_state(state)
	if not is_testing_save():state.game_clock.paused=false;state.game_clock.speed=1
	var top_panel:=PanelContainer.new();top_panel.name="GuildHallTopBar";top_panel.position=Vector2.ZERO;top_panel.size=Vector2(W,86);top_panel.add_theme_stylebox_override("panel",ui_box(Color("0b111b"),0,Color("303b4b"),1));ui.add_child(top_panel)
	var top:=HBoxContainer.new();top.position=Vector2(18,10);top.size=Vector2(1244,66);top.add_theme_constant_override("separation",12);top_panel.add_child(top)
	var identity:=VBoxContainer.new();identity.custom_minimum_size.x=500;top.add_child(identity);identity.add_child(label(state.guild_name,23,C_GOLD));identity.add_child(label("GUILD RANK %d     RENOWN  %d     GOLD  %d"%[int(state.guild_prestige_rank),int(state.guild_renown),int(state.gold)],14,C_MUTED))
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(spacer)
	if is_testing_save():
		var clock_controls:=HBoxContainer.new();clock_controls.name="GuildClockTestControls";clock_controls.alignment=BoxContainer.ALIGNMENT_CENTER;clock_controls.add_theme_constant_override("separation",3);top.add_child(clock_controls)
		var pause_clock:=compact_button("Resume" if bool(state.game_clock.paused) else "Pause",func():GameClockSystem.set_paused(state,not bool(state.game_clock.paused));save_game();show_hall(),74);pause_clock.name="GuildClockPause";pause_clock.tooltip_text="Testing-only simulation control.";clock_controls.add_child(pause_clock)
		for speed in GameClockSystem.VALID_SPEEDS:
			var speed_button:=compact_button("%dx"%speed,func(value=speed):GameClockSystem.set_speed(state,value);save_game();show_hall(),42);speed_button.name="GuildClockSpeed%d"%speed;speed_button.tooltip_text="Testing-only simulation speed.";speed_button.disabled=int(state.game_clock.speed)==speed;clock_controls.add_child(speed_button)
	var menu_button:=button("MENU",toggle_guild_hall_menu,100);menu_button.name="GuildHallMenuButton";menu_button.tooltip_text="Tour, settings, save slots, and testing tools.";top.add_child(menu_button)

func show_hall() -> void:
	screen="hall";clear_all();GuildHallData.ensure_state(state);guild_hall_dragging=false;guild_hall_drag_moved=false
	var bg:=ColorRect.new();bg.color=Color("0b111b");bg.position=Vector2.ZERO;bg.size=Vector2(W,H);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(bg)
	add_guild_hall_top_bar()
	guild_hall_scroll=ScrollContainer.new();guild_hall_scroll.name="GuildHallScroll";guild_hall_scroll.position=Vector2(0,86);guild_hall_scroll.size=Vector2(W,H-86);guild_hall_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;guild_hall_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;guild_hall_scroll.scroll_deadzone=10000;ui.add_child(guild_hall_scroll)
	var hall:=Control.new();hall.name="GuildHallFloorPlan";hall.custom_minimum_size=Vector2(2240,650);hall.size=Vector2(2240,650);guild_hall_scroll.add_child(hall)
	var foundation:=Panel.new();foundation.position=Vector2(12,6);foundation.size=Vector2(2195,510);foundation.add_theme_stylebox_override("panel",ui_box(Color("171d25"),2,Color("4b535f"),5));foundation.mouse_filter=Control.MOUSE_FILTER_IGNORE;hall.add_child(foundation)
	var lower_foundation:=Panel.new();lower_foundation.position=Vector2(365,514);lower_foundation.size=Vector2(1410,128);lower_foundation.add_theme_stylebox_override("panel",ui_box(Color("141920"),2,Color("3f4651"),4));lower_foundation.mouse_filter=Control.MOUSE_FILTER_IGNORE;hall.add_child(lower_foundation)
	for corridor_data in [[Vector2(565,180),Vector2(525,64)],[Vector2(795,190),Vector2(62,320)],[Vector2(1035,180),Vector2(390,64)],[Vector2(172,385),Vector2(455,42)],[Vector2(1045,385),Vector2(380,42)]]:
		var corridor:=ColorRect.new();corridor.position=corridor_data[0];corridor.size=corridor_data[1];corridor.color=Color("34363a");corridor.mouse_filter=Control.MOUSE_FILTER_IGNORE;hall.add_child(corridor)
	for heading_data in [["PUBLIC SIDE",Vector2(205,0),C_MUTED],["CORE GUILD",Vector2(615,0),C_GOLD],["PRODUCTION SIDE",Vector2(1090,0),C_MUTED],["LOWER EXPANSION",Vector2(390,508),C_MUTED]]:
		var heading:=label(str(heading_data[0]),12,heading_data[2]);heading.position=heading_data[1];heading.size=Vector2(300,18);heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;hall.add_child(heading)
	for room in GuildHallData.room_definitions():hall.add_child(make_guild_hall_room(room))
	call_deferred("restore_guild_hall_scroll")
	if not bool(state.get("guild_hall_scroll_hint_dismissed",false)):
		guild_hall_scroll_hint=Label.new();guild_hall_scroll_hint.name="GuildHallScrollHint";guild_hall_scroll_hint.text="DRAG OR SWIPE TO EXPLORE  <  >";guild_hall_scroll_hint.position=Vector2(475,610);guild_hall_scroll_hint.size=Vector2(330,32);guild_hall_scroll_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;guild_hall_scroll_hint.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;guild_hall_scroll_hint.add_theme_font_size_override("font_size",13);guild_hall_scroll_hint.add_theme_color_override("font_color",C_MUTED);guild_hall_scroll_hint.add_theme_stylebox_override("normal",ui_box(Color("0b111bd9"),12,Color("344256"),1));guild_hall_scroll_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(guild_hall_scroll_hint)
	var left_arrow:=button("<",func():guild_hall_scroll.scroll_horizontal-=320;dismiss_guild_hall_scroll_hint();remember_guild_hall_scroll(true),44);left_arrow.position=Vector2(10,340);left_arrow.size=Vector2(44,64);left_arrow.modulate=Color(1,1,1,.72);ui.add_child(left_arrow)
	var right_arrow:=button(">",func():guild_hall_scroll.scroll_horizontal+=320;dismiss_guild_hall_scroll_hint();remember_guild_hall_scroll(true),44);right_arrow.position=Vector2(1226,340);right_arrow.size=Vector2(44,64);right_arrow.modulate=Color(1,1,1,.72);ui.add_child(right_arrow)
	add_guild_hall_tutorial_bar();add_guild_hall_debug_panel();add_guild_hall_menu_panel()
