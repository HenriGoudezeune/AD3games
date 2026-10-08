extends CanvasLayer
## Autoload "Transition": scène-overgang met een diagonale "rolluik"-veeg in veiligheidsstrepen.

var _rect: ColorRect
var _mat: ShaderMaterial
var busy := false

const SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;   // 0 = open, 1 = dicht
uniform float dir = 1.0;        // 1 = van links, -1 = van rechts
uniform vec4 c_deep : source_color;
uniform vec4 c_stripe : source_color;
void fragment() {
	vec2 px = UV * vec2(1920.0, 1080.0);
	float x = dir > 0.0 ? UV.x : 1.0 - UV.x;
	float edge = x * 0.82 + (1.0 - UV.y) * 0.18;
	float p = progress * 1.25;
	float cover = step(edge, p);
	float band = smoothstep(p - 0.06, p - 0.055, edge) * cover;
	float stripes = step(0.5, fract((px.x + px.y) / 56.0));
	vec3 col = c_deep.rgb;
	col = mix(col, mix(c_deep.rgb * 1.4, c_stripe.rgb, stripes), band);
	COLOR = vec4(col, cover);
}
"""


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("c_deep", Pal.BG_DEEP)
	_mat.set_shader_parameter("c_stripe", Pal.WARN)
	_mat.set_shader_parameter("progress", 0.0)
	_rect.material = _mat
	add_child(_rect)


func goto(path: String) -> void:
	if busy:
		return
	busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	Sfx.play("sfx/ui_whoosh.wav", -4.0)
	_mat.set_shader_parameter("dir", 1.0)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_method(_set_p, 0.0, 1.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_mat.set_shader_parameter("dir", -1.0)
	var tw2 := create_tween().set_ignore_time_scale(true)
	tw2.tween_method(_set_p, 1.0, 0.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func _set_p(v: float) -> void:
	_mat.set_shader_parameter("progress", v)
