extends SceneTree

func _init()->void:
	# This project composes the application through one long inheritance chain.
	# Prime every layer from the root so a clean Godot cache can discover a newly
	# inserted class runtime without transient unresolved-parent diagnostics.
	var independent_paths:=[
		"res://scripts/data/monk_data.gd","res://scripts/data/monk_ability_presenter.gd","res://scripts/systems/monk_system.gd","res://tests/test_monk_system.gd","res://tests/test_ui_monk_runtime.gd","res://scripts/data/vanguard_data.gd","res://scripts/data/vanguard_ability_presenter.gd","res://scripts/systems/vanguard_system.gd","res://tests/test_vanguard_system.gd","res://tests/test_ui_vanguard_runtime.gd"
	]
	for path in independent_paths:
		if load(path)==null:push_error("Unable to prime dependency: "+path);quit(1);return
	var chain_paths:=[
		"res://scripts/runtime/app_state.gd","res://scripts/runtime/app_contracts.gd","res://scripts/runtime/app_core.gd","res://scripts/runtime/app_team_interaction_runtime.gd","res://scripts/runtime/app_vault_interaction_runtime.gd","res://scripts/runtime/app_interaction_runtime.gd",
		"res://scripts/ui/guild_hall_runtime.gd","res://scripts/ui/item_equipment_runtime.gd","res://scripts/ui/roster_ability_runtime.gd","res://scripts/ui/roster_talent_runtime.gd","res://scripts/ui/roster_profession_runtime.gd","res://scripts/ui/hero_roster_screen.gd","res://scripts/ui/team_builder_screen.gd","res://scripts/ui/world_map_screen.gd","res://scripts/ui/campaign_screen.gd","res://scripts/ui/profession_screen.gd","res://scripts/ui/tavern_screen.gd","res://scripts/ui/item_storage_screen.gd",
		"res://scripts/runtime/app_shell.gd","res://scripts/runtime/battle_setup.gd","res://scripts/runtime/tutorial_controller.gd","res://scripts/runtime/shared_combat_runtime.gd","res://scripts/runtime/item_combat_runtime.gd","res://scripts/runtime/enemy_combat_runtime.gd","res://scripts/runtime/guardian_runtime.gd","res://scripts/runtime/cleric_runtime.gd","res://scripts/runtime/ranger_runtime.gd","res://scripts/runtime/mage_runtime.gd","res://scripts/runtime/warlock_runtime.gd","res://scripts/runtime/rogue_runtime.gd","res://scripts/runtime/slayer_runtime.gd","res://scripts/runtime/priest_runtime.gd","res://scripts/runtime/shaman_runtime.gd","res://scripts/runtime/templar_runtime.gd","res://scripts/runtime/protector_runtime.gd","res://scripts/runtime/sentinel_runtime.gd","res://scripts/runtime/huntsman_runtime.gd","res://scripts/runtime/druid_runtime.gd","res://scripts/runtime/warrior_runtime.gd","res://scripts/runtime/death_knight_runtime.gd","res://scripts/runtime/beastmaster_runtime.gd","res://scripts/runtime/monk_runtime.gd","res://scripts/runtime/vanguard_runtime.gd","res://scripts/runtime/ability_runtime.gd","res://scripts/runtime/combat_input_runtime.gd","res://scripts/runtime/combat_runtime.gd","res://scripts/runtime/ashwood_runtime.gd","res://scripts/runtime/campaign_runtime.gd","res://scripts/runtime/victory_runtime.gd","res://scripts/runtime/combat_effect_presentation.gd","res://scripts/runtime/combat_presentation.gd","res://scripts/main.gd"
	]
	for path in chain_paths:
		if load(path)==null:push_error("Unable to prime dependency: "+path);quit(1);return
	print("DEPENDENCIES_PRIMED")
	quit()
