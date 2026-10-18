extends Control
## Het getijdenboek (kaart, GDD §4.2): een opengeslagen getijdenboek met per bladzijde een hoofdstuk van het
## kloosterjaar (Advent … Allerheiligen). Elk level is een verluchte initiaal met 0–3 lakzegels en het pictogram van
## het werktuig; hover toont de leerstof. Dicht = steengrijs met een slotje. ←/→ of de hoekjes bladeren; klik of Enter
## opent de brief. Rechtsboven het kaarsje Nachtwake. Esc = titel.

const BOOK := Rect2(150, 150, 1620, 800)

var t := 0.0
var spread := 0
var _n: Node2D
var _fx: Node2D
var _zones: Array = []          # [{r, id}]
var _hover := ""
var _sel := -1
var _stars := {}
var _new_stars := {}
var _turn := 0.0
var _mouse := Vector2(-99, -99)
var _wake_r := Rect2(1676, 20, 220, 110)
var _prev_r := Rect2()
var _next_r := Rect2()


func _ready() -> void:
	ScSession.apply_all()
	ScSession.lesson_boot()
	ScSession.lesson_queue.clear()     # een afgebroken les gaat niet stilletjes verder
	theme = ScUi.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load(ScPal.ASSETS + "art/bg/bg_room.jpg")
	bg.size = Vector2(1920, 1080)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(ScUi.shafts_overlay(Vector2(0.5, 0.06), 0.1))
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	_fx = Node2D.new()
	add_child(_fx)
	_stars = ScSave.all_stars()
	var focus := ScSession.map_focus
	if focus != "" and ScLevels.has(focus):
		spread = ScLevels.chapter_of(focus) / 2
		var before: Dictionary = ScSession.map_stars_before
		if int(_stars.get(focus, 0)) > int(before.get(focus, 0)):
			_new_stars[focus] = int(before.get(focus, 0))
			var tw := create_tween()
			tw.tween_interval(0.6)
			tw.tween_callback(func():
				ScSnd.play("wax_seal", -4.0)
				for z in _zones:
					if z.id == focus:
						ScFx.wax_splat(_fx, (z.r as Rect2).get_center() + Vector2(0, 70))
				_new_stars.clear())
	else:
		spread = _first_open_spread()
	ScSession.map_focus = ""
	var back := ScUi.button("← Titel", ScUi.Kind.GHOST, 24, 180)
	back.position = Vector2(24, 20)
	back.pressed.connect(func(): Transition.goto(ScSession.SCENE_TITLE))
	add_child(back)
	var th := ScUi.button("Theorie  (F1)", ScUi.Kind.GHOST, 24, 200)
	th.position = Vector2(384, 20)   # naast het HubNav-huisje
	th.tooltip_text = "Uitleg & theorie: compressie volgens de lesnotas (hoofdstuk 4)"
	th.pressed.connect(open_theory)
	add_child(th)
	if ScSession.has("guide"):
		get_tree().create_timer(1.0).timeout.connect(open_theory)
	# QA: check=<level> opent meteen de Check-vragen van dat level (leerpad)
	if ScSession.has("check") and ScLevels.has(ScSession.arg("check")):
		var lid := ScSession.arg("check")
		get_tree().create_timer(0.8).timeout.connect(func(): ScCheckQuiz.open(self, ScLessons.report_parts(lid)))
	ScSnd.music("title")
	ScSnd.play("page_turn", -6.0)


func _first_open_spread() -> int:
	var best := 0
	for id in ScLevels.ids():
		if ScSession.unlocked(id) and ScLevels.priority_of(id) == "P0":
			best = ScLevels.chapter_of(id) / 2
	return clampi(best, 0, 3)


func _process(delta: float) -> void:
	t += delta
	_turn = maxf(0.0, _turn - delta * 3.0)
	ScSession.qa_tick(delta)
	_n.queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_mouse = ev.position
		_hover = ""
		for z in _zones:
			if (z.r as Rect2).has_point(_mouse):
				_hover = z.id
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if _wake_r.has_point(ev.position):
			_open_wake()
			return
		if _prev_r.has_point(ev.position):
			_flip(-1)
			return
		if _next_r.has_point(ev.position):
			_flip(1)
			return
		for z in _zones:
			if (z.r as Rect2).has_point(ev.position):
				_open(str(z.id))
				return


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_ESCAPE:
				Transition.goto(ScSession.SCENE_TITLE)
			KEY_F1:
				open_theory()
			KEY_PAGEUP:
				_flip(-1)
			KEY_PAGEDOWN:
				_flip(1)
			KEY_LEFT, KEY_UP:
				_move_sel(-1)
			KEY_RIGHT, KEY_DOWN:
				_move_sel(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if _sel >= 0 and _sel < _zones.size():
					_open(str(_zones[_sel].id))
			_:
				return
		get_viewport().set_input_as_handled()


func _move_sel(d: int) -> void:
	if _zones.is_empty():
		return
	var n := _sel + d
	if n < 0:
		if spread > 0:
			_flip(-1)
			_sel = 99
		else:
			_sel = 0
		return
	if n >= _zones.size():
		if spread < 3:
			_flip(1)
			_sel = 0
		return
	_sel = n
	_hover = str(_zones[_sel].id)
	ScSnd.play("ui_wood", -12.0)


func _flip(d: int) -> void:
	var ns := clampi(spread + d, 0, 3)
	if ns == spread:
		return
	spread = ns
	_turn = 1.0
	_sel = -1
	ScSnd.play("page_turn", -4.0)


func _open(id: String) -> void:
	if not ScSession.unlocked(id):
		ScSnd.play("clamp", -6.0)
		return
	ScSession.level_id = id
	ScSession.wake = false
	Transition.goto(ScSession.SCENE_BENCH)


func _open_wake() -> void:
	if not ScSession.unlocked("nachtwake"):
		ScSnd.play("clamp", -6.0)
		return
	ScSession.wake = true
	Transition.goto(ScSession.SCENE_BENCH)


func _paint() -> void:
	var c := _n
	var ch_a := spread * 2
	var pages := ScDrawTools.book_spread(c, BOOK, ScPal.chapter(ch_a).col, t)
	_zones = []
	for side in 2:
		var ch := ch_a + side
		var pg: Rect2 = pages[side]
		_paint_page(c, pg, ch)
	if _sel >= _zones.size():
		_sel = _zones.size() - 1
	# bladerhoekjes
	_prev_r = Rect2(BOOK.position + Vector2(-10, BOOK.size.y - 80), Vector2(90, 90))
	_next_r = Rect2(Vector2(BOOK.end.x - 80, BOOK.end.y - 80), Vector2(90, 90))
	if spread > 0:
		ScDraw.fill(c, PackedVector2Array([_prev_r.position + Vector2(10, 80), _prev_r.position + Vector2(10, 20),
			_prev_r.position + Vector2(70, 80)]), Color(ScPal.VELLUM_AGED, 0.9 if _prev_r.has_point(_mouse) else 0.6))
		ScPal.text_c(c, ScPal.UI_BOLD, _prev_r.position + Vector2(30, 62), "‹", 34, ScPal.INK)
	if spread < 3:
		ScDraw.fill(c, PackedVector2Array([_next_r.position + Vector2(80, 80), _next_r.position + Vector2(80, 20),
			_next_r.position + Vector2(20, 80)]), Color(ScPal.VELLUM_AGED, 0.9 if _next_r.has_point(_mouse) else 0.6))
		ScPal.text_c(c, ScPal.UI_BOLD, _next_r.position + Vector2(60, 62), "›", 34, ScPal.INK)
	# Nachtwake-kaarsje
	var open_w := ScSession.unlocked("nachtwake")
	c.draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.9), 18, 8), _wake_r)
	ScPal.ring(c, _wake_r.grow(-4), 14, Color(ScPal.GILT, 0.8 if _wake_r.has_point(_mouse) else 0.4), 2)
	ScDraw.candle(c, _wake_r.position + Vector2(40, 96), 0.42, t, open_w, 0.8)
	ScPal.text_l(c, ScPal.TITLE, _wake_r.position + Vector2(74, 42), "Nachtwake", 26, ScPal.GILT_LIGHT if open_w else ScPal.TEXT_DIM)
	ScPal.text_l(c, ScPal.UI_MED, _wake_r.position + Vector2(74, 76), "eindeloos" if open_w else "na 1-2", 18, ScPal.TEXT_DIM)
	# hover-info
	if _hover != "" and ScLevels.has(_hover):
		var sp := ScLevels.get_spec(_hover)
		var lock := not ScSession.unlocked(_hover)
		var txt := "%s  %s · %s%s" % [_hover, sp.title, sp.notes_ref, "  (dicht)" if lock else ""]
		for pid in ScLessons.parts_for_level(_hover):
			txt += "  ·  leerpad %d: %s (%s)" % [ScLessons.index_of_part(pid) + 1, ScLessons.part(pid).title,
				ScLessons.LEVEL_TXT[ScLessons.level(pid)]]
		var hfs := 24
		while hfs > 15 and ScPal.text_w(ScPal.UI_MED, txt, hfs) + 50 > 1880:
			hfs -= 1
		var w := ScPal.text_w(ScPal.UI_MED, txt, hfs) + 50
		var r := Rect2(960 - w / 2, BOOK.end.y + 46, w, 52)
		c.draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.95), 26, 8), r)
		ScPal.text_c(c, ScPal.UI_MED, r.get_center(), txt, hfs, ScPal.TEXT)
	if _turn > 0.0:
		var x := lerpf(BOOK.position.x, BOOK.end.x, 1.0 - _turn)
		c.draw_rect(Rect2(x - 40, BOOK.position.y, 80, BOOK.size.y), Color(ScPal.VELLUM_HI, 0.5 * _turn))


func _paint_page(c: CanvasItem, pg: Rect2, ch: int) -> void:
	var chd := ScPal.chapter(ch)
	ScPal.text_c(c, ScPal.TITLE, Vector2(pg.get_center().x, pg.position.y + 70), chd.name, 52, chd.col)
	ScPal.text_c(c, ScPal.UI_MED, Vector2(pg.get_center().x, pg.position.y + 116), "%s · %s" % [ScSession.house(ch),
		"de Codex" if ch == 7 else ScSession.tool_title(_chapter_tool(ch)).to_lower()], 22, ScPal.INK_SOFT)
	var ids: Array = []
	for id in ScLevels.chapter_ids(ch):
		if ScLevels.priority_of(id) != "P2":
			ids.append(id)
	var cols := 3
	var cw := 200.0
	var x0 := pg.get_center().x - cw * (mini(cols, ids.size()) - 1) / 2.0
	for i in ids.size():
		var id: String = ids[i]
		var cx := x0 + (i % cols) * cw
		var cy := pg.position.y + 220 + (i / cols) * 250
		var r := Rect2(cx - 50, cy - 50, 100, 100)
		var lock := not ScSession.unlocked(id)
		var st := int(_stars.get(id, 0))
		if _new_stars.has(id):
			st = int(_new_stars[id])
		var sp := ScLevels.get_spec(id)
		var tt0 := sp.title
		if tt0.contains(": "):
			tt0 = tt0.substr(tt0.find(": ") + 2)
		var letter := tt0.substr(0, 1).to_upper()
		var hi := _hover == id
		var tl := ScSession.tool_icon(str(sp.stages[0].get("tool", ""))) if not sp.stages.is_empty() else "codex"
		ScDrawTools.initial(c, r, letter, ch, st, lock, hi, t, tl, id + ("  ·  P1" if ScLevels.priority_of(id) == "P1" else ""))
		var tt := sp.title
		var fs := 18
		while fs > 14 and ScPal.text_w(ScPal.UI_MED, tt, fs) > cw - 10:
			fs -= 1
		ScPal.text_c(c, ScPal.UI_MED, Vector2(cx, r.end.y + 72), tt, fs, ScPal.INK_SOFT if lock else ScPal.INK)
		_draw_badges(c, r, id)
		_zones.append({"r": r.grow(10), "id": id})
		if _sel == _zones.size() - 1:
			ScPal.ring(c, r.grow(10), 10, ScPal.INFO, 3)


## Leerpad-badges linksboven op de initiaal (rechtsboven staat het werktuig) van de poort: grijs = nog niet, blauw = demo bekeken, amber = samen
## geoefend, groen ✓ = begrepen (design/LEARNING_PATH.md).
func _draw_badges(c: CanvasItem, r: Rect2, id: String) -> void:
	var pids := ScLessons.parts_for_level(id)
	for k in pids.size():
		var lv := ScLessons.level(str(pids[k]))
		var col: Color = [ScPal.INK_FADED, ScPal.LAPIS_LIGHT, ScPal.WARN, ScPal.OK][lv]
		var p := Vector2(r.position.x - 2 + k * 26, r.position.y - 4)
		c.draw_circle(p, 12.0, ScPal.PANEL)
		c.draw_circle(p, 9.5, col)
		if lv == 3:
			c.draw_polyline(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(-1, 4), p + Vector2(5, -4)]), ScPal.VELLUM_HI, 2.6, true)
		else:
			ScPal.text_c(c, ScPal.MONO_B, p + Vector2(0, 1), str(ScLessons.index_of_part(str(pids[k])) + 1), 11, ScPal.VELLUM_HI if lv > 0 else ScPal.INK)


static func _chapter_tool(ch: int) -> String:
	match ch:
		0:
			return "prefix_read"
		1:
			return "bindery"
		2:
			return "living_tree"
		3:
			return "ruler"
		4:
			return "window"
		5:
			return "stampcase"
		6:
			return "drum"
	return ""


var _guide: HubGuide


## Gids op het tabblad Theorie (ook Doel en Handelingen voor alle werktuigen).
func open_theory() -> void:
	if _guide and is_instance_valid(_guide):
		return
	_guide = HubGuide.open(self, ScGuide.content(null, "", false, "theorie"), ScGuide.style())
	_guide.closed.connect(func(): _guide = null)
