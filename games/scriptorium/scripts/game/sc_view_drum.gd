extends ScView
## Draaitrommel (GDD §3.8, §4.4, juice #31–33). Zenden: de trommel drukt bij elke slag een rotatie op een strook; de
## speler schuift de strook in de juiste spleet van het rek (klik tussen twee stroken of ↑/↓ + Enter; de strook volgt de
## muis). Daarna: markeer de rij die eindigt op het eerste teken (p). Uitvoer "p␣laatste kolom".
## Ontvangen (de terugweg): twee kolommen e (gesorteerd) en c; de letter x staat gemarkeerd in e; klik in c dezelfde
## letter met dezelfde rang (de k-de x in e is de k-de x in c).

const DRUM_C := Vector2(200, 560)
const RACK := Vector2(470, 300)

var _spin := 0.0
var _gap := -1
var _ins := {}
var _walk := {}
var _rows_r: Array = []
var _mouse_p := Vector2(-99, -99)


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


func _size(n: int) -> int:
	return int(clampf(560.0 / (maxf(n, 1) * 1.45), 18, 34))


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"rotation":
			var target := float(fx.get("r", 0))
			create_tween().tween_property(self, "_spin", target, 0.3 * spd).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			ScSnd.play("drum_turn", -6.0)
			return 0.32 * spd
		"insert":
			_ins = fx.duplicate()
			start_anim("insert", 0.2)
			ScSnd.play("strip_slide", -4.0)
			return (0.06 if bool(fx.get("auto", false)) else 0.18) * spd
		"mark":
			ScSnd.play("wax_seal", -4.0)
			var r := int(fx.row)
			if r < _rows_r.size():
				burst_at("wax", (_rows_r[r] as Rect2).end - Vector2(-22, 20))
			return 0.4 * spd
		"walk":
			_walk = fx.duplicate()
			start_anim("walk", 0.35 * spd)
			ScSnd.play("strip_slide", -6.0)
			ScSnd.sing(str(fx.get("ch", "a")), -12.0)
			if bool(fx.get("closed", false)):
				ScSnd.play("needle_gold", -6.0)
			return 0.38 * spd
	return super.play(fx)


func bump_line(reason: String, fx: Dictionary) -> String:
	if reason == "letter":
		return "Zoek in c dezelfde letter als x."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	match str(m.get("act", "")):
		"insert":
			var g := int(m.get("gap", 0))
			var s := _size(int(cur.get("n", 9)))
			return RACK + Vector2(140, g * s * 1.45 - 2)
		"mark":
			var r := int(m.get("row", 0))
			if r < _rows_r.size():
				return (_rows_r[r] as Rect2).get_center()
		"find":
			var i := int(m.get("i", 0))
			return _col_c(i)
	return AREA.get_center()


func _col_c(i: int) -> Vector2:
	var n := maxi(1, int(cur.get("n", 9)))
	var rh := _size(n) * 1.45
	return Vector2(760, 330 + i * rh + rh / 2)


func _col_e(i: int) -> Vector2:
	var n := maxi(1, int(cur.get("n", 9)))
	var rh := _size(n) * 1.45
	return Vector2(480, 330 + i * rh + rh / 2)


func handle(ev: InputEvent) -> bool:
	if ev is InputEventMouseMotion:
		_mouse_p = (ev as InputEventMouseMotion).position
	if not readonly and not locked and ev is InputEventKey and ev.pressed and _phase() == "INSERT":
		var rc := int(cur.get("row_count", 0))
		var kc := (ev as InputEventKey).keycode
		if kc == KEY_UP or kc == KEY_DOWN:
			_gap = clampi((_gap if _gap >= 0 else rc) + (-1 if kc == KEY_UP else 1), 0, rc)
			ScSnd.play("ui_wood", -14.0)
			return true
		if (kc == KEY_ENTER or kc == KEY_KP_ENTER) and _gap >= 0:
			request.emit({"act": "insert", "gap": _gap})
			return true
	return super.handle(ev)


func band() -> Dictionary:
	if _recv():
		return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": alphabet != "", "alphabet": alphabet,
			"idx": false, "note": "p = %d · c = %s" % [int(cur.get("p", 0)), ScPal.show_text(str(cur.get("c", "")))]}
	return {"label": "Opdracht", "text": str(stage.get("text", "")), "cursor": -1, "chips": alphabet != "", "alphabet": alphabet,
		"note": "n = %d" % int(cur.get("n", 0))}


func strip() -> Dictionary:
	var d := tool as ScDrum
	if _recv():
		return {"tokens": [{"num": str(d.p)}, {"num": ScPal.show_text(d.c)}], "consumed": 0, "unit": ""}
	if d.p_out < 0:
		return {"tokens": [], "consumed": -1, "unit": ""}
	return {"tokens": [{"num": str(d.p_out)}, {"num": ScPal.show_text(d.c_out)}], "consumed": -1, "unit": ""}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "mark":
		var sp := ScReference.split_bwt_text(str(fx.out))
		return [{"num": str(sp.get("p", ""))}, {"num": ScPal.show_text(str(sp.get("c", "")))}]
	return []


func _paint() -> void:
	if _recv():
		_paint_recv()
	else:
		_paint_send()


func _paint_send() -> void:
	var ph := _phase()
	caption("De draaitrommel", "elke strook begint één letter verder · sorteer · de spatie is het kleinst" if ph == "INSERT"
		else "markeer de rij die eindigt op het eerste teken")
	var txt := str(stage.get("text", ""))
	var n := txt.length()
	ScDrawTools.drum(self, DRUM_C, 100, 240, txt, _spin, t, 34)
	var rows: Array = cur.get("rack", [])
	var size := _size(n)
	var rh := size * 1.45
	var pending := str(cur.get("pending", ""))
	var gap := -1
	var pend_at := Vector2.INF
	if ph == "INSERT" and not tool.is_done():
		# spleet onder de muis (of de toetsenbordkeuze)
		var rc := rows.size()
		var hg := -1
		if Rect2(RACK + Vector2(-20, -rh / 2), Vector2(700, rh * (rc + 1))).has_point(_mouse_p):
			hg = clampi(int(round((_mouse_p.y - RACK.y) / rh)), 0, rc)
		if hg >= 0:
			_gap = hg
		gap = _gap
		if is_ghost(ghost):
			gap = int(ghost.get("gap", gap))
		for g in rc + 1:
			zone(Rect2(RACK + Vector2(-20, (g - 0.5) * rh), Vector2(680, rh)), {"act": "insert", "gap": g}, false)
		if hg >= 0:
			pend_at = Vector2(RACK.x + 40 + 30, _mouse_p.y)
	var hm := hover_move()
	var hi_row := int(hm.get("row", -1)) if str(hm.get("act", "")) == "mark" else -1
	var marked := (tool as ScDrum).p_out
	_rows_r = ScDrawTools.rack(self, RACK, rows, size, marked, -1, "", Vector2.INF, t, true, hi_row)
	if gap >= 0:
		var y := RACK.y + gap * rh
		var w := (ScPal.char_w(size) + 6.0) * n + 24
		draw_line(Vector2(RACK.x + 30, y), Vector2(RACK.x + 40 + w + 10, y), ScPal.INFO, 4.0, true)
		ScDraw.fill(self, PackedVector2Array([Vector2(RACK.x + 22, y - 9), Vector2(RACK.x + 34, y), Vector2(RACK.x + 22, y + 9)]), ScPal.INFO)
	if pending != "" and ph == "INSERT":
		var pa := pend_at if pend_at != Vector2.INF else Vector2(RACK.x + 40 + (ScPal.char_w(size) + 6.0) * n + 90, RACK.y)
		var cw := ScPal.char_w(size) + 6.0
		var pr := Rect2(pa - Vector2(0, rh / 2), Vector2(cw * n + 24, rh - 6))
		draw_rect(Rect2(pr.position + Vector2(8, 12), pr.size), ScPal.SHADOW)
		draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 5, 3, ScPal.VELLUM_EDGE), pr)
		for q in n:
			ScPal.text_c(self, ScPal.MONO, Vector2(pr.position.x + 12 + cw * (q + 0.5) - 3, pr.get_center().y - 1), ScPal.show(pending[q]), size, ScPal.INK)
		ScPal.ring(self, pr.grow(3), 6, ScPal.INFO, 2)
	if ph == "MARK" and not tool.is_done():
		for r in _rows_r.size():
			zone(_rows_r[r], {"act": "mark", "row": r})
		table_label(Vector2(RACK.x, RACK.y - 50), "eerste teken: %s · welke rij eindigt erop?" % ScPal.show(txt[0] if n > 0 else ""), 20)
	if tool.is_done() and marked >= 0:
		table_label(Vector2(RACK.x, 870 - 30), "uitvoer: %s" % ScPal.show_text(ScReference.bwt_text(marked, (tool as ScDrum).c_out)), 22,
			ScPal.GOLD_LIGHT)


func _paint_recv() -> void:
	caption("De terugweg", "de k-de x in e is de k-de x in c")
	var c := str(cur.get("c", ""))
	var e := str(cur.get("e", ""))
	var n := c.length()
	var rc: Array = cur.get("ranks_c", [])
	var re: Array = cur.get("ranks_e", [])
	var ranks := bool(cur.get("ranks_visible", false)) or guides
	var x: Dictionary = cur.get("x", {})
	var xr := int(x.get("row", -1))
	var size := _size(n)
	var rh := size * 1.45
	ScDraw.wood(self, Rect2(400, 300, 480, rh * n + 60), ScPal.WALNUT, 10)
	ScPal.text_c(self, ScPal.TITLE, Vector2(480, 316), "e", 28, ScPal.LAPIS_LIGHT)
	ScPal.text_c(self, ScPal.TITLE, Vector2(760, 316), "c", 28, ScPal.GOLD_LIGHT)
	var ph := _phase()
	for i in n:
		var pe := _col_e(i) + Vector2(0, 20)
		var pc := _col_c(i) + Vector2(0, 20)
		ScPal.text_r(self, ScPal.MONO_B, Vector2(430, pe.y), str(i), 18, ScPal.TEXT_DIM)
		for side in 2:
			var p := pe if side == 0 else pc
			var ch := (e if side == 0 else c)[i]
			var rr := Rect2(p - Vector2(46, rh * 0.45), Vector2(92, rh * 0.9))
			var m := {"act": "find", "i": i}
			var hov := side == 1 and is_hover(m)
			draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI if hov else ScPal.VELLUM, 5, 3, ScPal.VELLUM_EDGE), rr)
			ScPal.text_c(self, ScPal.MONO, p, ScPal.show(ch), size, ScPal.INK)
			if ranks:
				var rk := int((re if side == 0 else rc)[i]) + 1 if i < (re if side == 0 else rc).size() else 0
				ScPal.text_c(self, ScPal.MONO_B, p + Vector2(30, size * 0.3), str(rk), 15, ScPal.INK_SOFT)
			if side == 0 and i == xr:
				ScPal.ring(self, rr.grow(4), 8, ScPal.GOLD, 3)
			if hov:
				ScPal.ring(self, rr.grow(3), 8, ScPal.INFO, 3)
			if side == 1 and ph == "WALK" and not tool.is_done():
				zone(rr, m)
	# pijl c[i] → e[i]
	var wa := anim("walk")
	if not _walk.is_empty() and wa < 1.0:
		var to := int(_walk.to_row)
		ScDrawTools.thread(self, _col_c(to) + Vector2(-46, 20), _col_e(to) + Vector2(46, 20), wa, t, 30)
	if xr >= 0 and ph == "WALK":
		var xc := str(x.get("ch", ""))
		var xk := int(x.get("rank", 0)) + 1
		table_label(Vector2(920, 360), "x = %s%s" % [ScPal.show(xc), ("  (de %de)" % xk) if ranks else ""], 26, ScPal.GOLD_LIGHT)
		table_label(Vector2(920, 410), "zoek dezelfde in kolom c", 20)
	table_label(Vector2(920, 470), "stap %d van %d" % [int(cur.get("step", 0)) + 1, n], 20)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _recv():
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De afzender stuurde p en de laatste kolom.", 20, ScPal.TEXT)
	else:
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Letterlijk wacht op p en de laatste kolom (p. 117).", 20, ScPal.TEXT)
