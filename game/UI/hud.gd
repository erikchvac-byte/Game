extends CanvasLayer

const SLOT_COUNT := 12
const TOP_BAR_H := 12.0
const HOTBAR_H := 16.0

var water: int = 0
var water_max: int = 10
var energy: int = 10
var energy_max: int = 10
var currency: int = 0
var selected_slot: int = 0

var _water_fill: ColorRect
var _energy_fill: ColorRect
var _currency_label: Label
var _slots: Array = []
var _toast_panel: Panel
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_hotbar()
	_build_toast()


# ── Top bar ───────────────────────────────────────────────────────────────────

func _build_top_bar() -> void:
	var bar := Panel.new()
	bar.name = "TopBar"
	bar.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.07, 0.09, 0.90)))
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_BAR_H
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 3.0
	hbox.offset_right = -3.0
	hbox.add_theme_constant_override("separation", 4)
	bar.add_child(hbox)

	# Water (left)
	var w_sec := _hbox(Control.SIZE_EXPAND_FILL, BoxContainer.ALIGNMENT_BEGIN, 2)
	hbox.add_child(w_sec)
	var w_icon := _color_dot(Color(0.24, 0.54, 1.0))
	w_sec.add_child(w_icon)
	_water_fill = _build_bar(w_sec, 48.0, Color(0.14, 0.20, 0.36), Color(0.24, 0.54, 1.0))

	# Currency (center)
	var c_sec := _hbox(Control.SIZE_EXPAND_FILL, BoxContainer.ALIGNMENT_CENTER, 2)
	hbox.add_child(c_sec)
	var coin := _color_dot(Color(1.0, 0.82, 0.1))
	c_sec.add_child(coin)
	_currency_label = Label.new()
	_currency_label.text = "0"
	_currency_label.add_theme_font_size_override("font_size", 8)
	_currency_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	_currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c_sec.add_child(_currency_label)

	# Energy (right)
	var e_sec := _hbox(Control.SIZE_EXPAND_FILL, BoxContainer.ALIGNMENT_END, 2)
	hbox.add_child(e_sec)
	_energy_fill = _build_bar(e_sec, 48.0, Color(0.14, 0.28, 0.14), Color(0.28, 0.88, 0.28))
	_energy_fill.size_flags_stretch_ratio = float(energy) / float(energy_max)
	var e_icon := _color_dot(Color(0.28, 0.88, 0.28))
	e_sec.add_child(e_icon)

	# Init bars
	_refresh_water_bar()
	_refresh_energy_bar()


# ── Hotbar ────────────────────────────────────────────────────────────────────

func _build_hotbar() -> void:
	var bar := Panel.new()
	bar.name = "Hotbar"
	bar.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.07, 0.09, 0.90)))
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -HOTBAR_H
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.name = "HotbarSlots"
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 1)
	bar.add_child(hbox)

	_slots = []
	for i in range(SLOT_COUNT):
		var slot := Panel.new()
		slot.name = "Slot%d" % i
		slot.custom_minimum_size = Vector2(24, 14)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.add_theme_stylebox_override("panel", _slot_style(false))
		hbox.add_child(slot)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

		var badge := Label.new()
		badge.name = "Badge"
		badge.visible = false
		badge.add_theme_font_size_override("font_size", 6)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(badge)

		_slots.append(slot)

	_refresh_hotbar_selection()


# ── Toast ─────────────────────────────────────────────────────────────────────

func _build_toast() -> void:
	_toast_panel = Panel.new()
	_toast_panel.name = "Toast"
	_toast_panel.visible = false
	_toast_panel.custom_minimum_size = Vector2(96, 12)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.08, 0.10, 0.92)
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	_toast_panel.add_theme_stylebox_override("panel", s)
	# Anchor to top-right, just below top bar
	_toast_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toast_panel.offset_left = -99.0
	_toast_panel.offset_top = TOP_BAR_H + 2.0
	_toast_panel.offset_right = -3.0
	_toast_panel.offset_bottom = TOP_BAR_H + 14.0
	add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 7)
	_toast_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_panel.add_child(_toast_label)


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: select_slot(0)
			KEY_2: select_slot(1)
			KEY_3: select_slot(2)
			KEY_4: select_slot(3)
			KEY_5: select_slot(4)
			KEY_6: select_slot(5)
			KEY_7: select_slot(6)
			KEY_8: select_slot(7)
			KEY_9: select_slot(8)
			KEY_0: select_slot(9)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_slot((selected_slot - 1 + SLOT_COUNT) % SLOT_COUNT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_slot((selected_slot + 1) % SLOT_COUNT)


# ── Public API ────────────────────────────────────────────────────────────────

func set_water(current: int, max_val: int = -1) -> void:
	if max_val >= 0:
		water_max = max_val
	water = clampi(current, 0, water_max)
	_refresh_water_bar()


func set_energy(current: int, max_val: int = -1) -> void:
	if max_val >= 0:
		energy_max = max_val
	energy = clampi(current, 0, energy_max)
	_refresh_energy_bar()


func set_currency(amount: int) -> void:
	currency = maxi(0, amount)
	if _currency_label:
		_currency_label.text = str(currency)


func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, SLOT_COUNT - 1)
	_refresh_hotbar_selection()


func set_slot_texture(slot: int, tex: Texture2D) -> void:
	if slot < 0 or slot >= _slots.size():
		return
	var icon := (_slots[slot] as Panel).get_node("Icon") as TextureRect
	if icon:
		icon.texture = tex


func set_slot_badge(slot: int, value: int) -> void:
	if slot < 0 or slot >= _slots.size():
		return
	var badge := (_slots[slot] as Panel).get_node("Badge") as Label
	if badge:
		badge.visible = value >= 0
		if value >= 0:
			badge.text = str(value)


func set_carrying_water(carrying: bool) -> void:
	set_water(water_max if carrying else 0)


func show_toast(message: String, duration: float = 2.0) -> void:
	if not _toast_panel:
		return
	_toast_label.text = message
	_toast_panel.modulate.a = 1.0
	_toast_panel.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(maxf(duration - 0.4, 0.1))
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


# ── Private ───────────────────────────────────────────────────────────────────

func _refresh_water_bar() -> void:
	if not _water_fill:
		return
	var ratio := 0.0 if water_max == 0 else float(water) / float(water_max)
	(_water_fill.get_parent() as Control).size = Vector2(48.0, 6.0)
	_water_fill.anchor_right = ratio
	_water_fill.offset_right = 0.0


func _refresh_energy_bar() -> void:
	if not _energy_fill:
		return
	var ratio := 0.0 if energy_max == 0 else float(energy) / float(energy_max)
	_energy_fill.anchor_right = ratio
	_energy_fill.offset_right = 0.0


func _refresh_hotbar_selection() -> void:
	for i in range(_slots.size()):
		(_slots[i] as Panel).add_theme_stylebox_override("panel", _slot_style(i == selected_slot))


func _build_bar(parent: HBoxContainer, width: float, bg_col: Color, fill_col: Color) -> ColorRect:
	var container := Control.new()
	container.custom_minimum_size = Vector2(width, 6.0)
	container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(container)

	var bg := ColorRect.new()
	bg.color = bg_col
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = fill_col
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_right = 1.0
	fill.anchor_bottom = 1.0
	fill.offset_left = 0.0
	fill.offset_top = 0.0
	fill.offset_right = 0.0
	fill.offset_bottom = 0.0
	container.add_child(fill)

	return fill


func _flat(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	return s


func _hbox(h_flags: int, align: int, sep: int) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = h_flags
	hb.alignment = align
	hb.add_theme_constant_override("separation", sep)
	return hb


func _color_dot(col: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.custom_minimum_size = Vector2(6.0, 6.0)
	cr.color = col
	cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return cr


func _slot_style(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if selected:
		s.bg_color = Color(0.36, 0.30, 0.07, 0.95)
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = Color(1.0, 0.85, 0.2)
	else:
		s.bg_color = Color(0.15, 0.15, 0.17, 0.90)
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = Color(0.30, 0.30, 0.34)
	return s
