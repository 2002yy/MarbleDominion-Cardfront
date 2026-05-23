extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTopResourceBarMinimalTest] Starting top resource bar minimal tests")
	await process_frame

	_test_cardfront_minibar_only_shows_player_values()
	_test_ballwar_has_no_cardfront_minibar()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontTopResourceBarMinimalTest]")
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


func _test_cardfront_minibar_only_shows_player_values() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	var bar = main.runtime.top_resource_bar
	_assert.that(bar != null, "top minibar: Cardfront should create top resource bar")
	if bar != null:
		_assert.that(bar.visible, "top minibar: top resource bar should be visible")
		var margin = bar.get_node_or_null("Margin")
		_assert.that(margin is Control, "top minibar: Margin should exist")
		if margin is Control:
			_assert.gte(220.0, (margin as Control).size.x, "top minibar: resource bar should stay compact")
		_assert.that(bar.get_node_or_null("Margin/HBox/EnergyBox/Margin2/Inner/Value") is Label, "top minibar: energy value should exist")
		_assert.that(bar.get_node_or_null("Margin/HBox/PartsBox/Margin2/Inner/Value") is Label, "top minibar: parts value should exist")
		var energy_value = bar.get_node_or_null("Margin/HBox/EnergyBox/Margin2/Inner/Value") as Label
		var parts_value = bar.get_node_or_null("Margin/HBox/PartsBox/Margin2/Inner/Value") as Label
		_assert.that(str(energy_value.text).is_valid_int(), "top minibar: energy should be numeric")
		_assert.that(str(parts_value.text).is_valid_int(), "top minibar: parts should be numeric")
		_assert.eq(bar.get_node_or_null("Margin/HBox/EnergyBox/Margin2/Inner/Name"), null, "top minibar: energy name label should be removed")
		_assert.eq(bar.get_node_or_null("Margin/HBox/PartsBox/Margin2/Inner/Name"), null, "top minibar: parts name label should be removed")
		_assert.eq(bar.get_node_or_null("Margin/HBox/YieldLabel"), null, "top minibar: yield label should be removed")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_has_no_cardfront_minibar() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.top_resource_bar, null, "top minibar: BallWar should not create Cardfront top resource bar")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
