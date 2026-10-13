class_name TtBeds extends TtTreeModel
## Level 3-4 "Oefening 20": twee tuinbedden; per bed kiest de speler array-boom (gewone trie) of rankboom (ternary).
## Daarna plant de tuin automatisch; raakt het sap op, dan waaien de resterende zaadjes weg (GDD §5.4).
## Zetten: {"act":"bed","bed":i,"choice":"array"|"ternary"} (opnieuw kiezen = herplanten) · {"act":"beds_done"} (opgeven)

var beds: Array = []             # [{name, alphabet, words, budget, best, array_sap, ternary_sap, choice, first_ok, planted, blown}]
var bed_models: Array = []       # TtTreeModel per bed (null = nog niet geplant)


func _init() -> void:
	kind = TtCodes.Kind.TRIE


func setup(alpha: TtAlphabet) -> TtBeds:
	alphabet = alpha
	_clear_nodes()
	var r := _new_node(NT.INNER)
	root = r.id
	return self


func bed_model(i: int) -> TtTreeModel:
	return bed_models[i] if i >= 0 and i < bed_models.size() else null


static func _plant(choice: String, alpha_name: String, words: Array, budget: int) -> Dictionary:
	var a := TtAlphabet.by_name(alpha_name)
	var m: TtTreeModel = TtTrie.new().setup(a) if choice == "array" else TtTernary.new().setup(a)
	m.sap_budget = budget if budget > 0 else (1 << 30)
	var planted: Array = []
	var blown: Array = []
	for w in words:
		if not blown.is_empty():
			blown.append(w)
			continue
		var snap := m.snapshot()
		m.insert_auto(str(w))
		if m.sap_used() > m.sap_budget:
			m.restore(snap)
			blown.append(w)
		else:
			planted.append(w)
	return {"model": m, "planted": planted, "blown": blown}


func _begin(c: TtCard) -> void:
	if c.kind != CK.BEDS:
		push_warning("TtBeds: enkel BEDS-kaarten")
		_finish("unsupported")
		return
	beds = []
	bed_models = []
	for b in c.beds:
		var ws: Array = b.get("words", [])
		var arr := _plant("array", str(b.alphabet), ws, 0)
		var ter := _plant("ternary", str(b.alphabet), ws, 0)
		var sa := (arr.model as TtTreeModel).sap_used()
		var stn := (ter.model as TtTreeModel).sap_used()
		var inner := (arr.model as TtTrie).inner_count()
		var kids := 0
		for x in (arr.model as TtTrie).nodes.keys():
			var nd: TtNode = (arr.model as TtTrie).nodes[x]
			if nd.type == NT.INNER:
				kids += nd.kids.size()
		beds.append({"name": str(b.get("name", "")), "alphabet": str(b.alphabet), "words": ws.duplicate(),
			"budget": int(b.get("budget", 0)), "best": "array" if sa <= stn else "ternary", "array_sap": sa,
			"ternary_sap": stn, "choice": "", "first_ok": false, "tries": 0, "planted": [], "blown": [],
			"size": TtAlphabet.by_name(str(b.alphabet)).size(), "avg_kids": float(kids) / maxf(inner, 1)})
		bed_models.append(null)
	sap_budget = 0
	for b in beds:
		sap_budget += int(b.budget)
	phase = P.BED


func sap_used() -> int:
	var s := 0
	for m in bed_models:
		if m != null:
			s += (m as TtTreeModel).sap_used()
	return s


func _bed_done(i: int) -> bool:
	return str(beds[i].choice) != "" and (beds[i].blown as Array).is_empty()


func _correct() -> Dictionary:
	if phase != P.BED:
		return {"act": "none"}
	for i in beds.size():
		if not _bed_done(i):
			return {"act": "bed", "bed": i, "choice": str(beds[i].best)}
	return {"act": "none"}


func cursor() -> Dictionary:
	var info := []
	for b in beds:
		info.append({"name": b.name, "alphabet": b.alphabet, "budget": b.budget, "choice": b.choice,
			"planted": (b.planted as Array).size(), "blown": (b.blown as Array).size(), "words": (b.words as Array).size()})
	return {"phase": phase, "beds": info}


func _apply(move: Dictionary, _hint: Dictionary) -> Dictionary:
	if phase != P.BED:
		return _bump("wrong_phase")
	match str(move.get("act", "")):
		"bed":
			var i := int(move.get("bed", -1))
			var ch := str(move.get("choice", ""))
			if i < 0 or i >= beds.size() or not (ch in ["array", "ternary"]) or _bed_done(i):
				return _bump("bad_target")
			var b: Dictionary = beds[i]
			var r := _plant(ch, str(b.alphabet), b.words, int(b.budget))
			bed_models[i] = r.model
			b.tries = int(b.tries) + 1
			if int(b.tries) == 1:
				b.first_ok = ch == str(b.best)
			b.choice = ch
			b.planted = r.planted
			b.blown = r.blown
			var verdict := V.OK if ch == str(b.best) else V.WRONG_BED
			var a := int(b.size)
			var k: float = b.avg_kids
			var data := {"bed": i, "choice": ch, "a": a, "k": "%.0f" % k if is_equal_approx(k, round(k)) else "%.1f" % k,
				"pa": a, "pt": int(round(k * 3.0)), "blown": (r.blown as Array).size()}
			if not (r.blown as Array).is_empty():
				data["affects"] = (r.blown as Array).duplicate()
			_fx_add({"fx": "bed", "bed": i, "choice": ch, "planted": r.planted, "blown": r.blown,
				"sap": (r.model as TtTreeModel).sap_used(), "budget": int(b.budget)})
			var all_done := true
			for q in beds.size():
				if not _bed_done(q):
					all_done = false
			if all_done:
				_finish("bloomed", {"first_choice": first_choice_ok()})
			return {"ok": true, "verdict": verdict, "type": "BED", "data": data}
		"beds_done":
			_finish("given_up")
			return {"ok": true, "verdict": V.LOST, "type": "BED", "data": {}}
	return _bump("unknown_act")


func first_choice_ok() -> bool:
	for b in beds:
		if not bool(b.first_ok):
			return false
	return true


func all_bloom() -> bool:
	for i in beds.size():
		if not _bed_done(i):
			return false
	return not beds.is_empty()


func lookup_auto(word: String) -> Dictionary:
	for m in bed_models:
		if m != null:
			var r := (m as TtTreeModel).lookup_auto(word)
			if r.found:
				return r
	return {"found": false, "path": [], "end": -1, "reason": "null"}


func serialize() -> String:
	var parts := PackedStringArray()
	for m in bed_models:
		parts.append("-" if m == null else (m as TtTreeModel).serialize())
	return " | ".join(parts)


func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var h := correct_move()
	if str(h.get("act", "")) == "bed":
		out.append({"act": "bed", "bed": int(h.bed), "choice": "ternary" if str(h.choice) == "array" else "array"})
	return out


func _snapshot_extra() -> Dictionary:
	var ms := []
	for m in bed_models:
		ms.append(null if m == null else {"kind": (m as TtTreeModel).kind, "alpha": (m as TtTreeModel).alphabet.name,
			"snap": (m as TtTreeModel).snapshot()})
	return {"beds": beds.duplicate(true), "models": ms}


func _restore_extra(d: Dictionary) -> void:
	beds = (d.get("beds", []) as Array).duplicate(true)
	bed_models = []
	for md in d.get("models", []):
		if md == null:
			bed_models.append(null)
			continue
		var a := TtAlphabet.by_name(str(md.alpha))
		var m: TtTreeModel = TtTrie.new().setup(a) if int(md.kind) == TtCodes.Kind.TRIE else TtTernary.new().setup(a)
		m.restore(md.snap)
		bed_models.append(m)


func _invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	for m in bed_models:
		if m != null:
			errs.append_array((m as TtTreeModel).invariants())
	return errs
