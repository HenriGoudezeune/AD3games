class_name ScReading
extends Control
## De Voorlezing (GDD §2.3 stap 3–4, juice #10–13): de duif (of twee) vliegt met de koker naar De Overkant, Broeder
## Letterlijk schraapt zijn keel en leest letter per letter (0,18 s, gezongen). Gelijk = gouden stip, anders = bruine
## inkt met een inktvlek. Geslaagd: klok, koor en bladgoud. Onzin: dissonant, een kan valt, de vlekken pulseren.
## Ontvangen: Zeno legt het origineel naast je kopie. Klik/Spatie versnelt; daarna "Verder".

signal closed

const PANEL := Rect2(150, 90, 1620, 900)

var res: Dictionary
var spec: ScLevelSpec
var t := 0.0
var shown := 0
var n := 0
var _dove := 0.0
var _mood := 0
var _talk := 0.0
var _pulse := 0.0
var _phase := 0         # 0 duif, 1 keel, 2 lezen, 3 klaar
var _timer := 0.0
var _fast := false
var _done := false
var _draw_n: Node2D
var _fx: Node2D
var _btn: Button
var _ov: TextureRect


func setup(r: Dictionary, s: ScLevelSpec, _d: ScDirector = null) -> void:
	res = r
	spec = s


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.01, 0.6)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_ov = TextureRect.new()
	_ov.texture = load(ScPal.ASSETS + "art/bg/bg_overkant.jpg")
	_ov.position = Vector2(PANEL.position.x + 860, PANEL.position.y + 24)
	_ov.size = Vector2(736, 540)
	_ov.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ov.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_n = Node2D.new()
	ScDraw.prepare(_draw_n)
	_draw_n.draw.connect(_paint)
	add_child(_draw_n)
	add_child(_ov)
	var front := Node2D.new()
	front.draw.connect(_paint_front.bind(front))
	front.set_meta("front", true)
	add_child(front)
	_fx = Node2D.new()
	add_child(_fx)
	n = maxi(str(res.get("original", "")).length(), str(res.get("read", "")).length())
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	if bool(res.get("receive", false)):
		_phase = 1
		_timer = 0.6
	else:
		ScSnd.play("pigeon_fly", -4.0)
		ScFx.feathers(_fx, Vector2(PANEL.position.x + 160, PANEL.position.y + 300))
		create_tween().tween_property(self, "_dove", 1.0, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_timer = 1.8
	_btn = ScUi.button("Verder", ScUi.Kind.PRIMARY, 28, 240)
	_btn.position = Vector2(PANEL.end.x - 300, PANEL.end.y - 80)
	_btn.visible = false
	_btn.pressed.connect(_close)
	add_child(_btn)


func _process(delta: float) -> void:
	t += delta
	_talk = maxf(0.0, _talk - delta * 4.0)
	var spd := 4.0 if _fast else 1.0
	_timer -= delta * spd
	match _phase:
		0:
			if _timer <= 0.0:
				_phase = 1
				_timer = 0.7
				ScSnd.play("pigeon_land", -6.0)
				ScFx.feathers(_fx, _ov.position + Vector2(150, 330))
		1:
			if _mood != 3 and not bool(res.get("receive", false)):
				_mood = 3
				ScSnd.play("throat", -4.0)
			if _timer <= 0.0:
				_phase = 2
				_mood = 0
				_timer = 0.0
		2:
			if _timer <= 0.0:
				if shown >= n:
					_end()
				else:
					_letter(shown)
					shown += 1
					_timer = 0.18
		3:
			_pulse = maxf(0.0, _pulse - delta * 0.7)
			if _btn and not _btn.visible:
				_btn.visible = true
				ScUi.pop_in(_btn)
				_btn.grab_focus()
			if ScSession.has("bot") and _timer < -1.6:
				_close()
	_draw_n.queue_redraw()
	for c in get_children():
		if c is Node2D and c.has_meta("front"):
			c.queue_redraw()


func _cell() -> float:
	return ScPal.char_w(_size()) + 10.0


func _size() -> int:
	var s := 56
	while s > 18 and (ScPal.char_w(s) + 10.0) * n > PANEL.size.x - 200:
		s -= 1
	return s


func _left() -> Vector2:
	var w := _cell() * n
	return Vector2(PANEL.get_center().x - w / 2, PANEL.end.y - 200)


func _letter(i: int) -> void:
	var o := str(res.original)
	var rd := str(res.read)
	var oc := o[i] if i < o.length() else ""
	var rc := rd[i] if i < rd.length() else ""
	_talk = 1.0
	var x := _left().x + _cell() * (i + 0.5)
	if oc == rc:
		ScSnd.sing(rc, -8.0)
	else:
		ScSnd.sing(rc if rc != "" else "u", -10.0)
		ScSnd.play("ink_blot", -8.0)
		ScFx.ink_splash(_fx, Vector2(x, _left().y + 26))


func _end() -> void:
	_phase = 3
	_timer = 0.0
	var demo := bool(res.get("demo", false))
	if bool(res.get("equal", false)):
		_mood = 1
		ScSnd.play("reading_ok", -3.0)
		var w := _cell() * n
		ScFx.gold_rain(_fx, Rect2(_left() - Vector2(0, 60), Vector2(w, 40)))
		ScFx.ring_wave(_fx, Vector2(PANEL.get_center().x, _left().y), ScPal.GOLD, 0.3, 4.0, 0.6)
	else:
		_mood = 2
		_pulse = 1.0
		ScSnd.play("reading_bad", -4.0 if not demo else -8.0)
		_shake()


func _shake() -> void:
	var s := 6.0 * ScSession.shake_scale()
	if s <= 0:
		return
	var tw := _draw_n.create_tween()
	for i in 4:
		tw.tween_property(_draw_n, "position", Vector2(randf_range(-s, s), randf_range(-s, s)), 0.03)
	tw.tween_property(_draw_n, "position", Vector2.ZERO, 0.05)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if _phase < 3:
			_fast = true
		else:
			_close()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var kc := (ev as InputEventKey).keycode
		if kc in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			if _phase < 3:
				_fast = true
			else:
				_close()
			get_viewport().set_input_as_handled()


func _close() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


func _paint() -> void:
	var c := _draw_n
	ScDraw.leather(c, PANEL, 22)
	var recv := bool(res.get("receive", false))
	var demo := bool(res.get("demo", false))
	var title := "De Voorlezing"
	if recv:
		title = "Zeno legt het origineel naast je kopie"
	elif demo:
		title = "Letterlijk leest gulzig voor"
	ScPal.text_l(c, ScPal.TITLE, PANEL.position + Vector2(40, 52), title, 44, ScPal.GILT_LIGHT)
	var sub := "%s · %s" % [ScSession.house(spec.chapter), spec.title] if spec else ""
	ScPal.text_l(c, ScPal.UI_MED, PANEL.position + Vector2(44, 96), sub, 20, ScPal.TEXT_DIM)
	# links: de werkbank met de duif die vertrekt
	if not recv:
		var pig := int(res.get("pigeons", 1))
		var ink := int(res.get("ink", 0))
		var opt := int(res.get("opt", 0))
		if ink > 0:
			ScPal.text_l(c, ScPal.UI_MED, PANEL.position + Vector2(44, 150), "inkt %d · koker %d" % [ink, opt], 22,
				ScPal.WARN if pig > 1 else ScPal.TEXT)
			ScDraw.koker(c, PANEL.position + Vector2(44, 190), 260, float(ink) / maxf(1.0, float(opt)), t)
		if pig > 1:
			ScPal.text_l(c, ScPal.UI_MED, PANEL.position + Vector2(44, 236), "Te lang voor één koker: een tweede duif vliegt mee.",
			20, ScPal.WARN)
		var toks: Array = res.get("tokens", [])
		if not toks.is_empty():
			ScPal.text_l(c, ScPal.TITLE, PANEL.position + Vector2(44, 290), "Het kortschrift", 30, ScPal.GILT_LIGHT)
			var lines: Array = [[]]
			var wsum := 0.0
			for tk in toks:
				var parts: Array = [tk]
				if tk.has("b") and ScStrip.tok_w(tk, 24) > 700:
					parts = []
					var b := str(tk.b)
					var per := 26
					var q := 0
					while q < b.length():
						parts.append({"b": b.substr(q, per)})
						q += per
				for pt in parts:
					var tw := ScStrip.tok_w(pt, 24) + 8
					if wsum + tw > 740 and not (lines[lines.size() - 1] as Array).is_empty():
						lines.append([])
						wsum = 0.0
					(lines[lines.size() - 1] as Array).append(pt)
					wsum += tw
			var box := Rect2(PANEL.position + Vector2(40, 316), Vector2(790, 40 + 44 * mini(lines.size(), 4)))
			ScDraw.parchment(c, box, 13, ScPal.VELLUM, true, 0.5)
			for li in mini(lines.size(), 4):
				ScDraw.shorthand(c, box.position + Vector2(24, 40 + li * 44), lines[li], 24, -1.0, t, false)


func _paint_front(c: Node2D) -> void:
	var recv := bool(res.get("receive", false))
	var pr := Rect2(_ov.position, _ov.size)
	ScPal.ring(c, pr.grow(3), 8, ScPal.GILT, 2)
	ScDraw.letterlijk(c, pr.position + Vector2(pr.size.x * 0.5, pr.size.y - 40), 1.1, t, _mood,
		_talk * (0.5 + 0.5 * sin(t * 16.0)))
	if recv:
		ScDraw.zeno(c, Vector2(PANEL.position.x + 330, PANEL.position.y + 560), 1.2, t, _talk * 0.5)
	else:
		var pig := int(res.get("pigeons", 1))
		for k in pig:
			var a := clampf(_dove * 1.1 - k * 0.12, 0.0, 1.0)
			var p0 := PANEL.position + Vector2(220 - k * 70, 380 + k * 40)
			var p1 := pr.position + Vector2(150 + k * 90, 330 + k * 20)
			var p := p0.lerp(p1, a) + Vector2(0, -sin(a * PI) * 160)
			var pose := 1 if a < 0.98 else 0
			ScDraw.dove(c, p, 1.1, t + k, pose, 1.0, 1 if k == 1 else 0, true)
	# de kopie
	var lm := _left()
	var w := _cell() * n
	var bw := maxf(w + 80, 700.0)
	var br := Rect2(Vector2(PANEL.get_center().x - bw / 2, lm.y - 130), Vector2(bw, 250))
	ScDraw.parchment(c, br, 51, ScPal.VELLUM, true, 0.6)
	ScPal.text_l(c, ScPal.UI_MED, br.position + Vector2(22, 24), "origineel" if not recv else "origineel van de afzender", 18,
		ScPal.INK_SOFT)
	ScPal.text_l(c, ScPal.UI_MED, br.position + Vector2(22, br.size.y - 22), "Letterlijk leest" if not recv else "jouw kopie", 18,
		ScPal.INK_SOFT)
	var sh := shown if _phase >= 2 else 0
	ScDraw.reading(c, lm + Vector2(0, 0), str(res.get("original", "")), str(res.get("read", "")), _size(), sh, t,
		_pulse * (0.5 + 0.5 * sin(t * 10.0)))
	if _phase == 3:
		var eq := bool(res.get("equal", false))
		var head := "VERLIESLOOS" if eq else ("DE OVERKANT LAS ONZIN" if not recv else "JE KOPIE WIJKT AF")
		if bool(res.get("demo", false)):
			head = "ZO LEEST LETTERLIJK DEZE CODE" if not eq else "TOEVALLIG JUIST"
		ScPal.text_outline_c(c, ScPal.UI_BOLD, Vector2(PANEL.get_center().x - 160, PANEL.end.y - 50), head, 34,
			ScPal.GOLD_LIGHT if eq else ScPal.VELLUM_HI, 8)
