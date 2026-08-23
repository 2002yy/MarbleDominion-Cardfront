extends SceneTree

const AssetRegistryScript = preload("res://scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd")
const EnvironmentBuilderScript = preload("res://scripts/cardfront/environment/CardfrontEnvironmentBuilder.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontEnvironmentAssetTest] Starting environment asset tests")
	await process_frame

	_test_registry_assets_are_loadable()
	await _test_builder_creates_presentation_only_nodes()
	await _test_cardfront_runtime_uses_imported_environment()
	await _test_ballwar_does_not_create_environment()
	_test_formal_bridge_gate_pass_validator()
	_test_role_debug_view_toggle()

	_assert.report("[CardfrontEnvironmentAssetTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_registry_assets_are_loadable() -> void:
	var ids: Array[String] = AssetRegistryScript.registered_ids()
	var kaykit_ids: Array[String] = []
	var custom_ids: Array[String] = []
	var formal_ids: Array[String] = []
	for asset_id in ids:
		if asset_id.begins_with("custom_"):
			custom_ids.append(asset_id)
		elif asset_id.begins_with("formal_"):
			formal_ids.append(asset_id)
		else:
			kaykit_ids.append(asset_id)
	_assert.eq(kaykit_ids.size(), 7, "environment registry: KayKit benchmark batch should contain seven reviewed source models")
	_assert.eq(custom_ids.size(), 10, "environment registry: custom Blender batch should contain ten building models")
	_assert.eq(formal_ids.size(), 16, "environment registry: Formal HQ (incl. hero variants), Tower, Bridge, Gate, Fortification, and Stronghold Base batches should contain sixteen imported modules")
	for asset_id in ids:
		var entry: Dictionary = AssetRegistryScript.get_entry(asset_id)
		_assert.that(not str(entry.get("path", "")).is_empty(), "%s: path should be explicit" % asset_id)
		_assert.that(not str(entry.get("fallback", "")).is_empty(), "%s: fallback should be explicit" % asset_id)
		_assert.that(AssetRegistryScript.is_available(asset_id), "%s: imported source model should exist" % asset_id)
		_assert.that(AssetRegistryScript.load_scene(asset_id) != null, "%s: source model should load as PackedScene" % asset_id)


func _test_formal_bridge_gate_pass_validator() -> void:
	var validator := CardfrontFormalAssetValidator.new()
	var bridge_result: Dictionary = validator.validate_resource_path(
		"res://assets/cardfront_environment/formal/bridge/bridge.glb",
		CardfrontFormalAssetValidator.bridge_contract()
	)
	_assert.that(
		bool(bridge_result.get("valid", false)),
		"formal bridge should pass fail-closed validator: %s" % str(bridge_result.get("errors", []))
	)
	var gate_result: Dictionary = validator.validate_resource_path(
		"res://assets/cardfront_environment/formal/gate/gate_frame.glb",
		CardfrontFormalAssetValidator.gate_frame_contract()
	)
	_assert.that(
		bool(gate_result.get("valid", false)),
		"formal gate frame should pass fail-closed validator: %s" % str(gate_result.get("errors", []))
	)
	var beacon_result: Dictionary = validator.validate_resource_path(
		"res://assets/cardfront_environment/formal/tower/tower_beacon.glb",
		CardfrontFormalAssetValidator.beacon_function_contract()
	)
	_assert.that(
		bool(beacon_result.get("valid", false)),
		"formal beacon module should pass fail-closed validator: %s" % str(beacon_result.get("errors", []))
	)
	var fort_result: Dictionary = validator.validate_resource_path(
		"res://assets/cardfront_environment/formal/fortification/fortification.glb",
		CardfrontFormalAssetValidator.fortification_contract()
	)
	_assert.that(
		bool(fort_result.get("valid", false)),
		"formal fortification should pass fail-closed validator: %s" % str(fort_result.get("errors", []))
	)
	for hero_name in ["hq_hero_rapid", "hq_hero_engineer"]:
		var hero_result: Dictionary = validator.validate_resource_path(
			"res://assets/cardfront_environment/formal/hq/%s.glb" % hero_name,
			CardfrontFormalAssetValidator.hero_module_contract()
		)
		_assert.that(
			bool(hero_result.get("valid", false)),
			"formal %s should pass fail-closed validator: %s" % [hero_name, str(hero_result.get("errors", []))]
		)
	for pad_name in ["stronghold_base_center", "stronghold_base_corner"]:
		var pad_result: Dictionary = validator.validate_resource_path(
			"res://assets/cardfront_environment/formal/stronghold_base/%s.glb" % pad_name,
			CardfrontFormalAssetValidator.stronghold_base_contract()
		)
		_assert.that(
			bool(pad_result.get("valid", false)),
			"formal %s should pass fail-closed validator: %s" % [pad_name, str(pad_result.get("errors", []))]
		)


func _test_role_debug_view_toggle() -> void:
	var view_script := load("res://scripts/cardfront/arena/CardfrontOrthographicArenaView.gd")
	if view_script == null:
		return
	var view = view_script.new()
	var root := get_root()
	root.add_child(view)
	var world := Node3D.new()
	world.name = "ArenaWorld"
	root.add_child(world)
	view.world_root = world
	var probe := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = StandardMaterial3D.new()
	(box.material as StandardMaterial3D).resource_name = "CF_METAL__FACTION_TRIM"
	probe.mesh = box
	var probe_host := Node3D.new()
	probe_host.name = "GateFrameGlb"
	world.add_child(probe_host)
	probe_host.add_child(probe)
	view.set_role_debug_visible(true)
	_assert.that(view.role_debug_active, "role debug: enable should mark active")
	var overridden := probe.get_surface_override_material(0)
	_assert.that(
		overridden != null and str(overridden.albedo_color) == str(Color(0.2, 0.8, 1.0)),
		"role debug: FACTION_TRIM surface should switch to the channel diagnostic color"
	)
	view.set_role_debug_visible(false)
	_assert.that(not view.role_debug_active, "role debug: disable should restore state")
	_assert.that(
		probe.get_surface_override_material(0) == null,
		"role debug: disable should restore the original surface material"
	)
	probe.queue_free()
	probe_host.queue_free()
	world.queue_free()
	view.queue_free()


func _test_builder_creates_presentation_only_nodes() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var builder = EnvironmentBuilderScript.new()
	_assert.that(builder.setup(root, {}), "environment builder: valid world root should be accepted")
	_assert.eq(builder.build_edge_dressing(40.0, 47.2, 1.28), 8, "environment builder: edge dressing should stay within the first-pass budget")
	builder.build_bridge_dressing(0.0, 1.28)
	builder.build_gate_foundations(0.0, 1.28)
	await process_frame
	_assert.eq(builder.get_loaded_asset_count(), 12, "environment builder: first-pass nodes should use imported models")
	_assert.eq(builder.get_fallback_count(), 0, "environment builder: complete source batch should not need fallback")
	_assert.that(builder.get_material_count() <= 3, "environment builder: first pass should share at most foliage, stone, and wood materials")
	for child in root.get_children():
		_assert.that(bool(child.get_meta("presentation_only", false)), "%s: environment nodes must remain presentation-only" % child.name)
		_assert.that(not _contains_collision(child), "%s: presentation environment must not create collision authority" % child.name)
	root.queue_free()
	await process_frame


func _test_cardfront_runtime_uses_imported_environment() -> void:
	for extent in [Vector2i(40, 40), Vector2i(50, 50), Vector2i(40, 50), Vector2i(40, 60)]:
		var label := "%dx%d" % [extent.x, extent.y]
		var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, extent)
		var view = main.runtime.orthographic_arena_view
		_assert.that(view != null, "%s: Cardfront should create the orthographic view" % label)
		_assert.eq(main.runtime.battlefield.grid_extent, extent, "%s: runtime should retain the requested extent" % label)
		_assert.gte(view.get_environment_asset_count_for_test(), 16, "%s: arena should instantiate edge, bridge, and gate assets" % label)
		_assert.eq(view.get_environment_fallback_count_for_test(), 0, "%s: imported assets should avoid primitive fallback" % label)
		_assert.gte(view.get_environment_presentation_node_count_for_test(), 16, "%s: presentation nodes should be tracked" % label)
		var metrics: Dictionary = view.get_environment_layout_metrics_for_test()
		_assert.eq(int(metrics.get("edge_count", 0)), 8, "%s: all eight edge props should be present" % label)
		_assert.eq(int(metrics.get("bridge_count", 0)), 8, "%s: both bridges should receive rails and gate foundations" % label)
		_assert.that(
			float(metrics.get("min_edge_abs_x", 0.0)) > float(extent.x) * view.ARENA_X_SCALE * 0.5,
			"%s: edge props should remain outside the playable width" % label
		)
		TestFixtures.cleanup_node(main)
		await _flush()


func _test_ballwar_does_not_create_environment() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, Vector2i(40, 60))
	_assert.eq(main.runtime.orthographic_arena_view, null, "environment runtime: BallWar should not create Cardfront environment presentation")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, extent: Vector2i):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_extent = extent
	main._start_game(extent, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame


func _contains_collision(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D:
		return true
	for child in node.get_children():
		if _contains_collision(child):
			return true
	return false
