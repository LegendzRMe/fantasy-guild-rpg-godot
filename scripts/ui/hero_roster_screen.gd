extends "res://scripts/ui/roster_profession_runtime.gd"

const EquipmentSlotSilhouette = preload("res://scripts/ui/equipment_slot_silhouette.gd")


func make_roster_card(idx: int) -> Button:
	var h = state.heroes[idx]
	var card := Button.new()
	card.custom_minimum_size = Vector2(132, 74)
	card.text = ("%s\n%s\n%s  •  Level %d" % [role_glyph(h["class"]), h["name"], h["class"], h["level"]])
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_font_size_override("font_size", 13)
	card.add_theme_color_override("font_color", CLASSES[h["class"]].color if idx == selected_roster_index else C_TEXT)
	card.add_theme_stylebox_override("normal", ui_box(Color("202d42"), 4, Color("35445a"), 1))
	card.add_theme_stylebox_override("hover", ui_box(Color("293a53"), 4, CLASSES[h["class"]].color, 1))
	card.add_theme_stylebox_override("pressed", ui_box(Color("172131"), 4, CLASSES[h["class"]].color, 2))
	var is_party_member := hero_is_on_active_team(idx)
	var active_star := Button.new()
	active_star.name = "ActiveTeamStar"
	active_star.text = "★" if is_party_member else "☆"
	active_star.position = Vector2(94, 0)
	active_star.size = Vector2(36, 34)
	active_star.flat = true
	active_star.focus_mode = Control.FOCUS_NONE
	active_star.tooltip_text = ("Remove from selected party" if is_party_member else "Add to selected party")
	active_star.add_theme_font_size_override("font_size", 20)
	active_star.add_theme_color_override("font_color", C_GOLD if is_party_member else C_MUTED)
	active_star.gui_input.connect(
		func(event, i = idx):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				begin_roster_party_press(i, "reserve", event.position)
			elif event is InputEventScreenTouch and event.pressed:
				begin_roster_party_press(i, "reserve", event.position)
	)
	card.add_child(active_star)
	if idx == selected_roster_index:
		card.add_theme_stylebox_override("normal", ui_box(Color("26384e"), 4, CLASSES[h["class"]].color, 2))
	card.pressed.connect(
		func():
			remember_roster_scroll()
			selected_roster_index = idx
			show_roster()
	)
	return card


func select_roster_team_option(option: int) -> void:
	current_team_slot = clampi(option, 0, 4) - 1
	state.selected_team = TeamManager.sanitize_team(state.active_team if current_team_slot < 0 else state.saved_teams[current_team_slot], state.heroes)
	if current_team_slot < 0:
		state.active_team = state.selected_team.duplicate()
	else:
		state.saved_teams[current_team_slot] = state.selected_team.duplicate()
	hero_roster_page = 0
	save_game()
	show_roster()


func make_roster_party_summary() -> VBoxContainer:
	var summary := VBoxContainer.new()
	summary.name = "RosterPartySummary"
	summary.custom_minimum_size.x = 220
	summary.add_theme_constant_override("separation", 3)
	var teams := OptionButton.new()
	teams.name = "RosterTeamSelector"
	teams.custom_minimum_size = Vector2(142, 30)
	teams.size_flags_horizontal = Control.SIZE_SHRINK_END
	for option_index in 5:
		teams.add_item(str(state.team_names[option_index]))
	teams.select(clampi(current_team_slot + 1, 0, 4))
	teams.item_selected.connect(select_roster_team_option)
	apply_sharp_compact_style(teams)
	summary.add_child(teams)
	var party_name := str(state.team_names[clampi(current_team_slot + 1, 0, 4)]).to_upper()
	var title := label("★  %s  %d / 4" % [party_name, state.selected_team.size()], 14, C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.add_child(title)
	var members := HBoxContainer.new()
	members.name = "RosterPartyMembers"
	members.alignment = BoxContainer.ALIGNMENT_END
	members.add_theme_constant_override("separation", 5)
	summary.add_child(members)
	team_active_zone = members
	team_active_row = members
	for hero_index_value in state.selected_team:
		var hero_index := int(hero_index_value)
		if hero_index < 0 or hero_index >= state.heroes.size():
			continue
		var hero: Dictionary = state.heroes[hero_index]
		var member := Button.new()
		member.name = "RosterPartyMember%d" % hero_index
		member.text = role_glyph(str(hero.get("class", "")))
		member.custom_minimum_size = Vector2(46, 40)
		member.focus_mode = Control.FOCUS_NONE
		member.tooltip_text = ("%s — click to remove, or hold and drag to reorder" % str(hero.get("name", "Hero")))
		member.add_theme_font_size_override("font_size", 17)
		member.add_theme_color_override("font_color", CLASSES[hero["class"]].color)
		member.add_theme_stylebox_override("normal", ui_box(Color("202d42"), 4, CLASSES[hero["class"]].color, 2))
		member.add_theme_stylebox_override("hover", ui_box(Color("293a53"), 4, C_GOLD, 2))
		member.gui_input.connect(
			func(event, i = hero_index):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					begin_roster_party_press(i, "active", event.position)
				elif event is InputEventScreenTouch and event.pressed:
					begin_roster_party_press(i, "active", event.position)
		)
		members.add_child(member)
	for empty_slot in range(state.selected_team.size(), 4):
		var empty := Button.new()
		empty.disabled = true
		empty.custom_minimum_size = Vector2(46, 40)
		empty.add_theme_stylebox_override("disabled", ui_box(Color("172131"), 4, Color("35445a"), 1))
		members.add_child(empty)
	return summary


func roster_display_indices() -> Array:
	var filtered_sorted: Array = sorted_hero_indices()
	var party_members: Array = []
	for hero_index_value in state.selected_team:
		var hero_index := int(hero_index_value)
		if hero_index in filtered_sorted and hero_index not in party_members:
			party_members.append(hero_index)
	var reserves: Array = filtered_sorted.filter(func(hero_index): return int(hero_index) not in party_members)
	return party_members + reserves


func make_hero_experience_bar(hero: Dictionary, width: float = 330, height: float = 24) -> Control:
	var experience_max: int = max(1, int(hero.level) * 100)
	var experience_value: int = clampi(int(hero.get("xp", 0)), 0, experience_max)
	var container := Control.new()
	container.name = "HeroExperience"
	container.custom_minimum_size = Vector2(width, height)
	var bar := ProgressBar.new()
	bar.name = "HeroExperienceBar"
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.max_value = experience_max
	bar.value = experience_value
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", ui_box(Color("111a28"), 4, Color("2c3a4e"), 1))
	bar.add_theme_stylebox_override("fill", ui_box(Color("326fae"), 4))
	container.add_child(bar)
	var amount := Label.new()
	amount.name = "HeroExperienceText"
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount.text = "XP   %d / %d" % [experience_value, experience_max]
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.add_theme_font_size_override("font_size", 12)
	amount.add_theme_color_override("font_color", C_MUTED)
	container.add_child(amount)
	return container


func select_roster_section(section: String) -> void:
	remember_roster_scroll()
	hero_roster_section = section
	show_roster()


func make_roster_section_button(section: String) -> Button:
	var section_button := compact_button(section, func(): select_roster_section(section), 125)
	section_button.name = "RosterSection" + section
	apply_sharp_compact_style(section_button)
	if hero_roster_section == section:
		section_button.add_theme_color_override("font_color", C_GOLD)
		section_button.add_theme_stylebox_override("normal", ui_box(Color("2b3b52"), 4, C_GOLD, 2))
	return section_button


func make_roster_detail_row(caption: String, value: String, value_color: Color = C_TEXT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "RosterDetailRow" + caption.replace(" ", "").replace("&", "")
	row.custom_minimum_size.y = 21
	row.add_theme_constant_override("separation", 8)
	var caption_label := label(caption, 12, C_MUTED)
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption_label)
	var value_label := label(value, 13, value_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.custom_minimum_size.x = 90
	row.add_child(value_label)
	return row


func make_roster_detail_card(card_name: String, title: String, rows: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "RosterDetails" + card_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(280, 0)
	card.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 6, Color("35445a"), 1))
	var card_content := VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 3)
	card.add_child(card_content)
	var heading := label(title, 13, C_GOLD)
	heading.name = "RosterDetails" + card_name + "Heading"
	heading.add_theme_color_override("font_outline_color", Color("111827"))
	heading.add_theme_constant_override("outline_size", 2)
	card_content.add_child(heading)
	card_content.add_child(rule())
	for row_data in rows:
		card_content.add_child(make_roster_detail_row(str(row_data.caption), str(row_data.value), row_data.get("color", C_TEXT)))
	return card


func append_roster_detail_group(card: PanelContainer, group_name: String, title: String, rows: Array) -> void:
	var card_content: VBoxContainer = card.get_child(0)
	var group_gap := Control.new()
	group_gap.custom_minimum_size.y = 6
	card_content.add_child(group_gap)
	var heading := label(title, 15, C_GOLD)
	heading.name = "RosterDetails" + group_name + "Heading"
	heading.add_theme_color_override("font_outline_color", Color("111827"))
	heading.add_theme_constant_override("outline_size", 2)
	card_content.add_child(heading)
	card_content.add_child(rule())
	for row_data in rows:
		card_content.add_child(make_roster_detail_row(str(row_data.caption), str(row_data.value), row_data.get("color", C_TEXT)))


func make_roster_equipment_slot(hero: Dictionary, slot: String) -> Button:
	var gear := Button.new()
	gear.name = "HeroEquipmentSlot" + slot.capitalize()
	gear.custom_minimum_size = Vector2(105, 70)
	gear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear.text = ""
	gear.focus_mode = Control.FOCUS_NONE
	var equipped_item := equipped_item_in_slot(hero, slot)
	gear.pressed.connect(func(): select_equipment_slot(slot))
	var frame_color := Color("35445a") if equipped_item.is_empty() else Color(ItemData.RARITY_COLORS.get(str(equipped_item.get("rarity", "Common")), "e9f1ff"))
	gear.add_theme_stylebox_override("normal", ui_box(Color("202d42"), 4, frame_color, 2 if not equipped_item.is_empty() else 1))
	gear.add_theme_stylebox_override("hover", ui_box(Color("26364e"), 4, frame_color, 3 if not equipped_item.is_empty() else 2))
	var slot_icon: Control
	if equipped_item.is_empty():
		var silhouette := EquipmentSlotSilhouette.new()
		silhouette.configure(slot)
		slot_icon = silhouette
		slot_icon.position = Vector2(13, 5)
		slot_icon.size = Vector2(78, 60)
	else:
		slot_icon = item_icon_control(equipped_item, Vector2(78, 60))
		slot_icon.position = Vector2(13, 5)
		slot_icon.size = Vector2(78, 60)
	slot_icon.name = "HeroEquipmentIcon"
	slot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear.add_child(slot_icon)
	return gear


func show_roster() -> void:
	screen = "roster"
	var root = base_screen("Hero Roster")
	var roster_header := Control.new()
	roster_header.name = "RosterHeader"
	roster_header.custom_minimum_size.y = 140
	root.add_child(roster_header)
	var roster_filters := filter_bar(show_roster, true, true, true)
	roster_filters.position = Vector2.ZERO
	roster_filters.size = Vector2(826, 32)
	roster_header.add_child(roster_filters)
	for filter_control in roster_filters.get_children():
		filter_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var party_summary := make_roster_party_summary()
	party_summary.position = Vector2(996, 0)
	party_summary.size = Vector2(220, 116)
	roster_header.add_child(party_summary)
	var carousel := HBoxContainer.new()
	carousel.position = Vector2(0, 54)
	carousel.size = Vector2(940, 74)
	carousel.add_theme_constant_override("separation", 8)
	roster_header.add_child(carousel)
	team_reserve_zone = carousel
	var previous_page := compact_button(
		"←",
		func():
			hero_roster_page = max(0, hero_roster_page - 1)
			show_roster(),
		42
	)
	apply_sharp_compact_style(previous_page)
	carousel.add_child(previous_page)
	var cards := GridContainer.new()
	cards.columns = 6
	cards.custom_minimum_size.x = 832
	cards.add_theme_constant_override("h_separation", 8)
	cards.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	carousel.add_child(cards)
	var indices = roster_display_indices()
	var pages = max(1, int(ceil(indices.size() / 6.0)))
	hero_roster_page = clampi(hero_roster_page, 0, pages - 1)
	if not indices.is_empty() and not indices.has(selected_roster_index):
		selected_roster_index = indices[0]
	for card_index in range(hero_roster_page * 6, min(indices.size(), hero_roster_page * 6 + 6)):
		cards.add_child(make_roster_card(indices[card_index]))
	var next_page := compact_button(
		"→",
		func():
			hero_roster_page = min(pages - 1, hero_roster_page + 1)
			show_roster(),
		42
	)
	apply_sharp_compact_style(next_page)
	carousel.add_child(next_page)
	if indices.is_empty():
		var empty_result := label("No heroes match the current filters.", 18, C_MUTED)
		empty_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(empty_result)
		return
	if selected_roster_index >= state.heroes.size():
		selected_roster_index = 0
	var hero = state.heroes[selected_roster_index]
	var info = CLASSES[hero["class"]]
	var resolved_stats := hero_final_stats(hero)
	var roster_detail_gap := Control.new()
	roster_detail_gap.name = "RosterDetailGap"
	roster_detail_gap.custom_minimum_size.y = 16
	root.add_child(roster_detail_gap)
	var detail := HBoxContainer.new()
	detail.add_theme_constant_override("separation", 28)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(detail)
	var character := VBoxContainer.new()
	character.custom_minimum_size.x = 510
	character.add_theme_constant_override("separation", 8)
	detail.add_child(character)
	var identity_row := HBoxContainer.new()
	identity_row.name = "HeroIdentityRow"
	identity_row.add_theme_constant_override("separation", 12)
	character.add_child(identity_row)
	var hero_name := label(hero["name"], 30, info.color)
	hero_name.name = "HeroName"
	hero_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	hero_name.custom_minimum_size.x = 95
	hero_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity_row.add_child(hero_name)
	var level_class := label("Level %d %s" % [hero.level, hero["class"]], 16, C_MUTED)
	level_class.name = "HeroLevelClass"
	level_class.autowrap_mode = TextServer.AUTOWRAP_OFF
	level_class.custom_minimum_size.x = 155
	level_class.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity_row.add_child(level_class)
	var identity_space := Control.new()
	identity_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(identity_space)
	var prestige := label(PrestigeSystem.stars(hero), 16, C_GOLD)
	prestige.name = "HeroPrestige"
	prestige.tooltip_text = "Prestige"
	prestige.autowrap_mode = TextServer.AUTOWRAP_OFF
	prestige.custom_minimum_size.x = 70
	prestige.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prestige.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	identity_row.add_child(prestige)
	var experience_row := HBoxContainer.new()
	experience_row.name = "HeroExperienceRow"
	experience_row.custom_minimum_size.x = 464
	experience_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	experience_row.alignment = BoxContainer.ALIGNMENT_CENTER
	character.add_child(experience_row)
	var experience := make_hero_experience_bar(hero, 330, 24)
	experience_row.add_child(experience)
	var tavern_status:=TavernFacilitySystem.member_status(state,str(hero.hero_id));var status_label:=label(str(tavern_status.label),12,C_GREEN if str(tavern_status.status) in ["available","well_rested"] else C_GOLD);status_label.name="HeroTavernStatus";status_label.custom_minimum_size.x=464;status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;character.add_child(status_label)
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 12)
	character.add_child(equipment_row)
	var left_slots := VBoxContainer.new()
	left_slots.add_theme_constant_override("separation", 8)
	equipment_row.add_child(left_slots)
	for slot in ["head", "chest", "weapon"]:
		left_slots.add_child(make_roster_equipment_slot(hero, slot))
	var portrait := Button.new()
	portrait.name = "HeroPortrait"
	portrait.text = role_glyph(hero["class"])
	portrait.disabled = true
	portrait.custom_minimum_size = Vector2(230, 220)
	portrait.add_theme_font_size_override("font_size", 64)
	portrait.add_theme_stylebox_override("disabled", ui_box(Color("1a2332"), 4, Color("35445a"), 1))
	if bool(hero.get("is_special_hero", false)):
		portrait.tooltip_text = "Prestige hero"
		portrait.add_theme_stylebox_override("disabled", ui_box(Color("1a2332"), 110, C_GOLD, 6))
	equipment_row.add_child(portrait)
	var right_slots := VBoxContainer.new()
	right_slots.add_theme_constant_override("separation", 8)
	equipment_row.add_child(right_slots)
	for slot in ["neck", "hands", "trinket"]:
		right_slots.add_child(make_roster_equipment_slot(hero, slot))
	var stats_row := HBoxContainer.new()
	stats_row.name = "HeroStats"
	stats_row.custom_minimum_size.x = 464
	stats_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stats_row.add_theme_constant_override("separation", 0)
	character.add_child(stats_row)
	var stats_indent := Control.new()
	stats_indent.custom_minimum_size.x = 117
	stats_row.add_child(stats_indent)
	var stats_group := HBoxContainer.new()
	stats_group.name = "HeroStatsGroup"
	stats_group.custom_minimum_size = Vector2(230, 54)
	stats_group.add_theme_constant_override("separation", 8)
	stats_row.add_child(stats_group)
	var stat_values := [
		{"title": "HEALTH", "value": int(resolved_stats.health), "color": Color("69d69f")},
		{"title": "POWER", "value": int(resolved_stats.power), "color": Color("65adff")},
		{"title": "ARMOR", "value": "%d%%" % int(round(resolved_stats.armor_reduction * 100.0)), "color": Color("e6b85c")}
	]
	for stat in stat_values:
		var tile := PanelContainer.new()
		tile.name = "HeroStat" + str(stat.title).capitalize()
		tile.custom_minimum_size = Vector2(71, 54)
		tile.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 4, Color("35445a"), 1))
		stats_group.add_child(tile)
		var tile_content := VBoxContainer.new()
		tile_content.alignment = BoxContainer.ALIGNMENT_CENTER
		tile_content.add_theme_constant_override("separation", 0)
		tile.add_child(tile_content)
		var stat_title := label(str(stat.title), 10, C_MUTED)
		stat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_content.add_child(stat_title)
		var stat_value := label(str(stat.value), 18, stat.color)
		stat_value.name = "HeroStat" + str(stat.title).capitalize() + "Value"
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
		tabs.add_child(make_roster_section_button(section))
	var workspace_panel := PanelContainer.new()
	workspace_panel.name = "RosterWorkspacePanel"
	workspace_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_panel.add_theme_stylebox_override("panel", ui_box(Color("172234"), 4, Color("35445a"), 1))
	workspace.add_child(workspace_panel)
	var workspace_margin := MarginContainer.new()
	workspace_margin.add_theme_constant_override("margin_left", 18)
	workspace_margin.add_theme_constant_override("margin_right", 18)
	workspace_margin.add_theme_constant_override("margin_top", 14)
	workspace_margin.add_theme_constant_override("margin_bottom", 14)
	workspace_panel.add_child(workspace_margin)
	var section_scroll := ScrollContainer.new()
	section_scroll.name = "RosterSectionScroll"
	section_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_margin.add_child(section_scroll)
	roster_section_scroll = section_scroll
	var section_content := VBoxContainer.new()
	section_content.name = "RosterSectionContent"
	section_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_scroll.add_child(section_content)
	populate_roster_workspace(section_content, hero, info)
	restore_roster_scroll(section_scroll, "%d:%s" % [selected_roster_index, hero_roster_section])
