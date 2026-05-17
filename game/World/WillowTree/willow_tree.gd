extends Node2D

# One-shot proximity animation: plays "shake" once when player enters,
# holds final frame until player leaves AND 120s have elapsed.

const RESET_DELAY := 120.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _area: Area2D = $ProximityArea

var _played := false
var _exit_time := -1.0

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_sprite.animation_finished.connect(_on_anim_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if _played:
		if _exit_time < 0.0:
			return
		var elapsed := Time.get_ticks_msec() / 1000.0 - _exit_time
		if elapsed < RESET_DELAY:
			return
		# Both conditions met: player left AND 120s passed — reset
		_played = false
		_sprite.play("idle")
	_sprite.play("shake")

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_exit_time = Time.get_ticks_msec() / 1000.0

func _on_anim_finished() -> void:
	if _sprite.animation == &"shake":
		_played = true
		_sprite.stop()
		_sprite.frame = _sprite.sprite_frames.get_frame_count("shake") - 1
