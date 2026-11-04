shader_type canvas_item;

uniform float petal_index = 0.0;
uniform float petal_count = 6.0;
uniform float aspect_ratio = 1.5;
uniform bool center_only = false;

void fragment() {
	vec2 from_center = (UV - vec2(0.5)) * vec2(aspect_ratio, 1.0);
	float radius = length(from_center);
	float angle = atan(from_center.y, from_center.x);
	float petal_angle = (petal_index / petal_count) * 6.2831853 - 1.5707963;
	float angular_distance = abs(atan(sin(angle - petal_angle), cos(angle - petal_angle)));
	float sector = 3.1415926 / petal_count;
	float visible_piece = center_only ? 1.0 - smoothstep(0.105, 0.13, radius) : smoothstep(0.11, 0.14, radius) * (1.0 - smoothstep(sector - 0.06, sector, angular_distance));
	vec4 painted = texture(TEXTURE, UV);
	painted.a *= visible_piece;
	COLOR = painted;
}
