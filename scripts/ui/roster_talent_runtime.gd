extends "res://scripts/ui/roster_ability_runtime.gd"

const TalentTierView = preload("res://scripts/ui/talent_tier_view.gd")


func guardian_talent_name(talent_id: String) -> String:
	if talent_id.begins_with("cleric_"):
		return str(ClericData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("ranger_"):
		return str(RangerData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("mage_"):
		return str(MageData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("warlock_"):
		return str(WarlockData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("rogue_"):
		return str(RogueData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("slayer_"):
		return str(SlayerData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("priest_"):
		return str(PriestData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("shaman_"):
		return str(ShamanData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("templar_"):
		return str(TemplarData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("protector_"):
		return str(ProtectorData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("sentinel_"):
		return str(SentinelData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("huntsman_"):
		return str(HuntsmanData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("druid_"):
		return str(DruidData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	if talent_id.begins_with("warrior_"):
		return str(WarriorData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))
	return str(GuardianData.WORKING_NAMES.get(talent_id, talent_id.replace("_", " ").capitalize()))


func roster_talent_description(hero_class: String, option_id: String) -> String:
	if hero_class == "Guardian":
		return str(GuardianData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Cleric":
		return str(ClericData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Rogue":
		return str(RogueData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Slayer":
		return str(SlayerData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Ranger":
		return str(RangerData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Mage":
		return str(MageData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Warlock":
		return str(WarlockData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Priest":
		return str(PriestData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Shaman":
		return str(ShamanData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Templar":
		return str(TemplarData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Protector":
		return str(ProtectorData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Sentinel":
		return str(SentinelData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Huntsman":
		return str(HuntsmanData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Druid":
		return str(DruidData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	if hero_class == "Warrior":
		return str(WarriorData.TALENT_DESCRIPTIONS.get(option_id, "Talent details are still being developed."))
	return "Talent details are still being developed."


func remember_roster_scroll() -> void:
	var scroll := roster_section_scroll
	if scroll != null:
		hero_roster_scroll_positions["%d:%s" % [selected_roster_index, hero_roster_section]] = (scroll.scroll_vertical)


func restore_roster_scroll(scroll: ScrollContainer, key: String) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(hero_roster_scroll_positions.get(key, 0))


func refresh_roster_preserving_scroll() -> void:
	remember_roster_scroll()
	show_roster()


func plan_roster_talent(hero_index: int, tier_id: String, option_id: String, refresh: bool = true) -> void:
	if hero_index < 0 or hero_index >= state.heroes.size():
		return
	var hero: Dictionary = state.heroes[hero_index]
	var definition := GameData.class_definition(str(hero.get("class", "")))
	var planned_id := str(hero.get("planned_talents", {}).get(tier_id, ""))
	state.heroes[hero_index] = (
		TalentSystem.clear_planned_option(hero, tier_id) if planned_id == option_id else TalentSystem.plan_option(hero, definition, tier_id, option_id)
	)
	save_game()
	if refresh:
		hero_roster_section = "Talents"
		refresh_roster_preserving_scroll()


func confirm_roster_talent(hero_index: int, tier_id: String, option_id: String, refresh: bool = true) -> bool:
	if hero_index < 0 or hero_index >= state.heroes.size():
		return false
	var hero: Dictionary = state.heroes[hero_index]
	var definition := GameData.class_definition(str(hero.get("class", "")))
	var result := TalentSystem.select_option(hero, definition, tier_id, option_id)
	if not bool(result.get("success", false)):
		flash(str(result.get("reason", "That talent cannot be selected.")))
		return false
	state.heroes[hero_index] = result.hero
	save_game()
	if refresh:
		hero_roster_section = "Talents"
		refresh_roster_preserving_scroll()
	return true


func open_roster_talent_details(hero_index: int, tier_id: String, option_id: String) -> void:
	if hero_index < 0 or hero_index >= state.heroes.size():
		return
	var hero: Dictionary = state.heroes[hero_index]
	var overlay := Control.new()
	overlay.name = "RosterTalentDetailsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)
	var backdrop := Button.new()
	backdrop.name = "RosterTalentDetailsBackdrop"
	backdrop.flat = true
	backdrop.focus_mode = Control.FOCUS_NONE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_theme_stylebox_override("normal", ui_box(Color(0.01, 0.02, 0.04, .78), 0))
	backdrop.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(backdrop)
	var panel := PanelContainer.new()
	panel.name = "RosterTalentDetailsCard"
	panel.position = Vector2(340, 145)
	panel.size = Vector2(600, 430)
	panel.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 10, CLASSES[hero["class"]].color, 2))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var tier_number := int(tier_id.trim_prefix("tier_"))
	column.add_child(label("TIER %d  •  LEVEL %d" % [tier_number, int(TalentSystem.TIER_LEVELS.get(tier_id, 0))], 13, C_GOLD))
	column.add_child(label(guardian_talent_name(option_id).to_upper(), 25, CLASSES[hero["class"]].color))
	column.add_child(rule())
	var description := label(roster_talent_description(str(hero.get("class", "")), option_id), 16, C_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var selected := str(hero.get("selected_talents", {}).get(tier_id, "")) == option_id
	var required_level := int(TalentSystem.TIER_LEVELS.get(tier_id, 999))
	var footer_text := (
		"SELECTED"
		if selected
		else ("Hold this talent on the tree to choose it." if int(hero.get("level", 1)) >= required_level else "UNLOCKS AT LEVEL %d" % required_level)
	)
	if footer_text != "":
		var footer := label(footer_text, 14, C_GOLD if selected else C_MUTED)
		footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(footer)


func victory_talent_unlocks() -> Array:
	var unlocks: Array = []
	var level_ups: Array = pending_victory.get("rewards", {}).get("level_ups", []) if current_ashwood_encounter != "" else victory_level_ups
	for level_up in level_ups:
		var hero_index := int(level_up.get("hero_index", -1))
		if hero_index < 0 and level_up.has("slot"):
			var slot := int(level_up.slot)
			hero_index = (int(battle_hero_indices[slot]) if slot >= 0 and slot < battle_hero_indices.size() else -1)
		if hero_index < 0 or hero_index >= state.heroes.size():
			continue
		for tier_id in level_up.get("talent_tiers", []):
			if str(state.heroes[hero_index].get("selected_talents", {}).get(str(tier_id), "")) == "":
				unlocks.append({"hero_index": hero_index, "tier_id": str(tier_id)})
	return unlocks


func open_victory_talent_choices() -> bool:
	if victory_talent_prompt_handled:
		return false
	victory_talent_prompt_handled = true
	victory_talent_queue = victory_talent_unlocks()
	victory_talent_choice_index = 0
	if victory_talent_queue.is_empty():
		return false
	show_victory_talent_choice()
	return true


func close_victory_talent_overlay() -> void:
	if victory_talent_overlay != null and is_instance_valid(victory_talent_overlay):
		victory_talent_overlay.queue_free()
	victory_talent_overlay = null


func advance_victory_talent_choice() -> void:
	victory_talent_choice_index += 1
	if victory_talent_choice_index >= victory_talent_queue.size():
		close_victory_talent_overlay()
		ui.visible = false
		complete_victory_sequence_navigation()
		return
	show_victory_talent_choice()


func victory_plan_talent(hero_index: int, tier_id: String, option_id: String) -> void:
	plan_roster_talent(hero_index, tier_id, option_id, false)
	show_victory_talent_choice()


func victory_confirm_talent(hero_index: int, tier_id: String, option_id: String) -> void:
	if confirm_roster_talent(hero_index, tier_id, option_id, false):
		advance_victory_talent_choice()


func show_victory_talent_choice() -> void:
	close_victory_talent_overlay()
	if victory_talent_choice_index < 0 or victory_talent_choice_index >= victory_talent_queue.size():
		return
	var entry: Dictionary = victory_talent_queue[victory_talent_choice_index]
	var hero_index := int(entry.hero_index)
	var tier_id := str(entry.tier_id)
	var hero: Dictionary = state.heroes[hero_index]
	var class_definition := GameData.class_definition(str(hero.get("class", "")))
	var class_id := str(class_definition.get("class_id", GameData.class_id_for(str(hero.get("class", "")))))
	var tier_number := int(tier_id.trim_prefix("tier_"))
	ui.visible = true
	var overlay := Control.new()
	overlay.name = "VictoryTalentChoiceOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)
	victory_talent_overlay = overlay
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.02, 0.04, .82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(210, 105)
	panel.size = Vector2(860, 510)
	panel.add_theme_stylebox_override("panel", ui_box(Color("172234"), 10, CLASSES[hero["class"]].color, 2))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_copy)
	heading_copy.add_child(label("NEW TALENT TIER", 28, C_GOLD))
	heading_copy.add_child(label("%s  •  Level %d %s" % [str(hero.get("name", "Hero")), int(hero.get("level", 1)), str(hero.get("class", ""))], 16, C_MUTED))
	var counter := label("%d / %d" % [victory_talent_choice_index + 1, victory_talent_queue.size()], 14, C_MUTED)
	counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(counter)
	column.add_child(rule())
	var tier_view := (
		make_roster_talent_tier(hero, class_definition, class_id, state.get("class_talent_discovery", {}), tier_number, hero_index) as TalentTierView
	)
	# Replace roster-refresh actions with victory-specific actions.
	for connection in tier_view.plan_toggled.get_connections():
		tier_view.plan_toggled.disconnect(connection.callable)
	for connection in tier_view.selection_confirmed.get_connections():
		tier_view.selection_confirmed.disconnect(connection.callable)
	tier_view.plan_toggled.connect(func(requested_tier: String, requested_option: String): victory_plan_talent(hero_index, requested_tier, requested_option))
	tier_view.selection_confirmed.connect(
		func(requested_tier: String, requested_option: String): victory_confirm_talent(hero_index, requested_tier, requested_option)
	)
	column.add_child(tier_view)
	var help := label("Tap a talent for details. Hold it until the bar fills to choose it.", 14, C_MUTED)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var later := compact_button("DECIDE LATER", advance_victory_talent_choice, 190)
	later.name = "VictoryTalentDecideLater"
	later.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(later)


func make_roster_talent_tier(
	hero: Dictionary, class_definition: Dictionary, class_id: String, discovery: Dictionary, tier_number: int, hero_index: int = -1
) -> Control:
	var tier_id := "tier_%d" % tier_number
	var tier_definition := TalentSystem.tier_definition(class_definition, tier_id)
	if tier_definition.is_empty():
		return Control.new()
	var required_level := int(tier_definition.get("unlock_level", TalentSystem.TIER_LEVELS.get(tier_id, 999)))
	var revealed := TalentSystem.tier_is_revealed(discovery, class_id, tier_id, is_testing_save())
	var hero_level := int(hero.get("level", 1))
	var selected_id := str(hero.get("selected_talents", {}).get(tier_id, ""))
	var planned_id := str(hero.get("planned_talents", {}).get(tier_id, ""))
	var options: Array = []
	for raw_option_id in tier_definition.get("option_ids", []):
		var option_id := str(raw_option_id)
		var available := true
		var unavailable_reason := ""
		if hero_level >= required_level:
			var validation := TalentSystem.validate_selection(hero, class_definition, tier_id, option_id)
			available = bool(validation.valid) or option_id == selected_id
			unavailable_reason = str(validation.reason)
		options.append(
			{
				"id": option_id,
				"display_name":
				guardian_talent_name(option_id) if str(hero.get("class", "")) in ["Guardian", "Cleric"] else option_id.replace("_", " ").capitalize(),
				"description": roster_talent_description(str(hero.get("class", "")), option_id),
				"selected": option_id == selected_id,
				"planned": option_id == planned_id,
				"available": available,
				"unavailable_reason": unavailable_reason,
				"class_name": str(hero.get("class", "Hero"))
			}
		)
	var resolved_index := selected_roster_index if hero_index < 0 else hero_index
	var view := TalentTierView.new()
	view.configure(
		tier_id,
		tier_number,
		required_level,
		str(tier_definition.get("kind", "talent")),
		hero_level,
		revealed,
		options,
		CLASSES[hero["class"]].color,
		C_TEXT,
		C_MUTED,
		C_GOLD
	)
	view.details_requested.connect(
		func(requested_tier: String, requested_option: String): open_roster_talent_details(resolved_index, requested_tier, requested_option)
	)
	view.plan_toggled.connect(func(requested_tier: String, requested_option: String): plan_roster_talent(resolved_index, requested_tier, requested_option))
	view.selection_confirmed.connect(
		func(requested_tier: String, requested_option: String): confirm_roster_talent(resolved_index, requested_tier, requested_option)
	)
	return view
