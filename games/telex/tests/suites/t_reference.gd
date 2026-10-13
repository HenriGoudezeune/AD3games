extends RefCounted
## T01–T24: TxReference tegen de notas en de oefeningen (GDD §9).

const R := preload("res://games/telex/scripts/core/tx_reference.gd")


func _bits(s: String) -> Array[int]:
	var out: Array[int] = []
	for c in s:
		out.append(int(c))
	return out


func _col_str(col: Array) -> String:
	var s := ""
	for b in col:
		s += str(int(b))
	return s


func _cols_str(cols: Array) -> Array:
	var out: Array = []
	for c in cols:
		out.append(_col_str(c))
	return out


func _em_seq(trace: Array) -> Array:
	var out: Array = []
	for x in trace:
		out.append(int(x.em))
	return out


func _triples(trace: Array) -> Array:
	var out: Array = []
	for x in trace:
		out.append([int(x.start), int(x.gel), int(x.em)])
	return out


func _table_rows(rows: PackedStringArray) -> Array:
	var out: Array = []
	for r in rows:
		var row: Array = []
		for p in r.split(" ", false):
			row.append(int(p))
		out.append(row)
	return out


func run(t) -> void:
	t.section("T01 V[] barbados (p. 56)")
	t.eq(R.v_def("barbados", false), [1, 1, 2, 3, 3, 3, 6, 7], "V barbados")
	t.eq(R.v_def("barbados", true)[8], 8, "V[8] uitgebreid")
	t.eq(R.v_def("zoek_me", false), [1, 1, 2, 3, 4, 5, 6], "zoek_me: V[j] = j (p. 56)")

	t.section("T02 Algoritme 5 barbados (p. 61-62)")
	var b5 := R.bereken_v("barbados")
	t.eq(b5.v.slice(0, 8), [1, 1, 2, 3, 3, 3, 6, 7], "Alg5 V")
	t.eq(int(b5.v[8]), -1, "V[8] niet ingevuld")
	var want_steps := [[1, 0, 0, [[2, 2]], 1], [2, 0, 0, [[3, 3]], 1], [3, 0, 2, [[4, 3], [5, 3]], 2],
		[5, 0, 0, [[6, 6]], 1], [6, 0, 0, [[7, 7]], 1]]
	t.eq(b5.steps.size(), 5, "5 stappen")
	for k in mini(5, b5.steps.size()):
		var st: Dictionary = b5.steps[k]
		t.eq([int(st.start), int(st.gel), int(st.em), st.filled, int(st.shift)], want_steps[k], "stap %d" % (k + 1))

	t.section("T03 KMP barbados (p. 58-59)")
	var vb := R.v_def("barbados")
	var k3 := R.kmp("barbados", "barbaarse_barbecue_in_barbados", vb, false)
	t.eq(_em_seq(k3.trace), [5, 2, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 8], "em-reeks")
	t.eq(k3.alignments, 18, "18 uitlijningen")
	t.eq(k3.cmp, 34, "34 tikken")
	t.eq(k3.hits, [22], "treffer 22")
	var bf3 := R.brute("barbados", "barbaarse_barbecue_in_barbados", false)
	t.eq([bf3.cmp, bf3.alignments, bf3.rewind], [42, 23, 8], "brute kracht 3-1")

	t.section("T04 Alg. 5 = Def. 11")
	var bad := 0
	var bad_m := 0
	var filled_m := 0
	var total := 0
	for spec in [["ab", 2, 9], ["abc", 2, 6]]:
		var alpha: String = spec[0]
		for L in range(int(spec[1]), int(spec[2]) + 1):
			for z in _all_words(alpha, L):
				total += 1
				var a5 := R.bereken_v(z)
				var vd := R.v_def(z, true)
				if a5.v.slice(0, L) != vd.slice(0, L):
					bad += 1
				if int(a5.v[L]) != -1:
					filled_m += 1
					if int(a5.v[L]) != vd[L]:
						bad_m += 1
	t.eq(bad, 0, "Alg5 == Def11 (%d woorden)" % total)
	t.eq(bad_m, 0, "V[m] door Alg5 == Def11 uitgebreid (%d keer ingevuld)" % filled_m)
	t.ok(filled_m > 0, "Alg5 vult V[m] soms zelf in")
	t.ok(total == 1020 + 9 + 27 + 81 + 243 + 729, "aantal woorden %d" % total)

	t.section("T05 ALL-matchers = brute kracht (20 000 paren)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var bad5 := [0, 0, 0, 0]
	for _r in 20000:
		var z := _rand_word(rng, "ab", rng.randi_range(2, 5))
		var tt := _rand_word(rng, "ab", rng.randi_range(z.length(), 15))
		var bf := R.brute(z, tt, true)
		if R.kmp(z, tt, R.v_def(z), true).hits != bf.hits:
			bad5[0] += 1
		if R.bmh(z, tt, true).hits != bf.hits:
			bad5[1] += 1
		if R.shift_and(z, tt).hits != bf.hits:
			bad5[2] += 1
		if R.occurrences(z, tt) != bf.hits:
			bad5[3] += 1
	t.eq(bad5, [0, 0, 0, 0], "KMP/BMH/shift-AND/naïef == brute kracht")

	t.section("T06 Oef. 39 volvoert")
	t.eq(R.v_def("volvoert", false), [1, 1, 2, 3, 3, 3, 6, 7], "V volvoert")
	var v39 := R.bereken_v("volvoert")
	var shape: Array = []
	for st in v39.steps:
		shape.append([int(st.start), int(st.gel), int(st.em), st.filled, int(st.shift)])
	t.eq(shape, want_steps, "Alg5-stappen = barbados-vorm")
	var k6 := R.kmp("volvoert", "volvo_vol_vogels_volvoert_kunststukje", R.v_def("volvoert"), false)
	var want6 := [[0, 0, 5], [3, 2, 2], [5, 0, 0], [6, 0, 3], [9, 0, 0], [10, 0, 2], [12, 0, 0], [13, 0, 0],
		[14, 0, 0], [15, 0, 0], [16, 0, 0], [17, 0, 8]]
	t.eq(_triples(k6.trace), want6, "KMP-spoor Oef. 39")
	t.eq([k6.cmp, k6.hits], [29, [17]], "29 tikken, treffer 17")
	var bf6 := R.brute("volvoert", "volvo_vol_vogels_volvoert_kunststukje", false)
	t.eq([bf6.cmp, bf6.rewind], [37, 8], "brute kracht 37, spoelmeter 8")

	t.section("T07 Oef. 40 ananas")
	t.eq(R.v_def("ananas", false), [1, 1, 2, 2, 2, 2], "V ananas")
	var a40 := R.bereken_v("ananas")
	var sh40: Array = []
	for st in a40.steps:
		sh40.append([int(st.start), int(st.gel), int(st.em), st.filled, int(st.shift)])
	t.eq(sh40, [[1, 0, 0, [[2, 2]], 1], [2, 0, 3, [[3, 2], [4, 2], [5, 2]], 2]], "Alg5 ananas")
	var k7 := R.kmp("ananas", "bananen_in_ra'ananas'_centrum", R.v_def("ananas"), false)
	t.eq(_em_seq(k7.trace), [0, 4, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 6], "em-reeks Oef. 40")
	t.eq([k7.cmp, k7.hits], [23, [14]], "23 tikken, treffer 14")
	t.eq(R.brute("ananas", "bananen_in_ra'ananas'_centrum", false).cmp, 27, "brute kracht 27")

	t.section("T08 V_H barbara (p. 65)")
	t.eq(R.vul_vh("barbara"), {"a": 2, "b": 3, "r": 1}, "V_H barbara")
	t.eq(R.vh_of(R.vul_vh("barbara"), "x", 7), 7, "andere = 7")
	var b8 := R.bmh("barbara", "barbados_zoekt_barbara", false)
	var is8: Array = []
	var sh8: Array = []
	for x in b8.trace:
		is8.append(int(x.i))
		sh8.append(int(x.shift))
	t.eq(is8, [6, 13, 20, 21], "i = 6, 13, 20, 21")
	t.eq(sh8.slice(0, 3), [7, 7, 1], "sprongen 7, 7, 1")
	t.eq([b8.cmp, b8.hits], [10, [15]], "10 tikken, treffer 15")

	t.section("T09 Oef. 48")
	t.eq(R.vul_vh("ananas"), {"a": 1, "n": 2}, "V_H ananas")
	t.eq(R.vh_of(R.vul_vh("ananas"), "s", 6), 6, "s = 6")
	var b9 := R.bmh("ananas", "de_spa_in_ra'ananas'", false)
	var is9: Array = []
	for x in b9.trace:
		is9.append(int(x.i))
	t.eq(is9, [5, 6, 12, 18], "i = 5, 6, 12, 18")
	t.eq([b9.cmp, b9.hits], [9, [13]], "9 tikken, treffer 13")

	t.section("T10 Figuur 23")
	var c10 := R.c_vectors("ana")
	t.eq([_col_str(c10.a), _col_str(c10.n)], ["101", "010"], "C_a, C_n")
	var s10 := R.shift_and("ana", "ananas")
	t.eq(_cols_str(s10.cols), ["100", "010", "101", "010", "101", "000"], "kolommen")
	t.eq(s10.ends, [2, 4], "eindes 2 en 4")
	t.eq(s10.hits, [0, 2], "begin 0 en 2")

	t.section("T11 Oef. 54")
	var c11 := R.c_vectors("zoeken")
	t.eq([_col_str(c11.e), _col_str(c11.k), _col_str(c11.n), _col_str(c11.o), _col_str(c11.z)],
		["001010", "000100", "000001", "010000", "100000"], "C_x zoeken")
	var s11 := R.shift_and("zoeken", "iets_zoets_zoeken")
	t.eq(_cols_str(s11.cols), ["000000", "000000", "000000", "000000", "000000", "100000", "010000", "001000",
		"000000", "000000", "000000", "100000", "010000", "001000", "000100", "000010", "000001"], "kolommen")
	t.eq([s11.ends, s11.hits], [[16], [11]], "einde 16, begin 11")

	t.section("T12 Oef. 60 (Definitie 14)")
	var s12 := R.shift_and_k("dank", "een_dansfeest", 1)
	t.eq(s12.ends_by_level[0], [], "M0 nooit onderaan")
	t.eq(s12.ends_by_level[1], [7], "M1 enkel op 7")
	var want12 := [["0000", "1000"], ["0000", "1000"], ["0000", "1000"], ["0000", "1000"], ["1000", "1000"],
		["0100", "1100"], ["0010", "1010"], ["0000", "1001"], ["0000", "1000"], ["0000", "1000"], ["0000", "1000"],
		["0000", "1000"], ["0000", "1000"]]
	var got12: Array = []
	for j in s12.cols.size():
		got12.append([_col_str(s12.cols[j][0]), _col_str(s12.cols[j][1])])
	t.eq(got12, want12, "kolommen M0/M1")
	t.eq(R.shift_and_k("dank", "een_dansfeest", 1, "old").ends_by_level[1], [], "stekker old: geen einde")
	t.eq(R.shift_and_k("dank", "een_dansfeest", 1, "new_shift").ends_by_level[1], [6], "stekker new_shift: einde 6")
	t.eq(R.shift_and_k("dank", "een_dansfeest", 1, "new").ends_by_level[1], [], "stekker new: geen einde")
	var bad12 := 0
	var tt12 := "een_dansfeest"
	for j in tt12.length():
		for l in 2:
			for i in 4:
				if int(s12.cols[j][l][i]) != R.mk_def("dank", tt12, l, i, j):
					bad12 += 1
	t.eq(bad12, 0, "elke cel = Definitie 14")

	t.section("T13 zender")
	var s13 := R.shift_and_k("zender", "zonder_zender_zander_zinder", 1)
	t.eq(s13.ends_by_level[0], [12], "M0 einde 12")
	t.eq(s13.ends_by_level[1], [5, 12, 19, 26], "M1 eindes 5, 12, 19, 26")
	var c13 := R.c_vectors("zender")
	t.eq([_col_str(c13.d), _col_str(c13.e), _col_str(c13.n), _col_str(c13.r), _col_str(c13.z)],
		["000100", "010010", "001000", "000001", "100000"], "C_x zender")

	t.section("T14 Oef. 34 Rabin-Karp")
	var r14 := R.rk("00101", "1101110010001010", 13, false)
	t.eq([r14.hz, r14.w], [5, 6], "hz 5, w 6")
	t.eq(r14.hs, [1, 10, 1, 2, 12, 5, 4, 8, 4, 2, 5], "hs")
	t.eq(r14.calls, [{"i": 5, "equal": false, "cmp": 1}, {"i": 10, "equal": true, "cmp": 5}], "controles")
	t.eq([r14.cmp, r14.wheel_ops, r14.hits], [6, 41, [10]], "6 tikken, 41 wielslagen, treffer 10")
	t.eq(R.brute("00101", "1101110010001010", false).cmp, 23, "brute kracht 23")
	t.eq(R.horner_prefixes("00101", 13), [0, 0, 1, 2, 5], "Horner z")
	t.eq(R.horner_prefixes("11011", 13), [1, 3, 6, 0, 1], "Horner venster 0")

	t.section("T15 2-2")
	var r15 := R.rk("1011", "1010010110110100", 7, true)
	t.eq([r15.hz, r15.w], [4, 2], "hz 4, w 2")
	t.eq(r15.hs, [3, 4, 2, 2, 5, 4, 6, 6, 4, 6, 6, 3, 4], "hs")
	var c15: Array = []
	for c in r15.calls:
		c15.append([int(c.i), bool(c.equal)])
	t.eq(c15, [[1, false], [5, true], [8, true], [12, false]], "controles")
	t.eq([r15.cmp, r15.wheel_ops, r15.wheel_ops - 4 - 7], [10, 42, 31], "10 tikken, 42 (31) wielslagen")
	t.eq(R.brute("1011", "1010010110110100", true).cmp, 29, "brute kracht ALL 29")
	t.eq([R.weight(4, 7), R.h("1011", 7)], [2, 4], "2-1 w en h(z)")
	t.eq([R.horner_prefixes("0100", 7), R.horner_prefixes("1011", 7), R.horner_prefixes("1110", 7)],
		[[0, 1, 2, 4], [1, 2, 5, 4], [1, 3, 0, 0]], "2-1 signalen")

	t.section("T16 Oef. 34b")
	var best16 := -1
	var arg16: Array = []
	for x in 65536:
		var s := ""
		for b in 16:
			s += "1" if (x >> (15 - b)) & 1 else "0"
		var calls: int = R.rk("00101", s, 13, false).calls.size()
		if calls > best16:
			best16 = calls
			arg16 = [s]
		elif calls == best16:
			arg16.append(s)
	t.eq([best16, arg16], [12, ["1111111111111111"]], "max 12 controles, enkel 1^16")

	t.section("T17 Oef. 32")
	for spec in [[12, 4, 36], [8, 4, 20]]:
		t.eq(_max_brute(int(spec[0]), int(spec[1])), int(spec[2]), "max brute (n=%d, m=%d)" % [spec[0], spec[1]])
	# (16, 8): exhaustief is te traag in GDScript; (n−m+1)·m is een bovengrens per constructie en wordt bereikt.
	t.eq(int(R.brute("aaaaaaab", "aaaaaaaaaaaaaaaa", false).cmp), 72, "(16, 8): aaaaaaab in a^16 = 72")
	t.eq(int(R.brute("aaaaaaab", "aaaaaaaaaaaaaaab", false).cmp), 72, "(16, 8): a^15b geeft ook 72")
	t.eq(int(R.brute("aaab", "aaaaaaaaaaaa", false).cmp), 36, "aaab in a^12 = 36")

	t.section("T18 Oef. 50")
	var mn := 1 << 30
	var mx := -1
	var amx: Array = []
	for zi in 16:
		var z := _ab_word(zi, 4)
		for ti in 65536:
			var r18 := _bmh_fast(zi, ti)
			var c18: int = r18.x
			if r18.y == 0:
				mn = mini(mn, c18)
			if c18 > mx:
				mx = c18
				amx = [[z, _ab_word(ti, 16)]]
			elif c18 == mx:
				amx.append([z, _ab_word(ti, 16)])
	# controle van de snelle variant tegen TxReference.bmh op een steekproef
	var bad18 := 0
	for k in 2000:
		var zi2 := k % 16
		var ti2 := (k * 7919) % 65536
		var rr := R.bmh(_ab_word(zi2, 4), _ab_word(ti2, 16), false)
		var ff := _bmh_fast(zi2, ti2)
		if int(rr.cmp) != ff.x or (rr.hits.is_empty()) != (ff.y == 0):
			bad18 += 1
	t.eq(bad18, 0, "snelle BMH = TxReference.bmh (steekproef)")
	t.eq(mn, 4, "minimum met z ∉ t")
	t.eq(mx, 52, "maximum")
	amx.sort()
	t.eq(amx, [["abbb", "bbbbbbbbbbbbbbbb"], ["baaa", "aaaaaaaaaaaaaaaa"]], "enkel (baaa, a^16) en (abbb, b^16)")

	t.section("T19 Algoritme 7 lessen/feesten (p. 76)")
	var d19 := R.edit_table("lessen", "feesten")
	t.eq(d19, _table_rows(["0 1 2 3 4 5 6 7", "1 1 2 3 4 5 6 7", "2 2 1 2 3 4 5 6", "3 3 2 2 2 3 4 5",
		"4 4 3 3 2 3 4 5", "5 5 4 3 3 3 3 4", "6 6 5 4 4 4 4 3"]), "tabel p. 76")
	t.eq(R.all_paths(d19, "lessen", "feesten", 6, 7, false).size(), 4, "4 optimale paden")
	var seq19 := R.distinct_sequences("lessen", "feesten")
	var want19 := [
		[["voegtoe", 0, "", "f"], ["vervang", 1, "l", "e"], ["vervang", 4, "s", "t"]],
		[["vervang", 0, "l", "f"], ["voegtoe", 1, "", "e"], ["vervang", 4, "s", "t"]],
		[["vervang", 0, "l", "f"], ["voegtoe", 2, "", "e"], ["vervang", 4, "s", "t"]],
		[["vervang", 0, "l", "f"], ["vervang", 2, "s", "e"], ["voegtoe", 4, "", "t"]]]
	t.eq(_sorted_ops(seq19), _sorted_lists(want19), "4 reeksen van §5.8")
	var bad19 := 0
	for ops in seq19:
		if R.apply_ops("lessen", ops) != "feesten" or ops.size() != 3:
			bad19 += 1
	t.eq(bad19, 0, "elke reeks geeft feesten in 3 bewerkingen")

	t.section("T20 Oef. 62 roestig/oesters")
	var d20 := R.edit_table("roestig", "oesters")
	t.eq(d20, _table_rows(["0 1 2 3 4 5 6 7", "1 1 2 3 4 5 5 6", "2 1 2 3 4 5 6 6", "3 2 1 2 3 4 5 6",
		"4 3 2 1 2 3 4 5", "5 4 3 2 1 2 3 4", "6 5 4 3 2 2 3 4", "7 6 5 4 3 3 3 4"]), "tabel")
	var want20 := [
		[["verwijder", 0, "r", ""], ["voegtoe", 4, "", "e"], ["vervang", 5, "i", "r"], ["vervang", 6, "g", "s"]],
		[["verwijder", 0, "r", ""], ["vervang", 4, "i", "e"], ["voegtoe", 5, "", "r"], ["vervang", 6, "g", "s"]],
		[["verwijder", 0, "r", ""], ["vervang", 4, "i", "e"], ["vervang", 5, "g", "r"], ["voegtoe", 6, "", "s"]]]
	t.eq(_sorted_ops(R.distinct_sequences("roestig", "oesters")), _sorted_lists(want20), "3 reeksen")

	t.section("T21 Algoritme 8 examen (p. 79)")
	var d21 := R.approx_table("examen", "de_armen_vouwen")
	t.eq(d21, _table_rows(["0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0", "1 1 0 1 1 1 1 0 1 1 1 1 1 1 0 1",
		"2 2 1 1 2 2 2 1 1 2 2 2 2 2 1 1", "3 3 2 2 1 2 3 2 2 2 3 3 3 3 2 2", "4 4 3 3 2 2 2 3 3 3 3 4 4 4 3 3",
		"5 5 4 4 3 3 3 2 3 4 4 4 5 5 4 4", "6 6 5 5 4 4 4 3 2 3 4 5 5 6 5 4"]), "tabel p. 79")
	t.eq(R.approx_best("examen", "de_armen_vouwen"), {"best": 2, "end_cols": [8]}, "best 2, kolom 8")
	var p21 := R.all_paths(d21, "examen", "de_armen_vouwen", 6, 8, true)
	t.eq(p21.size(), 1, "uniek pad")
	if p21.size() == 1:
		var st21 := R.path_start_col(p21[0])
		t.eq(st21, 1, "begin 1")
		t.eq("de_armen_vouwen".substr(st21, 8 - st21), "e_armen", "match e_armen")
		t.eq(_ops_list(R.ops_of_path(p21[0], "examen", "de_armen_vouwen", st21)),
			[["vervang", 1, "x", "_"], ["voegtoe", 3, "", "r"]], "bewerkingen")
		var cells: Array = []
		for st in p21[0]:
			cells.append([int(st.i), int(st.j), str(st.dir)])
		t.eq(cells, [[1, 2, "diag"], [2, 3, "diag"], [3, 4, "diag"], [3, 5, "left"], [4, 6, "diag"],
			[5, 7, "diag"], [6, 8, "diag"]], "lijn van p. 79")

	t.section("T22 Oef. 70")
	t.eq(R.approx_best("zoeken", "koekjes_kweken"), {"best": 2, "end_cols": [14]}, "best 2, kolom 14")
	var d22 := R.approx_table("zoeken", "koekjes_kweken")
	t.eq(d22, _table_rows(["0 0 0 0 0 0 0 0 0 0 0 0 0 0 0", "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1",
		"2 2 1 2 2 2 2 2 2 2 2 2 2 2 2", "3 3 2 1 2 3 2 3 3 3 3 2 3 2 3", "4 3 3 2 1 2 3 3 4 3 4 3 2 3 3",
		"5 4 4 3 2 2 2 3 4 4 4 4 3 2 3", "6 5 5 4 3 3 3 3 4 5 5 5 4 3 2"]), "tabel Oef. 70")
	var starts22 := {}
	for mm in R.approx_matches("zoeken", "koekjes_kweken"):
		starts22[int(mm.start)] = true
	var sk22 := starts22.keys()
	sk22.sort()
	t.eq(sk22, [8, 9, 10], "beginposities {8, 9, 10}")

	t.section("T23 Oef. 71")
	t.eq(R.approx_best("test", "beste_tekst"), {"best": 1, "end_cols": [4, 7, 11]}, "best 1, kolommen 4, 7, 11")
	var m23: Array = []
	for mm in R.approx_matches("test", "beste_tekst"):
		m23.append([int(mm.end_col), "beste_tekst".substr(int(mm.start), int(mm.end_col) - int(mm.start))])
	m23.sort()
	t.eq(m23, [[4, "best"], [4, "est"], [7, "te_t"], [11, "tekst"]], "matches")

	t.section("T24 brute kracht 1-1 en joker")
	var b24 := R.brute("kerk", "de_kerker_bij_de_kerk", true)
	t.eq([b24.cmp, b24.alignments, b24.rewind, b24.hits], [27, 18, 4, [3, 17]], "1-1")
	var j24 := R.brute("?uizen", "de_huizen_en_buizen", true, "?")
	t.eq([j24.cmp, j24.hits], [36, [3, 13]], "joker 1-3")


func _ops_list(ops: Array) -> Array:
	var out: Array = []
	for o in ops:
		out.append([str(o.op), int(o.pos), str(o.from), str(o.to)])
	return out


func _sorted_ops(seqs: Array) -> Array:
	var out: Array = []
	for s in seqs:
		out.append(str(_ops_list(s)))
	out.sort()
	return out


func _sorted_lists(seqs: Array) -> Array:
	var out: Array = []
	for s in seqs:
		out.append(str(s))
	out.sort()
	return out


func _all_words(alpha: String, L: int) -> PackedStringArray:
	var out := PackedStringArray()
	var k := alpha.length()
	var total := 1
	for _i in L:
		total *= k
	for x in total:
		var s := ""
		var y := x
		for _i in L:
			s = alpha[y % k] + s
			y /= k
		out.append(s)
	return out


## BMH (FIRST) op bitwoorden: z = 4 bits (zi), t = 16 bits (ti); 0 = a, 1 = b, bit 0 = eerste teken.
## -> Vector2i(tikken, treffer ? 1 : 0)
func _bmh_fast(zi: int, ti: int) -> Vector2i:
	var zb := PackedInt32Array()
	for k in 4:
		zb.append((zi >> (3 - k)) & 1)
	var tb := PackedInt32Array()
	for k in 16:
		tb.append((ti >> (15 - k)) & 1)
	var vh := [4, 4]
	for i in 3:
		vh[zb[i]] = 3 - i
	var i := 3
	var cmp := 0
	while i < 16:
		var ok := true
		for k in 4:
			cmp += 1
			if zb[3 - k] != tb[i - k]:
				ok = false
				break
		if ok:
			return Vector2i(cmp, 1)
		i += vh[tb[i]]
	return Vector2i(cmp, 0)


func _ab_word(x: int, L: int) -> String:
	var s := ""
	for b in L:
		s += "b" if (x >> (L - 1 - b)) & 1 else "a"
	return s


func _rand_word(rng: RandomNumberGenerator, alpha: String, L: int) -> String:
	var s := ""
	for _i in L:
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s


func _max_brute(n: int, m: int) -> int:
	var best := -1
	for zi in 1 << m:
		var z := _ab_word(zi, m)
		for ti in 1 << n:
			best = maxi(best, int(TxReference.brute(z, _ab_word(ti, n), false).cmp))
	return best
