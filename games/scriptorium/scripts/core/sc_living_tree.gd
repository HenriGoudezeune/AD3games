class_name ScLivingTree extends ScTool
## Levende boom (GDD §3.4): adaptieve Huffman, Algoritme 10/11, zenden en ontvangen.
## Zenden: fase WRITE ({"act":"write","leaf":id}: het blad van het teken, of nng bij een nieuw teken), daarna GROW
## (automatisch) en CLIMB ({"act":"swap","with":id} of {"act":"keep"}). Ontvangen: fase READ ({"act":"read","leaf":id},
## gedwongen door de bits), daarna GROW/CLIMB. Het eerste teken van een lege boom gaat volledig automatisch.
## stage {"tool":"living_tree","side":"send","text":"graag","start":"empty"|"p90"}
##       {"tool":"living_tree","side":"receive","tokens":"\"n\"0\"o\"…","expect":"nooddaad"}

var start: String = "empty"
var tree: ScTree
var text: String = ""
var stream: Array = []          # ontvangen: "0", "1" of "\"x\""
var tokens_in: Array = []
var expect: String = ""
var i: int = 0                  # index van het teken in behandeling
var ch: String = ""             # het (echte) teken in behandeling
var t: int = -1                 # lantaarn (CLIMB)
var pos: int = 0                # ontvangen: positie in de stroom
var tokens_out: Array = []      # zenden
var char_tokens: Array = []     # zenden: tokens van het huidige teken
var copy_text: String = ""
var ok_state: Dictionary = {"tokens": [], "start": "empty"}
var ok_view: Dictionary = {}
var climbs: int = 0             # klimstappen van het huidige teken


func _setup() -> void:
	tool = ScCodes.Tool.LIVING_TREE
	start = str(stage.get("start", "empty"))
	tree = ScReference.adaptive_start(start)
	text = str(stage.get("text", ""))
	expect = str(stage.get("expect", ""))
	var tk = stage.get("tokens", [])
	tokens_in = ScReference.tokens_from_string(tk) if tk is String else (tk as Array).duplicate(true)
	stream = ScReference.flatten_tokens(tokens_in)
	i = 0
	ch = ""
	t = -1
	pos = 0
	tokens_out = []
	char_tokens = []
	copy_text = ""
	ok_state = {"tokens": [], "start": start}
	ok_view = {"text": "", "tree": tree.render(), "show": tree.show(), "stuck": false}
	climbs = 0


func _begin() -> void:
	if side == ScCodes.Side.SEND:
		if text == "":
			_finish()
			return
		if tree.root == tree.nng:
			ch = text[0]
			char_tokens = [{"raw": ch}]
			_write_tokens(char_tokens)
			_update_for(ch)
		else:
			phase = P.WRITE
			ch = text[0]
	else:
		if stream.is_empty():
			_finish()
			return
		if tree.root == tree.nng:
			var item := str(stream[0])
			if item.length() == 1:
				_unreadable()
				return
			pos = 1
			ch = ScReference.raw_char(item)
			copy_text += ch
			_copy_dirty = true
			_fx.append({"fx": "read_path", "leaf": tree.nng, "path": [tree.nng], "bits": "", "ch": ch, "raw": true})
			_update_for(ch)
		else:
			_next_read()


# ------------------------------------------------------------------ automatische stappen

func _write_tokens(toks: Array) -> void:
	tokens_out.append_array(toks.duplicate(true))
	_add_ink(ScReference.tokens_bits(toks))
	_fx.append({"fx": "write", "tokens": toks.duplicate(true)})
	_auto("WRITE_OUT", {"tokens": toks.duplicate(true)})


## Werkt de boom bij voor teken c: GROW (nieuw) of CLIMB vanaf het blad.
func _update_for(c: String) -> void:
	climbs = 0
	var leaf := tree.leaf_of(c)
	if leaf < 0:
		phase = P.GROW
		var g := ScReference.adaptive_grow(tree, c)
		_auto("GROW", {"ch": c, "o": int(g.o), "leaf": int(g.leaf), "nng": int(g.nng)},
				{"fx": "grow", "old_nng": int(g.old_nng), "o": int(g.o), "nng": int(g.nng), "leaf": int(g.leaf),
				"renumber": 2})
		if tree.parent(int(g.o)) < 0:
			_char_done()
			return
		t = tree.parent(int(g.o))
	else:
		t = leaf
	_climb_on()


## Gaat verder met klimmen: bij de wortel automatisch +1 en het teken is af; anders wacht CLIMB.
func _climb_on() -> void:
	if t == tree.root:
		tree.nodes[t].w = tree.w(t) + 1
		_fx.append({"fx": "weight", "node": t, "w": tree.w(t)})
		t = -1
		_char_done()
		return
	phase = P.CLIMB
	_fx.append({"fx": "lantern", "node": t})


func _char_done() -> void:
	t = -1
	var st := tree.stumbling()
	if not st.is_empty():
		_fx.append({"fx": "stumble", "nodes": st})
	if side == ScCodes.Side.SEND:
		var f := ScReader.adaptive_feed(ok_state, char_tokens)
		ok_state = f.state
		ok_view = {"text": f.text, "tree": f.tree, "show": f.show, "stuck": f.stuck}
		_overkant_dirty = true
		_fx.append({"fx": "overkant", "state": ok_view.duplicate(true)})
		char_tokens = []
		i += 1
		if i >= text.length():
			_finish()
		else:
			ch = text[i]
			phase = P.WRITE
	else:
		i += 1
		_next_read()


func _next_read() -> void:
	if pos >= stream.size():
		_finish()
		return
	if _match_leaf() < 0:
		_unreadable()
		return
	phase = P.READ


## Ontvangen: het blad waar de volgende bits naartoe leiden (−1 als de strook onleesbaar is).
func _match_leaf() -> int:
	var x := tree.root
	var q := pos
	while not tree.is_leaf(x):
		if q >= stream.size() or str(stream[q]).length() != 1:
			return -1
		x = tree.left(x) if str(stream[q]) == "0" else tree.right(x)
		q += 1
	if x == tree.nng and (q >= stream.size() or str(stream[q]).length() == 1):
		return -1
	return x


func _unreadable() -> void:
	copy_text += ScCodes.STUCK
	_copy_dirty = true
	_auto("UNREADABLE", {"pos": pos}, {"fx": "bump", "reason": "unreadable", "at": pos})
	_finish()


# ------------------------------------------------------------------ beoordelen

func _tstar() -> int:
	return ScReference.adaptive_tstar(tree, t) if t >= 0 else -1


func _should_keep() -> bool:
	var ts := _tstar()
	return ts == t or ts == tree.parent(t)


func _correct_leaf() -> int:
	var lf := tree.leaf_of(ch)
	return lf if lf >= 0 else tree.nng


func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"write":
			if phase != P.WRITE or side != ScCodes.Side.SEND:
				return {"ok": false, "reason": "wrong_phase"}
			var id := int(move.get("leaf", -1))
			if not tree.alive(id):
				return {"ok": false, "reason": "range"}
			if not tree.is_leaf(id):
				return {"ok": false, "reason": "not_leaf", "at": id}
			var cl := _correct_leaf()
			var data := {"leaf": id, "x": ch, "code": tree.code(cl) + ("+\"" + ch + "\"" if cl == tree.nng else ""),
				"new": cl == tree.nng, "chosen": tree.sym(id)}
			return {"ok": true, "verdict": V.OK if id == cl else V.WRONG_LEAF, "type": "WRITE", "data": data}
		"read":
			if phase != P.READ or side != ScCodes.Side.RECEIVE:
				return {"ok": false, "reason": "wrong_phase"}
			var id2 := int(move.get("leaf", -1))
			if not tree.alive(id2):
				return {"ok": false, "reason": "range"}
			if not tree.is_leaf(id2):
				return {"ok": false, "reason": "not_leaf", "at": id2}
			if id2 != _match_leaf():
				return {"ok": false, "reason": "no_path", "at": id2}
			return {"ok": true, "verdict": V.OK, "type": "READ", "data": {"leaf": id2}}
		"swap", "keep":
			if phase != P.CLIMB:
				return {"ok": false, "reason": "wrong_phase"}
			var ts := _tstar()
			var data2 := {"t": tree.label(t), "w": tree.w(t), "t2": tree.label(ts), "o1": tree.num(t), "o2": tree.num(ts),
				"should_keep": _should_keep(), "parent": ts == tree.parent(t) and ts != t}
			if act == "keep":
				return {"ok": true, "verdict": V.OK if _should_keep() else V.MISSED_SWAP, "type": "KEEP", "data": data2}
			var id3 := int(move.get("with", -1))
			if not tree.alive(id3):
				return {"ok": false, "reason": "range"}
			if id3 == t:
				return {"ok": false, "reason": "self", "at": id3}
			if tree.is_ancestor(id3, t) or tree.is_ancestor(t, id3):
				return {"ok": false, "reason": "ancestor", "at": id3, "data": {"parent": id3 == tree.parent(t)}}
			data2["with"] = id3
			data2["chosen"] = tree.label(id3)
			var ok := not _should_keep() and id3 == ts
			return {"ok": true, "verdict": V.OK if ok else V.WRONG_SWAP, "type": "SWAP", "data": data2}
	return {"ok": false, "reason": "unknown_act"}


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	match str(move.get("act", "")):
		"write":
			var id := int(j.data.leaf)
			var toks: Array = []
			var c := tree.code(id)
			if c != "":
				toks.append({"b": c})
			if id == tree.nng:
				toks.append({"raw": ch})
			char_tokens = toks
			_fx.append({"fx": "read_path", "leaf": id, "path": tree.path(id), "bits": c, "ch": tree.sym(id),
				"write": true})
			_write_tokens(toks)
			_update_for(ch)
		"read":
			var id2 := int(j.data.leaf)
			var c2 := tree.code(id2)
			pos += c2.length()
			var rch := tree.sym(id2)
			var raw := false
			if id2 == tree.nng:
				rch = ScReference.raw_char(str(stream[pos]))
				pos += 1
				raw = true
			ch = rch
			copy_text += rch
			_copy_dirty = true
			_fx.append({"fx": "read_path", "leaf": id2, "path": tree.path(id2), "bits": c2, "ch": rch, "raw": raw})
			_update_for(rch)
		"swap":
			var other := int(j.data.with)
			_fx.append({"fx": "swap", "a": t, "b": other})
			tree.swap(t, other)
			_step_up()
		"keep":
			_step_up()


func _step_up() -> void:
	climbs += 1
	tree.nodes[t].w = tree.w(t) + 1
	_fx.append({"fx": "weight", "node": t, "w": tree.w(t)})
	t = tree.parent(t)
	_climb_on()


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	match phase:
		P.WRITE:
			return {"act": "write", "leaf": _correct_leaf()}
		P.READ:
			var m := _match_leaf()
			return {"act": "read", "leaf": m} if m >= 0 else {"act": "none"}
		P.CLIMB:
			if _should_keep():
				return {"act": "keep"}
			return {"act": "swap", "with": _tstar()}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.WRITE:
			var cl := _correct_leaf()
			for x in tree.leaves():
				if x != cl:
					out.append({"act": "write", "leaf": x})
		P.CLIMB:
			if not _should_keep():
				out.append({"act": "keep"})
			var ts := _tstar()
			for x in tree.procession():
				if x != t and x != ts and not tree.is_ancestor(x, t) and not tree.is_ancestor(t, x):
					out.append({"act": "swap", "with": x})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.WRITE:
			for x in tree.ids():
				if not tree.is_leaf(x):
					out.append({"act": "write", "leaf": x})
			out.append({"act": "keep"})
		P.READ:
			var m := _match_leaf()
			for x in tree.ids():
				if x != m:
					out.append({"act": "read", "leaf": x})
		P.CLIMB:
			out.append({"act": "swap", "with": t})
			var a := tree.parent(t)
			while a >= 0:
				out.append({"act": "swap", "with": a})
				a = tree.parent(a)
			out.append({"act": "write", "leaf": tree.leaves()[0]})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return i


func copy() -> String:
	return copy_text


func overkant() -> Dictionary:
	return ok_view.duplicate(true) if side == ScCodes.Side.SEND else {}


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": copy_text}
	return {"kind": "tokens", "tokens": tokens_out.duplicate(true), "ink": int(counters.ink), "start": start,
		"string": ScReference.tokens_to_string(tokens_out)}


func structure() -> Dictionary:
	return {"tree": tree.show()}


func procession() -> Array:
	var out: Array = []
	for x in tree.procession():
		out.append({"id": x, "num": tree.num(x), "w": tree.w(x), "sym": tree.sym(x)})
	return out


func _cursor() -> Dictionary:
	var sw: Array = []
	if t >= 0:
		for x in tree.ids():
			if tree.w(x) == tree.w(t):
				sw.append(x)
	return {"i": i, "ch": ch, "t": t, "tstar": _tstar(), "same_weight": sw, "tree": tree.render(), "show": tree.show(),
		"procession": procession(), "out": ScReference.tokens_to_string(tokens_out), "pos": pos, "copy": copy_text,
		"side": side, "text": text, "climbs": climbs}


func _snap() -> Dictionary:
	return {"tree": tree.snapshot(), "i": i, "ch": ch, "t": t, "pos": pos, "tokens_out": tokens_out.duplicate(true),
		"char_tokens": char_tokens.duplicate(true), "copy": copy_text, "ok_state": ok_state.duplicate(true),
		"ok_view": ok_view.duplicate(true), "climbs": climbs}


func _restore(d: Dictionary) -> void:
	tree.restore(d.get("tree", {}))
	i = int(d.get("i", 0))
	ch = str(d.get("ch", ""))
	t = int(d.get("t", -1))
	pos = int(d.get("pos", 0))
	tokens_out = _toks(d.get("tokens_out", []))
	char_tokens = _toks(d.get("char_tokens", []))
	copy_text = str(d.get("copy", ""))
	var os: Dictionary = d.get("ok_state", {})
	ok_state = {"tokens": _toks(os.get("tokens", [])), "start": str(os.get("start", start))}
	ok_view = d.get("ok_view", {})
	climbs = int(d.get("climbs", 0))


static func _toks(a: Array) -> Array:
	var out: Array = []
	for x in a:
		if (x as Dictionary).has("raw"):
			out.append({"raw": str(x.raw)})
		else:
			out.append({"b": str(x.b)})
	return out


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for x in tree.ids():
		if not tree.is_leaf(x) and tree.w(x) != tree.w(tree.left(x)) + tree.w(tree.right(x)):
			if x != t and not (t >= 0 and tree.is_ancestor(x, t)):
				e.append("(a) in %s" % tree.label(x))
	var nums := {}
	for x in tree.ids():
		nums[tree.num(x)] = true
	for k in range(1, tree.size() + 1):
		if not nums.has(k):
			e.append("ordenummer %d ontbreekt" % k)
			break
	if side == ScCodes.Side.SEND and ScReference.tokens_bits(tokens_out) != int(counters.ink):
		e.append("inkt %d ≠ bits %d" % [int(counters.ink), ScReference.tokens_bits(tokens_out)])
	return e
