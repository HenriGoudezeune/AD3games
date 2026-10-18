class_name TtTernary extends TtTrie
## Ternary trie (notas §3.1.2, p. 30–32; GDD §3.3, §8.7). Elke trie-top = een rankknoop (PACK) met een klein
## zoekboompje van letterbollen (BALL: kleiner/gelijk/groter). Sap = 3 per bol.
## Zetten: {"act":"go","dir":"lo"|"eq"|"hi"} · {"act":"split","j":j} · {"act":"same"} · {"act":"answer","found":b} ·
##         {"act":"place","letter":c}

const BALL_COST := 3

var conv: Array = []                      # omzetten: [{pack, letters:[...], kids:{letter: id}}] in breedte-eerst volgorde
var source_trie: String = ""              # de gewone trie waaruit omgezet wordt ("" = geen omzetting)
var word_order: PackedStringArray = []    # gewichten + volgorde voor het optimale plantorakel (bloeiwoorden)


func _init() -> void:
	kind = TtCodes.Kind.TERNARY


func setup(alpha: TtAlphabet, notation := "") -> TtTernary:
	alphabet = alpha
	load_notation(notation)
	return self


# ------------------------------------------------------------------ structuur

func load_notation(s: String) -> void:
	_clear_nodes()
	conv = []
	source_trie = ""
	var d := TtNotation.parse_ternary(s)
	if d.has("error"):
		push_warning("TtTernary: " + str(d.error))
		d = {}
	var rp := _new_node(NT.PACK)
	root = rp.id
	if not d.is_empty():
		rp.ball_root = _tbuild(d, rp.id, -1)
	card = null
	phase = P.IDLE
	st = {}


func _tbuild(d: Dictionary, pack: int, parent_ball: int) -> int:
	var b := _new_node(NT.BALL)
	b.ch = str(d.ch)
	b.pack = pack
	b.parent = parent_ball
	b.depth = node(pack).depth
	if not d.lo.is_empty():
		b.lo = _tbuild(d.lo, pack, b.id)
	if d.eq.has("leaf"):
		var lf := _new_node(NT.LEAF)
		lf.label = str(d.eq.leaf)
		lf.parent = b.id
		lf.depth = b.depth + 1
		lf.via = b.ch
		b.eq = lf.id
	elif not d.eq.is_empty():
		var pk := _new_node(NT.PACK)
		pk.parent = b.id
		pk.depth = b.depth + 1
		pk.via = b.ch
		b.eq = pk.id
		pk.ball_root = _tbuild(d.eq, pk.id, -1)
	if not d.hi.is_empty():
		b.hi = _tbuild(d.hi, pack, b.id)
	return b.id


## Laadt een gewone trie die omgezet moet worden (TERNARIFY-kaart): elke top wordt een lege rankknoop.
func load_trie(s: String) -> void:
	_clear_nodes()
	conv = []
	source_trie = TtNotation.normalize(s)
	var d := TtNotation.parse_trie(s)
	if d.has("error") or d.has("leaf"):
		push_warning("TtTernary.load_trie: ongeldige trie")
		d = {"kids": {}}
	var queue: Array = [[d, 0]]
	var rp := _new_node(NT.PACK)
	root = rp.id
	var packs: Array = [rp.id]
	var qi := 0
	while qi < queue.size():
		var td: Dictionary = queue[qi][0]
		var depth: int = queue[qi][1]
		var pid: int = packs[qi]
		qi += 1
		var kids := {}
		var letters: Array = alphabet.sorted(td.kids.keys())
		for k in letters:
			var sub: Dictionary = td.kids[k]
			if sub.has("leaf"):
				var lf := _new_node(NT.LEAF)
				lf.label = str(sub.leaf)
				lf.depth = depth + 1
				lf.via = str(k)
				kids[str(k)] = lf.id
			else:
				var pk := _new_node(NT.PACK)
				pk.depth = depth + 1
				pk.via = str(k)
				kids[str(k)] = pk.id
				queue.append([sub, depth + 1])
				packs.append(pk.id)
		conv.append({"pack": pid, "letters": letters, "kids": kids})
	card = null
	phase = P.IDLE
	st = {}


func converting() -> bool:
	for c in conv:
		if not (c.letters as Array).is_empty() and _placed(int(c.pack)).size() < (c.letters as Array).size():
			return true
	return false


func _placed(pack: int) -> Array:
	var out := []
	var pk := node(pack)
	if pk == null or pk.ball_root < 0:
		return out
	var stack: Array = [pk.ball_root]
	while not stack.is_empty():
		var b := node(int(stack.pop_back()))
		out.append(b.ch)
		if b.lo >= 0:
			stack.append(b.lo)
		if b.hi >= 0:
			stack.append(b.hi)
	return out


func serialize() -> String:
	var rp := node(root)
	if rp.ball_root < 0:
		return ""
	return _tser(rp.ball_root)


func _tser(id: int) -> String:
	if id < 0:
		return "."
	var n := node(id)
	if n.type == NT.LEAF:
		return "[" + n.label + "]"
	if n.type == NT.PACK:
		return _tser(n.ball_root)
	return "(%s %s %s %s)" % [n.ch, _tser(n.lo), _tser(n.eq), _tser(n.hi)]


func sap_used() -> int:
	return count_type(NT.BALL) * BALL_COST


func balls() -> int:
	return count_type(NT.BALL)


func _children(n: TtNode) -> Array[int]:
	var out: Array[int] = []
	match n.type:
		NT.PACK:
			if n.ball_root >= 0:
				out.append(n.ball_root)
		NT.BALL:
			for x in [n.lo, n.eq, n.hi]:
				if int(x) >= 0:
					out.append(int(x))
	return out


func _parent_of(id: int) -> int:
	var n := node(id)
	if n == null:
		return -1
	if n.type == NT.BALL and n.parent == -1:
		return n.pack
	return n.parent


func path_string(id: int) -> String:
	var n := node(id)
	if n == null:
		return ""
	match n.type:
		NT.LEAF:
			return n.label
		NT.BALL:
			return path_string(n.pack) + n.ch
		NT.PACK:
			if n.parent < 0:
				return ""
			return path_string(n.parent)
	return ""


func words() -> PackedStringArray:
	var out := PackedStringArray()
	for x in subtree(root):
		if node(x).type == NT.LEAF:
			out.append(node(x).label)
	out.sort()
	return out


func misplaced() -> Array[int]:
	var out: Array[int] = []
	for x in subtree(root):
		var n := node(x)
		if n.type == NT.LEAF and int(lookup_auto(n.label).end) != n.id:
			out.append(x)
	return out


func dead_wood() -> Array[int]:
	return []


# ------------------------------------------------------------------ algoritmen

## {found, path, end, reason, comparisons}
func lookup_auto(word: String) -> Dictionary:
	var path: Array[int] = [root]
	var pk := node(root)
	var b := pk.ball_root
	var d := 0
	var cmp := 0
	while true:
		if b < 0:
			return {"found": false, "path": path, "end": path[-1], "reason": "null", "comparisons": cmp}
		var bn := node(b)
		path.append(b)
		cmp += 1
		if d >= word.length():
			return {"found": false, "path": path, "end": b, "reason": "short", "comparisons": cmp}
		var c := alphabet.compare(word[d], bn.ch)
		if c < 0:
			b = bn.lo
		elif c > 0:
			b = bn.hi
		else:
			if bn.eq < 0:
				return {"found": false, "path": path, "end": b, "reason": "null", "comparisons": cmp}
			var e := node(bn.eq)
			path.append(e.id)
			if e.type == NT.LEAF:
				var f := e.label == word
				return {"found": f, "path": path, "end": e.id, "reason": "leaf_match" if f else "leaf_mismatch",
					"comparisons": cmp}
			b = e.ball_root
			d += 1
	return {}


## Som van het aantal bezochte bollen bij het opzoeken van elk woord (vluchtlengte).
func comparisons(ws: PackedStringArray) -> int:
	var s := 0
	for w in ws:
		s += int(lookup_auto(w).comparisons)
	return s


func insert_auto(word: String) -> void:
	var pk := node(root)
	if pk.ball_root < 0:
		_new_ball(root, -1, "root", word[0], word)
		return
	var b := pk.ball_root
	var d := 0
	while true:
		var bn := node(b)
		var c := alphabet.compare(word[d], bn.ch)
		if c != 0:
			var side := "lo" if c < 0 else "hi"
			var nx := bn.lo if c < 0 else bn.hi
			if nx < 0:
				_new_ball(bn.pack, b, side, word[d], word)
				return
			b = nx
			continue
		if bn.eq < 0:
			_attach_leaf(b, word)
			return
		var e := node(bn.eq)
		if e.type == NT.LEAF:
			if e.label == word:
				return
			var j := first_diff(e.label, word, e.depth)
			if j >= 0:
				_tsplit(e.id, word, j)
			return
		b = e.ball_root
		d += 1


## Nieuwe bol met letter ch in pack (onder ouderbol pb aan kant side), met een vrucht voor word aan zijn gelijk-rank.
func _new_ball(pack: int, pb: int, side: String, ch_: String, word: String) -> Array:
	var b := _new_node(NT.BALL)
	b.ch = ch_
	b.pack = pack
	b.parent = pb
	b.depth = node(pack).depth
	match side:
		"root":
			node(pack).ball_root = b.id
		"lo":
			node(pb).lo = b.id
		"hi":
			node(pb).hi = b.id
	var lf := _attach_leaf(b.id, word)
	return [b.id, lf]


func _attach_leaf(ball: int, word: String) -> int:
	var bn := node(ball)
	var lf := _new_node(NT.LEAF)
	lf.label = word
	lf.parent = ball
	lf.depth = bn.depth + 1
	lf.via = bn.ch
	bn.eq = lf.id
	return lf.id


## Split (GDD §3.3): rankknopen met één bol voor s_d…s_{j−1}; laatste rankknoop eerst bol l_j, dan s_j.
## -> {new: [ids], balls: [[ball, parent, dir, pack]], last_l, last_s, leaf_new}
func _tsplit(leaf_id: int, s: String, j: int) -> Dictionary:
	var lf := node(leaf_id)
	var l := lf.label
	var d := lf.depth
	var B := node(lf.parent)
	var new_ids: Array[int] = []
	var ball_fx: Array = []
	var cur_ball := B
	for k in range(d, j + 1):
		var pk := _new_node(NT.PACK)
		pk.depth = k
		pk.parent = cur_ball.id
		pk.via = cur_ball.ch
		cur_ball.eq = pk.id
		new_ids.append(pk.id)
		var b := _new_node(NT.BALL)
		b.pack = pk.id
		b.depth = k
		b.ch = s[k] if k < j else l[j]
		pk.ball_root = b.id
		new_ids.append(b.id)
		ball_fx.append([b.id, -1, "root", pk.id])
		cur_ball = b
	# cur_ball = bol l_j in de laatste rankknoop
	lf.parent = cur_ball.id
	lf.depth = j + 1
	lf.via = l[j]
	cur_ball.eq = lf.id
	var side := "lo" if alphabet.compare(s[j], l[j]) < 0 else "hi"
	var r := _new_ball(cur_ball.pack, cur_ball.id, side, s[j], s)
	new_ids.append(int(r[0]))
	ball_fx.append([int(r[0]), cur_ball.id, side, cur_ball.pack])
	return {"new": new_ids, "balls": ball_fx, "last_l": cur_ball.id, "last_s": int(r[0]), "leaf_new": int(r[1])}


func _steal(leaf_id: int) -> void:
	var lf := node(leaf_id)
	if lf.parent >= 0:
		node(lf.parent).eq = -1
	nodes.erase(leaf_id)


# ------------------------------------------------------------------ optimale plantvolgorde (orakel bij omzetten)

## Gewicht van letter k in conv-item ci: aantal woorden (word_order, anders alle vruchten) onder dat kind.
func _weights(ci: int) -> Dictionary:
	var item: Dictionary = conv[ci]
	var w := {}
	var rank := {}
	var all_words: Array = Array(word_order) if not word_order.is_empty() else Array(words_all())
	for k in item.letters:
		var child := int(item.kids[k])
		var labels := {}
		for x in _floating_subtree(child):
			if node(x).type == NT.LEAF:
				labels[node(x).label] = true
		var cnt := 0
		var first := 1 << 30
		for i in all_words.size():
			if labels.has(str(all_words[i])):
				cnt += 1
				first = mini(first, i)
		w[k] = cnt
		rank[k] = first
	return {"w": w, "rank": rank}


## Alle vruchtlabels, ook van nog niet verbonden toppen.
func words_all() -> PackedStringArray:
	var out := PackedStringArray()
	for n in nodes.values():
		if (n as TtNode).type == NT.LEAF:
			out.append((n as TtNode).label)
	out.sort()
	return out


## Deelboom van een (eventueel nog los) trie-kind tijdens het omzetten: volgt conv-items.
func _floating_subtree(id: int) -> Array:
	var out := [id]
	var n := node(id)
	if n.type == NT.PACK:
		for c in conv:
			if int(c.pack) == id:
				for k in c.kids.keys():
					out.append_array(_floating_subtree(int(c.kids[k])))
	return out


## Optimale bst (som gewicht × diepte) over gesorteerde sleutels; gelijke kost: kleinste rang als wortel.
## -> preorde (plantvolgorde)
func _opt_order(keys: Array, w: Dictionary, rank: Dictionary) -> Array:
	var n := keys.size()
	if n == 0:
		return []
	var cost := {}
	var root_of := {}
	var pre := [0]
	for i in n:
		pre.append(int(pre[-1]) + int(w[keys[i]]))
	for ln in range(1, n + 1):
		for i in range(0, n - ln + 1):
			var j := i + ln - 1
			var best := 1 << 30
			var br := -1
			for r in range(i, j + 1):
				var c := (int(cost.get(Vector2i(i, r - 1), 0)) if r > i else 0) + \
						(int(cost.get(Vector2i(r + 1, j), 0)) if r < j else 0)
				if c < best or (c == best and int(rank[keys[r]]) < int(rank[keys[br]])):
					best = c
					br = r
			cost[Vector2i(i, j)] = best + int(pre[j + 1]) - int(pre[i])
			root_of[Vector2i(i, j)] = br
	var out := []
	_preorder(0, n - 1, keys, root_of, out)
	return out


func _preorder(i: int, j: int, keys: Array, root_of: Dictionary, out: Array) -> void:
	if i > j:
		return
	var r := int(root_of[Vector2i(i, j)])
	out.append(keys[r])
	_preorder(i, r - 1, keys, root_of, out)
	_preorder(r + 1, j, keys, root_of, out)


## Plan voor de resterende letters van conv-item ci, gegeven de al geplante bollen (elke lege plek apart optimaal).
func _plan(ci: int) -> Array:
	var item: Dictionary = conv[ci]
	var placed := _placed(int(item.pack))
	var rem := []
	for k in item.letters:
		if not placed.has(k):
			rem.append(k)
	if rem.is_empty():
		return []
	var wr := _weights(ci)
	# groepeer per lege plek: letters tussen dezelfde twee geplante buren
	var sorted_placed: Array = alphabet.sorted(placed)
	var groups := {}
	for k in rem:
		var gi := 0
		for p in sorted_placed:
			if alphabet.compare(str(k), str(p)) > 0:
				gi += 1
		if not groups.has(gi):
			groups[gi] = []
		groups[gi].append(k)
	var out := []
	var gks := groups.keys()
	gks.sort()
	for g in gks:
		out.append_array(_opt_order(alphabet.sorted(groups[g]), wr.w, wr.rank))
	return out


## Optimale som van vergelijkingen voor word_order (of alle vruchten) na omzetting, onafhankelijk van de huidige staat.
func optimal_comparisons() -> int:
	var c := TtTernary.new().setup(alphabet)
	c.load_trie(source_trie)
	c.word_order = word_order
	for ci in c.conv.size():
		for k in c._plan(ci):
			c._place(ci, str(k))
	var ws := word_order if not word_order.is_empty() else c.words()
	return c.comparisons(ws)


func _place(ci: int, k: String) -> Array:
	var item: Dictionary = conv[ci]
	var pk := node(int(item.pack))
	var child := int(item.kids[k])
	var b := _new_node(NT.BALL)
	b.ch = k
	b.pack = pk.id
	b.depth = pk.depth
	var side := "root"
	var par := -1
	if pk.ball_root < 0:
		pk.ball_root = b.id
	else:
		var cur := node(pk.ball_root)
		while true:
			var c := alphabet.compare(k, cur.ch)
			if c < 0:
				if cur.lo < 0:
					cur.lo = b.id
					side = "lo"
					break
				cur = node(cur.lo)
			else:
				if cur.hi < 0:
					cur.hi = b.id
					side = "hi"
					break
				cur = node(cur.hi)
		par = cur.id
	b.parent = par
	b.eq = child
	var cn := node(child)
	cn.parent = b.id
	return [b.id, par, side, pk.id]


# ------------------------------------------------------------------ kaart-operatie

func _begin(c: TtCard) -> void:
	st = {"pack": root, "ball": node(root).ball_root, "d": 0, "leaf": -1, "word": c.word, "node": root}
	match c.kind:
		CK.SEED, CK.BEE:
			phase = P.WALK
			if node(root).ball_root < 0:
				if c.kind == CK.SEED:
					if not can_afford(BALL_COST):
						_finish("no_sap", {"affects": [c.word]})
						return
					var r := _new_ball(root, -1, "root", c.word[0], c.word)
					_fx_add({"fx": "ball", "ball": int(r[0]), "parent": -1, "dir": "root", "pack": root})
					_fx_add({"fx": "hang", "leaf": int(r[1]), "node": int(r[0]), "letter": c.word[0]})
					_finish("planted", {"leaf": int(r[1])})
				else:
					_fx_add({"fx": "bee_null", "at": root, "letter": c.word[0]})
					_finish("not_found", {"found": false})
		CK.TERNARIFY:
			phase = P.PLACING
			st = {"ci": _next_ci(0), "word": ""}
			if int(st.ci) >= conv.size():
				_finish("converted")
		_:
			push_warning("TtTernary: kaartsoort %s niet ondersteund" % c.kind_name())
			phase = P.IDLE
			_finish("unsupported")


func _next_ci(from: int) -> int:
	var ci := from
	while ci < conv.size() and _placed(int(conv[ci].pack)).size() >= (conv[ci].letters as Array).size():
		ci += 1
	return ci


func _dir_of(word: String, d: int, ball: TtNode) -> String:
	if d >= word.length():
		return "lo"
	var c := alphabet.compare(word[d], ball.ch)
	return "lo" if c < 0 else ("hi" if c > 0 else "eq")


func _correct() -> Dictionary:
	var w := _word()
	match phase:
		P.WALK:
			return {"act": "go", "dir": _dir_of(w, int(st.d), node(int(st.ball)))}
		P.COMPARE:
			var l := node(int(st.leaf)).label
			if l == w:
				return {"act": "same"}
			var j := first_diff(l, w, int(st.d))
			if j < 0:
				return {"act": "same"}
			return {"act": "split", "j": j}
		P.AT_LEAF:
			return {"act": "answer", "found": node(int(st.leaf)).label == w}
		P.PLACING:
			var plan := _plan(int(st.ci))
			if plan.is_empty():
				return {"act": "none"}
			return {"act": "place", "letter": str(plan[0])}
	return {"act": "none"}


func cursor() -> Dictionary:
	var w := _word()
	var d := int(st.get("d", 0))
	var c := {"phase": phase, "pack": int(st.get("pack", root)), "ball": int(st.get("ball", -1)), "depth": d,
		"word": w, "leaf": int(st.get("leaf", -1)), "letter_hint": w[d] if (phase == P.WALK and d < w.length()) else "",
		"placing_node": -1, "remaining": PackedStringArray(), "node": int(st.get("ball", root)), "j_min": d}
	if phase == P.PLACING and int(st.get("ci", 0)) < conv.size():
		var item: Dictionary = conv[int(st.ci)]
		c.placing_node = int(item.pack)
		var placed := _placed(int(item.pack))
		var rem := PackedStringArray()
		for k in item.letters:
			if not placed.has(k):
				rem.append(str(k))
		c.remaining = rem
		c["kids"] = (item.kids as Dictionary).duplicate()
		c["weights"] = _weights(int(st.ci)).w  # vruchten per letter (uitleg van de plantvolgorde)
	if phase == P.COMPARE and int(c.leaf) >= 0:
		c["label"] = node(int(c.leaf)).label
	return c


func _bump_at() -> int:
	if phase in [P.COMPARE, P.AT_LEAF]:
		return int(st.get("leaf", root))
	if phase == P.PLACING:
		return int(cursor().placing_node)
	return int(st.get("ball", root))


func _apply(move: Dictionary, hint: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"go":
			if phase != P.WALK:
				return _bump("wrong_phase")
			return _do_go(str(move.get("dir", "")), hint)
		"split":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_tsplit(int(move.get("j", -1)), hint)
		"same":
			if phase != P.COMPARE:
				return _bump("wrong_phase")
			return _do_same()
		"answer":
			if phase != P.AT_LEAF:
				return _bump("wrong_phase")
			return _do_answer(bool(move.get("found", false)))
		"place":
			if phase != P.PLACING:
				return _bump("wrong_phase")
			return _do_place(str(move.get("letter", "")))
	return _bump("unknown_act")


const DIR_NAMES := {"lo": "kleiner", "eq": "gelijk", "hi": "groter"}


func _do_go(dir: String, hint: Dictionary) -> Dictionary:
	if not DIR_NAMES.has(dir):
		return _bump("bad_target")
	var w := _word()
	var d := int(st.d)
	var b := node(int(st.ball))
	var cdir := str(hint.get("dir", dir))
	var verdict := V.OK if dir == cdir else V.WRONG_DIR
	var c := w[d] if d < w.length() else ""
	var rel: String = {"lo": "<", "eq": "=", "hi": ">"}[cdir]
	var data := {"c": c, "k": b.ch, "rel": rel, "dir_name": DIR_NAMES[cdir], "x": dir, "d": d, "word": w, "ball": b.id}
	if verdict != V.OK and card.kind == CK.SEED:
		data["affects"] = [w]
	if dir != "eq":
		var target := b.lo if dir == "lo" else b.hi
		if target < 0:
			if card.kind == CK.SEED:
				if not can_afford(BALL_COST):
					_finish("no_sap", {"affects": [w]})
					return _bump("no_sap", {"data": {"affects": [w], "word": w}})
				var r := _new_ball(b.pack, b.id, dir, c, w)
				_fx_add({"fx": "ball", "ball": int(r[0]), "parent": b.id, "dir": dir, "pack": b.pack})
				_fx_add({"fx": "hang", "leaf": int(r[1]), "node": int(r[0]), "letter": c})
				_finish("planted", {"leaf": int(r[1])})
			else:
				_fx_add({"fx": "bee_null", "at": b.id, "letter": c})
				_finish("not_found", {"found": false})
			return {"ok": true, "verdict": verdict, "type": "GO", "data": data}
		_fx_add({"fx": "go", "from": b.id, "to": target, "dir": dir})
		st.ball = target
		st.node = target
		return {"ok": true, "verdict": verdict, "type": "GO", "data": data}
	# gelijk
	if b.eq < 0:
		if card.kind == CK.SEED:
			var lf := _attach_leaf(b.id, w)
			_fx_add({"fx": "hang", "leaf": lf, "node": b.id, "letter": b.ch})
			_finish("planted", {"leaf": lf})
		else:
			_fx_add({"fx": "bee_null", "at": b.id, "letter": c})
			_finish("not_found", {"found": false})
		return {"ok": true, "verdict": verdict, "type": "GO", "data": data}
	var e := node(b.eq)
	_fx_add({"fx": "go", "from": b.id, "to": e.id, "dir": "eq"})
	st.d = d + 1
	if e.type == NT.LEAF:
		st.leaf = e.id
		if card.kind == CK.SEED:
			phase = P.COMPARE
			_fx_add({"fx": "compare", "a": e.label, "b": w, "d": d + 1})
		else:
			phase = P.AT_LEAF
	else:
		st.pack = e.id
		st.ball = e.ball_root
		st.node = e.ball_root
	return {"ok": true, "verdict": verdict, "type": "GO", "data": data}


func _do_tsplit(j: int, hint: Dictionary) -> Dictionary:
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
	var cost := (j - d + 2) * BALL_COST
	if not can_afford(cost):
		_finish("no_sap", {"affects": [s]})
		return _bump("no_sap", {"data": {"affects": [s], "word": s, "cost": cost}})
	var cj := int(hint.get("j", j))
	var verdict := V.OK if j == cj else V.J_LATE
	var from_b := lf.parent
	var r := _tsplit(lf.id, s, j)
	_fx_add({"fx": "grow", "nodes": r.new})
	for bf in r.balls:
		_fx_add({"fx": "ball", "ball": int(bf[0]), "parent": int(bf[1]), "dir": str(bf[2]), "pack": int(bf[3])})
	_fx_add({"fx": "rehang", "leaf": lf.id, "from": from_b, "to": int(r.last_l), "letter": l[j]})
	_fx_add({"fx": "hang", "leaf": int(r.leaf_new), "node": int(r.last_s), "letter": s[j]})
	var data := {"d": d, "j": cj, "x": j, "l": l, "s": s, "grown": (r.balls as Array).size()}
	if verdict != V.OK:
		data["affects"] = [l]
	_finish("planted", {"leaf": int(r.leaf_new)})
	return {"ok": true, "verdict": verdict, "type": "SPLIT", "data": data}


func _do_place(k: String) -> Dictionary:
	var ci := int(st.ci)
	var item: Dictionary = conv[ci]
	if not (item.letters as Array).has(k) or _placed(int(item.pack)).has(k):
		return _bump("no_letter_left")
	if not can_afford(BALL_COST):
		return _bump("no_sap")
	var r := _place(ci, k)
	_fx_add({"fx": "ball", "ball": int(r[0]), "parent": int(r[1]), "dir": str(r[2]), "pack": int(r[3])})
	var data := {"letter": k, "pack": int(item.pack), "dir": str(r[2])}
	var nci := _next_ci(ci)
	st.ci = nci
	if nci >= conv.size():
		var ws := word_order if not word_order.is_empty() else words()
		var cmp := comparisons(ws)
		_finish("converted", {"comparisons": cmp, "optimum": optimal_comparisons()})
	return {"ok": true, "verdict": V.OK, "type": "PLACE", "data": data}


func _snapshot_extra() -> Dictionary:
	return {"conv": conv.duplicate(true), "source": source_trie, "order": Array(word_order)}


func _restore_extra(d: Dictionary) -> void:
	conv = []
	for c in d.get("conv", []):
		var kids := {}
		for k in c.kids.keys():
			kids[str(k)] = int(c.kids[k])
		var letters := []
		for k in c.letters:
			letters.append(str(k))
		conv.append({"pack": int(c.pack), "letters": letters, "kids": kids})
	source_trie = str(d.get("source", ""))
	word_order = PackedStringArray(d.get("order", []))


func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hint := correct_move()
	match phase:
		P.WALK:
			for dr in ["lo", "eq", "hi"]:
				if dr != str(hint.dir):
					out.append({"act": "go", "dir": dr})
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
		P.PLACING:
			for k in cursor().remaining:
				if k != str(hint.get("letter", "")):
					out.append({"act": "place", "letter": k})
	return out


func impossible_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase == P.PLACING:
		out.append({"act": "place", "letter": "?"})
	out.append({"act": "go", "dir": "up"})
	return out


func _invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	var seen := {}
	for x in subtree(root):
		if seen.has(x):
			errs.append("top %d twee keer bereikt" % x)
		seen[x] = true
		var n := node(x)
		match n.type:
			NT.PACK:
				if n.ball_root >= 0 and (node(n.ball_root).pack != n.id or node(n.ball_root).parent != -1):
					errs.append("wortelbol van rankknoop %d klopt niet" % n.id)
			NT.BALL:
				for side in ["lo", "hi"]:
					var cid: int = n.lo if side == "lo" else n.hi
					if cid >= 0:
						var cn := node(cid)
						if cn == null or cn.type != NT.BALL or cn.parent != n.id or cn.pack != n.pack:
							errs.append("bol %d: %s-kind %d klopt niet" % [n.id, side, cid])
				if n.eq >= 0:
					var en := node(n.eq)
					if en == null or en.parent != n.id:
						errs.append("bol %d: gelijk-kind klopt niet" % n.id)
			NT.LEAF:
				if node(n.parent) == null or node(n.parent).eq != n.id:
					errs.append("vrucht %d hangt niet aan een gelijk-rank" % n.id)
	if not converting() and seen.size() != nodes.size():
		errs.append("%d toppen niet bereikbaar" % (nodes.size() - seen.size()))
	return errs


## BST-orde per rankknoop (waarschuwingen, geen fout): bollen die buiten hun interval hangen.
func bst_warnings() -> PackedStringArray:
	var out := PackedStringArray()
	for x in nodes.keys():
		var n: TtNode = nodes[x]
		if n.type == NT.PACK and n.ball_root >= 0:
			_bst_check(n.ball_root, -1, alphabet.size(), out)
	return out


func _bst_check(b: int, lo_i: int, hi_i: int, out: PackedStringArray) -> void:
	if b < 0:
		return
	var n := node(b)
	var i := alphabet.index_of(n.ch)
	if i <= lo_i or i >= hi_i:
		out.append("bol %s (rankknoop %d) hangt buiten zijn plaats" % [n.ch, n.pack])
	_bst_check(n.lo, lo_i, mini(hi_i, i), out)
	_bst_check(n.hi, maxi(lo_i, i), hi_i, out)
