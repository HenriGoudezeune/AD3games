extends Control
## Dagenkaart (GDD §7): 7 depots langs een weg + ∞. Sterren, slot, mechaniek-pictogram.
## Klik → de heftruck rijdt over de weg naar het depot → dag start.

const TITLES := ["", "Eerste werkdag", "De muur schuift", "Bijbouwen", "Klanten aan de balie", "De 11110-storm", "Oefening 5", "De Klonen"]
const ICONS := ["endless", "hatch", "lever", "saw", "desk", "storm", "book", "clones"]
const POS := [Vector2(940, 830), Vector2(230, 300), Vector2(520, 560), Vector2(820, 300), Vector2(1110, 560),
	Vector2(1400, 300), Vector2(1690, 520), Vector2(1400, 800)]
## volgorde langs de weg: 1..7, dan ∞ (index 0)
const ROUTE := [1, 2, 3, 4, 5, 6, 7, 0]

var _road: PackedVector2Array
var _hover := -1
var _pop := {}
var _t := 0.0
var _truck_f := 0.0
var _truck_pos := Vector2.ZERO
var _going := false
var _available := 7
var _canvas: Node2D
var _focus := 1


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.new())
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)
	_available = Days.count()
	var pts := PackedVector2Array()
	for d in ROUTE:
		pts.append(POS[d] + Vector2(0, 90))
	_road = _smooth(pts)
	for d in ROUTE:
		_pop[d] = 0.0
	var back := UIKit.button("Terug", Pal.PANEL_HI, Pal.TEXT, 26, 180)
	back.position = Vector2(30, 990)
	back.pressed.connect(func(): Transition.goto(Game.SCENE_TITLE))
	add_child(back)
	var theo := UIKit.button("Theorie", Pal.PANEL_HI, Pal.TEXT, 26, 180)
	theo.position = Vector2(230, 990)
	theo.pressed.connect(_open_theory)
	add_child(theo)
	var lp := UIKit.button("Leerpad", Pal.INFO, Pal.INK, 26, 180)
	lp.position = Vector2(430, 990)
	lp.pressed.connect(_open_path)
	add_child(lp)
	var lg := UIKit.label("Bolletjes onder een dag = delen van het leerpad:  amber = demo gezien · blauw = geoefend · groen = begrepen", 20, Pal.TEXT_DIM, Pal.UI_MED)
	lg.position = Vector2(640, 1004)
	add_child(lg)
	Game.lesson_queue.clear()
	var title := UIKit.label("Kies een werkdag", 56, Pal.TEXT, Pal.UI_BOLD)
	title.position = Vector2(200, 24)   # links ervan staat het HubNav-huisje
	add_child(title)
	Sfx.play_track("calm")
	# depots poppen een voor een op
	for i in ROUTE.size():
		var d: int = ROUTE[i]
		var tw := create_tween()
		tw.tween_interval(0.15 + i * 0.07)
		tw.tween_method(func(v): _pop[d] = v, 0.0, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): Sfx.play("drop_box", -12.0, 1.0 + i * 0.05))
	# heftruck staat bij de laatst gespeelde/ontgrendelde dag
	var start_day := 1
	for d in range(1, 8):
		if Game.is_unlocked(d) and d <= _available:
			start_day = d
	_focus = start_day
	_truck_f = _road_f(ROUTE.find(start_day))
	if Game.cmd.has("leerpad"):
		_open_path.call_deferred()
	if Game.cmd.has("check"):
		var cd := int(Game.cmd["check"])
		await get_tree().create_timer(0.6).timeout
		CheckQuiz.open(self, HDLessons.report_parts(cd))
	if Game.cmd.has("autostart"):
		await get_tree().create_timer(1.5).timeout
		_go(Game.current_day)


func _smooth(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for k in 16:
			var t := k / 16.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


func _road_f(route_i: int) -> float:
	return float(route_i) / (ROUTE.size() - 1)


func _process(d: float) -> void:
	_t += d
	_truck_pos = Pal.path_point(_road, _truck_f)
	var m := get_global_mouse_position()
	var h := -1
	for dd in ROUTE:
		if Rect2(POS[dd] - Vector2(110, 110), Vector2(220, 230)).has_point(m):
			h = dd
	if h != _hover and h >= 0:
		Sfx.ui("hover", -10.0)
	_hover = h
	_canvas.queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _hover >= 0:
		_go(_hover)


func _open_theory() -> void:
	if _guide and is_instance_valid(_guide):
		return
	Sfx.ui("open")
	_guide = HubGuide.open(self, HDGuide.content(null, "theorie"), HDGuide.style())


var _guide: HubGuide


## Gids op het leerpad (tab Doel, vanaf de eerste deel-pagina).
func _open_path() -> void:
	if _guide and is_instance_valid(_guide):
		return
	Sfx.ui("open")
	var c := HDGuide.content(null, "doel")
	c["page"] = 1
	_guide = HubGuide.open(self, c, HDGuide.style())


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed):
		return
	if (ev as InputEventKey).keycode == KEY_F1:
		_open_theory()
		return
	var k := (ev as InputEventKey).keycode
	var ri := ROUTE.find(_focus)
	if k == KEY_RIGHT or k == KEY_DOWN:
		_focus = ROUTE[mini(ri + 1, ROUTE.size() - 1)]
		Sfx.ui("hover")
	elif k == KEY_LEFT or k == KEY_UP:
		_focus = ROUTE[maxi(ri - 1, 0)]
		Sfx.ui("hover")
	elif k == KEY_ENTER or k == KEY_SPACE or k == KEY_KP_ENTER:
		_go(_focus)
	elif k >= KEY_1 and k <= KEY_7:
		_go(k - KEY_0)
	elif k == KEY_ESCAPE:
		Transition.goto(Game.SCENE_TITLE)


func _playable(d: int) -> bool:
	if d == 0:
		return Game.is_unlocked(0) and Days.get_day(0) != null and _available >= 7
	return d <= _available and Game.is_unlocked(d)


func _go(d: int) -> void:
	if _going:
		return
	if not _playable(d):
		Sfx.ui("error")
		_pop[d] = 0.85
		create_tween().tween_method(func(v): _pop[d] = v, 0.85, 1.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		return
	_going = true
	Sfx.ui("confirm")
	Sfx.play("sfx/warehouse_trip.wav", -4.0)
	var target := _road_f(ROUTE.find(d))
	var dur := clampf(absf(target - _truck_f) * 2.5, 0.35, 1.2)
	var tw := create_tween()
	tw.tween_property(self, "_truck_f", target, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	Game.goto_day(d)


func _draw_map() -> void:
	var c := _canvas
	# weg
	c.draw_polyline(_road, Pal.OUTLINE, 64, true)
	c.draw_polyline(_road, Color("#2A3452"), 52, true)
	var dash_len := 0.0
	for i in range(1, _road.size()):
		dash_len += _road[i - 1].distance_to(_road[i])
		if int(dash_len / 30.0) % 2 == 0:
			c.draw_line(_road[i - 1], _road[i], Color(Pal.WARN, 0.5), 4, true)
	for d in ROUTE:
		_draw_depot(c, d)
	# heftruck
	var ahead := Pal.path_point(_road, minf(_truck_f + 0.01, 1.0))
	var flip := -1.0 if ahead.x < _truck_pos.x else 1.0
	c.draw_set_transform(_truck_pos + Vector2(0, -16 + sin(_t * 12.0) * (2.0 if _going else 0.0)), 0, Vector2(2.6 * flip, 2.6))
	Pal.truck(c, Vector2.ZERO)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_depot(c: Node2D, d: int) -> void:
	var p: Vector2 = POS[d]
	var s: float = _pop.get(d, 1.0)
	if s <= 0.01:
		return
	var hov := (_hover == d or _focus == d) and not _going
	var lift := -8.0 if hov else 0.0
	c.draw_set_transform(p + Vector2(0, lift), 0, Vector2(s, s))
	var ok := _playable(d)
	var col: Color = Pal.bucket_color(d + 2) if ok else Pal.PANEL_LO
	var body := Rect2(-100, -70, 200, 150)
	c.draw_style_box(Pal.sb(Pal.PANEL if ok else Pal.PANEL_LO, 22, 16, Vector2(0, 10)), body)
	Pal.head(c, Rect2(body.position, Vector2(body.size.x, 44)), col, 22)
	# poort
	c.draw_style_box(Pal.sb(Pal.SLOT, 10), Rect2(-44, 10, 88, 70))
	for k in 4:
		c.draw_line(Vector2(-40, 22 + k * 16), Vector2(40, 22 + k * 16), Color(1, 1, 1, 0.06), 3)
	var lab := ("DAG %d" % d) if d > 0 else "∞"
	Pal.text_c(c, Pal.UI_BOLD, Vector2(0, -48), lab, 30 if d > 0 else 40, Pal.INK if ok else Pal.TEXT_DIM)
	_icon(c, Vector2(0, -2), ICONS[d], ok)
	var title: String = TITLES[d] if d > 0 else "Piekdag"
	Pal.text_c(c, Pal.UI_BOLD, Vector2(0, 104), title, 22, Pal.TEXT if ok else Pal.TEXT_DIM)
	if d > 0:
		var st := Game.stars_of(d)
		for k in 3:
			var sc := Vector2(-40 + k * 40, 140)
			Pal.star_shape(c, sc, 16, Pal.COIN if k < st else Color(1, 1, 1, 0.12))
		_draw_badges(c, d)
	if not ok:
		c.draw_texture_rect(Juice.icon("locked"), Rect2(-28, 14, 56, 56), false, Pal.TEXT_DIM)
	if hov and ok:
		Pal.ring(c, body.grow(8), 28, Color(Pal.OK, 0.6 + 0.4 * sin(_t * 6.0)), 5)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _icon(c: Node2D, at: Vector2, kind: String, ok: bool) -> void:
	if not ok:
		return
	var w := Pal.TEXT
	match kind:
		"hatch":
			c.draw_style_box(Pal.sb(Pal.HOLE, 6), Rect2(at + Vector2(-20, -8), Vector2(40, 30)))
			c.draw_style_box(Pal.sb(Pal.PANEL_HI, 6), Rect2(at + Vector2(-20, -8), Vector2(40, 14)))
		"lever":
			c.draw_line(at + Vector2(0, 22), at + Vector2(10, -8), Color("#566390"), 6, true)
			c.draw_circle(at + Vector2(10, -10), 11, Pal.WARN, true, -1, true)
		"saw":
			Pal.saw_icon(c, at + Vector2(0, 6), 18, w, _t)
		"desk":
			c.draw_circle(at + Vector2(0, -4), 12, Pal.SKIN[0], true, -1, true)
			c.draw_style_box(Pal.sb(Pal.CLOTHES[0], 8), Rect2(at + Vector2(-14, 8), Vector2(28, 18)))
		"storm":
			Pal.text_c(c, Pal.MONO, at + Vector2(0, 8), "11110", 18, Pal.WARN)
		"book":
			c.draw_style_box(Pal.sb(Pal.LABEL, 4), Rect2(at + Vector2(-20, -10), Vector2(40, 32)))
			c.draw_line(at + Vector2(0, -10), at + Vector2(0, 22), Pal.INK, 2)
		"clones":
			for k in 2:
				c.draw_style_box(Pal.sb(Pal.KRAFT, 4), Rect2(at + Vector2(-22 + k * 18, -8 + k * 6), Vector2(26, 22)))
		"endless":
			Pal.text_c(c, Pal.UI_BOLD, at + Vector2(0, 8), "∞", 44, Pal.COIN)


## Leerpad-badges: één bolletje per deel van deze dag (grijs = nog niet, amber = demo gezien, blauw = samen
## geoefend, groen + vinkje = begrepen).
func _draw_badges(c: Node2D, d: int) -> void:
	var ps := HDLessons.parts_for_day(d)
	var k := 0
	for id in ps:
		var lv := HDLessons.level(id)
		var col: Color = [Color(1, 1, 1, 0.14), Pal.WARN, Pal.INFO, Pal.OK][lv]
		var x := (k - (ps.size() - 1) / 2.0) * 44.0
		var at := Vector2(x, 176)
		c.draw_circle(at, 17, Pal.OUTLINE, true, -1, true)
		c.draw_circle(at, 14, col, true, -1, true)
		if lv >= 3:
			c.draw_polyline(PackedVector2Array([at + Vector2(-7, 0), at + Vector2(-2, 6), at + Vector2(8, -6)]), Pal.INK, 4, true)
		else:
			Pal.text_c(c, Pal.UI_BOLD, at, str(HDLessons.index_of_part(id) + 1), 18, Pal.INK if lv > 0 else Pal.TEXT_DIM)
		k += 1
