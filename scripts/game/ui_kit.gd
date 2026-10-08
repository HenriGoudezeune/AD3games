class_name UIKit
extends Object
## Knoppen, panelen en thema volgens ART.md §3–4 (StyleBoxFlat, "drukbare" knoppen).

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = Pal.UI
	_theme.default_font_size = 24
	_theme.set_color("font_color", "Label", Pal.TEXT)
	return _theme


static func _btn_box(col: Color, lift := 0.0) -> StyleBoxFlat:
	var s := Pal.sbn(col, 18)
	s.border_color = col.darkened(0.35)
	s.border_width_bottom = int(6 - lift)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 10 + lift
	s.content_margin_bottom = 10
	s.expand_margin_top = lift
	s.shadow_color = Color(0.02, 0.03, 0.08, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	return s


## Knop met kleur `col`, tekstkleur `fg`. Hover: 3 px omhoog; klik: squash + geluid.
static func button(text: String, col := Pal.PANEL_HI, fg := Pal.TEXT, size := 30, min_w := 280.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", Pal.UI_BOLD)
	b.add_theme_font_size_override("font_size", size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	b.add_theme_stylebox_override("normal", _btn_box(col))
	b.add_theme_stylebox_override("hover", _btn_box(col.lightened(0.08), 3))
	b.add_theme_stylebox_override("pressed", _btn_box(col.darkened(0.08), -3))
	b.add_theme_stylebox_override("disabled", _btn_box(col.darkened(0.3)))
	var f := _btn_box(col.lightened(0.08), 3)
	f.border_color = Pal.INFO
	f.set_border_width_all(4)
	f.border_width_bottom = 4
	b.add_theme_stylebox_override("focus", f)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.mouse_entered.connect(func():
		if not b.disabled:
			Sfx.ui("hover", -10.0))
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		var tw := b.create_tween().set_ignore_time_scale(true)
		tw.tween_property(b, "scale", Vector2(1.06, 0.92), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	b.pressed.connect(func(): Sfx.ui("click"))
	return b


static func label(text: String, size := 24, col := Pal.TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else Pal.UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


static func panel_box(col := Pal.PANEL, radius := 26) -> StyleBoxFlat:
	var s := Pal.sbn(col, radius, 20, Vector2(0, 10))
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s


## Pop-in (TRANS_BACK) van een Control/Node2D.
static func pop_in(n: CanvasItem, delay := 0.0, dur := 0.22) -> void:
	if n is Control:
		(n as Control).pivot_offset = (n as Control).size / 2.0
	n.scale = Vector2(0.01, 0.01)
	var tw := n.create_tween().set_ignore_time_scale(true)
	tw.tween_interval(delay)
	tw.tween_property(n, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
