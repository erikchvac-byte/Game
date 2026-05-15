extends AnimatedSprite2D

var _current_anim := ""

func _process(_delta: float) -> void:
	var player := get_parent()

	var dir: String = player.facing_name()
	var suffix := "_bucket" if player.carrying_water else ""
	var anim: String
	if player.is_moving:
		anim = "walk_" + dir + suffix
	else:
		anim = "idle_" + dir + suffix

	flip_h = (player.facing == player.Facing.SIDE and player.facing_left)

	if anim != _current_anim:
		_current_anim = anim
		play(anim)
