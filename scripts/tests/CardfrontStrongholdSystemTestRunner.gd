extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const StrongholdSystemScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const VolleyPlanScript = preload("res://scripts/cardfront/volley/CardfrontVolleyPlan.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontStrongholdSystemTest] Starting tactical stronghold tests")
	await process_frame

	await _test_threshold_and_one_bonus_per_type()
	await _test_lost_control_removes_bonus()
	_test_legacy_reward_application_is_metadata_only()

	_assert.report("[CardfrontStrongholdSystemTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_threshold_and_one_bonus_per_type() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_map = fixture.region_map
	var battlefield = fixture.battlefield
	var system = fixture.system
	var factory_ids: Array = _region_ids_of_type(region_map, RegionTypeScript.FACTORY)
	var energy_ids: Array = _region_ids_of_type(region_map, RegionTypeScript.ENERGY)
	var lab_ids: Array = _region_ids_of_type(region_map, RegionTypeScript.LAB)

	_paint_region_percent(battlefield, region_map, int(factory_ids[0]), CardfrontRulesScript.PLAYER_FACTION, 0.80)
	_paint_region_percent(battlefield, region_map, int(factory_ids[1]), CardfrontRulesScript.PLAYER_FACTION, 1.00)
	_paint_region_percent(battlefield, region_map, int(energy_ids[0]), CardfrontRulesScript.PLAYER_FACTION, 0.79)
	_paint_region_percent(battlefield, region_map, int(lab_ids[0]), CardfrontRulesScript.PLAYER_FACTION, 0.80)
	var snapshot: Dictionary = system.sample_bonuses()
	var player: Dictionary = snapshot[CardfrontRulesScript.PLAYER_FACTION]

	_assert.eq(int(player.shot_count_bonus), 0, "stronghold: factory must no longer grant live volley shots")
	_assert.eq(int(player.compatibility_shot_count_bonus), StrongholdRulesScript.FACTORY_SHOT_BONUS, "stronghold: factory legacy +3 formula should remain as compatibility evidence")
	_assert.eq(int(player.temporary_attack_level_bonus), 0, "stronghold: energy live attack bonus must stay neutral")
	_assert.eq(int(player.compatibility_temporary_attack_level_bonus), 0, "stronghold: 79 percent energy control should not activate even in compatibility output")
	_assert.eq(int(player.draft_choice_count), 3, "stronghold: lab must no longer expand the live draft beyond three choices")
	_assert.eq(int(player.compatibility_draft_choice_count), StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT, "stronghold: lab legacy four-choice formula should remain as compatibility evidence")
	_assert.eq(int(player.active_regions[RegionTypeScript.FACTORY]), int(factory_ids[1]), "stronghold: same type should select the highest-control region")
	_assert.eq((player.active_types as Array).count(RegionTypeScript.FACTORY), 1, "stronghold: same type should appear once")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_lost_control_removes_bonus() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_map = fixture.region_map
	var battlefield = fixture.battlefield
	var system = fixture.system
	var energy_id: int = int(_region_ids_of_type(region_map, RegionTypeScript.ENERGY)[0])

	_paint_region_percent(battlefield, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 1.00)
	var active: Dictionary = system.sample_bonuses()[CardfrontRulesScript.PLAYER_FACTION]
	_assert.eq(int(active.temporary_attack_level_bonus), 0, "stronghold: controlled energy relay must not mutate live attack level")
	_assert.eq(int(active.compatibility_temporary_attack_level_bonus), StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS, "stronghold: controlled energy relay should retain the legacy +1 formula as compatibility evidence")

	_paint_all_neutral(battlefield)
	var lost: Dictionary = system.sample_bonuses()[CardfrontRulesScript.PLAYER_FACTION]
	_assert.eq(int(lost.temporary_attack_level_bonus), 0, "stronghold: lost control should keep the live attack bonus neutral")
	_assert.eq(int(lost.compatibility_temporary_attack_level_bonus), 0, "stronghold: lost control should clear the compatibility producer value")
	_assert.that((lost.active_types as Array).is_empty(), "stronghold: lost control should clear active types")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_legacy_reward_application_is_metadata_only() -> void:
	var system = StrongholdSystemScript.new()
	var plan = VolleyPlanScript.new()
	for _index in range(31):
		plan.projectile_sequence.append(ProjectileTypeScript.STANDARD)
	plan.shot_count = plan.projectile_sequence.size()
	plan.projectile_counts = ProjectileTypeScript.count_types(plan.projectile_sequence)
	plan.projectile_power = 2
	plan.attack_level = RunStateScript.MAX_ATTACK_LEVEL
	plan.chamber_damage_quarters = 4 + RunStateScript.MAX_ATTACK_LEVEL
	var snapshot: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: {
			"active_types": [RegionTypeScript.FACTORY, RegionTypeScript.ENERGY],
			"shot_count_bonus": 0,
			"temporary_attack_level_bonus": 0,
			"draft_choice_count": 3,
			"compatibility_shot_count_bonus": StrongholdRulesScript.FACTORY_SHOT_BONUS,
			"compatibility_temporary_attack_level_bonus": StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS,
			"compatibility_draft_choice_count": StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT,
		},
	}
	system.apply_to_volley_plan(CardfrontRulesScript.PLAYER_FACTION, plan, snapshot)

	_assert.eq(plan.shot_count, 31, "stronghold: legacy factory reward must not append live volley shots")
	_assert.eq(plan.projectile_sequence.size(), 31, "stronghold: legacy factory reward must not mutate the typed projectile sequence")
	_assert.eq(plan.projectile_power, 2, "stronghold: compatibility metadata must not mutate projectile power")
	_assert.eq(plan.attack_level, RunStateScript.MAX_ATTACK_LEVEL, "stronghold: legacy energy reward must not raise live attack level")
	_assert.eq(plan.chamber_damage_quarters, 4 + RunStateScript.MAX_ATTACK_LEVEL, "stronghold: legacy energy reward must not raise chamber damage")
	_assert.eq(plan.stronghold_shot_bonus, StrongholdRulesScript.FACTORY_SHOT_BONUS, "stronghold: plan may retain factory legacy contribution as metadata")
	_assert.eq(plan.stronghold_attack_level_bonus, StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS, "stronghold: plan may retain energy legacy contribution as metadata")
	system.free()


func _make_fixture() -> Dictionary:
	var region_map = RegionMapScript.new()
	region_map.configure(20)
	region_map.generate_default_layout()
	var battlefield := Battlefield.new()
	battlefield.configure(20)
	get_root().add_child(battlefield)
	_paint_all_neutral(battlefield)
	var system = StrongholdSystemScript.new()
	get_root().add_child(system)
	_assert.that(system.setup(region_map, battlefield), "stronghold: fixture setup should succeed")
	return {
		"region_map": region_map,
		"battlefield": battlefield,
		"system": system,
	}


func _region_ids_of_type(region_map, region_type: String) -> Array:
	var result: Array = []
	for raw_region_id in region_map.get_controllable_region_ids():
		var region_id: int = int(raw_region_id)
		if str(region_map.get_region_type_by_id(region_id)) == region_type:
			result.append(region_id)
	return result


func _paint_all_neutral(battlefield) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	for x in range(owners.size()):
		for y in range((owners[x] as Array).size()):
			owners[x][y] = CardfrontRulesScript.NEUTRAL_OWNER
	battlefield.replace_owners(owners, false)


func _paint_region_percent(battlefield, region_map, region_id: int, owner_id: int, ratio: float) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	var cells: Array = region_map.get_region_cells(region_id)
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	var owner_count: int = (
		ceili(float(cells.size()) * clamped_ratio)
		if clamped_ratio >= 0.80
		else floori(float(cells.size()) * clamped_ratio)
	)
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		owners[cell.x][cell.y] = owner_id if index < owner_count else CardfrontRulesScript.NEUTRAL_OWNER
	battlefield.replace_owners(owners, false)
