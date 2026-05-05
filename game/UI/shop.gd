extends CanvasLayer

var is_open: bool = false


func _ready() -> void:
	layer = 20
	visible = false
	_build_overlay()


func _build_overlay() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 10.0
	layout.offset_right = -10.0
	layout.offset_top = 10.0
	layout.offset_bottom = -10.0
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.09, 0.09, 0.11, 0.96)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.38, 0.38, 0.48)

	# Left panel: player inventory
	var left := Panel.new()
	left.name = "PlayerInventory"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_stylebox_override("panel", ps)
	layout.add_child(left)
	_add_panel_title(left, "Your Items")

	# Right panel: shop stock
	var right := Panel.new()
	right.name = "ShopStock"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", ps.duplicate())
	layout.add_child(right)
	_add_panel_title(right, "Shop")


func _add_panel_title(panel: Panel, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_bottom = 14.0
	panel.add_child(lbl)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	is_open = true
	visible = true


func close() -> void:
	is_open = false
	visible = false
