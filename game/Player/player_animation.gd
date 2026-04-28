extends AnimatedSprite2D

var _current_anim := ""

func _process(_delta: float) -> void:
	var player := get_parent()

	var dir: String = player.facing
	var anim: String
	if player.is_moving:
		anim = "walk_" + dir
	else:
		anim = "idle_" + dir

	flip_h = (dir == "side" and player.facing_left)

	if anim != _current_anim:
		_current_anim = anim
		play(anim)
