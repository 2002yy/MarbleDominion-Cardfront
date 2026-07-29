extends RefCounted
class_name GameSceneBuilder

# Owner callback contract for the current builder wiring.
# Required methods:
# - _on_scores_changed(counts: Dictionary)
# - _on_turret_destroyed(faction_id: int)
# - _on_turret_burst_lock_changed(faction_id: int, locked: bool)
# - _on_turret_burst_progress(faction_id: int, remaining: int)
# - _on_chamber_release_requested(faction_id, bullet_count, chamber)
# - _on_ball_count_changed(faction_id: int, count: int)
# Keep this list aligned with Main.gd or any alternate runtime owner.

static func create_battlefield(owner, game_layer: Node, grid_extent_value, current_layout: Dictionary, view_size: Vector2) -> Dictionary:
    var battlefield = Battlefield.new()
    battlefield.configure_extent(grid_extent_value, int(current_layout.get("battlefield_cell_size", -1)))
    var battlefield_rect: Rect2 = current_layout.get("battlefield_rect", Rect2())
    var map_pixel_extent: Vector2 = battlefield.get_pixel_extent()
    var origin: Vector2 = battlefield_rect.position
    if battlefield_rect.size == Vector2.ZERO:
        origin = Vector2((view_size.x - map_pixel_extent.x) * 0.5, current_layout.get("map_y", 96.0))
    battlefield.position = origin
    battlefield.scores_changed.connect(Callable(owner, "_on_scores_changed"))
    game_layer.add_child(battlefield)

    var bullet_trail_layer = BulletTrailLayer.new()
    bullet_trail_layer.name = "BulletTrailLayer"
    bullet_trail_layer.z_index = 29
    game_layer.add_child(bullet_trail_layer)

    var bullet_container = BulletPool.new()
    bullet_container.name = "BulletPool"
    game_layer.add_child(bullet_container)
    bullet_container.set_trail_layer(bullet_trail_layer)

    return {
        "battlefield": battlefield,
        "bullet_container": bullet_container,
        "bullet_trail_layer": bullet_trail_layer,
        "chamber_scale": current_layout.get("chamber_scale", 0.80),
    }

static func create_turrets(owner, game_layer: Node, battlefield, bullet_container, current_layout: Dictionary = {}, active_factions: Array = []) -> Dictionary:
    var turrets: Dictionary = {}
    var positions: Dictionary = current_layout.get("turret_positions", {})
    var center_angles: Dictionary = current_layout.get("turret_center_angles", {})
    var sweep_amplitudes: Dictionary = current_layout.get("turret_sweep_amplitudes", {})
    if positions.is_empty():
        var map_extent: Vector2 = battlefield.get_pixel_extent()
        var margin: float = 16.0
        var origin: Vector2 = battlefield.position
        positions = {
            GameConfig.Faction.BLUE: origin + Vector2(margin, margin),
            GameConfig.Faction.RED: origin + Vector2(map_extent.x - margin, margin),
            GameConfig.Faction.GREEN: origin + Vector2(margin, map_extent.y - margin),
            GameConfig.Faction.YELLOW: origin + Vector2(map_extent.x - margin, map_extent.y - margin),
        }

    for faction_id in positions.keys():
        if not active_factions.is_empty() and not (faction_id in active_factions):
            continue
        var turret = Turret.new()
        turret.setup(faction_id, positions[faction_id], battlefield, bullet_container)
        if center_angles.has(faction_id):
            turret.set_aim_profile(
                float(center_angles[faction_id]),
                float(sweep_amplitudes.get(faction_id, turret.sweep_amplitude))
            )
        turret.name = "Turret_%s" % GameConfig.faction_name(faction_id)
        turret.destroyed.connect(Callable(owner, "_on_turret_destroyed"))
        turret.burst_lock_changed.connect(Callable(owner, "_on_turret_burst_lock_changed"))
        turret.burst_progress.connect(Callable(owner, "_on_turret_burst_progress"))
        game_layer.add_child(turret)
        turrets[faction_id] = turret

    for turret in turrets.values():
        turret.set_all_turrets(turrets)

    return turrets

static func create_control_chambers(owner, game_layer: Node, battlefield, turrets: Dictionary, current_layout: Dictionary, chamber_scale: float, view_size: Vector2, active_factions: Array = []) -> Dictionary:
    var chambers: Dictionary = {}
    var probe_chamber = ControlChamber.new()
    var scaled_size: Vector2 = probe_chamber.chamber_size * chamber_scale
    probe_chamber.free()
    var chamber_positions: Dictionary = current_layout.get("chamber_positions", {})
    if chamber_positions.is_empty():
        var map_left: float = battlefield.position.x
        var map_width: float = battlefield.get_pixel_extent().x
        var gap_x: float = current_layout.get("chamber_gap", 10.0)
        var top_gap_y: float = current_layout.get("chamber_top_turret_gap", 18.0)
        var bottom_gap_y: float = current_layout.get("chamber_bottom_turret_gap", 8.0)

        var blue_turret = turrets.get(GameConfig.Faction.BLUE, null)
        var red_turret = turrets.get(GameConfig.Faction.RED, null)
        var green_turret = turrets.get(GameConfig.Faction.GREEN, null)
        var yellow_turret = turrets.get(GameConfig.Faction.YELLOW, null)

        var left_x: float = map_left - scaled_size.x - gap_x
        var right_x: float = map_left + map_width + gap_x
        var top_y: float = current_layout.get("left_chamber_y_top", 110.0)
        var bottom_y: float = current_layout.get("left_chamber_y_bottom", 360.0)

        if blue_turret != null:
            left_x = blue_turret.global_position.x - scaled_size.x - gap_x
            top_y = blue_turret.global_position.y - top_gap_y
        elif red_turret != null:
            top_y = red_turret.global_position.y - top_gap_y

        if red_turret != null:
            right_x = red_turret.global_position.x + gap_x

        if green_turret != null:
            bottom_y = green_turret.global_position.y - scaled_size.y - bottom_gap_y
        elif yellow_turret != null:
            bottom_y = yellow_turret.global_position.y - scaled_size.y - bottom_gap_y

        left_x = clampf(left_x, 10.0, map_left - scaled_size.x - 2.0)
        right_x = clampf(right_x, map_left + map_width + 2.0, view_size.x - scaled_size.x - 10.0)
        top_y = clampf(top_y, 58.0, view_size.y - scaled_size.y - 70.0)
        bottom_y = clampf(bottom_y, top_y + scaled_size.y + 6.0, view_size.y - scaled_size.y - 10.0)

        chamber_positions = {
            GameConfig.Faction.BLUE: Vector2(left_x, top_y),
            GameConfig.Faction.RED: Vector2(right_x, top_y),
            GameConfig.Faction.GREEN: Vector2(left_x, bottom_y),
            GameConfig.Faction.YELLOW: Vector2(right_x, bottom_y),
        }

    for faction_id in chamber_positions.keys():
        if not active_factions.is_empty() and not (faction_id in active_factions):
            continue
        var chamber = ControlChamber.new()
        chamber.setup(faction_id, chamber_positions[faction_id])
        chamber.set_linked_turret(turrets.get(faction_id, null))
        chamber.scale = Vector2.ONE * chamber_scale
        chamber.name = "Chamber_%s" % GameConfig.faction_name(faction_id)
        chamber.release_requested.connect(Callable(owner, "_on_chamber_release_requested"))
        chamber.ball_count_changed.connect(Callable(owner, "_on_ball_count_changed"))
        game_layer.add_child(chamber)
        chambers[faction_id] = chamber

    return chambers
