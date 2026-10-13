class_name TtAsciiStorm
extends Control
## ASCII-storm (GDD 3-1, juice #25): de wind draait, de gewone geestboom (Figuur 16 boven, 4 toppen) blaast elke
## knoppenkrans op tot een waaier van 256 knoppen (4 × 256 = 1024 sap); de sapbuis loopt over en barst; de
## rankboom blijft 24. Notas p. 31–32: "terwijl de ternary trie niet zou veranderen."

signal finished

var t := 0.0
var k := 0.0          # 0..1 opblazen
var _a := 0.0
var rank_sap := 24
var _burst := 0.0
var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TtSnd.play("storm", 0.0)
	var tw := create_tween()
	tw.tween_property(self, "_a", 1.0, 0.4)
	tw.tween_interval(0.6)
	tw.tween_property(self, "k", 1.0, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_burst = 1.0
		TtSnd.play("clonk", 0.0, 0.6)
		Juice.shake(8.0, 0.4)
		TtFx.burst(self, Vector2(560, 220), "drop", 30, 1.2, 200, 600, Color.WHITE, 900, 0.3, 0.6, false, Vector2.UP, 160, [TtPal.SAP, TtPal.SAP_LIGHT]))
	tw.tween_property(self, "_burst", 0.0, 0.8)
	tw.tween_interval(2.6)
	tw.tween_callback(_close)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and k >= 1.0:
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "_a", 0.0, 0.4)
	tw.tween_callback(func():
		finished.emit()
		queue_free())


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.1, 0.12, 0.2, 0.55 * _a))
	# windstrepen
	for i in 14:
		var y := 120.0 + i * 64.0
		var x := fmod(t * (900.0 + i * 40.0) + i * 300.0, 2400.0) - 300.0
		draw_line(Vector2(x, y), Vector2(x + 220, y - 20), Color(1, 1, 1, 0.25 * _a), 3.0, true)
	var se := TtPal.season(2)
	# geestboom (gewone trie, Figuur 16 boven)
	var base := Vector2(560, 860)
	var nodes := [Vector2(560, 720), Vector2(360, 520), Vector2(560, 470), Vector2(760, 520)]
	var n_buds := int(lerpf(5.0, 256.0, k))
	for i in range(1, 4):
		draw_line(nodes[0], nodes[i], Color(TtPal.BARK, 0.7 * _a), 10.0, true)
	draw_line(base, nodes[0], Color(TtPal.BARK, 0.7 * _a), 18.0, true)
	for c in nodes:
		_fan(c, n_buds)
	var sap := 4 * n_buds
	TtPal.text_outline_c(self, TtPal.UI_BOLD, Vector2(560, 300), "gewone trie: %d sap" % sap, 40, Color(TtPal.ERR.lerp(TtPal.TEXT, 0.3), _a), 8, TtPal.OUTLINE)
	TtPal.text_outline_c(self, TtPal.UI, Vector2(560, 350), "%d knoppen per top" % n_buds, 28, Color(TtPal.TEXT, _a), 6, TtPal.OUTLINE)
	# sapbuis die overloopt
	var tube := Rect2(360, 200, 400, 30)
	var frac := clampf(1.0 - sap / 400.0, 0.0, 1.0)
	TtDraw.sap_meter(self, tube, frac if _burst <= 0.0 else 0.0, t)
	if _burst > 0.0:
		TtPal.text_outline_c(self, TtPal.UI_BOLD, tube.get_center() + Vector2(0, -50), "KRAK!", 48, Color(TtPal.WARN, _burst), 8, TtPal.OUTLINE)
	# rankboom blijft rustig
	var r := Rect2(1180, 380, 560, 260)
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.9 * _a), 26), r)
	TtDraw.rank_knot(self, r.position + Vector2(140, 150), "G", t, [true, true, true], 30.0, "ACGT_")
	for j in 5:
		var sp := r.position + Vector2(140 + cos(t + j) * 70, 150 + sin(t * 1.3 + j) * 50)
		draw_circle(sp, 3, Color(1, 1, 0.8, 0.6 * _a), true, -1, true)
	TtPal.text_l(self, TtPal.UI_BOLD, r.position + Vector2(240, 110), "rankboom: %d sap" % rank_sap, 36, Color(TtPal.OK, _a))
	TtPal.text_l(self, TtPal.UI, r.position + Vector2(240, 160), "enkel gebruikte letters", 24, Color(TtPal.TEXT, _a))
	TtPal.text_l(self, TtPal.UI, r.position + Vector2(240, 196), "notas p. 31–32", 22, Color(TtPal.TEXT_DIM, _a))
	TtPal.text_outline_c(self, TtPal.UI_BOLD, Vector2(960, 120), "Wat als het alfabet alle 256 tekens telt?", 40, Color(TtPal.TEXT, _a), 8, TtPal.OUTLINE)


func _fan(c: Vector2, n: int) -> void:
	var shown := mini(n, 120)
	var rad := 40.0 + 80.0 * k
	draw_circle(c, 22, Color(TtPal.KNOT, _a), true, -1, true)
	for i in shown:
		var a := PI + PI * (i + 0.5) / shown
		var p := c + Vector2(cos(a), sin(a)) * rad
		draw_circle(p, 4.0 if n > 40 else 7.0, Color(TtPal.BUD_EMPTY, _a), true, -1, true)
	if n > 20:
		var lab := "%d" % n
		var r := Rect2(c + Vector2(-34, 22), Vector2(68, 30))
		draw_style_box(TtPal.sb(Color(TtPal.PAPER, _a), 10), r)
		TtPal.text_c(self, TtPal.MONO, r.get_center(), lab, 20, Color(TtPal.INK, _a))
