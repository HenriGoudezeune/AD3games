extends RefCounted
## T33–T38: levels, director, bot, scoring, opslag, generator, oorzaken (GDD §9).

const H := preload("res://games/scriptorium/tests/suites/sc_helpers.gd")
const V := ScCodes.Verdict
const INK := {"0-1": 0, "0-2": 39, "0-3": 0, "1-1": 22, "1-2": 28, "1-3": 59, "1-4": 59, "1-5": 59, "2-1": 5, "2-2": 33,
	"2-3": 55, "2-4": 68, "2-5": 0, "3-1": 1, "3-2": 5, "3-3": 0, "3-4": 1, "4-1": 7, "4-2": 0, "4-3": 9, "4-4": 0,
	"4-5": 22, "4-6": 13, "5-1": 10, "5-2": 4, "5-3": 14, "5-4": 0, "5-5": 20, "6-1": 0, "6-2": 0, "6-3": 0, "6-4": 0,
	"6-5": 0, "C": 56}


func run(t) -> void:
	_t33_t34(t)
	_t35(t)
	_t36(t)
	_t37(t)
	_t38(t)
	_director(t)
	_unlock(t)
	_wake(t)


func _t33_t34(t) -> void:
	t.section("T33/T34 elk level met de bot")
	for id in ScLevels.ids():
		var spec := ScLevels.get_spec(id)
		t.ok(spec != null, "spec " + id)
		if spec == null:
			continue
		t.eq(spec.optimum.ink, INK[id], id + ": optimum inkt")
		var bad := [0]
		var snaps := [0]
		var bot := ScLevelBot.new("")
		var rep := bot.play(spec, 0.05, 3600.0, func(dd: ScDirector) -> void:
			if dd.tool != null and not dd.tool.is_done():
				if not H.snap_roundtrip(dd.tool):
					snaps[0] = int(snaps[0]) + 1
				var inv := dd.tool.invariants()
				if not inv.is_empty():
					H._bad(bad, str(inv)))
		t.ok(not rep.is_empty(), id + ": level eindigt")
		if rep.is_empty():
			continue
		t.eq(rep.n_stars, 3, id + ": 3 sterren " + str(rep.star_labels))
		t.eq(rep.counters.ink, INK[id], id + ": inkt = optimum")
		t.eq(rep.mistakes.size(), 0, id + ": geen misstappen")
		t.eq(snaps[0], 0, id + ": snapshot-roundtrip na elke zet")
		t.eq(bad[0], 0, id + ": invarianten " + str(bad))
		for r in rep.readings:
			if not bool(r.get("demo", false)):
				t.ok(bool(r.equal), "%s: voorlezing stage %d: %s = %s" % [id, int(r.stage), str(r.read), str(r.original)])
			t.eq(int(r.pigeons), 1, id + ": één duif")
		t.ok(int(rep.points) > 0, id + ": punten > 0")
		t.eq((rep.structures as Array).size(), spec.stages.size(), id + ": structuren per stage")
		for s in rep.structures:
			t.eq(JSON.stringify(s.yours), JSON.stringify(s.correct), "%s stage %d: jouw werk = het juiste" % [id, int(s.stage)])
	# lezingen van de levels met verwachte teksten
	var rep2 := ScLevelBot.new("").play(ScLevels.get_spec("6-1"))
	t.eq(rep2.read, "geen loon", "6-1 keten trommel → plank")
	var rep3 := ScLevelBot.new("").play(ScLevels.get_spec("C"))
	t.eq(rep3.read, "sanctus sanctus sanctus", "Codex: drie werktuigen terug")
	t.eq(rep3.counters.zeros, 14, "Codex: 14 nullen")


func _t35(t) -> void:
	t.section("T35 orakelconsistentie")
	var problems := [0]
	var checked := [0]
	for id in ScLevels.ids():
		var spec := ScLevels.get_spec(id)
		var carry := {}
		for st in spec.stages:
			var tl := H.mk(st, carry)
			var g := 0
			while not tl.is_done() and g < 2000:
				g += 1
				var snap := tl.snapshot()
				for m in tl.impossible_moves():
					var r := tl.apply(m)
					checked[0] += 1
					if bool(r.ok):
						H._bad(problems, "%s: onmogelijke zet %s werd aanvaard" % [id, str(m)])
					tl.restore(snap)
				for m in tl.wrong_moves():
					var r2 := tl.apply(m)
					checked[0] += 1
					if not bool(r2.ok) or int(r2.verdict) == V.OK:
						H._bad(problems, "%s: foute zet %s → %s" % [id, str(m), str(r2)])
					tl.restore(snap)
				var mv := tl.correct_move()
				var r3 := tl.apply(mv)
				checked[0] += 1
				if not bool(r3.ok) or int(r3.verdict) != V.OK:
					H._bad(problems, "%s: orakel %s → %s" % [id, str(mv), str(r3)])
					break
			carry = tl.output()
	t.eq(problems[0], 0, "orakel/fout/onmogelijk consistent " + str(problems))
	t.ok(checked[0] > 1000, "veel zetten gecontroleerd (%d)" % checked[0])


func _t36(t) -> void:
	t.section("T36 opslag")
	var old := ScSave.path
	ScSave.path = "user://scriptorium_test_save.json"
	ScSave.reset()
	t.eq(ScSave.load_data().stars, {}, "leeg")
	ScSave.set_stars("1-1", 2)
	ScSave.set_stars("1-1", 1)
	t.eq(ScSave.get_stars("1-1"), 2, "maximum blijft")
	ScSave.set_stars("1-1", 3)
	t.eq(ScSave.get_stars("1-1"), 3, "verhoogd")
	t.ok(ScSave.set_best("1-1", 300), "beste punten")
	t.ok(not ScSave.set_best("1-1", 200), "geen record")
	t.eq(ScSave.add_highscore(500, "abc", "14/10"), 1, "rang 1")
	t.eq(ScSave.add_highscore(700, "def", "14/10"), 1, "nieuwe rang 1")
	t.eq(ScSave.add_highscore(600, "ghi", "14/10"), 2, "rang 2")
	t.eq(ScSave.highscores()[0].name, "DEF", "naam in hoofdletters")
	for i in 10:
		ScSave.add_highscore(1000 + i, "x", "")
	t.eq(ScSave.highscores().size(), 10, "top-10")
	t.eq(ScSave.add_highscore(1, "low", ""), 0, "te laag")
	ScSave.set_setting("music", 0.5)
	t.eq(ScSave.setting("music", 1.0), 0.5, "instelling")
	t.ok(ScSave.add_seal("1-1", "notasboom"), "zegel")
	t.ok(not ScSave.add_seal("1-1", "notasboom"), "zegel al gehad")
	t.eq(ScSave.seals("1-1"), ["notasboom"], "zegels")
	var d := ScSave.load_data()
	ScSave.save_data(d)
	t.eq(JSON.stringify(ScSave.load_data()), JSON.stringify(d), "roundtrip")
	ScSave.reset()
	ScSave.path = old


func _t37(t) -> void:
	t.section("T37 generator")
	var a := ScTextGen.new(42)
	var b := ScTextGen.new(42)
	for r in 20:
		var x := a.wake_round(r)
		var y := b.wake_round(r)
		t.eq(JSON.stringify(x), JSON.stringify(y), "deterministisch r=%d" % r)
		t.eq((x.letters as Array).size(), mini(4 + r, 12), "k = min(4 + r, 12)")
		var ok := true
		for w in x.weights:
			ok = ok and int(w) >= 1 and int(w) <= 1 + 2 + 2 * r
		t.ok(ok, "gewichten in [1, 3 + 2r]")
		t.eq(str(x.read_text).length(), 8 if r % 4 == 3 else 0, "leesstrook elke 4e ronde")
	t.ok(JSON.stringify(ScTextGen.new(1).wake_round(5)) != JSON.stringify(ScTextGen.new(2).wake_round(5)), "seed telt")
	t.ok(is_equal_approx(ScTextGen.round_time(0, 4), 2.5 * 3 + 4.0), "rondetijd r=0")
	t.ok(is_equal_approx(ScTextGen.round_time(40, 12), 1.2 * 11 + 4.0), "rondetijd minimum 1,2 s")


func _t38(t) -> void:
	t.section("T38 oorzaak")
	var dd := ScDirector.new()
	dd.start(ScLevels.get_spec("2-2"))
	var keep_seq := -1
	var g := 0
	while not dd.finished and g < 200:
		g += 1
		var lt := dd.tool as ScLivingTree
		if keep_seq < 0 and lt.phase == ScCodes.Phase.CLIMB and lt.i == 2:
			dd.apply({"act": "keep"})
			keep_seq = dd.log.size() - 1
			while keep_seq >= 0 and str(dd.log.entry(keep_seq).type) != "KEEP":
				keep_seq -= 1
			continue
		dd.apply(dd.correct_move())
	var rep := dd.report
	t.eq(rep.read, "graggga", "voorlezing graggga")
	t.eq(rep.mistakes.size(), 1, "één misstap")
	t.eq(int(rep.mistakes[0].seq), keep_seq, "misstap = de keep")
	var first := int(rep.readings[0].first_diff)
	t.eq(first, 3, "eerste afwijking op positie 3")
	t.eq(int(dd.log.cause_of(first).seq), keep_seq, "cause_of wijst naar de keep")
	t.ok((dd.log.entry(keep_seq).affects as Array).has(3), "affects bevat 3")
	var gb := dd.log.of_type("GARBLED")
	t.eq(gb.size(), 1, "GARBLED gelogd")
	t.eq(int(gb[0].data.cause_seq), keep_seq, "GARBLED → keep")
	t.ok(dd.log.coach_line(dd.log.entry(keep_seq)).contains("g[1,6]"), "coachzin noemt g[1,6]: " +
		dd.log.coach_line(dd.log.entry(keep_seq)))
	t.eq(dd.log.notes_ref(dd.log.entry(keep_seq)), "Algoritme 11 · notas p. 95", "verwijzing")
	t.eq(rep.n_stars, 0, "onzin: geen sterren")
	t.ok(dd.resume_from(keep_seq), "herneem vanaf de keep")
	t.ok(not dd.finished, "level loopt weer")
	g = 0
	while not dd.finished and g < 200:
		g += 1
		dd.apply(dd.correct_move())
	t.eq(dd.report.read, "graag", "na hernemen: graag")
	t.eq(dd.report.mistakes.size(), 0, "misstap verdwenen uit de log")
	t.eq(dd.report.n_stars, 2, "hernemen telt als hulp: ★★")
	t.eq(dd.resumes, 1, "één keer hernomen")
	dd.dispose()


func _director(t) -> void:
	t.section("director, scoring, bot-foutmodi")
	var spec := ScLevels.get_spec("1-1")
	var dd := ScDirector.new()
	var started: Array = []
	var reads: Array = []
	dd.stage_started.connect(func(i: int, _tl: ScTool) -> void: started.append(i))
	dd.reading_started.connect(func(r: Dictionary) -> void: reads.append(r))
	dd.start(spec)
	t.eq(started, [0], "stage_started")
	dd.apply({"act": "bind", "a": 0, "b": 1})
	t.ok(dd.can_undo(), "terugnemen kan")
	t.ok(dd.undo(), "terugnemen")
	t.eq(dd.log.mistakes().size(), 0, "log afgekapt")
	t.eq(dd.hint(), {"act": "bind", "a": 0, "b": 3}, "hint = b+s (p. 85)")
	while not dd.finished:
		dd.apply(dd.correct_move())
	t.eq(reads.size(), 1, "één voorlezing")
	t.eq(dd.report.n_stars, 2, "hint + terugnemen: ★★")
	t.eq([dd.hints, dd.undos], [1, 1], "tellers hulp")
	dd.dispose()
	# twee duiven
	var b := ScLevelBot.new("first")
	var rep := b.play(ScLevels.get_spec("1-1"))
	t.eq([rep.pigeons, rep.n_stars, rep.read], [2, 1, "boosdoeer"], "1-1 fout paar: 2 duiven, ★")
	t.ok(dd.log.coach_line({"verdict": V.TWO_PIGEONS, "data": {"ink": 23, "opt": 22}}).contains("tweede duif"),
		"coachzin tweede duif")
	# perfect ≥ elke foutmodus
	for id in ["0-2", "1-1", "2-2", "2-3", "3-2", "4-1", "4-2", "5-1", "5-2", "6-1", "6-2"]:
		var perfect := ScLevelBot.new("").play(ScLevels.get_spec(id))
		for mode in ["first", "every", "bump", "hint", "undo", "random", "resume"]:
			var r := ScLevelBot.new(mode, 7).play(ScLevels.get_spec(id))
			t.ok(not r.is_empty(), "%s %s eindigt" % [id, mode])
			if r.is_empty():
				continue
			t.ok(int(perfect.points) >= int(r.points), "%s: perfect %d ≥ %s %d" % [id, int(perfect.points), mode,
				int(r.points)])
			t.ok(int(perfect.n_stars) >= int(r.n_stars), "%s: sterren perfect ≥ %s" % [id, mode])
			if mode in ["hint", "undo", "bump"]:
				t.ok(int(r.n_stars) <= 2 or mode == "bump", "%s %s: geen ★★★" % [id, mode])
	var idle := ScLevelBot.new("idle").play(ScLevels.get_spec("1-1"), 0.5, 20.0)
	t.ok(idle.is_empty(), "idle: level eindigt niet vanzelf")


func _unlock(t) -> void:
	t.section("ontsluiten")
	var st := {}
	t.ok(ScLevels.is_unlocked("0-1", st), "0-1 open")
	t.ok(not ScLevels.is_unlocked("0-2", st), "0-2 dicht")
	t.ok(ScLevels.is_unlocked("0-3", {"0-1": 1, "0-2": 1}) , "0-3 na 0-2")
	t.ok(not ScLevels.is_unlocked("1-1", {"0-1": 1}), "hoofdstuk 1 dicht")
	t.ok(ScLevels.is_unlocked("1-1", {"0-1": 1, "0-2": 1}), "hoofdstuk 1 open (0-3 is P1)")
	t.ok(not ScLevels.is_unlocked("nachtwake", {}), "Nachtwake dicht")
	t.ok(ScLevels.is_unlocked("nachtwake", {"1-2": 1}), "Nachtwake na 1-2")
	var all := {}
	for id in ScLevels.ids():
		if ScLevels.priority_of(id) == "P0":
			all[id] = 1
	t.ok(ScLevels.is_unlocked("C", all), "Codex na alle P0")
	all.erase("6-3")
	t.ok(not ScLevels.is_unlocked("C", all), "Codex dicht zonder 6-3")
	var p0 := 0
	for id in ScLevels.ids():
		if ScLevels.get_spec(id).priority == "P0":
			p0 += 1
		t.eq(ScLevels.get_spec(id).priority, ScLevels.priority_of(id), id + " prioriteit")
	t.eq(p0, 25, "25 P0-levels")


func _wake(t) -> void:
	t.section("Nachtwake")
	var rep := ScLevelBot.new("").play_wake(42, 6)
	t.eq(rep.rounds, 6, "6 rondes")
	t.eq(rep.lives, 3, "3 kaarsen")
	t.ok(int(rep.points) > 6 * 50, "punten: %d" % int(rep.points))
	var dd := ScDirector.new()
	dd.start(ScLevels.endless_spec(0, 42))
	var w := dd.wrong_moves()
	t.ok(not w.is_empty(), "foute paren bestaan")
	var r := dd.apply(w[0])
	t.eq([r.verdict, dd.lives], [V.WRONG_PAIR, 2], "touw knapt: een kaars minder")
	dd.tick(100.0)
	t.eq(dd.lives, 1, "kaars opgebrand: nog een kaars minder")
	t.ok(dd.tool.stage_index >= 1 or dd.rounds >= 1, "Zeno werkte de ronde af")
	var g := 0
	while not dd.finished and g < 100:
		g += 1
		dd.tick(100.0)
	t.ok(dd.finished, "de dageraad")
	t.eq(dd.lives, 0, "geen kaarsen meer")
	dd.dispose()
	var idle := ScLevelBot.new("idle").play_wake(3, 50, 0.5)
	t.eq(idle.lives, 0, "idle: dageraad")
	var four := ScLevelBot.new("").play_wake(9, 4)
	var read_ok := false
	for rd in four.readings:
		if bool(rd.receive) and bool(rd.equal) and str(rd.original).length() == 8:
			read_ok = true
	t.ok(read_ok, "leesronde in ronde 4")
