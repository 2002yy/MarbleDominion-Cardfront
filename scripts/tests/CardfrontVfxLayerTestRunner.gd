extends SceneTree

const CardfrontVfxLayerScript = preload("res://scripts/cardfront/vfx/CardfrontVfxLayer.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontVfxLayerTest] Starting Cardfront VFX layer tests")
	await process_frame

	_test_vfx_texture_paths_exist()
	_test_vfx_layer_created_in_cardfront()
	_test_old_ballwar_no_vfx_layer()
	_test_energy_ripple_creates_effect()
	_test_shield_crack_creates_effect()
	_test_effect_visual_metrics_expand_and_fade()
	_test_effect_expires_and_removed()
	_test_missing_region_pulse_no_crash()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontVfxLayerTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_vfx_layer():
	var bf = Battlefield.new()
	bf.configure(10)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(10)
	rm.generate_default_layout()

	var vfx = CardfrontVfxLayerScript.new()
	vfx.setup(bf, rm, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(vfx)

	return {
		"vfx": vfx,
		"bf": bf,
		"rm": rm,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	for key in ["vfx", "bf"]:
		TestFixtures.cleanup_node(fixture.get(key, null))


func _test_vfx_texture_paths_exist() -> void:
	var vfx = CardfrontVfxLayerScript.new()
	var paths = [
		vfx._texture_path("energy_ripple"),
		vfx._texture_path("shield_crack"),
		vfx._texture_path("region_pulse"),
	]
	for path in paths:
		_assert.that(path != "", "vfx: texture path should not be empty")
		_assert.that(ResourceLoader.exists(path), "vfx: texture should exist: %s" % path)


func _test_vfx_layer_created_in_cardfront() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.cardfront_vfx_layer != null, "vfx: Cardfront should have vfx_layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_old_ballwar_no_vfx_layer() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.cardfront_vfx_layer == null, "vfx: old BallWar should not have vfx_layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_energy_ripple_creates_effect() -> void:
	var fixture = _make_vfx_layer()
	var vfx = fixture.vfx
	vfx.play_energy_ripple(Vector2i(5, 5))
	var effects = vfx.get_active_effects_for_test()
	_assert.gte(effects.size(), 1, "vfx: energy ripple should create at least 1 effect")
	if effects.size() > 0:
		_assert.eq(str(effects[0].get("effect_type", "")), "energy_ripple", "vfx: effect type should be energy_ripple")
	_cleanup_fixture(fixture)


func _test_shield_crack_creates_effect() -> void:
	var fixture = _make_vfx_layer()
	var vfx = fixture.vfx
	vfx.play_shield_crack(Vector2i(3, 3))
	var effects = vfx.get_active_effects_for_test()
	_assert.gte(effects.size(), 1, "vfx: shield crack should create at least 1 effect")
	if effects.size() > 0:
		_assert.eq(str(effects[0].get("effect_type", "")), "shield_crack", "vfx: effect type should be shield_crack")
	_cleanup_fixture(fixture)


func _test_effect_visual_metrics_expand_and_fade() -> void:
	var vfx = CardfrontVfxLayerScript.new()
	var start: Dictionary = vfx._visual_metrics(1.0, 1.0, 20)
	var mid: Dictionary = vfx._visual_metrics(0.5, 1.0, 20)
	var end: Dictionary = vfx._visual_metrics(0.1, 1.0, 20)

	_assert.gt(float(mid.get("size", 0.0)), float(start.get("size", 0.0)), "vfx visual: effect should expand over time")
	_assert.gt(float(end.get("size", 0.0)), float(mid.get("size", 0.0)), "vfx visual: late effect should be largest")
	_assert.gt(float(start.get("alpha", 0.0)), float(mid.get("alpha", 0.0)), "vfx visual: alpha should fade after start")
	_assert.gt(float(mid.get("alpha", 0.0)), float(end.get("alpha", 0.0)), "vfx visual: alpha should keep fading")


func _test_effect_expires_and_removed() -> void:
	var fixture = _make_vfx_layer()
	var vfx = fixture.vfx
	vfx.play_energy_ripple(Vector2i(5, 5))
	vfx._tick_effects(2.0)
	var effects = vfx.get_active_effects_for_test()
	_assert.eq(effects.size(), 0, "vfx: energy ripple should expire after duration")
	_cleanup_fixture(fixture)


func _test_missing_region_pulse_no_crash() -> void:
	var fixture = _make_vfx_layer()
	var vfx = fixture.vfx
	vfx.play_region_pulse(-1)
	var effects = vfx.get_active_effects_for_test()
	_assert.eq(effects.size(), 0, "vfx: invalid region pulse should not crash or create effect")
	_cleanup_fixture(fixture)
