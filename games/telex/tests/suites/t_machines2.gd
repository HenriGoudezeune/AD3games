extends RefCounted
## Machines (vervolg): Vingerafdruk, Springer, Lampen-/ruisbord, Schakelbord, Tegenzet. T28–T31, T33–T35, T38.

const H := preload("res://games/telex/tests/suites/tx_helpers.gd")
const VD := TxCodes.Verdict
const PH := TxCodes.Phase

const RK23 := {"machine": "rk", "z": "00101", "q": 13, "t": "1101110010001010", "find": "first",
	"prep": ["w", "hz", "h0"]}
const RK22 := {"machine": "rk", "z": "1011", "q": 7, "t": "1010010110110100", "find": "all",
	"prep": ["w", "hz", "h0"], "prefill": {"w": 2, "hz": 4}}
const RK21 := {"machine": "rk", "z": "1011", "q": 7, "signals": ["0100", "1011", "1110"], "prep": ["w", "hz"],
	"find": "all"}


## Speelt met het orakel tot pred(mc) waar is (of klaar).
func _until(mc: TxMachine, pred: Callable, limit := 2000) -> void:
	var g := 0
	while not mc.is_done() and not pred.call(mc) and g < limit:
		g += 1
		mc.apply(mc.correct_move())


func run(t) -> void:
	var bad := [0]

	t.section("Vingerafdruk 2-1 (signalen)")
	var r21 := H.mk(RK21)
	t.eq(r21.phase, PH.W_CALC, "start in W_CALC")
	t.eq(r21.wheel, 1, "wiel op 1")
	H.play(r21, bad)
	t.eq(bad, [0], "perfect spel")
	t.eq([r21.w, r21.hz], [2, 4], "w = 2, h(z) = 4")
	t.eq([r21.counters.wheel, r21.counters.ticks], [30, 5], "30 wielslagen, 5 tikken")
	t.eq(H.hit_starts(r21), [1], "signaal 1 = treffer")
	var hw: Array = []
	for h in r21.history():
		hw.append(int(h.wheel))
	t.eq(hw, [4, 4, 0], "signaalwaarden 4, 4, 0")

	t.section("Vingerafdruk 2-2 (rollen)")
	var r22 := H.mk(RK22)
	t.eq(r22.phase, PH.HORNER, "w en h(z) voorgezet: meteen Horner op venster 0")
	H.play(r22, bad)
	t.eq([r22.counters.wheel, r22.counters.ticks, H.hit_starts(r22)], [31, 10, [5, 8]], "31 wielslagen, 10 tikken")
	var hw2: Array = []
	for h in r22.history():
		hw2.append(int(h.wheel))
	t.eq(hw2, [3, 4, 2, 2, 5, 4, 6, 6, 4, 6, 6, 3, 4], "vensterwaarden = §5.3")

	t.section("Vingerafdruk 2-3 (Oef. 34)")
	var r23 := H.mk(RK23)
	H.play(r23, bad)
	t.eq([r23.counters.wheel, r23.counters.ticks, H.hit_starts(r23)], [41, 6, [10]], "41 wielslagen, 6 tikken")
	t.eq([r23.w, r23.hz], [6, 5], "w 6, h(z) 5")
	var hw3: Array = []
	for h in r23.history():
		hw3.append(int(h.wheel))
	t.eq(hw3, [1, 10, 1, 2, 12, 5, 4, 8, 4, 2, 5], "hs")

	t.section("T28 vergeten −w (2-3)")
	var r28 := H.mk(RK23)
	_until(r28, func(mc): return mc.phase == PH.ROLL)
	t.eq([r28.i, r28.out_bit(), r28.in_bit()], [0, 1, 1], "i = 0 → 1: uit 1, in 1")
	r28.apply({"act": "wheel", "op": "double"})
	r28.apply({"act": "wheel", "op": "plus1"})
	var rs := r28.apply({"act": "slide"})
	t.eq(rs.verdict, VD.WRONG_HASH, "slide zonder −w → WRONG_HASH")
	var slide_seq := int(r28.log.of_type("SLIDE")[-1].seq)
	H.play(r28, [0])
	var hw28: Array = []
	for h in r28.history():
		hw28.append(int(h.wheel))
	t.eq(hw28, [1, 3, 0, 0, 8, 10, 1, 2, 5, 4, 9, 5], "wielstand per venster")
	var verif: Array = []
	for e in r28.log.of_type("VERIFY"):
		verif.append([int(e.data.i), bool(e.data.equal)])
	t.eq(verif, [[8, false], [11, false]], "alarmen bij 8 en 11, telkens botsing")
	t.eq(r28.counters.ticks, 3, "1 + 2 tikken")
	t.eq(H.missed_starts(r28), [10], "@10 gemist")
	t.eq(int(r28.missed[0].cause_seq), slide_seq, "cause_seq = de slide van i = 1")
	var wh := 0
	for e in r28.log.mistakes():
		if int(e.verdict) == VD.WRONG_HASH:
			wh += 1
	t.eq(wh, 1, "precies één WRONG_HASH")
	t.ok(r28.log.coach_line(r28.log.entry(slide_seq)).begins_with("Venster 1: 2·1 − 6 + 1 mod 13 = 10, niet 3"),
		"coachzin WRONG_HASH: %s" % r28.log.coach_line(r28.log.entry(slide_seq)))
	t.ok(r28.invariants().is_empty(), "invarianten")

	t.section("T33 alarmkeuzes (2-3)")
	var r33 := H.mk(RK23)
	_until(r33, func(mc): return mc.phase == PH.ALARM)
	t.eq(r33.i, 5, "eerste alarm bij i = 5")
	var a33 := r33.snapshot()
	var got := []
	r33.consequence.connect(func(ev): got.append(str(ev.kind)))
	t.eq(r33.apply({"act": "report"}).verdict, VD.FALSE_ALARM, "report → FALSE_ALARM")
	t.eq(got, ["false_alarm"], "consequence false_alarm")
	t.eq(r33.false_alarms.size(), 1, "één vals alarm")
	t.ok(r33.log.coach_line(r33.log.of_verdict(VD.FALSE_ALARM)[0]).begins_with("10010 ≡ 5 (mod 13)"),
		"coachzin hashbotsing")
	H.unhook(r33)
	r33.restore(a33)
	t.eq(r33.apply({"act": "ignore"}).verdict, VD.SKIPPED_CHECK, "ignore → SKIPPED_CHECK")
	t.eq(r33.missed.size(), 0, "geen MISSED")
	_until(r33, func(mc): return mc.phase == PH.ALARM)
	t.eq(r33.i, 10, "alarm bij i = 10")
	var a10 := r33.snapshot()
	t.eq(r33.apply({"act": "ignore"}).verdict, VD.SKIPPED_CHECK, "ignore bij 10 → SKIPPED_CHECK")
	t.eq(H.missed_starts(r33), [10], "+ MISSED @10")
	t.eq(str(r33.log.entry(int(r33.missed[0].cause_seq)).type), "IGNORE", "oorzaak = Negeer")
	r33.restore(a10)
	var rr := r33.apply({"act": "report"})
	t.eq([rr.verdict, rr.done], [VD.UNVERIFIED, true], "report bij 10 → UNVERIFIED en klaar (FIRST)")
	t.eq(H.hit_starts(r33), [10], "melding telt")
	t.eq(r33.apply({"act": "verify"}).reason, "wrong_phase", "na het einde klemt alles")

	t.section("Vingerafdruk klemmen")
	var rk := H.mk(RK23)
	t.eq(rk.apply({"act": "wheel", "op": "minus_w"}).reason, "not_now", "−w in W_CALC")
	t.eq(rk.apply({"act": "wheel", "op": "plus1"}).reason, "not_now", "+1 in W_CALC")
	t.eq(rk.apply({"act": "verify"}).reason, "no_alarm", "controle zonder alarm")
	var rk2 := H.mk({"machine": "rk", "z": "1011", "q": 7, "t": "10100101", "find": "all", "prep": ["hz", "w"]})
	t.eq(rk2.phase, PH.W_CALC, "prep-volgorde: w eerst")
	t.eq(rk2.apply({"act": "commit"}).verdict, VD.WRONG_HASH, "commit zonder verdubbelen → WRONG_HASH (w = 1)")

	t.section("Springer 4-1 barbara")
	var b41 := H.mk({"machine": "bmh", "z": "barbara", "cards": "stamp"})
	t.eq(b41.phase, PH.CARDS, "CARDS")
	t.eq(b41.apply({"act": "stamp", "i": 6}).reason, "last_pos", "positie 6 stempelen klemt")
	H.play(b41, bad)
	t.eq(b41.cards, {"b": 3, "a": 2, "r": 1}, "a = 2, b = 3, r = 1")
	t.ok(b41.is_done(), "kaartstage zonder lint eindigt na cards_done")
	var stamps: Array = []
	for e in b41.log.of_type("STAMP"):
		stamps.append([int(e.data.i), str(e.data.x), int(e.data.v)])
	t.eq(stamps, [[0, "b", 6], [1, "a", 5], [2, "r", 4], [3, "b", 3], [4, "a", 2], [5, "r", 1]], "stempels 0..5")
	var r41 := H.mk({"machine": "bmh", "z": "barbara", "t": "barbados_zoekt_barbara", "find": "first",
		"cards": "carry", "key_hint": true}, b41.output())
	H.play(r41, bad)
	var ii: Array = []
	for e in r41.log.of_type("KEY"):
		ii.append([int(e.data.i), str(e.data.x), int(e.data.s)])
	t.eq(ii, [[6, "o", 7], [13, "t", 7], [20, "r", 1]], "(i, sleutel, sprong)")
	t.eq([r41.counters.ticks, r41.counters.alignments, H.hit_starts(r41)], [10, 4, [15]], "10 tikken, treffer 15")

	t.section("Springer 4-2 / 4-3")
	var b42 := H.mk({"machine": "bmh", "z": "ananas", "cards": "stamp"})
	H.play(b42, bad)
	t.eq(b42.cards, {"a": 1, "n": 2}, "a = 1, n = 2 (s: overige)")
	var r42 := H.mk({"machine": "bmh", "z": "ananas", "t": "de_spa_in_ra'ananas'", "find": "first",
		"cards": "carry"}, b42.output())
	H.play(r42, bad)
	t.eq([r42.counters.ticks, H.hit_starts(r42)], [9, [13]], "9 tikken, treffer 13")
	var r43 := H.mk({"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
		"cards": "prefilled"})
	H.play(r43, bad)
	t.eq([r43.counters.ticks, r43.counters.alignments, H.hit_starts(r43)], [22, 9, [18, 27]], "22 tikken, 18 en 27")
	t.eq(bad, [0], "perfect spel zonder problemen")

	t.section("T29 kaartvolgorde (4-3)")
	var c29 := H.mk({"machine": "bmh", "z": "salsa", "cards": "stamp"})
	t.eq(c29.apply({"act": "stamp", "i": 4}).reason, "last_pos", "stamp 4 → klem last_pos")
	for p in [3, 0, 1, 2]:
		c29.apply({"act": "stamp", "i": p})
	t.eq(c29.cards, {"s": 4, "a": 3, "l": 2}, "s = 4 (overschreven)")
	t.eq(c29.apply({"act": "cards_done"}).verdict, VD.WRONG_CARDS, "WRONG_CARDS")
	var r29 := H.mk({"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
		"cards": "carry"}, c29.output())
	r29.apply({"act": "go"})
	var jumps: Array = []
	var g := 0
	while not r29.is_done() and g < 50:
		g += 1
		var before_i: int = r29.i
		r29.apply({"act": "key", "pos": r29.i})
		jumps.append(r29.i - before_i)
	t.eq(jumps, [3, 5, 2, 5, 3, 3, 5, 4], "sprongen 3, 5, 2, 5, 3, 3, 5, 4")
	t.eq(H.hit_starts(r29), [18], "treffer 18 gevonden")
	t.eq(H.missed_starts(r29), [27], "@27 gemist")
	var ce := r29.log.entry(int(r29.missed[0].cause_seq))
	t.eq([str(ce.type), int(ce.data.i), int(ce.verdict)], ["KEY", 30, VD.JUMP_LONG], "oorzaak: sprong bij i = 30")
	t.ok(c29.log.coach_line(c29.log.of_verdict(VD.WRONG_CARDS)[0]).begins_with("V_H[`s`] = 1"), "coachzin WRONG_CARDS")

	t.section("Springer: WRONG_KEY laat salsa ontsnappen (4-3)")
	var wk := H.mk({"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
		"cards": "prefilled"})
	_until(wk, func(mc): return mc.phase == PH.DECIDE and mc.i == 19)
	t.eq(wk.mis_z, 0, "mismatch op z[0] (w ≠ s)")
	var rk19 := wk.apply({"act": "key", "pos": 15})
	t.eq(rk19.verdict, VD.WRONG_KEY, "mismatchteken w → WRONG_KEY")
	t.eq(wk.i, 24, "sprong 5")
	t.eq(H.missed_starts(wk), [18], "salsa @18 ontsnapt")
	t.eq(wk.apply({"act": "key", "pos": 30}).reason, "out_of_window", "buiten het venster klemt")
	t.eq(wk.apply({"act": "jump", "s": 0}).reason, "zero", "sprong 0 klemt")

	_shift_and(t, bad)
	_edit(t, bad)

	t.section("T38 (deel) orakel/klem/fout per fase — rk, bmh")
	for sp in [RK23, RK22, RK21, {"machine": "bmh", "z": "salsa", "cards": "stamp"},
			{"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
				"cards": "prefilled"},
			{"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all", "cards": "none"},
			{"machine": "shift_and", "z": "zoeken", "t": "iets_zoets_zoeken", "k": 0, "cards": "punch"},
			{"machine": "shift_and", "z": "zender", "t": "zonder_zender_zander_zinder", "k": 1, "cards": "punch",
				"wiring": "plug", "choose": true},
			{"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": -1},
			{"machine": "edit", "a": "test", "b": "beste_tekst", "approx": true, "want": -1}]:
		t.eq(_oracle_check(sp, {}), [0, 0, 0], "%s: orakel/klem/fout" % str(sp.machine))


func _oracle_check(stage: Dictionary, carry: Dictionary) -> Array:
	var mc := H.mk(stage, carry)
	var bad := [0, 0, 0]
	var guard := 0
	while not mc.is_done() and guard < 3000:
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


func _cols(mc: TxShiftAnd) -> Array:
	var out: Array = []
	for c in mc.prev:
		var s := ""
		for x in c:
			s += str(int(x))
		out.append(s)
	return out


func _shift_and(t, bad: Array) -> void:
	t.section("Lampenbord 5-1 (Figuur 23)")
	var c51 := H.mk({"machine": "shift_and", "z": "ana", "k": 0, "cards": "punch", "run": false})
	t.eq(c51.phase, PH.CARDS, "CARDS")
	H.play(c51, bad)
	t.eq(c51.output().c, {"a": [1, 0, 1], "n": [0, 1, 0]}, "C_a = 101, C_n = 010")
	var r51 := H.mk({"machine": "shift_and", "z": "ana", "t": "ananas", "k": 0, "cards": "carry", "find": "all"},
		c51.output())
	t.eq(r51.phase, PH.LEVER, "doorloop start met de hendel")
	var cols: Array = []
	var g := 0
	while not r51.is_done() and g < 100:
		g += 1
		r51.apply(r51.correct_move())
		if r51.phase == PH.LEVER or r51.is_done():
			cols.append(_cols(r51)[0])
	t.eq(cols, ["100", "010", "101", "010", "101", "000"], "kolommen = tabel p. 67")
	t.eq([H.hit_starts(r51), r51.counters.lamps], [[0, 2], 6], "bellen: begin 0 en 2; 6 lampslagen")

	t.section("Lampenbord 5-2 (Oef. 54)")
	var c52 := H.mk({"machine": "shift_and", "z": "zoeken", "k": 0, "cards": "punch", "run": false})
	H.play(c52, bad)
	var r52s := {"machine": "shift_and", "z": "zoeken", "t": "iets_zoets_zoeken", "k": 0, "cards": "carry",
		"find": "all"}
	var r52 := H.mk(r52s, c52.output())
	H.play(r52, bad)
	t.eq([H.hit_starts(r52), r52.counters.lamps], [[11], 17], "bel op 16 (begin 11), 17 lampslagen")
	t.eq(bad, [0], "perfect spel")

	t.section("T30 lampenbord-fouten (5-2)")
	var a30 := H.mk(r52s, c52.output())
	_until(a30, func(mc): return mc.j == 14 and mc.phase == PH.LEVER)
	t.eq(a30.apply({"act": "card", "x": "k"}).verdict, VD.NO_SHIFT, "kaart zonder hendel bij j = 14 → NO_SHIFT")
	H.play(a30, [0])
	t.eq(H.hit_starts(a30), [], "geen bel op 16")
	t.eq(H.missed_starts(a30), [11], "MISSED @11")
	t.eq(int(a30.log.entry(int(a30.missed[0].cause_seq)).verdict), VD.NO_SHIFT, "oorzaak = de NO_SHIFT-kaart")
	var b30 := H.mk(r52s, c52.output())
	_until(b30, func(mc): return mc.j == 15 and mc.phase == PH.CARD)
	t.eq(b30.apply({"act": "card", "x": ""}).verdict, VD.WRONG_CARD, "blanco bij j = 15 (e) → WRONG_CARD")
	H.play(b30, [0])
	t.eq([H.hit_starts(b30), H.missed_starts(b30)], [[], [11]], "geen bel, MISSED @11")
	var c30 := H.mk(r52s, c52.output())
	c30.apply({"act": "lever"})
	t.eq(c30.apply({"act": "lever"}).reason, "already", "tweede hendel → klem already")
	t.ok(c30.log.coach_line(b30.log.of_verdict(VD.WRONG_CARD)[0]) == "t[15] = `e`: kaart e.", "coachzin WRONG_CARD")
	var h30 := H.mk({"machine": "shift_and", "z": "zoeken", "k": 0, "cards": "punch", "run": false})
	h30.apply({"act": "hole", "x": "e", "i": 2})
	t.eq(h30.apply({"act": "cards_done"}).verdict, VD.WRONG_HOLES, "onvolledige kaarten → WRONG_HOLES")
	t.eq(h30.apply({"act": "hole", "x": "q", "i": 0}).reason, "wrong_phase", "na cards_done klemt ponsen")

	t.section("Ruisbord 6-1 (Oef. 60)")
	var c61 := H.mk({"machine": "shift_and", "z": "dank", "k": 0, "cards": "punch", "run": false})
	H.play(c61, bad)
	t.eq(c61.output().c, {"d": [1, 0, 0, 0], "a": [0, 1, 0, 0], "n": [0, 0, 1, 0], "k": [0, 0, 0, 1]}, "C_x dank")
	var w61 := H.mk({"machine": "shift_and", "z": "dank", "k": 1, "cards": "carry", "wiring": "plug", "run": false},
		c61.output())
	t.eq(w61.phase, PH.WIRE, "WIRE")
	H.play(w61, bad)
	t.eq(w61.output().wiring, {1: "old_shift"}, "kabel in oud ↓")
	var s61 := {"machine": "shift_and", "z": "dank", "t": "een_dansfeest", "k": 1, "cards": "carry",
		"wiring": "carry", "find": "all"}
	var r61 := H.mk(s61, w61.output())
	var pairs: Array = []
	var g2 := 0
	while not r61.is_done() and g2 < 100:
		g2 += 1
		r61.apply(r61.correct_move())
		if r61.phase == PH.LEVER or r61.is_done():
			pairs.append(_cols(r61))
	t.eq(pairs[4], ["1000", "1000"], "j4 d")
	t.eq(pairs[7], ["0000", "1001"], "j7 s: bel M1")
	t.eq(pairs[0], ["0000", "1000"], "eerste kolom (0000, 1000)")
	t.eq(H.hit_starts(r61), [4], "dans @4 (M1)")
	t.eq(int(r61.hits[0].level), 1, "level 1")
	t.eq(r61.counters.lamps, 13, "13 lampslagen")

	t.section("T34 ruisbord-bedrading (6-1)")
	for spec in [["old", [], [4], 0], ["new_shift", [], [4], 1], ["new", [], [4], 0]]:
		var w := H.mk({"machine": "shift_and", "z": "dank", "k": 1, "cards": "carry", "wiring": "plug", "run": false},
			c61.output())
		w.apply({"act": "plug", "l": 1, "src": spec[0]})
		t.eq(w.apply({"act": "wire_done"}).verdict, VD.WRONG_WIRE, "%s → WRONG_WIRE" % spec[0])
		var r := H.mk(s61, w.output(), {}, w.log)
		H.play(r, [0])
		t.eq(H.hit_starts(r), spec[1], "%s: geen echte bel" % spec[0])
		t.eq(H.missed_starts(r), spec[2], "%s: dans @4 MISSED" % spec[0])
		t.eq(r.false_alarms.size(), spec[3], "%s: valse alarmen" % spec[0])
		if spec[0] == "new_shift":
			t.eq([int(r.hits[0].end), bool(r.hits[0].real)], [6, false], "new_shift: bel op j = 6, real = false")
		var ce := r.log.entry(int(r.missed[0].cause_seq))
		t.eq(str(ce.type), "WIRE_DONE", "%s: oorzaak = bedrading" % spec[0])

	t.section("Ruisbord 6-2 (zender) met keuze")
	var c62 := H.mk({"machine": "shift_and", "z": "zender", "t": "zonder_zender_zander_zinder", "k": 1,
		"cards": "punch", "wiring": "plug", "find": "all", "choose": true})
	var c62s := c62.snapshot()
	H.play(c62, bad)
	var ends0: Array = []
	var ends1: Array = []
	for h in c62.hits:
		if int(h.level) == 0:
			ends0.append(int(h.end))
		else:
			ends1.append(int(h.end))
	t.eq([ends0, ends1], [[12], [5, 12, 19, 26]], "M0 op 12; M1 op 5, 12, 19, 26")
	t.eq(c62.chosen, 7, "ploeg naar @7")
	c62.restore(c62s)
	_until(c62, func(mc): return mc.phase == PH.CHOOSE)
	t.eq(c62.apply({"act": "choose", "start": 0}).verdict, VD.WRONG_PICK, "zonder @0 → WRONG_PICK")
	t.eq(c62.false_alarms.size(), 1, "+ vals alarm")
	t.ok(c62.log.coach_line(c62.log.of_verdict(VD.WRONG_PICK)[0]).contains("zender"), "coachzin WRONG_PICK")


func _edit(t, bad: Array) -> void:
	t.section("Schakelbord 7-1 (p. 76)")
	var e71 := H.mk({"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": 2})
	t.eq(e71.phase, PH.FILL, "FILL")
	H.play(e71, bad)
	t.eq(bad, [0], "perfect spel")
	t.eq(e71.tab, TxReference.edit_table("lessen", "feesten"), "tabel = p. 76")
	t.eq([e71.counters.relays, e71.distinct_sequences().size()], [42, 2], "42 relais, 2 verschillende reeksen")
	for ops in e71.distinct_sequences():
		t.eq([TxReference.apply_ops("lessen", ops), ops.size()], ["feesten", 3], "reeks geeft feesten in 3")
	var all71 := H.mk({"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": -1})
	H.play(all71, bad)
	t.eq(all71.distinct_sequences().size(), 4, "want = −1: alle 4 reeksen")

	t.section("T31 schakelbord-fouten (7-1)")
	var e31 := H.mk({"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": 1})
	var r31 := e31.apply({"act": "fill", "dir": "up"})
	t.eq([r31.verdict, int(e31.tab[1][1])], [VD.WRONG_MIN, 2], "cel (1,1) met up → 2, WRONG_MIN")
	var warm := [false]
	e31.changed.connect(func(fx): if str(fx.fx) == "cell" and bool(fx.warm): warm[0] = true)
	_until(e31, func(mc): return mc.ci == 6 and mc.cj == 7)
	t.eq(int(e31.tab[2][2]), 2, "tab[2][2] = 2")
	var snap := e31.snapshot()
	t.eq(e31.apply({"act": "fill", "dir": "left"}).verdict, VD.WRONG_MIN, "(6,7) met left → WRONG_MIN")
	t.eq(int(e31.tab[6][7]), 5, "waarde 5")
	t.ok(warm[0], "warm-fx")
	e31.restore(snap)
	e31.apply(e31.correct_move())
	t.eq(int(e31.tab[6][7]), 3, "eindwaarde nog 3")
	t.eq(e31.phase, PH.TRACE, "TRACE")
	var bumpdir := ""
	for d in ["diag", "up", "left"]:
		if not e31.carries(e31.ti, e31.tj, d):
			bumpdir = d
			break
	t.eq(e31.apply({"act": "step", "dir": bumpdir}).reason, "no_current", "terugstap zonder stroom → klem")
	t.ok(e31.log.coach_line(e31.log.of_verdict(VD.WRONG_MIN)[0]).begins_with("min(0+1, 1+1, 1+1) = 1, niet 2"),
		"coachzin WRONG_MIN: %s" % e31.log.coach_line(e31.log.of_verdict(VD.WRONG_MIN)[0]))
	H.unhook(e31)

	t.section("Schakelbord 7-2 (Oef. 62)")
	var e72 := H.mk({"machine": "edit", "a": "roestig", "b": "oesters", "approx": false, "want": -1})
	H.play(e72, bad)
	t.eq([e72.counters.relays, e72.distinct_sequences().size(), int(e72.tab[7][7])], [49, 3, 4], "49 relais, 3 reeksen, d = 4")

	t.section("Zoeklicht 8-1 (p. 79)")
	var e81 := H.mk({"machine": "edit", "a": "examen", "b": "de_armen_vouwen", "approx": true, "prefill_rows": 3,
		"want": 1})
	t.eq([e81.ci, e81.cj], [4, 1], "rijen 1..3 voorgevuld: cursor op (4,1)")
	H.play(e81, bad)
	t.eq(e81.counters.relays, 45, "45 relais")
	t.eq(e81.tab, TxReference.approx_table("examen", "de_armen_vouwen"), "tabel = p. 79")
	t.eq([H.hit_starts(e81), int(e81.hits[0].end)], [[1], 7], "match t[1..7] = e_armen")
	t.eq(e81.matches_found(), [{"start": 1, "end": 7}], "matches_found")
	var w81 := H.mk({"machine": "edit", "a": "examen", "b": "de_armen_vouwen", "approx": true, "prefill_rows": 3})
	_until(w81, func(mc): return mc.phase == PH.PICK_END)
	t.eq(w81.apply({"act": "pick_end", "j": 15}).verdict, VD.WRONG_END, "einde 15 → WRONG_END")
	H.play(w81, [0])
	t.ok(w81.false_alarms.size() >= 1, "vals spoor (vals alarm)")

	t.section("Zoeklicht 8-2 / 8-3")
	var e82 := H.mk({"machine": "edit", "a": "zoeken", "b": "koekjes_kweken", "approx": true, "want": -1})
	H.play(e82, bad)
	var st82: Array = []
	for mm in e82.matches_found():
		st82.append(int(mm.start))
	st82.sort()
	t.eq([e82.counters.relays, st82], [84, [8, 9, 10]], "84 relais, beginposities 8, 9, 10")
	var e83 := H.mk({"machine": "edit", "a": "test", "b": "beste_tekst", "approx": true, "want": -1})
	H.play(e83, bad)
	var m83: Array = []
	for mm in e83.matches_found():
		m83.append([int(mm.start), int(mm.end)])
	m83.sort()
	t.eq([e83.counters.relays, m83], [44, [[0, 3], [1, 3], [3, 6], [6, 10]]], "44 relais, 4 matches")
	t.eq(bad, [0], "perfect spel zonder problemen")
