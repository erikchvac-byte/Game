extends AnimatedSprite2D

var _current_anim := ""

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	var player := get_parent()
	player.is_chopping = false
	player.is_trading = false
	_current_anim = ""

func _process(_delta: float) -> void:
	var player := get_parent()

	var dir: String = player.facing_name()
	var anim: String

	if player.is_chopping:
		anim = "chop_" + dir
	elif player.is_trading:
		anim = "trade_" + dir
	else:
		var suffix := "_bucket" if player.carrying_water else ""
		if player.is_moving:
			anim = "walk_" + dir + suffix
		else:
			anim = "idle_" + dir + suffix

	flip_h = (player.facing == player.Facing.SIDE and player.facing_left)

	if anim != _current_anim:
		_current_anim = anim
		if sprite_frames and sprite_frames.has_animation(anim):
			play(anim)
		elif "_bucket" in anim:
			var base := anim.replace("_bucket", "")
			if sprite_frames and sprite_frames.has_animation(base):
				play(base)
