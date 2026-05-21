extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)

var _collecting := false
var _player_in_range := false

func _ready() -> void:
	$WellArea.body_entered.connect(_on_area_entered)
	$WellArea.body_exited.connect(_on_area_exited)
	_reset_sprite()

func _reset_sprite() -> void:
	$WellWater.speed_scale = 1.0
	$WellWater.play("default")
	$WellWater.stop()
	$WellWater.frame = 0

func blocked_message(player: CharacterBody2D) -> String:
	if player.carrying_water:
		return "Already carrying water"
	return ""

func can_interact(player: CharacterBody2D) -> bool:
	return not _collecting and not player.carrying_water

func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		return
	_collecting = true
	$WellWater.speed_scale = 2.22
	$WellWater.play_backwards("default")
	await get_tree().create_timer(0.25).timeout
	_reset_sprite()
	_collecting = false
	player.carrying_water = true
	var hud = get_node_or_null("/root/HUD")
	if hud:
		hud.set_carrying_water(true)

func _on_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = true
	interactable_entered.emit(self)

func _on_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = false
	_reset_sprite()
	interactable_exited.emit(self)
