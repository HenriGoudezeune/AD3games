class_name ScUi
extends Object
## Kortschrift: thema, knoppen en panelen (design/ART.md §4). Zelfde "drukbare" mechaniek als Hash & Dash en Trietuin
## (hover 3 px omhoog, squash bij indrukken, Kenney-klikjes via de gedeelde autoload Sfx), maar in boekbandleer,
## bladgoud, perkament en zegelwas.

enum Kind { PRIMARY, SECONDARY, WAX, GHOST, VELLUM }

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = ScPal.UI
	_theme.default_font_size = 24
	_theme.set_color("font_color", "Label", ScPal.TEXT)
	return _theme


## [vlak, tekst, rand] per soort. PRIMARY = bladgoud met inkt, SECONDARY = leer met goudrand, WAX = zegelwas
## (bevestigen/verzenden), GHOST = verzonken leer, VELLUM = perkament (in de wereld, bv. "Geen match").
static func kind_colors(kind: int) -> Array:
	match kind:
		Kind.PRIMARY:
			return [ScPal.GOLD, ScPal.INK, ScPal.GOLD_DARK]
		Kind.WAX:
			return [ScPal.WAX, ScPal.VELLUM_HI, ScPal.WAX_DARK]
		Kind.GHOST:
			return [ScPal.PANEL_LO, ScPal.TEXT_DIM, ScPal.PANEL_LO.darkened(0.3)]
		Kind.VELLUM:
			return [ScPal.VELLUM_HI, ScPal.INK, ScPal.VELLUM_EDGE]
		_:
			return [ScPal.PANEL_HI, ScPal.TEXT, ScPal.PANEL.darkened(0.35)]


static func _btn_box(col: Color, edge: Color, lift := 0.0, gilt := false) -> StyleBoxFlat:
	var s := ScPal.sbn(col, 14)
	s.border_color = edge
	s.border_width_bottom = int(6 - lift)
	if gilt:
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_color = ScPal.GILT_DARK
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 10 + lift
	s.content_margin_bottom = 10
	s.expand_margin_top = lift
	s.shadow_color = Color(0.05, 0.02, 0.01, 0.4)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	return s


## Knop. Hover: 3 px omhoog; indrukken: squash (1,06; 0,92) -> elastisch terug; klik-geluid (Sfx.ui).
static func button(text: String, kind := Kind.SECONDARY, size := 30, min_w := 260.0) -> Button:
	var kc := kind_colors(kind)
	var col: Color = kc[0]
	var fg: Color = kc[1]
	var edge: Color = kc[2]
	var gilt := kind == Kind.SECONDARY
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", ScPal.UI_BOLD)
	b.add_theme_font_size_override("font_size", size)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	b.add_theme_stylebox_override("normal", _btn_box(col, edge, 0, gilt))
	b.add_theme_stylebox_override("hover", _btn_box(col.lightened(0.08), edge, 3, gilt))
	b.add_theme_stylebox_override("pressed", _btn_box(col.darkened(0.08), edge, -3, gilt))
	b.add_theme_stylebox_override("disabled", _btn_box(col.darkened(0.3), edge.darkened(0.3), 0, gilt))
	var f := _btn_box(col.lightened(0.08), edge, 3)
	f.border_color = ScPal.INFO
	f.set_border_width_all(4)
	b.add_theme_stylebox_override("focus", f)
	b.custom_minimum_size = Vector2(min_w, 0)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.mouse_entered.connect(func():
		if not b.disabled and b.is_inside_tree() and b.has_node("/root/Sfx"):
			b.get_node("/root/Sfx").ui("hover", -10.0))
	b.button_down.connect(func():
		b.pivot_offset = b.size / 2.0
		var tw := b.create_tween().set_ignore_time_scale(true)
		tw.tween_property(b, "scale", Vector2(1.06, 0.92), 0.05)
		tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	b.pressed.connect(func():
		if b.is_inside_tree() and b.has_node("/root/Sfx"):
			b.get_node("/root/Sfx").ui("click"))
	return b


## Ronde icoonknop met een getekend goudstempel-icoon (ScDraw.tool_icon: pause, hint, undo, notes, ...).
static func icon_button(icon: String, kind := Kind.SECONDARY, d := 60.0) -> Button:
	var b := button("", kind, 24, d)
	b.custom_minimum_size = Vector2(d, d)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sbx: StyleBoxFlat = (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate()
		sbx.set_corner_radius_all(int(d / 2))
		sbx.content_margin_left = 10
		sbx.content_margin_right = 10
		b.add_theme_stylebox_override(st, sbx)
	var fg: Color = kind_colors(kind)[1]
	b.draw.connect(func():
		var lift := -3.0 if b.is_hovered() else 0.0
		ScDraw.tool_icon(b, b.size / 2 + Vector2(0, lift - 2), d * 0.24, icon, fg if kind != Kind.SECONDARY else ScPal.GILT_LIGHT))
	return b


static func label(text: String, size := 24, col := ScPal.TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else ScPal.UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


## Mono-label: bits, codes, letters, getallen. Altijd INK op perkament of TEXT op leer.
static func mono_label(text: String, size := 26, col := ScPal.TEXT) -> Label:
	return label(text, size, col, ScPal.MONO)


## Titel/kop in Grenze Gotisch (hoofdstukken, schermtitels, kopjes van panelen). Nooit voor leerstof.
static func title_label(text: String, size := 48, col := ScPal.GILT_LIGHT) -> Label:
	return label(text, size, col, ScPal.TITLE)


## Leren paneel met goudrand (HUD, menu's, pauze, De Overkant-kader).
static func panel_box(col := ScPal.PANEL, radius := 20) -> StyleBoxFlat:
	var s := ScPal.sbn(col, radius, 20, Vector2(0, 10))
	s.border_color = ScPal.GILT_DARK
	s.set_border_width_all(2)
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s


## Perkamenten kaart (Kapittel, uitleg, notas-weergave): INK erop. Voor geschepte randen in de wereld: ScDraw.parchment.
static func paper_box(radius := 10) -> StyleBoxFlat:
	var s := ScPal.sbn(ScPal.VELLUM, radius, 18, Vector2(0, 10))
	s.border_color = ScPal.VELLUM_EDGE
	s.border_width_bottom = 6
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


## Overlay-ColorRect met het kaarslicht-shader (vignet + flakkerende warme poel rond `light_pos`).
static func candle_overlay(light_pos := Vector2(150, 120), darkness := 0.45, radius := 1100.0, sz := Vector2(1920, 1080)) -> ColorRect:
	var r := ColorRect.new()
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(ScPal.ASSETS + "art/shaders/sc_candlelight.gdshader")
	m.set_shader_parameter("size_px", sz)
	m.set_shader_parameter("light_pos", light_pos)
	m.set_shader_parameter("darkness", darkness)
	m.set_shader_parameter("radius", radius)
	r.material = m
	return r


## Overlay-ColorRect met lichtbundels + stof van het glas-in-loodraam (bg_room: raam op x 960, bovenaan).
static func shafts_overlay(origin := Vector2(0.5, 0.08), strength := 0.18, sz := Vector2(1920, 1080)) -> ColorRect:
	var r := ColorRect.new()
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(ScPal.ASSETS + "art/shaders/sc_light_shafts.gdshader")
	m.set_shader_parameter("origin", origin)
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("aspect", sz.x / sz.y)
	r.material = m
	return r
