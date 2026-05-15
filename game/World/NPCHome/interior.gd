extends Node2D

func _ready() -> void:
	var cam := $Player.get_node("Camera2D") as Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 160
	cam.limit_bottom = 128
	($Player as CharacterBody2D).facing = ($Player as CharacterBody2D).Facing.UP
	TransitionManager.fade_from_black(0.4)
	await get_tree().create_timer(0.5).timeout
	$ExitDoor.body_entered.connect(_on_exit_entered)

func _on_exit_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$ExitDoor.body_entered.disconnect(_on_exit_entered)
	var player := $Player as CharacterBody2D
	if player:
		player.set_physics_process(false)
	await TransitionManager.fade_to_black(0.4)
	Engine.set_meta("spawn_position", Vector2(534, 140))
	get_tree().change_scene_to_file("res://main.tscn")
