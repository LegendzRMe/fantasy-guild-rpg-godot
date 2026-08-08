extends "res://scripts/runtime/app_core.gd"


func team_has_member(idx: int) -> bool:
	return TeamManager.has_member(state.selected_team, idx)


func hero_is_on_active_team(idx: int) -> bool:
	return TeamManager.has_member(state.selected_team, idx)


func toggle_active_team_from_roster(idx: int) -> void:
	var was_active := hero_is_on_active_team(idx)
	if not was_active:
		var availability:=TavernFacilitySystem.member_status(state,str(state.heroes[idx].hero_id))
		if not bool(availability.available):flash(str(availability.label));return
	var next_active_team: Array = TeamManager.toggle_member(state.selected_team, idx, state.heroes)
	if not was_active and next_active_team == state.selected_team:
		flash("Only one hero of each class may join a party." if state.selected_team.size() < 4 else "Party is full.")
		return
	state.selected_team = next_active_team
	persist_current_team()
	show_roster()


func begin_roster_party_press(idx: int, origin: String, pointer_position: Vector2) -> void:
	roster_party_press_active = true
	roster_party_press_index = idx
	roster_party_press_origin = origin
	roster_party_press_time = 0.0
	roster_party_press_start = pointer_position


func update_roster_party_press(delta: float) -> void:
	if not roster_party_press_active or screen != "roster" or team_dragging:
		return
	roster_party_press_time += delta
	if roster_party_press_time >= ROSTER_PARTY_HOLD_DURATION:
		start_team_drag(roster_party_press_index, roster_party_press_origin)


func finish_roster_party_press(pointer_position: Vector2) -> void:
	if not roster_party_press_active:
		return
	var hero_index := roster_party_press_index
	roster_party_press_active = false
	roster_party_press_index = -1
	roster_party_press_origin = ""
	roster_party_press_time = 0.0
	if team_dragging:
		end_team_drag(pointer_position)
	else:
		toggle_active_team_from_roster(hero_index)


func open_victory_talent_choices() -> bool:
	return false


func complete_victory_sequence_navigation() -> void:
	victory_sequence = false
	if current_ashwood_encounter != "":
		show_ashwood_victory()
	else:
		show_zone_map(dungeon_id)


func attempt_victory_continue() -> void:
	if current_ashwood_encounter != "" and victory_timer < 1.6:
		victory_timer = 1.6
		queue_redraw()
		return
	if open_victory_talent_choices():
		return
	complete_victory_sequence_navigation()


func move_to_active_team(idx: int, target_slot: int = -1) -> void:
	if team_has_member(idx):
		if target_slot < 0:
			return
		state.selected_team = TeamManager.place_member(state.selected_team, idx, target_slot, state.heroes)
		persist_current_team()
		return
	if state.selected_team.size() >= 4:
		flash("Active party is full.")
		return
	var availability:=TavernFacilitySystem.member_status(state,str(state.heroes[idx].hero_id))
	if not bool(availability.available):flash(str(availability.label));return
	if not TeamManager.can_add_member(state.selected_team, idx, state.heroes):
		flash("Only one hero of each class may join a party.")
		return
	state.selected_team = (
		TeamManager.add_member(state.selected_team, idx, state.heroes)
		if target_slot < 0
		else TeamManager.place_member(state.selected_team, idx, target_slot, state.heroes)
	)
	persist_current_team()


func move_to_reserve(idx: int) -> void:
	if not team_has_member(idx):
		return
	state.selected_team = TeamManager.remove_member(state.selected_team, idx)
	persist_current_team()


func start_team_drag(idx: int, origin: String) -> void:
	team_swiping = false
	team_dragging = true
	team_drag_index = idx
	team_drag_origin = origin
	var preview_size := Vector2(58, 48) if screen == "roster" else Vector2(180, 100) if origin == "active" else Vector2(150, 74)
	team_drag_preview = Button.new()
	team_drag_preview.text = (role_glyph(str(state.heroes[idx].get("class", ""))) if screen == "roster" else team_card_text(idx))
	team_drag_preview.add_theme_font_size_override("font_size", 18 if screen == "roster" else 14)
	team_drag_preview.size = preview_size
	team_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	team_drag_preview.modulate = Color(1, 1, 1, .82)
	team_drag_preview.position = get_viewport().get_mouse_position() - preview_size * .5
	ui.add_child(team_drag_preview)
	team_drag_preview.size = preview_size
	queue_redraw()


func _input(event: InputEvent) -> void:
	if victory_talent_overlay != null and is_instance_valid(victory_talent_overlay):
		return
	if screen == "tavern" and bool(state.get("tavern_management",{}).get("manual_cooking",{}).get("active",false)) and event.is_action_pressed("ui_accept"):
		if has_method("stop_tavern_manual_cooking"):
			call("stop_tavern_manual_cooking")
		get_viewport().set_input_as_handled()
		return
	if screen == "hall" and handle_guild_hall_input(event):
		return
	if handle_item_overlay_input(event):
		return
	if handle_vault_pointer_input(event):
		return
	if handle_progression_continue_input(event):
		return
	handle_team_page_input(event)
	if handle_roster_party_input(event):
		return
	handle_team_drag_input(event)


func handle_item_overlay_input(event: InputEvent) -> bool:
	if item_card_overlay == null:
		return false
	if event.is_action_pressed("ui_cancel"):
		if not item_overlay_confirmation_active:
			navigate_item_overlay_back()
		get_viewport().set_input_as_handled()
		return true
	if item_overlay_mode not in ["equipment_carousel", "hero_carousel"]:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not item_carousel_transitioning:
			item_carousel_swiping = true
			item_carousel_swipe_start = event.position
			item_carousel_drag_offset = 0.0
		elif item_carousel_swiping:
			var mouse_swipe: float = event.position.x - item_carousel_swipe_start.x
			item_carousel_swiping = false
			finish_item_carousel_drag(mouse_swipe)
			if absf(mouse_swipe) >= 55.0:
				get_viewport().set_input_as_handled()
				return true
	elif event is InputEventMouseMotion and item_carousel_swiping:
		update_item_carousel_drag(event.position.x - item_carousel_swipe_start.x)
	elif event is InputEventScreenTouch:
		if event.pressed and not item_carousel_transitioning:
			item_carousel_swiping = true
			item_carousel_swipe_start = event.position
			item_carousel_drag_offset = 0.0
		elif item_carousel_swiping:
			var touch_swipe: float = event.position.x - item_carousel_swipe_start.x
			item_carousel_swiping = false
			finish_item_carousel_drag(touch_swipe)
			if absf(touch_swipe) >= 55.0:
				get_viewport().set_input_as_handled()
				return true
	elif event is InputEventScreenDrag and item_carousel_swiping:
		update_item_carousel_drag(event.position.x - item_carousel_swipe_start.x)
	return false


func handle_vault_pointer_input(event: InputEvent) -> bool:
	if screen != "vault" or not vault_press_active:
		return false
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		vault_pointer_position = event.position
		if not vault_dragging and (vault_pointer_position.distance_to(vault_press_start) >= InventorySystem.DRAG_THRESHOLD):
			begin_vault_drag()
		update_vault_drag_visual()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		finish_vault_pointer(event.position)
		get_viewport().set_input_as_handled()
		return true
	elif event is InputEventScreenTouch and not event.pressed:
		finish_vault_pointer(event.position)
		get_viewport().set_input_as_handled()
		return true
	return false


func handle_progression_continue_input(event: InputEvent) -> bool:
	var pressed: bool = (
		(event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	)
	if not pressed:
		return false
	if (
		screen == "ashwood_victory"
		and ashwood_victory_stage == "consequence"
		and ashwood_consequence_phase > 0
		and ashwood_consequence_phase <= ashwood_consequence_lines.size()
	):
		advance_ashwood_consequence()
	elif victory_sequence and victory_phase >= 5:
		attempt_victory_continue()
	else:
		return false
	get_viewport().set_input_as_handled()
	return true


func handle_team_page_input(event: InputEvent) -> void:
	if screen == "team" and event is InputEventKey and event.pressed and not (get_viewport().gui_get_focus_owner() is LineEdit):
		if event.keycode == KEY_A:
			team_roster_page = max(0, team_roster_page - 1)
			show_team()
		elif event.keycode == KEY_D:
			team_roster_page += 1
			show_team()
	if screen == "team" and team_reserve_zone != null:
		if event is InputEventScreenTouch:
			if event.pressed and Rect2(team_reserve_zone.global_position, team_reserve_zone.size).has_point(event.position):
				team_swipe_start = event.position
				team_swiping = true
			elif not event.pressed and team_swiping:
				var dx = event.position.x - team_swipe_start.x
				if abs(dx) > 55:
					team_roster_page += (-1 if dx > 0 else 1)
				team_swiping = false
				show_team()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Rect2(team_reserve_zone.global_position, team_reserve_zone.size).has_point(event.position):
				team_swipe_start = event.position
				team_swiping = true
			elif not event.pressed and team_swiping and not team_dragging:
				var dx = event.position.x - team_swipe_start.x
				if abs(dx) > 55:
					team_roster_page += (-1 if dx > 0 else 1)
				team_swiping = false
				show_team()


func handle_roster_party_input(event: InputEvent) -> bool:
	# Mouse release is usually received by the drop zone, not the card that began
	# the drag, so finish team drags at the viewport level.
	if screen == "roster" and roster_party_press_active:
		if event is InputEventMouseMotion and team_dragging and team_drag_preview != null:
			team_drag_preview.position = event.position - team_drag_preview.size * .5
		elif event is InputEventScreenDrag and team_dragging and team_drag_preview != null:
			team_drag_preview.position = event.position - team_drag_preview.size * .5
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			finish_roster_party_press(event.position)
			get_viewport().set_input_as_handled()
			return true
		elif event is InputEventScreenTouch and not event.pressed:
			finish_roster_party_press(event.position)
			get_viewport().set_input_as_handled()
			return true
	return false


func handle_team_drag_input(event: InputEvent) -> void:
	if team_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_team_drag(event.position)
	elif team_dragging and event is InputEventMouseMotion and team_drag_preview != null:
		team_drag_preview.position = event.position - team_drag_preview.size * .5


func hero_matches(idx: int) -> bool:
	return RosterManager.hero_matches(state.heroes[idx], CLASSES, hero_search, hero_role_filter, hero_class_filter, hero_type_filter)


func sorted_hero_indices() -> Array:
	return RosterManager.sorted_indices(
		state.heroes, CLASSES, hero_search, hero_role_filter, hero_class_filter, hero_type_filter, roster_sort, roster_descending
	)


func apply_sharp_compact_style(control: Control) -> void:
	if control is LineEdit:
		control.add_theme_stylebox_override("normal", ui_box(Color("182334"), 4, Color("35445a"), 1))
		control.add_theme_stylebox_override("focus", ui_box(Color("182334"), 4, C_GOLD, 2))
	elif control is Button:
		control.add_theme_stylebox_override("normal", ui_box(Color("202d42"), 4, Color("35445a"), 1))
		control.add_theme_stylebox_override("hover", ui_box(Color("293a53"), 4, C_GOLD, 1))
		control.add_theme_stylebox_override("pressed", ui_box(Color("172131"), 4, C_GOLD, 2))
		control.add_theme_stylebox_override("focus", ui_box(Color.TRANSPARENT, 4, C_GOLD, 1))


func filter_bar(refresh: Callable, include_sort: bool = false, compact: bool = false, narrow: bool = false) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	var control_height := 32.0 if compact else 42.0
	var search := LineEdit.new()
	search.placeholder_text = "Search"
	search.text = hero_search
	search.custom_minimum_size = Vector2(190 if narrow else (210 if compact else 250), control_height)
	search.text_changed.connect(func(value): hero_search = value)
	search.text_submitted.connect(func(_value): refresh.call())
	if compact:
		apply_sharp_compact_style(search)
	bar.add_child(search)
	var roles := OptionButton.new()
	roles.custom_minimum_size = Vector2(120 if narrow else (132 if compact else 150), control_height)
	if compact:
		apply_sharp_compact_style(roles)
	for value in ["All roles", "Tank", "Healer", "DPS"]:
		roles.add_item(value)
	roles.select(["All roles", "Tank", "Healer", "DPS"].find(hero_role_filter))
	roles.item_selected.connect(
		func(i):
			hero_role_filter = roles.get_item_text(i)
			refresh.call()
	)
	bar.add_child(roles)
	var classes := OptionButton.new()
	classes.custom_minimum_size = Vector2(132 if narrow else (145 if compact else 165), control_height)
	if compact:
		apply_sharp_compact_style(classes)
	var class_values = ["All classes", "Guardian", "Cleric", "Rogue", "Ranger", "Mage", "Warlock", "Slayer"]
	for value in class_values:
		classes.add_item(value)
	classes.select(class_values.find(hero_class_filter))
	classes.item_selected.connect(
		func(i):
			hero_class_filter = classes.get_item_text(i)
			refresh.call()
	)
	bar.add_child(classes)
	var types := OptionButton.new()
	types.custom_minimum_size = Vector2(155 if narrow else (174 if compact else 155), control_height)
	if compact:
		apply_sharp_compact_style(types)
	var type_values = ["All Heroes", "Standard Heroes", "Special Heroes"]
	for value in type_values:
		types.add_item(value)
	types.select(type_values.find(hero_type_filter))
	types.item_selected.connect(
		func(i):
			hero_type_filter = types.get_item_text(i)
			refresh.call()
	)
	bar.add_child(types)
	if include_sort:
		var sorts := OptionButton.new()
		sorts.custom_minimum_size = Vector2(112 if narrow else (125 if compact else 145), control_height)
		if compact:
			apply_sharp_compact_style(sorts)
		for value in ["Name", "Role", "Class", "Level"]:
			sorts.add_item(value)
		sorts.select(["Name", "Role", "Class", "Level"].find(roster_sort))
		sorts.item_selected.connect(
			func(i):
				roster_sort = sorts.get_item_text(i)
				refresh.call()
		)
		bar.add_child(sorts)
		var direction := button(
			"↓" if roster_descending else "↑",
			func():
				roster_descending = not roster_descending
				refresh.call(),
			54
		)
		direction.custom_minimum_size.y = control_height
		if compact:
			apply_sharp_compact_style(direction)
		bar.add_child(direction)
	return bar


func active_team_drop_slot(mouse_pos: Vector2) -> int:
	if team_active_row == null:
		return -1
	for slot_index in team_active_row.get_child_count():
		var slot_control := team_active_row.get_child(slot_index) as Control
		if slot_control != null and Rect2(slot_control.global_position, slot_control.size).has_point(mouse_pos):
			return slot_index
	return -1


func end_team_drag(mouse_pos: Vector2) -> void:
	if not team_dragging:
		return
	var dropped_on_active := (
		team_active_zone != null
		and mouse_pos.x >= team_active_zone.global_position.x
		and mouse_pos.x <= team_active_zone.global_position.x + team_active_zone.size.x
		and mouse_pos.y >= team_active_zone.global_position.y
		and mouse_pos.y <= team_active_zone.global_position.y + team_active_zone.size.y
	)
	var dropped_on_reserve := (
		team_reserve_zone != null
		and mouse_pos.x >= team_reserve_zone.global_position.x
		and mouse_pos.x <= team_reserve_zone.global_position.x + team_reserve_zone.size.x
		and mouse_pos.y >= team_reserve_zone.global_position.y
		and mouse_pos.y <= team_reserve_zone.global_position.y + team_reserve_zone.size.y
	)
	if dropped_on_active:
		move_to_active_team(team_drag_index, active_team_drop_slot(mouse_pos))
	elif dropped_on_reserve:
		move_to_reserve(team_drag_index)
	team_dragging = false
	team_drag_index = -1
	team_drag_origin = ""
	if team_drag_preview != null:
		team_drag_preview.queue_free()
		team_drag_preview = null
	save_game()
	if screen == "roster":
		show_roster()
	else:
		show_team()


func team_card_text(_idx: int) -> String:
	return ""


func role_glyph(_hero_class: String) -> String:
	return ""


func begin_vault_drag() -> void:
	pass


func update_vault_drag_visual() -> void:
	pass


func finish_vault_pointer(_pointer_position: Vector2) -> void:
	pass
