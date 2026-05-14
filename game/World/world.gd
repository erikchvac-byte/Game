extends Node2D

var _interactable: Node = null
var _npc_trade_active := false


func _ready() -> void:
	$DoorEntrance.body_entered.connect(_on_door_entered)
	# Small delay prevents immediate re-entry when player spawns near the door
	get_tree().create_timer(0.5).timeout.connect(func(): $NPCHomeDoor.body_entered.connect(_on_npc_door_entered))
	$Well.connect("interactable_entered", _on_interactable_entered)
	$Well.connect("interactable_exited", _on_interactable_exited)
	$Plant.connect("interactable_entered", _on_interactable_entered)
	$Plant.connect("interactable_exited", _on_interactable_exited)
	$Plant.plant_harvested.connect($DryingRack.add_plant)
	$GreyHoodie.arrived_for_trade.connect(_on_npc_arrived_for_trade)
	$GreyHoodie.departed_from_trade.connect(_on_npc_departed_from_trade)
	_grant_starting_bud()


func _grant_starting_bud() -> void:
	var inv := get_node_or_null("/root/Inventory")
	if inv:
		inv.add_item("bud", preload("res://GameAssets/Bud/dry_bud.png"))


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_T and _npc_trade_active:
		_handle_npc_trade()
		return
	if event.is_action_pressed("interact"):
		if _interactable and _interactable.has_method("interact"):
			_interactable.interact($Player as CharacterBody2D)


func _handle_npc_trade() -> void:
	var success: bool = $GreyHoodie.attempt_trade()
	var hud := get_node_or_null("/root/HUD")
	if hud:
		if success:
			hud.show_toast("Traded: +1 Gem", 2.5)
		else:
			hud.show_toast("No product available", 2.0)


func _on_npc_arrived_for_trade() -> void:
	_npc_trade_active = true
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_trade_prompt(true)


func _on_npc_departed_from_trade() -> void:
	_npc_trade_active = false
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_trade_prompt(false)

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

func _on_npc_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$NPCHomeDoor.body_entered.disconnect(_on_npc_door_entered)
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.auto_walk = Vector2(0, -1)
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/NPCHome/interior.tscn")

func _on_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$DoorEntrance.body_entered.disconnect(_on_door_entered)
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.auto_walk = Vector2(0, -1)
	var bakery := $PlayerHome as AnimatedSprite2D
	bakery.play("open")
	while bakery.frame < 4:
		await bakery.frame_changed
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/PlayerHome/interior.tscn")
