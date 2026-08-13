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
	print("[CardfrontUpgradeResolverTest] Starting v0.3 upgrade resolution tests")
	await process_frame

	_test_plus_five_is_one_volley_only()
	_test_x2_is_one_volley_only()
	_test_permanent_growth_survives_volley()
	_test_selected_level_and_application_count_are_distinct()
	_test_echo_repeats_on_the_following_round()
	_test_multiplier_does_not_stack_and_volley_is_capped()
	_test_unknown_upgrade_fails_without_mutation()
	_test_failed_selection_does_not_consume_queued_echo()

	_assert.report("[CardfrontUpgradeResolverTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_plus_five_is_one_volley_only() -> void:
	var fixture: Dictionary = _make_fixture()
	var result: Dictionary = fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var first_plan = fixture.volleys.build_and_consume(fixture.state)
	var second_plan = fixture.volleys.build_and_consume(fixture.state)

	_assert.that(bool(result.get("success", false)), "upgrade: +5 should resolve")
	_assert.eq(first_plan.shot_count, 15, "volley: +5 should affect the next volley")
	_assert.eq(second_plan.shot_count, 10, "volley: +5 should be consumed after one volley")


func _test_x2_is_one_volley_only() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_VOLLEY_X2)
	var first_plan = fixture.volleys.build_and_consume(fixture.state)
	var second_plan = fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(first_plan.shot_count, 20, "volley: x2 should double the next volley")
	_assert.eq(second_plan.shot_count, 10, "volley: x2 should be consumed after one volley")


func _test_permanent_growth_survives_volley() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1)
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1)
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_RARITY_PLUS_1)
	var plan = fixture.volleys.build_and_consume(fixture.state)
	fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(plan.attack_level, 1, "growth: attack level should enter the volley plan")
	_assert.eq(plan.chamber_damage_quarters, 5, "growth: attack level one should deal 125 percent chamber damage")
	_assert.eq(plan.territory_defense_cap, 2, "growth: defense cap should enter the volley plan")
	_assert.eq(fixture.state.attack_level, 1, "growth: attack level should persist")
	_assert.eq(fixture.state.territory_defense_cap, 2, "growth: defense cap should persist")
	_assert.eq(fixture.state.rarity_level, 1, "growth: rarity level should persist")


func _test_selected_level_and_application_count_are_distinct() -> void:
	var fixture: Dictionary = _make_fixture()
	var upgrade_id: String = UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1
	_assert.eq(fixture.state.get_selected_upgrade_level(upgrade_id), 0, "level authority: unselected upgrade starts at zero")
	_assert.eq(fixture.state.get_effect_application_count(upgrade_id), 0, "application history: unapplied effect starts at zero")
	fixture.upgrades.resolve(fixture.state, upgrade_id)
	fixture.upgrades.resolve(fixture.state, upgrade_id)
	_assert.eq(fixture.state.get_selected_upgrade_level(upgrade_id), 2, "level authority: two successful selections produce Level 2")
	_assert.eq(fixture.state.get_effect_application_count(upgrade_id), 2, "application history: two direct applications are recorded")
	fixture.state.record_effect_application(upgrade_id)
	_assert.eq(fixture.state.get_selected_upgrade_level(upgrade_id), 2, "level authority: non-selection application cannot increase Level")
	_assert.eq(fixture.state.get_effect_application_count(upgrade_id), 3, "application history: compatibility count includes non-selection application")


func _test_echo_repeats_on_the_following_round() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE)
	var queued_result: Dictionary = fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var current_plan = fixture.volleys.build_and_consume(fixture.state)
	var repeated_result: Dictionary = fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1)
	var next_plan = fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(current_plan.shot_count, 15, "echo: copied choice should apply only once in its current round")
	_assert.eq(str(queued_result.get("echo_queued_upgrade_id", "")), UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, "echo: next choice should be queued")
	_assert.eq(str(repeated_result.get("echo_repeated_upgrade_id", "")), UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, "echo: queued choice should replay next round")
	_assert.eq(next_plan.shot_count, 15, "echo: replayed +5 should affect the following volley")
	_assert.eq(fixture.state.attack_level, 1, "echo: current round choice should still apply exactly once")
	_assert.eq(fixture.state.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE), 1, "echo: selecting Echo itself gives Echo Level 1")
	_assert.eq(fixture.state.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5), 1, "echo: replay must not increase copied upgrade Level")
	_assert.eq(fixture.state.get_effect_application_count(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5), 2, "echo: copied effect application history includes selection and replay")
	_assert.eq(fixture.state.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1), 1, "echo: the following real selection gains one Level")


func _test_multiplier_does_not_stack_and_volley_is_capped() -> void:
	var fixture: Dictionary = _make_fixture()
	# setup() is the authoritative typed-projectile fixture builder; assigning only
	# base_volley_count would leave base_projectile_mix at the old ten-shot group.
	fixture.state.setup(0, 20)
	fixture.state.multiply_next_volley(2)
	fixture.state.multiply_next_volley(2)
	var plan = fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(plan.applied_multiplier, 2, "volley: same-round multipliers should not stack")
	_assert.eq(plan.shot_count, VolleyResolverScript.NORMAL_MAX_VOLLEY_COUNT, "volley: normal card output should stop at 24")


func _test_unknown_upgrade_fails_without_mutation() -> void:
	var fixture: Dictionary = _make_fixture()
	var before: Dictionary = fixture.state.snapshot()
	var result: Dictionary = fixture.upgrades.resolve(fixture.state, "missing_upgrade")

	_assert.that(not bool(result.get("success", true)), "upgrade: unknown id should fail")
	_assert.eq(fixture.state.snapshot(), before, "upgrade: failed resolution should not mutate state")
	_assert.eq(fixture.state.get_selected_upgrade_level("missing_upgrade"), 0, "level authority: failed resolution cannot increase Level")


func _test_failed_selection_does_not_consume_queued_echo() -> void:
	var fixture: Dictionary = _make_fixture()
	var queued_id: String = UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5
	fixture.state.queue_echo_upgrade(queued_id)
	var before_counts: Dictionary = fixture.state.applied_upgrade_counts.duplicate(true)
	var result: Dictionary = fixture.upgrades.resolve(fixture.state, "missing_upgrade")

	_assert.that(not bool(result.get("success", true)), "failure order: unknown selection fails")
	_assert.eq(fixture.state.queued_echo_upgrade_id, queued_id, "failure order: invalid selection cannot consume queued Echo")
	_assert.eq(fixture.state.applied_upgrade_counts, before_counts, "failure order: invalid selection cannot record any application")
	_assert.eq(fixture.state.get_selected_upgrade_level("missing_upgrade"), 0, "failure order: invalid selection cannot gain Level")
	_assert.eq(fixture.state.get_selected_upgrade_level(queued_id), 0, "failure order: unexecuted queued Echo cannot gain Level")


func _make_fixture() -> Dictionary:
	var state = RunStateScript.new()
	state.setup(0, 10)
	return {
		"state": state,
		"upgrades": UpgradeResolverScript.new(),
		"volleys": VolleyResolverScript.new(),
	}
