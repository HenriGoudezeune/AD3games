class_name HudView
extends Node2D
## HUD-balk bovenaan (GDD §7.1): [huisje HubNav] · pauze · dag · harten · munten · ritten L/S · ? · combo.

const BAR := Rect2(16, 8, 1888, 60)
const HOME_OFFSET := Vector2(14, 2)        # HubNav-huisje links in de balk (set_context corner_offset)
const PAUSE_RECT := Rect2(170, 16, 44, 44)
const HELP_RECT := Rect2(1640, 16, 44, 44)  # "?" = gids (F1)
const COIN_POS := Vector2(930, 38)
const TRIPS_POS := Vector2(1130, 38)

var day_label := "DAG 1"
var day_title := ""
var rep := 5
var rep_max := 5
var coins_shown := 0.0
var coins := 0
var reads := 0
var writes := 0
var opt_r := -1
var opt_w := -1
var combo := 1
var show_combo := true
var show_rep := true
var time_left := -1.0
var _coin_pop := 1.0
var _r_pop := 1.0
var _w_pop := 1.0
var _combo_pop := 1.0
var _pause_hover := 0.0
var _help_pulse := 0.0
var _broken: Array = []   # [{x, t}]
var _t := 0.0
var _zero_float := 0.0
var _coin_tw: Tween


func _process(delta: float) -> void:
	_t += delta
	for b in _broken:
		b.t += delta
	_broken = _broken.filter(func(b): return b.t < 0.7)
	queue_redraw()


func set_coins(v: int, animate := true) -> void:
	coins = v
	if not animate:
		coins_shown = v
		return
	if _coin_tw:
		_coin_tw.kill()
	_coin_tw = create_tween()
	_coin_tw.tween_property(self, "coins_shown", float(v), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func pulse_coins() -> void:
	_coin_pop = 1.25
	create_tween().tween_property(self, "_coin_pop", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_io(r: int, w: int) -> void:
	if r != reads:
		_r_pop = 1.35
		create_tween().tween_property(self, "_r_pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if w != writes:
		_w_pop = 1.35
		create_tween().tween_property(self, "_w_pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reads = r
	writes = w


func set_combo(c: int) -> void:
	if c != combo:
		_combo_pop = 1.3 if c > combo else 0.8
		create_tween().tween_property(self, "_combo_pop", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	combo = c


func set_rep(r: int) -> void:
	if r < rep:
		for k in range(r, rep):
			_broken.append({"x": 680.0 + k * 38, "t": 0.0})
	rep = r


## "0"-floater naast de rittenteller: verdubbelen kost geen schijf-I/O (#17).
func zero_trips() -> void:
	_zero_float = 1.0
	create_tween().tween_property(self, "_zero_float", 0.0, 1.0)


func hit_pause(p: Vector2) -> bool:
	return PAUSE_RECT.grow(6).has_point(p)


func hit_help(p: Vector2) -> bool:
	return HELP_RECT.grow(6).has_point(p)


## Laat de "?" even oplichten (bv. na een tutorial: "hier vind je dit terug").
func pulse_help() -> void:
	_help_pulse = 1.0
	create_tween().tween_property(self, "_help_pulse", 0.0, 1.6)


func _draw() -> void:
	var bar := BAR
	draw_style_box(Pal.sb(Color(Pal.PANEL, 0.97), 22, 14, Vector2(0, 6)), bar)
	var cy := bar.get_center().y
	draw_style_box(Pal.sb(Pal.PANEL_HI.lightened(0.1 * _pause_hover), 14), PAUSE_RECT)
	draw_texture_rect(Juice.icon("pause"), PAUSE_RECT.grow(-10), false, Pal.TEXT)
	# "?" = gids
	var qc := HELP_RECT.get_center()
	if _help_pulse > 0.01:
		draw_circle(qc, 22 + 16 * (1.0 - _help_pulse), Color(Pal.WARN, 0.5 * _help_pulse), true, -1, true)
	draw_circle(qc, 22, Pal.WARN if _help_pulse > 0.01 else Pal.PANEL_HI, true, -1, true)
	Pal.text_c(self, Pal.UI_BOLD, qc + Vector2(0, 1), "?", 30, Pal.INK if _help_pulse > 0.01 else Pal.TEXT)
	var x := PAUSE_RECT.end.x + 16
	x += Pal.text_l(self, Pal.UI_BOLD, Vector2(x, cy), day_label, 28, Pal.TEXT) + 10
	if day_title != "":
		Pal.text_l(self, Pal.UI, Vector2(x, cy), "· " + day_title, 24, Pal.TEXT_DIM)
	# harten
	if show_rep:
		for k in rep_max:
			var hc := Vector2(680 + k * 38, cy)
			if k < rep:
				var bob := 1.0 + 0.06 * maxf(0.0, sin(_t * 3.0 - k * 0.5)) * (1.0 if rep <= 2 else 0.0)
				Pal.heart(self, hc, 14 * bob, Pal.HEART)
			else:
				Pal.heart(self, hc, 14, Color(1, 1, 1, 0.15))
		for b in _broken:
			var f: float = b.t / 0.7
			var hc2 := Vector2(b.x, cy)
			for side in [-1.0, 1.0]:
				var off := Vector2(side * (4 + 30 * f), 50 * f * f)
				draw_set_transform(hc2 + off, side * f * 1.2, Vector2.ONE)
				var poly := PackedVector2Array([Vector2(0, -8), Vector2(side * 15, -10), Vector2(side * 14, 2), Vector2(0, 13)])
				draw_colored_polygon(poly, Color(Pal.HEART, 1.0 - f))
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# munten
	Pal.coin(self, COIN_POS, 17 * _coin_pop)
	Pal.text_l(self, Pal.UI_BOLD, Vector2(COIN_POS.x + 26, cy), "%d" % int(round(coins_shown)), int(28 * _coin_pop), Pal.COIN)
	# ritten
	Pal.truck(self, TRIPS_POS)
	x = TRIPS_POS.x + 34
	x += _pop_text(Vector2(x, cy), "L %d" % reads, _r_pop) + 14
	x += _pop_text(Vector2(x, cy), "S %d" % writes, _w_pop) + 12
	if opt_r >= 0:
		Pal.text_l(self, Pal.UI, Vector2(x, cy + 1), "(opt %d/%d)" % [opt_r, opt_w], 20, Pal.TEXT_DIM)
	if _zero_float > 0.01:
		Pal.text_outline_c(self, Pal.UI_BOLD, Vector2(TRIPS_POS.x, cy + 34 - 30 * (1.0 - _zero_float)), "0 ritten", 22, Color(Pal.OK, _zero_float), 6)
	if time_left >= 0.0:
		var tr := Rect2(1480, bar.position.y + 8, 130, 44)
		draw_style_box(Pal.sb(Pal.BG_DEEP, 22), tr)
		Pal.text_c(self, Pal.MONO, tr.get_center(), "%d:%02d" % [int(time_left) / 60, int(time_left) % 60], 26, Pal.TEXT if time_left > 10 else Pal.ERR)
	# combo
	if show_combo:
		var cr := Rect2(bar.end.x - 200, bar.position.y + 8, 188, 44)
		var active := combo > 1
		var cc := Pal.BIT_COLORS[0] if active else Pal.BG_DEEP
		if combo >= 5:
			cc = Pal.COIN.lerp(Color.WHITE, 0.2 + 0.2 * sin(_t * 10.0))
		var cs := _combo_pop
		var crr := Rect2(cr.get_center() - cr.size * cs / 2.0, cr.size * cs)
		draw_style_box(Pal.sb(cc, 22), crr)
		Pal.text_c(self, Pal.UI_BOLD, crr.get_center(), "COMBO ×%d" % combo, int(26 * cs), Pal.INK if active else Pal.TEXT_DIM)


func _pop_text(lm: Vector2, s: String, pop: float) -> float:
	var size := int(28 * pop)
	var w := Pal.UI_BOLD.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var w2 := Pal.UI_BOLD.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	Pal.text_l(self, Pal.UI_BOLD, lm - Vector2((w2 - w) / 2.0, 0), s, size, Pal.TEXT if pop < 1.05 else Pal.WARN)
	return w
