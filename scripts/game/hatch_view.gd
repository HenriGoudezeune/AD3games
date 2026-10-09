class_name HatchView
extends Node2D
## Eén luik in de sorteermuur (= één vakje van de pointerarray). Oorsprong = midden van het luik.

var idx := 0
var code := ""          # label, bv. "01"
var size := Vector2(124, 140)
var col := Color.WHITE  # kleur van het rek waar de buis naartoe gaat
var flap := 0.0         # 0 dicht, 1 open (80°)
var dim := 1.0          # 1 normaal, 0.3 gedimd (typbuffer)
var glow := 0.0         # doel-gloed (OK)
var warn := 0.0         # affordance (WARN)
var hover := 0.0
var new_bit_pop := 1.0  # schaal van de laatste bit (pop bij verdubbelen)
var label_alpha := 1.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func label_size() -> int:
	var by_h := int(size.y * (0.62 if size.y < 84 else 0.25))
	return clampi(mini(28 if code.length() <= 4 else 22, by_h), 18, 28)


func compact() -> bool:
	return size.y < 84


func hole_rect() -> Rect2:
	var r := Rect2(-size / 2.0, size)
	if compact():
		var ls := label_size()
		var lw := Pal.bits_width(code.length(), ls, 0) + 16
		var hx := r.position.x + lw + 4
		return Rect2(hx, r.position.y + 4, maxf(16.0, r.end.x - 6 - hx), r.size.y - 8)
	return Rect2(r.position.x + 14, r.position.y + 56, r.size.x - 28, r.size.y - 68)


func _draw() -> void:
	var r := Rect2(-size / 2.0, size)
	var rad := int(clampf(size.y * 0.2, 6, 18))
	var a := dim
	var s := 1.0 + 0.05 * hover + 0.03 * glow * sin(_t * 6.0)
	if s != 1.0:
		draw_set_transform(Vector2.ZERO, 0, Vector2(s, s))
	var frame := Pal.sbn(Color(Pal.PANEL_LO, a), rad)
	frame.border_color = Color(col, a)
	frame.set_border_width_all(4 if size.y > 40 else 3)
	draw_style_box(frame, r)
	var hr := hole_rect()
	draw_style_box(Pal.sb(Color(Pal.HOLE, a), int(clampf(hr.size.y * 0.2, 4, 12))), hr)
	# klepje: scharniert bovenaan; open = korter (perspectief van 0..80°)
	var fh := hr.size.y * (0.62 if not compact() else 0.8) * cos(deg_to_rad(80.0 * flap))
	if fh > 1.0:
		var fl := Pal.sbn(Color(Pal.PANEL_HI, a), int(clampf(hr.size.y * 0.16, 3, 10)))
		fl.border_color = Color(col.darkened(0.1), a)
		fl.border_width_bottom = 5 if size.y > 40 else 3
		draw_style_box(fl, Rect2(hr.position, Vector2(hr.size.x, fh)))
	var ls := label_size()
	var lc: Vector2
	if compact():
		lc = Vector2(r.position.x + (Pal.bits_width(code.length(), ls, 0) + 16) / 2.0 + 2, 0)
	else:
		lc = Vector2(0, r.position.y + 29)
	if label_alpha > 0.01:
		var pulse_pos := code.length() if new_bit_pop != 1.0 else 0
		# QA P1-11: bij a >= 5 geen kleurchips op de luiken (anders een regenboog-streepjescode), enkel inkt op crème
		var many := code.length() >= 5
		if many:
			var lw := Pal.bits_width(code.length(), ls, 0) + 8
			draw_style_box(Pal.sb(Color(Pal.LABEL, a * label_alpha), 4), Rect2(lc - Vector2(lw / 2.0, minf(size.y, ls * 1.1) / 2.0), Vector2(lw, minf(size.y, ls * 1.1))))
		Pal.bits(self, lc, code, ls, 0 if many else code.length(), 0, Color(Pal.INK, label_alpha), false, pulse_pos, new_bit_pop, a * label_alpha)
	if glow > 0.01:
		Pal.ring(self, r.grow(7), rad + 6, Color(Pal.OK, glow * (0.6 + 0.4 * sin(_t * 6.0))), 5)
	if warn > 0.01:
		Pal.ring(self, r.grow(7), rad + 6, Color(Pal.WARN, warn * (0.5 + 0.5 * sin(_t * 6.0))), 5)
	if hover > 0.01:
		Pal.ring(self, r.grow(4), rad + 4, Color(1, 1, 1, 0.35 * hover), 3)
	if dim < 1.0:
		pass
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Klep open (0,10 s quad) en terug met bounce (0,20 s).
func open_flap() -> void:
	var tw := create_tween()
	tw.tween_property(self, "flap", 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	tw.tween_property(self, "flap", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_redraw)
