extends Node2D

const NPC_TRADE_RADIUS := 36.0

# Maps item key → InputMap action name. Add a row to register a new equippable tool;
# no other code changes required.
const EQUIPPABLE_TOOLS := {
	"axe": "equip_toggle",
}

# Hotbar slot count must match InventoryManager.HOTBAR_SLOTS.
# Only hotbar slots map to HUD display, so the search is capped here.
const _HOTBAR_SLOTS := 12

var _interactables: Array[Node] = []
var _npc_trade_active := false
var _inv_mgr: Node


func _ready() -> void:
	_inv_mgr = get_node_or_null("/root/InventoryManager")
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.slot_selected.connect(_on_hud_slot_selected)
	$DoorEntrance.body_entered.connect(_on_door_entered)
	get_tree().create_timer(0.5).timeout.connect(func(): $NPCHomeDoor.body_entered.connect(_on_npc_door_entered))
	$Well.connect("interactable_entered", _on_interactable_entered)
	$Well.connect("interactable_exited", _on_interactable_exited)
	$Plant.connect("interactable_entered", _on_interactable_entered)
	$Plant.connect("interactable_exited", _on_interactable_exited)
	$Plant.plant_harvested.connect($DryingRack.add_plant)
	for tree in get_tree().get_nodes_in_group("choppable_trees"):
		tree.connect("interactable_entered", _on_interactable_entered)
		tree.connect("interactable_exited", _on_interactable_exited)
		tree.connect("wood_chopped", _on_wood_chopped)
	_grant_starting_items()


func _on_wood_chopped() -> void:
	if _inv_mgr:
		_inv_mgr.add_item("wood", preload("res://GameAssets/Caves/Rocks/rock3.png"))


func _grant_starting_items() -> void:
	if Engine.has_meta("starting_items_granted"):
		return
	if not _inv_mgr:
		return
	_inv_mgr.add_item("axe", preload("res://GameAssets/Tools/tool_axe.png"))
	_inv_mgr.add_item("bud", preload("res://GameAssets/Bud/dry_bud.png"))
	_inv_mgr.add_item("wood", preload("res://GameAssets/Caves/Rocks/rock3.png"))
	Engine.set_meta("starting_items_granted", true)


func _process(_delta: float) -> void:
	_update_npc_proximity()


func _update_npc_proximity() -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	var npc := get_node_or_null("GreyHoodie")
	if not player or not npc:
		return
	var dist: float = player.global_position.distance_to(npc.global_position)
	var in_range: bool = dist <= NPC_TRADE_RADIUS
	var can_trade: bool = in_range and npc.is_interactable()

	npc.call("set_player_nearby", in_range)
	if in_range:
		npc.call("face_toward", player.global_position)

	if can_trade == _npc_trade_active:
		return
	_npc_trade_active = can_trade
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_trade_prompt(_npc_trade_active)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("npc_trade") and _npc_trade_active:
		_handle_npc_trade()
		return
	for tool_key: String in EQUIPPABLE_TOOLS:
		if event.is_action_pressed(EQUIPPABLE_TOOLS[tool_key]):
			_handle_tool_toggle(tool_key)
			return
	if event.is_action_pressed("interact"):
		var target := _get_nearest_interactable()
		if target and target.has_method("interact"):
			var player := $Player as CharacterBody2D
			if target.has_method("can_interact") and not target.can_interact(player):
				var hud := get_node_or_null("/root/HUD")
				if hud:
					hud.show_toast("Equip axe first (C)", 1.5)
			else:
				target.interact(player)


func _on_hud_slot_selected(index: int) -> void:
	if not _inv_mgr:
		return
	var player := get_node_or_null("Player") as CharacterBody2D
	if not player:
		return
	var item = _inv_mgr.get_slot(index)
	var new_tool := ""
	if item != null and (item.key in EQUIPPABLE_TOOLS):
		new_tool = item.key
	if player.equipped_tool == new_tool:
		return
	player.equipped_tool = new_tool
	var hud := get_node_or_null("/root/HUD")
	if not hud:
		return
	if new_tool == "":
		hud.set_equipped_slot(-1)
	else:
		for i in range(1, _HOTBAR_SLOTS):
			var s = _inv_mgr.get_slot(i)
			if s != null and s.key == new_tool:
				hud.set_equipped_slot(i)
				break


func _handle_tool_toggle(tool_key: String) -> void:
	if not _inv_mgr or not _inv_mgr.has_item(tool_key):
		return
	var player := get_node_or_null("Player") as CharacterBody2D
	if not player:
		return
	player.equipped_tool = "" if player.equipped_tool == tool_key else tool_key
	var hud := get_node_or_null("/root/HUD")
	if hud:
		var slot_idx := -1
		if player.equipped_tool != "":
			for i in range(1, _HOTBAR_SLOTS):
				var item = _inv_mgr.get_slot(i)
				if item != null and item.key == player.equipped_tool:
					slot_idx = i
					break
		hud.set_equipped_slot(slot_idx)


func _handle_npc_trade() -> void:
	var success: bool = $GreyHoodie.attempt_trade()
	var hud := get_node_or_null("/root/HUD")
	if hud:
		if success:
			hud.show_toast("Traded: +1 Gem", 2.5)
		else:
			hud.show_toast("No product available", 2.0)


func _get_nearest_interactable() -> Node:
	if _interactables.is_empty():
		return null
	if _interactables.size() == 1:
		return _interactables[0]
	var player := $Player as Node2D
	var best: Node = null
	var best_dist := INF
	for node in _interactables:
		var n2d := node as Node2D
		if n2d == null:
			continue
		var d: float = player.global_position.distance_squared_to(n2d.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best


func _on_interactable_entered(node: Node) -> void:
	if not _interactables.has(node):
		_interactables.append(node)
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_interact_prompt(true)


func _on_interactable_exited(node: Node) -> void:
	_interactables.erase(node)
	var hud := get_node_or_null("/root/HUD")
	if hud:
		hud.show_interact_prompt(_interactables.size() > 0)


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
