extends Control
## Titelscherm (GDD §4.2): een ganzenveer schrijft "Kortschrift" op een perkamentrol; daarna schuiven de letters samen
## tot een klein lakzegel (het kortschrift) en ontrollen weer. Op de achtergrond (gedimd) bindt de kopiist in een lus
## een Huffman-boom (attract, gespeeld met het orakel). Knoppen: Het kloosterjaar · Nachtwake (slot) · Instellingen ·
## ← Alle games. Esc = terug naar de speelhal.

const WORD := "Kortschrift"
const ROLL := Rect2(560, 60, 800, 190)

var t := 0.0
var _write := 0.0
var _squeeze := 0.0
var _sub_a := 0.0
var _n: Node2D
var _fx: Node2D
var _menu: VBoxContainer
var _settings: Control
var _attract: ScView
var _attract_tool: ScBindery
var _attract_t := 0.0
var _attract_seed := 3
var _attract_clip: Control


func _ready() -> void:
	ScSession.apply_all()
	theme = ScUi.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load(ScPal.ASSETS + "art/bg/bg_room.jpg")
	bg.size = Vector2(1920, 1080)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(ScUi.shafts_overlay(Vector2(0.5, 0.06), 0.16))
	var frame := Node2D.new()
	frame.draw.connect(func():
		ScDraw.leather(frame, Rect2(50, 670, 800, 380), 18)
		ScDraw.parchment(frame, Rect2(66, 686, 768, 348), 3, ScPal.VELLUM_AGED, false, 0.8))
	ScDraw.prepare(frame)
	add_child(frame)
	_attract_clip = Control.new()
	_attract_clip.position = Vector2(70, 690)
	_attract_clip.size = Vector2(760, 340)
	_attract_clip.clip_contents = true
	_attract_clip.modulate = Color(1, 1, 1, 0.9)
	_attract_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_attract_clip)
	_new_attract()
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	_fx = Node2D.new()
	add_child(_fx)
	ScFx.ambient_dust(_fx, Rect2(0, 0, 1920, 1080), 0.7)
	add_child(ScUi.candle_overlay(Vector2(960, 140), 0.25, 1500.0))
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func(): ScSnd.play("quill_letter", -4.0))
	tw.tween_property(self, "_write", 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.3)
	tw.tween_callback(func(): ScSnd.play("wax_seal", -6.0))
	tw.tween_property(self, "_squeeze", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): ScFx.wax_splat(_fx, ROLL.get_center() + Vector2(0, 10)))
	tw.tween_interval(0.35)
	tw.tween_callback(func(): ScSnd.play("unroll", -6.0))
	tw.tween_property(self, "_squeeze", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_sub_a", 1.0, 0.4)
	_build_menu()
	ScSnd.music("title")
	ScSession.lesson_boot()
	if ScSession.has("map"):
		ScSession.consume("map")
		Transition.goto.call_deferred(ScSession.SCENE_MAP)
	elif ScSession.has("level"):
		ScSession.level_id = ScSession.consume("level")
		ScSession.wake = false
		Transition.goto.call_deferred(ScSession.SCENE_BENCH)
	elif ScSession.lessons_on() and ScSession.has("lesson"):
		ScSession.wake = false
		Transition.goto.call_deferred(ScSession.SCENE_BENCH)
	elif ScSession.has("wake"):
		ScSession.consume("wake")
		ScSession.wake = true
		Transition.goto.call_deferred(ScSession.SCENE_BENCH)
	elif ScSession.has("guide"):
		get_tree().create_timer(2.0).timeout.connect(open_theory)


func _build_menu() -> void:
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_menu.position = Vector2(1360, 430)
	add_child(_menu)
	var play := ScUi.button("Het kloosterjaar", ScUi.Kind.PRIMARY, 34, 420)
	play.pressed.connect(func(): Transition.goto(ScSession.SCENE_MAP))
	_menu.add_child(play)
	var unlocked := ScSession.unlocked("nachtwake")
	var wake := ScUi.button("Nachtwake" if unlocked else "Nachtwake  (na 1-2)", ScUi.Kind.SECONDARY if unlocked else ScUi.Kind.GHOST, 30, 420)
	wake.pressed.connect(func():
		if ScSession.unlocked("nachtwake"):
			ScSession.wake = true
			Transition.goto(ScSession.SCENE_BENCH)
		else:
			ScSnd.play("clamp", -6.0)
			_shake(wake))
	_menu.add_child(wake)
	var th := ScUi.button("Theorie  (F1)", ScUi.Kind.SECONDARY, 30, 420)
	th.tooltip_text = "Uitleg & theorie: compressie volgens de lesnotas (hoofdstuk 4)"
	th.pressed.connect(open_theory)
	_menu.add_child(th)
	var st := ScUi.button("Instellingen", ScUi.Kind.SECONDARY, 30, 420)
	st.pressed.connect(_open_settings)
	_menu.add_child(st)
	var q := ScUi.button("← Alle games", ScUi.Kind.GHOST, 26, 420)
	q.pressed.connect(func(): Transition.goto(HubRegistry.HUB_SCENE))
	_menu.add_child(q)
	for i in _menu.get_child_count():
		var b: Control = _menu.get_child(i)
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(1.4 + i * 0.08)
		tw.tween_property(b, "modulate:a", 1.0, 0.25)
	play.grab_focus.call_deferred()
	var cr := ScUi.label("lesnotas AD3 hoofdstuk 4 · compressie: Huffman, adaptief, aritmetisch, LZ77, LZW, Burrows-Wheeler", 20, ScPal.TEXT)
	cr.position = Vector2(24, 1040)
	cr.add_theme_color_override("font_outline_color", ScPal.OUTLINE)
	cr.add_theme_constant_override("outline_size", 6)
	add_child(cr)


func _shake(c: Control) -> void:
	var x := c.position.x
	var tw := c.create_tween()
	for k in 4:
		tw.tween_property(c, "position:x", x + (8 if k % 2 == 0 else -8), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)


func _open_settings() -> void:
	if _settings:
		return
	_settings = ScSettings.new()
	add_child(_settings)
	_settings.closed.connect(func(): _settings = null)


func _unhandled_input(ev: InputEvent) -> void:
	if _settings == null and ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_ESCAPE:
		Transition.goto(HubRegistry.HUB_SCENE)
	elif _settings == null and ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		open_theory()


var _guide: HubGuide


## Gids op het tabblad Theorie (ook Doel en Handelingen voor alle werktuigen).
func open_theory() -> void:
	if _guide and is_instance_valid(_guide):
		return
	_guide = HubGuide.open(self, ScGuide.content(null, "", false, "theorie"), ScGuide.style())
	_guide.closed.connect(func(): _guide = null)


# ------------------------------------------------------------------ attract: de kopiist bindt een boom

func _new_attract() -> void:
	if _attract:
		_attract.queue_free()
	var g := ScTextGen.new(_attract_seed).wake_round(2 + _attract_seed % 4)
	_attract_seed += 1
	var ws: Array = []
	for q in (g.letters as Array).size():
		ws.append([str(g.letters[q]), int(g.weights[q])])
	_attract_tool = ScLevels.make_tool({"tool": "bindery", "mode": "row", "weights": ws}) as ScBindery
	_attract_tool.begin()
	var v: ScView = (load(ScSession.VIEW_SCRIPTS.bindery) as GDScript).new()
	v.readonly = true
	v.fx_root = null
	ScDraw.prepare(v)
	v.setup(_attract_tool, _attract_tool.cursor())
	v.scale = Vector2(0.56, 0.56)
	v.position = Vector2(-10, -128)
	_attract_tool.changed.connect(func(f: Dictionary): v.play(f))
	_attract_tool.phase_changed.connect(func(_p: int, c: Dictionary): v.commit(c))
	_attract_clip.add_child(v)
	_attract = v
	_attract_t = 0.0


func _process(delta: float) -> void:
	t += delta
	ScSession.qa_tick(delta)
	_attract_t += delta
	if _attract_tool and _attract_t > 1.3:
		_attract_t = 0.0
		if _attract_tool.is_done():
			_new_attract()
		else:
			ScSnd.muted = true
			_attract_tool.apply(_attract_tool.correct_move())
			ScSnd.muted = false
	_n.queue_redraw()


func _paint() -> void:
	var c := _n
	ScDraw.scroll(c, ROLL)
	var cx := ROLL.get_center().x
	var y := ROLL.position.y + 92
	var full_w := ScPal.text_w(ScPal.TITLE, WORD, 110)
	var shown := int(ceil(_write * WORD.length()))
	var x := cx - full_w / 2.0
	var sq := _squeeze
	for i in WORD.length():
		var ch := WORD[i]
		var w := ScPal.text_w(ScPal.TITLE, ch, 110)
		if i < shown:
			var lx := x + w / 2.0
			var tx := lerpf(lx, cx, sq)
			var a := 1.0 - sq * 0.9
			c.draw_set_transform(Vector2(tx, y), 0.0, Vector2(1.0 - sq * 0.85, 1.0))
			ScPal.text_c(c, ScPal.TITLE, Vector2(3, 5), ch, 110, Color(ScPal.INK, 0.22 * a))
			ScPal.text_c(c, ScPal.TITLE, Vector2.ZERO, ch, 110, Color(ScPal.INK, a) if i > 0 else Color(ScPal.RUBRIC, a))
			c.draw_set_transform(Vector2.ZERO)
		x += w
	if sq > 0.6:
		var a2 := (sq - 0.6) / 0.4
		ScDraw.seal(c, Vector2(cx, y), 46 * a2, "K", ScPal.INITIAL, int(52 * a2), ScPal.WAX)
	if _write < 1.0 and _write > 0.0:
		var qx := cx - full_w / 2.0 + full_w * _write
		ScDraw.quill(c, Vector2(qx + 10, y + 30), 1.1, -1.0, t, 1.0)
	ScPal.text_c(c, ScPal.TITLE_LIGHT, Vector2(cx, ROLL.end.y + 30), "Het scriptorium van Zuinigem", 36, Color(ScPal.GILT_LIGHT, _sub_a))
	ScDraw.candle(c, Vector2(1690, 905), 1.0, t + 2.0, true, 0.6)
	ScDraw.zeno(c, Vector2(1000, 1010), 0.95, t, 0.0, -1.0)
	ScDraw.dove(c, Vector2(1520, 1000), 0.9, t, 0, -1.0)
	ScDraw.inkpot(c, Vector2(1820, 1010), 1.0, 1.0, false, t)
