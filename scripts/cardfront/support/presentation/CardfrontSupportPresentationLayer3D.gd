extends Node3D
class_name CardfrontSupportPresentationLayer3D

const SupportVisualScript = preload(
	"res://scripts/cardfront/support/presentation/CardfrontSupportVisual3D.gd"
)

var _cell_to_world: Callable
var _visuals_by_support_id: Dictionary = {}
var presentation_update_count: int = 0
var visual_create_count: int = 0
var visual_dispose_count: int = 0


func setup(cell_to_world: Callable) -> bool:
	if not cell_to_world.is_valid():
		return false
	name = "CardfrontSupportPresentationLayer3D"
	_cell_to_world = cell_to_world
	return true


func sync_snapshots(snapshots: Array) -> void:
	var live_ids: Dictionary = {}
	for raw_snapshot in snapshots:
		if not raw_snapshot is Dictionary:
			continue
		var snapshot: Dictionary = raw_snapshot as Dictionary
		var support_id: String = str(snapshot.get("support_id", ""))
		var anchor_value = snapshot.get("anchor_cell", null)
		if support_id == "" or not anchor_value is Vector2i or live_ids.has(support_id):
			continue
		live_ids[support_id] = true
		var visual = _visuals_by_support_id.get(support_id, null)
		if visual == null or not is_instance_valid(visual):
			visual = SupportVisualScript.new()
			if not visual.setup(support_id):
				visual.free()
				continue
			add_child(visual)
			_visuals_by_support_id[support_id] = visual
			visual_create_count += 1
			visual.position = _cell_to_world.call(anchor_value as Vector2i, 0.18) as Vector3
		if visual.apply_snapshot(snapshot):
			presentation_update_count += 1

	for raw_support_id in _visuals_by_support_id.keys():
		var support_id: String = str(raw_support_id)
		if live_ids.has(support_id):
			continue
		var stale = _visuals_by_support_id[support_id]
		_visuals_by_support_id.erase(support_id)
		if stale != null and is_instance_valid(stale):
			stale.queue_free()
		visual_dispose_count += 1


func clear_visuals() -> void:
	for visual in _visuals_by_support_id.values():
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
			visual_dispose_count += 1
	_visuals_by_support_id.clear()


func get_visual(support_id: String):
	return _visuals_by_support_id.get(str(support_id), null)


func get_visual_count() -> int:
	return _visuals_by_support_id.size()


func get_support_ids() -> Array:
	var result: Array = _visuals_by_support_id.keys()
	result.sort()
	return result
