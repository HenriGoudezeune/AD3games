class_name RackView
extends Node2D
## Eén rek (= emmer). Oorsprong = midden. Pakjes zijn ParcelView-kinderen in vakken.
## Twee layouts: "hoog" (kop + plank, bij weinig rekken) en "compact" (één rij, bij veel rekken).

var bucket_id := -1
var col := Color.WHITE
var label := ""          # eerste ab bits
var ab := 0
var a := 1
var g := 2
var n := 5
var size := Vector2(540, 214)
var stuck := 0.0         # 0..1 vastloper-intensiteit (zwaailicht, ring, bollen)
var lamp := 0.0          # inspectielampje (amber), 0..1
var saw_visible := true
var saw_rot := 0.0
var saw_drop := 0.0      # zaag zakt (klonk-animatie)
var hover := 0.0
var plate_pop := 1.0
var cut := 0.0           # zaaglijn over het rek 0..1
var hint_saw := 0.0      # affordance-gloed op de zaag
var echo := 0.0          # holle galm (leeg rek na zaag)
var slots: Array = []    # ParcelView of null, lengte g
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	var s := 1.0
	if stuck > 0.01:
		s = 1.0 + 0.03 * stuck * (0.5 + 0.5 * sin(_t * TAU * 2.0))
	s += 0.005 * sin(_t * TAU / 3.0 + bucket_id)   # het depot ademt
	scale = Vector2(s, s)
	queue_redraw()


func compact() -> bool:
	return size.y < 150


## Heel veel rekken (endless): enkel bordje + vulgraad, geen pakjeslabels.
func is_mini() -> bool:
	return size.x < 400 or size.y < 64


func rect() -> Rect2:
	return Rect2(-size / 2.0, size)


func shelf_rect() -> Rect2:
	var r := rect()
	if compact():
		var left := _strip_w()
		return Rect2(r.position.x + left + 8, r.position.y + 8, r.size.x - left - 16 - 64, r.size.y - 16)
	return Rect2(r.position.x + 12, r.position.y + 70, r.size.x - 24, r.size.y - 82)


func _strip_w() -> float:
	return 196.0


func slot_center(i: int) -> Vector2:
	var sh := shelf_rect()
	var sw := sh.size.x / g
	return Vector2(sh.position.x + sw * (i + 0.5), sh.get_center().y)


func slot_box() -> Vector2:
	var sh := shelf_rect()
	var sw := sh.size.x / g
	return Vector2(minf(sw - 12, 200), minf(sh.size.y - 10, 104))


func slot_label_size() -> int:
	var b := slot_box()
	var by_w := Pal.fit_bits(n, b.x * 0.88 - 10, 26, 14)
	var by_h := int(b.y * 0.54 * 0.72)
	return clampi(mini(by_w, by_h), 16, 26)


func saw_center() -> Vector2:
	var r := rect()
	if is_mini():
		return Vector2(r.end.x - minf(18.0, r.size.y * 0.5), 0)
	if compact():
		return Vector2(r.end.x - 34, r.position.y + r.size.y * 0.5 - 12)
	return Vector2(r.end.x - 116, r.position.y + 29)


func saw_rect_global() -> Rect2:
	var h := 30.0 if not is_mini() else clampf(size.y * 0.5, 12.0, 30.0)
	return Rect2(to_global(saw_center()) - Vector2(h, h), Vector2(h, h) * 2.0)


func plate_rect() -> Rect2:
	var r := rect()
	var ls := 26
	var w := maxf(Pal.bits_width(maxi(1, label.length()), ls, 0) + 28, 56)
	if compact():
		return Rect2(r.position.x + 12, r.position.y + r.size.y / 2.0 - 34 + (0 if r.size.y > 90 else 10), w, 40)
	return Rect2(r.position.x + 12, r.position.y + 9, w, 40)


func free_slot() -> int:
	for i in slots.size():
		if slots[i] == null:
			return i
	return -1


func count() -> int:
	var c := 0
	for p in slots:
		if p != null:
			c += 1
	return c


func set_g(g_: int) -> void:
	g = g_
	while slots.size() < g:
		slots.append(null)


func _draw() -> void:
	if is_mini():
		_draw_mini()
		return
	var r := rect()
	draw_style_box(Pal.sb(Pal.PANEL, 22 if not compact() else 18, 18, Vector2(0, 10)), r)
	var c := count()
	if compact():
		var strip := Rect2(r.position, Vector2(_strip_w(), r.size.y))
		var hs := Pal.sbn(col, 18)
		hs.corner_radius_top_right = 0
		hs.corner_radius_bottom_right = 0
		draw_style_box(hs, strip)
	else:
		Pal.head(self, Rect2(r.position, Vector2(r.size.x, 58)), col, 22)
	# bordje met prefix
	var pr := plate_rect()
	if plate_pop != 1.0:
		var cc := pr.get_center()
		pr = Rect2(cc - pr.size * plate_pop / 2.0, pr.size * plate_pop)
	var plate := Pal.sbn(Pal.LABEL, 12)
	if c == g - 1 and stuck < 0.01:
		plate.border_color = Pal.WARN
		plate.set_border_width_all(4)
	draw_style_box(plate, pr)
	if label == "":
		Pal.text_c(self, Pal.UI_BOLD, pr.get_center(), "·", 26, Pal.INK)
	else:
		Pal.bits(self, pr.get_center(), label, int(26 * plate_pop), label.length())
	# ab-badge + diepte-stippen
	var abr: Rect2
	var dots_y: float
	var dots_x: float
	if compact():
		abr = Rect2(pr.end.x + 8, pr.position.y + 2, 80, 36)
		if abr.end.x > r.position.x + _strip_w() - 6:
			abr.position = Vector2(pr.position.x, pr.end.y + 6)
		dots_y = minf(r.end.y - 14, pr.end.y + 16)
		dots_x = pr.position.x + 8
		if abr.position.y > pr.position.y:
			dots_x = abr.end.x + 14
			dots_y = abr.get_center().y
	else:
		abr = Rect2(pr.end.x + 10, r.position.y + 11, 96, 36)
		dots_y = r.position.y + 29
		dots_x = abr.end.x + 18
	draw_style_box(Pal.sb(Color(0, 0, 0, 0.28), 18), abr)
	Pal.text_c(self, Pal.UI_BOLD, abr.get_center(), "ab = %d" % ab if not compact() else "ab %d" % ab, 23 if not compact() else 21, Pal.TEXT)
	var ds := 20.0 if a <= 4 else 14.0
	for k in a:
		var dp := Vector2(dots_x + k * ds, dots_y)
		if k < ab:
			draw_circle(dp, ds * 0.36, Pal.TEXT, true, -1, true)
		else:
			draw_circle(dp, ds * 0.32, Color(0, 0, 0, 0.45), false, 3, true)
	# teller
	var cnt := "%d/%d" % [c, g]
	if compact():
		Pal.text_c(self, Pal.UI_BOLD, Vector2(r.end.x - 34, r.end.y - 18), cnt, 22, Color(Pal.TEXT, 0.8))
	else:
		Pal.text_c(self, Pal.UI_BOLD, Vector2(r.end.x - 44, r.position.y + 29), cnt, 26, Pal.INK)
	# plank + lege vakken
	var sh := shelf_rect()
	draw_style_box(Pal.sb(Pal.SLOT, 14), sh)
	var sb := slot_box()
	for i in g:
		if i < slots.size() and slots[i] != null:
			continue
		var sc := slot_center(i)
		Pal.ring(self, Rect2(sc - sb / 2.0, sb).grow(-2), 12, Color(1, 1, 1, 0.07), 3)
	if echo > 0.01:
		for k in 3:
			var f := fmod(_t * 0.8 + k / 3.0, 1.0)
			Pal.ring(self, sh.grow(-sh.size.y * 0.3 * (1.0 - f)), 14, Color(Pal.TEXT_DIM, echo * (1.0 - f) * 0.5), 3)
	# zaag
	if saw_visible:
		var scn := saw_center() + Vector2(0, saw_drop * 30.0)
		var hs2 := 1.0 + 0.12 * hint_saw * (0.5 + 0.5 * sin(_t * 6.0))
		if hint_saw > 0.01:
			draw_circle(scn, 34 * hs2, Color(Pal.OK, 0.22 * hint_saw), true, -1, true)
		draw_circle(scn, 24 * hs2, Color(0, 0, 0, 0.32), true, -1, true)
		Pal.saw_icon(self, scn, 16 * hs2, Pal.TEXT, saw_rot, col.darkened(0.2))
		if hover > 0.01:
			Pal.ring(self, Rect2(scn - Vector2(28, 28), Vector2(56, 56)), 28, Color(1, 1, 1, 0.5 * hover), 3)
	# zaaglijn
	if cut > 0.01:
		var y := sh.get_center().y
		var x0 := r.position.x - 10
		var x1 := lerpf(x0, r.end.x + 10, cut)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(Pal.WARN, 0.9), 4, true)
		draw_circle(Vector2(x1, y), 10, Color(1, 1, 1, 0.8), true, -1, true)
	# inspectielampje (amber)
	var lp := Vector2(r.position.x + (_strip_w() - 18 if compact() else r.size.x - 18), r.position.y + 12)
	draw_circle(lp, 7, Color(0, 0, 0, 0.35), true, -1, true)
	if lamp > 0.01:
		draw_circle(lp, 16 * lamp, Color(Pal.WARN, 0.3 * lamp), true, -1, true)
		draw_circle(lp, 6, Color(Pal.WARN, lamp), true, -1, true)
	# vastloper
	if stuck > 0.01:
		Pal.ring(self, r.grow(8), 28, Color(Pal.WARN, stuck * (0.35 + 0.5 * (0.5 + 0.5 * sin(_t * 7.0)))), 5)
		Pal.beacon(self, Vector2(r.end.x - 26, r.position.y - 6), _t, stuck)
	if hover > 0.01 and not saw_visible:
		Pal.ring(self, r.grow(4), 24, Color(1, 1, 1, 0.25 * hover), 3)


## Blink het inspectielampje 2× (verdwaald pakje, dag 1–3).
func blink_lamp() -> void:
	var tw := create_tween()
	for i in 2:
		tw.tween_property(self, "lamp", 1.0, 0.08)
		tw.tween_property(self, "lamp", 0.0, 0.22)


func wobble(deg := 2.0) -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation", deg_to_rad(deg), 0.05)
	tw.tween_property(self, "rotation", deg_to_rad(-deg * 0.6), 0.07)
	tw.tween_property(self, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw_mini() -> void:
	var r := rect()
	var rad := int(clampf(r.size.y * 0.3, 6, 14))
	draw_style_box(Pal.sb(Pal.PANEL, rad, 8, Vector2(0, 5)), r)
	var sw := minf(112.0, r.size.x * 0.52)
	var hs := Pal.sbn(col, rad)
	hs.corner_radius_top_right = 0
	hs.corner_radius_bottom_right = 0
	draw_style_box(hs, Rect2(r.position, Vector2(sw, r.size.y)))
	var ls := clampi(int(r.size.y * 0.62), 14, 24)
	ls = mini(ls, Pal.fit_bits(maxi(1, label.length()), sw - 16, ls, 12))
	var lw := Pal.bits_width(maxi(1, label.length()), ls, 0) + 14
	var pr := Rect2(r.position + Vector2(6, 4), Vector2(minf(lw, sw - 12), r.size.y - 8))
	draw_style_box(Pal.sb(Pal.LABEL, int(pr.size.y * 0.25)), pr)
	if label != "":
		Pal.bits(self, pr.get_center(), label, ls, label.length())
	# vulgraad: g vakjes
	var c := count()
	var x0 := r.position.x + sw + 8
	var avail := r.size.x - sw - 16 - (r.size.y if saw_visible else 0.0)
	var bw := clampf(avail / g - 4, 6, 24)
	var bh := clampf(r.size.y - 12, 6, 24)
	for i in g:
		var br := Rect2(x0 + i * (bw + 4), -bh / 2.0, bw, bh)
		draw_style_box(Pal.sb(Pal.KRAFT if i < c else Pal.SLOT, 4), br)
	if saw_visible:
		var scn := saw_center() + Vector2(0, saw_drop * 10.0)
		var rr := clampf(r.size.y * 0.4, 8, 16)
		if hint_saw > 0.01:
			draw_circle(scn, rr * 1.6, Color(Pal.OK, 0.25 * hint_saw), true, -1, true)
		draw_circle(scn, rr * 1.2, Color(0, 0, 0, 0.32), true, -1, true)
		Pal.saw_icon(self, scn, rr * 0.75, Pal.TEXT, saw_rot, col.darkened(0.2))
	if lamp > 0.01:
		draw_circle(Vector2(r.end.x - 6, r.position.y + 6), 6, Color(Pal.WARN, lamp), true, -1, true)
	if stuck > 0.01:
		Pal.ring(self, r.grow(4), rad + 4, Color(Pal.WARN, stuck * (0.4 + 0.5 * (0.5 + 0.5 * sin(_t * 7.0)))), 4)
		draw_circle(Vector2(r.end.x - 4, r.position.y), 9, Pal.WARN, true, -1, true)
	if hover > 0.01:
		Pal.ring(self, r.grow(3), rad + 3, Color(1, 1, 1, 0.3 * hover), 2)
