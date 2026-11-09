shader_type canvas_item;

// While the stage is drawn in big pixels, each pixel takes whichever of the three brand colours it is nearest,
// so the blocks read as pixel art rather than a blurred mosaic.

uniform bool snap = false;
uniform vec4 paper : source_color;
uniform vec4 ink : source_color;
uniform vec4 coral : source_color;

void fragment() {
	vec4 colour = texture(TEXTURE, UV);
	if (snap) {
		// A coloured pixel is coral, and a grey one is ink or paper by how light it is, so the soft grey edges of
		// letters fall to one side or the other instead of turning coral.
		float chroma = max(colour.r, max(colour.g, colour.b)) - min(colour.r, min(colour.g, colour.b));
		vec3 weights = vec3(0.299, 0.587, 0.114);
		float light = dot(colour.rgb, weights);
		float ink_light = dot(ink.rgb, weights);
		float paper_light = dot(paper.rgb, weights);
		if (chroma > 0.28) {
			colour.rgb = coral.rgb;
		} else {
			colour.rgb = abs(light - ink_light) < abs(light - paper_light) ? ink.rgb : paper.rgb;
		}
	}
	COLOR = colour;
}
