class_name LeverView
extends Node2D
## Hendel = muur verdubbelen (a + 1). Oorsprong = linksboven van de hendelkast.

var size := Vector2(220, 330)
var pull := 0.0          # 0 boven, 1 onder
var glow := 0.0          # affordance (WARN)
var jam := 0.0           # eindaanslag-flits (ERR)
var a := 1
var n := 5
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func slot_rect() -> Rect2:
	return Rect2(size.x / 2.0 - 14, 64, 28, size.y - 116)


func knob_local() -> Vector2:
	var sl := slot_rect()
	var wig := 0.03 * glow * sin(_t * 4.0)
	return Vector2(sl.get_center().x, sl.position.y + 24 + clampf(pull + wig, 0.0, 1.0) * (sl.size.y - 48))


func knob_global() -> Vector2:
	return to_global(knob_local())


func hit(gpos: Vector2) -> bool:
	return Rect2(global_position, size).has_point(gpos)


func pull_from_global_y(gy: float) -> float:
	var sl := slot_rect()
	return clampf((gy - global_position.y - sl.position.y - 24) / (sl.size.y - 48), 0.0, 1.0)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(Pal.sb(Pal.PANEL, 24, 16, Vector2(0, 10)), r)
	Pal.text_c(self, Pal.UI_BOLD, Vector2(r.get_center().x, 32), "hendel", 22, Pal.TEXT_DIM)
	var sl := slot_rect()
	draw_style_box(Pal.sb(Pal.SLOT, 14), sl)
	# veiligheidsstrepen onderaan de gleuf
	var stop := Rect2(sl.position.x - 10, sl.end.y - 6, sl.size.x + 20, 12)
	draw_style_box(Pal.sb(Color(Pal.WARN, 0.7) if jam < 0.01 else Pal.ERR.lerp(Pal.WARN, 1.0 - jam), 6), stop)
	var knob := knob_local()
	draw_line(Vector2(sl.get_center().x, sl.end.y - 10), knob, Color("#566390"), 12, true)
	var gl := glow * (0.5 + 0.5 * sin(_t * 6.0))
	if gl > 0.01:
		draw_circle(knob, 40 + 8 * gl, Color(Pal.WARN, 0.22 * gl), true, -1, true)
	var kc := Pal.WARN if jam < 0.01 else Pal.WARN.lerp(Pal.ERR, jam)
	draw_circle(knob + Vector2(0, 4), 30, kc.darkened(0.35), true, -1, true)
	draw_circle(knob, 30, kc, true, -1, true)
	draw_circle(knob + Vector2(-9, -10), 9, Color(1, 1, 1, 0.45), true, -1, true)
	var lab := "a + 1" if a < n else "a = n"
	Pal.text_c(self, Pal.UI_BOLD, Vector2(r.get_center().x, r.end.y - 26), lab, 22, Pal.WARN if a < n else Pal.ERR)
