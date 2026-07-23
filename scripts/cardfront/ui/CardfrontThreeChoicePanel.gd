extends CanvasLayer
class_name CardfrontThreeChoicePanel

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ChoiceCardScene = preload("res://scenes/ui/cardfront/CardfrontUpgradeChoiceCard.tscn")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

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
@onready var battle_status: Panel = get_node("BattleStatus")
@onready var battle_phase_label: Label = get_node("BattleStatus/PhaseLabel")
@onready var battle_stats_label: Label = get_node("BattleStatus/StatsLabel")
@onready var stronghold_label: Label = get_node("BattleStatus/StrongholdLabel")
@onready var upgrade_toast: Panel = get_node("UpgradeToast")
@onready var upgrade_toast_label: Label = get_node("UpgradeToast/ToastLabel")

var director = null
var _choice_cards: Array = []
var _timeout_seconds: float = 1.0
var _last_round_number: int = 0
var _pending_player_upgrade_name: String = ""
var _pending_player_upgrade_times: int = 1
var _upgrade_toast_remaining: float = 0.0
var _last_stronghold_bonuses: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draft_root.visible = false
	battle_status.visible = true
	upgrade_toast.visible = false
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	choice_shell.mouse_filter = Control.MOUSE_FILTER_STOP


func setup(new_director, view_size: Vector2 = Vector2(1120, 720)) -> bool:
	director = new_director
	if director == null or not is_instance_valid(director):
		visible = false
		return false
	draft_root.position = Vector2.ZERO
	draft_root.size = view_size
	dimmer.position = Vector2.ZERO
	dimmer.size = view_size
	choice_shell.position = Vector2((view_size.x - choice_shell.size.x) * 0.5, 116.0)
	battle_status.position = Vector2(24.0, 116.0)
	_connect_director()
	_refresh_initial_status()
	return true


func get_choice_cards() -> Array:
	return _choice_cards.duplicate(false)


func get_visible_choice_count() -> int:
	var count: int = 0
	for card in _choice_cards:
		if card != null and is_instance_valid(card) and card.visible:
			count += 1
	return count


func choose_index_for_test(index: int) -> bool:
	if index < 0 or index >= _choice_cards.size():
		return false
	var card = _choice_cards[index]
	return _choose_upgrade(str(card.upgrade_id))


func is_upgrade_toast_visible_for_test() -> bool:
	return upgrade_toast.visible


func get_upgrade_toast_text_for_test() -> String:
	return str(upgrade_toast_label.text)


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
	if director.has_method("get_stronghold_bonus"):
		_on_strongholds_sampled({
			RulesScript.PLAYER_FACTION: director.get_stronghold_bonus(RulesScript.PLAYER_FACTION),
		})
	_on_countdown_updated(director.phase_controller.time_remaining, director.round_number, state)


func _on_countdown_updated(time_remaining: float, round_number: int, player_state) -> void:
	if draft_root.visible:
		return
	_last_round_number = int(round_number)
	battle_status.visible = true
	var next_round: int = int(round_number) + 1
	battle_phase_label.text = "\u7b2c %d \u8f6e\u5f3a\u5316  %s" % [
		next_round,
		_format_seconds(time_remaining),
	]
	if player_state != null:
		battle_stats_label.text = "\u9f50\u5c04 %d  \u00b7  \u7834\u574f %d  \u00b7  \u9632\u5b88 %d  \u00b7  \u7a00\u6709 %d" % [
			int(player_state.base_volley_count),
			int(player_state.projectile_power),
			int(player_state.territory_defense_cap),
			int(player_state.rarity_level),
		]


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
	title_label.text = "\u9009\u62e9\u672c\u8f6e\u5f3a\u5316"
	round_label.text = "\u7b2c %d \u8f6e  \u00b7  \u5168\u573a\u5df2\u6682\u505c" % int(round_number)
	ai_status_label.text = "AI \u5df2\u9501\u5b9a\u9009\u62e9"
	var player_bonus: Dictionary = _last_stronghold_bonuses.get(RulesScript.PLAYER_FACTION, {}) as Dictionary
	if bool(player_bonus.get("guarantee_uncommon", false)):
		result_label.text = "实验室已激活：本次至少出现 1 张稀有牌\n点击一张强化牌，超时将随机选择"
	else:
		result_label.text = "\u70b9\u51fb\u4e00\u5f20\u5f3a\u5316\u724c\uff0c\u8d85\u65f6\u5c06\u968f\u673a\u9009\u62e9"
	timer_bar.max_value = _timeout_seconds
	timer_bar.value = _timeout_seconds
	timer_label.text = "%.1f" % _timeout_seconds
	battle_status.visible = false
	draft_root.visible = true


func _on_draft_time_updated(time_remaining: float, timeout_seconds: float) -> void:
	_timeout_seconds = maxf(0.01, timeout_seconds)
	timer_bar.max_value = _timeout_seconds
	timer_bar.value = clampf(time_remaining, 0.0, _timeout_seconds)
	timer_label.text = "%.1f" % maxf(0.0, time_remaining)


func _on_strongholds_sampled(bonuses: Dictionary) -> void:
	_last_stronghold_bonuses = bonuses.duplicate(true)
	var player_bonus: Dictionary = bonuses.get(RulesScript.PLAYER_FACTION, {}) as Dictionary
	var active_types: Array = player_bonus.get("active_types", []) as Array
	if active_types.is_empty():
		stronghold_label.text = "据点：尚未激活（需 80%）"
		stronghold_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.76))
		return
	var parts: Array[String] = []
	for region_type in active_types:
		var text: String = StrongholdRulesScript.compact_effect_text(str(region_type))
		if text != "":
			parts.append(text)
	stronghold_label.text = "据点：%s" % " · ".join(parts)
	stronghold_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))


func _on_choice_locked(owner_id: int, upgrade_id: String, automatic: bool) -> void:
	if int(owner_id) != RulesScript.PLAYER_FACTION:
		return
	for card in _choice_cards:
		if card != null and is_instance_valid(card):
			card.set_locked(str(card.upgrade_id) == str(upgrade_id))
	result_label.text = "\u8d85\u65f6\u81ea\u52a8\u9009\u62e9" if automatic else "\u5df2\u9501\u5b9a\uff0c\u6b63\u5728\u7ed3\u7b97\u53cc\u65b9\u5f3a\u5316"


func _on_choices_revealed(player_definition: Dictionary, ai_definition: Dictionary, resolution_results: Dictionary) -> void:
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


func _on_volley_launched(plans: Dictionary, _issued_intents: Dictionary) -> void:
	draft_root.visible = false
	battle_status.visible = true
	var player_plan = plans.get(RulesScript.PLAYER_FACTION, null)
	if player_plan != null:
		battle_phase_label.text = "\u7b2c %d \u8f6e\u9f50\u5c04  \u00b7  %d \u53d1" % [
			_last_round_number,
			int(player_plan.shot_count),
		]
	_show_upgrade_toast()


func _on_director_stopped() -> void:
	draft_root.visible = false
	battle_status.visible = false
	upgrade_toast.visible = false
	_upgrade_toast_remaining = 0.0


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
