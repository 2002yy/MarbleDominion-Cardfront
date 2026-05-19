extends SceneTree

const EngineerBotEffectSystemScript = preload("res://scripts/cardfront/devices/effects/EngineerBotEffectSystem.gd")
const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[EngineerBotLiteTest] Starting Cardfront engineer bot lite tests")
	await process_frame

	_test_setup_succeeds()
	_test_owned_border_in_radius_is_fortified()
	_test_non_border_not_fortified()
	_test_already_max_stack_not_increased()
	_test_no_engineer_device_no_effect()
	_test_expired_device_no_effect()
	_test_tick_does_not_change_battlefield_owner()
	_test_old_ballwar_no_engineer_system()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[EngineerBotLiteTest]")
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
		_fill_grid(bf, fill_faction)
	else:
		bf.reset_quadrants()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(grid_size)
	rm.generate_default_layout()

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(grid_size)

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)

	if place_device:
		var req = DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
		device_layer.place(req)

	var engineer_system = EngineerBotEffectSystemScript.new()
	engineer_system.setup(device_layer, fortify_layer, bf, rm)
	get_root().add_child(engineer_system)

	return {
		"bf": bf,
		"rm": rm,
		"fortify_layer": fortify_layer,
		"device_layer": device_layer,
		"engineer_system": engineer_system,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for key in ["engineer_system", "device_layer", "bf"]:
		TestFixtures.cleanup_node(fixture.get(key, null))


func _fill_grid(bf, faction_id: int) -> void:
	for x in range(int(bf.grid_size)):
		for y in range(int(bf.grid_size)):
			bf.owners[x][y] = faction_id
	bf.rebuild_owner_counts()


func _make_border(bf, cell: Vector2i, owner_id: int = CardfrontRulesScript.PLAYER_FACTION) -> void:
	bf.owners[cell.x][cell.y] = owner_id
	bf.rebuild_owner_counts()


func _test_setup_succeeds() -> void:
	var fixture = _make_fixture()
	_assert.that(fixture.engineer_system != null, "engineer: system should be created")
	_assert.that(fixture.engineer_system.is_processing(), "engineer: system should be processing")
	_cleanup_fixture(fixture)


func _test_owned_border_in_radius_is_fortified() -> void:
	var fixture = _make_fixture(20, true)
	var fortify_layer = fixture.fortify_layer
	var bf = fixture.bf

	var border_cell = Vector2i(4, 5)
	bf.owners[border_cell.x][border_cell.y] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[border_cell.x + 1][border_cell.y] = CardfrontRulesScript.AI_FACTION
	bf.rebuild_owner_counts()

	_assert.eq(fortify_layer.get_fortify_stack(border_cell), 0, "engineer: border cell should start at 0")

	fixture.engineer_system.tick(0.0)
	var any_fortified: bool = false
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if fortify_layer.get_fortify_stack(Vector2i(5 + dx, 5 + dy)) > 0:
				any_fortified = true
	_assert.that(any_fortified, "engineer: at least one owned border in radius should be fortified")

	_cleanup_fixture(fixture)


func _test_non_border_not_fortified() -> void:
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

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(20)

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, rm)
	get_root().add_child(device_layer)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var engineer_system = EngineerBotEffectSystemScript.new()
	engineer_system.setup(device_layer, fortify_layer, bf, rm)
	get_root().add_child(engineer_system)

	var internal_cell = Vector2i(6, 5)
	var stacks_before: int = fortify_layer.get_fortify_stack(internal_cell)
	engineer_system.tick(0.0)
	var stacks_after: int = fortify_layer.get_fortify_stack(internal_cell)

	_assert.eq(stacks_after, stacks_before, "engineer: non-border internal cell should not be fortified")

	TestFixtures.cleanup_node(engineer_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_already_max_stack_not_increased() -> void:
	var fixture = _make_fixture(20, true)
	var fortify_layer = fixture.fortify_layer
	var bf = fixture.bf

	var border_cell = Vector2i(4, 5)
	bf.owners[border_cell.x][border_cell.y] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[border_cell.x + 1][border_cell.y] = CardfrontRulesScript.AI_FACTION
	bf.rebuild_owner_counts()

	fortify_layer.set_fortify_stack(border_cell, FortifyRulesScript.MAX_FORTIFY_STACKS)

	fixture.engineer_system.tick(0.0)
	_assert.eq(fortify_layer.get_fortify_stack(border_cell), FortifyRulesScript.MAX_FORTIFY_STACKS, "engineer: max stack should not be increased")

	_cleanup_fixture(fixture)


func _test_no_engineer_device_no_effect() -> void:
	var fixture = _make_fixture(20, false)
	var fortify_layer = fixture.fortify_layer
	var bf = fixture.bf

	var border_cell = Vector2i(4, 5)
	bf.owners[border_cell.x][border_cell.y] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[border_cell.x + 1][border_cell.y] = CardfrontRulesScript.AI_FACTION
	bf.rebuild_owner_counts()

	fixture.engineer_system.tick(0.0)
	_assert.eq(fortify_layer.get_fortify_stack(border_cell), 0, "engineer: no device should mean no effect")

	_cleanup_fixture(fixture)


func _test_expired_device_no_effect() -> void:
	var fixture = _make_fixture(20, true)
	var fortify_layer = fixture.fortify_layer
	var bf = fixture.bf
	var device_layer = fixture.device_layer

	var border_cell = Vector2i(4, 5)
	bf.owners[border_cell.x][border_cell.y] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[border_cell.x + 1][border_cell.y] = CardfrontRulesScript.AI_FACTION
	bf.rebuild_owner_counts()

	device_layer.tick(120.0)
	fixture.engineer_system.tick(0.0)
	_assert.eq(fortify_layer.get_fortify_stack(border_cell), 0, "engineer: expired device should not fortify")

	_cleanup_fixture(fixture)


func _test_tick_does_not_change_battlefield_owner() -> void:
	var fixture = _make_fixture(20, true)
	var bf = fixture.bf

	var test_cell = Vector2i(10, 10)
	var owner_before: int = int(bf.owners[test_cell.x][test_cell.y])
	fixture.engineer_system.tick(0.0)
	var owner_after: int = int(bf.owners[test_cell.x][test_cell.y])

	_assert.eq(owner_after, owner_before, "engineer: tick should not change battlefield owner")

	_cleanup_fixture(fixture)


func _test_old_ballwar_no_engineer_system() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.engineer_bot_effect_system == null, "engineer: old BallWar should not create engineer system")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
