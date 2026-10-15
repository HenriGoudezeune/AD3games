class_name TxBoardPanel
extends TxPanel
## Schakelbord (editeerafstand, Algoritme 7) en zoeklicht (Algoritme 8); GDD §3.7–3.8, §4.4.
## FILL: per relais de ingang kiezen (Q/Spatie = ↖, W/↑ = ↑, A/← = ←, of klik een draadje/buurcel). De waarde volgt.
## PICK_END: klik de cel met de laagste meter in de onderste rij (←/→ + Enter). TRACE: terug langs stroomvoerende
## draadjes. TRACE_DONE: nog een reeks (R) of klaar (Enter). Finale F-2 (lead-beslissing): de machine vult zelf.

var approx := false
var a := ""
var b := ""
var vals: Array = []
var dirs: Array = []
var warm := {}
var path: Array = []
var cc := Vector2i(1, 1)
var cell := 56.0
var origin := Vector2.ZERO
var end_sel := 0
var flow := 0.0
var word := ""
var word_ops := {}
var seqs_txt: Array = []
var auto_fill := false
var spot_u := 0.0
var spot_aim := Vector2.ZERO
var _auto_acc := 0.0
var meter_pop := {}


func _setup() -> void:
	var eb := mc as TxEditBoard
	approx = eb.approx
	a = eb.a
	b = eb.b
	auto_fill = approx and str(stage.get("tape", "")) == "F-2"
	_read(eb.render())
	word = a
	if approx:
		tape.stencils = []
		tape.strip_vals = []
		tape.labels = []
		tape.arc = {}
		tape.punch = {}
		tape.setup_text(b)
		tape.head_on = false
		tape.show_positions = true
		tape.follow = 0.0
		tape.follow_hi = -1.0
		tape.scroll = 0.0
		tape.scroll_target = 0.0
	var cols := b.length() + 1
	var rows := a.length() + 1
	if approx:
		cell = clampf(minf(1500.0 / (cols + 1.5), 360.0 / (rows + 1.2)), 28.0, 56.0)
		origin = Vector2(70 + cell, 30 + cell * 1.2)
	else:
		cell = clampf(minf(980.0 / (cols + 1.5), 640.0 / (rows + 1.2)), 44.0, 76.0)
		origin = Vector2(70 + cell, 70 + cell * 1.4)
	end_sel = b.length()


func uses_tape() -> bool:
	return (mc as TxEditBoard).approx


func plate() -> Array:
	return ["MODEL  L-8", "ZOEKLICHT"] if approx else ["MODEL  L", "SCHAKELBORD"]


func unit() -> Array:
	return ["RELAIS", "relays"]


func chef_anchor() -> Vector2:
	return Vector2.INF


func _read(r: Dictionary) -> void:
	vals = []
	dirs = []
	var tb: Array = r.get("tab", [])
	var dr: Array = r.get("dirs", [])
	for i in tb.size():
		var row: Array = []
		var drow: Array = []
		for j in (tb[i] as Array).size():
			var v := int(tb[i][j])
			row.append(v if v >= 0 else null)
			var dd := str(dr[i][j]) if i < dr.size() and j < (dr[i] as Array).size() else ""
			drow.append({"diag": "d", "up": "u", "left": "l"}.get(dd, ""))
		vals.append(row)
		dirs.append(drow)


func cell_center(i: int, j: int) -> Vector2:
	return origin + Vector2((j + 0.5) * cell, (i + 0.5) * cell)


func fx(f: Dictionary) -> float:
	match str(f.fx):
		"cell":
			var i := int(f.i)
			var j := int(f.j)
			vals[i][j] = int(f.v)
			dirs[i][j] = {"diag": "d", "up": "u", "left": "l"}.get(str(f.dir), "")
			if bool(f.get("warm", false)):
				warm[Vector2i(i, j)] = true
				TxSnd.play("lamp_hum_loop", -14.0, 1.4, false, 200)
			TxSnd.play("relay", -8.0 if not auto_fill else -18.0, 1.0 + 0.03 * int(f.v), true, 25)
			flow = 1.0
			create_tween().tween_property(self, "flow", 0.0, d(0.25))
			if not auto_fill:
				TxFx.flash(con.fx_layer, global_position + cell_center(i, j), TxPal.SIG_AMBER, 0.5, 0.25)
			return d(0.12) if not auto_fill else d(0.015)
		"end_pick":
			var jj := int(f.j)
			spot_aim = cell_center(a.length(), jj)
			spot_u = 0.0
			TxSnd.play("searchlight", 0.0)
			create_tween().tween_property(self, "spot_u", 1.0, d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			path = [Vector2i(a.length(), jj)]
			return d(0.6)
		"trace_step":
			var i2 := int(f.i)
			var j2 := int(f.j)
			var pr := TxReference.pred(str(f.dir), i2, j2)
			if path.is_empty():
				path.append(Vector2i(i2, j2))
			path.append(Vector2i(pr.x, pr.y))
			var op: Dictionary = f.get("op", {})
			TxSnd.play("trace_step", -4.0)
			if not op.is_empty():
				TxSnd.play("typewriter", -6.0)
				TxFx.floater(con.fx_layer, global_position + cell_center(i2, j2) + Vector2(0, -30), {"vervang": "vervang", "verwijder": "verwijder", "voegtoe": "voeg toe"}.get(str(op.op), ""), TxPal.SIG_AMBER, 20, 30, 0.6)
			flow = 1.0
			create_tween().tween_property(self, "flow", 0.0, d(0.3))
			return d(0.2)
		"print_ops":
			var ops: Array = f.get("ops", [])
			word = str(f.get("result", word))
			word_ops = {}
			var lines := PackedStringArray()
			for o in ops:
				match str(o.op):
					"vervang":
						lines.append("vervang %s op %d door %s" % [str(o.from), int(o.pos), str(o.to)])
						word_ops[int(o.pos)] = "sub"
					"verwijder":
						lines.append("verwijder %s op %d" % [str(o.from), int(o.pos)])
					"voegtoe":
						lines.append("voeg %s toe op %d" % [str(o.to), int(o.pos)])
						word_ops[int(o.pos)] = "ins"
			var pre := ("@%d: " % int(f.start)) if approx else ""
			seqs_txt.append(pre + (" · ".join(lines) if not lines.is_empty() else "(geen bewerkingen)"))
			TxSnd.play("telex_rattle", -6.0)
			if approx:
				tape.spot = [int(f.start), int(f.end)]
			return d(0.5)
		"bump":
			bump_at(global_position + cell_center(cc.x, cc.y), 6)
			return d(0.12)
	return 0.0


func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	cc = Vector2i(int(c.get("i", 1)), int(c.get("j", 1)))
	if ph == P.PICK_END:
		path = []
		spot_u = 0.0
		var eb := mc as TxEditBoard
		end_sel = eb.min_cols()[0] if false else end_sel
	if ph == P.TRACE and path.is_empty():
		path = [cc]


func rebuild() -> void:
	_read(mc.render())
	warm = {}
	path = []
	sync(mc.phase, mc.cursor())


func _process(dt: float) -> void:
	super._process(dt)
	# Finale F-2: de machine vult de tabel zelf (lead-beslissing F-2), telt als machinetijd.
	if auto_fill and phase == P.FILL and not con.is_busy() and not con.input_locked():
		_auto_acc += dt
		var guard := 0
		while _auto_acc > 0.0 and guard < 6 and phase == P.FILL:
			_auto_acc -= 0.02
			guard += 1
			var mv := mc.correct_move()
			if str(mv.get("act", "")) != "fill":
				break
			mv["auto"] = true
			mc.apply(mv)
			phase = mc.phase


# ---------------------------------------------------------------- invoer
func _dir_key(kc: int) -> String:
	match kc:
		KEY_Q, KEY_SPACE:
			return "diag"
		KEY_W, KEY_UP:
			return "up"
		KEY_A, KEY_LEFT:
			return "left"
	return ""


func key(e: InputEventKey) -> bool:
	var kc := e.keycode
	match phase:
		P.FILL:
			if auto_fill:
				return false
			var dname := _dir_key(kc)
			if dname != "":
				move({"act": "fill", "dir": dname})
				return true
		P.TRACE:
			var d2 := _dir_key(kc)
			if d2 != "":
				move({"act": "step", "dir": d2})
				return true
		P.PICK_END:
			if kc == KEY_LEFT:
				end_sel = maxi(0, end_sel - 1)
				return true
			if kc == KEY_RIGHT:
				end_sel = mini(b.length(), end_sel + 1)
				return true
			if kc == KEY_ENTER or kc == KEY_KP_ENTER:
				move({"act": "pick_end", "j": end_sel})
				return true
		P.TRACE_DONE:
			if kc == KEY_R:
				move({"act": "trace_again"})
				return true
			if kc == KEY_ENTER or kc == KEY_KP_ENTER:
				move({"act": "finish"})
				return true
	return false


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and phase == P.PICK_END:
		var j0 := _col_at(e.position)
		if j0 >= 0:
			end_sel = j0
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or not con.can_act():
		return
	var p: Vector2 = e.position
	var rel := (p - origin) / cell
	var ci := int(floor(rel.y))
	var cj := int(floor(rel.x))
	match phase:
		P.FILL, P.TRACE:
			var dname := ""
			var base := cc
			if ci == base.x and cj == base.y:
				var fx_ := rel.x - cj
				var fy := rel.y - ci
				if fx_ < 0.4 and fy < 0.4:
					dname = "diag"
				elif fy < 0.4:
					dname = "up"
				elif fx_ < 0.4:
					dname = "left"
			elif ci == base.x - 1 and cj == base.y - 1:
				dname = "diag"
			elif ci == base.x - 1 and cj == base.y:
				dname = "up"
			elif ci == base.x and cj == base.y - 1:
				dname = "left"
			if dname != "" and not auto_fill:
				move({"act": "fill" if phase == P.FILL else "step", "dir": dname})
				accept_event()
		P.PICK_END:
			var j1 := _col_at(p)
			if j1 >= 0:
				move({"act": "pick_end", "j": j1})
				accept_event()


func _col_at(p: Vector2) -> int:
	var rel := (p - origin) / cell
	if int(floor(rel.y)) == a.length() and rel.x >= 0 and rel.x < b.length() + 1:
		return int(floor(rel.x))
	return -1


func buttons() -> Array:
	match phase:
		P.FILL:
			if auto_fill:
				return []
			return [{"text": "↖", "key": "Q", "kind": "key", "enabled": true, "call": func(): move({"act": "fill", "dir": "diag"})},
				{"text": "↑", "key": "W", "kind": "key", "enabled": true, "call": func(): move({"act": "fill", "dir": "up"})},
				{"text": "←", "key": "A", "kind": "key", "enabled": true, "call": func(): move({"act": "fill", "dir": "left"})}]
		P.TRACE:
			return [{"text": "↖", "key": "Q", "kind": "key", "enabled": true, "call": func(): move({"act": "step", "dir": "diag"})},
				{"text": "↑", "key": "W", "kind": "key", "enabled": true, "call": func(): move({"act": "step", "dir": "up"})},
				{"text": "←", "key": "A", "kind": "key", "enabled": true, "call": func(): move({"act": "step", "dir": "left"})}]
		P.PICK_END:
			return [{"text": "Zoeklicht hier", "key": "Enter", "kind": "brass", "enabled": true, "call": func(): move({"act": "pick_end", "j": end_sel})}]
		P.TRACE_DONE:
			return [{"text": "Nog een reeks", "key": "R", "kind": "key", "enabled": true, "call": func(): move({"act": "trace_again"})},
				{"text": "Klaar", "key": "Enter", "kind": "brass", "enabled": true, "call": func(): move({"act": "finish"})}]
	return []


func hint(mv: Dictionary) -> Vector2:
	var c := global_position + cell_center(cc.x, cc.y)
	match str(mv.get("act", "")):
		"fill", "step":
			# binnen de klikzone van de cel (rand < 0,4 cel), niet precies op de hoek/rand: daar besliste een
			# afrondingsverschil welke cel je raakte (QA: muisklik op de spookhand gaf soms WRONG_MIN / klem)
			var off: Vector2 = {"diag": Vector2(-0.33, -0.33), "up": Vector2(0, -0.33), "left": Vector2(-0.33, 0)}.get(str(mv.dir), Vector2.ZERO)
			return c + off * cell
		"pick_end":
			end_sel = int(mv.j)
			return global_position + cell_center(a.length(), int(mv.j))
		"finish":
			# QA: knop 0 is "Nog een reeks"; "Klaar" is knop 1 (spookhand wees de verkeerde knop aan)
			return con.button_pos(1)
	return con.button_pos(0)


func hit_origin(f: Dictionary) -> Vector2:
	if approx:
		return tape.char_pos((int(f.start) + int(f.end)) / 2.0)
	return global_position + origin + Vector2(400, -40)


# ---------------------------------------------------------------- tekenen
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	var pp := Vector2(1180, size.y - 34) if approx else Vector2(120, 40)
	TxPal.brass_plate(self, pp, pl[0], 18, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, pp + Vector2(110, 0), pl[1], 24, TxPal.TEXT)
	var showcur := cc if phase in [P.FILL, P.TRACE] else Vector2i(-1, -1)
	TxDrawMachines.relay_grid(self, origin, a, b, vals, dirs, cell, path, warm, showcur, approx, flow)
	if phase == P.PICK_END:
		var hc := cell_center(a.length(), end_sel)
		draw_style_box(TxPal.sb(Color(0, 0, 0, 0), 9, 0, Vector2.ZERO, 3, TxPal.SIG_AMBER), Rect2(hc - Vector2(cell, cell) * 0.46, Vector2(cell, cell) * 0.92))
	var gx := origin.x + (b.length() + 1) * cell + 40
	if approx:
		var base := Vector2(gx + 80, 330)
		if spot_u > 0.0:
			TxDrawMachines.searchlight(self, base, spot_aim, spot_u, sin(t * 2.0) * 0.02)
		elif phase == P.PICK_END:
			TxDrawMachines.searchlight(self, base, cell_center(a.length(), end_sel), 0.35, sin(t * 1.5) * 0.08)
	else:
		# herstelstrook + teksten rechts van het bord
		var sx := maxf(gx, 760.0)
		TxDrawMachines.repair_strip(self, Vector2(sx, 120), word, word_ops, 40.0, "HERSTELSTROOK")
	# uitleg
	var tx := maxf(gx, 760.0) if not approx else 60.0
	var ty := 250.0 if not approx else size.y - 34.0
	var lines: Array = []
	match phase:
		P.FILL:
			lines = ["Relais (%d, %d): kies de ingang met het kleinste resultaat." % [cc.x, cc.y],
				"↖ + 0 bij groen lampje (gelijk), anders + 1 · ↑ + 1 (verwijder) · ← + 1 (voeg toe)"] if not auto_fill else ["De machine vult de tabel zelf (finale): kijk mee."]
		P.PICK_END:
			lines = ["Kleinste waarde in de onderste rij = einde van de beste match: zet daar het zoeklicht."]
		P.TRACE:
			lines = ["Loop terug langs draadjes die de waarde dragen (waarde = buur + kost)." + (" Tot rij 0." if approx else " Tot (0,0).")]
		P.TRACE_DONE:
			lines = ["Reeks geprint. Nog een andere kortste reeks (R) of klaar (Enter)?"]
	if approx:
		if not lines.is_empty():
			TxPal.text_l(self, TxPal.UI_BOLD, Vector2(tx, ty), str(lines[0]), 19, TxPal.TEXT)
	else:
		for l in lines:
			for ll in TxChef._wrap(str(l), 52).split("\n"):
				TxPal.text_l(self, TxPal.UI, Vector2(tx, ty), ll, 20, TxPal.TEXT)
				ty += 28
		ty += 10
		TxPal.text_l(self, TxPal.STENCIL, Vector2(tx, ty + 10), "GEVONDEN REEKSEN", 18, TxPal.BRASS)
		ty += 40
		for s in seqs_txt.slice(-5):
			for ll in TxChef._wrap(str(s), 60).split("\n"):
				TxPal.text_l(self, TxPal.TAPE_REG, Vector2(tx, ty), ll, 17, TxPal.TEXT)
				ty += 24
			ty += 6
	if approx and not seqs_txt.is_empty():
		var sy := 30.0
		TxPal.text_l(self, TxPal.STENCIL, Vector2(gx + 10, sy), "MATCHES", 16, TxPal.BRASS)
		for s in seqs_txt.slice(-4):
			sy += 26
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(gx + 10, sy), str(s).substr(0, 40), 15, TxPal.TEXT)
