extends RefCounted
## Ukkonen: GDD §9 T27–T31 (abacabc_ p. 43–48, Oef. 27, acacacgt_, Ukkonen == naïef, weigeringen).

const V := TtCodes.Verdict
const PH := TtCodes.Phase
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")

var h := H.new()


func run(t) -> void:
	_t27(t)
	_t28(t)
	_t29(t)
	_t30(t)
	_t31(t)
	_property(t)


func _name(m: TtUkkonen, id: int) -> String:
	if id == m.root:
		return "w"
	return "[" + m.node_string(id) + "]"


func _tr(m: TtUkkonen) -> Array:
	var out := []
	for r in m.trace():
		out.append("(%d,%d,%s,%d,%s,%d)" % [r.it, r.j, r.rule, r.hops, _name(m, int(r.p_before)), r.x_before])
	return out


func _links(m: TtUkkonen) -> Array:
	var out := []
	for r in m.trace():
		if int(r.link_from) >= 0:
			out.append("%s→%s@%d" % [_name(m, int(r.link_from)), _name(m, int(r.link_to)), r.it])
	return out


## Speelt met het orakel; geeft x aan het einde van elke iteratie (dikke pijl) en de tussenboom na it 4.
func _play(m: TtUkkonen, t, snapcheck := false) -> Dictionary:
	var c := h.card("ukkonen")
	m.begin(c)
	var arrows := {}
	var mid := ""
	var bad := 0
	var last_it := m.it
	while m.card != null:
		if snapcheck:
			var s1 := m.snapshot()
			m.restore(s1)
			if m.snapshot() != s1:
				bad += 1
		var mv := m.correct_move()
		var r := m.apply(mv)
		if not r.ok or r.verdict != V.OK:
			bad += 1
			break
		if not m.invariants().is_empty():
			bad += 1
			t.ok(false, "invariants: " + str(m.invariants()))
		if m.it != last_it or m.finished:
			arrows[last_it] = m.x if not m.finished else 0
			if last_it == 4:
				mid = m.serialize()
			last_it = m.it
	return {"bad": bad, "arrows": arrows, "mid": mid}


func _t27(t) -> void:
	t.section("T27 abacabc_ (p. 43–48)")
	var m := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), "abacabc_", 1)
	var res := _play(m, t, true)
	t.eq(res.bad, 0, "orakel OK, snapshot-identiek, invariants")
	t.eq(_tr(m), ["(1,1,ii,0,w,0)", "(2,2,ii,0,w,0)", "(3,3,a,0,w,0)", "(4,3,iii,0,w,1)", "(4,4,ii,0,w,0)",
		"(5,5,a,0,w,0)", "(6,5,a,1,[a],0)", "(7,5,iii,0,[a],1)", "(7,6,iii,0,w,1)", "(7,7,a,0,w,0)",
		"(8,7,iii,0,w,1)", "(8,8,ii,0,w,0)"], "extensies")
	var arr := []
	for k in range(1, 9):
		arr.append(int(res.arrows.get(k, -9)))
	t.eq(arr, [0, 0, 1, 0, 1, 1, 1, 0], "dikke pijl per iteratie")
	t.eq(_links(m), ["[a]→w@4", "[ab]→[b]@7", "[b]→w@7", "[c]→w@8"], "suffix links")
	t.notation(m.serialize(), "{(1,1){(2,2){(3,8)#1 (7,8)#5} (4,8)#3} (2,2){(3,8)#2 (7,8)#6} (4,4){(5,8)#4 (8,8)#7} (8,8)#8}", "eindboom")
	t.notation(res.mid, "{(1,1){(2,it)#1 (4,it)#3} (2,it)#2 (4,it)#4}", "tussenboom na it 4")
	t.ok(m.finished, "klaar")


func _t28(t) -> void:
	t.section("T28 Oef. 27 aabbabc_")
	var m := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), "aabbabc_", 1)
	var res := _play(m, t)
	t.eq(res.bad, 0, "orakel")
	t.eq(_tr(m), ["(1,1,ii,0,w,0)", "(2,2,a,0,w,0)", "(3,2,iii,0,w,1)", "(3,3,ii,0,w,0)", "(4,4,a,0,w,0)",
		"(5,4,iii,0,w,1)", "(5,5,a,0,w,0)", "(6,5,a,1,[a],0)", "(7,5,iii,0,[a],1)", "(7,6,ii,1,[b],0)",
		"(7,7,ii,0,w,0)", "(8,8,ii,0,w,0)"], "extensies")
	t.notation(m.serialize(), "{(1,1){(2,8)#1 (3,3){(4,8)#2 (7,8)#5}} (3,3){(5,8)#4 (4,8)#3 (7,8)#6} (7,8)#7 (8,8)#8}", "eindboom")
	var ls := []
	for s in _links(m):
		ls.append(s.get_slice("@", 0))
	ls.sort()
	t.eq(ls, ["[a]→w", "[ab]→[b]", "[b]→w"], "suffix links")


func _t29(t) -> void:
	t.section("T29 acacacgt_")
	var m := TtUkkonen.new().setup_text(TtAlphabet.dna_lower(), "acacacgt_", 0)
	var res := _play(m, t)
	t.eq(res.bad, 0, "orakel")
	var tr := _tr(m)
	t.eq(tr.slice(0, 6), ["(1,1,ii,0,w,0)", "(2,2,ii,0,w,0)", "(3,3,a,0,w,0)", "(4,3,b,0,w,1)", "(5,3,b,0,w,2)", "(6,3,b,0,w,3)"], "it 1–6")
	t.eq(tr.slice(6, 11), ["(7,3,iii,0,w,4)", "(7,4,iii,0,w,3)", "(7,5,iii,0,w,2)", "(7,6,iii,0,w,1)", "(7,7,ii,0,w,0)"], "it 7: cascade")
	t.eq(tr.slice(11), ["(8,8,ii,0,w,0)", "(9,9,ii,0,w,0)"], "it 8, 9")
	t.eq(_links(m), ["[acac]→[cac]@7", "[cac]→[ac]@7", "[ac]→[c]@7", "[c]→w@7"], "links-keten")
	t.notation(m.serialize(), "{(0,1){(2,3){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(2,3){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}", "== T22")


func _t30(t) -> void:
	t.section("T30 Ukkonen == naïef ({a,c}, lengte 1..7)")
	var a := TtAlphabet.make("ac", PackedStringArray(["a", "c", "_"]))
	var cnt := 0
	var bad := 0
	var firsts_bad := 0
	for L in range(1, 8):
		for mask in range(1 << L):
			var s := ""
			for i in L:
				s += "c" if (mask >> i) & 1 else "a"
			s += "_"
			cnt += 1
			var u := TtUkkonen.new().setup_text(a, s, 0)
			u.run_all()
			var nv := TtReference.suffix_naive(s, a)
			if u.serialize() != nv:
				bad += 1
				if bad <= 3:
					t.eq(u.serialize(), nv, "tekst " + s)
			var st := TtSuffixTree.new().setup(a, s, 0)
			st.build_naive()
			if st.serialize() != nv:
				bad += 1
			# Oef. 28a (beslissing lead 10): b − l_t is het eerste voorkomen
			for i in range(s.length()):
				for k in range(1, s.length() - i + 1):
					var z := s.substr(i, k)
					var loc := u.locate_auto(z)
					if not loc.found or int(loc.pos) != s.find(z):
						firsts_bad += 1
	t.eq(cnt, 254, "254 teksten")
	t.eq(bad, 0, "Ukkonen == naïef == referentie")
	t.eq(firsts_bad, 0, "b − l_t == eerste voorkomen (alle deelstrings)")


static func _state(m: TtTreeModel) -> Dictionary:
	var s := m.snapshot()
	s.erase("verdicts")
	return s


func _t31(t) -> void:
	t.section("T31 Ukkonen-weigeringen (5-1)")
	var m := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), "abacabc_", 1)
	m.begin(h.card("ukkonen"))
	while not (m.it == 6 and m.phase == PH.U_CANON):
		m.apply(m.correct_move())
	var s := _state(m)
	var r := m.apply({"act": "rule", "grow": false})
	t.ok(not r.ok and r.reason == "not_canonical" and r.verdict == V.WRONG_HOP, "rule vóór de sprong: WRONG_HOP")
	t.ok(_state(m) == s, "staat ongewijzigd")
	t.eq(int(m.log.entries[-1].verdict), V.WRONG_HOP, "gelogd")
	t.eq(m.log.mistakes(true).size(), 1, "telt als misstap (count_bumps)")
	r = m.apply({"act": "hop", "node": m.root})
	t.ok(not r.ok and r.reason == "wrong_edge", "verkeerde boog")
	while not (m.it == 7 and m.phase == PH.U_FOLLOW):
		m.apply(m.correct_move())
	s = _state(m)
	r = m.apply({"act": "follow", "mode": "minus"})
	t.ok(not r.ok and r.verdict == V.WRONG_FOLLOW, "follow minus bij [a]: WRONG_FOLLOW")
	t.ok(_state(m) == s, "staat ongewijzigd")
	while m.phase != PH.U_LINK:
		m.apply(m.correct_move())
	s = _state(m)
	r = m.apply({"act": "link", "node": m.root})
	t.ok(not r.ok and r.verdict == V.WRONG_LINK, "link naar de wortel: WRONG_LINK")
	t.ok(_state(m) == s, "staat ongewijzigd")
	t.eq(m.log.coach_line(m.log.entries[-1]), "`ab` linkt naar `b`: zonder de eerste letter.", "coachzin")
	r = m.apply({"act": "rule", "grow": true})
	t.ok(not r.ok and r.reason == "wrong_phase", "regel tijdens link: klonk")
	m.auto_finish_card()
	t.ok(m.finished, "toch nog af te werken")
	t.eq(m.log.mistakes(true).size(), 5, "5 misstappen")
	# regel-fouten
	var m2 := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), "abacabc_", 1)
	m2.begin(h.card("ukkonen"))
	while m2.it != 3:
		m2.apply(m2.correct_move())
	r = m2.apply({"act": "rule", "grow": true})
	t.ok(not r.ok and r.verdict == V.WRONG_RULE, "groei terwijl a er al zit")
	t.eq(m2.log.coach_line(m2.log.entries[-1]), "`a` zit er al in: stop de iteratie, x + 1.", "coachzin groei")
	m2.apply(m2.correct_move())
	r = m2.apply({"act": "rule", "grow": false})
	t.ok(not r.ok and r.verdict == V.WRONG_RULE, "stop terwijl c ontbreekt")


func _property(t) -> void:
	t.section("Ukkonen == naïef (willekeurige DNA-teksten)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2727
	var a := TtAlphabet.dna_lower()
	var bad := 0
	var first_bad := 0
	for it in 300:
		var s := ""
		for k in rng.randi_range(1, 14):
			s += "acgt"[rng.randi_range(0, 3)]
		s += "_"
		var u := TtUkkonen.new().setup_text(a, s, 0)
		u.run_all()
		if u.serialize() != TtReference.suffix_naive(s, a) or not u.invariants().is_empty():
			bad += 1
		for k in 5:
			var i := rng.randi_range(0, s.length() - 1)
			var z := s.substr(i, rng.randi_range(1, s.length() - i))
			var loc := u.locate_auto(z)
			if int(loc.pos) != s.find(z) or (loc.starts as Array) != Array(TtReference.occurrences(s, z)):
				first_bad += 1
	t.eq(bad, 0, "300 teksten: Ukkonen == naïef")
	t.eq(first_bad, 0, "b − l_t == eerste voorkomen; bladeren == alle voorkomens")
