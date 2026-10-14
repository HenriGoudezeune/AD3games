class_name TxDebrief
extends Control
## Debrief (GDD §6.5): stempel + sterren één voor één, tellers (jij / optimum / brute kracht), punten, lintverslag
## (✓ / ✗ / !), jouw tabel naast de juiste, misstappen-tijdlijn met herbeleving + coachzin + notasverwijzing,
## notas-weergave, extra's (debrief_extra, teaser, notas-volgorde, Oef. 32-grafiek, rivaal, Nachtdienst-highscore).
## Knoppen Volgende · Opnieuw · Kaart.

var con: Node
var dd: TxDirector
var rep: Dictionary
var spec: TxLevelSpec
var t := 0.0
var star_u: Array = [0.0, 0.0, 0.0]
var stamp_u := 0.0
var bars_u := 0.0
var dots: Array = []          # [{seq, kind: "ok"/"mis"/"bump"/"lost", x}]
var sel := -1
var replay: TxReplay
var _btns: Array = []
var _name_edit: LineEdit = null
var _hs_rank := 0
var _notes: Control = null

const L := Rect2(30, 30, 900, 1020)
const R := Rect2(950, 30, 940, 1020)


func setup(c: Node, r: Dictionary) -> void:
	con = c
	rep = r
	dd = c.dd
	spec = c.spec


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.72)
	_collect_dots()
	replay = TxReplay.new()
	replay.position = R.position + Vector2(20, 200)
	replay.size = Vector2(R.size.x - 40, 400)
	add_child(replay)
	var first_mis := -1
	for i in dots.size():
		if dots[i].kind in ["mis", "lost"]:
			first_mis = i
			break
	if first_mis >= 0:
		_select(first_mis)
	# animatie
	var tw := create_tween()
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		TxSnd.play("stamp", 0.0)
		TxFx.shake(3.0, 0.15))
	tw.tween_property(self, "stamp_u", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		var ii := i
		tw.tween_interval(0.25)
		tw.tween_callback(func():
			if bool(rep.stars[ii]):
				TxSnd.play("star_%d" % (ii + 1), -2.0)
				TxFx.ink(self, Vector2(L.position.x + 120 + ii * 70, L.position.y + 150), TxPal.BRASS, 8)
			else:
				TxSnd.play("tak_1", -10.0, 0.7))
		tw.tween_method(func(v: float): star_u[ii] = v, 0.0, 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): TxSnd.jingle(int(rep.n_stars)))
	tw.tween_property(self, "bars_u", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	TxSnd.duck(true)
	_buttons()
	if spec.endless:
		_highscore_ui()
	if TxSession.arg("debrief", "") == "auto":
		var tw2 := create_tween()
		tw2.tween_interval(6.0)
		tw2.tween_callback(func():
			if TxSession.has("quit_after_level"):
				get_tree().quit())


func _collect_dots() -> void:
	dots = []
	if dd == null:
		return
	for e in dd.log.entries:
		var ty := str(e.type)
		var v := int(e.verdict)
		var kind := ""
		if not bool(e.ok):
			kind = "bump"
		elif ty == "MISSED" or ty == "FALSE_ALARM" or v == TxCodes.Verdict.FALSE_ALARM:
			kind = "lost"
		elif bool(e.auto):
			continue
		elif v != TxCodes.Verdict.OK:
			kind = "mis"
		elif TxScoring.DECISIONS.has(ty):
			kind = "ok"
		else:
			continue
		dots.append({"seq": int(e.seq), "kind": kind})
	# hoogstens 60 stippen: groene samenvatten
	while dots.size() > 60:
		var removed := false
		for i in range(dots.size() - 1, -1, -1):
			if dots[i].kind == "ok" and i > 0 and dots[i - 1].kind == "ok":
				dots.remove_at(i)
				removed = true
				break
		if not removed:
			dots.resize(60)


func _select(i: int) -> void:
	if i < 0 or i >= dots.size():
		return
	sel = i
	var e := dd.log.entry(int(dots[i].seq))
	var coach := dd.log.coach_line(e)
	var ref := dd.log.notes_ref(e)
	if str(dots[i].kind) == "ok":
		coach = "Correct: %s." % str(e.type).to_lower()
	replay.show_entry(dd, e, coach, ref)
	TxSnd.play("rewind", -10.0, 1.4)


func _buttons() -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.position = Vector2(R.position.x + 30, R.end.y - 96)
	add_child(hb)
	var nxt := _next_id()
	if nxt != "" and int(rep.n_stars) > 0 and not spec.endless:
		var b := TxUi.button("Volgende dienst", "brass", 26, 280)
		b.pressed.connect(func():
			TxSession.level_id = nxt
			Transition.goto(TxSession.SCENE_CONSOLE))
		hb.add_child(b)
	var o := TxUi.button("Opnieuw", "key", 26, 200)
	o.pressed.connect(func(): con.restart())
	hb.add_child(o)
	var k := TxUi.button("Missiekaart", "key", 26, 220)
	k.pressed.connect(func(): con.to_map())
	hb.add_child(k)
	var nb := TxUi.button("Notas-weergave", "flat", 22, 0)
	nb.position = Vector2(R.end.x - 260, R.position.y + 24)
	nb.pressed.connect(_show_notes)
	add_child(nb)


func _next_id() -> String:
	if spec.endless:
		return ""
	var ids := TxLevels.ids()
	var i := ids.find(spec.id)
	for k in range(i + 1, ids.size()):
		var id := ids[k]
		if TxLevels.priority_of(id) == "P2":
			continue
		if TxSession.unlocked(id):
			return id
	return ""


func _show_notes() -> void:
	if _notes != null:
		return
	_notes = TxNotesView.new()
	_notes.setup(dd, rep)
	add_child(_notes)
	_notes.tree_exited.connect(func(): _notes = null)


func _highscore_ui() -> void:
	var score := int(rep.points)
	if not TxSave.is_highscore(score) or score <= 0:
		return
	_name_edit = LineEdit.new()
	_name_edit.max_length = 3
	_name_edit.placeholder_text = "ABC"
	_name_edit.position = Vector2(L.position.x + 560, L.position.y + 380)
	_name_edit.custom_minimum_size = Vector2(120, 50)
	_name_edit.add_theme_font_override("font", TxPal.TAPE)
	_name_edit.add_theme_font_size_override("font_size", 30)
	add_child(_name_edit)
	var b := TxUi.button("Bewaar", "brass", 22, 140)
	b.position = Vector2(L.position.x + 700, L.position.y + 376)
	b.pressed.connect(func():
		var nm := _name_edit.text.strip_edges()
		if nm == "":
			nm = "???"
		_hs_rank = TxSave.add_highscore(score, nm, Time.get_date_string_from_system())
		_name_edit.queue_free()
		_name_edit = null
		b.queue_free()
		TxSnd.play("stamp", 0.0))
	add_child(b)


func key(e: InputEventKey) -> bool:
	if _notes != null:
		if e.keycode == KEY_ESCAPE:
			_notes.queue_free()
		return true
	if _name_edit != null and _name_edit.has_focus():
		return false
	match e.keycode:
		KEY_LEFT:
			_step_sel(-1)
			return true
		KEY_RIGHT:
			_step_sel(1)
			return true
		KEY_ENTER, KEY_KP_ENTER:
			var nxt := _next_id()
			if nxt != "" and int(rep.n_stars) > 0:
				TxSession.level_id = nxt
				Transition.goto(TxSession.SCENE_CONSOLE)
			else:
				con.to_map()
			return true
		KEY_R:
			con.restart()
			return true
		KEY_ESCAPE:
			con.to_map()
			return true
		KEY_N:
			_show_notes()
			return true
	return false


func _step_sel(d: int) -> void:
	# spring tussen misstappen (amber/rood); anders gewoon de volgende stip
	var i := sel
	for _k in dots.size():
		i = (i + d + dots.size()) % dots.size()
		if dots[i].kind != "ok":
			_select(i)
			return
	if not dots.is_empty():
		_select((sel + d + dots.size()) % dots.size())


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = e.position
		# tijdlijn
		var tl := _timeline_rect()
		if tl.grow(14).has_point(p) and not dots.is_empty():
			var best := -1
			var bd := 1e9
			for i in dots.size():
				var dx := absf(_dot_x(i) - p.x)
				if dx < bd:
					bd = dx
					best = i
			if best >= 0 and bd < 20:
				_select(best)
		# lintverslag: klik op een ✗ of ! → oorzaak
		var lr := _tape_rect()
		if lr.grow(10).has_point(p):
			var info := _tape_info()
			var tt: String = info.t
			if tt != "":
				var cell := minf(28.0, lr.size.x / tt.length())
				var pos := int((p.x - lr.position.x) / cell)
				for x in rep.missed + rep.false_alarms:
					if pos >= int(x.start) and pos <= int(x.end):
						var cs := int(x.get("cause_seq", -1))
						for i in dots.size():
							if int(dots[i].seq) == cs:
								_select(i)
								return


func _timeline_rect() -> Rect2:
	return Rect2(R.position.x + 40, R.position.y + 140, R.size.x - 80, 30)


func _dot_x(i: int) -> float:
	var tl := _timeline_rect()
	if dots.size() <= 1:
		return tl.position.x
	return tl.position.x + tl.size.x * i / float(dots.size() - 1)


func _tape_rect() -> Rect2:
	return Rect2(L.position.x + 40, L.position.y + 640, L.size.x - 80, 60)


## Het lint van het verslag: de laatste stage met een lint.
func _tape_info() -> Dictionary:
	if dd == null:
		return {"t": ""}
	for i in range(dd.machines.size() - 1, -1, -1):
		var mc := dd.machines[i]
		if mc.t != "" and not (mc is TxSabotage) and not (mc is TxRabinKarp and (mc as TxRabinKarp).signal_mode()):
			return {"t": mc.t, "stage": mc.stage_index}
	return {"t": ""}


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


# ================================================================ tekenen
func _draw() -> void:
	_draw_left()
	_draw_right()


func _draw_left() -> void:
	var r := L
	draw_rect(Rect2(r.position + Vector2(8, 12), r.size), TxPal.SHADOW)
	draw_texture_rect(TxPal.tex("tex/paper_tile.png"), r, true, Color(TxPal.MANILA.r * 1.22, TxPal.MANILA.g * 1.2, TxPal.MANILA.b * 1.12))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 64)), Color(TxPal.MANILA_LO, 0.55))
	var head := "DEBRIEF  ·  " + ("NACHTDIENST" if spec.endless else "%s  %s" % [spec.id, spec.title.to_upper()])
	TxPal.text_l(self, TxPal.STENCIL, r.position + Vector2(30, 34), head.substr(0, 46), 26, TxPal.INK)
	var x0 := r.position.x + 40
	# stempel
	var ok := bool(rep.get("completed", false)) and int(rep.n_stars) > 0
	if spec.endless:
		ok = true
	var sname := "missie_geslaagd" if ok and (rep.missed as Array).is_empty() else ("missie_geslaagd" if ok else "codewoord_ontsnapt")
	if not (rep.missed as Array).is_empty() and not spec.endless:
		sname = "codewoord_ontsnapt" if int(rep.n_stars) == 0 else "missie_geslaagd"
	var ss := lerpf(2.2, 0.75, stamp_u)
	if stamp_u > 0.01:
		TxDraw.stamp(self, sname, r.position + Vector2(660, 150), TxPal.STAMP_RED if sname != "missie_geslaagd" else TxPal.STAMP_BLUE, ss, -0.12, 0.85 * stamp_u)
	# sterren met voorwaarden
	for i in 3:
		var c := Vector2(x0 + 80 + i * 70, r.position.y + 130)
		var u: float = star_u[i]
		var got := bool(rep.stars[i])
		if u > 0.0:
			var sc := lerpf(1.8, 1.0, u)
			TxDraw.star(self, c, 26 * sc, TxPal.BRASS if got else Color(0, 0, 0, 0), TxPal.BRASS_LO if got else TxPal.PENCIL)
		else:
			TxDraw.star(self, c, 26, Color(0, 0, 0, 0), Color(TxPal.PENCIL, 0.4))
	var labels: Array = rep.get("star_labels", [])
	for i in labels.size():
		var got2 := bool(rep.stars[i])
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, r.position.y + 190 + i * 30), "%s  %s" % ["★".repeat(i + 1), str(labels[i])], 19,
				TxPal.INK if got2 else Color(TxPal.PENCIL, 0.8))
	# tellers
	var y := r.position.y + 300
	var c2: Dictionary = rep.get("counters", {})
	var opt: Dictionary = rep.get("optimum", {})
	var unit := "ticks"
	var uname := "TIKKEN"
	if int(c2.get("lamps", 0)) > 0:
		unit = "lamps"
		uname = "LAMPSLAGEN"
	elif int(c2.get("relays", 0)) > 0:
		unit = "relays"
		uname = "RELAIS"
	elif int(c2.get("wheel", 0)) > 0:
		unit = "wheel"
		uname = "WIELSLAGEN"
	var brute := int(rep.get("ghost", {}).get("brute_ticks", 0))
	if spec.endless:
		_draw_endless(Vector2(x0, y))
	elif not (rep.sabotage as Array).is_empty():
		_draw_sabotage(Vector2(x0, y))
	else:
		TxPal.text_l(self, TxPal.STENCIL, Vector2(x0, y), uname, 20, TxPal.INK)
		var mine := int(c2.get(unit, 0))
		var o := int(opt.get(unit, mine))
		var vmax := maxi(maxi(mine, o), maxi(brute, 1))
		var bw := 420.0
		TxDraw.tally_bar(self, Vector2(x0, y + 22), bw * bars_u, "jij", mine, vmax, TxPal.STAMP_BLUE)
		TxDraw.tally_bar(self, Vector2(x0, y + 56), bw * bars_u, "optimum", o, vmax, TxPal.SIG_EQ.darkened(0.3))
		if brute > 0:
			TxDraw.tally_bar(self, Vector2(x0, y + 90), bw * bars_u, "brute kracht", brute, vmax, TxPal.SIG_GREY)
		if unit != "ticks" and brute > 0:
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, y + 132), "brute kracht zou %d tikken nodig hebben (tikken: %d)" % [brute, int(c2.get("ticks", 0))], 17, TxPal.INK_SOFT)
		if spec.id == "F":
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, y + 132), "machinetijd van de doorlopen: %d (best 118)" % int(rep.get("machine_time", 0)), 18, TxPal.INK)
	# punten
	var py := r.position.y + 470
	TxPal.text_l(self, TxPal.STENCIL, Vector2(x0, py), "PUNTEN  %d" % int(rep.points), 20, TxPal.INK)
	var k := 0
	for b in rep.get("breakdown", []):
		var col := TxPal.INK if int(b.amount) >= 0 else TxPal.STAMP_RED
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0 + (k % 2) * 420, py + 30 + (k / 2) * 26), "%s  %+d" % [str(b.label), int(b.amount)], 18, col)
		k += 1
	var best := TxSave.get_best(spec.id) if not spec.endless else 0
	if best > 0:
		TxPal.text_r(self, TxPal.TAPE_REG, Vector2(r.end.x - 40, py), "beste: %d" % best, 18, TxPal.INK_SOFT)
	# lintverslag
	var info := _tape_info()
	var tt: String = info.t
	var ly := r.position.y + 610
	TxPal.text_l(self, TxPal.STENCIL, Vector2(x0, ly), "LINTVERSLAG", 20, TxPal.INK)
	if tt != "":
		var lr := _tape_rect()
		var cell := minf(28.0, lr.size.x / tt.length())
		var hb: Array = []
		var ms: Array = []
		var fa: Array = []
		for h in rep.hits:
			if bool(h.real) and int(h.stage) == int(info.stage):
				hb.append([int(h.start), int(h.end)])
		for x in rep.missed:
			if int(x.stage) == int(info.stage):
				ms.append([int(x.start), int(x.end)])
		for x in rep.false_alarms:
			if int(x.stage) == int(info.stage) and int(x.start) >= 0:
				fa.append([int(x.start), int(x.end)])
		draw_set_transform(lr.position, 0.0, Vector2(1.0, 0.56))
		TxDraw.tape(self, 0, 0, tt, 0, tt.length(), cell, {"hits": hb, "missed": ms, "false": fa, "size": int(cell * 0.85)})
		draw_set_transform(Vector2.ZERO)
		var sy := lr.end.y + 22
		var sx := x0
		for h2 in hb:
			sx += TxPal.text_l(self, TxPal.TAPE, Vector2(sx, sy), "✓ %s @%d   " % [tt.substr(int(h2[0]), int(h2[1]) - int(h2[0]) + 1), int(h2[0])], 17, TxPal.STAMP_BLUE)
		for x2 in ms:
			sx += TxPal.text_l(self, TxPal.TAPE, Vector2(sx, sy), "✗ @%d   " % int(x2[0]), 17, TxPal.STAMP_RED)
		for x3 in fa:
			sx += TxPal.text_l(self, TxPal.TAPE, Vector2(sx, sy), "! @%d   " % int(x3[0]), 17, TxPal.PENCIL)
		if not ms.is_empty() or not fa.is_empty():
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, sy + 28), "klik een ✗ of ! op het lint: de oorzaak verschijnt rechts", 15, TxPal.INK_SOFT)
	# extra's
	var ey := r.position.y + 790
	var extra := str(spec.story.get("debrief_extra", ""))
	if extra != "":
		for l in TxChef._wrap(extra, 72).split("\n"):
			TxPal.text_l(self, TxPal.TAPE, Vector2(x0, ey), l, 19, TxPal.INK)
			ey += 26
	if spec.story.has("notes_order"):
		ey += 6
		for l in TxChef._wrap(str(spec.story.notes_order), 72).split("\n"):
			TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, ey), l, 17, TxPal.INK_SOFT)
			ey += 23
	if not (rep.get("rival", {}) as Dictionary).is_empty():
		var rv: Dictionary = rep.rival
		TxPal.text_l(self, TxPal.TAPE, Vector2(x0, ey + 4), "Rivaal (brute kracht, B = 4): %d scheuren, %d treffers. Zij moet terug, jij niet." % [int(rv.tears), (rv.hits as Array).size()], 17, TxPal.STAMP_RED)
		ey += 28
	if spec.story.has("teaser") and int(rep.n_stars) > 0:
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, ey + 6), str(spec.story.teaser), 18, TxPal.STAMP_BLUE)
	if spec.id == "F" and bool(rep.get("completed", false)):
		TxPal.text_l(self, TxPal.TAPE, Vector2(x0, r.end.y - 40), "Chef Ponsaert: “%s”" % str(spec.story.get("outro", "")), 22, TxPal.STAMP_BLUE)


func _draw_sabotage(p: Vector2) -> void:
	TxPal.text_l(self, TxPal.STENCIL, p, "TEGENZET", 20, TxPal.INK)
	var y := p.y + 30
	for sb in rep.sabotage:
		var best := int(sb.best)
		var opt := int(sb.optimum)
		TxPal.text_l(self, TxPal.TAPE, Vector2(p.x, y), "z = %s   t = %s" % [str(sb.z), str(sb.t)], 17, TxPal.INK)
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(p.x, y + 24), "beste: %d   optimum: %d  %s" % [best, opt, "✓" if best == opt else ""], 18, TxPal.STAMP_BLUE if best == opt else TxPal.INK)
		y += 58
	if str(spec.story.get("graph", "")) == "brute_family":
		_draw_graph(Rect2(p.x + 470, p.y - 10, 360, 150))


## Oef. 32: tikken vs n voor z = a^(m−1)b, t = a^n met m = n/2 → (n/2 + 1)·n/2 (parabool) + jouw stempels.
func _draw_graph(r: Rect2) -> void:
	draw_rect(r, Color(TxPal.CARD, 0.7))
	draw_rect(r, Color(TxPal.INK, 0.4), false, 1.0)
	var pts := PackedVector2Array()
	var maxv := (32 / 2 + 1) * 32 / 2
	for n in range(4, 33, 2):
		var v := (n / 2 + 1) * (n / 2)
		pts.append(Vector2(r.position.x + 10 + (n - 4) / 28.0 * (r.size.x - 20), r.end.y - 10 - float(v) / maxv * (r.size.y - 30)))
	draw_polyline(pts, TxPal.STAMP_BLUE, 2.5, true)
	for pnt in pts:
		draw_circle(pnt, 2.5, TxPal.STAMP_BLUE)
	TxPal.text_l(self, TxPal.TAPE_REG, r.position + Vector2(8, 12), "tikken vs n  (m = n/2): Θ(n²)", 14, TxPal.INK)
	for sb in rep.sabotage:
		var n2 := str(sb.t).length()
		var v2 := int(sb.best)
		var q := Vector2(r.position.x + 10 + (n2 - 4) / 28.0 * (r.size.x - 20), r.end.y - 10 - float(v2) / maxv * (r.size.y - 30))
		TxDraw.star(self, q, 9, TxPal.STAMP_RED, TxPal.STAMP_RED)


func _draw_endless(p: Vector2) -> void:
	TxPal.text_l(self, TxPal.STENCIL, p, "NACHTDIENST", 20, TxPal.INK)
	var y := p.y + 30
	for tp in (rep.get("tapes", []) as Array).slice(-5):
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(p.x, y), "lint %d · %s · gevonden %d · gemist %d · %d tikken (brute %d)" % [int(tp.index) + 1, str(tp.z), int(tp.found), int(tp.missed), int(tp.ticks), int(tp.brute)], 16, TxPal.INK)
		y += 22
	var hs := TxSave.highscores()
	var hx := p.x + 520
	TxPal.text_l(self, TxPal.STENCIL, Vector2(hx, p.y - 0), "TOP-10", 18, TxPal.INK)
	for i in mini(5, hs.size()):
		TxPal.text_l(self, TxPal.TAPE, Vector2(hx, p.y + 30 + i * 22), "%d. %s  %d" % [i + 1, str(hs[i].name), int(hs[i].score)], 16, TxPal.STAMP_BLUE if i + 1 == _hs_rank else TxPal.INK)
	if _name_edit != null:
		TxPal.text_l(self, TxPal.TAPE, Vector2(hx - 0, p.y + 66 + 5 * 22), "Nieuwe highscore! Initialen:", 18, TxPal.STAMP_RED)


func _draw_right() -> void:
	var r := R
	TxPal.panel(self, r, TxPal.CONSOLE, true, 14)
	TxPal.text_l(self, TxPal.STENCIL, r.position + Vector2(30, 46), "MISSTAPPEN", 24, TxPal.BRASS)
	var nm := 0
	for dt in dots:
		if dt.kind in ["mis", "lost"]:
			nm += 1
	TxPal.text_l(self, TxPal.UI, r.position + Vector2(30, 92), "%d misstap(pen) · %d klemmen · %d hints · %d keer terug" % [(rep.mistakes as Array).size(), int(rep.bumps), int(rep.hints), int(rep.undos)], 19, TxPal.TEXT_DIM)
	var tl := _timeline_rect()
	draw_line(Vector2(tl.position.x, tl.get_center().y), Vector2(tl.end.x, tl.get_center().y), Color(TxPal.TEXT_DIM, 0.4), 2.0)
	for i in dots.size():
		var c := Vector2(_dot_x(i), tl.get_center().y)
		var col := TxPal.SIG_EQ
		match str(dots[i].kind):
			"mis":
				col = TxPal.SIG_AMBER
			"bump":
				col = TxPal.SIG_GREY
			"lost":
				col = TxPal.SIG_NE
		var rad := 7.0 if dots[i].kind == "ok" else 10.0
		if i == sel:
			draw_circle(c, rad + 5 + sin(t * 6.0) * 1.5, Color(col, 0.35))
		draw_circle(c, rad, col)
	TxPal.text_l(self, TxPal.UI, Vector2(tl.position.x, tl.end.y + 20), "● groen = juist · amber = misstap · grijs = klem · rood = gevolg   (← → om te kiezen)", 16, TxPal.TEXT_DIM)
	# tabel naast de juiste
	_draw_tables(Rect2(r.position.x + 20, r.position.y + 620, r.size.x - 40, 290))


func _draw_tables(r: Rect2) -> void:
	TxPal.text_l(self, TxPal.STENCIL, r.position + Vector2(10, 12), "JOUW TABEL  ·  DE JUISTE", 20, TxPal.BRASS)
	var y := r.position.y + 50
	var shown := 0
	for tb in rep.get("tables", []):
		if shown >= 2:
			break
		shown += 1
		match str(tb.kind):
			"strip":
				y = _row_vals(r.position.x + 10, y, "V (jij)", tb.yours, tb.correct)
				y = _row_vals(r.position.x + 10, y, "V (notas)", tb.correct.slice(0, (tb.yours as Array).size()), tb.correct.slice(0, (tb.yours as Array).size()))
			"cards":
				var ky: Array = (tb.correct as Dictionary).keys()
				ky.sort()
				var a1: Array = []
				var a2: Array = []
				var hdr := ""
				for kx in ky:
					a1.append(int((tb.yours as Dictionary).get(kx, int(tb.other))))
					a2.append(int(tb.correct[kx]))
					hdr += str(kx) + "  "
				TxPal.text_l(self, TxPal.TAPE_REG, Vector2(r.position.x + 150, y), "x = " + hdr + " overige = %d" % int(tb.other), 17, TxPal.TEXT_DIM)
				y += 26
				y = _row_vals(r.position.x + 10, y, "V_H jij", a1, a2)
				y = _row_vals(r.position.x + 10, y, "V_H notas", a2, a2)
			"c":
				var ks: Array = (tb.correct as Dictionary).keys()
				ks.sort()
				var line1 := ""
				var line2 := ""
				var bad := false
				for kx in ks:
					var yv := _bits(tb.yours.get(kx, []))
					var cv := _bits(tb.correct[kx])
					line1 += "C_%s=%s  " % [kx, yv]
					line2 += "C_%s=%s  " % [kx, cv]
					if yv != cv:
						bad = true
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y), "jij:   " + line1, 18, TxPal.SIG_AMBER if bad else TxPal.TEXT)
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y + 28), "notas: " + line2, 18, TxPal.SIG_EQ)
				y += 60
				if not (tb.get("wiring", {}) as Dictionary).is_empty():
					var w := str((tb.wiring as Dictionary).values())
					TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y), "foutkabel: %s   (juist: old_shift = oud ↓)" % w, 17, TxPal.TEXT)
					y += 28
			"wheel":
				var rows: Array = tb.yours
				var s1 := "jij:   "
				var s2 := "juist: "
				var bad2 := false
				for rw in rows.slice(0, 16):
					s1 += "%2d " % int(rw.yours)
					s2 += "%2d " % int(rw.correct)
					if int(rw.yours) != int(rw.correct):
						bad2 = true
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y), "w = %d (juist %d) · h(z) = %d (juist %d)" % [int(tb.w[0]), int(tb.w[1]), int(tb.hz[0]), int(tb.hz[1])], 17, TxPal.TEXT)
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y + 28), s1, 17, TxPal.SIG_AMBER if bad2 else TxPal.TEXT)
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y + 54), s2, 17, TxPal.SIG_EQ)
				y += 86
			"table":
				var yours: Array = tb.yours
				var corr: Array = tb.correct
				var diff := 0
				for i in yours.size():
					for j in (yours[i] as Array).size():
						if int(yours[i][j]) >= 0 and int(yours[i][j]) != int(corr[i][j]):
							diff += 1
				TxPal.text_l(self, TxPal.TAPE, Vector2(r.position.x + 10, y), "%d × %d relais · %d cel(len) wijken af van de notas" % [yours.size(), (yours[0] as Array).size(), diff], 18, TxPal.SIG_AMBER if diff > 0 else TxPal.SIG_EQ)
				y += 30
				var eb := dd.last_machine_of(TxEditBoard) as TxEditBoard
				if eb != null:
					for sq in eb.distinct_sequences().slice(0, 3):
						var ops: Array = sq if sq is Array else sq.get("ops", [])
						var parts := PackedStringArray()
						for o in ops:
							match str(o.op):
								"vervang":
									parts.append("vervang %s op %d door %s" % [str(o.from), int(o.pos), str(o.to)])
								"verwijder":
									parts.append("verwijder %s op %d" % [str(o.from), int(o.pos)])
								"voegtoe":
									parts.append("voeg %s toe op %d" % [str(o.to), int(o.pos)])
						var pre := "@%d: " % int(sq.start) if sq is Dictionary else ""
						TxPal.text_l(self, TxPal.TAPE_REG, Vector2(r.position.x + 10, y), pre + " · ".join(parts), 16, TxPal.TEXT)
						y += 24
	if shown == 0:
		TxPal.text_l(self, TxPal.UI, Vector2(r.position.x + 10, y), "Geen tabel in dit level.", 18, TxPal.TEXT_DIM)


static func _bits(a) -> String:
	var s := ""
	for b in a:
		s += str(int(b))
	return s


func _row_vals(x: float, y: float, label: String, vals: Array, correct: Array) -> float:
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y + 14), label, 17, TxPal.TEXT_DIM)
	for j in vals.size():
		var v := int(vals[j])
		var c := int(correct[j]) if j < correct.size() else v
		var cr := Rect2(x + 140 + j * 44, y, 40, 30)
		draw_rect(cr, TxPal.MANILA)
		var txt := "·" if v == TxCodes.STRIP_EMPTY else ("▓" if v == TxCodes.STRIP_BURNT else str(v))
		TxPal.text_c(self, TxPal.TAPE, cr.get_center(), txt, 20, TxPal.INK)
		if v != c and v != TxCodes.STRIP_BURNT:
			draw_arc(cr.get_center(), 21, 0, TAU, 24, TxPal.STAMP_RED, 2.5, true)
	return y + 40
