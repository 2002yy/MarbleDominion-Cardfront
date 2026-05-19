extends RefCounted
class_name CardfrontCaptureInterceptor

var fortify_layer = null


func setup(new_fortify_layer) -> void:
	fortify_layer = new_fortify_layer


func should_block_capture(cell: Vector2i, incoming_owner: int, current_owner: int) -> bool:
	if incoming_owner == current_owner:
		return false
	if fortify_layer == null:
		return false
	return fortify_layer.consume_hit(cell)
