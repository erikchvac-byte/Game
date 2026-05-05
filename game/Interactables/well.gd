extends Node2D

signal interactable_entered(node: Node)
signal interactable_exited(node: Node)

var _collecting := false
var _player_in_range := false

func _ready() -> void:
	$WellArea.body_entered.connect(_on_area_entered)
	$WellArea.body_exited.connect(_on_area_exited)
	$WellWater.stop()

func can_interact(player: CharacterBody2D) -> bool:
	return not _collecting and not player.carrying_water

func interact(player: CharacterBody2D) -> void:
	if not can_interact(player):
		return
	_collecting = true
	$WellPrompt.visible = false
	var frame_count: int = $WellWater.sprite_frames.get_frame_count("default")
	var fps: float = $WellWater.sprite_frames.get_animation_speed("default")
	$WellWater.play_backwards("default")
	await get_tree().create_timer(frame_count / fps).timeout
	$WellWater.stop()
	$WellWater.frame = 0
	_collecting = false
	player.carrying_water = true
	var hud = get_node_or_null("/root/HUD")
	if hud:
		hud.set_carrying_water(true)
		hud.show_toast("Water collected!")
	if _player_in_range:
		$WellPrompt.visible = true

func _on_area_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = true
	$WellPrompt.visible = true
	interactable_entered.emit(self)

func _on_area_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_in_range = false
	$WellPrompt.visible = false
	$WellWater.stop()
	$WellWater.frame = 0
	interactable_exited.emit(self)
