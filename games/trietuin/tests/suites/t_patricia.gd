extends RefCounted
## Patricia: GDD §9 T10–T16 (Figuur 15, Algoritme 1, BBBB-voorbeeld p. 29, enten, wesp, Oef. 19a).

const V := TtCodes.Verdict
const PH := TtCodes.Phase
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")
const F15 := "{C{G{C{C{C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]}}} G{A[GA_] G{C{C[GGCC_] G[GGCGG_]}}}}"
const F15P := "{0|C{2|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} G{0|A[GA_] G{1|C[GGCC_] G[GGCGG_]}}}"
const F17 := "{C{G{A{C{C[CGACCC_] T[CGACTAA_]}} T[CGTAAT_]}} G{G{A[GGA_] C{G{A[GGCGAA_] T[GGCGTA_]}} G{G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}}"
const F17P := "{0|C{1|A{1|C[CGACCC_] T[CGACTAA_]} T[CGTAAT_]} G{1|A[GGA_] C{1|A[GGCGAA_] T[GGCGTA_]} G{0|G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}"
const BB := "{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}"
const END23 := "{0|C{0|G{0|C{0|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} T[CGTA_]} _[C_]} G{0|A[GA_] G{1|C[GGCC_] G{0|G[GGCGG_] T[GGCGT_]}} T[GT_]}}"

var h := H.new()


func run(t) -> void:
	_t10(t)
	_t11(t)
	_t12(t)
	_t13(t)
	_t14(t)
	_t15(t)
	_t16(t)
	_errors(t)


func _pat(s := "{0|}", trie := false, alpha: TtAlphabet = null) -> TtPatricia:
	var m := TtPatricia.new().setup(alpha if alpha != null else TtAlphabet.dna())
	if trie:
		m.load_trie(s)
	else:
		m.load_notation(s)
	return m


func _prune_all(m: TtPatricia, order_rev := false) -> int:
	var c := h.card("patricify")
	m.begin(c)
	var n := 0
	while m.card != null:
		var mv := m.correct_move()
		if order_rev and mv.act == "prune":
			var un := m.unary_nodes()
			mv = {"act": "prune", "node": un[-1]}
		var r := m.apply(mv)
		if not r.ok or r.verdict != V.OK:
			return -1
		n += 1
	return n


func _t10(t) -> void:
	t.section("T10 Figuur 15 snoeien")
	var m := _pat(F15, true)
	t.eq(m.sap_used(), 48, "gewone vorm: 8 × 6 = 48")
	var names := []
	for id in m.unary_nodes():
		names.append(m.path_string(id))
	names.sort()
	t.eq(names, ["C", "CG", "GG"], "unaire toppen")
	for rev in [false, true]:
		var mm := _pat(F15, true)
		t.eq(_prune_all(mm, rev), 4, "3 knippen + klaar (omgekeerd=%s)" % str(rev))
		t.notation(mm.serialize(), F15P, "Figuur 15 onder")
		t.eq(mm.inner_count(), 5, "5 toppen")
		t.eq(mm.sap_used(), 30, "30 sap")
		t.ok(mm.invariants().is_empty(), "invariants " + str(mm.invariants()))
	t.notation(TtReference.patricia_of(F15, TtAlphabet.dna()), F15P, "referentie")
	var m2 := _pat(F15, true)
	m2.begin(h.card("patricify"))
	var r := m2.apply({"act": "prune", "node": m2.root})
	t.ok(not r.ok and r.reason == "branching", "vertakte top snoeien: klonk")
	r = m2.apply({"act": "prune_done"})
	t.eq(r.verdict, V.UNPRUNED, "te vroeg klaar: UNPRUNED")


func _t11(t) -> void:
	t.section("T11 Algoritme 1-sporen (Fig. 15P)")
	var m := _pat(F15P)
	var expect := {"GGCGG_": [[0, 1, 3], "leaf", true], "CGCGAA_": [[0, 3], "leaf", true], "GGC_": [[0, 1, 3], "null", false],
		"CA_": [[0], "short", false], "CGCCTT_": [[0, 3, 4], "leaf", true], "GACC_": [[0, 1], "leaf", false]}
	for w in expect.keys():
		var z := m.zoek(w)
		var reads := []
		for s in z.steps:
			reads.append(int(s.pos))
		t.eq(reads, expect[w][0], w + ": leesposities")
		t.eq(z.end, expect[w][1], w + ": einde")
		t.eq(z.found, expect[w][2], w + ": gevonden")
		var ref := TtReference.zoek_patricia(TtNotation.parse_patricia(F15P), w)
		t.eq(ref.reads, expect[w][0], w + ": referentie")
	# spelversie: bijen met het orakel
	t.eq(h.bee(m, "GGC_").result, "not_found", "GGC_ lege knop")
	t.eq(h.bee(m, "CA_").result, "not_found", "CA_ te kort")
	t.eq(h.bee(m, "GACC_").result, "rejected", "GACC_ Niet hier")
	t.eq(h.bee(m, "GGCGG_").result, "found", "GGCGG_")
	var c := h.card("bee", "CA_")
	m.begin(c)
	m.apply({"act": "read", "pos": 0})
	t.eq(m.cursor().read_pos, 3, "cursor: leespositie 1 + 2")
	t.eq(m.correct_move(), {"act": "short"}, "orakel: te kort")
	var r := m.apply({"act": "read", "pos": 3})
	t.ok(not r.ok and r.reason == "past_end", "voorbij het lint lezen: klonk")
	r = m.apply({"act": "short"})
	t.ok(r.ok and r.verdict == V.OK and r.done, "te kort")


func _t12(t) -> void:
	t.section("T12 BBBB (p. 29)")
	var a := TtAlphabet.abc()
	var m := _pat(BB, false, a)
	t.eq(m.sap_used(), 10, "2 toppen × 5")
	var z := m.zoek("BBBBBBBBBBBBB_")
	var reads := []
	for s in z.steps:
		reads.append(int(s.pos))
	t.eq(reads, [5, 11], "leest 5 en 11")
	t.eq(m.node(int(z.leaf)).label, "AAAAABAAAAABC_", "eindigt in AAAAABAAAAABC_")
	t.ok(not z.found, "niet gevonden")
	var tr := TtReference.trie_dict(["AAAAABAAAAABC_", "AAAAABAAAAAC_", "AAAAACA_"])
	t.eq(TtNotation.count_inner(tr), 12, "gewone vorm: 12 toppen")
	t.notation(TtReference.patricia_of(TtNotation.serialize_trie(tr, a), a), BB, "patricia_of == BB")


func _t13(t) -> void:
	t.section("T13 Patricia-invoegen (level 2-3)")
	var m := _pat(F15P)
	m.sap_budget = 54
	var bad := [0]
	var expect := {"GT_": [1, false], "CGTA_": [2, true], "GGCGT_": [4, true], "C_": [1, true]}
	for w in ["GT_", "CGTA_", "GGCGT_", "C_"]:
		var c := h.card("seed", w)
		m.begin(c)
		var j := -1
		var saw_short := false
		while m.card != null:
			var mv := m.correct_move()
			if mv.act == "split":
				j = int(mv.j)
			if mv.act == "short":
				saw_short = true
			var r := m.apply(mv)
			t.ok(r.ok and r.verdict == V.OK, "%s: orakelzet %s" % [w, str(mv)])
			t.ok(m.invariants().is_empty(), "invariants")
		t.eq(j, expect[w][0], w + ": j")
		t.eq(bool(h.last(m, "SPLIT").data.new), expect[w][1], w + ": nieuwe top")
		if w == "C_":
			t.ok(saw_short, "C_: te kort")
		if w == "CGTA_":
			var sk := []
			for x in m.subtree(m.root):
				if m.node(x).is_inner() and m.path_string(x).begins_with("C") and m.path_string(x).length() <= 3:
					sk.append([m.path_string(x), m.node(x).skip])
			t.eq(sk, [["CG", 1], ["CGC", 0]], "CGTA_: nieuwe top skip 1, oude top skip 0")
	t.notation(m.serialize(), END23, "eindboom 2-3")
	t.eq(m.inner_count(), 8, "8 toppen")
	t.eq(m.sap_used(), 48, "48 sap")
	for w in ["CGTA_", "C_", "GGCGT_", "GGCC_"]:
		t.eq(h.bee(m, w).result, "found", w)
	t.eq(h.bee(m, "CGTT_", true).result, "wasp_caught", "wesp CGTT_")
	t.eq(h.bee(m, "GTA_", true).result, "wasp_caught", "wesp GTA_")
	var ws := ["CGCCCT_", "CGCCTT_", "CGCGAA_", "GA_", "GGCC_", "GGCGG_", "GT_", "CGTA_", "GGCGT_", "C_"]
	t.notation(m.serialize(), TtReference.patricia_of(TtReference.trie_of(ws, m.alphabet), m.alphabet), "== snoei(trie)")


func _t14(t) -> void:
	t.section("T14 Patricia-invoegen = snoeien(gewone trie), 500 sets")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1414
	var a := TtAlphabet.dna()
	var fails := 0
	var checks := 0
	var lookups_bad := 0
	for it in 500:
		var n := rng.randi_range(3, 9)
		var set := {}
		while set.size() < n:
			var w := ""
			for k in rng.randi_range(1, 6):
				w += "ACGT"[rng.randi_range(0, 3)]
			set[w + "_"] = true
		var ws: Array = set.keys()
		var m := _pat(TtReference.patricia_of(TtReference.trie_of(ws.slice(0, 2), a), a), false, a)
		var bad := [0]
		for i in range(2, ws.size()):
			h.seed(m, ws[i], bad)
			checks += 1
			var want := TtReference.patricia_of(TtReference.trie_of(ws.slice(0, i + 1), a), a)
			if m.serialize() != want:
				fails += 1
				if fails <= 3:
					t.eq(m.serialize(), want, "set %s na %s" % [str(ws), ws[i]])
		fails += bad[0]
		var pd := TtNotation.parse_patricia(m.serialize())
		for w in ws:
			if not m.lookup_auto(w).found or not TtReference.zoek_patricia(pd, w).found:
				lookups_bad += 1
		# insert_auto geeft hetzelfde
		var m2 := _pat(TtReference.patricia_of(TtReference.trie_of(ws.slice(0, 2), a), a), false, a)
		for i in range(2, ws.size()):
			m2.insert_auto(ws[i])
		if m2.serialize() != m.serialize():
			fails += 1
	t.eq(fails, 0, "Patricia na elke invoeging == snoei(trie) (%d controles)" % checks)
	t.eq(lookups_bad, 0, "alle woorden terug te vinden")
	t.ok(checks > 1500, "genoeg controles: %d" % checks)


func _t15(t) -> void:
	t.section("T15 Figuur 17 snoeien (Oef. 19a)")
	var m := _pat(F17, true)
	t.eq(m.sap_used(), 60, "10 × 6")
	var names := []
	for id in m.unary_nodes():
		names.append(m.path_string(id))
	names.sort()
	t.eq(names, ["C", "CGA", "G", "GGC"], "unair: C, CGA, G, GGC")
	_prune_all(m)
	t.notation(m.serialize(), F17P, "Oef. 19a")
	t.eq(m.sap_used(), 36, "6 toppen = 36 sap")
	var expect := {"GGCGTA_": [0, 2, 4], "CGACTAA_": [0, 2, 4], "GGGTTT_": [0, 2, 3], "GTGGGG_": [0, 2, 3], "CCAT_": [0, 2, 4]}
	for w in expect.keys():
		var reads := []
		for s in m.zoek(w).steps:
			reads.append(int(s.pos))
		t.eq(reads, expect[w], w + " leesposities")
	t.eq(m.node(int(m.zoek("GTGGGG_").leaf)).label, "GGGGG_", "wesp GTGGGG_ komt bij GGGGG_")
	t.eq(m.zoek("CCAT_").end, "null", "CCAT_ lege knop")


func _t16(t) -> void:
	t.section("T16 wesp (level 2-2)")
	var m := _pat(BB, false, TtAlphabet.abc())
	h.bee(m, "AAAAABAAAAABC_")
	h.bee(m, "AAAAACA_")
	var c := h.card("bee", "BBBBBBBBBBBBB_", {"wasp": true})
	m.begin(c)
	while m.phase != PH.AT_LEAF:
		m.apply(m.correct_move())
	var r := m.apply({"act": "answer", "found": true})
	t.eq(r.verdict, V.WRONG_ANSWER, "wesp plukken: WRONG_ANSWER")
	t.eq(c.outcome.result, "stolen", "gestolen")
	t.ok(not m.words().has("AAAAABAAAAABC_"), "vrucht weg")
	var o := h.bee(m, "AAAAABAAAAABC_")
	t.eq(o.result, "not_found", "laatste bestelling: lege knop")
	var cause := m.log.cause_of_word("AAAAABAAAAABC_")
	t.eq(str(cause.get("type", "")), "ANSWER", "oorzaak = diefstal")
	t.eq(int(cause.get("card", -1)), c.id, "oorzaak = wespkaart")
	t.eq(m.log.coach_line(cause), "Een vrucht bereiken is niet vinden: `AAAAABAAAAABC_` ≠ `BBBBBBBBBBBBB_`.", "coachzin")


func _errors(t) -> void:
	t.section("Patricia foutpaden")
	var m := _pat(F15P)
	m.begin(h.card("bee", "GGCGG_"))
	var r := m.apply({"act": "read", "pos": 1})
	t.eq(r.verdict, V.WRONG_POS, "skip niet geteld")
	t.ok(m.log.coach_line(h.last(m, "READ")).begins_with("skip = 0"), "coachzin WRONG_POS")
	m.auto_finish_card()
	m.begin(h.card("bee", "GGCGG_"))
	r = m.apply({"act": "short"})
	t.eq(r.verdict, V.WRONG_SHORT, "te kort terwijl lang genoeg")
	t.ok(r.done, "bij keert terug")
	# enten met verkeerde j → onvindbaar
	var m2 := _pat(F15P)
	m2.begin(h.card("seed", "CGTA_"))
	while m2.phase != PH.COMPARE:
		m2.apply(m2.correct_move())
	t.eq(m2.correct_move(), {"act": "split", "j": 2}, "orakel j = 2")
	r = m2.apply({"act": "split", "j": 3})
	t.ok(r.ok and r.verdict == V.J_LATE, "j te laat: J_LATE (%s)" % str(r))
	var want := TtReference.patricia_of(TtReference.trie_of(["CGCCCT_", "CGCCTT_", "CGCGAA_", "GA_", "GGCC_", "GGCGG_", "CGTA_"], m2.alphabet), m2.alphabet)
	t.ok(m2.serialize() != want, "verkeerde ent: de boom is geen correcte Patricia meer")
	t.eq(m2.log.coach_line(h.last(m2, "SPLIT")), "`CGCCCT_` en `CGTA_` verschillen al op positie 2, niet pas op 3.", "coachzin")
	# vrucht van buiten de top kiezen
	var m3 := _pat(F15P)
	m3.begin(h.card("seed", "GGT_"))
	while m3.phase != PH.PICK_LEAF:
		m3.apply(m3.correct_move())
	var outside := -1
	for id in m3.nodes.keys():
		if m3.node(id).is_leaf() and m3.node(id).label == "CGCCCT_":
			outside = id
	r = m3.apply({"act": "pick_leaf", "leaf": outside})
	t.ok(not r.ok and r.reason == "not_in_subtree", "vrucht buiten de top: klonk")
	m3.auto_finish_card()
	t.ok(m3.lookup_auto("GGT_").found, "GGT_ geënt")
