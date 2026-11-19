extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportAuthorityScript = preload("res://scripts/cardfront/support/CardfrontSupportDeploymentAuthority.gd")
const ResolverScript = preload("res://scripts/cardfront/deployment/DeploymentPlacementResolver.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")

const SUPPORT_CELL := Vector2i(7, 31)
const SUPPORT_PROFILE := "directional_rear_rect_v1"

var _assert: TestAssert
var _battlefield: Battlefield
var _authority


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await _setup_fixture()
	_test_authority_revision_invalidates_stale_placement()
	_assert.report("[CardfrontDeploymentAuthorityRefreshTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	InitializerScript.configure_duel(_battlefield)
	_battlefield.owners[SUPPORT_CELL.x][SUPPORT_CELL.y] = Rules.PLAYER_FACTION
	_authority = SupportAuthorityScript.new()
	_assert.that(_authority.setup(DefaultMapScript.make(Vector2i(40, 40))), "authority: live topology should configure")


func _test_authority_revision_invalidates_stale_placement() -> void:
	_assert.that(_authority.set_support_state(Ids.SUPPORT_LEFT_SOUTH, Rules.PLAYER_FACTION, true), "authority: activating Support should change connectivity")
	var online_context: Dictionary = _authority.deployment_context(Rules.PLAYER_FACTION)
	var previous_revision: int = _authority.deployment_revision(Rules.PLAYER_FACTION)
	_assert.that(bool(_resolve_current().get("allowed", false)), "authority: online Support permits placement")

	_assert.that(_authority.set_operational(Ids.SUPPORT_LEFT_SOUTH, false), "authority: offline transition should invalidate the cache")
	_assert.gt(_authority.deployment_revision(Rules.PLAYER_FACTION), previous_revision, "authority: revision advances when Support goes offline")
	_assert.that(Ids.SUPPORT_LEFT_SOUTH in (online_context.get("online_support_ids", []) as Array), "authority: earlier preview context was legal")
	var denied: Dictionary = _resolve_current()
	_assert.that(not bool(denied.get("allowed", false)), "authority: current placement rejects stale online preview")
	_assert.eq(str(denied.get("reason", "")), DeploymentRulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "authority: placement resolver reports no legal deployment source")
	var query = QueryScript.new()
	query.owner_id = Rules.PLAYER_FACTION
	query.cell = SUPPORT_CELL
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = Ids.SUPPORT_LEFT_SOUTH
	query.spawn_profile_id = SUPPORT_PROFILE
	query.support_network_context = _authority.deployment_context(Rules.PLAYER_FACTION)
	_assert.eq(DeploymentRulesScript.evaluate(null, _battlefield, query).reason, DeploymentRulesScript.REASON_SUPPORT_OFFLINE, "authority: underlying rules identify the offline Support")


func _resolve_current() -> Dictionary:
	var only_target := func(candidate: Vector2i) -> bool:
		return candidate == SUPPORT_CELL
	return ResolverScript.resolve(
		null,
		_battlefield,
		Rules.PLAYER_FACTION,
		_authority.deployment_context(Rules.PLAYER_FACTION),
		{
			"preferred_support_id": Ids.SUPPORT_LEFT_SOUTH,
			"deployment_profile_id": SUPPORT_PROFILE,
		},
		only_target
	)
