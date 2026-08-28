extends SceneTree

const ObservationBuilderScript = preload("res://scripts/cardfront/ai/CardfrontAiObservationBuilder.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontAiObservationBoundaryTest] Starting P0-10A2-A5 boundary tests")
	await process_frame

	_test_empty_allowlist_shape()
	_test_explicit_three_bucket_projection()
	_test_forbidden_and_unknown_fields_are_invisible()
	_test_nested_records_are_allowlisted()
	_test_nested_object_escape_is_rejected()
	_test_observation_is_detached_and_pure()

	_assert.report("[CardfrontAiObservationBoundaryTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_empty_allowlist_shape() -> void:
	var observation: Dictionary = ObservationBuilderScript.build()
	_assert.eq(observation.keys().size(), 3, "shape: observation contains exactly three information buckets")
	_assert.eq(observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE], {}, "shape: public bucket starts empty")
	_assert.eq(observation[ObservationBuilderScript.OWN_PRIVATE_STATE], {}, "shape: own-private bucket starts empty")
	_assert.eq(observation[ObservationBuilderScript.OBSERVED_ENEMY_HISTORY], [], "shape: observed history starts empty")
	_assert.that(ObservationBuilderScript.is_pure_observation(observation), "shape: empty observation is a pure value tree")


func _test_explicit_three_bucket_projection() -> void:
	var observation: Dictionary = ObservationBuilderScript.build(
		{
			"round_number": 4,
			"phase": "draft_paused",
			"support_views": [{"support_id": "support_left_north", "owner_id": 0, "online": true}],
			"gate_states": {"gate_center": "open"},
		},
		{
			"hero_id": "fortification_engineer",
			"deck_id": "fortification_corps",
			"command_points": 2,
			"selected_upgrade_levels": {"volley_plus_5": 3},
		},
		[
			{"event_type": "card_revealed", "round_number": 3, "owner_id": 0, "card_id": "volley_x2"},
			{"event_type": "support_captured", "support_id": "support_center", "cell": Vector2i(20, 25)},
		]
	)
	var public_state: Dictionary = observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE]
	var own_state: Dictionary = observation[ObservationBuilderScript.OWN_PRIVATE_STATE]
	var history: Array = observation[ObservationBuilderScript.OBSERVED_ENEMY_HISTORY]
	_assert.eq(int(public_state.get("round_number", 0)), 4, "public: round is explicitly projected")
	_assert.eq(str(public_state.get("phase", "")), "draft_paused", "public: phase is explicitly projected")
	_assert.eq(str(own_state.get("deck_id", "")), "fortification_corps", "own: AI deck identity is explicitly projected")
	_assert.eq(int((own_state.get("selected_upgrade_levels", {}) as Dictionary).get("volley_plus_5", 0)), 3, "own: selected levels remain AI-private data")
	_assert.eq(history.size(), 2, "history: only supplied observed events are retained")
	_assert.eq((history[1] as Dictionary).get("cell"), Vector2i(20, 25), "history: safe value types remain available")


func _test_forbidden_and_unknown_fields_are_invisible() -> void:
	var observation: Dictionary = ObservationBuilderScript.build(
		{
			"round_number": 2,
			"player_offer": ["secret"],
			"future_offer": ["future"],
			"seed": 771,
			"new_future_game_state_field": "must default invisible",
		},
		{
			"deck_id": "core_tactics",
			"player_unrevealed_choice": "secret",
			"hidden_tactical_instruction": "cheat",
			"full_snapshot": {"command_chamber_health": 99},
		},
		[{
			"event_type": "card_revealed",
			"card_id": "volley_plus_5",
			"hidden_route_tendency_score": 0.99,
			"unknown_history_field": "invisible",
		}]
	)
	var public_state: Dictionary = observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE]
	var own_state: Dictionary = observation[ObservationBuilderScript.OWN_PRIVATE_STATE]
	var history_event: Dictionary = (observation[ObservationBuilderScript.OBSERVED_ENEMY_HISTORY] as Array)[0]
	_assert.eq(public_state.keys(), ["round_number"], "allowlist: public unknown and forbidden fields default invisible")
	_assert.eq(own_state.keys(), ["deck_id"], "allowlist: own unknown and forbidden fields default invisible")
	_assert.eq(history_event.keys(), ["event_type", "card_id"], "allowlist: observed event fields are explicit")
	_assert.that(not _contains_key_recursive(observation, "player_offer"), "forbidden: Player Offer cannot enter observation")
	_assert.that(not _contains_key_recursive(observation, "seed"), "forbidden: RNG seed cannot enter observation")


func _test_nested_object_escape_is_rejected() -> void:
	var node := Node.new()
	var ref := RefCounted.new()
	var observation: Dictionary = ObservationBuilderScript.build(
		{
			"round_number": 3,
			"support_views": [{"support_id": "support_center", "runtime_object": node}],
			"battlefield_entities": [ref],
			"bridge_states": {"bridge_center": {"callback": Callable(self, "_never_call")}},
		},
		{
			"deck_id": "core_tactics",
			"tower_levels": {"fire_control_beacon": 1, "node": node},
		},
		[]
	)
	node.free()
	var public_state: Dictionary = observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE]
	var own_state: Dictionary = observation[ObservationBuilderScript.OWN_PRIVATE_STATE]
	var support: Dictionary = (public_state["support_views"] as Array)[0]
	var bridge: Dictionary = (public_state["bridge_states"] as Dictionary)["bridge_center"]
	_assert.eq(public_state.keys(), ["round_number", "support_views", "bridge_states"], "escape: safe nested records survive without rejected object fields")
	_assert.eq(support, {"support_id": "support_center"}, "escape: runtime object is stripped from an otherwise public support record")
	_assert.eq(bridge, {}, "escape: callback-only bridge record projects to no readable fields")
	_assert.that(not public_state.has("battlefield_entities"), "escape: direct RefCounted entity array is rejected")
	_assert.eq(own_state.keys(), ["deck_id"], "escape: object-contaminated own field is rejected atomically")
	_assert.that(ObservationBuilderScript.is_pure_observation(observation), "escape: returned observation contains no Object or Callable")
	_assert.that(not ObservationBuilderScript.is_pure_observation({"node": ref}), "escape: validator rejects RefCounted objects")


func _test_nested_records_are_allowlisted() -> void:
	var observation: Dictionary = ObservationBuilderScript.build({
		"support_views": [{
			"support_id": "support_center",
			"owner_id": 0,
			"online": true,
			"future_secret_support_field": 99,
		}],
		"battlefield_entities": [{
			"entity_id": "tower_1",
			"entity_type": "tower",
			"cell": Vector2i(4, 5),
			"internal_target_score": 0.75,
		}],
		"gate_states": {
			"center": {"gate_id": "center", "open": true, "future_internal": "hidden"},
		},
	})
	var public_state: Dictionary = observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE]
	var support: Dictionary = (public_state["support_views"] as Array)[0]
	var entity: Dictionary = (public_state["battlefield_entities"] as Array)[0]
	var gate: Dictionary = (public_state["gate_states"] as Dictionary)["center"]
	_assert.eq(support.keys(), ["support_id", "owner_id", "online"], "nested allowlist: support fields default invisible unless approved")
	_assert.eq(entity.keys(), ["entity_id", "entity_type", "cell"], "nested allowlist: entity internals cannot hitchhike")
	_assert.eq(gate.keys(), ["gate_id", "open"], "nested allowlist: gate internals cannot hitchhike")


func _test_observation_is_detached_and_pure() -> void:
	var support_views: Array = [{"support_id": "support_center", "online": true}]
	var selected_levels: Dictionary = {"volley_plus_5": 2}
	var history: Array = [{"event_type": "card_revealed", "card_id": "volley_x2"}]
	var observation: Dictionary = ObservationBuilderScript.build(
		{"support_views": support_views},
		{"selected_upgrade_levels": selected_levels},
		history
	)
	support_views[0]["online"] = false
	selected_levels["volley_plus_5"] = 9
	history[0]["card_id"] = "mutated"
	var public_views: Array = (observation[ObservationBuilderScript.PUBLIC_BATTLE_STATE] as Dictionary)["support_views"]
	var own_levels: Dictionary = (observation[ObservationBuilderScript.OWN_PRIVATE_STATE] as Dictionary)["selected_upgrade_levels"]
	var observed_history: Array = observation[ObservationBuilderScript.OBSERVED_ENEMY_HISTORY]
	_assert.eq(bool((public_views[0] as Dictionary).get("online", false)), true, "detach: nested public source mutation cannot alter observation")
	_assert.eq(int(own_levels.get("volley_plus_5", 0)), 2, "detach: nested own source mutation cannot alter observation")
	_assert.eq(str((observed_history[0] as Dictionary).get("card_id", "")), "volley_x2", "detach: history source mutation cannot alter observation")
	_assert.that(ObservationBuilderScript.is_pure_observation(observation), "detach: final observation is recursively pure")


func _contains_key_recursive(value, target_key: String) -> bool:
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if str(key) == target_key or _contains_key_recursive((value as Dictionary)[key], target_key):
				return true
	elif value is Array:
		for item in value as Array:
			if _contains_key_recursive(item, target_key):
				return true
	return false


func _never_call() -> void:
	pass
