extends CharacterBody2D

enum Facing { DOWN, UP, SIDE }

const WALK_SPEED := 60.0
const RUN_SPEED := 110.0

var facing: Facing = Facing.DOWN
var is_moving := false
var is_running := false
var facing_left := false
var carrying_water := false
var equipped_tool: String = ""
var auto_walk := Vector2.ZERO
var is_chopping := false
var is_trading := false

func facing_name() -> String:
	match facing:
		Facing.UP: return "up"
		Facing.SIDE: return "side"
		_: return "down"

func _physics_process(_delta: float) -> void:
	var dir: Vector2
	if auto_walk != Vector2.ZERO:
		dir = auto_walk.normalized()
		is_running = false
	else:
		dir = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		).normalized()
		is_running = Input.is_action_pressed("run")

	velocity = dir * (RUN_SPEED if is_running else WALK_SPEED)
	is_moving = velocity.length_squared() > 0.0

	if is_moving:
		_update_facing(dir)

	move_and_slide()

func _update_facing(dir: Vector2) -> void:
	if abs(dir.y) >= abs(dir.x):
		facing = Facing.DOWN if dir.y > 0.0 else Facing.UP
	else:
		facing = Facing.SIDE
		facing_left = dir.x < 0.0
