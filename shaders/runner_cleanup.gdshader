shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float red_artifact = step(0.78, tex.r) * step(tex.g * 2.2, tex.r) * step(tex.b * 2.2, tex.r);
	float yellow_artifact = step(0.82, tex.r) * step(0.62, tex.g) * (1.0 - step(0.25, tex.b));
	tex.a *= 1.0 - max(red_artifact, yellow_artifact);
	COLOR = tex;
}
