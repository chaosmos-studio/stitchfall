shader_type canvas_item;

// The intro's back with a round hole in it, `radius` across from `centre`, both in the layer's own units, so
// the screen under the intro shows through.
uniform vec2 centre = vec2(0.0);
uniform float radius = 0.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	if (distance(local, centre) < radius) {
		discard;
	}
}
