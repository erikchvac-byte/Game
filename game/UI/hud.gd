extends CanvasLayer

const SLOT_COUNT := 7
const TOP_BAR_H := 12.0
const HOTBAR_H := 24.0

# Slot-hole geometry measured from hotbar17.png (source px). The 200×36 atlas
# region stretches to fill the bottom bar, so anchors = src_px / region_size.
const REGION_W := 200.0
const HOLE_X := [[24, 40], [46, 63], [69, 86], [92, 108], [114, 131], [137, 154], [160, 176]]
const HOLE_T := 0.25      # (91-82)/36
const HOLE_B := 0.7222    # (108-82)/36
const HOLE_BAND_L := 0.12 # 24/200  — left edge of hole band (backing)
const HOLE_BAND_R := 0.88 # 176/200 — right edge of hole band (backing)

var water: int = 0
var water_max: int = 10
var selected_slot: int = 0

var _water_fill: ColorRect
var _water_fill_max_w := 44.0
var _slots: Array = []
var _toast_panel: Panel
var _toast_label: Label
var _toast_tween: Tween
var _bucket_tex_empty: Texture2D
var _bucket_tex_full: Texture2D
var _equipped_slot: int = -1

signal slot_selected(index: int)


func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_hotbar()
	_build_toast()
	_build_datetime_panel()
	get_node("/root/InventoryManager").slot_changed.connect(_on_slot_changed)


# ── Top bar ───────────────────────────────────────────────────────────────────

func _build_top_bar() -> void:
	var bar := Panel.new()
	bar.name = "TopBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	w_gem.texture = load("res://assets/ui/WaterGem.png")
	w_gem.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	w_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	w_gem.custom_minimum_size = Vector2(10.0, 10.0)
	w_gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	w_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w_sec.add_child(w_gem)
	var fill_wrap := Control.new()
	fill_wrap.name = "WaterFillWrap"
	fill_wrap.custom_minimum_size = Vector2(52.0, TOP_BAR_H - 2.0)
	fill_wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fill_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fill_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w_sec.add_child(fill_wrap)

	var fill_atlas := AtlasTexture.new()
	fill_atlas.atlas = load("res://assets/ui/fill_bar_new.png")
	fill_atlas.region = Rect2(0, 82, 200, 36)
	var fill_bg := TextureRect.new()
	fill_bg.texture = fill_atlas
	fill_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill_bg.stretch_mode = TextureRect.STRETCH_SCALE
	fill_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_wrap.add_child(fill_bg)

	_water_fill = ColorRect.new()
	_water_fill.color = Color(0.24, 0.54, 1.0)
	_water_fill.anchor_left = 0.0
	_water_fill.anchor_top = 0.0
	_water_fill.anchor_right = 0.0
	_water_fill.anchor_bottom = 1.0
	_water_fill.offset_left = 4.0
	_water_fill.offset_right = 4.0 + _water_fill_max_w
	_water_fill.offset_top = 3.0
	_water_fill.offset_bottom = -3.0
	_water_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_wrap.add_child(_water_fill)

	_refresh_water_bar()


# ── Hotbar ────────────────────────────────────────────────────────────────────

func _build_hotbar() -> void:
	var bar := Panel.new()
	bar.name = "Hotbar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -HOTBAR_H
	add_child(bar)

	# Dark backing behind the wood frame — shows through the transparent holes
	var backing := Panel.new()
	backing.name = "HotbarBacking"
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.anchor_left = HOLE_BAND_L
	backing.anchor_right = HOLE_BAND_R
	backing.anchor_top = HOLE_T
	backing.anchor_bottom = HOLE_B
	backing.offset_left = 0.0
	backing.offset_right = 0.0
	backing.offset_top = 0.0
	backing.offset_bottom = 0.0
	backing.add_theme_stylebox_override("panel", _flat(Color(0.09, 0.07, 0.05, 1.0)))
	bar.add_child(backing)

	var hotbar_atlas := AtlasTexture.new()
	hotbar_atlas.atlas = load("res://assets/ui/hotbar17.png")
	hotbar_atlas.region = Rect2(0, 82, 200, 36)
	var hotbar_bg := TextureRect.new()
	hotbar_bg.name = "HotbarBG"
	hotbar_bg.texture = hotbar_atlas
	hotbar_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hotbar_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hotbar_bg.stretch_mode = TextureRect.STRETCH_SCALE
	hotbar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(hotbar_bg)

	_bucket_tex_empty = load("res://assets/ui/bucket_empty.png")
	_bucket_tex_full = load("res://assets/ui/bucket_full.png")

	# 7 slots absolutely anchored to the PNG hole rects (SPC/T prompts removed)
	_slots = []
	for i in range(SLOT_COUNT):
		var slot := Panel.new()
		slot.name = "Slot%d" % i
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.anchor_left = HOLE_X[i][0] / REGION_W
		slot.anchor_right = HOLE_X[i][1] / REGION_W
		slot.anchor_top = HOLE_T
		slot.anchor_bottom = HOLE_B
		slot.offset_left = 0.0
		slot.offset_right = 0.0
		slot.offset_top = 0.0
		slot.offset_bottom = 0.0
		slot.add_theme_stylebox_override("panel", _slot_style(false, false))
		bar.add_child(slot)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 1.0
		icon.offset_right = -1.0
		icon.offset_top = 0.0
		icon.offset_bottom = 0.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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

	# Slot 0 is the permanent bucket slot
	set_slot_texture(0, _bucket_tex_empty)
	_refresh_hotbar_selection()


# ── Toast ─────────────────────────────────────────────────────────────────────

func _build_toast() -> void:
	_toast_panel = Panel.new()
	_toast_panel.name = "Toast"
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


# ── Date/time panel ──────────────────────────────────────────────────────────

func _build_datetime_panel() -> void:
	var dt_atlas := AtlasTexture.new()
	dt_atlas.atlas = load("res://assets/UI/datetime_panel.png")
	dt_atlas.region = Rect2(0, 82, 200, 36)
	var dt := TextureRect.new()
	dt.name = "DateTimePanel"
	dt.texture = dt_atlas
	dt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dt.stretch_mode = TextureRect.STRETCH_SCALE
	dt.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dt.offset_left = -70.0
	dt.offset_top = 1.0
	dt.offset_right = -3.0
	dt.offset_bottom = TOP_BAR_H - 1.0
	add_child(dt)


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
			select_slot((selected_slot + 1) % SLOT_COUNT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_slot((selected_slot - 1 + SLOT_COUNT) % SLOT_COUNT)


# ── Public API ────────────────────────────────────────────────────────────────

func set_water(current: int, max_val: int = -1) -> void:
	if max_val >= 0:
		water_max = max_val
	water = clampi(current, 0, water_max)
	_refresh_water_bar()



func select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, SLOT_COUNT - 1)
	_refresh_hotbar_selection()
	slot_selected.emit(selected_slot)


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

func _on_slot_changed(index: int, item: Variant) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	set_slot_texture(index, null if item == null else item.tex)
	var count: int = 0 if item == null else item.count
	set_slot_badge(index, count if count > 1 else -1)
	var icon := (_slots[index] as Panel).get_node("Icon") as TextureRect
	icon.offset_left = 0.0
	icon.offset_top = 0.0
	icon.offset_right = 0.0
	icon.offset_bottom = 0.0


func _refresh_water_bar() -> void:
	if not _water_fill:
		return
	var ratio := 0.0 if water_max == 0 else float(water) / float(water_max)
	_water_fill.offset_right = 4.0 + _water_fill_max_w * ratio



func set_equipped_slot(index: int) -> void:
	_equipped_slot = index
	_refresh_hotbar_selection()


func _refresh_hotbar_selection() -> void:
	for i in range(_slots.size()):
		(_slots[i] as Panel).add_theme_stylebox_override("panel", _slot_style(i == selected_slot, i == _equipped_slot))



func _flat(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	return s


func _hbox(h_flags: int, align: int, sep: int) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = h_flags
	hb.alignment = align as HBoxContainer.AlignmentMode
	hb.add_theme_constant_override("separation", sep)
	return hb



func _slot_style(selected: bool, equipped: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	if equipped and selected:
		s.bg_color = Color(0.20, 0.18, 0.10, 0.90)
		s.border_color = Color(1.0, 0.85, 0.20)
	elif equipped:
		s.border_color = Color(0.90, 0.72, 0.15)
	elif selected:
		s.border_color = Color(0.85, 0.85, 0.90)
	else:
		s.border_color = Color(0, 0, 0, 0)
	return s
