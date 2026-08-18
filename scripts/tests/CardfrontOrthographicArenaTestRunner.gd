extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontOrthographicArenaTest] Starting orthographic arena tests")
	await process_frame

	await _test_cardfront_builds_true_3d_mirror()
	await _test_ballwar_does_not_build_3d_mirror()
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontOrthographicArenaTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_builds_true_3d_mirror() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)
	var view = main.runtime.orthographic_arena_view
	_assert.that(view != null and is_instance_valid(view), "orthographic arena: Cardfront should create the 3D mirror")
	if view == null or not is_instance_valid(view):
		TestFixtures.cleanup_node(main)
		await _flush()
		return
	_assert.that(view.world_viewport is SubViewport, "orthographic arena: presentation should render through a SubViewport")
	_assert.eq(view.viewport_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "orthographic arena: presentation must not block 2D battlefield input")
	var camera: Camera3D = view.get_camera_for_test()
	_assert.that(camera != null and camera.current, "orthographic arena: camera should be active")
	_assert.eq(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "orthographic arena: camera must be orthographic")
	_assert.eq(view.get_tile_instance_count_for_test(), 1600, "orthographic arena: every 40x40 simulation cell should have one 3D tile")
	_assert.eq(view.get_region_label_count_for_test(), 5, "orthographic arena: default map should expose five in-world stronghold labels")
	_assert.eq(view.get_stronghold_platform_count_for_test(), 5, "orthographic arena: strongholds should read as five large platforms")
	var first_region_id: int = int(main.runtime.region_map.get_controllable_region_ids()[0])
	var badge_metrics: Dictionary = view.get_region_badge_metrics_for_test(first_region_id)
	_assert.eq(int(badge_metrics.get("line_count", 0)), 1, "orthographic arena: stronghold percent should use a compact one-line badge")
	_assert.that(int(badge_metrics.get("font_size", 99)) <= 30, "orthographic arena: stronghold badge font should remain subordinate to combat")
	_assert.that(float(badge_metrics.get("pixel_size", 1.0)) <= 0.014, "orthographic arena: stronghold badge should remain subordinate to its status ring")
	_assert.that(view.get_region_badge_text_for_test(first_region_id).contains("%"), "orthographic arena: stronghold badge should keep an explicit percentage")
	_assert.eq(view.get_bridge_count_for_test(), 2, "orthographic arena: open arena should expose two clear bridge crossings")
	_assert.eq(view.get_bridge_edge_count_for_test(), 4, "orthographic arena: both bridges should carry readable raised edges")
	_assert.that(view.get_stronghold_platform_height_for_test() <= 0.20, "orthographic arena: stronghold platforms should remain low-profile presentation accents")
	_assert.gte(view.get_skyline_visual_count_for_test(), 6, "orthographic arena: map skyline should remain present behind the battlefield")
	_assert.eq(view.get_gate_count_for_test(), 2, "orthographic arena: both bridge lanes should expose a gate")
	_assert.eq(view.get_support_visual_count_for_test(), 7, "orthographic arena: every authored support_id should own one live visual")
	_assert.eq(view.get_support_presentation_update_count_for_test(), 7, "orthographic arena: initial Support presentation should update once per authored ID")
	_assert.eq(main.runtime.target_preview_layer, null, "orthographic arena: formal live runtime must not revive the legacy target preview")
	_assert.eq(view.get_deployment_zone_cell_count_for_test(), 0, "orthographic arena: deployment zone is hidden by default")
	_assert.that(not view.deployment_zone_layer.visible, "orthographic arena: empty deployment zone has no visual")
	var player_core_visual = view.support_presentation_layer.get_visual("core_player")
	_assert.that(player_core_visual != null, "orthographic arena: player Core support visual should be bound by stable ID")
	if player_core_visual != null:
		_assert.that(not player_core_visual.has_collision_nodes(), "orthographic arena: Support visuals must not enter collision authority")
	_assert.eq(view.get_gate_openness_for_test(0), 1.0, "orthographic arena: gates should default open without changing gameplay")
	_assert.that(view.set_gate_openness(0, 0.5), "orthographic arena: presentation gate should accept a normalized openness")
	_assert.eq(view.get_gate_openness_for_test(0), 0.5, "orthographic arena: presentation gate should retain its openness")
	_assert.gte(view.get_territory_boundary_count_for_test(), 160, "orthographic arena: outer edge and ownership fronts should receive bold boundaries")
	_assert.gte(view.get_arena_depth_ratio_for_test(), 1.08, "orthographic arena: visual depth should exceed width for a tall open field")
	_assert.that(view.get_camera_size_ratio_for_test() <= 1.20, "orthographic arena: playable field should fill the viewport")
	_assert.between(view.get_command_chamber_width_for_test(), 6.4, 7.2, "orthographic arena: command chambers should be primary targets without dominating the route")
	_assert.that(view.get_bridge_visual_width_for_test() <= 4.0, "orthographic arena: bridge gates should preserve combat space")
	_assert.that(view.get_edge_decoration_count_for_test() <= 8, "orthographic arena: peripheral decoration should stay subordinate")
	_assert.gte(view.get_checker_cell_span_for_test(), 4, "orthographic arena: background checker should read as broad quiet color fields")
	_assert.eq(view.get_turret_proxy_count_for_test(), 2, "orthographic arena: player and AI should each have one visual proxy")
	_assert.eq(view.get_faction_footprint_count_for_test(), 2, "orthographic arena: both command chambers should retain a faction-readable footprint")
	_assert.eq(view.get_command_chamber_module_count_for_test(CardfrontRulesScript.PLAYER_FACTION), 3, "orthographic arena: modular HQ should assemble hero, theme, and damage modules")
	var chamber_scale: Vector3 = view.get_command_chamber_model_scale_for_test(CardfrontRulesScript.PLAYER_FACTION)
	_assert.gte(chamber_scale.y, 0.60, "orthographic arena: imported command chamber silhouette should stay vertically readable")
	var background: Color = view.get_background_color_for_test()
	_assert.gte((background.r + background.g + background.b) / 3.0, 0.40, "orthographic arena: arena surround should stay bright enough for daylight readability")
	var player_color: Color = view.get_territory_color_for_test(CardfrontRulesScript.PLAYER_FACTION)
	var ai_color: Color = view.get_territory_color_for_test(CardfrontRulesScript.AI_FACTION)
	var neutral_color: Color = view.get_territory_color_for_test(CardfrontRulesScript.NEUTRAL_OWNER)
	_assert.gte(_color_distance(player_color, ai_color), 0.20, "orthographic arena: player and AI ownership tints should be visibly distinct")
	_assert.gte(_color_distance(player_color, neutral_color), 0.10, "orthographic arena: player ownership should remain distinct from grass")
	_assert.gte(_color_distance(ai_color, neutral_color), 0.10, "orthographic arena: AI ownership should remain distinct from grass")
	_assert.that(main.runtime.battlefield is Node2D, "orthographic arena: 2D Battlefield remains the authority")
	_assert.that(main.runtime.bullet_pool is Node2D, "orthographic arena: 2D BulletPool remains the authority")

	var player_turret = main.runtime.turrets.get(CardfrontRulesScript.PLAYER_FACTION, null)
	var world_position: Vector3 = view.simulation_to_world_for_test(player_turret.global_position)
	_assert.that(world_position.z > 20.0, "orthographic arena: bottom player turret should map beyond the positive-Z map edge")
	_assert.eq(view.get_sparse_claim_marker_count_for_test(), 0, "orthographic arena: connected spawn territories should not be covered in sparse markers")
	player_turret.rotation = 0.42
	view._process(0.0)
	_assert.eq(view.get_command_chamber_rotation_for_test(CardfrontRulesScript.PLAYER_FACTION), 0.0, "orthographic arena: command chamber body should stay fixed while aiming")
	_assert.that(
		absf(view.get_turret_pivot_rotation_for_test(CardfrontRulesScript.PLAYER_FACTION) + 0.42) < 0.001,
		"orthographic arena: only the turret pivot should follow the simulation aim"
	)

	var entity_runtime = main.runtime.battlefield.capture_interceptor.entity_runtime
	var repair_units: Array = entity_runtime.debug_spawn_repair_units(CardfrontRulesScript.PLAYER_FACTION, 1)
	var tower_result: Dictionary = entity_runtime.build_or_upgrade_tower(CardfrontRulesScript.PLAYER_FACTION, "interceptor_tower")
	await process_frame
	_assert.gte(view.get_entity_proxy_count_for_test(), 2, "orthographic arena: creatures and defense towers should enter the formal 3D view")
	var repair_id: String = str(repair_units[0].entity_id) if not repair_units.is_empty() else ""
	var tower = entity_runtime._find_owner_tower(CardfrontRulesScript.PLAYER_FACTION, "interceptor_tower")
	var tower_id: String = str(tower.entity_id) if tower != null else ""
	_assert.that(bool(tower_result.get("success", false)), "orthographic arena: interceptor tower fixture should build")
	_assert.eq(view.get_entity_status_text_for_test(repair_id), "", "orthographic arena: healthy entities should not carry persistent role text")
	_assert.eq(view.get_entity_status_text_for_test(tower_id), "", "orthographic arena: powered towers should not carry persistent state text")
	_assert.that(not view.get_entity_hp_visible_for_test(repair_id), "orthographic arena: full-health entity bars should stay hidden")
	_assert.gte(view.get_entity_visual_scale_for_test(repair_id), 1.45, "orthographic arena: combat creatures should receive the readability scale")
	_assert.gte(view.get_entity_visual_scale_for_test(tower_id), 1.45, "orthographic arena: defense towers should receive the readability scale")
	repair_units[0].max_hp = maxi(2, int(repair_units[0].hp) + 1)
	view._process(0.0)
	_assert.that(view.get_entity_hp_visible_for_test(repair_id), "orthographic arena: damaged entities should reveal their HP bar")
	_assert.that(view.get_entity_hp_scale_for_test(repair_id) > 0.0, "orthographic arena: damaged entity should retain a faction-colored HP fill")
	_assert.that(not view.get_chamber_health_label_visible_for_test(CardfrontRulesScript.PLAYER_FACTION), "orthographic arena: full-health chamber text should defer to the top HUD")

	var standard_spec: Dictionary = view.get_projectile_spec_for_test(ProjectileTypeScript.STANDARD, CardfrontRulesScript.PLAYER_FACTION)
	var siege_spec: Dictionary = view.get_projectile_spec_for_test(ProjectileTypeScript.SIEGE, CardfrontRulesScript.PLAYER_FACTION)
	var suppression_spec: Dictionary = view.get_projectile_spec_for_test(ProjectileTypeScript.SUPPRESSION, CardfrontRulesScript.PLAYER_FACTION)
	_assert.gte(view.get_projectile_visual_scale_for_test(), 1.40, "orthographic arena: projectile cores and trails should remain readable at desktop scale")
	_assert.that(float(siege_spec.get("radius", 0.0)) > float(standard_spec.get("radius", 0.0)), "orthographic arena: siege projectile should read heavier than standard")
	_assert.that(float(suppression_spec.get("trail_length", 0.0)) > float(standard_spec.get("trail_length", 0.0)), "orthographic arena: suppression projectile should carry the longest trail")
	_assert.gte(
		_color_distance(standard_spec.get("color", Color.WHITE), siege_spec.get("color", Color.WHITE)),
		0.18,
		"orthographic arena: standard and siege projectile colors should be distinct"
	)
	_assert.gte(
		_color_distance(siege_spec.get("color", Color.WHITE), suppression_spec.get("color", Color.WHITE)),
		0.18,
		"orthographic arena: siege and suppression projectile colors should be distinct"
	)
	entity_runtime.entity_contact_resolved.emit({
		"cell": Vector2i(20, 20),
		"projectile_type": ProjectileTypeScript.SIEGE,
	})
	_assert.gte(view.get_combat_effect_count_for_test(), 1, "orthographic arena: projectile contact should create a visible battlefield pulse")

	var isolated_cell := Vector2i(20, 20)
	main.runtime.battlefield.owners[isolated_cell.x][isolated_cell.y] = CardfrontRulesScript.PLAYER_FACTION
	view.mark_tiles_dirty()
	await process_frame
	_assert.eq(view.get_sparse_claim_marker_count_for_test(), 1, "orthographic arena: an isolated captured cell should receive one faction marker")

	main.runtime.bullet_pool.spawn_bullet(
		CardfrontRulesScript.PLAYER_FACTION,
		player_turret.global_position,
		Vector2.UP,
		main.runtime.battlefield,
		main.runtime.turrets
	)
	await process_frame
	_assert.gte(view.get_bullet_proxy_count_for_test(), 1, "orthographic arena: active 2D bullets should receive reusable 3D proxies")

	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_does_not_build_3d_mirror() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)
	_assert.eq(main.runtime.orthographic_arena_view, null, "orthographic arena: BallWar must not create the Cardfront 3D mirror")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, grid_size: int):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	# Main loads persisted menu preferences in _ready(); this runner asserts the
	# frozen default arena and must not inherit the developer's last map choice.
	main.selected_cardfront_map_id = MapRegistryScript.DEFAULT_DUEL_MAP_ID
	main._start_game(grid_size, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame


func _color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))
