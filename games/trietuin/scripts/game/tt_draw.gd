class_name TtDraw
extends Object
## Trietuin: alle spelelementen, in code getekend (design/ART.md §5). Statisch; elke functie krijgt het CanvasItem
## waarop getekend wordt (`ci`, meestal in een `draw`-callback) en het seizoen (`se` = TtPal.season(i)).
## Licht valt van linksboven; schaduwen naar rechtsonder. Letters altijd INK op papier/chip (TtPal.word).

const LIGHT_DIR := Vector2(-0.6, -0.8)


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


## Gevulde polygoon met zachte (anti-aliased) rand.
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


## Transformeer lokale punten (figuur kijkt naar rechts) naar wereld: schaal s, spiegel `facing` (-1 = links), draai rot.
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


## Natuurlijke takcurve van p0 naar p1: vertrekt in groeirichting `grow` (omhoog voor een boom die omhoog groeit),
## buigt dan naar het doel. `bend` (-0.3..0.3) geeft extra zijdelingse kromming.
## `arch`: de tak buigt over en komt zijdelings/van boven in p1 aan (tak naar een vrucht: de vrucht + het label
## hangen dan vrij onder de top, niet over de eigen tak).
static func branch_curve(p0: Vector2, p1: Vector2, grow := Vector2.UP, bend := 0.0, n := 24, arch := false) -> PackedVector2Array:
	var d := p1 - p0
	var L := d.length()
	var side := Vector2(-d.y, d.x).normalized() * bend * L
	var c0 := p0 + grow * L * 0.42
	var c1 := p1 - d.normalized() * L * 0.22 + side
	if arch:
		var sx := 1.0 if d.x >= 0.0 else -1.0
		c0 = p0 + grow * L * 0.55
		c1 = p1 + Vector2(-sx * L * 0.42, grow.y * L * 0.22)
	var out := PackedVector2Array()
	for k in n:
		out.append(bezier(p0, c0, c1, p1, float(k) / (n - 1)))
	return out


static func path_length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	return total


## Punt op fractie f (0..1, booglengte) van een polyline (bv. om een bij langs een tak te laten vliegen).
static func path_point(pts: PackedVector2Array, f: float) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	var target := clampf(f, 0.0, 1.0) * path_length(pts)
	for i in range(1, pts.size()):
		var l := pts[i - 1].distance_to(pts[i])
		if target <= l:
			return pts[i - 1].lerp(pts[i], target / maxf(l, 0.001))
		target -= l
	return pts[pts.size() - 1]


static func path_tangent(pts: PackedVector2Array, f: float) -> Vector2:
	var a := path_point(pts, maxf(0.0, f - 0.02))
	var b := path_point(pts, minf(1.0, f + 0.02))
	return (b - a).normalized()


static func _hash(i: int) -> float:
	var x := sin(float(i) * 127.1 + 311.7) * 43758.5453
	return x - floor(x)


# ================================================================ blad
## Blad met steel in `base`, wijzend in hoek `ang`. Lichte bovenhelft, nerf in donkere tint.
static func leaf(ci: CanvasItem, base: Vector2, ang: float, size: float, col: Color, vein := true) -> void:
	var up := PackedVector2Array()
	var lo := PackedVector2Array()
	for k in 11:
		var t := k / 10.0
		var x := t * size
		var y := pow(sin(t * PI), 0.85) * size * 0.27
		up.append(Vector2(x, -y))
		lo.append(Vector2(x, y * 0.92))
	var poly := PackedVector2Array()
	for p in up:
		poly.append(p)
	for k in range(lo.size() - 2, 0, -1):
		poly.append(lo[k])
	var w := xf(poly, base, 1.0, 1.0, ang)
	fill(ci, w, col)
	var half := PackedVector2Array()
	for p in up:
		half.append(p)
	half.append(Vector2(size, 0))
	fill(ci, xf(half, base, 1.0, 1.0, ang), col.lightened(0.14), false)
	if vein:
		ci.draw_line(xp(Vector2(size * 0.06, 0), base, 1.0, 1.0, ang), xp(Vector2(size * 0.82, 0), base, 1.0, 1.0, ang), col.darkened(0.28), maxf(1.2, size * 0.06), true)


# ================================================================ tak
## Taps toelopende tak langs `pts` (bv. uit branch_curve). w0 = breedte aan de start, w1 aan de top.
## `leaves`: aantal blaadjes (0..3). `glow`: kleur van een zachte gloed eronder (selectie/bijenpad), alpha 0 = uit.
## `wither` 0..1: verdord (foute/doodlopende tak).
static func branch(ci: CanvasItem, pts: PackedVector2Array, w0: float, w1: float, se: Dictionary, seed_ := 0, t := 0.0,
		leaves := 2, glow := Color(0, 0, 0, 0), wither := 0.0) -> void:
	var n := pts.size()
	if n < 2:
		return
	var bark := TtPal.BARK.lerp(Color("#8A8378"), wither * 0.6)
	var bark_d := TtPal.BARK_DARK.lerp(Color("#5E5850"), wither * 0.6)
	var bark_l := TtPal.BARK_LIGHT.lerp(Color("#B0A99C"), wither * 0.6)
	var overall := (pts[n - 1] - pts[0]).normalized()
	var nr0 := Vector2(-overall.y, overall.x)
	var flip := 1.0 if nr0.dot(LIGHT_DIR) >= 0.0 else -1.0
	var lit := PackedVector2Array()
	var dark := PackedVector2Array()
	var mid_dark := PackedVector2Array()
	var hl := PackedVector2Array()
	var snow := PackedVector2Array()
	var nrs: Array[Vector2] = []
	var ws: Array[float] = []
	for i in n:
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, n - 1)]
		var tg := (b - a).normalized()
		var nr := Vector2(-tg.y, tg.x) * flip
		var hw := lerpf(w0, w1, float(i) / (n - 1)) * 0.5
		nrs.append(nr)
		ws.append(hw)
		lit.append(pts[i] + nr * hw)
		dark.append(pts[i] - nr * hw)
		mid_dark.append(pts[i] - nr * hw * 0.05)
		hl.append(pts[i] + nr * hw * 0.52)
		snow.append(pts[i] + nr * hw * 0.78)
	var outline := lit.duplicate()
	for i in range(n - 1, -1, -1):
		outline.append(dark[i])
	if glow.a > 0.0:
		ci.draw_polyline(pts, glow, w0 + 18.0, true)
		ci.draw_circle(pts[n - 1], (w1 + 18.0) * 0.5, glow, true, -1, true)
	# schaduw
	var sh := PackedVector2Array()
	for p in outline:
		sh.append(p + Vector2(6, 8))
	fill(ci, sh, TtPal.SHADOW_SOFT, false)
	fill(ci, outline, bark)
	var under := mid_dark.duplicate()
	for i in range(n - 1, -1, -1):
		under.append(dark[i])
	fill(ci, under, bark_d)
	ci.draw_circle(pts[n - 1], w1 * 0.5, bark, true, -1, true)
	ci.draw_polyline(hl.slice(1, n - 1), Color(bark_l, 0.9), maxf(1.5, w1 * 0.22), true)
	# schorsstreepjes
	for k in 3:
		var f := 0.15 + 0.7 * _hash(seed_ * 7 + k)
		var i := clampi(int(f * (n - 1)), 1, n - 2)
		var tg := (pts[i + 1] - pts[i - 1]).normalized()
		var off := nrs[i] * ws[i] * (0.15 - 0.5 * _hash(seed_ * 13 + k))
		ci.draw_line(pts[i] + off - tg * 5, pts[i] + off + tg * 5, Color(bark_d, 0.7), 2.0, true)
	if se.get("snow", false):
		ci.draw_polyline(snow.slice(int(n * 0.08), int(n * 0.92)), TtPal.SNOW, maxf(3.0, w1 * 0.5), true)
		for k in 3:
			var i2 := clampi(int((0.2 + 0.25 * k) * (n - 1)), 1, n - 2)
			ci.draw_circle(snow[i2] + nrs[i2] * 1.5, maxf(2.5, ws[i2] * 0.42), TtPal.SNOW, true, -1, true)
	# blaadjes (afwisselend links/rechts, wiegen zacht)
	var leaf_cols: Array = se.get("leaf", [TtPal.BRAND])
	for k in leaves:
		var f2: float = [0.38, 0.66, 0.86][k % 3]
		var i3 := clampi(int(f2 * (n - 1)), 1, n - 2)
		var side := 1.0 if (k + seed_) % 2 == 0 else -1.0
		var tg2 := (pts[i3 + 1] - pts[i3 - 1]).normalized()
		var base := pts[i3] + nrs[i3] * side * ws[i3] * 0.7
		var ang := tg2.angle() + side * flip * -0.95 + sin(t * 1.7 + seed_ * 1.3 + k) * 0.10
		var lc: Color = leaf_cols[(seed_ + k) % leaf_cols.size()]
		lc = lc.lerp(Color("#A08A62"), wither)
		leaf(ci, base, ang, 20.0 + 6.0 * _hash(seed_ * 3 + k), lc)


## Spooktak: gestippelde voorvertoning van een tak die nog niet gegroeid is (plannen / tutorial-hint).
static func ghost_branch(ci: CanvasItem, pts: PackedVector2Array, t := 0.0, col := Color(1, 1, 1, 0.85), w := 6.0) -> void:
	var L := path_length(pts)
	var dash := 16.0
	var off := fmod(t * 30.0, dash * 2.0)
	var s := -off
	while s < L:
		var a := maxf(0.0, s)
		var b := minf(L, s + dash)
		if b > a:
			ci.draw_line(path_point(pts, a / L), path_point(pts, b / L), col, w, true)
		s += dash * 2.0
	ci.draw_circle(pts[pts.size() - 1], w * 1.4, col, true, -1, true)


## Spookvrucht: waar een nieuw blad zal hangen (stippelcirkel + vaag label).
static func ghost_fruit(ci: CanvasItem, tip: Vector2, word: String, t := 0.0, r := 24.0, label_size := 22, alphabet := "ACGT_") -> void:
	var c := tip + Vector2(0, r * 1.75)
	ci.draw_line(tip, c - Vector2(0, r), Color(1, 1, 1, 0.7), 2.0, true)
	var segs := 14
	for k in segs:
		if k % 2 == 0:
			var a0 := k * TAU / segs + t * 0.8
			ci.draw_arc(c, r, a0, a0 + TAU / segs, 6, Color(1, 1, 1, 0.85), 3.0, true)
	ci.draw_circle(c, r - 2, Color(1, 1, 1, 0.18), true, -1, true)
	var lw := TtPal.word_width(word.length(), label_size) + label_size * 0.8
	var lr := Rect2(c.x - lw / 2.0, c.y + r + 12, lw, label_size * 1.55)
	ci.draw_style_box(TtPal.sb(Color(TtPal.PAPER, 0.55), int(label_size * 0.35)), lr)
	TtPal.word(ci, lr.get_center() + Vector2(0, 1), word, label_size, true, alphabet, -1, -1, TtPal.WARN, -1, -1, 0)


## Ent-wikkel (raffia) rond een tak op fractie f: Patricia-tak waarin overgeslagen letters zitten.
static func graft_wrap(ci: CanvasItem, pts: PackedVector2Array, f: float, w: float, wraps := 3) -> void:
	var p := path_point(pts, f)
	var tg := path_tangent(pts, f)
	var nr := Vector2(-tg.y, tg.x)
	for k in wraps:
		var c := p + tg * (k - (wraps - 1) / 2.0) * 7.0
		var a := c + nr * (w * 0.62) - tg * 3.5
		var b := c - nr * (w * 0.62) + tg * 3.5
		ci.draw_line(a + Vector2(1, 2), b + Vector2(1, 2), Color(TtPal.RAFFIA_DARK, 0.8), 6.0, true)
		ci.draw_line(a, b, TtPal.RAFFIA, 5.0, true)
		ci.draw_line(a.lerp(b, 0.1), a.lerp(b, 0.45), Color(1, 1, 1, 0.35), 1.6, true)


## Spookknoppen: holle ringen op de tak voor letters die een Patricia-zoektocht NIET bekijkt (enkel aantal, geen letter).
static func ghost_beads(ci: CanvasItem, pts: PackedVector2Array, f0: float, f1: float, count: int, t := 0.0) -> void:
	for k in count:
		var f := lerpf(f0, f1, (k + 0.5) / count)
		var p := path_point(pts, f)
		var a := 0.55 + 0.15 * sin(t * 2.0 + k * 0.8)
		ci.draw_circle(p, 8.0, Color(TtPal.PAPER, 0.25), true, -1, true)
		ci.draw_arc(p, 8.0, 0, TAU, 20, Color(TtPal.PAPER, a), 2.0, true)


# ================================================================ knoest (interne trie-top = array van kinderen)
## Knoest met een knoppenrij: één knop per letter van het alfabet (k_a). `used[i]` = kind aanwezig.
## Gebruikte knop: groene knop + letterchip; lege knop: slapend knopje (= NULL-pointer, kost ook sap).
## `hi` = index van de knop die nu bekeken wordt (ring). `compact`: groot alfabet (> 8): smallere knoppen,
## enkel letters van gebruikte knoppen. Geeft de aanhechtpunten (bovenkant knop) terug.
static func knot(ci: CanvasItem, c: Vector2, letters: String, used: Array, gap := 34.0, hi := -1, t := 0.0,
		compact := false) -> PackedVector2Array:
	var n := letters.length()
	if compact:
		gap = minf(gap, 14.0)
	var w := n * gap + 20.0
	var h := 36.0
	var r := Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 18, 10, Vector2(4, 8)), r)
	ci.draw_style_box(TtPal.sb_thick(TtPal.KNOT, 18, 7, TtPal.KNOT_RIM), r)
	ci.draw_line(Vector2(r.position.x + 16, r.position.y + 4), Vector2(r.end.x - 16, r.position.y + 4), Color(TtPal.KNOT_TOP, 0.9), 3.0, true)
	# houtnerf
	ci.draw_arc(Vector2(r.end.x - 22, c.y + 2), 6, PI * 0.2, PI * 1.6, 10, Color(TtPal.KNOT_RIM, 0.6), 1.6, true)
	var tops := PackedVector2Array()
	for i in n:
		var bx := c.x - (n - 1) * gap / 2.0 + i * gap
		var on: bool = used[i] if i < used.size() else false
		var by := r.position.y
		if not compact or on:
			if on:
				var chip := Rect2(bx - 11, c.y - 10, 22, 24)
				ci.draw_style_box(TtPal.sb(TtPal.letter_color(letters[i], letters), 6), chip)
				TtPal.text_c(ci, TtPal.MONO, Vector2(bx, c.y + 2), letters[i], 18, TtPal.INK)
			else:
				TtPal.text_c(ci, TtPal.MONO_B, Vector2(bx, c.y + 2), letters[i], 18, Color(TtPal.TEXT, 0.42))
		if on:
			ci.draw_circle(Vector2(bx, by), 9.0, TtPal.BUD_DARK, true, -1, true)
			ci.draw_circle(Vector2(bx - 1, by - 1), 6.5, TtPal.BUD, true, -1, true)
		else:
			# slapend knopje: gesloten ovaaltje met puntje (NULL-pointer)
			var bs := 0.65 if compact else 1.0
			var bc := Vector2(bx, by - 3 * bs)
			ellipse(ci, bc + Vector2(0, 1), 6.5 * bs, 8 * bs, TtPal.BUD_EMPTY_DARK)
			ellipse(ci, bc, 5.2 * bs, 6.8 * bs, TtPal.BUD_EMPTY)
			fill(ci, PackedVector2Array([bc + Vector2(-2.5, -5) * bs, bc + Vector2(0, -11) * bs, bc + Vector2(2.5, -5) * bs]), TtPal.BUD_EMPTY_DARK)
			ci.draw_circle(bc + Vector2(-1.8, -2) * bs, 1.6 * bs, Color(1, 1, 1, 0.6), true, -1, true)
		if i == hi:
			var pr := 0.5 + 0.5 * sin(t * 8.0)
			TtPal.ring(ci, Rect2(bx - 15, by - 16, 30, 50), 12, Color(TtPal.INFO, 0.6 + 0.4 * pr), 3)
		tops.append(Vector2(bx, by - 2))
	return tops


## Wortel = lege string: stam van de grond naar de wortelknoest, wortels in een aardhoopje, plaatje "∅".
static func root(ci: CanvasItem, ground: Vector2, top: Vector2, se: Dictionary, t := 0.0) -> void:
	var gcol: Color = se.get("ground", TtPal.BRAND)
	ellipse(ci, ground + Vector2(6, 10), 130, 26, TtPal.SHADOW_SOFT)
	ellipse(ci, ground + Vector2(0, 6), 118, 24, gcol.darkened(0.22))
	ellipse(ci, ground + Vector2(-8, 1), 104, 17, gcol.darkened(0.08))
	for k in 4:
		var sx: float = [-1.0, -0.45, 0.4, 1.0][k]
		var a := ground + Vector2(sx * 14, -4)
		var b := ground + Vector2(sx * 92, 6 + 6 * absf(sx))
		var pts := branch_curve(a, b, Vector2(sx, 0.4).normalized(), 0.0, 12)
		branch(ci, pts, 16.0, 4.0, {"snow": false, "leaf": []}, k, t, 0)
	var trunk := branch_curve(ground + Vector2(0, -2), top, Vector2.UP, 0.04, 20)
	branch(ci, trunk, 44.0, 30.0, se, 99, t, 0)
	var plaque := Rect2(ground.x - 22, ground.y - 64, 44, 32)
	ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, 9, 4, TtPal.PAPER_EDGE), plaque)
	var f := TtPal.MONO if TtPal.MONO.has_char(0x2205) else TtPal.UI_BOLD
	TtPal.text_c(ci, f, plaque.get_center() + Vector2(0, -1), "∅", 22, TtPal.INK)


# ================================================================ letterlabel op een tak
## Letterchip (de letter a van kind k_a) op een tak. `size` = fontgrootte (≥ 22 aanbevolen).
static func letter_tag(ci: CanvasItem, c: Vector2, ch: String, size := 26, alphabet := "ACGT_", hi := Color(0, 0, 0, 0), dim := false) -> void:
	var cw := TtPal.char_w(size)
	var r := Rect2(c.x - cw / 2.0 - size * 0.32, c.y - size * 0.72, cw + size * 0.64, size * 1.44)
	if hi.a > 0.0:
		TtPal.ring(ci, r.grow(5), int(size * 0.34) + 5, hi, 4)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), int(size * 0.34), 4, Vector2(2, 4)), r)
	var col := TtPal.letter_color(ch, alphabet)
	if dim:
		col = col.lerp(TtPal.CHIP_NEUTRAL, 0.6)
	ci.draw_style_box(TtPal.sb_thick(col, int(size * 0.34), 3, col.darkened(0.3)), r)
	TtPal.text_c(ci, TtPal.MONO, c + Vector2(0, -1), ch, size, Color(TtPal.INK, 0.45 if dim else 1.0))


## Klein papieren label met mono-tekst (bv. "2,4" bij een suffixboog, "skip 3"). Geeft rect terug.
static func tag(ci: CanvasItem, c: Vector2, s: String, size := 20, bg := TtPal.PAPER, edge := TtPal.PAPER_EDGE, ink := TtPal.INK,
		border := Color(0, 0, 0, 0)) -> Rect2:
	var w := TtPal.MONO.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 0.9
	var r := Rect2(c.x - w / 2.0, c.y - size * 0.75, w, size * 1.5)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), int(size * 0.4), 4, Vector2(2, 4)), r)
	ci.draw_style_box(TtPal.sb_thick(bg, int(size * 0.4), 3, edge), r)
	if border.a > 0.0:
		TtPal.ring(ci, r, int(size * 0.4), border, 2)
	TtPal.text_c(ci, TtPal.MONO, c + Vector2(0, -1), s, size, ink)
	return r


## Boogpaar (b,e) van een suffixboom-tak: wijst naar posities in de slinger. `hi`: oplichten (koppeling met slinger).
static func be_tag(ci: CanvasItem, c: Vector2, b: int, e: int, hi := false) -> Rect2:
	var bg := TtPal.STAR if hi else TtPal.PAPER
	return tag(ci, c, "%d,%d" % [b, e], 20, bg, bg.darkened(0.18), TtPal.INK, TtPal.ROPE)


# ================================================================ vrucht (blad van de trie)
## Vrucht die aan `tip` (einde van een tak) hangt, met een papieren label met het woord eronder.
## state: 0 normaal, 1 doel/gemarkeerd (OK-ring), 2 fout/verkeerd (grijs + WARN-ring), 3 gevonden (gouden gloed).
## Geeft de rect van het label terug (handig voor klikzones/bijen).
static func fruit(ci: CanvasItem, tip: Vector2, se: Dictionary, word := "", t := 0.0, state := 0, r := 24.0,
		alphabet := "ACGT_", label_size := 22, hi_from := -1, hi_to := -1, chips := true, owner := -1) -> Rect2:
	## owner >= 0: veralgemeende suffixboom, de vrucht krijgt de kleur én het vormpje van verdachte `owner`.
	var sway := sin(t * 1.4 + tip.x * 0.013) * 0.06
	var stem := r * 0.75
	var dir := Vector2(sin(sway), cos(sway))
	var c := tip + dir * (stem + r)
	var col: Color = se.get("fruit", TtPal.SAP)
	var hi: Color = se.get("fruit_hi", Color.WHITE)
	var dk: Color = se.get("fruit_dark", TtPal.SAP_DARK)
	if state == 2:
		col = col.lerp(Color("#9C9486"), 0.65)
		hi = hi.lerp(Color("#C9C2B5"), 0.65)
		dk = dk.lerp(Color("#6E675C"), 0.65)
	if owner >= 0:
		var so: Dictionary = TtPal.SUSPECTS[owner % TtPal.SUSPECTS.size()]
		col = so.col
		hi = so.col.lightened(0.45)
		dk = so.col.darkened(0.3)
	var kind: String = se.get("fruit_kind", "appel")
	if state == 3 or kind == "lampion":
		var g: Color = TtPal.STAR if state == 3 else se.get("light", TtPal.STAR)
		for k in 3:
			ci.draw_circle(c, r * (2.1 - k * 0.38), Color(g, 0.07 + k * 0.05), true, -1, true)
	if state == 1:
		var p := 0.5 + 0.5 * sin(t * 6.0)
		ci.draw_arc(c, r + 9, 0, TAU, 40, Color(TtPal.OK, 0.55 + 0.45 * p), 4.0, true)
	ci.draw_line(tip, c - dir * r * 0.8, TtPal.BARK_DARK, 3.5, true)
	ellipse(ci, c + Vector2(5, 7), r, r * 0.95, TtPal.SHADOW_SOFT)
	match kind:
		"peer":
			ci.draw_circle(c + Vector2(0, -r * 0.55), r * 0.62, dk, true, -1, true)
			ci.draw_circle(c + Vector2(0, r * 0.12), r * 0.98, dk, true, -1, true)
			ci.draw_circle(c + Vector2(-1.5, -r * 0.6), r * 0.56, col, true, -1, true)
			ci.draw_circle(c + Vector2(-2, r * 0.06), r * 0.9, col, true, -1, true)
			ellipse(ci, c + Vector2(-r * 0.38, -r * 0.1), r * 0.2, r * 0.36, Color(hi, 0.85), -0.3)
		"lampion":
			var body := ellipse_pts(c, r * 0.92, r * 1.05, 0.0, 36)
			fill(ci, body, dk)
			fill(ci, ellipse_pts(c + Vector2(-1.5, -1.5), r * 0.84, r * 0.98, 0.0, 36), col)
			for k in 3:
				var x := (k - 1) * r * 0.42
				ci.draw_line(c + Vector2(x, -r * 0.95), c + Vector2(x * 1.25, 0), Color(dk, 0.7), 2.0, true)
				ci.draw_line(c + Vector2(x * 1.25, 0), c + Vector2(x, r * 0.95), Color(dk, 0.7), 2.0, true)
			ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(hi, 0.9), true, -1, true)
			ci.draw_style_box(TtPal.sb(TtPal.BARK_DARK, 3), Rect2(c + Vector2(-r * 0.32, -r * 1.12), Vector2(r * 0.64, r * 0.22)))
		_:
			# bloesemvrucht (lente) / appel (zomer): rond met kuiltje bovenaan
			ci.draw_circle(c + Vector2(1.5, 2), r, dk, true, -1, true)
			ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.08), r * 0.78, col, true, -1, true)
			ci.draw_circle(c + Vector2(r * 0.3, -r * 0.08), r * 0.74, col, true, -1, true)
			ci.draw_circle(c + Vector2(0, r * 0.12), r * 0.82, col, true, -1, true)
			ci.draw_arc(c + Vector2(0, -r * 0.95), r * 0.3, PI * 0.15, PI * 0.85, 8, Color(dk, 0.7), 2.0, true)
			ellipse(ci, c + Vector2(-r * 0.42, -r * 0.3), r * 0.18, r * 0.28, Color(hi, 0.9), -0.5)
			if kind == "bloesem":
				for k in 5:
					var a := -PI / 2 + k * TAU / 5
					ci.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.3 + Vector2(0, r * 0.15), r * 0.12, Color(hi, 0.55), true, -1, true)
	var lcol: Array = se.get("leaf", [TtPal.BRAND])
	leaf(ci, tip + dir * 3, dir.angle() - 2.2 + sway, r * 0.75, lcol[0])
	if state == 2:
		ci.draw_arc(c, r + 8, 0, TAU, 40, Color(TtPal.WARN, 0.9), 3.0, true)
		for k in 3:
			var a := t * (2.2 + k * 0.5) + k * 2.1
			var fp := c + Vector2(cos(a) * (r + 14), sin(a * 1.3) * (r * 0.6) - r * 0.4)
			ci.draw_circle(fp, 2.6, TtPal.BEE_STRIPE, true, -1, true)
			ci.draw_circle(fp + Vector2(-1.5, -2.5), 2.0, Color(1, 1, 1, 0.6), true, -1, true)
	if word == "":
		return Rect2(c - Vector2(r, r), Vector2(r, r) * 2)
	# label aan een touwtje
	var ls := label_size
	var lw := TtPal.word_width(word.length(), ls) + ls * 0.8
	var lh := ls * 1.55
	var top := c + Vector2(0, r + 12)
	var lr := Rect2(top.x - lw / 2.0, top.y, lw, lh)
	ci.draw_line(c + Vector2(0, r * 0.9), top + Vector2(0, 3), TtPal.INK_SOFT, 2.0, true)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), int(ls * 0.35), 5, Vector2(2, 5)), lr)
	ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, int(ls * 0.35), 4, TtPal.PAPER_EDGE), lr)
	ci.draw_circle(Vector2(top.x, top.y + 5), 2.6, TtPal.PAPER_EDGE.darkened(0.2), true, -1, true)
	TtPal.word(ci, lr.get_center() + Vector2(0, 1), word, ls, chips, alphabet, hi_from, hi_to)
	if state == 1:
		TtPal.ring(ci, lr.grow(5), int(ls * 0.35) + 5, Color(TtPal.OK, 0.8), 3)
	elif state == 2:
		TtPal.ring(ci, lr.grow(5), int(ls * 0.35) + 5, TtPal.WARN, 3)
	if owner >= 0:
		suspect_mark(ci, Vector2(lr.end.x + 12, lr.get_center().y), owner, 10.0)
	return lr


# ================================================================ zaadzakje (woord dat geplant moet worden)
static func seed_packet(ci: CanvasItem, c: Vector2, word: String, se: Dictionary, sz := Vector2(220, 116), lifted := false,
		t := 0.0, alphabet := "ACGT_", label_size := 26, hi_from := -1, hi_to := -1) -> Rect2:
	var r := Rect2(c - sz / 2.0, sz)
	if lifted:
		ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 14, 22, Vector2(8, 20)), r)
	else:
		ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 14, 8, Vector2(3, 6)), r)
	ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, 14, 6, TtPal.PAPER_EDGE), r)
	# gekartelde bovenrand in seizoenskleur
	var band := Rect2(r.position, Vector2(sz.x, sz.y * 0.34))
	var acc: Color = se.get("leaf", [TtPal.BRAND])[0]
	var pts := PackedVector2Array()
	pts.append(Vector2(band.position.x + 8, band.end.y))
	pts.append(Vector2(band.position.x, band.end.y - 8))
	pts.append(Vector2(band.position.x, band.position.y + 14))
	var teeth := 14
	for k in teeth + 1:
		var x := band.position.x + k * sz.x / teeth
		pts.append(Vector2(x, band.position.y + (0.0 if k % 2 == 0 else 6.0)))
	pts.append(Vector2(band.end.x, band.end.y - 8))
	pts.append(Vector2(band.end.x - 8, band.end.y))
	fill(ci, pts, acc)
	ci.draw_line(Vector2(band.position.x + 6, band.end.y), Vector2(band.end.x - 6, band.end.y), acc.darkened(0.25), 2.0, true)
	sprout(ci, Vector2(band.position.x + 24, band.end.y - 6), 0.8, Color.WHITE)
	TtPal.text_l(ci, TtPal.UI_BOLD, Vector2(band.position.x + 46, band.get_center().y + 1), "zaadje", 18, Color.WHITE)
	var ls := TtPal.fit_word(word.length(), sz.x - 24, label_size)
	TtPal.word(ci, Vector2(c.x, r.position.y + sz.y * 0.66), word, ls, true, alphabet, hi_from, hi_to)
	if lifted:
		TtPal.ring(ci, r.grow(7), 20, Color(1, 1, 1, 0.75 + 0.25 * sin(t * 6.0)), 4)
	return r


# ================================================================ iconen
static func sprout(ci: CanvasItem, base: Vector2, s := 1.0, col := TtPal.BRAND) -> void:
	ci.draw_line(base, base + Vector2(0, -14) * s, col, 3.0 * s, true)
	leaf(ci, base + Vector2(0, -12) * s, -PI * 0.25, 13 * s, col, false)
	leaf(ci, base + Vector2(0, -9) * s, -PI * 0.8, 10 * s, col, false)


## Sapdruppel (punt boven).
static func drop(ci: CanvasItem, c: Vector2, r: float, col := TtPal.SAP, shine := true) -> void:
	var pts := PackedVector2Array()
	for k in 25:
		var a := PI * 0.5 + (k / 24.0 - 0.5) * PI * 1.6
		pts.append(c + Vector2(cos(a), sin(a)) * r + Vector2(0, r * 0.25))
	pts.append(c + Vector2(0, -r * 1.35))
	fill(ci, pts, col)
	if shine:
		ellipse(ci, c + Vector2(-r * 0.35, r * 0.15), r * 0.18, r * 0.32, Color(1, 1, 1, 0.55), 0.3)


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * TAU / 10 + rot
		var rr := r if k % 2 == 0 else r * 0.5
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	fill(ci, pts, col)


## Rapportster: gevuld (goud met onderrand) of leeg slot.
static func star_slot(ci: CanvasItem, c: Vector2, r: float, filled: bool, rot := 0.0) -> void:
	if filled:
		star(ci, c + Vector2(0, r * 0.08), r, TtPal.STAR_DARK, rot)
		star(ci, c, r, TtPal.STAR, rot)
		star(ci, c + Vector2(-r * 0.12, -r * 0.14), r * 0.35, Color(1, 1, 1, 0.5), rot)
	else:
		star(ci, c, r, Color(0, 0, 0, 0.22), rot)


## Snoeischaar. `open` 0..1 (0 dicht). `col` = lemmet, `grip` = handvatten.
static func shears(ci: CanvasItem, c: Vector2, s := 1.0, open := 0.4, grip := TtPal.GREATER, col := Color("#DCE3EA")) -> void:
	var a := 0.15 + open * 0.45
	for side in [-1.0, 1.0]:
		var rot: float = -PI / 2 + side * a
		var blade := PackedVector2Array([Vector2(0, -4), Vector2(30, -3), Vector2(42, 0), Vector2(30, 4), Vector2(0, 4)])
		var bw := xf(blade, c, s, 1.0, rot)
		fill(ci, bw, col)
		ci.draw_line(xp(Vector2(2, -2), c, s, 1.0, rot), xp(Vector2(34, -1), c, s, 1.0, rot), Color(1, 1, 1, 0.7), 1.5 * s, true)
		var hc := c + (c - xp(Vector2(26, 0), c, s, 1.0, rot)).normalized() * 22 * s
		ci.draw_line(c, hc, grip.darkened(0.25), 7 * s, true)
		ci.draw_arc(hc + (hc - c).normalized() * 9 * s, 9 * s, 0, TAU, 20, grip, 5 * s, true)
	ci.draw_circle(c, 4.5 * s, Color("#8C97A3"), true, -1, true)
	ci.draw_circle(c + Vector2(-1, -1) * s, 1.8 * s, Color(1, 1, 1, 0.8), true, -1, true)


## Vergrootglas (speurneus, zoeken).
static func magnifier(ci: CanvasItem, c: Vector2, r: float, rot := 0.8) -> void:
	var hd := Vector2(cos(rot), sin(rot))
	ci.draw_line(c + hd * r, c + hd * r * 2.1, TtPal.BARK_DARK, r * 0.42, true)
	ci.draw_line(c + hd * r * 1.15, c + hd * r * 2.0, TtPal.BARK, r * 0.26, true)
	ci.draw_circle(c, r, Color(TtPal.INFO, 0.28), true, -1, true)
	ci.draw_arc(c, r * 0.68, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.8), r * 0.13, true)
	ci.draw_arc(c, r, 0, TAU, 36, Color("#3B4A55"), r * 0.2, true)


# ================================================================ sapmeter
## Horizontale sapmeter (geheugen = sap). `frac` 0..1 resterend sap, `ghost` = sap na de voorgestelde zet
## (lichter gebied = wat de zet kost), `opt` = optimale eindstand (vlaggetje). Druppelicoon links van de buis.
static func sap_meter(ci: CanvasItem, r: Rect2, frac: float, t := 0.0, opt := -1.0, ghost := -1.0, label := "", loss := 0.0) -> void:
	## loss: fractie die deze zet méér kostte dan nodig (amber "verlies"-streep rechts van het niveau).
	var h := r.size.y
	drop(ci, Vector2(r.position.x - h * 0.75, r.get_center().y + h * 0.05), h * 0.42)
	ci.draw_style_box(TtPal.sb(TtPal.SLOT, int(h / 2)), r)
	var inner := r.grow(-4)
	var fw := inner.size.x * clampf(frac, 0.0, 1.0)
	if ghost >= 0.0 and ghost < frac:
		var gx := inner.size.x * clampf(ghost, 0.0, 1.0)
		ci.draw_style_box(TtPal.sb(Color(TtPal.SAP_LIGHT, 0.45 + 0.2 * sin(t * 5.0)), int(inner.size.y / 2)), Rect2(inner.position, Vector2(fw, inner.size.y)))
		fw = gx
	if fw > inner.size.y * 0.5:
		var fr := Rect2(inner.position, Vector2(fw, inner.size.y))
		ci.draw_style_box(TtPal.sb_thick(TtPal.SAP, int(inner.size.y / 2), int(inner.size.y * 0.28), TtPal.SAP_DARK), fr)
		ci.draw_line(fr.position + Vector2(inner.size.y * 0.4, inner.size.y * 0.26), Vector2(fr.end.x - inner.size.y * 0.4, fr.position.y + inner.size.y * 0.26), Color(TtPal.SAP_LIGHT, 0.9), maxf(2.0, inner.size.y * 0.16), true)
		for k in 6:
			var u := fmod(_hash(k) + t * (0.05 + 0.03 * _hash(k + 9)), 1.0)
			var bx := fr.position.x + fr.size.x * (1.0 - u)
			var by := fr.position.y + fr.size.y * (0.45 + 0.3 * sin(t * 2.0 + k))
			ci.draw_arc(Vector2(bx, by), 2.2 + 1.5 * _hash(k + 3), 0, TAU, 10, Color(1, 1, 1, 0.45), 1.2, true)
	if loss > 0.0:
		var lx := inner.position.x + inner.size.x * clampf(frac, 0.0, 1.0)
		var lw2 := inner.size.x * loss
		var lr2 := Rect2(lx, inner.position.y, lw2, inner.size.y)
		ci.draw_style_box(TtPal.sb(Color(TtPal.WARN, 0.55 + 0.25 * sin(t * 6.0)), 4), lr2)
		var k := 0.0
		while k < lw2:
			ci.draw_line(Vector2(lx + k, lr2.end.y), Vector2(lx + minf(k + 8, lw2), lr2.position.y), Color(1, 1, 1, 0.35), 2.0, true)
			k += 10.0
	# glas
	ci.draw_line(Vector2(r.position.x + h * 0.5, r.position.y + 3), Vector2(r.end.x - h * 0.5, r.position.y + 3), Color(1, 1, 1, 0.18), 2.0, true)
	TtPal.ring(ci, r, int(h / 2), Color(1, 1, 1, 0.16), 2)
	if frac < 0.2:
		TtPal.ring(ci, r.grow(3), int(h / 2) + 3, Color(TtPal.WARN, 0.5 + 0.5 * sin(t * 7.0)), 3)
	if opt >= 0.0:
		# optimum: grijze streep met vlaggetje (GDD §4.3: pas zichtbaar in terugblik / vanaf een ★★-run)
		var ox := inner.position.x + inner.size.x * opt
		ci.draw_line(Vector2(ox, r.position.y - 7), Vector2(ox, r.end.y + 4), Color(TtPal.PAPER, 0.85), 3.0, true)
		fill(ci, PackedVector2Array([Vector2(ox, r.position.y - 7), Vector2(ox + 13, r.position.y - 2), Vector2(ox, r.position.y + 3)]), Color(TtPal.PAPER, 0.85))
	if label != "":
		TtPal.text_l(ci, TtPal.MONO_B, Vector2(r.end.x + 12, r.get_center().y), label, 20, TtPal.TEXT)


# ================================================================ Patricia: skip-label
## Bordje "skip k" bij een Patricia-top (aan `anchor`), met snoeischaar-icoon, aan een touwtje.
static func skip_tag(ci: CanvasItem, anchor: Vector2, skip: int, t := 0.0, side := 1.0, hi := false) -> Rect2:
	var sway := sin(t * 1.6) * 2.0
	var c := anchor + Vector2(side * 88 + sway, 10)
	var s := "skip %d" % skip
	var fs := 22
	var tw := TtPal.MONO.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := Rect2(c.x - (tw + 58) / 2.0, c.y - 20, tw + 58, 40)
	ci.draw_line(anchor, Vector2(r.position.x if side > 0 else r.end.x, c.y - 6), TtPal.RAFFIA_DARK, 2.5, true)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 12, 6, Vector2(2, 5)), r)
	ci.draw_style_box(TtPal.sb_thick(TtPal.RAFFIA if not hi else TtPal.STAR, 12, 5, TtPal.RAFFIA_DARK), r)
	shears(ci, Vector2(r.position.x + 20, c.y - 1), 0.42, 0.5, TtPal.GREATER, Color("#F4F6F8"))
	TtPal.text_l(ci, TtPal.MONO, Vector2(r.position.x + 38, c.y - 1), s, fs, TtPal.INK)
	return r


# ================================================================ ternary: rankknoop
## Rankknoop: één letter + drie uitgangen kleiner (<, links), gelijk (=, boven), groter (>, rechts).
## `exits[i]` = uitgang i heeft een kind (anders: opgekrulde rank = NULL). Geeft de 3 aanhechtpunten terug
## [kleiner, gelijk, groter]. `hi` = index van de uitgang die de bij nu neemt.
static func rank_knot(ci: CanvasItem, c: Vector2, ch: String, t := 0.0, exits := [false, true, false], r := 30.0,
		alphabet := "", hi := -1) -> PackedVector2Array:
	var dirs := [Vector2(-0.94, -0.34), Vector2(0, -1), Vector2(0.94, -0.34)]
	var cols := [TtPal.LESS, TtPal.EQUAL, TtPal.GREATER]
	var syms := ["<", "=", ">"]
	var anchors := PackedVector2Array()
	# opgerolde ranken voor lege uitgangen (achter de knoop)
	for i in 3:
		var d: Vector2 = dirs[i]
		var p0 := c + d * (r + 22)
		anchors.append(c + d * (r + 36))
		if not exits[i]:
			_curl(ci, p0, d, 26.0, t + i, TtPal.TENDRIL)
	ellipse(ci, c + Vector2(5, 8), r + 4, r + 2, TtPal.SHADOW_SOFT)
	ci.draw_circle(c, r + 4, TtPal.KNOT_RIM, true, -1, true)
	ci.draw_circle(c + Vector2(-1, -2), r + 1, TtPal.KNOT, true, -1, true)
	ci.draw_arc(c, r - 3, PI * 1.05, PI * 1.6, 12, Color(TtPal.KNOT_TOP, 0.9), 3.0, true)
	# rank die rond de knoop krult
	ci.draw_arc(c, r + 4, PI * 0.15, PI * 0.95, 20, TtPal.TENDRIL_DARK, 4.0, true)
	ci.draw_arc(c, r + 3, PI * 0.15, PI * 0.95, 20, TtPal.TENDRIL, 2.5, true)
	leaf(ci, c + Vector2(cos(PI * 0.2), sin(PI * 0.2)) * (r + 4), 0.5, 15, TtPal.TENDRIL)
	var lc := r * 0.86
	var lr := Rect2(c.x - lc / 2.0 - 4, c.y - lc / 2.0 - 6, lc + 8, lc + 10)
	ci.draw_style_box(TtPal.sb_thick(TtPal.letter_color(ch, alphabet if alphabet != "" else ch), 8, 3, TtPal.letter_color(ch, alphabet if alphabet != "" else ch).darkened(0.3)), lr)
	TtPal.text_c(ci, TtPal.MONO, lr.get_center() + Vector2(0, -1), ch, int(r * 0.9), TtPal.INK)
	for i in 3:
		var d: Vector2 = dirs[i]
		var bc := c + d * (r + 14)
		var col: Color = cols[i]
		if i == hi:
			ci.draw_circle(bc, 18 + 2 * sin(t * 8.0), Color(col, 0.45), true, -1, true)
		ci.draw_circle(bc + Vector2(1, 2), 13, col.darkened(0.35), true, -1, true)
		ci.draw_circle(bc, 13, col if exits[i] else col.lerp(TtPal.CHIP_NEUTRAL, 0.55), true, -1, true)
		TtPal.text_c(ci, TtPal.MONO, bc + Vector2(0, -1), syms[i], 18, TtPal.INK)
	return anchors


static func _curl(ci: CanvasItem, p0: Vector2, d: Vector2, L: float, t: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var nr := Vector2(-d.y, d.x)
	var steps := 26
	for k in steps:
		var u := float(k) / (steps - 1)
		if u < 0.45:
			pts.append(p0 + d * L * u / 0.45 * 0.8)
		else:
			var v := (u - 0.45) / 0.55
			var ang := v * PI * 1.6 + sin(t * 1.3) * 0.08
			var rad := 9.0 * (1.0 - v * 0.6)
			var cc := p0 + d * L * 0.8 + nr * 9.0
			pts.append(cc + (-nr).rotated(ang) * rad)
	ci.draw_polyline(pts, TtPal.TENDRIL_DARK, 4.0, true)
	ci.draw_polyline(pts, col, 2.6, true)


## Dunne rank (kleiner/groter-pointer in een ternary trie) van p0 naar p1, met wat golving.
static func tendril(ci: CanvasItem, p0: Vector2, p1: Vector2, col := TtPal.TENDRIL, t := 0.0, w := 4.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d := p1 - p0
	var nr := Vector2(-d.y, d.x).normalized()
	if nr.y > 0.0:
		nr = -nr
	for k in 25:
		var u := k / 24.0
		var wob := sin(u * PI * 3.0 + t * 1.2) * 5.0 * sin(u * PI)
		pts.append(p0 + d * u + nr * (wob + sin(u * PI) * d.length() * 0.12))
	ci.draw_polyline(pts, col.darkened(0.3), w + 1.5, true)
	ci.draw_polyline(pts, col, w, true)
	return pts


# ================================================================ slinger (tekst van de suffixboom)
## Slinger met de tekst `text` als bloemkralen (letter + index eronder). Kralen b..e (incl.) lichten op.
## Geeft de kraalcentra terug (index i -> positie), om takken/labels aan te koppelen.
static func garland(ci: CanvasItem, x0: Vector2, text: String, gap: float, se: Dictionary, t := 0.0, hl_b := -1, hl_e := -1,
		sag := 16.0, alphabet := "ACGT_", show_idx := true, cursor := -1) -> PackedVector2Array:
	var n := text.length()
	var span := (n - 1) * gap
	var a := x0 + Vector2(-gap * 0.7, -6)
	var b := x0 + Vector2(span + gap * 0.7, -6)
	# touw: twee in elkaar gedraaide ranken
	for layer in 2:
		var pts := PackedVector2Array()
		for k in 61:
			var u := k / 60.0
			var p := a.lerp(b, u)
			p.y += sin(u * PI) * sag + sin(u * TAU * 7.0 + layer * PI) * 2.2
			pts.append(p)
		ci.draw_polyline(pts, TtPal.ROPE_DARK if layer == 0 else TtPal.ROPE, 4.0 if layer == 0 else 3.0, true)
	for p in [a, b]:
		ci.draw_circle(p, 7, TtPal.BARK_DARK, true, -1, true)
		ci.draw_circle(p + Vector2(-1, -1), 4.5, TtPal.BARK_LIGHT, true, -1, true)
	var lc: Array = se.get("leaf", [TtPal.BRAND])
	for k in n + 1:
		var u := (k * gap + gap * 0.2) / (span + gap * 1.4)
		var p := a.lerp(b, u)
		p.y += sin(u * PI) * sag
		leaf(ci, p, -PI * 0.5 + (0.9 if k % 2 == 0 else -0.9) * 1.2, 13, lc[k % lc.size()], false)
	var centers := PackedVector2Array()
	var night: bool = se.get("night", false)
	for i in n:
		var u := (i * gap + gap * 0.7) / (span + gap * 1.4)
		var anchor := a.lerp(b, u)
		anchor.y += sin(u * PI) * sag
		var swing := sin(t * 1.8 + i * 0.7) * 0.05
		var c := anchor + Vector2(sin(swing), cos(swing)) * 30.0
		centers.append(c)
		var lit := i >= hl_b and i <= hl_e and hl_b >= 0
		ci.draw_line(anchor, c, TtPal.ROPE_DARK, 2.0, true)
		if night or lit:
			var g: Color = TtPal.STAR if lit else se.get("light", TtPal.STAR)
			ci.draw_circle(c, 34, Color(g, 0.10 if not lit else 0.22), true, -1, true)
			ci.draw_circle(c, 27, Color(g, 0.12 if not lit else 0.25), true, -1, true)
		var acc: Color = se.get("accent", TtPal.STAR)
		if not night:
			for k in 6:
				var ang := k * TAU / 6 + 0.3
				ci.draw_circle(c + Vector2(cos(ang), sin(ang)) * 17, 9, acc.darkened(0.08), true, -1, true)
		ci.draw_circle(c + Vector2(2, 3), 19, TtPal.SHADOW_SOFT, true, -1, true)
		var ring_col := TtPal.letter_color(text[i], alphabet)
		if text[i] == "_":
			# afsluitteken = sneeuwkristal (zeshoek)
			var hexa := PackedVector2Array()
			var hexi := PackedVector2Array()
			for k in 6:
				var ang := k * TAU / 6 + PI / 6
				hexa.append(c + Vector2(cos(ang), sin(ang)) * 21)
				hexi.append(c + Vector2(cos(ang), sin(ang)) * 17)
			fill(ci, hexa, Color("#9CC8EE") if not lit else TtPal.STAR_DARK)
			fill(ci, hexi, Color("#EAF5FF"))
		else:
			ci.draw_circle(c, 19, ring_col.darkened(0.25) if not lit else TtPal.STAR_DARK, true, -1, true)
			ci.draw_circle(c, 15.5, TtPal.PAPER, true, -1, true)
		TtPal.text_c(ci, TtPal.MONO, c + Vector2(0, -1), text[i], 24, TtPal.INK)
		if i == cursor:
			ci.draw_arc(c, 24, 0, TAU, 32, Color(TtPal.INFO, 0.7 + 0.3 * sin(t * 8.0)), 3.0, true)
		if show_idx:
			var s := str(i)
			var fs := 18
			var w := TtPal.MONO_B.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 12
			var ir := Rect2(c.x - w / 2.0, c.y + 26, w, 24)
			ci.draw_style_box(TtPal.sb(TtPal.STAR if lit else Color(TtPal.PANEL_LO, 0.88), 8), ir)
			TtPal.text_c(ci, TtPal.MONO_B, ir.get_center(), s, fs, TtPal.INK if lit else TtPal.TEXT)
	if hl_b >= 0 and hl_e >= hl_b and hl_e < n:
		var y := centers[hl_b].y + 60
		var xa := centers[hl_b].x - 14
		var xb := centers[hl_e].x + 14
		ci.draw_line(Vector2(xa, y), Vector2(xb, y), TtPal.STAR, 3.0, true)
		ci.draw_line(Vector2(xa, y), Vector2(xa, y - 8), TtPal.STAR, 3.0, true)
		ci.draw_line(Vector2(xb, y), Vector2(xb, y - 8), TtPal.STAR, 3.0, true)
		be_tag(ci, Vector2((xa + xb) / 2.0, y + 18), hl_b, hl_e, true)
	return centers


# ================================================================ bij (opzoeking)
## Bij die een gevraagd woord draagt. mood: 0 vliegt, 1 verdwaald/twijfel (?), 2 blij (gevonden), 3 weggejaagd.
## `word_pos`: index van de letter die de bij nu "leest" (ring); -1 = geen.
static func bee(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, facing := 1.0, mood := 0, word := "", alphabet := "ACGT_",
		word_pos := -1, chips := true, ghost_to := -1, wasp := 0.0) -> void:
	## wasp 0..1: de wesp (opzoeking van een woord dat er niet is) ziet eruit als een bij (0) tot het vergrootglas
	## haar ontmaskert (1): feller geel, drie dikke zwarte banden, wenkbrauwen, grotere angel, smaller lijf.
	var bob := sin(t * 7.0) * 3.0 * s
	var p := c + Vector2(0, bob)
	var tilt := sin(t * 3.1) * 0.06 + (0.35 * sin(t * 18.0) if mood == 3 else 0.0)
	# draad + label
	if word != "":
		var top := p + Vector2(0, 22 * s)
		var ls := int(20 * clampf(s, 0.8, 1.3))
		var lw := TtPal.word_width(word.length(), ls) + ls * 0.8
		var lr := Rect2(top.x - lw / 2.0, top.y + 18 * s, lw, ls * 1.5)
		ci.draw_line(top, Vector2(top.x, lr.position.y + 2), TtPal.INK_SOFT, 1.6, true)
		ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 8, 4, Vector2(2, 4)), lr)
		ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, 8, 3, TtPal.PAPER_EDGE), lr)
		TtPal.word(ci, lr.get_center(), word, ls, chips, alphabet, word_pos, word_pos, TtPal.INFO, 0 if ghost_to >= 0 else -1, ghost_to,
			word_pos + 1 if word_pos >= 0 else -1)
	ellipse(ci, c + Vector2(0, 46 * s), 16 * s, 4 * s, Color(0, 0, 0, 0.0))
	# vleugels (achter)
	var flap := 0.45 + 0.55 * absf(sin(t * 40.0))
	for k in 2:
		var wc := xp(Vector2(-4 + k * 10, -18), p, s, facing, tilt)
		var wp := ellipse_pts(Vector2.ZERO, 15, 9 * flap, 0.0, 20)
		var wpts := xf(wp, wc, s, facing, tilt - 0.5 + k * 0.35)
		fill(ci, wpts, TtPal.WING)
		var closed := wpts.duplicate()
		closed.append(wpts[0])
		ci.draw_polyline(closed, Color(1, 1, 1, 0.9), 1.4, true)
	# lijf
	var ry := lerpf(20.0, 16.0, wasp)
	var body := ellipse_pts(Vector2.ZERO, 26, ry, 0.0, 36)
	var yel := TtPal.BEE.lerp(TtPal.WASP, wasp)
	var stripe := TtPal.BEE_STRIPE.lerp(TtPal.WASP_STRIPE, wasp)
	fill(ci, xf(body, p + Vector2(1, 2) * s, s, facing, tilt), TtPal.BEE_DARK.lerp(TtPal.WASP.darkened(0.2), wasp))
	var inner := ellipse_pts(Vector2(-1, -2), 24.5, ry - 2.0, 0.0, 36)
	fill(ci, xf(inner, p, s, facing, tilt), yel)
	var bands: Array = [-12.0, 0.0] if wasp < 0.5 else [-17.0, -6.0, 5.0]
	var bw2 := lerpf(4.0, 4.6, wasp)
	for bx in bands:
		var band := PackedVector2Array([Vector2(bx - bw2, -30), Vector2(bx + bw2, -30), Vector2(bx + bw2, 30), Vector2(bx - bw2, 30)])
		for poly in Geometry2D.intersect_polygons(body, band):
			fill(ci, xf(poly, p, s, facing, tilt), stripe)
	var sl := lerpf(35.0, 42.0, wasp)
	fill(ci, xf(PackedVector2Array([Vector2(-24, -3), Vector2(-sl, 1), Vector2(-24, 5)]), p, s, facing, tilt), stripe)
	ci.draw_arc(xp(Vector2(-6, -8), p, s, facing, tilt), 10 * s, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.55), 3 * s, true)
	# voelsprieten
	for k in 2:
		var a0 := xp(Vector2(12 - k * 6, -16), p, s, facing, tilt)
		var a1 := xp(Vector2(20 - k * 4, -31 + k * 2), p, s, facing, tilt)
		ci.draw_line(a0, a1, TtPal.BEE_STRIPE, 2.0 * s, true)
		ci.draw_circle(a1, 3.0 * s, TtPal.BEE_STRIPE, true, -1, true)
	# gezicht
	var eye := xp(Vector2(14, -4), p, s, facing, tilt)
	var look := Vector2(facing * 1.5, 0) * s
	match mood:
		2:
			ci.draw_arc(eye, 5 * s, PI * 1.1, PI * 1.9, 10, TtPal.BEE_STRIPE, 2.6 * s, true)
		3:
			ci.draw_line(eye + Vector2(-4, -4) * s, eye + Vector2(4, 0) * s, TtPal.BEE_STRIPE, 2.6 * s, true)
			ci.draw_line(eye + Vector2(-4, 4) * s, eye + Vector2(4, 0) * s, TtPal.BEE_STRIPE, 2.6 * s, true)
		1:
			ci.draw_circle(eye, 7 * s, Color.WHITE, true, -1, true)
			ci.draw_arc(eye, 4 * s, t * 6.0, t * 6.0 + PI * 1.5, 12, TtPal.BEE_STRIPE, 2.0 * s, true)
		_:
			ci.draw_circle(eye, 7 * s, Color.WHITE, true, -1, true)
			ci.draw_circle(eye + look, 3.8 * s, TtPal.BEE_STRIPE, true, -1, true)
			ci.draw_circle(eye + look + Vector2(-1.2, -1.4) * s, 1.3 * s, Color.WHITE, true, -1, true)
	if wasp >= 0.5:
		ci.draw_line(xp(Vector2(8, -13), p, s, facing, tilt), xp(Vector2(20, -9), p, s, facing, tilt), stripe, 2.6 * s, true)
	else:
		ellipse(ci, xp(Vector2(17, 7), p, s, facing, tilt), 4.5 * s, 2.8 * s, Color(TtPal.BLUSH, 0.75))
	if mood != 3:
		ci.draw_arc(xp(Vector2(21, 3), p, s, facing, tilt), 3.5 * s, PI * 0.15, PI * 0.85 if mood != 1 else PI * 0.5, 8, TtPal.BEE_STRIPE, 1.8 * s, true)
	if mood == 1:
		TtPal.text_outline_c(ci, TtPal.UI_BOLD, p + Vector2(facing * 22, -44) * s, "?", int(30 * s), TtPal.TEXT, 6)


# ================================================================ speurneus (inspecteur, §3.3)
## Egel-detective met deerstalker en vergrootglas. `c` = midden tussen de voetjes. mood: 0 rustig, 1 "hmm?",
## 2 blij, 3 verbaasd.
static func hedgehog(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, facing := 1.0, mood := 0) -> void:
	var breathe := 1.0 + sin(t * 2.2) * 0.012
	var sv := s * breathe
	ellipse(ci, c + Vector2(4, 2) * s, 62 * s, 10 * s, TtPal.SHADOW_SOFT)
	# stekels: twee lagen gekartelde koepel
	for layer in 2:
		var pts := PackedVector2Array()
		var spikes := 15
		var cc := Vector2(-12, -44) + Vector2(layer * 2, layer * 3)
		var rx := 60.0 - layer * 7
		var ry := 46.0 - layer * 6
		pts.append(Vector2(32, -4))
		for k in spikes * 2 + 1:
			var u := float(k) / (spikes * 2)
			var a := lerpf(-0.05 * PI, -1.08 * PI, u)
			var rr := 1.0 if k % 2 == 0 else 1.2
			pts.append(cc + Vector2(cos(a) * rx * rr, sin(a) * ry * rr))
		pts.append(Vector2(-58, -4))
		fill(ci, xf(pts, c, sv, facing), TtPal.HOG_DARK if layer == 0 else TtPal.HOG)
	for k in 5:
		var a := lerpf(-0.25 * PI, -0.9 * PI, k / 4.0)
		var q0 := Vector2(-12, -44) + Vector2(cos(a), sin(a)) * 24.0
		var q1 := Vector2(-12, -44) + Vector2(cos(a), sin(a)) * 40.0
		ci.draw_line(xp(q0, c, sv, facing), xp(q1, c, sv, facing), Color(TtPal.HOG_DARK, 0.7), 2.0 * s, true)
	# voetjes
	for fx in [-10.0, 22.0]:
		ellipse(ci, xp(Vector2(fx, -3), c, s, facing), 11 * s, 6 * s, TtPal.HOG_DARK)
	# gezicht + snuit
	var face := PackedVector2Array()
	for k in 25:
		var a := lerpf(-PI * 0.95, PI * 0.55, k / 24.0)
		face.append(Vector2(22, -30) + Vector2(cos(a) * 28, sin(a) * 26))
	face.append(Vector2(66, -24))
	fill(ci, xf(face, c, sv, facing), TtPal.HOG_FACE)
	var nose := xp(Vector2(66, -25), c, sv, facing)
	ci.draw_circle(nose, 6.5 * s, TtPal.BEE_STRIPE, true, -1, true)
	ci.draw_circle(nose + Vector2(-2 * facing, -2) * s, 2.0 * s, Color(1, 1, 1, 0.7), true, -1, true)
	ci.draw_circle(xp(Vector2(10, -48), c, sv, facing), 7 * s, TtPal.HOG_FACE.darkened(0.15), true, -1, true)
	var eye := xp(Vector2(36, -38), c, sv, facing)
	match mood:
		2:
			ci.draw_arc(eye, 5 * s, PI * 1.1, PI * 1.9, 10, TtPal.BEE_STRIPE, 2.6 * s, true)
		3:
			ci.draw_circle(eye, 6.5 * s, Color.WHITE, true, -1, true)
			ci.draw_circle(eye, 3.4 * s, TtPal.BEE_STRIPE, true, -1, true)
		_:
			ci.draw_circle(eye, 4.6 * s, TtPal.BEE_STRIPE, true, -1, true)
			ci.draw_circle(eye + Vector2(-1.3 * facing, -1.6) * s, 1.5 * s, Color.WHITE, true, -1, true)
	if mood == 1:
		ci.draw_line(xp(Vector2(30, -50), c, sv, facing), xp(Vector2(42, -54), c, sv, facing), TtPal.HOG_DARK, 2.6 * s, true)
	ellipse(ci, xp(Vector2(44, -26), c, sv, facing), 5.5 * s, 3.4 * s, Color(TtPal.BLUSH, 0.6))
	if mood == 2:
		ci.draw_arc(xp(Vector2(52, -18), c, sv, facing), 6 * s, PI * 0.1, PI * 0.8, 10, TtPal.BEE_STRIPE, 2.0 * s, true)
	# deerstalker
	var hat := PackedVector2Array()
	for k in 17:
		var a := lerpf(PI, TAU, k / 16.0)
		hat.append(Vector2(20, -56) + Vector2(cos(a) * 26, sin(a) * 20))
	var hw := xf(hat, c, sv, facing)
	fill(ci, hw, TtPal.HAT)
	for k in 4:
		var x := -2.0 + k * 12.0
		ci.draw_line(xp(Vector2(x, -58), c, sv, facing), xp(Vector2(x + 4, -74), c, sv, facing), Color(TtPal.HAT_DARK, 0.6), 2.0 * s, true)
	ci.draw_line(xp(Vector2(-4, -64), c, sv, facing), xp(Vector2(44, -64), c, sv, facing), Color(TtPal.HAT_DARK, 0.6), 2.0 * s, true)
	fill(ci, xf(PackedVector2Array([Vector2(-8, -57), Vector2(50, -57), Vector2(60, -52), Vector2(-14, -52)]), c, sv, facing), TtPal.HAT_DARK)
	ci.draw_circle(xp(Vector2(20, -77), c, sv, facing), 4 * s, TtPal.HAT_DARK, true, -1, true)
	# vergrootglas in de hand
	var bobm := sin(t * 1.7) * 3.0
	var hand := xp(Vector2(50, -6 + bobm * 0.3), c, s, facing)
	var glass := xp(Vector2(84, -40 + bobm), c, s, facing)
	ci.draw_line(hand, glass, TtPal.BARK_DARK, 6 * s, true)
	ci.draw_circle(hand, 7 * s, TtPal.HOG_FACE.darkened(0.08), true, -1, true)
	ci.draw_circle(glass, 21 * s, Color(TtPal.INFO, 0.25), true, -1, true)
	ci.draw_arc(glass, 14 * s, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.8), 3 * s, true)
	ci.draw_arc(glass, 21 * s, 0, TAU, 40, Color("#3B4A55"), 4.5 * s, true)


# ================================================================ tekstballon
## Papieren tekstballon met staartje naar `tail` (punt waar de spreker staat).
static func bubble(ci: CanvasItem, r: Rect2, tail: Vector2, col := TtPal.PAPER) -> void:
	var cx := clampf(tail.x, r.position.x + 30, r.end.x - 30)
	var below := tail.y > r.end.y
	var by := r.end.y - 2 if below else r.position.y + 2
	var tri := PackedVector2Array([Vector2(cx - 14, by), Vector2(cx + 14, by), tail])
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 18, 10, Vector2(3, 8)), r)
	fill(ci, PackedVector2Array([tri[0] + Vector2(3, 5), tri[1] + Vector2(3, 5), tri[2] + Vector2(3, 5)]), TtPal.SHADOW_SOFT)
	ci.draw_style_box(TtPal.sb_thick(col, 18, 5, TtPal.PAPER_EDGE), r)
	fill(ci, tri, col)


# ================================================================ HUD-pil met icoon
## Donkere pil met icoon links en tekst (bv. sterren, stappen). icon: "star", "drop", "bee", "leaf".
static func pill(ci: CanvasItem, r: Rect2, icon: String, text: String, t := 0.0, col := TtPal.PANEL_LO) -> void:
	ci.draw_style_box(TtPal.sb(col, int(r.size.y / 2)), r)
	var ic := Vector2(r.position.x + r.size.y * 0.55, r.get_center().y)
	var ir := r.size.y * 0.34
	match icon:
		"star":
			star(ci, ic + Vector2(0, 1), ir * 1.15, TtPal.STAR_DARK)
			star(ci, ic, ir * 1.15, TtPal.STAR)
		"drop":
			drop(ci, ic + Vector2(0, 2), ir * 0.9)
		"bee":
			bee(ci, ic + Vector2(2, 0), ir / 26.0 * 0.95, t)
		"leaf":
			leaf(ci, ic + Vector2(-ir, ir * 0.6), -0.7, ir * 2.2, TtPal.BRAND)
		"honey":
			honey_pot(ci, ic + Vector2(0, 1), ir * 0.95)
	TtPal.text_l(ci, TtPal.UI_BOLD, Vector2(ic.x + ir + 12, r.get_center().y), text, int(r.size.y * 0.5), TtPal.TEXT)


# ================================================================ Patricia: jaarring-plaatje (skip)
## Jaarring-plaatje bij een Patricia-top (GDD §3.2): doorgezaagde boomschijf met het getal `skip` (28 px) en klein
## de leespositie `pos`. Zit naast de knoppenkrans. `hi`: pulserende ring (bv. de bij leest nu deze top).
static func skip_ring(ci: CanvasItem, c: Vector2, skip: int, pos := -1, r := 26.0, t := 0.0, hi := false) -> void:
	ellipse(ci, c + Vector2(4, 6), r + 2, r + 1, TtPal.SHADOW_SOFT)
	ci.draw_circle(c, r + 3, TtPal.BARK_DARK, true, -1, true)
	ci.draw_circle(c, r, Color("#E9C98F"), true, -1, true)
	for k in 3:
		ci.draw_arc(c + Vector2(1.5 * k - 2, k - 1), r * (0.92 - k * 0.2), 0, TAU, 36, Color("#C9A266"), 1.6, true)
	ci.draw_arc(c, r * 0.97, PI * 1.05, PI * 1.55, 12, Color(1, 1, 1, 0.45), 2.5, true)
	TtPal.text_c(ci, TtPal.MONO, c + Vector2(0, -1), str(skip), int(r * 1.08), TtPal.INK)
	if hi:
		ci.draw_arc(c, r + 8, 0, TAU, 40, Color(TtPal.INFO, 0.6 + 0.4 * sin(t * 8.0)), 3.0, true)
	if pos >= 0:
		var s := "pos %d" % pos
		var w := TtPal.MONO_B.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 12
		var pr := Rect2(c.x - w / 2.0, c.y + r + 4, w, 22)
		ci.draw_style_box(TtPal.sb(Color(TtPal.PANEL_LO, 0.9), 8), pr)
		TtPal.text_c(ci, TtPal.MONO_B, pr.get_center(), s, 16, TtPal.TEXT)


# ================================================================ werkbank: linten
## Lint (zaadje / hoplint / vraag): papieren strook met één vak per letter en de index eronder.
## `cursor`: leescursor (INFO-ring + pijltje), `grey_before`: kolommen < d zijn gedimd (al gelezen / niet relevant),
## `mark`: kolom j (ring in `mark_col`), `hops`: Patricia-sprongen [[van, naar], ...] als boogjes boven het lint.
## Geeft de vakcentra terug.
static func ribbon(ci: CanvasItem, left_mid: Vector2, word: String, cell := 48.0, size := 30, cursor := -1, grey_before := -1,
		mark := -1, mark_col := TtPal.WARN, alphabet := "ACGT_", chips := true, show_idx := true, t := 0.0,
		hops: Array = [], col := TtPal.PAPER) -> PackedVector2Array:
	var n := word.length()
	var w := n * cell + 24
	var h := cell * 1.25
	var r := Rect2(left_mid.x, left_mid.y - h / 2.0, w, h)
	# zwaluwstaartjes
	for side in [-1.0, 1.0]:
		var x0: float = r.position.x if side < 0 else r.end.x
		var tail := PackedVector2Array([Vector2(x0, r.position.y + 6), Vector2(x0 + side * 22, r.position.y + 2),
			Vector2(x0 + side * 12, r.get_center().y), Vector2(x0 + side * 22, r.end.y - 2), Vector2(x0, r.end.y - 6)])
		fill(ci, tail, col.darkened(0.12))
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 10, 8, Vector2(2, 6)), r)
	ci.draw_style_box(TtPal.sb_thick(col, 10, 5, TtPal.PAPER_EDGE), r)
	var centers := PackedVector2Array()
	for i in n:
		var cx := r.position.x + 12 + cell * (i + 0.5)
		var cc := Vector2(cx, r.position.y + h * 0.40)
		centers.append(cc)
		if i > 0:
			ci.draw_line(Vector2(cx - cell / 2.0, r.position.y + 8), Vector2(cx - cell / 2.0, r.end.y - 10), Color(TtPal.PAPER_EDGE, 0.9), 1.5, true)
		var dim := grey_before >= 0 and i < grey_before
		var cw := TtPal.char_w(size)
		var chip := Rect2(cx - cw / 2.0 - size * 0.12, cc.y - size * 0.62, cw + size * 0.24, size * 1.24)
		if chips:
			var lc := TtPal.letter_color(word[i], alphabet)
			if dim:
				lc = lc.lerp(TtPal.CHIP_NEUTRAL, 0.75)
			ci.draw_style_box(TtPal.sb(lc, int(size * 0.22)), chip)
		TtPal.text_c(ci, TtPal.MONO, cc, word[i], size, Color(TtPal.INK, 0.35 if dim else 1.0))
		if show_idx:
			TtPal.text_c(ci, TtPal.MONO_B, Vector2(cx, r.end.y - 14), str(i), 18, Color(TtPal.INK_SOFT, 0.5 if dim else 1.0))
		if i == mark:
			TtPal.ring(ci, Rect2(cx - cell / 2.0 + 3, r.position.y + 4, cell - 6, h - 10), 10, mark_col, 4)
		if i == cursor:
			var pr := 0.5 + 0.5 * sin(t * 7.0)
			TtPal.ring(ci, Rect2(cx - cell / 2.0 + 2, r.position.y + 2, cell - 4, h - 6), 10, Color(TtPal.INFO, 0.7 + 0.3 * pr), 3)
			fill(ci, PackedVector2Array([Vector2(cx - 9, r.position.y - 14), Vector2(cx + 9, r.position.y - 14), Vector2(cx, r.position.y - 3)]), TtPal.INFO)
	for hp in hops:
		var a: int = hp[0]
		var b: int = hp[1]
		if a < 0 or b >= n or a >= b:
			continue
		var pa := Vector2(centers[a].x, r.position.y - 4)
		var pb := Vector2(centers[b].x, r.position.y - 4)
		var mid := (pa + pb) / 2.0 + Vector2(0, -cell * 0.5 - (b - a) * 4)
		var pts := PackedVector2Array()
		for k in 17:
			var u := k / 16.0
			pts.append(pa.lerp(mid, u).lerp(mid.lerp(pb, u), u))
		ci.draw_polyline(pts, Color(TtPal.INFO, 0.9), 3.0, true)
		fill(ci, PackedVector2Array([pb + Vector2(-6, -9), pb + Vector2(6, -9), pb + Vector2(0, 0)]), TtPal.INFO)
	return centers


## Vergelijkingslint (gewone trie, j kiezen): woord l (vrucht) boven, s (zaadje) onder. Kolommen < d grijs; `hover` toont
## gelijk (OK) of verschil (oranje); `cut` = gekozen j (knipje). Geeft de kolomcentra terug.
static func compare_ribbon(ci: CanvasItem, left_mid: Vector2, l_word: String, s_word: String, d := 0, hover := -1, cut := -1,
		cell := 48.0, size := 28, alphabet := "ACGT_", t := 0.0) -> PackedVector2Array:
	var n := maxi(l_word.length(), s_word.length())
	var w := n * cell + 70
	var h := cell * 2.3
	var r := Rect2(left_mid.x, left_mid.y - h / 2.0, w, h)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 12, 8, Vector2(2, 6)), r)
	ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, 12, 5, TtPal.PAPER_EDGE), r)
	var centers := PackedVector2Array()
	TtPal.text_c(ci, TtPal.MONO_B, Vector2(r.position.x + 24, r.position.y + h * 0.27), "l", 20, TtPal.INK_SOFT)
	TtPal.text_c(ci, TtPal.MONO_B, Vector2(r.position.x + 24, r.position.y + h * 0.62), "s", 20, TtPal.INK_SOFT)
	for i in n:
		var cx := r.position.x + 50 + cell * (i + 0.5)
		centers.append(Vector2(cx, r.get_center().y))
		var lc := l_word[i] if i < l_word.length() else ""
		var sc := s_word[i] if i < s_word.length() else ""
		var dim := i < d
		if i == hover and not dim:
			var same := lc == sc
			ci.draw_style_box(TtPal.sb(Color(TtPal.OK if same else TtPal.GREATER, 0.35), 10), Rect2(cx - cell / 2.0 + 2, r.position.y + 6, cell - 4, h - 34))
		for row in 2:
			var ch: String = lc if row == 0 else sc
			if ch == "":
				continue
			var cy := r.position.y + h * (0.27 if row == 0 else 0.62)
			var cw := TtPal.char_w(size)
			var chip := Rect2(cx - cw / 2.0 - size * 0.12, cy - size * 0.62, cw + size * 0.24, size * 1.24)
			var col := TtPal.letter_color(ch, alphabet)
			if dim:
				col = col.lerp(TtPal.CHIP_NEUTRAL, 0.8)
			ci.draw_style_box(TtPal.sb(col, int(size * 0.22)), chip)
			TtPal.text_c(ci, TtPal.MONO, Vector2(cx, cy), ch, size, Color(TtPal.INK, 0.35 if dim else 1.0))
		TtPal.text_c(ci, TtPal.MONO_B, Vector2(cx, r.end.y - 14), str(i), 18, Color(TtPal.INK_SOFT, 0.5 if dim else 1.0))
		if i == cut:
			ci.draw_line(Vector2(cx - cell / 2.0, r.position.y + 4), Vector2(cx - cell / 2.0, r.end.y - 4), TtPal.WARN, 3.0, true)
			TtPal.ring(ci, Rect2(cx - cell / 2.0 + 2, r.position.y + 4, cell - 4, h - 30), 10, TtPal.WARN, 4)
			shears(ci, Vector2(cx - cell / 2.0, r.position.y - 16), 0.5, 0.3 + 0.3 * absf(sin(t * 5.0)))
	return centers


# ================================================================ personages
## De Uil (coach): spreekt één korte zin. `talk` 0..1 opent de snavel, `blink` sluit de ogen. Optioneel baret.
static func owl(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, talk := 0.0, cap := true) -> void:
	var blink := 1.0 if fmod(t, 4.0) < 3.85 else 0.1
	var sway := sin(t * 1.4) * 0.03
	ellipse(ci, c + Vector2(4, 44) * s, 34 * s, 7 * s, TtPal.SHADOW_SOFT)
	var body := ellipse_pts(Vector2(0, 0), 34, 42, 0.0, 40)
	fill(ci, xf(body, c, s, 1.0, sway), TtPal.OWL_DARK)
	fill(ci, xf(ellipse_pts(Vector2(-1, -2), 32, 40, 0.0, 40), c, s, 1.0, sway), TtPal.OWL)
	fill(ci, xf(ellipse_pts(Vector2(0, 12), 22, 26, 0.0, 30), c, s, 1.0, sway), TtPal.OWL_BELLY)
	for k in 3:
		for j in 2:
			var bx := -8.0 + j * 16.0 - (k % 2) * 4.0
			var by := 4.0 + k * 9.0
			ci.draw_arc(xp(Vector2(bx, by), c, s, 1.0, sway), 4 * s, PI * 0.15, PI * 0.85, 6, Color(TtPal.OWL_DARK, 0.6), 1.6 * s, true)
	# vleugels
	for side in [-1.0, 1.0]:
		var wing := ellipse_pts(Vector2(side * 30, 6), 10, 26, side * 0.25, 20)
		fill(ci, xf(wing, c, s, 1.0, sway), TtPal.OWL_DARK)
	# oorpluimen
	for side in [-1.0, 1.0]:
		fill(ci, xf(PackedVector2Array([Vector2(side * 16, -34), Vector2(side * 30, -50), Vector2(side * 28, -30)]), c, s, 1.0, sway), TtPal.OWL_DARK)
	# ogen
	for side in [-1.0, 1.0]:
		var e := xp(Vector2(side * 13, -16), c, s, 1.0, sway)
		ci.draw_circle(e, 13 * s, TtPal.OWL_BELLY, true, -1, true)
		ci.draw_circle(e, 10 * s, TtPal.SAP, true, -1, true)
		if blink > 0.5:
			ci.draw_circle(e, 6 * s, TtPal.BEE_STRIPE, true, -1, true)
			ci.draw_circle(e + Vector2(-2, -2.5) * s, 2 * s, Color.WHITE, true, -1, true)
		else:
			ci.draw_line(e + Vector2(-9, 0) * s, e + Vector2(9, 0) * s, TtPal.OWL_DARK, 3 * s, true)
	# snavel
	var open := talk * 5.0
	fill(ci, xf(PackedVector2Array([Vector2(-5, -6), Vector2(5, -6), Vector2(0, 4)]), c, s, 1.0, sway), TtPal.SAP_DARK)
	if open > 0.5:
		fill(ci, xf(PackedVector2Array([Vector2(-4, -1 + open * 0.3), Vector2(4, -1 + open * 0.3), Vector2(0, 4 + open)]), c, s, 1.0, sway), TtPal.SAP)
	# pootjes
	for side in [-1.0, 1.0]:
		ci.draw_line(xp(Vector2(side * 9, 40), c, s), xp(Vector2(side * 9, 46), c, s), TtPal.SAP_DARK, 3 * s, true)
	if cap:
		var top := xp(Vector2(0, -44), c, s, 1.0, sway)
		fill(ci, xf(PackedVector2Array([Vector2(-26, -44), Vector2(0, -54), Vector2(26, -44), Vector2(0, -34)]), c, s, 1.0, sway), TtPal.INK)
		ci.draw_style_box(TtPal.sb(TtPal.INK, int(3 * s)), Rect2(top + Vector2(-12, 0) * s, Vector2(24, 8) * s))
		ci.draw_line(top, top + Vector2(18, 10) * s + Vector2(sin(t * 2.0) * 2, 0), TtPal.STAR, 2 * s, true)
		ci.draw_circle(top + Vector2(18, 12) * s, 3 * s, TtPal.STAR, true, -1, true)


## Bijenkorf (stro) met vliegopening; optioneel de koningin ernaast (kroontje, `frown` = verkeerde honing).
static func hive(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, queen := true, frown := false, pulse := 0.0) -> void:
	var k := 1.0 + pulse * 0.08
	ellipse(ci, c + Vector2(6, 4) * s, 70 * s, 12 * s, TtPal.SHADOW_SOFT)
	ci.draw_style_box(TtPal.sb(TtPal.BARK_DARK, int(4 * s)), Rect2(c + Vector2(-64, -10) * s, Vector2(128, 14) * s))
	var rows := 5
	for i in rows:
		var y := -18.0 - i * 20.0
		var hw := 58.0 * sqrt(1.0 - pow(float(i) / rows, 1.6)) * k
		var rr := Rect2(c + Vector2(-hw, y - 12) * s, Vector2(hw * 2, 24) * s)
		ci.draw_style_box(TtPal.sb_thick(TtPal.STRAW, int(12 * s), int(5 * s), TtPal.STRAW_DARK), rr)
		for j in 4:
			var x := -hw + (j + 0.5 + (i % 2) * 0.5) * hw * 2 / 4.5
			ci.draw_line(c + Vector2(x, y - 8) * s, c + Vector2(x + 3, y + 6) * s, Color(TtPal.STRAW_DARK, 0.5), 1.5 * s, true)
	ci.draw_circle(c + Vector2(0, -14) * s, 11 * s, TtPal.BEE_STRIPE, true, -1, true)
	ci.draw_circle(c + Vector2(0, -16) * s, 8 * s, Color("#120D0A"), true, -1, true)
	if queen:
		var q := c + Vector2(92, -40) * s
		bee(ci, q, 1.05 * s, t + 0.7, -1.0, 3 if frown else 0)
		var crown := PackedVector2Array([Vector2(-11, 0), Vector2(-11, -12), Vector2(-5, -5), Vector2(0, -15), Vector2(5, -5), Vector2(11, -12), Vector2(11, 0)])
		var cp := q + Vector2(-4, -34) * s + Vector2(0, sin(t * 7.0) * 3.0 * s)
		fill(ci, xf(crown, cp, s), TtPal.STAR)
		ci.draw_polyline(xf(crown, cp, s), TtPal.STAR_DARK, 1.5 * s, true)
		ci.draw_circle(cp + Vector2(0, -15) * s, 2.5 * s, TtPal.BLUSH, true, -1, true)


## Honingpotje (HUD-icoon / score).
static func honey_pot(ci: CanvasItem, c: Vector2, r: float) -> void:
	var body := ellipse_pts(c + Vector2(0, r * 0.15), r, r * 0.92, 0.0, 30)
	fill(ci, body, TtPal.HONEY_DARK)
	fill(ci, ellipse_pts(c + Vector2(-r * 0.05, r * 0.08), r * 0.9, r * 0.84, 0.0, 30), TtPal.HONEY)
	ci.draw_style_box(TtPal.sb(TtPal.PAPER, int(r * 0.2)), Rect2(c + Vector2(-r * 0.75, -r * 0.95), Vector2(r * 1.5, r * 0.42)))
	ci.draw_line(c + Vector2(-r * 0.7, -r * 0.55), c + Vector2(r * 0.7, -r * 0.55), TtPal.BARK, maxf(1.5, r * 0.1), true)
	fill(ci, PackedVector2Array([c + Vector2(r * 0.2, -r * 0.55), c + Vector2(r * 0.42, -r * 0.55), c + Vector2(r * 0.32, -r * 0.05)]), TtPal.HONEY)
	ellipse(ci, c + Vector2(-r * 0.45, -r * 0.05), r * 0.12, r * 0.25, Color(1, 1, 1, 0.5), 0.3)


## Vuurvliegje (Ukkonen-wijzer p̄ met badge x̄).
static func firefly(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, badge := -1, facing := 1.0) -> void:
	var glow := 0.65 + 0.35 * sin(t * 4.0)
	var tail := xp(Vector2(-12, 3), c, s, facing)
	for k in 4:
		ci.draw_circle(tail, (30 - k * 7) * s, Color(TtPal.FIREFLY, (0.06 + k * 0.06) * glow), true, -1, true)
	ci.draw_circle(tail, 7 * s, TtPal.FIREFLY, true, -1, true)
	var flap := 0.5 + 0.5 * absf(sin(t * 30.0))
	for k in 2:
		fill(ci, xf(ellipse_pts(Vector2(-2 + k * 6, -9), 9, 5 * flap, -0.4 + k * 0.3, 16), c, s, facing), Color(1, 1, 1, 0.5))
	fill(ci, xf(ellipse_pts(Vector2(0, 0), 13, 8, 0.0, 20), c, s, facing), Color("#3D3A55"))
	ci.draw_circle(xp(Vector2(11, -2), c, s, facing), 5.5 * s, Color("#3D3A55"), true, -1, true)
	ci.draw_circle(xp(Vector2(13, -3), c, s, facing), 2.2 * s, Color.WHITE, true, -1, true)
	ci.draw_line(xp(Vector2(13, -6), c, s, facing), xp(Vector2(20, -14), c, s, facing), Color("#3D3A55"), 1.6 * s, true)
	if badge >= 0:
		var bs := str(badge)
		var w := TtPal.MONO.get_string_size(bs, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 16
		var br := Rect2(c.x + 14 * s, c.y - 34 * s, w, 28)
		ci.draw_style_box(TtPal.sb(TtPal.PANEL, 12, 4, Vector2(1, 3)), br)
		TtPal.ring(ci, br, 12, TtPal.FIREFLY, 2)
		TtPal.text_c(ci, TtPal.MONO, br.get_center(), bs, 20, TtPal.FIREFLY)


## Speurhond van inspecteur Egel. mood: 0 snuffelt, 1 kwispelt (goed), 2 blaft (fout spoor).
static func dog(ci: CanvasItem, c: Vector2, s := 1.0, t := 0.0, facing := 1.0, mood := 0) -> void:
	var wag := sin(t * (18.0 if mood == 1 else 3.0)) * (0.5 if mood == 1 else 0.15)
	var sniff := sin(t * 9.0) * 1.5 if mood == 0 else 0.0
	ellipse(ci, c + Vector2(4, 2) * s, 46 * s, 7 * s, TtPal.SHADOW_SOFT)
	# staart
	var tb := xp(Vector2(-34, -30), c, s, facing)
	var tt := xp(Vector2(-34 - 18 * cos(wag + 0.9), -30 - 18 * sin(wag + 0.9)), c, s, facing)
	ci.draw_line(tb, tt, TtPal.DOG, 6 * s, true)
	ci.draw_circle(tt, 4 * s, TtPal.PAPER, true, -1, true)
	# poten
	for fx in [-24.0, -12.0, 14.0, 26.0]:
		ci.draw_line(xp(Vector2(fx, -14), c, s, facing), xp(Vector2(fx, -1), c, s, facing), TtPal.DOG_DARK, 7 * s, true)
	fill(ci, xf(ellipse_pts(Vector2(0, -26), 38, 16, 0.0, 28), c, s, facing), TtPal.DOG)
	fill(ci, xf(ellipse_pts(Vector2(-6, -32), 14, 9, 0.0, 20), c, s, facing), TtPal.PAPER)
	# kop
	var head := Vector2(36, -42 + sniff)
	fill(ci, xf(ellipse_pts(head, 15, 14, 0.0, 24), c, s, facing), TtPal.DOG)
	fill(ci, xf(ellipse_pts(head + Vector2(14, 6), 12, 8, 0.2, 20), c, s, facing), TtPal.PAPER)
	ci.draw_circle(xp(head + Vector2(25, 4), c, s, facing), 4.5 * s, TtPal.BEE_STRIPE, true, -1, true)
	fill(ci, xf(ellipse_pts(head + Vector2(-6, 6), 7, 15, 0.3, 18), c, s, facing), TtPal.DOG_DARK)
	ci.draw_circle(xp(head + Vector2(6, -4), c, s, facing), 3.2 * s, TtPal.BEE_STRIPE, true, -1, true)
	if mood == 2:
		TtPal.text_outline_c(ci, TtPal.UI_BOLD, xp(head + Vector2(30, -26), c, s, facing), "waf!", int(22 * s), TtPal.TEXT, 6)


# ================================================================ inspecteur & verdachten
## Stempel (bv. "OPGELOST") schuin over een kaart. Groen = goed (nooit rood).
static func stamp(ci: CanvasItem, c: Vector2, text := "OPGELOST", size := 34, rot := -0.18, a := 1.0) -> void:
	var col := Color(TtPal.STAMP, 0.9 * a)
	var w := TtPal.UI_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size
	var h := size * 1.6
	ci.draw_set_transform(c, rot, Vector2.ONE)
	TtPal.ring(ci, Rect2(-w / 2.0, -h / 2.0, w, h), int(size * 0.3), col, 4)
	TtPal.ring(ci, Rect2(-w / 2.0 + 6, -h / 2.0 + 6, w - 12, h - 12), int(size * 0.2), col, 2)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2.ZERO, text, size, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Vormpje van verdachte i (kleur + vorm: cirkel, driehoek, vierkant, ruit).
static func suspect_mark(ci: CanvasItem, c: Vector2, i: int, r := 10.0) -> void:
	var so: Dictionary = TtPal.SUSPECTS[i % TtPal.SUSPECTS.size()]
	var col: Color = so.col
	var pts := PackedVector2Array()
	match so.shape:
		"triangle":
			pts = PackedVector2Array([c + Vector2(0, -r * 1.1), c + Vector2(r * 1.05, r * 0.8), c + Vector2(-r * 1.05, r * 0.8)])
		"square":
			pts = PackedVector2Array([c + Vector2(-r, -r) * 0.9, c + Vector2(r, -r) * 0.9, c + Vector2(r, r) * 0.9, c + Vector2(-r, r) * 0.9])
		"diamond":
			pts = PackedVector2Array([c + Vector2(0, -r * 1.15), c + Vector2(r * 1.0, 0), c + Vector2(0, r * 1.15), c + Vector2(-r * 1.0, 0)])
		_:
			pts = ellipse_pts(c, r, r, 0.0, 24)
	var outline := PackedVector2Array()
	for p in pts:
		outline.append(c + (p - c) * 1.3)
	fill(ci, outline, TtPal.PAPER)
	fill(ci, pts, col)


## Telbadge per top (Oef. 29: aantal bladeren onder het punt).
static func count_badge(ci: CanvasItem, c: Vector2, n: int, col := TtPal.PANEL) -> void:
	var s := str(n)
	var w := maxf(30.0, TtPal.MONO.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 14)
	var r := Rect2(c.x - w / 2.0, c.y - 15, w, 30)
	ci.draw_style_box(TtPal.sb(col, 15, 4, Vector2(1, 3)), r)
	TtPal.ring(ci, r, 15, Color(1, 1, 1, 0.35), 2)
	TtPal.text_c(ci, TtPal.MONO, r.get_center(), s, 18, TtPal.TEXT)


## Letterparels op een boog (suffixboom met strings aan de bogen, winter 4-1): kleine kralen langs de tak.
static func edge_pearls(ci: CanvasItem, pts: PackedVector2Array, text: String, f0 := 0.2, f1 := 0.8, alphabet := "acgt_") -> void:
	var n := text.length()
	for i in n:
		var f := lerpf(f0, f1, (i + 0.5) / n) if n > 1 else (f0 + f1) / 2.0
		var p := path_point(pts, f)
		ci.draw_circle(p + Vector2(1, 2), 13, TtPal.SHADOW_SOFT, true, -1, true)
		ci.draw_circle(p, 13, TtPal.letter_color(text[i], alphabet).darkened(0.2), true, -1, true)
		ci.draw_circle(p, 10.5, TtPal.PAPER, true, -1, true)
		TtPal.text_c(ci, TtPal.MONO, p + Vector2(0, -1), text[i], 18, TtPal.INK)


# ================================================================ seizoenkaart, sterren, windrij
## Plantpot = level op de seizoenkaart. stars 0..3, `locked` grijs met slotje, `label` bv. "1-2".
static func pot(ci: CanvasItem, c: Vector2, label: String, stars: int, se: Dictionary, locked := false, t := 0.0, hi := false) -> void:
	var tc := TtPal.TERRACOTTA if not locked else Color("#8E8A84")
	var th := TtPal.TERRACOTTA_HI if not locked else Color("#A6A29B")
	ellipse(ci, c + Vector2(5, 44), 42, 9, TtPal.SHADOW_SOFT)
	if hi:
		ci.draw_circle(c, 64 + 3 * sin(t * 4.0), Color(TtPal.INFO, 0.25), true, -1, true)
	if not locked:
		var lc: Array = se.get("leaf", [TtPal.BRAND])
		ci.draw_line(c + Vector2(0, -14), c + Vector2(0, -44), TtPal.BRAND_DARK, 4.0, true)
		leaf(ci, c + Vector2(0, -30), -PI * 0.2 + sin(t * 1.5) * 0.08, 24, lc[0])
		leaf(ci, c + Vector2(0, -24), -PI * 0.85 - sin(t * 1.5) * 0.08, 20, lc[1 % lc.size()])
		if stars >= 3:
			star_flower(ci, c + Vector2(0, -52), 13, 1.0, t)
	var body := PackedVector2Array([c + Vector2(-34, -10), c + Vector2(34, -10), c + Vector2(26, 40), c + Vector2(-26, 40)])
	fill(ci, body, tc)
	ci.draw_style_box(TtPal.sb_thick(th, 8, 5, tc.darkened(0.2)), Rect2(c + Vector2(-42, -22), Vector2(84, 20)))
	TtPal.text_c(ci, TtPal.UI_BOLD, c + Vector2(0, 16), label, 24, TtPal.PAPER if not locked else Color(TtPal.PAPER, 0.8))
	for i in 3:
		var sc := c + Vector2(-26 + i * 26, 62)
		star_slot(ci, sc, 10, i < stars)
	if locked:
		var lk := c + Vector2(30, -30)
		ci.draw_arc(lk + Vector2(0, -6), 7, PI, TAU, 12, TtPal.PANEL_LO, 3.0, true)
		ci.draw_style_box(TtPal.sb(TtPal.PANEL_LO, 4), Rect2(lk + Vector2(-10, -6), Vector2(20, 16)))


## Ster als bloem (rapport, GDD #36): `open` 0..1 (knop -> bloem met overshoot in de tween).
static func star_flower(ci: CanvasItem, c: Vector2, r: float, open := 1.0, t := 0.0) -> void:
	ci.draw_line(c + Vector2(0, r * 0.6), c + Vector2(0, r * 1.8), TtPal.BRAND_DARK, maxf(2.0, r * 0.14), true)
	leaf(ci, c + Vector2(0, r * 1.4), -PI * 0.15, r * 0.9, TtPal.BRAND)
	var rr := r * maxf(0.15, open)
	star(ci, c + Vector2(0, rr * 0.08), rr, TtPal.STAR_DARK, sin(t * 2.0) * 0.05)
	star(ci, c, rr, TtPal.STAR, sin(t * 2.0) * 0.05)
	ci.draw_circle(c, rr * 0.28, TtPal.SAP, true, -1, true)


## Kaartje in de windrij: kind = "seed", "bee", "wasp" (als bij getekend!), "shears", "convert", "loupe", "pearl".
static func card(ci: CanvasItem, c: Vector2, kind: String, word := "", t := 0.0, active := false, se: Dictionary = {}) -> Rect2:
	var sz := Vector2(128, 96) * (1.15 if active else 1.0)
	var r := Rect2(c - sz / 2.0, sz)
	ci.draw_style_box(TtPal.sb(Color(0, 0, 0, 0), 14, 6, Vector2(2, 5)), r)
	ci.draw_style_box(TtPal.sb_thick(TtPal.PAPER, 14, 5, TtPal.PAPER_EDGE), r)
	if active:
		TtPal.ring(ci, r.grow(4), 18, Color(TtPal.INFO, 0.7 + 0.3 * sin(t * 5.0)), 3)
	var ic := Vector2(c.x, r.position.y + sz.y * 0.36)
	match kind:
		"seed":
			sprout(ci, ic + Vector2(0, 14), 1.6, TtPal.BRAND_DARK)
		"bee", "wasp":
			bee(ci, ic, 0.62, t, 1.0, 0)
		"shears":
			shears(ci, ic + Vector2(0, 4), 0.55, 0.5)
		"convert":
			tendril(ci, ic + Vector2(-20, 12), ic + Vector2(20, -10), TtPal.TENDRIL, t, 3.0)
		"loupe":
			magnifier(ci, ic + Vector2(-4, -4), 13)
		"pearl":
			ci.draw_circle(ic, 14, TtPal.ROPE, true, -1, true)
			ci.draw_circle(ic, 11, TtPal.PAPER, true, -1, true)
	if word != "":
		var ls := TtPal.fit_word(word.length(), sz.x - 16, 20, 16)
		TtPal.word(ci, Vector2(c.x, r.position.y + sz.y * 0.76), word, ls, true, "ACGT_" if word == word.to_upper() else "acgt_")
	return r


## Composthoop (afgeknipte takken landen hier, sap stroomt terug).
static func compost(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	ellipse(ci, c + Vector2(4, 4) * s, 70 * s, 12 * s, TtPal.SHADOW_SOFT)
	fill(ci, ellipse_pts(c + Vector2(0, -12) * s, 64 * s, 26 * s, 0.0, 30), Color("#6B4A2E"))
	fill(ci, ellipse_pts(c + Vector2(-6, -18) * s, 48 * s, 18 * s, 0.0, 30), Color("#7E5A38"))
	for k in 5:
		var a := c + Vector2(-40 + k * 18, -22 - (k % 2) * 8) * s
		ci.draw_line(a, a + Vector2(18, -6 + k % 3 * 4) * s, TtPal.BARK, 4 * s, true)
	leaf(ci, c + Vector2(10, -30) * s, -0.5, 16 * s, Color("#A08A62"))
	leaf(ci, c + Vector2(-20, -26) * s, -2.4, 14 * s, Color("#8E7A52"))
