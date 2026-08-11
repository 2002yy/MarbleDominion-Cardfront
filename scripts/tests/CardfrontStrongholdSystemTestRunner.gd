extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const AiCommanderScript = preload("res://scripts/cardfront/ai/CardfrontAiCommander.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const StrongholdSystemScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const VolleyPlanScript = preload("res://scripts/cardfront/volley/CardfrontVolleyPlan.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontStrongholdSystemTest] Starting tactical stronghold status tests")
	await process_frame

	await _test_threshold_and_one_status_per_type()
	await _test_lost_control_removes_status()
	await _test_legacy_api_shell_is_status_only()
	_test_legacy_reward_application_is_fully_neutral()
	_test_consumers_reject_legacy_rewards()

	_assert.report("[CardfrontStrongholdSystemTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_threshold_and_one_status_per_type() -> void:
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
	var snapshot: Dictionary = system.sample_status()
	var player: Dictionary = snapshot[CardfrontRulesScript.PLAYER_FACTION]

	_assert.that(not player.has("shot_count_bonus"), "stronghold status: Factory reward field must not be produced")
	_assert.that(not player.has("temporary_attack_level_bonus"), "stronghold status: Energy reward field must not be produced")
	_assert.that(not player.has("draft_choice_count"), "stronghold status: Lab reward field must not be produced")
	_assert.that((player.active_types as Array).has(RegionTypeScript.FACTORY), "stronghold status: active Factory identity should remain observable")
	_assert.that((player.active_types as Array).has(RegionTypeScript.LAB), "stronghold status: active Lab identity should remain observable")
	_assert.that(not (player.active_types as Array).has(RegionTypeScript.ENERGY), "stronghold status: 79 percent Energy control should remain inactive")
	_assert.eq(int(player.active_regions[RegionTypeScript.FACTORY]), int(factory_ids[1]), "stronghold status: same type should select the highest-control region")
	_assert.eq((player.active_types as Array).count(RegionTypeScript.FACTORY), 1, "stronghold status: same type should appear once")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_lost_control_removes_status() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_map = fixture.region_map
	var battlefield = fixture.battlefield
	var system = fixture.system
	var energy_id: int = int(_region_ids_of_type(region_map, RegionTypeScript.ENERGY)[0])

	_paint_region_percent(battlefield, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 1.00)
	var active: Dictionary = system.sample_status()[CardfrontRulesScript.PLAYER_FACTION]
	_assert.that((active.active_types as Array).has(RegionTypeScript.ENERGY), "stronghold status: controlled Energy relay should be active")
	_assert.that(not active.has("temporary_attack_level_bonus"), "stronghold status: active Energy must still publish no reward value")

	_paint_all_neutral(battlefield)
	var lost: Dictionary = system.sample_status()[CardfrontRulesScript.PLAYER_FACTION]
	_assert.that((lost.active_types as Array).is_empty(), "stronghold status: lost control should clear active types")
	_assert.that((lost.active_regions as Dictionary).is_empty(), "stronghold status: lost control should clear active regions")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_legacy_api_shell_is_status_only() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_map = fixture.region_map
	var battlefield = fixture.battlefield
	var system = fixture.system
	var factory_id: int = int(_region_ids_of_type(region_map, RegionTypeScript.FACTORY)[0])
	_paint_region_percent(battlefield, region_map, factory_id, CardfrontRulesScript.PLAYER_FACTION, 1.00)

	var sampled: Dictionary = system.sample_bonuses()
	var legacy_named_owner: Dictionary = system.get_owner_bonus(CardfrontRulesScript.PLAYER_FACTION)
	var player: Dictionary = sampled[CardfrontRulesScript.PLAYER_FACTION]
	_assert.that((player.active_types as Array).has(RegionTypeScript.FACTORY), "stronghold compatibility shell: legacy method name may still expose status")
	_assert.that(not player.has("shot_count_bonus"), "stronghold compatibility shell: legacy method must not recreate Factory reward output")
	_assert.that(not legacy_named_owner.has("shot_count_bonus"), "stronghold compatibility shell: legacy owner getter must be status-only")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_legacy_reward_application_is_fully_neutral() -> void:
	var system = StrongholdSystemScript.new()
	var plan = VolleyPlanScript.new()
	for _index in range(31):
		plan.projectile_sequence.append(ProjectileTypeScript.STANDARD)
	plan.shot_count = plan.projectile_sequence.size()
	plan.projectile_counts = ProjectileTypeScript.count_types(plan.projectile_sequence)
	plan.projectile_power = 2
	plan.attack_level = RunStateScript.MAX_ATTACK_LEVEL
	plan.chamber_damage_quarters = 4 + RunStateScript.MAX_ATTACK_LEVEL
	var malicious_legacy_snapshot: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: {
			"active_types": [RegionTypeScript.FACTORY, RegionTypeScript.ENERGY],
			"shot_count_bonus": StrongholdRulesScript.FACTORY_SHOT_BONUS,
			"temporary_attack_level_bonus": StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS,
			"draft_choice_count": StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT,
		},
	}
	system.apply_to_volley_plan(CardfrontRulesScript.PLAYER_FACTION, plan, malicious_legacy_snapshot)

	_assert.eq(plan.shot_count, 31, "stronghold compatibility seam: injected Factory reward must not append live volley shots")
	_assert.eq(plan.projectile_sequence.size(), 31, "stronghold compatibility seam: injected Factory reward must not mutate projectile sequence")
	_assert.eq(plan.attack_level, RunStateScript.MAX_ATTACK_LEVEL, "stronghold compatibility seam: injected Energy reward must not raise attack level")
	_assert.eq(plan.chamber_damage_quarters, 4 + RunStateScript.MAX_ATTACK_LEVEL, "stronghold compatibility seam: injected Energy reward must not raise chamber damage")
	_assert.eq(plan.stronghold_shot_bonus, 0, "stronghold compatibility seam: retired Factory reward metadata must be neutral")
	_assert.eq(plan.stronghold_attack_level_bonus, 0, "stronghold compatibility seam: retired Energy reward metadata must be neutral")
	_assert.that((plan.active_stronghold_types as Array).has(RegionTypeScript.FACTORY), "stronghold compatibility seam: status identity may remain attached")
	system.free()


func _test_consumers_reject_legacy_rewards() -> void:
	var draft = DraftSystemScript.new()
	draft.set_seed(17)
	var offer: Array = draft.draw_offer(null, StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT)
	_assert.eq(offer.size(), DraftSystemScript.DEFAULT_OFFER_SIZE, "stronghold draft consumer: legacy four-choice request must stay capped to three")

	var commander = AiCommanderScript.new()
	var sanitized: Dictionary = commander._sanitize_legacy_stronghold_context({
		"source": "live",
		"post_multiplier_shot_bonus": StrongholdRulesScript.FACTORY_SHOT_BONUS,
		"temporary_attack_level_bonus": StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS,
		"future_offer_size": StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT,
	})
	_assert.eq(int(sanitized.post_multiplier_shot_bonus), 0, "stronghold AI consumer: legacy Factory reward must not affect valuation")
	_assert.eq(int(sanitized.temporary_attack_level_bonus), 0, "stronghold AI consumer: legacy Energy reward must not affect valuation")
	_assert.eq(int(sanitized.future_offer_size), DraftSystemScript.DEFAULT_OFFER_SIZE, "stronghold AI consumer: legacy Lab reward must not affect future-offer valuation")


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
