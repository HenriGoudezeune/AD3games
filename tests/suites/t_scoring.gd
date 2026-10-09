extends RefCounted
## Scoring (§6) en SaveData.


func _model(g: int = 3) -> ExtHashModel:
	var m := ExtHashModel.new()
	m.setup(5, g, 1)
	return m


func run(t) -> void:
	t.section("scoring: munten & combo")
	var m := _model(10)
	var s := Scoring.new()
	s.bind(m)
	var combos := []
	var dashes := [0]
	s.combo_changed.connect(func(c): combos.append(c))
	s.dash.connect(func(): dashes[0] += 1)
	var p := m.new_parcel(0b00001)
	m.drop(p, 0)
	t.eq(s.coins, 10 - 2, "+10 × combo 1, −2 ritten")
	for i in 5:
		s.tick_real(1.0)
		var pp := m.new_parcel(0b10000 + i)
		m.drop(pp, m.index_of(pp.hv))
	# plaatsingen 2..6 binnen 3 s: combo 2,3,4,5,5
	t.eq(combos, [2, 3, 4, 5], "combo loopt op tot ×5")
	t.eq(dashes[0], 1, "DASH bij ×5")
	t.eq(s.totals.pakjes, 10 + 20 + 30 + 40 + 50 + 50, "munten per plaatsing")
	s.tick_real(3.1)
	t.eq(s.combo, 1, "combo breekt na 3 s")
	# alarm pauzeert de combo-timer
	var m2 := _model()
	var s2 := Scoring.new()
	s2.bind(m2)
	m2.drop(m2.new_parcel(0b00001), 0)
	m2.drop(m2.new_parcel(0b00010), 0)
	t.eq(s2.combo, 2, "combo 2")
	m2.drop(m2.new_parcel(0b00011), 0)
	m2.drop(m2.new_parcel(0b00100), 0)   # vast
	t.ok(m2.is_alarm(), "alarm")
	s2.tick_real(10.0)
	t.eq(s2.combo, 3, "combo gepauzeerd tijdens alarm")
	# fout luik breekt de combo
	m2.auto_resolve()
	m2.drop(m2.new_parcel(0b11111), 0)
	t.eq(s2.combo, 1, "verdwaald breekt combo")
	s2.on_loupe_used()
	t.eq(s2.combo, 1, "loep breekt combo")

	t.section("scoring: reputatie & klanten")
	var m3 := _model()
	var s3 := Scoring.new()
	s3.bind(m3)
	var reps := []
	s3.reputation_changed.connect(func(r): reps.append(r))
	var q := m3.new_parcel(1)
	m3.lose(q, "belt")
	t.eq([s3.coins, s3.rep], [-5, 4], "kwijt: −5 en −1 ♥")
	s3.on_customer(true, 1.0)
	t.eq(s3.coins, -5 + 25, "klant: +15 + fooi 10")
	s3.on_customer(true, 0.0)
	t.eq(s3.coins, -5 + 25 + 15, "klant zonder fooi")
	s3.on_customer(false, 0.0)
	t.eq(s3.rep, 3, "boze klant −1 ♥")
	t.eq(s3.coins, -5 + 25 + 15 - 10, "boze klant −10 €")
	t.eq(reps, [4, 3], "reputation_changed")
	t.eq([s3.customers_ok, s3.customers_total], [2, 3], "klanten geteld")
	var m4 := _model()
	m4.g = 1
	m4.allow_dump = true
	var s4 := Scoring.new()
	s4.bind(m4)
	m4.drop(m4.new_parcel(5), 0)
	var c0 := s4.coins
	m4.dump(m4.new_parcel(5, "", true))
	t.eq(s4.coins - c0, 5, "kloon correct in bak: +5")
	m4.dump(m4.new_parcel(30))
	t.eq(s4.coins - c0, 5 - 10, "gezond pakje in bak: −5 kwijt −5 bakkosten")
	t.eq(s4.rep, 4, "en −1 ♥")
	# endless: +1 ♥ per 25 correcte pakjes op rij
	var m5 := ExtHashModel.new()
	m5.setup(8, 200, 1)
	var s5 := Scoring.new()
	s5.rep = 3
	s5.rep_regen_every = 25
	s5.bind(m5)
	for i in 50:
		m5.drop(m5.new_parcel(i), 0)
	t.eq(s5.rep, 5, "+2 ♥ na 50 op rij")

	t.section("scoring: huur & rapport")
	var spec := Days.get_day(6)
	var m6 := ExtHashModel.new()
	m6.setup(5, 2, 1)
	var s6 := Scoring.new()
	s6.bind(m6)
	for k in spec.keys:
		m6.auto_insert(m6.new_parcel(HashUtil.from_bits(k.hv)))
	t.eq(Scoring.rent(m6), {"wall": -8, "racks": -5, "misplaced": 0}, "muurhuur 0,5 × 16, rekhuur 5")
	var rep := s6.final_report(m6, spec, 30.0)
	t.eq(rep.stars, [true, true, true], "Oef. 5 perfect: 3 sterren")
	t.eq(rep.coins, s6.coins - 13, "huur in rapport")
	t.ok(rep.breakdown.any(func(b): return b.label == "muurhuur" and b.amount == -8), "breakdown muurhuur")
	t.eq(rep.opt.writes, 9, "opt in rapport")
	for k in ["stars", "coins", "breakdown", "reads", "writes", "opt", "mistakes", "parcels", "customers_ok", "customers_total"]:
		t.ok(rep.has(k), "rapport heeft " + k)
	# ★★ op dag 6 = eindtoestand: met een verkeerde kant klopt die niet meer
	var m7 := ExtHashModel.new()
	m7.setup(5, 2, 1)
	var s7 := Scoring.new()
	s7.bind(m7)
	m7.auto_insert(m7.new_parcel(0))
	m7.auto_insert(m7.new_parcel(31))
	m7.auto_insert(m7.new_parcel(9))
	m7.auto_insert(m7.new_parcel(17))
	m7.drop(m7.new_parcel(2), 0)
	m7.double_dir()
	m7.begin_split(0)
	var first: Parcel = m7.splitting.pending[0]
	m7.assign(first.id, 1 - m7.correct_side(first))
	m7.auto_resolve()
	m7.auto_insert(m7.new_parcel(1))
	var rep7 := s7.final_report(m7, spec, 30.0)
	t.eq(rep7.stars, [true, false, false], "fout op dag 6: ★ alleen")
	# tijd-ster
	var spec1 := Days.get_day(1)
	var m8 := ExtHashModel.new()
	m8.setup(5, 3, 1)
	var s8 := Scoring.new()
	s8.bind(m8)
	for k in spec1.keys:
		m8.auto_insert(m8.new_parcel(HashUtil.from_bits(k.hv)))
	t.eq(s8.final_report(m8, spec1, 39.0).stars, [true, true, true], "dag 1 binnen 40 s")
	t.eq(s8.final_report(m8, spec1, 41.0).stars, [true, true, false], "dag 1 te traag")

	t.section("SaveData")
	var old := SaveData.path
	SaveData.path = "user://test_save_%d.json" % Time.get_ticks_usec()
	t.eq(SaveData.load_data().stars, {}, "leeg begin")
	t.ok(SaveData.is_unlocked(1) and not SaveData.is_unlocked(2) and not SaveData.is_unlocked(0), "enkel dag 1 open")
	SaveData.set_stars(1, 2)
	SaveData.set_stars(1, 1)
	t.eq(SaveData.get_stars(1), 2, "beste blijft")
	SaveData.set_stars(5, 1)
	t.ok(SaveData.is_unlocked(2) and SaveData.is_unlocked(0), "dag 2 en endless open")
	for i in 12:
		SaveData.add_highscore(i * 10, "abcd")
	var hs := SaveData.highscores()
	t.eq(hs.size(), 10, "top-10")
	t.eq(int(hs[0].score), 110, "hoogste eerst")
	t.eq(hs[0].name, "ABC", "naam 3 letters")
	t.ok(str(hs[0].date).length() == 10, "datum")
	t.eq(SaveData.add_highscore(5, "x"), -1, "te laag")
	t.ok(not SaveData.is_highscore(15) and SaveData.is_highscore(1000), "is_highscore")
	SaveData.set_setting("music", 0.5)
	t.eq(SaveData.get_setting("music"), 0.5, "instelling")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	SaveData.path = old
