extends Node2D

const NPC_TRADE_RADIUS := 36.0
const CLICK_TREE_RADIUS := 22.0
const ARRIVE_DIST := 5.0
const NAV_STUCK_MAX := 1.0

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

var _nav_active := false
var _nav_target_pos := Vector2.ZERO
var _nav_target_node: Node = null
var _nav_pending_interact := false
var _nav_best_dist: float = INF
var _nav_stuck_time: float = 0.0


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


func _process(delta: float) -> void:
	_update_npc_proximity()
	_update_mouse_navigation(delta)


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_on_right_click(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return
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


func _on_right_click(world_pos: Vector2) -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	if not player:
		return
	if _nav_active:
		_cancel_navigation(player)
	var best_tree: Node = null
	var best_dist := CLICK_TREE_RADIUS
	for tree in get_tree().get_nodes_in_group("choppable_trees"):
		if tree.get("_is_chopped") == true:
			continue
		var n2d := tree as Node2D
		if n2d == null:
			continue
		var d := n2d.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best_tree = tree
	if best_tree != null:
		_nav_active = true
		_nav_target_pos = (best_tree as Node2D).global_position
		_nav_target_node = best_tree
		_nav_pending_interact = true
	else:
		_nav_active = true
		_nav_target_pos = world_pos
		_nav_target_node = null
		_nav_pending_interact = false


func _update_mouse_navigation(delta: float) -> void:
	if not _nav_active:
		return
	var player := get_node_or_null("Player") as CharacterBody2D
	if not player:
		return
	var kb_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if kb_dir.length_squared() > 0.0:
		_cancel_navigation(player)
		return
	if _nav_target_node != null and not is_instance_valid(_nav_target_node):
		_cancel_navigation(player)
		return
	if _nav_target_node != null and _interactables.has(_nav_target_node):
		var pending := _nav_pending_interact
		var target := _nav_target_node
		_cancel_navigation(player)
		if pending:
			_do_nav_interact(player, target)
		return
	var dist := player.global_position.distance_to(_nav_target_pos)
	if dist < ARRIVE_DIST:
		_cancel_navigation(player)
		return
	if dist < _nav_best_dist - 0.5:
		_nav_best_dist = dist
		_nav_stuck_time = 0.0
	else:
		_nav_stuck_time += delta
		if _nav_stuck_time >= NAV_STUCK_MAX:
			_cancel_navigation(player)
			return
	player.auto_walk = (_nav_target_pos - player.global_position).normalized()


func _cancel_navigation(player: CharacterBody2D) -> void:
	_nav_active = false
	_nav_target_node = null
	_nav_pending_interact = false
	_nav_best_dist = INF
	_nav_stuck_time = 0.0
	player.auto_walk = Vector2.ZERO


func _do_nav_interact(player: CharacterBody2D, target: Node) -> void:
	if not target.has_method("interact"):
		return
	if target.has_method("can_interact") and not target.can_interact(player):
		return
	target.interact(player)


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
