@tool
class_name PaletteQuantizer
extends RefCounted

const _PALETTE_PATH = "res://addons/palette_enforcer/palette.json"

static func load_palette() -> Array[Color]:
	if not FileAccess.file_exists(_PALETTE_PATH):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(_PALETTE_PATH))
	if typeof(data) != TYPE_DICTIONARY or not data.has("colors"):
		return []
	var out: Array[Color] = []
	for h: String in data["colors"]:
		out.append(Color.html(h))
	return out

static func save_palette(colors: Array[Color]) -> void:
	var hexes: Array = []
	for c in colors:
		hexes.append(_to_hex(c))
	var f = FileAccess.open(_PALETTE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"name": "Game Master Palette", "colors": hexes}, "\t"))

# Remaps every opaque pixel to nearest palette color. Returns true if anything changed.
static func quantize_image(img: Image, palette: Array[Color]) -> bool:
	if palette.is_empty():
		return false
	img.convert(Image.FORMAT_RGBA8)
	var changed := false
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a < 0.02:
				continue
			var nc := _nearest(px, palette)
			if not _eq(px, nc):
				img.set_pixel(x, y, Color(nc.r, nc.g, nc.b, px.a))
				changed = true
	return changed

# Collects unique opaque colors from an image (up to max_colors).
static func extract_palette(img: Image, max_colors: int = 256) -> Array[Color]:
	img.convert(Image.FORMAT_RGBA8)
	var seen: Dictionary = {}
	var result: Array[Color] = []
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a < 0.02:
				continue
			var k := _to_hex(px)
			if not seen.has(k):
				seen[k] = true
				result.append(Color(px.r, px.g, px.b, 1.0))
				if result.size() >= max_colors:
					return result
	return result

# Returns violation counts: {violations, total, off_colors: {hex: count}}
static func check_compliance(img: Image, palette: Array[Color]) -> Dictionary:
	img.convert(Image.FORMAT_RGBA8)
	var violations := 0
	var total := 0
	var off: Dictionary = {}
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a < 0.02:
				continue
			total += 1
			if not _in_palette(px, palette):
				violations += 1
				var k := _to_hex(px)
				off[k] = off.get(k, 0) + 1
	return {"violations": violations, "total": total, "off_colors": off}

# Writes a GIMP Palette (.gpl) file readable by Aseprite and GIMP.
static func export_gpl(palette: Array[Color], abs_path: String) -> void:
	var lines := PackedStringArray([
		"GIMP Palette",
		"Name: Game Master Palette",
		"Columns: 8",
		"#"
	])
	for c in palette:
		var r := int(c.r * 255.0 + 0.5)
		var g := int(c.g * 255.0 + 0.5)
		var b := int(c.b * 255.0 + 0.5)
		lines.append("%3d %3d %3d  %s" % [r, g, b, _to_hex(c)])
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")

static func _nearest(c: Color, pal: Array[Color]) -> Color:
	var best := pal[0]
	var bd := _dist(c, pal[0])
	for i in range(1, pal.size()):
		var d := _dist(c, pal[i])
		if d < bd:
			bd = d
			best = pal[i]
	return best

# Perceptual luminance weighting (ITU-R BT.601)
static func _dist(a: Color, b: Color) -> float:
	var dr := (a.r - b.r) * 0.299
	var dg := (a.g - b.g) * 0.587
	var db := (a.b - b.b) * 0.114
	return dr * dr + dg * dg + db * db

static func _in_palette(c: Color, pal: Array[Color]) -> bool:
	for p in pal:
		if _eq(c, p):
			return true
	return false

static func _eq(a: Color, b: Color) -> bool:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) < 0.008

static func _to_hex(c: Color) -> String:
	return "#%02X%02X%02X" % [
		int(c.r * 255.0 + 0.5),
		int(c.g * 255.0 + 0.5),
		int(c.b * 255.0 + 0.5)
	]
