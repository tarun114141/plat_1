shader_type canvas_item;

// Atmospheric Dark Fire UI Background Shader
uniform vec4 bg_color : source_color = vec4(0.06, 0.025, 0.02, 0.95);
uniform vec4 ember_color : source_color = vec4(1.0, 0.45, 0.12, 1.0);
uniform vec4 magma_color : source_color = vec4(0.35, 0.08, 0.03, 1.0);
uniform vec4 gold_color : source_color = vec4(1.0, 0.82, 0.35, 1.0);

uniform float ember_speed : hint_range(0.1, 5.0) = 0.6;
uniform float ember_density : hint_range(0.0, 5.0) = 1.6;
uniform float magma_intensity : hint_range(0.0, 2.0) = 0.55;
uniform float border_glow : hint_range(0.0, 2.0) = 0.7;

// Simple hash
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// 2D Noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM
float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.02;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec2 uv = UV;
	
	// Subtle swirling magma smoke in the dark background
	vec2 smoke_uv = uv * 3.0 + vec2(sin(TIME * 0.2 + uv.y * 2.0) * 0.15, -TIME * 0.12);
	float smoke = fbm(smoke_uv);
	
	vec4 col = bg_color;
	
	// Add gentle dark magma veins
	float magma = smoothstep(0.42, 0.78, smoke) * magma_intensity;
	col = mix(col, magma_color, magma * 0.7);
	
	// Drifting ember particles
	vec2 ember_uv1 = uv * vec2(12.0, 16.0) + vec2(sin(TIME * 0.8 + uv.y * 6.0) * 0.4, -TIME * ember_speed * 1.2);
	vec2 ember_uv2 = uv * vec2(18.0, 22.0) + vec2(cos(TIME * 0.6 + uv.y * 8.0) * 0.3, -TIME * ember_speed * 1.6 + 4.2);
	
	float e1 = smoothstep(0.82, 0.95, hash(floor(ember_uv1))) * (0.6 + 0.4 * sin(TIME * 4.0 + hash(floor(ember_uv1)) * 6.28));
	float e2 = smoothstep(0.85, 0.97, hash(floor(ember_uv2))) * (0.6 + 0.4 * cos(TIME * 3.5 + hash(floor(ember_uv2)) * 6.28));
	
	float embers = (e1 + e2) * ember_density;
	col.rgb += ember_color.rgb * embers * 0.85;
	col.rgb += gold_color.rgb * e2 * 0.4;
	
	// Border heat aura around the perimeter
	float dist_x = min(uv.x, 1.0 - uv.x) * 2.0;
	float dist_y = min(uv.y, 1.0 - uv.y) * 2.0;
	float edge_dist = min(dist_x, dist_y);
	float edge_aura = (1.0 - smoothstep(0.0, 0.25, edge_dist)) * border_glow;
	
	// Border heat pulsing
	float pulse = 0.9 + 0.1 * sin(TIME * 2.5);
	col.rgb += mix(magma_color.rgb, ember_color.rgb, 0.5) * edge_aura * 0.5 * pulse;
	
	COLOR = col;
}
