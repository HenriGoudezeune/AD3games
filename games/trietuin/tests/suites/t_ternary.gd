extends RefCounted
## Ternary: GDD §9 T17–T21 (Figuur 16, omzetten, level 3-2, Oef. 19b, ASCII).

const V := TtCodes.Verdict
const PH := TtCodes.Phase
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")
const F16 := "{C{A[CA_] G[CGGA_]} G{G[GGGG_]} T{A[TAC_] C[TCCA_]}}"
const F16T := "(G (C . (G (A . [CA_] .) [CGGA_] .) .) (G . [GGGG_] .) (T . (A . [TAC_] (C . [TCCA_] .)) .))"
const F17 := "{C{G{A{C{C[CGACCC_] T[CGACTAA_]}} T[CGTAAT_]}} G{G{A[GGA_] C{G{A[GGCGAA_] T[GGCGTA_]}} G{G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}}"
const W32 := ["mier_", "bij_", "roos_", "bijen_", "tak_", "blad_", "bloem_", "zaad_", "sap_", "tuin_", "bes_", "rank_"]
const END32 := "(m (b . (i (e . [bes_] .) (j . (_ (e . [bijen_] .) [bij_] .) .) (l . (a . [blad_] (o . [bloem_] .)) .)) .) [mier_] (r . (o (a . [rank_] .) [roos_] .) (t (s . [sap_] .) (a . [tak_] (u . [tuin_] .)) (z . [zaad_] .))))"

var h := H.new()


func run(t) -> void:
	_t17(t)
	_t18(t)
	_t19(t)
	_t20(t)
	_t21(t)
	_errors(t)


func _t17(t) -> void:
	t.section("T17 Figuur 16 via invoegen")
	var m := TtTernary.new().setup(TtAlphabet.dna())
	var bad := [0]
	for w in ["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"]:
		h.seed(m, w, bad)
	t.eq(bad[0], 0, "orakel + invariants")
	var want := "(G (C . (G (A . [CA_] .) [CGGA_] .) .) [GGGG_] (T . (A . [TAC_] (C . [TCCA_] .)) .))"
	t.notation(m.serialize(), want, "boom")
	t.eq(m.balls(), 7, "7 bollen")
	t.eq(m.sap_used(), 21, "21 sap")
	t.notation(TtReference.ternary_of(["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"], TtAlphabet.dna()), want, "referentie")
	for w in ["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"]:
		t.eq(h.bee(m, w).result, "found", w)
	var m2 := TtTernary.new().setup(TtAlphabet.dna(), want)
	t.notation(m2.serialize(), want, "laden")


func _convert(order: Dictionary) -> TtTernary:
	var m := TtTernary.new().setup(TtAlphabet.dna())
	m.load_trie(F16)
	m.begin(h.card("ternarify"))
	while m.card != null:
		var cur := m.cursor()
		var pk := int(cur.placing_node)
		var name := m.path_string(pk)
		var seq: Array = order.get(name, [])
		var letter := ""
		for k in seq:
			if (cur.remaining as PackedStringArray).has(k):
				letter = k
				break
		if letter == "":
			letter = str(m.correct_move().letter)
		var r := m.apply({"act": "place", "letter": letter})
		if not r.ok:
			break
	return m


func _t18(t) -> void:
	t.section("T18 Figuur 16 via omzetten")
	var ws := PackedStringArray(["CA_", "CGGA_", "GGGG_", "TAC_", "TCCA_"])
	var m := _convert({"": ["G", "C", "T"], "C": ["G", "A"], "G": ["G"], "T": ["A", "C"]})
	t.notation(m.serialize(), F16T, "Figuur 16 onder")
	t.eq(m.balls(), 8, "8 bollen")
	t.eq(m.sap_used(), 24, "24 sap")
	t.eq(m.comparisons(ws), 16, "16 vergelijkingen")
	t.ok(m.invariants().is_empty(), "invariants " + str(m.invariants()))
	t.eq(_convert({"": ["C", "G", "T"]}).comparisons(ws), 17, "wortel C,G,T: 17")
	t.eq(_convert({"": ["C", "T", "G"]}).comparisons(ws), 16, "wortel C,T,G: 16")
	# orakel (bot) geeft exact de figuur
	var mo := TtTernary.new().setup(TtAlphabet.dna())
	mo.load_trie(F16)
	mo.word_order = PackedStringArray(["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"])
	var bad := [0]
	var o := h.play(mo, h.card("ternarify"), bad, true)
	t.eq(bad[0], 0, "orakel OK + snapshot")
	t.notation(mo.serialize(), F16T, "orakel = Figuur 16")
	t.eq(int(o.comparisons), 16, "outcome.comparisons")
	t.eq(int(o.optimum), 16, "outcome.optimum")
	for w in ws:
		t.eq(h.bee(mo, w).result, "found", w)
	t.eq(h.bee(mo, "TA_").result, "rejected", "TA_ Niet hier")


func _t19(t) -> void:
	t.section("T19 level 3-2 (bot)")
	var m := TtTernary.new().setup(TtAlphabet.az())
	m.sap_budget = 70
	var bad := [0]
	for w in W32:
		var c := h.card("seed", w)
		m.begin(c)
		while m.card != null:
			var mv := m.correct_move()
			if w == "bijen_" and mv.act == "split":
				t.eq(int(mv.j), 3, "bijen_: j = 3")
			var r := m.apply(mv)
			if not r.ok or r.verdict != V.OK:
				bad[0] += 1
			if not m.invariants().is_empty():
				bad[0] += 1
		if w == "bijen_":
			var lf := -1
			for x in m.nodes.keys():
				if m.node(x).is_leaf() and m.node(x).label == "bijen_":
					lf = x
			var eb := m.node(m.node(lf).parent)
			var root_ball := m.node(eb.parent)
			t.eq([root_ball.ch, eb.ch, root_ball.lo == eb.id], ["_", "e", true], "bol _ wortel, e kleiner-kind")
	t.eq(bad[0], 0, "orakel OK")
	t.notation(m.serialize(), END32, "eindboom")
	t.eq(m.balls(), 18, "18 bollen")
	t.eq(m.sap_used(), 54, "54 sap")
	var tr := TtTrie.new().setup(TtAlphabet.az())
	for w in W32:
		tr.insert_auto(w)
	t.eq(tr.inner_count(), 7, "gewone trie: 7 toppen")
	t.eq(tr.sap_used(), 189, "189 sap")
	t.notation(TtReference.ternary_of(W32, TtAlphabet.az()), END32, "referentie")
	var expect := {"bloem_": "found", "tuin_": "found", "blos_": "rejected", "zon_": "rejected", "kip_": "not_found", "bij_": "found"}
	for w in expect.keys():
		t.eq(h.bee(m, w).result, expect[w], "bij " + w)


func _t20(t) -> void:
	t.section("T20 Figuur 17 omzetten (Oef. 19b)")
	var m := TtTernary.new().setup(TtAlphabet.dna())
	m.load_trie(F17)
	var ws := TtNotation.leaves(TtNotation.parse_trie(F17))
	m.word_order = ws
	t.eq(m.optimal_comparisons(), 49, "optimum 49")
	var bad := [0]
	h.play(m, h.card("ternarify"), bad)
	t.eq(bad[0], 0, "orakel")
	t.eq(m.comparisons(ws), 49, "orakel haalt 49")
	t.eq(m.balls(), 18, "18 bollen")
	t.eq(m.sap_used(), 54, "54 sap")
	# brute force: willekeurige plantvolgordes halen nooit minder dan 49
	var rng := RandomNumberGenerator.new()
	rng.seed = 20
	var best := 1 << 30
	for it in 200:
		var mm := TtTernary.new().setup(TtAlphabet.dna())
		mm.load_trie(F17)
		mm.begin(h.card("ternarify"))
		while mm.card != null:
			var rem: PackedStringArray = mm.cursor().remaining
			mm.apply({"act": "place", "letter": rem[rng.randi_range(0, rem.size() - 1)]})
		best = mini(best, mm.comparisons(ws))
		if it == 0:
			t.ok(mm.invariants().is_empty() and mm.bst_warnings().is_empty(), "willekeurige volgorde is geldig")
	t.ok(best >= 49, "geen volgorde beter dan 49 (beste: %d)" % best)


func _t21(t) -> void:
	t.section("T21 ASCII-storm")
	var g := TtTrie.new().setup(TtAlphabet.dna().with_cost(256), F16)
	t.eq(g.sap_used(), 1024, "gewone Fig. 16 met 256 knoppen: 1024")
	var tn := TtTernary.new().setup(TtAlphabet.dna().with_cost(256), F16T)
	t.eq(tn.sap_used(), 24, "ternary blijft 24")
	t.eq(TtTrie.new().setup(TtAlphabet.dna(), F16).sap_used(), 20, "gewone Fig. 16: 20")


func _errors(t) -> void:
	t.section("ternary foutpaden")
	var m := TtTernary.new().setup(TtAlphabet.dna(), F16T)
	var snap := m.snapshot()
	m.begin(h.card("seed", "AT_"))
	var r := m.apply({"act": "go", "dir": "hi"})
	t.eq(r.verdict, V.WRONG_DIR, "groter terwijl A < G")
	t.eq(m.log.coach_line(h.last(m, "GO")), "`A` < `G` → kleiner.", "coachzin")
	m.auto_finish_card()
	t.ok(not m.lookup_auto("AT_").found, "AT_ onvindbaar")
	t.ok(not m.bst_warnings().is_empty(), "BST-waarschuwing")
	t.ok(m.invariants().is_empty(), "structuur blijft geldig")
	m.restore(snap)
	m.begin(h.card("seed", "CC_"))
	r = m.apply({"act": "go", "dir": "eq"})
	t.eq(r.verdict, V.WRONG_DIR, "gelijk terwijl C ≠ G")
	m.restore(snap)
	m.begin(h.card("ternarify"))
	t.eq(m.phase, PH.IDLE, "niets om te zetten: kaart meteen af")
