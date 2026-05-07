// Optional runtime screen-space palette quantization.
// Apply to a full-screen ColorRect on a top-level CanvasLayer (layer=99, above world).
// Set palette uniform via GDScript: material.set_shader_parameter("palette", packed_colors)
//
// Usage in GDScript:
//   var mat := ShaderMaterial.new()
//   mat.shader = preload("res://addons/palette_enforcer/palette_enforcer.gdshader")
//   var pal := PaletteQuantizer.load_palette()
//   var packed := PackedColorArray(pal)
//   mat.set_shader_parameter("palette", packed)
//   mat.set_shader_parameter("palette_size", pal.size())
//   $CanvasLayer/ColorRect.material = mat

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform vec4 palette[64];
uniform int palette_size = 0;

vec4 nearest_palette(vec4 c) {
	if (c.a < 0.05 || palette_size == 0) {
		return c;
	}
	float best = 1e10;
	vec4 result = palette[0];
	for (int i = 0; i < palette_size; i++) {
		// Perceptual weighting (ITU-R BT.601)
		vec3 d = (c.rgb - palette[i].rgb) * vec3(0.299, 0.587, 0.114);
		float dist = dot(d, d);
		if (dist < best) {
			best = dist;
			result = palette[i];
		}
	}
	return vec4(result.rgb, c.a);
}

void fragment() {
	COLOR = nearest_palette(texture(SCREEN_TEXTURE, SCREEN_UV));
}
