class_name ScSettings
extends Control
## Instellingen (GDD §4.2): muziek, geluid, schermschok 0/50/100 %, kopiistsnelheid, kleurenblindmodus, hulplijnen
## (telt als hulp voor ★★★), volledig scherm. Opgeslagen via ScSave.

signal closed

var _rows: VBoxContainer


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.55)
	dim.size = size
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ScUi.panel_box())
	panel.position = Vector2(560, 150)
	panel.custom_minimum_size = Vector2(800, 0)
	add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 18)
	panel.add_child(_rows)
	_rows.add_child(ScUi.title_label("Instellingen", 52))
	_slider("Muziek", "music")
	_slider("Geluid", "sfx")
	_choice("Schermschok", "shake", [["uit", 0.0], ["50 %", 0.5], ["100 %", 1.0]])
	_choice("Kopiist", "speed", [["normaal", 0], ["snel", 1]])
	_toggle("Kleurenblindmodus", "colorblind")
	_toggle("Hulplijnen (posities, rangen; telt als hulp)", "guides")
	_toggle("Volledig scherm", "fullscreen")
	var back := ScUi.button("Terug", ScUi.Kind.PRIMARY, 28, 300)
	back.pressed.connect(_close)
	_rows.add_child(back)
	back.grab_focus.call_deferred()


func _row(text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := ScUi.label(text, 26)
	l.custom_minimum_size = Vector2(330, 0)
	h.add_child(l)
	_rows.add_child(h)
	return h


func _slider(text: String, key: String) -> void:
	var h := _row(text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(ScSession.setting(key))
	s.custom_minimum_size = Vector2(380, 36)
	s.value_changed.connect(func(v: float): ScSession.set_setting(key, v))
	h.add_child(s)


func _choice(text: String, key: String, opts: Array) -> void:
	var h := _row(text)
	var cur = ScSession.setting(key)
	for o in opts:
		var b := ScUi.button(o[0], ScUi.Kind.PRIMARY if str(cur) == str(o[1]) else ScUi.Kind.GHOST, 22, 120)
		var v = o[1]
		b.pressed.connect(func():
			ScSession.set_setting(key, v)
			for c in h.get_children():
				if c is Button:
					c.queue_free()
			_rebuild_choice(h, key, opts))
		h.add_child(b)


func _rebuild_choice(h: HBoxContainer, key: String, opts: Array) -> void:
	var cur = ScSession.setting(key)
	for o in opts:
		var b := ScUi.button(o[0], ScUi.Kind.PRIMARY if str(cur) == str(o[1]) else ScUi.Kind.GHOST, 22, 120)
		var v = o[1]
		b.pressed.connect(func():
			ScSession.set_setting(key, v)
			for c in h.get_children():
				if c is Button:
					c.queue_free()
			_rebuild_choice(h, key, opts))
		h.add_child(b)


func _toggle(text: String, key: String) -> void:
	var h := _row(text)
	var cb := CheckButton.new()
	cb.button_pressed = bool(ScSession.setting(key))
	cb.add_theme_font_override("font", ScPal.UI)
	cb.add_theme_font_size_override("font_size", 22)
	cb.toggled.connect(func(on: bool): ScSession.set_setting(key, on))
	h.add_child(cb)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
