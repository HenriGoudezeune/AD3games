shader_type canvas_item;
// Trietuin: winterse mist (GDD §7.1 #29, level 4-4). Zet op een ColorRect boven de slinger.
// `hole_px` = muispositie in lokale pixels van de ColorRect; de mist wijkt daar (radius `hole_radius`).
// `size_px` = grootte van de ColorRect (zet vanuit code). Animatie loopt via TIME.

uniform vec4 mist_color : source_color = vec4(0.91, 0.94, 1.0, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.85;
uniform vec2 size_px = vec2(800.0, 200.0);
uniform vec2 hole_px = vec2(-1000.0, -1000.0);
uniform float hole_radius = 90.0;
uniform float drift = 0.04;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 5; k++) { v += a * vnoise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 px = UV * size_px;
	vec2 q = px / 180.0 + vec2(TIME * drift, TIME * drift * 0.3);
	float n = fbm(q + fbm(q * 0.7 + TIME * 0.02));
	float a = smoothstep(0.25, 0.75, n) * density;
	// zachte randen rondom
	a *= smoothstep(0.0, 0.2, UV.y) * smoothstep(1.0, 0.8, UV.y);
	a *= smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.85, UV.x);
	// gat rond de muis
	float d = length(px - hole_px);
	a *= smoothstep(hole_radius * 0.55, hole_radius, d);
	COLOR = vec4(mist_color.rgb, a * mist_color.a);
}
