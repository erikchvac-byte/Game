extends Node2D

func _ready() -> void:
	$DoorEntrance.body_entered.connect(_on_door_entered)

func _on_door_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file("res://World/PlayerHome/interior.tscn")
