class_name ScRegister extends RefCounted
## Het register (GDD §3.6, §4.3.1): de deelstringboom van het al geschreven stuk, naïef opgebouwd (n ≤ 40), en de
## wandeling van de lantaarn: letter per letter verder zolang een beginpositie in het al geschreven stuk overleeft
## (de match mag in de nieuwe tekst doorlopen). Eén vergelijking per letter: l + 1 (l als de tekst eindigt).


## Wandeling bij positie k (raam = alles vóór k, of het raam [ws, k)).
## → {steps:[{depth, ch, alive:Array[int] (raamposities)}], p (kleinste overlevende), l, cost}
static func walk(text: String, k: int, ws := 0) -> Dictionary:
	var alive: Array[int] = []
	for p in k - ws:
		alive.append(p)
	var steps: Array = []
	var depth := 0
	while k + depth < text.length() and not alive.is_empty():
		var nxt: Array[int] = []
		for p in alive:
			if text[ws + p + depth] == text[k + depth]:
				nxt.append(p)
		if nxt.is_empty():
			break
		alive = nxt
		steps.append({"depth": depth, "ch": text[k + depth], "alive": alive.duplicate()})
		depth += 1
	var l := depth
	var cost := l + (1 if k + l < text.length() else 0)
	return {"steps": steps, "p": alive[0] if l > 0 and not alive.is_empty() else 0, "l": l, "cost": cost}


## De (naïeve) deelstringboom van s: een trie van alle suffixen, met ids. → {nodes:[{id, ch, parent, depth}], …}
static func trie(s: String) -> Dictionary:
	var nodes: Array = [{"id": 0, "ch": "", "parent": -1, "depth": 0, "children": {}}]
	for start in s.length():
		var cur := 0
		for q in range(start, s.length()):
			var c := s[q]
			var ch: Dictionary = nodes[cur].children
			if not ch.has(c):
				var id := nodes.size()
				nodes.append({"id": id, "ch": c, "parent": cur, "depth": int(nodes[cur].depth) + 1, "children": {}})
				ch[c] = id
			cur = int(ch[c])
	var out: Array = []
	for nd in nodes:
		out.append({"id": nd.id, "ch": nd.ch, "parent": nd.parent, "depth": nd.depth})
	return {"nodes": out, "size": out.size()}
