extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)

var _collecting := false
var _player_in_range := false

func _ready() -> void:
	$WellArea.body_entered.connect(_on_area_entered)
	$WellArea.body_exited.connect(_on_area_exited)
	$WellWater.animation_finished.connect(_on_water_animation_finished)
	$WellWater.stop()

func _on_water_animation_finished() -> void:
	$WellWater.speed_scale = 1.0
	$WellWater.frame = 0

func can_interact(player: CharacterBody2D) -> bool:
	return not _collecting and not player.carrying_water

func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		return
	_collecting = true
	$WellWater.speed_scale = 2.22
	$WellWater.play_backwards("default")
	await get_tree().create_timer(0.25).timeout
	$WellWater.speed_scale = 1.0
	$WellWater.stop()
	$WellWater.frame = 0
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
	$WellWater.speed_scale = 1.0
	$WellWater.stop()
	$WellWater.frame = 0
	interactable_exited.emit(self)
