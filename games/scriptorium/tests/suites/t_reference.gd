extends RefCounted
## T01–T22: ScReference, ScDec en ScReader tegen de notas (GDD §9).

const FIG25 := {"o": "00", "u": "010", "d": "011", "f": "10", "t": "11"}
const BEN := {"e": "0", "n": "1", "b": "10"}
const XYZ := [["x", "0.2"], ["y", "0.7"], ["z", "0.1"]]
const ACGT := [["a", "0.3"], ["c", "0.2"], ["g", "0.4"], ["t", "0.1"]]
const S40 := "yyyxzxxzyyyxyyyyxyyyzxyxyyyyxxyyyyyyxyyy"
const LIST61 := [" ", "1", "a", "b", "e", "f", "g", "n", "o", "l"]


func run(t) -> void:
	_t01(t)
	_t02(t)
	_t03(t)
	_t04(t)
	_t05(t)
	_t06(t)
	_t07(t)
	_t08(t)
	_t09(t)
	_t10(t)
	_t11(t)
	_t12(t)
	_t13(t)
	_t14(t)
	_t15(t)
	_t16(t)
	_t17(t)
	_t18(t)
	_t19(t)
	_t20(t)
	_t21(t)
	_t22(t)
	_reader(t)


static func _w(row: Array) -> Array:
	var out: Array = []
	for x in row:
		out.append(int(x[1]))
	return out


func _t01(t) -> void:
	t.section("T01 prefixcodes")
	var d := ScReference.decode_prefix(FIG25, "00010011")
	t.eq(d.text, "oud", "Fig. 25")
	t.eq(d.cuts, [2, 5, 8], "knippen Fig. 25")
	var d2 := ScReference.decode_prefix(FIG25, "100001011")
	t.eq(d2.text, "fout", "Oef. 79")
	t.eq(d2.cuts, [2, 4, 7, 9], "knippen Oef. 79")
	t.ok(ScReference.is_prefix_code(FIG25), "Fig. 25 is prefix")
	t.ok(not ScReference.is_prefix_code(BEN), "e/n/b geen prefix")
	var ps := Array(ScReference.all_parses(BEN, "100101"))
	ps.sort()
	t.eq(ps, ["bebn", "benen", "neebn", "neenen"], "lezingen 100101")
	var ps2 := Array(ScReference.all_parses(BEN, "10001"))
	ps2.sort()
	t.eq(ps2, ["been", "neeen"], "lezingen 10001")
	t.eq(ScReference.greedy_read(BEN, "100101"), "neenen", "gulzig")
	t.eq(ScReference.code_cost({"e": "0", "n": "10", " ": "110", "b": "111"}, ScReference.freqs_in_order("een been en een benen")), 39,
		"codebord 39")
	t.eq(ScReference.huffman_cost(_w(ScReference.freqs_in_order("een been en een benen"))), 39, "codebord optimum")


func _t02(t) -> void:
	t.section("T02 Huffman boosdoeer")
	var row := ScReference.freqs_in_order("boosdoeer", "boesdr")
	t.eq(row, [["b", 1], ["o", 3], ["e", 2], ["s", 1], ["d", 1], ["r", 1]], "rij p. 85")
	var h := ScReference.huffman(row)
	var ij: Array = []
	for s in h.steps:
		ij.append([int(s.i), int(s.j), int(s.w)])
	t.eq(ij, [[0, 3, 2], [3, 4, 2], [0, 3, 4], [2, 1, 5], [0, 1, 9]], "stappen p. 85 (X = e, Y = o)")
	t.eq(h.steps[2].row_labels, ["(bs):2", "o:3", "e:2", "(dr):2"], "rij vóór stap 3")
	t.eq(h.codes, {"b": "000", "s": "001", "d": "010", "r": "011", "o": "10", "e": "11"}, "codes p. 85")
	t.eq(ScReference.encode_with(h.codes, "boosdoeer"), "0001010001010101111011", "bericht p. 86")
	t.eq(h.cost, 22, "kost")
	t.eq(ScReference.huffman_cost([1, 3, 2, 1, 1, 1]), 22, "huffman_cost")
	t.eq(ScReference.valid_pairs([1, 3, 2, 1, 1, 1]), [[0, 3], [0, 4], [0, 5], [3, 4], [3, 5], [4, 5]], "geldige paren")
	var runs := ScReference.huffman_runs(row)
	t.eq(runs.runs, 18, "18 keuzereeksen")
	t.eq(runs.costs, [22], "allemaal 22")
	var bad := ScReference.huffman(row, [[0, 1]])
	t.eq(bad.cost, 23, "b+o eerst: 23")


func _t03(t) -> void:
	t.section("T03 Oef. 80/81")
	var row := ScReference.freqs_in_order("bananenboom")
	t.eq(row, [["b", 2], ["a", 2], ["n", 3], ["e", 1], ["o", 2], ["m", 1]], "rij bananenboom")
	var h := ScReference.huffman(row)
	t.eq(h.cost, 28, "kost 28")
	t.eq(h.codes, {"b": "000", "e": "0010", "m": "0011", "n": "01", "a": "10", "o": "11"}, "codes Oef. 80")
	t.eq(ScReference.encode_with(h.codes, "bananenboom"), "0001001100100100100011110011", "kortschrift 1-2")
	var r := ScReference.huffman_runs(row)
	t.eq([r.runs, r.profiles, r.costs], [12, 6, [28]], "12 reeksen, 6 profielen")
	var row2 := ScReference.freqs_in_order("zaken_nemen_geen_keer")
	t.eq(row2, [["z", 1], ["a", 1], ["k", 2], ["e", 7], ["n", 4], ["_", 3], ["m", 1], ["g", 1], ["r", 1]], "rij Oef. 81")
	var h2 := ScReference.huffman(row2)
	t.eq(h2.cost, 59, "kost 59")
	t.eq(h2.codes, {"z": "00000", "a": "00001", "r": "0001", "_": "001", "e": "01", "k": "100", "m": "1010",
		"g": "1011", "n": "11"}, "codes Oef. 81")
	var r2 := ScReference.huffman_runs(row2)
	t.eq([r2.runs, r2.profiles, r2.costs], [90, 11, [59]], "90 reeksen, 11 profielen")


func _t04(t) -> void:
	t.section("T04 Oef. 86/85")
	t.eq(ScReference.huffman_cost([8, 3, 5, 2, 9]), 59, "registers 59")
	var lr := ScReference.huffman([["A", 8], ["B", 3], ["C", 5], ["D", 2], ["E", 9]], [[0, 1], [0, 1], [0, 1], [0, 1]])
	t.eq(lr.cost, 72, "links naar rechts 72")
	var h := ScReference.huffman([["A", 8], ["B", 3], ["C", 5], ["D", 2], ["E", 9]])
	t.eq(h.cost, 59, "kanoniek 59")
	t.eq(ScReference.huffman_cost(_w(ScReference.freqs_in_order("de kok kookt koolsoep"))), 59, "koolsoep 59")


func _t05(t) -> void:
	t.section("T05 Algoritme 10 (p. 90–93)")
	var tr := ScReference.p90_tree()
	t.eq(tr.sibling_violations(), [], "p. 90 voldoet aan (a)–(c)")
	t.eq(tr.code(tr.leaf_of("e")), "10", "code e vooraf")
	t.eq(tr.code(tr.leaf_of("s")), "001", "code s vooraf")
	var st := ScReference.adaptive_update(tr, "e")
	t.eq(_kinds(st), ["keep", "keep", "root"], "e: geen wissels")
	t.eq(tr.show(), "[10,11]([4,9]([2,5](b[1,1] s[1,2]) [2,6](d[1,3] r[1,4])) [6,10](e[3,7] o[3,8]))", "boom p. 91")
	var tr2 := ScReference.p90_tree()
	var st2 := ScReference.adaptive_update(tr2, "s")
	t.eq(_kinds(st2), ["swap", "swap", "keep", "root"], "s: twee wissels")
	t.eq(tr2.sym(int(st2[0].t2)), "r", "eerste wisselpartner is r")
	t.eq(tr2.show(), "[10,11]([4,9]([2,5](b[1,1] r[1,2]) e[2,6]) [6,10]([3,7](d[1,3] s[2,4]) o[3,8]))", "boom p. 93")
	t.eq(tr2.sibling_violations(), [], "p. 93 voldoet")
	# zonder wissels: boom onderaan p. 91, schendt (b)
	var tr3 := ScReference.p90_tree()
	var cur := tr3.leaf_of("s")
	while cur != tr3.root:
		tr3.nodes[cur].w = tr3.w(cur) + 1
		cur = tr3.parent(cur)
	tr3.nodes[cur].w = tr3.w(cur) + 1
	t.eq(tr3.show(), "[10,11]([5,9]([3,5](b[1,1] s[2,2]) [2,6](d[1,3] r[1,4])) [5,10](e[2,7] o[3,8]))", "boom p. 91 onder")
	t.ok(not tr3.sibling_violations().is_empty(), "schendt (b)")
	t.eq(tr3.stumbling().size(), 4, "vier monniken struikelen")


static func _kinds(steps: Array) -> Array:
	var out: Array = []
	for s in steps:
		out.append(str(s.kind))
	return out


func _t06(t) -> void:
	t.section("T06 graag (p. 96–98)")
	var e := ScReference.adaptive_encode("graag")
	t.eq(ScReference.tokens_to_string(e.tokens), "\"g\"0\"r\"00\"a\"101101", "tokens")
	t.eq(e.bits, 33, "33 bits")
	var trees := ["[1,3](nng[0,1] g[1,2])", "[2,5]([1,3](nng[0,1] r[1,2]) g[1,4])",
		"[3,7](g[1,5] [2,6]([1,3](nng[0,1] a[1,2]) r[1,4]))", "[4,7](a[2,5] [2,6]([1,3](nng[0,1] g[1,2]) r[1,4]))",
		"[5,7](a[2,5] [3,6]([1,3](nng[0,1] r[1,2]) g[2,4]))"]
	for i in 5:
		t.eq(e.steps[i].tree, trees[i], "boom na teken %d" % i)
	t.eq(_kinds(e.steps[2].log), ["grow", "swap", "root"], "a: groei + wissel")
	t.eq(_kinds(e.steps[4].log), ["swap", "keep", "root"], "g: wissel + blijf")
	var e2 := ScReference.adaptive_encode("graagr")
	t.eq(e2.steps[5].tokens, [{"b": "101"}], "r: 101")
	t.eq(_kinds(e2.steps[5].log), ["keep_parent", "keep", "keep", "root"], "speciaal geval p. 98")
	t.eq(e2.steps[5].tree, "[6,7](a[2,5] [4,6]([2,3](nng[0,1] r[2,2]) g[2,4]))", "boom p. 98")
	t.eq(ScReference.adaptive_decode(e.tokens).text, "graag", "decode graag")


func _t07(t) -> void:
	t.section("T07 eetzaal en Oef. 90")
	var e := ScReference.adaptive_encode("eetzaal")
	t.eq(ScReference.tokens_to_string(e.tokens), "\"e\"10\"t\"00\"z\"000\"a\"11011100\"l\"", "tokens eetzaal")
	t.eq(e.bits, 55, "55 bits")
	t.eq(_kinds(e.steps[1].log), ["keep_parent", "root"], "tweede e: speciaal geval")
	var trees := ["[1,3](nng[0,1] e[1,2])", "[2,3](nng[0,1] e[2,2])", "[3,5]([1,3](nng[0,1] t[1,2]) e[2,4])",
		"[4,7]([2,5]([1,3](nng[0,1] z[1,2]) t[1,4]) e[2,6])",
		"[5,9](e[2,7] [3,8](t[1,5] [2,6]([1,3](nng[0,1] a[1,2]) z[1,4])))",
		"[6,9](e[2,7] [4,8](a[2,5] [2,6]([1,3](nng[0,1] t[1,2]) z[1,4])))",
		"[7,11]([3,9](z[1,5] [2,6]([1,3](nng[0,1] l[1,2]) t[1,4])) [4,10](a[2,7] e[2,8]))"]
	for i in trees.size():
		t.eq(e.steps[i].tree, trees[i], "eetzaal boom %d" % i)
	var v := ScReference.adaptive_encode("voordeel")
	t.eq(ScReference.tokens_to_string(v.tokens), "\"v\"0\"o\"0100\"r\"000\"d\"1100\"e\"10011000\"l\"", "tokens voordeel")
	t.eq(v.bits, 68, "68 bits")
	var vt := ["[1,3](nng[0,1] v[1,2])", "[2,5]([1,3](nng[0,1] o[1,2]) v[1,4])", "[3,5]([1,3](nng[0,1] v[1,2]) o[2,4])",
		"[4,7]([2,5]([1,3](nng[0,1] r[1,2]) v[1,4]) o[2,6])",
		"[5,9](o[2,7] [3,8](v[1,5] [2,6]([1,3](nng[0,1] d[1,2]) r[1,4])))",
		"[6,11](o[2,9] [4,10]([2,7]([1,3](nng[0,1] e[1,2]) d[1,4]) [2,8](v[1,5] r[1,6])))",
		"[7,11]([3,9](v[1,5] e[2,6]) [4,10]([2,7]([1,3](nng[0,1] r[1,2]) d[1,4]) o[2,8]))",
		"[8,13]([4,11]([2,7]([1,3](nng[0,1] l[1,2]) r[1,4]) e[2,8]) [4,12]([2,9](v[1,5] d[1,6]) o[2,10]))"]
	for i in vt.size():
		t.eq(v.steps[i].tree, vt[i], "voordeel boom %d" % i)
	t.eq(ScReference.adaptive_decode(e.tokens).text, "eetzaal", "decode eetzaal")
	t.eq(ScReference.adaptive_decode(v.tokens).text, "voordeel", "decode voordeel")


func _t08(t) -> void:
	t.section("T08 Oef. 91")
	var d := ScReference.adaptive_decode(ScReference.tokens_from_string("\"n\"0\"o\"0100\"d\"001100\"a\"100111"))
	t.eq(d.text, "nooddaad", "nooddaad")
	t.ok(not d.stuck, "niet vast")
	t.eq((d.tree as ScTree).show(), "[8,9]([3,7]([1,3](nng[0,1] n[1,2]) a[2,4]) [5,8](o[2,5] d[3,6]))", "eindboom")
	t.eq(ScReference.tokens_bits(ScReference.tokens_from_string("\"n\"0\"o\"0100\"d\"001100\"a\"100111")), 4 * 8 + 17, "bits")


func _t09(t) -> void:
	t.section("T09 aritmetisch x/y/z")
	var cases := {"yy": ["0.34", "0.83", "1"], "zx": ["0.9", "0.92", "11101"], "x": ["0", "0.2", "0"],
		"yx": ["0.2", "0.34", "01"]}
	for s in cases:
		var iv := ScReference.get_interval(s, XYZ)
		t.eq((iv.low as ScDec).to_full_string(), cases[s][0], s + " low")
		t.eq((iv.up as ScDec).to_full_string(), cases[s][1], s + " up")
		t.eq(ScReference.get_bitstring(iv.low, iv.up).bits, cases[s][2], s + " bits")
	var bounds := {}
	for a in ["x", "y", "z"]:
		for b in ["x", "y", "z"]:
			var iv := ScReference.get_interval(a + b, XYZ)
			bounds[(iv.low as ScDec).to_full_string()] = true
			bounds[(iv.up as ScDec).to_full_string()] = true
	var bl := bounds.keys()
	bl.sort_custom(func(p, q) -> bool: return ScDec.from_string(p).lt(ScDec.from_string(q)))
	t.eq(bl, ["0", "0.04", "0.18", "0.2", "0.34", "0.83", "0.9", "0.92", "0.99", "1"], "grenzen p. 100")
	t.eq(ScReference.arith_decode("1", 2, XYZ).text, "yy", "1 → yy")
	t.eq(ScReference.arith_decode("1101", 2, XYZ).text, "yy", "1101 → yy")
	t.eq(ScReference.arith_decode(ScDec.from_string("0.9"), 2, XYZ).text, "zx", "0.9 → zx")


func _t10(t) -> void:
	t.section("T10 veertig letters")
	t.eq(S40.length(), 40, "n = 40")
	var iv := ScReference.get_interval(S40, XYZ)
	t.eq((iv.low as ScDec).to_full_string(), "0.4999999999999965013204725978495833741312", "low exact")
	t.eq((iv.up as ScDec).to_full_string(), "0.5000000000000032302663786237598696633344", "up exact")
	t.eq(ScReference.get_bitstring(iv.low, iv.up).bits, "1", "één bit")
	t.eq(ScReference.huffman_cost(_w(ScReference.freqs_in_order(S40))), 53, "Huffman 53")
	t.eq(ScReference.lemma24_bound(iv.len), 48, "Lemma 24: 48")
	var lo := 0.0
	var ln := 1.0
	var f := {"x": 0.0, "y": 0.2, "z": 0.9}
	var p := {"x": 0.2, "y": 0.7, "z": 0.1}
	for ch in S40:
		lo = lo + float(f[ch]) * ln
		ln = ln * float(p[ch])
	t.ok(absf(lo - 0.49999999999999639178) < 1e-15 and absf(lo + ln - 0.50000000000000310862) < 1e-15,
		"floats ≈ waarden van de notas (%s, %s)" % [str(lo), str(lo + ln)])
	t.eq((iv.low as ScDec).to_string_sig(12), "0,499999999999…", "UI-weergave")


func _t11(t) -> void:
	t.section("T11 Oef. 93/95")
	var iv := ScReference.get_interval("cag", ACGT)
	var rows: Array = []
	for b in iv.book:
		rows.append([b.sym, (b.links as ScDec).to_full_string(), (b.lengte as ScDec).to_full_string()])
	t.eq(rows, [["c", "0.3", "0.2"], ["a", "0.3", "0.06"], ["g", "0.33", "0.024"]], "rekenboek")
	t.eq((iv.up as ScDec).to_full_string(), "0.354", "up 0.354")
	var bs := ScReference.get_bitstring(iv.low, iv.up)
	t.eq(bs.bits, "01011", "01011")
	var g: Array = []
	for x in bs.trace:
		g.append((x.getal as ScDec).to_full_string())
	t.eq(g, ["0", "0.25", "0.25", "0.3125", "0.34375"], "getal-waarden")
	t.eq(ScReference.lemma24_bound(iv.len), 6, "Lemma 24: 6")
	var d := ScReference.arith_decode("0010011", 3, ACGT)
	t.eq(d.text, "act", "Oef. 95: act")
	var segs: Array = []
	for s in d.trace:
		segs.append([(s.lo as ScDec).to_full_string(), (s.hi as ScDec).to_full_string()])
	t.eq(segs, [["0", "0.3"], ["0.09", "0.15"], ["0.144", "0.15"]], "vakken")
	t.eq(ScReference.arith_decode("1", 2, ACGT).text, "ga", "1 → ga")
	t.eq(ScReference.arith_decode("1", 3, ACGT).text, "gaa", "overshoot cag → gaa")


func _t12(t) -> void:
	t.section("T12 LZ77 p. 106–108")
	var e := ScReference.lz77_encode("banaan-baan", 6)
	t.eq(e.triples, [[0, 0, "b"], [0, 0, "a"], [0, 0, "n"], [1, 1, "a"], [2, 1, "-"], [0, 0, "b"], [1, 3, "EOF"]],
		"banaan-baan")
	var ws: Array = []
	for i in e.info:
		ws.append(i.window)
	t.eq(ws, ["", "b", "ba", "ban", "banaa", "anaan-", "naan-b"], "ramen")
	var tr := [[0, 0, "a"], [0, 1, "n"], [0, 0, "v"], [0, 2, "r"], [0, 0, "d"], [0, 0, "b"], [1, 3, "EOF"]]
	var d := ScReference.lz77_decode_full(tr, 6)
	t.eq(d.text, "aanvaardbaar", "aanvaardbaar")
	t.eq(d.windows, ["a", "aan", "aanv", "anvaar", "nvaard", "vaardb", "rdbaar"], "ramen p. 108")
	var bad := tr.duplicate(true)
	bad[3] = [1, 2, "r"]
	t.eq(ScReference.lz77_decode(bad, 6), "aanvanrdbanr", "verkeerde p")


func _t13(t) -> void:
	t.section("T13 Oef. 97/98")
	var exp := {
		"swiss_miss_missing": [[0, 0, "s"], [0, 0, "w"], [0, 0, "i"], [0, 1, "s"], [0, 0, "_"], [0, 0, "m"], [2, 8, "i"],
			[0, 0, "n"], [0, 0, "g"]],
		"een_benen_been": [[0, 0, "e"], [0, 1, "n"], [0, 0, "_"], [0, 0, "b"], [1, 2, "e"], [2, 4, "e"], [1, 1, "EOF"]],
		"ananas-kanaal": [[0, 0, "a"], [0, 0, "n"], [0, 3, "s"], [0, 0, "-"], [0, 0, "k"], [0, 3, "a"], [0, 0, "l"]],
		"een_been_beet_hebben": [[0, 0, "e"], [0, 1, "n"], [0, 0, "_"], [0, 0, "b"], [0, 7, "t"], [3, 1, "h"],
			[3, 1, "b"], [0, 2, "n"]],
	}
	for s in exp:
		var e := ScReference.lz77_encode(s, 8)
		t.eq(e.triples, exp[s], s)
		t.eq(ScReference.lz77_decode(e.triples, 8), s, s + " terug")
	t.eq(_alts(ScReference.lz77_encode("een_benen_been", 8), 13), [1, 3], "alternatieven een_benen_been")
	t.eq(_alts(ScReference.lz77_encode("ananas-kanaal", 8), 8), [0, 2], "alternatieven ananas-kanaal")
	t.eq(_alts(ScReference.lz77_encode("een_been_beet_hebben", 8), 15), [3, 4], "alternatieven hebben")
	t.eq(ScReference.lz77_decode([[0, 0, "e"], [0, 1, "n"], [0, 0, "d"], [1, 2, "b"], [0, 4, "EOF"]], 6), "eendenbende", "Oef. 98a")
	t.eq(ScReference.lz77_decode([[0, 0, "b"], [0, 0, "l"], [0, 0, "a"], [0, 9, "EOF"]], 6), "blablablabla", "Oef. 98b")


static func _alts(e: Dictionary, k: int) -> Array:
	for i in e.info:
		if int(i.k) == k:
			return Array(i.alts)
	return []


func _t14(t) -> void:
	t.section("T14 Oef. 100 / §4.3.1")
	var s := "abracadabra_simsalabim"
	var e := ScReference.lz77_encode(s, -1)
	t.eq(e.triples, [[0, 0, "a"], [0, 0, "b"], [0, 0, "r"], [0, 1, "c"], [0, 1, "d"], [0, 4, "_"], [0, 0, "s"],
		[0, 0, "i"], [0, 0, "m"], [12, 1, "a"], [0, 0, "l"], [0, 2, "i"], [14, 1, "EOF"]], "13 drietallen")
	var scan := 0
	var reg := 0
	for i in e.info.size():
		scan += int(e.info[i].scan)
		var l := int(e.triples[i][1])
		reg += l if str(e.triples[i][2]) == "EOF" else l + 1
	t.eq(scan, 146, "zoekwerk zonder register")
	t.eq(reg, 22, "met register")
	t.eq(_alts(e, 5), [0, 3], "alternatieven k=5")
	t.eq(_alts(e, 18), [0, 7], "alternatieven k=18")


func _t15(t) -> void:
	t.section("T15 LZW p. 111–114")
	var e := ScReference.lzw_encode("banaanaanval")
	t.eq(e.codes, [98, 97, 110, 97, 257, 259, 110, 118, 97, 108], "banaanaanval")
	t.eq(e.adds, [[256, "ba"], [257, "an"], [258, "na"], [259, "aa"], [260, "ana"], [261, "aan"], [262, "nv"],
		[263, "va"], [264, "al"]], "woorden")
	t.eq(e.steps, ["stamp", "stamp", "stamp", "stamp", "extend", "stamp", "extend", "stamp", "stamp", "stamp", "stamp"],
		"beslissingen")
	var d := ScReference.lzw_decode([97, 110, 256, 258, 115])
	t.eq(d.text, "anananas", "anananas")
	t.eq(d.adds, [[256, "an"], [257, "na"], [258, "ana"], [259, "anas"]], "woorden p. 114")
	t.eq(d.special, [3], "speciaal geval bij 258")
	var a := ScReference.lzw_encode("aaaaaaaa")
	t.eq(a.codes, [97, 256, 257, 256], "aaaaaaaa")
	var da := ScReference.lzw_decode(a.codes)
	t.eq(da.text, "aaaaaaaa", "terug")
	t.eq(da.special.size(), 2, "twee speciale gevallen")


func _t16(t) -> void:
	t.section("T16 Oef. 101/102")
	t.eq(ScReference.lzw_encode("swiss_miss_missing").codes, [115, 119, 105, 115, 115, 95, 109, 258, 260, 262, 259, 105, 110, 103],
		"swiss")
	var sw := ScReference.lzw_encode("swiss_miss_missing")
	var words: Array = []
	for x in sw.adds:
		words.append(x[1])
	t.eq(words, ["sw", "wi", "is", "ss", "s_", "_m", "mi", "iss", "s_m", "mis", "ssi", "in", "ng"], "woorden swiss")
	var steps := ""
	for s in sw.steps:
		steps += "S" if s == "stamp" else "V"
	t.eq(steps, "SSSSSSSVSVSVSVSSS", "17 beslissingen")
	t.eq(ScReference.lzw_encode("een_beenen_been").codes, [101, 101, 110, 95, 98, 256, 110, 257, 259, 261], "een_beenen_been")
	t.eq(ScReference.lzw_encode("ananas-kanaal").codes, [97, 110, 256, 97, 115, 45, 107, 258, 97, 108], "ananas-kanaal")
	var d := ScReference.lzw_decode([97, 256, 98, 99, 97, 98, 257, 260])
	t.eq(d.text, "aaabcabaabab", "Oef. 102")
	var w2: Array = []
	for x in d.adds:
		w2.append(x[1])
	t.eq(w2, ["aa", "aab", "bc", "ca", "ab", "ba", "aaba"], "woorden Oef. 102")


func _t17(t) -> void:
	t.section("T17 BWT + MTF geen loon")
	var b := ScReference.bwt("geen loon")
	t.eq(b.p, 1, "p")
	t.eq(b.c, "ngen eool", "c")
	t.eq(b.rows, [" loongeen", "een loong", "en loonge", "geen loon", "loongeen ", "n loongee", "ngeen loo", "ongeen lo",
		"oongeen l"], "rijen p. 116")
	var inv := ScReference.inverse_bwt(1, "ngen eool")
	t.eq(inv.text, "geen loon", "terugweg")
	t.eq(inv.e, " eeglnnoo", "e")
	var rows: Array = []
	for x in inv.walk:
		rows.append(int(x.i))
	t.eq(rows, [1, 2, 5, 0, 4, 8, 7, 6, 3], "weg")
	var m := ScReference.mtf_encode("1 ngen eool", LIST61)
	t.eq(m.nums, [1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9], "mtf p. 121")
	t.eq(m.lists[m.lists.size() - 1], ["l", "o", "e", " ", "n", "g", "1", "a", "b", "f"], "eindlijst")
	t.eq(ScReference.mtf_decode(m.nums, LIST61).text, "1 ngen eool", "mtf terug")
	t.eq(ScReference.inverse_bwt(2, "ngen eool").text, "een loong", "p = 2")
	t.eq(ScReference.inverse_bwt(2, "negn eool").text, "gen loong", "verkeerd rek p = 2")
	t.eq(ScReference.inverse_bwt(1, "negn eool").text, "eeeeeeeee", "verkeerd rek p = 1")
	var mm := ScReference.mtf_decode([1, 1, 8, 7, 6, 2, 3, 2, 8, 0, 9], LIST61)
	t.eq(mm.text, "1 ogeo ennl", "mtf afwijking")


func _t18(t) -> void:
	t.section("T18 Oef. 104 en Fig. 26")
	var b := ScReference.bwt("toon gaat")
	t.eq([b.p, b.c], [6, "nga ootta"], "Oef. 104")
	t.eq(b.rows, [" gaattoon", "aattoon g", "attoon ga", "gaattoon ", "n gaattoo", "on gaatto", "oon gaatt", "toon gaat",
		"ttoon gaa"], "rek Oef. 104")
	var lst: Array = []
	for ch in " 0123456789abgmnot":
		lst.append(ch)
	t.eq(ScReference.mtf_encode("6 nga ootta", lst).nums, [7, 1, 15, 14, 13, 3, 16, 0, 17, 0, 3], "mtf Oef. 104")
	var f := ScReference.bwt("aacaacaac")
	t.eq([f.p, f.c], [3, "cccaaaaaa"], "Fig. 26")
	for p in [3, 4, 5]:
		t.eq(ScReference.inverse_bwt(p, "cccaaaaaa").text, "aacaacaac", "p = %d" % p)
	for p in [0, 1, 2]:
		t.eq(ScReference.inverse_bwt(p, "cccaaaaaa").text, "caacaacaa", "p = %d" % p)
	var w: Array = []
	for x in ScReference.inverse_bwt(3, "cccaaaaaa").walk:
		w.append(int(x.i))
	t.eq(w, [3, 6, 0, 3, 6, 0, 3, 6, 0], "weg Fig. 26")


func _t19(t) -> void:
	t.section("T19 Oef. 105 (move-to-front)")
	var lst: Array = []
	for ch in "7aeioubcntw ":
		lst.append(ch)
	t.eq(ScReference.mtf_decode([0, 11, 10, 10, 7, 0, 6, 1, 0, 9, 11, 4, 6, 1], lst).text, "7 tnooeoobwn n", "Oef. 105")
	# de LF-permutatie van tnooeoobwn␣n heeft meer dan één cyclus
	var c := "tnooeoobwn n"
	var e := ScReference.sorted_chars(c)
	var rc := ScReference.ranks(c)
	var re := ScReference.ranks(e)
	var seen := {}
	var i := 7
	for _k in c.length():
		seen[i] = true
		i = ScReference.index_of_rank(c, e[i], re[i])
	t.ok(seen.size() < c.length(), "terugweg valt uiteen in kringetjes")


func _t20(t) -> void:
	t.section("T20 Codex")
	var s := "sanctus sanctus sanctus"
	var b := ScReference.bwt(s)
	t.eq([b.p, b.c], [2, "sssssnnnaaauus  ucccttt"], "BWT sanctus")
	var lst: Array = []
	for ch in " 2acnstu":
		lst.append(ch)
	var m := ScReference.mtf_encode(ScReference.bwt_text(b.p, b.c), lst)
	t.eq(m.nums, [1, 1, 5, 0, 0, 0, 0, 5, 0, 0, 4, 0, 0, 7, 0, 3, 4, 0, 2, 6, 0, 0, 7, 0, 0], "MTF sanctus")
	var syms: Array = []
	for x in m.nums:
		syms.append(str(x))
	var row := ScReference.freqs_of(syms)
	t.eq(row, [["1", 2], ["5", 2], ["0", 14], ["4", 2], ["7", 2], ["3", 1], ["2", 1], ["6", 1]], "rij Codex")
	var h := ScReference.huffman(row)
	t.eq(h.cost, 56, "Huffman op de getallen 56")
	t.eq(h.codes, {"0": "1", "4": "010", "7": "011", "1": "0000", "5": "0001", "6": "0011", "3": "00100", "2": "00101"},
		"codes Codex")
	t.eq(ScReference.huffman_cost(_w(ScReference.freqs_in_order(s))), 63, "Huffman op de tekst 63")
	var bits := ScReference.encode_with(h.codes, syms)
	var rc := ScReader.read_chain([{"p": b.p, "c": b.c}, {"nums": m.nums, "list": lst}, {"bits": bits, "code": h.codes}],
		["bwt", "mtf", "huffman"], [{}, {}, {}])
	t.eq(rc.text, s, "read_chain")


func _t21(t) -> void:
	t.section("T21 invoegspleten")
	t.eq(_lo(ScReference.insertion_gaps("geen loon")), [0, 1, 3, 0, 4, 6, 6, 6], "geen loon")
	t.eq(_lo(ScReference.insertion_gaps("toon gaat")), [0, 0, 0, 0, 1, 1, 2, 8], "toon gaat")
	t.eq(ScReference.insertion_gaps("aacaacaac"), [[1, 1], [2, 2], [0, 1], [2, 3], [4, 5], [0, 2], [3, 5], [6, 8]], "aacaacaac")


static func _lo(g: Array) -> Array:
	var out: Array = []
	for x in g:
		out.append(int(x[0]) if int(x[0]) == int(x[1]) else -1)
	return out


func _t22(t) -> void:
	t.section("T22 ScDec")
	t.eq(ScDec.from_string("0.2").add(ScDec.from_string("0.7")).to_full_string(), "0.9", "0.2 + 0.7")
	t.ok(ScDec.from_string("0.2").add(ScDec.from_string("0.7")).eq(ScDec.from_string("0.9")), "exact gelijk")
	t.eq(ScDec.dyadic(19, 7).to_full_string(), "0.1484375", "19/128")
	t.eq(ScDec.from_bits("0010011").to_full_string(), "0.1484375", "bits 0010011")
	var l := ScDec.one()
	for i in 27:
		l = l.mul(ScDec.from_string("0.7"))
	for i in 10:
		l = l.mul(ScDec.from_string("0.2"))
	for i in 3:
		l = l.mul(ScDec.from_string("0.1"))
	var iv := ScReference.get_interval(S40, XYZ)
	t.ok(l.eq(iv.len), "lengte = 0.7^27·0.2^10·0.1^3")
	t.ok(l.eq((iv.up as ScDec).sub(iv.low)), "lengte = up − low")
	t.eq(l.to_string_sig(3), "0,00000000000000672…", "≈ 6,73·10⁻¹⁵ (afgekapt)")
	var h := ScDec.one()
	for i in 60:
		h = h.half()
	t.ok(h.eq(ScDec.dyadic(1, 60)), "2^−60 via half")
	t.eq(ScDec.dyadic(1, 60).to_full_string().length(), 62, "2^−60 heeft 60 decimalen")
	t.eq(ScDec.from_string("0.5").cmp(ScDec.from_string("0.50")), 0, "cmp gelijk")
	t.eq(ScDec.from_string("0.33").cmp(ScDec.from_string("0.354")), -1, "cmp kleiner")
	t.eq(ScDec.from_string("0.354").cmp(ScDec.from_string("0.33")), 1, "cmp groter")
	t.ok(ScDec.from_string("0").is_zero(), "nul")
	t.eq(ScDec.from_string("0.3").sub(ScDec.from_string("0.5")).to_full_string(), "-0.2", "negatief")
	t.eq(ScDec.from_string("0,25").to_string_sig(), "0,25", "komma")
	t.eq(ScDec.one().to_full_string(), "1", "één")


func _reader(t) -> void:
	t.section("ScReader")
	t.eq(ScReader.read("prefix", {"bits": "00010011", "code": FIG25}).text, "oud", "prefix")
	t.eq(ScReader.read("prefix_greedy", {"bits": "100101", "code": BEN}).text, "neenen", "gulzig")
	t.eq(ScReader.read("adaptive", {"tokens": ScReference.tokens_from_string("\"g\"0\"r\"00\"a\"001001")}).text, "graggga",
		"graggga")
	t.eq(ScReader.read("arith", {"bits": "1", "n": 3, "model": ACGT}).text, "gaa", "arith")
	t.eq(ScReader.read("lzw", {"codes": [98, 97, 110, 97, 97, 258, 257, 118, 97, 108]}).text, "banaanaanval",
		"lzw met dubbele lade")
	t.eq(ScReader.read("bwt", {"p": 1, "c": "ngen eool"}).text, "geen loon", "bwt")
	t.eq(ScReader.read("mtf", {"nums": [1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9], "list": LIST61}).text, "1 ngen eool", "mtf")
	var cmp := ScReader.compare("graag", "graggga")
	t.eq([cmp.equal, cmp.first_diff, cmp.marks.size()], [false, 3, 7], "compare")
	var st := {"tokens": [], "start": "empty"}
	var f1 := ScReader.adaptive_feed(st, [{"raw": "g"}])
	var f2 := ScReader.adaptive_feed(f1.state, [{"b": "0"}, {"raw": "r"}])
	t.eq(f2.text, "gr", "adaptive_feed")
	t.eq(f2.show, "[2,5]([1,3](nng[0,1] r[1,2]) g[1,4])", "miniboom")
	var rc := ScReader.read_chain([{"p": 1, "c": "ngen eool"}, {"nums": [1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9],
		"list": LIST61}], ["bwt", "mtf"], [{}, {}])
	t.eq(rc.text, "geen loon", "keten 6-1")
	var rc2 := ScReader.read_chain([{"p": 1, "c": "ngen eool"}, {"nums": [1, 1, 8, 7, 6, 2, 3, 2, 8, 0, 9],
		"list": LIST61}], ["bwt", "mtf"], [{}, {}])
	t.ok(str(rc2.text) != "geen loon", "keten met afwijking leest anders: " + str(rc2.text))
