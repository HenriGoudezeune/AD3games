class_name TtSettings
extends Control
## Instellingen (GDD §4.2): muziek, geluid, schermschok 0/50/100 %, leeshulp altijd aan, volledig scherm.
## Opslag via TtSave.set_setting; toepassen via `TtSettings.apply_all()` (ook bij het opstarten van de titel).

signal closed

var _panel: PanelContainer


static func apply_all() -> void:
	var sfx: Node = Engine.get_main_loop().root.get_node_or_null("Sfx") if Engine.get_main_loop() else null
	if sfx:
		sfx.set("music_volume", float(TtSave.setting("music", 0.8)))
		sfx.set("sfx_volume", float(TtSave.setting("sfx", 0.9)))
	var j: Node = Engine.get_main_loop().root.get_node_or_null("Juice") if Engine.get_main_loop() else null
	if j:
		j.set("shake_scale", float(TtSave.setting("shake", 1.0)))
	var fs := bool(TtSave.setting("fullscreen", false))
	var cur := DisplayServer.window_get_mode()
	if fs and cur != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fs and cur == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = TtUi.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.04, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", TtUi.panel_box())
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_panel.add_child(v)
	var t := TtUi.label("Instellingen", 44, TtPal.TEXT, TtPal.UI_BOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_slider("Muziek", "music", 0.8))
	v.add_child(_slider("Geluid", "sfx", 0.9))
	var sh := TtUi.button(_shake_txt(), TtUi.Kind.SECONDARY, 26, 480)
	sh.pressed.connect(func():
		var s := float(TtSave.setting("shake", 1.0))
		TtSave.set_setting("shake", 0.5 if s > 0.9 else (0.0 if s > 0.01 else 1.0))
		apply_all()
		sh.text = _shake_txt()
		Juice.shake(4.0, 0.2))
	v.add_child(sh)
	var lh := TtUi.button(_hint_txt(), TtUi.Kind.SECONDARY, 26, 480)
	lh.pressed.connect(func():
		TtSave.set_setting("always_hint", not bool(TtSave.setting("always_hint", false)))
		lh.text = _hint_txt())
	v.add_child(lh)
	var fs := TtUi.button(_fs_txt(), TtUi.Kind.SECONDARY, 26, 480)
	fs.pressed.connect(func():
		TtSave.set_setting("fullscreen", not bool(TtSave.setting("fullscreen", false)))
		apply_all()
		fs.text = _fs_txt())
	v.add_child(fs)
	var ok := TtUi.button("Klaar", TtUi.Kind.PRIMARY, 30, 480)
	ok.pressed.connect(_close)
	v.add_child(ok)
	_panel.reset_size()
	_panel.position = Vector2(960, 540) - _panel.size / 2.0
	TtUi.pop_in(_panel)
	ok.grab_focus.call_deferred()


func _close() -> void:
	closed.emit()
	queue_free()


func _shake_txt() -> String:
	var s := float(TtSave.setting("shake", 1.0))
	return "Schermschok: " + ("uit" if s <= 0.01 else ("50 %" if s < 0.9 else "100 %"))


func _hint_txt() -> String:
	return "Leeshulp altijd aan: " + ("ja" if bool(TtSave.setting("always_hint", false)) else "nee")


func _fs_txt() -> String:
	return "Volledig scherm: " + ("aan" if bool(TtSave.setting("fullscreen", false)) else "uit")


func _slider(label: String, key: String, def: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := TtUi.label(label, 26)
	l.custom_minimum_size = Vector2(140, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(TtSave.setting(key, def))
	s.custom_minimum_size = Vector2(320, 40)
	s.add_theme_stylebox_override("slider", TtPal.sbn(TtPal.SLOT, 8))
	s.add_theme_stylebox_override("grabber_area", TtPal.sbn(TtPal.SAP_DARK, 8))
	s.add_theme_stylebox_override("grabber_area_highlight", TtPal.sbn(TtPal.SAP, 8))
	s.value_changed.connect(func(val):
		TtSave.set_setting(key, val)
		apply_all()
		TtSnd.play("sap_drop", -8.0))
	h.add_child(s)
	return h


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
