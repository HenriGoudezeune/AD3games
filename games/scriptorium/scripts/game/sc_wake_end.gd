class_name ScWakeEnd
extends Control
## Einde van de Nachtwake (GDD §5.10, §6.6): de dageraad. Score, rondes, paren; bij een topscore drie letters
## invullen; de lokale top-10 (ScSave). Opnieuw · Titel.

var rep: Dictionary
var t := 0.0
var _n: Node2D
var _name: LineEdit
var _saved := false
var _rank := 0
var _box: VBoxContainer


func setup(r: Dictionary) -> void:
	rep = r


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.0)
	dim.size = size
	add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.7, 0.8)
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 14)
	_box.position = Vector2(1120, 640)
	add_child(_box)
	var score := int(rep.get("points", 0))
	if score > 0 and ScSave.is_highscore(score):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.add_child(ScUi.label("Je naam:", 26, ScPal.TEXT))
		_name = LineEdit.new()
		_name.max_length = 3
		_name.text = str(ScSave.setting("wake_name", "NOV"))
		_name.custom_minimum_size = Vector2(120, 50)
		_name.add_theme_font_override("font", ScPal.MONO_B)
		_name.add_theme_font_size_override("font_size", 30)
		_name.text_submitted.connect(func(_s: String): _save())
		h.add_child(_name)
		var ok := ScUi.button("Bewaar", ScUi.Kind.WAX, 24, 160)
		ok.pressed.connect(_save)
		h.add_child(ok)
		_box.add_child(h)
		_name.grab_focus.call_deferred()
	var again := ScUi.button("Nog een nacht", ScUi.Kind.PRIMARY, 28, 340)
	again.pressed.connect(func():
		_save()
		ScSession.wake = true
		Transition.goto(ScSession.SCENE_BENCH))
	_box.add_child(again)
	var back := ScUi.button("Naar de titel", ScUi.Kind.GHOST, 26, 340)
	back.pressed.connect(func():
		_save()
		ScSession.wake = false
		Transition.goto(ScSession.SCENE_TITLE))
	_box.add_child(back)
	ScSnd.play("bell", -6.0)
	ScSnd.jingle(2)
	if ScSession.has("bot"):
		get_tree().create_timer(2.0).timeout.connect(func():
			print("SC_WAKE score=%d rounds=%d" % [int(rep.get("points", 0)), int(rep.get("rounds", 0))])
			get_tree().quit())


func _save() -> void:
	if _saved:
		return
	_saved = true
	var score := int(rep.get("points", 0))
	if score <= 0:
		return
	var nm := "NOV"
	if _name:
		nm = _name.text.strip_edges().to_upper()
		if nm == "":
			nm = "NOV"
		ScSave.set_setting("wake_name", nm)
	_rank = ScSave.add_highscore(score, nm, Time.get_date_string_from_system())
	ScSnd.play("wax_seal", -4.0)


func _process(delta: float) -> void:
	t += delta
	_n.queue_redraw()


func _paint() -> void:
	var c := _n
	var r := Rect2(260, 140, 1400, 800)
	ScDraw.parchment(c, r, 61, ScPal.VELLUM, true, 0.7)
	ScPal.text_c(c, ScPal.TITLE, Vector2(r.get_center().x, r.position.y + 70), "De dageraad", 72, ScPal.RUBRIC)
	ScPal.text_c(c, ScPal.UI_MED, Vector2(r.get_center().x, r.position.y + 130), "De kaarsen zijn op. De Nachtwake is voorbij.", 26,
		ScPal.INK_SOFT)
	var x := r.position.x + 90
	var y := r.position.y + 230
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(x, y), "Punten", 30, ScPal.INK)
	ScPal.text_l(c, ScPal.MONO_B, Vector2(x + 260, y), str(int(rep.get("points", 0))), 54, ScPal.INK)
	y += 80
	ScPal.text_l(c, ScPal.UI_BOLD, Vector2(x, y), "Rondes", 30, ScPal.INK)
	ScPal.text_l(c, ScPal.MONO_B, Vector2(x + 260, y), str(int(rep.get("rounds", 0))), 40, ScPal.INK)
	y += 60
	for b in rep.get("breakdown", []):
		ScPal.text_l(c, ScPal.UI, Vector2(x, y), str(b.label), 24, ScPal.INK_SOFT)
		ScPal.text_r(c, ScPal.MONO_B, Vector2(x + 420, y), "%+d" % int(b.amount), 24, ScPal.INK)
		y += 36
	ScDraw.candle(c, Vector2(x + 120, r.end.y - 40), 1.0, t, false, 0.1)
	# top-10
	var tx := r.position.x + 820
	var ty := r.position.y + 210
	ScPal.text_l(c, ScPal.TITLE, Vector2(tx, ty), "Getijdenlijst", 38, ScPal.RUBRIC)
	ty += 50
	var hs := ScSave.highscores()
	for i in mini(hs.size(), 10):
		var h: Dictionary = hs[i]
		var col := ScPal.GOLD_DARK if i + 1 == _rank else ScPal.INK
		ScPal.text_l(c, ScPal.MONO_B, Vector2(tx, ty), "%2d  %-3s  %6d" % [i + 1, str(h.name), int(h.score)], 24, col)
		ScPal.text_l(c, ScPal.UI, Vector2(tx + 330, ty), str(h.date), 18, ScPal.INK_SOFT)
		ty += 34
