extends ScView
## Letterplank (GDD §3.9, §4.4, juice #34): houten blokjes op een rij (move-to-front). Zenden: stempel de positie van
## de volgende letter (vanaf 0) met de cijferstempels (klik, of typ het getal + Enter); daarna schuift het blokje naar
## voren. Ontvangen: een getal komt binnen; klik het blokje op die positie. Positienummers enkel in het eerste level
## (of met hulplijnen). De Overkant toont de plank van Letterlijk.

const PLANK := Vector2(70, 470)

var _move := {}
var _prev_list: Array = []
var _press := -1
var _buf := ""
var _blocks: Array = []
var _stamps: Array = []


func _setup() -> void:
	alphabet = ""


func _recv() -> bool:
	return int(cur.get("side", 0)) == ScCodes.Side.RECEIVE


func _phase() -> String:
	return str(cur.get("phase_name", ""))


func _block() -> float:
	var n := maxi(1, (cur.get("list", []) as Array).size())
	return clampf(1080.0 / n - 8.0, 46.0, 84.0)


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"number":
			_press = int(fx.k)
			start_anim("press", 0.3)
			ScSnd.play("number_stamp", -4.0)
			return 0.2 * spd
		"shelf_move":
			_move = fx.duplicate()
			_prev_list = (cur.get("list", []) as Array).duplicate()
			start_anim("move", 0.35 * spd)
			ScSnd.play("block_slide", -4.0)
			if _recv():
				ScSnd.play("quill_letter", -10.0)
			return 0.36 * spd
	return super.play(fx)


func _on_commit() -> void:
	_move = {}


func anchor(m: Dictionary) -> Vector2:
	var k := int(m.get("k", 0))
	if str(m.get("act", "")) == "number":
		if k < _stamps.size():
			return (_stamps[k] as Rect2).get_center()
	elif k < _blocks.size():
		return (_blocks[k] as Rect2).get_center()
	return AREA.get_center()


func key_move(ev: InputEventKey) -> Dictionary:
	var d := -1
	if ev.keycode >= KEY_0 and ev.keycode <= KEY_9:
		d = ev.keycode - KEY_0
	elif ev.keycode >= KEY_KP_0 and ev.keycode <= KEY_KP_9:
		d = ev.keycode - KEY_KP_0
	var n := (cur.get("list", []) as Array).size()
	var act := "pick" if _recv() else "number"
	if d >= 0:
		_buf += str(d)
		if int(_buf) * 10 >= n or _buf.length() >= 2:
			var v := int(_buf)
			_buf = ""
			return {"act": act, "k": v}
		return {}
	if (ev.keycode == KEY_ENTER or ev.keycode == KEY_KP_ENTER) and _buf != "":
		var v2 := int(_buf)
		_buf = ""
		return {"act": act, "k": v2}
	return {}


func band() -> Dictionary:
	if _recv():
		return {"label": "Kopie", "text": str(cur.get("copy", "")), "cursor": -1, "chips": false, "idx": false}
	var inp := str(cur.get("input", ""))
	var i := int(cur.get("i", 0))
	return {"label": "Invoer", "text": inp, "cursor": i if not tool.is_done() else -1, "done": i, "chips": false,
		"idx": inp.length() <= 26}


func strip() -> Dictionary:
	var sh := tool as ScShelf
	var toks: Array = []
	if _recv():
		for x in sh.nums:
			toks.append({"num": x})
		return {"tokens": toks, "consumed": sh.i, "unit": ""}
	for x in sh.out:
		toks.append({"num": x})
	return {"tokens": toks, "consumed": -1, "unit": ""}


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "number" and not _recv():
		return [{"num": int(fx.k)}]
	return []


func _paint() -> void:
	var recv := _recv()
	caption("De letterplank", "schrijf de plaats (vanaf 0), dan naar voren" if not recv else "neem het blokje op die plaats, dan naar voren")
	var lst: Array = cur.get("list", [])
	var block := _block()
	var show_pos := bool(cur.get("show_positions", false)) or guides
	var ma := anim("move")
	var items := lst
	if not _move.is_empty() and ma < 1.0:
		items = _prev_list
	var hm := hover_move()
	var hk := int(hm.get("k", -1)) if str(hm.get("act", "")) == "pick" else -1
	_blocks = ScDrawTools.shelf(self, PLANK, items, block, show_pos, hk, t)
	if not _move.is_empty() and ma < 1.0:
		# het blokje vliegt naar voren (over de anderen heen)
		var k := int(_move.k)
		if k < _blocks.size():
			var r0: Rect2 = _blocks[k]
			var r1: Rect2 = _blocks[0]
			var e := ease_out(ma)
			var p := r0.position.lerp(r1.position, e) + Vector2(0, -sin(ma * PI) * 80)
			var rr := Rect2(p, r0.size)
			ScDraw.wood(self, rr, ScPal.OAK_LIGHT, 7, true, 5)
			var face := rr.grow(-7)
			draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 4), face)
			ScPal.text_c(self, ScPal.MONO, face.get_center(), ScPal.show(str(_move.ch)), int(block * 0.55), ScPal.INK)
			ScPal.ring(self, rr.grow(4), 9, ScPal.GOLD, 3)
	var ph := _phase()
	if recv:
		if ph == "PICK_BLOCK" and not tool.is_done():
			for q in _blocks.size():
				zone(_blocks[q], {"act": "pick", "k": q})
		var nums: Array = cur.get("nums", [])
		var i := int(cur.get("i", 0))
		if i < nums.size():
			table_label(Vector2(PLANK.x, 330), "binnengekomen getal: %d" % int(nums[i]), 26, ScPal.GOLD_LIGHT)
		return
	var ch := str(cur.get("ch", ""))
	if ch != "" and not tool.is_done():
		table_label(Vector2(PLANK.x, 330), "volgende letter: %s · waar staat ze nu?" % ScPal.show(ch), 24, ScPal.GOLD_LIGHT)
	# cijferstempels
	_stamps = []
	var n := lst.size()
	var per := mini(n, 10)
	for d in n:
		var row := d / per
		var col := d % per
		var c := Vector2(110 + col * 104, 690 + row * 110)
		var m := {"act": "number", "k": d}
		var pr := 0.0
		if d == _press:
			pr = 1.0 - anim("press")
		var r := ScDrawTools.digit_stamp(self, c, d, 0.95, is_hover(m) or is_ghost(m), pr)
		_stamps.append(r)
		if ph == "NUMBER" and not tool.is_done():
			zone(r, m)
	if _buf != "":
		table_label(Vector2(800, 330), "getypt: %s…" % _buf, 22)
	var z := int((tool as ScShelf).counters.zeros)
	table_label(Vector2(800, 380), "nullen: %d" % z, 20)


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _recv():
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De afzender begon met dezelfde plank.", 20, ScPal.TEXT)
		return
	ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "De plank van Letterlijk", 20, ScPal.TEXT)
	var mir: Array = cur.get("mirror", [])
	if mir.is_empty():
		return
	var b := clampf((r.size.x - 50) / mir.size() - 8.0, 22.0, 44.0)
	ScDrawTools.shelf(ci, r.position + Vector2(24, 110), mir, b, false, -1, t)


func overkant_copy() -> String:
	if _recv():
		return ""
	var sh := tool as ScShelf
	var out: Array = cur.get("out", [])
	if out.is_empty():
		return ""
	return str(ScReference.mtf_decode(out, sh.start_list).text)
