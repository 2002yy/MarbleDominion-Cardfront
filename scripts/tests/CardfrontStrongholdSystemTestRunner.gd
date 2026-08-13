extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const StrongholdSystemScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd")

const PRODUCTION_ROOT: String = "res://scripts/cardfront"
const OUTER_PRODUCTION_FILES: Array[String] = [
	"res://scripts/Main.gd",
	"res://scripts/GameRuntimeContext.gd",
]
const RETIRED_AUTHORITY_NEEDLES: Array[String] = [
	"FACTORY_SHOT_BONUS",
	"ENERGY_ATTACK_LEVEL_BONUS",
	"LAB_DRAFT_CHOICE_COUNT",
	"current_stronghold_bonuses",
	"get_stronghold_bonus",
	"sample_bonuses",
	"get_owner_bonus",
	"apply_to_volley_plan",
	"stronghold_shot_bonus",
	"stronghold_attack_level_bonus",
	"bonuses_sampled",
]

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontStrongholdSystemTest] Starting tactical stronghold status tests")
	await process_frame

	await _test_threshold_and_one_status_per_type()
	await _test_lost_control_removes_status()
	await _test_status_api_has_no_legacy_reward_seams()
	_test_draft_contract_remains_three_choice()
	_test_production_source_has_no_legacy_reward_authority()

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


func _test_status_api_has_no_legacy_reward_seams() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_map = fixture.region_map
	var battlefield = fixture.battlefield
	var system = fixture.system
	var factory_id: int = int(_region_ids_of_type(region_map, RegionTypeScript.FACTORY)[0])
	_paint_region_percent(battlefield, region_map, factory_id, CardfrontRulesScript.PLAYER_FACTION, 1.00)

	var sampled: Dictionary = system.sample_status()
	var player: Dictionary = system.get_owner_status(CardfrontRulesScript.PLAYER_FACTION)
	_assert.that((sampled[CardfrontRulesScript.PLAYER_FACTION].active_types as Array).has(RegionTypeScript.FACTORY), "stronghold status API: active identity should remain available")
	_assert.that(not player.has("shot_count_bonus"), "stronghold status API: no Factory reward field may survive")
	_assert.that(not system.has_method("sample_bonuses"), "stronghold status API: legacy sample_bonuses seam must be removed")
	_assert.that(not system.has_method("get_owner_bonus"), "stronghold status API: legacy get_owner_bonus seam must be removed")
	_assert.that(not system.has_method("apply_to_volley_plan"), "stronghold status API: legacy volley mutation seam must be removed")
	_assert.that(not system.has_signal("bonuses_sampled"), "stronghold status API: legacy reward signal must be removed")

	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(system)
	await process_frame


func _test_draft_contract_remains_three_choice() -> void:
	var draft = DraftSystemScript.new()
	draft.set_seed(17)
	var oversized_request: Array = draft.draw_offer(null, DraftSystemScript.DEFAULT_OFFER_SIZE + 1)
	_assert.eq(oversized_request.size(), DraftSystemScript.DEFAULT_OFFER_SIZE, "draft contract: oversized requests must remain capped to the formal three-choice UI")


func _test_production_source_has_no_legacy_reward_authority() -> void:
	var production_paths: Array[String] = []
	_collect_gd_files(PRODUCTION_ROOT, production_paths)
	production_paths.append_array(OUTER_PRODUCTION_FILES)
	_assert.that(not production_paths.is_empty(), "legacy gate: production Cardfront scripts should be discoverable")
	for path in production_paths:
		var source: String = _read_source(path)
		for needle in RETIRED_AUTHORITY_NEEDLES:
			_assert.that(
				not source.contains(needle),
				"legacy gate: retired Stronghold authority token '%s' must not exist in production source %s" % [needle, path]
			)


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


func _collect_gd_files(root_path: String, out_paths: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var child_path: String = root_path.path_join(entry)
			if dir.current_is_dir():
				_collect_gd_files(child_path, out_paths)
			elif entry.ends_with(".gd"):
				out_paths.append(child_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
