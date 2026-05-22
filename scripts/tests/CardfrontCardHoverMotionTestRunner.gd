extends SceneTree

const CardfrontCardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")
const CardfrontFeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardHoverMotionTest] Starting card hover motion tests")
	await process_frame

	var f1 := await _make_fixture()
	_test_initial_collapsed_offset(f1.view)
	await _test_mouse_entered_expands(f1.view)
	TestFixtures.cleanup_node(f1.view)
	TestFixtures.cleanup_node(f1.bus)

	var f2 := await _make_fixture()
	await _test_mouse_exited_collapses(f2.view)
	TestFixtures.cleanup_node(f2.view)
	TestFixtures.cleanup_node(f2.bus)

	var f3 := await _make_fixture()
	await _test_clicked_callback_unchanged(f3.view)
	TestFixtures.cleanup_node(f3.view)
	TestFixtures.cleanup_node(f3.bus)

	var f4 := await _make_fixture()
	await _test_feedback_bus_signals_unchanged(f4)
	TestFixtures.cleanup_node(f4.view)
	TestFixtures.cleanup_node(f4.bus)

	await _flush()
	_assert.report("[CardfrontCardHoverMotionTest]")
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
	await _flush()

	var counts := {"hovered": 0, "clicked": 0, "callback": 0}
	bus.card_hovered.connect(func(cid: int, _data: Dictionary, _cv: Control) -> void:
		if cid == 1001:
			counts.hovered += 1
	)
	bus.card_clicked.connect(func(cid: int, _data: Dictionary, _cv: Control) -> void:
		if cid == 1001:
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


func _test_initial_collapsed_offset(view: Control) -> void:
	_assert.that(view.position.y >= 58.0, "initial card position.y should be >= 58 (collapsed)")


func _test_mouse_entered_expands(view: Control) -> void:
	view.emit_signal("mouse_entered")
	await create_timer(0.3).timeout
	_assert.eq(view.z_index, 30, "mouse_entered should set z_index to 30")
	_assert.that(view.scale.x > 1.01, "mouse_entered should scale card up (x > 1.01)")
	_assert.that(view.scale.y > 1.01, "mouse_entered should scale card up (y > 1.01)")
	_assert.that(view.position.y < 10.0, "mouse_entered should move card near y=0")


func _test_mouse_exited_collapses(view: Control) -> void:
	view.emit_signal("mouse_entered")
	await create_timer(0.3).timeout
	_assert.that(view.position.y < 10.0, "card should be expanded before mouse_exit test")

	view.emit_signal("mouse_exited")
	await create_timer(0.3).timeout
	_assert.eq(view.z_index, 0, "mouse_exited should reset z_index to 0")
	_assert.that(view.scale.x == 1.0, "mouse_exited should reset scale.x to 1.0")
	_assert.that(view.scale.y == 1.0, "mouse_exited should reset scale.y to 1.0")
	_assert.gte(view.position.y, 58.0, "mouse_exited should move card back to collapsed offset")


func _test_clicked_callback_unchanged(view: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	view.emit_signal("gui_input", event)
	_assert.that(view.current_state == "idle", "gui_input click should not change state by itself")
	_assert.that(view.clicked_callback != Callable(), "clicked_callback should exist")


func _test_feedback_bus_signals_unchanged(fixture: Dictionary) -> void:
	var view = fixture.view
	var counts = fixture.counts
	view.emit_signal("mouse_entered")
	_assert.eq(counts.hovered, 1, "mouse_entered should emit card_hovered via feedback bus")

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	view.emit_signal("gui_input", event)
	_assert.eq(counts.clicked, 1, "gui_input click should emit card_clicked via feedback bus")
