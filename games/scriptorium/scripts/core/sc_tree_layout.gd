class_name ScTreeLayout
## Posities van boomtoppen (GDD §8.8): bladeren gelijk verdeeld van links naar rechts, interne toppen boven het midden
## van hun kinderen, één rij per diepte. tree = ScTree.render() (of een dictionary met dezelfde velden).


## → {id: Vector2} binnen [0, width] × [0, height] (wortel bovenaan, zoals Fig. 24/25).
static func layout(tree: Dictionary, width: float, height: float) -> Dictionary:
	var by := {}
	for nd in tree.get("nodes", []):
		by[int(nd.id)] = nd
	var root := int(tree.get("root", -1))
	var out := {}
	if root < 0 or not by.has(root):
		return out
	var leaves: Array[int] = []
	var depth := {}
	var maxd := [0]
	_walk(by, root, 0, leaves, depth, maxd)
	var nl := maxi(1, leaves.size())
	var dx := width / float(nl)
	var dy := height / float(maxi(1, int(maxd[0]))) if int(maxd[0]) > 0 else 0.0
	var xs := {}
	for q in leaves.size():
		xs[leaves[q]] = dx * (float(q) + 0.5)
	_x(by, root, xs)
	for id in depth:
		out[id] = Vector2(float(xs.get(id, width / 2.0)), dy * float(depth[id]) if int(maxd[0]) > 0 else height / 2.0)
	return out


static func _kids(by: Dictionary, id: int) -> Array[int]:
	var out: Array[int] = []
	var nd: Dictionary = by[id]
	for k in ["l", "r"]:
		if int(nd.get(k, -1)) >= 0 and by.has(int(nd[k])):
			out.append(int(nd[k]))
	return out


static func _walk(by: Dictionary, id: int, d: int, leaves: Array[int], depth: Dictionary, maxd: Array) -> void:
	depth[id] = d
	maxd[0] = maxi(int(maxd[0]), d)
	var ks := _kids(by, id)
	if ks.is_empty():
		leaves.append(id)
	for k in ks:
		_walk(by, k, d + 1, leaves, depth, maxd)


static func _x(by: Dictionary, id: int, xs: Dictionary) -> float:
	var ks := _kids(by, id)
	if ks.is_empty():
		return float(xs[id])
	var s := 0.0
	for k in ks:
		s += _x(by, k, xs)
	xs[id] = s / float(ks.size())
	return float(xs[id])
