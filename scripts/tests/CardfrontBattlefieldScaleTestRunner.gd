extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontArenaLayoutScript = preload("res://scripts/cardfront/arena/CardfrontArenaLayout.gd")
const CardfrontDirectionControllerScript = preload("res://scripts/cardfront/arena/CardfrontDirectionController.gd")
const CardfrontAimControlScene = preload("res://scenes/ui/cardfront/CardfrontAimControl.tscn")
const CardfrontHUDScene = preload("res://scenes/ui/cardfront/CardfrontHUD.tscn")

const DESKTOP_VIEWPORT := Vector2(1120.0, 720.0)
const NARROW_VIEWPORT := Vector2(760.0, 540.0)
const MAX_PERSISTENT_CHROME_RATIO: float = 0.12

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontBattlefieldScaleTest] Starting battlefield scale tests")
	await process_frame

	await _test_cardfront_scale_presets_and_authority_isolation()
	await _test_narrow_viewport_layout_and_chrome_bounds()
	await _test_ballwar_does_not_create_scale_control()
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontBattlefieldScaleTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_scale_presets_and_authority_isolation() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)
	var view = main.runtime.orthographic_arena_view
	var control = main.runtime.battlefield_scale_control
	_assert.that(view != null and is_instance_valid(view), "scale: Cardfront should create an orthographic view")
	_assert.eq(control, null, "scale: player battle should not expose a persistent scale debug control")
	_assert.eq(main.find_child("CardfrontBattlefieldScaleControl", true, false), null, "scale: player UI tree should not contain the scale debug widget")
	if view == null:
		TestFixtures.cleanup_node(main)
		await _flush()
		return

	_assert.eq(view.get_presentation_scale(), 1.20, "scale: match should begin at the close 120 percent combat framing")
	var authority_snapshot: String = JSON.stringify(main.runtime.battlefield.owners, "", true, true)
	var base_size: float = view.get_camera_for_test().size

	view.set_presentation_scale(1.0, false)
	_assert.eq(view.get_presentation_scale(), 1.0, "scale: 100 percent overview preset should be selected")
	_assert.that(view.get_camera_for_test().size > base_size, "scale: 100 percent should widen the default orthographic framing")
	_assert.eq(JSON.stringify(main.runtime.battlefield.owners, "", true, true), authority_snapshot, "scale: zooming out must not mutate authoritative cells")

	view.set_presentation_scale(1.20, false)
	_assert.eq(view.get_presentation_scale(), 1.20, "scale: 120 percent detail preset should be selected")
	_assert.eq(view.get_camera_for_test().size, base_size, "scale: 120 percent should restore the close default framing")
	_assert.eq(JSON.stringify(main.runtime.battlefield.owners, "", true, true), authority_snapshot, "scale: zooming in must not mutate authoritative cells")

	_assert.eq(view.set_presentation_scale(1.14, false), 1.12, "scale: arbitrary values should snap to the nearest approved preset")
	_assert.that(view.get_camera_for_test().size > base_size, "scale: snapped 112 percent should widen the close default framing")
	_assert.that(main.runtime.battlefield is Node2D, "scale: authoritative battlefield remains 2D")
	_assert.that(main.runtime.bullet_pool is Node2D, "scale: authoritative projectile pool remains 2D")
	_assert.eq(view.get_gate_count_for_test(), 2, "scale: gate presentation should remain intact")
	_assert.eq(view.get_turret_proxy_count_for_test(), 2, "scale: both command chambers should remain represented")
	_assert_runtime_hud_chrome(main)

	TestFixtures.cleanup_node(main)
	await _flush()


func _assert_runtime_hud_chrome(main) -> void:
	var battlefield_rect: Rect2 = main.runtime.current_layout.get("battlefield_rect", Rect2())
	var viewport_size: Vector2 = main.get_viewport().get_visible_rect().size
	if viewport_size.x < 1.0 or viewport_size.y < 1.0:
		viewport_size = DESKTOP_VIEWPORT
	var screen_rect := Rect2(Vector2.ZERO, viewport_size)
	var ui_canvas = main.runtime.hud.get("ui_canvas", null)
	var aim_control = main.runtime.aim_control
	var hero_hud = main.runtime.battle_hero_hud
	_assert.that(ui_canvas != null and is_instance_valid(ui_canvas), "hierarchy: Cardfront HUD canvas should exist")
	_assert.that(aim_control != null and is_instance_valid(aim_control), "hierarchy: compact aim control should exist")
	_assert.that(hero_hud != null and is_instance_valid(hero_hud), "hierarchy: both hero identity plates should exist")
	if ui_canvas == null or aim_control == null or hero_hud == null:
		return

	var chrome_controls: Array[Control] = [
		ui_canvas.get_node("TopPanel") as Control,
		ui_canvas.get_node("SettingsButton") as Control,
		ui_canvas.get_node("PauseButton") as Control,
		aim_control.get_node("Panel") as Control,
		hero_hud.get_node("PlayerPlate") as Control,
		hero_hud.get_node("AiPlate") as Control,
	]
	var chrome_area: float = 0.0
	for control in chrome_controls:
		var control_rect := control.get_global_rect()
		chrome_area += control_rect.get_area()
		_assert.that(control.is_visible_in_tree(), "hierarchy: expected persistent chrome should remain visible (%s)" % control.name)
		_assert.that(screen_rect.grow(0.5).encloses(control_rect), "hierarchy: persistent chrome should stay inside the runtime viewport (%s: %s within %s)" % [control.name, control_rect, screen_rect])
		_assert.that(not control_rect.intersects(battlefield_rect), "hierarchy: persistent chrome should not cover the central battlefield (%s)" % control.name)

	var chrome_ratio: float = chrome_area / screen_rect.get_area()
	_assert.that(chrome_ratio <= MAX_PERSISTENT_CHROME_RATIO, "hierarchy: persistent runtime chrome should occupy at most 12 percent of the viewport (actual %.2f%%)" % (chrome_ratio * 100.0))


func _test_narrow_viewport_layout_and_chrome_bounds() -> void:
	var base_layout: Dictionary = LayoutCoordinator.calculate_layout(40, NARROW_VIEWPORT, true)
	var layout: Dictionary = CardfrontArenaLayoutScript.apply_to(base_layout, Vector2i(40, 40), NARROW_VIEWPORT)
	var screen_rect := Rect2(Vector2.ZERO, NARROW_VIEWPORT)
	var arena_rect: Rect2 = layout.get("arena_view_rect", Rect2())
	var battlefield_rect: Rect2 = layout.get("battlefield_rect", Rect2())
	_assert.that(screen_rect.encloses(arena_rect), "narrow hierarchy: orthographic arena viewport should stay inside 760x540")
	_assert.that(screen_rect.encloses(battlefield_rect), "narrow hierarchy: logical battlefield should stay inside 760x540")
	_assert.that(arena_rect.encloses(battlefield_rect), "narrow hierarchy: logical battlefield should remain inside the orthographic arena viewport")
	_assert.that(arena_rect.end.y >= NARROW_VIEWPORT.y - 12.0, "narrow hierarchy: arena should use the lower screen instead of leaving a broad empty band")

	var narrow_viewport := SubViewport.new()
	narrow_viewport.name = "NarrowHierarchyViewport"
	narrow_viewport.size = Vector2i(NARROW_VIEWPORT)
	narrow_viewport.gui_disable_input = true
	root.add_child(narrow_viewport)

	var hud = CardfrontHUDScene.instantiate()
	narrow_viewport.add_child(hud)
	var direction_controller = CardfrontDirectionControllerScript.new()
	narrow_viewport.add_child(direction_controller)
	var aim_control = CardfrontAimControlScene.instantiate()
	narrow_viewport.add_child(aim_control)
	await process_frame

	hud.setup_static(null, NARROW_VIEWPORT, layout, true)
	_assert.gte((hud.get_node("TopPanel") as Control).size.x, 420.0, "narrow hierarchy: top match HUD should retain a readable minimum width")
	_assert.gte((hud.get_node("TopPanel/LeaderLabel") as Label).get_theme_font_size("font_size"), 14, "narrow hierarchy: top match HUD labels should retain a readable minimum font")
	_assert.that(aim_control.setup(direction_controller, layout, GameConfig.GAME_MODE_CARDFRONT), "narrow hierarchy: aim control should configure in the narrow viewport")
	await process_frame

	var chrome_controls: Array[Control] = [
		hud.get_node("TopPanel") as Control,
		hud.get_node("SettingsButton") as Control,
		hud.get_node("PauseButton") as Control,
		aim_control.get_node("Panel") as Control,
	]
	var chrome_area: float = 0.0
	for control in chrome_controls:
		var control_rect := control.get_global_rect()
		chrome_area += control_rect.get_area()
		_assert.that(screen_rect.grow(0.5).encloses(control_rect), "narrow hierarchy: live chrome should stay inside 760x540 (%s)" % control.name)
		_assert.that(not control_rect.intersects(battlefield_rect), "narrow hierarchy: live chrome should not cover the central battlefield (%s)" % control.name)

	var chrome_ratio: float = chrome_area / screen_rect.get_area()
	_assert.that(chrome_ratio <= MAX_PERSISTENT_CHROME_RATIO, "narrow hierarchy: live chrome should occupy at most 12 percent of the viewport (actual %.2f%%)" % (chrome_ratio * 100.0))
	_assert.eq(narrow_viewport.find_child("CardfrontBattlefieldScaleControl", true, false), null, "narrow hierarchy: scale debug widget should remain absent")

	TestFixtures.cleanup_node(narrow_viewport)
	await _flush()


func _test_ballwar_does_not_create_scale_control() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)
	_assert.eq(main.runtime.orthographic_arena_view, null, "scale: BallWar should not create the Cardfront orthographic view")
	_assert.eq(main.runtime.battlefield_scale_control, null, "scale: BallWar should not create the Cardfront scale control")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, grid_size: int):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	main._start_game(grid_size, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
