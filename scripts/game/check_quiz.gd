class_name CheckQuiz
extends Control
## Check-vragen (design/LEARNING_PATH_hashdash.md): 1–2 vragen over de delen van een dag, telkens op een NIEUW
## willekeurig voorbeeld (HDLessons.check_question, antwoord berekend met de core). Figuur zoals in de notas (NotasView).
## Fout -> uitleg + "Nieuw voorbeeld" (max. 2 herkansingen per deel). Juist -> deel "begrepen" (badge op de kaart).

signal finished(results: Dictionary)   # {deel: true/false}

var parts: Array = []
var auto_answer := false
var _i := 0
var _tries := 0
var _q: Dictionary = {}
var _done := false
var _results := {}
var _rng := RandomNumberGenerator.new()
var _answered := false

var _notas: NotasView
var _head: Label
var _qtext: RichTextLabel
var _opts: VBoxContainer
var _fb: RichTextLabel
var _next: Button
var _auto_t := 0.0
var _n_answers := 0


static func open(parent: Node, parts_: Array, layer := 45) -> CheckQuiz:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var q := CheckQuiz.new()
	q.parts = parts_
	q.auto_answer = Game.cmd.has("auto-answer")
	cl.add_child(q)
	return q


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	if Game.cmd.has("check-seed"):
		_rng.seed = int(Game.cmd["check-seed"])
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG_DEEP, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	var sb := UIKit.panel_box(Pal.PANEL, 26)
	sb.border_color = Pal.INFO
	sb.border_width_top = 8
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(120, 110)
	panel.size = Vector2(1680, 860)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	_head = UIKit.label("", 30, Pal.INFO, Pal.UI_BOLD)
	vb.add_child(_head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	_notas = NotasView.new()
	_notas.custom_minimum_size = Vector2(760, 560)
	hb.add_child(_notas)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	hb.add_child(right)
	_qtext = _rich(30)
	_qtext.custom_minimum_size = Vector2(0, 130)
	right.add_child(_qtext)
	_opts = VBoxContainer.new()
	_opts.add_theme_constant_override("separation", 10)
	right.add_child(_opts)
	_fb = _rich(25)
	_fb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_fb)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(row)
	_next = UIKit.button("Volgende", Pal.OK, Pal.INK, 28, 260)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	UIKit.pop_in(panel, 0.0, 0.25)
	_new_question()


func _rich(fs: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", Pal.UI)
	r.add_theme_font_override("bold_font", Pal.UI_BOLD)
	r.add_theme_font_override("mono_font", Pal.MONO)
	for k in ["normal_font_size", "bold_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fs)
	r.add_theme_color_override("default_color", Pal.TEXT)
	return r


func _new_question() -> void:
	var id: String = parts[_i]
	_q = HDLessons.shuffled(HDLessons.check_question(id, _rng), _rng)
	_answered = false
	var P := HDLessons.part(id)
	_head.text = "CHECK  ·  vraag %d van %d  ·  deel %d: %s%s" % [_i + 1, parts.size(), HDLessons.index_of_part(id) + 1, P.title,
		"  ·  nieuw voorbeeld" if _tries > 0 else ""]
	var fig: Dictionary = _q.get("fig", {})
	_notas.set_snapshot(fig.get("snapshot", {}), "Nieuw voorbeeld: " + str(fig.get("title", "")))
	_qtext.text = "[b]%s[/b]" % _q.get("q", "")
	for ch in _opts.get_children():
		ch.queue_free()
	var opts: Array = _q.get("options", [])
	for k in opts.size():
		var b := UIKit.button("%d   %s" % [k + 1, opts[k]], Pal.PANEL_HI, Pal.TEXT, 26, 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_answer.bind(k))
		_opts.add_child(b)
	_fb.text = "[color=#8D97B5]Kies een antwoord (klik of 1–%d). Reken het eerst zelf uit, zoals op het examen.[/color]" % opts.size()
	_next.visible = false
	_auto_t = 2.5


func _answer(k: int) -> void:
	if _answered:
		return
	_answered = true
	_n_answers += 1
	var corr: Array = _q.get("correct", [])
	var ok := corr.has(k)
	var kids := _opts.get_children()
	for j in kids.size():
		var b: Button = kids[j]
		b.disabled = true
		var col := Pal.PANEL_LO
		if corr.has(j):
			col = Pal.OK
		elif j == k:
			col = Pal.ERR
		b.add_theme_stylebox_override("disabled", UIKit._btn_box(col))
		b.add_theme_color_override("font_disabled_color", Pal.INK if col != Pal.PANEL_LO else Pal.TEXT_DIM)
	var id: String = parts[_i]
	if ok:
		_results[id] = true
		HDLessons.mark(id, "check")
		Sfx.play("sfx/star_2.wav", -4.0, 1.0, false)
		_fb.text = "[color=#3DDC97][b]Juist![/b][/color] %s\n[color=#8D97B5]Deel \"%s\" is %s.[/color]" % [_q.get("explain", ""), HDLessons.part(id).title,
			"begrepen" if HDLessons.level(id) >= 3 else "gecontroleerd (oefen het nog Samen voor de badge)"]
		_next.text = "Volgende vraag" if _i + 1 < parts.size() else "Klaar"
	else:
		if not _results.has(id):
			_results[id] = false
		Sfx.play("sfx/mistake.wav", -4.0, 1.0, false)
		_fb.text = "[color=#FF5A5F][b]Niet juist.[/b][/color] %s" % _q.get("explain", "")
		if _tries < 2:
			_fb.text += "\n[color=#8D97B5]Probeer een nieuw voorbeeld van hetzelfde soort.[/color]"
			_next.text = "Nieuw voorbeeld"
		else:
			_next.text = "Volgende vraag" if _i + 1 < parts.size() else "Klaar"
	_next.visible = true
	_auto_t = 3.5


func _on_next() -> void:
	if not _answered:
		return
	var id: String = parts[_i]
	if not bool(_results.get(id, false)) and _tries < 2:
		_tries += 1
		_new_question()
		return
	_i += 1
	_tries = 0
	if _i >= parts.size():
		_close()
		return
	_new_question()


func _close() -> void:
	if _done:
		return
	_done = true
	finished.emit(_results)
	var layer := get_parent()
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		if layer is CanvasLayer:
			layer.queue_free()
		else:
			queue_free())


func _process(delta: float) -> void:
	if not auto_answer or _done:
		return
	_auto_t -= delta
	if _auto_t > 0.0:
		return
	if not _answered:
		var corr: Array = _q.get("correct", [])
		var pick: int = int(corr[0]) if not corr.is_empty() else 0
		if _n_answers == 0:
			for j in (_q.get("options", []) as Array).size():
				if not corr.has(j):
					pick = j
					break
		_answer(pick)
	else:
		_on_next()


func _input(ev: InputEvent) -> void:
	if _done or not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k := (ev as InputEventKey).keycode
	if k >= KEY_1 and k <= KEY_4:
		if not _answered and k - KEY_1 < (_q.get("options", []) as Array).size():
			_answer(k - KEY_1)
	elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
		if _answered:
			_on_next()
	elif k == KEY_ESCAPE:
		_close()
	elif (ev as InputEventKey).ctrl_pressed:
		return
	get_viewport().set_input_as_handled()
