extends ScView
## Stempelkast (GDD §3.7, §4.4, juice #28–30): links de kast met de basisladen van het level (letter + ASCII) en de
## nieuwe laden 256, 257, … Zenden: de zetstok houdt w, het volgende teken k ernaast; twee hendels: Verleng (V) en
## Stempel (S). Ontvangen: een code komt binnen, de lade gaat open; de speler snijdt de nieuwe stempel (klik de letter,
## of 1…9). Een lege lade (het speciale geval) is donker met stof: volgend = w + een letter van w.

const CAB := Rect2(40, 262, 720, 600)
const ZET := Vector2(800, 340)
const LEV_V := Vector2(860, 700)
const LEV_S := Vector2(1060, 700)

var _open := -1
var _empty := -1
var _fresh := -1
var _pull := {"V": 0.0, "S": 0.0}
var _stamp_t := -9.0
var _lever_r := {}
var _carve_r: Array = []
var _cab := {}


func _setup() -> void:
	var s := ""
	var src := str(stage.get("text", stage.get("expect", "")))
	for ch in src:
		if not s.contains(ch):
			s += ch
	alphabet = s if s.length() <= 10 else ""


func _recv() -> bool:
	return int(cur.get("side", 0)) == ScCodes.Side.RECEIVE


func _phase() -> String:
	return str(cur.get("phase_name", ""))


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"zetstok":
			ScSnd.play("block_slide", -10.0)
			return 0.12 * spd
		"stamp":
			_stamp_t = t
			_pull["S"] = 1.0
			create_tween().tween_method(func(v: float): _pull["S"] = v, 1.0, 0.0, 0.4 * spd)
			ScSnd.play("stamp", -2.0)
			if int(fx.get("new_code", -1)) >= 0:
				_fresh = int(fx.new_code)
				var tw := create_tween()
				tw.tween_interval(0.2 * spd)
				tw.tween_callback(func():
					ScSnd.play("drawer", -6.0)
					ScSnd.play("carve", -8.0)
					var r: Rect2 = _cab.get(_fresh, Rect2(CAB.get_center(), Vector2.ZERO))
					burst_at("shavings", r.get_center()))
			return 0.55 * spd
		"drawer":
			_open = int(fx.code)
			if bool(fx.get("empty", false)):
				_empty = int(fx.code)
				ScSnd.play("drawer_empty", -4.0)
				var r2: Rect2 = _cab.get(_empty, Rect2(CAB.get_center(), Vector2.ZERO))
				burst_at("dust", r2.get_center())
				say.emit("Die stempel snijd je nu pas. Hoe begint hij?")
			else:
				_empty = -1
				ScSnd.play("drawer", -6.0)
			return 0.4 * spd
		"carve":
			_fresh = int(fx.code)
			_empty = -1
			ScSnd.play("carve", -4.0)
			var r3: Rect2 = _cab.get(_fresh, Rect2(CAB.get_center(), Vector2.ZERO))
			burst_at("shavings", r3.get_center())
			return 0.4 * spd
	return super.play(fx)


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"no_stamp":
			return "Die stempel bestaat nog niet. Eerst stempelen."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	match str(m.get("act", "")):
		"extend":
			return (_lever_r.get("V", Rect2(LEV_V, Vector2.ZERO)) as Rect2).get_center()
		"stamp":
			return (_lever_r.get("S", Rect2(LEV_S, Vector2.ZERO)) as Rect2).get_center()
		"carve":
			var j := int(m.get("i", 0))
			if j < _carve_r.size():
				return (_carve_r[j] as Rect2).get_center()
	return AREA.get_center()


func key_move(ev: InputEventKey) -> Dictionary:
	if _phase() == "DECIDE":
		if ev.keycode == KEY_V:
			_pull_lever("V")
			return {"act": "extend"}
		if ev.keycode == KEY_S:
			return {"act": "stamp"}
	if _phase() == "CARVE":
		var d := ev.keycode - KEY_1
		if d >= 0 and d <= 8:
			return {"act": "carve", "i": d}
	return {}


func _click(m: Dictionary) -> void:
	if str(m.get("act", "")) == "extend":
		_pull_lever("V")
	super._click(m)


func _pull_lever(l: String) -> void:
	create_tween().tween_method(func(v: float): _pull[l] = v, 1.0, 0.0, 0.35)
	ScSnd.play("ui_wood", -6.0)


func band() -> Dictionary:
	if _recv():
		return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": alphabet != "", "alphabet": alphabet,
			"idx": false}
	var txt := str(stage.get("text", ""))
	var i := int(cur.get("i", 0))
	return {"label": "Opdracht", "text": txt, "cursor": i if _phase() == "DECIDE" else -1, "done": i - str(cur.get("w", "")).length() + 0,
		"chips": alphabet != "", "alphabet": alphabet, "idx": txt.length() <= 24}


func strip() -> Dictionary:
	var sc := tool as ScStampCase
	var toks: Array = []
	if _recv():
		for c in sc.codes_in:
			toks.append({"code": c})
		return {"tokens": toks, "consumed": sc.cpos, "unit": ""}
	for c in sc.out:
		toks.append({"code": c})
	return {"tokens": toks, "consumed": -1, "unit": "stempels"}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "stamp" and not _recv():
		return [{"code": int(fx.code)}]
	return []


func _paint() -> void:
	var recv := _recv()
	caption("De stempelkast", "zit het woord met de volgende letter al in de kast? verleng" if not recv
		else "nieuwe stempel = w + eerste letter van het volgende woord")
	var base: Array = []
	for b in cur.get("base", []):
		base.append([str(b.word), int(b.code)])
	var news: Array = []
	for e in cur.get("entries_new", []):
		news.append([int(e.code), str(e.word), bool(e.dup)])
	if _empty >= 0 and recv and _phase() == "CARVE":
		news.append([_empty, "", false])
	_cab = ScDrawTools.cabinet(self, CAB, base, news, _open, _empty if _phase() == "CARVE" else -1, _fresh, t, 5)
	if recv:
		_paint_recv()
	else:
		_paint_send()


func _paint_send() -> void:
	var w := str(cur.get("w", ""))
	var kk := str(cur.get("k", ""))
	var help := guides or (spec != null and spec.id == "5-1")
	ScDrawTools.zetstok(self, ZET, w, kk, bool(cur.get("in_case", false)) if help else false, 40, t)
	table_label(Vector2(ZET.x, ZET.y - 70), "zetstok: w = %s · volgende letter k = %s" % [ScPal.show_text(w), ScPal.show(kk) if kk != "" else "—"], 20)
	var ph := _phase() == "DECIDE" and not tool.is_done()
	var mv := {"act": "extend"}
	var ms := {"act": "stamp"}
	var rv := ScDrawTools.lever(self, LEV_V, "Verleng", "V", float(_pull.V), is_hover(mv) or is_ghost(mv), ScPal.VERDIGRIS, t)
	var rs := ScDrawTools.lever(self, LEV_S, "Stempel", "S", float(_pull.S), is_hover(ms) or is_ghost(ms), ScPal.RUBRIC, t)
	_lever_r = {"V": rv, "S": rs}
	if ph:
		zone(rv, mv)
		zone(rs, ms)
	if t - _stamp_t < 0.5:
		var a := 1.0 - (t - _stamp_t) / 0.5
		ScDraw.stamp_print(self, LEV_S + Vector2(0, -260), str(((cur.get("out", []) as Array).back()) if not (cur.get("out", []) as Array).is_empty() else ""), 40, a)
	var nc := int(cur.get("next_code", 256))
	table_label(Vector2(ZET.x, 560), "volgende nieuwe lade: %d" % nc, 20)


func _paint_recv() -> void:
	var codes: Array = cur.get("codes", [])
	var cpos := int(cur.get("cpos", 0))
	var w := str(cur.get("w", ""))
	var vol := str(cur.get("volgend", ""))
	var special := bool(cur.get("special", false))
	var c := int(codes[cpos]) if cpos < codes.size() else -1
	if c >= 0:
		table_label(Vector2(800, 300), "binnengekomen code", 22)
		ScDraw.stamp_print(self, Vector2(1080, 300), str(c), 40)
	table_label(Vector2(800, 380), "w = %s" % ScPal.show_text(w), 24)
	if not special and vol != "":
		table_label(Vector2(800, 430), "volgend = %s" % ScPal.show_text(vol), 24)
	elif special:
		table_label(Vector2(800, 430), "lade %d is leeg: volgend = w + ?" % c, 24, ScPal.GOLD_LIGHT)
	_carve_r = []
	if _phase() == "CARVE" and not tool.is_done():
		var letters := w if special else vol
		ScDraw.wood(self, Rect2(790, 500, 440, 150), ScPal.OAK_DARK, 10)
		ScPal.text_l(self, ScPal.UI_MED, Vector2(806, 524), "snijbank: nieuwe stempel = %s + ?" % ScPal.show_text(w), 20, ScPal.TEXT)
		for j in letters.length():
			var r := Rect2(810 + j * 70, 556, 60, 74)
			var m := {"act": "carve", "i": j}
			ScDraw.wood(self, r, ScPal.OAK_LIGHT if is_hover(m) else ScPal.OAK, 6)
			var face := r.grow(-8)
			draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 4), face)
			ScPal.text_c(self, ScPal.MONO, face.get_center(), ScPal.show(letters[j]), 32, ScPal.INK)
			ScPal.text_c(self, ScPal.MONO_B, Vector2(r.get_center().x, r.end.y + 16), str(j + 1), 16, ScPal.TEXT_DIM)
			if is_hover(m):
				ScPal.ring(self, r.grow(3), 8, ScPal.INFO, 3)
			_carve_r.append(r)
			zone(r, m)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _recv():
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De afzender vulde dezelfde kast.", 20, ScPal.TEXT)
		return
	var out: Array = cur.get("out", [])
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Letterlijk snijdt dezelfde stempels:", 20, ScPal.TEXT)
	if out.is_empty():
		return
	var dz := ScReference.lzw_decode(out)
	var x := r.position.x + 14
	var y := r.position.y + 70
	for a in dz.adds:
		var s := "%d %s" % [int(a[0]), ScPal.show_text(str(a[1]))]
		var w := ScPal.text_w(ScPal.MONO_B, s, 20) + 20
		if x + w > r.end.x:
			x = r.position.x + 14
			y += 36
		ci.draw_style_box(ScPal.sb(Color(ScPal.VELLUM, 0.92), 6), Rect2(x, y - 15, w, 30))
		ScPal.text_l(ci, ScPal.MONO_B, Vector2(x + 10, y), s, 20, ScPal.INK)
		x += w + 8


func overkant_copy() -> String:
	if _recv():
		return ""
	var out: Array = cur.get("out", [])
	return str(ScReference.lzw_decode(out).text) if not out.is_empty() else ""
