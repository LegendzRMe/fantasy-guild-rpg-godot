extends SceneTree

const BalanceReporter = preload("res://scripts/systems/balance_reporter.gd")
const BalanceSimulator = preload("res://scripts/systems/balance_simulator.gd")
const SimulationData = preload("res://scripts/data/simulation_data.gd")

func _init()->void:
	var options:=_parse_options(OS.get_cmdline_user_args())
	var iterations:=maxi(1,int(options.get("iterations",100)))
	var level:=clampi(int(options.get("level",1)),1,30)
	var output_directory:=str(options.get("output_dir","user://balance_reports"))
	var report:=BalanceSimulator.simulate_suite(SimulationData.standard_scenarios(),SimulationData.prototype_baseline_builds(level),iterations,int(options.get("seed",1337)))
	report["generated_at_utc"]=Time.get_datetime_string_from_system(true)
	report["report_label"]="Prototype Basic Action Baselines"
	report["warning"]="Temporary prototype data only. Final classes, abilities, talents, rotations, positioning, resources, passives, and utility are not represented."
	var write_result:=BalanceReporter.write_reports(report,output_directory)
	if not bool(write_result.get("success",false)):
		push_error(str(write_result.get("error","Could not write balance reports.")))
		quit(1)
		return
	print("BALANCE_SIMULATION_COMPLETE")
	print("JSON: %s"%write_result.json_path)
	print("CSV: %s"%write_result.csv_path)
	print("Results: %d"%int(report.result_count))
	quit(0)

func _parse_options(arguments:PackedStringArray)->Dictionary:
	var result:={"iterations":100,"level":1,"seed":1337,"output_dir":"user://balance_reports"}
	var index:=0
	while index<arguments.size():
		var argument:=arguments[index]
		if argument in ["--iterations","--level","--seed","--output-dir"] and index+1<arguments.size():
			var key:=argument.trim_prefix("--").replace("-","_")
			result[key]=arguments[index+1]
			index+=2
		else:index+=1
	return result
