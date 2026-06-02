extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)
signal plant_harvested

@export var plant_stages: Array[int] = [0, 5, 10, 16]

var _stage := 0
var _growing := false

func _ready() -> void:
	add_to_group("garden_plants")
	$PlantArea.body_entered.connect(_on_area_entered)
	$PlantArea.body_exited.connect(_on_area_exited)
	$PurplePlant.stop()
	$PurplePlant.frame = plant_stages[0]

func blocked_message(player: CharacterBody2D) -> String:
	if not player.carrying_water and not _growing:
		return "Need water first"
	return ""

func can_interact(player: CharacterBody2D) -> bool:
	return player.carrying_water and not _growing and _stage < plant_stages.size() - 1

func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		return
	player.carrying_water = false
	var hud = get_node_or_null("/root/HUD")
	if hud:
		hud.set_carrying_water(false)
	_growing = true
	var prev_stage := _stage
	_stage += 1
	var start_frame: int = plant_stages[prev_stage]
	var end_frame: int = plant_stages[_stage]
	var fps: float = $PurplePlant.sprite_frames.get_animation_speed($PurplePlant.animation)
	if fps <= 0.0:
		fps = 8.0
	$PurplePlant.stop()
	$PurplePlant.frame = start_frame
	for f in range(start_frame + 1, end_frame + 1):
		await get_tree().create_timer(1.0 / fps).timeout
		$PurplePlant.frame = f
	_growing = false
	if _stage >= plant_stages.size() - 1:
		plant_harvested.emit()
		_stage = 0
		$PurplePlant.stop()
		$PurplePlant.frame = plant_stages[0]

func _on_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if _stage < plant_stages.size() - 1:
		interactable_entered.emit(self)

func _on_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactable_exited.emit(self)
