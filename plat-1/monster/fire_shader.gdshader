shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.75, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform vec4 outer_color : source_color = vec4(0.92, 0.15, 0.02, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.25, 0.04, 0.02, 0.0);

uniform float flame_speed : hint_range(0.1, 10.0) = 2.4;
uniform float flame_scale : hint_range(0.5, 10.0) = 3.2;
uniform float turbulence : hint_range(0.0, 1.5) = 0.45;
uniform float column_width : hint_range(0.1, 1.0) = 0.55;
uniform float edge_softness : hint_range(0.05, 0.8) = 0.35;
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.4;
uniform float ember_density : hint_range(0.0, 3.0) = 1.0;

// 2D Hash
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Value / Gradient Noise
float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y
	);
}

// Fractal Brownian Motion (4 octaves)
float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	float c = cos(0.65);
	float s = sin(0.65);

	for (int i = 0; i < 4; i++) {
		val += amp * noise2d(p * freq);
		p = vec2(p.x * c - p.y * s, p.x * s + p.y * c) * 2.05 + vec2(19.2, 37.4);
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec2 uv = UV;

	// Soft boundary fade on all 4 sides so fire NEVER cuts sharply against the rectangle edges
	float fade_x = smoothstep(0.0, 0.22, uv.x) * smoothstep(1.0, 0.78, uv.x);
	float fade_y = smoothstep(0.0, 0.16, uv.y) * smoothstep(1.0, 0.88, uv.y);
	float bounds_mask = fade_x * fade_y;

	// Coords scaled for natural vertical flame proportions
	vec2 aspect_uv = vec2(uv.x * 2.2, uv.y * 5.5);

	// Multi-frequency upward flow
	vec2 flow_main = vec2(0.0, -TIME * flame_speed);
	vec2 flow_detail = vec2(0.0, -TIME * flame_speed * 1.35);

	// Swirling domain distortion for realistic licking flame tongues
	float warp_x = fbm(aspect_uv * flame_scale + flow_main);
	float warp_y = fbm(aspect_uv * flame_scale * 1.4 + flow_detail + vec2(warp_x, warp_x * 0.7));
	vec2 warped_uv = aspect_uv + vec2(warp_x * turbulence, warp_y * (turbulence * 0.5));

	// Multi-octave flame turbulence
	float fire_noise = fbm(warped_uv * flame_scale + flow_main) * 0.5 + 0.5;
	float fire_noise_fine = noise2d(aspect_uv * (flame_scale * 2.5) + flow_detail) * 0.5 + 0.5;
	float combined_noise = mix(fire_noise, fire_noise_fine, 0.25);

	// Column shape: parabolic falloff from center (0 at edges, 1 in center)
	float center_dist = abs(uv.x - 0.5) * 2.0;
	float base_shape = clamp(1.0 - (center_dist / column_width), 0.0, 1.0);
	base_shape = smoothstep(0.0, 1.0, base_shape);

	// Combine column profile with organic flame noise for natural eroded licking edges
	float flame_density = (base_shape * 1.35 + combined_noise * 0.75 - 0.55) * bounds_mask;

	// Soft threshold layers for color gradients
	float core_val  = smoothstep(0.70, 0.95, flame_density);
	float inner_val = smoothstep(0.42, 0.78, flame_density);
	float outer_val = smoothstep(0.12, 0.52, flame_density);
	float smoke_val = smoothstep(0.01, 0.28, flame_density);

	// Smooth color blend from dark smoke -> deep fire -> orange flame -> molten core
	vec4 col = mix(smoke_color, outer_color, outer_val);
	col = mix(col, inner_color, inner_val);
	col = mix(col, core_color, core_val);

	// Dynamic brightness pulsation & flicker
	float flicker = 1.0 + sin(TIME * 8.0 + uv.y * 6.0) * 0.07 + cos(TIME * 14.0) * 0.04;
	col.rgb *= glow_intensity * flicker;

	// Soft atmospheric outer aura / halo (eliminates any harsh boundaries)
	float aura = smoothstep(0.0, 0.4, base_shape * bounds_mask) * (0.25 + combined_noise * 0.2);
	col.rgb += outer_color.rgb * aura * 0.6;

	// Floating rising embers / spark flakes
	vec2 ember_coords = aspect_uv * 10.0 + vec2(sin(TIME * 3.5 + uv.y * 12.0) * 0.5, -TIME * flame_speed * 2.8);
	float ember_noise = noise2d(ember_coords);
	float ember_val = smoothstep(0.52, 0.82, ember_noise) * ember_density * bounds_mask;
	col.rgb += vec3(1.0, 0.92, 0.65) * ember_val * 2.2;

	// Organic smooth alpha falloff with edge_softness
	float alpha_falloff = smoothstep(0.0, edge_softness, flame_density);
	col.a = clamp((alpha_falloff * smoke_val + aura * 0.4 + ember_val * 0.7) * bounds_mask, 0.0, 1.0);

	COLOR = col;
}
