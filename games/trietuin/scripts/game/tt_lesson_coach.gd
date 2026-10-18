class_name TtLessonCoach
extends Node
## Leerpad in de tuin (games/trietuin/design/LEARNING_PATH.md): één les = één deel in één fase, met de Uil als verteller.
##  - Kijk: de Uil speelt het orakel (correct_move) af. Vóór elke stap staat de tuin stil, licht het juiste element op
##    en toont het Uilpaneel wat + waarom + de toestand zoals je ze op het examen noteert. Volgende stap / Afspelen /
##    Overslaan. Voorspelvragen (Check in de wereld) op sleutelmomenten, vóór de stap getoond wordt.
##  - Samen: de speler doet het zelf. Tip vanzelf bij de eerste 2 stappen van elke soort, daarna enkel op vraag (Hint
##    of F2). Een foute zet wordt niet uitgevoerd (garden.do_move -> allow): uitleg + herkansing; na 2 fouten op
##    dezelfde stap licht het juiste element vanzelf op. Zetten in cfg.auto doet de Uil zelf (met uitleg).
## Teksten en antwoorden komen uit TtLessons (afgeleid van het model, dus altijd juist).

const PANEL_X := 1360.0
const PANEL_W := 544.0
const PANEL_BOTTOM := 856.0
const C_OK := "#3DDC97"
const C_ERR := "#FF5A5F"
const C_DIM := "#A9C0AC"
const C_WARN := "#FFB020"

var garden          # tt_garden.gd
var model: TtTreeModel
var part_id := ""
var phase := "kijk"
var P: Dictionary
var cfg: Dictionary
var forced := true
var autoplay := false
var auto_answer := false
var demo := false

var _state := "intro"               # intro | wait | step | ask | play | turn | auto | done
var _mv: Dictionary = {}
var _count := {}                    # act -> aantal keer (voorspelvragen, fading)
var _q: Dictionary = {}
var _q_done := false
var _auto_t := 0.0
var _mistakes := 0
var _step_wrong := 0
var _steps := 0
var _answers := 0
var _right_answers := 0
var _exec := false
var _ring_on := false
var _card_seen := -1
var _last_it := -1
var _note := ""
var _demo_t := 0.0
var _demo_wrong := {}
var _t := 0.0
var _rng := RandomNumberGenerator.new()

var _layer: CanvasLayer
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

## Vóór de tuin gebouwd wordt (de director is al gestart): Ukkonen vooruitspoelen tot from_it.
func prepare(g) -> void:
	garden = g
	model = g.model
	P = TtLessons.part(part_id)
	cfg = TtLessons.cfg(part_id, phase)
	var from_it := int(cfg.get("from_it", 0))
	if from_it > 0 and model is TtUkkonen:
		var c: TtCard = g.director.next_card()
		var guard := 0
		while model.card != null and (model as TtUkkonen).it < from_it and guard < 500:
			guard += 1
			model.apply(model.correct_move())
		if c:
			pass


func start() -> void:
	forced = not TtLessons.is_done(part_id, phase)
	autoplay = TtSession.has("autoplay")
	auto_answer = TtSession.has("auto_answer") or TtSession.has("lesson_demo")
	demo = TtSession.has("lesson_demo")
	_rng.seed = 11
	_build_ui()
	_show_intro()


func panel_top() -> float:
	match int(garden.kind):
		TtCodes.Kind.UKKONEN:
			return 300.0
		TtCodes.Kind.SUFFIX:
			return 254.0
	return 100.0


## De boom krijgt de ruimte links van het Uilpaneel.
func tree_rect(r: Rect2) -> Rect2:
	return Rect2(r.position, Vector2(PANEL_X - 20.0 - r.position.x, r.size.y))


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 12
	add_child(_layer)
	_ring = Control.new()
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	_layer.add_child(_ring)
	_panel = PanelContainer.new()
	var sb := TtUi.panel_box(Color(TtPal.PANEL, 0.97), 22)
	sb.border_color = TtPal.STAR
	sb.border_width_top = 6
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", sb)
	var top := panel_top()
	_panel.position = Vector2(PANEL_X, top)
	_panel.size = Vector2(PANEL_W, PANEL_BOTTOM - top)
	_panel.custom_minimum_size = _panel.size
	_layer.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	vb.add_child(head)
	_face = Control.new()
	_face.custom_minimum_size = Vector2(96, 96)
	_face.draw.connect(_draw_face)
	head.add_child(_face)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	_tag = TtUi.label("", 19, TtPal.STAR, TtPal.UI_BOLD)
	hv.add_child(_tag)
	_title = TtUi.label("", 25, TtPal.TEXT, TtPal.UI_BOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(380, 0)
	hv.add_child(_title)
	_text = _rich(22)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_text)
	_opts = VBoxContainer.new()
	_opts.add_theme_constant_override("separation", 6)
	vb.add_child(_opts)
	var sep := ColorRect.new()
	sep.color = Color(TtPal.TEXT_DIM, 0.25)
	sep.custom_minimum_size = Vector2(0, 2)
	vb.add_child(sep)
	_state_lbl = _rich(17)
	_state_lbl.add_theme_color_override("default_color", TtPal.TEXT_DIM)
	vb.add_child(_state_lbl)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	_row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(_row)
	_skip_btn = _btn("Overslaan", TtUi.Kind.GHOST, _on_skip, 130)
	_hint_btn = _btn("Hint (F2)", TtUi.Kind.SAP, _on_hint, 150)
	_play_btn = _btn("Afspelen", TtUi.Kind.SECONDARY, _toggle_play, 140)
	_next_btn = _btn("Volgende ›", TtUi.Kind.PRIMARY, _on_next, 160)
	_go_btn = _btn("Start", TtUi.Kind.PRIMARY, _on_go, 160)
	TtUi.pop_in(_panel, 0.1, 0.25)


func _btn(t: String, kind: int, cb: Callable, w: float) -> Button:
	var b := TtUi.button(t, kind, 21, w)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_row.add_child(b)
	return b


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(PANEL_W - 40.0, 0)
	r.add_theme_font_override("normal_font", TtPal.UI)
	r.add_theme_font_override("bold_font", TtPal.UI_BOLD)
	r.add_theme_font_override("mono_font", TtPal.MONO_B)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", TtPal.TEXT)
	r.add_theme_constant_override("line_separation", 3)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _set_buttons() -> void:
	var kijk := phase == "kijk"
	_go_btn.visible = _state == "intro" or _state == "done"
	_go_btn.text = "Verder ›" if _state == "done" else "Start"
	_next_btn.visible = kijk and _state == "step"
	_play_btn.visible = kijk and _state in ["step", "play", "wait"]
	_play_btn.text = "Pauze" if autoplay else "Afspelen"
	_hint_btn.visible = not kijk and _state == "turn"
	_skip_btn.visible = not forced and _state != "done"


func _set_tag() -> void:
	var n := TtLessons.all_parts().size()
	var ph := "KIJK" if phase == "kijk" else "SAMEN"
	_tag.text = "%s · deel %d van %d · %s" % [ph, TtLessons.index_of_part(part_id) + 1, n, str(P.page)]
	_title.text = str(P.title)


func _say(bb: String) -> void:
	_text.text = TtLessons.subs(bb)
	_state_lbl.text = "[b]Toestand[/b]  " + TtLessons.state_line(model) if model.card != null else ""
	_set_tag()
	_set_buttons()
	_face.queue_redraw()


func _show_intro() -> void:
	_state = "intro"
	var t := "[b]Regel[/b]: %s\n\n%s\n\n" % [P.rule, P.get("idea", "")]
	if phase == "kijk":
		t += "[color=%s]Ik doe het voor, stap voor stap. Bij elke stap zeg ik [b]wat[/b] ik doe en [b]waarom[/b]. Soms vraag ik eerst wat jij denkt.[/color]" % C_DIM
		if cfg.has("fig"):
			t += "\n[color=%s]Voorbeeld uit de notas: %s.[/color]" % [C_DIM, cfg.fig]
	else:
		t += "[color=%s]Nu jij, met dezelfde bediening als in het spel. Ik geef eerst tips; later enkel op vraag (Hint of F2). Een foute zet voer ik niet uit: ik leg uit waarom en je probeert opnieuw.[/color]" % C_DIM
	if not forced:
		t += "\n[color=%s]Al gezien: overslaan mag.[/color]" % C_DIM
	_say(t)
	if autoplay or demo or TtSession.has("auto_answer"):
		_auto_t = 1.2


func _on_go() -> void:
	if _state == "intro":
		_state = "wait"
		_say("[color=%s]…[/color]" % C_DIM)
	elif _state == "done":
		_finish_lesson()


func _on_skip() -> void:
	_finish_lesson(true)


## De Uil is klaar (alle kaarten of until_it): samenvatting + Verder.
func on_cards_done() -> void:
	if _state == "done":
		return
	_state = "done"
	_ring_on = false
	var t := "[color=%s][b]Klaar![/b][/color] " % C_OK
	if phase == "kijk":
		t += "Dat was de demo van [b]%s[/b]." % P.title
		if _answers > 0:
			t += " Voorspellingen: %d van %d juist." % [_right_answers, _answers]
		t += "\n\n[b]Regel[/b]: %s\n\nStraks doe je het zelf." % P.rule
	else:
		t += "Je deed %d stappen%s." % [_steps, (" met %d fout%s (telt niet mee)" % [_mistakes, "" if _mistakes == 1 else "en"]) if _mistakes > 0 else " zonder fouten"]
		var lv: Array = P.levels
		t += "\n\n[b]Regel[/b]: %s\n\nZelf oefen je dit in level %s." % [P.rule, ", ".join(lv)]
	_say(t)
	_state_lbl.text = "[b]Toestand[/b]  " + TtLessons.state_line(model)
	TtSnd.play("star_1", -6.0)
	if autoplay or demo or TtSession.has("auto_answer"):
		_auto_t = 1.5


func _finish_lesson(skipped := false) -> void:
	if _state == "left":
		return
	var done := _state == "done"
	print("LESSON_DONE part=%s phase=%s steps=%d mistakes=%d answers=%d/%d skipped=%s tree=%s" % [part_id, phase, _steps,
		_mistakes, _right_answers, _answers, str(skipped), model.serialize()])
	_state = "left"
	if done and not skipped:
		TtLessons.mark(part_id, phase)
	TtSession.lesson_done()


func blocks_input() -> bool:
	return phase == "kijk" or _state != "turn"


# ======================================================================
#  hoofdlus
# ======================================================================

func _ready_for_step() -> bool:
	return garden.state == "play" and not garden.busy and model.card != null


func _process(delta: float) -> void:
	_t += delta
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
					on_cards_done()
					return
				if phase == "kijk":
					_kijk_step()
				else:
					_samen_step()
		"play":
			if not garden.busy and not _exec:
				_state = "wait"
		"turn":
			if demo:
				_demo_t += delta
				if _demo_t > 1.2:
					_demo_t = 0.0
					_demo_act()


func _until_reached() -> bool:
	var u := int(cfg.get("until_it", 0))
	return u > 0 and model is TtUkkonen and (model as TtUkkonen).it > u


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


## Kopregel bij een nieuwe kaart of (Ukkonen) een nieuwe iteratie.
func _prefix() -> String:
	var pre := ""
	var c: TtCard = model.card
	if c != null and c.id != _card_seen:
		_card_seen = c.id
		var what := ""
		match c.kind:
			TtCodes.CardKind.SEED:
				what = "Zaadje %s: toevoegen." % TtLessons.code(c.word)
			TtCodes.CardKind.BEE:
				what = "Bij %s: opzoeken." % TtLessons.code(c.word)
			TtCodes.CardKind.PRUNE:
				what = "Schaar %s: verwijderen." % TtLessons.code(c.word)
			TtCodes.CardKind.PATRICIFY:
				what = "Snoeikaart: maak er een Patricia trie van."
			TtCodes.CardKind.TERNARIFY:
				what = "Omzetkaart: elke top wordt een rankknoop."
			TtCodes.CardKind.SUFFIX:
				var sm := model as TtSuffixTree
				what = "Suffix σ%s = %s aanhechten." % [TtLessons.sub(str(sm.display_pos(c.j))), TtLessons.code(sm.text.substr(c.j))]
			TtCodes.CardKind.ASK:
				var q: String = {"where": "Waar komt het voor?", "first": "Waar komt het eerst voor?", "count": "Hoe vaak?",
					"all": "Alle posities?", "exists": "Komt het voor?", "owner": "Van wie is het?"}.get(c.q, "")
				what = "Inspecteur: z = %s. %s" % [TtLessons.code(c.word), q]
			TtCodes.CardKind.UKKONEN:
				what = "Ukkonen op %s (posities vanaf 1)." % TtLessons.code((model as TtUkkonen).text)
		pre += "[color=%s]%s[/color]\n" % [C_WARN, what]
	if model is TtUkkonen:
		var um := model as TtUkkonen
		if um.it != _last_it:
			_last_it = um.it
			pre += "[color=%s]%s[/color]\n" % [C_WARN, TtLessons.iteration_intro(um)]
	return pre


# ======================================================================
#  Kijk
# ======================================================================

func _kijk_step() -> void:
	_mv = model.correct_move()
	if str(_mv.get("act", "none")) == "none":
		return
	var act := str(_mv.act)
	_count[act] = int(_count.get(act, 0)) + 1
	_note = _prefix()
	_ring_on = true
	_q = {}
	for a in cfg.get("ask", []):
		if str(a.on) == act and int(a.nth) == int(_count[act]):
			_q = TtLessons.predict(model, str(a.q), _mv)
	if not _q.is_empty() and not (_q.correct as Array).is_empty():
		_ask()
		return
	_show_narration("")


func _show_narration(pre: String) -> void:
	_state = "step"
	var n := TtLessons.narrate(model, _mv)
	_say(_note + pre + "[b]%s[/b]\n[color=%s]%s[/color]" % [n.what, C_DIM, n.why])
	if autoplay:
		_auto_t = 3.4


func _on_next() -> void:
	if _state != "step":
		return
	_execute(_mv)


func _toggle_play() -> void:
	autoplay = not autoplay
	_set_buttons()
	if autoplay and _state == "step":
		_auto_t = 0.6


func _execute(mv: Dictionary) -> void:
	if TtSession.has("lesson_log"):
		print("LESSON_STEP %s %s" % [phase, str(mv)])
	_state = "play"
	_ring_on = false
	_steps += 1
	_exec = true
	garden.do_move(mv)
	_exec = false


# ======================================================================
#  voorspelvragen
# ======================================================================

func _ask() -> void:
	_state = "ask"
	_q_done = false
	_q = TtLessons.shuffled(_q, _rng)
	_say(_note + "[color=%s][b]%s[/b][/color]\n[color=%s](klik een antwoord of 1–%d)[/color]" % [C_WARN, _q.q, C_DIM, (_q.options as Array).size()])
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.options
	for k in opts.size():
		var b := TtUi.button("%d   %s" % [k + 1, opts[k]], TtUi.Kind.SECONDARY, 21, PANEL_W - 40.0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
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
		_right_answers += 1
	var i := 0
	for b in _opts.get_children():
		var good := (_q.correct as Array).has(i)
		if good:
			b.modulate = Color(0.75, 1.3, 0.85)
		elif i == k:
			b.modulate = Color(1.3, 0.6, 0.6)
		else:
			b.modulate = Color(1, 1, 1, 0.5)
		b.disabled = true
		i += 1
	TtSnd.play("stamp" if ok else "clonk", -6.0)
	var fb := ("[color=%s][b]Juist![/b][/color] %s" % [C_OK, _q.right]) if ok else ("[color=%s][b]Niet helemaal.[/b][/color] %s" % [C_ERR, _q.wrong])
	_text.text = TtLessons.subs(_note + "[color=%s]%s[/color]\n%s" % [C_WARN, _q.q, fb])
	_ring_on = true
	_go_after_answer_btn()
	if autoplay or auto_answer:
		_auto_t = 2.2


func _go_after_answer_btn() -> void:
	_next_btn.visible = true
	_next_btn.text = "Toon het ›"
	for c in _next_btn.pressed.get_connections():
		_next_btn.pressed.disconnect(c.callable)
	_next_btn.pressed.connect(_after_answer)


func _after_answer() -> void:
	if _state != "ask":
		return
	for c in _next_btn.pressed.get_connections():
		_next_btn.pressed.disconnect(c.callable)
	_next_btn.pressed.connect(_on_next)
	_next_btn.text = "Volgende ›"
	for ch in _opts.get_children():
		ch.queue_free()
	_show_narration("")


# ======================================================================
#  Samen
# ======================================================================

func _kind(act: String) -> String:
	return act


func _samen_step() -> void:
	_mv = model.correct_move()
	if str(_mv.get("act", "none")) == "none":
		return
	var act := str(_mv.act)
	_note = _prefix()
	if (cfg.get("auto", []) as Array).has(act):
		var n := TtLessons.narrate(model, _mv)
		_state = "auto"
		_ring_on = true
		_say(_note + "[color=%s]Dit doe ik even:[/color] [b]%s[/b]\n[color=%s]%s[/color]" % [C_DIM, n.what, C_DIM, n.why])
		var mv := _mv
		get_tree().create_timer(2.6 if not demo else 1.2).timeout.connect(func():
			if _state == "auto":
				_execute(mv))
		return
	_count[act] = int(_count.get(act, 0)) + 1
	_step_wrong = 0
	_demo_t = 0.0
	_state = "turn"
	if int(_count[act]) <= 2:
		_ring_on = true
		_say(_note + "[color=%s][b]Tip[/b][/color]: %s" % [C_WARN, TtLessons.tip(model, _mv)])
	else:
		_ring_on = false
		_say(_note + "[b]Jouw beurt.[/b] [color=%s]Vast? Hint (F2).[/color]" % C_DIM)


func _on_hint() -> void:
	if phase != "samen" or _state != "turn":
		return
	_ring_on = true
	var extra := ""
	if _step_wrong >= 1 or _text.text.contains("Tip"):
		extra = "\n[color=%s]%s[/color]" % [C_DIM, TtLessons.narrate(model, _mv).what]
	_say(_note + "[color=%s][b]Hint[/b][/color]: %s%s" % [C_WARN, TtLessons.tip(model, _mv), extra])
	TtSnd.play("owl", -6.0)


## garden.do_move vraagt eerst toestemming. Kijk: enkel de zetten van de Uil. Samen: proef de zet op een kopie.
func allow(mv: Dictionary) -> bool:
	if _exec:
		return true
	if phase == "kijk" or _state != "turn":
		return false
	var trial := TtLevels.make_model(garden.spec)
	trial.restore(model.snapshot())
	if model is TtTernary:
		(trial as TtTernary).word_order = (model as TtTernary).word_order
	var before := trial.log.entries.size()
	var r := trial.apply(mv)
	var entry: Dictionary = trial.log.entries[trial.log.entries.size() - 1] if trial.log.entries.size() > before else {}
	if bool(r.get("ok", false)) and int(r.get("verdict", 0)) == TtCodes.Verdict.OK:
		_steps += 1
		_state = "play"
		_ring_on = false
		_text.text = TtLessons.subs(_note + "[color=%s][b]Goed.[/b][/color] %s" % [C_OK, TtLessons.narrate(model, mv).what])
		return true
	_mistakes += 1
	_step_wrong += 1
	var why := TtLessons.explain_wrong(trial, entry, _mv)
	_say(_note + "[color=%s][b]Nog niet.[/b][/color] %s\n[color=%s]Probeer opnieuw.%s[/color]" % [C_ERR, why, C_DIM,
		" Het juiste element licht op." if _step_wrong >= 2 else ""])
	if _step_wrong >= 2:
		_ring_on = true
	TtSnd.play("clonk", -6.0)
	garden.bench.bump()
	return false


## lesson_demo=1: gesimuleerde speler. Per soort zet eerst één foute zet (uitleg), daarna juist.
func _demo_act() -> void:
	if _state != "turn" or garden.busy:
		return
	var act := str(_mv.act)
	if not _demo_wrong.has(act):
		_demo_wrong[act] = true
		var wr := model.wrong_moves()
		if not wr.is_empty():
			garden.do_move(wr[0])
			return
	garden.do_move(_mv)


# ======================================================================
#  toetsen
# ======================================================================

func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := (ev as InputEventKey).keycode
	if _state == "ask" and not _q_done and k >= KEY_1 and k <= KEY_9:
		var i := k - KEY_1
		if i < (_q.options as Array).size():
			_answer(i)
			get_viewport().set_input_as_handled()
		return
	if phase == "kijk":
		if k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_RIGHT:
			if _state == "step":
				_on_next()
			elif _state == "ask" and _q_done:
				_after_answer()
			elif _state in ["intro", "done"]:
				_on_go()
			get_viewport().set_input_as_handled()
		elif k == KEY_P:
			_toggle_play()
			get_viewport().set_input_as_handled()
	elif _state in ["intro", "done"] and (k == KEY_ENTER or k == KEY_SPACE or k == KEY_KP_ENTER):
		_on_go()
		get_viewport().set_input_as_handled()
	if k == KEY_F2 and phase == "samen":
		_on_hint()
		get_viewport().set_input_as_handled()


# ======================================================================
#  tekenen: ring rond het juiste element, de Uil
# ======================================================================

func _draw_ring() -> void:
	if not _ring_on or _mv.is_empty() or garden == null or garden.busy:
		return
	var p: Vector2 = garden.move_screen_point(_mv)
	if p.x < 0:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := 34.0 + 6.0 * pulse
	_ring.draw_arc(p, r, 0, TAU, 48, Color(TtPal.STAR, 0.95), 5.0, true)
	_ring.draw_arc(p, r + 9.0, 0, TAU, 48, Color(TtPal.STAR, 0.35 * pulse), 3.0, true)
	# pijltje van het paneel naar het element
	var from := Vector2(PANEL_X - 6.0, clampf(p.y, panel_top() + 40.0, PANEL_BOTTOM - 40.0))
	if p.x < PANEL_X - 60.0:
		var to := p + (from - p).normalized() * (r + 12.0)
		_ring.draw_dashed_line(from, to, Color(TtPal.STAR, 0.55), 3.0, 10.0, true)


func _draw_face() -> void:
	var talk := 0.5 + 0.5 * sin(_t * 12.0) if _state in ["step", "auto", "ask"] else 0.0
	TtDraw.owl(_face, Vector2(48, 52), 0.62, _t, talk, true)
