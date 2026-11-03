shader_type canvas_item;

uniform float motion_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float canopy = smoothstep(0.32, 0.52, UV.x) * (1.0 - smoothstep(0.10, 0.31, UV.y));
	float meadow = smoothstep(0.49, 0.71, UV.x) * smoothstep(0.52, 0.78, UV.y);
	float sway = max(canopy, meadow * 0.55) * motion_amount;
	float breath = sin(TIME * 0.78 + UV.x * 14.0 + UV.y * 6.0);
	vec2 offset = vec2(breath * 0.0011, cos(TIME * 0.61 + UV.x * 9.0) * 0.00045) * sway;
	COLOR = texture(TEXTURE, clamp(UV + offset, vec2(0.0), vec2(1.0)));
}
