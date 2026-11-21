extends RefCounted
class_name GameHudView

static func create_control_buttons(owner, game_layer: Node, chambers: Dictionary, current_layout: Dictionary, view_size: Vector2, mobile_mode: bool) -> Dictionary:
	var add_ball_buttons: Dictionary = {}
	var add_ball_button_base_positions: Dictionary = {}
	var canvas := CanvasLayer.new()
	canvas.name = "ControlButtons"
	game_layer.add_child(canvas)

	var energy_button_script = load("res://scripts/EnergyButton.gd")
	var layout_positions: Dictionary = current_layout.get("add_ball_button_positions", current_layout.get("add_ball_positions", {}))
	var layout_button_size: Vector2 = current_layout.get("add_ball_button_size", current_layout.get("button_size", Vector2(76.0, 46.0)))
	for faction_id in chambers.keys():
		var chamber = chambers[faction_id]
		var button = energy_button_script.new()
		var pos: Vector2 = chamber.global_position
		var scaled_w: float = chamber.chamber_size.x * chamber.scale.x
		var scaled_h: float = chamber.chamber_size.y * chamber.scale.y
		var button_size: Vector2 = layout_button_size
		var button_gap: float = current_layout.get("button_gap", 10.0) + (4.0 if mobile_mode else 0.0)
		button.size = button_size
		button.pivot_offset = button.size * 0.5
		button.faction_id = faction_id
		button.process_mode = Node.PROCESS_MODE_PAUSABLE

		if layout_positions.has(faction_id):
			button.position = layout_positions[faction_id]
		else:
			var y_pos: float = pos.y + scaled_h * 0.5 - button.size.y * 0.5
			if faction_id == GameConfig.Faction.BLUE or faction_id == GameConfig.Faction.GREEN:
				button.position = Vector2(pos.x - button.size.x - button_gap, y_pos)
			else:
				button.position = Vector2(pos.x + scaled_w + button_gap, y_pos)

			button.position.x = clampf(button.position.x, 10.0, view_size.x - button.size.x - 10.0)
			button.position.y = clampf(button.position.y, 64.0, view_size.y - button.size.y - 12.0)

		add_ball_button_base_positions[faction_id] = button.position
		button.display_text = "+球"
		button.text = ""
		button.pressed.connect(Callable(owner, "_add_ball_to_chamber").bind(faction_id))
		canvas.add_child(button)
		add_ball_buttons[faction_id] = button

	return {
		"add_ball_buttons": add_ball_buttons,
		"add_ball_button_base_positions": add_ball_button_base_positions,
	}

static func refresh_add_ball_button(faction_id: int, add_ball_buttons: Dictionary, chambers: Dictionary) -> void:
	if not add_ball_buttons.has(faction_id):
		return

	var button = add_ball_buttons[faction_id]
	var count: int = 0
	var damaged: bool = false
	var locked: bool = false
	var jammed: bool = false

	if chambers.has(faction_id):
		var chamber = chambers[faction_id]
		count = chamber.get_ball_count()
		damaged = chamber.is_damaged
		locked = chamber.is_locked
		jammed = chamber.has_method("get_jammed_time_left") and float(chamber.get_jammed_time_left()) > 0.0

	if damaged:
		button.set_button_status("damaged", "损坏")
	elif jammed:
		button.set_button_status("locked", "短路")
	elif locked:
		button.set_button_status("locked", "锁定")
	elif count >= GameConfig.MAX_CONTROL_BALLS_PER_CHAMBER:
		button.set_button_status("full", "已满")
	else:
		button.set_button_status("normal", "+球")

	button.self_modulate = GameConfig.faction_color(faction_id)
