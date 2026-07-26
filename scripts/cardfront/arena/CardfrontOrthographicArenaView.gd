extends CanvasLayer
class_name CardfrontOrthographicArenaView

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

const CANVAS_LAYER: int = 4
const MAX_BULLET_PROXIES: int = 256
const TILE_GAP: float = 0.012
const TILE_HEIGHT: float = 0.16
const ARENA_X_SCALE: float = 1.18
const ARENA_Z_SCALE: float = 1.28
const CHECKER_CELL_SPAN: int = 1
const BRIDGE_COUNT: int = 2
const GRASS_LIGHT: Color = Color(0.50, 0.61, 0.27)
const GRASS_DARK: Color = Color(0.44, 0.55, 0.23)
const PLAYER_TINT: Color = Color(0.21, 0.49, 0.60)
const AI_TINT: Color = Color(0.62, 0.30, 0.30)
const OUTLINE_COLOR: Color = Color(0.16, 0.24, 0.17)
const PATH_COLOR: Color = Color(0.56, 0.42, 0.25, 0.72)

var battlefield = null
var region_map = null
var bullet_pool = null
var turrets: Dictionary = {}
var layout: Dictionary = {}

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
var _chamber_labels: Dictionary = {}
var _region_labels: Dictionary = {}
var _region_platforms: Dictionary = {}
var _bridge_tops: Array[MeshInstance3D] = []
var _gate_bars: Array[MeshInstance3D] = []
var _gate_labels: Array[Label3D] = []
var _gate_openness: Array[float] = []
var _gate_states: Array[Dictionary] = []
var _bullet_proxies: Array[MeshInstance3D] = []
var _bullet_mesh: SphereMesh
var _faction_materials: Dictionary = {}
var _aim_mesh := ImmediateMesh.new()
var _aim_material: StandardMaterial3D
var _tiles_dirty: bool = true


func _init() -> void:
	name = "CardfrontOrthographicArenaView"
	layer = CANVAS_LAYER
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(new_battlefield, new_region_map, new_bullet_pool, new_turrets: Dictionary, new_layout: Dictionary) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	if new_region_map == null or int(new_region_map.grid_size) != int(new_battlefield.grid_size):
		return false
	var arena_view_rect: Rect2 = new_layout.get("arena_view_rect", new_layout.get("battlefield_rect", Rect2()))
	if arena_view_rect.size.x <= 0.0 or arena_view_rect.size.y <= 0.0:
		return false

	battlefield = new_battlefield
	region_map = new_region_map
	bullet_pool = new_bullet_pool
	turrets = new_turrets.duplicate(false)
	layout = new_layout.duplicate(true)
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
	return ARENA_Z_SCALE / ARENA_X_SCALE


func get_checker_cell_span_for_test() -> int:
	return CHECKER_CELL_SPAN


func get_bullet_proxy_count_for_test() -> int:
	return _bullet_proxies.size()


func get_background_color_for_test() -> Color:
	return arena_environment.background_color if arena_environment != null else Color.BLACK


func get_territory_color_for_test(owner_id: int, cell: Vector2i = Vector2i.ZERO) -> Color:
	return _tile_color(owner_id, RegionTypeScript.NORMAL, cell)


func simulation_to_world_for_test(simulation_position: Vector2, height: float = 0.0) -> Vector3:
	return _simulation_to_world(simulation_position, height)


func _process(_delta: float) -> void:
	if battlefield == null or not is_instance_valid(battlefield):
		visible = false
		set_process(false)
		return
	if _tiles_dirty:
		_refresh_tile_colors()
		_tiles_dirty = false
	_sync_turrets()
	_sync_bullets()
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
	arena_environment.background_color = Color(0.69, 0.79, 0.76)
	arena_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	arena_environment.ambient_light_color = Color(0.94, 0.95, 0.84)
	arena_environment.ambient_light_energy = 1.02
	environment_node.environment = arena_environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color(1.0, 0.96, 0.84)
	key_light.light_energy = 1.42
	key_light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	key_light.shadow_enabled = false
	world_root.add_child(key_light)

	var grid: float = float(battlefield.grid_size)
	var arena_width: float = grid * ARENA_X_SCALE
	var arena_depth: float = grid * ARENA_Z_SCALE
	var outer_floor := MeshInstance3D.new()
	outer_floor.name = "ArenaGroundBase"
	var outer_box := BoxMesh.new()
	outer_box.size = Vector3(arena_width + 18.0, 0.64, arena_depth + 18.0)
	outer_floor.mesh = outer_box
	outer_floor.position.y = -0.48
	outer_floor.material_override = _make_material(Color(0.25, 0.39, 0.23), 0.0)
	world_root.add_child(outer_floor)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "ArenaFloor"
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(arena_width + 10.0, 0.42, arena_depth + 10.0)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.24
	floor_mesh.material_override = _make_material(Color(0.42, 0.55, 0.27), 0.0)
	world_root.add_child(floor_mesh)
	_build_lane_paths(grid)
	_build_edge_landscape(grid, arena_width)
	_build_river_and_bridges(grid, arena_width)

	camera = Camera3D.new()
	camera.name = "OrthographicCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = grid * 1.40
	camera.near = 0.1
	camera.far = grid * 5.0
	camera.look_at_from_position(
		Vector3(0.0, grid * 1.30, arena_depth * 0.76),
		Vector3(0.0, 0.0, -0.5),
		Vector3.UP
	)
	camera.current = true
	world_root.add_child(camera)


func _build_tiles() -> void:
	tile_multimesh = MultiMeshInstance3D.new()
	tile_multimesh.name = "TerritoryTiles"
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(ARENA_X_SCALE - TILE_GAP, TILE_HEIGHT, ARENA_Z_SCALE - TILE_GAP)
	var tile_material := StandardMaterial3D.new()
	tile_material.vertex_color_use_as_albedo = true
	tile_material.roughness = 0.72
	tile_material.metallic = 0.06
	tile_mesh.material = tile_material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = tile_mesh
	multimesh.instance_count = int(battlefield.grid_size) * int(battlefield.grid_size)
	tile_multimesh.multimesh = multimesh
	world_root.add_child(tile_multimesh)

	var grid: int = int(battlefield.grid_size)
	for x in range(grid):
		for y in range(grid):
			var index: int = x * grid + y
			var transform := Transform3D(Basis.IDENTITY, Vector3(
				(float(x) + 0.5 - float(grid) * 0.5) * ARENA_X_SCALE,
				TILE_HEIGHT * 0.5,
				(float(y) + 0.5 - float(grid) * 0.5) * ARENA_Z_SCALE
			))
			multimesh.set_instance_transform(index, transform)


func _build_territory_boundaries() -> void:
	territory_boundary_multimesh = MultiMeshInstance3D.new()
	territory_boundary_multimesh.name = "TerritoryBoundaries"
	var boundary_mesh := BoxMesh.new()
	boundary_mesh.size = Vector3.ONE
	boundary_mesh.material = _make_material(OUTLINE_COLOR, 0.0)

	var grid: int = int(battlefield.grid_size)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = boundary_mesh
	multimesh.instance_count = 2 * grid * (grid + 1)
	multimesh.visible_instance_count = 0
	territory_boundary_multimesh.multimesh = multimesh
	world_root.add_child(territory_boundary_multimesh)


func _refresh_territory_boundaries() -> void:
	if territory_boundary_multimesh == null or territory_boundary_multimesh.multimesh == null:
		return
	var grid: int = int(battlefield.grid_size)
	var index: int = 0
	var x_thickness: float = 0.36
	var z_thickness: float = 0.30
	var boundary_height: float = 0.24
	var boundary_y: float = TILE_HEIGHT + boundary_height * 0.5

	for x in range(grid):
		index = _set_boundary_instance(
			index,
			Vector3((float(x) + 0.5 - float(grid) * 0.5) * ARENA_X_SCALE, boundary_y, -float(grid) * 0.5 * ARENA_Z_SCALE),
			Vector3(ARENA_X_SCALE + x_thickness, boundary_height, z_thickness)
		)
		index = _set_boundary_instance(
			index,
			Vector3((float(x) + 0.5 - float(grid) * 0.5) * ARENA_X_SCALE, boundary_y, float(grid) * 0.5 * ARENA_Z_SCALE),
			Vector3(ARENA_X_SCALE + x_thickness, boundary_height, z_thickness)
		)
	for y in range(grid):
		index = _set_boundary_instance(
			index,
			Vector3(-float(grid) * 0.5 * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(grid) * 0.5) * ARENA_Z_SCALE),
			Vector3(x_thickness, boundary_height, ARENA_Z_SCALE + z_thickness)
		)
		index = _set_boundary_instance(
			index,
			Vector3(float(grid) * 0.5 * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(grid) * 0.5) * ARENA_Z_SCALE),
			Vector3(x_thickness, boundary_height, ARENA_Z_SCALE + z_thickness)
		)

	for x in range(grid):
		for y in range(grid):
			var owner_id: int = int(battlefield.owners[x][y])
			if x + 1 < grid and int(battlefield.owners[x + 1][y]) != owner_id:
				index = _set_boundary_instance(
					index,
					Vector3((float(x) + 1.0 - float(grid) * 0.5) * ARENA_X_SCALE, boundary_y, (float(y) + 0.5 - float(grid) * 0.5) * ARENA_Z_SCALE),
					Vector3(x_thickness, boundary_height, ARENA_Z_SCALE + z_thickness)
				)
			if y + 1 < grid and int(battlefield.owners[x][y + 1]) != owner_id:
				index = _set_boundary_instance(
					index,
					Vector3((float(x) + 0.5 - float(grid) * 0.5) * ARENA_X_SCALE, boundary_y, (float(y) + 1.0 - float(grid) * 0.5) * ARENA_Z_SCALE),
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

	var grid: int = int(battlefield.grid_size)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = marker_mesh
	multimesh.instance_count = grid * grid
	multimesh.visible_instance_count = 0
	sparse_claim_multimesh.multimesh = multimesh
	world_root.add_child(sparse_claim_multimesh)


func _refresh_sparse_claim_markers() -> void:
	if sparse_claim_multimesh == null or sparse_claim_multimesh.multimesh == null:
		return
	var grid: int = int(battlefield.grid_size)
	var marker_index: int = 0
	for x in range(grid):
		for y in range(grid):
			var owner_id: int = int(battlefield.owners[x][y])
			if owner_id == CardfrontRulesScript.NEUTRAL_OWNER:
				continue
			var cell := Vector2i(x, y)
			if _same_owner_neighbor_count(cell, owner_id, grid) > 1:
				continue
			var center := Vector3(
				(float(x) + 0.5 - float(grid) * 0.5) * ARENA_X_SCALE,
				TILE_HEIGHT + 0.25,
				(float(y) + 0.5 - float(grid) * 0.5) * ARENA_Z_SCALE
			)
			var basis := Basis(Vector3.UP, PI * 0.25).scaled(Vector3(0.62, 0.18, 0.62))
			sparse_claim_multimesh.multimesh.set_instance_transform(marker_index, Transform3D(basis, center))
			sparse_claim_multimesh.multimesh.set_instance_color(
				marker_index,
				_arena_faction_color(owner_id).lightened(0.24)
			)
			marker_index += 1
	sparse_claim_multimesh.multimesh.visible_instance_count = marker_index


func _same_owner_neighbor_count(cell: Vector2i, owner_id: int, grid: int) -> int:
	var count: int = 0
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + direction
		if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= grid or neighbor.y >= grid:
			continue
		if int(battlefield.owners[neighbor.x][neighbor.y]) == owner_id:
			count += 1
	return count


func _set_boundary_instance(index: int, center: Vector3, size: Vector3) -> int:
	var transform := Transform3D(Basis.IDENTITY.scaled(size), center)
	territory_boundary_multimesh.multimesh.set_instance_transform(index, transform)
	return index + 1


func _build_lane_paths(grid: float) -> void:
	var lane_offset: float = grid * 0.235 * ARENA_X_SCALE
	for lane_x in [-lane_offset, lane_offset]:
		var lane := MeshInstance3D.new()
		lane.name = "ArenaLane"
		var lane_mesh := BoxMesh.new()
		lane_mesh.size = Vector3(3.0, 0.10, (grid - 3.0) * ARENA_Z_SCALE)
		lane.mesh = lane_mesh
		lane.position = Vector3(lane_x, TILE_HEIGHT + 0.035, 0.0)
		lane.material_override = _make_material(PATH_COLOR, 0.0)
		world_root.add_child(lane)


func _build_edge_landscape(grid: float, arena_width: float) -> void:
	var z_positions: Array[float] = [-0.40, -0.27, -0.13, 0.04, 0.20, 0.36]
	for side in [-1.0, 1.0]:
		for index in range(z_positions.size()):
			var bush := MeshInstance3D.new()
			bush.name = "EdgeBush"
			var bush_mesh := SphereMesh.new()
			bush_mesh.radius = 1.55
			bush_mesh.height = 2.70
			bush_mesh.radial_segments = 10
			bush_mesh.rings = 5
			bush.mesh = bush_mesh
			bush.position = Vector3(
				side * (arena_width * 0.5 + 4.0 + float(index % 2) * 0.5),
				1.12,
				grid * z_positions[index] * ARENA_Z_SCALE
			)
			bush.scale = Vector3(1.20, 0.92 + float(index % 3) * 0.08, 1.0)
			var bush_color := Color(0.27, 0.48, 0.22) if index % 2 == 0 else Color(0.34, 0.55, 0.24)
			bush.material_override = _make_material(bush_color, 0.0)
			world_root.add_child(bush)


func _build_river_and_bridges(grid: float, arena_width: float) -> void:
	var river := MeshInstance3D.new()
	river.name = "CentralRiver"
	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(arena_width + 10.0, 0.13, 2.9 * ARENA_Z_SCALE)
	river.mesh = river_mesh
	river.position.y = 0.13
	river.material_override = _make_material(Color(0.20, 0.58, 0.68), 0.10)
	world_root.add_child(river)

	for bank_z in [-1.72 * ARENA_Z_SCALE, 1.72 * ARENA_Z_SCALE]:
		var bank := MeshInstance3D.new()
		bank.name = "RiverBank"
		var bank_mesh := BoxMesh.new()
		bank_mesh.size = Vector3(arena_width + 10.0, 0.24, 0.55 * ARENA_Z_SCALE)
		bank.mesh = bank_mesh
		bank.position = Vector3(0.0, 0.18, bank_z)
		bank.material_override = _make_material(Color(0.30, 0.40, 0.23), 0.0)
		world_root.add_child(bank)

	var bridge_offset: float = grid * 0.235 * ARENA_X_SCALE
	var bridge_positions: Array[float] = [-bridge_offset, bridge_offset]
	for bridge_index in range(BRIDGE_COUNT):
		var bridge_x: float = bridge_positions[bridge_index]
		var bridge_base := MeshInstance3D.new()
		bridge_base.name = "BridgeBase"
		var bridge_base_mesh := BoxMesh.new()
		bridge_base_mesh.size = Vector3(6.8, 0.48, 5.2 * ARENA_Z_SCALE)
		bridge_base.mesh = bridge_base_mesh
		bridge_base.position = Vector3(bridge_x, 0.31, 0.0)
		bridge_base.material_override = _make_material(Color(0.27, 0.25, 0.20), 0.0)
		world_root.add_child(bridge_base)

		var bridge_top := MeshInstance3D.new()
		bridge_top.name = "BridgeTop"
		var bridge_top_mesh := BoxMesh.new()
		bridge_top_mesh.size = Vector3(6.2, 0.30, 4.7 * ARENA_Z_SCALE)
		bridge_top.mesh = bridge_top_mesh
		bridge_top.position = Vector3(bridge_x, 0.62, 0.0)
		bridge_top.material_override = _make_material(Color(0.62, 0.43, 0.24), 0.0)
		world_root.add_child(bridge_top)
		_bridge_tops.append(bridge_top)
		_build_gate_visual(bridge_x)


func _build_gate_visual(bridge_x: float) -> void:
	for post_offset in [-3.15, 3.15]:
		var post := MeshInstance3D.new()
		post.name = "GatePost"
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.62, 2.5, 0.86 * ARENA_Z_SCALE)
		post.mesh = post_mesh
		post.position = Vector3(bridge_x + post_offset, 1.70, 0.0)
		post.material_override = _make_material(Color(0.24, 0.32, 0.31), 0.0)
		world_root.add_child(post)

		var cap := MeshInstance3D.new()
		cap.name = "GatePostCap"
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(0.86, 0.36, 1.10 * ARENA_Z_SCALE)
		cap.mesh = cap_mesh
		cap.position = Vector3(bridge_x + post_offset, 3.10, 0.0)
		cap.material_override = _make_material(Color(1.0, 0.72, 0.20), 0.08)
		world_root.add_child(cap)

	var bar := MeshInstance3D.new()
	bar.name = "GateBar"
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(6.15, 0.46, 0.52 * ARENA_Z_SCALE)
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
	label.font_size = 40
	label.outline_size = 14
	label.pixel_size = 0.018
	label.position = Vector3(bridge_x, 4.05, 0.0)
	label.modulate = Color(1.0, 0.92, 0.58)
	world_root.add_child(label)
	_gate_labels.append(label)
	_refresh_gate_visual(_gate_bars.size() - 1)


func _refresh_gate_visual(lane_index: int) -> void:
	var openness: float = _gate_openness[lane_index]
	var bridge_x: float = _bridge_tops[lane_index].position.x
	var bar: MeshInstance3D = _gate_bars[lane_index]
	bar.position = Vector3(bridge_x, lerpf(1.12, 3.35, openness), 0.0)
	var label: Label3D = _gate_labels[lane_index]
	var gate_state: Dictionary = _gate_states[lane_index] if lane_index < _gate_states.size() else {}
	var state_text: String = "\u5173\u95ed"
	if openness >= 0.80:
		state_text = "\u5f00\u542f"
	elif openness > 0.20:
		state_text = "\u534a\u5f00"
	var owner_id: int = int(gate_state.get("owner_id", CardfrontRulesScript.NEUTRAL_OWNER))
	var owner_text: String = "\u4e2d\u7acb"
	var bar_color := Color(0.95, 0.30, 0.26)
	if owner_id == CardfrontRulesScript.PLAYER_FACTION:
		owner_text = "\u84dd\u65b9"
		bar_color = PLAYER_TINT.lightened(0.12)
	elif owner_id == CardfrontRulesScript.AI_FACTION:
		owner_text = "\u7ea2\u65b9"
		bar_color = AI_TINT.lightened(0.12)
	bar.material_override = _make_material(bar_color, 0.08)
	label.text = "\u95f8\u95e8%d %s\u63a7 %s" % [lane_index + 1, owner_text, state_text]


func _build_stronghold_platforms() -> void:
	for region_id_value in region_map.get_controllable_region_ids():
		var region_id: int = int(region_id_value)
		var cells: Array = region_map.get_region_cells(region_id)
		if cells.is_empty():
			continue
		var bounds := _cell_bounds(cells)
		var center_cell: Vector2 = bounds.position + bounds.size * 0.5
		var center_world := Vector3(
			(center_cell.x - float(battlefield.grid_size) * 0.5) * ARENA_X_SCALE,
			0.0,
			(center_cell.y - float(battlefield.grid_size) * 0.5) * ARENA_Z_SCALE
		)

		var platform_shadow := MeshInstance3D.new()
		platform_shadow.name = "StrongholdShadow_%s" % region_id
		var shadow_mesh := BoxMesh.new()
		shadow_mesh.size = Vector3(bounds.size.x * ARENA_X_SCALE + 0.72, 0.46, bounds.size.y * ARENA_Z_SCALE + 0.72)
		platform_shadow.mesh = shadow_mesh
		platform_shadow.position = center_world + Vector3(0.0, 0.28, 0.0)
		platform_shadow.material_override = _make_material(Color(0.16, 0.25, 0.24), 0.0)
		world_root.add_child(platform_shadow)

		var platform := MeshInstance3D.new()
		platform.name = "StrongholdPlatform_%s" % region_id
		var platform_mesh := BoxMesh.new()
		platform_mesh.size = Vector3(bounds.size.x * ARENA_X_SCALE + 0.18, 0.44, bounds.size.y * ARENA_Z_SCALE + 0.18)
		platform.mesh = platform_mesh
		platform.position = center_world + Vector3(0.0, 0.56, 0.0)
		platform.material_override = _make_material(_region_accent(str(region_map.get_region_type_by_id(region_id))).lightened(0.08), 0.06)
		world_root.add_child(platform)
		_region_platforms[region_id] = platform


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
	var grid: int = int(battlefield.grid_size)
	if not (battlefield.owners is Array) or battlefield.owners.size() != grid:
		return
	for x in range(grid):
		if not (battlefield.owners[x] is Array):
			continue
		for y in range(grid):
			var owner_id: int = int(battlefield.owners[x][y])
			var region_type: String = str(region_map.get_region_type(Vector2i(x, y)))
			tile_multimesh.multimesh.set_instance_color(x * grid + y, _tile_color(owner_id, region_type, Vector2i(x, y)))
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
		label.font_size = 62
		label.outline_size = 20
		label.pixel_size = 0.022
		label.position = Vector3(
			(center.x - float(battlefield.grid_size) * 0.5) * ARENA_X_SCALE,
			1.18,
			(center.y - float(battlefield.grid_size) * 0.5) * ARENA_Z_SCALE
		)
		world_root.add_child(label)
		_region_labels[region_id] = label


func _refresh_region_labels() -> void:
	for region_id in _region_labels.keys():
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, int(region_id))
		var leader: Dictionary = _get_region_leader(control)
		var region_type: String = str(control.get("region_type", RegionTypeScript.NORMAL))
		var label: Label3D = _region_labels[region_id]
		label.text = "%s\n%d%%" % [
			StrongholdRulesScript.badge_name(region_type),
			int(leader.percent),
		]
		var leader_id: int = int(leader.owner_id)
		label.modulate = (
			Color.WHITE
			if leader_id == CardfrontRulesScript.NEUTRAL_OWNER
			else _arena_faction_color(leader_id).lightened(0.28)
		)


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
		var chamber_mesh := BoxMesh.new()
		chamber_mesh.size = Vector3(8.6, 1.12, 5.2)
		chamber.mesh = chamber_mesh
		chamber.position.y = 0.58
		chamber.material_override = _get_faction_material(int(owner_id), 0.10)
		proxy.add_child(chamber)

		var turret_base := MeshInstance3D.new()
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 1.32
		base_mesh.bottom_radius = 1.62
		base_mesh.height = 1.02
		turret_base.mesh = base_mesh
		turret_base.position.y = 1.42
		turret_base.material_override = _get_faction_material(int(owner_id), 0.24)
		proxy.add_child(turret_base)

		var barrel := MeshInstance3D.new()
		barrel.name = "Barrel"
		var barrel_mesh := BoxMesh.new()
		barrel_mesh.size = Vector3(4.2, 0.54, 0.82)
		barrel.mesh = barrel_mesh
		barrel.position = Vector3(1.92, 1.88, 0.0)
		barrel.material_override = _make_material(Color(0.95, 0.97, 0.98), 0.22)
		proxy.add_child(barrel)

		var label := Label3D.new()
		label.name = "HealthLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font = ThemeDB.fallback_font
		label.font_size = 52
		label.outline_size = 15
		label.pixel_size = 0.020
		label.position = Vector3(0.0, 3.36, 0.0)
		label.modulate = Color.WHITE
		proxy.add_child(label)
		_turret_proxies[int(owner_id)] = proxy
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
		proxy.rotation.y = -float(turret.rotation)
		var health: int = int(turret.health)
		var max_health: int = maxi(1, int(turret.max_health))
		var label: Label3D = _chamber_labels[owner_id]
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
		proxy.visible = true
		proxy.position = _simulation_to_world(bullet.global_position, 0.58)
		proxy.material_override = _get_faction_material(int(bullet.faction_id), 0.62)
		var radius: float = 0.24
		if bullet.has_method("get_visual_radius"):
			radius = clampf(float(bullet.get_visual_radius()) / maxf(1.0, float(battlefield.cell_size)), 0.18, 0.44)
		proxy.scale = Vector3.ONE * radius


func _ensure_bullet_proxies(required_count: int) -> void:
	if _bullet_mesh == null:
		_bullet_mesh = SphereMesh.new()
		_bullet_mesh.radius = 0.72
		_bullet_mesh.height = 1.44
		_bullet_mesh.radial_segments = 12
		_bullet_mesh.rings = 6
	while _bullet_proxies.size() < required_count:
		var proxy := MeshInstance3D.new()
		proxy.name = "BulletProxy_%03d" % _bullet_proxies.size()
		proxy.mesh = _bullet_mesh
		world_root.add_child(proxy)
		_bullet_proxies.append(proxy)


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
	var direction_3d := Vector3(direction_2d.x * ARENA_X_SCALE, 0.0, direction_2d.y * ARENA_Z_SCALE).normalized()
	var length: float = float(battlefield.grid_size) * 0.42
	_aim_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _aim_material)
	_aim_mesh.surface_add_vertex(origin + direction_3d * 1.4)
	_aim_mesh.surface_add_vertex(origin + direction_3d * length)
	_aim_mesh.surface_end()


func _simulation_to_world(simulation_position: Vector2, height: float) -> Vector3:
	var local: Vector2 = simulation_position - battlefield.global_position
	var cell_size: float = maxf(1.0, float(battlefield.cell_size))
	var grid: float = float(battlefield.grid_size)
	return Vector3(
		(local.x / cell_size - grid * 0.5) * ARENA_X_SCALE,
		height,
		(local.y / cell_size - grid * 0.5) * ARENA_Z_SCALE
	)


func _tile_color(owner_id: int, region_type: String, cell: Vector2i) -> Color:
	var checker_index: int = floori(float(cell.x) / float(CHECKER_CELL_SPAN)) + floori(float(cell.y) / float(CHECKER_CELL_SPAN))
	var owner_color: Color = GRASS_LIGHT if checker_index % 2 == 0 else GRASS_DARK
	if owner_id != CardfrontRulesScript.NEUTRAL_OWNER:
		owner_color = owner_color.lerp(_arena_faction_color(owner_id), 0.38)
	var accent: Color = _region_accent(region_type)
	if region_type != RegionTypeScript.NORMAL:
		owner_color = owner_color.lerp(accent, 0.18).lightened(0.04)
	return Color(owner_color.r, owner_color.g, owner_color.b, 1.0)


func _region_accent(region_type: String) -> Color:
	match region_type:
		RegionTypeScript.ENERGY:
			return Color(0.27, 0.55, 0.58)
		RegionTypeScript.FACTORY:
			return Color(0.68, 0.50, 0.22)
		RegionTypeScript.LAB:
			return Color(0.45, 0.39, 0.54)
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
