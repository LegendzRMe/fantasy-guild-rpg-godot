extends "res://scripts/runtime/app_team_interaction_runtime.gd"


func begin_vault_press(entry_id: String, pointer_position: Vector2) -> void:
	if item_card_overlay != null:
		return
	vault_press_active = true
	vault_press_entry_id = entry_id
	vault_press_time = 0.0
	vault_press_start = pointer_position
	vault_pointer_position = pointer_position
	vault_dragging = false
	vault_page_hover = -1
	vault_page_hover_time = 0.0


func vault_slot_input(event: InputEvent, entry_id: String, slot_control: Control) -> void:
	if entry_id == "":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		begin_vault_press(entry_id, slot_control.global_position + event.position)
	elif event is InputEventScreenTouch and event.pressed:
		begin_vault_press(entry_id, slot_control.global_position + event.position)


func begin_vault_drag() -> void:
	if not vault_press_active or vault_dragging:
		return
	var entry := InventorySystem.entry_by_id(state, vault_press_entry_id)
	if entry.is_empty():
		return
	vault_dragging = true
	var source_flat := InventorySystem.flat_position(entry)
	if storage_entry_controls.has(vault_press_entry_id):
		storage_entry_controls[vault_press_entry_id].modulate = Color(1, 1, 1, .28)
	elif vault_slot_controls.has(source_flat):
		vault_slot_controls[source_flat].modulate = Color(1, 1, 1, .28)
	var preview := Label.new()
	preview.text = InventorySystem.fallback_glyph(str(entry.get("fallback_icon_type", entry.get("slot", "item"))))
	preview.size = Vector2(92, 92)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 18)
	preview.add_theme_color_override("font_color", Color("ffffff"))
	preview.add_theme_stylebox_override("normal", ui_box(Color(0.08, 0.12, 0.19, .88), 8, C_GOLD, 2))
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.scale = Vector2(1.08, 1.08)
	ui.add_child(preview)
	vault_drag_preview = preview
	update_vault_drag_visual()


func update_vault_drag_visual() -> void:
	if not vault_dragging or vault_drag_preview == null:
		return
	vault_drag_preview.position = vault_pointer_position - vault_drag_preview.size * .5
	var entry := InventorySystem.entry_by_id(state, vault_press_entry_id)
	var source_location := InventorySystem.storage_location(entry)
	var page_controls: Dictionary = vault_page_controls if source_location == "vault" else depot_page_controls
	var current_page := vault_page if source_location == "vault" else depot_page
	var hovered_page := -1
	for page_index in page_controls:
		var control: Control = page_controls[page_index]
		if is_instance_valid(control) and Rect2(control.global_position, control.size).has_point(vault_pointer_position):
			hovered_page = int(page_index)
			break
	if hovered_page != current_page:
		if hovered_page == vault_page_hover:
			vault_page_hover_time += get_process_delta_time()
		else:
			vault_page_hover = hovered_page
			vault_page_hover_time = 0.0
		if hovered_page >= 0 and vault_page_hover_time >= InventorySystem.PAGE_HOVER_DURATION:
			var held_entry_id := vault_press_entry_id
			var held_pointer := vault_pointer_position
			cancel_vault_input()
			if source_location == "vault":
				vault_page = hovered_page
			else:
				depot_page = hovered_page
			show_vault()
			begin_vault_press(held_entry_id, held_pointer)
			begin_vault_drag()
	else:
		vault_page_hover = -1
		vault_page_hover_time = 0.0


func finish_vault_pointer(pointer_position: Vector2) -> void:
	if not vault_press_active:
		return
	var entry_id := vault_press_entry_id
	var entry := InventorySystem.entry_by_id(state, entry_id)
	var source_location := InventorySystem.storage_location(entry)
	var was_dragging := vault_dragging
	if was_dragging:
		var target_location := ""
		for location in storage_panes:
			var pane: Control = storage_panes[location]
			if is_instance_valid(pane) and pane.get_global_rect().has_point(pointer_position):
				target_location = str(location)
				break
		if target_location != "" and target_location != source_location:
			cancel_vault_input()
			request_storage_transfer(entry_id, target_location)
			return
		var target_slot := -1
		if source_location == "vault":
			for flat_index in vault_slot_controls:
				var control: Control = vault_slot_controls[flat_index]
				if is_instance_valid(control) and Rect2(control.global_position, control.size).has_point(pointer_position):
					target_slot = int(flat_index)
					break
		if source_location == "vault" and target_slot >= 0:
			InventorySystem.move_entry(state, entry_id, target_slot / InventorySystem.STORAGE_PAGE_SIZE, target_slot % InventorySystem.STORAGE_PAGE_SIZE)
			save_game()
			if vault_drag_preview != null:
				var target_control: Control = vault_slot_controls[target_slot]
				var target_position := target_control.global_position + (target_control.size - vault_drag_preview.size) * .5
				vault_press_active = false
				vault_dragging = false
				var tween := create_tween()
				tween.tween_property(vault_drag_preview, "position", target_position, .12)
				tween.parallel().tween_property(vault_drag_preview, "scale", Vector2.ONE, .12)
				tween.finished.connect(
					func():
						cancel_vault_input()
						show_vault()
				)
				return
	cancel_vault_input()
	if was_dragging:
		show_vault()
	else:
		open_item_card(entry_id, source_location)


func cancel_vault_input() -> void:
	if storage_entry_controls.has(vault_press_entry_id) and is_instance_valid(storage_entry_controls[vault_press_entry_id]):
		storage_entry_controls[vault_press_entry_id].modulate = Color.WHITE
	vault_press_active = false
	vault_press_entry_id = ""
	vault_press_time = 0.0
	vault_dragging = false
	vault_page_hover = -1
	vault_page_hover_time = 0.0
	if vault_drag_preview != null and is_instance_valid(vault_drag_preview):
		vault_drag_preview.queue_free()
	vault_drag_preview = null
