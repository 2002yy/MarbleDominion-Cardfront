extends CanvasLayer
class_name CardfrontPrematchScreen

const HeroCardScene = preload("res://scenes/ui/cardfront/CardfrontHeroChoiceCard.tscn")
const MapCardScene = preload("res://scenes/ui/cardfront/CardfrontMapChoiceCard.tscn")
const HeroRegistry = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistry = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")

signal battle_confirmed(map_id: String, player_hero_id: String, ai_hero_id: String)
signal cancelled

@onready var step_label: Label = $Root/Margin/Flow/StepLabel
@onready var map_section: Control = $Root/Margin/Flow/MapSection
@onready var map_cards: HBoxContainer = $Root/Margin/Flow/MapSection/MapCards
@onready var hero_section: Control = $Root/Margin/Flow/HeroSection
@onready var hero_cards: HBoxContainer = $Root/Margin/Flow/HeroSection/HeroCards
@onready var reveal_section: Control = $Root/Margin/Flow/RevealSection
@onready var player_icon: Control = $Root/Margin/Flow/RevealSection/Compare/Player/PlayerIcon
@onready var player_name: Label = $Root/Margin/Flow/RevealSection/Compare/Player/PlayerName
@onready var player_stats: Label = $Root/Margin/Flow/RevealSection/Compare/Player/PlayerStats
@onready var ai_icon: Control = $Root/Margin/Flow/RevealSection/Compare/AI/AiIcon
@onready var ai_name: Label = $Root/Margin/Flow/RevealSection/Compare/AI/AiName
@onready var ai_stats: Label = $Root/Margin/Flow/RevealSection/Compare/AI/AiStats
@onready var map_summary: Label = $Root/Margin/Flow/RevealSection/MapSummary
@onready var back_button: Button = $Root/Margin/Flow/Actions/Back
@onready var next_button: Button = $Root/Margin/Flow/Actions/Next

var selected_map_id: String = MapRegistry.DEFAULT_DUEL_MAP_ID
var selected_player_hero_id: String = HeroRegistry.DEFAULT_PLAYER_HERO_ID
var selected_ai_hero_id: String = HeroRegistry.DEFAULT_AI_HERO_ID
var _phase: int = 0
var _map_buttons: Dictionary = {}
var _hero_card_nodes: Dictionary = {}


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)


func setup(initial_map_id: String, initial_hero_id: String) -> void:
	selected_map_id = initial_map_id if MapRegistry.get_registered_map_ids().has(initial_map_id) else MapRegistry.DEFAULT_DUEL_MAP_ID
	selected_player_hero_id = HeroRegistry.sanitize_hero_id(initial_hero_id)
	_build_map_cards()
	_build_hero_cards()
	_set_phase(0)


func get_phase_for_test() -> int:
	return _phase


func choose_map_for_test(map_id: String) -> void:
	_select_map(map_id)


func choose_hero_for_test(hero_id: String) -> void:
	_select_hero(hero_id)


func advance_for_test() -> void:
	_on_next_pressed()


func _build_map_cards() -> void:
	for child in map_cards.get_children():
		child.queue_free()
	_map_buttons.clear()
	for raw_map_id in MapRegistry.get_registered_map_ids():
		var map_id: String = str(raw_map_id)
		var card = MapCardScene.instantiate()
		card.name = "Map_%s" % map_id
		map_cards.add_child(card)
		card.configure(map_id)
		card.map_chosen.connect(_select_map)
		_map_buttons[map_id] = card
	_refresh_map_selection()


func _build_hero_cards() -> void:
	for child in hero_cards.get_children():
		child.queue_free()
	_hero_card_nodes.clear()
	for raw_hero_id in HeroRegistry.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var card = HeroCardScene.instantiate()
		card.name = "Hero_%s" % hero_id
		hero_cards.add_child(card)
		card.configure(hero_id)
		card.hero_chosen.connect(_select_hero)
		_hero_card_nodes[hero_id] = card
	_refresh_hero_selection()


func _select_map(map_id: String) -> void:
	if not MapRegistry.get_registered_map_ids().has(map_id):
		return
	selected_map_id = map_id
	_refresh_map_selection()
	_bounce(_map_buttons.get(map_id))


func _select_hero(hero_id: String) -> void:
	if not HeroRegistry.has_hero(hero_id):
		return
	selected_player_hero_id = hero_id
	_refresh_hero_selection()


func _refresh_map_selection() -> void:
	for map_id in _map_buttons.keys():
		_map_buttons[map_id].set_selected(str(map_id) == selected_map_id)


func _refresh_hero_selection() -> void:
	for hero_id in _hero_card_nodes.keys():
		_hero_card_nodes[hero_id].set_selected(str(hero_id) == selected_player_hero_id)


func _set_phase(value: int) -> void:
	_phase = clampi(value, 0, 2)
	map_section.visible = _phase == 0
	hero_section.visible = _phase == 1
	reveal_section.visible = _phase == 2
	back_button.text = "返回主菜单" if _phase == 0 else "上一步"
	next_button.text = "选择英雄" if _phase == 0 else ("揭示对手" if _phase == 1 else "开始战斗")
	step_label.text = [
		"步骤 1 / 3  选择战场",
		"步骤 2 / 3  选择你的英雄",
		"步骤 3 / 3  对阵确认",
	][_phase]
	if _phase == 2:
		_choose_ai_hero()
		_refresh_reveal()


func _choose_ai_hero() -> void:
	var ids: Array = HeroRegistry.get_hero_ids()
	var seed_value: int = hash("%s:%s" % [selected_map_id, selected_player_hero_id])
	selected_ai_hero_id = str(ids[posmod(seed_value, ids.size())])


func _refresh_reveal() -> void:
	var player_presentation: Dictionary = Catalog.hero(selected_player_hero_id)
	var ai_presentation: Dictionary = Catalog.hero(selected_ai_hero_id)
	var player_definition: Dictionary = HeroRegistry.get_definition(selected_player_hero_id)
	var ai_definition: Dictionary = HeroRegistry.get_definition(selected_ai_hero_id)
	player_icon.configure(selected_player_hero_id)
	ai_icon.configure(selected_ai_hero_id)
	player_name.text = "玩家  ·  %s" % str(player_presentation.get("display_name", ""))
	ai_name.text = "AI  ·  %s" % str(ai_presentation.get("display_name", ""))
	player_stats.text = _stats_text(player_definition, player_presentation)
	ai_stats.text = _stats_text(ai_definition, ai_presentation)
	var map_presentation: Dictionary = Catalog.map(selected_map_id)
	map_summary.text = "%s  ·  %s" % [
		str(map_presentation.get("display_name", selected_map_id)),
		str(map_presentation.get("description", "")),
	]
	ai_icon.modulate.a = 0.0
	ai_icon.scale = Vector2(0.72, 0.72)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ai_icon, "modulate:a", 1.0, 0.28)
	tween.tween_property(ai_icon, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK)


func _stats_text(definition: Dictionary, presentation: Dictionary) -> String:
	return "基础齐射  %d\n控制舱  %d\n防御上限  %d\n%s" % [
		int(definition.get("base_volley_count", 0)),
		int(definition.get("command_chamber_health", 0)),
		int(definition.get("territory_defense_cap", 0)),
		str(presentation.get("trait", "")),
	]


func _on_next_pressed() -> void:
	if _phase < 2:
		_set_phase(_phase + 1)
		return
	battle_confirmed.emit(selected_map_id, selected_player_hero_id, selected_ai_hero_id)


func _on_back_pressed() -> void:
	if _phase == 0:
		cancelled.emit()
	else:
		_set_phase(_phase - 1)


func _bounce(control: Control) -> void:
	if control == null:
		return
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(0.96, 0.96), 0.06)
	tween.tween_property(control, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK)
