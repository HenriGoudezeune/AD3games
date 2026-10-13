class_name TtNotation
## Parse/serialize van de boomnotaties (GDD §5.1, §8.8). Spaties zijn optioneel.
##   trie      := "{" (LETTER trie_child)* "}"           trie_child := trie | "[" LABEL "]"
##   patricia  := "{" INT "|" (LETTER pat_child)* "}"    pat_child  := patricia | "[" LABEL "]"
##   ternary   := "(" LETTER t_side t_eq t_side ")"      t_side := "." | ternary      t_eq := ternary | "[" LABEL "]"
##   suffix    := "{" (edge)* "}"                        edge := "(" INT "," (INT|"it") ")" ( suffix | "#" INT )
## Geparste vormen:
##   trie/patricia: {"kids": {letter: sub}, ["skip": k]} of {"leaf": label}
##   ternary: {"ch", "lo", "eq", "hi"} (lo/hi = {} voor ".") of {"leaf": label}; lege boom = {}
##   suffix: {"edges": [{"b", "e", "child": {...}} | {"b", "e", "leaf_start": j}]}  (0-gebaseerd, e = TtCodes.OPEN voor "it")
## Bij een syntaxfout bevat het resultaat "error".


class _P:
	var s: String
	var i: int = 0
	var err: String = ""

	func _init(src: String) -> void:
		s = src

	func peek() -> String:
		return s[i] if i < s.length() else ""

	func take() -> String:
		var c := peek()
		i += 1
		return c

	func expect(c: String) -> bool:
		if peek() != c:
			if err == "":
				err = "verwacht '%s' op positie %d in %s" % [c, i, s]
			return false
		i += 1
		return true

	func read_int() -> int:
		var st := i
		if peek() == "-":
			i += 1
		while i < s.length() and s[i] >= "0" and s[i] <= "9":
			i += 1
		if st == i:
			if err == "":
				err = "getal verwacht op positie %d in %s" % [i, s]
			return 0
		return int(s.substr(st, i - st))

	func read_label() -> String:
		var st := i
		while i < s.length() and s[i] != "]":
			i += 1
		return s.substr(st, i - st)


static func normalize(s: String) -> String:
	return s.replace(" ", "").replace("\n", "").replace("\t", "")


# ---------------------------------------------------------------- trie / patricia

static func parse_trie(s: String) -> Dictionary:
	var p := _P.new(normalize(s))
	var d := _trie(p, false)
	if p.err == "" and p.i != p.s.length():
		p.err = "rest na einde: " + p.s.substr(p.i)
	if p.err != "":
		return {"error": p.err}
	return d


static func parse_patricia(s: String) -> Dictionary:
	var p := _P.new(normalize(s))
	var d := _trie(p, true)
	if p.err == "" and p.i != p.s.length():
		p.err = "rest na einde: " + p.s.substr(p.i)
	if p.err != "":
		return {"error": p.err}
	return d


static func _trie(p: _P, pat: bool) -> Dictionary:
	if p.peek() == "[":
		p.take()
		var lab := p.read_label()
		p.expect("]")
		return {"leaf": lab}
	var d := {"kids": {}}
	if not p.expect("{"):
		return d
	if pat:
		d["skip"] = p.read_int()
		p.expect("|")
	while p.err == "" and p.peek() != "}" and p.peek() != "":
		var letter := p.take()
		d.kids[letter] = _trie(p, pat)
	p.expect("}")
	return d


static func serialize_trie(d: Dictionary, alpha: TtAlphabet) -> String:
	if d.has("leaf"):
		return "[" + str(d.leaf) + "]"
	var parts := PackedStringArray()
	var kids: Dictionary = d.get("kids", {})
	for k in alpha.sorted(kids.keys()):
		parts.append(str(k) + serialize_trie(kids[k], alpha))
	var head := ("%d|" % int(d.skip)) if d.has("skip") else ""
	return "{" + head + " ".join(parts) + "}"


## Aantal interne toppen van een geparste trie/patricia.
static func count_inner(d: Dictionary) -> int:
	if d.has("leaf") or d.is_empty():
		return 0
	var n := 1
	for k in d.kids.keys():
		n += count_inner(d.kids[k])
	return n


## Labels van alle bladeren (alfabetisch gesorteerd).
static func leaves(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	_collect_leaves(d, out)
	out.sort()
	return out


static func _collect_leaves(d: Dictionary, out: PackedStringArray) -> void:
	if d.has("leaf"):
		out.append(str(d.leaf))
	elif d.has("kids"):
		for k in d.kids.keys():
			_collect_leaves(d.kids[k], out)
	elif d.has("ch"):
		_collect_leaves(d.lo, out)
		_collect_leaves(d.eq, out)
		_collect_leaves(d.hi, out)


# ---------------------------------------------------------------- ternary

static func parse_ternary(s: String) -> Dictionary:
	var ns := normalize(s)
	if ns == "" or ns == ".":
		return {}
	var p := _P.new(ns)
	var d := _tern(p)
	if p.err == "" and p.i != p.s.length():
		p.err = "rest na einde: " + p.s.substr(p.i)
	if p.err != "":
		return {"error": p.err}
	return d


static func _tern_side(p: _P) -> Dictionary:
	if p.peek() == ".":
		p.take()
		return {}
	return _tern(p)


static func _tern(p: _P) -> Dictionary:
	if p.peek() == "[":
		p.take()
		var lab := p.read_label()
		p.expect("]")
		return {"leaf": lab}
	if not p.expect("("):
		return {}
	var d := {"ch": p.take()}
	d["lo"] = _tern_side(p)
	d["eq"] = _tern(p)
	d["hi"] = _tern_side(p)
	p.expect(")")
	return d


static func serialize_ternary(d: Dictionary) -> String:
	if d.is_empty():
		return "."
	if d.has("leaf"):
		return "[" + str(d.leaf) + "]"
	return "(%s %s %s %s)" % [d.ch, serialize_ternary(d.lo), serialize_ternary(d.eq), serialize_ternary(d.hi)]


static func count_balls(d: Dictionary) -> int:
	if d.is_empty() or d.has("leaf"):
		return 0
	return 1 + count_balls(d.lo) + count_balls(d.eq) + count_balls(d.hi)


# ---------------------------------------------------------------- suffix

static func parse_suffix(s: String, pos_base: int) -> Dictionary:
	var p := _P.new(normalize(s))
	var d := _suf(p, pos_base)
	if p.err == "" and p.i != p.s.length():
		p.err = "rest na einde: " + p.s.substr(p.i)
	if p.err != "":
		return {"error": p.err}
	return d


static func _suf(p: _P, base: int) -> Dictionary:
	var d := {"edges": []}
	if not p.expect("{"):
		return d
	while p.err == "" and p.peek() == "(":
		p.take()
		var b := p.read_int() - base
		p.expect(",")
		var e := 0
		if p.s.substr(p.i, 2) == "it":
			p.i += 2
			e = TtCodes.OPEN
		else:
			e = p.read_int() - base
		p.expect(")")
		var edge := {"b": b, "e": e}
		if p.peek() == "#":
			p.take()
			edge["leaf_start"] = p.read_int() - base
		else:
			edge["child"] = _suf(p, base)
		d.edges.append(edge)
	p.expect("}")
	return d


## Serialiseert een geparste suffixboom; kinderen gesorteerd op eerste teken text[b].
static func serialize_suffix(d: Dictionary, pos_base: int, text: String, alpha: TtAlphabet) -> String:
	var edges: Array = d.get("edges", []).duplicate()
	edges.sort_custom(func(x, y): return alpha.index_of(text[int(x.b)]) < alpha.index_of(text[int(y.b)]))
	var parts := PackedStringArray()
	for ed in edges:
		var es := "it" if int(ed.e) == TtCodes.OPEN else str(int(ed.e) + pos_base)
		var head := "(%d,%s)" % [int(ed.b) + pos_base, es]
		if ed.has("leaf_start"):
			parts.append(head + "#" + str(int(ed.leaf_start) + pos_base))
		else:
			parts.append(head + serialize_suffix(ed.child, pos_base, text, alpha))
	return "{" + " ".join(parts) + "}"
