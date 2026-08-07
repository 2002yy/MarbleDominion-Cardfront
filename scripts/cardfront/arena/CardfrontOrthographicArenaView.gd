extends CanvasLayer
class_name CardfrontOrthographicArenaView

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const CombatReadabilityScript = preload("res://scripts/cardfront/arena/CardfrontCombatReadabilityProfile.gd")
const EnvironmentBuilderScript = preload("res://scripts/cardfront/environment/CardfrontEnvironmentBuilder.gd")

const CANVAS_LAYER: int = 4
const MAX_BULLET_PROXIES: int = 256
const TILE_GAP: float = 0.012
const TILE_HEIGHT: float = 0.16
const ARENA_X_SCALE: float = 1.18
const ARENA_Z_SCALE: float = 1.28
const OUTER_FLOOR_WIDTH_PADDING: float = 32.0
const CHECKER_CELL_SPAN: int = 5
const BRIDGE_COUNT: int = 2
const COMMAND_CHAMBER_SIZE: Vector3 = Vector3(6.8, 0.84, 4.0)
const BRIDGE_BASE_WIDTH: float = 3.8
const EDGE_DECORATION_COUNT: int = 4
const GRASS_LIGHT: Color = Color(0.48, 0.60, 0.52)
const GRASS_DARK: Color = Color(0.45, 0.56, 0.49)
const PLAYER_TINT: Color = Color(0.18, 0.46, 0.58)
const AI_TINT: Color = Color(0.58, 0.26, 0.26)
const OUTLINE_COLOR: Color = Color(0.10, 0.18, 0.17)
const PATH_COLOR: Color = Color(0.56, 0.44, 0.32, 0.62)
const PRESENTATION_SCALE_PRESETS: Array[float] = [1.0, 1.12, 1.20]
const DEFAULT_PRESENTATION_SCALE: float = 1.20
const SCALE_TWEEN_SECONDS: float = 0.18
const COMBAT_ENTITY_VISUAL_SCALE: float = 1.48
const PROJECTILE_VISUAL_SCALE: float = 1.45

var battlefield = null
var region_map = null
var bullet_pool = null
var turrets: Dictionary = {}
var layout: Dictionary = {}
var map_id: String = "default_duel"
var entity_runtime = null

var viewport_container: SubViewportContainer
var world_viewport: SubViewport
var world_root: Node3D
var camera: Camera3D
var arena_environment: Environment
var tile_multimesh: MultiMeshInstance3D
var territory_boundary_multimesh: MultiMeshInstance3D
var sparse_claim_multimesh: MultiMeshInstance3D
var aim_mesh_instance: MeshInstance3D

var _turret_proxies: Dictionary = {}
var _turret_barrels: Dictionary = {}
var _chamber_labels: Dictionary = {}
var _region_labels: Dictionary = {}
var _region_platforms: Dictionary = {}
var _region_control_rings: Dictionary = {}
var _region_badge_plates: Dictionary = {}
var _region_label_tweens: Dictionary = {}
var _last_region_leaders: Dictionary = {}
var _labels_force_visible: bool = false
const LABEL_FADE_DURATION: float = 0.35
const LABEL_AUTO_HIDE_DELAY: float = 2.8
const LABEL_CHANGE_THRESHOLD: int = 10
var _bridge_tops: Array[MeshInstance3D] = []
var _gate_bars: Array[MeshInstance3D] = []
var _gate_labels: Array[Label3D] = []
var _gate_openness: Array[float] = []
var _gate_states: Array[Dictionary] = []
var _bullet_proxies: Array[MeshInstance3D] = []
var _entity_proxies: Dictionary = {}
var _entity_sprites: Dictionary = {}
var _entity_hp_fills: Dictionary = {}
var _entity_status_labels: Dictionary = {}
var _bullet_meshes: Dictionary = {}
var _bullet_trails: Dictionary = {}
var _combat_effects: Array = []
var _faction_materials: Dictionary = {}
var _aim_mesh := ImmediateMesh.new()
var _aim_material: StandardMaterial3D
var _tiles_dirty: bool = true
var _base_camera_size: float = 0.0
var _z_scale: float = ARENA_Z_SCALE
var _presentation_scale: float = DEFAULT_PRESENTATION_SCALE
var _camera_scale_tween: Tween
var _environment_builder = null


func _init() -> void:
	name = "CardfrontOrthographicArenaView"
	layer = CANVAS_LAYER
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(new_battlefield, new_region_map, new_bullet_pool, new_turrets: Dictionary, new_layout: Dictionary) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	if new_region_map == null or new_region_map.grid_extent != new_battlefield.grid_extent:
		return false
	var arena_view_rect: Rect2 = new_layout.get("arena_view_rect", new_layout.get("battlefield_rect", Rect2()))
	if arena_view_rect.size.x <= 0.0 or arena_view_rect.size.y <= 0.0:
		return false

	battlefield = new_battlefield
	region_map = new_region_map
	_z_scale = _resolve_z_scale(battlefield.grid_extent)
	bullet_pool = new_bullet_pool
	turrets = new_turrets.duplicate(false)
	layout = new_layout.duplicate(true)
	map_id = str(layout.get("map_id", "default_duel"))
	_build_viewport(arena_view_rect)
	_build_world()
	_build_tiles()
	_build_territory_boundaries()
	_build_sparse_claim_markers()
	_build_stronghold_platforms()
	_build_region_labels()
	_build_combatant_proxies()
	_build_aim_guide()

	var score_callable := Callable(self, "mark_tiles_dirty")
	if battlefield.has_signal("scores_changed") and not battlefield.scores_changed.is_connected(score_callable):
		battlefield.scores_changed.connect(score_callable)
	mark_tiles_dirty()
	set_process(true)
	return true


func mark_tiles_dirty(_counts: Dictionary = {}) -> void:
	_tiles_dirty = true


func set_entity_runtime(new_entity_runtime) -> void:
	_disconnect_entity_runtime()
	entity_runtime = new_entity_runtime
	_connect_entity_runtime()
	_sync_entities()


func get_camera_for_test() -> Camera3D:
	return camera


func get_tile_instance_count_for_test() -> int:
	if tile_multimesh == null or tile_multimesh.multimesh == null:
		return 0
	return tile_multimesh.multimesh.instance_count


func get_turret_proxy_count_for_test() -> int:
	return _turret_proxies.size()


func get_region_label_count_for_test() -> int:
	return _region_labels.size()


func get_stronghold_platform_count_for_test() -> int:
	return _region_platforms.size()


func get_bridge_count_for_test() -> int:
	return _bridge_tops.size()


func get_gate_count_for_test() -> int:
	return _gate_bars.size()


func get_gate_openness_for_test(lane_index: int) -> float:
	if lane_index < 0 or lane_index >= _gate_openness.size():
		return -1.0
	return _gate_openness[lane_index]


func set_gate_openness(lane_index: int, openness: float) -> bool:
	if lane_index < 0 or lane_index >= _gate_bars.size():
		return false
	_gate_openness[lane_index] = clampf(openness, 0.0, 1.0)
	if lane_index < _gate_states.size():
		_gate_states[lane_index]["openness"] = _gate_openness[lane_index]
	_refresh_gate_visual(lane_index)
	return true


func set_gate_state(lane_index: int, state: Dictionary) -> bool:
	if lane_index < 0 or lane_index >= _gate_bars.size():
		return false
	_gate_states[lane_index] = state.duplicate(true)
	_gate_openness[lane_index] = clampf(float(state.get("openness", 1.0)), 0.0, 1.0)
	_refresh_gate_visual(lane_index)
	return true


func get_gate_state_for_test(lane_index: int) -> Dictionary:
	if lane_index < 0 or lane_index >= _gate_states.size():
		return {}
	return _gate_states[lane_index].duplicate(true)


func get_territory_boundary_count_for_test() -> int:
	if territory_boundary_multimesh == null or territory_boundary_multimesh.multimesh == null:
		return 0
	return territory_boundary_multimesh.multimesh.visible_instance_count


func get_sparse_claim_marker_count_for_test() -> int:
	if sparse_claim_multimesh == null or sparse_claim_multimesh.multimesh == null:
		return 0
	return sparse_claim_multimesh.multimesh.visible_instance_count


func get_arena_depth_ratio_for_test() -> float:
	var extent: Vector2i = battlefield.grid_extent
	return (float(extent.y) * _z_scale) / (float(extent.x) * ARENA_X_SCALE)


func get_z_scale_for_test() -> float:
	return _z_scale


func get_checker_cell_span_for_test() -> int:
	return CHECKER_CELL_SPAN


func get_bullet_proxy_count_for_test() -> int:
	return _bullet_proxies.size()


func get_entity_proxy_count_for_test() -> int:
	return _entity_proxies.size()


func get_projectile_spec_for_test(projectile_type: String, owner_id: int) -> Dictionary:
	return CombatReadabilityScript.projectile_spec(
		projectile_type,
		_arena_faction_color(owner_id)
	).duplicate(true)


func get_projectile_visual_scale_for_test() -> float:
	return PROJECTILE_VISUAL_SCALE


func get_combat_effect_count_for_test() -> int:
	return _combat_effects.size()


func get_command_chamber_rotation_for_test(owner_id: int) -> float:
	var proxy: Node3D = _turret_proxies.get(owner_id, null)
	return proxy.rotation.y if proxy != null and is_instance_valid(proxy) else INF


func get_turret_pivot_rotation_for_test(owner_id: int) -> float:
	var pivot: Node3D = _turret_barrels.get(owner_id, null)
	return pivot.rotation.y if pivot != null and is_instance_valid(pivot) else INF


func get_entity_status_text_for_test(entity_id: String) -> String:
	var status: Label3D = _entity_status_labels.get(entity_id, null)
	return status.text if status != null and is_instance_valid(status) else ""


func get_entity_hp_scale_for_test(entity_id: String) -> float:
	var fill: MeshInstance3D = _entity_hp_fills.get(entity_id, null)
	return fill.scale.x if fill != null and is_instance_valid(fill) else -1.0


func get_entity_hp_visible_for_test(entity_id: String) -> bool:
	var fill: MeshInstance3D = _entity_hp_fills.get(entity_id, null)
	return fill != null and is_instance_valid(fill) and fill.visible


func get_entity_visual_scale_for_test(entity_id: String) -> float:
	var proxy: Node3D = _entity_proxies.get(entity_id, null)
	return proxy.scale.x if proxy != null and is_instance_valid(proxy) else -1.0


func get_chamber_health_label_visible_for_test(owner_id: int) -> bool:
	var label: Label3D = _chamber_labels.get(owner_id, null)
	return label != null and is_instance_valid(label) and label.visible


func get_camera_size_ratio_for_test() -> float:
	return camera.size / float(maxi(battlefield.grid_extent.x, battlefield.grid_extent.y)) if camera != null else INF


func get_presentation_scale() -> float:
	return _presentation_scale


func get_presentation_scale_presets() -> Array[float]:
	return PRESENTATION_SCALE_PRESETS.duplicate()


func set_presentation_scale(requested_scale: float, animated: bool = true) -> float:
	var resolved_scale: float = _nearest_presentation_scale(requested_scale)
	_presentation_scale = resolved_scale
	if camera == null or _base_camera_size <= 0.0:
		return _presentation_scale
	var target_size: float = _base_camera_size / _presentation_scale
	if _camera_scale_tween != null and _camera_scale_tween.is_valid():
		_camera_scale_tween.kill()
	if animated and is_inside_tree():
		_camera_scale_tween = create_tween()
		_camera_scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_camera_scale_tween.set_trans(Tween.TRANS_QUAD)
		_camera_scale_tween.set_ease(Tween.EASE_OUT)
		_camera_scale_tween.tween_property(camera, "size", target_size, SCALE_TWEEN_SECONDS)
	else:
		camera.size = target_size
	return _presentation_scale


func step_presentation_scale(direction: int, animated: bool = true) -> float:
	var current_index: int = PRESENTATION_SCALE_PRESETS.find(_nearest_presentation_scale(_presentation_scale))
	var next_index: int = clampi(current_index + signi(direction), 0, PRESENTATION_SCALE_PRESETS.size() - 1)
	return set_presentation_scale(PRESENTATION_SCALE_PRESETS[next_index], animated)


func get_region_badge_text_for_test(region_id: int) -> String:
	var label: Label3D = _region_labels.get(region_id, null)
	return label.text if label != null and is_instance_valid(label) else ""


func get_region_badge_metrics_for_test(region_id: int) -> Dictionary:
	var label: Label3D = _region_labels.get(region_id, null)
	if label == null or not is_instance_valid(label):
		return {}
	return {
		"font_size": label.font_size,
		"pixel_size": label.pixel_size,
		"line_count": label.text.count("\n") + 1,
	}


func get_command_chamber_width_for_test() -> float:
	return COMMAND_CHAMBER_SIZE.x


func get_bridge_visual_width_for_test() -> float:
	return BRIDGE_BASE_WIDTH


func get_edge_decoration_count_for_test() -> int:
	return EDGE_DECORATION_COUNT


func get_environment_asset_count_for_test() -> int:
	if _environment_builder == null:
		return 0
	return _environment_builder.get_loaded_asset_count()


func get_environment_fallback_count_for_test() -> int:
	if _environment_builder == null:
		return 0
	return _environment_builder.get_fallback_count()


func get_environment_presentation_node_count_for_test() -> int:
	if _environment_builder == null:
		return 0
	return _environment_builder.get_created_count()


func get_environment_layout_metrics_for_test() -> Dictionary:
	if _environment_builder == null:
		return {}
	return _environment_builder.get_layout_metrics()


func get_background_color_for_test() -> Color:
	return arena_environment.background_color if arena_environment != null else Color.BLACK


func get_territory_color_for_test(owner_id: int, cell: Vector2i = Vector2i.ZERO) -> Color:
	return _tile_color(owner_id, RegionTypeScript.NORMAL, cell)


func simulation_to_world_for_test(simulation_position: Vector2, height: float = 0.0) -> Vector3:
	return _simulation_to_world(simulation_position, height)


func _process(delta: float) -> void:
	if battlefield == null or not is_instance_valid(battlefield):
		visible = false
		set_process(false)
		return
	if _tiles_dirty:
		_refresh_tile_colors()
		_tiles_dirty = false
	_sync_turrets()
	_sync_bullets()
	_sync_entities()
	_update_combat_effects(delta)
	_sync_aim_guide()


func _build_viewport(arena_view_rect: Rect2) -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "ArenaViewportContainer"
	viewport_container.position = arena_view_rect.position
	viewport_container.size = arena_view_rect.size
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	add_child(viewport_container)

	world_viewport = SubViewport.new()
	world_viewport.name = "ArenaSubViewport"
	world_viewport.size = Vector2i(maxi(1, roundi(arena_view_rect.size.x)), maxi(1, roundi(arena_view_rect.size.y)))
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.gui_disable_input = true
	viewport_container.add_child(world_viewport)


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "ArenaWorld"
	world_viewport.add_child(world_root)

	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	arena_environment = Environment.new()
	arena_environment.background_mode = Environment.BG_COLOR
	arena_environment.background_color = _theme_color("backdrop")
	arena_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	arena_environment.ambient_light_color = Color(0.94, 0.95, 0.84)
	arena_environment.ambient_light_energy = 0.94
	environment_node.environment = arena_environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color(1.0, 0.96, 0.84)
	key_light.light_energy = 1.30
	key_light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	key_light.shadow_enabled = false
	world_root.add_child(key_light)

	var width: float = float(battlefield.grid_extent.x)
	var height: float = float(battlefield.grid_extent.y)
	var arena_width: float = width * ARENA_X_SCALE
	var arena_depth: float = height * _z_scale
	var outer_floor := MeshInstance3D.new()
	outer_floor.name = "ArenaGroundBase"
	var outer_box := BoxMesh.new()
	outer_box.size = Vector3(arena_width + OUTER_FLOOR_WIDTH_PADDING, 0.56, arena_depth + 8.0)
	outer_floor.mesh = outer_box
	outer_floor.position.y = -0.48
	outer_floor.material_override = _make_material(_theme_color("outer"), 0.0)
	world_root.add_child(outer_floor)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "ArenaFloor"
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(arena_width + 3.5, 0.38, arena_depth + 3.5)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.24
	floor_mesh.material_override = _make_material(_theme_color("ground"), 0.0)
	world_root.add_child(floor_mesh)
	_environment_builder = EnvironmentBuilderScript.new()
	_environment_builder.setup(world_root, {
		"foliage": _theme_color("foliage_a"),
		"stone": Color(0.49, 0.50, 0.45),
		"wood": Color(0.49, 0.35, 0.24),
	})
	_build_lane_paths(width, height)
	_build_edge_landscape(height, arena_width)
	_build_map_landmarks(height, arena_width)
	_build_river_and_bridges(width, arena_width)

	camera = Camera3D.new()
	camera.name = "OrthographicCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_base_camera_size = maxf(width, height) * 1.18
	camera.size = _base_camera_size / DEFAULT_PRESENTATION_SCALE
	camera.near = 0.1
	camera.far = maxf(width, height) * 5.0
	camera.look_at_from_position(
		Vector3(0.0, height * 1.30, arena_depth * 0.76),
		Vector3(0.0, 0.0, -0.5),
		Vector3.UP
	)
	camera.current = true
	world_root.add_child(camera)


func _build_tiles() -> void:
	tile_multimesh = MultiMeshInstance3D.new()
	tile_multimesh.name = "TerritoryTiles"
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(ARENA_X_SCALE - TILE_GAP, TILE_HEIGHT, _z_scale - TILE_GAP)
	var tile_material := StandardMaterial3D.new()
	tile_material.vertex_color_use_as_albedo = true
	tile_material.roughness = 0.72
	tile_material.metallic = 0.06
	tile_mesh.material = tile_material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = tile_mesh
	multimesh.instance_count = battlefield.grid_extent.x * battlefield.grid_extent.y
	tile_multimesh.multimesh = multimesh
	world_root.add_child(tile_multimesh)

	var extent: Vector2i = battlefield.grid_extent
	for x in range(extent.x):
		for y in range(extent.y):
			var index: int = x * extent.y + y
			var transform := Transform3D(Basis.IDENTITY, Vector3(
				(float(x) + 0.5 - float(extent.x) * 0.5) * ARENA_X_SCALE,
				TILE_HEIGHT * 0.5,
				(float(y) + 0.5 - float(extent.y) * 0.5) * _z_scale
			))
			multimesh.set_instance_transform(index, transform)


func _build_territory_boundaries() -> void:
	territory_boundary_multimesh = MultiMeshInstance3D.new()
	territory_boundary_multimesh.name = "TerritoryBoundaries"
	var boundary_mesh := BoxMesh.new()
	boundary_mesh.size = Vector3.ONE
	boundary_mesh.material = _make_material(OUTLINE_COLOR, 0.0)

	var extent: Vector2i = battlefield.grid_extent
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = boundary_mesh
	multimesh.instance_count = 2 * extent.x * extent.y + extent.x + extent.y
	multimesh.visible_instance_count = 0
	territory_boundary_multimesh.multimesh = multimesh
	world_root.add_child(territory_boundary_multimesh)


func _refresh_territory_boundaries() -> void:
	if territory_boundary_multimesh == null or territory_boundary_multimesh.multimesh == null:
		return
	var extent: Vector2i = battlefield.grid_extent
	var index: int = 0
	var x_thickness: float = 0.36
	var z_thickness: float = 0.30
	var boundary_height: float = 0.24
	var boundary_y: float = TILE_HEIGHT + boundary_height * 0.5

	for x in range(extent.x):
		index = _set_boundary_instance(
			index,
			Vector3((float(x) + 0.5 - float(extent.x) * 0.5) * ARENA_X_SCALE, boundary_y, -float(extent.y) * 0.5 * _z_scale),
			Vector3(ARENA_X_SCALE + x_thickness, boundary_height, z_thickness)
		)
		index = _set_boundary_instance(
			index,
			Vector3((float(x) + 0.5 - float(extent.x) * 0.5) * ARENA_X_SCALE, boundary_y, float(extent.y) * 0.5 * _z_scale),
			Vector3(ARENA_X_SCALE + x_thickness, boundary_height, z_thickness)
		)
	for y in range(extent.y):
		index = _set_boundary_instance(
			index,
			Vector3(-float(extent.x) * 0.5 * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(extent.y) * 0.5) * _z_scale),
			Vector3(x_thickness, boundary_height, _z_scale + z_thickness)
		)
		index = _set_boundary_instance(
			index,
			Vector3(float(extent.x) * 0.5 * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(extent.y) * 0.5) * _z_scale),
			Vector3(x_thickness, boundary_height, _z_scale + z_thickness)
		)

	for x in range(extent.x):
		for y in range(extent.y):
			var owner_id: int = int(battlefield.owners[x][y])
			if x + 1 < extent.x and int(battlefield.owners[x + 1][y]) != owner_id:
				index = _set_boundary_instance(
					index,
					Vector3((float(x) + 1.0 - float(extent.x) * 0.5) * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(extent.y) * 0.5) * _z_scale),
					Vector3(x_thickness, boundary_height, _z_scale + z_thickness)
				)
			if y + 1 < extent.y and int(battlefield.owners[x][y + 1]) != owner_id:
				index = _set_boundary_instance(
					index,
					Vector3((float(x) + 0.5 - float(extent.x) * 0.5) * ARENA_X_SCALE, boundary_y, (float(y) + 1.0 - float(extent.y) * 0.5) * _z_scale),
					Vector3(ARENA_X_SCALE + x_thickness, boundary_height, z_thickness)
				)
	territory_boundary_multimesh.multimesh.visible_instance_count = index


func _build_sparse_claim_markers() -> void:
	sparse_claim_multimesh = MultiMeshInstance3D.new()
	sparse_claim_multimesh.name = "SparseClaimMarkers"
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3.ONE
	var marker_material := StandardMaterial3D.new()
	marker_material.vertex_color_use_as_albedo = true
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.roughness = 0.54
	marker_material.metallic = 0.08
	marker_mesh.material = marker_material

	var extent: Vector2i = battlefield.grid_extent
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = marker_mesh
	multimesh.instance_count = extent.x * extent.y
	multimesh.visible_instance_count = 0
	sparse_claim_multimesh.multimesh = multimesh
	world_root.add_child(sparse_claim_multimesh)


func _refresh_sparse_claim_markers() -> void:
	if sparse_claim_multimesh == null or sparse_claim_multimesh.multimesh == null:
		return
	var extent: Vector2i = battlefield.grid_extent
	var marker_index: int = 0
	for x in range(extent.x):
		for y in range(extent.y):
			var owner_id: int = int(battlefield.owners[x][y])
			if owner_id == CardfrontRulesScript.NEUTRAL_OWNER:
				continue
			var cell := Vector2i(x, y)
			if _same_owner_neighbor_count(cell, owner_id, extent) > 1:
				continue
			var center := Vector3(
				(float(x) + 0.5 - float(extent.x) * 0.5) * ARENA_X_SCALE,
				TILE_HEIGHT + 0.25,
				(float(y) + 0.5 - float(extent.y) * 0.5) * _z_scale
			)
			var basis := Basis(Vector3.UP, PI * 0.25).scaled(Vector3(0.62, 0.18, 0.62))
			sparse_claim_multimesh.multimesh.set_instance_transform(marker_index, Transform3D(basis, center))
			sparse_claim_multimesh.multimesh.set_instance_color(
				marker_index,
				_arena_faction_color(owner_id).lightened(0.24)
			)
			marker_index += 1
	sparse_claim_multimesh.multimesh.visible_instance_count = marker_index


func _same_owner_neighbor_count(cell: Vector2i, owner_id: int, extent: Vector2i) -> int:
	var count: int = 0
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + direction
		if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= extent.x or neighbor.y >= extent.y:
			continue
		if int(battlefield.owners[neighbor.x][neighbor.y]) == owner_id:
			count += 1
	return count


func _set_boundary_instance(index: int, center: Vector3, size: Vector3) -> int:
	var transform := Transform3D(Basis.IDENTITY.scaled(size), center)
	territory_boundary_multimesh.multimesh.set_instance_transform(index, transform)
	return index + 1


func _build_lane_paths(width: float, height: float) -> void:
	var lane_offset: float = width * 0.235 * ARENA_X_SCALE
	for lane_x in [-lane_offset, lane_offset]:
		var lane := MeshInstance3D.new()
		lane.name = "ArenaLane"
		var lane_mesh := BoxMesh.new()
		lane_mesh.size = Vector3(3.0, 0.10, (height - 3.0) * _z_scale)
		lane.mesh = lane_mesh
		lane.position = Vector3(lane_x, TILE_HEIGHT + 0.035, 0.0)
		lane.material_override = _make_material(_theme_color("path"), 0.0)
		world_root.add_child(lane)


func _build_edge_landscape(height: float, arena_width: float) -> void:
	if _environment_builder != null:
		var built_count: int = _environment_builder.build_edge_dressing(height, arena_width, _z_scale)
		if built_count > 0:
			return
	var z_positions: Array[float] = [-0.28, 0.28]
	for side in [-1.0, 1.0]:
		for index in range(z_positions.size()):
			var bush := MeshInstance3D.new()
			bush.name = "EdgeBush"
			var bush_mesh := SphereMesh.new()
			bush_mesh.radius = 0.82
			bush_mesh.height = 1.42
			bush_mesh.radial_segments = 10
			bush_mesh.rings = 5
			bush.mesh = bush_mesh
			bush.position = Vector3(
				side * (arena_width * 0.5 + 2.4 + float(index % 2) * 0.25),
				0.64,
				height * z_positions[index] * _z_scale
			)
			bush.scale = Vector3(1.05, 0.90 + float(index % 2) * 0.08, 0.94)
			var bush_color: Color = _theme_color("foliage_a") if index % 2 == 0 else _theme_color("foliage_b")
			bush.material_override = _make_material(bush_color, 0.0)
			world_root.add_child(bush)
			var trunk := MeshInstance3D.new()
			trunk.name = "EdgeTreeTrunk"
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.16
			trunk_mesh.bottom_radius = 0.24
			trunk_mesh.height = 1.02
			trunk_mesh.radial_segments = 7
			trunk.mesh = trunk_mesh
			trunk.position = bush.position - Vector3(0.0, 0.62, 0.0)
			trunk.material_override = _make_material(Color(0.38, 0.25, 0.13), 0.0)
			world_root.add_child(trunk)


func _build_map_landmarks(height: float, arena_width: float) -> void:
	match map_id:
		"central_lab":
			for side in [-1.0, 1.0]:
				for z_ratio in [-0.25, 0.25]:
					_add_landmark_pylon(
						Vector3(side * (arena_width * 0.5 + 2.2), 1.8, height * z_ratio * _z_scale),
						Color(0.64, 0.48, 0.86)
					)
		"cross_resource":
			for side in [-1.0, 1.0]:
				for z_ratio in [-0.31, 0.31]:
					_add_factory_stack(
						Vector3(side * (arena_width * 0.5 + 2.4), 0.0, height * z_ratio * _z_scale)
					)
		_:
			pass


func _add_landmark_pylon(position_value: Vector3, color: Color) -> void:
	var base := MeshInstance3D.new()
	base.name = "LabPylon"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.82
	mesh.bottom_radius = 1.20
	mesh.height = 3.8
	mesh.radial_segments = 8
	base.mesh = mesh
	base.position = position_value
	base.material_override = _make_material(color.darkened(0.18), 0.08)
	world_root.add_child(base)
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.78
	orb_mesh.height = 1.56
	orb.mesh = orb_mesh
	orb.position = position_value + Vector3(0.0, 2.35, 0.0)
	orb.material_override = _make_material(color.lightened(0.15), 0.42)
	world_root.add_child(orb)


func _add_factory_stack(position_value: Vector3) -> void:
	for offset in [-0.75, 0.75]:
		var stack := MeshInstance3D.new()
		stack.name = "FactoryStack"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.46
		mesh.bottom_radius = 0.72
		mesh.height = 4.6 if offset < 0.0 else 3.7
		mesh.radial_segments = 8
		stack.mesh = mesh
		stack.position = position_value + Vector3(offset, mesh.height * 0.5, 0.0)
		stack.material_override = _make_material(Color(0.37, 0.40, 0.38), 0.0)
		world_root.add_child(stack)


func _add_banner(position_value: Vector3, color: Color) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "ArenaBannerPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.12
	pole_mesh.bottom_radius = 0.16
	pole_mesh.height = 4.8
	pole.mesh = pole_mesh
	pole.position = position_value + Vector3(0.0, 2.4, 0.0)
	pole.material_override = _make_material(Color(0.24, 0.28, 0.23), 0.0)
	world_root.add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(1.8, 1.1, 0.10)
	flag.mesh = flag_mesh
	flag.position = position_value + Vector3(0.8, 3.75, 0.0)
	flag.material_override = _make_material(color, 0.08)
	world_root.add_child(flag)


func _build_river_and_bridges(width: float, arena_width: float) -> void:
	var river := MeshInstance3D.new()
	river.name = "CentralRiver"
	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(arena_width + 3.5, 0.13, 2.0 * _z_scale)
	river.mesh = river_mesh
	river.position.y = 0.13
	river.material_override = _make_material(Color(0.20, 0.58, 0.68), 0.10)
	world_root.add_child(river)

	for bank_z in [-1.18 * _z_scale, 1.18 * _z_scale]:
		var bank := MeshInstance3D.new()
		bank.name = "RiverBank"
		var bank_mesh := BoxMesh.new()
		bank_mesh.size = Vector3(arena_width + 3.5, 0.20, 0.36 * _z_scale)
		bank.mesh = bank_mesh
		bank.position = Vector3(0.0, 0.18, bank_z)
		bank.material_override = _make_material(Color(0.30, 0.40, 0.23), 0.0)
		world_root.add_child(bank)
		for stone_index in range(7):
			var stone := MeshInstance3D.new()
			stone.name = "RiverBankStone"
			var stone_mesh := CylinderMesh.new()
			stone_mesh.top_radius = 0.38 + float(stone_index % 3) * 0.05
			stone_mesh.bottom_radius = 0.44 + float(stone_index % 2) * 0.05
			stone_mesh.height = 0.24
			stone_mesh.radial_segments = 7
			stone.mesh = stone_mesh
			stone.position = Vector3(
				lerpf(-arena_width * 0.48, arena_width * 0.48, float(stone_index) / 6.0),
				0.36,
				bank_z
			)
			stone.rotation.y = float(stone_index % 4) * 0.31
			stone.material_override = _make_material(
				Color(0.54, 0.56, 0.48) if stone_index % 2 == 0 else Color(0.45, 0.49, 0.42),
				0.0
			)
			world_root.add_child(stone)

	var bridge_offset: float = width * 0.235 * ARENA_X_SCALE
	var bridge_positions: Array[float] = [-bridge_offset, bridge_offset]
	for bridge_index in range(BRIDGE_COUNT):
		var bridge_x: float = bridge_positions[bridge_index]
		var bridge_base := MeshInstance3D.new()
		bridge_base.name = "BridgeBase"
		var bridge_base_mesh := BoxMesh.new()
		bridge_base_mesh.size = Vector3(BRIDGE_BASE_WIDTH, 0.38, 3.0 * _z_scale)
		bridge_base.mesh = bridge_base_mesh
		bridge_base.position = Vector3(bridge_x, 0.31, 0.0)
		bridge_base.material_override = _make_material(Color(0.27, 0.25, 0.20), 0.0)
		world_root.add_child(bridge_base)

		var bridge_top := MeshInstance3D.new()
		bridge_top.name = "BridgeTop"
		var bridge_top_mesh := BoxMesh.new()
		bridge_top_mesh.size = Vector3(3.4, 0.24, 2.65 * _z_scale)
		bridge_top.mesh = bridge_top_mesh
		bridge_top.position = Vector3(bridge_x, 0.62, 0.0)
		bridge_top.material_override = _make_material(Color(0.62, 0.43, 0.24), 0.0)
		world_root.add_child(bridge_top)
		_bridge_tops.append(bridge_top)
		if _environment_builder != null:
			_environment_builder.build_bridge_dressing(bridge_x, _z_scale)
			_environment_builder.build_gate_foundations(bridge_x, _z_scale)
		_build_gate_visual(bridge_x)


func _build_gate_visual(bridge_x: float) -> void:
	for post_offset in [-1.72, 1.72]:
		var post := MeshInstance3D.new()
		post.name = "GatePost"
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.38, 1.42, 0.52 * _z_scale)
		post.mesh = post_mesh
		post.position = Vector3(bridge_x + post_offset, 1.08, 0.0)
		post.material_override = _make_material(Color(0.24, 0.32, 0.31), 0.0)
		world_root.add_child(post)

		var cap := MeshInstance3D.new()
		cap.name = "GatePostCap"
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(0.54, 0.24, 0.68 * _z_scale)
		cap.mesh = cap_mesh
		cap.position = Vector3(bridge_x + post_offset, 1.88, 0.0)
		cap.material_override = _make_material(Color(1.0, 0.72, 0.20), 0.08)
		world_root.add_child(cap)

	var bar := MeshInstance3D.new()
	bar.name = "GateBar"
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(3.34, 0.30, 0.34 * _z_scale)
	bar.mesh = bar_mesh
	bar.material_override = _make_material(Color(0.95, 0.30, 0.26), 0.08)
	world_root.add_child(bar)
	_gate_bars.append(bar)
	_gate_openness.append(1.0)
	_gate_states.append({
		"state": "open",
		"owner_id": CardfrontRulesScript.NEUTRAL_OWNER,
		"control_percent": 0,
		"openness": 1.0,
	})

	var label := Label3D.new()
	label.name = "GateLabel"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font = ThemeDB.fallback_font
	label.font_size = 28
	label.outline_size = 7
	label.pixel_size = 0.016
	label.position = Vector3(bridge_x, 2.34, 0.0)
	label.modulate = Color(1.0, 0.92, 0.58)
	world_root.add_child(label)
	_gate_labels.append(label)
	_refresh_gate_visual(_gate_bars.size() - 1)


func _refresh_gate_visual(lane_index: int) -> void:
	var openness: float = _gate_openness[lane_index]
	var bridge_x: float = _bridge_tops[lane_index].position.x
	var bar: MeshInstance3D = _gate_bars[lane_index]
	bar.position = Vector3(bridge_x, lerpf(0.78, 2.02, openness), 0.0)
	var label: Label3D = _gate_labels[lane_index]
	var gate_state: Dictionary = _gate_states[lane_index] if lane_index < _gate_states.size() else {}
	var state_text: String = "\u5173\u95ed"
	if openness >= 0.80:
		state_text = "\u5f00\u542f"
	elif openness > 0.20:
		state_text = "\u534a\u5f00"
	var owner_id: int = int(gate_state.get("owner_id", CardfrontRulesScript.NEUTRAL_OWNER))
	var bar_color := Color(0.95, 0.30, 0.26)
	if owner_id == CardfrontRulesScript.PLAYER_FACTION:
		bar_color = PLAYER_TINT.lightened(0.12)
	elif owner_id == CardfrontRulesScript.AI_FACTION:
		bar_color = AI_TINT.lightened(0.12)
	if openness >= 0.80:
		bar_color = Color(0.26, 0.74, 0.38)
	elif openness > 0.20:
		bar_color = Color(0.92, 0.74, 0.22)
	else:
		bar_color = Color(1.0, 0.22, 0.16)
	var gate_emission: float = 0.18
	if openness >= 0.80:
		gate_emission = 0.42
	elif openness <= 0.20:
		gate_emission = 0.56
	bar.material_override = _make_material(bar_color, gate_emission)
	label.modulate = bar_color.lightened(0.32)
	label.text = "%s  #%d" % [state_text, lane_index + 1]


func _build_stronghold_platforms() -> void:
	for region_id_value in region_map.get_controllable_region_ids():
		var region_id: int = int(region_id_value)
		var cells: Array = region_map.get_region_cells(region_id)
		if cells.is_empty():
			continue
		var bounds := _cell_bounds(cells)
		var center_cell: Vector2 = bounds.position + bounds.size * 0.5
		var center_world := Vector3(
			(center_cell.x - float(battlefield.grid_extent.x) * 0.5) * ARENA_X_SCALE,
			0.0,
			(center_cell.y - float(battlefield.grid_extent.y) * 0.5) * _z_scale
		)

		var platform_shadow := MeshInstance3D.new()
		platform_shadow.name = "StrongholdShadow_%s" % region_id
		var shadow_mesh := BoxMesh.new()
		shadow_mesh.size = Vector3(bounds.size.x * ARENA_X_SCALE + 0.36, 0.34, bounds.size.y * _z_scale + 0.36)
		platform_shadow.mesh = shadow_mesh
		platform_shadow.position = center_world + Vector3(0.0, 0.22, 0.0)
		platform_shadow.material_override = _make_material(Color(0.20, 0.28, 0.24), 0.0)
		world_root.add_child(platform_shadow)

		var platform := MeshInstance3D.new()
		platform.name = "StrongholdPlatform_%s" % region_id
		var platform_mesh := BoxMesh.new()
		platform_mesh.size = Vector3(bounds.size.x * ARENA_X_SCALE + 0.08, 0.34, bounds.size.y * _z_scale + 0.08)
		platform.mesh = platform_mesh
		platform.position = center_world + Vector3(0.0, 0.46, 0.0)
		platform.material_override = _make_material(_region_accent(str(region_map.get_region_type_by_id(region_id))).lightened(0.08), 0.06)
		world_root.add_child(platform)
		_region_platforms[region_id] = platform

		var ring := MeshInstance3D.new()
		ring.name = "StrongholdControlRing_%s" % region_id
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.84
		ring_mesh.outer_radius = 1.0
		ring_mesh.rings = 12
		ring_mesh.ring_segments = 8
		ring.mesh = ring_mesh
		ring.position = center_world + Vector3(0.0, 0.72, 0.0)
		ring.scale = Vector3(
			maxf(1.0, bounds.size.x * ARENA_X_SCALE * 0.52),
			1.0,
			maxf(1.0, bounds.size.y * _z_scale * 0.52)
		)
		ring.material_override = _make_material(Color(0.82, 0.88, 0.70, 0.90), 0.16)
		world_root.add_child(ring)
		_region_control_rings[region_id] = ring


func _cell_bounds(cells: Array) -> Rect2:
	var min_cell := Vector2(INF, INF)
	var max_cell := Vector2(-INF, -INF)
	for cell_value in cells:
		var cell := Vector2(Vector2i(cell_value))
		min_cell.x = minf(min_cell.x, cell.x)
		min_cell.y = minf(min_cell.y, cell.y)
		max_cell.x = maxf(max_cell.x, cell.x + 1.0)
		max_cell.y = maxf(max_cell.y, cell.y + 1.0)
	return Rect2(min_cell, max_cell - min_cell)


func _refresh_tile_colors() -> void:
	if tile_multimesh == null or tile_multimesh.multimesh == null:
		return
	var extent: Vector2i = battlefield.grid_extent
	if not (battlefield.owners is Array) or battlefield.owners.size() != extent.x:
		return
	for x in range(extent.x):
		if not (battlefield.owners[x] is Array):
			continue
		for y in range(extent.y):
			var owner_id: int = int(battlefield.owners[x][y])
			var region_type: String = str(region_map.get_region_type(Vector2i(x, y)))
			tile_multimesh.multimesh.set_instance_color(x * extent.y + y, _tile_color(owner_id, region_type, Vector2i(x, y)))
	_refresh_territory_boundaries()
	_refresh_sparse_claim_markers()
	_refresh_stronghold_platforms()
	_refresh_region_labels()


func _refresh_stronghold_platforms() -> void:
	for region_id in _region_platforms.keys():
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, int(region_id))
		var leader: Dictionary = _get_region_leader(control)
		var region_type: String = str(control.get("region_type", RegionTypeScript.NORMAL))
		var accent: Color = _region_accent(region_type)
		var leader_id: int = int(leader.owner_id)
		var color: Color = accent.lightened(0.10)
		if leader_id != CardfrontRulesScript.NEUTRAL_OWNER:
			color = accent.lerp(_arena_faction_color(leader_id).lightened(0.18), 0.38)
		var platform: MeshInstance3D = _region_platforms[region_id]
		platform.material_override = _make_material(color, 0.10)
		var ring: MeshInstance3D = _region_control_rings.get(region_id, null)
		if ring != null and is_instance_valid(ring):
			var control_ratio: float = clampf(float(leader.percent) / 100.0, 0.0, 1.0)
			var ring_color: Color = color.lightened(0.26)
			ring.material_override = _make_material(ring_color, lerpf(0.08, 0.32, control_ratio))
			ring.scale.y = 1.0 + (1.0 - control_ratio) * 0.18


func _build_region_labels() -> void:
	for region_id_value in region_map.get_controllable_region_ids():
		var region_id: int = int(region_id_value)
		var cells: Array = region_map.get_region_cells(region_id)
		if cells.is_empty():
			continue
		var center := Vector2.ZERO
		for cell_value in cells:
			var cell: Vector2i = cell_value
			center += Vector2(cell) + Vector2.ONE * 0.5
		center /= float(cells.size())
		var label := Label3D.new()
		label.name = "StrongholdLabel_%s" % region_id
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font = ThemeDB.fallback_font
		label.font_size = 30
		label.outline_size = 7
		label.pixel_size = 0.013
		label.render_priority = 1
		label.position = Vector3(
			(center.x - float(battlefield.grid_extent.x) * 0.5) * ARENA_X_SCALE,
			1.42,
			(center.y - float(battlefield.grid_extent.y) * 0.5) * _z_scale
		)

		var badge_plate := MeshInstance3D.new()
		badge_plate.name = "BadgePlate"
		var badge_mesh := QuadMesh.new()
		badge_mesh.size = Vector2(3.2, 0.70)
		badge_plate.mesh = badge_mesh
		var badge_material := StandardMaterial3D.new()
		badge_material.albedo_color = Color(0.035, 0.055, 0.060, 0.92)
		badge_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		badge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		badge_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		badge_material.no_depth_test = true
		badge_plate.material_override = badge_material
		badge_material.render_priority = -1
		badge_plate.position = label.position + Vector3(0.0, 0.0, -0.06)
		badge_material.albedo_color.a = 0.0
		world_root.add_child(badge_plate)

		label.modulate.a = 0.0
		world_root.add_child(label)
		_region_labels[region_id] = label
		_region_badge_plates[region_id] = badge_plate


func _refresh_region_labels() -> void:
	for region_id in _region_labels.keys():
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, int(region_id))
		var leader: Dictionary = _get_region_leader(control)
		var region_type: String = str(control.get("region_type", RegionTypeScript.NORMAL))
		var label: Label3D = _region_labels[region_id]
		label.text = "%s  %d%%" % [
			_region_badge_icon(region_type),
			int(leader.percent),
		]
		var leader_id: int = int(leader.owner_id)
		label.modulate = (
			Color.WHITE
			if leader_id == CardfrontRulesScript.NEUTRAL_OWNER
			else _arena_faction_color(leader_id).lightened(0.28)
		)
		if _labels_force_visible:
			continue
		var prev: Dictionary = _last_region_leaders.get(int(region_id), {})
		var prev_owner: int = int(prev.get("owner_id", -999))
		var prev_percent: int = int(prev.get("percent", -1))
		var owner_changed: bool = prev_owner != leader_id
		var percent_shift: bool = absi(int(leader.percent) - prev_percent) >= LABEL_CHANGE_THRESHOLD
		if owner_changed or percent_shift:
			_fade_label(int(region_id), 1.0, LABEL_FADE_DURATION, LABEL_AUTO_HIDE_DELAY)
		_last_region_leaders[int(region_id)] = {
			"owner_id": leader_id,
			"percent": int(leader.percent),
		}


func _region_badge_icon(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "⚡"
		RegionTypeScript.FACTORY:
			return "◆"
		RegionTypeScript.LAB:
			return "✦"
		_:
			return "●"


func set_stronghold_labels_visible(visible_flag: bool, auto_hide_delay: float = 0.0) -> void:
	_labels_force_visible = visible_flag
	for region_id in _region_labels.keys():
		if visible_flag:
			_fade_label(int(region_id), 1.0, LABEL_FADE_DURATION, auto_hide_delay)
		else:
			_fade_label(int(region_id), 0.0, LABEL_FADE_DURATION, 0.0)


func _fade_label(region_id: int, target_alpha: float, duration: float, auto_hide_delay: float) -> void:
	var label: Label3D = _region_labels.get(region_id, null)
	if label == null or not is_instance_valid(label):
		return
	var badge: MeshInstance3D = _region_badge_plates.get(region_id, null)
	var prev_tween: Tween = _region_label_tweens.get(region_id, null)
	if prev_tween != null and is_instance_valid(prev_tween):
		prev_tween.kill()
	var tween: Tween = create_tween()
	if tween == null:
		label.modulate.a = target_alpha
		return
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", target_alpha, duration)
	if badge != null and is_instance_valid(badge) and badge.material_override != null:
		tween.tween_property(badge, "material_override:albedo_color:a", target_alpha, duration)
	_region_label_tweens[region_id] = tween
	if auto_hide_delay > 0.0 and target_alpha > 0.5:
		tween.chain().tween_interval(auto_hide_delay)
		tween.chain().tween_property(label, "modulate:a", 0.0, LABEL_FADE_DURATION)
		if badge != null and is_instance_valid(badge) and badge.material_override != null:
			tween.chain().tween_property(badge, "material_override:albedo_color:a", 0.0, LABEL_FADE_DURATION)


func _nearest_presentation_scale(requested_scale: float) -> float:
	var nearest: float = PRESENTATION_SCALE_PRESETS[0]
	var nearest_distance: float = absf(requested_scale - nearest)
	for preset in PRESENTATION_SCALE_PRESETS:
		var distance: float = absf(requested_scale - preset)
		if distance < nearest_distance:
			nearest = preset
			nearest_distance = distance
	return nearest


func _get_region_leader(control: Dictionary) -> Dictionary:
	var best_owner: int = CardfrontRulesScript.NEUTRAL_OWNER
	var best_percent: int = -1
	for owner_id in CardfrontRulesScript.get_score_owner_ids():
		var percent: int = RegionControlCalculatorScript.get_owner_percent(control, int(owner_id))
		if percent > best_percent:
			best_owner = int(owner_id)
			best_percent = percent
	return {"owner_id": best_owner, "percent": maxi(0, best_percent)}


func _build_combatant_proxies() -> void:
	for owner_id in CardfrontRulesScript.get_duel_factions():
		var turret = turrets.get(owner_id, null)
		if turret == null or not is_instance_valid(turret):
			continue
		var proxy := Node3D.new()
		proxy.name = "Combatant_%s" % str(owner_id)
		world_root.add_child(proxy)

		var chamber := MeshInstance3D.new()
		chamber.name = "ChamberFoundation"
		var chamber_mesh := BoxMesh.new()
		chamber_mesh.size = COMMAND_CHAMBER_SIZE
		chamber.mesh = chamber_mesh
		chamber.position.y = 0.30
		chamber.material_override = _make_material(Color(0.34, 0.36, 0.31), 0.0)
		proxy.add_child(chamber)

		var keep := MeshInstance3D.new()
		keep.name = "ChamberKeep"
		var keep_mesh := BoxMesh.new()
		keep_mesh.size = Vector3(3.76, 1.72, 2.54)
		keep.mesh = keep_mesh
		keep.position.y = 1.06
		keep.material_override = _get_faction_material(int(owner_id), 0.14)
		proxy.add_child(keep)

		for corner in [
			Vector3(-1.94, 1.34, -1.34),
			Vector3(1.94, 1.34, -1.34),
			Vector3(-1.94, 1.34, 1.34),
			Vector3(1.94, 1.34, 1.34),
		]:
			var corner_tower := MeshInstance3D.new()
			corner_tower.name = "CornerTower"
			var corner_mesh := CylinderMesh.new()
			corner_mesh.top_radius = 0.48
			corner_mesh.bottom_radius = 0.58
			corner_mesh.height = 1.72
			corner_mesh.radial_segments = 8
			corner_tower.mesh = corner_mesh
			corner_tower.position = corner
			corner_tower.material_override = _get_faction_material(int(owner_id), 0.08)
			proxy.add_child(corner_tower)

		for merlon_x in [-1.20, -0.40, 0.40, 1.20]:
			var merlon := MeshInstance3D.new()
			merlon.name = "Battlement"
			var merlon_mesh := BoxMesh.new()
			merlon_mesh.size = Vector3(0.44, 0.38, 0.46)
			merlon.mesh = merlon_mesh
			merlon.position = Vector3(merlon_x, 1.98, -0.92)
			merlon.material_override = _get_faction_material(int(owner_id), 0.10)
			proxy.add_child(merlon)

		var turret_pivot := Node3D.new()
		turret_pivot.name = "TurretPivot"
		turret_pivot.position.y = 2.05
		proxy.add_child(turret_pivot)

		var turret_base := MeshInstance3D.new()
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.66
		base_mesh.bottom_radius = 0.82
		base_mesh.height = 0.54
		base_mesh.radial_segments = 10
		turret_base.mesh = base_mesh
		turret_base.material_override = _make_material(Color(0.22, 0.25, 0.24), 0.10)
		turret_pivot.add_child(turret_base)

		var barrel := MeshInstance3D.new()
		barrel.name = "Barrel"
		var barrel_mesh := BoxMesh.new()
		barrel_mesh.size = Vector3(1.62, 0.30, 0.42)
		barrel.mesh = barrel_mesh
		barrel.position = Vector3(0.82, 0.08, 0.0)
		barrel.material_override = _make_material(Color(0.95, 0.97, 0.98), 0.22)
		turret_pivot.add_child(barrel)

		var faction_banner := MeshInstance3D.new()
		faction_banner.name = "FactionBanner"
		var banner_mesh := BoxMesh.new()
		banner_mesh.size = Vector3(1.22, 0.62, 0.08)
		faction_banner.mesh = banner_mesh
		faction_banner.position = Vector3(0.0, 1.18, -1.18)
		faction_banner.material_override = _get_faction_material(int(owner_id), 0.32)
		proxy.add_child(faction_banner)

		var label := Label3D.new()
		label.name = "HealthLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font = ThemeDB.fallback_font
		label.font_size = 36
		label.outline_size = 9
		label.pixel_size = 0.017
		label.position = Vector3(0.0, 3.15, 0.0)
		label.modulate = Color.WHITE
		proxy.add_child(label)
		_turret_proxies[int(owner_id)] = proxy
		_turret_barrels[int(owner_id)] = turret_pivot
		_chamber_labels[int(owner_id)] = label


func _sync_turrets() -> void:
	for owner_id in _turret_proxies.keys():
		var turret = turrets.get(owner_id, null)
		var proxy: Node3D = _turret_proxies[owner_id]
		if turret == null or not is_instance_valid(turret):
			proxy.visible = false
			continue
		proxy.visible = true
		proxy.position = _simulation_to_world(turret.global_position, 0.0)
		proxy.position.z -= signf(proxy.position.z) * 2.2
		proxy.rotation.y = 0.0
		var turret_pivot: Node3D = _turret_barrels.get(owner_id, null)
		if turret_pivot != null and is_instance_valid(turret_pivot):
			turret_pivot.rotation.y = -float(turret.rotation)
		var health: int = int(turret.health)
		var max_health: int = maxi(1, int(turret.max_health))
		var label: Label3D = _chamber_labels[owner_id]
		label.visible = health < max_health
		label.text = "%s  %d/%d" % [
			"玩家" if int(owner_id) == CardfrontRulesScript.PLAYER_FACTION else "AI",
			health,
			max_health,
		]
		label.modulate = Color(1.0, 0.35, 0.26) if health * 3 < max_health else Color.WHITE


func _sync_bullets() -> void:
	var active: Array = []
	if bullet_pool != null and is_instance_valid(bullet_pool) and bullet_pool.has_method("get_active_bullets"):
		active = bullet_pool.get_active_bullets()
	var visible_count: int = mini(active.size(), MAX_BULLET_PROXIES)
	_ensure_bullet_proxies(visible_count)
	for index in range(_bullet_proxies.size()):
		var proxy: MeshInstance3D = _bullet_proxies[index]
		if index >= visible_count:
			proxy.visible = false
			continue
		var bullet = active[index]
		if bullet == null or not is_instance_valid(bullet):
			proxy.visible = false
			continue
		var projectile_type: String = ProjectileTypeScript.sanitize(str(bullet.projectile_type))
		var faction_color: Color = _arena_faction_color(int(bullet.faction_id))
		var spec: Dictionary = CombatReadabilityScript.projectile_spec(projectile_type, faction_color)
		proxy.visible = true
		proxy.position = _simulation_to_world(bullet.global_position, 0.58)
		proxy.mesh = _projectile_mesh(str(spec.get("shape", "round")))
		proxy.material_override = _make_material(
			spec.get("color", faction_color) as Color,
			float(spec.get("emission", 0.8))
		)
		var radius: float = float(spec.get("radius", 0.42)) * PROJECTILE_VISUAL_SCALE
		proxy.scale = Vector3.ONE * radius
		var direction: Vector2 = bullet.direction if bullet.get("direction") is Vector2 else Vector2.RIGHT
		if direction.length_squared() > 0.001:
			var direction_3d := Vector3(direction.x, 0.0, direction.y).normalized()
			proxy.look_at(proxy.position + direction_3d, Vector3.UP)
		_sync_projectile_trail(proxy, spec, radius)


func _ensure_bullet_proxies(required_count: int) -> void:
	while _bullet_proxies.size() < required_count:
		var proxy := MeshInstance3D.new()
		proxy.name = "BulletProxy_%03d" % _bullet_proxies.size()
		proxy.mesh = _projectile_mesh("round")
		var trail := MeshInstance3D.new()
		trail.name = "Trail"
		var trail_mesh := BoxMesh.new()
		trail_mesh.size = Vector3.ONE
		trail.mesh = trail_mesh
		proxy.add_child(trail)
		_bullet_trails[proxy.get_instance_id()] = trail
		world_root.add_child(proxy)
		_bullet_proxies.append(proxy)


func _projectile_mesh(shape: String) -> PrimitiveMesh:
	if _bullet_meshes.has(shape):
		return _bullet_meshes[shape] as PrimitiveMesh
	var mesh: PrimitiveMesh
	match shape:
		"disc":
			var disc := CylinderMesh.new()
			disc.top_radius = 0.94
			disc.bottom_radius = 0.94
			disc.height = 0.34
			disc.radial_segments = 14
			mesh = disc
		"heavy":
			var heavy := SphereMesh.new()
			heavy.radius = 1.02
			heavy.height = 1.62
			heavy.radial_segments = 12
			heavy.rings = 6
			mesh = heavy
		_:
			var round_mesh := SphereMesh.new()
			round_mesh.radius = 0.82
			round_mesh.height = 1.64
			round_mesh.radial_segments = 12
			round_mesh.rings = 6
			mesh = round_mesh
	_bullet_meshes[shape] = mesh
	return mesh


func _sync_projectile_trail(proxy: MeshInstance3D, spec: Dictionary, radius: float) -> void:
	var trail: MeshInstance3D = _bullet_trails.get(proxy.get_instance_id(), null)
	if trail == null or not is_instance_valid(trail):
		return
	var length: float = float(spec.get("trail_length", 1.0))
	var width: float = float(spec.get("trail_width", 0.12))
	trail.position = Vector3(0.0, 0.0, length * 0.5 + radius)
	trail.scale = Vector3(width, width, length)
	var color: Color = spec.get("color", Color.WHITE) as Color
	color.a = 0.52
	trail.material_override = _make_material(color, float(spec.get("emission", 0.8)) * 0.72)


func _sync_entities() -> void:
	if entity_runtime == null or not is_instance_valid(entity_runtime):
		return
	var registry = entity_runtime.get("registry")
	if registry == null:
		return
	var live_ids: Dictionary = {}
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		var entity_id: String = str(entity.entity_id)
		live_ids[entity_id] = true
		var proxy: Node3D = _entity_proxies.get(entity_id, null)
		if proxy == null or not is_instance_valid(proxy):
			proxy = _create_entity_proxy(entity)
			proxy.name = "BattlefieldEntity_%s" % entity_id
			world_root.add_child(proxy)
			_entity_proxies[entity_id] = proxy
		proxy.position = _cell_to_world(entity.cell, 0.0) + CombatReadabilityScript.stable_slot_offset(entity_id)
		_sync_entity_readability(entity)
		if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
			_sync_creature_sprite(entity_id)
	for entity_id in _entity_proxies.keys():
		if live_ids.has(entity_id):
			continue
		var stale_proxy: Node3D = _entity_proxies[entity_id]
		if stale_proxy != null and is_instance_valid(stale_proxy):
			stale_proxy.queue_free()
		_entity_proxies.erase(entity_id)
		_entity_sprites.erase(entity_id)
		_entity_hp_fills.erase(entity_id)
		_entity_status_labels.erase(entity_id)


func _create_entity_proxy(entity) -> Node3D:
	var proxy := Node3D.new()
	proxy.scale = Vector3.ONE * COMBAT_ENTITY_VISUAL_SCALE
	var owner_color: Color = (
		Color(0.92, 0.72, 0.22)
		if int(entity.owner_id) == CardfrontRulesScript.NEUTRAL_OWNER
		else _arena_faction_color(int(entity.owner_id)).lightened(0.12)
	)
	var faction_ring := MeshInstance3D.new()
	faction_ring.name = "FactionRing"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.78
	ring_mesh.bottom_radius = 0.86
	ring_mesh.height = 0.12
	ring_mesh.radial_segments = 16
	faction_ring.mesh = ring_mesh
	faction_ring.position.y = TILE_HEIGHT + 0.16
	faction_ring.material_override = _make_material(owner_color, 0.18)
	proxy.add_child(faction_ring)

	if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
		var sprite := Sprite3D.new()
		sprite.name = "AnimatedCreature"
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test = false
		sprite.pixel_size = 0.010
		sprite.position.y = 1.34
		proxy.add_child(sprite)
		_entity_sprites[str(entity.entity_id)] = sprite
	else:
		_build_tower_proxy(proxy, entity, owner_color)

	_build_entity_hp_bar(proxy, entity, owner_color)
	return proxy


func _build_entity_hp_bar(proxy: Node3D, entity, owner_color: Color) -> void:
	var backing := MeshInstance3D.new()
	backing.name = "HpBacking"
	var backing_mesh := BoxMesh.new()
	backing_mesh.size = Vector3(1.72, 0.18, 0.10)
	backing.mesh = backing_mesh
	backing.position = Vector3(0.0, 2.43, 0.0)
	backing.material_override = _make_material(Color(0.04, 0.055, 0.06), 0.0)
	backing.visible = false
	proxy.add_child(backing)

	var fill := MeshInstance3D.new()
	fill.name = "HpFill"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(1.56, 0.10, 0.12)
	fill.mesh = fill_mesh
	fill.position = Vector3(0.0, 2.43, -0.02)
	fill.material_override = _make_material(owner_color.lightened(0.18), 0.34)
	fill.visible = false
	proxy.add_child(fill)
	_entity_hp_fills[str(entity.entity_id)] = fill

	var status := Label3D.new()
	status.name = "Status"
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status.no_depth_test = true
	status.font = ThemeDB.fallback_font
	status.font_size = 18
	status.outline_size = 6
	status.pixel_size = 0.012
	status.position = Vector3(0.0, 2.74, 0.0)
	status.modulate = owner_color.lightened(0.28)
	status.visible = false
	proxy.add_child(status)
	_entity_status_labels[str(entity.entity_id)] = status


func _sync_entity_readability(entity) -> void:
	var entity_id: String = str(entity.entity_id)
	var ratio: float = CombatReadabilityScript.hp_ratio(entity)
	var show_hp: bool = ratio < 0.999
	var fill: MeshInstance3D = _entity_hp_fills.get(entity_id, null)
	if fill != null and is_instance_valid(fill):
		fill.visible = show_hp
		fill.scale.x = maxf(0.01, ratio)
		fill.position.x = -0.78 * (1.0 - ratio)
		var backing: MeshInstance3D = fill.get_parent().get_node_or_null("HpBacking")
		if backing != null:
			backing.visible = show_hp
	var status: Label3D = _entity_status_labels.get(entity_id, null)
	if status != null and is_instance_valid(status):
		status.visible = not bool(entity.powered)
		status.text = CombatReadabilityScript.entity_status_text(entity) if status.visible else ""
		status.modulate = Color(0.58, 0.62, 0.66) if not bool(entity.powered) else Color.WHITE
	var proxy: Node3D = _entity_proxies.get(entity_id, null)
	if proxy != null and is_instance_valid(proxy):
		var power_node: MeshInstance3D = proxy.get_node_or_null("PowerCore")
		if power_node != null:
			power_node.visible = bool(entity.powered)


func _build_tower_proxy(proxy: Node3D, entity, owner_color: Color) -> void:
	var base := MeshInstance3D.new()
	base.name = "TowerBase"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.62
	base_mesh.bottom_radius = 0.82
	base_mesh.height = 0.82
	base_mesh.radial_segments = 10
	base.mesh = base_mesh
	base.position.y = TILE_HEIGHT + 0.53
	base.material_override = _make_material(owner_color.darkened(0.16), 0.08)
	proxy.add_child(base)

	var mast := MeshInstance3D.new()
	mast.name = "TowerMast"
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.23
	mast_mesh.bottom_radius = 0.34
	mast_mesh.height = 1.20
	mast_mesh.radial_segments = 10
	mast.mesh = mast_mesh
	mast.position.y = 1.46
	mast.material_override = _make_material(owner_color, 0.18)
	proxy.add_child(mast)

	var head := MeshInstance3D.new()
	head.name = "TowerHead"
	var head_mesh := BoxMesh.new()
	var tower_id: String = str(entity.tower_id)
	var shape: String = CombatReadabilityScript.tower_shape(tower_id)
	head_mesh.size = Vector3(1.38, 0.46, 0.74) if shape == "interceptor" else Vector3(0.76, 0.42, 0.76)
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.12, 0.0)
	head.material_override = _make_material(Color(0.93, 0.96, 0.90), 0.24)
	proxy.add_child(head)

	var power_core := MeshInstance3D.new()
	power_core.name = "PowerCore"
	if shape == "beacon":
		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.40
		orb_mesh.height = 0.80
		orb_mesh.radial_segments = 12
		orb_mesh.rings = 6
		power_core.mesh = orb_mesh
		power_core.position = Vector3(0.0, 2.72, 0.0)
		power_core.material_override = _make_material(Color(0.30, 0.96, 1.0), 1.15)
		proxy.add_child(power_core)
		for arm_rotation in [0.0, PI * 0.5]:
			var signal_arm := MeshInstance3D.new()
			signal_arm.name = "SignalArm"
			var arm_mesh := BoxMesh.new()
			arm_mesh.size = Vector3(1.52, 0.10, 0.12)
			signal_arm.mesh = arm_mesh
			signal_arm.position = Vector3(0.0, 2.68, 0.0)
			signal_arm.rotation.y = arm_rotation
			signal_arm.material_override = _make_material(Color(0.24, 0.78, 0.86), 0.52)
			proxy.add_child(signal_arm)
	else:
		var shield_mesh := BoxMesh.new()
		shield_mesh.size = Vector3(1.58, 0.60, 0.20)
		power_core.mesh = shield_mesh
		power_core.position = Vector3(0.0, 2.12, -0.44)
		power_core.material_override = _make_material(owner_color.lightened(0.22), 0.64)
		proxy.add_child(power_core)
		for barrel_x in [-0.46, 0.46]:
			var barrel := MeshInstance3D.new()
			barrel.name = "InterceptorBarrel"
			var barrel_mesh := BoxMesh.new()
			barrel_mesh.size = Vector3(0.22, 0.22, 1.08)
			barrel.mesh = barrel_mesh
			barrel.position = Vector3(barrel_x, 2.22, -0.58)
			barrel.material_override = _make_material(Color(0.18, 0.23, 0.25), 0.12)
			proxy.add_child(barrel)


func _sync_creature_sprite(entity_id: String) -> void:
	var sprite_3d: Sprite3D = _entity_sprites.get(entity_id, null)
	if sprite_3d == null or not is_instance_valid(sprite_3d):
		return
	var presentation = entity_runtime.get("presentation_layer")
	if presentation == null or not is_instance_valid(presentation):
		return
	var actors_value = presentation.get("_actors_by_entity_id")
	if not (actors_value is Dictionary):
		return
	var actor = (actors_value as Dictionary).get(entity_id, null)
	if actor == null or not is_instance_valid(actor) or actor.sprite == null:
		return
	var animated_sprite: AnimatedSprite2D = actor.sprite
	if animated_sprite.sprite_frames == null:
		return
	sprite_3d.texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	sprite_3d.flip_h = animated_sprite.flip_h


func _connect_entity_runtime() -> void:
	if entity_runtime == null or not is_instance_valid(entity_runtime):
		return
	var bindings: Dictionary = {
		"entity_contact_resolved": "_on_entity_contact_resolved",
		"projectile_guided": "_on_projectile_guided",
		"tower_power_changed": "_on_tower_power_changed",
		"heavy_charge_exploded": "_on_heavy_charge_exploded",
	}
	for signal_name in bindings.keys():
		if not entity_runtime.has_signal(signal_name):
			continue
		var callable := Callable(self, str(bindings[signal_name]))
		if not entity_runtime.is_connected(signal_name, callable):
			entity_runtime.connect(signal_name, callable)


func _disconnect_entity_runtime() -> void:
	if entity_runtime == null or not is_instance_valid(entity_runtime):
		return
	var bindings: Dictionary = {
		"entity_contact_resolved": "_on_entity_contact_resolved",
		"projectile_guided": "_on_projectile_guided",
		"tower_power_changed": "_on_tower_power_changed",
		"heavy_charge_exploded": "_on_heavy_charge_exploded",
	}
	for signal_name in bindings.keys():
		if not entity_runtime.has_signal(signal_name):
			continue
		var callable := Callable(self, str(bindings[signal_name]))
		if entity_runtime.is_connected(signal_name, callable):
			entity_runtime.disconnect(signal_name, callable)


func _on_entity_contact_resolved(result: Dictionary) -> void:
	var cell: Vector2i = result.get("cell", Vector2i(-1, -1)) as Vector2i
	if cell.x < 0:
		return
	var projectile_type: String = str(result.get("projectile_type", ProjectileTypeScript.STANDARD))
	var spec: Dictionary = CombatReadabilityScript.projectile_spec(projectile_type, Color.WHITE)
	_add_combat_effect(cell, spec.get("color", Color.WHITE) as Color, 0.48, 1.8)


func _on_projectile_guided(tower_entity_id: String, owner_id: int, _projectile_type: String) -> void:
	if entity_runtime == null:
		return
	var registry = entity_runtime.get("registry")
	var tower = registry.get_entity(tower_entity_id) if registry != null else null
	if tower != null:
		_add_combat_effect(tower.cell, _arena_faction_color(owner_id).lightened(0.28), 0.34, 1.25)


func _on_tower_power_changed(entity_id: String, _powered: bool) -> void:
	if entity_runtime == null:
		return
	var registry = entity_runtime.get("registry")
	var tower = registry.get_entity(entity_id) if registry != null else null
	if tower != null:
		_add_combat_effect(tower.cell, Color(0.82, 0.88, 0.92), 0.42, 1.35)


func _on_heavy_charge_exploded(owner_id: int, cell: Vector2i, _center_target_id: String) -> void:
	_add_combat_effect(cell, _arena_faction_color(owner_id).lerp(Color(1.0, 0.44, 0.08), 0.72), 0.72, 3.2)


func _add_combat_effect(cell: Vector2i, color: Color, duration: float, max_scale: float) -> void:
	if world_root == null:
		return
	var effect := MeshInstance3D.new()
	effect.name = "CombatImpact"
	var mesh := SphereMesh.new()
	mesh.radius = 0.72
	mesh.height = 0.28
	mesh.radial_segments = 16
	mesh.rings = 4
	effect.mesh = mesh
	effect.position = _cell_to_world(cell, TILE_HEIGHT + 0.34)
	var material := _make_material(Color(color.r, color.g, color.b, 0.82), 0.92)
	effect.material_override = material
	world_root.add_child(effect)
	_combat_effects.append({
		"node": effect,
		"material": material,
		"remaining": maxf(0.05, duration),
		"total": maxf(0.05, duration),
		"color": color,
		"max_scale": maxf(1.0, max_scale),
	})


func _update_combat_effects(delta: float) -> void:
	for index in range(_combat_effects.size() - 1, -1, -1):
		var effect: Dictionary = _combat_effects[index] as Dictionary
		var node: MeshInstance3D = effect.get("node", null)
		if node == null or not is_instance_valid(node):
			_combat_effects.remove_at(index)
			continue
		var remaining: float = maxf(0.0, float(effect.get("remaining", 0.0)) - maxf(0.0, delta))
		effect["remaining"] = remaining
		if remaining <= 0.0:
			node.queue_free()
			_combat_effects.remove_at(index)
			continue
		var total: float = maxf(0.05, float(effect.get("total", 0.05)))
		var progress: float = 1.0 - remaining / total
		var scale_value: float = lerpf(0.45, float(effect.get("max_scale", 1.5)), progress)
		node.scale = Vector3(scale_value, 0.35, scale_value)
		var color: Color = effect.get("color", Color.WHITE) as Color
		color.a = (1.0 - progress) * 0.78
		var material: StandardMaterial3D = effect.get("material", null)
		if material != null:
			material.albedo_color = color
			material.emission = color


func _cell_to_world(cell: Vector2i, height: float) -> Vector3:
	return Vector3(
		(float(cell.x) + 0.5 - float(battlefield.grid_extent.x) * 0.5) * ARENA_X_SCALE,
		height,
		(float(cell.y) + 0.5 - float(battlefield.grid_extent.y) * 0.5) * _z_scale
	)
func _build_aim_guide() -> void:
	_aim_material = StandardMaterial3D.new()
	_aim_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aim_material.albedo_color = Color(0.28, 0.94, 1.0, 0.92)
	_aim_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aim_mesh_instance = MeshInstance3D.new()
	aim_mesh_instance.name = "AimGuide"
	aim_mesh_instance.mesh = _aim_mesh
	world_root.add_child(aim_mesh_instance)


func _sync_aim_guide() -> void:
	_aim_mesh.clear_surfaces()
	var turret = turrets.get(CardfrontRulesScript.PLAYER_FACTION, null)
	if turret == null or not is_instance_valid(turret):
		return
	var origin: Vector3 = _simulation_to_world(turret.global_position, 0.72)
	var direction_2d := Vector2.RIGHT.rotated(float(turret.rotation)).normalized()
	var direction_3d := Vector3(direction_2d.x * ARENA_X_SCALE, 0.0, direction_2d.y * _z_scale).normalized()
	var start: Vector3 = origin + direction_3d * 1.4
	var contacts: Array[Dictionary] = []
	var ray_origin: Vector3 = start
	var ray_direction: Vector3 = direction_3d
	for contact_index in range(2):
		var contact := _get_aim_bounce_contact(ray_origin, ray_direction)
		if contact.is_empty():
			break
		contacts.append(contact)
		ray_origin = contact.point + ray_direction * 0.03
		ray_direction = ray_direction.bounce(contact.normal).normalized()
	_aim_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _aim_material)
	var side: Vector3 = Vector3.UP.cross(direction_3d).normalized() * 0.48
	var cone_tip: Vector3 = start + direction_3d * 4.2
	_aim_mesh.surface_add_vertex(start)
	_aim_mesh.surface_add_vertex(cone_tip + side)
	_aim_mesh.surface_add_vertex(start)
	_aim_mesh.surface_add_vertex(cone_tip - side)
	var segment_start: Vector3 = start
	for contact in contacts:
		var point: Vector3 = contact.point
		_aim_mesh.surface_add_vertex(segment_start)
		_aim_mesh.surface_add_vertex(point)
		_aim_mesh.surface_add_vertex(point - side * 0.46)
		_aim_mesh.surface_add_vertex(point + side * 0.46)
		_aim_mesh.surface_add_vertex(point - Vector3.UP * 0.34)
		_aim_mesh.surface_add_vertex(point + Vector3.UP * 0.34)
		segment_start = point
	_aim_mesh.surface_end()


func _get_aim_bounce_contact(ray_origin: Vector3, ray_direction: Vector3) -> Dictionary:
	var half_width: float = float(battlefield.grid_extent.x) * ARENA_X_SCALE * 0.5 - 0.35
	var half_depth: float = float(battlefield.grid_extent.y) * _z_scale * 0.5 - 0.35
	var best_distance: float = INF
	var normal := Vector3.ZERO
	if absf(ray_direction.x) > 0.001:
		var x_limit: float = half_width if ray_direction.x > 0.0 else -half_width
		var x_distance: float = (x_limit - ray_origin.x) / ray_direction.x
		if x_distance > 0.08:
			best_distance = x_distance
			normal = Vector3(-signf(ray_direction.x), 0.0, 0.0)
	if absf(ray_direction.z) > 0.001:
		var z_limit: float = half_depth if ray_direction.z > 0.0 else -half_depth
		var z_distance: float = (z_limit - ray_origin.z) / ray_direction.z
		if z_distance > 0.08 and z_distance < best_distance:
			best_distance = z_distance
			normal = Vector3(0.0, 0.0, -signf(ray_direction.z))
	if not is_finite(best_distance):
		return {}
	return {"point": ray_origin + ray_direction * best_distance, "normal": normal}


func _simulation_to_world(simulation_position: Vector2, height: float) -> Vector3:
	var local: Vector2 = simulation_position - battlefield.global_position
	var cell_size: float = maxf(1.0, float(battlefield.cell_size))
	return Vector3(
		(local.x / cell_size - float(battlefield.grid_extent.x) * 0.5) * ARENA_X_SCALE,
		height,
		(local.y / cell_size - float(battlefield.grid_extent.y) * 0.5) * _z_scale
	)


func _resolve_z_scale(extent: Vector2i) -> float:
	var elongation: float = clampf(
		(float(extent.y) / float(maxi(1, extent.x)) - 1.0) / 0.5,
		0.0,
		1.0
	)
	return lerpf(ARENA_Z_SCALE, 1.0, elongation)


func _tile_color(owner_id: int, region_type: String, cell: Vector2i) -> Color:
	var checker_index: int = floori(float(cell.x) / float(CHECKER_CELL_SPAN)) + floori(float(cell.y) / float(CHECKER_CELL_SPAN))
	var owner_color: Color = _theme_color("tile_a") if checker_index % 2 == 0 else _theme_color("tile_b")
	if owner_id != CardfrontRulesScript.NEUTRAL_OWNER:
		owner_color = owner_color.lerp(_arena_faction_color(owner_id), 0.60)
	var accent: Color = _region_accent(region_type)
	if region_type != RegionTypeScript.NORMAL:
		owner_color = owner_color.lerp(accent, 0.18).lightened(0.035)
	return Color(owner_color.r, owner_color.g, owner_color.b, 1.0)


func _theme_color(key: String) -> Color:
	var theme: Dictionary
	match map_id:
		"cross_resource":
			theme = {
				"sky": Color(0.67, 0.72, 0.63),
				"backdrop": Color(0.46, 0.51, 0.39),
				"outer": Color(0.46, 0.51, 0.39),
				"ground": Color(0.48, 0.53, 0.39),
				"tile_a": Color(0.50, 0.55, 0.40),
				"tile_b": Color(0.49, 0.54, 0.39),
				"path": Color(0.57, 0.43, 0.30, 0.58),
				"foliage_a": Color(0.31, 0.43, 0.27),
				"foliage_b": Color(0.36, 0.47, 0.29),
			}
		"central_lab":
			theme = {
				"sky": Color(0.68, 0.74, 0.74),
				"backdrop": Color(0.41, 0.49, 0.48),
				"outer": Color(0.41, 0.49, 0.48),
				"ground": Color(0.42, 0.52, 0.50),
				"tile_a": Color(0.44, 0.54, 0.52),
				"tile_b": Color(0.43, 0.53, 0.51),
				"path": Color(0.46, 0.40, 0.48, 0.56),
				"foliage_a": Color(0.25, 0.40, 0.35),
				"foliage_b": Color(0.30, 0.45, 0.38),
			}
		_:
			theme = {
				"sky": Color(0.66, 0.74, 0.66),
				"backdrop": Color(0.42, 0.54, 0.49),
				"outer": Color(0.42, 0.54, 0.49),
				"ground": Color(0.44, 0.57, 0.49),
				"tile_a": GRASS_LIGHT,
				"tile_b": GRASS_DARK,
				"path": PATH_COLOR,
				"foliage_a": Color(0.25, 0.40, 0.31),
				"foliage_b": Color(0.30, 0.46, 0.35),
			}
	return theme.get(key, Color.WHITE)


func _region_accent(region_type: String) -> Color:
	match region_type:
		RegionTypeScript.ENERGY:
			return Color(0.31, 0.51, 0.52)
		RegionTypeScript.FACTORY:
			return Color(0.59, 0.44, 0.25)
		RegionTypeScript.LAB:
			return Color(0.43, 0.39, 0.48)
		_:
			return GRASS_DARK


func _arena_faction_color(owner_id: int) -> Color:
	if owner_id == CardfrontRulesScript.PLAYER_FACTION:
		return PLAYER_TINT
	if owner_id == CardfrontRulesScript.AI_FACTION:
		return AI_TINT
	return GRASS_DARK


func _get_faction_material(owner_id: int, emission_energy: float) -> StandardMaterial3D:
	var key: String = "%d:%.2f" % [owner_id, emission_energy]
	if not _faction_materials.has(key):
		_faction_materials[key] = _make_material(_arena_faction_color(owner_id).lightened(0.08), emission_energy)
	return _faction_materials[key]


func _make_material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	material.metallic = 0.02
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
