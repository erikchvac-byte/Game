extends Node2D

func _ready() -> void:
	if Engine.has_meta("spawn_position"):
		$Player.position = Engine.get_meta("spawn_position")
		Engine.remove_meta("spawn_position")
