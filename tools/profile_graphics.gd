extends SceneTree

const Main = preload("res://scripts/main.gd")
const SaveManager = preload("res://scripts/systems/save_manager.gd")
const WARMUP_FRAMES := 180
const SAMPLE_FRAMES := 900
const FINAL_HOLD_SECONDS := 5.0


func _init() -> void:
	call_deferred("run_profile")


func output_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return ProjectSettings.globalize_path("res://build/performance/graphics_latest.json")


func percentile(sorted_values: Array[float], ratio: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	return sorted_values[clampi(int(ceil((sorted_values.size() - 1) * ratio)), 0, sorted_values.size() - 1)]


func summarize(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"mean": 0.0, "median": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	values.sort()
	var total := 0.0
	for value in values:
		total += value
	return {
		"mean": total / float(values.size()),
		"median": percentile(values, 0.50),
		"p95": percentile(values, 0.95),
		"p99": percentile(values, 0.99),
		"max": values[-1],
	}


func node_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += node_count(child)
	return total


func sample_scenario(app: Node, scenario_name: String) -> Dictionary:
	for _frame in WARMUP_FRAMES:
		await process_frame

	var frame_ms: Array[float] = []
	var render_setup_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var primitives: Array[float] = []
	var previous_tick := Time.get_ticks_usec()
	for _frame in SAMPLE_FRAMES:
		await process_frame
		var current_tick := Time.get_ticks_usec()
		frame_ms.append(float(current_tick - previous_tick) / 1000.0)
		previous_tick = current_tick
		render_setup_ms.append(RenderingServer.get_frame_setup_time_cpu())
		draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitives.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))

	var frame_summary := summarize(frame_ms)
	return {
		"scenario": scenario_name,
		"samples": SAMPLE_FRAMES,
		"frame_ms": frame_summary,
		"estimated_fps_mean": 1000.0 / maxf(float(frame_summary.mean), 0.001),
		"render_setup_cpu_ms": summarize(render_setup_ms),
		"draw_calls": summarize(draw_calls),
		"primitives": summarize(primitives),
		"scene_nodes": node_count(app),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_memory_bytes": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"buffer_memory_bytes": int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
		"heroes": app.heroes.size(),
		"enemies": app.enemies.size(),
	}


func stabilize_battle(app: Node) -> void:
	app.testing_endless_spawn_timer = INF
	for hero in app.heroes:
		hero.suppress_auto_target = true
		hero.target = -1
		hero.dest = hero.pos
	for enemy in app.enemies:
		enemy.max_hp = 1000000000.0
		enemy.hp = enemy.max_hp
		enemy.damage = 0.0
		enemy.basic_action_amount = 0.0


func run_profile() -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		push_error("The graphics profile must run in a visible, non-headless session.")
		quit(1)
		return

	seed(20260730)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var app := Main.new()
	root.add_child(app)
	await process_frame
	app.current_save_slot = 3
	app.state = SaveManager.testing_state()

	var scenarios: Array = []
	app.show_hall()
	scenarios.append(await sample_scenario(app, "guild_hall_idle"))

	app.start_testing_zone()
	stabilize_battle(app)
	scenarios.append(await sample_scenario(app, "testing_range_four_heroes"))

	app.start_testing_endless(30)
	for _extra_enemy in 8:
		app.spawn_testing_endless_enemy()
	stabilize_battle(app)
	scenarios.append(await sample_scenario(app, "endless_level_30_twelve_enemies"))
	await create_timer(FINAL_HOLD_SECONDS).timeout

	var report := {
		"format_version": 1,
		"project_version": str(ProjectSettings.get_setting("application/config/version", "development")),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"platform": OS.get_name(),
		"captured_utc": Time.get_datetime_string_from_system(true),
		"mode": "visible graphical frame and renderer benchmark",
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter_name": RenderingServer.get_video_adapter_name(),
		"video_adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"video_adapter_api_version": RenderingServer.get_video_adapter_api_version(),
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"window_size": {"width": root.size.x, "height": root.size.y},
		"warmup_frames": WARMUP_FRAMES,
		"scenarios": scenarios,
	}
	var path := output_path()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write graphics profile: %s" % path)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("GRAPHICS_PROFILE_WRITTEN: %s" % path)
	quit(0)
