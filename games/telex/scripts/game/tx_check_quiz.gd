class_name TxCheckQuiz
extends Control
## Check in de terugblik (leerpad, games/telex/design/LEARNING_PATH.md): 1–2 vragen over de delen van het level op
## een NIEUW willekeurig voorbeeld (TxLessons.check_question, antwoord berekend met TxReference). Links het voorbeeld
## zoals op een examenblad (papier, monoschrift), rechts de vraag. Fout = uitleg + een nieuw voorbeeld van hetzelfde
## deel (max. 2 herkansingen). Juist = deel "check" (begrepen als Samen ook gedaan is: groene badge op de kaart).

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


static func open(parent: Node, parts_: Array, layer := 45) -> TxCheckQuiz:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var q := TxCheckQuiz.new()
	q.parts = parts_
	q.auto_answer = TxSession.has("auto_answer")
	cl.add_child(q)
	return q


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = TxPal.theme()
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	if TxSession.has("check_seed"):
		_rng.seed = int(TxSession.arg("check_seed"))
	TxUi.dimmer(self, 0.82)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TxPal.CONSOLE
	sb.border_color = TxPal.BRASS
	sb.set_border_width_all(2)
	sb.border_width_top = 8
	sb.set_corner_radius_all(14)
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
	_head = TxUi.label("", 26, TxPal.BRASS, TxPal.STENCIL)
	vb.add_child(_head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 26)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var paper := PanelContainer.new()
	var psb := StyleBoxTexture.new()
	psb.texture = TxPal.tex("tex/paper_tile.png")
	psb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	psb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	psb.content_margin_left = 26
	psb.content_margin_right = 26
	psb.content_margin_top = 22
	psb.content_margin_bottom = 22
	psb.modulate_color = Color(1.15, 1.13, 1.08)
	paper.add_theme_stylebox_override("panel", psb)
	paper.custom_minimum_size = Vector2(760, 720)
	hb.add_child(paper)
	var pv := VBoxContainer.new()
	paper.add_child(pv)
	pv.add_child(TxUi.label("EXAMENBLAD · NIEUW VOORBEELD", 18, TxPal.STAMP_RED, TxPal.STENCIL))
	_fig = RichTextLabel.new()
	_fig.bbcode_enabled = true
	_fig.fit_content = true
	_fig.scroll_active = false
	_fig.custom_minimum_size = Vector2(700, 0)
	_fig.add_theme_font_override("normal_font", TxPal.MONO_B)
	_fig.add_theme_font_override("mono_font", TxPal.MONO_B)
	_fig.add_theme_font_size_override("normal_font_size", 30)
	_fig.add_theme_font_size_override("mono_font_size", 30)
	_fig.add_theme_color_override("default_color", TxPal.INK)
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
	var close := TxUi.button("Sluiten (Esc)", "flat", 22, 200)
	close.pressed.connect(_close)
	row.add_child(close)
	_next = TxUi.button("Volgende", "brass", 26, 260)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	for b in [close, _next]:
		(b as Button).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	TxUi.pop_in(panel, 0.25)
	_new_question()


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(820, 0)
	r.add_theme_font_override("normal_font", TxPal.UI)
	r.add_theme_font_override("bold_font", TxPal.UI_BOLD)
	r.add_theme_font_override("mono_font", TxPal.MONO_B)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", TxPal.TEXT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _new_question() -> void:
	var id: String = parts[_i]
	_q = TxLessons.shuffled(TxLessons.check_question(id, _rng), _rng)
	_answered = false
	var Pt := TxLessons.part(id)
	_head.text = "CHECK  ·  VRAAG %d VAN %d  ·  DEEL %d: %s%s" % [_i + 1, parts.size(), TxLessons.index_of_part(id) + 1, str(Pt.get("title", id)).to_upper(),
		"  ·  NIEUW VOORBEELD" if _tries > 0 else ""]
	_fig.text = "[code]%s[/code]" % str(_q.get("fig", "")).replace("[", "[lb]")
	_qtext.text = TxLessons.bb("[b]%s[/b]" % _q.get("q", ""))
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.get("options", [])
	for k in opts.size():
		var b := TxUi.button("%d   %s" % [k + 1, opts[k]], "key", 25, 0)
		b.custom_minimum_size = Vector2(0, 58)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(_answer.bind(k))
		_opts.add_child(b)
	_fb.text = "[color=%s]Reken het eerst zelf uit, zoals op het examen. Kies dan (klik of 1–%d).[/color]" % [TxLessons.C_DIM, opts.size()]
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
		TxLessons.mark(id, "check")
		_results[id] = true
		TxSnd.play("stamp", -4.0)
		_fb.text = TxLessons.bb("[color=%s][b]Juist![/b][/color] %s\n\n[color=%s]Deel \"%s\" is %s.[/color]" % [TxLessons.C_OK, str(_q.get("explain", "")),
			TxLessons.C_DIM, TxLessons.part(id).title, "begrepen" if TxLessons.level(id) >= 3 else "gecontroleerd (oefen het nog Samen voor de badge)"])
		_next.text = "Volgende" if _i + 1 < parts.size() else "Klaar"
	else:
		_results[id] = false
		TxSnd.play("bump", -4.0)
		_fb.text = TxLessons.bb("[color=%s][b]Niet juist.[/b][/color] %s" % [TxLessons.C_ERR, str(_q.get("explain", ""))])
		if _tries < 2:
			_fb.text += TxLessons.bb("\n\n[color=%s]Probeer het op een nieuw voorbeeld.[/color]" % TxLessons.C_DIM)
			_next.text = "Nieuw voorbeeld"
		else:
			_fb.text += TxLessons.bb("\n\n[color=%s]Bekijk de demo opnieuw via de gids (F1 → Doel → Leerpad).[/color]" % TxLessons.C_DIM)
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
