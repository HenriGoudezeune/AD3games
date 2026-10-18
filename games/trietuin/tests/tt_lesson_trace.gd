extends SceneTree
## Leerpad-trace: speelt elk lesvoorbeeld (Kijk en Samen) met het orakel en print per stap de toestand, de
## verteltekst en de voorspelvragen met hun juiste antwoord, plus 3 Check-vragen per deel (nieuw voorbeeld).
## "$G" --headless --path . --script res://games/trietuin/tests/tt_lesson_trace.gd [-- deel[,deel]] [-- deel fase]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var only := PackedStringArray()
	if args.size() > 0:
		only = args[0].split(",")
	var phases := ["kijk", "samen"] if args.size() < 2 else [args[1]]
	for p in TtLessons.all_parts():
		if not only.is_empty() and not only.has(p.id):
			continue
		print("\n######## deel %d: %s (%s) — Zelf: %s" % [TtLessons.index_of_part(p.id) + 1, p.title, p.page, ", ".join(p.levels)])
		print("regel: ", _plain(p.rule))
		for ph in phases:
			print("\n== %s" % ph.to_upper())
			trace(p.id, ph)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for k in 3:
			var q := TtLessons.check_question(p.id, rng)
			print("CHECK %d: %s" % [k + 1, _plain(str(q.get("q", "??")))])
			for i in (q.get("options", []) as Array).size():
				print("   %s %s" % ["*" if (q.correct as Array).has(i) else " ", q.options[i]])
			print("   → ", _plain(str(q.get("explain", ""))))
	quit()


static func _plain(bb: String) -> String:
	var re := RegEx.new()
	re.compile("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	return re.sub(bb, "", true)


static func trace(id: String, phase: String) -> Array:
	var cfg := TtLessons.cfg(id, phase)
	var spec := TtLessons.spec(id, phase)
	var m := TtLevels.make_model(spec)
	var counts := {}
	var lines: Array = []
	var from_it := int(cfg.get("from_it", 0))
	var until_it := int(cfg.get("until_it", 0))
	var asks: Array = cfg.get("ask", [])
	for c in TtLevels.make_cards(spec):
		m.begin(c)
		print("-- kaart: %s %s" % [c.kind_name(), c.word if c.word != "" else ("j=%d" % c.j if c.j >= 0 else "")])
		var g := 0
		var last_it := -1
		while m.card != null and g < 400:
			g += 1
			var mv := m.correct_move()
			if str(mv.get("act", "none")) == "none":
				break
			if m is TtUkkonen:
				var um := m as TtUkkonen
				if from_it > 0 and um.it < from_it:
					m.apply(mv)
					continue
				if until_it > 0 and um.it > until_it:
					break
				if um.it != last_it:
					last_it = um.it
					print("   ", _plain(TtLessons.iteration_intro(um)))
			var act := str(mv.act)
			counts[act] = int(counts.get(act, 0)) + 1
			print("   [%s] %s" % [_plain(TtLessons.state_line(m)), str(mv)])
			var n := TtLessons.narrate(m, mv)
			print("     WAT: ", _plain(str(n.what)))
			print("     WAAROM: ", _plain(str(n.why)))
			lines.append(n)
			for a in asks:
				if str(a.on) == act and int(a.nth) == int(counts[act]):
					var q := TtLessons.predict(m, str(a.q), mv)
					print("     VRAAG: %s  %s  juist=%s" % [_plain(str(q.get("q", "(past niet)"))), str(q.get("options", [])), str(q.get("correct", []))])
			var r := m.apply(mv)
			if not bool(r.get("ok", true)):
				print("     !! orakelzet geweigerd: ", r)
		if m is TtUkkonen and until_it > 0 and (m as TtUkkonen).it > until_it:
			break
	print("   eind: ", m.serialize())
	return lines
