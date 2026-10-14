extends Control
## Missiekaart (GDD §4.2): kurkbord met de kustkaart, acht dossiermappen verbonden met rode draad, de finale
## "Operatie Ekster" en het kaartje Nachtdienst. Een map opent een waaier levelkaartjes (0–3 sterren, pictogram);
## hover toont de leerstof. Toetsen: 1–8 = map, ←/→ = kaartje, Enter = start, Esc = terug.

const SPOTS := [Vector2(220, 190), Vector2(220, 420), Vector2(220, 650), Vector2(220, 880), Vector2(1700, 880),
	Vector2(1700, 650), Vector2(1700, 420), Vector2(1700, 190)]
const ICONS := ["sjabloon", "vingerafdruk", "doorloper", "springer", "lampenbord", "ruisbord", "schakelbord", "zoeklicht"]
const COLS := [Color("#E2C98E"), Color("#D9C089"), Color("#E6CC94"), Color("#DEC48C"), Color("#E2C98E"), Color("#D9C089"),
	Color("#E6CC94"), Color("#DEC48C")]
const MAP_R := Rect2(600, 250, 744, 471)
const NIGHT_R := Rect2(830, 70, 280, 140)
const FINAL_R := Rect2(810, 790, 300, 170)

var t := 0.0
var open_d := -1
var fan_u := 0.0
var hover_card := -1
var hover_folder := -1
var sel_card := 0
var stars := {}
var _cards: Array = []       # [{id, pos, ang, rect}]
var _starting := false


func _ready() -> void:
	theme = TxPal.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxSession.apply_all()
	stars = TxSession.stars()
	TxUi.overlay(self, 60)
	TxSnd.music("title")
	var back := TxUi.button("← Titel", "flat", 22, 160)
	back.position = Vector2(1740, 6)
	back.custom_minimum_size = Vector2(160, 46)
	back.pressed.connect(func(): Transition.goto(TxSession.SCENE_TITLE))
	add_child(back)
	var d0 := TxSession.from_map_dossier
	if d0 < 1:
		d0 = _current_dossier()
	_open(d0, false)


func _current_dossier() -> int:
	for id in TxLevels.ids():
		if id == "F":
			continue
		if TxLevels.priority_of(id) == "P2":
			continue
		if TxSession.unlocked(id) and int(stars.get(id, 0)) == 0:
			return TxLevels.dossier_of(id)
	return 8


func _dossier_open(d: int) -> bool:
	for id in TxLevels.ids_in_dossier(d):
		if TxSession.unlocked(id):
			return true
	return false


func _levels(d: int) -> PackedStringArray:
	var out := PackedStringArray()
	for id in TxLevels.ids_in_dossier(d):
		if TxLevels.priority_of(id) != "P2":
			out.append(id)
	return out


func _open(d: int, snd := true) -> void:
	if d == open_d:
		return
	open_d = d
	fan_u = 0.0
	sel_card = 0
	var lv := _levels(d)
	for i in lv.size():
		if TxSession.unlocked(lv[i]) and int(stars.get(lv[i], 0)) < 3:
			sel_card = i
			break
	create_tween().tween_property(self, "fan_u", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if snd:
		TxSnd.play("strip_slide", -6.0, 1.2)
	TxSession.from_map_dossier = d


func _start(id: String) -> void:
	if _starting:
		return
	if not TxSession.unlocked(id):
		TxSnd.play("bump", -6.0)
		TxFx.shake(2.0, 0.1)
		return
	_starting = true
	TxSnd.play("stamp", -2.0)
	TxSession.level_id = id
	Transition.goto(TxSession.SCENE_CONSOLE)


func _layout_cards() -> void:
	_cards = []
	if open_d < 1:
		return
	var lv := _levels(open_d)
	var n := lv.size()
	var left := open_d <= 4
	var base: Vector2 = SPOTS[open_d - 1] + Vector2(330 if left else -330, -10)
	base.y = clampf(base.y, 260, 820)
	for i in n:
		var k := i - (n - 1) / 2.0
		var pos: Vector2 = base + Vector2(k * 128 * fan_u, absf(k) * 16 * fan_u)
		_cards.append({"id": lv[i], "pos": pos, "ang": k * 0.13 * fan_u, "rect": Rect2(pos - Vector2(70, 100), Vector2(140, 200))})


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var p: Vector2 = e.position
		var hc := -1
		for i in range(_cards.size() - 1, -1, -1):
			if (_cards[i].rect as Rect2).has_point(p):
				hc = i
				break
		if hc != hover_card and hc >= 0:
			TxSnd.ui("hover")
		hover_card = hc
		hover_folder = -1
		for d in 8:
			if Rect2(SPOTS[d] - Vector2(150, 80), Vector2(300, 160)).has_point(p):
				hover_folder = d + 1
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p2: Vector2 = e.position
		for i in range(_cards.size() - 1, -1, -1):
			if (_cards[i].rect as Rect2).has_point(p2):
				_start(str(_cards[i].id))
				return
		for d in 8:
			if Rect2(SPOTS[d] - Vector2(150, 80), Vector2(300, 160)).has_point(p2):
				if _dossier_open(d + 1):
					_open(d + 1)
				else:
					TxSnd.play("bump", -8.0)
				return
		if FINAL_R.has_point(p2):
			_start("F")
		elif NIGHT_R.has_point(p2):
			if TxSession.unlocked("N"):
				_start_night()
			else:
				TxSnd.play("bump", -8.0)


func _start_night() -> void:
	TxSession.level_id = "N"
	Transition.goto(TxSession.SCENE_CONSOLE)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k: int = e.keycode
	if k == KEY_ESCAPE:
		Transition.goto(TxSession.SCENE_TITLE)
	elif k >= KEY_1 and k <= KEY_8:
		if _dossier_open(k - KEY_0):
			_open(k - KEY_0)
	elif k == KEY_LEFT:
		sel_card = maxi(0, sel_card - 1)
		TxSnd.ui("hover")
	elif k == KEY_RIGHT:
		sel_card = mini(_cards.size() - 1, sel_card + 1)
		TxSnd.ui("hover")
	elif k == KEY_UP and open_d > 1:
		if _dossier_open(open_d - 1):
			_open(open_d - 1)
	elif k == KEY_DOWN and open_d < 8:
		if _dossier_open(open_d + 1):
			_open(open_d + 1)
	elif (k == KEY_ENTER or k == KEY_KP_ENTER) and sel_card < _cards.size():
		_start(str(_cards[sel_card].id))
	elif k == KEY_F:
		_start("F")
	elif k == KEY_N and TxSession.unlocked("N"):
		_start_night()
	get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	t += dt
	_layout_cards()
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(TxPal.tex("bg/corkboard.jpg"), Rect2(0, 0, 1920, 1080), false)
	# kustkaart met de gevolgen van je diensten
	var mr := MAP_R
	draw_set_transform(mr.get_center(), -0.015, Vector2.ONE)
	var lr := Rect2(-mr.size / 2.0, mr.size)
	draw_rect(Rect2(lr.position + Vector2(6, 12), lr.size), TxPal.SHADOW)
	draw_texture_rect(TxPal.tex("bg/coast_map.jpg"), lr, false)
	for cpos in [lr.position + Vector2(-14, -8), Vector2(lr.end.x - 46, lr.position.y - 8)]:
		draw_rect(Rect2(cpos, Vector2(60, 22)), Color(0.95, 0.92, 0.8, 0.55))
	draw_set_transform(Vector2.ZERO)
	var kk := mr.size.x / 1200.0
	TxDraw.pin(self, mr.position + Vector2(634, 403) * kk, TxPal.BRASS, 1.2)
	var cities := [Vector2(124, 584), Vector2(219, 543), Vector2(342, 492), Vector2(454, 438), Vector2(695, 326),
		Vector2(802, 278), Vector2(908, 234), Vector2(1026, 176), Vector2(869, 462)]
	var di := 0
	for d in range(1, 9):
		var tot := 0
		for id in _levels(d):
			tot += int(stars.get(id, 0))
		if tot > 0:
			TxDraw.pin(self, mr.position + cities[di % cities.size()] * kk, Color("#3FA86B"), 1.0)
		di += 1
	var final_done := int(stars.get("F", 0)) > 0
	if final_done:
		TxDraw.magpie(self, mr.get_center() + Vector2(200, -120), 0.6)
	var walk := fmod(t * 0.06, 1.0)
	if not final_done:
		TxDraw.courier(self, (mr.position + Vector2(906, 230) * kk).lerp(mr.position + Vector2(1100, 120) * kk, walk) + Vector2(0, 30), 0.55, Color("#15181A"), t * 1.5)
	# rode draad + mappen
	for i in 7:
		TxDraw.thread(self, SPOTS[i] + Vector2(0, -66), SPOTS[i + 1] + Vector2(0, -66), 30)
	for i in 8:
		var d := i + 1
		var lv := _levels(d)
		var got := 0
		for id in lv:
			got += int(stars.get(id, 0))
		var state := "locked"
		if _dossier_open(d):
			state = "open"
			var all := true
			for id in lv:
				if TxLevels.priority_of(id) == "P0" and int(stars.get(id, 0)) < 1:
					all = false
			if all:
				state = "done"
		var rot: float = [-0.03, 0.02, -0.01, 0.025][i % 4]
		var lift := -6.0 if (hover_folder == d or open_d == d) else 0.0
		TxDraw.folder(self, Rect2(SPOTS[i] - Vector2(150, 80) + Vector2(0, lift), Vector2(300, 160)), str(d), TxLevels.DOSSIERS[d],
				"%d/%d" % [got, lv.size() * 3] if state != "locked" else "", state, rot, COLS[i])
		TxDraw.pin(self, SPOTS[i] + Vector2(0, -60 + lift), Color("#B3261E"), 1.0)
		if state != "locked":
			TxDraw.icon(self, ICONS[i], SPOTS[i] + Vector2(100, 40 + lift), 34, Color(TxPal.INK, 0.55))
		if open_d == d:
			draw_rect(Rect2(SPOTS[i] - Vector2(156, 86) + Vector2(0, lift), Vector2(312, 172)), Color(TxPal.SIG_AMBER, 0.5 + 0.3 * sin(t * 3.0)), false, 3.0)
	# finale
	var fin_open := TxSession.unlocked("F")
	TxDraw.folder(self, FINAL_R, "F", "Operatie Ekster", "%d/3" % int(stars.get("F", 0)) if fin_open else "", "final" if fin_open else "locked", 0.01)
	TxDraw.pin(self, FINAL_R.position + Vector2(150, 16), TxPal.BRASS, 1.0)
	TxDraw.ekster_seal(self, FINAL_R.end - Vector2(46, 46), 30)
	# nachtdienst
	var nr := NIGHT_R
	draw_set_transform(nr.get_center(), 0.02, Vector2.ONE)
	var nl := Rect2(-nr.size / 2.0, nr.size)
	draw_rect(Rect2(nl.position + Vector2(4, 8), nl.size), TxPal.SHADOW)
	draw_rect(nl, Color("#14191C"))
	draw_rect(nl.grow(-6), TxPal.BRASS_LO, false, 2.0)
	var nopen := TxSession.unlocked("N")
	TxPal.text_c(self, TxPal.STENCIL, Vector2(0, -34), "NACHTDIENST", 28, TxPal.BRASS_HI if nopen else TxPal.TEXT_DIM)
	TxPal.text_c(self, TxPal.UI, Vector2(0, 2), "eindeloze Springer-sprints" if nopen else "opent na 4-1  ★", 17, TxPal.TEXT_DIM)
	var hs := TxSave.highscores()
	TxPal.text_c(self, TxPal.MONO, Vector2(0, 36), ("TOP  %s  %d" % [str(hs[0].name), int(hs[0].score)]) if not hs.is_empty() else "TOP  ---  0", 20, TxPal.SIG_AMBER)
	draw_set_transform(Vector2.ZERO)
	TxDraw.pin(self, nr.position + Vector2(140, 16), TxPal.BRASS, 1.0)
	# waaier levelkaartjes
	for i in _cards.size():
		var c: Dictionary = _cards[i]
		var id := str(c.id)
		var spec := TxLevels.get_spec(id)
		var ttl := spec.title if spec != null else id
		ttl = TxChef._wrap(ttl.replace(": ", ":\n").replace(" — ", "\n"), 10)
		var hl := i == hover_card or i == sel_card
		var pos: Vector2 = c.pos + (Vector2(0, -18) if hl else Vector2.ZERO)
		TxDraw.level_card(self, pos, float(c.ang), id, ttl, int(stars.get(id, 0)), ICONS[clampi(open_d - 1, 0, 7)], not TxSession.unlocked(id), hl)
		if spec != null and spec.priority == "P1":
			TxPal.text_c(self, TxPal.MONO, pos + Vector2(0, 112), "extra", 13, TxPal.TEXT_DIM)
	# tooltip
	var ti := hover_card if hover_card >= 0 else sel_card
	if ti >= 0 and ti < _cards.size():
		var sp := TxLevels.get_spec(str(_cards[ti].id))
		if sp != null:
			var pos2: Vector2 = _cards[ti].pos + Vector2(-160, -200)
			var w := maxf(TxPal.text_w(TxPal.TAPE, sp.notes_ref, 18), TxPal.text_w(TxPal.TAPE_REG, sp.intro, 16)) + 30
			var tr := Rect2(pos2, Vector2(w, 70))
			tr.position.x = clampf(tr.position.x, 10, 1910 - w)
			draw_rect(Rect2(tr.position + Vector2(3, 6), tr.size), TxPal.SHADOW)
			draw_texture_rect(TxPal.tex("tex/paper_tile.png"), tr, true, Color(1.15, 1.13, 1.08))
			TxPal.text_l(self, TxPal.TAPE, tr.position + Vector2(14, 22), sp.notes_ref, 18, TxPal.INK)
			TxPal.text_l(self, TxPal.TAPE_REG, tr.position + Vector2(14, 48), sp.intro, 16, TxPal.INK_SOFT)
	# kopbalk
	TxDraw.hud_bar(self, 1920, 56)
	TxPal.text_l(self, TxPal.STENCIL, Vector2(24, 28), "STATION ZOEKLICHT", 24, TxPal.BRASS)
	TxPal.text_l(self, TxPal.UI_BOLD, Vector2(290, 28), "Missiekaart", 24, TxPal.TEXT)
	TxPal.text_l(self, TxPal.UI, Vector2(470, 28), "1–8 dossier · ← → kaartje · Enter start · F finale · N nachtdienst · Esc terug", 18, TxPal.TEXT_DIM)
	var tot2 := 0
	for k in stars:
		tot2 += int(stars[k])
	TxDraw.star(self, Vector2(1590, 28), 12, TxPal.BRASS, TxPal.BRASS_HI)
	TxPal.text_l(self, TxPal.MONO, Vector2(1610, 28), "%d / %d" % [tot2, 3 * (TxLevels.ids().size() - 1)], 22, TxPal.TEXT)
