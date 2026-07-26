extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const MatchFlowTextScript = preload("res://scripts/cardfront/ui/CardfrontMatchFlowText.gd")

class MockTurret:
	extends Node
	var health: int = 40
	var max_health: int = 40
	var is_destroyed: bool = false

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontStrongholdTimeoutScoringTest] Starting v0.3.2c timeout scoring tests")
	await process_frame

	_test_weighted_score_uses_50_35_15()
	_test_strongholds_can_break_an_otherwise_equal_timeout()
	_test_exact_score_tie_draws()
	_test_chamber_destruction_still_ends_immediately()
	await _test_result_panel_shows_score_components()

	_assert.report("[CardfrontStrongholdTimeoutScoringTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_weighted_score_uses_50_35_15() -> void:
	var fixture: Dictionary = _make_turrets(20, 30)
	var counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 800,
		RulesScript.AI_FACTION: 600,
		RulesScript.NEUTRAL_OWNER: 200,
	}
	var strongholds: Dictionary = {
		RulesScript.PLAYER_FACTION: {"active_types": [RegionTypeScript.FACTORY, RegionTypeScript.LAB]},
		RulesScript.AI_FACTION: {"active_types": [RegionTypeScript.ENERGY]},
	}
	var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(
		counts,
		1600,
		true,
		fixture.turrets,
		strongholds
	)
	var breakdown: Dictionary = result.score_breakdown
	var player: Dictionary = breakdown.player
	var ai: Dictionary = breakdown.ai

	_assert.eq(int(result.winner), RulesScript.AI_FACTION, "timeout: weighted total should choose the higher composite score")
	_assert.between(float(player.chamber), 24.999, 25.001, "timeout: player chamber should contribute 25 of 50")
	_assert.between(float(player.territory), 17.499, 17.501, "timeout: player territory should contribute 17.5 of 35")
	_assert.between(float(player.strongholds), 9.999, 10.001, "timeout: two stronghold types should contribute 10 of 15")
	_assert.between(float(ai.total), 55.624, 55.626, "timeout: AI composite score should preserve fractional components")
	_assert.that(
		MatchFlowTextScript.score_summary(counts, 1600, breakdown).contains("舱"),
		"timeout UI: score summary should expose chamber, territory, and stronghold components"
	)
	_cleanup_fixture(fixture)


func _test_strongholds_can_break_an_otherwise_equal_timeout() -> void:
	var fixture: Dictionary = _make_turrets(30, 30)
	var counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 700,
		RulesScript.AI_FACTION: 700,
		RulesScript.NEUTRAL_OWNER: 200,
	}
	var strongholds: Dictionary = {
		RulesScript.PLAYER_FACTION: {
			"active_types": [RegionTypeScript.FACTORY, RegionTypeScript.ENERGY, RegionTypeScript.LAB],
		},
		RulesScript.AI_FACTION: {"active_types": []},
	}
	var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(counts, 1600, true, fixture.turrets, strongholds)

	_assert.eq(int(result.winner), RulesScript.PLAYER_FACTION, "timeout: controlled strongholds should matter for the final result")
	_assert.between(float(result.score_breakdown.player.strongholds), 14.999, 15.001, "timeout: all three types should grant the full 15 points")
	_cleanup_fixture(fixture)


func _test_exact_score_tie_draws() -> void:
	var fixture: Dictionary = _make_turrets(24, 24)
	var counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 700,
		RulesScript.AI_FACTION: 700,
		RulesScript.NEUTRAL_OWNER: 200,
	}
	var strongholds: Dictionary = {
		RulesScript.PLAYER_FACTION: {"active_types": [RegionTypeScript.FACTORY]},
		RulesScript.AI_FACTION: {"active_types": [RegionTypeScript.ENERGY]},
	}
	var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(counts, 1600, true, fixture.turrets, strongholds)

	_assert.that(bool(result.draw), "timeout: exact weighted tie should draw")
	_assert.eq(int(result.winner), -1, "timeout: draw should not assign a faction")
	_cleanup_fixture(fixture)


func _test_chamber_destruction_still_ends_immediately() -> void:
	var fixture: Dictionary = _make_turrets(1, 0)
	fixture.ai.is_destroyed = true
	var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(
		{RulesScript.PLAYER_FACTION: 1, RulesScript.AI_FACTION: 99},
		100,
		false,
		fixture.turrets,
		{}
	)

	_assert.that(bool(result.ended), "victory: destroyed chamber should end before timeout scoring")
	_assert.eq(str(result.reason), "command_chamber", "victory: immediate result should retain command-chamber reason")
	_assert.eq(int(result.winner), RulesScript.PLAYER_FACTION, "victory: surviving chamber should win")
	_cleanup_fixture(fixture)


func _test_result_panel_shows_score_components() -> void:
	var fixture: Dictionary = _make_turrets(20, 30)
	var counts: Dictionary = {
		RulesScript.PLAYER_FACTION: 800,
		RulesScript.AI_FACTION: 600,
		RulesScript.NEUTRAL_OWNER: 200,
	}
	var result: Dictionary = WinConditionEvaluator.evaluate_cardfront(
		counts,
		1600,
		true,
		fixture.turrets,
		{
			RulesScript.PLAYER_FACTION: {"active_types": [RegionTypeScript.FACTORY]},
			RulesScript.AI_FACTION: {"active_types": [RegionTypeScript.ENERGY]},
		}
	)
	var scene: PackedScene = load("res://scenes/ui/cardfront/CardfrontMatchResultPanel.tscn")
	var panel = scene.instantiate()
	get_root().add_child(panel)
	await process_frame
	panel.setup(null, Vector2(1120, 720))
	panel.show_result(
		"AI 胜利",
		str(result.sub_text),
		counts,
		1600,
		Color.RED,
		result.score_breakdown
	)
	var score_text: String = str(panel.get_node("Panel/ScoreLabel").text)

	_assert.that(score_text.contains("玩家：舱"), "timeout UI: result panel should show player score components")
	_assert.that(score_text.contains("AI：舱"), "timeout UI: result panel should show AI score components")
	_assert.that(score_text.contains("据点"), "timeout UI: result panel should name stronghold score")
	panel.free()
	_cleanup_fixture(fixture)


func _make_turrets(player_health: int, ai_health: int) -> Dictionary:
	var player = MockTurret.new()
	var ai = MockTurret.new()
	player.health = player_health
	ai.health = ai_health
	get_root().add_child(player)
	get_root().add_child(ai)
	return {
		"player": player,
		"ai": ai,
		"turrets": {
			RulesScript.PLAYER_FACTION: player,
			RulesScript.AI_FACTION: ai,
		},
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	fixture.player.free()
	fixture.ai.free()
