extends SceneTree

const AbsorberCoreEffectSystemScript = preload("res://scripts/cardfront/devices/effects/AbsorberCoreEffectSystem.gd")
const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[AbsorberCoreLiteTest] Starting Cardfront absorber core lite tests")
	await process_frame

	_test_setup_succeeds()
	_test_enemy_bullet_in_radius_is_absorbed()
	_test_absorbed_bullet_gives_owner_energy()
	_test_friendly_bullet_not_absorbed()
	_test_outside_radius_bullet_not_absorbed()
	_test_no_absorber_device_no_absorb()
	_test_expired_device_no_absorb()
	_test_old_ballwar_no_absorber_system()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[AbsorberCoreLiteTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture(place_device: bool = true):
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var pool = BulletPool.new()
	get_root().add_child(pool)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(10)
	player_state.add_parts(10)
	var ai_state = CardfrontResourceStateScript.new()
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, null)
	get_root().add_child(device_layer)

	if place_device:
		var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
		device_layer.place(req)

	var absorber_system = AbsorberCoreEffectSystemScript.new()
	absorber_system.setup(device_layer, pool, resource_states, bf)
	get_root().add_child(absorber_system)

	return {
		"bf": bf,
		"pool": pool,
		"device_layer": device_layer,
		"absorber_system": absorber_system,
		"player_state": player_state,
		"resource_states": resource_states,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for key in ["absorber_system", "device_layer", "pool", "bf"]:
		TestFixtures.cleanup_node(fixture.get(key, null))


func _spawn_bullet(pool, bf, faction_id: int, cell: Vector2i):
	var cell_size: int = int(bf.cell_size)
	var world_pos: Vector2 = bf.global_position + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * float(cell_size)
	return pool.spawn_bullet(faction_id, world_pos, Vector2.RIGHT, bf, {})


func _test_setup_succeeds() -> void:
	var fixture = _make_fixture()
	_assert.that(fixture.absorber_system != null, "absorber: system should be created")
	_assert.that(fixture.absorber_system.is_processing(), "absorber: system should be processing")
	_cleanup_fixture(fixture)


func _test_enemy_bullet_in_radius_is_absorbed() -> void:
	var fixture = _make_fixture(true)
	var pool = fixture.pool
	var bf = fixture.bf

	var device_cell = Vector2i(5, 5)
	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.AI_FACTION, device_cell)

	var active_before: int = pool.get_active_count()
	fixture.absorber_system.tick(1.0)
	var active_after: int = pool.get_active_count()

	_assert.eq(active_before, 1, "absorber: 1 bullet before tick")
	_assert.that(active_after < active_before, "absorber: enemy bullet in radius should be absorbed (before=%d after=%d)" % [active_before, active_after])

	_cleanup_fixture(fixture)


func _test_absorbed_bullet_gives_owner_energy() -> void:
	var fixture = _make_fixture(true)
	var pool = fixture.pool
	var bf = fixture.bf
	var player_state = fixture.player_state

	var energy_before: int = int(player_state.energy)
	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.AI_FACTION, Vector2i(5, 5))

	fixture.absorber_system.tick(1.0)
	var energy_after: int = int(player_state.energy)

	_assert.that(energy_after > energy_before, "absorber: owner should gain energy on absorb (before=%d after=%d)" % [energy_before, energy_after])
	_assert.eq(energy_after, energy_before + 1, "absorber: should gain exactly 1 energy per absorb")

	_cleanup_fixture(fixture)


func _test_friendly_bullet_not_absorbed() -> void:
	var fixture = _make_fixture(true)
	var pool = fixture.pool
	var bf = fixture.bf

	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))

	var active_before: int = pool.get_active_count()
	fixture.absorber_system.tick(1.0)
	var active_after: int = pool.get_active_count()

	_assert.eq(active_after, active_before, "absorber: friendly bullet should NOT be absorbed")

	_cleanup_fixture(fixture)


func _test_outside_radius_bullet_not_absorbed() -> void:
	var fixture = _make_fixture(true)
	var pool = fixture.pool
	var bf = fixture.bf

	var far_cell = Vector2i(15, 15)
	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.AI_FACTION, far_cell)

	var active_before: int = pool.get_active_count()
	fixture.absorber_system.tick(1.0)
	var active_after: int = pool.get_active_count()

	_assert.eq(active_after, active_before, "absorber: out-of-radius bullet should NOT be absorbed")

	_cleanup_fixture(fixture)


func _test_no_absorber_device_no_absorb() -> void:
	var fixture = _make_fixture(false)
	var pool = fixture.pool
	var bf = fixture.bf

	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.AI_FACTION, Vector2i(5, 5))

	var active_before: int = pool.get_active_count()
	fixture.absorber_system.tick(1.0)
	var active_after: int = pool.get_active_count()

	_assert.eq(active_after, active_before, "absorber: no absorber device should mean no absorption")

	_cleanup_fixture(fixture)


func _test_expired_device_no_absorb() -> void:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var pool = BulletPool.new()
	get_root().add_child(pool)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(10)
	var resource_states: Dictionary = {CardfrontRulesScript.PLAYER_FACTION: player_state}

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, null)
	get_root().add_child(device_layer)

	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
	device_layer.place(req)

	var absorber_system = AbsorberCoreEffectSystemScript.new()
	absorber_system.setup(device_layer, pool, resource_states, bf)
	get_root().add_child(absorber_system)

	device_layer.tick(100.0)

	var bullet = _spawn_bullet(pool, bf, CardfrontRulesScript.AI_FACTION, Vector2i(5, 5))
	var active_before: int = pool.get_active_count()
	absorber_system.tick(1.0)
	var active_after: int = pool.get_active_count()

	_assert.eq(active_after, active_before, "absorber: expired device should not absorb bullets")

	TestFixtures.cleanup_node(absorber_system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(pool)
	TestFixtures.cleanup_node(bf)


func _test_old_ballwar_no_absorber_system() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.absorber_core_effect_system == null, "absorber: old BallWar should not create absorber system")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
