extends RefCounted
## T39–T42: eigenschappen over duizenden willekeurige invoeren (GDD §9), plus roundtrips via de werktuigen.

const H := preload("res://games/scriptorium/tests/suites/sc_helpers.gd")
const V := ScCodes.Verdict

var rng := RandomNumberGenerator.new()


func run(t) -> void:
	rng.seed = 20261014
	_t39(t)
	_t40(t)
	_t41(t)
	_t42(t)
	_tools_roundtrip(t)


func _rand_text(alpha: String, lo: int, hi: int) -> String:
	var n := rng.randi_range(lo, hi)
	var s := ""
	for i in n:
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s


func _t39(t) -> void:
	t.section("T39 adaptieve Huffman: 2000 teksten")
	var bad_rt := 0
	var bad_sib := 0
	var bad_l23 := 0
	var bad_bits := 0
	for q in 2000:
		var s := _rand_text("abcde", 1, 20)
		var tr := ScReference.adaptive_empty()
		var tokens: Array = []
		for ch in s:
			var leaf := tr.leaf_of(ch)
			var d0 := tr.depth(leaf if leaf >= 0 else tr.nng)
			if leaf >= 0:
				tokens.append({"b": tr.code(leaf)})
			else:
				if tr.code(tr.nng) != "":
					tokens.append({"b": tr.code(tr.nng)})
				tokens.append({"raw": ch})
			var steps := ScReference.adaptive_update(tr, ch)
			var climbs := 0
			for st in steps:
				if str(st.kind) in ["swap", "keep", "keep_parent"]:
					climbs += 1
			if climbs > d0:
				bad_l23 += 1
			if not tr.sibling_violations().is_empty():
				bad_sib += 1
		var enc := ScReference.adaptive_encode(s)
		if ScReference.tokens_to_string(enc.tokens) != ScReference.tokens_to_string(tokens):
			bad_bits += 1
		var dec := ScReference.adaptive_decode(enc.tokens)
		if str(dec.text) != s or bool(dec.stuck):
			bad_rt += 1
	t.eq(bad_rt, 0, "decode ∘ encode = identiteit")
	t.eq(bad_sib, 0, "Lemma 22 (a)(b)(c) na elk teken")
	t.eq(bad_l23, 0, "klimstappen ≤ diepte vóór de update (Lemma 23)")
	t.eq(bad_bits, 0, "encode = schrijven met de boom vóór de wijziging")
	# zender- en ontvangerboom identiek na elke stap (werktuigen, orakel)
	var diff := 0
	var reads := 0
	for q in 200:
		var s2 := _rand_text("abcd", 1, 14)
		var snd := H.mk({"tool": "living_tree", "side": "send", "text": s2}) as ScLivingTree
		var rcv := H.mk({"tool": "living_tree", "side": "receive",
			"tokens": ScReference.adaptive_encode(s2).tokens, "expect": s2}) as ScLivingTree
		var g := 0
		while not snd.is_done() and g < 1000:
			g += 1
			snd.apply(snd.correct_move())
			if snd.phase == ScCodes.Phase.WRITE or snd.is_done():
				while not rcv.is_done() and (rcv.copy().length() < snd.i or rcv.phase == ScCodes.Phase.CLIMB):
					rcv.apply(rcv.correct_move())
				if rcv.tree.show() != snd.tree.show() or str(snd.overkant().show) != snd.tree.show():
					diff += 1
		if rcv.copy() != s2 or H.read_of(snd) != s2:
			reads += 1
	t.eq(diff, 0, "zender-, ontvanger- en Overkantboom identiek na elk teken")
	t.eq(reads, 0, "werktuigen: kopie en voorlezing juist")


func _t40(t) -> void:
	t.section("T40 Huffman: 500 gewichtsrijen")
	var bad_runs := 0
	var bad_canon := 0
	var bad_tool := 0
	for q in 500:
		var k := rng.randi_range(2, 7)
		var row: Array = []
		for i in k:
			row.append([char(97 + i), rng.randi_range(1, 6)])
		var opt := ScReference.huffman_cost(row)
		if k <= 6:
			var r := ScReference.huffman_runs(row)
			if r.costs != [opt]:
				bad_runs += 1
		else:
			for w in 30:
				if _random_run(row) != opt:
					bad_runs += 1
		var h := ScReference.huffman(row)
		if int(h.cost) != opt:
			bad_canon += 1
		var bd := H.mk({"tool": "bindery", "mode": "row", "weights": row}) as ScBindery
		var bad := [0]
		H.play(bd, bad, false)
		if int(bd.counters.twine) != opt or bad[0] != 0:
			bad_tool += 1
		var sh := H.mk({"tool": "bindery", "mode": "shelves", "weights": row}) as ScBindery
		H.play(sh, bad, false)
		if int(sh.counters.twine) != opt or bad[0] != 0:
			bad_tool += 1
	t.eq(bad_runs, 0, "elke geldige keuzereeks heeft kost huffman_cost")
	t.eq(bad_canon, 0, "de twee-plankenregel is optimaal")
	t.eq(bad_tool, 0, "binderij (rij en planken) met het orakel: touw = optimum")


func _random_run(row: Array) -> int:
	var ws: Array = []
	for x in row:
		ws.append(int(x[1]))
	var cost := 0
	while ws.size() > 1:
		var vp := ScReference.valid_pairs(ws)
		var p: Array = vp[rng.randi_range(0, vp.size() - 1)]
		var z: int = ws[p[0]] + ws[p[1]]
		cost += z
		ws[p[0]] = z
		ws.remove_at(p[1])
	return cost


func _rand_model(alpha: String) -> Array:
	var k := alpha.length()
	var parts: Array = []
	for i in k:
		parts.append(1)
	for i in 10 - k:
		parts[rng.randi_range(0, k - 1)] += 1
	var m: Array = []
	for i in k:
		m.append([alpha[i], "0." + str(parts[i]) if parts[i] < 10 else "1"])
	return m


func _t41(t) -> void:
	t.section("T41 roundtrips: 2000 teksten")
	var bad := {"lz77": 0, "lzw": 0, "bwt": 0, "mtf": 0, "arith": 0}
	for q in 2000:
		var s := _rand_text("ab c" if q % 2 == 0 else "aab", 1, 24)
		var G: int = [1, 2, 3, 4, 5, 6, 7, 8, -1][q % 9]
		if ScReference.lz77_decode(ScReference.lz77_encode(s, G).triples, G) != s:
			bad.lz77 += 1
		if str(ScReference.lzw_decode(ScReference.lzw_encode(s).codes).text) != s:
			bad.lzw += 1
		var b := ScReference.bwt(s)
		if str(ScReference.inverse_bwt(int(b.p), str(b.c)).text) != s:
			bad.bwt += 1
		var lst: Array = []
		for ch in " abc":
			lst.append(ch)
		if str(ScReference.mtf_decode(ScReference.mtf_encode(s, lst).nums, lst).text) != s:
			bad.mtf += 1
		if q % 4 == 0:
			var s2 := _rand_text("xyz", 1, 12)
			var m := _rand_model("xyz")
			var iv := ScReference.get_interval(s2, m)
			var bits := str(ScReference.get_bitstring(iv.low, iv.up).bits)
			var v := ScDec.from_bits(bits)
			if str(ScReference.arith_decode(bits, s2.length(), m).text) != s2 or v.lt(iv.low) or v.ge(iv.up):
				bad.arith += 1
	# herhalingen (Fig. 26): tekst = blok herhaald
	var rep := 0
	for q in 200:
		var blk := _rand_text("ab", 1, 4)
		var s3 := blk.repeat(rng.randi_range(2, 4))
		var b3 := ScReference.bwt(s3)
		if str(ScReference.inverse_bwt(int(b3.p), str(b3.c)).text) != s3:
			rep += 1
	for k in bad:
		t.eq(bad[k], 0, k + " roundtrip")
	t.eq(rep, 0, "BWT met herhalingen")


func _t42(t) -> void:
	t.section("T42 Algoritme 13 is minimaal (Oef. 92)")
	var bad_min := 0
	var bad_in := 0
	var n := 0
	for q in 500:
		var s := _rand_text("xyz", 1, 8)
		var m := _rand_model("xyz")
		var iv := ScReference.get_interval(s, m)
		var low: ScDec = iv.low
		var up: ScDec = iv.up
		var bits := str(ScReference.get_bitstring(low, up).bits)
		var v := ScDec.from_bits(bits)
		if v.lt(low) or v.ge(up):
			bad_in += 1
		if low.is_zero():
			continue
		n += 1
		for l in range(1, bits.length()):
			# de kleinste waarde j/2^l ≥ low
			var scaled := low.mul(ScDec.from_int(1 << l)).to_full_string()
			var parts := scaled.split(".")
			var j := int(parts[0]) + (1 if parts.size() > 1 else 0)
			if ScDec.dyadic(j, l).lt(up):
				bad_min += 1
				break
	t.eq(bad_in, 0, "de bitstring ligt in [low, up)")
	t.eq(bad_min, 0, "geen kortere bitstring (%d intervallen)" % n)
	t.ok(n > 300, "genoeg intervallen met low > 0")


func _tools_roundtrip(t) -> void:
	t.section("werktuigen: zenden → Letterlijk, ontvangen ← referentie")
	var bad := {"window": 0, "stampcase": 0, "drum+shelf": 0, "ruler": 0, "bindery": 0}
	for q in 150:
		var s := _rand_text("ab_n", 2, 16)
		var G: int = [3, 6, 8, -1][q % 4]
		var w := H.mk({"tool": "window", "side": "send", "text": s, "G": G})
		w.auto_finish()
		var wr := H.mk({"tool": "window", "side": "receive", "triples": ScReference.lz77_encode(s, G).triples, "G": G})
		wr.auto_finish()
		if H.read_of(w) != s or wr.copy() != s or (w as ScWindow).triples != ScReference.lz77_encode(s, G).triples:
			bad.window += 1
		var sc := H.mk({"tool": "stampcase", "side": "send", "text": s})
		sc.auto_finish()
		var sr := H.mk({"tool": "stampcase", "side": "receive", "codes": ScReference.lzw_encode(s).codes})
		sr.auto_finish()
		if H.read_of(sc) != s or sr.copy() != s:
			bad.stampcase += 1
		var d := H.mk({"tool": "drum", "side": "send", "text": s})
		d.auto_finish()
		var lst: Array = [" ", "_", "a", "b", "n"]
		for c in "0123456789":
			lst.append(c)
		var sh := H.mk({"tool": "shelf", "side": "send", "input": "carry", "list": lst}, d.output())
		sh.auto_finish()
		var rc := ScReader.read_chain([d.output(), sh.output()], ["bwt", "mtf"], [{}, {}])
		var b := ScReference.bwt(s)
		var dr := H.mk({"tool": "drum", "side": "receive", "p": b.p, "c": b.c})
		dr.auto_finish()
		if str(rc.text) != s or dr.copy() != s:
			bad["drum+shelf"] += 1
		var s2 := _rand_text("xyz", 1, 10)
		var m := _rand_model("xyz")
		var ru := H.mk({"tool": "ruler", "side": "send", "text": s2, "model": m})
		ru.auto_finish()
		var bits := str(ru.output().bits)
		var rr := H.mk({"tool": "ruler", "side": "receive", "bits": bits, "n": s2.length(), "model": m})
		rr.auto_finish()
		if H.read_of(ru) != s2 or rr.copy() != s2:
			bad.ruler += 1
		var bd := H.mk({"tool": "bindery", "mode": "row", "text": s})
		bd.auto_finish()
		if H.read_of(bd) != s:
			bad.bindery += 1
	for k in bad:
		t.eq(bad[k], 0, k)
