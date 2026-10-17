extends RefCounted
## Leerpad (games/telex/design/LEARNING_PATH.md): elke les headless uitgespeeld zoals de coach dat doet
## (TxLessons.kijk_group / narrate_group / predict / tip / accepts / explain_wrong), voorspelvragen nagerekend tegen
## wat de machine daarna echt doet, foute zetten geweigerd met uitleg, Check-vragen (30 nieuwe voorbeelden per deel)
## nagerekend met een eigen, onafhankelijke berekening, en voortgang/wachtrij (eerste keer verplicht).

const PH := TxCodes.Phase


func run(t) -> void:
	var old_path := TxSave.path
	TxSave.path = "user://telex_test_lessons.json"
	TxSave.reset()
	t.section("leerpad: structuur")
	var ids := TxLessons.ids()
	t.eq(ids.size(), 16, "16 delen")
	var seen := {}
	for p in TxLessons.all_parts():
		t.ok(not seen.has(p.id), "uniek id %s" % p.id)
		seen[p.id] = true
		for k in ["title", "rule", "idea", "page", "levels", "kijk", "samen"]:
			t.ok(p.has(k), "%s heeft %s" % [p.id, k])
		for lv in p.levels:
			t.ok(TxLevels.has_level(str(lv)), "%s: level %s bestaat" % [p.id, lv])
	# volgorde = opbouw: de poorten liggen in campagnevolgorde
	var last := -1
	for p in TxLessons.all_parts():
		var gi := Array(TxLevels.IDS).find(str(p.levels[0]))
		t.ok(gi >= last, "%s: poort %s niet vóór de vorige" % [p.id, p.levels[0]])
		last = gi
	# elk P0-level (behalve de finale) wordt door minstens één deel geoefend
	for id in TxLevels.ids():
		if id != "F" and TxLevels.priority_of(id) == "P0":
			t.ok(not TxLessons.parts_of_level(id).is_empty(), "level %s heeft een leerpaddeel" % id)
	for id in ids:
		for ph in ["kijk", "samen"]:
			_play(t, id, ph)
	_checks(t)
	_progress(t)
	TxSave.reset()
	TxSave.path = old_path


## Speelt één les uit met de logica van de coach.
func _play(t, id: String, ph: String) -> void:
	t.section("les %s/%s" % [id, ph])
	var cfg := TxLessons.cfg(id, ph)
	var sp := TxLessons.spec(id, ph)
	t.ok(sp != null and not sp.stages.is_empty() and sp.mode == TxCodes.Mode.CALM, "spec (CALM)")
	var dd := TxDirector.new()
	dd.start(sp)
	var count := {}
	var asked := 0
	var steps := 0
	var bad := 0
	var guard := 0
	while not dd.finished and guard < 600:
		guard += 1
		var mc := dd.machine
		if cfg.has("until_phase") and mc.phase == int(cfg.until_phase):
			break
		var mv := dd.correct_move()
		if str(mv.get("act", "none")) == "none":
			dd.tick(0.05)
			continue
		var group: Array = TxLessons.kijk_group(mc) if ph == "kijk" else [{"mv": mv, "mc": mc}]
		if ph == "kijk":
			var n := TxLessons.narrate_group(group)
			if str(n.what) == "" or str(n.what).contains("%"):
				bad += 1
				t.ok(false, "verteltekst voor %s: '%s'" % [str(mv), str(n.what)])
		else:
			var tip := TxLessons.tip(mc, mv)
			if tip == "" or tip.contains("%"):
				t.ok(false, "tip voor %s: '%s'" % [str(mv), tip])
			var acc := TxLessons.accepts(mc, mv, mv)
			if not bool(acc.ok):
				t.ok(false, "orakelzet %s wordt aanvaard" % str(mv))
			for w in mc.wrong_moves():
				var a2 := TxLessons.accepts(mc, w, mv)
				if bool(a2.ok):
					t.ok(false, "foute zet %s wordt geweigerd (juist: %s)" % [str(w), str(mv)])
				else:
					var ex := TxLessons.explain_wrong(mc, w, mv, a2.r)
					if ex == "" or ex.contains("%"):
						t.ok(false, "foutuitleg voor %s: '%s'" % [str(w), ex])
			for w2 in mc.impossible_moves():
				if TxLessons.accepts(mc, w2, mv).ok:
					t.ok(false, "onmogelijke zet %s geweigerd" % str(w2))
		var st := TxLessons.state(mc)
		if st == "" or st.contains("%"):
			t.ok(false, "toestand na %d stappen: '%s'" % [steps, st])
		for k in group.size():
			var it: Dictionary = group[k]
			var act := TxLessons.act_key(it.mv)
			count[act] = int(count.get(act, 0)) + 1
			for a in cfg.get("ask", []):
				if str(a.on) == act and int(a.nth) == int(count[act]):
					asked += 1
					_verify_predict(t, it.mc, str(a.q), it.mv)
		for it2 in group:
			var r := dd.apply(it2.mv)
			steps += 1
			if not bool(r.ok) or int(r.verdict) != TxCodes.Verdict.OK:
				bad += 1
				t.ok(false, "zet %s → %s" % [str(it2.mv), str(r)])
	var done := dd.finished or (cfg.has("until_phase") and dd.machine.phase == int(cfg.until_phase))
	t.ok(done, "les eindigt (%d stappen)" % steps)
	t.eq(asked, (cfg.get("ask", []) as Array).size(), "elke voorspelvraag komt aan bod")
	t.ok(bad == 0, "geen fouten in de les")
	if dd.finished:
		t.ok(dd.report.get("mistakes", [1]).is_empty(), "orakel speelt de les foutloos")
	dd.dispose()


## Voorspelvraag: het juiste antwoord moet kloppen met wat de machine daarna echt doet.
func _verify_predict(t, mc: TxMachine, kind: String, mv: Dictionary) -> void:
	var q := TxLessons.predict(mc, kind, mv)
	if not t.ok(not q.is_empty() and (q.options as Array).size() >= 2 and (q.correct as Array).size() == 1, "vraag %s" % kind):
		return
	var opts: Array = q.options
	var uniq := {}
	for o in opts:
		uniq[str(o)] = true
	t.eq(uniq.size(), opts.size(), "%s: opties uniek" % kind)
	var ans := str(opts[int(q.correct[0])])
	var tr := TxLessons.trial(mc, mv)
	var m2: TxMachine = tr.mc
	var want := ""
	match kind:
		"ticks":
			want = str(int(m2.counters.ticks) - int(mc.counters.ticks))
		"wheel":
			if str(mv.act) == "slide":
				var r := mc as TxRabinKarp
				want = str(r.window_bits(r.i + 1).bin_to_int() % r.q)
			else:
				want = str((mc as TxRabinKarp).wheel)
		"minus":
			var r2 := mc as TxRabinKarp
			want = "ja, want t_p = 1" if r2.out_bit() == 1 else "nee, want t_p = 0"
		"real":
			var r3 := mc as TxRabinKarp
			var win := r3.window_bits(r3.si if r3.signal_mode() else r3.i)
			want = "ja, echte treffer" if win == r3.z else "nee, valse treffer"
			t.eq(m2.hits.size() > mc.hits.size(), win == r3.z, "verify meldt enkel een echte treffer")
		"shift":
			# de eerste (niet-automatische) logregel van deze zet: de verschuiving die de machine echt deed
			want = str(int((tr.entries[0] as Dictionary).get("data", {}).get("s", -1)))
		"gel":
			# Algoritme 4: gelijke_tekens = em − V[em] (0 als V[em] ≥ em); de naald vergelijkt verder vanaf die positie
			var k := mc as TxKmp
			var s0 := int((tr.entries[0] as Dictionary).get("data", {}).get("s", -1))
			want = str(k.em - s0 if s0 < k.em else 0)
		"v":
			want = str(int((m2 as TxKmpTable).strip[int(mv.j)]))
		"fill":
			var kt := mc as TxKmpTable
			var k2 := m2 as TxKmpTable
			var a := kt.punch_from()
			var b := int(mv.to)
			want = "V[%s] = %d" % [("%d" % a) if a == b else "%d..%d" % [a, b], int(k2.strip[b])]
		"start":
			want = str((m2 as TxKmpTable).start)
		"vh":
			want = str(int((m2 as TxBmh).cards[(mc as TxBmh).z[int(mv.i)]]))
		"jump":
			var b1 := mc as TxBmh
			var b2 := m2 as TxBmh
			want = str(b2.i - b1.i)
		"col":
			var s2 := m2 as TxShiftAnd
			want = TxLessons.bits(s2.prev[s2.k])
			# onafhankelijk: Definitie 13/14
			var s1 := mc as TxShiftAnd
			var col := ""
			for i in s1.m:
				col += str(TxReference.mk_def(s1.z, s1.t, s1.k, i, s1.j))
			t.eq(want, col, "kolom volgens Definitie 13/14")
		"lever":
			want = TxLessons.bits((m2 as TxShiftAnd).shown_cols()[0])
		"cell":
			var e2 := m2 as TxEditBoard
			var e1 := mc as TxEditBoard
			want = str(int(e2.tab[e1.ci][e1.cj]))
			t.eq(int(want), int(e1.true_tab[e1.ci][e1.cj]), "cel = echte tabel")
		"op":
			var eb := mc as TxEditBoard
			var dir := str(mv.dir)
			want = "verwijderen" if dir == "up" else ("toevoegen" if dir == "left" else ("niets (gelijke letters)" if eb.a[eb.ti - 1] == eb.b[eb.tj - 1] else "vervangen"))
		"end":
			var eb2 := mc as TxEditBoard
			want = str(int(mv.j))
			t.eq(int(eb2.tab[eb2.ra][int(mv.j)]), int(TxReference.approx_best(eb2.a, eb2.b).best), "einde = minimum")
	t.eq(ans, want, "voorspelvraag %s (%s)" % [kind, str(q.q)])


# ---------------------------------------------------------------- Check-vragen: onafhankelijk nagerekend

func _checks(t) -> void:
	t.section("Check-vragen")
	var rng := RandomNumberGenerator.new()
	for id in TxLessons.ids():
		var okn := 0
		for sd in 30:
			rng.seed = 1000 + sd * 7 + id.length()
			var q := TxLessons.check_question(id, rng)
			if q.is_empty():
				t.ok(false, "%s: vraag (seed %d)" % [id, sd])
				continue
			var opts: Array = q.options
			var uniq := {}
			for o in opts:
				uniq[str(o)] = true
			if uniq.size() != opts.size() or opts.size() < 2 or (q.correct as Array).size() != 1:
				t.ok(false, "%s: opties %s" % [id, str(opts)])
				continue
			var ans := str(opts[int(q.correct[0])])
			var want := _indep(id, q.get("data", {}))
			if ans == want and str(q.get("explain", "")) != "" and str(q.get("fig", "")) != "":
				okn += 1
			else:
				t.ok(false, "%s: antwoord %s, onafhankelijk %s (%s)" % [id, ans, want, str(q.get("data", {}))])
		t.eq(okn, 30, "%s: 30 nieuwe voorbeelden juist" % id)
		# geschud blijft het juiste antwoord juist
		rng.seed = 77
		var q0 := TxLessons.check_question(id, rng)
		var right := str(q0.options[int(q0.correct[0])])
		var sh := TxLessons.shuffled(q0, rng)
		t.eq(str(sh.options[int(sh.correct[0])]), right, "%s: schudden behoudt het antwoord" % id)


static func _ed(a: String, b: String) -> int:
	var memo := {}
	return _ed_rec(a, b, a.length(), b.length(), memo)


static func _ed_rec(a: String, b: String, i: int, j: int, memo: Dictionary) -> int:
	if i == 0:
		return j
	if j == 0:
		return i
	var key := i * 100 + j
	if memo.has(key):
		return memo[key]
	var v := mini(_ed_rec(a, b, i - 1, j - 1, memo) + (0 if a[i - 1] == b[j - 1] else 1),
		mini(_ed_rec(a, b, i - 1, j, memo) + 1, _ed_rec(a, b, i, j - 1, memo) + 1))
	memo[key] = v
	return v


static func _vdef(z: String, j: int) -> int:
	if j == 0:
		return 1
	for s in range(1, j):
		if z.substr(0, j - s) == z.substr(s, j - s):
			return s
	return j


func _indep(id: String, d: Dictionary) -> String:
	match id:
		"brute":
			var z := str(d.z)
			var tt := str(d.t)
			var c := 0
			for i in tt.length() - z.length() + 1:
				for k in z.length():
					c += 1
					if z[k] != tt[i + k]:
						break
			return str(c)
		"rk_hash":
			return str(str(d.z).bin_to_int() % int(d.q))
		"rk_rollen":
			return str(str(d.t).substr(1, int(d.m)).bin_to_int() % int(d.q))
		"rk_vals":
			var z2 := str(d.z)
			var t2 := str(d.t)
			var hz := z2.bin_to_int() % int(d.q)
			var n := 0
			for i in t2.length() - z2.length() + 1:
				var w := t2.substr(i, z2.length())
				if w.bin_to_int() % int(d.q) == hz and w != z2:
					n += 1
			return str(n)
		"kmp_idee", "kmp_def11":
			return str(_vdef(str(d.z), int(d.j)))
		"kmp_alg5":
			# Algoritme 5 vult precies de waarden van Definitie 11 in
			var z3 := str(d.z)
			for q in range(int(d.a), int(d.b) + 1):
				if _vdef(z3, q) != int(d.v):
					return "V[%d] ≠ Def. 11" % q
			var a := int(d.a)
			var b := int(d.b)
			if int(d.em) == 0:
				return "V[%d] = %d" % [int(d.start) + 1, int(d.start) + 1]
			return "V[%s] = %d" % [("%d" % a) if a == b else "%d..%d" % [a, b], int(d.start)]
		"kmp_loop":
			var z4 := str(d.z)
			var t4 := str(d.t)
			var m := z4.length()
			var start := 0
			var gel := 0
			var c2 := 0
			while start <= t4.length() - m:
				var em := m
				for i in range(gel, m):
					c2 += 1
					if z4[i] != t4[start + i]:
						em = i
						break
				var s := _vdef(z4, em)
				start += s
				gel = 0 if em == 0 else em - s
			return str(c2)
		"bmh_tabel":
			var z5 := str(d.z)
			var x := str(d.x)
			for p in range(z5.length() - 2, -1, -1):
				if z5[p] == x:
					return str(z5.length() - 1 - p)
			return str(z5.length())
		"bmh_loop":
			var z6 := str(d.z)
			var t6 := str(d.t)
			var m6 := z6.length()
			var i6 := m6 - 1
			var al := 0
			while i6 < t6.length():
				al += 1
				var sh := m6
				for p in range(m6 - 2, -1, -1):
					if z6[p] == t6[i6]:
						sh = m6 - 1 - p
						break
				i6 += sh
			return str(al)
		"sa_cx":
			var s7 := ""
			for ch in str(d.z):
				s7 += "1" if ch == str(d.x) else "0"
			return s7
		"sa_col", "sa_k":
			var z8 := str(d.z)
			var t8 := str(d.t)
			var j := int(d.j)
			var col := ""
			for i in z8.length():
				var mis := 0
				var okk := i <= j
				if okk:
					for k in i + 1:
						if z8[k] != t8[j - i + k]:
							mis += 1
				col += "1" if okk and mis <= (1 if id == "sa_k" else 0) else "0"
			return col
		"ed_fill":
			return str(_ed(str(d.a).substr(0, int(d.i)), str(d.b).substr(0, int(d.j))))
		"ed_trace":
			return str(_ed(str(d.a), str(d.b)))
		"alg8":
			var z9 := str(d.z)
			var t9 := str(d.t)
			var best := 99
			for l in t9.length() + 1:
				for r in range(l, t9.length() + 1):
					best = mini(best, _ed(z9, t9.substr(l, r - l)))
			return str(best)
	return "?"


# ---------------------------------------------------------------- voortgang en wachtrij

func _progress(t) -> void:
	t.section("leerpad: voortgang, eerste keer verplicht")
	TxLessons.reset_progress()
	var pend := TxLessons.pending_for_level("1-1")
	t.eq(pend.size(), 2, "vóór 1-1: Kijk + Samen van deel 1")
	t.eq(str(pend[0].part) + "/" + str(pend[0].phase), "brute/kijk", "eerst Kijk")
	t.eq(TxLessons.pending_for_level("3-3").size(), 2 * 7, "vóór 3-3: delen 1–7")
	t.eq(TxLessons.pending_for_level("F").size(), 0, "finale: geen eigen les")
	TxLessons.mark("brute", "kijk")
	t.eq(TxLessons.level("brute"), 1, "demo bekeken")
	t.eq(TxLessons.pending_for_level("1-1").size(), 1, "na Kijk: enkel Samen")
	TxLessons.mark("brute", "samen")
	t.eq(TxLessons.level("brute"), 2, "samen geoefend")
	t.eq(TxLessons.pending_for_level("1-2").size(), 0, "1-2: niets meer verplicht")
	TxLessons.mark("brute", "check")
	t.eq(TxLessons.level("brute"), 3, "begrepen (badge)")
	t.eq(TxLessons.parts_for_level("3-1"), ["kmp_idee"], "badge 3-1 = deel 5")
	t.eq(TxLessons.report_parts("4-1"), ["bmh_tabel", "bmh_loop"], "Check van 4-1: twee delen")
	t.eq(TxLessons.report_parts("4-3"), ["bmh_loop"], "Check van 4-3: het deel dat het oefent")
	TxLessons.reset_progress()
	t.eq(TxLessons.level("brute"), 0, "reset_learning wist alles")
	# BBCode: haken van indices worden ontsnapt, opmaaktags niet
	var b := TxLessons.bb("[b]V[j][/b] = z[0..i] [color=#fff]x[/color] t_p")
	t.ok(b.contains("V[lb]j]") and b.contains("z[lb]0..i]") and b.contains("[b]") and b.contains("[color=#fff]"), "bb(): indices ontsnapt")
