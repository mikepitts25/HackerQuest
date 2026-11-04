shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.08, 0.09, 0.12, 1.0);
varying vec2 world_xz;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	// Staggered pavers with subtle per-tile wear; no imported textures.
	vec2 p = world_xz * 1.6;
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float grout = smoothstep(0.008, 0.028, edge);
	float wear = hash(cell);
	float grain = hash(floor(world_xz * 180.0));
	float wet = smoothstep(0.65, 0.88, sin(world_xz.x * 0.7 + sin(world_xz.y * 0.9)) * 0.5 + 0.5);
	ALBEDO = base_color.rgb * mix(0.65, 1.0, grout) * (0.9 + wear * 0.20 + grain * 0.035);
	ROUGHNESS = mix(0.91, 0.32, wet);
	METALLIC = wet * 0.12;
}
