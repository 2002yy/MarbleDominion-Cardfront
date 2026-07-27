extends SceneTree

const TestAssertScript = preload("res://scripts/tests/TestAssert.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const InteractionScript = preload("res://scripts/cardfront/entities/CardfrontProjectileEntityInteraction.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

var _assert = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssertScript.new()
	_test_registry_and_collision_order()
	_test_projectile_interactions()
	_test_tower_runtime_hooks()
	_assert.report("[CardfrontBattlefieldEntityFoundationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_registry_and_collision_order() -> void:
	var registry = RegistryScript.new()
	_assert.that(registry.register_building_slot("left_bridge", Vector2i(2, 2)), "register tower slot")
	var tower = registry.spawn_defense_tower("tower_a", "interceptor", 1, "left_bridge", 4)
	_assert.that(tower != null, "spawn tower in registered slot")
	_assert.eq(registry.spawn_defense_tower("tower_b", "interceptor", 1, "left_bridge", 4), null, "occupied slot rejects second tower")
	var creature = registry.spawn_creature("creature_a", "iron_guard", 2, Vector2i(2, 2), 4, CreatureStateScript.ARMOR_ARMORED)
	_assert.that(creature != null, "spawn creature on tower cell")
	var targets: Array = registry.get_collision_targets(Vector2i(2, 2), 1)
	_assert.eq(targets.size(), 1, "friendly tower excluded from collision targets")
	_assert.eq(targets[0].entity_id, "creature_a", "enemy creature blocks before structures")
	var enemy_targets: Array = registry.get_collision_targets(Vector2i(2, 2), 2)
	_assert.eq(enemy_targets.size(), 1, "friendly creature excluded")
	_assert.eq(enemy_targets[0].entity_id, "tower_a", "enemy tower remains target")


func _test_projectile_interactions() -> void:
	var normal = CreatureStateScript.new()
	normal.setup_creature("normal", "repair_drone", 2, Vector2i.ZERO, 2)
	var armored = CreatureStateScript.new()
	armored.setup_creature("armored", "iron_guard", 2, Vector2i.ZERO, 4, CreatureStateScript.ARMOR_ARMORED)
	var standard_hit: Dictionary = InteractionScript.apply(ProjectileTypeScript.STANDARD, normal)
	_assert.eq(standard_hit["damage_applied"], 1, "standard deals one to normal creature")
	var siege_hit: Dictionary = InteractionScript.apply(ProjectileTypeScript.SIEGE, armored)
	_assert.eq(siege_hit["damage_applied"], 2, "siege deals two to armored creature")
	var suppression_hit: Dictionary = InteractionScript.apply(ProjectileTypeScript.SUPPRESSION, armored)
	_assert.eq(suppression_hit["damage_applied"], 0, "suppression deals no creature damage")
	_assert.eq(suppression_hit["push_cells"], 1, "suppression requests one-cell push")
	_assert.that(not armored.can_act(), "suppression stuns creature")
	armored.tick_round()
	_assert.that(armored.can_act(), "creature recovers after one round")

	var registry = RegistryScript.new()
	registry.register_building_slot("tower_slot", Vector2i.ONE)
	var tower = registry.spawn_defense_tower("tower", "interceptor", 2, "tower_slot", 5)
	var tower_suppression: Dictionary = InteractionScript.apply(ProjectileTypeScript.SUPPRESSION, tower)
	_assert.eq(tower_suppression["damage_applied"], 0, "suppression does not damage tower")
	_assert.that(not tower.can_act(), "suppression disables tower")
	tower.tick_round()
	var tower_siege: Dictionary = InteractionScript.apply(ProjectileTypeScript.SIEGE, tower)
	_assert.eq(tower_siege["damage_applied"], 3, "siege deals three structure damage")


func _test_tower_runtime_hooks() -> void:
	var registry = RegistryScript.new()
	registry.register_building_slot("beacon_slot", Vector2i(3, 3))
	var beacon = registry.spawn_defense_tower("beacon", "fire_control_beacon", 1, "beacon_slot", 4)
	beacon.configure_interceptor(2)
	beacon.configure_summoner("repair_drone", 2)
	registry.begin_volley()
	_assert.that(beacon.consume_intercept(), "first intercept available")
	_assert.that(beacon.consume_intercept(), "second intercept available")
	_assert.that(not beacon.consume_intercept(), "intercept capacity enforced")
	registry.tick_round()
	_assert.that(not beacon.should_summon(), "summon cooldown remains after one round")
	registry.tick_round()
	_assert.that(beacon.should_summon(), "tower can request creature summon")
	beacon.acknowledge_summon()
	_assert.that(not beacon.should_summon(), "summon acknowledgement resets cooldown")
