class_name TxLessonCoach
extends Node
## Leerpad op de console (games/telex/design/LEARNING_PATH.md): één les = één deel in één fase, met Chef Ponsaert als
## verteller in een paneel rechts (in de stijl van het luisterstation).
##  - Kijk: de Chef speelt het orakel (correct_move) af. Vóór elke stap staat de machine stil, wijst de spookhand het
##    element aan en zegt het paneel wat + waarom; onderaan de toestand zoals je ze op het examen noteert (V[], V_H,
##    C_x, kolommen van M, d[i][j]). Volgende › / Afspelen / Overslaan. Voorspelvragen (Check in de wereld) op
##    sleutelmomenten, vóór de machine het toont.
##  - Samen: de speler doet het zelf (muis of toetsen, zoals in het spel). Tip vanzelf bij de eerste 2 zetten van elke
##    soort, daarna enkel op vraag (Hint of F2). Een foute zet wordt niet uitgevoerd (console.move -> allow): uitleg +
##    herkansing; na 2 fouten op dezelfde stap wijst de spookhand de juiste zet aan.
## Teksten en antwoorden komen uit TxLessons (afgeleid van de core, dus altijd juist).

const PANEL := Rect2(1376, 394, 536, 680)

var con                      # TxConsole
var part_id := ""
var phase := "kijk"
var P: Dictionary = {}
var cfg: Dictionary = {}
var forced := true
var autoplay := false
var auto_answer := false
var demo := false

var _state := "intro"        # intro | wait | step | ask | play | turn | done | left
var _group: Array = []       # Kijk: [{mv, mc}] van de huidige stap
var _queue: Array = []       # nog uit te voeren zetten van deze stap
var _mv: Dictionary = {}     # juiste zet (Samen) / eerste zet van de stap (Kijk)
var _count := {}
var _q: Dictionary = {}
var _q_done := false
var _q_after := ""           # "narrate" (Kijk) | "turn" (Samen)
var _auto_t := 0.0
var _mistakes := 0
var _step_wrong := 0
var _steps := 0
var _answers := 0
var _right := 0
var _exec := false
var _note := ""
var _demo_t := 0.0
var _demo_wrong := {}
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _ring_on := false
var _last_text := ""

var _layer: CanvasLayer
var _root: Control
var _panel: PanelContainer
var _tag: Label
var _title: Label
var _text: RichTextLabel
var _state_lbl: RichTextLabel
var _opts: VBoxContainer
var _row: HBoxContainer
var _next_btn: Button
var _play_btn: Button
var _skip_btn: Button
var _hint_btn: Button
var _go_btn: Button
var _face: Control
var _ring: Control


# ======================================================================
#  opbouw
# ======================================================================

func setup(console, part: String, ph: String) -> void:
	con = console
	part_id = part
	phase = ph
	P = TxLessons.part(part_id)
	cfg = TxLessons.cfg(part_id, phase)


func _ready() -> void:
	forced = not TxLessons.is_done(part_id, phase)
	autoplay = TxSession.has("autoplay")
	auto_answer = TxSession.has("auto_answer") or TxSession.has("lesson_demo")
	demo = TxSession.has("lesson_demo")
	_rng.seed = 11
	_build_ui()
	_show_intro()


func panel_rect() -> Rect2:
	return PANEL


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 11
	add_child(_layer)
	_root = Control.new()
	_root.size = Vector2(1920, 1080)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = TxPal.theme()
	_layer.add_child(_root)
	_ring = Control.new()
	_ring.size = Vector2(1920, 1080)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	_root.add_child(_ring)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(TxPal.CONSOLE_LO, 0.97)
	sb.border_color = TxPal.BRASS
	sb.set_border_width_all(2)
	sb.border_width_top = 6
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = TxPal.SHADOW
	sb.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = PANEL.position
	_panel.size = PANEL.size
	_panel.custom_minimum_size = PANEL.size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	_panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	vb.add_child(head)
	_face = Control.new()
	_face.custom_minimum_size = Vector2(92, 92)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.draw.connect(_draw_face)
	head.add_child(_face)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	_tag = TxUi.label("", 15, TxPal.BRASS, TxPal.STENCIL)
	_tag.clip_text = true
	_tag.custom_minimum_size = Vector2(390, 0)
	hv.add_child(_tag)
	_title = TxUi.label("", 23, TxPal.TEXT, TxPal.UI_BOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(390, 0)
	hv.add_child(_title)
	_text = _rich(20)
	_text.fit_content = false
	_text.scroll_active = true
	_text.scroll_following = false
	_text.custom_minimum_size = Vector2(PANEL.size.x - 40.0, 120)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_text)
	_opts = VBoxContainer.new()
	_opts.add_theme_constant_override("separation", 5)
	vb.add_child(_opts)
	var sep := ColorRect.new()
	sep.color = Color(TxPal.BRASS_LO, 0.6)
	sep.custom_minimum_size = Vector2(0, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sep)
	_state_lbl = _rich(16)
	_state_lbl.add_theme_color_override("default_color", TxPal.TEXT_DIM)
	vb.add_child(_state_lbl)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(_row)
	_skip_btn = _btn("Overslaan", "flat", _on_skip, 120)
	_hint_btn = _btn("Hint (F2)", "key", _on_hint, 130)
	_play_btn = _btn("Afspelen", "key", _toggle_play, 130)
	_next_btn = _btn("Volgende ›", "brass", _on_next, 150)
	_go_btn = _btn("Start", "brass", _on_go, 150)
	TxUi.pop_in(_panel, 0.25)


func _btn(t: String, kind: String, cb: Callable, w: float) -> Button:
	var b := TxUi.button(t, kind, 19, w)
	b.custom_minimum_size = Vector2(w, 46)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(cb)
	_row.add_child(b)
	return b


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(PANEL.size.x - 40.0, 0)
	r.add_theme_font_override("normal_font", TxPal.UI)
	r.add_theme_font_override("bold_font", TxPal.UI_BOLD)
	r.add_theme_font_override("mono_font", TxPal.MONO_B)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", TxPal.TEXT)
	r.add_theme_constant_override("line_separation", 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _set_buttons() -> void:
	var kijk := phase == "kijk"
	_go_btn.visible = _state == "intro" or _state == "done"
	_go_btn.text = "Verder ›" if _state == "done" else "Start"
	_next_btn.visible = (kijk and _state == "step") or (_state == "ask" and _q_done)
	if _state != "ask":
		_next_btn.text = "Volgende ›"
	_play_btn.visible = kijk and _state in ["step", "play", "wait"]
	_play_btn.text = "Pauze" if autoplay else "Afspelen"
	_hint_btn.visible = not kijk and _state == "turn"
	_skip_btn.visible = not forced and _state != "done" and _state != "left"


func _set_tag() -> void:
	var n := TxLessons.all_parts().size()
	_tag.text = "%s · DEEL %d VAN %d · %s" % ["KIJK" if phase == "kijk" else "SAMEN", TxLessons.index_of_part(part_id) + 1, n, str(P.page).to_upper()]
	_tag.tooltip_text = str(P.page)
	_title.text = str(P.title)


func _say(bb: String) -> void:
	_last_text = bb
	_text.text = TxLessons.bb(bb)
	var st := TxLessons.state(con.mc) if con != null and con.mc != null else ""
	_state_lbl.text = TxLessons.bb("[b]Toestand[/b]  " + st) if st != "" else ""
	_set_tag()
	_set_buttons()
	_face.queue_redraw()


func _show_intro() -> void:
	_state = "intro"
	var t := "[b]Regel[/b]: %s\n\n%s\n\n" % [P.rule, P.get("idea", "")]
	if phase == "kijk":
		t += "[color=%s]Ik doe het voor, stap voor stap: bij elke stap [b]wat[/b] ik doe en [b]waarom[/b]. Soms vraag ik eerst wat jij denkt. Klik [b]Volgende[/b] (of Spatie) of laat het [b]afspelen[/b].[/color]" % TxLessons.C_DIM
		if cfg.has("fig"):
			t += "\n[color=%s]Voorbeeld uit de notas: %s.[/color]" % [TxLessons.C_DIM, cfg.fig]
	else:
		t += "[color=%s]Nu jij, met dezelfde knoppen en muisklikken als in het spel. Eerst geef ik tips, later enkel op vraag (Hint of F2). Een foute zet voer ik niet uit: ik leg uit waarom en je probeert opnieuw.[/color]" % TxLessons.C_DIM
	if not forced:
		t += "\n[color=%s]Al gezien: overslaan mag.[/color]" % TxLessons.C_DIM
	_say(t)
	if autoplay or demo or TxSession.has("auto_answer"):
		_auto_t = 1.2


func _on_go() -> void:
	if _state == "intro":
		_state = "wait"
		_say("[color=%s]…[/color]" % TxLessons.C_DIM)
	elif _state == "done":
		_finish_lesson()


func _on_skip() -> void:
	_finish_lesson(true)


## De les is klaar (de director is klaar of until_phase bereikt): samenvatting + Verder.
func on_done() -> void:
	if _state == "done" or _state == "left":
		return
	_state = "done"
	_ring_on = false
	_queue = []
	var t := ""
	if _note != "":
		t += _note + "\n"
	t += "[color=%s][b]Klaar![/b][/color] " % TxLessons.C_OK
	if phase == "kijk":
		t += "Dat was de demo van [b]%s[/b]." % P.title
		if _answers > 0:
			t += " Voorspellingen: %d van %d juist." % [_right, _answers]
		t += "\n\n[b]Regel[/b]: %s\n\nNu doe je het zelf, samen met mij." % P.rule
	else:
		t += "Je deed %d stappen%s." % [_steps, (" met %d fout%s (telt niet mee)" % [_mistakes, "" if _mistakes == 1 else "en"]) if _mistakes > 0 else " zonder fouten"]
		if _answers > 0:
			t += " Vragen: %d van %d juist." % [_right, _answers]
		t += "\n\n[b]Regel[/b]: %s\n\nZelf oefen je dit (zonder hulp) in level %s." % [P.rule, ", ".join(P.levels)]
	_say(t)
	TxSnd.play("stamp", -6.0)
	if autoplay or demo or TxSession.has("auto_answer"):
		_auto_t = 1.5


func _finish_lesson(skipped := false) -> void:
	if _state == "left":
		return
	var done := _state == "done"
	print("LESSON_DONE part=%s phase=%s steps=%d mistakes=%d answers=%d/%d skipped=%s" % [part_id, phase, _steps, _mistakes,
		_right, _answers, str(skipped)])
	_state = "left"
	if done and not skipped:
		TxLessons.mark(part_id, phase)
	TxSession.lesson_done()


func blocks_input() -> bool:
	return phase == "kijk" or _state != "turn"


# ======================================================================
#  hoofdlus
# ======================================================================

func _ready_for_step() -> bool:
	return con.started and not con.ended and not con.is_busy() and con.dd != null and not con.dd.finished \
		and con.dd.machine != null and con.overlay == null


func _until_reached() -> bool:
	return cfg.has("until_phase") and con.dd != null and con.dd.machine != null and con.dd.machine.phase == int(cfg.until_phase)


func _process(delta: float) -> void:
	_t += delta
	_layer.visible = con.overlay == null and not (con._guide != null and is_instance_valid(con._guide))
	_ring.queue_redraw()
	_face.queue_redraw()
	if _auto_t > 0.0:
		_auto_t -= delta
		if _auto_t <= 0.0:
			_auto_fire()
	match _state:
		"wait":
			if _ready_for_step():
				if _until_reached():
					on_done()
					return
				var mv: Dictionary = con.dd.correct_move()
				if str(mv.get("act", "none")) == "none":
					return
				if phase == "kijk":
					_kijk_step()
				else:
					_samen_step()
		"play":
			if not con.is_busy() and not _exec:
				if not _queue.is_empty() and _ready_for_step():
					_execute(_queue.pop_front())
				elif _queue.is_empty():
					_state = "wait"
		"turn":
			if demo:
				_demo_t += delta
				if _demo_t > 1.0 / maxf(0.5, TxPanel.spd):
					_demo_t = 0.0
					_demo_act()


func _auto_fire() -> void:
	match _state:
		"intro", "done":
			_on_go()
		"step":
			if autoplay:
				_on_next()
		"ask":
			if auto_answer and not _q_done:
				_answer(int((_q.correct as Array)[0]))
			elif _q_done and (autoplay or auto_answer):
				_after_answer()


func _ask_for(acts: Array) -> Dictionary:
	for a in cfg.get("ask", []):
		for it in acts:
			if str(a.on) == str(it.act) and int(a.nth) == int(it.n):
				return {"q": str(a.q), "i": int(it.i)}
	return {}


# ======================================================================
#  Kijk
# ======================================================================

func _kijk_step() -> void:
	_group = TxLessons.kijk_group(con.dd.machine)
	if _group.is_empty():
		return
	_mv = _group[0].mv
	var acts: Array = []
	for k in _group.size():
		var act := TxLessons.act_key(_group[k].mv)
		_count[act] = int(_count.get(act, 0)) + 1
		acts.append({"act": act, "n": _count[act], "i": k})
	_ring_on = true
	_ghost()
	var a := _ask_for(acts)
	if not a.is_empty():
		var it: Dictionary = _group[int(a.i)]
		_q = TxLessons.predict(it.mc, str(a.q), it.mv)
		if not _q.is_empty() and not (_q.correct as Array).is_empty():
			_q_after = "narrate"
			_ask()
			return
	_show_narration()


func _show_narration() -> void:
	_state = "step"
	var n := TxLessons.narrate_group(_group)
	var t := _note
	if t != "":
		t += "\n"
	t += "[b]%s[/b]" % n.what
	if str(n.why) != "":
		t += "\n[color=%s]%s[/color]" % [TxLessons.C_DIM, n.why]
	_note = str(n.get("after", ""))
	_say(t)
	if autoplay:
		_auto_t = 3.6 / maxf(0.5, TxPanel.spd)


func _on_next() -> void:
	if _state == "ask" and _q_done:
		_after_answer()
		return
	if _state != "step":
		return
	_queue = []
	for it in _group:
		_queue.append(it.mv)
	_state = "play"
	_ring_on = false
	_execute(_queue.pop_front())


func _toggle_play() -> void:
	autoplay = not autoplay
	_set_buttons()
	if autoplay and _state == "step":
		_auto_t = 0.6


func _execute(mv: Dictionary) -> void:
	if TxSession.has("lesson_log"):
		print("LESSON_STEP %s %s %s" % [part_id, phase, str(mv)])
	_state = "play"
	_ring_on = false
	_steps += 1
	_exec = true
	con.move(mv)
	_exec = false


func _ghost() -> void:
	if con.panel != null and not _mv.is_empty():
		con._show_ghost(_mv, 2.5)


# ======================================================================
#  voorspelvragen
# ======================================================================

func _ask() -> void:
	_state = "ask"
	_q_done = false
	_q = TxLessons.shuffled(_q, _rng)
	var t := _note
	if t != "":
		t += "\n"
	_say(t + "[color=%s][b]%s[/b][/color]\n[color=%s](klik een antwoord of 1–%d)[/color]" % [TxLessons.C_HL, _q.q, TxLessons.C_DIM, (_q.options as Array).size()])
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.options
	for k in opts.size():
		var b := TxUi.button("%d   %s" % [k + 1, opts[k]], "key", 19, PANEL.size.x - 40.0)
		b.custom_minimum_size = Vector2(PANEL.size.x - 40.0, 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(_answer.bind(k))
		_opts.add_child(b)
	_ring_on = false
	if auto_answer:
		_auto_t = 1.6


func _answer(k: int) -> void:
	if _q_done or _state != "ask":
		return
	_q_done = true
	_answers += 1
	var ok := (_q.correct as Array).has(k)
	if ok:
		_right += 1
	var i := 0
	for b in _opts.get_children():
		var good := (_q.correct as Array).has(i)
		if good:
			b.modulate = Color(0.75, 1.3, 0.85)
		elif i == k:
			b.modulate = Color(1.3, 0.6, 0.6)
		else:
			b.modulate = Color(1, 1, 1, 0.5)
		(b as Button).disabled = true
		i += 1
	TxSnd.play("stamp" if ok else "bump", -6.0)
	var fb := ("[color=%s][b]Juist![/b][/color] %s" % [TxLessons.C_OK, _q.right]) if ok else ("[color=%s][b]Niet helemaal.[/b][/color] %s" % [TxLessons.C_ERR, _q.wrong])
	_text.text = TxLessons.bb("[color=%s]%s[/color]\n%s" % [TxLessons.C_HL, _q.q, fb])
	_ring_on = true
	_next_btn.text = "Toon het ›" if _q_after == "narrate" else "Verder ›"
	_set_buttons()
	if autoplay or auto_answer:
		_auto_t = 2.2


func _after_answer() -> void:
	if _state != "ask":
		return
	for ch in _opts.get_children():
		ch.queue_free()
	_next_btn.text = "Volgende ›"
	if _q_after == "narrate":
		_show_narration()
	else:
		_begin_turn()


# ======================================================================
#  Samen
# ======================================================================

func _samen_step() -> void:
	_mv = con.dd.correct_move()
	var act := TxLessons.act_key(_mv)
	if (cfg.get("auto", []) as Array).has(act):
		var n := TxLessons.narrate(con.dd.machine, _mv)
		_ring_on = true
		_say("[color=%s]Dit doe ik even:[/color] [b]%s[/b]\n[color=%s]%s[/color]" % [TxLessons.C_DIM, n.what, TxLessons.C_DIM, n.why])
		_queue = []
		var mv := _mv
		_state = "auto"
		get_tree().create_timer(2.4 if not demo else 1.0).timeout.connect(func():
			if _state == "auto" and is_inside_tree():
				_execute(mv))
		return
	_count[act] = int(_count.get(act, 0)) + 1
	_step_wrong = 0
	_demo_t = 0.0
	var a := _ask_for([{"act": act, "n": _count[act], "i": 0}])
	if not a.is_empty():
		_q = TxLessons.predict(con.dd.machine, str(a.q), _mv)
		if not _q.is_empty() and not (_q.correct as Array).is_empty():
			_q_after = "turn"
			_ask()
			return
	_begin_turn()


func _begin_turn() -> void:
	_state = "turn"
	var act := TxLessons.act_key(_mv)
	var t := _note
	if t != "":
		t += "\n"
	if int(_count.get(act, 0)) <= 2:
		_ring_on = true
		_ghost()
		_say(t + "[color=%s][b]Tip[/b][/color]: %s" % [TxLessons.C_HL, TxLessons.tip(con.dd.machine, _mv)])
	else:
		_ring_on = false
		_say(t + "[b]Jouw beurt.[/b] [color=%s]Vast? Hint (F2).[/color]" % TxLessons.C_DIM)


func _on_hint() -> void:
	if phase != "samen" or _state != "turn":
		return
	_ring_on = true
	_ghost()
	var extra := ""
	if _step_wrong >= 1:
		extra = "\n[color=%s]%s[/color]" % [TxLessons.C_DIM, TxLessons.narrate(con.dd.machine, _mv).what]
	_say("[color=%s][b]Hint[/b][/color]: %s%s" % [TxLessons.C_HL, TxLessons.tip(con.dd.machine, _mv), extra])
	TxSnd.play("plus_one", -8.0, 0.8)


## console.move vraagt eerst toestemming. Kijk: enkel de zetten van de Chef. Samen: proef de zet op een kopie.
func allow(mv: Dictionary) -> bool:
	if _exec:
		return true
	if _state == "left":
		return false
	if phase == "kijk" or _state != "turn":
		if phase == "kijk" and _state == "step":
			_text.text = TxLessons.bb(_last_text + "\n[color=%s]Kijk mee: klik [b]Volgende ›[/b] (of Spatie).[/color]" % TxLessons.C_HL)
		return false
	var mc: TxMachine = con.dd.machine
	var acc := TxLessons.accepts(mc, mv, _mv)
	if bool(acc.ok):
		_steps += 1
		_state = "play"
		_queue = []
		_ring_on = false
		var n := TxLessons.narrate(mc, mv)
		_note = "[color=%s][b]Goed.[/b][/color] %s" % [TxLessons.C_OK, n.what]
		if str(n.get("after", "")) != "":
			_note += " " + str(n.after)
		_text.text = TxLessons.bb(_note)
		TxSnd.play("relay", -10.0)
		return true
	_mistakes += 1
	_step_wrong += 1
	var why := TxLessons.explain_wrong(mc, mv, _mv, acc.r)
	_say("[color=%s][b]Nog niet.[/b][/color] %s\n[color=%s]Probeer opnieuw.%s[/color]" % [TxLessons.C_ERR, why, TxLessons.C_DIM,
		" De spookhand wijst de juiste zet aan." if _step_wrong >= 2 else ""])
	if _step_wrong >= 2:
		_ring_on = true
		_ghost()
	TxSnd.play("bump", -6.0)
	TxFx.shake(2.0, 0.12)
	return false


## lesson_demo: een gesimuleerde speler. Per soort zet eerst één foute zet (uitleg), daarna juist.
func _demo_act() -> void:
	if _state != "turn" or con.is_busy():
		return
	var act := TxLessons.act_key(_mv)
	if not _demo_wrong.has(act):
		_demo_wrong[act] = true
		var wr: Array = con.dd.machine.wrong_moves()
		if not wr.is_empty():
			con.move(wr[0])
			return
	con.move(_mv)


# ======================================================================
#  toetsen
# ======================================================================

func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo) or _state == "left" or not _layer.visible:
		return
	var k := (ev as InputEventKey).keycode
	if _state == "ask" and not _q_done and k >= KEY_1 and k <= KEY_9:
		var i := k - KEY_1
		if i < (_q.options as Array).size():
			_answer(i)
			get_viewport().set_input_as_handled()
		return
	if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER or (k == KEY_RIGHT and phase == "kijk"):
		if _state in ["intro", "done"]:
			_on_go()
			get_viewport().set_input_as_handled()
		elif _state == "ask" and _q_done:
			_after_answer()
			get_viewport().set_input_as_handled()
		elif phase == "kijk":
			if _state == "step":
				_on_next()
			get_viewport().set_input_as_handled()
	elif k == KEY_P and phase == "kijk":
		_toggle_play()
		get_viewport().set_input_as_handled()
	elif k == KEY_F2 and phase == "samen":
		_on_hint()
		get_viewport().set_input_as_handled()
	elif phase == "kijk" and k != KEY_ESCAPE and k != KEY_F1:
		get_viewport().set_input_as_handled()


# ======================================================================
#  tekenen: ring rond het juiste element, de Chef
# ======================================================================

func _draw_ring() -> void:
	if not _ring_on or _mv.is_empty() or con == null or con.panel == null or con.is_busy():
		return
	var p: Vector2 = con.panel.hint(_mv)
	if p == Vector2.INF:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := 34.0 + 6.0 * pulse
	_ring.draw_arc(p, r, 0, TAU, 48, Color(TxPal.SIG_AMBER, 0.95), 4.0, true)
	_ring.draw_arc(p, r + 9.0, 0, TAU, 48, Color(TxPal.SIG_AMBER, 0.35 * pulse), 3.0, true)
	if p.x < PANEL.position.x - 60.0:
		var from := Vector2(PANEL.position.x - 4.0, clampf(p.y, PANEL.position.y + 40.0, PANEL.end.y - 40.0))
		var to := p + (from - p).normalized() * (r + 12.0)
		_ring.draw_dashed_line(from, to, Color(TxPal.SIG_AMBER, 0.5), 3.0, 10.0, true)


func _draw_face() -> void:
	var talk := 0.5 + 0.5 * sin(_t * 12.0) if _state in ["step", "auto", "ask", "intro"] else 0.0
	var brow := 0.9 if _text != null and _text.text.contains("Nog niet") else 0.4
	TxDraw.chef(_face, Vector2(46, 50), 0.42, talk, 0.0, brow)
