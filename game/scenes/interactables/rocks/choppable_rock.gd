extends StaticBody2D

signal interactable_entered(node)
signal interactable_exited(node)
signal rock_broken

@export var hits_required: int = 3

@onready var _rock_sprite: AnimatedSprite2D = $RockSprite
@onready var _rock_col: CollisionShape2D = $RockCollider
@onready var _interact_area: Area2D = $InteractArea

enum State { IDLE, HIT, BREAKING, PILE }
var _state: State = State.IDLE
var _hits_done: int = 0
var _has_hit_anim: bool = false

func _ready() -> void:
	add_to_group("choppable_rocks")
	_has_hit_anim = _rock_sprite.sprite_frames.has_animation(&"hit")
	_rock_sprite.play(&"idle")
	_rock_sprite.animation_finished.connect(_on_anim_finished)
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

func can_interact(player: Node) -> bool:
	return _state == State.IDLE and player.equipped_tool == "axe"

func interact(_player: Node) -> void:
	if _state != State.IDLE or _player.equipped_tool != "axe":
		return
	_state = State.HIT
	_hits_done += 1
	get_tree().create_timer(0.3).timeout.connect(_begin_rock_reaction)

func _begin_rock_reaction() -> void:
	if _state != State.HIT:
		return
	if _hits_done >= hits_required:
		_state = State.BREAKING
		_rock_sprite.play(&"break")
	elif _has_hit_anim:
		_rock_sprite.play(&"hit")
	else:
		_state = State.IDLE

func _on_anim_finished() -> void:
	match _rock_sprite.animation:
		&"hit":
			_state = State.IDLE
			_rock_sprite.play(&"idle")
		&"break":
			_rock_col.disabled = true
			_rock_sprite.play(&"pile")
			_state = State.PILE
			rock_broken.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		interactable_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		interactable_exited.emit(self)
