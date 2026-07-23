extends CanvasLayer
class_name CardfrontOrthographicArenaView

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

const CANVAS_LAYER: int = 4
const MAX_BULLET_PROXIES: int = 256
const TILE_GAP: float = 0.08
const TILE_HEIGHT: float = 0.22
const SPECIAL_TILE_HEIGHT: float = 0.62

var battlefield = null
var region_map = null
var bullet_pool = null
var turrets: Dictionary = {}
var layout: Dictionary = {}

var viewport_container: SubViewportContainer
var world_viewport: SubViewport
var world_root: Node3D
var camera: Camera3D
var tile_multimesh: MultiMeshInstance3D
var aim_mesh_instance: MeshInstance3D

var _turret_proxies: Dictionary = {}
var _chamber_labels: Dictionary = {}
var _region_labels: Dictionary = {}
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
	var battlefield_rect: Rect2 = new_layout.get("battlefield_rect", Rect2())
	if battlefield_rect.size.x <= 0.0 or battlefield_rect.size.y <= 0.0:
		return false

	battlefield = new_battlefield
	region_map = new_region_map
	bullet_pool = new_bullet_pool
	turrets = new_turrets.duplicate(false)
	layout = new_layout.duplicate(true)
	_build_viewport(battlefield_rect)
	_build_world()
	_build_tiles()
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


func get_bullet_proxy_count_for_test() -> int:
	return _bullet_proxies.size()


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


func _build_viewport(battlefield_rect: Rect2) -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "ArenaViewportContainer"
	viewport_container.position = battlefield_rect.position
	viewport_container.size = battlefield_rect.size
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	add_child(viewport_container)

	world_viewport = SubViewport.new()
	world_viewport.name = "ArenaSubViewport"
	world_viewport.size = Vector2i(maxi(1, roundi(battlefield_rect.size.x)), maxi(1, roundi(battlefield_rect.size.y)))
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.gui_disable_input = true
	viewport_container.add_child(world_viewport)


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "ArenaWorld"
	world_viewport.add_child(world_root)

	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.028, 0.045)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.56, 0.64, 0.74)
	environment.ambient_light_energy = 0.72
	environment_node.environment = environment
	world_root.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color(0.82, 0.91, 1.0)
	key_light.light_energy = 1.25
	key_light.rotation_degrees = Vector3(-54.0, -32.0, 0.0)
	key_light.shadow_enabled = false
	world_root.add_child(key_light)

	var grid: float = float(battlefield.grid_size)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "ArenaFloor"
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(grid + 8.0, 0.42, grid + 8.0)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.30
	floor_mesh.material_override = _make_material(Color(0.035, 0.075, 0.105), 0.22)
	world_root.add_child(floor_mesh)

	camera = Camera3D.new()
	camera.name = "OrthographicCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = grid * 1.10
	camera.near = 0.1
	camera.far = grid * 5.0
	camera.look_at_from_position(
		Vector3(0.0, grid * 0.76, grid * 1.08),
		Vector3(0.0, 0.0, 0.0),
		Vector3.UP
	)
	camera.current = true
	world_root.add_child(camera)


func _build_tiles() -> void:
	tile_multimesh = MultiMeshInstance3D.new()
	tile_multimesh.name = "TerritoryTiles"
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(1.0 - TILE_GAP, TILE_HEIGHT, 1.0 - TILE_GAP)
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
			var region_type: String = str(region_map.get_region_type(Vector2i(x, y)))
			var height: float = SPECIAL_TILE_HEIGHT if region_type != RegionTypeScript.NORMAL else TILE_HEIGHT
			var transform := Transform3D(Basis.IDENTITY, Vector3(
				float(x) + 0.5 - float(grid) * 0.5,
				height * 0.5,
				float(y) + 0.5 - float(grid) * 0.5
			))
			transform.basis = transform.basis.scaled(Vector3(1.0, height / TILE_HEIGHT, 1.0))
			multimesh.set_instance_transform(index, transform)


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
			tile_multimesh.multimesh.set_instance_color(x * grid + y, _tile_color(owner_id, region_type))
	_refresh_region_labels()


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
		label.font_size = 52
		label.outline_size = 16
		label.pixel_size = 0.024
		label.position = Vector3(
			center.x - float(battlefield.grid_size) * 0.5,
			SPECIAL_TILE_HEIGHT + 0.32,
			center.y - float(battlefield.grid_size) * 0.5
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
			else CardfrontRulesScript.owner_color(leader_id).lightened(0.34)
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
		chamber_mesh.size = Vector3(5.2, 0.72, 3.4)
		chamber.mesh = chamber_mesh
		chamber.position.y = 0.38
		chamber.material_override = _get_faction_material(int(owner_id), 0.10)
		proxy.add_child(chamber)

		var turret_base := MeshInstance3D.new()
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.95
		base_mesh.bottom_radius = 1.18
		base_mesh.height = 0.82
		turret_base.mesh = base_mesh
		turret_base.position.y = 0.98
		turret_base.material_override = _get_faction_material(int(owner_id), 0.24)
		proxy.add_child(turret_base)

		var barrel := MeshInstance3D.new()
		barrel.name = "Barrel"
		var barrel_mesh := BoxMesh.new()
		barrel_mesh.size = Vector3(3.0, 0.42, 0.64)
		barrel.mesh = barrel_mesh
		barrel.position = Vector3(1.35, 1.35, 0.0)
		barrel.material_override = _make_material(Color(0.88, 0.93, 0.98), 0.42)
		proxy.add_child(barrel)

		var label := Label3D.new()
		label.name = "HealthLabel"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font = ThemeDB.fallback_font
		label.font_size = 46
		label.outline_size = 12
		label.pixel_size = 0.021
		label.position = Vector3(0.0, 2.75, 0.0)
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
	var direction_3d := Vector3(direction_2d.x, 0.0, direction_2d.y)
	var length: float = float(battlefield.grid_size) * 0.42
	_aim_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _aim_material)
	_aim_mesh.surface_add_vertex(origin + direction_3d * 1.4)
	_aim_mesh.surface_add_vertex(origin + direction_3d * length)
	_aim_mesh.surface_end()


func _simulation_to_world(simulation_position: Vector2, height: float) -> Vector3:
	var local: Vector2 = simulation_position - battlefield.global_position
	var cell_size: float = maxf(1.0, float(battlefield.cell_size))
	var grid: float = float(battlefield.grid_size)
	return Vector3(local.x / cell_size - grid * 0.5, height, local.y / cell_size - grid * 0.5)


func _tile_color(owner_id: int, region_type: String) -> Color:
	var owner_color: Color
	if owner_id == CardfrontRulesScript.NEUTRAL_OWNER:
		owner_color = Color(0.18, 0.22, 0.29)
	else:
		owner_color = GameConfig.faction_color(owner_id).darkened(0.18)
	var accent: Color = _region_accent(region_type)
	if region_type != RegionTypeScript.NORMAL:
		owner_color = owner_color.lerp(accent, 0.36).lightened(0.08)
	return Color(owner_color.r, owner_color.g, owner_color.b, 1.0)


func _region_accent(region_type: String) -> Color:
	match region_type:
		RegionTypeScript.ENERGY:
			return Color(0.18, 0.92, 1.0)
		RegionTypeScript.FACTORY:
			return Color(1.0, 0.72, 0.20)
		RegionTypeScript.LAB:
			return Color(0.73, 0.42, 1.0)
		_:
			return Color(0.32, 0.38, 0.46)


func _get_faction_material(owner_id: int, emission_energy: float) -> StandardMaterial3D:
	var key: String = "%d:%.2f" % [owner_id, emission_energy]
	if not _faction_materials.has(key):
		_faction_materials[key] = _make_material(GameConfig.faction_color(owner_id).lightened(0.08), emission_energy)
	return _faction_materials[key]


func _make_material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	material.metallic = 0.12
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
