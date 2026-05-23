extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontHandRealHitboxTest] Starting hand real hitbox tests")
	await process_frame

	var main = _make_main()
	await _flush()
	_test_hand_panel_hitbox_config(main)
	_test_card_views_intersect_screen(main)
	await _test_collapsed_visible_area_clicks(main)
	await _test_hover_expanded_card_clicks(main)
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontHandRealHitboxTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_main():
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _test_hand_panel_hitbox_config(main) -> void:
	var hand_panel = main.runtime.hand_panel
	_assert.that(hand_panel != null, "hand hitbox: Cardfront should create hand_panel")
	if hand_panel == null:
		return
	var card_box = hand_panel.get_node_or_null("CardHBox")
	var panel_bg = hand_panel.get_node_or_null("PanelBg")
	var panel_border = hand_panel.get_node_or_null("PanelBorder")
	_assert.that(card_box is Control, "hand hitbox: CardHBox should be a Control")
	if card_box is Control:
		_assert.gte((card_box as Control).size.y, 150.0, "hand hitbox: CardHBox height should cover card views")
		_assert.eq((card_box as Control).mouse_filter, Control.MOUSE_FILTER_PASS, "hand hitbox: CardHBox should pass mouse input")
	_assert.that(panel_bg is Control, "hand hitbox: PanelBg should be a Control")
	if panel_bg is Control:
		_assert.eq((panel_bg as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "hand hitbox: PanelBg should ignore mouse input")
	_assert.that(panel_border is Control, "hand hitbox: PanelBorder should be a Control")
	if panel_border is Control:
		_assert.eq((panel_border as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "hand hitbox: PanelBorder should ignore mouse input")


func _test_card_views_intersect_screen(main) -> void:
	var hand_panel = main.runtime.hand_panel
	if hand_panel == null:
		return
	var screen_rect := Rect2(Vector2.ZERO, get_root().get_visible_rect().size)
	var views: Array = hand_panel._card_views
	_assert.eq(views.size(), 4, "hand hitbox: hand panel should have 4 card views")
	for i in range(views.size()):
		var view: Control = views[i]
		var rect := view.get_global_rect()
		_assert.that(screen_rect.intersects(rect), "hand hitbox: card view %d should have a visible on-screen rect" % i)
		_assert.gte(rect.position.x, 0.0, "hand hitbox: card view %d should not start left of screen" % i)
		_assert.gte(rect.position.y, 0.0, "hand hitbox: card view %d should not start above screen" % i)
		_assert.that(rect.position.x < screen_rect.size.x, "hand hitbox: card view %d should start before screen right edge" % i)
		_assert.that(rect.position.y < screen_rect.size.y, "hand hitbox: card view %d should start before screen bottom edge" % i)


func _test_collapsed_visible_area_clicks(main) -> void:
	var hand_panel = main.runtime.hand_panel
	if hand_panel == null or hand_panel._card_views.is_empty():
		return
	var view: Control = hand_panel._card_views[0]
	var counts := {"clicked": 0}
	main.runtime.cardfront_feedback_bus.card_clicked.connect(func(_card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_view == view:
			counts.clicked += 1
	)
	await _click_at(_visible_click_point(view))
	_assert.eq(counts.clicked, 1, "hand hitbox: collapsed visible card area should receive real mouse click")


func _test_hover_expanded_card_clicks(main) -> void:
	var hand_panel = main.runtime.hand_panel
	if hand_panel == null or hand_panel._card_views.size() < 2:
		return
	var view: Control = hand_panel._card_views[1]
	var counts := {"clicked": 0}
	main.runtime.cardfront_feedback_bus.card_clicked.connect(func(_card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_view == view:
			counts.clicked += 1
	)
	view.emit_signal("mouse_entered")
	await create_timer(0.25).timeout
	await _click_at(_visible_click_point(view))
	_assert.eq(counts.clicked, 1, "hand hitbox: hover-expanded card should receive real mouse click")


func _visible_click_point(view: Control) -> Vector2:
	var rect := view.get_global_rect()
	var screen_size := get_root().get_visible_rect().size
	var parent_rect := Rect2(Vector2.ZERO, screen_size)
	if view.get_parent() is Control:
		parent_rect = (view.get_parent() as Control).get_global_rect()
	var left: float = maxf(rect.position.x, maxf(parent_rect.position.x, 0.0))
	var top: float = maxf(rect.position.y, maxf(parent_rect.position.y, 0.0))
	var right: float = minf(rect.end.x, minf(parent_rect.end.x, screen_size.x))
	var bottom: float = minf(rect.end.y, minf(parent_rect.end.y, screen_size.y))
	var x: float = clampf((left + right) * 0.5, 1.0, screen_size.x - 2.0)
	var y: float = clampf((top + bottom) * 0.5, 1.0, screen_size.y - 2.0)
	return Vector2(x, y)


func _click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_root().push_input(motion, true)
	await _flush()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	get_root().push_input(press, true)
	await _flush()

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	get_root().push_input(release, true)
	await _flush()
