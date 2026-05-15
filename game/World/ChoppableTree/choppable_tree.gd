extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)
signal wood_chopped

@export var tree_texture: Texture2D
@export var stump_texture: Texture2D
@export var tree_visual_scale: Vector2 = Vector2(1.0, 1.0)
@export var stump_offset: Vector2 = Vector2(0.0, 40.0)
@export var stump_visual_scale: Vector2 = Vector2(0.5, 0.5)
@export var stump_flip_h: bool = false
@export var chops_required: int = 3

var _chop_count: int = 0
var _is_chopped: bool = false


func _ready() -> void:
	$TreeSprite.texture = tree_texture
	$TreeSprite.scale = tree_visual_scale
	if stump_texture:
		$StumpSprite.texture = stump_texture
	$StumpSprite.position = stump_offset
	$StumpSprite.scale = stump_visual_scale
	$StumpSprite.flip_h = stump_flip_h
	$StumpSprite.visible = false
	$ChopArea.body_entered.connect(_on_body_entered)
	$ChopArea.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not _is_chopped:
		interactable_entered.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		interactable_exited.emit(self)


func can_interact(player: CharacterBody2D) -> bool:
	return not _is_chopped and player.equipped_tool == "axe"


func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		return
	_chop_count += 1
	if _chop_count >= chops_required:
		_do_chop()


func _do_chop() -> void:
	_is_chopped = true
	$TreeSprite.visible = false
	$StumpSprite.visible = true
	$TreeCollider/CollisionShape2D.disabled = true
	wood_chopped.emit()
