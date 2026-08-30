extends CanvasLayer
class_name CardfrontThreeChoicePanel

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ChoiceCardScene = preload("res://scenes/ui/cardfront/CardfrontUpgradeChoiceCard.tscn")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

@onready var draft_root: Control = get_node("DraftRoot")
@onready var dimmer: ColorRect = get_node("DraftRoot/Dimmer")
@onready var choice_shell: Panel = get_node("DraftRoot/ChoiceShell")
@onready var title_label: Label = get_node("DraftRoot/ChoiceShell/TitleLabel")
@onready var round_label: Label = get_node("DraftRoot/ChoiceShell/RoundLabel")
@onready var timer_bar: ProgressBar = get_node("DraftRoot/ChoiceShell/TimerBar")
@onready var timer_label: Label = get_node("DraftRoot/ChoiceShell/TimerLabel")
@onready var card_box: HBoxContainer = get_node("DraftRoot/ChoiceShell/CardBox")
@onready var ai_status_label: Label = get_node("DraftRoot/ChoiceShell/AiStatusLabel")
@onready var result_label: Label = get_node("DraftRoot/ChoiceShell/ResultLabel")
@onready var peek_chrome: Control = get_node("DraftRoot/PeekChrome")
@onready var _peek_button: Button = get_node("DraftRoot/PeekChrome/PeekButton")
@onready var battle_status: Panel = get_node("BattleStatus")
@onready var battle_phase_label: Label = get_node("BattleStatus/PhaseLabel")
@onready var battle_stats_label: Label = get_node("BattleStatus/StatsLabel")
@onready var stronghold_label: Label = get_node("BattleStatus/StrongholdLabel")
@onready var upgrade_history_chrome: Control = get_node("UpgradeHistoryChrome")
@onready var upgrade_history_button: Button = get_node("UpgradeHistoryChrome/ToggleButton")
@onready var upgrade_history_drawer: Panel = get_node("UpgradeHistoryChrome/Drawer")
@onready var upgrade_history_close_button: Button = get_node("UpgradeHistoryChrome/Drawer/CloseButton")
@onready var upgrade_history_summary: Label = get_node("UpgradeHistoryChrome/Drawer/Summary")
@onready var upgrade_history_list: VBoxContainer = get_node("UpgradeHistoryChrome/Drawer/Scroll/List")
@onready var upgrade_toast: Panel = get_node("UpgradeToast")
@onready var upgrade_toast_label: Label = get_node("UpgradeToast/ToastLabel")

var director = null
var _choice_cards: Array = []
var _timeout_seconds: float = 1.0
var _last_round_number: int = 0
var _pending_player_upgrade_name: String = ""
var _pending_player_upgrade_times: int = 1
var _upgrade_toast_remaining: float = 0.0
var _last_stronghold_status: Dictionary = {}
var _view_size: Vector2 = Vector2(1120, 720)
const DISPLAY_MODE_DRAFT_VISIBLE: String = "draft_visible"
const DISPLAY_MODE_BATTLEFIELD_PREVIEW: String = "battlefield_preview"
var _display_mode: String = DISPLAY_MODE_DRAFT_VISIBLE
const _NORMAL_DIMMER_ALPHA: float = 0.62
const _PEEK_DIMMER_ALPHA: float = 0.12


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draft_root.visible = false
	battle_status.visible = false
	upgrade_toast.visible = false
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_shell.mouse_filter = Control.MOUSE_FILTER_STOP
	_configure_peek_button()
	_configure_upgrade_history()


func _configure_peek_button() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.04, 0.08, 0.12, 0.92)
	stylebox.border_color = Color(0.30, 0.70, 0.90, 0.72)
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(4)
	stylebox.content_margin_left = 10.0
	stylebox.content_margin_right = 10.0
	stylebox.content_margin_top = 4.0
	stylebox.content_margin_bottom = 4.0
	_peek_button.add_theme_stylebox_override("normal", stylebox)
	_peek_button.add_theme_stylebox_override("hover", stylebox)
	_peek_button.add_theme_stylebox_override("pressed", stylebox)
	_peek_button.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0))
	_peek_button.add_theme_color_override("font_hover_color", Color(0.85, 0.98, 1.0))
	if not _peek_button.pressed.is_connected(_toggle_peek):
		_peek_button.pressed.connect(_toggle_peek)


func _configure_upgrade_history() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.04, 0.08, 0.12, 0.94)
	stylebox.border_color = Color(0.98, 0.76, 0.18, 0.78)
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(4)
	upgrade_history_button.add_theme_stylebox_override("normal", stylebox)
	upgrade_history_button.add_theme_stylebox_override("hover", stylebox)
	upgrade_history_button.add_theme_stylebox_override("pressed", stylebox)
	upgrade_history_button.add_theme_color_override("font_color", Color(1.0, 0.91, 0.62))
	if not upgrade_history_button.pressed.is_connected(_toggle_upgrade_history):
		upgrade_history_button.pressed.connect(_toggle_upgrade_history)
	if not upgrade_history_close_button.pressed.is_connected(_close_upgrade_history):
		upgrade_history_close_button.pressed.connect(_close_upgrade_history)


func setup(new_director, view_size: Vector2 = Vector2(1120, 720)) -> bool:
	director = new_director
	if director == null or not is_instance_valid(director):
		visible = false
		return false
	_view_size = view_size
	draft_root.position = Vector2.ZERO
	draft_root.size = view_size
	dimmer.position = Vector2.ZERO
	dimmer.size = view_size
	peek_chrome.position = Vector2.ZERO
	peek_chrome.size = view_size
	choice_shell.position = Vector2((view_size.x - choice_shell.size.x) * 0.5, 116.0)
	battle_status.position = Vector2(12.0, 68.0)
	upgrade_history_chrome.position = Vector2.ZERO
	upgrade_history_chrome.size = view_size
	upgrade_history_button.position = Vector2(maxf(8.0, view_size.x - 138.0), 68.0)
	upgrade_history_drawer.position = Vector2(maxf(8.0, view_size.x - 316.0), 110.0)
	upgrade_history_drawer.size.y = minf(456.0, maxf(280.0, view_size.y - 122.0))
	var drawer_bg := upgrade_history_drawer.get_node("Bg") as ColorRect
	drawer_bg.size.y = upgrade_history_drawer.size.y - 6.0
	var drawer_scroll := upgrade_history_drawer.get_node("Scroll") as ScrollContainer
	drawer_scroll.size.y = upgrade_history_drawer.size.y - 96.0
	_connect_director()
	_refresh_initial_status()
	_refresh_upgrade_history()
	return true


func get_choice_cards() -> Array:
	return _choice_cards.duplicate(false)


func get_visible_choice_count() -> int:
	var count: int = 0
	for card in _choice_cards:
		if card != null and is_instance_valid(card) and card.is_visible_in_tree():
			count += 1
	return count


func choose_index_for_test(index: int) -> bool:
	if _display_mode != DISPLAY_MODE_DRAFT_VISIBLE or not choice_shell.visible:
		return false
	if index < 0 or index >= _choice_cards.size():
		return false
	var card = _choice_cards[index]
	return _choose_upgrade(str(card.upgrade_id))


func is_upgrade_toast_visible_for_test() -> bool:
	return upgrade_toast.visible


func get_display_mode_for_test() -> String:
	return _display_mode


func get_upgrade_toast_text_for_test() -> String:
	return str(upgrade_toast_label.text)


func is_upgrade_history_open_for_test() -> bool:
	return upgrade_history_drawer.visible


func get_upgrade_history_texts_for_test() -> Array[String]:
	var texts: Array[String] = []
	for child in upgrade_history_list.get_children():
		if child is Label:
			texts.append(str((child as Label).text))
	return texts


func _process(delta: float) -> void:
	if _upgrade_toast_remaining <= 0.0:
		return
	_upgrade_toast_remaining = maxf(0.0, _upgrade_toast_remaining - maxf(0.0, delta))
	if _upgrade_toast_remaining <= 0.0:
		upgrade_toast.visible = false


func _connect_director() -> void:
	var bindings: Dictionary = {
		"countdown_updated": "_on_countdown_updated",
		"draft_opened": "_on_draft_opened",
		"draft_time_updated": "_on_draft_time_updated",
		"strongholds_sampled": "_on_strongholds_sampled",
		"choice_locked": "_on_choice_locked",
		"choices_revealed": "_on_choices_revealed",
		"volley_launched": "_on_volley_launched",
		"director_stopped": "_on_director_stopped",
	}
	for signal_name in bindings.keys():
		if not director.has_signal(signal_name):
			continue
		var callable := Callable(self, str(bindings[signal_name]))
		if not director.is_connected(signal_name, callable):
			director.connect(signal_name, callable)


func _refresh_initial_status() -> void:
	var state = director.get_run_state(RulesScript.PLAYER_FACTION)
	if director.has_method("get_stronghold_status"):
		_on_strongholds_sampled({
			RulesScript.PLAYER_FACTION: director.get_stronghold_status(RulesScript.PLAYER_FACTION),
		})
	_on_countdown_updated(director.phase_controller.time_remaining, director.round_number, state)


func _on_countdown_updated(time_remaining: float, round_number: int, player_state) -> void:
	if draft_root.visible:
		return
	_last_round_number = int(round_number)
	battle_status.visible = false
	var next_round: int = int(round_number) + 1
	battle_phase_label.text = "\u7b2c%d\u8f6e  %s" % [
		next_round,
		_format_seconds(time_remaining),
	]
	if player_state != null:
		battle_stats_label.text = "\u9f50%d  \u653b+%d%%  \u9632%d  \u7a00\u6709\u503e\u5411 Lv%d" % [
			int(player_state.base_volley_count),
			int(player_state.attack_level) * 25,
			int(player_state.territory_defense_cap),
			int(player_state.rarity_level),
		]
	_refresh_upgrade_history()


func _on_draft_opened(player_offer: Array, _ai_offer: Array, timeout_seconds: float, round_number: int) -> void:
	_timeout_seconds = maxf(0.01, timeout_seconds)
	_last_round_number = int(round_number)
	_clear_cards()
	for raw_definition in player_offer:
		if not (raw_definition is Dictionary):
			continue
		var card = ChoiceCardScene.instantiate()
		card_box.add_child(card)
		card.setup(raw_definition as Dictionary)
		card.upgrade_chosen.connect(_choose_upgrade)
		_choice_cards.append(card)
	_layout_choice_cards(_choice_cards.size())
	# P0-05B3: the formal draft is always three-choice. Stronghold identity may
	# be shown separately, but it must not alter or describe the draft offer.
	title_label.text = "\u9009\u62e9\u672c\u8f6e\u5f3a\u5316"
	round_label.text = "\u7b2c %d \u8f6e  \u00b7  \u5168\u573a\u5df2\u6682\u505c" % int(round_number)
	ai_status_label.text = "AI \u5df2\u9501\u5b9a\u9009\u62e9"
	result_label.text = "\u70b9\u51fb\u4e00\u5f20\u5f3a\u5316\u724c\uff0c\u8d85\u65f6\u5c06\u968f\u673a\u9009\u62e9"
	timer_bar.max_value = _timeout_seconds
	timer_bar.value = _timeout_seconds
	timer_label.text = "%.1f" % _timeout_seconds
	battle_status.visible = false
	draft_root.visible = true
	_set_draft_display_mode(DISPLAY_MODE_DRAFT_VISIBLE)
	_refresh_upgrade_history()


func _toggle_peek() -> void:
	if not draft_root.visible:
		return
	var next_mode: String = (
		DISPLAY_MODE_DRAFT_VISIBLE
		if _display_mode == DISPLAY_MODE_BATTLEFIELD_PREVIEW
		else DISPLAY_MODE_BATTLEFIELD_PREVIEW
	)
	_set_draft_display_mode(next_mode)


func _set_draft_display_mode(mode: String) -> void:
	_display_mode = (
		DISPLAY_MODE_BATTLEFIELD_PREVIEW
		if mode == DISPLAY_MODE_BATTLEFIELD_PREVIEW
		else DISPLAY_MODE_DRAFT_VISIBLE
	)
	var is_preview: bool = _display_mode == DISPLAY_MODE_BATTLEFIELD_PREVIEW
	dimmer.color.a = _PEEK_DIMMER_ALPHA if is_preview else _NORMAL_DIMMER_ALPHA
	choice_shell.visible = not is_preview
	choice_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_preview else Control.MOUSE_FILTER_STOP
	_peek_button.text = "返回选择" if is_preview else "查看战场"
	_peek_button.position = Vector2(
		clampf(
			choice_shell.position.x + choice_shell.size.x - _peek_button.size.x - 12.0,
			8.0,
			maxf(8.0, _view_size.x - _peek_button.size.x - 8.0)
		),
		choice_shell.position.y + 8.0
	)


func _unhandled_input(event: InputEvent) -> void:
	if not draft_root.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_toggle_peek()
		get_viewport().set_input_as_handled()


func _layout_choice_cards(choice_count: int) -> void:
	var safe_count: int = clampi(choice_count, 1, 4)
	var card_width: float = 280.0 if safe_count <= 3 else 214.0
	var separation: int = 20 if safe_count <= 3 else 13
	card_box.add_theme_constant_override("separation", separation)
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	for card in _choice_cards:
		if card != null and is_instance_valid(card):
			card.custom_minimum_size = Vector2(card_width, 266.0)
			card.size = card.custom_minimum_size
			card.pivot_offset = card.custom_minimum_size * 0.5


func _on_draft_time_updated(time_remaining: float, timeout_seconds: float) -> void:
	_timeout_seconds = maxf(0.01, timeout_seconds)
	timer_bar.max_value = _timeout_seconds
	timer_bar.value = clampf(time_remaining, 0.0, _timeout_seconds)
	timer_label.text = "%.1f" % maxf(0.0, time_remaining)


func _on_strongholds_sampled(status_snapshot: Dictionary) -> void:
	_last_stronghold_status = status_snapshot.duplicate(true)
	var player_status: Dictionary = status_snapshot.get(RulesScript.PLAYER_FACTION, {}) as Dictionary
	var active_types: Array = player_status.get("active_types", []) as Array
	if active_types.is_empty():
		stronghold_label.text = ""
		stronghold_label.visible = false
		return
	var parts: Array[String] = []
	for region_type in active_types:
		var text: String = StrongholdRulesScript.badge_name(str(region_type))
		if text != "":
			parts.append(text)
	stronghold_label.text = "据点控制：%s" % " · ".join(parts)
	stronghold_label.visible = true
	stronghold_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))


func _on_choice_locked(owner_id: int, upgrade_id: String, automatic: bool) -> void:
	if int(owner_id) != RulesScript.PLAYER_FACTION:
		return
	for card in _choice_cards:
		if card != null and is_instance_valid(card):
			card.set_locked(str(card.upgrade_id) == str(upgrade_id))
	result_label.text = "\u8d85\u65f6\u81ea\u52a8\u9009\u62e9" if automatic else "\u5df2\u9501\u5b9a\uff0c\u6b63\u5728\u7ed3\u7b97\u53cc\u65b9\u5f3a\u5316"


func _on_choices_revealed(player_definition: Dictionary, ai_definition: Dictionary, resolution_results: Dictionary) -> void:
	_set_draft_display_mode(DISPLAY_MODE_DRAFT_VISIBLE)
	title_label.text = "\u53cc\u65b9\u5f3a\u5316\u5df2\u786e\u5b9a"
	var player_times: int = int((resolution_results.get(RulesScript.PLAYER_FACTION, {}) as Dictionary).get("times_applied", 1))
	var player_suffix: String = " \u00d7%d" % player_times if player_times > 1 else ""
	_pending_player_upgrade_name = str(player_definition.get("name", "?"))
	_pending_player_upgrade_times = player_times
	result_label.text = "\u4f60\uff1a%s%s    AI\uff1a%s\n\u5373\u5c06\u81ea\u52a8\u9f50\u5c04" % [
		str(player_definition.get("name", "?")),
		player_suffix,
		str(ai_definition.get("name", "?")),
	]
	ai_status_label.text = "AI \u9009\u62e9\uff1a%s" % str(ai_definition.get("name", "?"))
	_refresh_upgrade_history()


func _on_volley_launched(plans: Dictionary, _issued_intents: Dictionary) -> void:
	_set_draft_display_mode(DISPLAY_MODE_DRAFT_VISIBLE)
	draft_root.visible = false
	battle_status.visible = false
	var player_plan = plans.get(RulesScript.PLAYER_FACTION, null)
	if player_plan != null:
		battle_phase_label.text = "\u7b2c %d \u8f6e\u9f50\u5c04  \u00b7  %d \u53d1" % [
			_last_round_number,
			int(player_plan.shot_count),
		]
	_show_upgrade_toast()
	_refresh_upgrade_history()


func _on_director_stopped() -> void:
	_set_draft_display_mode(DISPLAY_MODE_DRAFT_VISIBLE)
	draft_root.visible = false
	battle_status.visible = false
	upgrade_toast.visible = false
	_upgrade_toast_remaining = 0.0
	_close_upgrade_history()


func _choose_upgrade(upgrade_id: String) -> bool:
	if director == null or not is_instance_valid(director):
		return false
	return bool(director.select_player_upgrade(upgrade_id))


func _clear_cards() -> void:
	for card in _choice_cards:
		if card != null and is_instance_valid(card):
			card_box.remove_child(card)
			card.queue_free()
	_choice_cards.clear()


func _format_seconds(value: float) -> String:
	return "%02d:%02d" % [floori(maxf(0.0, value) / 60.0), floori(maxf(0.0, value)) % 60]


func _show_upgrade_toast() -> void:
	if _pending_player_upgrade_name == "":
		return
	var suffix: String = " \u00d7%d" % _pending_player_upgrade_times if _pending_player_upgrade_times > 1 else ""
	upgrade_toast_label.text = "\u5f3a\u5316\u751f\u6548\uff1a%s%s" % [_pending_player_upgrade_name, suffix]
	upgrade_toast.visible = true
	_upgrade_toast_remaining = TuningScript.UPGRADE_FEEDBACK_SECONDS


func _toggle_upgrade_history() -> void:
	upgrade_history_drawer.visible = not upgrade_history_drawer.visible
	if upgrade_history_drawer.visible:
		_refresh_upgrade_history()


func _close_upgrade_history() -> void:
	upgrade_history_drawer.visible = false


func _refresh_upgrade_history() -> void:
	if director == null or not is_instance_valid(director):
		return
	var state = director.get_run_state(RulesScript.PLAYER_FACTION)
	var selected_levels: Dictionary = {}
	if state != null:
		selected_levels = state.selected_upgrade_levels as Dictionary
	var distinct_count := selected_levels.size()
	var total_count := 0
	for level in selected_levels.values():
		total_count += maxi(0, int(level))
	upgrade_history_button.text = "本局强化 · %d" % distinct_count
	upgrade_history_summary.text = (
		"已选 %d 种 · 累计 %d 次" % [distinct_count, total_count]
		if distinct_count > 0
		else "尚未选择强化"
	)
	for child in upgrade_history_list.get_children():
		upgrade_history_list.remove_child(child)
		child.queue_free()
	for upgrade_id in UpgradeManifestScript.FORMAL_UPGRADE_IDS:
		var level := maxi(0, int(selected_levels.get(str(upgrade_id), 0)))
		if level <= 0:
			continue
		var definition := UpgradeManifestScript.get_definition(str(upgrade_id))
		var row := Label.new()
		row.custom_minimum_size = Vector2(266.0, 46.0)
		row.text = "%s  Lv%d\n%s" % [
			str(definition.get("name", upgrade_id)),
			level,
			_upgrade_status_text(state, definition),
		]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 14)
		row.add_theme_color_override("font_color", _rarity_text_color(str(definition.get("rarity", "common"))))
		upgrade_history_list.add_child(row)


func _upgrade_status_text(state, definition: Dictionary) -> String:
	var category := str(definition.get("category", ""))
	var effect_id := str(definition.get("effect_id", ""))
	match category:
		"next_volley":
			return "下轮待结算" if _has_pending_next_volley_effect(state, effect_id) else "已结算"
		"entity", "neutral_entity":
			return "待部署" if not (state.pending_entity_actions as Array).is_empty() else "已部署"
		"building":
			return "已建造 / 升级"
		"draft_growth":
			return "下次待回响" if effect_id == "echo_next_choice" and bool(state.echo_next_choice_armed) else "本局生效"
		_:
			return "本局生效"


func _has_pending_next_volley_effect(state, effect_id: String) -> bool:
	match effect_id:
		"add_next_volley":
			return int(state.next_volley_bonus) > 0
		"multiply_next_volley":
			return int(state.next_volley_multiplier) > 1
		"add_armor_pierce":
			return int(state.next_volley_armor_pierce_contacts) > 0
		"convert_next_volley":
			return not (state.next_volley_conversions as Dictionary).is_empty()
		"arm_heavy_charge":
			return not (state.heavy_charge_spec as Dictionary).is_empty()
	return false


func _rarity_text_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(1.0, 0.72, 0.30)
		"uncommon":
			return Color(0.50, 0.84, 1.0)
		_:
			return Color(0.88, 0.91, 0.94)
