extends CharacterBody2D

const WANDER_SPEED           := 18.0
const FLEE_SPEED             := 34.0
const FLEE_RADIUS            := 64.0
const APPROACH_FLEE_MULT     := 1.4
const APPROACH_UPWARD_BIAS   := 0.35
const APPROACH_VEL_THRESHOLD := 8.0
const ARRIVE_RADIUS          := 12.0
const STUMP_EXCLUSION_RADIUS := 80.0
const HOP_NEAR_RADIUS        := 150.0
const MAP_MIN_X := 215.0
const MAP_MIN_Y := 108.0
const MAP_MAX_X := 815.0
const MAP_MAX_Y := 564.0

enum State { TREE_HOP, FLEE }

var _state     := State.TREE_HOP
var _player    : CharacterBody2D
var _anim      : AnimatedSprite2D
var _trees     : Array  = []
var _target    : Node2D = null
var _stump_pos : Vector2 = Vector2.ZERO


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	_player = get_tree().current_scene.get_node_or_null("World/Player")
	_anim = $CreatureSprite
	call_deferred("_gather_trees")


func _gather_trees() -> void:
	_trees = []
	var stump := get_parent().get_node_or_null("StumpHome001") as Node2D
	if stump:
		_stump_pos = stump.global_position

	for t in get_tree().get_nodes_in_group("choppable_trees"):
		_trees.append(t)
	var world_node := get_parent()
	if world_node:
		for child in world_node.get_children():
			var n: String = child.name
			if ("Tree" in n or "Pine" in n or "Maple" in n or "Fir" in n or "Willow" in n) and not _trees.has(child):
				_trees.append(child)
	_pick_next_tree()


func _physics_process(_delta: float) -> void:
	if not _player:
		_player = get_tree().current_scene.get_node_or_null("World/Player")
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist < FLEE_RADIUS:
		_handle_flee()
		move_and_slide()
		_update_animation()
		return

	if _state == State.FLEE:
		_state = State.TREE_HOP
		_pick_next_tree()

	_do_tree_hop()
	move_and_slide()
	_update_animation()


func _handle_flee() -> void:
	_state = State.FLEE
	var flee_dir := (global_position - _player.global_position).normalized()
	var approaching := _player.velocity.dot(flee_dir) > APPROACH_VEL_THRESHOLD
	var spd := FLEE_SPEED * (APPROACH_FLEE_MULT if approaching else 1.0)
	if approaching:
		flee_dir = (flee_dir + Vector2(0.0, -APPROACH_UPWARD_BIAS)).normalized()
	var refuge := _tree_in_dir(flee_dir, 80.0)
	if refuge != null:
		flee_dir = ((refuge as Node2D).global_position - global_position).normalized()
	velocity = flee_dir * spd


func _do_tree_hop() -> void:
	if _target == null or not is_instance_valid(_target):
		_pick_next_tree()
		if _target == null:
			velocity = Vector2.ZERO
			return
	var diff: Vector2 = _target.global_position - global_position
	if diff.length() <= ARRIVE_RADIUS:
		_pick_next_tree()
	else:
		velocity = diff.normalized() * WANDER_SPEED


func _pick_next_tree() -> void:
	_prune_trees()
	if _trees.is_empty():
		_target = null
		return

	var safe: Array = []
	for t in _trees:
		if t == _target:
			continue
		var t_node := t as Node2D
		if not t_node.visible:
			continue
		var gp: Vector2 = t_node.global_position
		if gp.x <= MAP_MIN_X or gp.x >= MAP_MAX_X or gp.y <= MAP_MIN_Y or gp.y >= MAP_MAX_Y:
			continue
		if _stump_pos != Vector2.ZERO and gp.distance_to(_stump_pos) < STUMP_EXCLUSION_RADIUS:
			continue
		safe.append(t)

	if safe.is_empty():
		_target = null
		return

	var near: Array = []
	for t in safe:
		if global_position.distance_to((t as Node2D).global_position) <= HOP_NEAR_RADIUS:
			near.append(t)
	var pool: Array = near if not near.is_empty() else safe
	_target = pool[randi() % pool.size()] as Node2D


func _prune_trees() -> void:
	var valid: Array = []
	for t in _trees:
		if is_instance_valid(t):
			valid.append(t)
	_trees = valid


func _tree_in_dir(dir: Vector2, max_dist: float) -> Node:
	var best: Node = null
	var best_score := -INF
	for t in _trees:
		if not is_instance_valid(t):
			continue
		var to_t: Vector2 = (t as Node2D).global_position - global_position
		var d: float = to_t.length()
		if d < 4.0 or d > max_dist:
			continue
		var dot: float = to_t.normalized().dot(dir)
		if dot < 0.2:
			continue
		var score: float = dot - d * 0.01
		if score > best_score:
			best_score = score
			best = t
	return best


func _update_animation() -> void:
	if not _anim:
		return
	if velocity.length_squared() < 4.0:
		var idle := "idle_" + _facing_name()
		if _anim.animation != idle:
			_anim.play(idle)
	else:
		var walk := "walk_" + _facing_name()
		if _anim.animation != walk:
			_anim.play(walk)


func _facing_name() -> String:
	if velocity.length_squared() < 4.0:
		if _anim and _anim.animation != "":
			return _anim.animation.split("_")[-1]
		return "south"
	var angle := velocity.angle()
	if abs(angle) < PI / 4.0:
		return "east"
	elif abs(angle) > 3.0 * PI / 4.0:
		return "west"
	elif angle > 0:
		return "south"
	else:
		return "north"
