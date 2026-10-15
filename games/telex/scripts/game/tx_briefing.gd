class_name TxBriefing
extends Control
## Briefing (GDD §4.2): de dossiermap klapt open met titel, codewoord, modus, notasverwijzing en één zin van de Chef.
## Bij een nieuwe machine gaat eerst de kist open (typeplaatje met jaartal). Enter / klik = start.

signal closed

var spec: TxLevelSpec
var t := 0.0
var open_u := 0.0
var lid := 0.0
var sheen := -1.0
var crate_text := ""
var _closing := false
var _btn: Button


func setup(s: TxLevelSpec) -> void:
	spec = s
	crate_text = str(s.story.get("crate", ""))


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.55)
	var tw := create_tween()
	tw.tween_property(self, "open_u", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	TxSnd.play("strip_slide", -4.0, 0.7)
	if crate_text != "" and not spec.endless:
		tw.tween_interval(0.25)
		tw.tween_callback(func():
			TxSnd.play("crate_open", -2.0)
			TxFx.straw(self, Vector2(1440, 640), 26))
		tw.tween_property(self, "lid", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): TxSnd.play("stinger_machine", -4.0))
		tw.tween_method(func(v: float): sheen = v, 0.0, 1.2, 0.8)
	_btn = TxUi.button("Start dienst", "brass", 30, 320)
	_btn.position = Vector2(800, 880)
	_btn.pressed.connect(close)
	add_child(_btn)
	var sub := TxUi.label("Enter", 16, TxPal.TEXT_DIM, TxPal.MONO)
	sub.position = Vector2(938, 960)
	add_child(sub)
	# QA: Esc ging vroeger ook "start dienst"; nu kan je vanuit de briefing terug naar de kaart
	var bk := TxUi.button("← Missiekaart", "flat", 22, 220)
	bk.position = Vector2(300, 892)
	bk.pressed.connect(_back)
	add_child(bk)
	var sub2 := TxUi.label("Esc", 16, TxPal.TEXT_DIM, TxPal.MONO)
	sub2.position = Vector2(395, 960)
	add_child(sub2)


func key(e: InputEventKey) -> bool:
	if e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		close()
		return true
	if e.keycode == KEY_ESCAPE:
		_back()
		return true
	return false


func _back() -> void:
	if _closing:
		return
	_closing = true
	Transition.goto(TxSession.SCENE_TITLE if spec.endless and TxSession.from_map_dossier < 0 else TxSession.SCENE_MAP)


func close() -> void:
	if _closing:
		return
	_closing = true
	TxSnd.play("stamp", -4.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var u := open_u
	var r := Rect2(300, 120, 1320, 740)
	draw_set_transform(r.get_center() + Vector2(0, (1.0 - u) * 500), (1.0 - u) * -0.15, Vector2.ONE)
	var lr := Rect2(-r.size / 2.0, r.size)
	# map (manila) met tabje
	draw_rect(Rect2(lr.position + Vector2(8, 14), lr.size), TxPal.SHADOW)
	draw_style_box(TxPal.sb(TxPal.MANILA_LO, 6), Rect2(lr.position + Vector2(40, -36), Vector2(300, 50)))
	draw_texture_rect(TxPal.tex("tex/paper_tile.png"), lr, true, Color(TxPal.MANILA.r * 1.2, TxPal.MANILA.g * 1.2, TxPal.MANILA.b * 1.15))
	draw_rect(lr, TxPal.MANILA_LO, false, 2.0)
	var dn := "NACHTDIENST" if spec.endless else ("OPERATIE EKSTER" if spec.dossier == 9 else "DOSSIER %d · %s" % [spec.dossier, TxLevels.DOSSIERS[spec.dossier]])
	TxPal.text_l(self, TxPal.STENCIL, lr.position + Vector2(60, -12), dn, 22, TxPal.INK)
	var x0 := lr.position.x + 60
	var y := lr.position.y + 70
	TxPal.text_l(self, TxPal.TAPE, Vector2(x0, y), ("%s   " % spec.id if not spec.endless else "") + spec.title, 44, TxPal.INK)
	y += 70
	draw_line(Vector2(x0, y - 20), Vector2(lr.end.x - 60, y - 20), Color(TxPal.STAMP_RED, 0.5), 2.0)
	if spec.story.has("title_card"):
		TxPal.text_l(self, TxPal.STENCIL, Vector2(x0, y + 10), str(spec.story.title_card), 30, TxPal.STAMP_RED)
		y += 60
	var st: Dictionary = spec.stages[0]
	var words := PackedStringArray()
	for s in spec.stages:
		var zz := str(s.get("z", s.get("a", "")))
		if zz != "" and not words.has(zz):
			words.append(zz)
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, y + 20), "codewoord:", 26, TxPal.INK_SOFT)
	var cx := x0 + 200
	for w in words:
		var chip := TxDraw.word_chip(self, Vector2(cx, y), w, 30)
		cx = chip.end.x + 16
	y += 72
	var info := PackedStringArray()
	if st.has("q"):
		info.append("q = %d" % int(st.q))
	for s2 in spec.stages:
		if int(s2.get("k", 0)) > 0:
			info.append("k = %d fout(en) toegelaten" % int(s2.k))
			break
	var mode_s := ""
	for s3 in spec.stages:
		if str(s3.get("t", "")) != "":
			mode_s = "alle voorkomens" if str(s3.get("find", "first")) == "all" else "eerste voorkomen"
			info.append("lint: %d tekens" % str(s3.t).length())
			break
	if st.get("machine", "") == "edit":
		info.append("%s → %s" % [str(st.a), str(st.b)] if not bool(st.get("approx", false)) else "zoek %s in %s" % [str(st.a), str(st.b)])
	if mode_s != "":
		info.append(mode_s)
	if spec.mode == TxCodes.Mode.LIVE:
		info.append("LIVE: het lint wacht niet")
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, y), "   ·   ".join(info), 24, TxPal.INK)
	y += 50
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0, y), "leerstof: " + spec.notes_ref, 22, TxPal.STAMP_RED.darkened(0.2))
	y += 60
	# sterren
	for i in spec.stars.size():
		TxDraw.stars(self, Vector2(x0 + 14, y + i * 34), i + 1, 18, i + 1)
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x0 + 120, y + i * 34), TxScoring.star_label(spec.stars[i]), 20, TxPal.INK)
	y += 120
	# Chef
	TxDraw.chef(self, Vector2(x0 + 70, lr.end.y - 110), 0.62, absf(sin(t * 9.0)) * 0.4 if t < 2.0 else 0.0, 0.0)
	var line := str(spec.story.get("chef_intro", spec.intro))
	TxPal.text_l(self, TxPal.TAPE, Vector2(x0 + 160, lr.end.y - 120), "“%s”" % line, 24, TxPal.INK)
	# kist met nieuwe machine
	if crate_text != "" and not spec.endless:
		draw_set_transform(Vector2.ZERO)
		var cr := Rect2(1240, 470, 360, 230)
		TxDraw.crate(self, cr, "MODEL  " + crate_text, lid, sheen)
		if lid > 0.5:
			TxPal.text_c(self, TxPal.STENCIL, Vector2(cr.get_center().x, cr.position.y - 26), "NIEUWE MACHINE", 22, Color(TxPal.BRASS_HI, lid))
	draw_set_transform(Vector2.ZERO)
	TxDraw.stamp(self, "geheim", Vector2(1450, 220), TxPal.STAMP_RED, 0.8, 0.2, 0.7 * u)
