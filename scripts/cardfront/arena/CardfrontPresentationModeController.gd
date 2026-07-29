extends RefCounted
class_name CardfrontPresentationModeController


static func activate_orthographic(runtime) -> Array[String]:
	var hidden: Array[String] = []
	if runtime == null:
		return hidden
	var arena_view = runtime.orthographic_arena_view
	if arena_view == null or not is_instance_valid(arena_view):
		return hidden

	_hide_canvas_item(runtime.battlefield, "battlefield", hidden)
	_hide_canvas_item(runtime.region_overlay, "region_overlay", hidden)
	_hide_canvas_item(runtime.region_control_block_layer, "region_control_blocks", hidden)
	_hide_canvas_item(runtime.fortify_overlay, "fortify_overlay", hidden)
	_hide_canvas_item(runtime.arena_presentation_layer, "arena_presentation", hidden)
	_hide_canvas_item(runtime.aim_guide_layer, "aim_guide", hidden)
	_hide_canvas_item(runtime.target_preview_layer, "target_preview", hidden)
	_hide_canvas_item(runtime.device_overlay_layer, "device_overlay", hidden)
	_hide_canvas_item(runtime.cardfront_vfx_layer, "vfx_layer", hidden)

	for owner_id in runtime.turrets.keys():
		_hide_canvas_item(runtime.turrets[owner_id], "turret_%s" % str(owner_id), hidden)
	for owner_id in runtime.command_chambers.keys():
		_hide_canvas_item(runtime.command_chambers[owner_id], "command_chamber_%s" % str(owner_id), hidden)

	arena_view.visible = true
	return hidden


static func _hide_canvas_item(node, label: String, hidden: Array[String]) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is CanvasItem:
		node.visible = false
		hidden.append(label)
