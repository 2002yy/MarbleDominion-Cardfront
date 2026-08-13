extends Node3D
class_name CardfrontSupportVisual3D

const ViewStateScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationViewState.gd"
)

const GROUND_HEIGHT: float = 0.035
const FLAG_HEIGHT: float = 0.78

var support_id: String = ""
var last_snapshot: Dictionary = {}
var update_count: int = 0
var _ground: MeshInstance3D
var _beacon: MeshInstance3D
var _flag: MeshInstance3D
var _progress_back: MeshInstance3D
var _progress_fill: MeshInstance3D
var _status_label: Label3D


func setup(stable_support_id: String) -> bool:
	if stable_support_id == "":
		return false
	support_id = str(stable_support_id)
	name = "SupportVisual_%s" % support_id
	_build_low_occlusion_visual()
	return true


func apply_snapshot(snapshot: Dictionary) -> bool:
	if str(snapshot.get("support_id", "")) != support_id:
		return false
	last_snapshot = snapshot.duplicate(true)
	update_count += 1
	var view_state: String = str(snapshot.get("derived_view_state", ViewStateScript.DISABLED_NEUTRAL))
	var owner_id: int = int(snapshot.get("claim_owner", -1))
	var capture_side: int = int(snapshot.get("capture_side", -1))
	var color: Color = _state_color(view_state, owner_id, capture_side)
	var progress: float = clampf(float(snapshot.get("capture_progress_normalized", 0.0)), 0.0, 1.0)
	_set_material(_ground, color, 0.34, true)
	_set_material(_beacon, color.lightened(0.18), 0.78, true)
	_set_material(_flag, color, 0.96, false)
	_status_label.text = _state_label(view_state, progress)
	_status_label.modulate = color.lightened(0.28)
	_progress_back.visible = view_state == ViewStateScript.CAPTURING or view_state == ViewStateScript.CONTESTED
	_progress_fill.visible = _progress_back.visible and progress > 0.0
	_progress_fill.scale.x = maxf(0.001, progress)
	_progress_fill.position.x = -0.42 * (1.0 - progress)
	_set_material(_progress_fill, color.lightened(0.25), 0.96, true)
	return true


func has_collision_nodes() -> bool:
	return _subtree_has_collision(self)


func _subtree_has_collision(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D:
			return true
		if _subtree_has_collision(child):
			return true
	return false


func _build_low_occlusion_visual() -> void:
	_ground = _mesh("GroundMark", CylinderMesh.new())
	var ground_mesh: CylinderMesh = _ground.mesh as CylinderMesh
	ground_mesh.top_radius = 0.54
	ground_mesh.bottom_radius = 0.54
	ground_mesh.height = 0.045
	ground_mesh.radial_segments = 24
	_ground.position.y = GROUND_HEIGHT

	_beacon = _mesh("LowBeacon", CylinderMesh.new())
	var beacon_mesh: CylinderMesh = _beacon.mesh as CylinderMesh
	beacon_mesh.top_radius = 0.10
	beacon_mesh.bottom_radius = 0.15
	beacon_mesh.height = 0.38
	beacon_mesh.radial_segments = 12
	_beacon.position = Vector3(0.0, 0.22, 0.0)

	_flag = _mesh("SmallFlag", BoxMesh.new())
	var flag_mesh: BoxMesh = _flag.mesh as BoxMesh
	flag_mesh.size = Vector3(0.42, 0.22, 0.035)
	_flag.position = Vector3(0.22, FLAG_HEIGHT, 0.0)

	_progress_back = _mesh("CaptureProgressBack", BoxMesh.new())
	var back_mesh: BoxMesh = _progress_back.mesh as BoxMesh
	back_mesh.size = Vector3(0.90, 0.035, 0.10)
	_progress_back.position = Vector3(0.0, 0.09, 0.62)
	_set_material(_progress_back, Color(0.03, 0.04, 0.05), 0.78, false)

	_progress_fill = _mesh("CaptureProgressFill", BoxMesh.new())
	var fill_mesh: BoxMesh = _progress_fill.mesh as BoxMesh
	fill_mesh.size = Vector3(0.84, 0.045, 0.075)
	_progress_fill.position = Vector3.ZERO + _progress_back.position + Vector3(0.0, 0.03, 0.0)

	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.no_depth_test = true
	_status_label.font = ThemeDB.fallback_font
	_status_label.font_size = 30
	_status_label.outline_size = 8
	_status_label.pixel_size = 0.018
	_status_label.render_priority = 2
	_status_label.position = Vector3(0.0, 1.08, 0.0)
	add_child(_status_label)


func _mesh(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _set_material(node: MeshInstance3D, color: Color, alpha: float, emission: bool) -> void:
	var material := StandardMaterial3D.new()
	var resolved: Color = color
	resolved.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = resolved
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b, 1.0)
		material.emission_energy_multiplier = 0.62
	node.material_override = material


func _state_color(view_state: String, owner_id: int, capture_side: int) -> Color:
	match view_state:
		ViewStateScript.CONTESTED:
			return Color(1.0, 0.58, 0.16)
		ViewStateScript.CAPTURING:
			return _owner_color(capture_side)
		ViewStateScript.ACTIVE:
			return _owner_color(owner_id)
		ViewStateScript.CAPTURED_OFFLINE:
			return _owner_color(owner_id).darkened(0.42)
		_:
			return Color(0.42, 0.46, 0.50)


func _owner_color(owner_id: int) -> Color:
	if owner_id >= GameConfig.Faction.BLUE and owner_id <= GameConfig.Faction.YELLOW:
		return GameConfig.faction_color(owner_id)
	return Color(0.58, 0.60, 0.62)


func _state_label(view_state: String, progress: float) -> String:
	match view_state:
		ViewStateScript.ACTIVE:
			return "在线"
		ViewStateScript.CAPTURING:
			return "占领 %d%%" % roundi(progress * 100.0)
		ViewStateScript.CONTESTED:
			return "争夺中"
		ViewStateScript.CAPTURED_OFFLINE:
			return "离线"
		_:
			return "中立"
