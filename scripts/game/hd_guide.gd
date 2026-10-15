class_name HDGuide
extends Object
## Inhoud van de gedeelde gids (HubGuide, design/SHARED_UX.md §2–3) voor Hash & Dash:
## Doel · Handelingen · Theorie, plus korte tutorials (3–5 kaartjes) per nieuwe mechaniek.
## Theorie strikt volgens de lesnotas AD3 §2.1.1 (p. 5–9), notatie van de notas (a, a_b, x|a, g).

const SAVE_KEY := "tutorials_seen"   # SaveData settings: {"basis": true, ...}

## Eerste dag waarop een mechaniek verschijnt -> tutorial-sleutel.
const DAY_TUTORIAL := {1: "basis", 2: "verdubbelen", 3: "splitsen", 4: "klanten", 6: "oefening", 7: "klonen"}

const AB := "a[font_size=17]b[/font_size]"      # a_b zoals in de notas (lokale diepte)
const ABP := "a[font_size=17]b'[/font_size]"


static func style(tutorial := false) -> Dictionary:
	var s := {
		"panel": Pal.PANEL_LO, "accent": Pal.WARN, "accent_text": Pal.INK, "tab": Pal.PANEL_HI,
		"text": Pal.TEXT, "text_dim": Pal.TEXT_DIM, "font": Pal.UI, "font_bold": Pal.UI_BOLD,
		"font_mono": Pal.MONO, "layer": 40,
	}
	if tutorial:
		s["size"] = Vector2(1240, 620)
		s["font_size"] = 27
	return s


# ======================================================================
#  tutorials
# ======================================================================

static func seen(key: String) -> bool:
	var d = SaveData.get_setting(SAVE_KEY, {})
	return d is Dictionary and bool((d as Dictionary).get(key, false))


static func mark_seen(key: String) -> void:
	var d = SaveData.get_setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	d[key] = true
	SaveData.set_setting(SAVE_KEY, d)


## Tutorial-sleutel voor deze dag als die nog niet gezien is, anders "".
static func pending_tutorial(day: int) -> String:
	var k: String = DAY_TUTORIAL.get(day, "")
	if k == "" or seen(k):
		return ""
	return k


static func tutorial(key: String) -> Dictionary:
	var pages: Array = []
	var title := ""
	match key:
		"basis":
			title = "Welkom in het depot"
			pages = [
				{"title": "Wat zie je?", "text": "Rechts komt een [b]band[/b] met pakjes binnen. Elk pakje draagt een [b]hashwaarde[/b] van 5 bits, bv. [code]10101[/code].\n\nLinks staat de [b]sorteermuur met luiken[/b]; achter elk luik loopt een buis naar een [b]rek[/b].", "schema": _draw_prefix.bind("10101", 0)},
				{"title": "Het doel", "text": "Zet elk pakje in het juiste rek, zonder fouten en zonder onnodige ritten.\n\nHet juiste luik = de [b]eerste a bits[/b] van de hashwaarde. Vandaag is [b]a = 1[/b]: kijk enkel naar het eerste bit.", "schema": _draw_prefix.bind("10101", 1)},
				{"title": "Wat kun je doen?", "text": "• [b]Sleep[/b] het voorste pakje van de band naar een luik.\n• Of [b]typ[/b] de bits: [code]0[/code] of [code]1[/code] (Backspace wist).\n\nEen verkeerd luik kost munten."},
				{"title": "Mini-voorbeeld", "text": "[code]10101[/code] begint met [code]1[/code], dus luik [code]1[/code].\n[code]00110[/code] begint met [code]0[/code], dus luik [code]0[/code].\n\nVastgelopen? [b]F1[/b] of de [b]?[/b]-knop rechtsboven opent deze uitleg opnieuw, met ook de theorie uit de notas."},
			]
		"verdubbelen":
			title = "Nieuw: de hendel"
			pages = [
				{"title": "Een vol rek", "text": "Een rek (emmer) heeft plaats voor [b]g = 2[/b] pakjes. Is het vol en loopt er maar [b]één buis[/b] naartoe ([i]%s = a[/i]), dan blijft het nieuwe pakje vastzitten." % AB, "schema_width": 600, "schema_node": fig_node(1, "0{00100,01111} 1{10010,11100}", "a = 1: emmer 1 is vol, a_b = a")},
				{"title": "Trek de hendel = verdubbelen", "text": "Sleep de [b]hendel[/b] naar beneden (of druk [b]D[/b]). De muur verdubbelt: [b]a wordt a + 1[/b] en elk luik wordt er twee die naar hetzelfde rek wijzen.\n\nDat gebeurt in het geheugen: het kost [b]geen ritten[/b].", "schema_width": 600, "schema_node": fig_node(2, "0{00100,01111} 1{10010,11100}", "a = 2, alle emmers nog a_b = 1")},
				{"title": "Dan de zaag = splitsen", "text": "Nu lopen er [b]twee buizen[/b] naar het volle rek. Klik op de [b]zaag[/b] bij het rek (of druk [b]S[/b]): er komt een nieuw rek bij."},
				{"title": "De sorteertafel", "text": "Verdeel de pakjes op [b]bit nummer %s + 1[/b]:\n• bit [code]0[/code]: [b]links[/b] (oud rek)\n• bit [code]1[/code]: [b]rechts[/b] (nieuw rek)\n\nSleep, of druk [code]0[/code]/[code]1[/code] of de pijltjes [code]←[/code]/[code]→[/code]." % AB, "schema": _draw_prefix.bind("11100", 2)},
			]
		"splitsen":
			title = "Nieuw: bijbouwen zonder hendel"
			pages = [
				{"title": "Tel de buizen", "text": "Het getal op een rek is zijn [b]%s[/b]. Naar dat rek lopen [b]2^(a − %s)[/b] buizen.\n\nVandaag is a = 3 en hebben sommige rekken %s = 1 of 2: daar lopen meerdere buizen naartoe." % [AB, AB, AB], "schema_width": 600, "schema_node": fig_node(3, "0{00100,01111} 10{10010} 110{11000} 111{11100}", "Start van dag 3: a = 3")},
				{"title": "Meer dan één buis? Zaag!", "text": "Is een vol rek bereikbaar via [b]2 of meer buizen[/b] ([i]%s < a[/i]), dan hoef je niet te verdubbelen: [b]zaag[/b] meteen (klik de zaag of [b]S[/b]).\n\nVerdubbelen zonder reden kost je de derde ster." % AB},
				{"title": "Mini-voorbeeld", "text": "Rek [code]10[/code] (%s = 2) krijgt buizen [code]100[/code] en [code]101[/code]. Na het zagen op bit 3:\n• [code]100..[/code] blijft in het oude rek,\n• [code]101..[/code] gaat naar het nieuwe rek, en buis [code]101[/code] wijst ernaar.\nBeide rekken hebben dan %s = 3." % [AB, AB], "schema_width": 600, "schema_node": fig_node(3, "0{00100,01111} 100{10010} 101{10111} 110{11000} 111{11100}", "Na zagen van rek 10")},
			]
		"klanten":
			title = "Nieuw: klanten aan de balie"
			pages = [
				{"title": "Wat willen ze?", "text": "Rechts komen [b]klanten[/b] met een hashwaarde: ze vragen dat pakje op. Dat is [b]opzoeken[/b]."},
				{"title": "Zoeken = zelfde luik", "text": "Opzoeken gaat precies zoals toevoegen: het pakje ligt in het rek achter luik [b](h(r))|a[/b], de eerste a bits.\n\n[b]Klik op dat luik[/b]. Of druk [b]Tab[/b] (klantfocus) en typ de bits.", "schema": _draw_prefix.bind("01101", 2)},
				{"title": "Let op de tijd", "text": "De band loopt nu door en klanten hebben geduld voor ±15 s. Een klant die boos vertrekt of een gevallen pakje kost een [b]hartje[/b]. Elke opzoeking is één leesrit (L)."},
			]
		"oefening":
			title = "Oefening 5 uit de notas"
			pages = [
				{"title": "De opgave (notas p. 10)", "text": "Voeg de sleutels 3, 7, 12, 45, 44 en 1 toe aan een lege tabel met [b]twee emmers[/b] (a = 1) en [b]g = 2[/b].\n\nh(3) = [code]00000[/code], h(7) = [code]11111[/code], h(12) = [code]01001[/code], h(45) = [code]10001[/code], h(44) = [code]00010[/code], h(1) = [code]00001[/code].", "schema_width": 600, "schema_node": fig_node(1, "0{} 1{}", "Begin: a = 1, twee lege emmers")},
				{"title": "Zonder hulp", "text": "De pakjes tonen sleutel én hashwaarde, maar [b]geen kleuren of hints[/b] en geen loep. Lees de bits zelf.\n\nSterren: geen fouten, en een eindtoestand gelijk aan de oplossing van de oefening."},
				{"title": "Controle", "text": "Na de dag toont het rapport je eindtoestand getekend zoals de figuren in de notas: pointerarray met a, emmers met hun %s. Vergelijk met je eigen oplossing op papier." % AB},
			]
		"klonen":
			title = "Nieuw: identieke pakjes"
			pages = [
				{"title": "Klonen", "text": "Vandaag komen er pakjes met [b]dezelfde hashwaarde[/b]. Welke bits je ook bekijkt: ze horen altijd in [b]hetzelfde[/b] rek."},
				{"title": "Wanneer het faalt", "text": "Zijn er [b]meer dan g[/b] identieke waarden, dan helpt verdubbelen noch zagen: het gaat door tot er [b]geen bits meer[/b] zijn en dan werkt de methode niet (notas p. 8). Kijk 's ochtends wat er gebeurt; met [b]Doorspoelen[/b] ga je sneller.", "schema_width": 600, "schema_node": fig_node(2, "0{01001} 10{} 11{10110,10110}", "Twee klonen: altijd samen")},
				{"title": "'s Middags: de bak", "text": "Een vastzittende derde kloon [b]sleep[/b] je naar de [b]overloopbak[/b] (of druk [b]K[/b]).\n\nHoe je dit echt oplost, is Oefening 4 in de notas: zelf bedenken!"},
			]
	return {"title": title, "pages": pages, "tutorial": true}


# ======================================================================
#  volledige gids (Doel · Handelingen · Theorie)
# ======================================================================

## spec = DaySpec van de huidige dag (of null buiten een dag: dan enkel algemene inhoud).
static func content(spec = null, start_tab := "doel") -> Dictionary:
	return {
		"title": "Hash & Dash · hoe speel je?",
		"tabs": {"doel": goal_pages(spec), "handelingen": action_pages(spec), "theorie": theory_pages()},
		"tab": start_tab,
	}


static func goal_pages(spec) -> Array:
	var out: Array = []
	if spec != null:
		var d: int = spec.day_number
		var head := ("Dag %d · %s" % [d, spec.title]) if d > 0 else "Piekdag"
		var t := "%s\n\n" % _day_goal(spec)
		t += "[b]Vandaag:[/b] n = %d bits, g = %d pakjes per rek, start met a = %d.\n" % [spec.n, spec.g, spec.a0]
		if not spec.stars.is_empty():
			t += "\n[b]Sterren[/b]\n"
			var k := 1
			for s in spec.stars:
				t += "%d %s: %s\n" % [k, "ster" if k == 1 else "sterren", _star_text(s)]
				k += 1
		out.append({"title": head, "text": t})
	out.append({"title": "Het depot = extendible hashing", "text":
		"Je runt een pakjesdepot dat werkt zoals [b]extendible hashing[/b] (lesnotas §2.1.1).\n\n" +
		"• [b]Pakje[/b] = record r, met zijn hashwaarde h(r) in bits.\n" +
		"• [b]Sorteermuur met luiken[/b] = de pointerarray, 2^a vakjes.\n" +
		"• [b]Rek[/b] = emmer (bucket) met plaats voor g records; het getal erop is %s.\n" % AB +
		"• [b]Hendel[/b] = pointerarray verdubbelen.   [b]Zaag[/b] = emmer splitsen.\n" +
		"• [b]Sorteertafel[/b] = herverdelen op bit %s + 1.   [b]Klant[/b] = opzoeken.\n" % AB +
		"• [b]Ritten L / S[/b] = lees- en schrijfoperaties op de schijf. Die wil je zo laag mogelijk (\"opt\" = het minimum)."})
	return out


static func _day_goal(spec) -> String:
	match int(spec.day_number):
		1: return "Sorteer elk pakje via het luik van zijn [b]eerste bit[/b]. Snel en foutloos."
		2: return "Een rek loopt vol terwijl er maar één buis naartoe gaat: [b]verdubbel[/b] (hendel) en [b]splits[/b] (zaag)."
		3: return "De muur is al groot (a = 3). Splits volle rekken met de [b]zaag[/b], zonder te verdubbelen."
		4: return "Sorteer de band én help de [b]klanten[/b]: opzoeken via hetzelfde luik."
		5: return "Een storm van pakjes die met [code]1111[/code] beginnen: soms moet je [b]meermaals[/b] verdubbelen. Geen bitkleuren meer; Shift = loep."
		6: return "Speel [b]Oefening 5[/b] uit de notas (p. 10) na, zonder hulp."
		7: return "Identieke pakjes: zie waar extendible hashing [b]faalt[/b], en red 's middags de dag met de overloopbak."
		0: return "Eindeloze stroom pakjes en klanten. Hoe lang hou jij het vol?"
	return ""


static func _star_text(s: Dictionary) -> String:
	match str(s.get("kind", "")):
		"done": return "de dag uitspelen"
		"no_mistakes": return "geen fouten" + (" en alle klanten geholpen" if s.get("all_customers", false) else "")
		"time": return "klaar binnen %d s" % int(s.get("max", 0))
		"io_optimal": return "ritten (L/S) gelijk aan het optimum"
		"no_doubles": return "niet verdubbelen en ritten optimaal"
		"end_state": return "eindtoestand = oplossing van Oefening 5"
	return str(s.get("kind", ""))


static func action_pages(spec) -> Array:
	var d: int = spec.day_number if spec != null else 7
	var any := spec == null or d == 0
	var t := "[b]Pakje sorteren[/b]\n• Sleep het voorste pakje van de band naar een luik.\n• Of typ de eerste a bits met [code]0[/code]/[code]1[/code]; Backspace wist.\n"
	if any or d >= 2:
		t += "\n[b]Verdubbelen[/b] (vol rek, één buis)\n• Sleep de hendel naar beneden, of druk [b]D[/b].\n"
		t += "\n[b]Splitsen[/b] (vol rek, twee of meer buizen)\n• Klik op de zaag bij het rek, of druk [b]S[/b].\n"
		t += "\n[b]Sorteertafel[/b]\n• Sleep elk pakje naar links (bit 0) of rechts (bit 1), of druk [code]0[/code]/[code]1[/code] of [code]←[/code]/[code]→[/code].\n"
	if any or (spec != null and spec.has_customers()):
		t += "\n[b]Klant helpen[/b] (opzoeken)\n• Klik op het luik waar zijn pakje ligt, of druk [b]Tab[/b] en typ de bits.\n"
	if any or (spec != null and spec.loupe_allowed):
		t += "\n[b]Loep[/b]\n• Hou [b]Shift[/b] ingedrukt: de eerste a bits van elk pakje lichten op.\n"
	if any or (spec != null and (spec.overflow_bin or not spec.phases.is_empty())):
		t += "\n[b]Overloopbak[/b] (dag 7 middag, piekdag)\n• Sleep een vastzittend pakje naar de bak, of druk [b]K[/b].\n"
	var t2 := "• [b]Esc[/b] of de pauzeknop linksboven: pauze (opnieuw, spiekbrief, levelkeuze, speelhal).\n" + \
		"• [b]F1[/b] of [b]?[/b] rechtsboven: deze gids.\n" + \
		"• [b]Ctrl+H[/b] of het huisje: terug naar de speelhal.\n" + \
		"• Elke rit telt: een rek lezen = L, een rek schrijven = S (rechtsboven in de balk)."
	return [
		{"title": "Wat kun je nu doen?", "text": t},
		{"title": "Altijd", "text": t2},
	]


# ======================================================================
#  theorie (lesnotas §2.1.1, p. 5–9)
# ======================================================================

static func theory_pages() -> Array:
	return [
		{"title": "1 · Pointers naar emmers", "text":
			"De records staan op de [b]harde schijf[/b]; we willen het aantal [b]lees- en schrijfoperaties[/b] op de schijf beperken.\n\n" +
			"Een tabel van [b]pointers[/b] wijst naar de data. Die pointerarray past in het geheugen: ernaar kijken kost [b]geen[/b] leesoperatie.\n\n" +
			"De data zit in [b]emmers[/b] (buckets) met plaats voor een vast aantal [b]g[/b] records: een emmer is een blok dat je in één stap leest of schrijft.\n\n" +
			"[color=#8D97B5]lesnotas §2.1.1, p. 5 (Figuur 1)[/color]",
			"schema_width": 520, "schema_node": fig_node(1, "0{00100,01111} 1{10010,11100}", "Figuur 2: a = 1, g = 2")},
		{"title": "2 · a en " + AB, "text":
			"De pointerarray heeft altijd grootte [b]2^a[/b] (de globale diepte a). Het vakje van record r is [b](h(r))|a[/b]: het getal gevormd door de [b]eerste a bits[/b] van h(r).\n" +
			"Bv. x = [code]010011[/code] (19): x|3 = [code]010[/code] = 2.\n\n" +
			"Elke emmer b houdt [b]%s[/b] bij (de lokale diepte): hoeveel bits er geëvalueerd werden toen hij aangemaakt werd. Er wijzen altijd [b]2^(a − %s)[/b] pointers naar emmer b.\n\n" % [AB, AB] +
			"[color=#8D97B5]lesnotas §2.1.1, p. 6[/color]",
			"schema_width": 520, "schema_node": fig_node(2, "0{00100,01111} 10{10010} 11{11100,11111}", "Figuur 4: a = 2, emmer 0 heeft a_b = 1")},
		{"title": "3 · Opzoeken en toevoegen", "text":
			"Bereken h(r) en kijk waar vakje [b](h(r))|a[/b] naartoe wijst. Daar moet je r [b]plaatsen[/b] of [b]opzoeken[/b].\n\n" +
			"[code]i ← (h(r))|a\nb ← p[lb]i]\nlees emmer b            (1 leesoperatie)\nals r toevoegen en b vol: splits b[/code]\n\n" +
			"Opzoeken is nooit een probleem. Toevoegen aan een [b]volle[/b] emmer wel: dan komt er een nieuwe emmer bij, en daarvoor zijn ook 2 pointers nodig.\n\n" +
			"[color=#8D97B5]lesnotas §2.1.1, p. 7[/color]",
			"schema": _draw_prefix.bind("10010", 2)},
		{"title": "4 · %s = a: verdubbelen" % AB, "text":
			"Wijst er maar [b]één[/b] pointer naar de volle emmer, dan verdubbelen we eerst de pointerarray: a wordt a + 1 en\n\n" +
			"[code]p_n[lb]i] = p_o[lb]⌊i/2⌋]   voor 0 ≤ i < 2^a[/code]\n\n" +
			"Nu wijzen twee keer zoveel pointers naar elke emmer; de emmers zelf veranderen niet. Dit gebeurt in het [b]geheugen[/b]: het telt niet mee als lees-/schrijfoperatie.\n\n" +
			"[color=#8D97B5]lesnotas §2.1.1, p. 7 (Figuur 3)[/color]",
			"schema_width": 520, "schema_node": fig_node(2, "0{00100,01111} 1{10010,11100}", "Figuur 3: verdubbeld, emmers nog a_b = 1")},
		{"title": "5 · %s < a: splitsen" % AB, "text":
			"Er wijzen 2^(a − %s) (minstens 2) pointers naar de volle emmer b. Maak een nieuwe emmer b' en verdeel de records op [b]bit nummer %s + 1[/b]: bit 0 blijft in b, bit 1 gaat naar b'. Plaats dan het nieuwe record volgens dezelfde regel.\n\n" % [AB, AB] +
			"Pointers waarvan de eerste %s + 1 bits op 1 eindigen, wijzen voortaan naar b'. Daarna: %s = %s = oud %s + 1.\n\n" % [AB, AB, ABP, AB] +
			"[b]Voorbeeld[/b]: 11111 toevoegen aan Figuur 3. Emmer 1 (%s = 1) wordt gesplitst op bit 2; pointer 2·1 + 1 = 3 ([code]11[/code]) wijst naar de nieuwe emmer: Figuur 4.\n\n" % AB +
			"[color=#8D97B5]lesnotas §2.1.1, p. 7–8 (Figuur 4)[/color]",
			"schema_width": 520, "schema_node": fig_node(2, "0{00100,01111} 10{10010} 11{11100,11111}", "Figuur 4: na toevoegen van 11111")},
		{"title": "6 · Kost", "text":
			"Je moet enkel naar de emmer kijken die te vol zit: misschien met [b]één leesoperatie en twee schrijfoperaties[/b] (oude en nieuwe emmer). Naar de andere emmers moet je zelfs niet kijken.\n\n" +
			"Het uitbreiden van de pointerarray gebeurt in het geheugen en telt niet mee. Bovendien moet de array veel minder vaak verdubbeld worden dan emmers herverdeeld: bij [b]m[/b] herverdelingen en een gelijkmatige verdeling van de hashwaarden zijn er van de orde [b]log m[/b] verdubbelingen.\n\n" +
			"In het spel: de teller [b]L / S[/b] telt precies die ritten.\n\n" +
			"[color=#8D97B5]lesnotas §2.1.1, p. 9[/color]"},
		{"title": "7 · Wanneer het faalt", "text":
			"Bij het herverdelen kan één emmer [b]leeg[/b] blijven terwijl de andere nog altijd vol is: voeg 11110 toe aan Figuur 4: verdubbelen naar a = 3 en splitsen, en toch past 11110 nog niet (Figuur 5). Dan verdubbel je opnieuw.\n\n" +
			"Kent de hashfunctie [b]meer dan g keer dezelfde waarde[/b] toe, dan gaat het uitbreiden door tot er [b]geen bits meer[/b] zijn om te evalueren: de methode werkt niet. Een goede hashfunctie is dus heel belangrijk.\n\n" +
			"[color=#8D97B5]lesnotas §2.1.1, p. 8–9 (Figuur 5) · Oefening 4[/color]",
			"schema_width": 600, "schema_node": fig_node(3, "0{00100,01111} 10{10010} 110{} 111{11100,11111}", "Figuur 5: a = 3, 11110 past nog niet")},
	]


## Schema zoals de figuren in de notas (NotasView): pointerarray met a en emmers met a_b.
static func fig_node(a: int, layout: String, title: String) -> Callable:
	return func() -> Control:
		var m := ExtHashModel.new()
		m.setup(5, 2, a)
		m.load_layout(Days.layout_from(layout))
		var nv := NotasView.new()
		nv.set_snapshot(m.snapshot(), title)
		return nv



## Schema: een hashwaarde in bits, de eerste a bits gemarkeerd = het luik/vakje.
static func _draw_prefix(ci: Control, size: Vector2, bits: String, a: int) -> void:
	var c := Vector2(size.x / 2.0, size.y * 0.42)
	ci.draw_style_box(Pal.sb(Pal.LABEL, 18), Rect2(Vector2(20, c.y - 150), Vector2(size.x - 40, 300)))
	var fs := 56
	var cw := Pal.MONO.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14
	var x0 := c.x - cw * bits.length() / 2.0
	Pal.text_c(ci, Pal.UI_BOLD, Vector2(c.x, c.y - 100), "h(r)", 30, Pal.INK)
	for i in bits.length():
		var r := Rect2(x0 + i * cw + 3, c.y - 40, cw - 6, 80)
		var on := i < a
		ci.draw_style_box(Pal.sb(Pal.WARN if on else Color(Pal.INK, 0.08), 10), r)
		Pal.text_c(ci, Pal.MONO, r.get_center(), bits[i], fs, Pal.INK)
	if a <= 0:
		Pal.text_c(ci, Pal.UI_BOLD, Vector2(c.x, c.y + 90), "hashwaarde van 5 bits", 28, Pal.INK)
		return
	var pre := bits.substr(0, a)
	Pal.text_c(ci, Pal.UI_BOLD, Vector2(c.x, c.y + 90), "(h(r))|%d = %s = %d, dus vakje %s" % [a, pre, HashUtil.from_bits(pre), pre], 28, Pal.INK)
