class_name TtGuide
extends Object
## Inhoud van de gedeelde gids (HubGuide, design/SHARED_UX.md §2–3) voor Trietuin:
## Doel · Handelingen (per level, muis én toetsenbord) · Theorie (lesnotas §3.1–3.3, p. 25–50), plus korte
## tutorials (3–5 kaartjes) de eerste keer per mechaniek. "Gezien" staat in TtSave (setting `tutorials_seen`).
## Theorie strikt volgens de lesnotas; figuren in notas-stijl via TtNotesView, spelillustraties via TtDraw.

const SAVE_KEY := "tutorials_seen"
const DIMC := "[color=#A9C0AC]"

## Mechanieken per level (in volgorde); de eerste nog niet geziene opent automatisch bij de start van het level.
const LEVEL_TUTORIALS := {
	"1-1": ["trie"], "1-2": ["trie", "knippen"], "1-3": ["trie"], "1-4": ["trie", "zwerm"], "endless": ["trie", "zwerm"],
	"2-1": ["snoeien"], "2-2": ["snoeien", "wesp"], "2-3": ["enten"], "2-4": ["snoeien", "wesp"],
	"3-1": ["ternary"], "3-2": ["ternary"], "3-3": ["ternary"], "3-4": ["bedden"],
	"4-1": ["aanhechten"], "4-2": ["aanhechten", "be"], "4-3": ["inspecteur"], "4-4": ["inspecteur", "mist"],
	"4-5": ["inspecteur", "veralgemeend"], "5-1": ["ukkonen"], "5-2": ["ukkonen"], "5-3": ["ukkonen"],
}

const GOALS := {
	"1-1": "Bouw een gewone trie: volg bij elk zaadje de letters, hang vruchten aan lege knoppen en kies j als twee woorden botsen. Help ook de bijen (opzoeken).",
	"1-2": "Figuur 13 uit de notas staat al in de tuin. Voeg woorden toe (Figuur 14, Oefening 17), zoek op en verwijder TA_ met de snoeischaar.",
	"1-3": "Lange woorden met lange gemeenschappelijke prefixen. Kies j precies: te laat kiezen laat te veel toppen groeien (sap).",
	"1-4": "Zwermmodus: zaadjes en bijen komen op een klok. Help elke bij voor haar geduld op is.",
	"2-1": "Snoei de gewone trie van Figuur 15 tot een Patricia trie en zoek daarna op met Algoritme 1 (tel de skip).",
	"2-2": "Zoek op in een Patricia trie. Sommige bijen zijn wespen: pas in de vrucht zie je het verschil.",
	"2-3": "Voeg woorden toe aan een Patricia trie (enten) en zoek op.",
	"2-4": "Oefening 19a: snoei Figuur 17 tot een Patricia trie en zoek op. Geen hints.",
	"3-1": "Zet de trie van Figuur 16 om naar een ternary trie (rankknopen) en laat de bijen zoeken.",
	"3-2": "Voeg woorden toe aan een ternary trie met een groot alfabet (a tot z).",
	"3-3": "Oefening 19b: zet Figuur 17 om naar een ternary trie.",
	"3-4": "Oefening 20: kies per tuinbed een gewone trie (array van pointers) of een ternary trie. Het sap beslist.",
	"4-1": "Bouw de suffixboom van acacacgt_ (Figuur 18): hang elk suffix op de juiste plaats.",
	"4-2": "Bouw dezelfde boom met (b,e)-labels (Figuur 19): kies na het aanhechten de beginparel b.",
	"4-3": "Beantwoord de vragen van inspecteur Egel met de suffixboom: komt z voor, waar, hoe vaak, alle posities?",
	"4-4": "Dezelfde soort vragen, maar de slinger zit in de mist: lees de bordjes en reken b − l_t.",
	"4-5": "Een veralgemeende suffixboom van drie verdachten: van wie is het spoor?",
	"5-1": "Ukkonen op abacabc_ (notas p. 44–48): voer de extensies zelf uit. De Uil doet iteraties 1–4 voor.",
	"5-2": "Oefening 27: Ukkonen op aabbabc_, zonder voordoen.",
	"5-3": "Figuur 18 herboren: bouw de suffixboom van acacacgt_ met Ukkonen.",
	"endless": "Vrije tuin: plant en bedien zo lang je kunt. Drie missers en de tuin sluit.",
}

## Figuren uit de notas (notatie van de core).
const F14 := "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
const WASP_TREE := "{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}"


static func style(tutorial := false) -> Dictionary:
	var s := {
		"panel": TtPal.PANEL, "accent": TtPal.BRAND, "accent_text": TtPal.INK, "tab": TtPal.PANEL_HI,
		"text": TtPal.TEXT, "text_dim": TtPal.TEXT_DIM, "border": TtPal.BRAND_DARK,
		"font": TtPal.UI, "font_bold": TtPal.UI_BOLD, "layer": 40,
	}
	if tutorial:
		s["size"] = Vector2(1260, 640)
		s["font_size"] = 26
	return s


# ======================================================================
#  tutorials
# ======================================================================

static func seen(key: String) -> bool:
	var d = TtSave.setting(SAVE_KEY, {})
	return d is Dictionary and bool((d as Dictionary).get(key, false))


static func mark_seen(key: String) -> void:
	var d = TtSave.setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	d[key] = true
	TtSave.set_setting(SAVE_KEY, d)


## Eerste nog niet geziene tutorial voor dit level, anders "". `force`: de eerste van het level, gezien of niet.
static func pending_tutorial(level_id: String, force := false) -> String:
	for k in LEVEL_TUTORIALS.get(level_id, []):
		if force or not seen(k):
			return k
	return ""


static func tutorial_keys() -> Array:
	return ["trie", "knippen", "zwerm", "snoeien", "wesp", "enten", "ternary", "bedden", "aanhechten", "be",
		"inspecteur", "mist", "veralgemeend", "ukkonen"]


static func tutorial(key: String) -> Dictionary:
	var title := ""
	var pages: Array = []
	match key:
		"trie":
			title = "Welkom in de trietuin"
			pages = [
				{"title": "Wat zie je?", "text": "De boom groeit uit de [b]kiem[/b]: de wortel, die de lege string voorstelt.\n\nElke tak eindigt in een [b]knoppenkrans[/b]: één knop per letter, in de volgorde [code]A C G T _[/code]. Een groen knopje heeft een kind; een grijs, dicht knopje is een [b]lege pointer (NULL)[/b].\n\nEen [b]vrucht[/b] is een blad met het hele woord als label.", "schema": _ill_knot},
				{"title": "Het doel", "text": "Bovenaan in de [b]windrij[/b] komen de kaarten: een [b]zaadje[/b] = woord toevoegen, een [b]bij[/b] = woord opzoeken.\n\nZet elk woord waar Definitie 1 het wil, met zo weinig mogelijk [b]sap[/b] (geheugen: elke knop kost sap, ook een lege). 's Avonds test de [b]Bloei[/b] je boom: elke bij vliegt het echte algoritme."},
				{"title": "Wat kun je doen?", "text": "• [b]Letter volgen[/b]: typ de letter die op het lint oplicht, of klik die knop op de krans.\n• Een [b]lege knop[/b]? Dan hangt de vrucht er meteen.\n• Kom je bij een [b]vrucht[/b]: klik op het vergelijkingslint de kolom [b]j[/b] van het eerste verschil (of [code]←[/code]/[code]→[/code] en Enter). Zelfde woord? [b]Zit er al[/b] (Z).\n• Een bij bij een vrucht: [b]Pluk[/b] (Enter) of [b]Niet hier[/b] (N)."},
				{"title": "Mini-voorbeeld", "text": "AAGCGA_ landt op diepte 2 bij de vrucht AAGTT_. Het eerste verschil staat op positie 3 (T tegenover C): [b]j = 3[/b]. Het spel laat de top AAG groeien en hangt beide vruchten aan T en C (Figuur 14).\n\n[b]F1[/b] of de [b]?[/b]-knop opent deze uitleg opnieuw, met de theorie uit de notas. [b]F2[/b] of een klik op de Uil geeft een hint.", "schema": _ill_compare.bind("AAGTT_", "AAGCGA_", 2, 3)},
			]
		"knippen":
			title = "Nieuw: de snoeischaar"
			pages = [
				{"title": "Een woord verwijderen", "text": "Een kaart met een [b]schaar[/b] vraagt een woord te verwijderen. Volg eerst de letters tot bij zijn vrucht, net zoals bij opzoeken."},
				{"title": "Waar knip je?", "text": "Verwijder alle toppen op het pad [b]na de laatste top die ten minste twee niet-lege kinderen heeft[/b] (notas p. 27).\n\nKlik die tak, of kies hem met [code]↑[/code]/[code]↓[/code] en knip met [b]S[/b].", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.TRIE, F14, "dna", "Figuur 14")},
				{"title": "Te hoog of te laag?", "text": "Knip je [b]te hoog[/b], dan vallen ook andere vruchten op de grond: die woorden ben je kwijt.\n\nKnip je [b]te laag[/b], dan blijft er dood hout over: kale toppen zonder vruchten die sap blijven drinken."},
			]
		"zwerm":
			title = "Nieuw: de zwerm"
			pages = [
				{"title": "Realtime", "text": "Nu komen de kaarten [b]op een klok[/b]. In de windrij heeft elke wachtende bij een [b]geduldbalkje[/b]: is het leeg, dan vliegt ze weg (gemist).\n\nIn de vrije tuin groeit je sap langzaam bij, en na [b]drie missers[/b] sluit de tuin."},
				{"title": "Wat kun je doen?", "text": "Hetzelfde als altijd: letters typen of knoppen klikken, j kiezen, Pluk of Niet hier. De voorste kaart in de windrij is aan de beurt.\n\nGeen hints in de zwerm. Snel en foutloos achter elkaar geeft een [b]combo[/b]: meer honing."},
				{"title": "Tip", "text": "Typen is sneller dan klikken: elke letter van het woord is één toets. Je volgt het algoritme letterlijk met je vingers: op diepte d druk je letter s[font_size=17]d[/font_size]."},
			]
		"snoeien":
			title = "Nieuw: Patricia"
			pages = [
				{"title": "Takken zonder vertakking", "text": "Lange paden waar niets vertakt, verspillen sap. In een [b]Patricia trie[/b] heeft elke interne top een getal [b]skip[/b]: hoeveel letters je daar overslaat. Het jaarring-plaatje op een top toont skip.", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.PATRICIA, TtLevels.F15P, "dna", "Figuur 15: als Patricia trie")},
				{"title": "Snoeien", "text": "Een snoeikaart vraagt je de gewone boom te snoeien. Klik een [b]top met maar één kind[/b] (de schaar verschijnt als je erover beweegt), of doorloop de toppen met [b]Tab[/b] en knip met [b]S[/b].\n\nHet kind schuift op naar de ouder. Is het kind zelf een top, dan wordt zijn skip: skip van het kind + skip van de geknipte top + 1. Geen top met één kind meer? [b]Klaar[/b] (Enter).", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.TRIE, TtLevels.F15, "dna", "Figuur 15: de gewone trie")},
				{"title": "Opzoeken met skip", "text": "Algoritme 1: op een top met skip k sla je k letters over en lees je de volgende: [code]next = next + skip + 1[/code], dan letter s[lb]next − 1].\n\nOp het [b]hoplint[/b]: klik de letter die je leest, of schuif met [code]←[/code]/[code]→[/code] en druk Enter. Is het woord te kort ([code]next + skip > m[/code])? Kies [b]te kort[/b] (T)."},
			]
		"wesp":
			title = "Pas op: wespen"
			pages = [
				{"title": "Een bij... of een wesp?", "text": "Patricia kijkt [b]niet[/b] naar de letters die het overslaat. Zit AAAAABAAAAABC_ in de boom en wordt er enkel bij de B's vertakt, dan komt een zoektocht naar BBBBBBBBBBBBB_ toch tot in dat blad (notas p. 29).", "schema": _ill_bee.bind(1.0)},
				{"title": "In de vrucht beslis je", "text": "Pas in de vrucht vergelijk je [b]het hele woord[/b]. Exact gelijk? [b]Pluk[/b] (Enter of J). Anders: [b]Niet hier[/b] (N).\n\nLaat je een wesp plukken, dan steelt ze de vrucht en is het woord weg.", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.PATRICIA, WASP_TREE, "abc", "enkel vertakt bij de B's")},
				{"title": "Te kort", "text": "Is [code]next + skip > m[/code], dan is het gezochte woord korter dan alle woorden die je vanaf hier kan bereiken: [b]te kort[/b] (T), niet gevonden."},
			]
		"enten":
			title = "Nieuw: enten"
			pages = [
				{"title": "Toevoegen in Patricia", "text": "Tijdens het afdalen weet je niet welke letters je oversloeg. Daal af met Algoritme 1 tot je een [b]lege knop[/b], [b]te kort[/b] of een [b]vrucht[/b] tegenkomt."},
				{"title": "Een vrucht lezen", "text": "Kies dan een [b]vrucht onder de huidige top[/b]: die glanzen (klik er een, of Tab en Enter). Elke vrucht daar heeft dezelfde overgeslagen letters, dus je kan ermee [b]reconstrueren[/b] (notas p. 29).", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.PATRICIA, TtLevels.F15P, "dna", "Figuur 15 (Patricia)")},
				{"title": "j kiezen en enten", "text": "Vergelijk het woord met die vrucht en klik de kolom [b]j[/b] van het eerste verschil. De ent gebeurt dan vanzelf op diepte j en de skips worden herrekend.", "schema": _ill_compare.bind("CGCGAA_", "CGTA_", 0, 2)},
			]
		"ternary":
			title = "Nieuw: rankknopen"
			pages = [
				{"title": "Een top als zoekboompje", "text": "In een [b]ternary trie[/b] wordt elke top een klein zoekboompje van [b]letterbollen[/b]. Elke bol heeft drie ranken: [color=#7DB8F0]kleiner[/color] (links), [color=#7BC96F]gelijk[/color] (midden: naar het kind, de volgende letter) en [color=#F5A35C]groter[/color] (rechts).\n\nEnkel letters die echt gebruikt worden krijgen een bol.", "schema": _ill_rank},
				{"title": "Volgen", "text": "Vergelijk je letter met de bol:\n• kleiner: [code]←[/code] of klik de linkerrank\n• gelijk: [code]↑[/code] of Enter, of klik de middenrank\n• groter: [code]→[/code] of klik de rechterrank\nEindigt de zoektocht bij een lege rank, dan groeit daar een nieuwe bol."},
				{"title": "Omzetten", "text": "Een omzetkaart vraagt een gewone top om te zetten. [b]Typ[/b] of [b]klik[/b] de letters in de volgorde waarin je ze plant; hun plaats volgt uit de regel kleiner/groter.\n\nDe volgorde bepaalt hoe lang de bijen vliegen (aantal vergelijkingen). Afspraak van dit spel: [code]_[/code] staat achteraan; bij een nieuwe vertakking eerst l[font_size=17]j[/font_size], dan s[font_size=17]j[/font_size]."},
			]
		"bedden":
			title = "Oefening 20: twee tuinbedden"
			pages = [
				{"title": "De vraag", "text": "Alfabet A = {a, c, g, t, _} en interne toppen met gemiddeld maar 2 kinderen: kies je een [b]array van pointers[/b] of een [b]ternary trie[/b]? (notas p. 32)", "schema": _ill_null},
				{"title": "Wat kun je doen?", "text": "Per tuinbed klik je [b]array[/b] of [b]rank[/b]. Daarna groeit het bed vanzelf met die boomsoort.\n\nTel het sap: een gewone top kost |A| pointers, een rankknoop 3 per bol."},
				{"title": "Waarom?", "text": "Leg na afloop zelf uit waarom jouw keuze goed is, zoals de oefening vraagt. Het tweede bed heeft een groter alfabet: vergelijk."},
			]
		"aanhechten":
			title = "Nieuw: de slinger"
			pages = [
				{"title": "Wat zie je?", "text": "De [b]slinger[/b] is de tekst: één parel per teken, met het positienummer eronder. De laatste parel is het unieke afsluitteken [code]_[/code].\n\nDe suffixen komen één voor één aan, het langste eerst.", "schema": _ill_garland.bind("acacacgt_", -1, -1)},
				{"title": "Aanhechten", "text": "Klik het [b]afwijkpunt[/b]: de diepste plaats tot waar het suffix al in de boom zit. Dat is een [b]top[/b] (er komt een nieuwe tak bij) of een punt [b]midden in een boog[/b] (de boog wordt gesplitst).\n\nAlles met de muis: beweeg over de boom, de mogelijke punten lichten op."},
				{"title": "De regel", "text": "Er is nooit een top met maar één kind, en twee bogen uit dezelfde top beginnen nooit met dezelfde letter. Wie te ondiep of op een ander pad aanhecht, maakt een tak die iets anders spelt dan de vrucht."},
			]
		"be":
			title = "Nieuw: wijzers (b,e)"
			pages = [
				{"title": "Strings drinken sap", "text": "Alle strings aan de bogen opslaan kost Θ(n²) geheugen. Maar elke string staat al in de tekst: bewaar enkel een [b]begin- en eindpositie (b,e)[/b]. Dat kost constant geheugen per boog: samen Θ(n) (notas p. 33).", "schema": _ill_garland.bind("acacacgt_", 2, 3)},
				{"title": "Wat kun je doen?", "text": "Na het aanhechten klik je op de slinger de [b]beginparel b[/b] van de nieuwe bladboog; e (de laatste positie) volgt vanzelf.\n\nRegel: een nieuwe bladboog vanuit een punt op diepte l, voor het suffix dat op j begint, krijgt [b]b = j + l[/b].\n\nBeweeg over een bordje: de parels b..e lichten op."},
				{"title": "Mini-voorbeeld", "text": "Suffix j = 2 ([code]acacgt_[/code]) wijkt af van acacacgt_ na [code]acac[/code]: op diepte l = 4. De nieuwe bladboog krijgt b = 2 + 4 = [b]6[/b], dus [b](6,8)[/b] = [code]gt_[/code].", "schema": _ill_garland.bind("acacacgt_", 6, 8)},
			]
		"inspecteur":
			title = "Nieuw: inspecteur Egel"
			pages = [
				{"title": "Vragen over z", "text": "De inspecteur noemt een zoekstring [b]z[/b] en vraagt: komt z voor? waar? hoe vaak? alle posities?\n\nGebruik de boom, niet de slinger: vanuit de wortel de tekens van z volgen kost O(m).", "schema": _ill_inspector},
				{"title": "De loep zetten", "text": "Klik de plaats in de boom waar z [b]eindigt[/b] (een top of een punt in een boog). Kom je niet verder? Druk [b]Komt niet voor[/b] (X).", "schema_width": 560, "schema_node": fig_node(TtCodes.Kind.SUFFIX, TtLevels.F19U, "dna_lower", "de boom van acacacgt_", "acacacgt_")},
				{"title": "Antwoorden", "text": "• [b]Waar?[/b] Klik een parel op de slinger waar z begint: [b]b − l[font_size=17]t[/font_size][/b] (b van de boog, l[font_size=17]t[/font_size] = lengte van de string van de top erboven).\n• [b]Hoe vaak?[/b] Typ het aantal (cijfers en Enter): het aantal vruchten onder dat punt.\n• [b]Alle posities[/b]: klik alle vruchten onder het punt aan, dan [b]Klaar[/b] (Enter)."},
			]
		"mist":
			title = "Nieuw: mist"
			pages = [
				{"title": "De slinger is weg", "text": "De tekst zit in de mist: je ziet de parels enkel als je over een [b](b,e)-bordje[/b] beweegt."},
				{"title": "Reken", "text": "Een positie van z is [b]b − l[font_size=17]t[/font_size][/b]: b is het beginlabel van de boog waarin het laatste teken van z zit, l[font_size=17]t[/font_size] de lengte van de string van de top waar die boog vertrekt (notas p. 48). De toppen tonen hun diepte.\n\nDe inspecteur heeft beperkt geduld."},
				{"title": "Mini-voorbeeld", "text": "In de boom van acacacgt_: z = [code]cac[/code]. Volg de boog [code](1,1)[/code] = c naar de top c (l[font_size=17]t[/font_size] = 1), dan de boog [code](2,3)[/code] = ac: daar zit het laatste teken van z. Positie = b − l[font_size=17]t[/font_size] = 2 − 1 = [b]1[/b].", "schema": _ill_garland.bind("acacacgt_", 1, 3)},
			]
		"veralgemeend":
			title = "Nieuw: drie verdachten"
			pages = [
				{"title": "Eén boom, drie teksten", "text": "Drie teksten (het DNA van drie verdachten), elk met een eigen afsluitteken, staan aan elkaar op de slinger. De boom bevat de suffixen van alle drie: een [b]veralgemeende suffixboom[/b] (notas p. 49). Elke vrucht heeft de kleur van haar eigenaar."},
				{"title": "Van wie?", "text": "Zet de loep op het einde van z, kijk welke kleuren de vruchten eronder hebben en klik de [b]portret(ten)[/b] van de eigenaar(s). Dan [b]Klaar[/b] (Enter)."},
				{"title": "Waarom mag dat?", "text": "Dit is de [b]onechte[/b] veralgemeende suffixboom: de teksten achter elkaar. Er zitten ook suffixen in met een afsluitteken in het midden, maar je zoekt nooit naar een string met een afsluitteken, dus dat geeft geen foute antwoorden (notas p. 49)."},
			]
		"ukkonen":
			title = "Nieuw: Ukkonen"
			pages = [
				{"title": "Eén parel per iteratie", "text": "De slinger krijgt per iteratie één nieuwe parel en de boom bevat telkens alle deelstrings tot nu toe.\n\n[b]Bladeren groeien vanzelf[/b] mee (hun eindlabel is [b]it[/b]): eens blad, altijd blad. Jij doet de andere extensies.", "schema": _ill_firefly},
				{"title": "Het vuurvliegje", "text": "Het vuurvliegje is de wijzer [b](p̄, x̄)[/b]: het zit op top p̄ met x̄ tekens verder langs de boog.\n\nIs x̄ ≥ de booglengte? Eerst [b]Spring[/b] (H, of klik de top). Dan kies je de regel: [b]Zit er al[/b] (Z) stopt de iteratie, [b]Groei![/b] (G) maakt een nieuw blad (ii) of splitst de boog (iii)."},
				{"title": "Links en de volgende extensie", "text": "Een nieuwe interne top vraagt om een [b]suffix link[/b]: klik de top die dezelfde string zonder eerste letter voorstelt.\n\nDaarna: [b]Volg link[/b] (V), of [b]x − 1[/b] (W) als p de wortel is.\n\nFouten worden niet uitgevoerd: het vuurvliegje toont waarom het niet kan."},
			]
	return {"title": title, "pages": _fix_pages(pages), "tutorial": true}


# ======================================================================
#  volledige gids (Doel · Handelingen · Theorie)
# ======================================================================

## spec = TtLevelSpec van het huidige level (of null buiten een level: dan algemene inhoud).
static func content(spec = null, level_id := "", start_tab := "doel") -> Dictionary:
	return {
		"title": "Trietuin · hoe speel je?",
		"tabs": {"doel": _fix_pages(goal_pages(spec, level_id)), "handelingen": _fix_pages(action_pages(spec, level_id)),
			"theorie": _fix_pages(theory_pages())},
		"tab": start_tab,
	}


static func goal_pages(spec, level_id: String) -> Array:
	var out: Array = []
	if spec != null:
		var head: String = ("%s %s · %s" % [TtSession.season_name(TtSession.season_of(level_id)), level_id, spec.title]) \
			if level_id != "endless" else "Vrije tuin · " + spec.title
		var t := ""
		if spec.intro != "":
			t += "[i]%s[/i]\n\n" % spec.intro
		t += str(GOALS.get(level_id, "")) + "\n"
		if not spec.stars.is_empty():
			t += "\n[b]Sterren[/b]\n"
			for i in mini(3, spec.stars.size()):
				t += "%d. %s\n" % [i + 1, TtScoring.star_label(spec.stars[i])]
		if spec.notes_ref != "":
			t += "\n%s%s[/color]" % [DIMC, spec.notes_ref]
		out.append({"title": head, "text": t})
	out.append({"title": "De tuin is een trie", "text":
		"• [b]Kiem[/b] = de wortel (lege string).\n" +
		"• [b]Knoppenkrans[/b] = interne top met een kind k[font_size=17]a[/font_size] per letter; [b]grijs knopje[/b] = NULL.\n" +
		"• [b]Vrucht[/b] = blad met het woord als label.\n" +
		"• [b]Zaadje[/b] = toevoegen, [b]bij[/b] = opzoeken, [b]schaar[/b] = verwijderen, [b]wesp[/b] = opzoeken van een woord dat er niet in zit.\n" +
		"• [b]Jaarring[/b] = skip (Patricia), [b]rankknoop[/b] = ternary top, [b]slinger[/b] = tekst van een suffixboom, [b](b,e)-bord[/b] = boog als pointers, [b]vuurvliegje[/b] = Ukkonen-wijzer (p̄, x̄).\n" +
		"• [b]Sap[/b] = geheugen (pointers), [b]honing[/b] = score.\n" +
		"• [b]Bloei[/b]: na het level vliegen bijen het echte algoritme over jouw boom. Onvindbare vruchten worden grijs."})
	out.append_array(path_pages(spec, level_id))
	return out


# ======================================================================
#  leerpad (design/LEARNING_PATH.md): per deel herbekijken / opnieuw oefenen
# ======================================================================

const LEVEL_TXT := ["nog niet gezien", "demo bekeken", "samen geoefend", "begrepen"]


## Index van de eerste leerpadpagina in de Doel-tab (voor "Leerpad" op de kaart).
static func path_page_index(spec) -> int:
	return (1 if spec != null else 0) + 1


static func path_pages(_spec = null, level_id := "") -> Array:
	var out: Array = []
	var ps := TtLessons.all_parts()
	var nr := 1
	for P in ps:
		var lv := TtLessons.level(P.id)
		var t := "[b]Regel:[/b] %s\n\n" % P.rule
		t += "• [b]Kijk[/b]: de Uil doet het stap voor stap voor (wat + waarom + toestand).\n"
		t += "• [b]Samen[/b]: jij doet het, met tips, hint en uitleg bij een fout.\n"
		t += "• [b]Zelf[/b]: level %s.   • [b]Check[/b]: vragen in de terugblik.\n\n" % ", ".join(P.levels)
		t += "Status: [b]%s[/b]" % LEVEL_TXT[lv]
		if (P.levels as Array).has(level_id):
			t += "  [color=#FFD23F](hoort bij dit level)[/color]"
		t += "\n%slesnotas %s[/color]" % [DIMC, P.page]
		out.append({"title": "Leerpad · deel %d van %d: %s" % [nr, ps.size(), P.title], "text": t,
			"schema_width": 400, "schema_node": _path_buttons.bind(str(P.id))})
		nr += 1
	return out


static func _path_buttons(id: String) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	var a := TtUi.button("Bekijk de demo opnieuw", TtUi.Kind.SAP, 24, 370)
	a.pressed.connect(func(): _play_path(id, "kijk"))
	box.add_child(a)
	var b := TtUi.button("Oefen dit opnieuw", TtUi.Kind.PRIMARY, 24, 370)
	b.pressed.connect(func(): _play_path(id, "samen"))
	box.add_child(b)
	return box


static func _play_path(id: String, phase: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var cur := tree.current_scene if tree else null
	var in_level: bool = cur != null and cur.scene_file_path == TtSession.SCENE_GARDEN and cur.get("coach") == null \
		and str(cur.get("level_id")) != ""
	if tree:
		tree.paused = false
	TtSession.play_lesson(id, phase, in_level)


static func _k(keys: String) -> String:
	return "[color=#FFD23F]%s[/color]" % keys


static func action_pages(spec, level_id: String) -> Array:
	var lines: Array = []
	var any: bool = spec == null
	var kind: int = spec.kind if spec != null else -1
	var ck := {}
	if spec != null:
		for c in spec.cards:
			ck[str(c.get("kind", ""))] = true
			if bool(c.get("wasp", false)):
				ck["wasp"] = true
		if level_id == "endless":
			ck["seed"] = true
			ck["bee"] = true
			ck["prune"] = true
	var trie_like: bool = any or kind == TtCodes.Kind.TRIE or kind == TtCodes.Kind.PATRICIA or kind == TtCodes.Kind.TERNARY
	if any or (kind == TtCodes.Kind.TRIE and not ck.has("beds")):
		lines.append("[b]Letter volgen[/b] (zaadje, bij): klik de knop op de krans · typ de letter (%s = spatie of -)" % _k("_"))
		lines.append("[b]Vrucht hangen[/b] aan een lege knop: klik de knop · typ de letter")
	if any or kind == TtCodes.Kind.PATRICIA:
		lines.append("[b]Patricia, leespositie[/b]: klik de letter op het hoplint · %s schuift, %s leest, %s = te kort" % [_k("← →"), _k("Enter"), _k("T")])
		if any or ck.has("seed"):
			lines.append("[b]Vrucht kiezen[/b] om te reconstrueren (enten): klik een glanzende vrucht · %s, dan %s" % [_k("Tab"), _k("Enter")])
		if any or ck.has("patricify"):
			lines.append("[b]Snoeien[/b]: klik een top met één kind · %s doorloopt, %s knipt; klaar: knop Klaar · %s" % [_k("Tab"), _k("S"), _k("Enter")])
	if any or kind == TtCodes.Kind.TERNARY:
		lines.append("[b]Rankknoop[/b] kleiner / gelijk / groter: klik de rank links / midden / rechts · %s / %s of %s / %s" % [_k("←"), _k("↑"), _k("Enter"), _k("→")])
		if any or ck.has("ternarify"):
			lines.append("[b]Omzetten[/b]: klik de letterchips in plantvolgorde · typ de letters")
	if trie_like and (any or ck.has("seed")):
		lines.append("[b]j kiezen[/b] op het vergelijkingslint: klik de kolom · %s en %s; zelfde woord: Zit er al · %s" % [_k("← →"), _k("Enter"), _k("Z")])
	if trie_like and (any or ck.has("bee")):
		lines.append("[b]Bij aan een vrucht[/b]: knop Pluk / Niet hier · %s of %s / %s of %s" % [_k("Enter"), _k("J"), _k("N"), _k("Backspace")])
	if any or ck.has("prune"):
		lines.append("[b]Verwijderen (schaar)[/b]: klik de tak waar je knipt · %s kiest een tak op het pad, %s knipt" % [_k("↑ ↓"), _k("S")])
	if any or ck.has("beds"):
		lines.append("[b]Tuinbedden[/b] (Oef. 20): klik per bed array of rank")
	if any or ck.has("suffix"):
		lines.append("[b]Suffix aanhechten[/b]: klik het afwijkpunt (een top of een punt in een boog)")
		if any or (spec != null and spec.labels == "pointers"):
			lines.append("[b]Beginparel b[/b] (bladboog (b,e)): klik de parel op de slinger")
	if any or ck.has("ask"):
		lines.append("[b]Loep zetten[/b]: klik waar z eindigt · Komt niet voor: knop · %s" % _k("X"))
		lines.append("[b]Waar?[/b] klik een parel · [b]Hoe vaak?[/b] cijferpaneel · cijfers en %s · [b]Alle / van wie?[/b] klik vruchten of portretten, dan Klaar · %s" % [_k("Enter"), _k("Enter")])
	if any or kind == TtCodes.Kind.SUFFIX or kind == TtCodes.Kind.UKKONEN:
		lines.append("[b](b,e)-bord[/b]: beweeg erover, de parels b..e lichten op")
	if any or kind == TtCodes.Kind.UKKONEN:
		lines.append("[b]Ukkonen[/b]: Spring (klik de top) · %s; Zit er al · %s; Groei! · %s; suffix link: klik de doeltop; Volg link · %s; x − 1 · %s" % [_k("H"), _k("Z"), _k("G"), _k("V"), _k("W")])
	var t := ""
	for l in lines:
		t += "• " + l + "\n"
	var t2 := "• [b]Pauze[/b]: knop linksboven · %s (opnieuw, notas, instellingen, levelkeuze, speelhal)\n" % _k("Esc") + \
		"• [b]Deze gids[/b]: knop [b]?[/b] linksboven · %s\n" % _k("F1") + \
		"• [b]Hint van de Uil[/b] (kost de derde ster): klik de Uil · %s\n" % _k("F2") + \
		"• [b]Terugspoelen[/b] (laatste kaart, kost de derde ster): knop met de pijl terug · %s\n" % _k("Ctrl+Z") + \
		"• [b]Camera[/b]: scrollen = zoomen, rechtermuisknop slepen = pannen · %s / %s, %s = passend\n" % [_k("+"), _k("−"), _k("0")] + \
		"• [b]Speelhal[/b]: het huisje · %s" % _k("Ctrl+H")
	var head := "Wat kun je nu doen?" if spec != null else "Alle handelingen"
	return [{"title": head, "text": "[font_size=21]muis · toetsenbord[/font_size]\n" + t}, {"title": "Altijd", "text": t2}]


# ======================================================================
#  theorie (lesnotas §3.1–3.3, p. 25–50; paginanummers = gedrukte nummers)
# ======================================================================

static func _ref(s: String) -> String:
	return "\n\n%slesnotas %s[/color]" % [DIMC, s]


static func _sub(s: String) -> String:
	return "[font_size=17]%s[/font_size]" % s


## Dubbel subscript zoals k_{s_d}.
static func _ss(a: String, b: String) -> String:
	return "[font_size=17]%s[font_size=13]%s[/font_size][/font_size]" % [a, b]


static func theory_pages() -> Array:
	var kd := "k" + _ss("s", "d")
	return [
		{"title": "1 · Tries: waarom?", "text":
			"Strings in een gebalanceerde zoekboom met n sleutels: opzoeken kost O(log n) vergelijkingen, maar elke vergelijking kost tot m = |s| tekens. Samen [b]O(m log n)[/b].\n\n" +
			"Een [b]trie[/b] (van re[i]trie[/i]val; ook [i]prefix tree[/i]) combineert vergelijken en opzoeken: de [b]vertakking[/b] in de boom hangt af van de [b]lettertekens[/b] van de string.\n\n" +
			"We veronderstellen dat geen opgeslagen string een prefix van een andere is. Dat dwing je af met een extra [b]afsluitteken[/b] [code]_[/code], zoals het NULL-teken in C." +
			_ref("§3.1, p. 25–26"),
			"schema": _ill_knot},
		{"title": "2 · Definitie 1: gewone trie", "text":
			"Gegeven een eindig alfabet A. Een (gewone) trie is een wortelboom waar [b]elke interne top voor elke letter a ∈ A een kind k%s[/b] heeft, dat ook [b]leeg[/b] kan zijn, en elk blad een string s ∈ A* als [b]label[/b] heeft.\n" % _sub("a") +
			"• De wortel stelt de lege string ∅ voor.\n" +
			"• Stelt een top s voor en is k%s niet leeg, dan stelt k%s de string s,a voor.\n" % [_sub("a"), _sub("a")] +
			"• Heeft een blad label s en stelt het s′ voor, dan is s′ een prefix van s.\n" +
			"De labels van de bladeren zijn de opgeslagen strings." +
			_ref("§3.1, Definitie 1, p. 26 · Figuur 13"),
			"schema_width": 600, "schema_node": fig_node(TtCodes.Kind.TRIE, TtLevels.F13, "dna", "Figuur 13")},
		{"title": "3 · Opzoeken en toevoegen", "text":
			"[b]Opzoeken[/b] van s = s%s, …, s%s: begin in de wortel (diepte d = 0) en ga op diepte d naar kind %s, tot\n" % [_sub("0"), _sub("k"), kd] +
			"• het kind NULL is: niet gevonden, of\n• je een blad bereikt: vergelijk s met het label van het blad.\n\n" +
			"[b]Toevoegen[/b]: begin zoals opzoeken (gevonden: niets doen).\n" +
			"• %s is NULL: voeg daar een blad met label s toe.\n" % kd +
			"• Blad b op diepte d met label l ≠ s: kies [b]j = min{i | i ≥ d, l%s ≠ s%s}[/b]. Maak b intern, maak vanuit b een pad langs k%s, …, k%s en hang aan de laatste top twee bladeren k%s en k%s." % [_sub("i"), _sub("i"), _ss("s", "d"), _ss("s", "j−1"), _ss("l", "j"), _ss("s", "j")] +
			_ref("§3.1, p. 27 · Figuur 14: AAGCGA_ toegevoegd aan Figuur 13"),
			"schema_width": 600, "schema_node": fig_node(TtCodes.Kind.TRIE, F14, "dna", "Figuur 14")},
		{"title": "4 · Verwijderen", "text":
			"Zoek het blad op dat de string voorstelt. Verwijder dan [b]alle toppen op dit pad na de laatste top die ten minste twee niet-lege kinderen heeft[/b] (of na de wortel, als zo'n top niet bestaat).\n\n" +
			"Blijft alleen de wortel over, vervang die dan door een blad dat de lege string voorstelt.\n\n" +
			"De boom heeft altijd ten minste één top: hij start met één top die de lege string voorstelt.\n\n" +
			"[b]Oefening 17[/b]: voeg TGCGAAG_ toe aan de trie van Figuur 14. Verwijder dan TA_." +
			_ref("§3.1, p. 27")},
		{"title": "5 · Kost en geheugen", "text":
			"Opzoeken van een string van lengte m kan in [b]O(m)[/b]: een factor log n beter dan in een gebalanceerde zoekboom met n elementen, en zelfs [b]onafhankelijk van het aantal elementen[/b].\n\n" +
			"Het addertje onder het gras: is het alfabet groot (bv. alle ASCII-tekens), dan heeft elke top veel geheugen nodig, meestal voor [b]NULL-pointers[/b]. Zeker in een [i]dunne[/i] trie (weinig strings t.o.v. hun lengte).\n\n" +
			"Alternatieven: bv. hashmaps (minder geheugen bij veel NULL-pointers, maar trager), of de speciale tries hierna. Zie ook Oefening 18 (vertakken volgens 256 tekens of volgens {0, 1})." +
			_ref("§3.1, p. 26–28"),
			"schema": _ill_null},
		{"title": "6 · Patricia: skip", "text":
			"Patricia tries (Morrison, 1968: [i]Practical Algorithm to Retrieve Information Coded in Alphanumeric[/i]) vermijden lange paden [b]zonder vertakking[/b]: er zijn enkel interne toppen [b]met[/b] vertakking.\n\n" +
			"Daarvoor heeft elke interne top een extra variabele [b]skip[/b]: hoeveel lettertekens zonder vertakking er zijn. Die sla je gewoon over. Je zoekt dus enkel volgens de tekens waar er verschillende mogelijkheden zijn.\n\n" +
			"Ook [i]gecomprimeerde tries[/i] genoemd. Figuur 15: dezelfde trie op de gewone manier en als Patricia trie (getal links in de top = skip)." +
			_ref("§3.1.1, p. 28–30 · Figuur 15"),
			"schema_width": 560, "schema_node": fig_node(TtCodes.Kind.PATRICIA, TtLevels.F15P, "dna", "Figuur 15 (Patricia)")},
		{"title": "7 · Algoritme 1: zoek Patricia", "text":
			"[code]zoek_Patricia(s,m,top)   // s = s[lb]0],...,s[lb]m]\nnext=0\nwhile (top geen blad)\n{ if (next+top.skip > m) return \"niet gevonden\"\n  next = next+top.skip+1\n  top = top.kind[lb]s[lb]next-1]]\n  if (top = NULL) return \"niet gevonden\"\n}\nif (top.string = s) return \"gevonden\"\nelse return \"niet gevonden\"[/code]\n\n" +
			"next + skip > m: de string s is korter dan alle strings die je vanaf hier bereikt.\n" +
			"Complexiteit: net zoals voor gewone tries [b]O(m)[/b]." +
			_ref("§3.1.1, Algoritme 1, p. 29")},
		{"title": "8 · Pas in het blad", "text":
			"Omdat je tekens overslaat, kan de gezochte string al vroeg verschillen van de string in het blad, en [b]je merkt het niet[/b].\n\n" +
			"Zit AAAAABAAAAABC_ in de trie en wordt er enkel bij de B's vertakt, dan gaat opzoeken van BBBBBBBBBBBBB_ tot het blad met AAAAABAAAAABC_. Pas daar zie je dat het niet dezelfde string is, ook al verschilt al het eerste teken.\n\n" +
			"Belangrijk: zit de string [b]wel[/b] in de trie, dan wordt het juiste blad gevonden." +
			_ref("§3.1.1, p. 29"),
			"schema_width": 560, "schema_node": fig_node(TtCodes.Kind.PATRICIA, WASP_TREE, "abc", "enkel vertakt bij de B's (posities 5 en 11)")},
		{"title": "9 · Toevoegen in Patricia", "text":
			"Toevoegen is ingewikkelder: zolang je geen blad bereikt, weet je niet met welke prefix je bezig bent. Je kan pas laat merken dat je al vroeger een vertakking had moeten maken. Dan moet je eerst [b]een string vinden om de overgeslagen tekens te reconstrueren[/b].\n\n" +
			"Ligt de klemtoon ook op efficiënt toevoegen, dan kan je de [b]deelstrings met de overgeslagen tekens bij de interne toppen[/b] bijhouden. Dat vraagt wat extra geheugen, maar je kan dan al tijdens het zoeken de prefixen vergelijken; in de bladeren hoeft dan enkel het laatste deel." +
			_ref("§3.1.1, p. 29–30 · Figuur 15 (gewoon)"),
			"schema_width": 560, "schema_node": fig_node(TtCodes.Kind.TRIE, TtLevels.F15, "dna", "Figuur 15 (gewone voorstelling)")},
		{"title": "10 · Ternary tries", "text":
			"Ternary tries (Bentley en Sedgewick) zijn een manier om de [b]toppen[/b] van een trie voor te stellen; ze kunnen met alle soorten tries gecombineerd worden.\n\n" +
			"Elke top in de trie heeft een [b]pointerboom[/b] (klein zoekboompje) voor de kinderen. Elke top in de pointerboom heeft een sleutel uit het alfabet en [b]drie pointers[/b]: [b]kleiner[/b] en [b]groter[/b] gaan naar andere toppen in de pointerboom, [b]gelijk[/b] gaat naar de volgende top in de trie (het kind).\n\n" +
			"De pointerbomen bevatten enkel letters die echt gebruikt worden en worden bij het toevoegen [b]niet geherbalanceerd[/b]." +
			_ref("§3.1.2, p. 30–31 · Figuur 16"),
			"schema_width": 560, "schema_node": fig_node(TtCodes.Kind.TERNARY, TtLevels.F16T, "dna", "Figuur 16 (ternary)")},
		{"title": "11 · Wanneer loont ternary?", "text":
			"In Figuur 16 lijkt de ternary trie geen voordeel te hebben. Bevat het alfabet echter [b]alle ASCII-tekens[/b], dan eist de gewone manier veel meer ruimte, terwijl de ternary trie niet verandert. Interessant bij [b]grote alfabetten[/b] met veel NULL-pointers per interne top.\n\n" +
			"[b]Oefening 19[/b]: stel de trie van Figuur 17 voor als Patricia trie, als ternary trie, en als Patricia trie met de toppen op de manier van een ternary trie.\n" +
			"[b]Oefening 20[/b]: A = {a, c, g, t, _}, interne toppen met gemiddeld 2 kinderen: array van pointers of ternary trie? Geef uitleg." +
			_ref("§3.1.2, p. 31–32"),
			"schema_width": 560, "schema_node": fig_node(TtCodes.Kind.TRIE, TtLevels.F16, "dna", "Figuur 16 (gewone voorstelling)")},
		{"title": "12 · Suffixbomen", "text":
			"De tekst t wordt afgesloten door een uniek teken [code]_[/code]. De [b]suffixboom[/b] voor t is een trie die [b]alle suffixen[/b] van t bevat, en geen andere strings. Voor acacacgt_: acacacgt_, cacacgt_, acacgt_, cacgt_, acgt_, cgt_, gt_, t_ en _.\n\n" +
			"Hij lijkt het meest op een Patricia trie: [b]geen toppen met maar één kind[/b]. De overgeslagen strings staan, samen met het eerste teken dat het verschil maakt, [b]aan de bogen[/b] (Figuur 18).\n\n" +
			"Anders dan gewone tries (dynamisch) wordt een suffixboom normaal één keer opgebouwd (preprocessing) en blijft hij dan zo." +
			_ref("§3.2, p. 32–33 · Figuur 18"),
			"schema": _ill_garland.bind("acacacgt_", -1, -1)},
		{"title": "13 · (b,e)-labels: Θ(n)", "text":
			"Heeft de tekst lengte n, dan heeft de suffixboom [b]ten hoogste 2n − 1 toppen en 2n − 2 bogen[/b]: Θ(n). Maar alle strings expliciet opslaan vraagt Θ(n²) geheugen.\n\n" +
			"Alle opgeslagen strings zijn deelstrings van t: sla de tekst op en per string enkel [b]pointers naar begin en einde[/b] van een kopie in de tekst. Constant per string: samen [b]Θ(n)[/b].\n\n" +
			"De voor de hand liggende opbouw (suffix na suffix) vraagt wel tijd Θ(n²).\n" +
			"%s(Figuur 19 schrijft (0,1) bij de interne ac-bogen; hier de posities die Ukkonen kiest, (2,3): p. 48.)[/color]" % DIMC +
			_ref("§3.2, p. 33–34 · Figuur 19"),
			"schema_width": 600, "schema_node": fig_node(TtCodes.Kind.SUFFIX, TtLevels.F19U, "dna_lower", "Figuur 19: acacacgt_", "acacacgt_")},
		{"title": "14 · Ukkonen: het idee", "text":
			"[b]Stelling 2[/b]: de suffixboom voor een tekst van lengte n kan in tijd [b]O(n)[/b] opgebouwd worden (Ukkonen, 1995).\n\n" +
			"Bouw de [b]deelstringbomen[/b] S(1,1), S(1,2), …, S(1,n+1) op: telkens één teken meer (iteratie i+1). S(1,i) bevat alle deelstrings van s%s…s%s (Definitie 3); een string mag er prefix van een andere zijn. S(1,n+1), met s%s = _, is een echte suffixboom.\n\n" % [_sub("1"), _sub("i"), _sub("n+1")] +
			"In iteratie i+1 voeg je σ%s, σ%s, …, σ%s toe (σ%s = s%s…s%s). Lemma 4 en 5: de rij valt in drie blokken (schema)." % [_sub("1,i+1"), _sub("2,i+1"), _sub("i+1,i+1"), _sub("j,i"), _sub("j"), _sub("i")] +
			_ref("§3.2.1, p. 34–37"),
			"schema": _ill_blocks},
		{"title": "15 · Ukkonen: de gevallen", "text":
			"Waar eindigt s%s…s%s in S(1,i) als je s%s toevoegt?\n" % [_sub("j"), _sub("i"), _sub("i+1")] +
			"[b](i)[/b] in een blad: de eindpositie van de bladboog wordt i+1. Voor alle bladeren tegelijk: hun eindlabel is een pointer naar de variabele [b]it[/b].\n" +
			"[b](a)[/b] in een interne top met al een tak die met s%s begint: niets doen.\n" % _sub("i+1") +
			"[b](ii)[/b] in een interne top zonder zo'n tak: nieuwe tak naar een nieuw blad (i+1, it).\n" +
			"[b](b)[/b] midden in een boog, het volgende teken is s%s: niets doen.\n" % _sub("i+1") +
			"[b](iii)[/b] midden in een boog, volgend teken ≠ s%s: splits de boog, nieuwe top en nieuw blad.\n\n" % _sub("i+1") +
			"Bij de eerste (a) of (b) stop je de [b]hele iteratie[/b]. Over alle iteraties samen: O(n) stappen." +
			_ref("§3.2.1, p. 38–39")},
		{"title": "16 · Suffix links en de wijzer", "text":
			"[b]Suffix link[/b]: van een interne top t die s%s…s%s voorstelt naar de top l(t) die s%s…s%s voorstelt; de wortel linkt naar zichzelf.\n" % [_sub("i"), _sub("j"), _sub("i+1"), _sub("j")] +
			"[b]Wijzer (p, x)[/b]: p = laatste top op het pad, x = aantal tekens verder.\n" +
			"• Zelfde iteratie: p = wortel: (p%s, x − 1); anders (l(p), x).\n" % _sub("w") +
			"• Volgende iteratie: na σ%s toegevoegd (p%s, 0); na (a)/(b) (p, x + 1).\n" % [_sub("i+1,i+1"), _sub("w")] +
			"• Afdalen: is x̄ ≥ de lengte van de boog, ga naar de top en x̄ −= lengte. Enkel het [b]eerste teken[/b] en de [b]lengte[/b] bekijken: Σ m%s ≤ 4n.\n" % _sub("j") +
			"Een nieuwe interne top krijgt zijn link in de volgende stap. Alles samen: [b]O(n)[/b]." +
			_ref("§3.2.1, p. 40–43 · voorbeeld abacabc_, p. 44–48"),
			"schema_width": 560, "schema_node": ukkonen_node("abacabc_", "abacabc_ na de laatste iteratie (it = 8), p. 48")},
		{"title": "17 · Toepassingen (§3.3)", "text":
			"• Zoek z (lengte m) in t (lengte n): bouw de suffixboom in O(n) en volg de tekens van z vanuit de wortel in [b]O(m)[/b]. Is de boom al opgebouwd: O(m), hoe lang de tekst ook is.\n" +
			"• [b]Een positie[/b]: Ukkonen geeft een nieuwe boog vanuit top t (string s%s, lengte l%s) een beginlabel b zodat op positie [b]b − l%s[/b] een deelstring begint die met s%s begint en met de tekens van de boog doorgaat; b wijzigt nooit meer. Neem de boog waarin het laatste teken van z zit: b − l%s is een positie van z.\n" % [_sub("t"), _sub("t"), _sub("t"), _sub("t"), _sub("t")] +
			"• [b]Oefening 28[/b]: is dat altijd de eerste positie? Alle k posities in O(m + k).\n" +
			"• [b]Oefening 29[/b]: hoe vaak z voorkomt, in O(m)." +
			_ref("§3.3, p. 48–49"),
			"schema": _ill_garland.bind("acacacgt_", 1, 3)},
		{"title": "18 · Veralgemeende suffixboom", "text":
			"Meerdere teksten t%s, …, t%s: zit z in een ervan, en in welke? (DNA-databank, een citaat in boeken.) Apart zoeken kost O(i·m).\n\n" % [_sub("1"), _sub("i")] +
			"Een [b]veralgemeende suffixboom[/b] bevat de suffixen van alle teksten samen, met unieke afsluitingstekens _%s, _%s, … (t%s eindigt op _%s).\n\n" % [_sub("1"), _sub("2"), _sub("i"), _sub("i")] +
			"[b]Onechte[/b] versie in O(n), n = n%s + … + n%s: schrijf de teksten achter elkaar en bouw de suffixboom van t%s t%s … t%s. Suffixen met een afsluitteken in het midden geven geen foute matches: daar zoek je nooit naar.\n\n" % [_sub("1"), _sub("k"), _sub("1"), _sub("2"), _sub("k")] +
			"Verder: [b]suffix arrays[/b], alle suffixen in lexicografische volgorde (één integer per teken)." +
			_ref("§3.3, p. 49–50")},
	]


# ======================================================================
#  schema's
# ======================================================================

## Figuur in notas-stijl (TtNotesView) uit een notatie van de core.
static func fig_node(kind: int, notation: String, alpha_name: String, title: String, text := "") -> Callable:
	return func() -> Control:
		var a := TtAlphabet.by_name(alpha_name)
		var m: TtTreeModel = null
		match kind:
			TtCodes.Kind.TRIE:
				m = TtTrie.new().setup(a, notation)
			TtCodes.Kind.PATRICIA:
				m = TtPatricia.new().setup(a, notation)
			TtCodes.Kind.TERNARY:
				var tm := TtTernary.new().setup(a)
				tm.load_notation(notation)
				m = tm
			TtCodes.Kind.SUFFIX:
				var sm := TtSuffixTree.new().setup(a, text, 0, "pointers")
				sm.load_notation(notation)
				m = sm
		return _notes_control(m.render_nodes(), kind, "".join(a.letters), 0, text, title)


## Eindboom van Ukkonen (bladlabels (b, it)), positie vanaf 1 zoals p. 44–48.
static func ukkonen_node(text: String, title: String) -> Callable:
	return func() -> Control:
		var a := TtAlphabet.abc_lower()
		var u := TtUkkonen.new().setup_text(a, text, 1)
		u.run_all()
		return _notes_control(u.render_nodes(), TtCodes.Kind.UKKONEN, "".join(a.letters), 1, text, title)


static func _notes_control(nodes: Array, kind: int, letters: String, base: int, text: String, title: String) -> Control:
	var nv := TtNotesView.new()
	nv.resized.connect(func():
		nv.rect = Rect2(Vector2(6, 6), nv.size - Vector2(12, 12))
		nv.setup(nodes, kind, letters, base, text, title))
	return nv


static func _bg(ci: Control, size: Vector2) -> void:
	ci.draw_style_box(TtPal.sb(TtPal.PANEL_LO, 18), Rect2(Vector2(6, 6), size - Vector2(12, 12)))


static func _ill_knot(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var c := Vector2(size.x / 2.0, size.y * 0.55)
	var tops := TtDraw.knot(ci, c, "ACGT_", [true, false, false, true, false], 44.0)
	var se := TtPal.season(0)
	# twee takjes omhoog met een vrucht
	for i in [0, 3]:
		var p: Vector2 = tops[i]
		var q := p + Vector2(-60 if i == 0 else 60, -120)
		ci.draw_line(p, q, TtPal.BARK, 9.0, true)
		TtDraw.fruit(ci, q, se, "ACGT_" if i == 0 else "TGG_", 0.0, 0, 22.0, "ACGT_", 18)
	ci.draw_line(c + Vector2(0, 22), c + Vector2(0, 66), TtPal.BARK, 14.0, true)
	TtDraw.ellipse(ci, c + Vector2(0, 70), 46, 10, TtPal.BARK_DARK)
	TtPal.text_c(ci, TtPal.UI_BOLD, c + Vector2(0, 100), "kiem = wortel (lege string)", 22, TtPal.TEXT)
	TtPal.text_c(ci, TtPal.UI, c + Vector2(0, 140), "knoppenkrans = interne top", 22, TtPal.TEXT_DIM)
	TtPal.text_c(ci, TtPal.UI, c + Vector2(0, 172), "grijs knopje = NULL-pointer", 22, TtPal.TEXT_DIM)
	TtPal.text_c(ci, TtPal.UI, Vector2(c.x, c.y - 230), "vrucht = blad met label", 22, TtPal.TEXT_DIM)


static func _ill_null(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var c := Vector2(size.x / 2.0, size.y * 0.30)
	TtDraw.knot(ci, c, "ACGT_", [false, true, false, false, false], 44.0)
	TtPal.text_c(ci, TtPal.UI_BOLD, c + Vector2(0, 60), "|A| = 5: 1 kind, 4 NULL-pointers", 22, TtPal.TEXT)
	var c2 := Vector2(size.x / 2.0, size.y * 0.66)
	var abc := "abcdefghijklmnopqrstuvwxyz_"
	var used: Array = []
	for ch in abc:
		used.append(ch == "k")
	TtDraw.knot(ci, c2, abc, used, 17.0, -1, 0.0, true)
	TtPal.text_c(ci, TtPal.UI_BOLD, c2 + Vector2(0, 60), "|A| = 27: 1 kind, 26 NULL-pointers", 22, TtPal.TEXT)


static func _ill_compare(ci: Control, size: Vector2, l: String, s: String, d: int, j: int) -> void:
	_bg(ci, size)
	var n := maxi(l.length(), s.length())
	var cell := minf(56.0, (size.x - 120.0) / n)
	var w := n * cell + 70
	TtDraw.compare_ribbon(ci, Vector2(size.x / 2.0 - w / 2.0, size.y * 0.42), l, s, d, -1, j, cell, 26)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(size.x / 2.0, size.y * 0.72), "d = %d, eerste verschil: j = %d" % [d, j], 26, TtPal.TEXT)


static func _ill_bee(ci: Control, size: Vector2, wasp: float) -> void:
	_bg(ci, size)
	var c := size / 2.0 + Vector2(0, -30)
	TtDraw.bee(ci, c + Vector2(-110, 0), 2.2, 0.0, 1.0, 0, "", "ABC_", -1, true, -1, 0.0)
	TtDraw.bee(ci, c + Vector2(110, 0), 2.2, 0.0, -1.0, 0, "", "ABC_", -1, true, -1, wasp)
	TtPal.text_c(ci, TtPal.UI_BOLD, c + Vector2(-110, 110), "bij", 26, TtPal.TEXT)
	TtPal.text_c(ci, TtPal.UI_BOLD, c + Vector2(110, 110), "wesp", 26, TtPal.TEXT)
	TtPal.text_c(ci, TtPal.UI, c + Vector2(0, 170), "pas bij de vrucht zie je de strepen", 22, TtPal.TEXT_DIM)


static func _ill_rank(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var c := Vector2(size.x / 2.0, size.y * 0.62)
	var ends := [c + Vector2(-170, -150), c + Vector2(0, -230), c + Vector2(170, -150)]
	var cols := [TtPal.LESS, TtPal.EQUAL, TtPal.GREATER]
	for i in 3:
		TtDraw.tendril(ci, c, ends[i], cols[i], 0.0, 6.0)
	TtDraw.rank_knot(ci, c, "G", 0.0, [true, true, true], 46.0, "ACGT_")
	var sub := ["C", "", "T"]
	for i in 3:
		if sub[i] != "":
			TtDraw.rank_knot(ci, ends[i], sub[i], 0.0, [false, true, false], 30.0, "ACGT_")
		else:
			TtDraw.knot(ci, ends[i] + Vector2(0, -10), "ACGT_", [true, false, true, false, false], 22.0, -1, 0.0, true)
	TtPal.text_c(ci, TtPal.UI_BOLD, ends[0] + Vector2(0, 62), "kleiner", 24, TtPal.LESS)
	TtPal.text_c(ci, TtPal.UI_BOLD, ends[1] + Vector2(46, 34), "gelijk = kind", 24, TtPal.EQUAL)
	TtPal.text_c(ci, TtPal.UI_BOLD, ends[2] + Vector2(0, 62), "groter", 24, TtPal.GREATER)
	TtPal.text_c(ci, TtPal.UI, c + Vector2(0, 92), "bol = sleutel + 3 pointers", 22, TtPal.TEXT_DIM)


static func _ill_garland(ci: Control, size: Vector2, text: String, hb: int, he: int) -> void:
	_bg(ci, size)
	var n := text.length()
	var gap := minf(54.0, (size.x - 100.0) / maxf(1.0, n - 1))
	var x0 := Vector2(size.x / 2.0 - gap * (n - 1) / 2.0, size.y * 0.36)
	TtDraw.garland(ci, x0, text, gap, TtPal.season(3), 0.0, hb, he, 16.0, "acgt_")
	var cap := "tekst t met afsluitteken _ (posities 0..%d)" % (n - 1)
	if hb >= 0:
		cap = "parels %d..%d = de string \"%s\"" % [hb, he, text.substr(hb, he - hb + 1)]
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(size.x / 2.0, size.y * 0.76), cap, 22, TtPal.TEXT)


static func _ill_inspector(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var c := size / 2.0 + Vector2(-40, 20)
	TtDraw.hedgehog(ci, c, 1.6)
	TtDraw.magnifier(ci, c + Vector2(130, -90), 36.0)


static func _ill_firefly(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var gap := minf(54.0, (size.x - 100.0) / 7.0)
	TtDraw.garland(ci, Vector2(size.x / 2.0 - gap * 3.5, size.y * 0.26), "abacabc_", gap, TtPal.season(3), 0.0, -1, -1, 14.0, "abc_")
	TtDraw.firefly(ci, Vector2(size.x / 2.0, size.y * 0.58), 2.4, 0.0, -1)
	TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(size.x / 2.0, size.y * 0.78), "vuurvliegje = wijzer (p, x)", 24, TtPal.TEXT)


## Schets van p. 37: σ_{1,i+1} … σ_{i+1,i+1} in drie blokken.
static func _ill_blocks(ci: Control, size: Vector2) -> void:
	_bg(ci, size)
	var x := 30.0
	var w := size.x - 60.0
	var y := size.y * 0.30
	var parts := [[0.34, TtPal.OK, "toevoegen\naan blad", "(i): via it"], [0.33, TtPal.SAP, "toevoegen\nop plaats die\ngeen blad is", "(ii) / (iii)"],
		[0.33, TtPal.INFO, "zit al in\nde boom", "(a) / (b): stop"]]
	TtPal.text_l(ci, TtPal.MONO_B, Vector2(x, y - 50), "σ1,i+1 … σb−1 | σb … σb′−1 | σb′ … σi+1,i+1", 17, TtPal.TEXT)
	for p in parts:
		var pw: float = w * float(p[0])
		var r := Rect2(x, y, pw - 8, 110)
		ci.draw_style_box(TtPal.sb(p[1], 12), r)
		var lines: PackedStringArray = str(p[2]).split("\n")
		for k in lines.size():
			TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(r.get_center().x, r.get_center().y + (k - (lines.size() - 1) / 2.0) * 26), lines[k], 19, TtPal.INK)
		TtPal.text_c(ci, TtPal.UI_BOLD, Vector2(r.get_center().x, r.end.y + 30), str(p[3]), 20, TtPal.TEXT)
		x += pw
	TtPal.text_c(ci, TtPal.UI, Vector2(size.x / 2.0, y + 190), "b(i) groeit enkel: eens blad, altijd blad", 22, TtPal.TEXT_DIM)


# ======================================================================
#  tekens die Fredoka mist -> monospace (JetBrains Mono heeft ze)
# ======================================================================

const _MONO_CHARS := "≥≤→←↑↓≠∅Θσ⌊⌋∞∈√′Σ"


static func _fix(s: String) -> String:
	var out := ""
	var in_code := false
	var i := 0
	while i < s.length():
		if s.substr(i, 6) == "[code]":
			in_code = true
		elif s.substr(i, 7) == "[/code]":
			in_code = false
		var ch := s[i]
		if not in_code and _MONO_CHARS.contains(ch):
			out += "[code]" + ch + "[/code]"
		else:
			out += ch
		i += 1
	return out


static func _fix_pages(pages: Array) -> Array:
	for pg in pages:
		pg["text"] = _fix(str(pg.get("text", "")))
		pg["title"] = _fix(str(pg.get("title", "")))
	return pages
