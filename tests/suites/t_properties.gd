extends RefCounted
## Random property tests: duizenden invoegingen, perfect gespeeld met het orakel.
## Na elke actie: invariants() leeg, 2^(a-ab)-blokken, pn[i] = po[i/2] bij elke verdubbeling,
## elk record bereikbaar via zijn pointer, simulate_insert == wat het orakel daarna doet.


func run(t) -> void:
	t.section("properties")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261008
	var inserts := 0
	var bad_inv := 0
	var bad_reach := 0
	var bad_double := [0]
	var bad_span := 0
	var bad_sim := 0
	var bad_oracle := 0
	for trial in 300:
		var n := rng.randi_range(3, 8)
		var g := rng.randi_range(1, 4)
		var a0 := rng.randi_range(0, mini(2, n))
		var m := ExtHashModel.new()
		m.setup(n, g, a0)
		var dir_before := [m.dir.duplicate()]
		m.directory_doubled.connect(func(oa, na, v):
			var ok := m.dir.size() == 2 * dir_before[0].size()
			for i in m.dir.size():
				ok = ok and m.dir[i] == dir_before[0][i >> 1]
			if not ok:
				bad_double[0] += 1
		)
		var count := rng.randi_range(5, 40)
		var stored: Array[int] = []
		for k in count:
			var hv := rng.randi_range(0, (1 << n) - 1)
			var sim := m.simulate_insert(hv)
			var p := m.new_parcel(hv)
			# speel stap voor stap met het orakel, check na elke actie
			var acts := []
			var mv := m.correct_move(p)
			if mv.action != "drop":
				bad_oracle += 1
			dir_before[0] = m.dir.duplicate()
			m.drop(p, int(mv.dir_index))
			acts.append("drop")
			var result := "ok"
			for guard in 500:
				if not m.invariants().is_empty():
					bad_inv += 1
				var c := m.correct_move()
				if c.action == "none":
					break
				if c.action == "fail":
					result = "fail"
					break
				dir_before[0] = m.dir.duplicate()
				match c.action:
					"double":
						m.double_dir()
						acts.append("double")
					"split":
						m.begin_split(int(c.bucket_id))
						acts.append("split")
					"assign":
						m.assign(int(c.parcel_id), int(c.side))
					_:
						bad_oracle += 1
						break
			inserts += 1
			# orakel-acties == simulate_insert-stappen (zonder place/fail)
			var want := []
			for s in sim:
				if s.act == "double" or s.act == "split":
					want.append(s.act)
			var got := acts.slice(1)
			if got != want or (result == "fail") != (sim[-1].act == "fail"):
				bad_sim += 1
			if result == "fail":
				# identieke hashwaarden > g: a moet n zijn
				if m.a != n:
					bad_oracle += 1
				m.lose(p, "burst", true)
			else:
				stored.append(hv)
			# 2^(a-ab): aantal pointers per emmer
			var cnt := {}
			for i in m.dir.size():
				cnt[m.dir[i]] = cnt.get(m.dir[i], 0) + 1
			for b in m.buckets:
				if cnt.get(b.id, 0) != (1 << (m.a - b.ab)):
					bad_span += 1
			# elk record bereikbaar via zijn pointer
			for b in m.buckets:
				for q in b.parcels:
					if m.dir[m.index_of(q.hv)] != b.id:
						bad_reach += 1
			for h in stored:
				if not m.is_findable(h):
					bad_reach += 1
		if not m.invariants().is_empty():
			bad_inv += 1
	t.ok(inserts > 3000, "duizenden invoegingen (%d)" % inserts)
	t.eq(bad_inv, 0, "invariants na elke actie")
	t.eq(bad_double[0], 0, "pn[i] = po[i/2]")
	t.eq(bad_span, 0, "2^(a-ab) pointers per emmer")
	t.eq(bad_reach, 0, "elk record bereikbaar via zijn pointer")
	t.eq(bad_sim, 0, "simulate_insert == orakel-acties")
	t.eq(bad_oracle, 0, "orakel consistent")

	t.section("orakel in willekeurige toestanden")
	# willekeurige (ook foute) speler: het orakel moet in elke toestand een geldige zet geven die vooruitgang boekt
	var stuck := 0
	var inv := 0
	for trial in 200:
		var n := rng.randi_range(3, 6)
		var g := rng.randi_range(1, 3)
		var m := ExtHashModel.new()
		m.setup(n, g, 1)
		m.allow_dump = rng.randf() < 0.5
		for k in 25:
			var p := m.new_parcel(rng.randi_range(0, (1 << n) - 1))
			# willekeurige actie, soms fout
			m.drop(p, rng.randi_range(0, m.dir.size() - 1))
			for j in rng.randi_range(0, 3):
				match rng.randi_range(0, 3):
					0:
						m.double_dir()
					1:
						m.begin_split(rng.randi_range(0, m.buckets.size() - 1))
					2:
						if not m.splitting.is_empty() and not m.splitting.pending.is_empty():
							m.assign((m.splitting.pending[0] as Parcel).id, rng.randi_range(0, 1))
					3:
						pass
			if not m.invariants().is_empty():
				inv += 1
			var r := m.auto_resolve()
			var guard := 0
			while r == "fail" and guard < 100:
				m.lose(m.blocked[0].parcel, "burst", true)
				r = m.auto_resolve()
				guard += 1
			if r != "ok" or m.is_alarm():
				stuck += 1
				break
			if not m.invariants().is_empty():
				inv += 1
	t.eq(stuck, 0, "orakel lost elke toestand op")
	t.eq(inv, 0, "invariants ook met foute zetten")
