class_name LessonCoach
extends Node
## Leerpad in het depot (design/LEARNING_PATH_hashdash.md): één les = één deel in één fase.
##  - Kijk: de chef speelt het orakel (correct_move) af. Vóór elke stap staat de wereld stil, licht het juiste element
##    op en toont het chefpaneel wat + waarom. Volgende stap / Afspelen / Overslaan. Voorspelvragen op sleutelmomenten.
##  - Samen: de speler doet het zelf. Tip vanzelf bij de eerste 2 stappen van elke soort, daarna enkel op vraag (Hint).
##    Een foute zet wordt niet uitgevoerd (depot._guard → allow): uitleg + herkansing.
## Teksten en antwoorden komen uit HDLessons (afgeleid van het model, dus altijd juist).

const ZOOM := 0.84
const PANEL_RECT := Rect2(20, 884, 1880, 190)
const C_OK := "#3DDC97"
const C_ERR := "#FF5A5F"
const C_DIM := "#8D97B5"
const C_WARN := "#FFB020"

var depot          # depot.gd
var part_id := ""
var phase := "kijk"
var focus: Dictionary = {}          # {kind: hatch|lever|saw|side|bin|parcel, idx|bid|side|pid}

var P: Dictionary
var cfg: Dictionary
var forced := true
var autoplay := false
var auto_answer := false
var demo := false

var _state := "intro"               # intro | wait | step | ask | play | done
var _mv: Dictionary = {}
var _ctx: Dictionary = {}
var _count := {}                    # actie -> aantal keer (voorspelvragen, fading)
var _cool := 0.0
var _auto_t := 0.0
var _note := ""
var _split_note := ""
var _q: Dictionary = {}
var _q_done := false
var _mistakes := 0
var _step_wrong := 0
var _sig := ""
var _steps := 0
var _cost := Vector3i(-1, 0, 0)     # (pakje-id, L bij start, S bij start)
var _answers := 0
var _demo_t := 0.0
var _demo_wrong_done := {}
var _t := 0.0

var _layer: CanvasLayer
var _panel: PanelContainer
var _tag: Label
var _text: RichTextLabel
var _right: VBoxContainer
var _opts: GridContainer
var _next_btn: Button
var _play_btn: Button
var _skip_btn: Button
var _hint_btn: Button
var _go_btn: Button
var _ring: Node2D
var _face: Control


# ======================================================================
#  opbouw
# ======================================================================

func start() -> void:
	P = HDLessons.part(part_id)
	cfg = P.get(phase, {})
	forced = not HDLessons.is_done(part_id, phase)
	autoplay = Game.cmd.has("autoplay")
	auto_answer = Game.cmd.has("auto-answer") or Game.cmd.has("lesson-demo")
	demo = Game.cmd.has("lesson-demo")
	# ruimte voor het chefpaneel onderaan: camera iets uitzoomen, bovenkant blijft staan
	depot.cam.position = Vector2(960, 540.0 / ZOOM)
	Juice.base_zoom = ZOOM
	var fill := ColorRect.new()
	fill.color = Pal.BG_DEEP
	fill.position = Vector2(-800, -600)
	fill.size = Vector2(3600, 2400)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depot.add_child(fill)
	depot.move_child(fill, 0)
	_ring = Node2D.new()
	_ring.z_index = 66
	_ring.draw.connect(_draw_ring)
	depot.world.add_child(_ring)
	_build_ui()
	var m: ExtHashModel = depot.model
	m.parcel_placed.connect(_on_placed)
	m.split_finished.connect(_on_split_finished)
	depot.lesson_hold = true
	_show_intro()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 12
	add_child(_layer)
	_panel = PanelContainer.new()
	var sb := Pal.sbn(Color(Pal.PANEL, 0.97), 24, 18, Vector2(0, 8))
	sb.border_color = Pal.WARN
	sb.border_width_top = 6
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_layer.add_child(_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	_panel.add_child(hb)
	_face = Control.new()
	_face.custom_minimum_size = Vector2(112, 150)
	_face.draw.connect(_draw_face)
	hb.add_child(_face)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	hb.add_child(mid)
	_tag = UIKit.label("", 20, Pal.WARN, Pal.UI_BOLD)
	mid.add_child(_tag)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_override("normal_font", Pal.UI)
	_text.add_theme_font_override("bold_font", Pal.UI_BOLD)
	_text.add_theme_font_override("mono_font", Pal.MONO)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		_text.add_theme_font_size_override(k, 25)
	_text.add_theme_color_override("default_color", Pal.TEXT)
	_text.add_theme_constant_override("line_separation", 2)
	mid.add_child(_text)
	_right = VBoxContainer.new()
	_right.custom_minimum_size = Vector2(600, 0)
	_right.alignment = BoxContainer.ALIGNMENT_CENTER
	_right.add_theme_constant_override("separation", 10)
	hb.add_child(_right)
	_opts = GridContainer.new()
	_opts.columns = 2
	_opts.add_theme_constant_override("h_separation", 10)
	_opts.add_theme_constant_override("v_separation", 8)
	_right.add_child(_opts)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	_right.add_child(row)
	_next_btn = _btn("Volgende stap", Pal.OK, Pal.INK, _on_next)
	_play_btn = _btn("Afspelen", Pal.PANEL_HI, Pal.TEXT, _toggle_play)
	_hint_btn = _btn("Hint  (H)", Pal.INFO, Pal.INK, _on_hint)
	_skip_btn = _btn("Overslaan", Pal.PANEL_HI, Pal.TEXT, _on_skip)
	_go_btn = _btn("Start", Pal.OK, Pal.INK, _on_go)
	for b in [_hint_btn, _play_btn, _skip_btn, _next_btn, _go_btn]:
		row.add_child(b)
	_set_buttons()


func _btn(t: String, col: Color, fg: Color, cb: Callable) -> Button:
	var b := UIKit.button(t, col, fg, 24, 0)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _set_buttons() -> void:
	var kijk := phase == "kijk"
	_go_btn.visible = _state in ["intro", "done"]
	_go_btn.text = "Start" if _state == "intro" else "Verder"
	_next_btn.visible = kijk and _state == "step"
	_play_btn.visible = kijk and _state in ["step", "wait"]
	_play_btn.text = "Stop afspelen" if autoplay else "Afspelen"
	_hint_btn.visible = not kijk and _state == "play"
	_skip_btn.visible = not forced and _state != "done"
	_opts.visible = _state == "ask"


func _set_tag() -> void:
	var nr := HDLessons.index_of_part(part_id) + 1
	var t := "%s  ·  deel %d van %d: %s" % ["KIJK" if phase == "kijk" else "SAMEN", nr, HDLessons.PARTS.size(), P.get("title", "")]
	if _steps > 0 and _state != "done":
		t += "  ·  stap %d" % _steps
	if phase == "samen" and _mistakes > 0:
		t += "  ·  %d fout%s" % [_mistakes, "" if _mistakes == 1 else "en"]
	_tag.text = t


func _say(bb: String) -> void:
	_text.text = bb
	_set_tag()
	_set_buttons()
	_face.queue_redraw()


# ======================================================================
#  intro / einde
# ======================================================================

func _show_intro() -> void:
	_state = "intro"
	var rule := str(P.get("rule", ""))
	if phase == "kijk":
		var idea := str(P.get("idea", ""))
		_say("[b]Kijk mee: %s.[/b] De chef doet het voor, stap voor stap.%s\n[color=%s]Regel:[/color] %s\nKlik telkens op [b]Volgende stap[/b] (of Spatie). Soms vraag ik eerst wat jij denkt." % [P.title, (" " + idea) if idea != "" else "", C_WARN, rule])
	else:
		_say("[b]Nu jij: %s.[/b] Doe elke stap zelf; een foute zet leg ik uit en je mag opnieuw.\n[color=%s]Regel:[/color] %s\nWeet je het niet? [b]Hint[/b] (H) laat zien waar het moet." % [P.title, C_WARN, rule])
	if autoplay or demo or Game.cmd.has("lesson"):
		get_tree().create_timer(2.6).timeout.connect(func():
			if _state == "intro":
				_on_go())


func _on_go() -> void:
	if _state == "intro":
		_state = "wait"
		_cool = 0.3
		depot.lesson_hold = false
		_say("")
	elif _state == "done":
		Game.lesson_done()


func on_finished(_report: Dictionary) -> void:
	_finish_cost()
	_state = "done"
	focus = {}
	depot.lesson_hold = true
	HDLessons.mark(part_id, phase)
	var rule := str(P.get("rule", ""))
	if _note == "Goed!":
		_note = ""   # niet "Goed gedaan ...! Goed!"
	if _split_note != "":
		_note = _split_note
		_split_note = ""
	var t := ""
	if phase == "kijk":
		t = "[b]Dat was deel %d: %s.[/b] %s\n[color=%s]Regel:[/color] %s\nNu oefen je het zelf, met hulp als je wil." % [HDLessons.index_of_part(part_id) + 1, P.title, _note, C_WARN, rule]
	else:
		var f := "zonder fouten" if _mistakes == 0 else ("met %d fout%s (die je zelf verbeterde)" % [_mistakes, "" if _mistakes == 1 else "en"])
		t = "[b]Goed gedaan, %s![/b] %s\n[color=%s]Regel:[/color] %s\nStraks op dag %d doe je dit helemaal alleen; daarna volgen 1–2 controlevragen." % [f, _note, C_WARN, rule, int(P.day)]
	_note = ""
	_say(t)
	Sfx.play("sfx/day_complete.wav", -8.0, 1.0, false)
	if Game.cmd.has("quit-after-day"):
		print("LESSON_DONE %s %s stappen=%d fouten=%d a=%d %s" % [part_id, phase, _steps, _mistakes, depot.model.a, depot.model.describe()])
		get_tree().quit()
		return
	if autoplay or demo:
		get_tree().create_timer(4.0).timeout.connect(func():
			if _state == "done":
				_on_go())


func _on_skip() -> void:
	if forced:
		return
	Game.lesson_done()


# ======================================================================
#  hoofdlus
# ======================================================================

func blocks_input() -> bool:
	return phase == "kijk" or _state in ["intro", "ask", "done"]


func _busy() -> bool:
	return depot._lock or depot._running or depot.drag_view != null or depot._ending or depot.finished


func _process(delta: float) -> void:
	_t += delta
	_ring.queue_redraw()
	_face.queue_redraw()
	if _state in ["intro", "done"] or depot.paused:
		return
	_cool -= delta
	if phase == "kijk":
		_kijk_tick(delta)
	else:
		_samen_tick(delta)
	if auto_answer and _state == "ask" and not _q_done:
		_auto_t -= delta
		if _auto_t <= 0.0:
			var corr: Array = _q.correct
			var pick: int = int(corr[0])
			if _answers == 0:
				for i in (_q.options as Array).size():
					if not corr.has(i):
						pick = i
						break
			_answer(pick)


## De volgende zet die nu aan de beurt is (klanten eerst, zoals de bot), of {} (wachten).
func _next_move() -> Dictionary:
	var m: ExtHashModel = depot.model
	var dd = depot.director
	if m.splitting.is_empty():
		for c in dd.customers():
			var cid := int(c.id)
			if depot.cust_busy.has(cid) or not depot.cust_views.has(cid):
				continue
			if float(dd.time) - float(c.t) < 0.6:
				return {}
			return {"action": "serve", "cid": cid, "hv": int(c.hv), "dir_index": m.index_of(int(c.hv))}
	if not m.splitting.is_empty():
		var tb: SortTable = depot.table
		if tb.visible and not tb.mid.is_empty() and not (tb.front() as ParcelView).has_meta("anim"):
			var cm := m.correct_move()
			if cm.action == "assign":
				return cm
		return {}
	var fv: ParcelView = depot._front_view()
	var front: Parcel = depot._front_parcel()
	var ready: bool = fv != null and front != null and fv.pid == front.id and not fv.has_meta("anim")
	if ready and phase == "kijk" and m.blocked.is_empty() and dd.belt_progress(front.id) < 0.8:
		ready = false   # laat het pakje eerst tot vooraan rollen
	var mv := m.correct_move(front if ready else null)
	match str(mv.action):
		"none":
			return {}
		"retry":
			m.retry_blocked()
			return {}
		"finish":
			m.finish_split()
			return {}
		"drop":
			if not ready:
				return {}
			mv["parcel"] = front
		"dump":
			var pid := int(mv.parcel_id)
			mv["parcel"] = _parcel_by_id(pid)
	return mv


func _parcel_by_id(pid: int) -> Parcel:
	var m: ExtHashModel = depot.model
	for e in m.blocked:
		if (e.parcel as Parcel).id == pid:
			return e.parcel
	for q in depot.director.belt():
		if q.id == pid:
			return q
	return null


func _ctx_for(mv: Dictionary) -> Dictionary:
	var c := {"cost": bool(cfg.get("cost", false))}
	if mv.has("parcel") and mv.parcel != null:
		c["parcel"] = mv.parcel
		c["hv"] = (mv.parcel as Parcel).hv
	if mv.has("hv"):
		c["hv"] = int(mv.hv)
	return c


func _ask_for(act: String, n: int) -> String:
	for a in cfg.get("ask", []):
		if str(a.on) == act and int(a.nth) == n:
			return str(a.q)
	return ""


# ---------------------------------------------------------------- Kijk
func _kijk_tick(delta: float) -> void:
	match _state:
		"wait":
			if _busy() or _cool > 0.0:
				return
			_track_cost()
			var mv := _next_move()
			if mv.is_empty():
				depot.lesson_hold = false   # laat de band/klanten lopen
				return
			_show_step(mv)
		"step":
			if autoplay:
				_auto_t -= delta
				if _auto_t <= 0.0:
					_on_next()


func _show_step(mv: Dictionary) -> void:
	depot.lesson_hold = true
	_mv = mv
	_ctx = _ctx_for(mv)
	var act := str(mv.action)
	_count[act] = int(_count.get(act, 0)) + 1
	_steps += 1
	var qk := _ask_for(act, int(_count[act]))
	if qk != "":
		var q := HDLessons.predict(depot.model, qk, mv, _ctx)
		if not q.is_empty():
			_ask(q)
			return
	focus = _focus_for(mv)
	_show_narration("")


func _show_narration(prefix: String) -> void:
	var n := HDLessons.narrate(depot.model, _mv, _ctx)
	var t := ""
	if _split_note != "":
		t += "[color=%s]%s[/color]\n" % [C_OK, _split_note]
		_split_note = ""
		_note = ""   # "past nu in ..." zie je ook op de band; anders past het paneel niet
	if _note != "":
		t += "[color=%s]%s[/color]\n" % [C_DIM, _note]
		_note = ""
	if prefix != "":
		t += prefix + "\n"
	t += "[b]%s[/b]\n%s" % [n.what, n.why]
	_state = "step"
	_auto_t = 3.0 + _plain(t).length() / 32.0
	_say(t)


func _plain(bb: String) -> String:
	var r := RegEx.new()
	r.compile("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	return r.sub(bb, "", true)


func _on_next() -> void:
	if phase != "kijk" or _state != "step":
		return
	_execute(_mv)


func _toggle_play() -> void:
	autoplay = not autoplay
	_auto_t = 0.8
	_set_buttons()


func _execute(mv: Dictionary) -> void:
	_state = "wait"
	focus = _focus_for(mv)
	_cool = 1.1
	var m: ExtHashModel = depot.model
	match str(mv.action):
		"drop":
			var p: Parcel = mv.parcel
			_start_cost(p)
			depot.lesson_hold = false
			depot._bot_type(HashUtil.bits(int(mv.dir_index), m.a))
			_cool = 1.6
		"double", "fail":
			depot._pull_lever()
			_cool = 1.3
		"split":
			depot._try_split(int(mv.bucket_id))
		"assign":
			depot._do_assign(int(mv.parcel_id), int(mv.side))
			_cool = 0.8
		"serve":
			depot.lesson_hold = false
			depot._serve(int(mv.dir_index), int(mv.cid))
			_cool = 1.4
		"dump":
			_do_dump(int(mv.parcel_id))
	_set_buttons()
	get_tree().create_timer(0.9).timeout.connect(func():
		if _state == "wait":
			focus = {})


func _do_dump(pid: int) -> void:
	var m: ExtHashModel = depot.model
	for e in m.blocked:
		if (e.parcel as Parcel).id == pid:
			depot._dump_blocked(pid)
			return
	depot._dump_belt(pid)


# ---------------------------------------------------------------- Samen
func _samen_tick(delta: float) -> void:
	if _state == "ask":
		return
	if demo:
		_demo_tick(delta)
	if _busy() or _cool > 0.0:
		return
	_track_cost()
	var mv := _next_move()
	if mv.is_empty():
		if _state != "wait":
			_state = "wait"
			_sig = ""
			focus = {}
			if _note != "":
				_say("[color=%s]%s[/color]" % [C_DIM, _note])
		return
	var sig := _signature(mv)
	if sig == _sig:
		return
	_sig = sig
	_mv = mv
	_ctx = _ctx_for(mv)
	var act := _kind(str(mv.action))
	_count[act] = int(_count.get(act, 0)) + 1
	_steps += 1
	_step_wrong = 0
	focus = {}
	_demo_t = 0.0
	if str(mv.action) == "drop" and str(cfg.get("ask_each", "")) != "":
		_start_cost(mv.parcel)
		var q := HDLessons.predict(depot.model, str(cfg.ask_each), mv, _ctx)
		if not q.is_empty():
			_ask(q)
			return
	if str(mv.action) == "drop":
		_start_cost(mv.parcel)
	_prompt("")


func _kind(act: String) -> String:
	return "zet" if act in ["double", "split", "fail"] else act


func _signature(mv: Dictionary) -> String:
	var m: ExtHashModel = depot.model
	var s := str(mv.action)
	match s:
		"drop", "dump":
			s += str((mv.parcel as Parcel).id if mv.get("parcel") else mv.get("parcel_id", -1))
		"assign":
			s += str(mv.parcel_id)
		"serve":
			s += str(mv.cid)
	return s + ":%d:%d:%d" % [m.a, m.buckets.size(), m.blocked.size()]


func _prompt(prefix: String) -> void:
	_state = "play"
	var m: ExtHashModel = depot.model
	var t := ""
	if _split_note != "":
		t += "[color=%s]%s[/color]\n" % [C_OK, _split_note]
		_split_note = ""
		_note = ""
	if _note != "":
		t += "[color=%s]%s[/color]  " % [C_OK, _note]
		_note = ""
	if prefix != "":
		t += prefix + "\n"
	t += "[b]Jouw beurt:[/b] " + _what_now(m, _mv)
	var act := _kind(str(_mv.action))
	if int(_count.get(act, 0)) <= 2:
		t += "\n[color=%s]Tip:[/color] %s" % [C_WARN, HDLessons.tip(m, _mv, _ctx)]
	else:
		t += "\n[color=%s]Weet je het niet? Hint (H).[/color]" % C_DIM
	_say(t)


func _what_now(m: ExtHashModel, mv: Dictionary) -> String:
	match str(mv.action):
		"drop":
			return "door welk luik moet pakje %s?" % HDLessons.code(HDLessons.bitstr(m, (mv.parcel as Parcel).hv))
		"double", "split", "fail":
			return "er zit een pakje vast in de buis van %s. Hendel of zaag?" % HDLessons.rack(m, HDLessons._blocked_bucket(m))
		"assign":
			var p := HDLessons._pending(m, int(mv.parcel_id))
			return "sorteertafel: %s naar links of naar rechts?" % HDLessons.code(HDLessons.bitstr(m, p.hv))
		"serve":
			return "een klant zoekt %s. Klik het juiste luik." % HDLessons.code(HDLessons.bitstr(m, int(mv.hv)))
		"dump":
			return "pakje %s zit vast. Wat nu?" % HDLessons.code(HDLessons.bitstr(m, (mv.parcel as Parcel).hv))
	return ""


func _on_hint() -> void:
	if phase != "samen" or _state != "play" or _mv.is_empty():
		return
	focus = _focus_for(_mv)
	var m: ExtHashModel = depot.model
	var n := HDLessons.narrate(m, _mv, _ctx)
	_say("[b]Hint:[/b] %s\n[color=%s]%s[/color]" % [n.what, C_DIM, n.why])
	Sfx.play("sfx/kenney/ui_open.ogg", -8.0)


## Depot vraagt toestemming voor een spelerszet (Samen). Fout -> uitleg, zet gaat niet door.
func allow(kind: String, data: Dictionary) -> bool:
	if phase == "kijk":
		return true
	if _state in ["ask", "done", "intro"]:
		return false
	var m: ExtHashModel = depot.model
	var cm := m.correct_move()
	var ok := false
	match kind:
		"drop":
			var p: Parcel = data.parcel
			cm = m.correct_move(p)
			ok = cm.action == "drop" and m.dir[int(data.idx)] == m.dir[m.index_of(p.hv)]
		"double":
			ok = cm.action in ["double", "fail"]
		"split":
			ok = cm.action == "split" and int(cm.bucket_id) == int(data.bid)
		"assign":
			ok = int(data.side) == m.correct_side(data.parcel)
		"serve":
			ok = int(data.hv) >= 0 and m.dir[int(data.idx)] == m.dir[m.index_of(int(data.hv))]
		"dump":
			var p := _parcel_by_id(int(data.pid))
			if not m.blocked.is_empty():
				ok = cm.action == "dump" and int(cm.parcel_id) == int(data.pid)
			else:
				ok = p != null and m.allow_dump and m.is_clone_overflow(p.hv)
	if ok:
		_note = "Goed!"
		focus = {}
		_cool = 0.6
		return true
	_mistakes += 1
	_step_wrong += 1
	if kind == "serve":
		data["hv"] = int(data.hv)
	var ex := HDLessons.explain_wrong(m, kind, data, cm)
	var t := "[color=%s][b]Nog niet.[/b][/color] %s\n[b]Probeer opnieuw.[/b]" % [C_ERR, ex]
	if _step_wrong >= 2 and not _mv.is_empty():
		focus = _focus_for(_mv)
		t += " [color=%s]Het juiste element licht op.[/color]" % C_DIM
	_say(t)
	Juice.shake(3.0, 0.15)
	return false


# ---------------------------------------------------------------- voorspelvragen
func _ask(q: Dictionary) -> void:
	_q = q
	_q_done = false
	_state = "ask"
	focus = {}
	depot.lesson_hold = true
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = q.options
	_opts.columns = 2 if opts.size() > 1 else 1
	for i in opts.size():
		var b := UIKit.button("%d   %s" % [i + 1, opts[i]], Pal.PANEL_HI, Pal.TEXT, 22, 290)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_answer.bind(i))
		_opts.add_child(b)
	var t := ""
	if _note != "":
		t += "[color=%s]%s[/color]\n" % [C_DIM, _note]
		_note = ""
	t += "[color=%s][b]Voorspel![/b][/color] %s" % [C_WARN, str(q.q).trim_prefix("Voorspel: ")]
	_auto_t = 2.5
	_say(t)
	Sfx.play("sfx/kenney/ui_open.ogg", -6.0)


func _answer(i: int) -> void:
	if _state != "ask" or _q_done:
		return
	_q_done = true
	_answers += 1
	var right: bool = (_q.correct as Array).has(i)
	var kids := _opts.get_children()
	for k in kids.size():
		var b: Button = kids[k]
		b.disabled = true
		var col := Pal.PANEL_LO
		if (_q.correct as Array).has(k):
			col = Pal.OK
		elif k == i:
			col = Pal.ERR
		b.add_theme_stylebox_override("disabled", UIKit._btn_box(col))
		b.add_theme_color_override("font_disabled_color", Pal.INK if col != Pal.PANEL_LO else Pal.TEXT_DIM)
	Sfx.play("sfx/star_1.wav" if right else "sfx/mistake.wav", -6.0, 1.0, false)
	var fb := ("[color=%s][b]%s[/b][/color]" % [C_OK, _q.right]) if right else ("[color=%s][b]Niet juist. [/b][/color] %s" % [C_ERR, _q.wrong])
	if not right and phase == "samen":
		_mistakes += 1
	await get_tree().create_timer(0.9 if right else 1.6).timeout
	if _state != "ask":
		return
	_opts.visible = false
	for ch in _opts.get_children():
		ch.queue_free()
	if phase == "kijk":
		focus = _focus_for(_mv)
		_show_narration(fb)
		_auto_t += 1.5
	else:
		depot.lesson_hold = false
		_prompt(fb + " Doe het nu zelf; kijk daarna naar de teller L / S rechtsboven.")


# ---------------------------------------------------------------- kost (deel 4)
func _start_cost(p: Parcel) -> void:
	if not bool(cfg.get("cost", false)) or p == null:
		return
	_finish_cost()
	var m: ExtHashModel = depot.model
	_cost = Vector3i(p.id, m.reads, m.writes)


func _track_cost() -> void:
	if _cost.x < 0:
		return
	var m: ExtHashModel = depot.model
	if m.blocked.is_empty() and m.splitting.is_empty() and not _is_on_belt(_cost.x):
		_finish_cost()


func _finish_cost() -> void:
	if _cost.x < 0:
		return
	var m: ExtHashModel = depot.model
	var hv := -1
	for p in m.all_parcels():
		if p.id == _cost.x:
			hv = p.hv
	var who := HDLessons.code(HDLessons.bitstr(m, hv)) if hv >= 0 else "het pakje"
	_note = "Totaal voor %s: %s (teller rechtsboven)." % [who, HDLessons.cost_label(m.reads - _cost.y, m.writes - _cost.z)]
	_cost = Vector3i(-1, 0, 0)


func _is_on_belt(pid: int) -> bool:
	for q in depot.director.belt():
		if q.id == pid:
			return true
	return false


func _on_placed(parcel: Parcel, bid: int, _idx: int, _v: int) -> void:
	var m: ExtHashModel = depot.model
	if m.log.entries.is_empty() or m.log.entries[-1].type != "RETRY":
		return
	if _note == "" or _note == "Goed!":
		_note = "Het vastzittende pakje %s past nu in %s." % [HDLessons.code(HDLessons.bitstr(m, parcel.hv)), HDLessons.rack(m, bid)]


func _on_split_finished(bid: int, nbid: int) -> void:
	_split_note = HDLessons.split_summary(depot.model, bid, nbid)


# ---------------------------------------------------------------- demo-speler (opnames: --lesson-demo)
func _demo_tick(delta: float) -> void:
	if _state != "play" or _busy() or _mv.is_empty():
		return
	_demo_t += delta
	var act := _kind(str(_mv.action))
	if _demo_t > 1.6 and _demo_t - delta <= 1.6 and int(_count.get(act, 0)) == 1:
		_on_hint()
	if _demo_t > 3.4 and _demo_t - delta <= 3.4 and not _demo_wrong_done.has(act):
		_demo_wrong_done[act] = true
		_demo_act(true)
	if _demo_t > 6.4:
		_demo_t = -100.0
		_demo_act(false)


func _demo_act(wrong: bool) -> void:
	var m: ExtHashModel = depot.model
	var mv := _mv
	match str(mv.action):
		"drop":
			var p: Parcel = mv.parcel
			var idx := int(mv.dir_index)
			if wrong:
				for j in m.dir.size():
					if m.dir[j] != m.dir[idx]:
						idx = j
						break
			depot._do_drop(p.id, idx, true)
		"double", "fail", "split":
			var dbl: bool = str(mv.action) != "split"
			if wrong:
				dbl = not dbl
			if dbl:
				depot._pull_lever()
			else:
				var bid := int(mv.get("bucket_id", HDLessons._blocked_bucket(m)))
				depot._try_split(bid)
		"assign":
			depot._do_assign(int(mv.parcel_id), (1 - int(mv.side)) if wrong else int(mv.side))
		"serve":
			var idx := int(mv.dir_index)
			if wrong:
				for j in m.dir.size():
					if m.dir[j] != m.dir[idx]:
						idx = j
						break
			depot._serve(idx, int(mv.cid))
		"dump":
			if wrong:
				depot._pull_lever()
			else:
				_do_dump(int(mv.parcel_id))
	if not wrong:
		_demo_t = 0.0


# ======================================================================
#  invoer
# ======================================================================

func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo) or get_tree().paused:
		return
	var k := (ev as InputEventKey).keycode
	var handled := false
	match k:
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if _state in ["intro", "done"]:
				_on_go()
				handled = true
			elif phase == "kijk" and _state == "step":
				_on_next()
				handled = true
		KEY_H:
			if phase == "samen" and _state == "play" and not (ev as InputEventKey).ctrl_pressed:
				_on_hint()
				handled = true
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4:
			if _state == "ask":
				var i := (k - KEY_1) if k <= KEY_4 else (k - KEY_KP_1)
				if i < (_q.get("options", []) as Array).size():
					_answer(i)
				handled = true
	if handled:
		get_viewport().set_input_as_handled()


# ======================================================================
#  oplichten (focus) en tekenen
# ======================================================================

func _focus_for(mv: Dictionary) -> Dictionary:
	var m: ExtHashModel = depot.model
	match str(mv.get("action", "")):
		"drop", "serve":
			return {"kind": "hatch", "idx": int(mv.dir_index)}
		"double", "fail":
			return {"kind": "lever"}
		"split":
			return {"kind": "saw", "bid": int(mv.bucket_id)}
		"assign":
			return {"kind": "side", "side": int(mv.side)}
		"dump":
			return {"kind": "bin"}
	return {}


func _focus_rect() -> Rect2:
	match str(focus.get("kind", "")):
		"hatch":
			var i := int(focus.idx)
			if i >= 0 and i < depot.hatches.size():
				var hv: HatchView = depot.hatches[i]
				return Rect2(hv.global_position - hv.size / 2.0, hv.size).grow(8)
		"lever":
			return Rect2(depot.lever.global_position, depot.lever.size).grow(8)
		"saw":
			var rv: RackView = depot.racks.get(int(focus.bid))
			if rv:
				return rv.saw_rect_global().grow(14)
		"side":
			var r: Rect2 = SortTable.LEFT if int(focus.side) == 0 else SortTable.RIGHT
			return Rect2(depot.table.global_position + r.position, r.size).grow(6)
		"bin":
			return Rect2(140, 640, 220, 300).grow(8)   # depot.BIN2
	return Rect2()


func _draw_ring() -> void:
	var r := _focus_rect()
	if r.size == Vector2.ZERO:
		return
	var k := 0.5 + 0.5 * sin(_t * 6.0)
	var col := Pal.INFO if phase == "samen" else Pal.WARN
	if str(focus.get("kind", "")) == "saw":
		# tel de luiken (2^(a − a_b)) die naar dit rek wijzen
		var m: ExtHashModel = depot.model
		for i in depot.hatches.size():
			if i < m.dir.size() and m.dir[i] == int(focus.bid):
				var hv: HatchView = depot.hatches[i]
				Pal.ring(_ring, Rect2(hv.global_position - hv.size / 2.0, hv.size).grow(5), 14, Color(col, 0.75), 4)
	Pal.ring(_ring, r.grow(4 + 6 * k), 18, Color(col, 0.35 + 0.4 * k), 10)
	Pal.ring(_ring, r, 16, col, 5)
	# pijltje boven het doel
	var tip := Vector2(r.position.x - 10 - 8 * k, r.get_center().y)
	_ring.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-26, -17), tip + Vector2(-26, 17)]), col)


func _draw_face() -> void:
	var o := _face
	var c := Vector2(56, 104)
	var bob := sin(_t * 2.4) * 2.0
	o.draw_circle(c + Vector2(0, bob), 44, Pal.OUTLINE, true, -1, true)
	o.draw_circle(c + Vector2(0, bob), 40, Pal.SKIN[1], true, -1, true)
	o.draw_style_box(Pal.sb(Pal.LABEL, 14), Rect2(c + Vector2(-32, -82 + bob), Vector2(64, 42)))
	o.draw_circle(c + Vector2(-12, -76 + bob), 20, Pal.LABEL, true, -1, true)
	o.draw_circle(c + Vector2(12, -78 + bob), 22, Pal.LABEL, true, -1, true)
	for ex in [-13.0, 13.0]:
		o.draw_circle(c + Vector2(ex, -2 + bob), 5, Pal.INK, true, -1, true)
	var happy := _state != "play" or _step_wrong == 0
	if happy:
		o.draw_arc(c + Vector2(0, 10 + bob), 14, 0.2, PI - 0.2, 12, Color("#3a2a20"), 5, true)
	else:
		o.draw_line(c + Vector2(-14, 18 + bob), c + Vector2(14, 18 + bob), Color("#3a2a20"), 5, true)
