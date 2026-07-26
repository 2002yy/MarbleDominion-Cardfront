extends SceneTree

const AiPolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

class MockTurret:
	extends Node
	var is_destroyed: bool = false
	var health: int = 30
	var max_health: int = 30

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontRoundCombatTest] Starting round combat tests")
	await process_frame

	_test_ai_policy_prefers_immediate_power()
	_test_ai_policy_has_no_seven_shot_multiplier_cliff()
	_test_engineer_values_finite_repair_capacity()
	_test_attack_level_changes_real_turret_damage()
	_test_command_chamber_is_primary_victory()
	_test_timeout_uses_health_then_territory()

	_assert.report("[CardfrontRoundCombatTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_ai_policy_prefers_immediate_power() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.AI_FACTION)
	var offer: Array = [
		UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5),
		UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1),
		UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1),
	]
	var choice: Dictionary = AiPolicyScript.new().choose(offer, state)
	_assert.eq(str(choice.get("id", "")), UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1, "AI: should prioritize permanent attack growth in this offer")


func _test_ai_policy_has_no_seven_shot_multiplier_cliff() -> void:
	var policy = AiPolicyScript.new()
	var offer_ids: Array = [
		UpgradeManifestScript.UPGRADE_VOLLEY_X2,
		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING,
	]
	for hero_id in ["balanced_commander", "rapid_gunner"]:
		var state = RunStateScript.new()
		state.setup_from_hero(RulesScript.AI_FACTION, hero_id)
		_assert.eq(
			policy.choose_id(offer_ids, state),
			UpgradeManifestScript.UPGRADE_VOLLEY_X2,
			"AI: immediate multiplier choice should not flip only because base volley changes from six to seven"
		)


func _test_engineer_values_finite_repair_capacity() -> void:
	var state = RunStateScript.new()
	state.setup_from_hero(RulesScript.AI_FACTION, "fortification_engineer")
	var choice_id: String = AiPolicyScript.new().choose_id([
		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR,
		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING,
		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1,
	], state)
	_assert.eq(
		choice_id,
		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR,
		"AI: the engineer should convert its higher defense capacity into finite route repair value"
	)


func _test_attack_level_changes_real_turret_damage() -> void:
	var target = Turret.new()
	target.faction_id = RulesScript.AI_FACTION
	target.health = 30
	target.max_health = 30
	target.global_position = Vector2(100.0, 100.0)
	get_root().add_child(target)

	var bullet = Bullet.new()
	get_root().add_child(bullet)
	bullet.setup(
		RulesScript.PLAYER_FACTION,
		target.global_position,
		Vector2.UP,
		null,
		{RulesScript.AI_FACTION: target},
		1,
		5
	)
	for _index in range(4):
		_assert.that(bullet._try_hit_enemy_turret(), "damage: attack-level bullet should hit enemy turret")
	_assert.eq(target.health, 25, "damage: four level-one hits should deal five chamber health")
	TestFixtures.cleanup_node(bullet)
	TestFixtures.cleanup_node(target)


func _test_command_chamber_is_primary_victory() -> void:
	var player = MockTurret.new()
	var ai = MockTurret.new()
	get_root().add_child(player)
	get_root().add_child(ai)
	var turrets: Dictionary = {
		RulesScript.PLAYER_FACTION: player,
		RulesScript.AI_FACTION: ai,
	}
	var dominant_counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 1500,
		RulesScript.AI_FACTION: 50,
		RulesScript.NEUTRAL_OWNER: 50,
	}
	var ongoing: Dictionary = WinConditionEvaluator.evaluate_cardfront(dominant_counts, 1600, false, turrets)
	_assert.that(not bool(ongoing.get("ended", true)), "victory: territory dominance alone should no longer end the match")

	ai.is_destroyed = true
	ai.health = 0
	var destroyed: Dictionary = WinConditionEvaluator.evaluate_cardfront(dominant_counts, 1600, false, turrets)
	_assert.that(bool(destroyed.get("ended", false)), "victory: destroyed command chamber should end immediately")
	_assert.eq(int(destroyed.get("winner", -1)), RulesScript.PLAYER_FACTION, "victory: surviving player chamber should win")
	_assert.eq(str(destroyed.get("reason", "")), "command_chamber", "victory: result reason should identify chamber destruction")
	TestFixtures.cleanup_node(player)
	TestFixtures.cleanup_node(ai)


func _test_timeout_uses_health_then_territory() -> void:
	var player = MockTurret.new()
	var ai = MockTurret.new()
	get_root().add_child(player)
	get_root().add_child(ai)
	player.health = 18
	ai.health = 12
	var turrets: Dictionary = {
		RulesScript.PLAYER_FACTION: player,
		RulesScript.AI_FACTION: ai,
	}
	var ai_territory_lead: Dictionary = {
		RulesScript.PLAYER_FACTION: 400,
		RulesScript.AI_FACTION: 800,
		RulesScript.NEUTRAL_OWNER: 400,
	}
	var health_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(ai_territory_lead, 1600, true, turrets)
	_assert.eq(int(health_result.get("winner", -1)), RulesScript.PLAYER_FACTION, "timeout: chamber health should outrank territory")

	ai.health = player.health
	var territory_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(ai_territory_lead, 1600, true, turrets)
	_assert.eq(int(territory_result.get("winner", -1)), RulesScript.AI_FACTION, "timeout: tied chamber health should use territory")
	TestFixtures.cleanup_node(player)
	TestFixtures.cleanup_node(ai)
