// Ground layer: makes the magenta Rift cracks baked into the map pulse and
// bloom (HDR), and gives the floor a faint drifting light.
shader_type canvas_item;

uniform float time = 0.0;
uniform vec3 crack_color = vec3(0.75, 0.25, 0.95);
uniform float crack_glow = 2.6;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(c.rgb, crack_color);
	float is_crack = 1.0 - smoothstep(0.05, 0.18, d);
	// slow travelling pulse across the map
	float pulse = 0.55 + 0.45 * sin(time * 2.2 + (UV.x + UV.y) * 60.0);
	c.rgb = mix(c.rgb, crack_color * crack_glow * pulse, is_crack);
	// drifting cloud light
	float cloud = sin(UV.x * 23.0 + time * 0.15) * sin(UV.y * 19.0 - time * 0.11);
	c.rgb *= 1.0 + cloud * 0.05;
	COLOR = c;
}
