class_name ScCheatSheet
extends Control
## Notas-spiekbriefje (GDD §4.2): een wastafeltje met een tabblad per werktuig dat al binnen is. Per tab een
## mini-diagram en ≤ 5 regels met paginaverwijzing. ←/→ wisselt van tab, Esc sluit.

signal closed

const TABS := [
	{"tool": "prefix_read", "name": "Codeboom", "ch": 0, "lines": [
		["prefixcode: geen codewoord is het begin van een ander", "Def. 20, p. 83"],
		["lees tot een blad, begin opnieuw bij de wortel", "p. 83"],
		["links = 0, rechts = 1", "Fig. 24/25"],
		["geen prefixcode? Dan weet de lezer niet waar een letter stopt", "p. 82"]]},
	{"tool": "bindery", "name": "Binderij", "ch": 1, "lines": [
		["bind de twee lichtste; gewicht = som", "Alg. 9, p. 84"],
		["bij gelijk gewicht: elke keuze is even goed", "p. 84–85"],
		["touw = Σ l(x)·a(x) = bits", "Stelling 21, p. 86"],
		["twee planken: neem vooraan het lichtste", "Oef. 85"]]},
	{"tool": "living_tree", "name": "Levende boom", "ch": 2, "lines": [
		["eerst schrijven met de oude boom, dan bijwerken", "p. 92"],
		["nieuw teken: code(nng) + 8 bits", "p. 94"],
		["t′ = zelfde gewicht, hoogste nummer; is t′ je ouder: niet wisselen", "Alg. 11, p. 95"],
		["(a) som (b) gewicht stijgt met het nummer (c) 2j−1 en 2j zijn broers", "Lemma 22, p. 90"]]},
	{"tool": "ruler", "name": "Meetlat", "ch": 3, "lines": [
		["links += f·lengte; lengte ×= p", "Alg. 12, p. 101"],
		["[a, b): onder dicht, boven open", "p. 99"],
		["naald: stap als getal + next < up; stop als getal ≥ low", "Alg. 13, p. 101–102"],
		["low = 0 → schrijf 0", "Alg. 13, p. 102"],
		["⌈log₂(1/lengte)⌉ bits volstaan", "Lemma 24, p. 102"]]},
	{"tool": "window", "name": "Leesraam", "ch": 4, "lines": [
		["langste match die in het raam begint; mag erbuiten eindigen", "p. 105"],
		["(p, l, x); p vanaf links, vanaf 0", "p. 106"],
		["geen match: (0, 0, x)", "p. 106"],
		["decoderen: letter per letter kopiëren", "p. 107"],
		["met een deelstringboom: O(1) per teken", "§4.3.1, p. 110"]]},
	{"tool": "stampcase", "name": "Stempelkast", "ch": 5, "lines": [
		["wk in de kast: verlengen; anders code(w) stempelen, wk snijden, w = k", "p. 111"],
		["nieuwe codes vanaf 256; a = 97", "p. 110–111"],
		["decoderen: nieuwe stempel = w + eerste letter van het volgende woord", "p. 113"],
		["code bestaat nog niet: volgend = w + w[0]", "p. 113"],
		["volle kast: opnieuw beginnen (niet gespeeld)", "p. 112"]]},
	{"tool": "drum", "name": "Draaitrommel", "ch": 6, "lines": [
		["alle rotaties, sorteer, laatste kolom", "p. 116–117"],
		["p = de rij van rotatie 1 (eindigt op het eerste teken)", "p. 117"],
		["k-de x in de eerste kolom = k-de x in de laatste kolom", "p. 118"],
		["terug: n keer: schrijf, zoek dezelfde in c, ga naar e", "p. 118–119"],
		["de spatie is kleiner dan alle letters", "p. 116"]]},
	{"tool": "shelf", "name": "Letterplank", "ch": 6, "lines": [
		["schrijf de positie (vanaf 0), zet de letter vooraan", "p. 121"],
		["decoderen: zelfde beginlijst, positie → teken, vooraan", "p. 121"],
		["veel nullen en kleine getallen: goed voor Huffman", "p. 122"]]},
	{"tool": "dovecote", "name": "Duiventil", "ch": 0, "lines": [
		["minder bits = minder hokken", "p. 81"],
		["wie iets korter maakt, maakt iets anders langer", "Oef. 76"],
		["Σ_{i≤n} 256^i = (256^{n+1} − 1)/255 kortere bestanden", "Oef. 77"]]},
]

var _level := ""
var _tabs: Array = []
var _cur := 0
var t := 0.0
var _n: Node2D
var _tab_rects: Array = []


func setup(level_id: String, tool_name: String) -> void:
	_level = level_id
	var ch := 7
	if level_id != "nachtwake" and ScLevels.has(level_id):
		ch = ScLevels.chapter_of(level_id)
	elif level_id == "nachtwake":
		ch = 1
	var stars := ScSave.all_stars()
	var max_ch := ch
	for id in stars:
		if int(stars[id]) > 0 and ScLevels.has(str(id)):
			max_ch = maxi(max_ch, ScLevels.chapter_of(str(id)))
	for tb in TABS:
		if int(tb.ch) <= max_ch:
			_tabs.append(tb)
			if tb.tool == tool_name:
				_cur = _tabs.size() - 1
	if _tabs.is_empty():
		_tabs.append(TABS[0])


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.015, 0.01, 0.55)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_n = Node2D.new()
	ScDraw.prepare(_n)
	_n.draw.connect(_paint)
	add_child(_n)
	var b := ScUi.button("Sluiten", ScUi.Kind.PRIMARY, 26, 220)
	b.position = Vector2(1460, 900)
	b.pressed.connect(_close)
	add_child(b)
	ScSnd.play("page_turn", -8.0)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _process(delta: float) -> void:
	t += delta
	_n.queue_redraw()


func _close() -> void:
	closed.emit()
	queue_free()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in _tab_rects.size():
			if (_tab_rects[i] as Rect2).has_point(ev.position):
				_cur = i
				ScSnd.play("page_turn", -10.0)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_ESCAPE:
				_close()
			KEY_LEFT:
				_cur = (_cur - 1 + _tabs.size()) % _tabs.size()
			KEY_RIGHT:
				_cur = (_cur + 1) % _tabs.size()
			_:
				return
		get_viewport().set_input_as_handled()


func _paint() -> void:
	var c := _n
	var r := Rect2(220, 140, 1480, 820)
	ScDraw.wood(c, r, ScPal.OAK_DARK, 22, true, 8)
	var wax := r.grow(-34)
	wax.position.y += 60
	wax.size.y -= 60
	c.draw_style_box(ScPal.sb(Color("#5A3F22"), 12), wax)
	c.draw_style_box(ScPal.sb(Color("#6E4E2C"), 10), wax.grow(-6))
	_tab_rects = []
	var x := r.position.x + 40
	for i in _tabs.size():
		var tb: Dictionary = _tabs[i]
		var w := ScPal.text_w(ScPal.UI_BOLD, tb.name, 22) + 64
		var tr := Rect2(x, r.position.y + 26, w, 54)
		_tab_rects.append(tr)
		c.draw_style_box(ScPal.sb(ScPal.VELLUM_HI if i == _cur else ScPal.VELLUM_EDGE, 10), tr)
		ScDraw.tool_icon(c, tr.position + Vector2(24, 27), 10, ScSession.tool_icon(tb.tool), ScPal.INK)
		ScPal.text_l(c, ScPal.UI_BOLD, tr.position + Vector2(42, 27), tb.name, 22, ScPal.INK)
		x += w + 10
	var tb2: Dictionary = _tabs[_cur]
	ScPal.text_l(c, ScPal.TITLE, wax.position + Vector2(40, 52), ScSession.tool_title(tb2.tool), 46, ScPal.GOLD_LIGHT)
	var y := wax.position.y + 130
	for ln in tb2.lines:
		c.draw_circle(Vector2(wax.position.x + 48, y), 5, ScPal.GOLD)
		ScPal.text_l(c, ScPal.UI_MED, Vector2(wax.position.x + 66, y), ln[0], 26, ScPal.VELLUM_HI)
		ScPal.text_l(c, ScPal.UI, Vector2(wax.position.x + 66, y + 32), ln[1], 20, ScPal.GOLD_LIGHT)
		y += 84
	_diagram(c, tb2.tool, Rect2(wax.end.x - 470, wax.position.y + 120, 430, 520))


func _diagram(c: CanvasItem, tl: String, r: Rect2) -> void:
	ScDraw.parchment(c, r, 9, ScPal.VELLUM, true, 0.5)
	var m := r.get_center()
	match tl:
		"prefix_read":
			var top := m + Vector2(0, -170)
			var a := top + Vector2(-100, 100)
			var b := top + Vector2(100, 100)
			ScDrawTools.branch(c, top, a, "0", false, 6, t)
			ScDrawTools.branch(c, top, b, "1", false, 6, t)
			ScDrawTools.branch(c, a, a + Vector2(-60, 100), "0", false, 5, t)
			ScDrawTools.branch(c, a, a + Vector2(60, 100), "1", false, 5, t)
			ScDrawTools.knob(c, top, 12)
			ScDrawTools.knob(c, a, 12)
			ScDrawTools.leaf_tile(c, a + Vector2(-60, 100), "o", 24, "", false, "00", t)
			ScDrawTools.leaf_tile(c, a + Vector2(60, 100), "u", 24, "", false, "01", t)
			ScDrawTools.leaf_tile(c, b, "f", 24, "", false, "1", t)
		"bindery":
			ScDrawTools.pile(c, m + Vector2(-110, 140), "b", 1, "bs", false, t)
			ScDrawTools.pile(c, m + Vector2(0, 140), "s", 1, "bs", false, t)
			ScDrawTools.pile(c, m + Vector2(110, 140), "", 2, "", false, t, true)
			ScPal.text_c(c, ScPal.MONO_B, m + Vector2(0, -150), "1 + 1 = 2", 30, ScPal.INK)
		"living_tree":
			ScDraw.monk(c, m + Vector2(-80, 40), 1.0, t, ScPal.HABITS[0], "[2,6]", false, true)
			ScDraw.monk(c, m + Vector2(90, 40), 1.0, t, ScPal.HABITS[1], "[2,7]", true)
			ScDrawTools.seed_nng(c, m + Vector2(0, 170), 1.1, t)
		"ruler":
			var segs := [{"sym": "x", "lo": 0.0, "hi": 0.2}, {"sym": "y", "lo": 0.2, "hi": 0.9}, {"sym": "z", "lo": 0.9, "hi": 1.0}]
			ScDrawTools.ruler(c, Rect2(m.x - 50, r.position.y + 40, 100, r.size.y - 80), segs, "y", -1.0, t, ["0", "0,2", "0,9"])
		"window":
			ScDrawTools.reading_window(c, Vector2(r.position.x + 30, m.y), "banaan", 0, 5, 56, 36, 1, true, t, 5)
			ScDraw.triple_seal(c, m + Vector2(0, 130), 1, 1, "a", 24)
		"stampcase":
			ScDrawTools.zetstok(c, m + Vector2(-150, -120), "an", "a", true, 34, t)
			ScDrawTools.drawer(c, Rect2(m.x - 80, m.y + 20, 160, 74), "ana", "260", 0.0, false, false, true, t)
		"drum":
			ScDrawTools.drum(c, m + Vector2(-110, 0), 70, 180, "geen loon", t * 0.6, t, 26)
			ScPal.text_c(c, ScPal.MONO_B, m + Vector2(90, -40), "p = 1", 30, ScPal.INK)
			ScPal.text_c(c, ScPal.MONO_B, m + Vector2(90, 20), "ngen␣eool", 26, ScPal.INK)
		"shelf":
			ScDrawTools.shelf(c, Vector2(r.position.x + 30, m.y), [" ", "1", "a", "b", "e"], 64, true, 2, t)
		"dovecote":
			ScDrawTools.dovecote(c, m + Vector2(0, 60), 0.5, {"0": true, "1": true}, t)
