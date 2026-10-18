extends SceneTree
## Leerpad-hulpscript: speelt elk les-voorbeeld (HDLessons.PARTS) met het orakel en print per stap de verteltekst,
## de voorspelvragen met hun juiste antwoord, L/S per pakje en de eindtoestand; daarna voorbeeld-Check-vragen.
## "$G" --headless --path . --script res://tools/lesson_trace.gd [-- deel]

func _clean(s: String) -> String:
	var r := RegEx.new()
	r.compile("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	return r.sub(s, "", true).replace("[lb]", "[")


func _init() -> void:
	var only := ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	for P in HDLessons.PARTS:
		if only != "" and P.id != only:
			continue
		for phase in ["kijk", "samen"]:
			var s := HDLessons.spec(P.id, phase)
			var m := ExtHashModel.new()
			m.setup(s.n, s.g, s.a0)
			m.load_layout(s.start_layout)
			m.allow_dump = s.overflow_bin
			var c: Dictionary = P[phase]
			print("== %s / %s   start a=%d g=%d  %s" % [P.id, phase, m.a, m.g, m.describe()])
			var count := {}
			var asks: Array = c.get("ask", [])
			var cost: bool = c.get("cost", false)
			var items := []
			for k in s.keys:
				items.append({"hv": HashUtil.from_bits(k.hv)})
			for cu in s.customers:
				items.append({"cust": HashUtil.from_bits(cu.hv)})
			for it in items:
				var r0 := m.reads
				var w0 := m.writes
				if it.has("cust"):
					var mv := {"action": "serve"}
					count["serve"] = int(count.get("serve", 0)) + 1
					_ask(m, asks, "serve", count, mv, {"hv": it.cust})
					var nn := HDLessons.narrate(m, mv, {"hv": it.cust})
					print("   [serve] ", _clean(nn.what), " | ", _clean(nn.why))
					m.lookup(m.index_of(it.cust), it.cust)
				else:
					var p := m.new_parcel(it.hv)
					for g in 60:
						var mv := m.correct_move(p if g == 0 else null)
						if mv.action == "none":
							break
						var act := str(mv.action)
						count[act] = int(count.get(act, 0)) + 1
						var ctx := {"parcel": p, "cost": cost, "hv": p.hv}
						_ask(m, asks, act, count, mv, ctx)
						if phase == "samen" and c.get("ask_each", "") != "" and act == "drop":
							var q := HDLessons.predict(m, str(c.ask_each), mv, ctx)
							print("   ? ", _clean(q.q), "  -> ", ", ".join((q.correct as Array).map(func(i): return q.options[i])))
						var nn := HDLessons.narrate(m, mv, ctx)
						print("   [%s] %s | %s" % [act, _clean(nn.what), _clean(nn.why)])
						match act:
							"drop": m.drop(p, int(mv.dir_index))
							"double", "fail":
								m.double_dir()
								if act == "fail":
									break
							"split": m.begin_split(int(mv.bucket_id))
							"assign": m.assign(int(mv.parcel_id), int(mv.side))
							"retry": m.retry_blocked()
							"dump":
								m.dump(p)
					if cost:
						print("   = totaal %s: L+%d S+%d" % [HashUtil.bits(it.hv, m.n), m.reads - r0, m.writes - w0])
			print("   eind a=%d  %s  L=%d S=%d" % [m.a, m.describe(), m.reads, m.writes])
	print("== Check-vragen (voorbeelden, seed 7)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for P in HDLessons.PARTS:
		if only != "" and P.id != only:
			continue
		for k in 2:
			var q := HDLessons.check_question(P.id, rng)
			var fig := ExtHashModel.new()
			fig.setup(5, 2, 1)
			fig.restore(q.fig.snapshot)
			print("   %s: [%s] %s  opties: %s  -> %s  (%s)" % [P.id, fig.describe(), _clean(q.q), " / ".join(q.options),
				", ".join((q.correct as Array).map(func(i): return q.options[i])), _clean(q.explain)])
	quit()


func _ask(m: ExtHashModel, asks: Array, act: String, count: Dictionary, mv: Dictionary, ctx: Dictionary) -> void:
	for a in asks:
		if str(a.on) == act and int(a.nth) == int(count[act]):
			var q := HDLessons.predict(m, str(a.q), mv, ctx)
			print("   ? ", _clean(q.q), "  opties: ", " / ".join(q.options), "  -> ", ", ".join((q.correct as Array).map(func(i): return q.options[i])))
