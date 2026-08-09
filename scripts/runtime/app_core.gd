extends "res://scripts/runtime/app_contracts.gd"

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
const ProfessionData = preload("res://scripts/data/profession_data.gd")
const ProfessionSystem = preload("res://scripts/systems/profession_system.gd")
const RecruitmentData = preload("res://scripts/data/recruitment_data.gd")
const RecruitmentSystem = preload("res://scripts/systems/recruitment_system.gd")
const GameClockSystem = preload("res://scripts/systems/game_clock_system.gd")
const TavernFacilityData = preload("res://scripts/data/tavern_facility_data.gd")
const TavernFacilitySystem = preload("res://scripts/systems/tavern_facility_system.gd")
const CookingData = preload("res://scripts/data/cooking_data.gd")
const CookingSystem = preload("res://scripts/systems/cooking_system.gd")
const TavernManagementData = preload("res://scripts/data/tavern_management_data.gd")
const TavernManagementSystem = preload("res://scripts/systems/tavern_management_system.gd")
const GuildHallData = preload("res://scripts/data/guild_hall_data.gd")
const CampaignData = preload("res://scripts/data/campaign_data.gd")
const CampaignSystem = preload("res://scripts/systems/campaign_system.gd")
const GuildCodexData = preload("res://scripts/data/guild_codex_data.gd")
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
const MageData = preload("res://scripts/data/mage_data.gd")
const MageSystem = preload("res://scripts/systems/mage_system.gd")
const WarlockData = preload("res://scripts/data/warlock_data.gd")
const WarlockSystem = preload("res://scripts/systems/warlock_system.gd")
const RogueData = preload("res://scripts/data/rogue_data.gd")
const RogueSystem = preload("res://scripts/systems/rogue_system.gd")
const SlayerData = preload("res://scripts/data/slayer_data.gd")
const SlayerSystem = preload("res://scripts/systems/slayer_system.gd")
const PriestData = preload("res://scripts/data/priest_data.gd")
const PriestSystem = preload("res://scripts/systems/priest_system.gd")
const ShamanData = preload("res://scripts/data/shaman_data.gd")
const ShamanSystem = preload("res://scripts/systems/shaman_system.gd")
const TemplarData = preload("res://scripts/data/templar_data.gd")
const TemplarSystem = preload("res://scripts/systems/templar_system.gd")
const ProtectorData = preload("res://scripts/data/protector_data.gd")
const ProtectorSystem = preload("res://scripts/systems/protector_system.gd")
const SentinelData = preload("res://scripts/data/sentinel_data.gd")
const SentinelSystem = preload("res://scripts/systems/sentinel_system.gd")
const HuntsmanData = preload("res://scripts/data/huntsman_data.gd")
const HuntsmanSystem = preload("res://scripts/systems/huntsman_system.gd")
const OutgoingDamageReductionSystem = preload("res://scripts/systems/outgoing_damage_reduction_system.gd")
const ProgressionScopeSystem = preload("res://scripts/systems/progression_scope_system.gd")
const EvasionSystem = preload("res://scripts/systems/evasion_system.gd")
const BlockChargeSystem = preload("res://scripts/systems/block_charge_system.gd")
const TargetCategorySystem = preload("res://scripts/systems/combat_target_category_system.gd")
const ComboPointSystem = preload("res://scripts/systems/combo_point_system.gd")
const AlternateActionSetSystem = preload("res://scripts/systems/alternate_action_set_system.gd")
const StealthDetectionSystem = preload("res://scripts/systems/stealth_detection_system.gd")
const ArmorReductionSystem = preload("res://scripts/systems/armor_reduction_system.gd")
const PeriodicStatusSystem = preload("res://scripts/systems/periodic_status_system.gd")
const AbilityPowerSystem = preload("res://scripts/systems/ability_power_system.gd")
const LivingBombLineageSystem = preload("res://scripts/systems/living_bomb_lineage_system.gd")
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
const TOTAL_SAVE_SLOT_COUNT := LIVE_SAVE_SLOT_COUNT + 1
const TESTING_MAX_HERO_LEVEL := CombatSystem.LEVEL_CAP
const TUTORIAL_MOVEMENT_REACH_RADIUS := 72.0
const OBJECTIVE_THREAT_TARGET := -2
const CHALLENGE_TAUNT_DURATION := 3.0
const TESTING_DUMMY_RESPAWN_TIME := 5.0
const TESTING_DUMMY_REGEN_DELAY := 2.5
const TESTING_DUMMY_REGEN_RATE := 0.10
const TESTING_ENDLESS_ACTIVE_LIMIT := 6
const TESTING_ENDLESS_SPAWN_INTERVAL := 1.15
const TESTING_ENDLESS_DEFEATED_CLEAR_TIME := 0.7

# Transient UI coordination belongs beside the UI/input methods that consume it.
# Declaring it here also keeps Godot hot reloads from compiling AppCore against a
# stale cached AppState layout while several descendant scripts are reloading.
var hero_roster_scroll_positions: Dictionary = {}
var victory_talent_queue: Array = []
var victory_talent_choice_index := 0
var victory_talent_overlay: Control = null
var victory_talent_prompt_handled := false
var roster_party_press_active := false
var roster_party_press_index := -1
var roster_party_press_origin := ""
var roster_party_press_time := 0.0
var roster_party_press_start := Vector2.ZERO
var guild_storage_tab := "vault"
var codex_category := "Guide"
var codex_search := ""

const ROSTER_PARTY_HOLD_DURATION := 0.24
const SAVE_DEBOUNCE_SECONDS := 5.0


func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	ui.theme = build_ui_theme()
	ui.position = Vector2.ZERO
	ui.size = Vector2(W, H)
	ui_background.name = "PersistentScreenBackground"
	ui_background.color = C_BG
	ui_background.position = Vector2.ZERO
	ui_background.size = Vector2(W, H)
	ui_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_background)
	add_child(combat_layer)
	add_child(ui)
	load_game()
	show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_pending_save()


func ui_box(color: Color, radius: int = 8, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	return UiFactory.ui_box(color, radius, border_color, border_width)


func build_ui_theme() -> Theme:
	return UiFactory.build_theme(C_TEXT, C_MUTED, C_GOLD)


func save_slot_path(slot: int) -> String:
	return SaveManager.save_slot_path(slot)


func slot_state(slot: int) -> Dictionary:
	return SaveManager.slot_state(slot)


func default_casting_settings() -> Dictionary:
	return SaveManager.default_casting_settings()


func fresh_state() -> Dictionary:
	return SaveManager.fresh_state()


func load_game() -> void:
	state = SaveManager.load_state(current_save_slot)
	persistence.reset()


func persist_current_team() -> void:
	state.selected_team = TeamManager.sanitize_team(state.selected_team, state.heroes)
	if current_team_slot < 0:
		state.active_team = state.selected_team.duplicate()
	else:
		state.saved_teams[current_team_slot] = state.selected_team.duplicate()
	save_game()


func mark_save_dirty() -> void:
	persistence.mark_dirty()


func save_game() -> bool:
	var saved := persistence.save(current_save_slot, state)
	if saved:
		return true
	toast = "SAVE FAILED — RETRYING"
	toast_time = 5.0
	queue_redraw()
	return false


func flush_pending_save() -> bool:
	return true if not persistence.dirty else save_game()


func is_testing_save() -> bool:
	return current_save_slot == TESTING_SAVE_SLOT


func open_save_slot(slot: int) -> void:
	current_save_slot = slot
	load_game()
	if slot == TESTING_SAVE_SLOT and state.guild_name == "":
		state = SaveManager.testing_state()
		save_game()
		show_hall()
	elif state.guild_name == "":
		show_creation()
	elif not bool(state.get("tutorial_complete", true)):
		start_tutorial()
	else:
		show_hall()


func request_delete_save(slot: int) -> void:
	var saved = slot_state(slot)
	if saved.is_empty():
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete Saved Guild"
	dialog.dialog_text = ("Are you sure you want to delete %s?\nThis cannot be undone." % saved.get("guild_name", "this guild"))
	dialog.ok_button_text = "Delete"
	dialog.confirmed.connect(
		func():
			SaveManager.delete_slot(slot)
			if current_save_slot == slot:
				state = fresh_state()
			show_menu()
	)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(460, 210))


func clear_all() -> void:
	vault_slot_controls.clear()
	vault_page_controls.clear()
	storage_panes.clear()
	item_card_overlay = null
	item_carousel_track = null
	roster_section_scroll = null
	guild_hall_scroll_hint = null
	for c in ui.get_children():
		if c != ui_background:
			c.queue_free()
	for c in combat_layer.get_children():
		c.queue_free()
	heroes.clear()
	enemies.clear()
	effects.clear()
	focused_enemy_index = -1
	combat_layer.visible = false
	ui.visible = true
	queue_redraw()


func base_screen(title: String, subtitle: String = "") -> VBoxContainer:
	clear_all()
	var root := VBoxContainer.new()
	root.position = Vector2(32, 22)
	root.size = Vector2(1216, 676)
	root.add_theme_constant_override("separation", 14)
	ui.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var t := label(title, 32, C_TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	if screen == "menu":
		top.add_child(button("×", func(): get_tree().quit(), 64))
	elif screen == "settings":
		top.add_child(button("Return to Guild Hall", show_hall, 210))
	elif screen == "hall":
		top.add_child(button("×", show_menu, 64))
	elif screen == "zone_map":
		top.add_child(button("Return", show_dungeons, 130))
	elif screen == "campaign_region":
		top.add_child(button("World Map", show_dungeons, 150))
	elif screen in ["campaign_location","campaign_decision","campaign_settlement","campaign_operation"]:
		top.add_child(button("Region Map", func():show_campaign_region(campaign_current_region), 160))
	elif screen == "testing_zone_menu":
		top.add_child(button("Return", show_dungeons, 130))
	elif screen == "encounter_intro":
		top.add_child(button("Return", func(): show_zone_map(0), 130))
	elif screen == "recruitment_preview":
		top.add_child(button("Return to Tavern", show_tavern, 190))
	elif screen in ["ashwood_victory", "ashwood_consequence"]:
		pass
	else:
		top.add_child(button("Return to Guild Hall", show_hall, 210))
	if subtitle != "":
		root.add_child(label(subtitle, 16, C_MUTED))
	if persistence.failure_message != "":
		var save_warning := label("SAVE WARNING — " + persistence.failure_message, 14, C_RED)
		save_warning.name = "SaveFailureWarning"
		save_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(save_warning)
	var header_space := Control.new()
	header_space.custom_minimum_size.y = 14
	root.add_child(header_space)
	return root


func label(text: String, size: int = 18, color: Color = C_TEXT) -> Label:
	return UiFactory.label(text, size, color)


func rule() -> HSeparator:
	return UiFactory.rule()


func button(text: String, callback: Callable, width: float = 180) -> Button:
	return UiFactory.button(text, callback, width)


func panel() -> VBoxContainer:
	return UiFactory.panel(C_PANEL)


func show_menu() -> void:
	screen = "menu"
	var root = base_screen("FANTASY GUILD")
	root.add_spacer(false)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 14)
	root.add_child(slots)
	for slot in TOTAL_SAVE_SLOT_COUNT:
		var saved = slot_state(slot)
		var card := Button.new()
		card.custom_minimum_size = Vector2(280, 210)
		card.add_theme_font_size_override("font_size", 22)
		var slot_title := "TESTING" if slot == TESTING_SAVE_SLOT else "SAVE %d" % (slot + 1)
		if saved.is_empty() or str(saved.get("guild_name", "")) == "":
			card.text = ("%s\n\nEverything Unlocked" % slot_title if slot == TESTING_SAVE_SLOT else "%s\n\nNew Guild" % slot_title)
		else:
			card.text = ("%s\n\n%s\n●  %d" % [slot_title, saved.get("guild_name", "Unnamed Guild"), saved.get("gold", 0)])
			var delete_button := Button.new()
			delete_button.text = "×"
			delete_button.position = Vector2(234, 8)
			delete_button.size = Vector2(38, 38)
			delete_button.add_theme_font_size_override("font_size", 22)
			delete_button.tooltip_text = "Delete saved guild"
			delete_button.mouse_filter = Control.MOUSE_FILTER_STOP
			delete_button.pressed.connect(func(i = slot): request_delete_save(i))
			card.add_child(delete_button)
		card.pressed.connect(func(i = slot): open_save_slot(i))
		slots.add_child(card)
	root.add_spacer(false)


func casting_option(device: String, category: String, choices: Array) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(250, 44)
	for choice in choices:
		option.add_item(choice[0])
		option.set_item_metadata(option.item_count - 1, choice[1])
	var current = str(state.casting_settings[device][category])
	for i in option.item_count:
		if option.get_item_metadata(i) == current:
			option.select(i)
	option.item_selected.connect(
		func(index: int):
			state.casting_settings[device][category] = option.get_item_metadata(index)
			save_game()
	)
	return option


func show_settings() -> void:
	screen = "settings"
	var root = base_screen("Casting Settings")
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	root.add_child(columns)
	var categories = {"Ground Targeted": "ground", "Directional": "directional", "Area Around Hero": "area", "Enemy Targeted": "enemy", "Ally Targeted": "ally"}
	for device in ["pc", "mobile"]:
		var section := VBoxContainer.new()
		section.custom_minimum_size.x = 560
		section.add_theme_constant_override("separation", 10)
		columns.add_child(section)
		section.add_child(label("PC" if device == "pc" else "MOBILE", 24, C_GOLD))
		section.add_child(label("Self-cast abilities are always instant.", 15, C_MUTED))
		for title in categories:
			var row := HBoxContainer.new()
			section.add_child(row)
			var name_label = label(title, 17, C_TEXT)
			name_label.custom_minimum_size.x = 260
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(name_label)
			var category = categories[title]
			var choices: Array
			if category == "enemy" or category == "ally":
				choices = [["Cast on Target", "target"], ["Confirm Targeting", "confirm"]]

			elif category == "area":
				choices = [["Instant", "instant"], ["Cast on Release", "release"], ["Confirm Cast", "confirm"]]
			elif device == "mobile":
				choices = [["Facing Direction", "facing"], ["Cast on Release", "release"], ["Confirm Location", "confirm"]]
			else:
				choices = [["Cast on Cursor", "cursor"], ["Cast on Release", "release"], ["Confirm Location", "confirm"]]
			row.add_child(casting_option(device, category, choices))
	root.add_spacer(false)
	var reset := button(
		"Reset Defaults",
		func():
			state.casting_settings = default_casting_settings()
			save_game()
			show_settings(),
		190
	)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(reset)


func show_creation() -> void:
	screen = "creation"
	var root = base_screen("Create Your Guild")
	var box = panel()
	box.custom_minimum_size = Vector2(650, 400)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(box)
	box.add_child(label("Guild name", 18, C_GOLD))
	var guild_name_input := LineEdit.new()
	guild_name_input.placeholder_text = "The Dawnwardens"
	guild_name_input.text = "The Dawnwardens"
	guild_name_input.custom_minimum_size.y = 48
	box.add_child(guild_name_input)
	box.add_child(label("Four volunteers have answered your banner: a Guardian, Cleric, Ranger, and Mage.", 16, C_MUTED))
	box.add_spacer(false)
	box.add_child(
		button(
			"Found Guild",
			func():
				state = fresh_state()
				state.guild_name = (guild_name_input.text.strip_edges() if guild_name_input.text.strip_edges() != "" else "Unnamed Guild")
				save_game()
				start_tutorial(),
			240
		)
	)


func hub_button(title: String, caption: String, callback: Callable, locked: bool = false) -> Button:
	var b := Button.new()
	b.text = title if caption == "" else "%s\n%s" % [title, caption]
	b.custom_minimum_size = Vector2(260, 125)
	b.add_theme_font_size_override("font_size", 19)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(callback)
	if locked:
		b.disabled = true
		b.tooltip_text = "Locked"
		b.add_theme_color_override("font_disabled_color", Color("667187"))
		var veil := ColorRect.new()
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.color = Color(0.025, 0.032, 0.05, .78)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(veil)
		var lock_overlay := LockOverlay.new()
		lock_overlay.name = "LockOverlay"
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(lock_overlay)
	return b


func show_guild_page_intro(page_id: String) -> void:
	if not GameData.GUILD_PAGE_INTROS.has(page_id):
		return
	var intro: Dictionary = GameData.GUILD_PAGE_INTROS[page_id]
	var dialog := AcceptDialog.new()
	dialog.name = "GuildPageIntro"
	dialog.title = str(intro.title)
	dialog.dialog_text = str(intro.body)
	dialog.ok_button_text = "Continue"
	dialog.min_size = Vector2i(560, 250)
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(560, 250))


func open_guild_page(page_id: String, page_callback: Callable) -> void:
	var first_visit := not bool(state.seen_page_intros.get(page_id, false))
	if first_visit:
		state.seen_page_intros[page_id] = true
		save_game()
	page_callback.call()
	if first_visit:
		show_guild_page_intro(page_id)
