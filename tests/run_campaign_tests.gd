extends SceneTree

const TestCampaignSystem = preload("res://tests/test_campaign_system.gd")

func _init()->void:
	call_deferred("_run")

func _run()->void:
	var errors:=TestCampaignSystem.run()
	if errors.is_empty():print("CAMPAIGN_TESTS_PASSED");quit(0);return
	for message in errors:push_error(message)
	print("CAMPAIGN_TEST_FAILURES: %d"%errors.size());quit(1)
