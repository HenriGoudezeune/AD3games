class_name TtNotesView
extends Control
## Notas-weergave (GDD §6.5 punt 7): de boom getekend zoals de figuren in de lesnotas — wortel boven,
## gewone trie-toppen als rij vakjes `A C G T _` (pointer uit elk niet-leeg vakje), Patricia met een skip-vak,
## ternary als cirkels met drie pointers, suffixboom met (b,e)-labels in de weergavebasis. Bladeren = kaders met
## het label. Schaalt zichzelf in `rect`.

var rn: Array = []
var kind := 0
var letters := "ACGT_"
var pos_base := 0
var text := ""
var title := ""
var rect := Rect2(0, 0, 800, 500)
var _pos := {}
var _by := {}
var _s := 1.0
var _off := Vector2.ZERO
var _cell := 30.0


func setup(nodes: Array, kind_: int, letters_: String, pos_base_ := 0, text_ := "", title_ := "") -> void:
	rn = nodes
	kind = kind_
	letters = letters_
	pos_base = pos_base_
	text = text_
	title = title_
	_layout()
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout() -> void:
	_by.clear()
	for d in rn:
		_by[int(d.id)] = d
	var L := TtViewLayout.compute(rn, kind, letters, {"label_size": 22, "patricia": kind == TtCodes.Kind.PATRICIA, "edge_chars": {}, "strings": false})
	var P: Dictionary = L.get("pos", {})
	_pos.clear()
	if P.is_empty():
		return
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for id in P:
		var p: Vector2 = P[id]
		p.y = -p.y   # wortel boven
		_pos[id] = p
		mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
		mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
	var pad := Vector2(140, 120)
	var w := (mx - mn) + pad * 2.0
	var inner := Rect2(rect.position + Vector2(0, 40), rect.size - Vector2(0, 40))
	_s = minf(1.0, minf(inner.size.x / maxf(w.x, 1.0), inner.size.y / maxf(w.y, 1.0)))
	# de lay-out kent wereldmaten (knoppenkrans 220 px); in de figuurstijl zijn toppen smaller: rek verticaal wat op
	_s = maxf(_s, 0.25)
	_off = inner.get_center() - ((mn + mx) / 2.0) * _s


func _p(id: int) -> Vector2:
	return _pos.get(id, Vector2.ZERO) * _s + _off


func _draw() -> void:
	draw_style_box(TtPal.sb(Color("#FFFDF7"), 16), rect)
	TtPal.ring(self, rect, 16, TtPal.PAPER_EDGE, 2)
	if title != "":
		TtPal.text_l(self, TtPal.UI_BOLD, rect.position + Vector2(18, 24), title, 22, TtPal.INK)
	var ink := Color("#2B2B2B")
	var fs := 18 if _s >= 0.4 else 15
	_cell = 26.0 if _s >= 0.4 else 20.0
	match kind:
		TtCodes.Kind.TERNARY:
			_draw_ternary(ink, fs)
		TtCodes.Kind.SUFFIX, TtCodes.Kind.UKKONEN:
			_draw_suffix(ink, fs)
		_:
			_draw_trie(ink, fs)


func _draw_trie(ink: Color, fs: int) -> void:
	var n := letters.length()
	var pat := kind == TtCodes.Kind.PATRICIA
	for id in _by:
		var d: Dictionary = _by[id]
		if int(d.type) != TtNode.Type.INNER:
			continue
		var c := _p(id)
		var w := n * _cell + (_cell * 1.2 if pat else 0.0)
		var x0 := c.x - w / 2.0
		var r := Rect2(x0, c.y - _cell / 2.0, w, _cell)
		draw_rect(r, Color.WHITE)
		draw_rect(r, ink, false, 1.5)
		var kids: Dictionary = d.get("kids", {})
		var cx := x0
		if pat:
			var sr := Rect2(x0, r.position.y, _cell * 1.2, _cell)
			draw_rect(sr, Color("#F3EBD6"))
			draw_rect(sr, ink, false, 1.5)
			TtPal.text_c(self, TtPal.MONO_B, sr.get_center(), str(int(d.get("skip", 0))), fs, ink)
			cx += _cell * 1.2
		for i in n:
			var cr := Rect2(cx + i * _cell, r.position.y, _cell, _cell)
			draw_line(Vector2(cr.position.x, cr.position.y), Vector2(cr.position.x, cr.end.y), ink, 1.0)
			TtPal.text_c(self, TtPal.MONO_M, Vector2(cr.get_center().x, r.position.y - fs * 0.7), letters[i], int(fs * 0.8), Color(ink, 0.6))
			if kids.has(letters[i]):
				var kid := int(kids[letters[i]])
				draw_circle(cr.get_center(), 3.0, ink, true, -1, true)
				var target := _p(kid) + Vector2(0, -_cell / 2.0 - 2)
				if int(_by.get(kid, {}).get("type", 0)) == TtNode.Type.LEAF:
					target = _p(kid) + Vector2(0, -14)
				_arrow(cr.get_center(), target, ink)
	for id in _by:
		var d: Dictionary = _by[id]
		if int(d.type) == TtNode.Type.LEAF:
			_leaf_box(_p(id), str(d.get("label", "")), ink, fs)


func _leaf_box(c: Vector2, s: String, ink: Color, fs: int) -> void:
	var w := TtPal.MONO_B.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16
	var r := Rect2(c.x - w / 2.0, c.y - 14, w, fs * 1.5)
	draw_style_box(TtPal.sb(Color("#EEF6E8"), 8), r)
	TtPal.ring(self, r, 8, ink, 1)
	TtPal.text_c(self, TtPal.MONO_B, r.get_center(), s, fs, ink)


func _arrow(a: Vector2, b: Vector2, ink: Color) -> void:
	draw_line(a, b, ink, 1.4, true)
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([b, b - d * 9 + n * 4, b - d * 9 - n * 4]), ink)


func _draw_ternary(ink: Color, fs: int) -> void:
	for id in _by:
		var d: Dictionary = _by[id]
		if int(d.type) != TtNode.Type.BALL:
			continue
		var c := _p(id)
		var r := _cell * 0.7
		for k in [["lo", -1.0], ["eq", 0.0], ["hi", 1.0]]:
			var kid := int(d.get(k[0], -1))
			if kid < 0 or not _by.has(kid):
				continue
			var tgt := _p(kid)
			if int(_by[kid].type) == TtNode.Type.PACK:
				var br := int(_by[kid].get("ball_root", -1))
				tgt = _p(br) if br >= 0 else tgt
			_arrow(c + Vector2(k[1] * r * 0.7, r * 0.7), tgt + Vector2(0, -r if int(_by[kid].type) != TtNode.Type.LEAF else -14), ink)
		draw_circle(c, r, Color.WHITE, true, -1, true)
		draw_arc(c, r, 0, TAU, 28, ink, 1.5, true)
		TtPal.text_c(self, TtPal.MONO_B, c, str(d.get("ch", "")), fs, ink)
	for id in _by:
		var d: Dictionary = _by[id]
		if int(d.type) == TtNode.Type.LEAF:
			_leaf_box(_p(id), str(d.get("label", "")), ink, fs)


func _draw_suffix(ink: Color, fs: int) -> void:
	for id in _by:
		var d: Dictionary = _by[id]
		var par := int(d.get("parent", -1))
		if par < 0 or not _by.has(par):
			continue
		var a := _p(par)
		var b := _p(id)
		draw_line(a, b, ink, 1.4, true)
		var e := int(d.get("e", 0))
		var lab := "%d,%s" % [int(d.get("b", 0)) + pos_base, "it" if e == TtCodes.OPEN else str(e + pos_base)]
		var m := (a + b) / 2.0
		var w := TtPal.MONO_B.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8
		draw_rect(Rect2(m.x - w / 2.0, m.y - fs * 0.6, w, fs * 1.2), Color("#FFFDF7"))
		TtPal.text_c(self, TtPal.MONO_B, m, lab, fs, ink)
	for id in _by:
		var d: Dictionary = _by[id]
		var c := _p(id)
		if int(d.type) == TtNode.Type.LEAF:
			var r := Rect2(c - Vector2(15, 12), Vector2(30, 24))
			draw_rect(r, Color.WHITE)
			draw_rect(r, ink, false, 1.4)
			TtPal.text_c(self, TtPal.MONO_B, r.get_center(), str(int(d.get("start", 0)) + pos_base), int(fs * 0.9), ink)
		else:
			draw_circle(c, 8, Color.WHITE, true, -1, true)
			draw_arc(c, 8, 0, TAU, 20, ink, 1.5, true)
