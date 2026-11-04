shader_type canvas_item;

uniform float motion_amount : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D motion_map : filter_linear, repeat_disable;

void fragment() {
	vec4 motion = texture(motion_map, UV);
	float phase = motion.b * 6.2831853;
	float passing_air = 0.7 + 0.3 * sin(TIME * 0.43 - UV.x * 6.2);
	float sway = sin(TIME * 1.03 - UV.x * 2.4 + phase);
	float flutter = 0.26 * sin(TIME * 1.79 + phase * 1.7);
	vec2 displacement = vec2(
		(sway + flutter) * motion.r * 8.5,
		(0.55 * cos(TIME * 0.9 + phase) + 0.18 * sin(TIME * 1.6 + phase)) * motion.g * 5.0
	) * motion.a * passing_air * motion_amount;
	vec2 source_uv = clamp(UV + displacement / vec2(1672.0, 941.0), vec2(0.0), vec2(1.0));
	COLOR = texture(TEXTURE, source_uv);
}
