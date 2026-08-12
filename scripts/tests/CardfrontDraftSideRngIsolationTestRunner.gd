extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

const PLAYER_SEED: int = 80821
const AI_SEED: int = 80822

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDraftSideRngIsolationTest] Starting P0-08A2-A5 RNG isolation tests")
	await process_frame

	_test_master_seed_compatibility()
	_test_frozen_draw_semantics()
	_test_draw_order_invariance()
	_test_player_extra_draw_does_not_change_ai_trace()
	_test_player_fallback_does_not_change_ai_trace()
	_test_ai_consumption_does_not_change_player_trace()
	_test_same_side_draw_and_fallback_share_one_stream()

	_assert.report("[CardfrontDraftSideRngIsolationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_master_seed_compatibility() -> void:
	var first = DraftSystemScript.new()
	var second = DraftSystemScript.new()
	first.set_seed(20260812)
	second.set_seed(20260812)
	for owner_id in RulesScript.get_duel_factions():
		_assert.eq(
			first.draw_offer_ids(null, 3, int(owner_id)),
			second.draw_offer_ids(null, 3, int(owner_id)),
			"master seed: side %d remains deterministic" % int(owner_id)
		)


func _test_frozen_draw_semantics() -> void:
	var draft = DraftSystemScript.new()
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	_assert.eq(DeckRegistryScript.DEFAULT_DECK_ID, "core_tactics", "semantics: default deck remains core_tactics")
	_assert.eq(DeckRegistryScript.get_upgrade_ids(DeckRegistryScript.DEFAULT_DECK_ID), UpgradeManifestScript.get_upgrade_ids(), "semantics: formal deck IDs remain unchanged")
	_assert.eq(draft.DEFAULT_OFFER_SIZE, 3, "semantics: default offer size remains three")
	_assert.eq(draft.MAX_OFFER_SIZE, 3, "semantics: maximum formal offer remains three")
	_assert.eq(draft.COMMON_BASE_WEIGHT, 100.0, "semantics: common weight remains frozen")
	_assert.eq(draft.UNCOMMON_BASE_WEIGHT, 42.0, "semantics: uncommon weight remains frozen")
	_assert.eq(draft.RARE_BASE_WEIGHT, 12.0, "semantics: rare weight remains frozen")
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, PLAYER_SEED)
	var ids: Array = draft.draw_offer_ids(state, 4, RulesScript.PLAYER_FACTION)
	_assert.eq(ids.size(), 3, "semantics: oversized request remains capped to three")
	var unique: Dictionary = {}
	for upgrade_id in ids:
		unique[str(upgrade_id)] = true
	_assert.eq(unique.size(), 3, "semantics: one Offer still has unique IDs")
	_assert.eq(draft.choose_timeout_fallback([], RulesScript.PLAYER_FACTION), {}, "semantics: empty fallback remains safe")


func _test_draw_order_invariance() -> void:
	var player_first = _seeded_draft()
	var player_a: Array = player_first.draw_offer_ids(null, 3, RulesScript.PLAYER_FACTION)
	var ai_a: Array = player_first.draw_offer_ids(null, 3, RulesScript.AI_FACTION)
	var ai_first = _seeded_draft()
	var ai_b: Array = ai_first.draw_offer_ids(null, 3, RulesScript.AI_FACTION)
	var player_b: Array = ai_first.draw_offer_ids(null, 3, RulesScript.PLAYER_FACTION)
	_assert.eq(player_a, player_b, "draw order: Player offer is invariant")
	_assert.eq(ai_a, ai_b, "draw order: AI offer is invariant")


func _test_player_extra_draw_does_not_change_ai_trace() -> void:
	var baseline = _seeded_draft()
	var baseline_ai: Array = _trace(baseline, RulesScript.AI_FACTION, 5)
	var perturbed = _seeded_draft()
	perturbed.draw_offer_ids(null, 3, RulesScript.PLAYER_FACTION)
	var actual_ai: Array = _trace(perturbed, RulesScript.AI_FACTION, 5)
	_assert.eq(actual_ai, baseline_ai, "isolation: extra Player draw does not change AI trace")


func _test_player_fallback_does_not_change_ai_trace() -> void:
	var baseline = _seeded_draft()
	var baseline_ai: Array = _trace(baseline, RulesScript.AI_FACTION, 5)
	var perturbed = _seeded_draft()
	var player_offer: Array = perturbed.draw_offer(null, 3, RulesScript.PLAYER_FACTION)
	var fallback: Dictionary = perturbed.choose_timeout_fallback(player_offer, RulesScript.PLAYER_FACTION)
	_assert.that(_ids(player_offer).has(str(fallback.get("id", ""))), "isolation: Player fallback still comes from Player offer")
	var actual_ai: Array = _trace(perturbed, RulesScript.AI_FACTION, 5)
	_assert.eq(actual_ai, baseline_ai, "isolation: Player fallback consumption does not change AI trace")


func _test_ai_consumption_does_not_change_player_trace() -> void:
	var baseline = _seeded_draft()
	var baseline_player: Array = _trace(baseline, RulesScript.PLAYER_FACTION, 5)
	var perturbed = _seeded_draft()
	var ai_offer: Array = perturbed.draw_offer(null, 3, RulesScript.AI_FACTION)
	perturbed.choose_timeout_fallback(ai_offer, RulesScript.AI_FACTION)
	perturbed.draw_offer_ids(null, 3, RulesScript.AI_FACTION)
	var actual_player: Array = _trace(perturbed, RulesScript.PLAYER_FACTION, 5)
	_assert.eq(actual_player, baseline_player, "isolation: extra AI random consumption does not change Player trace")


func _test_same_side_draw_and_fallback_share_one_stream() -> void:
	var baseline = _seeded_draft()
	var offer: Array = baseline.draw_offer(null, 3, RulesScript.PLAYER_FACTION)
	var without_fallback: Array = baseline.draw_offer_ids(null, 3, RulesScript.PLAYER_FACTION)
	var consumed = _seeded_draft()
	var same_offer: Array = consumed.draw_offer(null, 3, RulesScript.PLAYER_FACTION)
	_assert.eq(_ids(same_offer), _ids(offer), "same-side stream: seeded first Offer matches")
	consumed.choose_timeout_fallback(same_offer, RulesScript.PLAYER_FACTION)
	var after_fallback: Array = consumed.draw_offer_ids(null, 3, RulesScript.PLAYER_FACTION)
	_assert.neq(after_fallback, without_fallback, "same-side stream: fallback advances the same side RNG")


func _seeded_draft():
	var draft = DraftSystemScript.new()
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, PLAYER_SEED)
	draft.set_side_seed_for_tests(RulesScript.AI_FACTION, AI_SEED)
	return draft


func _trace(draft, owner_id: int, count: int) -> Array:
	var result: Array = []
	for _index in range(count):
		result.append(draft.draw_offer_ids(null, 3, owner_id))
	return result


func _ids(offer: Array) -> Array:
	var result: Array = []
	for definition in offer:
		result.append(str((definition as Dictionary).get("id", "")))
	return result
