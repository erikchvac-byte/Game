extends Node2D

func _ready() -> void:
	if Engine.has_meta("spawn_position"):
		$World/Player.position = Engine.get_meta("spawn_position")
		Engine.remove_meta("spawn_position")
		TransitionManager.fade_from_black(0.4)
	else:
		TransitionManager.fade_from_black(0.0)
