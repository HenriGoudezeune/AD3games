class_name TxGuide
extends Object
## Inhoud van de gedeelde gids (HubGuide, design/SHARED_UX.md §2–3) voor TELEX:
## Doel · Handelingen (muis én toetsenbord, voor de machine van nu) · Theorie, plus korte tutorials (3–5 kaartjes)
## de eerste keer dat een machine opduikt. "Gezien" staat in TxSave (settings "tutorials_seen").
## Theorie strikt volgens de lesnotas AD3 §3.4–3.5 (p. 50–80), notatie van de notas (z, m, t, n, V[], VH, M, Cx, d, D).
## Paginanummers = de gedrukte nummers onderaan de bladzijden van de notas.

const SAVE_KEY := "tutorials_seen"

## Machinesleutel -> [naam in het spel, dossier, theoriepagina-index]
const MACHINES := {
	"sjabloon": ["Sjabloon", 1, 0], "tegenzet": ["Tegenzet", 1, 0], "vingerafdruk": ["Vingerafdruk", 2, 1],
	"ponsbank": ["Ponsbank", 3, 3], "doorloper": ["Doorloper", 3, 2], "springer": ["Springer", 4, 4],
	"lampenbord": ["Lampenbord", 5, 5], "ruisbord": ["Ruisbord", 6, 6], "schakelbord": ["Schakelbord", 7, 7],
	"zoeklicht": ["Zoeklicht", 8, 8], "rek": ["Machinerek", 9, 0],
}

static var _seen_mem := {}   # ook zonder save (nosave) maar één keer per sessie


## HubGuide.open + handcursor op alle knoppen van het paneel (hover-feedback zoals overal in TELEX).
static func open(parent: Node, c: Dictionary, tutorial_style := false) -> HubGuide:
	var g := HubGuide.open(parent, c, style(tutorial_style))
	_hand_cursor(g)
	return g


static func _hand_cursor(n: Node) -> void:
	if n is BaseButton:
		(n as Control).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for ch in n.get_children():
		_hand_cursor(ch)


static func style(tutorial := false) -> Dictionary:
	var s := {
		"panel": TxPal.CONSOLE, "accent": TxPal.BRASS, "accent_text": TxPal.TEXT_ON_BRASS, "tab": TxPal.CONSOLE_HI,
		"text": TxPal.TEXT, "text_dim": TxPal.TEXT_DIM, "font": TxPal.UI, "font_bold": TxPal.UI_BOLD,
		"font_mono": TxPal.MONO, "layer": 70,
	}
	if tutorial:
		s["size"] = Vector2(1240, 640)
		s["font_size"] = 26
	return s


# ======================================================================
#  machines en tutorials
# ======================================================================

## Machinesleutel van een stage-dictionary (TxLevels): sjabloon, vingerafdruk, ponsbank, doorloper, ...
static func machine_key(stage: Dictionary) -> String:
	match str(stage.get("machine", "")):
		"brute":
			return "sjabloon"
		"sabotage":
			return "tegenzet"
		"rk":
			return "vingerafdruk"
		"kmp_table":
			return "ponsbank"
		"kmp":
			return "doorloper"
		"bmh":
			return "springer"
		"shift_and":
			return "ruisbord" if int(stage.get("k", 0)) > 0 else "lampenbord"
		"edit":
			return "zoeklicht" if bool(stage.get("approx", false)) else "schakelbord"
		"choice":
			return "rek"
	return ""


static func seen(key: String) -> bool:
	if _seen_mem.has(key):
		return true
	var d = TxSave.setting(SAVE_KEY, {})
	return d is Dictionary and bool((d as Dictionary).get(key, false))


static func mark_seen(key: String) -> void:
	_seen_mem[key] = true
	if TxSession.has("nosave"):
		return
	var d = TxSave.setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	d[key] = true
	TxSave.set_setting(SAVE_KEY, d)


static func tutorial(key: String) -> Dictionary:
	var title := ""
	var pages: Array = []
	match key:
		"sjabloon":
			title = "Nieuw: het Sjabloon (brute kracht)"
			pages = [
				{"title": "Wat zie je?", "text": "Bovenaan loopt het [b]lint[/b] t (de tekst). Daaronder hangt het metalen [b]sjabloon[/b] met het zoekwoord z.\n\nDe [b]naald[/b] vergelijkt z teken per teken met het lint, [b]van links naar rechts[/b]. Groen = gelijk, rood = verschil.", "schema": _draw_align.bind("de_kerker", "kerk", 3, [3, 4, 5, 6], [])},
				{"title": "Het doel", "text": "Vind [b]elk voorkomen[/b] van z in t. Een voorkomen wordt vanzelf gestempeld als de naald alle m tekens groen ziet.\n\nWeinig tikken en geen fouten geven sterren."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik de knop [b]Naald[/b] (start) en daarna [b]Volgende[/b]: het sjabloon schuift één plaats op. Klikken op het lint doet hetzelfde.\n• [b]Toetsen[/b]: [code]Spatie[/code] (ingedrukt houden = sneller).\n\nAlles wat je kunt aanklikken licht op als je er met de muis over gaat."},
				{"title": "Mini-voorbeeld", "text": "z = [code]kerk[/code] op t = [code]de_kerker[/code]: op start 0, 1 en 2 botst de naald meteen; op start 3 zijn alle 4 tekens gelijk: treffer.\n\nVast? [b]F2[/b] of de knop [b]Hint[/b] toont de juiste zet; [b]F1[/b] of [b]?[/b] opent deze uitleg met de theorie (Algoritme 2, notas p. 50–51)."},
			]
		"tegenzet":
			title = "Nieuw: de Tegenzet"
			pages = [
				{"title": "Omgekeerde wereld", "text": "Nu ben jij de vijand: [b]schrijf zelf[/b] een zoekwoord z en een lint t (binnen de opgegeven m, n en het alfabet) zodat de machine [b]zo veel mogelijk werk[/b] moet doen."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik een letter van het lint of van het sjabloon: ze wisselt naar de volgende letter van het alfabet. Klik [b]Verstuur[/b] om de machine te laten lopen, [b]Klaar[/b] als je tevreden bent.\n• [b]Toetsen[/b]: pijltjes = cursor, [code]Spatie[/code] = letter wisselen, [code]Tab[/code] = rij wisselen, [code]Enter[/code] = verstuur, [code]F[/code] = klaar."},
				{"title": "Waarom?", "text": "Zo voel je wat het [b]slechtste geval[/b] van een algoritme is: welke invoer laat het algoritme de meeste vergelijkingen doen? (zie Opmerking 9 en Oefening 32, notas p. 51)."},
			]
		"vingerafdruk":
			title = "Nieuw: de Vingerafdruk (Rabin-Karp)"
			pages = [
				{"title": "Wat zie je?", "text": "Het lint bestaat uit bits. Het [b]wiel[/b] toont een getal tussen 0 en q − 1: de [b]hashwaarde[/b] h(s) = g(s) mod q van het stuk lint onder het venster (g(s) = de bits gelezen als binair getal)."},
				{"title": "Het doel", "text": "Bereken eerst h(z) en h van het eerste venster, en [b]rol[/b] dan het venster bit per bit verder. Is de hashwaarde gelijk aan h(z), dan gaat er een [b]alarm[/b] af: [b]controleer[/b] het (het kan een valse treffer zijn)."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik een van de drie hendels [code]×2[/code], [code]−w[/code], [code]+1[/code]; klik het [b]wiel[/b] om vast te zetten / het volgende bit te nemen / te schuiven. Bij een alarm: klik [b]Controleer[/b], [b]Meld meteen[/b] of [b]Negeer[/b].\n• [b]Toetsen[/b]: [code]D[/code] ×2 · [code]W[/code] −w · [code]1[/code] +1 · [code]Enter[/code] wiel · [code]C[/code]/[code]M[/code]/[code]N[/code] bij een alarm."},
				{"title": "Mini-voorbeeld (Oef. 34, q = 13)", "text": "z = [code]00101[/code]: h(z) = 5. Eerste venster [code]11011[/code] = 27, mod 13 = [b]1[/b].\nRollen naar [code]10111[/code]: ×2 → 2, het uitgaande bit is 1 dus −w met w = 2^5 mod 13 = 6 → −4, inkomend bit 1 dus +1 → −3 ≡ [b]10[/b] (mod 13). Controle: 10111 = 23 ≡ 10. ✓"},
			]
		"ponsbank":
			title = "Nieuw: de Ponsbank (tabel V[] van KMP)"
			pages = [
				{"title": "Wat zie je?", "text": "Een [b]kopie[/b] van het zoekwoord ligt onder z zelf. Onderaan zit de [b]ponsstrook[/b]: vakje j krijgt de verschuiving [b]V[lb]j][/b] die de Doorloper straks gebruikt."},
				{"title": "Het doel", "text": "Vul V[lb]0..m−1] in volgens [b]Definitie 11[/b] (of met Algoritme 5): V[lb]j] is de kleinste s > 0 zodat de kopie, s plaatsen opgeschoven, op de posities 0..j−1 nog past; past niets, dan V[lb]j] = j. Altijd V[lb]0] = 1."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: [b]sleep[/b] de kopie naar rechts om een verschuiving te kiezen en [b]klik het vakje[/b] van de strook om te ponsen; of kies met [b]Waarde +/−[/b] en klik [b]Pons[/b]. In de spiegelrit klik je vakjes op de strook en [b]Verschuif[/b].\n• [b]Toetsen[/b]: [code]←[/code]/[code]→[/code] of [code]1–9[/code] verschuiving, [code]↑[/code]/[code]↓[/code] waarde, [code]P[/code] pons, [code]Enter[/code] verschuif, [code]V[/code] strook, [code]D[/code] klaar."},
				{"title": "Mini-voorbeeld (notas p. 56)", "text": "Voor [code]barbados[/code] is V = [code]1 1 2 3 3 3 6 7[/code]. Bv. V[lb]5] = 3: na [code]barba[/code] past [code]ba[/code] opnieuw vanaf positie 3.", "schema": _draw_table.bind([["", "b", "a", "r", "b", "a", "d", "o", "s"], ["j", "0", "1", "2", "3", "4", "5", "6", "7"], ["V[j]", "1", "1", "2", "3", "3", "3", "6", "7"]], [Vector2i(6, 2)])},
			]
		"doorloper":
			title = "Nieuw: de Doorloper (Knuth-Morris-Pratt)"
			pages = [
				{"title": "Wat zie je?", "text": "Het sjabloon met zijn [b]tabel V[lb]][/b] op de ponsstrook. De leeskop [b]gaat nooit terug[/b] in het lint: wat al gelijk was, wordt niet opnieuw vergeleken."},
				{"title": "Het doel", "text": "Bij de eerste mismatch op positie j van z schuif je het sjabloon [b]V[lb]j][/b] plaatsen op. De eerste j − V[lb]j] tekens hoeven dan niet opnieuw (Algoritme 4). Mismatch op 0: schuif 1."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik [b]Naald[/b]; bij een mismatch [b]sleep het sjabloon[/b] naar rechts (laat los = vastzetten) of klik [b]Vastzetten[/b]; klik het vakje op de strook ([b]Strook[/b]) om V[lb]j] af te lezen.\n• [b]Toetsen[/b]: [code]Spatie[/code] naald, [code]←[/code]/[code]→[/code] of [code]1–9[/code] verschuiving, [code]Enter[/code] vastzetten, [code]V[/code] strook."},
				{"title": "Mini-voorbeeld (notas p. 58)", "text": "[code]barbados[/code] in [code]barbaarse_…[/code]: de eerste mismatch is op positie 5. V[lb]5] = 3: schuif 3 op en vergelijk pas vanaf positie 5 − 3 = 2 van z.", "schema": _draw_align.bind("barbaarse_bar", "barbados", 0, [0, 1, 2, 3, 4], [5])},
			]
		"springer":
			title = "Nieuw: de Springer (Boyer-Moore-Horspool)"
			pages = [
				{"title": "Wat zie je?", "text": "Het sjabloon vergelijkt [b]van rechts naar links[/b]. In de [b]kaartenbak[/b] staat voor elk teken x een kaart met de sprong [b]VH(x)[/b]; alle andere tekens: m."},
				{"title": "Het doel", "text": "Kijk naar het teken t[lb]i] van het lint onder de [b]laatste[/b] positie van het sjabloon (het sleutelteken) en spring [b]VH(t[lb]i])[/b] plaatsen verder: i = i + VH[lb]t[lb]i]]."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: in de kaartenfase [b]klik je de letters van het sjabloon[/b] van links naar rechts om kaarten te stempelen (latere stempels overschrijven), dan [b]Kaarten klaar[/b]. Daarna: [b]klik het sleutelteken[/b] op het lint (of [b]Sleutel trekken[/b]) en de Springer springt.\n• [b]Toetsen[/b]: [code]←[/code]/[code]→[/code] + [code]Enter[/code] stempel, [code]D[/code] kaarten klaar, [code]Spatie[/code] naald, [code]K[/code] sleutel."},
				{"title": "Mini-voorbeeld (notas p. 65)", "text": "Voor [code]barbara[/code]: VH(a) = 2, VH(b) = 3, VH(r) = 1 en VH(x) = 7 voor alle andere tekens.", "schema": _draw_table.bind([["x", "a", "b", "r", "anders"], ["VH[x]", "2", "3", "1", "7"]], [])},
			]
		"lampenbord":
			title = "Nieuw: het Lampenbord (shift-AND)"
			pages = [
				{"title": "Wat zie je?", "text": "Een kolom van m [b]lampen[/b] = één kolom M[lb]][lb]j] van de matrix uit Definitie 13. Lamp i brandt als z[lb]0..i] past op het stuk lint dat op j eindigt. Rechts de [b]ponskaarten[/b] C[sub]x[/sub] (gat waar z[lb]i] = x)."},
				{"title": "Het doel", "text": "Per teken van het lint: [b]trek de hendel[/b] (shift¹: alles één lamp omlaag, bovenste lamp aan) en [b]steek de kaart[/b] van dat teken in (AND). Brandt de [b]onderste[/b] lamp, dan eindigt een treffer op j."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: in de kaartenfase [b]klik de gaatjes[/b] in de kaarten aan/uit, dan [b]Kaarten klaar[/b]. In de doorloop: klik de [b]hendel[/b], dan de juiste [b]kaart[/b]. Bij een keuze: klik de treffer op het lint.\n• [b]Toetsen[/b]: pijltjes + [code]Spatie[/code] gat, [code]D[/code] klaar, [code]S[/code] hendel, de [b]letter[/b] = die kaart."},
				{"title": "Mini-voorbeeld (Figuur 23, p. 69)", "text": "z = [code]ana[/code]: C[sub]a[/sub] = 101, C[sub]n[/sub] = 010. Op t = [code]ananas[/code] brandt de onderste lamp in kolom 2 en 4.", "schema": _draw_table.bind([["", "a", "n", "a", "n", "a", "s"], ["a", "1", "0", "1", "0", "1", "0"], ["n", "0", "1", "0", "1", "0", "0"], ["a", "0", "0", "1", "0", "1", "0"]], [Vector2i(3, 3), Vector2i(5, 3)])},
			]
		"ruisbord":
			title = "Nieuw: het Ruisbord (shift-AND met k fouten)"
			pages = [
				{"title": "Wat zie je?", "text": "Naast het gewone lampenbord M[sup]0[/sup] staat een tweede bord [b]M[sup]1[/sup][/b]: daar mag het stuk lint [b]één mismatch[/b] bevatten (Definitie 14)."},
				{"title": "De foutkabel", "text": "M[sup]l[/sup][lb]][lb]j] = (1,0,…,0) | shift(M[sup]l−1[/sup][lb]][lb]j−1]) | (shift(M[sup]l[/sup][lb]][lb]j−1]) & C[lb]t[lb]j]]).\n\nDe [b]foutkabel[/b] brengt de [b]oude[/b] kolom van het bord erboven, één lamp omlaag, naar binnen: daar mag het teken op j fout zijn."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik de [b]aansluiting[/b] waar de foutkabel in moet; verder hendel en kaarten zoals op het lampenbord.\n• [b]Toetsen[/b]: [code]1–4[/code] aansluiting, [code]S[/code] hendel, letter = kaart, [code]D[/code] bedrading klaar."},
			]
		"schakelbord":
			title = "Nieuw: het Schakelbord (editeerafstand)"
			pages = [
				{"title": "Wat zie je?", "text": "Een tabel d[lb]i][lb]j]: de editeerafstand tussen de eerste i tekens van t en de eerste j tekens van t′ (Algoritme 7). Rij 0 en kolom 0 staan al ingevuld: d[lb]0][lb]j] = j, d[lb]i][lb]0] = i."},
				{"title": "Het doel", "text": "Vul elke cel met het minimum van [b]↖[/b] + (0 als de tekens gelijk zijn, anders 1), [b]↑[/b] + 1 en [b]←[/b] + 1. Loop daarna [b]terug[/b] van rechtsonder naar linksboven langs een kortste reeks bewerkingen."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik in de oplichtende cel het [b]driehoekje[/b] van de buur waar het minimum vandaan komt (hoek linksboven ↖, bovenrand ↑, linkerrand ←), of klik die buurcel zelf. Klik [b]Klaar[/b] op het einde, [b]Nog een reeks[/b] om opnieuw terug te lopen.\n• [b]Toetsen[/b]: [code]Q[/code] ↖ · [code]W[/code] ↑ · [code]A[/code] ← · [code]Enter[/code] klaar · [code]R[/code] nog een reeks."},
				{"title": "Mini-voorbeeld (notas p. 72)", "text": "[code]lessen[/code] → [code]feesten[/code]: vervang l door f, vervang s door t, voeg een e toe: d = [b]3[/b]."},
			]
		"zoeklicht":
			title = "Nieuw: het Zoeklicht (beste benaderende match)"
			pages = [
				{"title": "Wat zie je?", "text": "Bijna het schakelbord, maar nu zoek je z in een [b]lange tekst[/b] t (Algoritme 8). De bovenrij is overal [b]0[/b]: je mag op elke plaats in t instappen."},
				{"title": "Het doel", "text": "Vul de tabel D zoals bij de editeerafstand. De [b]kleinste waarde in de onderste rij[/b] is de kleinste editeerafstand van z tot een deelwoord van t; die kolom is het einde van de beste match."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: cellen vullen zoals op het schakelbord; in de onderste rij [b]klik je de kolom[/b] met het minimum ([b]Zoeklicht hier[/b]); daarna terug tot rij 0.\n• [b]Toetsen[/b]: [code]Q[/code]/[code]W[/code]/[code]A[/code], [code]←[/code]/[code]→[/code] + [code]Enter[/code] in de onderste rij."},
				{"title": "Mini-voorbeeld (notas p. 79)", "text": "z = [code]examen[/code] in t = [code]de_armen_vouwen[/code]: het minimum van de onderste rij is [b]2[/b], onder de n van [code]armen[/code]."},
			]
		"rek":
			title = "De finale: kies je machine"
			pages = [
				{"title": "Het rek", "text": "Voor elk lint kies [b]jij[/b] welke machine het werk doet. Lees de beperkingen (live, ruis, lang lint, budget) en kies het algoritme dat erbij past."},
				{"title": "Wat kun je doen?", "text": "• [b]Muis[/b]: klik de knop van de machine.\n• [b]Toetsen[/b]: [code]1[/code]–[code]3[/code].\n\nDe voorbereiding (tabellen, kaarten) doe je zelf; de doorloop speelt de machine daarna met jouw tabellen."},
			]
	return {"title": title, "pages": _fix(pages), "tutorial": true}


# ======================================================================
#  volledige gids
# ======================================================================

## spec = TxLevelSpec (of null buiten een level), mkey = machinesleutel van de huidige machine ("" = alle).
static func content(spec = null, mkey := "", start_tab := "doel") -> Dictionary:
	var gp := goal_pages(spec, mkey)
	gp.append_array(path_pages(spec))
	var tabs := {"doel": _fix(gp), "handelingen": _fix(action_pages(mkey)), "theorie": _fix(theory_pages())}
	var page := 0
	if start_tab == "theorie" and MACHINES.has(mkey):
		page = int(MACHINES[mkey][2])
	elif start_tab == "theorie" and spec != null:
		page = theory_page_of_dossier(int(spec.dossier))
	return {"title": "TELEX · hoe speel je?", "tabs": tabs, "tab": start_tab, "page": page}


## Dossier 1–8 -> index van de eerste theoriepagina (dossier 3 heeft er twee: KMP en Algoritme 5).
static func theory_page_of_dossier(d: int) -> int:
	return clampi(d - 1 + (1 if d >= 4 else 0), 0, 8)


static func goal_pages(spec, mkey: String) -> Array:
	var out: Array = []
	if spec != null:
		var head: String = ("%s · %s" % [spec.id, spec.title]) if not spec.endless else str(spec.title)
		var t := ""
		if spec.intro != "":
			t += "[i]%s[/i]\n\n" % spec.intro
		var st: Dictionary = spec.stages[0] if not spec.stages.is_empty() else {}
		if st.has("z") and str(st.z) != "":
			t += "Zoekwoord z = [code]%s[/code]" % str(st.z)
			if st.has("t") and str(st.t) != "":
				t += " · lint van %d tekens" % str(st.t).length()
			t += "\n"
		if st.has("a"):
			t += "t = [code]%s[/code] · t′ = [code]%s[/code]\n" % [str(st.a), str(st.b)]
		if MACHINES.has(mkey):
			t += "Machine nu: [b]%s[/b]\n" % MACHINES[mkey][0]
		if not spec.stars.is_empty():
			t += "\n[b]Sterren[/b]\n"
			for i in spec.stars.size():
				t += "%d. %s\n" % [i + 1, TxScoring.star_label(spec.stars[i])]
		if spec.notes_ref != "":
			t += "\nIn de notas: %s" % spec.notes_ref
		out.append({"title": head, "text": t})
	out.append({"title": "Station Zoeklicht", "text":
		"Je bedient de machines van een telexstation. Elke machine is een algoritme uit de lesnotas (§3.4–3.5):\n\n" +
		"• [b]Sjabloon[/b] = brute kracht (Alg. 2)   • [b]Vingerafdruk[/b] = Rabin-Karp (Alg. 3)\n" +
		"• [b]Ponsbank[/b] + [b]Doorloper[/b] = Knuth-Morris-Pratt (Def. 11, Alg. 4–5)\n" +
		"• [b]Springer[/b] = Boyer-Moore-Horspool   • [b]Lampenbord[/b] = shift-AND (Def. 13, Alg. 6)\n" +
		"• [b]Ruisbord[/b] = shift-AND met k fouten (Def. 14)\n" +
		"• [b]Schakelbord[/b] = editeerafstand (Def. 15, Alg. 7)   • [b]Zoeklicht[/b] = Algoritme 8\n\n" +
		"De [b]tikteller[/b] telt het werk (vergelijkingen, lampen, relais). Hoe minder, hoe beter: dat is complexiteit die je voelt."})
	return out


static func action_pages(mkey: String) -> Array:
	var out: Array = []
	if MACHINES.has(mkey):
		var tut := tutorial(mkey)
		for p in tut.pages:
			if str(p.title).begins_with("Wat kun je doen"):
				out.append({"title": "Nu: %s" % MACHINES[mkey][0], "text": p.text})
	out.append({"title": "Altijd", "text":
		"• [b]Muis[/b]: alles wat je kunt aanklikken, licht op en krijgt een handje als je erover gaat. Klik je tijdens een animatie, dan wacht je klik even en gebeurt hij daarna (net zoals een toets).\n" +
		"• Knoppen onderaan: de zetten van nu, met hun sneltoets eronder.\n" +
		"• [b]II[/b] linksboven of [code]Esc[/code]: pauze (verder, opnieuw, uitleg, instellingen, levelkeuze, speelhal).\n" +
		"• [b]?[/b] of [code]F1[/code]: deze uitleg.   [b]Hint[/b] of [code]F2[/code]: toont de juiste zet (kost de derde ster).\n" +
		"• [b]Terugnemen[/b] of [code]Ctrl+Z[/code] (rustige levels).   [b]Speelhal[/b] of [code]Ctrl+H[/code]: terug naar alle games."})
	return out


# ======================================================================
#  theorie (lesnotas §3.4–3.5, p. 50–80)
# ======================================================================

static func theory_pages() -> Array:
	return [
		{"title": "Brute kracht · Algoritme 2 (p. 50–51)", "text":
			"[b]Notatie[/b] (p. 50): zoek z[lb]0..m−1] in de tekst t[lb]0..n−1].\n\n" +
			"[b]Werking[/b]: voor elke startpositie i = 0, …, n − m vergelijkt [code]strings_gelijk(z,t,i)[/code] z[lb]0], z[lb]1], … met t[lb]i], t[lb]i+1], … en stopt bij de eerste mismatch.\n\n" +
			"[b]Complexiteit[/b] (Opmerking 9): n − m + 1 startposities, elk ten hoogste m stappen: [b]O((n − m + 1)·m)[/b]. Met m constant is dat O(n), maar m kan ook Θ(n) zijn (bv. n/2) en dan wordt het O(n²). Oefening 32 vraagt een reeks voorbeelden die echt Θ(n²) stappen nodig heeft.\n\n" +
			"[b]In TELEX[/b]: het Sjabloon (dossier 1); de Tegenzet laat je zelf zo'n slechte invoer bouwen.",
			"schema": _draw_align.bind("de_kerker", "kerk", 3, [3, 4, 5, 6], []), "schema_width": 470.0},
		{"title": "Rabin-Karp · Algoritme 3 (p. 52–54)", "text":
			"[b]Idee[/b]: vergelijk eerst een [b]hashwaarde[/b]; enkel als die gelijk is, vergelijk je de strings echt.\n\n" +
			"[b]Hashfunctie[/b] voor bitstrings: kies q (bv. een priemgetal), lees s als binair getal g(s) en neem h(s) = g(s) mod q = (Σ s[sub]i[/sub]·2[sup](m−1)−i[/sup]) mod q.\n\n" +
			"[b]Updaten in O(1)[/b]: h(t[sub]p+1[/sub]…t[sub]p+m[/sub]) = (2·h(t[sub]p[/sub]…t[sub]p+m−1[/sub]) − t[sub]p[/sub]·2[sup]m[/sup] + t[sub]p+m[/sub]) mod q. t[sub]p[/sub]·2[sup]m[/sup] mod q is 0 of één vooraf berekende waarde.\n\n" +
			"[b]Complexiteit[/b] (Opmerking 10): hashen kost samen O(n); slechtste geval (slecht verdeelde hashwaarden) nog steeds O((n − m + 1)·m). In de praktijk wordt [code]strings_gelijk[/code] maar in ±(n − m + 1)/q gevallen opgeroepen; met q ≥ m: [b]O(n)[/b].\n\n" +
			"[b]Voorbeeld[/b] (Oef. 34, q = 13): h([code]00101[/code]) = 5; h([code]11011[/code]) = 27 mod 13 = 1; rollen naar [code]10111[/code]: (2·1 − 32 + 1) mod 13 = 10 = 23 mod 13.\n\n[b]In TELEX[/b]: de Vingerafdruk (dossier 2): ×2, −w (w = 2[sup]m[/sup] mod q), +1."},
		{"title": "Knuth-Morris-Pratt · Def. 11, Alg. 4 (p. 55–60)", "text":
			"[b]Verschuivingstabel[/b] (Definitie 11): V[lb]0] = 1 en voor j > 0\nV[lb]j] = min{ s | (0 < s < j en z[lb]0] = z[lb]s], …, z[lb]j−1−s] = z[lb]j−1]) of s = j }.\nBij de eerste mismatch op positie j van z schuif je de start V[lb]j] plaatsen op.\n\n" +
			"[b]Observatie[/b]: na het schuiven zijn de eerste j − V[lb]j] tekens al gelijk; [code]gelijke_tekens = eerste_mismatch − V[lb]eerste_mismatch][/code] (mismatch op 0: gelijke_tekens = 0).\n\n" +
			"[b]Complexiteit[/b] (Stelling 12): O(n) voor het zoeken (als V[lb]] in O(m) berekend wordt). start + gelijke_tekens wordt nooit kleiner: elk teken wordt hoogstens één keer [i]succesvol[/i] vergeleken, en er zijn ten hoogste n − m mislukte vergelijkingen.\n\n" +
			"[b]Voorbeeld[/b] (p. 58): [code]barbados[/code] in [code]barbaarse_barbecue_in_barbados[/code]: eerste mismatch op 5, V[lb]5] = 3: 3 opschuiven, de eerste 2 tekens niet opnieuw vergelijken.\n\n[b]In TELEX[/b]: de Doorloper (dossier 3).",
			"schema": _draw_table.bind([["", "b", "a", "r", "b", "a", "d", "o", "s"], ["j", "0", "1", "2", "3", "4", "5", "6", "7"], ["V[j]", "1", "1", "2", "3", "3", "3", "6", "7"]], [Vector2i(6, 2)]), "schema_width": 470.0},
		{"title": "V[] berekenen · Algoritme 5 (p. 60–62)", "text":
			"[b]Idee[/b]: zoek z [b]in zichzelf[/b] met hetzelfde algoritme, voor elke startpositie vanaf 1, en ga door tot het einde. V[lb]0] = V[lb]1] = 1.\n\n" +
			"[code]eerste_mismatch = vergelijk_strings(z, z, start, gelijke_tekens)[/code]\n" +
			"• mismatch op 0: V[lb]start + 1] = start + 1\n" +
			"• anders: V[lb]start + i] = start voor i = gelijke_tekens + 1 … eerste_mismatch\n" +
			"• dan [code]start += V[lb]eerste_mismatch][/code] (die waarde is al ingevuld) en gelijke_tekens zoals in Algoritme 4.\n\n" +
			"[b]Complexiteit[/b]: [b]O(m)[/b], om dezelfde reden als het zoeken; het extra werk per stap is constant.\n\n" +
			"[b]Voorbeeld[/b] (p. 61–62): [code]barbados[/code]: start 1 en 2 botsen meteen (V[lb]2] = 2, V[lb]3] = 3); op start 3 mismatch op 2: V[lb]4] = V[lb]5] = 3; dan nog twee keer meteen botsen: V[lb]6] = 6, V[lb]7] = 7.\n\n[b]In TELEX[/b]: de Ponsbank (dossier 3)."},
		{"title": "Boyer-Moore-Horspool (p. 63–66)", "text":
			"[b]Werking[/b]: zoals brute kracht, maar vergelijk [b]van rechts naar links[/b] ([code]strings_gelijk_invers[/code]); i is de positie in t onder het [b]laatste[/b] teken van z.\n\n" +
			"[b]Tabel[/b]: VH(x) = |z| als x niet in z voorkomt of enkel op positie |z| − 1; anders |z| − 1 − p, met p de laatste positie vóór |z| − 1 waar x in z staat.\n[code]vul_VH[/code]: eerst overal |z|, dan voor i = 0 … |z| − 2: VH[lb]z[lb]i]] = |z| − i − 1 (de laatste keer telt). O(m).\n\n" +
			"[b]Zoeken[/b]: [code]i = |z| − 1; zolang i < |t|: test, dan i = i + VH[lb]t[lb]i]][/code].\n\n" +
			"[b]Complexiteit[/b]: heel eenvoudig en in de praktijk bijzonder snel; het slechtste geval is niet zo goed als bij ingewikkeldere algoritmen (beste en slechtste geval: Oefening 50).\n\n" +
			"[b]Voorbeeld[/b] (p. 64–65): [code]barbara[/code] in [code]barbados_zoekt_barbara[/code]: o en t staan niet in z: volle sprong; bij r spring je 1.\n\n[b]In TELEX[/b]: de Springer met de kaartenbak (dossier 4).",
			"schema": _draw_table.bind([["x", "a", "b", "r", "anders"], ["VH[x]", "2", "3", "1", "7"]], []), "schema_width": 420.0},
		{"title": "shift-AND · Def. 13, Alg. 6 (p. 66–69)", "text":
			"[b]Matrix[/b] (Definitie 13): M[lb]i][lb]j] = 1 als z[lb]0] = t[lb]j−i], …, z[lb]i] = t[lb]j], anders 0. Een 1 in de laatste rij (M[lb]m−1][lb]j]) = een match van z die op j eindigt.\n\n" +
			"[b]Karakteristieke vector[/b] C[sub]x[/sub][lb]i] = 1 als z[lb]i] = x.\n\n" +
			"[b]Volgende kolom[/b]: M[lb]][lb]j+1] = shift¹(M[lb]][lb]j]) & C[sub]t[lb]j+1][/sub], waarbij shift¹ bit i − 1 naar positie i schuift en bit 0 op 1 zet. Je houdt maar één kolom bij.\n\n" +
			"[b]Complexiteit[/b]: de hele matrix is Θ(n·m), ook in het beste geval. Maar als m ≤ de woordlengte (bv. 64) is een kolom één computerwoord en zijn << en & constant én heel goedkoop: zeer snel, vooral als je [b]alle[/b] matches zoekt.\n\n" +
			"[b]Voorbeeld[/b] (Figuur 23): z = [code]ana[/code], t = [code]ananas[/code], C[sub]a[/sub] = 101, C[sub]n[/sub] = 010.\n\n[b]In TELEX[/b]: het Lampenbord (dossier 5): hendel = shift¹, kaart = AND met C[sub]x[/sub].",
			"schema": _draw_table.bind([["", "a", "n", "a", "n", "a", "s"], ["a", "1", "0", "1", "0", "1", "0"], ["n", "0", "1", "0", "1", "0", "0"], ["a", "0", "0", "1", "0", "1", "0"]], [Vector2i(3, 3), Vector2i(5, 3)]), "schema_width": 400.0},
		{"title": "Matches met k fouten · Def. 14 (p. 70–71)", "text":
			"[b]Matrix[/b] (Definitie 14): M[sup]k[/sup][lb]i][lb]j] = 1 als de prefix z[lb]0..i] gematcht kan worden met de deelstring van t die op j eindigt, met [b]ten hoogste k mismatches[/b]. M[sup]0[/sup] = M.\n\n" +
			"[b]Randen[/b]: M[sup]k[/sup][lb]][lb]0] = (1, 0, …, 0) en M[sup]l[/sup][lb]0][lb]j] = 1 voor l > 0.\n\n" +
			"[b]Twee redenen[/b] voor M[sup]l[/sup][lb]i][lb]j] = 1 (i, j, l > 0):\n• M[sup]l−1[/sup][lb]i−1][lb]j−1] = 1: het teken op j mag fout zijn;\n• M[sup]l[/sup][lb]i−1][lb]j−1] = 1 en t[lb]j] = z[lb]i].\n\n" +
			"[b]Kolom[/b]: M[sup]l[/sup][lb]][lb]j] = (1,0,…,0) | shift(M[sup]l−1[/sup][lb]][lb]j−1]) | (shift(M[sup]l[/sup][lb]][lb]j−1]) & C[lb]t[lb]j]]). Bereken in een volgorde waarin l − 1 en j − 1 al bekend zijn; per teken dus k + 1 kolommen met dezelfde bitoperaties.\n\n" +
			"[b]Oefening[/b] 60: z = [code]dank[/code], t = [code]een_dansfeest[/code], 1 mismatch.\n\n[b]In TELEX[/b]: het Ruisbord (dossier 6): de foutkabel is shift(M[sup]l−1[/sup][lb]][lb]j−1])."},
		{"title": "Editeerafstand · Def. 15, Alg. 7 (p. 71–76)", "text":
			"[b]Definitie 15[/b]: bewerkingen [b]vervangen[/b], [b]verwijderen[/b] en [b]toevoegen[/b] van een letterteken. d(t, t′) = het kleinste aantal bewerkingen op t zodat het resultaat t′ is (Levenshtein-afstand). Het is een metriek (Opmerking 16).\n\n" +
			"[b]Dynamisch programmeren[/b] over prefixen (Lemma 17): d[lb]i][lb]j] = afstand tussen t[lb]0..i−1] en t′[lb]0..j−1]; d[lb]i][lb]0] = i, d[lb]0][lb]j] = j;\n" +
			"d[lb]i][lb]j] = min{ d[lb]i−1][lb]j−1] + wisselkost, d[lb]i−1][lb]j] + 1 (verwijder t[lb]i−1]), d[lb]i][lb]j−1] + 1 (voeg t′[lb]j−1] toe) }, wisselkost = 0 als t[lb]i−1] = t′[lb]j−1], anders 1.\n\n" +
			"[b]Complexiteit[/b] (Lemma 18): [b]O(n·m)[/b].\n\n" +
			"[b]Voorbeeld[/b] (p. 72, 76): d([code]lessen[/code], [code]feesten[/code]) = 3.\n\n[b]In TELEX[/b]: het Schakelbord (dossier 7).",
			"schema": _draw_table.bind([["", "", "f", "e", "e", "s", "t", "e", "n"], ["", "0", "1", "2", "3", "4", "5", "6", "7"], ["l", "1", "1", "2", "3", "4", "5", "6", "7"], ["e", "2", "2", "1", "2", "3", "4", "5", "6"], ["s", "3", "3", "2", "2", "2", "3", "4", "5"], ["s", "4", "4", "3", "3", "2", "3", "4", "5"], ["e", "5", "5", "4", "3", "3", "3", "3", "4"], ["n", "6", "6", "5", "4", "4", "4", "4", "3"]], [Vector2i(8, 7)]), "schema_width": 470.0},
		{"title": "Beste benaderende match · Algoritme 8 (p. 77–79)", "text":
			"[b]Probleem[/b]: het deelwoord van t met de kleinste editeerafstand tot z. Alle deelwoorden apart proberen kost O(m·n³).\n\n" +
			"[b]Tabel[/b]: D[lb]i][lb]j] = min{ d(z[lb]0..i−1], t[lb]l..j−1]) | 0 ≤ l ≤ j }: de beste afstand van een deelwoord dat op j eindigt.\n" +
			"D[lb]i][lb]0] = i en [b]D[lb]0][lb]j] = 0[/b] (overal instappen); verder dezelfde regel als bij Algoritme 7:\n" +
			"D[lb]i][lb]j] = min{ D[lb]i−1][lb]j] + 1, D[lb]i][lb]j−1] + 1, D[lb]i−1][lb]j−1] + g(i, j) }.\n" +
			"Antwoord = de [b]kleinste waarde in de laatste rij[/b].\n\n" +
			"[b]Complexiteit[/b] (Lemma 19): [b]O(n·m)[/b].\n\n" +
			"[b]Voorbeeld[/b] (p. 79): z = [code]examen[/code], t = [code]de_armen_vouwen[/code]: minimum 2 (onder de n van armen).\n\n[b]In TELEX[/b]: het Zoeklicht (dossier 8).",
			"schema": _draw_table.bind([["", "", "d", "e", "_", "a", "r", "m", "e", "n"], ["", "0", "0", "0", "0", "0", "0", "0", "0", "0"], ["e", "1", "1", "0", "1", "1", "1", "1", "0", "1"], ["x", "2", "2", "1", "1", "2", "2", "2", "1", "1"], ["a", "3", "3", "2", "2", "1", "2", "3", "2", "2"], ["m", "4", "4", "3", "3", "2", "2", "2", "3", "3"], ["e", "5", "5", "4", "4", "3", "3", "3", "2", "3"], ["n", "6", "6", "5", "5", "4", "4", "4", "3", "2"]], [Vector2i(9, 7)]), "schema_width": 470.0},
	]


# ======================================================================
#  BBCode: RichTextLabel kent geen [sub]/[sup] → notatie t_p, 2^m, M^(l−1)
# ======================================================================

static func _fix(pages: Array) -> Array:
	for p in pages:
		for k in ["title", "text"]:
			if (p as Dictionary).has(k):
				p[k] = subsup(str(p[k]))
	return pages


static func subsup(s: String) -> String:
	var re := RegEx.create_from_string("\\[(sub|sup)\\](.*?)\\[/\\1\\]")
	var out := ""
	var at := 0
	for m in re.search_all(s):
		out += s.substr(at, m.get_start() - at)
		var inner := m.get_string(2)
		var plain := inner.replace("[lb]", "[")
		out += ("_" if m.get_string(1) == "sub" else "^") + (inner if plain.length() == 1 else "(%s)" % inner)
		at = m.get_end()
	return out + s.substr(at)


# ======================================================================
#  schema's (tekenen in het paneel)
# ======================================================================

## Tabel: rows[r][c] als tekst; hl = cellen (kolom, rij) die oplichten. Eerste rij en kolom = koppen.
static func _draw_table(ci: Control, sz: Vector2, rows: Array, hl: Array) -> void:
	var nr := rows.size()
	var nc := 0
	for r in rows:
		nc = maxi(nc, (r as Array).size())
	if nr == 0 or nc == 0:
		return
	var cw := minf(64.0, sz.x / nc)
	var ch := minf(52.0, sz.y / nr)
	var w0 := cw * 1.4 if str(rows[nr - 1][0]).length() > 2 or str(rows[0][0]).length() > 2 else cw
	var tw := w0 + cw * (nc - 1)
	var org := Vector2((sz.x - tw) / 2.0, maxf(0.0, (sz.y - ch * nr) / 2.0))
	var fs := int(clampf(ch * 0.5, 14, 26))
	for r in nr:
		for c in (rows[r] as Array).size():
			var x := org.x + (0.0 if c == 0 else w0 + (c - 1) * cw)
			var w := w0 if c == 0 else cw
			var rect := Rect2(x, org.y + r * ch, w, ch)
			var head := r == 0 or c == 0
			var bg := TxPal.CONSOLE_LO if head else Color(TxPal.PAPER, 0.92)
			if hl.has(Vector2i(c, r)):
				bg = TxPal.SIG_EQ
			ci.draw_rect(rect.grow(-1), bg)
			var txt := str(rows[r][c])
			var col := TxPal.BRASS_HI if head else TxPal.INK
			var f: Font = TxPal.MONO
			var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			ci.draw_string(f, rect.position + Vector2((w - ts.x) / 2.0, ch / 2.0 + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Lint + sjabloon: t met z eronder op `start`; eq = posities in t die groen zijn, ne = posities in z die rood zijn.
static func _draw_align(ci: Control, sz: Vector2, t: String, z: String, start: int, eq: Array, ne: Array) -> void:
	var n := maxi(t.length(), start + z.length())
	var cw := minf(46.0, sz.x / maxf(1.0, n))
	var org := Vector2((sz.x - cw * n) / 2.0, sz.y / 2.0 - cw * 1.2)
	var fs := int(cw * 0.6)
	var f: Font = TxPal.MONO
	for i in t.length():
		var r := Rect2(org + Vector2(i * cw, 0), Vector2(cw, cw))
		ci.draw_rect(r.grow(-1), Color(TxPal.PAPER, 0.95))
		if eq.has(i):
			ci.draw_rect(Rect2(r.position + Vector2(2, cw - 6), Vector2(cw - 4, 4)), TxPal.SIG_EQ)
		ci.draw_string(f, r.position + Vector2(cw * 0.2, cw * 0.72), t[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TxPal.INK)
		ci.draw_string(f, r.position + Vector2(cw * 0.3, -6), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 0.55), TxPal.TEXT_DIM)
	for i in z.length():
		var r2 := Rect2(org + Vector2((start + i) * cw, cw * 1.35), Vector2(cw, cw))
		var col := TxPal.STEEL
		if ne.has(i):
			col = TxPal.SIG_NE
		elif eq.has(start + i):
			col = TxPal.SIG_EQ
		ci.draw_rect(r2.grow(-1), col)
		ci.draw_string(f, r2.position + Vector2(cw * 0.2, cw * 0.72), z[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TxPal.INK)



# ======================================================================
#  leerpad (design/LEARNING_PATH.md): per deel herbekijken / opnieuw oefenen
# ======================================================================

## Pagina's "Leerpad · deel k" in de Doel-tab, met de knoppen "Bekijk de demo opnieuw" en "Oefen dit opnieuw".
## In een level staan eerst de delen die bij dat level horen.
static func path_pages(spec = null) -> Array:
	var out: Array = []
	var ps: Array = TxLessons.all_parts().duplicate()
	var lid: String = str(spec.id) if spec != null else ""
	if lid != "" and lid != "LES":
		var mine: Array = []
		var rest: Array = []
		for P in ps:
			if (P.levels as Array).has(lid):
				mine.append(P)
			else:
				rest.append(P)
		ps = mine + rest
	for P in ps:
		var lv := TxLessons.level(P.id)
		var t := "[b]Regel:[/b] %s\n\n" % P.rule
		t += "• [b]Kijk[/b]: Chef Ponsaert doet het stap voor stap voor (wat + waarom + toestand).\n"
		t += "• [b]Samen[/b]: jij doet het, met tips, hint en uitleg bij een fout.\n"
		t += "• [b]Zelf[/b]: level %s.   • [b]Check[/b]: vragen in de terugblik.\n\n" % ", ".join(P.levels)
		t += "Status: [b]%s[/b]" % TxLessons.LEVEL_TXT[lv]
		if lid != "" and (P.levels as Array).has(lid):
			t += "  [color=#FFB23E](hoort bij dit level)[/color]"
		t += "\n[color=#96A39C]lesnotas %s[/color]" % P.page
		out.append({"title": "Leerpad · deel %d van %d: %s" % [TxLessons.index_of_part(P.id) + 1, ps.size(), P.title],
			"text": TxLessons.bb(t), "schema_width": 400.0, "schema_node": _path_buttons.bind(str(P.id))})
	return out


static func _path_buttons(id: String) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	var a := TxUi.button("Bekijk de demo opnieuw", "key", 24, 370)
	a.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	a.pressed.connect(func(): _play_path(id, "kijk"))
	box.add_child(a)
	var b := TxUi.button("Oefen dit opnieuw", "brass", 24, 370)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): _play_path(id, "samen"))
	box.add_child(b)
	return box


static func _play_path(id: String, phase: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var cur := tree.current_scene if tree else null
	var in_level: bool = cur != null and cur.scene_file_path == TxSession.SCENE_CONSOLE and cur.get("coach") == null \
		and TxLevels.has_level(TxSession.level_id)
	TxSession.play_lesson(id, phase, in_level)
