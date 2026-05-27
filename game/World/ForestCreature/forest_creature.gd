extends CharacterBody2D

const WANDER_SPEED           := 18.0
const FLEE_SPEED             := 34.0
const FLEE_RADIUS            := 64.0
const FLEE_EXIT_RADIUS       := 90.0   # hysteresis — only exit FLEE when this far away
const APPROACH_VEL_THRESHOLD := 8.0
const APPROACH_FLEE_MULT     := 1.4
const APPROACH_UPWARD_BIAS   := 0.35
const ARRIVE_RADIUS          := 12.0
const STUMP_EXCLUSION_RADIUS := 80.0
const HOP_NEAR_RADIUS        := 150.0
const MAP_MIN_X              := 215.0
const MAP_MIN_Y              := 108.0
const MAP_MAX_X              := 815.0
const MAP_MAX_Y              := 445.0   # brick wall top (~global y=435); keep ShT in grass

# Panic burst
const PANIC_DIST             := 28.0   # distance threshold that triggers panic speed
const PANIC_APPROACH_THRESH  := 18.0   # player approach speed that triggers panic
const PANIC_SPEED_MULT       := 1.75   # speed multiplier at full panic
const WARY_IDLE_SPEED_FRAC   := 0.40   # fraction of FLEE_SPEED when player is idle nearby

# Speed interpolation rates (applied per second)
const SPEED_LERP_NORMAL      := 4.0
const SPEED_LERP_PANIC       := 10.0

# Stuck detection
const STUCK_CHECK_SEC        := 0.35   # sample interval in seconds
const STUCK_DIST_THRESH      := 5.0    # px moved per interval to count as "not stuck"
const STUCK_COUNT_TRIGGER    := 3      # consecutive stuck samples before teleport

# Off-screen respawn geometry (camera zoom 0.87 on 320x180 viewport)
const CAM_HALF_W             := 184.0
const CAM_HALF_H             := 104.0
const OFF_SCREEN_PAD         := 35.0   # extra distance beyond screen edge to spawn
const RESPAWN_TRIES          := 20

enum State { TREE_HOP, FLEE }

var _state          := State.TREE_HOP
var _player         : CharacterBody2D
var _anim           : AnimatedSprite2D
var _trees          : Array  = []
var _target         : Node2D = null
var _stump_pos      : Vector2 = Vector2.ZERO
var _cur_flee_speed := FLEE_SPEED
var _stuck_timer    := 0.0
var _stuck_last_pos := Vector2.ZERO
var _stuck_count    := 0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	_player = get_tree().current_scene.get_node_or_null("World/Player")
	_anim = $CreatureSprite
	_stuck_last_pos = global_position
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


func _physics_process(delta: float) -> void:
	if not _player:
		_player = get_tree().current_scene.get_node_or_null("World/Player")
		return

	var dist := global_position.distance_to(_player.global_position)

	var exit_radius := FLEE_EXIT_RADIUS if _state == State.FLEE else FLEE_RADIUS
	if dist < exit_radius:
		_handle_flee(delta)
		_check_stuck(delta)
		move_and_slide()
		_update_animation()
		return

	if _state == State.FLEE:
		_state = State.TREE_HOP
		_cur_flee_speed = FLEE_SPEED
		_stuck_count = 0
		_pick_next_tree()

	_reset_stuck_tracking()
	_do_tree_hop()
	move_and_slide()
	_update_animation()


func _handle_flee(delta: float) -> void:
	_state = State.FLEE

	var flee_dir := (global_position - _player.global_position).normalized()

	# Positive = player moving toward ShT
	var approach_spd  := _player.velocity.dot(flee_dir)
	var player_moving := _player.velocity.length_squared() > 25.0
	var dist          := global_position.distance_to(_player.global_position)

	var panic := dist < PANIC_DIST or approach_spd > PANIC_APPROACH_THRESH

	if panic:
		flee_dir = (flee_dir + Vector2(0.0, -APPROACH_UPWARD_BIAS)).normalized()
		_cur_flee_speed = lerp(_cur_flee_speed, FLEE_SPEED * PANIC_SPEED_MULT, delta * SPEED_LERP_PANIC)
	elif approach_spd > APPROACH_VEL_THRESHOLD:
		flee_dir = (flee_dir + Vector2(0.0, -APPROACH_UPWARD_BIAS)).normalized()
		_cur_flee_speed = lerp(_cur_flee_speed, FLEE_SPEED * APPROACH_FLEE_MULT, delta * SPEED_LERP_NORMAL)
	elif not player_moving:
		# Player idle: stay nervous but slow — never fully stop
		_cur_flee_speed = lerp(_cur_flee_speed, FLEE_SPEED * WARY_IDLE_SPEED_FRAC, delta * SPEED_LERP_NORMAL)
	else:
		_cur_flee_speed = lerp(_cur_flee_speed, FLEE_SPEED, delta * SPEED_LERP_NORMAL)

	# Steer toward a refuge tree if one is in the flee direction
	var refuge := _tree_in_dir(flee_dir, 80.0)
	if refuge != null:
		flee_dir = ((refuge as Node2D).global_position - global_position).normalized()

	velocity = flee_dir * _cur_flee_speed

	# Immediate escape if cornered at map boundary
	_check_map_edge()


func _check_map_edge() -> void:
	const EDGE_MARGIN := 10.0
	var at_edge := (
		global_position.x <= MAP_MIN_X + EDGE_MARGIN or
		global_position.x >= MAP_MAX_X - EDGE_MARGIN or
		global_position.y <= MAP_MIN_Y + EDGE_MARGIN or
		global_position.y >= MAP_MAX_Y - EDGE_MARGIN
	)
	if at_edge:
		_teleport_escape()


func _check_stuck(delta: float) -> void:
	_stuck_timer += delta
	if _stuck_timer < STUCK_CHECK_SEC:
		return
	_stuck_timer = 0.0
	var moved := global_position.distance_to(_stuck_last_pos)
	_stuck_last_pos = global_position
	if moved < STUCK_DIST_THRESH:
		_stuck_count += 1
		if _stuck_count >= STUCK_COUNT_TRIGGER:
			_teleport_escape()
	else:
		_stuck_count = 0


func _reset_stuck_tracking() -> void:
	_stuck_timer    = 0.0
	_stuck_count    = 0
	_stuck_last_pos = global_position


func _teleport_escape() -> void:
	_stuck_count    = 0
	_stuck_timer    = 0.0
	_cur_flee_speed = FLEE_SPEED
	visible         = false

	var new_pos     := _pick_respawn_pos()
	global_position  = new_pos
	_stuck_last_pos  = new_pos

	visible = true
	_state  = State.TREE_HOP
	_pick_next_tree()


func _pick_respawn_pos() -> Vector2:
	if not _player:
		return global_position

	var pp := _player.global_position

	for _i in range(RESPAWN_TRIES):
		var side := randi() % 4
		var x: float
		var y: float
		match side:
			0:  # left of screen
				x = pp.x - CAM_HALF_W - OFF_SCREEN_PAD - randf_range(0.0, 30.0)
				y = randf_range(pp.y - CAM_HALF_H, pp.y + CAM_HALF_H)
			1:  # right of screen
				x = pp.x + CAM_HALF_W + OFF_SCREEN_PAD + randf_range(0.0, 30.0)
				y = randf_range(pp.y - CAM_HALF_H, pp.y + CAM_HALF_H)
			2:  # above screen
				x = randf_range(pp.x - CAM_HALF_W, pp.x + CAM_HALF_W)
				y = pp.y - CAM_HALF_H - OFF_SCREEN_PAD - randf_range(0.0, 30.0)
			_:  # below screen
				x = randf_range(pp.x - CAM_HALF_W, pp.x + CAM_HALF_W)
				y = pp.y + CAM_HALF_H + OFF_SCREEN_PAD + randf_range(0.0, 30.0)

		x = clampf(x, MAP_MIN_X + 16.0, MAP_MAX_X - 16.0)
		y = clampf(y, MAP_MIN_Y + 16.0, MAP_MAX_Y - 16.0)
		var candidate := Vector2(x, y)

		# Reject if still on-screen after map-boundary clamping
		if absf(candidate.x - pp.x) < CAM_HALF_W and absf(candidate.y - pp.y) < CAM_HALF_H:
			continue
		# Reject if too close to stump
		if _stump_pos != Vector2.ZERO and candidate.distance_to(_stump_pos) < STUMP_EXCLUSION_RADIUS:
			continue

		return candidate

	# Fallback: farthest map corner from player, not near stump
	var corners := [
		Vector2(MAP_MIN_X + 20.0, MAP_MIN_Y + 20.0),
		Vector2(MAP_MAX_X - 20.0, MAP_MIN_Y + 20.0),
		Vector2(MAP_MIN_X + 20.0, MAP_MAX_Y - 20.0),
		Vector2(MAP_MAX_X - 20.0, MAP_MAX_Y - 20.0),
	]
	corners.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_to(pp) > b.distance_to(pp)
	)
	for c: Vector2 in corners:
		if _stump_pos == Vector2.ZERO or c.distance_to(_stump_pos) >= STUMP_EXCLUSION_RADIUS:
			return c
	return corners[0]


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
	# While fleeing: always walk — never show idle, even at wary-idle speed
	if _state == State.FLEE:
		var walk := "walk_" + _facing_name()
		if _anim.animation != walk:
			_anim.play(walk)
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
