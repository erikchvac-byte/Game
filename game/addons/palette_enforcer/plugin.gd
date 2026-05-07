@tool
extends EditorPlugin

const ASSETS_PATH = "res://GameAssets"
const GPL_PATH = "res://addons/palette_enforcer/game_palette.gpl"
const DEBOUNCE_SECS = 1.0

var _debounce: Timer
var _known_mtimes: Dictionary = {}
var _processing: Dictionary = {}
var _auto_quantize := true

func _enter_tree() -> void:
	add_tool_menu_item("Palette: Extract from Image...", _extract_from_image)
	add_tool_menu_item("Palette: Quantize All GameAssets", _quantize_all)
	add_tool_menu_item("Palette: Check Compliance", _check_compliance_all)
	add_tool_menu_item("Palette: Export .gpl for Aseprite", _export_gpl)
	add_tool_menu_item("Palette: Toggle Auto-Quantize", _toggle_auto_quantize)

	_debounce = Timer.new()
	_debounce.one_shot = true
	_debounce.wait_time = DEBOUNCE_SECS
	_debounce.timeout.connect(_do_auto_scan)
	add_child(_debounce)

	_refresh_mtimes()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_fs_changed)

	var pal = PaletteQuantizer.load_palette()
	print("[PaletteEnforcer] Active | %d palette colors | auto-quantize: ON" % pal.size())

func _exit_tree() -> void:
	for item: String in [
		"Palette: Extract from Image...",
		"Palette: Quantize All GameAssets",
		"Palette: Check Compliance",
		"Palette: Export .gpl for Aseprite",
		"Palette: Toggle Auto-Quantize",
	]:
		remove_tool_menu_item(item)

	var fs = EditorInterface.get_resource_filesystem()
	if fs.filesystem_changed.is_connected(_on_fs_changed):
		fs.filesystem_changed.disconnect(_on_fs_changed)

# ── filesystem watcher ─────────────────────────────────────────────────────────

func _on_fs_changed() -> void:
	if _auto_quantize:
		_debounce.start()

func _refresh_mtimes() -> void:
	_known_mtimes.clear()
	_walk_pngs(ASSETS_PATH, func(p): _known_mtimes[p] = FileAccess.get_modified_time(p))

func _do_auto_scan() -> void:
	var palette := PaletteQuantizer.load_palette()
	if palette.is_empty():
		return

	var current: Dictionary = {}
	_walk_pngs(ASSETS_PATH, func(p): current[p] = FileAccess.get_modified_time(p))

	var changed: Array[String] = []
	for path: String in current:
		if not _processing.has(path):
			if not _known_mtimes.has(path) or _known_mtimes[path] != current[path]:
				changed.append(path)

	_known_mtimes = current

	if changed.is_empty():
		return

	for path in changed:
		_quantize_file(path, palette)

	print("[PaletteEnforcer] Auto-quantized %d file(s)." % changed.size())
	EditorInterface.get_resource_filesystem().scan()

# ── quantization ───────────────────────────────────────────────────────────────

func _quantize_file(res_path: String, palette: Array[Color]) -> void:
	if _processing.has(res_path):
		return
	_processing[res_path] = true

	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img and PaletteQuantizer.quantize_image(img, palette):
		img.save_png(abs_path)

	_known_mtimes[res_path] = FileAccess.get_modified_time(res_path)
	_processing.erase(res_path)

func _quantize_all() -> void:
	var palette := PaletteQuantizer.load_palette()
	if palette.is_empty():
		push_warning("[PaletteEnforcer] Palette is empty — use 'Extract from Image' first.")
		return

	var paths: Array[String] = []
	_walk_pngs(ASSETS_PATH, func(p): paths.append(p))

	var fixed := 0
	for path: String in paths:
		var abs := ProjectSettings.globalize_path(path)
		var img := Image.load_from_file(abs)
		if img and PaletteQuantizer.quantize_image(img, palette):
			img.save_png(abs)
			fixed += 1

	_refresh_mtimes()
	EditorInterface.get_resource_filesystem().scan()
	print("[PaletteEnforcer] Quantize All: %d/%d files modified." % [fixed, paths.size()])

# ── compliance check ───────────────────────────────────────────────────────────

func _check_compliance_all() -> void:
	var palette := PaletteQuantizer.load_palette()
	if palette.is_empty():
		print("[PaletteEnforcer] Palette is empty.")
		return

	var paths: Array[String] = []
	_walk_pngs(ASSETS_PATH, func(p): paths.append(p))

	var report: Array[String] = []
	var total_violations := 0

	for path: String in paths:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if not img:
			continue
		var result := PaletteQuantizer.check_compliance(img, palette)
		if result["violations"] > 0:
			total_violations += result["violations"]
			report.append("  %s  (%d/%d px off-palette)" % [
				path.trim_prefix(ASSETS_PATH + "/"),
				result["violations"],
				result["total"]
			])

	if total_violations == 0:
		print("[PaletteEnforcer] PASS: all %d assets are palette-compliant." % paths.size())
	else:
		print("[PaletteEnforcer] FAIL: %d off-palette pixels across %d file(s):" % [
			total_violations, report.size()
		])
		for line in report:
			print(line)

# ── extract palette ────────────────────────────────────────────────────────────

func _extract_from_image() -> void:
	var dialog := EditorFileDialog.new()
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.png", "PNG Images")
	dialog.title = "Select Source Image — all its colors become the master palette"
	dialog.file_selected.connect(
		func(path: String) -> void:
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if not img:
				push_error("[PaletteEnforcer] Could not load: " + path)
				return
			var colors := PaletteQuantizer.extract_palette(img, 256)
			PaletteQuantizer.save_palette(colors)
			print("[PaletteEnforcer] Extracted %d colors from %s → palette.json" % [
				colors.size(), path.get_file()
			])
			if colors.size() > 64:
				push_warning(("[PaletteEnforcer] %d colors extracted — that's a lot for pixel art. "
					+ "Consider using a simpler source image or manually trimming palette.json.") % colors.size())
	)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered(Vector2i(900, 650))

# ── Aseprite export ────────────────────────────────────────────────────────────

func _export_gpl() -> void:
	var palette := PaletteQuantizer.load_palette()
	if palette.is_empty():
		push_warning("[PaletteEnforcer] Palette is empty — extract from an image first.")
		return
	var abs := ProjectSettings.globalize_path(GPL_PATH)
	PaletteQuantizer.export_gpl(palette, abs)
	print("[PaletteEnforcer] Exported → %s  (%d colors)" % [GPL_PATH, palette.size()])
	print("[PaletteEnforcer] In Aseprite: File > Load Palette → pick game_palette.gpl")

# ── toggle ─────────────────────────────────────────────────────────────────────

func _toggle_auto_quantize() -> void:
	_auto_quantize = not _auto_quantize
	print("[PaletteEnforcer] Auto-quantize: " + ("ON" if _auto_quantize else "OFF"))

# ── helpers ────────────────────────────────────────────────────────────────────

func _walk_pngs(base: String, cb: Callable) -> void:
	var dir := DirAccess.open(base)
	if not dir:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := base + "/" + name
		if dir.current_is_dir() and not name.begins_with("."):
			_walk_pngs(full, cb)
		elif name.to_lower().ends_with(".png"):
			cb.call(full)
		name = dir.get_next()
	dir.list_dir_end()
