extends SceneTree

const TestAssert = preload("res://scripts/tests/TestAssert.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var t: TestAssert = TestAssert.new()
	print("[EventRouletteSceneTest] v2.0.8 — scene load verification")

	var scene_path: String = "res://scenes/ui/EventRouletteView.tscn"
	var resource = load(scene_path)
	t.that(resource != null, "scene loadable")
	if resource == null:
		quit(1)
		return

	var instance = resource.instantiate()
	t.that(instance != null, "instantiable")
	t.that(instance is Control, "root is Control")
	if instance == null:
		quit(1)
		return

	get_root().add_child(instance)
	await process_frame
	instance.setup(Vector2(1120, 720), {}, false)
	await process_frame

	t.that(instance.has_node("StagePanel"), "has StagePanel")
	var panel = instance.get_node("StagePanel")
	t.that(panel != null, "StagePanel not null")
	t.that(panel.has_node("HeaderLabel"), "has HeaderLabel")
	t.that(panel.has_node("LeftTitleLabel"), "has LeftTitleLabel")
	t.that(panel.has_node("RightTitleLabel"), "has RightTitleLabel")
	t.that(panel.has_node("LeftValueLabel"), "has LeftValueLabel")
	t.that(panel.has_node("RightValueLabel"), "has RightValueLabel")
	t.that(panel.has_node("LeftPointer"), "has LeftPointer")
	t.that(panel.has_node("RightPointer"), "has RightPointer")
	t.that(panel.has_node("ResultLabel"), "has ResultLabel")
	var stage_panel_count: int = 0
	for child in instance.get_children():
		if child.name == "StagePanel":
			stage_panel_count += 1
	t.eq(stage_panel_count, 1, "setup should reuse scene StagePanel")
	t.that(instance.stage_panel == panel, "setup binds the scene StagePanel")
	t.that(instance.header_label == panel.get_node("HeaderLabel"), "setup binds the scene header label")
	t.that(instance.left_pointer == panel.get_node("LeftPointer"), "setup binds the scene pointer")

	t.report("[EventRouletteSceneTest]")

	if t.failures.is_empty():
		quit(0)
	else:
		quit(1)
