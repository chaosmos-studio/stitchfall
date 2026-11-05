shader_type canvas_item;

uniform sampler2D clean_plate : filter_linear;
uniform sampler2D reveal_mask : filter_linear;

void fragment() {
	float tree = smoothstep(0.46, 0.58, UV.x) * (1.0 - smoothstep(0.18, 0.47, UV.y));
	float meadow = smoothstep(0.47, 0.67, UV.y) * (1.0 - smoothstep(0.87, 1.0, UV.y));
	vec2 tree_air = vec2(sin(TIME * 0.58 + UV.y * 4.0) * 0.0062, cos(TIME * 0.42 + UV.x * 7.0) * 0.0024) * tree;
	vec2 meadow_air = vec2(sin(TIME * 0.72 + UV.x * 20.0) * 0.0022, cos(TIME * 0.53 + UV.x * 14.0) * 0.0027) * meadow;
	vec2 painted_uv = clamp(UV + tree_air + meadow_air, vec2(0.0), vec2(1.0));
	vec4 painting = texture(TEXTURE, painted_uv);
	vec4 bare_canvas = texture(clean_plate, UV);
	float reveal = texture(reveal_mask, painted_uv).a;
	COLOR = mix(painting, bare_canvas, reveal);
}
