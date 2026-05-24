extends Node2D

const DESPAWN_MIN := 30.0
const DESPAWN_MAX := 90.0

var item_key: String = ""
var item_tex: Texture2D = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _timer: Timer = $DespawnTimer
@onready var _area: Area2D = $Area2D


func _ready() -> void:
	add_to_group("world_drop_items")
	item_key = get_meta("item_key", "")
	item_tex = get_meta("item_tex", null)
	if item_tex and _sprite:
		_sprite.texture = item_tex
	var override: float = get_meta("despawn_time", -1.0)
	_timer.wait_time = override if override > 0.0 else randf_range(DESPAWN_MIN, DESPAWN_MAX)
	_timer.start()
	_timer.timeout.connect(queue_free)


func consume() -> Dictionary:
	var result := {"key": item_key, "tex": item_tex}
	queue_free()
	return result
