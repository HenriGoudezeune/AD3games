extends RefCounted
## Gedeelde helpers voor de Trietuin-suites.

var _id := 1000


func card(kind: String, word: String = "", extra: Dictionary = {}) -> TtCard:
	_id += 1
	var d := {"kind": kind, "word": word}
	d.merge(extra)
	return TtCard.from_spec(_id, d)


## Speelt een kaart perfect met het orakel; controleert invariants na elke zet (bad[0]++ bij een fout).
func play(model: TtTreeModel, c: TtCard, bad: Array = [0], check_snap: bool = false) -> Dictionary:
	model.begin(c)
	var guard := 0
	while model.card != null and guard < 10000:
		guard += 1
		if check_snap:
			var s1 := model.snapshot()
			model.restore(s1)
			if model.snapshot() != s1:
				bad[0] += 1
		var m := model.correct_move()
		if m.act == "none":
			break
		var r := model.apply(m)
		if not r.ok:
			bad[0] += 1
			break
		if int(r.verdict) != TtCodes.Verdict.OK:
			bad[0] += 1
		if not model.invariants().is_empty():
			bad[0] += 1
	return c.outcome


func seed(model: TtTreeModel, word: String, bad: Array = [0]) -> Dictionary:
	return play(model, card("seed", word), bad)


func bee(model: TtTreeModel, word: String, wasp := false) -> Dictionary:
	return play(model, card("bee", word, {"wasp": wasp}))


## Laatste logentry van een type.
func last(model: TtTreeModel, type: String) -> Dictionary:
	var l := model.log.of_type(type)
	return l[-1] if not l.is_empty() else {}
