extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")

const DIRECTOR_SIGNALS: Array[String] = [
	"countdown_updated",
	"draft_opened",
	"draft_time_updated",
	"strongholds_sampled",
	"choice_locked",
	"choices_revealed",
	"volley_launched",
	"director_stopped",
]

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDraftLifecycleSnapshotTest] Starting P0-07A2 lifecycle snapshot")
	await process_frame

	await _test_choice_and_next_draft_lifecycle()
	await _test_repeated_toggle_and_resize_geometry()
	await _test_timeout_while_preview_lifecycle()
	await _test_director_stop_lifecycle()

	GameConfig.reset_runtime_defaults()
	paused = false
	_assert.report("[CardfrontDraftLifecycleSnapshotTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_choice_and_next_draft_lifecycle() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	_assert.that(not panel.draft_root.visible, "initial: DraftRoot starts hidden")
	for signal_name in DIRECTOR_SIGNALS:
		var connections: Array = director.get_signal_connection_list(signal_name)
		_assert.eq(_connection_count_for_object(connections, panel), 1, "initial: %s has one panel connection" % signal_name)
		print("[CardfrontDraftLifecycleSnapshotTest] signal=%s total=%d panel=%d" % [
			signal_name,
			connections.size(),
			_connection_count_for_object(connections, panel),
		])

	director.set_seed_for_tests(1702)
	director.force_open_draft_for_test()
	await process_frame
	var baseline_position: Vector2 = panel.choice_shell.position
	var baseline_peek_global_rect: Rect2 = panel._peek_button.get_global_rect()
	var first_offer_ids: Array = _card_ids(panel)
	_assert.eq(director.get_phase(), MatchPhaseScript.DRAFT_PAUSED, "draft_opened: phase is paused Draft")
	_assert.that(panel.draft_root.visible, "draft_opened: DraftRoot is visible")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_DRAFT_VISIBLE, "draft_opened: display mode starts in Draft")
	_assert.eq(panel._peek_button.text, "查看战场", "draft_opened: peek chrome starts in Draft mode")
	_assert.eq(first_offer_ids.size(), 3, "draft_opened: three cards are present")

	panel._toggle_peek()
	var preview_position: Vector2 = panel.choice_shell.position
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "peek click: display authority enters preview")
	_assert.eq(preview_position, baseline_position, "peek click: ChoiceShell geometry stays fixed")
	_assert.eq(panel._peek_button.get_global_rect(), baseline_peek_global_rect, "peek click: stable chrome does not move with ChoiceShell")
	_assert.that(panel.draft_root.visible, "peek click: DraftRoot remains visible")
	_assert.eq(panel.get_visible_choice_count(), 3, "peek click: current cards remain visible and clickable")
	_assert.eq(panel._peek_button.text, "返回选择", "peek click: button offers return")
	_assert.that(paused, "peek click: battle remains paused")
	_assert.that(not main.runtime.direction_controller.is_processing_unhandled_input(), "peek click: Aim input remains disabled")
	var space_event := InputEventKey.new()
	space_event.keycode = KEY_SPACE
	space_event.pressed = true
	Input.parse_input_event(space_event)
	await process_frame
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_DRAFT_VISIBLE, "Space: display authority returns to Draft mode")
	_assert.eq(panel.choice_shell.position, baseline_position, "Space: ChoiceShell geometry stays fixed")
	Input.parse_input_event(space_event)
	await process_frame
	preview_position = panel.choice_shell.position
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "Space: display authority can enter preview again")

	director._process(0.25)
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "timer update: preview mode is preserved")
	_assert.eq(panel.choice_shell.position, preview_position, "timer update: current preview position is preserved")
	_assert.eq(_card_ids(panel), first_offer_ids, "timer update: offer identity is unchanged")

	_assert.that(panel.choose_index_for_test(0), "choice_locked: current visible preview card can still lock")
	_assert.eq(director.get_phase(), MatchPhaseScript.RESOLVE_CHOICES, "choice_locked: normal resolution starts")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "choices_revealed: current implementation retains preview mode")
	_assert.eq(panel.choice_shell.position, preview_position, "choices_revealed: fixed shell geometry remains unchanged")
	_assert.that(panel.draft_root.visible, "choices_revealed: DraftRoot stays visible for result")
	_assert.eq(panel.title_label.text, "双方强化已确定", "choices_revealed: result title is rendered")

	director.complete_reveal_for_test()
	_assert.eq(director.get_phase(), MatchPhaseScript.BATTLE_COUNTDOWN, "volley_launched: next countdown starts")
	_assert.that(not panel.draft_root.visible, "volley_launched: DraftRoot hides")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "volley_launched: current implementation does not reset preview mode")
	_assert.eq(panel.choice_shell.position, preview_position, "volley_launched: shell geometry remains fixed")

	director.force_open_draft_for_test()
	await process_frame
	_assert.that(panel.draft_root.visible, "next draft_opened: DraftRoot becomes visible")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_DRAFT_VISIBLE, "next draft_opened: display mode resets")
	_assert.eq(panel._peek_button.text, "查看战场", "next draft_opened: button text resets")
	_assert.eq(panel.choice_shell.position, baseline_position, "next draft_opened: golden shell geometry is retained")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_timeout_while_preview_lifecycle() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	director.set_seed_for_tests(1707)
	director.force_open_draft_for_test()
	await process_frame
	var offered_ids: Array = _card_ids(panel)
	panel._toggle_peek()
	var preview_position: Vector2 = panel.choice_shell.position

	director._process(director.phase_controller.draft_timeout)
	var selected_id: String = director.phase_controller.get_selected_upgrade_id(RulesScript.PLAYER_FACTION)
	_assert.that(selected_id != "", "timeout preview: automatic player choice is made")
	_assert.that(offered_ids.has(selected_id), "timeout preview: fallback comes from the visible offer")
	_assert.eq(director.get_phase(), MatchPhaseScript.RESOLVE_CHOICES, "timeout preview: resolution still starts")
	_assert.that(panel.draft_root.visible, "timeout preview: result surface remains visible")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "timeout preview: current implementation retains preview mode during reveal")
	_assert.eq(panel.choice_shell.position, preview_position, "timeout preview: fixed shell geometry remains unchanged during reveal")
	_assert.eq(panel.title_label.text, "双方强化已确定", "timeout preview: both results are rendered")

	director.complete_reveal_for_test()
	_assert.eq(director.get_phase(), MatchPhaseScript.BATTLE_COUNTDOWN, "timeout preview: volley launches and countdown resumes")
	_assert.that(not paused, "timeout preview: world resumes after launch")
	_assert.that(not panel.draft_root.visible, "timeout preview: DraftRoot hides after launch")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_repeated_toggle_and_resize_geometry() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	director.force_open_draft_for_test()
	await process_frame
	var desktop_position: Vector2 = panel.choice_shell.position
	var desktop_size: Vector2 = panel.choice_shell.size
	var offer_ids: Array = _card_ids(panel)
	for index in range(20):
		panel._toggle_peek()
		_assert.eq(panel.choice_shell.position, desktop_position, "repeat toggle %d: desktop shell position stays fixed" % index)
		_assert.eq(panel.choice_shell.size, desktop_size, "repeat toggle %d: desktop shell size stays fixed" % index)
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_DRAFT_VISIBLE, "repeat toggle: even toggle count returns to Draft mode")
	_assert.eq(_card_ids(panel), offer_ids, "repeat toggle: offer IDs stay unchanged")

	_assert.that(panel.setup(director, Vector2(760.0, 540.0)), "resize: narrow setup succeeds")
	var narrow_position: Vector2 = panel.choice_shell.position
	var narrow_size: Vector2 = panel.choice_shell.size
	for index in range(20):
		panel._toggle_peek()
		_assert.eq(panel.choice_shell.position, narrow_position, "repeat narrow toggle %d: shell position stays fixed" % index)
		_assert.eq(panel.choice_shell.size, narrow_size, "repeat narrow toggle %d: shell size stays fixed" % index)
	_assert.eq(narrow_position, Vector2(-92.0, 116.0), "resize: narrow shell stays on A1 golden position")
	_assert.eq(narrow_size, Vector2(944.0, 488.0), "resize: narrow shell stays on A1 golden size")
	_assert.eq(_card_ids(panel), offer_ids, "resize: offer IDs stay unchanged")

	_assert.that(panel.setup(director, Vector2(1120.0, 720.0)), "resize: desktop restore setup succeeds")
	_assert.eq(panel.choice_shell.position, desktop_position, "resize: desktop shell returns to A1 golden position")
	_assert.eq(panel.choice_shell.size, desktop_size, "resize: desktop shell returns to A1 golden size")
	for signal_name in DIRECTOR_SIGNALS:
		_assert.eq(_connection_count_for_object(director.get_signal_connection_list(signal_name), panel), 1, "resize: %s retains one panel connection" % signal_name)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_director_stop_lifecycle() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	director.force_open_draft_for_test()
	await process_frame
	panel._toggle_peek()
	var preview_position: Vector2 = panel.choice_shell.position
	director.stop()
	_assert.that(not panel.draft_root.visible, "director_stopped: DraftRoot hides")
	_assert.that(not panel.battle_status.visible, "director_stopped: battle status hides")
	_assert.that(not panel.upgrade_toast.visible, "director_stopped: upgrade toast hides")
	_assert.eq(panel.get_display_mode_for_test(), panel.DISPLAY_MODE_BATTLEFIELD_PREVIEW, "director_stopped: current implementation does not reset preview mode")
	_assert.eq(panel.choice_shell.position, preview_position, "director_stopped: shell geometry remains fixed")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _card_ids(panel) -> Array:
	var ids: Array = []
	for card in panel.get_choice_cards():
		ids.append(str(card.upgrade_id))
	return ids


func _connection_count_for_object(connections: Array, target: Object) -> int:
	var count: int = 0
	for raw_connection in connections:
		var connection: Dictionary = raw_connection as Dictionary
		var callable: Callable = connection.get("callable", Callable()) as Callable
		if callable.is_valid() and callable.get_object() == target:
			count += 1
	return count


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
