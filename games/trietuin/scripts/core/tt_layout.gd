class_name TtLayout
## Pure boomlayout (GDD §4.3, §8.9): deterministisch; kinderen in alfabetvolgorde links → rechts; elke vrucht krijgt
## een eigen kolom (dus nooit overlappende vruchten); een interne top staat midden boven zijn eerste en laatste kind.
## Ternary: kinderen van een bol zijn kleiner/gelijk/groter; een rankknoop (PACK) valt samen met zijn wortelbol.
## Losse deelbomen (parent == -1, bv. tijdens het omzetten) komen naast de hoofdboom.
## -> {id: Vector2} (centrum van top/vrucht/bol), plus "_meta": {cols, levels, dx, dy}

const NT := TtNode.Type
const DY_MAX := 110.0
const DY_MIN := 40.0


static func _letter_less(a: String, b: String) -> bool:
	var sa := a == "_" or (a >= "0" and a <= "9")
	var sb := b == "_" or (b >= "0" and b <= "9")
	if sa != sb:
		return sb
	return a < b


static func compute(render_nodes: Array[Dictionary], kind: int, rect: Rect2, root_bottom := true,
		letters := PackedStringArray()) -> Dictionary:
	var by_id := {}
	for d in render_nodes:
		by_id[int(d.id)] = d
	var order := {}
	for i in letters.size():
		order[letters[i]] = i
	var kids := {}       # id -> [child ids] in volgorde
	var has_parent := {}
	for d in render_nodes:
		var id := int(d.id)
		var ch: Array = []
		if kind == TtCodes.Kind.TERNARY:
			match int(d.type):
				NT.PACK:
					if int(d.ball_root) >= 0:
						ch.append(int(d.ball_root))
				NT.BALL:
					for x in [int(d.lo), int(d.eq), int(d.hi)]:
						if x >= 0 and by_id.has(x):
							ch.append(x)
		else:
			var ks: Array = (d.kids as Dictionary).keys()
			if order.is_empty():
				ks.sort_custom(func(a, b): return _letter_less(str(a), str(b)))
			else:
				ks.sort_custom(func(a, b): return int(order.get(str(a), 999)) < int(order.get(str(b), 999)))
			for k in ks:
				var c := int(d.kids[k])
				if by_id.has(c):
					ch.append(c)
		kids[id] = ch
		for c in ch:
			has_parent[c] = true
	var roots: Array = []
	for d in render_nodes:
		if not has_parent.has(int(d.id)):
			roots.append(int(d.id))
	roots.sort()
	# rankknopen zijn "doorzichtig": ze krijgen dezelfde plaats als hun wortelbol en tellen niet als niveau
	var col := {}
	var lvl := {}
	var next_col := [0.0]
	var max_lvl := [0]
	for r in roots:
		_place(r, 0, kids, by_id, kind, col, lvl, next_col, max_lvl)
		next_col[0] += 0.5
	var cols := maxf(next_col[0] - 0.5, 1.0)
	var levels: int = max_lvl[0]
	var dx := rect.size.x / cols
	var dy := DY_MAX
	if levels > 0:
		dy = clampf(rect.size.y / levels, DY_MIN, DY_MAX)
		if dy * levels > rect.size.y:
			dy = rect.size.y / levels
	var out := {}
	for id in col.keys():
		var x := rect.position.x + (float(col[id]) + 0.5) * dx
		var y := 0.0
		if root_bottom:
			y = rect.end.y - float(lvl[id]) * dy
		else:
			y = rect.position.y + float(lvl[id]) * dy
		out[id] = Vector2(x, y)
	out["_meta"] = {"cols": cols, "levels": levels, "dx": dx, "dy": dy}
	return out


static func _place(id: int, level: int, kids: Dictionary, by_id: Dictionary, kind: int, col: Dictionary, lvl: Dictionary,
		next_col: Array, max_lvl: Array) -> void:
	var d: Dictionary = by_id[id]
	var ch: Array = kids.get(id, [])
	var is_pack := kind == TtCodes.Kind.TERNARY and int(d.type) == NT.PACK
	if is_pack:
		if ch.is_empty():
			col[id] = next_col[0]
			lvl[id] = level
			next_col[0] += 1.0
			max_lvl[0] = maxi(max_lvl[0], level)
			return
		_place(int(ch[0]), level, kids, by_id, kind, col, lvl, next_col, max_lvl)
		col[id] = col[int(ch[0])]
		lvl[id] = lvl[int(ch[0])]
		return
	lvl[id] = level
	max_lvl[0] = maxi(max_lvl[0], level)
	if ch.is_empty():
		col[id] = next_col[0]
		next_col[0] += 1.0
		return
	for c in ch:
		_place(int(c), level + 1, kids, by_id, kind, col, lvl, next_col, max_lvl)
	col[id] = (float(col[int(ch[0])]) + float(col[int(ch[-1])])) / 2.0
