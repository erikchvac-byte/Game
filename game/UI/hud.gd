extends CanvasLayer

const SLOT_COUNT := 12
const TOP_BAR_H := 12.0
const HOTBAR_H := 16.0

var water: int = 0
var water_max: int = 10
var selected_slot: int = 0

var _water_tp: TextureProgressBar
var _e_prompt: TextureRect
var _slots: Array = []
var _slot_items: Array = []
var _toast_panel: Panel
var _toast_label: Label
var _toast_tween: Tween
var _bucket_tex_empty: Texture2D
var _bucket_tex_full: Texture2D


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
	var w_gem := TextureRect.new()
	w_gem.texture = load("res://GameAssets/UI/WaterGem.png")
	w_gem.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	w_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	w_gem.custom_minimum_size = Vector2(10.0, 10.0)
	w_gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	w_sec.add_child(w_gem)
	_water_tp = TextureProgressBar.new()
	_water_tp.custom_minimum_size = Vector2(48.0, 8.0)
	_water_tp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_water_tp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_water_tp.min_value = 0.0
	_water_tp.max_value = 1.0
	_water_tp.value = 1.0
	_water_tp.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	var _bar_tex: Texture2D = load("res://GameAssets/UI/WaterMeterBar.png")
	_water_tp.texture_under = _bar_tex
	_water_tp.texture_progress = _bar_tex
	_water_tp.tint_under = Color(0.08, 0.15, 0.30)
	_water_tp.tint_progress = Color(0.24, 0.54, 1.0)
	w_sec.add_child(_water_tp)

	_refresh_water_bar()


# ── Hotbar ────────────────────────────────────────────────────────────────────

func _build_hotbar() -> void:
	var bar := Panel.new()
	bar.name = "Hotbar"
	bar.add_theme_stylebox_override("panel", _flat(Color(0.07, 0.07, 0.09, 0.90)))
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -HOTBAR_H
	add_child(bar)

	# Top-level HBox: [EPromptArea 20px] [HotbarSlots expand]
	var main_hbox := HBoxContainer.new()
	main_hbox.name = "HotbarLayout"
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 0)
	bar.add_child(main_hbox)

	# Dedicated E prompt zone — fixed 20px left column
	var e_container := Control.new()
	e_container.name = "EPromptArea"
	e_container.custom_minimum_size = Vector2(20, 0)
	e_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(e_container)

	_e_prompt = TextureRect.new()
	_e_prompt.name = "EPrompt"
	_e_prompt.texture = load("res://GameAssets/UI/key_e.png")
	_e_prompt.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_e_prompt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_e_prompt.visible = false
	_e_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_e_prompt.offset_left = 3.0
	_e_prompt.offset_right = -3.0
	e_container.add_child(_e_prompt)

	var hbox := HBoxContainer.new()
	hbox.name = "HotbarSlots"
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 1)
	main_hbox.add_child(hbox)

	_bucket_tex_empty = load("res://GameAssets/UI/bucket_empty.png")
	_bucket_tex_full = load("res://GameAssets/UI/bucket_full.png")

	_slots = []
	_slot_items = []
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
		_slot_items.append(null)

	# Slot 0 is the permanent bucket slot
	set_slot_texture(0, _bucket_tex_empty)
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



func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, SLOT_COUNT - 1)
	_refresh_hotbar_selection()


func hotbar_add_item(key: String, tex: Texture2D) -> bool:
	# slot 0 is reserved for bucket — stack into 1..11
	for i in range(1, SLOT_COUNT):
		var item = _slot_items[i]
		if item != null and item.key == key and item.count < 16:
			item.count += 1
			set_slot_badge(i, item.count if item.count > 1 else -1)
			return true
	for i in range(1, SLOT_COUNT):
		if _slot_items[i] == null:
			_slot_items[i] = {key = key, tex = tex, count = 1}
			set_slot_texture(i, tex)
			set_slot_badge(i, -1)
			return true
	return false


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


func show_interact_prompt(on: bool) -> void:
	if _e_prompt:
		_e_prompt.visible = on


func set_carrying_water(carrying: bool) -> void:
	set_water(water_max if carrying else 0)
	set_slot_texture(0, _bucket_tex_full if carrying else _bucket_tex_empty)


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
	if not _water_tp:
		return
	_water_tp.value = 0.0 if water_max == 0 else float(water) / float(water_max)



func _refresh_hotbar_selection() -> void:
	for i in range(_slots.size()):
		(_slots[i] as Panel).add_theme_stylebox_override("panel", _slot_style(i == selected_slot))



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



func _slot_style(_selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.15, 0.17, 0.90)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.30, 0.30, 0.34)
	return s
