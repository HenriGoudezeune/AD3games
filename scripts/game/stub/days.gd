extends RefCounted
## STUB (tijdelijk) van core Days: dag 1–3 uit GDD §5.2. Wordt vervangen door scripts/core/days.gd.

const Spec := preload("res://scripts/game/stub/day_spec.gd")


static func count() -> int:
	return 3


static func _keys(s: String) -> Array:
	var out := []
	for k in s.split(" ", false):
		out.append({"hv": k, "label": ""})
	return out


static func get_day(i: int):
	var d := Spec.new()
	d.id = str(i)
	match i:
		1:
			d.title = "Eerste werkdag"
			d.intro = "Eerste bit = het luik."
			d.n = 5; d.g = 3; d.a0 = 1
			d.keys = _keys("00110 10101 01011 11000 00011 10010")
			d.bit_hint = 0
			d.stars = [{"kind": "done"}, {"kind": "no_mistakes"}, {"kind": "time", "max": 40}]
		2:
			d.title = "De muur schuift"
			d.intro = "Eén buis? Trek aan de hendel."
			d.n = 5; d.g = 2; d.a0 = 1
			d.keys = _keys("00100 01111 10010 11100 11111 10111")
			d.bit_hint = 0
			d.stars = [{"kind": "done"}, {"kind": "no_mistakes"}, {"kind": "io_optimal"}]
		_:
			d.title = "Bijbouwen"
			d.intro = "Twee buizen of meer? Zagen."
			d.n = 5; d.g = 2; d.a0 = 3
			d.start_layout = [{"label": "0", "hvs": ["00100", "01111"]}, {"label": "10", "hvs": ["10010"]},
				{"label": "110", "hvs": ["11000"]}, {"label": "111", "hvs": ["11100"]}]
			d.keys = _keys("00110 10111 10000 01001 00010 11001 01110 11111")
			d.bit_hint = 1
			d.stars = [{"kind": "done"}, {"kind": "no_mistakes"}, {"kind": "no_doubles"}]
	d.mode = 0
	d.spawn_interval = 2.5
	return d


static func optimum(spec) -> Dictionary:
	var m := ExtHashModel.new()
	m.setup(spec.n, spec.g, spec.a0)
	m.load_layout(spec.start_layout)
	for k in spec.keys:
		m.auto_insert(m.new_parcel(HashUtil.from_bits(k.hv)))
	return {"reads": m.reads, "writes": m.writes, "doubles": m.doubles, "splits": m.splits}
