extends RefCounted
## T23–T32: werktuigen, spelregels, klemmen en gevolgen (GDD §9).

const H := preload("res://games/scriptorium/tests/suites/sc_helpers.gd")
const V := ScCodes.Verdict


func run(t) -> void:
	_t23(t)
	_t24(t)
	_t25(t)
	_t26(t)
	_t27(t)
	_t28(t)
	_t29(t)
	_t30(t)
	_t31(t)
	_t32(t)


## Speelt met het orakel tot cond(tool) waar is (of klaar).
static func _until(tl: ScTool, cond: Callable, max_moves := 1000) -> void:
	var g := 0
	while not tl.is_done() and not cond.call(tl) and g < max_moves:
		g += 1
		tl.apply(tl.correct_move())


func _t23(t) -> void:
	t.section("T23 codeboom")
	var pr := H.mk_stage("0-1", 0) as ScPrefixReader
	var u := pr.tree.leaf_of("u")
	var s0 := JSON.stringify(ScTool.norm(pr.snapshot()))
	var r := pr.apply({"act": "read", "leaf": u})
	t.eq([r.ok, r.reason], [false, "no_path"], "blad u bij pos 0")
	var s1 := pr.snapshot()
	s1.log_len = int(JSON.parse_string(s0).log_len)
	s1.counters.bumps = 0
	t.eq(JSON.stringify(ScTool.norm(s1)), s0, "snapshot ongewijzigd (buiten de log)")
	var r2 := pr.apply({"act": "read", "leaf": pr.tree.root})
	t.eq([r2.ok, r2.reason], [false, "not_leaf"], "interne top")
	t.eq(pr.counters.bumps, 2, "twee klemmen")
	var bad := [0]
	H.play(pr, bad)
	t.eq(bad[0], 0, "orakel 0-1 A " + str(bad))
	t.eq(pr.copy(), "oud", "kopie oud")
	var pb := H.mk_stage("0-1", 1)
	H.play(pb, bad)
	t.eq(pb.copy(), "fout", "kopie fout")
	t.eq(pb.log.mistakes().size(), 0, "geen misstappen")


func _t24(t) -> void:
	t.section("T24 codebord")
	var cb := H.mk_stage("0-2", 0) as ScCodeBoard
	var r := cb.apply({"act": "cut", "at": 3})
	t.eq([r.ok, r.reason], [false, "no_word"], "100 is geen codewoord")
	for i in [2, 3, 4, 5, 6]:
		cb.apply({"act": "cut", "at": i})
	t.eq(cb.readings, ["benen"], "eerste lezing benen")
	var r2 := cb.apply({"act": "done"})
	t.eq([r2.ok, r2.reason], [false, "need_more"], "done met één lezing")
	var bad := [0]
	H.play(cb, bad)
	t.eq(bad[0], 0, "orakel cuts " + str(bad))
	t.eq(cb.readings.size(), 4, "alle 4 lezingen")
	var b := H.mk_stage("0-2", 1) as ScCodeBoard
	var rec := H.record(b)
	for kv in [["e", "0"], ["n", "01"], [" ", "10"], ["b", "11"]]:
		b.apply({"act": "place", "sym": kv[0], "path": kv[1]})
	var rs := b.apply({"act": "send"})
	t.eq([rs.ok, rs.verdict], [true, V.NOT_PREFIX], "geen prefixcode")
	t.ok(not b.is_done(), "stage blijft open")
	var tr: Dictionary = {}
	for f in rec:
		if str(f.fx) == "trial_read":
			tr = f
	t.eq(str(tr.get("text", "")), "eeebebeeebeeebeeeebebee e…", "Letterlijk leest gulzig")
	var rp := b.apply({"act": "place", "sym": "e", "path": "0000"})
	t.eq([rp.ok, rp.reason], [false, "range"], "diepte > 3")
	var b2 := H.mk_stage("0-2", 1) as ScCodeBoard
	for kv in [["e", "00"], ["n", "01"], [" ", "10"], ["b", "11"]]:
		b2.apply({"act": "place", "sym": kv[0], "path": kv[1]})
	var rt := b2.apply({"act": "place", "sym": "e", "path": "01"})
	t.eq([rt.ok, rt.reason], [false, "taken"], "bezet")
	var rl := b2.apply({"act": "send"})
	t.eq([rl.ok, rl.verdict, rl.done], [true, V.LONG_CODE, true], "vaste code: LONG_CODE")
	t.eq(b2.counters.ink, 42, "42 bits")
	t.eq(H.read_of(b2), "een been en een benen", "voorlezing juist")
	var b3 := H.mk_stage("0-2", 1) as ScCodeBoard
	t.eq(b3.apply({"act": "send"}).reason, "incomplete", "onvolledig")
	H.play(b3, bad)
	t.eq(bad[0], 0, "orakel design")
	t.eq(b3.counters.ink, 39, "optimum 39")


func _t25(t) -> void:
	t.section("T25 binderij")
	var b := H.mk_stage("1-1", 0) as ScBindery
	var r := b.apply({"act": "bind", "a": 0, "b": 1})
	t.eq([r.ok, r.verdict], [true, V.WRONG_PAIR], "b+o")
	var bad := [0]
	H.play(b, bad)
	t.eq(bad[0], 0, "bot verder " + str(bad))
	t.eq(b.counters.twine, 23, "touw 23")
	t.eq(b.counters.ink, 23, "inkt 23")
	t.eq(H.read_of(b), "boosdoeer", "voorlezing juist")
	t.eq(b.log.mistakes().size(), 1, "één misstap")
	var b2 := H.mk_stage("1-1", 0) as ScBindery
	t.eq(b2.apply({"act": "bind", "a": 2, "b": 2}).reason, "same", "klem same")
	H.play(b2, bad)
	t.eq([b2.counters.twine, b2.bits], [22, "0001010001010101111011"], "perfect: 22 bits p. 86")
	t.eq(b2.codes, {"b": "000", "s": "001", "d": "010", "r": "011", "o": "10", "e": "11"}, "codes p. 85")
	var p := H.mk_stage("1-5", 0) as ScBindery
	t.eq(p.apply({"act": "bind", "a": "B", "b": "B"}).reason, "empty", "klem empty")
	H.play(p, bad)
	t.eq([p.counters.twine, p.counters.search], [59, 12], "planken: touw 59, zoekwerk 12")
	var rw := H.mk_stage("1-5", 0) as ScBindery
	var row := H.mk({"tool": "bindery", "mode": "row", "text": "de kok kookt koolsoep",
		"row": "dtlspe k" + "o"}) as ScBindery
	H.play(row, bad)
	t.eq(row.counters.search, 64, "rij: zoekwerk 64")
	t.eq(rw.shelf_a.size(), 9, "plank A 9 stapels")
	var k := H.mk_stage("1-4", 0) as ScBindery
	H.play(k, bad)
	t.eq([k.counters.twine, k.counters.ink], [59, 59], "registers 59")
	var bk := H.mk_stage("1-2", 0) as ScBindery
	H.play(bk, bad)
	t.eq(bk.bits, "0001001100100100100011110011", "bananenboom")
	var z := H.mk_stage("1-3", 0) as ScBindery
	H.play(z, bad)
	t.eq(z.counters.twine, 59, "zaken 59")
	var st := H.mk({"tool": "bindery", "mode": "row", "weights": [["a", 1], ["b", 1], ["c", 5]], "strict": true}) as ScBindery
	var rs := st.apply({"act": "bind", "a": 0, "b": 2})
	t.eq([rs.ok, rs.verdict, st.row.size(), st.counters.twine], [true, V.WRONG_PAIR, 3, 0], "strikt: touw knapt")


func _t26(t) -> void:
	t.section("T26 levende boom")
	var g := H.mk_stage("2-2", 0) as ScLivingTree
	_until(g, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB and (x as ScLivingTree).i == 2)
	t.eq(g.tree.label(g.t), "*[1,5]", "lantaarn bij [1,5]")
	t.eq(g.tree.label(g.tree.max_num_with_weight(1)), "g[1,6]", "t′ = g[1,6]")
	var r := g.apply({"act": "keep"})
	t.eq([r.ok, r.verdict], [true, V.MISSED_SWAP], "blijven staan")
	var bad := [0]
	H.play(g, bad, true)
	t.eq(bad[0], 0, "bot verder " + str(bad))
	t.eq(ScReference.tokens_to_string(g.tokens_out), "\"g\"0\"r\"00\"a\"001001", "tokens van de speler")
	t.eq(H.read_of(g), "graggga", "Letterlijk leest graggga")
	t.eq(g.log.mistakes().size(), 1, "precies één misstap")
	t.eq(str(g.overkant().text), "graggga", "De Overkant")
	var gp := H.mk_stage("2-2", 0) as ScLivingTree
	H.play(gp, bad)
	t.eq([gp.counters.ink, H.read_of(gp)], [33, "graag"], "perfect graag")
	var e := H.mk_stage("2-3", 0) as ScLivingTree
	_until(e, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB)
	t.eq((e as ScLivingTree).i, 1, "eerste klim bij de tweede e")
	var ra := e.apply({"act": "swap", "with": e.tree.root})
	t.eq([ra.ok, ra.reason], [false, "ancestor"], "wissel met de ouder klemt")
	var rs := e.apply({"act": "swap", "with": e.t})
	t.eq(rs.reason, "self", "klem self")
	t.eq(e.apply({"act": "keep"}).verdict, V.OK, "blijf (ouder)")
	H.play(e, bad)
	t.eq([e.counters.ink, H.read_of(e)], [55, "eetzaal"], "perfect eetzaal")
	var e2 := H.mk_stage("2-3", 0) as ScLivingTree
	_until(e2, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB and (x as ScLivingTree).i == 4)
	e2.apply({"act": "keep"})
	H.play(e2, bad)
	t.eq(H.read_of(e2), "eetzate…", "eetzate…")
	var v := H.mk_stage("2-4", 0) as ScLivingTree
	_until(v, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB and (x as ScLivingTree).i == 4)
	v.apply({"act": "keep"})
	H.play(v, bad)
	t.eq(H.read_of(v), "voordvoo…", "voordvoo…")
	var vp := H.mk_stage("2-4", 0) as ScLivingTree
	H.play(vp, bad)
	t.eq([vp.counters.ink, H.read_of(vp)], [68, "voordeel"], "perfect voordeel")
	var rc := H.mk_stage("2-5", 0) as ScLivingTree
	_until(rc, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB and (x as ScLivingTree).i == 2)
	t.eq(rc.apply({"act": "keep"}).verdict, V.MISSED_SWAP, "ontvanger: blijven staan")
	H.play(rc, bad)
	t.eq(rc.copy(), "noonn…", "kopie noonn…")
	var rp := H.mk_stage("2-5", 0) as ScLivingTree
	var wrong_leaf: int = -1
	for x in rp.tree.leaves():
		if x != int(rp.correct_move().leaf):
			wrong_leaf = x
	t.eq(rp.apply({"act": "read", "leaf": wrong_leaf}).reason, "no_path", "ontvangen: verkeerd blad klemt")
	H.play(rp, bad)
	t.eq(rp.copy(), "nooddaad", "kopie nooddaad")
	t.eq(rp.tree.show(), "[8,9]([3,7]([1,3](nng[0,1] n[1,2]) a[2,4]) [5,8](o[2,5] d[3,6]))", "eindboom Oef. 91")
	var a := H.mk_stage("2-1", 0) as ScLivingTree
	H.play(a, bad)
	t.eq(a.tree.show(), "[10,11]([4,9]([2,5](b[1,1] s[1,2]) [2,6](d[1,3] r[1,4])) [6,10](e[3,7] o[3,8]))", "2-1 A")
	var bb := H.mk_stage("2-1", 1) as ScLivingTree
	H.play(bb, bad)
	t.eq(bb.tree.show(), "[10,11]([4,9]([2,5](b[1,1] r[1,2]) e[2,6]) [6,10]([3,7](d[1,3] s[2,4]) o[3,8]))", "2-1 B")
	t.eq(bb.counters.ink, 3, "s = 001")
	var nb := H.mk_stage("2-1", 1) as ScLivingTree
	_until(nb, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.CLIMB)
	var rec := H.record(nb)
	while not nb.is_done():
		nb.apply({"act": "keep"})
	t.eq(nb.tree.show(), "[10,11]([5,9]([3,5](b[1,1] s[2,2]) [2,6](d[1,3] r[1,4])) [5,10](e[2,7] o[3,8]))", "zonder wissels")
	t.ok(H.fx_names(rec).has("stumble"), "monniken struikelen")


func _t27(t) -> void:
	t.section("T27 meetlat")
	var bad := [0]
	var c := H.mk_stage("3-2", 0) as ScRuler
	_until(c, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.NEEDLE)
	var r := c.apply({"act": "bit", "b": 1})
	t.eq([r.verdict, r.done, c.bits], [V.OVERSHOOT, true, "1"], "overshoot")
	t.eq(H.read_of(c), "gaa", "Letterlijk leest gaa")
	var c2 := H.mk_stage("3-2", 0) as ScRuler
	_until(c2, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.NEEDLE)
	t.eq(c2.apply({"act": "bit", "b": 0}).verdict, V.OK, "eerste 0")
	var rec := H.record(c2)
	t.eq(c2.apply({"act": "bit", "b": 0}).verdict, V.UNREACHABLE, "onbereikbaar")
	t.ok(H.fx_names(rec).has("needle_reset"), "naald zakt terug")
	t.eq([c2.bits, c2.counters.wasted], ["", 2], "strook gewist")
	H.play(c2, bad)
	t.eq([c2.bits, c2.counters.ink, H.read_of(c2)], ["01011", 7, "cag"], "verder: 01011, inkt 7")
	var cp := H.mk_stage("3-2", 0) as ScRuler
	H.play(cp, bad)
	t.eq([cp.bits, cp.counters.ink], ["01011", 5], "perfect cag")
	var y := H.mk_stage("3-1", 0) as ScRuler
	_until(y, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.NEEDLE)
	t.eq(y.apply({"act": "bit", "b": 0}).verdict, V.LONG_BITS, "te lang")
	H.play(y, bad)
	t.eq([y.bits, H.read_of(y)], ["011", "yy"], "strook 011, yy")
	var w := y.apply({"act": "cut", "sym": "x"})
	t.eq(w.reason, "wrong_phase", "na het einde")
	var pin := H.mk_stage("3-1", 3) as ScRuler
	t.eq(pin.apply({"act": "cut", "sym": "x"}).reason, "no_pin", "x klemt")
	var we := pin.apply({"act": "cut", "sym": "y"})
	t.eq([we.verdict, pin.copy()], [V.WRONG_EDGE, "yz"], "WRONG_EDGE → yz")
	var pin2 := H.mk_stage("3-1", 3) as ScRuler
	H.play(pin2, bad)
	t.eq(pin2.copy(), "zx", "0,9 → zx")
	var o := H.mk_stage("3-3", 0) as ScRuler
	H.play(o, bad)
	t.eq(o.copy(), "act", "act")
	var o2 := H.mk_stage("3-3", 1) as ScRuler
	t.eq(o2.apply({"act": "cut", "sym": "c"}).verdict, V.WRONG_EDGE, "grens c|g")
	var o3 := H.mk_stage("3-3", 1) as ScRuler
	H.play(o3, bad)
	t.eq(o3.copy(), "ga", "ga")
	var f := H.mk_stage("3-4", 0) as ScRuler
	H.play(f, bad)
	t.eq([f.bits, f.counters.decisions], ["1", 6], "veertig letters: 5 knippen + 1 bit")
	t.eq(f.low.to_full_string(), "0.4999999999999965013204725978495833741312", "exact low")
	t.eq(f.book.size(), 40, "rekenboek 40 regels")
	var xx := H.mk({"tool": "ruler", "side": "send", "model": ScLevels.XYZ, "text": "x"})
	H.play(xx, bad)
	t.eq([(xx as ScRuler).bits, xx.counters.decisions], ["0", 1], "low = 0 → 0 automatisch")
	t.eq(bad[0], 0, "orakel meetlat " + str(bad))


func _t28(t) -> void:
	t.section("T28 leesraam")
	var bad := [0]
	var w := H.mk_stage("4-1", 0) as ScWindow
	_until(w, func(x: ScTool) -> bool: return (x as ScWindow).k == 3)
	t.eq(w.apply({"act": "start", "p": 2}).reason, "no_match", "no_match")
	t.eq(w.apply({"act": "start", "p": 3}).reason, "out_of_window", "out_of_window")
	_until(w, func(x: ScTool) -> bool: return (x as ScWindow).k == 8)
	t.eq(w.apply({"act": "literal"}).verdict, V.SHORT_MATCH, "geen match terwijl er één is")
	H.play(w, bad)
	t.eq(w.triples.slice(5), [[0, 0, "b"], [0, 0, "a"], [1, 2, "EOF"]], "8 zegels")
	t.eq([w.counters.ink, H.read_of(w)], [8, "banaan-baan"], "voorlezing juist")
	var wp := H.mk_stage("4-1", 0) as ScWindow
	var rec := H.record(wp)
	H.play(wp, bad)
	t.eq(wp.counters.ink, 7, "perfect 7 zegels")
	var th: Dictionary = {}
	for f in rec:
		if str(f.fx) == "thread":
			th = f
	t.eq([th.from, th.to, th.steps], [3, 8, [3, 4, 5]], "draad van de laatste match")
	var d := H.mk_stage("4-2", 0) as ScWindow
	_until(d, func(x: ScTool) -> bool: return (x as ScWindow).idx == 3)
	t.eq(d.apply({"act": "start", "p": 1}).verdict, V.WRONG_POS, "p = 1 bij (0,2,r)")
	H.play(d, bad)
	t.eq(d.copy(), "aanvanrdbanr", "aanvanrdbanr")
	var sw := H.mk_stage("4-3", 0) as ScWindow
	var rec2 := H.record(sw)
	H.play(sw, bad)
	t.eq(sw.counters.ink, 9, "swiss: 9 zegels")
	var over := -1
	for f in rec2:
		if str(f.fx) == "thread" and int(f.overlap_from) >= 0:
			over = int(f.overlap_from)
	t.eq(over, 5, "draad loopt over de rand (vanaf de zesde letter)")
	var bl := H.mk_stage("4-4", 1) as ScWindow
	H.play(bl, bad)
	t.eq(bl.copy(), "blablablabla", "blablablabla")
	var rg := H.mk_stage("4-6", 0) as ScWindow
	var g := 0
	while not rg.is_done() and g < 100:
		g += 1
		rg.apply({"act": "register"})
		rg.apply(rg.correct_move())
	t.eq([rg.counters.ink, rg.counters.search], [13, 22], "register: 13 zegels, zoekwerk 22")
	var nr := H.mk({"tool": "window", "side": "send", "text": "abracadabra_simsalabim", "G": -1, "register": false}) as ScWindow
	H.play(nr, bad)
	t.eq(nr.counters.search, 146, "zonder register 146")
	t.eq(bad[0], 0, "orakel leesraam " + str(bad))


func _t29(t) -> void:
	t.section("T29 stempelkast")
	var bad := [0]
	var s := H.mk_stage("5-1", 0) as ScStampCase
	t.eq(s.apply({"act": "extend"}).reason, "no_stamp", "ba bestaat niet")
	_until(s, func(x: ScTool) -> bool: return str(x.correct_move().act) == "extend")
	t.eq(s.w + s._k(), "an", "eerste an")
	t.eq(s.apply({"act": "stamp"}).verdict, V.EARLY_STAMP, "te vroeg stempelen")
	H.play(s, bad)
	t.eq(s.out, [98, 97, 110, 97, 97, 258, 257, 118, 97, 108], "codes met dubbele lade")
	t.eq(s.word_of(260), "an", "lade 260 = an")
	t.ok(bool(s.entries[4][2]), "dubbel")
	t.eq(H.read_of(s), "banaanaanval", "voorlezing juist")
	var sp := H.mk_stage("5-1", 0) as ScStampCase
	H.play(sp, bad)
	t.eq([sp.out, sp.counters.ink], [[98, 97, 110, 97, 257, 259, 110, 118, 97, 108], 10], "perfect 10 stempels")
	var r := H.mk_stage("5-2", 0) as ScStampCase
	t.eq(r.phase, ScCodes.Phase.CARVE, "eerste snijkeuze")
	t.eq([r.volgend, r.special], ["an", false], "lade 256 = an")
	r.apply({"act": "carve", "i": 0})
	t.eq(r.special, true, "lege lade bij 258")
	t.eq(r.apply({"act": "carve", "i": 2}).reason, "range", "j ≥ |w|")
	t.eq(r.apply({"act": "carve", "i": 1}).verdict, V.WRONG_CARVE, "verkeerde letter")
	H.play(r, bad)
	t.eq(r.copy(), "anananns", "anananns")
	var rp := H.mk_stage("5-2", 0) as ScStampCase
	H.play(rp, bad)
	t.eq([rp.copy(), rp.words()], ["anananas", ["an", "na", "ana", "anas"]], "perfect anananas")
	t.eq(rp.counters.decisions, 2, "2 beslissingen")
	var aa := H.mk_stage("5-2", 1) as ScStampCase
	H.play(aa, bad)
	t.eq(aa.out, [97, 256, 257, 256], "aaaaaaaa")
	var o := H.mk_stage("5-4", 0) as ScStampCase
	H.play(o, bad)
	t.eq([o.copy(), o.words(), o.counters.decisions], ["aaabcabaabab", ["aa", "aab", "bc", "ca", "ab", "ba", "aaba"], 3],
		"Oef. 102")
	var sw := H.mk_stage("5-3", 0) as ScStampCase
	H.play(sw, bad)
	t.eq([sw.counters.ink, sw.counters.decisions], [14, 17], "swiss: 14 stempels, 17 beslissingen")
	t.eq(bad[0], 0, "orakel stempelkast " + str(bad))


func _t30(t) -> void:
	t.section("T30 trommel")
	var bad := [0]
	var d := H.mk_stage("6-1", 0) as ScDrum
	d.apply(d.correct_move())
	var r := d.apply({"act": "insert", "gap": 0})
	t.eq([r.verdict, d.pending], [V.WRONG_ORDER, 3], "rotatie 2 bovenaan")
	_until(d, func(x: ScTool) -> bool: return x.phase == ScCodes.Phase.MARK)
	t.eq(d.last_column(), "negn eool", "c = negn eool")
	t.eq(d.apply({"act": "mark", "row": 2}).verdict, V.OK, "rij 2 = een loong")
	t.eq(H.read_of(d), "gen loong", "Letterlijk leest gen loong")
	var d2 := H.mk_stage("6-1", 0) as ScDrum
	var gaps: Array = []
	_until(d2, func(x: ScTool) -> bool:
		if x.phase == ScCodes.Phase.INSERT:
			gaps.append(int(x.correct_move().gap))
		return x.phase == ScCodes.Phase.MARK)
	t.eq(gaps, [0, 1, 3, 0, 4, 6, 6, 6], "spleten 6-1")
	t.eq(Array(d2.rows()), ScReference.bwt("geen loon").rows, "rek p. 116")
	t.eq(d2.apply({"act": "mark", "row": 2}).verdict, V.WRONG_P, "verkeerde rij")
	t.eq(H.read_of(d2), "een loong", "Letterlijk leest een loong")
	var d3 := H.mk_stage("6-1", 0) as ScDrum
	H.play(d3, bad)
	t.eq(d3.output().text, "1 ngen eool", "uitvoer p. 117")
	var w := H.mk_stage("6-2", 1) as ScDrum
	t.eq(w.copy(), "ge", "begin: g, dan e")
	t.eq(w.apply({"act": "find", "i": 5}).verdict, V.WRONG_RANK, "e₂ i.p.v. e₁")
	var w2 := H.mk_stage("6-2", 1) as ScDrum
	t.eq(w2.apply({"act": "find", "i": 0}).reason, "letter", "andere letter klemt")
	var picks: Array = []
	_until(w2, func(x: ScTool) -> bool:
		if x.phase == ScCodes.Phase.WALK:
			picks.append(int(x.correct_move().i))
		return false)
	t.eq(picks, [2, 5, 0, 4, 8, 7, 6, 3], "de weg van p. 117")
	t.eq(w2.copy(), "geen loon", "kopie geen loon")
	var f := H.mk_stage("6-4", 0) as ScDrum
	var all_ok := true
	while f.phase == ScCodes.Phase.INSERT:
		var gp := f._gaps(f.pending)
		var rr := f.apply({"act": "insert", "gap": int(gp[1])})
		all_ok = all_ok and int(rr.verdict) == V.OK
	t.ok(all_ok, "Fig. 26: elke spleet binnen de groep is goed")
	t.eq(f.apply({"act": "mark", "row": 5}).verdict, V.OK, "rij 5 van het blok")
	t.eq(H.read_of(f), "aacaacaac", "aacaacaac")
	var f2 := H.mk_stage("6-4", 1) as ScDrum
	H.play(f2, bad)
	t.eq(f2.copy(), "aacaacaac", "Fig. 26 terug")
	var c := H.mk_stage("C", 0) as ScDrum
	t.eq(c.phase, ScCodes.Phase.MARK, "Codex: trommel sorteert zelf")
	H.play(c, bad)
	t.eq([c.p_out, c.c_out], [2, "sssssnnnaaauus  ucccttt"], "Codex BWT")
	t.eq(bad[0], 0, "orakel trommel " + str(bad))


func _t31(t) -> void:
	t.section("T31 letterplank")
	var bad := [0]
	var s := H.mk_stage("6-1", 1) as ScShelf
	_until(s, func(x: ScTool) -> bool: return (x as ScShelf).i == 2)
	t.eq(s.apply({"act": "number", "k": 8}).verdict, V.WRONG_INDEX, "8 i.p.v. 7")
	H.play(s, bad)
	t.eq(s.out, [1, 1, 8, 7, 6, 2, 3, 2, 8, 0, 9], "getallen")
	t.eq(H.read_of(s), "1 ogeo ennl", "Letterlijk leest 1 ogeo ennl")
	t.eq(s.apply({"act": "number", "k": 0}).reason, "wrong_phase", "klaar")
	var sp := H.mk_stage("6-1", 1) as ScShelf
	t.eq(sp.apply({"act": "number", "k": 10}).reason, "range", "klem range")
	H.play(sp, bad)
	t.eq([sp.out, sp.counters.zeros], [[1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9], 1], "p. 121")
	var r := H.mk_stage("6-2", 0) as ScShelf
	_until(r, func(x: ScTool) -> bool: return (x as ScShelf).i == 2)
	t.eq(r.apply({"act": "pick", "k": 8}).verdict, V.WRONG_INDEX, "ontvangen 8")
	H.play(r, bad)
	t.eq(r.copy(), "1 ogeo ennl", "kopie 1 ogeo ennl")
	var o := H.mk_stage("6-3", 1) as ScShelf
	H.play(o, bad)
	t.eq(o.out, [7, 1, 15, 14, 13, 3, 16, 0, 17, 0, 3], "Oef. 104")
	var c := H.mk_stage("C", 1) as ScShelf
	H.play(c, bad)
	t.eq([c.out.count(0), c.counters.zeros], [14, 14], "Codex: 14 nullen")
	var c3 := H.mk_stage("C", 2) as ScBindery
	H.play(c3, bad)
	t.eq(c3.counters.ink, 56, "Codex: 56 bits")
	var x := H.mk_stage("6-5", 0) as ScShelf
	H.play(x, bad)
	t.eq(x.copy(), "7 tnooeoobwn n", "Oef. 105")
	t.eq(bad[0], 0, "orakel plank " + str(bad))


func _t32(t) -> void:
	t.section("T32 duiventil")
	var d := H.mk_stage("0-3", 0) as ScDovecote
	t.eq(d.apply({"act": "roost", "pigeon": 0, "hole": "0000"}).reason, "not_shorter", "zolder terwijl kort vrij")
	d.apply({"act": "roost", "pigeon": 0, "hole": "01"})
	t.eq(d.apply({"act": "roost", "pigeon": 1, "hole": "01"}).reason, "taken", "bezet")
	_until(d, func(x: ScTool) -> bool: return (x as ScDovecote).roost.size() == 7)
	t.eq(d.correct_move().hole, "0000", "achtste duif naar de zolder")
	t.eq(d.apply({"act": "roost", "pigeon": 7, "hole": "0000"}).verdict, V.OK, "zolder nu toegelaten")
	t.eq(d.phase, ScCodes.Phase.DECREE, "decreten")
	t.eq(d.apply({"act": "decree", "which": 1, "answer": "true"}).verdict, V.WRONG_DECREE, "decreet 1 fout")
	d.apply({"act": "decree", "which": 2, "answer": "true"})
	t.ok(d.is_done() and not d.decrees_ok(), "klaar, niet alle decreten juist")
