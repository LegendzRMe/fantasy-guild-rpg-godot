extends RefCounted

const TestUiGuildHall = preload("res://tests/test_ui_guild_hall.gd")
const TestUiRosterTeam = preload("res://tests/test_ui_roster_team.gd")
const TestUiAshwood = preload("res://tests/test_ui_ashwood.gd")
const TestUiStorage = preload("res://tests/test_ui_storage.gd")
const TestUiCombat = preload("res://tests/test_ui_combat.gd")
const TestUiDruidRuntime = preload("res://tests/test_ui_druid_runtime.gd")
const TestUiWarriorRuntime = preload("res://tests/test_ui_warrior_runtime.gd")
const TestUiTestingTools = preload("res://tests/test_ui_testing_tools.gd")
const TestUiCampaign = preload("res://tests/test_ui_campaign.gd")

static func run(main:Node) -> Array:
	var errors:=[]
	errors.append_array(await TestUiGuildHall.run(main))
	errors.append_array(await TestUiRosterTeam.run(main))
	errors.append_array(await TestUiAshwood.run(main))
	errors.append_array(await TestUiStorage.run(main))
	errors.append_array(await TestUiCombat.run(main))
	errors.append_array(await TestUiDruidRuntime.run(main))
	errors.append_array(await TestUiWarriorRuntime.run(main))
	errors.append_array(await TestUiTestingTools.run(main))
	errors.append_array(await TestUiCampaign.run(main))
	return errors
