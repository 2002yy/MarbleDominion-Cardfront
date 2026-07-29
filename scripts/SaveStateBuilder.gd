extends RefCounted
class_name SaveStateBuilder

const ChamberSaveAdapterScript = preload("res://scripts/ChamberSaveAdapter.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")

static func build_faction_states(chambers: Dictionary, turrets: Dictionary) -> Array:
	var factions: Array = []
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var chamber = chambers.get(faction_id)
		if chamber == null or not is_instance_valid(chamber):
			chamber = null
		var turret = turrets.get(faction_id)
		if turret == null or not is_instance_valid(turret):
			turret = null
		var chamber_state: Dictionary = ChamberSaveAdapterScript.default_state()
		if chamber != null:
			chamber_state = chamber.collect_state()
		var faction_state: Dictionary = {"faction_id": faction_id}
		for key in chamber_state.keys():
			faction_state[key] = chamber_state[key]
		faction_state["turret_health"] = turret.health if turret != null else GameConfig.TURRET_MAX_HEALTH
		faction_state["turret_destroyed"] = turret.is_destroyed if turret != null else false
		faction_state["turret_sweep_phase"] = turret.sweep_phase if turret != null else 0.0
		faction_state["turret_rotation"] = turret.rotation if turret != null else 0.0
		faction_state["turret_burst_remaining"] = turret.burst_remaining if turret != null else 0
		faction_state["turret_burst_total"] = turret.burst_total if turret != null else 0
		faction_state["turret_burst_index"] = turret.burst_index if turret != null else 0
		faction_state["turret_burst_timer"] = turret.burst_timer if turret != null else 0.0
		faction_state["turret_burst_locked"] = turret.burst_locked if turret != null else false
		faction_state["turret_burst_projectile_power"] = turret.burst_projectile_power if turret != null else 1
		factions.append(faction_state)
	return factions

static func build_save_payload(chambers: Dictionary, turrets: Dictionary, battlefield, bullet_container, event_roulette_controller, game_elapsed_time: float, is_game_over: bool, selected_save_slot: int, winner_label) -> Dictionary:
	var grid_extent: Vector2i = GridExtentScript.normalize(
		battlefield.get("grid_extent"),
		Vector2i(int(battlefield.grid_size), int(battlefield.grid_size))
	)
	var core_payload: Dictionary = {
		"save_version": SaveGameCodec.get_current_save_version(),
		"save_slot": selected_save_slot,
		"grid_size": battlefield.grid_size,
		"grid_extent": GridExtentScript.to_array(grid_extent),
		"palette_name": GameConfig.get_palette_name(),
		"quality_name": GameConfig.get_quality_name(),
		"game_mode_name": GameConfig.get_game_mode_name(),
		"time_limit_minutes": GameConfig.get_time_limit_minutes(),
		"owners": battlefield.owners,
		"game_elapsed_time": game_elapsed_time,
		"is_game_over": is_game_over,
		"match_finished": is_game_over || winner_label != null and is_instance_valid(winner_label) and winner_label.text != "",
		"factions": build_faction_states(chambers, turrets),
		"bullets": SaveGameCodec.collect_bullet_states(bullet_container),
		"winner_text": winner_label.text if winner_label != null else "",
		"event_state": event_roulette_controller.export_save_state() if event_roulette_controller != null else {},
	}
	return SaveGameCodec.attach_payload_hash(core_payload)
