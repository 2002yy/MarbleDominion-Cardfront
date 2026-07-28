extends SceneTree

const VisualRegistryScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityVisualRegistry.gd"
)
const EntityRegistryScript = preload(
	"res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd"
)
const PresentationLayerScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityPresentationLayer.gd"
)
const ManifestScript = preload(
	"res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd"
)


class MockBattlefield:
	extends Node2D
	var cell_size: int = 32
	var grid_size: int = 10

	func is_inside(cell: Vector2i) -> bool:
		return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size


class MockRuntime:
	extends Node
	signal neutral_creature_attacked(result)
	signal entity_contact_resolved(result)
	signal entity_removed(entity_id, entity_kind, owner_id, cell)
	signal creature_repaired(entity_id, cell, restored_points)
	signal projectile_guided(entity_id, owner_id, projectile_type)
	signal sapper_detonated(owner_id, target_kind, cell, damage)
	signal tower_power_changed(entity_id, powered)
	signal building_volley_fired(owner_id, tower_entity_id, shot_count)
	signal tower_counter_fired(tower_entity_id, owner_id)
	signal heavy_charge_exploded(owner_id, cell, center_target_id)


var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_test_animation_sets()
	await _test_runtime_feedback_routes()
	await _test_upgrade_card_stats()
	_assert.report("[CardfrontEntityPresentationFeedbackTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_animation_sets() -> void:
	var visual_registry = VisualRegistryScript.new()
	var expected: Dictionary = {
		VisualRegistryScript.REPAIR_UNIT: {
			"idle": 4, "move": 6, "repair": 6, "hit": 4, "death": 6,
		},
		VisualRegistryScript.ARMORED_GUARD: {
			"idle": 4, "move": 6, "block": 6, "hit": 4, "death": 6,
		},
		VisualRegistryScript.SAPPER_UNIT: {
			"idle": 4, "move": 6, "attack": 6, "detonate": 6, "hit": 4, "death": 6,
		},
		VisualRegistryScript.SCOUT_UNIT: {
			"idle": 4, "move": 6, "guide": 6, "hit": 4, "death": 6,
		},
	}
	for visual_id in expected.keys():
		for state_name in (expected[visual_id] as Dictionary).keys():
			var paths: Array = visual_registry.get_animation_frame_paths(
				str(visual_id),
				str(state_name)
			)
			_assert.eq(
				paths.size(),
				int((expected[visual_id] as Dictionary)[state_name]),
				"entity presentation: %s %s frame count" % [visual_id, state_name]
			)
			for path in paths:
				_assert.that(
					visual_registry.resource_path_exists(str(path)),
					"entity presentation: frame exists %s" % str(path)
				)
		_assert.that(
			visual_registry.load_sprite_frames(str(visual_id)) != null,
			"entity presentation: %s SpriteFrames loads" % visual_id
		)


func _test_runtime_feedback_routes() -> void:
	var battlefield := MockBattlefield.new()
	var runtime := MockRuntime.new()
	var registry = EntityRegistryScript.new()
	get_root().add_child(battlefield)
	get_root().add_child(runtime)
	var repair = registry.spawn_creature(
		"repair", "repair_unit", 0, Vector2i(1, 1), 1, "normal", 1, "repair", 3
	)
	var guard = registry.spawn_creature(
		"guard", "armored_guard", 0, Vector2i(2, 1), 4, "armored", 1, "guard"
	)
	var sapper = registry.spawn_creature(
		"sapper", "sapper_unit", 0, Vector2i(3, 1), 3, "armored", 1, "sapper"
	)
	var scout = registry.spawn_creature(
		"scout", "scout_unit", 1, Vector2i(4, 1), 1, "normal", 1, "scout"
	)
	registry.register_building_slot("beacon_slot", Vector2i(2, 3))
	registry.register_building_slot("interceptor_slot", Vector2i(7, 3))
	var beacon = registry.spawn_defense_tower(
		"beacon", "fire_control_beacon", 0, "beacon_slot", 5
	)
	var interceptor = registry.spawn_defense_tower(
		"interceptor", "interceptor_tower", 1, "interceptor_slot", 4
	)
	interceptor.configure_interceptor(3)
	var layer = PresentationLayerScript.new()
	battlefield.add_child(layer)
	layer.setup(battlefield, registry, runtime)
	await process_frame

	_assert.eq(layer._actors_by_entity_id.size(), 4, "entity presentation: four creature actors")
	_assert.eq(layer._tower_actors_by_entity_id.size(), 2, "entity presentation: two tower actors")
	runtime.creature_repaired.emit(repair.entity_id, repair.cell, 1)
	_assert.eq(
		layer._actors_by_entity_id[repair.entity_id].current_state,
		&"repair",
		"entity presentation: repair signal plays repair"
	)
	runtime.entity_contact_resolved.emit({
		"target_id": guard.entity_id,
		"bounce_projectile": true,
		"damage_applied": 1,
	})
	_assert.eq(
		layer._actors_by_entity_id[guard.entity_id].current_state,
		&"block",
		"entity presentation: guard bounce plays block"
	)
	runtime.entity_contact_resolved.emit({
		"target_id": repair.entity_id,
		"bounce_projectile": true,
		"damage_applied": 1,
	})
	_assert.eq(
		layer._actors_by_entity_id[repair.entity_id].current_state,
		&"hit",
		"entity presentation: non-guard bounce plays hit instead of profession action"
	)
	runtime.projectile_guided.emit(scout.entity_id, scout.owner_id, "standard")
	_assert.eq(
		layer._actors_by_entity_id[scout.entity_id].current_state,
		&"guide",
		"entity presentation: scout guidance plays guide"
	)
	runtime.sapper_detonated.emit(sapper.owner_id, "defense_tower", sapper.cell, 3)
	_assert.eq(
		layer._actors_by_entity_id[sapper.entity_id].current_state,
		&"detonate",
		"entity presentation: Sapper signal plays terminal detonate"
	)
	runtime.projectile_guided.emit(beacon.entity_id, beacon.owner_id, "standard")
	_assert.eq(
		layer._tower_actors_by_entity_id[beacon.entity_id]._effect,
		"guidance",
		"entity presentation: beacon guidance pulses"
	)
	runtime.entity_contact_resolved.emit({
		"target_id": interceptor.entity_id,
		"intercepted": true,
		"damage_applied": 0,
	})
	_assert.eq(
		layer._tower_actors_by_entity_id[interceptor.entity_id]._effect,
		"intercept",
		"entity presentation: interceptor shield pulses"
	)
	runtime.tower_counter_fired.emit(interceptor.entity_id, interceptor.owner_id)
	_assert.eq(
		layer._tower_actors_by_entity_id[interceptor.entity_id]._effect,
		"counter",
		"entity presentation: interceptor counterfire is visible"
	)
	interceptor.powered = false
	runtime.tower_power_changed.emit(interceptor.entity_id, false)
	_assert.that(
		not layer._tower_actors_by_entity_id[interceptor.entity_id].powered,
		"entity presentation: tower power state is synchronized"
	)
	runtime.heavy_charge_exploded.emit(0, interceptor.cell, interceptor.entity_id)
	_assert.that(
		not layer._world_effects.is_empty(),
		"entity presentation: Heavy Charge adds a battlefield pulse"
	)
	_assert.that(
		layer._entity_detail(interceptor).contains("HP")
		and layer._entity_detail(interceptor).contains("L1"),
		"entity presentation: hover detail includes HP and level"
	)
	_assert.eq(
		layer._entity_name(interceptor),
		"拦截塔",
		"entity presentation: tower hover resolves tower name safely"
	)
	battlefield.queue_free()
	runtime.queue_free()
	await process_frame


func _test_upgrade_card_stats() -> void:
	var scene: PackedScene = load("res://scenes/ui/cardfront/CardfrontUpgradeChoiceCard.tscn")
	var card = scene.instantiate()
	get_root().add_child(card)
	await process_frame
	for upgrade_id in [
		ManifestScript.UPGRADE_REPAIR_UNITS,
		ManifestScript.UPGRADE_FIRE_CONTROL_BEACON,
		ManifestScript.UPGRADE_INTERCEPTOR_TOWER,
		ManifestScript.UPGRADE_ARMORED_GUARD,
		ManifestScript.UPGRADE_SAPPER_UNIT,
		ManifestScript.UPGRADE_GATE_COLOSSUS,
	]:
		var definition: Dictionary = ManifestScript.get_definition(str(upgrade_id))
		_assert.that(
			not str(definition.get("display_stats", "")).is_empty(),
			"entity presentation: %s has direct card stats" % upgrade_id
		)
		card.setup(definition)
		_assert.eq(
			card.stats_label.text,
			str(definition.get("display_stats", "")),
			"entity presentation: card renders %s stats" % upgrade_id
		)
	card.queue_free()
	await process_frame
