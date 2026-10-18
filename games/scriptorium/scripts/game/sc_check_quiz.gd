class_name ScCheckQuiz
extends Control
## Check in de terugblik (leerpad, games/scriptorium/design/LEARNING_PATH.md): 1–2 vragen over de delen van het level
## op een NIEUW willekeurig voorbeeld (ScLessons.check_question, antwoord berekend met ScReference). Links het voorbeeld
## zoals op een examenblad (perkament, monoschrift), rechts de vraag. Fout = uitleg + een nieuw voorbeeld van hetzelfde
## deel (max. 2 herkansingen). Juist = deel "check" (begrepen als Samen ook gedaan is: groene badge in het getijdenboek).

signal finished(results: Dictionary)   # {deel: true/false}

var parts: Array = []
var auto_answer := false
var _i := 0
var _tries := 0
var _q: Dictionary = {}
var _answered := false
var _results := {}
var _rng := RandomNumberGenerator.new()
var _auto_t := 0.0

var _fig: RichTextLabel
var _head: Label
var _qtext: RichTextLabel
var _opts: VBoxContainer
var _fb: RichTextLabel
var _next: Button


static func open(parent: Node, parts_: Array, layer := 45) -> ScCheckQuiz:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var q := ScCheckQuiz.new()
	q.parts = parts_
	q.auto_answer = ScSession.has("auto_answer")
	cl.add_child(q)
	return q


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ScUi.theme()
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	if ScSession.has("check_seed"):
		_rng.seed = int(ScSession.arg("check_seed"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	var sb := ScUi.panel_box(ScPal.PANEL, 16)
	sb.border_color = ScPal.GILT
	sb.set_border_width_all(2)
	sb.border_width_top = 8
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(110, 90)
	panel.size = Vector2(1700, 900)
	panel.custom_minimum_size = panel.size
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	_head = ScUi.label("", 24, ScPal.GILT_LIGHT, ScPal.UI_BOLD)
	_head.clip_text = true
	_head.custom_minimum_size = Vector2(1640, 0)
	vb.add_child(_head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 26)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var paper := PanelContainer.new()
	var psb := ScUi.paper_box(10)
	psb.content_margin_left = 26
	psb.content_margin_right = 26
	psb.content_margin_top = 22
	psb.content_margin_bottom = 22
	paper.add_theme_stylebox_override("panel", psb)
	paper.custom_minimum_size = Vector2(760, 720)
	hb.add_child(paper)
	var pv := VBoxContainer.new()
	paper.add_child(pv)
	pv.add_child(ScUi.label("EXAMENBLAD · NIEUW VOORBEELD", 20, ScPal.RUBRIC, ScPal.UI_BOLD))
	_fig = RichTextLabel.new()
	_fig.bbcode_enabled = true
	_fig.fit_content = true
	_fig.scroll_active = false
	_fig.custom_minimum_size = Vector2(700, 0)
	_fig.add_theme_font_override("normal_font", ScPal.MONO_B)
	_fig.add_theme_font_override("mono_font", ScPal.MONO_B)
	_fig.add_theme_font_size_override("normal_font_size", 26)
	_fig.add_theme_font_size_override("mono_font_size", 26)
	_fig.add_theme_color_override("default_color", ScPal.INK)
	_fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.add_child(_fig)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	hb.add_child(right)
	_qtext = _rich(27)
	right.add_child(_qtext)
	_opts = VBoxContainer.new()
	_opts.add_theme_constant_override("separation", 10)
	right.add_child(_opts)
	_fb = _rich(22)
	_fb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_fb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	var close := ScUi.button("Sluiten (Esc)", ScUi.Kind.GHOST, 22, 200)
	close.pressed.connect(_close)
	row.add_child(close)
	_next = ScUi.button("Volgende", ScUi.Kind.PRIMARY, 26, 260)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	for b in [close, _next]:
		(b as Button).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		(b as Button).focus_mode = Control.FOCUS_NONE
	ScUi.pop_in(panel, 0.1)
	_new_question()


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(820, 0)
	r.add_theme_font_override("normal_font", ScPal.UI)
	r.add_theme_font_override("bold_font", ScPal.UI_BOLD)
	r.add_theme_font_override("mono_font", ScPal.MONO_M)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", ScPal.TEXT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _new_question() -> void:
	var id: String = parts[_i]
	_q = ScLessons.shuffled(ScLessons.check_question(id, _rng), _rng)
	_answered = false
	var Pt := ScLessons.part(id)
	_head.text = "CHECK  ·  VRAAG %d / %d  ·  DEEL %d: %s%s" % [_i + 1, parts.size(), ScLessons.index_of_part(id) + 1,
		str(Pt.get("title", id)).to_upper(), "  ·  NIEUW VOORBEELD" if _tries > 0 else ""]
	_fig.text = "[code]%s[/code]" % str(_q.get("fig", "")).replace("[", "[lb]")
	_qtext.text = ScLessons.bb("[b]%s[/b]" % _q.get("q", ""))
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.get("options", [])
	var fs := 25
	for o in opts:
		while fs > 15 and ScPal.text_w(ScPal.UI_MED, "1   " + str(o), fs) > 800:
			fs -= 1
	for k in opts.size():
		var b := ScUi.button("%d   %s" % [k + 1, str(opts[k])], ScUi.Kind.VELLUM, fs, 0)
		b.custom_minimum_size = Vector2(0, 58)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_answer.bind(k))
		_opts.add_child(b)
	_fb.text = "[color=%s]Reken het eerst zelf uit, zoals op het examen. Kies dan (klik of 1–%d).[/color]" % [ScLessons.C_DIM, opts.size()]
	_next.visible = false
	_auto_t = 2.5


func _answer(k: int) -> void:
	if _answered:
		return
	_answered = true
	var id: String = parts[_i]
	var ok := (_q.get("correct", []) as Array).has(k)
	var i := 0
	for b in _opts.get_children():
		if (_q.correct as Array).has(i):
			b.modulate = Color(0.75, 1.3, 0.85)
		elif i == k:
			b.modulate = Color(1.3, 0.6, 0.6)
		else:
			b.modulate = Color(1, 1, 1, 0.5)
		(b as Button).disabled = true
		i += 1
	if ok:
		ScLessons.mark(id, "check")
		_results[id] = true
		ScSnd.play("wax_seal", -4.0)
		_fb.text = ScLessons.bb("[color=%s][b]Juist![/b][/color] %s\n\n[color=%s]Deel \"%s\" is %s.[/color]" % [ScLessons.C_OK, str(_q.get("explain", "")),
			ScLessons.C_DIM, ScLessons.part(id).title, "begrepen" if ScLessons.level(id) >= 3 else "gecontroleerd (oefen het nog Samen voor de badge)"])
		_next.text = "Volgende" if _i + 1 < parts.size() else "Klaar"
	else:
		_results[id] = false
		ScSnd.play("clamp", -4.0)
		_fb.text = ScLessons.bb("[color=%s][b]Niet juist.[/b][/color] %s" % [ScLessons.C_ERR, str(_q.get("explain", ""))])
		if _tries < 2:
			_fb.text += ScLessons.bb("\n\n[color=%s]Probeer het op een nieuw voorbeeld.[/color]" % ScLessons.C_DIM)
			_next.text = "Nieuw voorbeeld"
		else:
			_fb.text += ScLessons.bb("\n\n[color=%s]Bekijk de demo opnieuw via de gids (F1 → Doel → Leerpad).[/color]" % ScLessons.C_DIM)
			_next.text = "Volgende" if _i + 1 < parts.size() else "Klaar"
	_next.visible = true
	_auto_t = 1.5


func _on_next() -> void:
	if not _answered:
		return
	var id: String = parts[_i]
	if not bool(_results.get(id, false)) and _tries < 2:
		_tries += 1
		_new_question()
		return
	_tries = 0
	_i += 1
	if _i >= parts.size():
		_close()
	else:
		_new_question()


func _close() -> void:
	finished.emit(_results)
	var cl := get_parent()
	queue_free()
	if cl is CanvasLayer:
		cl.queue_free()


func _process(delta: float) -> void:
	if not auto_answer or _auto_t <= 0.0:
		return
	_auto_t -= delta
	if _auto_t > 0.0:
		return
	if not _answered:
		_answer(int((_q.correct as Array)[0]))
	else:
		_on_next()


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := (ev as InputEventKey).keycode
	if not _answered and k >= KEY_1 and k <= KEY_9:
		var i := k - KEY_1
		if i < (_q.get("options", []) as Array).size():
			_answer(i)
	elif _answered and (k == KEY_ENTER or k == KEY_SPACE or k == KEY_KP_ENTER):
		_on_next()
	elif k == KEY_ESCAPE:
		_close()
	get_viewport().set_input_as_handled()
