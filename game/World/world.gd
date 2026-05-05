extends Node2D

const PLANT_STAGES := [0, 5, 10, 16]

var _near_well := false
var _near_plant := false
var _plant_stage := 0
var _growing := false
var _collecting := false

func _ready() -> void:
	$DoorEntrance.body_entered.connect(_on_door_entered)
	$WellArea.body_entered.connect(_on_well_area_entered)
	$WellArea.body_exited.connect(_on_well_area_exited)
	$PlantArea.body_entered.connect(_on_plant_area_entered)
	$PlantArea.body_exited.connect(_on_plant_area_exited)
	$PurplePlant.stop()
	$PurplePlant.frame = PLANT_STAGES[0]

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _near_well:
		_collect_water()
	elif _near_plant:
		_water_plant()

func _collect_water() -> void:
	if _collecting or ($Player as CharacterBody2D).carrying_water:
		return
	_collecting = true
	$WellPrompt.visible = false
	var frame_count: int = $WellWater.sprite_frames.get_frame_count("default")
	var fps: float = $WellWater.sprite_frames.get_animation_speed("default")
	$WellWater.play_backwards("default")
	await get_tree().create_timer(frame_count / fps).timeout
	$WellWater.stop()
	$WellWater.frame = 0
	_collecting = false
	($Player as CharacterBody2D).carrying_water = true
	$HUDLayer/BucketIcon.texture = load("res://GameAssets/UI/bucket_full.png")
	if _near_well:
		$WellPrompt.visible = true

func _water_plant() -> void:
	if _growing:
		return
	var player := $Player as CharacterBody2D
	if not player.carrying_water:
		return
	if _plant_stage >= PLANT_STAGES.size() - 1:
		return
	player.carrying_water = false
	$HUDLayer/BucketIcon.texture = load("res://GameAssets/UI/bucket_empty.png")
	_growing = true
	var prev_stage := _plant_stage
	_plant_stage += 1
	var start_frame: int = PLANT_STAGES[prev_stage]
	var end_frame: int = PLANT_STAGES[_plant_stage]
	var fps: float = $PurplePlant.sprite_frames.get_animation_speed("default")
	$PurplePlant.stop()
	$PurplePlant.frame = start_frame
	for f in range(start_frame + 1, end_frame + 1):
		await get_tree().create_timer(1.0 / fps).timeout
		$PurplePlant.frame = f
	_growing = false
	if _plant_stage >= PLANT_STAGES.size() - 1:
		$PlantPrompt.visible = false

func _on_well_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near_well = true
	$WellPrompt.visible = true

func _on_well_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near_well = false
	$WellPrompt.visible = false
	$WellWater.stop()
	$WellWater.frame = 0

func _on_plant_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near_plant = true
	if _plant_stage < PLANT_STAGES.size() - 1:
		$PlantPrompt.visible = true

func _on_plant_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near_plant = false
	$PlantPrompt.visible = false

func _on_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$DoorEntrance.body_entered.disconnect(_on_door_entered)
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.set_physics_process(false)
	var door := $PlayerHomeDoor as AnimatedSprite2D
	door.play("open")
	await door.animation_finished
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/PlayerHome/interior.tscn")
