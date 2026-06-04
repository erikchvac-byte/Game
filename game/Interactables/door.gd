extends Node2D

# Animated interior door. Matches the interactable pattern (well.gd): emits
# interactable_entered / interactable_exited when the player is in range and
# exposes interact(player) so the scene's interact handler can fire it on the
# "interact" action (Space). The door is decorative — it carries no collision
# body, so it never blocks player movement (the wall behind it does).
#
# The "open" animation is the full GIF cycle (closed -> opens inward -> closed),
# played ONCE per interaction, never looped. The _animating guard prevents a
# re-trigger while it is mid-swing. The door rests on frame 0 (closed) and the
# cycle ends back on the closed frame, so closed is always the idle state.

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)

var _animating := false

func _ready() -> void:
	$DoorArea.body_entered.connect(_on_area_entered)
	$DoorArea.body_exited.connect(_on_area_exited)
	$DoorSprite.animation_finished.connect(_on_animation_finished)
	# Rest on the closed door. The "open" animation's frame 0 (frame_000) is the
	# fully-closed state.
	$DoorSprite.animation = "open"
	$DoorSprite.frame = 0
	$DoorSprite.stop()

func interact(_player: CharacterBody2D) -> void:
	if _animating:
		return
	_animating = true
	$DoorSprite.play("open")

func _on_animation_finished() -> void:
	_animating = false
	# Settle back on the closed frame so closed is always the idle state.
	$DoorSprite.animation = "open"
	$DoorSprite.frame = 0
	$DoorSprite.stop()

func _on_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactable_entered.emit(self)

func _on_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactable_exited.emit(self)
