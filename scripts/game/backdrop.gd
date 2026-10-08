class_name Backdrop
extends ColorRect
## Vloer met tegelraster + vignet (ART.md §2.1), gedeeld door menu-schermen.

const SHADER := """
shader_type canvas_item;
uniform vec4 c_bg : source_color;
uniform vec4 c_deep : source_color;
uniform vec4 c_line : source_color;
uniform float scroll = 0.0;
void fragment() {
	vec2 px = UV * vec2(1920.0, 1080.0) + vec2(scroll, scroll * 0.35);
	vec2 g = abs(fract(px / 64.0) - 0.5);
	float line = 1.0 - smoothstep(0.475, 0.49, max(g.x, g.y));
	vec3 col = mix(c_bg.rgb, c_line.rgb, (1.0 - line) * 0.9);
	vec2 q = UV - vec2(0.5, 0.55);
	float v = smoothstep(0.35, 0.95, length(q * vec2(1.0, 1.25)));
	col = mix(col, c_deep.rgb, v * 0.85);
	COLOR = vec4(col, 1.0);
}
"""

var speed := 12.0
var _mat: ShaderMaterial
var _s := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("c_bg", Pal.BG)
	_mat.set_shader_parameter("c_deep", Pal.BG_DEEP)
	_mat.set_shader_parameter("c_line", Pal.FLOOR_LINE)
	material = _mat


func _process(d: float) -> void:
	_s += d * speed
	_mat.set_shader_parameter("scroll", _s)
