class_name ScLessonCoach
extends Node
## Leerpad op de werkbank (games/scriptorium/design/LEARNING_PATH.md): één les = één deel in één fase, met Broeder Zeno
## als verteller in een paneel rechts (op de plaats van De Overkant, in de stijl van het scriptorium).
##  - Kijk: Zeno speelt het orakel (correct_move) af. Vóór elke stap staat het werktuig stil en wijst de inkthand het
##    element aan; na de stap zegt het paneel wat + waarom, en onderaan de toestand zoals je ze op het examen noteert.
##    Volgende › / Afspelen / Overslaan. Voorspelvragen (Check in de wereld) op sleutelmomenten, vóór het werktuig het
##    toont.
##  - Samen: de speler doet het zelf (muis of toetsen, zoals in het spel). Tip vanzelf bij de eerste 2 zetten van elke
##    soort, daarna enkel op vraag (Hint of F2). Een foute zet wordt niet uitgevoerd (werkbank._on_request -> allow):
##    uitleg + herkansing; na 2 fouten op dezelfde stap wijst de inkthand de juiste zet aan.
## Teksten en antwoorden komen uit ScLessons (afgeleid van de core, dus altijd juist).

const PANEL := Rect2(1282, 196, 626, 684)

var wb                       # werkbank (sc_workbench.gd)
var part_id := ""
var phase := "kijk"
var P: Dictionary = {}
var cfg: Dictionary = {}
var forced := true
var autoplay := false
var auto_answer := false
var demo := false

var _state := "intro"        # intro | wait | step | ask | play | turn | auto | done | left
var _group: Array = []       # Kijk: [{mv, t}] van de huidige stap
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
var _pending := ""
var _last_text := ""
var _shot_n := 0
var _shot_t := 0
var _hold := 0.0

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

func setup(bench, part: String, ph: String) -> void:
	wb = bench
	part_id = part
	phase = ph
	P = ScLessons.part(part_id)
	cfg = ScLessons.cfg(part_id, phase)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	forced = not ScLessons.is_done(part_id, phase)
	autoplay = ScSession.has("autoplay")
	auto_answer = ScSession.has("auto_answer") or ScSession.has("lesson_demo")
	demo = ScSession.has("lesson_demo")
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
	_root.theme = ScUi.theme()
	_layer.add_child(_root)
	_ring = Control.new()
	_ring.size = Vector2(1920, 1080)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	_root.add_child(_ring)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(ScPal.PANEL, 0.98)
	sb.border_color = ScPal.GILT
	sb.set_border_width_all(2)
	sb.border_width_top = 6
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = ScPal.SHADOW
	sb.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = PANEL.position
	_panel.size = PANEL.size
	_panel.custom_minimum_size = PANEL.size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	vb.add_child(head)
	_face = Control.new()
	_face.custom_minimum_size = Vector2(84, 84)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.clip_contents = true
	_face.draw.connect(_draw_face)
	head.add_child(_face)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	_tag = ScUi.label("", 16, ScPal.GILT, ScPal.UI_BOLD)
	_tag.clip_text = true
	_tag.custom_minimum_size = Vector2(490, 0)
	hv.add_child(_tag)
	_title = ScUi.label("", 25, ScPal.GILT_LIGHT, ScPal.TITLE)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(490, 0)
	hv.add_child(_title)
	_text = _rich(21)
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
	sep.color = Color(ScPal.GILT_DARK, 0.7)
	sep.custom_minimum_size = Vector2(0, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sep)
	_state_lbl = _rich(17)
	_state_lbl.add_theme_color_override("default_color", ScPal.TEXT_DIM)
	vb.add_child(_state_lbl)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(_row)
	_skip_btn = _btn("Overslaan", ScUi.Kind.GHOST, _on_skip, 130)
	_hint_btn = _btn("Hint (F2)", ScUi.Kind.SECONDARY, _on_hint, 140)
	_play_btn = _btn("Afspelen", ScUi.Kind.SECONDARY, _toggle_play, 140)
	_next_btn = _btn("Volgende ›", ScUi.Kind.PRIMARY, _on_next, 160)
	_go_btn = _btn("Start", ScUi.Kind.PRIMARY, _on_go, 160)
	ScUi.pop_in(_panel, 0.25)


func _btn(t: String, kind: int, cb: Callable, w: float) -> Button:
	var b := ScUi.button(t, kind, 20, w)
	b.custom_minimum_size = Vector2(w, 48)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_row.add_child(b)
	return b


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(PANEL.size.x - 40.0, 0)
	r.add_theme_font_override("normal_font", ScPal.UI)
	r.add_theme_font_override("bold_font", ScPal.UI_BOLD)
	r.add_theme_font_override("italics_font", ScPal.UI)
	r.add_theme_font_override("mono_font", ScPal.MONO_M)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size", "italics_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", ScPal.TEXT)
	r.add_theme_constant_override("line_separation", 3)
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
	var n := ScLessons.all_parts().size()
	_tag.text = "%s · DEEL %d VAN %d · %s" % ["KIJK" if phase == "kijk" else "SAMEN", ScLessons.index_of_part(part_id) + 1, n,
		str(P.page).to_upper()]
	_tag.tooltip_text = str(P.page)
	var fs := 16
	while fs > 11 and ScPal.UI_BOLD.get_string_size(_tag.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > _tag.custom_minimum_size.x:
		fs -= 1
	_tag.add_theme_font_size_override("font_size", fs)
	_title.text = str(P.title)


func _cur_tool() -> ScTool:
	return wb.director.tool if wb != null and wb.director != null else null


func _say(bb: String) -> void:
	_last_text = bb
	_text.text = ScLessons.bb(bb)
	var st := ScLessons.state(_cur_tool())
	_log_text(bb, st)
	_state_lbl.text = ScLessons.bb("[b]Toestand[/b] [color=%s](zoals op het examen)[/color]\n%s" % [ScLessons.C_DIM, st]) if st != "" else ""
	_set_tag()
	_set_buttons()
	_face.queue_redraw()


## lesson_log: toon wat de speler leest ook op stdout (LESSON_SAY / LESSON_STATE), voor QA zonder frames.
func _log_text(bb: String, st := "") -> void:
	if ScSession.arg("lesson_shots", "") != "":
		_shot_t = 6
	if not ScSession.has("lesson_log"):
		_shot_n += 1
		return
	var re := RegEx.create_from_string("\\[/?(b|i|code|color|font_size)(=[^\\]]*)?\\]")
	_shot_n += 1
	print("LESSON_SAY #%d %s" % [_shot_n, re.sub(bb, "", true).replace("[lb]", "[").replace("\n", " / ")])
	if st != "":
		print("LESSON_STATE %s" % re.sub(st, "", true).replace("[lb]", "[").replace("\n", " / "))


func _show_intro() -> void:
	_state = "intro"
	var t := "[b]Regel[/b]: %s\n\n%s\n\n" % [P.rule, P.get("idea", "")]
	if phase == "kijk":
		t += "[color=%s]Ik doe het voor, stap voor stap: bij elke stap [b]wat[/b] ik doe en [b]waarom[/b]. Soms vraag ik eerst wat jij denkt. Klik [b]Volgende[/b] (of Spatie) of laat het [b]afspelen[/b].[/color]" % ScLessons.C_DIM
		if cfg.has("fig"):
			t += "\n[color=%s]Voorbeeld uit de notas: %s.[/color]" % [ScLessons.C_DIM, cfg.fig]
	else:
		t += "[color=%s]Nu jij, met dezelfde muisklikken en toetsen als in het spel. Eerst geef ik tips, later enkel op vraag (Hint of F2). Een foute zet voer ik niet uit: ik leg uit waarom en je probeert opnieuw.[/color]" % ScLessons.C_DIM
	if not forced:
		t += "\n[color=%s]Al gezien: overslaan mag.[/color]" % ScLessons.C_DIM
	_say(t)
	if autoplay or demo or ScSession.has("auto_answer"):
		_auto_t = 1.2


func _on_go() -> void:
	if _state == "intro":
		_state = "wait"
		_note = ScLessons.start_note(_cur_tool())
		_say("[color=%s]…[/color]" % ScLessons.C_DIM)
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
	_clear_ghost()
	var t := ""
	if _pending != "":
		t += _pending + "\n"
		_pending = ""
	if _note != "":
		t += _note + "\n"
	t += "[color=%s][b]Klaar![/b][/color] " % ScLessons.C_OK
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
	ScSnd.play("wax_seal", -6.0)
	if autoplay or demo or ScSession.has("auto_answer"):
		_auto_t = 1.5


func _finish_lesson(skipped := false) -> void:
	if _state == "left":
		return
	var done := _state == "done"
	print("LESSON_DONE part=%s phase=%s steps=%d mistakes=%d answers=%d/%d skipped=%s" % [part_id, phase, _steps, _mistakes,
		_right, _answers, str(skipped)])
	_state = "left"
	if done and not skipped:
		ScLessons.mark(part_id, phase)
	ScSession.lesson_done()


func blocks_input() -> bool:
	return phase == "kijk" or _state != "turn"


# ======================================================================
#  hoofdlus
# ======================================================================

func _ready_for_step() -> bool:
	return wb.director != null and not wb.director.finished and not wb.busy() and wb.director.tool != null \
		and wb.view != null


func _until_reached() -> bool:
	var tl := _cur_tool()
	return cfg.has("until_phase") and tl != null and tl.phase == int(cfg.until_phase)


func _process(delta: float) -> void:
	_t += delta
	if _shot_t > 0:
		_shot_t -= 1
		if _shot_t == 0:
			var dir := str(ScSession.arg("lesson_shots", ""))
			DirAccess.make_dir_recursive_absolute(dir)
			var img := get_viewport().get_texture().get_image()
			if img != null:
				img.save_png(dir.path_join("%s_%s_%03d.png" % [part_id, phase, _shot_n]))
	var guide_open: bool = wb._guide != null and is_instance_valid(wb._guide)
	_layer.visible = not guide_open and not wb._paused and wb._overlay_open == 0
	_ring.queue_redraw()
	_face.queue_redraw()
	if not _layer.visible:
		return
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
				var mv: Dictionary = wb.director.correct_move()
				if str(mv.get("act", "none")) == "none":
					return
				if phase == "kijk":
					_kijk_step()
				else:
					_samen_step()
		"play":
			if _hold > 0.0:
				_hold -= delta
				return
			if not wb.busy() and not _exec:
				if not _queue.is_empty() and _ready_for_step():
					_execute(_queue.pop_front())
				elif _queue.is_empty():
					if phase == "kijk" and _pending != "":
						_show_done()
					else:
						_state = "wait"
		"turn":
			if demo:
				_demo_t += delta
				if _demo_t > 1.0:
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
	_group = ScLessons.kijk_group(_cur_tool())
	if _group.is_empty():
		return
	_mv = _group[0].mv
	var acts: Array = []
	for k in _group.size():
		var act := ScLessons.act_key(_group[k].t, _group[k].mv)
		_count[act] = int(_count.get(act, 0)) + 1
		acts.append({"act": act, "n": _count[act], "i": k})
	var a := _ask_for(acts)
	if not a.is_empty():
		var it: Dictionary = _group[int(a.i)]
		_q = ScLessons.predict(it.t, str(a.q), it.mv)
		if not _q.is_empty() and not (_q.correct as Array).is_empty():
			_q_after = "narrate"
			_ring_on = true
			_ghost(it.mv)
			_ask()
			return
	_show_narration()


## Kijk: eerst de stap uitvoeren, dan pas de uitleg tonen (tekst, werktuig en toestand tonen dan dezelfde stap).
func _show_narration() -> void:
	var n := ScLessons.narrate_group(_group)
	var t := _note
	_note = ""
	if t != "":
		t += "\n"
	t += "[b]%s[/b]" % n.what
	if str(n.why) != "":
		t += "\n[color=%s]%s[/color]" % [ScLessons.C_DIM, n.why]
	if str(n.get("after", "")) != "":
		t += "\n" + str(n.after)
	_pending = t
	_queue = []
	for it in _group:
		_queue.append(it.mv)
	_ring_on = false
	_ghost(_group[0].mv)
	_state = "play"
	_hold = 0.55 if not (autoplay or demo) else 0.35   # eerst de inkthand even tonen, dan de zet
	_set_buttons()


func _show_done() -> void:
	_state = "step"
	var t := _pending
	_pending = ""
	_say(t)
	if autoplay:
		_auto_t = 3.6


func _on_next() -> void:
	if _state == "ask" and _q_done:
		_after_answer()
		return
	if _state != "step":
		return
	_state = "wait"
	_set_buttons()


func _toggle_play() -> void:
	autoplay = not autoplay
	_set_buttons()
	if autoplay and _state == "step":
		_auto_t = 0.6


func _execute(mv: Dictionary) -> void:
	if ScSession.has("lesson_log"):
		print("LESSON_STEP %s %s %s" % [part_id, phase, str(mv)])
	_state = "play"
	_ring_on = false
	_clear_ghost()
	_steps += 1
	_exec = true
	wb._on_request(mv)
	_exec = false


func _ghost(mv: Dictionary) -> void:
	if wb.view == null or mv.is_empty():
		return
	wb.view.ghost = mv
	wb.view.ghost_a = 0.0
	wb.view.create_tween().tween_property(wb.view, "ghost_a", 1.0, 0.25)


func _clear_ghost() -> void:
	if wb.view != null:
		wb.view.ghost = {}
		wb.view.ghost_a = 0.0


# ======================================================================
#  voorspelvragen
# ======================================================================

func _ask() -> void:
	_state = "ask"
	_q_done = false
	_q = ScLessons.shuffled(_q, _rng)
	var t := _note
	if t != "":
		t += "\n"
	if phase == "kijk":
		_note = ""
	_say(t + "[color=%s][b]%s[/b][/color]\n[color=%s](klik een antwoord of 1–%d)[/color]" % [ScLessons.C_HL, _q.q, ScLessons.C_DIM, (_q.options as Array).size()])
	for c in _opts.get_children():
		c.queue_free()
	var opts: Array = _q.options
	for k in opts.size():
		var b := ScUi.button("%d   %s" % [k + 1, str(opts[k])], ScUi.Kind.VELLUM, 19, PANEL.size.x - 40.0)
		b.custom_minimum_size = Vector2(PANEL.size.x - 40.0, 42)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.focus_mode = Control.FOCUS_NONE
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
	ScSnd.play("wax_seal" if ok else "clamp", -8.0)
	var fb := ("[color=%s][b]Juist![/b][/color] %s" % [ScLessons.C_OK, _q.right]) if ok else ("[color=%s][b]Niet helemaal.[/b][/color] %s" % [ScLessons.C_ERR, _q.wrong])
	_text.text = ScLessons.bb("[color=%s]%s[/color]\n%s" % [ScLessons.C_HL, _q.q, fb])
	_log_text("ANTWOORD %d: %s" % [k + 1, fb])
	_ring_on = true
	_next_btn.text = "Toon het ›" if _q_after == "narrate" else "Verder ›"
	_set_buttons()
	if autoplay or auto_answer:
		_auto_t = 2.2


func _after_answer() -> void:
	if _state != "ask":
		return
	for c in _opts.get_children():
		c.queue_free()
	_next_btn.text = "Volgende ›"
	if _q_after == "narrate":
		_show_narration()
	else:
		_begin_turn()


# ======================================================================
#  Samen
# ======================================================================

func _samen_step() -> void:
	_mv = wb.director.correct_move()
	var tl := _cur_tool()
	var act := ScLessons.act_key(tl, _mv)
	if (cfg.get("auto", []) as Array).has(act):
		var n := ScLessons.narrate(tl, _mv)
		_ring_on = true
		_say("[color=%s]Dit doe ik even:[/color] [b]%s[/b]\n[color=%s]%s[/color]" % [ScLessons.C_DIM, n.what, ScLessons.C_DIM, n.why])
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
		_q = ScLessons.predict(tl, str(a.q), _mv)
		if not _q.is_empty() and not (_q.correct as Array).is_empty():
			_q_after = "turn"
			_ask()
			return
	_begin_turn()


func _begin_turn() -> void:
	_state = "turn"
	var tl := _cur_tool()
	var act := ScLessons.act_key(tl, _mv)
	var t := _note
	if t != "":
		t += "\n"
	if int(_count.get(act, 0)) <= 2:
		_ring_on = true
		_ghost(_mv)
		_say(t + "[color=%s][b]Tip[/b][/color]: %s" % [ScLessons.C_HL, ScLessons.tip(tl, _mv)])
	else:
		_ring_on = false
		_clear_ghost()
		_say(t + "[b]Jouw beurt.[/b] [color=%s]Vast? Hint (F2).[/color]" % ScLessons.C_DIM)


func _on_hint() -> void:
	if phase != "samen" or _state != "turn":
		return
	_ring_on = true
	_ghost(_mv)
	_say("[color=%s][b]Hint[/b][/color]: %s" % [ScLessons.C_HL, ScLessons.tip(_cur_tool(), _mv)])
	ScSnd.play("unroll", -10.0)


## De werkbank vraagt eerst toestemming voor elke zet. Kijk: enkel de zetten van Zeno. Samen: proef de zet op een kopie.
func allow(mv: Dictionary) -> bool:
	if _exec:
		return true
	if _state == "left":
		return false
	if phase == "kijk" or _state != "turn":
		if phase == "kijk" and _state == "step":
			_text.text = ScLessons.bb(_last_text + "\n[color=%s]Kijk mee: klik [b]Volgende ›[/b] (of Spatie).[/color]" % ScLessons.C_HL)
		return false
	var tl := _cur_tool()
	var acc := ScLessons.accepts(tl, mv)
	if bool(acc.ok):
		_steps += 1
		_state = "play"
		_queue = []
		_ring_on = false
		_clear_ghost()
		var n := ScLessons.narrate(tl, mv)
		_note = "[color=%s][b]Goed.[/b][/color] %s" % [ScLessons.C_OK, n.what]
		if str(n.get("after", "")) != "":
			_note += " " + str(n.after)
		_text.text = ScLessons.bb(_note)
		_log_text(_note)
		return true
	_mistakes += 1
	_step_wrong += 1
	var why := ScLessons.explain_wrong(tl, mv, acc)
	_say("[color=%s][b]Nog niet.[/b][/color] %s\n[color=%s]Probeer opnieuw.%s[/color]" % [ScLessons.C_ERR, why, ScLessons.C_DIM,
		" De inkthand wijst de juiste zet aan." if _step_wrong >= 2 else ""])
	if _step_wrong >= 2:
		_ring_on = true
		_ghost(_mv)
	ScSnd.play("clamp", -6.0)
	return false


## lesson_demo: een gesimuleerde speler. Per soort zet eerst één foute zet (uitleg), daarna juist.
func _demo_act() -> void:
	if _state != "turn" or wb.busy():
		return
	var tl := _cur_tool()
	var act := ScLessons.act_key(tl, _mv)
	if not _demo_wrong.has(act):
		_demo_wrong[act] = true
		var wr: Array = tl.wrong_moves()
		if wr.is_empty():
			wr = tl.impossible_moves().slice(0, 1)
		if not wr.is_empty():
			wb._on_request(wr[0])
			return
	wb._on_request(_mv)


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
	elif phase == "kijk" and k != KEY_ESCAPE and k != KEY_F1 and not (ev as InputEventKey).ctrl_pressed:
		get_viewport().set_input_as_handled()


# ======================================================================
#  tekenen: ring rond het juiste element, Zeno
# ======================================================================

func _draw_ring() -> void:
	if not _ring_on or _mv.is_empty() or wb == null or wb.view == null or wb.busy():
		return
	var v: ScView = wb.view
	var p: Vector2 = v.get_global_transform() * v.anchor(_mv)
	var bt := _button_for(_mv)
	if bt != null:
		p = bt.get_global_rect().get_center()
	if p.x < 0 or p.y < 0 or p.x > 1920 or p.y > 1080:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := 34.0 + 6.0 * pulse
	_ring.draw_arc(p, r, 0, TAU, 48, Color(ScPal.GILT_LIGHT, 0.95), 4.0, true)
	_ring.draw_arc(p, r + 9.0, 0, TAU, 48, Color(ScPal.GILT_LIGHT, 0.35 * pulse), 3.0, true)
	if p.x < PANEL.position.x - 60.0:
		var from := Vector2(PANEL.position.x - 4.0, clampf(p.y, PANEL.position.y + 40.0, PANEL.end.y - 40.0))
		var to := p + (from - p).normalized() * (r + 12.0)
		_ring.draw_dashed_line(from, to, Color(ScPal.GILT_LIGHT, 0.5), 3.0, 10.0, true)


## De contextknop onderaan (Geen match, Verleng, Blijf staan, …) die zet mv doet, of null.
func _button_for(mv: Dictionary) -> Button:
	if wb == null or wb.view == null:
		return null
	var labels := {}
	for vb in wb.view.buttons():
		if vb.get("move", {}) == mv:
			labels[str(vb.text)] = true
	for b in wb.ctx_row.get_children():
		if b is Button and labels.has((b as Button).text):
			return b
	return null


func _draw_face() -> void:
	var talk := 0.5 + 0.5 * sin(_t * 12.0) if _state in ["step", "auto", "ask", "intro", "turn"] else 0.0
	ScDraw.zeno(_face, Vector2(42, 70), 0.4, _t, talk, 1.0)
