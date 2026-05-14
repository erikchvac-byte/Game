extends Node2D

const SPEED := 45.0
const IDLE_DURATION := 2.5
const TRADE_WAIT_DURATION := 10.0
const TRADE_PAUSE := 1.5
const PLAYER_DOOR_IDX := 0

const GEM_TEX := preload("res://GameAssets/UI/WaterGem.png")

signal arrived_for_trade
signal departed_from_trade

var _waypoints := [Vector2(112.0, 150.0), Vector2(534.0, 158.0)]
var _target_idx := 1
var _idle_timer := 0.0
var _trade_wait := false
var _trade_pause := false
var _trade_done_this_visit := false


func _ready() -> void:
	$AnimatedSprite2D.play("idle_south")


func _process(delta: float) -> void:
	if _idle_timer > 0.0:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_idle_timer = 0.0
			if _trade_wait:
				_trade_wait = false
				departed_from_trade.emit()
			_trade_pause = false
			_start_walk()
		return

	if _trade_wait:
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
	$AnimatedSprite2D.play("idle_south")
	var arrived_at := _target_idx
	_target_idx = (_target_idx + 1) % _waypoints.size()

	if arrived_at == PLAYER_DOOR_IDX and not _trade_done_this_visit:
		_trade_wait = true
		_idle_timer = TRADE_WAIT_DURATION
		arrived_for_trade.emit()
	else:
		if arrived_at != PLAYER_DOOR_IDX:
			_trade_done_this_visit = false
		_idle_timer = IDLE_DURATION


func attempt_trade() -> bool:
	if not _trade_wait:
		return false
	var inv := get_node_or_null("/root/Inventory")
	if not inv or not inv.has_method("has_item") or not inv.has_item("bud"):
		return false
	inv.remove_item("bud")
	inv.add_item("gem", GEM_TEX)
	_trade_wait = false
	_trade_done_this_visit = true
	_trade_pause = true
	_idle_timer = TRADE_PAUSE
	departed_from_trade.emit()
	return true


func _start_walk() -> void:
	var target: Vector2 = _waypoints[_target_idx]
	var dir: Vector2 = (target - position).normalized()
	if dir.x >= 0.0:
		$AnimatedSprite2D.play("walk_east")
	else:
		$AnimatedSprite2D.play("walk_west")
