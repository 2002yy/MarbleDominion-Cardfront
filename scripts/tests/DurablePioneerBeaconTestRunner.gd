extends SceneTree

const DurablePioneerBeaconEffectSystemScript = preload("res://scripts/cardfront/devices/effects/DurablePioneerBeaconEffectSystem.gd")
const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[DurablePioneerBeaconTest] Starting Cardfront durable pioneer beacon tests")
	await process_frame

	_test_setup_succeeds()
	_test_nearby_neutral_cell_converted()
	_test_per_tick_cap_one_cell()
	_test_friendly_cell_not_reconverted()
	_test_enemy_cell_not_converted()
	_test_no_device_no_effect()
	_test_expired_device_no_effect()
	_test_old_ballwar_no_beacon_system()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[DurablePioneerBeaconTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture(grid_size: int = 20, place_device: bool = true, fill_faction: int = -1):
	var bf = Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	if fill_faction >= 0:
		for x in range(grid_size):
			for y in range(grid_size):
				bf.owners[x][y] = fill_faction
		bf.rebuild_owner_counts()
	else:
		bf.reset_quadrants()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(grid_size)
	rm.generate_default_layout()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)

	if place_device:
		var req = DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
		device_layer.place(req)

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, bf, rm)
	get_root().add_child(beacon_system)

	return {
		"bf": bf,
		"device_layer": device_layer,
		"beacon_system": beacon_system,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for key in ["beacon_system", "device_layer", "bf"]:
		TestFixtures.cleanup_node(fixture.get(key, null))


func _count_owner(bf, owner_id: int) -> int:
	var total: int = 0
	for x in range(int(bf.grid_size)):
		for y in range(int(bf.grid_size)):
			if DeploymentRulesScript.get_owner_at(bf, Vector2i(x, y)) == owner_id:
				total += 1
	return total


func _test_setup_succeeds() -> void:
	var fixture = _make_fixture()
	_assert.that(fixture.beacon_system != null, "beacon: system should be created")
	_assert.that(fixture.beacon_system.is_processing(), "beacon: system should be processing")
	_cleanup_fixture(fixture)


func _test_nearby_neutral_cell_converted() -> void:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[5][4] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.rebuild_owner_counts()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, bf, rm)
	get_root().add_child(beacon_system)

	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.that(player_after > player_before, "beacon: neutral cell should be converted (before=%d after=%d)" % [player_before, player_after])

	TestFixtures.cleanup_node(beacon_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_per_tick_cap_one_cell() -> void:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, bf, rm)
	get_root().add_child(beacon_system)

	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(player_after - player_before, 1, "beacon: should convert exactly 1 cell per tick")

	TestFixtures.cleanup_node(beacon_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_friendly_cell_not_reconverted() -> void:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, bf, rm)
	get_root().add_child(beacon_system)

	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(player_after, player_before, "beacon: friendly cells should not be reconverted")

	TestFixtures.cleanup_node(beacon_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_enemy_cell_not_converted() -> void:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.AI_FACTION
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, bf, rm)
	get_root().add_child(beacon_system)

	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(player_after, player_before, "beacon: enemy cells should not be converted")

	TestFixtures.cleanup_node(beacon_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_no_device_no_effect() -> void:
	var fixture = _make_fixture(20, false)
	var bf = fixture.bf

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	fixture.beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(player_after, player_before, "beacon: no device should mean no effect")

	_cleanup_fixture(fixture)


func _test_expired_device_no_effect() -> void:
	var fixture = _make_fixture(20, true)
	var bf = fixture.bf
	var device_layer = fixture.device_layer

	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	device_layer.tick(200.0)
	var player_before: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)
	fixture.beacon_system.tick(0.0)
	var player_after: int = _count_owner(bf, CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(player_after, player_before, "beacon: expired device should not convert cells")

	_cleanup_fixture(fixture)


func _test_old_ballwar_no_beacon_system() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.durable_pioneer_beacon_effect_system == null, "beacon: old BallWar should not create beacon system")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
