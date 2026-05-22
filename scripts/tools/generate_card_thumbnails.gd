extends SceneTree

const CARD_IDS := [1001, 1002, 1003, 1004]
const SRC_BASE := "res://assets/cardfront_runtime/卡牌插图_cards/512/"
const DST_BASE := "res://assets/cardfront_runtime/卡牌插图_cards/256/"
const THUMB_WIDTH := 256

const FILENAMES := {
	1001: "前线加固_frontline_fortify_v01.png",
	1002: "校准射击_calibrated_shot_v01.png",
	1003: "民心起伏_morale_shift_v01.png",
	1004: "拓荒信标_pioneer_beacon_v01.png",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[ThumbnailGen] Starting thumbnail generation...")
	var dst_dir = DST_BASE.replace("res://", "res://").simplify_path()
	var dst_path = ProjectSettings.globalize_path(DST_BASE)
	DirAccess.make_dir_recursive_absolute(dst_path)

	for card_id in CARD_IDS:
		var filename: String = FILENAMES.get(card_id, "")
		if filename == "":
			print("  SKIP %d: no filename" % card_id)
			continue
		var src_full = SRC_BASE + filename
		var dst_full = DST_BASE + filename
		var src_global = ProjectSettings.globalize_path(src_full)
		var dst_global = ProjectSettings.globalize_path(dst_full)

		if not FileAccess.file_exists(src_global):
			print("  SKIP %d: source not found at %s" % [card_id, src_global])
			continue

		var img = Image.new()
		var err = img.load(src_global)
		if err != OK:
			print("  FAIL %d: could not load image (err=%d)" % [card_id, err])
			continue

		var w = img.get_width()
		var h = img.get_height()
		var new_h = int(h * THUMB_WIDTH / w)
		img.resize(THUMB_WIDTH, new_h, Image.INTERPOLATE_LANCZOS)

		err = img.save_png(dst_global)
		if err != OK:
			print("  FAIL %d: could not save thumbnail (err=%d)" % [card_id, err])
			continue

		print("  OK   %d: %s → %s (%dx%d → %dx%d)" % [card_id, filename, filename, w, h, THUMB_WIDTH, new_h])

	print("[ThumbnailGen] Done")
	quit(0)
