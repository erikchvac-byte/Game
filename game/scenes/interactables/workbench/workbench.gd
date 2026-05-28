extends StaticBody2D

const HOE_TEX := preload("res://assets/props/items/hoe.png")

const RECIPE := [
	{"key": "stone_pile", "count": 2},
	{"key": "wood", "count": 2},
]

var _player_in_range := false


func _ready() -> void:
	$ProximityArea.body_entered.connect(_on_body_entered)
	$ProximityArea.body_exited.connect(_on_body_exited)
	$CraftPanel.visible = false
	$PromptLabel.visible = false


func _input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		var opening: bool = not $CraftPanel.visible
		$CraftPanel.visible = opening
		if opening:
			$CraftPanel/Panel/StatusLabel.text = ""
			$CraftPanel/Panel/CraftButton.disabled = false
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = true
	$PromptLabel.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = false
	$PromptLabel.visible = false
	$CraftPanel.visible = false


func _count_item(key: String) -> int:
	var total := 0
	for i in range(1, 48):
		var slot = InventoryManager.get_slot(i)
		if slot != null and slot.key == key:
			total += slot.count
	return total


func attempt_craft() -> void:
	for ingredient in RECIPE:
		if _count_item(ingredient.key) < ingredient.count:
			$CraftPanel/Panel/StatusLabel.text = "Need 2 wood + 2 stone"
			return
	for ingredient in RECIPE:
		for i in ingredient.count:
			InventoryManager.remove_item(ingredient.key)
	InventoryManager.add_item("hoe", HOE_TEX)
	$CraftPanel/Panel/StatusLabel.text = "Crafted: Hoe!"
	$CraftPanel/Panel/CraftButton.disabled = true
