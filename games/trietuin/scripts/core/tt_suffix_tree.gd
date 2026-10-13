class_name TtSuffixTree extends TtTreeModel
## Suffixboom (notas §3.2, p. 32–34; §3.3, p. 48–50; GDD §3.4, §8.7). Posities intern 0-gebaseerd; pos_base = weergave.
## Boog naar top t heeft label (b, e) (inclusief); blad: (j + l, n) met l de stringdiepte van het aanhechtpunt.
## Een punt is {"node": id, "off": k}: k = 0 → op top id; 1 ≤ k < booglengte → in de boog naar id na k tekens.
## Zetten: {"act":"attach","node":id,"off":k} · {"act":"label","b":b} · {"act":"locate","node":id,"off":k} ·
##         {"act":"absent"} · {"act":"where","pos":p} · {"act":"count","n":n} · {"act":"pick","leaves":[ids]} ·
##         {"act":"owner","texts":[k…]}

var text: String = ""
var n: int = 0                       # laatste positie (0-gebaseerd) = text.length() − 1
var pos_base: int = 0
var labels: String = "pointers"      # "pointers" (b,e) of "strings" (letters aan de bogen)
var owners: PackedInt32Array = []    # per positie: index van de tekst (1..k) in een veralgemeende boom; leeg = 0
var owner_names: PackedStringArray = []   # weergavenamen per tekst (index 0 = tekst 1)


func _init() -> void:
	kind = TtCodes.Kind.SUFFIX


func setup(alpha: TtAlphabet, text_: String, pos_base_: int = 0, labels_: String = "pointers",
		owners_: PackedInt32Array = PackedInt32Array()) -> TtSuffixTree:
	alphabet = alpha
	text = text_
	n = text.length() - 1
	pos_base = pos_base_
	labels = labels_
	owners = owners_
	_reset()
	return self


func _reset() -> void:
	_clear_nodes()
	var r := _new_node(NT.INNER)
	r.depth = 0
	root = r.id
	r.link = r.id
	card = null
	phase = P.IDLE
	st = {}


func owner_of(pos: int) -> int:
	return owners[pos] if pos >= 0 and pos < owners.size() else 0


func owner_name(k: int) -> String:
	return owner_names[k - 1] if k >= 1 and k <= owner_names.size() else str(k)


func display_pos(p: int) -> int:
	return p + pos_base


# ------------------------------------------------------------------ bogen en punten

## Eindpositie van open bladbogen ("it"); de Ukkonen-subklasse geeft de huidige iteratie.
func _open_end() -> int:
	return n


func edge_end(id: int) -> int:
	var nd := node(id)
	return _open_end() if nd.e == TtCodes.OPEN else nd.e


func edge_len(id: int) -> int:
	var nd := node(id)
	if nd == null or id == root:
		return 0
	return edge_end(id) - nd.b + 1


func edge_string(id: int) -> String:
	if id == root:
		return ""
	return text.substr(node(id).b, edge_len(id))


func string_depth(id: int) -> int:
	var nd := node(id)
	if nd == null:
		return 0
	if nd.type == NT.LEAF:
		return string_depth(nd.parent) + edge_len(id)
	return nd.depth


func node_string(id: int) -> String:
	var s := ""
	for x in path_to(id):
		s += edge_string(x)
	return s


func path_string(id: int) -> String:
	return node_string(id)


## Canonieke vorm van een punt (off = booglengte → de top zelf). {} als ongeldig.
func canon(pt: Dictionary) -> Dictionary:
	var id := int(pt.get("node", -1))
	var off := int(pt.get("off", 0))
	var nd := node(id)
	if nd == null or off < 0:
		return {}
	if off == 0:
		return {"node": id, "off": 0}
	if id == root:
		return {}
	var L := edge_len(id)
	if off > L:
		return {}
	if off == L:
		return {"node": id, "off": 0}
	return {"node": id, "off": off}


func point_string(pt: Dictionary) -> String:
	var c := canon(pt)
	if c.is_empty():
		return ""
	if int(c.off) == 0:
		return node_string(int(c.node))
	return node_string(node(int(c.node)).parent) + edge_string(int(c.node)).substr(0, int(c.off))


## Volgend teken na het punt in de boom ("" als het punt op een top staat: dan kijk je naar de kinderen).
func _next_char_at(c: Dictionary) -> String:
	if int(c.off) == 0:
		return ""
	return text[node(int(c.node)).b + int(c.off)]


func leaves_under_point(pt: Dictionary) -> Array[int]:
	var c := canon(pt)
	if c.is_empty():
		return []
	return leaves_under(int(c.node))


## Diepste punt tot waar z in de boom aanwezig is. -> {matched, node, off, x (volgend boomteken of ""), c}
func walk(z: String) -> Dictionary:
	var cur := root
	var i := 0
	while i < z.length():
		var cn := node(cur)
		if not cn.kids.has(z[i]):
			return {"matched": i, "node": cur, "off": 0, "x": "", "c": z[i]}
		var kid := int(cn.kids[z[i]])
		var L := edge_len(kid)
		var b := node(kid).b
		var k := 0
		while k < L and i + k < z.length():
			if text[b + k] != z[i + k]:
				return {"matched": i + k, "node": kid, "off": k, "x": text[b + k], "c": z[i + k]}
			k += 1
		if k == L:
			cur = kid
			i += L
		else:
			return {"matched": z.length(), "node": kid, "off": k, "x": text[b + k], "c": ""}
	return {"matched": z.length(), "node": cur, "off": 0, "x": "", "c": ""}


## §3.3: {found, node, off, b, e, l_t, pos (= b − l_t), leaves: [ids], starts: [j…], owners: [k…], u, x, c}
func locate_auto(z: String) -> Dictionary:
	var w := walk(z)
	if int(w.matched) < z.length() or z == "":
		var u := z.substr(0, int(w.matched))
		return {"found": false, "node": int(w.node), "off": int(w.off), "u": u, "x": str(w.x), "c": str(w.c),
			"leaves": [], "starts": [], "owners": [], "pos": -1}
	var c := canon({"node": int(w.node), "off": int(w.off)})
	var id := int(c.node)
	var nd := node(id)
	var lt := string_depth(nd.parent) if nd.parent >= 0 else 0
	var lv := leaves_under(id)
	var starts: Array = []
	var ows := {}
	for x in lv:
		starts.append(node(x).start)
		ows[node(x).owner] = true
	starts.sort()
	var ol: Array = ows.keys()
	ol.sort()
	return {"found": true, "node": id, "off": int(c.off), "b": nd.b, "e": edge_end(id), "l_t": lt, "pos": nd.b - lt,
		"leaves": lv, "starts": starts, "owners": ol, "u": z, "x": "", "c": ""}


func lookup_auto(word: String) -> Dictionary:
	var r := locate_auto(word)
	var path: Array[int] = []
	if r.found:
		path = path_to(int(r.node))
	var exact: bool = r.found and int(r.off) == 0 and node(int(r.node)).type == NT.LEAF
	return {"found": r.found, "path": path, "end": int(r.node), "reason": "leaf" if exact else ("point" if r.found else "null"),
		"exact_leaf": exact}


## Juiste afwijkpunt voor σ_j: het diepste punt tot waar σ_j al in de boom zit.
func attach_point(j: int) -> Dictionary:
	var w := walk(text.substr(j))
	return canon({"node": int(w.node), "off": int(w.off)})


## Klopt de padstring van dit blad met het suffix vanaf start?
func path_ok(leaf: int) -> bool:
	var nd := node(leaf)
	return nd != null and nd.type == NT.LEAF and node_string(leaf) == text.substr(nd.start)


func leaf_count() -> int:
	return count_type(NT.LEAF)


func inner_count() -> int:
	return count_type(NT.INNER)


# ------------------------------------------------------------------ sap

func sap_used() -> int:
	var s := 0
	for x in nodes.keys():
		if int(x) == root:
			continue
		var nd: TtNode = nodes[x]
		if labels == "strings":
			s += edge_len(nd.id)
			if nd.type == NT.LEAF:
				s += text.length() - nd.start
		else:
			s += 2
			if nd.type == NT.LEAF:
				s += 2
	return s


# ------------------------------------------------------------------ structuur

## Splitst de boog naar kid na k tekens. -> id van de nieuwe top.
func _split_edge(kid: int, k: int) -> int:
	var c := node(kid)
	var p := node(c.parent)
	var u := _new_node(NT.INNER)
	u.b = c.b
	u.e = c.b + k - 1
	u.parent = p.id
	u.depth = string_depth(p.id) + k
	u.via = c.via
	p.kids[u.via] = u.id
	c.b += k
	c.via = text[c.b]
	c.parent = u.id
	u.kids[c.via] = c.id
	return u.id


func _add_leaf(parent: int, b: int, e: int, start: int) -> int:
	var lf := _new_node(NT.LEAF)
	lf.b = b
	lf.e = e
	lf.start = start
	lf.owner = owner_of(start)
	lf.parent = parent
	lf.via = text[b]
	node(parent).kids[lf.via] = lf.id
	return lf.id


## Naïeve opbouw (alle suffixen, langste eerst) zonder log.
func build_naive() -> void:
	_reset()
	for j in range(text.length()):
		insert_suffix_auto(j)


func insert_suffix_auto(j: int) -> int:
	var pt := attach_point(j)
	var at := int(pt.node)
	var l := point_string(pt).length()
	if int(pt.off) > 0:
		at = _split_edge(at, int(pt.off))
	return _add_leaf(at, j + l, n, j)


func insert_auto(word: String) -> void:
	var j := text.find(word)
	if j >= 0:
		insert_suffix_auto(j)


func serialize() -> String:
	return TtNotation.serialize_suffix(_to_dict(root), pos_base, text, alphabet)


func _to_dict(id: int) -> Dictionary:
	var edges: Array = []
	for k in alphabet.sorted(node(id).kids.keys()):
		var c := node(int(node(id).kids[k]))
		if c.type == NT.LEAF:
			edges.append({"b": c.b, "e": c.e, "leaf_start": c.start})
		else:
			edges.append({"b": c.b, "e": c.e, "child": _to_dict(c.id)})
	return {"edges": edges}


func load_notation(s: String) -> void:
	_reset()
	var d := TtNotation.parse_suffix(s, pos_base)
	if d.has("error"):
		push_warning("TtSuffixTree: " + str(d.error))
		return
	_sbuild(d, root)


func _sbuild(d: Dictionary, parent: int) -> void:
	for ed in d.edges:
		var b := int(ed.b)
		if ed.has("leaf_start"):
			var lf := _add_leaf(parent, b, int(ed.e), int(ed.leaf_start))
			node(lf).e = int(ed.e)
		else:
			var u := _new_node(NT.INNER)
			u.b = b
			u.e = int(ed.e)
			u.parent = parent
			u.via = text[b]
			u.depth = string_depth(parent) + u.e - u.b + 1
			node(parent).kids[u.via] = u.id
			_sbuild(ed.child, u.id)


func _decorate(d: Dictionary) -> void:
	var id := int(d.id)
	d["depth"] = string_depth(id)
	d["e_now"] = edge_end(id) if id != root else -1
	d["edge"] = edge_string(id)
	d["string"] = node_string(id)
	if int(d.type) == NT.LEAF:
		d["path_ok"] = path_ok(id)


func _render_flags() -> Dictionary:
	var mis := {}
	for x in nodes.keys():
		if node(x).type == NT.LEAF and not path_ok(x):
			mis[x] = true
	return {"misplaced": mis}


# ------------------------------------------------------------------ kaart-operatie

func _begin(c: TtCard) -> void:
	match c.kind:
		CK.SUFFIX:
			st = {"j": c.j, "leaf": -1, "l": 0, "point": {}}
			phase = P.ATTACH
		CK.ASK:
			st = {"z": c.word, "q": c.q, "point": {}}
			phase = P.LOCATE
		_:
			_begin_other(c)


func _begin_other(c: TtCard) -> void:
	push_warning("TtSuffixTree: kaartsoort %s niet ondersteund" % c.kind_name())
	phase = P.IDLE
	_finish("unsupported")


func _restore_st(s: Dictionary) -> Dictionary:
	var out := super._restore_st(s)
	if out.has("point") and out.point is Dictionary and not out.point.is_empty():
		out.point = {"node": int(out.point.node), "off": int(out.point.off)}
	return out


func _sigma() -> String:
	return text.substr(int(st.get("j", 0)))


func _correct() -> Dictionary:
	match phase:
		P.ATTACH:
			var pt := attach_point(int(st.j))
			return {"act": "attach", "node": int(pt.node), "off": int(pt.off)}
		P.LABEL:
			return {"act": "label", "b": int(st.j) + int(st.l)}
		P.LOCATE:
			var loc := locate_auto(str(st.z))
			if not loc.found:
				return {"act": "absent"}
			return {"act": "locate", "node": int(loc.node), "off": int(loc.off)}
		P.ANSWER:
			var loc2 := locate_auto(str(st.z))
			match str(st.q):
				"where":
					return {"act": "where", "pos": int(loc2.pos)}
				"first":
					return {"act": "where", "pos": text.find(str(st.z))}
				"count":
					return {"act": "count", "n": (loc2.leaves as Array).size()}
				"all":
					return {"act": "pick", "leaves": loc2.leaves}
				"owner":
					return {"act": "owner", "texts": loc2.owners}
	return {"act": "none"}


func cursor() -> Dictionary:
	var c := {"phase": phase, "j": int(st.get("j", -1)), "suffix": _sigma() if st.has("j") else "",
		"point": st.get("point", {}), "z": str(st.get("z", "")), "q": str(st.get("q", "")),
		"leaf": int(st.get("leaf", -1)), "l": int(st.get("l", 0)), "pos_base": pos_base}
	return c


func _bump_at() -> int:
	var pt: Dictionary = st.get("point", {})
	if not pt.is_empty():
		return int(pt.node)
	return root


func _apply(move: Dictionary, hint: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"attach":
			if phase != P.ATTACH:
				return _bump("wrong_phase")
			return _do_attach({"node": int(move.get("node", -1)), "off": int(move.get("off", 0))}, hint)
		"label":
			if phase != P.LABEL:
				return _bump("wrong_phase")
			return _do_label(int(move.get("b", -1)), hint)
		"locate":
			if phase != P.LOCATE:
				return _bump("wrong_phase")
			return _do_locate({"node": int(move.get("node", -1)), "off": int(move.get("off", 0))})
		"absent":
			if phase != P.LOCATE:
				return _bump("wrong_phase")
			return _do_absent()
		"where", "count", "pick", "owner":
			if phase != P.ANSWER:
				return _bump("wrong_phase")
			return _do_answer_q(act, move)
	return _apply_other(move, hint)


func _apply_other(_move: Dictionary, _hint: Dictionary) -> Dictionary:
	return _bump("unknown_act")


func _do_attach(pt: Dictionary, hint: Dictionary) -> Dictionary:
	var c := canon(pt)
	if c.is_empty():
		return _bump("past_end" if node(int(pt.node)) != null else "bad_target", {"at": root})
	var at := node(int(c.node))
	if int(c.off) == 0 and at.type == NT.LEAF:
		return _bump("bad_target", {"at": at.id})
	var j := int(st.j)
	var sig := _sigma()
	var u := point_string(c)
	var l := u.length()
	if l >= sig.length():
		return _bump("past_end", {"at": at.id})
	if int(c.off) == 0:
		if at.kids.has(sig[l]):
			return _bump("duplicate_first", {"at": at.id})
	elif _next_char_at(c) == sig[l]:
		return _bump("duplicate_first", {"at": at.id})
	var cost := 0
	if labels == "strings":
		cost = (n - (j + l) + 1) + (n - j + 1)
	else:
		cost = 4 + (2 if int(c.off) > 0 else 0)
	if not can_afford(cost):
		_finish("no_sap")
		return _bump("no_sap", {"at": at.id})
	var cp := {"node": int(hint.node), "off": int(hint.off)}
	var verdict := V.OK if c == cp else V.WRONG_POINT
	var data := {"sigma": sig, "u": point_string(cp), "x": u, "j": j, "l": l, "node": c.node, "off": c.off}
	var parent := at.id
	if int(c.off) > 0:
		var up := at.parent
		parent = _split_edge(at.id, int(c.off))
		_fx_add({"fx": "split_edge", "upper": up, "new_node": parent, "lower": at.id, "k": int(c.off)})
		_fx_add({"fx": "label", "node": parent, "b": node(parent).b, "e": node(parent).e})
		_fx_add({"fx": "label", "node": at.id, "b": at.b, "e": at.e})
	var lf := _add_leaf(parent, j + l, n, j)
	_fx_add({"fx": "attach", "leaf": lf, "at": parent, "off": 0})
	data["leaf"] = lf
	st.point = c
	if labels == "pointers":
		st.leaf = lf
		st.l = l
		phase = P.LABEL
	else:
		_fx_add({"fx": "label", "node": lf, "b": j + l, "e": n})
		_finish("attached", {"leaf": lf, "path_ok": path_ok(lf)})
	return {"ok": true, "verdict": verdict, "type": "ATTACH", "data": data}


func _do_label(b: int, hint: Dictionary) -> Dictionary:
	if b > n:
		return _bump("past_end", {"at": int(st.leaf)})
	if b < 0:
		return _bump("bad_target", {"at": int(st.leaf)})
	var lf := node(int(st.leaf))
	var p := node(lf.parent)
	var ch := text[b]
	if ch != lf.via and p.kids.has(ch):
		return _bump("duplicate_first", {"at": lf.id})
	var cb := int(hint.b)
	var verdict := V.OK if b == cb else V.WRONG_B
	p.kids.erase(lf.via)
	lf.b = b
	lf.via = ch
	p.kids[ch] = lf.id
	_fx_add({"fx": "label", "node": lf.id, "b": b, "e": lf.e})
	var data := {"l": int(st.l), "j": int(st.j) + pos_base, "b": cb + pos_base, "x": b + pos_base, "leaf": lf.id}
	if verdict != V.OK:
		data["affects"] = [_sigma()]
	_finish("labeled", {"leaf": lf.id, "path_ok": path_ok(lf.id)})
	return {"ok": true, "verdict": verdict, "type": "LABEL", "data": data}


func _do_locate(pt: Dictionary) -> Dictionary:
	var c := canon(pt)
	if c.is_empty():
		return _bump("bad_target")
	var z := str(st.z)
	var loc := locate_auto(z)
	var verdict := V.OK
	var data := {"z": z, "node": c.node, "off": c.off}
	if not loc.found:
		verdict = V.WRONG_ABSENT
		data.merge({"present": false, "u": str(loc.u), "x": str(loc.x) if str(loc.x) != "" else "niets", "c": str(loc.c)})
	elif int(loc.node) != int(c.node) or int(loc.off) != int(c.off):
		verdict = V.WRONG_POINT
		data.merge({"ask": true, "u": point_string(c)})
	st.point = c
	_fx_add({"fx": "loupe", "node": int(c.node), "off": int(c.off), "found": verdict == V.OK})
	var q := str(st.q)
	if loc.found and q in ["where", "first", "count", "all", "owner"]:
		phase = P.ANSWER
	else:
		_finish("answered" if verdict == V.OK else "wrong", {"found": loc.found})
	return {"ok": true, "verdict": verdict, "type": "LOCATE", "data": data}


func _do_absent() -> Dictionary:
	var z := str(st.z)
	var loc := locate_auto(z)
	var verdict := V.OK if not loc.found else V.WRONG_ABSENT
	var data := {"z": z, "present": loc.found}
	_fx_add({"fx": "loupe", "node": -1, "off": 0, "found": false})
	_finish("answered" if verdict == V.OK else "wrong", {"found": loc.found})
	return {"ok": true, "verdict": verdict, "type": "ABSENT", "data": data}


func _do_answer_q(act: String, move: Dictionary) -> Dictionary:
	var z := str(st.z)
	var loc := locate_auto(z)
	var lv: Array = loc.leaves
	var verdict := V.OK
	var data := {"z": z, "n": lv.size()}
	var type := ""
	match act:
		"where":
			type = "WHERE"
			var p := int(move.get("pos", -1))
			var lt := int(loc.l_t)
			var formula := p == int(loc.pos)
			if p < 0 or p > n or text.substr(p, z.length()) != z:
				verdict = V.WRONG_WHERE
			elif str(st.q) == "first" and p != text.find(z):
				verdict = V.WRONG_WHERE
			data.merge({"b": int(loc.b) + pos_base, "e": int(loc.e) + pos_base, "l": lt, "p": int(loc.pos) + pos_base,
				"x": p + pos_base, "formula": formula})
		"count":
			type = "COUNT"
			var cnt := int(move.get("n", -1))
			if cnt != lv.size():
				verdict = V.WRONG_COUNT
			data["x"] = cnt
		"pick":
			type = "PICKSET"
			var got := {}
			for x in move.get("leaves", []):
				got[int(x)] = true
			var want := {}
			for x in lv:
				want[int(x)] = true
			if got.size() != want.size() or not _same_keys(got, want):
				verdict = V.WRONG_PICK
			data["x"] = got.keys()
		"owner":
			type = "OWNER"
			var got2 := {}
			for x in move.get("texts", []):
				got2[int(x)] = true
			var want2 := {}
			for x in loc.owners:
				want2[int(x)] = true
			if got2.size() != want2.size() or not _same_keys(got2, want2):
				verdict = V.WRONG_OWNER
			var names := PackedStringArray()
			for k in loc.owners:
				names.append(owner_name(int(k)))
			data["names"] = " en ".join(names) if not names.is_empty() else "niemand"
			data["x"] = got2.keys()
	_finish("answered" if verdict == V.OK else "wrong")
	return {"ok": true, "verdict": verdict, "type": type, "data": data}


static func _same_keys(a: Dictionary, b: Dictionary) -> bool:
	for k in a.keys():
		if not b.has(k):
			return false
	return true


# ------------------------------------------------------------------ bots / QA

## Alle geldige aanhechtpunten voor σ_j (zonder klonk), het juiste eerst.
func valid_attach_points(j: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sig := text.substr(j)
	for x in subtree(root):
		var nd := node(x)
		var offs: Array = [0] if nd.type == NT.INNER else []
		if x != root:
			for k in range(1, edge_len(x)):
				offs.append(k)
		for k in offs:
			var c := {"node": x, "off": int(k)}
			var u := point_string(c)
			if u.length() >= sig.length():
				continue
			if int(k) == 0:
				if nd.kids.has(sig[u.length()]):
					continue
			elif _next_char_at(c) == sig[u.length()]:
				continue
			out.append(c)
	return out


func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hint := correct_move()
	match phase:
		P.ATTACH:
			for c in valid_attach_points(int(st.j)):
				if int(c.node) != int(hint.node) or int(c.off) != int(hint.off):
					out.append({"act": "attach", "node": int(c.node), "off": int(c.off)})
				if out.size() >= 8:
					break
		P.LABEL:
			var lf := node(int(st.leaf))
			for b in [int(hint.b) - 1, int(hint.b) + 1, int(st.j)]:
				if b >= 0 and b <= n and b != int(hint.b):
					var ch := text[b]
					if ch == lf.via or not node(lf.parent).kids.has(ch):
						out.append({"act": "label", "b": b})
		P.LOCATE:
			if hint.act == "locate":
				out.append({"act": "absent"})
				out.append({"act": "locate", "node": root, "off": 0})
			else:
				out.append({"act": "locate", "node": root, "off": 0})
		P.ANSWER:
			match str(hint.act):
				"where":
					var occ := TtReference.occurrences(text, str(st.z))
					if str(st.q) == "first" and occ.size() > 1:
						out.append({"act": "where", "pos": occ[1]})
					for p in range(0, n + 1):
						if not occ.has(p):
							out.append({"act": "where", "pos": p})
							break
				"count":
					out.append({"act": "count", "n": int(hint.n) + 1})
				"pick":
					var l2: Array = (hint.leaves as Array).duplicate()
					l2.pop_back()
					out.append({"act": "pick", "leaves": l2})
				"owner":
					out.append({"act": "owner", "texts": []})
	return out


func impossible_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.ATTACH:
			var sig := _sigma()
			var w := walk(sig.substr(0, 1))
			if int(w.matched) == 1:
				out.append({"act": "attach", "node": root, "off": 0})
		P.LABEL:
			out.append({"act": "label", "b": n + 1})
	out.append({"act": "unknown"})
	return out


func _invariants() -> PackedStringArray:
	var errs := _check_kids_tree()
	for x in nodes.keys():
		var nd: TtNode = nodes[x]
		if int(x) == root:
			continue
		if nd.b < 0 or nd.b > n:
			errs.append("top %d: b = %d buiten de tekst" % [nd.id, nd.b])
			continue
		if edge_len(nd.id) < 1:
			errs.append("top %d: lege boog (%d,%d)" % [nd.id, nd.b, edge_end(nd.id)])
		var p := node(nd.parent)
		if p != null and int(p.kids.get(text[nd.b], -1)) != nd.id:
			errs.append("top %d hangt niet onder zijn eerste teken %s" % [nd.id, text[nd.b]])
		if nd.type == NT.INNER:
			if nd.depth != string_depth(nd.parent) + edge_len(nd.id):
				errs.append("stringdiepte van %d klopt niet" % nd.id)
			if nd.kids.size() < 2:
				errs.append("interne top %d heeft maar %d kind(eren)" % [nd.id, nd.kids.size()])
	return errs
