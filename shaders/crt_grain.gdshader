shader_type canvas_item;
render_mode blend_add;

uniform float grain_amount : hint_range(0.0, 0.3) = 0.045;
uniform float flicker_amount : hint_range(0.0, 0.2) = 0.016;
uniform vec4 grain_tint : source_color = vec4(0.62, 0.56, 0.40, 1.0);

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * vec2(520.0, 300.0));
	float n = hash12(cell + vec2(floor(TIME * 26.0), floor(TIME * 11.0)));
	float f = (hash12(vec2(floor(TIME * 9.0), 1.7)) - 0.5) * flicker_amount;
	COLOR = vec4(grain_tint.rgb, n * grain_amount + max(f, 0.0));
}