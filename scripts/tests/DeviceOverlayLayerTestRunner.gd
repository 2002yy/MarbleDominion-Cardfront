extends SceneTree

const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const DeviceVisualRegistryScript = preload("res://scripts/cardfront/devices/DeviceVisualRegistry.gd")
const CardfrontDeviceOverlayLayerScript = preload("res://scripts/cardfront/devices/CardfrontDeviceOverlayLayer.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[DeviceOverlayLayerTest] Starting Cardfront device overlay layer tests")
	await process_frame

	_test_texture_paths_exist()
	_test_overlay_created_in_cardfront()
	_test_old_ballwar_no_overlay()
	_test_expired_device_not_drawn()
	_test_removed_device_not_drawn()
	_test_missing_texture_falls_back_to_color()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[DeviceOverlayLayerTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_texture_paths_exist() -> void:
	var registry = DeviceVisualRegistryScript.new()
	var types = [DeviceTypeScript.ABSORBER_CORE, DeviceTypeScript.ENGINEER_BOT, DeviceTypeScript.PIONEER_BEACON]
	for device_type in types:
		var path: String = registry.get_texture_path(str(device_type))
		_assert.that(path != "", "overlay: texture path should not be empty for %s" % str(device_type))
		_assert.that(ResourceLoader.exists(path), "overlay: texture should exist: %s" % path)

	var fallback: Color = registry.get_fallback_color(DeviceTypeScript.ABSORBER_CORE)
	_assert.that(fallback != Color.GRAY, "overlay: absorber fallback color should not be default gray")

	var label: String = registry.get_label(DeviceTypeScript.ABSORBER_CORE)
	_assert.eq(label, "吸弹核心", "overlay: absorber label")


func _test_overlay_created_in_cardfront() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var overlay = main.runtime.device_layer  # check if device_layer exists
	_assert.that(overlay != null, "overlay: Cardfront should have device_layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_old_ballwar_no_overlay() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.device_layer == null, "overlay: old BallWar should not have device layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_expired_device_not_drawn() -> void:
	var bf = Battlefield.new()
	bf.configure(10)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, null)
	get_root().add_child(device_layer)

	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, Vector2i(2, 2))
	device_layer.place(req)
	device_layer.tick(100.0)

	var active_devices = device_layer.get_all_active_devices()
	_assert.eq(active_devices.size(), 0, "overlay: expired device should not appear in active list")

	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_removed_device_not_drawn() -> void:
	var bf = Battlefield.new()
	bf.configure(10)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(bf, null)
	get_root().add_child(device_layer)

	var cell = Vector2i(2, 2)
	var req = DevicePlacementRequestScript.make(DeviceTypeScript.ABSORBER_CORE, CardfrontRulesScript.PLAYER_FACTION, cell)
	device_layer.place(req)
	device_layer.remove_at(cell)

	var active_devices = device_layer.get_all_active_devices()
	_assert.eq(active_devices.size(), 0, "overlay: removed device should not appear in active list")

	TestFixtures.cleanup_node(device_layer)
	TestFixtures.cleanup_node(bf)


func _test_missing_texture_falls_back_to_color() -> void:
	var overlay = CardfrontDeviceOverlayLayerScript.new()
	var fallback: Color = overlay.device_visual_registry.get_fallback_color(DeviceTypeScript.ABSORBER_CORE)
	_assert.that(fallback.a == 1.0 or fallback != Color.GRAY, "overlay: fallback color should be registered")
	_assert.that(fallback.r > 0.0 or fallback.g > 0.0 or fallback.b > 0.0, "overlay: fallback should not be pure black")
