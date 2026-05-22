extends SceneTree

const CardVisualRegistryScript = preload("res://scripts/cardfront/ui/CardVisualRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardArtBindingTest] Starting card art binding tests")
	await process_frame

	_test_card_1001_path_exists()
	_test_card_1002_path_exists()
	_test_card_1003_path_exists()
	_test_card_1004_path_registered()
	_test_missing_card_returns_empty_path()
	_test_thumbnail_paths_registered()
	_test_thumbnail_paths_exist()
	_test_card_view_bind_does_not_crash()
	_test_card_view_fallback_on_missing_image()
	_test_card_view_thumbnail_loaded_via_bind()
	_test_ballwar_no_card_ui()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontCardArtBindingTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_card_1001_path_exists() -> void:
	var path: String = CardVisualRegistryScript.get_texture_path(1001)
	_assert.neq(path, "", "1001 frontline_fortify should have a path")
	if path != "":
		_assert.that(ResourceLoader.exists(path), "1001 texture should exist at: %s" % path)


func _test_card_1002_path_exists() -> void:
	var path: String = CardVisualRegistryScript.get_texture_path(1002)
	_assert.neq(path, "", "1002 calibrated_shot should have a path")
	if path != "":
		_assert.that(ResourceLoader.exists(path), "1002 texture should exist at: %s" % path)


func _test_card_1003_path_exists() -> void:
	var path: String = CardVisualRegistryScript.get_texture_path(1003)
	_assert.neq(path, "", "1003 morale_fluctuation should have a path")
	if path != "":
		_assert.that(ResourceLoader.exists(path), "1003 texture should exist at: %s" % path)


func _test_card_1004_path_registered() -> void:
	_assert.that(CardVisualRegistryScript.has_texture(1004), "1004 pioneer_beacon should be registered")
	var path: String = CardVisualRegistryScript.get_texture_path(1004)
	_assert.neq(path, "", "1004 pioneer_beacon should have a path")
	if path != "":
		var exists_via_loader: bool = ResourceLoader.exists(path)
		var exists_raw: bool = FileAccess.file_exists(path)
		_assert.that(exists_via_loader or exists_raw, "1004 pioneer_beacon PNG should exist on disk (loader=%s, raw=%s)" % [str(exists_via_loader), str(exists_raw)])


func _test_missing_card_returns_empty_path() -> void:
	_assert.that(not CardVisualRegistryScript.has_texture(9999), "unknown card 9999 should not be registered")
	_assert.eq(CardVisualRegistryScript.get_texture_path(9999), "", "unknown card should return empty path")


func _test_thumbnail_paths_registered() -> void:
	var card_ids := [1001, 1002, 1003, 1004]
	for card_id in card_ids:
		var path: String = CardVisualRegistryScript.get_thumbnail_path(card_id)
		_assert.neq(path, "", "%d thumbnail path should not be empty" % card_id)
		_assert.that(CardVisualRegistryScript.has_thumbnail(card_id), "%d has_thumbnail should be true" % card_id)


func _test_thumbnail_paths_exist() -> void:
	var card_ids := [1001, 1002, 1003, 1004]
	for card_id in card_ids:
		var path: String = CardVisualRegistryScript.get_thumbnail_path(card_id)
		if path != "":
			_assert.that(ResourceLoader.exists(path), "%d thumbnail should exist at: %s" % [card_id, path])


func _test_card_view_thumbnail_loaded_via_bind() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var views = main.runtime.hand_panel._card_views
	_assert.that(views.size() >= 1, "should have at least 1 card view")

	var card_art = views[0].get_node("CardArt") as TextureRect
	_assert.that(card_art != null, "CardArt TextureRect should exist")

	if card_art.texture != null:
		_assert.that(card_art.visible, "CardArt should be visible when texture is loaded")
	else:
		var card_icon = views[0].get_node("CardIcon") as ColorRect
		_assert.that(card_icon.visible, "CardIcon fallback should be visible when no texture")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_card_view_bind_does_not_crash() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var hand_data = main.runtime.card_system.get_hand_card_data()
	_assert.that(hand_data.size() == 4, "should have 4 cards in hand")

	var views = main.runtime.hand_panel._card_views
	_assert.eq(views.size(), 4, "hand panel should have 4 card views")

	for view in views:
		var card_name = view.get_node("CardName") as Label
		_assert.neq(card_name.text, "???", "card should have a name bound (got: %s)" % card_name.text)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_card_view_fallback_on_missing_image() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var views = main.runtime.hand_panel._card_views
	_assert.that(views.size() >= 1, "should have at least 1 card view")

	var card_art = views[0].get_node("CardArt") as TextureRect
	_assert.that(card_art != null, "CardArt TextureRect should exist")

	var card_icon = views[0].get_node("CardIcon") as ColorRect
	_assert.that(card_icon != null, "CardIcon fallback should exist")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_no_card_ui() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.eq(main.runtime.hand_panel, null, "BallWar should have no hand panel")
	_assert.eq(main.runtime.top_resource_bar, null, "BallWar should have no resource bar")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
