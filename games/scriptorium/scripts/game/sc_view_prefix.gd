extends ScView
## Codeboom (GDD §3.1, §4.4): de boom van de code (wortel boven, links = 0, rechts = 1), bladeren als lettertegels.
## De speler klikt het blad waar de volgende bits naartoe leiden; de leesvinger loopt het pad af (60 ms per tak), de
## takken lichten goud op, de strook wordt na het codewoord afgeknipt en de letter gaat naar de kopie.
## Ook gebruikt in de Nachtwake-leesronde (code = de boom die je net bond).

const TREE_R := Rect2(150, 300, 960, 360)

var _path: Array = []
var _path_leaf := -1
var _pos := {}


func _setup() -> void:
	var syms := ""
	for nd in (cur.get("tree", {}) as Dictionary).get("nodes", []):
		if str(nd.sym) != "" and not syms.contains(str(nd.sym)):
			syms += str(nd.sym)
	alphabet = syms


func _layout(tree: Dictionary) -> Dictionary:
	var lay := ScTreeLayout.layout(tree, TREE_R.size.x, TREE_R.size.y)
	var out := {}
	for id in lay:
		out[id] = TREE_R.position + (lay[id] as Vector2)
	return out


func _nodes(tree: Dictionary) -> Dictionary:
	var by := {}
	for nd in tree.get("nodes", []):
		by[int(nd.id)] = nd
	return by


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"read_path":
			_path = fx.get("path", [])
			_path_leaf = int(fx.get("leaf", -1))
			var dur := (0.08 * maxi(1, _path.size()) + 0.25) * spd
			start_anim("path", dur)
			ScSnd.play("quill_letter", -8.0)
			var tw := create_tween()
			tw.tween_interval(dur * 0.8)
			tw.tween_callback(func():
				ScSnd.play("scissors", -6.0)
				if _pos.has(_path_leaf):
					burst_at("snip", _pos[_path_leaf] + Vector2(0, 60)))
			return dur
	return super.play(fx)


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"no_path":
			return "Volg de bits: daar leidt de strook niet heen."
		"not_leaf":
			return "Enkel aan een blad hangt een letter."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	var id := int(m.get("leaf", -1))
	if _pos.has(id):
		return _pos[id] + Vector2(0, 62)
	return AREA.get_center()


func band() -> Dictionary:
	return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": true, "alphabet": alphabet, "idx": false,
		"note": "" if str(cur.get("copy", "")) != "" else "klik het blad waar de bits naartoe leiden"}


func strip() -> Dictionary:
	var bits := str(cur.get("bits", ""))
	var pos := int(cur.get("pos", 0))
	var dec := ScReference.decode_prefix(_code(), bits.substr(0, pos))
	var toks: Array = []
	var s := 0
	for c in dec.cuts:
		toks.append({"b": bits.substr(s, int(c) - s)})
		s = int(c)
	var consumed := toks.size()
	if pos < bits.length():
		toks.append({"b": bits.substr(pos)})
	return {"tokens": toks, "consumed": consumed, "unit": ""}


func _code() -> Dictionary:
	var out := {}
	for nd in (cur.get("tree", {}) as Dictionary).get("nodes", []):
		if str(nd.sym) != "" and str(nd.sym) != ScCodes.NNG:
			out[str(nd.sym)] = str(nd.code)
	return out


func _paint() -> void:
	var tree: Dictionary = cur.get("tree", {})
	var by := _nodes(tree)
	_pos = _layout(tree)
	var root := int(tree.get("root", -1))
	if root < 0:
		return
	caption("De codeboom", "links 0 · rechts 1 · lees tot een blad")
	# gouden pad (leesvinger)
	var prog := anim("path")
	var lit := {}
	if not _path.is_empty() and prog < 1.0:
		var nlit := int(floor(prog * 1.25 * _path.size()))
		for q in mini(nlit, _path.size()):
			lit[int(_path[q])] = true
	for id in by:
		var nd: Dictionary = by[id]
		for side in ["l", "r"]:
			var ch := int(nd.get(side, -1))
			if ch >= 0 and _pos.has(ch):
				var hi := lit.has(ch)
				var bit := "0" if side == "l" else "1"
				var b: Vector2 = _pos[ch]
				ScDrawTools.branch(self, _pos[id], b, bit, hi, 7.0, t)
	var rest := str(cur.get("rest", ""))
	for id in by:
		var nd2: Dictionary = by[id]
		var p: Vector2 = _pos[id]
		var sym := str(nd2.sym)
		if int(nd2.l) < 0 and int(nd2.r) < 0 and sym != "":
			var m := {"act": "read", "leaf": int(id)}
			var hi2 := is_hover(m) or lit.has(int(id))
			var code := str(nd2.code) if guides else ""
			var r := ScDrawTools.leaf_tile(self, p, sym, 32, alphabet, hi2, code, t, -1, false)
			if lit.has(int(id)) and prog < 1.0:
				ScPal.ring(self, r.grow(8), 12, Color(ScPal.GOLD, 0.9), 4)
			zone(r, m)
		else:
			ScDrawTools.knob(self, p, 15, lit.has(int(id)))
	# leesvinger bij de wortel en de volgende bits
	var rp: Vector2 = _pos[root]
	if prog < 1.0 and not _path.is_empty():
		var q2 := clampf(prog * 1.25 * (_path.size() - 1), 0.0, float(_path.size() - 1))
		var a := int(floor(q2))
		var bq := mini(a + 1, _path.size() - 1)
		var pa: Vector2 = _pos.get(int(_path[a]), rp)
		var pb: Vector2 = _pos.get(int(_path[bq]), rp)
		ScDraw.inkhand(self, pa.lerp(pb, q2 - a) + Vector2(4, 4), 0.7, t, 0.9, 1.0)
	if rest != "":
		var nb := mini(rest.length(), 6)
		var s := rest.substr(0, nb) + ("…" if rest.length() > nb else "")
		table_label(rp + Vector2(40, -54), "volgende bits: " + s, 22, ScPal.TEXT)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	var code := _code()
	var keys := code.keys()
	keys.sort_custom(func(a, b) -> bool: return str(code[a]) < str(code[b]))
	var y := r.position.y + 30
	ScPal.text_l(ci, ScPal.UI_MED, Vector2(r.position.x + 10, y), "Het codeboek van de afzender", 20, ScPal.TEXT)
	y += 36
	var x := r.position.x + 14
	for k in keys:
		var s := "%s %s" % [ScPal.show(str(k)), str(code[k])]
		var w := ScPal.text_w(ScPal.MONO_B, s, 22) + 22
		if x + w > r.end.x:
			x = r.position.x + 14
			y += 38
		ci.draw_style_box(ScPal.sb(Color(ScPal.VELLUM, 0.92), 8), Rect2(x, y - 16, w, 32))
		ScPal.text_l(ci, ScPal.MONO_B, Vector2(x + 11, y), s, 22, ScPal.INK)
		x += w + 10
