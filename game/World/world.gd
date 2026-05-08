extends Node2D

var _interactable: Node = null

func _ready() -> void:
	$DoorEntrance.body_entered.connect(_on_door_entered)
	$Well.connect("interactable_entered", _on_interactable_entered)
	$Well.connect("interactable_exited", _on_interactable_exited)
	$Plant.connect("interactable_entered", _on_interactable_entered)
	$Plant.connect("interactable_exited", _on_interactable_exited)
	$Plant.plant_harvested.connect($DryingRack.add_plant)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _interactable and _interactable.has_method("interact"):
		_interactable.interact($Player as CharacterBody2D)

func _on_interactable_entered(node: Node) -> void:
	_interactable = node
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_interact_prompt(true)

func _on_interactable_exited(node: Node) -> void:
	if _interactable == node:
		_interactable = null
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_interact_prompt(false)

func _on_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$DoorEntrance.body_entered.disconnect(_on_door_entered)
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.set_physics_process(false)
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/PlayerHome/interior.tscn")
