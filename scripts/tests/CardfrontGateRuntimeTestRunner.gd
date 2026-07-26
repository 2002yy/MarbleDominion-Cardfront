extends SceneTree

const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontGateRuntimeTest] Starting live gate integration tests")
	await process_frame

	await _test_cardfront_runtime_wires_gate_filter()
	await _test_ballwar_has_no_gate_filter()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontGateRuntimeTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_runtime_wires_gate_filter() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT)
	var runtime = main.runtime
	var gate_system = runtime.gate_connectivity_system
	_assert.that(gate_system != null, "runtime: Cardfront should create the authoritative gate system")
	_assert.eq(runtime.bullet_pool.route_filter, gate_system, "runtime: BulletPool should delegate route crossings to the gate system")
	_assert.that(runtime.round_director.gate_connectivity_system == gate_system, "runtime: round sampling should use the same gate system")
	_assert.eq(float(runtime.orthographic_arena_view.get_gate_openness_for_test(0)), 1.0, "runtime: gates should start open before the first sample")

	var owners: Array = _owner_grid(runtime.battlefield, RulesScript.NEUTRAL_OWNER)
	_paint_lane_control(runtime.battlefield, owners, 0, RulesScript.AI_FACTION)
	runtime.battlefield.replace_owners(owners, false)
	runtime.round_director.force_open_draft_for_test()
	await process_frame
	var sampled_state: Dictionary = gate_system.get_lane_state(0)
	_assert.eq(str(sampled_state["state"]), GateRulesScript.STATE_CLOSED, "runtime: opening the draft should sample and lock gate control")
	_assert.eq(int(runtime.round_director.current_gate_snapshot[0]["owner_id"]), RulesScript.AI_FACTION, "runtime: RoundDirector should retain the sampled gate snapshot")
	_assert.eq(str(runtime.orthographic_arena_view.get_gate_state_for_test(0)["state"]), GateRulesScript.STATE_CLOSED, "runtime: the 3D presenter should mirror the authoritative state")

	var map_size: float = float(runtime.battlefield.grid_size * runtime.battlefield.cell_size)
	var lane_x: float = map_size * GateRulesScript.LANE_CENTER_RATIOS[0]
	var bullet = runtime.bullet_pool.spawn_bullet(
		RulesScript.PLAYER_FACTION,
		runtime.battlefield.to_global(Vector2(lane_x, map_size * 0.53)),
		Vector2.UP,
		runtime.battlefield,
		{},
		1,
		4
	)
	_assert.eq(bullet.route_filter, gate_system, "runtime: spawned projectiles should carry the gate route filter")
	_assert.eq(int(bullet.route_context["sampled_round"]), 1, "runtime: projectile context should freeze the launch-round gate snapshot")
	bullet._physics_process(0.12)
	_assert.gt(float(bullet.direction.y), 0.0, "runtime: an enemy projectile should visibly reflect from a closed gate")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_has_no_gate_filter() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.gate_connectivity_system, null, "BallWar: legacy modes should not create Cardfront gate rules")
	_assert.eq(main.runtime.bullet_pool.route_filter, null, "BallWar: projectile movement should keep its legacy route")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _owner_grid(battlefield, owner_id: int) -> Array:
	var result: Array = []
	for _x in range(int(battlefield.grid_size)):
		var column: Array = []
		for _y in range(int(battlefield.grid_size)):
			column.append(owner_id)
		result.append(column)
	return result


func _paint_lane_control(battlefield, owners: Array, lane_index: int, owner_id: int) -> void:
	var size: int = int(battlefield.grid_size)
	var center_x: int = roundi(float(size - 1) * GateRulesScript.LANE_CENTER_RATIOS[lane_index])
	var center_y: int = size >> 1
	var half_width: int = maxi(2, roundi(float(size) * GateRulesScript.CONTROL_ZONE_HALF_WIDTH_RATIO))
	var half_height: int = maxi(2, roundi(float(size) * GateRulesScript.CONTROL_ZONE_HALF_HEIGHT_RATIO))
	for x in range(maxi(0, center_x - half_width), mini(size, center_x + half_width + 1)):
		for y in range(maxi(0, center_y - half_height), mini(size, center_y + half_height + 1)):
			owners[x][y] = owner_id


func _flush() -> void:
	await process_frame
	await process_frame
