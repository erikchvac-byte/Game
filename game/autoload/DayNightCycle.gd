extends Node

@export var cycle_duration: float = 120.0
@export var start_time: float = 0.35

var _t: float

@onready var _mod: CanvasModulate = $"../CanvasModulate"
@onready var _sun: DirectionalLight2D = $"../Sun"

# [normalized_time, Color]  0=midnight  0.5=noon  1=midnight
const _AMBIENT: Array = [
	[0.00, Color(0.20, 0.22, 0.38)],
	[0.23, Color(0.18, 0.20, 0.35)],
	[0.28, Color(0.55, 0.38, 0.28)],
	[0.35, Color(0.88, 0.82, 0.72)],
	[0.50, Color(1.00, 0.98, 0.92)],
	[0.65, Color(0.90, 0.82, 0.65)],
	[0.73, Color(0.70, 0.42, 0.22)],
	[0.80, Color(0.28, 0.18, 0.32)],
	[0.88, Color(0.20, 0.22, 0.38)],
	[1.00, Color(0.20, 0.22, 0.38)],
]

# [normalized_time, energy]
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

# [normalized_time, rotation degrees]  shadows opposite the light direction
const _SUN_ROT: Array = [
	[0.00, -90.0],
	[0.27, -60.0],
	[0.50,  90.0],
	[0.75, 240.0],
	[1.00, 300.0],
]

# [normalized_time, Color]
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

func _process(delta: float) -> void:
	_t = fmod(_t + delta / cycle_duration, 1.0)
	_mod.color = _lerp_color(_AMBIENT, _t)
	_sun.energy = _lerp_float(_SUN_ENERGY, _t)
	_sun.rotation_degrees = _lerp_float(_SUN_ROT, _t)
	_sun.color = _lerp_color(_SUN_COLOR, _t)

static func _lerp_color(keys: Array, t: float) -> Color:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		if t < keys[i + 1][0]:
			var f := (t - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var c0: Color = keys[i][1]
			var c1: Color = keys[i + 1][1]
			return c0.lerp(c1, f)
	return keys[-1][1]

static func _lerp_float(keys: Array, t: float) -> float:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		if t < keys[i + 1][0]:
			var f := (t - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var v0: float = keys[i][1]
			var v1: float = keys[i + 1][1]
			return lerpf(v0, v1, f)
	return keys[-1][1]
