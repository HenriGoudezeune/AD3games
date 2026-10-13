class_name TtCheatSheet
extends Control
## Notas-spiekbriefje (GDD §4.2): notitieboekje met een tab per structuur (open zodra het seizoen open is),
## per tab een minidiagram en ≤ 5 regels met paginaverwijzing. Esc/klik buiten = sluiten.

signal closed

const SIZE := Vector2(1240, 760)
const TABS := [
	{"name": "Trie", "season": 0, "ref": "notas p. 25–28 · §3.1", "lines": [
		"Op diepte d lees je letter s_d en ga je naar knop k_{s_d}.",
		"Lege knop? Opzoeken: niet gevonden. Toevoegen: hang de vrucht.",
		"Vrucht bereikt? Vergelijk het hele woord (label = s?).",
		"j = min{i ≥ d | l_i ≠ s_i}; pad tot j; vruchten aan k_{l_j} en k_{s_j}.",
		"Verwijderen: knip onder de laatste top met ≥ 2 kinderen."]},
	{"name": "Patricia", "season": 1, "ref": "notas p. 28–30 · Algoritme 1", "lines": [
		"skip k: sla k letters over, lees positie next + k.",
		"next + skip > m → te kort (niet gevonden).",
		"Pas in de vrucht vergelijken: overgeslagen letters kunnen verschillen!",
		"Enten: reconstrueer met een vrucht onder de top, zoek j, ent op diepte j.",
		"Snoeien: elke top met één kind verdwijnt; skip van het kind += skip + 1."]},
	{"name": "Ternary", "season": 2, "ref": "notas p. 30–32 · §3.1.2", "lines": [
		"Letter < bol → kleiner (links); = → gelijk (volgende top); > → groter (rechts).",
		"Enkel gebruikte letters krijgen een bol: 3 pointers per bol.",
		"Loont bij een groot alfabet (ASCII), niet bij {A,C,G,T,_} met veel kinderen.",
		"Volgorde-afspraak van deze game: _ achteraan; bij een split eerst l_j, dan s_j planten.",
		"Gebalanceerde rankknoop = kortere bijenvluchten."]},
	{"name": "Suffixboom", "season": 3, "ref": "notas p. 32–34, 48–49", "lines": [
		"Alle suffixen van t_ in één Patricia-achtige trie; geen top met 1 kind.",
		"Boog (b,e) = de parels b..e van de slinger (Θ(n) geheugen).",
		"Nieuwe boog vanuit diepte l voor suffix j: b = j + l.",
		"Positie van een voorkomen = b − l_t (top t op diepte l_t).",
		"Aantal voorkomens = aantal vruchten onder het punt."]},
	{"name": "Ukkonen", "season": 4, "ref": "notas p. 34–48 · §3.2.1", "lines": [
		"Bladeren groeien vanzelf mee (eind = it): eens blad, altijd blad.",
		"Zit het teken er al? Stop de iteratie, x̄ := x + 1.",
		"Op een top → nieuw blad (ii); midden in een boog → splits (iii).",
		"p = wortel → x − 1; anders volg de suffix link (x blijft).",
		"x̄ ≥ booglengte → spring naar de top en x̄ −= lengte."]},
]

var tab := 0
var max_season := 0
var t := 0.0
var _rect := Rect2()


func setup(open_upto_season: int, start_tab := -1) -> void:
	max_season = open_upto_season
	tab = clampi(start_tab if start_tab >= 0 else mini(open_upto_season, 4), 0, 4)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rect = Rect2(Vector2(960, 540) - SIZE / 2.0, SIZE)
	TtSnd.play("ribbon_roll", -4.0)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = ev.position
		for i in TABS.size():
			if _tab_rect(i).has_point(p):
				if TABS[i].season <= max_season:
					tab = i
					TtSnd.play("ribbon_roll", -8.0, 1.3)
				else:
					TtSnd.play("clonk", -8.0)
				return
		if not _rect.has_point(p):
			_close()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_close()
		elif k == KEY_RIGHT or k == KEY_TAB:
			tab = (tab + 1) % TABS.size()
			if TABS[tab].season > max_season:
				tab = 0
			get_viewport().set_input_as_handled()
		elif k == KEY_LEFT:
			tab = (tab - 1 + TABS.size()) % TABS.size()
			while TABS[tab].season > max_season:
				tab -= 1
			get_viewport().set_input_as_handled()


func _close() -> void:
	closed.emit()
	queue_free()


func _tab_rect(i: int) -> Rect2:
	return Rect2(_rect.position.x + 40 + i * 200, _rect.position.y - 52, 190, 60)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.03, 0.06, 0.04, 0.6))
	for i in TABS.size():
		var tr := _tab_rect(i)
		var open: bool = TABS[i].season <= max_season
		var col := TtPal.PAPER if i == tab else (TtPal.PAPER_EDGE if open else Color(TtPal.PANEL_LO, 0.9))
		draw_style_box(TtPal.sb(col, 16), tr)
		TtPal.text_c(self, TtPal.UI_BOLD, tr.get_center() + Vector2(0, -6), TABS[i].name if open else "· · ·", 24, TtPal.INK if open else TtPal.TEXT_DIM)
	draw_style_box(TtUi.paper_box(), _rect)
	# spiraal
	for k in 12:
		var c := Vector2(_rect.position.x + 6, _rect.position.y + 60 + k * 58)
		draw_circle(c, 9, TtPal.PANEL_LO, true, -1, true)
		draw_arc(c + Vector2(-10, 0), 12, -PI * 0.5, PI * 0.5, 10, Color("#9AA3A0"), 3.0, true)
	var tb: Dictionary = TABS[tab]
	TtPal.text_l(self, TtPal.UI_BOLD, _rect.position + Vector2(60, 60), "Notas · " + str(tb.name), 40, TtPal.INK)
	TtPal.text_r(self, TtPal.UI, Vector2(_rect.end.x - 40, _rect.position.y + 62), str(tb.ref), 22, TtPal.INK_SOFT)
	var y := _rect.position.y + 150
	for line in tb.lines:
		draw_circle(Vector2(_rect.position.x + 70, y), 6, TtPal.BRAND_DARK, true, -1, true)
		TtPal.text_l(self, TtPal.UI_MED, Vector2(_rect.position.x + 90, y), str(line), 26, TtPal.INK)
		y += 64
	_diagram(Rect2(_rect.position.x + 60, _rect.end.y - 250, _rect.size.x - 120, 210))
	TtPal.text_c(self, TtPal.UI, Vector2(960, _rect.end.y + 34), "Esc of klik ernaast = sluiten · ←/→ = andere tab", 20, TtPal.TEXT)


func _diagram(r: Rect2) -> void:
	draw_style_box(TtPal.sb(Color(TtPal.PAPER_EDGE, 0.35), 18), r)
	var se := TtPal.season(mini(tab, 3))
	var c := r.get_center()
	match tab:
		0:
			var tops := TtDraw.knot(self, c + Vector2(-200, 50), "ACGT_", [true, false, false, true, false], 40.0, 0, t)
			var e := TtDraw.branch_curve(tops[0], c + Vector2(-330, -40), Vector2.UP, 0.0, 16, true)
			TtDraw.branch(self, e, 12, 8, se, 1, t, 1)
			TtDraw.letter_tag(self, TtDraw.path_point(e, 0.35), "A", 22)
			TtDraw.fruit(self, c + Vector2(-330, -40), se, "", t, 0, 18)
			var e2 := TtDraw.branch_curve(tops[3], c + Vector2(-60, -50), Vector2.UP, 0.0, 16, true)
			TtDraw.branch(self, e2, 12, 8, se, 2, t, 1)
			TtDraw.letter_tag(self, TtDraw.path_point(e2, 0.35), "T", 22)
			TtDraw.fruit(self, c + Vector2(-60, -50), se, "", t, 0, 18)
			TtDraw.knot(self, c + Vector2(-200, 50), "ACGT_", [true, false, false, true, false], 40.0, 0, t)
			TtPal.text_l(self, TtPal.UI_BOLD, c + Vector2(80, -30), "knop = pointer k_a", 24, TtPal.INK)
			TtPal.text_l(self, TtPal.UI, c + Vector2(80, 10), "lege knop = NULL (kost ook sap)", 22, TtPal.INK_SOFT)
		1:
			TtDraw.knot(self, c + Vector2(-260, 30), "ACGT_", [false, true, true, false, false], 40.0, -1, t)
			var r2 := Rect2(c.x - 140, c.y + 8, 110, 44)
			draw_style_box(TtPal.sb_thick(TtPal.RAFFIA, 14, 4, TtPal.RAFFIA_DARK), r2)
			TtPal.text_c(self, TtPal.MONO, r2.get_center(), "skip 2", 22, TtPal.INK)
			TtPal.word(self, c + Vector2(200, -40), "CGCCTT_", 30, true, "ACGT_", 3, 3, TtPal.INFO, 1, 2)
			TtPal.text_c(self, TtPal.UI, c + Vector2(200, 10), "next = 1, skip 2 → lees positie 3", 22, TtPal.INK)
		2:
			var anc := TtDraw.rank_knot(self, c + Vector2(-120, 40), "G", t, [true, true, true], 30.0, "ACGT_", 1)
			TtDraw.tendril(self, anc[0], c + Vector2(-260, 0), TtPal.LESS, t)
			TtDraw.tendril(self, anc[2], c + Vector2(20, 0), TtPal.GREATER, t)
			TtDraw.rank_knot(self, c + Vector2(-280, -10), "C", t, [false, true, false], 24.0, "ACGT_")
			TtDraw.rank_knot(self, c + Vector2(40, -10), "T", t, [false, true, false], 24.0, "ACGT_")
			TtPal.text_l(self, TtPal.UI_BOLD, c + Vector2(160, -20), "< kleiner · = gelijk · > groter", 24, TtPal.INK)
		3:
			TtDraw.garland(self, Vector2(r.position.x + 80, r.position.y + 40), "acacacgt_", 62.0, se, t, 2, 3, 8.0, "acgt_", true)
			TtPal.text_l(self, TtPal.UI_BOLD, Vector2(r.position.x + 700, r.position.y + 70), "(2,3) = parels 2..3 = ac", 24, TtPal.INK)
			TtPal.text_l(self, TtPal.UI, Vector2(r.position.x + 700, r.position.y + 110), "positie = b − l_t", 24, TtPal.INK_SOFT)
		4:
			var ff := c + Vector2(-200, 0)
			for k in 4:
				draw_circle(ff, 34.0 - k * 7.0, Color(1.0, 0.95, 0.55, 0.08 + 0.05 * k), true, -1, true)
			draw_circle(ff, 10, Color("#FFD23F"), true, -1, true)
			var rb := Rect2(ff + Vector2(20, -44), Vector2(80, 30))
			draw_style_box(TtPal.sb_thick(TtPal.STAR, 10, 3, TtPal.STAR_DARK), rb)
			TtPal.text_c(self, TtPal.MONO, rb.get_center(), "x̄ = 1", 20, TtPal.INK)
			TtPal.text_l(self, TtPal.UI_BOLD, c + Vector2(-40, -20), "(p̄, x̄) = actief punt", 24, TtPal.INK)
			TtPal.text_l(self, TtPal.UI, c + Vector2(-40, 20), "suffix link: top u → u zonder eerste letter", 22, TtPal.INK_SOFT)
