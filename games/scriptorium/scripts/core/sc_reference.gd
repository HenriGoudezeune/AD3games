class_name ScReference
## Onafhankelijke referenties die de lesnotas (hoofdstuk 4) letterlijk volgen (GDD §8.3). Static en puur.
## Bron voor het orakel, de geesten, Broeder Letterlijk (ScReader) en de tests.
## Conventies: posities 0-gebaseerd; links = 0; LZW-codes = Unicode-waarde (ASCII), nieuwe codes vanaf 256;
## exacte getallen met ScDec.

const NNG := ScCodes.NNG
const EOF := ScCodes.EOF


# ================================================================== prefixcodes (Definitie 20, p. 82–84)

## Geen codewoord is het begin van een ander (en geen twee gelijke, geen leeg woord).
static func is_prefix_code(code: Dictionary) -> bool:
	var words: Array = code.values()
	for a in words:
		if str(a) == "":
			return false
		for b in words:
			if a != b and str(b).begins_with(str(a)):
				return false
	var seen := {}
	for a in words:
		if seen.has(str(a)):
			return false
		seen[str(a)] = true
	return true


## {woord: symbool}
static func inverse(code: Dictionary) -> Dictionary:
	var inv := {}
	for k in code:
		inv[str(code[k])] = str(k)
	return inv


## Lees bit per bit tot het gelezene een codewoord is (p. 83). {text, symbols, cuts (posities na elk woord), rest}.
static func decode_prefix(code: Dictionary, bits: String) -> Dictionary:
	var inv := inverse(code)
	var text := ""
	var syms: Array = []
	var cuts: Array[int] = []
	var cur := ""
	for i in bits.length():
		cur += bits[i]
		if inv.has(cur):
			text += str(inv[cur])
			syms.append(str(inv[cur]))
			cuts.append(i + 1)
			cur = ""
	return {"text": text, "symbols": syms, "cuts": cuts, "rest": cur}


## Alle ontledingen van bits in codewoorden, met hun knippen: [{text, cuts}] (diepte eerst, korte woorden eerst).
static func all_parses_cuts(code: Dictionary, bits: String) -> Array:
	var inv := inverse(code)
	var res: Array = []
	_parses(inv, bits, 0, "", [], res)
	return res


static func _parses(inv: Dictionary, bits: String, i: int, acc: String, cuts: Array, res: Array) -> void:
	if i == bits.length():
		res.append({"text": acc, "cuts": cuts.duplicate()})
		return
	for j in range(i + 1, bits.length() + 1):
		var wd := bits.substr(i, j - i)
		if inv.has(wd):
			cuts.append(j)
			_parses(inv, bits, j, acc + str(inv[wd]), cuts, res)
			cuts.pop_back()


static func all_parses(code: Dictionary, bits: String) -> PackedStringArray:
	var out := PackedStringArray()
	for p in all_parses_cuts(code, bits):
		out.append(str(p.text))
	return out


## Broeder Letterlijk (spelafspraak §3.2): telkens het kortste codewoord dat hij herkent; "…" als er een rest blijft.
static func greedy_read(code: Dictionary, bits: String) -> String:
	var d := decode_prefix(code, bits)
	return str(d.text) + (ScCodes.STUCK if str(d.rest) != "" else "")


static func encode_with(code: Dictionary, symbols) -> String:
	var out := ""
	for s in symbols:
		out += str(code.get(str(s), ""))
	return out


## Σ a(x)·l(x) van een code voor gegeven frequenties [[sym, a]].
static func code_cost(code: Dictionary, freqs: Array) -> int:
	var c := 0
	for f in freqs:
		c += int(f[1]) * str(code.get(str(f[0]), "")).length()
	return c


# ================================================================== Huffman (Algoritme 9, Stelling 21, p. 84–88)

## [[sym, a(sym)]] in volgorde van eerste voorkomen (of in de volgorde van `order`).
static func freqs_in_order(text: String, order := "") -> Array:
	var syms: Array = []
	for ch in text:
		syms.append(ch)
	var ord: Array = []
	for ch in order:
		ord.append(ch)
	return freqs_of(syms, ord)


## Idem voor een rij symbolen (strings; Codex: de move-to-front-getallen).
static func freqs_of(symbols: Array, order: Array = []) -> Array:
	var cnt := {}
	var first: Array = []
	for s in symbols:
		var k := str(s)
		if not cnt.has(k):
			cnt[k] = 0
			first.append(k)
		cnt[k] = int(cnt[k]) + 1
	var ord: Array = order if not order.is_empty() else first
	var out: Array = []
	for k in ord:
		out.append([str(k), int(cnt.get(str(k), 0))])
	return out


static func _wt(x) -> int:
	if x is Dictionary:
		return int(x.w)
	if x is Array:
		return int(x[1])
	return int(x)


## Alle ongeordende paren [i, j] (i < j) die Algoritme 9 toelaat: X met het kleinste gewicht, Y het kleinste van de rest.
static func valid_pairs(weights: Array) -> Array:
	var ws: Array[int] = []
	for x in weights:
		ws.append(_wt(x))
	var res: Array = []
	if ws.size() < 2:
		return res
	var m: int = ws.min()
	var seen := {}
	for i in ws.size():
		if ws[i] != m:
			continue
		var m2 := -1
		for q in ws.size():
			if q != i and (m2 < 0 or ws[q] < m2):
				m2 = ws[q]
		for j in ws.size():
			if j != i and ws[j] == m2:
				var a := mini(i, j)
				var b := maxi(i, j)
				var key := "%d,%d" % [a, b]
				if not seen.has(key):
					seen[key] = true
					res.append([a, b])
	res.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
	return res


static func is_valid_pair(weights: Array, i: int, j: int) -> bool:
	var a := mini(i, j)
	var b := maxi(i, j)
	for p in valid_pairs(weights):
		if int(p[0]) == a and int(p[1]) == b:
			return true
	return false


## De twee-plankenregel (Oef. 85; reproduceert p. 85): sleutel (gewicht, 0 = bundel / 1 = losse stapel,
## ontstaansvolgorde van de bundel / rijpositie). row: [{w, born}] (born −1 = losse stapel) of gewichten.
## → [i, j]: X = minimum, Y = minimum van de rest.
static func canonical_pair(row: Array) -> Array:
	var keys: Array = []
	for q in row.size():
		var x = row[q]
		var born := -1
		if x is Dictionary:
			born = int(x.get("born", -1))
		var bundle := born >= 0
		keys.append([_wt(x), 0 if bundle else 1, born if bundle else q])
	var i := _argmin(keys, -1)
	var j := _argmin(keys, i)
	return [i, j]


static func _argmin(keys: Array, skip: int) -> int:
	var best := -1
	for q in keys.size():
		if q == skip:
			continue
		if best < 0 or _key_less(keys[q], keys[best]):
			best = q
	return best


static func _key_less(a: Array, b: Array) -> bool:
	for t in a.size():
		if int(a[t]) != int(b[t]):
			return int(a[t]) < int(b[t])
	return false


## Algoritme 9 met de twee-plankenregel (of met de gegeven keuzes, daarna de regel).
## row: [[sym, w]]. → {tree: ScTree, render, show, codes, cost, steps:[{row_labels, i, j, w}]}
## Bundel op de plaats van de meest linkse van de twee; kinderen in rijvolgorde (links = 0).
static func huffman(row: Array, choices: Array = []) -> Dictionary:
	var t := ScTree.new()
	var ids: Array[int] = []
	var born: Array[int] = []
	var labels: Array[String] = []
	for x in row:
		ids.append(t.add_node(int(x[1]), str(x[0])))
		born.append(-1)
		labels.append(str(x[0]))
	var steps: Array = []
	var k := 0
	var nb := 0
	while ids.size() > 1:
		var ij: Array
		if k < choices.size():
			ij = choices[k]
		else:
			var r: Array = []
			for q in ids.size():
				r.append({"w": t.w(ids[q]), "born": born[q]})
			ij = canonical_pair(r)
		var i := int(ij[0])
		var j := int(ij[1])
		var a := mini(i, j)
		var b := maxi(i, j)
		var rl: Array[String] = []
		for q in ids.size():
			rl.append("%s:%d" % [labels[q], t.w(ids[q])])
		var z := t.add_node(t.w(ids[a]) + t.w(ids[b]))
		t.set_children(z, ids[a], ids[b])
		steps.append({"row_labels": rl, "i": i, "j": j, "w": t.w(z)})
		var lab := "(" + labels[a] + labels[b] + ")"
		ids[a] = z
		born[a] = nb
		labels[a] = lab
		nb += 1
		ids.remove_at(b)
		born.remove_at(b)
		labels.remove_at(b)
		k += 1
	if ids.size() == 1:
		t.root = ids[0]
	var codes := t.codes()
	if ids.size() == 1 and t.is_leaf(t.root):
		codes = {t.sym(t.root): "0"}
	return {"tree": t, "render": t.render(), "show": t.show(), "codes": codes, "cost": t.internal_sum(),
		"steps": steps}


## Minimale kost Σ a(x)·l(x) (twee kleinste samenvoegen).
static func huffman_cost(weights: Array) -> int:
	var ws: Array[int] = []
	for x in weights:
		ws.append(_wt(x))
	var tot := 0
	while ws.size() > 1:
		ws.sort()
		var s: int = ws[0] + ws[1]
		tot += s
		ws.remove_at(0)
		ws[0] = s
	return tot


## Exhaustief: aantal geldige keuzereeksen, verschillende lengteprofielen ({sym: lengte}) en de verzameling kosten.
static func huffman_runs(row: Array) -> Dictionary:
	var items: Array = []
	for x in row:
		items.append({"w": int(x[1]), "syms": {str(x[0]): 0}})
	var acc := {"runs": 0, "profiles": {}, "costs": {}}
	_runs(items, 0, acc)
	return {"runs": int(acc.runs), "profiles": (acc.profiles as Dictionary).size(), "costs": (acc.costs as Dictionary).keys()}


static func _runs(items: Array, cost: int, acc: Dictionary) -> void:
	if items.size() <= 1:
		acc.runs = int(acc.runs) + 1
		var prof: Array = []
		var d: Dictionary = items[0].syms if items.size() == 1 else {}
		var ks := d.keys()
		ks.sort()
		for k in ks:
			prof.append("%s=%d" % [k, int(d[k])])
		acc.profiles[",".join(prof)] = true
		acc.costs[cost] = true
		return
	for p in valid_pairs(items):
		var a: int = p[0]
		var b: int = p[1]
		var syms := {}
		for k in items[a].syms:
			syms[k] = int(items[a].syms[k]) + 1
		for k in items[b].syms:
			syms[k] = int(items[b].syms[k]) + 1
		var z := {"w": int(items[a].w) + int(items[b].w), "syms": syms}
		var nx := items.duplicate()
		nx[a] = z
		nx.remove_at(b)
		_runs(nx, cost + int(z.w), acc)


# ================================================================== adaptieve Huffman (Algoritme 10/11, p. 89–98)

## De lege boom: enkel nng [0,1].
static func adaptive_empty() -> ScTree:
	var t := ScTree.new()
	t.root = t.add_node(0, NNG, 1)
	t.nng = t.root
	return t


## De [g,o]-boom van p. 90 (boosdoeer, zonder nng).
static func p90_tree() -> ScTree:
	return ScTree.from_spec([9, 11, [4, 9, [2, 5, [1, 1, "b"], [1, 2, "s"]], [2, 6, [1, 3, "d"], [1, 4, "r"]]],
		[5, 10, [2, 7, "e"], [3, 8, "o"]]])


static func adaptive_start(start: String) -> ScTree:
	return p90_tree() if start == "p90" else adaptive_empty()


## Nieuw teken (p. 95): nng → o met kinderen nng (links, nr 1) en het nieuwe blad (rechts, nr 2), o nr 3, a(o) = 1;
## alle andere ordenummers +2. → {old_nng, o, nng, leaf}
static func adaptive_grow(t: ScTree, ch: String) -> Dictionary:
	var old := t.nng
	for x in t.ids():
		t.nodes[x].num = t.num(x) + 2
	var p := t.parent(old)
	var o := t.add_node(1, "", 3)
	var nn := t.add_node(0, NNG, 1)
	var leaf := t.add_node(1, ch, 2)
	t.set_children(o, nn, leaf)
	t.nodes[o].p = p
	if p < 0:
		t.root = o
	elif t.left(p) == old:
		t.nodes[p].l = o
	else:
		t.nodes[p].r = o
	t.kill(old)
	t.nng = nn
	return {"old_nng": old, "o": o, "nng": nn, "leaf": leaf}


## t′ = de top x met a(x) = a(t) en o(x) maximaal.
static func adaptive_tstar(t: ScTree, node: int) -> int:
	return t.max_num_with_weight(t.w(node))


## Algoritme 11 voor teken ch. → [{kind:"grow", …} | {kind:"swap"|"keep"|"keep_parent", t, t2} | {kind:"root", t}]
static func adaptive_update(t: ScTree, ch: String) -> Array:
	var steps: Array = []
	var cur := t.leaf_of(ch)
	if cur < 0:
		var g := adaptive_grow(t, ch)
		g["kind"] = "grow"
		steps.append(g)
		if t.parent(int(g.o)) < 0:
			return steps
		cur = t.parent(int(g.o))
	while cur != t.root:
		var t2 := adaptive_tstar(t, cur)
		if t2 == cur:
			steps.append({"kind": "keep", "t": cur, "t2": t2})
		elif t2 == t.parent(cur):
			steps.append({"kind": "keep_parent", "t": cur, "t2": t2})
		else:
			steps.append({"kind": "swap", "t": cur, "t2": t2})
			t.swap(cur, t2)
		t.nodes[cur].w = t.w(cur) + 1
		cur = t.parent(cur)
	t.nodes[cur].w = t.w(cur) + 1
	steps.append({"kind": "root", "t": cur})
	return steps


## Coderen (p. 92–96): eerst schrijven met de boom vóór de wijziging, dan Algoritme 11. Het eerste teken van een lege
## boom gaat ruw (de code van nng is dan leeg). → {tokens, bits, steps:[{ch, tokens, kind, log, tree}], tree}
static func adaptive_encode(text: String, start := "empty") -> Dictionary:
	var t := adaptive_start(start)
	var tokens: Array = []
	var steps: Array = []
	for ch in text:
		var toks: Array = []
		var leaf := t.leaf_of(ch)
		var kind := "known"
		if leaf >= 0:
			toks.append({"b": t.code(leaf)})
		else:
			kind = "new"
			var c := t.code(t.nng)
			if c != "":
				toks.append({"b": c})
			toks.append({"raw": ch})
		tokens.append_array(toks)
		var log := adaptive_update(t, ch)
		steps.append({"ch": ch, "tokens": toks, "kind": kind, "log": log, "tree": t.show()})
	return {"tokens": tokens, "bits": tokens_bits(tokens), "steps": steps, "tree": t}


## Decoderen (p. 98): lezen tot een blad (nng: de ruwe letter erna), dan dezelfde wijziging.
## Robuust: raken de bits op of staat er een lakzegel midden in een pad, dan stuck = true en de tekst eindigt op "…".
static func adaptive_decode(tokens: Array, start := "empty", limit := 1000) -> Dictionary:
	var t := adaptive_start(start)
	var st := flatten_tokens(tokens)
	var i := 0
	var text := ""
	var steps: Array = []
	var stuck := false
	while i < st.size() and text.length() < limit:
		var x := t.root
		var bits := ""
		var bad := false
		while not t.is_leaf(x):
			if i >= st.size() or str(st[i]).length() != 1:
				bad = true
				break
			bits += str(st[i])
			x = t.left(x) if str(st[i]) == "0" else t.right(x)
			i += 1
		if bad:
			stuck = true
			break
		var ch := t.sym(x)
		if x == t.nng:
			if i >= st.size() or str(st[i]).length() == 1:
				stuck = true
				break
			ch = raw_char(str(st[i]))
			i += 1
		var log := adaptive_update(t, ch)
		text += ch
		steps.append({"bits": bits, "ch": ch, "log": log, "tree": t.show()})
	if stuck:
		text += ScCodes.STUCK
	return {"text": text, "stuck": stuck, "steps": steps, "tree": t}


## Tokens → stroom van "0", "1" en ruwe letters als "\"x\"".
static func flatten_tokens(tokens: Array) -> Array:
	var out: Array = []
	for tk in tokens:
		if tk is Dictionary and tk.has("raw"):
			out.append("\"" + str(tk.raw) + "\"")
		elif tk is Dictionary and tk.has("b"):
			for ch in str(tk.b):
				out.append(ch)
	return out


static func raw_char(item: String) -> String:
	return item.substr(1, item.length() - 2)


## '"n"0"o"0100…' → tokens (bits gegroepeerd tussen de lakzegels).
static func tokens_from_string(s: String) -> Array:
	var out: Array = []
	var i := 0
	var bits := ""
	while i < s.length():
		var ch := s[i]
		if ch == "\"":
			if bits != "":
				out.append({"b": bits})
				bits = ""
			out.append({"raw": s[i + 1]})
			i += 3
			continue
		if ch == "0" or ch == "1":
			bits += ch
		i += 1
	if bits != "":
		out.append({"b": bits})
	return out


static func tokens_to_string(tokens: Array) -> String:
	var s := ""
	for tk in tokens:
		if tk.has("raw"):
			s += "\"" + str(tk.raw) + "\""
		else:
			s += str(tk.b)
	return s


## Bits: elke bit 1, elke ruwe letter RAW_BITS.
static func tokens_bits(tokens: Array) -> int:
	var n := 0
	for tk in tokens:
		if tk.has("raw"):
			n += ScCodes.RAW_BITS
		else:
			n += str(tk.b).length()
	return n


# ================================================================== aritmetisch coderen (Algoritme 12/13, p. 98–104)

## model [[sym, "0.2"], …] → [{sym, p:ScDec, f:ScDec}] (f = Σ van de kansen ervoor).
static func parse_model(model: Array) -> Array:
	var out: Array = []
	var acc := ScDec.zero()
	for m in model:
		var p: ScDec = m[1] if m[1] is ScDec else ScDec.from_string(str(m[1]))
		out.append({"sym": str(m[0]), "p": p, "f": acc})
		acc = acc.add(p)
	return out


static func model_syms(model: Array) -> Array:
	var out: Array = []
	for m in model:
		out.append(str(m[0]))
	return out


## De vakken van het interval [links, links+lengte): [{sym, lo, hi}] in modelvolgorde.
static func segments(links: ScDec, lengte: ScDec, model: Array) -> Array:
	var out: Array = []
	for m in parse_model(model):
		var lo := links.add((m.f as ScDec).mul(lengte))
		var hi := lo.add((m.p as ScDec).mul(lengte))
		out.append({"sym": m.sym, "lo": lo, "hi": hi})
	return out


## Algoritme 12. → {low, up, len, book:[{i, sym, links, lengte}]} (ScDec)
static func get_interval(text: String, model: Array) -> Dictionary:
	var pm := parse_model(model)
	var by := {}
	for m in pm:
		by[m.sym] = m
	var links := ScDec.zero()
	var lengte := ScDec.one()
	var book: Array = []
	for i in text.length():
		var m: Dictionary = by[text[i]]
		links = links.add((m.f as ScDec).mul(lengte))
		lengte = lengte.mul(m.p)
		book.append({"i": i, "sym": text[i], "links": links, "lengte": lengte})
	return {"low": links, "up": links.add(lengte), "len": lengte, "book": book}


## Algoritme 13: kortste bitstring met een waarde in [low, up). trace: [{getal (na de stap), next (gebruikt), bit}].
static func get_bitstring(low: ScDec, up: ScDec) -> Dictionary:
	if low.is_zero():
		return {"bits": "0", "trace": [{"getal": ScDec.zero(), "next": ScDec.one().half(), "bit": 0, "low0": true}]}
	var getal := ScDec.zero()
	var nxt := ScDec.one().half()
	var bits := ""
	var trace: Array = []
	var guard := 0
	while guard < 4000:
		guard += 1
		if getal.add(nxt).lt(up):
			bits += "1"
			getal = getal.add(nxt)
			trace.append({"getal": getal, "next": nxt, "bit": 1})
			if getal.ge(low):
				break
		else:
			bits += "0"
			trace.append({"getal": getal, "next": nxt, "bit": 0})
		nxt = nxt.half()
	return {"bits": bits, "trace": trace}


## Decoderen (Oef. 94/95): telkens het vak [lo, hi) dat r bevat. bits_or_pin: bitstring of ScDec (of "0.9"-string
## met een punt/komma). → {text, trace:[{sym, lo, hi}], stuck}
static func arith_decode(bits_or_pin, n: int, model: Array) -> Dictionary:
	var r: ScDec
	if bits_or_pin is ScDec:
		r = bits_or_pin
	elif str(bits_or_pin).contains(".") or str(bits_or_pin).contains(","):
		r = ScDec.from_string(str(bits_or_pin))
	else:
		r = ScDec.from_bits(str(bits_or_pin))
	var links := ScDec.zero()
	var lengte := ScDec.one()
	var text := ""
	var trace: Array = []
	for _k in n:
		var found := false
		for sg in segments(links, lengte, model):
			if (sg.lo as ScDec).le(r) and r.lt(sg.hi):
				text += str(sg.sym)
				trace.append(sg)
				links = sg.lo
				lengte = (sg.hi as ScDec).sub(sg.lo)
				found = true
				break
		if not found:
			return {"text": text + ScCodes.STUCK, "trace": trace, "stuck": true}
	return {"text": text, "trace": trace, "stuck": false}


## Lemma 24: ⌈log₂(1/l)⌉ = de kleinste k met 2^(−k) ≤ l.
static func lemma24_bound(lengte: ScDec) -> int:
	var k := 0
	var p := ScDec.one()
	while p.gt(lengte) and k < 4000:
		p = p.half()
		k += 1
	return k


# ================================================================== LZ77 (Algoritme 14, p. 104–110)

static func window_start(k: int, G: int) -> int:
	return 0 if G < 0 else maxi(0, k - G)


## Lengte van de match vanaf bronpositie src (absoluut) met text[k…]; de bron mag voorbij k lopen.
static func match_len(text: String, src: int, k: int) -> int:
	var l := 0
	while k + l < text.length() and text[src + l] == text[k + l]:
		l += 1
	return l


## Langste matches bij k: {best, alts (raamposities met de maximale lengte; leeg als best = 0)}.
static func lz77_best(text: String, k: int, G: int) -> Dictionary:
	var ws := window_start(k, G)
	var best := 0
	var alts: Array[int] = []
	for p in k - ws:
		var l := match_len(text, ws + p, k)
		if l > best:
			best = l
			alts = [p]
		elif l == best and l > 0:
			alts.append(p)
	return {"best": best, "alts": alts}


## Zoekwerk zonder register (§4.3.1): Σ over p in het raam: lengte van de match + 1 (geen +1 als de tekst eindigde).
static func lz77_scan_cost(text: String, k: int, G: int) -> int:
	var ws := window_start(k, G)
	var c := 0
	for p in k - ws:
		var l := match_len(text, ws + p, k)
		c += l
		if k + l < text.length():
			c += 1
	return c


## G = −1: oneindig raam. → {triples:[[p,l,x]], info:[{k, ws, window, alts, scan}]}
static func lz77_encode(text: String, G: int) -> Dictionary:
	var k := 0
	var triples: Array = []
	var info: Array = []
	while k < text.length():
		var ws := window_start(k, G)
		var b := lz77_best(text, k, G)
		var l := int(b.best)
		var p: int = 0 if l == 0 else int((b.alts as Array)[0])
		var x: String = text[k + l] if k + l < text.length() else EOF
		triples.append([p, l, x])
		info.append({"k": k, "ws": ws, "window": text.substr(ws, k - ws), "alts": b.alts, "scan": lz77_scan_cost(text, k, G)})
		k += l + 1
	return {"triples": triples, "info": info}


## → {text, windows (raam na elk drietal), stuck}. Een bron buiten de tekst maakt de strook onleesbaar.
static func lz77_decode_full(triples: Array, G: int) -> Dictionary:
	var s := ""
	var windows: Array = []
	for tr in triples:
		var p := int(tr[0])
		var l := int(tr[1])
		var x := str(tr[2])
		var ws := window_start(s.length(), G)
		var start := ws + p
		if l > 0 and (p < 0 or start >= s.length()):
			return {"text": s + ScCodes.STUCK, "windows": windows, "stuck": true}
		for i in l:
			s += s[start + i]
		if x != EOF:
			s += x
		windows.append(s.substr(window_start(s.length(), G)))
	return {"text": s, "windows": windows, "stuck": false}


static func lz77_decode(triples: Array, G: int) -> String:
	return str(lz77_decode_full(triples, G).text)


# ================================================================== LZW (p. 110–115)

static func lzw_code_of(ch: String) -> int:
	return ch.unicode_at(0)


## → {codes, adds:[[code, word]], steps:["extend"|"stamp"]} (geen stap voor het eerste teken en de slotstempel)
static func lzw_encode(text: String) -> Dictionary:
	var dict := {}
	var nxt := ScCodes.LZW_FIRST
	var codes: Array[int] = []
	var adds: Array = []
	var steps: Array[String] = []
	if text == "":
		return {"codes": codes, "adds": adds, "steps": steps}
	var w := text[0]
	for i in range(1, text.length()):
		var k := text[i]
		var wk := w + k
		if wk.length() == 1 or dict.has(wk):
			w = wk
			steps.append("extend")
		else:
			codes.append(_lzw_code(dict, w))
			dict[wk] = nxt
			adds.append([nxt, wk])
			nxt += 1
			w = k
			steps.append("stamp")
	codes.append(_lzw_code(dict, w))
	return {"codes": codes, "adds": adds, "steps": steps}


static func _lzw_code(dict: Dictionary, w: String) -> int:
	if w.length() == 1:
		return lzw_code_of(w)
	return int(dict[w])


## (p. 113) if c in woordenboek: volgend = woord(c) else volgend = w + w[0]; voeg w + volgend[0] toe.
## → {text, adds:[[code, word]], special:Array[int] (indices in codes met lege lade), stuck}
static func lzw_decode(codes: Array) -> Dictionary:
	var words := {}
	var nxt := ScCodes.LZW_FIRST
	var adds: Array = []
	var special: Array[int] = []
	if codes.is_empty():
		return {"text": "", "adds": adds, "special": special, "stuck": false}
	var c0 := int(codes[0])
	if c0 >= ScCodes.LZW_FIRST:
		return {"text": ScCodes.STUCK, "adds": adds, "special": special, "stuck": true}
	var w := char(c0)
	var text := w
	for idx in range(1, codes.size()):
		var c := int(codes[idx])
		var vw := ""
		if c < ScCodes.LZW_FIRST:
			vw = char(c)
		elif words.has(c):
			vw = str(words[c])
		elif c == nxt:
			vw = w + w[0]
			special.append(idx)
		else:
			return {"text": text + ScCodes.STUCK, "adds": adds, "special": special, "stuck": true}
		words[nxt] = w + vw[0]
		adds.append([nxt, w + vw[0]])
		nxt += 1
		w = vw
		text += w
	return {"text": text, "adds": adds, "special": special, "stuck": false}


# ================================================================== Burrows-Wheeler + move-to-front (p. 115–122)

## Lexicografisch op codepunten (de spatie is het kleinst, p. 116).
static func str_cmp(a: String, b: String) -> int:
	var n := mini(a.length(), b.length())
	for i in n:
		var x := a.unicode_at(i)
		var y := b.unicode_at(i)
		if x != y:
			return -1 if x < y else 1
	if a.length() == b.length():
		return 0
	return -1 if a.length() < b.length() else 1


static func rotation(s: String, i: int) -> String:
	return s.substr(i) + s.substr(0, i)


## Gesorteerde rotaties (stabiel). p = de rij die eindigt op s[0] = de rij van rotatie 1 (p. 117).
## → {p, c, rows, order (rotatie-index per rij)}
static func bwt(s: String) -> Dictionary:
	var n := s.length()
	var order: Array[int] = []
	for i in n:
		order.append(i)
	var rots: Array[String] = []
	for i in n:
		rots.append(rotation(s, i))
	order.sort_custom(func(a: int, b: int) -> bool:
		var c := str_cmp(rots[a], rots[b])
		return c < 0 or (c == 0 and a < b))
	var rows: Array[String] = []
	var c := ""
	var p := 0
	for r in n:
		rows.append(rots[order[r]])
		c += rots[order[r]][n - 1]
		if order[r] == 1 % maxi(1, n):
			p = r
	return {"p": p, "c": c, "rows": rows, "order": order}


## Per rotatie r ≥ 1 (in volgorde): [lo, hi] = aantal rotaties 0…r−1 die < resp. ≤ rotatie r zijn.
static func insertion_gaps(s: String) -> Array:
	var out: Array = []
	for r in range(1, s.length()):
		var rr := rotation(s, r)
		var lo := 0
		var hi := 0
		for q in r:
			var c := str_cmp(rotation(s, q), rr)
			if c < 0:
				lo += 1
			if c <= 0:
				hi += 1
		out.append([lo, hi])
	return out


## Rang (1-gebaseerd) van elk teken onder de gelijke tekens ervoor.
static func ranks(s: String) -> Array[int]:
	var cnt := {}
	var out: Array[int] = []
	for ch in s:
		cnt[ch] = int(cnt.get(ch, 0)) + 1
		out.append(int(cnt[ch]))
	return out


static func sorted_chars(c: String) -> String:
	var arr: Array[String] = []
	for ch in c:
		arr.append(ch)
	arr.sort_custom(func(a: String, b: String) -> bool: return a.unicode_at(0) < b.unicode_at(0))
	return "".join(arr)


## Positie in s van het teken ch met rang k (−1 als er geen is).
static func index_of_rank(s: String, ch: String, k: int) -> int:
	var cnt := 0
	for i in s.length():
		if s[i] == ch:
			cnt += 1
			if cnt == k:
				return i
	return -1


## Terugweg (p. 118–119): e = gesorteerde c; begin met c[p]; herhaal n keer: output, zoek i met c[i] = x, x = e[i].
## → {text, e, walk:[{ch, rank, i}]}
static func inverse_bwt(p: int, c: String) -> Dictionary:
	var n := c.length()
	var e := sorted_chars(c)
	var rc := ranks(c)
	var re := ranks(e)
	var walk: Array = []
	var text := ""
	if n == 0 or p < 0 or p >= n:
		return {"text": "", "e": e, "walk": walk}
	var ch := c[p]
	var rank := rc[p]
	for _k in n:
		text += ch
		var i := index_of_rank(c, ch, rank)
		walk.append({"ch": ch, "rank": rank, "i": i})
		ch = e[i]
		rank = re[i]
	return {"text": text, "e": e, "walk": walk}


## Move-to-front (p. 121): c(x) = positie in de lijst (vanaf 0), daarna x vooraan. → {nums, lists (na elk teken)}
static func mtf_encode(s: String, lst: Array) -> Dictionary:
	var l := lst.duplicate()
	var nums: Array[int] = []
	var lists: Array = []
	for ch in s:
		var k := l.find(ch)
		nums.append(k)
		if k >= 0:
			l.remove_at(k)
			l.insert(0, ch)
		lists.append(l.duplicate())
	return {"nums": nums, "lists": lists}


## → {text, lists, stuck} (een getal buiten de lijst: onleesbaar)
static func mtf_decode(nums: Array, lst: Array) -> Dictionary:
	var l := lst.duplicate()
	var text := ""
	var lists: Array = []
	for x in nums:
		var k := int(x)
		if k < 0 or k >= l.size():
			return {"text": text + ScCodes.STUCK, "lists": lists, "stuck": true}
		var ch := str(l[k])
		text += ch
		l.remove_at(k)
		l.insert(0, ch)
		lists.append(l.duplicate())
	return {"text": text, "lists": lists, "stuck": false}


## "p␣c" (uitvoer van de trommel, p. 117).
static func bwt_text(p: int, c: String) -> String:
	return str(p) + " " + c


## "p␣c" → {p, c, ok}
static func split_bwt_text(s: String) -> Dictionary:
	var sp := s.find(" ")
	if sp <= 0 or not s.substr(0, sp).is_valid_int():
		return {"p": -1, "c": s, "ok": false}
	return {"p": s.substr(0, sp).to_int(), "c": s.substr(sp + 1), "ok": true}
