extends Node2D

func _ready() -> void:
	var cam := $Player.get_node("Camera2D") as Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 160
	cam.limit_bottom = 128
	await get_tree().create_timer(0.4).timeout
	$ExitDoor.body_entered.connect(_on_exit_entered)

func _on_exit_entered(body: Node2D) -> void:
	if body.name == "Player":
		Engine.set_meta("spawn_position", Vector2(112, 168))
		get_tree().change_scene_to_file("res://main.tscn")
