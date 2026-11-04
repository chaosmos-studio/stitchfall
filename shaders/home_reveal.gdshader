shader_type canvas_item;

uniform sampler2D clean_plate : filter_linear;
uniform sampler2D reveal_mask : filter_linear;

void fragment() {
	vec4 painting = texture(TEXTURE, UV);
	vec4 bare_canvas = texture(clean_plate, UV);
	float canopy = smoothstep(0.34, 0.41, UV.x) * (1.0 - smoothstep(0.17, 0.25, UV.y));
	float reveal = max(texture(reveal_mask, UV).a, canopy);
	COLOR = mix(painting, bare_canvas, reveal);
}
