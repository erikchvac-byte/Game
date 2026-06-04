extends Node2D

const ARRIVE_DIST := 5.0
const NAV_STUCK_MAX := 1.0

var _nav_active := false
var _nav_target_pos := Vector2.ZERO
var _nav_best_dist: float = INF
var _nav_stuck_time: float = 0.0
var _player: CharacterBody2D

# Interactables in range of the player (matches world.gd's pattern). The
# AnimatedDoor on the north wall emits enter/exit and exposes interact().
var _interactables: Array[Node] = []


func _ready() -> void:
	_player = $Player as CharacterBody2D
	var cam := _player.get_node("Camera2D") as Camera2D
	var origin := global_position
	cam.limit_left = int(origin.x)
	cam.limit_top = int(origin.y)
	cam.limit_right = int(origin.x) + 224
	cam.limit_bottom = int(origin.y) + 150
	_player.facing = _player.Facing.UP
	TransitionManager.fade_from_black(0.4)
	var door := $AnimatedDoor
	door.interactable_entered.connect(_on_interactable_entered)
	door.interactable_exited.connect(_on_interactable_exited)
	await get_tree().create_timer(0.5).timeout
	$ExitDoor.body_entered.connect(_on_exit_entered)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _get_nearest_interactable()
		if target and target.has_method("interact"):
			target.interact(_player)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_nav_active = true
		_nav_target_pos = get_global_mouse_position()
		_nav_best_dist = INF
		_nav_stuck_time = 0.0
		get_viewport().set_input_as_handled()


func _on_interactable_entered(node: Node) -> void:
	if not _interactables.has(node):
		_interactables.append(node)


func _on_interactable_exited(node: Node) -> void:
	_interactables.erase(node)


func _get_nearest_interactable() -> Node:
	var nearest: Node = null
	var best := INF
	for node in _interactables:
		if not is_instance_valid(node):
			continue
		var d: float = _player.global_position.distance_squared_to((node as Node2D).global_position)
		if d < best:
			best = d
			nearest = node
	return nearest


func _process(delta: float) -> void:
	if not _nav_active or not _player:
		return
	var dist := _player.global_position.distance_to(_nav_target_pos)
	if dist < ARRIVE_DIST:
		_cancel_navigation()
		return
	if dist < _nav_best_dist - 0.5:
		_nav_best_dist = dist
		_nav_stuck_time = 0.0
	else:
		_nav_stuck_time += delta
		if _nav_stuck_time >= NAV_STUCK_MAX:
			_cancel_navigation()
			return
	_player.auto_walk = (_nav_target_pos - _player.global_position).normalized()


func _cancel_navigation() -> void:
	_nav_active = false
	_nav_best_dist = INF
	_nav_stuck_time = 0.0
	if _player:
		_player.auto_walk = Vector2.ZERO


func _on_exit_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$ExitDoor.body_entered.disconnect(_on_exit_entered)
	_cancel_navigation()
	if _player:
		_player.set_physics_process(false)
	await TransitionManager.fade_to_black(0.4)
	Engine.set_meta("spawn_position", Vector2(112, 150))
	get_tree().change_scene_to_file("res://main.tscn")
