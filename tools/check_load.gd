extends SceneTree

func _init()->void:
	for sentinel_path in ["res://scripts/data/sentinel_data.gd","res://scripts/data/sentinel_ability_presenter.gd","res://scripts/systems/outgoing_damage_reduction_system.gd","res://scripts/systems/sentinel_system.gd","res://scripts/runtime/sentinel_runtime.gd"]:
		if load(sentinel_path)==null:push_error("Unable to prime dependency: "+sentinel_path);quit(1);return
	for druid_path in ["res://scripts/data/druid_data.gd","res://scripts/systems/druid_system.gd","res://scripts/runtime/druid_runtime.gd"]:
		if load(druid_path)==null:push_error("Unable to prime dependency: "+druid_path);quit(1);return
	for path in ["res://scripts/data/profession_data.gd","res://scripts/systems/profession_system.gd","res://scripts/runtime/app_state.gd","res://scripts/runtime/app_contracts.gd","res://scripts/runtime/app_core.gd","res://scripts/runtime/app_team_interaction_runtime.gd","res://scripts/runtime/app_vault_interaction_runtime.gd","res://scripts/runtime/app_interaction_runtime.gd","res://scripts/ui/guild_hall_runtime.gd","res://scripts/ui/item_equipment_runtime.gd","res://scripts/ui/roster_ability_runtime.gd","res://scripts/ui/roster_talent_runtime.gd","res://scripts/ui/roster_profession_runtime.gd","res://scripts/ui/hero_roster_screen.gd","res://scripts/ui/team_builder_screen.gd","res://scripts/ui/world_map_screen.gd","res://scripts/ui/profession_screen.gd","res://scripts/ui/item_storage_screen.gd","res://scripts/runtime/app_shell.gd","res://scripts/runtime/battle_setup.gd","res://scripts/runtime/tutorial_controller.gd","res://scripts/runtime/shared_combat_runtime.gd","res://scripts/runtime/item_combat_runtime.gd","res://scripts/runtime/enemy_combat_runtime.gd","res://scripts/runtime/ability_runtime.gd","res://scripts/runtime/combat_input_runtime.gd","res://scripts/runtime/combat_runtime.gd","res://scripts/runtime/ashwood_runtime.gd","res://scripts/runtime/victory_runtime.gd","res://scripts/runtime/combat_effect_presentation.gd","res://scripts/runtime/combat_presentation.gd","res://scripts/main.gd"]:
		var resource=load(path)
		if resource==null:push_error("Unable to prime dependency: "+path);quit(1);return
	print("DEPENDENCIES_PRIMED")
	quit()
