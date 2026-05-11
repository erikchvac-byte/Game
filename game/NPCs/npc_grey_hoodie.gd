extends Node2D

const SPEED := 45.0
const IDLE_DURATION := 2.5

# Patrol waypoints: in front of Erik's house, then in front of NPC's house
var _waypoints := [Vector2(165.0, 150.0), Vector2(510.0, 150.0)]
var _target_idx := 1
var _idle_timer := 0.0

func _ready() -> void:
	$AnimatedSprite2D.play("idle_south")

func _process(delta: float) -> void:
	if _idle_timer > 0.0:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_idle_timer = 0.0
			_start_walk()
		return

	var target: Vector2 = _waypoints[_target_idx]
	var diff: Vector2 = target - global_position
	var dist: float = diff.length()

	if dist < 2.0:
		global_position = target
		_idle_timer = IDLE_DURATION
		$AnimatedSprite2D.play("idle_south")
		_target_idx = (_target_idx + 1) % _waypoints.size()
		return

	global_position += diff.normalized() * SPEED * delta

func _start_walk() -> void:
	var target: Vector2 = _waypoints[_target_idx]
	var dir: Vector2 = (target - global_position).normalized()
	if dir.x > 0.1:
		$AnimatedSprite2D.play("walk_east")
	elif dir.x < -0.1:
		$AnimatedSprite2D.play("walk_west")
	elif dir.y > 0.0:
		$AnimatedSprite2D.play("walk_south")
	else:
		$AnimatedSprite2D.play("walk_north")
