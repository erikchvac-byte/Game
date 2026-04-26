extends AnimatedSprite2D

var _current_anim := ""

func _process(_delta: float) -> void:
	var player := get_parent()

	var tier: String
	if not player.is_moving:
		tier = "idle"
	elif player.is_running:
		tier = "run"
	else:
		tier = "walk"

	var anim: String = tier + "_" + player.facing

	if player.facing == "side":
		flip_h = player.facing_left

	if anim != _current_anim:
		_current_anim = anim
		play(anim)
