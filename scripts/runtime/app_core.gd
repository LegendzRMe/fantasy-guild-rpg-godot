
extends "res://scripts/runtime/app_state.gd"

const GameData = preload("res://scripts/data/game_data.gd")
const ItemData = preload("res://scripts/data/item_data.gd")
const InventorySystem = preload("res://scripts/systems/inventory_system.gd")
const AshwoodData = preload("res://scripts/data/ashwood_data.gd")
const CombatSystem = preload("res://scripts/systems/combat_system.gd")
const PrestigeSystem = preload("res://scripts/systems/prestige_system.gd")
const TalentSystem = preload("res://scripts/systems/talent_system.gd")
const AshwoodManager = preload("res://scripts/systems/ashwood_manager.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const TeamManager = preload("res://scripts/systems/team_manager.gd")
const RosterManager = preload("res://scripts/systems/roster_manager.gd")
const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const LockOverlay = preload("res://scripts/ui/lock_overlay.gd")
const ItemCardView = preload("res://scripts/ui/item_card_view.gd")
const CombatRulesV1 = preload("res://scripts/combat/combat_rules_v1.gd")
const CombatGeometry = preload("res://scripts/combat/combat_geometry.gd")
const CombatProjectile = preload("res://scripts/combat/combat_projectile.gd")
const GuardianData = preload("res://scripts/data/guardian_data.gd")
const GuardianSystem = preload("res://scripts/systems/guardian_system.gd")
const ClericData = preload("res://scripts/data/cleric_data.gd")
const ClericSystem = preload("res://scripts/systems/cleric_system.gd")
const RangerData = preload("res://scripts/data/ranger_data.gd")
const RangerSystem = preload("res://scripts/systems/ranger_system.gd")
const AbilitySlotSystem = preload("res://scripts/systems/ability_slot_system.gd")
const PercentageHealthDamageSystem = preload("res://scripts/systems/percentage_health_damage_system.gd")
const ASHWOOD_COMBAT_BACKGROUND = preload("res://assets/generated/ashwood_combat_background.png")

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
const TESTING_MAX_HERO_LEVEL := CombatSystem.LEVEL_CAP
const TUTORIAL_MOVEMENT_REACH_RADIUS := 72.0
const OBJECTIVE_THREAT_TARGET := -2
const CHALLENGE_TAUNT_DURATION := 3.0
const TESTING_DUMMY_RESPAWN_TIME := 5.0
const TESTING_DUMMY_REGEN_DELAY := 2.5
const TESTING_DUMMY_REGEN_RATE := 0.10

# Transient UI coordination belongs beside the UI/input methods that consume it.
# Declaring it here also keeps Godot hot reloads from compiling AppCore against a
# stale cached AppState layout while several descendant scripts are reloading.
var hero_roster_scroll_positions:Dictionary = {}
var victory_talent_queue:Array = []
var victory_talent_choice_index := 0
var victory_talent_overlay:Control = null
var victory_talent_prompt_handled := false
var roster_party_press_active := false
var roster_party_press_index := -1
var roster_party_press_origin := ""
var roster_party_press_time := 0.0
var roster_party_press_start := Vector2.ZERO

const ROSTER_PARTY_HOLD_DURATION := 0.24

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
	state.selected_team=TeamManager.sanitize_team(state.selected_team,state.heroes)
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

func hero_is_on_active_team(idx:int) -> bool:
	return TeamManager.has_member(state.selected_team,idx)

func toggle_active_team_from_roster(idx:int) -> void:
	var was_active:=hero_is_on_active_team(idx)
	var next_active_team:Array=TeamManager.toggle_member(state.selected_team,idx,state.heroes)
	if not was_active and next_active_team==state.selected_team:
		flash("Only one hero of each class may join a party." if state.selected_team.size()<4 else "Party is full.")
		return
	state.selected_team=next_active_team
	persist_current_team()
	show_roster()

func begin_roster_party_press(idx:int,origin:String,pointer_position:Vector2)->void:
	roster_party_press_active=true;roster_party_press_index=idx;roster_party_press_origin=origin;roster_party_press_time=0.0;roster_party_press_start=pointer_position

func update_roster_party_press(delta:float)->void:
	if not roster_party_press_active or screen!="roster" or team_dragging:return
	roster_party_press_time+=delta
	if roster_party_press_time>=ROSTER_PARTY_HOLD_DURATION:start_team_drag(roster_party_press_index,roster_party_press_origin)

func finish_roster_party_press(pointer_position:Vector2)->void:
	if not roster_party_press_active:return
	var hero_index:=roster_party_press_index
	roster_party_press_active=false;roster_party_press_index=-1;roster_party_press_origin="";roster_party_press_time=0.0
	if team_dragging:end_team_drag(pointer_position)
	else:toggle_active_team_from_roster(hero_index)

func open_victory_talent_choices()->bool:
	return false

func complete_victory_sequence_navigation()->void:
	victory_sequence=false
	if current_ashwood_encounter!="":show_ashwood_victory()
	else:show_zone_map(dungeon_id)

func attempt_victory_continue()->void:
	if current_ashwood_encounter!="" and victory_timer<1.6:victory_timer=1.6;queue_redraw();return
	if open_victory_talent_choices():return
	complete_victory_sequence_navigation()

func move_to_active_team(idx:int,target_slot:int=-1) -> void:
	if team_has_member(idx):
		if target_slot<0:return
		state.selected_team=TeamManager.place_member(state.selected_team,idx,target_slot,state.heroes)
		persist_current_team()
		return
	if state.selected_team.size() >= 4:
		flash("Active party is full.")
		return
	if not TeamManager.can_add_member(state.selected_team,idx,state.heroes):
		flash("Only one hero of each class may join a party.")
		return
	state.selected_team=TeamManager.add_member(state.selected_team,idx,state.heroes) if target_slot<0 else TeamManager.place_member(state.selected_team,idx,target_slot,state.heroes)
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
	var preview_size:=Vector2(58,48) if screen=="roster" else Vector2(180,100) if origin=="active" else Vector2(150,74)
	team_drag_preview=Button.new(); team_drag_preview.text=role_glyph(str(state.heroes[idx].get("class",""))) if screen=="roster" else team_card_text(idx);team_drag_preview.add_theme_font_size_override("font_size",18 if screen=="roster" else 14);team_drag_preview.size=preview_size; team_drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE; team_drag_preview.modulate=Color(1,1,1,.82); team_drag_preview.position=get_viewport().get_mouse_position()-preview_size*.5; ui.add_child(team_drag_preview);team_drag_preview.size=preview_size
	queue_redraw()

func _input(event:InputEvent) -> void:
	if victory_talent_overlay!=null and is_instance_valid(victory_talent_overlay):return
	if item_card_overlay!=null:
		if event.is_action_pressed("ui_cancel"):
			if not item_overlay_confirmation_active:navigate_item_overlay_back()
			get_viewport().set_input_as_handled();return
		if item_overlay_mode in ["equipment_carousel","hero_carousel"]:
			if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
				if event.pressed and not item_carousel_transitioning:item_carousel_swiping=true;item_carousel_swipe_start=event.position;item_carousel_drag_offset=0.0
				elif item_carousel_swiping:
					var mouse_swipe:float=event.position.x-item_carousel_swipe_start.x;item_carousel_swiping=false;finish_item_carousel_drag(mouse_swipe)
					if absf(mouse_swipe)>=55.0:get_viewport().set_input_as_handled();return
			elif event is InputEventMouseMotion and item_carousel_swiping:update_item_carousel_drag(event.position.x-item_carousel_swipe_start.x)
			elif event is InputEventScreenTouch:
				if event.pressed and not item_carousel_transitioning:item_carousel_swiping=true;item_carousel_swipe_start=event.position;item_carousel_drag_offset=0.0
				elif item_carousel_swiping:
					var touch_swipe:float=event.position.x-item_carousel_swipe_start.x;item_carousel_swiping=false;finish_item_carousel_drag(touch_swipe)
					if absf(touch_swipe)>=55.0:get_viewport().set_input_as_handled();return
			elif event is InputEventScreenDrag and item_carousel_swiping:update_item_carousel_drag(event.position.x-item_carousel_swipe_start.x)
	if screen=="vault" and vault_press_active:
		if event is InputEventMouseMotion:
			vault_pointer_position=event.position
			if not vault_dragging and vault_pointer_position.distance_to(vault_press_start)>=InventorySystem.DRAG_THRESHOLD:begin_vault_drag()
			update_vault_drag_visual()
		elif event is InputEventScreenDrag:
			vault_pointer_position=event.position
			if not vault_dragging and vault_pointer_position.distance_to(vault_press_start)>=InventorySystem.DRAG_THRESHOLD:begin_vault_drag()
			update_vault_drag_visual()
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
			finish_vault_pointer(event.position);get_viewport().set_input_as_handled();return
		elif event is InputEventScreenTouch and not event.pressed:
			finish_vault_pointer(event.position);get_viewport().set_input_as_handled();return
	if screen=="ashwood_victory" and ashwood_victory_stage=="consequence" and ashwood_consequence_phase>0 and ashwood_consequence_phase<=ashwood_consequence_lines.size() and (event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed or event is InputEventScreenTouch and event.pressed):
		advance_ashwood_consequence()
		get_viewport().set_input_as_handled()
		return
	if victory_sequence and victory_phase>=5 and (event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed or event is InputEventScreenTouch and event.pressed):
		attempt_victory_continue()
		get_viewport().set_input_as_handled()
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
	if screen=="roster" and roster_party_press_active:
		if event is InputEventMouseMotion and team_dragging and team_drag_preview!=null:team_drag_preview.position=event.position-team_drag_preview.size*.5
		elif event is InputEventScreenDrag and team_dragging and team_drag_preview!=null:team_drag_preview.position=event.position-team_drag_preview.size*.5
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:finish_roster_party_press(event.position);get_viewport().set_input_as_handled();return
		elif event is InputEventScreenTouch and not event.pressed:finish_roster_party_press(event.position);get_viewport().set_input_as_handled();return
	if team_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_team_drag(event.position)
	elif team_dragging and event is InputEventMouseMotion and team_drag_preview!=null:
		team_drag_preview.position=event.position-team_drag_preview.size*.5

func hero_matches(idx:int) -> bool:
	return RosterManager.hero_matches(state.heroes[idx],CLASSES,hero_search,hero_role_filter,hero_class_filter,hero_type_filter)

func sorted_hero_indices() -> Array:
	return RosterManager.sorted_indices(state.heroes,CLASSES,hero_search,hero_role_filter,hero_class_filter,hero_type_filter,roster_sort,roster_descending)

func apply_sharp_compact_style(control:Control) -> void:
	if control is LineEdit:
		control.add_theme_stylebox_override("normal",ui_box(Color("182334"),4,Color("35445a"),1))
		control.add_theme_stylebox_override("focus",ui_box(Color("182334"),4,C_GOLD,2))
	elif control is Button:
		control.add_theme_stylebox_override("normal",ui_box(Color("202d42"),4,Color("35445a"),1))
		control.add_theme_stylebox_override("hover",ui_box(Color("293a53"),4,C_GOLD,1))
		control.add_theme_stylebox_override("pressed",ui_box(Color("172131"),4,C_GOLD,2))
		control.add_theme_stylebox_override("focus",ui_box(Color.TRANSPARENT,4,C_GOLD,1))

func filter_bar(refresh:Callable, include_sort:bool=false, compact:bool=false, narrow:bool=false) -> HBoxContainer:
	var bar:=HBoxContainer.new(); bar.add_theme_constant_override("separation",8)
	var control_height:=32.0 if compact else 42.0
	var search:=LineEdit.new(); search.placeholder_text="Search"; search.text=hero_search; search.custom_minimum_size=Vector2(190 if narrow else (210 if compact else 250),control_height); search.text_changed.connect(func(value): hero_search=value); search.text_submitted.connect(func(_value): refresh.call());if compact:apply_sharp_compact_style(search);bar.add_child(search)
	var roles:=OptionButton.new(); roles.custom_minimum_size=Vector2(120 if narrow else (132 if compact else 150),control_height);if compact:apply_sharp_compact_style(roles)
	for value in ["All roles","Tank","Healer","DPS"]: roles.add_item(value)
	roles.select(["All roles","Tank","Healer","DPS"].find(hero_role_filter)); roles.item_selected.connect(func(i): hero_role_filter=roles.get_item_text(i); refresh.call()); bar.add_child(roles)
	var classes:=OptionButton.new(); classes.custom_minimum_size=Vector2(132 if narrow else (145 if compact else 165),control_height);if compact:apply_sharp_compact_style(classes)
	var class_values=["All classes","Guardian","Cleric","Rogue","Ranger","Mage","Warlock"]
	for value in class_values: classes.add_item(value)
	classes.select(class_values.find(hero_class_filter)); classes.item_selected.connect(func(i): hero_class_filter=classes.get_item_text(i); refresh.call()); bar.add_child(classes)
	var types:=OptionButton.new(); types.custom_minimum_size=Vector2(155 if narrow else (174 if compact else 155),control_height);if compact:apply_sharp_compact_style(types)
	var type_values=["All Heroes","Standard Heroes","Special Heroes"]
	for value in type_values:types.add_item(value)
	types.select(type_values.find(hero_type_filter));types.item_selected.connect(func(i):hero_type_filter=types.get_item_text(i);refresh.call());bar.add_child(types)
	if include_sort:
		var sorts:=OptionButton.new(); sorts.custom_minimum_size=Vector2(112 if narrow else (125 if compact else 145),control_height);if compact:apply_sharp_compact_style(sorts)
		for value in ["Name","Role","Class","Level"]: sorts.add_item(value)
		sorts.select(["Name","Role","Class","Level"].find(roster_sort)); sorts.item_selected.connect(func(i): roster_sort=sorts.get_item_text(i); refresh.call()); bar.add_child(sorts)

		var direction:=button("↓" if roster_descending else "↑",func(): roster_descending=not roster_descending; refresh.call(),54);direction.custom_minimum_size.y=control_height;if compact:apply_sharp_compact_style(direction);bar.add_child(direction)
	return bar

func active_team_drop_slot(mouse_pos:Vector2) -> int:
	if team_active_row==null:return -1
	for slot_index in team_active_row.get_child_count():
		var slot_control:=team_active_row.get_child(slot_index) as Control
		if slot_control!=null and Rect2(slot_control.global_position,slot_control.size).has_point(mouse_pos):return slot_index
	return -1

func end_team_drag(mouse_pos:Vector2) -> void:
	if not team_dragging:
		return
	var dropped_on_active := team_active_zone != null and mouse_pos.x >= team_active_zone.global_position.x and mouse_pos.x <= team_active_zone.global_position.x + team_active_zone.size.x and mouse_pos.y >= team_active_zone.global_position.y and mouse_pos.y <= team_active_zone.global_position.y + team_active_zone.size.y
	var dropped_on_reserve := team_reserve_zone != null and mouse_pos.x >= team_reserve_zone.global_position.x and mouse_pos.x <= team_reserve_zone.global_position.x + team_reserve_zone.size.x and mouse_pos.y >= team_reserve_zone.global_position.y and mouse_pos.y <= team_reserve_zone.global_position.y + team_reserve_zone.size.y
	if dropped_on_active:
		move_to_active_team(team_drag_index,active_team_drop_slot(mouse_pos))
	elif dropped_on_reserve:
		move_to_reserve(team_drag_index)
	team_dragging = false
	team_drag_index = -1
	team_drag_origin = ""
	if team_drag_preview!=null: team_drag_preview.queue_free(); team_drag_preview=null
	save_game()
	if screen=="roster":show_roster()
	else:show_team()

func begin_vault_press(entry_id:String,pointer_position:Vector2)->void:
	if item_card_overlay!=null:return
	vault_press_active=true;vault_press_entry_id=entry_id;vault_press_time=0.0;vault_press_start=pointer_position;vault_pointer_position=pointer_position;vault_dragging=false;vault_page_hover=-1;vault_page_hover_time=0.0

func vault_slot_input(event:InputEvent,entry_id:String,slot_control:Control)->void:
	if entry_id=="":return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:begin_vault_press(entry_id,slot_control.global_position+event.position)
	elif event is InputEventScreenTouch and event.pressed:begin_vault_press(entry_id,slot_control.global_position+event.position)

func begin_vault_drag()->void:
	if not vault_press_active or vault_dragging:return
	var entry:=InventorySystem.entry_by_id(state,vault_press_entry_id)
	if entry.is_empty():return
	vault_dragging=true
	var source_flat:=InventorySystem.flat_position(entry)
	if vault_slot_controls.has(source_flat):vault_slot_controls[source_flat].modulate=Color(1,1,1,.28)
	var preview:=Label.new();preview.text=InventorySystem.fallback_glyph(str(entry.get("fallback_icon_type",entry.get("slot","item"))));preview.size=Vector2(92,92);preview.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;preview.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;preview.add_theme_font_size_override("font_size",18);preview.add_theme_color_override("font_color",Color("ffffff"));preview.add_theme_stylebox_override("normal",ui_box(Color(0.08,0.12,0.19,.88),8,C_GOLD,2));preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview.scale=Vector2(1.08,1.08);ui.add_child(preview);vault_drag_preview=preview
	update_vault_drag_visual()

func update_vault_drag_visual()->void:
	if not vault_dragging or vault_drag_preview==null:return
	vault_drag_preview.position=vault_pointer_position-vault_drag_preview.size*.5
	var hovered_page:=-1
	for page_index in vault_page_controls:
		var control:Control=vault_page_controls[page_index]
		if is_instance_valid(control) and Rect2(control.global_position,control.size).has_point(vault_pointer_position):hovered_page=int(page_index);break
	if hovered_page!=vault_page:
		if hovered_page==vault_page_hover:vault_page_hover_time+=get_process_delta_time()
		else:vault_page_hover=hovered_page;vault_page_hover_time=0.0
		if hovered_page>=0 and vault_page_hover_time>=InventorySystem.PAGE_HOVER_DURATION:
			var held_entry_id:=vault_press_entry_id;var held_pointer:=vault_pointer_position
			cancel_vault_input();vault_page=hovered_page;show_vault();begin_vault_press(held_entry_id,held_pointer);begin_vault_drag()
	else:vault_page_hover=-1;vault_page_hover_time=0.0

func finish_vault_pointer(pointer_position:Vector2)->void:
	if not vault_press_active:return
	var entry_id:=vault_press_entry_id;var was_dragging:=vault_dragging
	if was_dragging:
		var target_slot:=-1
		for flat_index in vault_slot_controls:
			var control:Control=vault_slot_controls[flat_index]
			if is_instance_valid(control) and Rect2(control.global_position,control.size).has_point(pointer_position):target_slot=int(flat_index);break
		if target_slot>=0:
			InventorySystem.move_entry(state,entry_id,target_slot/InventorySystem.STORAGE_PAGE_SIZE,target_slot%InventorySystem.STORAGE_PAGE_SIZE);save_game()
			if vault_drag_preview!=null:
				var target_control:Control=vault_slot_controls[target_slot];var target_position:=target_control.global_position+(target_control.size-vault_drag_preview.size)*.5;vault_press_active=false;vault_dragging=false;var tween:=create_tween();tween.tween_property(vault_drag_preview,"position",target_position,.12);tween.parallel().tween_property(vault_drag_preview,"scale",Vector2.ONE,.12);tween.finished.connect(func():cancel_vault_input();show_vault());return
	cancel_vault_input()
	if was_dragging:show_vault()
	else:open_item_card(entry_id,"vault")

func cancel_vault_input()->void:
	vault_press_active=false;vault_press_entry_id="";vault_press_time=0.0;vault_dragging=false;vault_page_hover=-1;vault_page_hover_time=0.0
	if vault_drag_preview!=null and is_instance_valid(vault_drag_preview):vault_drag_preview.queue_free()
	vault_drag_preview=null


func team_card_text(idx:int) -> String:
	var h = state.heroes[idx]
	return "%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]),h.name,h["class"],h["level"]]

func role_glyph(hero_class:String) -> String:
	match hero_class:
		"Guardian": return "◈"
		"Cleric": return "✚"
		"Mage": return "✦━"
		_: return "➶"

func toggle_test_special_hero(idx:int) -> void:
	if not is_testing_save():return
	var hero=state.heroes[idx];var make_special=not bool(hero.get("is_special_hero",false));hero["is_special_hero"]=make_special;hero["identity_type"]="special" if make_special else "standard";hero["editable_name"]=not make_special;hero["editable_appearance"]=not make_special;hero["can_edit_name"]=not make_special;hero["can_edit_appearance"]=not make_special;hero["member_type"]="special_hero" if make_special else "founding_recruit";hero["prestige_rank"]=1 if make_special else 0;hero["prestige_reward_floor_rank"]=int(hero.prestige_rank) if make_special else 0;hero["legacy_rank"]=hero.prestige_rank;save_game();show_roster()

func set_testing_hero_level(idx:int,value:float) -> void:
	if not is_testing_save() or idx<0 or idx>=state.heroes.size():return
	var hero:Dictionary=state.heroes[idx]
	hero.level=clampi(int(round(value)),1,TESTING_MAX_HERO_LEVEL)
	hero.xp=clampi(int(hero.get("xp",0)),0,int(hero.level)*100-1)
	state.class_talent_discovery=TalentSystem.record_class_discovery(state.class_talent_discovery,str(hero.class_id),30 if is_testing_save() else int(hero.level))
	save_game()
	show_roster()

func reset_testing_ashwood_story() -> void:
	if not is_testing_save():return
	var preserved_next_item_id:int=int(state.zone0.get("next_item_id",1))
	state.zone0=AshwoodManager.default_progress()
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

func make_team_card(idx:int, origin:String, slot_index:int=-1) -> Button:
	var b := Button.new()
	var active_card:=origin=="active"
	b.custom_minimum_size = Vector2(180,100) if active_card else Vector2(150,74)
	b.text = team_card_text(idx)
	b.add_theme_font_size_override("font_size",16 if active_card else 13)
	b.add_theme_stylebox_override("normal",ui_box(Color("202d42"),4,Color("35445a"),1))
	b.add_theme_stylebox_override("hover",ui_box(Color("293a53"),4,CLASSES[state.heroes[idx]["class"]].color,1))
	if bool(state.heroes[idx].get("is_special_hero",false)):
		b.add_theme_stylebox_override("normal",ui_box(Color("2b3040"),4,C_GOLD,2))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	if active_card and slot_index>=0:
		var formation_names:=["Front","Top","Bottom","Back"]
		var hero:Dictionary=state.heroes[idx]
		b.text="%d  %s\n%s  %s\n%s  •  Level %d"%[slot_index+1,formation_names[clampi(slot_index,0,3)].to_upper(),role_glyph(hero["class"]),hero.name,hero["class"],hero.level]
		b.tooltip_text="Party slot %d — %s position. Drag onto another party slot to reorder."%[slot_index+1,formation_names[clampi(slot_index,0,3)]]
	if team_has_member(idx):
		b.add_theme_color_override("font_color", CLASSES[state.heroes[idx]["class"]].color)
		b.add_theme_stylebox_override("normal",ui_box(Color("24364b"),4,CLASSES[state.heroes[idx]["class"]].color,2))
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
	vault_slot_controls.clear();vault_page_controls.clear()
	item_card_overlay=null
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

func request_battle_menu()->void:
	InventorySystem.ensure_storage_state(state)
	if InventorySystem.empty_slots(state)>0:show_dungeons();return
	var dialog:=ConfirmationDialog.new();dialog.name="VaultFullBattleWarning";dialog.title="VAULT FULL";dialog.dialog_text="The Guild Vault has no empty slots for new items.\n\nStackable materials may still be collected when an existing stack has room, but equipment and new material stacks cannot be stored.";dialog.ok_button_text="Continue Anyway";dialog.cancel_button_text="Cancel"
	dialog.add_button("Manage Vault",false,"manage_vault");dialog.custom_action.connect(func(action):if action=="manage_vault":dialog.hide();show_vault());dialog.confirmed.connect(show_dungeons);ui.add_child(dialog);dialog.popup_centered(Vector2i(570,300))

func show_hall() -> void:
	screen="hall"; var root=base_screen("Guild Hall")
	var guild_status:=HBoxContainer.new();guild_status.custom_minimum_size.y=48;guild_status.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;guild_status.add_theme_constant_override("separation",18);root.add_child(guild_status)
	var guild_name_label:=label(state.guild_name,20,C_TEXT);guild_name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;guild_name_label.autowrap_mode=TextServer.AUTOWRAP_OFF;guild_name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;guild_status.add_child(guild_name_label)
	var prestige_label:=label("Guild Prestige  •  Rank %d"%state.guild_prestige_rank,17,C_GOLD);prestige_label.custom_minimum_size.x=280;prestige_label.autowrap_mode=TextServer.AUTOWRAP_OFF;prestige_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;prestige_label.tooltip_text="Guild Prestige represents the guild's reputation, accomplishments, and influence in the world.";guild_status.add_child(prestige_label)
	var renown_label:=label("Renown  %d"%state.guild_renown,17,C_MUTED);renown_label.custom_minimum_size.x=140;renown_label.autowrap_mode=TextServer.AUTOWRAP_OFF;renown_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;guild_status.add_child(renown_label)
	var battle:=Button.new(); battle.text="BATTLE"; battle.custom_minimum_size=Vector2(1170,120); battle.add_theme_font_size_override("font_size",34); battle.add_theme_color_override("font_color",C_GOLD); battle.pressed.connect(request_battle_menu); root.add_child(battle)
	var destinations:=GridContainer.new(); destinations.columns=4; destinations.add_theme_constant_override("h_separation",18); destinations.add_theme_constant_override("v_separation",18); destinations.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; root.add_child(destinations)
	var all_systems:=bool(state.get("major_systems_unlocked",false))
	var zone0:Dictionary=state.get("zone0",AshwoodManager.default_progress())
	destinations.add_child(hub_button("Command Table","",func():open_guild_page("command",show_command_table),not all_systems))
	destinations.add_child(hub_button("Heroes","",func():open_guild_page("heroes",show_roster),not (all_systems or bool(state.tutorial_complete) or bool(zone0.heroes_unlocked))))
	destinations.add_child(hub_button("Party","",func():open_guild_page("party",show_team),not (all_systems or bool(zone0.party_management_unlocked))))
	var vault_button:=hub_button("Vault","",func():open_guild_page("vault",show_vault),not (all_systems or bool(zone0.vault_unlocked)))
	var vault_warning:=InventorySystem.warning_state(state)
	if vault_warning!="normal":
		vault_button.add_theme_color_override("font_color",C_RED);vault_button.add_theme_stylebox_override("normal",ui_box(Color("35212c"),8,C_RED,2 if vault_warning=="warning" else 4));vault_button.tooltip_text="Item Storage is full" if vault_warning=="critical" else "Item Storage is becoming full"
	destinations.add_child(vault_button)
	destinations.add_child(hub_button("Tavern","",func():open_guild_page("tavern",func():flash("The Tavern is not open yet.")),not all_systems))
	destinations.add_child(hub_button("Merchant","",func():open_guild_page("merchant",show_market),not all_systems))
	destinations.add_child(hub_button("Workshop","",func():open_guild_page("workshop",show_crafting),not all_systems))
	var settings_button:=Button.new();settings_button.text="⚙";settings_button.tooltip_text="Casting Settings";settings_button.position=Vector2(24,648);settings_button.size=Vector2(52,52);settings_button.add_theme_font_size_override("font_size",25);settings_button.pressed.connect(show_settings);ui.add_child(settings_button)

# Screen contracts implemented by later layers in the application stack.
func open_item_card(_entry_id:String,_origin:String="vault",_comparison:Dictionary={},_back_action:Callable=Callable())->void:pass
func compact_button(_text:String,_callback:Callable,_width:float=100)->Button:return null
func navigate_item_overlay_back()->void:pass
func shift_active_item_carousel(_direction:int)->void:pass
func update_item_carousel_drag(_offset:float)->void:pass
func finish_item_carousel_drag(_offset:float)->void:pass
func close_item_overlay()->void:pass
func show_roster()->void:pass
func show_team()->void:pass
func show_dungeons()->void:pass
func show_zone_map(_zone:int)->void:pass
func show_command_table()->void:pass
func show_market()->void:pass
func show_crafting()->void:pass
func show_vault()->void:pass

# Combat/story contracts implemented by the runtime layers.
func start_battle(_id:int,_node:int=0,_party_override:Array=[])->void:pass
func start_testing_zone()->void:pass
func start_ashwood_battle(_encounter_key:String)->void:pass
func show_ashwood_consequence(_text_value:String)->void:pass
func start_tutorial()->void:pass
func ashwood_story_is_pending(_encounter_key:String)->bool:return false
func resume_pending_ashwood_story(_encounter_key:String)->void:pass
func show_ashwood_victory()->void:pass
func advance_ashwood_consequence()->void:pass
func show_pending_special_choice()->void:pass
func flash(_msg:String)->void:pass
