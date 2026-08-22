extends SceneTree

const RegistryScript = preload("res://scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd")


func _initialize() -> void:
	var scene: PackedScene = RegistryScript.load_scene("formal_fortification")
	if scene == null:
		print("LOAD_FAIL")
		quit(1)
		return
	var inst: Node3D = scene.instantiate()
	root.add_child(inst)
	var null_count := 0
	for mesh_node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh_node as MeshInstance3D
		for s in range(mi.mesh.get_surface_count()):
			var override_mat := mi.get_surface_override_material(s)
			var active_mat := mi.get_active_material(s)
			var mesh_mat := mi.mesh.surface_get_material(s)
			if override_mat == null and active_mat == null:
				null_count += 1
				print("NULL_SURF ", mi.name, " surface=", s, " mesh_mat=", mesh_mat)
	print("NULL_COUNT=", null_count)
	inst.queue_free()
	quit(0)
