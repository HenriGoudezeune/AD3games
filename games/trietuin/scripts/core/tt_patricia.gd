class_name TtPatricia extends TtTrie
## Patricia trie (notas §3.1.1, p. 28–30, Algoritme 1; GDD §3.2, §8.7). Interne top = |A| + 1 sap (knoppen + skip).
## Zetten: {"act":"read","pos":p} · {"act":"short"} · {"act":"pick_leaf","leaf":id} · {"act":"split","j":j} ·
##         {"act":"same"} · {"act":"answer","found":b} · {"act":"prune","node":id} · {"act":"prune_done"}


func _init() -> void:
	kind = TtCodes.Kind.PATRICIA


func setup(alpha: TtAlphabet, notation := "{0|}") -> TtPatricia:
	alphabet = alpha
	load_notation(notation)
	return self


# ------------------------------------------------------------------ structuur

func load_notation(s: String) -> void:
	_load(TtNotation.parse_patricia(s))


## Laadt een gewone trie als Patricia met skip 0 (snoeilevels).
func load_trie(s: String) -> void:
	_load(TtNotation.parse_trie(s))


func _load(d: Dictionary) -> void:
	_clear_nodes()
	if d.has("error"):
		push_warning("TtPatricia: " + str(d.error))
		d = {"skip": 0, "kids": {}}
	root = _pbuild(d, -1, "")
	_recompute()
	card = null
	phase = P.IDLE
	st = {}


func _pbuild(d: Dictionary, parent: int, via: String) -> int:
	if d.has("leaf"):
		var lf := _new_node(NT.LEAF)
		lf.label = str(d.leaf)
		lf.parent = parent
		lf.via = via
		return lf.id
	var n := _new_node(NT.INNER)
	n.parent = parent
	n.via = via
	n.skip = int(d.get("skip", 0))
	for k in alphabet.sorted(d.kids.keys()):
		n.kids[str(k)] = _pbuild(d.kids[k], n.id, str(k))
	return n.id


## pos(t) = pos(ouder) + skip(t) + 1, wortel: skip. depth = pos (lengte van de voorgestelde string);
## blad: pos = -1, depth = pos(ouder) + 1.
func _recompute() -> void:
	if root < 0:
		return
	var stack: Array = [[root, -1]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var n := node(int(it[0]))
		var ppos: int = it[1]
		if n.type == NT.LEAF:
			n.pos = -1
			n.depth = ppos + 1
			continue
		n.pos = ppos + n.skip + 1
		n.depth = n.pos
		for k in n.kids.keys():
			stack.append([int(n.kids[k]), n.pos])


func serialize() -> String:
	return _pser(root)


func _pser(id: int) -> String:
	var n := node(id)
	if n.type == NT.LEAF:
		return "[" + n.label + "]"
	var parts := PackedStringArray()
	for k in alphabet.sorted(n.kids.keys()):
		parts.append(str(k) + _pser(int(n.kids[k])))
	return "{%d|" % n.skip + " ".join(parts) + "}"


func sap_used() -> int:
	return count_type(NT.INNER) * (alphabet.cost_size + 1)


## String die een top voorstelt: de eerste pos(t) tekens van een vrucht eronder (voor een blad: het label).
func path_string(id: int) -> String:
	var n := node(id)
	if n == null:
		return ""
	if n.type == NT.LEAF:
		return n.label
	var lv := leaves_under(id)
	if lv.is_empty():
		return ""
	return node(lv[0]).label.substr(0, n.pos)


func unary_nodes() -> Array[int]:
	var out: Array[int] = []
	for id in subtree(root):
		var n := node(id)
		if n.type == NT.INNER and n.kids.size() == 1:
			out.append(id)
	return out


## Vruchten die Algoritme 1 niet terugvindt.
func misplaced() -> Array[int]:
	var out: Array[int] = []
	var ids := nodes.keys()
	ids.sort()
	for id in ids:
		var n: TtNode = nodes[id]
		if n.type == NT.LEAF:
			var z := zoek(n.label)
			if int(z.get("leaf", -1)) != n.id:
				out.append(n.id)
	return out


# ------------------------------------------------------------------ Algoritme 1

## Algoritme 1 (p. 29): {found, steps: [{node, pos, letter}], end: "leaf"|"null"|"short", node, leaf}
func zoek(word: String) -> Dictionary:
	var m := word.length() - 1
	var nxt := 0
	var top := node(root)
	var steps: Array = []
	while top.type != NT.LEAF:
		if nxt + top.skip > m:
			return {"found": false, "steps": steps, "end": "short", "node": top.id, "leaf": -1}
		nxt = nxt + top.skip + 1
		var c := word[nxt - 1]
		steps.append({"node": top.id, "pos": nxt - 1, "letter": c})
		if not top.kids.has(c):
			return {"found": false, "steps": steps, "end": "null", "node": top.id, "leaf": -1}
		top = node(int(top.kids[c]))
	return {"found": top.label == word, "steps": steps, "end": "leaf", "node": top.id, "leaf": top.id}


func lookup_auto(word: String) -> Dictionary:
	var z := zoek(word)
	var path: Array[int] = [root]
	for s in z.steps:
		var n := node(int(s.node))
		if n.kids.has(str(s.letter)):
			path.append(int(n.kids[str(s.letter)]))
	var reason := "null"
	if z.end == "short":
		reason = "short"
	elif z.end == "leaf":
		reason = "leaf_match" if z.found else "leaf_mismatch"
	return {"found": z.found, "path": path, "end": path[-1], "reason": reason, "steps": z.steps}


func insert_auto(word: String) -> void:
	var z := zoek(word)
	var lf := int(z.leaf)
	if lf < 0:
		var lv := leaves_under(int(z.node))
		if lv.is_empty():
			return
		lf = lv[0]
	var l := node(lf).label
	if l == word:
		return
	var j := first_diff(l, word, 0)
	if j < 0:
		return
	var g := _graft_target(lf, word, j)
	if not g.ok:
		return
	_graft(g, lf, word, j)


## Waar de ent voor (s, j) gebeurt: eerste top t op het pad wortel → vrucht lf met pos(t) ≥ j (blad: ∞).
## -> {ok, t, parent, new:bool, reason}
func _graft_target(lf: int, s: String, j: int) -> Dictionary:
	var path := path_to(lf)
	var par := -1
	for x in path:
		var n := node(x)
		var p := n.pos if n.type == NT.INNER else 1 << 30
		if p == j:
			if n.kids.has(s[j]):
				return {"ok": false, "reason": "occupied", "t": x}
			return {"ok": true, "t": x, "parent": par, "new": false}
		if p > j:
			return {"ok": true, "t": x, "parent": par, "new": true}
		par = x
	return {"ok": false, "reason": "occupied", "t": lf}


## Voert de ent uit (GDD §3.2 stap 3). -> {node, new, skips, leaf}
func _graft(g: Dictionary, lf: int, s: String, j: int) -> Dictionary:
	var l := node(lf).label
	var t := node(int(g.t))
	var skips := {}
	var target: TtNode
	if not bool(g.new):
		target = t
	else:
		var par := int(g.parent)
		var ppos := -1 if par == -1 else node(par).pos
		var u := _new_node(NT.INNER)
		u.skip = j - ppos - 1
		u.parent = par
		u.via = t.via
		if par == -1:
			root = u.id
		else:
			node(par).kids[t.via] = u.id
		if t.type == NT.INNER:
			t.skip = t.pos - j - 1
			skips[t.id] = t.skip
		t.parent = u.id
		t.via = l[j]
		u.kids[l[j]] = t.id
		skips[u.id] = u.skip
		target = u
	var nl := _new_node(NT.LEAF)
	nl.label = s
	nl.parent = target.id
	nl.via = s[j]
	target.kids[s[j]] = nl.id
	_recompute()
	return {"node": target.id, "new": bool(g.new), "skips": skips, "leaf": nl.id}


# ------------------------------------------------------------------ kaart-operatie

func _begin(c: TtCard) -> void:
	st = {"node": root, "next": 0, "d": 0, "leaf": -1, "word": c.word}
	match c.kind:
		CK.SEED, CK.BEE:
			phase = P.WALK
			if node(root).type == NT.LEAF:
				_arrive_leaf(root)
		CK.PATRICIFY:
			phase = P.PRUNING
		_:
			push_warning("TtPatricia: kaartsoort %s niet ondersteund" % c.kind_name())
			phase = P.IDLE
			_finish("unsupported")


func _arrive_leaf(id: int) -> void:
	st.leaf = id
	if card.kind == CK.SEED:
		phase = P.COMPARE
		_fx_add({"fx": "compare", "a": node(id).label, "b": _word(), "d": 0})
	else:
		phase = P.AT_LEAF


func _first_leaf(id: int) -> int:
	var lv := leaves_under(id)
	return lv[0] if not lv.is_empty() else -1


func _correct() -> Dictionary:
	var w := _word()
	match phase:
		P.WALK:
			var top := node(int(st.node))
			var nxt := int(st.next)
			if nxt + top.skip > w.length() - 1:
				return {"act": "short"}
			return {"act": "read", "pos": nxt + top.skip}
		P.PICK_LEAF:
			return {"act": "pick_leaf", "leaf": _first_leaf(int(st.node))}
		P.COMPARE:
			var l := node(int(st.leaf)).label
			if l == w:
				return {"act": "same"}
			var j := first_diff(l, w, 0)
			if j < 0:
				return {"act": "same"}
			return {"act": "split", "j": j}
		P.AT_LEAF:
			return {"act": "answer", "found": node(int(st.leaf)).label == w}
		P.PRUNING:
			var un := unary_nodes()
			if un.is_empty():
				return {"act": "prune_done"}
			return {"act": "prune", "node": un[0]}
	return {"act": "none"}


func cursor() -> Dictionary:
	var w := _word()
	var c := {"phase": phase, "word": w, "m": w.length() - 1, "node": int(st.get("node", root)),
		"next": int(st.get("next", 0)), "leaf": int(st.get("leaf", -1)), "skip": 0, "read_pos": -1, "candidates": []}
	var top := node(int(c.node))
	if top != null and top.type == NT.INNER:
		c.skip = top.skip
		c.read_pos = int(c.next) + top.skip
	if phase == P.PICK_LEAF:
		c.candidates = leaves_under(int(c.node))
	if phase == P.COMPARE and int(c.leaf) >= 0:
		c["label"] = node(int(c.leaf)).label
	if phase == P.PRUNING:
		c["unary"] = unary_nodes()
	return c


func _apply(move: Dictionary, hint: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"read":
			if phase != P.WALK:
				return _bump("wrong_phase")
			return _do_read(int(move.get("pos", -1)), hint)
		"short":
			if phase != P.WALK:
				return _bump("wrong_phase")
			return _do_short()
		"pick_leaf":
			if phase != P.PICK_LEAF:
				return _bump("wrong_phase")
			return _do_pick(int(move.get("leaf", -1)))
		"split":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_psplit(int(move.get("j", -1)), hint)
		"same":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_same()
		"answer":
			if phase != P.AT_LEAF:
				return _bump("wrong_phase")
			return _do_answer(bool(move.get("found", false)))
		"prune":
			if phase != P.PRUNING:
				return _bump("wrong_phase")
			return _do_prune(int(move.get("node", -1)))
		"prune_done":
			if phase != P.PRUNING:
				return _bump("wrong_phase")
			return _do_prune_done()
	return _bump("unknown_act")


func _do_read(p: int, hint: Dictionary) -> Dictionary:
	var w := _word()
	var m := w.length() - 1
	var top := node(int(st.node))
	var nxt := int(st.next)
	if p > m:
		return _bump("past_end")
	if p < nxt:
		return _bump("before_d")
	var cp := nxt + top.skip
	var verdict := V.OK if (hint.get("act", "") == "read" and p == cp) else V.WRONG_POS
	var data := {"k": top.skip, "p": cp, "x": p, "next": nxt, "m": m, "node": top.id, "word": w}
	if cp > m:
		data["short_a"] = cp
	if verdict != V.OK and card.kind == CK.SEED:
		data["affects"] = [w]
	var c := w[p]
	st.next = p + 1
	_fx_add({"fx": "read", "node": top.id, "pos": p, "letter": c})
	var child := int(top.kids.get(c, -1))
	if child == -1:
		if card.kind == CK.BEE:
			_fx_add({"fx": "bee_null", "at": top.id, "letter": c})
			_finish("not_found", {"found": false})
		else:
			phase = P.PICK_LEAF
		return {"ok": true, "verdict": verdict, "type": "READ", "data": data}
	_fx_add({"fx": "move", "from": top.id, "to": child, "letter": c, "who": _who()})
	if node(child).type == NT.LEAF:
		_arrive_leaf(child)
	else:
		st.node = child
	return {"ok": true, "verdict": verdict, "type": "READ", "data": data}


func _do_short() -> Dictionary:
	var w := _word()
	var m := w.length() - 1
	var top := node(int(st.node))
	var a := int(st.next) + top.skip
	var verdict := V.OK if a > m else V.WRONG_SHORT
	var data := {"a": a, "m": m, "node": top.id, "word": w}
	_fx_add({"fx": "short", "node": top.id})
	if card.kind == CK.BEE:
		_finish("not_found", {"found": false})
	else:
		phase = P.PICK_LEAF
	return {"ok": true, "verdict": verdict, "type": "SHORT", "data": data}


func _do_pick(leaf: int) -> Dictionary:
	var n := node(leaf)
	if n == null or n.type != NT.LEAF or not leaves_under(int(st.node)).has(leaf):
		return _bump("not_in_subtree")
	_fx_add({"fx": "pick", "leaf": leaf})
	st.leaf = leaf
	phase = P.COMPARE
	_fx_add({"fx": "compare", "a": n.label, "b": _word(), "d": 0})
	return {"ok": true, "verdict": V.OK, "type": "PICK", "data": {"leaf": leaf, "l": n.label}}


func _do_psplit(j: int, hint: Dictionary) -> Dictionary:
	var lf := node(int(st.leaf))
	var l := lf.label
	var s := _word()
	if l == s:
		return _bump("no_diff")
	if j < 0:
		return _bump("before_d")
	if j >= mini(l.length(), s.length()):
		return _bump("past_end")
	if l[j] == s[j]:
		return _bump("same_letter")
	var g := _graft_target(lf.id, s, j)
	if not g.ok:
		return _bump(str(g.reason), {"at": int(g.t)})
	var cost := (alphabet.cost_size + 1) if bool(g.new) else 0
	if not can_afford(cost):
		_finish("no_sap", {"affects": [s]})
		return _bump("no_sap", {"data": {"affects": [s], "word": s, "cost": cost}})
	var cj := int(hint.get("j", j))
	var verdict := V.OK if j == cj else V.J_LATE
	var r := _graft(g, lf.id, s, j)
	_fx_add({"fx": "graft", "node": int(r.node), "new": bool(r.new), "skips": r.skips})
	_fx_add({"fx": "hang", "leaf": int(r.leaf), "node": int(r.node), "letter": s[j]})
	var data := {"d": 0, "j": cj, "x": j, "l": l, "s": s, "grown": 1 if bool(r.new) else 0, "new": bool(r.new)}
	if verdict != V.OK:
		data["affects"] = [l]
	_finish("planted", {"leaf": int(r.leaf)})
	return {"ok": true, "verdict": verdict, "type": "SPLIT", "data": data}


func _do_prune(id: int) -> Dictionary:
	var n := node(id)
	if n == null or n.type != NT.INNER or n.kids.size() != 1:
		return _bump("branching", {"at": id if n != null else root})
	var u := path_string(id)
	var c := node(int(n.kids.values()[0]))
	if c.type == NT.INNER:
		c.skip += n.skip + 1
	if n.parent == -1:
		root = c.id
		c.parent = -1
		c.via = ""
	else:
		node(n.parent).kids[n.via] = c.id
		c.parent = n.parent
		c.via = n.via
	nodes.erase(id)
	_recompute()
	_fx_add({"fx": "prune", "node": id, "child": c.id, "new_skip": c.skip if c.type == NT.INNER else -1})
	return {"ok": true, "verdict": V.OK, "type": "PRUNE", "data": {"node": id, "u": u}}


func _do_prune_done() -> Dictionary:
	var un := unary_nodes()
	var verdict := V.OK if un.is_empty() else V.UNPRUNED
	var data := {"left": un.size()}
	if not un.is_empty():
		data["u"] = path_string(un[0])
	_finish("pruned", {"left": un.size()})
	return {"ok": true, "verdict": verdict, "type": "PRUNE_DONE", "data": data}


func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hint := correct_move()
	match phase:
		P.WALK:
			var w := _word()
			var nxt := int(st.next)
			for p in range(nxt, w.length()):
				if not (hint.act == "read" and p == int(hint.pos)):
					out.append({"act": "read", "pos": p})
			if hint.act != "short":
				out.append({"act": "short"})
		P.COMPARE:
			var l := node(int(st.leaf)).label
			var s := _word()
			if l != s:
				out.append({"act": "same"})
				for j in range(int(hint.get("j", 0)) + 1, mini(l.length(), s.length())):
					if l[j] != s[j] and _graft_target(int(st.leaf), s, j).ok:
						out.append({"act": "split", "j": j})
		P.AT_LEAF:
			out.append({"act": "answer", "found": not bool(hint.found)})
		P.PRUNING:
			if hint.act == "prune":
				out.append({"act": "prune_done"})
	return out


func impossible_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.WALK:
			out.append({"act": "read", "pos": _word().length()})
		P.PICK_LEAF:
			for id in nodes.keys():
				if node(id).type == NT.LEAF and not leaves_under(int(st.node)).has(int(id)):
					out.append({"act": "pick_leaf", "leaf": int(id)})
					break
		P.PRUNING:
			for id in subtree(root):
				if node(id).type == NT.INNER and node(id).kids.size() >= 2:
					out.append({"act": "prune", "node": id})
					break
	return out


func _invariants() -> PackedStringArray:
	var errs := _check_kids_tree()
	var expect := {}
	var stack: Array = [[root, -1]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var n := node(int(it[0]))
		if n == null:
			continue
		if n.type == NT.INNER:
			var p: int = int(it[1]) + n.skip + 1
			if n.pos != p:
				errs.append("pos van %d is %d, verwacht %d" % [n.id, n.pos, p])
			if n.skip < 0:
				errs.append("negatieve skip in %d" % n.id)
			for k in n.kids.keys():
				stack.append([int(n.kids[k]), p])
				if node(int(n.kids[k])) != null and node(int(n.kids[k])).via != str(k):
					errs.append("via van %d klopt niet" % int(n.kids[k]))
	return errs
