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
	_test_mirror_doubles_next_choice_once()
	_test_mirror_can_create_x4_volley()
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
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_PROJECTILE_POWER_PLUS_1)
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1)
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_RARITY_PLUS_1)
	var plan = fixture.volleys.build_and_consume(fixture.state)
	fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(plan.projectile_power, 2, "growth: projectile power should enter the volley plan")
	_assert.eq(plan.territory_defense_cap, 2, "growth: defense cap should enter the volley plan")
	_assert.eq(fixture.state.projectile_power, 2, "growth: projectile power should persist")
	_assert.eq(fixture.state.territory_defense_cap, 2, "growth: defense cap should persist")
	_assert.eq(fixture.state.rarity_level, 1, "growth: rarity level should persist")


func _test_mirror_doubles_next_choice_once() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE)
	var copied_result: Dictionary = fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var copied_plan = fixture.volleys.build_and_consume(fixture.state)
	var normal_result: Dictionary = fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_PROJECTILE_POWER_PLUS_1)

	_assert.eq(int(copied_result.get("times_applied", 0)), 2, "mirror: next choice should resolve twice")
	_assert.eq(copied_plan.shot_count, 20, "mirror: duplicated +5 should add ten shots")
	_assert.that(not fixture.state.duplicate_next_choice, "mirror: token should be consumed")
	_assert.eq(int(normal_result.get("times_applied", 0)), 1, "mirror: following choice should return to one application")
	_assert.eq(fixture.state.projectile_power, 2, "mirror: following permanent upgrade should apply once")


func _test_mirror_can_create_x4_volley() -> void:
	var fixture: Dictionary = _make_fixture()
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE)
	fixture.upgrades.resolve(fixture.state, UpgradeManifestScript.UPGRADE_VOLLEY_X2)
	var plan = fixture.volleys.build_and_consume(fixture.state)

	_assert.eq(plan.applied_multiplier, 4, "mirror: duplicated x2 should resolve as x4")
	_assert.eq(plan.shot_count, 40, "mirror: x4 should apply to the base volley")


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
