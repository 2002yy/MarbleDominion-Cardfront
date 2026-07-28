extends RefCounted
class_name CardfrontEntityVisualRegistry

const RUNTIME_BASE: String = "res://assets/cardfront_runtime/中立生物_neutral_creatures/256/"
const GATE_COLOSSUS: String = "gate_colossus"

var _path_map: Dictionary = {
	GATE_COLOSSUS: RUNTIME_BASE + "闸门巨像_gate_colossus_v01_256.png",
}
var _animation_map: Dictionary = {
	GATE_COLOSSUS: {
		"idle": {"count": 4, "fps": 5.0, "loop": true},
		"move": {"count": 6, "fps": 8.0, "loop": true},
		"attack": {"count": 6, "fps": 10.0, "loop": false},
		"hit": {"count": 4, "fps": 12.0, "loop": false},
		"death": {"count": 6, "fps": 10.0, "loop": false},
	},
}
var _sprite_frames_cache: Dictionary = {}


func get_texture_path(visual_id: String) -> String:
	return str(_path_map.get(str(visual_id), ""))


func load_texture(visual_id: String) -> Texture2D:
	var path := get_texture_path(visual_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func get_animation_frame_paths(visual_id: String, animation_name: String) -> Array:
	var visual_spec: Dictionary = _animation_map.get(str(visual_id), {}) as Dictionary
	var animation_spec: Dictionary = visual_spec.get(str(animation_name), {}) as Dictionary
	var frame_count: int = maxi(0, int(animation_spec.get("count", 0)))
	var paths: Array = []
	for frame_index in range(frame_count):
		paths.append(
			RUNTIME_BASE
			+ "%s/%s/frame_%02d.png"
			% [str(visual_id), str(animation_name), frame_index + 1]
		)
	return paths


func load_sprite_frames(visual_id: String) -> SpriteFrames:
	var safe_id := str(visual_id)
	if _sprite_frames_cache.has(safe_id):
		return _sprite_frames_cache[safe_id] as SpriteFrames
	var visual_spec: Dictionary = _animation_map.get(safe_id, {}) as Dictionary
	if visual_spec.is_empty():
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in visual_spec.keys():
		var spec: Dictionary = visual_spec[animation_name] as Dictionary
		var paths: Array = get_animation_frame_paths(safe_id, str(animation_name))
		if paths.is_empty():
			return null
		frames.add_animation(str(animation_name))
		frames.set_animation_speed(str(animation_name), float(spec.get("fps", 8.0)))
		frames.set_animation_loop(str(animation_name), bool(spec.get("loop", false)))
		for path_value in paths:
			var path := str(path_value)
			if not ResourceLoader.exists(path):
				return null
			var texture := load(path) as Texture2D
			if texture == null:
				return null
			frames.add_frame(str(animation_name), texture)
	_sprite_frames_cache[safe_id] = frames
	return frames
