class_name TtCheckQuiz
extends Control
## Check in de terugblik (leerpad, games/trietuin/design/LEARNING_PATH.md): 1–2 vragen over de delen van het level
## op een NIEUW willekeurig voorbeeld (TtLessons.check_question, antwoord berekend met de core). Links de figuur in
## notas-stijl (TtNotesView), rechts de vraag. Fout = uitleg + een nieuw voorbeeld van hetzelfde deel (max. 2
## herkansingen). Juist = deel "check" (begrepen als Samen ook gedaan is: groene badge op de kaart).

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

var _notes: TtNotesView
var _fig_box: Control
var _head: Label
var _qtext: RichTextLabel
var _opts: VBoxContainer
var _fb: RichTextLabel
var _next: Button


static func open(parent: Node, parts_: Array, layer := 45) -> TtCheckQuiz:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var q := TtCheckQuiz.new()
	q.parts = parts_
	q.auto_answer = TtSession.has("auto_answer")
	cl.add_child(q)
	return q


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = TtUi.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	if TtSession.has("check_seed"):
		_rng.seed = int(TtSession.arg("check_seed"))
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.07, 0.05, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	var sb := TtUi.panel_box(TtPal.PANEL, 26)
	sb.border_color = TtPal.STAR
	sb.border_width_top = 8
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(90, 80)
	panel.size = Vector2(1740, 920)
	panel.custom_minimum_size = panel.size
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	_head = TtUi.label("", 28, TtPal.STAR, TtPal.UI_BOLD)
	vb.add_child(_head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 26)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	_fig_box = Panel.new()
	_fig_box.custom_minimum_size = Vector2(860, 720)
	var fsb := TtUi.paper_box(18)
	_fig_box.add_theme_stylebox_override("panel", fsb)
	hb.add_child(_fig_box)
	_notes = TtNotesView.new()
	_notes.position = Vector2(8, 8)
	_notes.size = Vector2(844, 704)
	_fig_box.add_child(_notes)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	hb.add_child(right)
	_qtext = _rich(27)
	right.add_child(_qtext)
	_opts = VBoxContainer.new()
	_opts.add_theme_constant_override("separation", 10)
	right.add_child(_opts)
	_fb = _rich(23)
	_fb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_fb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(row)
	_next = TtUi.button("Volgende", TtUi.Kind.PRIMARY, 28, 240)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	TtUi.pop_in(panel, 0.0, 0.25)
	_new_question()


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(760, 0)
	r.add_theme_font_override("normal_font", TtPal.UI)
	r.add_theme_font_override("bold_font", TtPal.UI_BOLD)
	r.add_theme_font_override("mono_font", TtPal.MONO_B)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", TtPal.TEXT)
	return r


func _new_question() -> void:
	var id: String = parts[_i]
	_q = TtLessons.shuffled(TtLessons.check_question(id, _rng), _rng)
	_answered = false
	var Pt := TtLessons.part(id)
	_head.text = "CHECK  ·  vraag %d van %d  ·  deel %d: %s%s" % [_i + 1, parts.size(), TtLessons.index_of_part(id) + 1, Pt.get("title", id),
		"  ·  nieuw voorbeeld" if _tries > 0 else ""]
	var fig: Dictionary = _q.get("fig", {})
	_notes.rect = Rect2(Vector2.ZERO, _notes.size)
	_notes.setup(fig.get("rn", []), int(fig.get("kind", 0)), str(fig.get("letters", "ACGT_")), int(fig.get("pos_base", 0)),
		str(fig.get("text", "")), "Nieuw voorbeeld: " + str(fig.get("title", "")))
	_qtext.text = "[b]%s[/b]" % _q.get("q", "")
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.get("options", [])
	for k in opts.size():
		var b := TtUi.button("%d   %s" % [k + 1, opts[k]], TtUi.Kind.SECONDARY, 25, 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_answer.bind(k))
		_opts.add_child(b)
	_fb.text = "[color=#A9C0AC]Reken het eerst zelf uit, zoals op het examen. Kies dan (klik of 1–%d).[/color]" % opts.size()
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
		b.disabled = true
		i += 1
	if ok:
		TtLessons.mark(id, "check")
		_results[id] = true
		TtSnd.play("stamp", -4.0)
		_fb.text = "[color=#3DDC97][b]Juist![/b][/color] %s\n\n[color=#A9C0AC]Deel \"%s\" is %s.[/color]" % [_q.get("explain", ""),
			TtLessons.part(id).title, "begrepen" if TtLessons.level(id) >= 3 else "gecontroleerd (oefen het nog Samen voor de badge)"]
		_next.text = "Volgende" if _i + 1 < parts.size() else "Klaar"
	else:
		_results[id] = false
		TtSnd.play("clonk", -4.0)
		_fb.text = "[color=#FF5A5F][b]Niet juist.[/b][/color] %s" % _q.get("explain", "")
		if _tries < 2:
			_fb.text += "\n\n[color=#A9C0AC]Probeer het op een nieuw voorbeeld.[/color]"
			_next.text = "Nieuw voorbeeld"
		else:
			_fb.text += "\n\n[color=#A9C0AC]Bekijk de demo opnieuw via de gids (F1, Doel → Leerpad).[/color]"
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
