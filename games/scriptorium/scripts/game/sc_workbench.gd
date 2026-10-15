extends Control
## De werkbank (GDD §2.2, §4.3): één scène voor alle levels en de Nachtwake. Bouwt de nodes in _ready:
## achtergrond, HUD, opdrachtband, de weergave van het huidige werktuig (ScView), De Overkant, de kortschrift-strook,
## Zeno, het kaarslicht en de overlays (brief, voorlezing, Kapittel, pauze, instellingen, notas).
##
## Alle signalen van ScDirector en van de werktuigen komen in één wachtrij en worden in volgorde afgespeeld
## (_run): animaties (changed(fx)) duren even, pas daarna volgt de nieuwe toestand (phase_changed), de voorlezing en
## het Kapittel. Zo ziet de speler elke stap van de kopiist, ook de automatische.

const OV_RECT := Rect2(1282, 196, 626, 684)
const STRIP_RECT := Rect2(40, 958, 1220, 92)
const STRIP_WRITERS := ["write", "seal", "stamp", "number", "needle", "mark"]

var spec: ScLevelSpec
var director: ScDirector
var wake := false
var view: ScView
var views := {}
var t := 0.0

var bg: TextureRect
var ov_tex: TextureRect
var world: Node2D
var hud: Node2D
var band_n: Node2D
var deco: Node2D
var strip: ScStrip
var strip_clip: Control
var fx: Node2D
var overlay: ColorRect
var ui: Control
var ctx_row: HBoxContainer
var top_row: HBoxContainer
var layer: Control

var _queue: Array = []
var _playing := false
var _overlay_open := 0
var _counters := {"ink": 0, "twine": 0, "search": 0, "decisions": 0, "bumps": 0, "wasted": 0, "zeros": 0}
var _ink_shown := 0.0
var _points := 0
var _points_shown := 0.0
var _band := {}
var _stage_i := 0
var _stage_tool := ""
var _stage_opt := -1
var _stage_plain := -1
var _zeno_text := ""
var _zeno_until := 0.0
var _zeno_a := 0.0
var _idle := 0.0
var _ghost_tut := false
var _bot: ScLevelBot
var _bot_cool := 0.0
var _finished := false
var _report := {}
var _letterlijk_mood := 0
var _letterlijk_talk := 0.0
var _fast := 1.0
var _paused := false
var _said_ids := {}
# Nachtwake
var _lives := 3
var _burn := 0.0
var _burn_max := 1.0
var _combo := 1
var _flare := 0.0
var _round := 0
var _wake_seed := 0


func _ready() -> void:
	ScSession.apply_all()
	theme = ScUi.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	wake = ScSession.wake or ScSession.has("wake")
	if ScSession.has("wake"):
		ScSession.consume("wake")
	var lv := ScSession.consume("level")
	if lv != "":
		ScSession.level_id = lv
		wake = false
	if wake:
		_wake_seed = int(ScSession.arg("seed", str(randi() % 100000)))
		spec = ScLevels.endless_spec(0, _wake_seed)
	else:
		if not ScLevels.has(ScSession.level_id):
			ScSession.level_id = "0-1"
		spec = ScLevels.get_spec(ScSession.level_id)
	_build()
	ScSnd.music("wake" if wake else ("codex" if spec.id == "C" else "bench"))
	var bm := ScSession.arg("bot")
	if bm != "":
		_bot = ScLevelBot.new("" if bm == "perfect" else bm, int(ScSession.arg("seed", "7")))
	if wake:
		ScSnd.play("candle_light", -4.0)
		_start()
	elif ScSession.arg("brief", "1") == "0" or _bot != null:
		_start()
	else:
		_open_brief()


# ================================================================ opbouw

func _build() -> void:
	bg = TextureRect.new()
	bg.texture = load(ScPal.ASSETS + "art/bg/%s.jpg" % ("bg_desk_night" if wake else "bg_desk"))
	bg.size = Vector2(1920, 1080)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	ov_tex = TextureRect.new()
	ov_tex.texture = load(ScPal.ASSETS + "art/bg/bg_overkant.jpg")
	ov_tex.position = OV_RECT.position
	ov_tex.size = OV_RECT.size
	ov_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ov_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ov_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov_tex.visible = not wake
	add_child(ov_tex)
	world = Node2D.new()
	ScDraw.prepare(world)
	add_child(world)
	var amb := Node2D.new()
	world.add_child(amb)
	ScFx.ambient_dust(amb, Rect2(0, 200, 1260, 680), 0.6)
	deco = Node2D.new()
	ScDraw.prepare(deco)
	deco.draw.connect(_draw_deco)
	world.add_child(deco)
	band_n = Node2D.new()
	ScDraw.prepare(band_n)
	band_n.draw.connect(_draw_band)
	world.add_child(band_n)
	hud = Node2D.new()
	ScDraw.prepare(hud)
	hud.draw.connect(_draw_hud)
	strip_clip = Control.new()
	strip_clip.position = STRIP_RECT.position
	strip_clip.size = STRIP_RECT.size
	strip_clip.clip_contents = true
	strip_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip_clip)
	strip = ScStrip.new()
	strip.clip_w = STRIP_RECT.size.x
	strip.spd = ScSession.copyist()
	ScDraw.prepare(strip)
	strip_clip.add_child(strip)
	fx = Node2D.new()
	fx.z_index = 30
	add_child(fx)
	strip.fx_root = fx
	overlay = ScUi.candle_overlay(Vector2(1500, 640) if wake else Vector2(120, 330), 0.6 if wake else 0.36,
		1000.0 if wake else 1250.0)
	add_child(overlay)
	add_child(hud)
	ui = Control.new()
	ui.size = Vector2(1920, 1080)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	var pause_b := ScUi.icon_button("pause", ScUi.Kind.SECONDARY, 54)
	pause_b.position = Vector2(22, 14)
	pause_b.tooltip_text = "Pauze (Esc)"
	pause_b.pressed.connect(_open_pause)
	ui.add_child(pause_b)
	top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.position = Vector2(1716, 14)
	ui.add_child(top_row)
	if not wake:
		var hint_b := ScUi.icon_button("hint", ScUi.Kind.SECONDARY, 54)
		hint_b.tooltip_text = "Zeno's inkthand (F1) — kost ★★★"
		hint_b.pressed.connect(_hint)
		top_row.add_child(hint_b)
		var undo_b := ScUi.icon_button("undo", ScUi.Kind.SECONDARY, 54)
		undo_b.tooltip_text = "Zet terugnemen (Ctrl+Z) — kost ★★★"
		undo_b.pressed.connect(_undo)
		top_row.add_child(undo_b)
	var notes_b := ScUi.icon_button("notes", ScUi.Kind.SECONDARY, 54)
	notes_b.tooltip_text = "Notas (spiekbriefje)"
	notes_b.pressed.connect(_open_sheet)
	top_row.add_child(notes_b)
	if wake:
		top_row.position.x = 1846
	ctx_row = HBoxContainer.new()
	ctx_row.add_theme_constant_override("separation", 14)
	ctx_row.alignment = BoxContainer.ALIGNMENT_END
	ctx_row.position = Vector2(1290, 984)
	ctx_row.size = Vector2(610, 70)
	ui.add_child(ctx_row)
	layer = Control.new()
	layer.size = Vector2(1920, 1080)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)


# ================================================================ start

func _open_brief() -> void:
	var b := ScBrief.new()
	b.setup(spec)
	_overlay_open += 1
	layer.add_child(b)
	b.closed.connect(func():
		_overlay_open -= 1
		_start())


func _start() -> void:
	director = ScDirector.new()
	director.stage_started.connect(_on_stage_started)
	director.reading_started.connect(func(res: Dictionary): _q("reading", null, res))
	director.level_finished.connect(func(rep: Dictionary): _q("finished", null, rep))
	director.candle_changed.connect(_on_candle)
	director.round_started.connect(func(r: int, st: Dictionary): _q("round", null, {"r": r, "stage": st}))
	_finished = false
	director.start(spec)
	director.assisted = ScSession.guides()
	director.scoring.points_changed.connect(_on_points)
	director.scoring.combo_changed.connect(_on_combo)
	director.scoring.full_flame.connect(_on_flame)
	_kick()


func _on_stage_started(i: int, tl: ScTool) -> void:
	tl.changed.connect(func(f: Dictionary): _q("fx", tl, f))
	tl.phase_changed.connect(func(_p: int, c: Dictionary): _q("phase", tl, c))
	tl.counters_changed.connect(func(c: Dictionary): _q("counters", tl, c))
	tl.output_changed.connect(func(o: Dictionary): _q("output", tl, o))
	tl.copy_changed.connect(func(c: String): _q("copy", tl, c))
	tl.overkant_changed.connect(func(s: Dictionary): _q("ov", tl, s))
	tl.event_logged.connect(func(e: Dictionary): _q("event", tl, e))
	_q("stage", tl, {"i": i, "cursor": tl.cursor()})


func _q(kind: String, tl, data) -> void:
	_queue.append({"k": kind, "tool": tl, "d": data})
	_kick()


func _kick() -> void:
	if not _playing:
		_run.call_deferred()


func busy() -> bool:
	return _playing or not _queue.is_empty() or _overlay_open > 0 or _paused


# ================================================================ wachtrij

func _run() -> void:
	if _playing:
		return
	_playing = true
	while not _queue.is_empty():
		var ev: Dictionary = _queue.pop_front()
		var d := 0.0
		match str(ev.k):
			"stage":
				d = _enter_stage(ev.tool, ev.d)
			"fx":
				d = _play_fx(ev.tool, ev.d)
			"phase":
				var v: ScView = views.get(ev.tool.get_instance_id())
				if v:
					v.commit(ev.d)
					if v == view:
						_refresh_after_phase()
			"counters":
				_counters = (ev.d as Dictionary).duplicate()
			"output":
				var v2: ScView = views.get(ev.tool.get_instance_id())
				if v2 == view:
					strip.sync(view.strip().tokens, true)
			"copy":
				pass
			"ov":
				var v3: ScView = views.get(ev.tool.get_instance_id())
				if v3:
					v3.set_overkant(ev.d)
					_letterlijk_talk = 1.0
			"event":
				_on_event(ev.tool, ev.d)
			"reading":
				if wake:
					_wake_reading(ev.d)
				else:
					await _reading(ev.d)
			"finished":
				await _finish(ev.d)
			"round":
				_round = int(ev.d.r)
				_float_text(Vector2(630, 560), "Ronde %d" % (_round + 1), ScPal.GILT_LIGHT, 44)
		if d > 0.0:
			await get_tree().create_timer(d / _fast, false).timeout
	_playing = false
	if view:
		view.locked = busy()
	_refresh_buttons()


func _view_for(tl) -> ScView:
	return views.get(tl.get_instance_id()) if tl != null else null


func _enter_stage(tl: ScTool, d: Dictionary) -> float:
	var tn := ScCodes.tool_name(tl.tool)
	_stage_i = int(d.i)
	_stage_tool = tn
	var path: String = ScSession.VIEW_SCRIPTS.get(tn, "")
	var v: ScView
	if path != "" and ResourceLoader.exists(path):
		v = (load(path) as GDScript).new()
	else:
		v = ScView.new()
	v.spd = ScSession.copyist()
	v.guides = ScSession.guides()
	v.tutorial = _is_tutorial()
	v.fx_root = fx
	ScDraw.prepare(v)
	v.setup(tl, d.cursor, spec)
	v.request.connect(_on_request)
	v.say.connect(_say)
	world.add_child(v)
	world.move_child(v, band_n.get_index())
	var old := view
	views[tl.get_instance_id()] = v
	view = v
	var dur := 0.0
	if old != null and is_instance_valid(old):
		var tw := old.create_tween()
		tw.tween_property(old, "position:x", -1300.0, 0.45 * v.spd).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(old.queue_free)
		v.position.x = 1300.0
		var tw2 := v.create_tween()
		tw2.tween_interval(0.2 * v.spd)
		tw2.tween_property(v, "position:x", 0.0, 0.5 * v.spd).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ScSnd.play("ui_whoosh", -6.0)
		dur = 0.65 * v.spd
	# kortschrift-strook en geesten
	strip.clear()
	var opt_st: Array = director.optimum.get("stages", []) if director else []
	_stage_opt = int((opt_st[_stage_i] as Dictionary).ink) if _stage_i < opt_st.size() else -1
	_stage_plain = _plain_for(tl.stage)
	var s0 := v.strip()
	strip.koker_units = _stage_opt if str(s0.get("unit", "")) != "" and tl.side == ScCodes.Side.SEND else -1
	strip.sync(s0.tokens, false)
	strip.consumed = int(s0.get("consumed", -1))
	_counters = tl.counters.duplicate()
	_ink_shown = float(_counters.ink)
	var intros: Array = spec.story.get("stage_intros", [])
	if _stage_i < intros.size():
		_say(str(intros[_stage_i]))
	elif _stage_i == 0 and spec.intro != "" and not wake:
		_say(spec.intro)
	_refresh_after_phase()
	return dur


func _plain_for(st: Dictionary) -> int:
	if str(st.get("side", "send")) == "receive":
		return -1
	var tx := str(st.get("text", ""))
	match str(st.get("tool", "")):
		"window", "stampcase":
			return tx.length()
		"bindery", "code_board", "living_tree", "ruler":
			if tx != "":
				return 8 * tx.length()
			return int(spec.ghosts.get("plain", -1)) if spec.id == "C" else -1
	return -1


func _play_fx(tl: ScTool, f: Dictionary) -> float:
	var v := _view_for(tl)
	if v == null:
		return 0.0
	var kind := str(f.get("fx", ""))
	var d := 0.0
	if kind == "restore":
		v.k = 1.0
		strip.sync(v.strip().tokens, false)
		return 0.0
	if kind == "needle_reset":
		strip.sync([], false)
	if kind in STRIP_WRITERS and v == view and tl.side == ScCodes.Side.SEND:
		var toks := v.fx_tokens(f)
		if not toks.is_empty():
			d = strip.append(toks)
	if kind == "overkant":
		v.set_overkant(f.get("state", {}))
		_letterlijk_talk = 1.0
	if kind == "bump":
		_counters.bumps = int(_counters.bumps)
	return maxf(d, v.play(f))


func _refresh_after_phase() -> void:
	if view == null:
		return
	_band = view.band()
	var s := view.strip()
	if int(s.get("consumed", -1)) >= 0:
		strip.sync(s.tokens, false)
		strip.consumed = int(s.consumed)
	view.ghost = {}
	view.ghost_a = 0.0
	_idle = 0.0
	_refresh_buttons()


func _refresh_buttons() -> void:
	for c in ctx_row.get_children():
		c.queue_free()
	if view == null or _finished:
		return
	for b in view.buttons():
		var bt := ScUi.button(str(b.text), int(b.get("kind", ScUi.Kind.VELLUM)), 24, 150)
		if b.has("key"):
			bt.tooltip_text = "Sneltoets: %s" % str(b.key)
		var mv: Dictionary = b.get("move", {})
		bt.disabled = bool(b.get("disabled", false))
		bt.pressed.connect(func():
			if busy():
				return
			if mv.has("_local"):
				view._local(mv)
			else:
				_on_request(mv))
		ctx_row.add_child(bt)


func _on_event(tl: ScTool, e: Dictionary) -> void:
	if wake:
		if str(e.type) == "BIND" and bool(e.ok) and int(e.verdict) == ScCodes.Verdict.WRONG_PAIR:
			_float_text(Vector2(630, 520), "Het touw knapt!", ScPal.WARN, 40)
			ScSnd.play("candle_out", -2.0)
		return
	# een paar zinnen van Zeno bij bijzondere momenten (≤ 12 woorden, enkel de eerste keer)
	var typ := str(e.type)
	if typ == "BUMP" and str(e.data.get("reason", "")) == "ancestor" and not _said_ids.has("ancestor"):
		_said_ids["ancestor"] = true
		_say("Een monnik kan niet ruilen met zijn eigen stoet." if not bool(e.data.get("parent", false))
			else "Je ouder is de verste? Dan blijf je staan.")
	if typ == "BIND" and spec.id == "1-1" and int(e.seq) >= 0 and tl is ScBindery:
		if (tl as ScBindery).binds.size() == 2 and not _said_ids.has("uniek"):
			_said_ids["uniek"] = true
			_say("Niet uniek. Elke keuze is even goed.")


# ================================================================ zetten

func _on_request(m: Dictionary) -> void:
	if busy() or director == null or _finished or m.is_empty():
		return
	if view:
		view.last_move = m
		view.ghost = {}
		view.ghost_a = 0.0
	_idle = 0.0
	ScSnd.pad(false)
	director.apply(m)
	_kick()


func _hint() -> void:
	if busy() or director == null or wake or _finished:
		return
	var mv := director.hint()
	if mv.is_empty() or view == null:
		return
	view.ghost = mv
	view.create_tween().tween_property(view, "ghost_a", 1.0, 0.3)
	ScSnd.play("unroll", -10.0)
	_say("Kijk, zo.")


func _undo() -> void:
	if busy() or director == null or wake or _finished:
		return
	if director.undo():
		ScSnd.play("page_turn", -6.0)
		_kick()
	else:
		ScSnd.play("clamp", -10.0)


func _say(text: String) -> void:
	if text == "":
		return
	_zeno_text = text
	_zeno_until = t + 3.2 + text.length() * 0.05


func _is_tutorial() -> bool:
	if wake:
		return false
	return spec.id.ends_with("-1") or spec.id in ["0-2", "2-2", "4-2", "5-2", "6-2"]


# ================================================================ lus en input

func _process(delta: float) -> void:
	t += delta
	ScSession.qa_tick(delta)
	_fast = 3.0 if Input.is_key_pressed(KEY_SPACE) and not _bot else 1.0
	if _bot and not _bot_cool_ok(delta):
		pass
	if director and not _finished and not busy():
		director.tick(delta)
		_idle += delta
		if _idle > 8.0:
			ScSnd.pad(true)
		if view and _idle > 8.0 and view.ghost.is_empty() and _is_tutorial():
			var mv := director.correct_move()
			if str(mv.get("act", "none")) != "none":
				view.ghost = mv
				view.create_tween().tween_property(view, "ghost_a", 0.8, 0.4)
				_say("Zeno wijst het voor je aan.")
	if view:
		view.locked = busy()
	_ink_shown = lerpf(_ink_shown, float(_counters.get("ink", 0)), minf(1.0, delta * 8.0))
	_points_shown = lerpf(_points_shown, float(_points), minf(1.0, delta * 6.0))
	_letterlijk_talk = maxf(0.0, _letterlijk_talk - delta * 0.8)
	_flare = maxf(0.0, _flare - delta)
	var want_a := 1.0 if t < _zeno_until else 0.0
	_zeno_a = move_toward(_zeno_a, want_a, delta * 4.0)
	hud.queue_redraw()
	deco.queue_redraw()
	band_n.queue_redraw()


func _bot_cool_ok(delta: float) -> bool:
	if director == null or _finished or busy():
		return false
	_bot_cool -= delta
	if _bot_cool > 0.0:
		return false
	_bot_cool = float(ScSession.arg("bot_delay", "0.35"))
	_bot.step(director, delta)
	_kick()
	return true


func _unhandled_input(ev: InputEvent) -> void:
	if _overlay_open > 0 or _paused:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var ke := ev as InputEventKey
		match ke.keycode:
			KEY_ESCAPE:
				_open_pause()
				get_viewport().set_input_as_handled()
				return
			KEY_F1:
				_hint()
				get_viewport().set_input_as_handled()
				return
			KEY_Z:
				if ke.ctrl_pressed:
					_undo()
					get_viewport().set_input_as_handled()
					return
	if view and view.handle(ev):
		get_viewport().set_input_as_handled()


func _input(ev: InputEvent) -> void:
	# muisbeweging altijd doorgeven (hover), ook als de knoppen het event opeten
	if ev is InputEventMouseMotion and view:
		view.handle(ev)


# ================================================================ voorlezing en einde

func _reading(res: Dictionary) -> void:
	var r := ScReading.new()
	var res2 := res.duplicate()
	res2["tokens"] = strip.tokens.duplicate(true)
	r.setup(res2, spec, director)
	_overlay_open += 1
	layer.add_child(r)
	ScSnd.duck(true, true)
	await r.closed
	ScSnd.duck(false)
	_overlay_open -= 1


func _wake_reading(res: Dictionary) -> void:
	if bool(res.get("equal", false)):
		_float_text(Vector2(630, 520), "Goed gelezen!", ScPal.GOLD_LIGHT, 40)
		ScSnd.play("bell", -10.0)
	else:
		_float_text(Vector2(630, 520), "Verkeerd gelezen", ScPal.WARN, 40)


func _finish(rep: Dictionary) -> void:
	_finished = true
	_report = rep
	_refresh_buttons()
	if wake:
		await get_tree().create_timer(0.8, false).timeout
		var w := ScWakeEnd.new()
		w.setup(rep)
		_overlay_open += 1
		layer.add_child(w)
		return
	ScSession.map_stars_before = ScSave.all_stars()
	ScSave.record(spec.id, rep)
	if spec.id == "1-1" and _notes_tree(rep):
		ScSave.add_seal("1-1", "notasboom")
	ScSession.map_focus = spec.id
	if ScSession.arg("review", "1") == "0":
		print("SC_REPORT %s stars=%d points=%d read=%s" % [spec.id, int(rep.n_stars), int(rep.points), str(rep.read)])
		if _bot:
			get_tree().quit()
		return
	await get_tree().create_timer(0.5, false).timeout
	var rv := ScReview.new()
	rv.setup(rep, spec, director)
	rv.action.connect(_on_review_action)
	_overlay_open += 1
	layer.add_child(rv)


func _notes_tree(rep: Dictionary) -> bool:
	var st: Array = rep.get("structures", [])
	if st.is_empty():
		return false
	var y: Dictionary = st[0].get("yours", {})
	var c: Dictionary = st[0].get("correct", {})
	return int(rep.n_stars) >= 1 and y.get("codes", {}) == c.get("codes", {})


func _on_review_action(a: String, arg = null) -> void:
	match a:
		"next":
			var nx := _next_id()
			if nx == "":
				Transition.goto(ScSession.SCENE_MAP)
			else:
				ScSession.level_id = nx
				Transition.goto(ScSession.SCENE_BENCH)
		"retry":
			Transition.goto(ScSession.SCENE_BENCH)
		"map":
			Transition.goto(ScSession.SCENE_MAP)
		"resume":
			# hernemen vanaf vóór een misstap (telt als hulp)
			for c in layer.get_children():
				c.queue_free()
			_overlay_open = 0
			_finished = false
			if director.resume_from(int(arg)):
				_kick()


func _next_id() -> String:
	var ids := ScLevels.ids()
	var i := ids.find(spec.id)
	for q in range(i + 1, ids.size()):
		var x: String = ids[q]
		if ScLevels.priority_of(x) == "P2":
			continue
		if ScSession.unlocked(x):
			return x
	return ""


# ================================================================ overlays

func _open_pause() -> void:
	if _overlay_open > 0 or _paused:
		return
	var p := ScPause.new()
	p.setup(spec, wake)
	_paused = true
	layer.add_child(p)
	ScSnd.duck(true)
	p.action.connect(_on_pause_action)


func _on_pause_action(a: String) -> void:
	match a:
		"resume":
			_paused = false
			ScSnd.duck(false)
		"retry":
			Transition.goto(ScSession.SCENE_BENCH)
		"map":
			Transition.goto(ScSession.SCENE_MAP if not wake else ScSession.SCENE_TITLE)
		"stop":
			_paused = false
			ScSnd.duck(false)
			if director:
				director.finish()
				_kick()


func _open_sheet() -> void:
	if _overlay_open > 0 or _paused:
		return
	var s := ScCheatSheet.new()
	s.setup(spec.id if not wake else "nachtwake", _stage_tool)
	_paused = true
	layer.add_child(s)
	s.closed.connect(func(): _paused = false)


# ================================================================ Nachtwake

func _on_candle(lives: int, burn: float) -> void:
	if lives < _lives:
		ScSnd.play("candle_out", -2.0)
		_shake_world(6.0)
	_lives = lives
	_burn = burn
	if director and director.tool:
		_burn_max = maxf(0.1, float(director.current_stage().get("time", 10.0)))
	ScSnd.pad(_lives <= 1 or (_burn / _burn_max) < 0.25)


func _on_points(total: int, delta: int, _reason: String) -> void:
	_points = total
	if delta != 0 and view:
		var p := Vector2(900, 120)
		_float_text(p, ("+%d" if delta > 0 else "%d") % delta, ScPal.GOLD_LIGHT if delta > 0 else ScPal.WARN, 30)


func _on_combo(c: int) -> void:
	_combo = c
	if c > 1:
		ScSnd.play("choir_note", -8.0, 1.0 + 0.12 * c, false)


func _on_flame() -> void:
	_flare = 1.0
	ScSnd.play("candle_flare", -2.0)
	ScFx.embers(fx, Vector2(210, 860))
	_float_text(Vector2(630, 460), "Volle vlam!", ScPal.FLAME, 52)
	Engine.time_scale = 0.5
	get_tree().create_timer(0.2, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func _float_text(p: Vector2, s: String, col: Color, size := 34) -> void:
	var j = get_node_or_null("/root/Juice")
	if j:
		j.floater(fx, p, s, col, size, 50.0, 0.9)


func _shake_world(px: float) -> void:
	var s := px * ScSession.shake_scale()
	if s <= 0.0:
		return
	var tw := world.create_tween()
	for i in 5:
		tw.tween_property(world, "position", Vector2(randf_range(-s, s), randf_range(-s, s)), 0.03)
	tw.tween_property(world, "position", Vector2.ZERO, 0.05)


# ================================================================ tekenen

func _draw_hud() -> void:
	var c := hud
	ScDraw.leather(c, Rect2(12, 6, 1896, 70), 18)
	var title := ""
	if wake:
		title = "Nachtwake · ronde %d" % (_round + 1)
	else:
		title = "%s · %s %s" % [ScSession.chapter_title(spec.chapter), spec.id, spec.title]
	var x := 92.0
	var tw := ScPal.text_l(c, ScPal.TITLE, Vector2(x, 40), title, 32, ScPal.GILT_LIGHT)
	x += tw + 18
	if not wake:
		var ref := spec.notes_ref
		ScPal.text_l(c, ScPal.UI_MED, Vector2(x, 42), ref, 18, ScPal.TEXT_DIM)
	var mx := 880.0
	if wake:
		_draw_wake_hud(c)
		return
	if _stage_plain > 0 or _stage_opt > 0 and _counts_ink():
		if _counts_ink():
			ScDraw.ink_meter(c, Rect2(mx, 12, 470, 58), int(round(_ink_shown)), _stage_opt, maxi(_stage_plain, 0), t)
	var px := 1376.0
	if _stage_tool == "bindery":
		ScDraw.pill(c, Rect2(px, 20, 116, 42), "twine", str(int(_counters.twine)), t, ScPal.PANEL_LO,
			_stage_opt > 0 and int(_counters.twine) > _stage_opt)
		px += 124
		if str(view.stage.get("mode", "")) == "shelves" if view else false:
			ScDraw.pill(c, Rect2(px, 20, 116, 42), "search", str(int(_counters.search)), t)
			px += 124
	elif _stage_tool == "shelf":
		ScDraw.pill(c, Rect2(px, 20, 116, 42), "zero", str(int(_counters.zeros)), t)
		px += 124
	elif _stage_tool == "window" and view and bool(view.stage.get("register", false)):
		ScDraw.pill(c, Rect2(px, 20, 116, 42), "search", str(int(_counters.search)), t)
		px += 124
	ScDraw.pill(c, Rect2(px, 20, 104, 42), "bump", str(int(_counters.bumps)), t)
	px += 112
	var pr := Rect2(px, 20, 104, 42)
	c.draw_style_box(ScPal.sb(ScPal.PANEL_LO, 21), pr)
	ScPal.ring(c, pr, 21, Color(ScPal.GILT, 0.5), 1)
	ScPal.text_c(c, ScPal.MONO_B, pr.get_center(), str(int(round(_points_shown))), 22, ScPal.GILT_LIGHT)


func _counts_ink() -> bool:
	if wake or view == null or view.tool.side == ScCodes.Side.RECEIVE:
		return false
	return _stage_tool in ["bindery", "code_board", "living_tree", "ruler", "window", "stampcase"] and \
		not (_stage_tool == "code_board" and str(view.stage.get("mode", "")) == "cuts") and _stage_opt >= 0


func _draw_wake_hud(c: CanvasItem) -> void:
	# rondetijd als brandende lont; levens als kaarsjes
	var fr := clampf(_burn / _burn_max, 0.0, 1.0)
	var bar := Rect2(560, 22, 420, 38)
	c.draw_style_box(ScPal.sb(ScPal.SLOT, 19), bar)
	var col := ScPal.FLAME if fr > 0.25 else ScPal.FLAME_OUT
	if fr > 0.0:
		c.draw_style_box(ScPal.sb(col, 19), Rect2(bar.position, Vector2(maxf(38, bar.size.x * fr), bar.size.y)))
	ScPal.text_c(c, ScPal.MONO_B, bar.get_center(), "%.1f s" % maxf(0.0, _burn), 22, ScPal.INK)
	for i in 3:
		ScDraw.tool_icon(c, Vector2(1010 + i * 44, 41), 14, "candle", ScPal.FLAME if i < _lives else ScPal.TEXT_DIM, t)
	var pr := Rect2(1160, 18, 200, 46)
	c.draw_style_box(ScPal.sb(ScPal.PANEL_LO, 23), pr)
	ScPal.text_c(c, ScPal.MONO_B, pr.get_center(), "%d" % int(round(_points_shown)), 28, ScPal.GILT_LIGHT)
	if _combo > 1:
		var cr := Rect2(1376, 18, 110, 46)
		c.draw_style_box(ScPal.sb(Color(ScPal.FLAME_OUT, 0.35 + 0.15 * sin(t * 8.0)), 23), cr)
		ScPal.text_c(c, ScPal.MONO_B, cr.get_center(), "×%d" % _combo, 28, ScPal.FLAME_CORE)
	ScDraw.pill(c, Rect2(1500, 20, 120, 42), "twine", str(int(_counters.twine)), t)
	ScDraw.pill(c, Rect2(1630, 20, 120, 42), "dove", "%d" % (director.rounds if director else 0), t)

func _draw_band() -> void:
	var c := band_n
	_draw_zeno(c)
	if _band.is_empty() or wake and _band.get("text", "") == "":
		return
	var label := str(_band.get("label", "Opdracht"))
	ScPal.text_l(c, ScPal.TITLE, Vector2(30, 140), label, 26, ScPal.GILT_LIGHT)
	var txt := str(_band.get("text", ""))
	var n := maxi(txt.length(), 1)
	var cell := 58.0
	var size := 44
	if n > 18:
		cell = clampf(1060.0 / n, 34.0, 58.0)
		size = int(clampf(cell * 0.72, 24, 44))
	if txt != "":
		ScDraw.task_band(c, Vector2(170, 146), txt, cell, size, int(_band.get("cursor", -1)), int(_band.get("done", -1)),
			bool(_band.get("idx", true)), str(_band.get("alphabet", "")), bool(_band.get("chips", false)), t)
	var note := str(_band.get("note", ""))
	var nx := 170.0 + n * cell + 70.0 if txt != "" else 170.0
	if note != "" and nx + ScPal.text_w(ScPal.UI_MED, note, 20) < 1250.0:
		ScPal.text_l(c, ScPal.UI_MED, Vector2(nx, 146), note, 20, ScPal.TEXT)


func _draw_deco() -> void:
	var c := deco
	# De Overkant
	if not wake:
		var ov := OV_RECT
		ScPal.ring(c, ov.grow(4), 10, ScPal.GILT_DARK, 6)
		ScPal.ring(c, ov.grow(1), 8, ScPal.GILT, 2)
		var recv := view != null and view.tool.side == ScCodes.Side.RECEIVE
		_caption(c, ov.position + Vector2(18, 16), "De Overkant", ScSession.house(spec.chapter) + (" · afzender" if recv else ""))
		if view:
			view.draw_overkant(c, Rect2(ov.position.x + 14, ov.position.y + 70, ov.size.x - 28, 250))
		var mood := _letterlijk_mood
		ScDraw.letterlijk(c, Vector2(1600, 700), 0.86, t, mood, _letterlijk_talk * (0.5 + 0.5 * sin(t * 14.0)))
		var copy := view.overkant_copy() if view else ""
		if copy != "" or not recv:
			var pr := Rect2(ov.position.x + 24, 772, ov.size.x - 48, 92)
			ScDraw.parchment(c, pr, 77, ScPal.VELLUM, true, 0.5)
			ScPal.text_l(c, ScPal.UI_MED, pr.position + Vector2(16, 18), "Letterlijk leest:" if not recv else "", 16, ScPal.INK_SOFT)
			var fs := ScPal.fit_word(maxi(copy.length(), 1), pr.size.x - 40, 34, 18)
			if copy != "":
				ScPal.word(c, Vector2(pr.get_center().x, pr.position.y + 58), copy, fs, false)
	# kortschrift-paneel
	ScDraw.leather(c, Rect2(12, 892, 1896, 182), 18)
	var recv2 := view != null and view.tool.side == ScCodes.Side.RECEIVE
	ScPal.text_l(c, ScPal.TITLE, Vector2(44, 930), "Binnengekomen kortschrift" if recv2 else "Kortschrift", 28, ScPal.GILT_LIGHT)
	ScDraw.parchment(c, STRIP_RECT, 5, ScPal.VELLUM, false, 0.6)
	if _counts_ink() and _stage_opt > 0:
		ScPal.text_l(c, ScPal.UI_MED, Vector2(1300, 930), "koker van de duif (optimum %d)" % _stage_opt, 18, ScPal.TEXT_DIM)
		var fill := float(_counters.ink) / float(_stage_opt) if _stage_opt > 0 else 0.0
		ScDraw.koker(c, Vector2(1300, 962), 300, fill, t)
	# kaars (werkbank) en Zeno
	if wake:
		_draw_wake_side(c)



func _caption(c: CanvasItem, pos: Vector2, title: String, sub := "") -> void:
	var w := ScPal.text_w(ScPal.TITLE, title, 28) + (ScPal.text_w(ScPal.UI_MED, sub, 18) + 24 if sub != "" else 0.0) + 40
	var r := Rect2(pos, Vector2(w, 44))
	c.draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.92), 22, 8, Vector2(0, 4)), r)
	ScPal.ring(c, r.grow(-4), 18, Color(ScPal.GILT, 0.6), 1)
	var x := ScPal.text_l(c, ScPal.TITLE, pos + Vector2(20, 22), title, 28, ScPal.GILT_LIGHT)
	if sub != "":
		ScPal.text_l(c, ScPal.UI_MED, pos + Vector2(20 + x + 18, 23), sub, 18, ScPal.TEXT_DIM)


func _draw_zeno(c: CanvasItem) -> void:
	if _zeno_a <= 0.01:
		return
	var zp := Vector2(1214, 198)
	c.draw_set_transform(Vector2(0, (1.0 - _zeno_a) * -30))
	ScDraw.zeno(c, zp, 0.6, t, (0.5 + 0.5 * sin(t * 12.0)) if t < _zeno_until - 0.6 else 0.0, -1.0)
	var fsz := 22
	var w := ScPal.text_w(ScPal.UI, _zeno_text, fsz) + 60
	var r := Rect2(zp.x - 64 - w, 96, w, 58)
	ScDraw.scroll(c, r, zp + Vector2(-46, -50))
	ScPal.text_l(c, ScPal.UI, r.position + Vector2(30, 30), _zeno_text, fsz, Color(ScPal.INK, _zeno_a))
	c.draw_set_transform(Vector2.ZERO)


func _draw_wake_side(c: CanvasItem) -> void:
	# kandelaar met drie kaarsen: de levens; de brandende kaars brandt op met de rondetijd
	var base := Vector2(1600, 820)
	c.draw_rect(Rect2(base + Vector2(-190, 0), Vector2(380, 16)), ScPal.BRASS_DARK)
	c.draw_rect(Rect2(base + Vector2(-12, 0), Vector2(24, 90)), ScPal.BRASS_DARK)
	ScDraw.ellipse(c, base + Vector2(0, 96), 90, 16, ScPal.BRASS)
	for i in 3:
		var lit := i < _lives
		var burn := 1.0
		if i == _lives - 1:
			burn = clampf(_burn / _burn_max, 0.05, 1.0)
		ScDraw.candle(c, base + Vector2((i - 1) * 150, 0), 1.0, t + i, lit, burn if lit else 0.12,
			_flare if i == _lives - 1 else 0.0, 150)
	# beste nachten
	var r := Rect2(1310, 210, 580, 300)
	ScDraw.parchment(c, r, 15, ScPal.VELLUM_AGED, true, 0.8)
	ScPal.text_l(c, ScPal.TITLE, r.position + Vector2(28, 40), "Beste nachten", 32, ScPal.INK)
	var hs := ScSave.highscores()
	for i in mini(hs.size(), 5):
		var h: Dictionary = hs[i]
		ScPal.text_l(c, ScPal.MONO_B, r.position + Vector2(30, 90 + i * 38), "%d  %-3s  %6d" % [i + 1, str(h.name), int(h.score)], 22, ScPal.INK)
	if hs.is_empty():
		ScPal.text_l(c, ScPal.UI, r.position + Vector2(30, 92), "Nog geen nachten bewaakt.", 22, ScPal.INK_SOFT)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(1320, 540), "Bind voor de kaars opbrandt. Een verkeerd paar knapt het touw.", 18, ScPal.TEXT)
