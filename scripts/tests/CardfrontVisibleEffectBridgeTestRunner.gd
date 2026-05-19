extends SceneTree

const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const AbsorberCoreEffectSystemScript = preload("res://scripts/cardfront/devices/effects/AbsorberCoreEffectSystem.gd")
const EngineerBotEffectSystemScript = preload("res://scripts/cardfront/devices/effects/EngineerBotEffectSystem.gd")
const DurablePioneerBeaconEffectSystemScript = preload("res://scripts/cardfront/devices/effects/DurablePioneerBeaconEffectSystem.gd")
const CardfrontVfxLayerScript = preload("res://scripts/cardfront/vfx/CardfrontVfxLayer.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontVisibleEffectBridgeTest] Starting visible effect bridge tests")
	await process_frame

	_test_absorber_absorb_triggers_vfx()
	_test_engineer_repair_triggers_vfx()
	_test_beacon_convert_triggers_vfx()
	_test_debug_panel_creates_absorber_device()
	_test_debug_panel_creates_engineer_device()
	_test_debug_panel_creates_beacon_device()
	_test_old_ballwar_no_vfx_effect()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontVisibleEffectBridgeTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_bf(gs: int = 10):
	var bf = Battlefield.new()
	bf.configure(gs)
	get_root().add_child(bf)
	bf.reset_quadrants()
	return bf


func _make_vfx(bf):
	var rm = load("res://scripts/cardfront/regions/RegionMap.gd").new()
	rm.configure(int(bf.grid_size))
	rm.generate_default_layout()
	var vfx = CardfrontVfxLayerScript.new()
	vfx.setup(bf, rm, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(vfx)
	return vfx


func _make_device_layer(bf):
	var layer = DeviceLayerScript.new()
	layer.setup(bf, null)
	get_root().add_child(layer)
	return layer


func _test_absorber_absorb_triggers_vfx() -> void:
	var bf = _make_bf(20)
	var vfx = _make_vfx(bf)
	var pool = BulletPool.new()
	get_root().add_child(pool)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(50)
	var resource_states: Dictionary = {CardfrontRulesScript.PLAYER_FACTION: player_state}

	var device_layer = _make_device_layer(bf)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, Vector2i(9, 5)))

	var system = AbsorberCoreEffectSystemScript.new()
	system.setup(device_layer, pool, resource_states, bf, vfx)
	get_root().add_child(system)

	var bullet = pool.spawn_bullet(CardfrontRulesScript.AI_FACTION, bf.global_position + Vector2(9.5, 5.5) * float(bf.cell_size), Vector2.RIGHT, bf, {})

	system.tick(1.0)
	var effects = vfx.get_active_effects_for_test()
	_assert.gte(effects.size(), 1, "bridge: absorber vfx should trigger on absorb")

	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(pool)
	TestFixtures.cleanup_node(vfx)
	TestFixtures.cleanup_node(bf)


func _test_engineer_repair_triggers_vfx() -> void:
	var bf = _make_bf(20)
	var vfx = _make_vfx(bf)
	var fortify = FortifyLayerScript.new()
	fortify.configure(20)

	var device_layer = _make_device_layer(bf)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.ENGINEER_BOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	bf.owners[4][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.owners[5][5] = CardfrontRulesScript.AI_FACTION
	bf.rebuild_owner_counts()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var system = EngineerBotEffectSystemScript.new()
	system.setup(device_layer, fortify, bf, rm, vfx)
	get_root().add_child(system)

	system.tick(0.0)
	var effects = vfx.get_active_effects_for_test()
	_assert.gte(effects.size(), 1, "bridge: engineer repair should trigger vfx")

	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(vfx)
	TestFixtures.cleanup_node(bf)


func _test_beacon_convert_triggers_vfx() -> void:
	var bf = _make_bf(20)
	for x in range(20):
		for y in range(20):
			bf.owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	bf.owners[5][5] = CardfrontRulesScript.PLAYER_FACTION
	bf.rebuild_owner_counts()

	var vfx = _make_vfx(bf)
	var device_layer = _make_device_layer(bf)
	device_layer.place(DevicePlacementRequestScript.make(DeviceTypeScript.PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5)))

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var system = DurablePioneerBeaconEffectSystemScript.new()
	system.setup(device_layer, bf, rm, vfx)
	get_root().add_child(system)

	system.tick(0.0)
	var effects = vfx.get_active_effects_for_test()
	_assert.gte(effects.size(), 1, "bridge: beacon convert should trigger vfx")

	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(vfx)
	TestFixtures.cleanup_node(bf)


func _test_debug_panel_creates_absorber_device() -> void:
	var bf = _make_bf(12)
	var device_layer = _make_device_layer(bf)
	var CardPlaySystemScript = load("res://scripts/cardfront/cards/CardPlaySystem.gd")
	var card_system = CardPlaySystemScript.new()

	var DebugPanelScript = load("res://scripts/cardfront/debug/CardfrontDebugActionPanel.gd")
	var panel = DebugPanelScript.new()
	panel.setup(device_layer, card_system, bf, null, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(panel)

	panel._place_device(DeviceTypeScript.ABSORBER_CORE)
	var devices = device_layer.get_all_active_devices()
	_assert.gte(devices.size(), 1, "bridge: debug panel should place absorber device")
	if devices.size() > 0:
		_assert.eq(str(devices[0].device_type), DeviceTypeScript.ABSORBER_CORE, "bridge: placed device should be absorber")

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_debug_panel_creates_engineer_device() -> void:
	var bf = _make_bf(12)
	var device_layer = _make_device_layer(bf)
	var CardPlaySystemScript = load("res://scripts/cardfront/cards/CardPlaySystem.gd")
	var card_system = CardPlaySystemScript.new()

	var DebugPanelScript = load("res://scripts/cardfront/debug/CardfrontDebugActionPanel.gd")
	var panel = DebugPanelScript.new()
	panel.setup(device_layer, card_system, bf, null, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(panel)

	panel._place_device(DeviceTypeScript.ENGINEER_BOT)
	var devices = device_layer.get_all_active_devices()
	_assert.gte(devices.size(), 1, "bridge: debug panel should place engineer device")

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_debug_panel_creates_beacon_device() -> void:
	var bf = _make_bf(12)
	var device_layer = _make_device_layer(bf)
	var CardPlaySystemScript = load("res://scripts/cardfront/cards/CardPlaySystem.gd")
	var card_system = CardPlaySystemScript.new()

	var DebugPanelScript = load("res://scripts/cardfront/debug/CardfrontDebugActionPanel.gd")
	var panel = DebugPanelScript.new()
	panel.setup(device_layer, card_system, bf, null, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(panel)

	panel._place_device(DeviceTypeScript.PIONEER_BEACON)
	var devices = device_layer.get_all_active_devices()
	_assert.gte(devices.size(), 1, "bridge: debug panel should place beacon device")

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_old_ballwar_no_vfx_effect() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.cardfront_vfx_layer == null, "bridge: old BallWar should not have vfx layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
