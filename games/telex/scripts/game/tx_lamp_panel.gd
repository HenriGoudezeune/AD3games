class_name TxLampPanel
extends TxPanel
## Lampenbord en ruisbord (shift-AND, Definitie 13/14, Algoritme 6; GDD §3.5–3.6, §4.4).
## CARDS: ponskaarten C_x ponsen (klik een gatpositie; Tab/↑↓/Spatie). WIRE: foutkabel in één van vier aansluitingen
## (1–4). Doorloop per teken: hendel (S/↓) en kaart insteken (letter typen of klikken; Spatie/0 = blanco).
## CHOOSE (6-2): stuur de ploeg naar één van de kandidaten.

var k := 0
var letters: Array = []          # kaartletters (alfabetisch) + "" (blanco)
var cards := {}                  # letter -> bitstring
var disp: Array = []             # per niveau l: bitstring op het bord
var logs: Array = []             # per niveau l: [bitstring per j]
var j := 0
var lever_u := 0.0
var lever_pulled := false
var card_sel := 0
var row_sel := 0
var ins_letter := "?"
var ins_u := 0.0
var bells: Array = []
var wiring := {}
var cable_sway := 0.0
var beat_u := 0.0
var drop := 0.0
var pitch := 52.0
var choose_starts: Array = []
var auto_lever := false
var COL_Y := 110.0


func _setup() -> void:
	var sa := mc as TxShiftAnd
	k = sa.k
	auto_lever = sa.auto_lever
	letters = sa.c_true.keys()
	letters.sort()
	letters.append("")
	pitch = clampf(280.0 / maxf(1, m), 34.0, 54.0)
	COL_Y = 110.0 if k == 0 else 128.0
	tape.stencils = []
	tape.strip_vals = []
	tape.labels = []
	tape.arc = {}
	tape.punch = {}
	tape.setup_text(mc.t)
	tape.head_on = mc.t != ""
	tape.show_positions = mc.t != ""
	tape.head_col = 0.0
	tape.follow = 0.0
	tape.follow_hi = -1.0
	tape.scroll = 0.0
	tape.scroll_target = 0.0
	if mc.mode == TxCodes.Mode.LIVE:
		tape.front = 0
	disp = []
	logs = []
	bells = []
	for l in k + 1:
		disp.append("0".repeat(m))
		logs.append([])
		bells.append(0.0)
	_read_cards(sa.cursor())
	wiring = sa.wiring.duplicate()
	tape.tape_clicked.connect(_on_tape)


func _read_cards(c: Dictionary) -> void:
	cards = {}
	var cd: Dictionary = c.get("cards", {})
	for x in cd:
		var s := ""
		for b in cd[x]:
			s += str(int(b))
		cards[str(x)] = s


func plate() -> Array:
	return ["MODEL  W-M  1992", "RUISBORD  (k = %d)" % k] if k > 0 else ["MODEL  B-Y/G", "LAMPENBORD"]


func unit() -> Array:
	return ["LAMPSLAGEN", "lamps"]


func chef_anchor() -> Vector2:
	return Vector2.INF


func col_x(l: int) -> float:
	return 190.0 + l * 400.0


func cards_x() -> float:
	return 420.0 if k == 0 else 860.0


func card_x(i: int) -> float:
	return cards_x() + i * 74.0


func log_rect(l: int) -> Rect2:
	var x0 := card_x(letters.size()) + 10.0
	var w := 1560.0 - x0
	if k == 0:
		return Rect2(x0, 24, w, 420)
	var h := 420.0 / (k + 1) - 8
	return Rect2(x0, 24 + l * (h + 8), w, h)




func fx(f: Dictionary) -> float:
	match str(f.fx):
		"ready":
			tape.head_col = 0.0
			return 0.0
		"hole":
			var x := str(f.x)
			var i := int(f.i)
			var s: String = cards.get(x, "0".repeat(m))
			s = s.substr(0, i) + ("1" if bool(f.on) else "0") + s.substr(i + 1)
			cards[x] = s
			TxSnd.play("punch", -4.0, 1.1 if bool(f.on) else 0.8)
			TxFx.punch_dots(con.fx_layer, global_position + Vector2(card_x(letters.find(x)), COL_Y + i * pitch + 10), 4)
			return d(0.1)
		"plug":
			wiring[int(f.l)] = str(f.src)
			TxSnd.play("plug", -2.0)
			cable_sway = 1.0
			create_tween().tween_property(self, "cable_sway", 0.0, d(0.8)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			TxFx.sparks(con.fx_layer, global_position + _socket_pos(TxCodes.PLUGS.find(str(f.src))), 6)
			return d(0.2)
		"lever":
			var cols: Array = f.get("cols", [])
			lever_pulled = true
			TxSnd.play("lever", -2.0)
			TxSnd.play("relay", -10.0, 0.9)
			var tw := create_tween()
			tw.tween_property(self, "lever_u", 1.0, d(0.09)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func():
				for l in cols.size():
					disp[l] = _bits(cols[l])
				drop = 1.0
				TxSnd.play("lamp_on", -10.0, 1.2)
				TxFx.flash(con.fx_layer, global_position + Vector2(col_x(0), COL_Y + 10), TxPal.SIG_WHITE, 0.7, 0.3))
			tw.tween_property(self, "drop", 0.0, d(0.12))
			tw.tween_property(self, "lever_u", 0.0, d(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			return d(0.2)
		"card":
			var x2 := str(f.x)
			var cols2: Array = f.get("cols", [])
			ins_letter = x2
			ins_u = 1.0
			TxSnd.play("card_in", -3.0)
			var tw2 := create_tween()
			tw2.tween_interval(d(0.1))
			tw2.tween_callback(func():
				for l in cols2.size():
					var nb := _bits(cols2[l])
					if nb.count("1") < str(disp[l]).count("1"):
						TxSnd.play("lamp_on", -16.0, 0.7)
					disp[l] = nb
				lever_pulled = false)
			tw2.tween_property(self, "ins_u", 0.0, d(0.35)).set_delay(d(0.15))
			j = int(f.j) + 1
			tape.states[int(f.j)] = "eq" if (x2 != "") else ""
			if x2 == "":
				tape.states.erase(int(f.j))
			return d(0.18)
		"column":
			var cols3: Array = f.get("cols", [])
			if bool(f.get("reset", false)):
				for l in cols3.size():
					disp[l] = _bits(cols3[l])
				return d(0.1)
			for l in cols3.size():
				if l < logs.size():
					var lg: Array = logs[l]
					var jj := int(f.j)
					while lg.size() < jj:
						lg.append("0".repeat(m))
					if lg.size() == jj:
						lg.append(_bits(cols3[l]))
			TxSnd.tak(-12.0, 1.2)
			tape.head_col = float(int(f.j) + 1 if int(f.j) + 1 < mc.n else int(f.j))
			tape.follow = tape.head_col
			return d(0.06)
		"hit":
			var l2 := clampi(int(f.get("level", 0)), 0, k)
			bells[l2] = 1.0
			create_tween().tween_method(func(v: float): bells[l2] = v, 1.0, 0.0, d(1.0))
			if not bool(f.get("real", true)):
				TxSnd.play("bell", -6.0, 0.8)
			return d(0.1)
		"choose":
			TxSnd.play("searchlight", -2.0)
			return d(0.3)
		"bump":
			bump_at(global_position + Vector2(col_x(k) + 140, 200), 6)
			lever_u = 0.4
			create_tween().tween_property(self, "lever_u", 0.0, d(0.3)).set_trans(Tween.TRANS_ELASTIC)
			return d(0.12)
	return 0.0


static func _bits(a) -> String:
	if a is String:
		return a
	var s := ""
	for b in a:
		s += str(int(b))
	return s


func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	j = int(c.get("j", 0))
	lever_pulled = bool(c.get("lever_pulled", false))
	var cols: Array = c.get("cols", [])
	for l in mini(cols.size(), disp.size()):
		disp[l] = _bits(cols[l])
	_read_cards(c)
	wiring = (c.get("wiring", {}) as Dictionary).duplicate()
	if ph in [P.LEVER, P.CARD]:
		tape.head_col = float(mini(j, mc.n - 1))
		tape.follow = tape.head_col
	if ph == P.CHOOSE:
		choose_starts = []
		for h in mc.hits:
			if not choose_starts.has(int(h.start)):
				choose_starts.append(int(h.start))
		tape.hover_enabled = true
	else:
		tape.hover_enabled = false


func rebuild() -> void:
	var sa := mc as TxShiftAnd
	for l in disp.size():
		logs[l] = []
	sync(sa.phase, sa.cursor())


func beat() -> void:
	beat_u = 1.0
	create_tween().tween_property(self, "beat_u", 0.0, 0.25)


# ---------------------------------------------------------------- invoer
func _card(x: String) -> void:
	if phase == P.LEVER or phase == P.CARD:
		move({"act": "card", "x": x})


func _toggle() -> void:
	if phase == P.CARDS and card_sel < letters.size() - 1:
		move({"act": "hole", "x": letters[card_sel], "i": row_sel})


func key(e: InputEventKey) -> bool:
	var kc := e.keycode
	match phase:
		P.CARDS:
			if kc == KEY_TAB or kc == KEY_RIGHT:
				card_sel = (card_sel + 1) % maxi(1, letters.size() - 1)
				return true
			if kc == KEY_LEFT:
				card_sel = (card_sel + letters.size() - 2) % maxi(1, letters.size() - 1)
				return true
			if kc == KEY_DOWN:
				row_sel = mini(m - 1, row_sel + 1)
				return true
			if kc == KEY_UP:
				row_sel = maxi(0, row_sel - 1)
				return true
			if kc == KEY_SPACE:
				_toggle()
				return true
			if kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_D:
				move({"act": "cards_done"})
				return true
		P.WIRE:
			if kc >= KEY_1 and kc <= KEY_4:
				move({"act": "plug", "l": 1 if k >= 1 else 1, "src": TxCodes.PLUGS[kc - KEY_1]})
				return true
			if kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_D:
				move({"act": "wire_done"})
				return true
		P.LEVER, P.CARD:
			if (kc == KEY_S or kc == KEY_DOWN) and not auto_lever:
				move({"act": "lever"})
				return true
			if kc == KEY_SPACE or kc == KEY_0 or kc == KEY_KP_0:
				_card("")
				return true
			var ch := char(e.unicode).to_lower() if e.unicode > 0 else ""
			if ch != "" and letters.has(ch):
				_card(ch)
				return true
		P.CHOOSE:
			if kc >= KEY_1 and kc <= KEY_9 and kc - KEY_1 < choose_starts.size():
				move({"act": "choose", "start": choose_starts[kc - KEY_1]})
				return true
	return false


func _socket_pos(i: int) -> Vector2:
	return Vector2(col_x(0) + 100, 70) + Vector2(138, 42 + i * 64)


func hot(p: Vector2) -> Dictionary:
	# kaarten (in de kaartenfase: één gat per klik; anders: kaart = teken invoeren)
	for i in letters.size():
		var cx := card_x(i)
		var cr := Rect2(cx - 29, COL_Y - 52, 58, m * pitch + 64)
		if cr.has_point(p):
			if phase == P.CARDS and i < letters.size() - 1:
				var row := int(floor((p.y - (COL_Y + 10 - pitch / 2.0)) / pitch))
				if row >= 0 and row < m:
					var ii := i
					return {"rect": Rect2(cx - 27, COL_Y + 10 - pitch / 2.0 + row * pitch, 54, pitch),
						"call": func():
							card_sel = ii
							row_sel = row
							_toggle()}
				return {}
			var lt = letters[i]
			return {"rect": cr, "call": func(): _card(lt)}
	# hendel
	var lx := lever_x()
	var lr := Rect2(lx - 30, COL_Y - 40, 120, m * pitch + 60)
	if lr.has_point(p) and not auto_lever:
		return {"rect": lr, "call": func(): move({"act": "lever"})}
	# aansluitingen (foutkabel, ruisbord)
	if k > 0:
		for i in 4:
			if p.distance_to(_socket_pos(i)) < 28:
				var src = TxCodes.PLUGS[i]
				return {"rect": Rect2(_socket_pos(i) - Vector2(28, 28), Vector2(56, 56)),
					"call": func(): move({"act": "plug", "l": 1, "src": src})}
	return {}


func tape_clickable(kind_: String, pos: int) -> bool:
	if kind_ != "tape" or phase != P.CHOOSE:
		return false
	for s0 in choose_starts:
		if pos >= int(s0) and pos < int(s0) + m:
			return true
	return false


func _on_tape(pos: int) -> void:
	if phase != P.CHOOSE or con.input_locked():
		return
	for s in choose_starts:
		if pos >= int(s) and pos < int(s) + m:
			move({"act": "choose", "start": int(s)})
			return


func lever_x() -> float:
	return col_x(k) + 120.0


func buttons() -> Array:
	match phase:
		P.CARDS:
			return [{"text": "Kaarten klaar", "key": "D", "kind": "brass", "enabled": true, "call": func(): move({"act": "cards_done"})},
				{"text": "Gat aan/uit", "key": "Spatie", "kind": "key", "enabled": true, "call": _toggle}]
		P.WIRE:
			return [{"text": "Bedrading klaar", "key": "D", "kind": "brass", "enabled": true, "call": func(): move({"act": "wire_done"})}]
		P.LEVER, P.CARD:
			var out: Array = []
			if not auto_lever:
				out.append({"text": "Hendel", "key": "S", "kind": "brass", "enabled": phase == P.LEVER, "call": func(): move({"act": "lever"})})
			out.append({"text": "Blanco", "key": "Spatie", "kind": "key", "enabled": true, "call": func(): _card("")})
			return out
		P.CHOOSE:
			var out2: Array = []
			for i in choose_starts.size():
				var s := int(choose_starts[i])
				out2.append({"text": "@%d" % s, "key": str(i + 1), "kind": "key", "enabled": true, "call": func(): move({"act": "choose", "start": s})})
			return out2
	return []


func hint(mv: Dictionary) -> Vector2:
	match str(mv.get("act", "")):
		"hole":
			card_sel = letters.find(str(mv.x))
			row_sel = int(mv.i)
			return global_position + Vector2(card_x(card_sel), COL_Y + row_sel * pitch + 10)
		"card":
			return global_position + Vector2(card_x(letters.find(str(mv.x))), COL_Y - 30)
		"lever":
			return global_position + Vector2(lever_x() + 60, COL_Y + 40)
		"plug":
			return global_position + _socket_pos(TxCodes.PLUGS.find(str(mv.src)))
		"choose":
			return tape.char_pos(float(int(mv.start)) + m / 2.0) + Vector2(0, 40)
	return con.button_pos(0)


func hit_origin(f: Dictionary) -> Vector2:
	return tape.char_pos(float(int(f.end)))


# ---------------------------------------------------------------- tekenen
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	TxPal.brass_plate(self, Vector2(150, 30), pl[0], 18, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, Vector2(290, 30), pl[1], 24, TxPal.TEXT)
	var running := phase in [P.LEVER, P.CARD]
	# lampkolommen
	for l in k + 1:
		var col: Color = TxPal.LEVEL_COLORS[mini(l, 2)]
		var lr := TxDrawMachines.lamp_column(self, col_x(l), COL_Y, z, disp[l], pitch, col, drop, float(bells[l]), l == 0 or true)
		if k > 0:
			TxDrawMachines.sup_label(self, Vector2(col_x(l) + 70, COL_Y - 50), "M", str(l), 24, col)
		TxDrawMachines.bell(self, Vector2(col_x(l) + 64, COL_Y + (m - 1) * pitch + 10), 16.0 - l * 2.0, float(bells[l]))
		# voedingslamp-pijl
		if l > 0:
			TxPal.lamp(self, Vector2(col_x(l), COL_Y - 30), 5, TxPal.SIG_WHITE, 1.0)
	# ruisbord: stekkerbus + kabel + OF-poort
	if k > 0:
		var src := str(wiring.get(1, ""))
		var lit := TxCodes.PLUGS.find(src)
		var socks: Array = TxDrawMachines.sockets(self, Vector2(col_x(0) + 100, 70), lit)
		var gate := Vector2(col_x(1) - 70, COL_Y + 10)
		TxDrawMachines.or_gate(self, gate, 1.0, running)
		if lit >= 0:
			TxDrawMachines.cable(self, socks[lit], gate + Vector2(-24, 0), 50, Color("#B23A2A"), cable_sway)
		elif phase == P.WIRE:
			TxDrawMachines.cable(self, gate + Vector2(-60, 160), gate + Vector2(-24, 0), 30, Color("#B23A2A"), sin(t * 2.0) * 0.4)
		draw_line(gate + Vector2(26, 0), Vector2(col_x(1) - 46, COL_Y + 10), TxPal.SIG_AMBER if running else TxPal.STEEL, 3.0)
	# hendel
	TxDrawMachines.lever(self, lever_x(), COL_Y - 30, m * pitch + 10, lever_u, "S" if not auto_lever else "♪")
	if auto_lever and beat_u > 0.0:
		TxPal.glow(self, Vector2(lever_x() + 60, COL_Y + 40), 160, TxPal.SIG_AMBER, 0.5 * beat_u)
	# ponskaarten
	for i in letters.size():
		var x: String = letters[i]
		var bits: String = cards.get(x, "0".repeat(m)) if x != "" else "0".repeat(m)
		var inserted := running and x == ins_letter and ins_u > 0.0
		var cy := COL_Y - (16.0 * ins_u if inserted else 0.0)
		TxDrawMachines.punch_card(self, card_x(i), cy, x if x != "" else "blanco", bits, pitch, inserted,
				row_sel if (phase == P.CARDS and i == card_sel) else -1, 58)
		if running:
			var key_l := x if x != "" else "␣"
			TxDraw.keycap(self, Vector2(card_x(i) - 14, COL_Y + m * pitch + 22), key_l, 14)
	# matrixlog(s)
	if mc.t != "":
		for l in k + 1:
			var lg: Array = logs[l]
			var boxes: Array = []
			for jj in lg.size():
				if str(lg[jj]).ends_with("1"):
					boxes.append([jj, TxPal.STAMP_RED])
			TxDrawMachines.matrix_log(self, log_rect(l), mc.t, z, lg, j if running else -1, boxes, "M" if k == 0 else "M^%d" % l)
	else:
		var ir := log_rect(0)
		var y := ir.position.y + 30
		var lines: Array = ["Ponskaarten C_x (Algoritme 6):", "kaart x krijgt een gat op rij i", "als z[i] = x.", "", "Tab / ← → = kaart, ↑ ↓ = rij,", "Spatie = gat, D = klaar."]
		if phase == P.WIRE:
			lines = ["Foutkabel van M¹ (Definitie 14):", "een fout op t[j] bouwt verder op", "M⁰ van kolom j−1, geschoven.", "", "Kies de aansluiting (1–4),", "dan D = bedrading klaar."]
		for l2 in lines:
			TxPal.text_l(self, TxPal.UI, Vector2(ir.position.x + 10, y), str(l2), 22, TxPal.TEXT_DIM if l2 != lines[0] else TxPal.TEXT)
			y += 34
	if running:
		var ch := mc.t[j] if j < mc.n else ""
		TxPal.text_l(self, TxPal.UI_BOLD, Vector2(28, 452), "t[%d] = %s   ·   hendel (S), dan kaart (letter of Spatie = blanco)" % [j, ch] if not auto_lever else "Op de tel: typ t, i of k. Al de rest is blanco.", 20, TxPal.TEXT)
	elif phase == P.CHOOSE:
		TxPal.text_l(self, TxPal.UI_BOLD, Vector2(28, 452), "Stuur de ploeg naar de echte zender: klik een kandidaat op het lint (of 1–%d)." % choose_starts.size(), 20, TxPal.SIG_AMBER)
