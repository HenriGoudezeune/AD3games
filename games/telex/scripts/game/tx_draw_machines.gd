class_name TxDrawMachines
extends Object
## TELEX — tekenfuncties voor de machinepanelen (design/ART.md §6): hashwiel, kaartenbak, ponsbank,
## lampenbord + matrixlog, ruisbord + foutkabel, schakelbord/zoeklicht + herstelstrook.

const P := preload("res://games/telex/scripts/game/tx_pal.gd")
const D := preload("res://games/telex/scripts/game/tx_draw.gd")


# ================================================================ VINGERAFDRUK (Rabin-Karp)
## Hashwiel: tandwiel met q tanden 0..q−1. pos = stand onder de wijzer (mag fractioneel zijn tijdens het draaien),
## notch = h(z) (rode inkeping, −1 = nog niet geijkt), alarm 0..1 (wijzer op de inkeping: rode gloed).
static func wheel(ci: CanvasItem, c: Vector2, R: float, q: int, pos: float, notch := -1, alarm := 0.0) -> void:
	var step := TAU / q
	var rot := -pos * step          # tand `pos` staat bovenaan (hoek −PI/2)
	# schaduw + tanden
	ci.draw_circle(c + Vector2(4, 8), R + 14, P.SHADOW, true, -1.0, true)
	var pts := PackedVector2Array()
	var teeth := q
	for i in teeth:
		var a0 := -PI / 2 + rot + i * step
		for k in 4:
			var u: float = [-0.36, -0.2, 0.2, 0.36][k]
			var rr: float = R + (16.0 if absf(u) < 0.3 else 2.0)
			pts.append(c + Vector2(cos(a0 + u * step), sin(a0 + u * step)) * rr)
	ci.draw_colored_polygon(pts, P.BRASS_LO)
	ci.draw_circle(c, R + 1, P.BRASS_LO, true, -1.0, true)
	ci.draw_circle(c, R - 3, P.BRASS, true, -1.0, true)
	# glanzende ring + geborsteld vlak
	ci.draw_arc(c, R - 8, PI * 1.05, PI * 1.6, 24, Color(P.BRASS_HI, 0.8), 3.0, true)
	ci.draw_circle(c, R * 0.72, P.BRASS.darkened(0.08), true, -1.0, true)
	ci.draw_arc(c, R * 0.72, 0, TAU, 64, P.BRASS_LO, 2.0, true)
	# spaken en uitsparingen
	for k in 5:
		var a := rot + k * TAU / 5.0 + 0.3
		var hole := c + Vector2(cos(a), sin(a)) * R * 0.45
		ci.draw_circle(hole, R * 0.15, P.CONSOLE_LO, true, -1.0, true)
		ci.draw_arc(hole, R * 0.15, PI * 0.2, PI * 1.1, 10, Color(0, 0, 0, 0.4), 2.0, true)
	# cijfers op de rand
	for i in q:
		var a := -PI / 2 + rot + i * step
		var p := c + Vector2(cos(a), sin(a)) * (R - 22)
		var col := P.TEXT_ON_BRASS
		if i == notch:
			col = P.STAMP_RED.darkened(0.2)
		P.text_c(ci, P.MONO, p, str(i), int(clampf(R * 0.16, 14, 26)), col)
		ci.draw_line(c + Vector2(cos(a + step / 2), sin(a + step / 2)) * (R - 8), c + Vector2(cos(a + step / 2), sin(a + step / 2)) * (R - 34), Color(P.BRASS_LO, 0.6), 1.5, true)
	# rode inkeping op tand h(z)
	if notch >= 0:
		var a := -PI / 2 + rot + notch * step
		var d := Vector2(cos(a), sin(a))
		var nrm := Vector2(-d.y, d.x)
		ci.draw_colored_polygon(PackedVector2Array([c + d * (R + 17) + nrm * 7, c + d * (R + 17) - nrm * 7, c + d * (R + 2)]), P.STAMP_RED)
	# naaf
	ci.draw_circle(c, R * 0.2, P.BAKELITE, true, -1.0, true)
	ci.draw_circle(c, R * 0.2 - 4, P.BAKELITE_HI, true, -1.0, true)
	P.text_c(ci, P.STENCIL, c, "mod " + str(q), int(clampf(R * 0.1, 12, 18)), P.BRASS_HI)
	# wijzer bovenaan (vast)
	var top := c + Vector2(0, -R - 18)
	ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-16, -26), top + Vector2(16, -26), top + Vector2(0, 8)]), P.STEEL_LO)
	ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-12, -23), top + Vector2(12, -23), top + Vector2(0, 3)]), P.STEEL_HI)
	if alarm > 0.0:
		P.glow(ci, top, 140, P.SIG_NE, 0.6 * alarm)


## Klein tandwieltje "−w" dat in het grote wiel grijpt. engaged 0..1 schuift het naar het wiel.
static func minus_w_gear(ci: CanvasItem, c: Vector2, w: int, spin := 0.0, engaged := 0.0) -> void:
	var r := 34.0
	var cc := c + Vector2(18 * engaged, 0)
	var pts := PackedVector2Array()
	for i in 24:
		var a := spin + TAU * i / 24.0
		var rr := r + (8.0 if (i % 2) == 0 else 0.0)
		pts.append(cc + Vector2(cos(a), sin(a)) * rr)
	ci.draw_circle(cc + Vector2(3, 5), r + 8, P.SHADOW, true, -1.0, true)
	ci.draw_colored_polygon(pts, P.STEEL_LO)
	ci.draw_circle(cc, r - 2, P.STEEL, true, -1.0, true)
	ci.draw_circle(cc, r - 12, P.STEEL_LO, true, -1.0, true)
	P.text_c(ci, P.MONO, cc, "−" + str(w), 22, P.STEEL_HI)


## Drie hendels ×2 / −w / +1 in sleuven. pull = {naam: 0..1}, disabled = {naam: true} (bv. −w vóór het ijken).
static func wheel_levers(ci: CanvasItem, pos: Vector2, pull := {}, disabled := {}) -> void:
	var names := ["×2", "−w", "+1"]
	var keys := ["D", "W", "1"]
	for i in 3:
		var x := pos.x + i * 92
		var slot := Rect2(x - 9, pos.y, 18, 150)
		P.well(ci, slot, P.NIGHT, 9)
		var u: float = pull.get(names[i], 0.0)
		var ky := pos.y + 18 + u * 110
		ci.draw_rect(Rect2(x - 4, pos.y + 8, 8, ky - pos.y - 8), P.STEEL)
		var off: bool = disabled.get(names[i], false)
		var kc := P.BAKELITE if not off else P.BAKELITE.darkened(0.4)
		ci.draw_circle(Vector2(x, ky) + Vector2(2, 4), 24, P.SHADOW, true, -1.0, true)
		ci.draw_circle(Vector2(x, ky), 24, kc, true, -1.0, true)
		ci.draw_circle(Vector2(x - 6, ky - 7), 9, Color(1, 1, 1, 0.07), true, -1.0, true)
		ci.draw_arc(Vector2(x, ky), 24, 0, TAU, 32, P.BRASS_LO if not off else P.STEEL_LO, 2.0, true)
		P.text_c(ci, P.UI_BOLD, Vector2(x, ky), names[i], 22, P.BRASS_HI if not off else P.TEXT_DIM)
		D.keycap(ci, Vector2(x - 14, pos.y + 160), keys[i], 15)


## Bitvenster: het venster t[i..i+m−1] als m lampjes met gewichten 2^(m−1)..1, het uitgaande bit links (vervaagt)
## en het inkomende bit rechts (licht op). slide 0..1 = schuif-animatie.
static func bit_window(ci: CanvasItem, pos: Vector2, bits: String, out_bit := "", in_bit := "", slide := 1.0) -> Rect2:
	var m := bits.length()
	var cw := 58.0
	var r := Rect2(pos, Vector2((m + 2) * cw + 24, 110))
	P.panel(ci, r, P.CONSOLE_HI, false, 8)
	P.text_l(ci, P.STENCIL, pos + Vector2(14, 16), "BITVENSTER", 14, P.TEXT_DIM)
	for k in m + 2:
		var x := pos.x + 12 + k * cw + cw / 2
		var bit := ""
		var a := 1.0
		if k == 0:
			bit = out_bit
			a = 0.35 + 0.65 * (1.0 - slide)
		elif k == m + 1:
			bit = in_bit
			a = 0.35 + 0.65 * slide
		else:
			bit = bits[k - 1]
		if bit == "":
			continue
		var on := bit == "1"
		var c := Vector2(x, pos.y + 52)
		P.lamp(ci, c, 17, P.SIG_WHITE if (k > 0 and k <= m) else P.SIG_AMBER, (1.0 if on else 0.0) * a)
		P.text_c(ci, P.MONO, c, bit, 20, Color(P.INK if on else P.TEXT_DIM, a))
		if k > 0 and k <= m:
			P.text_c(ci, P.MONO, Vector2(x, pos.y + 92), str(1 << (m - k)), 15, P.TEXT_DIM)
		else:
			P.text_c(ci, P.UI, Vector2(x, pos.y + 92), "uit" if k == 0 else "in", 15, Color(P.SIG_AMBER, a))
	ci.draw_rect(Rect2(pos.x + 12 + cw, pos.y + 28, m * cw, 76), Color(P.BRASS, 0.6), false, 2.0)
	return r


## Alarmlampje (knippert 3 Hz) met de drie knoppen Controleer / Meld meteen / Negeer.
static func alarm_panel(ci: CanvasItem, pos: Vector2, blink := 0.0, compact := false) -> Rect2:
	if compact:
		return _alarm_compact(ci, pos, blink)
	var r := Rect2(pos, Vector2(300, 250))
	P.panel(ci, r, P.CONSOLE_HI, true, 10)
	var c := pos + Vector2(150, 64)
	ci.draw_circle(c + Vector2(0, 30), 46, P.STEEL_LO, true, -1.0, true)
	ci.draw_rect(Rect2(c + Vector2(-46, 0), Vector2(92, 30)), P.STEEL_LO)
	var on := blink
	ci.draw_circle(c, 40, P.SIG_NE_DIM.lerp(P.SIG_NE, on), true, -1.0, true)
	if on > 0.0:
		P.glow(ci, c, 220, P.SIG_NE, 0.7 * on)
	ci.draw_circle(c + Vector2(-12, -14), 12, Color(1, 1, 1, 0.18 + 0.2 * on), true, -1.0, true)
	for k in 3:
		ci.draw_arc(c, 40 - k * 9, PI * 1.15, PI * 1.85, 10, Color(0, 0, 0, 0.2), 1.5, true)
	var labels := [["Controleer", "C", P.BRASS], ["Meld", "M", Color("#8E2A20")], ["Negeer", "N", P.BAKELITE_HI]]
	for i in 3:
		var br := Rect2(pos.x + 14 + i * 94, pos.y + 160, 86, 72)
		P.box(ci, Rect2(br.position + Vector2(0, 5), br.size), Color(labels[i][2]).darkened(0.5), 8)
		P.box(ci, br, labels[i][2], 8)
		var fg := P.TEXT_ON_BRASS if i == 0 else P.TEXT
		P.text_c(ci, P.UI_BOLD, br.get_center() + Vector2(0, -8), labels[i][0], 17, fg)
		P.text_c(ci, P.MONO, br.get_center() + Vector2(0, 18), labels[i][1], 14, Color(fg, 0.7))
	return r


static func _alarm_compact(ci: CanvasItem, pos: Vector2, blink: float) -> Rect2:
	var r := Rect2(pos, Vector2(170, 330))
	P.panel(ci, r, P.CONSOLE_HI, true, 10)
	var c := pos + Vector2(85, 70)
	ci.draw_circle(c + Vector2(0, 4), 44, P.STEEL_LO, true, -1.0, true)
	ci.draw_circle(c, 38, P.SIG_NE_DIM.lerp(P.SIG_NE, blink), true, -1.0, true)
	if blink > 0.0:
		P.glow(ci, c, 220, P.SIG_NE, 0.7 * blink)
	ci.draw_circle(c + Vector2(-12, -14), 11, Color(1, 1, 1, 0.18 + 0.2 * blink), true, -1.0, true)
	P.text_c(ci, P.STENCIL, c + Vector2(0, 56), "ALARM", 14, P.TEXT_DIM)
	var labels := [["Controleer", "C", P.BRASS], ["Meld meteen", "M", Color("#8E2A20")], ["Negeer", "N", P.BAKELITE_HI]]
	for i in 3:
		var br := Rect2(pos.x + 12, pos.y + 152 + i * 58, 146, 48)
		P.box(ci, Rect2(br.position + Vector2(0, 4), br.size), Color(labels[i][2]).darkened(0.5), 8)
		P.box(ci, br, labels[i][2], 8)
		var fg := P.TEXT_ON_BRASS if i == 0 else P.TEXT
		P.text_l(ci, P.UI_BOLD, Vector2(br.position.x + 12, br.get_center().y), labels[i][0], 18, fg)
		P.text_r(ci, P.MONO, Vector2(br.end.x - 10, br.get_center().y), labels[i][1], 14, Color(fg, 0.7))
	return r


# ================================================================ SPRINGER (Boyer-Moore-Horspool)
## Indexkaart van de kaartenbak: grote letter + gestempelde waarde. old ≥ 0 = vorige waarde doorgestreept (0..1 = streep).
static func index_card(ci: CanvasItem, r: Rect2, letter: String, v, old := -1, strike := 1.0, hl := false) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 4), r.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(P.CARD.r * 1.15, P.CARD.g * 1.15, P.CARD.b * 1.12))
	ci.draw_rect(Rect2(r.position.x, r.position.y + 30, r.size.x, 1.5), Color(P.STAMP_RED, 0.55))
	for k in 3:
		ci.draw_line(Vector2(r.position.x + 6, r.position.y + 46 + k * 14), Vector2(r.end.x - 6, r.position.y + 46 + k * 14), Color(P.STAMP_BLUE, 0.15), 1.0)
	var big := letter.length() == 1
	P.text_c(ci, P.TAPE, Vector2(r.get_center().x, r.position.y + 16), letter, 26 if big else 15, P.INK)
	if old >= 0:
		P.text_c(ci, P.TAPE, Vector2(r.position.x + r.size.x * 0.3, r.position.y + 58), str(old), 26, Color(P.STAMP_RED, 0.55))
		ci.draw_line(Vector2(r.position.x + r.size.x * 0.12, r.position.y + 64), Vector2(r.position.x + r.size.x * (0.12 + 0.36 * strike), r.position.y + 50), P.STAMP_RED, 2.5, true)
	if v != null:
		var vx := r.get_center().x + (r.size.x * 0.16 if old >= 0 else 0.0)
		P.text_c(ci, P.STENCIL, Vector2(vx + 1, r.position.y + 61), str(v), 34, Color(P.STAMP_RED, 0.25))
		P.text_c(ci, P.STENCIL, Vector2(vx, r.position.y + 60), str(v), 34, P.STAMP_RED)
	if hl:
		ci.draw_rect(r.grow(3), P.SIG_AMBER, false, 3.0)


## Kaartenbak (V_H): houten bak met staande kaarten. cards = [[letter, waarde], ...] (laatste = "overige"),
## pulled = index van de getrokken kaart (−1 = geen), pull 0..1 = hoe ver ze eruit is.
static func card_box(ci: CanvasItem, r: Rect2, cards: Array, pulled := -1, pull := 0.0) -> void:
	var n := cards.size()
	var cw := minf(86.0, (r.size.x - 40) / maxf(n, 1) - 10)
	var ch := 92.0
	# achterwand
	ci.draw_rect(Rect2(r.position + Vector2(6, 10), r.size), P.SHADOW)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), P.WOOD_LO)
	for i in n:
		var cr := Rect2(r.position.x + 20 + i * (cw + 10), r.position.y + 14 - (ch * 0.9 * pull if i == pulled else 0.0), cw, ch)
		if i == pulled:
			continue
		index_card(ci, cr, cards[i][0], cards[i][1])
	# voorkant van de bak (hout) met messing label
	var front := Rect2(r.position.x - 8, r.position.y + r.size.y * 0.45, r.size.x + 16, r.size.y * 0.55)
	ci.draw_rect(front, P.WOOD)
	for k in 4:
		var yy := front.position.y + 8 + k * front.size.y / 4.0
		ci.draw_line(Vector2(front.position.x + 6, yy), Vector2(front.end.x - 6, yy + 2 * sin(k * 1.3)), Color(P.WOOD_LO, 0.45), 1.2)
	ci.draw_rect(Rect2(front.position, Vector2(front.size.x, 4)), P.WOOD_HI)
	P.brass_plate(ci, front.get_center() + Vector2(0, 4), "KAARTENBAK  V_H", 18)
	if pulled >= 0 and pulled < n:
		var cr := Rect2(r.position.x + 20 + pulled * (cw + 10), r.position.y + 14 - (ch + 30) * pull, cw, ch)
		ci.draw_set_transform(cr.get_center(), -0.12 * pull, Vector2.ONE * (1.0 + 0.15 * pull))
		index_card(ci, Rect2(-cr.size / 2.0, cr.size), cards[pulled][0], cards[pulled][1], -1, 1.0, true)
		ci.draw_set_transform(Vector2.ZERO)


## Sprongboog boven het lint (Springer): van kolom x_from naar x_to, u 0..1 = voortgang; trail = luchtspoor.
static func jump_arc(ci: CanvasItem, x_from: float, x_to: float, y: float, u := 1.0, label := "", hmax := 120.0) -> void:
	var h := clampf(absf(x_to - x_from) * 0.35, minf(30.0, hmax), hmax)
	var pts := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var s := float(i) / n * u
		pts.append(Vector2(lerpf(x_from, x_to, s), y - h * 4.0 * s * (1.0 - s)))
	if pts.size() > 1:
		ci.draw_polyline(pts, Color(P.SIG_AMBER, 0.85), 3.0, true)
		var e := pts[pts.size() - 1]
		var d := (e - pts[pts.size() - 2]).normalized()
		ci.draw_colored_polygon(PackedVector2Array([e + d * 10, e + d.rotated(2.4) * 10, e + d.rotated(-2.4) * 10]), P.SIG_AMBER)
	if label != "":
		P.text_l(ci, P.UI_BOLD, Vector2(maxf(x_from, x_to) + 18, y - h * 0.5), label, 22, P.SIG_AMBER)


# ================================================================ PONSBANK (Algoritme 5)
## Ponskop boven vakjes a..b van de strook (x0 = vakje 0) + draaiknop voor de waarde. hit 0..1 = slaat.
static func punch_head(ci: CanvasItem, x0: float, y_strip: float, cell: float, a: int, b: int, v: int, hit := 0.0) -> void:
	var xa := x0 + a * cell
	var xb := x0 + (b + 1) * cell
	var top := y_strip - 40 + 12 * hit
	for k in range(a, b + 1):
		var cx := x0 + (k + 0.5) * cell
		ci.draw_rect(Rect2(cx - 5, top + 8, 10, 26), P.STEEL)
		ci.draw_rect(Rect2(cx - 5, top + 8, 3, 26), P.STEEL_HI)
	var hr := Rect2(xa - 6, top - 6, xb - xa + 12, 16)
	P.box(ci, hr, P.BRASS, 4, 3)
	ci.draw_rect(Rect2(hr.position + Vector2(3, 2), Vector2(hr.size.x - 6, 3)), Color(P.BRASS_HI, 0.7))
	var lr := Rect2(xb + 14, top - 10, 120, 26)
	P.box(ci, lr, P.BAKELITE, 5)
	P.text_c(ci, P.MONO_B, lr.get_center(), "%d..%d = %d" % [a, b, v], 15, P.BRASS_HI)
	if hit > 0.9:
		P.glow(ci, Vector2((xa + xb) / 2.0, y_strip), (xb - xa) * 1.4, P.SIG_WHITE, 0.4)


# ================================================================ LAMPENBORD (shift-AND) + RUISBORD
## Lampkolom M[][j]: m lampen, rij 0 boven. bits = String "101" (rij 0 eerst), letters = z (labels links).
## drop 0..1 = schuif-animatie (lampen glijden één rij omlaag), bell 0..1 = onderste lamp flitst.
static func lamp_column(ci: CanvasItem, x: float, y: float, z: String, bits: String, pitch := 62.0, col := P.SIG_EQ,
		drop := 0.0, bell := 0.0, labels := true, title := "") -> Rect2:
	var m := z.length()
	var r := Rect2(x - 46, y - 40, 92, m * pitch + 52)
	P.panel(ci, r, P.CONSOLE_HI, false, 10)
	if title != "":
		P.text_c(ci, P.STENCIL, Vector2(x, y - 22), title, 18, col)
	for i in m:
		var c := Vector2(x, y + i * pitch + 10 + drop * pitch * 0.0)
		var on := bits.length() > i and bits[i] == "1"
		var st := 1.0 if on else 0.0
		if i == m - 1 and bell > 0.0:
			st = maxf(st, bell)
		P.lamp(ci, c, 20, col, st, "dot" if on else "")
		if labels:
			var tag := Rect2(x - 92, c.y - 17, 36, 34)
			ci.draw_rect(Rect2(tag.position + Vector2(1, 3), tag.size), P.SHADOW)
			ci.draw_rect(tag, P.CARD)
			P.text_c(ci, P.TAPE, tag.get_center() + Vector2(0, 1), z[i], 26, P.INK)
			P.text_c(ci, P.MONO, Vector2(x - 108, c.y), str(i), 14, P.TEXT_DIM)
	if bell > 0.0:
		var bc := Vector2(x, y + (m - 1) * pitch + 10)
		P.glow(ci, bc, 200 * bell, col, 0.5 * bell)
	return r


## Grote hendel (shift¹). u 0..1 = omlaag getrokken.
static func lever(ci: CanvasItem, x: float, y: float, h: float, u := 0.0, label := "S") -> void:
	var slot := Rect2(x - 11, y, 22, h)
	P.well(ci, slot, P.NIGHT, 10)
	ci.draw_rect(Rect2(x - 26, y - 8, 52, 12), P.STEEL_LO)
	ci.draw_rect(Rect2(x - 26, y + h - 4, 52, 12), P.STEEL_LO)
	var ky := y + 14 + u * (h - 28)
	var piv := Vector2(x, y + h * 0.5)
	ci.draw_line(Vector2(x, ky), Vector2(x + 54, ky - 10), P.STEEL, 9.0, true)
	ci.draw_line(Vector2(x, ky - 2), Vector2(x + 54, ky - 12), P.STEEL_HI, 2.5, true)
	ci.draw_circle(Vector2(x, ky), 10, P.STEEL_LO, true, -1.0, true)
	var kb := Vector2(x + 62, ky - 12)
	ci.draw_circle(kb + Vector2(3, 5), 21, P.SHADOW, true, -1.0, true)
	ci.draw_circle(kb, 21, Color("#9E2A1E"), true, -1.0, true)
	ci.draw_circle(kb - Vector2(6, 7), 8, Color(1, 1, 1, 0.3), true, -1.0, true)
	D.keycap(ci, Vector2(x - 14, y + h + 16), label, 15)


## Ponskaart C_x (verticaal): kop met de letter, gaten op rij i als bits[i] = "1". pitch zoals de lampkolom.
## inserted = kaart steekt in het rek (lichter, licht door de gaten), cursor = rij waarop de ponskop staat (−1 geen).
static func punch_card(ci: CanvasItem, x: float, y: float, letter: String, bits: String, pitch := 62.0, inserted := false, cursor := -1, w := 58.0) -> Rect2:
	var m := bits.length()
	var r := Rect2(x - w / 2, y - 52, w, m * pitch + 64)
	ci.draw_rect(Rect2(r.position + Vector2(2, 5), r.size), P.SHADOW)
	var tint := P.MANILA if not inserted else P.MANILA.lightened(0.15)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(tint.r * 1.2, tint.g * 1.2, tint.b * 1.18))
	# afgeknipte hoek (zoals echte ponskaarten)
	ci.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(14, 0), r.position + Vector2(0, 14)]), P.CONSOLE_HI)
	var head := Rect2(r.position.x, r.position.y + 6, w, 34)
	P.text_c(ci, P.TAPE, head.get_center(), letter, 28 if letter.length() == 1 else 15, P.INK)
	ci.draw_line(Vector2(r.position.x + 4, head.end.y), Vector2(r.end.x - 4, head.end.y), Color(P.INK, 0.4), 1.0)
	for i in m:
		var c := Vector2(x, y + i * pitch + 10)
		ci.draw_rect(Rect2(c.x - w / 2 + 6, c.y - 13, w - 12, 26), Color(P.MANILA_LO, 0.35), false, 1.0)
		P.text_c(ci, P.MONO, Vector2(r.position.x + 8, c.y - 16), str(i), 10, Color(P.INK, 0.4))
		if bits[i] == "1":
			ci.draw_style_box(P.sb(P.NIGHT, 4), Rect2(c.x - 9, c.y - 12, 18, 24))
			if inserted:
				P.glow(ci, c, 70, P.SIG_WHITE, 0.8)
				ci.draw_style_box(P.sb(P.SIG_WHITE, 4), Rect2(c.x - 9, c.y - 12, 18, 24))
		if i == cursor:
			ci.draw_rect(Rect2(c.x - w / 2 + 3, c.y - 15, w - 6, 30), P.SIG_AMBER, false, 2.5)
	return r


## Matrixlog: papieren uitdraai van M (of M^k), kolom per kolom getypt, zoals de tabel in de notas.
## t = tekst (kolomkoppen), z = rijen, cols = Array van bitstrings (rij 0 eerst) voor j = 0..cols.size()−1,
## cur = kolom die nu gedrukt wordt, boxes = [[j_end, kleur]] diagonale kaders (Figuur 23).
static func matrix_log(ci: CanvasItem, r: Rect2, t: String, z: String, cols: Array, cur := -1, boxes := [], title := "M") -> void:
	ci.draw_rect(Rect2(r.position + Vector2(4, 8), r.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(1.17, 1.12, 1.0))
	# kettinggaten links en rechts (kettingpapier)
	for k in int(r.size.y / 24):
		for x in [r.position.x + 10, r.end.x - 10]:
			ci.draw_circle(Vector2(x, r.position.y + 14 + k * 24), 4, Color(P.NIGHT, 0.75), true, -1.0, true)
	ci.draw_line(Vector2(r.position.x + 22, r.position.y), Vector2(r.position.x + 22, r.end.y), Color(P.PAPER_EDGE, 0.8), 1.0)
	ci.draw_line(Vector2(r.end.x - 22, r.position.y), Vector2(r.end.x - 22, r.end.y), Color(P.PAPER_EDGE, 0.8), 1.0)
	var m := z.length()
	var n := t.length()
	var cw := minf(40.0, (r.size.x - 110) / maxf(n, 1))
	var rh := minf(38.0, (r.size.y - 90) / maxf(m, 1))
	var ox := r.position.x + 70
	var oy := r.position.y + 62
	if title.contains("^"):
		var parts := title.split("^")
		sup_label(ci, r.position + Vector2(52, 26), parts[0], parts[1], 26, P.INK)
	else:
		P.text_l(ci, P.TAPE, r.position + Vector2(32, 26), title, 26, P.INK)
	for j in n:
		var cx := ox + (j + 0.5) * cw
		P.text_c(ci, P.TAPE, Vector2(cx, oy - 18), t[j], 22, P.INK)
		P.text_c(ci, P.MONO, Vector2(cx, oy - 40), str(j), 11, P.INK_SOFT)
	ci.draw_line(Vector2(ox - 4, oy - 2), Vector2(ox + n * cw, oy - 2), Color(P.INK, 0.5), 1.0)
	for i in m:
		var cy := oy + (i + 0.5) * rh
		P.text_c(ci, P.TAPE, Vector2(ox - 24, cy), z[i], 22, P.INK)
	ci.draw_line(Vector2(ox - 4, oy - 2), Vector2(ox - 4, oy + m * rh), Color(P.INK, 0.5), 1.0)
	if cur >= 0 and cur < n:
		ci.draw_rect(Rect2(ox + cur * cw + 1, oy - 30, cw - 2, m * rh + 32), Color(P.SIG_AMBER, 0.18))
	for j in cols.size():
		var bits: String = cols[j]
		for i in mini(m, bits.length()):
			var on := bits[i] == "1"
			var c := Vector2(ox + (j + 0.5) * cw, oy + (i + 0.5) * rh)
			P.text_c(ci, P.TAPE, c, bits[i], 22 if on else 20, P.INK if on else Color(P.INK, 0.35))
			if on and i == m - 1:
				ci.draw_arc(c, 13, 0, TAU, 20, P.STAMP_RED, 2.0, true)
	for b in boxes:
		var je: int = b[0]
		var colr: Color = b[1]
		var pts := PackedVector2Array()
		for i in m:
			pts.append(Vector2(ox + (je - (m - 1) + i + 0.5) * cw, oy + (i + 0.5) * rh))
		ci.draw_polyline(pts, Color(colr, 0.8), 3.0, true)


## Superscript-label zoals M⁰, M¹ (fonts hebben niet altijd superscriptcijfers).
static func sup_label(ci: CanvasItem, c: Vector2, base: String, sup: String, size := 24, col := P.TEXT) -> void:
	var w := P.text_w(P.TAPE, base, size)
	var ws := P.text_w(P.MONO, sup, int(size * 0.6))
	var x := c.x - (w + ws) / 2.0
	P.text_l(ci, P.TAPE, Vector2(x, c.y), base, size, col)
	P.text_l(ci, P.MONO, Vector2(x + w + 1, c.y - size * 0.32), sup, int(size * 0.6), col)


## Stekkerbus (ruisbord): vier aansluitingen `oud ↓`, `oud`, `nieuw ↓`, `nieuw` onder elkaar. lit = index van de
## aansluiting waar de kabel in zit (−1 = geen). Geeft de middelpunten van de bussen terug.
static func sockets(ci: CanvasItem, pos: Vector2, lit := -1) -> Array:
	var names := ["oud ↓", "oud", "nieuw ↓", "nieuw"]
	var out := []
	var r := Rect2(pos, Vector2(170, 4 * 64 + 20))
	P.panel(ci, r, P.CONSOLE_HI, false, 8)
	for i in 4:
		var c := pos + Vector2(138, 42 + i * 64)
		ci.draw_circle(c, 17, P.BRASS_LO, true, -1.0, true)
		ci.draw_circle(c, 13, P.BRASS, true, -1.0, true)
		ci.draw_circle(c, 7, P.NIGHT, true, -1.0, true)
		if i == lit:
			P.glow(ci, c, 70, P.SIG_AMBER, 0.6)
		P.text_r(ci, P.MONO_B, Vector2(c.x - 24, c.y), names[i], 16, P.TEXT if i == lit else P.TEXT_DIM)
		D.keycap(ci, Vector2(pos.x + 8, c.y - 13), str(i + 1), 11)
		out.append(c)
	return out


## Foutkabel: rubberen kabel (bezier met doorhang) met messing stekkers aan beide uiteinden.
static func cable(ci: CanvasItem, a: Vector2, b: Vector2, sag := 60.0, col := Color("#B23A2A"), sway := 0.0) -> void:
	var mid := (a + b) / 2.0 + Vector2(sway * 20.0, sag)
	var pts := PackedVector2Array()
	for i in 25:
		var s := float(i) / 24.0
		var p := a.lerp(mid, s).lerp(mid.lerp(b, s), s)
		pts.append(p)
	var sh := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(4, 8))
	ci.draw_polyline(sh, Color(0, 0, 0, 0.35), 10.0, true)
	ci.draw_polyline(pts, col.darkened(0.35), 10.0, true)
	ci.draw_polyline(pts, col, 6.5, true)
	var hl := PackedVector2Array()
	for p in pts:
		hl.append(p + Vector2(-1, -2))
	ci.draw_polyline(hl, col.lightened(0.35), 1.6, true)
	for e in [a, b]:
		ci.draw_circle(e, 12, P.BRASS_LO, true, -1.0, true)
		ci.draw_circle(e, 9, P.BRASS, true, -1.0, true)
		ci.draw_circle(e - Vector2(3, 3), 3, P.BRASS_HI, true, -1.0, true)


## OF-poort (ruisbord): halve-maan-symbool met drie ingangen (voeding, foutkabel, AND-weg).
static func or_gate(ci: CanvasItem, c: Vector2, s := 1.0, lit := false) -> void:
	var col := P.SIG_AMBER if lit else P.STEEL
	var pts := PackedVector2Array()
	for i in 13:
		var a := -PI / 2 + PI * i / 12.0
		pts.append(c + Vector2(cos(a) * 26, sin(a) * 22) * s)
	for i in 7:
		var a := PI / 2 - PI * i / 6.0
		pts.append(c + Vector2(-12 + cos(a) * 8, sin(a) * 22) * s)
	ci.draw_colored_polygon(pts, P.CONSOLE_LO)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, 2.5, true)
	P.text_c(ci, P.STENCIL, c + Vector2(2, 0) * s, "OF", int(14 * s), col)


## Bel (per lampkolom; toonhoogte zakt per niveau l). ring 0..1 = slingert.
static func bell(ci: CanvasItem, c: Vector2, r := 18.0, ring := 0.0, col := P.BRASS) -> void:
	var a := sin(ring * TAU * 3.0) * 0.25 * ring
	ci.draw_set_transform(c, a, Vector2.ONE)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-r, r * 0.6), Vector2(-r * 0.7, -r * 0.5), Vector2(0, -r * 0.9),
		Vector2(r * 0.7, -r * 0.5), Vector2(r, r * 0.6)]), col)
	ci.draw_rect(Rect2(-r * 1.1, r * 0.55, r * 2.2, r * 0.25), col.darkened(0.2))
	ci.draw_circle(Vector2(0, r * 0.95), r * 0.22, col.darkened(0.3), true, -1.0, true)
	ci.draw_line(Vector2(-r * 0.4, -r * 0.4), Vector2(-r * 0.6, r * 0.4), Color(1, 1, 1, 0.35), 2.0, true)
	ci.draw_set_transform(Vector2.ZERO)
	if ring > 0.0:
		for k in 2:
			ci.draw_arc(c, r * (1.6 + k * 0.5 + ring * 0.4), -0.6, 0.6, 8, Color(col, 0.6 * ring), 2.0, true)
			ci.draw_arc(c, r * (1.6 + k * 0.5 + ring * 0.4), PI - 0.6, PI + 0.6, 8, Color(col, 0.6 * ring), 2.0, true)


# ================================================================ SCHAKELBORD (Algoritme 7) + ZOEKLICHT (Algoritme 8)
## Relaisrooster d[i][j]. rows = t (links), cols = t′ (boven). vals[i][j] = int of null (leeg).
## dirs[i][j] = "d" (↖) / "u" (↑) / "l" (←) / "" ; path = Array van Vector2i (teruggelopen pad, oplichtend);
## warm = {Vector2i: true} (WRONG_MIN); cur = Vector2i(cel met de cursor); rail = bovenrij is een stroomrail op 0
## (Algoritme 8); cell = 56 of 44. Geeft de rect van het rooster terug.
static func relay_grid(ci: CanvasItem, o: Vector2, rows: String, cols: String, vals: Array, dirs: Array, cell := 56.0,
		path := [], warm := {}, cur := Vector2i(-1, -1), rail := false, flow := 0.0) -> Rect2:
	var R := rows.length() + 1
	var C := cols.length() + 1
	var gr := Rect2(o, Vector2(C * cell, R * cell))
	P.well(ci, gr.grow(10), P.CONSOLE_LO, 10)
	var on_path := {}
	for p in path:
		on_path[p] = true
	# koppen
	for j in C:
		var cx := o.x + (j + 0.5) * cell
		if j > 0:
			var tg := Rect2(cx - cell * 0.36, o.y - cell * 0.95, cell * 0.72, cell * 0.66)
			ci.draw_rect(Rect2(tg.position + Vector2(1, 3), tg.size), P.SHADOW)
			ci.draw_rect(tg, P.CARD)
			P.text_c(ci, P.TAPE, tg.get_center() + Vector2(0, 1), cols[j - 1], int(cell * 0.5), P.INK)
		P.text_c(ci, P.MONO, Vector2(cx, o.y - cell * 1.15), str(j), 12, P.TEXT_DIM)
	for i in R:
		var cy := o.y + (i + 0.5) * cell
		if i > 0:
			var tg := Rect2(o.x - cell * 0.98, cy - cell * 0.33, cell * 0.66, cell * 0.66)
			ci.draw_rect(Rect2(tg.position + Vector2(1, 3), tg.size), P.SHADOW)
			ci.draw_rect(tg, P.CARD)
			P.text_c(ci, P.TAPE, tg.get_center() + Vector2(0, 1), rows[i - 1], int(cell * 0.5), P.INK)
		P.text_c(ci, P.MONO, Vector2(o.x - cell * 1.2, cy), str(i), 12, P.TEXT_DIM)
	if rail:
		var rr := Rect2(o.x - 6, o.y + cell * 0.18, C * cell + 12, cell * 0.64)
		P.box(ci, rr, P.BRASS_LO, 6)
		P.box(ci, rr.grow(-3), P.BRASS, 5)
		ci.draw_rect(Rect2(rr.position + Vector2(6, 5), Vector2(rr.size.x - 12, 3)), Color(P.BRASS_HI, 0.7))
	# draden (onder de cellen)
	for i in range(1, R):
		for j in range(1, C):
			var dsel: String = dirs[i][j] if i < dirs.size() and j < dirs[i].size() else ""
			var c := o + Vector2((j + 0.5) * cell, (i + 0.5) * cell)
			var stubs := {"d": c + Vector2(-cell * 0.5, -cell * 0.5), "u": c + Vector2(0, -cell * 0.5), "l": c + Vector2(-cell * 0.5, 0)}
			for k in stubs:
				var sel: bool = dsel == k
				var lit: bool = sel and on_path.has(Vector2i(i, j))
				var a: Vector2 = c + (stubs[k] - c) * 0.42
				var b: Vector2 = stubs[k] if not sel else c + (stubs[k] - c) * 2.0 * 0.58
				var colw := Color(P.STEEL_LO, 0.55)
				var wd := 2.0
				if sel:
					colw = P.SIG_AMBER if lit else Color("#C98A4A")
					wd = 4.0 if lit else 3.0
				ci.draw_line(a, b, colw, wd, true)
	# cellen
	for i in R:
		for j in C:
			var c := o + Vector2((j + 0.5) * cell, (i + 0.5) * cell)
			var v = vals[i][j] if i < vals.size() and j < vals[i].size() else null
			var border := i == 0 or j == 0
			if rail and i == 0:
				_meter(ci, c, cell * 0.3, 0, 0, P.BRASS_HI, true)
				continue
			var hot: bool = warm.has(Vector2i(i, j))
			var lit := on_path.has(Vector2i(i, j))
			var bg := P.BAKELITE if not border else P.CONSOLE_HI
			ci.draw_style_box(P.sb(bg, 8), Rect2(c - Vector2(cell, cell) * 0.36, Vector2(cell, cell) * 0.72))
			if lit:
				P.glow(ci, c, cell * 1.6, P.SIG_AMBER, 0.35 + 0.25 * flow)
				ci.draw_style_box(P.sb(Color(0, 0, 0, 0), 8, 0, Vector2.ZERO, 2, P.SIG_AMBER), Rect2(c - Vector2(cell, cell) * 0.36, Vector2(cell, cell) * 0.72))
			if hot:
				P.glow(ci, c, cell * 1.8, P.HEAT, 0.55)
			if v != null:
				_meter(ci, c, cell * 0.3, int(v), maxi(rows.length(), cols.length()), P.HEAT if hot else (P.SIG_AMBER if lit else P.PAPER_HI), false)
			# gelijk-lampje
			if i > 0 and j > 0 and rows[i - 1] == cols[j - 1]:
				ci.draw_circle(c + Vector2(cell * 0.27, -cell * 0.27), 4.5, P.SIG_EQ, true, -1.0, true)
				P.glow(ci, c + Vector2(cell * 0.27, -cell * 0.27), 22, P.SIG_EQ, 0.5)
			if Vector2i(i, j) == cur:
				ci.draw_style_box(P.sb(Color(0, 0, 0, 0), 9, 0, Vector2.ZERO, 3, P.SIG_BLUE), Rect2(c - Vector2(cell, cell) * 0.44, Vector2(cell, cell) * 0.88))
	return gr


## Kleine wijzermeter in een relais: boogschaal + naald + cijfer.
static func _meter(ci: CanvasItem, c: Vector2, r: float, v: int, vmax: int, col: Color, rail: bool) -> void:
	if rail:
		P.text_c(ci, P.MONO, c, "0", int(r * 1.1), P.TEXT_ON_BRASS)
		return
	var a0 := PI * 1.15
	var a1 := PI * 1.85
	ci.draw_arc(c + Vector2(0, r * 0.35), r * 0.95, a0, a1, 12, Color(col, 0.35), 1.5, true)
	var u := clampf(float(v) / maxf(vmax, 1), 0.0, 1.0)
	var a := lerpf(a0, a1, u)
	ci.draw_line(c + Vector2(0, r * 0.35), c + Vector2(0, r * 0.35) + Vector2(cos(a), sin(a)) * r * 0.95, Color(col, 0.55), 1.5, true)
	P.text_c(ci, P.MONO, c + Vector2(0, r * 0.28), str(v), int(r * 1.15), col)


## Herstelstrook: telexprint die stap voor stap van t naar t′ gaat. word = huidige string, ops = {pos: "sub"/"del"/"ins"}.
static func repair_strip(ci: CanvasItem, pos: Vector2, word: String, ops := {}, cell := 38.0, title := "HERSTEL") -> Rect2:
	var n := word.length()
	var r := Rect2(pos, Vector2(n * cell + 24, 70))
	P.text_l(ci, P.STENCIL, pos + Vector2(0, -16), title, 16, P.TEXT_DIM)
	ci.draw_rect(Rect2(r.position + Vector2(2, 6), r.size), P.SHADOW)
	ci.draw_texture_rect(P.tex("tex/paper_tile.png"), r, true, Color(1.15, 1.09, 0.95))
	for k in n:
		var c := Vector2(pos.x + 12 + (k + 0.5) * cell, pos.y + 38)
		var op: String = ops.get(k, "")
		var col := P.INK
		match op:
			"sub":
				ci.draw_rect(Rect2(c.x - cell * 0.42, pos.y + 8, cell * 0.84, 54), Color(P.SIG_AMBER, 0.35))
				ci.draw_arc(c + Vector2(0, -26), 8, PI * 1.1, PI * 1.9, 8, P.BRASS_LO, 2.0, true)
			"del":
				col = Color(P.INK, 0.35)
				ci.draw_line(c + Vector2(-cell * 0.35, -2), c + Vector2(cell * 0.35, -2), NE_INK_C, 3.0, true)
			"ins":
				col = P.STAMP_BLUE
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 30), c + Vector2(6, 30), c + Vector2(0, 22)]), P.STAMP_BLUE)
		P.text_c(ci, P.TAPE, c, word[k], 32, col)
	return r

const NE_INK_C := Color("#C8361A")


## Zoeklicht: schijnwerper op een statief. aim = doelpunt van de bundel, on 0..1, sweep = extra hoek (zwaaien).
static func searchlight(ci: CanvasItem, base: Vector2, aim: Vector2, on := 1.0, sweep := 0.0) -> void:
	var head := base + Vector2(0, -70)
	var dir := (aim - head).normalized().rotated(sweep)
	var ang := dir.angle()
	if on > 0.0:
		var L := head.distance_to(aim) * 1.08
		ci.draw_set_transform(head, ang, Vector2(L / 512.0, 1.0))
		ci.draw_texture_rect(P.tex("particles/beam.png"), Rect2(0, -128, 512, 256), false, Color(1.0, 0.95, 0.75, 0.55 * on))
		ci.draw_set_transform(Vector2.ZERO)
		P.glow(ci, head + dir * L, 120, Color(1.0, 0.95, 0.7), 0.45 * on)
	# statief
	ci.draw_line(base, base + Vector2(-30, 40), P.STEEL_LO, 6.0, true)
	ci.draw_line(base, base + Vector2(30, 40), P.STEEL_LO, 6.0, true)
	ci.draw_line(base, head, P.STEEL_LO, 8.0, true)
	ci.draw_arc(head, 30, ang + PI / 2, ang + PI * 1.5, 12, P.STEEL, 5.0, true)
	# trommel
	ci.draw_set_transform(head, ang, Vector2.ONE)
	ci.draw_rect(Rect2(-34, -30, 54, 60), P.CONSOLE_HI)
	ci.draw_rect(Rect2(-34, -30, 54, 8), P.CONSOLE_HI.lightened(0.15))
	for k in 3:
		ci.draw_line(Vector2(-28 + k * 14, -30), Vector2(-28 + k * 14, 30), Color(0, 0, 0, 0.35), 2.0)
	ci.draw_rect(Rect2(18, -36, 12, 72), P.BRASS)
	ci.draw_colored_polygon(D._ell(Vector2(30, 0), 6, 33), Color(1.0, 0.96, 0.8).lerp(P.LAMP_GLASS, 1.0 - on))
	ci.draw_set_transform(Vector2.ZERO)
