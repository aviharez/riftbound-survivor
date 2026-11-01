shader_type canvas_item;
// Academy menu background: deep navy night with a slow purple / cyan Rift nebula and twinkling stars.

uniform vec4 top_color : source_color = vec4(0.03, 0.04, 0.12, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.06, 0.07, 0.18, 1.0);
uniform vec4 rift_color : source_color = vec4(0.45, 0.18, 0.75, 1.0);
uniform vec4 glow_color : source_color = vec4(0.15, 0.55, 0.85, 1.0);
uniform vec2 rift_center = vec2(0.72, 0.42);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float aspect = 1.0 / max(SCREEN_PIXEL_SIZE.x, 0.0001) * SCREEN_PIXEL_SIZE.y;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, uv.y);
	vec2 q = (uv - rift_center) * vec2(aspect, 1.0);
	float d = length(q * vec2(1.0, 1.6));
	float swirl = fbm(vec2(atan(q.y, q.x) * 1.5 + TIME * 0.03, d * 4.0 - TIME * 0.05) + uv * 2.0);
	float neb = smoothstep(0.55, 0.0, d) * (0.35 + 0.65 * swirl);
	col += rift_color.rgb * neb * 0.55;
	col += glow_color.rgb * smoothstep(0.25, 0.0, d) * 0.25 * swirl;
	vec2 sp = uv * vec2(160.0, 90.0);
	float s = hash(floor(sp));
	float star = step(0.985, s) * (0.5 + 0.5 * sin(TIME * (1.0 + s * 3.0) + s * 40.0));
	col += vec3(0.8, 0.9, 1.0) * star * 0.6 * (1.0 - uv.y * 0.6);
	COLOR = vec4(col, 1.0);
}
