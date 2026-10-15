class_name ScDraw
extends Object
## Kortschrift: materialen, rekwisieten, personages en stroken, in code getekend (design/ART.md §5). Statisch: elke
## functie krijgt het CanvasItem (`ci`, in een draw-callback). De werktuigen zelf staan in ScDrawTools.
## Licht valt van linksboven (kaars), schaduw 6–8 px naar rechtsonder. Letters altijd INK op perkament of chip.
## Getextureerde vlakken (perkament, hout, leer) gebruiken naadloze texturen: roep `ScDraw.prepare(ci)` één keer
## (bv. in _ready) zodat texture_repeat aanstaat.

const LIGHT_DIR := Vector2(-0.6, -0.8)


static func prepare(ci: CanvasItem) -> void:
	ci.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


# ================================================================ geometrie
static func ellipse_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 32) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for k in n:
		var a := k * TAU / n
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		out.append(c + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr))
	return out


## Gevulde polygoon met zachte rand.
static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, aa := true) -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	ci.draw_colored_polygon(pts, col)
	if aa:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, col, 1.0, true)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	fill(ci, ellipse_pts(c, rx, ry, rot), col)


static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w := 2.0) -> void:
	if pts.size() < 2:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, w, true)


## Lokale punten (figuur kijkt naar rechts) -> wereld: schaal s, spiegel `facing`, draai rot.
static func xf(pts: PackedVector2Array, c: Vector2, s: float, facing := 1.0, rot := 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for p in pts:
		var q := Vector2(p.x * facing, p.y) * s
		out.append(c + Vector2(q.x * cr - q.y * sr, q.x * sr + q.y * cr))
	return out


static func xp(p: Vector2, c: Vector2, s: float, facing := 1.0, rot := 0.0) -> Vector2:
	var q := Vector2(p.x * facing, p.y) * s
	return c + Vector2(q.x * cos(rot) - q.y * sin(rot), q.x * sin(rot) + q.y * cos(rot))


static func bezier(p0: Vector2, c0: Vector2, c1: Vector2, p1: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * c0 + 3.0 * u * t * t * c1 + t * t * t * p1


static func curve(p0: Vector2, c0: Vector2, c1: Vector2, p1: Vector2, n := 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		out.append(bezier(p0, c0, c1, p1, float(i) / n))
	return out


static func _hash(i: int) -> float:
	var x := (i * 374761393 + 668265263) & 0x7fffffff
	x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff
	return float(x % 10000) / 10000.0


## Afgeronde rechthoek als punten (voor getextureerde vlakken).
static func rrect_pts(r: Rect2, rad: float, n := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) / 2.0)
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for i in n + 1:
			var a := -PI / 2 + (k + float(i) / n) * PI / 2
			out.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return out


## Rechthoek met geschepte (rafelige) perkamentrand.
static func deckle_pts(r: Rect2, seed_ := 0, amp := 2.5, step := 14.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var k := 0
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var n := maxi(2, int(a.distance_to(b) / step))
		var nrm := (b - a).normalized().orthogonal()
		for i in n:
			var p := a.lerp(b, float(i) / n)
			if i > 0:
				p += nrm * (_hash(seed_ * 131 + k) - 0.5) * 2.0 * amp
			out.append(p)
			k += 1
	return out


## Polygoon met een naadloze detailtextuur, getint met `col` (UV = wereldpositie / textuurgrootte * schaal).
static func tex_poly(ci: CanvasItem, pts: PackedVector2Array, tex: Texture2D, col: Color, scale := 1.0) -> void:
	if pts.size() < 3:
		return
	if tex == null:
		fill(ci, pts, col)
		return
	var sz := tex.get_size() * scale
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(Vector2(p.x / sz.x, p.y / sz.y))
	ci.draw_polygon(pts, PackedColorArray([col]), uvs, tex)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col.darkened(0.05), 1.0, true)


# ================================================================ materialen
## Perkamentblad: geschepte rand, vellum-textuur, verbruinde rand, zachte schaduw. Basis van band, strook en kaart.
static func parchment(ci: CanvasItem, r: Rect2, seed_ := 0, col := ScPal.VELLUM, shadow := true, aged := 0.5, amp := 2.5) -> void:
	var pts := deckle_pts(r, seed_, amp)
	if shadow:
		fill(ci, xf(pts, Vector2(6, 8), 1.0), ScPal.SHADOW_SOFT, false)
	tex_poly(ci, pts, ScPal.tex("art/tex/vellum.png"), col, 0.8)
	if aged > 0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, Color(ScPal.VELLUM_AGED, 0.22 * aged), 9.0, true)
		ci.draw_polyline(closed, Color(ScPal.VELLUM_AGED, 0.45 * aged), 3.0, true)


## Houten vlak (eik): nerftextuur, lichtrand linksboven, donkere onderrand. Voor raam, kast, plank, tegels.
static func wood(ci: CanvasItem, r: Rect2, col := ScPal.OAK, rad := 8.0, shadow := true, bevel := 4.0) -> void:
	var pts := rrect_pts(r, rad)
	if shadow:
		fill(ci, xf(pts, Vector2(5, 7), 1.0), ScPal.SHADOW, false)
	if bevel > 0:
		fill(ci, xf(pts, Vector2(0, bevel), 1.0), col.darkened(0.35), true)
	tex_poly(ci, pts, ScPal.tex("art/tex/wood.png"), col, 1.0)
	ci.draw_line(r.position + Vector2(rad, 1.5), Vector2(r.end.x - rad, r.position.y + 1.5), Color(col.lightened(0.35), 0.8), 2.0, true)
	ci.draw_line(r.position + Vector2(1.5, rad), Vector2(r.position.x + 1.5, r.end.y - rad), Color(col.lightened(0.2), 0.5), 2.0, true)


## Leren band met goudstempeling (HUD, panelen in de wereld). `tooling` = dubbele goudlijn + hoekfleurons.
static func leather(ci: CanvasItem, r: Rect2, rad := 18.0, col := ScPal.PANEL, tooling := true, shadow := true) -> void:
	var pts := rrect_pts(r, rad, 6)
	if shadow:
		fill(ci, xf(pts, Vector2(0, 10), 1.0), ScPal.SHADOW, false)
	tex_poly(ci, pts, ScPal.tex("art/tex/leather.png"), col, 1.0)
	ci.draw_polyline(curve(r.position + Vector2(rad, 1), r.position + Vector2(r.size.x * 0.3, 1),
		r.position + Vector2(r.size.x * 0.7, 1), Vector2(r.end.x - rad, r.position.y + 1), 4), Color(col.lightened(0.25), 0.7), 2.0, true)
	if tooling:
		var i1 := r.grow(-8)
		var i2 := r.grow(-13)
		ScPal.ring(ci, i1, int(maxf(2, rad - 8)), Color(ScPal.GILT, 0.85), 2)
		ScPal.ring(ci, i2, int(maxf(2, rad - 13)), Color(ScPal.GILT_DARK, 0.6), 1)
		for c in [i1.position + Vector2(14, 14), Vector2(i1.end.x - 14, i1.position.y + 14),
				Vector2(i1.position.x + 14, i1.end.y - 14), i1.end - Vector2(14, 14)]:
			fleuron(ci, c, 5.0, ScPal.GILT)


## Klein goud ornament (ruit met vier punten).
static func fleuron(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	fill(ci, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.45, 0), c + Vector2(0, s), c + Vector2(-s * 0.45, 0)]), col)
	fill(ci, PackedVector2Array([c + Vector2(-s, 0), c + Vector2(0, -s * 0.45), c + Vector2(s, 0), c + Vector2(0, s * 0.45)]), col)


# ================================================================ licht, kaars, veer, inkt
## Zachte lichtvlek (lichtpoel-textuur), normaal geblend; gebruik `ScFx.glow_sprite` voor additief licht.
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var tx := ScPal.particle("light_pool")
	if tx:
		ci.draw_texture_rect(tx, Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false, col)
	else:
		ci.draw_circle(c, r * 0.5, Color(col, col.a * 0.4))


static func _teardrop(base: Vector2, w: float, h: float, sway: float, n := 18) -> PackedVector2Array:
	var tip := base + Vector2(sway, -h)
	var poly := PackedVector2Array()
	for i in n + 1:  # onderkant: halve cirkel onder de basis, van links naar rechts
		var a := PI * float(i) / n
		poly.append(base + Vector2(-cos(a) * w, sin(a) * w * 0.9))
	var right := curve(base + Vector2(w, 0), base + Vector2(w * 1.05, -h * 0.45), tip + Vector2(w * 0.25, h * 0.25), tip, 10)
	var left := curve(tip, tip + Vector2(-w * 0.25, h * 0.25), base + Vector2(-w * 1.05, -h * 0.45), base + Vector2(-w, 0), 10)
	poly.append_array(right.slice(1))
	poly.append_array(left.slice(1, left.size() - 1))
	return poly


## Kaarsvlam met flakkering. `base` = onderkant van de vlam (pit). `flare` 0..1 = "volle vlam" (Nachtwake).
static func flame(ci: CanvasItem, base: Vector2, s := 1.0, t := 0.0, flare := 0.0, glow_r := 150.0) -> void:
	var fl := 1.0 + 0.07 * sin(t * 13.0) + 0.05 * sin(t * 23.0 + 1.3) + 0.6 * flare
	var sway := (2.2 * sin(t * 3.1) + 1.2 * sin(t * 7.7)) * s
	if glow_r > 0:
		glow(ci, base + Vector2(0, -12 * s), glow_r * s * (0.95 + 0.05 * sin(t * 11.0)) * (1 + flare * 0.6), Color(ScPal.GLOW, 0.32))
	fill(ci, _teardrop(base, 7.5 * s, 34.0 * s * fl, sway), Color(ScPal.FLAME_OUT, 0.85))
	fill(ci, _teardrop(base + Vector2(0, -1 * s), 5.6 * s, 26.0 * s * fl, sway * 0.8), ScPal.FLAME)
	fill(ci, _teardrop(base + Vector2(0, -2 * s), 3.2 * s, 14.0 * s * fl, sway * 0.5), ScPal.FLAME_CORE)
	ci.draw_circle(base + Vector2(0, 1.5 * s), 2.6 * s, Color(ScPal.LAPIS_LIGHT, 0.55))
	ci.draw_line(base + Vector2(0, 3 * s), base + Vector2(0, -3 * s), ScPal.INK, 1.6 * s, true)


## Kaars in een koperen schaaltje. `base` = midden onderaan de schaal. `burn` 1 = nieuw, 0 = op (Nachtwake-klok).
static func candle(ci: CanvasItem, base: Vector2, s := 1.0, t := 0.0, lit := true, burn := 1.0, flare := 0.0, h := 110.0) -> void:
	var w := 22.0 * s
	var hh := lerpf(14.0, h, clampf(burn, 0, 1)) * s
	# schaal
	ellipse(ci, base + Vector2(4, 4) * s, 40 * s, 10 * s, ScPal.SHADOW_SOFT)
	ellipse(ci, base, 38 * s, 10 * s, ScPal.BRASS_DARK)
	ellipse(ci, base + Vector2(0, -3 * s), 36 * s, 8 * s, ScPal.BRASS)
	ellipse(ci, base + Vector2(-8 * s, -5 * s), 18 * s, 3 * s, Color(ScPal.GOLD_LIGHT, 0.5))
	# kaarslijf
	var top := base.y - 4 * s - hh
	var body := Rect2(base.x - w / 2, top, w, hh)
	ci.draw_rect(body, ScPal.CANDLE)
	ci.draw_rect(Rect2(body.position + Vector2(w * 0.62, 0), Vector2(w * 0.38, hh)), ScPal.CANDLE_SHADE)
	ci.draw_rect(Rect2(body.position + Vector2(w * 0.12, 0), Vector2(w * 0.14, hh)), Color(1, 1, 1, 0.35))
	ellipse(ci, Vector2(base.x, top), w / 2, 4 * s, ScPal.CANDLE.lightened(0.2))
	ellipse(ci, Vector2(base.x + 1 * s, top + 0.5 * s), w * 0.3, 2.2 * s, ScPal.CANDLE_SHADE)
	# druppels
	for k in 3:
		var dx := (-0.35 + 0.33 * k) * w
		var dl := (8 + 10 * _hash(k + 3)) * s * clampf(1.2 - burn * 0.4, 0.6, 1.2)
		ci.draw_line(Vector2(base.x + dx, top + 1), Vector2(base.x + dx, top + dl), ScPal.CANDLE.lightened(0.1), 4.5 * s, true)
		ci.draw_circle(Vector2(base.x + dx, top + dl), 2.6 * s, ScPal.CANDLE.lightened(0.1))
	if lit:
		flame(ci, Vector2(base.x, top - 3 * s), s, t, flare)
	else:
		ci.draw_line(Vector2(base.x, top), Vector2(base.x + 2 * s, top - 7 * s), ScPal.INK, 2.0 * s, true)


## Ganzenveer. `tip` = de pen (schrijfpunt), `ang` = richting van de punt naar de vlag (rad), `writing` wiebelt.
static func quill(ci: CanvasItem, tip: Vector2, s := 1.0, ang := -2.2, t := 0.0, writing := 0.0) -> void:
	var a := ang + sin(t * 40.0) * 0.03 * writing
	var d := Vector2(cos(a), sin(a))
	var n := d.orthogonal()
	var L := 170.0 * s
	var p_end := tip + d * L
	# schaduw
	ci.draw_line(tip + Vector2(10, 14), p_end + Vector2(18, 22), ScPal.SHADOW_SOFT, 6 * s, true)
	# vlag (vaan): links breed, rechts smal
	var lpts := PackedVector2Array()
	var rpts := PackedVector2Array()
	for i in 13:
		var f := 0.25 + 0.75 * float(i) / 12.0
		var wv := sin(PI * minf(1.0, (f - 0.25) / 0.78)) * 24.0 * s
		lpts.append(tip + d * L * f + n * wv * 1.0)
		rpts.append(tip + d * L * f - n * wv * 0.55)
	var vane := PackedVector2Array()
	vane.append_array(lpts)
	rpts.reverse()
	vane.append_array(rpts)
	fill(ci, vane, Color("#F3EEE4"))
	for i in range(1, 12, 2):
		var f := 0.3 + 0.7 * float(i) / 12.0
		var o := tip + d * L * f
		ci.draw_line(o, o + (n * 0.9 + d * 0.5).normalized() * 18.0 * s * sin(PI * f), Color("#CFC6B6"), 1.2, true)
	# schacht en pen
	ci.draw_line(tip + d * 14 * s, p_end, Color("#E2D6BE"), 3.0 * s, true)
	fill(ci, PackedVector2Array([tip, tip + d * 22 * s + n * 3.2 * s, tip + d * 22 * s - n * 3.2 * s]), ScPal.INK)
	fill(ci, PackedVector2Array([tip + d * 22 * s + n * 3.2 * s, tip + d * 36 * s + n * 3.0 * s,
		tip + d * 36 * s - n * 3.0 * s, tip + d * 22 * s - n * 3.2 * s]), Color("#C7B48E"))


## Inktpot (keramiek met glazuur). `level` 0..1 (vulling, zichtbaar in de hals), `amber` = boven het optimum (borrelt).
static func inkpot(ci: CanvasItem, c: Vector2, s := 1.0, level := 1.0, amber := false, t := 0.0) -> void:
	ellipse(ci, c + Vector2(6, 30) * s, 40 * s, 10 * s, ScPal.SHADOW)
	var body := PackedVector2Array()
	for i in 21:
		var a := PI * (1.0 + float(i) / 20.0)
		body.append(c + Vector2(cos(a) * 34 * s, -sin(a) * 30 * s + 6 * s))
	body.append(c + Vector2(20 * s, -26 * s))
	body.append(c + Vector2(-20 * s, -26 * s))
	fill(ci, body, Color("#2C3346"))
	fill(ci, xf(body, c + Vector2(-6, -4) * s, 0.0), Color(0, 0, 0, 0))
	ellipse(ci, c + Vector2(-14, 2) * s, 7 * s, 16 * s, Color(1, 1, 1, 0.12), 0.3)
	ci.draw_rect(Rect2(c + Vector2(-16, -34) * s, Vector2(32, 10) * s), Color("#3A4258"))
	ellipse(ci, c + Vector2(0, -34) * s, 16 * s, 5 * s, Color("#4A5370"))
	var ink_col := ScPal.WARN if amber else Color("#120C0A")
	ellipse(ci, c + Vector2(0, -34) * s, 12 * s, 3.4 * s, ink_col.darkened(0.2 * (1.0 - level)))
	if amber:
		for k in 3:
			var ph := fmod(t * 1.3 + k * 0.37, 1.0)
			ci.draw_arc(c + Vector2(-6 + k * 6, -36 - ph * 10) * s, (2 + ph * 2) * s, 0, TAU, 12, Color(ScPal.WARN, 1.0 - ph), 1.5, true)
	# etiketje
	parchment(ci, Rect2(c + Vector2(-17, -12) * s, Vector2(34, 18) * s), 7, ScPal.VELLUM, false, 0.3, 1.0)


## Inktdruppel (HUD-icoon, partikel-voorbeeld).
static func drop(ci: CanvasItem, c: Vector2, r: float, col := ScPal.INK, shine := true) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := k * TAU / 24
		var rr := r * (1.0 - 0.55 * maxf(0, -sin(a)) ** 3)
		pts.append(c + Vector2(cos(a) * rr * 0.85, sin(a) * rr - maxf(0, -sin(a)) ** 4 * r * 0.9))
	fill(ci, pts, col)
	if shine:
		ellipse(ci, c + Vector2(-r * 0.3, -r * 0.05), r * 0.16, r * 0.3, Color(1, 1, 1, 0.45), 0.3)


## Inktvlek (anders gelezen letter, klodder op perkament). Deterministisch per seed.
static func ink_blot(ci: CanvasItem, c: Vector2, r: float, seed_ := 0, col := Color(ScPal.SEPIA, 0.55), pulse := 0.0) -> void:
	r *= 1.0 + 0.15 * pulse
	var pts := PackedVector2Array()
	for k in 20:
		var a := k * TAU / 20
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.78 + 0.32 * _hash(seed_ * 37 + k)))
	fill(ci, pts, col)
	for k in 5:
		var a := _hash(seed_ * 11 + k) * TAU
		var dd := r * (1.25 + 0.6 * _hash(seed_ * 13 + k))
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * dd, r * (0.08 + 0.1 * _hash(seed_ * 17 + k)), col)


# ================================================================ zegels, stempels, sterren
static func _wax_pts(c: Vector2, r: float, seed_: int, n := 22) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := k * TAU / n
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.92 + 0.14 * _hash(seed_ * 53 + k)))
	return pts


## Lakzegel met tekst (ruwe letter in de levende boom, sterren, brief). Tekst in licht reliëf op de was.
static func seal(ci: CanvasItem, c: Vector2, r: float, text := "", font: Font = null, size := 0, col := ScPal.WAX,
		seed_ := 0, squash := Vector2.ONE) -> void:
	var pts := _wax_pts(Vector2.ZERO, r, seed_)
	var tp := PackedVector2Array()
	for p in pts:
		tp.append(c + p * squash)
	fill(ci, xf(tp, Vector2(3, 4), 1.0), ScPal.SHADOW, false)
	fill(ci, tp, col.darkened(0.25))
	ellipse(ci, c + Vector2(-0.5, -1.0) * r * 0.05, r * 0.74 * squash.x, r * 0.74 * squash.y, col)
	ci.draw_arc(c, r * 0.74 * squash.x, PI * 1.05, PI * 1.6, 12, Color(ScPal.WAX_LIGHT if col == ScPal.WAX else col.lightened(0.3), 0.8), 2.0, true)
	ci.draw_arc(c, r * 0.74 * squash.x, PI * 0.05, PI * 0.6, 12, Color(col.darkened(0.45), 0.7), 2.0, true)
	ellipse(ci, c + Vector2(-r * 0.42, -r * 0.5), r * 0.16, r * 0.08, Color(1, 1, 1, 0.35), -0.6)
	if text != "":
		var f := font if font else ScPal.MONO
		var sz := size if size > 0 else int(r * 0.95)
		ScPal.text_c(ci, f, c + Vector2(1, 1.5), text, sz, col.darkened(0.55))
		ScPal.text_c(ci, f, c, text, sz, ScPal.VELLUM_HI)


## Wassen zegel (LZ77-drietal) "(p,l,x)": langwerpige groene was zodat hij verschilt van het rode lakzegel.
static func triple_seal(ci: CanvasItem, c: Vector2, p: int, l: int, x: String, size := 24, hi := false) -> Rect2:
	var s := "(%d,%d,%s)" % [p, l, ScPal.show(x)]
	var w := ScPal.text_w(ScPal.MONO_B, s, size) + size * 1.2
	var h := size * 1.75
	var r := Rect2(c - Vector2(w, h) / 2, Vector2(w, h))
	var pts := rrect_pts(r, h * 0.48, 6)
	var j := PackedVector2Array()
	for i in pts.size():
		j.append(pts[i] + (pts[i] - c).normalized() * (_hash(i + p * 7 + l * 3) - 0.5) * 3.0)
	fill(ci, xf(j, Vector2(3, 4), 1.0), ScPal.SHADOW, false)
	fill(ci, j, ScPal.WAX_GREEN_DARK)
	fill(ci, rrect_pts(r.grow(-4), h * 0.4, 6), ScPal.WAX_GREEN)
	ci.draw_line(r.position + Vector2(h * 0.4, 6), Vector2(r.end.x - h * 0.4, r.position.y + 6), Color(1, 1, 1, 0.25), 2.0, true)
	ScPal.text_c(ci, ScPal.MONO_B, c + Vector2(1, 1.5), s, size, ScPal.WAX_GREEN_DARK.darkened(0.4))
	ScPal.text_c(ci, ScPal.MONO_B, c, s, size, ScPal.VELLUM_HI)
	if hi:
		ScPal.ring(ci, r.grow(5), int(h * 0.5 + 5), ScPal.INFO, 3)
	return r


## Stempelafdruk (LZW-code): inktkader met het nummer, licht onregelmatig zoals een houtstempel.
static func stamp_print(ci: CanvasItem, c: Vector2, num: String, size := 28, a := 1.0, seed_ := 0, col := ScPal.INK) -> Rect2:
	var w := ScPal.text_w(ScPal.MONO_B, num, size) + size * 0.9
	var h := size * 1.45
	var r := Rect2(c - Vector2(w, h) / 2, Vector2(w, h))
	var ink := Color(col, 0.88 * a)
	ScPal.ring(ci, r, int(size * 0.18), ink, maxi(2, int(size * 0.09)))
	ScPal.text_c(ci, ScPal.MONO_B, c, num, size, ink)
	# vlekjes waar de stempel geen inkt pakte
	for k in 4:
		var p := r.position + Vector2(_hash(seed_ * 7 + k) * w, (_hash(seed_ * 9 + k) > 0.5) as int * h)
		ci.draw_circle(p, 1.6, Color(ScPal.VELLUM, 0.9 * a))
	return r


## Ster als lakzegel (terugblik/kaart). `filled` = in rode was gedrukt; anders een lege, gestippelde plek.
static func star_seal(ci: CanvasItem, c: Vector2, r: float, filled: bool, press := 1.0, seed_ := 0) -> void:
	if not filled:
		for k in 16:
			var a := k * TAU / 16
			ci.draw_arc(c, r * 0.8, a, a + TAU / 32, 4, Color(ScPal.INK_FADED, 0.8), 2.0, true)
		star(ci, c, r * 0.42, Color(ScPal.INK_FADED, 0.45))
		return
	var sq := Vector2(1.0 + 0.15 * (1.0 - press), 1.0 - 0.15 * (1.0 - press))
	seal(ci, c, r, "", null, 0, ScPal.WAX, seed_, sq)
	star(ci, c + Vector2(1, 2), r * 0.42, ScPal.WAX_DARK)
	star(ci, c, r * 0.42, ScPal.GOLD)


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := rot - PI / 2 + k * PI / 5
		var rr := r if k % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	fill(ci, pts, col)


# ================================================================ stroken: opdrachtband, kortschrift, voorlezing
## Opdrachtband: perkamentband met zwaluwstaartjes, één vak per teken (mono), positie eronder (vanaf 0).
## `done_before` = al gecodeerd (gedimd + gouden streepje), `cursor` = volgend teken (lapisring + veertje).
## Geeft de centra van de vakken terug.
static func task_band(ci: CanvasItem, left_mid: Vector2, text: String, cell := 58.0, size := 44, cursor := -1,
		done_before := -1, show_idx := true, alphabet := "", chips := false, t := 0.0, seed_ := 3) -> PackedVector2Array:
	var n := text.length()
	var w := n * cell + 36.0
	var h := size * 1.5 + (26.0 if show_idx else 10.0)
	var r := Rect2(left_mid.x, left_mid.y - h / 2, w, h)
	# zwaluwstaarten
	for side in [-1, 1]:
		var x0: float = r.position.x if side == -1 else r.end.x
		var tail := PackedVector2Array([Vector2(x0, r.position.y + 8), Vector2(x0 + side * 30, r.position.y + 4),
			Vector2(x0 + side * 18, r.get_center().y), Vector2(x0 + side * 30, r.end.y - 4), Vector2(x0, r.end.y - 8)])
		fill(ci, xf(tail, Vector2(4, 6), 1.0), ScPal.SHADOW_SOFT, false)
		fill(ci, tail, ScPal.VELLUM_EDGE)
	parchment(ci, r, seed_, ScPal.VELLUM, true, 0.6)
	var centers := PackedVector2Array()
	for i in n:
		var cx := r.position.x + 18 + cell * (i + 0.5)
		var cy := r.position.y + size * 0.78
		centers.append(Vector2(cx, cy))
		var ch := text[i]
		var done := done_before >= 0 and i < done_before
		if chips:
			var cc := ScPal.letter_color(ch, alphabet)
			cc.a = 0.35 if done else 0.9
			ci.draw_style_box(ScPal.sb(cc, int(size * 0.2)), Rect2(cx - cell * 0.42, cy - size * 0.62, cell * 0.84, size * 1.24))
		var col := ScPal.INK_FADED if done else ScPal.INK
		ScPal.text_c(ci, ScPal.MONO, Vector2(cx, cy), ScPal.show(ch), size, col)
		if done:
			ci.draw_line(Vector2(cx - cell * 0.32, cy + size * 0.56), Vector2(cx + cell * 0.32, cy + size * 0.56), ScPal.GOLD, 3.0, true)
		if show_idx:
			ScPal.text_c(ci, ScPal.MONO_M, Vector2(cx, r.end.y - 14), str(i), 18, ScPal.INK_SOFT)
		if i > 0:
			ci.draw_line(Vector2(cx - cell / 2, r.position.y + 10), Vector2(cx - cell / 2, r.end.y - (24 if show_idx else 8)),
				Color(ScPal.VELLUM_AGED, 0.35), 1.0)
	if cursor >= 0 and cursor < n:
		var cc2 := centers[cursor]
		var cr := Rect2(cc2.x - cell * 0.46, cc2.y - size * 0.68, cell * 0.92, size * 1.36)
		ScPal.ring(ci, cr, int(size * 0.22), ScPal.INFO, 3)
		var bob := sin(t * 4.0) * 3.0
		fill(ci, PackedVector2Array([Vector2(cc2.x, r.position.y - 4 + bob), Vector2(cc2.x - 9, r.position.y - 18 + bob),
			Vector2(cc2.x + 9, r.position.y - 18 + bob)]), ScPal.INFO)
	return centers


## Kortschrift-strook (de uitvoer). tokens: {"b":"0101"} bits, {"raw":"g"} lakzegel, {"triple":[p,l,x]} wassen zegel,
## {"code":97} stempelafdruk, {"num":7} getal (letterplank). Een dun streepje scheidt de tokens (codewoorden).
## Bits: inktcijfer met een penstreek eronder, kort voor 0, lang voor 1 (ook zonder kleur leesbaar).
## `koker` > 0: breedte van de duivenkoker (optimum) -> gouden lijn; wat erover gaat, wordt amber. Geeft de eind-x terug.
static func shorthand(ci: CanvasItem, left_mid: Vector2, tokens: Array, size := 28, koker := -1.0, t := 0.0,
		cursor_blink := true) -> float:
	var x := left_mid.x
	var y := left_mid.y
	var bw := ScPal.char_w(size) + 6.0
	var limit := left_mid.x + koker if koker > 0 else INF
	for ti in tokens.size():
		var tk: Dictionary = tokens[ti]
		if ti > 0:
			ci.draw_line(Vector2(x + 3, y - size * 0.7), Vector2(x + 3, y + size * 0.7), Color(ScPal.INK_SOFT, 0.55), 1.5, true)
			x += 8
		if tk.has("b"):
			var bits: String = tk["b"]
			for i in bits.length():
				var cx := x + bw / 2
				var over := cx > limit
				var col := ScPal.WARN.darkened(0.25) if over else ScPal.INK
				ScPal.text_c(ci, ScPal.MONO, Vector2(cx, y - size * 0.15), bits[i], size, col)
				var half := (bw * 0.18) if bits[i] == "0" else (bw * 0.42)
				ci.draw_line(Vector2(cx - half, y + size * 0.62), Vector2(cx + half, y + size * 0.62), col, 3.0, true)
				x += bw
		elif tk.has("raw"):
			var r := size * 0.68
			seal(ci, Vector2(x + r + 2, y), r, ScPal.show(str(tk["raw"])), ScPal.MONO, int(size * 0.85), ScPal.WAX, ti)
			x += 2 * r + 4
		elif tk.has("triple"):
			var tr: Array = tk["triple"]
			var s := "(%d,%d,%s)" % [tr[0], tr[1], ScPal.show(str(tr[2]))]
			var w := ScPal.text_w(ScPal.MONO_B, s, int(size * 0.8)) + size * 0.96
			triple_seal(ci, Vector2(x + w / 2, y), int(tr[0]), int(tr[1]), str(tr[2]), int(size * 0.8))
			x += w + 4
		elif tk.has("code"):
			var s2 := str(tk["code"])
			var w2 := ScPal.text_w(ScPal.MONO_B, s2, size) + size * 0.9
			stamp_print(ci, Vector2(x + w2 / 2, y), s2, size, 1.0, ti)
			x += w2 + 4
		elif tk.has("num"):
			var s3 := str(tk["num"])
			var w3 := ScPal.text_w(ScPal.MONO, s3, size) + 12
			ScPal.text_c(ci, ScPal.MONO, Vector2(x + w3 / 2, y), s3, size, ScPal.INK)
			x += w3
	if cursor_blink and fmod(t, 1.0) < 0.6:
		ci.draw_line(Vector2(x + 6, y - size * 0.6), Vector2(x + 6, y + size * 0.6), ScPal.INFO, 3.0, true)
	if koker > 0:
		ci.draw_line(Vector2(limit, y - size * 0.95), Vector2(limit, y + size * 0.95), ScPal.GOLD, 3.0, true)
	return x


## Voorlezing: origineel (boven) en wat Letterlijk las (onder), letter per letter. Gelijk = gouden stip,
## anders = bruine inkt met een inktvlek erachter (vorm + kleur). `shown` = aantal al voorgelezen letters.
static func reading(ci: CanvasItem, left_mid: Vector2, orig: String, read: String, size := 36, shown := -1, t := 0.0,
		pulse := 0.0) -> void:
	var cw := ScPal.char_w(size) + 10.0
	var n := maxi(orig.length(), read.length())
	if shown < 0:
		shown = n
	for i in n:
		var x := left_mid.x + cw * (i + 0.5)
		var o := orig[i] if i < orig.length() else ""
		var rd := read[i] if i < read.length() else ""
		ScPal.text_c(ci, ScPal.MONO, Vector2(x, left_mid.y - size * 0.75), ScPal.show(o), size, ScPal.INK_SOFT)
		if i >= shown:
			continue
		var same := o == rd
		var y := left_mid.y + size * 0.65
		if not same:
			ink_blot(ci, Vector2(x, y), size * 0.52, i + 5, Color(ScPal.SEPIA, 0.32), pulse)
		ScPal.text_c(ci, ScPal.MONO, Vector2(x, y), ScPal.show(rd) if rd != "" else "…", size, ScPal.INK if same else ScPal.SEPIA)
		if same:
			ci.draw_circle(Vector2(x, y + size * 0.78), 4.5, ScPal.GOLD)
			ci.draw_circle(Vector2(x - 1.2, y + size * 0.78 - 1.2), 1.6, ScPal.GOLD_LIGHT)
		else:
			ci.draw_line(Vector2(x - 6, y + size * 0.78), Vector2(x + 6, y + size * 0.78), ScPal.SEPIA, 3.0, true)


# ================================================================ personages
## Monnik (chibi). `c` = voeten. `card` = kaartje boven het hoofd (bv. "[2,6]" of "e 2·7"); `lantern` = de lantaarn
## hangt boven hem (t van Algoritme 11); `stumble` 0..1 = scheef (eigenschap (b) gebroken); `hi` = selectiering;
## `walk` 0..1 = loopcyclus (wissel); `mood` 0 rustig, 1 blij, 2 verbaasd.
static func monk(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, habit := ScPal.HABITS[0], card := "", hi := false,
		lantern := false, stumble := 0.0, facing := 1.0, mood := 0, walk := 0.0, sym := "", alphabet := "") -> Rect2:
	var rot := stumble * 0.32 * (1.0 + 0.1 * sin(t * 3.0))
	var bob := (absf(sin(walk * PI * 2.0)) * -4.0 + sin(t * 2.0 + c.x * 0.05) * 0.8) * s
	var o := c + Vector2(0, bob)
	ellipse(ci, c + Vector2(3, 0) * s, 22 * s, 5 * s, ScPal.SHADOW_SOFT)
	if hi:
		ellipse(ci, c, 30 * s, 8 * s, Color(ScPal.INFO, 0.35 + 0.15 * sin(t * 7.0)))
	# habijt (klok)
	var body := PackedVector2Array([Vector2(-11, -44), Vector2(11, -44), Vector2(19, -6), Vector2(21, 0), Vector2(-21, 0), Vector2(-19, -6)])
	fill(ci, xf(body, o, s, facing, rot), habit)
	fill(ci, xf(PackedVector2Array([Vector2(4, -44), Vector2(11, -44), Vector2(19, -6), Vector2(21, 0), Vector2(8, 0)]), o, s, facing, rot), habit.darkened(0.18))
	# voetjes
	for fx in [-8.0, 8.0]:
		var lift: float = maxf(0.0, sin(walk * TAU + (0.0 if fx < 0 else PI))) * 3.0
		ellipse(ci, xp(Vector2(fx, 1 - lift), o, s, facing, rot), 6 * s, 3 * s, ScPal.WALNUT)
	# koord + mouwen
	ci.draw_line(xp(Vector2(-14, -22), o, s, facing, rot), xp(Vector2(14, -22), o, s, facing, rot), ScPal.CORD, 2.4 * s, true)
	ci.draw_line(xp(Vector2(-4, -22), o, s, facing, rot), xp(Vector2(-6, -9), o, s, facing, rot), ScPal.CORD, 2.0 * s, true)
	fill(ci, xf(PackedVector2Array([Vector2(-12, -34), Vector2(12, -34), Vector2(9, -26), Vector2(-9, -26)]), o, s, facing, rot), habit.darkened(0.1))
	ellipse(ci, xp(Vector2(0, -28), o, s, facing, rot), 5 * s, 3.5 * s, ScPal.SKIN_SHADE)
	# kap (achter het hoofd) + hoofd
	var head := xp(Vector2(0, -56), o, s, facing, rot)
	ellipse(ci, xp(Vector2(-2, -50), o, s, facing, rot), 15 * s, 9 * s, habit.darkened(0.25))
	ci.draw_circle(head, 14 * s, ScPal.SKIN)
	# tonsuur: haarkrans
	ci.draw_arc(head + Vector2(0, -2 * s), 13.5 * s, PI * 0.95, PI * 2.05, 16, ScPal.HAIR, 5 * s, true)
	ci.draw_circle(head + Vector2(-4, -7) * s, 3.5 * s, Color(1, 1, 1, 0.35))
	# gezicht
	var ex := 4.5 * s
	var eye_y := 1.5 * s
	var blink := fmod(t + c.x * 0.013, 4.0) < 0.12
	for k in [-1.0, 1.0]:
		var e := head + Vector2(k * ex + facing * 2 * s, eye_y)
		if mood == 1 or blink:
			ci.draw_arc(e + Vector2(0, 1.2 * s), 2.4 * s, PI * 1.1, PI * 1.9, 6, ScPal.INK, 1.6 * s, true)
		elif mood == 2:
			ci.draw_circle(e, 2.4 * s, ScPal.INK)
		else:
			ci.draw_circle(e, 1.9 * s, ScPal.INK)
	ci.draw_circle(head + Vector2(-8 * s + facing * 2 * s, 6 * s), 2.6 * s, Color(ScPal.BLUSH, 0.5))
	ci.draw_circle(head + Vector2(8 * s + facing * 2 * s, 6 * s), 2.6 * s, Color(ScPal.BLUSH, 0.5))
	if mood == 2:
		ci.draw_circle(head + Vector2(facing * 2 * s, 8 * s), 2.0 * s, ScPal.INK)
	else:
		ci.draw_arc(head + Vector2(facing * 2 * s, 6.5 * s), 3 * s, PI * 0.15, PI * 0.85, 6, ScPal.INK, 1.4 * s, true)
	# letter op de borst (blad = letter), als pigmentchip
	if sym != "":
		var chest := xp(Vector2(0, -15), o, s, facing, rot)
		var cs := 16.0 * s
		ci.draw_style_box(ScPal.sb(ScPal.letter_color(sym, alphabet), int(4 * s)), Rect2(chest - Vector2(cs * 0.62, cs * 0.62), Vector2(cs, cs) * 1.24))
		ScPal.text_c(ci, ScPal.MONO, chest, ScPal.show(sym), int(cs), ScPal.INK)
	var top := head + Vector2(0, -16 * s)
	var card_r := Rect2()
	if card != "":
		var fs := int(maxf(16.0, 17.0 * s))
		var w := ScPal.text_w(ScPal.MONO_B, card, fs) + 14
		card_r = Rect2(top + Vector2(-w / 2, -fs * 1.55 - 4), Vector2(w, fs * 1.45))
		ci.draw_line(top, card_r.get_center() + Vector2(0, card_r.size.y / 2), ScPal.INK_SOFT, 1.2, true)
		ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 5, 3, ScPal.VELLUM_EDGE), card_r)
		ScPal.text_c(ci, ScPal.MONO_B, card_r.get_center() + Vector2(0, -1), card, fs, ScPal.INK)
		top = card_r.position + Vector2(card_r.size.x / 2, 0)
	if lantern:
		lantern_(ci, top + Vector2(0, -26 * s), s * 0.9, t)
	return card_r


## Lantaarn (wijst t aan in de levende boom; ook sfeerlicht).
static func lantern_(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0) -> void:
	var sw := sin(t * 2.4) * 0.08
	glow(ci, c + Vector2(0, 4 * s), 70 * s, Color(ScPal.GLOW, 0.45 + 0.08 * sin(t * 9.0)))
	ci.draw_line(c + Vector2(0, -22 * s), c + Vector2(0, -12 * s), ScPal.IRON, 2.0 * s, true)
	ci.draw_arc(c + Vector2(0, -24 * s), 4 * s, 0, TAU, 10, ScPal.IRON, 2.0 * s, true)
	var body := PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(10, 10), Vector2(-10, 10)])
	fill(ci, xf(body, c, s, 1.0, sw), Color(ScPal.FLAME, 0.85))
	ci.draw_circle(xp(Vector2(0, 2), c, s, 1.0, sw), 4 * s, ScPal.FLAME_CORE)
	for x in [-9.0, 0.0, 9.0]:
		ci.draw_line(xp(Vector2(x * 0.85, -12), c, s, 1.0, sw), xp(Vector2(x * 1.05, 10), c, s, 1.0, sw), ScPal.IRON, 2.0 * s, true)
	fill(ci, xf(PackedVector2Array([Vector2(-11, -12), Vector2(0, -20), Vector2(11, -12)]), c, s, 1.0, sw), ScPal.IRON)
	ci.draw_rect(Rect2(xp(Vector2(-12, 9), c, s, 1.0, sw), Vector2(24, 4) * s), ScPal.IRON)


## Broeder Zeno (mentor): oude bibliothecaris, zwart habijt, witte baard, brilletje. `talk` 0..1 opent de mond.
static func zeno(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, talk := 0.0, facing := 1.0) -> void:
	_bust(ci, c, s, t, ScPal.HABIT_ZENO, facing, talk, true, true, false)


## Broeder Letterlijk (de lezer aan de overkant) achter zijn lessenaar met een open boek.
## mood: 0 leest (mond op en neer met `talk`), 1 blij (zingt), 2 fronst (onzin), 3 schraapt zijn keel.
static func letterlijk(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, mood := 0, talk := 0.0) -> void:
	_bust(ci, c + Vector2(0, -10 * s), s, t, ScPal.HABIT_LETTERLIJK, 1.0, talk, false, false, true, mood)
	# lessenaar
	var top := c + Vector2(0, 10 * s)
	var desk := PackedVector2Array([top + Vector2(-80, -6) * s, top + Vector2(80, -26) * s, top + Vector2(86, -10) * s, top + Vector2(-74, 10) * s])
	fill(ci, xf(desk, Vector2(4, 6), 1.0), ScPal.SHADOW, false)
	fill(ci, desk, ScPal.OAK_DARK)
	ci.draw_rect(Rect2(top + Vector2(-14, 4) * s, Vector2(28, 90) * s), ScPal.WALNUT)
	ci.draw_rect(Rect2(top + Vector2(-44, 88) * s, Vector2(88, 12) * s), ScPal.WALNUT)
	# open boek
	var bk := PackedVector2Array([top + Vector2(-66, -12) * s, top + Vector2(0, -28) * s, top + Vector2(68, -40) * s,
		top + Vector2(70, -26) * s, top + Vector2(0, -12) * s, top + Vector2(-64, 2) * s])
	fill(ci, bk, ScPal.VELLUM)
	ci.draw_line(top + Vector2(0, -28) * s, top + Vector2(0, -12) * s, ScPal.VELLUM_AGED, 2.0, true)
	for k in 4:
		var f := 0.25 + k * 0.17
		ci.draw_line(top + Vector2(-58 + 4 * k, -9 - 3 * k) * s, top + Vector2(-10, -21 - 3 * k) * s * Vector2(1, 1), Color(ScPal.INK_SOFT, 0.6), 1.5, true)
		ci.draw_line(top + Vector2(8, -25 - 3 * k) * s, top + Vector2(60, -35 - 3 * k + f) * s, Color(ScPal.INK_SOFT, 0.6), 1.5, true)
	# handen op het boek
	ci.draw_circle(top + Vector2(-46, -14) * s, 7 * s, ScPal.SKIN)
	ci.draw_circle(top + Vector2(48, -32) * s, 7 * s, ScPal.SKIN)


## Kelner Gommaar (boekhouder): bruin habijt, sleutelbos, kasboek onder de arm.
static func gommaar(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, talk := 0.0) -> void:
	_bust(ci, c, s * 1.05, t, ScPal.HABIT_GOMMAAR, -1.0, talk, false, false, false, 0, true)
	# kasboek
	var b := Rect2(c + Vector2(18, -60) * s, Vector2(56, 70) * s)
	ci.draw_rect(Rect2(b.position + Vector2(4, 4), b.size), ScPal.SHADOW)
	ci.draw_rect(b, ScPal.RUBRIC.darkened(0.3))
	ci.draw_rect(Rect2(b.position + Vector2(b.size.x - 8 * s, 2 * s), Vector2(6 * s, b.size.y - 4 * s)), ScPal.VELLUM)
	ScPal.ring(ci, b.grow(-6 * s), 2, ScPal.GILT, 2)
	ScPal.text_c(ci, ScPal.TITLE, b.get_center(), "℔", int(26 * s), ScPal.GILT)
	# sleutels
	for k in 3:
		var p := c + Vector2(-26 + k * 5, -18 + k * 3) * s
		ci.draw_line(p, p + Vector2(2, 16) * s, ScPal.BRASS, 2.5 * s, true)
		ci.draw_circle(p, 3.5 * s, ScPal.BRASS_DARK)


static func _bust(ci: CanvasItem, c: Vector2, s: float, t: float, habit: Color, facing: float, talk: float, beard: bool,
		glasses: bool, tonsure: bool, mood := 0, plump := false) -> void:
	var breath := sin(t * 1.6) * 1.5 * s
	var wide := 1.25 if plump else 1.0
	# schouders + kap
	var body := PackedVector2Array([Vector2(-62 * wide, 60), Vector2(-54 * wide, 0), Vector2(-30, -26), Vector2(30, -26),
		Vector2(54 * wide, 0), Vector2(62 * wide, 60)])
	fill(ci, xf(body, c + Vector2(0, breath * 0.5), s, facing), habit)
	fill(ci, xf(PackedVector2Array([Vector2(10, -26), Vector2(30, -26), Vector2(54 * wide, 0), Vector2(62 * wide, 60), Vector2(20, 60)]), c + Vector2(0, breath * 0.5), s, facing), habit.darkened(0.15))
	fill(ci, xf(PackedVector2Array([Vector2(-34, -22), Vector2(34, -22), Vector2(26, 6), Vector2(-26, 6)]), c, s, facing), habit.darkened(0.3))
	var head := c + Vector2(0, -52 * s + breath)
	ellipse(ci, head + Vector2(0, 10 * s), 36 * s, 30 * s, habit.darkened(0.3))
	ci.draw_circle(head, 30 * s, ScPal.SKIN)
	ellipse(ci, head + Vector2(10, 4) * s * Vector2(facing, 1), 20 * s, 26 * s, Color(ScPal.SKIN_SHADE, 0.35))
	if tonsure:
		ci.draw_arc(head + Vector2(0, -4 * s), 29 * s, PI * 0.92, PI * 2.08, 20, ScPal.HAIR, 9 * s, true)
	else:
		ci.draw_arc(head + Vector2(0, -2 * s), 29 * s, PI * 0.88, PI * 2.12, 20, ScPal.BEARD if beard else ScPal.HAIR, 8 * s, true)
	ci.draw_circle(head + Vector2(-10, -14) * s, 6 * s, Color(1, 1, 1, 0.3))
	# ogen en wenkbrauwen
	var blink := fmod(t + 1.7, 4.3) < 0.12
	for k in [-1.0, 1.0]:
		var e := head + Vector2(k * 11 + facing * 3, -2) * s
		if blink or mood == 1:
			ci.draw_arc(e + Vector2(0, 2 * s), 4 * s, PI * 1.1, PI * 1.9, 6, ScPal.INK, 2.4 * s, true)
		else:
			ci.draw_circle(e, 3.6 * s, ScPal.INK)
			ci.draw_circle(e + Vector2(-1.2, -1.2) * s, 1.2 * s, Color(1, 1, 1, 0.8))
		var tilt := 0.0
		if mood == 2:
			tilt = 0.35 * k
		elif mood == 3:
			tilt = -0.2 * k
		var bc := e + Vector2(0, -9 * s)
		ci.draw_line(bc + Vector2(-6, -tilt * 8) * s, bc + Vector2(6, tilt * 8) * s, ScPal.BEARD.darkened(0.3) if beard else ScPal.HAIR, 2.6 * s, true)
		if glasses:
			ci.draw_arc(e, 8 * s, 0, TAU, 16, ScPal.BRASS_DARK, 2.2 * s, true)
	if glasses:
		ci.draw_line(head + Vector2(-3 + facing * 3, -2) * s, head + Vector2(3 + facing * 3, -2) * s, ScPal.BRASS_DARK, 2.0 * s, true)
	ci.draw_circle(head + Vector2(-18 + facing * 2, 8) * s, 5 * s, Color(ScPal.BLUSH, 0.45))
	ci.draw_circle(head + Vector2(18 + facing * 2, 8) * s, 5 * s, Color(ScPal.BLUSH, 0.45))
	# baard
	var mouth := head + Vector2(facing * 3, 14) * s
	if beard:
		var bd := PackedVector2Array([Vector2(-22, 4), Vector2(22, 4), Vector2(16, 30), Vector2(0, 42), Vector2(-16, 30)])
		fill(ci, xf(bd, head + Vector2(facing * 2, 4 * s), s), ScPal.BEARD)
		ci.draw_line(mouth + Vector2(-9, -4) * s, mouth + Vector2(9, -4) * s, ScPal.BEARD.darkened(0.15), 4 * s, true)
		mouth += Vector2(0, 2 * s)
	var open := clampf(talk, 0, 1) * (0.5 + 0.5 * absf(sin(t * 14.0)))
	if mood == 1:
		ellipse(ci, mouth, 6 * s, (3 + 4 * maxf(open, 0.5)) * s, ScPal.INK.lightened(0.15))
	elif mood == 2:
		ci.draw_arc(mouth + Vector2(0, 5 * s), 6 * s, PI * 1.2, PI * 1.8, 8, ScPal.INK, 2.4 * s, true)
	elif open > 0.05:
		ellipse(ci, mouth, 5 * s, (1.5 + 5 * open) * s, ScPal.INK.lightened(0.15))
	else:
		ci.draw_arc(mouth, 6 * s, PI * 0.15, PI * 0.85, 8, ScPal.INK, 2.4 * s, true)
	if mood == 3:
		ScPal.text_c(ci, ScPal.UI_BOLD, head + Vector2(44, -30) * s, "hm-hm", int(18 * s), ScPal.INK_SOFT)


## Postduif. pose 0 zit, 1 vliegt (vleugels klapperen), 2 landt. `tube` = koker aan de poot. mood 1 = kijkt verwijtend
## (tweede duif), 2 = blij.
static func dove(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, pose := 0, facing := 1.0, mood := 0, tube := true) -> void:
	var bob := sin(t * (9.0 if pose == 1 else 2.2)) * (3.0 if pose == 1 else 1.0) * s
	var o := c + Vector2(0, bob)
	if pose == 0:
		ellipse(ci, c + Vector2(4, 22) * s, 24 * s, 5 * s, ScPal.SHADOW_SOFT)
	# staart
	fill(ci, xf(PackedVector2Array([Vector2(-18, 2), Vector2(-42, -4), Vector2(-44, 6), Vector2(-20, 12)]), o, s, facing), ScPal.DOVE_DARK)
	# vleugel achter (vliegend)
	var flap := sin(t * 18.0) if pose == 1 else 0.0
	if pose == 1:
		fill(ci, xf(PackedVector2Array([Vector2(-6, -6), Vector2(-26, -34 - 14 * flap), Vector2(4, -40 - 16 * flap), Vector2(12, -8)]), o, s, facing), ScPal.DOVE_DARK)
	# lijf
	ellipse(ci, o + Vector2(-2 * facing, 2) * s, 26 * s, 18 * s, ScPal.DOVE)
	ellipse(ci, o + Vector2(4 * facing, 8) * s, 16 * s, 10 * s, ScPal.DOVE.lightened(0.15))
	# hals (iriserend)
	ellipse(ci, o + Vector2(14 * facing, -10) * s, 10 * s, 11 * s, ScPal.DOVE_NECK)
	ellipse(ci, o + Vector2(17 * facing, -6) * s, 6 * s, 6 * s, ScPal.DOVE_NECK2)
	var head := o + Vector2(20 * facing, -20) * s
	ci.draw_circle(head, 10 * s, ScPal.DOVE)
	fill(ci, xf(PackedVector2Array([Vector2(8, -2), Vector2(17, 1), Vector2(8, 3)]), head, s, facing), ScPal.DOVE_BEAK)
	ci.draw_circle(head + Vector2(8 * facing, -3) * s, 2.6 * s, Color.WHITE)
	var eye := head + Vector2(3 * facing, -2) * s
	ci.draw_circle(eye, 3.2 * s, Color("#E9935A"))
	ci.draw_circle(eye, 1.9 * s, ScPal.INK)
	if mood == 1:
		ci.draw_line(eye + Vector2(-4, -5) * s, eye + Vector2(4 * facing, -3) * s, ScPal.INK, 2.0 * s, true)
	elif mood == 2:
		ci.draw_arc(eye + Vector2(0, 1 * s), 3 * s, PI * 1.1, PI * 1.9, 6, ScPal.INK, 1.8 * s, true)
	# vleugel voor
	if pose == 1:
		fill(ci, xf(PackedVector2Array([Vector2(-8, -2), Vector2(-30, -30 - 18 * flap), Vector2(-4, -44 - 20 * flap), Vector2(14, -4)]), o, s, facing), ScPal.DOVE.lightened(0.05))
		for k in 3:
			var p := xp(Vector2(-18 + k * 8, -34 - 18 * flap), o, s, facing)
			ci.draw_line(p, p + Vector2(0, 8) * s, ScPal.DOVE_DARK, 2.0 * s, true)
	else:
		fill(ci, xf(PackedVector2Array([Vector2(-20, -6), Vector2(8, -10), Vector2(10, 6), Vector2(-14, 10)]), o, s, facing), ScPal.DOVE.darkened(0.08))
		for k in 3:
			ci.draw_line(xp(Vector2(-16 + k * 4, 4 + k), o, s, facing), xp(Vector2(-4 + k * 4, 2 + k), o, s, facing), ScPal.DOVE_DARK, 2.0 * s, true)
	# pootjes + koker
	if pose != 1:
		for fx in [-2.0, 6.0]:
			ci.draw_line(xp(Vector2(fx, 16), o, s, facing), xp(Vector2(fx, 24), c, s, facing), ScPal.DOVE_BEAK, 2.5 * s, true)
	if tube:
		var tp := xp(Vector2(3, 20 if pose != 1 else 16), o, s, facing)
		ci.draw_rect(Rect2(tp - Vector2(7, 4) * s, Vector2(14, 8) * s), ScPal.OAK_DARK)
		ci.draw_rect(Rect2(tp - Vector2(7, 4) * s, Vector2(3, 8) * s), ScPal.BRASS)


## Spookhand (inkthand): doorschijnende wijzende hand (tutorial/hint). `tip` = vingertop.
static func inkhand(ci: CanvasItem, tip: Vector2, s := 1.0, t := 0.0, a := 0.6, press := 0.0) -> void:
	var o := tip + Vector2(0, (sin(t * 4.0) * 4.0 + press * 6.0) * s)
	var col := Color(ScPal.GOLD_LIGHT, a * 0.5)
	var edge := Color(ScPal.GOLD, a)
	var hand := PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(6, 34), Vector2(22, 36), Vector2(30, 44),
		Vector2(30, 76), Vector2(18, 92), Vector2(-14, 92), Vector2(-22, 70), Vector2(-26, 46), Vector2(-16, 40), Vector2(-6, 42)])
	var p := xf(hand, o, s)
	fill(ci, p, col)
	outline(ci, p, edge, 2.0)
	for k in 3:
		ci.draw_line(xp(Vector2(4 + k * 8, 46), o, s), xp(Vector2(4 + k * 8, 58), o, s), Color(ScPal.GOLD, a * 0.6), 1.5, true)
	ci.draw_arc(o, (8 + press * 10) * s, 0, TAU, 16, Color(ScPal.GOLD, a * (1.0 - press)), 2.0, true)


## Spreekrol (Zeno-ballon): perkamentrol met opgekrulde uiteinden en een staartje naar de spreker.
static func scroll(ci: CanvasItem, r: Rect2, tail := Vector2.INF, seed_ := 9) -> void:
	if tail != Vector2.INF:
		var bx := clampf(tail.x, r.position.x + 30, r.end.x - 30)
		var by := r.end.y if tail.y > r.end.y else r.position.y
		fill(ci, PackedVector2Array([Vector2(bx - 14, by), Vector2(bx + 14, by), tail]), ScPal.VELLUM_EDGE)
	parchment(ci, r, seed_, ScPal.VELLUM_HI, true, 0.4, 1.5)
	for side in [-1.0, 1.0]:
		var x: float = r.position.x if side < 0 else r.end.x
		var cr := Rect2(Vector2(x - 9, r.position.y - 6), Vector2(18, r.size.y + 12))
		ci.draw_style_box(ScPal.sb(ScPal.VELLUM_EDGE, 9), cr)
		ci.draw_line(Vector2(x, r.position.y - 4), Vector2(x, r.end.y + 4), Color(ScPal.VELLUM_AGED, 0.8), 2.0, true)
		ci.draw_line(Vector2(x - 4 * side, r.position.y), Vector2(x - 4 * side, r.end.y), Color(1, 1, 1, 0.4), 1.5, true)


# ================================================================ HUD
## Inktmeter: inktpotje + balk met druppelteller, geesten "gewoon" en "optimum". Boven het optimum: amber.
static func ink_meter(ci: CanvasItem, r: Rect2, ink: int, opt: int, plain: int, t := 0.0, show_opt := true) -> void:
	var over := opt > 0 and ink > opt
	inkpot(ci, r.position + Vector2(24, r.size.y * 0.5 + 14), 0.55, 1.0, over, t)
	var vx := r.position.x + 56
	ScPal.text_l(ci, ScPal.MONO_B, Vector2(vx, r.size.y * 0.5 + r.position.y), "%d" % ink, 30, ScPal.WARN if over else ScPal.TEXT)
	var bar := Rect2(Vector2(vx + 74, r.position.y + r.size.y * 0.5 - 13), Vector2(r.size.x - (vx + 74 - r.position.x), 26))
	ci.draw_style_box(ScPal.sb(ScPal.SLOT, 13), bar)
	var mx := float(maxi(plain, maxi(ink, opt)))
	var fw := bar.size.x * clampf(ink / mx, 0, 1) if mx > 0 else 0.0
	if fw > 2:
		var fr := Rect2(bar.position, Vector2(maxf(fw, 26), bar.size.y))
		ci.draw_style_box(ScPal.sb(ScPal.WARN if over else Color("#2E3550"), 13), fr)
		ci.draw_line(fr.position + Vector2(10, 6), Vector2(fr.end.x - 10, fr.position.y + 6), Color(1, 1, 1, 0.22), 2.0, true)
	var used_x0 := INF
	var used_x1 := -INF
	for g in [[plain, "gewoon %d" % plain, ScPal.TEXT_DIM], [opt, "optimum %d" % opt, ScPal.GOLD]]:
		if int(g[0]) <= 0 or (not show_opt and g[2] == ScPal.GOLD):
			continue
		var gx := bar.position.x + bar.size.x * clampf(float(g[0]) / mx, 0, 1)
		ci.draw_line(Vector2(gx, bar.position.y - 5), Vector2(gx, bar.end.y + 5), g[2], 3.0, true)
		var tw := ScPal.text_w(ScPal.UI_MED, g[1], 16)
		var tx := gx - tw - 8 if gx + tw + 8 > bar.end.x else gx + 8
		if g[2] == ScPal.GOLD:
			# botst het label "optimum" met "gewoon": links van de eigen streep, desnoods vóór het label "gewoon"
			if tx + tw + 12 > used_x0 and tx < used_x1 + 12:
				tx = gx - tw - 8
				if tx + tw + 12 > used_x0 and tx < used_x1 + 12:
					tx = used_x0 - tw - 12
			tx = maxf(tx, bar.position.x + 8)
		else:
			used_x0 = tx
			used_x1 = tx + tw
		ScPal.text_l(ci, ScPal.UI_MED, Vector2(tx, bar.get_center().y), g[1], 16, g[2])


## Duivenkoker (leer + koper): lengte = optimum; `fill` 0..>1 hoeveel kortschrift erin zit (> 1 steekt uit, krult).
static func koker(ci: CanvasItem, left_mid: Vector2, length: float, fill_: float, t := 0.0, h := 26.0) -> void:
	var r := Rect2(left_mid - Vector2(0, h / 2), Vector2(length, h))
	ci.draw_style_box(ScPal.sb(ScPal.SHADOW, int(h / 2)), Rect2(r.position + Vector2(4, 6), r.size))
	var strip_w := length * minf(fill_, 1.0)
	ci.draw_style_box(ScPal.sb(ScPal.OAK_DARK, int(h / 2)), r)
	ci.draw_style_box(ScPal.sb(ScPal.SLOT, int(h * 0.3)), Rect2(r.position + Vector2(8, h * 0.32), Vector2(length - 16, h * 0.36)))
	if strip_w > 0:
		ci.draw_rect(Rect2(r.position + Vector2(8, h * 0.36), Vector2(maxf(0, strip_w - 16), h * 0.28)), ScPal.VELLUM)
	ci.draw_line(r.position + Vector2(h / 2, 3), Vector2(r.end.x - h / 2, r.position.y + 3), Color(1, 1, 1, 0.2), 2.0, true)
	for x in [r.position.x + 6, r.end.x - 10]:
		ci.draw_rect(Rect2(Vector2(x, r.position.y - 2), Vector2(5, h + 4)), ScPal.BRASS)
	if fill_ > 1.0:
		var over := length * (fill_ - 1.0)
		var p0 := Vector2(r.end.x, left_mid.y)
		var pts := curve(p0, p0 + Vector2(over * 0.6, 0), p0 + Vector2(over, -6 + sin(t * 3.0) * 2), p0 + Vector2(over + 10, -20), 16)
		ci.draw_polyline(pts, ScPal.WARN, 7.0, true)
		ci.draw_polyline(pts, ScPal.VELLUM, 4.0, true)


## Teller-pil op leer (touw, zoekwerk, klemmen, nullen). icon: "twine", "search", "bump", "zero", "dove", "candle".
static func pill(ci: CanvasItem, r: Rect2, icon: String, text: String, t := 0.0, col := ScPal.PANEL_LO, warn := false) -> void:
	ci.draw_style_box(ScPal.sb(col, int(r.size.y / 2)), r)
	ScPal.ring(ci, r, int(r.size.y / 2), Color(ScPal.GILT, 0.5), 1)
	var c := r.position + Vector2(r.size.y / 2 + 4, r.size.y / 2)
	tool_icon(ci, c, r.size.y * 0.32, icon, ScPal.WARN if warn else ScPal.GILT_LIGHT, t)
	ScPal.text_l(ci, ScPal.MONO_B, Vector2(c.x + r.size.y * 0.5, c.y), text, int(r.size.y * 0.48), ScPal.WARN if warn else ScPal.TEXT)


## Lijn-iconen (goudstempel op leer). kind: codeboom, codebord, binderij, levende_boom, meetlat, leesraam, stempelkast,
## draaitrommel, letterplank, duiventil, codex, twine, search, bump, zero, dove, candle, ink, hint, undo, pause, notes.
static func tool_icon(ci: CanvasItem, c: Vector2, s: float, kind: String, col: Color, t := 0.0) -> void:
	var w := maxf(1.6, s * 0.16)
	match kind:
		"codeboom", "levende_boom":
			var pts := [Vector2(0, -0.8), Vector2(-0.55, -0.05), Vector2(0.55, -0.05), Vector2(-0.8, 0.75), Vector2(-0.3, 0.75)]
			for e in [[0, 1], [0, 2], [1, 3], [1, 4]]:
				ci.draw_line(c + pts[e[0]] * s, c + pts[e[1]] * s, col, w, true)
			for p in pts:
				ci.draw_circle(c + p * s, s * 0.16, col)
			if kind == "levende_boom":
				ci.draw_circle(c + Vector2(0.55, -0.05) * s, s * 0.28, col)
				ci.draw_circle(c + Vector2(0.55, 0.75) * s, s * 0.13, col)
		"codebord":
			ScPal.ring(ci, Rect2(c - Vector2(0.85, 0.85) * s, Vector2(1.7, 1.7) * s), int(s * 0.2), col, int(w))
			ci.draw_line(c + Vector2(0, -0.5) * s, c + Vector2(-0.45, 0.4) * s, col, w, true)
			ci.draw_line(c + Vector2(0, -0.5) * s, c + Vector2(0.45, 0.4) * s, col, w, true)
		"binderij":
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-0.8, 0.45 - k * 0.38) * s, Vector2(1.6, 0.28) * s), col, false, w)
			ci.draw_line(c + Vector2(-0.2, -0.9) * s, c + Vector2(0.2, 0.9) * s, col, w, true)
			ci.draw_circle(c + Vector2(0, 0) * s, s * 0.14, col)
		"meetlat":
			ci.draw_rect(Rect2(c + Vector2(-0.35, -0.9) * s, Vector2(0.7, 1.8) * s), col, false, w)
			for k in 5:
				ci.draw_line(c + Vector2(-0.35, -0.6 + k * 0.3) * s, c + Vector2(0.05, -0.6 + k * 0.3) * s, col, w * 0.8, true)
		"leesraam":
			ci.draw_rect(Rect2(c + Vector2(-0.9, -0.5) * s, Vector2(1.8, 1.0) * s), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.7) * s, Vector2(1.1, 1.4) * s), col, false, w * 1.4)
		"stempelkast":
			for i in 2:
				for j in 2:
					ci.draw_rect(Rect2(c + Vector2(-0.85 + i * 0.9, -0.85 + j * 0.9) * s, Vector2(0.8, 0.8) * s), col, false, w)
					ci.draw_circle(c + Vector2(-0.45 + i * 0.9, -0.45 + j * 0.9) * s, s * 0.09, col)
		"draaitrommel":
			ci.draw_arc(c + Vector2(0, -0.55) * s, s * 0.7, PI, TAU, 10, col, w, true)
			ci.draw_line(c + Vector2(-0.7, -0.55) * s, c + Vector2(-0.7, 0.55) * s, col, w, true)
			ci.draw_line(c + Vector2(0.7, -0.55) * s, c + Vector2(0.7, 0.55) * s, col, w, true)
			ci.draw_arc(c + Vector2(0, 0.55) * s, s * 0.7, 0, PI, 10, col, w, true)
			ci.draw_arc(c + Vector2(0, -0.55) * s, s * 0.7, 0, PI, 10, Color(col, 0.6), w * 0.7, true)
		"letterplank":
			ci.draw_line(c + Vector2(-0.95, 0.45) * s, c + Vector2(0.95, 0.45) * s, col, w * 1.4, true)
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-0.85 + k * 0.6, -0.15) * s, Vector2(0.5, 0.55) * s), col, false, w)
		"duiventil", "dove":
			ellipse(ci, c + Vector2(-0.1, 0.15) * s, s * 0.6, s * 0.4, col)
			ci.draw_circle(c + Vector2(0.45, -0.35) * s, s * 0.25, col)
			fill(ci, PackedVector2Array([c + Vector2(0.65, -0.4) * s, c + Vector2(0.95, -0.3) * s, c + Vector2(0.65, -0.22) * s]), col)
		"codex":
			ci.draw_rect(Rect2(c + Vector2(-0.75, -0.9) * s, Vector2(1.5, 1.8) * s), col, false, w)
			ci.draw_line(c + Vector2(-0.45, -0.9) * s, c + Vector2(-0.45, 0.9) * s, col, w, true)
			star(ci, c + Vector2(0.15, 0) * s, s * 0.35, col)
		"twine":
			ci.draw_circle(c, s * 0.75, Color(col, 0.0))
			ci.draw_arc(c, s * 0.7, 0, TAU, 16, col, w, true)
			for k in 3:
				ci.draw_line(c + Vector2(-0.6, -0.35 + k * 0.35) * s, c + Vector2(0.6, -0.35 + k * 0.35) * s, col, w * 0.7, true)
		"search":
			ci.draw_arc(c + Vector2(-0.15, -0.15) * s, s * 0.5, 0, TAU, 14, col, w, true)
			ci.draw_line(c + Vector2(0.2, 0.2) * s, c + Vector2(0.75, 0.75) * s, col, w * 1.4, true)
		"bump":
			ci.draw_line(c + Vector2(-0.7, 0.6) * s, c + Vector2(0.7, 0.6) * s, col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-0.5, -0.4) * s, Vector2(1.0, 0.7) * s), col, false, w)
			ci.draw_line(c + Vector2(-0.6, -0.8) * s, c + Vector2(-0.3, -0.55) * s, col, w, true)
			ci.draw_line(c + Vector2(0.6, -0.8) * s, c + Vector2(0.3, -0.55) * s, col, w, true)
		"zero":
			ScPal.text_c(ci, ScPal.MONO_B, c, "0", int(s * 1.6), col)
		"candle":
			ci.draw_rect(Rect2(c + Vector2(-0.25, -0.2) * s, Vector2(0.5, 1.0) * s), col)
			fill(ci, _teardrop(c + Vector2(0, -0.3) * s, s * 0.18, s * 0.6, sin(t * 6.0) * s * 0.05), col)
		"ink":
			drop(ci, c, s * 0.8, col, false)
		"hint":
			ci.draw_arc(c + Vector2(0, -0.2) * s, s * 0.5, PI * 0.9, PI * 2.1, 12, col, w, true)
			ci.draw_line(c + Vector2(0.3, 0.15) * s, c + Vector2(0, 0.35) * s, col, w, true)
			ci.draw_circle(c + Vector2(0, 0.7) * s, s * 0.12, col)
		"undo":
			ci.draw_arc(c, s * 0.6, PI * 1.2, PI * 2.6, 14, col, w, true)
			fill(ci, PackedVector2Array([c + Vector2(-0.85, -0.55) * s, c + Vector2(-0.2, -0.45) * s, c + Vector2(-0.6, 0.05) * s]), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-0.45, -0.6) * s, Vector2(0.3, 1.2) * s), col)
			ci.draw_rect(Rect2(c + Vector2(0.15, -0.6) * s, Vector2(0.3, 1.2) * s), col)
		"notes":
			ci.draw_rect(Rect2(c + Vector2(-0.6, -0.8) * s, Vector2(1.2, 1.6) * s), col, false, w)
			for k in 3:
				ci.draw_line(c + Vector2(-0.35, -0.4 + k * 0.4) * s, c + Vector2(0.35, -0.4 + k * 0.4) * s, col, w * 0.8, true)
		_:
			ci.draw_circle(c, s * 0.5, col)
