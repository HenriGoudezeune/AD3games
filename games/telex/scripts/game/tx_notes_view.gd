class_name TxNotesView
extends Control
## Notas-weergave (GDD §6.5 punt 6): het level zoals de lesnotas het tekenen — v-diagrammen/sporen (KMP), de tabel
## V[] (p. 56), "x | V_H[x]" (p. 65), de matrix M met de kaders van Figuur 23 (p. 67), M⁰/M¹ naast elkaar (p. 71),
## de editeertabel met de lijn van het pad (p. 76/79), de rollende hash per venster (p. 54). Esc / klik = sluiten.

var dd: TxDirector
var rep: Dictionary
var t := 0.0


func setup(d: TxDirector, r: Dictionary) -> void:
	dd = d
	rep = r


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.6)
	var b := TxUi.button("Sluiten", "brass", 24, 220)
	b.position = Vector2(850, 980)
	b.pressed.connect(queue_free)
	add_child(b)
	TxSnd.play("strip_slide", -6.0)


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var r := Rect2(120, 60, 1680, 900)
	draw_rect(Rect2(r.position + Vector2(8, 12), r.size), TxPal.SHADOW)
	draw_texture_rect(TxPal.tex("tex/paper_tile.png"), r, true, Color(1.18, 1.16, 1.1))
	TxPal.text_l(self, TxPal.STENCIL, r.position + Vector2(40, 44), "NOTAS-WEERGAVE", 28, TxPal.INK)
	if dd == null:
		return
	var y := r.position.y + 100.0
	var x := r.position.x + 40.0
	var done := {}
	for mc in dd.machines:
		if y > r.end.y - 120:
			break
		var key := "%d" % mc.kind
		if mc is TxKmpTable:
			y = _kmp_table(mc as TxKmpTable, x, y)
		elif mc is TxKmp:
			y = _kmp(mc as TxKmp, x, y)
		elif mc is TxBmh and not done.has(key):
			if (mc as TxBmh).t != "":
				done[key] = true
				y = _bmh(mc as TxBmh, x, y)
		elif mc is TxShiftAnd and (mc as TxShiftAnd).t != "":
			y = _shift_and(mc as TxShiftAnd, x, y)
		elif mc is TxEditBoard:
			y = _edit(mc as TxEditBoard, x, y)
		elif mc is TxRabinKarp:
			y = _rk(mc as TxRabinKarp, x, y)
		elif mc is TxBrute:
			y = _brute(mc as TxBrute, x, y)
		elif mc is TxSabotage:
			var sb := mc as TxSabotage
			TxPal.text_l(self, TxPal.TAPE, Vector2(x, y), "Tegenzet %s: z = %s, t = %s → %d (optimum %d)" % [sb.target, sb.zt, sb.tt, sb.best, sb.optimum], 20, TxPal.INK)
			y += 40


func _h(x: float, y: float, s: String) -> float:
	TxPal.text_l(self, TxPal.STENCIL, Vector2(x, y), s, 22, TxPal.STAMP_RED)
	return y + 36


func _vtable(x: float, y: float, z: String, v: Array, label := "V") -> float:
	var cw := 46.0
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), "j", 20, TxPal.INK_SOFT)
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y + 30), "z[j]", 20, TxPal.INK_SOFT)
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y + 60), label + "[j]", 20, TxPal.INK_SOFT)
	for j in v.size():
		var cx := x + 90 + j * cw
		TxPal.text_c(self, TxPal.TAPE_REG, Vector2(cx, y), str(j), 20, TxPal.INK)
		TxPal.text_c(self, TxPal.TAPE, Vector2(cx, y + 30), z[j] if j < z.length() else "–", 22, TxPal.INK)
		var vv := int(v[j])
		TxPal.text_c(self, TxPal.TAPE, Vector2(cx, y + 60), str(vv) if vv > 0 else "·", 22, TxPal.STAMP_BLUE)
	draw_line(Vector2(x, y + 15), Vector2(x + 90 + v.size() * cw, y + 15), Color(TxPal.INK, 0.4), 1.0)
	draw_line(Vector2(x + 70, y - 14), Vector2(x + 70, y + 76), Color(TxPal.INK, 0.4), 1.0)
	return y + 100


func _kmp_table(mc: TxKmpTable, x: float, y: float) -> float:
	y = _h(x, y, "Definitie 11 / Algoritme 5 — verschuivingstabel van %s (p. 56, 61)" % mc.z)
	var v := TxReference.v_def(mc.z, mc.cells_n > mc.m)
	y = _vtable(x, y, mc.z, v)
	if mc.method == "alg5":
		var steps: Array = TxReference.bereken_v(mc.z).steps
		var parts := PackedStringArray()
		for s in steps:
			var f := PackedStringArray()
			for c in s.filled:
				f.append("V[%d]=%d" % [int(c[0]), int(c[1])])
			parts.append("(start %d, gel %d, em %d: %s)" % [int(s.start), int(s.gel), int(s.em), ", ".join(f)])
		for l in TxChef._wrap(" · ".join(parts), 120).split("\n"):
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), l, 18, TxPal.INK)
			y += 26
	return y + 14


func _kmp(mc: TxKmp, x: float, y: float) -> float:
	y = _h(x, y, "Algoritme 4 — de oproepen van vergelijk_strings (p. 58–59)")
	var v := TxReference.v_def(mc.z, true)
	var r := TxReference.kmp(mc.z, mc.t, v, mc.find == TxCodes.Find.ALL)
	var parts := PackedStringArray()
	for s in r.trace:
		parts.append("(%d,%d,%d)" % [int(s.start), int(s.gel), int(s.em)])
	for l in TxChef._wrap("(start, gelijke_tekens, eerste_mismatch): " + " ".join(parts), 110).split("\n"):
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), l, 18, TxPal.INK)
		y += 26
	TxPal.text_l(self, TxPal.TAPE, Vector2(x, y + 4), "%d tikken · treffers %s" % [int(r.cmp), str(r.hits)], 20, TxPal.STAMP_BLUE)
	y += 40
	if not mc.strip.is_empty():
		y = _vtable(x, y, mc.z, v.slice(0, mc.strip.size()))
	return y + 10


func _bmh(mc: TxBmh, x: float, y: float) -> float:
	y = _h(x, y, "Boyer-Moore-Horspool — tabel V_H van %s (p. 65)" % mc.z)
	var vh := TxReference.vul_vh(mc.z)
	var keys: Array = vh.keys()
	keys.sort()
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), "x", 20, TxPal.INK_SOFT)
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y + 30), "V_H[x]", 20, TxPal.INK_SOFT)
	var i := 0
	for k in keys:
		TxPal.text_c(self, TxPal.TAPE, Vector2(x + 120 + i * 60, y), str(k), 22, TxPal.INK)
		TxPal.text_c(self, TxPal.TAPE, Vector2(x + 120 + i * 60, y + 30), str(vh[k]), 22, TxPal.STAMP_BLUE)
		i += 1
	TxPal.text_c(self, TxPal.TAPE, Vector2(x + 140 + i * 60, y), "andere", 20, TxPal.INK)
	TxPal.text_c(self, TxPal.TAPE, Vector2(x + 140 + i * 60, y + 30), str(mc.m), 22, TxPal.STAMP_BLUE)
	y += 70
	var r := TxReference.bmh(mc.z, mc.t, mc.find == TxCodes.Find.ALL)
	var parts := PackedStringArray()
	for s in r.trace:
		# bij een treffer in "eerste voorkomen" stopt is_contained_BMH (return TRUE): geen sprong meer tonen
		if bool(s.ok) and mc.find != TxCodes.Find.ALL:
			parts.append("i=%d '%s' treffer @%d" % [int(s.i), str(s.key), int(s.start)])
		elif bool(s.ok):
			parts.append("i=%d '%s' treffer @%d, +%d" % [int(s.i), str(s.key), int(s.start), int(s.shift)])
		else:
			parts.append("i=%d '%s' +%d" % [int(s.i), str(s.key), int(s.shift)])
	for l in TxChef._wrap(" · ".join(parts), 120).split("\n"):
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), l, 18, TxPal.INK)
		y += 26
	return y + 14


func _shift_and(mc: TxShiftAnd, x: float, y: float) -> float:
	y = _h(x, y, "Shift-AND — matrix M%s (Definitie 13/14, p. 67–71)" % ("" if mc.k == 0 else "⁰ en M¹"))
	var ref := TxReference.shift_and_k(mc.z, mc.t, mc.k)
	var w := minf(780.0, 120.0 + mc.n * 34.0)
	for l in mc.k + 1:
		var cols: Array = []
		var boxes: Array = []
		for j in ref.cols.size():
			var bits := ""
			for b in ref.cols[j][l]:
				bits += str(int(b))
			cols.append(bits)
			if bits.ends_with("1"):
				boxes.append([j, TxPal.STAMP_RED])
		TxDrawMachines.matrix_log(self, Rect2(x + l * (w + 30), y, w, 70 + mc.m * 34), mc.t, mc.z, cols, -1, boxes, "M" if mc.k == 0 else "M^%d" % l)
	return y + 100 + mc.m * 34


func _edit(mc: TxEditBoard, x: float, y: float) -> float:
	y = _h(x, y, ("Algoritme 8 — D[i][j] (p. 79)" if mc.approx else "Algoritme 7 — d[i][j] (p. 76)") + "  %s / %s" % [mc.a, mc.b])
	var tab := mc.true_table()
	var vals: Array = []
	var dirs: Array = []
	for i in tab.size():
		var row: Array = []
		var drow: Array = []
		for j in (tab[i] as Array).size():
			row.append(int(tab[i][j]))
			drow.append("")
		vals.append(row)
		dirs.append(drow)
	var path: Array = []
	var seqs := mc.distinct_sequences()
	var ps: Array = []
	if mc.approx:
		var best := TxReference.approx_best(mc.a, mc.b)
		var cols: Array = best.end_cols
		if not cols.is_empty():
			var pp := TxReference.all_paths(tab, mc.a, mc.b, mc.a.length(), int(cols[0]), true)
			if not pp.is_empty():
				ps = pp[0]
	else:
		var pp2 := TxReference.all_paths(tab, mc.a, mc.b, mc.a.length(), mc.b.length(), false)
		if not pp2.is_empty():
			ps = pp2[pp2.size() - 1]
	for s in ps:
		path.append(Vector2i(int(s.i), int(s.j)))
	if not ps.is_empty():
		var lst: Dictionary = ps[0]
		var pr := TxReference.pred(str(lst.dir), int(lst.i), int(lst.j))
		path.append(pr)
	var cell := minf(44.0, 760.0 / (mc.b.length() + 2))
	TxDrawMachines.relay_grid(self, Vector2(x + cell * 1.4, y + cell * 1.4), mc.a, mc.b, vals, dirs, cell, path, {}, Vector2i(-1, -1), mc.approx)
	return y + (mc.a.length() + 3) * cell


func _rk(mc: TxRabinKarp, x: float, y: float) -> float:
	y = _h(x, y, "Rabin-Karp — vingerafdrukken mod %d (p. 52–54)" % mc.q)
	var tt := mc.t if not mc.signal_mode() else ""
	TxPal.text_l(self, TxPal.TAPE, Vector2(x, y), "h(z) = h(%s) = %d   ·   w = 2^%d mod %d = %d" % [mc.z, TxReference.h(mc.z, mc.q), mc.m, mc.q, TxReference.weight(mc.m, mc.q)], 22, TxPal.INK)
	y += 40
	if tt != "":
		var r := TxReference.rk(mc.z, tt, mc.q, mc.find == TxCodes.Find.ALL)
		var hs: Array = r.hs
		var hz := int(r.hz)
		for i in hs.size():
			var col := TxPal.STAMP_RED if int(hs[i]) == hz else TxPal.INK
			var cx := x + (i % 8) * 200
			var cy := y + (i / 8) * 30
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(cx, cy), "%d: %s → %d" % [i, tt.substr(i, mc.m), int(hs[i])], 18, col)
		y += (hs.size() / 8 + 1) * 30 + 10
	else:
		for s in mc.signals:
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), "%s → %d%s" % [s, TxReference.h(s, mc.q), "  (alarm)" if TxReference.h(s, mc.q) == TxReference.h(mc.z, mc.q) else ""], 20, TxPal.INK)
			y += 28
	return y + 10


func _brute(mc: TxBrute, x: float, y: float) -> float:
	y = _h(x, y, "Algoritme 2 — brute kracht (p. 50–51)")
	var r := TxReference.brute(mc.z, mc.t, mc.find == TxCodes.Find.ALL, mc.joker)
	var parts := PackedStringArray()
	for s in r.trace:
		parts.append("%d:%d" % [int(s.start), int(s.cmp)])
	for l in TxChef._wrap("start:tikken  " + "  ".join(parts), 120).split("\n"):
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y), l, 18, TxPal.INK)
		y += 26
	TxPal.text_l(self, TxPal.TAPE, Vector2(x, y + 6), "%d tikken · %d uitlijningen · treffers %s · (n−m+1)·m = %d" % [int(r.cmp), int(r.alignments), str(r.hits), (mc.n - mc.m + 1) * mc.m], 20, TxPal.STAMP_BLUE)
	return y + 50
