extends RefCounted
## Alfabet, notatie, kaart, log.

func run(t) -> void:
	t.section("TtAlphabet")
	var a := TtAlphabet.dna()
	t.eq(a.letters, PackedStringArray(["A", "C", "G", "T", "_"]), "dna")
	t.eq(a.size(), 5, "|A|")
	t.eq(a.cost_size, 5, "cost")
	t.eq(a.compare("T", "_"), -1, "_ achteraan")
	t.eq(a.index_of("X"), -1, "onbekend")
	var az := TtAlphabet.az()
	t.eq(az.size(), 27, "a-z_")
	t.eq(az.compare("e", "_"), -1, "e < _")
	var mu := TtAlphabet.dna_lower_multi(3)
	t.eq(mu.letters, PackedStringArray(["a", "c", "g", "t", "1", "2", "3"]), "multi")
	t.eq(mu.display("2"), "_₂", "display _₂")
	t.eq(TtAlphabet.by_name("dna@256").cost_size, 256, "ASCII-kost")
	t.eq(TtAlphabet.by_name("abc").letters.size(), 4, "abc")
	t.eq(a.with_cost(256).cost_size, 256, "with_cost")
	t.section("TtNotation")
	var s := "{A{A[AAGTT_] C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
	t.eq(TtNotation.serialize_trie(TtNotation.parse_trie(s), a), s, "trie roundtrip")
	t.eq(TtNotation.count_inner(TtNotation.parse_trie(s)), 6, "count_inner")
	var p := "{0|C{2|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} G{0|A[GA_] G{1|C[GGCC_] G[GGCGG_]}}}"
	t.eq(TtNotation.serialize_trie(TtNotation.parse_patricia(p), a), p, "patricia roundtrip")
	var tn := "(G (C . (G (A . [CA_] .) [CGGA_] .) .) (G . [GGGG_] .) (T . (A . [TAC_] (C . [TCCA_] .)) .))"
	t.eq(TtNotation.serialize_ternary(TtNotation.parse_ternary(tn)), tn, "ternary roundtrip")
	t.eq(TtNotation.count_balls(TtNotation.parse_ternary(tn)), 8, "8 bollen")
	var sf := "{(1,1){(2,it)#1 (4,it)#3} (2,it)#2 (4,it)#4}"
	var ps := TtNotation.parse_suffix(sf, 1)
	t.eq(int(ps.edges[0].b), 0, "suffix 0-gebaseerd")
	t.eq(int(ps.edges[0].child.edges[0].e), TtCodes.OPEN, "it = OPEN")
	t.eq(TtNotation.serialize_suffix(ps, 1, "abacabc_", TtAlphabet.by_name("abc_lower")), sf, "suffix roundtrip")
	t.ok(TtNotation.parse_trie("{A[").has("error"), "syntaxfout")
	t.eq(TtNotation.leaves(TtNotation.parse_trie(s)).size(), 5, "leaves")
	t.section("TtCard / TtEventLog")
	var c := TtCard.from_spec(3, {"kind": "bee", "word": "BBB_", "wasp": true})
	t.ok(c.kind == TtCodes.CardKind.BEE and c.wasp, "card from_spec")
	t.eq(TtCard.from_dict(c.to_dict()).to_dict(), c.to_dict(), "card roundtrip")
	t.eq(c.describe(), "wesp BBB_", "describe")
	var lg := TtEventLog.new()
	lg.add("SPLIT", {"l": "AB_", "s": "AC_", "j": 1, "x": 2, "affects": ["AB_"]}, TtCodes.Verdict.J_LATE, {}, {})
	lg.add("MOVE", {}, TtCodes.Verdict.OK, {}, {})
	lg.add("BUMP", {"reason": "x"}, TtCodes.Verdict.BUMP, {}, {}, -1, false)
	t.eq(lg.mistakes().size(), 1, "mistakes zonder bumps")
	t.eq(lg.mistakes(true).size(), 2, "mistakes met bumps")
	t.eq(int(lg.cause_of_word("AB_").seq), 0, "cause_of_word")
	t.ok(lg.notes_ref(lg.entries[0]).contains("p. 27"), "notes_ref")
	# elke foutcode heeft een coachzin en verwijzing
	for v in range(2, TtCodes.Verdict.size() - 2):
		var e := {"verdict": v, "data": {}}
		t.ok(lg.coach_line(e) != "", "coachzin voor " + TtCodes.verdict_name(v))
		t.ok(lg.notes_ref(e) != "", "verwijzing voor " + TtCodes.verdict_name(v))
