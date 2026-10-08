class_name NotasView
extends Control
## Tekent een model-snapshot zoals Figuur 4/5 in de lesnotas: pointerarray met binaire indices, pijlen naar
## emmers met hun hashwaarden en de lokale diepte ab. Papierlook (crème + inkt).

var snap: Dictionary = {}
var highlight_bucket := -1
var title := ""
var bad_index := -1       # luik van de foute zet (rood-transparant)
var good_index := -1      # luik van de juiste zet (groen, spookhand)
var _t := 0.0


func _process(d: float) -> void:
	if good_index >= 0 or bad_index >= 0:
		_t += d
		queue_redraw()


func set_snapshot(d: Dictionary, t := "") -> void:
	snap = d
	title = t
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var paper := Pal.sbn(Pal.LABEL, 18, 12, Vector2(0, 8))
	draw_style_box(paper, r)
	for y in range(60, int(size.y), 34):
		draw_line(Vector2(20, y), Vector2(size.x - 20, y), Color(0.3, 0.5, 0.8, 0.10), 1)
	if title != "":
		Pal.text_l(self, Pal.UI_BOLD, Vector2(24, 28), title, 24, Pal.INK)
	if snap.is_empty():
		return
	var n := int(snap.n)
	var a := int(snap.a)
	var dir: Array = snap.dir
	var buckets: Array = snap.buckets
	var cnt := dir.size()
	var top := 64.0
	var avail := size.y - top - 20
	var cell_h := minf(44.0, avail / cnt)
	var fs := clampi(int(cell_h * 0.6), 12, 24)
	var x_idx := 30.0
	var cell_w := 30.0
	var cell_x := x_idx + Pal.bits_width(a, fs, 0) + 14
	var y0 := top + (avail - cell_h * cnt) / 2.0
	Pal.text_c(self, Pal.UI_BOLD, Vector2(cell_x + cell_w / 2.0, top - 10), "a = %d" % a, 18, Pal.INK)
	# emmers in dir-volgorde
	var order: Array = []
	var seen := {}
	for i in cnt:
		var b := int(dir[i])
		if not seen.has(b):
			seen[b] = true
			order.append(b)
	var bx := cell_x + cell_w + 150
	var bh := minf(52.0, (avail - 8 * order.size()) / maxf(1, order.size()))
	var bfs := clampi(int(bh * 0.42), 12, 22)
	var gap := (avail - bh * order.size()) / maxf(1, order.size())
	var bpos := {}
	for k in order.size():
		var by := top + gap / 2.0 + k * (bh + gap)
		bpos[order[k]] = by
	for i in cnt:
		var cy := y0 + i * cell_h + cell_h / 2.0
		Pal.text_l(self, Pal.MONO_B, Vector2(x_idx, cy), HashUtil.bits(i, a), fs, Pal.INK)
		var cr := Rect2(cell_x, y0 + i * cell_h, cell_w, cell_h)
		if i == bad_index:
			draw_rect(cr.grow(3), Color(Pal.ERR, 0.35))
		if i == good_index:
			draw_rect(cr.grow(3), Color(Pal.OK, 0.25 + 0.25 * sin(_t * 5.0)))
		draw_rect(cr, Pal.INK, false, 2)
		draw_circle(cr.get_center(), 3.5, Pal.INK, true, -1, true)
		var b := int(dir[i])
		var tgt := Vector2(bx - 4, float(bpos[b]) + bh / 2.0)
		var col := Pal.INK if b != highlight_bucket else Pal.ERR
		draw_line(cr.get_center(), tgt, Color(col, 0.8), 2, true)
		var dvec := (tgt - cr.get_center()).normalized()
		var perp := Vector2(-dvec.y, dvec.x)
		draw_colored_polygon(PackedVector2Array([tgt, tgt - dvec * 10 + perp * 5, tgt - dvec * 10 - perp * 5]), col)
	for b in order:
		var bd: Dictionary = {}
		for x in buckets:
			if int(x.id) == b:
				bd = x
		var by: float = bpos[b]
		var ab := int(bd.get("ab", 0))
		var br := Rect2(bx, by, size.x - bx - 30, bh)
		var sb := Pal.sbn(Color(Pal.bucket_color(b), 0.18), 6)
		sb.border_color = Pal.INK if b != highlight_bucket else Pal.ERR
		sb.set_border_width_all(2)
		draw_style_box(sb, br)
		draw_line(Vector2(bx + 64, by), Vector2(bx + 64, by + bh), Pal.INK, 2)
		Pal.text_c(self, Pal.UI_BOLD, Vector2(bx + 32, by + bh / 2.0), "ab %d" % ab, bfs, Pal.INK)
		var hs := PackedStringArray()
		for p in bd.get("parcels", []):
			hs.append(HashUtil.bits(int(p.hv), n))
		Pal.text_l(self, Pal.MONO_B, Vector2(bx + 78, by + bh / 2.0), "  ".join(hs) if not hs.is_empty() else "—", bfs, Pal.INK)
	if good_index >= 0 and good_index < cnt:
		# spookhand tikt op het juiste luik
		var gy := y0 + good_index * cell_h + cell_h / 2.0
		var target := Vector2(cell_x + cell_w / 2.0, gy)
		var f := fposmod(_t, 2.0) / 2.0
		var from := target + Vector2(-90, 70)
		var k := clampf(f * 2.0, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		var pressed := f > 0.5 and f < 0.65
		Pal.hand(self, from.lerp(target, e), Color(Pal.INFO, 0.8), 0.9, pressed)
		if pressed:
			draw_circle(target, 16, Color(Pal.OK, 0.4), true, -1, true)
