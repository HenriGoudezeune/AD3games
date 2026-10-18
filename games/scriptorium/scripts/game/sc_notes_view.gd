class_name ScNotesView
extends Control
## Notas-weergave (GDD §6.5 punt 4 en 6): het level zoals de notas het tekenen (de stappen van Algoritme 9, de
## [g,o]-bomen, het rekenboek, de drietallen met hun ramen, de LZW-stappen, de gesorteerde matrix, de move-to-front-
## regels) en, ernaast, jouw werk. Verschillen in sepia (met een streepje), de juiste regels in inkt. Kaal perkament,
## zoals in de andere games: geen chips, geen schaduw.

signal closed

const R := Rect2(80, 60, 1760, 960)

var spec: ScLevelSpec
var director: ScDirector
var rep: Dictionary
var _pages: Array = []          # [{title, notes:[lines], yours:[lines]}]
var _page := 0
var _n: Node2D
var _tabs: Array = []


func setup(s: ScLevelSpec, d: ScDirector, r: Dictionary) -> void:
	spec = s
	director = d
	rep = r
	_build_pages()


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.5)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	var b := ScUi.button("Sluiten", ScUi.Kind.PRIMARY, 24, 200)
	b.position = Vector2(R.end.x - 240, R.end.y - 76)
	b.pressed.connect(_close)
	add_child(b)


func _close() -> void:
	closed.emit()
	queue_free()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		for i in _tabs.size():
			if (_tabs[i] as Rect2).has_point(ev.position):
				_page = i
				_n.queue_redraw()
				ScSnd.play("page_turn", -10.0)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_ESCAPE:
				_close()
			KEY_TAB, KEY_PAGEDOWN:
				_page = (_page + 1) % maxi(1, _pages.size())
				_n.queue_redraw()
			_:
				return
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ inhoud

func _build_pages() -> void:
	var structs: Array = rep.get("structures", [])
	var carry := {}
	for i in spec.stages.size():
		var st: Dictionary = spec.stages[i]
		var yours: Dictionary = {}
		for s in structs:
			if int(s.stage) == i:
				yours = s.yours
		var pg := _stage_page(st, carry, yours)
		pg["title"] = "Stage %d · %s" % [i + 1, ScSession.tool_title(str(st.get("tool", "")))]
		_pages.append(pg)
		var opt: Array = ScLevels.optimum(spec).get("stages", [])
		carry = (opt[i] as Dictionary).get("output", {}) if i < opt.size() else {}


func _sh(s: String) -> String:
	return ScPal.show_text(s)


func _stage_page(st: Dictionary, carry: Dictionary, yours: Dictionary) -> Dictionary:
	var notes: Array = []
	var mine: Array = []
	var tl := str(st.get("tool", ""))
	var recv := str(st.get("side", "send")) == "receive"
	match tl:
		"prefix_read":
			var code: Dictionary = st.get("code", carry.get("code", {}))
			var bits := str(st.get("bits", ""))
			if bits == "" and st.has("text"):
				bits = ScReference.encode_with(code, str(st.text))
			var dec := ScReference.decode_prefix(code, bits)
			var keys := code.keys()
			keys.sort()
			for k in keys:
				notes.append("%s = %s" % [_sh(str(k)), str(code[k])])
			notes.append("")
			var parts := PackedStringArray()
			var s := 0
			for cpos in dec.cuts:
				parts.append(bits.substr(s, int(cpos) - s))
				s = int(cpos)
			notes.append("%s  =  %s" % [" · ".join(parts), _sh(str(dec.text))])
			mine.append("kopie: %s" % _sh(str(yours.get("copy", ""))))
		"code_board":
			if str(st.get("mode", "")) == "cuts":
				notes.append("code: e = 0, n = 1, b = 10 (geen prefixcode)")
				notes.append("strook %s, alle lezingen:" % str(st.get("bits", "")))
				for p in ScReference.all_parses(st.code, str(st.bits)):
					notes.append("  " + _sh(p))
				notes.append("Letterlijk (gulzig): " + ScReference.greedy_read(st.code, str(st.bits)))
				mine.append("jouw lezingen:")
				for p2 in yours.get("readings", []):
					mine.append("  " + _sh(str(p2)))
			else:
				var fr := ScReference.freqs_in_order(str(st.text))
				var h := ScReference.huffman(fr)
				notes.append("a(x): " + ", ".join(fr.map(func(x): return "%s %d" % [_sh(str(x[0])), int(x[1])])))
				for k in h.codes:
					notes.append("%s = %s" % [_sh(str(k)), str(h.codes[k])])
				notes.append("Σ a(x)·l(x) = %d bits" % int(h.cost))
				var yc: Dictionary = yours.get("code", {})
				for k2 in yc:
					mine.append("%s = %s" % [_sh(str(k2)), str(yc[k2])])
				if not yc.is_empty():
					var ok := ScReference.is_prefix_code(yc)
					mine.append("prefixcode: %s · kost %d" % ["ja" if ok else "NEE", ScReference.code_cost(yc, fr)])
		"bindery":
			var fr2: Array = []
			if st.has("weights"):
				for x in st.weights:
					fr2.append([str(x[0]), int(x[1])])
			elif str(st.get("symbols", "")) == "carry":
				var syms: Array = []
				for x in carry.get("symbols", []):
					syms.append(str(x))
				fr2 = ScReference.freqs_of(syms)
			else:
				var seq: Array = []
				for ch in str(st.text):
					seq.append(ch)
				var ord: Array = []
				for ch in str(st.get("row", "")):
					ord.append(ch)
				fr2 = ScReference.freqs_of(seq, ord)
			var h2 := ScReference.huffman(fr2)
			var tw := 0
			for stp in h2.steps:
				tw += int(stp.w)
				var rl: Array = stp.row_labels
				notes.append("%s  →  %s + %s = %d   (touw %d)" % [_sh(" ".join(PackedStringArray(rl))), _sh(str(rl[int(stp.i)])),
					_sh(str(rl[int(stp.j)])), int(stp.w), tw])
			notes.append("")
			var keys2: Array = h2.codes.keys()
			for k in keys2:
				notes.append("%s  %s" % [_sh(str(k)), str(h2.codes[k])])
			notes.append("touw = bits = %d (Stelling 21)" % int(h2.cost))
			var yc2: Dictionary = yours.get("codes", {})
			for k in yc2:
				var bad := str(yc2[k]).length() != str(h2.codes.get(k, "")).length()
				mine.append(("✕ " if bad else "") + "%s  %s" % [_sh(str(k)), str(yc2[k])])
			mine.append("touw %d" % int(yours.get("twine", 0)))
		"living_tree":
			if recv:
				var tk = st.get("tokens", [])
				var toks: Array = ScReference.tokens_from_string(tk) if tk is String else tk
				var dec2 := ScReference.adaptive_decode(toks, str(st.get("start", "empty")))
				notes.append("kopie: " + _sh(str(dec2.text)))
				for stp in dec2.get("steps", []):
					if stp is Dictionary and stp.has("tree"):
						notes.append("%s  →  %s" % [_sh(str(stp.get("ch", ""))), str(stp.tree)])
			else:
				var enc := ScReference.adaptive_encode(str(st.text), str(st.get("start", "empty")))
				for stp in enc.steps:
					var ts := ScReference.tokens_to_string(stp.tokens)
					notes.append("%s  uit %s" % [_sh(str(stp.ch)), ts])
					notes.append("    %s" % str(stp.tree))
				notes.append("%d bits" % int(enc.bits))
			mine.append("jouw boom op het einde:")
			mine.append("    " + str(yours.get("tree", "")))
		"ruler":
			var model: Array = st.get("model", [])
			if recv:
				var src = st.get("bits", "")
				var dc := ScReference.arith_decode(ScDec.from_string(str(st.pin)) if st.has("pin") else str(src), int(st.get("n", 0)), model)
				notes.append("%s → %s" % [str(st.get("bits", st.get("pin", ""))), str(dc.text)])
				mine.append("jouw kopie: " + str(yours.get("copy", "")))
			else:
				var iv := ScReference.get_interval(str(st.text), model)
				notes.append("i  teken  links  lengte")
				for b in iv.book:
					notes.append("%d  %s  %s  %s" % [int(b.i), str(b.sym), ScDec.from_string(str(b.links)).to_string_sig(14),
						ScDec.from_string(str(b.lengte)).to_string_sig(14)])
				var bs := ScReference.get_bitstring(iv.low, iv.up)
				notes.append("[%s; %s)" % [(iv.low as ScDec).to_string_sig(16), (iv.up as ScDec).to_string_sig(16)])
				notes.append("bits: %s" % str(bs.bits))
				var bk: Array = yours.get("book", [])
				for b2 in bk:
					mine.append("%d  %s  %s  %s" % [int(b2.i), str(b2.sym), ScDec.from_string(str(b2.links)).to_string_sig(14),
						ScDec.from_string(str(b2.lengte)).to_string_sig(14)])
				mine.append("bits: %s" % str(yours.get("bits", "")))
		"window":
			var G := int(st.get("G", -1))
			if recv:
				var full := ScReference.lz77_decode_full(st.triples, G)
				var wins: Array = full.get("windows", [])
				for q in (st.triples as Array).size():
					var tr: Array = st.triples[q]
					notes.append("(%d,%d,%s)  raam %s" % [int(tr[0]), int(tr[1]), _sh(str(tr[2])), _sh(str(wins[q])) if q < wins.size() else ""])
				notes.append("kopie: " + _sh(str(full.text)))
				mine.append("jouw kopie: " + _sh(str(yours.get("copy", ""))))
			else:
				var lz := ScReference.lz77_encode(str(st.text), G)
				for q in (lz.triples as Array).size():
					var tr2: Array = lz.triples[q]
					var inf: Dictionary = lz.info[q]
					notes.append("k=%d  raam %-8s (%d,%d,%s)" % [int(inf.k), _sh(str(inf.window)), int(tr2[0]), int(tr2[1]), _sh(str(tr2[2]))])
				notes.append("%d zegels" % (lz.triples as Array).size())
				for tr3 in yours.get("triples", []):
					mine.append("(%d,%d,%s)" % [int(tr3[0]), int(tr3[1]), _sh(str(tr3[2]))])
				mine.append("%d zegels" % (yours.get("triples", []) as Array).size())
		"stampcase":
			if recv:
				var dz := ScReference.lzw_decode(st.codes)
				notes.append("kopie: " + _sh(str(dz.text)))
				for a in dz.adds:
					notes.append("%d = %s" % [int(a[0]), _sh(str(a[1]))])
				mine.append("jouw kast:")
				var ws: Array = yours.get("words", [])
				for q in ws.size():
					mine.append("%d = %s" % [256 + q, _sh(str(ws[q]))])
			else:
				var lw := ScReference.lzw_encode(str(st.text))
				notes.append("codes: " + " ".join(PackedStringArray((lw.codes as Array).map(func(x): return str(x)))))
				for a in lw.adds:
					notes.append("%d = %s" % [int(a[0]), _sh(str(a[1]))])
				mine.append("codes: " + " ".join(PackedStringArray((yours.get("codes", []) as Array).map(func(x): return str(x)))))
				var ws2: Array = yours.get("words", [])
				for q in ws2.size():
					mine.append("%d = %s" % [256 + q, _sh(str(ws2[q]))])
		"drum":
			if recv:
				var ib := ScReference.inverse_bwt(int(st.p), str(st.c))
				notes.append("c = %s   e = %s" % [_sh(str(st.c)), _sh(str(ib.e))])
				var rows := PackedStringArray()
				for wk in ib.walk:
					rows.append("%s%d→%d" % [_sh(str(wk.ch)), int(wk.rank), int(wk.i)])
				notes.append(" ".join(rows))
				notes.append("tekst: " + _sh(str(ib.text)))
				mine.append("jouw kopie: " + _sh(str(yours.get("copy", ""))))
			else:
				var bw := ScReference.bwt(str(st.text))
				for q in (bw.rows as Array).size():
					notes.append("%d  %s" % [q, _sh(str(bw.rows[q]))])
				notes.append("p = %d, c = %s" % [int(bw.p), _sh(str(bw.c))])
				var yr: Array = yours.get("rows", [])
				for q in yr.size():
					var bad2 := q < (bw.rows as Array).size() and str(yr[q]) != str(bw.rows[q])
					mine.append(("✕ " if bad2 else "") + "%d  %s" % [q, _sh(str(yr[q]))])
				mine.append("p = %d, c = %s" % [int(yours.get("p", -1)), _sh(str(yours.get("c", "")))])
		"shelf":
			var lst: Array = st.get("list", [])
			if recv:
				var md := ScReference.mtf_decode(st.nums, lst)
				for q in (st.nums as Array).size():
					notes.append("lees %d: %s, lijst nu (%s)" % [int(st.nums[q]), _sh(str(md.text)[q]),
						_sh(",".join(PackedStringArray(md.lists[q])))])
				mine.append("jouw kopie: " + _sh(str(yours.get("copy", ""))))
			else:
				var inp := str(carry.get("text", "")) if str(st.get("input", "")) == "carry" else str(st.get("input", ""))
				var me := ScReference.mtf_encode(inp, lst)
				for q in inp.length():
					notes.append("lees %s: schrijf %d, lijst nu (%s)" % [_sh(inp[q]), int(me.nums[q]),
						_sh(",".join(PackedStringArray(me.lists[q])))])
				mine.append("jouw getallen: " + ",".join(PackedStringArray((yours.get("nums", []) as Array).map(func(x): return str(x)))))
		"dovecote":
			notes.append("8 duiven, 7 kortere hokken (ε, 0, 1, 00, 01, 10, 11)")
			notes.append("1 + 2 + 4 = 7 < 8 = 2³")
			notes.append("decreet 1: onmogelijk · decreet 2: waar (Oef. 76)")
	return {"notes": notes, "yours": mine}


# ------------------------------------------------------------------ tekenen

func _paint() -> void:
	var c := _n
	ScDraw.parchment(c, R, 71, ScPal.VELLUM_HI, true, 0.3)
	ScPal.text_l(c, ScPal.TITLE, R.position + Vector2(40, 50), "Zoals de notas het schrijven", 44, ScPal.INK)
	ScPal.text_l(c, ScPal.UI_MED, R.position + Vector2(40, 92), "%s %s · %s" % [spec.id, spec.title, spec.notes_ref], 20, ScPal.INK_SOFT)
	_tabs = []
	var x := R.position.x + 40
	for i in _pages.size():
		var tt := str(_pages[i].title)
		var w := ScPal.text_w(ScPal.UI_BOLD, tt, 20) + 30
		var tr := Rect2(x, R.position.y + 116, w, 40)
		_tabs.append(tr)
		c.draw_rect(tr, ScPal.VELLUM if i != _page else ScPal.VELLUM_EDGE)
		c.draw_rect(tr, ScPal.INK, false, 2.0)
		ScPal.text_l(c, ScPal.UI_BOLD, tr.position + Vector2(15, 20), tt, 20, ScPal.INK)
		x += w + 10
	if _pages.is_empty():
		return
	var pg: Dictionary = _pages[_page]
	var top := R.position.y + 200
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(R.position.x + 40, top), "Notas", 24, ScPal.RUBRIC)
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(R.position.x + 1060, top), "Jij", 24, ScPal.RUBRIC)
	c.draw_line(Vector2(R.position.x + 1030, top - 10), Vector2(R.position.x + 1030, R.end.y - 100), ScPal.INK_FADED, 2.0)
	_lines(c, pg.notes, Vector2(R.position.x + 40, top + 44), 960, R.end.y - 110 - top)
	_lines(c, pg.yours, Vector2(R.position.x + 1060, top + 44), 640, R.end.y - 110 - top, pg.notes)


func _lines(c: CanvasItem, lines: Array, pos: Vector2, width: float, height: float, ref: Array = []) -> void:
	if lines.is_empty():
		return
	var size := 22
	while size > 14 and lines.size() * size * 1.45 > height:
		size -= 1
	var longest := 0
	for l in lines:
		longest = maxi(longest, str(l).length())
	while size > 14 and ScPal.text_w(ScPal.MONO_M, "M".repeat(longest), size) > width:
		size -= 1
	var y := pos.y
	for l in lines:
		var s := str(l)
		var bad := s.begins_with("✕ ")
		if bad:
			s = s.substr(2)
		ScPal.text_l(c, ScPal.MONO_M, Vector2(pos.x, y), s, size, ScPal.SEPIA if bad else ScPal.INK)
		if bad:
			var w := ScPal.text_w(ScPal.MONO_M, s, size)
			c.draw_line(Vector2(pos.x, y + size * 0.6), Vector2(pos.x + w, y + size * 0.6), ScPal.SEPIA, 2.0)
		y += size * 1.45
