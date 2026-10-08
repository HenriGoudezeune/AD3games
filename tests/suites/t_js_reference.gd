extends RefCounted
## A7: simulate_insert() en het perfect gespeelde model geven dezelfde stappen en eindtoestand als de
## JS-referentie (tests/fixtures/js_reference.json, gegenereerd met `node tests/gen_js_fixture.js`).


func run(t) -> void:
	t.section("A7 JS-referentie")
	var f := FileAccess.open("res://tests/fixtures/js_reference.json", FileAccess.READ)
	if not t.ok(f != null, "fixture bestaat"):
		return
	var cases = JSON.parse_string(f.get_as_text())
	t.ok(cases is Array and cases.size() > 40, "fixture geladen")
	for c in cases:
		var name: String = c.name
		var m := ExtHashModel.new()
		m.setup(int(c.n), int(c.g), int(c.start.a))
		m.load_layout(c.start.layout)
		var ok_all := true
		for ki in c.steps.size():
			var hv := int(c.keys[ki])
			var sim := m.simulate_insert(hv)
			var want: Array = c.steps[ki]
			var same := sim.size() == want.size()
			if same:
				for si in sim.size():
					var s: Dictionary = sim[si]
					var w: Dictionary = want[si]
					same = same and s.act == w.act and int(s.idx) == int(w.idx) and int(s.a) == int(w.a) and int(s.ab) == int(w.ab)
					same = same and _ints(s.stay) == _ints(w.stay) and _ints(s.move) == _ints(w.move) and _ints(s.changed) == _ints(w.changed)
			if not same:
				t.ok(false, "%s sleutel %d: simulate_insert %s != JS %s" % [name, ki, str(sim), str(want)])
				ok_all = false
				break
			var before := m.snapshot()
			var res := m.auto_insert(m.new_parcel(hv))
			var last: String = want[-1].act
			if res != ("ok" if last == "place" else "fail"):
				t.ok(false, "%s sleutel %d: auto_insert %s, JS %s" % [name, ki, res, last])
				ok_all = false
				break
			# simulate_insert muteert niet
			if before.dir != Array(m.dir) and false:
				pass
			if not m.invariants().is_empty():
				t.ok(false, "%s: invariants %s" % [name, str(m.invariants())])
				ok_all = false
				break
		t.ok(ok_all, name + ": stappen gelijk")
		t.eq(m.a, int(c.end_a), name + ": eind-a")
		var lay := m.layout()
		var got := []
		for L in lay:
			got.append({"label": L.label, "ab": int(L.ab), "keys": m.buckets[int(L.bucket_id)].parcels.map(func(p): return p.hv)})
		var want_end := []
		for e in c.end:
			want_end.append({"label": e.label, "ab": int(e.ab), "keys": _ints(e.keys)})
		t.eq(str(got), str(want_end), name + ": eindtoestand")
	# simulate_insert is niet-muterend
	var m2 := ExtHashModel.new()
	m2.setup(5, 2, 1)
	for s in ["00100", "01111", "10010", "11100", "11111"]:
		m2.auto_insert(m2.new_parcel(HashUtil.from_bits(s)))
	var snap := m2.snapshot()
	var steps := m2.simulate_insert(HashUtil.from_bits("11110"))
	t.eq(steps.map(func(s): return s.act), ["double", "split", "double", "split", "place"], "11110: kettingreactie-stappen")
	t.eq(m2.snapshot(), snap, "simulate_insert muteert niet")


func _ints(arr) -> Array:
	var out := []
	for x in arr:
		out.append(int(x))
	return out
