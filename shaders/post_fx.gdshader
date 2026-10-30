// Full-screen post effects: up to 4 shockwave distortions, chromatic
// aberration, damage vignette and a subtle Rift colour grade.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 waves[4];          // xy = centre (UV), z = radius (UV, aspect-corrected), w = strength
uniform float aspect = 1.7778;  // width / height
uniform float chroma = 0.0;     // 0..1 chromatic aberration
uniform float vignette = 0.0;   // 0..1 red damage vignette
uniform float danger = 0.0;     // 0..1 low-HP pulse
uniform float grade = 1.0;      // 0..1 Rift colour grade amount
uniform float time = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = vec2(0.0);
	for (int i = 0; i < 4; i++) {
		vec4 w = waves[i];
		if (w.w <= 0.0) { continue; }
		vec2 d = uv - w.xy;
		d.x *= aspect;
		float dist = length(d);
		float band = 0.035;
		float x = (dist - w.z) / band;
		float ring = exp(-x * x * 2.5);  // gaussian band around the wave front
		if (dist > 0.0001) {
			vec2 dir = d / dist;
			dir.x /= aspect;
			offset -= dir * ring * w.w * 0.025;
		}
	}
	uv += offset;
	vec2 from_c = uv - vec2(0.5);
	float edge = dot(from_c, from_c);
	float ca = chroma * 0.006 + edge * chroma * 0.01;
	vec3 col;
	col.r = texture(screen_tex, uv + from_c * ca).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - from_c * ca).b;

	// Rift grade: cool shadows, slightly warm highlights
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(col * vec3(0.92, 0.95, 1.08), col * vec3(1.04, 1.0, 0.94), smoothstep(0.35, 0.9, lum));
	col = mix(col, graded, grade);

	// vignettes
	float v = smoothstep(0.18, 0.62, edge * 1.6);
	col *= 1.0 - v * 0.35;
	float hurt = max(vignette, danger * (0.55 + 0.45 * sin(time * 6.0)));
	col = mix(col, vec3(0.75, 0.02, 0.08), v * hurt * 0.7);
	COLOR = vec4(col, 1.0);
}
