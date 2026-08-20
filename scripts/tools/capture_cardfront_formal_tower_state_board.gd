extends SceneTree

const EnvironmentAssetRegistryScript = preload(
	"res://scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd"
)

const OUTPUT_DIR := "res://artifacts/formal-tower-state-board"
const OUTPUT_IMAGE := "formal-tower-state-board.png"
const OUTPUT_MANIFEST := "formal-tower-state-board-manifest.json"
const BOARD_DESIGN_SIZE := Vector2i(1600, 1400)
const CARD_VIEWPORT_SIZE := Vector2i(500, 235)
const PLAYER_COLOR := Color(0.18, 0.46, 0.58)
const AI_COLOR := Color(0.58, 0.26, 0.26)

const STATES: Array[Dictionary] = [
	{"row": "阵营 + 等级 / FACTION + LEVEL", "title": "玩家  L1  HP4  ACTIVE", "faction": 0, "level": 1, "hp": 4, "state": "active"},
	{"row": "阵营 + 等级 / FACTION + LEVEL", "title": "AI  L2  HP4  ACTIVE", "faction": 1, "level": 2, "hp": 4, "state": "active"},
	{"row": "阵营 + 等级 / FACTION + LEVEL", "title": "玩家  L3  HP4  COUNTER", "faction": 0, "level": 3, "hp": 4, "state": "counter"},
	{"row": "损伤 / DAMAGE", "title": "玩家  HP3  LIGHT", "faction": 0, "level": 2, "hp": 3, "state": "active"},
	{"row": "损伤 / DAMAGE", "title": "AI  HP2  HEAVY", "faction": 1, "level": 2, "hp": 2, "state": "active"},
	{"row": "损伤 / DAMAGE", "title": "玩家  HP1  CRITICAL", "faction": 0, "level": 2, "hp": 1, "state": "active"},
	{"row": "运行状态 / OPERATION", "title": "玩家  ACTIVE", "faction": 0, "level": 2, "hp": 4, "state": "active"},
	{"row": "运行状态 / OPERATION", "title": "AI  UNPOWERED", "faction": 1, "level": 2, "hp": 4, "state": "unpowered"},
	{"row": "运行状态 / OPERATION", "title": "玩家  SUPPRESSED", "faction": 0, "level": 2, "hp": 4, "state": "suppressed"},
	{"row": "动作 / ACTION", "title": "AI  QUOTA EMPTY", "faction": 1, "level": 2, "hp": 4, "state": "quota_empty"},
	{"row": "动作 / ACTION", "title": "玩家  INTERCEPT PULSE", "faction": 0, "level": 2, "hp": 4, "state": "intercept"},
	{"row": "动作 / ACTION", "title": "AI  HP0  DEATH SNAPSHOT", "faction": 1, "level": 3, "hp": 0, "state": "destroyed"},
]

var _errors: Array[String] = []
var _manifest_entries: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Formal Tower state-board capture requires a rendering display; omit --headless")
		quit(1)
		return
	root.content_scale_size = BOARD_DESIGN_SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = BOARD_DESIGN_SIZE
	await _flush(2)
	_build_board()
	await _flush(8)

	var absolute_output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if dir_error != OK:
		push_error("Could not create Formal Tower state-board directory")
		quit(2)
		return
	var image_path := absolute_output_dir.path_join(OUTPUT_IMAGE)
	var image := root.get_texture().get_image()
	var image_error := image.save_png(image_path) if image != null else ERR_UNAVAILABLE
	if image_error != OK:
		_errors.append("state-board image write failed: %s" % error_string(image_error))
	var manifest := {
		"experiment": "P0-FT1 Formal Interceptor Tower deterministic state board",
		"status": "PASS" if _errors.is_empty() else "FAIL",
		"design_size": [BOARD_DESIGN_SIZE.x, BOARD_DESIGN_SIZE.y],
		"capture_size": [image.get_width(), image.get_height()] if image != null else [0, 0],
		"card_count": STATES.size(),
		"font_floor_px": 22,
		"states": _manifest_entries,
		"errors": _errors,
		"image": OUTPUT_IMAGE,
	}
	var manifest_error := _write_json(absolute_output_dir.path_join(OUTPUT_MANIFEST), manifest)
	if manifest_error != OK:
		_errors.append("state-board manifest write failed: %s" % error_string(manifest_error))

	if _errors.is_empty():
		print("[CardfrontFormalTowerStateBoard] PASS (12 deterministic states)")
		print("[CardfrontFormalTowerStateBoard] Image: %s" % image_path)
	else:
		for message in _errors:
			push_error(message)
	quit(0 if _errors.is_empty() else 3)


func _build_board() -> void:
	var background := ColorRect.new()
	background.color = Color("#10181d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var heading := Label.new()
	heading.position = Vector2(24, 14)
	heading.size = Vector2(1552, 42)
	heading.text = "P0-FT1  正式拦截塔状态板 / FORMAL INTERCEPTOR TOWER"
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("#f2f5e8"))
	root.add_child(heading)

	var subtitle := Label.new()
	subtitle.position = Vector2(25, 55)
	subtitle.size = Vector2(1550, 30)
	subtitle.text = "类型靠轮廓与大构件·阵营靠色带/核心·无持久小字依赖·每卡文字≥22px"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#aebdc2"))
	root.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(20, 94)
	grid.size = Vector2(1560, 1280)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	for specification in STATES:
		grid.add_child(_build_card(specification))


func _build_card(specification: Dictionary) -> Control:
	var faction_id := int(specification["faction"])
	var accent := PLAYER_COLOR if faction_id == 0 else AI_COLOR
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(512, 302)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#18252b")
	style.border_color = accent.lightened(0.16)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	panel.add_child(content)
	var row_label := Label.new()
	row_label.text = str(specification["row"])
	row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row_label.add_theme_font_size_override("font_size", 22)
	row_label.add_theme_color_override("font_color", Color("#9fb2b8"))
	content.add_child(row_label)
	var title := Label.new()
	title.text = str(specification["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", accent.lightened(0.34))
	content.add_child(title)

	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(CARD_VIEWPORT_SIZE)
	viewport_container.stretch = true
	content.add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = CARD_VIEWPORT_SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport_container.add_child(viewport)
	_build_card_world(viewport, specification)
	return panel


func _build_card_world(viewport: SubViewport, specification: Dictionary) -> void:
	var world := Node3D.new()
	viewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#27383d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.80, 0.86, 0.82)
	environment.ambient_light_energy = 0.44
	environment_node.environment = environment
	world.add_child(environment_node)
	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.94, 0.82)
	key_light.light_energy = 0.62
	key_light.rotation_degrees = Vector3(-54.0, -32.0, 0.0)
	key_light.shadow_enabled = true
	world.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.light_color = Color(0.50, 0.72, 0.92)
	fill_light.light_energy = 0.20
	fill_light.rotation_degrees = Vector3(-35.0, 142.0, 0.0)
	world.add_child(fill_light)
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(5.2, 0.12, 5.2)
	floor.mesh = floor_mesh
	floor.position.y = -0.08
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#405451")
	floor_material.roughness = 0.92
	floor.material_override = floor_material
	world.add_child(floor)

	var tower := _assemble_tower(int(specification["faction"]))
	if tower == null:
		_errors.append("could not assemble state-board Tower: %s" % specification["title"])
		return
	world.add_child(tower)
	var facts := _apply_state(tower, specification)
	_manifest_entries.append(facts)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.85
	camera.look_at_from_position(Vector3(4.4, 3.35, 6.2), Vector3(0.0, 1.32, 0.0), Vector3.UP)
	world.add_child(camera)
	camera.current = true


func _assemble_tower(faction_id: int) -> Node3D:
	var common_scene := EnvironmentAssetRegistryScript.load_scene("formal_tower_common")
	var function_scene := EnvironmentAssetRegistryScript.load_scene("formal_tower_interceptor")
	var theme_scene := EnvironmentAssetRegistryScript.load_scene("formal_tower_theme_castle")
	var damage_scene := EnvironmentAssetRegistryScript.load_scene("formal_tower_damage")
	if common_scene == null or function_scene == null or theme_scene == null or damage_scene == null:
		return null
	var tower := common_scene.instantiate() as Node3D
	for scene in [function_scene, theme_scene, damage_scene]:
		var module := (scene as PackedScene).instantiate() as Node3D
		if module == null:
			tower.free()
			return null
		tower.add_child(module)
	_apply_faction_materials(tower, faction_id)
	return tower


func _apply_faction_materials(tower: Node3D, faction_id: int) -> void:
	var tint := PLAYER_COLOR if faction_id == 0 else AI_COLOR
	for child in tower.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface_index) as BaseMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as BaseMaterial3D
			var role := source.resource_name.to_upper()
			var base := material.albedo_color
			if role.ends_with("__FACTION_PRIMARY"):
				material.albedo_color = tint
			elif role.ends_with("__FACTION_TRIM"):
				material.albedo_color = tint.darkened(0.35)
			elif role.ends_with("__OWNERSHIP"):
				material.albedo_color = tint.lightened(0.08)
			elif role.ends_with("__CORE"):
				material.albedo_color = Color(0.32, 0.90, 1.0)
				material.emission_enabled = true
				material.emission = Color(0.22, 0.82, 1.0)
				material.emission_energy_multiplier = 3.0
			elif role.ends_with("__METAL"):
				material.albedo_color = base.darkened(0.22)
				material.metallic = 0.72
				material.roughness = 0.38
			elif role.ends_with("__DAMAGE"):
				material.albedo_color = base.darkened(0.34)
			else:
				material.albedo_color = base.darkened(0.22)
			mesh_instance.set_surface_override_material(surface_index, material)


func _apply_state(tower: Node3D, specification: Dictionary) -> Dictionary:
	var level := int(specification["level"])
	var hp := int(specification["hp"])
	var state := str(specification["state"])
	var operational := not ["unpowered", "suppressed", "quota_empty", "counter", "destroyed"].has(state)
	var visible_plates := 0
	var visible_damage := 0
	var counter_flash_count := 0
	for child in tower.find_children("GEO_*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var min_level := _minimum_level(str(mesh.name))
		mesh.visible = min_level <= level and hp > 0
		if str(mesh.name).begins_with("GEO_InterceptPlate_"):
			mesh.visible = mesh.visible and operational
			if state == "intercept" and mesh.visible:
				_boost_emission(mesh, 4.4)
			if mesh.visible:
				visible_plates += 1
		elif str(mesh.name).begins_with("GEO_Counter") and state == "counter":
			_boost_emission(mesh, 4.8)
	if state == "counter":
		counter_flash_count = _add_counter_action_pose(tower)
	var status_core := tower.find_child("GEO_StatusCore", true, false) as MeshInstance3D
	if status_core != null:
		status_core.visible = hp > 0 and not ["unpowered", "suppressed"].has(state)
	for child in tower.find_children("DMG_*", "MeshInstance3D", true, false):
		var damage_mesh := child as MeshInstance3D
		damage_mesh.visible = _damage_state(str(damage_mesh.name)) == hp
		if damage_mesh.visible:
			visible_damage += 1
	var expected_plates := 0
	if operational:
		expected_plates = 2 if level == 1 else 3
	if visible_plates != expected_plates:
		_errors.append("%s expected %d visible plates, got %d" % [specification["title"], expected_plates, visible_plates])
	if hp < 4 and visible_damage == 0:
		_errors.append("%s should expose one or more damage meshes" % specification["title"])
	if hp == 0 and visible_damage < 5:
		_errors.append("%s should expose the five-piece readable rubble cluster" % specification["title"])
	if state == "counter" and counter_flash_count != 1:
		_errors.append("%s should expose one frozen counter muzzle flash" % specification["title"])
	return {
		"row": specification["row"],
		"title": specification["title"],
		"faction": int(specification["faction"]),
		"level": level,
		"hp": hp,
		"state": state,
		"visible_intercept_plates": visible_plates,
		"visible_damage_meshes": visible_damage,
		"counter_flash_count": counter_flash_count,
		"module_count": 4,
	}


func _minimum_level(node_name: String) -> int:
	if node_name.ends_with("_C"):
		return 2
	if node_name.begins_with("GEO_Counter"):
		return 3
	return 1


func _damage_state(node_name: String) -> int:
	if node_name.begins_with("DMG_Light"):
		return 3
	if node_name.begins_with("DMG_Heavy"):
		return 2
	if node_name.begins_with("DMG_Critical"):
		return 1
	if node_name.begins_with("DMG_Rubble"):
		return 0
	return 4


func _boost_emission(mesh: MeshInstance3D, energy: float) -> void:
	if mesh.mesh == null:
		return
	for surface_index in range(mesh.mesh.get_surface_count()):
		var source := mesh.get_active_material(surface_index) as BaseMaterial3D
		if source == null:
			continue
		var material := source.duplicate() as BaseMaterial3D
		material.emission_enabled = true
		material.emission = material.albedo_color.lightened(0.24)
		material.emission_energy_multiplier = energy
		mesh.set_surface_override_material(surface_index, material)


func _add_counter_action_pose(tower: Node3D) -> int:
	var pivot := tower.find_child("PIV_Turret", true, false) as Node3D
	var socket := tower.find_child("SOCKET_Muzzle", true, false) as Node3D
	if pivot == null or socket == null:
		return 0
	pivot.position.z -= 0.24
	var flash := MeshInstance3D.new()
	flash.name = "CounterMuzzleFlash_StateBoard"
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	mesh.radial_segments = 12
	mesh.rings = 4
	flash.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.74, 0.18, 0.96)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.46, 0.08)
	material.emission_energy_multiplier = 6.2
	flash.material_override = material
	flash.scale = Vector3(1.0, 0.72, 1.35)
	socket.add_child(flash)
	return 1


func _write_json(absolute_path: String, data: Dictionary) -> int:
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", false) + "\n")
	file.close()
	return OK


func _flush(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
