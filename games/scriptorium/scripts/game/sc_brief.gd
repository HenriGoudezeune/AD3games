class_name ScBrief
extends Control
## De brief van het huis (GDD §2.3 stap 1, §4.2): bij een nieuw werktuig gaat eerst een houten kist open (1,5 s),
## dan breekt het zegel en ontrolt de brief: titel, opdracht, modus (verzenden/ontvangen), notasverwijzing en één zin
## van Zeno. Klik, Enter of Spatie: beginnen (skipbaar).

signal closed

var spec: ScLevelSpec
var t := 0.0
var _crate := ""
var _crate_open := 0.0
var _open := 0.0
var _text_a := 0.0
var _phase := 0
var _done := false
var _draw_n: Node2D
var _fx: Node2D
var _btn: Button
var _tw: Tween


func setup(s: ScLevelSpec) -> void:
	spec = s


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.55)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_draw_n = Node2D.new()
	ScDraw.prepare(_draw_n)
	_draw_n.draw.connect(_paint)
	add_child(_draw_n)
	_fx = Node2D.new()
	add_child(_fx)
	var seen: Array = ScSave.setting("crates_seen", [])
	var cr := str(spec.story.get("crate", ""))
	if cr != "" and not seen.has(cr):
		_crate = cr
		seen.append(cr)
		ScSave.set_setting("crates_seen", seen)
	var tw := create_tween()
	_tw = tw
	if _crate != "":
		tw.tween_interval(0.3)
		tw.tween_callback(func():
			ScSnd.play("crate_open", -2.0)
			ScFx.crate_open(_fx, Vector2(960, 560)))
		tw.tween_property(self, "_crate_open", 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.1)
		tw.tween_callback(func(): _phase = 1)
	else:
		_phase = 1
	tw.tween_callback(func(): ScSnd.play("letter_open", -4.0))
	tw.tween_property(self, "_open", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): ScSnd.play("unroll", -8.0))
	tw.tween_property(self, "_text_a", 1.0, 0.5)
	_btn = ScUi.button("Aan het werk", ScUi.Kind.WAX, 30, 300)
	_btn.position = Vector2(810, 900)
	_btn.modulate.a = 0.0
	_btn.pressed.connect(_close)
	add_child(_btn)
	tw.tween_property(_btn, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func(): _btn.grab_focus())


func _process(delta: float) -> void:
	t += delta
	_draw_n.queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_skip_or_close()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if (ev as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			_skip_or_close()
			get_viewport().set_input_as_handled()


func _skip_or_close() -> void:
	if _text_a < 1.0:
		if _tw and _tw.is_valid():
			_tw.custom_step(20.0)
		_crate_open = 1.0
		_open = 1.0
		_text_a = 1.0
		_phase = 1
		_btn.modulate.a = 1.0
		return
	_close()


func _close() -> void:
	if _done:
		return
	_done = true
	ScSnd.play("page_turn", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		closed.emit()
		queue_free())


static func _stage_line(st: Dictionary) -> String:
	var tl := str(st.get("tool", ""))
	var recv := str(st.get("side", "send")) == "receive" or tl == "prefix_read"
	var mode := "ontvangen" if recv else "verzenden"
	var what := ""
	match tl:
		"prefix_read":
			what = "lees de strook %s met de codeboom" % str(st.get("bits", ""))
		"code_board":
			what = "knip de strook %s in woorden" % str(st.get("bits", "")) if str(st.get("mode", "")) == "cuts" \
				else "ontwerp een prefixcode voor \"%s\"" % ScPal.show_text(str(st.get("text", "")))
		"bindery":
			if st.has("weights"):
				what = "voeg de registers samen"
			elif str(st.get("symbols", "")) == "carry":
				what = "bind een boom over de getallen van de plank"
			else:
				what = "bind een codeboom voor \"%s\"" % ScPal.show_text(str(st.get("text", "")))
		"living_tree":
			what = "schrijf \"%s\" met de levende boom" % ScPal.show_text(str(st.get("text", ""))) if not recv \
				else "lees het kortschrift met de levende boom"
		"ruler":
			if recv:
				what = "lees %s letters van de meetlat" % str(st.get("n", ""))
			else:
				what = "meet \"%s\" op de meetlat" % ScPal.show_text(str(st.get("text", "")))
		"window":
			what = "schrijf \"%s\" met het leesraam (G = %s)" % [ScPal.show_text(str(st.get("text", ""))), _g(st)] if not recv \
				else "lees de zegels met het leesraam (G = %s)" % _g(st)
		"stampcase":
			what = "stempel \"%s\"" % ScPal.show_text(str(st.get("text", ""))) if not recv else "lees de stempels %s" % _codes(st)
		"drum":
			what = "draai \"%s\" op de trommel" % ScPal.show_text(str(st.get("text", ""))) if not recv \
				else "loop de terugweg van p = %s, c = %s" % [str(st.get("p", "")), ScPal.show_text(str(st.get("c", "")))]
		"shelf":
			what = "zet de tekst op de letterplank" if not recv else "lees de getallen met de letterplank"
		"dovecote":
			what = "breng elke duif in een korter hok"
	return "%s · %s" % [mode, what]


static func _g(st: Dictionary) -> String:
	var g := int(st.get("G", -1))
	return "∞" if g < 0 else str(g)


static func _codes(st: Dictionary) -> String:
	var parts := PackedStringArray()
	for c in st.get("codes", []):
		parts.append(str(c))
	return " ".join(parts)


func _paint() -> void:
	var c := _draw_n
	var ch := ScPal.chapter(spec.chapter)
	if _crate != "" and _phase == 0:
		ScDrawTools.crate(c, Vector2(960, 640), 1.6, _crate_open, t)
		ScPal.text_outline_c(c, ScPal.TITLE, Vector2(960, 330), "Een nieuw werktuig: %s" % _crate, 52, ScPal.GILT_LIGHT)
		return
	var r := Rect2(460, 120 + (1.0 - _open) * 200, 1000, 740 * _open + 60)
	ScDraw.parchment(c, r, 17, ScPal.VELLUM, true, 0.7)
	ScDraw.seal(c, Vector2(r.get_center().x, r.position.y + 6), 34, ScSession.house(spec.chapter).substr(0, 1), ScPal.TITLE,
		32, ch.col if spec.chapter != 3 else ScPal.WAX)
	if _text_a <= 0.01:
		return
	var a := _text_a
	var x := r.position.x + 70
	var y := r.position.y + 80
	ScPal.text_l(c, ScPal.TITLE_LIGHT, Vector2(x, y), "Van %s · %s" % [ScSession.house(spec.chapter), ScSession.chapter_title(spec.chapter)],
		28, Color(ScPal.RUBRIC, a))
	y += 64
	ScPal.text_l(c, ScPal.TITLE, Vector2(x, y), "%s  %s" % [spec.id, spec.title], 56, Color(ScPal.INK, a))
	y += 54
	ScPal.text_l(c, ScPal.UI_MED, Vector2(x, y), spec.notes_ref, 22, Color(ScPal.INK_SOFT, a))
	y += 30
	c.draw_line(Vector2(x, y), Vector2(r.end.x - 70, y), Color(ScPal.RUBRIC, 0.5 * a), 2.0, true)
	y += 40
	for i in spec.stages.size():
		var st: Dictionary = spec.stages[i]
		var line := _stage_line(st)
		ScDraw.tool_icon(c, Vector2(x + 18, y), 13, ScSession.tool_icon(str(st.get("tool", ""))), Color(ScPal.INK_SOFT, a), t)
		ScPal.text_l(c, ScPal.UI_BOLD, Vector2(x + 46, y), ScSession.tool_title(str(st.get("tool", ""))), 24, Color(ScPal.INK, a))
		var lw := ScPal.text_w(ScPal.UI_BOLD, ScSession.tool_title(str(st.get("tool", ""))), 24)
		ScPal.text_l(c, ScPal.UI, Vector2(x + 56 + lw, y), "— " + line, 22, Color(ScPal.INK, a))
		y += 42
		if y > r.end.y - 220:
			break
	var opt := ScLevels.optimum(spec)
	if int(opt.get("ink", 0)) > 0:
		y += 6
		ScPal.text_l(c, ScPal.UI_MED, Vector2(x, y), "De koker van de duif past precies het optimum. Elke druppel telt.", 20,
			Color(ScPal.INK_SOFT, a))
		y += 34
	# Zeno
	ScDraw.zeno(c, Vector2(r.position.x + 120, r.end.y - 30), 0.8, t, 0.0)
	var zr := Rect2(r.position.x + 200, r.end.y - 170, r.size.x - 260, 64)
	ScDraw.scroll(c, zr, Vector2(r.position.x + 160, r.end.y - 120))
	ScPal.text_l(c, ScPal.UI, zr.position + Vector2(30, 32), spec.intro, 24, Color(ScPal.INK, a))
	# sterren
	var sx := r.end.x - 70
	for i in range(spec.stars.size() - 1, -1, -1):
		var lab := ScScoring.star_label(spec.stars[i])
		var w := ScPal.text_w(ScPal.UI_MED, lab, 18)
		ScPal.text_l(c, ScPal.UI_MED, Vector2(sx - w, r.position.y + 84 + i * 28), lab, 18, Color(ScPal.INK_SOFT, a))
		ScDraw.star_seal(c, Vector2(sx - w - 20, r.position.y + 84 + i * 28), 10, false, 1.0, i)
