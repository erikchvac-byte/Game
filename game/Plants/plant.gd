extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)
signal plant_harvested

const PLANT_STAGES := [0, 5, 10, 16]

var _stage := 0
var _growing := false

func _ready() -> void:
	$PlantArea.body_entered.connect(_on_area_entered)
	$PlantArea.body_exited.connect(_on_area_exited)
	$PurplePlant.stop()
	$PurplePlant.frame = PLANT_STAGES[0]

func can_interact(player: CharacterBody2D) -> bool:
	return player.carrying_water and not _growing and _stage < PLANT_STAGES.size() - 1

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
	var start_frame: int = PLANT_STAGES[prev_stage]
	var end_frame: int = PLANT_STAGES[_stage]
	var fps: float = $PurplePlant.sprite_frames.get_animation_speed("default")
	$PurplePlant.stop()
	$PurplePlant.frame = start_frame
	for f in range(start_frame + 1, end_frame + 1):
		await get_tree().create_timer(1.0 / fps).timeout
		$PurplePlant.frame = f
	_growing = false
	if _stage >= PLANT_STAGES.size() - 1:
		if hud:
			hud.show_interact_prompt(false)
		plant_harvested.emit()
		_stage = 0
		$PurplePlant.stop()
		$PurplePlant.frame = PLANT_STAGES[0]

func _on_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if _stage < PLANT_STAGES.size() - 1:
		interactable_entered.emit(self)

func _on_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactable_exited.emit(self)
