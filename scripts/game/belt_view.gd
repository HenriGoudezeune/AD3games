class_name BeltView
extends Node2D
## Band (loopt van rechts naar links) + retourbak links.

const BIN_RECT := Rect2(16, 84, 92, 140)
const BELT_RECT := Rect2(120, 84, 1784, 140)

var scroll := 0.0
var bin_wobble := 0.0
var bin_count := 0
var stopped := false


func _process(_d: float) -> void:
	queue_redraw()


func center_y() -> float:
	return BELT_RECT.get_center().y


func _draw() -> void:
	# retourbak
	var br := BIN_RECT
	draw_set_transform(br.get_center() + Vector2(0, br.size.y / 2), bin_wobble, Vector2.ONE)
	var lr := Rect2(-br.size.x / 2, -br.size.y, br.size.x, br.size.y)
	draw_style_box(Pal.sb(Pal.PANEL_LO, 18, 12, Vector2(0, 8)), lr)
	draw_style_box(Pal.sb(Pal.SLOT, 12), lr.grow(-12))
	for i in mini(bin_count, 6):
		var y := -24.0 - i * 14.0
		draw_style_box(Pal.sb(Pal.KRAFT if i % 2 == 0 else Pal.KRAFT_DARK, 4), Rect2(-26 + (i % 2) * 6, y, 46, 12))
	Pal.text_c(self, Pal.UI, Vector2(0, -br.size.y + 26), "retour", 17, Pal.TEXT_DIM)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# band
	var r := BELT_RECT
	draw_style_box(Pal.sb(Pal.PANEL_LO, 22, 16, Vector2(0, 10)), r)
	var inner := r.grow(-14)
	draw_style_box(Pal.sb(Pal.SLOT, 14), inner)
	var pitch := 44.0
	var off := fposmod(scroll, pitch)
	var x := inner.end.x + pitch - off
	var roll := Color("#28314D")
	while x > inner.position.x:
		if x < inner.end.x - 8 and x > inner.position.x + 2:
			var rr := Rect2(x, inner.position.y + 8, 14, inner.size.y - 16)
			draw_style_box(Pal.sb(roll, 7), rr)
			draw_line(Vector2(x + 4, rr.position.y + 6), Vector2(x + 4, rr.end.y - 6), Color(1, 1, 1, 0.06), 2)
		x -= pitch
	for y in [r.position.y + 7, r.end.y - 7]:
		draw_line(Vector2(r.position.x + 24, y), Vector2(r.end.x - 24, y), Color(Pal.WARN, 0.5), 4)
	# instroom-pijltjes rechts
	for k in 3:
		var ax := r.end.x - 30 - k * 16
		var al := 0.25 + 0.25 * sin(scroll * 0.05 - k)
		draw_colored_polygon(PackedVector2Array([Vector2(ax, r.get_center().y - 10), Vector2(ax - 10, r.get_center().y), Vector2(ax, r.get_center().y + 10)]), Color(Pal.TEXT_DIM, al))
