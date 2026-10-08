class_name CustomerView
extends Node2D
## Eén klant (oorsprong = voeten). Ballon met de gevraagde hashwaarde + geduldsbalk.
## Varianten: hoed, pet, rugzak, staart. Emoties: neutraal, blij (boogjes-ogen), boos (wenkbrauwen + blos).

var cid := -1
var hv := 0
var n := 5
var chips := 0
var knip := 0
var patience := 1.0         # 0..1
var mood := 0               # -1 boos, 0 neutraal, 1 blij
var at_desk := false
var focus := false
var balloon := 0.0          # 0..1 pop
var shake := 0.0            # hoofdschudden
var variant := 0
var skin := Color.WHITE
var cloth := Color.WHITE
var hair := Color("#4A2E1F")
var _t := 0.0


func setup(id_: int, hv_: int, n_: int) -> CustomerView:
	cid = id_
	hv = hv_
	n = n_
	var rng := RandomNumberGenerator.new()
	rng.seed = id_ * 7919 + hv_
	variant = rng.randi_range(0, 3)
	skin = Pal.SKIN[rng.randi_range(0, Pal.SKIN.size() - 1)]
	cloth = Pal.CLOTHES[rng.randi_range(0, Pal.CLOTHES.size() - 1)]
	hair = [Color("#4A2E1F"), Color("#1F1A17"), Color("#C9883B"), Color("#7A3B2E")][rng.randi_range(0, 3)]
	_t = rng.randf() * 10.0
	return self


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var tap := 0.0
	if patience < 0.3 and at_desk:
		tap = absf(sin(_t * 10.0)) * 4.0   # tikt met zijn voet
	var bob := sin(_t * 3.2) * 4.0
	var sx := sin(shake * TAU * 3.0) * 10.0 * (1.0 - shake) if shake > 0.0 else 0.0
	# schaduw
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 60, Color(0, 0, 0, 0.25), true, -1, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if variant == 2:   # rugzak
		draw_style_box(Pal.sb(cloth.darkened(0.35), 20), Rect2(Vector2(-66, -150 + bob), Vector2(40, 90)))
	var body := Rect2(Vector2(-54, -160 + bob), Vector2(108, 160 - bob))
	draw_style_box(Pal.sb(cloth, 48, 10, Vector2(0, 6)), body)
	draw_style_box(Pal.sb(cloth.lightened(0.15), 14), Rect2(body.position + Vector2(22, 18), Vector2(64, 18)))
	draw_rect(Rect2(Vector2(-30, -6 - tap), Vector2(22, 6)), Pal.OUTLINE)
	var hc := Vector2(sx, -206 + bob)
	if variant == 3:   # staart
		draw_circle(hc + Vector2(40, 10), 16, hair, true, -1, true)
	draw_circle(hc, 46, Pal.OUTLINE, true, -1, true)
	draw_circle(hc, 42, skin, true, -1, true)
	draw_arc(hc + Vector2(0, -6), 40, PI * 1.05, PI * 1.95, 24, hair, 18, true)
	match variant:
		0:   # hoed
			draw_style_box(Pal.sb(Pal.PANEL_LO, 8), Rect2(hc + Vector2(-56, -40), Vector2(112, 14)))
			draw_style_box(Pal.sb(Pal.PANEL_LO, 14), Rect2(hc + Vector2(-34, -78), Vector2(68, 44)))
			draw_rect(Rect2(hc + Vector2(-34, -46), Vector2(68, 8)), cloth)
		1:   # pet
			draw_arc(hc + Vector2(0, -8), 42, PI, TAU, 24, cloth.darkened(0.2), 22, true)
			draw_style_box(Pal.sb(cloth.darkened(0.3), 6), Rect2(hc + Vector2(10, -24), Vector2(52, 10)))
	# ogen
	var blink := 1.0 if fmod(_t, 3.1) > 0.12 else 0.15
	for ex in [-15.0, 15.0]:
		var ep := hc + Vector2(ex, 4)
		if mood > 0:
			draw_arc(ep + Vector2(0, 3), 7, PI * 1.1, PI * 1.9, 10, Pal.INK, 4, true)
		else:
			draw_set_transform(ep, 0, Vector2(1, blink))
			draw_circle(Vector2.ZERO, 5.5, Pal.INK, true, -1, true)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if mood < 0:
			var s := -1.0 if ex < 0 else 1.0
			draw_line(ep + Vector2(-9 * s, -14), ep + Vector2(8 * s, -9), Pal.INK, 4, true)
	# mond
	if mood > 0:
		draw_arc(hc + Vector2(0, 12), 14, 0.15, PI - 0.15, 16, Pal.INK, 5, true)
	elif mood < 0:
		draw_arc(hc + Vector2(0, 26), 12, PI + 0.3, TAU - 0.3, 12, Pal.INK, 4, true)
	elif patience < 0.3:
		draw_line(hc + Vector2(-10, 20), hc + Vector2(10, 20), Pal.INK, 4, true)
	else:
		draw_arc(hc + Vector2(0, 12), 13, 0.25, PI - 0.25, 16, Pal.INK, 4, true)
	var blush := 0.35 if mood >= 0 else 0.8
	draw_circle(hc + Vector2(-26, 14), 7, Color(Pal.HEART if mood >= 0 else Pal.ERR, blush), true, -1, true)
	draw_circle(hc + Vector2(26, 14), 7, Color(Pal.HEART if mood >= 0 else Pal.ERR, blush), true, -1, true)
	# ballon
	if balloon > 0.01 and at_desk:
		var bs := balloon
		var bc := Vector2(sx * 0.5, -330 + bob * 0.5)
		draw_set_transform(bc, 0, Vector2(bs, bs))
		var br := Rect2(-140, -44, 280, 88)
		draw_style_box(Pal.sb(Pal.LABEL, 24, 10, Vector2(0, 6)), br)
		draw_colored_polygon(PackedVector2Array([Vector2(-20, 42), Vector2(16, 42), Vector2(-10, 68)]), Pal.LABEL)
		var w := Pal.bits(self, Vector2(-14, -6), HashUtil.bits(hv, n), 36, chips, knip)
		Pal.text_c(self, Pal.UI_BOLD, Vector2(-14 + w / 2.0 + 16, -6), "?", 40, Pal.INK)
		var pb := Rect2(br.position.x + 22, br.end.y - 18, br.size.x - 44, 8)
		draw_style_box(Pal.sb(Color(Pal.INK, 0.12), 4), pb)
		var pc := Pal.OK if patience > 0.3 else Pal.ERR
		draw_style_box(Pal.sb(pc, 4), Rect2(pb.position, Vector2(pb.size.x * clampf(patience, 0.0, 1.0), pb.size.y)))
		if focus:
			Pal.ring(self, br.grow(8), 30, Color(Pal.INFO, 0.6 + 0.4 * sin(_t * 6.0)), 5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
