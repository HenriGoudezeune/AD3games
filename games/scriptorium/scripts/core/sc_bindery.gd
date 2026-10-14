class_name ScBindery extends ScTool
## Binderij (GDD §3.3): Huffman, Algoritme 9. Elke binding kost a(Z) touw; totaal touw = Σ gewichten van de interne
## toppen = Q(T) = bits (Stelling 21).
## stage {"tool":"bindery", "mode":"row"|"shelves", "text":…, "row":"boesdr"} · {"weights":[["A",8],…]} ·
##       {"symbols":"carry"} (Codex: de getallen van de plank) · "strict":true (Nachtwake: fout paar wordt niet gebonden)
## Zetten: rij {"act":"bind","a":i,"b":j} (klem same, range; WRONG_PAIR als Algoritme 9 het paar niet toelaat).
##         planken {"act":"bind","a":"A"|"B","b":"A"|"B"} (klem empty; neemt de voorkant van plank a, dan van plank b).
## Orakel = twee-plankenregel (Oef. 85; reproduceert p. 85).

var mode: String = "row"
var strict: bool = false
var text: String = ""
var seq: Array = []             # de te schrijven symbolen (tekst of carry), leeg bij gewichten
var freqs: Array = []           # [[sym, a]]
var tree: ScTree
var row: Array[int] = []        # rijmodus: ids
var born: Dictionary = {}       # id → ontstaansvolgorde van de bundel
var shelf_a: Array[int] = []
var shelf_b: Array[int] = []
var nb: int = 0
var bits: String = ""
var codes: Dictionary = {}
var optimum: int = 0
var binds: Array = []           # [{a_id, b_id, z, w}]


func _setup() -> void:
	tool = ScCodes.Tool.BINDERY
	mode = str(stage.get("mode", "row"))
	strict = bool(stage.get("strict", false))
	text = ""
	seq = []
	if stage.has("weights"):
		freqs = []
		for x in stage.weights:
			freqs.append([str(x[0]), int(x[1])])
	elif str(stage.get("symbols", "")) == "carry":
		for s in carry_in.get("symbols", []):
			seq.append(str(s))
		freqs = ScReference.freqs_of(seq)
	else:
		text = str(stage.get("text", carry_in.get("text", "")))
		for ch in text:
			seq.append(ch)
		var ord: Array = []
		for ch in str(stage.get("row", "")):
			ord.append(ch)
		freqs = ScReference.freqs_of(seq, ord)
	optimum = ScReference.huffman_cost(_weights(freqs))
	tree = ScTree.new()
	row = []
	born = {}
	for f in freqs:
		row.append(tree.add_node(int(f[1]), str(f[0])))
	shelf_a = []
	shelf_b = []
	if mode == "shelves":
		var ids := row.duplicate()
		var pos := {}
		for q in ids.size():
			pos[ids[q]] = q
		ids.sort_custom(func(a: int, b: int) -> bool:
			return tree.w(a) < tree.w(b) or (tree.w(a) == tree.w(b) and int(pos[a]) < int(pos[b])))
		shelf_a = ids
		row = []
	nb = 0
	bits = ""
	codes = {}
	binds = []


static func _weights(fr: Array) -> Array:
	var out: Array = []
	for f in fr:
		out.append(int(f[1]))
	return out


func _begin() -> void:
	phase = P.BIND
	if _items().size() <= 1:
		_complete()


## Alle losse stapels en bundels (rij, of plank A + plank B).
func _items() -> Array[int]:
	if mode == "shelves":
		var out: Array[int] = shelf_a.duplicate()
		out.append_array(shelf_b)
		return out
	return row


func _born(id: int) -> int:
	return int(born.get(id, -1))


func label(id: int) -> String:
	if tree.is_leaf(id):
		return tree.sym(id)
	return "(" + label(tree.left(id)) + label(tree.right(id)) + ")"


## De twee lichtste gewichten nu: [w1, w2].
func lightest() -> Array:
	var ws: Array = []
	for x in _items():
		ws.append(tree.w(x))
	ws.sort()
	return [ws[0], ws[1]] if ws.size() >= 2 else [0, 0]


func _pair_valid(a: int, b: int) -> bool:
	var items := _items()
	var ws: Array = []
	for x in items:
		ws.append(tree.w(x))
	return ScReference.is_valid_pair(ws, items.find(a), items.find(b))


# ------------------------------------------------------------------ beoordelen

## Rijmodus: indices; plankmodus: welke ids er genomen worden.
func _resolve(move: Dictionary) -> Dictionary:
	if mode == "shelves":
		var sa := str(move.get("a", ""))
		var sb := str(move.get("b", ""))
		if not sa in ["A", "B"] or not sb in ["A", "B"]:
			return {"ok": false, "reason": "range"}
		var a_list := shelf_a.duplicate()
		var b_list := shelf_b.duplicate()
		var first := -1
		var second := -1
		var src: Array = a_list if sa == "A" else b_list
		if src.is_empty():
			return {"ok": false, "reason": "empty"}
		first = src.pop_front()
		var src2: Array = a_list if sb == "A" else b_list
		if src2.is_empty():
			return {"ok": false, "reason": "empty"}
		second = src2.pop_front()
		return {"ok": true, "x": first, "y": second}
	var i := int(move.get("a", -1)) if str(move.get("a", "")).is_valid_int() else -1
	var j := int(move.get("b", -1)) if str(move.get("b", "")).is_valid_int() else -1
	if i < 0 or j < 0 or i >= row.size() or j >= row.size():
		return {"ok": false, "reason": "range"}
	if i == j:
		return {"ok": false, "reason": "same"}
	return {"ok": true, "x": row[i], "y": row[j], "i": i, "j": j}


func _judge(move: Dictionary) -> Dictionary:
	if str(move.get("act", "")) != "bind":
		return {"ok": false, "reason": "unknown_act"}
	if phase != P.BIND:
		return {"ok": false, "reason": "wrong_phase"}
	var r := _resolve(move)
	if not bool(r.ok):
		return r
	var x := int(r.x)
	var y := int(r.y)
	var lw := lightest()
	var data := {"x": label(x), "y": label(y), "v1": tree.w(x), "v2": tree.w(y), "w1": lw[0], "w2": lw[1]}
	var verdict := V.OK if _pair_valid(x, y) else V.WRONG_PAIR
	return {"ok": true, "verdict": verdict, "type": "BIND", "data": data, "x": x, "y": y}


func _exec(_move: Dictionary, j: Dictionary, e: Dictionary) -> void:
	if strict and int(j.verdict) != V.OK:
		_fx.append({"fx": "snap", "a": int(j.x), "b": int(j.y)})
		e.data["snapped"] = true
		return
	var x := int(j.x)
	var y := int(j.y)
	var z: int
	var at: int
	if mode == "shelves":
		var both := not shelf_a.is_empty() and not shelf_b.is_empty()
		_take(x)
		var both2 := not shelf_a.is_empty() and not shelf_b.is_empty()
		_take(y)
		counters.search = int(counters.search) + (1 if both else 0) + (1 if both2 else 0)
		z = tree.add_node(tree.w(x) + tree.w(y))
		tree.set_children(z, x, y)
		shelf_b.append(z)
		at = shelf_b.size() - 1
	else:
		var i := row.find(x)
		var k := row.find(y)
		var a := mini(i, k)
		var b := maxi(i, k)
		counters.search = int(counters.search) + 2 * row.size() - 3
		z = tree.add_node(tree.w(row[a]) + tree.w(row[b]))
		tree.set_children(z, row[a], row[b])
		row[a] = z
		row.remove_at(b)
		at = a
	born[z] = nb
	nb += 1
	counters.twine = int(counters.twine) + tree.w(z)
	binds.append({"a": tree.left(z), "b": tree.right(z), "z": z, "w": tree.w(z)})
	_fx.append({"fx": "bind", "a": tree.left(z), "b": tree.right(z), "at": at, "id": z, "w": tree.w(z),
		"twine": int(counters.twine)})
	e.data["id"] = z
	if _items().size() == 1:
		_complete()


func _take(id: int) -> void:
	if not shelf_a.is_empty() and shelf_a[0] == id:
		shelf_a.pop_front()
	elif not shelf_b.is_empty() and shelf_b[0] == id:
		shelf_b.pop_front()


## Eén boom: codeboek, de kopiist schrijft, klaar.
func _complete() -> void:
	var items := _items()
	if items.size() == 1:
		tree.root = items[0]
	codes = tree.codes()
	if items.size() == 1 and tree.is_leaf(tree.root):
		codes = {tree.sym(tree.root): "0"}
	_auto("CODEBOOK", {"codes": codes.duplicate()}, {"fx": "codebook", "codes": codes.duplicate()})
	if not seq.is_empty():
		phase = P.COPY
		bits = ScReference.encode_with(codes, seq)
		_auto("COPY", {"bits": bits}, {"fx": "write", "tokens": [{"b": bits}]})
	counters.ink = bits.length() if not seq.is_empty() else int(counters.twine)
	_out_dirty = true
	_finish()


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	if phase != P.BIND:
		return {"act": "none"}
	if mode == "shelves":
		var a := shelf_a.duplicate()
		var b := shelf_b.duplicate()
		var picks: Array[String] = []
		for _k in 2:
			var use_b := not b.is_empty() and (a.is_empty() or tree.w(b[0]) <= tree.w(a[0]))
			if use_b:
				picks.append("B")
				b.pop_front()
			else:
				picks.append("A")
				a.pop_front()
		return {"act": "bind", "a": picks[0], "b": picks[1]}
	var r: Array = []
	for x in row:
		r.append({"w": tree.w(x), "born": _born(x)})
	var ij := ScReference.canonical_pair(r)
	return {"act": "bind", "a": int(ij[0]), "b": int(ij[1])}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase != P.BIND:
		return out
	if mode == "shelves":
		for sa in ["A", "B"]:
			for sb in ["A", "B"]:
				out.append({"act": "bind", "a": sa, "b": sb})
		return out
	var ws: Array = []
	for x in row:
		ws.append(tree.w(x))
	for i in row.size():
		for j in range(i + 1, row.size()):
			if not ScReference.is_valid_pair(ws, i, j):
				out.append({"act": "bind", "a": i, "b": j})
	# de zwaarste eerst (meest zichtbare gevolg), maar deterministisch
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mode == "shelves":
		if shelf_b.is_empty():
			out.append({"act": "bind", "a": "B", "b": "A"})
		if shelf_a.is_empty():
			out.append({"act": "bind", "a": "A", "b": "B"})
		out.append({"act": "bind", "a": "C", "b": "A"})
		return out
	out.append({"act": "bind", "a": 0, "b": 0})
	out.append({"act": "bind", "a": 0, "b": row.size()})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _output() -> Dictionary:
	return {"kind": "bits", "bits": bits, "code": codes.duplicate(), "tree": tree.render(), "ink": int(counters.ink),
		"symbols": seq.duplicate()}


func structure() -> Dictionary:
	var lens := {}
	for k in codes:
		lens[k] = str(codes[k]).length()
	return {"codes": codes.duplicate(), "lengths": lens, "twine": int(counters.twine)}


func _row_info(ids: Array[int]) -> Array:
	var out: Array = []
	for x in ids:
		out.append({"id": x, "label": label(x), "w": tree.w(x), "leaf": tree.is_leaf(x)})
	return out


func _cursor() -> Dictionary:
	return {"mode": mode, "row": _row_info(row), "shelf_a": _row_info(shelf_a), "shelf_b": _row_info(shelf_b),
		"twine": int(counters.twine), "search": int(counters.search), "selected": -1, "optimum": optimum,
		"lightest": lightest() if _items().size() >= 2 else []}


func _render_extra() -> Dictionary:
	return {"tree": tree.render(), "freqs": freqs, "codes": codes}


func _snap() -> Dictionary:
	var bd := {}
	for k in born:
		bd[str(k)] = born[k]
	return {"tree": tree.snapshot(), "row": row.duplicate(), "born": bd, "shelf_a": shelf_a.duplicate(),
		"shelf_b": shelf_b.duplicate(), "nb": nb, "bits": bits, "codes": codes.duplicate(), "binds": binds.duplicate(true)}


func _restore(d: Dictionary) -> void:
	tree.restore(d.get("tree", {}))
	row = ints(d.get("row", []))
	born = {}
	var bd: Dictionary = d.get("born", {})
	for k in bd:
		born[int(str(k))] = int(bd[k])
	shelf_a = ints(d.get("shelf_a", []))
	shelf_b = ints(d.get("shelf_b", []))
	nb = int(d.get("nb", 0))
	bits = str(d.get("bits", ""))
	codes = {}
	var cd: Dictionary = d.get("codes", {})
	for k in cd:
		codes[str(k)] = str(cd[k])
	binds = d.get("binds", [])


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	var tw := 0
	var seen := {}
	for x in _items():
		seen[x] = true
		for y in _sub(x):
			if not tree.is_leaf(y):
				tw += tree.w(y)
				if tree.w(y) != tree.w(tree.left(y)) + tree.w(tree.right(y)):
					e.append("(a) bundel %s" % label(y))
	if tw != int(counters.twine):
		e.append("touw %d ≠ Σ bundels %d" % [int(counters.twine), tw])
	if seq.size() > 0 and _done and bits.length() != int(counters.twine) and _items().size() == 1 \
			and not tree.is_leaf(tree.root):
		e.append("bits %d ≠ touw %d" % [bits.length(), int(counters.twine)])
	return e


func _sub(x: int) -> Array[int]:
	var out: Array[int] = [x]
	if not tree.is_leaf(x):
		out.append_array(_sub(tree.left(x)))
		out.append_array(_sub(tree.right(x)))
	return out
