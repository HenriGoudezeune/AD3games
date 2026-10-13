extends RefCounted
## Machines (spelregels, gevolgen): Sjabloon, Doorloper, Ponsbank. T24–T27, T32 (deels), tellers per level.

const H := preload("res://games/telex/tests/suites/tx_helpers.gd")
const VD := TxCodes.Verdict


func _trace(fx: Array) -> Array:
	var out: Array = []
	for f in fx:
		if str(f.fx) == "needle" and str(f.result) != "wait":
			out.append([int(f.start), int(f.gel), int(f.em)])
	return out


func run(t) -> void:
	t.section("Sjabloon 1-1 (T24 via machine)")
	var b := H.mk({"machine": "brute", "z": "kerk", "t": "de_kerker_bij_de_kerk", "find": "all"})
	var bad := [0]
	var mv := H.play(b, bad)
	t.eq(bad, [0], "perfect spel zonder problemen")
	t.eq([b.counters.ticks, b.counters.alignments, b.counters.rewind], [27, 18, 4], "27 tikken, 18 uitlijningen, spoelmeter 4")
	t.eq(H.hit_starts(b), [3, 17], "treffers 3 en 17")
	t.eq(mv, 19, "go + 18× next")
	t.ok(b.is_done() and b.missed.is_empty(), "klaar, niets gemist")
	var bj := H.mk({"machine": "brute", "z": "?uizen", "t": "de_huizen_en_buizen", "find": "all", "joker": "?"})
	H.play(bj, bad)
	t.eq([bj.counters.ticks, H.hit_starts(bj)], [36, [3, 13]], "joker: 36 tikken, treffers 3 en 13")
	var b31 := H.mk({"machine": "brute", "z": "barbados", "t": "barbaarse_barbecue_in_barbados", "find": "first"})
	H.play(b31, bad)
	t.eq([b31.counters.ticks, b31.counters.alignments, b31.counters.rewind], [42, 23, 8], "brute 3-1: 42/23/8")

	t.section("Doorloper 3-1 (T03 via machine)")
	var k31 := H.mk({"machine": "kmp", "z": "barbados", "t": "barbaarse_barbecue_in_barbados", "find": "first",
		"strip": "none", "auto_zero": true})
	var rec := H.record(k31)
	H.play(k31, bad)
	t.eq(bad, [0], "perfect spel")
	var tr := _trace(rec)
	var ems: Array = []
	for x in tr:
		ems.append(x[2])
	t.eq(ems, [5, 2, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 8], "em-reeks p. 58–59")
	t.eq([k31.counters.ticks, k31.counters.alignments, k31.counters.rewind], [34, 18, 0], "34 tikken, 18 uitlijningen")
	t.eq(H.hit_starts(k31), [22], "treffer 22")
	var shifts: Array = []
	for e in k31.log.of_type("SHIFT"):
		if not bool(e.auto):
			shifts.append(int(e.data.s))
	t.eq(shifts, [3, 2, 3, 1], "spelersverschuivingen 3, 2, 3, 1")
	H.unhook(k31)

	t.section("T25 tanden (3-1)")
	var k := H.mk({"machine": "kmp", "z": "barbados", "t": "barbaarse_barbecue_in_barbados", "find": "first",
		"strip": "none", "auto_zero": true})
	k.apply({"act": "go"})
	t.eq([k.start, k.gel, k.em], [0, 0, 5], "(0,0,5)")
	var s0 := var_to_str(k.snapshot())
	var r1 := k.apply({"act": "shift", "s": 1})
	var r2 := k.apply({"act": "shift", "s": 2})
	t.eq([r1.ok, r1.reason, r2.ok, r2.reason], [false, "no_mesh", false, "no_mesh"], "shift 1 en 2 klemmen")
	var s1 := k.snapshot()
	s1.log_len = 0
	var s0d: Dictionary = str_to_var(s0)
	s0d.log_len = 0
	s1.counters.bumps = 0
	t.eq(var_to_str(s1), var_to_str(s0d), "staat ongewijzigd (op log en klemteller na)")
	t.eq(k.counters.bumps, 2, "2 klemmen geteld")
	t.eq(k.preview({"act": "shift", "s": 4}).mesh, false, "preview s=4: mesh false")
	t.eq(k.preview({"act": "shift", "s": 3}).mesh, true, "preview s=3: mesh true")
	var snap := k.snapshot()
	t.eq(k.apply({"act": "shift", "s": 5}).verdict, VD.SHIFT_LONG, "shift 5 → SHIFT_LONG")
	k.restore(snap)
	t.eq(k.apply({"act": "shift", "s": 3}).verdict, VD.OK, "shift 3 OK")
	t.eq([k.start, k.gel, k.em], [3, 2, 2], "(3,2,2)")
	k.apply({"act": "shift", "s": 2})
	t.eq([k.start, k.em], [10, 4], "auto_zero tot (10,0,4)")
	var fit: Array = []
	for s in range(1, 6):
		if k.preview({"act": "shift", "s": s}).mesh:
			fit.append(s)
	t.eq(fit, [3, 4, 5], "na em 4 passen {3, 4, ≥4}")
	t.eq(k.need(), 14, "need() = leeskop start + em")

	t.section("Ponsbank Oef. 40 (3-2 stage A) + doorloop (stage B)")
	var p := H.mk({"machine": "kmp_table", "z": "ananas", "method": "def11", "cells": "m-1"})
	t.eq(p.phase, TxCodes.Phase.PUNCH_CELL, "fase PUNCH_CELL")
	var fits := {}
	for j in range(2, 6):
		var l: Array = []
		for v in range(1, j + 1):
			if p.preview({"act": "punch", "j": j, "v": v}).mesh:
				l.append(v)
		fits[j] = l
	t.eq(fits, {2: [2], 3: [2, 3], 4: [2, 4], 5: [2, 4, 5]}, "passende waarden §5.4")
	H.play(p, bad)
	t.eq(p.strip, [1, 1, 2, 2, 2, 2], "V = 1 1 2 2 2 2")
	var kb := H.mk({"machine": "kmp", "z": "ananas", "t": "bananen_in_ra'ananas'_centrum", "find": "first",
		"strip": "carry", "auto_zero": true, "auto_strip": true}, p.output())
	var recb := H.record(kb)
	var nb := H.play(kb, bad)
	var trb := _trace(recb)
	t.eq(trb, [[0, 0, 0], [1, 0, 4], [3, 2, 2], [5, 0, 0], [6, 0, 0], [7, 0, 0], [8, 0, 0], [9, 0, 0], [10, 0, 0],
		[11, 0, 0], [12, 0, 1], [13, 0, 0], [14, 0, 6]], "spoor 3-2 B")
	t.eq([kb.counters.ticks, kb.counters.alignments, H.hit_starts(kb)], [23, 13, [14]], "23 tikken, treffer 14")
	t.eq(nb, 1, "met volledige strook: enkel go (alles automatisch)")
	H.unhook(kb)
	# PUNCH_LONG: V[4] = 4 past ook → de Doorloper springt op start 1 te ver
	var p2 := H.mk({"machine": "kmp_table", "z": "ananas", "method": "def11", "cells": "m-1"})
	p2.apply({"act": "punch", "j": 2, "v": 2})
	p2.apply({"act": "punch", "j": 3, "v": 2})
	t.eq(p2.apply({"act": "punch", "j": 4, "v": 4}).verdict, VD.PUNCH_LONG, "V[4] = 4 → PUNCH_LONG")
	t.eq(p2.apply({"act": "punch", "j": 4, "v": 2}).reason, "filled", "al gevuld → klem")
	t.eq(p2.apply({"act": "punch", "j": 5, "v": 3}).reason, "no_mesh", "V[5] = 3 past niet")
	p2.apply({"act": "punch", "j": 5, "v": 2})
	t.ok(p2.is_done(), "klaar na het laatste vakje")
	var kb2 := H.mk({"machine": "kmp", "z": "ananas", "t": "bananen_in_ra'ananas'_centrum", "find": "first",
		"strip": "carry", "auto_zero": true, "auto_strip": true}, p2.output())
	kb2.apply({"act": "go"})
	t.ok(kb2.log.of_verdict(VD.SHIFT_LONG).size() >= 1, "auto_strip verschuift te ver (SHIFT_LONG, auto)")
	t.ok(bool(kb2.log.of_verdict(VD.SHIFT_LONG)[0].auto), "gelogd met auto = true")

	t.section("T27 spiegelrit (3-3)")
	var a5 := H.mk({"machine": "kmp_table", "z": "volvoert", "method": "alg5", "cells": "m-1"})
	var a5c := a5.snapshot()
	var steps: Array = []
	var guard := 0
	while not a5.is_done() and guard < 100:
		guard += 1
		if a5.phase == TxCodes.Phase.MIRROR_PUNCH:
			steps.append([a5.start, a5.gel, a5.em])
		var r := a5.apply(a5.correct_move())
		if not r.ok or int(r.verdict) != VD.OK:
			t.ok(false, "orakel spiegelrit: %s" % str(r))
			break
	t.eq(steps, [[1, 0, 0], [2, 0, 0], [3, 0, 2], [5, 0, 0], [6, 0, 0]], "stappen = barbados-vorm")
	t.eq(a5.strip.slice(0, 8), [1, 1, 2, 3, 3, 3, 6, 7], "V = 1 1 2 3 3 3 6 7")
	t.eq(a5.counters.ticks, 7, "7 tikken in de spiegelrit")
	a5.restore(a5c)
	t.eq(a5.apply({"act": "punch_to", "to": 2, "v": 1}).reason, "no_mesh", "stap 1: punch_to 2 v=1 → klem")
	t.eq(a5.apply({"act": "punch_to", "to": 2, "v": 2}).verdict, VD.OK, "stap 1 correct")
	a5.apply({"act": "shift", "s": 1})
	a5.apply({"act": "punch_to", "to": 3, "v": 3})
	a5.apply({"act": "strip"})
	t.eq([a5.start, a5.em], [3, 2], "stap 3: start 3, em 2")
	t.eq(a5.apply({"act": "punch_to", "to": 6, "v": 3}).reason, "no_mesh", "punch_to 6 v=3 → klem")
	t.eq(a5.apply({"act": "punch_to", "to": 4, "v": 3}).verdict, VD.PUNCH_SHORT, "punch_to 4 v=3 → PUNCH_SHORT")
	var g2 := 0
	while a5.phase != TxCodes.Phase.PUNCH_CELL and not a5.is_done() and g2 < 50:
		g2 += 1
		a5.apply(a5.correct_move())
	t.eq(a5.strip[5], TxCodes.STRIP_EMPTY, "na de spiegelrit is vakje 5 leeg")
	t.eq(a5.phase, TxCodes.Phase.PUNCH_CELL, "herstel met de spiegel (PUNCH_CELL)")
	t.eq(a5.correct_move(), {"act": "punch", "j": 5, "v": 3}, "orakel: vakje 5 = 3")
	var kv := H.mk({"machine": "kmp", "z": "volvoert", "t": "volvo_vol_vogels_volvoert_kunststukje",
		"find": "first", "strip": [1, 1, 2, 3, 3, 3, 6, 7], "auto_zero": true, "auto_strip": true})
	var recv := H.record(kv)
	H.play(kv, bad)
	t.eq(_trace(recv), [[0, 0, 5], [3, 2, 2], [5, 0, 0], [6, 0, 3], [9, 0, 0], [10, 0, 2], [12, 0, 0], [13, 0, 0],
		[14, 0, 0], [15, 0, 0], [16, 0, 0], [17, 0, 8]], "3-3 B spoor (T06)")
	t.eq([kv.counters.ticks, kv.counters.alignments, H.hit_starts(kv)], [29, 12, [17]], "29 tikken, treffer 17")
	H.unhook(kv)

	t.section("T26 te ver na een treffer (3-4)")
	var tt := H.mk({"machine": "kmp_table", "z": "tata", "method": "alg5", "cells": "m"})
	H.play(tt, bad)
	t.eq(tt.strip, [1, 1, 2, 2, 2], "V = 1 1 2 2 | 2 (Alg5 vult V[m] zelf)")
	var k34 := H.mk({"machine": "kmp", "z": "tata", "t": "tatatata_zei_de_telex_tatata", "find": "all",
		"strip": "none", "auto_zero": true})
	var k34s := k34.snapshot()
	H.play(k34, bad)
	t.eq([H.hit_starts(k34), k34.counters.ticks, k34.counters.alignments], [[0, 2, 4, 22, 24], 30, 20],
		"perfect: 5 treffers, 30 tikken, 20 uitlijningen")
	k34.restore(k34s)
	k34.apply({"act": "go"})
	t.eq([k34.em, H.hit_starts(k34)], [4, [0]], "treffer @0")
	var r4 := k34.apply({"act": "shift", "s": 4})
	t.eq(r4.verdict, VD.SHIFT_LONG, "shift 4 na de treffer → SHIFT_LONG")
	t.eq(H.missed_starts(k34), [2], "@2 gemist")
	var seq_shift := int(k34.log.of_type("SHIFT")[-1].seq)
	t.eq(int(k34.missed[0].cause_seq), seq_shift, "cause_seq = die verschuiving")
	t.ok(k34.log.entry(seq_shift).affects.has(2), "affects bevat 2")
	t.eq(k34.log.cause_of(2).seq, seq_shift, "cause_of(2)")
	H.play(k34, bad)
	t.eq(H.hit_starts(k34), [0, 4, 22, 24], "verder: 4, 22, 24")
	t.eq(k34.counters.ticks, 30, "30 tikken")
	t.ok(k34.log.coach_line(k34.log.entry(seq_shift)).begins_with("Na een mismatch op 4 past al 2"),
		"coachzin SHIFT_LONG")
	t.eq(k34.log.notes_ref(k34.log.entry(seq_shift)), "Definitie 11 · notas p. 56", "notasverwijzing")

	t.section("T32 stroommodel (KMP LIVE, brute kracht LIVE)")
	var kl := H.mk({"machine": "kmp", "z": "kokos", "t": "kokokokos_in_de_kokoskokosnoot", "find": "all",
		"strip": [1, 1, 2, 2, TxCodes.STRIP_BURNT, TxCodes.STRIP_BURNT], "auto_zero": true, "auto_strip": true},
		{}, {"B": 4})
	t.eq(kl.front, 0, "LIVE: front start op 0")
	kl.apply({"act": "go"})
	t.eq(kl.phase, TxCodes.Phase.WAIT_TAPE, "naald wacht op het lint")
	var tears := 0
	for f in range(1, 31):
		kl.set_front(f)
		var g := 0
		while not kl.is_done() and kl.phase == TxCodes.Phase.DECIDE and g < 10:
			g += 1
			kl.apply(kl.correct_move())
	tears = kl.log.count_type("TEAR")
	t.eq(tears, 0, "met onmiddellijke beslissingen nooit een scheur")
	t.eq(H.hit_starts(kl), [4, 16, 21], "treffers 4, 16, 21")
	t.eq(kl.counters.ticks, 28, "28 tikken")
	var hand := 0
	for e in kl.log.entries:
		if str(e.type) in ["SHIFT", "STRIP"] and not bool(e.auto):
			hand += 1
	t.eq(hand, 5, "5 handverschuivingen (2, 2, 5 en 2× V[5] na een treffer)")
	# een scheur: wachten in DECIDE
	var kt := H.mk({"machine": "kmp", "z": "kokos", "t": "kokokokos_in_de_kokoskokosnoot", "find": "all",
		"strip": [1, 1, 2, 2, TxCodes.STRIP_BURNT, TxCodes.STRIP_BURNT], "auto_zero": true, "auto_strip": true},
		{}, {"B": 4})
	kt.apply({"act": "go"})
	for f in range(1, 12):
		kt.set_front(f)
	t.ok(kt.log.count_type("TEAR") >= 1, "te lang wachten → scheur")
	t.eq(H.missed_starts(kt), [4], "kokos @4 gemist door de scheur")
	t.eq(str(kt.log.entry(int(kt.missed[0].cause_seq)).type), "TEAR", "oorzaak = TEAR")
	t.ok(kt.invariants().is_empty(), "invarianten na scheur: %s" % str(kt.invariants()))
	# brute kracht met B = 4 scheurt (B < m)
	var bl := H.mk({"machine": "brute", "z": "kokos", "t": "kokokokos_in_de_kokoskokosnoot", "find": "all"}, {},
		{"B": 4})
	bl.apply({"act": "go"})
	for f in range(1, 31):
		bl.set_front(f)
		var g3 := 0
		while not bl.is_done() and bl.phase == TxCodes.Phase.DECIDE and g3 < 10:
			g3 += 1
			bl.apply(bl.correct_move())
	t.ok(bl.log.count_type("TEAR") >= 1, "brute kracht B = 4 scheurt")
	t.eq(H.hit_starts(bl), [], "en vindt niets")
	t.eq(H.missed_starts(bl), [4, 16, 21], "alle drie gemist")
	var b5 := H.mk({"machine": "brute", "z": "kokos", "t": "kokokokos_in_de_kokoskokosnoot", "find": "all"}, {},
		{"B": 5})
	b5.apply({"act": "go"})
	for f in range(1, 31):
		b5.set_front(f)
		var g4 := 0
		while not b5.is_done() and b5.phase == TxCodes.Phase.DECIDE and g4 < 10:
			g4 += 1
			b5.apply(b5.correct_move())
	t.eq([b5.log.count_type("TEAR"), H.hit_starts(b5)], [0, [4, 16, 21]], "B = 5: geen scheur, alle drie")
	# force_to rechtstreeks
	var bf := H.mk({"machine": "brute", "z": "kerk", "t": "de_kerker_bij_de_kerk", "find": "all"})
	bf.force_to(10)
	t.eq(H.missed_starts(bf), [3], "force_to(10): @3 gemist")
	t.eq(bf.start, 10, "start := S")

	t.section("T38 (deel) orakel/klem/fout per fase — brute, kmp, kmp_table")
	var specs := [
		[{"machine": "brute", "z": "kerk", "t": "de_kerker_bij_de_kerk", "find": "all"}, {}],
		[{"machine": "kmp", "z": "tata", "t": "tatatata_zei_de_telex_tatata", "find": "all", "strip": "none",
			"auto_zero": true}, {}],
		[{"machine": "kmp_table", "z": "volvoert", "method": "alg5", "cells": "m"}, {}],
		[{"machine": "kmp_table", "z": "ananas", "method": "def11", "cells": "m-1"}, {}],
	]
	for sp in specs:
		var res := _oracle_check(sp[0], sp[1])
		t.eq(res, [0, 0, 0], "%s: orakel OK / onmogelijk klemt / fout ≠ OK" % str(sp[0].machine))


## Loopt de stage af met het orakel en controleert in elke toestand: correct_move OK, impossible_moves klemmen,
## wrong_moves ok = true met verdict ≠ OK (telkens op een kopie via snapshot/restore).
func _oracle_check(stage: Dictionary, carry: Dictionary) -> Array:
	var mc := H.mk(stage, carry)
	var bad := [0, 0, 0]
	var guard := 0
	while not mc.is_done() and guard < 2000:
		guard += 1
		var snap := mc.snapshot()
		for im in mc.impossible_moves():
			var r := mc.apply(im)
			if bool(r.ok):
				bad[1] += 1
			mc.restore(snap)
		for wm in mc.wrong_moves():
			var r2 := mc.apply(wm)
			if not bool(r2.ok) or int(r2.verdict) == VD.OK:
				bad[2] += 1
			mc.restore(snap)
		var cm := mc.correct_move()
		if str(cm.act) == "none":
			break
		var r3 := mc.apply(cm)
		if not bool(r3.ok) or int(r3.verdict) != VD.OK:
			bad[0] += 1
			break
	return bad
