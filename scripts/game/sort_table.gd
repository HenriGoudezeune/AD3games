class_name SortTable
extends Node2D
## Sorteertafel bij splitsen (GDD §2.1 stap 3, §7.1): links OUD (bit = 0), rechts NIEUW (bit = 1).
## Staat rechts NAAST het gesplitste rek (QA P1-1: het rek en de buizen blijven zichtbaar).
## Oorsprong = linksboven van het paneel.

const SIZE := Vector2(400, 560)
const LEFT := Rect2(12, 262, 182, 286)
const RIGHT := Rect2(206, 262, 182, 286)
const FRONT := Vector2(200, 126)

var old_label := ""
var new_label := ""
var old_col := Color.WHITE
var new_col := Color.WHITE
var bit_pos := 1
var pulse_bit := true
var hint := 0
var a := 1
var cap := 2             # g
var link_y := 100.0      # lokale y van het rek (verbindingsnokje)
var mid: Array = []      # ParcelView, voorste eerst
var left: Array = []
var right: Array = []
var hover_side := -1
var open_k := 0.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Kant onder een globaal punt: enkel in de bakken (of helemaal links/rechts), anders -1.
func side_at(gpos: Vector2) -> int:
	var p := to_local(gpos)
	if p.y > LEFT.position.y - 20 or p.x < 90 or p.x > SIZE.x - 90:
		if p.x < SIZE.x / 2.0:
			return 0
		return 1
	return -1


func front() -> ParcelView:
	return mid[0] if not mid.is_empty() else null


func mid_target(i: int) -> Vector2:
	if i == 0:
		return FRONT
	var k := i - 1
	return Vector2(FRONT.x + (k - (mid.size() - 2) / 2.0) * 120, 218)


func small_box() -> Vector2:
	return Vector2(150, 58) if cap <= 2 else Vector2(150, 48)


func bin_target(side: int, i: int) -> Vector2:
	var r := LEFT if side == 0 else RIGHT
	var step := small_box().y + 8
	return Vector2(r.get_center().x, r.position.y + 90 + i * step)


func layout_mid(animated := true) -> void:
	for i in mid.size():
		var pv: ParcelView = mid[i]
		var big := i == 0
		var tgt := position + mid_target(i)
		if big:
			pv.set_size(Vector2(176, 104), Pal.fit_bits(pv.n, 140, 40, 24))
			pv.set_pulse(bit_pos if pulse_bit else 0)
		else:
			pv.set_size(Vector2(110, 62), 20)
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
	# nokje naar het rek dat gesplitst wordt
	var ly := clampf(link_y, 30.0, SIZE.y - 30.0)
	draw_colored_polygon(PackedVector2Array([Vector2(2, ly - 22), Vector2(-14, ly), Vector2(2, ly + 22)]), old_col)
	draw_style_box(Pal.sb(Color(Pal.PANEL, 0.98), 26, 20, Vector2(0, 12)), r)
	Pal.head(self, Rect2(0, 0, SIZE.x, 50), Pal.PANEL_HI, 26)
	var cx := SIZE.x / 2.0
	var chip_col: Color = Pal.bit_color(bit_pos - 1) if hint < 2 else Pal.TEXT
	var cr := Rect2(cx - 70, 9, 140, 34)
	draw_style_box(Pal.sb(chip_col, 17), cr)
	Pal.text_c(self, Pal.UI_BOLD, cr.get_center(), "bit %d" % bit_pos, 24, Pal.INK)
	_bin(LEFT, old_col, "OUD", old_label, "0", "←", hover_side == 0)
	_bin(RIGHT, new_col, "NIEUW", new_label, "1", "→", hover_side == 1)
	var al := 0.35 + 0.25 * sin(_t * 5.0)
	for s in [-1.0, 1.0]:
		var base := Vector2(cx + s * 116, FRONT.y + 70)
		draw_colored_polygon(PackedVector2Array([base + Vector2(s * 22, 14), base + Vector2(0, 0), base + Vector2(s * 4, 26)]), Color(Pal.TEXT_DIM, al))


func _bin(r: Rect2, col: Color, title: String, lab: String, key: String, arrow: String, hov: bool) -> void:
	var s := Pal.sbn(Color(col, 0.16), 18)
	s.border_color = Color(col, 0.85 if hov else 0.5)
	s.set_border_width_all(4 if hov else 3)
	draw_style_box(s, r)
	var w := maxf(80.0, Pal.bits_width(maxi(1, lab.length()), 26, 0) + 28)
	var pr := Rect2(r.get_center().x - w / 2.0, r.position.y + 12, w, 40)
	draw_style_box(Pal.sb(Pal.LABEL, 12), pr)
	Pal.bits(self, pr.get_center(), lab, 26, lab.length())
	Pal.text_l(self, Pal.UI_BOLD, Vector2(r.position.x + 10, r.end.y - 18), title, 20, Color(Pal.TEXT, 0.8))
	var kr := Rect2(r.end.x - 64, r.end.y - 32, 56, 26)
	draw_style_box(Pal.sb(Color(0, 0, 0, 0.3), 13), kr)
	Pal.text_c(self, Pal.MONO, kr.get_center(), key + " " + arrow, 18, Pal.TEXT)
