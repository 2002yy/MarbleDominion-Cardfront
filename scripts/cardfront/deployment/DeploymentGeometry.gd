extends RefCounted
class_name DeploymentGeometry

const PROFILE_DIRECTIONAL_REAR_RECT_V1: String = "directional_rear_rect_v1"
const CLASS_INSIDE: String = "inside"
const CLASS_WRONG_DIRECTION: String = "wrong_direction"
const CLASS_OUTSIDE: String = "outside"

const LATERAL_RATIO: float = 0.075
const REAR_DEPTH_RATIO: float = 0.10


static func dimensions(grid_extent: Vector2i) -> Dictionary:
	var min_axis: int = mini(grid_extent.x, grid_extent.y)
	return {
		"lateral_half_width_cells": maxi(2, roundi(float(min_axis) * LATERAL_RATIO)),
		"rear_depth_cells": maxi(2, roundi(float(min_axis) * REAR_DEPTH_RATIO)),
	}


static func classify(
	profile_id: String,
	anchor: Vector2i,
	forward: Vector2i,
	target: Vector2i,
	grid_extent: Vector2i
) -> String:
	if str(profile_id) != PROFILE_DIRECTIONAL_REAR_RECT_V1:
		return CLASS_OUTSIDE
	if absi(forward.x) + absi(forward.y) != 1:
		return CLASS_OUTSIDE
	var offset: Vector2i = target - anchor
	var perpendicular := Vector2i(-forward.y, forward.x)
	var forward_component: int = offset.x * forward.x + offset.y * forward.y
	if forward_component > 0:
		return CLASS_WRONG_DIRECTION
	var rear_distance: int = -forward_component
	var lateral_component: int = absi(offset.x * perpendicular.x + offset.y * perpendicular.y)
	var size: Dictionary = dimensions(grid_extent)
	if rear_distance > int(size.rear_depth_cells) or lateral_component > int(size.lateral_half_width_cells):
		return CLASS_OUTSIDE
	return CLASS_INSIDE
