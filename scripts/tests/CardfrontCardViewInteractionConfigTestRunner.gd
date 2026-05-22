extends SceneTree

const CardfrontCardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")
const CardfrontFeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardViewInteractionConfigTest] Starting card view interaction config tests")
	await process_frame

	var fixture := await _make_fixture()
	_test_root_accepts_input(fixture.view)
	_test_decor_children_ignore_input(fixture.view)
	_test_signal_connections_exist(fixture.view)
	_test_hover_signal_reaches_feedback_bus(fixture.view, fixture.bus, fixture.counts)
	_test_click_signal_reaches_feedback_bus(fixture.view, fixture.bus, fixture.counts)
	TestFixtures.cleanup_node(fixture.view)
	TestFixtures.cleanup_node(fixture.bus)

	await _flush()
	_assert.report("[CardfrontCardViewInteractionConfigTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture() -> Dictionary:
	var view = CardfrontCardViewScene.instantiate()
	get_root().add_child(view)
	await _flush()

	var bus = CardfrontFeedbackBusScript.new()
	get_root().add_child(bus)
	var counts := {"hovered": 0, "clicked": 0, "callback": 0}
	bus.card_hovered.connect(func(card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_id == 1001 and card_view == view:
			counts.hovered += 1
	)
	bus.card_clicked.connect(func(card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_id == 1001 and card_view == view:
			counts.clicked += 1
	)
	view.set_feedback_bus(bus)
	view.clicked_callback = func() -> void:
		counts.callback += 1
	view.bind(_sample_card(), null)
	return {"view": view, "bus": bus, "counts": counts}


func _sample_card() -> Dictionary:
	return {
		"id": 1001,
		"card_name": "Frontline Fortify",
		"type": "structure",
		"target_type": "owned_border",
		"energy_cost": 0,
		"parts_cost": 0,
		"used": false,
	}


func _test_root_accepts_input(view: Control) -> void:
	_assert.that(view.mouse_filter != Control.MOUSE_FILTER_IGNORE, "card view input: root must not ignore mouse input")
	_assert.eq(view.mouse_filter, Control.MOUSE_FILTER_STOP, "card view input: root should stop mouse input")


func _test_decor_children_ignore_input(view: Control) -> void:
	var decorative_names := [
		"CardBorder",
		"Bg",
		"HoverBorder",
		"SelectedBorder",
		"CardIcon",
		"CardIconBorder",
		"CardIconLabel",
		"CardArt",
		"CardName",
		"CostEnergy",
		"CostParts",
		"TargetLabel",
		"StatusLabel",
	]
	for node_name in decorative_names:
		var child = view.get_node_or_null(node_name)
		_assert.that(child is Control, "card view input: %s should be a Control" % node_name)
		if child is Control:
			_assert.eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "card view input: %s should ignore mouse input" % node_name)


func _test_signal_connections_exist(view: Control) -> void:
	_assert.that(view.mouse_entered.is_connected(Callable(view, "_on_mouse_entered")), "card view input: mouse_entered should be connected")
	_assert.that(view.mouse_exited.is_connected(Callable(view, "_on_mouse_exited")), "card view input: mouse_exited should be connected")
	_assert.that(view.gui_input.is_connected(Callable(view, "_on_gui_input")), "card view input: gui_input should be connected")


func _test_hover_signal_reaches_feedback_bus(view: Control, _bus: Node, counts: Dictionary) -> void:
	view.emit_signal("mouse_entered")
	_assert.eq(counts.hovered, 1, "card view input: hover should reach feedback bus")
	_assert.eq(view.current_state, "hover", "card view input: hover should update visual state")


func _test_click_signal_reaches_feedback_bus(view: Control, _bus: Node, counts: Dictionary) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	view.emit_signal("gui_input", event)
	_assert.eq(counts.clicked, 1, "card view input: click should reach feedback bus")
	_assert.eq(counts.callback, 1, "card view input: click should preserve clicked_callback")
