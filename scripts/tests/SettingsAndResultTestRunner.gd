extends SceneTree

const TestAssert = preload("res://scripts/tests/TestAssert.gd")
const SettingsScene = preload("res://scenes/ui/SettingsPanel.tscn")
const ResultScene = preload("res://scenes/ui/ResultPanel.tscn")
const PlayerSettingsStore = preload("res://scripts/PlayerSettingsStore.gd")
const RuntimeHudController = preload("res://scripts/RuntimeHudController.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t: TestAssert = TestAssert.new()
	print("[SettingsAndResultTest] v2.1.9")
	await process_frame

	_cleanup_settings_file()
	await _test_settings_persistence(t)
	await _flush()
	await _test_performance_toggle(t)
	await _flush()
	await _test_result_panel(t)
	await _flush()

	t.report("[SettingsAndResultTest]")
	if t.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _cleanup_settings_file() -> void:
	var path := ProjectSettings.globalize_path("user://player_settings.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# === P1: Settings persistence ===
func _test_settings_persistence(t: TestAssert) -> void:
	print("  [P1] settings persistence")

	var prefs := PlayerSettingsStore.default_settings()
	prefs["show_performance_info"] = false
	prefs["low_effect_mode"] = true
	PlayerSettingsStore.save_settings(prefs)

	var loaded := PlayerSettingsStore.load_settings()
	t.eq(bool(loaded["show_performance_info"]), false, "persist: show_performance_info=false")
	t.eq(bool(loaded["low_effect_mode"]), true, "persist: low_effect_mode=true")

	var panel = SettingsScene.instantiate()
	get_root().add_child(panel)
	await process_frame

	var perf_cb: CheckButton = panel.get_node("PanelMargin/MainVBox/PerformanceCheck")
	t.that(not perf_cb.button_pressed, "panel loads show_perf=false")

	panel.queue_free()
	await process_frame


# === P2: Performance bar toggle ===
func _test_performance_toggle(t: TestAssert) -> void:
	print("  [P2] performance bar toggle")

	var prefs := PlayerSettingsStore.default_settings()
	prefs["show_performance_info"] = false
	PlayerSettingsStore.save_settings(prefs)

	var main_script = load("res://scripts/Main.gd")
	var main = main_script.new()
	get_root().add_child(main)
	main.player_settings = PlayerSettingsStore.load_settings()
	main._apply_performance_setting()

	t.that(not RuntimeHudController.performance_visible, "perf_visible=false after load")
	t.eq(RuntimeHudController.get_perf_debug_text(null, null, 10, {}), "", "perf_debug_text returns empty when hidden")

	prefs["show_performance_info"] = true
	PlayerSettingsStore.save_settings(prefs)
	main.player_settings = PlayerSettingsStore.load_settings()
	main._apply_performance_setting()

	t.that(RuntimeHudController.performance_visible, "perf_visible=true after toggle on")

	main.queue_free()
	await process_frame


# === P3: Result panel ===
func _test_result_panel(t: TestAssert) -> void:
	print("  [P3] result panel")

	var panel = ResultScene.instantiate()
	get_root().add_child(panel)
	await process_frame

	t.that(not panel.visible, "starts hidden")

	panel.show_result({
		"winner_name": "海方",
		"winner_color": Color(0.2, 0.49, 1.0),
		"reason_text": "击败全部对手",
		"duration_seconds": 222.0,
		"occupation_rates": {
			GameConfig.Faction.BLUE: 0.48,
			GameConfig.Faction.RED: 0.22,
			GameConfig.Faction.GREEN: 0.18,
			GameConfig.Faction.YELLOW: 0.12,
		},
		"peak_active_bullets": 126,
		"event_count": 8,
	})

	t.that(panel.visible, "visible after show_result")
	t.that(panel.title_label.text.containsn("海方"), "title contains winner name")
	t.that(panel.reason_label.text.containsn("击败全部对手"), "reason label correct")
	t.that(panel.duration_label.text.containsn("03:42"), "duration formatted 03:42")
	t.that(panel.occupation_label.text.containsn("48%"), "occupation shows 48%")
	t.that(panel.stats_label.text.containsn("126"), "stats shows peak bullets")
	t.that(panel.stats_label.text.containsn("8"), "stats shows event count")

	panel.queue_free()
	await process_frame


func _cleanup_save_slot(slot: int) -> void:
	for ext in ["", ".bak", ".tmp"]:
		var p := ProjectSettings.globalize_path("user://ballwar_save_slot_%d.save%s" % [slot, ext])
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
