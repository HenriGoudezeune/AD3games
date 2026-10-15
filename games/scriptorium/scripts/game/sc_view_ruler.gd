extends ScView
## Meetlat + binaire naald (GDD §3.5, §4.4, juice #20–23): de staande lat (0 onder, 1 boven) toont altijd het
## huidige interval, verdeeld in de vakken van het model (kleur + arcering). Knippen: klik het vak van het volgende
## teken (of typ de letter); de schaar knipt en de lat zoomt in (0,6 s). Het rekenboek noteert i · teken · links ·
## lengte. Daarna de binaire naald (Algoritme 13): 1 = stap, 0 = blijf (toetsen 1/0). Ontvangen: een koperen speld
## staat op de waarde van de bits; klik het vak waarin ze zit (onderrand dicht, bovenrand open).

const LAT := Rect2(170, 290, 120, 560)
const NEEDLE_R := Rect2(380, 720, 760, 90)

var _zoom := {}                 # {a0, b0, a1, b1, segs, labels}
var _snip := 0.0
var _needle := {}
var _auto_k := 0
var _zones_sym := {}


func _setup() -> void:
	var s := ""
	for m in stage.get("model", []):
		s += str(m[0])
	alphabet = s


func _phase() -> String:
	return str(cur.get("phase_name", ""))


func _recv() -> bool:
	return int(cur.get("side", 0)) == ScCodes.Side.RECEIVE


static func sig(s: String, n := 10) -> String:
	if s == "":
		return ""
	return ScDec.from_string(s).to_string_sig(n)


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"segment":
			var a1 := ScDec.from_string(str(fx.lo)).to_float()
			var b1 := ScDec.from_string(str(fx.hi)).to_float()
			_zoom = {"a0": float(cur.get("low_f", 0.0)), "b0": float(cur.get("up_f", 1.0)), "a1": a1, "b1": b1,
				"segs": (cur.get("segs", []) as Array).duplicate(true), "sym": str(fx.sym)}
			var auto := bool(fx.get("auto", false))
			var dur := (0.12 if auto else 0.6) * spd
			start_anim("zoom", dur)
			if auto:
				_auto_k += 1
				ScSnd.pluck(mini(_auto_k / 3, 10), "needle_tick", -10.0)
			else:
				_auto_k = 0
				ScSnd.play("scissors", -4.0)
				ScSnd.play("ruler_zoom", -8.0)
				var zr: Rect2 = _zones_sym.get(str(fx.sym), LAT)
				burst_at("snip", Vector2(LAT.end.x + 20, zr.get_center().y))
			return dur + (0.0 if auto else 0.05)
		"needle":
			_needle = fx.duplicate()
			start_anim("needle", 0.25 * spd)
			ScSnd.play("needle_tick", -4.0)
			if bool(fx.get("inside", false)) and int(fx.bit) == 1:
				ScSnd.play("needle_gold", -6.0)
				burst_at("gold", _needle_x(ScDec.from_string(str(fx.getal)).to_float()))
			if bool(fx.get("overshoot", false)):
				ScSnd.play("clamp", -10.0)
			return 0.3 * spd
		"needle_reset":
			ScSnd.play("drawer_empty", -8.0)
			_needle = {}
			return 0.4
		"pin":
			ScSnd.play("pin", -4.0)
			start_anim("pin", 0.3)
			return 0.3
	return super.play(fx)


func _on_commit() -> void:
	pass


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"no_pin":
			return "De speld zit niet in dat vak."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	if str(m.get("act", "")) == "bit":
		return Vector2(1200, 990) if int(m.b) == 1 else Vector2(1380, 990)
	var zr: Rect2 = _zones_sym.get(str(m.get("sym", "")), LAT)
	return zr.get_center()


func buttons() -> Array:
	if _phase() == "NEEDLE" and not readonly:
		return [{"text": "1 · stap", "move": {"act": "bit", "b": 1}, "kind": ScUi.Kind.PRIMARY, "key": "1"},
			{"text": "0 · blijf", "move": {"act": "bit", "b": 0}, "kind": ScUi.Kind.VELLUM, "key": "0"}]
	return []


func key_move(ev: InputEventKey) -> Dictionary:
	if _phase() == "NEEDLE":
		if ev.keycode == KEY_1 or ev.keycode == KEY_KP_1:
			return {"act": "bit", "b": 1}
		if ev.keycode == KEY_0 or ev.keycode == KEY_KP_0:
			return {"act": "bit", "b": 0}
	if _phase() == "CUT":
		var ch := char(ev.unicode).to_lower() if ev.unicode > 0 else ""
		if ch != "" and alphabet.contains(ch):
			return {"act": "cut", "sym": ch}
	return {}


func band() -> Dictionary:
	if _recv():
		return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": true, "alphabet": alphabet,
			"idx": false, "note": "n = %d" % int(cur.get("n", 0))}
	var txt := str(stage.get("text", ""))
	var i := int(cur.get("i", 0))
	return {"label": "Opdracht", "text": txt, "cursor": i if _phase() == "CUT" else -1, "done": i, "chips": txt.length() <= 24,
		"alphabet": alphabet, "idx": txt.length() <= 24, "note": "n = %d" % txt.length()}


func strip() -> Dictionary:
	var r := tool as ScRuler
	if _recv():
		var src := str(stage.get("bits", ""))
		if src == "":
			return {"tokens": [], "consumed": -1, "unit": ""}
		return {"tokens": [{"b": src}], "consumed": 0, "unit": ""}
	return {"tokens": [{"b": r.bits}] if r.bits != "" else [], "consumed": -1, "unit": "bits"}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "needle":
		return [{"b": str(fx.bit)}]
	return []


# ------------------------------------------------------------------ tekenen

func _segs_in(view_a: float, view_b: float, segs: Array) -> Array:
	var out: Array = []
	var span := maxf(view_b - view_a, 1e-300)
	for s in segs:
		var lo := (float(s.lo_f) - view_a) / span
		var hi := (float(s.hi_f) - view_a) / span
		if hi <= 0.0 or lo >= 1.0:
			continue
		out.append({"sym": s.sym, "lo": clampf(lo, 0.0, 1.0), "hi": clampf(hi, 0.0, 1.0)})
	return out


func _paint() -> void:
	caption("De meetlat", "onder dicht, boven open · links += f·lengte · lengte ×= p")
	var segs: Array = cur.get("segs", [])
	var low := float(cur.get("low_f", 0.0))
	var up := float(cur.get("up_f", 1.0))
	var z := anim("zoom")
	var draw_segs: Array
	var labels: Array = []
	var zooming := not _zoom.is_empty() and z < 1.0
	if zooming:
		var e := z * z * (3.0 - 2.0 * z)
		var va := lerpf(float(_zoom.a0), float(_zoom.a1), e)
		var vb := lerpf(float(_zoom.b0), float(_zoom.b1), e)
		draw_segs = _segs_in(va, vb, _zoom.segs)
	else:
		draw_segs = []
		for s in segs:
			draw_segs.append({"sym": s.sym, "lo": (float(s.lo_f) - low) / maxf(up - low, 1e-300),
				"hi": (float(s.hi_f) - low) / maxf(up - low, 1e-300)})
		for s in segs:
			labels.append(str(s.lo_s))
		labels.append(sig(str(cur.get("up", "1")), 12))
	var pin := -1.0
	if _recv():
		pin = clampf((float(cur.get("pin_f", 0.0)) - low) / maxf(up - low, 1e-300), 0.0, 1.0)
	var hm := hover_move()
	var hs := str(hm.get("sym", "")) if str(hm.get("act", "")) == "cut" else ""
	if zooming:
		hs = str(_zoom.sym)
	_zones_sym = ScDrawTools.ruler(self, LAT, draw_segs, hs, pin if not zooming else -1.0, t, labels, true)
	if _phase() == "CUT" and not zooming:
		for s in _zones_sym:
			zone(_zones_sym[s], {"act": "cut", "sym": str(s)})
	if zooming:
		ScDrawTools.scissors(self, Vector2(LAT.end.x + 34, LAT.get_center().y), 1.0, 0.5 + 0.5 * sin(z * PI * 4.0), PI)
	# zoomladdertje (geneste intervallen)
	var book: Array = cur.get("book", [])
	_ladder(Rect2(LAT.end.x + 70, LAT.position.y, 40, LAT.size.y), book)
	# rekenboek
	var rows: Array = []
	var start := maxi(0, book.size() - 8)
	for q in range(start, book.size()):
		var b: Dictionary = book[q]
		rows.append([int(b.i), ScPal.show(str(b.sym)), sig(str(b.links), 12), sig(str(b.lengte), 12)])
	var bh := 30.0 * (rows.size() + 1) + 24
	ScDrawTools.ledger_table(self, Rect2(470, 290, 640, maxf(bh, 90)), ["i", "teken", "links", "lengte"], rows, 20,
		rows.size() - 1)
	var model: Array = stage.get("model", [])
	var mparts := PackedStringArray()
	for m in model:
		mparts.append("%s %s" % [ScPal.show(str(m[0])), str(m[1]).replace(".", ",")])
	table_label(Vector2(470, 266), "model: " + " · ".join(mparts), 20)
	if _recv():
		var src := str(stage.get("bits", ""))
		var val := sig(str(cur.get("pin", "")), 14)
		table_label(Vector2(470, 680), ("speld = %s" % val) + (" (bits %s)" % src if src != "" else ""), 22, ScPal.GOLD_LIGHT)
	# naald
	if _phase() == "NEEDLE" or (str(cur.get("bits", "")) != "" and not _recv()):
		_paint_needle(low, up)


func _ladder(r: Rect2, book: Array) -> void:
	draw_rect(r, Color(ScPal.PANEL_LO, 0.6))
	var a := 0.0
	var b := 1.0
	var y0 := r.end.y
	var y1 := r.position.y
	for q in book.size():
		var bk: Dictionary = book[q]
		var lo := ScDec.from_string(str(bk.links)).to_float()
		var hi := lo + ScDec.from_string(str(bk.lengte)).to_float()
		var span := maxf(b - a, 1e-300)
		var ny0 := y0 - (y0 - y1) * (lo - a) / span
		var ny1 := y0 - (y0 - y1) * (hi - a) / span
		draw_line(Vector2(r.position.x + 4, y0), Vector2(r.end.x - 4, ny0), Color(ScPal.GOLD, 0.6), 1.5, true)
		draw_line(Vector2(r.position.x + 4, y1), Vector2(r.end.x - 4, ny1), Color(ScPal.GOLD, 0.6), 1.5, true)
		a = lo
		b = hi
		y0 = r.end.y
		y1 = r.position.y
		if q >= 6:
			break
	ScPal.text_c(self, ScPal.UI_MED, Vector2(r.get_center().x, r.end.y + 26), "zoom", 16, ScPal.TEXT_DIM)


func _view() -> Vector2:
	var low := float(cur.get("low_f", 0.0))
	var up := float(cur.get("up_f", 1.0))
	var g := float(cur.get("getal_f", 0.0))
	var nx := float(cur.get("next_f", 0.5))
	var a := minf(low, g)
	var b := maxf(up, g + nx)
	var span := b - a
	if span > 0.3 or up - low < 1e-9:
		return Vector2(0.0, 1.0)
	return Vector2(maxf(0.0, a - span * 0.25), minf(1.0, b + span * 0.25))


func _needle_x(v: float) -> Vector2:
	var vw := _view()
	return Vector2(NEEDLE_R.position.x + NEEDLE_R.size.x * clampf((v - vw.x) / maxf(vw.y - vw.x, 1e-300), 0, 1), NEEDLE_R.get_center().y)


func _paint_needle(low: float, up: float) -> void:
	var vw := _view()
	var g := float(cur.get("getal_f", 0.0))
	var nx := float(cur.get("next_f", 0.5))
	var over := not _needle.is_empty() and bool(_needle.get("overshoot", false))
	var labels := {vw.x: str(snappedf(vw.x, 0.0001)).replace(".", ","), vw.y: str(snappedf(vw.y, 0.0001)).replace(".", ",")}
	if up - low > (vw.y - vw.x) * 0.08:
		labels[low] = sig(str(cur.get("low", "0")), 6)
		labels[up] = sig(str(cur.get("up", "1")), 6)
	ScDrawTools.needle(self, NEEDLE_R, vw.x, vw.y, low, up, g, nx, t, labels, over)
	ScPal.text_l(self, ScPal.UI_BOLD, NEEDLE_R.position + Vector2(0, -38), "Binaire naald", 22, ScPal.TEXT)
	ScPal.text_l(self, ScPal.MONO_M, NEEDLE_R.position + Vector2(190, -38), "getal %s · next %s · bits %s" % [
		sig(str(cur.get("getal", "0")), 8), sig(str(cur.get("next", "0.5")), 8), str(cur.get("bits", ""))], 20, ScPal.TEXT)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	var model: Array = stage.get("model", [])
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 22), "Letterlijk kent hetzelfde model:", 20, ScPal.TEXT)
	var y := r.position.y + 64
	var x := r.position.x + 14
	for k in model.size():
		var m: Array = model[k]
		var s := "%s  %s" % [ScPal.show(str(m[0])), str(m[1]).replace(".", ",")]
		var w := ScPal.text_w(ScPal.MONO_B, s, 22) + 26
		ci.draw_style_box(ScPal.sb(ScPal.segment_color(k), 8), Rect2(x, y - 17, w, 34))
		ScPal.text_l(ci, ScPal.MONO_B, Vector2(x + 13, y), s, 22, ScPal.INK)
		x += w + 10
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 120), "en de lengte n = %d." % int(cur.get("n", 0)), 20, ScPal.TEXT)
