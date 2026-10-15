class_name TxDraw
extends Object
## TELEX — tekenfuncties voor alle elementen uit de GDD (design/ART.md §5–6). Statisch, roep ze aan vanuit `_draw()`:
##   TxDraw.tape(self, x0, TxPal.Y_TAPE, "barbaarse_barbecue", 0, 30, TxPal.TAPE_CELL, {"states": {...}})
## Elke functie neemt een CanvasItem `ci` en tekent op absolute coördinaten. Animatie = parameters (0..1, hoeken)
## die de front-end tweent. Geen state, geen nodes.

const P := preload("res://games/telex/scripts/game/tx_pal.gd")

## inktkleuren voor markeringen OP PAPIER (donkerder dan de lampkleuren, contrast ≥ 3:1 op PAPER)
const EQ_INK := Color("#13875C")
const NE_INK := Color("#C8361A")


# ================================================================ LINT
## Het telexlint t[first .. first+count−1] vanaf x0 (kolom = cell px). opts:
##  "states": {pos: "eq"/"ne"}   gelezen-gelijk (groene onderstreep) / mismatch (rode zigzag)
##  "front": int                 posities ≥ front zijn nog niet binnen (blanco papier, LIVE)
##  "shred": int                 posities < shred zijn vernietigd (gescheurde linkerrand)
##  "hits": [[a, b], ...]        gemelde voorkomens (blauwe stempelband over t[a..b])
##  "missed": [[a, b], ...]      gemist (rode gloed)
##  "false": [[a, b], ...]       vals alarm (grijze band)
##  "key": int                   sleutelteken (Springer): cirkel rond t[key]
##  "spot": [a, b]               zoeklicht beschijnt t[a..b]
##  "size": int                  fontgrootte (44 of 32)
##  "glow": float                globale gloed bij treffer-golf (0..1)
static func tape(ci: CanvasItem, x0: float, y: float, t: String, first: int, count: int, cell: float, opts := {}) -> void:
	var states: Dictionary = opts.get("states", {})
	var front: int = opts.get("front", t.length())
	var shred: int = opts.get("shred", -1)
	var fsize: int = opts.get("size", 44 if cell >= 40.0 else 32)
	var h := P.TAPE_H
	var a := maxi(first, shred if shred >= 0 else first)
	var xs := x0 + (a - first) * cell
	var xe := x0 + count * cell
	if xe <= xs:
		return
	# schaduw + papier
	ci.draw_rect(Rect2(xs + 2, y + 8, xe - xs, h), Color(0, 0, 0, 0.35))
	var body := Rect2(xs, y, xe - xs, h)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), body, true, Color(1.15, 1.09, 0.95))
	ci.draw_rect(Rect2(xs, y, xe - xs, 2), P.PAPER_HI)
	ci.draw_rect(Rect2(xs, y + h - 7, xe - xs, 7), Color(P.PAPER_EDGE, 0.35))
	ci.draw_rect(Rect2(xs, y + h - 1.5, xe - xs, 1.5), P.PAPER_EDGE)
	# nog niet binnengekomen stuk: blanco, iets koeler
	if front < first + count:
		var fx := x0 + (maxi(front, a) - first) * cell
		ci.draw_rect(Rect2(fx, y, xe - fx, h), Color(P.PAPER_SHADE, 0.35))
	# banden (achter de tekens)
	for hb in opts.get("hits", []):
		_band(ci, x0, y, first, cell, hb, Color(P.STAMP_BLUE, 0.20), P.STAMP_BLUE)
	for hb in opts.get("false", []):
		_band(ci, x0, y, first, cell, hb, Color(P.SIG_GREY, 0.28), P.SIG_GREY.darkened(0.3))
	for hb in opts.get("missed", []):
		var r := Rect2(x0 + (hb[0] - first) * cell, y, (hb[1] - hb[0] + 1) * cell, h)
		ci.draw_rect(r, Color(P.SIG_NE, 0.30))
		P.glow(ci, r.get_center(), r.size.x * 1.6, P.SIG_NE, 0.35)
	if opts.has("spot"):
		var sp: Array = opts["spot"]
		var r := Rect2(x0 + (sp[0] - first) * cell, y - 4, (sp[1] - sp[0] + 1) * cell, h + 8)
		P.glow(ci, r.get_center(), r.size.x * 1.5, Color(1.0, 0.92, 0.6), 0.55)
		ci.draw_rect(r, Color(1.0, 0.93, 0.6, 0.45))
		ci.draw_rect(r, Color(1.0, 0.85, 0.4, 0.9), false, 2.0)
	# per kolom: ITA2-gaten, toestand, teken
	for p in range(a, first + count):
		if p >= t.length():
			break
		var cx := x0 + (p - first + 0.5) * cell
		var arrived := p < front
		if arrived:
			_code_holes(ci, cx, y + 5, t[p], cell)
		var st: String = states.get(p, "")
		if st == "eq":
			ci.draw_rect(Rect2(cx - cell / 2 + 1, y + 34, cell - 2, h - 40), Color(P.SIG_EQ, 0.13))
			ci.draw_rect(Rect2(cx - cell * 0.38, y + h - 13, cell * 0.76, 5), EQ_INK)
		elif st == "ne":
			ci.draw_rect(Rect2(cx - cell / 2 + 1, y + 34, cell - 2, h - 40), Color(P.SIG_NE, 0.16))
			_zigzag(ci, cx - cell * 0.38, cx + cell * 0.38, y + h - 11, NE_INK)
		if arrived:
			if t[p] == "⏎":
				eol(ci, Vector2(cx, y + 67), fsize * 0.8)
			else:
				_glyph(ci, Vector2(cx, y + 67), t[p], fsize)
	if opts.has("frame"):
		var fr: Array = opts["frame"]
		var r := Rect2(x0 + (fr[0] - first) * cell + 1, y - 6, (fr[1] - fr[0] + 1) * cell - 2, h + 12)
		ci.draw_rect(r, P.BRASS, false, 3.0)
		for cx2 in [r.position.x, r.end.x]:
			ci.draw_rect(Rect2(cx2 - 4, y - 10, 8, 8), P.BRASS)
			ci.draw_rect(Rect2(cx2 - 4, y + h + 2, 8, 8), P.BRASS)
	if opts.has("key"):
		var kx := x0 + (int(opts["key"]) - first + 0.5) * cell
		ci.draw_arc(Vector2(kx, y + 67), cell * 0.55, 0, TAU, 40, P.SIG_AMBER, 3.0, true)
		ci.draw_arc(Vector2(kx, y + 67), cell * 0.55 + 4, 0, TAU, 40, Color(P.SIG_AMBER, 0.3), 3.0, true)
	if shred >= first and shred < first + count:
		_torn_edge(ci, xs, y, h, true)
	if float(opts.get("glow", 0.0)) > 0.0:
		ci.draw_rect(body, Color(P.SIG_EQ, 0.15 * float(opts["glow"])))


## Het end_of_line-teken ⏎ (Algoritme 5, spiegelrit): messing pijltje.
static func eol(ci: CanvasItem, c: Vector2, size := 30.0, col := P.BRASS_LO) -> void:
	var k := size / 30.0
	ci.draw_polyline(_sc(c, k, [Vector2(10, -12), Vector2(10, 4), Vector2(-8, 4)]), col, 3.5 * k, true)
	ci.draw_colored_polygon(_sc(c, k, [Vector2(-14, 4), Vector2(-6, -4), Vector2(-6, 12)]), col)


## Eén teken in typemachine-inkt (met lichte inktuitloop). `_` blijft zichtbaar (spatie in de notas).
static func _glyph(ci: CanvasItem, c: Vector2, ch: String, size: int, col := P.INK) -> void:
	P.text_c(ci, P.TAPE, c + Vector2(0.7, 0.6), ch, size, Color(col, 0.22))
	P.text_c(ci, P.TAPE, c, ch, size, col)


static func _code_holes(ci: CanvasItem, cx: float, y: float, ch: String, cell: float) -> void:
	var code := P.ita2(ch)
	var pitch := 4.9
	var r := 1.9 if cell >= 40.0 else 1.5
	var row := 0
	for i in 6:
		var yy := y + i * pitch + 2
		if i == 2:
			ci.draw_circle(Vector2(cx, yy), r * 0.62, Color(P.NIGHT, 0.55), true, -1.0, true)
			continue
		var bit := code[row]
		row += 1
		if bit == "1":
			ci.draw_circle(Vector2(cx, yy), r, Color(P.NIGHT, 0.62), true, -1.0, true)
			ci.draw_arc(Vector2(cx, yy), r, 0.2, PI - 0.2, 6, Color(P.PAPER_HI, 0.8), 0.8, true)


static func _band(ci: CanvasItem, x0: float, y: float, first: int, cell: float, hb: Array, fill: Color, line: Color) -> void:
	var r := Rect2(x0 + (hb[0] - first) * cell + 2, y + 32, (hb[1] - hb[0] + 1) * cell - 4, P.TAPE_H - 38)
	ci.draw_rect(r, fill)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(line, 0.85))
	ci.draw_rect(Rect2(Vector2(r.position.x, r.end.y - 3), Vector2(r.size.x, 3)), Color(line, 0.85))


static func _zigzag(ci: CanvasItem, x0: float, x1: float, y: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 6
	for i in n + 1:
		pts.append(Vector2(lerpf(x0, x1, float(i) / n), y + (-2.5 if i % 2 == 0 else 2.5)))
	ci.draw_polyline(pts, col, 3.0, true)


static func _torn_edge(ci: CanvasItem, x: float, y: float, h: float, left: bool) -> void:
	var pts := PackedVector2Array()
	var n := 12
	var s := -1.0 if left else 1.0
	pts.append(Vector2(x + s * 14, y - 2))
	for i in n + 1:
		var yy := y + h * i / n
		var jag := 6.0 * (0.4 + 0.6 * absf(sin(i * 2.7 + x * 0.1)))
		pts.append(Vector2(x + s * (i % 2) * jag - s * 1.0, yy))
	pts.append(Vector2(x + s * 14, y + h + 2))
	# alles aan de buitenkant van de rand wordt "weggeknipt" met de consolekleur
	ci.draw_colored_polygon(pts, P.CONSOLE_LO)
	var edge := PackedVector2Array()
	for i in range(1, pts.size() - 1):
		edge.append(pts[i] + Vector2(-s * 1.5, 0))
	ci.draw_polyline(edge, P.PAPER_EDGE, 1.5, true)


## Positienummers 0..n−1 onder het lint (elke 5e helderder, met streepje).
static func tape_positions(ci: CanvasItem, x0: float, y: float, first: int, count: int, cell: float, n: int, head := -1) -> void:
	for p in range(first, mini(first + count, n)):
		var cx := x0 + (p - first + 0.5) * cell
		var major := p % 5 == 0
		var col := P.TEXT if major else P.TEXT_DIM
		if p == head:
			col = P.BRASS_HI
		P.text_c(ci, P.MONO, Vector2(cx, y + 10), str(p), 15 if p < 100 else 13, Color(col, 1.0 if major or p == head else 0.75))
		if major:
			ci.draw_line(Vector2(cx, y - 1), Vector2(cx, y + 2), P.TEXT_DIM, 1.0)


# ================================================================ LEESKOP & NAALD
## Messing leeskop boven kolom cx. strike 0..1 (naald omlaag), lit: "eq"/"ne"/"" (lampje), warm 0..1
## (gloeit warm-wit: KMP, "hij gaat niet terug"), streak 0..1 (bewegingsstreep bij terugspoelen, naar rechts).
static func head(ci: CanvasItem, cx: float, y_tape: float, strike := 0.0, lit := "", warm := 0.0, streak := 0.0) -> void:
	var top := y_tape - 38.0
	if streak > 0.0:
		for i in 4:
			var yy := top + 8 + i * 7
			ci.draw_line(Vector2(cx + 30, yy), Vector2(cx + 30 + 140 * streak * (1.0 - i * 0.18), yy), Color(P.BRASS_HI, 0.35 * streak), 3.0, true)
	# naald (staal), slaat op de kolom
	var tip := y_tape + lerpf(4.0, 30.0, strike)
	ci.draw_line(Vector2(cx, top + 26), Vector2(cx, tip), P.STEEL_LO, 4.0, true)
	ci.draw_line(Vector2(cx - 0.8, top + 26), Vector2(cx - 0.8, tip - 1), P.STEEL_HI, 1.5, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 3, tip - 4), Vector2(cx + 3, tip - 4), Vector2(cx, tip + 3)]), P.STEEL)
	if strike > 0.85:
		P.glow(ci, Vector2(cx, tip), 26, P.SIG_WHITE, 0.6)
	# behuizing: trapezium met schuine kanten
	var body := PackedVector2Array([Vector2(cx - 34, top), Vector2(cx + 34, top), Vector2(cx + 20, top + 30), Vector2(cx - 20, top + 30)])
	ci.draw_colored_polygon(PackedVector2Array([body[0] + Vector2(2, 4), body[1] + Vector2(2, 4), body[2] + Vector2(2, 4), body[3] + Vector2(2, 4)]), P.SHADOW)
	ci.draw_colored_polygon(body, P.BRASS_LO)
	ci.draw_colored_polygon(PackedVector2Array([body[0] + Vector2(2, 2), body[1] + Vector2(-2, 2), body[2] + Vector2(-1, -2), body[3] + Vector2(1, -2)]), P.BRASS)
	ci.draw_line(body[0] + Vector2(3, 3), body[1] + Vector2(-3, 3), P.BRASS_HI, 2.0, true)
	if warm > 0.0:
		ci.draw_colored_polygon(body, Color(P.SIG_WHITE, 0.45 * warm))
		P.glow(ci, Vector2(cx, top + 14), 120, P.SIG_WHITE, 0.45 * warm)
	# lampje in de kop
	var lc := P.SIG_EQ if lit == "eq" else (P.SIG_NE if lit == "ne" else P.SIG_AMBER)
	P.lamp(ci, Vector2(cx, top + 13), 7.0, lc, 1.0 if lit != "" else 0.0, "ok" if lit == "eq" else ("ne" if lit == "ne" else ""))
	P.rivet(ci, Vector2(cx - 24, top + 7), 2.5, P.BRASS)
	P.rivet(ci, Vector2(cx + 24, top + 7), 2.5, P.BRASS)


# ================================================================ SJABLOON (z) MET TANDEN
## Metalen sjabloon met z, z[0] onder kolom x0. teeth: {i: "mesh"/"clash"} (tanden aan de bovenrand),
## cur = sjabloonpositie onder de naald (−1 = geen), ghost = spookkopie (half transparant), size = fontgrootte.
static func stencil(ci: CanvasItem, x0: float, y: float, z: String, cell: float, teeth := {}, cur := -1, ghost := false, size := 44, marks := {}) -> void:
	var m := z.length()
	var w := m * cell
	var r := Rect2(x0 - 10, y, w + 20, P.STENCIL_H)
	if ghost:
		ci.draw_style_box(P.sb(Color(P.SIG_BLUE, 0.10), 9), r)
		ci.draw_style_box(P.sb(Color(0, 0, 0, 0), 9, 0, Vector2.ZERO, 2, Color(P.SIG_BLUE, 0.55)), r)
		for i in m:
			P.text_c(ci, P.TAPE, Vector2(x0 + (i + 0.5) * cell, y + 50), z[i], size, Color(P.SIG_BLUE, 0.45))
		return
	var a := 1.0
	ci.draw_style_box(P.sb(P.SHADOW, 9), Rect2(r.position + Vector2(2, 7), r.size))
	ci.draw_style_box(P.sb(P.STEEL_LO, 9), r)
	ci.draw_texture_rect(P.tex("tex/brushed.png"), r.grow(-3), true, Color(P.STEEL.r * 1.05, P.STEEL.g * 1.05, P.STEEL.b * 1.05))
	ci.draw_rect(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, 3)), Color(P.STEEL_HI, 0.7))
	ci.draw_rect(Rect2(Vector2(r.position.x + 4, r.end.y - 6), Vector2(r.size.x - 8, 3)), Color(0, 0, 0, 0.25))
	# tanden
	for i in m:
		var cx := x0 + (i + 0.5) * cell
		var st: String = teeth.get(i, "")
		var tc := P.STEEL
		if st == "mesh":
			tc = P.SIG_EQ
		elif st == "clash":
			tc = P.SIG_NE
		var tri := PackedVector2Array([Vector2(cx - 8, y + 1), Vector2(cx + 8, y + 1), Vector2(cx + 3, y - 10), Vector2(cx - 3, y - 10)])
		ci.draw_colored_polygon(tri, Color(tc.darkened(0.25), a))
		ci.draw_line(Vector2(cx - 6, y - 1), Vector2(cx - 2.5, y - 9), Color(tc.lightened(0.4), a), 1.5, true)
		if st == "mesh":
			P.glow(ci, Vector2(cx, y - 5), 30, P.SIG_EQ, 0.5)
		elif st == "clash":
			for k in 4:
				var ang := -PI / 2 + (k - 1.5) * 0.45
				var d := Vector2(cos(ang), sin(ang))
				ci.draw_line(Vector2(cx, y - 11) + d * 3, Vector2(cx, y - 11) + d * (10 + (k % 2) * 5), P.SIG_AMBER, 2.0, true)
	# cursor onder de naald
	if cur >= 0 and cur < m:
		var cr := Rect2(x0 + cur * cell + 3, y + 22, cell - 6, P.STENCIL_H - 28)
		ci.draw_style_box(P.sb(Color(P.SIG_WHITE, 0.25 * a), 5), cr)
	# indices + letters (gegraveerd)
	for i in m:
		var cx := x0 + (i + 0.5) * cell
		P.text_c(ci, P.MONO, Vector2(cx, y + 14), str(i), 13, Color(P.STEEL_LO.darkened(0.35), a))
		var mk: String = marks.get(i, "")
		var lc := P.INK
		if mk == "eq":
			lc = EQ_INK
		elif mk == "ne":
			lc = NE_INK
		P.text_c(ci, P.TAPE, Vector2(cx, y + 50 + 1), z[i], size, Color(P.STEEL_HI, 0.8 * a))
		P.text_c(ci, P.TAPE, Vector2(cx, y + 50), z[i], size, Color(lc, a))
	P.rivet(ci, Vector2(r.position.x + 7, r.get_center().y), 3.0)
	P.rivet(ci, Vector2(r.end.x - 7, r.get_center().y), 3.0)


# ================================================================ PONSSTROOK (V[])
## Ponsstrook onder het sjabloon: vakje j onder sjabloonpositie j. values[j] = int (geponst) / null (leeg) /
## "burnt" (verbrand, 3-5). extra = toon vakje "m" (ALL-levels). hl = vakje dat oplicht (−1 = geen).
static func strip(ci: CanvasItem, x0: float, y: float, values: Array, cell: float, extra := false, hl := -1, label := "V") -> void:
	var m := values.size() - (1 if extra else 0)
	var w := m * cell
	var h := P.STRIP_H
	var r := Rect2(x0 - 4, y, w + 8, h)
	ci.draw_rect(Rect2(r.position + Vector2(2, 5), r.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(P.MANILA.r * 1.18, P.MANILA.g * 1.18, P.MANILA.b * 1.18))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.35))
	var tag := Rect2(x0 - 46, y + 6, 36, h - 12)
	ci.draw_style_box(P.sb(P.BRASS, 4), tag)
	P.engraved(ci, P.STENCIL, tag.get_center(), label, 22, P.BRASS)
	for j in values.size():
		var xx := x0 + j * cell
		if extra and j == values.size() - 1:
			xx += 18
			var er := Rect2(xx - 4, y, cell + 8, h)
			ci.draw_rect(Rect2(er.position + Vector2(2, 5), er.size), P.SHADOW)
			ci.draw_texture_rect(P.tex("tex/paper_tile.png"), er, true, Color(P.MANILA.r * 1.12, P.MANILA.g * 1.1, P.MANILA.b * 1.05))
			P.text_c(ci, P.MONO, Vector2(xx + cell / 2, y - 9), "m", 13, P.TEXT_DIM)
		var c := Vector2(xx + cell / 2, y + h / 2)
		if j > 0 and not (extra and j == values.size() - 1):
			ci.draw_dashed_line(Vector2(xx, y + 5), Vector2(xx, y + h - 5), Color(P.MANILA_LO, 0.9), 1.0, 3.0)
		var v = values[j]
		if v is String and v == "burnt":
			var br := Rect2(xx + 2, y + 2, cell - 4, h - 4)
			ci.draw_rect(br, Color("#1A1411"))
			ci.draw_rect(br.grow(1), Color("#5A3A22", 0.6), false, 2.0)
			for k in 3:
				ci.draw_circle(c + Vector2(-8 + k * 8, 6 - (k % 2) * 10), 1.6, Color(P.HEAT, 0.8), true, -1.0, true)
		elif v == null:
			for k in 10:
				var a0 := TAU * k / 10.0
				ci.draw_arc(c, 9, a0, a0 + TAU / 20.0, 4, Color(P.MANILA_LO.darkened(0.2), 0.95), 1.6, true)
		else:
			ci.draw_circle(Vector2(c.x, y + 7), 3.0, Color(P.NIGHT, 0.75), true, -1.0, true)
			P.text_c(ci, P.TAPE, c + Vector2(0, 4), str(v), 28, P.INK)
		if j == hl:
			ci.draw_style_box(P.sb(Color(0, 0, 0, 0), 6, 0, Vector2.ZERO, 3, P.SIG_AMBER), Rect2(xx + 1, y - 1, cell - 2, h + 2))
			P.glow(ci, c, cell * 2.2, P.SIG_AMBER, 0.35)


# ================================================================ VERSNIPPERAAR, INLAAT, LUSBAK
## Versnipperaar links van het lint (x1 = rechterrand van de behuizing). spin = hoek van de messen,
## red 0..1 = gemist-gloed, fill 0..1 = snippers in de bak.
static func shredder(ci: CanvasItem, x1: float, y_tape: float, spin := 0.0, red := 0.0, fill := 0.4) -> void:
	var r := Rect2(x1 - 128, y_tape - 26, 128, P.TAPE_H + 52)
	P.panel(ci, r, P.CONSOLE_HI, false, 8)
	# mond (sleuf)
	var mouth := Rect2(r.end.x - 26, y_tape + 6, 26, P.TAPE_H - 12)
	ci.draw_rect(mouth, P.NIGHT)
	if red > 0.0:
		ci.draw_rect(mouth, Color(P.SIG_NE, 0.55 * red))
		P.glow(ci, mouth.get_center(), 160, P.SIG_NE, 0.55 * red)
	# twee messenrollen (zij-aanzicht), draaiend
	for k in 2:
		var c := Vector2(r.end.x - 46, y_tape + 26 + k * 54)
		ci.draw_circle(c, 21, P.STEEL_LO.darkened(0.3), true, -1.0, true)
		for i in 10:
			var ang := spin * (1 if k == 0 else -1) + TAU * i / 10.0
			var d := Vector2(cos(ang), sin(ang))
			var dn := Vector2(cos(ang + 0.28), sin(ang + 0.28))
			ci.draw_colored_polygon(PackedVector2Array([c + d * 12, c + d * 23, c + dn * 14]), P.STEEL)
		ci.draw_circle(c, 12, P.STEEL, true, -1.0, true)
		ci.draw_circle(c, 4, P.STEEL_LO, true, -1.0, true)
	# bak met snippers onder de behuizing
	var bin := Rect2(r.position.x + 8, r.end.y + 6, r.size.x - 16, 52)
	ci.draw_style_box(P.sb(Color(P.NIGHT, 0.9), 4), bin)
	for k in 6:
		ci.draw_line(Vector2(bin.position.x + 8 + k * 20, bin.position.y + 2), Vector2(bin.position.x + 8 + k * 20, bin.end.y - 2), Color(P.STEEL_LO, 0.35), 1.0)
	var n := int(46 * fill)
	for i in n:
		var px := bin.position.x + 8 + fmod(i * 37.3, bin.size.x - 16)
		var py := bin.end.y - 6 - fmod(i * 13.7, 40.0 * fill + 4.0)
		var ang := fmod(i * 1.37, PI)
		var d := Vector2(cos(ang), sin(ang)) * 6
		var col := P.PAPER.darkened(0.15 * (i % 3))
		if red > 0.0 and i % 3 == 0:
			col = col.lerp(P.SIG_NE, 0.6 * red)
		ci.draw_line(Vector2(px, py) - d, Vector2(px, py) + d, col, 3.0)
	ci.draw_rect(bin, Color(P.STEEL_LO, 0.9), false, 2.0)
	ci.draw_rect(Rect2(r.position.x + 14, r.position.y + 10, 70, 16), Color(0, 0, 0, 0.0))
	P.text_c(ci, P.STENCIL, Vector2(r.position.x + 50, r.position.y + 16), "SNIPPER", 14, Color(P.TEXT_DIM, 0.8))


## Inlaat rechts van het lint (x0 = linkerrand). hammer 0..1 (typehamer slaat), roll = hoek van de rol.
static func inlet(ci: CanvasItem, x0: float, y_tape: float, hammer := 0.0, roll := 0.0) -> void:
	var r := Rect2(x0, y_tape - 26, 136, P.TAPE_H + 52)
	P.panel(ci, r, P.CONSOLE_HI, false, 8)
	var slot := Rect2(r.position.x, y_tape + 4, 22, P.TAPE_H - 8)
	ci.draw_rect(slot, P.NIGHT)
	# rubberen drukrol (zij-aanzicht) met ribbels
	var c := Vector2(r.position.x + 52, y_tape + P.TAPE_H / 2)
	ci.draw_circle(c + Vector2(2, 3), 30, P.SHADOW, true, -1.0, true)
	ci.draw_circle(c, 30, P.RUBBER, true, -1.0, true)
	for i in 12:
		var ang := roll + TAU * i / 12.0
		ci.draw_line(c + Vector2(cos(ang), sin(ang)) * 22, c + Vector2(cos(ang), sin(ang)) * 29, Color(1, 1, 1, 0.08), 2.0, true)
	ci.draw_circle(c, 9, P.STEEL, true, -1.0, true)
	ci.draw_circle(c - Vector2(3, 3), 3, P.STEEL_HI, true, -1.0, true)
	# typehamer (messing arm, scharnier rechtsboven)
	var piv := Vector2(r.end.x - 26, r.position.y + 22)
	var ang := lerpf(-0.95, -0.35, hammer) + PI
	var tip := piv + Vector2(cos(ang), sin(ang)) * 74
	ci.draw_line(piv, tip, P.BRASS_LO, 7.0, true)
	ci.draw_line(piv, tip, P.BRASS, 4.0, true)
	ci.draw_rect(Rect2(tip - Vector2(7, 4), Vector2(14, 12)), P.BRASS_HI)
	ci.draw_circle(piv, 7, P.BRASS_LO, true, -1.0, true)
	P.rivet(ci, piv, 3.5, P.BRASS)
	P.text_c(ci, P.STENCIL, Vector2(r.get_center().x + 8, r.end.y - 14), "INLAAT", 14, Color(P.TEXT_DIM, 0.8))


## Lusbak (LIVE): glazen bak waarin het slappe lint hangt + meter met B vakjes. fill = gevulde vakjes,
## warn 0..1 = amber knipperen (< 1,5 s tot scheur).
static func loop_bin(ci: CanvasItem, r: Rect2, B: int, fill: float, warn := 0.0) -> void:
	P.panel(ci, r, P.CONSOLE, false, 8)
	P.text_l(ci, P.STENCIL, r.position + Vector2(14, 18), "LUSBAK", 16, P.TEXT_DIM)
	# meter
	var mw := minf(22.0, (r.size.x - 120) / maxf(B, 1))
	for i in B:
		var cr := Rect2(r.position.x + 100 + i * (mw + 3), r.position.y + 8, mw, 20)
		var on := float(i) < fill
		var col := P.SIG_AMBER if (warn > 0.0 and on) else P.SIG_EQ
		ci.draw_style_box(P.sb(P.LAMP_GLASS, 3), cr)
		if on:
			ci.draw_style_box(P.sb(col.darkened(0.1) if warn <= 0.5 else col, 3), cr.grow(-2))
	# glazen bak met hangend lint (U-lus)
	var g := Rect2(r.position.x + 14, r.position.y + 38, r.size.x - 28, r.size.y - 50)
	P.well(ci, g, Color(P.NIGHT, 0.85))
	var depth := clampf(fill / maxf(B, 1), 0.0, 1.0) * (g.size.y - 40) + 30
	var rad := g.size.x * 0.16
	var cxl := g.get_center().x
	var top := g.position.y + 2
	var pts := PackedVector2Array([Vector2(cxl - rad, top)])
	var bottom := top + depth
	for i in 17:
		var u := PI * float(i) / 16.0
		pts.append(Vector2(cxl - rad * cos(u), bottom - rad + rad * sin(u)))
	pts.append(Vector2(cxl + rad, top))
	ci.draw_polyline(pts, P.PAPER_SHADE, 14.0, true)
	ci.draw_polyline(pts, P.PAPER, 10.0, true)
	ci.draw_rect(Rect2(g.position + Vector2(2, 2), Vector2(g.size.x - 4, 6)), Color(1, 1, 1, 0.06))
	if warn > 0.0:
		ci.draw_style_box(P.sb(Color(0, 0, 0, 0), 8, 0, Vector2.ZERO, 3, Color(P.SIG_AMBER, warn)), r)
		P.glow(ci, r.get_center(), r.size.x * 1.3, P.SIG_AMBER, 0.25 * warn)


# ================================================================ HUD
## Mechanische teller met rolcijfers. value mag fractioneel zijn: het laatste cijfer rolt mee (animatie).
static func counter(ci: CanvasItem, pos: Vector2, value: float, digits := 4, label := "TIKKEN", dw := 30.0, dh := 44.0) -> Rect2:
	var w := digits * (dw + 4) + 16
	var r := Rect2(pos, Vector2(w, dh + 16))
	ci.draw_style_box(P.sb(P.SHADOW, 8), Rect2(r.position + Vector2(1, 4), r.size))
	ci.draw_style_box(P.sb(P.BAKELITE_LO, 8), r)
	ci.draw_texture_rect(P.tex("tex/bakelite.png"), r.grow(-3), true, Color(P.BAKELITE.r * 1.6, P.BAKELITE.g * 1.6, P.BAKELITE.b * 1.6, 0.9))
	var v := maxf(value, 0.0)
	for k in digits:
		var place := pow(10.0, digits - 1 - k)
		var dv := fmod(v / place, 10.0)
		var digit := int(floor(dv))
		var frac := 0.0
		if k == digits - 1:
			frac = dv - digit
		else:
			# hogere rollen draaien enkel mee in de laatste fractie van het lagere cijfer (mechanisch)
			var lower := fmod(v, place)
			var thr := place - 1.0
			frac = clampf(lower - thr, 0.0, 1.0) if lower > thr else 0.0
		var dr := Rect2(pos.x + 8 + k * (dw + 4), pos.y + 8, dw, dh)
		ci.draw_rect(dr, Color("#0E0D0C"))
		var cy := dr.get_center().y - frac * dh
		var big := int(dh * 0.62)
		for o in 2:
			var dd := (digit + o) % 10
			var yy := cy + o * dh
			if yy > dr.position.y - dh * 0.5 and yy < dr.end.y + dh * 0.5:
				var a := 1.0 - clampf(absf(yy - dr.get_center().y) / (dh * 0.62), 0.0, 1.0)
				P.text_c(ci, P.MONO, Vector2(dr.get_center().x, yy), str(dd), big, Color(P.PAPER_HI, a))
		# cilinder-schaduw boven en onder
		ci.draw_rect(Rect2(dr.position, Vector2(dw, dh * 0.22)), Color(0, 0, 0, 0.55))
		ci.draw_rect(Rect2(dr.position.x, dr.end.y - dh * 0.22, dw, dh * 0.22), Color(0, 0, 0, 0.55))
		ci.draw_rect(Rect2(dr.position.x, dr.get_center().y - 1, dw, 1), Color(1, 1, 1, 0.04))
	ci.draw_rect(Rect2(pos.x + 4, pos.y + 4, w - 8, 3), Color(1, 1, 1, 0.07))
	if label != "":
		P.text_r(ci, P.STENCIL, Vector2(pos.x - 10, r.get_center().y), label, 18, P.BRASS)
	return r


## Geest-balk "brute kracht: N": grijze goot die volloopt; overschreden = amber.
static func ghost_bar(ci: CanvasItem, r: Rect2, mine: float, brute: float) -> void:
	P.well(ci, r, P.CONSOLE_LO, 5)
	var u := clampf(mine / maxf(brute, 1.0), 0.0, 1.0)
	var over := mine > brute
	var col := P.SIG_AMBER if over else P.SIG_GREY
	ci.draw_style_box(P.sb(Color(col, 0.75), 4), Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6) * u, r.size.y - 6)))
	P.text_c(ci, P.UI_BOLD, r.get_center() + Vector2(0, -1), "brute kracht: %d" % int(brute), 16, P.TEXT if not over else P.BAKELITE_LO)


## Drie vertrouwenslampjes (◉◉◉). lit = aantal aan; fade 0..1 = het (lit)-de lampje dooft net.
static func trust(ci: CanvasItem, pos: Vector2, lit: int, fade := 0.0) -> void:
	for i in 3:
		var on := 1.0 if i < lit else 0.0
		if i == lit and fade > 0.0:
			on = 1.0 - fade
		P.lamp(ci, pos + Vector2(i * 30, 0), 9.0, P.SIG_AMBER, on)


## Sterren (gestempeld). n = behaald.
static func stars(ci: CanvasItem, pos: Vector2, n: int, size := 26.0, total := 3) -> void:
	for i in total:
		var c := pos + Vector2(i * (size * 1.25), 0)
		star(ci, c, size * 0.5, P.BRASS if i < n else Color(0, 0, 0, 0), P.BRASS_HI if i < n else P.TEXT_DIM)


static func star(ci: CanvasItem, c: Vector2, r: float, fill: Color, line: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	if fill.a > 0.0:
		ci.draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	ci.draw_polyline(pts, line, 2.0, true)


## HUD-balk bovenaan (bakeliet met messing bies). Geeft de rect terug.
static func hud_bar(ci: CanvasItem, w: float, h := 60.0) -> Rect2:
	var r := Rect2(0, 0, w, h)
	ci.draw_rect(Rect2(0, h, w, 8), Color(0, 0, 0, 0.35))
	ci.draw_texture_rect(P.tex("tex/bakelite.png"), r, true, Color(P.BAKELITE.r * 1.4, P.BAKELITE.g * 1.4, P.BAKELITE.b * 1.4))
	ci.draw_rect(Rect2(0, h - 4, w, 4), P.BRASS_LO)
	ci.draw_rect(Rect2(0, h - 4, w, 1.5), P.BRASS_HI)
	return r


## Codewoord-chip (z) zoals op een dossierkaartje: getypt op een stukje lint.
static func word_chip(ci: CanvasItem, pos: Vector2, s: String, size := 26, col := P.PAPER) -> Rect2:
	var w := P.text_w(P.TAPE, s, size) + 24
	var r := Rect2(pos, Vector2(w, size * 1.45))
	ci.draw_rect(Rect2(r.position + Vector2(1, 3), r.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(col.r * 1.15, col.g * 1.12, col.b * 1.05))
	P.text_l(ci, P.TAPE, Vector2(r.position.x + 12, r.get_center().y + 1), s, size, P.INK)
	return r


# ================================================================ BUIZENPOST, DOSSIER, KUSTKAART
## Buizenpost (rechts van de console): messing buis met glazen venster; capsule u 0..1 schiet omhoog.
static func tube(ci: CanvasItem, r: Rect2, u := -1.0, label := "") -> void:
	P.panel(ci, r, P.CONSOLE, true, 10)
	var tr := Rect2(r.get_center().x - 26, r.position.y + 36, 52, r.size.y - 110)
	ci.draw_style_box(P.sb(P.BRASS_LO, 24), tr.grow(5))
	ci.draw_style_box(P.sb(Color(P.NIGHT, 0.9), 22), tr)
	ci.draw_rect(Rect2(tr.position.x + 8, tr.position.y + 10, 6, tr.size.y - 20), Color(1, 1, 1, 0.08))
	for k in 3:
		var yy := tr.position.y + 20 + k * (tr.size.y - 40) / 2.0
		ci.draw_rect(Rect2(tr.position.x - 7, yy - 5, tr.size.x + 14, 10), P.BRASS)
		ci.draw_rect(Rect2(tr.position.x - 7, yy - 5, tr.size.x + 14, 3), P.BRASS_HI)
	if u >= 0.0:
		var cy := lerpf(tr.end.y - 30, tr.position.y + 10, u)
		capsule(ci, Vector2(tr.get_center().x, cy), PI / 2, label, 0.85)
	# ontvangstklep onderaan
	var flap := Rect2(r.position.x + 18, r.end.y - 62, r.size.x - 36, 44)
	ci.draw_style_box(P.sb(P.BAKELITE, 6), flap)
	P.text_c(ci, P.STENCIL, flap.get_center(), "BUIZENPOST", 15, P.BRASS)


## Koker (capsule) met papieren etiket "z @ positie". ang = rotatie (0 = liggend naar rechts).
static func capsule(ci: CanvasItem, c: Vector2, ang := 0.0, label := "", s := 1.0) -> void:
	var lw := P.text_w(P.TAPE, label, 17) + 14 if label != "" else 0.0
	var hw := maxf(46.0, lw / 2.0 + 22.0)
	ci.draw_set_transform(c, ang, Vector2(s, s))
	var body := Rect2(-hw, -15, hw * 2, 30)
	ci.draw_style_box(P.sb(P.SHADOW, 15), Rect2(body.position + Vector2(2, 5), body.size))
	ci.draw_style_box(P.sb(P.BRASS_LO, 15), body)
	ci.draw_style_box(P.sb(P.BRASS, 13), body.grow(-2))
	ci.draw_rect(Rect2(-hw + 6, -11, hw * 2 - 12, 5), Color(P.BRASS_HI, 0.6))
	for x in [-hw + 12, hw - 12]:
		ci.draw_rect(Rect2(x - 3, -15, 6, 30), P.BRASS_LO)
	if label != "":
		var lr := Rect2(-lw / 2, -11, lw, 22)
		ci.draw_rect(lr, P.CARD)
		ci.draw_rect(lr, P.PAPER_EDGE, false, 1.0)
		P.text_c(ci, P.TAPE, lr.get_center() + Vector2(0, 1), label, 17, P.STAMP_BLUE)
	ci.draw_set_transform(Vector2.ZERO)


## Dossierkaart (opdracht): manila kaart met getypte velden en een stempel. fields = [[sleutel, waarde], ...].
static func dossier_card(ci: CanvasItem, r: Rect2, title: String, fields: Array, ref := "", rot := -0.012) -> void:
	ci.draw_set_transform(r.get_center(), rot, Vector2.ONE)
	var lr := Rect2(-r.size / 2.0, r.size)
	ci.draw_rect(Rect2(lr.position + Vector2(3, 6), lr.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), lr, true, Color(P.MANILA.r * 1.2, P.MANILA.g * 1.2, P.MANILA.b * 1.18))
	ci.draw_rect(Rect2(lr.position, Vector2(lr.size.x, 34)), Color(P.MANILA_LO, 0.55))
	P.text_l(ci, P.STENCIL, lr.position + Vector2(14, 18), title, 20, P.INK)
	var y := lr.position.y + 54
	for f in fields:
		P.text_l(ci, P.TAPE_REG, Vector2(lr.position.x + 14, y), str(f[0]), 18, P.INK_SOFT)
		var vx := lr.position.x + 14 + P.text_w(P.TAPE_REG, str(f[0]), 18) + 10
		P.text_l(ci, P.TAPE, Vector2(vx, y), str(f[1]), 22, P.INK)
		y += 30
	if ref != "":
		# notasverwijzing moet binnen de kaart blijven (QA: "notas p. 56–59" liep over de rand)
		var rs := 16
		while rs > 11 and P.text_w(P.TAPE_REG, ref, rs) > lr.size.x - 28:
			rs -= 1
		P.text_l(ci, P.TAPE_REG, Vector2(lr.position.x + 14, lr.end.y - 18), ref, rs, P.STAMP_RED)
	# paperclip
	var px := lr.end.x - 40
	ci.draw_arc(Vector2(px, lr.position.y + 2), 7, PI, TAU, 10, P.STEEL_HI, 2.0, true)
	ci.draw_line(Vector2(px - 7, lr.position.y + 2), Vector2(px - 7, lr.position.y + 26), P.STEEL_HI, 2.0, true)
	ci.draw_line(Vector2(px + 7, lr.position.y + 2), Vector2(px + 7, lr.position.y + 20), P.STEEL_HI, 2.0, true)
	ci.draw_set_transform(Vector2.ZERO)


## Kaartspeld (rood = koerier ontsnapt, grijs = vals adres, groen = opgepakt, messing = station).
static func pin(ci: CanvasItem, p: Vector2, col: Color, s := 1.0) -> void:
	ci.draw_line(p, p + Vector2(6, 8) * s, Color(0, 0, 0, 0.35), 2.0 * s, true)
	ci.draw_line(p, p + Vector2(0, -14) * s, P.STEEL_HI, 2.0 * s, true)
	ci.draw_circle(p + Vector2(1, -15) * s, 7.5 * s, Color(0, 0, 0, 0.35), true, -1.0, true)
	ci.draw_circle(p + Vector2(0, -17) * s, 7.0 * s, col, true, -1.0, true)
	ci.draw_circle(p + Vector2(-2, -19) * s, 2.5 * s, col.lightened(0.5), true, -1.0, true)


## Silhouet van een Ekster-koerier (hoed, trenchcoat, koffertje). p = voeten, s = schaal (1 = 64 px hoog).
static func courier(ci: CanvasItem, p: Vector2, s := 1.0, col := Color("#121416"), walk := 0.0) -> void:
	var o := p
	var lg := sin(walk * TAU) * 4.0
	ci.draw_colored_polygon(_sc(o, s, [Vector2(-6 + lg, 0), Vector2(-2 + lg, 0), Vector2(-1, -18), Vector2(-5, -18)]), col)
	ci.draw_colored_polygon(_sc(o, s, [Vector2(2 - lg, 0), Vector2(6 - lg, 0), Vector2(5, -18), Vector2(1, -18)]), col)
	ci.draw_colored_polygon(_sc(o, s, [Vector2(-10, -44), Vector2(10, -44), Vector2(13, -14), Vector2(-13, -14)]), col)
	ci.draw_colored_polygon(_sc(o, s, [Vector2(-3, -44), Vector2(3, -44), Vector2(0, -34)]), Color("#3A3A3A"))
	ci.draw_circle(o + Vector2(0, -50) * s, 6.5 * s, col, true, -1.0, true)
	ci.draw_colored_polygon(_sc(o, s, [Vector2(-13, -54), Vector2(13, -54), Vector2(10, -52), Vector2(-10, -52)]), col)
	ci.draw_colored_polygon(_sc(o, s, [Vector2(-7, -54), Vector2(7, -54), Vector2(6, -63), Vector2(-6, -63)]), col)
	ci.draw_rect(Rect2(o + Vector2(-7, -57) * s, Vector2(14, 2) * s), P.STAMP_RED.darkened(0.2))
	ci.draw_rect(Rect2(o + Vector2(12, -24) * s, Vector2(13, 10) * s), col.lightened(0.12))
	ci.draw_arc(o + Vector2(18.5, -24) * s, 3.0 * s, PI, TAU, 6, col.lightened(0.12), 1.5 * s, true)


## Polizieautootje (de ploeg) in zijaanzicht, 60 px breed bij s = 1. siren 0..1 = blauw zwaailicht.
static func car(ci: CanvasItem, p: Vector2, s := 1.0, siren := 0.0, col := Color("#2C3E50")) -> void:
	ci.draw_colored_polygon(_sc(p, s, [Vector2(-30, -6), Vector2(-28, -16), Vector2(-16, -17), Vector2(-9, -28), Vector2(12, -28),
		Vector2(19, -17), Vector2(29, -15), Vector2(31, -6)]), col)
	ci.draw_colored_polygon(_sc(p, s, [Vector2(-7, -25), Vector2(0, -25), Vector2(0, -18), Vector2(-12, -18)]), Color("#9FC3D1"))
	ci.draw_colored_polygon(_sc(p, s, [Vector2(3, -25), Vector2(11, -25), Vector2(16, -18), Vector2(3, -18)]), Color("#9FC3D1"))
	ci.draw_rect(Rect2(p + Vector2(-28, -12) * s, Vector2(58, 3) * s), Color(1, 1, 1, 0.7))
	for wx in [-18, 19]:
		ci.draw_circle(p + Vector2(wx, -5) * s, 6 * s, Color("#111111"), true, -1.0, true)
		ci.draw_circle(p + Vector2(wx, -5) * s, 2.5 * s, P.STEEL, true, -1.0, true)
	ci.draw_rect(Rect2(p + Vector2(-2, -32) * s, Vector2(5, 4) * s), P.SIG_BLUE.lerp(Color.WHITE, siren * 0.6))
	if siren > 0.0:
		P.glow(ci, p + Vector2(0.5, -30) * s, 40 * s, P.SIG_BLUE, 0.7 * siren)


## Ekster (embleem van het netwerk): eksterprofiel naar rechts, zwart met witte buik en vleugelvlek.
static func magpie(ci: CanvasItem, c: Vector2, s := 1.0, col := Color("#101214"), white := Color("#F2EFE6")) -> void:
	ci.draw_colored_polygon(_sc(c, s, [Vector2(-10, 1), Vector2(-46, 15), Vector2(-48, 11), Vector2(-12, -5)]), col)
	ci.draw_colored_polygon(_ell(c + Vector2(0, 0) * s, 17 * s, 9 * s, -0.25), col)
	ci.draw_colored_polygon(_ell(c + Vector2(3, 3) * s, 9 * s, 5 * s, -0.2), white)
	ci.draw_colored_polygon(_ell(c + Vector2(-3, -3) * s, 8 * s, 3 * s, -0.3), white)
	ci.draw_circle(c + Vector2(15, -8) * s, 7.5 * s, col, true, -1.0, true)
	ci.draw_colored_polygon(_sc(c, s, [Vector2(21, -10), Vector2(31, -7), Vector2(21, -5)]), col)
	ci.draw_circle(c + Vector2(17, -10) * s, 1.4 * s, white, true, -1.0, true)
	ci.draw_line(c + Vector2(2, 8) * s, c + Vector2(0, 16) * s, col, 1.6 * s, true)
	ci.draw_line(c + Vector2(6, 8) * s, c + Vector2(6, 16) * s, col, 1.6 * s, true)


## Lakzegel met ekster (finale-map, debrief bij "Operatie Ekster").
static func ekster_seal(ci: CanvasItem, c: Vector2, r := 40.0) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var rr := r * (1.0 + 0.06 * sin(i * 2.3))
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, P.STAMP_RED.darkened(0.15))
	ci.draw_circle(c, r * 0.78, P.STAMP_RED, true, -1.0, true)
	ci.draw_arc(c, r * 0.72, 0, TAU, 40, P.STAMP_RED.darkened(0.35), 2.0, true)
	magpie(ci, c + Vector2(4, 0), r / 52.0, P.STAMP_RED.darkened(0.55), P.STAMP_RED.lightened(0.25))


## Mini-kustkaart (HUD rechtsonder, debrief). pins = [[Vector2 kaartpixel (1200×760), Color], ...].
static func mini_map(ci: CanvasItem, r: Rect2, pins := [], tilt := 0.02) -> void:
	ci.draw_set_transform(r.get_center(), tilt, Vector2.ONE)
	var lr := Rect2(-r.size / 2.0, r.size)
	ci.draw_rect(Rect2(lr.position + Vector2(3, 6), lr.size), P.SHADOW)
	ci.draw_texture_rect_region(P.tex("bg/coast_map.jpg"), lr, Rect2(300, 150, 700, 440))
	ci.draw_rect(lr, Color(P.INK, 0.6), false, 2.0)
	for pn in pins:
		var mp: Vector2 = pn[0]
		var q := lr.position + (mp - Vector2(300, 150)) / Vector2(700, 440) * lr.size
		pin(ci, q, pn[1], 0.8)
	ci.draw_set_transform(Vector2.ZERO)


# ================================================================ PERSONAGES
## Chef Ponsaert (coach): oud-telegrafiste, grijze knot, ronde messing bril, koptelefoon, groen vest, potlood.
## c = midden van het portret (ovaal ~170×190 bij s = 1). talk 0..1 (mond), blink 0..1, brow 0..1 (wenkbrauw op).
static func chef(ci: CanvasItem, c: Vector2, s := 1.0, talk := 0.0, blink := 0.0, brow := 0.4, frame := true) -> void:
	var skin := Color("#E8C2A0")
	var skin_sh := Color("#C99A78")
	var hair := Color("#BDB8AE")
	var hair_sh := Color("#8F8A80")
	if frame:
		ci.draw_colored_polygon(_ell(c + Vector2(0, 4) * s, 88 * s, 98 * s, 0.0), P.SHADOW)
		ci.draw_colored_polygon(_ell(c, 86 * s, 96 * s, 0.0), P.BRASS_LO)
		ci.draw_colored_polygon(_ell(c, 81 * s, 91 * s, 0.0), Color("#24413A"))
		ci.draw_colored_polygon(_ell(c + Vector2(-14, -22) * s, 60 * s, 52 * s, 0.0), Color(1, 1, 1, 0.05))
	# lichaam: vest, kraag, broche
	ci.draw_colored_polygon(_sc(c, s, [Vector2(-74, 92), Vector2(-66, 52), Vector2(-34, 36), Vector2(34, 36), Vector2(66, 52), Vector2(74, 92)]), Color("#2F5446"))
	ci.draw_colored_polygon(_sc(c, s, [Vector2(-16, 36), Vector2(16, 36), Vector2(0, 74)]), Color("#F3EEE2"))
	ci.draw_colored_polygon(_sc(c, s, [Vector2(-16, 36), Vector2(-26, 50), Vector2(-4, 56)]), Color("#E2DCCD"))
	ci.draw_colored_polygon(_sc(c, s, [Vector2(16, 36), Vector2(26, 50), Vector2(4, 56)]), Color("#E2DCCD"))
	ci.draw_line(c + Vector2(-3, 60) * s, c + Vector2(-8, 92) * s, Color("#22403A"), 2.0 * s, true)
	for k in 2:
		ci.draw_circle(c + Vector2(-10, 70 + k * 12) * s, 2.2 * s, P.BRASS, true, -1.0, true)
	ci.draw_circle(c + Vector2(30, 56) * s, 5 * s, P.BRASS, true, -1.0, true)
	ci.draw_circle(c + Vector2(30, 56) * s, 2.5 * s, P.STAMP_RED, true, -1.0, true)
	# hals + achterhoofd-haar
	ci.draw_rect(Rect2(c + Vector2(-11, 14) * s, Vector2(22, 26) * s), skin_sh)
	ci.draw_colored_polygon(_ell(c + Vector2(0, -16) * s, 36 * s, 38 * s, 0.0), hair_sh)
	# knot
	ci.draw_circle(c + Vector2(0, -58) * s, 17 * s, hair_sh, true, -1.0, true)
	ci.draw_circle(c + Vector2(-2, -60) * s, 14 * s, hair, true, -1.0, true)
	ci.draw_arc(c + Vector2(0, -58) * s, 10 * s, 0.4, 2.6, 8, hair_sh, 1.5 * s, true)
	# gezicht
	ci.draw_colored_polygon(_ell(c + Vector2(0, -8) * s, 29 * s, 35 * s, 0.0), skin)
	ci.draw_colored_polygon(_ell(c + Vector2(-29, -6) * s, 5 * s, 8 * s, 0.0), skin_sh)
	ci.draw_colored_polygon(_ell(c + Vector2(13, 8) * s, 7 * s, 4 * s, 0.0), Color(0.9, 0.5, 0.45, 0.25))
	ci.draw_colored_polygon(_ell(c + Vector2(-13, 8) * s, 7 * s, 4 * s, 0.0), Color(0.9, 0.5, 0.45, 0.25))
	# haar bovenop (scheiding, golf)
	ci.draw_colored_polygon(_sc(c, s, [Vector2(-31, -14), Vector2(-30, -34), Vector2(-16, -46), Vector2(4, -48), Vector2(22, -42),
		Vector2(31, -28), Vector2(31, -12), Vector2(24, -24), Vector2(10, -32), Vector2(-6, -30), Vector2(-20, -24)]), hair)
	ci.draw_polyline(_sc(c, s, [Vector2(-18, -40), Vector2(-4, -36), Vector2(10, -38)]), hair_sh, 1.5 * s, true)
	# ogen + bril
	var ey := -10.0
	for side in [-1, 1]:
		var e := c + Vector2(side * 12, ey) * s
		if blink > 0.5:
			ci.draw_line(e + Vector2(-4, 0) * s, e + Vector2(4, 0) * s, Color("#2A2018"), 2.0 * s, true)
		else:
			ci.draw_circle(e, 2.8 * s, Color("#2A2018"), true, -1.0, true)
			ci.draw_circle(e + Vector2(-1, -1) * s, 0.9 * s, Color(1, 1, 1, 0.8), true, -1.0, true)
		ci.draw_arc(e, 10 * s, 0, TAU, 24, P.BRASS_LO, 2.4 * s, true)
		ci.draw_arc(e, 9 * s, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.5), 1.4 * s, true)
		var by := -24.0 - (brow * 4.0 if side == 1 else 0.0)
		ci.draw_line(c + Vector2(side * 6, by + 2) * s, c + Vector2(side * 18, by) * s, hair_sh.darkened(0.3), 2.4 * s, true)
	ci.draw_line(c + Vector2(-2, ey) * s, c + Vector2(2, ey) * s, P.BRASS_LO, 2.0 * s, true)
	ci.draw_line(c + Vector2(22, ey - 2) * s, c + Vector2(29, ey - 6) * s, P.BRASS_LO, 2.0 * s, true)
	# neus, mond (talk opent)
	ci.draw_polyline(_sc(c, s, [Vector2(0, -6), Vector2(-3, 6), Vector2(1, 8)]), skin_sh.darkened(0.15), 1.8 * s, true)
	var mo := 1.0 + talk * 5.0
	ci.draw_colored_polygon(_ell(c + Vector2(1, 17) * s, 8 * s, mo * s, 0.0), Color("#7A3A34"))
	ci.draw_line(c + Vector2(-8, 16) * s, c + Vector2(10, 15) * s, Color("#9A4E46"), 2.0 * s, true)
	ci.draw_line(c + Vector2(10, 15) * s, c + Vector2(13, 12) * s, Color("#9A4E46"), 1.6 * s, true)
	# koptelefoon: beugel, oorschelp rechts, microfoonarm
	ci.draw_arc(c + Vector2(0, -12) * s, 38 * s, PI * 1.02, PI * 1.98, 24, P.STEEL_LO, 5.0 * s, true)
	ci.draw_arc(c + Vector2(0, -12) * s, 38 * s, PI * 1.1, PI * 1.5, 12, P.STEEL_HI, 1.5 * s, true)
	ci.draw_style_box(P.sb(Color("#1C1C1C"), int(8 * s)), Rect2(c + Vector2(26, -20) * s, Vector2(16, 26) * s))
	ci.draw_style_box(P.sb(Color("#3A3A3A"), int(6 * s)), Rect2(c + Vector2(29, -16) * s, Vector2(9, 18) * s))
	ci.draw_polyline(_sc(c, s, [Vector2(34, 4), Vector2(30, 18), Vector2(16, 24)]), Color("#1C1C1C"), 2.5 * s, true)
	ci.draw_circle(c + Vector2(14, 24) * s, 3.2 * s, Color("#1C1C1C"), true, -1.0, true)
	# potlood achter het linkeroor
	ci.draw_line(c + Vector2(-44, -30) * s, c + Vector2(-22, 2) * s, Color("#E8B83A"), 4.0 * s, true)
	ci.draw_line(c + Vector2(-44, -30) * s, c + Vector2(-41, -26) * s, Color("#E07A8A"), 4.0 * s, true)


## Spreekwolk van de Chef: getypt telegramstrookje met een staartje naar `tail`.
static func balloon(ci: CanvasItem, r: Rect2, text: String, tail := Vector2.INF, size := 22) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 6), r.size), P.SHADOW)
	if tail != Vector2.INF:
		var base := Vector2(clampf(tail.x, r.position.x + 20, r.end.x - 20), r.end.y - 2 if tail.y > r.end.y else r.position.y + 2)
		if tail.x < r.position.x:
			base = Vector2(r.position.x + 2, clampf(tail.y, r.position.y + 16, r.end.y - 16))
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-12, 0) if tail.x >= r.position.x else base + Vector2(0, -12),
			base + Vector2(12, 0) if tail.x >= r.position.x else base + Vector2(0, 12), tail]), P.CARD)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(P.CARD.r * 1.15, P.CARD.g * 1.15, P.CARD.b * 1.12))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(P.STAMP_BLUE, 0.7))
	P.text_l(ci, P.TAPE_REG, r.position + Vector2(16, 20), "CHEF PONSAERT  —  STOP", 13, P.INK_SOFT)
	var y := r.position.y + 50
	for line in text.split("\n"):
		P.text_l(ci, P.TAPE, Vector2(r.position.x + 16, y), line, size, P.INK)
		y += size * 1.3


# ================================================================ MAPPEN, KIST
## Dossiermap op de missiekaart. state: "open"/"done"/"locked"/"final". stars = behaalde sterren (0..3 per level ⇒ hier
## het dossiertotaal als "x/y"). col = kleur van het tabje (dossier).
static func folder(ci: CanvasItem, r: Rect2, num: String, title: String, stars_txt := "", state := "open", rot := 0.0, col := P.MANILA) -> void:
	ci.draw_set_transform(r.get_center(), rot, Vector2.ONE)
	var lr := Rect2(-r.size / 2.0, r.size)
	var base := col if state != "final" else Color("#8E2A20")
	if state == "locked":
		base = base.darkened(0.45)
	ci.draw_rect(Rect2(lr.position + Vector2(4, 8), lr.size), P.SHADOW)
	ci.draw_style_box(P.sb(base.darkened(0.12), 4), Rect2(lr.position + Vector2(10, -16), Vector2(lr.size.x * 0.42, 24)))
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), lr, true, Color(base.r * 1.2, base.g * 1.2, base.b * 1.18))
	ci.draw_rect(Rect2(lr.position.x, lr.position.y + 6, lr.size.x, 2), Color(0, 0, 0, 0.12))
	var ink := P.INK if state != "final" else Color("#FFE9DC")
	P.text_l(ci, P.STENCIL, lr.position + Vector2(18, -3), "DOSSIER " + num, 16, ink.darkened(0.1) if state != "final" else ink)
	P.text_l(ci, P.TAPE, lr.position + Vector2(18, 40), title, 24, ink)
	ci.draw_line(lr.position + Vector2(18, 58), Vector2(lr.end.x - 18, lr.position.y + 58), Color(ink, 0.3), 1.0)
	if stars_txt != "":
		star(ci, Vector2(lr.position.x + 30, lr.end.y - 24), 11, P.BRASS, P.BRASS_LO)
		P.text_l(ci, P.MONO, Vector2(lr.position.x + 48, lr.end.y - 24), stars_txt, 18, ink)
	if state == "locked":
		icon(ci, "lock", lr.get_center() + Vector2(0, 10), 40, P.TEXT_DIM)
	elif state == "done":
		ci.draw_texture_rect(P.tex("stamps/gezien.png"), Rect2(lr.end.x - 130, lr.end.y - 64, 120, 50), false, Color(P.STAMP_RED, 0.85))
	elif state == "final":
		ekster_seal(ci, Vector2(lr.end.x - 46, lr.end.y - 44), 30)
	ci.draw_set_transform(Vector2.ZERO)


## Houten kist met een nieuwe machine. lid 0..1 (deksel open), sheen 0..1 (glans op het typeplaatje), plate = tekst.
static func crate(ci: CanvasItem, r: Rect2, plate: String, lid := 0.0, sheen := -1.0) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(6, 10), r.size), P.SHADOW)
	for i in 4:
		var pr := Rect2(r.position.x, r.position.y + i * r.size.y / 4.0, r.size.x, r.size.y / 4.0 - 3)
		var c := P.WOOD.lerp(P.WOOD_HI, 0.15 * (i % 2))
		ci.draw_rect(pr, c)
		ci.draw_rect(Rect2(pr.position, Vector2(pr.size.x, 2)), P.WOOD_HI)
		for k in 3:
			var yy := pr.position.y + pr.size.y * (0.3 + 0.2 * k)
			ci.draw_line(Vector2(pr.position.x + 8, yy), Vector2(pr.end.x - 8, yy + sin(k + i) * 2), Color(P.WOOD_LO, 0.35), 1.0)
	for x in [r.position.x + 18, r.end.x - 34]:
		ci.draw_rect(Rect2(x, r.position.y, 16, r.size.y), P.WOOD_LO.lerp(P.WOOD, 0.5))
	for p in [r.position + Vector2(26, 12), Vector2(r.end.x - 26, r.position.y + 12), r.position + Vector2(26, r.size.y - 14), r.end - Vector2(26, 14)]:
		ci.draw_circle(p, 3, P.STEEL_LO, true, -1.0, true)
	P.text_c(ci, P.STENCIL, Vector2(r.get_center().x, r.position.y + 24), "STATION ZOEKLICHT", 24, Color(P.INK, 0.7))
	P.text_c(ci, P.STENCIL, Vector2(r.get_center().x, r.end.y - 16), "BREEKBAAR", 16, Color(P.STAMP_RED, 0.8))
	P.brass_plate(ci, r.get_center() + Vector2(0, 6), plate, 24, P.STENCIL, sheen)
	if lid > 0.0:
		var h := 26.0
		ci.draw_set_transform(Vector2(r.position.x, r.position.y), -lid * 0.9, Vector2.ONE)
		ci.draw_rect(Rect2(0, -h, r.size.x, h), P.WOOD_HI)
		ci.draw_rect(Rect2(0, -h, r.size.x, 3), P.WOOD_HI.lightened(0.2))
		ci.draw_set_transform(Vector2.ZERO)


## Toetskapje voor toetsenbord-hints ("Spatie", "Enter", "V").
static func keycap(ci: CanvasItem, pos: Vector2, s: String, size := 16) -> Rect2:
	var w := maxf(P.text_w(P.MONO_B, s, size) + 16, size + 14)
	var r := Rect2(pos, Vector2(w, size + 14))
	ci.draw_style_box(P.sb(P.BAKELITE_LO, 5), Rect2(r.position + Vector2(0, 3), r.size))
	ci.draw_style_box(P.sb(P.BAKELITE_HI, 5), r)
	ci.draw_rect(Rect2(r.position + Vector2(3, 2), Vector2(r.size.x - 6, 2)), Color(1, 1, 1, 0.12))
	P.text_c(ci, P.MONO_B, r.get_center(), s, size, P.TEXT)
	return r


# ================================================================ ICONEN (lijnstijl, 2,5 px bij size 40)
## name: sjabloon, vingerafdruk, doorloper, springer, lampenbord, ruisbord, schakelbord, zoeklicht,
##       pauze, notas, hint, terug, instellingen, kaart, lock, play, buis, koerier, tik
static func icon(ci: CanvasItem, name: String, c: Vector2, size := 40.0, col := P.TEXT) -> void:
	var k := size / 40.0
	var w := 2.6 * k
	match name:
		"sjabloon":
			ci.draw_rect(Rect2(c + Vector2(-16, -2) * k, Vector2(32, 12) * k), col, false, w)
			for i in 4:
				var x := -12 + i * 8
				ci.draw_colored_polygon(_sc(c, k, [Vector2(x - 3, -2), Vector2(x + 3, -2), Vector2(x, -9)]), col)
			ci.draw_line(c + Vector2(-16, -14) * k, c + Vector2(16, -14) * k, col, w, true)
		"vingerafdruk":
			for i in 4:
				ci.draw_arc(c, (5 + i * 4) * k, PI * 0.9, PI * 2.25, 16, col, w * 0.8, true)
			ci.draw_line(c + Vector2(0, -2) * k, c + Vector2(0, 8) * k, col, w * 0.8, true)
		"doorloper":
			ci.draw_line(c + Vector2(-16, 6) * k, c + Vector2(14, 6) * k, col, w, true)
			ci.draw_colored_polygon(_sc(c, k, [Vector2(16, 6), Vector2(8, 0), Vector2(8, 12)]), col)
			for i in 3:
				ci.draw_colored_polygon(_sc(c, k, [Vector2(-12 + i * 9, -2), Vector2(-6 + i * 9, -2), Vector2(-9 + i * 9, -11)]), col)
		"springer":
			ci.draw_arc(c + Vector2(0, 8) * k, 14 * k, PI * 1.05, PI * 1.95, 16, col, w, true)
			ci.draw_colored_polygon(_sc(c, k, [Vector2(16, 7), Vector2(8, 4), Vector2(13, -2)]), col)
			ci.draw_line(c + Vector2(-17, 12) * k, c + Vector2(17, 12) * k, col, w, true)
		"lampenbord":
			for i in 3:
				ci.draw_circle(c + Vector2(-4, -12 + i * 12) * k, 4.5 * k, col if i != 1 else Color(col, 0.35), true, -1.0, true)
			ci.draw_line(c + Vector2(10, -14) * k, c + Vector2(10, 12) * k, col, w, true)
			ci.draw_circle(c + Vector2(10, -14) * k, 4 * k, col, true, -1.0, true)
		"ruisbord":
			for i in 2:
				for j in 3:
					ci.draw_circle(c + Vector2(-10 + i * 20, -11 + j * 11) * k, 3.5 * k, col, true, -1.0, true)
			ci.draw_polyline(_sc(c, k, [Vector2(-10, 11), Vector2(-3, -2), Vector2(3, 6), Vector2(10, -11)]), col, w * 0.8, true)
		"schakelbord":
			for i in 3:
				for j in 3:
					ci.draw_rect(Rect2(c + Vector2(-15 + i * 11, -15 + j * 11) * k, Vector2(8, 8) * k), col if (i == j) else Color(col, 0.4), false, w * 0.7)
			ci.draw_line(c + Vector2(-11, -11) * k, c + Vector2(11, 11) * k, col, w * 0.8, true)
		"zoeklicht":
			ci.draw_colored_polygon(_sc(c, k, [Vector2(-14, -6), Vector2(-4, -12), Vector2(-4, 0)]), col)
			ci.draw_colored_polygon(_sc(c, k, [Vector2(-4, -10), Vector2(16, -2), Vector2(16, 14), Vector2(-4, -2)]), Color(col, 0.35))
			ci.draw_line(c + Vector2(-10, 0) * k, c + Vector2(-10, 14) * k, col, w, true)
		"pauze":
			ci.draw_rect(Rect2(c + Vector2(-9, -12) * k, Vector2(6, 24) * k), col)
			ci.draw_rect(Rect2(c + Vector2(3, -12) * k, Vector2(6, 24) * k), col)
		"play":
			ci.draw_colored_polygon(_sc(c, k, [Vector2(-8, -12), Vector2(12, 0), Vector2(-8, 12)]), col)
		"notas":
			ci.draw_rect(Rect2(c + Vector2(-12, -14) * k, Vector2(24, 30) * k), col, false, w)
			ci.draw_rect(Rect2(c + Vector2(-6, -18) * k, Vector2(12, 7) * k), col)
			for i in 3:
				ci.draw_line(c + Vector2(-7, -4 + i * 7) * k, c + Vector2(7, -4 + i * 7) * k, col, w * 0.7, true)
		"hint":
			ci.draw_arc(c + Vector2(0, -6) * k, 8 * k, PI, TAU * 1.12, 12, col, w, true)
			ci.draw_line(c + Vector2(4, 0) * k, c + Vector2(0, 5) * k, col, w, true)
			ci.draw_circle(c + Vector2(0, 13) * k, 2.6 * k, col, true, -1.0, true)
		"terug":
			ci.draw_arc(c, 12 * k, PI * 0.15, PI * 1.6, 18, col, w, true)
			ci.draw_colored_polygon(_sc(c, k, [Vector2(-2, -18), Vector2(-2, -6), Vector2(-12, -12)]), col)
		"instellingen":
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				var rr := 15.0 if (i % 2) == 0 else 11.5
				pts.append(c + Vector2(cos(a), sin(a)) * rr * k)
			pts.append(pts[0])
			ci.draw_polyline(pts, col, w * 0.8, true)
			ci.draw_arc(c, 5 * k, 0, TAU, 12, col, w * 0.8, true)
		"kaart":
			ci.draw_polyline(_sc(c, k, [Vector2(-16, -10), Vector2(-6, -14), Vector2(6, -10), Vector2(16, -14), Vector2(16, 12),
				Vector2(6, 16), Vector2(-6, 12), Vector2(-16, 16), Vector2(-16, -10)]), col, w * 0.8, true)
			ci.draw_line(c + Vector2(-6, -14) * k, c + Vector2(-6, 12) * k, col, w * 0.6, true)
			ci.draw_line(c + Vector2(6, -10) * k, c + Vector2(6, 16) * k, col, w * 0.6, true)
		"lock":
			ci.draw_rect(Rect2(c + Vector2(-12, -2) * k, Vector2(24, 18) * k), col)
			ci.draw_arc(c + Vector2(0, -2) * k, 8 * k, PI, TAU, 10, col, w * 1.2, true)
			ci.draw_circle(c + Vector2(0, 6) * k, 2.5 * k, P.NIGHT, true, -1.0, true)
		"buis":
			ci.draw_rect(Rect2(c + Vector2(-14, -7) * k, Vector2(28, 14) * k), col, false, w)
			ci.draw_line(c + Vector2(-6, -7) * k, c + Vector2(-6, 7) * k, col, w * 0.7, true)
			ci.draw_line(c + Vector2(6, -7) * k, c + Vector2(6, 7) * k, col, w * 0.7, true)
		"koerier":
			courier(ci, c + Vector2(0, 18) * k, 0.55 * k, col)
		"tik":
			ci.draw_line(c + Vector2(0, -16) * k, c + Vector2(0, 6) * k, col, w, true)
			ci.draw_colored_polygon(_sc(c, k, [Vector2(-4, 4), Vector2(4, 4), Vector2(0, 12)]), col)
			ci.draw_line(c + Vector2(-14, 14) * k, c + Vector2(14, 14) * k, col, w, true)


# ================================================================ helpers
static func _sc(o: Vector2, s: float, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(o + p * s)
	return out


static func _ell(c: Vector2, rx: float, ry: float, rot := 0.0, n := 32) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out


# ================================================================ TITEL & UI-ONDERDELEN
## Logo: "TELEX" op een breed telexlint met ITA2-gaten. typed = aantal getypte letters (fractie = hamer valt),
## c = midden, k = schaal (1 = letters 150 px).
static func logo(ci: CanvasItem, c: Vector2, k := 1.0, typed := 5.0, word := "TELEX") -> Rect2:
	var cell := 150.0 * k
	var n := word.length()
	var h := 290.0 * k
	var w := n * cell + 160 * k
	var r := Rect2(c - Vector2(w, h) / 2.0, Vector2(w, h))
	ci.draw_rect(Rect2(r.position + Vector2(8, 16) * k, r.size), Color(0, 0, 0, 0.45))
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(1.15, 1.09, 0.95))
	ci.draw_rect(Rect2(r.position, Vector2(w, 5 * k)), P.PAPER_HI)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 14 * k, w, 14 * k), Color(P.PAPER_EDGE, 0.35))
	_torn_edge(ci, r.position.x, r.position.y, h, true)
	# ITA2-gaten (groot) + transportgaatjes
	var x0 := r.position.x + 80 * k
	for i in n:
		var cx := x0 + (i + 0.5) * cell
		if float(i) >= typed:
			continue
		var code := P.ita2(word[i])
		var row := 0
		for j in 6:
			var yy := r.position.y + (22 + j * 15) * k
			if j == 2:
				ci.draw_circle(Vector2(cx, yy), 3.5 * k, Color(P.NIGHT, 0.7), true, -1.0, true)
				continue
			if code[row] == "1":
				ci.draw_circle(Vector2(cx, yy), 6.5 * k, Color(P.NIGHT, 0.75), true, -1.0, true)
			row += 1
		var a := clampf(typed - i, 0.0, 1.0)
		var off := (1.0 - a) * -18.0 * k
		P.text_c(ci, P.TAPE, Vector2(cx + 3 * k, r.position.y + 190 * k + off + 3 * k), word[i], int(190 * k), Color(P.INK, 0.25 * a))
		P.text_c(ci, P.TAPE, Vector2(cx, r.position.y + 190 * k + off), word[i], int(190 * k), Color(P.INK, a))
	return r


## Tuimelschakelaar (instellingen aan/uit). on = 0..1 (animatie).
static func toggle(ci: CanvasItem, c: Vector2, on: float, label := "") -> void:
	var plate := Rect2(c - Vector2(30, 46), Vector2(60, 92))
	ci.draw_style_box(P.sb(P.SHADOW, 8), Rect2(plate.position + Vector2(1, 4), plate.size))
	ci.draw_style_box(P.sb(P.STEEL_LO, 8), plate)
	ci.draw_style_box(P.sb(P.STEEL, 7), plate.grow(-2))
	P.screw(ci, c + Vector2(0, -36), 4.0)
	P.screw(ci, c + Vector2(0, 36), 4.0, 1.2)
	ci.draw_circle(c, 13, P.STEEL_LO, true, -1.0, true)
	var ang := lerpf(0.5, -0.5, on) + PI / 2
	var tip := c + Vector2(cos(ang + PI), sin(ang + PI)) * 30
	ci.draw_line(c, tip, P.STEEL_HI, 9.0, true)
	ci.draw_circle(tip, 7, P.BAKELITE, true, -1.0, true)
	P.lamp(ci, c + Vector2(50, 0), 7, P.SIG_EQ, on)
	P.text_c(ci, P.STENCIL, c + Vector2(0, -60), "AAN" if on > 0.5 else "UIT", 13, P.TEXT_DIM)
	if label != "":
		P.text_c(ci, P.UI, c + Vector2(0, 66), label, 18, P.TEXT)


## Schuifregelaar (muziek/geluid): messing knop in een sleuf, u 0..1.
static func fader(ci: CanvasItem, r: Rect2, u: float, label := "") -> void:
	P.well(ci, Rect2(r.position.x, r.get_center().y - 6, r.size.x, 12), P.NIGHT, 6)
	for k in 11:
		var x := r.position.x + r.size.x * k / 10.0
		ci.draw_line(Vector2(x, r.get_center().y + 14), Vector2(x, r.get_center().y + (22 if k % 5 == 0 else 18)), P.TEXT_DIM, 1.5)
	ci.draw_rect(Rect2(r.position.x + 2, r.get_center().y - 3, (r.size.x - 4) * u, 6), Color(P.SIG_AMBER, 0.8))
	var kx := r.position.x + r.size.x * u
	var kr := Rect2(kx - 14, r.get_center().y - 22, 28, 44)
	ci.draw_style_box(P.sb(P.SHADOW, 6), Rect2(kr.position + Vector2(1, 4), kr.size))
	ci.draw_style_box(P.sb(P.BRASS_LO, 6), kr)
	ci.draw_style_box(P.sb(P.BRASS, 5), kr.grow(-2))
	for k in 3:
		ci.draw_line(Vector2(kr.position.x + 6, kr.position.y + 14 + k * 8), Vector2(kr.end.x - 6, kr.position.y + 14 + k * 8), P.BRASS_LO, 1.5)
	if label != "":
		P.text_l(ci, P.UI, Vector2(r.position.x, r.position.y - 6), label, 18, P.TEXT)


## Levelkaartje in de waaier van een dossiermap: nummer, titel, 0–3 sterren, pictogram van de mechaniek.
static func level_card(ci: CanvasItem, c: Vector2, rot: float, num: String, title: String, stars_n: int, icon_name: String, locked := false, hl := false) -> void:
	ci.draw_set_transform(c, rot, Vector2.ONE)
	var r := Rect2(-70, -96, 140, 192)
	ci.draw_rect(Rect2(r.position + Vector2(4, 8), r.size), P.SHADOW)
	var col := P.CARD if not locked else P.CARD.darkened(0.4)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(col.r * 1.15, col.g * 1.15, col.b * 1.12))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 34)), Color(P.STAMP_BLUE, 0.85) if not locked else P.SIG_GREY)
	P.text_c(ci, P.STENCIL, Vector2(0, -79), num, 22, P.PAPER_HI)
	if locked:
		icon(ci, "lock", Vector2(0, 0), 46, P.INK_SOFT)
	else:
		icon(ci, icon_name, Vector2(0, -22), 46, P.INK)
		var lines := title.split("\n")
		for i in lines.size():
			P.text_c(ci, P.TAPE, Vector2(0, 26 + i * 20), lines[i], 17, P.INK)
		for i in 3:
			star(ci, Vector2(-34 + i * 34, 76), 12, P.BRASS if i < stars_n else Color(0, 0, 0, 0), P.BRASS_LO if i < stars_n else P.INK_SOFT)
	if hl:
		ci.draw_rect(r.grow(4), P.SIG_AMBER, false, 3.0)
	ci.draw_set_transform(Vector2.ZERO)


## Rode draad tussen twee spelden (missiekaart).
static func thread(ci: CanvasItem, a: Vector2, b: Vector2, sag := 24.0) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var s := float(i) / 16.0
		pts.append(a.lerp(b, s) + Vector2(0, sag * 4.0 * s * (1.0 - s)))
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(3, 5))
	ci.draw_polyline(sh, Color(0, 0, 0, 0.3), 3.0, true)
	ci.draw_polyline(pts, Color("#B3261E"), 2.5, true)


## Stempel uit art/stamps/ (wit, wordt getint). s = schaal, squash 0..1 (landt), a = alfa.
static func stamp(ci: CanvasItem, name: String, c: Vector2, col: Color, s := 1.0, rot := 0.0, a := 0.9) -> void:
	var tx := P.tex("stamps/%s.png" % name)
	var sz := tx.get_size() * s
	ci.draw_set_transform(c, rot, Vector2.ONE)
	ci.draw_texture_rect(tx, Rect2(-sz / 2.0, sz), false, Color(col, a))
	ci.draw_set_transform(Vector2.ZERO)


## Tellerbalk in de debrief (jouw tikken / optimum / brute kracht).
static func tally_bar(ci: CanvasItem, pos: Vector2, w: float, label: String, v: int, vmax: int, col: Color) -> void:
	P.text_l(ci, P.TAPE, pos + Vector2(0, 12), label, 20, P.INK)
	var r := Rect2(pos.x + 190, pos.y, w, 26)
	ci.draw_rect(r, Color(P.INK, 0.08))
	ci.draw_rect(Rect2(r.position, Vector2(w * clampf(float(v) / vmax, 0.0, 1.0), 26)), col)
	ci.draw_rect(r, Color(P.INK, 0.4), false, 1.0)
	P.text_l(ci, P.MONO, Vector2(r.end.x + 12, r.get_center().y), str(v), 20, P.INK)
