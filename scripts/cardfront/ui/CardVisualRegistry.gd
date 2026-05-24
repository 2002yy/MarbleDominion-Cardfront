extends RefCounted
class_name CardVisualRegistry

const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")

const RUNTIME_BASE: String = "res://assets/cardfront_runtime/卡牌插图_cards/512/"
const RUNTIME_BASE_THUMB: String = "res://assets/cardfront_runtime/卡牌插图_cards/256/"


static func get_texture_path(card_id: int) -> String:
	var entry: Dictionary = CardfrontContentManifestScript.get_visual_for_card(card_id)
	var filename: String = str(entry.get("filename", ""))
	if filename == "":
		return ""
	return RUNTIME_BASE + filename


static func has_texture(card_id: int) -> bool:
	return not CardfrontContentManifestScript.get_visual_for_card(card_id).is_empty()


static func get_thumbnail_path(card_id: int) -> String:
	var entry: Dictionary = CardfrontContentManifestScript.get_visual_for_card(card_id)
	var thumb_filename: String = str(entry.get("thumbnail", ""))
	if thumb_filename == "":
		return ""
	return RUNTIME_BASE_THUMB + thumb_filename


static func has_thumbnail(card_id: int) -> bool:
	var entry: Dictionary = CardfrontContentManifestScript.get_visual_for_card(card_id)
	var thumb_filename: String = str(entry.get("thumbnail", ""))
	return thumb_filename != ""
