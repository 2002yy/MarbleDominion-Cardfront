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
	_assert.eq(formal_ids.size(), 4, "environment registry: Formal HQ batch should contain four imported modules")
	for asset_id in ids:
		var entry: Dictionary = AssetRegistryScript.get_entry(asset_id)
		_assert.that(not str(entry.get("path", "")).is_empty(), "%s: path should be explicit" % asset_id)
		_assert.that(not str(entry.get("fallback", "")).is_empty(), "%s: fallback should be explicit" % asset_id)
		_assert.that(AssetRegistryScript.is_available(asset_id), "%s: imported source model should exist" % asset_id)
		_assert.that(AssetRegistryScript.load_scene(asset_id) != null, "%s: source model should load as PackedScene" % asset_id)


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
