class_name TtOwl
extends Control
## De Uil (coach): zit rechts boven de werkbank en zegt hoogstens één korte zin (tekstballon). Klik op de uil =
## hint (F2). `say(text)` toont de ballon; die verdwijnt na een tijd of bij de volgende zin.

signal clicked

var text := ""
var parts: Array = []        # rich_line-onderdelen (wint van text)
var letters := "ACGT_"
var t := 0.0
var _a := 0.0
var _blink := 0.0
var _hop := 0.0
var _gen := 0
var anchor := Vector2(1838, 800)
var enabled_hint := true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func say(s: String, dur := 4.5, rich: Array = []) -> void:
	text = s
	parts = rich
	_gen += 1
	var g := _gen
	_hop = 1.0
	create_tween().tween_property(self, "_hop", 0.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(self, "_a", 1.0, 0.18)
	TtSnd.play("owl", -8.0)
	if dur > 0.0:
		await get_tree().create_timer(dur).timeout
		if g == _gen:
			hide_bubble()


func hide_bubble() -> void:
	create_tween().tween_property(self, "_a", 0.0, 0.25)


func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and is_visible_in_tree():
		if get_local_mouse_position().distance_to(anchor + Vector2(0, -6)) < 46.0 and enabled_hint:
			clicked.emit()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	t += delta
	_blink -= delta
	if _blink < -3.2:
		_blink = 0.12
	queue_redraw()


func _draw() -> void:
	var c := anchor + Vector2(0, -6 - sin(_hop * PI) * 18.0)
	_draw_owl(c)
	if _a > 0.01 and (text != "" or not parts.is_empty()):
		var fs := 24
		var w := 0.0
		if not parts.is_empty():
			w = TtPal.rich_line(self, Vector2.ZERO, parts, fs, TtPal.INK, true, letters, true)
		else:
			w = TtPal.UI_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r := Rect2(anchor.x - 70 - w - 40, anchor.y - 150, w + 40, 58)
		r.position.x = maxf(r.position.x, 40)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var col := Color(TtPal.PAPER, _a)
		TtDraw.bubble(self, r, anchor + Vector2(-40, -70), col)
		if not parts.is_empty():
			TtPal.rich_line(self, Vector2(r.position.x + 20, r.get_center().y - 2), parts, fs, Color(TtPal.INK, _a), true, letters)
		else:
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(r.position.x + 20, r.get_center().y - 2), text, fs, Color(TtPal.INK, _a))


func _draw_owl(c: Vector2) -> void:
	# tak waarop hij zit
	draw_line(c + Vector2(-70, 46), c + Vector2(60, 42), TtPal.BARK_DARK, 10.0, true)
	draw_line(c + Vector2(-70, 44), c + Vector2(60, 40), TtPal.BARK, 6.0, true)
	TtDraw.leaf(self, c + Vector2(-58, 44), -2.6, 22, TtPal.BRAND)
	TtDraw.owl(self, c, 1.0, t, _a * (0.5 + 0.5 * sin(t * 14.0)) if _hop > 0.0 else 0.0, true)
	if enabled_hint:
		var hr := Rect2(c.x - 26, c.y + 46, 52, 22)
		draw_style_box(TtPal.sb(Color(TtPal.PANEL_LO, 0.85), 10), hr)
		TtPal.text_c(self, TtPal.MONO_B, hr.get_center(), "F2", 15, TtPal.TEXT)
