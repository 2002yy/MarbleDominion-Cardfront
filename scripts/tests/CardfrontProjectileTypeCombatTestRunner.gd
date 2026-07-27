extends SceneTree
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const CaptureInterceptorScript = preload("res://scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd")
class MockRoundDirector:
	extends RefCounted
	var states: Dictionary = {}
	func get_run_state(owner_id: int): return states.get(owner_id, null)
class MockDefenseSystem:
	extends RefCounted
	var battlefield = null
var _assert: TestAssert
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	_test_mixes()
	_test_cards()
	_test_chamber_and_visuals()
	_test_defense()
	_test_engineer_passives()
	_assert.report("[CardfrontProjectileTypeCombatTest]")
	quit(0 if _assert.failures.is_empty() else 1)
func _test_mixes() -> void:
	var resolver = VolleyResolverScript.new()
	var ep = resolver.build_and_consume(_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER))
	var bp = resolver.build_and_consume(_state(HeroRegistryScript.HERO_BALANCED_COMMANDER))
	var gp = resolver.build_and_consume(_state(HeroRegistryScript.HERO_RAPID_GUNNER))
	_assert.eq(ep.projectile_counts[ProjectileTypeScript.STANDARD], 4, "Engineer standard")
	_assert.eq(ep.projectile_counts[ProjectileTypeScript.SIEGE], 1, "Engineer siege")
	_assert.eq(bp.projectile_counts[ProjectileTypeScript.STANDARD], 6, "Balanced standard")
	_assert.eq(gp.projectile_counts[ProjectileTypeScript.SUPPRESSION], 1, "Gunner suppression")
	_assert.eq(ep.projectile_sequence[0], ProjectileTypeScript.SIEGE, "Engineer siege opens volley")
	_assert.eq(gp.projectile_sequence[0], ProjectileTypeScript.SUPPRESSION, "Gunner suppression opens volley")
	_assert.eq(ep.special_shot_count, 1, "Engineer special segment")
	_assert.eq(ep.standard_shot_count, 4, "Engineer standard segment")
	_assert.eq(ProjectileTypeScript.direct_damage_units_for_sequence(ep.projectile_sequence), 6.0, "Engineer direct budget")
	_assert.eq(ProjectileTypeScript.direct_damage_units_for_sequence(gp.projectile_sequence), 6.0, "Gunner direct budget")
	_assert.eq(ProjectileTypeScript.territory_pressure_units(ProjectileTypeScript.SUPPRESSION), 1.35, "suppression trades all chamber damage for stronger route occupation")
	_assert.eq(ProjectileTypeScript.territory_pressure_units(ProjectileTypeScript.SIEGE), 0.9, "siege trades ten percent territory pressure for chamber and pierce power")
func _test_cards() -> void:
	var resolver = VolleyResolverScript.new()
	var engineer = _state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	engineer.add_next_volley_bonus(5)
	var plus = resolver.build_and_consume(engineer)
	_assert.eq(plus.projectile_counts[ProjectileTypeScript.STANDARD], 9, "+5 all standard")
	_assert.eq(plus.projectile_counts[ProjectileTypeScript.SIEGE], 1, "+5 no siege")
	var combined = _state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	combined.multiply_next_volley(2)
	combined.add_next_volley_bonus(5)
	var combined_plan = resolver.build_and_consume(combined)
	_assert.eq(combined_plan.projectile_counts[ProjectileTypeScript.SIEGE], 2, "x2 duplicates Engineer base siege")
	_assert.eq(combined_plan.projectile_counts[ProjectileTypeScript.STANDARD], 13, "+5 is appended once after x2")
	_assert.eq(combined_plan.projectile_sequence[0], ProjectileTypeScript.SIEGE, "first copied siege remains in special segment")
	_assert.eq(combined_plan.projectile_sequence[1], ProjectileTypeScript.SIEGE, "second copied siege remains in special segment")
	var gunner = _state(HeroRegistryScript.HERO_RAPID_GUNNER)
	gunner.multiply_next_volley(2)
	var doubled = resolver.build_and_consume(gunner)
	_assert.eq(doubled.projectile_counts[ProjectileTypeScript.SUPPRESSION], 2, "x2 duplicates group")
	_assert.eq(doubled.projectile_sequence[0], ProjectileTypeScript.SUPPRESSION, "first suppression precedes standards")
	_assert.eq(doubled.projectile_sequence[1], ProjectileTypeScript.SUPPRESSION, "second suppression precedes standards")
	_assert.eq(ProjectileTypeScript.territory_pressure_units(doubled.projectile_sequence[0]) + ProjectileTypeScript.territory_pressure_units(doubled.projectile_sequence[1]), 2.7, "two copied suppression shots create a visible route-control spike")
	var converted = _state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	converted.add_next_volley_conversion(ProjectileTypeScript.SIEGE, 2)
	var converted_plan = resolver.build_and_consume(converted)
	_assert.eq(converted_plan.projectile_sequence[0], ProjectileTypeScript.SIEGE, "converted siege moves into special segment")
	_assert.eq(converted_plan.projectile_sequence[1], ProjectileTypeScript.SIEGE, "all converted siege projectiles lead")
func _test_chamber_and_visuals() -> void:
	var target = Turret.new()
	target.faction_id = RulesScript.AI_FACTION
	target.configure_health_pool(20, true)
	target.global_position = Vector2.ZERO
	get_root().add_child(target)
	var standard = _bullet(ProjectileTypeScript.STANDARD, target)
	var siege = _bullet(ProjectileTypeScript.SIEGE, target)
	var suppression = _bullet(ProjectileTypeScript.SUPPRESSION, target)
	standard._try_hit_enemy_turret(); _assert.eq(target.health, 19, "standard damage")
	siege._try_hit_enemy_turret(); _assert.eq(target.health, 17, "siege double damage")
	suppression._try_hit_enemy_turret(); _assert.eq(target.health, 17, "suppression zero damage")
	_assert.neq(standard.get_projectile_visual_signature()["fill"], siege.get_projectile_visual_signature()["fill"], "siege visible")
	_assert.neq(standard.get_projectile_visual_signature()["fill"], suppression.get_projectile_visual_signature()["fill"], "suppression visible")
	for node in [standard, siege, suppression, target]: TestFixtures.cleanup_node(node)
func _test_defense() -> void:
	var layer = FortifyLayerScript.new(); layer.configure(4)
	var interceptor = CaptureInterceptorScript.new(); interceptor.setup(layer)
	var cell := Vector2i(1, 1)
	layer.set_fortify_stack(cell, 1)
	_assert.that(not interceptor.should_block_capture(cell, 1, 2, {"projectile_defense_pierce_remaining": 1}), "siege through one")
	layer.set_fortify_stack(cell, 2)
	_assert.that(interceptor.should_block_capture(cell, 1, 2, {"projectile_defense_pierce_remaining": 1}), "siege blocked by two")
	_assert.eq(layer.get_fortify_stack(cell), 0, "siege consumes two")
	layer.set_fortify_stack(cell, 1)
	_assert.that(interceptor.should_block_capture(cell, 1, 2, {}), "suppression normal defense")
func _test_engineer_passives() -> void:
	var battlefield = Battlefield.new(); battlefield.configure(4); get_root().add_child(battlefield)
	var owners: Array = []
	for x in range(4):
		var col: Array = []
		for y in range(4): col.append(RulesScript.NEUTRAL_OWNER)
		owners.append(col)
	owners[1][2] = RulesScript.PLAYER_FACTION
	battlefield.replace_owners(owners, false)
	var layer = FortifyLayerScript.new(); layer.configure(4)
	var interceptor = CaptureInterceptorScript.new(); interceptor.setup(layer)
	var director = MockRoundDirector.new(); director.states[RulesScript.PLAYER_FACTION] = _state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER); director.states[RulesScript.AI_FACTION] = _state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var defense = MockDefenseSystem.new(); defense.battlefield = battlefield
	interceptor.configure_runtime(director, defense); battlefield.capture_interceptor = interceptor
	var cell := Vector2i(1, 1)
	_assert.eq(battlefield.apply_bullet(cell, RulesScript.PLAYER_FACTION, {}), "HIT_ENEMY_CELL", "neutral capture")
	_assert.eq(layer.get_fortify_stack(cell), 1, "first neutral frontline capture fortifies")
	var engineer = director.states[RulesScript.PLAYER_FACTION]
	_assert.that(engineer.has_first_capture_fortified(cell), "first-capture history recorded")
	_assert.eq(battlefield.apply_bullet(cell, RulesScript.AI_FACTION, {}), "BLOCKED_BY_FORTIFY", "enemy first removes defense")
	_assert.eq(battlefield.apply_bullet(cell, RulesScript.AI_FACTION, {}), "HIT_ENEMY_CELL", "enemy then captures")
	_assert.eq(battlefield.apply_bullet(cell, RulesScript.PLAYER_FACTION, {}), "HIT_ENEMY_CELL", "Engineer recaptures")
	_assert.eq(layer.get_fortify_stack(cell), 0, "recapture starts at zero defense")
	engineer.request_territory_repair(6, "frontline")
	_assert.eq(engineer.consume_pending_repair()["points"], 8, "Engineer repair +2")
	TestFixtures.cleanup_node(battlefield)
func _state(hero_id: String):
	var state = RunStateScript.new(); state.setup_from_hero(RulesScript.PLAYER_FACTION, hero_id); return state
func _bullet(projectile_type: String, target):
	var bullet = Bullet.new(); bullet.setup(RulesScript.PLAYER_FACTION, Vector2.ZERO, Vector2.RIGHT, null, {RulesScript.AI_FACTION: target}, 1, 4, {"projectile_type": projectile_type}); get_root().add_child(bullet); return bullet
