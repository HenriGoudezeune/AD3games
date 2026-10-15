extends ScView
## Binderij (GDD §3.3, §4.4, juice #7–9): de rij stapels perkament (hoogte ∝ gewicht). Klik twee stapels (of ←/→ +
## Spatie): de kopiist bindt ze tot een bundel met het somgewicht; de bundel komt op de plaats van de linkse, met haar
## boompje erboven (links 0, rechts 1). De touwklos telt het touw = Σ gewichten van de bundels = de bits (Stelling 21).
## Na de laatste binding ontrolt het codeboek en schrijft de kopiist het bericht. Plankmodus (Oef. 85): plank A
## (gesorteerd) en plank B (nieuwe bundels achteraan); je neemt enkel van de voorkant.

const BASE_Y := 820.0
const PILE_S := 1.3
const SPOOL := Vector2(1170, 430)

var _sel := -1                  # rij: index; planken: 0 = A, 1 = B
var _first_shelf := ""
var _xs := {}                   # id → x (huidige tekening)
var _xs_prev := {}
var _born_from := {}            # nieuwe bundel → id van de linkse
var _bind := {}                 # lopende binding (fx)
var _snap := {}
var _codes := {}
var _weights := {}
var _spin := 0.0
var _book_rows: Array = []


func _setup() -> void:
	var bd := tool as ScBindery
	var a := ""
	for f in bd.freqs:
		a += str(f[0])
		_weights[str(f[0])] = int(f[1])
	alphabet = a if a.length() <= 10 else ""
	_codes = bd.codes.duplicate()


func _mode() -> String:
	return str(cur.get("mode", "row"))


func _items() -> Array:
	return cur.get("row", [])


static func parse(s: String) -> Variant:
	var i := [0]
	return _p(s, i)


static func _p(s: String, i: Array) -> Variant:
	if i[0] >= s.length():
		return ""
	if s[i[0]] == "(":
		i[0] += 1
		var l = _p(s, i)
		var r = _p(s, i)
		i[0] += 1
		return [l, r]
	var c := s[i[0]]
	i[0] += 1
	return c


static func leaves_of(n) -> int:
	if n is Array:
		return leaves_of(n[0]) + leaves_of(n[1])
	return 1


static func depth_of(n) -> int:
	if n is Array:
		return 1 + maxi(depth_of(n[0]), depth_of(n[1]))
	return 0


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"bind":
			_bind = fx.duplicate()
			_born_from[int(fx.id)] = int(fx.a)
			start_anim("bind", 0.6 * spd)
			ScSnd.play("twine_bind", -4.0)
			var tw := create_tween()
			tw.tween_interval(0.28 * spd)
			tw.tween_callback(func():
				ScSnd.play("twine_spool", -8.0)
				var p: Vector2 = Vector2(_xs.get(int(fx.a), 600.0), BASE_Y - 60)
				burst_at("twine", p))
			tw.tween_property(self, "_spin", _spin + float(fx.w), 0.5 * spd)
			_sel = -1
			_first_shelf = ""
			return 0.62 * spd
		"snap":
			_snap = fx.duplicate()
			start_anim("snap", 0.5)
			_sel = -1
			_first_shelf = ""
			burst_at("twine", Vector2(_xs.get(int(fx.a), 600.0), BASE_Y - 80))
			return 0.45
		"codebook":
			_codes = fx.get("codes", {}).duplicate()
			_book_rows = []
			for f in (tool as ScBindery).freqs:
				var s := str(f[0])
				var code := str(_codes.get(s, ""))
				_book_rows.append([ScPal.show(s), code, int(f[1]), code.length() * int(f[1])])
			_book_rows.sort_custom(_book_less)
			start_anim("book", (0.5 + 0.06 * _book_rows.size()) * spd)
			ScSnd.play("unroll", -4.0)
			return (0.5 + 0.06 * _book_rows.size()) * spd
		"write":
			return 0.0
	return super.play(fx)


static func _book_less(a: Array, b: Array) -> bool:
	if str(a[1]).length() != str(b[1]).length():
		return str(a[1]).length() < str(b[1]).length()
	return str(a[1]) < str(b[1])


func _on_commit() -> void:
	_bind = {}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "write":
		return _tokens_for((tool as ScBindery).seq)
	return []


func _tokens_for(seq: Array) -> Array:
	var out: Array = []
	for s in seq:
		out.append({"b": str(_codes.get(str(s), ""))})
	return out


func strip() -> Dictionary:
	var bd := tool as ScBindery
	if bd.bits == "":
		return {"tokens": [], "consumed": -1, "unit": "bits"}
	return {"tokens": _tokens_for(bd.seq), "consumed": -1, "unit": "bits"}


func band() -> Dictionary:
	var bd := tool as ScBindery
	var txt := ""
	if bd.text != "":
		txt = bd.text
	elif not bd.seq.is_empty():
		for s in bd.seq:
			txt += str(s)
	var note := ""
	if txt == "":
		var parts := PackedStringArray()
		for f in bd.freqs:
			parts.append("%s %d" % [str(f[0]), int(f[1])])
		note = "gewichten: " + " · ".join(parts)
	else:
		note = "n = %d" % txt.length()
	return {"label": "Opdracht", "text": txt, "cursor": -1, "chips": alphabet != "", "alphabet": alphabet, "idx": txt.length() <= 24,
		"note": note}


func buttons() -> Array:
	return []


func anchor(m: Dictionary) -> Vector2:
	if _mode() == "shelves":
		var sa := str(m.get("a", "A"))
		return Vector2(260, 480 if sa == "A" else 770)
	var it := _items()
	var i := int(m.get("a", -1))
	var j := int(m.get("b", -1))
	var p := Vector2.ZERO
	var n := 0
	for q in [i, j]:
		if q >= 0 and q < it.size():
			p += Vector2(_xs.get(int(it[q].id), 600.0), BASE_Y - (40 + _pile_h(int(it[q].w))) * PILE_S)
			n += 1
	return p / maxf(1, n) if n > 0 else AREA.get_center()


func _pile_h(w: int) -> float:
	var n := mini(w, 16)
	var sh := 11.0 if w <= 10 else 150.0 / float(maxi(n, 1))
	return n * sh


# ------------------------------------------------------------------ input

func handle(ev: InputEvent) -> bool:
	if not readonly and not locked and ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_SPACE:
		var kz := _kbd()
		if sel >= 0 and sel < kz.size():
			_click(kz[sel].m)
			return true
	if not readonly and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		_sel = -1
		_first_shelf = ""
		return true
	return super.handle(ev)


func _click(m: Dictionary) -> void:
	if m.has("pick"):
		var i := int(m.pick)
		if _sel < 0:
			_sel = i
			ScSnd.play("ui_wood", -6.0, 0.9)
		elif _sel == i:
			_sel = -1
			ScSnd.play("ui_wood", -10.0, 0.7)
		else:
			var a := _sel
			_sel = -1
			request.emit({"act": "bind", "a": a, "b": i})
		return
	if m.has("shelf"):
		var s := str(m.shelf)
		if _first_shelf == "":
			_first_shelf = s
			ScSnd.play("ui_wood", -6.0, 0.9)
		else:
			var a2 := _first_shelf
			_first_shelf = ""
			request.emit({"act": "bind", "a": a2, "b": s})
		return
	super._click(m)


# ------------------------------------------------------------------ tekenen

func _positions(items: Array, x0 := 90.0, x1 := 1060.0) -> Dictionary:
	var ws: Array = []
	var tot := 0.0
	for it in items:
		var lv := leaves_of(parse(str(it.label)))
		var w := maxf(118.0, lv * 44.0)
		ws.append(w)
		tot += w
	var sc := minf(1.0, (x1 - x0) / maxf(tot, 1.0))
	var x := x0 + maxf(0.0, ((x1 - x0) - tot * sc) / 2.0)
	var out := {}
	for q in items.size():
		var w2: float = ws[q] * sc
		out[int(items[q].id)] = x + w2 / 2.0
		x += w2
	return out


func _paint() -> void:
	caption("De binderij", "bind de twee lichtste stapels · touw = bits")
	ScDrawTools.twine_spool(self, SPOOL, 1.0, t, int(cur.get("twine", 0)),
		int(cur.get("optimum", 0)) > 0 and int(cur.get("twine", 0)) > int(cur.get("optimum", 0)), _spin)
	if _mode() == "shelves":
		_paint_shelves()
		return
	var items := _items()
	var pos_new := _positions(items)
	var pos_old := _positions(prev.get("row", []))
	_xs = {}
	for id in pos_new:
		var xn: float = pos_new[id]
		var xo: float = pos_old.get(id, pos_old.get(_born_from.get(id, -1), xn))
		_xs[id] = lerpf(xo, xn, k)
	# tijdens een binding: de vorige rij, de twee stapels schuiven naar elkaar
	var draw_items := items
	var ba := anim("bind")
	if not _bind.is_empty() and k < 0.01:
		draw_items = prev.get("row", [])
		_xs = pos_old
	var done := items.size() == 1 and str(cur.get("phase_name", "")) != "BIND"
	var lw: Array = cur.get("lightest", [])
	for q in draw_items.size():
		var it: Dictionary = draw_items[q]
		var id := int(it.id)
		var x: float = _xs.get(id, 600.0)
		var off := Vector2.ZERO
		if not _bind.is_empty() and k < 0.01 and (id == int(_bind.a) or id == int(_bind.b)):
			var xa: float = pos_old.get(int(_bind.a), x)
			var xb: float = pos_old.get(int(_bind.b), x)
			var mid := (xa + xb) / 2.0
			off.x = (mid - x) * ease_out(ba / 0.45)
		if not _snap.is_empty() and anim("snap") < 1.0 and (id == int(_snap.a) or id == int(_snap.b)):
			off.x = sin(t * 60.0) * 6.0 * (1.0 - anim("snap"))
		var base := Vector2(x, BASE_Y) + off
		var m := {"pick": q}
		var selected := q == _sel
		var hint := is_ghost_item(q)
		var label := str(it.label)
		draw_set_transform(base * (1.0 - PILE_S), 0.0, Vector2(PILE_S, PILE_S))
		var zr0 := ScDrawTools.pile(self, base, label if bool(it.leaf) else "", int(it.w), alphabet, selected, t,
			not bool(it.leaf), 86.0, hint)
		draw_set_transform(Vector2.ZERO)
		var zr := Rect2(base + (zr0.position - base) * PILE_S, zr0.size * PILE_S)
		if is_hover(m) and not selected:
			ScPal.ring(self, zr, 12, Color(ScPal.INFO, 0.5), 2)
		if not done:
			zone(zr, m)
		if not bool(it.leaf):
			var tree = parse(label)
			var top_y := zr.position.y - 6
			var big := done
			_mini_tree(tree, Vector2(base.x, top_y), big)
	if done:
		_paint_book()
	# hint voor de lichtste (enkel tutorial/hulplijnen)
	if (guides or tutorial) and not lw.is_empty() and not done:
		table_label(Vector2(90, 266), "lichtste gewichten nu: %d en %d" % [int(lw[0]), int(lw[1])], 20, ScPal.TEXT)


func is_ghost_item(q: int) -> bool:
	if ghost.is_empty() or ghost_a < 0.3:
		return false
	return int(ghost.get("a", -9)) == q or int(ghost.get("b", -9)) == q


func _mini_tree(tree, bottom: Vector2, big := false) -> void:
	var lv := leaves_of(tree)
	var dp := depth_of(tree)
	var dx := 46.0 if not big else clampf(900.0 / maxf(lv, 1), 40.0, 120.0)
	var dy := 38.0 if not big else clampf(330.0 / maxf(dp, 1), 40.0, 80.0)
	var size := 20 if not big else 26
	var width := dx * (lv - 1)
	var top := bottom - Vector2(0, dy * dp + size * 1.32 + 36)
	if big:
		top = Vector2(clampf(bottom.x, 80 + width / 2, 1060 - width / 2), 300)
	var counter := [0]
	_tree_node(tree, top, dx, dy, top.x - width / 2.0, counter, size, 0, "")


func _tree_node(n, top: Vector2, dx: float, dy: float, x0: float, counter: Array, size: int, depth: int, code: String) -> Vector2:
	if n is Array:
		var pl := _tree_node(n[0], top, dx, dy, x0, counter, size, depth + 1, code + "0")
		var pr := _tree_node(n[1], top, dx, dy, x0, counter, size, depth + 1, code + "1")
		var p := Vector2((pl.x + pr.x) / 2.0, top.y + depth * dy)
		ScDrawTools.branch(self, p, pl, "0", false, 4.0 if size < 24 else 6.0, t)
		ScDrawTools.branch(self, p, pr, "1", false, 4.0 if size < 24 else 6.0, t)
		ScDrawTools.knob(self, p, 8 if size < 24 else 12)
		return p
	var x: float = x0 + counter[0] * dx
	counter[0] += 1
	var leaf := Vector2(x, top.y + depth * dy)
	var s := str(n)
	var showcode := code if size >= 24 else ""
	ScDrawTools.leaf_tile(self, leaf, s, size, alphabet, false, showcode, t, _weights.get(s, -1) if size >= 24 else -1)
	return leaf


func _paint_book() -> void:
	if _book_rows.is_empty():
		for f in (tool as ScBindery).freqs:
			var s := str(f[0])
			var code := str(_codes.get(s, ""))
			_book_rows.append([ScPal.show(s), code, int(f[1]), code.length() * int(f[1])])
	var a := anim("book")
	var n := int(ceil(a * (_book_rows.size() + 1)))
	var rows := _book_rows.slice(0, mini(n, _book_rows.size()))
	var tot := 0
	for r in _book_rows:
		tot += int(r[3])
	var h := 30.0 * (rows.size() + 2) + 16
	var rr := Rect2(870, 880 - h - 20, 370, h * minf(1.0, a * 1.4))
	ScDrawTools.ledger_table(self, rr, ["letter", "code", "a(x)", "l·a"], rows + ([["", "", "Σ", tot]] if n > _book_rows.size() else []), 20)


# ------------------------------------------------------------------ planken (Oef. 85)

func _paint_shelves() -> void:
	var sa: Array = cur.get("shelf_a", [])
	var sb: Array = cur.get("shelf_b", [])
	var done := sa.size() + sb.size() <= 1 and str(cur.get("phase_name", "")) != "BIND"
	for s in 2:
		var lst: Array = sa if s == 0 else sb
		var y := 560.0 if s == 0 else 850.0
		ScDraw.wood(self, Rect2(70, y, 1000, 18), ScPal.OAK_DARK, 6, true, 5)
		var name := "A" if s == 0 else "B"
		table_label(Vector2(40, y - 20), name, 26, ScPal.GILT_LIGHT)
		var x := 160.0
		var front_r := Rect2()
		for q in lst.size():
			var it: Dictionary = lst[q]
			var hi := q == 0 and _first_shelf == name
			var gh := q == 0 and not ghost.is_empty() and ghost_a > 0.3 and (str(ghost.get("a", "")) == name or str(ghost.get("b", "")) == name)
			var r := ScDrawTools.pile(self, Vector2(x, y), str(it.label) if bool(it.leaf) else "", int(it.w), alphabet, hi, t,
				not bool(it.leaf), 74.0, gh)
			if not bool(it.leaf):
				var lab := str(it.label).replace("(", "").replace(")", "")
				var fs := 16
				ScPal.text_c(self, ScPal.MONO_B, Vector2(x, y + 30), ScPal.show_text(lab), fs, ScPal.TEXT)
			if q == 0:
				front_r = r
			x += 98
		if lst.is_empty():
			table_label(Vector2(160, y - 40), "leeg", 20, ScPal.TEXT_DIM)
		elif not done:
			var m := {"shelf": name}
			if is_hover(m):
				ScPal.ring(self, front_r, 12, ScPal.INFO, 3)
			zone(front_r, m)
	table_label(Vector2(560, 266), "neem telkens vooraan het lichtste · zoekwerk %d" % int(cur.get("search", 0)), 20)
	if _first_shelf != "":
		table_label(Vector2(560, 304), "eerste: voorkant van plank %s" % _first_shelf, 20, ScPal.GOLD_LIGHT)
	if done:
		_paint_book()


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _codes.is_empty():
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 30), "Letterlijk wacht op je boom en je strook.", 20, ScPal.TEXT)
		return
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 30), "De duif brengt de boom mee (p. 86):", 20, ScPal.TEXT)
	var x := r.position.x + 14
	var y := r.position.y + 72
	for s in _codes:
		var txt := "%s %s" % [ScPal.show(str(s)), str(_codes[s])]
		var w := ScPal.text_w(ScPal.MONO_B, txt, 22) + 22
		if x + w > r.end.x:
			x = r.position.x + 14
			y += 38
		ci.draw_style_box(ScPal.sb(Color(ScPal.VELLUM, 0.92), 8), Rect2(x, y - 16, w, 32))
		ScPal.text_l(ci, ScPal.MONO_B, Vector2(x + 11, y), txt, 22, ScPal.INK)
		x += w + 10
