extends RefCounted
class_name CardfrontUiAssetRegistry

const ASSETS := {
	"font_kenney_future": {
		"path": "res://assets/ui/Kenney科幻UI_kenney_scifi/font/Kenney Future.ttf",
		"fallback": "default_theme_font",
		"license": "CC0",
	},
	"hand_panel_bg": {
		"path": "res://assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01/common/BqPanelBotton.png",
		"fallback": "flat_panel",
		"license": "CC0",
	},
	"card_frame": {
		"path": "res://assets/ui/Kenney科幻UI_kenney_scifi/blue_default/button_square_header_large_rectangle.png",
		"fallback": "color_rect_frame",
		"license": "CC0",
	},
	"card_bg": {
		"path": "res://assets/ui/Kenney科幻UI_kenney_scifi/blue_default/bar_square_gloss_large.png",
		"fallback": "color_rect_bg",
		"license": "CC0",
	},
	"resource_panel_bg": {
		"path": "res://assets/ui/Kenney科幻UI_kenney_scifi/blue_default/bar_round_gloss_large.png",
		"fallback": "flat_panel",
		"license": "CC0",
	},
	"detail_popup_panel": {
		"path": "res://assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01/elements/BlockInformation.png",
		"fallback": "flat_panel",
		"license": "CC0",
	},
	"toast_panel": {
		"path": "res://assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01/common/ItemEnable.png",
		"fallback": "flat_panel",
		"license": "CC0",
	},
	"region_info_panel": {
		"path": "res://assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01/elements/BlockInformation.png",
		"fallback": "flat_panel",
		"license": "CC0",
	},
	"icon_energy": {
		"path": "res://assets/ui/游戏图标_科幻_game_icons_scifi/event_icons/energise.svg",
		"fallback": "text_energy",
		"license": "CC BY 3.0",
	},
	"icon_parts": {
		"path": "res://assets/ui/游戏图标_科幻_game_icons_scifi/totem_candidates/power-generator.svg",
		"fallback": "text_parts",
		"license": "CC BY 3.0",
	},
	"icon_target": {
		"path": "res://assets/ui/游戏图标_科幻_game_icons_scifi/event_icons/targeting.svg",
		"fallback": "text_target",
		"license": "CC BY 3.0",
	},
}


static func get_asset_ids() -> Array:
	return ASSETS.keys()


static func get_asset_path(asset_id: String) -> String:
	var entry: Dictionary = ASSETS.get(str(asset_id), {})
	return str(entry.get("path", ""))


static func get_fallback(asset_id: String) -> String:
	var entry: Dictionary = ASSETS.get(str(asset_id), {})
	return str(entry.get("fallback", "missing_asset"))


static func get_license(asset_id: String) -> String:
	var entry: Dictionary = ASSETS.get(str(asset_id), {})
	return str(entry.get("license", "unknown"))


static func has_asset(asset_id: String) -> bool:
	var path: String = get_asset_path(asset_id)
	return path != "" and ResourceLoader.exists(path)


static func load_texture(asset_id: String):
	var path: String = get_asset_path(asset_id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


static func load_font(asset_id: String = "font_kenney_future"):
	var path: String = get_asset_path(asset_id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


static func make_panel_style(asset_id: String, fallback_bg: Color, fallback_border: Color):
	var tex = load_texture(asset_id)
	if tex != null:
		var style := StyleBoxTexture.new()
		style.texture = tex
		return style
	var flat := StyleBoxFlat.new()
	flat.bg_color = fallback_bg
	flat.border_color = fallback_border
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(5)
	flat.content_margin_left = 8.0
	flat.content_margin_right = 8.0
	flat.content_margin_top = 6.0
	flat.content_margin_bottom = 6.0
	return flat


static func validation_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for asset_id in get_asset_ids():
		result[asset_id] = {
			"path": get_asset_path(asset_id),
			"exists": has_asset(asset_id),
			"fallback": get_fallback(asset_id),
			"license": get_license(asset_id),
		}
	return result
