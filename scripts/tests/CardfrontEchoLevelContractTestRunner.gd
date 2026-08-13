extends SceneTree

const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontEchoLevelContractTest] Starting P0-09A4 Echo contract")
	await process_frame
	_test_echo_replay_is_application_not_selection()
	_assert.report("[CardfrontEchoLevelContractTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_echo_replay_is_application_not_selection() -> void:
	var state = RunStateScript.new()
	state.setup(0, 10)
	var resolver = UpgradeResolverScript.new()
	var volleys = VolleyResolverScript.new()

	# Round N: selecting Echo arms the following real selection.
	var echo_result: Dictionary = resolver.resolve(state, UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE)
	_assert.that(bool(echo_result.get("success", false)), "round N: Echo selection resolves")
	_assert.that(state.echo_next_choice_armed, "round N: Echo arms the next selection")
	_assert.eq(state.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE), 1, "round N: Echo itself gains one Selected Level")
	_assert.eq(state.get_effect_application_count(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE), 1, "round N: Echo effect application is recorded once")

	# Round N+1: the real +5 selection applies once and is queued for replay.
	var copied_id: String = UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5
	var queued_result: Dictionary = resolver.resolve(state, copied_id)
	var current_plan = volleys.build_and_consume(state)
	_assert.eq(str(queued_result.get("echo_queued_upgrade_id", "")), copied_id, "round N+1: the real selection is queued for replay")
	_assert.eq(current_plan.shot_count, 15, "round N+1: the selected +5 effect applies once")
	_assert.eq(state.get_selected_upgrade_level(copied_id), 1, "round N+1: the real selection gives copied card Level 1")
	_assert.eq(state.get_effect_application_count(copied_id), 1, "round N+1: copied effect has one application")

	# Round N+2: queued +5 replays, while a different card is truly selected.
	var selected_id: String = UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1
	var replay_result: Dictionary = resolver.resolve(state, selected_id)
	var next_plan = volleys.build_and_consume(state)
	_assert.eq(str(replay_result.get("echo_repeated_upgrade_id", "")), copied_id, "round N+2: the queued +5 is the automatic replay")
	_assert.eq(next_plan.shot_count, 15, "round N+2: replayed +5 executes its effect")
	_assert.eq(next_plan.attack_level, 1, "round N+2: the different real selection also executes")
	_assert.eq(state.get_effect_application_count(copied_id), 2, "round N+2: copied effect history includes selection and replay")
	_assert.eq(state.get_selected_upgrade_level(copied_id), 1, "round N+2: automatic replay does not increase copied card Level")
	_assert.eq(state.get_effect_application_count(selected_id), 1, "round N+2: real selection effect application is recorded")
	_assert.eq(state.get_selected_upgrade_level(selected_id), 1, "round N+2: the different real selection gains one Level")
	_assert.eq(state.queued_echo_upgrade_id, "", "round N+2: replay queue is consumed")
