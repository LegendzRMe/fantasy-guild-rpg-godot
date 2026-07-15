extends Node2D

const GameData = preload("res://scripts/data/game_data.gd")
const AshwoodData = preload("res://scripts/data/ashwood_data.gd")
const AshwoodManager = preload("res://scripts/systems/ashwood_manager.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TeamManager = preload("res://scripts/systems/team_manager.gd")
const RosterManager = preload("res://scripts/systems/roster_manager.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const LockOverlay = preload("res://scripts/ui/lock_overlay.gd")
const FOREST_GROUND_TEXTURE = preload("res://assets/third_party/ggbotnet_forest_ground/Forest-Ground_01.png")

const W := 1280.0
const H := 720.0
const C_BG := Color("101827")
const C_PANEL := Color("1b2940")
const C_PANEL_2 := Color("243652")
const C_GOLD := Color("f5c451")
const C_TEXT := Color("e9f1ff")
const C_MUTED := Color("9fb1ca")
const C_GREEN := Color("54d69a")
const C_RED := Color("ef6571")
const CLASSES := GameData.CLASSES
const ABILITIES := GameData.ABILITIES
const TRAITS := GameData.TRAITS
const ABILITY_TARGETING := GameData.ABILITY_TARGETING
const ABILITY_RANGES := GameData.ABILITY_RANGES
const LIVE_SAVE_SLOT_COUNT := 3
const TESTING_SAVE_SLOT := LIVE_SAVE_SLOT_COUNT
const TOTAL_SAVE_SLOT_COUNT := LIVE_SAVE_SLOT_COUNT+1
const TESTING_MAX_HERO_LEVEL := 60
const TUTORIAL_MOVEMENT_REACH_RADIUS := 72.0
const OBJECTIVE_THREAT_TARGET := -2
const DAMAGE_THREAT_RATIO := 1.0
const HEALING_THREAT_RATIO := 0.5
const GUARDIAN_THREAT_MULTIPLIER := 5.0
const THREAT_PULL_MULTIPLIER := 1.10
const CHALLENGE_TAUNT_DURATION := 3.0

var state := {}
var screen := "menu"
var ui := Control.new()
var combat_layer := Node2D.new()
var heroes := []
var battle_hero_indices:Array = []
var enemies := []
var effects := []
var selected := 0
var focused_enemy_index := -1
var dragging_hero := false
var drag_cursor := Vector2.ZERO
var drag_start := Vector2.ZERO
var drag_has_moved := false
var drag_target_type := "ground"
var drag_target_index := -1
var team_dragging := false
var team_drag_index := -1
var team_drag_origin := ""
var team_active_zone: Control = null
var team_reserve_zone: Control = null
var team_drag_preview: Button = null
var team_roster_page := 0
var team_swipe_start := Vector2.ZERO
var team_swiping := false
var hero_search := ""
var hero_role_filter := "All roles"
var hero_class_filter := "All classes"
var hero_type_filter := "All Heroes"
var roster_sort := "Name"
var roster_descending := false
var selected_roster_index := 0
var hero_roster_page := 0
var selected_profession := 0
var selected_mission := 0
var current_team_slot := -1
var current_save_slot := 0
var battle_time := 0.0
var spawn_timer := 0.0
var battle_over := false
var paused := false
var dungeon_id := 0
var encounter_id := 0
var wave_index := 0
var total_waves := 3
var wave_spawn_remaining := 0
var wave_break := 0.0
var waiting_wave := false
var battle_gold_earned := 0
var current_ashwood_encounter := ""
var current_wave_roles := []
var ashwood_spawn_count := 0
var ashwood_midfight_recruit_index := -1
var battle_objective := {}
var objective_progress := 0.0
var objective_health := 0.0
var objective_max_health := 0.0
var objective_complete := true
var objective_pressure_spawned := false
var objective_actor_pos := Vector2(930,330)
var objective_notice := ""
var objective_notice_time := 0.0
var objective_banner_time := 0.0
var objective_combat_intro := ""
var rune_active := false
var rune_timer := 0.0
var rune_charge := 0.0
var rune_center := Vector2.ZERO
var rune_radius := 0.0
var pending_victory := {}
var pending_map_reveals := []
var ashwood_victory_stage := ""
var ashwood_reward_reveal_complete := false
var ashwood_reward_reveal_nodes:Array[CanvasItem] = []
var ashwood_reward_tween:Tween
var ashwood_next_encounter := ""
var ashwood_selected_decision_text := ""
var ashwood_consequence_lines:Array[String] = []
var ashwood_consequence_phase := 0
var victory_sequence := false
var victory_phase := 0
var victory_timer := 0.0
var victory_level_ups := []
var world_map_view:Control = null
var world_map_content:Control = null
var world_map_zoom := 0.84
var world_map_pan := Vector2.ZERO
var world_map_dragging := false
var world_map_touches := {}
var toast := ""
var toast_time := 0.0
var ability_aiming := false
var aimed_ability_slot := -1
var aimed_ability_category := ""
var aimed_cast_mode := ""
var aimed_from_touch := false
var ability_button_held := false
var ability_aim_point := Vector2.ZERO
var tutorial_active := false
var tutorial_step := 0
var tutorial_targets := []
var tutorial_target_reached := []
var tutorial_move_round := 0
var tutorial_hero_clicked := false
var tutorial_timer := 0.0
var tutorial_ability_used := false
var tutorial_reject_time := 0.0
var tutorial_feedback_message := ""
var tutorial_idle_time := 0.0
var tutorial_idle_hint_shown := false
var tutorial_input_device := "pc"

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	ui.theme=build_ui_theme()
	ui.position = Vector2.ZERO
	ui.size = Vector2(W, H)
	add_child(combat_layer)
	add_child(ui)
	load_game()
	show_menu()

func ui_box(color:Color,radius:int=8,border_color:Color=Color.TRANSPARENT,border_width:int=0) -> StyleBoxFlat:
	return UiFactory.ui_box(color,radius,border_color,border_width)

func build_ui_theme() -> Theme:
	return UiFactory.build_theme(C_TEXT,C_MUTED,C_GOLD)

func save_slot_path(slot:int) -> String:
	return SaveManager.save_slot_path(slot)

func slot_state(slot:int) -> Dictionary:
	return SaveManager.slot_state(slot)

func default_casting_settings()->Dictionary:
	return SaveManager.default_casting_settings()

func fresh_state() -> Dictionary:
	return SaveManager.fresh_state()

func load_game() -> void:
	state=SaveManager.load_state(current_save_slot)

func persist_current_team() -> void:
	if current_team_slot < 0: state.active_team=state.selected_team.duplicate()
	else: state.saved_teams[current_team_slot]=state.selected_team.duplicate()
	save_game()

func save_game() -> void:
	SaveManager.save_state(current_save_slot,state)

func is_testing_save() -> bool:
	return current_save_slot==TESTING_SAVE_SLOT

func open_save_slot(slot:int) -> void:
	current_save_slot=slot; load_game()
	if slot==TESTING_SAVE_SLOT and state.guild_name=="":
		state=SaveManager.testing_state(); save_game(); show_hall()
	elif state.guild_name=="": show_creation()
	elif not bool(state.get("tutorial_complete",true)):start_tutorial()
	else: show_hall()

func request_delete_save(slot:int) -> void:
	var saved=slot_state(slot)
	if saved.is_empty():return
	var dialog:=ConfirmationDialog.new(); dialog.title="Delete Saved Guild"; dialog.dialog_text="Are you sure you want to delete %s?\nThis cannot be undone." % saved.get("guild_name","this guild"); dialog.ok_button_text="Delete"
	dialog.confirmed.connect(func():
		SaveManager.delete_slot(slot)
		if current_save_slot==slot:state=fresh_state()
		show_menu())
	ui.add_child(dialog);dialog.popup_centered(Vector2i(460,210))

func team_has_member(idx:int) -> bool:
	return TeamManager.has_member(state.selected_team,idx)

func team_is_active(idx:int) -> bool:
	return team_has_member(idx)

func active_team_index_of(idx:int) -> int:
	return TeamManager.member_index(state.selected_team,idx)

func reserve_team_indices() -> Array:
	return TeamManager.reserve_indices(state.heroes.size(),state.selected_team)

func toggle_team_member(idx:int) -> void:
	state.selected_team=TeamManager.toggle_member(state.selected_team,idx)
	save_game()

func hero_is_on_active_team(idx:int) -> bool:
	return TeamManager.has_member(state.active_team,idx)

func toggle_active_team_from_roster(idx:int) -> void:
	var was_active:=hero_is_on_active_team(idx)
	var next_active_team:Array=TeamManager.toggle_member(state.active_team,idx)
	if not was_active and next_active_team==state.active_team:
		flash("Active party is full.")
		return
	state.active_team=next_active_team
	if current_team_slot<0:state.selected_team=TeamManager.copy_team(state.active_team)
	save_game()
	show_roster()

func set_active_team() -> void:
	state.active_team=TeamManager.copy_team(state.selected_team)
	save_game()
	flash("Current party set as active.")

func load_active_team() -> void:
	state.selected_team=TeamManager.copy_team(state.active_team)
	save_game()
	flash("Loaded active party.")

func save_team_slot(slot:int) -> void:
	state.saved_teams=TeamManager.save_slot(state.saved_teams,slot,state.selected_team)
	save_game()
	flash("Saved team %d." % (slot + 1))

func load_team_slot(slot:int) -> void:
	var team:=TeamManager.load_slot(state.saved_teams,slot)
	if team.size()>0:
		state.selected_team=team
		save_game()
		flash("Loaded team %d." % (slot + 1))
	else:
		flash("Team %d is empty." % (slot + 1))

func team_slot_names(slot:int) -> String:
	var team:Array=state.active_team if slot<0 else state.saved_teams[slot] if slot<state.saved_teams.size() else []
	return TeamManager.slot_names(team,state.heroes)

func move_to_active_team(idx:int) -> void:
	if team_has_member(idx):
		return
	if state.selected_team.size() >= 4:
		flash("Active party is full.")
		return
	state.selected_team=TeamManager.add_member(state.selected_team,idx)
	persist_current_team()

func move_to_reserve(idx:int) -> void:
	if not team_has_member(idx):
		return
	state.selected_team=TeamManager.remove_member(state.selected_team,idx)
	persist_current_team()

func start_team_drag(idx:int, origin:String) -> void:
	team_swiping=false
	team_dragging = true
	team_drag_index = idx
	team_drag_origin = origin
	team_drag_preview=Button.new(); team_drag_preview.text=team_card_text(idx); team_drag_preview.size=Vector2(180,100); team_drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE; team_drag_preview.modulate=Color(1,1,1,.82); team_drag_preview.position=get_viewport().get_mouse_position()-Vector2(90,50); ui.add_child(team_drag_preview)
	queue_redraw()

func _input(event:InputEvent) -> void:
	if screen=="ashwood_victory" and ashwood_victory_stage=="consequence" and ashwood_consequence_phase>0 and ashwood_consequence_phase<=ashwood_consequence_lines.size() and (event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed or event is InputEventScreenTouch and event.pressed):
		advance_ashwood_consequence()
		get_viewport().set_input_as_handled()
		return
	if victory_sequence and victory_phase>=5 and (event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed or event is InputEventScreenTouch and event.pressed):
		if current_ashwood_encounter!="" and victory_timer<1.6:victory_timer=1.6;queue_redraw();get_viewport().set_input_as_handled();return
		victory_sequence=false
		if current_ashwood_encounter!="":show_ashwood_victory()
		else:show_zone_map(dungeon_id)
		return
	if screen=="team" and event is InputEventKey and event.pressed and not (get_viewport().gui_get_focus_owner() is LineEdit):
		if event.keycode==KEY_A: team_roster_page=max(0,team_roster_page-1); show_team()
		elif event.keycode==KEY_D: team_roster_page+=1; show_team()
	if screen=="team" and team_reserve_zone!=null:
		if event is InputEventScreenTouch:
			if event.pressed and Rect2(team_reserve_zone.global_position,team_reserve_zone.size).has_point(event.position): team_swipe_start=event.position; team_swiping=true
			elif not event.pressed and team_swiping: var dx=event.position.x-team_swipe_start.x; if abs(dx)>55: team_roster_page+=(-1 if dx>0 else 1); team_swiping=false; show_team()
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and Rect2(team_reserve_zone.global_position,team_reserve_zone.size).has_point(event.position): team_swipe_start=event.position; team_swiping=true
			elif not event.pressed and team_swiping and not team_dragging: var dx=event.position.x-team_swipe_start.x; if abs(dx)>55: team_roster_page+=(-1 if dx>0 else 1); team_swiping=false; show_team()
	# Mouse release is usually received by the drop zone, not the card that began
	# the drag, so finish team drags at the viewport level.
	if team_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_team_drag(event.position)
	elif team_dragging and event is InputEventMouseMotion and team_drag_preview!=null:
		team_drag_preview.position=event.position-Vector2(90,50)

func hero_matches(idx:int) -> bool:
	return RosterManager.hero_matches(state.heroes[idx],CLASSES,hero_search,hero_role_filter,hero_class_filter,hero_type_filter)

func sorted_hero_indices() -> Array:
	return RosterManager.sorted_indices(state.heroes,CLASSES,hero_search,hero_role_filter,hero_class_filter,hero_type_filter,roster_sort,roster_descending)

func filter_bar(refresh:Callable, include_sort:bool=false) -> HBoxContainer:
	var bar:=HBoxContainer.new(); bar.add_theme_constant_override("separation",8)
	var search:=LineEdit.new(); search.placeholder_text="Search"; search.text=hero_search; search.custom_minimum_size=Vector2(250,42); search.text_changed.connect(func(value): hero_search=value); search.text_submitted.connect(func(_value): refresh.call()); bar.add_child(search)
	var roles:=OptionButton.new(); roles.custom_minimum_size=Vector2(150,42)
	for value in ["All roles","Tank","Healer","DPS"]: roles.add_item(value)
	roles.select(["All roles","Tank","Healer","DPS"].find(hero_role_filter)); roles.item_selected.connect(func(i): hero_role_filter=roles.get_item_text(i); refresh.call()); bar.add_child(roles)
	var classes:=OptionButton.new(); classes.custom_minimum_size=Vector2(165,42)
	var class_values=["All classes","Guardian","Cleric","Rogue","Ranger","Mage","Warlock"]
	for value in class_values: classes.add_item(value)
	classes.select(class_values.find(hero_class_filter)); classes.item_selected.connect(func(i): hero_class_filter=classes.get_item_text(i); refresh.call()); bar.add_child(classes)
	var types:=OptionButton.new(); types.custom_minimum_size=Vector2(155,42)
	var type_values=["All Heroes","Standard Heroes","Special Heroes"]
	for value in type_values:types.add_item(value)
	types.select(type_values.find(hero_type_filter));types.item_selected.connect(func(i):hero_type_filter=types.get_item_text(i);refresh.call());bar.add_child(types)
	if include_sort:
		var sorts:=OptionButton.new(); sorts.custom_minimum_size=Vector2(145,42)
		for value in ["Name","Role","Class","Level"]: sorts.add_item(value)
		sorts.select(["Name","Role","Class","Level"].find(roster_sort)); sorts.item_selected.connect(func(i): roster_sort=sorts.get_item_text(i); refresh.call()); bar.add_child(sorts)
		bar.add_child(button("↓" if roster_descending else "↑",func(): roster_descending=not roster_descending; refresh.call(),54))
	return bar

func end_team_drag(mouse_pos:Vector2) -> void:
	if not team_dragging:
		return
	var dropped_on_active := team_active_zone != null and mouse_pos.x >= team_active_zone.global_position.x and mouse_pos.x <= team_active_zone.global_position.x + team_active_zone.size.x and mouse_pos.y >= team_active_zone.global_position.y and mouse_pos.y <= team_active_zone.global_position.y + team_active_zone.size.y
	var dropped_on_reserve := team_reserve_zone != null and mouse_pos.x >= team_reserve_zone.global_position.x and mouse_pos.x <= team_reserve_zone.global_position.x + team_reserve_zone.size.x and mouse_pos.y >= team_reserve_zone.global_position.y and mouse_pos.y <= team_reserve_zone.global_position.y + team_reserve_zone.size.y
	if dropped_on_active:
		move_to_active_team(team_drag_index)
	elif dropped_on_reserve:
		move_to_reserve(team_drag_index)
	team_dragging = false
	team_drag_index = -1
	team_drag_origin = ""
	if team_drag_preview!=null: team_drag_preview.queue_free(); team_drag_preview=null
	save_game()
	show_team()

func team_card_text(idx:int) -> String:
	var h = state.heroes[idx]
	return "%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h.name,h["class"],h["level"]]

func role_glyph(hero_class:String) -> String:
	match hero_class:
		"Guardian": return "◈"
		"Cleric": return "✚"
		"Mage": return "✦━"
		_: return "➶"

func member_type_label(member_type:String) -> String:
	return {"founding_recruit":"Founding Recruit","guild_recruit":"Guild Recruit","special_hero":"Special Hero","guild_champion":"Guild Champion","mercenary":"Mercenary"}.get(member_type,"Guild Recruit")

func legacy_stars(rank:int) -> String:
	var safe_rank=clampi(rank,0,5)
	return "★".repeat(safe_rank)+"☆".repeat(5-safe_rank)

func toggle_test_special_hero(idx:int) -> void:
	if not is_testing_save():return
	var hero=state.heroes[idx];var make_special=not bool(hero.get("is_special_hero",false));hero["is_special_hero"]=make_special;hero["member_type"]="special_hero" if make_special else "founding_recruit";save_game();show_roster()

func set_testing_hero_level(idx:int,value:float) -> void:
	if not is_testing_save() or idx<0 or idx>=state.heroes.size():return
	var hero:Dictionary=state.heroes[idx]
	hero.level=clampi(int(round(value)),1,TESTING_MAX_HERO_LEVEL)
	hero.xp=clampi(int(hero.get("xp",0)),0,int(hero.level)*100-1)
	save_game()
	show_roster()

func reset_testing_ashwood_story() -> void:
	if not is_testing_save():return
	var preserved_inventory:Array=state.zone0.get("inventory",[]).duplicate(true)
	var preserved_next_item_id:int=int(state.zone0.get("next_item_id",1))
	state.zone0=AshwoodManager.default_progress()
	state.zone0.inventory=preserved_inventory
	state.zone0.next_item_id=preserved_next_item_id
	state.selected_team=[0,1]
	state.active_team=[0,1]
	current_team_slot=-1
	pending_victory.clear()
	pending_map_reveals.clear()
	ashwood_victory_stage=""
	ashwood_reward_reveal_complete=false
	ashwood_next_encounter=""
	ashwood_selected_decision_text=""
	ashwood_consequence_lines.clear()
	ashwood_consequence_phase=0
	current_ashwood_encounter=""
	save_game()
	show_zone_map(0)

func request_reset_testing_story() -> void:
	if not is_testing_save():return
	var dialog:=ConfirmationDialog.new()
	dialog.name="TestingStoryResetDialog"
	dialog.title="Reset Ashwood Story?"
	dialog.dialog_text="Reset all Ashwood encounter progress, decisions, optional paths, and story choices?\n\nHeroes, levels, equipment, inventory, and guild resources will be kept. Your active party will return to Brann and Sera for story testing."
	dialog.ok_button_text="Reset Story"
	dialog.confirmed.connect(reset_testing_ashwood_story)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(590,260))

func ability_tooltip(hero_class:String,slot:int) -> String:
	return GameData.ability_tooltip(hero_class,slot)

func make_team_card(idx:int, origin:String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180,100)
	b.text = team_card_text(idx)
	b.add_theme_font_size_override("font_size",16)
	if bool(state.heroes[idx].get("is_special_hero",false)):
		var special_marker:=Label.new();special_marker.text="★ SPECIAL";special_marker.position=Vector2(7,6);special_marker.size=Vector2(90,20);special_marker.add_theme_font_size_override("font_size",10);special_marker.add_theme_color_override("font_color",C_GOLD);special_marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(special_marker)
		b.add_theme_stylebox_override("normal",ui_box(Color("2b3040"),9,C_GOLD,2))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	if team_has_member(idx):
		b.add_theme_color_override("font_color", CLASSES[state.heroes[idx]["class"]].color)
		b.add_theme_stylebox_override("normal",ui_box(Color("24364b"),9,CLASSES[state.heroes[idx]["class"]].color,2))
	else:
		b.add_theme_color_override("font_color", C_TEXT)
	b.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_team_drag(idx, origin)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_team_drag(get_viewport().get_mouse_position())
	)
	return b

func clear_all() -> void:
	for c in ui.get_children(): c.queue_free()
	for c in combat_layer.get_children(): c.queue_free()
	heroes.clear(); enemies.clear(); effects.clear();focused_enemy_index=-1
	combat_layer.visible = false
	ui.visible = true
	queue_redraw()

func base_screen(title:String, subtitle:String="") -> VBoxContainer:
	clear_all()
	var bg := ColorRect.new(); bg.color=C_BG; bg.position=Vector2.ZERO; bg.size=Vector2(W,H); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
	var root := VBoxContainer.new(); root.position=Vector2(32,22); root.size=Vector2(1216,676); root.add_theme_constant_override("separation",14); ui.add_child(root)
	var top := HBoxContainer.new(); root.add_child(top)
	var t := label(title,32,C_TEXT); t.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(t)
	if screen=="menu": top.add_child(button("×",func():get_tree().quit(),64))
	elif screen=="settings": top.add_child(button("Return",show_hall,130))
	elif screen=="hall": top.add_child(button("×",show_menu,64))
	elif screen=="zone_map": top.add_child(button("Return",show_dungeons,130))
	elif screen=="encounter_intro": top.add_child(button("Return",func():show_zone_map(0),130))
	elif screen in ["ashwood_victory","ashwood_consequence"]: pass
	else: top.add_child(button("Return",show_hall,130))
	if subtitle != "": root.add_child(label(subtitle,16,C_MUTED))
	var header_space:=Control.new(); header_space.custom_minimum_size.y=14; root.add_child(header_space)
	return root

func label(text:String, size:int=18, color:Color=C_TEXT) -> Label:
	return UiFactory.label(text,size,color)

func rule() -> HSeparator:
	return UiFactory.rule()

func button(text:String, callback:Callable, width:float=180) -> Button:
	return UiFactory.button(text,callback,width)

func panel() -> VBoxContainer:
	return UiFactory.panel(C_PANEL)

func show_menu() -> void:
	screen="menu"; var root=base_screen("FANTASY GUILD")
	root.add_spacer(false)
	var slots:=HBoxContainer.new(); slots.alignment=BoxContainer.ALIGNMENT_CENTER; slots.add_theme_constant_override("separation",14); root.add_child(slots)
	for slot in TOTAL_SAVE_SLOT_COUNT:
		var saved=slot_state(slot); var card:=Button.new(); card.custom_minimum_size=Vector2(280,210); card.add_theme_font_size_override("font_size",22)
		var slot_title:="TESTING" if slot==TESTING_SAVE_SLOT else "SAVE %d" % (slot+1)
		if saved.is_empty() or str(saved.get("guild_name",""))=="": card.text="%s\n\nEverything Unlocked" % slot_title if slot==TESTING_SAVE_SLOT else "%s\n\nNew Guild" % slot_title
		else:
			card.text="%s\n\n%s\n●  %d" % [slot_title,saved.get("guild_name","Unnamed Guild"),saved.get("gold",0)]
			var delete_button:=Button.new();delete_button.text="×";delete_button.position=Vector2(234,8);delete_button.size=Vector2(38,38);delete_button.add_theme_font_size_override("font_size",22);delete_button.tooltip_text="Delete saved guild";delete_button.mouse_filter=Control.MOUSE_FILTER_STOP;delete_button.pressed.connect(func(i=slot):request_delete_save(i));card.add_child(delete_button)
		card.pressed.connect(func(i=slot):open_save_slot(i)); slots.add_child(card)
	root.add_spacer(false)

func casting_option(device:String,category:String,choices:Array)->OptionButton:
	var option:=OptionButton.new();option.custom_minimum_size=Vector2(250,44)
	for choice in choices:option.add_item(choice[0]);option.set_item_metadata(option.item_count-1,choice[1])
	var current=str(state.casting_settings[device][category])
	for i in option.item_count:if option.get_item_metadata(i)==current:option.select(i)
	option.item_selected.connect(func(index:int):state.casting_settings[device][category]=option.get_item_metadata(index);save_game())
	return option

func show_settings()->void:
	screen="settings";var root=base_screen("Casting Settings")
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",36);root.add_child(columns)
	var categories={"Ground Targeted":"ground","Directional":"directional","Area Around Hero":"area","Enemy Targeted":"enemy","Ally Targeted":"ally"}
	for device in ["pc","mobile"]:
		var section:=VBoxContainer.new();section.custom_minimum_size.x=560;section.add_theme_constant_override("separation",10);columns.add_child(section)
		section.add_child(label("PC" if device=="pc" else "MOBILE",24,C_GOLD));section.add_child(label("Self-cast abilities are always instant.",15,C_MUTED))
		for title in categories:
			var row:=HBoxContainer.new();section.add_child(row);var name_label=label(title,17,C_TEXT);name_label.custom_minimum_size.x=260;name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(name_label)
			var category=categories[title];var choices:Array
			if category=="enemy" or category=="ally":choices=[["Cast on Target","target"],["Confirm Targeting","confirm"]]
			elif category=="area":choices=[["Instant","instant"],["Cast on Release","release"],["Confirm Cast","confirm"]]
			elif device=="mobile":choices=[["Facing Direction","facing"],["Cast on Release","release"],["Confirm Location","confirm"]]
			else:choices=[["Cast on Cursor","cursor"],["Cast on Release","release"],["Confirm Location","confirm"]]
			row.add_child(casting_option(device,category,choices))
	root.add_spacer(false);var reset:=button("Reset Defaults",func():state.casting_settings=default_casting_settings();save_game();show_settings(),190);reset.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(reset)

func show_creation() -> void:
	screen="creation"; var root=base_screen("Create Your Guild")
	var box=panel(); box.custom_minimum_size=Vector2(650,400); box.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(box)
	box.add_child(label("Guild name",18,C_GOLD)); var guild_name_input:=LineEdit.new(); guild_name_input.placeholder_text="The Dawnwardens"; guild_name_input.text="The Dawnwardens"; guild_name_input.custom_minimum_size.y=48; box.add_child(guild_name_input)
	box.add_child(label("Four volunteers have answered your banner: a Guardian, Cleric, Ranger, and Mage.",16,C_MUTED))
	box.add_spacer(false); box.add_child(button("Found Guild",func():
		state=fresh_state(); state.guild_name=guild_name_input.text.strip_edges() if guild_name_input.text.strip_edges()!="" else "Unnamed Guild"
		save_game(); start_tutorial(),240))

func hub_button(title:String, caption:String, callback:Callable, locked:bool=false) -> Button:
	var b:=Button.new()
	b.text=title if caption=="" else "%s\n%s" % [title,caption]
	b.custom_minimum_size=Vector2(260,125)
	b.add_theme_font_size_override("font_size",19)
	b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(callback)
	if locked:
		b.disabled=true
		b.tooltip_text="Locked"
		b.add_theme_color_override("font_disabled_color",Color("667187"))
		var veil:=ColorRect.new()
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.color=Color(0.025,0.032,0.05,.78)
		veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.add_child(veil)
		var lock_overlay:=LockOverlay.new()
		lock_overlay.name="LockOverlay"
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(lock_overlay)
	return b

func show_guild_page_intro(page_id:String) -> void:
	if not GameData.GUILD_PAGE_INTROS.has(page_id):return
	var intro:Dictionary=GameData.GUILD_PAGE_INTROS[page_id]
	var dialog:=AcceptDialog.new();dialog.name="GuildPageIntro";dialog.title=str(intro.title);dialog.dialog_text=str(intro.body);dialog.ok_button_text="Continue";dialog.min_size=Vector2i(560,250);ui.add_child(dialog);dialog.popup_centered(Vector2i(560,250))

func open_guild_page(page_id:String,page_callback:Callable) -> void:
	var first_visit:=not bool(state.seen_page_intros.get(page_id,false))
	if first_visit:
		state.seen_page_intros[page_id]=true
		save_game()
	page_callback.call()
	if first_visit:show_guild_page_intro(page_id)

func show_hall() -> void:
	screen="hall"; var root=base_screen("Guild Hall")
	var guild_status:=HBoxContainer.new();guild_status.custom_minimum_size.y=48;guild_status.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;guild_status.add_theme_constant_override("separation",18);root.add_child(guild_status)
	var guild_name_label:=label(state.guild_name,20,C_TEXT);guild_name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;guild_name_label.autowrap_mode=TextServer.AUTOWRAP_OFF;guild_name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;guild_status.add_child(guild_name_label)
	var prestige_label:=label("Guild Prestige  •  Rank %d"%state.guild_prestige_rank,17,C_GOLD);prestige_label.custom_minimum_size.x=280;prestige_label.autowrap_mode=TextServer.AUTOWRAP_OFF;prestige_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;prestige_label.tooltip_text="Guild Prestige represents the guild's reputation, accomplishments, and influence in the world.";guild_status.add_child(prestige_label)
	var renown_label:=label("Renown  %d"%state.guild_renown,17,C_MUTED);renown_label.custom_minimum_size.x=140;renown_label.autowrap_mode=TextServer.AUTOWRAP_OFF;renown_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;guild_status.add_child(renown_label)
	var battle:=Button.new(); battle.text="BATTLE"; battle.custom_minimum_size=Vector2(1170,120); battle.add_theme_font_size_override("font_size",34); battle.add_theme_color_override("font_color",C_GOLD); battle.pressed.connect(show_dungeons); root.add_child(battle)
	var destinations:=GridContainer.new(); destinations.columns=4; destinations.add_theme_constant_override("h_separation",18); destinations.add_theme_constant_override("v_separation",18); destinations.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(destinations)
	var all_systems:=bool(state.get("major_systems_unlocked",false))
	var zone0:Dictionary=state.get("zone0",AshwoodManager.default_progress())
	destinations.add_child(hub_button("Command Table","",func():open_guild_page("command",show_command_table),not all_systems))
	destinations.add_child(hub_button("Heroes","",func():open_guild_page("heroes",show_roster),not (all_systems or bool(state.tutorial_complete) or bool(zone0.heroes_unlocked))))
	destinations.add_child(hub_button("Party","",func():open_guild_page("party",show_team),not (all_systems or bool(zone0.party_management_unlocked))))
	destinations.add_child(hub_button("Vault","",func():open_guild_page("vault",show_vault),not (all_systems or bool(zone0.vault_unlocked))))
	destinations.add_child(hub_button("Tavern","",func():open_guild_page("tavern",func():flash("The Tavern is not open yet.")),not all_systems))
	destinations.add_child(hub_button("Merchant","",func():open_guild_page("merchant",show_market),not all_systems))
	destinations.add_child(hub_button("Workshop","",func():open_guild_page("workshop",show_crafting),not all_systems))
	var settings_button:=Button.new();settings_button.text="⚙";settings_button.tooltip_text="Casting Settings";settings_button.position=Vector2(24,648);settings_button.size=Vector2(52,52);settings_button.add_theme_font_size_override("font_size",25);settings_button.pressed.connect(show_settings);ui.add_child(settings_button)

func make_roster_card(idx:int) -> Button:
	var h=state.heroes[idx]
	var card:=Button.new(); card.custom_minimum_size=Vector2(170,108); card.text="%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h["name"],h["class"],h["level"]]
	card.add_theme_font_size_override("font_size",15); card.add_theme_color_override("font_color",CLASSES[h["class"]].color if idx==selected_roster_index else C_TEXT)
	if bool(h.get("is_special_hero",false)):
		var special_marker:=Label.new();special_marker.text="★ SPECIAL HERO";special_marker.position=Vector2(8,5);special_marker.size=Vector2(120,18);special_marker.add_theme_font_size_override("font_size",9);special_marker.add_theme_color_override("font_color",C_GOLD);special_marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(special_marker)
		card.add_theme_stylebox_override("normal",ui_box(Color("2b3040"),9,C_GOLD,2))
	var active_star:=Button.new();active_star.name="ActiveTeamStar";active_star.text="★" if hero_is_on_active_team(idx) else "☆";active_star.position=Vector2(134,4);active_star.size=Vector2(32,32);active_star.flat=true;active_star.focus_mode=Control.FOCUS_NONE;active_star.tooltip_text="Remove from Active Party" if hero_is_on_active_team(idx) else "Add to Active Party";active_star.add_theme_font_size_override("font_size",23);active_star.add_theme_color_override("font_color",C_GOLD if hero_is_on_active_team(idx) else C_MUTED);active_star.pressed.connect(func(i=idx):toggle_active_team_from_roster(i));card.add_child(active_star)
	if idx==selected_roster_index: card.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,CLASSES[h["class"]].color,2))
	card.pressed.connect(func():selected_roster_index=idx;show_roster())
	return card

func show_roster() -> void:
	screen="roster"; var root=base_screen("Hero Roster")
	var roster_toolbar:=HBoxContainer.new();roster_toolbar.add_theme_constant_override("separation",12);root.add_child(roster_toolbar)
	var roster_filters:=filter_bar(show_roster,true);roster_filters.size_flags_horizontal=Control.SIZE_EXPAND_FILL;roster_toolbar.add_child(roster_filters)
	var active_legend:=label("★  ACTIVE PARTY",14,C_GOLD);active_legend.custom_minimum_size.x=150;active_legend.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;active_legend.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;active_legend.tooltip_text="Toggle the star on any hero card to update the Active Party.";roster_toolbar.add_child(active_legend)
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); root.add_child(carousel)
	carousel.add_child(compact_button("←",func():hero_roster_page=max(0,hero_roster_page-1);show_roster(),48))
	var cards:=GridContainer.new(); cards.columns=6; cards.add_theme_constant_override("h_separation",10); cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(cards)
	var indices=sorted_hero_indices(); var pages=max(1,int(ceil(indices.size()/6.0))); hero_roster_page=clampi(hero_roster_page,0,pages-1)
	if not indices.is_empty() and not indices.has(selected_roster_index):selected_roster_index=indices[0]
	for card_index in range(hero_roster_page*6,min(indices.size(),hero_roster_page*6+6)):cards.add_child(make_roster_card(indices[card_index]))
	carousel.add_child(compact_button("→",func():hero_roster_page=min(pages-1,hero_roster_page+1);show_roster(),48))
	if indices.is_empty():var empty_result:=label("No heroes match the current filters.",18,C_MUTED);empty_result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(empty_result);return
	if selected_roster_index>=state.heroes.size():selected_roster_index=0
	var hero=state.heroes[selected_roster_index]; var info=CLASSES[hero["class"]]
	var detail:=HBoxContainer.new(); detail.add_theme_constant_override("separation",34); detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(detail)
	var character:=VBoxContainer.new(); character.custom_minimum_size.x=510; character.add_theme_constant_override("separation",8); detail.add_child(character)
	character.add_child(label(hero["name"],32,info.color));character.add_child(label("Level %d %s"%[hero.level,hero["class"]],16,C_MUTED))
	if bool(hero.get("is_special_hero",false)):character.add_child(label("★ SPECIAL HERO",13,C_GOLD))
	var equipment_row:=HBoxContainer.new();equipment_row.add_theme_constant_override("separation",12);character.add_child(equipment_row)
	var left_slots:=VBoxContainer.new();left_slots.add_theme_constant_override("separation",8);equipment_row.add_child(left_slots)
	for slot in ["Head","Chest","Weapon"]:var gear:=Button.new();gear.text=slot;gear.disabled=true;gear.custom_minimum_size=Vector2(105,70);left_slots.add_child(gear)
	var portrait:=Button.new();portrait.text=role_glyph(hero["class"]);portrait.disabled=true;portrait.custom_minimum_size=Vector2(230,220);portrait.add_theme_font_size_override("font_size",64);equipment_row.add_child(portrait)
	var right_slots:=VBoxContainer.new();right_slots.add_theme_constant_override("separation",8);equipment_row.add_child(right_slots)
	for slot in ["Neck","Hands","Trinket"]:var gear:=Button.new();gear.text=slot;gear.disabled=true;gear.custom_minimum_size=Vector2(105,70);right_slots.add_child(gear)
	var management:=VBoxContainer.new();management.custom_minimum_size.x=330;management.add_theme_constant_override("separation",9);detail.add_child(management);var management_offset:=Control.new();management_offset.custom_minimum_size.y=40;management.add_child(management_offset)
	management.add_child(label("Member Type   %s"%member_type_label(str(hero.get("member_type","founding_recruit"))),16));management.add_child(label("Hero Legacy   %s"%legacy_stars(int(hero.get("legacy_rank",0))),18,C_GOLD));management.add_child(label("Gear Score   %d"%hero.gear,16));management.add_child(label("Experience   %d / %d"%[hero.xp,hero.level*100],16));management.add_child(label("Health   %d     Power   %d"%[int(info.hp),int(info.damage)],16))
	var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",7);management.add_child(tabs);for section in ["Talents","Profession","History"]:tabs.add_child(compact_button(section,func(section_name=section):flash("%s management is coming next."%section_name),100))
	if is_testing_save():
		management.add_child(rule())
		management.add_child(label("TESTING TOOLS",13,Color("b381ff")))
		var level_row:=HBoxContainer.new();level_row.add_theme_constant_override("separation",12);management.add_child(level_row)
		var level_caption:=label("Hero Level",15,C_TEXT);level_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;level_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;level_row.add_child(level_caption)
		var level_picker:=SpinBox.new();level_picker.name="TestingHeroLevel";level_picker.min_value=1;level_picker.max_value=TESTING_MAX_HERO_LEVEL;level_picker.step=1;level_picker.allow_greater=false;level_picker.allow_lesser=false;level_picker.value=int(hero.level);level_picker.custom_minimum_size=Vector2(105,40);level_picker.value_changed.connect(func(value,hero_index=selected_roster_index):set_testing_hero_level(hero_index,value));level_row.add_child(level_picker)
		management.add_child(compact_button("Toggle Special Hero",func():toggle_test_special_hero(selected_roster_index),190))
	var abilities:=VBoxContainer.new();abilities.custom_minimum_size.x=245;abilities.add_theme_constant_override("separation",8);detail.add_child(abilities);var abilities_offset:=Control.new();abilities_offset.custom_minimum_size.y=40;abilities.add_child(abilities_offset);abilities.add_child(label("ABILITIES",13,C_MUTED))
	for slot in 4:var ability:=Button.new();ability.text=["Q","W","E","R"][slot]+"   "+ABILITIES[hero["class"]][slot];ability.custom_minimum_size=Vector2(235,52);ability.tooltip_text=ability_tooltip(hero["class"],slot);abilities.add_child(ability)

func compact_button(text:String, callback:Callable, width:float=100) -> Button:
	return UiFactory.compact_button(text,callback,width)

func select_team_slot(option:int) -> void:
	current_team_slot=option-1
	state.selected_team=(state.active_team if current_team_slot<0 else state.saved_teams[current_team_slot]).duplicate()
	save_game(); show_team()

func rename_current_team(value:String) -> void:
	if current_team_slot>=0 and value.strip_edges()!="": state.team_names[current_team_slot]=value.strip_edges(); save_game()

func show_team() -> void:
	screen="team"; var root=base_screen("Team Builder")
	var chooser:=HBoxContainer.new(); chooser.add_theme_constant_override("separation",10); root.add_child(chooser)
	var teams:=OptionButton.new(); teams.custom_minimum_size=Vector2(260,44); teams.add_item("Active Party")
	for team_name in state.team_names: teams.add_item(team_name)
	teams.select(current_team_slot+1); teams.item_selected.connect(select_team_slot); chooser.add_child(teams)
	if current_team_slot>=0:
		var rename:=LineEdit.new(); rename.placeholder_text="Team name"; rename.text=state.team_names[current_team_slot]; rename.custom_minimum_size=Vector2(220,44); rename.text_submitted.connect(func(value): rename_current_team(value); show_team()); chooser.add_child(rename)
	var chooser_space:=Control.new(); chooser_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL; chooser.add_child(chooser_space)
	var party_count:=label("%d / 4" % state.selected_team.size(),18,C_GOLD); party_count.custom_minimum_size.x=60; party_count.autowrap_mode=TextServer.AUTOWRAP_OFF; party_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; chooser.add_child(party_count)
	team_active_zone=VBoxContainer.new(); team_active_zone.custom_minimum_size=Vector2(1160,100); root.add_child(team_active_zone)
	var active:=HBoxContainer.new(); active.add_theme_constant_override("separation",12); team_active_zone.add_child(active)
	for idx in state.selected_team: active.add_child(make_team_card(idx,"active"))
	for _slot in range(4-state.selected_team.size()): var empty:=Button.new(); empty.text="Empty"; empty.disabled=true; empty.custom_minimum_size=Vector2(180,100); active.add_child(empty)
	var party_roster_gap:=Control.new();party_roster_gap.custom_minimum_size.y=24;root.add_child(party_roster_gap)
	var roster_heading:=HBoxContainer.new(); root.add_child(roster_heading); var roster_title:=label("GUILD ROSTER",18,C_GOLD); roster_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; roster_heading.add_child(roster_title)
	root.add_child(filter_bar(show_team,true))
	team_reserve_zone=VBoxContainer.new(); team_reserve_zone.custom_minimum_size=Vector2(1160,180); team_reserve_zone.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(team_reserve_zone)
	var carousel:=HBoxContainer.new(); carousel.add_theme_constant_override("separation",8); team_reserve_zone.add_child(carousel)
	carousel.add_child(compact_button("←",func(): team_roster_page=max(0,team_roster_page-1); show_team(),48))
	var reserves:=GridContainer.new(); reserves.columns=5; reserves.add_theme_constant_override("h_separation",12); reserves.add_theme_constant_override("v_separation",12); reserves.size_flags_horizontal=Control.SIZE_EXPAND_FILL; carousel.add_child(reserves)
	var roster_indices=sorted_hero_indices().filter(func(idx):return not team_has_member(idx)); var page_count=max(1,int(ceil(roster_indices.size()/10.0))); team_roster_page=clampi(team_roster_page,0,page_count-1)
	for card_index in range(team_roster_page*10,min(roster_indices.size(),team_roster_page*10+10)):
		reserves.add_child(make_team_card(roster_indices[card_index],"reserve"))
	if roster_indices.is_empty(): var empty_message:=label("All available heroes are assigned to this team.",16,C_MUTED); empty_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; empty_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL; reserves.add_child(empty_message)
	carousel.add_child(compact_button("→",func(): team_roster_page=min(page_count-1,team_roster_page+1); show_team(),48))

func clamp_world_map_pan() -> void:
	if world_map_view==null or world_map_content==null:return
	var content_size=world_map_content.size*world_map_zoom; var view_size=world_map_view.size
	world_map_pan.x=(view_size.x-content_size.x)*.5 if content_size.x<=view_size.x else clamp(world_map_pan.x,view_size.x-content_size.x,0.0)
	world_map_pan.y=(view_size.y-content_size.y)*.5 if content_size.y<=view_size.y else clamp(world_map_pan.y,view_size.y-content_size.y,0.0)
	world_map_content.position=world_map_pan; world_map_content.scale=Vector2.ONE*world_map_zoom

func zoom_world_map(amount:float,focus:Vector2) -> void:
	var old_zoom=world_map_zoom; world_map_zoom=clamp(world_map_zoom*amount,.84,2.2)
	var map_point=(focus-world_map_pan)/old_zoom; world_map_pan=focus-map_point*world_map_zoom; clamp_world_map_pan()

func handle_world_map_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:zoom_world_map(1.12,event.position)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:zoom_world_map(.89,event.position)
		elif event.button_index==MOUSE_BUTTON_LEFT:world_map_dragging=event.pressed
	elif event is InputEventMouseMotion and world_map_dragging:
		world_map_pan+=event.relative;clamp_world_map_pan()
	elif event is InputEventScreenTouch:
		if event.pressed:world_map_touches[event.index]=event.position
		else:world_map_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		var old_positions=world_map_touches.duplicate();world_map_touches[event.index]=event.position
		if world_map_touches.size()==1:world_map_pan+=event.relative;clamp_world_map_pan()
		elif world_map_touches.size()>=2:
			var ids=world_map_touches.keys();var old_a=old_positions.get(ids[0],world_map_touches[ids[0]]);var old_b=old_positions.get(ids[1],world_map_touches[ids[1]]);var new_a=world_map_touches[ids[0]];var new_b=world_map_touches[ids[1]];var old_distance=old_a.distance_to(old_b);var new_distance=new_a.distance_to(new_b)
			if old_distance>1:zoom_world_map(new_distance/old_distance,(new_a+new_b)*.5)

func show_dungeons() -> void:
	screen="dungeons"; clear_all()
	world_map_view=Control.new(); world_map_view.position=Vector2.ZERO; world_map_view.size=Vector2(W,H); world_map_view.clip_contents=true; world_map_view.mouse_filter=Control.MOUSE_FILTER_STOP; world_map_view.gui_input.connect(handle_world_map_input); ui.add_child(world_map_view)
	world_map_content=Control.new(); world_map_content.size=GameData.WORLD_MAP_SIZE; world_map_content.mouse_filter=Control.MOUSE_FILTER_PASS; world_map_view.add_child(world_map_content)
	var map_image:=TextureRect.new(); map_image.texture=load("res://assets/world_map.png"); map_image.position=Vector2.ZERO; map_image.size=world_map_content.size; map_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; map_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; map_image.modulate=Color(.86,.89,.95,1); map_image.mouse_filter=Control.MOUSE_FILTER_IGNORE; world_map_content.add_child(map_image)
	var active_region=GameData.WORLD_ACTIVE_REGION
	var completed_count:=0
	for encounter_key in AshwoodData.MANDATORY_ORDER:
		if AshwoodManager.encounter_is_completed(state.zone0,encounter_key):completed_count+=1
	var ashwood:=Button.new(); ashwood.position=active_region.position; ashwood.size=active_region.size; ashwood.text="%s\n%d / 7" % [active_region.name,completed_count]; ashwood.add_theme_font_size_override("font_size",19); ashwood.add_theme_color_override("font_color",C_GOLD); ashwood.add_theme_stylebox_override("normal",ui_box(Color(0.04,.08,.10,.92),12,C_GOLD,3)); ashwood.pressed.connect(func():show_zone_map(active_region.zone)); world_map_content.add_child(ashwood)
	for region in GameData.LOCKED_WORLD_REGIONS:
		var marker:=Button.new(); marker.position=region[1]; marker.size=Vector2(210,72); marker.text="🔒  %s" % region[0]; marker.disabled=true; marker.mouse_filter=Control.MOUSE_FILTER_IGNORE; marker.tooltip_text="Locked region"; marker.add_theme_font_size_override("font_size",15); marker.add_theme_stylebox_override("disabled",ui_box(Color(0.05,.07,.11,.88),10,Color("68778e"),2)); world_map_content.add_child(marker)
	var return_button:=button("Return",show_hall,130); return_button.position=Vector2(1116,22); world_map_view.add_child(return_button)
	var zoom_controls:=HBoxContainer.new(); zoom_controls.position=Vector2(995,24); zoom_controls.add_theme_constant_override("separation",6); world_map_view.add_child(zoom_controls); zoom_controls.add_child(compact_button("−",func():zoom_world_map(.85,world_map_view.size*.5),46));zoom_controls.add_child(compact_button("+",func():zoom_world_map(1.18,world_map_view.size*.5),46))
	if is_testing_save():
		var reset_story:=button("TEST: RESET ASHWOOD STORY",request_reset_testing_story,265);reset_story.name="TestingResetStoryButton";reset_story.position=Vector2(24,648);reset_story.tooltip_text="Reset Ashwood story progress while keeping testing heroes, levels, equipment, inventory, and guild resources.";reset_story.add_theme_color_override("font_color",Color("d9c2ff"));reset_story.add_theme_stylebox_override("normal",ui_box(Color("261d3d"),8,Color("b381ff"),2));world_map_view.add_child(reset_story)
	clamp_world_map_pan();call_deferred("clamp_world_map_pan")

func show_zone_map(zone:int) -> void:
	if zone==0:
		show_ashwood_map()
		return
	screen="zone_map"; dungeon_id=zone; var root=base_screen(GameData.ZONE_NAMES[zone])
	var map:=Control.new(); map.custom_minimum_size=Vector2(1120,445); root.add_child(map)
	var node_names=GameData.ZONE_NODE_NAMES[zone]
	var positions=GameData.ZONE_NODE_POSITIONS
	for i in 9:
		var line:=Line2D.new(); line.width=5; line.default_color=C_GOLD if i<int(state.zone_progress[zone]) else Color("3d4a5d"); line.points=PackedVector2Array([positions[i]+Vector2(55,32),positions[i+1]+Vector2(55,32)]); map.add_child(line)
	for branch_data in GameData.ZONE_BRANCHES:
		var line:=Line2D.new(); line.width=4; line.default_color=Color("b381ff") if state.zone_branches[zone][branch_data[2]] else Color("3d4a5d"); line.points=PackedVector2Array([positions[branch_data[0]]+Vector2(55,32),positions[branch_data[1]]+Vector2(55,32)]); map.add_child(line)
	for node in 12:
		var is_branch=node>=10; var branch_index=node-10; var unlocked=node<=int(state.zone_progress[zone]) if not is_branch else int(state.zone_progress[zone])>=(3 if branch_index==0 else 6); var completed=node<int(state.zone_progress[zone]) if not is_branch else state.zone_branches[zone][branch_index]
		var encounter:=Button.new(); encounter.position=positions[node]; encounter.size=Vector2(110,64); encounter.text=("✓\n" if completed else "")+(node_names[node] if unlocked else "?"); encounter.disabled=not unlocked; encounter.add_theme_font_size_override("font_size",12); encounter.add_theme_color_override("font_color",Color("b381ff") if is_branch else C_GOLD if node==9 else C_TEXT); encounter.pressed.connect(func(i=node,z=zone):start_battle(z,i)); map.add_child(encounter)

func add_dotted_map_connection(map:Control,from_pos:Vector2,to_pos:Vector2,color:Color) -> Node2D:
	var trail:=Node2D.new();trail.name="OptionalPathTrail";map.add_child(trail)
	var path_length:float=from_pos.distance_to(to_pos)
	if path_length<=0:return trail
	var direction:Vector2=from_pos.direction_to(to_pos)
	var distance:=0.0
	while distance<path_length:
		var segment_end:float=min(distance+13.0,path_length)
		var segment:=Line2D.new();segment.width=4;segment.default_color=color;segment.points=PackedVector2Array([from_pos+direction*distance,from_pos+direction*segment_end]);trail.add_child(segment)
		distance+=23.0
	return trail

func show_ashwood_map() -> void:
	if state.zone0.zone0_boss_defeated and str(state.zone0.special_hero_choice)=="":
		show_pending_special_choice()
		return
	screen="zone_map"
	dungeon_id=0
	var root=base_screen("THE ASHWOOD MARCHES")
	var summary:="The servant has fallen. Completed locations now offer expanded patrols." if state.zone0.zone0_boss_defeated else "Choose a revealed location. Completed battles can be replayed for XP, gold, and loot."
	root.add_child(label(summary,15,C_MUTED))
	var map:=Control.new()
	map.custom_minimum_size=Vector2(1160,470)
	root.add_child(map)
	var optional_source_revealed:bool=AshwoodManager.encounter_is_unlocked(state.zone0,"raider_cache")
	var optional_branch_hidden:bool=not bool(state.zone0.optional_branch_discovered) and not bool(state.zone0.zone0_boss_defeated)
	for connection in AshwoodData.MAP_CONNECTIONS:
		var from_id:String=connection[0]
		var to_id:String=connection[1]
		if not AshwoodManager.encounter_is_unlocked(state.zone0,from_id) or not AshwoodManager.encounter_is_unlocked(state.zone0,to_id):continue
		var from_pos:Vector2=AshwoodData.ENCOUNTERS[from_id].map_position+Vector2(65,38)
		var to_pos:Vector2=AshwoodData.ENCOUNTERS[to_id].map_position+Vector2(65,38)
		var line:=Line2D.new()
		line.width=5
		line.default_color=Color("9a6bdb") if bool(AshwoodData.ENCOUNTERS[to_id].optional) else C_GOLD
		line.points=PackedVector2Array([from_pos,to_pos])
		map.add_child(line)
	if optional_source_revealed and optional_branch_hidden:
		var optional_from:Vector2=AshwoodData.ENCOUNTERS.raider_cache.map_position+Vector2(65,38)
		var optional_to:Vector2=AshwoodData.ENCOUNTERS.ruined_chapel.map_position+Vector2(65,38)
		add_dotted_map_connection(map,optional_from,optional_to,Color("76558f"))
	for encounter_key in AshwoodData.all_encounter_ids():
		if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):continue
		var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
		var completed:=AshwoodManager.encounter_is_completed(state.zone0,encounter_key)
		var encounter_button:=Button.new()
		encounter_button.position=encounter_data.map_position
		encounter_button.size=Vector2(132,76)
		encounter_button.text=("✓  " if completed else "")+str(encounter_data.display_name)
		encounter_button.add_theme_font_size_override("font_size",13)
		encounter_button.add_theme_color_override("font_color",C_GREEN if completed else Color("c692ff") if encounter_data.optional else C_GOLD)
		encounter_button.add_theme_stylebox_override("normal",ui_box(Color("182536"),10,Color("9a6bdb") if encounter_data.optional else C_GOLD,2))
		encounter_button.pressed.connect(func(id=encounter_key):open_ashwood_encounter(id))
		map.add_child(encounter_button)
		if encounter_key in pending_map_reveals:
			encounter_button.modulate=Color(1.5,1.35,.75,1)
			var tween=create_tween();tween.tween_property(encounter_button,"modulate",Color.WHITE,.8)
	if optional_source_revealed and optional_branch_hidden:
		var clue:=Button.new()
		clue.name="OptionalPathHint"
		clue.position=Vector2(585,350);clue.size=Vector2(132,76)
		clue.text=("Ruined chapel?" if state.zone0.optional_clue else "?")+"\nOPTIONAL PATH"
		clue.disabled=not state.zone0.optional_available
		clue.tooltip_text="Complete the nearby route to investigate this optional trail." if clue.disabled else "Investigate the optional trail."
		clue.add_theme_font_size_override("font_size",13);clue.add_theme_color_override("font_color",Color("c692ff"));clue.add_theme_color_override("font_disabled_color",Color("876c9e"));clue.add_theme_stylebox_override("normal",ui_box(Color("151c29"),10,Color("8b63a8"),2));clue.add_theme_stylebox_override("disabled",ui_box(Color("121824"),10,Color("5f496f"),2));clue.pressed.connect(discover_ashwood_optional_branch);map.add_child(clue)
	pending_map_reveals.clear()

func discover_ashwood_optional_branch() -> void:
	if AshwoodManager.discover_optional_branch(state.zone0):
		pending_map_reveals=["ruined_chapel"]
		save_game()
		show_ashwood_consequence("The roots give way to a ruined chapel path. Something below is still drawing power from its runes.")

func open_ashwood_encounter(encounter_key:String) -> void:
	if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):return
	if AshwoodManager.encounter_is_completed(state.zone0,encounter_key) and ashwood_story_is_pending(encounter_key):
		resume_pending_ashwood_story(encounter_key)
		return
	if encounter_key=="first_battle":start_ashwood_battle(encounter_key)
	else:show_encounter_intro(encounter_key)

func show_encounter_intro(encounter_key:String) -> void:
	if not AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):return
	if AshwoodManager.encounter_is_completed(state.zone0,encounter_key) and ashwood_story_is_pending(encounter_key):
		resume_pending_ashwood_story(encounter_key)
		return
	if encounter_key=="first_battle":
		start_ashwood_battle(encounter_key)
		return
	current_ashwood_encounter=encounter_key
	screen="encounter_intro"
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	var completed:=AshwoodManager.encounter_is_completed(state.zone0,encounter_key)
	var root=base_screen(str(encounter_data.display_name),"REPLAY" if completed else "SCENARIO")
	var story_panel=panel();story_panel.custom_minimum_size=Vector2(900,250);story_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(story_panel)
	story_panel.add_child(label(str(encounter_data.get("replay_scenario","Ashwood remains dangerous in the wake of the guild's earlier victory.")) if completed else str(encounter_data.scenario),19,C_TEXT))
	if not completed:
		for moment in encounter_data.get("story_moments",[]):
			story_panel.add_child(label(str(moment),15,Color("c6b6da")))
	story_panel.add_child(rule())
	story_panel.add_child(label("OBJECTIVE",13,C_MUTED));story_panel.add_child(label(str(encounter_data.objective.label),22,C_GOLD))
	var rewards:Dictionary=encounter_data.repeat_rewards if completed else encounter_data.first_rewards
	story_panel.add_child(label("Rewards: %d gold  •  %d XP%s"%[rewards.gold,rewards.xp,"  •  loot chance" if completed or not rewards.get("loot",[]).is_empty() else ""],16,C_GREEN))
	root.add_spacer(false)
	var begin:=button("Begin Replay" if completed else "Enter Encounter",func():start_ashwood_battle(encounter_key),240);begin.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(begin)

func show_command_table() -> void:
	screen="command"; var root=base_screen("Command Table")
	var mission_data=GameData.MISSIONS
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var missions:=VBoxContainer.new(); missions.custom_minimum_size.x=350; missions.add_theme_constant_override("separation",10); columns.add_child(missions); missions.add_child(label("AVAILABLE MISSIONS",14,C_MUTED))
	for i in mission_data.size():
		var mission_button:=Button.new(); mission_button.text="%s\n%s"%[mission_data[i][0],mission_data[i][1]]; mission_button.custom_minimum_size=Vector2(340,78); if i==selected_mission:mission_button.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); mission_button.pressed.connect(func(index=i):selected_mission=index;show_command_table()); missions.add_child(mission_button)
	var chosen=mission_data[selected_mission]; var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details); details.add_child(label(chosen[0],30,C_TEXT)); details.add_child(label(chosen[1],18,C_GOLD)); details.add_child(label("REWARDS",13,C_MUTED)); details.add_child(label(chosen[2],20,C_GREEN)); details.add_child(label("ASSIGNED HEROES",13,C_MUTED)); var slots:=HBoxContainer.new(); details.add_child(slots); for i in 4:var slot:=Button.new();slot.text="+";slot.custom_minimum_size=Vector2(110,90);slots.add_child(slot); details.add_child(button("Assign Heroes",func(): flash("Hero assignment is the next automation step."),220))

func auto_run(i:int) -> void:
	if state.gold<40: flash("Not enough gold."); return
	state.gold-=40; grant_rewards(i,false); save_game(); flash("Expedition complete. Reduced auto-run rewards delivered."); show_dungeons()

func show_market() -> void:
	screen="market"; var root=base_screen("Merchant Contacts")
	var gold_row:=HBoxContainer.new(); root.add_child(gold_row)
	var gold_label:=label("●  %d" % state.gold,20,C_GOLD); gold_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; gold_row.add_child(gold_label)
	root.add_child(label("Discover merchants while exploring the world. Once you have made contact, they can provide goods, recipes, selling services, and trade contracts.",16,C_MUTED))
	var merchant_data=GameData.MERCHANTS
	var merchant_row:=HBoxContainer.new();merchant_row.add_theme_constant_override("separation",14);merchant_row.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(merchant_row)
	for merchant in merchant_data:
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(390,300);card.add_theme_stylebox_override("panel",ui_box(Color("182536"),12,Color("35445a"),1));merchant_row.add_child(card)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",9);card.add_child(content);content.add_child(label(merchant[0],24,C_GOLD));content.add_child(label(merchant[1],16,C_TEXT));content.add_child(label("Location  •  "+merchant[2],14,C_MUTED));content.add_child(rule());content.add_child(label("Offers",13,C_MUTED));content.add_child(label(merchant[3],16,C_TEXT));content.add_spacer(false)
		var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);content.add_child(actions);actions.add_child(compact_button("View Wares",func(merchant_name=merchant[0]):flash("%s's inventory will be added later."%merchant_name),105));actions.add_child(compact_button("View Contracts",func(merchant_name=merchant[0]):flash("%s's contracts will be added later."%merchant_name),120));actions.add_child(compact_button("Sell Items",func(merchant_name=merchant[0]):flash("Selling through %s will be added later."%merchant_name),100))

func show_crafting() -> void:
	screen="crafting"; var root=base_screen("Professions")
	var profession_data=GameData.PROFESSIONS
	var columns:=HBoxContainer.new(); columns.add_theme_constant_override("separation",18); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(columns)
	var profession_scroll:=ScrollContainer.new(); profession_scroll.custom_minimum_size=Vector2(360,485); columns.add_child(profession_scroll); var profession_list:=VBoxContainer.new(); profession_list.custom_minimum_size.x=340; profession_list.add_theme_constant_override("separation",8); profession_scroll.add_child(profession_list)
	for i in profession_data.size():
		var entry:=Button.new(); entry.custom_minimum_size=Vector2(330,78); entry.text=profession_data[i][0]; entry.add_theme_color_override("font_color",C_GOLD if i==selected_profession else C_TEXT); if i==selected_profession:entry.add_theme_stylebox_override("normal",ui_box(Color("26384e"),9,C_GOLD,2)); entry.pressed.connect(func(index=i):selected_profession=index;show_crafting()); profession_list.add_child(entry)
	var details:=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); columns.add_child(details)
	var chosen=profession_data[selected_profession]; details.add_child(label(chosen[0],30,C_GOLD)); details.add_child(label("AVAILABLE RECIPE",13,C_MUTED)); details.add_child(label(chosen[1],24,C_TEXT)); details.add_child(label("Cost  •  "+chosen[2],17,C_MUTED)); details.add_child(button("Craft",func():craft(chosen[3],chosen[4],chosen[5]),190))

func craft(resource:String,cost:int,kind:String) -> void:
	if state[resource]<cost: flash("Missing materials."); return
	state[resource]-=cost
	if kind=="gear": for h in state.heroes: h["gear"]+=1
	else: state["tonics"]=state.get("tonics",0)+1
	save_game(); show_crafting(); flash("Craft complete!")

func vault_used()->int: return state.ore+state.herbs+state.dust+state.get("tonics",0)
func request_bag_unlock(slot:int) -> void:
	if slot<state.vault_level:return
	var cost=GameData.STORAGE_BAG_UNLOCK_BASE_COST*state.vault_level; var dialog:=ConfirmationDialog.new(); dialog.title="Unlock Bag Slot"; dialog.dialog_text="Unlock this bag slot for ● %d?" % cost; dialog.ok_button_text="Unlock"
	dialog.confirmed.connect(func():
		if state.gold>=cost: state.gold-=cost; state.vault_level+=1; state.vault_limit=min(GameData.STORAGE_MAX_CAPACITY,state.vault_limit+GameData.STORAGE_BAG_CAPACITY); save_game(); show_vault()
		else: flash("Not enough gold."))
	ui.add_child(dialog); dialog.popup_centered(Vector2i(420,180))

func show_vault() -> void:
	screen="vault"; var root=base_screen("Item Storage")
	var toolbar:=HBoxContainer.new(); toolbar.custom_minimum_size.y=44; toolbar.size_flags_vertical=Control.SIZE_SHRINK_BEGIN; root.add_child(toolbar)
	var vault_gold:=label("●  %d" % state.gold,18,C_GOLD); vault_gold.custom_minimum_size.x=220; vault_gold.autowrap_mode=TextServer.AUTOWRAP_OFF; toolbar.add_child(vault_gold)
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; toolbar.add_child(spacer)
	var organize:=compact_button("▦↕",func(): flash("Vault organized by item type."),58); organize.custom_minimum_size.y=42; organize.size_flags_vertical=Control.SIZE_SHRINK_CENTER; organize.tooltip_text="Auto Organize"; toolbar.add_child(organize)
	if not state.zone0.inventory.is_empty():
		root.add_child(label("ASHWOOD EQUIPMENT",13,C_MUTED))
		var equipment_scroll:=ScrollContainer.new();equipment_scroll.custom_minimum_size=Vector2(1160,96);root.add_child(equipment_scroll)
		var equipment_row:=HBoxContainer.new();equipment_row.add_theme_constant_override("separation",8);equipment_scroll.add_child(equipment_row)
		for item in state.zone0.inventory:
			var item_card:=VBoxContainer.new();item_card.custom_minimum_size=Vector2(220,88);item_card.add_theme_constant_override("separation",3);equipment_row.add_child(item_card)
			item_card.add_child(label(str(item.name),15,AshwoodData.RARITY_COLORS[item.rarity]));item_card.add_child(label("%s %s  •  +%d Gear"%[item.rarity,item["class"],item.power],12,C_MUTED))
			var equipped_by=int(item.get("equipped_by",-1))
			if equipped_by>=0:item_card.add_child(label("Equipped by "+str(state.heroes[equipped_by].name),12,C_GREEN))
			else:item_card.add_child(compact_button("Equip",func(id=item.id):equip_ashwood_item(id),80))
	var item_grid:=GridContainer.new(); item_grid.columns=GameData.STORAGE_COLUMNS; item_grid.add_theme_constant_override("h_separation",6); item_grid.add_theme_constant_override("v_separation",6); item_grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(item_grid)
	var contents=[]
	for item in GameData.STORAGE_ITEMS:contents.append({"name":item[0],"count":state.get(item[1],0),"color":item[2]})
	for slot in state.vault_limit:
		var cell:=Button.new(); cell.custom_minimum_size=Vector2(68,62)
		if slot<contents.size() and contents[slot].count>0: cell.text="%s\n%d" % [contents[slot].name,contents[slot].count]; cell.add_theme_color_override("font_color",contents[slot].color)
		else: cell.text=""
		item_grid.add_child(cell)
	var bags:=HBoxContainer.new(); bags.add_theme_constant_override("separation",8); bags.alignment=BoxContainer.ALIGNMENT_CENTER; root.add_child(bags)
	for slot in GameData.STORAGE_BAG_SLOTS:
		var bag:=Button.new(); bag.custom_minimum_size=Vector2(76,64); bag.text="▣" if slot<state.vault_level else "▧"; bag.add_theme_font_size_override("font_size",30); bag.modulate=Color.WHITE if slot<state.vault_level else Color(.35,.38,.45,1); bag.tooltip_text="Installed bag" if slot<state.vault_level else "Locked bag slot"; bag.pressed.connect(func(i=slot):request_bag_unlock(i)); bags.add_child(bag)

func start_battle(id:int,node:int=0,party_override:Array=[]) -> void:
	current_ashwood_encounter=""
	battle_objective={};objective_progress=0;objective_health=0;objective_max_health=0;objective_complete=true;objective_pressure_spawned=false;objective_notice="";objective_notice_time=0;objective_banner_time=0;objective_combat_intro="";rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
	dungeon_id=id; encounter_id=node; clear_all(); ui.visible=false; combat_layer.visible=true; screen="combat"; battle_time=0; spawn_timer=0; battle_over=false; paused=false; selected=0;focused_enemy_index=-1; wave_index=0; total_waves=3+(1 if node>=3 else 0); wave_spawn_remaining=0; wave_break=.8; waiting_wave=false; battle_gold_earned=0
	var starts=[Vector2(125,170),Vector2(125,270),Vector2(125,370),Vector2(125,470)]
	battle_hero_indices=(state.selected_team if party_override.is_empty() else party_override).slice(0,4)
	for i in battle_hero_indices.size():
		var data=state.heroes[battle_hero_indices[i]];var c=CLASSES[data["class"]];var auto_damage=c.damage+(data.level-1)*1.2+(data.gear-10)*.35;var combat_hp:float=c.hp+(data.level-1)*15;heroes.append({"name":data.name,"class":data["class"],"combat_affiliation":"player","independent":false,"pos":starts[i],"dest":starts[i],"facing_direction":Vector2.RIGHT,"hp":combat_hp,"max_hp":combat_hp,"damage":auto_damage,"range":c.range,"target":-1,"heal_target":-1,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"last_hit":0.0})
	queue_redraw()

func ashwood_party_indices(_encounter_key:String) -> Array:
	return state.selected_team.duplicate()

func start_ashwood_battle(encounter_key:String) -> void:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	var index:=AshwoodData.all_encounter_ids().find(encounter_key)
	start_battle(0,max(0,index),ashwood_party_indices(encounter_key))
	current_ashwood_encounter=encounter_key
	battle_objective=encounter_data.objective.duplicate(true)
	objective_banner_time=5.5
	objective_combat_intro=str(encounter_data.get("combat_intro",""))
	objective_max_health=float(battle_objective.get("max_health",0.0))
	objective_health=clampf(float(battle_objective.get("starting_health",objective_max_health)),0.0,objective_max_health)
	objective_progress=objective_health/objective_max_health if objective_max_health>0 else 0.0
	objective_complete=str(battle_objective.type) in ["elimination","rune_survival","rune_boss","finale"]
	objective_pressure_spawned=false
	objective_actor_pos=Vector2(930,330)
	objective_notice="Rune pattern recognized — move before it reaches the outer ring." if state.zone0.optional_mini_boss_defeated and encounter_key=="finale" else ""
	objective_notice_time=5.5 if objective_notice!="" else 0.0
	ashwood_spawn_count=0
	ashwood_midfight_recruit_index=-1
	rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
	total_waves=encounter_data.waves.size()
	wave_index=0;wave_spawn_remaining=0;wave_break=.8;waiting_wave=false
	queue_redraw()

func show_ashwood_consequence(text_value:String) -> void:
	screen="ashwood_consequence"
	var root=base_screen("THE ASHWOOD MARCHES","CONSEQUENCE")
	root.add_spacer(false)
	var consequence_panel=panel();consequence_panel.custom_minimum_size=Vector2(850,260);consequence_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(consequence_panel)
	consequence_panel.add_child(label(text_value,22,C_TEXT))
	consequence_panel.add_spacer(false)
	var continue_button:=button("Continue to Map",func():show_zone_map(0),230);continue_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;consequence_panel.add_child(continue_button)
	root.add_spacer(false)

func start_tutorial()->void:
	state.selected_team=[0,1];state.active_team=[0,1];save_game();start_battle(0,0)
	tutorial_active=true;tutorial_step=0;tutorial_move_round=0;tutorial_timer=0;tutorial_hero_clicked=false;tutorial_ability_used=false
	tutorial_reject_time=0;tutorial_feedback_message="";tutorial_idle_time=0;tutorial_idle_hint_shown=false;tutorial_input_device="mobile" if OS.has_feature("mobile") else "pc"
	tutorial_targets=[Vector2(390,250)];tutorial_target_reached=[false]
	for h in heroes:h.target=-1;h.heal_target=-1
	queue_redraw()

func set_tutorial_movement_targets(round_index:int)->void:
	var layouts=[[Vector2(430,175),Vector2(430,400)],[Vector2(650,180),Vector2(570,430)],[Vector2(820,265),Vector2(700,470)]]
	tutorial_targets=layouts[clampi(round_index,0,layouts.size()-1)].duplicate();tutorial_target_reached=[false,false]

func tutorial_movement_target_reached(hero_position:Vector2,target_position:Vector2)->bool:
	return hero_position.distance_to(target_position)<=TUTORIAL_MOVEMENT_REACH_RADIUS

func tutorial_prompt()->String:
	var mobile=tutorial_input_device=="mobile"
	match tutorial_step:
		0:return "First, let's practice movement. Touch and drag either hero to the marker." if mobile else "First, let's practice movement. Drag either hero to the marked area."
		1:return "Touch and drag to reach both markers. One hero can visit both." if mobile else "Nice job. Reach both marked areas. One hero can visit both, or split up."
		2:return "Touch and drag Brann onto the training dummy." if mobile else "Now drag Brann to the training dummy. He will attack until it is destroyed."
		3:return "Oh no—Brann is hurt. Tap Brann to check his health." if mobile else "Oh no—Brann is hurt. Click Brann to check his health."
		4:return "Touch and drag Sera onto Brann to order her to heal him." if mobile else "Drag Sera onto Brann and release to order her to heal him."
		5:return "Sera will keep Brann as her healing target until you give different orders."
		6:return "Protect Sera! Touch and drag Brann onto the creature." if mobile else "Protect Sera! Drag Brann onto the creature and defeat it."
		7:return "Both heroes are hurt. Tap Sera, then tap Radiant Mend." if mobile else "Both heroes are hurt. Select Sera, then press Q or click Radiant Mend."
		8:return "Great work. Tap anywhere to continue." if mobile else "Great work. Click or press any key to continue."
	return ""

func tutorial_rejection_message()->String:
	var tap="Tap" if tutorial_input_device=="mobile" else "Click"
	match tutorial_step:
		0,1:return "Move either hero anywhere, then reach the highlighted marker to continue."
		2:return "Only Brann can be assigned to the Training Dummy."
		3:return "%s Brann to inspect his health."%tap
		4:return "Drag Sera directly onto Brann to set her healing target."
		5:return "Watch Sera finish healing Brann."
		6:return "Move Sera freely, or assign Brann to the Raider to continue."
		7:return "Select Sera first." if selected!=1 else "Use Radiant Mend with Q or the highlighted button."
	return "Follow the highlighted action to continue."

func reject_tutorial_action(message:String="")->void:
	if not tutorial_active:return
	tutorial_reject_time=1.15
	tutorial_feedback_message=message if message!="" else tutorial_rejection_message()
	queue_redraw()

func tutorial_record_valid_action()->void:
	tutorial_idle_time=0
	tutorial_idle_hint_shown=false
	tutorial_reject_time=0
	tutorial_feedback_message=""

func spawn_tutorial_dummy()->void:
	spawn_enemy(Vector2(660,330),"Dummy");var tutorial_hp=heroes[0].damage*5.0;enemies[-1].hp=tutorial_hp;enemies[-1].max_hp=tutorial_hp;enemies[-1].damage=0.0;enemies[-1].rewarded=true

func spawn_tutorial_raider()->void:
	spawn_enemy(heroes[1].pos+Vector2(155,0),"Raider");var tutorial_hp=heroes[0].damage*8.0;enemies[-1].hp=tutorial_hp;enemies[-1].max_hp=tutorial_hp;enemies[-1].target=1;enemies[-1].rewarded=true;enemies[-1]["tutorial_opening_target"]=1

func tutorial_has_living_enemy(enemy_type:String)->bool:
	for enemy in enemies:
		if enemy.type==enemy_type and enemy.hp>0:return true
	return false

func tutorial_has_enemy(enemy_type:String)->bool:
	for enemy in enemies:
		if enemy.type==enemy_type:return true
	return false

func enter_tutorial_step(next_step:int)->void:
	tutorial_step=next_step;tutorial_timer=0;tutorial_idle_time=0;tutorial_idle_hint_shown=false;tutorial_reject_time=0;tutorial_feedback_message="";dragging_hero=false
	match tutorial_step:
		1:
			tutorial_move_round=0;set_tutorial_movement_targets(0)
		2:
			tutorial_targets=[];spawn_tutorial_dummy()
		3:
			tutorial_hero_clicked=false;heroes[0].hp=max(1,heroes[0].hp-90);heroes[0].target=-1
		6:
			spawn_tutorial_raider()
		7:
			heroes[0].hp=max(1,heroes[0].hp-55);heroes[1].hp=max(1,heroes[1].hp-45);heroes[0].target=-1;heroes[0].dest=heroes[0].pos;heroes[1].target=-1;heroes[1].heal_target=0;heroes[1].dest=heroes[1].pos
		8:
			state.tutorial_complete=true;state.zone0.heroes_unlocked=true;save_game()
	queue_redraw()

func recover_tutorial_state()->void:
	if heroes.size()<2:
		start_tutorial();reject_tutorial_action("Training restarted so both heroes are available.");return
	var recovered=false
	for hero in heroes:
		if hero.hp<=0:
			hero.hp=max(1.0,hero.max_hp*.6);hero.dest=hero.pos;hero.target=-1;recovered=true
	if tutorial_step==6 and heroes[1].hp<heroes[1].max_hp*.22:
		heroes[1].hp=heroes[1].max_hp*.55;recovered=true
	if tutorial_step==2 and not tutorial_has_enemy("Dummy"):
		spawn_tutorial_dummy();recovered=true
	if tutorial_step==6 and not tutorial_has_enemy("Raider"):
		spawn_tutorial_raider();recovered=true
	if recovered:
		for enemy in enemies:enemy.telegraph=0.0;enemy.cooldown=max(enemy.cooldown,.8)
		reject_tutorial_action("Training restored the current step so you can continue.")

func update_tutorial(delta:float)->void:
	tutorial_reject_time=max(0.0,tutorial_reject_time-delta)
	tutorial_timer+=delta;tutorial_idle_time+=delta
	if tutorial_step==0:
		for h in heroes:
			if tutorial_movement_target_reached(h.pos,tutorial_targets[0]):enter_tutorial_step(1);break
	elif tutorial_step==1:
		for target_index in tutorial_targets.size():
			for h in heroes:
				if tutorial_movement_target_reached(h.pos,tutorial_targets[target_index]):tutorial_target_reached[target_index]=true
		if tutorial_target_reached.all(func(reached):return reached):
			tutorial_move_round+=1
			if tutorial_move_round<3:set_tutorial_movement_targets(tutorial_move_round);tutorial_idle_time=0
			else:enter_tutorial_step(2)
	elif tutorial_step==2 and tutorial_has_enemy("Dummy") and not tutorial_has_living_enemy("Dummy"):enter_tutorial_step(3)
	elif tutorial_step==3 and tutorial_hero_clicked and selected==0:enter_tutorial_step(4)
	elif tutorial_step==4 and heroes.size()>1 and heroes[1].heal_target==0 and heroes[0].hp>=heroes[0].max_hp:enter_tutorial_step(5)
	elif tutorial_step==5 and tutorial_timer>=2.8:enter_tutorial_step(6)
	elif tutorial_step==6 and tutorial_has_enemy("Raider") and not tutorial_has_living_enemy("Raider"):enter_tutorial_step(7)
	elif tutorial_step==7 and tutorial_ability_used:enter_tutorial_step(8)
	var awaiting_input=tutorial_step in [0,1,3,4,7] or tutorial_step==2 and (heroes.is_empty() or heroes[0].target<0) or tutorial_step==6 and (heroes.is_empty() or heroes[0].target<0)
	if awaiting_input and tutorial_idle_time>=10 and not tutorial_idle_hint_shown:
		tutorial_idle_hint_shown=true;reject_tutorial_action()
	queue_redraw()

func begin_next_wave() -> void:
	wave_index+=1
	if current_ashwood_encounter!="":
		current_wave_roles=ashwood_wave_roles(wave_index)
		wave_spawn_remaining=current_wave_roles.size()
		spawn_timer=.2
		return
	wave_spawn_remaining=2+int(encounter_id/2.0)+(1 if dungeon_id>0 else 0); spawn_timer=.2
	if wave_index==total_waves: wave_spawn_remaining+=1

func ashwood_wave_roles(wave_number:int) -> Array:
	var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
	var roles:Array=[]
	if current_ashwood_encounter=="finale" and wave_number==1:
		roles=AshwoodManager.finale_opening_roles(state.zone0)
	elif wave_number>0 and wave_number<=encounter_data.waves.size():
		roles=encounter_data.waves[wave_number-1].duplicate()
	if state.zone0.raiders_chased and current_ashwood_encounter in ["crossing","finale"] and wave_number==2 and roles.size()>1:
		roles.pop_back()
	if current_ashwood_encounter=="caravan" and state.zone0.approach_choice=="investigate" and wave_number==2:
		roles.append("Swift")
	return roles

func spawn_wave_enemy() -> void:
	if current_ashwood_encounter!="":
		var role_index=current_wave_roles.size()-wave_spawn_remaining
		var ashwood_role:String=current_wave_roles[clampi(role_index,0,current_wave_roles.size()-1)]
		var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
		var ashwood_side:int=ashwood_spawn_count%4 if bool(encounter_data.get("spawn_all_sides",false)) else (wave_index+wave_spawn_remaining)%4
		var ashwood_entry=[Vector2(1200,130+(wave_spawn_remaining*97)%390),Vector2(300+(wave_spawn_remaining*151)%800,85),Vector2(80,540-(wave_spawn_remaining*89)%390),Vector2(320+(wave_spawn_remaining*127)%760,555)][ashwood_side]
		spawn_enemy(ashwood_entry,ashwood_role);ashwood_spawn_count+=1;wave_spawn_remaining-=1;spawn_timer=float(encounter_data.get("spawn_interval",.55))
		return
	var is_boss=wave_index==total_waves and wave_spawn_remaining==1
	var role="Boss" if is_boss else GameData.WAVE_ENEMY_ROLES[(wave_index+wave_spawn_remaining+encounter_id)%GameData.WAVE_ENEMY_ROLES.size()]
	var side=(wave_index+wave_spawn_remaining)%4; var entry=[Vector2(1200,120+(wave_spawn_remaining*97)%410),Vector2(260+(wave_spawn_remaining*151)%850,75),Vector2(1200,545-(wave_spawn_remaining*89)%410),Vector2(280+(wave_spawn_remaining*127)%820,565)][side]
	spawn_enemy(entry,role); wave_spawn_remaining-=1; spawn_timer=.65

func spawn_enemy(pos:Vector2,type:String) -> void:
	var enemy:=GameData.create_enemy(type,pos,dungeon_id)
	if current_ashwood_encounter!="":
		var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
		var health_overrides:Dictionary=encounter_data.get("enemy_health_overrides",{})
		if health_overrides.has(type):enemy.hp=float(health_overrides[type]);enemy.max_hp=enemy.hp
		else:
			var health_multiplier:=float(encounter_data.get("enemy_health_multiplier",1.0))
			enemy.hp*=health_multiplier;enemy.max_hp*=health_multiplier
		var objective_type:=str(battle_objective.get("type",""))
		var objective_aggro_chance:=float(battle_objective.get("objective_aggro_chance",1.0 if objective_type=="protect_task" else 0.0))
		if objective_type in ["protect_task","protect_caravan"] and not objective_complete and randf()<objective_aggro_chance:
			enemy.objective_threat=float(battle_objective.get("objective_threat",24.0))
			enemy.target=OBJECTIVE_THREAT_TARGET
			if bool(enemy.get("prefers_backline",false)):
				var backline_target:int=nearest_backline_hero(enemy.pos)
				if backline_target>=0:enemy.threat[backline_target]=30.0
	enemies.append(enemy)

func damage_battle_objective(amount:float,source_position:Vector2) -> void:
	if amount<=0 or not objective_is_threat_target():return
	if str(battle_objective.get("type",""))=="protect_caravan":
		objective_health=max(0.0,objective_health-amount)
		objective_progress=objective_health/max(1.0,objective_max_health)
		add_effect("hit",source_position,objective_actor_pos,"CARAVAN -%d"%int(amount),C_RED)
		if objective_health<=0 and not battle_over:
			set_objective_notice("The caravan has been destroyed!",3.5)
			finish_battle(false)
	else:
		objective_progress=max(0.0,objective_progress-.055)
		add_effect("hit",source_position,objective_actor_pos,"SIGNAL HIT",C_RED)

func update_ashwood_objective(delta:float) -> void:
	if current_ashwood_encounter=="" or battle_objective.is_empty():return
	var objective_type:=str(battle_objective.type)
	if objective_type in ["protect_task","ritual_defense"] and not objective_complete:
		var threatened:=false
		for enemy in enemies:
			if enemy.hp>0 and enemy.pos.distance_to(objective_actor_pos)<100:threatened=true;break
		if threatened:
			objective_progress=max(min(objective_progress,.08),objective_progress-delta*.018)
		else:
			objective_progress=min(1.0,objective_progress+delta/max(1.0,float(battle_objective.duration)))
		if objective_progress>=.75 and not objective_pressure_spawned:
			objective_pressure_spawned=true
			spawn_enemy(Vector2(1180,210),"Brute");spawn_enemy(Vector2(1180,455),"Swift")
			set_objective_notice("The final pressure wave has arrived!",3.0)
		if objective_progress>=1.0:
			objective_complete=true
			if objective_type=="ritual_defense":complete_ashwood_ritual()
			else:
				for enemy in enemies:
					if enemy.hp>0:enemy.hp-=180.0
				add_first_recruit_to_battle()
				set_objective_notice("The signal is complete — the rescued fighter joins the attack!",3.5)
	elif objective_type=="survival" and not objective_complete:
		objective_progress=min(1.0,objective_progress+delta/max(1.0,float(battle_objective.duration)))
		if objective_progress>=1.0:
			objective_complete=true
			for enemy in enemies:enemy.hp=0
			set_objective_notice("The crossing holds. The remaining attackers break and flee.",3.5)
	if objective_type in ["rune_survival","rune_boss","finale","survival"] and (objective_type!="finale" or wave_index>=total_waves):
		update_ashwood_rune(delta)

func update_objective_banner(delta:float) -> void:
	objective_banner_time=max(0.0,objective_banner_time-delta)

func set_objective_notice(text_value:String,duration:float=3.5) -> void:
	objective_notice=text_value
	objective_notice_time=duration

func update_objective_notice(delta:float) -> void:
	if objective_notice_time<=0:return
	objective_notice_time=max(0.0,objective_notice_time-delta)
	if objective_notice_time<=0:objective_notice=""

func update_ashwood_rune(delta:float) -> void:
	if rune_active:
		rune_charge+=delta
		var warning_time:=3.1 if state.zone0.optional_mini_boss_defeated else 2.35
		rune_radius=lerp(24.0,118.0,clamp(rune_charge/warning_time,0.0,1.0))
		if rune_charge>=warning_time:
			for hero in heroes:
				if hero.hp>0 and hero.pos.distance_to(rune_center)<118:
					var damage=58.0 if current_ashwood_encounter=="finale" else 46.0
					hero.hp-=damage;hero.last_hit=3;add_effect("hit",rune_center,hero.pos,"RUNE",C_RED)
			rune_active=false;rune_timer=0;rune_charge=0;rune_radius=0
		return
	rune_timer+=delta
	if rune_timer>=6.2 and not heroes.is_empty():
		rune_active=true;rune_charge=0;rune_center=heroes[(wave_index+selected)%heroes.size()].pos

func ashwood_combat_complete() -> bool:
	if current_ashwood_encounter=="":return wave_index==total_waves and wave_spawn_remaining==0 and enemies.size()>0 and enemies.all(func(enemy):return enemy.hp<=0)
	var all_waves_done=wave_index==total_waves and wave_spawn_remaining==0
	var all_enemies_down=not enemies.is_empty() and enemies.all(func(enemy):return enemy.hp<=0)
	if str(battle_objective.get("type",""))=="protect_caravan":return all_waves_done and all_enemies_down and objective_health>0
	return all_waves_done and all_enemies_down and objective_complete

func _process(delta:float) -> void:
	if toast_time>0: toast_time-=delta; queue_redraw()
	update_objective_notice(delta)
	if victory_sequence: update_victory(delta); return
	if screen!="combat" or battle_over or paused: return
	if tutorial_active:
		update_tutorial(delta)
		if tutorial_step==8:return
		recover_tutorial_state()
	battle_time+=delta
	spawn_timer=max(0,spawn_timer-delta); wave_break=max(0,wave_break-delta)
	if not tutorial_active and wave_index==0 and wave_break<=0: begin_next_wave()
	if not tutorial_active and wave_spawn_remaining>0 and spawn_timer<=0: spawn_wave_enemy()
	if not tutorial_active and wave_spawn_remaining==0 and wave_index<total_waves and enemies.size()>0 and enemies.all(func(foe):return foe.hp<=0):
		if not waiting_wave: waiting_wave=true; wave_break=2.2
		elif wave_break<=0: waiting_wave=false; begin_next_wave()
	if not tutorial_active and current_ashwood_encounter!="":update_ashwood_objective(delta)
	if current_ashwood_encounter!="":update_objective_banner(delta)
	for fx in effects: fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)
	for i in heroes.size():
		var h=heroes[i]; if h.hp<=0: continue
		h.cooldown=max(0,h.cooldown-delta); h.shield=max(0,h.shield-delta)
		h.last_hit=max(0,h.last_hit-delta)
		for slot in 5: h.ability_cds[slot]=max(0,h.ability_cds[slot]-delta)
		var hero_speed=135.0 if h["class"]=="Guardian" else 145.0 if h["class"]=="Cleric" else 150.0
		var d=h.pos.distance_to(h.dest); if d>4:h.facing_direction=h.pos.direction_to(h.dest);h.pos=h.pos.move_toward(h.dest,hero_speed*delta)
		var healed=false
		if h["class"]=="Cleric":
			# Pause basic tutorial healing so Radiant Mend performs the requested heal.
			var low=-1 if tutorial_active and tutorial_step==7 else h.heal_target if h.heal_target>=0 and h.heal_target<heroes.size() and heroes[h.heal_target].hp>0 else -1
			if low<0 and not tutorial_active:
				var wounded=nearest_wounded_hero(h.pos)
				if wounded>=0 and heroes[wounded].hp<heroes[wounded].max_hp:low=wounded;h.heal_target=wounded
			if low>=0:
				healed=true
				if heroes[low].hp<heroes[low].max_hp and h.cooldown<=0:
					var heal_amount=16.0 if heroes[low]["class"]=="Guardian" else 14.0
					var effective_healing:float=min(heal_amount,heroes[low].max_hp-heroes[low].hp)
					heroes[low].hp+=effective_healing;add_healing_threat(i,effective_healing);add_effect("heal",h.pos,heroes[low].pos,"+%d"%int(effective_healing),C_GREEN);h.cooldown=1.7
		if not healed:
			if h.target>=0 and (h.target>=enemies.size() or enemies[h.target].hp<=0):h.target=-1
			if h.target<0 and h["class"]!="Cleric" and not tutorial_active:h.target=nearest_living_enemy(h.pos,INF if bool(h.get("independent",false)) else 82.0)
			if h.target>=0 and h.target<enemies.size() and enemies[h.target].hp>0:
				var target_enemy=enemies[h.target];var attack_distance=h.pos.distance_to(target_enemy.pos)
				if attack_distance>h.range*.88 and d<=4:h.facing_direction=h.pos.direction_to(target_enemy.pos);h.pos=h.pos.move_toward(target_enemy.pos,hero_speed*.78*delta);h.dest=h.pos
				elif attack_distance<=h.range and h.cooldown<=0:
					h.facing_direction=h.pos.direction_to(target_enemy.pos)
					var damage_dealt:float=min(h.damage,max(0.0,float(target_enemy.hp)))
					target_enemy.hp-=h.damage;add_damage_threat(target_enemy,i,damage_dealt)
					target_enemy.revealed=true; add_effect("projectile" if h.range>100 else "slash",h.pos,target_enemy.pos,"-%d"%int(h.damage),CLASSES[h["class"]].color);h.cooldown=1.25 if h["class"]=="Guardian" else 1.4 if h["class"]=="Cleric" else 1.1
	if not heroes.is_empty() and heroes.all(func(hero):return hero.hp<=0):finish_battle(false);return
	for enemy_index in enemies.size():
		var e=enemies[enemy_index]
		if e.hp<=0:
			if not e.rewarded:
				e.rewarded=true
				if current_ashwood_encounter=="":
					var kill_gold=12 if bool(e.get("boss",false)) else 5 if e.type=="Brute" else 2;state.gold+=kill_gold;battle_gold_earned+=kill_gold;add_effect("cast",e.pos,e.pos,"● +%d"%kill_gold,C_GOLD);save_game()
				elif str(e.type).begins_with("Controlled "):
					add_effect("cast",e.pos,e.pos,"SUBDUED",C_GREEN)
			continue
		if e.type=="Dummy":continue
		e.cooldown=max(0,e.cooldown-delta);e.taunt_time=max(0.0,float(e.get("taunt_time",0.0))-delta)
		if e.type=="Shaman" and e.cooldown<=0:
			var wounded=-1; var lowest=1.0
			for ally_i in enemies.size():
				if enemies[ally_i].hp>0 and enemies[ally_i].hp/enemies[ally_i].max_hp<lowest: lowest=enemies[ally_i].hp/enemies[ally_i].max_hp; wounded=ally_i
			if wounded>=0 and lowest<.8: enemies[wounded].hp=min(enemies[wounded].max_hp,enemies[wounded].hp+30); add_effect("heal",e.pos,enemies[wounded].pos,"+30",C_GREEN); e.cooldown=3.2; continue
		var ti=preferred_enemy_target(e)
		if tutorial_active and tutorial_step==6 and e.has("tutorial_opening_target"):
			var opening_target=int(e.tutorial_opening_target)
			if opening_target<heroes.size() and heroes[opening_target].hp>0 and (heroes.is_empty() or heroes[0].target!=enemy_index):ti=opening_target
			else:e.erase("tutorial_opening_target")
		if ti<0 and ti!=OBJECTIVE_THREAT_TARGET: finish_battle(false); return
		var targets_objective:bool=ti==OBJECTIVE_THREAT_TARGET
		var target_pos:Vector2=objective_actor_pos if targets_objective else heroes[ti].pos
		e.target=ti; var dist=e.pos.distance_to(target_pos)
		if bool(e.get("boss",false)) and not e.summoned and e.hp<e.max_hp*.55: e.summoned=true; spawn_enemy(e.pos+Vector2(-70,-60),"Swift"); spawn_enemy(e.pos+Vector2(-70,60),"Raider"); add_effect("cast",e.pos,e.pos,"PHASE TWO",C_RED)
		if bool(e.get("boss",false)) and e.hp<e.max_hp*.25: e.enraged=true
		if bool(e.get("boss",false)) and e.cooldown<=0 and e.telegraph<=0:
			e.special=["cleave","charge","danger"][e.special_index%3]; e.special_index+=1; e.telegraph=1.5; e.danger_pos=target_pos
		if e.telegraph>0:
			e.telegraph-=delta
			if e.telegraph<=0:
				if e.special=="basic":
					if targets_objective and objective_is_threat_target():
						damage_battle_objective(float(e.damage),e.pos)
					elif ti<heroes.size() and heroes[ti].hp>0:
						var basic_dealt=e.damage if heroes[ti].shield<=0 else e.damage*.35;heroes[ti].hp-=basic_dealt;heroes[ti].last_hit=3.0;add_effect("projectile" if e.type=="Archer" else "hit",e.pos,heroes[ti].pos,"-%d"%int(basic_dealt),C_RED)
						if heroes[ti]["class"]!="Cleric" and heroes[ti].target<0:heroes[ti].target=enemy_index;heroes[ti].heal_target=-1
				elif e.special=="charge": e.pos=e.pos.move_toward(e.danger_pos,220); for hero_charge in heroes: if hero_charge.hp>0 and hero_charge.pos.distance_to(e.pos)<65: hero_charge.hp-=e.damage*1.25; add_effect("hit",e.pos,hero_charge.pos,"CHARGE",C_RED)
				else:
					var impact=e.danger_pos if e.special=="danger" else e.pos; var radius=78.0 if e.special=="danger" else 115.0
					for struck_hero in heroes:
						if struck_hero.hp>0 and struck_hero.pos.distance_to(impact)<radius: var dealt=e.damage*1.4 if struck_hero.shield<=0 else e.damage*.45; struck_hero.hp-=dealt; add_effect("hit",impact,struck_hero.pos,"-%d"%int(dealt),C_RED)
				e.cooldown=(1.55 if not bool(e.get("boss",false)) else 2.7 if e.enraged else 4.0)
		elif dist>(185 if e.type=="Archer" or e.type=="Shaman" or bool(e.get("ranged",false)) else 44):
			var enemy_speed=160.0 if e.type=="Swift" else 75.0 if bool(e.get("boss",false)) or e.type=="Brute" else 110.0;e.facing_direction=e.pos.direction_to(target_pos);e.pos=e.pos.move_toward(target_pos,enemy_speed*delta)
		elif e.cooldown<=0:
			e.facing_direction=e.pos.direction_to(target_pos)
			e.special="basic"; e.telegraph=.48; e.danger_pos=target_pos
	if ashwood_combat_complete():finish_battle(true)
	queue_redraw()

func lowest_hero()->int:
	var idx=-1; var ratio=2.0
	for i in heroes.size(): if heroes[i].hp>0 and heroes[i].hp/heroes[i].max_hp<ratio: ratio=heroes[i].hp/heroes[i].max_hp; idx=i
	return idx

func nearest_wounded_hero(pos:Vector2)->int:
	var idx=-1;var distance=99999.0
	for i in heroes.size():
		if heroes[i].hp>0 and heroes[i].hp<heroes[i].max_hp:
			var ally_distance=pos.distance_to(heroes[i].pos)
			if ally_distance<distance:distance=ally_distance;idx=i
	return idx
func nearest_living_hero(pos:Vector2)->int:
	var idx=-1; var dist=99999.0
	for i in heroes.size():
		if heroes[i].hp>0:
			var d=pos.distance_to(heroes[i].pos)*(0.55 if heroes[i]["class"]=="Guardian" else 1.0); if d<dist:dist=d;idx=i
	return idx

func nearest_living_enemy(pos:Vector2,max_distance:float=INF)->int:
	var idx=-1;var distance=99999.0
	for i in enemies.size():
		if enemies[i].hp>0:
			var enemy_distance=pos.distance_to(enemies[i].pos)
			if enemy_distance<=max_distance and enemy_distance<distance:distance=enemy_distance;idx=i
	return idx

func nearest_backline_hero(pos:Vector2) -> int:
	var best:int=-1
	var distance:float=INF
	for hero_index in heroes.size():
		if heroes[hero_index].hp<=0 or heroes[hero_index]["class"]=="Guardian":continue
		var candidate_distance:float=pos.distance_to(heroes[hero_index].pos)
		if candidate_distance<distance:distance=candidate_distance;best=hero_index
	return best

func objective_is_threat_target() -> bool:
	if current_ashwood_encounter=="":return false
	var objective_type:=str(battle_objective.get("type",""))
	return objective_type=="protect_caravan" and objective_health>0 or objective_type=="protect_task" and not objective_complete

func add_enemy_threat(enemy:Dictionary,hero_index:int,amount:float) -> void:
	if amount<=0 or hero_index<0 or hero_index>=heroes.size() or bool(enemy.get("ignores_tank_aggro",false)):return
	var threat_table:Dictionary=enemy.get("threat",{})
	threat_table[hero_index]=float(threat_table.get(hero_index,0.0))+amount
	enemy.threat=threat_table

func add_damage_threat(enemy:Dictionary,hero_index:int,damage_dealt:float) -> void:
	if damage_dealt<=0:return
	var role_multiplier:float=GUARDIAN_THREAT_MULTIPLIER if heroes[hero_index]["class"]=="Guardian" else 1.0
	add_enemy_threat(enemy,hero_index,damage_dealt*DAMAGE_THREAT_RATIO*role_multiplier)

func add_healing_threat(healer_index:int,effective_healing:float) -> void:
	if effective_healing<=0:return
	for enemy in enemies:
		if enemy.hp>0:add_enemy_threat(enemy,healer_index,effective_healing*HEALING_THREAT_RATIO)

func enemy_target_threat(enemy:Dictionary,target_index:int) -> float:
	if target_index==OBJECTIVE_THREAT_TARGET:return float(enemy.get("objective_threat",0.0)) if objective_is_threat_target() else -1.0
	if target_index<0 or target_index>=heroes.size() or heroes[target_index].hp<=0:return -1.0
	return float(enemy.get("threat",{}).get(target_index,0.0))

func taunt_enemy(enemy:Dictionary,hero_index:int) -> void:
	if bool(enemy.get("ignores_tank_aggro",false)):return
	var highest_threat:float=float(enemy.get("objective_threat",0.0))
	for threat_value in enemy.get("threat",{}).values():highest_threat=max(highest_threat,float(threat_value))
	var threat_table:Dictionary=enemy.get("threat",{})
	threat_table[hero_index]=max(float(threat_table.get(hero_index,0.0)),highest_threat+1.0)
	enemy.threat=threat_table;enemy.taunt_target=hero_index;enemy.taunt_time=CHALLENGE_TAUNT_DURATION;enemy.target=hero_index

func preferred_enemy_target(enemy:Dictionary)->int:
	if bool(enemy.get("ignores_tank_aggro",false)):
		var fixate_target:int=nearest_backline_hero(enemy.pos)
		return fixate_target if fixate_target>=0 else nearest_living_hero(enemy.pos)
	var taunt_target:int=int(enemy.get("taunt_target",-1))
	if float(enemy.get("taunt_time",0.0))>0 and taunt_target>=0 and taunt_target<heroes.size() and heroes[taunt_target].hp>0:return taunt_target
	if not objective_is_threat_target() and enemy.get("threat",{}).is_empty() and bool(enemy.get("prefers_backline",false)):
		var opening_backline_target:int=nearest_backline_hero(enemy.pos)
		if opening_backline_target>=0:return opening_backline_target
	var best_target:int=OBJECTIVE_THREAT_TARGET if objective_is_threat_target() and float(enemy.get("objective_threat",0.0))>0 else -1
	var best_threat:float=enemy_target_threat(enemy,best_target)
	for hero_index in heroes.size():
		var hero_threat:float=enemy_target_threat(enemy,hero_index)
		if hero_threat>best_threat:best_threat=hero_threat;best_target=hero_index
	if best_target>=0 or best_target==OBJECTIVE_THREAT_TARGET:
		var current_target:int=int(enemy.get("target",-1))
		var current_threat:float=enemy_target_threat(enemy,current_target)
		if current_threat>0 and current_target!=best_target and best_threat<current_threat*THREAT_PULL_MULTIPLIER:return current_target
		return best_target
	if bool(enemy.get("prefers_backline",false)) or enemy.type=="Boss" and enemy.special_index%3==1:
		var backline_target:int=nearest_backline_hero(enemy.pos)
		if backline_target>=0:return backline_target
	return nearest_living_hero(enemy.pos)

func player_controlled_hero_indices() -> Array:
	var result:=[]
	for hero_index in heroes.size():
		if not bool(heroes[hero_index].get("independent",false)):result.append(hero_index)
	return result

func cycle_selected_hero(direction:int)->void:
	if heroes.is_empty():return
	for offset in heroes.size():
		var candidate=posmod(selected+direction*(offset+1),heroes.size())
		if heroes[candidate].hp>0 and not bool(heroes[candidate].get("independent",false)):
			selected=candidate
			queue_redraw()
			return

func cycle_selected_enemy()->void:
	if heroes.is_empty():return
	var living_targets:=[]
	for i in enemies.size():
		if enemies[i].hp>0:living_targets.append(i)
	if living_targets.is_empty():
		focused_enemy_index=-1
		queue_redraw()
		return
	var current_position=living_targets.find(focused_enemy_index)
	var next_position=0 if current_position<0 else (current_position+1)%living_targets.size()
	focused_enemy_index=living_targets[next_position]
	queue_redraw()

func combat_enemy_target() -> int:
	if focused_enemy_index>=0 and focused_enemy_index<enemies.size() and enemies[focused_enemy_index].hp>0:return focused_enemy_index
	if selected>=0 and selected<heroes.size():
		var assigned_target:=int(heroes[selected].target)
		if assigned_target>=0 and assigned_target<enemies.size() and enemies[assigned_target].hp>0:return assigned_target
	return -1

func cancel_ability_aim()->void:
	ability_aiming=false;aimed_ability_slot=-1;aimed_ability_category="";aimed_cast_mode="";ability_button_held=false;queue_redraw()

func clear_selected_combat_target()->void:
	if selected<0 or selected>=heroes.size():return
	heroes[selected].target=-1
	heroes[selected].heal_target=-1
	focused_enemy_index=-1
	queue_redraw()

func begin_ability(slot:int,device:String="pc")->void:
	if selected>=heroes.size() or bool(heroes[selected].get("independent",false)) or slot<0 or slot>=4:return
	if tutorial_active and (tutorial_step<7 or slot!=0):return
	if tutorial_active and tutorial_step==7 and heroes[selected]["class"]!="Cleric":return
	if tutorial_active and tutorial_step==7:use_ability(0,heroes[selected].pos);return
	if state.heroes[battle_hero_indices[selected]].level<=1 and slot>0:flash("This ability has not been unlocked yet.");return
	var category=ABILITY_TARGETING[heroes[selected]["class"]][slot]
	var mode="instant" if category=="self" else str(state.casting_settings[device].get(category,"cursor"))
	if mode=="instant" or mode=="cursor" or mode=="facing" or mode=="target":
		if (category=="enemy" and combat_enemy_target()<0) or (category=="ally" and (heroes[selected].heal_target<0 or heroes[selected].heal_target>=heroes.size())):
			flash("Choose a valid %s target first."%category);return
		var cast_point=get_global_mouse_position()
		if mode=="facing":cast_point=heroes[selected].pos+heroes[selected].facing_direction*ABILITY_RANGES[heroes[selected]["class"]][slot]
		use_ability(slot,cast_point);return
	ability_aiming=true;aimed_ability_slot=slot;aimed_ability_category=category;aimed_cast_mode=mode;aimed_from_touch=device=="mobile";ability_button_held=mode=="release";ability_aim_point=get_global_mouse_position();queue_redraw()

func confirm_aim_at(point:Vector2)->bool:
	if not ability_aiming:return false
	if aimed_ability_category=="enemy":
		for i in enemies.size():
			if enemies[i].hp>0 and enemies[i].pos.distance_to(point)<58:focused_enemy_index=i;var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	if aimed_ability_category=="ally":
		for i in heroes.size():
			if heroes[i].hp>0 and heroes[i].pos.distance_to(point)<58:heroes[selected].heal_target=i;heroes[selected].target=-1;var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true
		return false
	var slot=aimed_ability_slot;cancel_ability_aim();use_ability(slot,point);return true

func tutorial_allows_hero(hero_index:int)->bool:
	match tutorial_step:
		0,1:return hero_index>=0 and hero_index<heroes.size()
		2,3:return hero_index==0
		6:return hero_index==0 or hero_index==1
		4,7:return hero_index==1
	return false

func tutorial_pointer_press(point:Vector2,device:String="pc")->void:
	tutorial_input_device=device
	if tutorial_step==7:
		if point.y>575 and point.y<635 and point.x>420 and point.x<875:
			var portrait_index=clampi(int((point.x-424)/54),0,heroes.size()-1)
			if portrait_index==1:selected=1;tutorial_record_valid_action();queue_redraw()
			else:reject_tutorial_action("Only Sera can be selected for this step.")
			return
		if point.y>635 and point.x>445 and point.x<523:
			if selected==1:tutorial_record_valid_action();begin_ability(0,device)
			else:reject_tutorial_action("Select Sera before using Radiant Mend.")
			return
	for hero_index in heroes.size():
		if heroes[hero_index].pos.distance_to(point)<58 and tutorial_allows_hero(hero_index):
			selected=hero_index;tutorial_record_valid_action()
			if tutorial_step==3:
				tutorial_hero_clicked=true
				dragging_hero=false
				queue_redraw()
				return
			if tutorial_step==7:
				queue_redraw()
				return
			dragging_hero=true;drag_cursor=point;drag_start=point;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
	reject_tutorial_action()

func update_hero_drag(point:Vector2)->void:
	drag_cursor=point
	if drag_cursor.distance_to(drag_start)>12:drag_has_moved=true
	drag_target_type="ground";drag_target_index=-1
	if heroes[selected]["class"]=="Cleric":
		for hero_index in heroes.size():
			if heroes[hero_index].hp>0 and heroes[hero_index].pos.distance_to(drag_cursor)<42:drag_target_type="ally";drag_target_index=hero_index;break
	if drag_target_type=="ground":
		for enemy_index in enemies.size():
			if enemies[enemy_index].hp>0 and enemies[enemy_index].pos.distance_to(drag_cursor)<45:drag_target_type="enemy";drag_target_index=enemy_index;break
	queue_redraw()

func tutorial_drag_release_is_valid()->bool:
	match tutorial_step:
		0:
			return drag_target_type=="ground"
		1:
			return drag_target_type=="ground"
		2:
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Dummy"
		4:
			return drag_target_type=="ally" and drag_target_index==0
		6:
			if selected==1:return drag_target_type=="ground"
			return drag_target_type=="enemy" and drag_target_index>=0 and enemies[drag_target_index].type=="Raider"
	return false

func finish_hero_drag()->void:
	dragging_hero=false
	if not drag_has_moved:return
	if tutorial_active and not tutorial_drag_release_is_valid():reject_tutorial_action();queue_redraw();return
	if tutorial_active:tutorial_record_valid_action()
	if drag_target_type=="enemy":heroes[selected].target=drag_target_index;heroes[selected].heal_target=-1
	elif drag_target_type=="ally" and heroes[selected]["class"]=="Cleric":heroes[selected].heal_target=drag_target_index;heroes[selected].target=-1
	else:heroes[selected].dest=Vector2(clamp(drag_cursor.x,55.0,1225.0),clamp(drag_cursor.y,70.0,570.0));heroes[selected].target=-1
	queue_redraw()

func _unhandled_input(event:InputEvent) -> void:
	if screen!="combat":return
	if tutorial_active:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:tutorial_input_device="mobile"
		elif not OS.has_feature("mobile") and (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey):tutorial_input_device="pc"
	if tutorial_active and tutorial_step==8 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
		tutorial_active=false;show_hall();return
	if victory_sequence:
		if victory_phase>=5 and ((event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.pressed):
			if current_ashwood_encounter!="" and victory_timer<1.6:victory_timer=1.6;queue_redraw();return
			victory_sequence=false
			if current_ashwood_encounter!="":show_ashwood_victory()
			else:show_zone_map(dungeon_id)
		return
	if battle_over:
		if event is InputEventKey and event.pressed:
			if event.keycode==KEY_ESCAPE or event.keycode==KEY_ENTER: show_hall()
			elif event.keycode==KEY_R: start_battle(dungeon_id,encounter_id)
		return
	if tutorial_active and event is InputEventKey:
		var accepted=false
		if event.pressed and tutorial_step==7:
			if event.keycode==KEY_2:selected=1;tutorial_record_valid_action();queue_redraw();accepted=true
			elif not event.echo and event.keycode==KEY_Q and selected==1:tutorial_record_valid_action();begin_ability(0);accepted=true
		if event.pressed and not accepted:reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if tutorial_active and event is InputEventMouseButton and event.pressed and event.button_index!=MOUSE_BUTTON_LEFT:
		reject_tutorial_action()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE and ability_aiming:cancel_ability_aim();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_SPACE:paused=!paused;queue_redraw()
		if event.keycode==KEY_TAB and not event.echo:
			cycle_selected_enemy()
			get_viewport().set_input_as_handled()
		if event.keycode>=KEY_1 and event.keycode<=KEY_4:
			var selectable_heroes:Array=player_controlled_hero_indices()
			var requested_slot:int=event.keycode-KEY_1
			if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
		if not event.echo and event.keycode==KEY_Q:begin_ability(0)
		if not event.echo and event.keycode==KEY_W:begin_ability(1)
		if not event.echo and event.keycode==KEY_E:begin_ability(2)
		if not event.echo and event.keycode==KEY_R:begin_ability(3)
	if event is InputEventKey and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		var released_slot={KEY_Q:0,KEY_W:1,KEY_E:2,KEY_R:3}.get(event.keycode,-1)
		if released_slot==aimed_ability_slot:confirm_aim_at(get_global_mouse_position());return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			if ability_aiming:cancel_ability_aim()
			elif not paused:clear_selected_combat_target()
			get_viewport().set_input_as_handled();return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			cycle_selected_hero(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			cycle_selected_hero(1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var p=event.position
		if tutorial_active:
			tutorial_pointer_press(p,"pc")
			get_viewport().set_input_as_handled()
			return
		if ability_aiming and aimed_cast_mode=="confirm":
			if confirm_aim_at(p):get_viewport().set_input_as_handled()
			return
		if p.x>1190 and p.y<70: paused=true; queue_redraw(); return
		if paused:
			if Rect2(490,285,300,58).has_point(p):paused=false;queue_redraw()
			elif Rect2(490,360,300,58).has_point(p):paused=false;show_zone_map(dungeon_id)
			return
		if p.y>575 and p.y<635 and p.x>420 and p.x<875:
			var selectable_heroes:Array=player_controlled_hero_indices()
			var requested_slot:int=clampi(int((p.x-424)/54),0,7)
			if requested_slot<selectable_heroes.size():selected=selectable_heroes[requested_slot];queue_redraw()
			return
		if p.y>635 and p.x>445 and p.x<835:begin_ability(clampi(int((p.x-445)/78),0,4));return
		for i in heroes.size():
			if not bool(heroes[i].get("independent",false)) and heroes[i].pos.distance_to(p)<58:
				selected=i;if tutorial_active and tutorial_step==3:tutorial_hero_clicked=true
				dragging_hero=true;drag_cursor=p;drag_start=p;drag_has_moved=false;drag_target_type="ground";drag_target_index=-1;queue_redraw();return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and ability_aiming and aimed_cast_mode=="release":
		confirm_aim_at(event.position);return
	if event is InputEventMouseMotion and ability_aiming:ability_aim_point=event.position;queue_redraw()
	if event is InputEventScreenDrag and ability_aiming:ability_aim_point=event.position;queue_redraw();return
	if event is InputEventScreenTouch:
		if tutorial_active:
			if event.pressed:tutorial_pointer_press(event.position,"mobile")
			elif dragging_hero:update_hero_drag(event.position);finish_hero_drag()
			get_viewport().set_input_as_handled()
			return
		if event.pressed and ability_aiming and aimed_cast_mode=="confirm":confirm_aim_at(event.position);return
		if event.pressed and event.position.y>635 and event.position.x>445 and event.position.x<835:begin_ability(clampi(int((event.position.x-445)/78),0,4),"mobile");return
		if not event.pressed and ability_aiming and aimed_cast_mode=="release":confirm_aim_at(event.position);return
		if event.pressed and not paused and event.position.y<635:clear_selected_combat_target()
	if event is InputEventScreenDrag and tutorial_active and dragging_hero:update_hero_drag(event.position);return
	if event is InputEventMouseMotion and dragging_hero:update_hero_drag(event.position)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and dragging_hero:
		finish_hero_drag()

func clamped_cast_point(hero:Dictionary,point:Vector2,range_limit:float)->Vector2:
	if range_limit<=0:return hero.pos
	var offset=point-hero.pos
	if offset.length()<=range_limit:return point.clamp(Vector2(55,70),Vector2(1225,620))
	return (hero.pos+offset.normalized()*range_limit).clamp(Vector2(55,70),Vector2(1225,620))

func use_ability(slot:int,cast_position:Vector2=Vector2.INF) -> void:
	if selected>=heroes.size():return
	var h=heroes[selected]
	var ability_enemy_target:int=combat_enemy_target()
	if slot>=4:return
	if h.hp<=0 or h.ability_cds[slot]>0:return
	var enemy_hp_before:Array[float]=[]
	for enemy in enemies:enemy_hp_before.append(max(0.0,float(enemy.hp)))
	var hero_hp_before:Array[float]=[]
	for hero in heroes:hero_hp_before.append(float(hero.hp))
	if tutorial_active and tutorial_step==7 and h["class"]=="Cleric" and slot==0:tutorial_ability_used=true
	if cast_position==Vector2.INF:cast_position=get_global_mouse_position()
	var ability_range=float(ABILITY_RANGES[h["class"]][slot])
	var resolved_point=clamped_cast_point(h,cast_position,ability_range) if ability_range>0 else h.pos
	if resolved_point.distance_to(h.pos)>1:h.facing_direction=h.pos.direction_to(resolved_point)
	h.ability_cds[slot]=[4.0,7.0,8.0,18.0][slot]
	add_effect("heroic" if slot==3 else "cast",h.pos,h.pos,ABILITIES[h["class"]][slot],CLASSES[h["class"]].color)
	match h["class"]:
		"Guardian":
			if slot==0:
				h.shield=4.0
				for shield_enemy in enemies:if shield_enemy.hp>0:add_enemy_threat(shield_enemy,selected,30.0)
			elif slot==1:
				for foe_challenge in enemies:
					if foe_challenge.hp>0:taunt_enemy(foe_challenge,selected);foe_challenge.pos=foe_challenge.pos.move_toward(h.pos,45)
			elif slot==2:
				h.pos=resolved_point;h.dest=h.pos
				for foe_rush in enemies:if foe_rush.hp>0 and foe_rush.pos.distance_to(h.pos)<105:foe_rush.hp-=38
			else:for ally_bastion in heroes:if ally_bastion.hp>0:ally_bastion.shield=5.0
		"Cleric":
			if slot==0:
				var low=h.heal_target if h.heal_target>=0 and h.heal_target<heroes.size() else lowest_hero();if low>=0:heroes[low].hp=min(heroes[low].max_hp,heroes[low].hp+72)
			elif slot==1:for ally_sanctuary in heroes:if ally_sanctuary.hp>0:ally_sanctuary.hp=min(ally_sanctuary.max_hp,ally_sanctuary.hp+38)
			elif slot==2:
				for ally_purify in heroes:if ally_purify.hp>0:ally_purify.hp=min(ally_purify.max_hp,ally_purify.hp+24)
				for foe_purify in enemies:if foe_purify.hp>0 and foe_purify.pos.distance_to(h.pos)<180:foe_purify.hp-=30
			else:for ally_renewal in heroes:if ally_renewal.hp>0:ally_renewal.hp=min(ally_renewal.max_hp,ally_renewal.hp+110)
		"Ranger":
			if slot==0 and ability_enemy_target>=0:enemies[ability_enemy_target].hp-=65
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_volley in enemies:if foe_volley.hp>0 and foe_volley.pos.distance_to(resolved_point)<140:foe_volley.hp-=42
			else:for foe_arrowstorm in enemies:if foe_arrowstorm.hp>0 and foe_arrowstorm.pos.distance_to(resolved_point)<180:foe_arrowstorm.hp-=72
		"Mage":
			if slot==0 and ability_enemy_target>=0:enemies[ability_enemy_target].hp-=78
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_burst in enemies:if foe_burst.hp>0 and foe_burst.pos.distance_to(h.pos)<240:foe_burst.hp-=55
			else:for foe_starfall in enemies:if foe_starfall.hp>0 and foe_starfall.pos.distance_to(resolved_point)<190:foe_starfall.hp-=85
		"Rogue":
			if slot==0 and ability_enemy_target>=0:enemies[ability_enemy_target].hp-=72
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_knives in enemies:if foe_knives.hp>0 and foe_knives.pos.distance_to(h.pos)<120:foe_knives.hp-=46
			elif ability_enemy_target>=0:enemies[ability_enemy_target].hp-=105
		"Warlock":
			if slot==0 and ability_enemy_target>=0:enemies[ability_enemy_target].hp-=74
			elif slot==1:h.pos=resolved_point;h.dest=h.pos
			elif slot==2:for foe_wither in enemies:if foe_wither.hp>0 and foe_wither.pos.distance_to(resolved_point)<150:foe_wither.hp-=48
			else:for foe_soul in enemies:if foe_soul.hp>0 and foe_soul.pos.distance_to(h.pos)<260:foe_soul.hp-=78
	for enemy_index in mini(enemies.size(),enemy_hp_before.size()):
		var ability_damage:float=max(0.0,enemy_hp_before[enemy_index]-max(0.0,float(enemies[enemy_index].hp)))
		add_damage_threat(enemies[enemy_index],selected,ability_damage)
	var total_effective_healing:float=0.0
	for hero_index in mini(heroes.size(),hero_hp_before.size()):total_effective_healing+=max(0.0,float(heroes[hero_index].hp)-hero_hp_before[hero_index])
	add_healing_threat(selected,total_effective_healing)

func add_ashwood_recruit(choice_key:String) -> void:
	if not AshwoodData.RECRUITS.has(choice_key):return
	var recruit:Dictionary=AshwoodData.RECRUITS[choice_key]
	for existing in state.heroes:
		if existing.name==recruit.name:return
	var hero={"name":recruit.name,"class":recruit["class"],"level":1,"xp":0,"gear":10,"equipment":[],"member_type":"guild_recruit","is_special_hero":false,"legacy_rank":0,"signature_ability":recruit.signature}
	state.heroes.append(hero)
	var hero_index=state.heroes.size()-1
	if state.selected_team.size()<4:state.selected_team.append(hero_index)
	if state.active_team.size()<4:state.active_team.append(hero_index)

func add_recruit_to_battle(choice_key:String,expected_encounter:String) -> void:
	if current_ashwood_encounter!=expected_encounter:return
	if not AshwoodData.RECRUITS.has(choice_key):return
	var recruit:Dictionary=AshwoodData.RECRUITS[choice_key]
	var recruit_existed:bool=state.heroes.any(func(hero):return hero.name==recruit.name)
	add_ashwood_recruit(choice_key)
	var hero_index:=-1
	for candidate_index in state.heroes.size():
		if state.heroes[candidate_index].name==recruit.name:
			hero_index=candidate_index
			break
	if hero_index<0 or hero_index in battle_hero_indices:return
	if not recruit_existed:ashwood_midfight_recruit_index=hero_index
	var data:Dictionary=state.heroes[hero_index]
	var class_data:Dictionary=CLASSES[data["class"]]
	var auto_damage:float=class_data.damage+(data.level-1)*1.2+(data.gear-10)*.35
	battle_hero_indices.append(hero_index)
	var combat_hp:float=class_data.hp+(data.level-1)*15
	heroes.append({"name":data.name,"class":data["class"],"combat_affiliation":"allied_npc","independent":true,"pos":objective_actor_pos,"dest":objective_actor_pos-Vector2(85,0),"facing_direction":Vector2.LEFT,"hp":combat_hp,"max_hp":combat_hp,"damage":auto_damage,"range":class_data.range,"target":nearest_living_enemy(objective_actor_pos),"heal_target":-1,"cooldown":0.0,"ability_cds":[0.0,0.0,0.0,0.0,0.0],"shield":0.0,"last_hit":0.0})
	add_effect("heroic",objective_actor_pos,objective_actor_pos,str(recruit.name).to_upper()+" JOINS",CLASSES[recruit["class"]].color)
	queue_redraw()

func add_first_recruit_to_battle() -> void:
	add_recruit_to_battle(str(state.zone0.first_recruit_choice),"first_recruit")

func add_second_recruit_to_battle() -> void:
	add_recruit_to_battle(str(state.zone0.second_recruit_choice),"second_recruit")

func complete_ashwood_ritual() -> void:
	var remaining_ratio:=clampf(float(battle_objective.get("enemy_health_remaining",.12)),.01,1.0)
	for enemy in enemies:
		if enemy.hp<=0:continue
		var health_before:float=enemy.hp
		enemy.hp=max(1.0,min(enemy.hp,enemy.max_hp*remaining_ratio))
		var ritual_damage:float=max(0.0,health_before-enemy.hp)
		if ritual_damage>0:add_effect("cast",objective_actor_pos,enemy.pos,"RITUAL -%d"%int(ritual_damage),Color("b381ff"))
	add_effect("heroic",objective_actor_pos,objective_actor_pos,"RITUAL ERUPTS",Color("b381ff"))
	add_second_recruit_to_battle()
	var recruit_key:=str(state.zone0.second_recruit_choice)
	var recruit_name:=str(AshwoodData.RECRUITS.get(recruit_key,{}).get("name","The caster"))
	set_objective_notice("The ritual devastates the attackers — %s joins the fight!"%recruit_name,4.0)

func rollback_midfight_recruit() -> void:
	if ashwood_midfight_recruit_index<0 or ashwood_midfight_recruit_index>=state.heroes.size():return
	var recruit_index:=ashwood_midfight_recruit_index
	state.heroes.remove_at(recruit_index)
	state.selected_team=state.selected_team.filter(func(member):return int(member)!=recruit_index)
	state.active_team=state.active_team.filter(func(member):return int(member)!=recruit_index)
	ashwood_midfight_recruit_index=-1

func add_special_hero(choice_key:String) -> void:
	if not AshwoodData.SPECIAL_HEROES.has(choice_key):return
	var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
	for existing in state.heroes:
		if existing.get("special_identifier","")==candidate.identifier:return
	state.heroes.append({"name":candidate.name,"class":candidate["class"],"level":3,"xp":0,"gear":14,"equipment":[],"member_type":"special_hero","is_special_hero":true,"legacy_rank":1,"signature_ability":candidate.signature,"story_lead":candidate.lead,"special_identifier":candidate.identifier})

func ashwood_item_from_spec(spec:Dictionary) -> Dictionary:
	var hero_class:="Guardian"
	if str(spec.get("family",""))=="guardian_cleric":
		hero_class=["Guardian","Cleric"].pick_random()
	else:
		var available_classes:=[]
		for hero_index in state.selected_team:
			var candidate_class=str(state.heroes[hero_index]["class"])
			if AshwoodData.LOOT_NAMES.has(candidate_class):available_classes.append(candidate_class)
		if not available_classes.is_empty():hero_class=available_classes.pick_random()
	var rarity:=str(spec.get("rarity","Common"))
	var power={"Poor":0,"Common":1,"Uncommon":2,"Rare":3,"Epic":4,"Legendary":5}.get(rarity,1)
	var item_id="ashwood_item_%d"%int(state.zone0.next_item_id)
	state.zone0.next_item_id=int(state.zone0.next_item_id)+1
	return {"id":item_id,"name":AshwoodData.LOOT_NAMES[hero_class].pick_random(),"class":hero_class,"slot":"Weapon" if int(state.zone0.next_item_id)%2==0 else "Armor","rarity":rarity,"power":power,"equipped_by":-1,"source":current_ashwood_encounter}

func equip_ashwood_item(item_id:String) -> void:
	for item in state.zone0.inventory:
		if item.id!=item_id or int(item.get("equipped_by",-1))>=0:continue
		for hero_index in state.heroes.size():
			if state.heroes[hero_index]["class"]==item["class"]:
				item.equipped_by=hero_index
				state.heroes[hero_index].equipment.append(item.id)
				state.heroes[hero_index].gear+=int(item.power)
				save_game()
				if screen=="ashwood_victory":show_ashwood_victory()
				elif screen=="vault":show_vault()
				return

func unlocked_ashwood_encounters() -> Array:
	var result:=[]
	for encounter_key in AshwoodData.all_encounter_ids():
		if AshwoodManager.encounter_is_unlocked(state.zone0,encounter_key):result.append(encounter_key)
	return result

func grant_ashwood_rewards(encounter_data:Dictionary,first_clear:bool) -> Dictionary:
	var reward:Dictionary=(encounter_data.first_rewards if first_clear else encounter_data.repeat_rewards).duplicate(true)
	var previous_progress:={}
	for hero_index in battle_hero_indices:previous_progress[hero_index]={"level":int(state.heroes[hero_index].level),"xp":int(state.heroes[hero_index].xp)}
	state.gold+=int(reward.gold)
	for hero_index in battle_hero_indices:
		var hero=state.heroes[hero_index]
		hero.xp+=int(reward.xp)
		while hero.xp>=hero.level*100:
			hero.xp-=hero.level*100
			hero.level+=1
	var item_specs:Array=reward.get("loot",[]).duplicate(true)
	if first_clear and current_ashwood_encounter=="raider_cache" and state.zone0.raiders_chased:item_specs.append({"rarity":"Common","family":"ashwood_arms"})
	if not first_clear and randf()<.38:
		var replay_rarity="Uncommon" if state.zone0.zone0_boss_defeated and randf()<.18 else "Common"
		item_specs.append({"rarity":replay_rarity,"family":"ashwood_arms"})
	var drops:=[]
	for spec in item_specs:
		var item=ashwood_item_from_spec(spec);state.zone0.inventory.append(item);drops.append(item)
	var level_ups:=[]
	var xp_progress:=[]
	for hero_index in previous_progress:
		var previous:Dictionary=previous_progress[hero_index]
		var current:Dictionary=state.heroes[hero_index]
		xp_progress.append({"hero_index":hero_index,"hero":current.name,"before_level":int(previous.level),"before_xp":int(previous.xp),"after_level":int(current.level),"after_xp":int(current.xp)})
		if current.level>previous.level:level_ups.append({"hero":current.name,"level":current.level,"hero_index":hero_index})
	return {"gold":int(reward.gold),"xp":int(reward.xp),"drops":drops,"level_ups":level_ups,"xp_progress":xp_progress}

func ashwood_story_is_pending(encounter_key:String) -> bool:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	if not encounter_data.get("decisions",[]).is_empty():
		return str(state.zone0.encounters[encounter_key].decision)==""
	if bool(encounter_data.get("special_choice",false)):
		return str(state.zone0.special_hero_choice)==""
	return false

func resume_pending_ashwood_story(encounter_key:String) -> void:
	var encounter_data:=AshwoodData.encounter(encounter_key,state.zone0)
	pending_victory={"encounter":encounter_key,"first_clear":false,"story_pending":true,"rewards":{"gold":0,"xp":0,"drops":[],"level_ups":[]},"story":str(encounter_data.story),"recruit":""}
	screen="ashwood_victory"
	show_ashwood_decision_stage()

func centered_victory_position(hero_index:int,hero_count:int,spacing:float,y_position:float) -> Vector2:
	var lineup_width:float=max(0,hero_count-1)*spacing
	var first_x:float=W*.5-lineup_width*.5
	return Vector2(first_x+hero_index*spacing,y_position)

func start_ashwood_victory_sequence() -> void:
	screen="combat"
	ui.visible=false
	victory_sequence=true;victory_phase=0;victory_timer=0.0
	dragging_hero=false;drag_target_type="ground";drag_target_index=-1
	rune_active=false;objective_notice="";objective_notice_time=0;objective_banner_time=0
	for hero_index in heroes.size():heroes[hero_index].dest=centered_victory_position(hero_index,heroes.size(),125.0,445.0)
	queue_redraw()

func finish_ashwood_battle(win:bool) -> void:
	if not win:
		rollback_midfight_recruit()
		show_ashwood_defeat()
		return
	var encounter_data:=AshwoodData.encounter(current_ashwood_encounter,state.zone0)
	var first_clear:=not AshwoodManager.encounter_is_completed(state.zone0,current_ashwood_encounter)
	var before_unlocks:=unlocked_ashwood_encounters()
	var rewards:=grant_ashwood_rewards(encounter_data,first_clear)
	if first_clear and current_ashwood_encounter=="first_recruit":add_ashwood_recruit(str(state.zone0.first_recruit_choice))
	if first_clear and current_ashwood_encounter=="raider_cache":
		state.zone0.vault_unlocked=true;state.zone0.heroes_unlocked=true
	if first_clear and current_ashwood_encounter=="second_recruit":add_ashwood_recruit(str(state.zone0.second_recruit_choice))
	AshwoodManager.mark_victory(state.zone0,current_ashwood_encounter)
	for encounter_key in unlocked_ashwood_encounters():
		if encounter_key not in before_unlocks:pending_map_reveals.append(encounter_key)
	var story_pending:=first_clear or ashwood_story_is_pending(current_ashwood_encounter)
	pending_victory={"encounter":current_ashwood_encounter,"first_clear":first_clear,"story_pending":story_pending,"rewards":rewards,"story":str(encounter_data.story),"recruit":""}
	if first_clear and current_ashwood_encounter=="first_recruit":pending_victory.recruit=str(AshwoodData.RECRUITS[state.zone0.first_recruit_choice].name)+" — "+str(AshwoodData.RECRUITS[state.zone0.first_recruit_choice]["class"])
	if first_clear and current_ashwood_encounter=="second_recruit":pending_victory.recruit=str(AshwoodData.RECRUITS[state.zone0.second_recruit_choice].name)+" — "+str(AshwoodData.RECRUITS[state.zone0.second_recruit_choice]["class"])
	save_game()
	start_ashwood_victory_sequence()

func show_ashwood_defeat() -> void:
	screen="ashwood_defeat"
	combat_layer.visible=false;ui.visible=true
	var root=base_screen("DEFEAT")
	root.add_spacer(false)
	var box=panel();box.custom_minimum_size=Vector2(720,300);box.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;root.add_child(box)
	box.add_child(label("The guild withdraws from Ashwood.",30,C_RED));box.add_child(label("No XP, gold, or equipment was awarded. Completed progress remains intact.",18,C_MUTED));box.add_spacer(false)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",14);box.add_child(actions)
	actions.add_child(button("Retry",func():start_ashwood_battle(current_ashwood_encounter),180));actions.add_child(button("Return to Map",func():show_zone_map(0),190))

func clear_ashwood_overlay() -> void:
	for child in ui.get_children():
		child.visible=false
		child.queue_free()
	ui.visible=true
	combat_layer.visible=true
	queue_redraw()

func ashwood_overlay(title_text:String,subtitle_text:String="",wide:bool=false) -> VBoxContainer:
	clear_ashwood_overlay()
	var veil:=ColorRect.new();veil.position=Vector2.ZERO;veil.size=Vector2(W,H);veil.color=Color(0.015,0.025,0.04,.42);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(veil)
	var shell:=PanelContainer.new();shell.position=Vector2(80,48) if wide else Vector2(280,95);shell.size=Vector2(1120,624) if wide else Vector2(720,530);shell.add_theme_stylebox_override("panel",ui_box(Color("172131"),16,C_GOLD,3));ui.add_child(shell)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",11);shell.add_child(content)
	var title_label:=label(title_text,38,C_GOLD);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(title_label)
	if subtitle_text!="":
		var subtitle_label:=label(subtitle_text,15,C_MUTED);subtitle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(subtitle_label)
	content.add_child(rule())
	return content

func ashwood_recap_overlay(encounter_name:String) -> VBoxContainer:
	clear_ashwood_overlay()
	var veil:=ColorRect.new();veil.position=Vector2.ZERO;veil.size=Vector2(W,H);veil.color=Color(0.015,0.025,0.04,.28);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(veil)
	var shell:=PanelContainer.new();shell.name="AshwoodRecap";shell.position=Vector2(360,145);shell.size=Vector2(560,430);shell.add_theme_stylebox_override("panel",ui_box(Color("172131"),14,C_GOLD,3));ui.add_child(shell)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",9);shell.add_child(content)
	var title_label:=label("VICTORY",30,C_GOLD);title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(title_label)
	var encounter_label:=label(encounter_name.to_upper(),13,C_MUTED);encounter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(encounter_label)
	content.add_child(rule())
	return content

func animate_ashwood_rewards() -> void:
	ashwood_reward_reveal_complete=false
	for reward_node in ashwood_reward_reveal_nodes:reward_node.modulate=Color(1,1,1,0)
	ashwood_reward_tween=create_tween()
	for reward_node in ashwood_reward_reveal_nodes:ashwood_reward_tween.tween_property(reward_node,"modulate",Color.WHITE,.18)
	ashwood_reward_tween.finished.connect(func():ashwood_reward_reveal_complete=true)

func complete_ashwood_reward_reveal() -> void:
	if ashwood_reward_tween and ashwood_reward_tween.is_valid():ashwood_reward_tween.kill()
	for reward_node in ashwood_reward_reveal_nodes:reward_node.modulate=Color.WHITE
	ashwood_reward_reveal_complete=true

func ashwood_primary_button(text_value:String,callback:Callable,width:float=240) -> Button:
	var result:=button(text_value,callback,width)
	result.add_theme_font_size_override("font_size",20)
	result.add_theme_color_override("font_color",Color("111827"))
	result.add_theme_color_override("font_hover_color",Color("111827"))
	result.add_theme_color_override("font_pressed_color",Color("111827"))
	result.add_theme_stylebox_override("normal",ui_box(C_GOLD,10,Color("fff0ad"),2))
	result.add_theme_stylebox_override("hover",ui_box(Color("ffe08a"),10,Color.WHITE,2))
	result.add_theme_stylebox_override("pressed",ui_box(Color("dba93b"),10,Color("fff0ad"),2))
	return result

func show_ashwood_victory() -> void:
	screen="ashwood_victory"
	ashwood_victory_stage="recap"
	ashwood_selected_decision_text=""
	var encounter_data:=AshwoodData.encounter(str(pending_victory.encounter),state.zone0)
	var content:=ashwood_recap_overlay(str(encounter_data.display_name))
	var reward:Dictionary=pending_victory.rewards
	content.add_child(label("●  %d Gold"%int(reward.gold),17,C_GOLD))
	content.add_child(label("+%d XP per deployed hero"%int(reward.xp),17,Color("6aa7ff")))
	if reward.drops.is_empty():content.add_child(label("No equipment drop",14,C_MUTED))
	else:
		for item in reward.drops.slice(0,2):content.add_child(label("%s  •  %s %s"%[item.name,item.rarity,item["class"]],15,AshwoodData.RARITY_COLORS[item.rarity]))
		if reward.drops.size()>2:content.add_child(label("+%d more item(s)"%(reward.drops.size()-2),13,C_MUTED))
	for level_up in reward.level_ups:content.add_child(label("%s reached Level %d"%[level_up.hero,level_up.level],15,C_GREEN))
	if str(pending_victory.recruit)!="":content.add_child(label("New member: "+str(pending_victory.recruit),15,C_GREEN))
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(spacer)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",10);content.add_child(actions)
	if bool(pending_victory.get("story_pending",false)):
		actions.add_child(ashwood_primary_button("CONTINUE",show_ashwood_decision_stage,200))
	else:
		actions.add_child(ashwood_primary_button("AGAIN",replay_ashwood_encounter,170))
		actions.add_child(button("RETURN TO WORLD MAP",return_to_ashwood_map_after_victory,230))

func show_ashwood_decision_stage() -> void:
	if not bool(pending_victory.get("story_pending",false)):return
	complete_ashwood_reward_reveal()
	ashwood_victory_stage="decision"
	var encounter_data:=AshwoodData.encounter(str(pending_victory.encounter),state.zone0)
	var content:=ashwood_overlay("VICTORY",str(encounter_data.display_name).to_upper(),bool(encounter_data.get("special_choice",false)))
	var story_label:=label(str(pending_victory.story),20,C_TEXT);story_label.custom_minimum_size.y=90;story_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;story_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(story_label)
	if bool(encounter_data.get("special_choice",false)):
		show_special_hero_choices(content)
	elif not encounter_data.get("decisions",[]).is_empty():
		var decision_heading:=label("WHAT DOES THE GUILD DO?",15,C_GOLD);decision_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(decision_heading)
		for decision in encounter_data.decisions:
			var choice:=Button.new();choice.text=str(decision.text);choice.custom_minimum_size=Vector2(650,76);choice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;choice.add_theme_font_size_override("font_size",16);choice.pressed.connect(func(id=decision.id):resolve_ashwood_decision(id));content.add_child(choice)
	else:
		show_ashwood_consequence_overlay(str(encounter_data.get("aftermath","The guild gathers itself and prepares to continue through Ashwood.")))

func next_ashwood_encounter_after(encounter_key:String) -> String:
	if not bool(pending_victory.get("story_pending",false)):return ""
	if encounter_key=="ruined_chapel" and AshwoodManager.encounter_is_unlocked(state.zone0,"rune_servant"):return "rune_servant"
	if encounter_key in AshwoodData.MANDATORY_ORDER:
		var position:=AshwoodData.MANDATORY_ORDER.find(encounter_key)
		if position>=0 and position+1<AshwoodData.MANDATORY_ORDER.size():
			var candidate:String=AshwoodData.MANDATORY_ORDER[position+1]
			if AshwoodManager.encounter_is_unlocked(state.zone0,candidate):return candidate
	for candidate in AshwoodData.MANDATORY_ORDER:
		if AshwoodManager.encounter_is_unlocked(state.zone0,candidate) and not AshwoodManager.encounter_is_completed(state.zone0,candidate):return candidate
	return ""

func ashwood_sentence_parts(text_value:String) -> Array[String]:
	var result:Array[String]=[]
	var raw_parts:=text_value.strip_edges().split(". ",false)
	for part_index in raw_parts.size():
		var sentence:=str(raw_parts[part_index]).strip_edges()
		if sentence=="":continue
		if not sentence.ends_with(".") and not sentence.ends_with("!") and not sentence.ends_with("?"):sentence+="."
		result.append(sentence)
	return result

func show_ashwood_consequence_overlay(text_value:String) -> void:
	ashwood_consequence_lines.clear()
	if ashwood_selected_decision_text!="":ashwood_consequence_lines.append_array(ashwood_sentence_parts(ashwood_selected_decision_text))
	ashwood_consequence_lines.append_array(ashwood_sentence_parts(text_value))
	if ashwood_consequence_lines.is_empty():ashwood_consequence_lines.append("The road through Ashwood changes.")
	ashwood_consequence_phase=1
	render_ashwood_consequence_overlay()

func advance_ashwood_consequence() -> void:
	if ashwood_consequence_phase<=0 or ashwood_consequence_phase>ashwood_consequence_lines.size():return
	ashwood_consequence_phase+=1
	render_ashwood_consequence_overlay()

func render_ashwood_consequence_overlay() -> void:
	ashwood_victory_stage="consequence"
	ashwood_next_encounter=next_ashwood_encounter_after(str(pending_victory.encounter))
	var overlay_title:="YOUR DECISION" if ashwood_selected_decision_text!="" else "AFTERMATH"
	var content:=ashwood_overlay(overlay_title,"THE ASHWOOD MARCHES")
	var revealed_text:=""
	for line_index in mini(ashwood_consequence_phase,ashwood_consequence_lines.size()):
		if revealed_text!="":revealed_text+="\n\n"
		revealed_text+=ashwood_consequence_lines[line_index]
	var consequence_label:=label(revealed_text,21,C_TEXT);consequence_label.custom_minimum_size.y=190;consequence_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;consequence_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(consequence_label)
	if ashwood_consequence_phase<=ashwood_consequence_lines.size():
		var reveal_prompt:=label("Tap to continue" if OS.has_feature("mobile") else "Click, tap, or press any key to continue",15,C_GOLD);reveal_prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(reveal_prompt)
		return
	content.add_child(rule())
	if ashwood_next_encounter!="":
		var next_data:=AshwoodData.encounter(ashwood_next_encounter,state.zone0)
		var next_label:=label("NEXT  •  "+str(next_data.display_name),16,C_GOLD);next_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(next_label)
		var next_story:=label(str(next_data.scenario),16,C_MUTED);next_story.custom_minimum_size.y=90;next_story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(next_story)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",16);content.add_child(actions)
	if ashwood_next_encounter!="":actions.add_child(ashwood_primary_button("CONTINUE",continue_ashwood_adventure,250))
	actions.add_child(button("RETURN TO WORLD MAP",return_to_ashwood_map_after_victory,250))

func replay_ashwood_encounter() -> void:
	var replay_encounter:=str(pending_victory.encounter)
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	start_ashwood_battle(replay_encounter)

func continue_ashwood_adventure() -> void:
	var next_encounter:=ashwood_next_encounter
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	if next_encounter!="":start_ashwood_battle(next_encounter)
	else:show_zone_map(0)

func return_to_ashwood_map_after_victory() -> void:
	pending_victory={};ashwood_victory_stage="";ashwood_next_encounter="";ashwood_selected_decision_text="";ashwood_consequence_lines.clear();ashwood_consequence_phase=0
	show_zone_map(0)

func resolve_ashwood_decision(decision_id:String) -> void:
	var before_unlocks:=unlocked_ashwood_encounters()
	var decision:=AshwoodManager.apply_decision(state.zone0,str(pending_victory.encounter),decision_id)
	ashwood_selected_decision_text=str(decision.get("text",""))
	for encounter_key in unlocked_ashwood_encounters():
		if encounter_key not in before_unlocks:pending_map_reveals.append(encounter_key)
	save_game()
	show_ashwood_consequence_overlay(str(decision.get("consequence","The road through Ashwood changes.")))

func show_special_hero_choices(content:VBoxContainer) -> void:
	content.add_child(label("CHOOSE ONE SPECIAL HERO",18,C_GOLD))
	content.add_child(label("The other survivors will leave to pursue separate leads. This choice is permanent for this guild.",15,C_MUTED))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
	for choice_key in AshwoodData.SPECIAL_HEROES:
		var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
		var card:=Button.new();card.custom_minimum_size=Vector2(350,205);card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_theme_font_size_override("font_size",14);card.add_theme_color_override("font_color",CLASSES[candidate["class"]].color);card.add_theme_stylebox_override("normal",ui_box(Color("182536"),10,CLASSES[candidate["class"]].color,2));card.text="[%s]\n%s\n%s  •  %s\n%s\nSignature: %s\n%s"%[candidate.visual_identity,candidate.name,candidate["class"],candidate.role,candidate.personality,candidate.signature,candidate.reason];card.pressed.connect(func(id=choice_key):choose_special_hero(id));row.add_child(card)

func show_pending_special_choice() -> void:
	screen="ashwood_victory"
	var root=base_screen("THE ASHWOOD SURVIVORS","A PERMANENT CHOICE")
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",12);root.add_child(content)
	content.add_child(label("The servant is gone, but the lost party's traitor escaped. Three survivors now decide which lead to follow.",18,C_TEXT))
	show_special_hero_choices(content)

func choose_special_hero(choice_key:String) -> void:
	if str(state.zone0.special_hero_choice)!="":return
	var candidate:Dictionary=AshwoodData.SPECIAL_HEROES[choice_key]
	state.zone0.special_hero_choice=choice_key
	state.zone0.party_management_unlocked=true
	add_special_hero(choice_key)
	ashwood_selected_decision_text="%s will remain with the guild."%candidate.name
	save_game()
	show_ashwood_consequence_overlay("%s remains with the guild. The other two survivors depart to follow separate leads. Party Management is now available."%candidate.name)

func finish_battle(win:bool)->void:
	battle_over=true
	if current_ashwood_encounter!="":
		finish_ashwood_battle(win)
		return
	if win:
		var previous_levels:=[]
		for i in heroes.size():previous_levels.append(state.heroes[battle_hero_indices[i]].level)
		state.dungeon_clears[dungeon_id]+=1
		if encounter_id<10:
			state.zone_progress[dungeon_id]=max(int(state.zone_progress[dungeon_id]),min(10,encounter_id+1))
			if encounter_id==9 and dungeon_id==0:
				state.unlocked_dungeon=1
		elif encounter_id<12:
			state.zone_branches[dungeon_id][encounter_id-10]=true
		grant_rewards(dungeon_id,true); victory_level_ups.clear()
		for i in heroes.size():
			var hero_data=state.heroes[battle_hero_indices[i]]
			if hero_data.level>previous_levels[i]:victory_level_ups.append({"slot":i,"level":hero_data.level,"unlocks":[]})
		save_game()
		dragging_hero=false;drag_target_type="ground";drag_target_index=-1;victory_sequence=true; victory_phase=0; victory_timer=0.0
		for i in heroes.size():heroes[i].dest=centered_victory_position(i,heroes.size(),105.0,465.0)
		queue_redraw(); return
	var overlay:=ColorRect.new(); overlay.color=Color(0.03,0.05,0.09,.96); overlay.position=Vector2(300,120); overlay.size=Vector2(680,480); ui.visible=true; ui.add_child(overlay)
	var box:=VBoxContainer.new(); box.position=Vector2(350,160); box.size=Vector2(580,400); box.add_theme_constant_override("separation",14); ui.add_child(box)
	box.add_child(label("VICTORY" if win else "DEFEAT",38,C_GOLD if win else C_RED)); box.add_child(label(("The guild returns richer and stronger." if win else "Recover, re-equip, and try a new formation."),18,C_MUTED)); if win:box.add_child(label("Rewards: %d gold • XP • materials • dungeon token"%(90+dungeon_id*55),18,C_GREEN)); box.add_spacer(false); box.add_child(button("Return to Guild Hall",show_hall,250))
	box.add_child(button("Retry Encounter",func():start_battle(dungeon_id,encounter_id),250))
	box.add_child(label("Enter / Esc: Guild Hall     R: Retry",15,C_MUTED))

func update_victory(delta:float) -> void:
	for fx in effects:fx.life-=delta
	effects=effects.filter(func(fx):return fx.life>0)
	victory_timer+=delta
	if victory_phase==0 and victory_timer>=1.2: victory_phase=1; victory_timer=0
	elif victory_phase==1:
		for h in heroes: h.pos=h.pos.move_toward(h.dest,115*delta)
		var gathered=heroes.all(func(h):return h.pos.distance_to(h.dest)<4)
		if gathered or victory_timer>=4.5:
			# Guarantee a clean lineup if a distant hero cannot finish walking
			# before the reward presentation advances.
			for h in heroes: h.pos=h.dest
			victory_phase=2; victory_timer=0
	elif victory_phase==2 and victory_timer>=1.3: victory_phase=3; victory_timer=0
	elif victory_phase==3 and victory_timer>=1.3: victory_phase=4; victory_timer=0
	elif victory_phase==4 and victory_timer>=1.2: victory_phase=5; victory_timer=0
	queue_redraw()

func victory_xp_animation_state(progress_data:Dictionary,xp_award:int,animation_progress:float) -> Dictionary:
	var shown_level:int=int(progress_data.get("before_level",1))
	var shown_xp:float=float(progress_data.get("before_xp",0))+xp_award*clampf(animation_progress,0.0,1.0)
	while shown_xp>=shown_level*100:shown_xp-=shown_level*100;shown_level+=1
	return {"level":shown_level,"xp":shown_xp,"ratio":shown_xp/max(1.0,shown_level*100.0)}

func grant_rewards(id:int,manual:bool)->void:
	var mod=1.0 if manual else .7; state.gold+=int((90+id*55)*mod); state.tokens+=1; state.ore+=int((3+id)*mod); state.herbs+=int((2+id*2)*mod); if id==1:state.dust+=int(3*mod)
	for h in state.heroes:
		h.xp+=int((55+id*35)*mod)
		while h.xp>=h.level*100: h.xp-=h.level*100; h.level+=1; h.gear+=1

func octagon_points(center:Vector2,radius:float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i in 8: points.append(center+Vector2(cos(PI/8+i*PI/4),sin(PI/8+i*PI/4))*radius)
	return points

func draw_octagon(center:Vector2,radius:float,fill:Color,outline:Color,width:float=3.0) -> void:
	var points=octagon_points(center,radius); draw_colored_polygon(points,fill); points.append(points[0]); draw_polyline(points,outline,width)

func draw_octagon_health(center:Vector2,radius:float,ratio:float) -> void:
	var points=octagon_points(center,radius);var edge_progress=clamp(ratio,0.0,1.0)*8.0
	for edge in 8:
		var fraction=clamp(edge_progress-edge,0.0,1.0)
		if fraction>0:draw_line(points[edge],points[edge].lerp(points[(edge+1)%8],fraction),C_GREEN,4)

func draw_tutorial_dotted_path(from:Vector2,to:Vector2)->void:
	var length=from.distance_to(to)
	if length<1:return
	var direction=from.direction_to(to)
	var alpha=.8*(.5+.5*sin(tutorial_timer*3.2))
	var distance=fposmod(tutorial_timer*42.0,24.0)
	while distance<length:
		draw_circle(from+direction*distance,4.5,Color(C_GOLD,alpha))
		distance+=24.0

func draw_tutorial_glow(center:Vector2,radius:float,color:Color=C_GOLD)->void:
	var pulse=.5+.5*sin(tutorial_timer*4.0)
	var emphasis=1.55 if tutorial_reject_time>0 else 1.0
	draw_circle(center,radius+(8+pulse*5)*emphasis,Color(color,(.06+.06*pulse)*emphasis))
	draw_arc(center,radius+(7+pulse*3)*emphasis,0,TAU,48,Color(color,min(1.0,(.42+.35*pulse)*emphasis)),3*emphasis)

func draw_tutorial_box(rect:Rect2)->void:
	var pulse=.5+.5*sin(tutorial_timer*4.0)
	var emphasis=1.55 if tutorial_reject_time>0 else 1.0
	draw_rect(rect.grow((4+pulse*3)*emphasis),Color(C_GOLD,(.035+.035*pulse)*emphasis))
	draw_rect(rect.grow((2+pulse*2)*emphasis),Color(C_GOLD,min(1.0,(.5+.4*pulse)*emphasis)),false,3*emphasis)

func tutorial_should_show_instruction_box()->bool:
	return tutorial_active and tutorial_step!=8

func tutorial_should_show_ability_bar()->bool:
	if selected<0 or selected>=heroes.size():return false
	if not tutorial_active:return true
	return tutorial_step>=7 and (tutorial_step!=7 or selected==1)

func draw_damaged_caravan(center:Vector2) -> void:
	var body_rect:=Rect2(center+Vector2(-72,-24),Vector2(144,52))
	var canvas_points:=PackedVector2Array([center+Vector2(-58,-24),center+Vector2(-43,-58),center+Vector2(42,-58),center+Vector2(61,-24)])
	draw_colored_polygon(canvas_points,Color("c9b17d"))
	draw_polyline(PackedVector2Array([canvas_points[0],canvas_points[1],canvas_points[2],canvas_points[3]]),Color("7f6844"),4)
	draw_rect(body_rect,Color("805537"));draw_rect(body_rect,Color("d2a260"),false,4)
	for wheel_offset in [-43.0,43.0]:
		var wheel_center:=center+Vector2(wheel_offset,32)
		draw_circle(wheel_center,19,Color("28231f"));draw_circle(wheel_center,14,Color("765338"));draw_circle(wheel_center,4,Color("d2a260"))
		for spoke in 4:draw_line(wheel_center,wheel_center+Vector2.from_angle(spoke*PI/2.0)*13,Color("c18b50"),3)
	# Broken boards and torn canvas make its starting damage readable at a glance.
	draw_line(center+Vector2(-14,-22),center+Vector2(-2,1),Color("3c261f"),4)
	draw_line(center+Vector2(-2,1),center+Vector2(-13,23),Color("3c261f"),4)
	draw_line(center+Vector2(21,-55),center+Vector2(12,-38),Color("755d40"),3)
	draw_line(center+Vector2(12,-38),center+Vector2(27,-25),Color("755d40"),3)
	var health_ratio:float=objective_health/max(1.0,objective_max_health)
	health_bar(center+Vector2(-76,-82),152,health_ratio,C_GREEN if health_ratio>.45 else C_GOLD if health_ratio>.2 else C_RED)
	draw_string(ThemeDB.fallback_font,center+Vector2(-55,-91),"DAMAGED CARAVAN",HORIZONTAL_ALIGNMENT_CENTER,110,12,C_TEXT)

func draw_combat_background() -> void:
	# A dark tint keeps units, telegraphs, and targeting guides readable while
	# demonstrating a real imported environment texture in the combat scene.
	draw_texture_rect(FOREST_GROUND_TEXTURE,Rect2(0,0,W,H),true,Color("829985"))
	draw_rect(Rect2(0,0,W,H),Color(0.025,0.055,0.045,.46))
	for x in range(0,1281,80):draw_line(Vector2(x,0),Vector2(x,H),Color(1,1,1,.018),1)
	for y in range(0,721,80):draw_line(Vector2(0,y),Vector2(W,y),Color(1,1,1,.018),1)

func _draw() -> void:
	if screen not in ["combat","ashwood_victory"]:return
	draw_combat_background()
	if tutorial_should_show_instruction_box():
		if tutorial_step==0 and not heroes.is_empty() and not tutorial_targets.is_empty():
			draw_tutorial_dotted_path(heroes[0].pos,tutorial_targets[0]);draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color)
		elif tutorial_step==2 and not heroes.is_empty() and not enemies.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color);draw_tutorial_glow(enemies[0].pos,52,C_RED)
		elif tutorial_step==3 and not heroes.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color)
		elif tutorial_step==4 and heroes.size()>1:
			draw_tutorial_glow(heroes[1].pos,52,CLASSES["Cleric"].color);draw_tutorial_glow(heroes[0].pos,52,C_GREEN)
		elif tutorial_step==6 and not heroes.is_empty() and not enemies.is_empty():
			draw_tutorial_glow(heroes[0].pos,52,CLASSES["Guardian"].color);draw_tutorial_glow(enemies[-1].pos,52,C_RED)
		for target_index in tutorial_targets.size():
			if target_index>=tutorial_target_reached.size() or not tutorial_target_reached[target_index]:
				var marker:Vector2=tutorial_targets[target_index]
				draw_circle(marker,44,Color(C_GREEN,.15));draw_arc(marker,44,0,TAU,40,C_GREEN,5)
				draw_line(marker+Vector2(0,-92),marker+Vector2(0,-58),C_GREEN,9)
				draw_colored_polygon(PackedVector2Array([marker+Vector2(-16,-65),marker+Vector2(16,-65),marker+Vector2(0,-45)]),C_GREEN)
	if current_ashwood_encounter!="" and not battle_objective.is_empty() and not victory_sequence:
		var objective_type:=str(battle_objective.type)
		var tracks_progress:=objective_type in ["protect_task","protect_caravan","ritual_defense","survival"]
		var progress_color:=C_GREEN if objective_type=="protect_caravan" else Color("6aa7ff")
		if objective_banner_time>0:
			var banner_alpha:float=clampf(objective_banner_time,0.0,1.0)
			var has_story:=objective_combat_intro!=""
			var objective_rect:=Rect2(310,18,660,76 if has_story else 58)
			draw_rect(objective_rect,Color(0.03,.055,.09,.92*banner_alpha));draw_rect(objective_rect,Color(C_GOLD,.65*banner_alpha),false,2)
			if has_story:draw_string(ThemeDB.fallback_font,Vector2(335,42),objective_combat_intro,HORIZONTAL_ALIGNMENT_CENTER,610,15,Color(C_MUTED,banner_alpha))
			draw_string(ThemeDB.fallback_font,Vector2(335,67 if has_story else 43),str(battle_objective.label).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,610,16,Color(C_TEXT,banner_alpha))
			if tracks_progress:
				var progress_y:=78 if has_story else 52
				draw_rect(Rect2(355,progress_y,570,8),Color(0.06,.08,.12,banner_alpha));draw_rect(Rect2(355,progress_y,570*objective_progress,8),Color(progress_color,banner_alpha))
		elif tracks_progress and not objective_complete:
			draw_rect(Rect2(440,20,400,7),Color("10151e"));draw_rect(Rect2(440,20,400*objective_progress,7),progress_color)
		if objective_type=="protect_caravan" and objective_health>0:
			draw_damaged_caravan(objective_actor_pos)
		elif objective_type in ["protect_task","ritual_defense"] and not objective_complete:
			var actor_color:=Color("65dc89") if state.zone0.first_recruit_choice=="ranger" else Color("e6b35f")
			if objective_type=="ritual_defense":actor_color=Color("b381ff") if state.zone0.second_recruit_choice=="mage" else Color("d16ca8")
			draw_circle(objective_actor_pos,42,Color(actor_color,.18));draw_arc(objective_actor_pos,48,0,TAU,40,actor_color,4);draw_string(ThemeDB.fallback_font,objective_actor_pos+Vector2(-55,7),"SIGNAL" if objective_type=="protect_task" else "RITUAL",HORIZONTAL_ALIGNMENT_CENTER,110,14,C_TEXT)
	if rune_active:
		draw_circle(rune_center,rune_radius,Color(C_RED,.10));draw_arc(rune_center,rune_radius,0,TAU,64,Color(C_RED,.92),5);draw_circle(rune_center,118,Color(C_RED,.025));draw_arc(rune_center,118,0,TAU,64,Color(C_RED,.35),2)
	if objective_notice!="":draw_string(ThemeDB.fallback_font,Vector2(320,102),objective_notice,HORIZONTAL_ALIGNMENT_CENTER,640,17,C_GOLD)
	for i in enemies.size():
		var e=enemies[i]; if e.hp<=0:continue
		if e.telegraph>0:
			var warning_pos=e.danger_pos if e.special=="danger" or e.special=="charge" or e.special=="basic" else e.pos; var warning_radius=38.0 if e.special=="basic" else 78.0 if e.special=="danger" else 115.0
			draw_circle(warning_pos,warning_radius,Color(1,.15,.12,.16));draw_arc(warning_pos,warning_radius,0,TAU,48,C_RED,3)
			if e.special=="charge": draw_dashed_line(e.pos,e.danger_pos,C_RED,5,10)
		var enemy_color=GameData.enemy_color(e.type)
		var target_outline:=Color.WHITE if focused_enemy_index==i else C_GOLD if heroes.size()>selected and heroes[selected].target==i else Color("5f2931")
		draw_circle(e.pos,46,enemy_color); draw_circle(e.pos,52,target_outline,4); if not victory_sequence and (e.revealed or e.hp<e.max_hp):health_bar(e.pos+Vector2(-54,-70),108,e.hp/e.max_hp,C_RED); draw_string(ThemeDB.fallback_font,e.pos+Vector2(-40,6),e.type.substr(0,7),HORIZONTAL_ALIGNMENT_CENTER,80,15,C_TEXT)
	for i in heroes.size():
		var h=heroes[i]; var col=CLASSES[h["class"]].color; if h.hp<=0:col=Color("455067")
		if i==selected and not victory_sequence and not bool(h.get("independent",false)):
			draw_circle(h.pos,66,Color(C_GOLD,.18));draw_circle(h.pos,59,C_GOLD,4)
		if h.shield>0 and not victory_sequence:draw_circle(h.pos,63,Color("5fa8ff"),4)
		draw_circle(h.pos,48,col);draw_role_icon(h.pos,h["class"]);if not victory_sequence and (h.hp<h.max_hp or h.last_hit>0):health_bar(h.pos+Vector2(-54,-70),108,max(0,h.hp/h.max_hp),C_GREEN)
		if bool(h.get("independent",false)) and not victory_sequence:draw_string(ThemeDB.fallback_font,h.pos+Vector2(-42,-62),"ALLIED NPC",HORIZONTAL_ALIGNMENT_CENTER,84,12,C_GREEN)
	if dragging_hero:
		draw_dashed_line(heroes[selected].pos,drag_cursor,Color(C_GOLD,.75),6,8)
		var preview_color=C_GREEN if drag_target_type=="ally" else (C_RED if drag_target_type=="enemy" else C_GOLD)
		var preview_pos=drag_cursor
		if drag_target_type=="enemy":preview_pos=enemies[drag_target_index].pos
		elif drag_target_type=="ally":preview_pos=heroes[drag_target_index].pos
		draw_circle(preview_pos,42,Color(preview_color,.14));draw_arc(preview_pos,42,0,TAU,40,preview_color,4)
	if ability_aiming and selected<heroes.size():
		var aiming_hero=heroes[selected];var range_limit=float(ABILITY_RANGES[aiming_hero["class"]][aimed_ability_slot]);var aim_point=clamped_cast_point(aiming_hero,ability_aim_point,range_limit) if range_limit>0 else aiming_hero.pos
		if range_limit>0:draw_circle(aiming_hero.pos,range_limit,Color(C_GOLD,.035));draw_arc(aiming_hero.pos,range_limit,0,TAU,64,Color(C_GOLD,.55),2)
		if aimed_ability_category=="ground":draw_circle(aim_point,30,Color(C_GOLD,.16));draw_arc(aim_point,30,0,TAU,30,C_GOLD,3);draw_dashed_line(aiming_hero.pos,aim_point,Color(C_GOLD,.7),8,6)
		elif aimed_ability_category=="directional":draw_dashed_line(aiming_hero.pos,aim_point,C_GOLD,10,6);draw_circle(aim_point,14,Color(C_GOLD,.3))
		elif aimed_ability_category=="area":draw_circle(aiming_hero.pos,max(90.0,range_limit),Color(C_GOLD,.10));draw_arc(aiming_hero.pos,max(90.0,range_limit),0,TAU,48,C_GOLD,3)
	for fx in effects: draw_combat_effect(fx)
	if screen!="combat":return
	if tutorial_should_show_instruction_box():
		var instruction_pulse=.5+.5*sin(tutorial_timer*5.0) if tutorial_idle_hint_shown else 0.0
		var instruction_rect=Rect2(230,18,820,82)
		if tutorial_idle_hint_shown:draw_rect(instruction_rect.grow(3+instruction_pulse*5),Color(C_GOLD,.035+.055*instruction_pulse))
		draw_rect(instruction_rect,Color(0.03,.055,.09,.92));draw_rect(instruction_rect,Color(C_GOLD,.55+.4*instruction_pulse),false,2+instruction_pulse*2);draw_string(ThemeDB.fallback_font,Vector2(275,43),"TRAINING",HORIZONTAL_ALIGNMENT_CENTER,730,14,C_GOLD);draw_string(ThemeDB.fallback_font,Vector2(275,74),tutorial_prompt(),HORIZONTAL_ALIGNMENT_CENTER,730,19,C_TEXT)
		if tutorial_reject_time>0:
			draw_rect(Rect2(320,106,640,38),Color(0.03,.055,.09,.94));draw_rect(Rect2(320,106,640,38),Color(C_GOLD,.65),false,2);draw_string(ThemeDB.fallback_font,Vector2(345,131),tutorial_feedback_message,HORIZONTAL_ALIGNMENT_CENTER,590,15,C_GOLD)
	if not victory_sequence and (not tutorial_active or tutorial_step>=4):
		var selectable_heroes:Array=player_controlled_hero_indices()
		for i in 8:
			var center=Vector2(451+i*54,604)
			var occupied=i<selectable_heroes.size()
			var hero_index:int=selectable_heroes[i] if occupied else -1
			var is_selected=occupied and hero_index==selected
			var portrait_radius=29.0 if is_selected else 26.0
			var portrait_fill=Color("26364a") if is_selected else Color("172130")
			if is_selected:
				var glow_color=Color(CLASSES[heroes[hero_index]["class"]].color,.16)
				draw_circle(center,35,glow_color)
				draw_octagon(center,33,Color.TRANSPARENT,C_GOLD,3)
			draw_octagon(center,portrait_radius,portrait_fill,Color("65758d") if occupied else Color("46546a"),3)
			if occupied:
				draw_octagon_health(center,portrait_radius+1,max(0,heroes[hero_index].hp/heroes[hero_index].max_hp))
				var class_color:Color=CLASSES[heroes[hero_index]["class"]].color
				var icon_color=class_color if is_selected else class_color.lerp(Color("929aa6"),.68)
				draw_role_icon(center-Vector2(0,4),heroes[hero_index]["class"],icon_color)
				draw_string(ThemeDB.fallback_font,center+Vector2(-8,20),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,16,11,C_GOLD if is_selected else C_MUTED)
		if tutorial_should_show_ability_bar():
			var active=heroes[selected];var keys=["Q","W","E","R",""]
			var visible_ability_count=1 if state.heroes[battle_hero_indices[selected]].level<=1 else 5
			for slot in visible_ability_count:
				var center=Vector2(484+slot*78,674); draw_octagon(center,37,Color("263a57") if slot<3 else Color("59402b"),C_MUTED,3); draw_string(ThemeDB.fallback_font,center+Vector2(-34,-4),(ABILITIES[active["class"]][slot] if slot<4 else TRAITS[active["class"]]).substr(0,10),HORIZONTAL_ALIGNMENT_CENTER,68,10,C_TEXT); draw_string(ThemeDB.fallback_font,center+Vector2(-28,25),keys[slot],HORIZONTAL_ALIGNMENT_CENTER,56,14,C_GOLD)
				if active.ability_cds[slot]>0:draw_octagon(center,37,Color(0,0,0,.62),C_MUTED,2);draw_string(ThemeDB.fallback_font,center+Vector2(-18,7),"%.1f"%active.ability_cds[slot],HORIZONTAL_ALIGNMENT_CENTER,36,15,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(1080,50),"●  %d"%state.gold,HORIZONTAL_ALIGNMENT_RIGHT,115,20,C_GOLD);draw_circle(Vector2(1235,42),25,Color(0.08,.11,.16,.9)); draw_string(ThemeDB.fallback_font,Vector2(1222,50),"Ⅱ",HORIZONTAL_ALIGNMENT_LEFT,-1,22,C_TEXT)
	if tutorial_active and tutorial_step==4:
		draw_tutorial_box(Rect2(420,570,455,68))
	if tutorial_active and tutorial_step==7:
		if selected!=1:draw_tutorial_box(Rect2(478,570,54,68))
		draw_tutorial_box(Rect2(445,635,78,78))
	if tutorial_active and tutorial_step==8:
		draw_rect(Rect2(300,145,680,330),Color(0.025,.045,.075,.96));draw_rect(Rect2(300,145,680,330),Color(C_GREEN,.8),false,3)
		draw_string(ThemeDB.fallback_font,Vector2(350,195),"TRAINING COMPLETE",HORIZONTAL_ALIGNMENT_CENTER,580,32,C_GREEN)
		draw_string(ThemeDB.fallback_font,Vector2(375,242),"•  Drag heroes to move or assign targets",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,282),"•  Brann draws enemy attention",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,322),"•  Sera keeps a persistent healing target",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(375,362),"•  Use the action bar for abilities",HORIZONTAL_ALIGNMENT_LEFT,530,20,C_TEXT)
		draw_string(ThemeDB.fallback_font,Vector2(365,427),"Tap to continue" if tutorial_input_device=="mobile" else "Click or press any key to continue",HORIZONTAL_ALIGNMENT_CENTER,550,18,C_GOLD)
	if paused:
		draw_rect(Rect2(390,190,500,300),Color(0.03,.05,.08,.94)); draw_string(ThemeDB.fallback_font,Vector2(565,250),"PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,34,C_GOLD); draw_rect(Rect2(490,285,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,322),"RESUME",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_TEXT); draw_rect(Rect2(490,360,300,58),C_PANEL_2); draw_string(ThemeDB.fallback_font,Vector2(600,397),"RETREAT",HORIZONTAL_ALIGNMENT_LEFT,-1,20,C_RED)
	if victory_sequence and victory_phase>=1:
		draw_string(ThemeDB.fallback_font,Vector2(400,117),"VICTORY",HORIZONTAL_ALIGNMENT_CENTER,480,66,C_GOLD)
		if current_ashwood_encounter!="" and not pending_victory.is_empty():
			var reward:Dictionary=pending_victory.rewards
			if victory_phase>=2:draw_string(ThemeDB.fallback_font,Vector2(420,190),"●  +%d GOLD"%int(reward.gold),HORIZONTAL_ALIGNMENT_CENTER,440,32,C_GOLD)
			if victory_phase>=3:
				var drop_text:="NO EQUIPMENT DROP" if reward.drops.is_empty() else str(reward.drops[0].name).to_upper()
				draw_string(ThemeDB.fallback_font,Vector2(390,240),drop_text,HORIZONTAL_ALIGNMENT_CENTER,500,24,C_MUTED if reward.drops.is_empty() else AshwoodData.RARITY_COLORS[reward.drops[0].rarity])
			if victory_phase>=4:draw_string(ThemeDB.fallback_font,Vector2(390,282),"+%d XP PER HERO"%int(reward.xp),HORIZONTAL_ALIGNMENT_CENTER,500,26,Color("6aa7ff"))
			if victory_phase>=5:
				var xp_animation:float=clampf(victory_timer/1.6,0.0,1.0)
				var xp_progress:Array=reward.get("xp_progress",[])
				for i in heroes.size():
					var hero_index:int=battle_hero_indices[i]
					var progress_data:Dictionary={}
					for candidate in xp_progress:
						if int(candidate.hero_index)==hero_index:progress_data=candidate;break
					if progress_data.is_empty():progress_data={"before_level":state.heroes[hero_index].level,"before_xp":state.heroes[hero_index].xp}
					var shown_progress:Dictionary=victory_xp_animation_state(progress_data,int(reward.xp),xp_animation)
					var shown_level:int=int(shown_progress.level)
					var xp_ratio:float=float(shown_progress.ratio)
					var bar_center_x:float=535+i*125
					health_bar(Vector2(bar_center_x-45,505),90,xp_ratio,Color("6aa7ff"))
					draw_string(ThemeDB.fallback_font,Vector2(bar_center_x-50,532),"LV %d"%shown_level,HORIZONTAL_ALIGNMENT_CENTER,100,13,C_MUTED)
					if xp_animation>=.8 and int(progress_data.get("after_level",shown_level))>int(progress_data.get("before_level",shown_level)):
						draw_string(ThemeDB.fallback_font,Vector2(bar_center_x-58,557),"LEVEL UP!",HORIZONTAL_ALIGNMENT_CENTER,116,15,C_GREEN)
				if xp_animation>=1.0:draw_string(ThemeDB.fallback_font,Vector2(440,610),"Click or tap to continue",HORIZONTAL_ALIGNMENT_CENTER,400,22,C_MUTED)
		else:
			if victory_phase>=2:draw_string(ThemeDB.fallback_font,Vector2(420,190),"●  +%d"%(90+dungeon_id*55),HORIZONTAL_ALIGNMENT_CENTER,440,36,C_GOLD)
			if victory_phase>=3:draw_string(ThemeDB.fallback_font,Vector2(390,235),"MATERIALS COLLECTED",HORIZONTAL_ALIGNMENT_CENTER,500,26,C_GREEN)
			if victory_phase>=4:draw_string(ThemeDB.fallback_font,Vector2(390,275),"SPECIAL REWARD",HORIZONTAL_ALIGNMENT_CENTER,500,26,Color("b381ff"))
			if victory_phase>=5:draw_string(ThemeDB.fallback_font,Vector2(440,585),"Click To Continue",HORIZONTAL_ALIGNMENT_CENTER,400,24,C_MUTED)
	if toast_time>0:draw_string(ThemeDB.fallback_font,Vector2(480,680),toast,HORIZONTAL_ALIGNMENT_LEFT,-1,17,C_GOLD)

func health_bar(pos:Vector2,width:float,ratio:float,color:Color)->void:
	draw_rect(Rect2(pos,Vector2(width,7)),Color("11151e"));draw_rect(Rect2(pos,Vector2(width*clamp(ratio,0,1),7)),color)
func add_effect(kind:String,from:Vector2,to:Vector2,text_value:String,color:Color)->void:
	effects.append({"kind":kind,"from":from,"to":to,"text":text_value,"color":color,"life":.75 if kind!="heroic" else 1.25,"max_life":.75 if kind!="heroic" else 1.25})
func draw_combat_effect(fx:Dictionary)->void:
	var progress=1.0-fx.life/fx.max_life
	var alpha=clamp(fx.life*2.0,0.0,1.0)
	var col=Color(fx.color,alpha)
	match fx.kind:
		"projectile":
			var p=fx.from.lerp(fx.to,clamp(progress*1.8,0.0,1.0));draw_line(p-Vector2(12,0),p+Vector2(8,0),col,5);draw_circle(p,5,Color.WHITE)
		"slash":
			draw_line(fx.to+Vector2(-22,-18),fx.to+Vector2(22,18),col,7);draw_line(fx.to+Vector2(-16,22),fx.to+Vector2(18,-16),Color.WHITE,3)
		"hit":
			draw_circle(fx.to,28+progress*22,Color(col,.16));draw_line(fx.from,fx.to,col,4)
		"heal":
			draw_line(fx.from,fx.to,col,4);draw_circle(fx.to,25+progress*30,Color(col,.18));draw_arc(fx.to,25+progress*30,0,TAU,30,col,3)
		"cast":
			draw_arc(fx.from,30+progress*18,0,TAU,32,col,4)
		"heroic":
			draw_circle(fx.from,38+progress*80,Color(col,.14));draw_arc(fx.from,38+progress*80,0,TAU,40,col,6)
	if fx.text!="":
		var text_pos=fx.to+Vector2(-28,-48-progress*30)
		draw_string(ThemeDB.fallback_font,text_pos,fx.text,HORIZONTAL_ALIGNMENT_CENTER,90,17,col)
func draw_role_icon(pos:Vector2,hero_class:String,ink:Color=Color("101827"))->void:
	if hero_class=="Guardian":
		var shield=PackedVector2Array([pos+Vector2(-11,-13),pos+Vector2(11,-13),pos+Vector2(9,5),pos+Vector2(0,15),pos+Vector2(-9,5)])
		draw_colored_polygon(shield,ink);draw_polyline(shield+PackedVector2Array([shield[0]]),Color.WHITE,2)
	elif hero_class=="Cleric":
		draw_rect(Rect2(pos+Vector2(-5,-15),Vector2(10,30)),ink);draw_rect(Rect2(pos+Vector2(-15,-5),Vector2(30,10)),ink)
	elif hero_class=="Mage":
		draw_line(pos+Vector2(-11,13),pos+Vector2(8,-8),ink,5);draw_circle(pos+Vector2(11,-11),6,ink);draw_circle(pos+Vector2(11,-11),2,Color.WHITE)
	elif hero_class=="Rogue":
		draw_line(pos+Vector2(-13,12),pos+Vector2(11,-12),ink,5);draw_line(pos+Vector2(-11,-12),pos+Vector2(13,12),ink,5)
	elif hero_class=="Warlock":
		draw_circle(pos,13,Color.TRANSPARENT,2);draw_arc(pos,14,0,TAU,28,ink,4);draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-15),pos+Vector2(10,6),pos+Vector2(0,2),pos+Vector2(-10,6)]),ink)
	else:
		# Ranged DPS use a bow marker. Future melee classes can use crossed swords.
		draw_arc(pos+Vector2(-3,0),15,-PI/2,PI/2,18,ink,4);draw_line(pos+Vector2(-3,-15),pos+Vector2(-3,15),ink,2);draw_line(pos+Vector2(-3,0),pos+Vector2(15,0),ink,3);draw_colored_polygon(PackedVector2Array([pos+Vector2(15,0),pos+Vector2(8,-5),pos+Vector2(8,5)]),ink)
func flash(msg:String)->void:toast=msg;toast_time=2.5;queue_redraw()
