extends ScView
## Codebord (GDD §3.2, §4.4). Stage "Grenzen" (cuts): de kelner stuurt een strook in zijn eigen code (geen
## prefixcode); knip ze in codewoorden (klik tussen twee bits). Elke volledige lezing komt op de lijst; "Opnieuw lezen"
## (R) begint opnieuw, "Klaar" stuurt de strook door (Letterlijk leest gulzig). Stage "Codebord" (design): een leeg
## houten boomraam (diepte ≤ 3); sleep (of klik en klik) lettertegels op knopen, rechtsklik haalt ze weg. Het pad is
## het codewoord; de inktpot telt Σ a(x)·l(x). "Verzenden" laat Letterlijk proeflezen.

const ROOT := Vector2(640, 300)
const DX := [270.0, 135.0, 68.0]
const DY := 128.0
const TRAY_Y := 800.0

var _sel_sym := ""
var _drag := ""
var _drag_from := Vector2.ZERO
var _mouse_p := Vector2(-99, -99)
var _cut_flash := {}
var _reading_flash := 0.0
var _gap_r: Array = []
var _tiles := {}
var _nodes := {}


func _setup() -> void:
	var s := ""
	for f in cur.get("freqs", []):
		s += str(f[0])
	if s == "":
		for k in (stage.get("code", {}) as Dictionary):
			s += str(k)
	alphabet = s


func _mode() -> String:
	return str(cur.get("mode", stage.get("mode", "cuts")))


func play(fx: Dictionary) -> float:
	match str(fx.get("fx", "")):
		"cut":
			_cut_flash = fx.duplicate()
			start_anim("cut", 0.3)
			ScSnd.play("scissors", -4.0)
			if int(fx.at) - 1 < _gap_r.size() and int(fx.at) - 1 >= 0:
				burst_at("snip", (_gap_r[int(fx.at) - 1] as Rect2).get_center())
			return 0.18 * spd
		"reading_done":
			if bool(fx.get("demo", false)):
				return 0.0
			_reading_flash = t
			if bool(fx.get("new", false)):
				ScSnd.play("bell", -10.0)
				say.emit("Nog een lezing! Dezelfde strook, een andere tekst.")
			else:
				ScSnd.play("page_turn", -8.0)
				say.emit("Die lezing had je al.")
			return 0.4
		"place":
			if str(fx.path) == "":
				ScSnd.play("ui_wood", -8.0, 0.8)
			else:
				ScSnd.play("block_slide", -4.0)
			return 0.1
		"trial_read":
			ov = {"text": str(fx.text), "trial": true}
			ScSnd.play("reading_bad", -6.0)
			say.emit("Letterlijk las onzin. Waar stopt een letter?")
			return 0.6
	return super.play(fx)


func bump_line(reason: String, fx: Dictionary) -> String:
	match reason:
		"no_word":
			return "Dat stuk is geen codewoord."
		"need_more":
			return "Zoek eerst nog een andere lezing."
		"taken":
			return "Op die knoop hangt al een letter."
		"incomplete":
			return "Hang eerst alle letters op."
		"range":
			return "Dat kan niet op dit bord."
	return super.bump_line(reason, fx)


func anchor(m: Dictionary) -> Vector2:
	match str(m.get("act", "")):
		"cut":
			var i := int(m.at) - 1
			if i >= 0 and i < _gap_r.size():
				return (_gap_r[i] as Rect2).get_center()
		"done":
			return Vector2(1380, 990)
		"send":
			return Vector2(1500, 990)
		"place":
			return _node_pos(str(m.get("path", ""))) + Vector2(0, 40)
	return AREA.get_center()


func buttons() -> Array:
	if readonly or tool.is_done():
		return []
	if _mode() == "cuts":
		return [{"text": "Opnieuw lezen  (R)", "move": {"act": "reset"}, "kind": ScUi.Kind.VELLUM, "key": "R"},
			{"text": "Klaar", "move": {"act": "done"}, "kind": ScUi.Kind.WAX}]
	return [{"text": "Verzenden", "move": {"act": "send"}, "kind": ScUi.Kind.WAX}]


func key_move(ev: InputEventKey) -> Dictionary:
	if _mode() == "cuts" and ev.keycode == KEY_R:
		return {"act": "reset"}
	return {}


func band() -> Dictionary:
	if _mode() == "cuts":
		return {"label": "Bedoeld", "text": str(stage.get("intended", "")), "cursor": -1, "chips": true, "alphabet": alphabet,
			"idx": false, "note": "de abt schreef dit; de strook is %s" % str(stage.get("bits", ""))}
	var txt := str(stage.get("text", ""))
	return {"label": "Opdracht", "text": txt, "cursor": -1, "chips": true, "alphabet": alphabet, "idx": false,
		"note": "n = %d" % txt.length()}


func strip() -> Dictionary:
	var cb := tool as ScCodeBoard
	if _mode() == "cuts":
		var toks: Array = []
		for p in cur.get("parts", []):
			toks.append({"b": str(p)})
		var rest := cb.bits.substr(cb.start)
		if rest != "":
			toks.append({"b": rest})
		return {"tokens": toks, "consumed": (cur.get("parts", []) as Array).size(), "unit": ""}
	if cb.sent_bits != "":
		return {"tokens": _word_tokens(cb.sent_code), "consumed": -1, "unit": "bits"}
	return {"tokens": [], "consumed": -1, "unit": "bits"}


func _word_tokens(code: Dictionary) -> Array:
	var out: Array = []
	for ch in str(stage.get("text", "")):
		out.append({"b": str(code.get(ch, ""))})
	return out


func fx_tokens(fx: Dictionary) -> Array:
	if str(fx.get("fx", "")) == "write":
		return _word_tokens((tool as ScCodeBoard).sent_code)
	return []


# ------------------------------------------------------------------ input (slepen)

func handle(ev: InputEvent) -> bool:
	if readonly:
		return false
	if ev is InputEventMouseMotion:
		_mouse_p = (ev as InputEventMouseMotion).position
	if _mode() == "design" and not locked:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				var s := _tile_at(mb.position)
				if s != "":
					_drag = s
					_drag_from = mb.position
					return true
				var path := _node_at(mb.position)
				if path != "" and _sel_sym != "":
					var sym := _sel_sym
					_sel_sym = ""
					request.emit({"act": "place", "sym": sym, "path": path})
					return true
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and _drag != "":
				var sym2 := _drag
				_drag = ""
				var path2 := _node_at(mb.position)
				if mb.position.distance_to(_drag_from) < 8:
					_sel_sym = "" if _sel_sym == sym2 else sym2
					ScSnd.play("ui_wood", -8.0)
				elif path2 != "":
					_sel_sym = ""
					request.emit({"act": "place", "sym": sym2, "path": path2})
				elif mb.position.y > TRAY_Y - 60 and (cur.get("placed", {}) as Dictionary).has(sym2):
					request.emit({"act": "remove", "sym": sym2})
				return true
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				var s3 := _tile_at(mb.position)
				if s3 != "" and (cur.get("placed", {}) as Dictionary).has(s3):
					request.emit({"act": "remove", "sym": s3})
					return true
	return super.handle(ev)


func _tile_at(p: Vector2) -> String:
	for s in _tiles:
		if (_tiles[s] as Rect2).has_point(p):
			return str(s)
	return ""


func _node_at(p: Vector2) -> String:
	var best := ""
	var bd := 60.0
	for path in _nodes:
		var d := p.distance_to(_nodes[path])
		if d < bd:
			bd = d
			best = str(path)
	return best


func _node_pos(path: String) -> Vector2:
	var p := ROOT
	for i in path.length():
		p.x += (-1.0 if path[i] == "0" else 1.0) * DX[i]
		p.y += DY
	return p


# ------------------------------------------------------------------ tekenen

func _paint() -> void:
	if _mode() == "cuts":
		_paint_cuts()
	else:
		_paint_design()


func _paint_cuts() -> void:
	caption("Grenzen", "knip de strook in codewoorden · een lezing per volledige knipreeks")
	var code: Dictionary = stage.get("code", {})
	var bits := str(cur.get("bits", stage.get("bits", "")))
	var start := int(cur.get("start", 0))
	var parts: Array = cur.get("parts", [])
	# code van de kelner
	var x := 60.0
	table_label(Vector2(60, 280), "code van de kelner:", 22)
	x = 300.0
	for k in code:
		var s := "%s = %s" % [ScPal.show(str(k)), str(code[k])]
		var w := ScPal.text_w(ScPal.MONO_B, s, 26) + 30
		draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 8, 4, ScPal.VELLUM_EDGE), Rect2(x, 260, w, 44))
		ScPal.text_l(self, ScPal.MONO_B, Vector2(x + 15, 282), s, 26, ScPal.INK)
		x += w + 16
	# grote strook
	var n := bits.length()
	var cw := 90.0
	var x0 := 640.0 - cw * n / 2.0
	var y := 470.0
	ScDraw.parchment(self, Rect2(x0 - 30, y - 60, cw * n + 60, 120), 31, ScPal.VELLUM, true, 0.5)
	var cuts_at := {}
	var acc := 0
	for p in parts:
		acc += str(p).length()
		cuts_at[acc] = true
	for i in n:
		var c := Vector2(x0 + cw * (i + 0.5), y)
		var used := i < start
		ScPal.text_c(self, ScPal.MONO, c, bits[i], 60, ScPal.INK_FADED if used else ScPal.INK)
		var half := 12.0 if bits[i] == "0" else 30.0
		draw_line(Vector2(c.x - half, y + 40), Vector2(c.x + half, y + 40), ScPal.INK_FADED if used else ScPal.INK, 4.0, true)
	# letters onder de geknipte woorden
	var s0 := 0
	for p in parts:
		var w2 := str(p).length()
		var cx := x0 + cw * (s0 + w2 / 2.0)
		var inv := ScReference.inverse(code)
		var letter := str(inv.get(str(p), "?"))
		draw_style_box(ScPal.sb(ScPal.letter_color(letter, alphabet), 8), Rect2(cx - 24, y + 62, 48, 50))
		ScPal.text_c(self, ScPal.MONO, Vector2(cx, y + 87), letter, 34, ScPal.INK)
		s0 += w2
	_gap_r = []
	for i in range(1, n + 1):
		var gx := x0 + cw * i
		var r := Rect2(gx - 22, y - 60, 44, 120)
		_gap_r.append(r)
		var m := {"act": "cut", "at": i}
		if cuts_at.has(i):
			ScDrawTools.scissors(self, Vector2(gx, y - 76), 0.8, 0.1, PI / 2)
			draw_line(Vector2(gx, y - 52), Vector2(gx, y + 52), ScPal.RUBRIC, 3.0, true)
		elif i > start and not tool.is_done():
			if is_hover(m) or is_ghost(m):
				draw_line(Vector2(gx, y - 52), Vector2(gx, y + 52), ScPal.INFO, 3.0, true)
				ScDrawTools.scissors(self, Vector2(gx, y - 76), 0.8, 0.5, PI / 2)
			zone(r, m)
	# lezingen
	var readings: Array = cur.get("readings", [])
	var flash := clampf(1.0 - (t - _reading_flash) * 1.5, 0.0, 1.0)
	table_label(Vector2(60, 680), "lezingen gevonden: %d (nodig: %d, alle: %d)" % [readings.size(), int(cur.get("need", 1)),
		int(cur.get("total", 0))], 22)
	var lx := 60.0
	for q in readings.size():
		var rs := str(readings[q])
		var w3 := ScPal.word_width(rs.length(), 30) + 30
		var rr := Rect2(lx, 720, w3, 56)
		draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 8, 4, ScPal.VELLUM_EDGE), rr)
		if q == readings.size() - 1 and flash > 0:
			ScPal.ring(self, rr.grow(4), 10, Color(ScPal.GOLD, flash), 3)
		ScPal.word(self, rr.get_center(), rs, 30, true, alphabet)
		lx += w3 + 16


func _paint_design() -> void:
	caption("Het codebord", "hang letters enkel aan bladeren · frequente letters hoog")
	var placed: Dictionary = cur.get("placed", {})
	var by_path := {}
	for s in placed:
		by_path[str(placed[s])] = str(s)
	_nodes = {}
	var md := int(cur.get("max_depth", 3))
	# lege knopen en takken
	var paths: Array = [""]
	for d in md:
		var nxt: Array = []
		for p in paths:
			if str(p).length() == d:
				nxt.append(str(p) + "0")
				nxt.append(str(p) + "1")
		paths.append_array(nxt)
	for p in paths:
		var ps := str(p)
		if ps == "":
			continue
		var parent := ps.substr(0, ps.length() - 1)
		var live := not _under_leaf(ps, by_path) or by_path.has(ps)
		ScDrawTools.branch(self, _node_pos(parent), _node_pos(ps), ps[ps.length() - 1], false, 5.0 if live else 3.0, t, not live or not _used(ps, by_path))
	for p in paths:
		var ps2 := str(p)
		var pos := _node_pos(ps2)
		if ps2 != "":
			_nodes[ps2] = pos
		var hov := ps2 != "" and pos.distance_to(_mouse_p) < 50 and (_drag != "" or _sel_sym != "")
		ScDrawTools.knob(self, pos, 13 if ps2 != "" else 16, hov)
		if hov:
			ScPal.ring(self, Rect2(pos - Vector2(26, 26), Vector2(52, 52)), 26, ScPal.INFO, 3)
		if guides and ps2 != "":
			ScPal.text_c(self, ScPal.MONO_M, pos + Vector2(0, -26), ps2, 16, ScPal.TEXT_DIM)
	# geplaatste tegels + lade
	_tiles = {}
	var freqs: Array = cur.get("freqs", [])
	var bad := _prefix_violators(placed)
	var tx := 120.0
	ScDraw.wood(self, Rect2(60, TRAY_Y - 10, 1140, 70), ScPal.OAK_DARK, 10)
	for f in freqs:
		var s := str(f[0])
		var a := int(f[1])
		var r: Rect2
		if s == _drag:
			r = ScDrawTools.leaf_tile(self, _mouse_p - Vector2(0, 60), s, 32, alphabet, true, "", t, a)
		elif placed.has(s):
			var pp := str(placed[s])
			r = ScDrawTools.leaf_tile(self, _node_pos(pp), s, 30, alphabet, s == _sel_sym, pp, t, a)
			if bad.has(s):
				ScDraw.ink_blot(self, r.get_center() + Vector2(26, -24), 12, s.hash() % 50)
				ScPal.ring(self, r.grow(6), 10, ScPal.SEPIA, 3)
		else:
			r = ScDrawTools.leaf_tile(self, Vector2(tx, TRAY_Y - 40), s, 30, alphabet, s == _sel_sym, "", t, a)
		_tiles[s] = r
		tx += 120
	table_label(Vector2(640, TRAY_Y + 74), "sleep een tegel op een knoop (rechtsklik = weghalen) · Σ a(x)·l(x) = %d · optimum %d" % [
		int(cur.get("ink", 0)), int(cur.get("optimum", 0))], 18, ScPal.TEXT, true)


func _under_leaf(path: String, by_path: Dictionary) -> bool:
	for k in range(1, path.length()):
		if by_path.has(path.substr(0, k)):
			return true
	return false


func _used(path: String, by_path: Dictionary) -> bool:
	for p in by_path:
		if str(p).begins_with(path):
			return true
	return false


static func _prefix_violators(placed: Dictionary) -> Dictionary:
	var out := {}
	for a in placed:
		for b in placed:
			if a != b and str(placed[b]).begins_with(str(placed[a])):
				out[a] = true
				out[b] = true
	return out


func draw_overkant(ci: CanvasItem, r: Rect2) -> void:
	if _mode() == "cuts":
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Letterlijk leest gulzig:", 20, ScPal.TEXT)
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 54), "telkens het kortste woord dat hij herkent.", 20, ScPal.TEXT)
		return
	if bool(ov.get("trial", false)):
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Proeflezing (geen prefixcode):", 20, ScPal.WARN)
	else:
		ScPal.text_l(ci, ScPal.UI_MED, r.position + Vector2(10, 24), "Letterlijk wacht op je code.", 20, ScPal.TEXT)
