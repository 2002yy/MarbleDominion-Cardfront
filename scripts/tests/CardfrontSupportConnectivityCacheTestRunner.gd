extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const TopologyScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const CacheScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityCache.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportConnectivityCacheTest] Checking revisioned invalidation")
	await process_frame

	_test_relevant_mutations_and_cache_hits()

	_assert.report("[CardfrontSupportConnectivityCacheTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_relevant_mutations_and_cache_hits() -> void:
	var topology: Dictionary = TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)
	var cache = CacheScript.new()
	cache.load_topology(topology)
	_assert.eq(cache.revision, 1, "connectivity cache: topology load invalidates once")
	_assert.that(cache.load_states({
		Ids.CORE_PLAYER: RulesScript.PLAYER_FACTION,
		Ids.SUPPORT_LEFT_SOUTH: RulesScript.AI_FACTION,
	}, {
		Ids.CORE_PLAYER: true,
		Ids.SUPPORT_LEFT_SOUTH: true,
	}), "connectivity cache: initial states load")
	_assert.eq(cache.revision, 2, "connectivity cache: logical state load invalidates once")

	var first: Dictionary = cache.resolve_for_side(RulesScript.PLAYER_FACTION)
	_assert.eq(first.connected_support_ids, [Ids.CORE_PLAYER], "connectivity cache: initial traversal")
	_assert.eq(cache.recompute_count, 1, "connectivity cache: first query recomputes")
	for _frame in 100:
		cache.resolve_for_side(RulesScript.PLAYER_FACTION)
	_assert.eq(cache.recompute_count, 1, "connectivity cache: 100 idle-frame queries do not recompute")
	for hover_index in 100:
		var _hovered_support_id: String = Ids.SUPPORT_LEFT_SOUTH if hover_index % 2 == 0 else Ids.CORE_PLAYER
		cache.resolve_for_side(RulesScript.PLAYER_FACTION)
	_assert.eq(cache.recompute_count, 1, "connectivity cache: 100 hover queries do not recompute")

	var revision_before_claim: int = cache.revision
	_assert.that(cache.set_claim_owner(Ids.SUPPORT_LEFT_SOUTH, RulesScript.PLAYER_FACTION), "connectivity cache: changed Claim invalidates")
	_assert.eq(cache.revision, revision_before_claim + 1, "connectivity cache: one Claim change is exactly one invalidation")
	_assert.that(not cache.set_claim_owner(Ids.SUPPORT_LEFT_SOUTH, RulesScript.PLAYER_FACTION), "connectivity cache: identical Claim is a no-op")
	_assert.eq(cache.revision, revision_before_claim + 1, "connectivity cache: identical Claim does not invalidate")
	var after_claim: Dictionary = cache.resolve_for_side(RulesScript.PLAYER_FACTION)
	_assert.that(Ids.SUPPORT_LEFT_SOUTH in after_claim.connected_support_ids, "connectivity cache: Claim mutation refreshes result")
	_assert.eq(cache.recompute_count, 2, "connectivity cache: first query after mutation recomputes once")
	_assert.eq(int(after_claim.revision), cache.revision, "connectivity cache: result exposes owning revision")

	var revision_before_operational: int = cache.revision
	_assert.that(cache.set_operational(Ids.SUPPORT_LEFT_SOUTH, false), "connectivity cache: operational change invalidates")
	_assert.eq(cache.revision, revision_before_operational + 1, "connectivity cache: one operational change is exactly one invalidation")
	_assert.eq(cache.resolve_for_side(RulesScript.PLAYER_FACTION).connected_support_ids, [Ids.CORE_PLAYER], "connectivity cache: disabled node disappears after recompute")
	_assert.eq(cache.recompute_count, 3, "connectivity cache: operational mutation recomputes once on demand")

	var revision_before_reload: int = cache.revision
	cache.load_topology(topology)
	_assert.eq(cache.revision, revision_before_reload + 1, "connectivity cache: topology_loaded explicitly invalidates")
	_assert.eq(cache.recompute_count, 3, "connectivity cache: invalidation is lazy until queried")
