extends SceneTree

const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DevicePlacementResultScript = preload("res://scripts/cardfront/devices/DevicePlacementResult.gd")
const DeviceRegistryScript = preload("res://scripts/cardfront/devices/DeviceRegistry.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[DeviceCoreTest] Starting Cardfront device core tests")
	await process_frame

	_test_owned_cell_placement_succeeds()
	_test_enemy_cell_placement_fails()
	_test_outside_grid_placement_fails()
	_test_duplicate_same_cell_fails()
	_test_max_per_owner_type_enforced()
	_test_remove_device_then_not_found()
	_test_lifetime_tick_expires_device()
	_test_tick_does_not_change_battlefield_owner()
	_test_snapshot_includes_devices()
	_test_old_ballwar_no_device_layer()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[DeviceCoreTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_battlefield(grid_size: int = 20):
	var bf = Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	bf.reset_quadrants()
	return bf


func _make_region_map(grid_size: int = 20):
	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(grid_size)
	rm.generate_default_layout()
	return rm


func _make_layer(grid_size: int = 20):
	var bf = _make_battlefield(grid_size)
	var rm = _make_region_map(grid_size)
	var layer = DeviceLayerScript.new()
	layer.setup(bf, rm)
	get_root().add_child(layer)
	return {
		"layer": layer,
		"bf": bf,
		"rm": rm,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for key in ["layer", "bf"]:
		var node = fixture.get(key, null)
		TestFixtures.cleanup_node(node)


func _test_owned_cell_placement_succeeds() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer
	var bf = fixture.bf

	var cell = Vector2i(3, 3)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = layer.place(req)

	_assert.that(result.success, "device: placement on owned cell should succeed")
	_assert.eq(result.reason, DevicePlacementResultScript.REASON_SUCCESS, "device: reason should be success")
	_assert.that(result.instance != null, "device: result should include instance")
	if result.instance != null:
		_assert.eq(result.instance.device_type, DeviceTypeScript.ABSORBER_CORE, "device: instance type")
		_assert.eq(result.instance.owner_id, CardfrontRulesScript.PLAYER_FACTION, "device: instance owner")
		_assert.that(result.instance.active, "device: instance should be active")

	_cleanup_fixture(fixture)


func _test_enemy_cell_placement_fails() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer

	var cell = Vector2i(15, 15)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = layer.place(req)

	_assert.that(not result.success, "device: placement on enemy cell should fail")
	_assert.eq(result.reason, DevicePlacementResultScript.REASON_NOT_OWNED_CELL, "device: reason should be not_owned_cell")
	_assert.that(result.instance == null, "device: result should have null instance")

	_cleanup_fixture(fixture)


func _test_outside_grid_placement_fails() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer

	var cell = Vector2i(-5, 5)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = layer.place(req)

	_assert.that(not result.success, "device: outside grid should fail")
	_assert.eq(result.reason, DevicePlacementResultScript.REASON_OUTSIDE_MAP, "device: reason should be outside_map")

	_cleanup_fixture(fixture)


func _test_duplicate_same_cell_fails() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer

	var cell = Vector2i(3, 3)
	var req1 = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	var r1 = layer.place(req1)
	_assert.that(r1.success, "device: first placement should succeed")

	var req2 = DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, cell)
	var r2 = layer.place(req2)
	_assert.that(not r2.success, "device: duplicate cell should fail")
	_assert.eq(r2.reason, DevicePlacementResultScript.REASON_DUPLICATE_CELL, "device: reason should be duplicate_cell")

	_cleanup_fixture(fixture)


func _test_max_per_owner_type_enforced() -> void:
	var fixture = _make_layer(30)
	var layer = fixture.layer

	var count: int = DeviceRegistryScript.new().get_max_per_owner(DeviceTypeScript.ABSORBER_CORE)
	_assert.eq(count, 3, "device: absorber max should be 3")

	var cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	for i in range(cells.size()):
		var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cells[i])
		var result = layer.place(req)
		if i < 3:
			_assert.that(result.success, "device: placement %d should succeed" % i)
		else:
			_assert.that(not result.success, "device: placement %d should fail (max per owner type)" % i)
			_assert.eq(result.reason, DevicePlacementResultScript.REASON_MAX_PER_OWNER_TYPE, "device: reason should be max_per_owner_type")

	_cleanup_fixture(fixture)


func _test_remove_device_then_not_found() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer

	var cell = Vector2i(3, 3)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	layer.place(req)

	_assert.that(layer.get_device_at(cell) != null, "device: should find before remove")
	var removed: bool = layer.remove_at(cell)
	_assert.that(removed, "device: remove_at should return true")
	_assert.that(layer.get_device_at(cell) == null, "device: should be null after remove")

	_cleanup_fixture(fixture)


func _test_lifetime_tick_expires_device() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer

	var registry = DeviceRegistryScript.new()
	var lifetime: float = registry.get_default_lifetime(DeviceTypeScript.ABSORBER_CORE)
	_assert.gt(int(lifetime), 0, "device: absorber should have positive default lifetime")

	var cell = Vector2i(3, 3)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	layer.place(req)

	_assert.that(layer.get_device_at(cell) != null, "device: should exist before expiry tick")

	layer.tick(lifetime + 1.0)
	_assert.that(layer.get_device_at(cell) == null, "device: should be removed after lifetime expires")

	_cleanup_fixture(fixture)


func _test_tick_does_not_change_battlefield_owner() -> void:
	var fixture = _make_layer()
	var layer = fixture.layer
	var bf = fixture.bf

	var cell = Vector2i(3, 3)
	var owner_before: int = DeploymentRulesScript.get_owner_at(bf, cell)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	layer.place(req)

	layer.tick(60.0)
	layer.tick(60.0)

	var owner_after: int = DeploymentRulesScript.get_owner_at(bf, cell)
	_assert.eq(owner_after, owner_before, "device: tick should not change battlefield owner")

	_cleanup_fixture(fixture)


func _test_snapshot_includes_devices() -> void:
	var fixture = _make_layer(30)
	var layer = fixture.layer

	var cell1 = Vector2i(0, 0)
	var cell2 = Vector2i(1, 0)
	layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell1))
	layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, cell2))

	var snap: Dictionary = layer.snapshot()
	var device_list: Array = snap.get("devices", [])
	_assert.eq(device_list.size(), 2, "device: snapshot should contain 2 devices")

	var found_types: Array = []
	for d in device_list:
		found_types.append(str(d.get("device_type", "")))
	_assert.that(DeviceTypeScript.ABSORBER_CORE in found_types, "device: snapshot includes absorber")
	_assert.that(DeviceTypeScript.ENGINEER_BOT in found_types, "device: snapshot includes engineer bot")

	_cleanup_fixture(fixture)


func _test_old_ballwar_no_device_layer() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.device_layer == null, "device: old BallWar mode should not create device layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
