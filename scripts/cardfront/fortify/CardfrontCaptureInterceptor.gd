extends RefCounted
class_name CardfrontCaptureInterceptor

var fortify_layer = null
var round_director = null
var territory_defense_system = null

func setup(new_fortify_layer) -> void:
	fortify_layer = new_fortify_layer

func configure_runtime(new_round_director, new_territory_defense_system) -> void:
	round_director = new_round_director
	territory_defense_system = new_territory_defense_system

func should_block_capture(cell: Vector2i, incoming_owner: int, current_owner: int, capture_context: Dictionary = {}) -> bool:
	if incoming_owner == current_owner or fortify_layer == null or fortify_layer.get_fortify_stack(cell) <= 0:
		return false
	var armor_pool = capture_context.get("armor_pierce_pool", null)
	if armor_pool is Dictionary and int((armor_pool as Dictionary).get("remaining", 0)) > 0:
		(armor_pool as Dictionary)["remaining"] = int((armor_pool as Dictionary)["remaining"]) - 1
		fortify_layer.consume_hit(cell)
		if fortify_layer.get_fortify_stack(cell) <= 0:
			return false
	elif maxi(0, int(capture_context.get("armor_pierce_contacts_remaining", 0))) > 0:
		capture_context["armor_pierce_contacts_remaining"] = int(capture_context["armor_pierce_contacts_remaining"]) - 1
		fortify_layer.consume_hit(cell)
		if fortify_layer.get_fortify_stack(cell) <= 0:
			return false
	var projectile_pierce: int = maxi(0, int(capture_context.get("projectile_defense_pierce_remaining", 0)))
	if projectile_pierce > 0 and fortify_layer.get_fortify_stack(cell) > 0:
		capture_context["projectile_defense_pierce_remaining"] = projectile_pierce - 1
		fortify_layer.consume_hit(cell)
		if fortify_layer.get_fortify_stack(cell) <= 0:
			return false
	return fortify_layer.consume_hit(cell)

func on_capture_applied(cell: Vector2i, incoming_owner: int, _current_owner: int, _capture_context: Dictionary = {}) -> void:
	if fortify_layer == null or round_director == null or territory_defense_system == null or not round_director.has_method("get_run_state"):
		return
	var run_state = round_director.get_run_state(int(incoming_owner))
	if run_state == null:
		return
	var captured_defense: int = clampi(int(run_state.captured_frontline_defense), 0, int(run_state.territory_defense_cap))
	if captured_defense > 0 and _is_frontline_cell(cell, incoming_owner):
		fortify_layer.set_fortify_stack(cell, captured_defense)

func _is_frontline_cell(cell: Vector2i, owner_id: int) -> bool:
	var battlefield = territory_defense_system.battlefield
	if battlefield == null or not is_instance_valid(battlefield):
		return false
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		if battlefield.is_inside(neighbor) and int(battlefield.owners[neighbor.x][neighbor.y]) != int(owner_id):
			return true
	return false
