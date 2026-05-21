extends StaticBody2D

signal interactable_entered(node)
signal interactable_exited(node)
signal tree_chopped

@export var species: String = "pine"
@export var chops_required: int = 3
@export var stump_y_offset: float = 28.0

@onready var _tree_sprite: AnimatedSprite2D = $TreeSprite
@onready var _stump_sprite: AnimatedSprite2D = $StumpSprite
@onready var _trunk_col: CollisionShape2D = $TrunkCollider
@onready var _stump_col: CollisionShape2D = $StumpCollider
@onready var _interact_area: Area2D = $InteractArea
@onready var _interact_col: CollisionShape2D = $InteractArea/InteractCol

enum State { IDLE, CHOPPING, FALLING, STUMP }
var _state: State = State.IDLE
var _chops_done: int = 0
var _player: Node = null

func _ready() -> void:
	add_to_group("choppable_trees")
	_stump_sprite.visible = false
	_stump_sprite.position = Vector2(0.0, stump_y_offset)
	_stump_col.position = Vector2(0.0, stump_y_offset)
	_stump_col.disabled = true
	_tree_sprite.play("idle")
	_tree_sprite.animation_finished.connect(_on_tree_anim_finished)
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)

func can_interact(player: Node) -> bool:
	return _state == State.IDLE and player.equipped_tool == "axe"

func interact(player: Node) -> void:
	if _state != State.IDLE or player.equipped_tool != "axe":
		return
	_player = player
	_player.is_chopping = true
	_state = State.CHOPPING
	_chops_done += 1
	# Player swing happens first; tree reacts 0.5s later
	get_tree().create_timer(0.5).timeout.connect(_begin_tree_reaction)

func _begin_tree_reaction() -> void:
	if _state != State.CHOPPING:
		return
	if _player:
		_player.is_chopping = false
	_tree_sprite.play("chop")

func _on_tree_anim_finished() -> void:
	if _state == State.CHOPPING:
		if _chops_done >= chops_required:
			_state = State.FALLING
			var fall_anim := "fall"
			if species == "maple" and randf() < 0.5:
				fall_anim = "hit_fall"
			_tree_sprite.play(fall_anim)
		else:
			_state = State.IDLE
			_tree_sprite.play("idle")
	elif _state == State.FALLING:
		_tree_sprite.visible = false
		_stump_sprite.stop()
		_stump_sprite.animation = &"idle"
		_stump_sprite.frame = 0
		_stump_sprite.visible = true
		_trunk_col.disabled = true
		_interact_col.disabled = true
		_stump_col.disabled = false
		_state = State.STUMP
		tree_chopped.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		interactable_entered.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		interactable_exited.emit(self)
