extends SceneTree

const Main = preload("res://scripts/main.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const WARMUP_FRAMES := 120
const SAMPLE_FRAMES := 600
const FIXED_DELTA := 1.0/60.0

func _init()->void:
	call_deferred("run_profile")

func output_path()->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):return argument.trim_prefix("--output=")
	return ProjectSettings.globalize_path("res://build/performance/latest.json")

func percentile(sorted_values:Array[float],ratio:float)->float:
	if sorted_values.is_empty():return 0.0
	return sorted_values[clampi(int(ceil((sorted_values.size()-1)*ratio)),0,sorted_values.size()-1)]

func node_count(node:Node)->int:
	var total:=1
	for child in node.get_children():total+=node_count(child)
	return total

func sample_scenario(app:Node,scenario_name:String)->Dictionary:
	for frame in WARMUP_FRAMES:app._process(FIXED_DELTA)
	var samples:Array[float]=[]
	var total_microseconds:=0.0
	for frame in SAMPLE_FRAMES:
		var started:=Time.get_ticks_usec()
		app._process(FIXED_DELTA)
		var elapsed:=float(Time.get_ticks_usec()-started)
		samples.append(elapsed);total_microseconds+=elapsed
	samples.sort()
	return {
		"scenario":scenario_name,
		"samples":SAMPLE_FRAMES,
		"fixed_delta_seconds":FIXED_DELTA,
		"update_ms_mean":total_microseconds/float(SAMPLE_FRAMES)/1000.0,
		"update_ms_median":percentile(samples,.50)/1000.0,
		"update_ms_p95":percentile(samples,.95)/1000.0,
		"update_ms_p99":percentile(samples,.99)/1000.0,
		"update_ms_max":samples[-1]/1000.0,
		"scene_nodes":node_count(app),
		"heroes":app.heroes.size(),
		"enemies":app.enemies.size(),
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	}

func fresh_app()->Node:
	var app:=Main.new()
	root.add_child(app)
	app.set_process(false)
	app.current_save_slot=3
	app.state=SaveManager.testing_state()
	return app

func run_profile()->void:
	seed(20260730)
	var scenarios:Array=[]
	var app:=fresh_app();await process_frame
	app.show_hall();await process_frame
	scenarios.append(sample_scenario(app,"guild_hall_idle"))
	app.free()

	app=fresh_app();await process_frame
	app.start_testing_zone();await process_frame
	scenarios.append(sample_scenario(app,"testing_range_four_heroes"))
	app.free()

	app=fresh_app();await process_frame
	app.start_testing_endless(30)
	for extra_enemy in 8:app.spawn_testing_endless_enemy()
	app.testing_endless_spawn_timer=INF
	for hero in app.heroes:hero.suppress_auto_target=true;hero.target=-1;hero.dest=hero.pos
	for enemy in app.enemies:enemy.max_hp=1000000000.0;enemy.hp=enemy.max_hp;enemy.damage=0.0;enemy.basic_action_amount=0.0
	await process_frame
	scenarios.append(sample_scenario(app,"endless_level_30_twelve_enemies"))
	app.free()

	var report:={
		"format_version":1,
		"project_version":str(ProjectSettings.get_setting("application/config/version","development")),
		"godot_version":Engine.get_version_info().get("string","unknown"),
		"platform":OS.get_name(),
		"processor_count":OS.get_processor_count(),
		"captured_utc":Time.get_datetime_string_from_system(true),
		"mode":"headless deterministic application-update benchmark",
		"warmup_frames":WARMUP_FRAMES,
		"scenarios":scenarios
	}
	var path:=output_path();DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:push_error("Unable to write performance report: %s"%path);quit(1);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("PERFORMANCE_PROFILE_WRITTEN: %s"%path)
	quit(0)
