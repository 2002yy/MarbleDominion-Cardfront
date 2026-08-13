extends SceneTree

const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSelectedLevelSnapshotTest] Starting P0-09B2 save contract")
	await process_frame

	_test_new_snapshot_roundtrip_preserves_both_semantics()
	_test_legacy_snapshot_does_not_guess_level_from_applications()
	_test_snapshot_and_restore_are_detached()

	_assert.report("[CardfrontSelectedLevelSnapshotTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_new_snapshot_roundtrip_preserves_both_semantics() -> void:
	var state = RunStateScript.new()
	state.setup(0, 10)
	var resolver = UpgradeResolverScript.new()
	var copied_id: String = UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5
	resolver.resolve(state, UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE)
	resolver.resolve(state, copied_id)
	resolver.resolve(state, UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1)

	var snapshot: Dictionary = state.snapshot()
	var restored = RunStateScript.restore(snapshot)
	_assert.that(snapshot.has("selected_upgrade_levels"), "new save: snapshot explicitly includes Selected Level authority")
	_assert.eq(restored.get_selected_upgrade_level(copied_id), 1, "new save: copied card Level round-trips independently")
	_assert.eq(restored.get_effect_application_count(copied_id), 2, "new save: copied effect applications include Echo replay")
	_assert.eq(restored.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE), 1, "new save: Echo card Level round-trips")
	_assert.eq(restored.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1), 1, "new save: following real selection Level round-trips")


func _test_legacy_snapshot_does_not_guess_level_from_applications() -> void:
	var legacy_snapshot: Dictionary = {
		"owner_id": 0,
		"base_volley_count": 10,
		"applied_upgrade_counts": {
			UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5: 4,
			UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1: 2,
		},
	}
	var restored = RunStateScript.restore(legacy_snapshot)
	_assert.eq(restored.get_effect_application_count(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5), 4, "legacy save: application history remains readable")
	_assert.eq(restored.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5), 0, "legacy save: application history is not guessed into exact Level")
	_assert.eq(restored.get_selected_upgrade_level(UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1), 0, "legacy save: every missing Level safely defaults to zero")
	_assert.eq(restored.selected_upgrade_levels, {}, "legacy save: missing Level store restores as an explicit empty authority")


func _test_snapshot_and_restore_are_detached() -> void:
	var state = RunStateScript.new()
	state.setup(0, 10)
	var upgrade_id: String = UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1
	state.record_selected_upgrade_resolved(upgrade_id)
	state.record_effect_application(upgrade_id, 2)
	var snapshot: Dictionary = state.snapshot()
	(snapshot.selected_upgrade_levels as Dictionary)[upgrade_id] = 9
	(snapshot.applied_upgrade_counts as Dictionary)[upgrade_id] = 8
	_assert.eq(state.get_selected_upgrade_level(upgrade_id), 1, "detachment: mutating snapshot Level does not change live state")
	_assert.eq(state.get_effect_application_count(upgrade_id), 2, "detachment: mutating snapshot history does not change live state")

	var restored = RunStateScript.restore(snapshot)
	(snapshot.selected_upgrade_levels as Dictionary)[upgrade_id] = 7
	(snapshot.applied_upgrade_counts as Dictionary)[upgrade_id] = 6
	_assert.eq(restored.get_selected_upgrade_level(upgrade_id), 9, "detachment: restored Level does not share snapshot dictionary")
	_assert.eq(restored.get_effect_application_count(upgrade_id), 8, "detachment: restored history does not share snapshot dictionary")
