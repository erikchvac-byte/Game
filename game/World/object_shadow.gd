extends Node2D

## Stardew-style grounded shadow.
## Attach as child of any world object.
## ground_offset: vector from node origin to the object's ground-contact centre.
## shadow_size:   base ellipse half-extents (x=width, y=depth). Width should
##                match the object's horizontal footprint at ground level.
## cast_length:   how far the shadow tip travels at max (dawn/dusk).

@export var ground_offset: Vector2 = Vector2.ZERO
@export var shadow_size: Vector2 = Vector2(10, 4)
@export var cast_length: float = 16.0

var _dnc: Node = null

func _ready() -> void:
	z_as_relative = false
	z_index = 0
	show_behind_parent = true

func _process(_delta: float) -> void:
	if _dnc == null:
		_dnc = get_tree().get_first_node_in_group("day_night_cycle")
	queue_redraw()

func _draw() -> void:
	if _dnc == null:
		return
	var alpha: float = _dnc.shadow_alpha
	if alpha < 0.01:
		return

	var dir: Vector2 = _dnc.shadow_dir
	var len_f: float = _dnc.shadow_length_factor

	# Shadow shifts horizontally from ground contact; Y flattened for top-down look.
	# The ellipse does NOT rotate — it stays as a flat horizontal oval.
	var shift_x: float = dir.x * cast_length * len_f
	var shift_y: float = dir.y * cast_length * len_f * 0.25
	var centre: Vector2 = ground_offset + Vector2(shift_x, shift_y)

	# Width stretches slightly as shadow lengthens; depth stays fixed.
	var w: float = shadow_size.x + absf(shift_x) * 0.18
	var h: float = shadow_size.y

	# Two-pass soft look: faint outer halo + solid inner core.
	_draw_ellipse(centre, Vector2(w * 1.45, h * 1.6), Color(0.0, 0.0, 0.0, alpha * 0.28))
	_draw_ellipse(centre, Vector2(w, h),               Color(0.0, 0.0, 0.0, alpha * 0.82))

func _draw_ellipse(centre: Vector2, radius: Vector2, color: Color) -> void:
	const N := 20
	var pts: PackedVector2Array
	pts.resize(N)
	for i in N:
		var a: float = TAU * i / N
		pts[i] = centre + Vector2(cos(a) * radius.x, sin(a) * radius.y)
	draw_colored_polygon(pts, color)
