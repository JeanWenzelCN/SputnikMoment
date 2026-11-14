shader_type canvas_item;
render_mode blend_mix;

uniform vec3 ocean_color : source_color = vec3(0.043, 0.075, 0.086);
uniform vec3 land_color : source_color = vec3(0.325, 0.298, 0.216);
uniform vec3 highland_color : source_color = vec3(0.443, 0.412, 0.310);
uniform vec3 ice_color : source_color = vec3(0.780, 0.800, 0.790);
uniform vec3 atmo_color : source_color = vec3(0.350, 0.600, 0.720);
uniform vec3 surface_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float light_dir : hint_range(-3.15, 3.15) = -2.30;
uniform float terrain_scale = 2.60;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = (UV * 2.0 - 1.0) * 1.4;
	float r = length(uv);
	vec3 light_vec = normalize(vec3(cos(light_dir), sin(light_dir), 0.55));

	if (r > 1.0) {
		float g = clamp((r - 1.0) / 0.40, 0.0, 1.0);
		float a = pow(1.0 - g, 2.6) * 0.50;
		COLOR = vec4(atmo_color * 1.1, a);
	} else {
		vec3 n = vec3(uv, sqrt(max(0.0, 1.0 - r * r)));
		vec3 sp = n * terrain_scale;

		float h = fbm(sp * 1.7 + vec3(11.3, 4.7, 8.1));
		float h2 = fbm(sp * 5.1 + vec3(2.2, 9.9, 3.3));
		float land = smoothstep(0.505, 0.590, h + h2 * 0.18);

		vec3 base = mix(ocean_color, land_color, land);
		base = mix(base, highland_color, smoothstep(0.620, 0.860, h) * land);

		float lat = abs(n.y);
		float ice = smoothstep(0.760, 0.945, lat + (h2 - 0.5) * 0.10);
		base = mix(base, ice_color, ice);

		float lit = smoothstep(-0.28, 0.34, dot(n, light_vec));
		vec3 col = base * (0.055 + 1.075 * lit);

		float rim = pow(1.0 - clamp(n.z, 0.0, 1.0), 3.0);
		col += atmo_color * rim * 0.42 * lit;

		float grain = hash31(vec3(uv * 640.0, 3.0)) - 0.5;
		col *= 1.0 + grain * 0.045;
		col = mix(col, col * surface_tint * 1.9, 0.88);

		COLOR = vec4(col, 1.0);
	}
}