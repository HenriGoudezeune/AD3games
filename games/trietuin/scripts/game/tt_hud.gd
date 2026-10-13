class_name TtHud
extends Control
## Bovenbalk van de tuin (GDD §4.3): pauze, seizoen + levelnaam + notasverwijzing, windrij (komende kaarten),
## sapbuis (geheugen), honing, klok/geduld (zwermmodus). Getekend in code; de pauzeknop is een echte knop.

signal pause_pressed

var title := ""
var sub := ""
var season := 0
var letters := "ACGT_"
var sap_used := 0
var sap_shown := 0.0
var sap_budget := 0
var sap_scale := 0          # noemer van de buis (budget of piek)
var sap_loss := 0.0         # amber "verlies"-streep (j te laat)
var honey := 0
var honey_shown := 0.0
var combo := 0
var queue: Array = []       # [{kind, word, wasp}]
var clock := -1.0           # zwerm: resterende tijd / of verstreken tijd
var clock_label := ""
var lives := -1             # vrije tuin: missers over
var t := 0.0
var _honey_pop := 1.0
var _sap_pop := 1.0
var _pause: Button
var _wind_pop := 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause = TtUi.icon_button("pause", TtUi.Kind.SECONDARY, 58)
	_pause.position = Vector2(26, 21)
	_pause.focus_mode = Control.FOCUS_NONE
	_pause.pressed.connect(func(): pause_pressed.emit())
	add_child(_pause)


func set_sap(used: int, budget: int, delta := 0) -> void:
	if budget >= 1000000:
		budget = 0
	sap_used = used
	sap_budget = budget
	if budget > 0:
		sap_scale = budget
	else:
		sap_scale = maxi(sap_scale, int(ceil(used * 1.25 / 10.0)) * 10)
	if delta != 0:
		_sap_pop = 1.15
		var tw := create_tween()
		tw.tween_property(self, "_sap_pop", 1.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_honey(total: int) -> void:
	honey = total
	_honey_pop = 1.3
	var tw := create_tween()
	tw.tween_property(self, "_honey_pop", 1.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_queue(q: Array) -> void:
	queue = q
	_wind_pop = 0.6
	create_tween().tween_property(self, "_wind_pop", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Wereldpositie van de sapbuis (voor druppels die naar de boom vliegen).
func sap_anchor() -> Vector2:
	return Vector2(1300, 50)


func honey_anchor() -> Vector2:
	return Vector2(1640, 50)


func _process(delta: float) -> void:
	t += delta
	sap_shown = lerpf(sap_shown, float(sap_used), 1.0 - exp(-delta * 6.0))
	honey_shown = lerpf(honey_shown, float(honey), 1.0 - exp(-delta * 8.0))
	if absf(honey_shown - honey) < 0.5:
		honey_shown = honey
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(16, 12, 1888, 76)
	draw_style_box(TtPal.sb(Color(TtPal.PANEL, 0.96), 24, 14, Vector2(0, 6)), bar)
	# titel
	var se := TtPal.season(mini(season, 3))
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(100, 38), title, 28, TtPal.TEXT)
	TtPal.text_l(self, TtPal.UI, Vector2(100, 68), sub, 19, TtPal.TEXT_DIM)
	# windrij
	var wx := 700.0
	var wy := 50.0
	if not queue.is_empty():
		TtPal.text_l(self, TtPal.UI_BOLD, Vector2(wx - 8, 26), "wind", 16, TtPal.TEXT_DIM)
	var x := wx + 40.0
	var shown := 0
	for c in queue:
		if shown >= 5 or x + _chip_w(c) > 1190.0:
			break
		var w := _wind_chip(Vector2(x, wy), c, shown == 0)
		x += w + 10.0
		shown += 1
	if queue.size() > shown:
		TtPal.text_l(self, TtPal.UI_BOLD, Vector2(x, wy), "+%d" % (queue.size() - shown), 20, TtPal.TEXT_DIM)
	# sapbuis
	var sr := Rect2(1250, 33, 250, 30)
	var scale_ := maxf(1.0, float(sap_scale))
	var frac := clampf(1.0 - sap_shown / scale_, 0.0, 1.0)
	draw_set_transform(sr.get_center(), 0.0, Vector2(_sap_pop, _sap_pop))
	TtDraw.sap_meter(self, Rect2(-sr.size / 2.0, sr.size), frac, t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var lab := "%d/%d" % [sap_used, sap_budget] if sap_budget > 0 else "%d" % sap_used
	TtPal.text_l(self, TtPal.MONO_B, Vector2(sr.end.x + 12, sr.get_center().y - 8), lab, 20, TtPal.TEXT)
	TtPal.text_l(self, TtPal.UI, Vector2(sr.end.x + 12, sr.get_center().y + 14), "sap gebruikt", 14, TtPal.TEXT_DIM)
	# honing
	var hr := Rect2(1640, 26, 150, 46)
	draw_set_transform(hr.get_center(), 0.0, Vector2(_honey_pop, _honey_pop))
	_honey_pill(Rect2(-hr.size / 2.0, hr.size), "%d" % int(round(honey_shown)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if combo > 1:
		var cr := Rect2(1800, 26, 92, 46)
		draw_style_box(TtPal.sb(TtPal.STAR, 23), cr)
		TtPal.text_c(self, TtPal.UI_BOLD, cr.get_center(), "×%d" % combo, 24, TtPal.INK)
	elif clock_label != "":
		var cr2 := Rect2(1800, 26, 92, 46)
		draw_style_box(TtPal.sb(TtPal.PANEL_LO, 23), cr2)
		TtPal.text_c(self, TtPal.MONO_B, cr2.get_center(), clock_label, 20, TtPal.TEXT)
	if lives >= 0:
		for i in 3:
			var c := Vector2(1830 + i * 26 - 40, 102)
			draw_circle(c, 10, TtPal.ERR if i < lives else Color(TtPal.PANEL_LO, 0.9), true, -1, true)


func _honey_pill(r: Rect2, txt: String) -> void:
	draw_style_box(TtPal.sb(TtPal.PANEL_LO, int(r.size.y / 2)), r)
	var ic := Vector2(r.position.x + 24, r.get_center().y)
	TtDraw.honey_pot(self, ic + Vector2(0, 1), 15)
	TtPal.text_l(self, TtPal.UI_BOLD, Vector2(ic.x + 22, r.get_center().y), txt, 26, TtPal.TEXT)


func _chip_w(c: Dictionary) -> float:
	var word: String = c.get("word", "")
	if word == "":
		return 160.0
	return 44.0 + TtPal.word_width(mini(word.length(), 12), 18) + 16 + 40


func _wind_chip(p: Vector2, c: Dictionary, first: bool) -> float:
	var word: String = c.get("word", "")
	var k: String = c.get("kind", "seed")
	var ms := 18
	var ww := TtPal.word_width(mini(word.length(), 12), ms) if word != "" else 0.0
	var label := k
	match k:
		"prune":
			label = "knip"
		"patricify":
			label = "snoei"
		"ternarify":
			label = "rankknopen"
		"beds":
			label = "bedden"
		"ukkonen":
			label = "slinger"
	var w := 44.0 + (ww if word != "" else TtPal.UI_BOLD.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x) + 16
	var s := _wind_pop if first else 1.0
	var r := Rect2(p.x, p.y - 20, w, 40)
	draw_set_transform(r.get_center(), 0.0, Vector2(s, s))
	var lr := Rect2(-r.size / 2.0, r.size)
	var arrived: bool = c.get("arrived", false)
	draw_style_box(TtPal.sb(TtPal.PANEL_LO if not (first or arrived) else TtPal.PANEL_HI, 14), lr)
	if c.has("pat"):
		var pf: float = c.pat
		draw_style_box(TtPal.sb(TtPal.OK.lerp(TtPal.ERR, 1.0 - pf), 3), Rect2(lr.position.x + 8, lr.end.y - 7, (lr.size.x - 16) * pf, 5))
	var ic := Vector2(lr.position.x + 22, 0)
	match k:
		"seed":
			TtDraw.sprout(self, ic + Vector2(0, 8), 1.0, TtPal.BRAND)
		"bee":
			TtDraw.bee(self, ic, 0.45, t, 1.0, 0, "", letters)
		"prune", "patricify":
			TtDraw.shears(self, ic, 0.42, 0.5)
		"ask":
			TtDraw.magnifier(self, ic + Vector2(-2, -2), 9)
		"suffix", "ukkonen":
			draw_circle(ic, 10, TtPal.STAR, true, -1, true)
			draw_circle(ic, 7, TtPal.PAPER, true, -1, true)
		_:
			TtDraw.leaf(self, ic + Vector2(-8, 4), -0.6, 18, TtPal.BRAND)
	if word != "":
		var shown := word if word.length() <= 12 else word.substr(0, 11) + "…"
		TtPal.word(self, Vector2(lr.position.x + 44 + ww / 2.0, 0), shown, ms, true, letters)
	else:
		TtPal.text_l(self, TtPal.UI_BOLD, Vector2(lr.position.x + 42, 0), label, 18, TtPal.TEXT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return w
