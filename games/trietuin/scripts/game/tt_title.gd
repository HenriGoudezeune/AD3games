extends Control
## Titelscherm (GDD §4.2): een boompje groeit in 3 s op; zijn vruchten spellen T R I E T U I N. Bijen zoemen
## rond. Spelen · Vrije tuin (slot) · Instellingen · ← Alle games. Esc = terug naar de speelhal.

const WORD := "TRIETUIN"
const KNOT := Vector2(820, 600)
const GROUND := Vector2(820, 980)

var t := 0.0
var _grow := 0.0
var _fruit_g: Array = []
var _tips: Array = []
var _tree: Node2D
var _bees: Array = []
var _menu: VBoxContainer
var _settings: Control
var _sub_a := 0.0
var _fx: Node2D
var _backdrop: TtBackdrop


func _ready() -> void:
	theme = TtUi.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	TtSettings.apply_all()
	_backdrop = TtBackdrop.new(0, true, -10)
	add_child(_backdrop)
	_tree = Node2D.new()
	_tree.draw.connect(_draw_tree)
	add_child(_tree)
	_fx = Node2D.new()
	add_child(_fx)
	var n := WORD.length()
	for i in n:
		_fruit_g.append(0.0)
		var u := (i - (n - 1) / 2.0) / ((n - 1) / 2.0)
		_tips.append(KNOT + Vector2(u * 560.0, -330.0 - (1.0 - u * u) * 70.0 + (26.0 if i % 2 == 1 else 0.0)))
	var tw := create_tween()
	tw.tween_property(self, "_grow", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	TtSnd.play("grow_wood", -4.0)
	for i in n:
		var ii := i
		tw.tween_callback(func():
			TtSnd.play("fruit_plop", -6.0, 0.8 + ii * 0.06, false)
			TtFx.ripen(_fx, _tips[ii] + Vector2(0, 50), 0))
		tw.tween_method(func(v: float): _fruit_g[ii] = v, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_sub_a", 1.0, 0.4)
	for k in 3:
		var b := TtCritter.new(TtCritter.K.BEE, "", "ACGT_", TtPal.season(0))
		b.label_on = false
		b.scale = Vector2(0.8, 0.8)
		add_child(b)
		_bees.append(b)
	_build_menu()
	TtSnd.season_music(-1)
	if TtSession.has("map"):
		Transition.goto.call_deferred(TtSession.SCENE_MAP)
	elif TtSession.has("level"):
		TtSession.level_id = TtSession.arg("level")
		Transition.goto.call_deferred(TtSession.SCENE_GARDEN)
	elif TtSession.has("guide"):
		get_tree().create_timer(float(TtSession.arg("guide", "2"))).timeout.connect(open_theory)


func _build_menu() -> void:
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_menu.position = Vector2(1430, 470)
	add_child(_menu)
	var play := TtUi.button("Spelen", TtUi.Kind.PRIMARY, 36, 400)
	play.pressed.connect(func(): Transition.goto(TtSession.SCENE_MAP))
	_menu.add_child(play)
	var unlocked := _endless_unlocked()
	var endless := TtUi.button("Vrije tuin" if unlocked else "Vrije tuin  (na 1-4)", TtUi.Kind.SAP if unlocked else TtUi.Kind.GHOST, 30, 400)
	endless.pressed.connect(func():
		if _endless_unlocked():
			TtSession.level_id = "endless"
			Transition.goto(TtSession.SCENE_GARDEN)
		else:
			TtSnd.play("clonk", -6.0)
			_shake(endless))
	_menu.add_child(endless)
	var st := TtUi.button("Instellingen", TtUi.Kind.SECONDARY, 30, 400)
	st.pressed.connect(_open_settings)
	_menu.add_child(st)
	var th := TtUi.button("Theorie", TtUi.Kind.SECONDARY, 30, 400)
	th.tooltip_text = "Tries, Patricia, ternary, suffixbomen en Ukkonen volgens de lesnotas (F1)"
	th.pressed.connect(open_theory)
	_menu.add_child(th)
	var q := TtUi.button("← Alle games", TtUi.Kind.GHOST, 26, 400)
	q.pressed.connect(func(): Transition.goto(HubRegistry.HUB_SCENE))
	_menu.add_child(q)
	for i in _menu.get_child_count():
		var b: Control = _menu.get_child(i)
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(1.6 + i * 0.08)
		tw.tween_property(b, "modulate:a", 1.0, 0.25)
	play.grab_focus.call_deferred()
	var cr := TtUi.label("lesnotas AD3 §3.1–3.3 · tries, Patricia, ternary & suffixbomen", 20, TtPal.TEXT)
	cr.position = Vector2(24, 1040)
	cr.add_theme_color_override("font_outline_color", TtPal.OUTLINE)
	cr.add_theme_constant_override("outline_size", 6)
	add_child(cr)


func _endless_unlocked() -> bool:
	if TtSession.has("unlock"):
		return true
	return TtLevels.is_unlocked("vrij", TtSave.all_stars(), TtLevels.ids())


func _shake(c: Control) -> void:
	var x := c.position.x
	var tw := c.create_tween()
	for k in 4:
		tw.tween_property(c, "position:x", x + (8 if k % 2 == 0 else -8), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)


func _process(delta: float) -> void:
	t += delta
	TtSession.qa_tick(self, delta)
	for k in _bees.size():
		var b: TtCritter = _bees[k]
		var ph := t * (0.35 + 0.08 * k) + k * 2.1
		var p := KNOT + Vector2(sin(ph) * (520 - k * 60), -220 + sin(ph * 2.0 + k) * 160)
		b.facing = signf(cos(ph)) if absf(cos(ph)) > 0.05 else b.facing
		b.position = b.position.lerp(p, 1.0 - exp(-delta * 4.0)) if t > 0.1 else p
	_tree.queue_redraw()


func _draw_tree() -> void:
	var se := TtPal.season(0)
	var g := _grow
	var top := GROUND.lerp(KNOT + Vector2(0, 20), g)
	TtDraw.root(_tree, GROUND, top, se, t)
	if g < 0.6:
		return
	var a := clampf((g - 0.6) / 0.4, 0.0, 1.0)
	var n := WORD.length()
	var used := []
	for i in n:
		used.append(true)
	_tree.draw_set_transform(KNOT, 0.0, Vector2(lerpf(0.3, 1.0, a), a))
	var tops := TtDraw.knot(_tree, Vector2.ZERO, WORD, used, 44.0, -1, t)
	_tree.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in n:
		var f: float = _fruit_g[i]
		var p0: Vector2 = KNOT + tops[i]
		var p1: Vector2 = _tips[i]
		var pts := TtDraw.branch_curve(p0, p1, Vector2.UP, 0.08 if p1.x < p0.x else -0.08, 22, absf(p1.x - p0.x) > 120)
		var gg := clampf(a * 1.2 - i * 0.02, 0.0, 1.0)
		if gg <= 0.05:
			continue
		var m := maxi(4, int(pts.size() * gg))
		TtDraw.branch(_tree, pts.slice(0, m), 16, 10, se, i * 5 + 1, t, 2)
	for i in n:
		var f2: float = _fruit_g[i]
		if f2 <= 0.01:
			continue
		var tip: Vector2 = _tips[i]
		_tree.draw_set_transform(tip, sin(t * 1.3 + i) * 0.04, Vector2(f2, f2))
		var col: Color = TtPal.LETTER_CYCLE[i % TtPal.LETTER_CYCLE.size()]
		var c := Vector2(0, 58)
		_tree.draw_line(Vector2.ZERO, c - Vector2(0, 40), TtPal.BARK_DARK, 4.0, true)
		TtDraw.leaf(_tree, Vector2(0, 4), -2.3, 26, TtPal.BRAND)
		TtDraw.ellipse(_tree, c + Vector2(6, 9), 44, 42, TtPal.SHADOW_SOFT)
		_tree.draw_circle(c + Vector2(2, 3), 44, col.darkened(0.3), true, -1, true)
		_tree.draw_circle(c, 42, col, true, -1, true)
		TtDraw.ellipse(_tree, c + Vector2(-16, -16), 9, 14, Color(1, 1, 1, 0.45), -0.5)
		TtPal.text_c(_tree, TtPal.UI_BOLD, c + Vector2(0, 2), WORD[i], 60, TtPal.INK)
		_tree.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _sub_a > 0.0:
		var sr := Rect2(KNOT.x - 330, 40, 660, 52)
		_tree.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.85 * _sub_a), 26), sr)
		TtPal.text_c(_tree, TtPal.UI_BOLD, sr.get_center(), "laat een boom vol woorden groeien", 28, Color(TtPal.TEXT, _sub_a))


func _unhandled_input(ev: InputEvent) -> void:
	if _settings != null or (_guide and is_instance_valid(_guide)):
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		Transition.goto(HubRegistry.HUB_SCENE)
	elif ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		open_theory()


var _guide: HubGuide


## Gids op het tabblad Theorie (lesnotas §3.1–3.3). Knop "Theorie" of F1.
func open_theory() -> void:
	if _guide and is_instance_valid(_guide):
		return
	_guide = HubGuide.open(self, TtGuide.content(null, "", "theorie"), TtGuide.style())
	_guide.closed.connect(func(): _guide = null)


func _open_settings() -> void:
	if _settings:
		return
	_settings = TtSettings.new()
	add_child(_settings)
	_settings.closed.connect(func(): _settings = null)
