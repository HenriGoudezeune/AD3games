class_name ScTree extends RefCounted
## Binaire boom met ids (GDD §8.1): gewicht, ordenummer, symbool. Gebruikt door de binderij (Huffman, ordenummers −1)
## en de levende boom (adaptieve Huffman, [gewicht, ordenummer]). Links = 0, rechts = 1 (p. 83).
## Knopen staan in `nodes` op index = id; een verwijderde knoop is {"dead": true}. JSON-veilig (snapshot/restore).

var nodes: Array[Dictionary] = []
var root: int = -1
var nng: int = -1          # id van de nng-top (adaptief), −1 als die er niet is


func add_node(w: int, sym := "", num := -1) -> int:
	var id := nodes.size()
	nodes.append({"id": id, "w": w, "num": num, "sym": sym, "l": -1, "r": -1, "p": -1})
	return id


func set_children(p: int, l: int, r: int) -> void:
	nodes[p].l = l
	nodes[p].r = r
	nodes[l].p = p
	nodes[r].p = p


func alive(id: int) -> bool:
	return id >= 0 and id < nodes.size() and not nodes[id].has("dead")


func kill(id: int) -> void:
	nodes[id] = {"dead": true, "id": id}


func node(id: int) -> Dictionary:
	return nodes[id] if alive(id) else {}


func w(id: int) -> int:
	return int(nodes[id].w)


func num(id: int) -> int:
	return int(nodes[id].num)


func sym(id: int) -> String:
	return str(nodes[id].sym)


func left(id: int) -> int:
	return int(nodes[id].l)


func right(id: int) -> int:
	return int(nodes[id].r)


func parent(id: int) -> int:
	return int(nodes[id].p)


func is_leaf(id: int) -> bool:
	return int(nodes[id].l) < 0


func is_root(id: int) -> bool:
	return id == root


## Levende ids in preorde (wortel, links, rechts).
func ids() -> Array[int]:
	var out: Array[int] = []
	if root < 0:
		return out
	var stack: Array[int] = [root]
	while not stack.is_empty():
		var x: int = stack.pop_back()
		out.append(x)
		if not is_leaf(x):
			stack.append(right(x))
			stack.append(left(x))
	return out


## Bladeren van links naar rechts.
func leaves() -> Array[int]:
	var out: Array[int] = []
	for x in ids():
		if is_leaf(x):
			out.append(x)
	return out


func size() -> int:
	return ids().size()


## Pad van de wortel naar id: "0" = links, "1" = rechts.
func code(id: int) -> String:
	var s := ""
	var x := id
	while x >= 0 and parent(x) >= 0:
		var p := parent(x)
		s = ("0" if left(p) == x else "1") + s
		x = p
	return s


func depth(id: int) -> int:
	return code(id).length()


## Ids op het pad van de wortel naar id (wortel eerst, id inbegrepen).
func path(id: int) -> Array[int]:
	var out: Array[int] = []
	var x := id
	while x >= 0:
		out.push_front(x)
		x = parent(x)
	return out


## Is a een (strikte) voorouder van b?
func is_ancestor(a: int, b: int) -> bool:
	var x := parent(b)
	while x >= 0:
		if x == a:
			return true
		x = parent(x)
	return false


## Volgt bits vanaf de wortel tot een blad: {leaf, used} of {leaf:-1, used} als de bits opraken.
func follow(bits: String) -> Dictionary:
	var x := root
	var used := 0
	while x >= 0 and not is_leaf(x):
		if used >= bits.length():
			return {"leaf": -1, "used": used}
		x = left(x) if bits[used] == "0" else right(x)
		used += 1
	return {"leaf": x, "used": used}


func leaf_of(s: String) -> int:
	for x in ids():
		if is_leaf(x) and sym(x) == s:
			return x
	return -1


func node_with_num(n: int) -> int:
	for x in ids():
		if num(x) == n:
			return x
	return -1


## Codes van alle bladeren (nng uitgezonderd): {sym: code}.
func codes() -> Dictionary:
	var out := {}
	for x in leaves():
		if x != nng:
			out[sym(x)] = code(x)
	return out


## Wisselt de deelbomen a en b van plaats, en hun ordenummers (Algoritme 11). Geen voorouder/nakomeling.
func swap(a: int, b: int) -> void:
	var pa := parent(a)
	var pb := parent(b)
	if pa == pb:
		var ol := left(pa)
		nodes[pa].l = right(pa)
		nodes[pa].r = ol
	else:
		var a_left := left(pa) == a
		var b_left := left(pb) == b
		if a_left:
			nodes[pa].l = b
		else:
			nodes[pa].r = b
		if b_left:
			nodes[pb].l = a
		else:
			nodes[pb].r = a
		nodes[a].p = pb
		nodes[b].p = pa
	var na := num(a)
	nodes[a].num = num(b)
	nodes[b].num = na


## Som van de gewichten van de interne toppen (= Σ a(x)·l(x) voor een Huffman-boom, Stelling 21).
func internal_sum() -> int:
	var s := 0
	for x in ids():
		if not is_leaf(x):
			s += w(x)
	return s


## Lemma 22 (a)–(c) (enkel voor bomen met ordenummers). Leeg = in orde.
func sibling_violations() -> PackedStringArray:
	var errs := PackedStringArray()
	var all := ids()
	for x in all:
		if not is_leaf(x) and w(x) != w(left(x)) + w(right(x)):
			errs.append("(a) gewicht van %s ≠ som van de kinderen" % label(x))
	var by := procession()
	for i in by.size():
		if num(by[i]) != i + 1:
			errs.append("ordenummers zijn niet 1…%d" % by.size())
			break
	for i in by.size() - 1:
		if w(by[i]) > w(by[i + 1]):
			errs.append("(b) %s vóór %s" % [label(by[i]), label(by[i + 1])])
	for j in range(1, (by.size() + 1) / 2):
		var a: int = by[2 * j - 2]
		var b: int = by[2 * j - 1]
		if parent(a) != parent(b) or parent(a) < 0:
			errs.append("(c) %d en %d zijn geen broers" % [2 * j - 1, 2 * j])
	return errs


## Toppen die struikelen: eigenschap (b) gebroken (gewicht daalt in de processie).
func stumbling() -> Array[int]:
	var out: Array[int] = []
	var by := procession()
	for i in by.size() - 1:
		if w(by[i]) > w(by[i + 1]):
			if not out.has(by[i]):
				out.append(by[i])
			if not out.has(by[i + 1]):
				out.append(by[i + 1])
	return out


## Ids gesorteerd op ordenummer (de processie).
func procession() -> Array[int]:
	var all := ids()
	all.sort_custom(func(a: int, b: int) -> bool: return num(a) < num(b))
	return all


## De top x met a(x) = gewicht en o(x) maximaal (Algoritme 11), −1 als er geen is.
func max_num_with_weight(weight: int) -> int:
	var best := -1
	for x in ids():
		if w(x) == weight and (best < 0 or num(x) > num(best)):
			best = x
	return best


func label(x: int) -> String:
	var s := sym(x)
	if s == "" or s == ScCodes.NNG:
		s = "*" if s == "" else s
	return "%s[%d,%d]" % [s, w(x), num(x)]


## Notatie van de GDD: `[g,o](links rechts)`, bladeren `x[g,o]`, nng als `nng[0,1]`. Zonder ordenummers: `label:g`.
func show(x := -2) -> String:
	if x == -2:
		x = root
	if x < 0:
		return ""
	var s := sym(x)
	var tag := "[%d,%d]" % [w(x), num(x)] if num(x) >= 0 else ":%d" % w(x)
	if is_leaf(x):
		return (s if s != "" else "?") + tag
	return tag + "(" + show(left(x)) + " " + show(right(x)) + ")"


## Renderformaat (GDD §8.8).
func render() -> Dictionary:
	var out: Array = []
	for x in ids():
		out.append({"id": x, "w": w(x), "num": num(x), "sym": sym(x), "l": left(x), "r": right(x), "p": parent(x),
			"code": code(x)})
	return {"root": root, "nng": nng, "nodes": out}


func snapshot() -> Dictionary:
	return {"nodes": nodes.duplicate(true), "root": root, "nng": nng}


func restore(d: Dictionary) -> void:
	nodes.clear()
	for x in d.get("nodes", []):
		var n: Dictionary = x
		var c := {}
		for k in n:
			c[k] = n[k]
		for k in ["id", "w", "num", "l", "r", "p"]:
			if c.has(k):
				c[k] = int(c[k])
		if c.has("sym"):
			c["sym"] = str(c["sym"])
		nodes.append(c)
	root = int(d.get("root", -1))
	nng = int(d.get("nng", -1))


func clone() -> ScTree:
	var t := ScTree.new()
	t.restore(snapshot())
	return t


## Bouwt een boom uit een geneste spec: [w, num, sym] (blad) of [w, num, links, rechts] (intern).
static func from_spec(spec: Array) -> ScTree:
	var t := ScTree.new()
	t.root = t._build(spec, -1)
	return t


func _build(sp: Array, p: int) -> int:
	var id: int
	if sp.size() == 3:
		id = add_node(int(sp[0]), str(sp[2]), int(sp[1]))
		if str(sp[2]) == ScCodes.NNG:
			nng = id
	else:
		id = add_node(int(sp[0]), "", int(sp[1]))
		var l := _build(sp[2], id)
		var r := _build(sp[3], id)
		nodes[id].l = l
		nodes[id].r = r
	nodes[id].p = p
	return id
