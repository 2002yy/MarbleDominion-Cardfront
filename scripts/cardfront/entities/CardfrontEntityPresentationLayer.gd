extends Node2D
class_name CardfrontEntityPresentationLayer

const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const EntityVisualRegistryScript = preload("res://scripts/cardfront/entities/CardfrontEntityVisualRegistry.gd")
const EntityVisualActorScript = preload("res://scripts/cardfront/entities/CardfrontEntityVisualActor.gd")

var battlefield = null
var registry = null
var runtime = null
var _visual_registry = EntityVisualRegistryScript.new()
var _texture_cache: Dictionary = {}
var _actors_by_entity_id: Dictionary = {}


func setup(new_battlefield, new_registry, new_runtime) -> void:
	_disconnect_runtime()
	battlefield = new_battlefield
	registry = new_registry
	runtime = new_runtime
	z_index = 22
	_connect_runtime()
	_sync_visual_actors()
	queue_redraw()


func mark_dirty() -> void:
	_sync_visual_actors()
	queue_redraw()


func _draw() -> void:
	if battlefield == null or registry == null:
		return
	var cell_size: float = float(battlefield.cell_size)
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		var center := (Vector2(entity.cell) + Vector2(0.5, 0.5)) * cell_size
		var owner_color: Color = _owner_color(int(entity.owner_id))
		match str(entity.entity_kind):
			BattlefieldEntityScript.KIND_CREATURE:
				if _actors_by_entity_id.has(str(entity.entity_id)):
					continue
				var creature_scale: float = 1.22 if int(entity.size_slots) >= 2 else 1.0
				var texture: Texture2D = _creature_texture(str(entity.creature_id))
				if texture != null:
					var texture_size := Vector2.ONE * cell_size * 1.34 * creature_scale
					draw_texture_rect(
						texture,
						Rect2(center - texture_size * 0.5, texture_size),
						false
					)
				else:
					draw_circle(
						center,
						cell_size * 0.30 * creature_scale,
						Color(0.05, 0.06, 0.08, 0.88)
					)
					draw_circle(center, cell_size * 0.23 * creature_scale, owner_color)
					if int(entity.owner_id) == -1:
						draw_circle(center, cell_size * 0.08, Color(0.96, 0.88, 0.48, 0.98))
			BattlefieldEntityScript.KIND_DEFENSE_TOWER:
				var half := Vector2.ONE * cell_size * 0.28
				var rect := Rect2(center - half, half * 2.0)
				draw_rect(rect, Color(0.05, 0.06, 0.08, 0.90), true)
				draw_rect(
					rect.grow(-cell_size * 0.06),
					owner_color if entity.powered else Color(0.34, 0.34, 0.38, 0.90),
					true
				)
				if not entity.powered:
					draw_line(rect.position, rect.end, Color(1.0, 0.30, 0.22, 0.95), 2.0)
					draw_line(
						Vector2(rect.end.x, rect.position.y),
						Vector2(rect.position.x, rect.end.y),
						Color(1.0, 0.30, 0.22, 0.95),
						2.0
					)


func _owner_color(owner_id: int) -> Color:
	if owner_id >= GameConfig.Faction.BLUE and owner_id <= GameConfig.Faction.YELLOW:
		return GameConfig.faction_color(owner_id)
	return Color(0.70, 0.72, 0.76, 0.95)


func _creature_texture(creature_id: String) -> Texture2D:
	if _texture_cache.has(creature_id):
		return _texture_cache[creature_id] as Texture2D
	var texture: Texture2D = _visual_registry.load_texture(creature_id)
	_texture_cache[creature_id] = texture
	return texture


func _sync_visual_actors() -> void:
	if battlefield == null or registry == null:
		return
	var live_actor_ids: Dictionary = {}
	for entity in registry.entities_by_id.values():
		if (
			entity == null
			or not entity.is_alive()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_CREATURE
		):
			continue
		var safe_id := str(entity.entity_id)
		var frames: SpriteFrames = _visual_registry.load_sprite_frames(str(entity.creature_id))
		if frames == null:
			continue
		live_actor_ids[safe_id] = true
		var actor = _actors_by_entity_id.get(safe_id, null)
		if actor == null or not is_instance_valid(actor):
			actor = EntityVisualActorScript.new()
			actor.name = "Visual_%s" % safe_id
			add_child(actor)
			actor.setup(
				safe_id,
				str(entity.creature_id),
				float(battlefield.cell_size),
				frames,
				entity.cell
			)
			actor.death_finished.connect(_on_actor_death_finished)
			_actors_by_entity_id[safe_id] = actor
		else:
			actor.sync_cell(entity.cell)
	for entity_id in _actors_by_entity_id.keys():
		var actor = _actors_by_entity_id[entity_id]
		if live_actor_ids.has(entity_id) or (actor != null and actor.is_dying()):
			continue
		_remove_actor(str(entity_id))


func _connect_runtime() -> void:
	if runtime == null or not is_instance_valid(runtime):
		return
	_connect_signal(runtime.neutral_creature_attacked, "_on_neutral_creature_attacked")
	_connect_signal(runtime.entity_contact_resolved, "_on_entity_contact_resolved")
	_connect_signal(runtime.entity_removed, "_on_entity_removed")


func _disconnect_runtime() -> void:
	if runtime == null or not is_instance_valid(runtime):
		return
	_disconnect_signal(runtime.neutral_creature_attacked, "_on_neutral_creature_attacked")
	_disconnect_signal(runtime.entity_contact_resolved, "_on_entity_contact_resolved")
	_disconnect_signal(runtime.entity_removed, "_on_entity_removed")


func _connect_signal(runtime_signal: Signal, method_name: String) -> void:
	var callback := Callable(self, method_name)
	if not runtime_signal.is_connected(callback):
		runtime_signal.connect(callback)


func _disconnect_signal(runtime_signal: Signal, method_name: String) -> void:
	var callback := Callable(self, method_name)
	if runtime_signal.is_connected(callback):
		runtime_signal.disconnect(callback)


func _on_neutral_creature_attacked(result: Dictionary) -> void:
	var actor = _actors_by_entity_id.get(str(result.get("creature_id", "")), null)
	if actor != null and is_instance_valid(actor):
		actor.play_attack()


func _on_entity_contact_resolved(result: Dictionary) -> void:
	if int(result.get("damage_applied", 0)) <= 0:
		return
	var actor = _actors_by_entity_id.get(str(result.get("target_id", "")), null)
	if actor != null and is_instance_valid(actor):
		actor.play_hit()


func _on_entity_removed(entity_id: String, _kind: String, _owner_id: int, _cell: Vector2i) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_death()


func _on_actor_death_finished(entity_id: String) -> void:
	_remove_actor(entity_id)


func _remove_actor(entity_id: String) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	_actors_by_entity_id.erase(str(entity_id))
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
