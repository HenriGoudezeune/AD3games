extends RefCounted
## Levels via TtDirector + TtLevelBot: T32 (snapshot), T33 (perfecte bot), T34 (orakel), T35 (sap), T36 (layout),
## foutmodi, director (hint/terugspoelen/SWARM/geduld), opslag, ontgrendeling, vrije tuin.

const V := TtCodes.Verdict
const H := preload("res://games/trietuin/tests/suites/tt_helpers.gd")

var h := H.new()


func run(t) -> void:
	_specs(t)
	_t33_t32(t)
	_t34_wrong_moves(t)
	_t35(t)
	_t36(t)
	_wasp_story(t)
	_director(t)
	_save(t)
	_unlock(t)
	_endless(t)


func _specs(t) -> void:
	t.section("TtLevels: specs")
	var ids := TtLevels.ids()
	t.eq(ids.size(), 20, "20 levels")
	t.eq(TtLevels.ids("P0").size(), 16, "16 P0-levels")
	t.eq(Array(TtLevels.ids("P0")), ["1-1", "1-2", "1-3", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "4-1", "4-2", "4-3",
		"4-4", "4-5", "5-1", "5-2"], "P0 zoals §10")
	for id in ids:
		var s := TtLevels.get_spec(id)
		t.ok(s != null and s.id == id, id + ": spec")
		if s == null:
			continue
		t.ok(s.title != "" and s.intro != "" and s.notes_ref != "", id + ": titel/intro/notasverwijzing")
		t.eq(s.stars.size(), 3, id + ": 3 sterren")
		t.ok(not s.cards.is_empty(), id + ": kaarten")
		var m := TtLevels.make_model(s)
		t.ok(m != null and m.invariants().is_empty(), id + ": startmodel geldig")
		for i in 3:
			t.ok(TtScoring.star_label(s.stars[i]) != "", id + ": sterlabel %d" % i)
		var o := TtLevels.optimum(s)
		if s.optimum.has("sap"):
			t.eq(int(o.sap), int(s.optimum.sap), id + ": optimum sap")
		if s.expect_end != "":
			t.notation(str(o.end), s.expect_end, id + ": optimum eindboom")
		if s.optimum.has("comparisons"):
			t.eq(int(o.comparisons), int(s.optimum.comparisons), id + ": optimum vluchtlengte")
	t.ok(TtLevels.get_spec("9-9") == null, "onbekend level")
	t.ok(TtLevels.endless().endless, "vrije tuin")


func _t33_t32(t) -> void:
	for id in TtLevels.ids():
		t.section("T33/T32 perfecte bot " + id)
		var spec := TtLevels.get_spec(id)
		var bad := {"inv": 0, "snap": 0}
		var bot := TtLevelBot.new()
		var rep := bot.play(spec, 0.1, 900.0, func(dd: TtDirector):
			if not dd.model.invariants().is_empty():
				bad.inv += 1
			var s1 := dd.model.snapshot()
			var m2 := TtLevels.make_model(spec)
			m2.restore(s1)
			if m2.snapshot() != s1:
				bad.snap += 1
			var js = JSON.parse_string(JSON.stringify(s1))
			if not js is Dictionary:
				bad.snap += 1)
		if not t.ok(not rep.is_empty(), id + ": level eindigt"):
			continue
		t.eq(bad.inv, 0, id + ": invariants na elke zet")
		t.eq(bad.snap, 0, id + ": snapshot → restore → snapshot identiek (en JSON-baar)")
		t.eq(rep.stars, [true, true, true], id + ": 3 sterren")
		t.eq((rep.mistakes as Array).size(), 0, id + ": 0 misstappen")
		t.eq(float(rep.bloom_ratio), 1.0, id + ": Bloei 100 %")
		if spec.optimum.has("sap"):
			t.eq(int(rep.sap_used), int(spec.optimum.sap), id + ": sap == optimum")
		if spec.expect_end != "":
			t.ok(bool(rep.end_exact), id + ": eindboom == expect_end (%s)" % str(rep.end))
		t.ok(int(rep.honey) > 0, id + ": honing")


## T34 + foutpaden: in elke fase van elke perfecte run wordt elke foute zet aanvaard met verdict ≠ OK (of
## geweigerd met een Ukkonen-verdict) en elke onmogelijke zet geweigerd zonder de staat te wijzigen.
func _t34_wrong_moves(t) -> void:
	t.section("T34 orakel + foute/onmogelijke zetten per fase")
	var stats := {"wrong": 0, "wrong_bad": 0, "imp": 0, "imp_bad": 0, "oracle_bad": 0}
	var phases := {}
	for id in TtLevels.ids():
		var spec := TtLevels.get_spec(id)
		var bot := TtLevelBot.new()
		bot.play(spec, 0.1, 900.0, func(dd: TtDirector):
			var m := dd.model
			if m.card == null:
				return
			phases["%d:%s" % [m.kind, TtCodes.phase_name(m.phase)]] = true
			var snap := m.snapshot()
			var cm := m.correct_move()
			var m0 := TtLevels.make_model(spec)
			m0.restore(snap)
			var r0 := m0.apply(cm)
			if not r0.ok or int(r0.verdict) != V.OK:
				stats.oracle_bad += 1
			for w in m.wrong_moves():
				var m2 := TtLevels.make_model(spec)
				m2.restore(snap)
				var r := m2.apply(w)
				stats.wrong += 1
				if str(w.act) == "place":
					continue   # plantvolgorde is nooit fout (enkel langere vluchten, GDD §3.3)
				if (int(r.verdict) == V.OK or int(r.verdict) == V.BUMP) and str(r.reason) != "no_sap":
					stats.wrong_bad += 1
					if stats.wrong_bad <= 3:
						t.ok(false, "%s: foute zet %s gaf %s" % [id, str(w), str(r)])
				if not m2.invariants().is_empty():
					stats.wrong_bad += 1
			for w in m.impossible_moves():
				var m3 := TtLevels.make_model(spec)
				m3.restore(snap)
				var before := m3.snapshot()
				before.erase("verdicts")
				var r2 := m3.apply(w)
				var after := m3.snapshot()
				after.erase("verdicts")
				stats.imp += 1
				if r2.ok or (after != before and str(r2.reason) != "no_sap"):
					stats.imp_bad += 1
					if stats.imp_bad <= 3:
						t.ok(false, "%s: onmogelijke zet %s gaf %s" % [id, str(w), str(r2)]))
	t.eq(stats.oracle_bad, 0, "orakelzet altijd OK")
	t.eq(stats.wrong_bad, 0, "foute zetten: verdict ≠ OK (%d getest)" % stats.wrong)
	t.eq(stats.imp_bad, 0, "onmogelijke zetten: klonk, staat gelijk (%d getest)" % stats.imp)
	t.ok(stats.wrong > 300 and stats.imp > 100, "genoeg zetten getest: %s" % str(stats))
	t.ok(phases.size() >= 18, "veel fasen gedekt: %s" % str(phases.keys()))


func _t35(t) -> void:
	t.section("T35 sap")
	var o := TtLevels.optimum(TtLevels.get_spec("1-2"))
	t.eq([int(o.peak), int(o.sap)], [55, 50], "1-2: piek 55, eind 50")
	var m21 := TtLevels.make_model(TtLevels.get_spec("2-1"))
	t.eq(m21.sap_used(), 48, "2-1 start 48")
	t.eq(int(TtLevels.optimum(TtLevels.get_spec("2-1")).sap), 30, "2-1 eind 30")
	t.eq(int(TtLevels.optimum(TtLevels.get_spec("4-1")).sap), 80, "4-1: 80")
	t.eq(int(TtLevels.optimum(TtLevels.get_spec("4-2")).sap), 44, "4-2: 44")
	var bm := TtLevels.make_model(TtLevels.get_spec("3-4")) as TtBeds
	bm.begin(TtLevels.make_cards(TtLevels.get_spec("3-4"))[0])
	t.eq([int(bm.beds[0].array_sap), int(bm.beds[0].ternary_sap)], [45, 54], "3-4 bed A: array 45 / ternary 54")
	t.eq([int(bm.beds[1].array_sap), int(bm.beds[1].ternary_sap)], [189, 54], "3-4 bed B: array 189 / ternary 54")
	t.eq([str(bm.beds[0].best), str(bm.beds[1].best)], ["array", "ternary"], "beste keuzes")
	var r := bm.apply({"act": "bed", "bed": 0, "choice": "ternary"})
	t.eq(r.verdict, V.WRONG_BED, "bed A rankboom: WRONG_BED")
	t.ok(int(bm.beds[0].blown.size()) > 0, "sap op: zaadjes waaien weg")
	t.eq(bm.log.coach_line(bm.log.entries[-1]), "|A| = 5, 2 kinderen gemiddeld: 5 pointers vs. 6.", "coachzin Oef. 20")
	r = bm.apply({"act": "bed", "bed": 0, "choice": "array"})
	t.ok(r.ok and r.verdict == V.OK, "herplanten met array")
	r = bm.apply({"act": "bed", "bed": 1, "choice": "ternary"})
	t.ok(r.done, "beide bedden bloeien")
	t.ok(not bm.first_choice_ok(), "eerste keuze niet juist")


func _t36(t) -> void:
	t.section("T36 layout")
	var rect := Rect2(0, 220, 1920, 860 - 220)
	var checked := 0
	for id in TtLevels.ids():
		var spec := TtLevels.get_spec(id)
		if spec.expect_end == "":
			continue
		var m := TtLevels.make_model(spec)
		if m is TtSuffixTree:
			m.load_notation(spec.expect_end)
		elif m is TtTernary:
			m.load_notation(spec.expect_end)
		elif m is TtPatricia:
			m.load_notation(spec.expect_end)
		else:
			m.load_notation(spec.expect_end)
		var rn := m.render_nodes()
		var a := TtLayout.compute(rn, m.kind, rect, true, m.alphabet.letters)
		var b := TtLayout.compute(m.render_nodes(), m.kind, rect, true, m.alphabet.letters)
		t.ok(a == b, id + ": deterministisch")
		var leaves: Array = []
		var inside := true
		for d in rn:
			if not a.has(int(d.id)):
				inside = false
				continue
			var pnt: Vector2 = a[int(d.id)]
			if not rect.grow(1.0).has_point(pnt):
				inside = false
			if int(d.type) == TtNode.Type.LEAF:
				leaves.append(pnt)
		t.ok(inside, id + ": alle toppen binnen het tuinvlak")
		var min_d := 1e9
		for i in leaves.size():
			for k in range(i + 1, leaves.size()):
				min_d = minf(min_d, (leaves[i] as Vector2).distance_to(leaves[k]))
		t.ok(min_d >= 60.0, id + ": vruchten overlappen niet (min. afstand %.0f px)" % min_d)
		# wortel onderaan, kinderen erboven
		var root_p: Vector2 = a[m.root]
		t.ok(root_p.y >= rect.end.y - 1.0, id + ": wortel onderaan")
		checked += 1
	t.ok(checked >= 17, "layout van %d eindbomen" % checked)
	var top := TtLayout.compute(TtTrie.new().setup(TtAlphabet.dna(), TtLevels.F13).render_nodes(), TtCodes.Kind.TRIE,
		rect, false)
	t.ok((top[0] as Vector2).y <= rect.position.y + 1.0, "notas-weergave: wortel bovenaan")


func _wasp_story(t) -> void:
	t.section("2-2 wespenbedrog via de director")
	var bot := TtLevelBot.new("pluck_wasp")
	var dd := TtDirector.new()
	dd.start(TtLevels.get_spec("2-2"))
	var rep := bot.run(dd)
	t.eq(rep.stars, [true, false, false], "★ maar geen ★★ na diefstal")
	var last := dd.cards[-1]
	t.eq(str(last.outcome.result), "not_found", "laatste bestelling vindt een lege knop")
	t.ok(not TtScoring.bee_success(last), "en mislukt")
	var fail := {}
	for b in rep.bloom:
		if str(b.word) == "AAAAABAAAAABC_":
			fail = b
	t.ok(not fail.is_empty() and not bool(fail.ok), "Bloei: AAAAABAAAAABC_ faalt")
	var cause := dd.model.log.entries[int(fail.get("cause_seq", 0))]
	t.eq(int(cause.card), dd.cards[2].id, "oorzaak = de eerste wesp")
	var has_neg := false
	for x in rep.breakdown:
		if str(x.label) == "gestolen vruchten" and int(x.amount) < 0:
			has_neg = true
	t.ok(has_neg, "honing: gestolen vruchten negatief")
	dd.dispose()


func _director(t) -> void:
	t.section("director: hint, terugspoelen, rapport")
	var spec := TtLevels.get_spec("1-1")
	var perfect := TtLevelBot.new().play(spec)
	var rh := TtLevelBot.new("hint").play(spec)
	t.eq(rh.stars, [true, true, false], "hint: ★★ blijft, ★★★ weg")
	t.eq(int(rh.hints), 1, "1 hint")
	var rr := TtLevelBot.new("rewind").play(spec)
	t.eq(rr.stars, [true, true, false], "terugspoelen: ★★ blijft, ★★★ weg")
	t.eq(int(rr.rewinds), 1, "1 keer teruggespoeld")
	t.eq(int(rr.honey), int(perfect.honey), "terugspoelen: honing zoals perfect")
	var rf := TtLevelBot.new("first").play(spec)
	t.eq(rf.stars, [true, false, false], "eerste zet fout: ★")
	t.ok(int(rf.honey) < int(perfect.honey), "minder honing")
	var mis: Array = rf.mistakes
	t.ok(mis.size() >= 1 and TtEventLog.new().coach_line(mis[0]) != "", "misstap met coachzin")
	t.ok(not (mis[0].before as Dictionary).is_empty(), "misstap heeft before-snapshot (herbeleving)")
	# herbeleving: restore(entry.before) in een tweede model
	var m2 := TtLevels.make_model(spec)
	m2.restore(mis[0].before)
	t.ok(m2.invariants().is_empty() and m2.card != null, "herbeleving: tuin van dat moment")
	var r2 := m2.apply(mis[0].hint)
	t.ok(r2.ok and r2.verdict == V.OK, "de juiste zet (hint) werkt in de herbeleving")
	# rewind na een misstap wist de misstap
	var dd := TtDirector.new()
	dd.start(spec)
	dd.next_card()
	dd.model.apply({"act": "move", "letter": "A"})
	t.eq(dd.mistakes().size(), 1, "1 misstap")
	t.ok(dd.rewind(), "terugspoelen")
	t.eq(dd.mistakes().size(), 0, "misstap vervallen")
	t.ok(dd.model.card == null and dd.cards[0].state == "waiting", "kaart terug in de windrij")
	t.ok(dd.next_card() == dd.cards[0], "dezelfde kaart opnieuw")
	dd.dispose()
	# 2-4: geen hints
	var d24 := TtDirector.new()
	d24.start(TtLevels.get_spec("2-4"))
	d24.next_card()
	t.eq(d24.hint(), {}, "2-4: geen hints")
	d24.dispose()
	# 3-2: leeshulp FULL voor de eerste 3 kaarten
	var d32 := TtDirector.new()
	d32.start(TtLevels.get_spec("3-2"))
	var hl := []
	for i in 5:
		d32.next_card()
		hl.append(d32.letter_hint())
		d32.model.auto_finish_card()
	t.eq(hl, [0, 0, 0, 1, 1], "3-2: FULL, FULL, FULL, CURSOR…")
	d32.dispose()
	t.section("director: SWARM (1-4)")
	var r14 := TtLevelBot.new().play(TtLevels.get_spec("1-4"))
	t.eq(r14.stars, [true, true, true], "perfect: 3 sterren (combo ×5)")
	t.ok(int(r14.max_combo) >= 5, "combo ×5")
	var ri := TtLevelBot.new("idle").play(TtLevels.get_spec("1-4"), 0.1, 200.0)
	t.eq(ri.is_empty(), true, "idle: geen einde vanzelf? (kaarten wachten)")
	var dsw := TtDirector.new()
	dsw.start(TtLevels.get_spec("1-4"))
	var expired := []
	dsw.card_expired.connect(func(c, why): expired.append(why))
	for i in 1000:
		dsw.tick(0.1)
	t.ok(expired.has("blown"), "een vierde zaadje blaast het oudste weg")
	t.ok(expired.has("patience"), "bijen verliezen hun geduld")
	t.ok(not dsw.all_done(), "zaadjes blijven wachten (max. 3)")
	var left := dsw.waiting()
	var only_seeds := left.size() <= 3
	for c in left:
		if c.kind != TtCodes.CardKind.SEED:
			only_seeds = false
	t.ok(only_seeds, "enkel ≤ 3 zaadjes wachten nog")
	var rep := dsw.finish()
	t.eq(rep.stars, [false, false, false], "geen sterren")
	H.unhook(dsw)
	dsw.dispose()
	t.section("director: geduld in 4-4")
	var d44 := TtDirector.new()
	d44.start(TtLevels.get_spec("4-4"))
	d44.next_card()
	for i in 260:
		d44.tick(0.1)
	t.eq(d44.cards[0].state, "expired", "inspecteur vertrekt na 25 s")
	t.eq(d44.model.card, null, "geen actieve kaart meer")
	d44.dispose()


func _save(t) -> void:
	t.section("TtSave")
	var old := TtSave.path
	TtSave.path = "user://trietuin_test_save.json"
	TtSave.reset()
	t.eq(TtSave.get_stars("1-1"), 0, "leeg")
	TtSave.set_stars("1-1", 2)
	TtSave.set_stars("1-1", 1)
	t.eq(TtSave.get_stars("1-1"), 2, "houdt het maximum")
	t.ok(TtSave.set_best("1-1", 100), "record")
	t.ok(not TtSave.set_best("1-1", 50), "geen record")
	t.eq(TtSave.get_best("1-1"), 100, "beste honing")
	t.eq(TtSave.add_highscore(300, "hen", "2026-10-13"), 1, "eerste highscore: rang 1")
	t.eq(TtSave.add_highscore(500, "abc", "2026-10-13"), 1, "nieuwe eerste")
	t.eq(TtSave.add_highscore(100, "xyz", "2026-10-13"), 3, "derde")
	for i in 10:
		TtSave.add_highscore(1000 + i, "q", "d")
	t.eq(TtSave.highscores().size(), 10, "max 10")
	t.eq(TtSave.add_highscore(1, "low", "d"), 0, "te laag: 0")
	t.eq(str(TtSave.highscores()[0].name), "Q", "naam 3 hoofdletters")
	TtSave.set_setting("shake", 50)
	t.eq(int(TtSave.setting("shake", 100)), 50, "instelling")
	t.eq(TtSave.setting("onbekend", "x"), "x", "default")
	t.ok(TtSave.is_unlocked("1-2") == false, "1-2 dicht zonder ster op 1-1? (1-1 heeft 2)") if false else t.ok(TtSave.is_unlocked("1-2"), "1-2 open (1-1 ★★)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TtSave.path))
	TtSave.path = old


func _unlock(t) -> void:
	t.section("ontgrendeling")
	var st := {}
	t.ok(TtLevels.is_unlocked("1-1", st), "1-1 altijd")
	t.ok(not TtLevels.is_unlocked("1-2", st), "1-2 dicht")
	st["1-1"] = 1
	t.ok(TtLevels.is_unlocked("1-2", st), "1-2 open na 1-1 ★")
	t.ok(not TtLevels.is_unlocked("2-1", st), "zomer dicht")
	st["1-2"] = 1
	st["1-3"] = 1
	t.ok(TtLevels.is_unlocked("2-1", st), "zomer open na alle P0 van de lente")
	t.ok(not TtLevels.is_unlocked("vrij", st), "vrije tuin dicht zonder 1-4")
	t.ok(TtLevels.is_unlocked("vrij", st, PackedStringArray(["1-1", "1-2", "1-3"])), "vrije tuin na 1-3 als 1-4 ontbreekt")
	st["1-4"] = 1
	t.ok(TtLevels.is_unlocked("vrij", st), "vrije tuin na 1-4")
	for id in ["2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "4-1", "4-2", "4-3", "4-4", "4-5"]:
		st[id] = 1
	t.ok(TtLevels.is_unlocked("5-1", st), "finale open na alle winter-P0")
	t.eq(TtLevels.next_id("1-4"), "2-1", "volgend level")


func _endless(t) -> void:
	t.section("vrije tuin")
	var perfect := TtLevelBot.new()
	var dd := TtDirector.new()
	dd.start(TtLevels.endless(), 42)
	perfect.run(dd, 0.1, 180.0)
	t.ok(not dd.finished, "perfect: na 180 s nog bezig")
	t.eq(dd.misses, 0, "0 missers")
	t.ok(dd.scoring.honey > 200, "honing %d" % dd.scoring.honey)
	t.ok(dd.model.invariants().is_empty(), "boom geldig")
	t.ok(dd.model.sap_budget > 60, "sap groeit aan")
	dd.dispose()
	var idle := TtDirector.new()
	idle.start(TtLevels.endless(), 7)
	TtLevelBot.new("idle").run(idle, 0.1, 300.0)
	t.ok(idle.finished, "idle: game over")
	t.eq(idle.misses, 3, "na 3 missers")
	idle.dispose()
	var g := TtWordGen.new(5, TtAlphabet.dna())
	var g2 := TtWordGen.new(5, TtAlphabet.dna())
	var ws := PackedStringArray()
	var same := true
	var ok_shape := true
	for i in 200:
		var w := g.next_word(ws)
		if w != g2.next_word(ws):
			same = false
		if not w.ends_with("_") or w.length() < 3 or w.length() > 8 or w.count("_") != 1:
			ok_shape = false
		ws.append(w)
	t.ok(same, "TtWordGen deterministisch")
	t.ok(ok_shape, "woorden van 2–7 letters + _")
