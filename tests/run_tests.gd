extends SceneTree

const Main = preload("res://scripts/main.gd")
const TestAshwoodManager = preload("res://tests/test_ashwood_manager.gd")
const TestBalanceSimulator = preload("res://tests/test_balance_simulator.gd")
const TestBalanceLab = preload("res://tests/test_balance_lab.gd")
const TestCombatSystem = preload("res://tests/test_combat_system.gd")
const TestClericSystem = preload("res://tests/test_cleric_system.gd")
const TestStatusEffectSystem = preload("res://tests/test_status_effect_system.gd")
const TestGameDefaults = preload("res://tests/test_game_defaults.gd")
const TestGuardianSystem = preload("res://tests/test_guardian_system.gd")
const TestInventorySystem = preload("res://tests/test_inventory_system.gd")
const TestItemCardView = preload("res://tests/test_item_card_view.gd")
const TestPrestigeSystem = preload("res://tests/test_prestige_system.gd")
const TestPrestigeRewards = preload("res://tests/test_prestige_rewards.gd")
const TestRosterManager = preload("res://tests/test_roster_manager.gd")
const TestSaveManager = preload("res://tests/test_save_manager.gd")
const TestSharedCombatRulesV1 = preload("res://tests/test_shared_combat_rules_v1.gd")
const TestTeamManager = preload("res://tests/test_team_manager.gd")
const TestTalentSystem = preload("res://tests/test_talent_system.gd")
const TestUiSmoke = preload("res://tests/test_ui_smoke.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors:=[]
	errors.append_array(TestAshwoodManager.run())
	errors.append_array(TestBalanceSimulator.run())
	errors.append_array(TestCombatSystem.run())
	errors.append_array(TestClericSystem.run())
	errors.append_array(TestGameDefaults.run())
	errors.append_array(TestGuardianSystem.run())
	errors.append_array(TestInventorySystem.run())
	errors.append_array(TestItemCardView.run())
	errors.append_array(TestPrestigeSystem.run())
	errors.append_array(TestPrestigeRewards.run())
	errors.append_array(TestRosterManager.run())
	errors.append_array(TestSaveManager.run())
	errors.append_array(TestSharedCombatRulesV1.run())
	errors.append_array(TestStatusEffectSystem.run())
	errors.append_array(TestTeamManager.run())
	errors.append_array(TestTalentSystem.run())

	var main:=Main.new()
	root.add_child(main)
	await process_frame
	errors.append_array(await TestUiSmoke.run(main))
	main.queue_free()
	await process_frame
	errors.append_array(await TestBalanceLab.run(self))
	# Give standalone UI resources one idle frame to release before the headless
	# SceneTree exits; otherwise the dummy renderer reports false-positive leaks.
	await process_frame

	if errors.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for message in errors:
		push_error(message)
	print("TEST_FAILURES: %d" % errors.size())
	quit(1)
