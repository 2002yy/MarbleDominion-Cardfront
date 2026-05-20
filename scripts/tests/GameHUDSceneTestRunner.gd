extends SceneTree

const TestAssert = preload("res://scripts/tests/TestAssert.gd")

class MockController extends RefCounted:
	var toggle_pause_called: int = 0
	var save_exit_called: int = 0
	var toggle_settings_called: int = 0
	var pause_state: bool = false

	func _toggle_pause() -> void:
		toggle_pause_called += 1
		pause_state = not pause_state

	func _save_and_exit_to_menu() -> void:
		save_exit_called += 1

	func _toggle_settings_panel() -> void:
		toggle_settings_called += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t: TestAssert = TestAssert.new()
	print("[GameHUDSceneTest] v2.1.7 — scene load + button signal tests")

	var scene_path: String = "res://scenes/ui/GameHUD.tscn"
	var resource = load(scene_path)
	t.that(resource != null, "scene loadable")
	if resource == null:
		t.report("[GameHUDSceneTest]")
		quit(1)
		return

	var instance = resource.instantiate()
	t.that(instance != null, "instantiable")
	t.that(instance is CanvasLayer, "root is CanvasLayer")
	if instance == null:
		t.report("[GameHUDSceneTest]")
		quit(1)
		return

	get_root().add_child(instance)
	await process_frame

	t.that(instance.has_method("get_static_parts"), "has get_static_parts")
	t.that(instance.has_method("setup_static"), "has setup_static")
	var layout: Dictionary = LayoutProfiles.get_profile(40).duplicate(true)
	layout.merge(LayoutCoordinator.calculate_layout(40, Vector2(1120, 720), false), true)

	var mock := MockController.new()
	instance.setup_static(mock, Vector2(1120, 720), layout, false)
	await process_frame

	var parts: Dictionary = instance.get_static_parts()
	t.that(parts.has("top_bar_segments"), "part: top_bar_segments")
	t.that(parts.has("leader_label"), "part: leader_label")
	t.that(parts.has("timer_label"), "part: timer_label")
	t.that(parts.has("stage_label"), "part: stage_label")
	t.that(parts.has("game_title_label"), "part: game_title_label")
	t.that(parts.has("fps_label"), "part: fps_label")
	t.that(parts.has("event_label"), "part: event_label")
	t.that(parts.has("settings_button"), "part: settings_button")
	t.that(parts.has("pause_button"), "part: pause_button")
	t.that(parts.has("exit_button"), "part: exit_button")
	t.that(parts.has("settings_panel"), "part: settings_panel")
	t.that(parts["settings_panel"] != null, "settings_panel not null")
	t.that(parts["settings_panel"] is Control, "settings_panel is Control")
	t.that(parts.has("pause_overlay"), "part: pause_overlay")
	t.that(parts.has("winner_label"), "part: winner_label")

	t.that(parts["fps_label"] is Label, "fps_label is Label")
	t.that(parts["event_label"] is Label, "event_label is Label")
	t.that(parts["settings_button"] is Button, "settings_button is Button")
	t.that(parts["pause_button"] is Button, "pause_button is Button")
	t.that(parts["exit_button"] is Button, "exit_button is Button")
	t.that(parts["fps_label"].visible, "fps_label visible after setup_static")
	t.that((parts["top_bar_segments"] as Dictionary).size() == 4, "top bar has 4 segments")
	t.that(instance.get_node("TopPanel").position == layout["hud_positions"]["top_panel_rect"].position, "top panel uses merged layout")

	_test_button_click(parts, mock, t)

	t.report("[GameHUDSceneTest]")

	if t.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_button_click(parts: Dictionary, mock: MockController, t: TestAssert) -> void:
	var pause_btn: Button = parts["pause_button"] as Button
	var exit_btn: Button = parts["exit_button"] as Button
	var settings_btn: Button = parts["settings_button"] as Button

	pause_btn.pressed.emit()
	t.eq(mock.toggle_pause_called, 1, "pause button pressed → _toggle_pause called once")

	pause_btn.pressed.emit()
	t.eq(mock.toggle_pause_called, 2, "pause button pressed again → _toggle_pause called twice")

	exit_btn.pressed.emit()
	t.eq(mock.save_exit_called, 1, "exit button pressed → _save_and_exit_to_menu called once")

	settings_btn.pressed.emit()
	t.eq(mock.toggle_settings_called, 1, "settings button pressed → _toggle_settings_panel called once")
