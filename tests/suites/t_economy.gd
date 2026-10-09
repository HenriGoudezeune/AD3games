extends RefCounted
## QA P1-6: perfect spel levert op elke dag minstens evenveel munten op als spel met fouten, en strikt meer zodra
## er echt een fout gemaakt is. Getest met verschillende denktijden (de combo mag niet afhangen van opstapelen).

const Bot := preload("res://tests/bot.gd")
const MODES := ["misroute_first", "wrong_side", "double_first", "ignore_customers", "dump_healthy", "no_dump", "idle_block"]


func _play(spec: DaySpec, mode: String, delay: float) -> Dictionary:
	var b := Bot.new()
	b.mistake_mode = mode
	b.delay = delay
	return b.play(DayDirector.new(), spec, 0.1, 400.0)


func run(t) -> void:
	t.section("P1-6 munten: perfect >= fouten")
	var specs := []
	for d in range(1, 8):
		specs.append(Days.get_day(d))
	specs.append(Days.get_day(7).phases[1])  # middag apart: daar vallen de klonen-fouten
	for spec in specs:
		var per_delay := []
		for delay in [0.0, 0.8, 1.6]:
			var perfect := _play(spec, "", delay)
			per_delay.append(int(perfect.coins))
			for mode in MODES:
				var r := _play(spec, mode, delay)
				if r.is_empty():
					continue  # idle_block op rustige dagen eindigt nooit (zo ontworpen)
				var tag := "%s d=%.1f %s: %d vs perfect %d" % [spec.id, delay, mode, r.coins, perfect.coins]
				t.ok(int(r.coins) <= int(perfect.coins), tag + " (niet meer)")
				if not r.mistakes.is_empty():
					t.ok(int(r.coins) < int(perfect.coins), tag + " (strikt minder bij fout)")
		t.ok(per_delay.min() == per_delay.max(), "%s: perfecte munten onafhankelijk van denktijd %s" % [spec.id, str(per_delay)])
