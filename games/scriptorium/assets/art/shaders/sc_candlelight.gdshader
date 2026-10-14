shader_type canvas_item;
// Kortschrift: kaarslicht-overlay (design/ART.md §6.3). Op een ColorRect over de hele werkbank (onder de UI).
// Donkert de randen af (vignet) en laat een warme lichtpoel rond `light_pos` flakkeren. Normale blending.
uniform vec2 size_px = vec2(1920.0, 1080.0);
uniform vec2 light_pos = vec2(150.0, 120.0);   // kaars (px)
uniform float radius = 1100.0;                  // reikwijdte van het licht (px)
uniform float darkness : hint_range(0.0, 1.0) = 0.45;  // hoe donker het buiten de poel wordt
uniform vec4 warm : source_color = vec4(1.0, 0.70, 0.35, 1.0);
uniform float warmth : hint_range(0.0, 0.5) = 0.10;
uniform float flicker : hint_range(0.0, 0.2) = 0.05;

float n1(float x) { return fract(sin(x * 12.9898) * 43758.5453); }
float smooth_noise(float x) { float i = floor(x); float f = fract(x); return mix(n1(i), n1(i + 1.0), f * f * (3.0 - 2.0 * f)); }

void fragment() {
	vec2 p = UV * size_px;
	float fl = 1.0 + flicker * (smooth_noise(TIME * 7.0) - 0.5) * 2.0 + flicker * 0.5 * sin(TIME * 13.0);
	float d = length(p - light_pos) / (radius * fl);
	float lit = clamp(1.0 - d * d, 0.0, 1.0);
	vec2 q = UV - 0.5;
	float vig = smoothstep(0.35, 0.85, length(q * vec2(1.0, 1.25)));
	float dark_a = clamp(darkness * (1.0 - lit) * 0.85 + vig * darkness * 0.6, 0.0, 0.95);
	float warm_a = lit * warmth;
	float a = clamp(dark_a + warm_a, 0.0, 0.95);
	vec3 col = (vec3(0.05, 0.02, 0.01) * dark_a + warm.rgb * warm_a) / max(dark_a + warm_a, 0.001);
	COLOR = vec4(col, a);
}
