extends RefCounted
## Suffixbomen: GDD §9 T22–T26 (Figuur 18/19, §3.3-vragen, mist, veralgemeend).

const V := TtCodes.Verdict
const PH := TtCodes.Phase
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")
const T := "acacacgt_"
const F19U := "{(0,1){(2,3){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(2,3){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}"
const F19 := "{(0,1){(0,1){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(0,1){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}"
const MIST := "gcatcgcatgcatcga_"
const MIST_N := "{(2,2){(3,3){(4,5){(15,16)#11 (6,16)#2} (9,16)#7} (16,16)#15} (1,1){(2,3){(4,5){(15,16)#10 (6,16)#1} (9,16)#6} (5,5){(15,16)#13 (6,16)#4}} (0,0){(15,16)#14 (1,3){(4,5){(15,16)#9 (6,16)#0} (9,16)#5}} (3,3){(4,5){(15,16)#12 (6,16)#3} (9,16)#8} (16,16)#16}"
const GEN := "gatcga1tcgatt2atcgg3"

var h := H.new()


func run(t) -> void:
	_t22(t)
	_t23(t)
	_t24(t)
	_t25(t)
	_t26(t)
	_errors(t)


func _sx(labels := "pointers") -> TtSuffixTree:
	return TtSuffixTree.new().setup(TtAlphabet.dna_lower(), T, 0, labels)


func _t22(t) -> void:
	t.section("T22 Figuur 18/19 naïef")
	var expect_pts := {0: ["", 0], 1: ["", 0], 2: ["acac", 0], 3: ["cac", 0], 4: ["ac", 0], 5: ["c", 0], 6: ["", 0], 7: ["", 0], 8: ["", 0]}
	var m := _sx("strings")
	m.sap_budget = 90
	var bad := [0]
	var pts := []
	for jj in range(9):
		var c := h.card("suffix", "", {"j": jj})
		m.begin(c)
		var mv := m.correct_move()
		pts.append(m.point_string({"node": int(mv.node), "off": int(mv.off)}))
		var r := m.apply(mv)
		if not r.ok or r.verdict != V.OK or not m.invariants().is_empty():
			bad[0] += 1
	t.eq(bad[0], 0, "orakel + invariants")
	t.eq(pts, ["", "", "acac", "cac", "ac", "c", "", "", ""], "afwijkpunten (strings)")
	t.notation(m.serialize(), F19U, "eindboom (0-gebaseerd)")
	t.eq(m.inner_count(), 5, "5 interne toppen")
	t.eq(m.leaf_count(), 9, "9 bladeren")
	t.ok(m.inner_count() + m.leaf_count() <= 2 * 9 - 1, "≤ 2n − 1")
	t.eq(m.sap_used(), 80, "sap 4-1 = 80")
	t.notation(TtReference.suffix_naive(T, TtAlphabet.dna_lower()), F19U, "referentie")
	# 4-2: pointers + b kiezen
	var m2 := _sx("pointers")
	m2.sap_budget = 50
	var bs := []
	var splits := []
	for jj in range(9):
		m2.begin(h.card("suffix", "", {"j": jj}))
		var mv := m2.correct_move()
		splits.append(int(mv.off) > 0)
		m2.apply(mv)
		t.eq(m2.phase, PH.LABEL, "LABEL-fase na aanhechten")
		var lb := m2.correct_move()
		bs.append(int(lb.b))
		var r := m2.apply(lb)
		t.ok(r.ok and r.verdict == V.OK and r.done, "label OK")
	t.eq(bs, [0, 1, 6, 6, 6, 6, 6, 7, 8], "juiste b per suffix")
	t.eq(splits, [false, false, true, true, true, true, false, false, false], "splits bij 2–5")
	t.notation(m2.serialize(), F19U, "eindboom 4-2")
	t.eq(m2.sap_used(), 44, "sap 4-2 = 44")
	t.eq(m2.text, T, "tekst")
	for jj in range(9):
		t.ok(m2.lookup_auto(T.substr(jj)).exact_leaf, "suffix %d eindigt in een blad" % jj)


func _t23(t) -> void:
	t.section("T23 Figuur 19 zoals getekend")
	var m := _sx()
	m.load_notation(F19)
	t.ok(m.invariants().is_empty(), "invariants " + str(m.invariants()))
	t.notation(m.serialize(), F19, "laadt exact")
	var ok_paths := true
	for id in m.nodes.keys():
		if m.node(id).is_leaf() and not m.path_ok(id):
			ok_paths = false
	t.ok(ok_paths, "elke boog spelt de juiste string")
	t.eq(int(m.locate_auto("cac").pos), -1, "cac: b − l_t = 0 − 1 = −1")
	var m2 := _sx()
	m2.load_notation(F19U)
	t.eq(int(m2.locate_auto("cac").pos), 1, "Ukkonen-labels: 1")


func _t24(t) -> void:
	t.section("T24 §3.3-vragen (T22-boom)")
	var m := _sx()
	m.load_notation(F19U)
	var l := m.locate_auto("cac")
	t.eq([int(l.b), int(l.l_t), int(l.pos)], [2, 1, 1], "cac: b 2, l_t 1, pos 1")
	t.eq(l.starts, [1, 3], "cac: bladeren {1,3}")
	l = m.locate_auto("ac")
	t.eq(int(l.pos), 0, "ac: pos 0")
	t.eq(l.starts, [0, 2, 4], "ac: {0,2,4}")
	l = m.locate_auto("acg")
	t.eq([int(l.b), int(l.e), int(l.l_t), int(l.pos)], [6, 8, 2, 4], "acg: (6,8), l_t 2, pos 4")
	l = m.locate_auto("caca")
	t.eq([int(l.b), int(l.e), int(l.l_t), int(l.pos)], [4, 8, 3, 1], "caca: (4,8), l_t 3, pos 1")
	t.ok(not m.locate_auto("cat").found, "cat niet")
	t.ok(not m.locate_auto("ccc").found, "ccc niet")
	t.eq(m.locate_auto("a").starts, [0, 2, 4], "a: {0,2,4}")
	t.eq(m.locate_auto("c").starts, [1, 3, 5], "c: {1,3,5}")
	# level 4-3 als kaarten met het orakel
	var qs := [["exists", "cac"], ["where", "cac"], ["count", "ac"], ["exists", "cat"], ["where", "acg"], ["all", "a"],
		["count", "c"], ["where", "caca"]]
	var bad := [0]
	for q in qs:
		var o := h.play(m, h.card("ask", q[1], {"q": q[0]}), bad)
		t.eq(o.result, "answered", "%s %s" % q)
	t.eq(bad[0], 0, "orakel")
	# fout antwoord + coach
	m.begin(h.card("ask", "cac", {"q": "where"}))
	m.apply(m.correct_move())
	var r := m.apply({"act": "where", "pos": 3})
	t.ok(r.ok and r.verdict == V.OK, "where 3 (ander voorkomen) is ook goed")
	t.eq(bool(h.last(m, "WHERE").data.formula), false, "maar niet via b − l_t")
	m.begin(h.card("ask", "cac", {"q": "where"}))
	m.apply(m.correct_move())
	r = m.apply({"act": "where", "pos": 2})
	t.eq(r.verdict, V.WRONG_WHERE, "where 2 fout")
	t.eq(m.log.coach_line(h.last(m, "WHERE")), "Boog (2,3) vanuit diepte 1: positie = 2 − 1 = 1.", "coachzin WRONG_WHERE")
	m.begin(h.card("ask", "cat", {"q": "exists"}))
	r = m.apply({"act": "locate", "node": m.root, "off": 0})
	t.eq(r.verdict, V.WRONG_ABSENT, "cat: loep zetten terwijl afwezig")
	t.eq(m.log.coach_line(h.last(m, "LOCATE")), "Na `ca` volgt `c`, niet `t`.", "coachzin WRONG_ABSENT")
	m.begin(h.card("ask", "ac", {"q": "count"}))
	r = m.apply({"act": "absent"})
	t.eq(r.verdict, V.WRONG_ABSENT, "ac: komt niet voor (fout)")
	t.ok(r.done, "kaart af")


func _t25(t) -> void:
	t.section("T25 mist-tekst gcatcgcatgcatcga_")
	var a := TtAlphabet.dna_lower()
	var m := TtSuffixTree.new().setup(a, MIST, 0)
	m.build_naive()
	t.notation(m.serialize(), MIST_N, "naïef")
	t.notation(TtReference.suffix_naive(MIST, a), MIST_N, "referentie")
	var u := TtUkkonen.new().setup_text(a, MIST, 0)
	u.run_all()
	t.notation(u.serialize(), MIST_N, "Ukkonen")
	t.eq(m.inner_count(), 13, "13 interne toppen")
	t.eq(int(m.locate_auto("cat").pos), 1, "cat pos 1")
	t.eq(m.locate_auto("cat").starts, [1, 6, 10], "cat {1,6,10}")
	t.eq((m.locate_auto("gcat").starts as Array).size(), 3, "gcat 3")
	t.eq(int(m.locate_auto("atg").pos), 7, "atg pos 7")
	t.eq(m.locate_auto("tcg").starts, [3, 12], "tcg {3,12}")
	t.eq(int(m.locate_auto("cga").pos), 13, "cga pos 13")
	t.eq(m.locate_auto("catc").starts, [1, 10], "catc {1,10}")
	t.ok(not m.locate_auto("ttt").found, "ttt niet")


func _t26(t) -> void:
	t.section("T26 veralgemeend gatcga1tcgatt2atcgg3")
	var a := TtAlphabet.dna_lower_multi(3)
	var own := PackedInt32Array()
	for i in GEN.length():
		own.append(1 if i <= 6 else (2 if i <= 13 else 3))
	var m := TtSuffixTree.new().setup(a, GEN, 0, "pointers", own)
	m.owner_names = PackedStringArray(["Mol", "Merel", "Muis"])
	m.build_naive()
	t.eq(m.inner_count(), 12, "12 interne toppen")
	var u := TtUkkonen.new().setup_text(a, GEN, 0, own)
	u.run_all()
	t.notation(u.serialize(), m.serialize(), "Ukkonen == naïef")
	t.notation(m.serialize(), TtReference.suffix_naive(GEN, a), "referentie")
	var expect := {"gatt": [2], "tcgg": [3], "cga": [1, 2], "atc": [1, 3], "cgat": [2]}
	for z in expect.keys():
		t.eq(m.locate_auto(z).owners, expect[z], "eigenaars " + z)
	t.ok(not m.locate_auto("ggg").found, "ggg niemand")
	var o := h.play(m, h.card("ask", "cga", {"q": "owner"}))
	t.eq(o.result, "answered", "kaart cga: van wie")
	m.begin(h.card("ask", "cga", {"q": "owner"}))
	m.apply(m.correct_move())
	var r := m.apply({"act": "owner", "texts": [1]})
	t.eq(r.verdict, V.WRONG_OWNER, "enkel Mol: fout")
	t.eq(m.log.coach_line(h.last(m, "OWNER")), "De kleuren onder het punt: Mol en Merel.", "coachzin")


func _errors(t) -> void:
	t.section("suffix foutpaden")
	var m := _sx("pointers")
	for jj in range(2):
		h.play(m, h.card("suffix", "", {"j": jj}))
	m.begin(h.card("suffix", "", {"j": 2}))
	var r := m.apply({"act": "attach", "node": m.root, "off": 0})
	t.ok(not r.ok and r.reason == "duplicate_first", "aan de wortel: twee bogen met a: klonk")
	var leaf0 := -1
	var leaf1 := -1
	for id in m.nodes.keys():
		if m.node(id).is_leaf() and m.node(id).start == 0:
			leaf0 = id
		if m.node(id).is_leaf() and m.node(id).start == 1:
			leaf1 = id
	r = m.apply({"act": "attach", "node": leaf0, "off": 2})
	t.ok(not r.ok and r.reason == "duplicate_first", "te ondiep op hetzelfde pad: volgende teken gelijk → klonk")
	r = m.apply({"act": "attach", "node": leaf1, "off": 1})
	t.eq(r.verdict, V.WRONG_POINT, "ander pad (c i.p.v. acac)")
	t.eq(m.log.coach_line(h.last(m, "ATTACH")), "`acacgt_` volgt de boom tot `acac` en wijkt daar pas af.", "coachzin")
	t.eq(m.correct_move(), {"act": "label", "b": 3}, "label-orakel: b = j + l = 2 + 1")
	r = m.apply({"act": "label", "b": 4})
	t.ok(not r.ok and r.reason == "duplicate_first", "b = 4 geeft een tweede boog met a: klonk")
	r = m.apply({"act": "label", "b": 6})
	t.ok(r.ok and r.verdict == V.WRONG_B, "label kiezen (fout)")
	var lf := int(h.last(m, "ATTACH").data.leaf)
	t.ok(not m.path_ok(lf), "pad en vrucht kloppen niet (amber)")
	t.ok(not m.lookup_auto("acacgt_").exact_leaf, "Bloei: suffix 2 niet gevonden")
	# verkeerde b
	var m2 := _sx("pointers")
	for jj in range(2):
		h.play(m2, h.card("suffix", "", {"j": jj}))
	m2.begin(h.card("suffix", "", {"j": 2}))
	m2.apply(m2.correct_move())
	r = m2.apply({"act": "label", "b": 9})
	t.ok(not r.ok and r.reason == "past_end", "b > n: klonk")
	r = m2.apply({"act": "label", "b": 5})
	t.eq(r.verdict, V.WRONG_B, "b = 5 i.p.v. 6")
	t.eq(m2.log.coach_line(h.last(m2, "LABEL")), "Nieuwe boog vanuit diepte 4: b = 2 + 4 = 6.", "coachzin WRONG_B")
