extends RefCounted

const V := ExtHashModel.Verdict


static func hv(s: String) -> int:
	return HashUtil.from_bits(s)


static func make(n: int, g: int, a: int, layout: Array = []) -> ExtHashModel:
	var m := ExtHashModel.new()
	m.setup(n, g, a)
	m.load_layout(layout)
	return m


static func ins(m: ExtHashModel, s: String) -> String:
	return m.auto_insert(m.new_parcel(hv(s)))


func run(t) -> void:
	_setup_and_layout(t)
	_a2_double(t)
	_a3_split(t)
	_a4_notas(t)
	_oef5(t)
	_identical(t)
	_a8_snapshot(t)
	_io_counts(t)
	_mistakes(t)
	_oracle(t)
	_dump(t)
	_coach(t)


func _setup_and_layout(t) -> void:
	t.section("setup/load_layout")
	var m := make(5, 2, 1)
	t.eq(m.dir.size(), 2, "2^a pointers")
	t.eq(m.buckets.size(), 2, "2 emmers")
	t.eq(m.buckets[0].ab, 1, "ab = a")
	t.eq(m.describe(), "0{} 1{}", "lege tabel")
	m = make(5, 2, 3, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": ["10010"]},
		{"label": "110", "hvs": ["11000"]}, {"label": "111", "hvs": ["11100"]}])
	t.eq(m.describe(), "0{00100,01111} 10{10010} 110{11000} 111{11100}", "dag-3-start")
	t.eq(m.span(0), 4, "span emmer 0 = 2^(3-1)")
	t.eq(m.dir_range(1), Vector2i(4, 2), "dir_range 10")
	t.eq(m.label_of(2), "110", "label_of")
	t.eq(m.index_of(hv("10110")), 5, "index_of")
	t.eq(m.bucket_at(5).id, 1, "bucket_at")
	t.eq(m.invariants().size(), 0, "invariants start")
	var lay := m.layout()
	t.eq(lay.size(), 4, "layout 4 emmers")
	t.eq(lay[1], {"bucket_id": 1, "start": 4, "span": 2, "ab": 2, "label": "10"}, "layout[1]")


func _a2_double(t) -> void:
	t.section("A2 verdubbelen")
	var m := make(5, 2, 2, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": ["10010"]}, {"label": "11", "hvs": ["11100", "11111"]}])
	var old := m.dir.duplicate()
	var sig := []
	m.directory_doubled.connect(func(o, nw, v): sig.append([o, nw, v]))
	t.ok(m.double_dir(), "double_dir true")
	t.eq(m.a, 3, "a+1")
	t.eq(m.dir.size(), 8, "2^3")
	var good := true
	for i in m.dir.size():
		good = good and m.dir[i] == old[i >> 1]
	t.ok(good, "pn[i] = po[i>>1]")
	t.eq(m.reads + m.writes, 0, "geen ritten")
	t.eq(sig, [[2, 3, V.UNNEEDED_DOUBLE]], "signaal (niets zat vast -> UNNEEDED)")
	t.eq(m.invariants().size(), 0, "invariants")
	# eindaanslag
	var m2 := make(2, 1, 2)
	var refused := [0]
	m2.double_refused.connect(func(): refused[0] += 1)
	t.ok(not m2.can_double(), "can_double a==n")
	t.ok(not m2.double_dir(), "double_dir false bij a==n")
	t.eq(refused[0], 1, "double_refused")
	t.eq(m2.a, 2, "a ongewijzigd")


func _a3_split(t) -> void:
	t.section("A3 splitsen")
	var m := make(5, 2, 2, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": ["10010"]}, {"label": "11", "hvs": ["11100", "11111"]}])
	var refused := []
	m.split_refused.connect(func(b): refused.append(b))
	t.ok(not m.can_split(1), "can_split ab==a")
	t.ok(not m.begin_split(1), "begin_split ab==a false")
	t.eq(refused, [1], "split_refused")
	t.eq(m.splits, 0, "geen split")
	# a = 4: emmer 0 (ab 1) heeft 8 pointers -> changed = 0100..0111
	m.double_dir()
	m.double_dir()
	var got := []
	m.split_started.connect(func(b, nb, pos, changed, to_sort, v): got.append([b, nb, pos, Array(changed), to_sort.size(), v]))
	t.ok(m.begin_split(0), "begin_split ab<a")
	t.eq(got.size(), 1, "split_started")
	t.eq(got[0][0], 0, "bucket")
	t.eq(got[0][1], 3, "nieuwe id = buckets.size()")
	t.eq(got[0][2], 2, "bit_pos = ab+1")
	t.eq(got[0][3], [4, 5, 6, 7], "changed = 2^(a-ab-1) indices met i|(ab+1) = 2p+1, aaneengesloten")
	t.eq(got[0][4], 2, "to_sort = alle pakjes")
	t.eq(got[0][5], V.UNNEEDED_SPLIT, "niets zat vast -> UNNEEDED_SPLIT")
	t.eq(m.reads, 1, "onnodige split: L+1")
	t.ok(not m.can_split(1), "geen tweede split tegelijk")
	# verdeel
	var p0: Parcel = m.splitting.pending[0]   # 00100 -> bit 2 = 0
	t.eq(m.correct_side(p0), 0, "correct_side 00100")
	t.eq(m.assign(p0.id, 0), V.OK, "assign OK")
	var p1: Parcel = m.splitting.pending[0]   # 01111 -> bit 2 = 1
	t.eq(m.assign(p1.id, 1), V.OK, "assign OK 2")
	t.ok(m.splitting.is_empty(), "finish na laatste")
	t.eq(m.writes, 2, "onnodige split S+2")
	t.eq(m.buckets[0].ab, 2, "ab oud")
	t.eq(m.buckets[3].ab, 2, "ab nieuw")
	t.eq(m.describe(), "00{00100} 01{01111} 10{10010} 11{11100,11111}", "na split")
	t.eq(m.invariants().size(), 0, "invariants")
	# randgeval: changed voor willekeurige a, ab
	for a in range(1, 7):
		for ab in range(0, a):
			for p in (1 << ab):
				var mm := ExtHashModel.new()
				mm.setup(8, 2, ab)
				for k in a - ab:
					mm.double_dir()
				var cap := []
				mm.split_started.connect(func(b, nb, pos, ch, ts, v): cap.append(Array(ch)))
				mm.begin_split(mm.dir[p << (a - ab)])
				var w := 1 << (a - ab - 1)
				var want := []
				for i in range((2 * p + 1) * w, (2 * p + 2) * w):
					want.append(i)
				t.eq(cap[0], want, "changed a=%d ab=%d p=%d" % [a, ab, p])


func _a4_notas(t) -> void:
	t.section("A4 notas Fig 2 -> 4 -> 5")
	var m := make(5, 2, 1)
	for s in ["00100", "01111", "10010", "11100"]:
		t.eq(ins(m, s), "ok", "ins " + s)
	t.eq(m.describe(), "0{00100,01111} 1{10010,11100}", "Figuur 2")
	t.eq(ins(m, "11111"), "ok", "ins 11111")
	t.eq(m.a, 2, "Fig 4: a = 2")
	t.eq(m.describe(), "0{00100,01111} 10{10010} 11{11100,11111}", "Figuur 4")
	t.eq(m.buckets[0].ab, 1, "Fig 4: emmer 0 ab 1")
	# 11110 stap voor stap met het orakel
	var p := m.new_parcel(hv("11110"))
	var still := []
	m.still_blocked.connect(func(pp, b): still.append([pp.hv, b]))
	t.eq(m.correct_move(p), {"action": "drop", "dir_index": 3}, "orakel: drop luik 11")
	var r := m.drop(p, 3)
	t.eq(r.status, ExtHashModel.Drop.BLOCKED, "11110 zit vast")
	t.eq(m.correct_move(), {"action": "double"}, "orakel: 1 buis -> double")
	t.eq(m.double_dir(), true, "double")
	t.eq(m.log.entries[-1].verdict, V.OK, "double OK")
	var mv := m.correct_move()
	t.eq(mv.action, "split", "orakel: split")
	t.ok(m.begin_split(int(mv.bucket_id)), "split 11")
	t.eq(m.log.entries[-1].verdict, V.OK, "split OK")
	while not m.splitting.is_empty():
		var c := m.correct_move()
		t.eq(c.side, 1, "beide naar rechts (bit 3 = 1)")
		m.assign(int(c.parcel_id), int(c.side))
	t.eq(still.size(), 1, "still_blocked geëmit")
	t.eq(m.a, 3, "Fig 5: a = 3")
	t.eq(m.describe(), "0{00100,01111} 10{10010} 110{} 111{11100,11111}", "Figuur 5")
	t.eq(m.buckets[m.dir[6]].ab, 3, "110 ab 3")
	t.eq(m.correct_move(), {"action": "double"}, "orakel: nog eens verdubbelen")
	t.eq(m.auto_resolve(), "ok", "kettingreactie opgelost")
	t.eq(m.a, 4, "eind a = 4")
	t.eq(m.describe(), "0{00100,01111} 10{10010} 110{} 1110{11100} 1111{11111,11110}", "eindtoestand")
	t.eq(m.blocked.size(), 0, "niets vast")
	t.eq(m.log.mistakes().size(), 0, "geen fouten")


func _oef5(t) -> void:
	t.section("Oefening 5")
	var m := make(5, 2, 1)
	var keys := {3: "00000", 7: "11111", 12: "01001", 45: "10001", 44: "00010", 1: "00001"}
	for k in [3, 7, 12, 45, 44, 1]:
		t.eq(m.auto_insert(m.new_parcel(hv(keys[k]), str(k))), "ok", "ins %d" % k)
	t.eq(m.a, 4, "a = 4")
	t.eq(m.layout().size(), 5, "5 emmers")
	var empty := 0
	for L in m.layout():
		if m.buckets[int(L.bucket_id)].parcels.is_empty():
			empty += 1
	t.eq(empty, 1, "één lege emmer")
	t.eq(m.describe(), "0000{00000,00001} 0001{00010} 001{} 01{01001} 1{11111,10001}", "oplossing Oef. 5")
	t.eq(m.span(m.dir[15]), 8, "emmer 1: 8 pointers")
	t.eq([m.reads, m.writes, m.doubles, m.splits], [6, 9, 3, 3], "L6 S9, 3 dubbels, 3 splits")
	t.eq(m.buckets[0].parcels[0].key_label, "3", "sleutellabel")


func _identical(t) -> void:
	t.section("identieke hashwaarden -> faalt bij a = n")
	var m := make(5, 2, 1)
	ins(m, "01001")
	ins(m, "10110")
	ins(m, "10110")
	var p := m.new_parcel(hv("10110"))
	var refused := [0]
	m.double_refused.connect(func(): refused[0] += 1)
	t.eq(m.auto_insert(p), "fail", "faalt")
	t.eq(m.a, 5, "a = n")
	t.eq(m.correct_move(), {"action": "fail", "parcel_id": p.id}, "orakel: fail")
	t.eq(m.describe(), "0{01001} 100{} 1010{} 10110{10110,10110} 10111{} 11{}", "dag 7 ochtend eind")
	t.ok(not m.double_dir(), "hendel op eindaanslag")
	t.eq(refused[0], 1, "double_refused")
	t.eq(m.blocked.size(), 1, "pakje zit nog vast")
	m.lose(p, "burst", true)
	t.eq(m.blocked.size(), 0, "na burst niet meer vast")
	t.eq(m.log.mistakes().size(), 0, "excused burst is geen fout")
	# g+1 identieke voor kleine n
	for n in range(2, 7):
		for g in range(1, 4):
			var mm := make(n, g, 1)
			var res := ""
			for i in g + 1:
				res = mm.auto_insert(mm.new_parcel(0b1 << (n - 1)))
			t.eq(res, "fail", "n=%d g=%d: g+1 identieke faalt" % [n, g])
			t.eq(mm.a, n, "n=%d g=%d: a == n" % [n, g])
			t.eq(mm.invariants().size(), 0, "invariants na falen")


func _a8_snapshot(t) -> void:
	t.section("A8 snapshot/restore")
	var m := make(5, 2, 2, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": ["10010"]}, {"label": "11", "hvs": ["11100", "11111"]}])
	m.allow_dump = true
	var p := m.new_parcel(hv("11110"), "x", true)
	m.drop(p, 3)
	m.double_dir()
	m.begin_split(m.dir[6])
	m.assign((m.splitting.pending[0] as Parcel).id, 1)   # midden in een split, met een vastzittend pakje
	var s1 := m.snapshot()
	var m2 := ExtHashModel.new()
	m2.restore(s1)
	t.eq(m2.snapshot(), s1, "snapshot -> restore -> snapshot identiek")
	var js = JSON.parse_string(JSON.stringify(s1))
	var m3 := ExtHashModel.new()
	m3.restore(js)
	t.eq(m3.snapshot(), s1, "ook na JSON-roundtrip")
	t.eq(m3.auto_resolve(), "ok", "herstelde toestand speelbaar")
	t.eq(m.auto_resolve(), "ok", "origineel speelbaar")
	t.eq(m3.describe(), m.describe(), "zelfde eindtoestand")


func _io_counts(t) -> void:
	t.section("ritten §6.2")
	var m := make(5, 2, 1)
	ins(m, "00100")
	t.eq([m.reads, m.writes], [1, 1], "gewone invoeging 1L 1S")
	for s in ["01111", "10010", "11100"]:
		ins(m, s)
	ins(m, "11111")
	t.eq([m.reads, m.writes], [5, 6], "met 1 split: +1L +2S")
	ins(m, "11110")
	t.eq([m.reads, m.writes], [6, 9], "11110 met 2 splits: +1L +3S")
	m.lookup(m.index_of(hv("11110")), hv("11110"))
	t.eq(m.reads, 7, "lookup L+1")
	var io := []
	m.io_changed.connect(func(r, w): io.append([r, w]))
	m.double_dir()
	t.eq(io.size(), 0, "verdubbelen: geen ritten")


func _mistakes(t) -> void:
	t.section("fouten -> verdicts")
	var m := make(5, 2, 2)
	var p := m.new_parcel(hv("10110"))
	var r := m.drop(p, 0)
	t.eq(r.verdict, V.MISROUTED, "fout luik")
	t.eq(r.correct_index, 2, "correct_index")
	t.ok(m.is_misplaced(p, int(r.bucket_id)), "is_misplaced")
	t.eq(m.misplaced().size(), 1, "misplaced()")
	t.eq(m.log.cause_of(p.id).seq, m.log.entries[0].seq, "cause_of")
	t.ok(not m.log.entries[0].before.is_empty(), "before-snapshot bij fout")
	t.eq(m.invariants().size(), 0, "verdwaald is geen structuurfout")
	var lk := m.lookup(2, hv("10110"))
	t.eq([lk.found, lk.verdict], [false, V.OK], "juist luik maar niet gevonden")
	t.eq(m.log.entries[-1].data.get("cause_seq", -1), 0, "lookup linkt naar oorzaak")
	lk = m.lookup(0, hv("10110"))
	t.eq([lk.found, lk.verdict], [true, V.WRONG_LOOKUP], "fout luik bij klant")
	# zelfde buis = geen fout
	var m2 := make(5, 2, 2, [{"label": "0", "hvs": []}, {"label": "10", "hvs": []}, {"label": "11", "hvs": []}])
	t.eq(m2.drop(m2.new_parcel(hv("00110")), 1).verdict, V.OK, "luik dat dezelfde buis deelt is OK")
	# verkeerde kant
	var m3 := make(5, 2, 1)
	ins(m3, "10010")
	ins(m3, "11100")
	var q := m3.new_parcel(hv("11111"))
	m3.drop(q, 1)
	m3.double_dir()
	m3.begin_split(m3.dir[2])
	var first: Parcel = m3.splitting.pending[0]  # 10010 -> 0
	t.eq(m3.assign(first.id, 1), V.WRONG_SIDE, "verkeerde kant")
	t.eq(m3.log.cause_of(first.id).type, "ASSIGN", "cause_of verkeerde kant")
	m3.auto_assign_rest()
	t.eq(m3.misplaced().size(), 1, "10010 verdwaald")
	t.eq(m3.invariants().size(), 0, "structuur ok")
	# onnodige verdubbeling terwijl splitsen volstond
	var m4 := make(5, 2, 2, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": []}, {"label": "11", "hvs": []}])
	m4.drop(m4.new_parcel(hv("00110")), 0)
	t.eq(m4.correct_move().action, "split", "orakel split")
	m4.double_dir()
	t.eq(m4.log.entries[-1].verdict, V.UNNEEDED_DOUBLE, "UNNEEDED_DOUBLE")
	t.eq(m4.log.entries[-1].hint.action, "split", "hint = split")
	t.eq(m4.blocked.size(), 1, "alarm blijft")
	t.eq(m4.blocked[0].via_index, 1, "via_index geremapt: (0<<1)|bit2(00110)=0 -> 0? ")


func _oracle(t) -> void:
	t.section("orakel")
	var m := make(5, 2, 1)
	t.eq(m.correct_move(), {"action": "none"}, "none")
	var p := m.new_parcel(hv("10000"))
	t.eq(m.correct_move(p), {"action": "drop", "dir_index": 1}, "drop")
	ins(m, "00001")
	ins(m, "00010")
	var q := m.new_parcel(hv("00011"))
	m.drop(q, 0)
	t.eq(m.correct_move(p), {"action": "double"}, "blocked gaat voor front")
	m.double_dir()
	t.eq(m.correct_move().action, "split", "split")
	m.begin_split(0)
	var c := m.correct_move()
	t.eq(c.action, "assign", "assign tijdens split")
	# drop tijdens split naar het splitsende rek -> BLOCKED
	var r := m.drop(m.new_parcel(hv("00111")), 0)
	t.eq(r.status, ExtHashModel.Drop.BLOCKED, "drop naar splitsend rek: BLOCKED")
	t.eq(m.auto_resolve(), "ok", "auto_resolve")
	t.eq(m.invariants().size(), 0, "invariants")


func _dump(t) -> void:
	t.section("overloopbak")
	var m := make(5, 2, 1)
	m.allow_dump = true
	ins(m, "11001")
	ins(m, "11001")
	var c := m.new_parcel(hv("11001"), "", true)
	t.eq(m.correct_move(c), {"action": "dump", "parcel_id": c.id}, "orakel: kloon -> dump van de band")
	t.eq(m.auto_insert(c), "dump", "auto_insert dump")
	t.eq(m.log.entries[-1].verdict, V.OK, "dump OK")
	t.eq(m.reads, 2, "dump kost geen rit")
	var h := m.new_parcel(hv("00000"))
	var lost := []
	m.parcel_lost.connect(func(pp, why): lost.append(why))
	t.eq(m.dump(h), V.UNNEEDED_DUMP, "gezond pakje in bak")
	t.eq(lost, ["dump_healthy"], "telt als kwijt")
	# kloon vast in rek -> dump uit blocked
	var c2 := m.new_parcel(hv("11001"), "", true)
	m.drop(c2, 1)
	t.eq(m.correct_move().action, "dump", "blocked kloon -> dump")
	t.eq(m.dump(c2), V.OK, "dump uit blocked")
	t.eq(m.blocked.size(), 0, "niet meer vast")
	t.eq(m.dumped.size(), 3, "3 in de bak")


func _coach(t) -> void:
	t.section("coach_line")
	var m := make(5, 2, 3)
	m.drop(m.new_parcel(hv("10110")), 4)
	t.eq(m.log.coach_line(m.log.entries[0]), "`10110` begint met `101`. Luik `101`, niet `100`.", "chef: fout luik")
	var m2 := make(5, 2, 2, [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": []}, {"label": "11", "hvs": []}])
	m2.drop(m2.new_parcel(hv("00110")), 0)
	m2.double_dir()
	t.eq(m2.log.coach_line(m2.log.entries[-1]), "Twee buizen naar dit rek → zagen volstond. Hendel was niet nodig.", "chef: onnodig verdubbelen")
	var m3 := make(5, 2, 2, [{"label": "0", "hvs": []}, {"label": "10", "hvs": []}, {"label": "11", "hvs": ["11100", "11111"]}])
	m3.drop(m3.new_parcel(hv("11110")), 3)
	m3.double_dir()
	m3.begin_split(m3.dir[6])
	m3.assign((m3.splitting.pending[0] as Parcel).id, 0)
	var e: Dictionary = m3.log.of_type("ASSIGN")[0]
	t.eq(m3.log.coach_line(e), "Bit 3 van `11100` is `1` → rechts, naar het nieuwe rek.", "chef: verkeerde kant")
