extends ScView
## Levende boom (GDD §3.4, §4.4, juice #14–19): elke top is een monnik met een kaartje [gewicht, nummer]; bladeren
## dragen hun letter op de borst, nng is een groen zaadje. Onderaan loopt de processie (op ordenummer, broers 2j−1/2j
## hand in hand). SCHRIJF/LEES: klik het blad (of het zaadje). KLIM: de lantaarn hangt bij t; klik de wisselpartner t′
## (zelfde gewicht, verste plaats) of de monnik met de lantaarn / "Blijf staan" (B). Wissels lopen in een boog,
## kaartjes klappen om, een monnik die eigenschap (b) breekt struikelt. De Overkant toont de boom van Letterlijk.

const TREE_R := Rect2(90, 345, 1040, 350)  # wortel onder de kop "De levende boom"
const PROC_Y := 850.0

var _pos := {}
var _ppos := {}
var _path: Array = []
var _path_t := -1.0
var _flip := {}
var _grow_id := -1
var _swap := []


func _setup() -> void:
	var s := ""
	var src := str(stage.get("text", stage.get("expect", "")))
	for ch in src:
		if not s.contains(ch):
			s += ch
	alphabet = s if s.length() <= 10 else ""


func _tree() -> Dictionary:
	return cur.get("tree", {})


func _nodes(tree: Dictionary) -> Dictionary:
	var by := {}
	for nd in tree.get("nodes", []):
		by[int(nd.id)] = nd
	return by


func _layout(tree: Dictionary) -> Dictionary:
	var lay := ScTreeLayout.layout(tree, TREE_R.size.x, TREE_R.size.y)
	var out := {}
	for id in lay:
		out[id] = TREE_R.position + (lay[id] as Vector2)
	return out


func _phase() -> String:
	return str(cur.get("phase_name", ""))


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"read_path":
			_path = fx.get("path", [])
			start_anim("path", (0.08 * maxi(1, _path.size()) + 0.2) * spd)
			if bool(fx.get("raw", false)):
				ScSnd.play("wax_seal", -6.0)
			else:
				ScSnd.play("quill_letter", -8.0)
			return (0.08 * maxi(1, _path.size()) + 0.25) * spd
		"grow":
			_grow_id = int(fx.get("old_nng", -1))
			start_anim("grow", 0.5 * spd)
			ScSnd.play("grow", -4.0)
			return 0.45 * spd
		"lantern":
			return 0.12 * spd
		"swap":
			_swap = [int(fx.a), int(fx.b)]
			ScSnd.play("steps", -6.0)
			ScSnd.play("cards", -8.0)
			return 0.1
		"weight":
			var id := int(fx.node)
			_flip[id] = t
			var depth := 0
			var by := _nodes(_tree())
			var x := id
			while by.has(x) and int(by[x].p) >= 0:
				depth += 1
				x = int(by[x].p)
			ScSnd.bell(maxi(0, 6 - depth), -10.0)
			return 0.12 * spd
		"stumble":
			ScSnd.play("stumble", -6.0)
			return 0.2
		"overkant":
			return 0.0
	return super.play(fx)


func commit_time() -> float:
	return (0.5 if not _swap.is_empty() else 0.35) * spd


func _on_commit() -> void:
	_ppos = _layout(prev.get("tree", {}))
	var tw := create_tween()
	tw.tween_interval(commit_time())
	tw.tween_callback(func(): _swap = [])


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"self":
			return "Dat is t zelf. Blijven staan? Klik op Blijf staan."
		"not_leaf":
			return "Schrijven gaat enkel met een blad of het zaadje."
		"no_path":
			return "De bits leiden daar niet heen."
		"ancestor":
			return ""
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	var act := str(m.get("act", ""))
	if act == "keep":
		var tt := int(cur.get("t", -1))
		return _pos.get(tt, AREA.get_center()) + Vector2(0, -10)
	var id := int(m.get("leaf", m.get("with", -1)))
	if _pos.has(id):
		return _pos[id] + Vector2(0, -20)
	return AREA.get_center()


func buttons() -> Array:
	if readonly:
		return []
	if _phase() == "CLIMB":
		return [{"text": "Blijf staan  (B)", "move": {"act": "keep"}, "kind": ScUi.Kind.VELLUM, "key": "B"}]
	return []


func key_move(ev: InputEventKey) -> Dictionary:
	if ev.keycode == KEY_B and _phase() == "CLIMB":
		return {"act": "keep"}
	return {}


func band() -> Dictionary:
	if int(cur.get("side", 0)) == ScCodes.Side.RECEIVE:
		return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": alphabet != "", "alphabet": alphabet,
			"idx": false}
	var txt := str(cur.get("text", ""))
	var i := int(cur.get("i", 0))
	return {"label": "Opdracht", "text": txt, "cursor": i if _phase() == "WRITE" else -1, "done": i, "chips": alphabet != "",
		"alphabet": alphabet, "note": _phase_note()}


func _phase_note() -> String:
	match _phase():
		"WRITE":
			return "schrijf `%s`" % ScPal.show(str(cur.get("ch", "")))
		"CLIMB":
			return "klim: wissel of blijf"
		"READ":
			return "lees"
	return ""


func strip() -> Dictionary:
	var lt := tool as ScLivingTree
	if lt.side == ScCodes.Side.SEND:
		return {"tokens": lt.tokens_out.duplicate(true), "consumed": -1, "unit": "bits"}
	var toks: Array = []
	var consumed := 0
	var group := ""
	var q := 0
	for it in lt.stream:
		var s := str(it)
		if q == lt.pos and group != "":
			toks.append({"b": group})
			group = ""
		if q == lt.pos:
			consumed = toks.size()
		if s.length() == 1:
			group += s
		else:
			if group != "":
				toks.append({"b": group})
				group = ""
			toks.append({"raw": ScReference.raw_char(s)})
		q += 1
	if group != "":
		toks.append({"b": group})
	if lt.pos >= lt.stream.size():
		consumed = toks.size()
	return {"tokens": toks, "consumed": consumed, "unit": ""}


static func stumblers(proc: Array) -> Dictionary:
	var out := {}
	var mx := -1
	for p in proc:
		if int(p.w) < mx:
			out[int(p.id)] = true
		mx = maxi(mx, int(p.w))
	return out


func _paint() -> void:
	var recv := int(cur.get("side", 0)) == ScCodes.Side.RECEIVE
	caption("De levende boom", "[gewicht, nummer] · zelfde gewicht, verste plaats" if not recv else "lees met jouw boom, werk hem bij")
	var tree := _tree()
	var by := _nodes(tree)
	var lay := _layout(tree)
	if _ppos.is_empty():
		_ppos = lay
	_pos = {}
	for id in lay:
		var p1: Vector2 = lay[id]
		var p0: Vector2 = _ppos.get(id, p1)
		var p := p0.lerp(p1, k)
		if p0.distance_to(p1) > 30:
			p.y -= sin(k * PI) * 50.0
		_pos[id] = p
	var root := int(tree.get("root", -1))
	if root < 0:
		return
	var depth := 0
	for id in by:
		var d := 0
		var x := int(id)
		while by.has(x) and int(by[x].p) >= 0:
			d += 1
			x = int(by[x].p)
		depth = maxi(depth, d)
	var ms := 0.86 if depth <= 3 else (0.72 if depth == 4 else 0.62)
	var ph := _phase()
	var lantern := int(cur.get("t", -1))
	var proc: Array = cur.get("procession", [])
	var stum := stumblers(proc)
	var sw := {}
	if guides or tutorial:
		for x in cur.get("same_weight", []):
			sw[int(x)] = true
	# gouden pad
	var lit := {}
	var pa := anim("path")
	if pa < 1.0:
		var nl := int(floor(pa * 1.3 * _path.size()))
		for q in mini(nl, _path.size()):
			lit[int(_path[q])] = true
	for id in by:
		var nd: Dictionary = by[id]
		for side in ["l", "r"]:
			var ch := int(nd.get(side, -1))
			if ch >= 0 and _pos.has(ch):
				ScDrawTools.branch(self, _pos[id] + Vector2(0, -20), _pos[ch] + Vector2(0, -60 * ms), "0" if side == "l" else "1",
					lit.has(ch), 6.0, t)
	var nng := int(tree.get("nng", -1))
	for id in by:
		var nd2: Dictionary = by[id]
		var p: Vector2 = _pos[id]
		var leaf := int(nd2.l) < 0 and int(nd2.r) < 0
		var card := "[%d,%d]" % [int(nd2.w), int(nd2.num)]
		var m := {}
		if leaf and ph == "WRITE":
			m = {"act": "write", "leaf": int(id)}
		elif leaf and ph == "READ":
			m = {"act": "read", "leaf": int(id)}
		elif ph == "CLIMB":
			m = {"act": "keep"} if int(id) == lantern else {"act": "swap", "with": int(id)}
		var hi := (not m.is_empty() and is_hover(m)) or sw.has(int(id)) or lit.has(int(id))
		var r: Rect2
		if int(id) == nng:
			var sprout := 0.0
			if int(id) == _grow_id and anim("grow") < 1.0:
				sprout = anim("grow")
			r = ScDrawTools.seed_nng(self, p + Vector2(0, -24), 1.1 * ms + 0.1, t, card, hi, sprout)
		else:
			var fl := 0.0
			if _flip.has(int(id)):
				fl = clampf((t - float(_flip[int(id)])) / 0.18, 0.0, 1.0)
			var sq := Vector2(1, 1)
			if fl < 1.0:
				sq.x = absf(cos(fl * PI))
			var walk := k * 2.0 if not _swap.is_empty() and (_swap.has(int(id))) else 0.0
			r = ScDraw.monk(self, p, ms, t + int(id), ScPal.HABITS[int(id) % 4], card, hi, int(id) == lantern,
				1.0 if stum.has(int(id)) else 0.0, 1.0, 1 if int(id) == lantern else 0, walk, str(nd2.sym) if leaf else "", alphabet)
			r = r.merge(Rect2(p - Vector2(30, 70) * ms, Vector2(60, 76) * ms))
		if not m.is_empty() and not readonly:
			zone(r, m)
	# processie
	_paint_procession(proc, stum, sw, lantern, ph)


func _paint_procession(proc: Array, stum: Dictionary, sw: Dictionary, lantern: int, ph: String) -> void:
	if proc.is_empty():
		return
	var n := proc.size()
	var step := minf(96.0, 1060.0 / n)
	var x0 := 640.0 - step * (n - 1) / 2.0
	ScDraw.wood(self, Rect2(x0 - 50, PROC_Y + 6, step * (n - 1) + 100, 16), ScPal.OAK_DARK, 6)
	table_label(Vector2(x0 - 46, PROC_Y + 44), "processie: nummer 1 → %d, gewicht stijgt nooit naar links" % n, 18)
	var pts: Array = []
	for q in n:
		pts.append(Vector2(x0 + q * step, PROC_Y))
	for q in range(0, n - 1, 2):
		ScDrawTools.hand_link(self, pts[q], pts[q + 1], 0.6)
	for q in n:
		var it: Dictionary = proc[q]
		var id := int(it.id)
		var m := {}
		if ph == "CLIMB":
			m = {"act": "keep"} if id == lantern else {"act": "swap", "with": id}
		var hi := (not m.is_empty() and is_hover(m)) or sw.has(id)
		var p: Vector2 = pts[q]
		var r: Rect2
		if str(it.sym) == ScCodes.NNG:
			r = ScDrawTools.seed_nng(self, p + Vector2(0, -16), 0.7, t, "%d·%d" % [int(it.w), int(it.num)], hi)
		else:
			r = ScDraw.monk(self, p, 0.56, t + q, ScPal.HABITS[id % 4], "%d·%d" % [int(it.w), int(it.num)], hi, id == lantern,
				1.0 if stum.has(id) else 0.0, 1.0, 0, 0.0, str(it.sym), alphabet)
			r = r.merge(Rect2(p - Vector2(22, 50), Vector2(44, 54)))
		if not m.is_empty() and not readonly:
			zone(r, m, false)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if int(cur.get("side", 0)) == ScCodes.Side.RECEIVE:
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De afzender hield dezelfde boom bij.", 20, ScPal.TEXT)
		return
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 20), "De boom van Letterlijk", 20, ScPal.TEXT)
	var tree: Dictionary = ov.get("tree", {})
	if tree.is_empty():
		return
	var box := Rect2(r.position + Vector2(30, 60), Vector2(r.size.x - 60, r.size.y - 90))
	var lay := ScTreeLayout.layout(tree, box.size.x, box.size.y)
	var by := _nodes(tree)
	for id in by:
		var nd: Dictionary = by[id]
		for side in ["l", "r"]:
			var ch := int(nd.get(side, -1))
			if ch >= 0 and lay.has(ch):
				ci.draw_line(box.position + lay[id], box.position + lay[ch], ScPal.OAK_LIGHT, 3.0, true)
	for id in by:
		var nd2: Dictionary = by[id]
		var p: Vector2 = box.position + lay[id]
		var leaf := int(nd2.l) < 0 and int(nd2.r) < 0
		var s := str(nd2.sym)
		if leaf:
			var col := ScPal.SEED if s == ScCodes.NNG else ScPal.letter_color(s, alphabet)
			ci.draw_style_box(ScPal.sb(col, 6), Rect2(p - Vector2(15, 13), Vector2(30, 26)))
			ScPal.text_c(ci, ScPal.MONO_B, p, "•" if s == ScCodes.NNG else ScPal.show(s), 18, ScPal.INK)
		else:
			ci.draw_circle(p, 9, ScPal.OAK)
		ScPal.text_c(ci, ScPal.MONO_M, p + Vector2(0, 24), "%d,%d" % [int(nd2.w), int(nd2.num)], 16, ScPal.TEXT)
