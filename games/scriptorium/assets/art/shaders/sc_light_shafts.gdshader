shader_type canvas_item;
render_mode blend_add;
// Kortschrift: lichtbundels van het glas-in-loodraam met zwevend stof (titel, kaart, voorlezing).
// Op een ColorRect; `origin` = het raam (UV), `dir` = richting van de bundels. Additief, dus zacht houden.
uniform vec2 origin = vec2(0.5, 0.05);
uniform vec2 dir = vec2(-0.45, 1.0);
uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.18;
uniform float aspect = 1.7778;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec2 d = normalize(dir * vec2(1.0, aspect));
	vec2 rel = (uv - origin) * vec2(aspect, 1.0);
	float along = dot(rel, d);
	float across = dot(rel, vec2(-d.y, d.x));
	float beams = 0.5 + 0.5 * sin(across * 38.0 + 1.3) * sin(across * 17.0 + TIME * 0.15);
	float cone = smoothstep(0.42, 0.0, abs(across) - along * 0.18) * smoothstep(0.0, 0.15, along) * smoothstep(1.4, 0.4, along);
	// stofjes
	vec2 g = uv * vec2(aspect, 1.0) * 60.0 + vec2(TIME * 0.6, TIME * 0.9);
	vec2 cell = floor(g);
	float h = hash(cell);
	vec2 f = fract(g) - vec2(hash(cell + 3.1), hash(cell + 7.7));
	float mote = step(0.965, h) * smoothstep(0.08, 0.0, length(f)) * (0.5 + 0.5 * sin(TIME * 2.0 + h * 40.0));
	float v = cone * (beams * strength + mote * 0.8);
	COLOR = vec4(tint.rgb * v, v);
}
