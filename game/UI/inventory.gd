extends CanvasLayer

const TOTAL_SLOTS := 36
const COLS := 6

var is_open: bool = false

var _slot_panels: Array = []
var _slot_icons: Array = []
var _slot_badges: Array = []
var _overlay: Control
var _inv_mgr: Node


func _ready() -> void:
	layer = 20
	visible = false
	_build_overlay()
	_inv_mgr = get_node("/root/InventoryManager")
	_inv_mgr.slot_changed.connect(_on_slot_changed)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "InventoryOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)

	# Center panel
	var panel_w := 192.0
	var panel_h := 148.0
	var panel := Panel.new()
	panel.name = "InventoryPanel"
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.09, 0.09, 0.11, 0.96)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 1
	ps.border_color = Color(0.38, 0.38, 0.48)
	panel.add_theme_stylebox_override("panel", ps)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_w * 0.5
	panel.offset_top = -panel_h * 0.5
	panel.offset_right = panel_w * 0.5
	panel.offset_bottom = panel_h * 0.5
	_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 4.0
	vbox.offset_right = -4.0
	vbox.offset_top = 4.0
	vbox.offset_bottom = -4.0
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", Color(0.90, 0.90, 0.92))
	title.custom_minimum_size = Vector2(0.0, 13.0)
	vbox.add_child(title)

	# Divider
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.color = Color(0.35, 0.35, 0.45, 0.8)
	vbox.add_child(div)

	# Grid
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)

	var slot_style_normal := StyleBoxFlat.new()
	slot_style_normal.bg_color = Color(0.15, 0.15, 0.17, 0.90)
	slot_style_normal.border_width_left = 1
	slot_style_normal.border_width_right = 1
	slot_style_normal.border_width_top = 1
	slot_style_normal.border_width_bottom = 1
	slot_style_normal.border_color = Color(0.28, 0.28, 0.33)

	_slot_panels = []
	_slot_icons = []
	_slot_badges = []
	for i in range(TOTAL_SLOTS):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(26.0, 26.0)
		slot.add_theme_stylebox_override("panel", slot_style_normal)
		grid.add_child(slot)

		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

		var badge := Label.new()
		badge.add_theme_font_size_override("font_size", 6)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		slot.add_child(badge)

		_slot_panels.append(slot)
		_slot_icons.append(icon)
		_slot_badges.append(badge)

	# Hint
	var hint := Label.new()
	hint.text = "[Tab / I / Esc] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	hint.custom_minimum_size = Vector2(0.0, 11.0)
	vbox.add_child(hint)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if not is_open:
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			open()
			get_viewport().set_input_as_handled()
	else:
		if event.keycode in [KEY_TAB, KEY_I, KEY_ESCAPE]:
			close()
			get_viewport().set_input_as_handled()


# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	is_open = true
	visible = true


func close() -> void:
	is_open = false
	visible = false


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func set_item(slot: int, tex: Texture2D) -> void:
	if slot < 0 or slot >= _slot_icons.size():
		return
	(_slot_icons[slot] as TextureRect).texture = tex


func has_item(key: String) -> bool:
	return _inv_mgr.has_item(key)


func remove_item(key: String) -> bool:
	return _inv_mgr.remove_item(key)


func add_item(key: String, tex: Texture2D) -> bool:
	return _inv_mgr.add_item(key, tex)


func _on_slot_changed(index: int, item: Variant) -> void:
	var grid_index: int = index - 12  # InventoryManager.HOTBAR_SLOTS
	if grid_index < 0 or grid_index >= TOTAL_SLOTS:
		return
	set_item(grid_index, null if item == null else item.tex)
	_set_badge(grid_index, 0 if item == null else item.count)


func _set_badge(slot: int, count: int) -> void:
	if slot < 0 or slot >= _slot_badges.size():
		return
	var badge := _slot_badges[slot] as Label
	if count > 1:
		badge.text = str(count)
		badge.visible = true
	else:
		badge.visible = false
