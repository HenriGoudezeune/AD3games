extends Control
## Titelscherm (GDD §7): logo-letters vallen als pakjes en squashen bij landen; band met pakjes op de
## achtergrond; Spelen · Eindeloos (slot) · Instellingen | Theorie · Alle games.

const WORD := "HASH&DASH"
var _letters: Array = []   # Node2D per letter
var _belt_items: Array = []
var _belt: Node2D
var _menu: VBoxContainer
var _t := 0.0
var _settings: Control


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.new())
	_belt = Node2D.new()
	_belt.draw.connect(_draw_belt)
	add_child(_belt)
	for i in 7:
		var pv := ParcelView.new()
		pv.setup(-1, randi() % 32, 5)
		pv.apply_hint(1, 2)
		pv.set_size(Vector2(176, 104), 40)
		pv.position = Vector2(i * 300.0, 930)
		pv.modulate = Color(0.8, 0.8, 0.85, 1.0)
		add_child(pv)
		_belt_items.append(pv)
	_build_logo()
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_menu.position = Vector2(960 - 190, 520)
	add_child(_menu)
	var play := UIKit.button("Spelen", Pal.OK, Pal.INK, 36, 380)
	play.pressed.connect(func(): Transition.goto(Game.SCENE_MAP))
	_menu.add_child(play)
	var endless := UIKit.button("Eindeloos" if Game.is_unlocked(0) else "Eindeloos  (dag 5)", Pal.PANEL_HI, Pal.TEXT, 30, 380)
	endless.pressed.connect(func():
		if Game.is_unlocked(0):
			Game.goto_day(0)
		else:
			Sfx.ui("error")
			_shake_ctrl(endless))
	_menu.add_child(endless)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_menu.add_child(row)
	var st := UIKit.button("Instellingen", Pal.PANEL_HI, Pal.TEXT, 28, 182)
	st.pressed.connect(_open_settings)
	row.add_child(st)
	var th := UIKit.button("Theorie", Pal.PANEL_HI, Pal.TEXT, 28, 182)
	th.pressed.connect(_open_theory)
	row.add_child(th)
	var q := UIKit.button("← Alle games", Pal.PANEL_LO, Pal.TEXT_DIM, 26, 380)
	q.pressed.connect(func(): Transition.goto(HubRegistry.HUB_SCENE))
	_menu.add_child(q)
	for i in _menu.get_child_count():
		var b: Control = _menu.get_child(i)
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(1.3 + i * 0.07)
		tw.tween_property(b, "modulate:a", 1.0, 0.2)
	play.grab_focus.call_deferred()
	Sfx.play_track("calm")
	var cr := UIKit.label("lesnotas AD3 §2.1.1 · extendible hashing", 20, Pal.TEXT_DIM)
	cr.position = Vector2(24, 1040)
	add_child(cr)
	if Game.cmd.has("autostart"):
		await get_tree().create_timer(2.5).timeout
		Transition.goto(Game.SCENE_MAP)


func _shake_ctrl(c: Control) -> void:
	var x := c.position.x
	var tw := c.create_tween()
	for k in 4:
		tw.tween_property(c, "position:x", x + (8 if k % 2 == 0 else -8), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)


func _build_logo() -> void:
	var size := Vector2(150, 150)
	var gap := 14.0
	var total := WORD.length() * size.x + (WORD.length() - 1) * gap
	var x0 := 960 - total / 2.0 + size.x / 2.0
	for i in WORD.length():
		var ch := WORD[i]
		var n := Node2D.new()
		var amp := ch == "&"
		n.draw.connect(func(): _draw_letter(n, ch, size, amp))
		n.position = Vector2(x0 + i * (size.x + gap), -200)
		add_child(n)
		_letters.append(n)
		var y := 300.0 + (14.0 if i % 2 == 1 else 0.0)
		var tw := n.create_tween()
		tw.tween_interval(0.25 + i * 0.09)
		tw.tween_property(n, "position:y", y, 0.32).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			n.scale = Vector2(1.25, 0.75)
			Sfx.play("drop_box", -4.0, 0.9 + i * 0.03)
			Juice.burst(self, n.position + Vector2(0, size.y / 2.0), "puff", 5, 0.4, 40, 90, Color(Pal.KRAFT, 0.5), -20, 0.25, 0.5, false, Vector2.UP, 80))
		tw.tween_property(n, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw_letter(n: Node2D, ch: String, sz: Vector2, amp: bool) -> void:
	var r := Rect2(-sz / 2.0, sz)
	n.draw_style_box(Pal.sb(Pal.SHADOW, 20, 14, Vector2(0, 10)), r)
	var box := Pal.sbn(Pal.WARN if amp else Pal.KRAFT, 20)
	box.border_color = Pal.WARN.darkened(0.3) if amp else Pal.KRAFT_DARK
	box.border_width_bottom = 12
	n.draw_style_box(box, r)
	if not amp:
		n.draw_rect(Rect2(-sz.x * 0.07, r.position.y, sz.x * 0.14, sz.y * 0.9), Color(Pal.TAPE, 0.55))
	var lr := Rect2(-sz.x * 0.36, -sz.y * 0.36, sz.x * 0.72, sz.y * 0.66)
	n.draw_style_box(Pal.sb(Pal.LABEL, 16), lr)
	Pal.text_c(n, Pal.UI_BOLD, lr.get_center() + Vector2(0, 2), ch, 92, Pal.INK)


func _process(d: float) -> void:
	_t += d
	for i in _letters.size():
		var n: Node2D = _letters[i]
		if n.scale == Vector2.ONE and _t > 2.0:
			n.rotation = sin(_t * 1.6 + i * 0.7) * 0.03
	for pv in _belt_items:
		pv.position.x -= d * 120.0
		if pv.position.x < -120:
			pv.position.x += 7 * 300.0
			pv.setup(-1, randi() % 32, 5)
			pv.apply_hint(1, 2)
	_belt.queue_redraw()


func _draw_belt() -> void:
	var r := Rect2(-20, 860, 1960, 140)
	_belt.draw_style_box(Pal.sb(Pal.PANEL_LO, 0), r)
	_belt.draw_style_box(Pal.sb(Pal.SLOT, 0), r.grow(-14))
	var off := fposmod(_t * 120.0, 44.0)
	var x := 1960.0 - off
	while x > -20:
		_belt.draw_style_box(Pal.sb(Color("#28314D"), 7), Rect2(x, r.position.y + 22, 14, r.size.y - 44))
		x -= 44.0
	for y in [r.position.y + 7, r.end.y - 7]:
		_belt.draw_line(Vector2(0, y), Vector2(1920, y), Color(Pal.WARN, 0.5), 4)


func _unhandled_input(ev: InputEvent) -> void:
	if _settings == null and ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		Transition.goto(HubRegistry.HUB_SCENE)
	elif ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		_open_theory()


var _guide: HubGuide


## Gids met de theorie uit de notas (ook Doel/Handelingen algemeen). F1 of knop "Theorie".
func _open_theory() -> void:
	if _guide and is_instance_valid(_guide):
		return
	Sfx.ui("open")
	_guide = HubGuide.open(self, HDGuide.content(null, "theorie"), HDGuide.style())


func _open_settings() -> void:
	if _settings:
		return
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.tree_exited.connect(func(): _settings = null)
