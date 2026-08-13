extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

const VIEWPORT := Vector2i(1120, 720)
const GRID_EXTENT := Vector2i(40, 40)
const WARMUP_FRAMES: int = 120
const SAMPLE_FRAMES: int = 600


func _initialize() -> void:
	call_deferred("_measure")


func _measure() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("P0 runtime measurement requires a rendering display")
		quit(1)
		return
	root.size = VIEWPORT
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_extent = GRID_EXTENT
	main._start_game(GRID_EXTENT, true, false)
	await _frames(5)

	var entity_runtime = main.runtime.battlefield.get_node_or_null("CardfrontBattlefieldEntityRuntime")
	if entity_runtime != null:
		entity_runtime.spawn_repair_units(RulesScript.PLAYER_FACTION, 2)
		entity_runtime.spawn_armored_guard(RulesScript.PLAYER_FACTION)
		entity_runtime.spawn_repair_units(RulesScript.AI_FACTION, 2)
		entity_runtime.spawn_armored_guard(RulesScript.AI_FACTION)
		entity_runtime._mark_visuals_dirty()
	await _frames(WARMUP_FRAMES)

	var frame_times_ms: Array[float] = []
	for _frame in SAMPLE_FRAMES:
		var started_usec: int = Time.get_ticks_usec()
		await process_frame
		frame_times_ms.append(float(Time.get_ticks_usec() - started_usec) / 1000.0)
	frame_times_ms.sort()
	var average_ms: float = _average(frame_times_ms)
	var p95_index: int = clampi(ceili(float(frame_times_ms.size()) * 0.95) - 1, 0, frame_times_ms.size() - 1)
	var entity_count: int = 0
	if entity_runtime != null:
		entity_count = int((entity_runtime.registry.snapshot().entities as Array).size())
	var support_count: int = 0
	var support_authority = main.runtime.battlefield.get_meta("cardfront_support_deployment_authority", null)
	if support_authority != null:
		support_count = int(support_authority.presentation_snapshots().size())
	var report: Dictionary = {
		"commit": OS.get_environment("CARDFRONT_P0_COMMIT"),
		"godot": Engine.get_version_info().get("string", ""),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport": [VIEWPORT.x, VIEWPORT.y],
		"grid_extent": [GRID_EXTENT.x, GRID_EXTENT.y],
		"warmup_frames": WARMUP_FRAMES,
		"sample_frames": SAMPLE_FRAMES,
		"average_frame_time_ms": snappedf(average_ms, 0.001),
		"p95_frame_time_ms": snappedf(frame_times_ms[p95_index], 0.001),
		"average_fps_equivalent": snappedf(1000.0 / average_ms if average_ms > 0.0 else 0.0, 0.01),
		"active_entity_count": entity_count,
		"support_count": support_count,
		"notes": "Rendered process_frame wall time; VSync/display scheduling included. P0-00B has no comparable frame-time sample.",
	}
	var output_path: String = OS.get_environment("CARDFRONT_P0_PERF_OUTPUT").strip_edges()
	if output_path == "":
		output_path = ProjectSettings.globalize_path("res://artifacts/p0-11-performance.json")
	else:
		output_path = output_path.replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write P0 runtime report: %s" % output_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("[CardfrontP0RuntimeMeasurement] %s" % JSON.stringify(report))
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	quit(0)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())
