extends RefCounted
class_name GameConfig

const GRID_SIZE: int = 40
const CELL_SIZE: int = 13

const BULLET_SPEED: float = 108.0
const BULLET_RADIUS: float = 5.0
const BULLET_MAX_LIFETIME: float = 60.0

const TURRET_RADIUS: float = 18.0
const TURRET_MAX_HEALTH: int = 30
const TURRET_HIT_RADIUS: float = 24.0
const TURRET_HIT_CHECK_INTERVAL: float = 0.055
const BULLET_DAMAGE: int = 1

const BASE_MAX_PENDING_COUNT: int = 2048
const WILD_MAX_PENDING_COUNT: int = 2187
const MAX_CONTROL_BALLS_PER_CHAMBER: int = 8
const MAX_ACTIVE_BULLETS: int = 6000
const BURST_FIRE_INTERVAL: float = 0.040
const BURST_MAX_SHOTS_PER_FRAME: int = 3

const GAME_MODE_BASIC: String = "基础模式"
const GAME_MODE_OCCUPATION: String = "占领模式"
const GAME_MODE_TIMED: String = "限时模式"
const GAME_MODE_WILD: String = "狂野模式"
const GAME_MODE_CARDFRONT: String = "卡牌前线"
const OCCUPATION_TARGET_PERCENT: int = 75
const TIMED_MODE_MIN_MINUTES: int = 5
const TIMED_MODE_MAX_MINUTES: int = 15
const DEFAULT_TIMED_MODE_MINUTES: int = 5

const QUALITY_LOW: String = "低"
const QUALITY_MEDIUM: String = "中"
const QUALITY_HIGH: String = "高"

enum Faction { BLUE, RED, GREEN, YELLOW }

static var _game_mode_name: String = GAME_MODE_BASIC
static var _timed_mode_minutes: int = DEFAULT_TIMED_MODE_MINUTES
static var _quality_name: String = QUALITY_MEDIUM
static var _palette_name: String = "经典"
static var _palette_colors: Array = [
	Color(0.20, 0.49, 1.00),
	Color(1.00, 0.30, 0.22),
	Color(0.20, 0.82, 0.34),
	Color(1.00, 0.82, 0.16),
]
static var _palette_names: Array = ["蓝方", "红方", "绿方", "黄方"]
static var _palette_nicknames: Array = ["小蓝", "小红", "小绿", "小黄"]

static func get_turret_max_health(grid_size: int) -> int:
	match grid_size:
		10:
			return 30
		20:
			return 60
		30:
			return 90
		40:
			return 120
		50:
			return 150
		60:
			return 180
		_:
			return 30

static func get_game_mode_names() -> Array:
	return [GAME_MODE_BASIC, GAME_MODE_OCCUPATION, GAME_MODE_TIMED, GAME_MODE_WILD, GAME_MODE_CARDFRONT]

static func set_game_mode_by_name(name: String) -> void:
	var normalized: String = _normalize_game_mode_name(name)
	if normalized in get_game_mode_names():
		_game_mode_name = normalized
	else:
		_game_mode_name = GAME_MODE_BASIC

static func get_game_mode_name() -> String:
	return _game_mode_name

static func get_occupation_target_percent() -> int:
	return OCCUPATION_TARGET_PERCENT

static func set_time_limit_minutes(minutes: int) -> void:
	_timed_mode_minutes = clampi(minutes, TIMED_MODE_MIN_MINUTES, TIMED_MODE_MAX_MINUTES)

static func get_time_limit_minutes() -> int:
	return clampi(_timed_mode_minutes, TIMED_MODE_MIN_MINUTES, TIMED_MODE_MAX_MINUTES)

static func get_time_limit_seconds() -> float:
	return float(get_time_limit_minutes() * 60)

static func get_gate_multiplier() -> int:
	if _game_mode_name == GAME_MODE_WILD:
		return 3
	return 2

static func get_max_pending_count() -> int:
	if _game_mode_name == GAME_MODE_WILD:
		return WILD_MAX_PENDING_COUNT
	return BASE_MAX_PENDING_COUNT

static func get_quality_names() -> Array:
	return [QUALITY_LOW, QUALITY_MEDIUM, QUALITY_HIGH]

static func set_quality_by_name(name: String) -> void:
	var normalized: String = _normalize_quality_name(name)
	if normalized in get_quality_names():
		_quality_name = normalized
	else:
		_quality_name = QUALITY_MEDIUM

static func get_quality_name() -> String:
	return _quality_name

static func get_max_active_bullets() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 1800
		QUALITY_HIGH:
			return MAX_ACTIVE_BULLETS
		_:
			return 2800

static func get_restore_bullet_limit() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 1000
		QUALITY_HIGH:
			return MAX_ACTIVE_BULLETS
		_:
			return 2600

static func get_restore_per_frame() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 80
		QUALITY_HIGH:
			return 180
		_:
			return 120

static func get_mid_pressure_threshold() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 300
		QUALITY_HIGH:
			return 700
		_:
			return 480

static func get_high_pressure_threshold() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 700
		QUALITY_HIGH:
			return 1400
		_:
			return 900

static func get_force_simple_threshold() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 950
		QUALITY_HIGH:
			return 2400
		_:
			return 1400

static func get_normal_trail_points() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 4
		QUALITY_HIGH:
			return 12
		_:
			return 7

static func get_mid_trail_points() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 2
		QUALITY_HIGH:
			return 6
		_:
			return 4

static func get_high_trail_points() -> int:
	match _quality_name:
		QUALITY_LOW:
			return 0
		QUALITY_HIGH:
			return 2
		_:
			return 1

static func get_trail_mid_segments_threshold() -> int:
	return 500

static func get_trail_high_segments_threshold() -> int:
	return 800

static func get_trail_extreme_segments_threshold() -> int:
	return 1000

static func get_trail_mid_fps_threshold() -> int:
	return 45

static func get_trail_high_fps_threshold() -> int:
	return 30

static func get_trail_extreme_fps_threshold() -> int:
	return 20

static func get_trail_mid_redraws_threshold() -> int:
	return 30

static func get_trail_high_redraws_threshold() -> int:
	return 45

static func get_trail_extreme_redraws_threshold() -> int:
	return 55

static func get_trail_redraw_interval_mid() -> float:
	return 1.0 / 30.0

static func get_trail_redraw_interval_high() -> float:
	return 1.0 / 18.0

static func get_trail_redraw_interval_extreme() -> float:
	return 0.10

static func get_grid_line_alpha() -> float:
	match _quality_name:
		QUALITY_LOW:
			return 0.035
		QUALITY_HIGH:
			return 0.10
		_:
			return 0.065

static func get_emblem_alpha_mul() -> float:
	match _quality_name:
		QUALITY_LOW:
			return 0.35
		QUALITY_HIGH:
			return 1.0
		_:
			return 0.65

static func get_palette_names() -> Array:
	return ["经典", "霓虹", "糖果", "暗夜", "薄荷"]

static func is_test_mode() -> bool:
	return OS.get_cmdline_args().has("--ballwar-test")

static func get_safe_screen_size() -> Vector2i:
	if DisplayServer.get_name().to_lower() == "headless":
		return Vector2i(1280, 720)

	var count: int = DisplayServer.get_screen_count()
	if count <= 0:
		return Vector2i(1280, 720)

	return DisplayServer.screen_get_size()

static func set_random_palette() -> void:
	var names: Array = get_palette_names()
	if names.is_empty():
		return
	set_palette_by_name(str(names[randi() % names.size()]))

static func set_palette_by_name(name: String) -> void:
	var normalized: String = _normalize_palette_name(name)
	_palette_name = normalized

	match normalized:
		"霓虹":
			_palette_colors = [
				Color(0.00, 0.93, 1.00),
				Color(1.00, 0.18, 0.62),
				Color(0.52, 1.00, 0.18),
				Color(1.00, 0.84, 0.10),
			]
			_palette_names = ["青方", "粉方", "荧方", "金方"]
			_palette_nicknames = ["小青", "小粉", "小荧", "小金"]
		"糖果":
			_palette_colors = [
				Color(0.33, 0.73, 1.00),
				Color(1.00, 0.46, 0.52),
				Color(0.36, 0.88, 0.56),
				Color(1.00, 0.77, 0.38),
			]
			_palette_names = ["莓方", "桃方", "糖方", "蜜方"]
			_palette_nicknames = ["小莓", "小桃", "小糖", "小蜜"]
		"暗夜":
			_palette_colors = [
				Color(0.26, 0.43, 0.95),
				Color(0.85, 0.25, 0.28),
				Color(0.22, 0.66, 0.34),
				Color(0.82, 0.64, 0.18),
			]
			_palette_names = ["靛方", "赤方", "森方", "铜方"]
			_palette_nicknames = ["小靛", "小赤", "小森", "小铜"]
		"薄荷":
			_palette_colors = [
				Color(0.23, 0.73, 0.95),
				Color(0.93, 0.39, 0.56),
				Color(0.38, 0.89, 0.73),
				Color(0.96, 0.83, 0.41),
			]
			_palette_names = ["海方", "莓方", "荷方", "杏方"]
			_palette_nicknames = ["小海", "小莓", "小荷", "小杏"]
		_:
			_palette_name = "经典"
			_palette_colors = [
				Color(0.20, 0.49, 1.00),
				Color(1.00, 0.30, 0.22),
				Color(0.20, 0.82, 0.34),
				Color(1.00, 0.82, 0.16),
			]
			_palette_names = ["蓝方", "红方", "绿方", "黄方"]
			_palette_nicknames = ["小蓝", "小红", "小绿", "小黄"]

static func get_palette_name() -> String:
	return _palette_name

static func faction_color(id: int) -> Color:
	if id >= 0 and id < _palette_colors.size():
		return _palette_colors[id]
	return Color.WHITE

static func faction_name(id: int) -> String:
	if id >= 0 and id < _palette_names.size():
		return _palette_names[id]
	return "未知"

static func faction_nickname(id: int) -> String:
	if id >= 0 and id < _palette_nicknames.size():
		return _palette_nicknames[id]
	return "小球"

static func _normalize_game_mode_name(name: String) -> String:
	match name:
		GAME_MODE_BASIC, "basic":
			return GAME_MODE_BASIC
		GAME_MODE_OCCUPATION, "occupation":
			return GAME_MODE_OCCUPATION
		GAME_MODE_TIMED, "timed":
			return GAME_MODE_TIMED
		GAME_MODE_WILD, "wild":
			return GAME_MODE_WILD
		GAME_MODE_CARDFRONT, "cardfront", "cardfront-prototype":
			return GAME_MODE_CARDFRONT
		_:
			return name

static func _normalize_quality_name(name: String) -> String:
	match name:
		QUALITY_LOW, "low":
			return QUALITY_LOW
		QUALITY_MEDIUM, "medium":
			return QUALITY_MEDIUM
		QUALITY_HIGH, "high":
			return QUALITY_HIGH
		_:
			return name

static func reset_runtime_defaults() -> void:
	_game_mode_name = GAME_MODE_BASIC
	_timed_mode_minutes = DEFAULT_TIMED_MODE_MINUTES
	_quality_name = QUALITY_MEDIUM
	set_palette_by_name("经典")

static func _normalize_palette_name(name: String) -> String:
	match name:
		"默认随机":
			return "经典"
		"经典", "霓虹", "糖果", "暗夜", "薄荷":
			return name
		_:
			return "经典"
