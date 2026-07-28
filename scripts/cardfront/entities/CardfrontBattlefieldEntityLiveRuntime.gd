extends "res://scripts/cardfront/entities/CardfrontBattlefieldEntityRuntime.gd"
class_name CardfrontBattlefieldEntityLiveRuntime

const RegistryClassScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const BattlefieldEntityClassScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")


func configure_dependencies(new_round_director, new_territory_defense_system) -> void:
	round_director = new_round_director
	territory_defense_system = new_territory_defense_system
	_resolve_bullet_pool()
	if round_director == null or not is_instance_valid(round_director):
		return
	if round_director.has_method("set_battlefield_entity_runtime"):
		round_director.set_battlefield_entity_runtime(self)
	var volley_callable := Callable(self, "_on_volley_launched")
	if round_director.has_signal("volley_launched") and not round_director.volley_launched.is_connected(volley_callable):
		round_director.volley_launched.connect(volley_callable)


func resolve_capture_contact(cell: Vector2i, incoming_owner_id: int, capture_context: Dictionary) -> Dictionary:
	var result: Dictionary = super.resolve_capture_contact(cell, incoming_owner_id, capture_context)
	if bool(result.get("valid", false)):
		capture_context["entity_contact_cell_key"] = _cell_key(cell)
	return result


func _physics_process(_delta: float) -> void:
	if bullet_pool == null or not is_instance_valid(bullet_pool):
		_resolve_bullet_pool()
	if bullet_pool == null or not is_instance_valid(bullet_pool) or not bullet_pool.has_method("get_active_bullets"):
		return
	for bullet in bullet_pool.get_active_bullets():
		if bullet == null or not is_instance_valid(bullet) or not bool(bullet.get("is_active")):
			continue
		var context: Dictionary = bullet.capture_context
		context["projectile_direction"] = bullet.direction
		var cell: Vector2i = battlefield.world_to_cell(bullet.global_position)
		if battlefield.is_inside(cell):
			var cell_key: String = _cell_key(cell)
			if str(context.get("entity_contact_cell_key", "")) != cell_key:
				if registry.get_collision_targets(cell, int(bullet.faction_id)).is_empty():
					context.erase("entity_contact_cell_key")
				else:
					resolve_capture_contact(cell, int(bullet.faction_id), context)

		if bool(context.get("entity_consume_projectile", false)):
			context.erase("entity_consume_projectile")
			context.erase("entity_bounce_direction")
			if bullet.has_method("_despawn"):
				bullet.call("_despawn")
			continue
		if context.has("entity_bounce_direction"):
			var bounce_direction: Vector2 = context.get("entity_bounce_direction", Vector2.RIGHT) as Vector2
			context.erase("entity_bounce_direction")
			if bounce_direction.length() > 0.001:
				bullet.direction = bounce_direction.normalized()
		_apply_fire_control_guidance(bullet)
		context["projectile_direction"] = bullet.direction


func _resolve_bullet_pool() -> void:
	bullet_pool = null
	if round_director == null or not is_instance_valid(round_director):
		return
	var turret_map = round_director.get("turrets")
	if not (turret_map is Dictionary):
		return
	for turret in (turret_map as Dictionary).values():
		if turret == null or not is_instance_valid(turret):
			continue
		var candidate = turret.get("bullet_container")
		if candidate != null and is_instance_valid(candidate) and candidate.has_method("get_active_bullets"):
			bullet_pool = candidate
			return


func _next_owned_step_toward(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_distance: int = _manhattan_distance(origin, target)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if not battlefield.is_inside(candidate):
			continue
		if int(battlefield.owners[candidate.x][candidate.y]) != int(owner_id):
			continue
		var occupied_creature_slots: int = 0
		for entity in registry.get_entities_at(candidate):
			if str(entity.entity_kind) == BattlefieldEntityClassScript.KIND_CREATURE:
				occupied_creature_slots += maxi(1, int(entity.size_slots))
		if occupied_creature_slots >= RegistryClassScript.MAX_CREATURE_SLOTS_PER_CELL:
			continue
		var distance: int = _manhattan_distance(candidate, target)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best
