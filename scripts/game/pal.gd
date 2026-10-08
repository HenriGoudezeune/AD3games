class_name Pal
extends Object
## Palet, fonts en teken-helpers (ART.md §2–4). Alles statisch: `Pal.bits(ci, ...)`.
## Afgeleid van scripts/game/art_preview.gd (goedgekeurde preview).

# ---------------------------------------------------------------- palet
const BG_DEEP := Color("#121829")
const BG := Color("#1A2238")
const FLOOR_LINE := Color("#212B45")
const PANEL := Color("#28334F")
const PANEL_HI := Color("#34416A")
const PANEL_LO := Color("#1F2840")
const SLOT := Color("#141A2B")
const OUTLINE := Color("#0B101C")
const TEXT := Color("#F4F1EA")
const TEXT_DIM := Color("#8D97B5")
const KRAFT := Color("#E0A96D")
const KRAFT_DARK := Color("#B97F46")
const TAPE := Color("#F3DDB0")
const LABEL := Color("#FFFBF2")
const INK := Color("#1A1F2E")
const OK := Color("#3DDC97")
const ERR := Color("#FF5A5F")
const WARN := Color("#FFB020")
const COIN := Color("#FFD23F")
const COIN_DARK := Color("#E09A1B")
const HEART := Color("#FF5A7A")
const INFO := Color("#4CC9F0")
const HOLE := Color("#06090F")
const SHADOW := Color(0.02, 0.03, 0.08, 0.45)

const BIT_COLORS := [Color("#FFC94D"), Color("#5CD6C8"), Color("#FF8FAB"), Color("#A5E05A"), Color("#B39DFF"), Color("#FFA463")]
const BUCKET_COLORS := [Color("#3A86FF"), Color("#FB8500"), Color("#06D6A0"), Color("#EF476F"), Color("#8338EC"), Color("#00B4D8"), Color("#E056FD"), Color("#FFD166")]
const SKIN := [Color("#F2C29B"), Color("#C68B59"), Color("#8D5524"), Color("#FFDBAC")]
const CLOTHES := [Color("#8338EC"), Color("#00B4D8"), Color("#E056FD"), Color("#FFD166"), Color("#7B61FF")]

## Bits-markering (zelfde waarden als DaySpec.BitHint)
enum Hint { FULL, COLORS, NONE }

static var MONO: Font = preload("res://assets/fonts/JetBrainsMono-ExtraBold.ttf")
static var MONO_B: Font = preload("res://assets/fonts/JetBrainsMono-Bold.ttf")
static var UI: Font = preload("res://assets/fonts/Fredoka-SemiBold.ttf")
static var UI_BOLD: Font = preload("res://assets/fonts/Fredoka-Bold.ttf")
static var UI_MED: Font = preload("res://assets/fonts/Fredoka-Medium.ttf")

static var _sb_cache := {}


static func bucket_color(idx: int) -> Color:
	var c: Color = BUCKET_COLORS[idx % BUCKET_COLORS.size()]
	var cyc := idx / BUCKET_COLORS.size()
	if cyc % 2 == 1:
		c = c.lightened(0.12 * ((cyc + 1) / 2))
	elif cyc > 0:
		c = c.darkened(0.12 * (cyc / 2))
	return c


static func bit_color(pos0: int) -> Color:
	return BIT_COLORS[pos0 % BIT_COLORS.size()]


# ---------------------------------------------------------------- styleboxen
## Gecachete StyleBoxFlat (kleur, radius, schaduw). Niet muteren!
static func sb(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 6)) -> StyleBoxFlat:
	var key := [col, radius, shadow, shadow_off]
	var hit = _sb_cache.get(key)
	if hit:
		return hit
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.corner_detail = 10
	if shadow > 0:
		s.shadow_color = SHADOW
		s.shadow_size = shadow
		s.shadow_offset = shadow_off
	if _sb_cache.size() > 4000:
		_sb_cache.clear()
	_sb_cache[key] = s
	return s


## Nieuwe (muteerbare) StyleBoxFlat.
static func sbn(col: Color, radius: int, shadow := 0, shadow_off := Vector2(0, 6)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.corner_detail = 10
	if shadow > 0:
		s.shadow_color = SHADOW
		s.shadow_size = shadow
		s.shadow_offset = shadow_off
	return s


static func ring(ci: CanvasItem, r: Rect2, radius: int, col: Color, w: int) -> void:
	var key := ["ring", col, radius, w]
	var g = _sb_cache.get(key)
	if g == null:
		g = sbn(Color(0, 0, 0, 0), radius)
		g.draw_center = false
		g.border_color = col
		g.set_border_width_all(w)
		_sb_cache[key] = g
	ci.draw_style_box(g, r)


## Rechthoek met alleen bovenste hoeken afgerond (kop van muur/rek).
static func head(ci: CanvasItem, r: Rect2, col: Color, radius: int) -> void:
	var key := ["head", col, radius]
	var g = _sb_cache.get(key)
	if g == null:
		g = sbn(col, radius)
		g.corner_radius_bottom_left = 0
		g.corner_radius_bottom_right = 0
		_sb_cache[key] = g
	ci.draw_style_box(g, r)


# ---------------------------------------------------------------- tekst
static func text_c(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(center.x - w.x / 2.0, center.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_l(ci: CanvasItem, font: Font, left_mid: Vector2, s: String, size: int, col: Color) -> float:
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(left_mid.x, left_mid.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_r(ci: CanvasItem, font: Font, right_mid: Vector2, s: String, size: int, col: Color) -> float:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	ci.draw_string(font, Vector2(right_mid.x - w, right_mid.y + (asc - desc) / 2.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return w


static func text_outline_c(ci: CanvasItem, font: Font, center: Vector2, s: String, size: int, col: Color, outline := 8, ocol := OUTLINE) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	var p := Vector2(center.x - w.x / 2.0, center.y + (asc - desc) / 2.0)
	ci.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# ---------------------------------------------------------------- bits
## Breedte van een bitlabel (zelfde maatvoering als bits()).
static func bits_width(n: int, size: int, knip: int) -> float:
	var cw := MONO.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var gap := maxf(3.0, size * 0.12)
	var sep := size * 0.3 if knip > 0 and knip < n else 0.0
	return n * cw + (n - 1) * gap + sep


## Bitlabel in mono. `chips` = aantal bits (vanaf links) op een chip in positiekleur; `knip` = na welke bit de
## extra spatie komt (0 = geen); `accolade` = lijn onder de eerste `knip` bits. `pulse` = 1-gebaseerde positie die
## extra groot getekend wordt met schaal `pulse_s`. `dim_from` = bits vanaf deze 0-index gedimd (typbuffer).
## Geeft de totale breedte terug.
static func bits(ci: CanvasItem, center: Vector2, s: String, size: int, chips: int, knip := -1, ink := INK,
		accolade := false, pulse := 0, pulse_s := 1.0, chip_alpha := 1.0) -> float:
	if knip < 0:
		knip = chips
	var cw := MONO.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var gap := maxf(3.0, size * 0.12)
	var sep := size * 0.3 if knip > 0 and knip < s.length() else 0.0
	var total := s.length() * cw + (s.length() - 1) * gap + sep
	var x := center.x - total / 2.0
	var asc := MONO.get_ascent(size)
	var desc := MONO.get_descent(size)
	var acc_end := x
	for i in s.length():
		var sz := size
		var scale := 1.0
		if pulse == i + 1:
			scale = pulse_s
		if scale != 1.0:
			sz = int(round(size * scale))
		var ccx := x + cw / 2.0
		if i < chips:
			var cwz := cw * scale
			var r := Rect2(ccx - cwz / 2.0 - sz * 0.09, center.y - sz * 0.62, cwz + sz * 0.18, sz * 1.24)
			var cc: Color = bit_color(i)
			cc.a *= chip_alpha
			ci.draw_style_box(sb(cc, int(sz * 0.24)), r)
		if pulse == i + 1 and i >= chips:
			var r2 := Rect2(ccx - cw * scale / 2.0 - sz * 0.09, center.y - sz * 0.62, cw * scale + sz * 0.18, sz * 1.24)
			ring(ci, r2, int(sz * 0.24), Color(bit_color(i), 0.9), 3)
		var a2 := MONO.get_ascent(sz)
		var d2 := MONO.get_descent(sz)
		var cwz2 := MONO.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		ci.draw_string(MONO, Vector2(ccx - cwz2 / 2.0, center.y + (a2 - d2) / 2.0), s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ink)
		x += cw + gap
		if i == knip - 1:
			acc_end = x - gap
			x += sep
	if accolade and knip > 0:
		var x0 := center.x - total / 2.0
		var y := center.y + size * 0.78
		var col := Color(ink, 0.8)
		ci.draw_line(Vector2(x0, y), Vector2(acc_end, y), col, 2.5, true)
		ci.draw_line(Vector2(x0, y), Vector2(x0, y - size * 0.15), col, 2.5, true)
		ci.draw_line(Vector2(acc_end, y), Vector2(acc_end, y - size * 0.15), col, 2.5, true)
		var mid := (x0 + acc_end) / 2.0
		ci.draw_line(Vector2(mid, y), Vector2(mid, y + size * 0.14), col, 2.5, true)
	return total


## Grootste fontgrootte (>= min_size) zodat `n` bits in `width` passen.
static func fit_bits(n: int, width: float, max_size: int, min_size := 18) -> int:
	var s := max_size
	while s > min_size and bits_width(n, s, 0) > width:
		s -= 1
	return s


# ---------------------------------------------------------------- geometrie
static func fillet(pts: PackedVector2Array, radius: float, seg := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.size() < 3:
		return pts
	out.append(pts[0])
	for i in range(1, pts.size() - 1):
		var p0 := pts[i - 1]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var d0 := p0.distance_to(p1)
		var d2 := p1.distance_to(p2)
		if d0 < 0.5 or d2 < 0.5:
			out.append(p1)
			continue
		var r := minf(radius, minf(d0, d2) * 0.5)
		var a := p1 + (p0 - p1).normalized() * r
		var b := p1 + (p2 - p1).normalized() * r
		for k in seg + 1:
			var s := float(k) / seg
			out.append(a.lerp(p1, s).lerp(p1.lerp(b, s), s))
	out.append(pts[pts.size() - 1])
	return out


static func path_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	return total


static func path_point(pts: PackedVector2Array, f: float) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	var total := path_length(pts)
	var target := clampf(f, 0.0, 1.0) * total
	for i in range(1, pts.size()):
		var l := pts[i - 1].distance_to(pts[i])
		if target <= l:
			return pts[i - 1].lerp(pts[i], target / maxf(l, 0.001))
		target -= l
	return pts[pts.size() - 1]


# ---------------------------------------------------------------- pakje
## Pakje gecentreerd op `c`. `chips`/`knip`/`accolade` zoals bits(). `t` voor de pulserende ring als lifted.
static func parcel(ci: CanvasItem, c: Vector2, sz: Vector2, s: String, label_size: int, chips: int, knip := -1,
		lifted := false, accolade := false, t := 0.0, key_label := "", pulse := 0, pulse_s := 1.0, ring_col := Color(0, 0, 0, 0)) -> void:
	var r := Rect2(c - sz / 2.0, sz)
	var rad := int(sz.y * 0.13)
	if lifted:
		ci.draw_style_box(_shadow_sb(rad, 22, Vector2(8, 22)), r)
	else:
		ci.draw_style_box(_shadow_sb(rad, 7, Vector2(0, 6)), r)
	var key := ["box", rad, maxi(4, int(sz.y * 0.08))]
	var box = _sb_cache.get(key)
	if box == null:
		box = sbn(KRAFT, rad)
		box.border_color = KRAFT_DARK
		box.border_width_bottom = maxi(4, int(sz.y * 0.08))
		_sb_cache[key] = box
	ci.draw_style_box(box, r)
	ci.draw_rect(Rect2(c.x - sz.x * 0.07, r.position.y, sz.x * 0.14, sz.y * 0.92), Color(TAPE, 0.55))
	var lw := sz.x * 0.88
	if key_label != "":
		# dag 6: groot sleutelnummer + kleine hashwaarde eronder
		var lh2 := sz.y * 0.70
		var lr2 := Rect2(c.x - lw / 2.0, c.y - lh2 / 2.0 - sz.y * 0.04, lw, lh2)
		ci.draw_style_box(_label_sb(int(lh2 * 0.16)), lr2)
		text_c(ci, UI_BOLD, Vector2(c.x, lr2.position.y + lh2 * 0.34), "#" + key_label, int(label_size * 0.95), INK)
		bits(ci, Vector2(c.x, lr2.position.y + lh2 * 0.74), s, maxi(18, int(label_size * 0.5)), chips, knip, INK, false, pulse, pulse_s)
	else:
		var lh := sz.y * 0.54
		var lr := Rect2(c.x - lw / 2.0, c.y - lh / 2.0 - sz.y * 0.05, lw, lh)
		ci.draw_style_box(_label_sb(int(lh * 0.2)), lr)
		bits(ci, lr.get_center() + (Vector2(0, -label_size * 0.08) if accolade else Vector2.ZERO), s, label_size, chips, knip, INK, accolade, pulse, pulse_s)
	if lifted:
		ring(ci, r.grow(7), rad + 6, Color(1, 1, 1, 0.75 + 0.25 * sin(t * 6.0)), 4)
	if ring_col.a > 0.0:
		ring(ci, r.grow(6), rad + 6, ring_col, 4)


static func _shadow_sb(rad: int, size: int, off: Vector2) -> StyleBoxFlat:
	var key := ["psh", rad, size, off]
	var s = _sb_cache.get(key)
	if s == null:
		s = sbn(Color(0, 0, 0, 0), rad)
		s.shadow_color = Color(0.02, 0.03, 0.08, 0.5)
		s.shadow_size = size
		s.shadow_offset = off
		_sb_cache[key] = s
	return s


static func _label_sb(rad: int) -> StyleBoxFlat:
	var key := ["lab", rad]
	var s = _sb_cache.get(key)
	if s == null:
		s = sbn(LABEL, rad)
		s.shadow_color = Color(0, 0, 0, 0.18)
		s.shadow_size = 2
		s.shadow_offset = Vector2(0, 2)
		_sb_cache[key] = s
	return s


# ---------------------------------------------------------------- iconen
static func heart(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.25), r * 0.56, col, true, -1, true)
	ci.draw_circle(c + Vector2(r * 0.5, -r * 0.25), r * 0.56, col, true, -1, true)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.04, -r * 0.08), c + Vector2(r * 1.04, -r * 0.08), c + Vector2(0, r * 0.95)]), col)


static func coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.18), r, COIN_DARK, true, -1, true)
	ci.draw_circle(c, r, COIN, true, -1, true)
	ci.draw_circle(c, r * 0.62, COIN_DARK.lightened(0.25), false, maxf(2.0, r * 0.18), true)
	ci.draw_arc(c, r * 0.8, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.8), maxf(2.0, r * 0.18), true)


static func truck(ci: CanvasItem, c: Vector2, s := 1.0, col := WARN) -> void:
	ci.draw_style_box(sb(col, int(5 * s)), Rect2(c + Vector2(-18, -8) * s, Vector2(24, 16) * s))
	ci.draw_style_box(sb(col.darkened(0.2), int(3 * s)), Rect2(c + Vector2(-12, -18) * s, Vector2(12, 12) * s))
	ci.draw_line(c + Vector2(10, -16) * s, c + Vector2(10, 10) * s, TEXT_DIM, 3 * s)
	ci.draw_line(c + Vector2(10, 10) * s, c + Vector2(22, 10) * s, TEXT_DIM, 3 * s)
	ci.draw_circle(c + Vector2(-12, 11) * s, 5 * s, INK, true, -1, true)
	ci.draw_circle(c + Vector2(2, 11) * s, 5 * s, INK, true, -1, true)


static func saw_icon(ci: CanvasItem, c: Vector2, rad: float, col: Color, rot := 0.0, hub := PANEL) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := k * TAU / 10 + rot
		pts.append(c + Vector2(cos(a), sin(a)) * rad * 0.7)
		pts.append(c + Vector2(cos(a + 0.5), sin(a + 0.5)) * rad * 1.15)
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c, rad * 0.3, hub, true, -1, true)


static func star_shape(ci: CanvasItem, c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * TAU / 10 + rot
		var rr := r if k % 2 == 0 else r * 0.48
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


static func beacon(ci: CanvasItem, c: Vector2, t: float, strength := 1.0) -> void:
	var a := t * 5.0
	for side in [0.0, PI]:
		var dir := Vector2(cos(a + side), sin(a + side) * 0.35)
		var tip := c + dir * 90
		var perp := Vector2(-dir.y, dir.x) * 28
		ci.draw_colored_polygon(PackedVector2Array([c, tip + perp, tip - perp]), Color(WARN, 0.18 * strength))
	ci.draw_style_box(sb(PANEL_LO, 6), Rect2(c + Vector2(-20, 4), Vector2(40, 12)))
	ci.draw_circle(c, 16, WARN, true, -1, true)
	ci.draw_circle(c + Vector2(-5, -5), 5, Color(1, 1, 1, 0.6), true, -1, true)


## Gestileerde hand (spookhand / cursor). `c` = vingertop.
static func hand(ci: CanvasItem, c: Vector2, col: Color, s := 1.0, pressed := false) -> void:
	var o := c + Vector2(6, 26) * s
	var k := 0.85 if pressed else 1.0
	var palm := Rect2(o + Vector2(-14, 8) * s, Vector2(42, 40) * s * Vector2(1, k))
	ci.draw_style_box(sb(Color(col, col.a * 0.25), int(14 * s)), palm.grow(6 * s))
	ci.draw_style_box(sb(col, int(12 * s)), palm)
	ci.draw_style_box(sb(col, int(7 * s)), Rect2(c + Vector2(-7, 0) * s, Vector2(14, 44) * s))
	for f in 3:
		ci.draw_style_box(sb(col, int(6 * s)), Rect2(o + Vector2(8 + f * 11, 0) * s, Vector2(11, 22) * s))
	ci.draw_style_box(sb(col, int(6 * s)), Rect2(o + Vector2(-24, 18) * s, Vector2(16, 11) * s))
