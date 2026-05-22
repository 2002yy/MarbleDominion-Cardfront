extends SceneTree

const CardfrontHandPanelScene = preload("res://scenes/ui/cardfront/CardfrontHandPanel.tscn")
const CardfrontCardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")
const CardfrontTopResourceBarScene = preload("res://scenes/ui/cardfront/CardfrontTopResourceBar.tscn")
const CardfrontCardDetailPopupScene = preload("res://scenes/ui/cardfront/CardfrontCardDetailPopup.tscn")
const CardfrontToastLayerScene = preload("res://scenes/ui/cardfront/CardfrontToastLayer.tscn")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUiArtSceneTest] Starting UI art scene tests")
	await process_frame

	_test_scenes_instantiate()
	_test_art_fallback_style_available()
	_test_top_resource_bar_icon_nodes_exist()
	_test_cardfront_mode_creates_feedback_ui()
	_test_ballwar_mode_does_not_create_cardfront_ui()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontUiArtSceneTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_scenes_instantiate() -> void:
	var scenes: Array = [
		CardfrontHandPanelScene,
		CardfrontCardViewScene,
		CardfrontTopResourceBarScene,
		CardfrontCardDetailPopupScene,
		CardfrontToastLayerScene,
	]
	for scene in scenes:
		var node = scene.instantiate()
		get_root().add_child(node)
		_assert.that(node != null and is_instance_valid(node), "ui art scene: scene should instantiate")
		TestFixtures.cleanup_node(node)


func _test_art_fallback_style_available() -> void:
	var style = CardfrontUiAssetRegistryScript.make_panel_style("missing_asset_for_scene_test", Color(0.1, 0.1, 0.1), Color(0.5, 0.5, 0.5))
	_assert.that(style != null, "ui art scene: missing resources should keep fallback style")


func _test_top_resource_bar_icon_nodes_exist() -> void:
	var bar = CardfrontTopResourceBarScene.instantiate()
	get_root().add_child(bar)
	var energy_icon = bar.get_node_or_null("Margin/HBox/EnergyBox/Margin2/Inner/EnergyIcon")
	var parts_icon = bar.get_node_or_null("Margin/HBox/PartsBox/Margin2/Inner/PartsIcon")
	_assert.that(energy_icon is TextureRect, "top resource bar: EnergyIcon should be TextureRect")
	_assert.that(parts_icon is TextureRect, "top resource bar: PartsIcon should be TextureRect")
	_assert.that(energy_icon != null, "top resource bar: EnergyIcon node should exist")
	_assert.that(parts_icon != null, "top resource bar: PartsIcon node should exist")
	TestFixtures.cleanup_node(bar)


func _make_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(mode_name)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _test_cardfront_mode_creates_feedback_ui() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	_assert.that(main.runtime.hand_panel != null, "ui art scene: Cardfront should create hand panel")
	_assert.that(main.runtime.top_resource_bar != null, "ui art scene: Cardfront should create top resource bar")
	_assert.that(main.runtime.card_detail_popup != null, "ui art scene: Cardfront should create card detail popup")
	_assert.that(main.runtime.toast_layer != null, "ui art scene: Cardfront should create toast layer")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_mode_does_not_create_cardfront_ui() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.hand_panel, null, "ui art scene: BallWar should not create hand panel")
	_assert.eq(main.runtime.top_resource_bar, null, "ui art scene: BallWar should not create top resource bar")
	_assert.eq(main.runtime.card_detail_popup, null, "ui art scene: BallWar should not create card detail popup")
	_assert.eq(main.runtime.toast_layer, null, "ui art scene: BallWar should not create toast layer")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
