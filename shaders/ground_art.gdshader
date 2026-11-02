// Painted ground (GroundArt): a colour grade that softens PixelLab's bright greens towards the mockup's muted,
// warm palette, plus large slow light/shade patches in world space so the tiled grass does not look flat.
shader_type canvas_item;

uniform float saturation = 0.78;
uniform float brightness = 0.92;
uniform vec3 warm = vec3(1.04, 1.0, 0.9);
uniform float patch_amount = 0.10;

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec4 c = COLOR; // already texture x modulate in Godot 4
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(l), c.rgb, saturation) * brightness * warm;
	// whole art pixels (0.5 world px) share one value, so the shading stays blocky like the art
	vec2 p = floor(wpos * 2.0) / 2.0;
	float n = noise(p / 90.0) * 0.65 + noise(p / 31.0) * 0.35;
	c.rgb *= 1.0 + (n - 0.5) * 2.0 * patch_amount;
	COLOR = c;
}
