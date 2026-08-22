extends SceneTree

const ValidatorScript = preload("res://scripts/cardfront/environment/CardfrontFormalAssetValidator.gd")


func _initialize() -> void:
	var validator := ValidatorScript.new()
	for spec in [
		{"path": "res://assets/cardfront_environment/formal/bridge/bridge.glb", "contract": ValidatorScript.bridge_contract()},
		{"path": "res://assets/cardfront_environment/formal/gate/gate_frame.glb", "contract": ValidatorScript.gate_frame_contract()},
	]:
		var scene: PackedScene = load(str(spec["path"]))
		if scene == null:
			print("LOAD_FAIL ", spec["path"])
			continue
		var instance: Node3D = scene.instantiate()
		print("ROOT_NAME=", instance.name)
		for child in instance.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			var aabb := mesh.mesh.get_aabb()
			var to_world := mesh.global_transform if mesh.is_inside_tree() else mesh.transform
			print("MESH ", mesh.name, " basis_scale=", mesh.transform.basis.get_scale(), " aabb_pos=", aabb.position, " aabb_size=", aabb.size)
		var result: Dictionary = validator.validate_instance(instance, spec["contract"])
		print("VALID=", result.get("valid"), " errors=", result.get("errors"))
		instance.free()
	quit(0)
