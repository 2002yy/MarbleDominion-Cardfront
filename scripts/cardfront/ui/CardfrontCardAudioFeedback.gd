extends Node
class_name CardfrontCardAudioFeedback

const STREAM_PATHS := {
	"hover": "res://assets/音效_sfx/ui_hover/button_hover_tick_01.ogg",
	"click": "res://assets/音效_sfx/ui_click/button_click_soft_01.ogg",
	"success": "res://assets/音效_sfx/event_result/event_result_positive_01.wav",
	"fail": "res://assets/音效_sfx/event_result/event_result_negative_01.wav",
}

var feedback_bus = null
var _players: Dictionary = {}


func _init() -> void:
	name = "CardfrontCardAudioFeedback"


func setup(new_feedback_bus) -> void:
	feedback_bus = new_feedback_bus
	_load_players()
	if feedback_bus == null:
		return
	_connect_bus()


func _load_players() -> void:
	for key in STREAM_PATHS.keys():
		var path: String = str(STREAM_PATHS[key])
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		if stream == null:
			continue
		var player := AudioStreamPlayer.new()
		player.name = "CardFeedback_%s" % str(key)
		player.stream = stream
		player.volume_db = -10.0
		add_child(player)
		_players[str(key)] = player


func _connect_bus() -> void:
	var hover_callable := Callable(self, "_on_card_hovered")
	if feedback_bus.has_signal("card_hovered") and not feedback_bus.card_hovered.is_connected(hover_callable):
		feedback_bus.card_hovered.connect(hover_callable)
	var click_callable := Callable(self, "_on_card_clicked")
	if feedback_bus.has_signal("card_clicked") and not feedback_bus.card_clicked.is_connected(click_callable):
		feedback_bus.card_clicked.connect(click_callable)
	var success_callable := Callable(self, "_on_card_play_succeeded")
	if feedback_bus.has_signal("card_play_succeeded") and not feedback_bus.card_play_succeeded.is_connected(success_callable):
		feedback_bus.card_play_succeeded.connect(success_callable)
	var fail_callable := Callable(self, "_on_card_play_failed")
	if feedback_bus.has_signal("card_play_failed") and not feedback_bus.card_play_failed.is_connected(fail_callable):
		feedback_bus.card_play_failed.connect(fail_callable)


func _play(key: String) -> void:
	var player: AudioStreamPlayer = _players.get(str(key), null)
	if player == null or not is_instance_valid(player):
		return
	player.stop()
	player.play()


func _on_card_hovered(_card_id: int, _card_data: Dictionary, _card_view: Control) -> void:
	_play("hover")


func _on_card_clicked(_card_id: int, _card_data: Dictionary, _card_view: Control) -> void:
	_play("click")


func _on_card_play_succeeded(_card_id: int, _card_data: Dictionary, _result: Dictionary) -> void:
	_play("success")


func _on_card_play_failed(_card_id: int, _card_data: Dictionary, _result: Dictionary) -> void:
	_play("fail")
