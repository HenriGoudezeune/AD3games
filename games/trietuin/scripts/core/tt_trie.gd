class_name TtTrie extends TtTreeModel
## Gewone trie (notas §3.1, p. 25–28; GDD §3.1, §8.7). Elke interne top heeft een kind k_a per letter (sap = |A|).
## Zetten: {"act":"move","letter":c} · {"act":"split","j":j} · {"act":"same"} · {"act":"answer","found":b} ·
##         {"act":"cut","node":id}


func _init() -> void:
	kind = TtCodes.Kind.TRIE


func setup(alpha: TtAlphabet, notation := "{}") -> TtTrie:
	alphabet = alpha
	load_notation(notation)
	return self


# ------------------------------------------------------------------ structuur

func load_notation(s: String) -> void:
	_clear_nodes()
	var d := TtNotation.parse_trie(s)
	if d.has("error"):
		push_warning("TtTrie: " + str(d.error))
		d = {"kids": {}}
	if d.has("leaf"):
		push_warning("TtTrie: wortel moet een top zijn")
		d = {"kids": {}}
	root = _build(d, -1, "", 0)
	card = null
	phase = P.IDLE
	st = {}


func _build(d: Dictionary, parent: int, via: String, depth: int) -> int:
	if d.has("leaf"):
		var lf := _new_node(NT.LEAF)
		lf.label = str(d.leaf)
		lf.parent = parent
		lf.via = via
		lf.depth = depth
		return lf.id
	var n := _new_node(NT.INNER)
	n.parent = parent
	n.via = via
	n.depth = depth
	for k in alphabet.sorted(d.kids.keys()):
		n.kids[str(k)] = _build(d.kids[k], n.id, str(k), depth + 1)
	return n.id


func serialize() -> String:
	return _ser(root)


func _ser(id: int) -> String:
	var n := node(id)
	if n.type == NT.LEAF:
		return "[" + n.label + "]"
	var parts := PackedStringArray()
	for k in alphabet.sorted(n.kids.keys()):
		parts.append(str(k) + _ser(int(n.kids[k])))
	return "{" + " ".join(parts) + "}"


func sap_used() -> int:
	return count_type(NT.INNER) * alphabet.cost_size


func inner_count() -> int:
	return count_type(NT.INNER)


## Labels van alle vruchten (gesorteerd).
func words() -> PackedStringArray:
	var out := PackedStringArray()
	for n in nodes.values():
		if (n as TtNode).type == NT.LEAF:
			out.append((n as TtNode).label)
	out.sort()
	return out


## De string die top id voorstelt (letters langs het pad).
func path_string(id: int) -> String:
	var s := ""
	for x in path_to(id):
		if x != root:
			s += node(x).via
	return s


## Vruchten waarvan het pad geen prefix van hun label is (onvindbaar).
func misplaced() -> Array[int]:
	var out: Array[int] = []
	var ids := nodes.keys()
	ids.sort()
	for id in ids:
		var n: TtNode = nodes[id]
		if n.type == NT.LEAF and not n.label.begins_with(path_string(n.id)):
			out.append(n.id)
	return out


## Interne toppen ≠ wortel zonder vrucht eronder.
func dead_wood() -> Array[int]:
	var out: Array[int] = []
	var ids := nodes.keys()
	ids.sort()
	for id in ids:
		var n: TtNode = nodes[id]
		if n.type == NT.INNER and n.id != root and leaves_under(n.id).is_empty():
			out.append(n.id)
	return out


func _render_flags() -> Dictionary:
	var dead := {}
	for x in dead_wood():
		dead[x] = true
	var mis := {}
	for x in misplaced():
		mis[x] = true
	return {"dead": dead, "misplaced": mis}


func _decorate(d: Dictionary) -> void:
	d["path"] = path_string(int(d.id))


# ------------------------------------------------------------------ algoritmen (zonder log)

## Opzoeken volgens p. 27: {found, path, end, reason ("null"|"leaf_match"|"leaf_mismatch"|"short"), depth}
func lookup_auto(word: String) -> Dictionary:
	var cur := root
	var path: Array[int] = [root]
	var d := 0
	while true:
		var n := node(cur)
		if n.type == NT.LEAF:
			var f := n.label == word
			return {"found": f, "path": path, "end": cur, "reason": "leaf_match" if f else "leaf_mismatch", "depth": d}
		if d >= word.length():
			return {"found": false, "path": path, "end": cur, "reason": "short", "depth": d}
		var c := word[d]
		if not n.kids.has(c):
			return {"found": false, "path": path, "end": cur, "reason": "null", "depth": d, "letter": c}
		cur = int(n.kids[c])
		path.append(cur)
		d += 1
	return {}


## Juiste invoeging zonder log of signalen (opbouw, bedden).
func insert_auto(word: String) -> void:
	var r := lookup_auto(word)
	var end := node(int(r.end))
	if r.reason == "null":
		_hang(end.id, str(r.letter), word, end.depth + 1)
	elif r.reason == "leaf_mismatch":
		var j := first_diff(end.label, word, end.depth)
		if j >= 0:
			_split(end.id, word, j)


func delete_auto(word: String) -> void:
	var r := lookup_auto(word)
	if r.found:
		_cut(correct_cut(int(r.end)))


static func first_diff(l: String, s: String, from: int) -> int:
	var n := mini(l.length(), s.length())
	for i in range(maxi(from, 0), n):
		if l[i] != s[i]:
			return i
	return -1


func _hang(parent: int, letter: String, word: String, depth: int) -> int:
	var lf := _new_node(NT.LEAF)
	lf.label = word
	lf.parent = parent
	lf.via = letter
	lf.depth = depth
	node(parent).kids[letter] = lf.id
	return lf.id


## Notas p. 27: blad b wordt intern, pad langs k_{s_d}…k_{s_{j−1}}, bladeren k_{l_j}, k_{s_j}.
## -> {grown: [ids van onder naar boven], last, leaf_new}
func _split(leaf_id: int, s: String, j: int) -> Dictionary:
	var lf := node(leaf_id)
	var par := node(lf.parent)
	var d := lf.depth
	var l := lf.label
	var grown: Array[int] = []
	var top := _new_node(NT.INNER)
	top.parent = par.id
	top.via = lf.via
	top.depth = d
	par.kids[lf.via] = top.id
	grown.append(top.id)
	var cur := top
	for k in range(d, j):
		var nx := _new_node(NT.INNER)
		nx.parent = cur.id
		nx.via = s[k]
		nx.depth = k + 1
		cur.kids[s[k]] = nx.id
		grown.append(nx.id)
		cur = nx
	lf.parent = cur.id
	lf.via = l[j]
	lf.depth = j + 1
	cur.kids[l[j]] = lf.id
	var nl := _hang(cur.id, s[j], s, j + 1)
	return {"grown": grown, "last": cur.id, "leaf_new": nl}


## Knipt de deelboom onder id weg. -> [verwijderde ids]
func _cut(id: int) -> Array[int]:
	var n := node(id)
	var removed := subtree(id)
	if n.parent != -1:
		node(n.parent).kids.erase(n.via)
	for x in removed:
		nodes.erase(x)
	return removed


## De juiste knipplaats voor de vrucht leaf_id (p. 27): het kind op het pad van de laatste top met ≥ 2 niet-lege
## kinderen (of het kind van de wortel).
func correct_cut(leaf_id: int) -> int:
	var path := path_to(leaf_id)
	var last := 0
	for i in range(path.size() - 1):
		if node(path[i]).kids.size() >= 2:
			last = i
	return path[last + 1] if path.size() > 1 else leaf_id


# ------------------------------------------------------------------ kaart-operatie

func _begin(c: TtCard) -> void:
	st = {"node": root, "d": 0, "leaf": -1, "word": c.word}
	match c.kind:
		CK.SEED, CK.BEE, CK.PRUNE:
			phase = P.WALK
		_:
			push_warning("TtTrie: kaartsoort %s niet ondersteund" % c.kind_name())
			phase = P.IDLE
			_finish("unsupported")


func _word() -> String:
	return str(st.get("word", ""))


func _correct() -> Dictionary:
	var w := _word()
	var d := int(st.d)
	match phase:
		P.WALK:
			return {"act": "move", "letter": _walk_letter(w, d, node(int(st.node)))}
		P.COMPARE:
			var l := node(int(st.leaf)).label
			if l == w:
				return {"act": "same"}
			var j := first_diff(l, w, d)
			if j < 0:
				return {"act": "same"}
			return {"act": "split", "j": j}
		P.AT_LEAF:
			return {"act": "answer", "found": node(int(st.leaf)).label == w}
		P.CUT:
			return {"act": "cut", "node": correct_cut(int(st.leaf))}
	return {"act": "none"}


## De juiste letter op diepte d; voorbij het woord (enkel na eerdere fouten): eerste lege knop.
func _walk_letter(w: String, d: int, n: TtNode) -> String:
	if d < w.length():
		return w[d]
	for a in alphabet.letters:
		if not n.kids.has(a):
			return a
	return alphabet.letters[0]


func cursor() -> Dictionary:
	var w := _word()
	var d := int(st.get("d", 0))
	var c := {"phase": phase, "node": int(st.get("node", root)), "depth": d, "word": w, "leaf": int(st.get("leaf", -1)),
		"j_min": d, "letter_hint": w[d] if (phase == P.WALK and d < w.length()) else ""}
	if phase == P.COMPARE and int(st.get("leaf", -1)) >= 0:
		c["label"] = node(int(st.leaf)).label
	return c


func _bump_at() -> int:
	if phase in [P.COMPARE, P.AT_LEAF, P.CUT]:
		return int(st.get("leaf", root))
	return int(st.get("node", root))


func _apply(move: Dictionary, hint: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"move":
			if phase != P.WALK:
				return _bump("wrong_phase")
			return _do_move(str(move.get("letter", "")), hint)
		"split":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_split(int(move.get("j", -1)), hint)
		"same":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_same()
		"answer":
			if phase != P.AT_LEAF:
				return _bump("wrong_phase")
			return _do_answer(bool(move.get("found", false)))
		"cut":
			if phase != P.CUT:
				return _bump("wrong_phase")
			return _do_cut(int(move.get("node", -1)), hint)
	return _bump("unknown_act")


func _who() -> String:
	return "seed" if card.kind == CK.SEED else "bee"


func _do_move(c: String, hint: Dictionary) -> Dictionary:
	if not alphabet.has(c):
		return _bump("bad_target")
	var w := _word()
	var d := int(st.d)
	var cur := node(int(st.node))
	var target := int(cur.kids.get(c, -1))
	var verdict := V.OK
	if d < w.length() and c != str(hint.get("letter", c)):
		verdict = V.WRONG_KNOP if (card.kind == CK.SEED and target == -1) else V.WRONG_LETTER
	var data := {"d": d, "c": w[d] if d < w.length() else "", "x": c, "word": w, "from": cur.id}
	if verdict != V.OK and card.kind == CK.SEED:
		data["affects"] = [w]
	if target == -1:
		if card.kind == CK.SEED:
			var lf := _hang(cur.id, c, w, d + 1)
			_fx_add({"fx": "hang", "leaf": lf, "node": cur.id, "letter": c})
			data["leaf"] = lf
			_finish("planted", {"leaf": lf})
		else:
			_fx_add({"fx": "bee_null", "at": cur.id, "letter": c})
			_finish("not_found", {"found": false, "present": words().has(w)})
		return {"ok": true, "verdict": verdict, "type": "MOVE", "data": data}
	_fx_add({"fx": "move", "from": cur.id, "to": target, "letter": c, "who": _who()})
	var tn := node(target)
	if tn.type == NT.LEAF:
		st.leaf = target
		st.d = d + 1
		match card.kind:
			CK.SEED:
				phase = P.COMPARE
				_fx_add({"fx": "compare", "a": tn.label, "b": w, "d": d + 1})
			CK.BEE:
				phase = P.AT_LEAF
			CK.PRUNE:
				phase = P.CUT
	else:
		st.node = target
		st.d = d + 1
	return {"ok": true, "verdict": verdict, "type": "MOVE", "data": data}


func _do_split(j: int, hint: Dictionary) -> Dictionary:
	var lf := node(int(st.leaf))
	var l := lf.label
	var s := _word()
	var d := int(st.d)
	if l == s:
		return _bump("no_diff")
	if j < d:
		return _bump("before_d")
	if j >= mini(l.length(), s.length()):
		return _bump("past_end")
	if l[j] == s[j]:
		return _bump("same_letter")
	var cost := (j - d + 1) * alphabet.cost_size
	if not can_afford(cost):
		_finish("no_sap", {"affects": [s]})
		return _bump("no_sap", {"data": {"affects": [s], "word": s, "cost": cost}})
	var cj := int(hint.get("j", j))
	var verdict := V.OK if j == cj else V.J_LATE
	var from_par := lf.parent
	var r := _split(lf.id, s, j)
	_fx_add({"fx": "grow", "nodes": r.grown})
	_fx_add({"fx": "rehang", "leaf": lf.id, "from": from_par, "to": int(r.last), "letter": l[j]})
	_fx_add({"fx": "hang", "leaf": int(r.leaf_new), "node": int(r.last), "letter": s[j]})
	var data := {"d": d, "j": cj, "x": j, "l": l, "s": s, "grown": (r.grown as Array).size()}
	if verdict != V.OK:
		data["affects"] = [l]
	_finish("planted", {"leaf": int(r.leaf_new)})
	return {"ok": true, "verdict": verdict, "type": "SPLIT", "data": data}


func _do_same() -> Dictionary:
	var lf := node(int(st.leaf))
	var s := _word()
	var ok := _same_is_ok(lf, s)
	_fx_add({"fx": "same", "leaf": lf.id, "correct": ok})
	var data := {"l": lf.label, "s": s}
	if ok:
		_finish("same")
		return {"ok": true, "verdict": V.OK, "type": "SAME", "data": data}
	data["affects"] = [s]
	_finish("blown")
	return {"ok": true, "verdict": V.WRONG_SAME, "type": "SAME", "data": data}


func _do_answer(found: bool) -> Dictionary:
	var lf := node(int(st.leaf))
	var s := _word()
	var truth := lf.label == s
	var verdict := V.OK if found == truth else V.WRONG_ANSWER
	var stolen := card.wasp and found and not truth
	var data := {"found": found, "l": lf.label, "s": s, "leaf": lf.id}
	var result := ""
	if truth:
		result = "found" if found else "missed"
	elif found:
		result = "stolen" if stolen else "wrong_honey"
	else:
		result = "wasp_caught" if card.wasp else "rejected"
	if stolen:
		data["affects"] = [lf.label]
		_steal(lf.id)
	_fx_add({"fx": "answer", "found": found, "correct": verdict == V.OK, "wasp": card.wasp, "stolen": stolen,
		"leaf": lf.id})
	_finish(result, {"found": found, "truth": truth})
	return {"ok": true, "verdict": verdict, "type": "ANSWER", "data": data}


## "Zit er al" is juist als de woorden gelijk zijn (of, na eerdere fouten, als er geen geldige split meer bestaat).
func _same_is_ok(lf: TtNode, s: String) -> bool:
	return lf.label == s or first_diff(lf.label, s, int(st.d)) < 0


## Wesp steelt een vrucht: het blad verdwijnt (de knop wordt leeg).
func _steal(leaf_id: int) -> void:
	var lf := node(leaf_id)
	if lf.parent != -1:
		node(lf.parent).kids.erase(lf.via)
	nodes.erase(leaf_id)


func _do_cut(id: int, hint: Dictionary) -> Dictionary:
	var leaf := int(st.leaf)
	var path := path_to(leaf)
	if id == root or not path.has(id):
		return _bump("not_on_path")
	var cc := int(hint.get("node", id))
	var ci := path.find(cc)
	var ii := path.find(id)
	var verdict := V.OK
	if ii < ci:
		verdict = V.CUT_TOO_HIGH
	elif ii > ci:
		verdict = V.CUT_TOO_LOW
	var u := path_string(path[ci - 1]) if ci >= 1 else ""
	var fallen: Array[int] = []
	var fallen_words: Array = []
	for x in leaves_under(id):
		if x != leaf:
			fallen.append(x)
			fallen_words.append(node(x).label)
	var removed := _cut(id)
	_fx_add({"fx": "cut", "node": id, "removed": removed, "fallen": fallen})
	var dead := dead_wood()
	if not dead.is_empty():
		_fx_add({"fx": "dead_wood", "nodes": dead})
	var data := {"u": u, "word": _word(), "node": id, "correct": cc, "removed": removed.size()}
	if not fallen_words.is_empty():
		data["affects"] = fallen_words
	_finish("cut", {"fallen": fallen.size(), "dead": dead.size()})
	return {"ok": true, "verdict": verdict, "type": "CUT", "data": data}


# ------------------------------------------------------------------ bots / QA

func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hint := correct_move()
	match phase:
		P.WALK:
			for a in alphabet.letters:
				if a != str(hint.get("letter", "")):
					out.append({"act": "move", "letter": a})
		P.COMPARE:
			var l := node(int(st.leaf)).label
			var s := _word()
			if l != s:
				out.append({"act": "same"})
				for j in range(int(hint.get("j", 0)) + 1, mini(l.length(), s.length())):
					if l[j] != s[j]:
						out.append({"act": "split", "j": j})
		P.AT_LEAF:
			out.append({"act": "answer", "found": not bool(hint.found)})
		P.CUT:
			for x in path_to(int(st.leaf)):
				if x != root and x != int(hint.node):
					out.append({"act": "cut", "node": x})
	return out


func impossible_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.COMPARE:
			var l := node(int(st.leaf)).label
			var s := _word()
			for j in range(int(st.d), mini(l.length(), s.length())):
				if l[j] == s[j]:
					out.append({"act": "split", "j": j})
					break
			if int(st.d) > 0:
				out.append({"act": "split", "j": int(st.d) - 1})
		P.CUT:
			out.append({"act": "cut", "node": root})
	out.append({"act": "answer" if phase != P.AT_LEAF else "move", "found": true, "letter": "A"})
	return out


func _invariants() -> PackedStringArray:
	var errs := _check_kids_tree()
	for id in nodes.keys():
		var n: TtNode = nodes[id]
		if n.parent != -1:
			var p := node(n.parent)
			if p == null:
				errs.append("ouder van %d bestaat niet" % n.id)
				continue
			if int(p.kids.get(n.via, -1)) != n.id:
				errs.append("top %d hangt niet aan knop %s van %d" % [n.id, n.via, p.id])
			if n.depth != p.depth + 1:
				errs.append("diepte van %d klopt niet" % n.id)
		if n.type == NT.INNER:
			for k in n.kids.keys():
				if not alphabet.has(str(k)):
					errs.append("letter %s niet in alfabet" % str(k))
	return errs
