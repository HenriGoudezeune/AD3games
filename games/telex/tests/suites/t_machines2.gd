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

	t.section("T38 (deel) orakel/klem/fout per fase — rk, bmh")
	for sp in [RK23, RK22, RK21, {"machine": "bmh", "z": "salsa", "cards": "stamp"},
			{"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
				"cards": "prefilled"},
			{"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all", "cards": "none"}]:
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
