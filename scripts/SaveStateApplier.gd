extends RefCounted
class_name SaveStateApplier

const NEUTRAL_OWNER_ID: int = -1

static func apply_owners(battlefield, data: Dictionary, on_scores_changed: Callable = Callable()) -> void:
	if battlefield == null:
		return

	var owners = data.get("owners", [])
	if owners is Array and owners.size() == battlefield.grid_size:
		var loaded_owners: Array = []
		for x in range(battlefield.grid_size):
			var col: Array = []
			var src_col = owners[x]
			for y in range(battlefield.grid_size):
				var raw_owner = 0
				if src_col is Array and y < src_col.size():
					raw_owner = src_col[y]
				col.append(_sanitize_owner_id(raw_owner))
			loaded_owners.append(col)
		battlefield.owners = loaded_owners
		battlefield.rebuild_owner_counts()
		if battlefield.has_method("flush_visual_update"):
			battlefield.flush_visual_update()
		else:
			battlefield.queue_redraw()
		if on_scores_changed.is_valid():
			on_scores_changed.call(battlefield.count_cells_by_team())

static func apply_factions(chambers: Dictionary, turrets: Dictionary, factions: Array, on_chamber_unlock: Callable, on_button_refresh: Callable) -> void:
	if factions is Array:
		for faction_state in factions:
			if not (faction_state is Dictionary):
				continue
			var faction_id: int = int(faction_state.get("faction_id", 0))
			if chambers.has(faction_id) and chambers[faction_id] != null and is_instance_valid(chambers[faction_id]):
				chambers[faction_id].restore_from_state(faction_state)
			if turrets.has(faction_id) and turrets[faction_id] != null and is_instance_valid(turrets[faction_id]):
				turrets[faction_id].restore_from_state(faction_state)

			if chambers.has(faction_id) and turrets.has(faction_id):
				var chamber = chambers[faction_id]
				var turret = turrets[faction_id]
				if chamber.is_locked and chamber.locked_remaining > 0 and turret.burst_remaining <= 0:
					on_chamber_unlock.call(chamber)

			if on_button_refresh.is_valid():
				on_button_refresh.call(faction_id)

static func apply_event_state(event_roulette_controller, data: Dictionary) -> void:
	if event_roulette_controller != null:
		var saved_event_state = data.get("event_state", {})
		if saved_event_state is Dictionary:
			event_roulette_controller.import_save_state(saved_event_state)

static func apply_game_over_state(data: Dictionary, winner_label) -> bool:
	var is_game_over: bool = bool(data.get("is_game_over", false))
	if winner_label != null:
		winner_label.text = str(data.get("winner_text", ""))
	return is_game_over

static func _sanitize_owner_id(raw_owner) -> int:
	var owner_id: int = int(raw_owner)
	if owner_id == NEUTRAL_OWNER_ID:
		return NEUTRAL_OWNER_ID
	return clampi(owner_id, 0, 3)
