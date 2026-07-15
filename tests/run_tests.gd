extends SceneTree

const Main = preload("res://scripts/main.gd")
const TestAshwoodManager = preload("res://tests/test_ashwood_manager.gd")
const TestGameDefaults = preload("res://tests/test_game_defaults.gd")
const TestRosterManager = preload("res://tests/test_roster_manager.gd")
const TestSaveManager = preload("res://tests/test_save_manager.gd")
const TestTeamManager = preload("res://tests/test_team_manager.gd")
const TestUiSmoke = preload("res://tests/test_ui_smoke.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors:=[]
	errors.append_array(TestAshwoodManager.run())
	errors.append_array(TestGameDefaults.run())
	errors.append_array(TestRosterManager.run())
	errors.append_array(TestSaveManager.run())
	errors.append_array(TestTeamManager.run())

	var main:=Main.new()
	root.add_child(main)
	await process_frame
	errors.append_array(await TestUiSmoke.run(main))
	main.queue_free()
	await process_frame

	if errors.is_empty():
		print("ALL_TESTS_PASSED")
		quit(0)
		return
	for message in errors:
		push_error(message)
	print("TEST_FAILURES: %d" % errors.size())
	quit(1)
