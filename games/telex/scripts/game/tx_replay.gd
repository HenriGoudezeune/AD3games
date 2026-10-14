class_name TxReplay
extends Control
## Herbeleving van één misstap in de debrief (GDD §6.5 punt 5): de console van dat moment wordt herbouwd in een
## tweede, alleen-lezen machine (restore(entry.before)). Eerst jouw zet in rood-transparant, daarna de juiste zet als
## groene spookhand, met de coachzin en de notasverwijzing.

var rm: TxMachine = null            # herbouwde machine
var entry: Dictionary = {}
var yours: Dictionary = {}
var right: Dictionary = {}
var coach := ""
var ref := ""
var title := ""
var t := 0.0
var cell := 34.0
var _ok := false


func show_entry(dd: TxDirector, e: Dictionary, coach_line: String, ref_line: String) -> void:
	entry = e
	coach = coach_line
	ref = ref_line
	t = 0.0
	_ok = false
	rm = null
	var src := e
	var d: Dictionary = e.get("data", {})
	if str(e.get("type", "")) in ["MISSED", "FALSE_ALARM"] and int(d.get("cause_seq", -1)) >= 0:
		var c := dd.log.entry(int(d.cause_seq))
		if not c.is_empty() and not (c.get("before", {}) as Dictionary).is_empty():
			src = c
	yours = (src.get("data", {}) as Dictionary).get("move", {})
	right = src.get("hint", {})
	title = TxCodes.verdict_name(int(e.get("verdict", 0)))
	var before: Dictionary = src.get("before", {})
	var mch := dd.machine_at(int(src.get("stage", 0)))
	if mch != null and not before.is_empty():
		rm = TxLevels.make_machine(mch.stage, mch.carry_in, TxCodes.Mode.CALM)
		rm.restore(before)
		_ok = true
	queue_redraw()


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.well(self, r, TxPal.CONSOLE_LO, 10)
	if entry.is_empty():
		TxPal.text_c(self, TxPal.UI, r.get_center(), "Geen misstappen. Klik een stip om een moment te herbeleven.", 22, TxPal.TEXT_DIM)
		return
	var phase_u := fmod(t, 4.0)
	var show_right := phase_u > 2.0
	TxPal.text_l(self, TxPal.STENCIL, Vector2(20, 24), "HERBELEVING", 18, TxPal.BRASS)
	TxPal.text_r(self, TxPal.UI_BOLD, Vector2(r.size.x - 20, 24), ("JUISTE ZET" if show_right else "JOUW ZET"), 20,
			TxPal.SIG_EQ if show_right else TxPal.SIG_NE)
	if _ok and rm != null:
		_draw_machine(show_right)
	# coachzin + verwijzing
	var cr := Rect2(20, r.size.y - 112, r.size.x - 40, 96)
	draw_rect(cr, TxPal.CARD)
	draw_rect(Rect2(cr.position, Vector2(6, cr.size.y)), TxPal.STAMP_RED)
	var lines := TxChef._wrap(coach, 70).split("\n")
	var y := cr.position.y + 26
	for l in lines.slice(0, 2):
		TxPal.text_l(self, TxPal.TAPE, Vector2(cr.position.x + 22, y), l, 20, TxPal.INK)
		y += 26
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(cr.position.x + 22, cr.end.y - 18), "→ " + ref, 17, TxPal.STAMP_RED)


func _mv_text(mv: Dictionary) -> String:
	var act := str(mv.get("act", "?"))
	match act:
		"shift":
			return "verschuif %d" % int(mv.s)
		"strip":
			return "strook"
		"jump":
			return "spring %d" % int(mv.s)
		"key":
			return "sleutel t[%d]" % int(mv.pos)
		"punch":
			return "pons V[%d] = %d" % [int(mv.j), int(mv.v)]
		"punch_to":
			return "pons tot %d met %d" % [int(mv.to), int(mv.v)]
		"done", "cards_done", "wire_done":
			return "klaar"
		"stamp":
			return "stempel %d" % int(mv.i)
		"wheel":
			return {"double": "×2", "minus_w": "−w", "plus1": "+1"}.get(str(mv.op), "wiel")
		"slide":
			return "schuif"
		"next_bit":
			return "volgend bit"
		"commit":
			return "gewicht vastzetten"
		"verify":
			return "controleer"
		"report":
			return "meld meteen"
		"ignore":
			return "negeer"
		"lever":
			return "hendel"
		"card":
			return "kaart %s" % (str(mv.x) if str(mv.x) != "" else "blanco")
		"plug":
			return "kabel in %s" % str(mv.src)
		"fill":
			return {"diag": "ingang ↖", "up": "ingang ↑", "left": "ingang ←"}.get(str(mv.dir), "?")
		"pick_end":
			return "einde kolom %d" % int(mv.j)
		"choose":
			return "ploeg naar @%d" % int(mv.start)
		"step":
			return "terug %s" % str(mv.dir)
	return act


func _draw_machine(show_right: bool) -> void:
	var mv := right if show_right else yours
	var col := TxPal.SIG_EQ if show_right else TxPal.SIG_NE
	var label := _mv_text(mv)
	TxPal.text_l(self, TxPal.UI_BOLD, Vector2(20, 60), ("juist: " if show_right else "jij: ") + label, 24, col)
	if not show_right and not right.is_empty():
		TxPal.text_l(self, TxPal.UI, Vector2(360, 60), "(juist: %s)" % _mv_text(right), 20, TxPal.TEXT_DIM)
	var c := rm.cursor()
	var area := Rect2(20, 90, size.x - 40, size.y - 220)
	if rm is TxBmh and rm.t == "":
		var bm := rm as TxBmh
		var keys: Array = bm.vh.keys()
		keys.sort()
		var x := area.position.x + 10
		TxPal.text_l(self, TxPal.TAPE, Vector2(x, area.position.y + 30), "z = %s   (stempel 0..m−2 van links naar rechts)" % bm.z, 22, TxPal.TEXT)
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, area.position.y + 80), "jouw kaarten:", 20, TxPal.TEXT_DIM)
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, area.position.y + 130), "volgens vul_VH:", 20, TxPal.TEXT_DIM)
		for i in keys.size():
			var kx: String = keys[i]
			var yours := bm.card_value(kx)
			var good := int(bm.vh[kx])
			var cx := x + 220 + i * 90
			TxPal.text_c(self, TxPal.TAPE, Vector2(cx, area.position.y + 80), "%s=%d" % [kx, yours], 22, TxPal.SIG_NE if yours != good else TxPal.TEXT)
			TxPal.text_c(self, TxPal.TAPE, Vector2(cx, area.position.y + 130), "%s=%d" % [kx, good], 22, TxPal.SIG_EQ)
	elif rm is TxKmp or rm is TxBrute or rm is TxBmh:
		_draw_tape_state(area, c, mv, col)
	elif rm is TxKmpTable:
		_draw_strip_state(area, c, mv, col)
	elif rm is TxRabinKarp:
		var rk := rm as TxRabinKarp
		TxDrawMachines.wheel(self, Vector2(area.position.x + 130, area.get_center().y + 10), 95, rk.q, float(rk.wheel), rk.hz, 0.0)
		TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 270, area.position.y + 40), "wiel = %d   (q = %d, w = %d)" % [rk.wheel, rk.q, rk.w], 22, TxPal.TEXT)
		var tg := rk.step_target()
		if tg >= 0:
			TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 270, area.position.y + 80), "de stap moest uitkomen op %d" % tg, 22, TxPal.SIG_EQ)
		if rk.phase == TxCodes.Phase.ROLL:
			TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 270, area.position.y + 120), "uit = %s, in = %s" % [str(rk.out_bit()), str(rk.in_bit())], 22, TxPal.TEXT_DIM)
	elif rm is TxShiftAnd:
		var sa := rm as TxShiftAnd
		var cols: Array = sa.shown_cols()
		for l in cols.size():
			var bits := ""
			for b in cols[l]:
				bits += str(int(b))
			TxDrawMachines.lamp_column(self, area.position.x + 160 + l * 170, area.position.y + 50, sa.z, bits, minf(46.0, 150.0 / maxf(1, sa.m)), TxPal.LEVEL_COLORS[mini(l, 2)], 0.0, 0.0, l == 0)
		TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 520, area.position.y + 40), "j = %d, t[j] = %s" % [sa.j, sa.t[sa.j] if sa.j < sa.n else "–"], 22, TxPal.TEXT)
		TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 520, area.position.y + 80), "hendel: %s" % ("getrokken" if sa.lever_pulled else "nog niet"), 22, TxPal.TEXT_DIM)
	elif rm is TxEditBoard:
		var eb := rm as TxEditBoard
		var i := int(c.i)
		var j := int(c.j)
		TxPal.text_l(self, TxPal.TAPE, Vector2(area.position.x + 10, area.position.y + 40), "cel (%d, %d)" % [i, j], 24, TxPal.TEXT)
		if i >= 1 and j >= 1 and i < eb.tab.size():
			var dg := int(eb.tab[i - 1][j - 1])
			var up := int(eb.tab[i - 1][j])
			var lf := int(eb.tab[i][j - 1])
			var cst := eb.cost("diag", i, j)
			var o := area.position + Vector2(260, 30)
			for k in 4:
				var rr := Rect2(o + Vector2((k % 2) * 90, (k / 2) * 90), Vector2(80, 80))
				draw_style_box(TxPal.sb(TxPal.BAKELITE, 8), rr)
			TxPal.text_c(self, TxPal.MONO, o + Vector2(40, 40), str(dg), 30, TxPal.TEXT)
			TxPal.text_c(self, TxPal.MONO, o + Vector2(130, 40), str(up), 30, TxPal.TEXT)
			TxPal.text_c(self, TxPal.MONO, o + Vector2(40, 130), str(lf), 30, TxPal.TEXT)
			TxPal.text_c(self, TxPal.MONO, o + Vector2(130, 130), "?", 30, col)
			TxPal.text_l(self, TxPal.TAPE, o + Vector2(220, 40), "↖ %d + %d = %d" % [dg, cst, dg + cst], 22, TxPal.TEXT)
			TxPal.text_l(self, TxPal.TAPE, o + Vector2(220, 80), "↑ %d + 1 = %d" % [up, up + 1], 22, TxPal.TEXT)
			TxPal.text_l(self, TxPal.TAPE, o + Vector2(220, 120), "← %d + 1 = %d" % [lf, lf + 1], 22, TxPal.TEXT)
	else:
		TxPal.text_l(self, TxPal.UI, area.position + Vector2(10, 40), "fase: %s" % TxCodes.phase_name(rm.phase), 20, TxPal.TEXT_DIM)


func _draw_tape_state(area: Rect2, c: Dictionary, mv: Dictionary, col: Color) -> void:
	var tt := rm.t
	if tt == "":
		return
	var start := int(c.get("start", 0))
	var first := clampi(start - 4, 0, maxi(0, tt.length() - 24))
	var count := mini(26, tt.length() - first)
	var x0 := area.position.x + 10
	var y := area.position.y + 4
	var states := {}
	if rm is TxKmp:
		var ok: Array = c.get("window_ok", [])
		for q in ok.size():
			if ok[q]:
				states[start + q] = "eq"
		if int(c.get("em", -1)) >= 0 and int(c.em) < rm.m:
			states[start + int(c.em)] = "ne"
	TxDraw.tape(self, x0, y, tt, first, count, cell, {"states": states, "size": 30})
	TxDraw.tape_positions(self, x0, y + 108, first, count, cell, tt.length(), int(c.get("head", -1)))
	var base_x := x0 + (start - first) * cell
	TxDraw.stencil(self, base_x, y + 140, rm.z, cell, {}, -1, false, 30)
	var s := 0
	match str(mv.get("act", "")):
		"shift", "jump":
			s = int(mv.get("s", 0))
		"key":
			if rm is TxBmh:
				s = (rm as TxBmh).card_value(tt[int(mv.pos)])
				var kx := x0 + (int(mv.pos) - first + 0.5) * cell
				draw_arc(Vector2(kx, y + 66), cell * 0.55, 0, TAU, 30, col, 3.0, true)
		"strip":
			if rm is TxKmp:
				s = (rm as TxKmp).strip_cell(int(c.get("em", 0)))
		"next":
			s = 1
	if s > 0:
		var gx := x0 + (start + s - first) * cell
		var a := 0.55 + 0.25 * sin(t * 6.0)
		draw_style_box(TxPal.sb(Color(col, 0.18 * a), 9), Rect2(gx - 10, y + 140, rm.m * cell + 20, 80))
		draw_style_box(TxPal.sb(Color(0, 0, 0, 0), 9, 0, Vector2.ZERO, 3, Color(col, a)), Rect2(gx - 10, y + 140, rm.m * cell + 20, 80))
		for i in rm.m:
			TxPal.text_c(self, TxPal.TAPE, Vector2(gx + (i + 0.5) * cell, y + 190), rm.z[i], 30, Color(col, 0.9))
		TxPal.text_l(self, TxPal.UI_BOLD, Vector2(gx + rm.m * cell + 18, y + 180), "+%d" % s, 22, col)


func _draw_strip_state(area: Rect2, c: Dictionary, mv: Dictionary, col: Color) -> void:
	var strip: Array = c.get("strip", [])
	var vals: Array = []
	for v in strip:
		vals.append(null if int(v) < 0 else int(v))
	var x0 := area.position.x + 70
	TxDraw.tape(self, x0, area.position.y + 4, rm.z + "⏎", 0, rm.m + 1, 40.0, {"size": 32})
	TxDraw.strip(self, x0, area.position.y + 150, vals, 40.0, false, -1)
	var act := str(mv.get("act", ""))
	if act == "punch":
		var j := int(mv.j)
		TxPal.text_c(self, TxPal.TAPE, Vector2(x0 + (j + 0.5) * 40, area.position.y + 222), str(int(mv.v)), 28, col)
	elif act == "punch_to":
		for q in range(int(c.get("punch_from", 0)), int(mv.to) + 1):
			TxPal.text_c(self, TxPal.TAPE, Vector2(x0 + (q + 0.5) * 40, area.position.y + 222), str(int(mv.v)), 28, col)
	elif act == "shift":
		TxPal.text_l(self, TxPal.UI_BOLD, Vector2(x0, area.position.y + 250), "verschuif %d (start %d)" % [int(mv.s), int(c.get("start", 0))], 22, col)
