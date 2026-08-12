extends SceneTree

const TestDruidSystem=preload("res://tests/test_druid_system.gd")

func _init()->void:
	var errors:=TestDruidSystem.run()
	if errors.is_empty():print("DRUID_TESTS_PASSED");quit(0);return
	for error in errors:push_error(str(error))
	quit(1)
