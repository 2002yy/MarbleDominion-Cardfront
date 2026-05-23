extends SceneTree

const CardfrontCardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")
const CardfrontFeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDisabledCardFeedbackTest] Starting disabled card feedback tests")
	await process_frame

	await _test_resource_disabled_card_click_feedback()
	await _test_used_card_click_feedback()

	await _flush()
	_assert.report("[CardfrontDisabledCardFeedbackTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _sample_card(card_id: int = 1001, used: bool = false) -> Dictionary:
	return {
		"id": card_id,
		"card_name": "Frontline Fortify",
		"type": "structure",
		"target_type": "owned_border",
		"energy_cost": 10,
		"parts_cost": 3,
		"used": used,
	}


func _make_view(card_data: Dictionary, resource_state) -> Dictionary:
	var view = CardfrontCardViewScene.instantiate()
	get_root().add_child(view)
	await _flush()

	var bus = CardfrontFeedbackBusScript.new()
	get_root().add_child(bus)
	var counts := {"clicked": 0, "failed": 0, "callback": 0, "reason": ""}
	bus.card_clicked.connect(func(card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_id == int(card_data.id) and card_view == view:
			counts.clicked += 1
	)
	bus.card_play_failed.connect(func(card_id: int, _card_data: Dictionary, result: Dictionary) -> void:
		if card_id == int(card_data.id):
			counts.failed += 1
			counts.reason = str(result.get("reason", ""))
	)
	view.set_feedback_bus(bus)
	view.clicked_callback = func() -> void:
		counts.callback += 1
		view.set_state("selected")
	view.bind(card_data, resource_state)
	return {"view": view, "bus": bus, "counts": counts}


func _click_view(view: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	view.emit_signal("gui_input", event)


func _test_resource_disabled_card_click_feedback() -> void:
	var poor_state = CardfrontResourceStateScript.new()
	var fixture := await _make_view(_sample_card(1001, false), poor_state)
	var view: Control = fixture.view
	var counts: Dictionary = fixture.counts

	_assert.eq(view.current_state, "disabled_resource", "disabled feedback: card should bind as resource-disabled")
	_click_view(view)
	_assert.eq(counts.clicked, 1, "disabled feedback: resource-disabled click should emit card_clicked")
	_assert.eq(counts.failed, 1, "disabled feedback: resource-disabled click should emit card_play_failed")
	_assert.eq(counts.reason, "not_enough_resource", "disabled feedback: resource-disabled reason should be not_enough_resource")
	_assert.eq(counts.callback, 0, "disabled feedback: resource-disabled card should not call clicked_callback")
	_assert.neq(view.current_state, "selected", "disabled feedback: resource-disabled card should not become selected")

	TestFixtures.cleanup_node(fixture.view)
	TestFixtures.cleanup_node(fixture.bus)


func _test_used_card_click_feedback() -> void:
	var rich_state = CardfrontResourceStateScript.new()
	rich_state.add_energy(100)
	rich_state.add_parts(100)
	var fixture := await _make_view(_sample_card(1001, true), rich_state)
	var view: Control = fixture.view
	var counts: Dictionary = fixture.counts

	_assert.eq(view.current_state, "used", "disabled feedback: used card should bind as used")
	_click_view(view)
	_assert.eq(counts.clicked, 1, "disabled feedback: used click should emit card_clicked")
	_assert.eq(counts.failed, 1, "disabled feedback: used click should emit card_play_failed")
	_assert.eq(counts.reason, "card_already_used", "disabled feedback: used reason should be card_already_used")
	_assert.eq(counts.callback, 0, "disabled feedback: used card should not call clicked_callback")
	_assert.neq(view.current_state, "selected", "disabled feedback: used card should not become selected")

	TestFixtures.cleanup_node(fixture.view)
	TestFixtures.cleanup_node(fixture.bus)
