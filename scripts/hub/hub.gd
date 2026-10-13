extends Control
## Gedeeld startscherm van de AD3-speelhal: één kaart per game (HubRegistry), muis en toetsenbord.

const CARD_SIZE := Vector2(520, 420)
const GAP := 48.0

var _cards: Array = []
var _focus := 0
var _t := 0.0
var _logo: Node2D


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.new())
	_logo = Node2D.new()
	_logo.draw.connect(_draw_logo)
	_logo.position = Vector2(960, 190)
	add_child(_logo)
	var sub := UIKit.label("Algoritmen en Datastructuren 3 · leer de lesnotas door ze te spelen", 26, Pal.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1920, 40)
	sub.position = Vector2(0, 280)
	add_child(sub)
	var games := HubRegistry.available()
	# Eén rij; bij meer games worden de kaarten kleiner geschaald (breedte 1920 − marges).
	var n := games.size()
	var sc: float = minf(1.0, (1920.0 - 120.0 - maxi(0, n - 1) * GAP) / maxf(1.0, n * CARD_SIZE.x))
	var total: float = n * CARD_SIZE.x * sc + maxi(0, n - 1) * GAP
	var x0: float = 960.0 - total / 2.0
	for i in n:
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.scale = Vector2(sc, sc)
		holder.position = Vector2(x0 + i * (CARD_SIZE.x * sc + GAP), 600.0 - CARD_SIZE.y * sc / 2.0)
		add_child(holder)
		var card := _make_card(games[i], i)
		card.modulate.a = 0.0
		holder.add_child(card)
		_cards.append(card)
		var tw := card.create_tween()
		tw.tween_interval(0.15 + i * 0.1)
		tw.tween_property(card, "modulate:a", 1.0, 0.25)
	var q := UIKit.button("Stoppen", Pal.PANEL_LO, Pal.TEXT_DIM, 24, 220)
	q.position = Vector2(960 - 110, 900)
	q.pressed.connect(func(): get_tree().quit())
	add_child(q)
	var foot := UIKit.label("pijltjes + Enter of klik · Esc = stoppen", 20, Pal.TEXT_DIM)
	foot.position = Vector2(24, 1040)
	add_child(foot)
	if not _cards.is_empty():
		_cards[0].grab_focus.call_deferred()
	Sfx.play_track("calm")


func _make_card(g: Dictionary, i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.size = CARD_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.pivot_offset = CARD_SIZE / 2.0
	var col: Color = g.color
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s := Pal.sbn(Pal.PANEL, 28)
		s.border_color = col if st in ["hover", "focus"] else Pal.PANEL_HI
		s.set_border_width_all(5 if st in ["hover", "focus"] else 3)
		s.border_width_bottom = 12
		s.shadow_color = Color(0.02, 0.03, 0.08, 0.45)
		s.shadow_size = 18
		s.shadow_offset = Vector2(0, 10)
		b.add_theme_stylebox_override(st, s)
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size = CARD_SIZE
	art.draw.connect(func(): _draw_card(art, g))
	b.add_child(art)
	var blurb := UIKit.label(g.blurb, 22, Pal.TEXT_DIM)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.position = Vector2(36, 292)
	blurb.size = Vector2(CARD_SIZE.x - 72, 110)
	blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(blurb)
	b.mouse_entered.connect(func(): b.grab_focus())
	b.focus_entered.connect(func():
		_focus = i
		Sfx.ui("hover", -10.0)
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	b.focus_exited.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.15))
	b.pressed.connect(func():
		Sfx.ui("click")
		Transition.goto(g.scene))
	return b


func _draw_card(c: Control, g: Dictionary) -> void:
	var col: Color = g.color
	var badge := Rect2(36, 36, 150, 150)
	c.draw_style_box(Pal.sb(col.darkened(0.35), 30), Rect2(badge.position + Vector2(0, 8), badge.size))
	c.draw_style_box(Pal.sb(col, 30), badge)
	Pal.text_c(c, Pal.UI_BOLD, badge.get_center() + Vector2(0, 4), g.glyph, 110, Pal.INK)
	Pal.text_l(c, Pal.UI_BOLD, Vector2(212, 78), g.title, 48, Pal.TEXT)
	var fs := 23
	while fs > 14 and Pal.UI.get_string_size(g.topic, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > CARD_SIZE.x - 212 - 28:
		fs -= 1
	Pal.text_l(c, Pal.UI, Vector2(212, 126), g.topic, fs, col.lightened(0.15))
	var tag := Rect2(212, 152, 0, 40)
	var tw := Pal.UI_BOLD.get_string_size(g.section, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	tag.size.x = tw + 28
	c.draw_style_box(Pal.sb(Pal.SLOT, 12), tag)
	Pal.text_c(c, Pal.UI_BOLD, tag.get_center(), g.section, 22, Pal.TEXT_DIM)
	c.draw_line(Vector2(36, 236), Vector2(CARD_SIZE.x - 36, 236), Pal.PANEL_HI, 3)
	Pal.text_l(c, Pal.UI_BOLD, Vector2(36, 266), "Spelen  →", 24, col)


func _draw_logo() -> void:
	var word := "AD3 SPEELHAL"
	var size := 92
	var w := Pal.UI_BOLD.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x := -w / 2.0
	for k in word.length():
		var ch := word[k]
		var cw := Pal.UI_BOLD.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var y := sin(_t * 2.0 + k * 0.5) * 6.0
		var c: Color = Pal.BIT_COLORS[k % Pal.BIT_COLORS.size()] if ch != " " else Pal.TEXT
		Pal.text_outline_c(_logo, Pal.UI_BOLD, Vector2(x + cw / 2.0, y), ch, size, c, 10)
		x += cw


func _process(d: float) -> void:
	_t += d
	_logo.queue_redraw()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_tree().quit()
