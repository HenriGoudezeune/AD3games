extends RefCounted
## Dagen (§5.2 / §11-tabel), DayDirector met perfecte bot (A5) en foute bots (A6 + gevolgen), endless.

const V := ExtHashModel.Verdict
const Bot := preload("res://tests/bot.gd")


func _types(log: EventLog, verdict: int) -> Array:
	var out := []
	for e in log.entries:
		if int(e.verdict) == verdict:
			out.append(e.type)
	return out


## Verbreekt alle verbindingen op de signalen van dd (lambdas die dd vangen maken anders een referentiecyclus).
static func unhook(dd: DayDirector) -> void:
	for sig in dd.get_signal_list():
		for c in dd.get_signal_connection_list(sig.name):
			dd.disconnect(sig.name, c.callable)


func run(t) -> void:
	_optimum(t)
	_perfect_bot(t)
	_day7(t)
	_a6(t)
	_mistake_bots(t)
	_belt(t)
	_endless(t)


func _optimum(t) -> void:
	t.section("Days.optimum == §11")
	t.eq(Days.count(), 7, "7 dagen")
	for i in range(1, 8):
		var s := Days.get_day(i)
		t.ok(s != null and s.title != "" and s.intro != "" and s.icon != "", "dag %d: spec compleet" % i)
		var leaf: DaySpec = s.phases[-1] if not s.phases.is_empty() else s
		var o := Days.optimum(s)
		var ee := leaf.expect_end
		t.eq(o.a, int(ee.a), "dag %d: a" % i)
		t.eq(o.end, _describe(ee.layout), "dag %d: eindtoestand" % i)
		t.eq(o.reads, int(ee.reads) - leaf.customers.size(), "dag %d: L (zonder klanten)" % i)
		t.eq(o.writes, int(ee.writes), "dag %d: S" % i)
		t.eq(o.doubles, int(ee.doubles), "dag %d: verdubbelingen" % i)
		t.eq(o.splits, int(ee.splits), "dag %d: splitsingen" % i)
	var morning := Days.optimum(Days.get_day(7).phases[0])
	t.eq(morning.end, _describe(Days.get_day(7).phases[0].expect_end.layout), "dag 7 ochtend: eindtoestand")
	t.ok(morning.fail, "dag 7 ochtend: faalt")
	t.eq(Days.optimum(Days.get_day(7)).dumps, 2, "dag 7 middag: 2 klonen in de bak")
	t.eq(Days.get_day(6).keys[3].label, "45", "dag 6 sleutellabels")
	t.ok(Days.get_day(0).endless, "endless")
	t.eq(Days.get_day(8), null, "ongeldige dag")


func _describe(layout: Array) -> String:
	var parts := PackedStringArray()
	for e in layout:
		parts.append("%s{%s}" % [e.label, ",".join(PackedStringArray(e.hvs))])
	return " ".join(parts)


func _perfect_bot(t) -> void:
	t.section("A5 perfecte bot via DayDirector")
	for i in range(1, 7):
		var spec := Days.get_day(i)
		var dd := DayDirector.new()
		var bot := Bot.new()
		var bad := [0]
		var report := bot.play(dd, spec, 0.1, 900.0, func(d):
			if not d.model.invariants().is_empty():
				bad[0] += 1)
		t.ok(not report.is_empty(), "dag %d: dag eindigt" % i)
		if report.is_empty():
			continue
		t.eq(bad[0], 0, "dag %d: invariants na elke stap" % i)
		t.eq(report.stars, [true, true, true], "dag %d: 3 sterren" % i)
		t.ok(report.end_state_ok, "dag %d: eindtoestand == expect_end" % i)
		t.eq(report.mistakes.size(), 0, "dag %d: 0 fouten" % i)
		t.eq(dd.model.misplaced().size(), 0, "dag %d: niets verdwaald" % i)
		var ee := spec.expect_end
		t.eq([report.doubles, report.splits], [int(ee.doubles), int(ee.splits)], "dag %d: dubbels/splits" % i)
		t.eq(report.writes, int(ee.writes), "dag %d: S" % i)
		t.eq(report.reads, report.opt.reads + report.customers_total, "dag %d: L = optimum + klanten" % i)
		t.eq(report.lost, 0, "dag %d: niets kwijt" % i)
		t.eq(dd.scoring.rep, spec.reputation, "dag %d: volle reputatie" % i)
		t.ok(report.coins > 0, "dag %d: munten > 0 (%d)" % [i, report.coins])
		if i == 4:
			t.eq([report.customers_ok, report.customers_total], [5, 5], "dag 4: 5 klanten gevonden")
			t.eq(report.reads, 17, "dag 4: L 12 + 5")
		if i == 5:
			t.ok(report.customers_total >= 1, "dag 5: klanten (%d)" % report.customers_total)
			t.eq(report.customers_ok, report.customers_total, "dag 5: alle klanten blij")
		if i == 1:
			t.ok(report.time <= 40.0, "dag 1: binnen 40 s (%.1f)" % report.time)
		# herbeleving: elke DOUBLE/SPLIT_BEGIN heeft een before-snapshot die restore'baar is
		for e in dd.model.log.entries:
			if e.type == "DOUBLE" or e.type == "SPLIT_BEGIN":
				if not t.ok(not e.before.is_empty(), "dag %d: snapshot bij %s" % [i, e.type]):
					break
				var replay := ExtHashModel.new()
				replay.restore(e.before)
				t.ok(replay.invariants().is_empty() and replay.correct_move().action == e.hint.action, "dag %d: herbeleving seq %d -> juiste zet %s" % [i, e.seq, e.hint.action])


func _day7(t) -> void:
	t.section("dag 7 (twee fasen)")
	var spec := Days.get_day(7)
	var dd := DayDirector.new()
	var refused := [0]
	var bursts := []
	var phases := []
	dd.phase_started.connect(func(i, s):
		phases.append(i)
		dd.model.double_refused.connect(func(): refused[0] += 1))
	dd.burst.connect(func(p): bursts.append(p.hv))
	var bot := Bot.new()
	var report := bot.play(dd, spec)
	unhook(dd)
	t.eq(phases, [0, 1], "ochtend + middag")
	t.eq(report.all_reports.size(), 2, "twee rapporten")
	var morning: Dictionary = report.all_reports[0]
	t.eq(morning.stars, [false, false, false], "ochtend: geen sterren")
	t.ok(morning.has_next_phase, "ochtend: has_next_phase")
	t.eq(int(morning.a), 5, "ochtend: a = 5")
	t.ok(morning.end_state_ok, "ochtend: eindtoestand (6 rekken, 4 leeg)")
	t.eq(refused[0], 1, "ochtend: double_refused")
	t.eq(bursts, [HashUtil.from_bits("10110")], "ochtend: buis barst")
	t.eq(morning.mistakes.size(), 0, "ochtend: falen van het algoritme is geen spelersfout")
	t.eq(report.stars, [true, true, true], "middag: 3 sterren")
	t.ok(report.end_state_ok, "middag: eindtoestand")
	t.eq([report.reads, report.writes], [9, 14], "middag: L9 S14")
	var dumped := dd.model.dumped.map(func(p): return HashUtil.bits(p.hv, 5))
	t.eq(dumped, ["11001", "00111"], "middag: bak = 2 klonen")
	t.ok(dd.model.dumped.all(func(p): return p.is_clone), "gedumpte pakjes zijn klonen")


func _a6(t) -> void:
	t.section("A6 bot verdubbelt eerst op dag 3")
	var dd := DayDirector.new()
	var bot := Bot.new()
	bot.mistake_mode = "double_first"
	var report := bot.play(dd, Days.get_day(3))
	t.ok(_types(dd.model.log, V.UNNEEDED_DOUBLE).size() >= 1, "log bevat UNNEEDED_DOUBLE")
	t.eq(report.stars[1], false, "★★ ontbreekt")
	t.eq(report.stars[0], true, "★ wel")
	t.ok(dd.model.a > 3, "muur breder")
	t.ok(dd.model.invariants().is_empty(), "invariants")
	var e: Dictionary = dd.model.log.mistakes()[0]
	t.eq(e.hint.action, "split", "hint: zagen")
	t.ok(dd.model.log.coach_line(e).contains("zagen volstond"), "chef: zagen volstond")
	t.ok(report.coach.size() >= 1, "rapport bevat chefzinnen")


func _mistake_bots(t) -> void:
	t.section("foute bots -> gevolgen in de log")
	# fout luik op dag 4: de klant voor 01101 vindt zijn pakje niet en loopt boos weg; oorzaak = de drop
	var dd := DayDirector.new()
	var bot := Bot.new()
	bot.mistake_mode = "misroute_first"
	var report := bot.play(dd, Days.get_day(4))
	var drops := dd.model.log.of_type("DROP")
	t.eq(int(drops[0].verdict), V.MISROUTED, "dag 4: eerste drop verdwaald")
	var angry := dd.model.log.of_type("CUSTOMER_ANGRY")
	t.eq(angry.size(), 1, "één boze klant")
	if angry.size() == 1:
		t.eq(int(angry[0].data.get("cause_seq", -1)), int(drops[0].seq), "boze klant linkt naar de drop")
		t.eq(HashUtil.bits(int(angry[0].data.hv), 5), "01101", "het verdwaalde pakje")
	t.eq(dd.scoring.rep, 4, "−1 ♥")
	t.eq(report.stars, [true, false, false], "★ maar geen ★★")
	t.eq([report.customers_ok, report.customers_total], [4, 5], "4/5 klanten")
	# verkeerde kant op dag 2
	dd = DayDirector.new()
	bot = Bot.new()
	bot.mistake_mode = "wrong_side"
	report = bot.play(dd, Days.get_day(2))
	t.eq(_types(dd.model.log, V.WRONG_SIDE).size(), 1, "dag 2: WRONG_SIDE")
	t.eq(dd.model.misplaced().size(), 1, "dag 2: één pakje verdwaald")
	t.eq(report.stars[1], false, "dag 2: geen ★★")
	t.ok(not report.end_state_ok, "dag 2: eindtoestand fout")
	# niets doen bij vastloper op dag 5 (realtime): buis barst na 12 s speltijd
	dd = DayDirector.new()
	bot = Bot.new()
	bot.mistake_mode = "idle_block"
	var burst_t := []
	dd.burst.connect(func(p): burst_t.append(dd.time))
	report = bot.play(dd, Days.get_day(5))
	unhook(dd)
	t.ok(burst_t.size() >= 1, "dag 5: burst")
	if burst_t.size() >= 1:
		t.ok(absf(burst_t[0] - 12.0) < 0.2, "burst na ~12 s speltijd (%.2f)" % burst_t[0])
	var lost := dd.model.log.of_type("LOST")
	t.ok(lost.size() >= 1 and lost[0].data.reason == "burst", "LOST burst in log")
	t.ok(dd.scoring.rep < 5, "reputatie gezakt")
	t.eq(report.stars[1], false, "geen ★★")
	t.ok(dd.model.invariants().is_empty(), "invariants")
	# klonen niet in de bak (dag 7 middag): kettingreactie tot de eindaanslag, dan barst de buis (niet excused)
	var spec7 := Days.get_day(7).phases[1]
	dd = DayDirector.new()
	bot = Bot.new()
	bot.mistake_mode = "no_dump"
	report = bot.play(dd, spec7)
	t.eq(dd.model.dumped.size(), 0, "geen klonen in de bak")
	var bursts := dd.model.log.of_type("LOST").filter(func(e): return e.data.reason == "burst")
	t.ok(bursts.size() >= 1 and not bursts[0].data.excused, "kloon barst de buis (fout)")
	t.eq(dd.model.a, 5, "muur tot de eindaanslag")
	t.eq(report.stars[1], false, "geen ★★")
	# gezond pakje in de bak
	dd = DayDirector.new()
	bot = Bot.new()
	bot.mistake_mode = "dump_healthy"
	report = bot.play(dd, spec7)
	t.eq(_types(dd.model.log, V.UNNEEDED_DUMP).size(), 1, "UNNEEDED_DUMP")
	t.eq(dd.scoring.rep, 4, "telt als kwijt (−1 ♥)")
	t.eq(report.stars[1], false, "geen ★★")
	# klanten negeren
	dd = DayDirector.new()
	bot = Bot.new()
	bot.mistake_mode = "ignore_customers"
	report = bot.play(dd, Days.get_day(4))
	t.eq(dd.model.log.of_type("CUSTOMER_ANGRY").size(), 5, "5 boze klanten")
	t.eq(dd.scoring.rep, 0, "reputatie 0")
	t.ok(report.failed, "depot gesloten")
	t.eq(report.stars, [false, false, false], "0 sterren")


func _belt(t) -> void:
	t.section("band")
	# RUSTIG: niets valt, pakjes schuiven aan, band stopt bij BELT_CAPACITY
	var dd := DayDirector.new()
	var spawned := []
	dd.parcel_spawned.connect(func(p): spawned.append(p))
	dd.start(Days.get_day(3))
	for i in 600:
		dd.tick(0.1, 0.1)
	var b := dd.belt()
	t.eq(b.size(), DayDirector.BELT_CAPACITY, "rustig: band vol, stopt met spawnen")
	t.eq(dd.belt_progress(b[0].id), 1.0, "voorste aan het einde")
	t.ok(absf(dd.belt_progress(b[1].id) - (1.0 - DayDirector.BELT_SPACING)) < 0.001, "tweede schuift aan")
	t.eq(dd.model.lost.size(), 0, "rustig: niets kwijt")
	t.ok(not dd.finished, "dag loopt nog")
	# set_held: geen opschuiven
	var p := b[2]
	dd.set_held(p.id, true)
	var before := dd.belt_progress(p.id)
	var nxt := dd.belt_progress(b[3].id)
	dd.tick(1.0, 1.0)
	t.eq(dd.belt_progress(p.id), before, "vastgehouden pakje schuift niet")
	t.ok(dd.belt_progress(b[3].id) > nxt, "volgende schuift door")
	var taken := dd.take(p.id)
	t.eq(taken, p, "take")
	t.eq(dd.belt_progress(p.id), -1.0, "niet meer op de band")
	# REALTIME: pakje valt van de band na belt_time
	dd = DayDirector.new()
	var fell := []
	dd.parcel_fell_off.connect(func(q): fell.append(dd.time))
	dd.start(Days.get_day(4))
	for i in 150:
		dd.tick(0.1, 0.1)
	unhook(dd)
	t.ok(fell.size() >= 1 and absf(fell[0] - 14.0) < 0.15, "realtime: eerste pakje valt na 14 s")
	t.eq(dd.model.log.of_type("LOST")[0].data.reason, "belt", "LOST belt")
	t.eq(dd.scoring.rep, 5 - fell.size(), "−1 ♥ per pakje")
	# set_held voorkomt vallen
	dd = DayDirector.new()
	dd.start(Days.get_day(4))
	dd.tick(0.01, 0.01)
	var q: Parcel = dd.belt()[0]
	dd.set_held(q.id, true)
	for i in 200:
		dd.tick(0.1, 0.1)
	t.ok(dd.belt().has(q), "vastgehouden pakje valt niet")
	# klanten: customers(), serve met fout luik kost geduld
	dd = DayDirector.new()
	dd.start(Days.get_day(4))
	var bot := Bot.new()
	bot.mistake_mode = "ignore_customers"
	for i in 210:
		bot.step(dd)
		dd.tick(0.1 * dd.world_time_scale(), 0.1)
	var cs := dd.customers()
	t.eq(cs.size(), 1, "klant aan de balie op t=21")
	if cs.size() == 1:
		var c: Dictionary = cs[0]
		var wrong := (dd.model.index_of(int(c.hv)) + (1 << dd.model.a) / 2) % (1 << dd.model.a)
		var pat_before := float(c.patience_left)
		var r := dd.serve(int(c.id), wrong)
		t.eq([r.found, r.verdict], [false, V.WRONG_LOOKUP], "fout luik")
		t.ok(absf(float(dd.customers()[0].patience_left) - (pat_before - 0.25 * 15.0)) < 0.001, "−25 % geduld")
		r = dd.serve(int(c.id), dd.model.index_of(int(c.hv)))
		t.eq([r.found, r.happy], [true, true], "juist luik: gevonden")
		t.eq(dd.customers().size(), 0, "klant weg")
	# burst_left
	dd = DayDirector.new()
	dd.start(Days.get_day(5))
	dd.tick(0.01, 0.01)
	var f := dd.take_front()
	dd.model.drop(f, dd.model.index_of(f.hv))
	t.ok(dd.model.is_alarm(), "11110 zit vast")
	t.eq(dd.world_time_scale(), 0.35, "slow-mo")
	dd.tick(2.0, 2.0)
	t.ok(absf(dd.burst_left(f.id) - 10.0) < 0.001, "burst_left")


func _endless(t) -> void:
	t.section("endless")
	t.eq(Days.endless_tempo(360.0).spawn_interval, 1.3, "spawn op 6 min")
	t.eq(Days.endless_tempo(180.0).spawn_interval, 2.5, "spawn op 3 min")
	t.eq(Days.endless_tempo(0.0).belt_time, 14.0, "band op 0")
	t.eq(Days.endless_tempo(600.0).belt_time, 8.0, "band minimum")
	var spec := Days.get_day(0)
	spec.generator.seed = 42
	var dd := DayDirector.new()
	var bot := Bot.new()
	var bad := [0]
	var clones := [0]
	dd.parcel_spawned.connect(func(p):
		if p.is_clone:
			clones[0] += 1)
	var report := bot.play(dd, spec, 0.1, 600.0, func(d):
		if not d.model.invariants().is_empty():
			bad[0] += 1)
	t.eq(bad[0], 0, "10 min bot: geen invariant-fouten")
	t.ok(dd.time > 100.0, "speeltijd %.0f s" % dd.time)
	t.eq(dd.model.misplaced().size(), 0, "niets verdwaald")
	t.ok(clones[0] >= 1, "kloonbursts na 180 s (%d klonen)" % clones[0])
	t.ok(dd.model.dumped.size() >= 1, "bot dumpt klonen (%d)" % dd.model.dumped.size())
	var non_excused := dd.model.log.mistakes().filter(func(e): return e.type != "LOST" and e.type != "CUSTOMER_ANGRY")
	t.eq(non_excused.size(), 0, "bot maakt geen algoritmische fouten")
	print("   endless: t=%.0f s, a=%d, rekken=%d, rep=%d, munten=%d, klonen=%d, gedumpt=%d, kwijt=%d" % [dd.time, dd.model.a, dd.model.buckets.size(), dd.scoring.rep, dd.scoring.coins, clones[0], dd.model.dumped.size(), dd.model.lost.size()])
