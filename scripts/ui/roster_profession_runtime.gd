extends "res://scripts/ui/roster_talent_runtime.gd"


func profession_trainer_is_unlocked(profession_id: String) -> bool:
	if profession_id == "cooking":
		return true
	if is_testing_save():
		return true
	var trainer: Dictionary = ProfessionData.TRAINERS.get(profession_id, {})
	var encounter_id := str(trainer.get("unlock_encounter", ""))
	return encounter_id != "" and AshwoodManager.encounter_is_completed(state.zone0, encounter_id)


func request_roster_profession_training(hero_id: String, profession_id: String) -> void:
	var hero_index := ProfessionSystem.hero_index(state, hero_id)
	if hero_index < 0 or not profession_trainer_is_unlocked(profession_id):
		return
	var hero: Dictionary = state.heroes[hero_index]
	var trainer: Dictionary = ProfessionData.TRAINERS[profession_id]
	var profession_name := ProfessionData.profession_name(profession_id)
	var dialog := ConfirmationDialog.new()
	dialog.name = "ProfessionTrainingJourneyDialog"
	dialog.title = "TRAVEL TO THE %s TRAINER?" % profession_name.to_upper()
	dialog.dialog_text = (
		"%s will leave the guild to visit %s in the %s and learn %s for %d Gold.\n\nA Hero may train only one profession at a time. This introductory journey resolves immediately; future rank training can require longer trips."
		% [hero.display_name, str(trainer.trainer_name), str(trainer.location), profession_name, ProfessionData.LEARN_COST]
	)
	dialog.ok_button_text = "Begin Training Journey"
	dialog.confirmed.connect(
		func():
			var result: Dictionary = ProfessionSystem.learn_profession(state, hero_id, profession_id)
			if bool(result.success):
				save_game()
				selected_roster_index = hero_index
				hero_roster_section = "Professions"
				show_roster()
				flash("%s returned as a trained %s." % [hero.display_name, profession_name])
			else:
				flash(str(result.reason))
	)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(650, 330))


func populate_untrained_roster_professions(content: VBoxContainer, hero: Dictionary) -> void:
	content.add_theme_constant_override("separation", 6)
	var intro := label("CHOOSE ONE PROFESSION", 18, C_GOLD)
	content.add_child(intro)
	var explanation := label("One per Hero • Trainers unlock through quests and exploration.", 12, C_MUTED)
	content.add_child(explanation)
	var grid := GridContainer.new()
	grid.name = "RosterProfessionChoices"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for profession_id in ProfessionData.PROFESSIONS:
		var definition: Dictionary = ProfessionData.PROFESSIONS[profession_id]
		var trainer: Dictionary = ProfessionData.TRAINERS[profession_id]
		var unlocked := profession_trainer_is_unlocked(profession_id)
		var card := PanelContainer.new()
		card.name = "RosterProfessionCard_%s" % profession_id
		card.custom_minimum_size = Vector2(260, 86)
		card.add_theme_stylebox_override("panel", ui_box(Color("1b283a"), 5, C_GOLD if unlocked else Color("35445a"), 2 if unlocked else 1))
		grid.add_child(card)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 2)
		card.add_child(card_content)
		card_content.add_child(label(str(definition.display_name), 17, C_GOLD if unlocked else C_MUTED))
		card_content.add_child(
			label(str(trainer.location) if unlocked else "Trainer locked", 11, C_MUTED)
		)
		var train := compact_button(
			"Train • %d Gold" % ProfessionData.LEARN_COST if unlocked else "Trainer Locked",
			func(id = profession_id): request_roster_profession_training(str(hero.hero_id), id),
			155
		)
		train.name = "RosterProfessionChoice_%s" % profession_id
		train.custom_minimum_size.y = 28
		train.disabled = (not unlocked or int(state.gold) < ProfessionData.LEARN_COST or str(hero.get("activity", "")) != "")
		train.tooltip_text = (
			"Only one profession may be trained at a time."
			if unlocked and int(state.gold) >= ProfessionData.LEARN_COST
			else ("Requires %d Gold." % ProfessionData.LEARN_COST if unlocked else str(trainer.unlock_hint))
		)
		card_content.add_child(train)


func populate_roster_profession(content: VBoxContainer, hero: Dictionary) -> void:
	var hero_id := str(hero.hero_id)
	var current: Dictionary = ProfessionSystem.progress(state, hero_id)
	if str(current.profession_id) == "":
		populate_untrained_roster_professions(content, hero)
		return
	var profession_id := str(current.profession_id)
	var definition: Dictionary = ProfessionData.PROFESSIONS[profession_id]
	content.add_child(label("%s  •  Rank %d" % [str(definition.display_name), int(current.profession_rank)], 24, C_GOLD))
	content.add_child(label("Specialization lean  •  %s" % ProfessionSystem.specialization_lean(current), 14, C_MUTED))
	content.add_child(label("Activity  •  %s" % ProfessionSystem.member_activity(state, hero_id), 14, C_TEXT))
	var next_rank := mini(5, int(current.profession_rank) + 1)
	var requirement: Dictionary = ProfessionData.RANK_REQUIREMENTS[next_rank]
	var xp := ProgressBar.new()
	xp.name = "ProfessionXP"
	xp.custom_minimum_size = Vector2(560, 28)
	xp.max_value = int(requirement.xp)
	xp.value = int(current.profession_xp)
	xp.show_percentage = false
	content.add_child(xp)
	content.add_child(label("Profession XP  •  %d / %d" % [int(current.profession_xp), int(requirement.xp)], 13, C_MUTED))
	var status: Dictionary = ProfessionSystem.rank_requirement_status(state, hero_id, next_rank)
	content.add_child(label("Next Rank  •  %s" % str(status.reason), 14, C_GREEN if bool(status.met) else C_MUTED))
	content.add_child(label("MILESTONES", 13, C_GOLD))
	for milestone in ["profession_introduction", "first_order", "advanced_work", "pattern_mastered", "signature_work"]:
		content.add_child(
			label(
				"%s  %s" % ["✓" if milestone in current.profession_milestones else "○", milestone.replace("_", " ").capitalize()],
				13,
				C_GREEN if milestone in current.profession_milestones else C_MUTED
			)
		)
	content.add_child(label("PROTOTYPE PROFESSION TREE", 13, C_GOLD))
	var choices: Array = ProfessionData.CHOICES[profession_id]
	for rank_index in 5:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		content.add_child(row)
		var rank_label := label("R%d" % (rank_index + 1), 13, C_GOLD if int(current.profession_rank) >= rank_index + 1 else C_MUTED)
		rank_label.custom_minimum_size.x = 34
		row.add_child(rank_label)
		for choice in choices[rank_index]:
			var chosen := str(current.profession_choices.get(str(rank_index + 1), ""))
			var option := compact_button(str(choice.name), func(rank = rank_index + 1, id = str(choice.id)): select_profession_choice(hero_id, rank, id), 245)
			option.disabled = (int(current.profession_rank) < rank_index + 1 or (chosen != "" and chosen != str(choice.id)))
			option.tooltip_text = (
				str(choice.description) if int(current.profession_rank) >= rank_index + 1 else "Requires Profession Rank %d." % (rank_index + 1)
			)
			if chosen == str(choice.id):
				option.add_theme_color_override("font_color", C_GREEN)
			row.add_child(option)
	content.add_child(
		label(
			(
				"Known actions  •  %s"
				% (
					", ".join(current.known_personal_techniques)
					if not current.known_personal_techniques.is_empty()
					else "Select a rank choice to unlock techniques."
				)
			),
			13,
			C_TEXT
		)
	)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	actions.add_child(compact_button("Open Workshop", show_crafting, 140))
	if profession_id == "forgecraft":
		actions.add_child(compact_button("Separate Item", func(): request_profession_item_action(hero_id, "separate"), 135))
	elif profession_id == "enchanting":
		actions.add_child(compact_button("Inspect / Prepare", func(): prepare_prototype_parent_set(hero_id), 150))
		actions.add_child(compact_button("Disenchant Item", func(): request_profession_item_action(hero_id, "disenchant"), 145))
	elif profession_id == "alchemy":
		actions.add_child(compact_button("Purify", func(): perform_alchemy_choice_action(hero_id, "purify"), 105))
		actions.add_child(compact_button("Convert", func(): perform_alchemy_choice_action(hero_id, "convert"), 105))
	if not state.rune_collection.is_empty():
		content.add_child(label("RUNE LOADOUT  •  presentation only; mechanics retain the original ability ID", 13, Color("c692ff")))
		var ability_id := "%s:q" % str(hero.class_id)
		for rune_id in state.rune_collection:
			var rune: Dictionary = ProfessionData.RUNES.get(rune_id, {})
			if str(rune.get("ability_id", "")) != ability_id:
				continue
			var equipped := str(current.rune_loadout.get(ability_id, "")) == str(rune_id)
			content.add_child(
				compact_button(
					("Remove " if equipped else "Equip ") + str(rune.display_name),
					func(id = str(rune_id), remove = equipped): equip_member_rune(hero_id, ability_id, "" if remove else id),
					210
				)
			)
	content.add_child(rule())
	var unlearn := compact_button("Unlearn Profession • %d Gold" % ProfessionData.UNLEARN_COST, func(): request_unlearn_profession(hero_id), 240)
	unlearn.add_theme_color_override("font_color", C_RED)
	content.add_child(unlearn)


func select_profession_choice(hero_id: String, rank: int, choice_id: String) -> void:
	var result: Dictionary = ProfessionSystem.choose_specialization(state, hero_id, rank, choice_id)
	if bool(result.success):
		save_game()
		refresh_roster_preserving_scroll()
	else:
		flash(str(result.reason))


func equip_member_rune(hero_id: String, ability_id: String, rune_id: String) -> void:
	var result: Dictionary = ProfessionSystem.apply_rune(state, hero_id, ability_id, rune_id)
	if bool(result.success):
		save_game()
		refresh_roster_preserving_scroll()
		flash("Rune presentation updated; ability mechanics are unchanged.")
	else:
		flash(str(result.reason))


func perform_alchemy_choice_action(hero_id: String, action: String) -> void:
	var result: Dictionary = ProfessionSystem.purify_material(state, hero_id) if action == "purify" else ProfessionSystem.convert_material(state, hero_id)
	if bool(result.success):
		save_game()
		refresh_roster_preserving_scroll()
		flash(str(result.reason))
	else:
		flash(str(result.reason))


func populate_roster_workspace(content: VBoxContainer, hero: Dictionary, info: Dictionary) -> void:
	var resolved_stats := hero_final_stats(hero)
	content.add_theme_constant_override("separation", 10)
	match hero_roster_section:
		"Abilities":
			var trait_name: String = (
				"Stoneform" if hero["class"] == "Guardian" and GuardianSystem.has_talent(hero, "guardian_l24_2") else str(TRAITS[hero["class"]])
			)
			if hero["class"] == "Cleric" and ClericSystem.has_talent(hero, "cleric_l12_2"):
				trait_name = "Safety Sprint"
			elif hero["class"] == "Cleric" and ClericSystem.has_talent(hero, "cleric_l12_3"):
				trait_name = "Let's Go!"
			elif hero["class"] == "Warlock":
				trait_name = "Life Tap"
			var trait_text: String = GuardianData.TALENT_DESCRIPTIONS.guardian_l24_2 if trait_name == "Stoneform" else "Passive Trait"
			if hero["class"] == "Cleric" and trait_name == "Safety Sprint":
				trait_text = str(ClericData.TALENT_DESCRIPTIONS.cleric_l12_2)
			elif hero["class"] == "Cleric" and trait_name == "Let's Go!":
				trait_text = str(ClericData.TALENT_DESCRIPTIONS.cleric_l12_3)
			elif hero["class"] == "Warlock":
				trait_text = "Sacrifice 13% of maximum Health to accelerate eligible cooldowns."
			var class_color: Color = CLASSES[hero["class"]].color
			for slot in 3:
				var required_level := int(TalentSystem.ABILITY_UNLOCK_LEVELS[slot])
				var locked := int(hero.get("level", 1)) < required_level
				var description := ability_tooltip(hero["class"], slot)
				if locked:
					description = "Unlocks at Level %d  •  %s" % [required_level, description]
				var action_key: String = ["Q", "W", "E"][slot]
				var base_ability_name := str(ABILITIES[hero["class"]][slot])
				var ability_id := "%s:%s" % [str(hero.class_id), ["q", "w", "e"][slot]]
				var presentation: Dictionary = ProfessionSystem.ability_presentation(state, str(hero.hero_id), ability_id, base_ability_name)
				var shown_name := (
					str(presentation.display_name) + ("  " + str(presentation.get("symbol", "")) if str(presentation.get("rune_id", "")) != "" else "")
				)
				content.add_child(
					make_roster_ability_row(
						action_key, shown_name, description, class_color, locked, func(key = action_key): open_roster_ability_details(hero, key)
					)
				)
			var selected_heroic_id := str(hero.get("selected_heroic_id", ""))
			var heroic_unlocked := TalentSystem.ability_is_unlocked(int(hero.get("level", 1)), 3)
			if heroic_unlocked and selected_heroic_id != "":
				var heroic_name := (
					guardian_talent_name(selected_heroic_id)
					if hero["class"] in ["Guardian", "Cleric", "Rogue", "Ranger", "Mage", "Warlock"]
					else str(ABILITIES[hero["class"]][3])
				)
				var heroic_description := (
					str(GuardianData.TALENT_DESCRIPTIONS.get(selected_heroic_id, ability_tooltip(hero["class"], 3)))
					if hero["class"] == "Guardian"
					else (
						str(ClericData.TALENT_DESCRIPTIONS.get(selected_heroic_id, ability_tooltip(hero["class"], 3)))
						if hero["class"] == "Cleric"
						else (
							str(RangerData.TALENT_DESCRIPTIONS.get(selected_heroic_id, ability_tooltip(hero["class"], 3)))
							if hero["class"] == "Ranger"
							else (
								str(MageData.TALENT_DESCRIPTIONS.get(selected_heroic_id, ability_tooltip(hero["class"], 3)))
								if hero["class"] == "Mage"
								else (
									str(WarlockData.TALENT_DESCRIPTIONS.get(selected_heroic_id, ability_tooltip(hero["class"], 3)))
									if hero["class"] == "Warlock"
									else ability_tooltip(hero["class"], 3)
								)
							)
						)
					)
				)
				content.add_child(
					make_roster_ability_row(
						"R",
						heroic_name,
						heroic_description,
						class_color,
						false,
						func(heroic = selected_heroic_id): open_roster_ability_details(hero, "R", heroic)
					)
				)
			else:
				content.add_child(
					make_roster_ability_row(
						"R", "Heroic Ability", "Choose your Heroic at Level %d." % int(TalentSystem.ABILITY_UNLOCK_LEVELS[3]), class_color, true
					)
				)
			content.add_child(make_roster_ability_row("D", trait_name, trait_text, class_color, false, func(): open_roster_ability_details(hero, "D")))
		"Talents":
			var class_definition: Dictionary = GameData.class_definition(str(hero["class"]))
			var class_id := str(class_definition.get("class_id", GameData.class_id_for(str(hero["class"]))))
			var discovery: Dictionary = state.get("class_talent_discovery", {})
			for tier_number in range(1, 9):
				content.add_child(make_roster_talent_tier(hero, class_definition, class_id, discovery, tier_number, selected_roster_index))
		"Professions":
			populate_roster_profession(content, hero)
		_:
			var action_is_heal: bool = str(resolved_stats.basic_action_type) == "heal"
			var action_title := "BASIC HEAL" if action_is_heal else "BASIC ATTACK"
			var action_rows: Array = [
				{
					"caption": "Healing" if action_is_heal else "Damage",
					"value": str(int(floor(float(resolved_stats.basic_action_amount)))),
					"color": C_GREEN if action_is_heal else C_TEXT
				},
				{"caption": "Interval", "value": "%.2f sec" % resolved_stats.basic_action_interval},
				{"caption": "Range", "value": str(int(resolved_stats.basic_action_range))}
			]
			if not action_is_heal:
				action_rows.append({"caption": "Damage Type", "value": str(resolved_stats.basic_action_damage_type).capitalize()})
			if hero["class"] == "Mage":
				var roster_ability_power := (
					float(resolved_stats.get("ability_power_percent", 0.0)) + (0.04 if "mage_l9_2" in hero.get("selected_talents", {}).values() else 0.0)
				)
				action_rows.append({"caption": "Ability Power", "value": "%.0f%%" % (roster_ability_power * 100.0), "color": CLASSES.Mage.color})
			var defense_rows: Array = [
				{"caption": "Armor Rating", "value": "%.0f" % resolved_stats.armor},
				{"caption": "Damage Reduction", "value": "%d%%" % int(round(resolved_stats.armor_reduction * 100.0)), "color": Color("e6b85c")},
				{"caption": "Movement Speed", "value": str(int(resolved_stats.movement_speed))},
				{"caption": "Threat Generation", "value": "%.2fx" % resolved_stats.threat_modifier}
			]
			if float(resolved_stats.health_regeneration) > 0.0:
				defense_rows.append({"caption": "Health Regeneration", "value": str(int(floor(float(resolved_stats.health_regeneration)))), "color": C_GREEN})
			var critical_rows: Array = [
				{"caption": "Chance", "value": "%.1f%%" % (resolved_stats.critical_chance * 100.0)},
				{"caption": "Critical Result", "value": "%.0f%%" % (resolved_stats.critical_damage * 100.0)}
			]
			var concise_weapon_names: Dictionary = {
				"weapon_and_shield": "Shield", "one_handed": "1-Handed", "two_handed": "2-Handed", "dual_wield": "Dual Wield"
			}
			var weapon_names: Array = resolved_stats.weapon_proficiencies.map(
				func(weapon): return str(concise_weapon_names.get(str(weapon), str(weapon).replace("_", " ").capitalize()))
			)
			var proficiency_rows: Array = [
				{"caption": "Armor", "value": str(resolved_stats.armor_family).capitalize()}, {"caption": "Weapons", "value": ", ".join(weapon_names)}
			]
			var details_grid := GridContainer.new()
			details_grid.name = "RosterDetailsGrid"
			details_grid.columns = 2
			details_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			details_grid.add_theme_constant_override("h_separation", 10)
			details_grid.add_theme_constant_override("v_separation", 8)
			content.add_child(details_grid)
			details_grid.add_child(make_roster_detail_card("Action", action_title, action_rows))
			details_grid.add_child(make_roster_detail_card("Defense", "DEFENSE & MOVEMENT", defense_rows))
			details_grid.add_child(make_roster_detail_card("Critical", "CRITICALS", critical_rows))
			details_grid.add_child(make_roster_detail_card("Proficiencies", "PROFICIENCIES", proficiency_rows))
			var equipped := hero_equipped_items(hero)
			if not equipped.is_empty():
				content.add_child(label("ACTIVE ITEM EFFECTS", 14, C_GOLD))
				var effect_grid := GridContainer.new()
				effect_grid.name = "RosterItemEffects"
				effect_grid.columns = 2
				effect_grid.add_theme_constant_override("h_separation", 10)
				effect_grid.add_theme_constant_override("v_separation", 8)
				content.add_child(effect_grid)
				for item in equipped:
					var passive_names: Array = item.get("passive_effect_ids", []).map(
						func(passive_id): return str(ItemData.PASSIVE_EFFECTS.get(passive_id, {}).get("display_name", passive_id))
					)
					var effect_card := Label.new()
					effect_card.text = ("%s\n%s" % [item.display_name, " • ".join(passive_names) if not passive_names.is_empty() else "No passive effect"])
					effect_card.custom_minimum_size = Vector2(280, 52)
					effect_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					effect_card.add_theme_font_size_override("font_size", 13)
					effect_card.add_theme_color_override("font_color", Color(ItemData.RARITY_COLORS.get(str(item.get("rarity", "Common")), "e9f1ff")))
					effect_card.add_theme_stylebox_override("normal", ui_box(Color("182334"), 5, Color("35445a"), 1))
					effect_grid.add_child(effect_card)
			if is_testing_save():
				content.add_child(rule())
				content.add_child(label("TESTING TOOLS", 13, Color("b381ff")))
				var level_row := HBoxContainer.new()
				level_row.add_theme_constant_override("separation", 12)
				content.add_child(level_row)
				var level_caption := label("Hero Level", 15, C_TEXT)
				level_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				level_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				level_row.add_child(level_caption)
				var level_picker := SpinBox.new()
				level_picker.name = "TestingHeroLevel"
				level_picker.min_value = 1
				level_picker.max_value = TESTING_MAX_HERO_LEVEL
				level_picker.step = 1
				level_picker.allow_greater = false
				level_picker.allow_lesser = false
				level_picker.value = int(hero.level)
				level_picker.custom_minimum_size = Vector2(105, 40)
				level_picker.value_changed.connect(func(value, hero_index = selected_roster_index): set_testing_hero_level(hero_index, value))
				level_row.add_child(level_picker)
				content.add_child(compact_button("Toggle Special Hero", func(): toggle_test_special_hero(selected_roster_index), 190))


func make_roster_detail_card(_card_name: String, _title: String, _rows: Array) -> PanelContainer:
	return null
