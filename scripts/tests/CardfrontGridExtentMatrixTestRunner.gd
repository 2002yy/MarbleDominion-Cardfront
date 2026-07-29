extends SceneTree

const GridExtentScript = preload("res://scripts/GridExtent.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const SaveStateApplierScript = preload("res://scripts/SaveStateApplier.gd")
const SaveStateBuilderScript = preload("res://scripts/SaveStateBuilder.gd")

const EXTENTS: Array[Vector2i] = [
	Vector2i(40, 40),
	Vector2i(50, 50),
	Vector2i(40, 50),
	Vector2i(40, 60),
]

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontGridExtentMatrixTest] Starting rectangular grid matrix")
	await process_frame

	_test_legacy_square_save()
	for extent in EXTENTS:
		await _test_runtime_extent(extent)
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontGridExtentMatrixTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_runtime_extent(extent: Vector2i) -> void:
	var main = await _start_main(extent)
	var battlefield = main.runtime.battlefield
	var label := "%dx%d" % [extent.x, extent.y]

	_assert.eq(battlefield.grid_extent, extent, "%s: Battlefield should retain width and height" % label)
	_assert.eq(battlefield.owners.size(), extent.x, "%s: owner grid should have width columns" % label)
	_assert.eq((battlefield.owners[0] as Array).size(), extent.y, "%s: owner columns should have height rows" % label)
	_assert.eq(battlefield.get_pixel_extent(), Vector2(extent) * float(battlefield.cell_size), "%s: pixel extent should be rectangular" % label)

	_assert.eq(main.runtime.region_map.grid_extent, extent, "%s: RegionMap should retain the rectangular extent" % label)
	_assert.eq(main.runtime.region_map.regions.size(), extent.x, "%s: RegionMap should iterate width" % label)
	_assert.eq((main.runtime.region_map.regions[0] as Array).size(), extent.y, "%s: RegionMap should iterate height" % label)
	_assert.eq(main.runtime.fortify_layer.grid_extent, extent, "%s: defense layer should retain the rectangular extent" % label)
	_assert.eq(main.runtime.fortify_layer.stacks.size(), extent.x, "%s: defense layer should iterate width" % label)
	_assert.eq((main.runtime.fortify_layer.stacks[0] as Array).size(), extent.y, "%s: defense layer should iterate height" % label)

	var definition: Dictionary = MapRegistryScript.get_map_definition(main.selected_cardfront_map_id, extent)
	_assert.eq(GridExtentScript.from_config(definition), extent, "%s: map definition should use the requested extent" % label)
	var gate_state: Dictionary = main.runtime.gate_connectivity_system._sample_lane(0, 1)
	var gate_counts: Dictionary = gate_state.get("control_counts", {})
	var sampled_cells: int = 0
	for count in gate_counts.values():
		sampled_cells += int(count)
	_assert.that(sampled_cells > 0, "%s: gate control zone should sample the rectangular battlefield" % label)

	var capture_interceptor = battlefield.capture_interceptor
	var entity_runtime = capture_interceptor.entity_runtime if capture_interceptor != null else null
	_assert.that(entity_runtime != null and entity_runtime.battlefield == battlefield, "%s: entity runtime should share the rectangular Battlefield authority" % label)

	var battlefield_rect: Rect2 = main.runtime.current_layout.get("battlefield_rect", Rect2())
	_assert.eq(battlefield_rect.size.x / battlefield_rect.size.y, float(extent.x) / float(extent.y), "%s: 2D layout should preserve the map aspect ratio" % label)
	var arena_view = main.runtime.orthographic_arena_view
	_assert.eq(arena_view.get_tile_instance_count_for_test(), extent.x * extent.y, "%s: orthographic view should create one tile per cell" % label)
	_assert.that(arena_view.get_camera_size_ratio_for_test() <= 1.20, "%s: orthographic camera should frame the rectangular outer bound" % label)
	if extent == Vector2i(40, 60):
		_assert.that(arena_view.get_z_scale_for_test() <= 1.01, "40x60: cell depth should not stack the legacy 1.28 stretch")
		_test_projectile_rectangular_bounds(main, battlefield, label)

	var payload: Dictionary = SaveStateBuilderScript.build_save_payload(
		{},
		{},
		battlefield,
		null,
		null,
		0.0,
		false,
		1,
		null
	)
	var clean: Dictionary = SaveGameCodec.validate_save_data(payload)
	_assert.eq(GridExtentScript.from_config(clean), extent, "%s: save schema should round-trip grid_extent" % label)
	_assert.eq(str(clean.get("save_version", "")), "2.1.0", "%s: new save should use schema 2.1.0" % label)
	var saved_corner_owner: int = int((clean.get("owners", []) as Array)[extent.x - 1][extent.y - 1])
	battlefield.owners[extent.x - 1][extent.y - 1] = GameConfig.Faction.GREEN
	SaveStateApplierScript.apply_owners(battlefield, clean)
	_assert.eq(int(battlefield.owners[extent.x - 1][extent.y - 1]), saved_corner_owner, "%s: rectangular owner state should restore through SaveStateApplier" % label)

	TestFixtures.cleanup_node(main)
	await _flush()


func _test_projectile_rectangular_bounds(main, battlefield, label: String) -> void:
	var bullet := Bullet.new()
	main.game_layer.add_child(bullet)
	var pixel_extent: Vector2 = battlefield.get_pixel_extent()
	bullet.setup(
		GameConfig.Faction.BLUE,
		battlefield.to_global(pixel_extent - Vector2.ONE),
		Vector2.ONE,
		battlefield
	)
	bullet.speed = 100.0
	bullet.activate()
	bullet._physics_process(0.5)
	var local_position: Vector2 = battlefield.to_local(bullet.global_position)
	_assert.that(local_position.x >= 0.0 and local_position.x <= pixel_extent.x, "%s: projectile should use the width bound" % label)
	_assert.that(local_position.y >= 0.0 and local_position.y <= pixel_extent.y, "%s: projectile should use the height bound" % label)
	TestFixtures.cleanup_node(bullet)


func _test_legacy_square_save() -> void:
	var owners: Array = []
	for x in range(40):
		var column: Array = []
		for y in range(40):
			column.append(GameConfig.Faction.BLUE)
		owners.append(column)
	var clean: Dictionary = SaveGameCodec.validate_save_data({
		"save_version": "2.0.0",
		"grid_size": 40,
		"owners": owners,
	})
	_assert.eq(GridExtentScript.from_config(clean), Vector2i(40, 40), "legacy grid_size save should migrate to a square grid_extent")
	_assert.that(clean.has("owners"), "legacy square owner grid should remain restorable")


func _start_main(extent: Vector2i):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = extent.x
	main.selected_grid_extent = extent
	main._start_game(extent, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
