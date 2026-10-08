class_name SettingsPanel
extends Control
## Instellingen: muziek- en effectenvolume, schermschok 0/50/100 %, volledig scherm.

var _panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG_DEEP, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UIKit.panel_box())
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_panel.add_child(v)
	var t := UIKit.label("Instellingen", 44, Pal.TEXT, Pal.UI_BOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_slider("Muziek", "music"))
	v.add_child(_slider("Effecten", "sfx"))
	var sh := UIKit.button(_shake_txt(), Pal.PANEL_HI, Pal.TEXT, 26, 460)
	sh.pressed.connect(func():
		var s := float(Game.settings.shake)
		Game.settings.shake = 0.5 if s > 0.9 else (0.0 if s > 0.01 else 1.0)
		Game.save_settings()
		sh.text = _shake_txt()
		Juice.shake(4.0, 0.2))
	v.add_child(sh)
	var fs := UIKit.button(_fs_txt(), Pal.PANEL_HI, Pal.TEXT, 26, 460)
	fs.pressed.connect(func():
		Game.settings.fullscreen = not bool(Game.settings.fullscreen)
		Game.save_settings()
		fs.text = _fs_txt())
	v.add_child(fs)
	var ok := UIKit.button("Klaar", Pal.OK, Pal.INK, 30, 460)
	ok.pressed.connect(func():
		Sfx.ui("close")
		queue_free())
	v.add_child(ok)
	_panel.reset_size()
	_panel.position = Vector2(960, 540) - _panel.size / 2.0
	UIKit.pop_in(_panel)
	ok.grab_focus.call_deferred()


func _shake_txt() -> String:
	var s := float(Game.settings.shake)
	return "Schermschok: " + ("uit" if s <= 0.01 else ("50 %" if s < 0.9 else "100 %"))


func _fs_txt() -> String:
	return "Volledig scherm: " + ("aan" if bool(Game.settings.fullscreen) else "uit")


func _slider(label: String, key: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := UIKit.label(label, 26)
	l.custom_minimum_size = Vector2(140, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(300, 40)
	var grab := Pal.sbn(Pal.WARN, 12)
	s.add_theme_stylebox_override("slider", Pal.sbn(Pal.SLOT, 8))
	s.add_theme_stylebox_override("grabber_area", Pal.sbn(Pal.WARN.darkened(0.2), 8))
	s.add_theme_stylebox_override("grabber_area_highlight", Pal.sbn(Pal.WARN, 8))
	s.value_changed.connect(func(v):
		Game.settings[key] = v
		Game.apply_settings()
		Sfx.play("sfx/coin.wav", -10.0))
	s.drag_ended.connect(func(_c): Game.save_settings())
	h.add_child(s)
	return h


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
