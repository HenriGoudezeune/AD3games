class_name TtBloom
## Automatische testrun na een level (GDD §2.2, §8.9): voor elk woord vliegt een bij volgens het JUISTE algoritme
## over de boom van de speler. Suffix/Ukkonen: voor elk suffix j moet locate(σ_j) exact in het blad met start j eindigen.
## -> [{word, expected, found, ok, path, end, reason, cause_seq, j}]


static func run(model: TtTreeModel, present: PackedStringArray, absent: PackedStringArray) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if model is TtSuffixTree:
		var sm := model as TtSuffixTree
		for jj in range(sm.text.length()):
			var sig := sm.text.substr(jj)
			var r := sm.lookup_auto(sig)
			var ok: bool = bool(r.exact_leaf) and sm.node(int(r.end)).start == jj
			var e := {"word": sig, "j": jj, "expected": true, "found": ok, "ok": ok, "path": r.path, "end": int(r.end),
				"reason": str(r.reason), "cause_seq": -1}
			if not ok:
				e.cause_seq = _cause(model, sig)
			out.append(e)
		return out
	var pres := present
	if model is TtBeds and pres.is_empty():
		pres = PackedStringArray()
		for b in (model as TtBeds).beds:
			for w in b.words:
				pres.append(str(w))
	for w in pres:
		out.append(_one(model, w, true))
	for w in absent:
		out.append(_one(model, w, false))
	return out


static func _one(model: TtTreeModel, w: String, expected: bool) -> Dictionary:
	var r := model.lookup_auto(w)
	var found := bool(r.found)
	var e := {"word": w, "expected": expected, "found": found, "ok": found == expected, "path": r.get("path", []),
		"end": int(r.get("end", -1)), "reason": str(r.get("reason", "")), "cause_seq": -1, "j": -1}
	if found != expected:
		e.cause_seq = _cause(model, w)
	return e


static func _cause(model: TtTreeModel, w: String) -> int:
	var c := model.log.cause_of_word(w)
	return int(c.get("seq", -1))


## Fractie geslaagde bijen (1.0 als er geen zijn).
static func ratio(results: Array) -> float:
	if results.is_empty():
		return 1.0
	var ok := 0
	for r in results:
		if bool(r.ok):
			ok += 1
	return float(ok) / results.size()
