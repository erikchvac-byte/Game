extends Node2D

const NPC_TRADE_RADIUS := 36.0
const ARRIVE_DIST := 5.0
const NAV_STUCK_MAX := 1.0

# Maps item key → InputMap action name. Add a row to register a new equippable tool;
# no other code changes required.
const EQUIPPABLE_TOOLS := {
	"axe": "equip_toggle",
	"pickaxe": "equip_pickaxe",
}

# Hotbar slot count must match InventoryManager.HOTBAR_SLOTS.
const _HOTBAR_SLOTS := 7

var _interactables: Array[Node] = []
var _npc_trade_active := false
var _inv_mgr: Node
var _hud: Node
var _player: CharacterBody2D
var _npc: Node

var _nav_active := false
var _nav_target_pos := Vector2.ZERO
var _nav_target_node: Node = null
var _nav_pending_interact := false
var _nav_best_dist: float = INF
var _nav_stuck_time: float = 0.0


func _ready() -> void:
	_inv_mgr = get_node_or_null("/root/InventoryManager")
	_hud = get_node_or_null("/root/HUD")
	_player = get_node_or_null("Player") as CharacterBody2D
	_npc = get_node_or_null("GreyHoodie")
	if _hud:
		_hud.slot_selected.connect(_on_hud_slot_selected)
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
		tree.connect("tree_chopped", _on_tree_chopped)
	for rock in get_tree().get_nodes_in_group("choppable_rocks"):
		rock.connect("interactable_entered", _on_interactable_entered)
		rock.connect("interactable_exited", _on_interactable_exited)
	_grant_starting_items()


func _grant_starting_items() -> void:
	if not _inv_mgr:
		return
	# Skip if inventory already populated (returning from interior, or already granted)
	for i in range(1, _HOTBAR_SLOTS):
		if _inv_mgr.get_slot(i) != null:
			return
	_inv_mgr.add_item("axe", preload("res://assets/props/items/tool_axe.png"))
	_inv_mgr.add_item("pickaxe", preload("res://assets/props/items/tool_pickaxe.png"))
	_inv_mgr.add_item("stone_pile", preload("res://assets/props/items/stone_pile.png"))
	_inv_mgr.add_item("bud", preload("res://assets/props/bud/dry_bud.png"))
	_inv_mgr.add_item("wood", preload("res://assets/props/items/wood_pile.png"))
	_inv_mgr.add_item("seed_packets", preload("res://assets/props/items/seed_packets.png"))


func _process(delta: float) -> void:
	_update_npc_proximity()
	_update_mouse_navigation(delta)


func _update_npc_proximity() -> void:
	if not _player or not _npc:
		return
	var dist: float = _player.global_position.distance_to(_npc.global_position)
	var in_range: bool = dist <= NPC_TRADE_RADIUS
	var can_trade: bool = in_range and _npc.is_interactable()

	_npc.call("set_player_nearby", in_range)
	if in_range:
		_npc.call("face_toward", _player.global_position)
		if not _player.is_moving and not _player.is_chopping and not _player.is_trading:
			_face_player_toward(_npc as Node2D)

	if can_trade == _npc_trade_active:
		return
	_npc_trade_active = can_trade


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_right_click(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("npc_trade") and _npc_trade_active and _npc != null and _npc.is_interactable():
		_handle_npc_trade()
		return
	for tool_key: String in EQUIPPABLE_TOOLS:
		if event.is_action_pressed(EQUIPPABLE_TOOLS[tool_key]):
			_handle_tool_toggle(tool_key)
			return
	if event.is_action_pressed("drop_item"):
		_handle_drop_item()
		return
	if event.is_action_pressed("interact"):
		if _npc_trade_active and _npc != null and _npc.is_interactable():
			_handle_npc_trade()
			return
		var target := _get_nearest_interactable()
		if target and target.has_method("interact"):
			if target.has_method("can_interact") and not target.can_interact(_player):
				var msg := "Equip axe first (C)"
				if target.has_method("blocked_message"):
					msg = target.blocked_message(_player)
				if msg != "" and _hud:
					_hud.show_toast(msg, 1.5)
			else:
				target.interact(_player)


func _on_hud_slot_selected(index: int) -> void:
	if not _inv_mgr or not _player:
		return
	var item = _inv_mgr.get_slot(index)
	var new_tool := ""
	if item != null and (item.key in EQUIPPABLE_TOOLS):
		new_tool = item.key
	if _player.equipped_tool != new_tool:
		_player.equipped_tool = new_tool
	if _hud:
		_hud.set_equipped_slot(index)


func _handle_tool_toggle(tool_key: String) -> void:
	if not _inv_mgr or not _inv_mgr.has_item(tool_key) or not _player:
		return
	_player.equipped_tool = "" if _player.equipped_tool == tool_key else tool_key
	if _hud:
		var slot_idx := -1 if _player.equipped_tool == "" else _find_equipped_slot(_player.equipped_tool)
		_hud.set_equipped_slot(slot_idx)


func _find_equipped_slot(tool_key: String) -> int:
	for i in range(1, _HOTBAR_SLOTS):
		var item = _inv_mgr.get_slot(i)
		if item != null and item.key == tool_key:
			return i
	return -1


func _handle_npc_trade() -> void:
	var success: bool = _npc.attempt_trade()
	if success and _player:
		_player.is_trading = true
	if _hud:
		_hud.show_toast("Traded: +1 Gem" if success else "No product available", 2.5 if success else 2.0)


func _handle_drop_item() -> void:
	if not _inv_mgr or not _player:
		return
	var selected_slot: int = _hud.selected_slot if _hud else -1
	if selected_slot < 0:
		return
	var item = _inv_mgr.get_slot(selected_slot)
	if item == null:
		return
	# Don't allow dropping tools
	if item.key in EQUIPPABLE_TOOLS:
		if _hud:
			_hud.show_toast("Can't drop equipped tools", 1.5)
		return
	_inv_mgr.remove_item(item.key)
	var drop_scene := preload("res://World/WorldDropItem/world_drop_item.tscn")
	var drop := drop_scene.instantiate() as Node2D
	drop.set_meta("item_key", item.key)
	drop.set_meta("item_tex", item.tex)
	drop.position = _player.position + Vector2(0, 8)
	add_child(drop)


func _get_nearest_interactable() -> Node:
	if _interactables.is_empty():
		return null
	if _interactables.size() == 1:
		return _interactables[0]
	var best: Node = null
	var best_dist := INF
	for node in _interactables:
		var n2d := node as Node2D
		if n2d == null:
			continue
		var d: float = _player.global_position.distance_squared_to(n2d.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	return best


func _on_right_click(world_pos: Vector2) -> void:
	if not _player:
		return
	if _nav_active:
		_cancel_navigation()
	# NPC — highest priority
	if _npc != null and (_npc as Node2D).visible:
		var d := (_npc as Node2D).global_position.distance_to(world_pos)
		if d < NPC_TRADE_RADIUS:
			_nav_active = true
			_nav_target_pos = (_npc as Node2D).global_position
			_nav_target_node = _npc
			_nav_pending_interact = true
			_player.nav_agent.set_target_position(_nav_target_pos)
			return
	# Rocks
	for rock in get_tree().get_nodes_in_group("choppable_rocks"):
		var rock_node := rock as Node2D
		if rock_node == null:
			continue
		if rock_node.global_position.distance_to(world_pos) < 28.0:
			_nav_active = true
			_nav_target_pos = rock_node.global_position
			_nav_target_node = rock
			_nav_pending_interact = true
			_player.nav_agent.set_target_position(_nav_target_pos)
			return
	# Trees — click anywhere on sprite navigates and interacts
	for tree in get_tree().get_nodes_in_group("choppable_trees"):
		var tree_node := tree as Node2D
		if tree_node == null:
			continue
		if tree_node.global_position.distance_to(world_pos) < 35.0:
			_nav_active = true
			_nav_target_pos = tree_node.global_position
			_nav_target_node = tree
			_nav_pending_interact = true
			_player.nav_agent.set_target_position(_nav_target_pos)
			return
	_nav_active = true
	_nav_target_pos = world_pos
	_nav_target_node = null
	_nav_pending_interact = false
	_player.nav_agent.set_target_position(world_pos)


func _update_mouse_navigation(delta: float) -> void:
	if not _nav_active or not _player:
		return
	if _nav_target_node != null and not is_instance_valid(_nav_target_node):
		_cancel_navigation()
		return
	# NPC arrival: track NPC position and trigger trade when in range
	if _nav_target_node == _npc and _npc != null:
		_nav_target_pos = (_npc as Node2D).global_position
		_player.nav_agent.set_target_position(_nav_target_pos)
		if _player.global_position.distance_to(_nav_target_pos) <= NPC_TRADE_RADIUS:
			_cancel_navigation()
			return
	if _nav_target_node != null and _interactables.has(_nav_target_node):
		var pending := _nav_pending_interact
		var target := _nav_target_node
		_cancel_navigation()
		if pending:
			_do_nav_interact(_player, target)
		return
	var dist := _player.global_position.distance_to(_nav_target_pos)
	if _player.nav_agent.is_navigation_finished() or dist < ARRIVE_DIST:
		_cancel_navigation()
		return
	if dist < _nav_best_dist - 0.5:
		_nav_best_dist = dist
		_nav_stuck_time = 0.0
	else:
		_nav_stuck_time += delta
		if _nav_stuck_time >= NAV_STUCK_MAX:
			_cancel_navigation()
			return


func _cancel_navigation() -> void:
	_nav_active = false
	_nav_target_node = null
	_nav_pending_interact = false
	_nav_best_dist = INF
	_nav_stuck_time = 0.0
	if _player:
		_player.auto_walk = Vector2.ZERO
		_player.nav_agent.set_target_position(_player.global_position)


func _do_nav_interact(player: CharacterBody2D, target: Node) -> void:
	if not target.has_method("interact"):
		return
	if target.has_method("can_interact") and not target.can_interact(player):
		return
	target.interact(player)


func _face_player_toward(target: Node2D) -> void:
	if not _player or not target:
		return
	var diff := target.global_position - _player.global_position
	if abs(diff.x) >= abs(diff.y):
		_player.facing = _player.Facing.SIDE
		_player.facing_left = diff.x < 0.0
	else:
		_player.facing = _player.Facing.DOWN if diff.y > 0.0 else _player.Facing.UP


func _on_interactable_entered(node: Node) -> void:
	if not _interactables.has(node):
		_interactables.append(node)


func _on_interactable_exited(node: Node) -> void:
	_interactables.erase(node)


func _on_npc_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$NPCHomeDoor.body_entered.disconnect(_on_npc_door_entered)
	if _player:
		_player.auto_walk = Vector2(0, -1)
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/NPCHome/interior.tscn")


func _on_door_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	$DoorEntrance.body_entered.disconnect(_on_door_entered)
	if _player:
		_player.auto_walk = Vector2(0, -1)
	var bakery := $PlayerHome as AnimatedSprite2D
	bakery.play("open")
	while bakery.frame < 4:
		await bakery.frame_changed
	await TransitionManager.fade_to_black(0.4)
	get_tree().change_scene_to_file("res://World/PlayerHome/interior.tscn")


func _on_tree_chopped() -> void:
	if _inv_mgr:
		_inv_mgr.add_item("wood", preload("res://assets/props/items/wood_pile.png"))
