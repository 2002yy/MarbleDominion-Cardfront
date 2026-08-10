extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const ResolverScript = preload("res://scripts/cardfront/deployment/DeploymentPlacementResolver.gd")
const FrontlineRuleScript = preload("res://scripts/cardfront/targets/target_rules/FrontlineDeploymentTargetRule.gd")
const PreviewLayerScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const AiPlannerScript = preload("res://scripts/cardfront/ai/CardfrontAiDeploymentPlanner.gd")
const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")

const CORE_CELL := Vector2i(0, 32)
const SUPPORT_CELL := Vector2i(7, 31)
const SUPPORT_PROFILE := "directional_rear_rect_v1"

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await _setup_fixture()
	print("[CardfrontDeploymentFourConsumerParityTest] Comparing Commit / Preview / AI / Auto on the same deployment facts")

	var core_context: Dictionary = ContextScript.core_only(
		_map_definition,
		Rules.PLAYER_FACTION,
		41
	)
	_assert_matrix(
		"Core legal",
		CORE_CELL,
		core_context,
		Ids.CORE_PLAYER,
		"",
		true
	)

	var online_context: Dictionary = ContextScript.with_online_supports(
		_map_definition,
		Rules.PLAYER_FACTION,
		[Ids.SUPPORT_LEFT_SOUTH],
		{Ids.SUPPORT_LEFT_SOUTH: 1},
		42
	)
	_assert_matrix(
		"Online support rear zone",
		SUPPORT_CELL,
		online_context,
		Ids.SUPPORT_LEFT_SOUTH,
		SUPPORT_PROFILE,
		true
	)

	var disconnected_context: Dictionary = ContextScript.core_only(
		_map_definition,
		Rules.PLAYER_FACTION,
		43
	)
	_assert_matrix(
		"Support disconnected",
		SUPPORT_CELL,
		disconnected_context,
		Ids.SUPPORT_LEFT_SOUTH,
		SUPPORT_PROFILE,
		false
	)

	# Deployment consumers intentionally receive only derived Online truth. A disabled
	# support and a disconnected support are different upstream Support states but both
	# must be absent from online_support_ids here.
	var disabled_context: Dictionary = ContextScript.core_only(
		_map_definition,
		Rules.PLAYER_FACTION,
		44
	)
	_assert_matrix(
		"Support disabled",
		SUPPORT_CELL,
		disabled_context,
		Ids.SUPPORT_LEFT_SOUTH,
		SUPPORT_PROFILE,
		false
	)

	_assert.report("[CardfrontDeploymentFourConsumerParityTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	InitializerScript.configure_duel(_battlefield)
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))
	# Keep target ownership constant so parity differences can only come from the
	# deployment-source context, not from territory ownership drift.
	_battlefield.owners[CORE_CELL.x][CORE_CELL.y] = Rules.PLAYER_FACTION
	_battlefield.owners[SUPPORT_CELL.x][SUPPORT_CELL.y] = Rules.PLAYER_FACTION


func _assert_matrix(
	label: String,
	cell: Vector2i,
	deployment_context: Dictionary,
	requested_support_id: String,
	profile_id: String,
	expected: bool
) -> void:
	var results: Dictionary = _consumer_results(
		cell,
		deployment_context,
		requested_support_id,
		profile_id
	)
	for consumer in ["commit", "preview", "ai", "auto_spawn"]:
		_assert.eq(
			bool(results.get(consumer, not expected)),
			expected,
			"four-consumer parity: %s -> %s" % [label, consumer]
		)
	_assert.eq(
		bool(results.commit),
		bool(results.preview),
		"four-consumer parity: %s Commit equals Preview" % label
	)
	_assert.eq(
		bool(results.commit),
		bool(results.ai),
		"four-consumer parity: %s Commit equals AI" % label
	)
	_assert.eq(
		bool(results.commit),
		bool(results.auto_spawn),
		"four-consumer parity: %s Commit equals Auto Spawn" % label
	)


func _consumer_results(
	cell: Vector2i,
	deployment_context: Dictionary,
	requested_support_id: String,
	profile_id: String
) -> Dictionary:
	var provider := func(_owner_id: int):
		return deployment_context.duplicate(true)

	var card = CardDataScript.new()
	card.id = 99104
	card.card_name = "Parity Frontline Deployment"
	card.target_type = CardTargetTypeScript.FRONTLINE_DEPLOYMENT
	card.params = {
		"requested_support_id": requested_support_id,
		"deployment_profile_id": profile_id,
	}
	var req = CardPlayRequestScript.make(
		card.id,
		Rules.PLAYER_FACTION,
		cell,
		-1
	)
	var commit_result = FrontlineRuleScript.new().validate(
		req,
		card,
		{
			"battlefield": _battlefield,
			"region_map": null,
			"deployment_context_provider": provider,
		}
	)

	var preview = PreviewLayerScript.new()
	get_root().add_child(preview)
	preview.battlefield = _battlefield
	preview.region_map = null
	preview.configure_deployment_authority(provider)
	preview.show_for_card(
		card.id,
		{
			"target_type": CardTargetTypeScript.FRONTLINE_DEPLOYMENT,
			"params": card.params.duplicate(true),
		}
	)
	var preview_allowed: bool = preview.is_valid_target(cell)
	TestFixtures.cleanup_node(preview)

	var ai = AiPlannerScript.new()
	ai.setup(null, _battlefield, provider)
	var ai_result = ai.evaluate_cell(
		Rules.PLAYER_FACTION,
		cell,
		requested_support_id,
		profile_id
	)

	# Automatic placement chooses among legal cells rather than validating one target.
	# Restrict availability to this exact cell so the matrix compares the same fact and
	# cannot silently pass by falling back to another Core/Support cell.
	var availability := func(candidate: Vector2i) -> bool:
		return candidate == cell
	var auto_result: Dictionary = ResolverScript.resolve(
		null,
		_battlefield,
		Rules.PLAYER_FACTION,
		deployment_context,
		{
			"preferred_support_id": requested_support_id,
			"deployment_profile_id": profile_id,
		},
		availability
	)

	return {
		"commit": bool(commit_result.success),
		"preview": preview_allowed,
		"ai": bool(ai_result.allowed),
		"auto_spawn": bool(auto_result.get("allowed", false)),
	}
