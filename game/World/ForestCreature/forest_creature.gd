extends CharacterBody2D

const WANDER_SPEED := 18.0
const FLEE_SPEED := 34.0
const FLEE_RADIUS := 64.0
const TRUST_HOLD_RADIUS := 32.0
const WANDER_CHANGE_INTERVAL_MIN := 1.5
const WANDER_CHANGE_INTERVAL_MAX := 4.0
const APPROACH_FLEE_MULT := 1.4
const APPROACH_UPWARD_BIAS := 0.35
const APPROACH_VEL_THRESHOLD := 8.0

var _player: CharacterBody2D
var _shrine_mgr: Node
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _anim: AnimatedSprite2D


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	_player = get_tree().current_scene.get_node_or_null("World/Player")
	_shrine_mgr = get_node_or_null("/root/ShrineManager")
	_pick_new_wander_dir()

	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = load("res://resources/characters/hobo_man_sprites.tres")
	_anim.scale = Vector2(0.177, 0.177)
	_anim.play("idle_south")
	add_child(_anim)

	var cshape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 5.0
	cap.height = 10.0
	cshape.shape = cap
	add_child(cshape)


func _physics_process(delta: float) -> void:
	if not _player:
		_player = get_tree().current_scene.get_node_or_null("World/Player")
		return
	var trust: int = _shrine_mgr.trust if _shrine_mgr else 0
	var dist := global_position.distance_to(_player.global_position)

	if dist < FLEE_RADIUS:
		if trust >= 80 and dist > TRUST_HOLD_RADIUS:
			var dir_to_player := (_player.global_position - global_position).normalized()
			var hold_pos := _player.global_position - dir_to_player * TRUST_HOLD_RADIUS
			velocity = (hold_pos - global_position).normalized() * WANDER_SPEED
		else:
			var flee_dir := (global_position - _player.global_position).normalized()
			var player_approaching: bool = _player.velocity.dot(flee_dir) > APPROACH_VEL_THRESHOLD
			var flee_spd := FLEE_SPEED * (APPROACH_FLEE_MULT if player_approaching else 1.0)
			if player_approaching:
				flee_dir = (flee_dir + Vector2(0.0, -APPROACH_UPWARD_BIAS)).normalized()
			velocity = flee_dir * flee_spd
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_new_wander_dir()
		velocity = _wander_dir * WANDER_SPEED

	move_and_slide()
	_update_animation()


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
		# Keep last facing — derive from current animation suffix
		if _anim and _anim.animation != "":
			return _anim.animation.split("_")[-1]
		return "south"
	var angle := velocity.angle()
	# Snap to 4 dirs: right=east, left=west, up=north, down=south
	if abs(angle) < PI / 4.0:
		return "east"
	elif abs(angle) > 3.0 * PI / 4.0:
		return "west"
	elif angle > 0:
		return "south"
	else:
		return "north"


func _pick_new_wander_dir() -> void:
	_wander_timer = randf_range(WANDER_CHANGE_INTERVAL_MIN, WANDER_CHANGE_INTERVAL_MAX)
	var angle := randf() * TAU
	_wander_dir = Vector2(cos(angle), sin(angle))
	if randf() < 0.25:
		_wander_dir = Vector2.ZERO
