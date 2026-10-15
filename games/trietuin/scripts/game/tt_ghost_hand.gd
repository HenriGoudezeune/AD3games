class_name TtGhostHand
extends Control
## Spookhand (tutorial/hint): zweeft naar een schermpunt en tikt twee keer, met een ring.

var target := Vector2.ZERO
var pos := Vector2(1500, 1100)
var press := 0.0
var alpha := 0.0
var t := 0.0
var _tw: Tween
var _ring := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50


func tap(p: Vector2, times := 2) -> void:
	stop()
	target = p
	pos = p + Vector2(140, 160)
	alpha = 0.0
	_tw = create_tween()
	_tw.tween_property(self, "alpha", 1.0, 0.15)
	_tw.parallel().tween_property(self, "pos", p, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for k in times:
		_tw.tween_property(self, "press", 1.0, 0.12)
		_tw.tween_callback(func():
			_ring = 1.0
			create_tween().tween_property(self, "_ring", 0.0, 0.45))
		_tw.tween_property(self, "press", 0.0, 0.16)
		_tw.tween_interval(0.18)
	_tw.tween_interval(0.6)
	_tw.tween_property(self, "alpha", 0.0, 0.3)


func stop() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	alpha = 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if alpha <= 0.01:
		return
	if _ring > 0.0:
		draw_arc(target, 20 + 40 * (1.0 - _ring), 0, TAU, 40, Color(1, 1, 1, _ring * alpha), 4.0, true)
	var p := pos + Vector2(10, 18) * (1.0 - press * 0.5)
	var a := alpha * 0.92
	var col := Color(1, 1, 1, a)
	var sh := Color(0.1, 0.15, 0.2, 0.35 * alpha)
	# wijsvinger + hand (handschoen)
	var s := 1.0 - press * 0.12
	draw_set_transform(p, -0.35, Vector2(s, s))
	draw_style_box(TtPal.sb(sh, 12), Rect2(-9 + 4, -4 + 6, 18, 44))
	draw_style_box(TtPal.sb(sh, 22), Rect2(-22 + 4, 26 + 6, 52, 48))
	draw_style_box(TtPal.sb(col, 12), Rect2(-9, -4, 18, 44))
	draw_style_box(TtPal.sb(col, 22), Rect2(-22, 26, 52, 48))
	for k in 3:
		draw_style_box(TtPal.sb(col, 9), Rect2(10 + k * 0.0, 30 + k * 12, 26, 14))
	draw_arc(Vector2(0, 0), 9, PI, TAU, 10, Color(TtPal.INFO, a), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
