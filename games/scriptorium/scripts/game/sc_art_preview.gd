extends Node2D
## Art-proef "Kortschrift" (design/ART.md). Toont alle elementen in de stijl van ART.md, met idle-animatie, kaarslicht,
## partikels en muziek. Referentie voor de front-end engineer, geen gameplaycode. Alles via ScPal/ScDraw/ScDrawTools/
## ScUi/ScFx.
##   pagina 0 "werkbank"   HUD, opdrachtband, binderij (stapels, bundels, touwklos), De Overkant, kortschrift, Zeno
##   pagina 1 "bomen"      levende boom met monniken [g,o] + processie + lantaarn + nng; codeboom (Fig. 25); meetlat + naald
##   pagina 2 "werktuigen" leesraam + draad + zegels, letterplank, stempelkast + zetstok + hendels, trommel + rek
##   pagina 3 "schermen"   titel, getijdenboek met initialen, brief, kist, Kapittel, personages, duiventil, Nachtwake
## Argumenten (na `--`): page=0..3, night=1. Zonder argumenten wisselt de pagina elke 6 s. Toetsen: Tab, N (nacht).

const PAGES := 4
var page := 0
var auto := true
var night := false
var t := 0.0
var _cycle := 0.0

var bg: TextureRect
var ov_tex: TextureRect
var world: Node2D
var overlay: ColorRect
var shafts: ColorRect
var fx: Node2D
var ui: Control
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var _fx_timer := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("page="):
			page = clampi(int(a.get_slice("=", 1)), 0, PAGES - 1)
			auto = false
		elif a == "night=1":
			night = true
	bg = TextureRect.new()
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# De Overkant-achtergrond als eigen TextureRect (niet in de draw-callback: NPOT-textuur zonder repeat)
	ov_tex = TextureRect.new()
	ov_tex.texture = load(ScPal.ASSETS + "art/bg/bg_overkant.jpg")
	ov_tex.position = Vector2(1282, 196)
	ov_tex.size = Vector2(626, 684)
	ov_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ov_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ov_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov_tex)
	world = Node2D.new()
	ScDraw.prepare(world)
	add_child(world)
	world.draw.connect(_draw_world)
	fx = Node2D.new()
	add_child(fx)
	shafts = ScUi.shafts_overlay(Vector2(0.5, 0.06), 0.16)
	add_child(shafts)
	overlay = ScUi.candle_overlay(Vector2(120, 330), 0.42, 1250.0)
	add_child(overlay)
	ui = Control.new()
	ui.size = Vector2(1920, 1080)
	ui.theme = ScUi.theme()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	music = AudioStreamPlayer.new()
	add_child(music)
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	_build_page()


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k == KEY_TAB:
			auto = false
			page = (page + 1) % PAGES
			_build_page()
		elif k == KEY_N:
			night = not night
			_build_page()


func _process(delta: float) -> void:
	t += delta
	if auto:
		_cycle += delta
		if _cycle > 6.0:
			_cycle = 0.0
			page = (page + 1) % PAGES
			_build_page()
	_fx_timer += delta
	if _fx_timer > 2.2:
		_fx_timer = 0.0
		_demo_fx()
	world.queue_redraw()


func _play(path: String, vol := -6.0) -> void:
	var p := ScPal.ASSETS + path
	if ResourceLoader.exists(p):
		sfx.stream = load(p)
		sfx.volume_db = vol
		sfx.play()


func _build_page() -> void:
	for c in fx.get_children():
		c.queue_free()
	for c in ui.get_children():
		c.queue_free()
	var room := page == 3
	var bg_name := "bg_room" if room else ("bg_desk_night" if night else "bg_desk")
	bg.texture = load(ScPal.ASSETS + "art/bg/%s.jpg" % bg_name)
	shafts.visible = room
	ov_tex.visible = page == 0
	overlay.visible = not room
	var m := overlay.material as ShaderMaterial
	m.set_shader_parameter("light_pos", Vector2(200, 930) if night else Vector2(120, 330))
	m.set_shader_parameter("darkness", 0.62 if night else 0.38)
	ScFx.ambient_dust(fx, Rect2(0, 0, 1920, 1080), 0.8)
	var track := "music/sc_title_loop.ogg" if room else ("music/sc_wake_loop.ogg" if night else "music/sc_bench_loop.ogg")
	music.stream = load(ScPal.ASSETS + track)
	music.volume_db = -10.0
	music.play()
	if room:
		_build_room_ui()
	else:
		_build_bench_ui()


func _build_bench_ui() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.position = Vector2(1300, 1000)
	ui.add_child(row)
	row.add_child(ScUi.button("Verzenden", ScUi.Kind.WAX, 24, 180))
	row.add_child(ScUi.button("Geen match", ScUi.Kind.VELLUM, 24, 180))
	row.add_child(ScUi.icon_button("hint", ScUi.Kind.SECONDARY, 56))
	row.add_child(ScUi.icon_button("undo", ScUi.Kind.SECONDARY, 56))


func _build_room_ui() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.position = Vector2(1530, 300)
	ui.add_child(col)
	col.add_child(ScUi.button("Het kloosterjaar", ScUi.Kind.PRIMARY, 26, 300))
	col.add_child(ScUi.button("Nachtwake", ScUi.Kind.SECONDARY, 26, 300))
	col.add_child(ScUi.button("Instellingen", ScUi.Kind.SECONDARY, 26, 300))
	col.add_child(ScUi.button("Terug naar de speelhal", ScUi.Kind.GHOST, 22, 300))


func _demo_fx() -> void:
	match page:
		0:
			ScFx.twine_knot(fx, Vector2(330, 610))
			ScFx.ink_flick(fx, Vector2(880, 980))
			_play("sfx/twine_bind.wav", -8)
		1:
			ScFx.snip(fx, Vector2(1320, 470))
			_play("sfx/weight_bell.wav", -10)
		2:
			ScFx.wax_splat(fx, Vector2(560, 380), ScPal.WAX_GREEN)
			ScFx.shavings(fx, Vector2(330, 760), 6)
			_play("sfx/stamp.wav", -8)
		3:
			ScFx.gold_rain(fx, Rect2(1060, 640, 380, 80))
			ScFx.wax_splat(fx, Vector2(1180, 470))
			_play("sfx/wax_seal.wav", -10)


# ================================================================ tekenen
func _caption(c: CanvasItem, pos: Vector2, title: String, sub := "") -> void:
	var w := ScPal.text_w(ScPal.TITLE, title, 28) + (ScPal.text_w(ScPal.UI_MED, sub, 18) + 24 if sub != "" else 0.0) + 40
	var r := Rect2(pos, Vector2(w, 44))
	c.draw_style_box(ScPal.sb(Color(ScPal.PANEL, 0.92), 22, 8, Vector2(0, 4)), r)
	ScPal.ring(c, r.grow(-4), 18, Color(ScPal.GILT, 0.6), 1)
	var x := ScPal.text_l(c, ScPal.TITLE, pos + Vector2(20, 22), title, 28, ScPal.GILT_LIGHT)
	if sub != "":
		ScPal.text_l(c, ScPal.UI_MED, pos + Vector2(20 + x + 18, 23), sub, 18, ScPal.TEXT_DIM)


func _draw_world() -> void:
	match page:
		0:
			_page_bench(world)
		1:
			_page_trees(world)
		2:
			_page_tools(world)
		3:
			_page_room(world)


# ---------------------------------------------------------------- pagina 0: werkbank (binderij, 1-1 boosdoeer)
func _page_bench(c: CanvasItem) -> void:
	var alpha := "boesdr"
	# HUD
	ScDraw.leather(c, Rect2(12, 6, 1896, 70), 18)
	ScDraw.tool_icon(c, Vector2(54, 41), 13, "pause", ScPal.GILT_LIGHT, t)
	ScPal.text_l(c, ScPal.TITLE, Vector2(84, 40), "Kerstmis · 1-1 Boosdoeer", 32, ScPal.GILT_LIGHT)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(440, 42), "notas p. 84–85", 18, ScPal.TEXT_DIM)
	ScDraw.ink_meter(c, Rect2(620, 12, 600, 58), 8, 22, 72, t)
	ScDraw.pill(c, Rect2(1240, 20, 150, 42), "twine", "8", t)
	ScDraw.pill(c, Rect2(1404, 20, 130, 42), "bump", "0", t)
	for k in 3:
		ScDraw.star_seal(c, Vector2(1640 + k * 42, 41), 16, k < 1, 1.0, k)
	ScDraw.tool_icon(c, Vector2(1860, 41), 13, "notes", ScPal.GILT_LIGHT, t)
	# opdrachtband
	ScPal.text_l(c, ScPal.TITLE, Vector2(40, 150), "Opdracht", 26, ScPal.GILT_LIGHT)
	ScDraw.task_band(c, Vector2(170, 150), "boosdoeer", 58, 44, -1, -1, true, alpha, true, t)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(760, 150), "n = 9 · gewoon schrift 72 bits", 20, ScPal.TEXT_DIM)
	# kaars links op de tafel
	ScDraw.candle(c, Vector2(110, 420), 1.0, t, true, 0.8)
	# binderij: rij na b+s en d+r (= p. 85 stap 3)
	var base_y := 690.0
	var xs := [330.0, 520.0, 690.0, 870.0]
	_mini_tree(c, Vector2(xs[0], base_y - 250), "b", "s", alpha)
	ScDrawTools.pile(c, Vector2(xs[0], base_y), "", 2, alpha, true, t, true)
	ScDrawTools.pile(c, Vector2(xs[1], base_y), "o", 3, alpha, false, t)
	ScDrawTools.pile(c, Vector2(xs[2], base_y), "e", 2, alpha, false, t)
	_mini_tree(c, Vector2(xs[3], base_y - 250), "d", "r", alpha)
	ScDrawTools.pile(c, Vector2(xs[3], base_y), "", 2, alpha, false, t, true, 86.0, true)
	ScDraw.inkhand(c, Vector2(xs[3] + 30, base_y - 70), 0.9, t, 0.55)
	ScDrawTools.twine_spool(c, Vector2(1110, 560), 1.0, t, 8, false, t * 0.2)
	# Zeno
	ScDraw.zeno(c, Vector2(150, 820), 0.95, t, 0.5 + 0.5 * sin(t * 2.0))
	ScDraw.scroll(c, Rect2(260, 735, 470, 60), Vector2(205, 780))
	ScPal.text_l(c, ScPal.UI, Vector2(286, 765), "Niet uniek. Elke keuze is even goed.", 24, ScPal.INK)
	# De Overkant
	var ov := Rect2(1282, 196, 626, 684)
	ScPal.ring(c, ov.grow(4), 10, ScPal.GILT_DARK, 6)
	ScPal.ring(c, ov.grow(1), 8, ScPal.GILT, 2)
	_caption(c, ov.position + Vector2(18, 16), "De Overkant", "Priorij Bindervoort")
	ScDraw.letterlijk(c, Vector2(1520, 600), 1.0, t, 0, 0.6)
	ScDraw.dove(c, Vector2(1800, 360), 1.1, t, 0, -1.0, 0, true)
	ScDraw.parchment(c, Rect2(1310, 760, 570, 100), 77, ScPal.VELLUM, true, 0.5)
	ScDraw.reading(c, Vector2(1340, 810), "boosdoeer", "boosdoeer", 30, int(fmod(t * 4.0, 12.0)), t)
	# kortschrift
	ScDraw.leather(c, Rect2(12, 892, 1896, 182), 18)
	ScPal.text_l(c, ScPal.TITLE, Vector2(44, 930), "Kortschrift", 28, ScPal.GILT_LIGHT)
	ScDraw.parchment(c, Rect2(40, 958, 1220, 92), 5, ScPal.VELLUM, false, 0.6)
	var toks := [{"b": "000"}, {"b": "10"}, {"b": "10"}, {"b": "001"}, {"b": "010"}, {"b": "10"}, {"b": "11"}, {"b": "11"}, {"b": "011"}]
	var endx := ScDraw.shorthand(c, Vector2(64, 1004), toks, 28, 22 * (ScPal.char_w(28) + 6.0) + 8 * 8, t)
	ScDraw.quill(c, Vector2(endx + 18, 1000), 0.75, -1.0, t, 1.0)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(1300, 930), "koker van de duif (optimum 22)", 18, ScPal.TEXT_DIM)
	ScDraw.koker(c, Vector2(1300, 970), 300, 0.85 + 0.25 * (0.5 + 0.5 * sin(t * 0.8)), t)


func _mini_tree(c: CanvasItem, top: Vector2, a: String, b: String, alpha: String) -> void:
	var la := top + Vector2(-40, 40)
	var lb := top + Vector2(40, 40)
	ScDrawTools.branch(c, top, la, "0", false, 5, t)
	ScDrawTools.branch(c, top, lb, "1", false, 5, t)
	ScDrawTools.knob(c, top, 11)
	ScDrawTools.leaf_tile(c, la, a, 26, alpha, false, "", t)
	ScDrawTools.leaf_tile(c, lb, b, 26, alpha, false, "", t)


# ---------------------------------------------------------------- pagina 1: levende boom, codeboom, meetlat
func _page_trees(c: CanvasItem) -> void:
	_caption(c, Vector2(30, 20), "De levende boom", "monniken [gewicht, nummer] · processie · lantaarn · nng (notas p. 90)")
	var alpha := "bsdreo"
	# boom van p. 90; s krijgt de lantaarn, r is de wisselpartner t'
	var P := {
		"root": Vector2(560, 210), "nL": Vector2(360, 330), "nR": Vector2(780, 330),
		"LL": Vector2(240, 450), "LR": Vector2(480, 450), "b": Vector2(180, 590), "s": Vector2(300, 590),
		"d": Vector2(420, 590), "r": Vector2(540, 590), "e": Vector2(700, 470), "o": Vector2(860, 470),
	}
	var edges := [["root", "nL", "0"], ["root", "nR", "1"], ["nL", "LL", "0"], ["nL", "LR", "1"], ["LL", "b", "0"],
		["LL", "s", "1"], ["LR", "d", "0"], ["LR", "r", "1"], ["nR", "e", "0"], ["nR", "o", "1"]]
	for e in edges:
		ScDrawTools.branch(c, P[e[0]] + Vector2(0, -30), P[e[1]] + Vector2(0, -70), e[2], e[1] == "s" or e[1] == "LL" or e[1] == "nL", 6, t)
	var cards := {"root": "[9,11]", "nL": "[4,9]", "nR": "[5,10]", "LL": "[2,5]", "LR": "[2,6]", "b": "[1,1]", "s": "[1,2]",
		"d": "[1,3]", "r": "[1,4]", "e": "[2,7]", "o": "[3,8]"}
	var i := 0
	for k in P:
		var sym: String = k if k.length() == 1 else ""
		ScDraw.monk(c, P[k], 1.0, t, ScPal.HABITS[i % 4], cards[k], k == "r", k == "s", 0.0, 1.0, 1 if k == "r" else 0, 0.0, sym, alpha)
		i += 1
	# processie (op ordenummer), broers hand in hand
	var order := ["b", "s", "d", "r", "LL", "LR", "e", "o", "nL", "nR", "root"]
	var wts := [1, 1, 1, 1, 2, 2, 2, 3, 4, 5, 9]
	ScDraw.wood(c, Rect2(60, 708, 1020, 18), ScPal.OAK_DARK, 6)
	var pos := []
	for j in order.size():
		var p := Vector2(110 + j * 92, 700)
		pos.append(p)
	for j in range(0, 10, 2):
		ScDrawTools.hand_link(c, pos[j], pos[j + 1], 0.8)
	for j in order.size():
		var nm: String = order[j]
		var stumble := 0.0
		ScDraw.monk(c, pos[j], 0.8, t + j, ScPal.HABITS[j % 4], "%d·%d" % [wts[j], j + 1], nm == "r", false, stumble, 1.0, 0,
			0.0, nm if nm.length() == 1 else "", alpha)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(70, 752), "processie: gewicht stijgt nooit naar links · broers 2j−1 en 2j hand in hand", 20, ScPal.TEXT)
	# nng-zaadje + struikelende monnik (eigenschap (b) gebroken)
	ScDrawTools.seed_nng(c, Vector2(1000, 230), 1.4, t, "[0,1]", false, 0.5 + 0.5 * sin(t))
	ScDraw.monk(c, Vector2(1010, 530), 1.1, t, ScPal.HABITS[2], "[3,5]", false, false, 1.0, 1.0, 2)
	ScPal.text_c(c, ScPal.UI_MED, Vector2(1010, 566), "struikelt: (b) gebroken", 18, ScPal.TEXT)
	# codeboom Fig. 25 (klein)
	_caption(c, Vector2(30, 790), "Codeboom", "Fig. 25 · lees 00010011 = oud")
	var T := {"w": Vector2(330, 850), "A": Vector2(230, 900), "C": Vector2(450, 900), "B": Vector2(290, 950)}
	var L := {"o": Vector2(170, 950), "u": Vector2(240, 1000), "d": Vector2(340, 1000), "f": Vector2(410, 950), "t": Vector2(490, 950)}
	var codes := {"o": "00", "u": "010", "d": "011", "f": "10", "t": "11"}
	ScDrawTools.branch(c, T["w"], T["A"], "0", true, 6, t)
	ScDrawTools.branch(c, T["w"], T["C"], "1", false, 6, t)
	ScDrawTools.branch(c, T["A"], L["o"], "", false, 5, t)
	ScDrawTools.branch(c, T["A"], T["B"], "1", true, 6, t)
	ScDrawTools.branch(c, T["B"], L["u"], "0", true, 5, t)
	ScDrawTools.branch(c, T["B"], L["d"], "", false, 5, t)
	ScDrawTools.branch(c, T["C"], L["f"], "", false, 5, t)
	ScDrawTools.branch(c, T["C"], L["t"], "", false, 5, t)
	for k in T:
		ScDrawTools.knob(c, T[k], 11)
	for k in L:
		ScDrawTools.leaf_tile(c, L[k] + Vector2(0, -26), k, 20, "", k == "u", codes[k], t)
	ScDraw.task_band(c, Vector2(560, 900), "00010011", 46, 30, 2, 2, true, "", false, t)
	# meetlat (rechts)
	_caption(c, Vector2(1160, 20), "De meetlat", "x 0,2 · y 0,7 · z 0,1 · onder dicht, boven open")
	var segs := [{"sym": "x", "lo": 0.0, "hi": 0.2}, {"sym": "y", "lo": 0.2, "hi": 0.9}, {"sym": "z", "lo": 0.9, "hi": 1.0}]
	ScDrawTools.ruler(c, Rect2(1260, 110, 110, 600), segs, "y", -1.0, t, ["0", "0,2", "0,9"])
	ScPal.text_r(c, ScPal.MONO_M, Vector2(1238, 110), "1", 20, ScPal.TEXT)
	ScDrawTools.scissors(c, Vector2(1400, 220), 1.0, 0.25 + 0.2 * sin(t * 6.0), PI)
	ScDrawTools.ledger_table(c, Rect2(1440, 110, 450, 190), ["i", "teken", "links", "lengte"],
		[[0, "y", "0,2", "0,7"], [1, "y", "0,34", "0,49"]], 22, 1)
	ScDrawTools.ruler(c, Rect2(1520, 360, 90, 300), segs, "", 0.62, t, [], true)
	ScPal.text_l(c, ScPal.UI_MED, Vector2(1640, 400), "ontvangen: de speld", 20, ScPal.TEXT)
	ScPal.text_l(c, ScPal.MONO_B, Vector2(1640, 432), "0,8125", 22, ScPal.TEXT)
	ScDrawTools.needle(c, Rect2(1200, 770, 680, 90), 0.0, 1.0, 0.34, 0.83, 0.25, 0.25, t, {0.0: "0", 0.34: "0,34", 0.83: "0,83", 1.0: "1"})
	ScPal.text_l(c, ScPal.UI_MED, Vector2(1200, 900), "binaire naald (Alg. 13): goud = [low; up), spookstreep = getal + next", 18, ScPal.TEXT)


# ---------------------------------------------------------------- pagina 2: leesraam, letterplank, stempelkast, trommel
func _page_tools(c: CanvasItem) -> void:
	_caption(c, Vector2(30, 20), "Het leesraam", "LZ77 · G = 6 · banaan-baan bij k = 8")
	var cents := ScDrawTools.reading_window(c, Vector2(60, 170), "banaan-baan", 2, 6, 52, 40, 1, true, t, 8)
	var prog := fmod(t * 0.6, 1.0)
	ScDrawTools.thread(c, cents[3] + Vector2(0, -26), cents[8] + Vector2(0, -26), prog, t, 70)
	var seals := [[0, 0, "b"], [0, 0, "a"], [0, 0, "n"], [1, 1, "a"], [2, 1, "-"], [0, 0, "b"], [1, 3, "EOF"]]
	for k in seals.size():
		ScDraw.triple_seal(c, Vector2(110 + k * 112 + (40 if k == 6 else 0), 300 + (k % 2) * 8), seals[k][0], seals[k][1], seals[k][2], 20, k == 6)
	# letterplank
	_caption(c, Vector2(1000, 20), "De letterplank", "move-to-front · positie vanaf 0")
	ScDrawTools.shelf(c, Vector2(1010, 160), [" ", "1", "a", "b", "e", "f", "g", "n", "o", "l"], 74, true, 7, t)
	for d in 8:
		ScDrawTools.digit_stamp(c, Vector2(1060 + d * 104, 340), d, 1.0, d == 7, 0.5 + 0.5 * sin(t * 4.0) if d == 7 else 0.0)
	# stempelkast
	_caption(c, Vector2(30, 420), "De stempelkast", "LZW · banaanaanval")
	ScDrawTools.cabinet(c, Rect2(40, 480, 620, 420), [["b", 98], ["a", 97], ["n", 110], ["v", 118], ["l", 108]],
		[[256, "ba"], [257, "an"], [258, "na"], [259, "aa"], [260, "ana"], [261, ""]], 257, 261, 260, t)
	ScDrawTools.zetstok(c, Vector2(700, 560), "aa", "n", true, 36, t)
	ScDrawTools.lever(c, Vector2(760, 760), "Verleng", "V", 0.0, true, ScPal.VERDIGRIS, t)
	ScDrawTools.lever(c, Vector2(940, 760), "Stempel", "S", 0.5 + 0.5 * sin(t * 2.0), false, ScPal.RUBRIC, t)
	var toks := [{"code": 98}, {"code": 97}, {"code": 110}, {"code": 97}, {"code": 257}]
	ScDraw.parchment(c, Rect2(40, 940, 640, 90), 9)
	ScDraw.shorthand(c, Vector2(70, 985), toks, 28, -1.0, t)
	# trommel + rek
	_caption(c, Vector2(1060, 420), "De draaitrommel", "BWT · geen loon · p = 1")
	ScDrawTools.drum(c, Vector2(1230, 680), 100, 230, "geen loon", t * 0.8, t, 34)
	var rows := ["␣loongeen", "een␣loong", "en␣loonge", "geen␣loon", "loongeen␣", "n␣loongee", "ngeen␣loo", "ongeen␣lo", "oongeen␣l"]
	var plain: Array = []
	for r in rows:
		plain.append(r.replace("␣", " "))
	ScDrawTools.rack(c, Vector2(1440, 500), plain, 26, 1, -1, "", Vector2.INF, t, true)


# ---------------------------------------------------------------- pagina 3: schermen (titel, kaart, Kapittel, personages)
func _page_room(c: CanvasItem) -> void:
	# titel op een perkamentrol
	ScDraw.scroll(c, Rect2(620, 36, 680, 150))
	ScPal.text_c(c, ScPal.TITLE, Vector2(963, 103), "Kortschrift", 104, Color(ScPal.INK, 0.25))
	ScPal.text_c(c, ScPal.TITLE, Vector2(960, 98), "Kortschrift", 104, ScPal.INK)
	ScPal.text_c(c, ScPal.TITLE_LIGHT, Vector2(960, 160), "Het scriptorium van Zuinigem", 30, ScPal.RUBRIC)
	# getijdenboek (kaart)
	var pages := ScDrawTools.book_spread(c, Rect2(60, 260, 800, 470), ScPal.FOLIUM, t)
	var lp: Rect2 = pages[0]
	var rp: Rect2 = pages[1]
	ScPal.text_c(c, ScPal.TITLE, Vector2(lp.get_center().x, lp.position.y + 52), "Kerstmis", 40, ScPal.RUBRIC)
	ScPal.text_c(c, ScPal.TITLE, Vector2(rp.get_center().x, rp.position.y + 52), "Vasten", 40, ScPal.FOLIUM)
	var lv := [["B", 1, 3, false, "binderij", "1-1"], ["O", 1, 2, false, "binderij", "1-2"], ["Z", 1, 0, false, "binderij", "1-3"],
		["G", 2, 1, false, "levende_boom", "2-1"], ["E", 2, 0, true, "levende_boom", "2-2"], ["V", 2, 0, true, "levende_boom", "2-3"]]
	for k in lv.size():
		var pg: Rect2 = lp if k < 3 else rp
		var col := k % 3
		var r := Rect2(pg.position + Vector2(40 + col * 120, 110 + (col % 2) * 40), Vector2(86, 86))
		ScDrawTools.initial(c, r, lv[k][0], lv[k][1], lv[k][2], lv[k][3], k == 2, t, lv[k][4], lv[k][5])
	ScPal.text_c(c, ScPal.UI_MED, Vector2(lp.get_center().x, lp.end.y - 50), "Priorij Bindervoort · de binderij", 18, ScPal.INK_SOFT)
	ScPal.text_c(c, ScPal.UI_MED, Vector2(rp.get_center().x, rp.end.y - 50), "Klooster Groeiendonk", 18, ScPal.INK_SOFT)
	# Kapittel (terugblik)
	var kr := Rect2(960, 230, 520, 520)
	ScDraw.parchment(c, kr, 33, ScPal.VELLUM, true, 0.7)
	ScPal.text_c(c, ScPal.TITLE, Vector2(kr.get_center().x, kr.position.y + 44), "Het Kapittel", 40, ScPal.RUBRIC)
	ScPal.text_c(c, ScPal.UI_BOLD, Vector2(kr.get_center().x, kr.position.y + 86), "DE OVERKANT LAS ONZIN", 22, ScPal.SEPIA)
	for k in 3:
		var press := clampf(fmod(t, 4.0) * 2.0 - k * 0.5, 0, 1)
		ScDraw.star_seal(c, Vector2(kr.get_center().x + (k - 1) * 80, kr.position.y + 150), 30, k < 1, press, k + 11)
	ScDraw.reading(c, Vector2(kr.position.x + 120, kr.position.y + 250), "graag", "graggga", 34, -1, t, 0.5 + 0.5 * sin(t * 3.0))
	ScDrawTools.ledger_bars(c, Rect2(kr.position.x + 20, kr.position.y + 330, kr.size.x - 40, 175),
		[{"label": "jouw inkt", "value": 33, "col": ScPal.INK}, {"label": "optimum", "value": 33, "col": ScPal.GOLD},
		{"label": "gewoon", "value": 40, "col": ScPal.INK_FADED}])
	# personages en rekwisieten op het tafelblad
	ScDraw.candle(c, Vector2(230, 905), 1.1, t, true, 0.9)
	ScDraw.candle(c, Vector2(1690, 905), 1.0, t + 2.0, true, 0.5)
	ScDraw.zeno(c, Vector2(420, 1000), 0.9, t, 0.4)
	ScDraw.gommaar(c, Vector2(640, 1010), 0.85, t)
	ScDrawTools.letter(c, Vector2(900, 960), 0.55, 0.0, ScPal.WAX)
	ScDrawTools.crate(c, Vector2(1140, 1040), 0.65, 0.5 + 0.5 * sin(t * 1.5), t)
	ScDraw.dove(c, Vector2(1360 + sin(t * 0.7) * 30, 840), 1.0, t, 1, 1.0, 0, true)
	ScDraw.dove(c, Vector2(1500, 1005), 0.9, t, 0, -1.0, 1, true)
	ScDraw.inkpot(c, Vector2(1820, 1010), 1.0, 1.0, false, t)
	ScDraw.quill(c, Vector2(1790, 975), 0.8, -2.0, t)
	ScDrawTools.dovecote(c, Vector2(1730, 700), 0.42, {"": true, "0": true, "1": true, "00": true, "01": true, "10": true, "11": true, "0101": true}, t)
