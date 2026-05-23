extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontRegionInfoPanelVisibilityTest] Starting region info panel visibility tests")
	await process_frame

	await _test_panel_is_bright_large_and_off_map()
	await _test_ballwar_does_not_create_region_panel()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontRegionInfoPanelVisibilityTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(mode_name)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _test_panel_is_bright_large_and_off_map() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	await _flush()

	_assert.that(main.runtime.region_info_panel != null, "region panel should exist in Cardfront")
	if main.runtime.region_info_panel != null:
		main.runtime.region_info_panel.update_for_cell(Vector2i(-1, -1))
		await _flush()
		var region_panel = main.runtime.region_info_panel._panel
		_assert.that(region_panel != null, "region panel node should exist")
		if region_panel != null:
			var viewport_size: Vector2 = main.runtime.current_layout.get("viewport_size", Vector2(1120.0, 720.0))
			var battlefield_rect: Rect2 = main.runtime.current_layout.get("battlefield_rect", Rect2())
			var panel_rect := Rect2(region_panel.global_position, region_panel.size)
			var bg = region_panel.get_node_or_null("Bg")
			var title_label = main.runtime.region_info_panel._title_label

			_assert.gte(region_panel.size.x, 240.0, "region panel should be wider and readable")
			_assert.gte(region_panel.size.y, 180.0, "region panel should be taller and readable")
			_assert.gte(region_panel.self_modulate.a, 0.95, "region panel should be visually solid")
			_assert.gte(region_panel.self_modulate.r + region_panel.self_modulate.g + region_panel.self_modulate.b, 0.60, "region panel should be brighter")
			_assert.that(bg is ColorRect, "region panel should keep background node")
			if bg is ColorRect:
				_assert.gte(bg.color.a, 0.84, "region panel background should be clear")
			_assert.that(title_label is Label, "region panel should keep title label")
			if title_label is Label:
				_assert.gte(title_label.get_theme_font_size("font_size"), 16, "region title font should be larger")

			_assert.gte(panel_rect.position.x, battlefield_rect.position.x + battlefield_rect.size.x + 8.0, "region panel should not overlap the battlefield map")
			_assert.that(not panel_rect.intersects(battlefield_rect), "region panel rect should stay outside battlefield rect")
			_assert.gte(viewport_size.x - (panel_rect.position.x + panel_rect.size.x), 8.0, "region panel should stay inside the viewport")

			var settings_button = main.runtime.hud.get("settings_button", null)
			if settings_button != null:
				_assert.gte(settings_button.global_position.y, panel_rect.position.y + panel_rect.size.y + 8.0, "settings button should remain below brighter region panel")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_does_not_create_region_panel() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	await _flush()

	_assert.eq(main.runtime.region_info_panel, null, "BallWar should not create Cardfront region panel")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
