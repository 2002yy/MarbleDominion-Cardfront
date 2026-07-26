extends SceneTree

const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")
const GateSystemScript = preload("res://scripts/cardfront/gates/CardfrontGateConnectivitySystem.gd")
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

class MockArenaView:
	extends Node
	var states: Dictionary = {}

	func set_gate_state(lane_index: int, state: Dictionary) -> bool:
		states[lane_index] = state.duplicate(true)
		return true

var _assert: TestAssert
var _battlefield: Battlefield
var _system
var _arena_view: MockArenaView


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontGateConnectivityTest] Starting gate rule tests")
	await process_frame
	_setup_fixture()

	_test_defaults_open()
	_test_closed_gate_is_owner_only()
	_test_half_open_gate_filters_every_other_enemy_projectile()
	_test_snapshot_stays_locked_until_next_sample()
	_test_river_bank_rejects_off_bridge_crossing()

	_cleanup_fixture()
	_assert.report("[CardfrontGateConnectivityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(20, 10)
	get_root().add_child(_battlefield)
	_battlefield.replace_owners(_owner_grid(RulesScript.NEUTRAL_OWNER), false)
	_arena_view = MockArenaView.new()
	get_root().add_child(_arena_view)
	_system = GateSystemScript.new()
	get_root().add_child(_system)
	_assert.that(_system.setup(_battlefield, null, _arena_view), "setup: gate system should accept a configured battlefield")


func _test_defaults_open() -> void:
	for lane_index in range(GateRulesScript.LANE_COUNT):
		var state: Dictionary = _system.get_lane_state(lane_index)
		_assert.eq(str(state["state"]), GateRulesScript.STATE_OPEN, "default: gates should remain open before the first draft sample")
		_assert.eq(float(state["openness"]), 1.0, "default: presentation openness should be 100 percent")
	_assert.eq((_arena_view.states as Dictionary).size(), 2, "default: both 3D gate presenters should receive the initial snapshot")


func _test_closed_gate_is_owner_only() -> void:
	var owners: Array = _owner_grid(RulesScript.NEUTRAL_OWNER)
	_paint_control_zone(owners, 0, RulesScript.PLAYER_FACTION, 0.80)
	_battlefield.replace_owners(owners, false)
	var snapshot: Dictionary = _system.sample_and_lock(3)
	var state: Dictionary = snapshot[0] as Dictionary
	_assert.eq(str(state["state"]), GateRulesScript.STATE_CLOSED, "closed: 80 percent control should close the gate to the enemy")
	_assert.eq(int(state["control_percent"]), 80, "closed: the threshold sample should retain its exact control percentage")
	_assert.eq(int(state["owner_id"]), RulesScript.PLAYER_FACTION, "closed: sampled owner should be the controlling faction")

	var player_result: Dictionary = _cross_gate(0, RulesScript.PLAYER_FACTION, 1, snapshot)
	var ai_result: Dictionary = _cross_gate(0, RulesScript.AI_FACTION, 1, snapshot)
	_assert.that(bool(player_result["allowed"]), "closed: controlling faction should always pass")
	_assert.that(not bool(ai_result["allowed"]), "closed: opposing faction should be reflected")
	_assert.gt(float((ai_result["direction"] as Vector2).y), 0.0, "closed: a northbound enemy projectile should reflect south")


func _test_half_open_gate_filters_every_other_enemy_projectile() -> void:
	var owners: Array = _owner_grid(RulesScript.NEUTRAL_OWNER)
	_paint_control_zone(owners, 1, RulesScript.AI_FACTION, 0.62)
	_battlefield.replace_owners(owners, false)
	var snapshot: Dictionary = _system.sample_and_lock(4)
	var state: Dictionary = snapshot[1] as Dictionary
	_assert.eq(str(state["state"]), GateRulesScript.STATE_HALF_OPEN, "half: 55 to 79 percent control should create a half-open enemy route")
	_assert.eq(int(state["owner_id"]), RulesScript.AI_FACTION, "half: controlling faction should be recorded")
	_assert.that(bool(_cross_gate(1, RulesScript.AI_FACTION, 1, snapshot)["allowed"]), "half: owner should still pass every projectile")

	var enemy_first: bool = bool(_cross_gate(1, RulesScript.PLAYER_FACTION, 1, snapshot)["allowed"])
	var enemy_second: bool = bool(_cross_gate(1, RulesScript.PLAYER_FACTION, 2, snapshot)["allowed"])
	_assert.neq(enemy_first, enemy_second, "half: consecutive enemy projectile serials should alternate pass and reflection")


func _test_snapshot_stays_locked_until_next_sample() -> void:
	var locked_before: Dictionary = _system.get_snapshot()
	_battlefield.replace_owners(_owner_grid(RulesScript.NEUTRAL_OWNER), false)
	var still_locked: Dictionary = _system.get_snapshot()
	_assert.eq(still_locked, locked_before, "sampling: live territory changes should not alter the current volley snapshot")
	var refreshed: Dictionary = _system.sample_and_lock(5)
	_assert.eq(str((refreshed[0] as Dictionary)["state"]), GateRulesScript.STATE_OPEN, "sampling: the next draft should refresh the route state")
	_assert.eq(str((refreshed[1] as Dictionary)["state"]), GateRulesScript.STATE_OPEN, "sampling: neutral control should reopen both routes")


func _test_river_bank_rejects_off_bridge_crossing() -> void:
	var map_size: float = float(_battlefield.grid_size * _battlefield.cell_size)
	var result: Dictionary = _system.filter_step(
		RulesScript.PLAYER_FACTION,
		Vector2(map_size * 0.5, map_size * 0.55),
		Vector2(map_size * 0.5, map_size * 0.45),
		Vector2.UP,
		{"gate_snapshot": _system.get_snapshot(), "projectile_serial": 1}
	)
	_assert.that(bool(result["crossed"]), "river: crossing the center line should be detected")
	_assert.that(not bool(result["allowed"]), "river: projectiles outside bridge lanes should be reflected")
	_assert.eq(str(result["reason"]), "river_bank", "river: rejection reason should distinguish the bank from a controlled gate")


func _cross_gate(lane_index: int, faction_id: int, serial: int, snapshot: Dictionary) -> Dictionary:
	var map_size: float = float(_battlefield.grid_size * _battlefield.cell_size)
	var x: float = map_size * GateRulesScript.LANE_CENTER_RATIOS[lane_index]
	return _system.filter_step(
		faction_id,
		Vector2(x, map_size * 0.55),
		Vector2(x, map_size * 0.45),
		Vector2.UP,
		{"gate_snapshot": snapshot, "projectile_serial": serial}
	)


func _owner_grid(owner_id: int) -> Array:
	var result: Array = []
	for x in range(_battlefield.grid_size):
		var column: Array = []
		for _y in range(_battlefield.grid_size):
			column.append(owner_id)
		result.append(column)
	return result


func _paint_control_zone(owners: Array, lane_index: int, owner_id: int, ratio: float) -> void:
	var size: int = _battlefield.grid_size
	var center_x: int = roundi(float(size - 1) * GateRulesScript.LANE_CENTER_RATIOS[lane_index])
	var center_y: int = size >> 1
	var half_width: int = maxi(2, roundi(float(size) * GateRulesScript.CONTROL_ZONE_HALF_WIDTH_RATIO))
	var half_height: int = maxi(2, roundi(float(size) * GateRulesScript.CONTROL_ZONE_HALF_HEIGHT_RATIO))
	var cells: Array[Vector2i] = []
	for x in range(maxi(0, center_x - half_width), mini(size, center_x + half_width + 1)):
		for y in range(maxi(0, center_y - half_height), mini(size, center_y + half_height + 1)):
			cells.append(Vector2i(x, y))
	var paint_count: int = roundi(float(cells.size()) * clampf(ratio, 0.0, 1.0))
	for index in range(paint_count):
		var cell: Vector2i = cells[index]
		owners[cell.x][cell.y] = owner_id


func _cleanup_fixture() -> void:
	_system.detach()
	TestFixtures.cleanup_node(_system)
	TestFixtures.cleanup_node(_arena_view)
	TestFixtures.cleanup_node(_battlefield)
