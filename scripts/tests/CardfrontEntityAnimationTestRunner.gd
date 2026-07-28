extends SceneTree

const VisualRegistryScript = preload("res://scripts/cardfront/entities/CardfrontEntityVisualRegistry.gd")
const VisualActorScript = preload("res://scripts/cardfront/entities/CardfrontEntityVisualActor.gd")
const EntityRegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const DebugLayerScript = preload("res://scripts/cardfront/entities/CardfrontEntityDebugLayer.gd")


class MockBattlefield:
	extends Node2D
	var cell_size: int = 32


class MockRuntime:
	extends Node
	signal neutral_creature_attacked(result)
	signal entity_contact_resolved(result)
	signal entity_removed(entity_id, entity_kind, owner_id, cell)

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	_test_animation_assets()
	await _test_state_priority_and_transitions()
	await _test_runtime_signal_routing()
	_assert.report("[CardfrontEntityAnimationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_animation_assets() -> void:
	var registry = VisualRegistryScript.new()
	var expected_counts: Dictionary = {
		"idle": 4,
		"move": 6,
		"attack": 6,
		"hit": 4,
		"death": 6,
	}
	for animation_name in expected_counts.keys():
		var paths: Array = registry.get_animation_frame_paths(
			VisualRegistryScript.GATE_COLOSSUS,
			str(animation_name)
		)
		_assert.eq(
			paths.size(),
			int(expected_counts[animation_name]),
			"entity animation: %s frame count" % animation_name
		)
		for path_value in paths:
			_assert.that(
				ResourceLoader.exists(str(path_value)),
				"entity animation: frame exists %s" % str(path_value)
			)
	var frames := registry.load_sprite_frames(VisualRegistryScript.GATE_COLOSSUS)
	_assert.that(frames != null, "entity animation: SpriteFrames builds from registry")
	if frames == null:
		return
	_assert.that(frames.get_animation_loop("idle"), "entity animation: idle loops")
	_assert.that(frames.get_animation_loop("move"), "entity animation: move loops")
	_assert.that(not frames.get_animation_loop("attack"), "entity animation: attack is one-shot")
	_assert.that(not frames.get_animation_loop("hit"), "entity animation: hit is one-shot")
	_assert.that(not frames.get_animation_loop("death"), "entity animation: death is one-shot")


func _test_state_priority_and_transitions() -> void:
	var registry = VisualRegistryScript.new()
	var actor = VisualActorScript.new()
	get_root().add_child(actor)
	actor.setup(
		"gate_colossus_test",
		VisualRegistryScript.GATE_COLOSSUS,
		32.0,
		registry.load_sprite_frames(VisualRegistryScript.GATE_COLOSSUS),
		Vector2i(2, 2)
	)
	_assert.eq(actor.current_state, VisualActorScript.STATE_IDLE, "entity animation: starts idle")
	actor.sync_cell(Vector2i(3, 2))
	_assert.eq(actor.current_state, VisualActorScript.STATE_MOVE, "entity animation: movement starts move")
	actor.play_attack()
	_assert.eq(actor.current_state, VisualActorScript.STATE_ATTACK, "entity animation: attack overrides move")
	actor.play_hit()
	_assert.eq(actor.current_state, VisualActorScript.STATE_HIT, "entity animation: hit overrides attack")
	actor.play_attack()
	_assert.eq(actor.current_state, VisualActorScript.STATE_HIT, "entity animation: attack cannot override hit")
	actor.play_death()
	_assert.eq(actor.current_state, VisualActorScript.STATE_DEATH, "entity animation: death has highest priority")
	actor.play_hit()
	_assert.eq(actor.current_state, VisualActorScript.STATE_DEATH, "entity animation: hit cannot override death")
	var death_events: Array = []
	actor.death_finished.connect(func(entity_id): death_events.append(str(entity_id)))
	actor._on_animation_finished()
	_assert.eq(death_events.size(), 1, "entity animation: death completion is reported")
	actor.queue_free()
	await process_frame


func _test_runtime_signal_routing() -> void:
	var battlefield := MockBattlefield.new()
	var runtime := MockRuntime.new()
	var registry = EntityRegistryScript.new()
	get_root().add_child(battlefield)
	get_root().add_child(runtime)
	var creature = registry.spawn_creature(
		"gate_colossus_live",
		VisualRegistryScript.GATE_COLOSSUS,
		-1,
		Vector2i(4, 4),
		6,
		"armored",
		1,
		"gate_colossus",
		-1,
		2
	)
	var layer = DebugLayerScript.new()
	battlefield.add_child(layer)
	layer.setup(battlefield, registry, runtime)
	var actor = layer._actors_by_entity_id.get("gate_colossus_live", null)
	_assert.that(actor != null, "entity animation: runtime layer creates the visual actor")
	if actor == null:
		battlefield.queue_free()
		runtime.queue_free()
		await process_frame
		return
	registry.move_entity(creature.entity_id, Vector2i(5, 4))
	layer.mark_dirty()
	_assert.eq(actor.current_state, VisualActorScript.STATE_MOVE, "entity animation: registry movement routes to move")
	runtime.neutral_creature_attacked.emit({"creature_id": creature.entity_id})
	_assert.eq(actor.current_state, VisualActorScript.STATE_ATTACK, "entity animation: runtime attack signal routes to attack")
	runtime.entity_contact_resolved.emit({"target_id": creature.entity_id, "damage_applied": 1})
	_assert.eq(actor.current_state, VisualActorScript.STATE_HIT, "entity animation: contact damage routes to hit")
	registry.remove_entity(creature.entity_id)
	runtime.entity_removed.emit(creature.entity_id, "creature", -1, creature.cell)
	layer.mark_dirty()
	_assert.eq(actor.current_state, VisualActorScript.STATE_DEATH, "entity animation: removal routes to death")
	_assert.that(
		layer._actors_by_entity_id.has(creature.entity_id),
		"entity animation: death actor remains until the one-shot completes"
	)
	actor._on_animation_finished()
	await process_frame
	_assert.that(
		not layer._actors_by_entity_id.has(creature.entity_id),
		"entity animation: death actor is released after the last frame"
	)
	battlefield.queue_free()
	runtime.queue_free()
	await process_frame
