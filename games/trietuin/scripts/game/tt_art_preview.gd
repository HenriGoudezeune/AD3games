extends Node2D
## Art-proef "Trietuin" (design/ART.md). Toont alle elementen in de stijl van ART.md, per seizoen, met idle-animatie.
## Pagina 0 "tuin": een spelscène (HUD, sapmeter, zaadjes, trie met vruchten, bijen, spooktak, kaartje met knoppen).
## Pagina 1 "plaat": Patricia (skip + BBBB-bedrog), ternary rankknopen, suffixboom + slinger + speurneus, UI-kit.
## Referentie voor de front-end engineer, geen gameplaycode. Alles in code (TtPal / TtDraw / TtUi / TtFx).
##
## Argumenten (na `--`): season=0..3, page=0..1. Zonder argumenten wisselt het seizoen elke 5 s en de pagina na
## elke vier seizoenen. Toetsen: 1–4 seizoen, Tab pagina.

const ALPHA := "ACGT_"
const GROUND := Vector2(970, 952)

var season := 0
var page := 0
var auto := true
var t := 0.0
var _cycle_t := 0.0

var bg_back: TextureRect
var bg_front: TextureRect
var fg: TextureRect
var clouds: Array[Sprite2D] = []
var amb: CPUParticles2D
var world: Node2D
var hud: Node2D
var ui_root: Control
var fx_layer: Node2D
var music: AudioStreamPlayer
var bloom: AudioStreamPlayer
var ambience: AudioStreamPlayer
var buzz: AudioStreamPlayer
var sfx: AudioStreamPlayer
var _bee_was_home := false

# ---------------------------------------------------------------- de trie van pagina 0
# woorden {ACAT_, ACGT_, AGT_, CAT_, CT_, G_}; interne toppen met hun positie, bladeren met de top van hun tak.
var nodes := {
	"": Vector2(970, 792),
	"A": Vector2(730, 612),
	"AC": Vector2(590, 438),
	"C": Vector2(1190, 600),
}
var leaves := {
	"ACAT_": Vector2(420, 262),
	"ACGT_": Vector2(690, 270),
	"AGT_": Vector2(850, 430),
	"CAT_": Vector2(1040, 410),
	"CT_": Vector2(1330, 405),
	"G_": Vector2(1440, 660),
}
var edges := []      # {from, to, letter, pts, depth, child}
var bee_path := PackedVector2Array()
var bee_marks: Array[float] = []   # fracties waar de bij een knoest passeert


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("season="):
			season = clampi(int(a.get_slice("=", 1)), 0, 3)
			auto = false
		elif a.begins_with("page="):
			page = clampi(int(a.get_slice("=", 1)), 0, 2)
			auto = false
	_build_bg()
	world = Node2D.new()
	add_child(world)
	world.draw.connect(_draw_world)
	fx_layer = Node2D.new()
	add_child(fx_layer)
	fg = TextureRect.new()
	fg.position = Vector2(0, 1080 - 180)
	fg.size = Vector2(1920, 180)
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fg)
	hud = Node2D.new()
	add_child(hud)
	hud.draw.connect(_draw_hud)
	ui_root = Control.new()
	ui_root.size = Vector2(1920, 1080)
	ui_root.theme = TtUi.theme()
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	# eigen spelers: de preview hangt niet af van de game-audiolaag (TtSnd, front-end)
	music = _player("Music")
	bloom = _player("Music")
	ambience = _player("SFX")
	buzz = _player("SFX")
	sfx = _player("SFX")
	buzz.stream = load(TtPal.ASSETS + "sfx/bee_buzz_loop.wav")
	_build_tree()
	_apply_season(true)
	_build_page()


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k := (ev as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_4:
			auto = false
			season = k - KEY_1
			_apply_season(false)
		elif k == KEY_TAB:
			auto = false
			page = (page + 1) % 3
			_build_page()


func _process(delta: float) -> void:
	t += delta
	if auto:
		_cycle_t += delta
		if _cycle_t > 5.0:
			_cycle_t = 0.0
			season = (season + 1) % 4
			if season == 0:
				page = (page + 1) % 3
				_build_page()
			_apply_season(false)
	for i in clouds.size():
		var c := clouds[i]
		c.position.x += delta * (8.0 + i * 5.0)
		if c.position.x > 2150:
			c.position.x = -250
	world.queue_redraw()
	hud.queue_redraw()
	# kleine audio/partikel-demo op pagina 0: de bij zoemt en vindt ACGT_
	if page == 0:
		var home := fmod(t * 0.16, 1.25) >= 1.0
		if not home and not buzz.playing:
			buzz.volume_db = -20.0
			buzz.play()
		elif home and buzz.playing:
			buzz.stop()
		if home and not _bee_was_home:
			_sfx("pick_ok", -4.0)
			TtFx.found(fx_layer, leaves["ACGT_"] + Vector2(0, 50))
		_bee_was_home = home
	elif buzz.playing:
		buzz.stop()


# ================================================================ achtergrond & seizoen
func _build_bg() -> void:
	bg_back = TextureRect.new()
	bg_front = TextureRect.new()
	for r in [bg_back, bg_front]:
		r.size = Vector2(1920, 1080)
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
	var tex1 := TtPal.tex("art/bg/cloud_1.png")
	var tex2 := TtPal.tex("art/bg/cloud_2.png")
	for i in 3:
		var s := Sprite2D.new()
		s.texture = tex1 if i % 2 == 0 else tex2
		s.position = Vector2(300 + i * 620, 150 + (i % 2) * 110)
		s.scale = Vector2.ONE * (0.8 + 0.2 * i)
		add_child(s)
		clouds.append(s)


func _apply_season(instant: bool) -> void:
	var se := TtPal.season(season)
	bg_back.texture = bg_front.texture if bg_front.texture else load(TtPal.bg_path(season))
	bg_front.texture = load(TtPal.bg_path(season))
	fg.texture = load(TtPal.fg_path(season))
	if instant:
		bg_front.modulate.a = 1.0
	else:
		bg_front.modulate.a = 0.0
		create_tween().tween_property(bg_front, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		TtFx.season_wave(fx_layer, season)
	for c in clouds:
		c.modulate = Color(1, 1, 1, 0.35) if se.night else Color(1, 1, 1, 0.75)
	# muziek (basis + bloei, synchroon) en sfeerlus van het seizoen (ART.md §8)
	music.stream = load(TtPal.ASSETS + se.music)
	bloom.stream = load(TtPal.ASSETS + se.music.replace("_loop", "_bloom_loop"))
	ambience.stream = load(TtPal.ASSETS + se.ambience)
	music.volume_db = -8.0
	bloom.volume_db = -11.0 if page != 0 else -60.0
	ambience.volume_db = -14.0
	music.play()
	bloom.play()
	ambience.play()
	if not instant:
		_sfx("season_change", -10.0)
	if amb:
		amb.queue_free()
	amb = TtFx.ambient(self, season)
	move_child(amb, bg_front.get_index() + 1 + clouds.size())


# ================================================================ pagina's
func _build_page() -> void:
	for c in ui_root.get_children():
		c.queue_free()
	fg.visible = page == 0
	if page == 0:
		var pause := TtUi.icon_button("pause", TtUi.Kind.SECONDARY, 56)
		pause.position = Vector2(30, 20)
		ui_root.add_child(pause)
		var bloom := TtUi.button("Laat bloeien", TtUi.Kind.PRIMARY, 28, 230)
		bloom.position = Vector2(1520, 900)
		ui_root.add_child(bloom)
		var undo := TtUi.button("Herstel", TtUi.Kind.SECONDARY, 28, 150)
		undo.position = Vector2(1760, 900)
		ui_root.add_child(undo)
	elif page == 1:
		var mist := ColorRect.new()
		mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(mist)
		mist.set_deferred("position", Vector2(400, 690))
		mist.set_deferred("size", Vector2(340, 190))
		var mm := ShaderMaterial.new()
		mm.shader = load(TtPal.ASSETS + "art/shaders/tt_mist.gdshader")
		mm.set_shader_parameter("size_px", Vector2(340, 190))
		mm.set_shader_parameter("hole_px", Vector2(150, 95))
		mm.set_shader_parameter("hole_radius", 70.0)
		mist.material = mm
		var y := 514.0
		var x := 1250.0
		var specs := [["Volgende", TtUi.Kind.PRIMARY, 170], ["Opnieuw", TtUi.Kind.SECONDARY, 150],
			["Snoei", TtUi.Kind.SAP, 120], ["Kaart", TtUi.Kind.GHOST, 120]]
		for sp in specs:
			var b := TtUi.button(sp[0], sp[1], 24, sp[2])
			b.position = Vector2(x, y)
			ui_root.add_child(b)
			x += sp[2] + 14 + 0.0
		var ib := TtUi.icon_button("home", TtUi.Kind.SECONDARY, 52)
		ib.position = Vector2(1250 + 0, 1080)
		ib.visible = false
		ui_root.add_child(ib)


# ================================================================ boomstructuur (pagina 0)
func _build_tree() -> void:
	edges.clear()
	var keys := nodes.keys()
	for k in keys:
		if k == "":
			continue
		edges.append({"from": k.substr(0, k.length() - 1), "letter": k[k.length() - 1], "child": k, "leaf": false})
	for w in leaves:
		var parent := ""
		for k in keys:
			if w.begins_with(k) and k.length() > parent.length():
				parent = k
		edges.append({"from": parent, "letter": w[parent.length()], "child": w, "leaf": true})
	# punten berekenen: van de knop van de ouder naar de onderkant van de kind-knoest of de vruchttop
	for e in edges:
		var tops := _bud_tops(e.from)
		var i := ALPHA.find(e.letter)
		var p0: Vector2 = tops[i]
		var p1: Vector2 = leaves[e.child] if e.leaf else nodes[e.child] + Vector2(0, 20)
		var depth: int = e.from.length()
		var bend := 0.08 if p1.x < p0.x else -0.08
		e["arch"] = e.leaf and p1.y < p0.y - 120.0
		e["pts"] = TtDraw.branch_curve(p0, p1, Vector2.UP, bend, 26, e.arch)
		e["depth"] = depth
	# bijenpad: wortel -> A -> AC -> ACGT_
	bee_path = PackedVector2Array()
	bee_marks.clear()
	var route := ["A", "AC", "ACGT_"]
	var acc := 0.0
	var lens: Array[float] = []
	var segs := []
	for ch in route:
		for e in edges:
			if e.child == ch:
				segs.append(e.pts)
				lens.append(TtDraw.path_length(e.pts))
	var total := 0.0
	for l in lens:
		total += l
	for k in segs.size():
		for p in segs[k]:
			bee_path.append(p)
		acc += lens[k]
		bee_marks.append(acc / total)


func _bud_tops(key: String) -> PackedVector2Array:
	var c: Vector2 = nodes[key]
	var n := ALPHA.length()
	var gap := 40.0
	var w := n * gap + 20.0
	var out := PackedVector2Array()
	for i in n:
		out.append(Vector2(c.x - (n - 1) * gap / 2.0 + i * gap, c.y - 18 - 2))
	return out


func _used(key: String) -> Array:
	var u := []
	for ch in ALPHA:
		var hit := false
		for e in edges:
			if e.from == key and e.letter == ch:
				hit = true
		u.append(hit)
	return u


# ================================================================ tekenen
func _draw_world() -> void:
	var se := TtPal.season(season)
	if page == 0:
		_draw_garden(world, se)
	elif page == 1:
		_draw_plate(world, se)
	else:
		_draw_cast(world, se)


func _draw_garden(ci: CanvasItem, se: Dictionary) -> void:
	TtDraw.root(ci, GROUND, nodes[""] + Vector2(0, 20), se, t)
	# bijenpad-gloed onder de takken die de bij nu volgt
	var bf := fmod(t * 0.16, 1.25)
	for e in edges:
		var depth: int = e.depth
		var w0: float = [24.0, 18.0, 13.0][mini(depth, 2)]
		var w1: float = [16.0, 12.0, 9.0][mini(depth, 2)]
		var on_route: bool = e.child in ["A", "AC", "ACGT_"]
		var glow := Color(TtPal.INFO, 0.22) if on_route and bf < 1.0 else Color(0, 0, 0, 0)
		TtDraw.branch(ci, e.pts, w0, w1, se, e.child.length() * 7 + e.letter.unicode_at(0), t, 2, glow)
	# spooktak: zaadje ACCA_ zou via AC -> knop C groeien
	var tops := _bud_tops("AC")
	var ghost := TtDraw.branch_curve(tops[1], Vector2(556, 160), Vector2.UP, 0.0, 20)
	TtDraw.ghost_branch(ci, ghost, t, Color(1, 1, 1, 0.8))
	TtDraw.ghost_fruit(ci, ghost[ghost.size() - 1], "ACCA_", t)
	TtDraw.letter_tag(ci, TtDraw.path_point(ghost, 0.3), "C", 22, ALPHA, Color(1, 1, 1, 0.9), true)
	for key in nodes:
		var hi := -1
		if key == "AC" and bf < 1.0 and bf > bee_marks[1] - 0.02:
			hi = 2
		TtDraw.knot(ci, nodes[key], ALPHA, _used(key), 40.0, hi, t)
	for e in edges:
		var lt: Vector2 = TtDraw.path_point(e.pts, 0.3 if e.arch else 0.45)
		var lit: bool = e.child in ["A", "AC", "ACGT_"] and bf < 1.0
		TtDraw.letter_tag(ci, lt, e.letter, 26, ALPHA, Color(TtPal.INFO, 0.9) if lit else Color(0, 0, 0, 0))
	for w in leaves:
		var st := 0
		if w == "ACGT_" and bf >= 1.0:
			st = 3
		elif w == "G_":
			st = 0
		TtDraw.fruit(ci, leaves[w], se, w, t + w.length(), st, 24.0, ALPHA, 22)
	# bij 1: zoekt ACGT_ (leest letter per knoest)
	if bf < 1.0:
		var p := TtDraw.path_point(bee_path, bf) + Vector2(0, -42)
		var tg := TtDraw.path_tangent(bee_path, bf)
		var pos := 0
		for m in bee_marks:
			if bf > m - 0.02:
				pos += 1
		TtDraw.bee(ci, p, 1.0, t, 1.0 if tg.x >= 0 else -1.0, 0, "ACGT_", ALPHA, mini(pos, 3))
	else:
		var p2: Vector2 = leaves["ACGT_"] + Vector2(46, -20)
		TtDraw.bee(ci, p2, 1.0, t, -1.0, 2, "ACGT_", ALPHA)
	# bij 2: zoekt GT_, komt bij vrucht G_ uit en twijfelt
	TtDraw.bee(ci, leaves["G_"] + Vector2(84, -120), 1.0, t + 1.3, -1.0, 1, "GT_", ALPHA, -1)


func _draw_hud() -> void:
	var se := TtPal.season(season)
	if page == 0:
		var bar := Rect2(16, 12, 1888, 76)
		hud.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.96), 24, 14, Vector2(0, 6)), bar)
		TtPal.text_l(hud, TtPal.UI_BOLD, Vector2(104, 40), "%s · dag 3" % se.name, 30, TtPal.TEXT)
		TtPal.text_l(hud, TtPal.UI, Vector2(104, 70), "Plant de zaadjes: volg de letters, maak één knoest per vertakking", 20, TtPal.TEXT_DIM)
		TtDraw.sap_meter(hud, Rect2(930, 34, 420, 30), 0.62, t, 0.42, 0.52, "62/100")
		TtDraw.pill(hud, Rect2(1540, 28, 160, 44), "bee", "2 / 5", t)
		TtDraw.pill(hud, Rect2(1716, 28, 170, 44), "star", "2 / 3", t)
		# zaadjes
		var panel := Rect2(24, 108, 290, 470)
		hud.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.97), 24, 14, Vector2(0, 8)), panel)
		TtPal.text_l(hud, TtPal.UI_BOLD, Vector2(48, 140), "Zaadjes", 26, TtPal.TEXT)
		TtPal.text_r(hud, TtPal.UI, Vector2(290, 141), "3 over", 20, TtPal.TEXT_DIM)
		var words := ["ACCA_", "GA_", "TTA_"]
		for i in words.size():
			TtDraw.seed_packet(hud, Vector2(169, 236 + i * 128), words[i], se, Vector2(236, 112), i == 0, t, ALPHA, 28)
		# kaartje met uitleg (papier) + knoppen
		var card := Rect2(1500, 640, 396, 240)
		hud.draw_style_box(TtUi.paper_box(), card)
		TtPal.text_l(hud, TtPal.UI_BOLD, Vector2(1528, 676), "Volgende zet", 26, TtPal.INK)
		TtPal.rich_line(hud, Vector2(1528, 724), [["Plant ", "ui"], ["ACCA_", "mono"], [":", "ui"]], 24, TtPal.INK)
		TtPal.rich_line(hud, Vector2(1528, 766), [["volg ", "ui"], ["A", "mono"], [", ", "ui"], ["C", "mono"], [", dan knop ", "ui"], ["C", "mono"]], 24, TtPal.INK)
		var lw := TtPal.text_l(hud, TtPal.UI, Vector2(1528, 808), "eerste verschil op j = 2: ", 22, TtPal.INK_SOFT)
		TtPal.word(hud, Vector2(1528 + lw + TtPal.word_width(5, 21) / 2.0 + 4, 808), "ACCA_", 21, true, ALPHA, 2, 2, TtPal.WARN)
		TtPal.text_l(hud, TtPal.UI_MED, Vector2(1528, 848), "kost: 1 knoest = 5 knoppen sap", 20, TtPal.INK_SOFT)
	else:
		var tagr := Rect2(24, 18, 640, 56)
		hud.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.95), 28, 10, Vector2(0, 6)), tagr)
		TtDraw.sprout(hud, Vector2(58, 58), 1.3, TtPal.BRAND)
		TtPal.text_l(hud, TtPal.UI_BOLD, Vector2(84, 46), "Trietuin · art preview %d/3 · %s" % [page + 1, se.name], 28, TtPal.TEXT)


func _card(ci: CanvasItem, r: Rect2, title: String, sub: String) -> void:
	ci.draw_style_box(TtPal.sb(Color(TtPal.PAPER, 0.42), 26, 18, Vector2(0, 10)), r)
	TtPal.ring(ci, r, 26, Color(1, 1, 1, 0.55), 2)
	var head := Rect2(r.position + Vector2(14, 14), Vector2(r.size.x - 28, 50))
	ci.draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.94), 18), head)
	TtPal.text_l(ci, TtPal.UI_BOLD, head.position + Vector2(18, 25), title, 26, TtPal.TEXT)
	TtPal.text_r(ci, TtPal.UI, head.end + Vector2(-18, -25), sub, 20, TtPal.TEXT_DIM)


func _draw_plate(ci: CanvasItem, se: Dictionary) -> void:
	# ---------------- Patricia
	var cp := Rect2(24, 90, 600, 572)
	_card(ci, cp, "Zomer · Patricia", "skip, Algoritme 1")
	var rootp := Vector2(180, 586)
	var nodep := Vector2(180, 410)
	var trunk := TtDraw.branch_curve(rootp + Vector2(0, -60), nodep + Vector2(0, 20), Vector2.UP, 0.0, 20)
	TtDraw.root(ci, rootp, nodep + Vector2(0, 20), se, t)
	TtDraw.graft_wrap(ci, trunk, 0.36, 30)
	TtDraw.ghost_beads(ci, trunk, 0.48, 0.97, 5, t)
	var tops := TtDraw.knot(ci, nodep, "AB", [true, true], 40.0, -1, t)
	TtDraw.skip_ring(ci, nodep + Vector2(92, 2), 5, 5, 26.0, t, fmod(t, 4.0) < 2.0)
	var la := TtDraw.branch_curve(tops[0], Vector2(96, 214), Vector2.UP, 0.0, 22, true)
	var lb := TtDraw.branch_curve(tops[1], Vector2(352, 208), Vector2.UP, 0.0, 22, true)
	TtDraw.branch(ci, la, 16, 10, se, 5, t, 2)
	TtDraw.branch(ci, lb, 16, 10, se, 6, t, 2)
	TtDraw.knot(ci, nodep, "AB", [true, true], 40.0, 1 if fmod(t, 4.0) < 2.0 else -1, t)
	TtDraw.letter_tag(ci, TtDraw.path_point(la, 0.3), "A", 24, "AB")
	TtDraw.letter_tag(ci, TtDraw.path_point(lb, 0.3), "B", 24, "AB", Color(TtPal.INFO, 0.9))
	TtDraw.fruit(ci, Vector2(96, 214), se, "AAAAAA_", t, 0, 22.0, "AB", 20)
	TtDraw.fruit(ci, Vector2(352, 208), se, "AAAAABAAAAABC_", t + 1.0, 0, 22.0, "ABC_", 18, 0, 0)
	TtDraw.bee(ci, Vector2(500, 196) + Vector2(sin(t * 9.0) * 4.0, 0), 0.95, t, -1.0, 3, "BBBBBBBBBBBBB_", "ABC_", 5, true, 4)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(324, 640), "skip 5: de bij leest enkel s[5]; de fout blijkt pas bij de vrucht", 18, TtPal.INK)
	# ---------------- Ternary
	var ct := Rect2(644, 90, 560, 572)
	_card(ci, ct, "Herfst · ternary", "kleiner / gelijk / groter")
	var kc := Vector2(924, 530)
	var ka := Vector2(760, 410)
	var kt := Vector2(1088, 410)
	var anc := TtDraw.rank_knot(ci, kc, "C", t, [true, true, true], 32.0, ALPHA, int(fmod(t, 3.0)))
	TtDraw.tendril(ci, anc[0], ka + Vector2(26, 26), TtPal.LESS, t)
	TtDraw.tendril(ci, anc[2], kt + Vector2(-26, 26), TtPal.GREATER, t)
	var eqc := TtDraw.branch_curve(anc[1], Vector2(924, 205), Vector2.UP, 0.0, 18)
	TtDraw.branch(ci, eqc, 16, 11, se, 8, t, 2)
	var a2 := TtDraw.rank_knot(ci, ka, "A", t + 1, [false, true, false], 28.0, ALPHA)
	var t2 := TtDraw.rank_knot(ci, kt, "T", t + 2, [false, true, false], 28.0, ALPHA)
	var eqa := TtDraw.branch_curve(a2[1], Vector2(760, 205), Vector2.UP, 0.0, 14)
	var eqt := TtDraw.branch_curve(t2[1], Vector2(1088, 205), Vector2.UP, 0.0, 14)
	TtDraw.branch(ci, eqa, 13, 9, se, 9, t, 1)
	TtDraw.branch(ci, eqt, 13, 9, se, 10, t, 1)
	TtDraw.fruit(ci, Vector2(760, 205), se, "AG_", t, 0, 20.0, ALPHA, 20)
	TtDraw.fruit(ci, Vector2(924, 205), se, "CAT_", t + 0.6, 1, 20.0, ALPHA, 20)
	TtDraw.fruit(ci, Vector2(1088, 205), se, "TA_", t + 1.2, 0, 20.0, ALPHA, 20)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(924, 640), "lege uitgang = opgekrulde rank (NULL)", 18, TtPal.INK)
	# ---------------- UI-kit
	var cu := Rect2(1224, 90, 672, 572)
	_card(ci, cu, "UI & iconen", "TtUi · TtDraw")
	var y0 := 190.0
	TtDraw.sap_meter(ci, Rect2(1290, y0 - 14, 300, 28), 0.74, t, 0.5, 0.6)
	TtDraw.sap_meter(ci, Rect2(1290, y0 + 34, 300, 28), 0.14, t)
	TtDraw.pill(ci, Rect2(1640, y0 - 22, 120, 42), "star", "3", t)
	TtDraw.pill(ci, Rect2(1770, y0 - 22, 110, 42), "drop", "62", t)
	TtDraw.pill(ci, Rect2(1640, y0 + 28, 120, 42), "bee", "4/5", t)
	TtDraw.pill(ci, Rect2(1770, y0 + 28, 110, 42), "leaf", "12", t)
	for i in 3:
		TtDraw.star_slot(ci, Vector2(1300 + i * 70, 320), 28, i < 2, sin(t * 2.0 + i) * 0.05)
	for i in ALPHA.length():
		TtDraw.letter_tag(ci, Vector2(1530 + i * 46, 320), ALPHA[i], 26, ALPHA)
	TtDraw.shears(ci, Vector2(1300, 392), 0.8, 0.5 + 0.5 * sin(t * 3.0))
	TtDraw.drop(ci, Vector2(1376, 396), 18)
	TtDraw.magnifier(ci, Vector2(1434, 386), 16)
	TtDraw.sprout(ci, Vector2(1500, 412), 1.6)
	TtDraw.star(ci, Vector2(1560, 394), 20, TtPal.STAR)
	TtDraw.tag(ci, Vector2(1650, 394), "skip 3", 20, TtPal.RAFFIA, TtPal.RAFFIA_DARK)
	TtDraw.be_tag(ci, Vector2(1752, 394), 6, 8)
	TtDraw.be_tag(ci, Vector2(1830, 394), 0, 1, true)
	for m in 4:
		TtDraw.bee(ci, Vector2(1316 + m * 150, 456), 0.8, t + m, 1.0, m, "", ALPHA)
	TtPal.text_c(ci, TtPal.UI, Vector2(1316, 492), "vliegt", 18, TtPal.INK)
	TtPal.text_c(ci, TtPal.UI, Vector2(1466, 492), "twijfelt", 18, TtPal.INK)
	TtPal.text_c(ci, TtPal.UI, Vector2(1616, 492), "gevonden", 18, TtPal.INK)
	TtPal.text_c(ci, TtPal.UI, Vector2(1766, 492), "weggejaagd", 18, TtPal.INK)
	TtDraw.seed_packet(ci, Vector2(1360, 618), "ACGT_", se, Vector2(220, 70), false, t, ALPHA, 24)
	TtDraw.pill(ci, Rect2(1490, 596, 200, 44), "leaf", se.topic, t)
	# ---------------- Suffixboom + slinger + speurneus
	var cs := Rect2(24, 680, 1872, 384)
	_card(ci, cs, "Winter · suffixboom van acacacgt_", "boogpaar (b,e) wijst in de slinger")
	var hl := int(fmod(t / 2.0, 3.0))
	var ranges := [[0, 1], [6, 8], [2, 4]]
	var b: int = ranges[hl][0]
	var e: int = ranges[hl][1]
	TtDraw.garland(ci, Vector2(120, 790), "acacacgt_", 66.0, se, t, b, e, 16.0, "acgt_")
	# klein stukje suffixboom: wortel met 5 bogen (Figuur 19)
	var sr := Vector2(1060, 1010)
	var kids := [[Vector2(820, 850), 0, 1], [Vector2(960, 830), 1, 1], [Vector2(1100, 820), 6, 8], [Vector2(1220, 840), 7, 8], [Vector2(1330, 870), 8, 8]]
	var stops := TtDraw.knot(ci, sr, "acgt_", [true, true, true, true, true], 30.0, -1, t)
	for i in kids.size():
		var k: Array = kids[i]
		var pts := TtDraw.branch_curve(stops[i], k[0], Vector2.UP, 0.0, 16)
		TtDraw.branch(ci, pts, 13, 9, se, 20 + i, t, 1, Color(TtPal.STAR, 0.3) if k[1] == b and k[2] == e else Color(0, 0, 0, 0))
	TtDraw.knot(ci, sr, "acgt_", [true, true, true, true, true], 30.0, -1, t)
	for i in kids.size():
		var k: Array = kids[i]
		var pts := TtDraw.branch_curve(stops[i], k[0], Vector2.UP, 0.0, 16)
		TtDraw.be_tag(ci, TtDraw.path_point(pts, 0.62), k[1], k[2], k[1] == b and k[2] == e)
		ci.draw_circle(k[0], 8, TtPal.BUD_DARK, true, -1, true)
		ci.draw_circle(k[0] + Vector2(-1, -1), 6, TtPal.BUD, true, -1, true)
	# speurneus met vraag
	TtDraw.hedgehog(ci, Vector2(1600, 1030), 1.25, t, -1.0, 1)
	var br := Rect2(1420, 760, 452, 128)
	TtDraw.bubble(ci, br, Vector2(1600, 935))
	TtPal.rich_line(ci, Vector2(1446, 806), [["Komt ", "ui"], ["cac", "mono"], [" voor?", "ui"]], 28, TtPal.INK, true, "acgt_")
	TtPal.rich_line(ci, Vector2(1446, 852), [["Hoe vaak, en waar?", "ui"]], 24, TtPal.INK_SOFT)


func _draw_cast(ci: CanvasItem, se: Dictionary) -> void:
	# ---------------- personages
	var cc := Rect2(24, 90, 1100, 476)
	_card(ci, cc, "Personages", "bij · wesp · korf · Uil · Egel · hond · vuurvliegje")
	TtDraw.bee(ci, Vector2(110, 230), 1.2, t, 1.0, 0, "ACGT_", ALPHA, 2)
	var wr := clampf(0.5 + 0.8 * sin(t * 1.2), 0.0, 1.0)
	TtDraw.bee(ci, Vector2(300, 230), 1.2, t + 0.4, -1.0, 3 if wr > 0.5 else 0, "CATT_", ALPHA, -1, true, -1, wr)
	TtDraw.magnifier(ci, Vector2(300 + 46 * (1.0 - wr), 200), 26, 0.9)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(205, 352), "bij  ·  wesp (ontmaskerd)", 18, TtPal.INK)
	TtDraw.hive(ci, Vector2(510, 330), 1.0, t, true, fmod(t, 5.0) > 3.5, 0.5 + 0.5 * sin(t * 3.0))
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(560, 352), "korf + koningin", 18, TtPal.INK)
	TtDraw.owl(ci, Vector2(780, 300), 1.2, t, 0.5 + 0.5 * sin(t * 12.0))
	var ob := Rect2(840, 160, 270, 92)
	TtDraw.bubble(ci, ob, Vector2(830, 270))
	TtPal.rich_line(ci, Vector2(860, 192), [["Op diepte 2 lees", "ui"]], 22, TtPal.INK)
	TtPal.rich_line(ci, Vector2(860, 226), [["je letter 2: ", "ui"], ["G", "mono"], [".", "ui"]], 22, TtPal.INK)
	TtDraw.hedgehog(ci, Vector2(170, 520), 1.0, t, 1.0, 2)
	TtDraw.dog(ci, Vector2(400, 528), 1.2, t, 1.0, 1 if fmod(t, 4.0) < 2.0 else 0)
	TtDraw.firefly(ci, Vector2(620, 470) + Vector2(sin(t * 1.3) * 10, cos(t * 1.7) * 6), 1.4, t, 3)
	TtDraw.compost(ci, Vector2(850, 540), 1.0)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(620, 548), "vuurvliegje (p̄, x̄ = 3)", 18, TtPal.INK)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(1000, 548), "composthoop", 18, TtPal.INK)
	# ---------------- werkbank
	var cw := Rect2(1144, 90, 752, 476)
	_card(ci, cw, "Werkbank", "lint · vergelijkingslint · hoplint")
	TtDraw.ribbon(ci, Vector2(1180, 210), "AAGCGA_", 52.0, 32, 2, 2, -1, TtPal.WARN, ALPHA, true, true, t)
	TtDraw.compare_ribbon(ci, Vector2(1180, 352), "AAGTT_", "AAGCGA_", 2, 3, 3, 52.0, 30, ALPHA, t)
	TtDraw.ribbon(ci, Vector2(1180, 500), "BBBBBBBBBBBBB_", 46.0, 26, 11, -1, -1, TtPal.WARN, "ABC_", true, true, t, [[0, 5], [5, 11]])
	# ---------------- seizoenkaart, rapport, windrij
	var cm := Rect2(24, 586, 1100, 476)
	_card(ci, cm, "Seizoenkaart · rapport · windrij", "potten, sterbloemen, kaartjes")
	TtDraw.pot(ci, Vector2(110, 760), "1-1", 3, se, false, t)
	TtDraw.pot(ci, Vector2(240, 760), "1-2", 2, se, false, t, true)
	TtDraw.pot(ci, Vector2(370, 760), "1-3", 0, se, true, t)
	var open := clampf(fmod(t, 3.0) / 0.6, 0.0, 1.0)
	for i in 3:
		TtDraw.star_flower(ci, Vector2(520 + i * 90, 740), 30, clampf(open * 3.0 - i, 0.0, 1.0) * (1.0 + 0.1 * sin(PI * clampf(open * 3.0 - i, 0.0, 1.0))), t)
	TtDraw.honey_pot(ci, Vector2(860, 720), 34)
	TtDraw.pill(ci, Rect2(910, 700, 180, 44), "honey", "120", t)
	TtDraw.stamp(ci, Vector2(960, 800), "OPGELOST", 30)
	var kinds := [["seed", "AAGCGA_"], ["bee", "CAT_"], ["wasp", "CATT_"], ["shears", "TA_"], ["loupe", "cac"], ["pearl", "g"]]
	for i in kinds.size():
		TtDraw.card(ci, Vector2(110 + i * 150, 950), kinds[i][0], kinds[i][1], t, i == 0, se)
	# ---------------- winter: verdachten
	var cv := Rect2(1144, 586, 752, 476)
	_card(ci, cv, "Winter · verdachten & telbadges", "kleur én vorm")
	for i in 4:
		TtDraw.suspect_mark(ci, Vector2(1200 + i * 175, 682), i, 13.0)
		TtPal.text_l(ci, TtPal.UI_BOLD, Vector2(1222 + i * 175, 682), TtPal.SUSPECTS[i].name, 22, TtPal.INK)
	var stem := TtDraw.branch_curve(Vector2(1300, 1040), Vector2(1300, 900), Vector2.UP, 0.0, 16)
	TtDraw.branch(ci, stem, 16, 12, se, 31, t, 1)
	TtDraw.edge_pearls(ci, stem, "cac", 0.2, 0.8)
	TtDraw.count_badge(ci, Vector2(1262, 900), 2)
	var lb := TtDraw.branch_curve(Vector2(1300, 900), Vector2(1450, 850), Vector2.UP, 0.0, 16, true)
	TtDraw.branch(ci, lb, 11, 8, se, 32, t, 1)
	TtDraw.fruit(ci, Vector2(1450, 850), se, "cacgt_", t, 0, 20.0, "acgt_", 20, -1, -1, true, 0)
	var lb2 := TtDraw.branch_curve(Vector2(1300, 900), Vector2(1640, 860), Vector2.UP, 0.0, 16, true)
	TtDraw.branch(ci, lb2, 11, 8, se, 33, t, 1)
	TtDraw.fruit(ci, Vector2(1640, 860), se, "cacag_", t + 1.0, 0, 20.0, "acgt_", 20, -1, -1, true, 1)
	TtDraw.count_badge(ci, Vector2(1850, 1030), 7, TtPal.PANEL_HI)
	TtPal.text_r(ci, TtPal.UI, Vector2(1828, 1030), "telbadge = bladeren onder het punt", 20, TtPal.INK)




func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	add_child(p)
	return p


func _sfx(name_: String, vol_db := 0.0) -> void:
	sfx.stream = load(TtPal.ASSETS + "sfx/%s.wav" % name_)
	sfx.volume_db = vol_db
	sfx.play()


func _exit_tree() -> void:
	for p in [music, bloom, ambience, buzz, sfx]:
		if p:
			p.stop()
			p.stream = null
