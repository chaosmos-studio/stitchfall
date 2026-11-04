shader_type canvas_item;

uniform sampler2D clean_plate : filter_linear;
uniform sampler2D reveal_mask : filter_linear;

void fragment() {
	vec4 painting = texture(TEXTURE, UV);
	vec4 bare_canvas = texture(clean_plate, UV);
	float reveal = texture(reveal_mask, UV).a;
	COLOR = mix(painting, bare_canvas, reveal);
}
