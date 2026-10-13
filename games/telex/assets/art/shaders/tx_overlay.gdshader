shader_type canvas_item;
// TELEX — schermoverlay (ART.md §3.3): vignet, filmkorrel en een heel trage, zachte lichtflikkering.
// Op een ColorRect (volledig scherm, mouse_filter = IGNORE) in een CanvasLayer boven de wereld, onder de UI.

uniform sampler2D grain_tex : repeat_enable, filter_nearest;
uniform float vignette = 0.55;     // 0 = uit
uniform float grain = 0.045;       // sterkte korrel
uniform float flicker = 0.015;     // lichtschommeling (0 = uit, respecteer "schermschok 0 %")
uniform vec4 tint : source_color = vec4(0.0, 0.02, 0.02, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = (uv - 0.5) * vec2(1.15, 1.0);
	float v = smoothstep(0.35, 0.95, length(d) * 1.25) * vignette;
	vec2 gu = UV * vec2(7.5, 4.2) + vec2(fract(TIME * 13.7), fract(TIME * 7.3));
	float g = texture(grain_tex, gu).r - 0.5;
	float f = flicker * (sin(TIME * 2.1) * 0.6 + sin(TIME * 5.3 + 1.7) * 0.4);
	float a = clamp(v + f, 0.0, 1.0);
	COLOR = vec4(tint.rgb + vec3(g * grain * 4.0), a + abs(g) * grain);
}
