class_name TtUi
extends Object
## Trietuin: thema, knoppen en panelen (design/ART.md §4 en §7). Zelfde "drukbare" mechaniek als Hash & Dash
## (UIKit), maar in Trietuin-kleuren. Geluid via de gedeelde autoload Sfx (Kenney-UI-klikjes = familie).

enum Kind { PRIMARY, SECONDARY, SAP, GHOST, DANGER }

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = TtPal.UI
	_theme.default_font_size = 24
	_theme.set_color("font_color", "Label", TtPal.TEXT)
	return _theme


static func kind_colors(kind: int) -> Array:
	match kind:
		Kind.PRIMARY:
			return [TtPal.BRAND, TtPal.INK]
		Kind.SAP:
			return [TtPal.SAP, TtPal.INK]
		Kind.GHOST:
			return [TtPal.PANEL_LO, TtPal.TEXT_DIM]
		Kind.DANGER:
			return [Color("#E9796B"), TtPal.INK]
		_:
			return [TtPal.PANEL_HI, TtPal.TEXT]


static func _btn_box(col: Color, lift := 0.0) -> StyleBoxFlat:
	var s := TtPal.sbn(col, 20)
	s.border_color = col.darkened(0.35)
	s.border_width_bottom = int(6 - lift)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 10 + lift
	s.content_margin_bottom = 10
	s.expand_margin_top = lift
	s.shadow_color = Color(0.05, 0.08, 0.03, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	return s


## Knop. Hover: 3 px omhoog; indrukken: squash (1.06, 0.92) -> elastisch terug; klik-geluid.
static func button(text: String, kind := Kind.SECONDARY, size := 30, min_w := 260.0) -> Button:
	var kc := kind_colors(kind)
	var col: Color = kc[0]
	var fg: Color = kc[1]
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", TtPal.UI_BOLD)
	b.add_theme_font_size_override("font_size", size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	b.add_theme_stylebox_override("normal", _btn_box(col))
	b.add_theme_stylebox_override("hover", _btn_box(col.lightened(0.08), 3))
	b.add_theme_stylebox_override("pressed", _btn_box(col.darkened(0.08), -3))
	b.add_theme_stylebox_override("disabled", _btn_box(col.darkened(0.3)))
	var f := _btn_box(col.lightened(0.08), 3)
	f.border_color = TtPal.INFO
	f.set_border_width_all(4)
	f.border_width_bottom = 4
	b.add_theme_stylebox_override("focus", f)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.mouse_entered.connect(func():
		if not b.disabled and b.is_inside_tree():
			b.get_node("/root/Sfx").ui("hover", -10.0))
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		var tw := b.create_tween().set_ignore_time_scale(true)
		tw.tween_property(b, "scale", Vector2(1.06, 0.92), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	b.pressed.connect(func():
		if b.is_inside_tree():
			b.get_node("/root/Sfx").ui("click"))
	return b


## Ronde icoonknop (pauze, terug, instellingen). Icoon = Kenney Game Icon (res://assets/art/icons/<name>.png).
static func icon_button(icon: String, kind := Kind.SECONDARY, d := 60.0) -> Button:
	var b := button("", kind, 24, d)
	b.custom_minimum_size = Vector2(d, d)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat = (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate()
		sb.set_corner_radius_all(int(d / 2))
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		b.add_theme_stylebox_override(st, sb)
	var p := "res://assets/art/icons/%s.png" % icon
	if ResourceLoader.exists(p):
		b.icon = load(p)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_color_override("icon_normal_color", kind_colors(kind)[1])
		b.add_theme_color_override("icon_hover_color", kind_colors(kind)[1])
		b.add_theme_color_override("icon_pressed_color", kind_colors(kind)[1])
		b.add_theme_color_override("icon_focus_color", kind_colors(kind)[1])
		b.add_theme_constant_override("icon_max_width", int(d * 0.5))
	return b


static func label(text: String, size := 24, col := TtPal.TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else TtPal.UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


## Mono-label (woorden, strings uit de lesnotas). Altijd INK op papier of TEXT op donker.
static func mono_label(text: String, size := 26, col := TtPal.TEXT) -> Label:
	return label(text, size, col, TtPal.MONO)


## Donker bospaneel (HUD, menu's, pauze).
static func panel_box(col := TtPal.PANEL, radius := 26) -> StyleBoxFlat:
	var s := TtPal.sbn(col, radius, 20, Vector2(0, 10))
	s.border_color = col.lightened(0.10)
	s.border_width_top = 2
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s


## Papieren kaart (rapport, uitleg, notas-weergave): INK erop.
static func paper_box(radius := 22) -> StyleBoxFlat:
	var s := TtPal.sbn(TtPal.PAPER, radius, 18, Vector2(0, 10))
	s.border_color = TtPal.PAPER_EDGE
	s.border_width_bottom = 8
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 28
	s.content_margin_bottom = 32
	return s


## Pop-in (TRANS_BACK) van een Control/Node2D.
static func pop_in(n: CanvasItem, delay := 0.0, dur := 0.22) -> void:
	if n is Control:
		(n as Control).pivot_offset = (n as Control).size / 2.0
	n.scale = Vector2(0.01, 0.01)
	var tw := n.create_tween().set_ignore_time_scale(true)
	tw.tween_interval(delay)
	tw.tween_property(n, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
