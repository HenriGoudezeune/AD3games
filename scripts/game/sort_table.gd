class_name SortTable
extends Node2D
## Sorteertafel bij splitsen (GDD §2.1 stap 3, §7.1): links OUD (bit = 0), rechts NIEUW (bit = 1).
## Oorsprong = linksboven van het paneel.

const SIZE := Vector2(900, 300)
const LEFT := Rect2(16, 62, 230, 222)
const RIGHT := Rect2(654, 62, 230, 222)
const FRONT := Vector2(450, 150)
const SMALL := Vector2(150, 58)

var old_label := ""
var new_label := ""
var old_col := Color.WHITE
var new_col := Color.WHITE
var bit_pos := 1
var pulse_bit := true
var hint := 0
var a := 1
var mid: Array = []      # ParcelView, voorste eerst
var left: Array = []
var right: Array = []
var hover_side := -1
var open_k := 0.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func side_at(gpos: Vector2) -> int:
	var p := to_local(gpos)
	if p.x < SIZE.x * 0.38:
		return 0
	if p.x > SIZE.x * 0.62:
		return 1
	return -1


func front() -> ParcelView:
	return mid[0] if not mid.is_empty() else null


func mid_target(i: int) -> Vector2:
	if i == 0:
		return FRONT
	var k := i - 1
	return Vector2(FRONT.x + (k - (mid.size() - 2) / 2.0) * 128, 258)


func bin_target(side: int, i: int) -> Vector2:
	var r := LEFT if side == 0 else RIGHT
	return Vector2(r.get_center().x, r.position.y + 76 + i * (SMALL.y + 8))


func layout_mid(animated := true) -> void:
	for i in mid.size():
		var pv: ParcelView = mid[i]
		var big := i == 0
		var tgt := position + mid_target(i)
		if big:
			pv.set_size(Vector2(176, 104), 40)
			pv.set_pulse(bit_pos if pulse_bit else 0)
		else:
			pv.set_size(Vector2(120, 70), 24)
			pv.set_pulse(0)
		pv.z_index = 30 if big else 29
		if animated:
			var tw := pv.create_tween()
			tw.tween_property(pv, "position", tgt, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			pv.position = tgt


func _draw() -> void:
	if open_k <= 0.001:
		return
	var r := Rect2(Vector2.ZERO, SIZE)
	draw_style_box(Pal.sb(Color(Pal.PANEL, 0.98), 26, 20, Vector2(0, 12)), r)
	Pal.head(self, Rect2(0, 0, SIZE.x, 50), Pal.PANEL_HI, 26)
	# bit-chip in het midden van de kop
	var cx := SIZE.x / 2.0
	var chip_col: Color = Pal.bit_color(bit_pos - 1) if hint < 2 else Pal.TEXT
	var cr := Rect2(cx - 70, 9, 140, 34)
	draw_style_box(Pal.sb(chip_col, 17), cr)
	Pal.text_c(self, Pal.UI_BOLD, cr.get_center(), "bit %d" % bit_pos, 24, Pal.INK)
	_bin(LEFT, old_col, "OUD", old_label, "0", "←", hover_side == 0)
	_bin(RIGHT, new_col, "NIEUW", new_label, "1", "→", hover_side == 1)
	# pijltjes naar links/rechts onder het voorste pakje
	var al := 0.35 + 0.25 * sin(_t * 5.0)
	for s in [-1.0, 1.0]:
		var base := Vector2(cx + s * 128, FRONT.y)
		draw_colored_polygon(PackedVector2Array([base + Vector2(s * 26, 0), base + Vector2(0, -16), base + Vector2(0, 16)]), Color(Pal.TEXT_DIM, al))


func _bin(r: Rect2, col: Color, title: String, lab: String, key: String, arrow: String, hov: bool) -> void:
	var s := Pal.sbn(Color(col, 0.16), 18)
	s.border_color = Color(col, 0.85 if hov else 0.5)
	s.set_border_width_all(4 if hov else 3)
	draw_style_box(s, r)
	var pr := Rect2(r.get_center().x - 60, r.position.y + 10, 120, 40)
	draw_style_box(Pal.sb(Pal.LABEL, 12), pr)
	Pal.bits(self, pr.get_center(), lab, 26, lab.length())
	Pal.text_l(self, Pal.UI_BOLD, Vector2(r.position.x + 10, r.end.y - 18), title, 20, Color(Pal.TEXT, 0.8))
	var kr := Rect2(r.end.x - 74, r.end.y - 34, 64, 28)
	draw_style_box(Pal.sb(Color(0, 0, 0, 0.3), 14), kr)
	Pal.text_c(self, Pal.MONO, kr.get_center(), key + " " + arrow, 20, Pal.TEXT)
