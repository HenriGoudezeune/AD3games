extends ScView
## Duiventil (GDD §3.10, P1): acht duiven (alle berichten van 3 bits) en zeven kortere hokken (ε, 0, 1, 00, 01, 10,
## 11). Klik een duif en dan een hok (of sleep). De achtste past nergens en moet naar de zolder (4 bits). Daarna twee
## decreten van de abt: onmogelijk, waar of vals?

const TOWER := Vector2(820, 760)

var _sel := -1
var _hole_r := {}
var _pig_r: Array = []
var _land := {}
var _mouse_p := Vector2(-99, -99)


func _phase() -> String:
	return str(cur.get("phase_name", ""))


func play(fx: Dictionary) -> float:
	if str(fx.get("fx", "")) == "roost":
		_land = fx.duplicate()
		start_anim("land", 0.5 * spd)
		ScSnd.play("pigeon_fly", -8.0)
		var tw := create_tween()
		tw.tween_interval(0.45 * spd)
		tw.tween_callback(func():
			ScSnd.play("pigeon_land", -6.0)
			var r: Rect2 = _hole_r.get(str(fx.hole), Rect2(TOWER, Vector2.ZERO))
			if fx_root:
				ScFx.feathers(fx_root, r.get_center()))
		return 0.5 * spd
	return super.play(fx)


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"taken":
			return "In elk hok past maar één duif."
		"not_shorter":
			return "Er is nog een korter hok vrij."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	if str(m.get("act", "")) == "roost":
		var r: Rect2 = _hole_r.get(str(m.get("hole", "")), Rect2(TOWER, Vector2.ZERO))
		return r.get_center()
	return Vector2(1300, 990)


func buttons() -> Array:
	if _phase() != "DECREE" or readonly:
		return []
	var dec: Dictionary = cur.get("decrees", {})
	var which := 1 if not dec.has("1") else 2
	var out: Array = []
	for a in [["Onmogelijk", "impossible"], ["Waar", "true"], ["Vals", "false"]]:
		out.append({"text": a[0], "move": {"act": "decree", "which": which, "answer": a[1]}, "kind": ScUi.Kind.VELLUM})
	return out


func band() -> Dictionary:
	return {"label": "Opdracht", "text": "", "note": "elke duif een eigen, korter hok — kan dat?"}


func handle(ev: InputEvent) -> bool:
	if ev is InputEventMouseMotion:
		_mouse_p = (ev as InputEventMouseMotion).position
	return super.handle(ev)


func _click(m: Dictionary) -> void:
	if m.has("pigeon_pick"):
		_sel = int(m.pigeon_pick)
		ScSnd.play("pigeon_coo", -10.0)
		return
	if m.has("hole_pick"):
		if _sel >= 0:
			var p := _sel
			_sel = -1
			request.emit({"act": "roost", "pigeon": p, "hole": str(m.hole_pick)})
		return
	super._click(m)


func _paint() -> void:
	caption("De duiventil", "geen algoritme maakt alles korter (Oef. 76)")
	var roost: Dictionary = cur.get("roost", {})
	var filled := {}
	var la := anim("land")
	for k in roost:
		if not _land.is_empty() and la < 1.0 and str(k) == str(_land.pigeon):
			continue
		filled[str(roost[k])] = true
	_hole_r = ScDrawTools.dovecote(self, TOWER, 1.25, filled, t, _bits())
	var ph := _phase()
	if ph == "ROOST" and _sel >= 0:
		# hokken zijn pas klikbaar (handje + ring) als er een duif gekozen is
		for h in _hole_r:
			var m := {"hole_pick": str(h)}
			if is_hover(m) and _sel >= 0:
				ScPal.ring(self, (_hole_r[h] as Rect2).grow(4), 8, ScPal.INFO, 3)
			zone(_hole_r[h], m, false)
	var pigs: Array = cur.get("pigeons", [])
	_pig_r = []
	for i in pigs.size():
		var placed := roost.has(str(i))
		var c := Vector2(110 + (i % 2) * 120, 300 + (i / 2) * 140)
		if placed and not (not _land.is_empty() and la < 1.0 and int(_land.pigeon) == i):
			continue
		var p := c
		if not _land.is_empty() and la < 1.0 and int(_land.pigeon) == i:
			var r: Rect2 = _hole_r.get(str(_land.hole), Rect2(TOWER, Vector2.ZERO))
			p = c.lerp(r.get_center(), ease_out(la)) + Vector2(0, -sin(la * PI) * 120)
		var hi := i == _sel or is_hover({"pigeon_pick": i})
		ScDraw.dove(self, p, 1.0, t + i, 1 if (not _land.is_empty() and la < 1.0 and int(_land.pigeon) == i) else 0, 1.0, 0, false)
		var lab := Rect2(p + Vector2(-30, 22), Vector2(60, 26))
		draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 6), lab)
		ScPal.text_c(self, ScPal.MONO_B, lab.get_center(), str(pigs[i]), 20, ScPal.INK)
		var zr := Rect2(p - Vector2(50, 50), Vector2(100, 100))
		if hi:
			ScPal.ring(self, zr, 14, ScPal.INFO, 3)
		if ph == "ROOST" and not placed:
			zone(zr, {"pigeon_pick": i})
	if ph == "DECREE":
		var dec: Dictionary = cur.get("decrees", {})
		ScDraw.parchment(self, Rect2(300, 275, 560, 170), 19, ScPal.VELLUM, true, 0.6)
		var which := 1 if not dec.has("1") else 2
		var txt := ("\"Elk bericht van %d bits kan korter.\"" % _bits()) if which == 1 else "\"Voor elk bericht bestaat een code die het korter maakt.\""
		ScPal.text_l(self, ScPal.TITLE, Vector2(330, 315), "Decreet %d van de abt" % which, 30, ScPal.RUBRIC)
		var fs := 22
		while fs > 15 and ScPal.text_w(ScPal.UI, txt, fs) > 500:
			fs -= 1
		ScPal.text_l(self, ScPal.UI, Vector2(330, 375), txt, fs, ScPal.INK)


## Aantal bits van de berichten (2^bits duiven).
func _bits() -> int:
	var pigs: Array = cur.get("pigeons", [])
	return str(pigs[0]).length() if not pigs.is_empty() else 3


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	var b := _bits()
	var terms: Array = []
	for l in b:
		terms.append(str(1 << l))
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "%d berichten, maar %d kortere hokken:" % [1 << b, (1 << b) - 1], 20, ScPal.TEXT)
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 54), "%s = %d < %d = 2%s (p. 81)" % [" + ".join(terms), (1 << b) - 1, 1 << b, "⁰¹²³⁴⁵⁶⁷⁸⁹"[b % 10]], 20, ScPal.GOLD_LIGHT)
