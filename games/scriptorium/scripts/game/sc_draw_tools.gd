class_name ScDrawTools
extends Object
## Kortschrift: de werktuigen (design/ART.md §5.3–5.9). Statisch, zoals ScDraw. Elk werktuig is hout, perkament,
## touw, was of koper; de leerstof (letters, bits, codes, getallen) staat altijd in JetBrains Mono, INK op perkament.
## Functies geven waar nuttig klikzones (Rect2) of ankerpunten terug zodat de front-end er input op kan zetten.


# ================================================================ codeboom / binderij / levende boom
## Houten tak tussen twee toppen met het bit (0 links, 1 rechts) op een schijfje halverwege. `hi` = gouden pad.
static func branch(ci: CanvasItem, a: Vector2, b: Vector2, bit := "", hi := false, w := 7.0, t := 0.0, ghost := false) -> void:
	if ghost:
		var n := int(a.distance_to(b) / 12.0)
		for i in n:
			if i % 2 == 0:
				ci.draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(ScPal.GOLD_LIGHT, 0.8), 3.0, true)
		return
	if hi:
		ci.draw_line(a, b, Color(ScPal.GOLD, 0.35 + 0.1 * sin(t * 6.0)), w + 10, true)
	ci.draw_line(a + Vector2(3, 5), b + Vector2(3, 5), ScPal.SHADOW_SOFT, w, true)
	ci.draw_line(a, b, ScPal.OAK_DARK, w, true)
	var n2 := (b - a).normalized().orthogonal()
	ci.draw_line(a - n2 * w * 0.2, b - n2 * w * 0.2, ScPal.OAK, w * 0.45, true)
	if bit != "":
		var m := a.lerp(b, 0.5)
		ci.draw_circle(m + Vector2(1.5, 2.5), 13, ScPal.SHADOW_SOFT)
		ci.draw_circle(m, 13, ScPal.GOLD if hi else ScPal.VELLUM_HI)
		ci.draw_arc(m, 13, 0, TAU, 20, ScPal.OAK_DARK, 2.0, true)
		ScPal.text_c(ci, ScPal.MONO_B, m, bit, 18, ScPal.INK)


## Knoop (interne top): houten pin met een optioneel gewicht erop.
static func knob(ci: CanvasItem, c: Vector2, r := 15.0, hi := false, label := "", t := 0.0) -> void:
	if hi:
		ci.draw_circle(c, r + 8 + sin(t * 6.0), Color(ScPal.INFO, 0.35))
	ci.draw_circle(c + Vector2(3, 4), r, ScPal.SHADOW)
	ci.draw_circle(c, r, ScPal.OAK_DARK)
	ci.draw_circle(c + Vector2(-1, -1.5), r * 0.78, ScPal.OAK)
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.3))
	if label != "":
		ScPal.text_c(ci, ScPal.MONO_B, c, label, int(r * 1.05), ScPal.VELLUM_HI)


## Blad = lettertegel aan een touwtje onder `top`. `code` (klein, onder de tegel) = het codewoord.
## Geeft de klikzone terug.
static func leaf_tile(ci: CanvasItem, top: Vector2, ch: String, size := 30, alphabet := "", hi := false, code := "",
		t := 0.0, weight := -1, dim := false) -> Rect2:
	var sway := sin(t * 1.7 + top.x * 0.03) * 2.0
	var c := top + Vector2(sway, 30 + size * 0.6)
	ci.draw_line(top, c - Vector2(0, size * 0.62), ScPal.TWINE_DARK, 2.0, true)
	var r := Rect2(c - Vector2(size * 0.7, size * 0.66), Vector2(size * 1.4, size * 1.32))
	if hi:
		ScPal.ring(ci, r.grow(6), int(size * 0.3), Color(ScPal.INFO, 0.85), 3)
	ci.draw_style_box(ScPal.sb(ScPal.SHADOW, int(size * 0.22)), Rect2(r.position + Vector2(3, 5), r.size))
	ci.draw_style_box(ScPal.sb_thick(ScPal.OAK, int(size * 0.24), 5, ScPal.OAK_DARK), r)
	var inner := r.grow(-5)
	inner.size.y -= 3
	var cc := ScPal.letter_color(ch, alphabet)
	if dim:
		cc.a = 0.5
	ci.draw_style_box(ScPal.sb(cc, int(size * 0.18)), inner)
	ScPal.text_c(ci, ScPal.MONO, inner.get_center(), ScPal.show(ch), size, Color(ScPal.INK, 0.5 if dim else 1.0))
	if weight >= 0:
		var wc := Vector2(r.end.x - 2, r.position.y + 2)
		ci.draw_circle(wc, 12, ScPal.PANEL)
		ScPal.text_c(ci, ScPal.MONO_B, wc, str(weight), 15, ScPal.TEXT)
	if code != "":
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(c.x, r.end.y + 16), code, 18, ScPal.INK_SOFT)
	return r


## Stapel perkamentstrookjes (binderij): hoogte ∝ gewicht, label met letter + gewicht. `selected` = opgetild.
## `bundle` = gebonden met touw. Geeft de klikzone terug.
static func pile(ci: CanvasItem, base: Vector2, label: String, w: int, alphabet := "", selected := false, t := 0.0,
		bundle := false, width := 86.0, hint := false) -> Rect2:
	var lift := -14.0 if selected else 0.0
	var n := mini(w, 16)
	var sh := 7.0 if w <= 10 else 112.0 / float(maxi(n, 1))
	var o := base + Vector2(0, lift)
	ScDraw.ellipse(ci, base + Vector2(4, 4), width * 0.55, 8, ScPal.SHADOW_SOFT)
	for k in n:
		var jx := (ScDraw._hash(k * 7 + label.hash() % 97) - 0.5) * 6.0
		var r := Rect2(o + Vector2(-width / 2 + jx, -(k + 1) * sh), Vector2(width, sh + 1))
		ci.draw_style_box(ScPal.sb(ScPal.VELLUM_EDGE if k % 2 == 0 else ScPal.VELLUM, 2), r)
		ci.draw_line(r.position + Vector2(3, sh), r.position + Vector2(width - 3, sh), Color(ScPal.VELLUM_AGED, 0.6), 1.0)
	var top_y := o.y - n * sh
	if bundle:
		for dx in [-width * 0.22, width * 0.22]:
			ci.draw_line(Vector2(o.x + dx, o.y), Vector2(o.x + dx, top_y), ScPal.TWINE_DARK, 4.0, true)
			ci.draw_line(Vector2(o.x + dx - 1, o.y), Vector2(o.x + dx - 1, top_y), ScPal.TWINE, 2.0, true)
		ci.draw_circle(Vector2(o.x, top_y - 2), 6, ScPal.TWINE_DARK)
		ci.draw_line(Vector2(o.x, top_y - 2), Vector2(o.x + 12, top_y + 10), ScPal.TWINE, 3.0, true)
		ci.draw_line(Vector2(o.x, top_y - 2), Vector2(o.x - 10, top_y + 12), ScPal.TWINE, 3.0, true)
	# kaartje bovenop: letter (chip) + gewicht
	var tag := Rect2(Vector2(o.x - 34, top_y - 50), Vector2(68, 42))
	ci.draw_style_box(ScPal.sb(ScPal.SHADOW, 7), Rect2(tag.position + Vector2(3, 4), tag.size))
	ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 7, 4, ScPal.VELLUM_EDGE), tag)
	if label.length() == 1:
		var chip := Rect2(tag.position + Vector2(6, 6), Vector2(26, 28))
		ci.draw_style_box(ScPal.sb(ScPal.letter_color(label, alphabet), 5), chip)
		ScPal.text_c(ci, ScPal.MONO, chip.get_center(), ScPal.show(label), 24, ScPal.INK)
		ScPal.text_c(ci, ScPal.MONO_B, tag.position + Vector2(50, 20), str(w), 24, ScPal.INK)
	else:
		ScPal.text_c(ci, ScPal.MONO_B, tag.get_center() + Vector2(0, -2), str(w), 26, ScPal.INK)
	if hint:
		ScPal.ring(ci, tag.grow(5), 10, Color(ScPal.GOLD, 0.6 + 0.3 * sin(t * 6.0)), 3)
	var zone := Rect2(Vector2(o.x - width / 2 - 6, tag.position.y - 6), Vector2(width + 12, o.y - tag.position.y + 12))
	if selected:
		ScPal.ring(ci, zone, 12, ScPal.INFO, 3)
	return zone


## Touwklos met teller (het touw = de bits, Stelling 21). `amber` = boven het optimum.
static func twine_spool(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, twine := 0, amber := false, spin := 0.0) -> void:
	ScDraw.ellipse(ci, c + Vector2(6, 46) * s, 46 * s, 10 * s, ScPal.SHADOW_SOFT)
	for y in [-38.0, 38.0]:
		ScDraw.ellipse(ci, c + Vector2(0, y) * s, 44 * s, 12 * s, ScPal.OAK_DARK)
		ScDraw.ellipse(ci, c + Vector2(0, y - 3) * s, 42 * s, 10 * s, ScPal.OAK)
	ci.draw_rect(Rect2(c + Vector2(-32, -36) * s, Vector2(64, 72) * s), ScPal.TWINE_DARK)
	for k in 12:
		var y := (-32 + k * 6 + fmod(spin * 20.0, 6.0)) * s
		ci.draw_line(c + Vector2(-32 * s, y), c + Vector2(32 * s, y + 3 * s), ScPal.TWINE, 2.5 * s, true)
	ci.draw_rect(Rect2(c + Vector2(-32, -36) * s, Vector2(10, 72) * s), Color(1, 1, 1, 0.12))
	ScDraw.ellipse(ci, c + Vector2(0, -41) * s, 42 * s, 10 * s, ScPal.OAK_LIGHT)
	ScDraw.ellipse(ci, c + Vector2(0, -41) * s, 8 * s, 3 * s, ScPal.WALNUT)
	var loose := ScDraw.curve(c + Vector2(32, 10) * s, c + Vector2(60, 20) * s, c + Vector2(50, 50) * s, c + Vector2(74, 56) * s, 12)
	ci.draw_polyline(loose, ScPal.TWINE_DARK, 3.0 * s, true)
	var tag := Rect2(c + Vector2(-46, 62) * s, Vector2(92, 40) * s)
	ci.draw_style_box(ScPal.sb(ScPal.PANEL, int(10 * s)), tag)
	ScPal.ring(ci, tag, int(10 * s), Color(ScPal.WARN if amber else ScPal.GILT, 0.8), 2)
	ScPal.text_c(ci, ScPal.MONO_B, tag.get_center(), "%d" % twine, int(24 * s), ScPal.WARN if amber else ScPal.TEXT)
	ScPal.text_c(ci, ScPal.UI_MED, tag.position + Vector2(tag.size.x / 2, tag.size.y + 14 * s), "touw = bits", int(16 * s), ScPal.TEXT_DIM)


## nng-zaadje [0,1] (levende boom): groen zaadje met kiempje en kaartje.
static func seed_nng(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, card := "[0,1]", hi := false, sprout := 0.0) -> Rect2:
	if hi:
		ci.draw_circle(c, 26 * s, Color(ScPal.INFO, 0.35 + 0.1 * sin(t * 7.0)))
	ScDraw.ellipse(ci, c + Vector2(3, 6) * s, 15 * s, 5 * s, ScPal.SHADOW_SOFT)
	ScDraw.ellipse(ci, c, 13 * s, 17 * s, ScPal.SEED_DARK, 0.3)
	ScDraw.ellipse(ci, c + Vector2(-2, -2) * s, 10 * s, 14 * s, ScPal.SEED, 0.3)
	ci.draw_line(c + Vector2(-4, 10) * s, c + Vector2(4, -12) * s, ScPal.SEED_DARK, 1.6 * s, true)
	var g := 1.0 + sprout * 1.5
	ci.draw_line(c + Vector2(2, -16) * s, c + Vector2(6, -26 * g) * s, ScPal.SEED_DARK, 2.4 * s, true)
	ScDraw.ellipse(ci, c + Vector2(12, -28 * g) * s, 7 * s, 3.5 * s, ScPal.SEED, -0.5 + sin(t * 2.0) * 0.1)
	ScPal.text_c(ci, ScPal.MONO_B, c + Vector2(0, 2 * s), "nng", int(11 * s), ScPal.VELLUM_HI)
	var tag := Rect2(c + Vector2(-28, 22) * s, Vector2(56, 24) * s)
	ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 5, 3, ScPal.VELLUM_EDGE), tag)
	ScPal.text_c(ci, ScPal.MONO_B, tag.get_center(), card, 16, ScPal.INK)
	return Rect2(c - Vector2(20, 26) * s, Vector2(40, 74) * s)


## Twee monniken hand in hand (broers 2j−1 en 2j in de processie, Lemma 22 (c)).
static func hand_link(ci: CanvasItem, a: Vector2, b: Vector2, s := 1.0) -> void:
	var y := maxf(a.y, b.y) - 24 * s
	ci.draw_polyline(ScDraw.curve(Vector2(a.x + 14 * s, y), Vector2(a.x + 24 * s, y + 8 * s), Vector2(b.x - 24 * s, y + 8 * s),
		Vector2(b.x - 14 * s, y), 10), ScPal.SKIN_SHADE, 4.0 * s, true)


# ================================================================ meetlat (aritmetisch coderen)
## Staande meetlat (0 onder, 1 boven; het huidige interval vult de hele lat). segs = [{sym, lo, hi}] met lo/hi als
## fracties 0..1 van de lat, `labels` = grenswaarden als tekst (bv. "0,2"), naast de lat. Vak `hi_sym` licht op;
## onderrand = volle lijn (dicht), bovenrand = stippellijn (open). `pin` 0..1 = speld (ontvangen), -1 = geen.
## Geeft per symbool de klikzone terug.
static func ruler(ci: CanvasItem, r: Rect2, segs: Array, hi_sym := "", pin := -1.0, t := 0.0, labels: Array = [],
		hatch := true) -> Dictionary:
	var zones := {}
	ScDraw.wood(ci, r.grow(14), ScPal.OAK, 10)
	ci.draw_rect(r, ScPal.VELLUM_HI)
	for k in segs.size():
		var sg: Dictionary = segs[k]
		var y0: float = r.end.y - r.size.y * float(sg["lo"])
		var y1: float = r.end.y - r.size.y * float(sg["hi"])
		var zr := Rect2(r.position.x, y1, r.size.x, y0 - y1)
		zones[sg["sym"]] = zr
		var col := ScPal.segment_color(k)
		if hi_sym != "" and sg["sym"] != hi_sym:
			col = col.lerp(ScPal.VELLUM, 0.45)
		ci.draw_rect(zr, col)
		if hatch:
			_hatch(ci, zr, ScPal.segment_hatch(k), Color(ScPal.INK, 0.16))
		if sg["sym"] == hi_sym:
			ci.draw_rect(zr, Color(ScPal.GOLD_LIGHT, 0.25 + 0.12 * sin(t * 5.0)))
		# onderrand dicht, bovenrand open (stippels)
		ci.draw_line(Vector2(r.position.x, y0), Vector2(r.end.x, y0), ScPal.INK, 3.0, true)
		var x := r.position.x
		while x < r.end.x:
			ci.draw_line(Vector2(x, y1 + 1.5), Vector2(minf(x + 8, r.end.x), y1 + 1.5), ScPal.INK, 2.0, true)
			x += 14
		if zr.size.y > 26:
			var chip := Rect2(zr.get_center() - Vector2(22, 20), Vector2(44, 40))
			ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 7, 4, ScPal.VELLUM_EDGE), chip)
			ScPal.text_c(ci, ScPal.MONO, chip.get_center() + Vector2(0, -2), ScPal.show(str(sg["sym"])), 28, ScPal.INK)
	for k in labels.size():
		if k > segs.size():
			break
		var f: float = float(segs[k]["lo"]) if k < segs.size() else 1.0
		var y := r.end.y - r.size.y * f
		ScPal.text_r(ci, ScPal.MONO_M, Vector2(r.position.x - 22, y), str(labels[k]), 20, ScPal.TEXT)
		ci.draw_line(Vector2(r.position.x - 16, y), Vector2(r.position.x - 4, y), ScPal.TEXT_DIM, 2.0, true)
	if pin >= 0.0:
		pin_(ci, Vector2(r.get_center().x, r.end.y - r.size.y * pin), 1.0, t)
	return zones


static func _hatch(ci: CanvasItem, r: Rect2, kind: int, col: Color) -> void:
	match kind:
		1:
			var d := -r.size.y
			while d < r.size.x:
				var a := Vector2(r.position.x + maxf(d, 0), r.end.y - maxf(-d, 0))
				var L := minf(r.end.x - a.x, a.y - r.position.y)
				ci.draw_line(a, a + Vector2(L, -L), col, 2.0, true)
				d += 14
		2:
			var x := r.position.x + 7
			while x < r.end.x:
				ci.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), col, 2.0)
				x += 14
		3:
			var y := r.position.y + 7
			while y < r.end.y:
				var x2 := r.position.x + 7
				while x2 < r.end.x:
					ci.draw_circle(Vector2(x2, y), 2.0, col)
					x2 += 14
				y += 14
		4:
			_hatch(ci, r, 1, col)
			var y2 := r.position.y + 7
			while y2 < r.end.y:
				ci.draw_line(Vector2(r.position.x, y2), Vector2(r.end.x, y2), col, 1.5)
				y2 += 14


## Koperen speld (ontvangen op de meetlat; de waarde van de bits).
static func pin_(ci: CanvasItem, p: Vector2, s := 1.0, t := 0.0) -> void:
	ci.draw_line(p + Vector2(-70, 0) * s, p + Vector2(70, 0) * s, Color(ScPal.RUBRIC, 0.85), 2.5, true)
	ci.draw_line(p + Vector2(3, 3), p + Vector2(-40, -34) * s + Vector2(3, 3), ScPal.SHADOW, 3.0, true)
	ci.draw_line(p, p + Vector2(-40, -34) * s, ScPal.IRON_LIGHT, 3.0 * s, true)
	ci.draw_circle(p + Vector2(-42, -36) * s, 9 * s, ScPal.RUBRIC)
	ci.draw_circle(p + Vector2(-45, -39) * s, 3 * s, Color(1, 1, 1, 0.5))
	ci.draw_circle(p, 4.0 * s, ScPal.RUBRIC.darkened(0.3))


## Binaire naald (Algoritme 13): liggende getallenlijn [view0, view1), goud = [low, up), naald op `getal`,
## spookstreep op getal + next. `overshoot` = de naald staat boven het goud (trilt). Waarden als floats om te tekenen.
static func needle(ci: CanvasItem, r: Rect2, view0: float, view1: float, low: float, up: float, getal: float, nxt: float,
		t := 0.0, labels := {}, overshoot := false) -> void:
	ScDraw.parchment(ci, r.grow(16), 21, ScPal.VELLUM, true, 0.4)
	var y := r.get_center().y + 10
	var span := maxf(view1 - view0, 1e-12)
	var xof := func(v: float) -> float: return r.position.x + r.size.x * clampf((v - view0) / span, -0.02, 1.02)
	var gx0: float = xof.call(low)
	var gx1: float = xof.call(up)
	ci.draw_rect(Rect2(gx0, y - 16, gx1 - gx0, 32), Color(ScPal.GOLD, 0.55))
	ci.draw_line(Vector2(gx0, y - 22), Vector2(gx0, y + 22), ScPal.GOLD_DARK, 3.0, true)
	var yy := y - 22
	while yy < y + 22:
		ci.draw_line(Vector2(gx1, yy), Vector2(gx1, yy + 5), ScPal.GOLD_DARK, 3.0, true)
		yy += 9
	ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), ScPal.INK, 3.0, true)
	for k in 9:
		var x := r.position.x + r.size.x * k / 8.0
		ci.draw_line(Vector2(x, y - 8), Vector2(x, y + 8), ScPal.INK_SOFT, 2.0, true)
	for v in labels:
		ScPal.text_c(ci, ScPal.MONO_M, Vector2(xof.call(float(v)), y + 34), str(labels[v]), 18, ScPal.INK_SOFT)
	# spookstreep
	var sx: float = xof.call(getal + nxt)
	var d := y - 40
	while d < y + 20:
		ci.draw_line(Vector2(sx, d), Vector2(sx, d + 6), Color(ScPal.LAPIS, 0.8), 3.0, true)
		d += 10
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(sx, y - 54), "+next", 16, ScPal.LAPIS)
	# naald
	var nx: float = xof.call(getal) + (sin(t * 60.0) * 3.0 if overshoot else 0.0)
	ci.draw_line(Vector2(nx + 3, y - 46 + 4), Vector2(nx + 3, y + 4), ScPal.SHADOW, 4.0, true)
	ci.draw_line(Vector2(nx, y - 46), Vector2(nx, y), ScPal.IRON, 4.0, true)
	ScDraw.fill(ci, PackedVector2Array([Vector2(nx - 9, y - 50), Vector2(nx + 9, y - 50), Vector2(nx, y - 36)]), ScPal.IRON_LIGHT)
	ci.draw_circle(Vector2(nx, y - 54), 6, ScPal.BRASS)
	if getal >= low and getal < up:
		ScDraw.glow(ci, Vector2(nx, y), 60, Color(ScPal.GOLD_LIGHT, 0.6))


## Schaar (meetlat knippen). `open` 0..1.
static func scissors(ci: CanvasItem, c: Vector2, s := 1.0, open := 0.4, rot := 0.0) -> void:
	for side: float in [-1.0, 1.0]:
		var a := rot + side * open * 0.35
		var d := Vector2(cos(a), sin(a))
		var n := d.orthogonal() * side
		ScDraw.fill(ci, PackedVector2Array([c, c + d * 58 * s + n * 2 * s, c + d * 8 * s + n * 7 * s]), ScPal.IRON_LIGHT)
		ci.draw_line(c, c + d * 56 * s, Color(1, 1, 1, 0.5), 1.0, true)
		var ring_c := c - d * 26 * s + n * 9 * s
		ci.draw_arc(ring_c, 10 * s, 0, TAU, 16, ScPal.BRASS, 4 * s, true)
		ci.draw_line(c, ring_c, ScPal.BRASS, 4 * s, true)
	ci.draw_circle(c, 3.5 * s, ScPal.BRASS_DARK)


## Rekenboek (meetlat): tabel i · teken · links · lengte op perkament. rows = [[i, sym, links, lengte], ...].
static func ledger_table(ci: CanvasItem, r: Rect2, head: Array, rows: Array, size := 20, hi_row := -1) -> void:
	ScDraw.parchment(ci, r, 31, ScPal.VELLUM, true, 0.5)
	var cols := head.size()
	var cw := (r.size.x - 24) / cols
	var lh := size * 1.6
	for j in cols:
		ScPal.text_l(ci, ScPal.UI_BOLD, Vector2(r.position.x + 12 + j * cw, r.position.y + 22), str(head[j]), size, ScPal.RUBRIC)
	ci.draw_line(Vector2(r.position.x + 10, r.position.y + 40), Vector2(r.end.x - 10, r.position.y + 40), ScPal.RUBRIC, 2.0, true)
	for i in rows.size():
		var y := r.position.y + 40 + lh * (i + 0.5) + 4
		if i == hi_row:
			ci.draw_rect(Rect2(r.position.x + 8, y - lh / 2, r.size.x - 16, lh), Color(ScPal.GOLD_LIGHT, 0.45))
		var row: Array = rows[i]
		for j in mini(cols, row.size()):
			ScPal.text_l(ci, ScPal.MONO_M, Vector2(r.position.x + 12 + j * cw, y), ScPal.show(str(row[j])), size, ScPal.INK)


# ================================================================ leesraam (LZ77)
## Eén regel geschreven tekst met het houten leesraam over de laatste G tekens [ws, ws+G). Posities 0..G−1 boven
## het raam (`show_pos`). `hi_p` = raampositie onder de muis/gekozen bron. Geeft de centra van alle tekens terug.
static func reading_window(ci: CanvasItem, left_mid: Vector2, text: String, ws: int, G: int, cell := 52.0, size := 40,
		hi_p := -1, show_pos := true, t := 0.0, upto := -1) -> PackedVector2Array:
	var centers := PackedVector2Array()
	var n := text.length()
	var shown := n if upto < 0 else upto
	var band := Rect2(left_mid + Vector2(-14, -size * 0.85), Vector2(cell * maxi(n, 1) + 28, size * 1.7))
	ScDraw.parchment(ci, band, 41, ScPal.VELLUM, true, 0.5)
	for i in n:
		var c := left_mid + Vector2(cell * (i + 0.5), 0)
		centers.append(c)
		if i < shown:
			ScPal.text_c(ci, ScPal.MONO, c, ScPal.show(text[i]), size, ScPal.INK)
		else:
			ScPal.text_c(ci, ScPal.MONO, c, ScPal.show(text[i]), size, Color(ScPal.INK_FADED, 0.45))
	var wl := mini(G, maxi(0, shown - ws))
	if wl > 0:
		var fr := Rect2(left_mid + Vector2(cell * ws - 6, -size * 1.0), Vector2(cell * wl + 12, size * 2.0))
		# raam: vier houten latten, glas licht
		ci.draw_rect(fr, Color(ScPal.GOLD_LIGHT, 0.10))
		for side in 4:
			var lr: Rect2
			match side:
				0:
					lr = Rect2(fr.position + Vector2(-10, -12), Vector2(fr.size.x + 20, 12))
				1:
					lr = Rect2(Vector2(fr.position.x - 10, fr.end.y), Vector2(fr.size.x + 20, 12))
				2:
					lr = Rect2(fr.position + Vector2(-10, -12), Vector2(10, fr.size.y + 24))
				_:
					lr = Rect2(Vector2(fr.end.x, fr.position.y - 12), Vector2(10, fr.size.y + 24))
			ci.draw_rect(Rect2(lr.position + Vector2(3, 4), lr.size), ScPal.SHADOW_SOFT)
			ci.draw_rect(lr, ScPal.OAK)
			ci.draw_rect(Rect2(lr.position, Vector2(lr.size.x, 3)), ScPal.OAK_LIGHT)
		for k in [Vector2(fr.position.x - 5, fr.position.y - 6), Vector2(fr.end.x + 5, fr.position.y - 6),
				Vector2(fr.position.x - 5, fr.end.y + 6), Vector2(fr.end.x + 5, fr.end.y + 6)]:
			ci.draw_circle(k, 3.0, ScPal.BRASS)
		if show_pos:
			for p in wl:
				ScPal.text_c(ci, ScPal.MONO_B, Vector2(centers[ws + p].x, fr.position.y - 24), str(p), 18, ScPal.TEXT)
		if hi_p >= 0 and hi_p < wl:
			var hc := centers[ws + hi_p]
			ScPal.ring(ci, Rect2(hc - Vector2(cell * 0.46, size * 0.7), Vector2(cell * 0.92, size * 1.4)), 8, ScPal.INFO, 3)
	return centers


## Rode draad van bron naar doel (match). `prog` 0..1 loopt de draad af; boog boven de tekst.
static func thread(ci: CanvasItem, a: Vector2, b: Vector2, prog := 1.0, t := 0.0, lift := 70.0) -> void:
	var pts := ScDraw.curve(a, a + Vector2(0, -lift), b + Vector2(0, -lift), b, 32)
	var m := int(round((pts.size() - 1) * clampf(prog, 0, 1))) + 1
	if m >= 2:
		var sub := pts.slice(0, m)
		ci.draw_polyline(sub, Color(ScPal.THREAD.darkened(0.4), 0.5), 5.0, true)
		ci.draw_polyline(sub, ScPal.THREAD, 3.0, true)
		var tip: Vector2 = sub[sub.size() - 1]
		ci.draw_circle(tip, 4.5, ScPal.IRON_LIGHT)
	ci.draw_circle(a, 5, ScPal.THREAD)


# ================================================================ stempelkast (LZW)
## Lade: houten front met koperen greep en een etiket (boven: letter/woord, onder: nummer).
## `open` 0..1 schuift ze uit; `empty` = lege lade (speciaal geval: donker + stofje); `fresh` = net gesneden (goud).
static func drawer(ci: CanvasItem, r: Rect2, word: String, num: String, open := 0.0, empty := false, hi := false,
		fresh := false, t := 0.0) -> Rect2:
	var o := r.position + Vector2(0, open * 18.0)
	var rr := Rect2(o, r.size)
	if open > 0:
		ci.draw_rect(Rect2(r.position + Vector2(4, 0), Vector2(r.size.x - 8, open * 18.0 + 6)), ScPal.WALNUT.darkened(0.4))
		if empty:
			for k in 5:
				ci.draw_circle(r.position + Vector2(12 + k * (r.size.x - 24) / 4.0, open * 10.0 + 2), 3, Color(ScPal.STONE_LIGHT, 0.6))
	ScDraw.wood(ci, rr, ScPal.OAK if not fresh else ScPal.OAK_LIGHT, 5, true, 3)
	var label := Rect2(rr.position + Vector2(8, 6), Vector2(rr.size.x - 16, rr.size.y * 0.52))
	ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 4), label)
	var fs := ScPal.fit_word(word.length(), label.size.x - 10, 24, 14)
	ScPal.text_c(ci, ScPal.MONO, label.get_center(), ScPal.show_text(word), fs, ScPal.INK if not empty else ScPal.INK_FADED)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(rr.get_center().x, rr.end.y - rr.size.y * 0.2), num, 18, ScPal.VELLUM_HI)
	ci.draw_arc(Vector2(rr.end.x - 14, rr.end.y - rr.size.y * 0.2), 6, 0, PI, 8, ScPal.BRASS, 3.0, true)
	if fresh:
		ScPal.ring(ci, rr.grow(3), 7, Color(ScPal.GOLD, 0.7 + 0.3 * sin(t * 6.0)), 3)
	if hi:
		ScPal.ring(ci, rr.grow(4), 8, ScPal.INFO, 3)
	return rr


## De stempelkast: bovenaan de basisladen van het level (letter + ASCII), daaronder de nieuwe laden 256, 257, ...
## base = [[ch, code], ...]; news = [[code, word, dup], ...]; `open_code` gaat open; `empty_code` = de lege lade.
## Geeft code -> Rect2 terug.
static func cabinet(ci: CanvasItem, r: Rect2, base: Array, news: Array, open_code := -1, empty_code := -1, fresh_code := -1,
		t := 0.0, cols := 5) -> Dictionary:
	var zones := {}
	ScDraw.wood(ci, r, ScPal.WALNUT, 12, true, 6)
	ci.draw_rect(Rect2(r.position + Vector2(10, 10), Vector2(r.size.x - 20, 30)), ScPal.OAK_DARK)
	ScPal.text_c(ci, ScPal.TITLE, r.position + Vector2(r.size.x / 2, 26), "Stempelkast", 26, ScPal.GILT_LIGHT)
	var dw := (r.size.x - 20 - (cols - 1) * 8) / cols
	var dh := 74.0
	var y := r.position.y + 52
	for i in base.size():
		var it: Array = base[i]
		var dr := Rect2(r.position.x + 10 + (i % cols) * (dw + 8), y + (i / cols) * (dh + 8), dw, dh)
		zones[int(it[1])] = drawer(ci, dr, ScPal.show(str(it[0])), str(it[1]), 1.0 if int(it[1]) == open_code else 0.0, false,
			false, false, t)
	y += ceili(base.size() / float(cols)) * (dh + 8) + 8
	ci.draw_line(Vector2(r.position.x + 14, y - 6), Vector2(r.end.x - 14, y - 6), ScPal.GILT_DARK, 2.0, true)
	for i in news.size():
		var it2: Array = news[i]
		var code := int(it2[0])
		var dr2 := Rect2(r.position.x + 10 + (i % cols) * (dw + 8), y + (i / cols) * (dh + 8), dw, dh)
		var dup: bool = it2.size() > 2 and bool(it2[2])
		var word: String = "" if code == empty_code else str(it2[1])
		zones[code] = drawer(ci, dr2, word, str(code) + (" ²" if dup else ""), 1.0 if (code == open_code or code == empty_code) else 0.0,
			code == empty_code, false, code == fresh_code, t)
	return zones


## Zetstok: koperen houder met het huidige woord w als loden lettertjes, en het volgende teken k ernaast.
## `in_case` = wk zit al in de kast (k gloeit goud), anders lapis.
static func zetstok(ci: CanvasItem, left_mid: Vector2, w: String, k: String, in_case := true, size := 36, t := 0.0) -> void:
	var cw := size * 1.05
	var r := Rect2(left_mid + Vector2(0, -size * 0.8), Vector2(cw * w.length() + 28, size * 1.6))
	ci.draw_rect(Rect2(r.position + Vector2(4, 6), r.size), ScPal.SHADOW)
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 10), Vector2(r.size.x, 10)), ScPal.BRASS_DARK)
	ci.draw_rect(Rect2(r.position, Vector2(10, r.size.y)), ScPal.BRASS)
	ci.draw_rect(Rect2(Vector2(r.end.x - 10, r.position.y + 8), Vector2(10, r.size.y - 8)), ScPal.BRASS)
	for i in w.length():
		var c := r.position + Vector2(14 + cw * (i + 0.5), r.size.y * 0.45)
		var b := Rect2(c - Vector2(cw * 0.46, size * 0.6), Vector2(cw * 0.92, size * 1.2))
		ci.draw_style_box(ScPal.sb(ScPal.IRON_LIGHT, 3), b)
		ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 3), b.grow(-3))
		ScPal.text_c(ci, ScPal.MONO, c, ScPal.show(w[i]), size, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(r.get_center().x, r.end.y + 16), "w", 18, ScPal.TEXT_DIM)
	if k != "":
		var kc := Vector2(r.end.x + cw * 0.85, r.get_center().y - 4 + sin(t * 3.0) * 3.0)
		var col := ScPal.GOLD if in_case else ScPal.INFO
		ScDraw.glow(ci, kc, size * 1.6, Color(col, 0.5))
		var kb := Rect2(kc - Vector2(cw * 0.46, size * 0.6), Vector2(cw * 0.92, size * 1.2))
		ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 3), kb)
		ScPal.ring(ci, kb.grow(2), 5, col, 3)
		ScPal.text_c(ci, ScPal.MONO, kc, ScPal.show(k), size, ScPal.INK)
		ScPal.text_c(ci, ScPal.UI_MED, Vector2(kc.x, r.end.y + 16), "k", 18, ScPal.TEXT_DIM)


## Hendel (Verleng / Stempel): houten arm met knop, koperen plaatje met label en sneltoets. `pulled` 0..1.
static func lever(ci: CanvasItem, base: Vector2, label: String, key: String, pulled := 0.0, hi := false, col := ScPal.RUBRIC, t := 0.0) -> Rect2:
	var a := lerpf(-1.25, -0.55, pulled)
	var tip := base + Vector2(cos(a), sin(a)) * 92
	ci.draw_rect(Rect2(base + Vector2(-36, -6), Vector2(72, 26)), ScPal.IRON)
	ci.draw_line(base + Vector2(3, 4), tip + Vector2(3, 4), ScPal.SHADOW, 10, true)
	ci.draw_line(base, tip, ScPal.OAK_DARK, 10, true)
	ci.draw_line(base + Vector2(-2, -2), tip + Vector2(-2, -2), ScPal.OAK, 4, true)
	ci.draw_circle(tip, 16, col.darkened(0.25))
	ci.draw_circle(tip + Vector2(-2, -2), 13, col)
	ci.draw_circle(tip + Vector2(-6, -6), 4, Color(1, 1, 1, 0.45))
	ci.draw_circle(base, 8, ScPal.BRASS)
	var plate := Rect2(base + Vector2(-70, 28), Vector2(140, 40))
	ci.draw_style_box(ScPal.sb(ScPal.BRASS, 6, 6, Vector2(0, 4)), plate)
	ci.draw_style_box(ScPal.sb(ScPal.BRASS_DARK, 4), Rect2(plate.position + Vector2(plate.size.x - 34, 7), Vector2(26, 26)))
	ScPal.text_c(ci, ScPal.MONO_B, plate.position + Vector2(plate.size.x - 21, 20), key, 18, ScPal.VELLUM_HI)
	ScPal.text_c(ci, ScPal.UI_BOLD, plate.position + Vector2((plate.size.x - 34) / 2, 20), label, 22, ScPal.WALNUT)
	if hi:
		ScPal.ring(ci, plate.grow(4), 8, Color(ScPal.INFO, 0.8 + 0.2 * sin(t * 6.0)), 3)
	return Rect2(plate.position.x, tip.y - 20, plate.size.x, plate.end.y - tip.y + 20)


# ================================================================ draaitrommel + rek (Burrows-Wheeler)
## Houten trommel (vooraanzicht) met de tekst rondom: de rij in het midden is vol, erboven/eronder krimpen de
## letters (perspectief). `spin` (in letters) draait de trommel; bij een geheel getal staat rotatie `spin` vooraan.
static func drum(ci: CanvasItem, c: Vector2, rw := 120.0, rh := 200.0, text := "", spin := 0.0, t := 0.0, size := 34) -> void:
	var n := text.length()
	# as + slinger
	ci.draw_line(c + Vector2(-rw - 40, 0), c + Vector2(rw + 40, 0), ScPal.IRON, 10, true)
	ci.draw_rect(Rect2(c + Vector2(-rw - 56, -12), Vector2(16, 24)), ScPal.OAK_DARK)
	var crank_a := spin * TAU / maxf(n, 1)
	var ce := c + Vector2(rw + 46, 0) + Vector2(cos(crank_a), sin(crank_a)) * 26
	ci.draw_line(c + Vector2(rw + 46, 0), ce, ScPal.IRON, 6, true)
	ci.draw_circle(ce, 9, ScPal.OAK)
	# lichaam
	var body := Rect2(c - Vector2(rw, rh / 2), Vector2(rw * 2, rh))
	ci.draw_rect(Rect2(body.position + Vector2(6, 8), body.size), ScPal.SHADOW)
	ScDraw.tex_poly(ci, ScDraw.rrect_pts(body, 18), ScPal.tex("art/tex/wood.png"), ScPal.OAK, 1.0)
	# schaduw van de ronding (boven/onder donkerder)
	for k in 8:
		var f := float(k) / 8.0
		var a := 0.42 * (1.0 - f) ** 2
		ci.draw_rect(Rect2(body.position.x, body.position.y + f * rh * 0.22, body.size.x, rh * 0.03), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(body.position.x, body.end.y - (f + 1.0 / 8.0) * rh * 0.22, body.size.x, rh * 0.03), Color(0, 0, 0, a))
	ci.draw_rect(Rect2(body.position.x, c.y - rh * 0.18, body.size.x, rh * 0.1), Color(1, 1, 1, 0.07))
	# perkamentband met letters rond de trommel
	if n > 0:
		var band := Rect2(c.x - rw * 0.62, body.position.y, rw * 1.24, rh)
		ci.draw_rect(band, Color(ScPal.VELLUM, 0.92))
		var fr: float = spin - floorf(spin)
		for k in range(-3, 4):
			var ang := (k - fr) * 0.42
			if absf(ang) > 1.35:
				continue
			var y := c.y + sin(ang) * rh * 0.48
			var sc := cos(ang)
			var idx := posmod(int(floorf(spin)) + k, n)
			var fs := int(maxf(10, size * sc))
			ScPal.text_c(ci, ScPal.MONO, Vector2(c.x, y), ScPal.show(text[idx]), fs, Color(ScPal.INK, clampf(sc * 1.3 - 0.2, 0, 1)))
		ScPal.ring(ci, Rect2(band.position.x - 2, c.y - size * 0.75, band.size.x + 4, size * 1.5), 6, ScPal.GOLD, 3)
	# ijzeren banden
	for x in [body.position.x + 14, body.end.x - 22]:
		ci.draw_rect(Rect2(x, body.position.y, 8, rh), ScPal.IRON)
		ci.draw_rect(Rect2(x, body.position.y, 2, rh), ScPal.IRON_LIGHT)


## Rek met stroken (gesorteerde rotaties). rows = Array[String]; eerste kolom lapis-getint, laatste kolom goud
## (de uitvoer). `marked` = gemarkeerde rij p (lakzegel), `gap` = open spleet (invoegen), `pending` = zwevende strook.
## Geeft de rij-rechthoeken terug.
static func rack(ci: CanvasItem, pos: Vector2, rows: Array, size := 32, marked := -1, gap := -1, pending := "",
		pending_at := Vector2.INF, t := 0.0, row_nums := true, hi_row := -1) -> Array:
	var cw := ScPal.char_w(size) + 6.0
	var n := 0
	for r in rows:
		n = maxi(n, str(r).length())
	n = maxi(n, pending.length())
	var rh := size * 1.45
	var w := cw * n + 24
	var rects := []
	var frame := Rect2(pos + Vector2(-18, -14), Vector2(w + 36 + (40 if row_nums else 0), rh * (rows.size() + (1 if gap >= 0 else 0)) + 28))
	ScDraw.wood(ci, frame, ScPal.WALNUT, 10)
	var y := pos.y
	var x0 := pos.x + (40 if row_nums else 0)
	for i in rows.size():
		if i == gap:
			var gr := Rect2(x0, y + 4, w, rh - 8)
			ci.draw_rect(gr, Color(ScPal.INFO, 0.18 + 0.1 * sin(t * 6.0)))
			ScPal.ring(ci, gr, 6, ScPal.INFO, 2)
			y += rh
		var r := Rect2(x0, y + 3, w, rh - 6)
		rects.append(r)
		var s: String = rows[i]
		_strip(ci, r, s, size, cw, i == hi_row)
		if row_nums:
			ScPal.text_r(ci, ScPal.MONO_B, Vector2(x0 - 12, r.get_center().y), str(i), 20, ScPal.TEXT_DIM)
		if i == marked:
			ScPal.ring(ci, r.grow(4), 8, ScPal.GOLD, 3)
			ScDraw.seal(ci, Vector2(r.end.x + 22, r.get_center().y), 17, "p", ScPal.MONO_B, 18, ScPal.WAX, i)
		y += rh
	if gap >= rows.size():
		var gr2 := Rect2(x0, y + 4, w, rh - 8)
		ci.draw_rect(gr2, Color(ScPal.INFO, 0.18))
		ScPal.ring(ci, gr2, 6, ScPal.INFO, 2)
	if pending != "":
		var pc := pending_at if pending_at != Vector2.INF else Vector2(x0 + w + 80, pos.y)
		var pr := Rect2(pc - Vector2(0, rh / 2), Vector2(w, rh - 6))
		ci.draw_rect(Rect2(pr.position + Vector2(8, 12), pr.size), ScPal.SHADOW)
		_strip(ci, pr, pending, size, cw, true)
	return rects


static func _strip(ci: CanvasItem, r: Rect2, s: String, size: int, cw: float, hi := false) -> void:
	ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI if hi else ScPal.VELLUM, 5, 3, ScPal.VELLUM_EDGE), r)
	var n := s.length()
	if n == 0:
		return
	ci.draw_rect(Rect2(r.position + Vector2(12 - 3, 3), Vector2(cw, r.size.y - 9)), Color(ScPal.LAPIS_LIGHT, 0.35))
	ci.draw_rect(Rect2(r.position + Vector2(12 - 3 + cw * (n - 1), 3), Vector2(cw, r.size.y - 9)), Color(ScPal.GOLD, 0.45))
	for i in n:
		ScPal.text_c(ci, ScPal.MONO, Vector2(r.position.x + 12 + cw * (i + 0.5) - 3, r.get_center().y - 1), ScPal.show(s[i]), size, ScPal.INK)


# ================================================================ letterplank (move-to-front)
## Plank met houten blokjes (letters op perkament). `show_pos` = positienummers eronder (tutorial / hulplijnen).
## `hi` = het blokje dat vooraan schuift. Geeft de klikzones terug.
static func shelf(ci: CanvasItem, left_mid: Vector2, items: Array, block := 60.0, show_pos := true, hi := -1, t := 0.0) -> Array:
	var zones := []
	var gap := 8.0
	var w := items.size() * (block + gap) + 30
	var plank := Rect2(left_mid + Vector2(-16, block * 0.55), Vector2(w, 22))
	ScDraw.wood(ci, plank, ScPal.OAK_DARK, 6, true, 5)
	for k in [plank.position.x + 30, plank.end.x - 46]:
		ci.draw_rect(Rect2(k, plank.end.y, 16, 30), ScPal.WALNUT)
	for i in items.size():
		var c := left_mid + Vector2(i * (block + gap) + block / 2, 0)
		var up := -10.0 if i == hi else 0.0
		var r := Rect2(c - Vector2(block / 2, block / 2 - up), Vector2(block, block))
		r.position.y += up
		zones.append(r)
		ScDraw.wood(ci, r, ScPal.OAK, 7, true, 5)
		var face := r.grow(-7)
		face.size.y -= 3
		ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 4), face)
		ScPal.text_c(ci, ScPal.MONO, face.get_center(), ScPal.show(str(items[i])), int(block * 0.55), ScPal.INK)
		if i == hi:
			ScPal.ring(ci, r.grow(4), 9, ScPal.GOLD, 3)
		if show_pos:
			ScPal.text_c(ci, ScPal.MONO_B, Vector2(c.x, plank.end.y + 18), str(i), 18, ScPal.TEXT)
	return zones


## Cijferstempel (letterplank zenden): houten stempeltje met koperen voet en het cijfer.
static func digit_stamp(ci: CanvasItem, c: Vector2, d: int, s := 1.0, hi := false, pressed := 0.0) -> Rect2:
	var o := c + Vector2(0, pressed * 8 * s)
	ScDraw.ellipse(ci, c + Vector2(3, 30) * s, 22 * s, 6 * s, ScPal.SHADOW_SOFT)
	ci.draw_rect(Rect2(o + Vector2(-20, 12) * s, Vector2(40, 14) * s), ScPal.BRASS)
	ScDraw.wood(ci, Rect2(o + Vector2(-14, -30) * s, Vector2(28, 44) * s), ScPal.OAK, 10 * s, false, 0)
	ci.draw_circle(o + Vector2(0, -32) * s, 12 * s, ScPal.OAK_LIGHT)
	var plate := Rect2(o + Vector2(-18, -10) * s, Vector2(36, 30) * s)
	ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, int(4 * s)), plate)
	ScPal.text_c(ci, ScPal.MONO_B, plate.get_center(), str(d), int(24 * s), ScPal.INK)
	if hi:
		ScPal.ring(ci, plate.grow(4), 6, ScPal.INFO, 3)
	return Rect2(o + Vector2(-22, -44) * s, Vector2(44, 72) * s)


# ================================================================ duiventil
## Duiventoren met zeven korte hokken (ε, 0, 1, 00, 01, 10, 11) en een zolder met 16 lange hokken (4 bits).
## filled = {label: true}. Geeft label -> Rect2 terug.
static func dovecote(ci: CanvasItem, c: Vector2, s := 1.0, filled := {}, t := 0.0) -> Dictionary:
	var zones := {}
	var w := 420.0 * s
	var body := Rect2(c + Vector2(-w / 2, -300 * s), Vector2(w, 360 * s))
	ScDraw.wood(ci, body, Color("#B89270"), 8, true, 6)
	# dak
	ScDraw.fill(ci, PackedVector2Array([body.position + Vector2(-30, 0) * s, Vector2(c.x, body.position.y - 130 * s),
		Vector2(body.end.x + 30 * s, body.position.y)]), ScPal.RUBRIC.darkened(0.35))
	for k in 6:
		var y := body.position.y - k * 20 * s
		var hw := (w / 2 + 30 * s) * (1.0 - k * 20.0 / 130.0)
		ci.draw_line(Vector2(c.x - hw, y), Vector2(c.x + hw, y), ScPal.RUBRIC.darkened(0.5), 2.0, true)
	var rows := [["ε"], ["0", "1"], ["00", "01", "10", "11"]]
	var y0 := body.position.y + 40 * s
	for ri in rows.size():
		var row: Array = rows[ri]
		for j in row.size():
			var cx := c.x + (j - (row.size() - 1) / 2.0) * 92 * s
			var hc := Vector2(cx, y0 + ri * 78 * s)
			var hr := Rect2(hc - Vector2(32, 26) * s, Vector2(64, 52) * s)
			zones[row[j]] = hr
			ScDraw.fill(ci, ScDraw.rrect_pts(hr, 26 * s), ScPal.WALNUT.darkened(0.3))
			ci.draw_rect(Rect2(hr.position.x - 6 * s, hr.end.y - 4 * s, hr.size.x + 12 * s, 8 * s), ScPal.OAK_DARK)
			if filled.get(row[j], false):
				ScDraw.dove(ci, hc + Vector2(0, 2) * s, 0.55 * s, t + j, 0, 1.0, 0, false)
			var lab := Rect2(hc + Vector2(-22, 30) * s, Vector2(44, 20) * s)
			ci.draw_style_box(ScPal.sb(ScPal.VELLUM_HI, 3), lab)
			ScPal.text_c(ci, ScPal.MONO_B, lab.get_center(), row[j], int(15 * s), ScPal.INK)
	# zolder: 16 lange hokken (4 bits)
	var zy := body.end.y - 40 * s
	ci.draw_rect(Rect2(body.position.x + 10 * s, zy - 26 * s, w - 20 * s, 56 * s), ScPal.OAK_DARK)
	for k in 16:
		var hc2 := Vector2(body.position.x + 26 * s + k * (w - 52 * s) / 15.0, zy)
		ScDraw.ellipse(ci, hc2, 9 * s, 13 * s, ScPal.WALNUT.darkened(0.4))
		var lbl := ""
		for b in 4:
			lbl += "1" if (k >> (3 - b)) & 1 else "0"
		zones[lbl] = Rect2(hc2 - Vector2(11, 15) * s, Vector2(22, 30) * s)
		if filled.get(lbl, false):
			ScDraw.dove(ci, hc2, 0.3 * s, t, 0, 1.0, 1, false)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(c.x, zy + 42 * s), "zolder: 4 bits", int(16 * s), ScPal.TEXT_DIM)
	return zones


# ================================================================ getijdenboek, brief, kist, kasboek
## Opengeslagen getijdenboek (kaart): leren kaft, twee perkamentbladzijden met rode rubrieken en een leeslint.
static func book_spread(ci: CanvasItem, r: Rect2, ribbon_col := ScPal.FOLIUM, t := 0.0) -> Array:
	var cover := r.grow(22)
	ScDraw.leather(ci, cover, 26, ScPal.PANEL, true, true)
	var mid := r.get_center().x
	var left := Rect2(r.position, Vector2(r.size.x / 2 - 6, r.size.y))
	var right := Rect2(Vector2(mid + 6, r.position.y), Vector2(r.size.x / 2 - 6, r.size.y))
	for pg in [left, right]:
		ScDraw.parchment(ci, pg, int(pg.position.x), ScPal.VELLUM, false, 0.9, 1.5)
		ScPal.ring(ci, pg.grow(-26), 2, Color(ScPal.RUBRIC, 0.55), 2)
	# rug: schaduw in de vouw
	for k in 10:
		ci.draw_rect(Rect2(mid - 6 - k * 3, r.position.y, 3, r.size.y), Color(0, 0, 0, 0.16 * (1.0 - k / 10.0)))
		ci.draw_rect(Rect2(mid + 6 + k * 3, r.position.y, 3, r.size.y), Color(0, 0, 0, 0.16 * (1.0 - k / 10.0)))
	# leeslint
	var sway := sin(t * 1.3) * 4.0
	var rb := PackedVector2Array([Vector2(mid - 8, r.position.y - 20), Vector2(mid + 8, r.position.y - 20),
		Vector2(mid + 10 + sway, r.end.y + 50), Vector2(mid + 1 + sway, r.end.y + 40), Vector2(mid - 6 + sway, r.end.y + 50)])
	ScDraw.fill(ci, rb, ribbon_col)
	ci.draw_line(Vector2(mid - 2, r.position.y - 20), Vector2(mid - 1 + sway, r.end.y + 40), Color(1, 1, 1, 0.2), 2.0, true)
	return [left, right]


## Verluchte initiaal (levelknop op de kaart): goud/lapisveld met de hoofdletter in fraktuur, rankwerk,
## werktuigpictogram, 0–3 lakzegels eronder en een slotje als hij dicht is. Geeft de klikzone terug.
static func initial(ci: CanvasItem, r: Rect2, letter: String, chapter_i := 0, stars := 0, locked := false, hi := false,
		t := 0.0, tool := "", label := "") -> Rect2:
	var ch := ScPal.chapter(chapter_i)
	var field: Color = ch["field"]
	if locked:
		field = field.lerp(ScPal.STONE_LIGHT, 0.75)
	if hi:
		ScDraw.glow(ci, r.get_center(), r.size.x * 1.2, Color(ScPal.GOLD_LIGHT, 0.55))
	ci.draw_style_box(ScPal.sb(ScPal.SHADOW, 6), Rect2(r.position + Vector2(4, 6), r.size))
	ci.draw_style_box(ScPal.sb(ScPal.GOLD_DARK if not locked else ScPal.STONE, 6), r)
	ci.draw_style_box(ScPal.sb(ScPal.GOLD if not locked else ScPal.STONE_LIGHT, 5), r.grow(-3))
	var inner := r.grow(-9)
	ci.draw_style_box(ScPal.sb(field, 3), inner)
	# rankwerk in de hoeken (wit), stippen goud
	var vine := Color(1, 1, 1, 0.35 if not locked else 0.15)
	for k in 4:
		var cx: float = inner.position.x + (inner.size.x if k % 2 else 0.0)
		var cy: float = inner.position.y + (inner.size.y if k / 2 else 0.0)
		var sx := -1.0 if k % 2 else 1.0
		var sy := -1.0 if k / 2 else 1.0
		ci.draw_arc(Vector2(cx + sx * 12, cy + sy * 12), 9, 0, TAU, 12, vine, 2.0, true)
		ci.draw_circle(Vector2(cx + sx * 5, cy + sy * 5), 2.5, ScPal.GOLD_LIGHT if not locked else ScPal.STONE_LIGHT)
	var fs := int(r.size.y * 0.66)
	ScPal.text_c(ci, ScPal.INITIAL, inner.get_center() + Vector2(2, 3), letter, fs, Color(0, 0, 0, 0.35))
	ScPal.text_c(ci, ScPal.INITIAL, inner.get_center(), letter, fs, ScPal.GOLD_LIGHT if not locked else ScPal.VELLUM)
	if tool != "":
		var tc := Vector2(r.end.x - 4, r.position.y + 4)
		ci.draw_circle(tc, 15, ScPal.VELLUM_HI)
		ci.draw_arc(tc, 15, 0, TAU, 16, ScPal.GOLD_DARK, 2.0, true)
		ScDraw.tool_icon(ci, tc, 9, tool, ScPal.INK, t)
	if label != "":
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(r.get_center().x, r.end.y + 16), label, 18, ScPal.INK)
	var sy2 := r.end.y + (40.0 if label != "" else 22.0)
	for k in 3:
		ScDraw.star_seal(ci, Vector2(r.get_center().x + (k - 1) * 30, sy2), 12, k < stars, 1.0, k + chapter_i * 3)
	if locked:
		var lc := r.get_center() + Vector2(0, r.size.y * 0.3)
		ci.draw_arc(lc + Vector2(0, -12), 9, PI, TAU, 10, ScPal.IRON, 4.0, true)
		ci.draw_style_box(ScPal.sb(ScPal.IRON, 3), Rect2(lc + Vector2(-13, -12), Vector2(26, 20)))
		ci.draw_circle(lc + Vector2(0, -3), 3, ScPal.SLOT)
	return r


## Gezegelde brief (opdracht van een huis). `open` 0..1 vouwt open; `seal_col` = was van het huis.
static func letter(ci: CanvasItem, c: Vector2, s := 1.0, open := 0.0, seal_col := ScPal.WAX, mono := "") -> Rect2:
	var w := 300.0 * s
	var h := 200.0 * s
	var r := Rect2(c - Vector2(w, h) / 2, Vector2(w, h))
	ScDraw.parchment(ci, r, 61, ScPal.VELLUM, true, 0.7)
	var flap_tip := Vector2(c.x, lerpf(c.y + 10 * s, r.position.y - h * 0.45, open))
	ScDraw.fill(ci, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), flap_tip]), ScPal.VELLUM_EDGE)
	ci.draw_line(r.position, flap_tip, Color(ScPal.VELLUM_AGED, 0.8), 2.0, true)
	ci.draw_line(Vector2(r.end.x, r.position.y), flap_tip, Color(ScPal.VELLUM_AGED, 0.8), 2.0, true)
	ci.draw_line(Vector2(r.position.x, r.end.y), c + Vector2(0, 30 * s), Color(ScPal.VELLUM_AGED, 0.5), 1.5, true)
	ci.draw_line(r.end, c + Vector2(0, 30 * s), Color(ScPal.VELLUM_AGED, 0.5), 1.5, true)
	if open < 0.5:
		ScDraw.seal(ci, Vector2(c.x, c.y + 10 * s), 26 * s, "Z", ScPal.TITLE, int(28 * s), seal_col, 4)
	elif mono != "":
		ScPal.text_c(ci, ScPal.MONO, c + Vector2(0, 40 * s), mono, int(26 * s), ScPal.INK)
	return r


## Houten kist (nieuw werktuig). `open` 0..1 tilt het deksel; stro piept eruit.
static func crate(ci: CanvasItem, c: Vector2, s := 1.0, open := 0.0, t := 0.0) -> void:
	var w := 220.0 * s
	var h := 130.0 * s
	var r := Rect2(c - Vector2(w / 2, h), Vector2(w, h))
	ScDraw.ellipse(ci, c + Vector2(8, 4) * s, w * 0.56, 12 * s, ScPal.SHADOW)
	if open > 0.05:
		for k in 9:
			var x := r.position.x + 16 * s + k * (w - 32 * s) / 8.0
			ci.draw_line(Vector2(x, r.position.y + 6), Vector2(x + (ScDraw._hash(k) - 0.5) * 30 * s, r.position.y - 22 * s * open), Color("#E2C26A"), 3.0 * s, true)
		ScDraw.glow(ci, Vector2(c.x, r.position.y), 120 * s * open, Color(ScPal.GOLD_LIGHT, 0.5 * open))
	ScDraw.wood(ci, r, ScPal.OAK, 6, false, 0)
	for k in 3:
		ci.draw_line(Vector2(r.position.x, r.position.y + (k + 1) * h / 3.5), Vector2(r.end.x, r.position.y + (k + 1) * h / 3.5), ScPal.OAK_DARK, 2.0, true)
	ci.draw_line(r.position, r.end, ScPal.OAK_DARK, 8 * s, true)
	ci.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), ScPal.OAK_DARK, 8 * s, true)
	for corner in [r.position, Vector2(r.end.x - 14 * s, r.position.y), Vector2(r.position.x, r.end.y - 14 * s), r.end - Vector2(14, 14) * s]:
		ci.draw_rect(Rect2(corner, Vector2(14, 14) * s), ScPal.IRON)
	# deksel
	var lid_a := -open * 1.1
	var hinge := Vector2(r.end.x, r.position.y)
	var lid := PackedVector2Array([Vector2(-w, -18 * s), Vector2(0, -18 * s), Vector2(0, 0), Vector2(-w, 0)])
	var lp := ScDraw.xf(lid, hinge, 1.0, 1.0, lid_a)
	ScDraw.fill(ci, lp, ScPal.OAK_LIGHT)
	ScDraw.outline(ci, lp, ScPal.OAK_DARK, 2.0)


## Kelners kasboek (terugblik): staven voor jouw inkt, optimum, gewoon schrift (en vaste lengte / Huffman).
## rows = [{"label", "value", "col"}]. Geeft niets terug.
static func ledger_bars(ci: CanvasItem, r: Rect2, rows: Array, unit := "bits") -> void:
	ScDraw.parchment(ci, r, 71, ScPal.VELLUM, true, 0.6)
	ScPal.text_l(ci, ScPal.TITLE, r.position + Vector2(22, 30), "Kelners kasboek", 30, ScPal.RUBRIC)
	var mx := 1.0
	for row in rows:
		mx = maxf(mx, float(row["value"]))
	var y := r.position.y + 76
	var bx := r.position.x + 200
	var bw := r.size.x - 290
	for row in rows:
		ScPal.text_r(ci, ScPal.UI_BOLD, Vector2(bx - 14, y), str(row["label"]), 20, ScPal.INK)
		var L := bw * float(row["value"]) / mx
		var col: Color = row.get("col", ScPal.INK_SOFT)
		ci.draw_style_box(ScPal.sb(Color(col, 0.85), 6), Rect2(bx, y - 13, maxf(L, 12), 26))
		# inktstreepjes in de staaf (handgeschreven gevoel)
		for k in int(L / 18):
			ci.draw_line(Vector2(bx + 9 + k * 18, y - 8), Vector2(bx + 15 + k * 18, y + 8), Color(1, 1, 1, 0.18), 2.0, true)
		ScPal.text_l(ci, ScPal.MONO_B, Vector2(bx + L + 12, y), "%d %s" % [int(row["value"]), unit], 20, ScPal.INK)
		y += 44
