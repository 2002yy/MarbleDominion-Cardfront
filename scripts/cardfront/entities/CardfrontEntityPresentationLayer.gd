extends Node2D
class_name CardfrontEntityPresentationLayer

const BattlefieldEntityScript = preload(
	"res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd"
)
const EntityVisualRegistryScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityVisualRegistry.gd"
)
const EntityVisualActorScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityVisualActor.gd"
)
const TowerVisualActorScript = preload(
	"res://scripts/cardfront/entities/CardfrontTowerVisualActor.gd"
)

const EFFECT_SECONDS: float = 0.62

var battlefield = null
var registry = null
var runtime = null
var _visual_registry = EntityVisualRegistryScript.new()
var _texture_cache: Dictionary = {}
var _actors_by_entity_id: Dictionary = {}
var _tower_actors_by_entity_id: Dictionary = {}
var _world_effects: Array = []
var _hovered_entity_id: String = ""


func setup(new_battlefield, new_registry, new_runtime) -> void:
	_disconnect_runtime()
	battlefield = new_battlefield
	registry = new_registry
	runtime = new_runtime
	z_index = 22
	_connect_runtime()
	_sync_visual_actors()
	set_process(true)
	queue_redraw()


func mark_dirty() -> void:
	_sync_visual_actors()
	queue_redraw()


func _process(delta: float) -> void:
	var needs_redraw := _update_hovered_entity()
	for effect in _world_effects:
		effect["remaining"] = maxf(0.0, float(effect.get("remaining", 0.0)) - delta)
		needs_redraw = true
	_world_effects = _world_effects.filter(
		func(effect): return float(effect.get("remaining", 0.0)) > 0.0
	)
	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	if battlefield == null or registry == null:
		return
	var cell_size: float = float(battlefield.cell_size)
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		var entity_id := str(entity.entity_id)
		if (
			not _actors_by_entity_id.has(entity_id)
			and not _tower_actors_by_entity_id.has(entity_id)
		):
			_draw_fallback_entity(entity, cell_size)
		_draw_status(entity, cell_size)
	_draw_world_effects(cell_size)
	_draw_hover_tooltip(cell_size)


func _draw_fallback_entity(entity, cell_size: float) -> void:
	var center := (Vector2(entity.cell) + Vector2(0.5, 0.5)) * cell_size
	var owner_color: Color = _owner_color(int(entity.owner_id))
	if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
		var texture: Texture2D = _creature_texture(str(entity.creature_id))
		if texture != null:
			var texture_size := Vector2.ONE * cell_size * 1.34
			draw_texture_rect(
				texture,
				Rect2(center - texture_size * 0.5, texture_size),
				false
			)
			return
		draw_circle(center, cell_size * 0.30, Color(0.05, 0.06, 0.08, 0.88))
		draw_circle(center, cell_size * 0.23, owner_color)
	else:
		var half := Vector2.ONE * cell_size * 0.28
		draw_rect(Rect2(center - half, half * 2.0), owner_color, true)


func _draw_status(entity, cell_size: float) -> void:
	var center := (Vector2(entity.cell) + Vector2(0.5, 0.5)) * cell_size
	var owner_color: Color = _owner_color(int(entity.owner_id))
	var top_y: float = center.y - cell_size * 0.47
	var badge_center := Vector2(center.x - cell_size * 0.31, top_y)
	draw_circle(badge_center, maxf(2.8, cell_size * 0.095), Color(0.05, 0.07, 0.09, 0.96))
	draw_circle(badge_center, maxf(1.9, cell_size * 0.063), owner_color)
	var hp_ratio: float = clampf(
		float(entity.hp) / float(maxi(1, int(entity.max_hp))),
		0.0,
		1.0
	)
	var bar_width: float = cell_size * 0.48
	var bar_rect := Rect2(
		Vector2(center.x - cell_size * 0.18, top_y - maxf(1.5, cell_size * 0.035)),
		Vector2(bar_width, maxf(3.0, cell_size * 0.08))
	)
	draw_rect(bar_rect, Color(0.04, 0.06, 0.08, 0.90), true)
	draw_rect(
		Rect2(bar_rect.position + Vector2.ONE, Vector2((bar_width - 2.0) * hp_ratio, bar_rect.size.y - 2.0)),
		Color(0.31, 0.88, 0.48) if hp_ratio > 0.35 else Color(1.0, 0.36, 0.22),
		true
	)
	if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
		_draw_creature_role_icon(entity, center + Vector2(cell_size * 0.36, -cell_size * 0.47), cell_size)
	else:
		_draw_tower_status(entity, center, cell_size)


func _draw_creature_role_icon(entity, center: Vector2, cell_size: float) -> void:
	var radius: float = maxf(2.5, cell_size * 0.08)
	draw_circle(center, radius * 1.45, Color(0.04, 0.06, 0.08, 0.88))
	match str(entity.creature_id):
		"repair_unit":
			draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.42, 1.0, 0.63), 1.6)
			draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.42, 1.0, 0.63), 1.6)
		"armored_guard":
			var points := PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, -radius * 0.35),
				center + Vector2(radius * 0.65, radius),
				center + Vector2(0, radius * 1.35),
				center + Vector2(-radius * 0.65, radius),
				center + Vector2(-radius, -radius * 0.35),
			])
			draw_colored_polygon(points, Color(0.36, 0.78, 1.0))
		"sapper_unit":
			draw_circle(center, radius, Color(1.0, 0.40, 0.22))
			draw_line(center, center + Vector2(radius * 0.7, -radius * 1.2), Color(1.0, 0.82, 0.30), 1.6)
		"scout_unit":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0, -radius),
					center + Vector2(radius, 0),
					center + Vector2(0, radius),
					center + Vector2(-radius, 0),
				]),
				Color(0.36, 0.94, 1.0)
			)


func _draw_tower_status(entity, center: Vector2, cell_size: float) -> void:
	var font := ThemeDB.fallback_font
	var level_text := "L%d" % maxi(1, int(entity.tower_level))
	draw_string(
		font,
		center + Vector2(-cell_size * 0.18, cell_size * 0.47),
		level_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		maxi(9, roundi(cell_size * 0.23)),
		Color.WHITE
	)
	if not bool(entity.powered):
		draw_string(
			font,
			center + Vector2(cell_size * 0.02, cell_size * 0.47),
			"OFF",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			maxi(8, roundi(cell_size * 0.20)),
			Color(1.0, 0.38, 0.25)
		)
	elif str(entity.tower_id) == "interceptor_tower":
		draw_string(
			font,
			center + Vector2(cell_size * 0.02, cell_size * 0.47),
			"×%d" % maxi(0, int(entity.intercepts_remaining)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			maxi(8, roundi(cell_size * 0.20)),
			Color(0.43, 0.91, 1.0)
		)


func _draw_world_effects(cell_size: float) -> void:
	for effect in _world_effects:
		var remaining: float = float(effect.get("remaining", 0.0))
		var progress: float = 1.0 - remaining / EFFECT_SECONDS
		var cell: Vector2i = effect.get("cell", Vector2i.ZERO) as Vector2i
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
		var color: Color = effect.get("color", Color.WHITE) as Color
		color.a *= 1.0 - progress
		draw_arc(
			center,
			cell_size * lerpf(0.22, 0.72, progress),
			0.0,
			TAU,
			28,
			color,
			maxf(2.0, cell_size * 0.07)
		)


func _draw_hover_tooltip(cell_size: float) -> void:
	if _hovered_entity_id.is_empty():
		return
	var entity = registry.get_entity(_hovered_entity_id)
	if entity == null or not entity.is_alive():
		return
	var mouse := get_local_mouse_position()
	var panel_size := Vector2(
		clampf(cell_size * 5.6, 148.0, 240.0),
		clampf(cell_size * 1.45, 44.0, 60.0)
	)
	var position := mouse + Vector2(14.0, -panel_size.y - 12.0)
	var battlefield_extent: Vector2 = battlefield.get_pixel_extent()
	position.x = clampf(position.x, 4.0, maxf(4.0, battlefield_extent.x - panel_size.x - 4.0))
	position.y = clampf(position.y, 4.0, maxf(4.0, battlefield_extent.y - panel_size.y - 4.0))
	var rect := Rect2(position, panel_size)
	draw_rect(rect, Color(0.035, 0.055, 0.075, 0.96), true)
	draw_rect(rect, _owner_color(int(entity.owner_id)).lightened(0.15), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		position + Vector2(9.0, 17.0),
		_entity_name(entity),
		HORIZONTAL_ALIGNMENT_LEFT,
		panel_size.x - 18.0,
		13,
		Color.WHITE
	)
	draw_string(
		font,
		position + Vector2(9.0, 35.0),
		_entity_detail(entity),
		HORIZONTAL_ALIGNMENT_LEFT,
		panel_size.x - 18.0,
		11,
		Color(0.76, 0.86, 0.92)
	)


func _sync_visual_actors() -> void:
	if battlefield == null or registry == null:
		return
	var live_creature_ids: Dictionary = {}
	var live_tower_ids: Dictionary = {}
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		var safe_id := str(entity.entity_id)
		if str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
			var frames: SpriteFrames = _visual_registry.load_sprite_frames(str(entity.creature_id))
			if frames == null:
				continue
			live_creature_ids[safe_id] = true
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
		elif str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			live_tower_ids[safe_id] = true
			var tower_actor = _tower_actors_by_entity_id.get(safe_id, null)
			if tower_actor == null or not is_instance_valid(tower_actor):
				tower_actor = TowerVisualActorScript.new()
				tower_actor.name = "TowerVisual_%s" % safe_id
				add_child(tower_actor)
				tower_actor.setup(
					safe_id,
					str(entity.tower_id),
					_owner_color(int(entity.owner_id)),
					float(battlefield.cell_size),
					entity.cell
				)
				tower_actor.destruction_finished.connect(_on_tower_destruction_finished)
				_tower_actors_by_entity_id[safe_id] = tower_actor
			tower_actor.sync(entity)
	for entity_id in _actors_by_entity_id.keys():
		var actor = _actors_by_entity_id[entity_id]
		if live_creature_ids.has(entity_id) or (actor != null and actor.is_dying()):
			continue
		_remove_actor(str(entity_id))
	for entity_id in _tower_actors_by_entity_id.keys():
		var actor = _tower_actors_by_entity_id[entity_id]
		if live_tower_ids.has(entity_id) or (actor != null and actor.is_destroyed()):
			continue
		_remove_tower_actor(str(entity_id))


func _connect_runtime() -> void:
	if runtime == null or not is_instance_valid(runtime):
		return
	_connect_named_signal("neutral_creature_attacked", "_on_neutral_creature_attacked")
	_connect_named_signal("entity_contact_resolved", "_on_entity_contact_resolved")
	_connect_named_signal("entity_removed", "_on_entity_removed")
	_connect_named_signal("creature_repaired", "_on_creature_repaired")
	_connect_named_signal("projectile_guided", "_on_projectile_guided")
	_connect_named_signal("sapper_detonated", "_on_sapper_detonated")
	_connect_named_signal("tower_power_changed", "_on_tower_power_changed")
	_connect_named_signal("building_volley_fired", "_on_building_volley_fired")
	_connect_named_signal("tower_counter_fired", "_on_tower_counter_fired")
	_connect_named_signal("heavy_charge_exploded", "_on_heavy_charge_exploded")


func _disconnect_runtime() -> void:
	if runtime == null or not is_instance_valid(runtime):
		return
	_disconnect_named_signal("neutral_creature_attacked", "_on_neutral_creature_attacked")
	_disconnect_named_signal("entity_contact_resolved", "_on_entity_contact_resolved")
	_disconnect_named_signal("entity_removed", "_on_entity_removed")
	_disconnect_named_signal("creature_repaired", "_on_creature_repaired")
	_disconnect_named_signal("projectile_guided", "_on_projectile_guided")
	_disconnect_named_signal("sapper_detonated", "_on_sapper_detonated")
	_disconnect_named_signal("tower_power_changed", "_on_tower_power_changed")
	_disconnect_named_signal("building_volley_fired", "_on_building_volley_fired")
	_disconnect_named_signal("tower_counter_fired", "_on_tower_counter_fired")
	_disconnect_named_signal("heavy_charge_exploded", "_on_heavy_charge_exploded")


func _connect_named_signal(signal_name: String, method_name: String) -> void:
	if not runtime.has_signal(signal_name):
		return
	var runtime_signal: Signal = runtime.get(signal_name) as Signal
	var callback := Callable(self, method_name)
	if not runtime_signal.is_connected(callback):
		runtime_signal.connect(callback)


func _disconnect_named_signal(signal_name: String, method_name: String) -> void:
	if not runtime.has_signal(signal_name):
		return
	var runtime_signal: Signal = runtime.get(signal_name) as Signal
	var callback := Callable(self, method_name)
	if runtime_signal.is_connected(callback):
		runtime_signal.disconnect(callback)


func _on_neutral_creature_attacked(result: Dictionary) -> void:
	var actor = _actors_by_entity_id.get(str(result.get("creature_id", "")), null)
	if actor != null and is_instance_valid(actor):
		actor.play_action(_visual_registry.get_default_action(actor.visual_id))


func _on_entity_contact_resolved(result: Dictionary) -> void:
	var target_id := str(result.get("target_id", ""))
	var actor = _actors_by_entity_id.get(target_id, null)
	if actor != null and is_instance_valid(actor):
		if (
			actor.visual_id == CardfrontEntityVisualRegistry.ARMORED_GUARD
			and bool(result.get("bounce_projectile", false))
		):
			actor.play_action("block")
		elif int(result.get("damage_applied", 0)) > 0:
			actor.play_hit()
	var tower_actor = _tower_actors_by_entity_id.get(target_id, null)
	if tower_actor != null and is_instance_valid(tower_actor):
		if bool(result.get("intercepted", false)):
			tower_actor.play_intercept()
		elif int(result.get("damage_applied", 0)) > 0:
			tower_actor.play_hit()


func _on_entity_removed(entity_id: String, _kind: String, _owner_id: int, _cell: Vector2i) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_death()
	var tower_actor = _tower_actors_by_entity_id.get(str(entity_id), null)
	if tower_actor != null and is_instance_valid(tower_actor):
		tower_actor.play_destroyed()


func _on_creature_repaired(entity_id: String, cell: Vector2i, _restored_points: int) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_action("repair")
	_add_world_effect(cell, Color(0.36, 1.0, 0.55, 0.92))


func _on_projectile_guided(entity_id: String, _owner_id: int, _projectile_type: String) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_action("guide")
	var tower_actor = _tower_actors_by_entity_id.get(str(entity_id), null)
	if tower_actor != null and is_instance_valid(tower_actor):
		tower_actor.play_guidance()


func _on_sapper_detonated(
	owner_id: int,
	_target_kind: String,
	cell: Vector2i,
	_damage: int
) -> void:
	for entity in registry.get_entities_at(cell):
		if (
			int(entity.owner_id) == int(owner_id)
			and str(entity.creature_id) == "sapper_unit"
		):
			var actor = _actors_by_entity_id.get(str(entity.entity_id), null)
			if actor != null and is_instance_valid(actor):
				actor.play_terminal("detonate")
			break
	_add_world_effect(cell, Color(1.0, 0.42, 0.16, 0.96))


func _on_tower_power_changed(entity_id: String, _powered: bool) -> void:
	var entity = registry.get_entity(str(entity_id))
	var actor = _tower_actors_by_entity_id.get(str(entity_id), null)
	if actor != null and is_instance_valid(actor) and entity != null:
		actor.sync(entity)


func _on_building_volley_fired(
	_owner_id: int,
	tower_entity_id: String,
	_shot_count: int
) -> void:
	var actor = _tower_actors_by_entity_id.get(str(tower_entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_fire()


func _on_tower_counter_fired(tower_entity_id: String, _owner_id: int) -> void:
	var actor = _tower_actors_by_entity_id.get(str(tower_entity_id), null)
	if actor != null and is_instance_valid(actor):
		actor.play_counter()


func _on_heavy_charge_exploded(
	_owner_id: int,
	cell: Vector2i,
	_center_target_id: String
) -> void:
	_add_world_effect(cell, Color(1.0, 0.35, 0.12, 1.0))


func _add_world_effect(cell: Vector2i, color: Color) -> void:
	_world_effects.append({"cell": cell, "color": color, "remaining": EFFECT_SECONDS})
	queue_redraw()


func _update_hovered_entity() -> bool:
	if (
		battlefield == null
		or registry == null
		or not battlefield.has_method("is_inside")
		or battlefield.get("grid_extent") == null
	):
		return false
	var mouse := get_local_mouse_position()
	var cell := Vector2i(
		floori(mouse.x / float(battlefield.cell_size)),
		floori(mouse.y / float(battlefield.cell_size))
	)
	var next_id := ""
	if battlefield.is_inside(cell):
		var entities: Array = registry.get_entities_at(cell)
		if not entities.is_empty():
			next_id = str(entities[0].entity_id)
	if next_id == _hovered_entity_id:
		return false
	_hovered_entity_id = next_id
	return true


func _owner_color(owner_id: int) -> Color:
	if owner_id >= GameConfig.Faction.BLUE and owner_id <= GameConfig.Faction.YELLOW:
		return GameConfig.faction_color(owner_id)
	return Color(0.88, 0.76, 0.32, 0.96)


func _creature_texture(creature_id: String) -> Texture2D:
	if _texture_cache.has(creature_id):
		return _texture_cache[creature_id] as Texture2D
	var texture: Texture2D = _visual_registry.load_texture(creature_id)
	_texture_cache[creature_id] = texture
	return texture


func _entity_name(entity) -> String:
	var names: Dictionary = {
		"repair_unit": "维修单位",
		"armored_guard": "装甲护卫",
		"sapper_unit": "掘城单位",
		"scout_unit": "侦察单位",
		"gate_colossus": "闸门巨像",
		"fire_control_beacon": "火控信标",
		"interceptor_tower": "拦截塔",
	}
	var key := ""
	if str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
		key = str(entity.tower_id)
	else:
		key = str(entity.creature_id)
	return str(names.get(key, key))


func _entity_detail(entity) -> String:
	if str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
		var power_text := "供电" if bool(entity.powered) else "断电"
		var extra := ""
		if str(entity.tower_id) == "interceptor_tower":
			extra = " · 拦截 %d" % maxi(0, int(entity.intercepts_remaining))
		return "HP %d/%d · L%d · %s%s" % [
			int(entity.hp),
			int(entity.max_hp),
			maxi(1, int(entity.tower_level)),
			power_text,
			extra,
		]
	var duration := "永久" if int(entity.rounds_remaining) < 0 else "%d 回合" % int(entity.rounds_remaining)
	return "HP %d/%d · 移动 %d · %s" % [
		int(entity.hp),
		int(entity.max_hp),
		int(entity.movement),
		duration,
	]


func _on_actor_death_finished(entity_id: String) -> void:
	_remove_actor(entity_id)


func _on_tower_destruction_finished(entity_id: String) -> void:
	_remove_tower_actor(entity_id)


func _remove_actor(entity_id: String) -> void:
	var actor = _actors_by_entity_id.get(str(entity_id), null)
	_actors_by_entity_id.erase(str(entity_id))
	if actor != null and is_instance_valid(actor):
		actor.queue_free()


func _remove_tower_actor(entity_id: String) -> void:
	var actor = _tower_actors_by_entity_id.get(str(entity_id), null)
	_tower_actors_by_entity_id.erase(str(entity_id))
	if actor != null and is_instance_valid(actor):
		actor.queue_free()
