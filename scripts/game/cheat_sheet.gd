class_name CheatSheet
extends Control
## Spiekbrief (GDD §4.1): 4 pictogrammen, geen tekstmuur.
##  eerste a bits → luik · vol + 1 buis → hendel · vol + ≥ 2 buizen → zaag · bit ab+1: 0 links / 1 rechts

signal closed

const SIZE := Vector2(1400, 520)
var _t := 0.0


func _ready() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = SIZE / 2.0
	UIKit.pop_in(self, 0.0, 0.25)
	Sfx.ui("open")


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		closed.emit()
		queue_free()


func _draw() -> void:
	draw_style_box(Pal.sb(Pal.PANEL, 28, 24, Vector2(0, 12)), Rect2(Vector2.ZERO, SIZE))
	Pal.head(self, Rect2(0, 0, SIZE.x, 70), Pal.WARN, 28)
	Pal.text_c(self, Pal.UI_BOLD, Vector2(SIZE.x / 2, 35), "SPIEKBRIEF", 40, Pal.INK)
	var w := (SIZE.x - 100) / 4.0
	for i in 4:
		var r := Rect2(20 + i * (w + 20), 96, w, SIZE.y - 130)
		draw_style_box(Pal.sb(Pal.PANEL_LO, 20), r)
		var c := r.get_center() + Vector2(0, -30)
		match i:
			0: _pic_hatch(c)
			1: _pic_lever(c)
			2: _pic_saw(c)
			3: _pic_sort(c)
		var cap: String = ["eerste a bits → luik", "vol + 1 buis → hendel", "vol + 2+ buizen → zaag", "bit ab+1: 0 ← · → 1"][i]
		Pal.text_c(self, Pal.UI_BOLD, Vector2(r.get_center().x, r.end.y - 40), cap, 24, Pal.TEXT)
	Pal.text_c(self, Pal.UI, Vector2(SIZE.x / 2, SIZE.y - 14), "klik om te sluiten", 18, Pal.TEXT_DIM)


func _pic_hatch(c: Vector2) -> void:
	Pal.parcel(self, c + Vector2(0, -70), Vector2(176, 104), "10110", 36, 3, 3, false, true)
	draw_line(c + Vector2(0, -10), c + Vector2(0, 30), Pal.TEXT_DIM, 4, true)
	var hr := Rect2(c + Vector2(-60, 40), Vector2(120, 70))
	var f := Pal.sbn(Pal.PANEL_LO, 14)
	f.border_color = Pal.BUCKET_COLORS[1]
	f.set_border_width_all(4)
	draw_style_box(f, hr)
	Pal.bits(self, hr.get_center(), "101", 30, 3)


func _rack(c: Vector2, pipes_n: int, col: Color) -> void:
	for k in pipes_n:
		var y := c.y - 30 + k * (60.0 / maxf(1, pipes_n - 1)) if pipes_n > 1 else c.y
		draw_line(Vector2(c.x - 140, y), Vector2(c.x - 90, y), Pal.OUTLINE, 18, true)
		draw_line(Vector2(c.x - 140, y), Vector2(c.x - 90, y), col, 12, true)
		draw_line(Vector2(c.x - 90, y), Vector2(c.x - 60, c.y), col, 12, true)
	var r := Rect2(c + Vector2(-60, -50), Vector2(150, 100))
	draw_style_box(Pal.sb(Pal.PANEL_HI, 14), r)
	for s in 2:
		draw_style_box(Pal.sb(Pal.KRAFT, 8), Rect2(r.position + Vector2(10 + s * 70, 30), Vector2(60, 56)))
	Pal.ring(self, r.grow(6), 18, Color(Pal.WARN, 0.6 + 0.4 * sin(_t * 6)), 4)


func _pic_lever(c: Vector2) -> void:
	_rack(c + Vector2(40, -60), 1, Pal.BUCKET_COLORS[2])
	var k := c + Vector2(0, 90 + 10 * sin(_t * 4))
	draw_line(c + Vector2(0, 150), k, Color("#566390"), 10, true)
	draw_circle(k, 26, Pal.WARN, true, -1, true)


func _pic_saw(c: Vector2) -> void:
	_rack(c + Vector2(40, -60), 2, Pal.BUCKET_COLORS[0])
	draw_circle(c + Vector2(0, 100), 40, Color(0, 0, 0, 0.3), true, -1, true)
	Pal.saw_icon(self, c + Vector2(0, 100), 28, Pal.TEXT, _t * 2.0)


func _pic_sort(c: Vector2) -> void:
	Pal.parcel(self, c + Vector2(0, -60), Vector2(176, 104), "11100", 36, 0, 0, false, false, 0.0, "", 3, 1.25)
	for s in [-1.0, 1.0]:
		var base := c + Vector2(s * 70, 50)
		draw_colored_polygon(PackedVector2Array([base + Vector2(s * 30, 0), base + Vector2(0, -18), base + Vector2(0, 18)]), Pal.TEXT_DIM)
		Pal.text_c(self, Pal.MONO, base + Vector2(s * 10, 60), "0" if s < 0 else "1", 40, Pal.TEXT)
