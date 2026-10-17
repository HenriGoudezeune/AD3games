extends RefCounted
## Leerpad (scripts/game/hd_lessons.gd): elk lesvoorbeeld speelt uit met het orakel, verteltekst en voorspelvragen
## zijn consistent met correct_move(), Check-vragen hebben een juist antwoord dat de core onafhankelijk bevestigt,
## voortgang/badges en de verplichte volgorde vóór elke dag.

const Bot := preload("res://tests/bot.gd")


func run(t) -> void:
	_specs(t)
	_narration(t)
	_checks(t)
	_progress(t)


func _specs(t) -> void:
	t.section("lessen: specs spelen uit")
	for P in HDLessons.PARTS:
		for phase in ["kijk", "samen"]:
			var s := HDLessons.spec(P.id, phase)
			t.ok(s != null and s.title != "", "%s/%s: spec" % [P.id, phase])
			var dd := DayDirector.new()
			var bot := Bot.new()
			var rep: Dictionary = bot.play(dd, s, 0.1, 300.0)
			t.ok(not rep.is_empty(), "%s/%s: les eindigt" % [P.id, phase])
			t.eq(dd.model.invariants().size(), 0, "%s/%s: invarianten" % [P.id, phase])
			if P.id == "faalt" and phase == "kijk":
				t.eq(dd.model.lost.size(), 1, "faalt/kijk: het pakje gaat verloren (a = n)")
			elif P.id == "faalt":
				t.eq(dd.model.dumped.size(), 1, "faalt/samen: 1 kloon in de bak")
			else:
				t.eq(dd.model.lost.size(), 0, "%s/%s: niets kwijt" % [P.id, phase])
			for sig in dd.get_signal_list():
				for c in dd.get_signal_connection_list(sig.name):
					dd.disconnect(sig.name, c.callable)


func _narration(t) -> void:
	t.section("lessen: verteltekst + voorspelvragen")
	for P in HDLessons.PARTS:
		var s := HDLessons.spec(P.id, "kijk")
		var m := ExtHashModel.new()
		m.setup(s.n, s.g, s.a0)
		m.load_layout(s.start_layout)
		m.allow_dump = s.overflow_bin
		for k in s.keys:
			var p := m.new_parcel(HashUtil.from_bits(k.hv))
			for g in 60:
				var mv := m.correct_move(p if g == 0 else null)
				if mv.action == "none":
					break
				var n := HDLessons.narrate(m, mv, {"parcel": p, "hv": p.hv, "cost": true})
				t.ok(str(n.what) != "", "%s: tekst voor %s" % [P.id, mv.action])
				t.ok(not str(n.what).contains("%"), "%s: geen open format in %s" % [P.id, mv.action])
				for kind in ["luik", "zet", "kant", "kost"]:
					var applies: bool = (kind == "luik" and mv.action == "drop") or (kind == "zet" and mv.action in ["double", "split"]) \
						or (kind == "kant" and mv.action == "assign") or (kind == "kost" and mv.action == "drop")
					if not applies:
						continue
					var q := HDLessons.predict(m, kind, mv, {"parcel": p})
					t.ok(not (q.correct as Array).is_empty(), "%s: %s heeft een juist antwoord" % [P.id, kind])
					var c0: String = q.options[q.correct[0]]
					match kind:
						"luik":
							t.eq(m.dir[HashUtil.from_bits(c0.trim_prefix("luik "))], m.dir[int(mv.dir_index)], "%s: luik wijst naar het juiste rek" % P.id)
						"zet":
							t.eq(c0.begins_with("Hendel"), mv.action == "double", "%s: zet" % P.id)
						"kant":
							t.eq(int(q.correct[0]), int(mv.side), "%s: kant" % P.id)
				match str(mv.action):
					"drop": m.drop(p, int(mv.dir_index))
					"double": m.double_dir()
					"fail":
						m.double_dir()
						break
					"split": m.begin_split(int(mv.bucket_id))
					"assign": m.assign(int(mv.parcel_id), int(mv.side))
					"retry": m.retry_blocked()
					"dump": m.dump(p)
		# fouten-uitleg bestaat voor elke soort
		for kind in ["drop", "double", "split", "serve", "dump"]:
			var e := HDLessons.explain_wrong(m, kind, {"idx": 0, "hv": 0, "parcel": m.new_parcel(0)}, {"action": "drop"})
			t.ok(e != "", "%s: uitleg %s" % [P.id, kind])


func _checks(t) -> void:
	t.section("lessen: Check-vragen (rapport)")
	var rng := RandomNumberGenerator.new()
	for P in HDLessons.PARTS:
		for seed in 25:
			rng.seed = 1000 + seed
			var q := HDLessons.check_question(P.id, rng)
			if not t.ok(not q.is_empty(), "%s: vraag gemaakt (seed %d)" % [P.id, seed]):
				continue
			t.ok((q.correct as Array).size() >= 1 and int(q.correct[0]) < (q.options as Array).size(), "%s: geldig antwoord" % P.id)
			var m := ExtHashModel.new()
			m.setup(5, 2, 1)
			m.restore(q.fig.snapshot)
			t.eq(m.invariants().size(), 0, "%s: figuur is geldig" % P.id)
			if not q.has("hv"):
				continue
			var hv := int(q.hv)
			var c0: String = q.options[q.correct[0]]
			match P.id:
				"luik":
					t.eq(m.dir[HashUtil.from_bits(c0.trim_prefix("luik "))], m.dir[m.index_of(hv)], "luik: juist rek")
				"kost":
					var r0 := m.reads
					var w0 := m.writes
					m.auto_insert(m.new_parcel(hv))
					t.eq(c0, "%d L + %d S" % [m.reads - r0, m.writes - w0], "kost: L/S klopt")
				"opnieuw":
					var d0 := m.doubles
					m.auto_insert(m.new_parcel(hv))
					t.eq(c0, "%d keer" % (m.doubles - d0), "opnieuw: aantal verdubbelingen")
				"verdubbelen", "splitsen":
					if (q.options as Array).size() == 3:
						var st := m.simulate_insert(hv)
						t.eq(c0.begins_with("Hendel"), str(st[0].act) == "double", "%s: eerste stap" % P.id)
				"faalt":
					var res := m.auto_insert(m.new_parcel(hv))
					t.eq(c0.begins_with("Ja"), res == "ok", "faalt: lukt of faalt")
			var sh := HDLessons.shuffled(q, rng)
			t.eq(sh.options[sh.correct[0]], c0, "%s: schudden behoudt het antwoord" % P.id)
	for d in range(1, 8):
		t.ok(HDLessons.report_parts(d).size() >= 1 and HDLessons.report_parts(d).size() <= 2, "dag %d: 1-2 rapportvragen" % d)


func _progress(t) -> void:
	t.section("lessen: voortgang en volgorde")
	var old := SaveData.path
	SaveData.path = "user://test_lessons_%d.json" % Time.get_ticks_usec()
	HDLessons.reset_progress()
	t.eq(HDLessons.pending_for_day(1), [{"part": "luik", "phase": "kijk"}, {"part": "luik", "phase": "samen"}], "dag 1: eerst luik")
	t.eq(HDLessons.pending_for_day(2).size(), 6, "dag 2 zonder voorkennis: luik, splitsen, verdubbelen")
	HDLessons.mark("luik", "kijk")
	t.eq(HDLessons.level("luik"), 1, "kijk gezien")
	t.eq(HDLessons.pending_for_day(1), [{"part": "luik", "phase": "samen"}], "kijk niet opnieuw verplicht")
	HDLessons.mark("luik", "samen")
	t.eq(HDLessons.pending_for_day(1).size(), 0, "dag 1 vrij")
	HDLessons.mark("luik", "check")
	t.eq(HDLessons.level("luik"), 3, "begrepen")
	# elke dag vraagt enkel delen die vóór of op die dag getoond worden
	var seen := {}
	for d in range(1, 8):
		for p in HDLessons.parts_for_day(d):
			seen[p] = true
		for P in HDLessons.PARTS:
			if int(P.day) <= d:
				t.ok(seen.has(P.id), "dag %d: deel %s is getoond" % [d, P.id])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	SaveData.path = old
