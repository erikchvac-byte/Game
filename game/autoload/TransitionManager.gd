extends Node

var _canvas: CanvasLayer
var _rect: ColorRect

func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	add_child(_canvas)
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(_rect)

func fade_to_black(duration: float = 0.4) -> void:
	_rect.color = Color(0, 0, 0, 0)
	var tween := create_tween()
	tween.tween_property(_rect, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

func fade_from_black(duration: float = 0.4) -> void:
	_rect.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(_rect, "color", Color(0, 0, 0, 0), duration)
	await tween.finished
