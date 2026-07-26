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
	_test_echo_repeats_on_the_following_round()
	_test_multiplier_does_not_stack_and_volley_is_capped()
	_test_unknown_upgrade_fails_without_mutation()

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


func _test_multiplier_does_not_stack_and_volley_is_capped() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.state.base_volley_count = 20
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


func _make_fixture() -> Dictionary:
	var state = RunStateScript.new()
	state.setup(0, 10)
	return {
		"state": state,
		"upgrades": UpgradeResolverScript.new(),
		"volleys": VolleyResolverScript.new(),
	}
