extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const AdapterScript = preload("res://scripts/cardfront/support/capture/SupportCaptureOccupancyAdapter.gd")
const ProfilesScript = preload("res://scripts/cardfront/support/capture/SupportCaptureProfiles.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureOccupancyAdapterTest] Checking registry extraction")
	await process_frame

	_test_registry_records_become_explicit_contributors()
	_test_missing_registry_fails_closed()

	_assert.report("[CardfrontSupportCaptureOccupancyAdapterTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_registry_records_become_explicit_contributors() -> void:
	var registry = RegistryScript.new()
	var cell_a := Vector2i(7, 30)
	var cell_b := Vector2i(8, 30)
	var outside := Vector2i(9, 30)
	registry.register_building_slot("tower_slot", cell_a)
	registry.spawn_creature("player_scout", "scout_unit", RulesScript.PLAYER_FACTION, cell_a, 2)
	registry.spawn_creature("ai_guard", "armored_guard", RulesScript.AI_FACTION, cell_b, 4)
	registry.spawn_creature("unknown_control", "unknown_creature", RulesScript.PLAYER_FACTION, cell_a, 2)
	registry.spawn_creature("neutral_colossus", "gate_colossus", RulesScript.NEUTRAL_OWNER, cell_a, 5)
	var dead = registry.spawn_creature("dead_repair", "repair_unit", RulesScript.PLAYER_FACTION, cell_b, 1)
	dead.apply_damage(1)
	registry.spawn_creature("outside_repair", "repair_unit", RulesScript.AI_FACTION, outside, 2)
	registry.spawn_defense_tower("tower", "interceptor_tower", RulesScript.PLAYER_FACTION, "tower_slot", 4)

	var contributors: Array = AdapterScript.extract(registry, [cell_b, cell_a, cell_a])
	_assert.eq(contributors.size(), 3, "occupancy adapter: only in-footprint living duel creatures produce DTOs")
	var by_id: Dictionary = {}
	for contributor in contributors:
		by_id[contributor.entity_id] = contributor
	_assert.eq(contributors.map(func(value): return value.entity_id), ["ai_guard", "player_scout", "unknown_control"], "occupancy adapter: output order and duplicate-cell handling are deterministic")
	_assert.eq(by_id.player_scout.capture_profile, ProfilesScript.PROFILE_LIGHT_CONTROL, "occupancy adapter: Scout uses centralized profile")
	_assert.eq(by_id.player_scout.capture_weight, 2.0, "occupancy adapter: Scout uses centralized weight")
	_assert.that(by_id.player_scout.eligible, "occupancy adapter: known control Creature is eligible")
	_assert.eq(by_id.ai_guard.owner_id, RulesScript.AI_FACTION, "occupancy adapter: owner remains explicit")
	_assert.eq(by_id.ai_guard.cell, cell_b, "occupancy adapter: registry cell remains explicit")
	_assert.eq(by_id.unknown_control.capture_profile, ProfilesScript.PROFILE_NON_CONTROL, "occupancy adapter: unknown Creature fails closed")
	_assert.eq(by_id.unknown_control.capture_weight, 0.0, "occupancy adapter: unknown Creature contributes zero")
	_assert.that(not by_id.unknown_control.eligible, "occupancy adapter: unknown Creature is ineligible by profile")
	for excluded_id in ["neutral_colossus", "dead_repair", "outside_repair", "tower"]:
		_assert.that(not by_id.has(excluded_id), "occupancy adapter: excludes %s" % excluded_id)


func _test_missing_registry_fails_closed() -> void:
	_assert.eq(AdapterScript.extract(null, [Vector2i.ZERO]), [], "occupancy adapter: missing registry returns no contributors")
