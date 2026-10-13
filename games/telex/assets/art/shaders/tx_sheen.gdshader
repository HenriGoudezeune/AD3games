shader_type canvas_item;
// TELEX — glansstreep over messing (typeplaatje bij een nieuwe machine, juice #37; ook medailles/sterren).
// Zet `progress` met een tween van 0 → 1 (0,6 s, TRANS_SINE). Werkt op elke TextureRect/Sprite2D/Control.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float width = 0.12;
uniform float strength = 0.55;
uniform float angle = 0.35;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float x = UV.x + UV.y * angle;
	float p = mix(-0.3, 1.3 + angle, progress);
	float s = 1.0 - smoothstep(0.0, width, abs(x - p));
	c.rgb += vec3(1.0, 0.95, 0.8) * s * strength * c.a;
	COLOR = c;
}
