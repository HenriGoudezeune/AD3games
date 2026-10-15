shader_type canvas_item;
// Kortschrift: inkt vloeit in (juice #1, codeboek ontrollen, brief schrijven). Op een Sprite2D/TextureRect/Label.
// `progress` 0 -> 1 onthult van links naar rechts met een rafelige, natte rand.
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float edge = 0.06;
uniform vec4 wet : source_color = vec4(0.17, 0.11, 0.08, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float n = noise(UV * vec2(18.0, 6.0)) * 0.8 + noise(UV * 60.0) * 0.2;
	float x = UV.x + (n - 0.5) * edge * 2.0;
	float p = progress * (1.0 + edge * 2.0) - edge;
	float m = smoothstep(p + edge * 0.5, p - edge * 0.5, x);
	float rim = smoothstep(p - edge, p, x) * m;
	c.rgb = mix(c.rgb, wet.rgb, rim * 0.6);
	c.a *= m;
	COLOR = c;
}
