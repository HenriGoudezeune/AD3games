class_name TtBot
extends RefCounted
## QA-bot: kiest de volgende zet via het orakel (`model.correct_move()`), optioneel met foutmodi:
## "perfect" (altijd juist), "errors" (de eerste keer dat een zettype voorkomt een typische fout, daarna juist),
## "random" (elke zet 22 % kans op een fout). Foute zetten zijn de klassiekers uit GDD §3 (verkeerde letter,
## j te laat, verkeerde leespositie, wesp laten plukken, verkeerde richting, ...).

var mode := "perfect"
var rng := RandomNumberGenerator.new()
var _seen := {}
var errors_made := 0


func _init(mode_ := "perfect", seed_ := 7) -> void:
	mode = mode_
	rng.seed = seed_


func choose(model: TtTreeModel) -> Dictionary:
	var mv: Dictionary = model.correct_move()
	if mv.is_empty() or str(mv.get("act", "none")) == "none":
		return mv
	var act := str(mv.act)
	var wrong := false
	match mode:
		"errors":
			if not _seen.has(act):
				_seen[act] = true
				wrong = true
		"random":
			wrong = rng.randf() < 0.22
	if not wrong:
		return mv
	var w := _wrong(model, mv)
	if w.is_empty():
		return mv
	errors_made += 1
	return w


func _wrong(model: TtTreeModel, mv: Dictionary) -> Dictionary:
	var cur: Dictionary = model.cursor()
	var letters: PackedStringArray = model.alphabet.letters
	match str(mv.act):
		"move":
			var c := str(mv.letter)
			var node: TtNode = model.node(int(cur.get("node", model.root)))
			# liefst een bestaande tak (verkeerde letter volgen), anders een andere lege knop
			if node:
				for k in node.kids.keys():
					if str(k) != c:
						return {"act": "move", "letter": str(k)}
			for l in letters:
				if l != c:
					return {"act": "move", "letter": l}
		"split":
			var j := int(mv.j)
			var a := str(cur.get("word", ""))
			var lf := model.node(int(cur.get("leaf", -1)))
			var l := lf.label if lf else ""
			for jj in range(j + 1, mini(a.length(), l.length())):
				if a[jj] != l[jj]:
					return {"act": "split", "j": jj}
			return {"act": "same"}
		"same":
			return {"act": "split", "j": int(cur.get("depth", 0))}
		"answer":
			return {"act": "answer", "found": not bool(mv.found)}
		"cut":
			var n := model.node(int(mv.node))
			if n and n.parent >= 0 and n.parent != model.root:
				return {"act": "cut", "node": n.parent}
			if n and not n.kids.is_empty():
				return {"act": "cut", "node": int(n.kids.values()[0])}
		"read":
			var p := int(mv.pos)
			if p + 1 <= int(cur.get("m", 0)):
				return {"act": "read", "pos": p + 1}
			if p - 1 >= 0:
				return {"act": "read", "pos": p - 1}
		"short":
			return {}
		"prune":
			return {"act": "prune_done"}
		"go":
			var dirs := ["lo", "eq", "hi"]
			dirs.erase(str(mv.dir))
			return {"act": "go", "dir": dirs[rng.randi() % 2]}
		"place":
			var rem: PackedStringArray = cur.get("remaining", PackedStringArray())
			for l2 in rem:
				if l2 != str(mv.letter):
					return {"act": "place", "letter": l2}
		"attach":
			return {"act": "attach", "node": model.root, "off": 0}
		"label":
			return {"act": "label", "b": int(mv.b) + 1}
		"locate":
			return {"act": "absent"}
		"absent":
			return {"act": "locate", "node": model.root, "off": 0}
		"where":
			return {"act": "where", "pos": int(mv.pos) + 1}
		"count":
			return {"act": "count", "n": int(mv.n) + 1}
		"pick":
			var lv: Array = mv.leaves.duplicate()
			if lv.size() > 1:
				lv.pop_back()
				return {"act": "pick", "leaves": lv}
		"owner":
			var tx: Array = mv.texts.duplicate()
			if tx.size() > 1:
				tx.pop_back()
				return {"act": "owner", "texts": tx}
			return {"act": "owner", "texts": [1 if (tx.is_empty() or int(tx[0]) != 1) else 2]}
		"rule":
			return {"act": "rule", "grow": not bool(mv.grow)}
		"follow":
			return {"act": "follow", "mode": "minus" if str(mv.mode) == "link" else "link"}
		"link":
			return {"act": "link", "node": model.root if int(mv.node) != model.root else int(mv.node)}
		"hop":
			return {"act": "rule", "grow": true}
	return {}
