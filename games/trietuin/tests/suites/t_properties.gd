extends RefCounted
## Property-tests over willekeurige invoer (deterministische seeds).

const V := TtCodes.Verdict
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")

var h := H.new()
var rng := RandomNumberGenerator.new()


func run(t) -> void:
	rng.seed = 31337
	_tries(t)
	_ternary_vs_trie(t)
	_delete(t)
	_random_play(t)
	_monotone(t)
	_layout_random(t)


func _rand_words(n: int, letters: String, maxlen: int, minlen := 1) -> Array:
	var set := {}
	var guard := 0
	while set.size() < n and guard < 10000:
		guard += 1
		var w := ""
		for k in rng.randi_range(minlen, maxlen):
			w += letters[rng.randi_range(0, letters.length() - 1)]
		set[w + "_"] = true
	return set.keys()


func _tries(t) -> void:
	t.section("eigenschap: gewone trie via het orakel == referentie (1200 sets)")
	var a := TtAlphabet.dna()
	var bad := 0
	var bad_lookup := 0
	var bad_inv := 0
	for it in 1200:
		var ws := _rand_words(rng.randi_range(1, 10), "ACGT", 6)
		var m := TtTrie.new().setup(a)
		var b := [0]
		for w in ws:
			h.seed(m, w, b)
		bad_inv += b[0]
		if m.serialize() != TtReference.trie_of(ws, a):
			bad += 1
		var d := TtNotation.parse_trie(m.serialize())
		for q in _rand_words(5, "ACGT", 6):
			if m.lookup_auto(q).found != ws.has(q) or TtReference.trie_has(d, q) != ws.has(q):
				bad_lookup += 1
		if TtNotation.serialize_trie(TtNotation.parse_trie(m.serialize()), a) != m.serialize():
			bad += 1
	t.eq(bad, 0, "trie == trie_of(woorden) en notatie-roundtrip")
	t.eq(bad_lookup, 0, "opzoeken == lidmaatschap")
	t.eq(bad_inv, 0, "orakel OK + invariants")
	t.section("eigenschap: Patricia zoek == Algoritme 1-referentie")
	var bz := 0
	for it in 300:
		var ws := _rand_words(rng.randi_range(2, 9), "ACGT", 7)
		var pn := TtReference.patricia_of(TtReference.trie_of(ws, a), a)
		if pn.begins_with("["):
			continue
		var m := TtPatricia.new().setup(a, pn)
		var pd := TtNotation.parse_patricia(pn)
		for q in ws + _rand_words(4, "ACGT", 7):
			var z := m.zoek(q)
			var r := TtReference.zoek_patricia(pd, q)
			var reads := []
			for s in z.steps:
				reads.append(int(s.pos))
			if z.found != r.found or reads != r.reads or str(z.end) != str(r.end):
				bz += 1
	t.eq(bz, 0, "zoek == referentie (sporen, einde, gevonden)")


func _ternary_vs_trie(t) -> void:
	t.section("eigenschap: ternary-zoeken == trie-zoeken (1000 sets)")
	var bad := 0
	var bad_shape := 0
	var bad_balls := 0
	for it in 1000:
		var big := it % 2 == 0
		var a := TtAlphabet.az() if big else TtAlphabet.dna()
		var letters := "abcdefghijklmnopqrstuvwxyz" if big else "ACGT"
		var ws := _rand_words(rng.randi_range(1, 9), letters if not big else letters.substr(0, rng.randi_range(3, 26)), 5)
		var tm := TtTernary.new().setup(a)
		var tr := TtTrie.new().setup(a)
		var b := [0]
		for w in ws:
			h.seed(tm, w, b)
			tr.insert_auto(w)
		bad += b[0]
		if tm.serialize() != TtReference.ternary_of(ws, a):
			bad_shape += 1
		if not tm.bst_warnings().is_empty():
			bad_shape += 1
		for q in ws + _rand_words(5, letters.substr(0, 5), 5):
			if tm.lookup_auto(q).found != tr.lookup_auto(q).found:
				bad += 1
		# omzetten van de gewone trie (orakel) geeft evenveel bollen als er (top, letter)-paren zijn
		var conv := TtTernary.new().setup(a)
		conv.load_trie(tr.serialize())
		conv.word_order = PackedStringArray(ws)
		h.play(conv, h.card("ternarify"), b)
		var pairs := 0
		for nd in tr.nodes.values():
			if (nd as TtNode).type == TtNode.Type.INNER:
				pairs += (nd as TtNode).kids.size()
		if conv.balls() != pairs:
			bad_balls += 1
		for q in ws:
			if not conv.lookup_auto(q).found:
				bad += 1
		if conv.comparisons(PackedStringArray(ws)) != conv.optimal_comparisons():
			bad += 1
	t.eq(bad, 0, "ternary == trie bij opzoeken; omzetten met orakel = optimum")
	t.eq(bad_shape, 0, "ternary via orakel == referentie, BST-orde intact")
	t.eq(bad_balls, 0, "omgezette boom: één bol per (top, letter)")


func _delete(t) -> void:
	t.section("eigenschap: verwijderen (knip op de juiste plaats)")
	var a := TtAlphabet.dna()
	var bad := 0
	for it in 400:
		var ws := _rand_words(rng.randi_range(2, 9), "ACGT", 6)
		var m := TtTrie.new().setup(a)
		for w in ws:
			m.insert_auto(w)
		var left: Array = ws.duplicate()
		for k in rng.randi_range(1, ws.size() - 1):
			var w: String = left[rng.randi_range(0, left.size() - 1)]
			var b := [0]
			h.play(m, h.card("prune", w), b)
			bad += b[0]
			left.erase(w)
			for x in ws:
				if m.lookup_auto(x).found != left.has(x):
					bad += 1
			if not m.dead_wood().is_empty() or not m.invariants().is_empty():
				bad += 1
	t.eq(bad, 0, "na elke knip: precies de resterende woorden, geen dood hout")


## Willekeurige fouten breken nooit de structuur, en elk CALM-level eindigt.
func _random_play(t) -> void:
	t.section("eigenschap: willekeurig spel (p = 0.4) breekt niets")
	var bad := 0
	var unfinished := 0
	for id in TtLevels.ids():
		for sd in [1, 2, 3]:
			var bot := TtLevelBot.new("random", sd * 97 + id.hash() % 1000)
			bot.p = 0.4
			var spec := TtLevels.get_spec(id)
			var badc := [0]
			var rep := bot.play(spec, 0.1, 900.0, func(dd: TtDirector):
				if not dd.model.invariants().is_empty():
					badc[0] += 1)
			bad += badc[0]
			if rep.is_empty():
				unfinished += 1
	t.eq(bad, 0, "invariants na elke zet")
	t.eq(unfinished, 0, "elk level eindigt")


## Sterren en honing zijn monotoon: perfect spel ≥ elke foutmodus.
func _monotone(t) -> void:
	t.section("eigenschap: scoring monotoon (perfect ≥ elke foutmodus)")
	var modes := ["first", "every", "bump", "hint", "rewind", "act:split", "act:answer", "act:move", "act:read",
		"act:go", "act:attach", "act:label", "act:rule", "act:link", "act:follow", "act:locate", "act:where",
		"act:count", "act:pick", "act:owner", "act:prune", "act:cut", "act:place", "act:bed", "act:short", "act:hop",
		"pluck_wasp", "random"]
	var bad := 0
	var cmp := 0
	var strictly := 0
	for id in TtLevels.ids():
		var spec := TtLevels.get_spec(id)
		var perfect := TtLevelBot.new().play(spec)
		for md in modes:
			var bot := TtLevelBot.new(md, 5)
			var rep := bot.play(spec)
			if rep.is_empty():
				continue
			cmp += 1
			if int(rep.n_stars) > int(perfect.n_stars) or int(rep.honey) > int(perfect.honey):
				bad += 1
				if bad <= 5:
					t.ok(false, "%s %s: %d★ %d honing > perfect %d★ %d" % [id, md, rep.n_stars, rep.honey,
						perfect.n_stars, perfect.honey])
			if int(rep.n_stars) < 3:
				strictly += 1
	t.eq(bad, 0, "perfect ≥ foutmodus (%d vergelijkingen)" % cmp)
	t.ok(cmp > 300, "genoeg vergelijkingen: %d" % cmp)
	t.ok(strictly > 100, "foutmodi kosten sterren: %d" % strictly)


func _layout_random(t) -> void:
	t.section("eigenschap: layout op willekeurige bomen")
	var bad := 0
	var rect := Rect2(0, 220, 1920, 640)
	for it in 100:
		var ws := _rand_words(rng.randi_range(1, 14), "ACGT", 6)
		var m := TtTrie.new().setup(TtAlphabet.dna())
		for w in ws:
			m.insert_auto(w)
		var lay := TtLayout.compute(m.render_nodes(), m.kind, rect)
		var pts: Array = []
		for d in m.render_nodes():
			if int(d.type) == TtNode.Type.LEAF:
				pts.append(lay[int(d.id)])
		for i in pts.size():
			for k in range(i + 1, pts.size()):
				if (pts[i] as Vector2).distance_to(pts[k]) < 60.0:
					bad += 1
	t.eq(bad, 0, "geen overlappende vruchten")
