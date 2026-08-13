extends RefCounted
class_name CardfrontSystemRegistry

const RuntimeRefsScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeRefs.gd")

const RUNTIME_FIELD_BY_RESULT_KEY: Dictionary = {
	"region_map": "region_map",
	"region_overlay": "region_overlay",
	"region_control_block_layer": "region_control_block_layer",
	"stronghold_system": "stronghold_system",
	"economy_system": "economy_system",
	"resource_states": "resource_states",
	"economy_debug_panel": "economy_debug_panel",
	"morale_system": "morale_system",
	"fortify_layer": "fortify_layer",
	"fortify_overlay": "fortify_overlay",
	"territory_defense_system": "territory_defense_system",
	"support_capture_runtime": "support_capture_runtime",
	"target_bias_system": "target_bias_system",
	"card_system": "card_system",
	"fire_director": "fire_director",
	"shot_guide_layer": "shot_guide_layer",
	"device_layer": "device_layer",
	"device_overlay": "device_overlay_layer",
	"vfx_layer": "cardfront_vfx_layer",
	"debug_action_panel": "debug_action_panel",
	"absorber_core_effect_system": "absorber_core_effect_system",
	"engineer_bot_effect_system": "engineer_bot_effect_system",
	"durable_pioneer_beacon_effect_system": "durable_pioneer_beacon_effect_system",
	"target_preview_layer": "target_preview_layer",
	"feedback_bus": "cardfront_feedback_bus",
	"top_resource_bar": "top_resource_bar",
	"hand_panel": "hand_panel",
	"selection_controller": "selection_controller",
	"region_info_panel": "region_info_panel",
	"tutorial_overlay": "tutorial_overlay",
	"card_detail_popup": "card_detail_popup",
	"toast_layer": "toast_layer",
	"card_audio_feedback": "card_audio_feedback",
	"effect_visual_bridge": "effect_visual_bridge",
	"arena_presentation_layer": "arena_presentation_layer",
	"orthographic_arena_view": "orthographic_arena_view",
	"gate_connectivity_system": "gate_connectivity_system",
	"command_chambers": "command_chambers",
	"direction_controller": "direction_controller",
	"aim_guide_layer": "aim_guide_layer",
	"round_director": "round_director",
	"faction_run_states": "faction_run_states",
}

var refs = RuntimeRefsScript.new()
var failures: Array = []


func clear() -> void:
	refs.clear()
	failures.clear()


func record_result(stage: String, result: Dictionary) -> bool:
	if not bool(result.get("configured", false)):
		failures.append({
			"stage": stage,
			"reason": str(result.get("reason", "unknown")),
		})
		return false
	refs.merge_result(result)
	return true


func apply_to(runtime) -> void:
	if runtime == null:
		return
	var refs_snapshot: Dictionary = refs.snapshot()
	for key in refs_snapshot.keys():
		var runtime_field: String = str(RUNTIME_FIELD_BY_RESULT_KEY.get(str(key), ""))
		if runtime_field == "":
			continue
		runtime.set(runtime_field, refs_snapshot[key])


func snapshot() -> Dictionary:
	return refs.snapshot()


func failure_snapshot() -> Array:
	return failures.duplicate(true)


func has_failures() -> bool:
	return not failures.is_empty()
