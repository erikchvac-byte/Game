extends Node2D

const SPEED := 45.0
const IDLE_DURATION := 2.5
const TRADE_PAUSE := 1.5
const ENTER_HOME_DURATION := 1.0
const NPC_DOOR_IDX := 1

const GEM_TEX := preload("res://GameAssets/Date-time-Coin.png")

var _waypoints := [Vector2(112.0, 150.0), Vector2(534.0, 158.0)]
var _target_idx := 1
var _idle_timer := 0.0

var _is_trading := false
var _trade_completed := false
var _entering_home := false
var _inside_home := false
var _home_elapsed_t := 0.0
var _prev_cycle_t := -1.0

var _player_nearby := false


func _ready() -> void:
	$AnimatedSprite2D.play("idle_south")


func _process(delta: float) -> void:
	if _inside_home:
		_tick_home_cycle()
		return

	if _idle_timer > 0.0:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_idle_timer = 0.0
			if _is_trading:
				_is_trading = false
			if _entering_home:
				_entering_home = false
				_go_inside()
				return
			if not _player_nearby:
				_start_walk()
			else:
				$AnimatedSprite2D.play("idle_south")
		return

	if _player_nearby:
		return

	var target: Vector2 = _waypoints[_target_idx]
	var diff: Vector2 = target - position
	var dist: float = diff.length()

	if dist < 2.0:
		position = target
		_arrive_at_waypoint()
		return

	position += diff.normalized() * SPEED * delta


func _arrive_at_waypoint() -> void:
	var arrived_at := _target_idx
	_target_idx = (_target_idx + 1) % _waypoints.size()

	if arrived_at == NPC_DOOR_IDX and _trade_completed:
		_enter_home()
	else:
		$AnimatedSprite2D.play("idle_south")
		_idle_timer = IDLE_DURATION


func _enter_home() -> void:
	_entering_home = true
	$AnimatedSprite2D.play("walk_north")
	_idle_timer = ENTER_HOME_DURATION


func _go_inside() -> void:
	visible = false
	_inside_home = true
	_home_elapsed_t = 0.0
	var dnc := get_tree().get_first_node_in_group("day_night_cycle")
	_prev_cycle_t = dnc._t if dnc else -1.0


func _tick_home_cycle() -> void:
	var dnc := get_tree().get_first_node_in_group("day_night_cycle")
	if not dnc or _prev_cycle_t < 0.0:
		return
	var current_t: float = dnc._t
	var dt: float = current_t - _prev_cycle_t
	if dt < 0.0:
		dt += 1.0  # wrap around
	_home_elapsed_t += dt
	_prev_cycle_t = current_t
	if _home_elapsed_t >= 1.0:
		_exit_home()


func _exit_home() -> void:
	_inside_home = false
	_trade_completed = false
	position = _waypoints[NPC_DOOR_IDX]
	visible = true
	_target_idx = 0
	if _player_nearby:
		$AnimatedSprite2D.play("idle_south")
	else:
		_start_walk()


func set_player_nearby(nearby: bool) -> void:
	if _player_nearby == nearby:
		return
	_player_nearby = nearby
	if not nearby and not _is_trading and _idle_timer <= 0.0 and not _entering_home and not _inside_home:
		_start_walk()


func face_toward(target_pos: Vector2) -> void:
	if not visible or _entering_home:
		return
	var diff := target_pos - global_position
	if abs(diff.x) >= abs(diff.y):
		$AnimatedSprite2D.play("idle_east" if diff.x > 0 else "idle_west")
	else:
		$AnimatedSprite2D.play("idle_south")


func is_interactable() -> bool:
	return not _is_trading and not _trade_completed


func attempt_trade() -> bool:
	if _is_trading or _trade_completed:
		return false
	var inv := get_node_or_null("/root/Inventory")
	if not inv or not inv.has_method("has_item") or not inv.has_item("bud"):
		return false
	inv.remove_item("bud")
	inv.add_item("gem", GEM_TEX)
	_is_trading = true
	_trade_completed = true
	_target_idx = NPC_DOOR_IDX
	_idle_timer = TRADE_PAUSE
	return true


func _start_walk() -> void:
	if _inside_home:
		return
	var target: Vector2 = _waypoints[_target_idx]
	var dir: Vector2 = (target - position).normalized()
	if dir.x >= 0.0:
		$AnimatedSprite2D.play("walk_east")
	else:
		$AnimatedSprite2D.play("walk_west")
