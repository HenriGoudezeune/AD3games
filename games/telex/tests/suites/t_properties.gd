extends RefCounted
## Property-tests: machines tegen de referentie, referentie tegen de definities, robuustheid na fouten.

const H := preload("res://games/telex/tests/suites/tx_helpers.gd")
const R := preload("res://games/telex/scripts/core/tx_reference.gd")
const VD := TxCodes.Verdict

var rng := RandomNumberGenerator.new()


func _w(alpha: String, lo: int, hi: int) -> String:
	var s := ""
	for _i in rng.randi_range(lo, hi):
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s


## Recursieve definitie van de editeerafstand (enkel voor korte strings).
func _rec(a: String, b: String, memo: Dictionary) -> int:
	var key := a + "|" + b
	if memo.has(key):
		return memo[key]
	var r: int
	if a == "":
		r = b.length()
	elif b == "":
		r = a.length()
	else:
		var c := 0 if a[a.length() - 1] == b[b.length() - 1] else 1
		r = mini(_rec(a.left(-1), b.left(-1), memo) + c, mini(_rec(a.left(-1), b, memo) + 1, _rec(a, b.left(-1), memo) + 1))
	memo[key] = r
	return r


func run(t) -> void:
	rng.seed = 2026

	t.section("P1 machines vinden exact de naïeve treffers; tikken = pseudocode (600 willekeurige z/t)")
	var bad := {"brute": 0, "kmp": 0, "kmp_strip": 0, "kmp_first": 0, "bmh": 0, "sa": 0, "inv": 0}
	for _r in 600:
		var alpha := "ab" if rng.randf() < 0.6 else "abc"
		var z := _w(alpha, 1, 5)
		var tx := _w(alpha, z.length(), 24)
		var naive := R.occurrences(z, tx)
		var b := H.mk({"machine": "brute", "z": z, "t": tx, "find": "all"})
		var pb := [0]
		H.play(b, pb, false)
		var rb := R.brute(z, tx, true)
		if H.hit_starts(b) != naive or int(b.counters.ticks) != int(rb.cmp) or int(b.counters.rewind) != int(rb.rewind) \
				or not b.missed.is_empty():
			bad.brute += 1
		var k := H.mk({"machine": "kmp", "z": z, "t": tx, "find": "all", "strip": "none", "auto_zero": true})
		H.play(k, pb, false)
		var rk := R.kmp(z, tx, R.v_def(z), true)
		if H.hit_starts(k) != naive or int(k.counters.ticks) != int(rk.cmp) or int(k.counters.alignments) != int(rk.alignments):
			bad.kmp += 1
		var ks := H.mk({"machine": "kmp", "z": z, "t": tx, "find": "all", "strip": R.v_def(z), "auto_zero": true,
			"auto_strip": true})
		H.play(ks, pb, false)
		if H.hit_starts(ks) != naive or int(ks.counters.ticks) != int(rk.cmp):
			bad.kmp_strip += 1
		var kf := H.mk({"machine": "kmp", "z": z, "t": tx, "find": "first", "strip": "none", "auto_zero": true})
		H.play(kf, pb, false)
		var rkf := R.kmp(z, tx, R.v_def(z), false)
		if H.hit_starts(kf) != Array(rkf.hits) or int(kf.counters.ticks) != int(rkf.cmp):
			bad.kmp_first += 1
		var bm := H.mk({"machine": "bmh", "z": z, "t": tx, "find": "all", "cards": "prefilled"})
		H.play(bm, pb, false)
		var rbm := R.bmh(z, tx, true)
		if H.hit_starts(bm) != naive or int(bm.counters.ticks) != int(rbm.cmp):
			bad.bmh += 1
		var sa := H.mk({"machine": "shift_and", "z": z, "t": tx, "k": 0, "cards": "prefilled", "find": "all"})
		H.play(sa, pb, false)
		if H.hit_starts(sa) != naive or int(sa.counters.lamps) != tx.length():
			bad.sa += 1
		bad.inv += int(pb[0])
	t.eq(bad, {"brute": 0, "kmp": 0, "kmp_strip": 0, "kmp_first": 0, "bmh": 0, "sa": 0, "inv": 0}, "alle matchers")

	t.section("P2 Vingerafdruk = Algoritme 3 (300 willekeurige bitstrings)")
	var bad_rk := 0
	for _r in 300:
		var z := _w("01", 2, 6)
		var tx := _w("01", z.length(), 22)
		var q: int = [5, 7, 11, 13][rng.randi_range(0, 3)]
		var fa := rng.randf() < 0.5
		var mc := H.mk({"machine": "rk", "z": z, "q": q, "t": tx, "find": "all" if fa else "first",
			"prep": ["w", "hz", "h0"]}) as TxRabinKarp
		var pb2 := [0]
		H.play(mc, pb2, false)
		var ref := R.rk(z, tx, q, fa)
		var hs: Array = []
		for h in mc.history():
			hs.append(int(h.wheel))
		if H.hit_starts(mc) != Array(ref.hits) or int(mc.counters.ticks) != int(ref.cmp) \
				or int(mc.counters.wheel) != int(ref.wheel_ops) or hs != Array(ref.hs) or pb2[0] != 0:
			bad_rk += 1
	t.eq(bad_rk, 0, "treffers, tikken, wielslagen en vensterwaarden")

	t.section("P3 spiegelrit = Algoritme 5 = Definitie 11 (1000 willekeurige woorden + alle levelwoorden)")
	var words: Array = ["barbados", "volvoert", "ananas", "tata", "kokos", "ekster", "vuurtoren", "zoek_me"]
	for _r in 1000:
		words.append(_w("ab" if rng.randf() < 0.5 else "abc", 2, 12))
	var bad5 := 0
	var bad11 := 0
	for z in words:
		var a5 := H.mk({"machine": "kmp_table", "z": z, "method": "alg5", "cells": "m"}) as TxKmpTable
		var pb3 := [0]
		H.play(a5, pb3, false)
		var bv := R.bereken_v(z)
		var vd := R.v_def(z, true)
		var tick_sum := 0
		for st in bv.steps:
			tick_sum += int(st.cmp)
		if a5.strip.slice(0, z.length()) != vd.slice(0, z.length()) or a5.strip.slice(0, z.length()) != bv.v.slice(0, z.length()) \
				or a5.strip[z.length()] != vd[z.length()] or int(a5.counters.ticks) != tick_sum or pb3[0] != 0:
			bad5 += 1
		var d11 := H.mk({"machine": "kmp_table", "z": z, "method": "def11", "cells": "m"}) as TxKmpTable
		H.play(d11, pb3, false)
		if d11.strip != vd:
			bad11 += 1
	t.eq([bad5, bad11], [0, 0], "geponste strook na een foutloze rit == Alg. 5 == Def. 11 (%d woorden)" % words.size())

	t.section("P4 Definitie 11: V[j] is de kleinste passende verschuiving")
	var bad_v := 0
	for _r in 500:
		var z := _w("abc", 1, 10)
		var v := R.v_def(z, true)
		for j in range(1, z.length() + 1):
			if not R.mesh(z, j, v[j]):
				bad_v += 1
			for s in range(1, v[j]):
				if R.mesh(z, j, s):
					bad_v += 1
	t.eq(bad_v, 0, "mesh(V[j]) en geen kleinere")

	t.section("P5 shift-AND / M^k == Definitie 13/14 (cel per cel), machine == referentie")
	var bad_mk := 0
	var bad_mm := 0
	for _r in 300:
		var z := _w("abc", 1, 5)
		var tx := _w("abc", 1, 16)
		var kk := rng.randi_range(0, 2)
		var ref := R.shift_and_k(z, tx, kk)
		for j in tx.length():
			for l in kk + 1:
				for i in z.length():
					if int(ref.cols[j][l][i]) != R.mk_def(z, tx, l, i, j):
						bad_mk += 1
		var cols: Array = []
		var mc := H.mk({"machine": "shift_and", "z": z, "t": tx, "k": kk, "cards": "prefilled", "wiring": "prefilled",
			"find": "all"})
		mc.changed.connect(func(fx: Dictionary) -> void: if str(fx.fx) == "column": cols.append(fx.cols))
		H.play(mc, [0], false)
		H.unhook(mc)
		if cols.size() != tx.length():
			bad_mm += 1
		else:
			for j in tx.length():
				for l in kk + 1:
					if Array(cols[j][l]) != Array(ref.cols[j][l]):
						bad_mm += 1
		var ends: Array = []
		for h in mc.hits:
			if int(h.level) == kk and bool(h.real):
				ends.append(int(h.end))
		if ends != Array(ref.ends_by_level[kk]):
			bad_mm += 1
	t.eq([bad_mk, bad_mm], [0, 0], "M^k cellen = Definitie 14; machinekolommen = referentie")

	t.section("P6 editeerafstand: DP == recursieve definitie; terugloop = geldige reeks van d bewerkingen")
	var bad_e := [0, 0, 0, 0]
	var memo := {}
	for _r in 400:
		var a := _w("abc", 0, 5)
		var b := _w("abc", 0, 5)
		var d := R.edit_table(a, b)
		if int(d[a.length()][b.length()]) != _rec(a, b, memo):
			bad_e[0] += 1
		for ops in R.distinct_sequences(a, b):
			if ops.size() != int(d[a.length()][b.length()]) or R.apply_ops(a, ops) != b:
				bad_e[1] += 1
			var prev := -1
			for o in ops:
				if int(o.pos) < prev:
					bad_e[1] += 1
				prev = int(o.pos)
		if a != "" and b != "":
			var z := a
			var tx := b + _w("abc", 0, 6)
			var dd := R.approx_table(z, tx)
			for j in tx.length() + 1:
				var best := 1 << 20
				for l in j + 1:
					best = mini(best, R.edit_distance(z, tx.substr(l, j - l)))
				if int(dd[z.length()][j]) != best:
					bad_e[2] += 1
			for mm in R.approx_matches(z, tx):
				var piece := tx.substr(int(mm.start), int(mm.end_col) - int(mm.start))
				if R.apply_ops(z, mm.ops) != piece or (mm.ops as Array).size() != int(R.approx_best(z, tx).best):
					bad_e[3] += 1
	t.eq(bad_e, [0, 0, 0, 0], "d == recursie; reeksen geldig (stijgend, lengte d); D == min over l; matches geldig")

	t.section("P7 schakelbord-machine == referentie (willekeurig, alle reeksen)")
	var bad_b := [0, 0, 0]
	for _r in 120:
		var a := _w("abc", 1, 5)
		var b := _w("abc", 1, 5)
		var mc := H.mk({"machine": "edit", "a": a, "b": b, "approx": false, "want": -1}) as TxEditBoard
		var pb4 := [0]
		H.play(mc, pb4, false)
		if mc.tab != R.edit_table(a, b) or pb4[0] != 0:
			bad_b[0] += 1
		if mc.distinct_sequences().size() != R.distinct_sequences(a, b).size():
			bad_b[1] += 1
		var z := a
		var tx := b + _w("abc", 0, 4)
		var ma := H.mk({"machine": "edit", "a": z, "b": tx, "approx": true, "want": -1}) as TxEditBoard
		H.play(ma, pb4, false)
		var want := {}
		for mm in R.approx_matches(z, tx):
			want["%d:%d" % [int(mm.start), int(mm.end_col) - 1]] = true
		var got := {}
		for mm in ma.matches_found():
			got["%d:%d" % [int(mm.start), int(mm.end)]] = true
		if got.keys().size() != want.keys().size() or pb4[0] != 0:
			bad_b[2] += 1
	t.eq(bad_b, [0, 0, 0], "tabel, aantal reeksen, alle beste matches")

	t.section("P8 robuustheid: willekeurige fouten breken nooit de invarianten en snapshot blijft identiek")
	var bad_r := [0, 0, 0]
	var stages := [{"machine": "kmp", "z": "abab", "t": "abababbababaab", "find": "all", "strip": "none", "auto_zero": true},
		{"machine": "kmp_table", "z": "abaabab", "method": "alg5", "cells": "m"},
		{"machine": "kmp_table", "z": "abcabd", "method": "def11", "cells": "m"},
		{"machine": "bmh", "z": "abcab", "t": "cabcabcababcab", "find": "all", "cards": "stamp"},
		{"machine": "rk", "z": "101", "q": 5, "t": "1101011101", "find": "all", "prep": ["w", "hz", "h0"]},
		{"machine": "shift_and", "z": "aba", "t": "abaababa", "k": 1, "cards": "punch", "wiring": "plug",
			"find": "all"},
		{"machine": "edit", "a": "abca", "b": "bcab", "approx": false, "want": -1},
		{"machine": "edit", "a": "abc", "b": "cabcba", "approx": true, "want": -1}]
	for st in stages:
		for sd in 25:
			rng.seed = 77 + sd
			var mc := H.mk(st)
			var g := 0
			while not mc.is_done() and g < 3000:
				g += 1
				var mv := mc.correct_move()
				var roll := rng.randf()
				if roll < 0.25 and not mc.wrong_moves().is_empty():
					var w := mc.wrong_moves()
					mv = w[rng.randi_range(0, w.size() - 1)]
				elif roll < 0.35 and not mc.impossible_moves().is_empty():
					var im := mc.impossible_moves()
					mv = im[rng.randi_range(0, im.size() - 1)]
				if str(mv.get("act", "none")) == "none":
					break
				mc.apply(mv)
				if not mc.invariants().is_empty():
					bad_r[0] += 1
					break
				if not H.snap_roundtrip(mc):
					bad_r[1] += 1
					break
			if not mc.is_done():
				bad_r[2] += 1
	t.eq(bad_r, [0, 0, 0], "invarianten, snapshot, stage eindigt (8 machines × 25 seeds)")
