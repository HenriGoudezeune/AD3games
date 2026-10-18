class_name HubGuide
extends Control
## Gedeeld paneel "Hoe speel je dit?" (design/SHARED_UX.md §2–3): tabbladen Doel · Handelingen · Theorie,
## pagina's met titel + BBCode-tekst + optioneel schema, bladeren met ←/→, sluiten met Esc of klik ernaast.
##
##   var g := HubGuide.open(self, {
##       "title": "Hash & Dash",
##       "tabs": {"doel": [page, ...], "handelingen": [...], "theorie": [...]},   # ontbrekende tabs vallen weg
##       "tab": "theorie", "page": 0,           # optioneel: startpositie
##   })
##   # of een tutorial zonder tabbladen:  {"title": "Nieuw: de hendel", "pages": [page, ...], "tutorial": true}
##   page = {"title": String, "text": String (BBCode),
##           "schema": Texture2D | Callable(ci: Control, size: Vector2) die tekent,
##           "schema_node": Callable() -> Control (wordt ingebed),   "schema_width": float (standaard 520)}
##   g.closed.connect(...)
## `style` (alles optioneel): bg, panel, border, text, text_dim, accent, accent_text, tab, font, font_bold,
## font_mono, size (Vector2 paneel), font_size, layer (CanvasLayer, standaard 90), pause (bool, standaard true).
## Geen afhankelijkheid van game-specifieke klassen.

signal closed

const TAB_KEYS := ["doel", "handelingen", "theorie"]
const TAB_NAMES := {"doel": "Doel", "handelingen": "Handelingen", "theorie": "Theorie"}

var content: Dictionary = {}
var style: Dictionary = {}
var tab := ""
var page := 0

var _tabs: Array = []            # beschikbare tab-sleutels
var _pages: Array = []           # pagina's van de huidige tab
var _tab_btns := {}
var _page_title: RichTextLabel
var _text: RichTextLabel
var _schema_box: Control
var _prev: Button
var _next: Button
var _count: Label
var _panel: PanelContainer
var _was_paused := false
var _closing := false


## Opent het paneel in een eigen CanvasLayer onder `parent` (dus altijd schermvullend, los van camera's).
static func open(parent: Node, c: Dictionary, s: Dictionary = {}) -> HubGuide:
	var cl := CanvasLayer.new()
	cl.layer = int(s.get("layer", 90))
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var g := HubGuide.new()
	g.content = c
	g.style = s
	cl.add_child(g)
	return g


func _c(key: String, def: Color) -> Color:
	return style.get(key, def)


func _f(key: String) -> Font:
	var f = style.get(key, null)
	if f is Font:
		return f
	var path: String = {"font": "res://assets/fonts/Fredoka-SemiBold.ttf", "font_bold": "res://assets/fonts/Fredoka-Bold.ttf",
		"font_mono": "res://assets/fonts/JetBrainsMono-Bold.ttf"}.get(key, "")
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if bool(style.get("pause", true)) and is_inside_tree():
		_was_paused = get_tree().paused
		get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = _c("bg", Color(0.03, 0.04, 0.08, 0.72))
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close())
	add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = style.get("size", Vector2(1320, 780))
	var sb := StyleBoxFlat.new()
	sb.bg_color = _c("panel", Color("#1F2840"))
	sb.set_corner_radius_all(24)
	sb.border_color = _c("accent", Color("#FFB020"))
	sb.border_width_top = 10
	sb.set_content_margin_all(30)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", sb)
	cc.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	# kop: titel + sluiten
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var t := _label(str(content.get("title", "Hoe speel je dit?")), 36, _c("text", Color("#F4F1EA")), _f("font_bold"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := _button("Sluiten  (Esc)", _c("tab", Color("#34416A")), _c("text", Color("#F4F1EA")), 20)
	x.pressed.connect(close)
	head.add_child(x)
	# tabbladen
	if content.has("pages"):
		_tabs = ["_"]
	else:
		var tabs: Dictionary = content.get("tabs", {})
		for k in TAB_KEYS:
			if tabs.has(k) and not (tabs[k] as Array).is_empty():
				_tabs.append(k)
		if _tabs.size() > 0:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			v.add_child(row)
			for k in _tabs:
				var b := _button(TAB_NAMES[k], _c("tab", Color("#34416A")), _c("text", Color("#F4F1EA")), 24)
				b.toggle_mode = true
				b.custom_minimum_size = Vector2(200, 0)
				b.pressed.connect(func(): show_tab(k))
				row.add_child(b)
				_tab_btns[k] = b
			var hint := _label("Tab: volgend tabblad · pijltjes: bladeren", 18, _c("text_dim", Color("#8D97B5")), _f("font"))
			hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(hint)
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(_c("text_dim", Color("#8D97B5")), 0.3))
	v.add_child(sep)
	# inhoud: tekst links, schema rechts
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(col)
	_page_title = RichTextLabel.new()
	_page_title.bbcode_enabled = true
	_page_title.fit_content = true
	_page_title.scroll_active = false
	_page_title.focus_mode = Control.FOCUS_NONE
	_page_title.add_theme_color_override("default_color", _c("accent", Color("#FFB020")))
	var tf := _f("font_bold")
	if tf:
		_page_title.add_theme_font_override("normal_font", tf)
	_page_title.add_theme_font_size_override("normal_font_size", 30)
	col.add_child(_page_title)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.focus_mode = Control.FOCUS_NONE
	var fs := int(style.get("font_size", 24))
	_text.add_theme_color_override("default_color", _c("text", Color("#F4F1EA")))
	for pair in [["normal_font", "font"], ["bold_font", "font_bold"], ["mono_font", "font_mono"], ["italics_font", "font"]]:
		var ff := _f(pair[1])
		if ff:
			_text.add_theme_font_override(pair[0], ff)
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_text.add_theme_font_size_override(k, fs)
	_text.add_theme_font_size_override("mono_font_size", fs - 2)
	_text.add_theme_constant_override("line_separation", 6)
	col.add_child(_text)
	_schema_box = Control.new()
	_schema_box.custom_minimum_size = Vector2(0, 0)
	_schema_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_schema_box)
	# voet: vorige · k/n · volgende
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	v.add_child(foot)
	_prev = _button("‹  Vorige", _c("tab", Color("#34416A")), _c("text", Color("#F4F1EA")), 22)
	_prev.custom_minimum_size = Vector2(190, 0)
	_prev.pressed.connect(func(): flip(-1))
	foot.add_child(_prev)
	_count = _label("", 22, _c("text_dim", Color("#8D97B5")), _f("font"))
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_count)
	_next = _button("Volgende  ›", _c("accent", Color("#FFB020")), _c("accent_text", Color("#1A1F2E")), 22)
	_next.custom_minimum_size = Vector2(190, 0)
	_next.pressed.connect(func(): flip(1))
	foot.add_child(_next)
	# startpositie
	var start := str(content.get("tab", ""))
	if not _tabs.has(start):
		start = _tabs[0] if not _tabs.is_empty() else ""
	show_tab(start, int(content.get("page", 0)))
	_panel.pivot_offset = _panel.custom_minimum_size / 2.0
	_panel.scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	var tw := create_tween().set_ignore_time_scale(true).set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_next.grab_focus.call_deferred()


func show_tab(k: String, p := 0) -> void:
	tab = k
	if k == "_":
		_pages = content.get("pages", [])
	else:
		_pages = (content.get("tabs", {}) as Dictionary).get(k, [])
	for key in _tab_btns:
		var b: Button = _tab_btns[key]
		b.button_pressed = key == k
		var on: bool = key == k
		var cb := _c("accent", Color("#FFB020")) if on else _c("tab", Color("#34416A"))
		var fg := _c("accent_text", Color("#1A1F2E")) if on else _c("text", Color("#F4F1EA"))
		_style_button(b, cb, fg)
	show_page(p)


func show_page(p: int) -> void:
	page = clampi(p, 0, maxi(0, _pages.size() - 1))
	var pg: Dictionary = _pages[page] if page < _pages.size() else {}
	_page_title.text = str(pg.get("title", ""))
	_page_title.visible = _page_title.text != ""
	_text.text = str(pg.get("text", ""))
	_text.scroll_to_line(0)
	for ch in _schema_box.get_children():
		ch.queue_free()
	var has_schema := pg.has("schema") or pg.has("schema_node")
	_schema_box.visible = has_schema
	_schema_box.custom_minimum_size = Vector2(float(pg.get("schema_width", 520)), 0) if has_schema else Vector2.ZERO
	if pg.has("schema_node"):
		var cb: Callable = pg.schema_node
		var n = cb.call()
		if n is Control:
			(n as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_schema_box.add_child(n)
	elif pg.has("schema"):
		var sc := _Schema.new()
		sc.what = pg.schema
		sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_schema_box.add_child(sc)
	var n_pages := _pages.size()
	_count.text = ("%d / %d" % [page + 1, n_pages]) if n_pages > 1 else ""
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prev.disabled = page == 0
	var last := page >= n_pages - 1
	_next.text = ("Aan de slag!" if bool(content.get("tutorial", false)) else "Klaar") if last else "Volgende  ›"


## Bladert; voorbij de laatste pagina sluit het paneel.
func flip(d: int) -> void:
	var p := page + d
	if p >= _pages.size():
		close()
		return
	if p < 0:
		return
	show_page(p)


func _cycle_tab() -> void:
	if _tabs.size() <= 1 or tab == "_":
		return
	show_tab(_tabs[(_tabs.find(tab) + 1) % _tabs.size()])


func close() -> void:
	if _closing:
		return
	_closing = true
	if bool(style.get("pause", true)) and is_inside_tree():
		get_tree().paused = _was_paused
	closed.emit()
	var layer := get_parent()
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func():
		if layer is CanvasLayer:
			layer.queue_free()
		else:
			queue_free())


func _input(ev: InputEvent) -> void:
	if _closing or not (ev is InputEventKey and ev.pressed):
		return
	var k := (ev as InputEventKey).keycode
	var handled := true
	match k:
		KEY_ESCAPE, KEY_F1:
			close()
		KEY_RIGHT, KEY_PAGEDOWN:
			flip(1)
		KEY_LEFT, KEY_PAGEUP:
			flip(-1)
		KEY_TAB:
			_cycle_tab()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			# een knop van het paneel met focus handelt dit zelf af; anders = Volgende
			var fo := get_viewport().gui_get_focus_owner()
			if fo and is_ancestor_of(fo):
				handled = false
			else:
				flip(1)
		_:
			# andere toetsen niet doorlaten naar het spel; Ctrl+H (HubNav) wel
			handled = not (ev as InputEventKey).ctrl_pressed
	if handled:
		get_viewport().set_input_as_handled()


func _label(t: String, size: int, col: Color, f: Font) -> Label:
	var l := Label.new()
	l.text = t
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _box(col: Color, lift := 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(14)
	s.border_color = col.darkened(0.35)
	s.border_width_bottom = int(4 - lift)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 6 + lift
	s.content_margin_bottom = 6
	return s


func _style_button(b: Button, col: Color, fg: Color) -> void:
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.35))
	b.add_theme_stylebox_override("normal", _box(col))
	b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), 2))
	b.add_theme_stylebox_override("pressed", _box(col, 0))
	b.add_theme_stylebox_override("hover_pressed", _box(col.lightened(0.1), 0))
	b.add_theme_stylebox_override("disabled", _box(col.darkened(0.3)))
	var f := _box(col.lightened(0.1), 2)
	f.border_color = Color("#4CC9F0")
	f.set_border_width_all(3)
	b.add_theme_stylebox_override("focus", f)


func _button(t: String, col: Color, fg: Color, size: int) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_ALL
	var f := _f("font_bold")
	if f:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", size)
	_style_button(b, col, fg)
	return b


## Schema-vlak: een Texture2D (passend geschaald) of een Callable(ci: Control, size: Vector2) die tekent.
class _Schema extends Control:
	var what = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		if what is Texture2D:
			var tex: Texture2D = what
			var ts := tex.get_size()
			var k := minf(size.x / ts.x, size.y / ts.y)
			var ds := ts * k
			draw_texture_rect(tex, Rect2((size - ds) / 2.0, ds), false)
		elif what is Callable and (what as Callable).is_valid():
			(what as Callable).call(self, size)
