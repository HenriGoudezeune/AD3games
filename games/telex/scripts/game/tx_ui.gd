class_name TxUi
extends Object
## UI-hulpjes bovenop TxPal: knoppen met geluid, de korrel/vignet-overlay, een modale laag, een papieren label.

## Bakelieten toets met klik- en hovergeluid. kind: "key" | "brass" | "red" | "flat".
static func button(text: String, kind := "key", size := 28, min_w := 260.0, sub := "") -> Button:
	var b := TxPal.button(text, kind, size, min_w)
	if sub != "":
		b.text = text + "\n" + sub
		b.add_theme_constant_override("line_spacing", -6)
	b.mouse_entered.connect(func():
		if not b.disabled:
			TxSnd.ui("hover"))
	b.button_down.connect(func(): TxSnd.ui("key"))
	b.focus_mode = Control.FOCUS_NONE
	return b


## Kleine knop met een sneltoets eronder (contextknoppen van de console).
static func key_button(text: String, key: String, kind := "key", w := 230.0, size := 26) -> Button:
	var b := button(text, kind, size, w)
	b.custom_minimum_size = Vector2(w, 70)
	b.set_meta("key", key)
	var l := Label.new()
	l.text = key
	l.add_theme_font_override("font", TxPal.MONO)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(TxPal.TEXT_ON_BRASS if kind == "brass" else TxPal.TEXT_DIM, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(w / 2.0 - 60, 46)
	l.size = Vector2(120, 18)
	b.add_child(l)
	b.add_theme_constant_override("h_separation", 0)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_stylebox_override("normal", _padded(b.get_theme_stylebox("normal")))
	b.add_theme_stylebox_override("hover", _padded(b.get_theme_stylebox("hover")))
	b.add_theme_stylebox_override("pressed", _padded(b.get_theme_stylebox("pressed")))
	b.add_theme_stylebox_override("disabled", _padded(b.get_theme_stylebox("disabled")))
	return b


static func _padded(sb: StyleBox) -> StyleBox:
	if sb == null:
		return sb
	var s := sb.duplicate() as StyleBox
	s.content_margin_bottom = 24
	s.content_margin_top = 4
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s


## Korrel + vignet + lichte scanlines over het hele scherm (bovenste laag).
static func overlay(parent: Node, layer := 60) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = layer
	parent.add_child(cl)
	var r := ColorRect.new()
	r.size = Vector2(1920, 1080)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = load("res://games/telex/assets/art/shaders/tx_overlay.gdshader")
	if sh != null:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("grain_tex", TxPal.tex("tex/grain.png"))
		r.material = mat
	else:
		r.color = Color(0, 0, 0, 0)
	cl.add_child(r)
	return cl


## Halfdoorzichtige donkere laag die alle klikken opvangt (modale schermen).
static func dimmer(parent: Node, a := 0.62) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(TxPal.NIGHT, a)
	d.size = Vector2(1920, 1080)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(d)
	d.modulate.a = 0.0
	d.create_tween().tween_property(d, "modulate:a", 1.0, 0.18)
	return d


static func label(text: String, size := 24, col := TxPal.TEXT, font: Font = null, wrap_w := 0.0) -> Label:
	var l := TxPal.label(text, size, col, font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_w > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_w, 0)
	return l


## Pop-in van een Control (schaal 0.9 → 1, alfa).
static func pop_in(c: Control, dur := 0.22) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(0.92, 0.92)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true).set_ignore_time_scale(true)
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.7)


## Schud een Control horizontaal (geweigerde knop).
static func wobble(c: Control) -> void:
	var x0 := c.position.x
	var tw := c.create_tween()
	for k in 4:
		tw.tween_property(c, "position:x", x0 + (8.0 if k % 2 == 0 else -8.0) * (1.0 - k * 0.2), 0.04)
	tw.tween_property(c, "position:x", x0, 0.05)


## Achtergrond: bunkermuur, gedimd.
static func draw_bunker(ci: CanvasItem, dim := 0.0) -> void:
	ci.draw_texture_rect(TxPal.tex("bg/bunker_wall.jpg"), Rect2(0, 0, 1920, 1080), false)
	if dim > 0.0:
		ci.draw_rect(Rect2(0, 0, 1920, 1080), Color(TxPal.NIGHT, dim))
