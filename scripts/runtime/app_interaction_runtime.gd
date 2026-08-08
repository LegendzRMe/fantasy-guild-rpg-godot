extends "res://scripts/runtime/app_vault_interaction_runtime.gd"


func team_card_text(idx: int) -> String:
	var h = state.heroes[idx]
	return "%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]), h.name, h["class"], h["level"]]


func role_glyph(hero_class: String) -> String:
	match hero_class:
		"Guardian":
			return "◈"
		"Cleric":
			return "✚"
		"Mage":
			return "✦━"
		_:
			return "➶"


func toggle_test_special_hero(idx: int) -> void:
	if not is_testing_save():
		return
	var hero = state.heroes[idx]
	var make_special = not bool(hero.get("is_special_hero", false))
	hero["is_special_hero"] = make_special
	hero["identity_type"] = "special" if make_special else "standard"
	hero["editable_name"] = not make_special
	hero["editable_appearance"] = not make_special
	hero["can_edit_name"] = not make_special
	hero["can_edit_appearance"] = not make_special
	hero["member_type"] = "special_hero" if make_special else "founding_recruit"
	hero["prestige_rank"] = 1 if make_special else 0
	hero["prestige_reward_floor_rank"] = int(hero.prestige_rank) if make_special else 0
	hero["legacy_rank"] = hero.prestige_rank
	save_game()
	show_roster()


func set_testing_hero_level(idx: int, value: float) -> void:
	if not is_testing_save() or idx < 0 or idx >= state.heroes.size():
		return
	var hero: Dictionary = state.heroes[idx]
	hero.level = clampi(int(round(value)), 1, TESTING_MAX_HERO_LEVEL)
	hero.xp = clampi(int(hero.get("xp", 0)), 0, int(hero.level) * 100 - 1)
	state.class_talent_discovery = TalentSystem.record_class_discovery(
		state.class_talent_discovery, str(hero.class_id), 30 if is_testing_save() else int(hero.level)
	)
	save_game()
	show_roster()


func reset_testing_ashwood_story() -> void:
	if not is_testing_save():
		return
	var preserved_next_item_id: int = int(state.zone0.get("next_item_id", 1))
	state.zone0 = AshwoodManager.default_progress()
	state.zone0.next_item_id = preserved_next_item_id
	state.selected_team = [0, 1]
	state.active_team = [0, 1]
	current_team_slot = -1
	pending_victory.clear()
	pending_map_reveals.clear()
	ashwood_victory_stage = ""
	ashwood_reward_reveal_complete = false
	ashwood_next_encounter = ""
	ashwood_selected_decision_text = ""
	ashwood_consequence_lines.clear()
	ashwood_consequence_phase = 0
	current_ashwood_encounter = ""
	save_game()
	show_zone_map(0)


func request_reset_testing_story() -> void:
	if not is_testing_save():
		return
	var dialog := ConfirmationDialog.new()
	dialog.name = "TestingStoryResetDialog"
	dialog.title = "Reset Ashwood Story?"
	dialog.dialog_text = "Reset all Ashwood encounter progress, decisions, optional paths, and story choices?\n\nHeroes, levels, equipment, inventory, and guild resources will be kept. Your active party will return to Brann and Sera for story testing."
	dialog.ok_button_text = "Reset Story"
	dialog.confirmed.connect(reset_testing_ashwood_story)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(590, 260))


func ability_tooltip(hero_class: String, slot: int) -> String:
	return GameData.ability_tooltip(hero_class, slot)


func make_team_card(idx: int, origin: String, slot_index: int = -1) -> Button:
	var b := Button.new()
	var active_card := origin == "active"
	b.custom_minimum_size = Vector2(180, 100) if active_card else Vector2(150, 74)
	b.text = team_card_text(idx)
	b.add_theme_font_size_override("font_size", 16 if active_card else 13)
	b.add_theme_stylebox_override("normal", ui_box(Color("202d42"), 4, Color("35445a"), 1))
	b.add_theme_stylebox_override("hover", ui_box(Color("293a53"), 4, CLASSES[state.heroes[idx]["class"]].color, 1))
	if bool(state.heroes[idx].get("is_special_hero", false)):
		b.add_theme_stylebox_override("normal", ui_box(Color("2b3040"), 4, C_GOLD, 2))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	if active_card and slot_index >= 0:
		var formation_names := ["Front", "Top", "Bottom", "Back"]
		var hero: Dictionary = state.heroes[idx]
		b.text = (
			"%d  %s\n%s  %s\n%s  •  Level %d"
			% [slot_index + 1, formation_names[clampi(slot_index, 0, 3)].to_upper(), role_glyph(hero["class"]), hero.name, hero["class"], hero.level]
		)
		b.tooltip_text = ("Party slot %d — %s position. Drag onto another party slot to reorder." % [slot_index + 1, formation_names[clampi(slot_index, 0, 3)]])
	if team_has_member(idx):
		b.add_theme_color_override("font_color", CLASSES[state.heroes[idx]["class"]].color)
		b.add_theme_stylebox_override("normal", ui_box(Color("24364b"), 4, CLASSES[state.heroes[idx]["class"]].color, 2))
	else:
		b.add_theme_color_override("font_color", C_TEXT)
	var availability:=TavernFacilitySystem.member_status(state,str(state.heroes[idx].hero_id))
	if str(availability.status)!="available":
		b.text+="\n"+str(availability.label)
		b.tooltip_text=str(availability.label)
		if not active_card:b.disabled=not bool(availability.available)

	b.gui_input.connect(
		func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				start_team_drag(idx, origin)
			elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				end_team_drag(get_viewport().get_mouse_position())
	)
	return b
