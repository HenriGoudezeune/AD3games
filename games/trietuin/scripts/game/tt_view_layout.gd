class_name TtViewLayout
extends Object
## Weergave-layout van de boom (front-end). Werkt op `model.render_nodes()` en kent de getekende maten
## (knoppenkrans, vruchtlabel, rankknoop, (b,e)-bord), zodat niets overlapt. Wortel op (0,0), de boom groeit
## omhoog (-y). Kinderen in alfabetvolgorde links -> rechts (zoals de figuren). Elk kind krijgt een eigen kolom
## (subboombreedte); een ouder staat boven het midden van zijn kinderen. Deterministisch.
##
## Resultaat: {"pos": {id: Vector2}, "bounds": Rect2, "w": {id: float}}
## - INNER (trie/Patricia/suffix): pos = midden van de knoest.
## - LEAF: pos = top van de tak (de vrucht + label hangen eronder).
## - BALL (ternary): midden van de letterbol. PACK: = positie van zijn wortelbol (of een lege plek).

const VS_IN := 132.0      # verticale afstand knoest -> kind-knoest
const VS_LEAF := 205.0    # knoest -> vruchttop
const COL_GAP := 40.0
static var _vs := 1.0     # verticale compressie van knoest -> knoest (diepe bomen)


static func knot_gap(n: int) -> float:
	if n <= 5:
		return 40.0
	if n <= 8:
		return 34.0
	return 14.0


static func knot_width(n: int) -> float:
	return n * knot_gap(n) + 20.0


static func leaf_width(label: String, label_size := 22) -> float:
	return maxf(64.0, TtPal.word_width(label.length(), label_size) + label_size * 0.8 + 14.0)


static func compute(rn: Array, kind: int, letters: String, opts := {}) -> Dictionary:
	_vs = float(opts.get("vs", 1.0))
	var by_id := {}
	for d in rn:
		by_id[int(d.id)] = d
	match kind:
		TtCodes.Kind.TERNARY:
			return _ternary(by_id, letters, opts)
		TtCodes.Kind.SUFFIX, TtCodes.Kind.UKKONEN:
			return _suffix(by_id, letters, opts)
		_:
			return _trie(by_id, letters, opts)


static func _root_of(by_id: Dictionary) -> int:
	for id in by_id:
		var d: Dictionary = by_id[id]
		if int(d.get("parent", -1)) < 0 and int(d.type) == TtNode.Type.INNER:
			return id
	for id in by_id:
		if int(by_id[id].get("parent", -1)) < 0:
			return id
	return -1


static func _sorted_kids(d: Dictionary, letters: String) -> Array:
	var kids: Dictionary = d.get("kids", {})
	var keys := kids.keys()
	keys.sort_custom(func(a, b): return _ord(str(a), letters) < _ord(str(b), letters))
	var out := []
	for k in keys:
		out.append(int(kids[k]))
	return out


static func _ord(ch: String, letters: String) -> int:
	var i := letters.find(ch)
	return i if i >= 0 else 1000 + ch.unicode_at(0)


# ---------------------------------------------------------------- trie / Patricia
static func _trie(by_id: Dictionary, letters: String, opts: Dictionary) -> Dictionary:
	var root := _root_of(by_id)
	var w := {}
	var pos := {}
	if root < 0:
		return {"pos": pos, "bounds": Rect2(), "w": w}
	var label_size: int = opts.get("label_size", 22)
	var kw := knot_width(letters.length())
	if opts.get("patricia", false):
		kw += 130.0
	_tw(root, by_id, letters, kw, label_size, w)
	_tp(root, by_id, letters, 0.0, 0.0, w, pos)
	return {"pos": pos, "bounds": _bounds(pos, by_id, kw, label_size), "w": w}


static func _tw(id: int, by_id: Dictionary, letters: String, kw: float, ls: int, w: Dictionary) -> float:
	var d: Dictionary = by_id[id]
	if int(d.type) == TtNode.Type.LEAF:
		w[id] = leaf_width(str(d.get("label", "")), ls)
		return w[id]
	var kids := _sorted_kids(d, letters)
	var s := 0.0
	for k in kids:
		if by_id.has(k):
			s += _tw(k, by_id, letters, kw, ls, w) + COL_GAP
	s -= COL_GAP if kids.size() > 0 else 0.0
	w[id] = maxf(kw, s)
	return w[id]


static func _tp(id: int, by_id: Dictionary, letters: String, cx: float, y: float, w: Dictionary, pos: Dictionary) -> void:
	pos[id] = Vector2(cx, y)
	var d: Dictionary = by_id[id]
	if int(d.type) == TtNode.Type.LEAF:
		return
	var kids := _sorted_kids(d, letters)
	var total := 0.0
	for k in kids:
		if by_id.has(k):
			total += float(w[k]) + COL_GAP
	total -= COL_GAP if kids.size() > 0 else 0.0
	var x := cx - total / 2.0
	for k in kids:
		if not by_id.has(k):
			continue
		var kwid: float = w[k]
		var leaf := int(by_id[k].type) == TtNode.Type.LEAF
		_tp(k, by_id, letters, x + kwid / 2.0, y - (VS_LEAF if leaf else VS_IN * _vs), w, pos)
		x += kwid + COL_GAP


static func _bounds(pos: Dictionary, by_id: Dictionary, kw: float, ls: int) -> Rect2:
	var r := Rect2()
	var first := true
	for id in pos:
		var p: Vector2 = pos[id]
		var d: Dictionary = by_id.get(id, {})
		var rr: Rect2
		if int(d.get("type", 0)) == TtNode.Type.LEAF:
			var lw := leaf_width(str(d.get("label", "")), ls)
			rr = Rect2(p.x - lw / 2.0, p.y - 20, lw, 20 + 50 + ls * 1.55 + 40)
		else:
			rr = Rect2(p.x - kw / 2.0, p.y - 40, kw, 70)
		if first:
			r = rr
			first = false
		else:
			r = r.merge(rr)
	return r


# ---------------------------------------------------------------- ternary
## Bollen: kinderen [lo, eq, hi] in die volgorde links -> rechts. lo/hi een halve trede hoger (rank),
## eq een volle trede (volgende rankknoop of vrucht).
const T_BALL_W := 112.0
const T_SIDE_UP := 64.0
const T_EQ_UP := 136.0
const T_LEAF_UP := 150.0


static func _ternary(by_id: Dictionary, letters: String, opts: Dictionary) -> Dictionary:
	var pos := {}
	var w := {}
	var ls: int = opts.get("label_size", 22)
	# wortel-PACK: parent == -1
	var root_pack := -1
	for id in by_id:
		var d: Dictionary = by_id[id]
		if int(d.type) == TtNode.Type.PACK and int(d.get("parent", -1)) < 0:
			root_pack = id
	if root_pack < 0:
		return {"pos": pos, "bounds": Rect2(), "w": w}
	_t_pack_w(root_pack, by_id, ls, w)
	_t_pack_p(root_pack, by_id, 0.0, 0.0, w, pos)
	var r := Rect2()
	var first := true
	for id in pos:
		var p: Vector2 = pos[id]
		var d: Dictionary = by_id[id]
		var rr := Rect2(p.x - 60, p.y - 60, 120, 110)
		if int(d.type) == TtNode.Type.LEAF:
			var lw := leaf_width(str(d.get("label", "")), ls)
			rr = Rect2(p.x - lw / 2.0, p.y - 20, lw, 20 + 50 + ls * 1.55 + 40)
		if first:
			r = rr
			first = false
		else:
			r = r.merge(rr)
	return {"pos": pos, "bounds": r, "w": w}


static func _t_pack_w(pack: int, by_id: Dictionary, ls: int, w: Dictionary) -> float:
	var d: Dictionary = by_id[pack]
	var br := int(d.get("ball_root", -1))
	if br < 0 or not by_id.has(br):
		w[pack] = T_BALL_W
		return T_BALL_W
	w[pack] = _t_ball_w(br, by_id, ls, w)
	return w[pack]


static func _t_ball_w(ball: int, by_id: Dictionary, ls: int, w: Dictionary) -> float:
	var d: Dictionary = by_id[ball]
	var s := 0.0
	var n := 0
	for k in [int(d.get("lo", -1)), int(d.get("eq", -1)), int(d.get("hi", -1))]:
		if k < 0 or not by_id.has(k):
			continue
		var kd: Dictionary = by_id[k]
		var kwid := 0.0
		match int(kd.type):
			TtNode.Type.BALL:
				kwid = _t_ball_w(k, by_id, ls, w)
			TtNode.Type.PACK:
				kwid = _t_pack_w(k, by_id, ls, w)
			TtNode.Type.LEAF:
				kwid = leaf_width(str(kd.get("label", "")), ls)
				w[k] = kwid
		s += kwid
		n += 1
	s += COL_GAP * maxi(0, n - 1)
	w[ball] = maxf(T_BALL_W, s)
	return w[ball]


static func _t_pack_p(pack: int, by_id: Dictionary, cx: float, y: float, w: Dictionary, pos: Dictionary) -> void:
	pos[pack] = Vector2(cx, y)
	var br := int(by_id[pack].get("ball_root", -1))
	if br >= 0 and by_id.has(br):
		_t_ball_p(br, by_id, cx, y, w, pos)


static func _t_ball_p(ball: int, by_id: Dictionary, cx: float, y: float, w: Dictionary, pos: Dictionary) -> void:
	var d: Dictionary = by_id[ball]
	var kids := []
	for k in [int(d.get("lo", -1)), int(d.get("eq", -1)), int(d.get("hi", -1))]:
		if k >= 0 and by_id.has(k):
			kids.append(k)
	var total := 0.0
	for k in kids:
		total += float(w.get(k, T_BALL_W)) + COL_GAP
	total -= COL_GAP if kids.size() > 0 else 0.0
	# eq-kind recht boven de bol: schuif de kolommen zodat de eq-kolom gecentreerd staat
	var x := cx - total / 2.0
	var eq := int(d.get("eq", -1))
	if eq >= 0 and by_id.has(eq):
		var before := 0.0
		for k in kids:
			if k == eq:
				break
			before += float(w.get(k, T_BALL_W)) + COL_GAP
		var eq_center := x + before + float(w.get(eq, T_BALL_W)) / 2.0
		x += cx - eq_center
	# eigen positie = midden van de eq-kolom (= cx); lo/hi kolommen links/rechts
	pos[ball] = Vector2(cx, y)
	for k in kids:
		var kwid: float = w.get(k, T_BALL_W)
		var kc := x + kwid / 2.0
		var kd: Dictionary = by_id[k]
		match int(kd.type):
			TtNode.Type.BALL:
				_t_ball_p(k, by_id, kc, y - T_SIDE_UP, w, pos)
			TtNode.Type.PACK:
				_t_pack_p(k, by_id, kc, y - T_EQ_UP, w, pos)
			TtNode.Type.LEAF:
				pos[k] = Vector2(kc, y - T_LEAF_UP)
		x += kwid + COL_GAP


# ---------------------------------------------------------------- suffixboom
## Toppen = knoesten zonder knoppenrij (kleine knoest); bogen dragen hun string (parels) of een (b,e)-bord.
## Verticale afstand groeit met de booglengte (begrensd), zodat parels op de boog passen.
static func edge_len_px(chars: int, strings: bool) -> float:
	if strings:
		return clampf(70.0 + chars * 38.0, 130.0, 400.0)
	return clampf(150.0 + chars * 10.0, 170.0, 270.0)


static func _suffix(by_id: Dictionary, letters: String, opts: Dictionary) -> Dictionary:
	var root := _root_of(by_id)
	var pos := {}
	var w := {}
	if root < 0:
		return {"pos": pos, "bounds": Rect2(), "w": w}
	var lens: Dictionary = opts.get("edge_chars", {})   # id -> zichtbare booglengte (tekens)
	var strings: bool = opts.get("strings", false)
	var leaf_w: float = opts.get("leaf_w", 96.0)
	_sw(root, by_id, letters, leaf_w, w, opts)
	_sp(root, by_id, letters, 0.0, 0.0, w, pos, lens, strings)
	var r := Rect2()
	var first := true
	for id in pos:
		var p: Vector2 = pos[id]
		var rr := Rect2(p.x - leaf_w / 2.0, p.y - 30, leaf_w, 130)
		if first:
			r = rr
			first = false
		else:
			r = r.merge(rr)
	return {"pos": pos, "bounds": r, "w": w}


static func _suffix_kids(d: Dictionary, by_id: Dictionary, letters: String) -> Array:
	var kids: Dictionary = d.get("kids", {})
	var keys := kids.keys()
	keys.sort_custom(func(a, b): return _ord(str(a), letters) < _ord(str(b), letters))
	var out := []
	for k in keys:
		if by_id.has(int(kids[k])):
			out.append(int(kids[k]))
	return out


static func _sw(id: int, by_id: Dictionary, letters: String, leaf_w: float, w: Dictionary, opts: Dictionary) -> float:
	var d: Dictionary = by_id[id]
	var kids := _suffix_kids(d, by_id, letters)
	if kids.is_empty():
		w[id] = leaf_w
		return leaf_w
	var s := 0.0
	for k in kids:
		s += _sw(k, by_id, letters, leaf_w, w, opts) + 14.0
	s -= 14.0
	w[id] = maxf(80.0, s)
	return w[id]


static func _sp(id: int, by_id: Dictionary, letters: String, cx: float, y: float, w: Dictionary, pos: Dictionary,
		lens: Dictionary, strings: bool) -> void:
	pos[id] = Vector2(cx, y)
	var d: Dictionary = by_id[id]
	var kids := _suffix_kids(d, by_id, letters)
	var total := 0.0
	for k in kids:
		total += float(w[k]) + 14.0
	total -= 14.0 if kids.size() > 0 else 0.0
	var x := cx - total / 2.0
	for k in kids:
		var kwid: float = w[k]
		var L: int = lens.get(k, 2)
		_sp(k, by_id, letters, x + kwid / 2.0, y - edge_len_px(L, strings), w, pos, lens, strings)
		x += kwid + 14.0
