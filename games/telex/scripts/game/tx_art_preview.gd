extends Node2D
## TELEX — art preview (design/ART.md). Toont alle visuele elementen op zeven pagina's, opgebouwd in code.
## Argumenten na `--`: `page=0..6` (zonder: wisselt elke 6 s). Toetsen: Tab / → volgende, ← vorige, 0–6 direct.
##   0 Console (Doorloper, live) · 1 Vingerafdruk + Springer + Ponsbank · 2 Lampenbord + Ruisbord
##   3 Schakelbord + Zoeklicht · 4 Missiekaart · 5 Debrief, UI, personages, palet · 6 Titel

const P := preload("res://games/telex/scripts/game/tx_pal.gd")
const D := preload("res://games/telex/scripts/game/tx_draw.gd")
const M := preload("res://games/telex/scripts/game/tx_draw_machines.gd")
const PAGES := 7
const W := 1920.0
const H := 1080.0

var page := 0
var auto := true
var t := 0.0
var _overlay: ColorRect
var _ui: Control


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("page="):
			page = clampi(int(a.substr(5)), 0, PAGES - 1)
			auto = false
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.size = Vector2(W, H)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://games/telex/assets/art/shaders/tx_overlay.gdshader")
	mat.set_shader_parameter("grain_tex", P.tex("tex/grain.png"))
	_overlay.material = mat
	layer.add_child(_overlay)
	var uil := CanvasLayer.new()
	uil.layer = 4
	add_child(uil)
	_ui = Control.new()
	_ui.size = Vector2(W, H)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = P.theme()
	uil.add_child(_ui)
	_build_ui()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		auto = false
		if e.keycode == KEY_TAB or e.keycode == KEY_RIGHT:
			page = (page + 1) % PAGES
		elif e.keycode == KEY_LEFT:
			page = (page + PAGES - 1) % PAGES
		elif e.keycode >= KEY_0 and e.keycode <= KEY_6:
			page = e.keycode - KEY_0
		elif e.keycode == KEY_ESCAPE:
			get_tree().quit()
		_build_ui()


func _process(delta: float) -> void:
	t += delta
	if auto and t > 6.0 * (page + 1):
		page = (page + 1) % PAGES
		_build_ui()
	queue_redraw()


## Echte Control-knoppen (TxPal.button) per pagina, zodat de thema-stijl zichtbaar is.
func _build_ui() -> void:
	for c in _ui.get_children():
		c.queue_free()
	match page:
		5:
			var col := VBoxContainer.new()
			col.position = Vector2(1442, 640)
			col.add_theme_constant_override("separation", 12)
			_ui.add_child(col)
			col.add_child(P.button("Volgende dienst", "brass", 24, 412))
			col.add_child(P.button("Opnieuw", "key", 24, 412))
			col.add_child(P.button("Missiekaart", "key", 24, 412))
			col.add_child(P.button("Codewoord melden", "red", 24, 412))
		6:
			var col := VBoxContainer.new()
			col.position = Vector2(760, 650)
			col.add_theme_constant_override("separation", 16)
			_ui.add_child(col)
			col.add_child(P.button("Diensten", "brass", 32, 400))
			col.add_child(P.button("Nachtdienst", "key", 32, 400))
			col.add_child(P.button("Instellingen", "key", 32, 400))
			col.add_child(P.button("Terug naar de speelhal", "flat", 26, 400))


func _draw() -> void:
	match page:
		0: _page_console()
		1: _page_machines_a()
		2: _page_machines_b()
		3: _page_board()
		4: _page_map()
		5: _page_debrief()
		6: _page_title()
	P.text_r(self, P.MONO, Vector2(W - 16, H - 14), "art preview %d/%d  ·  Tab = volgende" % [page, PAGES - 1], 14, Color(P.TEXT_DIM, 0.6))


func _bg() -> void:
	draw_texture_rect(P.tex("bg/bunker_wall.jpg"), Rect2(0, 0, W, H), false)


# ================================================================ 0 CONSOLE (Doorloper, LIVE)
func _page_console() -> void:
	_bg()
	var tt := "barbaarse_barbecue_in_barbados"
	var z := "barbados"
	var cell := P.TAPE_CELL
	var x0 := 168.0
	var count := 35
	# console-achterplaat onder lint/sjabloon
	P.panel(self, Rect2(8, 70, W - 16, 312), P.CONSOLE, true, 12)
	P.well(self, Rect2(150, 86, W - 300, 282), P.CONSOLE_LO, 8)
	# HUD
	D.hud_bar(self, W, 60)
	D.keycap(self, Vector2(14, 13), "II", 18)
	P.text_l(self, P.STENCIL, Vector2(70, 30), "DOSSIER 3", 22, P.BRASS)
	P.text_l(self, P.UI_BOLD, Vector2(198, 30), "3-1  Barbados", 26, P.TEXT)
	P.text_l(self, P.UI, Vector2(400, 30), "z =", 22, P.TEXT_DIM)
	D.word_chip(self, Vector2(440, 12), z, 24)
	P.text_l(self, P.UI, Vector2(592, 30), "eerste voorkomen", 20, P.TEXT_DIM)
	P.text_l(self, P.UI_BOLD, Vector2(800, 30), "LIVE", 18, P.SIG_AMBER)
	P.lamp(self, Vector2(866, 30), 7, P.SIG_AMBER, 0.5 + 0.5 * sin(t * 6.0))
	var tick_v := 6.0 + clampf(fmod(t, 3.0) - 2.0, 0.0, 1.0)
	D.counter(self, Vector2(1090, 6), tick_v, 4, "TIKKEN", 24, 36)
	D.ghost_bar(self, Rect2(1236, 15, 230, 30), tick_v, 42)
	D.trust(self, Vector2(1520, 30), 3)
	D.stars(self, Vector2(1640, 30), 1, 26)
	D.keycap(self, Vector2(1752, 13), "F1", 18)
	P.text_l(self, P.UI, Vector2(1800, 30), "hint", 20, P.TEXT_DIM)
	# lint + versnipperaar + inlaat
	var shred_spin := t * 3.0
	D.shredder(self, x0 - 2, P.Y_TAPE, shred_spin, 0.0, 0.35)
	var states := {0: "eq", 1: "eq", 2: "eq", 3: "eq", 4: "eq", 5: "ne"}
	var front := 24 + int(fmod(t * 2.0, 6.0))
	D.tape(self, x0, P.Y_TAPE, tt, 0, count, cell, {"states": states, "front": front})
	D.inlet(self, x0 + count * cell + 4, P.Y_TAPE, clampf(sin(t * 12.0), 0.0, 1.0), -t * 2.0)
	D.tape_positions(self, x0, P.Y_POS, 0, count, cell, tt.length(), 5)
	# leeskop blijft op t[5] (KMP) en gloeit warm
	var strike := clampf(1.0 - fmod(t * 1.5, 1.0) * 4.0, 0.0, 1.0)
	D.head(self, x0 + 5.5 * cell, P.Y_TAPE, strike, "ne", 0.35 + 0.25 * sin(t * 3.0))
	# sjabloon in voorvertoning s = 3: tanden 0,1 haken in op "ba"
	var start := 3
	var sx := x0 + start * cell
	D.stencil(self, x0, P.Y_STENCIL, z, cell, {}, -1, true)
	D.stencil(self, sx, P.Y_STENCIL, z, cell, {0: "mesh", 1: "mesh"}, 2)
	D.strip(self, sx, P.Y_STRIP, [1, 1, 2, 3, 3, 3, 6, 7, 8], cell, true, 5)
	P.text_l(self, P.UI_BOLD, Vector2(sx + 8 * cell + 80, P.Y_STENCIL + 40), "s = 3  ✓ past", 24, P.SIG_EQ)
	# machinepaneel
	P.panel(self, Rect2(8, 392, W - 16, 466), P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(220, 432), "MODEL  K-M-P  1977", 22, P.STENCIL, fmod(t * 0.35, 1.0))
	P.text_l(self, P.STENCIL, Vector2(40, 480), "DOORLOPER", 30, P.TEXT)
	P.text_l(self, P.UI, Vector2(40, 518), "verschuiving kiezen: ← → , vastzetten: Enter", 20, P.TEXT_DIM)
	for i in 6:
		var kr := Rect2(40 + i * 66, 556, 58, 58)
		var on := i == 2
		P.box(self, Rect2(kr.position + Vector2(0, 5), kr.size), P.BAKELITE_LO, 8)
		P.box(self, kr, P.BRASS if on else P.BAKELITE_HI, 8)
		P.text_c(self, P.MONO, kr.get_center(), str(i + 1), 28, P.TEXT_ON_BRASS if on else P.TEXT)
	P.text_l(self, P.UI, Vector2(40, 650), "tanden:", 20, P.TEXT_DIM)
	P.lamp(self, Vector2(140, 650), 9, P.SIG_EQ, 1.0, "ok")
	P.text_l(self, P.UI, Vector2(158, 650), "haken in", 20, P.TEXT)
	P.lamp(self, Vector2(270, 650), 9, P.SIG_NE, 1.0, "ne")
	P.text_l(self, P.UI, Vector2(288, 650), "botsen (klem)", 20, P.TEXT)
	D.keycap(self, Vector2(40, 700), "←", 20)
	D.keycap(self, Vector2(80, 700), "→", 20)
	D.keycap(self, Vector2(120, 700), "Enter", 20)
	D.keycap(self, Vector2(206, 700), "V", 20)
	P.text_l(self, P.UI, Vector2(250, 716), "= strook gebruiken", 20, P.TEXT_DIM)
	D.loop_bin(self, Rect2(560, 420, 420, 260), 9, 5.0 + 3.0 * absf(sin(t * 0.5)), clampf(sin(t * 0.5) * 2.0 - 1.0, 0.0, 1.0))
	P.text_l(self, P.UI, Vector2(574, 704), "lint loopt binnen aan v = 1,5 teken/s · B = 9", 18, P.TEXT_DIM)
	# Chef + ballon
	D.chef(self, Vector2(1150, 560), 0.95, absf(sin(t * 9.0)) * 0.6, 1.0 if fmod(t, 3.7) < 0.12 else 0.0)
	D.balloon(self, Rect2(1260, 440, 360, 120), "Na een mismatch op 5\npast al 3 plaatsen.", Vector2(1225, 520))
	D.tube(self, Rect2(1680, 410, 210, 430), fmod(t * 0.4, 1.0))
	# onderbalk
	P.panel(self, Rect2(8, 868, W - 16, 204), P.CONSOLE_HI, true, 12)
	D.dossier_card(self, Rect2(30, 884, 380, 176), "OPDRACHT  3-1", [["z =", "barbados"], ["modus:", "eerste voorkomen"], ["lint:", "30 tekens"]], "notas p. 58 · Definitie 11")
	P.text_l(self, P.STENCIL, Vector2(452, 900), "GEVONDEN", 20, P.TEXT_DIM)
	D.capsule(self, Vector2(580, 956), 0.0, "barbados @22", 1.0)
	P.text_c(self, P.UI, Vector2(580, 1010), "volgende koker: nog leeg", 18, P.TEXT_DIM)
	var bx := 760.0
	for b in [["Vastzetten", "Enter", true], ["Strook", "V", false], ["Terugnemen", "Ctrl+Z", false]]:
		var br := Rect2(bx, 920, 230, 64)
		P.box(self, Rect2(br.position + Vector2(0, 6), br.size), P.BRASS_LO if b[2] else P.BAKELITE_LO, 10)
		P.box(self, br, P.BRASS if b[2] else P.BAKELITE, 10, 0, 2, P.BRASS_LO)
		P.text_c(self, P.UI_BOLD, br.get_center() + Vector2(0, -6), b[0], 26, P.TEXT_ON_BRASS if b[2] else P.TEXT)
		P.text_c(self, P.MONO, br.get_center() + Vector2(0, 20), b[1], 13, Color(P.TEXT_ON_BRASS if b[2] else P.TEXT_DIM, 0.8))
		bx += 250
	D.mini_map(self, Rect2(1540, 884, 340, 172), [[Vector2(634, 365), P.BRASS], [Vector2(900, 230), P.SIG_NE]])


func _page_machines_a() -> void:
	_bg()
	# ---- links: Vingerafdruk (Rabin-Karp), level 2-2 bij venster i = 5
	var L := Rect2(14, 14, 940, 690)
	P.panel(self, L, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(170, 52), "MODEL  R-K · q", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(320, 52), "VINGERAFDRUK", 28, P.TEXT)
	var tb := "1010010110110100"
	var x0 := 60.0
	D.tape(self, x0, 96, tb, 0, 16, 44.0, {"frame": [5, 8], "states": {}})
	D.tape_positions(self, x0, 204, 0, 16, 44.0, 16, 8)
	var wob := 4.0 + 0.06 * sin(t * 18.0) * exp(-fmod(t, 3.0) * 2.0)
	M.wheel(self, Vector2(250, 470), 150, 7, wob, 4, 0.5 + 0.5 * sin(t * TAU * 1.5))
	M.minus_w_gear(self, Vector2(66, 628), 2, t * 0.5, 0.0)
	P.text_c(self, P.UI, Vector2(66, 684), "gewicht w", 16, P.TEXT_DIM)
	M.wheel_levers(self, Vector2(492, 262), {"×2": 0.0, "−w": 0.0, "+1": clampf(sin(t * 2.0), 0.0, 1.0)})
	M.bit_window(self, Vector2(440, 560), "1011", "0", "1", clampf(fmod(t, 2.0), 0.0, 1.0))
	D.counter(self, Vector2(784, 104), 31, 3, "", 24, 34)
	P.text_c(self, P.STENCIL, Vector2(840, 162), "WIELSLAGEN", 13, P.BRASS)
	P.text_l(self, P.UI_BOLD, Vector2(784, 192), "h(z) = 4", 20, P.STAMP_RED.lightened(0.35))
	P.text_l(self, P.UI, Vector2(784, 218), "q = 7 · w = 2", 18, P.TEXT_DIM)
	M.alarm_panel(self, Vector2(L.end.x - 186, 262), 0.5 + 0.5 * signf(sin(t * TAU * 3.0)), true)
	# ---- rechts: Springer (BMH), level 4-1 bij i = 20
	var Rr := Rect2(966, 14, 940, 690)
	P.panel(self, Rr, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(1130, 52), "MODEL  B-M-H  1980", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(1300, 52), "SPRINGER", 28, P.TEXT)
	var tt := "barbados_zoekt_barbara"
	var c2 := 38.0
	var x1 := 1010.0
	D.tape(self, x1, 96, tt, 0, 22, c2, {"states": {20: "ne"}, "key": 20, "size": 36})
	D.tape_positions(self, x1, 204, 0, 22, c2, 22, 20)
	D.head(self, x1 + 20.5 * c2, 96, 1.0, "ne")
	var j := clampf(fmod(t * 0.5, 1.0) * 1.6 - 0.3, 0.0, 1.0)
	var sx := x1 + lerpf(14.0, 15.0, j) * c2
	D.stencil(self, sx, 238, "barbara", c2, {}, 6, false, 36, {6: "ne"})
	M.jump_arc(self, sx + 6.5 * c2, sx + 7.5 * c2, 240, 1.0, "", 22)
	P.text_r(self, P.UI_BOLD, Vector2(sx - 24, 280), "kaart r: spring V_H[r] = 1", 22, P.SIG_AMBER)
	P.text_l(self, P.UI, Vector2(1010, 676), "← naald van rechts naar links · sleutelteken = t[i] onder de laatste letter", 19, P.TEXT_DIM)
	M.card_box(self, Rect2(1040, 420, 560, 230), [["a", 2], ["b", 3], ["r", 1], ["overige", 7]], 2, 0.55 + 0.25 * sin(t * 2.0))
	M.index_card(self, Rect2(1660, 430, 96, 96), "a", 2, 5, 1.0)
	P.text_c(self, P.UI, Vector2(1708, 548), "stempel: overschrijven", 16, P.TEXT_DIM)
	D.keycap(self, Vector2(1650, 590), "K", 16)
	P.text_l(self, P.UI, Vector2(1690, 604), "= sleutelteken", 18, P.TEXT_DIM)
	# ---- onder: Ponsbank (Algoritme 5, spiegelrit) voor barbados, start = 3
	var B := Rect2(14, 718, 1892, 348)
	P.panel(self, B, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(190, 756), "MODEL  K-M-P  1977", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(360, 756), "PONSBANK  ·  SPIEGELRIT", 26, P.TEXT)
	var x2 := 300.0
	D.tape(self, x2, 776, "barbados⏎", 0, 9, 44.0, {"states": {3: "eq", 4: "eq", 5: "ne"}})
	D.stencil(self, x2 + 3 * 44.0, 898, "barbados", 44.0, {}, 2, false, 44, {0: "eq", 1: "eq", 2: "ne"})
	P.text_r(self, P.UI, Vector2(x2 - 20, 830), "z als tekst", 18, P.TEXT_DIM)
	P.text_r(self, P.UI, Vector2(x2 + 3 * 44.0 - 24, 938), "spiegel, start 3", 18, P.TEXT_DIM)
	var hit := clampf(1.0 - fmod(t, 1.6) * 3.0, 0.0, 1.0)
	M.punch_head(self, x2, 1016, 44.0, 4, 5, 3, hit)
	D.strip(self, x2, 1016, [1, 1, 2, 3, null, null, null, null], 44.0, false, -1)
	P.text_r(self, P.UI, Vector2(x2 - 60, 1039), "ponsstrook", 18, P.TEXT_DIM)
	P.knob(self, Vector2(1000, 900), 40, -PI / 2 + 0.5, "waarde = start = 3")
	P.text_l(self, P.UI, Vector2(1100, 860), "Algoritme 5: pons tot en met de mismatch", 20, P.TEXT_DIM)
	P.text_l(self, P.TAPE, Vector2(1100, 900), "em = 2  →  V[4..5] = 3", 30, P.TEXT)
	P.text_l(self, P.UI, Vector2(1100, 944), "daarna verschuiven met V[em] = V[2] = 2", 20, P.TEXT_DIM)
	for i in 4:
		D.keycap(self, Vector2(1100 + i * 60, 990), ["←", "→", "↑", "P"][i], 18)
	P.text_l(self, P.UI, Vector2(1350, 1004), "vakje b · waarde · ponsen", 18, P.TEXT_DIM)


func _page_machines_b() -> void:
	_bg()
	# ---- links: Lampenbord (shift-AND), level 5-1 "ana" in "ananas", j = 2
	var L := Rect2(14, 14, 940, 1052)
	P.panel(self, L, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(150, 52), "MODEL  B-Y/G", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(290, 52), "LAMPENBORD", 28, P.TEXT)
	D.tape(self, 60, 96, "ananas", 0, 6, 44.0, {"states": {0: "eq", 1: "eq", 2: "eq"}})
	D.tape_positions(self, 60, 204, 0, 6, 44.0, 6, 2)
	var bell := clampf(1.0 - fmod(t, 2.0) * 1.2, 0.0, 1.0)
	M.lamp_column(self, 200, 320, "ana", "101", 70, P.SIG_EQ, 0.0, bell)
	M.bell(self, Vector2(200, 540), 20, bell)
	M.lever(self, 300, 300, 200, clampf(sin(t * 1.5) * 1.5, 0.0, 1.0))
	M.punch_card(self, 470, 330, "a", "101", 70, true)
	M.punch_card(self, 560, 330, "n", "010", 70, false)
	M.punch_card(self, 650, 330, "blanco", "000", 70, false)
	P.text_c(self, P.UI, Vector2(560, 560), "ponskaarten C_x  (a steekt in het rek)", 17, P.TEXT_DIM)
	M.matrix_log(self, Rect2(40, 610, 440, 300), "ananas", "ana", ["100", "010", "101"], 2, [[2, P.STAMP_RED]])
	P.text_l(self, P.UI, Vector2(500, 640), "bel: \"ana\" eindigt op j = 2", 22, P.SIG_EQ)
	P.text_l(self, P.UI, Vector2(500, 676), "kolom = SHIFT(kolom) & C[t[j]]", 20, P.TEXT_DIM)
	D.keycap(self, Vector2(500, 720), "S", 16)
	P.text_l(self, P.UI, Vector2(536, 734), "hendel", 18, P.TEXT_DIM)
	D.keycap(self, Vector2(620, 720), "a", 16)
	P.text_l(self, P.UI, Vector2(656, 734), "kaart insteken", 18, P.TEXT_DIM)
	D.keycap(self, Vector2(500, 770), "Spatie", 16)
	P.text_l(self, P.UI, Vector2(584, 784), "blanco", 18, P.TEXT_DIM)
	P.text_l(self, P.STENCIL, Vector2(60, 950), "VOORBEREIDING", 18, P.TEXT_DIM)
	M.punch_card(self, 300, 950, "n", "0" + ("1" if fmod(t, 2.0) > 1.0 else "0") + "0", 22, false, 1, 50)
	P.text_l(self, P.UI, Vector2(360, 950), "kaart n ponsen: gat waar z[i] = n  (Tab · ↑↓ · Spatie)", 18, P.TEXT_DIM)
	# ---- rechts: Ruisbord (k = 1), level 6-1 "dank" in "een_dansfeest", j = 7
	var Rr := Rect2(966, 14, 940, 1052)
	P.panel(self, Rr, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(1130, 52), "MODEL  W-M  1992", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(1290, 52), "RUISBORD", 28, P.TEXT)
	D.tape(self, 1000, 96, "een_dansfeest", 0, 13, 44.0, {"states": {4: "eq", 5: "eq", 6: "eq", 7: "ne"}})
	D.tape_positions(self, 1000, 204, 0, 13, 44.0, 13, 7)
	var b1 := clampf(1.0 - fmod(t + 0.7, 2.0) * 1.2, 0.0, 1.0)
	M.lamp_column(self, 1130, 330, "dank", "0000", 62, P.LEVEL_COLORS[0], 0.0, 0.0, true)
	M.sup_label(self, Vector2(1130, 284), "M", "0", 26, P.LEVEL_COLORS[0])
	M.lamp_column(self, 1530, 330, "dank", "1001", 62, P.LEVEL_COLORS[1], 0.0, b1, false)
	M.sup_label(self, Vector2(1530, 284), "M", "1", 26, P.LEVEL_COLORS[1])
	M.bell(self, Vector2(1130, 600), 18, 0.0, P.BRASS)
	M.bell(self, Vector2(1530, 600), 15, b1, P.BRASS)
	var socks: Array = M.sockets(self, Vector2(1220, 300), 0)
	M.or_gate(self, Vector2(1440, 360), 1.0, true)
	P.text_c(self, P.UI, Vector2(1440, 400), "voeding", 14, P.TEXT_DIM)
	M.cable(self, socks[0], Vector2(1416, 352), 70, Color("#B23A2A"), sin(t * 2.0) * 0.4)
	draw_line(Vector2(1466, 360), Vector2(1484, 360), P.SIG_AMBER, 3.0)
	P.text_l(self, P.UI, Vector2(1000, 660), "foutkabel in  oud ↓  = vorige kolom van M0, geschoven", 20, P.TEXT_DIM)
	P.text_l(self, P.UI, Vector2(1000, 692), "bel M1: \"dans\" eindigt op 7 met ≤ 1 fout", 22, P.LEVEL_COLORS[1])
	var m0 := ["0000", "0000", "0000", "0000", "1000", "0100", "0010", "0000"]
	var m1 := ["1000", "1000", "1000", "1000", "1000", "1100", "1010", "1001"]
	M.matrix_log(self, Rect2(990, 730, 440, 320), "een_dans", "dank", m0, 7, [], "M^0")
	M.matrix_log(self, Rect2(1450, 730, 440, 320), "een_dans", "dank", m1, 7, [[7, P.STAMP_RED]], "M^1")


func _page_board() -> void:
	_bg()
	# ---- links: Schakelbord (Algoritme 7), lessen → feesten, d = 3, pad = lijn van p. 76
	var L := Rect2(14, 14, 860, 1052)
	P.panel(self, L, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(120, 52), "MODEL  L", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(230, 52), "SCHAKELBORD", 28, P.TEXT)
	var d := [[0, 1, 2, 3, 4, 5, 6, 7], [1, 1, 2, 3, 4, 5, 6, 7], [2, 2, 1, 2, 3, 4, 5, 6], [3, 3, 2, 2, 2, 3, 4, 5],
		[4, 4, 3, 3, 2, 3, 4, 5], [5, 5, 4, 3, 3, 3, 3, 4], [6, 6, 5, 4, 4, 4, 4, 3]]
	var dirs := [["", "", "", "", "", "", "", ""], ["", "d", "d", "d", "d", "d", "d", "d"], ["", "d", "d", "d", "l", "l", "d", "l"],
		["", "d", "u", "d", "d", "l", "l", "l"], ["", "d", "u", "d", "d", "l", "d", "d"], ["", "d", "d", "d", "u", "d", "d", "l"],
		["", "d", "u", "u", "d", "d", "d", "d"]]
	var path := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3), Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7)]
	var shown := int(clampf(fmod(t * 3.0, 12.0), 0.0, 8.0))
	M.relay_grid(self, Vector2(200, 230), "lessen", "feesten", d, dirs, 72.0, path.slice(path.size() - shown), {}, Vector2i(-1, -1), false, 0.5 + 0.5 * sin(t * 4.0))
	M.repair_strip(self, Vector2(200, 820), "feesten", {0: "sub", 2: "sub", 4: "ins"}, 44.0, "HERSTELSTROOK")
	P.text_l(self, P.TAPE, Vector2(200, 930), "vervang l op 0 door f · vervang s op 2 door e · voeg t toe op 4", 17, P.TEXT)
	P.text_l(self, P.UI, Vector2(200, 966), "d = 3: de stroom neemt de kortste weg (lijn van p. 76)", 19, P.TEXT_DIM)
	# legende
	var lg := Vector2(40, 1010)
	P.text_l(self, P.UI, lg, "↖ ↑ ← = ingang kiezen (Q / W / A)", 18, P.TEXT_DIM)
	# ---- rechts: Zoeklicht (Algoritme 8), examen in de_armen_vouwen
	var Rr := Rect2(886, 14, 1020, 1052)
	P.panel(self, Rr, P.CONSOLE, true, 12)
	P.brass_plate(self, Vector2(990, 52), "MODEL  L-8", 20, P.STENCIL)
	P.text_l(self, P.STENCIL, Vector2(1090, 52), "ZOEKLICHT", 28, P.TEXT)
	var tt := "de_armen_vouwen"
	D.tape(self, 1200, 92, tt, 0, 15, 44.0, {"spot": [1, 7], "states": {}})
	var d2 := [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
		[2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 1, 1], [3, 3, 2, 2, 1, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2],
		[4, 4, 3, 3, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 3, 3], [5, 5, 4, 4, 3, 3, 3, 2, 3, 4, 4, 4, 5, 5, 4, 4],
		[6, 6, 5, 5, 4, 4, 4, 3, 2, 3, 4, 5, 5, 6, 5, 4]]
	var dirs2 := [[], ["", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d", "d"],
		["", "d", "u", "d", "d", "d", "d", "u", "d", "d", "d", "d", "d", "d", "u", "d"],
		["", "d", "u", "d", "d", "l", "d", "u", "d", "d", "d", "d", "d", "d", "u", "d"],
		["", "d", "u", "d", "u", "d", "d", "u", "d", "d", "d", "d", "d", "d", "u", "d"],
		["", "d", "d", "d", "u", "d", "d", "d", "l", "d", "d", "d", "d", "d", "d", "d"],
		["", "d", "u", "d", "u", "d", "d", "u", "d", "l", "l", "d", "d", "d", "u", "d"]]
	var p2 := [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 6), Vector2i(5, 7), Vector2i(6, 8)]
	var g := M.relay_grid(self, Vector2(1156, 320), "examen", tt, d2, dirs2, 44.0, p2, {}, Vector2i(6, 8), true, 0.5)
	var aim := Vector2(1156 + 8.5 * 44.0, 320 + 6.5 * 44.0)
	M.searchlight(self, Vector2(1040, 760), aim, 1.0, sin(t * 1.2) * 0.03)
	P.text_l(self, P.UI_BOLD, Vector2(1156, 700), "minimum onderaan: 2 in kolom 8", 22, P.SIG_AMBER)
	P.text_l(self, P.UI, Vector2(1156, 732), "teruglopen tot de rail: begin in kolom 1 → match t[1..7] = e_armen", 19, P.TEXT_DIM)
	P.text_l(self, P.UI, Vector2(1156, 760), "bovenrij = stroomrail op 0: de stroom mag overal instappen", 19, P.TEXT_DIM)
	# legende relais
	var lx := 940.0
	var ly := 850.0
	P.text_l(self, P.STENCIL, Vector2(lx, ly), "RELAIS", 18, P.TEXT_DIM)
	var leg := [["gewoon", {}, Vector2i(-1, -1), []], ["op het pad", {}, Vector2i(-1, -1), [Vector2i(1, 1)]],
		["warm (te hoog)", {Vector2i(1, 1): true}, Vector2i(-1, -1), []], ["cursor", {}, Vector2i(1, 1), []]]
	for k in leg.size():
		var o := Vector2(lx + 90 + k * 230, ly + 70)
		M.relay_grid(self, o, "a", "b", [[null, null], [null, 2 if k != 2 else 3]], [[], ["", "d"]], 52.0, leg[k][3], leg[k][1], leg[k][2])
		P.text_c(self, P.UI, o + Vector2(78, 122), leg[k][0], 16, P.TEXT_DIM)


func _page_map() -> void:
	draw_texture_rect(P.tex("bg/corkboard.jpg"), Rect2(0, 0, W, H), false)
	# kustkaart, vastgeprikt met plakband
	var mr := Rect2(600, 236, 744, 471)
	draw_set_transform(mr.get_center(), -0.015, Vector2.ONE)
	var lr := Rect2(-mr.size / 2.0, mr.size)
	draw_rect(Rect2(lr.position + Vector2(6, 12), lr.size), P.SHADOW)
	draw_texture_rect(P.tex("bg/coast_map.jpg"), lr, false)
	for cpos in [lr.position + Vector2(-14, -8), Vector2(lr.end.x - 46, lr.position.y - 8)]:
		draw_rect(Rect2(cpos, Vector2(60, 22)), Color(0.95, 0.92, 0.8, 0.55))
	draw_set_transform(Vector2.ZERO)
	var k := mr.size.x / 1200.0
	var mp := func(px: float, py: float) -> Vector2: return mr.position + Vector2(px, py) * k
	D.pin(self, mp.call(632, 370), P.BRASS, 1.2)
	D.pin(self, mp.call(906, 230), P.SIG_NE, 1.1)
	D.pin(self, mp.call(240, 520), P.SIG_NE, 1.1)
	D.pin(self, mp.call(1050, 160), P.SIG_GREY, 1.1)
	D.pin(self, mp.call(470, 430), Color("#3FA86B"), 1.1)
	var walk := fmod(t * 0.08, 1.0)
	D.courier(self, mp.call(906, 230).lerp(mp.call(1100, 120), walk) + Vector2(0, 30), 0.6, Color("#15181A"), t * 1.5)
	D.car(self, mp.call(640, 400).lerp(mp.call(1040, 175), clampf(fmod(t * 0.12, 1.0) * 1.2, 0.0, 1.0)), 0.8, 0.5 + 0.5 * sin(t * 10.0))
	# dossiermappen + rode draad (route 1 → 8)
	var spots := [Vector2(220, 170), Vector2(220, 400), Vector2(220, 630), Vector2(220, 860), Vector2(1700, 860),
		Vector2(1700, 630), Vector2(1700, 400), Vector2(1700, 170)]
	var titles := ["Het lint", "Vingerafdrukken", "De Doorloper", "De Springer", "Het lampenbord", "Ruis op de lijn", "Het schakelbord", "Het zoeklicht"]
	var st := ["done", "done", "open", "open", "locked", "locked", "locked", "locked"]
	var stx := ["6/6", "8/9", "4/12", "", "", "", "", ""]
	for i in 7:
		D.thread(self, spots[i] + Vector2(0, -66), spots[i + 1] + Vector2(0, -66), 30)
	for i in 8:
		D.folder(self, Rect2(spots[i] - Vector2(150, 80), Vector2(300, 160)), str(i + 1), titles[i], stx[i], st[i], [-0.03, 0.02, -0.01, 0.025][i % 4])
		D.pin(self, spots[i] + Vector2(0, -60), Color("#B3261E"), 1.0)
	# finale + nachtdienst
	D.folder(self, Rect2(820, 760, 300, 170), "F", "Operatie Ekster", "", "final", 0.01)
	D.pin(self, Vector2(970, 776), P.BRASS, 1.0)
	var nr := Rect2(830, 60, 280, 140)
	draw_set_transform(nr.get_center(), 0.02, Vector2.ONE)
	var nl := Rect2(-nr.size / 2.0, nr.size)
	draw_rect(Rect2(nl.position + Vector2(4, 8), nl.size), P.SHADOW)
	draw_rect(nl, Color("#14191C"))
	draw_rect(nl.grow(-6), P.BRASS_LO, false, 2.0)
	P.text_c(self, P.STENCIL, Vector2(0, -34), "NACHTDIENST", 28, P.BRASS_HI)
	P.text_c(self, P.UI, Vector2(0, 2), "eindeloze Springer-sprints", 17, P.TEXT_DIM)
	P.text_c(self, P.MONO, Vector2(0, 36), "TOP  HDG  4 120", 20, P.SIG_AMBER)
	draw_set_transform(Vector2.ZERO)
	D.pin(self, Vector2(970, 76), P.BRASS, 1.0)
	# waaier met levelkaartjes van dossier 3 (open)
	var base := Vector2(560, 620)
	var cards := [["3-1", "Barbados", 3, "doorloper"], ["3-2", "De spiegel\nOef. 40", 1, "doorloper"], ["3-3", "Spiegelrit\nOef. 39", 0, "doorloper"],
		["3-4", "Alle\nvoorkomens", 0, "doorloper"], ["3-5", "Nachtstroom", 0, "doorloper"]]
	for i in cards.size():
		var ang := (i - 2) * 0.16
		var c := base + Vector2((i - 2) * 120, absf(i - 2) * 18)
		D.level_card(self, c, ang, cards[i][0], cards[i][1], cards[i][2], cards[i][3], i >= 3, i == 2)
	# tooltip (hover op 3-3)
	var tr := Rect2(600, 360, 300, 70)
	draw_rect(Rect2(tr.position + Vector2(3, 6), tr.size), P.SHADOW)
	draw_texture_rect(P.tex("tex/paper_tile.png"), tr, true, Color(1.15, 1.13, 1.08))
	P.text_l(self, P.TAPE, tr.position + Vector2(14, 22), "Oefening 39 · notas p. 62", 18, P.INK)
	P.text_l(self, P.TAPE_REG, tr.position + Vector2(14, 48), "Algoritme 5: V[] zelf berekenen", 16, P.INK_SOFT)
	# kopbalk
	D.hud_bar(self, W, 56)
	P.text_l(self, P.STENCIL, Vector2(24, 28), "STATION ZOEKLICHT", 24, P.BRASS)
	P.text_l(self, P.UI_BOLD, Vector2(290, 28), "Missiekaart", 24, P.TEXT)
	D.star(self, Vector2(1720, 28), 12, P.BRASS, P.BRASS_HI)
	P.text_l(self, P.MONO, Vector2(1740, 28), "18 / 81", 22, P.TEXT)


func _page_debrief() -> void:
	_bg()
	# ---- debriefmap (links)
	var dr := Rect2(40, 40, 900, 1000)
	draw_rect(Rect2(dr.position + Vector2(8, 14), dr.size), P.SHADOW)
	draw_texture_rect(P.tex("tex/paper_tile.png"), dr, true, Color(P.MANILA.r * 1.22, P.MANILA.g * 1.22, P.MANILA.b * 1.2))
	draw_rect(Rect2(dr.position, Vector2(dr.size.x, 70)), Color(P.MANILA_LO, 0.5))
	P.text_l(self, P.STENCIL, dr.position + Vector2(30, 36), "DEBRIEF  ·  DOSSIER 3-1  BARBADOS", 28, P.INK)
	var land := clampf(t * 2.0 - 0.3, 0.0, 1.0)
	var sq := 1.0 + 0.4 * (1.0 - land)
	D.stamp(self, "missie_geslaagd", dr.position + Vector2(690, 170), P.STAMP_BLUE, 0.62 * sq, -0.12, 0.9 * land)
	for i in 3:
		var sl := clampf(t * 2.0 - 0.8 - i * 0.35, 0.0, 1.0)
		if sl > 0.0:
			D.stamp(self, "ster", dr.position + Vector2(90 + i * 120, 170), P.STAMP_RED if i < 2 else P.SIG_GREY, 0.5 * (1.0 + 0.4 * (1.0 - sl)), -0.1 + i * 0.08, 0.95 * sl)
	P.text_l(self, P.TAPE_REG, dr.position + Vector2(40, 250), "★ treffer   ★★ 0 misstappen   ★★★ zonder hint", 18, P.INK_SOFT)
	# tellers
	P.text_l(self, P.STENCIL, dr.position + Vector2(40, 300), "TIKKEN", 20, P.INK)
	D.tally_bar(self, dr.position + Vector2(40, 330), 480, "jij", 36, 42, P.STAMP_BLUE)
	D.tally_bar(self, dr.position + Vector2(40, 366), 480, "optimum", 34, 42, Color("#3FA86B"))
	D.tally_bar(self, dr.position + Vector2(40, 402), 480, "brute kracht", 42, 42, P.SIG_GREY)
	# lintverslag
	P.text_l(self, P.STENCIL, dr.position + Vector2(40, 470), "LINTVERSLAG", 20, P.INK)
	var mt := "barbaarse_barbecue_in_barbados"
	D.tape(self, dr.position.x + 40, dr.position.y + 500, mt, 0, 30, 27.0, {"hits": [[22, 29]], "size": 24})
	D.stamp(self, "treffer", dr.position + Vector2(40 + 26 * 27, 506), P.STAMP_BLUE, 0.32, 0.05, 0.85)
	P.text_l(self, P.TAPE, dr.position + Vector2(40, 630), "✓ barbados @22", 20, Color("#13875C"))
	P.text_l(self, P.TAPE, dr.position + Vector2(300, 630), "✗ gemist: 0", 20, P.INK_SOFT)
	P.text_l(self, P.TAPE, dr.position + Vector2(520, 630), "! vals alarm: 0", 20, P.INK_SOFT)
	# misstappen-tijdlijn
	P.text_l(self, P.STENCIL, dr.position + Vector2(40, 690), "MISSTAPPEN", 20, P.INK)
	draw_line(dr.position + Vector2(50, 730), dr.position + Vector2(840, 730), Color(P.INK, 0.4), 2.0)
	var kinds := ["ok", "ok", "ok", "mis", "ok", "klem", "ok", "ok", "ok", "ok", "ok", "ok"]
	for i in kinds.size():
		var c := dr.position + Vector2(60 + i * 66, 730)
		var col := Color("#3FA86B") if kinds[i] == "ok" else (P.SIG_AMBER if kinds[i] == "mis" else P.SIG_GREY)
		draw_circle(c, 11 if kinds[i] == "mis" else 8, col, true, -1.0, true)
		if kinds[i] == "mis":
			draw_arc(c, 16, 0, TAU, 20, P.SIG_AMBER, 2.0, true)
	# coachzin
	D.chef(self, dr.position + Vector2(110, 870), 0.62)
	var cr := Rect2(dr.position + Vector2(200, 800), Vector2(660, 140))
	draw_rect(cr, Color(P.CARD, 0.9))
	draw_rect(Rect2(cr.position, Vector2(6, cr.size.y)), P.SIG_AMBER)
	P.text_l(self, P.TAPE, cr.position + Vector2(22, 34), "Na een mismatch op 5 past al 3 plaatsen:", 21, P.INK)
	P.text_l(self, P.TAPE, cr.position + Vector2(22, 64), "V[5] = 3, niet 5.", 21, P.INK)
	P.text_l(self, P.TAPE_REG, cr.position + Vector2(22, 104), "→ Definitie 11, notas p. 56", 18, P.STAMP_RED)
	# ---- UI-onderdelen (rechts)
	P.panel(self, Rect2(980, 40, 900, 520), P.CONSOLE, true, 12)
	P.text_l(self, P.STENCIL, Vector2(1010, 78), "PERSONAGES & WERELD", 22, P.TEXT_DIM)
	D.chef(self, Vector2(1120, 250), 1.0, absf(sin(t * 8.0)) * 0.5, 1.0 if fmod(t, 3.1) < 0.12 else 0.0)
	P.text_c(self, P.UI_BOLD, Vector2(1120, 372), "Chef Ponsaert", 20, P.TEXT)
	D.courier(self, Vector2(1290, 330), 2.3, Color("#0E1012"), 0.0)
	P.text_c(self, P.UI, Vector2(1300, 372), "Ekster-koerier", 18, P.TEXT_DIM)
	D.ekster_seal(self, Vector2(1440, 230), 58)
	P.text_c(self, P.UI, Vector2(1440, 314), "Ekster-netwerk", 18, P.TEXT_DIM)
	D.car(self, Vector2(1600, 300), 1.8, 0.5 + 0.5 * sin(t * 9.0))
	P.text_c(self, P.UI, Vector2(1600, 340), "de ploeg", 18, P.TEXT_DIM)
	D.crate(self, Rect2(1010, 384, 420, 160), "MODEL  K-M-P  1977", 0.0, fmod(t * 0.4, 1.0))
	D.capsule(self, Vector2(1640, 470), -0.2, "radar @12", 1.1)
	D.pin(self, Vector2(1780, 520), P.SIG_NE, 1.4)
	D.pin(self, Vector2(1830, 520), P.SIG_GREY, 1.4)
	D.pin(self, Vector2(1805, 470), Color("#3FA86B"), 1.4)
	# iconen
	P.panel(self, Rect2(980, 576, 420, 464), P.CONSOLE, true, 12)
	P.text_l(self, P.STENCIL, Vector2(1010, 612), "ICONEN", 20, P.TEXT_DIM)
	var ic := ["sjabloon", "vingerafdruk", "doorloper", "springer", "lampenbord", "ruisbord", "schakelbord", "zoeklicht",
		"pauze", "notas", "hint", "terug", "instellingen", "kaart", "lock", "tik"]
	for i in ic.size():
		var c := Vector2(1040 + (i % 4) * 96, 680 + (i / 4) * 92)
		P.box(self, Rect2(c - Vector2(34, 34), Vector2(68, 68)), P.CONSOLE_LO, 10)
		D.icon(self, ic[i], c, 40, P.BRASS_HI if i < 8 else P.TEXT)
		P.text_c(self, P.UI, c + Vector2(0, 44), ic[i], 11, P.TEXT_DIM)
	# knoppen (echte Controls staan in _build_ui), schakelaar, regelaar, toetsen
	P.panel(self, Rect2(1416, 576, 464, 464), P.CONSOLE, true, 12)
	P.text_l(self, P.STENCIL, Vector2(1440, 612), "KNOPPEN & REGELAARS", 20, P.TEXT_DIM)
	D.fader(self, Rect2(1450, 990, 200, 40), 0.7 + 0.1 * sin(t), "muziek")
	D.toggle(self, Vector2(1740, 984), 1.0 if fmod(t, 4.0) > 2.0 else 0.0, "")
	P.text_r(self, P.UI, Vector2(1700, 950), "kleurenblind", 16, P.TEXT)
	# paletstrook
	var pal := [P.NIGHT, P.BUNKER, P.CONSOLE, P.CONSOLE_HI, P.BAKELITE, P.BRASS, P.STEEL, P.WOOD, P.PAPER, P.MANILA, P.INK,
		P.SIG_EQ, P.SIG_NE, P.SIG_AMBER, P.SIG_BLUE, P.SIG_WHITE, P.STAMP_RED, P.STAMP_BLUE, P.HEAT]
	for i in pal.size():
		draw_rect(Rect2(40 + i * 47, 1046, 44, 24), pal[i])
		draw_rect(Rect2(40 + i * 47, 1046, 44, 24), Color(0, 0, 0, 0.5), false, 1.0)


func _page_title() -> void:
	_bg()
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.25))
	# attract-lint onderaan (gedimd): de Springer springt zelf
	var at := "de_ekster_vliegt_om_middernacht_over_de_haven_van_oostende"
	var off := fmod(t * 40.0, 44.0)
	D.tape(self, -off, 950, at, int(t * 40.0 / 44.0) % 20, 46, 44.0, {"size": 44})
	draw_rect(Rect2(0, 930, W, 150), Color(P.NIGHT, 0.7))
	# morselampje + jaartal
	P.lamp(self, Vector2(170, 120), 12, P.SIG_AMBER, 1.0 if fmod(t * 3.0, 2.0) < 0.6 else 0.0)
	P.text_l(self, P.TAPE, Vector2(194, 120), "BELGIË · 1961 · LUISTERPOST IN DE DUINEN", 22, P.TEXT_DIM)
	D.ekster_seal(self, Vector2(1760, 140), 54)
	# logo
	var typed := clampf(t * 4.0, 0.0, 5.0)
	var lr := D.logo(self, Vector2(W / 2.0, 360), 1.0, typed)
	D.inlet(self, lr.end.x - 10, 300, clampf(sin(t * 25.0), 0.0, 1.0) if typed < 5.0 else 0.0, -t)
	P.brass_plate(self, Vector2(W / 2.0, 560), "STATION  ZOEKLICHT", 34, P.STENCIL, fmod(t * 0.3, 1.0))
	P.text_c(self, P.UI, Vector2(W / 2.0, 612), "een analoge operator-thriller over exact en benaderend string matching", 20, P.TEXT_DIM)
