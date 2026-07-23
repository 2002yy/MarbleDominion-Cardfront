extends SceneTree

const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const MatchPhaseControllerScript = preload("res://scripts/cardfront/run/CardfrontMatchPhaseController.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontMatchPhaseControllerTest] Starting v0.3 match phase tests")
	await process_frame

	_test_countdown_opens_paused_draft()
	_test_choices_are_required_before_resolve()
	_test_timeout_can_fill_missing_choice()
	_test_resolve_launch_and_restart_order()

	_assert.report("[CardfrontMatchPhaseControllerTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_countdown_opens_paused_draft() -> void:
	var controller = _make_controller()
	_assert.eq(controller.phase, MatchPhaseScript.BATTLE_COUNTDOWN, "phase: setup should start battle countdown")
	_assert.eq(controller.tick(0.5), MatchPhaseScript.BATTLE_COUNTDOWN, "phase: partial countdown should remain in battle")
	_assert.eq(controller.tick(0.5), MatchPhaseScript.DRAFT_PAUSED, "phase: countdown expiry should open paused draft")
	_assert.eq(controller.time_remaining, 2.0, "phase: draft should receive its own timeout")


func _test_choices_are_required_before_resolve() -> void:
	var controller = _make_controller()
	controller.tick(1.0)

	_assert.that(not controller.begin_launch(), "phase: launch cannot skip draft and resolve")
	_assert.that(controller.select_upgrade(0, "volley_plus_5"), "phase: first owner should select once")
	_assert.that(not controller.select_upgrade(0, "volley_x2"), "phase: owner cannot overwrite a locked choice")
	_assert.that(not controller.begin_resolve(), "phase: one missing owner should block resolve")
	_assert.eq(controller.get_missing_owner_ids(), [1], "phase: missing-owner list should identify AI")


func _test_timeout_can_fill_missing_choice() -> void:
	var controller = _make_controller()
	controller.tick(1.0)
	controller.select_upgrade(0, "volley_plus_5")
	controller.tick(2.0)
	_assert.that(controller.draft_timed_out, "phase: draft should mark timeout while the world is paused")
	_assert.eq(controller.phase, MatchPhaseScript.DRAFT_PAUSED, "phase: timeout should wait for fallback selection")

	var state = RunStateScript.new()
	state.setup(1)
	var draft = DraftSystemScript.new()
	draft.set_seed(91)
	var offer: Array = draft.draw_three(state)
	var fallback: Dictionary = draft.choose_timeout_fallback(offer)
	var fallback_id: String = str(fallback.get("id", ""))

	_assert.that(controller.select_upgrade(1, fallback_id), "phase: timeout fallback should fill the missing AI choice")
	_assert.that(_offer_ids(offer).has(controller.get_selected_upgrade_id(1)), "phase: fallback choice should belong to the AI offer")
	_assert.that(controller.has_all_choices(), "phase: timeout fallback should complete the draft")


func _test_resolve_launch_and_restart_order() -> void:
	var controller = _make_controller()
	controller.tick(1.0)
	controller.select_upgrade(0, "volley_plus_5")
	controller.select_upgrade(1, "volley_x2")

	_assert.that(controller.begin_resolve(), "phase: complete choices should enter resolve")
	_assert.eq(controller.phase, MatchPhaseScript.RESOLVE_CHOICES, "phase: resolve state")
	_assert.that(controller.begin_launch(), "phase: resolve should advance to launch")
	_assert.eq(controller.phase, MatchPhaseScript.LAUNCH_VOLLEY, "phase: launch state")
	_assert.that(controller.complete_launch(), "phase: completed launch should start next cycle")
	_assert.eq(controller.phase, MatchPhaseScript.BATTLE_COUNTDOWN, "phase: next cycle should return to battle countdown")
	_assert.eq(controller.selected_upgrade_ids, {}, "phase: next cycle should clear prior choices")


func _make_controller():
	var controller = MatchPhaseControllerScript.new()
	controller.setup([0, 1], 1.0, 2.0)
	return controller


func _offer_ids(offer: Array) -> Array:
	var result: Array = []
	for raw_definition in offer:
		if raw_definition is Dictionary:
			result.append(str((raw_definition as Dictionary).get("id", "")))
	return result
