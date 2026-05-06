extends Node2D

## Stardew-style grounded shadow. Attach as child of any world object.
## Position this node at the object's LOCAL origin; set ground_offset to
## the vector from that origin to the centre of the ground contact point.

@export var ground_offset: Vector2 = Vector2.ZERO
@export var shadow_size: Vector2 = Vector2(10, 4)   ## base ellipse (half-extents)
@export var cast_length: float = 16.0               ## max elongation distance

var _dnc: Node = null

func _ready() -> void:
	z_as_relative = false
	z_index = 0

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
	var cast: float = cast_length * len_f

	# Shadow centre: halfway between ground contact and cast tip
	var tip: Vector2 = ground_offset + dir * cast
	var centre: Vector2 = (ground_offset + tip) * 0.5

	# Ellipse: elongated along shadow direction
	var ex: float = shadow_size.x + cast * 0.4
	var ey: float = shadow_size.y
	var angle: float = dir.angle()

	# Soft edge: outer ring + solid core
	_draw_ellipse(centre, Vector2(ex * 1.35, ey * 1.35), angle, Color(0.0, 0.0, 0.0, alpha * 0.35))
	_draw_ellipse(centre, Vector2(ex, ey), angle, Color(0.0, 0.0, 0.0, alpha))

func _draw_ellipse(centre: Vector2, radius: Vector2, angle: float, color: Color) -> void:
	const N := 18
	var pts: PackedVector2Array
	pts.resize(N)
	for i in N:
		var a: float = TAU * i / N
		pts[i] = centre + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(angle)
	draw_colored_polygon(pts, color)
