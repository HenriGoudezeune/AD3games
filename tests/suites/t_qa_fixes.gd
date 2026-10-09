extends RefCounted
## Regressietests voor de QA-fixronde (design/QA.md) in core-gebied.

const Bot := preload("res://tests/bot.gd")


func run(t) -> void:
	t.section("P1-3 wereld staat stil tijdens de sorteertafel / animatie-lock")
	var dd := DayDirector.new()
	dd.start(Days.get_day(5))
	dd.tick(0.01, 0.01)
	var storm := dd.take_front()
	dd.model.drop(storm, dd.model.index_of(storm.hv))
	dd.tick(4.0, 4.0)   # tweede pakje verschijnt intussen (slow-mo is aan de gameplay-kant)
	dd.model.double_dir()
	dd.model.begin_split(dd.model.correct_move().bucket_id)
	t.ok(dd.is_world_frozen(), "bevroren tijdens split")
	var belt := dd.belt()
	var prog := []
	for p in belt:
		prog.append(dd.belt_progress(p.id))
	var t0 := dd.time
	var left := dd.burst_left(storm.id)
	dd.tick(30.0, 30.0)
	var prog2 := []
	for p in belt:
		prog2.append(dd.belt_progress(p.id))
	t.eq(prog2, prog, "band schuift niet op")
	t.eq(dd.time, t0, "speltijd staat stil")
	t.eq(dd.belt().size(), belt.size(), "geen spawns, niets valt")
	t.eq(dd.burst_left(storm.id), left, "burst-timer staat stil")
	t.eq(dd.model.lost.size(), 0, "niets kwijt")
	dd.model.auto_resolve()
	t.ok(not dd.is_world_frozen(), "na de split loopt de wereld weer")
	dd.set_world_hold(true)
	t0 = dd.time
	dd.tick(5.0, 5.0)
	t.eq(dd.time, t0, "set_world_hold(true) bevriest")
	dd.set_world_hold(false)
	dd.tick(1.0, 1.0)
	t.eq(dd.time, t0 + 1.0, "set_world_hold(false) hervat")

	t.section("P1-5 / P2-5 klanten")
	var bot := Bot.new()
	dd = DayDirector.new()
	var r4 := bot.play(dd, Days.get_day(4))
	t.eq([r4.customers_ok, r4.customers_total], [5, 5], "dag 4: 5/5 klanten")
	t.ok(float(r4.time) < 60.0, "dag 4: geen lange dode tijd op het einde (%.1f s)" % r4.time)
	dd = DayDirector.new()
	var r5 := bot.play(dd, Days.get_day(5))
	t.ok(int(r5.customers_total) >= 2, "dag 5: meerdere klanten (%d)" % r5.customers_total)
	t.eq(r5.stars, [true, true, true], "dag 5: nog altijd 3 sterren")

	t.section("P1-8 optimum inclusief klanten")
	t.eq(r5.opt_total.reads, int(r5.opt.reads) + int(r5.customers_total), "rapport: opt_total.reads = opt + klanten")
	t.eq(int(r5.reads), int(r5.opt_total.reads), "dag 5 perfect: L == opt_total")
	t.eq(dd.optimum_live().reads, int(r5.opt_total.reads), "optimum_live() aan het einde == opt_total")

	t.section("P1-9 dag 7 rapportregel")
	dd = DayDirector.new()
	var r7 := bot.play(dd, Days.get_day(7))
	t.ok(str(r7.note).contains("Oefening 4"), "middag: Oef. 4-regel")
	t.ok(str(r7.all_reports[0].note).contains("Geen bits meer"), "ochtend: uitleg falen")
	var lost := dd.model.log.of_type("LOST")
	t.eq(lost.size(), 0, "middag: niets kwijt")
