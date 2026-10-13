extends RefCounted
## Gewone trie: GDD §9 T01–T09 (Figuur 13/14, Oef. 17, foutpaden).

const V := TtCodes.Verdict
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")
const F13 := "{A{A[AAGTT_] C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
const F14 := "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
const O17A := "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}"
const O17B := "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}"

var h := H.new()


func run(t) -> void:
	_t01(t)
	_t02_t03(t)
	_t04(t)
	_t05(t)
	_t06(t)
	_t07(t)
	_t08(t)
	_t09(t)
	_signals(t)


func _trie(s := "{}") -> TtTrie:
	return TtTrie.new().setup(TtAlphabet.dna(), s)


func _t01(t) -> void:
	t.section("T01 Figuur 13 laden/serialiseren")
	var m := _trie(F13)
	t.notation(m.serialize(), F13, "serialize")
	t.eq(m.inner_count(), 6, "6 interne toppen")
	t.eq(m.sap_used(), 30, "sap 30")
	t.ok(m.invariants().is_empty(), "invariants: " + str(m.invariants()))
	t.eq(m.words().size(), 5, "5 woorden")


func _t02_t03(t) -> void:
	t.section("T02 Figuur 14 = Figuur 13 + AAGCGA_")
	var m := _trie(F13)
	var c := h.card("seed", "AAGCGA_")
	m.begin(c)
	var seen_split := {}
	while m.card != null:
		var mv := m.correct_move()
		if mv.act == "split":
			seen_split = {"j": int(mv.j), "d": int(m.cursor().depth)}
		var r := m.apply(mv)
		t.ok(r.ok and r.verdict == V.OK, "orakelzet OK")
		t.ok(m.invariants().is_empty(), "invariants")
	t.eq(seen_split, {"j": 3, "d": 2}, "split j=3 bij d=2")
	t.notation(m.serialize(), F14, "Figuur 14")
	t.eq(m.inner_count(), 8, "8 toppen")
	t.eq(int(h.last(m, "SPLIT").data.grown), 2, "2 toppen gegroeid")
	t.section("T03 Oef. 17a")
	c = h.card("seed", "TGCGAAG_")
	m.begin(c)
	while m.card != null:
		var mv := m.correct_move()
		if mv.act == "split":
			seen_split = {"j": int(mv.j), "d": int(m.cursor().depth)}
		m.apply(mv)
	t.eq(seen_split, {"j": 6, "d": 4}, "split j=6 bij d=4")
	t.eq(int(h.last(m, "SPLIT").data.grown), 3, "3 toppen gegroeid")
	t.notation(m.serialize(), O17A, "Oef. 17a")
	t.eq(m.inner_count(), 11, "11 toppen")


func _t04(t) -> void:
	t.section("T04 Oef. 17b verwijderen")
	var m := _trie(O17A)
	var c := h.card("prune", "TA_")
	m.begin(c)
	while m.phase != TtCodes.Phase.CUT:
		m.apply(m.correct_move())
	var cut := int(m.correct_move().node)
	t.eq(m.path_string(cut), "TA", "juiste knip = top TA")
	var snap := m.snapshot()
	m.apply(m.correct_move())
	t.notation(m.serialize(), O17B, "eindboom")
	t.eq(m.inner_count(), 10, "10 toppen")
	t.eq(m.sap_used(), 50, "50 sap")
	# te hoog
	var m2 := _trie(O17A)
	m2.restore(snap)
	var tnode := int(m2.node(cut).parent)
	var r := m2.apply({"act": "cut", "node": tnode})
	t.eq(r.verdict, V.CUT_TOO_HIGH, "knip op T = te hoog")
	var ws := m2.words()
	for w in ["TGG_", "TGCGAAA_", "TGCGAAG_", "TA_"]:
		t.ok(not ws.has(w), w + " valt mee")
	var cause := m2.log.cause_of_word("TGG_")
	t.eq(str(cause.get("type", "")), "CUT", "oorzaak TGG_ = knip")
	t.ok(m2.log.coach_line(cause).contains("Knip net onder `T`"), "coachzin: " + m2.log.coach_line(cause))
	# te laag
	var m3 := _trie(O17A)
	m3.restore(snap)
	var leaf := int(m3.cursor().leaf)
	r = m3.apply({"act": "cut", "node": leaf})
	t.eq(r.verdict, V.CUT_TOO_LOW, "knip op de vrucht = te laag")
	t.eq(m3.dead_wood(), [cut], "dead_wood = [TA]")
	t.eq(m3.sap_used(), 55, "dood hout drinkt sap")
	var rn := m3.render_nodes()
	var dead_flag := false
	for d in rn:
		if int(d.id) == cut:
			dead_flag = bool(d.dead)
	t.ok(dead_flag, "render_nodes: dead")
	# niet op het pad
	var m4 := _trie(O17A)
	m4.restore(snap)
	r = m4.apply({"act": "cut", "node": m4.root})
	t.ok(not r.ok and r.reason == "not_on_path", "wortel knippen kan niet")
	t.eq(m4.snapshot(), snap, "staat ongewijzigd na klonk")


func _t05(t) -> void:
	t.section("T05 opzoeken in de T04-boom")
	var m := _trie(O17B)
	for w in ["ACGT_", "TGCGAAG_", "TGCGAAA_", "TGG_", "AAGCGA_"]:
		t.ok(m.lookup_auto(w).found, w + " gevonden")
		var o := h.bee(m, w)
		t.eq(o.result, "found", w + " bij: found")
	for w in ["TA_", "GA_"]:
		var r := m.lookup_auto(w)
		t.ok(not r.found and r.reason == "null", w + " eindigt op lege knop")
		t.eq(h.bee(m, w).result, "not_found", w + " bij: niet gevonden")
	var r2 := m.lookup_auto("AAGC_")
	t.ok(not r2.found and r2.reason == "leaf_mismatch" and m.node(int(r2.end)).label == "AAGCGA_", "AAGC_ eindigt op AAGCGA_")
	t.eq(h.bee(m, "AAGC_").result, "rejected", "AAGC_: Niet hier")
	t.notation(m.serialize(), O17B, "opzoeken muteert niets")


func _play_words(m: TtTrie, words: Array, t, tag: String) -> Array:
	var js := []
	for w in words:
		var c := h.card("seed", w)
		m.begin(c)
		while m.card != null:
			var mv := m.correct_move()
			if mv.act == "split":
				js.append(int(mv.j))
			var r := m.apply(mv)
			if not t.ok(r.ok and r.verdict == V.OK, "%s %s: orakelzet %s" % [tag, w, str(mv)]):
				return js
			t.ok(m.invariants().is_empty(), "%s invariants" % tag)
	return js


func _t06(t) -> void:
	t.section("T06 level 1-1 (bot)")
	var m := _trie()
	var js := _play_words(m, ["TGG_", "ACGT_", "TA_", "AAGTT_", "TGCGAAA_"], t, "1-1")
	t.notation(m.serialize(), "{A{A[AAGTT_] C[ACGT_]} T{A[TA_] G{C[TGCGAAA_] G[TGG_]}}}", "eindboom")
	t.eq(m.inner_count(), 4, "4 toppen")
	t.eq(js, [1, 1, 2], "j-waarden")
	t.eq(h.bee(m, "TGA_").result, "not_found", "TGA_ afwezig")
	t.eq(h.bee(m, "GA_").result, "not_found", "GA_ afwezig")


func _t07(t) -> void:
	t.section("T07 level 1-3 (bot)")
	var m := _trie()
	m.sap_budget = 70
	var words := ["GATTACA_", "GATTAGA_", "CAT_", "GATC_", "CATTAG_", "ACGTACGT_", "ACGTTT_"]
	var grown := []
	for w in words:
		var c := h.card("seed", w)
		m.begin(c)
		var hang_d := -1
		while m.card != null:
			var mv := m.correct_move()
			var cur := m.cursor()
			var r := m.apply(mv)
			t.ok(r.ok and r.verdict == V.OK, "orakelzet")
			if r.done and mv.act == "move":
				hang_d = int(cur.depth)
		if w == "GATC_":
			t.eq(hang_d, 3, "GATC_ hangt aan lege knop op d = 3")
		var sp := h.last(m, "SPLIT")
		grown.append(int(sp.data.grown) if not sp.is_empty() and str(sp.data.s) == w else 0)
	t.eq(grown[1], 5, "GATTAGA_ groeit 5 toppen")
	t.eq(grown[4], 3, "CATTAG_ groeit 3 toppen")
	t.eq(grown[6], 4, "ACGTTT_ groeit 4 toppen")
	t.notation(m.serialize(), "{A{C{G{T{A[ACGTACGT_] T[ACGTTT_]}}}} C{A{T{T[CATTAG_] _[CAT_]}}} G{A{T{C[GATC_] T{A{C[GATTACA_] G[GATTAGA_]}}}}}}", "eindboom")
	t.eq(m.inner_count(), 13, "13 toppen")
	t.eq(m.sap_used(), 65, "65 sap")
	for w in ["GATTA_", "CATT_", "ACGTAC_"]:
		t.ok(not m.lookup_auto(w).found, w + " afwezig")


func _t08(t) -> void:
	t.section("T08 foutpaden trie")
	var m := _trie()
	for w in ["GATTACA_", "GATTAGA_", "CAT_", "GATC_", "CATTAG_", "ACGTACGT_"]:
		h.seed(m, w)
	var snap0 := m.snapshot()
	var sap0 := m.sap_used()
	m.begin(h.card("seed", "ACGTTT_"))
	while m.phase != TtCodes.Phase.COMPARE:
		m.apply(m.correct_move())
	var snap := m.snapshot()
	var r := m.apply({"act": "split", "j": 2})
	t.ok(not r.ok and r.reason == "same_letter", "split met l_j == s_j: klonk")
	t.eq(m.snapshot().nodes, snap.nodes, "staat ongewijzigd")
	r = m.apply({"act": "split", "j": 0})
	t.ok(not r.ok and r.reason == "before_d", "j < d: klonk")
	r = m.apply({"act": "split", "j": 5})
	t.eq(r.verdict, V.J_LATE, "j = 5 i.p.v. 4: J_LATE")
	var mis := []
	for id in m.misplaced():
		mis.append(m.node(id).label)
	t.eq(mis, ["ACGTACGT_"], "misplaced bevat ACGTACGT_")
	t.eq(m.sap_used() - sap0, 25, "5 toppen (1 extra = 5 sap)")
	var e := h.last(m, "SPLIT")
	t.eq(m.log.coach_line(e), "`ACGTACGT_` en `ACGTTT_` verschillen al op positie 4, niet pas op 5.", "coachzin J_LATE")
	t.eq(m.log.cause_of_word("ACGTACGT_").seq, e.seq, "oorzaak ACGTACGT_")
	t.ok(not e.before.is_empty(), "before-snapshot bij misstap")
	t.ok(not m.lookup_auto("ACGTACGT_").found, "ACGTACGT_ onvindbaar")
	# same bij verschillende woorden
	m.restore(snap0)
	m.begin(h.card("seed", "ACGTTT_"))
	while m.phase != TtCodes.Phase.COMPARE:
		m.apply(m.correct_move())
	r = m.apply({"act": "same"})
	t.eq(r.verdict, V.WRONG_SAME, "same bij verschillende woorden")
	t.ok(not m.words().has("ACGTTT_"), "woord ontbreekt")
	# same bij gelijke woorden; split onmogelijk
	m.begin(h.card("seed", "CAT_"))
	while m.phase != TtCodes.Phase.COMPARE:
		m.apply(m.correct_move())
	r = m.apply({"act": "split", "j": 3})
	t.ok(not r.ok and r.reason == "no_diff", "gelijke woorden: split kan niet")
	r = m.apply({"act": "same"})
	t.ok(r.ok and r.verdict == V.OK and r.done, "zit er al")
	# verkeerde letter bij zaadje
	m.begin(h.card("seed", "TTT_"))
	r = m.apply({"act": "move", "letter": "C"})
	t.eq(r.verdict, V.WRONG_LETTER, "verkeerde tak volgen")
	while m.card != null:
		m.apply(m.correct_move())
	t.ok(not m.lookup_auto("TTT_").found, "TTT_ verdwaald")
	t.ok(m.misplaced().size() >= 1, "verdwaalde vrucht gemarkeerd")
	# verkeerde lege knop
	m.restore(snap0)
	m.begin(h.card("seed", "TT_"))
	r = m.apply({"act": "move", "letter": "_"})
	t.eq(r.verdict, V.WRONG_KNOP, "vrucht aan verkeerde lege knop")
	t.ok(r.done, "kaart klaar")
	# pluk bij andere vrucht
	m.begin(h.card("bee", "CATT_"))
	while m.phase != TtCodes.Phase.AT_LEAF:
		m.apply(m.correct_move())
	r = m.apply({"act": "answer", "found": true})
	t.eq(r.verdict, V.WRONG_ANSWER, "Pluk bij andere vrucht")
	t.ok(m.words().has("CATTAG_"), "geen wesp: vrucht blijft")
	# sap op
	var m2 := _trie()
	m2.sap_budget = 10
	h.seed(m2, "GATTACA_")
	m2.begin(h.card("seed", "GATTAGA_"))
	while m2.phase != TtCodes.Phase.COMPARE:
		m2.apply(m2.correct_move())
	r = m2.apply(m2.correct_move())
	t.ok(not r.ok and r.reason == "no_sap" and r.done, "sap op: zaadje waait weg")
	t.eq(m2.sap_used(), 5, "niets gegroeid")
	t.eq(str(m2.log.cause_of_word("GATTAGA_").get("type", "")), "BUMP", "oorzaak = sap op")


func _t09(t) -> void:
	t.section("T09 Figuur 15/16/17 vanaf leeg")
	var f15 := ["CGCCCT_", "CGCCTT_", "CGCGAA_", "GA_", "GGCC_", "GGCGG_"]
	var f15n := "{C{G{C{C{C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]}}} G{A[GA_] G{C{C[GGCC_] G[GGCGG_]}}}}"
	var f17 := ["CGACCC_", "CGACTAA_", "CGTAAT_", "GGA_", "GGCGAA_", "GGCGTA_", "GGGGG_", "GGGTTT_", "GGTT_"]
	var f17n := "{C{G{A{C{C[CGACCC_] T[CGACTAA_]}} T[CGTAAT_]}} G{G{A[GGA_] C{G{A[GGCGAA_] T[GGCGTA_]}} G{G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}}"
	var f16 := ["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 15
	for k in 6:
		for pair in [[f15, f15n], [f17, f17n], [f16, "{C{A[CA_] G[CGGA_]} G[GGGG_] T{A[TAC_] C[TCCA_]}}"]]:
			var ws: Array = (pair[0] as Array).duplicate()
			if k > 0:
				for i in range(ws.size() - 1, 0, -1):
					var jj := rng.randi_range(0, i)
					var tmp = ws[i]
					ws[i] = ws[jj]
					ws[jj] = tmp
			var m := _trie()
			var bad := [0]
			for w in ws:
				h.seed(m, w, bad)
			t.notation(m.serialize(), pair[1], "volgorde %s" % str(ws))
			t.eq(bad[0], 0, "orakel + invariants")
			t.notation(TtReference.trie_of(ws, TtAlphabet.dna()), pair[1], "referentie")


func _signals(t) -> void:
	t.section("trie: signalen en volgorde")
	var m := _trie(F13)
	var got := []
	m.changed.connect(func(fx): got.append("fx:" + str(fx.fx)))
	m.sap_changed.connect(func(u, dl): got.append("sap:%d:%d" % [u, dl]))
	m.event_logged.connect(func(e): got.append("log:" + str(e.type)))
	m.card_finished.connect(func(c, o): got.append("done:" + str(o.result)))
	m.card_started.connect(func(c): got.append("start"))
	h.seed(m, "AAGCGA_")
	t.eq(got, ["start", "log:CARD_START", "fx:move", "log:MOVE", "fx:move", "fx:compare", "log:MOVE",
		"fx:grow", "fx:rehang", "fx:hang", "sap:40:10", "log:SPLIT", "log:CARD_END", "done:planted"], "volgorde")
	h.unhook(m)
