extends SceneTree

const CardfrontHUDScene = preload("res://scenes/ui/cardfront/CardfrontHUD.tscn")
const CardfrontMatchFlowTextScript = preload("res://scripts/cardfront/ui/CardfrontMatchFlowText.gd")

var _assert: TestAssert


class MockController extends Node:
	var restart_calls: int = 0
	var menu_calls: int = 0

	func _restart_current_cardfront_match() -> void:
		restart_calls += 1

	func _exit_cardfront_result_to_menu() -> void:
		menu_calls += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontMatchFlowClarityTest] Starting match-flow clarity tests")
	await process_frame
	_test_objective_and_countdown_text()
	await _test_result_panel_scene_and_actions()
	await _test_mode_boundary()
	GameConfig.reset_runtime_defaults()
	_assert.report("[CardfrontMatchFlowClarityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_objective_and_countdown_text() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var timer := Label.new()
	var stage := Label.new()
	var leader := Label.new()
	RuntimeHudController.update_meta(timer, stage, leader, {0: 320, 1: 320, -1: 960}, 65.0)
	_assert.eq(stage.text, "摧毁控制舱", "match flow: top HUD should state the command-chamber objective")
	_assert.eq(timer.text, "\u5269\u4f59 06:55", "match flow: top HUD should show remaining time instead of elapsed time")
	_assert.that(CardfrontMatchFlowTextScript.opening_hint_text().contains("\u4e09\u9009\u4e00"), "match flow: opening hint should explain the upgrade draft")
	_assert.that(CardfrontMatchFlowTextScript.opening_hint_text().contains("\u6467\u6bc1\u654c\u65b9\u63a7\u5236\u8231"), "match flow: opening hint should identify the primary objective")
	timer.free()
	stage.free()
	leader.free()


func _test_result_panel_scene_and_actions() -> void:
	var controller := MockController.new()
	get_root().add_child(controller)
	var hud = CardfrontHUDScene.instantiate()
	get_root().add_child(hud)
	await process_frame
	hud.setup_static(controller, Vector2(1120.0, 720.0))
	var panel = hud.match_result_panel
	_assert.that(panel != null, "match flow: Cardfront HUD should contain the formal result panel")
	_assert.that(not panel.visible, "match flow: result panel should start hidden")
	panel.show_result(
		"\u73a9\u5bb6\u80dc\u5229\uff01",
		CardfrontMatchFlowTextScript.result_reason(false),
		{0: 1120, 1: 320, -1: 160},
		1600,
		Color(0.25, 0.65, 1.0)
	)
	_assert.that(panel.visible, "match flow: result panel should become visible at match end")
	_assert.eq(panel._title_label.text, "\u73a9\u5bb6\u80dc\u5229\uff01", "match flow: result title should use Cardfront player naming")
	_assert.that(panel._score_label.text.contains("\u73a9\u5bb6 70%"), "match flow: result panel should show the player's final percentage")
	_assert.that(panel._score_label.text.contains("AI 20%"), "match flow: result panel should show the AI final percentage")
	panel._restart_button.pressed.emit()
	panel._menu_button.pressed.emit()
	_assert.eq(controller.restart_calls, 1, "match flow: restart button should route to the controller")
	_assert.eq(controller.menu_calls, 1, "match flow: menu button should route to the controller")
	hud.queue_free()
	controller.queue_free()
	await process_frame


func _test_mode_boundary() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var cardfront_main = load("res://scripts/Main.gd").new()
	get_root().add_child(cardfront_main)
	cardfront_main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	cardfront_main.selected_grid_size = 20
	cardfront_main._start_game(20, true, false)
	await process_frame
	var cardfront_result_panel = cardfront_main._hud_ref("match_result_panel")
	_assert.that(cardfront_result_panel != null, "match flow: Cardfront mode should create the result panel")
	cardfront_main.current_score_counts = {0: 280, 1: 80, -1: 40}
	cardfront_main._finish_with_winner(GameConfig.Faction.BLUE, "test")
	_assert.that(cardfront_result_panel.visible, "match flow: the real Main winner route should show the result panel")
	_assert.eq(cardfront_result_panel._title_label.text, "\u73a9\u5bb6\u80dc\u5229\uff01", "match flow: the real winner route should use Cardfront player naming")
	cardfront_main._cleanup_game_layer()
	TestFixtures.cleanup_node(cardfront_main)
	await process_frame

	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)
	var ballwar_main = load("res://scripts/Main.gd").new()
	get_root().add_child(ballwar_main)
	ballwar_main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	ballwar_main.selected_grid_size = 20
	ballwar_main._start_game(20, true, false)
	await process_frame
	_assert.that(ballwar_main._hud_ref("match_result_panel") == null, "match flow: BallWar mode should not create the Cardfront result panel")
	ballwar_main._cleanup_game_layer()
	TestFixtures.cleanup_node(ballwar_main)
	await process_frame
