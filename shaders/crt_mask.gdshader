shader_type canvas_item;
render_mode blend_mix;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.30;
uniform float line_density = 235.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.012, 0.024, 0.020, 1.0);

void fragment() {
	float sy = sin(UV.y * line_density * 6.2831853) * 0.5 + 0.5;
	float scan = smoothstep(0.12, 1.0, sy);
	float a = (1.0 - scan) * scanline_strength;

	vec2 d = UV - vec2(0.5);
	float vig = smoothstep(0.26, 0.80, length(d * vec2(1.06, 1.0)));
	a += vig * vignette_strength * 0.55;

	COLOR = vec4(tint.rgb, clamp(a, 0.0, 0.94));
}