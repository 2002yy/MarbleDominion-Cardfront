extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ContributorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureContributor.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureContributorTest] Checking contributor DTO")
	await process_frame

	_test_complete_snapshot()
	_test_ineligible_and_zero_weight_contribute_nothing()
	_test_negative_weight_is_sanitized()
	_test_dto_has_no_scene_or_combat_inference_fields()

	_assert.report("[CardfrontSupportCaptureContributorTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_complete_snapshot() -> void:
	var contributor = ContributorScript.new()
	contributor.setup("creature_17", RulesScript.PLAYER_FACTION, "light_control", 2.0, Vector2i(7, 30), true)
	var snapshot: Dictionary = contributor.snapshot()
	_assert.eq(snapshot.keys().size(), 6, "capture contributor: exact DTO field count")
	_assert.eq(str(snapshot.entity_id), "creature_17", "capture contributor: entity id")
	_assert.eq(int(snapshot.owner_id), RulesScript.PLAYER_FACTION, "capture contributor: owner")
	_assert.eq(str(snapshot.capture_profile), "light_control", "capture contributor: profile")
	_assert.eq(float(snapshot.capture_weight), 2.0, "capture contributor: centralized weight")
	_assert.eq(snapshot.cell, Vector2i(7, 30), "capture contributor: cell")
	_assert.that(bool(snapshot.eligible), "capture contributor: explicit eligibility")


func _test_ineligible_and_zero_weight_contribute_nothing() -> void:
	var ineligible = ContributorScript.new()
	ineligible.setup("neutral", RulesScript.NEUTRAL_OWNER, "none", 2.0, Vector2i.ZERO, false)
	_assert.eq(ineligible.effective_weight(), 0.0, "capture contributor: ineligible entity contributes zero")
	var zero_weight = ContributorScript.new()
	zero_weight.setup("blocked", RulesScript.PLAYER_FACTION, "non_control", 0.0, Vector2i.ZERO, true)
	_assert.eq(zero_weight.effective_weight(), 0.0, "capture contributor: zero profile weight contributes zero")


func _test_negative_weight_is_sanitized() -> void:
	var contributor = ContributorScript.new()
	contributor.setup("bad_weight", RulesScript.PLAYER_FACTION, "invalid", -5.0, Vector2i.ZERO, true)
	_assert.eq(contributor.capture_weight, 0.0, "capture contributor: negative weight clamps to zero")


func _test_dto_has_no_scene_or_combat_inference_fields() -> void:
	var snapshot: Dictionary = ContributorScript.new().snapshot()
	for forbidden_key in ["node", "scene_tree", "armor_type", "movement", "size_slots", "damage", "dps", "rarity"]:
		_assert.that(not snapshot.has(forbidden_key), "capture contributor: excludes %s" % forbidden_key)
