extends Control
## Seizoenkaart (GDD §4.2): een jaarwiel met vier kwadranten (Lente, Zomer, Herfst, Winter). Elk level is een
## plantpot langs een spiraalpad; in het midden de finale "De eeuwige slinger"; de bijenkorf rechtsonder is de
## vrije tuin. Een pot toont 0–3 sterren en het pictogram van zijn mechaniek; hover = leerstofreferentie.
## Volgend level open met ≥ 1 ster; een seizoen opent als het vorige seizoen (P0) volledig ≥ 1 ster heeft.

const C := Vector2(900, 560)
const R := 420.0

var t := 0.0
var ids: PackedStringArray
var specs := {}
var stars := {}
var pots := {}            # id -> Vector2
var hover := ""
var focus := ""
var _grow := {}           # id -> 0..1 (nieuwe ster-animatie)
var _wheel_a := 0.0
var _hive := Vector2(1700, 880)
var _back: Button
var _sheet: Control
var _key_sel := -1
var _backdrop: TtBackdrop


func _ready() -> void:
	theme = TtUi.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop = TtBackdrop.new(0, false, -10)
	_backdrop.dim = 0.25
	add_child(_backdrop)
	ids = TtLevels.ids()
	for id in ids:
		specs[id] = TtLevels.get_spec(id)
	stars = TtSave.all_stars()
	_place_pots()
	_back = TtUi.button("← Titel", TtUi.Kind.GHOST, 24, 170)
	_back.position = Vector2(30, 24)
	_back.pressed.connect(func(): Transition.goto(TtSession.SCENE_TITLE))
	add_child(_back)
	var notes := TtUi.button("Notas", TtUi.Kind.SAP, 24, 150)
	notes.position = Vector2(30, 96)
	notes.pressed.connect(_open_sheet)
	add_child(notes)
	create_tween().tween_property(self, "_wheel_a", 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	TtSnd.season_music(-1)
	focus = TtSession.map_focus
	TtSession.map_focus = ""
	if focus != "":
		var before := int(TtSession.map_stars_before.get(focus, 0))
		if int(stars.get(focus, 0)) > before:
			_grow[focus] = 0.0
			var tw := create_tween()
			tw.tween_interval(0.6)
			tw.tween_method(func(v: float): _grow[focus] = v, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func():
				TtSnd.play("star_3", -4.0)
				TtFx.found(self, pots[focus]))
	if TtSession.has("season"):
		_backdrop.set_season(clampi(int(TtSession.arg("season")), 0, 3), true)


func _place_pots() -> void:
	var by_season := {}
	for id in ids:
		var s := TtSession.season_of(id)
		if not by_season.has(s):
			by_season[s] = []
		by_season[s].append(id)
	# kwadrant per seizoen: lente linksboven, zomer rechtsboven, herfst rechtsonder, winter linksonder
	var arcs := {0: [PI * 1.03, PI * 1.47], 1: [PI * 1.53, PI * 1.97], 2: [PI * 0.03, PI * 0.47], 3: [PI * 0.53, PI * 0.97]}
	for s in by_season:
		var list: Array = by_season[s]
		if s == 4:
			for i in list.size():
				var a := -PI / 2 + (i - (list.size() - 1) / 2.0) * 0.9
				pots[list[i]] = C + Vector2(cos(a), sin(a) + 0.3) * 92.0
			continue
		var a0: float = arcs[s][0]
		var a1: float = arcs[s][1]
		for i in list.size():
			var u := (i + 0.5) / list.size()
			var a := lerpf(a0, a1, u)
			var rr := (R - 110.0) if i % 2 == 0 else (R - 215.0)
			pots[list[i]] = C + Vector2(cos(a), sin(a)) * rr + Vector2(0, -10)


func is_open(id: String) -> bool:
	if TtSession.has("unlock"):
		return true
	return TtLevels.is_unlocked(id, stars, ids)


func endless_open() -> bool:
	return TtSession.has("unlock") or TtLevels.is_unlocked("vrij", stars, ids)


func _process(delta: float) -> void:
	t += delta
	TtSession.qa_tick(self, delta)
	var h := _pot_at(get_local_mouse_position())
	if h != hover and h != "":
		TtSnd.play("letter_tick", -14.0, 1.5)
	hover = h
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		# QA: bepaal de pot uit de klikpositie zelf (touch/pen of klik zonder voorafgaande muisbeweging)
		var h := _pot_at(ev.position)
		if h != "":
			hover = h
		if hover != "":
			_open(hover)


func _pot_at(m: Vector2) -> String:
	var h := ""
	for id in pots:
		if (pots[id] as Vector2).distance_to(m) < 52:
			h = id
	if _hive.distance_to(m) < 70:
		h = "endless"
	return h


func _open(id: String) -> void:
	if id == "endless":
		if endless_open():
			TtSession.level_id = "endless"
			Transition.goto(TtSession.SCENE_GARDEN)
		else:
			TtSnd.play("clonk", -6.0)
		return
	if not is_open(id):
		TtSnd.play("clonk", -6.0)
		Juice.shake(2.0, 0.1)
		return
	TtSnd.play("bud_plop", -2.0)
	TtSession.level_id = id
	TtSession.from_map = true
	Transition.goto(TtSession.SCENE_GARDEN)


func _unhandled_input(ev: InputEvent) -> void:
	if _sheet:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_ESCAPE:
			Transition.goto(TtSession.SCENE_TITLE)
		elif k == KEY_RIGHT or k == KEY_DOWN or k == KEY_TAB:
			_key_sel = (_key_sel + 1) % ids.size()
			hover = ids[_key_sel]
		elif k == KEY_LEFT or k == KEY_UP:
			_key_sel = (_key_sel - 1 + ids.size()) % ids.size()
			hover = ids[_key_sel]
		elif (k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE) and hover != "":
			_open(hover)


func _open_sheet() -> void:
	if _sheet:
		return
	var max_s := 0
	for id in ids:
		if is_open(id):
			max_s = maxi(max_s, TtSession.season_of(id))
	var cs := TtCheatSheet.new()
	cs.setup(max_s)
	_sheet = cs
	add_child(cs)
	cs.closed.connect(func(): _sheet = null)


func _draw() -> void:
	var a := _wheel_a
	draw_set_transform(C, sin(t * 0.2) * 0.004, Vector2(a, a))
	# kwadranten
	var quad_a := [[PI, PI * 1.5], [PI * 1.5, TAU], [0.0, PI * 0.5], [PI * 0.5, PI]]
	for s in 4:
		var se := TtPal.season(s)
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 33:
			var ang := lerpf(quad_a[s][0], quad_a[s][1], k / 32.0)
			pts.append(Vector2(cos(ang), sin(ang)) * R)
		var top: Color = se.sky_top
		draw_colored_polygon(pts, Color(top.lerp(se.ground, 0.35), 0.92))
		var mid: float = (quad_a[s][0] + quad_a[s][1]) / 2.0
		var lp := Vector2(cos(mid), sin(mid)) * (R + 78)
		TtPal.text_outline_c(self, TtPal.UI_BOLD, lp, str(se.name).to_upper(), 34, Color.WHITE, 8, TtPal.OUTLINE)
		TtPal.text_outline_c(self, TtPal.UI, lp + Vector2(0, 34), str(se.topic), 20, TtPal.TEXT, 6, TtPal.OUTLINE)
		for k in 7:
			var ang2 := lerpf(quad_a[s][0], quad_a[s][1], (k + 0.5) / 7.0)
			var lc: Color = se.leaf[k % 3]
			TtDraw.leaf(self, Vector2(cos(ang2), sin(ang2)) * (R - 6), ang2 + PI * 0.5 + sin(t + k) * 0.1, 26, lc, false)
	draw_arc(Vector2.ZERO, R, 0, TAU, 96, Color(TtPal.BARK_DARK, 0.9), 10.0, true)
	draw_arc(Vector2.ZERO, R, 0, TAU, 96, TtPal.BARK, 6.0, true)
	for s in 4:
		draw_line(Vector2.ZERO, Vector2(cos(s * PI / 2), sin(s * PI / 2)) * R, Color(TtPal.BARK_DARK, 0.5), 4.0, true)
	# spiraalpad
	var sp := PackedVector2Array()
	for k in 241:
		var u := k / 240.0
		var ang3 := PI + u * TAU * 1.0
		var rr := lerpf(R - 60, 120, u)
		sp.append(Vector2(cos(ang3), sin(ang3)) * rr)
	draw_polyline(sp, Color(TtPal.PAPER, 0.35), 14.0, true)
	draw_polyline(sp, Color(TtPal.PAPER_EDGE, 0.5), 4.0, true)
	# finale
	draw_circle(Vector2.ZERO, 150, Color(TtPal.PANEL, 0.88), true, -1, true)
	draw_arc(Vector2.ZERO, 150, 0, TAU, 64, Color("#FFE680", 0.6 + 0.2 * sin(t * 2.0)), 4.0, true)
	TtPal.text_c(self, TtPal.UI_BOLD, Vector2(0, -118), "FINALE", 22, Color("#FFE680"))
	TtPal.text_c(self, TtPal.UI, Vector2(0, 112), "De eeuwige slinger", 20, TtPal.TEXT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for id in pots:
		_draw_pot(id, pots[id])
	_draw_hive()
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(220, 46), "Seizoenkaart", 40, TtPal.TEXT)
	if hover != "":
		_draw_tip(hover)


func _draw_pot(id: String, p: Vector2) -> void:
	var open := is_open(id)
	var n := int(stars.get(id, 0))
	var hov := hover == id
	var s := (1.1 if hov else 1.0) * _wheel_a
	var se := TtPal.season(mini(TtSession.season_of(id), 3))
	if _grow.has(id):
		s *= lerpf(0.8, 1.0, _grow[id])
	draw_set_transform(p, 0.0, Vector2(s, s) * 0.85)
	TtDraw.pot(self, Vector2.ZERO, id, n, se, not open, t, hov)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hive() -> void:
	var p := _hive
	var open := endless_open()
	var hov := hover == "endless"
	var s := 1.08 if hov else 1.0
	draw_set_transform(p + Vector2(0, 60), 0.0, Vector2(s, s))
	if not open:
		modulate_hive_locked()
	TtDraw.hive(self, Vector2.ZERO, 1.0, t, false, false, 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	TtPal.text_outline_c(self, TtPal.UI_BOLD, p + Vector2(0, 104), "Vrije tuin" if open else "Vrije tuin (na 1-4)", 24, TtPal.TEXT, 6, TtPal.OUTLINE)
	if open:
		var hs: Array = TtSave.highscores()
		if not hs.is_empty():
			TtPal.text_outline_c(self, TtPal.UI, p + Vector2(0, 132), "record %d" % int(hs[0].get("score", 0)), 20, TtPal.STAR, 6, TtPal.OUTLINE)
		for k in 3:
			var ang := t * (1.2 + k * 0.3) + k * 2.0
			TtDraw.bee(self, p + Vector2(cos(ang) * 90, -40 + sin(ang * 2.0) * 30), 0.45, t + k, signf(-sin(ang)) if absf(sin(ang)) > 0.05 else 1.0)


func modulate_hive_locked() -> void:
	draw_circle(Vector2(0, -50), 80, Color(0.2, 0.2, 0.2, 0.25), true, -1, true)


func _draw_tip(id: String) -> void:
	var p: Vector2 = _hive if id == "endless" else pots[id]
	var lines := []
	if id == "endless":
		lines = ["Vrije tuin · Bijenkoorts", "gewone trie, realtime, highscore"]
	else:
		var sp: TtLevelSpec = specs[id]
		lines = ["%s · %s" % [id, sp.title], sp.notes_ref]
		if not is_open(id):
			lines.append("nog dicht: haal ★ op het vorige level")
		elif sp.priority != "P0":
			lines.append("extra level")
	var w := 0.0
	for l in lines:
		w = maxf(w, TtPal.UI_BOLD.get_string_size(str(l), HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x)
	var r := Rect2(p.x + 60, p.y - 70, w + 40, 30 + lines.size() * 34)
	if r.end.x > 1900:
		r.position.x = p.x - 60 - r.size.x
	draw_style_box(TtUi.paper_box(16), r)
	for i in lines.size():
		TtPal.text_l(self, TtPal.UI_BOLD if i == 0 else TtPal.UI, r.position + Vector2(20, 30 + i * 34), str(lines[i]), 24 if i == 0 else 20, TtPal.INK if i == 0 else TtPal.INK_SOFT)
