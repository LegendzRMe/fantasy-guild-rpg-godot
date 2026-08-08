extends "res://scripts/ui/item_equipment_runtime.gd"

const AbilityKeyBadge = preload("res://scripts/ui/ability_key_badge.gd")
const GuardianAbilityPresenter = preload("res://scripts/data/guardian_ability_presenter.gd")
const ClericAbilityPresenter = preload("res://scripts/data/cleric_ability_presenter.gd")
const RangerAbilityPresenter = preload("res://scripts/data/ranger_ability_presenter.gd")
const MageAbilityPresenter = preload("res://scripts/data/mage_ability_presenter.gd")
const WarlockAbilityPresenter = preload("res://scripts/data/warlock_ability_presenter.gd")
const RogueAbilityPresenter = preload("res://scripts/data/rogue_ability_presenter.gd")
const SlayerAbilityPresenter = preload("res://scripts/data/slayer_ability_presenter.gd")
const PriestAbilityPresenter = preload("res://scripts/data/priest_ability_presenter.gd")


func recruitment_preview_value(candidate: Dictionary, field_id: String, value: String, unavailable: bool = false) -> String:
	if not RecruitmentSystem.field_is_revealed(candidate, field_id):
		return "Unknown"
	return "Not currently available" if unavailable else value


func recruitment_preview_section(container: Container, title: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 6, Color("35445a"), 1))
	container.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	content.add_child(label(title, 14, C_GOLD))
	content.add_child(rule())
	return content


func _show_recruitment_candidate_preview_legacy(candidate: Dictionary) -> void:
	if candidate.is_empty():
		show_tavern()
		return
	screen = "recruitment_preview"
	var hero: Dictionary = candidate.hero_record
	var hero_class := str(hero.get("class", "Guardian"))
	var class_info: Dictionary = CLASSES[hero_class]
	var root := base_screen("Candidate Inspection", "READ-ONLY RECRUITMENT PREVIEW  •  HIDDEN INFORMATION REMAINS UNVERIFIED")
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	var portrait := Button.new()
	portrait.name = "RecruitmentPreviewPortrait"
	portrait.disabled = true
	portrait.text = role_glyph(hero_class)
	portrait.custom_minimum_size = Vector2(150, 140)
	portrait.add_theme_font_size_override("font_size", 52)
	portrait.add_theme_stylebox_override("disabled", ui_box(Color("1a2332"), 70, class_info.color, 4))
	header.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	identity.add_child(label(str(hero.display_name), 31, class_info.color))
	identity.add_child(label("Role  •  %s" % str(candidate.broad_role), 16, C_TEXT))
	identity.add_child(label("Class  •  %s" % recruitment_preview_value(candidate, "class", hero_class), 15, C_MUTED))
	identity.add_child(label("Level  •  %s" % recruitment_preview_value(candidate, "exact_level", str(int(hero.level))), 15, C_MUTED))
	identity.add_child(label("Origin  •  %s" % str(candidate.origin_zone_name), 14, C_MUTED))
	var disclosure := VBoxContainer.new()
	disclosure.custom_minimum_size.x = 290
	header.add_child(disclosure)
	disclosure.add_child(label("INFORMATION REVEALED", 13, C_GOLD))
	disclosure.add_child(
		label(
			(
				"%d of %d  •  %d%%"
				% [int(candidate.revealed_field_count), int(candidate.total_revealable_field_count), int(candidate.information_disclosure_score)]
			),
			22,
			C_TEXT
		)
	)
	disclosure.add_child(
		label(
			(
				"Signing cost  •  %d Gold\nDeparture  •  %s%s"
				% [int(candidate.signing_cost), "Locked  •  " if bool(candidate.locked) else "", tavern_time_text(float(candidate.remaining_wait_minutes))]
			),
			14,
			C_MUTED
		)
	)
	var scroll := ScrollContainer.new()
	scroll.name = "RecruitmentPreviewScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var overview := recruitment_preview_section(grid, "OVERVIEW")
	overview.add_child(make_roster_detail_row("Broad Role", str(candidate.broad_role)))
	overview.add_child(make_roster_detail_row("Exact Class", recruitment_preview_value(candidate, "class", hero_class)))
	overview.add_child(make_roster_detail_row("Exact Level", recruitment_preview_value(candidate, "exact_level", str(int(hero.level)))))
	overview.add_child(make_roster_detail_row("Approximate Level", "%d–%d" % [int(candidate.approximate_level_min), int(candidate.approximate_level_max)]))
	overview.add_child(make_roster_detail_row("Personality", "Unverified"))
	var abilities := recruitment_preview_section(grid, "ABILITIES")
	var ability_revealed: bool = RecruitmentSystem.field_is_revealed(candidate, "abilities_talents")
	for slot in 4:
		var unlocked := TalentSystem.ability_is_unlocked(int(hero.level), slot)
		var ability_name := (
			str(ABILITIES[hero_class][slot])
			if ability_revealed and unlocked
			else ("Not disclosed" if not ability_revealed else "Locked at Level %d" % int(TalentSystem.ABILITY_UNLOCK_LEVELS[slot]))
		)
		abilities.add_child(make_roster_detail_row(["Q", "W", "E", "R"][slot], ability_name))
	var talents := recruitment_preview_section(grid, "TALENTS")
	talents.add_child(
		label(
			"No talents are unlocked within this Level 1–4 recruitment test." if ability_revealed else "Talent information has not been disclosed.", 13, C_MUTED
		)
	)
	var equipment := recruitment_preview_section(grid, "EQUIPMENT")
	var equipment_instances: Array = candidate.get("equipment_instances", [])
	var summary := "%d equipped item(s)" % equipment_instances.size()
	equipment.add_child(make_roster_detail_row("Summary", recruitment_preview_value(candidate, "equipment_summary", summary)))
	if RecruitmentSystem.field_is_revealed(candidate, "equipped_items"):
		if equipment_instances.is_empty():
			equipment.add_child(label("No equipment verified.", 13, C_MUTED))
		else:
			for item in equipment_instances:
				equipment.add_child(make_roster_detail_row(str(item.get("slot", "Item")).capitalize(), str(item.get("display_name", "Item"))))
	else:
		equipment.add_child(label("Equipped item details  •  Not disclosed", 13, C_MUTED))
	var profession := recruitment_preview_section(grid, "PROFESSION")
	var progress := ProfessionSystem.migrate_progress(hero.get("profession_progress", {}))
	var profession_id := str(progress.profession_id)
	var profession_name := "None" if profession_id == "" else ProfessionData.profession_name(profession_id)
	profession.add_child(make_roster_detail_row("Profession", recruitment_preview_value(candidate, "profession", profession_name)))
	profession.add_child(
		make_roster_detail_row(
			"Rank", recruitment_preview_value(candidate, "profession_level", str(int(progress.profession_rank)) if profession_id != "" else "0")
		)
	)
	var traits := recruitment_preview_section(grid, "TRAITS")
	traits.add_child(make_roster_detail_row("Positive Trait", recruitment_preview_value(candidate, "positive_trait", "", true)))
	traits.add_child(make_roster_detail_row("Negative Trait", recruitment_preview_value(candidate, "negative_trait", "", true)))
	var title := recruitment_preview_section(grid, "TITLE")
	title.add_child(make_roster_detail_row("Title", recruitment_preview_value(candidate, "title", "", true)))
	title.add_child(label("Character Titles are not functional in the current game.", 12, C_MUTED))


func make_recruitment_preview_section_button(section: String, candidate: Dictionary) -> Button:
	var tab := compact_button(section, func(): recruitment_preview_active_section = section; show_recruitment_candidate_preview(candidate), 125)
	tab.name = "RecruitmentPreviewSection" + section
	apply_sharp_compact_style(tab)
	if recruitment_preview_active_section == section:
		tab.add_theme_color_override("font_color", C_GOLD)
		tab.add_theme_stylebox_override("normal", ui_box(Color("2b3b52"), 4, C_GOLD, 2))
	return tab


func make_recruitment_preview_equipment_slot(candidate: Dictionary, slot: String) -> Button:
	var gear := Button.new()
	gear.name = "RecruitmentPreviewEquipment" + slot.capitalize()
	gear.disabled = true
	gear.custom_minimum_size = Vector2(105, 70)
	gear.add_theme_stylebox_override("disabled", ui_box(Color("202d42"), 4, Color("35445a"), 1))
	if not RecruitmentSystem.field_is_revealed(candidate, "equipped_items"):
		gear.text = "?"
		gear.add_theme_font_size_override("font_size", 27)
		return gear
	var matching: Dictionary = {}
	for item in candidate.get("equipment_instances", []):
		if str(item.get("slot", "")) == slot:
			matching = item
			break
	gear.text = "—" if matching.is_empty() else str(matching.get("display_name", "Item"))
	gear.tooltip_text = gear.text
	gear.add_theme_font_size_override("font_size", 11 if not matching.is_empty() else 22)
	return gear


func populate_recruitment_preview_workspace(content: VBoxContainer, candidate: Dictionary, hero: Dictionary, hero_class: String) -> void:
	content.add_theme_constant_override("separation", 10)
	var abilities_revealed := RecruitmentSystem.field_is_revealed(candidate, "abilities_talents")
	match recruitment_preview_active_section:
		"Abilities":
			for slot in 4:
				var unlocked := TalentSystem.ability_is_unlocked(int(hero.level), slot)
				var ability_name := "Unknown"
				var description := "This candidate's ability information has not been revealed."
				if abilities_revealed:
					ability_name = str(ABILITIES[hero_class][slot]) if unlocked else "Locked at Level %d" % int(TalentSystem.ABILITY_UNLOCK_LEVELS[slot])
					description = ability_tooltip(hero_class, slot) if unlocked else "This ability has not unlocked yet."
				content.add_child(make_roster_ability_row(["Q", "W", "E", "R"][slot], ability_name, description, CLASSES[hero_class].color if abilities_revealed else C_MUTED, true))
			content.add_child(make_roster_ability_row("D", str(TRAITS[hero_class]) if abilities_revealed else "Unknown", "Passive trait" if abilities_revealed else "This candidate's trait has not been revealed.", CLASSES[hero_class].color if abilities_revealed else C_MUTED, true))
		"Talents":
			var rows: Array = []
			for tier in range(1, 9):
				rows.append({"caption": "Tier %d" % tier, "value": "None unlocked" if abilities_revealed else "Unknown"})
			content.add_child(make_roster_detail_card("CandidateTalents", "TALENTS", rows))
		"Professions":
			var progress := ProfessionSystem.migrate_progress(hero.get("profession_progress", {}))
			var profession_id := str(progress.profession_id)
			var profession_name := "None" if profession_id == "" else ProfessionData.profession_name(profession_id)
			content.add_child(make_roster_detail_card("CandidateProfession", "PROFESSION", [
				{"caption": "Profession", "value": recruitment_preview_value(candidate, "profession", profession_name)},
				{"caption": "Rank", "value": recruitment_preview_value(candidate, "profession_level", str(int(progress.profession_rank)) if profession_id != "" else "0")},
				{"caption": "Specialization", "value": "Unknown"},
			]))
		_:
			var equipment: Array = candidate.get("equipment_instances", [])
			var grid := GridContainer.new()
			grid.name = "RosterDetailsGrid"
			grid.columns = 2
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 8)
			content.add_child(grid)
			grid.add_child(make_roster_detail_card("CandidateIdentity", "CANDIDATE", [
				{"caption": "Broad Role", "value": str(candidate.broad_role)},
				{"caption": "Class", "value": recruitment_preview_value(candidate, "class", hero_class)},
				{"caption": "Level", "value": recruitment_preview_value(candidate, "exact_level", str(int(hero.level)))},
				{"caption": "Estimated Level", "value": "%d–%d" % [int(candidate.approximate_level_min), int(candidate.approximate_level_max)]},
			]))
			grid.add_child(make_roster_detail_card("CandidateRecruitment", "RECRUITMENT", [
				{"caption": "Origin", "value": str(candidate.origin_zone_name)},
				{"caption": "Signing Cost", "value": "%d Gold" % int(candidate.signing_cost)},
				{"caption": "Departure", "value": "Locked" if bool(candidate.locked) else tavern_time_text(float(candidate.remaining_wait_minutes))},
				{"caption": "Information", "value": "%d / %d" % [int(candidate.revealed_field_count), int(candidate.total_revealable_field_count)]},
			]))
			grid.add_child(make_roster_detail_card("CandidateTraits", "TRAITS & TITLE", [
				{"caption": "Positive Trait", "value": recruitment_preview_value(candidate, "positive_trait", "", true)},
				{"caption": "Negative Trait", "value": recruitment_preview_value(candidate, "negative_trait", "", true)},
				{"caption": "Title", "value": recruitment_preview_value(candidate, "title", "", true)},
			]))
			grid.add_child(make_roster_detail_card("CandidateEquipment", "EQUIPMENT", [
				{"caption": "Summary", "value": recruitment_preview_value(candidate, "equipment_summary", "%d equipped item(s)" % equipment.size())},
				{"caption": "Item Details", "value": "%d verified" % equipment.size() if RecruitmentSystem.field_is_revealed(candidate, "equipped_items") else "Unknown"},
			]))


func show_recruitment_candidate_preview(candidate: Dictionary) -> void:
	if candidate.is_empty():
		show_tavern()
		return
	screen = "recruitment_preview"
	var hero: Dictionary = candidate.hero_record
	var hero_class := str(hero.get("class", "Guardian"))
	var class_revealed := RecruitmentSystem.field_is_revealed(candidate, "class")
	var level_revealed := RecruitmentSystem.field_is_revealed(candidate, "exact_level")
	var accent: Color = CLASSES[hero_class].color if class_revealed else C_MUTED
	var root := base_screen("Candidate Inspection", "READ-ONLY TAVERN CANDIDATE • UNKNOWN INFORMATION IS MARKED CLEARLY")
	var gap := Control.new()
	gap.custom_minimum_size.y = 16
	root.add_child(gap)
	var detail := HBoxContainer.new()
	detail.add_theme_constant_override("separation", 28)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(detail)
	var character := VBoxContainer.new()
	character.custom_minimum_size.x = 510
	character.add_theme_constant_override("separation", 8)
	detail.add_child(character)
	var identity := HBoxContainer.new()
	identity.name = "HeroIdentityRow"
	identity.add_theme_constant_override("separation", 12)
	character.add_child(identity)
	var name_label := label(str(hero.display_name), 30, accent)
	name_label.name = "HeroName"
	name_label.custom_minimum_size.x = 150
	identity.add_child(name_label)
	var level_class := label("Level %s %s" % [str(int(hero.level)) if level_revealed else "?", hero_class if class_revealed else "Unknown"], 16, C_MUTED)
	level_class.name = "HeroLevelClass"
	level_class.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(level_class)
	identity.add_child(label("?", 16, C_GOLD))
	var disclosure := ProgressBar.new()
	disclosure.name = "RecruitmentPreviewDisclosure"
	disclosure.max_value = 100
	disclosure.value = float(candidate.information_disclosure_score)
	disclosure.show_percentage = true
	disclosure.custom_minimum_size = Vector2(464, 24)
	character.add_child(disclosure)
	var status := label("Candidate • %s • %d of %d details revealed" % [str(candidate.broad_role), int(candidate.revealed_field_count), int(candidate.total_revealable_field_count)], 12, C_GOLD)
	status.custom_minimum_size.x = 464
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character.add_child(status)
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 12)
	character.add_child(equipment_row)
	var left_slots := VBoxContainer.new()
	left_slots.add_theme_constant_override("separation", 8)
	equipment_row.add_child(left_slots)
	for slot in ["head", "chest", "weapon"]:
		left_slots.add_child(make_recruitment_preview_equipment_slot(candidate, slot))
	var portrait := Button.new()
	portrait.name = "RecruitmentPreviewPortrait"
	portrait.disabled = true
	portrait.text = role_glyph(hero_class) if class_revealed else "?"
	portrait.custom_minimum_size = Vector2(230, 220)
	portrait.add_theme_font_size_override("font_size", 64)
	portrait.add_theme_stylebox_override("disabled", ui_box(Color("1a2332"), 4, accent, 2))
	equipment_row.add_child(portrait)
	var right_slots := VBoxContainer.new()
	right_slots.add_theme_constant_override("separation", 8)
	equipment_row.add_child(right_slots)
	for slot in ["neck", "hands", "trinket"]:
		right_slots.add_child(make_recruitment_preview_equipment_slot(candidate, slot))
	var stats := HBoxContainer.new()
	stats.name = "HeroStats"
	stats.custom_minimum_size.x = 464
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 8)
	character.add_child(stats)
	for stat in [["HEALTH", Color("69d69f")], ["POWER", Color("65adff")], ["ARMOR", Color("e6b85c")]]:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(71, 54)
		tile.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 4, Color("35445a"), 1))
		stats.add_child(tile)
		var tile_content := VBoxContainer.new()
		tile_content.alignment = BoxContainer.ALIGNMENT_CENTER
		tile.add_child(tile_content)
		var stat_title := label(str(stat[0]), 10, C_MUTED)
		stat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_content.add_child(stat_title)
		var stat_value := label("?", 18, stat[1])
		stat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_content.add_child(stat_value)
	var workspace := VBoxContainer.new()
	workspace.name = "RosterWorkspace"
	workspace.custom_minimum_size.x = 635
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 10)
	detail.add_child(workspace)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 7)
	workspace.add_child(tabs)
	for section in ["Details", "Talents", "Abilities", "Professions"]:
		tabs.add_child(make_recruitment_preview_section_button(section, candidate))
	var panel := PanelContainer.new()
	panel.name = "RosterWorkspacePanel"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ui_box(Color("172234"), 4, Color("35445a"), 1))
	workspace.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "RecruitmentPreviewScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "RosterSectionContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	populate_recruitment_preview_workspace(content, candidate, hero, hero_class)


func make_roster_ability_row(
	key_text: String, title: String, description: String, accent: Color, locked: bool = false, details_action: Callable = Callable()
) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "RosterTrait" if key_text == "D" else "RosterAbility%s" % key_text
	card.custom_minimum_size = Vector2(600, 58)
	card.add_theme_stylebox_override("panel", ui_box(Color("182334") if not locked else Color("151e2c"), 6, Color("35445a"), 1))
	if not locked and details_action.is_valid():
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(
			func(event):
				if (
					(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
					or (event is InputEventScreenTouch and event.pressed)
				):
					details_action.call()
		)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var badge := AbilityKeyBadge.new()
	badge.name = "AbilityKeyBadge"
	badge.configure(key_text, accent, locked)
	row.add_child(badge)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var heading := label(title, 16, C_MUTED if locked else C_TEXT)
	copy.add_child(heading)
	var body := label(description, 13, C_MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(body)
	return card


func close_roster_ability_details(overlay: Control) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


func fit_roster_ability_details(panel: PanelContainer, scroll: ScrollContainer, body: VBoxContainer) -> void:
	await get_tree().process_frame
	if not is_instance_valid(panel) or not is_instance_valid(scroll) or not is_instance_valid(body):
		return
	var body_height := body.get_combined_minimum_size().y
	var desired_height := clampf(body_height + 160.0, 230.0, 580.0)
	panel.size = Vector2(680, desired_height)
	panel.position = Vector2((W - panel.size.x) * .5, (H - panel.size.y) * .5)
	scroll.custom_minimum_size.y = minf(body_height, desired_height - 160.0)


func open_roster_ability_details(hero: Dictionary, action_key: String, heroic_id: String = "") -> void:
	var details: Dictionary
	if str(hero.get("class", "")) == "Guardian":
		details = GuardianAbilityPresenter.details(hero, action_key, heroic_id, float(hero_final_stats(hero).power))
	elif str(hero.get("class", "")) == "Cleric":
		var presenter_hero := hero.duplicate(true)
		presenter_hero["power"] = float(hero_final_stats(hero).power)
		if not presenter_hero.has("cleric_runtime"):
			ClericSystem.initialize_runtime(presenter_hero, false)
		details = ClericAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	elif str(hero.get("class", "")) == "Ranger":
		var presenter_hero := hero.duplicate(true)
		presenter_hero["ranger_runtime"] = hero.get("ranger_runtime", {})
		if presenter_hero.ranger_runtime.is_empty():
			RangerSystem.initialize_runtime(presenter_hero, is_testing_save())
		details = RangerAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	elif str(hero.get("class", "")) == "Mage":
		var presenter_hero := hero.duplicate(true)
		var presenter_stats := hero_final_stats(hero)
		presenter_hero["power"] = float(presenter_stats.power)
		presenter_hero["stats"] = presenter_stats
		presenter_hero["base_ability_power_percent"] = float(presenter_stats.get("ability_power_percent", 0.0))
		if presenter_hero.get("mage_runtime", {}).is_empty():
			MageSystem.initialize_runtime(presenter_hero, is_testing_save())
		details = MageAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	elif str(hero.get("class", "")) == "Warlock":
		var presenter_hero := hero.duplicate(true)
		var presenter_stats := hero_final_stats(hero)
		presenter_hero["power"] = float(presenter_stats.power)
		presenter_hero["stats"] = presenter_stats
		presenter_hero["max_hp"] = float(presenter_stats.health)
		presenter_hero["hp"] = float(presenter_stats.health)
		presenter_hero["ability_cds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
		WarlockSystem.initialize_runtime(presenter_hero, false)
		details = WarlockAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	elif str(hero.get("class", "")) == "Slayer":
		var presenter_hero := hero.duplicate(true)
		if presenter_hero.get("slayer_runtime", {}).is_empty():
			SlayerSystem.initialize_runtime(presenter_hero, false)
		details = SlayerAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	elif str(hero.get("class", "")) == "Priest":
		var presenter_hero:=hero.duplicate(true);var presenter_stats:=hero_final_stats(hero);presenter_hero["power"]=float(presenter_stats.power);presenter_hero["stats"]=presenter_stats;presenter_hero["ability_cds"]=[0.0,0.0,0.0,0.0,0.0]
		PriestSystem.initialize_runtime(presenter_hero,false);details=PriestAbilityPresenter.details(presenter_hero,action_key,heroic_id)
	elif str(hero.get("class", "")) == "Rogue":
		var presenter_hero := hero.duplicate(true)
		var presenter_stats := hero_final_stats(hero)
		presenter_hero["power"] = float(presenter_stats.power)
		presenter_hero["level"] = int(hero.get("level", 1))
		presenter_hero["max_hp"] = float(presenter_stats.health)
		presenter_hero["hp"] = float(presenter_stats.health)
		presenter_hero["ability_cds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
		RogueSystem.initialize_runtime(presenter_hero, false)
		details = RogueAbilityPresenter.details(presenter_hero, action_key, heroic_id)
	else:
		var action_keys: Array = ["Q", "W", "E", "R"]
		var slot := action_keys.find(action_key)
		details = {
			"key": action_key,
			"title": str(TRAITS[hero["class"]]) if action_key == "D" else str(ABILITIES[hero["class"]][slot]),
			"meta": "Passive Trait" if action_key == "D" else "Ability",
			"description": "Passive Trait" if action_key == "D" else ability_tooltip(hero["class"], slot),
			"sections": [],
			"note": ""
		}
	var overlay := Control.new()
	overlay.name = "RosterAbilityDetailsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)
	var backdrop := Button.new()
	backdrop.name = "RosterAbilityDetailsBackdrop"
	backdrop.flat = true
	backdrop.focus_mode = Control.FOCUS_NONE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_theme_stylebox_override("normal", ui_box(Color(0.01, 0.02, 0.04, .78), 0))
	backdrop.pressed.connect(func(): close_roster_ability_details(overlay))
	overlay.add_child(backdrop)
	var panel := PanelContainer.new()
	panel.name = "RosterAbilityDetailsCard"
	panel.position = Vector2(300, 230)
	panel.size = Vector2(680, 260)
	panel.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 10, CLASSES[hero["class"]].color, 2))
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var badge := AbilityKeyBadge.new()
	badge.name = "RosterAbilityDetailsBadge"
	badge.configure(str(details.key), CLASSES[hero["class"]].color, false)
	header.add_child(badge)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	identity.add_child(label(str(details.title), 27, CLASSES[hero["class"]].color))
	identity.add_child(label(str(details.meta), 14, C_MUTED))
	column.add_child(rule())
	var scroll := ScrollContainer.new()
	scroll.name = "RosterAbilityDetailsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 13)
	scroll.add_child(body)
	var description := label(str(details.description), 16, C_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(description)
	for section in details.sections:
		body.add_child(label(str(section.heading), 14, C_GOLD))
		var section_body := label(str(section.body), 14, C_MUTED)
		section_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(section_body)
	if str(details.note) != "":
		body.add_child(rule())
		var note := label(str(details.note), 12, C_MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(note)
	fit_roster_ability_details(panel, scroll, body)


func make_roster_detail_row(_caption: String, _value: String, _value_color: Color = C_TEXT) -> HBoxContainer:
	return null


func make_roster_detail_card(_card_name: String, _title: String, _rows: Array) -> PanelContainer:
	return null
