class_name TtStringView
extends Control
## De slinger (tekst van de suffixboom) bovenaan de tuin: één parel per teken met positienummer in de
## weergavebasis van het level ("telt vanaf 0/1"), (b,e)-markering, mist (4-4), eigenaarskleuren (4-5) en de
## σ-rij van Ukkonen (bladen-groep onderstreept, pijl op de huidige σ).

signal pearl_clicked(i: int)

var text := ""
var shown := -1              # Ukkonen: enkel parels 0..shown-1 zichtbaar (-1 = alles)
var pos_base := 0
var letters := "acgt_"
var season := 3
var hl_b := -1
var hl_e := -1
var cursor := -1
var mist := false
var clickable := false
var hover := -1
var picked: Array = []       # gekozen/foute parels: [{i, col}]
var owners: Array = []       # [{name, from, to, col}]
var sigmas: Array = []       # [{j, leaf, current}]
var it_i := 0
var t := 0.0
var _centers := PackedVector2Array()
var _reveal := {}            # i -> alpha van een parel die net bijkwam
var y0 := 112.0
var _mist_a := 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func gap() -> float:
	var n := maxi(text.length(), 1)
	return clampf(1560.0 / n, 48.0, 92.0)


func x_start() -> float:
	var n := maxi(text.length(), 1)
	return 960.0 - (n - 1) * gap() / 2.0 + 60.0


func pearl_pos(i: int) -> Vector2:
	if i >= 0 and i < _centers.size():
		return _centers[i]
	return Vector2(x_start() + i * gap(), y0 + 46)


func add_pearl_anim(i: int) -> void:
	_reveal[i] = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float): _reveal[i] = v, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree() or text == "":
		return
	if ev is InputEventMouseMotion:
		hover = _hit(get_local_mouse_position()) if clickable or mist else -1
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and clickable:
		var h := _hit(get_local_mouse_position())
		if h >= 0:
			pearl_clicked.emit(h)
			get_viewport().set_input_as_handled()


func _hit(p: Vector2) -> int:
	for i in _centers.size():
		if shown >= 0 and i >= shown:
			continue
		if _centers[i].distance_to(p) < 26.0 or Rect2(_centers[i] + Vector2(-20, 24), Vector2(40, 30)).has_point(p):
			return i
	return -1


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if text == "":
		return
	var se := TtPal.season(season)
	var panel := Rect2(16, 96, 1888, 150 if sigmas.is_empty() else 196)
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.78), 22, 10, Vector2(0, 6)), panel)
	# basisplaatje
	var plate := Rect2(32, 112, 110, 56)
	draw_style_box(TtPal.sb_thick(TtPal.PAPER, 12, 4, TtPal.PAPER_EDGE), plate)
	TtPal.text_c(self, TtPal.UI_BOLD, plate.get_center() + Vector2(0, -11), "telt vanaf", 16, TtPal.INK_SOFT)
	TtPal.text_c(self, TtPal.MONO, plate.get_center() + Vector2(0, 12), str(pos_base), 24, TtPal.INK)
	var disp := ""
	for i in text.length():
		var ch := text[i]
		disp += {"1": "₁", "2": "₂", "3": "₃"}.get(ch, ch)
	var vis := disp if shown < 0 else disp.substr(0, shown)
	if vis == "":
		vis = " "
	var g := gap()
	# eigenaarskleuren onder de parels
	_centers = TtDraw.garland(self, Vector2(x_start(), y0), vis, g, se, t, hl_b, hl_e, 10.0, letters, false, cursor)
	for o in owners:
		var a := pearl_pos(int(o.from))
		var b := pearl_pos(int(o.to))
		var col: Color = o.col
		draw_style_box(TtPal.sb(Color(col, 0.35), 12), Rect2(a.x - 26, a.y + 24, b.x - a.x + 52, 10))
		TtPal.text_c(self, TtPal.UI_BOLD, Vector2((a.x + b.x) / 2.0, a.y - 44), str(o.name), 18, col.lightened(0.3))
	# indices in de weergavebasis
	for i in _centers.size():
		var c := _centers[i]
		var lit := hl_b >= 0 and i >= hl_b and i <= hl_e
		var s := str(i + pos_base)
		var w := TtPal.MONO_B.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 12
		var ir := Rect2(c.x - w / 2.0, c.y + 26, w, 24)
		draw_style_box(TtPal.sb(TtPal.STAR if lit else Color(TtPal.PANEL_LO, 0.92), 8), ir)
		TtPal.text_c(self, TtPal.MONO_B, ir.get_center(), s, 18, TtPal.INK if lit else TtPal.TEXT)
		if _reveal.has(i) and _reveal[i] < 1.0:
			draw_circle(c, 30 * (1.0 - _reveal[i]) + 10, Color(TtPal.STAR, 0.5 * (1.0 - _reveal[i])), true, -1, true)
	# (b,e)-markering in de weergavebasis (over die van TtDraw.garland heen)
	if hl_b >= 0 and hl_e >= hl_b and hl_e < _centers.size():
		var yy := _centers[hl_b].y + 60
		var xa := _centers[hl_b].x - 14
		var xb := _centers[hl_e].x + 14
		TtDraw.be_tag(self, Vector2((xa + xb) / 2.0, yy + 18), hl_b + pos_base, hl_e + pos_base, true)
	for pk in picked:
		var pc := pearl_pos(int(pk.i))
		draw_arc(pc, 25, 0, TAU, 32, pk.col, 4.0, true)
	if clickable and hover >= 0:
		draw_arc(pearl_pos(hover), 26, 0, TAU, 32, TtPal.WARN, 4.0, true)
	if mist:
		_draw_mist()
	if not sigmas.is_empty():
		_draw_sigmas()


func _draw_mist() -> void:
	for i in _centers.size():
		var lit := hl_b >= 0 and i >= hl_b and i <= hl_e
		if lit:
			continue
		var c := _centers[i]
		var a := 0.9 + 0.06 * sin(t * 1.3 + i * 0.9)
		for k in 3:
			var off := Vector2(sin(t * 0.6 + i * 1.7 + k) * 8.0, cos(t * 0.5 + i + k * 2.0) * 5.0)
			draw_circle(c + off + Vector2(0, -2 + k * 6), 28.0 - k * 3, Color(0.86, 0.88, 0.93, a * (0.5 + 0.2 * k)), true, -1, true)
	TtPal.text_r(self, TtPal.UI_BOLD, Vector2(1890, 236), "mist: hover een (b,e)-bord om die parels te zien", 16, TtPal.TEXT_DIM)


func _draw_sigmas() -> void:
	var y := 262.0
	var n := sigmas.size()
	if n == 0:
		return
	var step := clampf(1500.0 / maxf(n, 1), 58.0, 96.0)
	var x0 := 960.0 - (n - 1) * step / 2.0
	TtPal.text_r(self, TtPal.UI_BOLD, Vector2(x0 - 46, y), "it = %d" % it_i, 22, TtPal.TEXT)
	var leaf_end := -1
	for k in n:
		if sigmas[k].get("leaf", false):
			leaf_end = k
	for k in n:
		var s: Dictionary = sigmas[k]
		var c := Vector2(x0 + k * step, y)
		var r := Rect2(c.x - 26, c.y - 18, 52, 36)
		var cur: bool = s.get("current", false)
		var col := TtPal.STAR if cur else (Color("#CFE3FF") if s.get("leaf", false) else TtPal.PAPER)
		draw_style_box(TtPal.sb_thick(col, 10, 3, col.darkened(0.25)), r)
		TtPal.text_c(self, TtPal.MONO, c + Vector2(-5, -1), "σ", 20, TtPal.INK)
		TtPal.text_c(self, TtPal.MONO_B, c + Vector2(10, 5), str(s.get("j", k + 1)), 14, TtPal.INK)
		if cur:
			var ay := c.y - 26 - 4 * sin(t * 6.0)
			TtDraw.fill(self, PackedVector2Array([Vector2(c.x - 9, ay - 10), Vector2(c.x + 9, ay - 10), Vector2(c.x, ay)]), TtPal.STAR)
	if leaf_end >= 0:
		var xa := x0 - 28
		var xb := x0 + leaf_end * step + 28
		draw_line(Vector2(xa, y + 24), Vector2(xb, y + 24), Color("#9CC4F2"), 3.0, true)
		TtPal.text_c(self, TtPal.UI_BOLD, Vector2((xa + xb) / 2.0, y + 36), "blad", 15, Color("#CFE3FF"))
