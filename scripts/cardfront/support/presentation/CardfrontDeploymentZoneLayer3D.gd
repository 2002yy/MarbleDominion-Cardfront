extends MultiMeshInstance3D
class_name CardfrontDeploymentZoneLayer3D

var _cell_to_world: Callable
var _cell_footprint: Vector2 = Vector2.ONE
var _visible_cells: Array[Vector2i] = []
var update_count: int = 0
var last_revision: int = -1


func setup(cell_to_world: Callable, cell_footprint: Vector2) -> bool:
	if not cell_to_world.is_valid() or cell_footprint.x <= 0.0 or cell_footprint.y <= 0.0:
		return false
	name = "CardfrontDeploymentZoneLayer3D"
	_cell_to_world = cell_to_world
	_cell_footprint = cell_footprint
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(_cell_footprint.x * 0.88, 0.025, _cell_footprint.y * 0.88)
	material_override = _make_material()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = marker_mesh
	multimesh.instance_count = 0
	multimesh.visible_instance_count = 0
	visible = false
	return true


func show_cells(cells: Array, revision: int = -1) -> void:
	var unique: Dictionary = {}
	for raw_cell in cells:
		if raw_cell is Vector2i:
			unique[raw_cell as Vector2i] = true
	_visible_cells.clear()
	for raw_cell in unique.keys():
		_visible_cells.append(raw_cell as Vector2i)
	_visible_cells.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		return left.y < right.y or (left.y == right.y and left.x < right.x)
	)
	last_revision = int(revision)
	update_count += 1
	multimesh.instance_count = _visible_cells.size()
	multimesh.visible_instance_count = _visible_cells.size()
	for index in range(_visible_cells.size()):
		var transform := Transform3D.IDENTITY
		transform.origin = _cell_to_world.call(_visible_cells[index], 0.205) as Vector3
		multimesh.set_instance_transform(index, transform)
	visible = not _visible_cells.is_empty()


func clear_zone() -> void:
	show_cells([], -1)


func get_visible_cells_for_test() -> Array[Vector2i]:
	return _visible_cells.duplicate()


func has_collision_authority() -> bool:
	return false


func _make_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.95, 0.56, 0.28)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.16, 0.78, 0.44)
	material.emission_energy_multiplier = 0.38
	return material
