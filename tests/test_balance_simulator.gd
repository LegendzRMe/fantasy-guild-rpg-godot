extends RefCounted

const BalanceReporter = preload("res://scripts/systems/balance_reporter.gd")
const BalanceSimulator = preload("res://scripts/systems/balance_simulator.gd")
const ClassData = preload("res://scripts/data/class_data.gd")
const SimulationData = preload("res://scripts/data/simulation_data.gd")
const TestSupport = preload("res://tests/test_support.gd")

static func run()->Array:
	var errors:=[]
	var damage_scenario:Dictionary=SimulationData.STANDARD_SCENARIOS.single_target_120.duplicate(true)
	damage_scenario.duration=10.0
	var guardian_build:Dictionary=SimulationData.prototype_baseline_builds(1).filter(func(build):return build.class_id=="guardian")[0]
	var first:=BalanceSimulator.simulate(guardian_build,damage_scenario,20,9001)
	var second:=BalanceSimulator.simulate(guardian_build,damage_scenario,20,9001)
	TestSupport.check(errors,first.mean_per_second>0.0 and first.mean_per_second==second.mean_per_second,"Balance simulations should be deterministic for the same seed and produce Basic Attack output.")
	TestSupport.check(errors,first.by_action.has("guardian_basic_attack") and first.iterations==20,"Balance reports should include per-action breakdowns and iteration metadata.")

	var ability_build:=guardian_build.duplicate(true)
	ability_build.build_id="synthetic_ability_fixture"
	ability_build.actions=[{"action_id":"test_strike","result_category":"damage","source_action":"basic_ability","power_coefficient":2.0,"cooldown":5.0,"priority":1,"damage_type":"physical"}]
	var ability_result:=BalanceSimulator.simulate(ability_build,damage_scenario,1,5)
	TestSupport.check(errors,ability_result.by_action.has("test_strike") and ability_result.mean_per_second>first.mean_per_second,"Future class abilities should plug into the simulator as data without changing its engine.")
	TestSupport.check(errors,ability_result.by_action.test_strike.cast_count==3.0 and ability_result.by_action.test_strike.result_count==3.0,"Single-target actions should report casts and resolved hits independently.")
	var multi_target_scenario:=damage_scenario.duplicate(true)
	multi_target_scenario.targets.append({"target_id":"second_dummy","max_health":1000000000.0,"armor":0.0})
	ability_build.actions[0].max_targets=2
	var multi_target_result:=BalanceSimulator.simulate(ability_build,multi_target_scenario,1,5)
	TestSupport.check(errors,multi_target_result.by_action.test_strike.cast_count==3.0 and multi_target_result.by_action.test_strike.result_count==6.0,"Multi-target actions should not inflate their cast count when one cast resolves against several targets.")

	var healing_scenario:Dictionary=SimulationData.STANDARD_SCENARIOS.sustained_tank_healing_120.duplicate(true)
	healing_scenario.duration=10.0
	var cleric_build:Dictionary=SimulationData.prototype_baseline_builds(1).filter(func(build):return build.class_id=="cleric")[0]
	var healing_result:=BalanceSimulator.simulate(cleric_build,healing_scenario,5,77)
	TestSupport.check(errors,healing_result.mode=="healing" and healing_result.mean_effective_output>0.0 and healing_result.mean_wasted_output>=0.0,"Healing scenarios should report effective healing and overhealing separately.")
	var full_health_scenario:=healing_scenario.duplicate(true)
	full_health_scenario.targets[0].initial_health_percent=1.0
	full_health_scenario.targets[0].incoming_damage=0.0
	var healing_ability_build:=cleric_build.duplicate(true)
	healing_ability_build.actions=[{"action_id":"test_heal","result_category":"healing","source_action":"basic_ability","power_coefficient":2.0,"cooldown":2.0}]
	var full_health_result:=BalanceSimulator.simulate(healing_ability_build,full_health_scenario,1,1)
	TestSupport.check(errors,not full_health_result.event_limit_reached and full_health_result.mean_effective_output==0.0,"A ready heal with no injured target should wait safely instead of stalling the simulator.")

	var suite:=BalanceSimulator.simulate_suite([damage_scenario,healing_scenario],[guardian_build,cleric_build],2,1)
	TestSupport.check(errors,suite.result_count==2,"A suite should skip incompatible Basic Action/scenario combinations.")
	var csv:=BalanceReporter.to_csv(suite)
	TestSupport.check(errors,csv.contains("scenario_id") and csv.contains("single_target_120") and csv.contains("sustained_tank_healing_120"),"Balance reports should export spreadsheet-friendly CSV rows.")
	return errors
