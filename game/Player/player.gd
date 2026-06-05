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
var is_planting := false

var nav_agent: NavigationAgent2D

func _ready() -> void:
	nav_agent = get_node_or_null("NavAgent")
	# Group membership lets interactables identify the player without depending
	# on the node being named "Player" (rename-proof). See door.gd.
	add_to_group("player")

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
	elif nav_agent != null and not nav_agent.is_navigation_finished():
		dir = (nav_agent.get_next_path_position() - global_position).normalized()
		is_running = false
	else:
		dir = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		).normalized()
		is_running = Input.is_action_pressed("run")

	velocity = dir * (RUN_SPEED if is_running else WALK_SPEED)

	# Update facing from input intent (so the player turns to face a wall
	# he's pushing against, even though he won't actually move).
	if dir != Vector2.ZERO:
		_update_facing(dir)

	move_and_slide()

	# is_moving reflects ACTUAL movement (post-collision), not intended
	# velocity — so the walk animation stops when blocked by a wall/collider
	# instead of cycling in place. (length 5 px/s threshold; walk speed is 60.)
	is_moving = get_real_velocity().length_squared() > 25.0

func _update_facing(dir: Vector2) -> void:
	if abs(dir.y) >= abs(dir.x):
		facing = Facing.DOWN if dir.y > 0.0 else Facing.UP
	else:
		facing = Facing.SIDE
		facing_left = dir.x < 0.0
