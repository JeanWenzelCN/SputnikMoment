shader_type canvas_item;
render_mode blend_mix;

uniform float density = 300.0;
uniform vec4 star_color : source_color = vec4(0.86, 0.88, 0.93, 1.0);
uniform float brightness = 0.55;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void fragment() {
	vec2 g = UV * vec2(density * 1.8, density);
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;

	float h = hash21(cell);
	float star = 0.0;
	if (h > 0.982) {
		vec2 off = vec2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5;
		float d = length(f - off * 0.65);
		float size = mix(0.05, 0.15, hash21(cell + 11.3));
		star = smoothstep(size, 0.0, d);
	}

	float tw = 0.62 + 0.38 * sin(TIME * (0.6 + h * 2.2) + h * 40.0);
	COLOR = vec4(star_color.rgb, star * tw * brightness);
}