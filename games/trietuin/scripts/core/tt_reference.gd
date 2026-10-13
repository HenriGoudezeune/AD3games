class_name TtReference
## Onafhankelijke referentie-implementaties voor tests (naïef, zonder spelstaat; GDD §8.1).
## Werkt enkel op strings en geparste notaties (TtNotation), nooit op TtTreeModel.


## Minimale gewone trie van een woordenset (= resultaat van invoegen vanuit een lege wortel, in eender welke volgorde):
## een top bestaat voor elk echt gemeenschappelijk prefix van ≥ 2 woorden (en de wortel).
static func trie_dict(words: Array, depth: int = 0, is_root: bool = true) -> Dictionary:
	var uniq := {}
	for w in words:
		uniq[str(w)] = true
	var ws := uniq.keys()
	if ws.size() == 1 and not is_root:
		return {"leaf": ws[0]}
	var groups := {}
	for w in ws:
		var s: String = w
		var c := s[depth] if depth < s.length() else ""
		if not groups.has(c):
			groups[c] = []
		groups[c].append(s)
	var kids := {}
	for c in groups.keys():
		kids[c] = trie_dict(groups[c], depth + 1, false)
	return {"kids": kids}


static func trie_of(words: Array, alpha: TtAlphabet) -> String:
	return TtNotation.serialize_trie(trie_dict(words), alpha)


## Gewone trie → Patricia (snoeien van alle toppen met één kind; GDD §3.2).
static func patricia_dict(d: Dictionary) -> Dictionary:
	if d.has("leaf"):
		return {"leaf": d.leaf}
	var kids := {}
	for k in d.kids.keys():
		kids[k] = patricia_dict(d.kids[k])
	var own_skip := int(d.get("skip", 0))
	if kids.size() == 1:
		var only: Dictionary = kids.values()[0]
		if only.has("leaf"):
			return only
		only["skip"] = int(only.skip) + own_skip + 1
		return only
	return {"skip": own_skip, "kids": kids}


static func patricia_of(trie_notation: String, alpha: TtAlphabet) -> String:
	var d := patricia_dict(TtNotation.parse_trie(trie_notation))
	if d.has("leaf"):
		return "[" + str(d.leaf) + "]"
	return TtNotation.serialize_trie(d, alpha)


## Algoritme 1 (p. 29) op een geparste Patricia: {found, reads: [posities], end: "leaf"|"null"|"short"}
static func zoek_patricia(d: Dictionary, s: String) -> Dictionary:
	var m := s.length() - 1
	var nxt := 0
	var top := d
	var reads: Array = []
	while not top.has("leaf"):
		if nxt + int(top.skip) > m:
			return {"found": false, "reads": reads, "end": "short"}
		nxt = nxt + int(top.skip) + 1
		reads.append(nxt - 1)
		var c := s[nxt - 1]
		if not top.kids.has(c):
			return {"found": false, "reads": reads, "end": "null"}
		top = top.kids[c]
	return {"found": str(top.leaf) == s, "reads": reads, "end": "leaf"}


## Opzoeken in een geparste gewone trie: true als gevonden.
static func trie_has(d: Dictionary, s: String) -> bool:
	var top := d
	var dep := 0
	while not top.has("leaf"):
		if dep >= s.length() or not top.kids.has(s[dep]):
			return false
		top = top.kids[s[dep]]
		dep += 1
	return str(top.leaf) == s


# ------------------------------------------------------------------ ternary

## Ternary trie door invoegen (p. 31; GDD §3.3: bij een split eerst bol l_j, dan s_j). Muteert d (geparste vorm).
static func ternary_insert(d: Dictionary, s: String, alpha: TtAlphabet) -> Dictionary:
	if d.is_empty():
		return {"ch": s[0], "lo": {}, "eq": {"leaf": s}, "hi": {}}
	_tins(d, s, 0, alpha)
	return d


static func _tins(ball: Dictionary, s: String, dep: int, alpha: TtAlphabet) -> void:
	var b := ball
	while true:
		var c := alpha.compare(s[dep], str(b.ch))
		if c < 0:
			if b.lo.is_empty():
				b["lo"] = {"ch": s[dep], "lo": {}, "eq": {"leaf": s}, "hi": {}}
				return
			b = b.lo
		elif c > 0:
			if b.hi.is_empty():
				b["hi"] = {"ch": s[dep], "lo": {}, "eq": {"leaf": s}, "hi": {}}
				return
			b = b.hi
		else:
			if b.eq.has("leaf"):
				var l := str(b.eq.leaf)
				if l == s:
					return
				var j := dep + 1
				while j < mini(l.length(), s.length()) and l[j] == s[j]:
					j += 1
				# nieuwe rankknopen voor s_{dep+1} … s_{j−1}, laatste: eerst l_j dan s_j
				var lastb := {"ch": l[j], "lo": {}, "eq": {"leaf": l}, "hi": {}}
				var sb := {"ch": s[j], "lo": {}, "eq": {"leaf": s}, "hi": {}}
				if alpha.compare(s[j], l[j]) < 0:
					lastb["lo"] = sb
				else:
					lastb["hi"] = sb
				var sub := lastb
				for k in range(j - 1, dep, -1):
					sub = {"ch": s[k], "lo": {}, "eq": sub, "hi": {}}
				b["eq"] = sub
				return
			_tins(b.eq, s, dep + 1, alpha)
			return


static func ternary_of(words: Array, alpha: TtAlphabet) -> String:
	var d := {}
	for w in words:
		d = ternary_insert(d, str(w), alpha)
	return TtNotation.serialize_ternary(d)


## Aantal bezochte bollen bij het opzoeken van s.
static func ternary_comparisons(d: Dictionary, s: String, alpha: TtAlphabet) -> int:
	var b := d
	var dep := 0
	var n := 0
	while not b.is_empty() and not b.has("leaf"):
		n += 1
		if dep >= s.length():
			return n
		var c := alpha.compare(s[dep], str(b.ch))
		if c < 0:
			b = b.lo
		elif c > 0:
			b = b.hi
		else:
			b = b.eq
			dep += 1
	return n


# ------------------------------------------------------------------ suffixbomen

## Naïeve suffixboom (Θ(n²)): suffixen langste eerst, labelregel van GDD §3.4.3 (blad (j + l, n); splits
## (b, b+k−1)/(b+k, e)). Eigen boomvoorstelling (arrays), los van TtSuffixTree. -> TtNotation-suffixvorm.
static func suffix_naive_dict(text: String) -> Dictionary:
	var n := text.length() - 1
	# top: {"b","e","kids":[top...],"leaf":j or -1,"dep":stringdiepte}
	var rt := {"b": -1, "e": -1, "kids": [], "leaf": -1, "dep": 0}
	for j in range(text.length()):
		var cur := rt
		var i := j
		while true:
			var nxt = null
			for k in cur.kids:
				if text[int(k.b)] == text[i]:
					nxt = k
					break
			if nxt == null:
				cur.kids.append({"b": i, "e": n, "kids": [], "leaf": j, "dep": int(cur.dep) + n - i + 1})
				break
			var kk: Dictionary = nxt
			var ln := int(kk.e) - int(kk.b) + 1
			var m := 0
			while m < ln and text[int(kk.b) + m] == text[i + m]:
				m += 1
			if m == ln:
				cur = kk
				i += ln
				continue
			# splits na m tekens
			var mid := {"b": int(kk.b), "e": int(kk.b) + m - 1, "kids": [], "leaf": -1, "dep": int(cur.dep) + m}
			cur.kids.erase(kk)
			cur.kids.append(mid)
			kk["b"] = int(kk.b) + m
			mid.kids.append(kk)
			mid.kids.append({"b": i + m, "e": n, "kids": [], "leaf": j, "dep": int(mid.dep) + n - (i + m) + 1})
			break
	return _to_notation_dict(rt)


static func _to_notation_dict(t: Dictionary) -> Dictionary:
	var edges: Array = []
	for k in t.kids:
		if int(k.leaf) >= 0:
			edges.append({"b": int(k.b), "e": int(k.e), "leaf_start": int(k.leaf)})
		else:
			edges.append({"b": int(k.b), "e": int(k.e), "child": _to_notation_dict(k)})
	return {"edges": edges}


static func suffix_naive(text: String, alpha: TtAlphabet, pos_base: int = 0) -> String:
	return TtNotation.serialize_suffix(suffix_naive_dict(text), pos_base, text, alpha)


## Alle beginposities van z in text (naïef).
static func occurrences(text: String, z: String) -> Array[int]:
	var out: Array[int] = []
	if z == "":
		return out
	var i := text.find(z)
	while i != -1:
		out.append(i)
		i = text.find(z, i + 1)
	return out
