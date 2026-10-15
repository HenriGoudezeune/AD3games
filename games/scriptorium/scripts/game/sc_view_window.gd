extends ScView
## Leesraam (GDD §3.6, §4.4, juice #24–27): één regel tekst met het houten raam over de laatste G tekens (posities
## vanaf 0 links). Zenden: klik de letter in het raam waar de match begint (de rode draad loopt letter per letter mee,
## ook over de rand van het raam) of "Geen match" (G). Elk drietal wordt een groen wassen zegel (p,l,x).
## Ontvangen: een zegel komt binnen; klik positie p in het raam: de kopiist kopieert l letters één voor één.
## Met register (4-6): "Register" (R) laat de lantaarn de langste match zoeken.

const LM := Vector2(70, 470)

var _thread := {}
var _copy := {}
var _centers := PackedVector2Array()
var _seal_pop := {}
var _reg := {}


func _setup() -> void:
	var s := ""
	var src := str(stage.get("text", stage.get("expect", "")))
	for ch in src:
		if not s.contains(ch):
			s += ch
	alphabet = s if s.length() <= 10 else ""


func _recv() -> bool:
	return int(cur.get("side", 0)) == ScCodes.Side.RECEIVE


func _G() -> int:
	return int(cur.get("G", stage.get("G", -1)))


func _cell_size(n: int) -> Vector2:
	var cell := clampf(1100.0 / maxf(n, 1), 34.0, 56.0)
	return Vector2(cell, int(clampf(cell * 0.76, 24, 42)))


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"thread":
			_thread = fx.duplicate()
			var l := (fx.get("steps", []) as Array).size()
			var dur := (0.12 * l + 0.25) * spd
			start_anim("thread", dur)
			for q in l:
				var qq := q
				get_tree().create_timer(0.12 * spd * q + 0.1).timeout.connect(func(): ScSnd.pluck(qq))
			return dur
		"copy_letters":
			_copy = fx.duplicate()
			var l2 := str(fx.get("letters", "")).length()
			var dur2 := (0.16 * l2 + 0.2) * spd
			start_anim("copy", dur2)
			for q in l2:
				var qq2 := q
				get_tree().create_timer(0.16 * spd * q + 0.08).timeout.connect(func():
					ScSnd.pluck(qq2)
					ScSnd.play("quill_letter", -12.0))
			return dur2
		"seal":
			_seal_pop = fx.duplicate()
			start_anim("seal", 0.3)
			ScSnd.play("seal_plop", -4.0)
			return 0.22 * spd
		"slide":
			ScSnd.play("window_slide", -8.0)
			start_anim("slide", 0.2)
			return 0.2 * spd
		"register_walk":
			_reg = fx.duplicate()
			start_anim("reg", 0.6)
			ScSnd.play("needle_gold", -10.0)
			return 0.6
	return super.play(fx)


func _on_commit() -> void:
	_thread = {}
	_copy = {}


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"no_match":
			return "Die letter is niet de volgende letter: de draad vertrekt niet."
		"out_of_window":
			return "De match moet in het raam beginnen."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	var act := str(m.get("act", ""))
	if act == "literal":
		return Vector2(1200, 990)
	if act == "register":
		return Vector2(1380, 990)
	var p := int(m.get("p", 0))
	var ws := int(cur.get("ws", 0))
	if ws + p < _centers.size():
		return _centers[ws + p] + Vector2(0, 10)
	return AREA.get_center()


func buttons() -> Array:
	if readonly or _recv() or tool.is_done():
		return []
	var out := [{"text": "Geen match  (G)", "move": {"act": "literal"}, "kind": ScUi.Kind.VELLUM, "key": "G"}]
	if bool(cur.get("register", false)):
		out.append({"text": "Register  (R)", "move": {"act": "register"}, "kind": ScUi.Kind.SECONDARY, "key": "R"})
	return out


func key_move(ev: InputEventKey) -> Dictionary:
	if _recv():
		return {}
	if ev.keycode == KEY_G:
		return {"act": "literal"}
	if ev.keycode == KEY_R and bool(cur.get("register", false)):
		return {"act": "register"}
	return {}


func band() -> Dictionary:
	if _recv():
		return {"label": "Kopie", "text": str(cur.get("written", "")), "cursor": -1, "chips": alphabet != "", "alphabet": alphabet,
			"idx": false}
	var txt := str(stage.get("text", ""))
	var k := int(cur.get("k", 0))
	return {"label": "Opdracht", "text": txt, "cursor": k, "done": k, "chips": alphabet != "", "alphabet": alphabet,
		"idx": txt.length() <= 24, "note": "G = %s" % ("∞" if _G() < 0 else str(_G()))}


func _triple_tokens(trs: Array) -> Array:
	var out: Array = []
	for tr in trs:
		out.append({"triple": [int(tr[0]), int(tr[1]), str(tr[2])]})
	return out


func strip() -> Dictionary:
	var w := tool as ScWindow
	if _recv():
		return {"tokens": _triple_tokens(w.triples), "consumed": w.idx, "unit": ""}
	return {"tokens": _triple_tokens(w.triples), "consumed": -1, "unit": "zegels"}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "seal" and not _recv():
		return _triple_tokens([fx.triple])
	return []


func _paint() -> void:
	var recv := _recv()
	caption("Het leesraam", "begin in het raam, mag erbuiten eindigen · p vanaf 0" if not recv else "tel vanaf de linkerrand, de eerste is 0")
	var text := str(stage.get("text", "")) if not recv else (tool as ScWindow).written
	var upto := int(cur.get("k", 0)) if not recv else str(cur.get("written", "")).length()
	var ws := int(cur.get("ws", 0))
	var G := _G()
	var gw := G if G >= 0 else 9999
	# kopiëren (ontvangen): letters verschijnen één voor één
	var ca := anim("copy")
	if recv and not _copy.is_empty() and ca < 1.0:
		upto += int(floor(ca * str(_copy.letters).length() * 1.05))
	elif recv and not _copy.is_empty():
		upto = text.length()
	upto = clampi(upto, 0, text.length())
	var cs := _cell_size(maxi(text.length(), 8))
	var hm := hover_move()
	var hp := int(hm.get("p", -1)) if str(hm.get("act", "")) == "start" else -1
	if is_ghost(ghost):
		hp = int(ghost.get("p", hp))
	var show_pos := guides or tutorial or G < 0 or true
	_centers = ScDrawTools.reading_window(self, LM, text if text != "" else " ", ws, gw, cs.x, int(cs.y), hp, show_pos, t, upto)
	var phase := str(cur.get("phase_name", ""))
	var wl := mini(gw, maxi(0, upto - ws)) if recv else mini(gw, maxi(0, int(cur.get("k", 0)) - ws))
	if phase == "PICK" and not tool.is_done():
		for p in wl:
			if ws + p < _centers.size():
				var c := _centers[ws + p]
				zone(Rect2(c - Vector2(cs.x * 0.48, cs.y * 0.8), Vector2(cs.x * 0.96, cs.y * 1.6)), {"act": "start", "p": p})
	# rode draad
	var ta := anim("thread")
	if not _thread.is_empty() and ta < 1.0:
		var steps: Array = _thread.get("steps", [])
		var to := int(_thread.get("to", 0))
		var l := steps.size()
		var pr := ta * 1.1 * l
		for q in mini(l, int(floor(pr)) + 1):
			var s := int(steps[q])
			var d := to + q
			if s < _centers.size() and d < _centers.size():
				var f := clampf(pr - q, 0.0, 1.0)
				ScDrawTools.thread(self, _centers[s] + Vector2(0, -cs.y * 0.6), _centers[d] + Vector2(0, -cs.y * 0.6), f, t, 50 + 6 * q)
				if f >= 1.0:
					draw_line(_centers[d] + Vector2(-cs.x * 0.35, cs.y * 0.7), _centers[d] + Vector2(cs.x * 0.35, cs.y * 0.7), ScPal.RUBRIC, 3.0)
				if s >= to:
					ScDraw.glow(self, _centers[s], 22, Color(ScPal.GOLD_LIGHT, 0.5))
	if recv and not _copy.is_empty() and ca < 1.0:
		var src: Array = _copy.get("src", [])
		var n := str(_copy.letters).length()
		var q2 := mini(n - 1, int(floor(ca * n * 1.05)))
		var base := text.length() - n - (0 if str((cur.get("triple", ["", "", "EOF"]) as Array)[2]) == "EOF" else 1)
		if q2 >= 0 and q2 < src.size() and int(src[q2]) < _centers.size() and base + q2 < _centers.size():
			ScDrawTools.thread(self, _centers[int(src[q2])] + Vector2(0, -cs.y * 0.6), _centers[base + q2] + Vector2(0, -cs.y * 0.6),
				fmod(ca * n * 1.05, 1.0), t, 50)
	# zegels / het binnenkomende zegel
	if recv:
		var tr: Array = cur.get("triple", [])
		if not tr.is_empty():
			table_label(Vector2(700, 650), "binnengekomen zegel", 22)
			ScDraw.triple_seal(self, Vector2(1000, 660), int(tr[0]), int(tr[1]), str(tr[2]), 34, true)
			if int(tr[1]) > 0:
				table_label(Vector2(700, 730), "kopieer %d letter%s vanaf raampositie %d" % [int(tr[1]), "" if int(tr[1]) == 1 else "s",
					int(tr[0])] if guides else "waar begint de kopie in het raam?", 20)
	else:
		var trs: Array = cur.get("triples", [])
		var x := 90.0
		var y := 700.0
		table_label(Vector2(70, 640), "zegels: %d" % trs.size(), 20)
		for q in trs.size():
			var tr2: Array = trs[q]
			var r := ScDraw.triple_seal(self, Vector2(x + 60, y), int(tr2[0]), int(tr2[1]), str(tr2[2]), 22)
			x += r.size.x + 14
			if x > 1100:
				x = 90.0
				y += 64
		var rest := str(cur.get("rest", ""))
		if rest != "" and phase == "PICK":
			table_label(Vector2(70, 330), "volgende letter: %s" % ScPal.show(rest[0]), 22, ScPal.GOLD_LIGHT)
	if not _reg.is_empty():
		table_label(Vector2(560, 330), "register: langste match vanaf p = %d, l = %d" % [int(_reg.p), int(_reg.l)], 22, ScPal.GOLD_LIGHT)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _recv():
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De afzender gebruikte hetzelfde raam (G = %s)." % (
			"∞" if _G() < 0 else str(_G())), 20, ScPal.TEXT)
		return
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Letterlijk kopieert mee:", 20, ScPal.TEXT)
	var trs: Array = cur.get("triples", [])
	var txt := ScReference.lz77_decode(trs, _G()) if not trs.is_empty() else ""
	if txt != "":
		var cell := clampf((r.size.x - 40) / maxf(txt.length(), 1), 20.0, 40.0)
		var ws := ScReference.window_start(txt.length(), _G())
		ScDrawTools.reading_window(ci, r.position + Vector2(24, 110), txt, ws, _G() if _G() >= 0 else 9999, cell, int(cell * 0.72), -1,
			false, t)


func overkant_copy() -> String:
	if _recv():
		return ""
	var trs: Array = cur.get("triples", [])
	return ScReference.lz77_decode(trs, _G()) if not trs.is_empty() else ""
