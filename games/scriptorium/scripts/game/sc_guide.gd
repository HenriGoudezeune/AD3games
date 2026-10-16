class_name ScGuide
extends Object
## Inhoud van de gedeelde gids (HubGuide, design/SHARED_UX.md §2–3) voor Kortschrift: Doel · Handelingen · Theorie,
## plus korte tutorials (3–5 kaartjes) de eerste keer per werktuig (en voor de Voorlezing en de Nachtwake).
## "Gezien" staat in ScSave (tutorials). Het Notas-spiekbriefje (ScCheatSheet.TABS) zit in het tabblad Doel.
## Theorie strikt volgens de lesnotas AD3 hoofdstuk 4 (p. 81–122), met de notatie en de voorbeelden van de notas.
## Schema's worden getekend met ScDraw/ScDrawTools op een perkamentje (Fig: schaalt een nominaal vlak passend).

## werktuig (ScCodes.tool_name) -> tutorial-sleutel en naam
const TOOL_KEY := {"prefix_read": "codeboom", "code_board": "codebord", "bindery": "binderij",
	"living_tree": "levende_boom", "ruler": "meetlat", "window": "leesraam", "stampcase": "stempelkast",
	"drum": "draaitrommel", "shelf": "letterplank", "dovecote": "duiventil"}
const NAMES := {"codeboom": "de codeboom", "codebord": "het codebord", "binderij": "de binderij",
	"levende_boom": "de levende boom", "meetlat": "de meetlat", "leesraam": "het leesraam", "register": "het register",
	"stempelkast": "de stempelkast", "draaitrommel": "de draaitrommel", "letterplank": "de letterplank",
	"duiventil": "het duiventil", "voorlezing": "de Voorlezing", "nachtwake": "de Nachtwake"}
## eerste theoriepagina per werktuig (index in theory_pages())
const THEORY_PAGE := {"duiventil": 0, "codeboom": 1, "codebord": 1, "binderij": 2, "levende_boom": 4, "meetlat": 6,
	"leesraam": 8, "register": 9, "stempelkast": 10, "draaitrommel": 12, "letterplank": 14}

const DIM := "[color=#CDB394]"
const REF := "[color=#F4D27A]"


static func style(tutorial := false) -> Dictionary:
	var s := {
		"panel": ScPal.PANEL, "border": ScPal.GILT, "accent": ScPal.GILT, "accent_text": ScPal.INK,
		"tab": ScPal.PANEL_HI, "text": ScPal.TEXT, "text_dim": ScPal.TEXT_DIM, "font": ScPal.UI,
		"font_bold": ScPal.UI_BOLD, "font_mono": ScPal.MONO_M,
	}
	if tutorial:
		s["size"] = Vector2(1260, 640)
		s["font_size"] = 26
	return s


# ======================================================================
#  tutorials
# ======================================================================

static func seen(key: String) -> bool:
	return ScSave.tutorial_seen(key)


static func mark_seen(key: String) -> void:
	ScSave.mark_tutorial(key)


## Tutorial-sleutel van een stage ("register" voor het leesraam met register).
static func key_for_stage(st: Dictionary) -> String:
	var tl := str(st.get("tool", ""))
	if tl == "window" and bool(st.get("register", false)):
		return "register"
	return TOOL_KEY.get(tl, "")


## Sleutel als die tutorial nog niet gezien is, anders "".
static func pending(key: String) -> String:
	if key == "" or seen(key):
		return ""
	return key


static func tutorial(key: String) -> Dictionary:
	var pages: Array = []
	var title := "Nieuw: " + str(NAMES.get(key, key))
	match key:
		"codeboom":
			pages = [
				{"title": "Wat zie je?", "text": "De [b]codeboom[/b]: de wortel staat boven, een tak naar [b]links is 0[/b], naar [b]rechts is 1[/b]. Aan de bladeren hangen de letters.\n\nBovenaan ligt een [b]strook bits[/b]: een bericht in deze code.", "schema_node": fig(_fig25.bind(""))},
				{"title": "Het doel", "text": "Lees de strook terug naar tekst (decoderen, notas p. 83).\n\nBegin bij de wortel en volg de bits tot je een [b]blad[/b] bereikt. Schrijf die letter op en begin opnieuw bij de wortel."},
				{"title": "Wat kun je doen?", "text": "• [b]Klik het blad[/b] waar de volgende bits naartoe leiden.\n• Of kies met [b]←/→[/b] en bevestig met [b]Enter[/b].\n\nDe leesvinger loopt het pad af en knipt het codewoord van de strook."},
				{"title": "Mini-voorbeeld (Figuur 25)", "text": "Strook [code]00010011[/code]:\n[code]00[/code] → o, dan [code]010[/code] → u, dan [code]011[/code] → d.\nHet woord is [b]oud[/b].\n\nVastgelopen? [b]F1[/b] of de [b]?[/b]-knop rechtsboven opent deze uitleg opnieuw, met ook de theorie uit de notas.", "schema_node": fig(_fig25.bind("oud"))},
			]
		"codebord":
			pages = [
				{"title": "Grenzen knippen", "text": "De kelner schrijft in zijn eigen code, en die is [b]geen prefixcode[/b]: het ene codewoord is het begin van een ander. Waar stopt een letter? Met e = [code]0[/code], n = [code]1[/code], b = [code]10[/code] kan [code]10[/code] zowel b als ne zijn.\n\n• [b]Klik tussen twee bits[/b] om de strook te knippen.\n• [b]Opnieuw lezen[/b] (R) begint opnieuw, [b]Klaar[/b] stuurt de strook door."},
				{"title": "Een prefixcode ontwerpen", "text": "Op het [b]codebord[/b] maak je zelf een code: een leeg boomraam.\n\n• [b]Sleep[/b] een lettertegel op een knoop (of klik de tegel en dan de knoop).\n• [b]Rechtsklik[/b] haalt een tegel weg.\n• Het pad van de wortel naar de tegel is het codewoord."},
				{"title": "De regel (Definitie 20)", "text": "Een prefixcode: geen codewoord is het begin van een ander. In de boom: letters hangen enkel aan [b]bladeren[/b]. Dan weet de lezer altijd waar een letter stopt.\n\nDe inktpot telt [code]Σ a(x)·l(x)[/code]: hoe vaak x voorkomt maal de lengte van zijn code. Daarna: [b]Verzenden[/b].", "schema_node": fig(_fig25.bind(""))},
			]
		"binderij":
			pages = [
				{"title": "Wat zie je?", "text": "Een rij [b]stapels perkament[/b]: één per letter. De hoogte is het [b]gewicht a(x)[/b]: hoe vaak de letter in de tekst voorkomt.\n\nKlik je twee stapels, dan bindt de kopiist ze tot één bundel.", "schema_node": fig(_fig_piles, Vector2(520, 340))},
				{"title": "Het doel: Huffman", "text": "Bind telkens de [b]twee lichtste[/b] stapels samen (Algoritme 9). De bundel weegt de som en krijgt een boompje: links 0, rechts 1. Herhaal tot er één boom is.\n\nDe touwklos telt het touw = de som van de gewichten van alle bundels = het aantal bits.", "schema_node": fig(_fig_huff)},
				{"title": "Wat kun je doen?", "text": "• [b]Klik twee stapels[/b] na elkaar: de kopiist bindt ze.\n• Of kies met [b]←/→[/b] en markeer/bind met [b]Spatie[/b].\n\nBij gelijk gewicht is elke keuze even goed (de boom is niet uniek)."},
				{"title": "Mini-voorbeeld: boosdoeer", "text": "Gewichten b:1 o:3 e:2 s:1 d:1 r:1.\nBind b+s (2), dan d+r (2), dan die twee (4), dan e+o (5), tot slot 4+5 (9).\n\nCodes: o = [code]10[/code], e = [code]11[/code], b = [code]000[/code], s = [code]001[/code], d = [code]010[/code], r = [code]011[/code]: samen [b]22 bits[/b].", "schema_node": fig(_fig_huff)},
			]
		"levende_boom":
			pages = [
				{"title": "Wat zie je?", "text": "Adaptieve Huffman (notas §4.1.1): de boom groeit [b]terwijl[/b] je schrijft. Elke top is een monnik met een kaartje [code][lb]gewicht, nummer][/code]. Het groene zaadje is [b]nng[/b] (nog niet gezien).\n\nOnderaan loopt de processie in volgorde van ordenummer.", "schema_node": fig(_fig_fgk)},
				{"title": "Eerst schrijven", "text": "• [b]Klik het blad[/b] van de volgende letter: je schrijft zijn code met de [b]oude[/b] boom.\n• Nieuwe letter? Klik het [b]zaadje nng[/b]: code van nng + de letter in 8 bits."},
				{"title": "Dan klimmen (Algoritme 11)", "text": "De lantaarn hangt bij top t. Zoek t′: [b]zelfde gewicht, hoogste nummer[/b].\n\n• [b]Klik t′[/b] om t en t′ te wisselen; t krijgt +1 en de lantaarn gaat naar de ouder.\n• Is t′ de top zelf, of zijn ouder: niet wisselen. Klik de monnik met de lantaarn of [b]Blijf staan[/b] (B)."},
				{"title": "Waarom?", "text": "Zo blijven (a) gewicht = som van de kinderen, (b) gewicht stijgt met het nummer en (c) 2j−1 en 2j zijn broers waar: dan is de boom optimaal (Lemma 22, p. 90)."},
			]
		"meetlat":
			pages = [
				{"title": "Wat zie je?", "text": "Aritmetisch coderen (notas §4.2). De [b]meetlat[/b] is het huidige interval [code][lb]links, links+lengte)[/code]: 0 onder, 1 boven. Elke letter heeft een vak zo groot als zijn kans p.", "schema_node": fig(_fig_ruler)},
				{"title": "Knippen (Algoritme 12)", "text": "• [b]Klik het vak[/b] van de volgende letter (of typ de letter).\nDe schaar knipt: links += f·lengte en lengte ×= p. De lat zoomt in op dat vak. Het rekenboek noteert elke stap."},
				{"title": "De binaire naald (Algoritme 13)", "text": "Zoek de kortste bitstring in [code][lb]low, up)[/code]:\n• [b]1 = stap[/b] (toets 1) als getal + next < up,\n• [b]0 = blijf[/b] (toets 0) anders.\nStop zodra getal ≥ low. Is low = 0: schrijf meteen 0."},
				{"title": "Ontvangen", "text": "Een koperen [b]speld[/b] staat op de waarde van de bits. [b]Klik het vak[/b] waarin ze zit; de lat zoomt in.\n\nLet op: de onderrand hoort bij het vak (dicht), de bovenrand niet (open)."},
			]
		"leesraam":
			pages = [
				{"title": "Wat zie je?", "text": "LZ77 (notas §4.3). Eén regel tekst met een [b]houten raam[/b] over de laatste G tekens. De posities in het raam tellen [b]vanaf 0 links[/b].", "schema_node": fig(_fig_lz77)},
				{"title": "Zenden", "text": "Zoek de [b]langste match[/b] die in het raam begint (ze mag erbuiten eindigen).\n\n• [b]Klik de letter[/b] in het raam waar de match begint: de rode draad loopt mee.\n• Geen match? [b]Geen match[/b] (G).\nElk drietal [code](p, l, x)[/code] wordt een groen zegel."},
				{"title": "Ontvangen", "text": "Een zegel [code](p, l, x)[/code] komt binnen. [b]Klik positie p[/b] in het raam: de kopiist kopieert l letters één voor één en schrijft dan x."},
				{"title": "Mini-voorbeeld", "text": "banaan-baan met G = 6: na [code]ban[/code] begint [code]aa[/code] met een match van lengte 1 op positie 1, gevolgd door a: [code](1,1,a)[/code].\nOp het einde: [code]aan[/code] staat op positie 1 van het raam [code]naan-b[/code]: [code](1,3,EOF)[/code].", "schema_node": fig(_fig_lz77)},
			]
		"register":
			pages = [
				{"title": "Een oneindig raam", "text": "Nu is er geen sliding window meer (G = ∞): de hele tekst tot nu is het woordenboek. Zelf zoeken wordt dan traag."},
				{"title": "Het register", "text": "Het [b]register[/b] is een deelstringboom (notas §4.3.1) die meegroeit met de tekst.\n\n• [b]Register[/b] (R): de lantaarn zoekt de langste match.\n• De teller [b]zoeken[/b] telt je blikken: met het register één per letter."},
				{"title": "Waarom snel?", "text": "Per letter kijk je enkel of er een tak (of het volgende teken op de boog) met die letter verder gaat: gemiddeld O(1) per teken, dus O(n) voor de hele tekst. Maar de boom vraagt veel geheugen."},
			]
		"stempelkast":
			pages = [
				{"title": "Wat zie je?", "text": "LZW (notas §4.4). De [b]stempelkast[/b]: bovenaan de laden van de letters (met hun code, a = 97), daaronder de nieuwe laden [b]256, 257, ...[/b]\n\nDe [b]zetstok[/b] houdt het woord w; ernaast staat het volgende teken k.", "schema_node": fig(_fig_lzw)},
				{"title": "Zenden", "text": "• Zit [b]wk[/b] al in de kast? Trek [b]Verleng[/b] (V): w wordt wk.\n• Anders: [b]Stempel[/b] (S): code(w) gaat op de strook, wk krijgt de volgende lade, en w = k."},
				{"title": "Ontvangen", "text": "Een code komt binnen en de lade gaat open. Snijd de nieuwe stempel: [b]vorig woord + eerste letter van dit woord[/b] (klik de letter, of 1…9).\n\nIs de lade nog [b]leeg[/b] (het speciale geval)? Dan begint het woord zoals het vorige: volgend = w + w[lb]0]."},
				{"title": "Mini-voorbeeld", "text": "banaanaanval: b → [code]98[/code] (ba = 256), a → [code]97[/code] (an = 257), n → [code]110[/code] (na = 258), a → [code]97[/code] (aa = 259), an → [code]257[/code] (ana = 260), aa → [code]259[/code] (aan = 261) ..."},
			]
		"draaitrommel":
			pages = [
				{"title": "Zenden: alle rotaties", "text": "Burrows-Wheeler (notas §4.5). De [b]trommel[/b] drukt de tekst cyclisch: bij elke slag een strook die één letter verder begint.\n\n• Schuif elke strook in de juiste [b]spleet[/b] van het rek, zodat het rek gesorteerd blijft: klik tussen twee stroken of ↑/↓ + Enter.", "schema_node": fig(_fig_bwt)},
				{"title": "Markeer p", "text": "• [b]Klik de rij[/b] die eindigt op het [b]eerste teken[/b] van de tekst: dat is p.\nDe uitvoer is p en de [b]laatste kolom[/b].\n\nDe spatie is kleiner dan alle letters.", "schema_node": fig(_fig_bwt)},
				{"title": "Ontvangen: de terugweg", "text": "Twee kolommen: [b]e[/b] (gesorteerd) en [b]c[/b] (de laatste kolom). In e staat een letter x gemarkeerd.\n\n• [b]Klik in c[/b] dezelfde letter met dezelfde rang: de k-de x in e is de k-de x in c.", "schema_node": fig(_fig_bwt_back)},
			]
		"letterplank":
			pages = [
				{"title": "Wat zie je?", "text": "Move-to-front (notas p. 121). Houten blokjes op een plank: de [b]lijst[/b] van tekens. De posities tellen [b]vanaf 0[/b].", "schema_node": fig(_fig_mtf)},
				{"title": "Zenden", "text": "Stempel de [b]positie[/b] van de volgende letter:\n• klik de cijferstempels, of typ het getal + Enter.\nDaarna schuift dat blokje [b]vooraan[/b] (positie 0)."},
				{"title": "Ontvangen", "text": "Een getal komt binnen. [b]Klik het blokje[/b] op die positie (of typ het getal): die letter schrijf je, en ze schuift vooraan."},
				{"title": "Mini-voorbeeld", "text": "Lijst ( ,1,a,b,e,f,g,n,o,l), tekst [code]1 ngen eool[/code]:\n1 → [code]1[/code], spatie → [code]1[/code], n → [code]7[/code], g → [code]7[/code], e → [code]6[/code], ...\nUit een BWT komen veel [b]nullen en kleine getallen[/b]: goed voor Huffman.", "schema_node": fig(_fig_mtf)},
			]
		"duiventil":
			pages = [
				{"title": "Wat zie je?", "text": "Acht duiven: alle berichten van [b]3 bits[/b]. Het duiventil heeft maar zeven kortere hokken: het lege woord, 0, 1, 00, 01, 10, 11.", "schema_node": fig(_fig_dovecote)},
				{"title": "Wat kun je doen?", "text": "• [b]Klik een duif[/b] en dan een [b]hok[/b] (of sleep).\n• Daarna twee decreten van de abt: klik [b]onmogelijk[/b], [b]waar[/b] of [b]vals[/b]."},
				{"title": "Wat leer je?", "text": "De achtste duif past nergens: ze moet naar de zolder (4 bits). Wie een bestand korter maakt, maakt een ander langer (notas p. 81, Oefening 76).", "schema_node": fig(_fig_count)},
			]
		"voorlezing":
			title = "Nieuw: de Voorlezing"
			pages = [
				{"title": "De duif vliegt", "text": "Je kortschrift gaat met de duif naar [b]De Overkant[/b]. Daar leest Broeder [b]Letterlijk[/b] het voor, letter per letter, precies zoals het er staat.", "schema_node": fig(_fig_reading)},
				{"title": "Gelijk of anders", "text": "• [b]Gouden stip[/b]: gelijk aan het origineel.\n• [b]Bruine inkt + inktvlek[/b]: anders gelezen. Dan liep er iets mis in je code of je zetten.\n\nCompressie moet [b]verliesloos[/b] zijn: elke letter moet terugkomen.", "schema_node": fig(_fig_reading)},
				{"title": "Wat kun je doen?", "text": "• [b]Klik[/b] of [b]Spatie[/b] versnelt de voorlezing; daarna [b]Verder[/b].\n• In het [b]Kapittel[/b] zie je sterren, inkt en de oorzaak van elke vlek; [b]Herneem vanaf hier[/b] speelt vanaf die zet opnieuw."},
			]
		"nachtwake":
			title = "Nieuw: de Nachtwake"
			pages = [
				{"title": "Eindeloos binden", "text": "Elke ronde een nieuwe rij stapels. [b]Bind Huffman[/b] (telkens de twee lichtste) voor de kaars opbrandt.", "schema_node": fig(_fig_wake)},
				{"title": "Streng", "text": "Een verkeerd paar (niet de twee lichtste) [b]knapt het touw[/b]: er wordt niet gebonden. Brandt de kaars op, dan verlies je een kaarsje (3 levens).\n\n• Klik twee stapels, of ←/→ + Spatie."},
				{"title": "Lezen en punten", "text": "Soms volgt een leesronde: lees een strook met de [b]codeboom die je net bond[/b] (klik de bladeren).\n\nSnel en foutloos = combo. Stoppen kan via de pauze (Esc): je score wordt bewaard."},
			]
	return _qa_page({"title": title, "pages": _clean_pages(pages), "tutorial": true})


# ======================================================================
#  volledige gids (Doel · Handelingen · Theorie)
# ======================================================================

## spec = het level (of null buiten een level), tool = huidig werktuig (ScCodes.tool_name), wake = Nachtwake.
static func content(spec = null, tool := "", wake := false, start_tab := "doel") -> Dictionary:
	var key := ""
	if tool != "" and spec != null:
		key = TOOL_KEY.get(tool, "")
		for st in spec.stages:
			if str(st.get("tool", "")) == tool and bool(st.get("register", false)):
				key = "register"
	var c := {
		"title": "Kortschrift · hoe speel je?",
		"tabs": {"doel": _clean_pages(goal_pages(spec, key, wake)), "handelingen": _clean_pages(action_pages(spec, key, wake)),
			"theorie": _clean_pages(theory_pages())},
		"tab": start_tab,
	}
	if start_tab == "theorie" and THEORY_PAGE.has(key):
		c["page"] = int(THEORY_PAGE[key])
	return _qa_page(c)


## QA (frame-opnames): `guide_page=N` opent de gids/tutorial op pagina N.
static func _qa_page(c: Dictionary) -> Dictionary:
	if ScSession.has("guide_page"):
		c["page"] = int(ScSession.arg("guide_page"))
	return c


static func goal_pages(spec, key: String, wake: bool) -> Array:
	var out: Array = []
	if wake:
		out.append({"title": "De Nachtwake", "text": "Eindeloos: bind elke ronde de stapels met [b]Huffman[/b] (Algoritme 9, notas p. 84) voor de kaars opbrandt. Een verkeerd paar knapt het touw. Drie kaarsjes = drie levens.\n\nPunten: per ronde, met een combo voor snel en foutloos werk. De beste nachten komen in de top-10."})
	elif spec != null:
		var t := ""
		if str(spec.intro) != "":
			t += "[i]Zeno: \"%s\"[/i]\n\n" % spec.intro
		t += "[b]Opdracht[/b]\n"
		for st in spec.stages:
			t += "• %s\n" % ScBrief._stage_line(st)
		if not spec.stars.is_empty():
			t += "\n[b]Sterren[/b]\n"
			var k := 1
			for s in spec.stars:
				t += "%d. %s\n" % [k, ScScoring.star_label(s)]
				k += 1
		t += "\n%s%s[/color]" % [REF, spec.notes_ref]
		out.append({"title": "%s · %s" % [spec.id, spec.title], "text": t})
	var sheet := _sheet_page(spec, key, wake)
	if not sheet.is_empty():
		out.append(sheet)
	out.append({"title": "Kortschrift in het kort", "text":
		"Jij bent de kopiist van een scriptorium. Je schrijft berichten zo [b]kort[/b] mogelijk op een strook (het kortschrift); een duif brengt die naar [b]De Overkant[/b], waar Broeder Letterlijk ze letterlijk voorleest.\n\n" +
		"• [b]Verliesloos[/b]: Letterlijk moet precies de oorspronkelijke tekst terugvinden.\n" +
		"• [b]Kort[/b]: de inktmeter telt de bits (of zegels, stempels); \"optimum\" is het minimum.\n" +
		"• Elk werktuig is een algoritme uit hoofdstuk 4 van de lesnotas: codeboom en codebord (prefixcodes), binderij (Huffman), levende boom (adaptieve Huffman), meetlat (aritmetisch coderen), leesraam (LZ77), stempelkast (LZW), draaitrommel (Burrows-Wheeler) en letterplank (move-to-front).\n" +
		"• Zeno's inkthand (F2) toont de juiste zet en terugnemen (Ctrl+Z) kan, maar dat kost de derde ster."})
	return out


## Spiekbrief (ScCheatSheet.TABS) van het huidige werktuig en de andere werktuigen van dit level.
static func _sheet_page(spec, key: String, wake: bool) -> Dictionary:
	var tools: Array = []
	if wake:
		tools = ["bindery", "prefix_read"]
	elif spec != null:
		for st in spec.stages:
			var tl := str(st.get("tool", ""))
			if not tools.has(tl):
				tools.append(tl)
	else:
		return {}
	var t := ""
	for tl in tools:
		for tb in ScCheatSheet.TABS:
			if str(tb.tool) == tl:
				t += "[b]%s[/b]\n" % str(tb.name)
				for ln in tb.lines:
					t += "• %s  %s(%s)[/color]\n" % [str(ln[0]), DIM, str(ln[1])]
				t += "\n"
	if t == "":
		return {}
	return {"title": "Spiekbrief uit de notas", "text": t.strip_edges()}


static func action_pages(spec, key: String, wake: bool) -> Array:
	var keys: Array = []
	if wake:
		keys = ["binderij", "codeboom"]
	elif spec != null:
		for st in spec.stages:
			var k := key_for_stage(st)
			if k != "" and not keys.has(k):
				keys.append(k)
		if key != "" and keys.has(key):
			keys.erase(key)
			keys.push_front(key)
	else:
		keys = ["codeboom", "codebord", "binderij", "levende_boom", "meetlat", "leesraam", "register", "stempelkast",
			"draaitrommel", "letterplank", "duiventil"]
	var out: Array = []
	for k in keys:
		var tx := _actions(k)
		if tx != "":
			out.append({"title": "Nu: " + str(NAMES.get(k, k)) if spec != null or wake else str(NAMES.get(k, k)).capitalize(), "text": tx})
	out.append({"title": "Altijd", "text":
		"• [b]Klik[/b] een blad, stapel, monnik, vak, letter, rij of blokje: wat je kunt aanklikken licht op onder de muis.\n" +
		"• [b]←/→[/b] (of ↑/↓) kiest met het toetsenbord, [b]Enter[/b] bevestigt.\n" +
		"• [b]Spatie[/b] ingedrukt: de kopiist werkt sneller.\n" +
		"• [b]F1[/b] of de [b]?[/b]-knop rechtsboven: deze gids. [b]F2[/b] of de handknop: Zeno's inkthand (kost de derde ster).\n" +
		"• [b]Ctrl+Z[/b] of de pijlknop: zet terugnemen (kost de derde ster).\n" +
		"• [b]Esc[/b] of de pauzeknop linksboven: pauze (opnieuw, instellingen, levelkeuze, speelhal).\n" +
		"• [b]Ctrl+H[/b] of het huisje: terug naar de speelhal."})
	return out


static func _actions(k: String) -> String:
	match k:
		"codeboom":
			return "[b]Lezen[/b]\n• Klik het blad waar de volgende bits naartoe leiden (of ←/→ + Enter).\n• De leesvinger volgt het pad; na een blad begin je opnieuw bij de wortel."
		"codebord":
			return "[b]Grenzen[/b] (strook van de kelner)\n• Klik tussen twee bits om te knippen.\n• [b]R[/b] of \"Opnieuw lezen\": opnieuw beginnen. \"Klaar\": doorsturen.\n\n[b]Codebord[/b] (eigen code)\n• Sleep een lettertegel op een knoop, of klik de tegel en dan de knoop.\n• Rechtsklik haalt een tegel weg. \"Verzenden\": Letterlijk proefleest."
		"binderij":
			return "[b]Binden[/b]\n• Klik twee stapels na elkaar: de twee lichtste.\n• Of ←/→ om te kiezen en [b]Spatie[/b] om te markeren/binden.\n• Twee planken (Oefening 85): neem enkel van de [b]voorkant[/b] van plank A of B."
		"levende_boom":
			return "[b]Schrijven / lezen[/b]\n• Klik het blad van de letter, of het zaadje nng voor een nieuwe letter.\n\n[b]Klimmen[/b]\n• Klik de wisselpartner t′ (zelfde gewicht, hoogste nummer).\n• Niet wisselen: klik de monnik met de lantaarn of \"Blijf staan\" ([b]B[/b])."
		"meetlat":
			return "[b]Knippen[/b]\n• Klik het vak van de volgende letter, of typ de letter.\n\n[b]Binaire naald[/b]\n• [b]1[/b] = stap, [b]0[/b] = blijf (knoppen of toetsen 1/0).\n\n[b]Ontvangen[/b]\n• Klik het vak waarin de speld staat."
		"leesraam":
			return "[b]Zenden[/b]\n• Klik de letter in het raam waar de langste match begint.\n• Geen match: knop \"Geen match\" of [b]G[/b].\n\n[b]Ontvangen[/b]\n• Klik positie p van het zegel in het raam."
		"register":
			return "[b]Register[/b]\n• Knop \"Register\" of [b]R[/b]: de lantaarn zoekt de langste match.\n• Of klik zelf de beginletter (elke blik telt bij \"zoeken\").\n• Geen match: [b]G[/b]."
		"stempelkast":
			return "[b]Zenden[/b]\n• Hendel \"Verleng\" ([b]V[/b]) als wk in de kast zit.\n• Hendel \"Stempel\" ([b]S[/b]) anders.\n\n[b]Ontvangen[/b]\n• Snijd de nieuwe stempel: klik de letter, of toets 1…9."
		"draaitrommel":
			return "[b]Zenden[/b]\n• Klik de spleet waar de nieuwe strook hoort (of ↑/↓ + Enter).\n• Klik daarna de rij die eindigt op het eerste teken (p).\n\n[b]Terugweg[/b]\n• Klik in c dezelfde letter met dezelfde rang als de gemarkeerde letter in e."
		"letterplank":
			return "[b]Zenden[/b]\n• Klik de cijferstempels van de positie, of typ het getal + Enter.\n\n[b]Ontvangen[/b]\n• Klik het blokje op de gegeven positie (of typ het getal)."
		"duiventil":
			return "• Klik een duif en dan een hok (of sleep).\n• Daarna: klik je antwoord op de decreten van de abt."
	return ""


# ======================================================================
#  theorie (lesnotas hoofdstuk 4, p. 81–122)
# ======================================================================

static func theory_pages() -> Array:
	return [
		# 0
		{"title": "1 · Compressie zonder verlies", "text":
			"[b]Met verlies[/b] (jpg, mp3) kan je het origineel niet terugkrijgen. Wij bekijken enkel compressie [b]zonder verlies[/b]: elke bit van het bestand moet te reconstrueren zijn.\n\n" +
			"[b]Niet alles is comprimeerbaar.[/b] Twee bestanden mogen niet op hetzelfde resultaat afgebeeld worden. Wordt er één bestand echt korter, dan wordt er ook minstens één [b]langer[/b] (Oefening 76).\n\n" +
			"Er zijn [code]Σ 256^i = (256^(n+1) - 1)/255[/code] bestanden met ten hoogste n bytes, tegen [code]256^(n+1)[/code] met n+1 bytes: hoogstens [b]1/255[/b] daarvan kan één byte korter.\n\n" +
			"Het werkt toch omdat echte bestanden [b]structuur[/b] hebben (sommige letters komen veel vaker voor). Toevallige bits comprimeer je niet.\n\n" +
			"%slesnotas hoofdstuk 4, p. 81–82[/color]" % REF, "schema_node": fig(_fig_count)},
		# 1
		{"title": "2 · Prefixcodes en codebomen", "text":
			"Codewoorden van variabele lengte achter elkaar: waar stopt het ene woord? Oplossing: een prefixcode.\n\n" +
			"[b]Definitie 20[/b]: een verzameling woorden is een [b]prefixcode[/b] als geen woord het begin (prefix) van een ander woord is.\n\n" +
			"Een prefixcode is een [b]boom[/b] met bogen gelabeld 0 en 1; de codewoorden zijn de paden van de wortel naar de [b]bladeren[/b], de tekens staan aan de bladeren.\n\n" +
			"[b]Decoderen[/b]: volg de bits tot een blad, schrijf het teken, begin opnieuw bij de wortel.\n" +
			"Figuur 25: [code]00010011[/code] = [code]00|010|011[/code] = [b]oud[/b].\n\n" +
			"%slesnotas p. 82–83 (Figuur 24, 25)[/color]" % REF, "schema_node": fig(_fig25.bind("oud"))},
		# 2
		{"title": "3 · Huffman codering (Algoritme 9)", "text":
			"Komt x a(x) keer voor en is l(x) de lengte van zijn code, dan is het gecodeerde bestand [code]Σ a(x)·l(x)[/code] bits lang. Kies de code zodat dat [b]minimaal[/b] is.\n\n" +
			"[b]Algoritme 9[/b] (gretig):\n• elke letter met a(x) > 0 is een boom met één top;\n• herhaal tot er één boom is: neem de twee bomen X en Y met de [b]kleinste[/b] frequentie, maak ze kinderen van een nieuwe wortel Z met a(Z) = a(X) + a(Y).\n\n" +
			"De boom is niet uniek, maar alle bomen zijn even goed. [b]boosdoeer[/b]: b 000, o 10, e 11, s 001, d 010, r 011, samen 22 bits.\n\n" +
			"%slesnotas §4.1, p. 84–86[/color]" % REF, "schema_node": fig(_fig_huff)},
		# 3
		{"title": "4 · Huffman is optimaal (Stelling 21)", "text":
			"[b]Stelling 21[/b]: voor een alfabet x1..xk (k ≥ 2) met frequenties a(xi) geeft Huffman een prefixboom T met [code]Q(T) = Σ l(xi)·a(xi)[/code] minimaal.\n\n" +
			"[b]Bewijsidee[/b]\n• In een optimale boom heeft elke top 0 of 2 kinderen.\n• De twee lichtste letters mag je als [b]broers op het laagste niveau[/b] zetten: wisselen geeft [code]Q' = Q - (a(y)-a(x))(l(y)-l(x)) ≤ Q[/code].\n• Inductie op de grootte van het alfabet: vervang die twee door één top met de som van hun frequenties.\n\n" +
			"Dit is [b]statische[/b] Huffman: je moet het bestand twee keer lezen. Om de twee kleinste te vinden kan je twee lijsten gebruiken (Oefening 85).\n\n" +
			"%slesnotas p. 86–88[/color]" % REF},
		# 4
		{"title": "5 · Adaptieve Huffman (FGK)", "text":
			"Eén keer lezen, dus ook voor streams. Teken ti wordt gecodeerd met een optimale boom voor [code]nng, t1, ..., t(i-1)[/code]; daarna gaat het gewicht van ti met 1 omhoog en wordt de boom bijgewerkt. [b]nng[/b] = \"nog niet gezien\".\n\n" +
			"Elke top t heeft een gewicht a(t) en een ordenummer o(t): notatie [code][lb]gewicht,nummer][/code].\n\n" +
			"[b]Lemma 22[/b]: voldoet de boom aan\n(a) gewicht van een interne top = som van de kinderen,\n(b) o(t) < o(t′) ⇒ a(t) ≤ a(t′),\n(c) toppen 2j−1 en 2j zijn broers,\ndan is hij optimaal.\n\n" +
			"%slesnotas §4.1.1, p. 89–90[/color]" % REF, "schema_node": fig(_fig_fgk)},
		# 5
		{"title": "6 · De boom bijwerken (Alg. 10 en 11)", "text":
			"[b]Schrijf eerst[/b] de code van het teken met de oude boom. Dan, vanaf het blad t tot de wortel:\n" +
			"[code]t' = top met a(t') = a(t), o(t') maximaal\nals t' niet de ouder van t is:\n    wissel t en t' (en hun nummers)\na(t) += 1;  t = ouder van t[/code]\n\n" +
			"[b]Nieuw teken[/b]: schrijf code(nng) + het teken in 8 bits. De nng-top wordt een ouder o met kinderen nng (nummer 1, gewicht 0) en het nieuwe teken (nummer 2); o krijgt nummer 3, alle andere nummers +2. Ga verder bij de ouder van o.\n\n" +
			"[b]Speciaal geval[/b]: is t′ de ouder van t, dan niet wisselen (\"eetzaal\").\n\n" +
			"Het aantal iteraties is hoogstens de diepte d van het teken (Lemma 23): O(d).\n\n" +
			"%slesnotas p. 91–98[/color]" % REF},
		# 6
		{"title": "7 · Aritmetisch coderen: intervallen", "text":
			"Een [b]model[/b] geeft elk teken een kans p(t). Elke string s krijgt een interval [code]i(s) = [lb]a, b)[/code] in [code][lb]0, 1)[/code]; voor elke lengte n vormen die intervallen een partitie. De lengte van i(s) = het [b]product[/b] van de kansen.\n\n" +
			"Model van de notas: p(x) = 0.2, p(y) = 0.7, p(z) = 0.1, dus i(x) = [code][lb]0, 0.2)[/code], i(y) = [code][lb]0.2, 0.9)[/code], i(z) = [code][lb]0.9, 1)[/code].\n\n" +
			"[b]Algoritme 12[/b], met f(t) = begin van het vak van t:\n[code]links = 0; lengte = 1\nvoor elk teken s[lb]i]:\n  links += f(s[lb]i]) * lengte\n  lengte *= p(s[lb]i])[/code]\n\n" +
			"Voorbeeld: i(yy) = [code][lb]0.34, 0.83)[/code].\n\n" +
			"%slesnotas §4.2, p. 98–101[/color]" % REF, "schema_node": fig(_fig_ruler)},
		# 7
		{"title": "8 · Aritmetisch coderen: de bits", "text":
			"Een bitstring b1..bk stelt [code]Σ bi·2^(-i)[/code] voor. 0.5 = binair [code]1[/code] ligt in i(yy), dus [code]1[/code] codeert yy.\n\n" +
			"[b]Lemma 24[/b]: een interval met lengte l bevat een getal met hoogstens [code]⌈log(1/l)⌉[/code] bits.\n\n" +
			"[b]Algoritme 13[/b] (kortste bitstring in [code][lb]low, up)[/code]):\n[code]getal = 0; next = 0.5\nals low = 0: output 0, klaar\nherhaal:\n  als getal + next < up:\n    output 1; getal += next\n    als getal >= low: klaar\n  anders output 0\n  next = next / 2[/code]\n\n" +
			"De lengte n moet mee (of een einde-teken). 40 letters [code]yyyxzx...[/code] passen in [b]1 bit[/b]. In de praktijk: vaste precisie door te herschalen.\n\n" +
			"%slesnotas p. 100–103[/color]" % REF},
		# 8
		{"title": "9 · LZ77 (Algoritme 14)", "text":
			"De tekst zelf is het woordenboek. Een [b]sliding window[/b] houdt de laatste G tekens bij; posities in het raam tellen vanaf links, vanaf 0.\n\n" +
			"• Zoek de [b]langste match[/b] voor de tekst vanaf positie k. De match moet in het raam [b]beginnen[/b], maar mag erbuiten eindigen.\n• Schrijf [code](p, l, x)[/code]: begin p, lengte l, volgend teken x. Geen match: [code](0, 0, x)[/code].\n• Ga verder op positie k + l + 1.\n\n" +
			"[b]banaan-baan[/b], G = 6:\n[code](0,0,b) (0,0,a) (0,0,n) (1,1,a)\n(2,1,-) (0,0,b) (1,3,EOF)[/code]\n\n" +
			"[b]Decoderen[/b]: bouw hetzelfde raam op en kopieer letter per letter (altijd efficiënt). De uitvoer kan daarna nog Huffman gecodeerd worden (DEFLATE/gzip: twee bomen).\n\n" +
			"%slesnotas §4.3, p. 104–109[/color]" % REF, "schema_node": fig(_fig_lz77)},
		# 9
		{"title": "10 · LZ77 met deelstringbomen (§4.3.1)", "text":
			"Het zoeken van de langste match is duur in een groot raam: een raam heeft geen structuur.\n\n" +
			"Zonder sliding window (een [b]oneindig[/b] raam) kan het in [b]lineaire tijd[/b]: bouw met het algoritme van Ukkonen de deelstringboom van [code]s1..s(i-1)[/code] en zoek er [b]tegelijk[/b] in.\n\n" +
			"• Alle updates samen kosten O(n) (Stelling 8): gemiddeld O(1) per teken.\n• Zoeken: per teken enkel kijken of er een tak (of het volgende teken op de boog) met dat teken verdergaat: O(1), één keer per teken.\n• Samen: [b]O(n)[/b] voor de hele tekst.\n\n" +
			"Maar: een echt lange tekst vraagt [b]extreem veel geheugen[/b] voor de boom; je kan de tekst in blokken opdelen.\n\n" +
			"%slesnotas §4.3.1, p. 109–110[/color]" % REF},
		# 10
		{"title": "11 · LZW: coderen", "text":
			"Een [b]echt woordenboek[/b] (codes van 12 bits: 0..4095). Begin met de bytes 0..255; nieuwe woorden krijgen 256, 257, ...\n\n" +
			"[code]w = \"\"\nzolang niet EOF:\n  k = volgende teken\n  als wk in woordenboek: w = wk\n  anders:\n    output code(w)\n    voeg wk toe (volgende code)\n    w = k[/code]\n\n" +
			"[b]banaanaanval[/b]: 98 (ba = 256), 97 (an = 257), 110 (na = 258), 97 (aa = 259), 257 (ana = 260), 259 (aan = 261), ...\n\n" +
			"Woordenboek vol: opnieuw beginnen, doorgaan, of het langst niet gebruikte woord schrappen.\n\n" +
			"%slesnotas §4.4, p. 110–112[/color]" % REF, "schema_node": fig(_fig_lzw)},
		# 11
		{"title": "12 · LZW: decoderen en het speciale geval", "text":
			"Bouw hetzelfde woordenboek op. Na elke code voeg je [code][lb]w, volgend_woord[lb]0]][/code] toe.\n\n" +
			"[b]Probleem[/b]: soms is de code nog niet in het woordenboek, namelijk als (en slechts als) een woord [b]meteen[/b] nadat het toegevoegd werd als code geschreven wordt (bv. [code]aaaaaaaa[/code]: 97, 256, ...). Dan begint het nieuwe woord met hetzelfde teken als w:\n" +
			"[code]als c in woordenboek: volgend = woord(c)\nanders: volgend = [lb]w, w[lb]0]][/code]\n\n" +
			"Voorbeeld [code]97 110 256 258 115[/code]: a, n (256 = an), an (257 = na), dan 258 nog niet gekend: ana (258 = ana), s: [b]anananas[/b].\n\n" +
			"LZW codeert sneller dan LZ77: geen dure zoektocht naar de langste match (bv. tries).\n\n" +
			"%slesnotas p. 112–114[/color]" % REF},
		# 12
		{"title": "13 · Burrows-Wheeler transformatie", "text":
			"Nieuw idee: [b]transformeer[/b] de tekst zodat hij beter te comprimeren is (bzip2), omkeerbaar.\n\n" +
			"• Lees de tekst cyclisch en vorm alle n rotaties.\n• [b]Sorteer[/b] ze (een blank is kleiner dan de letters).\n• Output het nummer p van de rij die eindigt op s[lb]0], en de [b]laatste kolom[/b].\n\n" +
			"[b]geen loon[/b] wordt [code](1 ngen eool)[/code].\n\n" +
			"Alle rijen moeten verschillend zijn (anders: een herhaling, of voeg een nieuw teken toe). De laatste kolom bevat dezelfde letters, maar [b]beter gegroepeerd[/b]: het zijn de tekens die vóór de gesorteerde beginstukken komen.\n\n" +
			"%slesnotas §4.5, p. 115–117, 120[/color]" % REF, "schema_node": fig(_fig_bwt)},
		# 13
		{"title": "14 · BWT terug", "text":
			"Uit c (de laatste kolom) krijg je e door te [b]sorteren[/b]: de eerste kolom. Na c[lb]i] komt in de tekst e[lb]i].\n\n" +
			"Identieke letters koppel je [b]in volgorde[/b]: de k-de x in e is de k-de x in c (bewijs met rijen die allemaal verschillend zijn).\n\n" +
			"[code]begin met x = c[lb]p]; herhaal n keer:\n  output x\n  zoek i met c[lb]i] = x\n  x = e[lb]i][/code]\n\n" +
			"(1 ngen eool): g, e, e, n, _, l, o, o, n = [b]geen loon[/b]. Omdat de lus n keer loopt, werkt het ook voor herhalingen (Figuur 26).\n\n" +
			"%slesnotas p. 117–120[/color]" % REF, "schema_node": fig(_fig_bwt_back)},
		# 14
		{"title": "15 · Move-to-front", "text":
			"Een vaste lijst met alle tekens; c(x) = de positie van x (vanaf 0). Voor elk teken: [b]schrijf c(x)[/b] en zet x [b]vooraan[/b] in de lijst.\n\n" +
			"Lijst ( ,1,a,b,e,f,g,n,o,l), tekst (1 ngen eool):\n[code]1 1 7 7 6 2 3 2 8 0 9[/code]\n\n" +
			"[b]Decoderen[/b]: begin met dezelfde lijst, positie → teken, zet het vooraan.\n\n" +
			"De tekst wordt hierdoor niet korter. Maar na Burrows-Wheeler staan gelijke letters vaak bij elkaar, dus komen er [b]veel nullen en kleine getallen[/b]: ideaal om daarna (statisch) [b]Huffman[/b] te coderen.\n\n" +
			"%slesnotas p. 121–122[/color]" % REF, "schema_node": fig(_fig_mtf)},
	]


# ======================================================================
#  BBCode: tekens die Fredoka mist in [code] (JetBrains Mono)
# ======================================================================

const _OK_CHARS := "–—‘’“”…•"


static func _clean_pages(pages: Array) -> Array:
	for p in pages:
		if p.has("text"):
			p["text"] = safe(str(p.text))
		if p.has("title"):
			p["title"] = safe(str(p.title))
	return pages


## Zet tekens buiten Latin-1 (→, ≤, Σ, ′, ⌈ …) in [code] zodat ze met de mono-font getekend worden.
static func safe(s: String) -> String:
	var out := ""
	var in_code := false
	var run := ""
	var i := 0
	while i < s.length():
		if s.substr(i, 6) == "[code]":
			out += _flush(run)
			run = ""
			in_code = true
			out += "[code]"
			i += 6
			continue
		if s.substr(i, 7) == "[/code]":
			in_code = false
			out += "[/code]"
			i += 7
			continue
		var ch := s[i]
		if not in_code and ch.unicode_at(0) > 0xFF and not _OK_CHARS.contains(ch):
			run += ch
		else:
			out += _flush(run)
			run = ""
			out += ch
		i += 1
	return out + _flush(run)


static func _flush(run: String) -> String:
	return "" if run == "" else "[code]%s[/code]" % run


# ======================================================================
#  schema's (perkament + ScDraw/ScDrawTools), nominaal 520 × 520
# ======================================================================

class Fig extends Control:
	var painter: Callable
	var nominal := Vector2(520, 520)

	func _ready() -> void:
		ScDraw.prepare(self)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 8 or size.y < 8:
			return
		var k := minf(size.x / nominal.x, size.y / nominal.y)
		draw_set_transform((size - nominal * k) / 2.0, 0.0, Vector2(k, k))
		ScDraw.parchment(self, Rect2(Vector2(6, 6), nominal - Vector2(12, 16)), 11, ScPal.VELLUM, true, 0.5)
		painter.call(self)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func fig(painter: Callable, nominal := Vector2(520, 520)) -> Callable:
	return func() -> Control:
		var f := Fig.new()
		f.painter = painter
		f.nominal = nominal
		return f


static func _cap(ci: CanvasItem, y: float, s: String, size := 20) -> void:
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(260, y), s, size, ScPal.RUBRIC)


## Figuur 25: o = 00, u = 010, d = 011, f = 10, t = 11. `word` = gelezen woord (gouden paden), "" = enkel de boom.
static func _fig25(ci: CanvasItem, word: String) -> void:
	_cap(ci, 36, "Figuur 25")
	var P := {"r": Vector2(260, 80), "0": Vector2(160, 170), "1": Vector2(360, 170), "00": Vector2(100, 260),
		"01": Vector2(220, 260), "10": Vector2(310, 260), "11": Vector2(420, 260), "010": Vector2(170, 350),
		"011": Vector2(270, 350)}
	var leaves := {"00": "o", "010": "u", "011": "d", "10": "f", "11": "t"}
	var hi := {}
	if word != "":
		for code in ["00", "010", "011"]:
			for j in range(1, code.length() + 1):
				hi[code.substr(0, j)] = true
	for key in P.keys():
		if key == "r":
			continue
		var par: String = "r" if key.length() == 1 else key.substr(0, key.length() - 1)
		ScDrawTools.branch(ci, P[par], P[key], key[key.length() - 1], hi.has(key), 6.0)
	for key in P.keys():
		if leaves.has(key):
			ScDrawTools.leaf_tile(ci, P[key], leaves[key], 26, "oudft", hi.has(key), key)
		else:
			ScDrawTools.knob(ci, P[key], 13.0, hi.has(key) or key == "r")
	if word != "":
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 460), "00 | 010 | 011", 26, ScPal.INK)
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 494), "o    u     d", 26, ScPal.RUBRIC)
	else:
		ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 470), "links = 0 · rechts = 1", 22, ScPal.INK_SOFT)


## Huffman-boom van boosdoeer (p. 85): gewichten bij de toppen, codes onder de bladeren.
static func _fig_huff(ci: CanvasItem) -> void:
	_cap(ci, 36, "boosdoeer · Algoritme 9")
	var P := {"": Vector2(260, 80), "0": Vector2(160, 160), "1": Vector2(380, 160), "00": Vector2(95, 250),
		"01": Vector2(235, 250), "10": Vector2(330, 250), "11": Vector2(430, 250), "000": Vector2(60, 330),
		"001": Vector2(130, 330), "010": Vector2(200, 330), "011": Vector2(270, 330)}
	var leaves := {"000": ["b", 1], "001": ["s", 1], "010": ["d", 1], "011": ["r", 1], "10": ["o", 3], "11": ["e", 2]}
	var w := {"": 9, "0": 4, "1": 5, "00": 2, "01": 2}
	for key in P.keys():
		if key == "":
			continue
		ScDrawTools.branch(ci, P[key.substr(0, key.length() - 1)], P[key], key[key.length() - 1], false, 5.0)
	for key in P.keys():
		if leaves.has(key):
			var lf: Array = leaves[key]
			ScDrawTools.leaf_tile(ci, P[key], lf[0], 24, "bosder", false, key, 0.0, int(lf[1]))
		else:
			ScDrawTools.knob(ci, P[key], 17.0, key == "", str(w[key]))
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 470), "touw = 2+2+4+5+9 = 22 bits", 22, ScPal.INK)


## Adaptieve Huffman: de boosdoeer-boom met [gewicht,nummer] (p. 90).
static func _fig_fgk(ci: CanvasItem) -> void:
	_cap(ci, 36, "[gewicht,nummer] · p. 90")
	var P := {"": Vector2(260, 85), "0": Vector2(150, 175), "1": Vector2(380, 175), "00": Vector2(90, 270),
		"01": Vector2(215, 270), "10": Vector2(330, 270), "11": Vector2(430, 270), "000": Vector2(55, 370),
		"001": Vector2(125, 370), "010": Vector2(185, 370), "011": Vector2(255, 370)}
	var lab := {"": "9,11", "0": "4,9", "1": "5,10", "00": "2,5", "01": "2,6", "10": "2,7", "11": "3,8",
		"000": "1,1", "001": "1,2", "010": "1,3", "011": "1,4"}
	var let := {"10": "e", "11": "o", "000": "b", "001": "s", "010": "d", "011": "r"}
	for key in P.keys():
		if key != "":
			ScDrawTools.branch(ci, P[key.substr(0, key.length() - 1)], P[key], "", false, 5.0)
	for key in P.keys():
		var c: Vector2 = P[key]
		var r := Rect2(c - Vector2(34, 16), Vector2(68, 32))
		ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI, 6, 3, ScPal.VELLUM_EDGE), r)
		ScPal.text_c(ci, ScPal.MONO_B, c, "[%s]" % lab[key], 16, ScPal.INK)
		if let.has(key):
			ScPal.text_c(ci, ScPal.MONO, c + Vector2(0, 36), let[key], 26, ScPal.RUBRIC)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 470), "(b) gewicht stijgt met het nummer", 20, ScPal.INK_SOFT)


## Meetlat: [0,1) met x, y, z en het vak van y verder verdeeld (yy = [0.34, 0.83)).
static func _fig_ruler(ci: CanvasItem) -> void:
	_cap(ci, 36, "p(x) = 0.2 · p(y) = 0.7 · p(z) = 0.1")
	var segs := [{"sym": "x", "lo": 0.0, "hi": 0.2}, {"sym": "y", "lo": 0.2, "hi": 0.9}, {"sym": "z", "lo": 0.9, "hi": 1.0}]
	ScDrawTools.ruler(ci, Rect2(150, 80, 60, 360), segs, "y", -1.0, 0.0, ["0", "0.2", "0.9", "1"])
	var segs2 := [{"sym": "yx", "lo": 0.0, "hi": 0.2}, {"sym": "yy", "lo": 0.2, "hi": 0.9}, {"sym": "yz", "lo": 0.9, "hi": 1.0}]
	ScDrawTools.ruler(ci, Rect2(390, 80, 60, 360), segs2, "yy", (0.5 - 0.2) / 0.7, 0.0, ["0.2", "0.34", "0.83", "0.9"])
	ci.draw_line(Vector2(224, 80), Vector2(376, 80), Color(ScPal.INK_SOFT, 0.6), 2.0, true)
	ci.draw_line(Vector2(224, 440 - 360 * 0.2), Vector2(376, 440), Color(ScPal.INK_SOFT, 0.6), 2.0, true)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(420, 480), "0.5 = 1", 20, ScPal.INK)


## LZ77: banaan-baan, G = 6, laatste stap (1,3,EOF) en alle zegels.
static func _fig_lz77(ci: CanvasItem) -> void:
	_cap(ci, 36, "banaan-baan · G = 6")
	ScDrawTools.reading_window(ci, Vector2(40, 140), "banaan-baan", 2, 6, 40.0, 30, 1, true)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 210), "match aan op positie 1, lengte 3", 20, ScPal.INK_SOFT)
	var seals := [[0, 0, "b"], [0, 0, "a"], [0, 0, "n"], [1, 1, "a"], [2, 1, "-"], [0, 0, "b"], [1, 3, "EOF"]]
	for i in seals.size():
		var s: Array = seals[i]
		var c := Vector2(140 + (i % 3) * 120, 270 + (i / 3) * 62) if i < 6 else Vector2(260, 400)
		ScDraw.triple_seal(ci, c, int(s[0]), int(s[1]), str(s[2]), 18, i == 6)


## LZW: de stempelkast na het begin van banaanaanval.
static func _fig_lzw(ci: CanvasItem) -> void:
	_cap(ci, 36, "banaanaanval · LZW")
	ScDrawTools.cabinet(ci, Rect2(30, 60, 460, 330), [["b", 98], ["a", 97], ["n", 110], ["v", 118], ["l", 108]],
		[[256, "ba"], [257, "an"], [258, "na"], [259, "aa"], [260, "ana"], [261, "aan"]], -1, -1, 261)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 430), "98 97 110 97 257 259 ...", 22, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 470), "nieuwe woorden vanaf 256", 20, ScPal.INK_SOFT)


## BWT: de gesorteerde rotaties van "geen loon", rij p = 1 gemarkeerd.
static func _fig_bwt(ci: CanvasItem) -> void:
	_cap(ci, 36, "geen loon · gesorteerd")
	var rows := [" loongeen", "een loong", "en loonge", "geen loon", "loongeen ", "n loongee", "ngeen loo",
		"ongeen lo", "oongeen l"]
	ScDrawTools.rack(ci, Vector2(70, 80), rows, 24, 1)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 478), "(1 ngen eool)", 24, ScPal.RUBRIC)


## BWT terug: kolommen e (gesorteerd) en c (laatste kolom) met rangen; volgorde van de terugweg.
static func _fig_bwt_back(ci: CanvasItem) -> void:
	_cap(ci, 36, "p = 1 · c = ngen eool")
	var e := [" ", "e1", "e2", "g", "l", "n1", "n2", "o1", "o2"]
	var c := ["n1", "g", "e1", "n2", " ", "e2", "o1", "o2", "l"]
	var order := {1: 1, 2: 2, 5: 3, 0: 4, 4: 5, 8: 6, 7: 7, 6: 8, 3: 9}   # rij van c -> stap
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(110, 74), "i", 20, ScPal.INK_SOFT)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(220, 74), "c", 22, ScPal.RUBRIC)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(340, 74), "e", 22, ScPal.RUBRIC)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(440, 74), "stap", 18, ScPal.INK_SOFT)
	for i in 9:
		var y := 112 + i * 40
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(110, y), str(i), 20, ScPal.INK_SOFT)
		for col in 2:
			var s: String = c[i] if col == 0 else e[i]
			var x := 220 if col == 0 else 340
			var r := Rect2(x - 30, y - 16, 60, 32)
			ci.draw_style_box(ScPal.sb_thick(ScPal.VELLUM_HI if not (col == 0 and i == 1) else ScPal.GOLD_LIGHT, 5, 3, ScPal.VELLUM_EDGE), r)
			ScPal.text_c(ci, ScPal.MONO, Vector2(x - 5, y), ScPal.show(s[0]), 24, ScPal.INK)
			if s.length() > 1:
				ScPal.text_c(ci, ScPal.MONO_B, Vector2(x + 16, y + 7), s[1], 13, ScPal.INK_SOFT)
		ci.draw_line(Vector2(252, y), Vector2(306, y), Color(ScPal.RUBRIC, 0.7), 2.0, true)
		ScPal.text_c(ci, ScPal.MONO_B, Vector2(440, y), str(order.get(i, "")), 20, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 488), "na c[i] komt e[i] · geen loon", 20, ScPal.INK_SOFT)


## Move-to-front: de lijst van p. 121 voor en na het teken n (code 7).
static func _fig_mtf(ci: CanvasItem) -> void:
	_cap(ci, 36, "move-to-front · p. 121")
	var a := [" ", "1", "a", "b", "e", "f", "g", "n", "o", "l"]
	ScDrawTools.shelf(ci, Vector2(40, 130), a, 38.0, true, 7)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 250), "lees n: schrijf 7, n vooraan", 22, ScPal.RUBRIC)
	var b := ["n", " ", "1", "a", "b", "e", "f", "g", "o", "l"]
	ScDrawTools.shelf(ci, Vector2(40, 330), b, 38.0, true, 0)
	ScPal.text_c(ci, ScPal.MONO_B, Vector2(260, 460), "1 1 7 7 6 2 3 2 8 0 9", 24, ScPal.INK)


## Niet alles is comprimeerbaar: bestanden met n+1 bytes tegen bestanden met ten hoogste n bytes.
static func _fig_count(ci: CanvasItem) -> void:
	_cap(ci, 36, "p. 81 · tellen")
	var big := Rect2(60, 90, 400, 120)
	ci.draw_style_box(ScPal.sb_thick(ScPal.LAPIS_LIGHT.lerp(ScPal.VELLUM, 0.4), 8, 4, ScPal.VELLUM_EDGE), big)
	ScPal.text_c(ci, ScPal.MONO_B, big.get_center() + Vector2(0, -16), "256^(n+1)", 26, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_MED, big.get_center() + Vector2(0, 22), "bestanden met n+1 bytes", 20, ScPal.INK)
	var small := Rect2(60, 260, 400.0 / 255.0 * 12.0, 120)
	ci.draw_style_box(ScPal.sb_thick(ScPal.GOLD_LIGHT, 6, 4, ScPal.VELLUM_EDGE), small)
	ScPal.text_l(ci, ScPal.MONO_B, Vector2(100, 304), "≈ 256^(n+1) / 255", 24, ScPal.INK)
	ScPal.text_l(ci, ScPal.UI_MED, Vector2(100, 340), "bestanden met hoogstens n bytes", 20, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(260, 440), "hoogstens 1/255 kan korter", 22, ScPal.RUBRIC)


## Binderij: de stapels van boosdoeer (hoogte = gewicht).
static func _fig_piles(ci: CanvasItem) -> void:
	_cap(ci, 36, "boosdoeer · gewichten")
	var w := [["b", 1], ["o", 3], ["e", 2], ["s", 1], ["d", 1], ["r", 1]]
	for i in w.size():
		ScDrawTools.pile(ci, Vector2(70 + i * 76, 210), str(w[i][0]), int(w[i][1]), "boesdr", i == 0 or i == 3, 0.0,
			false, 64.0)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 270), "de twee lichtste: gewicht 1 en 1", 22, ScPal.INK)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(260, 304), "bundel = 2 · touw + 2", 20, ScPal.INK_SOFT)


## Duiventil: zeven kortere hokken en de zolder (4 bits).
static func _fig_dovecote(ci: CanvasItem) -> void:
	ScDrawTools.dovecote(ci, Vector2(260, 360), 1.0, {"0": true, "11": true, "01": true})


## De Voorlezing: gelijk (gouden stip) en anders gelezen (bruine inkt + inktvlek).
static func _fig_reading(ci: CanvasItem) -> void:
	_cap(ci, 36, "origineel boven · Letterlijk onder")
	ScDraw.reading(ci, Vector2(60, 150), "boosdoeer", "boosdoeer", 36)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(260, 240), "gelijk: verliesloos", 20, ScPal.OK.darkened(0.3))
	ScDraw.reading(ci, Vector2(60, 340), "boosdoeer", "bsodoerr", 36)
	ScPal.text_c(ci, ScPal.UI_BOLD, Vector2(260, 440), "anders gelezen: inktvlek", 20, ScPal.SEPIA)


## Nachtwake: de kaars en een rij stapels.
static func _fig_wake(ci: CanvasItem) -> void:
	_cap(ci, 36, "bind voor de kaars opbrandt")
	ScDraw.candle(ci, Vector2(90, 360), 1.2, 0.0, true, 0.6)
	var w := [["a", 4], ["k", 2], ["e", 5], ["n", 3]]
	for i in w.size():
		ScDrawTools.pile(ci, Vector2(210 + i * 84, 360), str(w[i][0]), int(w[i][1]), "aken", i == 1 or i == 3, 0.0,
			false, 66.0)
	ScPal.text_c(ci, ScPal.UI_MED, Vector2(300, 440), "lichtste paar: k (2) en n (3)", 22, ScPal.INK)
