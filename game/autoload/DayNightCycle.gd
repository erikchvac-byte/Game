extends Node

@export var cycle_duration: float = 120.0
@export var start_time: float = 0.35

# Read by object_shadow.gd nodes each frame
var shadow_dir: Vector2 = Vector2(0.0, 1.0)
var shadow_alpha: float = 0.0
var shadow_length_factor: float = 0.5

var _t: float

@onready var _mod: CanvasModulate = $"../CanvasModulate"
@onready var _sun: DirectionalLight2D = $"../Sun"

const _AMBIENT: Array = [
	[0.00, Color(0.38, 0.42, 0.62)],
	[0.23, Color(0.35, 0.38, 0.58)],
	[0.28, Color(0.60, 0.42, 0.32)],
	[0.35, Color(0.88, 0.82, 0.72)],
	[0.50, Color(1.00, 0.98, 0.92)],
	[0.65, Color(0.90, 0.82, 0.65)],
	[0.73, Color(0.70, 0.42, 0.22)],
	[0.80, Color(0.42, 0.32, 0.52)],
	[0.88, Color(0.38, 0.42, 0.62)],
	[1.00, Color(0.38, 0.42, 0.62)],
]

const _SUN_ENERGY: Array = [
	[0.00, 0.00],
	[0.25, 0.00],
	[0.30, 0.20],
	[0.40, 0.42],
	[0.50, 0.45],
	[0.65, 0.38],
	[0.73, 0.18],
	[0.78, 0.00],
	[1.00, 0.00],
]

const _SUN_ROT: Array = [
	[0.00, -90.0],
	[0.27, -60.0],
	[0.50,  90.0],
	[0.75, 240.0],
	[1.00, 300.0],
]

const _SUN_COLOR: Array = [
	[0.28, Color(1.0, 0.65, 0.35)],
	[0.38, Color(1.0, 0.92, 0.72)],
	[0.50, Color(1.0, 0.98, 0.90)],
	[0.65, Color(1.0, 0.90, 0.62)],
	[0.73, Color(1.0, 0.55, 0.18)],
	[0.78, Color(0.75, 0.25, 0.08)],
]

func _ready() -> void:
	_t = start_time
	add_to_group("day_night_cycle")

func _process(delta: float) -> void:
	_t = fmod(_t + delta / cycle_duration, 1.0)
	_mod.color = _lerp_color(_AMBIENT, _t)
	var energy: float = _lerp_float(_SUN_ENERGY, _t)
	_sun.energy = energy
	_sun.rotation_degrees = _lerp_float(_SUN_ROT, _t)
	_sun.color = _lerp_color(_SUN_COLOR, _t)
	_update_shadow(energy)

func _update_shadow(energy: float) -> void:
	shadow_alpha = energy * 0.48

	# day_t: 0 = sunrise (t≈0.27), 0.5 = noon (t≈0.50), 1 = sunset (t≈0.75)
	var day_t: float = clampf((_t - 0.27) / 0.48, 0.0, 1.0)

	# Shadow direction: morning → left+down, noon → straight down, evening → right+down
	var dir_deg: float = lerpf(170.0, 10.0, day_t)
	var r: float = deg_to_rad(dir_deg)
	shadow_dir = Vector2(cos(r), sin(r))

	# Shadow length: longest at edges of day, shortest at noon
	var noon_dist: float = absf(day_t - 0.5) * 2.0  # 0 at noon, 1 at dawn/dusk
	shadow_length_factor = lerpf(0.15, 1.0, noon_dist)

static func _lerp_color(keys: Array, t: float) -> Color:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		if t < keys[i + 1][0]:
			var f: float = (t - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var c0: Color = keys[i][1]
			var c1: Color = keys[i + 1][1]
			return c0.lerp(c1, f)
	return keys[-1][1]

static func _lerp_float(keys: Array, t: float) -> float:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		if t < keys[i + 1][0]:
			var f: float = (t - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var v0: float = keys[i][1]
			var v1: float = keys[i + 1][1]
			return lerpf(v0, v1, f)
	return keys[-1][1]
