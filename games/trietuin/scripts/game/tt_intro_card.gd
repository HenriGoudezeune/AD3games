class_name TtIntroCard
extends Control
## Levelintro (GDD §4.2): papieren titelkaart met seizoen, levelnaam, notasverwijzing en één zin van de Uil.
## Klik/toets/≤ 6 s -> verder.

signal finished

var season_name := ""
var level := ""
var title := ""
var ref := ""
var line := ""
var se: Dictionary = {}
var t := 0.0
var _a := 0.0
var _y := -60.0
var _done := false


func setup(season_name_: String, level_: String, title_: String, ref_: String, line_: String, se_: Dictionary) -> void:
	season_name = season_name_
	level = level_
	title = title_
	ref = ref_
	line = line_
	se = se_


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_a", 1.0, 0.3)
	tw.tween_property(self, "_y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	TtSnd.play("season_change", -6.0)
	get_tree().create_timer(5.5).timeout.connect(_close)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_close()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_a", 0.0, 0.3)
	tw.tween_property(self, "_y", -40.0, 0.3)
	tw.chain().tween_callback(func():
		finished.emit()
		queue_free())


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.03, 0.06, 0.04, 0.45 * _a))
	var r := Rect2(560, 300 + _y, 800, 420)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var col := Color(1, 1, 1, _a)
	draw_style_box(TtPal.sb(Color(0, 0, 0, 0.25 * _a), 30, 24, Vector2(0, 14)), r)
	draw_style_box(TtPal.sb_thick(Color(TtPal.PAPER, _a), 30, 10, Color(TtPal.PAPER_EDGE, _a)), r)
	var band := Rect2(r.position, Vector2(r.size.x, 96))
	var lc: Color = se.get("leaf", [TtPal.BRAND])[0]
	draw_style_box(TtPal.sb(Color(lc, _a), 30), band)
	draw_rect(Rect2(band.position.x, band.end.y - 30, band.size.x, 30), Color(lc, _a))
	for k in 9:
		TtDraw.leaf(self, Vector2(r.position.x + 40 + k * 92, band.end.y + 2), -PI / 2 + sin(t * 1.5 + k) * 0.1 + (0.5 if k % 2 == 0 else -0.5), 26, Color(lc.darkened(0.15), _a), false)
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(r.position.x + 40, band.get_center().y), season_name.to_upper(), 40, Color(Color.WHITE, _a))
	TtPal.text_r(self, TtPal.MONO, Vector2(r.end.x - 40, band.get_center().y), level, 44, Color(Color.WHITE, _a))
	TtPal.text_c(self, TtPal.UI_BOLD, Vector2(r.get_center().x, r.position.y + 170), title, 52, Color(TtPal.INK, _a))
	TtPal.text_c(self, TtPal.UI, Vector2(r.get_center().x, r.position.y + 232), ref, 26, Color(TtPal.INK_SOFT, _a))
	if line != "":
		var lr := Rect2(r.position.x + 60, r.position.y + 280, r.size.x - 120, 76)
		draw_style_box(TtPal.sb(Color(TtPal.PAPER_EDGE, 0.5 * _a), 18), lr)
		TtPal.text_c(self, TtPal.UI_BOLD, lr.get_center(), "Uil: “%s”" % line, 25, Color(TtPal.INK, _a))
	var blink := 0.5 + 0.5 * sin(t * 4.0)
	TtPal.text_c(self, TtPal.UI, Vector2(r.get_center().x, r.end.y + 40), "klik of druk een toets", 22, Color(TtPal.TEXT, _a * (0.5 + 0.5 * blink)))
