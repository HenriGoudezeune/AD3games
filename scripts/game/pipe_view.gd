class_name PipeView
extends Node
## Eén buis (= één pointer) van luik naar rek. Drie Line2D's in drie gedeelde lagen (rand / body / glans),
## zodat buizen die samenkomen in een verzamelbuis naadloos versmelten. Plus een gloei-lijn (add).

var idx := 0
var p_start := Vector2.ZERO:
	set(v):
		p_start = v
		_dirty = true
var p_end := Vector2.ZERO:
	set(v):
		p_end = v
		_dirty = true
var mid_x := 700.0:
	set(v):
		mid_x = v
		_dirty = true
var col := Color.WHITE:
	set(v):
		col = v
		_dirty = true
var width := 24.0:
	set(v):
		width = v
		_dirty = true
var lit := 0.0:
	set(v):
		lit = v
		_dirty = true
var alpha := 1.0:
	set(v):
		alpha = v
		_dirty = true

var points := PackedVector2Array()
var _l_out: Line2D
var _l_body: Line2D
var _l_shine: Line2D
var _l_glow: Line2D
var _dirty := true


func attach(out_layer: Node2D, body_layer: Node2D, shine_layer: Node2D, glow_layer: Node2D) -> void:
	_l_out = _mk(out_layer)
	_l_body = _mk(body_layer)
	_l_shine = _mk(shine_layer)
	_l_glow = _mk(glow_layer)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_l_glow.material = m
	rebuild()


func _mk(layer: Node2D) -> Line2D:
	var l := Line2D.new()
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_NONE
	l.antialiased = true
	layer.add_child(l)
	return l


func _exit_tree() -> void:
	for l in [_l_out, _l_body, _l_shine, _l_glow]:
		if is_instance_valid(l):
			l.queue_free()


func _process(_d: float) -> void:
	if _dirty:
		rebuild()


func rebuild() -> void:
	_dirty = false
	if _l_out == null:
		return
	var pts := PackedVector2Array()
	if absf(p_start.y - p_end.y) < 1.0:
		pts = PackedVector2Array([p_start, p_end])
	else:
		var mx := clampf(mid_x, p_start.x + 10, p_end.x - 10)
		pts = PackedVector2Array([p_start, Vector2(mx, p_start.y), Vector2(mx, p_end.y), p_end])
		var r := minf(40.0, absf(p_end.y - p_start.y) * 0.5)
		pts = Pal.fillet(pts, r)
	points = pts
	_l_out.points = pts
	_l_out.width = width + 10.0 * clampf(width / 24.0, 0.5, 1.0)
	_l_out.default_color = Color(Pal.OUTLINE, alpha)
	_l_body.points = pts
	_l_body.width = width
	_l_body.default_color = Color(col.darkened(0.12), alpha)
	var sp := PackedVector2Array()
	var off := -width * 0.2
	for p in pts:
		sp.append(p + Vector2(0, off))
	_l_shine.points = sp
	_l_shine.width = maxf(2.0, width * 0.25)
	_l_shine.default_color = Color(col.lightened(0.45), 0.9 * alpha)
	_l_glow.points = pts
	_l_glow.width = width * 1.1
	_l_glow.default_color = Color(col.lightened(0.5), 0.75 * lit * alpha)
	_l_glow.visible = lit > 0.01


func point_at(f: float) -> Vector2:
	return Pal.path_point(points, f)


func length() -> float:
	return Pal.path_length(points)
