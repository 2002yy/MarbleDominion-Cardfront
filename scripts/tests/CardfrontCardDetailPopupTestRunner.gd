extends SceneTree

const FeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")
const ResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const DetailPopupScene = preload("res://scenes/ui/cardfront/CardfrontCardDetailPopup.tscn")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardDetailPopupTest] Starting card detail popup tests")
	await process_frame

	_test_hover_shows_popup()
	_test_unhover_hides_popup()
	_test_not_enough_resource_text()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontCardDetailPopupTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture() -> Dictionary:
	var bus = FeedbackBusScript.new()
	get_root().add_child(bus)

	var state = ResourceStateScript.new()
	var popup = DetailPopupScene.instantiate()
	get_root().add_child(popup)
	popup.setup(bus, state, GameConfig.GAME_MODE_CARDFRONT)

	var view := Panel.new()
	view.size = Vector2(130, 150)
	view.position = Vector2(360, 520)
	get_root().add_child(view)

	return {
		"bus": bus,
		"state": state,
		"popup": popup,
		"view": view,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("popup", null))
	TestFixtures.cleanup_node(fixture.get("view", null))
	TestFixtures.cleanup_node(fixture.get("bus", null))


func _sample_card(cost_energy: int = 5, cost_parts: int = 2) -> Dictionary:
	return {
		"id": 1001,
		"card_name": "前线加固",
		"card_type": "fortify",
		"energy_cost": cost_energy,
		"parts_cost": cost_parts,
		"target_type": "owned_border",
		"effect_id": "fortify_border",
		"used": false,
	}


func _test_hover_shows_popup() -> void:
	var fixture = _make_fixture()
	fixture.state.add_energy(20)
	fixture.state.add_parts(20)
	fixture.bus.emit_card_hovered(1001, _sample_card(), fixture.view)
	_assert.that(fixture.popup.visible, "detail popup: hover should show popup")
	_cleanup_fixture(fixture)


func _test_unhover_hides_popup() -> void:
	var fixture = _make_fixture()
	fixture.state.add_energy(20)
	fixture.state.add_parts(20)
	var card: Dictionary = _sample_card()
	fixture.bus.emit_card_hovered(1001, card, fixture.view)
	fixture.bus.emit_card_unhovered(1001, card, fixture.view)
	_assert.that(not fixture.popup.visible, "detail popup: unhover should hide popup")
	_cleanup_fixture(fixture)


func _test_not_enough_resource_text() -> void:
	var fixture = _make_fixture()
	fixture.bus.emit_card_hovered(1001, _sample_card(99, 99), fixture.view)
	_assert.that(fixture.popup.visible, "detail popup: resource-poor hover should still show popup")
	_assert.that(fixture.popup.get_status_text_for_test().contains("资源不足"), "detail popup: should show resource shortage")
	_cleanup_fixture(fixture)
