class_name ScReview
extends Control
## Het Kapittel (terugblik, GDD §6.5): lakzegels (sterren) met hun voorwaarde, Kelners kasboek (jouw inkt, optimum,
## gewoon schrift, vaste lengte) met de punten, origineel en voorlezing met klikbare inktvlekken (oorzakenketen), de
## misstappen-tijdlijn met herbeleving (een tweede, alleen-lezen werktuig: jouw zet bruin-transparant, daarna de
## juiste als gouden inkthand) + coachzin + notasverwijzing + "Herneem vanaf hier", en de notas-weergave.

signal action(a: String, arg)

const PAPER := Rect2(36, 26, 1848, 1028)
const REPLAY := Rect2(980, 236, 860, 470)

var rep: Dictionary
var spec: ScLevelSpec
var director: ScDirector
var t := 0.0
var _n: Node2D
var _fx: Node2D
var _press := [0.0, 0.0, 0.0]
var _dots: Array = []           # [{e, r:Rect2, kind}]
var _blots: Array = []          # [{pos, r}]
var _sel := -1
var _replay_clip: Control
var _replay_view: ScView
var _replay_tool: ScTool
var _replay_stage := -1
var _replay_phase := ""
var _coach := ""
var _ref := ""
var _resume_btn: Button
var _notes: ScNotesView
var _btns: HBoxContainer
var _hover_dot := -1
var _token := 0


func setup(r: Dictionary, s: ScLevelSpec, d: ScDirector) -> void:
	rep = r
	spec = s
	director = d


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.7)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	_replay_clip = Control.new()
	_replay_clip.position = REPLAY.position
	_replay_clip.size = REPLAY.size
	_replay_clip.clip_contents = true
	_replay_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_replay_clip)
	var top := Node2D.new()
	top.draw.connect(_paint_top.bind(top))
	top.set_meta("top", true)
	add_child(top)
	_fx = Node2D.new()
	add_child(_fx)
	_build_dots()
	_btns = HBoxContainer.new()
	_btns.add_theme_constant_override("separation", 16)
	_btns.position = Vector2(980, 966)
	add_child(_btns)
	var notes := ScUi.button("Notas-weergave", ScUi.Kind.SECONDARY, 24, 220)
	notes.pressed.connect(_toggle_notes)
	_btns.add_child(notes)
	var nxt := ScUi.button("Volgende", ScUi.Kind.PRIMARY, 26, 200)
	nxt.pressed.connect(func(): action.emit("next", null))
	nxt.disabled = int(rep.get("n_stars", 0)) < 1 and ScLevels.priority_of(spec.id) == "P0"
	_btns.add_child(nxt)
	var again := ScUi.button("Opnieuw", ScUi.Kind.SECONDARY, 24, 170)
	again.pressed.connect(func(): action.emit("retry", null))
	_btns.add_child(again)
	var mp := ScUi.button("Kaart", ScUi.Kind.GHOST, 24, 140)
	mp.pressed.connect(func(): action.emit("map", null))
	_btns.add_child(mp)
	(nxt if not nxt.disabled else again).grab_focus.call_deferred()
	_resume_btn = ScUi.button("Herneem vanaf hier", ScUi.Kind.WAX, 22, 260)
	_resume_btn.position = Vector2(REPLAY.end.x - 270, REPLAY.end.y + 112)
	_resume_btn.visible = false
	_resume_btn.pressed.connect(func():
		if _sel >= 0:
			action.emit("resume", int(_dots[_sel].e.seq)))
	add_child(_resume_btn)
	# animatie: lakzegels één voor één
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	ScSnd.play("unroll", -6.0)
	var st: Array = rep.get("stars", [false, false, false])
	for i in 3:
		var ii := i
		tw.tween_interval(0.25)
		tw.tween_callback(func():
			if st[ii]:
				ScSnd.play("star_%d" % (ii + 1), -4.0)
				ScFx.wax_splat(_fx, _star_pos(ii))
			else:
				ScSnd.play("ui_wood", -10.0))
		tw.tween_method(func(v: float): _press[ii] = v, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): ScSnd.jingle(int(rep.get("n_stars", 0))))
	if ScSession.has("replay") and not _dots.is_empty():
		tw.tween_callback(func(): _open_first_mistake())
	if ScSession.has("notes"):
		tw.tween_callback(_toggle_notes)
	if ScSession.has("chain"):
		get_tree().create_timer(4.0).timeout.connect(func(): action.emit("next", null))


func _star_pos(i: int) -> Vector2:
	return Vector2(PAPER.position.x + 120 + i * 190, PAPER.position.y + 210)


func _open_first_mistake() -> void:
	for i in _dots.size():
		if _dots[i].kind == "mistake":
			_select(i)
			return
	for i in _dots.size():
		if _dots[i].kind == "bump":
			_select(i)
			return


func _build_dots() -> void:
	_dots = []
	if director == null:
		return
	for e in director.log.entries:
		if bool(e.auto):
			continue
		var typ := str(e.type)
		var kind := ""
		if typ == "BUMP":
			kind = "bump"
		elif ScScoring.DECISIONS.has(typ):
			kind = "ok" if int(e.verdict) == ScCodes.Verdict.OK else "mistake"
		else:
			continue
		_dots.append({"e": e, "kind": kind, "r": Rect2()})


func _process(delta: float) -> void:
	t += delta
	_n.queue_redraw()
	for c in get_children():
		if c is Node2D and c.has_meta("top"):
			c.queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_hover_dot = -1
		for i in _dots.size():
			if (_dots[i].r as Rect2).grow(4).has_point(ev.position):
				_hover_dot = i
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in _dots.size():
			if (_dots[i].r as Rect2).grow(4).has_point(ev.position):
				_select(i)
				return
		for b in _blots:
			if (b.r as Rect2).has_point(ev.position):
				_select_cause(int(b.pos))
				return


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var kc := (ev as InputEventKey).keycode
		var targets: Array = []
		for i in _dots.size():
			if _dots[i].kind != "ok":
				targets.append(i)
		if targets.is_empty():
			return
		if kc == KEY_RIGHT or kc == KEY_LEFT:
			var at := targets.find(_sel)
			at = (at + (1 if kc == KEY_RIGHT else -1) + targets.size()) % targets.size() if at >= 0 else 0
			_select(targets[at])
			get_viewport().set_input_as_handled()


func _select_cause(pos: int) -> void:
	for m in rep.get("mistakes", []):
		if (m.get("affects", []) as Array).has(pos):
			for i in _dots.size():
				if int(_dots[i].e.seq) == int(m.seq):
					_select(i)
					return
	_open_first_mistake()


# ------------------------------------------------------------------ herbeleving

func _select(i: int) -> void:
	if _notes:
		_toggle_notes()
	_sel = i
	_token += 1
	var tok := _token
	var e: Dictionary = _dots[i].e
	_coach = director.log.coach_line(e)
	_ref = director.log.notes_ref(e)
	ScSnd.play("page_turn", -8.0)
	_build_replay(e)
	_resume_btn.visible = _dots[i].kind == "mistake" and not (e.before as Dictionary).is_empty()
	if _replay_view == null:
		return
	# 1. jouw zet (bruin-transparant), met de gevolgen
	_replay_phase = "Jouw zet"
	_replay_view.modulate = Color(0.85, 0.62, 0.42, 0.9)
	await get_tree().create_timer(0.7).timeout
	if tok != _token or _replay_tool == null:
		return
	var mv: Dictionary = (e.data as Dictionary).get("move", {})
	if not mv.is_empty():
		var fxs: Array = []
		var phases: Array = []
		_replay_tool.changed.connect(func(f: Dictionary): fxs.append(f))
		_replay_tool.phase_changed.connect(func(_p: int, c: Dictionary): phases.append(c))
		_replay_view.last_move = mv
		_replay_tool.apply(mv)
		for f in fxs:
			if tok != _token:
				return
			var d := _replay_view.play(f)
			if d > 0:
				await get_tree().create_timer(minf(d, 0.9)).timeout
		if not phases.is_empty() and tok == _token:
			_replay_view.commit(phases[phases.size() - 1])
	await get_tree().create_timer(1.4).timeout
	if tok != _token:
		return
	# 2. de juiste zet: terug naar vóór de zet, gouden inkthand
	_build_replay(e)
	_replay_phase = "De juiste zet"
	_replay_view.modulate = Color.WHITE
	var hint: Dictionary = e.get("hint", {})
	if not hint.is_empty():
		_replay_view.ghost = hint
		_replay_view.create_tween().tween_property(_replay_view, "ghost_a", 1.0, 0.3)
		ScSnd.play("unroll", -10.0)


func _build_replay(e: Dictionary) -> void:
	if _replay_view:
		_replay_view.queue_free()
		_replay_view = null
	_replay_tool = null
	var before: Dictionary = e.get("before", {})
	var si := int(e.stage)
	if before.is_empty() or si < 0 or si >= director.stages.size():
		return
	var st: Dictionary = director.stages[si]
	var carry: Dictionary = director._carries.get(si, {})
	var tl := ScLevels.make_tool(st, carry)
	if tl == null:
		return
	tl.log = ScEventLog.new()
	tl.restore(before)
	_replay_tool = tl
	_replay_stage = si
	var tn := ScCodes.tool_name(tl.tool)
	var path: String = ScSession.VIEW_SCRIPTS.get(tn, "")
	var v: ScView = (load(path) as GDScript).new() if path != "" and ResourceLoader.exists(path) else ScView.new()
	v.readonly = true
	v.fx_root = _fx
	v.spd = 0.8
	ScDraw.prepare(v)
	v.setup(tl, tl.cursor(), spec)
	var sc := minf(REPLAY.size.x / 1260.0, REPLAY.size.y / 680.0)
	v.scale = Vector2(sc, sc)
	v.position = -ScView.AREA.position * sc + Vector2((REPLAY.size.x - 1260.0 * sc) / 2.0, 0)
	_replay_clip.add_child(v)
	_replay_view = v


func _toggle_notes() -> void:
	if _notes:
		_notes.queue_free()
		_notes = null
		return
	_notes = ScNotesView.new()
	_notes.setup(spec, director, rep)
	_notes.position = Vector2(0, 0)
	add_child(_notes)
	_notes.closed.connect(func(): _notes = null)
	ScSnd.play("unroll", -8.0)


# ------------------------------------------------------------------ tekenen

func _paint() -> void:
	var c := _n
	ScDraw.parchment(c, PAPER, 33, ScPal.VELLUM, true, 0.7)
	var x0 := PAPER.position.x + 50
	ScPal.text_l(c, ScPal.TITLE, Vector2(x0, PAPER.position.y + 56), "Het Kapittel", 56, ScPal.RUBRIC)
	var head := ""
	var eq := false
	var reads: Array = rep.get("readings", [])
	var any_bad := false
	for r in reads:
		if not bool(r.get("demo", false)) and not bool(r.get("equal", false)):
			any_bad = true
	if not bool(rep.get("completed", true)):
		head = "NIET AFGEWERKT"
	elif any_bad:
		head = "DE OVERKANT LAS ONZIN"
	else:
		head = "VERLIESLOOS"
		eq = true
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(x0 + 360, PAPER.position.y + 60), head, 30, ScPal.GOLD_DARK if eq else ScPal.SEPIA)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(x0, PAPER.position.y + 104), "%s · %s %s · %s" % [ScSession.chapter_title(spec.chapter),
		spec.id, spec.title, spec.notes_ref], 20, ScPal.INK_SOFT)
	# sterren
	var st: Array = rep.get("stars", [false, false, false])
	var labels: Array = rep.get("star_labels", ["", "", ""])
	for i in 3:
		var p := _star_pos(i)
		ScDraw.star_seal(c, p, 36, bool(st[i]), _press[i], i + 11)
		var lab := str(labels[i])
		var fs := 18 if ScPal.text_w(ScPal.UI_MED, lab, 18) < 180 else 15
		ScPal.text_c(c, ScPal.UI_MED, p + Vector2(0, 58), lab, fs, ScPal.GOLD_DARK if st[i] else ScPal.INK_FADED)
	# kasboek
	ScDraw.gommaar(c, Vector2(PAPER.position.x + 760, PAPER.position.y + 300), 0.8, t)
	var rows := _ledger_rows()
	if not rows.is_empty():
		ScDrawTools.ledger_bars(c, Rect2(x0, PAPER.position.y + 320, 820, 74.0 + 37.0 * rows.size()), rows, _unit())
	var by := PAPER.position.y + 350 + 74.0 + 37.0 * rows.size()
	if rows.is_empty():
		by = PAPER.position.y + 380
	var bd: Array = rep.get("breakdown", [])
	var col := 0
	var yy := by
	for b in bd:
		var bx := x0 + col * 420
		ScPal.text_l(c, ScPal.UI, Vector2(bx, yy), str(b.label), 21, ScPal.INK_SOFT)
		ScPal.text_r(c, ScPal.MONO_B, Vector2(bx + 390, yy), "%+d" % int(b.amount), 21, ScPal.INK)
		col += 1
		if col == 2:
			col = 0
			yy += 32
	if col == 1:
		yy += 32
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(x0, yy + 8), "Punten", 26, ScPal.INK)
	ScPal.text_l(c, ScPal.MONO_B, Vector2(x0 + 140, yy + 8), str(int(rep.get("points", 0))), 32, ScPal.INK)
	var tm := "tijd %d s · klemmen %d · hulp %d" % [int(rep.get("time_s", 0)), int(rep.get("bumps", 0)),
		int(rep.get("hints", 0)) + int(rep.get("undos", 0)) + int(rep.get("resumes", 0))]
	ScPal.text_l(c, ScPal.UI, Vector2(x0 + 300, yy + 10), tm, 20, ScPal.INK_SOFT)
	# origineel en voorlezing
	_blots = []
	var main := {}
	for r2 in reads:
		if not bool(r2.get("demo", false)):
			main = r2
	if not main.is_empty():
		var oy := PAPER.end.y - 190
		ScPal.text_l(c, ScPal.TITLE, Vector2(x0, oy - 70), "Origineel en voorlezing" if not bool(main.get("receive", false))
			else "Origineel en jouw kopie", 30, ScPal.INK)
		var o := str(main.get("original", ""))
		var rd := str(main.get("read", ""))
		var n := maxi(o.length(), rd.length())
		var size := 34
		while size > 16 and (ScPal.char_w(size) + 10.0) * n > 860:
			size -= 1
		var cw := ScPal.char_w(size) + 10.0
		var lm := Vector2(x0 + 10, oy + 20)
		ScDraw.reading(c, lm, o, rd, size, -1, t, 0.3 + 0.3 * sin(t * 4.0))
		for i in n:
			var oc := o[i] if i < o.length() else ""
			var rc := rd[i] if i < rd.length() else ""
			if oc != rc:
				var r3 := Rect2(lm + Vector2(cw * i, 0), Vector2(cw, size * 1.5))
				_blots.append({"pos": i, "r": r3})
		if not _blots.is_empty():
			ScPal.text_l(c, ScPal.UI_MED, Vector2(x0, oy + 100), "Klik op een inktvlek: waar liep het mis?", 20, ScPal.SEPIA)
	var extra := str(spec.story.get("debrief_extra", ""))
	if extra != "":
		ScPal.text_l(c, ScPal.UI_MED, Vector2(x0, PAPER.end.y - 38), "Zeno: " + extra, 21, ScPal.INK)
	# rechts: tijdlijn + herbeleving
	var rx := REPLAY.position.x
	ScPal.text_l(c, ScPal.TITLE, Vector2(rx, PAPER.position.y + 72), "Misstappen", 34, ScPal.INK)
	_draw_dots(c, Rect2(rx, PAPER.position.y + 110, REPLAY.size.x, 80))
	ScDraw.wood(c, REPLAY.grow(10), ScPal.WALNUT, 12)


func _draw_dots(c: CanvasItem, r: Rect2) -> void:
	var n := _dots.size()
	if n == 0:
		ScPal.text_l(c, ScPal.UI_MED, r.position + Vector2(0, 28), "Geen beslissingen gelogd.", 20, ScPal.INK_SOFT)
		return
	var step := minf(34.0, (r.size.x - 20) / n)
	var rad := clampf(step * 0.36, 5.0, 11.0)
	c.draw_line(r.position + Vector2(0, 30), Vector2(r.position.x + step * n, r.position.y + 30), ScPal.INK_FADED, 2.0, true)
	var nm := 0
	for i in n:
		var d: Dictionary = _dots[i]
		var p := r.position + Vector2(step * (i + 0.5), 30)
		var col := ScPal.OK
		if d.kind == "mistake":
			col = ScPal.WARN
			nm += 1
		elif d.kind == "bump":
			col = ScPal.STONE_LIGHT
		var rr := rad * (1.35 if i == _sel or i == _hover_dot else 1.0)
		c.draw_circle(p + Vector2(1, 2), rr, ScPal.SHADOW_SOFT)
		c.draw_circle(p, rr, col)
		if d.kind == "mistake":
			c.draw_line(p + Vector2(-rr * 0.5, 0), p + Vector2(rr * 0.5, 0), ScPal.INK, 2.0)
		elif d.kind == "bump":
			c.draw_line(p + Vector2(-rr * 0.4, -rr * 0.4), p + Vector2(rr * 0.4, rr * 0.4), ScPal.INK, 2.0)
		if i == _sel:
			ScPal.ring(c, Rect2(p - Vector2(rr + 5, rr + 5), Vector2(rr + 5, rr + 5) * 2), int(rr + 5), ScPal.INFO, 3)
		d.r = Rect2(p - Vector2(rr, rr), Vector2(rr, rr) * 2)
	var nb := int(rep.get("bumps", 0))
	var leg := "%d %s · %d %s · %d %s" % [n, "beslissing" if n == 1 else "beslissingen", nm,
		"misstap" if nm == 1 else "misstappen", nb, "klem" if nb == 1 else "klemmen"]
	ScPal.text_l(c, ScPal.UI_MED, r.position + Vector2(0, 66), leg + ("  ·  klik een amber stip" if nm > 0 else ""), 19, ScPal.INK_SOFT)


func _paint_top(c: Node2D) -> void:
	if _sel < 0:
		var msg := "Foutloos! Niets te herbeleven." if _count_kind("mistake") == 0 else "Kies een amber stip om dat moment te herbeleven."
		ScPal.text_c(c, ScPal.UI_MED, REPLAY.get_center(), msg, 26, ScPal.TEXT)
		if _count_kind("mistake") == 0:
			ScDraw.zeno(c, REPLAY.get_center() + Vector2(0, 170), 1.0, t, 0.0)
		return
	var tag := Rect2(REPLAY.position + Vector2(12, 12), Vector2(ScPal.text_w(ScPal.UI_BOLD, _replay_phase, 22) + 30, 40))
	c.draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.92), 20), tag)
	ScPal.text_l(c, ScPal.UI_BOLD, tag.position + Vector2(15, 20), _replay_phase, 22,
		ScPal.GOLD_LIGHT if _replay_phase == "De juiste zet" else ScPal.VELLUM_HI)
	var cy := REPLAY.end.y + 34
	var cr := Rect2(REPLAY.position.x, cy, REPLAY.size.x, 74)
	ScDraw.scroll(c, cr)
	var fs := 24
	while fs > 16 and ScPal.text_w(ScPal.UI, _coach, fs) > cr.size.x - 60:
		fs -= 1
	ScPal.text_l(c, ScPal.UI, cr.position + Vector2(30, 28), _coach, fs, ScPal.INK)
	ScPal.text_l(c, ScPal.UI_MED, cr.position + Vector2(30, 56), _ref, 18, ScPal.RUBRIC)


func _count_kind(k: String) -> int:
	var n := 0
	for d in _dots:
		if d.kind == k:
			n += 1
	return n


func _unit() -> String:
	var tools := spec.tool_names()
	for tl in tools:
		if tl == "window":
			return "zegels"
		if tl == "stampcase":
			return "stempels"
	return "bits"


func _ledger_rows() -> Array:
	var c: Dictionary = rep.get("counters", {})
	var opt: Dictionary = rep.get("optimum", {})
	var gh: Dictionary = rep.get("ghosts", {})
	var ink := int(c.get("ink", 0))
	var oink := int(opt.get("ink", 0))
	if oink <= 0 and ink <= 0:
		return []
	var rows := [{"label": "jouw inkt", "value": ink, "col": ScPal.INK}, {"label": "optimum", "value": oink, "col": ScPal.GOLD}]
	if int(gh.get("plain", 0)) > 0:
		rows.append({"label": "gewoon schrift", "value": int(gh.plain), "col": ScPal.INK_FADED})
	if int(gh.get("fixed", 0)) > 0:
		rows.append({"label": "vaste lengte", "value": int(gh.fixed), "col": ScPal.INK_SOFT})
	if spec.id == "3-4":
		rows.append({"label": "Huffman", "value": 53, "col": ScPal.INK_SOFT})
	if spec.id == "C":
		rows.append({"label": "Huffman op de tekst", "value": 63, "col": ScPal.INK_SOFT})
	return rows
