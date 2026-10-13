extends RefCounted
## Levels, director, scoring, opslag, generator, bot: T32 (rivaal), T35–T40, foutmodi.

const H := preload("res://games/telex/tests/suites/tx_helpers.gd")
const VD := TxCodes.Verdict
const PH := TxCodes.Phase


func _starts(rep: Dictionary) -> Array:
	var out: Array = []
	for h in rep.get("hits", []):
		if bool(h.real) and not out.has(int(h.start)):
			out.append(int(h.start))
	out.sort()
	return out


func run(t) -> void:
	t.section("TxLevels: ids, specs, ontgrendeling")
	t.eq(TxLevels.ids().size(), 27, "27 levels (incl. F)")
	var p0 := 0
	for id in TxLevels.ids():
		var s := TxLevels.get_spec(id)
		t.ok(s != null and s.stages.size() >= 1 and s.stars.size() == 3, "%s: spec met stages en 3 sterren" % id)
		if s.priority == "P0":
			p0 += 1
	t.eq(p0, 19, "19 P0-levels")
	t.ok(TxLevels.is_unlocked("1-1", {}), "1-1 open")
	t.ok(not TxLevels.is_unlocked("1-2", {}), "1-2 dicht")
	t.ok(TxLevels.is_unlocked("1-2", {"1-1": 1}), "1-2 open na 1-1")
	t.ok(not TxLevels.is_unlocked("1-3", {"1-1": 1}) and TxLevels.is_unlocked("1-3", {"1-1": 1, "1-2": 1}),
		"1-3 (P2) volgt het vorige P0-level (1-2)")
	t.ok(not TxLevels.is_unlocked("2-1", {"1-1": 3}), "dossier 2 dicht zolang 1-2 geen ster heeft")
	t.ok(TxLevels.is_unlocked("2-1", {"1-1": 1, "1-2": 1}), "dossier 2 open (1-3 is P2)")
	t.ok(TxLevels.is_unlocked("3-4", {"1-1": 1, "1-2": 1, "2-1": 1, "2-2": 1, "2-3": 1, "3-1": 1, "3-2": 1, "3-3": 1}),
		"3-4 (P1) open na 3-3")
	t.ok(not TxLevels.is_unlocked("N", {}), "Nachtdienst dicht")
	t.ok(TxLevels.is_unlocked("N", {"4-1": 1}), "Nachtdienst open met 4-1")
	var all_p0 := {}
	for id in TxLevels.ids():
		if TxLevels.priority_of(id) == "P0":
			all_p0[id] = 1
	t.ok(TxLevels.is_unlocked("F", all_p0), "finale open met alle P0")
	all_p0.erase("8-3")
	t.ok(not TxLevels.is_unlocked("F", all_p0), "finale dicht zonder 8-3")
	t.eq(TxLevels.get_spec("3-1").ghost, {"brute_ticks": 42}, "geest 3-1 = 42")
	t.eq(TxLevels.get_spec("2-2").ghost, {"brute_ticks": 29}, "geest 2-2 = 29")
	t.eq(TxLevels.get_spec("2-3").ghost, {"brute_ticks": 23}, "geest 2-3 = 23")

	t.section("T37 elk level met de bot: 3 sterren, tellers = optimum, treffers = §5")
	for id in TxLevels.ids():
		var spec := TxLevels.get_spec(id)
		var bad := [0]
		var bot := TxBot.new("", 1)
		var rep := bot.play(spec, 0.05, 2000.0, func(dd: TxDirector) -> void:
			if dd.machine != null and not dd.machine.invariants().is_empty():
				H._bad(bad, "%s: invariant %s" % [id, str(dd.machine.invariants())]))
		t.ok(not rep.is_empty(), "%s: level eindigt" % id)
		if rep.is_empty():
			continue
		t.eq(bad, [0], "%s: invarianten na elke zet" % id)
		t.eq(rep.n_stars, 3, "%s: 3 sterren (%s)" % [id, str(rep.star_labels)])
		t.eq(rep.mistakes.size(), 0, "%s: 0 misstappen" % id)
		var opt: Dictionary = spec.optimum
		for k in ["ticks", "wheel", "lamps", "relays"]:
			if opt.has(k):
				t.eq(int(rep.counters[k]), int(opt[k]), "%s: %s = optimum" % [id, k])
		if opt.has("rewind"):
			t.eq(int(rep.counters.rewind), int(opt.rewind), "%s: spoelmeter" % id)
		if spec.expect.has("hits") and spec.expect.hits is Array:
			t.eq(_starts(rep), spec.expect.hits, "%s: treffers" % id)
		if id != "F":
			var o := TxLevels.optimum(spec)
			for k in ["ticks", "wheel", "lamps", "relays"]:
				if opt.has(k):
					t.eq(int(o[k]), int(opt[k]), "%s: TxLevels.optimum %s" % [id, k])
		t.eq(rep.missed.size() + rep.false_alarms.size(), 0, "%s: niets gemist, geen vals alarm" % id)

	t.section("Finale: machinetijd en keuzes")
	var fr := TxBot.new("", 1).play(TxLevels.get_spec("F"), 0.05, 3000.0)
	t.eq(fr.get("machine_time", -1), 118, "51 + 34 + 33 = 118")
	t.eq(fr.get("found", -1), 7, "7 codewoorden")
	t.eq(fr.get("choices", {}), {"F-1": "kmp", "F-2": "shift_and_k", "F-3": "bmh"}, "beste keuzes")
	_finale_alternatives(t)

	t.section("T32 rivaal (3-5)")
	var dd := TxDirector.new()
	dd.start(TxLevels.get_spec("3-5"))
	var bot2 := TxBot.new("", 1)
	bot2.run(dd, 0.05, 200.0)
	var rv := dd.rival()
	t.eq(rv.tear_fronts, [5, 7, 9, 21, 26], "rivaal scheurt bij F = 5, 7, 9, 21, 26")
	t.eq(rv.hits, [], "en vindt niets")
	t.eq(dd.log.count_type("TEAR"), 0, "de Doorloper scheurt nooit")
	dd.dispose()
	var s5 := TxLevels.get_spec("3-5")
	s5.live.B = 5
	var d5 := TxDirector.new()
	d5.start(s5)
	TxBot.new("", 1).run(d5, 0.05, 200.0)
	t.eq([d5.rival().hits, d5.rival().tears], [[4, 16, 21], 0], "B = 5: rivaal vindt alle drie, geen scheur")
	d5.dispose()
	var d6 := TxDirector.new()
	d6.start(TxLevels.get_spec("3-5"))
	var slow := TxBot.new("", 1)
	slow.think = 7.0
	var rs := slow.run(d6, 0.05, 300.0)
	t.ok(d6.log.count_type("TEAR") > 0, "te trage beslissingen → scheur")
	t.ok(int(rs.get("n_stars", 0)) < 3, "geen ★★★ met een scheur")
	d6.dispose()
	var warn := [0]
	var d7 := TxDirector.new()
	d7.live_warning.connect(func(_s: float) -> void: warn[0] += 1)
	d7.start(TxLevels.get_spec("3-5"))
	TxBot.new("idle").run(d7, 0.05, 60.0)
	t.ok(warn[0] > 0, "live_warning vóór de scheur")
	d7.dispose()

	t.section("Ritme 5-3")
	var dr := TxDirector.new()
	var beats := [0]
	dr.beat.connect(func(_j: int) -> void: beats[0] += 1)
	dr.start(TxLevels.get_spec("5-3"))
	var rr := TxBot.new("", 1).run(dr, 0.02, 200.0)
	t.eq(beats[0], 44, "44 tellen")
	t.eq(rr.strak, 32, "32 kaarten strak")
	t.eq(rr.n_stars, 3, "3 sterren")
	dr.dispose()
	var di := TxDirector.new()
	di.start(TxLevels.get_spec("5-3"))
	var ri := TxBot.new("idle").run(di, 0.02, 200.0)
	var late := 0
	for m in ri.mistakes:
		if int(m.verdict) == VD.LATE:
			late += 1
	t.eq(late, 32, "niets doen: 32 × LATE (blanco na de tel)")
	t.eq(_starts(ri), [], "geen bellen")
	di.dispose()

	t.section("T35 tegenzet")
	var sb := H.mk({"machine": "sabotage", "target": "brute", "n": 12, "m": 4, "alphabet": "ab"}) as TxSabotage
	sb.apply({"act": "set", "which": "z", "i": 3, "ch": "b"})
	sb.apply({"act": "send"})
	t.eq([sb.last, sb.best], [36, 36], "z = aaab, t = a^12 → 36")
	t.eq(sb.apply({"act": "set", "which": "t", "i": 0, "ch": "c"}).reason, "range", "teken buiten het alfabet klemt")
	var sm := H.mk({"machine": "sabotage", "target": "bmh_min", "n": 16, "m": 4, "alphabet": "ab"}) as TxSabotage
	t.eq(sm.apply({"act": "finish"}).reason, "not_now", "finish zonder geldige poging klemt")
	sm.apply({"act": "send"})
	t.eq([sm.last, sm.last_valid, sm.best], [4, false, -1], "z = aaaa ⊂ a^16 → valid = false (telt niet)")
	var sk := H.mk({"machine": "sabotage", "target": "rk_calls", "n": 16, "m": 5, "alphabet": "01", "z_fixed": "00101",
		"q": 13}) as TxSabotage
	t.eq(sk.apply({"act": "set", "which": "z", "i": 0, "ch": "1"}).reason, "not_now", "vaste z")
	for i in 16:
		sk.apply({"act": "set", "which": "t", "i": i, "ch": "1"})
	sk.apply({"act": "send"})
	t.eq(sk.best, 12, "t = 1^16 → 12 controles")

	t.section("T36 snapshot-roundtrip na elke bot-zet, elk level")
	for id in TxLevels.ids():
		var bad3 := [0]
		TxBot.new("", 1).play(TxLevels.get_spec(id), 0.05, 2000.0, func(d: TxDirector) -> void:
			if d.machine != null and not H.snap_roundtrip(d.machine):
				H._bad(bad3, "%s: roundtrip in fase %s" % [id, TxCodes.phase_name(d.machine.phase)]))
		t.eq(bad3, [0], "%s: snapshot → restore → snapshot identiek" % id)

	t.section("T38 orakel/klem/fout per fase, elk level")
	for id in TxLevels.ids():
		if id == "F":
			continue
		t.eq(_oracle_level(TxLevels.get_spec(id)), [0, 0, 0], "%s: orakel OK, onmogelijk klemt, fout ≠ OK" % id)

	t.section("Foutmodi: perfect spel ≥ elke foutmodus")
	var modes := ["first", "every", "random", "bump", "hint", "undo"]
	for id in TxLevels.ids():
		if id == "F":
			continue
		var spec2 := TxLevels.get_spec(id)
		var perfect := TxBot.new("", 1).play(spec2, 0.05, 2000.0)
		var worse := 0
		var tested := 0
		for md in modes:
			for sd in ([1, 2, 3] if md == "random" else [1]):
				var rep2 := TxBot.new(md, sd).play(TxLevels.get_spec(id), 0.05, 2000.0)
				if rep2.is_empty():
					continue
				tested += 1
				if int(rep2.points) > int(perfect.points) or int(rep2.n_stars) > int(perfect.n_stars):
					worse += 1
					t.ok(false, "%s: modus %s/%d beter dan perfect (%d > %d)" % [id, md, sd, rep2.points, perfect.points])
		t.ok(tested >= 5 and worse == 0, "%s: perfect ≥ %d foutmodi" % [id, tested])
	var rf := TxBot.new("first", 1).play(TxLevels.get_spec("3-1"))
	t.ok(int(rf.n_stars) < 3 and rf.mistakes.size() >= 1, "3-1 foutmodus first: misstap, geen ★★★")
	var rh := TxBot.new("hint", 1).play(TxLevels.get_spec("4-1"))
	t.eq([rh.hints, rh.n_stars], [1, 2], "hint kost ★★★")
	var ru := TxBot.new("undo", 1).play(TxLevels.get_spec("7-1"))
	t.eq([ru.undos, ru.n_stars], [1, 2], "terugnemen kost ★★★")
	var rp := TxBot.new("plug:new_shift", 1).play(TxLevels.get_spec("6-1"))
	t.eq([rp.false_alarms.size(), rp.missed.size(), rp.n_stars], [1, 1, 0], "6-1 kabel nieuw ↓: vals alarm + gemist")
	var rk := TxBot.new("act:key", 1).play(TxLevels.get_spec("4-3"))
	t.ok(rk.mistakes.size() >= 1, "4-3 act:key: WRONG_KEY")
	t.ok(rk.mistakes[0].coach != "" and rk.mistakes[0].ref != "", "rapport: coachzin + notasverwijzing")

	t.section("Nachtdienst")
	var de := TxDirector.new()
	var tapes_seen := [0]
	de.tape_started.connect(func(_i: int, _s: TxLevelSpec) -> void: tapes_seen[0] += 1)
	de.start(TxLevels.endless_spec(0, 42))
	var be := TxBot.new("", 1)
	var g := 0
	while not de.finished and tapes_seen[0] < 4 and g < 200000:
		g += 1
		if not be.step(de, 0.05):
			de.tick(0.05)
	t.eq(tapes_seen[0], 4, "perfect: 4 linten gehaald")
	t.eq(de.lives, 3, "3 vertrouwenslampjes")
	var rep_e := de.finish()
	t.ok(int(rep_e.points) > 0 and rep_e.tapes.size() == 4, "rapport met 4 linten, punten %d" % int(rep_e.points))
	de.dispose()
	var dz := TxDirector.new()
	dz.start(TxLevels.endless_spec(0, 7))
	var rz := TxBot.new("idle").run(dz, 0.05, 2000.0)
	t.ok(dz.finished and dz.lives == 0, "niets doen: lampjes op, game over")
	t.ok((rz.get("tapes", []) as Array).size() >= 1, "minstens één lint")
	dz.dispose()

	t.section("T39 opslag")
	var old := TxSave.path
	TxSave.path = "user://telex_save_test.json"
	TxSave.reset()
	t.eq(TxSave.load_data(), {"version": 1, "stars": {}, "best": {}, "highscores": [], "settings": {}}, "leeg")
	TxSave.set_stars("3-1", 2)
	TxSave.set_stars("3-1", 1)
	t.eq(TxSave.get_stars("3-1"), 2, "set_stars houdt het maximum")
	TxSave.set_stars("3-1", 3)
	t.eq(TxSave.get_stars("3-1"), 3, "verhoogt")
	t.ok(TxSave.set_best("3-1", 500) and not TxSave.set_best("3-1", 400), "beste punten")
	t.eq(TxSave.get_best("3-1"), 500, "best 500")
	t.eq(TxSave.add_highscore(100, "abc", "13/10"), 1, "rang 1")
	t.eq(TxSave.add_highscore(300, "xyz", "13/10"), 1, "hogere score rang 1")
	t.eq(TxSave.add_highscore(200, "def", "13/10"), 2, "rang 2")
	for i in 10:
		TxSave.add_highscore(1000 + i, "zzz", "")
	t.eq(TxSave.highscores().size(), 10, "top-10")
	t.eq(TxSave.add_highscore(5, "low", ""), 0, "te laag: rang 0")
	t.eq(str(TxSave.highscores()[0].name), "ZZZ", "naam 3 hoofdletters")
	TxSave.set_setting("volume", 0.5)
	t.eq(TxSave.setting("volume", 1.0), 0.5, "instelling")
	t.eq(TxSave.setting("onbekend", 7), 7, "standaardwaarde")
	TxSave.record("4-1", {"n_stars": 2, "points": 77})
	t.eq([TxSave.get_stars("4-1"), TxSave.get_best("4-1")], [2, 77], "record(rapport)")
	t.ok(TxSave.is_unlocked("1-1") and not TxSave.is_unlocked("2-1"), "ontgrendeling via opslag")
	var f := FileAccess.open(TxSave.path, FileAccess.WRITE)
	f.store_string("{kapot")
	f.close()
	t.eq(TxSave.load_data().stars, {}, "corrupt bestand → standaard")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TxSave.path))
	TxSave.path = old

	t.section("T40 generator")
	var gen := TxTextGen.new(42)
	var bad4 := 0
	for k in 40:
		var tp := gen.tape(k)
		var tp2 := TxTextGen.new(42).tape(k)
		if tp != tp2:
			bad4 += 1
		var z := str(tp.z)
		var tx := str(tp.t)
		if z.length() != TxTextGen.z_length(k) or tx.length() < 60 or tx.length() > 90:
			bad4 += 1
		if not (tp.plants as Array).size() in [1, 2, 3] or not (tp.decoys as Array).size() in [2, 3, 4]:
			bad4 += 1
		var hits: Array = TxReference.bmh(z, tx, true).hits
		for pl in tp.plants:
			if not hits.has(int(pl)) or tx.substr(int(pl), z.length()) != z:
				bad4 += 1
		var pls: Array = tp.plants
		for a in pls.size():
			for b in range(a + 1, pls.size()):
				if absi(int(pls[a]) - int(pls[b])) < z.length():
					bad4 += 1
		for dpos in tp.decoys:
			if tx[int(dpos)] == "_":
				bad4 += 1
	t.eq(bad4, 0, "40 linten: deterministisch, lengtes, plants ⊆ BMH-treffers, geen overlap")
	t.ok(gen.tape(0) != TxTextGen.new(43).tape(0), "andere seed → ander lint")
	t.eq(TxTextGen.WORDS.size() >= 200, true, "≥ 200 woorden")
	t.eq([TxTextGen.z_length(0), TxTextGen.z_length(3), TxTextGen.z_length(30)], [4, 5, 9], "lengte van z")
	var es := TxLevels.endless_spec(5, 42)
	t.eq([es.live.v, es.live.B], [1.2 + 0.75, str(gen.tape(5).z).length() + 3], "v en B van lint 5")


## Alternatieve keuzes in de finale (GDD §5.10): Springer/Sjabloon scheuren in F-1, exacte machines vinden niets
## in F-2, de Doorloper loopt in F-3 uit zijn budget.
func _finale_alternatives(t) -> void:
	var res := {}
	for pick in [["F-1", "bmh"], ["F-1", "brute"], ["F-1", "shift_and"], ["F-2", "kmp"], ["F-2", "edit"],
			["F-3", "kmp"], ["F-3", "shift_and"], ["F-3", "brute"]]:
		var spec := TxLevels.get_spec("F")
		var dd := TxDirector.new()
		dd.start(spec)
		var bot := TxBot.new("", 1)
		var g := 0
		while not dd.finished and g < 400000:
			g += 1
			if not dd.pending_choice.is_empty():
				var tape := str(dd.pending_choice.stage.tape)
				dd.apply({"act": "pick_machine", "machine": pick[1] if tape == pick[0] else str(dd.pending_choice.stage.best)})
				continue
			if not bot.step(dd, 0.05):
				dd.tick(0.05)
		var found := 0
		var missed := 0
		var mt := 0
		for mc in dd.machines:
			if str(mc.stage.get("tape", "")) == pick[0] and bool(mc.stage.get("autoplay", false)):
				found += mc.found_count()
				missed += mc.missed.size()
				mt += mc.machine_time()
			elif str(mc.stage.get("tape", "")) == pick[0] and mc is TxEditBoard:
				found += mc.found_count()
				mt += mc.machine_time()
		res["%s/%s" % pick] = [found, missed, mt]
		dd.dispose()
	t.eq(res["F-1/bmh"][0], 0, "F-1 Springer (B < m): niets gevonden")
	t.eq(res["F-1/brute"][0], 0, "F-1 Sjabloon (B < m): niets gevonden")
	t.eq(res["F-1/shift_and"], [3, 0, 52], "F-1 Lampenbord: 3 treffers, 52 lampslagen")
	t.eq((res["F-2/kmp"] as Array).slice(0, 2), [0, 2], "F-2 exacte Doorloper: 2 gemist")
	t.eq(res["F-2/edit"], [2, 0, 204], "F-2 Zoeklicht: 2 matches, 204 relais")
	t.eq((res["F-3/kmp"] as Array).slice(0, 2), [1, 1], "F-3 Doorloper: budget op, @94 gemist")
	t.eq((res["F-3/shift_and"] as Array).slice(0, 2), [1, 1], "F-3 Lampenbord: budget op")
	t.eq((res["F-3/brute"] as Array).slice(0, 2), [1, 1], "F-3 Sjabloon: budget op")


## Speelt een level stage per stage met losse machines (gedeelde log) en controleert in elke toestand het orakel.
func _oracle_level(spec: TxLevelSpec) -> Array:
	var bad := [0, 0, 0]
	var carry := {}
	var log := TxEventLog.new()
	for i in spec.stages.size():
		var st: Dictionary = spec.stages[i]
		var mc := TxLevels.make_machine(st, carry, TxCodes.Mode.CALM)
		mc.log = log
		mc.stage_index = i
		mc.begin()
		var guard := 0
		while not mc.is_done() and guard < 5000:
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
				bad[0] += 1
				break
			var r3 := mc.apply(cm)
			if not bool(r3.ok) or int(r3.verdict) != VD.OK:
				bad[0] += 1
				break
		carry = mc.output()
	return bad
