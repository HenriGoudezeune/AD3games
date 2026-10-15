class_name TxSettings
extends Control
## Instellingen (GDD §4.2): muziek, geluid, schermschok 0/50/100 %, tekstgrootte 100/125 %, naaldsnelheid,
## live-tempo 100/80 % (telt als hulp), kleurenblindmodus, volledig scherm. Bewaard via TxSave (settings).

var _rows: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.5)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", TxPal.panel_box(TxPal.CONSOLE, 14))
	_panel.position = Vector2(560, 150)
	_panel.custom_minimum_size = Vector2(800, 0)
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)
	var ttl := TxUi.label("INSTELLINGEN", 36, TxPal.BRASS, TxPal.STENCIL)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(ttl)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	col.add_child(_rows)
	_slider("Muziek", "music")
	_slider("Geluid", "sfx")
	_cycle("Schermschok", "shake", [[0.0, "uit"], [0.5, "50 %"], [1.0, "100 %"]])
	_cycle("Tekstgrootte", "text", [[1.0, "100 %"], [1.25, "125 %"]])
	_cycle("Naaldsnelheid", "fast_needle", [[false, "normaal"], [true, "snel"]])
	_cycle("Live-tempo", "tempo80", [[false, "100 %"], [true, "80 % (telt als hulp)"]])
	_cycle("Kleurenblindmodus", "colorblind", [[false, "uit"], [true, "aan (vormen op lampjes)"]])
	_cycle("Volledig scherm", "fullscreen", [[false, "uit"], [true, "aan"]])
	var back := TxUi.button("Terug", "brass", 26, 300)
	back.pressed.connect(queue_free)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	col.add_child(hb)
	TxUi.pop_in(_panel)


func key(e: InputEventKey) -> bool:
	if e.keycode == KEY_ESCAPE:
		queue_free()
		return true
	return false


func _row(label: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	var l := TxUi.label(label, 24, TxPal.TEXT)
	l.custom_minimum_size = Vector2(280, 0)
	hb.add_child(l)
	_rows.add_child(hb)
	return hb


func _slider(label: String, k: String) -> void:
	var hb := _row(label)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(TxSession.setting(k))
	s.custom_minimum_size = Vector2(400, 40)
	s.add_theme_stylebox_override("slider", TxPal.sbn(TxPal.CONSOLE_LO, 6))
	var gr := TxPal.sbn(TxPal.BRASS_LO, 6)
	s.add_theme_stylebox_override("grabber_area", gr)
	s.add_theme_stylebox_override("grabber_area_highlight", TxPal.sbn(TxPal.BRASS, 6))
	s.value_changed.connect(func(v: float):
		TxSession.set_setting(k, v)
		TxSnd.play("ui_switch", -10.0, 0.8 + v * 0.4, false, 60))
	hb.add_child(s)


func _cycle(label: String, k: String, opts: Array) -> void:
	var hb := _row(label)
	var cur = TxSession.setting(k)
	var idx := 0
	for i in opts.size():
		if typeof(opts[i][0]) == typeof(cur) and opts[i][0] == cur:
			idx = i
		elif (cur is float or cur is int) and (opts[i][0] is float) and is_equal_approx(float(opts[i][0]), float(cur)):
			idx = i
	var b := TxUi.button(str(opts[idx][1]), "key", 22, 400)
	b.set_meta("i", idx)
	b.pressed.connect(func():
		var i2 := (int(b.get_meta("i")) + 1) % opts.size()
		b.set_meta("i", i2)
		b.text = str(opts[i2][1])
		TxSession.set_setting(k, opts[i2][0])
		TxSnd.ui("switch"))
	hb.add_child(b)
