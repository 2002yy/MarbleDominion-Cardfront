extends SceneTree

const LaneAllocationScript = preload("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd")
const DirectionControllerScript = preload("res://scripts/cardfront/arena/CardfrontDirectionController.gd")
const CommandPointScript = preload("res://scripts/cardfront/run/CardfrontCommandPointSystem.gd")
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontLaneAllocationTest] Starting lane allocation and command point tests")
	await process_frame

	_test_lane_split_even()
	_test_lane_split_all_left()
	_test_lane_split_all_right()
	_test_sequence_split()
	_test_allocation_roundtrip()
	_test_direction_controller_lane_angles()
	_test_direction_controller_priority_target()
	_test_command_point_spend()
	_test_command_point_add_and_cap()
	_test_command_point_snapshot_restore()

	_assert.report("[CardfrontLaneAllocationTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_lane_split_even() -> void:
	var allocs: Array = LaneAllocationScript.build_split(10, 0.5, -1.2, 1.2)
	_assert.eq(allocs.size(), 2, "even split: should produce 2 allocations")
	_assert.eq(int(allocs[0].shot_count), 5, "even split: left should get 5 shots")
	_assert.eq(int(allocs[1].shot_count), 5, "even split: right should get 5 shots")
	_assert.eq(float(allocs[0].angle), -1.2, "even split: left angle should match")
	_assert.eq(float(allocs[1].angle), 1.2, "even split: right angle should match")


func _test_lane_split_all_left() -> void:
	var allocs: Array = LaneAllocationScript.build_split(8, 1.0, -1.0, 1.0)
	_assert.eq(allocs.size(), 1, "all left: should produce 1 allocation")
	_assert.eq(int(allocs[0].shot_count), 8, "all left: should get all 8 shots")
	_assert.eq(int(allocs[0].lane_index), 0, "all left: should be lane 0")


func _test_lane_split_all_right() -> void:
	var allocs: Array = LaneAllocationScript.build_split(8, 0.0, -1.0, 1.0)
	_assert.eq(allocs.size(), 1, "all right: should produce 1 allocation")
	_assert.eq(int(allocs[0].shot_count), 8, "all right: should get all 8 shots")
	_assert.eq(int(allocs[0].lane_index), 1, "all right: should be lane 1")


func _test_sequence_split() -> void:
	var seq: Array = []
	ProjectileTypeScript.append_standard(seq, 4)
	seq.append(ProjectileTypeScript.SIEGE)
	seq.append(ProjectileTypeScript.SUPPRESSION)
	ProjectileTypeScript.append_standard(seq, 2)
	var allocs: Array = LaneAllocationScript.build_split(8, 0.5, -1.0, 1.0)
	LaneAllocationScript.split_sequence(seq, allocs)
	var left_seq: Array = allocs[0].projectile_sequence
	var right_seq: Array = allocs[1].projectile_sequence
	_assert.eq(left_seq.size(), 4, "seq split: left should get 4 projectiles")
	_assert.eq(right_seq.size(), 4, "seq split: right should get 4 projectiles")
	var total_seq: Array = left_seq.duplicate()
	total_seq.append_array(right_seq)
	_assert.eq(total_seq, seq, "seq split: combined should match original")


func _test_allocation_roundtrip() -> void:
	var alloc = LaneAllocationScript.new(0, 5, -0.8)
	alloc.has_priority_target = true
	alloc.priority_target_cell = Vector2i(10, 15)
	alloc.projectile_sequence = ["standard", "standard", "siege"]
	var data: Dictionary = alloc.to_dict()
	var restored = LaneAllocationScript.from_dict(data)
	_assert.eq(int(restored.lane_index), 0, "roundtrip: lane_index preserved")
	_assert.eq(int(restored.shot_count), 5, "roundtrip: shot_count preserved")
	_assert.eq(float(restored.angle), -0.8, "roundtrip: angle preserved")
	_assert.eq(bool(restored.has_priority_target), true, "roundtrip: has_priority_target preserved")
	_assert.eq(restored.priority_target_cell, Vector2i(10, 15), "roundtrip: priority_target_cell preserved")


func _test_direction_controller_lane_angles() -> void:
	var controller = DirectionControllerScript.new()
	controller.set_grid_extent(Vector2i(40, 50))
	var default_allocs: Array = controller.get_lane_allocations(10)
	_assert.eq(default_allocs.size(), 0, "controller: default split=0.5 should return empty (legacy path)")
	controller.set_lane_split(0.7)
	var allocs: Array = controller.get_lane_allocations(10)
	_assert.eq(allocs.size(), 2, "controller: non-0.5 split should produce 2 allocations")
	_assert.that(int(allocs[0].shot_count) > int(allocs[1].shot_count), "controller: 0.7 ratio should give left more shots")
	_assert.that(float(allocs[0].angle) < float(allocs[1].angle), "controller: left lane angle should be less than right (more negative = further left)")
	controller.set_lane_split(0.3)
	var allocs2: Array = controller.get_lane_allocations(10)
	_assert.that(int(allocs2[1].shot_count) > int(allocs2[0].shot_count), "controller: 0.3 ratio should give right more shots")


func _test_direction_controller_priority_target() -> void:
	var controller = DirectionControllerScript.new()
	controller.set_grid_extent(Vector2i(40, 50))
	_assert.that(not controller.has_priority_target(), "priority: should start without target")
	controller.set_priority_target(Vector2i(30, 5))
	_assert.that(controller.has_priority_target(), "priority: should have target after set")
	_assert.eq(controller.get_priority_target(), Vector2i(30, 5), "priority: target cell should match")
	var allocs: Array = controller.get_lane_allocations(6)
	_assert.that(allocs.size() >= 1, "priority: should still produce allocations")
	var has_priority: bool = false
	for alloc in allocs:
		if alloc.has_priority_target:
			has_priority = true
			_assert.eq(alloc.priority_target_cell, Vector2i(30, 5), "priority: allocation should carry target cell")
	_assert.that(has_priority, "priority: at least one allocation should have priority target")
	controller.clear_priority_target()
	_assert.that(not controller.has_priority_target(), "priority: should clear target")


func _test_command_point_spend() -> void:
	var cps = CommandPointScript.new()
	cps.setup([RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION], 3)
	_assert.eq(cps.get_points(RulesScript.PLAYER_FACTION), 3, "cp: should start with 3 points")
	_assert.that(cps.has_points(RulesScript.PLAYER_FACTION), "cp: should have points")
	_assert.that(cps.spend_point(RulesScript.PLAYER_FACTION), "cp: spend should succeed")
	_assert.eq(cps.get_points(RulesScript.PLAYER_FACTION), 2, "cp: should have 2 after spend")
	cps.spend_point(RulesScript.PLAYER_FACTION)
	cps.spend_point(RulesScript.PLAYER_FACTION)
	_assert.eq(cps.get_points(RulesScript.PLAYER_FACTION), 0, "cp: should have 0 after 3 spends")
	_assert.that(not cps.spend_point(RulesScript.PLAYER_FACTION), "cp: spend with 0 should fail")


func _test_command_point_add_and_cap() -> void:
	var cps = CommandPointScript.new()
	cps.setup([RulesScript.PLAYER_FACTION], 3)
	cps.add_point(RulesScript.PLAYER_FACTION, 10)
	_assert.eq(cps.get_points(RulesScript.PLAYER_FACTION), 5, "cp: should cap at MAX_POINTS (5)")
	_assert.eq(cps.get_points(RulesScript.AI_FACTION), 0, "cp: unconfigured faction should have 0")


func _test_command_point_snapshot_restore() -> void:
	var cps = CommandPointScript.new()
	cps.setup([RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION], 3)
	cps.spend_point(RulesScript.PLAYER_FACTION)
	var snap: Dictionary = cps.snapshot()
	_assert.eq(int(snap[RulesScript.PLAYER_FACTION]), 2, "cp snapshot: player should have 2")
	_assert.eq(int(snap[RulesScript.AI_FACTION]), 3, "cp snapshot: AI should have 3")
	var cps2 = CommandPointScript.new()
	cps2.restore(snap)
	_assert.eq(cps2.get_points(RulesScript.PLAYER_FACTION), 2, "cp restore: player should have 2")
	_assert.eq(cps2.get_points(RulesScript.AI_FACTION), 3, "cp restore: AI should have 3")
