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
			_assert.that(not region_panel.visible, "region panel should collapse outside a stronghold")
			var region_ids: Array = main.runtime.region_map.get_controllable_region_ids()
			if not region_ids.is_empty():
				var region_cells: Array = main.runtime.region_map.get_region_cells(int(region_ids[0]))
				if not region_cells.is_empty():
					main.runtime.region_info_panel.update_for_cell(region_cells[0])
					_assert.that(region_panel.visible, "region panel should appear contextually over a stronghold")
					_assert.that(main.runtime.region_info_panel._title_label.text.contains("能源"), "region panel hover state should expose the full resource name")
					_assert.that(main.runtime.region_info_panel.toggle_pinned_cell(region_cells[0]), "region panel should pin on the first click or touch")
					_assert.that(main.runtime.region_info_panel.is_region_pinned_for_test(), "region panel should report its pinned interaction state")
					main.runtime.region_info_panel.update_for_cell(Vector2i(-1, -1))
					_assert.that(region_panel.visible, "region panel should survive pointer exit while pinned")
					_assert.that(main.runtime.region_info_panel._title_label.text.contains("固定"), "region panel should make the pinned state explicit")
					_assert.that(not main.runtime.region_info_panel.toggle_pinned_cell(region_cells[0]), "clicking the pinned region again should release it")
					main.runtime.region_info_panel.update_for_cell(Vector2i(-1, -1))
					_assert.that(not region_panel.visible, "region panel should collapse after unpinning outside a stronghold")
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT
					click.pressed = true
					click.position = main.runtime.battlefield.to_global(
						(Vector2(region_cells[0]) + Vector2.ONE * 0.5) * float(main.runtime.battlefield.cell_size)
					)
					main._handle_region_info_pin_input(click)
					_assert.that(main.runtime.region_info_panel.is_region_pinned_for_test(), "Main should route a battlefield click into the contextual pin layer")
					main.runtime.region_info_panel.clear_pinned_region()
					main.runtime.region_info_panel.update_for_cell(region_cells[0])
					var threshold_text: String = str(main.runtime.region_info_panel._threshold_80.text)
					var stronghold_text: String = str(main.runtime.region_info_panel._stronghold_label.text)
					var semantic_text: String = "%s %s" % [threshold_text, stronghold_text]
					_assert.that(threshold_text.begins_with("据点控制："), "region panel: 80 percent line should describe control status, not a retired ability")
					_assert.that(stronghold_text.begins_with("据点状态："), "region panel: stronghold line should describe current status")
					for retired_text in ["据点能力", "四选一", "+3", "+1", "攻击等级", "额外发射"]:
						_assert.that(not semantic_text.contains(retired_text), "region panel: retired stronghold promise must stay absent: %s" % retired_text)
			var viewport_size: Vector2 = main.runtime.current_layout.get("viewport_size", Vector2(1120.0, 720.0))
			var battlefield_rect: Rect2 = main.runtime.orthographic_arena_view.get_playable_screen_rect_for_ui()
			var panel_rect := Rect2(region_panel.global_position, region_panel.size)
			var bg = region_panel.get_node_or_null("Bg")
			var title_label = main.runtime.region_info_panel._title_label

			_assert.that(region_panel.size.x <= 188.0 and region_panel.size.x >= 184.0, "region panel should be compact but readable")
			_assert.that(region_panel.size.y <= 194.0 and region_panel.size.y >= 188.0, "region panel should preserve readable body text without becoming a tall overlay")
			_assert.gte(region_panel.self_modulate.a, 0.95, "region panel should be visually solid")
			_assert.gte(region_panel.self_modulate.r + region_panel.self_modulate.g + region_panel.self_modulate.b, 0.60, "region panel should be brighter")
			_assert.that(bg is ColorRect, "region panel should keep background node")
			if bg is ColorRect:
				_assert.gte(bg.color.a, 0.84, "region panel background should be clear")
			_assert.that(title_label is Label, "region panel should keep title label")
			if title_label is Label:
				_assert.gte(title_label.get_theme_font_size("font_size"), 16, "region title font should remain readable")
			_assert.gte(main.runtime.region_info_panel._threshold_80.get_theme_font_size("font_size"), 12, "region detail body text should remain readable at narrow width")

			_assert.gte(panel_rect.position.x, battlefield_rect.position.x + battlefield_rect.size.x + 8.0, "region panel should not overlap the battlefield map")
			_assert.that(not panel_rect.intersects(battlefield_rect), "region panel rect should stay outside battlefield rect")
			_assert.gte(viewport_size.x - (panel_rect.position.x + panel_rect.size.x), 8.0, "region panel should stay inside the viewport")

			var settings_button = main.runtime.hud.get("settings_button", null)
			if settings_button != null:
				var settings_rect := Rect2(settings_button.global_position, settings_button.size)
				_assert.that(not settings_rect.intersects(panel_rect), "compact settings button should stay beside rather than cover the region panel")
				_assert.that(settings_button.size.x <= 70.0 and settings_button.size.y <= 30.0, "region panel: settings button should stay compact")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_does_not_create_region_panel() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	await _flush()

	_assert.eq(main.runtime.region_info_panel, null, "BallWar should not create Cardfront region panel")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
