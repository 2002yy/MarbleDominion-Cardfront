extends RefCounted
class_name CardfrontCaptureInterceptor

var fortify_layer = null


func setup(new_fortify_layer) -> void:
	fortify_layer = new_fortify_layer


func should_block_capture(
	cell: Vector2i,
	incoming_owner: int,
	current_owner: int,
	capture_context: Dictionary = {}
) -> bool:
	if incoming_owner == current_owner:
		return false
	if fortify_layer == null:
		return false
	var pierce_remaining: int = maxi(
		0,
		int(capture_context.get("armor_pierce_contacts_remaining", 0))
	)
	if pierce_remaining > 0 and fortify_layer.get_fortify_stack(cell) > 0:
		capture_context["armor_pierce_contacts_remaining"] = pierce_remaining - 1
		fortify_layer.consume_hit(cell)
		if fortify_layer.get_fortify_stack(cell) <= 0:
			return false
	return fortify_layer.consume_hit(cell)
