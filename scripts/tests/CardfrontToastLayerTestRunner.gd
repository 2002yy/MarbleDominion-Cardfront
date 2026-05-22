extends SceneTree

const FeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")
const ToastLayerScene = preload("res://scenes/ui/cardfront/CardfrontToastLayer.tscn")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontToastLayerTest] Starting toast layer tests")
	await process_frame

	_test_toast_added()
	_test_toast_max_three()
	_test_toast_auto_expires()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontToastLayerTest]")
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
	var layer = ToastLayerScene.instantiate()
	get_root().add_child(layer)
	layer.setup(bus, GameConfig.GAME_MODE_CARDFRONT, Vector2(1120, 720))
	return {"bus": bus, "layer": layer}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("layer", null))
	TestFixtures.cleanup_node(fixture.get("bus", null))


func _test_toast_added() -> void:
	var fixture = _make_fixture()
	fixture.layer.show_toast("目标无效", "warn")
	_assert.eq(fixture.layer.get_toast_count_for_test(), 1, "toast: show_toast should add one item")
	_cleanup_fixture(fixture)


func _test_toast_max_three() -> void:
	var fixture = _make_fixture()
	fixture.layer.show_toast("one")
	fixture.layer.show_toast("two")
	fixture.layer.show_toast("three")
	fixture.layer.show_toast("four")
	_assert.eq(fixture.layer.get_toast_count_for_test(), 3, "toast: should keep at most 3 items")
	var texts: Array[String] = fixture.layer.get_toast_texts_for_test()
	_assert.that(not texts.has("one"), "toast: oldest item should be removed")
	_cleanup_fixture(fixture)


func _test_toast_auto_expires() -> void:
	var fixture = _make_fixture()
	fixture.layer.show_toast("expires", "info", 0.2)
	fixture.layer._process(0.25)
	_assert.eq(fixture.layer.get_toast_count_for_test(), 0, "toast: item should auto expire")
	_cleanup_fixture(fixture)
