class_name TxCheatSheet
extends Control
## Notas-spiekbriefje (GDD §4.2): een klembord met een tabblad per machine (zichtbaar zodra de machine binnen is),
## elk met ≤ 5 regels + paginaverwijzing, plus een kaartje met alle toetsen. ←/→ = tab, Esc = sluiten.

const TABS := [
	["Sjabloon", 1, "brute kracht · Algoritme 2", ["Schuif telkens 1; vergelijk van links naar rechts.", "Stop bij de eerste mismatch.",
		"Slechtste geval (n − m + 1) · m vergelijkingen (Opm. 9).", "Oef. 32: z = a…ab, t = a…a geeft Θ(n²) — het bewijs staat bij de oefening."], "notas p. 50–51"],
	["Vingerafdruk", 2, "Rabin-Karp · Algoritme 3", ["h(s) = s als binair getal, mod q.", "Horner: per bit ×2, +1 als het bit 1 is.",
		"Rollen: ×2, −w als het uitgaande bit 1 is, +1 als het inkomende bit 1 is.", "w = 2^m mod q, één keer vooraf.",
		"Zelfde vingerafdruk → controleren! (valse treffer)"], "notas p. 52–54"],
	["Doorloper", 3, "Knuth-Morris-Pratt · Def. 11, Alg. 4–5", ["V[j] = kleinste s > 0 met z[0..j−1−s] = z[s..j−1]; anders j; V[0] = 1.",
		"Na het schuiven blijft de leeskop staan: gelijke_tekens = j − V[j].",
		"Spiegelrit: pons tot en met de mismatch met de huidige start.", "Mismatch op 0 → V[start+1] = start+1.",
		"Na een treffer (alle voorkomens): V[m] (Oef. 41)."], "notas p. 55–62"],
	["Springer", 4, "Boyer-Moore-Horspool", ["Vergelijk van rechts naar links.", "Sleutelteken = t[i] onder de LAATSTE positie.",
		"V_H(x) = afstand van de laatste x vóór de laatste positie tot het einde;", "anders m (ook als x enkel op m−1 staat).",
		"vul_VH: van links naar rechts, latere stempels overschrijven."], "notas p. 63–66"],
	["Lampenbord", 5, "shift-AND · Def. 13, Alg. 6", ["C_x: een gat waar z[i] = x.", "Hendel: alles 1 omlaag, bovenste lamp aan (shift¹).",
		"Kaart t[j] insteken = AND met C_t[j].", "Onderste lamp aan = treffer eindigt op j."], "notas p. 67–69"],
	["Ruisbord", 6, "shift-AND met k mismatches · Def. 14", ["M^l[][j] = (1,0,…,0)", "  | shift(M^(l−1)[][j−1])   ← foutkabel in oud ↓",
		"  | (shift¹(M^l[][j−1]) & C[t[j]])", "Bel van M^l: z eindigt op j met ≤ l fouten."], "notas p. 70–71"],
	["Schakelbord", 7, "editeerafstand · Def. 15, Alg. 7", ["d[i][0] = i, d[0][j] = j.", "d[i][j] = min(↖ + (gelijk ? 0 : 1), ↑ + 1, ← + 1).",
		"↑ = verwijder t[i−1], ← = voeg t′[j−1] toe, ↖ = vervang (of gelijk).", "Teruglopen langs dragende draadjes geeft een kortste reeks."], "notas p. 72–76"],
	["Zoeklicht", 8, "kleinste editeerafstand van een deelstring · Alg. 8", ["Bovenrij D[0][j] = 0: overal instappen.",
		"Kleinste waarde in de onderste rij = einde van de beste match.", "Terug tot rij 0: de kolom waar je de rail verlaat = begin."], "notas p. 77–80"],
]

var tab := 0
var avail: Array = []
var t := 0.0
var _tabs_btn: Array = []


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	TxUi.dimmer(self, 0.55)
	var stars := TxSession.stars()
	var cur_d := TxLevels.dossier_of(TxSession.level_id) if TxSession.level_id != "" and TxSession.level_id != "N" else 1
	for i in TABS.size():
		var dn := int(TABS[i][1])
		var seen := TxSession.unlock_all or dn <= cur_d
		for id in TxLevels.ids_in_dossier(dn):
			if int(stars.get(id, 0)) > 0:
				seen = true
		if seen or dn == 1:
			avail.append(i)
	tab = avail.find(clampi(cur_d - 1, 0, TABS.size() - 1))
	if tab < 0:
		tab = 0
	var x := 330.0
	for k in avail.size():
		var i: int = avail[k]
		var b := TxUi.button(str(TABS[i][0]), "flat", 20, 0)
		b.position = Vector2(x, 132)
		var kk := k
		b.pressed.connect(func():
			tab = kk
			TxSnd.play("strip_slide", -10.0, 1.4))
		add_child(b)
		_tabs_btn.append(b)
		x += b.get_combined_minimum_size().x + 8
	var close := TxUi.button("Sluiten", "brass", 24, 220)
	close.position = Vector2(850, 940)
	close.pressed.connect(queue_free)
	add_child(close)
	TxSnd.play("strip_slide", -6.0)


func key(e: InputEventKey) -> bool:
	match e.keycode:
		KEY_ESCAPE:
			queue_free()
			return true
		KEY_RIGHT, KEY_TAB:
			tab = (tab + 1) % avail.size()
			return true
		KEY_LEFT:
			tab = (tab + avail.size() - 1) % avail.size()
			return true
	return false


func _process(dt: float) -> void:
	t += dt
	for k in _tabs_btn.size():
		(_tabs_btn[k] as Button).modulate = Color(1.25, 1.1, 0.7) if k == tab else Color(0.8, 0.8, 0.8)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(300, 190, 1320, 730)
	# klembord
	draw_rect(Rect2(r.position + Vector2(8, 12), r.size), TxPal.SHADOW)
	draw_style_box(TxPal.sb(TxPal.WOOD, 14), r)
	var paper := r.grow(-26)
	paper.position.y += 30
	paper.size.y -= 30
	draw_texture_rect(TxPal.tex("tex/paper_tile.png"), paper, true, Color(1.15, 1.12, 1.05))
	var clip := Rect2(r.get_center().x - 120, r.position.y - 14, 240, 56)
	draw_style_box(TxPal.sb(TxPal.STEEL_LO, 8), clip)
	draw_style_box(TxPal.sb(TxPal.STEEL, 6), clip.grow(-4))
	if avail.is_empty():
		return
	var d: Array = TABS[avail[tab]]
	var x := paper.position.x + 50
	var y := paper.position.y + 60
	TxPal.text_l(self, TxPal.STENCIL, Vector2(x, y), str(d[0]).to_upper(), 40, TxPal.INK)
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, y + 44), str(d[2]), 24, TxPal.INK_SOFT)
	y += 110
	for l in d[3]:
		TxPal.text_l(self, TxPal.TAPE, Vector2(x, y), "•  " + str(l), 26, TxPal.INK)
		y += 46
	TxPal.text_l(self, TxPal.TAPE_REG, Vector2(x, paper.end.y - 120), "→ " + str(d[4]), 24, TxPal.STAMP_RED)
	TxDraw.stamp(self, "gezien", Vector2(paper.end.x - 160, paper.position.y + 80), TxPal.STAMP_RED, 0.7, 0.15, 0.5)
	# toetsenkaartje
	var kr := Rect2(paper.end.x - 400, paper.end.y - 250, 360, 220)
	draw_rect(Rect2(kr.position + Vector2(3, 5), kr.size), TxPal.SHADOW)
	draw_rect(kr, TxPal.CARD)
	TxPal.text_l(self, TxPal.STENCIL, kr.position + Vector2(16, 22), "TOETSEN", 18, TxPal.INK)
	var keys := ["Spatie  naald / volgende", "← →  Enter  verschuiven", "V  strook · K  sleutel", "D W 1  wiel · Enter schuif",
		"S  hendel · letter = kaart", "Q W A  ingang ↖ ↑ ←", "F2 hint · F1 uitleg · Ctrl+Z"]
	var ky := kr.position.y + 52
	for k in keys:
		TxPal.text_l(self, TxPal.TAPE_REG, Vector2(kr.position.x + 16, ky), k, 16, TxPal.INK)
		ky += 23
