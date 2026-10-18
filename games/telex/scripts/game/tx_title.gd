extends Control
## Titelscherm (GDD §4.2): een telexmachine typt het logo TELEX letter per letter op een lint (tak-tak-tak, bel).
## Daaronder "Station Zoeklicht". Diensten · Nachtdienst (slot: 4-1 ≥ 1 ★) · Instellingen · Theorie (F1) · ← Alle games.
## Esc / "← Alle games" gaan naar de speelhal (HubRegistry.HUB_SCENE). Onderaan loopt een attract-lint waarop de
## Springer zelf springt (Boyer-Moore-Horspool, gedimd).

const ATTRACT := "de_ekster_vliegt_om_middernacht_over_de_haven_en_zoekt_de_vuurtoren_bij_de_duinen_"
const AZ := "vuurtoren"

var t := 0.0
var typed := 0.0
var sub_a := 0.0
var menu: VBoxContainer
var sub: Control = null
var _scroll := 0.0
var _jump_i := 8
var _jump_t := 0.0
var _jump_from := 8.0
var _jump_u := 1.0
var _bell_done := false


func _ready() -> void:
	theme = TxPal.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)  # volgt de viewport (1920×1080); geen size-override (Godot-waarschuwing)
	TxSession.apply_all()
	TxUi.overlay(self, 60)
	var tw := create_tween()
	tw.tween_interval(0.4)
	for i in 5:
		tw.tween_callback(func():
			TxSnd.tak(-2.0, 0.9 + 0.05 * randf())
			TxFx.shake(1.5, 0.06))
		tw.tween_property(self, "typed", float(i + 1), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.08)
	tw.tween_callback(func():
		TxSnd.play("bell", -2.0, 1.0, false)
		TxSnd.play("carriage", -6.0))
	tw.tween_property(self, "sub_a", 1.0, 0.5)
	_build_menu()
	TxSnd.music("title")
	TxSession.lesson_boot()
	if TxSession.has("lesson") and TxSession.take("lesson") and not TxSession.lesson_queue.is_empty():
		if TxSession.has("level"):
			TxSession.level_id = TxSession.arg("level")
		Transition.goto.call_deferred(TxSession.SCENE_CONSOLE)
	elif TxSession.take("level"):
		TxSession.level_id = TxSession.arg("level")
		Transition.goto.call_deferred(TxSession.SCENE_CONSOLE)
	elif TxSession.take("map"):
		Transition.goto.call_deferred(TxSession.SCENE_MAP)
	elif TxSession.take("screen"):
		match TxSession.arg("screen"):
			"settings":
				_open(TxSettings.new())
			"notes":
				_open(TxCheatSheet.new())
			"theory":
				open_theory.call_deferred()


func _build_menu() -> void:
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 16)
	menu.position = Vector2(760, 610)
	add_child(menu)
	var play := TxUi.button("Diensten", "brass", 32, 400)
	play.pressed.connect(func(): Transition.goto(TxSession.SCENE_MAP))
	menu.add_child(play)
	var open := TxSession.unlocked("N")
	var night := TxUi.button("Nachtdienst" if open else "Nachtdienst  (na 4-1)", "key", 32, 400)
	night.pressed.connect(func():
		if TxSession.unlocked("N"):
			TxSession.level_id = "N"
			Transition.goto(TxSession.SCENE_CONSOLE)
		else:
			TxSnd.play("bump", -6.0)
			TxUi.wobble(night))
	menu.add_child(night)
	var st := TxUi.button("Instellingen", "key", 32, 400)
	st.pressed.connect(func(): _open(TxSettings.new()))
	menu.add_child(st)
	var th := TxUi.button("Theorie", "key", 32, 400)
	th.tooltip_text = "Theorie uit de lesnotas §3.4–3.5 (F1)"
	th.pressed.connect(open_theory)
	menu.add_child(th)
	var back := TxUi.button("← Alle games", "flat", 26, 400)
	back.pressed.connect(_to_hub)
	menu.add_child(back)
	for i in menu.get_child_count():
		var c := menu.get_child(i) as Control
		c.modulate.a = 0.0
		var tw := c.create_tween()
		tw.tween_interval(1.5 + i * 0.08)
		tw.tween_property(c, "modulate:a", 1.0, 0.25)


func _open(c: Control) -> void:
	if sub != null:
		sub.queue_free()
	sub = c
	add_child(c)
	c.tree_exited.connect(func(): sub = null)


func _to_hub() -> void:
	Transition.goto(HubRegistry.HUB_SCENE)


var _guide: HubGuide = null


## Gids op het tabblad Theorie (ook Doel/Handelingen algemeen). Knop "Theorie" of F1.
func open_theory() -> void:
	if _guide != null and is_instance_valid(_guide):
		return
	_guide = TxGuide.open(self, TxGuide.content(null, "", "theorie"))
	_guide.closed.connect(func(): _guide = null)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_F1 and sub == null:
			open_theory()
			get_viewport().set_input_as_handled()
			return
		if sub != null:
			if sub.has_method("key"):
				sub.key(e)
			get_viewport().set_input_as_handled()
			return
		if e.keycode == KEY_ESCAPE:
			_to_hub()
			get_viewport().set_input_as_handled()
		elif e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
			Transition.goto(TxSession.SCENE_MAP)
			get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	t += dt
	_scroll += dt * 1.4
	# attract: de Springer springt zelf over het lint (BMH met V_H)
	_jump_t += dt
	if _jump_t > 0.9:
		_jump_t = 0.0
		var tt := ATTRACT.repeat(3)
		var m := AZ.length()
		var vh := TxReference.vul_vh(AZ)
		var s := TxReference.vh_of(vh, tt[_jump_i % tt.length()], m)
		_jump_from = float(_jump_i)
		_jump_i += s
		_jump_u = 0.0
		if _jump_i > int(_scroll) + 40:
			_jump_i = int(_scroll) + 8
			_jump_from = float(_jump_i)
		TxSnd.play("jump", -26.0)
	_jump_u = minf(1.0, _jump_u + dt * 3.0)
	if _jump_i < int(_scroll) + 2:
		_jump_i = int(_scroll) + 10
		_jump_from = float(_jump_i)
	queue_redraw()


func _draw() -> void:
	TxUi.draw_bunker(self, 0.15)
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.0))
	# kopregel
	TxPal.lamp(self, Vector2(176, 122), 10, TxPal.BRASS, 0.5 + 0.5 * sin(t * 2.0))
	TxPal.text_l(self, TxPal.TAPE, Vector2(202, 122), "BELGIË · 1961 · LUISTERPOST IN DE DUINEN", 22, TxPal.TEXT_DIM)
	TxDraw.ekster_seal(self, Vector2(1760, 140), 52)
	# logo
	TxDraw.logo(self, Vector2(960, 330), 1.0, typed)
	if sub_a > 0.0:
		draw_set_transform(Vector2.ZERO)
		TxPal.brass_plate(self, Vector2(960, 520), "STATION  ZOEKLICHT", 30, TxPal.STENCIL, TxPanel.sheen(t))
		TxPal.text_c(self, TxPal.UI, Vector2(960, 572), "een analoge operator-thriller over exact en benaderend string matching", 20, Color(TxPal.TEXT_DIM, sub_a))
	# attract-lint onderaan
	var cell := 40.0
	var tt := ATTRACT.repeat(3)
	var first := int(_scroll)
	var x0 := -(_scroll - first) * cell
	TxDraw.tape(self, x0, 960, tt, first, 50, cell, {"size": 32})
	var m := AZ.length()
	var u := _jump_u
	var sx := lerpf(_jump_from, float(_jump_i), u) - m + 1
	var lift := -sin(u * PI) * 40.0
	TxDraw.stencil(self, x0 + (sx - first) * cell, 860 + lift, AZ, cell, {}, -1, false, 30)
	draw_rect(Rect2(0, 850, 1920, 230), Color(TxPal.NIGHT, 0.45))
	var best := TxSave.highscores()
	if not best.is_empty():
		TxPal.text_r(self, TxPal.TAPE, Vector2(1880, 820), "Nachtdienst-record: %s %d" % [str(best[0].name), int(best[0].score)], 18, TxPal.BRASS)
	var stars := TxSession.stars()
	var tot := 0
	for k in stars:
		tot += int(stars[k])
	TxPal.text_l(self, TxPal.UI, Vector2(40, 820), "★ %d / %d" % [tot, 3 * (TxLevels.ids().size() - 1)], 20, TxPal.BRASS)
