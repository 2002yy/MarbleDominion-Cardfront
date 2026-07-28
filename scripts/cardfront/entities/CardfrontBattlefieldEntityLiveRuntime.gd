extends "res://scripts/cardfront/entities/CardfrontBattlefieldEntityRuntime.gd"
class_name CardfrontBattlefieldEntityLiveRuntime


func configure_dependencies(new_round_director, new_territory_defense_system) -> void:
	super.configure_dependencies(new_round_director, new_territory_defense_system)


func resolve_capture_contact(
	cell: Vector2i,
	incoming_owner_id: int,
	capture_context: Dictionary
) -> Dictionary:
	var result: Dictionary = super.resolve_capture_contact(
		cell,
		incoming_owner_id,
		capture_context
	)
	if bool(result.get("valid", false)):
		capture_context["entity_contact_cell_key"] = _cell_key(cell)
	return result


func _physics_process(_delta: float) -> void:
	_projectile_bridge.process_active_bullets(true)
