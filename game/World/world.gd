extends Node2D

func _ready() -> void:
	$DoorEntrance.body_entered.connect(_on_door_entered)
	$WellArea.body_entered.connect(_on_well_area_entered)
	$WellArea.body_exited.connect(_on_well_area_exited)

func _on_well_area_entered(body: Node2D) -> void:
	if body.name == "Player":
		$WellWater.play_backwards("default")

func _on_well_area_exited(body: Node2D) -> void:
	if body.name == "Player":
		$WellWater.stop()
		$WellWater.frame = 0

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
