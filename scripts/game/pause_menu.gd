class_name PauseMenu
extends Control
## Pauzemenu (GDD §7): Verder · Opnieuw · Spiekbrief · Instellingen · Kaart. Spiekbrief = 4 pictogrammen.

var depot: Node
var _panel: PanelContainer
var _sheet: Control
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG_DEEP, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var dtw := dim.create_tween().set_ignore_time_scale(true)
	dtw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	dtw.tween_property(dim, "color:a", 0.8, 0.2)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UIKit.panel_box())
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_panel.add_child(_box)
	var t := UIKit.label("PAUZE", 56, Pal.TEXT, Pal.UI_BOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	_add("Verder", Pal.OK, Pal.INK, func(): depot._close_pause())
	_add("Opnieuw", Pal.PANEL_HI, Pal.TEXT, func(): depot.restart_day())
	_add("Spiekbrief", Pal.WARN, Pal.INK, _show_sheet)
	_add("Schermschok: %s" % _shake_txt(), Pal.PANEL_HI, Pal.TEXT, _toggle_shake)
	_add("Dagenkaart", Pal.PANEL_HI, Pal.TEXT, func():
		get_tree().paused = false
		Transition.goto(Game.SCENE_MAP))
	_panel.reset_size()
	_panel.position = Vector2(960, 540) - _panel.size / 2.0
	UIKit.pop_in(_panel, 0.0, 0.25)
	(_box.get_child(1) as Button).grab_focus.call_deferred()


func _shake_txt() -> String:
	var s := float(Game.settings.shake)
	return "uit" if s <= 0.01 else ("50 %" if s < 0.9 else "100 %")


func _toggle_shake() -> void:
	var s := float(Game.settings.shake)
	Game.settings.shake = 0.5 if s > 0.9 else (0.0 if s > 0.01 else 1.0)
	Game.save_settings()
	(_box.get_child(4) as Button).text = "Schermschok: %s" % _shake_txt()
	Juice.shake(4.0, 0.2)


func _add(txt: String, col: Color, fg: Color, cb: Callable) -> void:
	var b := UIKit.button(txt, col, fg, 30, 380)
	b.pressed.connect(cb)
	_box.add_child(b)


func close_anim() -> void:
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.13)


func _show_sheet() -> void:
	if _sheet:
		_sheet.queue_free()
		_sheet = null
		return
	_sheet = CheatSheet.new()
	add_child(_sheet)
	_sheet.position = Vector2(960, 540) - CheatSheet.SIZE / 2.0
	_panel.visible = false
	_sheet.closed.connect(func():
		_sheet = null
		_panel.visible = true)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _sheet:
			_sheet.queue_free()
			_sheet = null
			_panel.visible = true
		else:
			depot._close_pause()
