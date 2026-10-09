class_name Days
## Alle dagen van de campagne (GDD §5.2) + endless. Exacte configuraties en verwachte eindtoestanden (§11).


static func count() -> int:
	return 7


## 1..7; 0 = endless. Ongeldig -> null.
static func get_day(i: int) -> DaySpec:
	match i:
		0: return _endless()
		1: return _day1()
		2: return _day2()
		3: return _day3()
		4: return _day4()
		5: return _day5()
		6: return _day6()
		7: return _day7()
	return null


static func _keys(s: String, labels: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i := 0
	for tok in s.split(" ", false):
		var clone := tok.ends_with("*")
		var hv := tok.trim_suffix("*")
		out.append({"hv": hv, "label": str(labels[i]) if i < labels.size() else "", "clone": clone})
		i += 1
	return out


## "0{00100,01111} 10{10010}" -> [{label, hvs}]
static func layout_from(s: String) -> Array:
	var out := []
	for tok in s.split(" ", false):
		var lb := tok.find("{")
		var label := tok.substr(0, lb)
		var inner := tok.substr(lb + 1, tok.length() - lb - 2)
		var hvs := []
		for h in inner.split(",", false):
			hvs.append(h)
		out.append({"label": label, "hvs": hvs})
	return out


static func _stars(third: Dictionary, second: Dictionary = {"kind": "no_mistakes"}) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"kind": "done"}, second, third]
	return out


static func _hints(arr: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in arr:
		out.append(h)
	return out


static func _base(id: String, num: int, title: String, n: int, g: int, a0: int) -> DaySpec:
	var s := DaySpec.new()
	s.id = id
	s.day_number = num
	s.title = title
	s.n = n
	s.g = g
	s.a0 = a0
	return s


static func _day1() -> DaySpec:
	var s := _base("day1", 1, "Eerste werkdag", 5, 3, 1)
	s.mode = DaySpec.Mode.CALM
	s.bit_hint = DaySpec.BitHint.FULL
	s.keys = _keys("00110 10101 01011 11000 00011 10010")
	s.spawn_interval = 2.5
	s.stars = _stars({"kind": "time", "max": 40.0})
	s.intro = "Eerste bit. Dat is het luik."
	s.icon = "hatch"
	s.hints = _hints([
		{"trigger": "start", "anchor": "hatch", "ghost": "drag_parcel", "text": "Eerste bit. Dat is het luik."},
		{"trigger": "idle", "anchor": "hatch", "ghost": "", "text": ""},
	])
	s.expect_end = {"a": 1, "layout": layout_from("0{00110,01011,00011} 1{10101,11000,10010}"), "reads": 6, "writes": 6, "doubles": 0, "splits": 0}
	return s


static func _day2() -> DaySpec:
	var s := _base("day2", 2, "De muur schuift", 5, 2, 1)
	s.bit_hint = DaySpec.BitHint.FULL
	s.keys = _keys("00100 01111 10010 11100 11111 10111")
	s.spawn_interval = 2.5
	s.stars = _stars({"kind": "io_optimal"})
	s.intro = "Vol rek, één buis: trek de hendel."
	s.icon = "lever"
	s.hints = _hints([
		{"trigger": "first_block", "anchor": "lever", "ghost": "drag_lever", "text": "Eén buis. Maak er twee."},
		{"trigger": "first_double", "anchor": "saw", "ghost": "click_saw", "text": "Nu kan het."},
		{"trigger": "first_sort", "anchor": "sort_table", "ghost": "sort_parcel", "text": ""},
	])
	s.expect_end = {"a": 2, "layout": layout_from("0{00100,01111} 10{10010,10111} 11{11100,11111}"), "reads": 6, "writes": 7, "doubles": 1, "splits": 1}
	return s


static func _day3() -> DaySpec:
	var s := _base("day3", 3, "Bijbouwen", 5, 2, 3)
	s.bit_hint = DaySpec.BitHint.COLORS
	s.start_layout = layout_from("0{00100,01111} 10{10010} 110{11000} 111{11100}")
	s.keys = _keys("00110 10111 10000 01001 00010 11001 01110 11111")
	s.spawn_interval = 2.5
	s.stars = _stars({"kind": "no_doubles"})
	s.intro = "Meer buizen? Dan mag de zaag."
	s.icon = "saw"
	s.hints = _hints([
		{"trigger": "first_block", "anchor": "rack_pipes", "ghost": "count_pipes", "text": ""},
	])
	s.expect_end = {"a": 3, "layout": layout_from("000{00010} 001{00100,00110} 010{01001} 011{01111,01110} 100{10010,10000} 101{10111} 110{11000,11001} 111{11100,11111}"),
		"reads": 8, "writes": 12, "doubles": 0, "splits": 4}
	return s


static func _day4() -> DaySpec:
	var s := _base("day4", 4, "Klanten aan de balie", 5, 2, 2)
	s.mode = DaySpec.Mode.REALTIME
	s.bit_hint = DaySpec.BitHint.COLORS
	s.start_layout = layout_from("0{00011} 10{10100} 11{11010}")
	s.keys = _keys("01101 10001 00110 11100 10110 01000 00000 11111 10011 01011 00101 11000")
	s.spawn_interval = 4.0
	s.belt_time = 14.0
	s.burst_time = 12.0
	s.reputation = 5
	for c in [[20.0, "01101"], [32.0, "10001"], [44.0, "10110"], [56.0, "00000"], [68.0, "11111"]]:
		s.customers.append({"t": c[0], "hv": c[1], "patience": 15.0})
	s.stars = _stars({"kind": "io_optimal"}, {"kind": "no_mistakes", "all_customers": true})
	s.intro = "Zoeken = zelfde luik."
	s.icon = "desk"
	s.hints = _hints([
		{"trigger": "first_customer", "anchor": "hatch", "ghost": "click_hatch", "text": "Zoeken = zelfde luik."},
	])
	s.expect_end = {"a": 3, "layout": layout_from("000{00011,00000} 001{00110,00101} 010{01000,01011} 011{01101} 100{10001,10011} 101{10100,10110} 110{11010,11000} 111{11100,11111}"),
		"reads": 12 + 5, "writes": 17, "doubles": 1, "splits": 5}
	return s


static func _day5() -> DaySpec:
	var s := _base("day5", 5, "De 11110-storm", 5, 2, 2)
	s.mode = DaySpec.Mode.REALTIME
	s.bit_hint = DaySpec.BitHint.NONE
	s.loupe_allowed = true
	s.start_layout = layout_from("0{00100,01111} 10{10010} 11{11100,11111}")
	s.keys = _keys("11110 00110 10011 01010 11010 10100 00001 01100 10111 11001")
	s.spawn_interval = 3.5
	s.belt_time = 14.0
	s.burst_time = 12.0
	# QA P2-5: GDD zei "elke 10 s vanaf 25 s", maar de dag is dan te kort voor meer dan één klant
	s.customer_gen = {"start": 12.0, "every": 9.0, "patience": 14.0, "seed": 5}
	s.stars = _stars({"kind": "io_optimal"})
	s.intro = "Een storm van enen."
	s.icon = "storm"
	s.hints = _hints([
		{"trigger": "still_blocked", "anchor": "lever", "ghost": "", "text": ""},
	])
	s.expect_end = {"a": 4, "layout": layout_from("000{00001} 001{00100,00110} 010{01010} 011{01111,01100} 100{10010,10011} 101{10100,10111} 110{11010,11001} 1110{11100} 1111{11111,11110}"),
		"reads": 10, "writes": 16, "doubles": 2, "splits": 6}
	return s


static func _day6() -> DaySpec:
	var s := _base("day6", 6, "Oefening 5", 5, 2, 1)
	s.bit_hint = DaySpec.BitHint.NONE
	s.loupe_allowed = false
	s.show_keys = true
	s.keys = _keys("00000 11111 01001 10001 00010 00001", [3, 7, 12, 45, 44, 1])
	s.spawn_interval = 2.5
	s.stars = _stars({"kind": "no_mistakes"}, {"kind": "end_state"})
	s.intro = "Oefening 5 — lesnotas p. 10"
	s.icon = "book"
	s.expect_end = {"a": 4, "layout": layout_from("0000{00000,00001} 0001{00010} 001{} 01{01001} 1{11111,10001}"),
		"reads": 6, "writes": 9, "doubles": 3, "splits": 3}
	return s


static func _day7() -> DaySpec:
	var s := _base("day7", 7, "De Klonen", 5, 2, 1)
	s.icon = "clones"
	s.intro = "Identieke pakjes. Kijk wat er gebeurt."
	s.stars = _stars({"kind": "io_optimal"})
	s.report_note = "Meer dan g identieke hashwaarden: de methode faalt (notas p. 8). Hoe je dit echt oplost: Oefening 4, zelf bedenken."
	var m := _base("day7_morning", 7, "De Klonen — ochtend", 5, 2, 1)
	m.bit_hint = DaySpec.BitHint.NONE
	m.keys = _keys("01001 10110 10110 10110")
	m.spawn_interval = 2.5
	m.no_stars = true
	m.report_note = "Geen bits meer. Identieke pakjes blijven samen, hoe vaak je ook verdubbelt of zaagt."
	m.intro = "Identieke pakjes. Kijk wat er gebeurt."
	m.icon = "clones"
	m.hints = _hints([
		{"trigger": "two_cycles", "anchor": "fast_forward", "ghost": "", "text": ""},
		{"trigger": "double_refused", "anchor": "lever", "ghost": "", "text": "Geen bits meer. Dit lost hendel noch zaag op."},
	])
	m.expect_end = {"a": 5, "layout": layout_from("0{01001} 100{} 1010{} 10110{10110,10110} 10111{} 11{}"), "fail": true}
	var pm := _base("day7_afternoon", 7, "De Klonen — middag", 5, 2, 1)
	pm.mode = DaySpec.Mode.REALTIME
	pm.bit_hint = DaySpec.BitHint.NONE
	pm.loupe_allowed = true
	pm.overflow_bin = true
	pm.keys = _keys("11001 00111 11001 01100 10010 11001* 00111 11010 00000 00111* 01110")
	pm.spawn_interval = 4.0
	pm.belt_time = 14.0
	pm.burst_time = 12.0
	pm.stars = _stars({"kind": "io_optimal"})
	pm.intro = "Derde kloon? In de bak (K)."
	pm.report_note = s.report_note
	pm.icon = "clones"
	pm.expect_end = {"a": 4, "layout": layout_from("000{00000} 001{00111,00111} 01{01100,01110} 10{10010} 1100{11001,11001} 1101{11010} 111{}"),
		"reads": 9, "writes": 14, "doubles": 3, "splits": 5, "dumped": ["11001", "00111"]}
	s.phases.append(m)
	s.phases.append(pm)
	# de ouder-spec neemt de configuratie van de ochtend over (start(spec) begint met fase 0)
	return s


static func _endless() -> DaySpec:
	var s := _base("endless", 0, "Piekdag", 6, 4, 1)
	s.endless = true
	s.mode = DaySpec.Mode.REALTIME
	s.bit_hint = DaySpec.BitHint.NONE
	s.loupe_allowed = true
	s.overflow_bin = true
	s.generator = {"seed": int(Time.get_unix_time_from_system()), "clone_after": 180.0, "clone_every": 40.0}
	s.customer_gen = {"start": 30.0, "every": 11.0, "patience": 15.0, "seed": 0, "endless": true}
	s.spawn_interval = 4.0
	s.belt_time = 14.0
	s.burst_time = 12.0
	s.reputation = 5
	s.stars = []
	s.intro = "Hoe lang hou jij het vol?"
	s.icon = "endless"
	return s


## Tempo van endless op speltijd t (GDD §5.2): niveau L = floor(t / 30).
static func endless_tempo(t: float) -> Dictionary:
	var lv := int(floor(t / 30.0))
	return {
		"level": lv,
		"spawn_interval": maxf(1.3, 4.0 - 0.25 * lv),
		"belt_time": maxf(8.0, 14.0 - 0.5 * lv),
		"customer_every": maxf(5.0, 11.0 - 0.5 * lv),
		"patience": maxf(8.0, 15.0 - 0.5 * lv),
	}


## Optimum bij perfect spel (correct_move-bot), zonder klanten:
## {reads, writes, doubles, splits, dumps, customers (aantal vaste klanten), end (describe()), a}.
## Ouder-spec met fasen -> optimum van de laatste fase (de fase met sterren).
static func optimum(spec: DaySpec) -> Dictionary:
	if spec == null:
		return {}
	if not spec.phases.is_empty():
		return optimum(spec.phases[-1])
	var m := ExtHashModel.new()
	m.setup(spec.n, spec.g, spec.a0)
	m.load_layout(spec.start_layout)
	m.allow_dump = spec.overflow_bin
	var dumps := 0
	var failed := false
	for k in spec.keys:
		var p := m.new_parcel(HashUtil.from_bits(str(k.hv)), str(k.get("label", "")), bool(k.get("clone", false)))
		var r := m.auto_insert(p)
		if r == "dump":
			dumps += 1
		elif r == "fail":
			failed = true
			m.lose(p, "burst", true)
	return {"reads": m.reads, "writes": m.writes, "doubles": m.doubles, "splits": m.splits, "dumps": dumps,
		"customers": spec.customers.size(), "a": m.a, "end": m.describe(), "fail": failed}
