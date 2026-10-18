class_name ScLessons
extends Object
## Leerpad van Kortschrift (games/scriptorium/design/LEARNING_PATH.md, design/LEARNING.md): de delen in volgorde, per
## deel een Kijk- en een Samen-voorbeeld (kleine stages voor ScDirector), de verteltekst per stap (afgeleid van het
## orakel correct_move() en een proefkopie van het werktuig, dus altijd juist), tips/foutuitleg voor Samen, de toestand
## zoals je ze op het examen noteert, voorspelvragen (Check in de wereld) en Check-vragen voor de terugblik op een NIEUW
## willekeurig voorbeeld (antwoord altijd berekend met ScReference).
## Pure logica + data: geen nodes (ook gebruikt in tests/suites/t_lessons.gd).

const SAVE_KEY := "learning"     # ScSave setting: {"huffman": {"kijk": true, "samen": true, "check": true}, ...}
const V := ScCodes.Verdict
const P := ScCodes.Phase
const C_DIM := "#CDB394"
const C_OK := "#A8E07E"
const C_ERR := "#FF8A6A"
const C_HL := "#F4D27A"
const LEVEL_TXT := ["nog niet gezien", "demo bekeken", "samen geoefend", "begrepen"]
const MODEL_ABC := [["a", "0.5"], ["b", "0.3"], ["c", "0.2"]]

static var _mem := {}            # voortgang zonder save (nosave)
static var _parts_cache: Array = []


# ======================================================================
#  de delen (volgorde = opbouw)
# ======================================================================

## Elk deel: id, title, levels (Zelf; het eerste is de poort), page, rule, idea, kijk/samen: {stages, ask, auto, fig,
## until_phase}. ask = voorspelvragen [{on: act, nth: n, q: soort}] (nth telt de zetten met die act in de les).
static func parts() -> Array:
	var tok_graag := ScReference.tokens_to_string(ScReference.adaptive_encode("graag").tokens)
	var tok_kaak := ScReference.tokens_to_string(ScReference.adaptive_encode("kaak").tokens)
	return [
		{"id": "prefix_lezen", "title": "Prefixcode lezen: volg de takken tot een blad", "levels": ["0-1"],
			"page": "Figuur 25 · p. 82–84",
			"rule": "Begin bij de wortel: 0 = links, 1 = rechts. Bij een blad schrijf je de letter en begin je opnieuw bij de wortel.",
			"idea": "Een codeboom is een prefixcode: de codewoorden zijn de paden naar de bladeren. Zo weet de lezer altijd waar een letter stopt.",
			"kijk": {"stages": [{"tool": "prefix_read", "code": ScLevels.FIG25, "bits": "00010011", "expect": "oud"}],
				"ask": [{"on": "read", "nth": 2, "q": "next"}], "fig": "Figuur 25 (o = 00, u = 010, d = 011, f = 10, t = 11)"},
			"samen": {"stages": [{"tool": "prefix_read", "code": ScLevels.FIG25, "bits": "0110011", "expect": "dot"}],
				"ask": [{"on": "read", "nth": 2, "q": "next"}]}},
		{"id": "prefix_def", "title": "Waarom prefix? (Definitie 20)", "levels": ["0-2"], "page": "Definitie 20 · p. 82–83",
			"rule": "Een prefixcode: geen codewoord is het begin (prefix) van een ander. In de boom hangen letters enkel aan bladeren.",
			"idea": "Met e = 0, n = 1, b = 10 is 1 het begin van 10: dezelfde strook kan dan verschillende teksten zijn. Met een prefixcode is er maar één lezing.",
			"kijk": {"stages": [{"tool": "code_board", "mode": "cuts", "code": ScLevels.BEN, "bits": "100101", "need": 2, "intended": "benen"}],
				"ask": [{"on": "cut", "nth": 1, "q": "readings"}], "fig": "de eerste aanzet, p. 82 (e = 0, n = 1, b = 10)"},
			"samen": {"stages": [{"tool": "code_board", "mode": "design", "text": "been", "max_depth": 2}],
				"ask": [{"on": "send", "nth": 1, "q": "ink"}]}},
		{"id": "duiventil", "title": "Geen algoritme comprimeert alles", "levels": ["0-3"], "page": "Oefening 76 · p. 81–82",
			"rule": "Er zijn 2^n berichten van n bits, maar maar 1 + 2 + … + 2^(n−1) = 2^n − 1 kortere bitstrings (het lege woord ε inbegrepen).",
			"idea": "Twee berichten mogen nooit op hetzelfde resultaat uitkomen. Wie één bericht korter maakt, maakt dus een ander langer.",
			"kijk": {"stages": [{"tool": "dovecote", "bits": 3}], "ask": [{"on": "roost", "nth": 1, "q": "holes"}],
				"fig": "Oefening 76: 8 berichten van 3 bits"},
			"samen": {"stages": [{"tool": "dovecote", "bits": 2}], "ask": [{"on": "decree", "nth": 2, "q": "next"}]}},
		{"id": "huffman", "title": "Huffman: bind de twee lichtste (Algoritme 9)", "levels": ["1-1", "1-2", "1-3", "1-4"],
			"page": "Algoritme 9 · p. 84–86",
			"rule": "Bind telkens de twee bomen met de kleinste frequentie a(x) tot één boom; de nieuwe wortel weegt de som. Links = 0, rechts = 1.",
			"idea": "Het touw = de som van de gewichten van alle bundels = Σ a(x)·l(x) = het aantal bits (Stelling 21: minimaal). Bij gelijk gewicht is elke keuze even goed.",
			"kijk": {"stages": [{"tool": "bindery", "mode": "row", "text": "boosdoeer", "row": "boesdr"}],
				"ask": [{"on": "bind", "nth": 3, "q": "next"}, {"on": "bind", "nth": 5, "q": "twine"}], "fig": "boosdoeer, p. 84–85"},
			"samen": {"stages": [{"tool": "bindery", "mode": "row", "text": "kaaskop"}],
				"ask": [{"on": "bind", "nth": 2, "q": "next"}, {"on": "bind", "nth": 4, "q": "twine"}]}},
		{"id": "planken", "title": "Twee planken (Oefening 85)", "levels": ["1-5"], "page": "Oefening 85 · p. 88",
			"rule": "Lijst (a) = plank A: de letters gesorteerd op gewicht; lijst (b) = plank B: de bundels, in het begin leeg. Kies 2 keer het kleinste van wat vooraan staat; de nieuwe bundel gaat achteraan plank B.",
			"idea": "Een nieuwe bundel is nooit lichter dan een vorige: B blijft vanzelf gesorteerd. Na het sorteren kost het zoeken van de twee lichtste dus O(1) per stap.",
			"kijk": {"stages": [{"tool": "bindery", "mode": "shelves", "text": "boosdoeer"}],
				"ask": [{"on": "bind", "nth": 3, "q": "next"}], "fig": "boosdoeer met lijst (a) en (b)"},
			"samen": {"stages": [{"tool": "bindery", "mode": "shelves", "text": "kaaskop"}],
				"ask": [{"on": "bind", "nth": 2, "q": "next"}]}},
		{"id": "fgk_klim", "title": "Adaptieve Huffman: wisselen en klimmen", "levels": ["2-1"],
			"page": "Lemma 22, Algoritme 11 · p. 89–93",
			"rule": "Schrijf het teken met de boom van nu. Dan vanaf het blad t: t′ = de top met hetzelfde gewicht en het hoogste nummer. Is t′ niet t (en niet de ouder): wissel. Dan a(t) + 1 en t = ouder van t.",
			"idea": "Elke top heeft [lb]gewicht,nummer]. Zo blijven (a) gewicht = som van de kinderen, (b) gewicht stijgt met het nummer en (c) 2j−1 en 2j zijn broers waar: de boom blijft optimaal (Lemma 22).",
			"kijk": {"stages": [{"tool": "living_tree", "side": "send", "text": "s", "start": "p90"}],
				"ask": [{"on": "climb", "nth": 1, "q": "next"}], "fig": "de [lb]g,o]-boom van p. 90 (boosdoeer)"},
			"samen": {"stages": [{"tool": "living_tree", "side": "send", "text": "d", "start": "p90"}],
				"ask": [{"on": "climb", "nth": 2, "q": "next"}]}},
		{"id": "fgk_nieuw", "title": "Eerst schrijven, nieuw teken via nng", "levels": ["2-2", "2-4"],
			"page": "Algoritme 10/11 · p. 92–98",
			"rule": "Schrijf eerst met de boom vóór de wijziging. Nieuw teken: code(nng) + het teken ruw (8 bits). nng wordt een ouder o met nng [lb]0,1] en het nieuwe blad [lb]1,2]; o krijgt nummer 3, de andere nummers +2; verder klimmen vanaf de ouder van o.",
			"idea": "nng = \"nog niet gezien\". In de lege boom is nng de wortel: het eerste teken gaat ruw, zonder bits ervoor.",
			"kijk": {"stages": [{"tool": "living_tree", "side": "send", "text": "graag", "start": "empty"}],
				"ask": [{"on": "write", "nth": 1, "q": "next"}], "fig": "graag, p. 96–98"},
			"samen": {"stages": [{"tool": "living_tree", "side": "send", "text": "gaga", "start": "empty"}],
				"ask": [{"on": "write", "nth": 2, "q": "next"}]}},
		{"id": "fgk_ouder", "title": "Het speciale geval: t′ is de ouder", "levels": ["2-3"], "page": "Algoritme 11 · p. 95",
			"rule": "De broer van nng heeft een ouder met hetzelfde gewicht. Is die ouder t′, dan wissel je niet: a(t) + 1 en verder met de ouder.",
			"idea": "Je kan een top niet vervangen door een boom waar hij zelf in zit. Zonder wissel blijven (a), (b) en (c) toch waar.",
			"kijk": {"stages": [{"tool": "living_tree", "side": "send", "text": "neen", "start": "empty"}],
				"ask": [{"on": "climb", "nth": 2, "q": "next"}], "fig": "het speciale geval, p. 95"},
			"samen": {"stages": [{"tool": "living_tree", "side": "send", "text": "kaak", "start": "empty"}],
				"ask": [{"on": "climb", "nth": 2, "q": "next"}]}},
		{"id": "fgk_lezen", "title": "Adaptief decoderen: de ontvanger", "levels": ["2-5"], "page": "p. 98 · Oefening 91",
			"rule": "Lees bits tot een blad. Is het nng, dan volgt de letter ruw. Werk daarna de boom bij, precies zoals de afzender.",
			"idea": "Ontvanger en afzender beginnen met dezelfde boom en doen dezelfde wijzigingen: zo hebben ze na elk teken weer dezelfde boom.",
			"kijk": {"stages": [{"tool": "living_tree", "side": "receive", "tokens": tok_graag, "expect": "graag"}],
				"ask": [{"on": "read", "nth": 2, "q": "next"}], "fig": "de uitvoer van graag (p. 98)"},
			"samen": {"stages": [{"tool": "living_tree", "side": "receive", "tokens": tok_kaak, "expect": "kaak"}],
				"ask": [{"on": "read", "nth": 2, "q": "next"}]}},
		{"id": "arit_interval", "title": "Aritmetisch coderen: het interval (Algoritme 12)", "levels": ["3-1", "3-2", "3-4"],
			"page": "Algoritme 12 · p. 98–101",
			"rule": "links = 0, lengte = 1. Per teken: links += f(s[lb]i])·lengte en lengte ×= p(s[lb]i]); f = het begin van het vak van het teken.",
			"idea": "Het interval [lb]links, links+lengte) krimpt bij elk teken tot het vak van dat teken; de lengte is het product van de kansen.",
			"kijk": {"stages": [{"tool": "ruler", "side": "send", "model": ScLevels.XYZ, "text": "yy", "auto_after": -1}],
				"ask": [{"on": "cut", "nth": 2, "q": "interval"}], "until_phase": P.NEEDLE,
				"fig": "model p(x) = 0,2 · p(y) = 0,7 · p(z) = 0,1 (p. 99)"},
			"samen": {"stages": [{"tool": "ruler", "side": "send", "model": ScLevels.ACGT, "text": "gc", "auto_after": -1}],
				"ask": [{"on": "cut", "nth": 2, "q": "interval"}], "until_phase": P.NEEDLE}},
		{"id": "arit_bits", "title": "De kortste bitstring (Algoritme 13)", "levels": ["3-1", "3-2", "3-4"],
			"page": "Algoritme 13 · p. 100–102",
			"rule": "getal = 0, next = 0,5. Is getal + next < up: schrijf 1 en getal += next (klaar zodra getal ≥ low); anders schrijf 0. Dan next = next / 2.",
			"idea": "Bits b1 b2 … stellen Σ bi·2^(−i) voor. Je zoekt het kortste getal in [lb]low, up); is low = 0, dan volstaat 0.",
			"kijk": {"stages": [{"tool": "ruler", "side": "send", "model": ScLevels.XYZ, "text": "xy", "auto_after": 0}],
				"ask": [{"on": "bit", "nth": 3, "q": "next"}], "fig": "xy met het model van p. 99"},
			"samen": {"stages": [{"tool": "ruler", "side": "send", "model": ScLevels.ACGT, "text": "cg", "auto_after": 0}],
				"ask": [{"on": "bit", "nth": 1, "q": "next"}]}},
		{"id": "arit_lezen", "title": "Decoderen: in welk vak zit de speld?", "levels": ["3-1", "3-3"],
			"page": "p. 99–102 · Oefening 94/95",
			"rule": "Zet de speld op de waarde r van de bits. Kies telkens het vak [lb]lo, hi) waarin r ligt en zoom in; n tekens lang.",
			"idea": "Onderrand dicht, bovenrand open: r = 0,9 hoort bij [lb]0,9; 1), niet bij [lb]0,2; 0,9).",
			"kijk": {"stages": [{"tool": "ruler", "side": "receive", "model": ScLevels.XYZ, "pin": "0.9", "n": 2, "expect": "zx"}],
				"ask": [{"on": "cut", "nth": 1, "q": "next"}], "fig": "het model van p. 99"},
			"samen": {"stages": [{"tool": "ruler", "side": "receive", "model": ScLevels.ACGT, "bits": "011", "n": 2, "expect": "cc"}],
				"ask": [{"on": "cut", "nth": 2, "q": "next"}]}},
		{"id": "lz77_zend", "title": "LZ77: de langste match in het raam (Algoritme 14)", "levels": ["4-1", "4-3", "4-5"],
			"page": "Algoritme 14 · p. 104–107",
			"rule": "Het raam = de laatste G tekens, posities vanaf 0 links. Zoek de langste match die in het raam begint (ze mag erbuiten eindigen); schrijf (p, l, x) en ga l + 1 tekens verder. Geen match: (0, 0, x).",
			"idea": "De tekst zelf is het woordenboek. x = het teken na de match (EOF als de tekst op is).",
			"kijk": {"stages": [{"tool": "window", "side": "send", "text": "banaan-baan", "G": 6, "register": false}],
				"ask": [{"on": "triple", "nth": 7, "q": "next"}], "fig": "banaan-baan met G = 6 (p. 106–107)"},
			"samen": {"stages": [{"tool": "window", "side": "send", "text": "anna_ananas", "G": 4, "register": false}],
				"ask": [{"on": "triple", "nth": 6, "q": "next"}]}},
		{"id": "lz77_lees", "title": "LZ77 decoderen", "levels": ["4-2", "4-4"], "page": "p. 108",
			"rule": "Bouw hetzelfde raam op. Bij (p, l, x): kopieer l letters vanaf positie p van het raam, één voor één, en schrijf dan x.",
			"idea": "Letter per letter kopiëren: zo mag de bron voorbij het raam lopen in wat je net schrijft (bv. (0, 9, EOF) bij blablabla).",
			"kijk": {"stages": [{"tool": "window", "side": "receive", "G": 6, "expect": "aanvaardbaar", "triples": [[0, 0, "a"],
				[0, 1, "n"], [0, 0, "v"], [0, 2, "r"], [0, 0, "d"], [0, 0, "b"], [1, 3, "EOF"]]}],
				"ask": [{"on": "copy", "nth": 3, "q": "next"}], "fig": "aanvaardbaar, p. 108"},
			"samen": {"stages": [{"tool": "window", "side": "receive", "G": 4, "expect": "kaka_kakao",
				"triples": ScReference.lz77_encode("kaka_kakao", 4).triples}],
				"ask": [{"on": "copy", "nth": 2, "q": "next"}]}},
		{"id": "lz77_register", "title": "Oneindig raam en het register (§4.3.1)", "levels": ["4-6"], "page": "§4.3.1 · p. 109–110",
			"rule": "Zonder sliding window (G = ∞) is de hele tekst tot nu het woordenboek. Het register (een deelstringboom) zoekt de langste match met één blik per letter.",
			"idea": "Met het algoritme van Ukkonen groeit de boom mee: alles samen O(n). Maar de boom vraagt veel geheugen.",
			"kijk": {"stages": [{"tool": "window", "side": "send", "text": "kaka_kakao", "G": -1, "register": true}],
				"ask": [{"on": "triple", "nth": 4, "q": "next"}], "fig": "§4.3.1: LZ77 met een deelstringboom"},
			"samen": {"stages": [{"tool": "window", "side": "send", "text": "nana_banaan", "G": -1, "register": true}],
				"ask": [{"on": "triple", "nth": 5, "q": "next"}]}},
		{"id": "lzw_zend", "title": "LZW coderen", "levels": ["5-1", "5-3", "5-5"], "page": "LZW · p. 110–112",
			"rule": "Zit wk (woord + volgend teken) in het woordenboek: w = wk (verleng). Anders: schrijf code(w), voeg wk toe met de volgende code (vanaf 256) en w = k (stempel).",
			"idea": "Het woordenboek begint met de 256 bytes (a = 97). Op het einde schrijf je nog code(w).",
			"kijk": {"stages": [{"tool": "stampcase", "side": "send", "text": "banaanaanval"}],
				"ask": [{"on": "decide", "nth": 5, "q": "next"}], "fig": "banaanaanval, p. 111–112"},
			"samen": {"stages": [{"tool": "stampcase", "side": "send", "text": "barbara"}],
				"ask": [{"on": "decide", "nth": 4, "q": "next"}]}},
		{"id": "lzw_lees", "title": "LZW decoderen en de lege lade", "levels": ["5-2", "5-4"], "page": "p. 112–114",
			"rule": "Na elke code voeg je toe: vorig woord w + de eerste letter van het nieuwe woord. Is de code nog niet gekend (lege lade), dan is het nieuwe woord w + w[lb]0].",
			"idea": "De lade is enkel leeg als de afzender een woord meteen na het toevoegen gebruikte; dan begint het met dezelfde letter als w.",
			"kijk": {"stages": [{"tool": "stampcase", "side": "receive", "codes": [97, 110, 256, 258, 115], "expect": "anananas"}],
				"ask": [{"on": "carve", "nth": 2, "q": "next"}], "fig": "97 110 256 258 115, p. 113"},
			"samen": {"stages": [{"tool": "stampcase", "side": "receive", "codes": [97, 98, 256, 258], "expect": "abababa"}],
				"ask": [{"on": "carve", "nth": 2, "q": "next"}]}},
		{"id": "bwt_zend", "title": "Burrows-Wheeler: sorteren, p en de laatste kolom", "levels": ["6-1", "6-3", "6-4"],
			"page": "Burrows-Wheeler · p. 115–117",
			"rule": "Vorm alle rotaties (elke strook begint één letter verder) en sorteer ze; de spatie is het kleinst. Uitvoer: p = de rij die eindigt op s[lb]0], en de laatste kolom.",
			"idea": "De laatste kolom bevat dezelfde letters, maar beter gegroepeerd. Alle rotaties moeten verschillend zijn.",
			"kijk": {"stages": [{"tool": "drum", "side": "send", "text": "geen loon", "auto_sort": false}],
				"ask": [{"on": "mark", "nth": 1, "q": "next"}], "fig": "geen loon, p. 115–117"},
			"samen": {"stages": [{"tool": "drum", "side": "send", "text": "banaan", "auto_sort": false}],
				"ask": [{"on": "mark", "nth": 1, "q": "next"}]}},
		{"id": "mtf", "title": "Move-to-front", "levels": ["6-1", "6-2", "6-3"], "page": "move-to-front · p. 121",
			"rule": "Schrijf de positie c(x) van het teken x in de lijst zoals ze nu is (vanaf 0) en zet x vooraan. Ontvangen: het teken op die positie, en dat vooraan.",
			"idea": "Na Burrows-Wheeler staan gelijke letters vaak samen: dan komen er veel nullen en kleine getallen, goed voor Huffman.",
			"kijk": {"stages": [{"tool": "shelf", "side": "send", "input": "1 ngen eool", "list": ScLevels.LIST61, "positions": true}],
				"ask": [{"on": "number", "nth": 4, "q": "next"}], "fig": "lijst ( ,1,a,b,e,f,g,n,o,l), p. 121"},
			"samen": {"stages": [{"tool": "shelf", "side": "receive", "nums": [2, 2, 2, 2, 1, 0], "list": ["a", "b", "n"],
				"expect": "nbanaa", "positions": true}], "ask": [{"on": "pick", "nth": 5, "q": "next"}]}},
		{"id": "bwt_terug", "title": "BWT terug: de k-de x in e is de k-de x in c", "levels": ["6-2", "6-4"],
			"page": "p. 117–119",
			"rule": "e = c gesorteerd (de eerste kolom). Na c[lb]i] komt in de tekst e[lb]i]. Begin bij rij p; zoek telkens in c dezelfde letter met dezelfde rang als x in e.",
			"idea": "Gelijke letters koppel je in volgorde: de k-de x in e is de k-de x in c. De lus loopt n keer, dus herhalingen zijn geen probleem.",
			"kijk": {"stages": [{"tool": "drum", "side": "receive", "p": 1, "c": "ngen eool", "ranks": true, "expect": "geen loon"}],
				"ask": [{"on": "find", "nth": 3, "q": "next"}], "fig": "(1, ngen eool), p. 117–119"},
			"samen": {"stages": [{"tool": "drum", "side": "receive", "p": 1, "c": "nbanaa", "ranks": true, "expect": "banaan"}],
				"ask": [{"on": "find", "nth": 2, "q": "next"}]}},
	]


static func all_parts() -> Array:
	if _parts_cache.is_empty():
		_parts_cache = parts()
	return _parts_cache


static func part(id: String) -> Dictionary:
	for p in all_parts():
		if str(p.id) == id:
			return p
	return {}


static func index_of_part(id: String) -> int:
	var ps := all_parts()
	for i in ps.size():
		if str(ps[i].id) == id:
			return i
	return -1


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for p in all_parts():
		out.append(str(p.id))
	return out


static func cfg(id: String, phase: String) -> Dictionary:
	return part(id).get(phase, {})


## Delen waarvan `level` de poort is (het eerste Zelf-level): badges in het getijdenboek.
static func parts_for_level(level: String) -> Array:
	var out: Array = []
	for p in all_parts():
		if str(p.levels[0]) == level:
			out.append(str(p.id))
	return out


## Delen die `level` oefent (poort of later).
static func parts_of_level(level: String) -> Array:
	var out: Array = []
	for p in all_parts():
		if (p.levels as Array).has(level):
			out.append(str(p.id))
	return out


## Check in de terugblik van `level`: 1–2 delen (de nieuwe delen van dat level, anders de delen die het oefent).
static func report_parts(level: String) -> Array:
	var ps := parts_for_level(level)
	if ps.is_empty():
		ps = parts_of_level(level)
	return ps.slice(0, 2)


## Lessen die vóór `level` nog moeten (eerste keer verplicht): elk deel met poort ≤ level waarvan Samen nog niet
## gedaan is → [{part, phase}] (Kijk dan Samen, in volgorde van het leerpad). De Codex: niets.
static func pending_for_level(level: String) -> Array:
	var out: Array = []
	var order := Array(ScLevels.ORDER)
	var li := order.find(level)
	if li < 0 or level == "C":
		return out
	for p in all_parts():
		var gi := order.find(str(p.levels[0]))
		if gi < 0 or gi > li or is_done(str(p.id), "samen"):
			continue
		if not is_done(str(p.id), "kijk"):
			out.append({"part": str(p.id), "phase": "kijk"})
		out.append({"part": str(p.id), "phase": "samen"})
	return out


# ======================================================================
#  voortgang (ScSave setting "learning"; nosave: enkel in het geheugen)
# ======================================================================

static func _nosave() -> bool:
	return ScSession.has("nosave")


static func _all_progress() -> Dictionary:
	if _nosave():
		return _mem
	var d = ScSave.setting(SAVE_KEY, {})
	return d if d is Dictionary else {}


static func progress(id: String) -> Dictionary:
	var d: Dictionary = _all_progress().get(id, {})
	return d


static func mark(id: String, key: String, value := true) -> void:
	var all := _all_progress().duplicate(true)
	var d: Dictionary = all.get(id, {})
	d[key] = value
	all[id] = d
	if _nosave():
		_mem = all
	else:
		ScSave.set_setting(SAVE_KEY, all)


static func reset_progress() -> void:
	_mem = {}
	if not _nosave():
		ScSave.set_setting(SAVE_KEY, {})


static func is_done(id: String, phase: String) -> bool:
	return bool(progress(id).get(phase, false))


## 0 = nog niets, 1 = demo bekeken, 2 = samen geoefend, 3 = begrepen (samen + check juist).
static func level(id: String) -> int:
	var p := progress(id)
	if bool(p.get("samen", false)) and bool(p.get("check", false)):
		return 3
	if bool(p.get("samen", false)):
		return 2
	if bool(p.get("kijk", false)):
		return 1
	return 0


# ======================================================================
#  specs
# ======================================================================

static func spec(id: String, phase: String) -> ScLevelSpec:
	var P_ := part(id)
	if P_.is_empty():
		return null
	var c: Dictionary = P_.get(phase, {})
	var s := ScLevelSpec.new()
	s.id = "LES:%s:%s" % [id, phase]
	s.chapter = ScLevels.chapter_of(str(P_.levels[0]))
	s.title = str(P_.title)
	s.notes_ref = str(P_.page)
	s.intro = ""
	s.priority = "P0"
	for st in c.get("stages", []):
		s.stages.append((st as Dictionary).duplicate(true))
	s.stars = []
	s.story = {"house": ScLevels.HOUSES[clampi(s.chapter, 0, 7)], "chapter_name": ScLevels.CHAPTERS[clampi(s.chapter, 0, 7)],
		"lesson": true, "zeno_intro": ""}
	s.optimum = ScLevels.optimum(s)
	return s


## Director zoals de les start (tests).
static func make_director(id: String, phase: String) -> ScDirector:
	var d := ScDirector.new()
	d.start(spec(id, phase))
	return d


# ======================================================================
#  tekst-hulpjes
# ======================================================================

## Haken ontsnappen ([lb]) en tekens die Fredoka mist in het monolettertype zetten (ScGuide.safe).
static func bb(s: String) -> String:
	var re := RegEx.create_from_string("\\[(?!/?(b|i|code|color|font_size|lb|rb)[\\]=])")
	return ScGuide.safe(re.sub(s, "[lb]", true))


static func code(s) -> String:
	return "[code]%s[/code]" % ScCodes.show_text(str(s)).replace("[", "[lb]")


static func ch(s) -> String:
	return "[b]%s[/b]" % ScCodes.show_text(str(s))


static func d(x: ScDec) -> String:
	return x.to_string_sig()


static func iv(lo: ScDec, hi: ScDec) -> String:
	return "[lb]%s; %s)" % [d(lo), d(hi)]


static func _join(a: Array, sep := " ") -> String:
	var out := PackedStringArray()
	for x in a:
		out.append(str(x))
	return sep.join(out)


static func triple(tr: Array) -> String:
	return "(%d, %d, %s)" % [int(tr[0]), int(tr[1]), ScCodes.show_text(str(tr[2]))]


static func lab(tr: ScTree, x: int) -> String:
	if x < 0:
		return "?"
	var s := tr.sym(x)
	if s == ScCodes.NNG:
		return "nng[%d,%d]" % [tr.w(x), tr.num(x)]
	return "%s[%d,%d]" % [ScCodes.show_text(s), tr.w(x), tr.num(x)]


static func list_txt(l: Array) -> String:
	var out := PackedStringArray()
	for x in l:
		out.append(ScCodes.show_text(str(x)))
	return "(" + ",".join(out) + ")"


static func hole(h: String) -> String:
	return "ε" if h == "" else h


static func toks_txt(toks: Array) -> String:
	var s := ""
	for tk in toks:
		if (tk as Dictionary).has("raw"):
			s += "\"%s\"" % str(tk.raw)
		else:
			s += str(tk.get("b", ""))
	return s


# ======================================================================
#  proefkopie
# ======================================================================

## Proefkopie van een werktuig (zelfde stage, carry en toestand; eigen log).
static func copy(t: ScTool) -> ScTool:
	var c := ScLevels.make_tool(t.stage, t.carry_in)
	c.stage_index = t.stage_index
	c.restore(t.snapshot())
	return c


## Speelt mv op een kopie: {t: kopie na de zet, r: resultaat, entries: logregels van deze zet, e: de zet zelf}.
static func trial(t: ScTool, mv: Dictionary) -> Dictionary:
	var c := copy(t)
	var n0 := c.log.size()
	var r := c.apply(mv)
	var ents: Array = c.log.entries.slice(n0)
	var main := {}
	for e in ents:
		if not bool(e.auto) and str(e.type) != "STAGE_END":
			main = e
			break
	return {"t": c, "r": r, "entries": ents, "e": main}


## Sleutel voor tellen (voorspelvragen, afbouwende tips).
static func act_key(t: ScTool, mv: Dictionary) -> String:
	var a := str(mv.get("act", ""))
	if t is ScLivingTree and (a == "swap" or a == "keep"):
		return "climb"
	if t is ScWindow:
		if t.side == ScCodes.Side.RECEIVE:
			return "copy"
		if a == "start" or a == "literal":
			return "triple"
	if t is ScStampCase and (a == "extend" or a == "stamp"):
		return "decide"
	return a


# ======================================================================
#  toestand zoals op het examen
# ======================================================================

static func state(t: ScTool) -> String:
	if t == null:
		return ""
	if t is ScPrefixReader:
		var pr := t as ScPrefixReader
		return "gelezen: %s · rest: %s" % [ch(pr.copy_text) if pr.copy_text != "" else "–", code(pr.rest()) if pr.rest() != "" else "–"]
	if t is ScCodeBoard:
		var cb := t as ScCodeBoard
		if cb.mode == "cuts":
			var segs := PackedStringArray()
			var a := 0
			for c in cb.cuts:
				segs.append(cb.bits.substr(a, c - a))
				a = c
			var cur := "|".join(segs) + ("|" if not segs.is_empty() else "") + cb.bits.substr(a)
			return "code e = 0, n = 1, b = 10 · strook %s\nlezingen: %s" % [code(cur),
				", ".join(cb.readings) if not cb.readings.is_empty() else "–"]
		var pl := PackedStringArray()
		for s in cb.symbols():
			pl.append("%s = %s" % [s, code(cb.placed[s]) if cb.placed.has(s) else "?"])
		var fq := PackedStringArray()
		for f in cb.freqs:
			fq.append("a(%s) = %d" % [f[0], int(f[1])])
		return "code: %s\n%s" % [", ".join(pl), ", ".join(fq)]
	if t is ScDovecote:
		var dc := t as ScDovecote
		var free := 0
		for h in dc.short_holes:
			if not dc._taken(h):
				free += 1
		return "duiven (berichten van %d bits): %d · kortere hokken: %d (vrij: %d)" % [dc.bits, dc.pigeons.size(),
			dc.short_holes.size(), free]
	if t is ScBindery:
		var bd := t as ScBindery
		if bd.mode == "shelves":
			return "plank A: %s\nplank B: %s · touw %d" % [_items_txt(bd, bd.shelf_a), _items_txt(bd, bd.shelf_b), int(bd.counters.twine)]
		return "rij: %s · touw %d" % [_items_txt(bd, bd.row), int(bd.counters.twine)]
	if t is ScLivingTree:
		var lt := t as ScLivingTree
		var s := "boom: [code]%s[/code]" % lt.tree.show().replace("*", "").replace("[", "[lb]")
		if lt.t >= 0:
			s += "\nt = %s" % lab(lt.tree, lt.t)
		if lt.side == ScCodes.Side.SEND:
			s += " · uitvoer: %s" % code(toks_txt(lt.tokens_out)) if not lt.tokens_out.is_empty() else ""
		else:
			s += " · gelezen: %s" % ch(lt.copy_text)
		return s
	if t is ScRuler:
		var ru := t as ScRuler
		var s2 := "interval %s · lengte %s" % [iv(ru.low, ru.up()), d(ru.lengte)]
		if ru.phase == P.NEEDLE or ru.bits != "":
			s2 += "\ngetal %s · next %s · bits %s" % [d(ru.getal), d(ru.nxt), code(ru.bits) if ru.bits != "" else "–"]
		if ru.side == ScCodes.Side.RECEIVE:
			s2 += "\nspeld r = %s · gelezen: %s" % [d(ru.pin), ch(ru.copy_text) if ru.copy_text != "" else "–"]
		return s2
	if t is ScWindow:
		var wi := t as ScWindow
		var trs := PackedStringArray()
		for tr in wi.triples:
			trs.append(triple(tr))
		if wi.side == ScCodes.Side.SEND:
			return "k = %d · raam%s: %s\ndrietallen: %s" % [wi.k, " (G = %d)" % wi.G if wi.G > 0 else " (G = ∞)",
				code(wi.window()) if wi.window() != "" else "–", " ".join(trs) if not trs.is_empty() else "–"]
		var nxt := triple(wi.triples[wi.idx]) if wi.idx < wi.triples.size() else "–"
		return "geschreven: %s · raam (G = %d): %s\nvolgend zegel: %s" % [code(wi.written), wi.G, code(wi.window()), nxt]
	if t is ScStampCase:
		var sc := t as ScStampCase
		var en := PackedStringArray()
		for e in sc.entries:
			en.append("%d = %s" % [int(e[0]), ScCodes.show_text(str(e[1]))])
		var dict := ", ".join(en.slice(maxi(0, en.size() - 6))) if not en.is_empty() else "–"
		if sc.side == ScCodes.Side.SEND:
			return "w = %s · k = %s · uitvoer: %s\nnieuw: %s" % [code(sc.w), code(sc._k()) if sc._k() != "" else "–",
				_join(sc.out) if not sc.out.is_empty() else "–", dict]
		return "w = %s · gelezen: %s\nnieuw: %s" % [code(sc.w), code(sc.copy_text), dict]
	if t is ScDrum:
		var dr := t as ScDrum
		if dr.side == ScCodes.Side.SEND:
			var rows := PackedStringArray()
			for r in dr.rows():
				rows.append(ScCodes.show_text(r))
			var s3 := "rek: %s" % code(" / ".join(rows))
			if dr.phase == P.INSERT:
				s3 += "\nnieuwe strook: %s" % code(dr.rot(dr.pending))
			return s3
		return "c = %s · e = %s\nx = %s (rang %d) · gelezen: %s" % [code(dr.c), code(dr.e), ch(dr.x_ch), dr.x_rank, code(dr.copy_text)]
	if t is ScShelf:
		var sh := t as ScShelf
		if sh.side == ScCodes.Side.SEND:
			return "lijst: %s\nuitvoer: %s" % [code(list_txt(sh.list)), _join(sh.out) if not sh.out.is_empty() else "–"]
		return "lijst: %s\ngelezen: %s" % [code(list_txt(sh.list)), code(sh.copy_text) if sh.copy_text != "" else "–"]
	return ""


static func _items_txt(bd: ScBindery, ids_: Array) -> String:
	var out := PackedStringArray()
	for x in ids_:
		out.append("%s %d" % [ScCodes.show_text(bd.label(x)), bd.tree.w(x)])
	return " · ".join(out) if not out.is_empty() else "–"


# ======================================================================
#  verteltekst: wat + waarom (+ wat er daarna vanzelf gebeurde)
# ======================================================================

## Kijk: de zetten die samen één vertelde stap vormen ([{mv, t}], t = kopie vlak vóór die zet).
## Codebord-knippen: alle knippen van één lezing; register: de zoektocht + het drietal.
## Wat het werktuig al vanzelf deed vóór de eerste zet (adaptieve Huffman: het eerste teken van een lege boom).
static func start_note(t: ScTool) -> String:
	if t is ScLivingTree:
		var lt := t as ScLivingTree
		if lt.start == "empty" and lt.i == 1:
			var snd := lt.side == ScCodes.Side.SEND
			var src: String = lt.text if snd else lt.copy()
			if src == "":
				return ""
			var c0 := ScCodes.show_text(src[0])
			return ("[color=%s]Vanzelf: in de lege boom is nng de wortel (een leeg codewoord). Het eerste teken %s dus ruw, zonder bits ervoor: [b]\"%s\"[/b]. nng groeit tot een ouder [lb]1,3] met nng [lb]0,1] en [b]%s[/b] [lb]1,2].[/color]"
				% [C_DIM, "gaat" if snd else "staat", c0, c0])
	return ""


static func kijk_group(t: ScTool) -> Array:
	var out: Array = []
	var c := copy(t)
	var guard := 0
	while guard < 40:
		guard += 1
		var mv := c.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		out.append({"mv": mv, "t": copy(c)})
		var tr := trial(c, mv)
		c = tr.t
		var a := str(mv.act)
		if c.is_done():
			break
		if t is ScCodeBoard and a == "cut" and not (tr.e as Dictionary).get("data", {}).has("reading"):
			continue
		if t is ScWindow and a == "register":
			continue
		break
	return out


static func narrate_group(group: Array) -> Dictionary:
	if group.size() == 1:
		return narrate(group[0].t, group[0].mv)
	var t0: ScTool = group[0].t
	if t0 is ScCodeBoard:
		var last: Dictionary = group[group.size() - 1]
		var tr := trial(last.t, last.mv)
		var cb := tr.t as ScCodeBoard
		var segs := PackedStringArray()
		var a := 0
		var lets := PackedStringArray()
		var inv := ScReference.inverse(cb.code)
		var all_cuts: Array = (last.t as ScCodeBoard).cuts.duplicate()
		all_cuts.append(int(last.mv.at))
		for c in all_cuts:
			var w := cb.bits.substr(a, int(c) - a)
			segs.append(w)
			lets.append(str(inv.get(w, "?")))
			a = int(c)
		var rd := str((tr.e as Dictionary).get("data", {}).get("reading", "".join(lets)))
		return {"what": "Lezing %d: %s = %s" % [cb.readings.size(), code("|".join(segs)), ch(rd)],
			"why": "Knip telkens na een stuk dat een codewoord is (%s). Ook een andere knip kon: 1 (n) is het begin van 10 (b)." % ", ".join(_word_list(cb.code)),
			"after": ""}
	# register + drietal
	var n1 := narrate(group[0].t, group[0].mv)
	var n2 := narrate(group[1].t, group[1].mv)
	return {"what": "%s %s" % [n1.what, n2.what], "why": "%s %s" % [n1.why, n2.why], "after": str(n2.get("after", ""))}


static func _word_list(cd: Dictionary) -> Array:
	var out: Array = []
	for k in cd:
		out.append("%s = %s" % [k, cd[k]])
	return out


static func narrate(t: ScTool, mv: Dictionary) -> Dictionary:
	var tr := trial(t, mv)
	var t2: ScTool = tr.t
	var e: Dictionary = tr.e
	var dd: Dictionary = e.get("data", {})
	var out := {"what": "", "why": "", "after": ""}
	var a := str(mv.get("act", ""))
	if t is ScPrefixReader:
		var pr := t as ScPrefixReader
		var id := int(mv.leaf)
		out.what = "Bits %s → blad %s: schrijf %s." % [code(pr.tree.code(id)), ch(pr.tree.sym(id)), ch(pr.tree.sym(id))]
		out.why = "0 = links, 1 = rechts. Bij een blad stop je: geen codewoord gaat verder, dus de letter is af."
		if t2.is_done():
			out.after = "Strook op: gelezen [b]%s[/b]." % (t2 as ScPrefixReader).copy_text
	elif t is ScCodeBoard:
		var cb := t as ScCodeBoard
		match a:
			"cut":
				out.what = "Knip na %s: dat is het codewoord van %s." % [code(dd.get("word", "")), ch(ScReference.inverse(cb.code).get(str(dd.get("word", "")), "?"))]
				out.why = "Je mag enkel een stuk afknippen dat een codewoord is."
			"reset":
				out.what = "Opnieuw lezen: zoek een andere lezing van dezelfde strook."
				out.why = "Geen prefixcode: 1 (n) is het begin van 10 (b). De lezer weet dan niet waar de letter stopt."
			"done":
				out.what = "Klaar: %d lezingen (%s) voor één strook." % [cb.readings.size(), ", ".join(cb.readings)]
				out.why = "Definitie 20: in een prefixcode is geen codewoord het begin van een ander; dan is er maar één lezing."
			"place":
				out.what = "Hang %s aan knoop %s: codewoord %s." % [ch(mv.sym), code(mv.path), code(mv.path)]
				out.why = "Enkel aan een blad: geen ander codewoord begint met %s, en %s begint met geen ander." % [code(mv.path), code(mv.path)]
			"remove":
				out.what = "Haal %s weg." % ch(mv.sym)
				out.why = "Op die plaats hoort een andere letter."
			"send":
				var cb2 := t2 as ScCodeBoard
				out.what = "Verzend: %s." % ", ".join(_word_list(cb.placed))
				out.why = "Een prefixcode, en kort: %s = Σ a(x)·l(x) = %d bits." % [ch(cb.text), int(dd.get("ink", ScReference.code_cost(cb.placed, cb.freqs)))]
				if cb2 != null and int(e.get("verdict", V.OK)) != V.OK:
					out.why = ScEventLog.new().coach_line(e)
	elif t is ScDovecote:
		var dc := t as ScDovecote
		if a == "roost":
			var h := str(mv.hole)
			if h.length() > dc.bits:
				out.what = "Duif %s: alle %d kortere hokken zijn bezet → zolder %s (%d bits)." % [code(dc.pigeons[int(mv.pigeon)]),
					dc.short_holes.size(), code(h), h.length()]
				out.why = "%d berichten, maar maar %d bitstrings korter dan %d bits: één bericht wordt niet korter." % [dc.pigeons.size(),
					dc.short_holes.size(), dc.bits]
			else:
				out.what = "Duif %s → hok %s (%d %s)." % [code(dc.pigeons[int(mv.pigeon)]), code(hole(h)), h.length(), "bit" if h.length() == 1 else "bits"]
				out.why = "Elke duif een eigen, korter hok: twee berichten mogen nooit hetzelfde resultaat krijgen."
		else:
			var which := int(mv.which)
			var txt := "Elk bericht van %d bits kan korter." % dc.bits if which == 1 else "Voor elk bericht bestaat een code die het korter maakt."
			var ans := {"impossible": "onmogelijk", "true": "waar", "false": "vals"}
			out.what = "Decreet %d \"%s\": %s." % [which, txt, ans.get(str(mv.answer), "?")]
			out.why = "Er zijn %d berichten en maar %d kortere bitstrings." % [dc.pigeons.size(), dc.short_holes.size()] if which == 1 \
				else "Voor één bericht apart lukt het wel: geef het een kort codewoord (een ander bericht wordt dan langer)."
	elif t is ScBindery:
		var bd := t as ScBindery
		var x := str(dd.get("x", "?"))
		var y := str(dd.get("y", "?"))
		var w := int(dd.get("v1", 0)) + int(dd.get("v2", 0))
		if bd.mode == "shelves":
			out.what = "Neem vooraan plank %s: %s (%d) en vooraan plank %s: %s (%d) → bundel %d achteraan plank B." % [str(mv.a), ch(x),
				int(dd.v1), str(mv.b), ch(y), int(dd.v2), w]
			out.why = "Vooraan staat telkens het lichtste van elke plank. Bij gelijk gewicht is elke keuze goed (Zeno neemt dan B)."
		else:
			out.what = "Bind %s (%d) en %s (%d) → bundel met gewicht %d. Touw: %d." % [ch(x), int(dd.v1), ch(y), int(dd.v2), w,
				int(t2.counters.twine)]
			out.why = "De twee lichtste wegen nu %d en %d (Algoritme 9)." % [int(dd.w1), int(dd.w2)]
			var n_ok := 0
			for i in bd.row.size():
				for j in range(i + 1, bd.row.size()):
					var ws: Array = []
					for q in bd.row:
						ws.append(bd.tree.w(q))
					if ScReference.is_valid_pair(ws, i, j):
						n_ok += 1
			if n_ok > 1:
				out.why += " Bij gelijk gewicht is elke keuze even goed."
		if t2.is_done():
			var bd2 := t2 as ScBindery
			out.after = "Eén boom: %s. Touw %d = Σ a(x)·l(x) = %d bits." % [", ".join(_word_list(bd2.codes)), int(bd2.counters.twine),
				int(bd2.counters.twine)]
	elif t is ScLivingTree:
		_n_living(t as ScLivingTree, t2 as ScLivingTree, mv, dd, out)
	elif t is ScRuler:
		_n_ruler(t as ScRuler, t2 as ScRuler, mv, out)
	elif t is ScWindow:
		_n_window(t as ScWindow, t2 as ScWindow, mv, dd, out)
	elif t is ScStampCase:
		_n_stamp(t as ScStampCase, t2 as ScStampCase, mv, tr.entries, out)
	elif t is ScDrum:
		_n_drum(t as ScDrum, t2 as ScDrum, mv, out)
	elif t is ScShelf:
		var sh := t as ScShelf
		if sh.side == ScCodes.Side.SEND:
			var xx := sh.input[sh.i]
			out.what = "%s staat op plaats %d van de lijst: schrijf %d en zet %s vooraan." % [ch(xx), int(mv.k), int(mv.k), ch(xx)]
			out.why = "Tel vanaf 0, in de lijst zoals ze nu is: %s." % code(list_txt(sh.list))
		else:
			var y2 := str(sh.list[int(mv.k)])
			out.what = "Getal %d: plaats %d van de lijst is %s. Schrijf %s en zet het vooraan." % [int(mv.k), int(mv.k), ch(y2), ch(y2)]
			out.why = "Ontvanger en afzender houden dezelfde lijst bij: %s." % code(list_txt(sh.list))
	return out


static func _n_living(lt: ScLivingTree, l2: ScLivingTree, mv: Dictionary, dd: Dictionary, out: Dictionary) -> void:
	var tr := lt.tree
	match str(mv.act):
		"write":
			var id := int(mv.leaf)
			if id == tr.nng:
				out.what = "Nieuw teken %s: schrijf code(nng) = %s en dan %s ruw (8 bits)." % [ch(lt.ch), code(tr.code(id)), ch(lt.ch)]
				out.why = "Een teken dat nog niet gezien is, staat niet in de boom: de nng-top meldt het aan."
			else:
				out.what = "Schrijf %s met de boom van nu: %s." % [ch(lt.ch), code(tr.code(id))]
				out.why = "Eerst schrijven met de oude boom, dan pas bijwerken: zo kan de ontvanger het volgen."
		"read":
			var id2 := int(mv.leaf)
			if id2 == tr.nng:
				out.what = "Bits %s → nng: de letter erna staat ruw: %s." % [code(tr.code(id2)) if tr.code(id2) != "" else "(geen)", ch(l2.ch)]
				out.why = "nng betekent: een nieuw teken volgt, letterlijk."
			else:
				out.what = "Bits %s → blad %s: lees %s." % [code(tr.code(id2)), ch(tr.sym(id2)), ch(tr.sym(id2))]
				out.why = "Lees tot een blad, zoals bij elke prefixcode."
		"swap":
			var w := int(mv.with)
			out.what = "t = %s: t′ = %s (gewicht %d, hoogste nummer). Wissel; dan a(t) + 1 en naar de ouder." % [lab(tr, lt.t), lab(tr, w), tr.w(lt.t)]
			out.why = "Zo blijft het gewicht stijgen met het nummer (b): de verste top met hetzelfde gewicht krijgt de +1."
		"keep":
			var ts := lt._tstar()
			if ts == tr.parent(lt.t) and ts != lt.t:
				out.what = "t = %s: t′ = %s is de ouder van t. Niet wisselen; a(t) + 1 en naar de ouder." % [lab(tr, lt.t), lab(tr, ts)]
				out.why = "Het speciale geval (p. 95): je kan een top niet vervangen door een boom waar hij zelf in zit."
			else:
				out.what = "t = %s: geen top met gewicht %d en een hoger nummer. Niet wisselen; a(t) + 1 en naar de ouder." % [lab(tr, lt.t), tr.w(lt.t)]
				out.why = "t′ is t zelf: (b) blijft waar als t één hoger wordt."
	# wat er daarna vanzelf gebeurde
	var notes := PackedStringArray()
	if str(mv.act) == "write" or str(mv.act) == "read":
		if l2.tree.size() > tr.size():
			notes.append("Vanzelf: nng groeit tot een ouder met nng [lb]0,1] en %s [lb]1,2]; de andere nummers +2." % ch(lt.ch if str(mv.act) == "write" else l2.ch))
	if l2.t >= 0 and l2.phase == P.CLIMB:
		notes.append("Nu t = %s." % lab(l2.tree, l2.t))
	elif l2.t < 0:
		notes.append("De wortel krijgt +1: klaar met dit teken.")
		if l2.phase == P.WRITE and l2.side == ScCodes.Side.SEND:
			notes.append("Volgend teken: %s." % ch(l2.ch))
	out.after = " ".join(notes)


static func _n_ruler(ru: ScRuler, r2: ScRuler, mv: Dictionary, out: Dictionary) -> void:
	if str(mv.act) == "cut":
		var sym := str(mv.sym)
		if ru.side == ScCodes.Side.SEND:
			var f := ScDec.zero()
			var p := ScDec.zero()
			for m in ScReference.parse_model(ru.model):
				if str(m.sym) == sym:
					f = m.f
					p = m.p
			out.what = "Knip het vak van %s: links = %s + %s·%s = %s; lengte = %s·%s = %s → %s." % [ch(sym), d(ru.low), d(f),
				d(ru.lengte), d(r2.low), d(ru.lengte), d(p), d(r2.lengte), iv(r2.low, r2.up())]
			out.why = "Algoritme 12: f(%s) = %s is het begin van het vak van %s, p(%s) = %s zijn breedte." % [sym, d(f), sym, sym, d(p)]
			if r2.phase == P.NEEDLE:
				out.after = "Alle tekens geknipt: nu de kortste bitstring in %s." % iv(r2.low, r2.up())
			elif r2.is_done() and r2.bits == "0":
				out.after = "low = 0: de bitstring is meteen 0."
		else:
			var sg := ru._seg(sym)
			out.what = "De speld r = %s zit in het vak van %s: %s. Lees %s en zoom in." % [d(ru.pin), ch(sym), iv(sg.lo, sg.hi), ch(sym)]
			out.why = "Onderrand dicht, bovenrand open: [lb]a, b) bevat a wel en b niet."
			if ru.pin.eq(sg.lo):
				out.why += " Hier ligt r precies op de onderrand %s: die hoort bij %s." % [d(sg.lo), ch(sym)]
			if r2.is_done():
				out.after = "%d tekens gelezen: %s." % [ru.n, ch(r2.copy_text)]
	else:
		var b := int(mv.b)
		var s := ru.getal.add(ru.nxt)
		if b == 1:
			out.what = "getal + next = %s + %s = %s < up = %s → bit 1 (stap): getal = %s." % [d(ru.getal), d(ru.nxt), d(s), d(ru.up()), d(s)]
			if r2.is_done():
				out.what += " %s ≥ low = %s: klaar, bits %s." % [d(s), d(ru.low), code(r2.bits)]
		else:
			out.what = "getal + next = %s + %s = %s ≥ up = %s → bit 0 (blijf)." % [d(ru.getal), d(ru.nxt), d(s), d(ru.up())]
		out.why = "Algoritme 13: een 1 enkel als je onder up blijft; daarna halveert next."


static func _n_window(wi: ScWindow, w2: ScWindow, mv: Dictionary, dd: Dictionary, out: Dictionary) -> void:
	var a := str(mv.act)
	if wi.side == ScCodes.Side.RECEIVE:
		var tr: Array = wi.triples[wi.idx]
		var p := int(mv.p)
		var l := int(tr[1])
		var letters := w2.written.substr(wi.written.length(), l)
		out.what = "Zegel %s: kopieer %d %s vanaf positie %d van het raam %s: %s%s." % [triple(tr), l, "letter" if l == 1 else "letters",
			p, code(wi.window()), code(letters), (", dan %s" % ch(tr[2])) if str(tr[2]) != ScCodes.EOF else " (EOF: klaar)"]
		out.why = "Tel vanaf de linkerrand van het raam, de eerste is 0. Kopieer letter per letter."
		var auto := w2.idx - wi.idx - 1
		if auto > 0:
			out.after = "Vanzelf: %d %s met l = 0 (enkel de letter)." % [auto, "zegel" if auto == 1 else "zegels"]
		return
	if a == "register":
		var wk := ScRegister.walk(wi.text, wi.k, wi.ws())
		out.what = "Register: de langste match hier is %d %s lang%s." % [int(wk.l), "letter" if int(wk.l) == 1 else "letters",
			(" (positie %d)" % int(wk.p)) if int(wk.l) > 0 else ""]
		out.why = "De deelstringboom van de tekst tot nu: per letter één blik of er een tak verdergaat."
		return
	var trp: Array = dd.get("triple", [])
	if trp.is_empty():
		trp = (w2.triples[w2.triples.size() - 1] as Array) if not w2.triples.is_empty() else [0, 0, "?"]
	var gtxt := ("de laatste G = %d tekens" % wi.G) if wi.G > 0 else "alles tot nu (G = ∞)"
	if a == "literal":
		out.what = "%s staat niet in het raam %s: geen match → %s." % [ch(wi.text[wi.k]), code(wi.window()) if wi.window() != "" else "(leeg)", triple(trp)]
		out.why = "Het raam = %s. Zonder match schrijf je (0, 0, x) en ga je 1 verder." % gtxt
	else:
		var l2 := int(trp[1])
		var src := wi.ws() + int(trp[0])
		out.what = "Langste match %s begint op positie %d van het raam %s (lengte %d) → %s." % [code(wi.text.substr(wi.k, l2)), int(trp[0]),
			code(wi.window()), l2, triple(trp)]
		out.why = "Het raam = %s, posities vanaf 0 links. x = het teken na de match%s." % [gtxt, " (de tekst is op: EOF)" if str(trp[2]) == ScCodes.EOF else ""]
		if src + l2 > wi.k:
			out.why += " De match loopt voorbij het raam: dat mag, ze moet er enkel in beginnen."
	if not w2.is_done():
		out.after = "Verder op positie k = %d." % w2.k


static func _n_stamp(sc: ScStampCase, s2: ScStampCase, mv: Dictionary, ents: Array, out: Dictionary) -> void:
	var a := str(mv.act)
	if sc.side == ScCodes.Side.SEND:
		var wk := sc.w + sc._k()
		if a == "extend":
			out.what = "w + k = %s zit in de kast: verleng, w = %s." % [code(wk), code(wk)]
			out.why = "Zolang het woord met het volgende teken in het woordenboek zit, maak je w langer."
		else:
			out.what = "w + k = %s zit niet in de kast: stempel code(%s) = %d; %s krijgt lade %d; w = %s." % [code(wk), ScCodes.show_text(sc.w),
				sc.code_of(sc.w), code(wk), sc.next_code, code(sc._k())]
			out.why = "Het langste woord dat in de kast zit, is w: schrijf zijn code en voeg wk toe."
		if s2.is_done():
			out.after = "Einde van de tekst: stempel nog code(%s) = %d. Uitvoer: %s." % [ScCodes.show_text(s2.w), s2.code_of(s2.w), _join(s2.out)]
		return
	var c := sc.codes_in[sc.cpos]
	if sc.special:
		var vv := sc.w + sc.w[0]
		out.what = "Code %d is nog leeg (de lade die je nu snijdt): het woord is w + w[lb]0] = %s + %s = %s; lade %d = %s." % [c,
			code(sc.w), code(sc.w[0]), code(vv), sc.next_code, code(vv)]
		out.why = "De afzender gebruikte het woord meteen na het toevoegen: het begint met dezelfde letter als w."
	else:
		out.what = "Code %d = %s. Nieuwe lade %d = w + eerste letter = %s + %s = %s; w = %s." % [c, code(sc.volgend), sc.next_code,
			code(sc.w), code(sc.volgend[0]), code(sc.w + sc.volgend[0]), code(sc.volgend)]
		out.why = "Na elke code voeg je het vorige woord + de eerste letter van het nieuwe woord toe, net als de afzender."
	var autos := PackedStringArray()
	for e in ents:
		if bool(e.auto) and str(e.type) == "CARVE":
			autos.append("%d = %s" % [int(e.data.code), ScCodes.show_text(str(e.data.word))])
	if not autos.is_empty():
		out.after = "Vanzelf (codes van één letter): %s." % ", ".join(autos)


static func _n_drum(dr: ScDrum, d2: ScDrum, mv: Dictionary, out: Dictionary) -> void:
	match str(mv.act):
		"insert":
			var g := int(mv.gap)
			var rows := dr.rows()
			var s := dr.rot(dr.pending)
			var where := ""
			if rows.is_empty():
				where = "in het lege rek"
			elif g == 0:
				where = "bovenaan, vóór %s" % code(rows[0])
			elif g >= rows.size():
				where = "onderaan, na %s" % code(rows[rows.size() - 1])
			else:
				where = "tussen %s en %s" % [code(rows[g - 1]), code(rows[g])]
			out.what = "Strook %s (rotatie %d) komt %s." % [code(s), dr.pending, where]
			out.why = "Het rek blijft gesorteerd: vergelijk letter per letter; de spatie is het kleinst."
			if d2.phase == P.MARK:
				out.after = "Alle %d rotaties staan gesorteerd. Nu p." % dr.n
		"mark":
			var r := int(mv.row)
			out.what = "Rij %d (%s) eindigt op %s = s[lb]0]: p = %d. Uitvoer (%d, %s)." % [r, code(dr.rot(dr.rack[r])), ch(dr.s[0]), r, r,
				code(d2.c_out)]
			out.why = "Die rij is de rotatie die één letter verder begint: zo vind je het begin terug. De rest = de laatste kolom."
		"find":
			var i := int(mv.i)
			out.what = "x = %s is de %de %s in e. De %de %s in c staat op rij %d; e[lb]%d] = %s." % [ch(dr.x_ch), dr.x_rank, ScCodes.show_text(dr.x_ch),
				dr.x_rank, ScCodes.show_text(dr.x_ch), i, i, ch(dr.e[i])]
			out.why = "Na c[lb]i] komt in de tekst e[lb]i]; gelijke letters koppel je in volgorde."
			if d2.is_done():
				out.after = "De kring is rond: %s." % ch(d2.copy_text)
			else:
				out.after = "Gelezen: %s." % code(d2.copy_text)


# ======================================================================
#  Samen: tips, aanvaarden, foutuitleg
# ======================================================================

static func tip(t: ScTool, mv: Dictionary) -> String:
	var n := narrate(t, mv)
	var a := str(mv.get("act", ""))
	var how := ""
	if t is ScPrefixReader:
		how = "Volg de bits van de rest in de boom en klik het blad waar je uitkomt."
	elif t is ScCodeBoard:
		how = "Sleep (of klik) een lettertegel op een knoop: het pad is het codewoord. Een letter enkel aan een blad: geen tegel onder een andere." if a == "place" else "Klik \"Verzenden\" als alle letters hangen."
	elif t is ScDovecote:
		how = "Klik een duif en dan een hok dat korter is (zolang er een vrij is)." if a == "roost" else "Klik je antwoord op het decreet."
	elif t is ScBindery:
		how = "Klik de twee lichtste stapels." if (t as ScBindery).mode == "row" else "Neem 2 keer het lichtste dat vooraan een plank staat: klik die stapels."
	elif t is ScLivingTree:
		match a:
			"write":
				how = "Klik het blad van het teken (of het zaadje nng voor een nieuw teken)."
			"read":
				how = "Volg de bits en klik het blad waar je uitkomt."
			_:
				how = "Zoek t′: hetzelfde gewicht als t, het hoogste nummer. Klik t′ om te wisselen, of \"Blijf staan\" (B) als t′ = t of de ouder is."
	elif t is ScRuler:
		how = "Klik het vak van de letter." if a == "cut" else "Bereken getal + next en vergelijk met up: knop 1 (stap) of 0 (blijf)."
	elif t is ScWindow:
		if t.side == ScCodes.Side.RECEIVE:
			how = "Klik positie p van het zegel in het raam (tel vanaf 0)."
		elif a == "register":
			how = "Klik \"Register\" (R): het register zoekt de langste match."
		elif a == "literal":
			how = "Geen match in het raam: klik \"Geen match\" (G)."
		else:
			how = "Klik de letter in het raam waar de langste match begint."
	elif t is ScStampCase:
		how = "Zit w + k in de kast? Dan Verleng (V), anders Stempel (S)." if t.side == ScCodes.Side.SEND else "Snij de nieuwe stempel: klik de letter (w + de eerste letter van het nieuwe woord)."
	elif t is ScDrum:
		match a:
			"insert":
				how = "Klik de spleet waar de nieuwe strook in het gesorteerde rek past."
			"mark":
				how = "Klik de rij die eindigt op de eerste letter van de tekst."
			_:
				how = "Klik in kolom c dezelfde letter met dezelfde rang."
	elif t is ScShelf:
		how = "Klik de cijferstempels van de positie (of typ het getal + Enter)." if t.side == ScCodes.Side.SEND else "Klik het blokje op die positie (of typ het getal)."
	return "%s\n[color=%s]%s[/color]" % [how, C_DIM, n.what]


## Aanvaardt de les deze zet? Proefzet op een kopie: geldig en oordeel OK. Codebord: elke tegel moet een blad blijven.
static func accepts(t: ScTool, mv: Dictionary) -> Dictionary:
	var tr := trial(t, mv)
	var r: Dictionary = tr.r
	var ok := bool(r.ok) and int(r.verdict) == V.OK
	if ok and t is ScCodeBoard and str(mv.get("act", "")) == "place":
		ok = ScReference.is_prefix_code((tr.t as ScCodeBoard).placed)
	if ok and t is ScCodeBoard and str(mv.get("act", "")) == "remove":
		ok = true
	return {"ok": ok, "r": r, "e": tr.e, "t": tr.t}


static func explain_wrong(t: ScTool, mv: Dictionary, acc: Dictionary) -> String:
	var r: Dictionary = acc.r
	var a := str(mv.get("act", ""))
	if not bool(r.ok):
		var reason := str(r.get("reason", ""))
		var s := ScEventLog.bump_line(reason)
		if reason == "no_path" or reason == "not_leaf":
			s += " Volg de bits van de rest: 0 = links, 1 = rechts."
		elif reason == "out_of_window":
			s += " Tel enkel posities in het raam (vanaf 0 links)."
		elif reason == "no_match":
			s += " De match begint met de volgende letter %s." % ch((t as ScWindow).text[(t as ScWindow).k]) if t is ScWindow else ""
		elif reason == "no_stamp":
			s += " w + k zit niet in de kast: dan stempel je."
		elif reason == "letter":
			s += " x is %s." % ch((t as ScDrum).x_ch) if t is ScDrum else ""
		return s
	if t is ScCodeBoard and a == "place":
		var pl := (acc.t as ScCodeBoard).placed
		var pair := ScCodeBoard._prefix_pair(pl)
		return "%s is het begin van %s: de lezer weet niet waar de letter stopt. Hang letters enkel aan bladeren." % [code(pair[0]), code(pair[1])]
	var line := ScEventLog.new().coach_line(acc.e)
	if line == "":
		line = "Dat is niet de zet van het algoritme."
	return bb(line.replace("`", ""))


# ======================================================================
#  voorspelvragen (Check in de wereld)
# ======================================================================

## Korte omschrijving van een zet (knoptekst; geen BBCode).
static func describe(t: ScTool, mv: Dictionary) -> String:
	var tr := trial(t, mv)
	var e: Dictionary = tr.e
	var dd: Dictionary = e.get("data", {})
	var a := str(mv.get("act", ""))
	if t is ScPrefixReader:
		var pr := t as ScPrefixReader
		return "%s (%s)" % [pr.tree.sym(int(mv.leaf)), pr.tree.code(int(mv.leaf))]
	if t is ScBindery:
		if (t as ScBindery).mode == "shelves":
			return "plank %s en plank %s" % [str(mv.a), str(mv.b)]
		return "%s (%d) en %s (%d)" % [ScCodes.show_text(str(dd.get("x", "?"))), int(dd.get("v1", 0)), ScCodes.show_text(str(dd.get("y", "?"))), int(dd.get("v2", 0))]
	if t is ScLivingTree:
		var lt := t as ScLivingTree
		match a:
			"write", "read":
				var id := int(mv.leaf)
				if id == lt.tree.nng:
					return "nng: %s + de letter ruw" % (lt.tree.code(id) if lt.tree.code(id) != "" else "niets")
				return "blad %s: %s" % [ScCodes.show_text(lt.tree.sym(id)), lt.tree.code(id)]
			"swap":
				return "wissel met %s" % lab(lt.tree, int(mv.with))
			"keep":
				var ts := lt._tstar()
				return "niet wisselen (t′ is de ouder)" if ts == lt.tree.parent(lt.t) and ts != lt.t else "niet wisselen (t′ = t)"
	if t is ScRuler:
		if a == "bit":
			return "1 (stap)" if int(mv.b) == 1 else "0 (blijf)"
		return "vak %s" % str(mv.sym)
	if t is ScWindow:
		var wi := t as ScWindow
		if wi.side == ScCodes.Side.RECEIVE:
			var l := int(wi.triples[wi.idx][1])
			var w2 := tr.t as ScWindow
			if bool(tr.r.ok):
				return "%s (vanaf positie %d)" % [ScCodes.show_text(w2.written.substr(wi.written.length(), l)), int(mv.p)]
			return "positie %d" % int(mv.p)
		var trp: Array = dd.get("triple", [])
		return triple(trp) if not trp.is_empty() else a
	if t is ScStampCase:
		var sc := t as ScStampCase
		if sc.side == ScCodes.Side.SEND:
			return "verleng (w = %s)" % ScCodes.show_text(sc.w + sc._k()) if a == "extend" else "stempel %d" % sc.code_of(sc.w)
		var j := int(mv.get("i", 0))
		if sc.special:
			return "%d = %s" % [sc.codes_in[sc.cpos], ScCodes.show_text(sc.w + sc.w[j]) if j < sc.w.length() else "?"]
		return "%d = %s" % [sc.next_code, ScCodes.show_text(sc.w + sc.volgend[j]) if j < sc.volgend.length() else "?"]
	if t is ScDrum:
		var dr := t as ScDrum
		match a:
			"mark":
				return "rij %d (%s)" % [int(mv.row), ScCodes.show_text(dr.rot(dr.rack[int(mv.row)]))]
			"find":
				return "rij %d" % int(mv.i)
			"insert":
				return "spleet %d" % int(mv.gap)
	if t is ScShelf:
		var sh := t as ScShelf
		return str(int(mv.k)) if sh.side == ScCodes.Side.SEND else "%s (plaats %d)" % [ScCodes.show_text(str(sh.list[int(mv.k)])), int(mv.k)]
	if t is ScDovecote:
		return {"impossible": "onmogelijk", "true": "waar", "false": "vals"}.get(str(mv.get("answer", "")), a)
	if t is ScCodeBoard:
		return "knip na %s" % str(dd.get("word", "")) if a == "cut" else a
	return a


static func _q_text(t: ScTool, mv: Dictionary) -> String:
	var a := str(mv.get("act", ""))
	if t is ScPrefixReader:
		return "Rest %s: welke letter lees je nu?" % code((t as ScPrefixReader).rest())
	if t is ScBindery:
		return "Welke twee bind je nu?" if (t as ScBindery).mode == "row" else "Uit welke planken neem je de twee lichtste?"
	if t is ScLivingTree:
		var lt := t as ScLivingTree
		if a == "write":
			return "Wat schrijf je voor %s?" % ch(lt.ch)
		if a == "read":
			return "Rest van de strook begint met %s: welk blad?" % code(_stream_rest(lt))
		return "t = %s: met welke top wissel je?" % lab(lt.tree, lt.t)
	if t is ScRuler:
		if a == "bit":
			var ru := t as ScRuler
			return "getal = %s, next = %s, interval %s: welke bit?" % [d(ru.getal), d(ru.nxt), iv(ru.low, ru.up())]
		return "In welk vak zit de speld r = %s?" % d((t as ScRuler).pin)
	if t is ScWindow:
		return "Welke letters kopieer je voor zegel %s?" % triple((t as ScWindow).triples[(t as ScWindow).idx]) if t.side == ScCodes.Side.RECEIVE else "Welk drietal schrijf je nu?"
	if t is ScStampCase:
		var sc := t as ScStampCase
		return "w = %s, k = %s: verleng of stempel?" % [code(sc.w), code(sc._k())] if sc.side == ScCodes.Side.SEND else "Code %d: welke nieuwe lade snij je?" % sc.codes_in[sc.cpos]
	if t is ScDrum:
		var dr := t as ScDrum
		if a == "mark":
			return "Welke rij is p (de tekst begint met %s)?" % ch(dr.s[0])
		if a == "find":
			return "x = %s (rang %d in e): welke rij in c?" % [ch(dr.x_ch), dr.x_rank]
		return "Waar komt strook %s?" % code(dr.rot(dr.pending))
	if t is ScShelf:
		var sh := t as ScShelf
		return "Welk getal schrijf je voor %s?" % ch(sh.input[sh.i]) if sh.side == ScCodes.Side.SEND else "Getal %d: welke letter?" % sh.nums[sh.i]
	if t is ScDovecote:
		var which := int(mv.get("which", 1))
		return "Decreet %d: \"%s\"" % [which, "Elk bericht van %d bits kan korter." % (t as ScDovecote).bits if which == 1 else "Voor elk bericht bestaat een code die het korter maakt."]
	return "Wat is de volgende zet?"


static func _stream_rest(lt: ScLivingTree) -> String:
	var s := ""
	for q in range(lt.pos, mini(lt.stream.size(), lt.pos + 6)):
		s += str(lt.stream[q])
	return s


static func _num_q(q: String, right: int, cands: Array, why: String, lo := 0) -> Dictionary:
	var opts: Array = [right]
	for c in cands:
		if int(c) >= lo and not opts.has(int(c)) and opts.size() < 4:
			opts.append(int(c))
	var dd := 1
	while opts.size() < 4 and dd < 40:
		for c in [right + dd, right - dd]:
			if c >= lo and not opts.has(c) and opts.size() < 4:
				opts.append(c)
		dd += 1
	var so: Array = []
	for o in opts:
		so.append(str(o))
	return {"q": q, "options": so, "correct": [0], "right": why, "wrong": "Juist is [b]%d[/b]. %s" % [right, why]}


static func _str_q(q: String, right: String, cands: Array, why: String) -> Dictionary:
	var opts: Array = [right]
	for c in cands:
		if not opts.has(str(c)) and opts.size() < 4:
			opts.append(str(c))
	return {"q": q, "options": opts, "correct": [0], "right": why, "wrong": "Juist is [b]%s[/b]. %s" % [right, why]}


## Voorspelvraag vóór zet mv in toestand t. kind: "next" (welke zet?) of een getalvraag.
static func predict(t: ScTool, kind: String, mv: Dictionary) -> Dictionary:
	var n := narrate(t, mv)
	var why := "%s %s" % [n.what, n.why]
	match kind:
		"readings":
			var cb := t as ScCodeBoard
			return _num_q("Strook %s met e = 0, n = 1, b = 10: hoeveel verschillende lezingen?" % code(cb.bits), cb.parses.size(), [1, 2, 3],
				"Alle lezingen: %s." % ", ".join(_parse_texts(cb)), 1)
		"ink":
			var cb2 := t as ScCodeBoard
			var cost := ScReference.code_cost(cb2.placed, cb2.freqs)
			return _num_q("Hoeveel bits wordt %s met deze code (Σ a(x)·l(x))?" % ch(cb2.text), cost, [cb2.text.length() * 2, cost + 2],
				"%s." % _cost_txt(cb2.placed, cb2.freqs), 1)
		"holes":
			var dc := t as ScDovecote
			return _num_q("Hoeveel bitstrings zijn korter dan %d bits (het lege woord meegeteld)?" % dc.bits, dc.short_holes.size(),
				[dc.pigeons.size(), dc.pigeons.size() / 2], "1 + 2 + … + 2^%d = 2^%d − 1 = %d: één minder dan de %d duiven." % [dc.bits - 1,
				dc.bits, dc.short_holes.size(), dc.pigeons.size()], 1)
		"twine":
			var bd := t as ScBindery
			var tot := ScReference.huffman_cost(bd.freqs)
			var fixed := ScLevels._ceil_log2(bd.freqs.size()) * _sum_w(bd.freqs)
			return _num_q("Hoeveel bits (touw) telt de hele code samen?" , tot, [fixed, tot + 1], "Touw = som van de bundels = Σ a(x)·l(x) = %d bits (vaste lengte: %d)." % [tot, fixed], 1)
		"interval":
			var c := copy(t)
			c.apply(mv)
			var ru := c as ScRuler
			var right := iv(ru.low, ru.up()).replace("[lb]", "[")
			var cands: Array = []
			for m in (t as ScRuler).model:
				var c2 := copy(t)
				c2.apply({"act": "cut", "sym": str(m[0])})
				var r2 := c2 as ScRuler
				cands.append(iv(r2.low, r2.up()).replace("[lb]", "["))
			return _str_q("Welk interval heb je na %s?" % ch(str(mv.sym)), right, cands, why)
	# "next": welke zet? Juist = elke zet die de proef doorstaat (oordeel OK).
	var opts: Array = [describe(t, mv)]
	var correct: Array = [0]
	var cands2: Array = []
	cands2.append_array(t.wrong_moves())
	cands2.append_array(_valid_alts(t, mv))
	cands2.append_array(_other_choices(t, mv))
	for c3 in cands2:
		if opts.size() >= 4:
			break
		var lb := describe(t, c3)
		if opts.has(lb):
			continue
		var tr := trial(t, c3)
		var good := bool(tr.r.ok) and int(tr.r.verdict) == V.OK
		opts.append(lb)
		if good:
			correct.append(opts.size() - 1)
	if opts.size() < 2:
		return {}
	var q := _q_text(t, mv)
	var right := "%s %s" % [n.what, n.why]
	return {"q": q, "options": opts, "correct": correct, "right": right, "wrong": "Juist is [b]%s[/b]. %s" % [opts[0], right]}


## Andere geldige zetten (bv. een ander lichtste paar): ook juist bij de voorspelvraag.
static func _valid_alts(t: ScTool, mv: Dictionary) -> Array:
	var out: Array = []
	if t is ScBindery and (t as ScBindery).mode == "row":
		var bd := t as ScBindery
		var ws: Array = []
		for q in bd.row:
			ws.append(bd.tree.w(q))
		for pr in ScReference.valid_pairs(ws):
			var m := {"act": "bind", "a": int(pr[0]), "b": int(pr[1])}
			if m != mv:
				out.append(m)
	return out


## Andere keuzes die de speler kan aanklikken (ook als de core ze als klem weigert): andere bladeren, vakken, posities.
static func _other_choices(t: ScTool, mv: Dictionary) -> Array:
	var out: Array = []
	var a := str(mv.get("act", ""))
	if t is ScPrefixReader:
		for x in (t as ScPrefixReader).tree.leaves():
			out.append({"act": "read", "leaf": x})
	elif t is ScLivingTree and a == "read":
		for x in (t as ScLivingTree).tree.leaves():
			out.append({"act": "read", "leaf": x})
	elif t is ScRuler and a == "cut" and t.side == ScCodes.Side.RECEIVE:
		for m in (t as ScRuler).model:
			out.append({"act": "cut", "sym": str(m[0])})
	elif t is ScWindow and t.side == ScCodes.Side.RECEIVE:
		for p in (t as ScWindow).window().length():
			out.append({"act": "start", "p": p})
	elif t is ScBindery and (t as ScBindery).mode == "shelves":
		for sa in ["A", "B"]:
			for sb in ["A", "B"]:
				out.append({"act": "bind", "a": sa, "b": sb})
	elif t is ScShelf:
		var k := int(mv.get("k", 0))
		for k2 in [k + 2, k - 2, k + 3]:
			if k2 >= 0 and k2 < (t as ScShelf).list.size():
				out.append({"act": a, "k": k2})
	out.erase(mv)
	return out


static func _parse_texts(cb: ScCodeBoard) -> Array:
	var out: Array = []
	for p in cb.parses:
		out.append(str(p.text))
	return out


static func _sum_w(freqs: Array) -> int:
	var s := 0
	for f in freqs:
		s += int(f[1])
	return s


static func _cost_txt(cd: Dictionary, freqs: Array) -> String:
	var parts_ := PackedStringArray()
	var tot := 0
	for f in freqs:
		var l := str(cd.get(str(f[0]), "")).length()
		parts_.append("%d·%d" % [int(f[1]), l])
		tot += int(f[1]) * l
	return "%s = %d" % [" + ".join(parts_), tot]


static func shuffled(q: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if q.is_empty() or (q.options as Array).size() < 2:
		return q
	var opts: Array = q.options
	var idx: Array = range(opts.size())
	for i in range(idx.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = idx[i]
		idx[i] = idx[j]
		idx[j] = tmp
	var out := q.duplicate(true)
	var no: Array = []
	var nc: Array = []
	for k in idx.size():
		no.append(opts[idx[k]])
		if (q.correct as Array).has(idx[k]):
			nc.append(k)
	out.options = no
	out.correct = nc
	return out


# ======================================================================
#  Check-vragen in de terugblik: nieuw willekeurig voorbeeld (antwoord uit ScReference)
#  {q, options, correct, explain, fig (mono-tekst zoals op het examen)}
# ======================================================================

static func _rs(rng: RandomNumberGenerator, alpha: String, n: int) -> String:
	var s := ""
	for _i in n:
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s


static func _opts(right: String, cands: Array) -> Array:
	var o: Array = [right]
	for c in cands:
		if not o.has(str(c)) and o.size() < 4:
			o.append(str(c))
	return o


static func _code_txt(cd: Dictionary) -> String:
	var ks := cd.keys()
	ks.sort()
	var out := PackedStringArray()
	for k in ks:
		out.append("%s = %s" % [k, cd[k]])
	return ", ".join(out)


static func _rand_weights(rng: RandomNumberGenerator, letters: String, lo := 1, hi := 6) -> Array:
	var out: Array = []
	for c in letters:
		out.append([c, rng.randi_range(lo, hi)])
	return out


static func _huff_code(rng: RandomNumberGenerator, letters: String) -> Dictionary:
	return ScReference.huffman(_rand_weights(rng, letters)).codes


static func _tree_table(tr: ScTree) -> String:
	var rows := PackedStringArray(["nr  gewicht  top     ouder"])
	var pro := tr.procession()
	for k in range(pro.size() - 1, -1, -1):
		var x: int = pro[k]
		var s := tr.sym(x)
		var nm := "nng" if s == ScCodes.NNG else ("blad " + s if s != "" else "intern")
		var par := tr.parent(x)
		rows.append("%-3d %-8d %-7s %s" % [tr.num(x), tr.w(x), nm, str(tr.num(par)) if par >= 0 else "-"])
	return "\n".join(rows)


static func check_question(id: String, rng: RandomNumberGenerator) -> Dictionary:
	for _try in 20:
		var q := _check(id, rng)
		if not q.is_empty() and (q.options as Array).size() >= 2:
			return q
	return {}


static func _check(id: String, rng: RandomNumberGenerator) -> Dictionary:
	match id:
		"prefix_lezen":
			var cd := _huff_code(rng, "klmn")
			var w := _rs(rng, "klmn", rng.randi_range(4, 5))
			var bits := ScReference.encode_with(cd, w)
			var right := str(ScReference.decode_prefix(cd, bits).text)
			var cands: Array = []
			for _k in 8:
				cands.append(_rs(rng, "klmn", w.length()))
			var inv := ScReference.inverse(cd)
			var split := PackedStringArray()
			var a := 0
			for c in ScReference.decode_prefix(cd, bits).cuts:
				split.append(bits.substr(a, int(c) - a))
				a = int(c)
			return {"fig": "code: %s\nstrook: %s" % [_code_txt(cd), bits], "q": "Lees de strook met deze prefixcode. Wat staat er?",
				"options": _opts(right, cands), "correct": [0],
				"explain": "Volg de bits tot een codewoord: %s = %s." % [code("|".join(split)), ch(right)]}
		"prefix_def":
			var good := _huff_code(rng, "abcd")
			var opts: Array = []
			var bads: Array = []
			var keys := good.keys()
			for _k in 6:
				var bad := good.duplicate()
				var x: String = keys[rng.randi_range(0, keys.size() - 1)]
				var y: String = keys[rng.randi_range(0, keys.size() - 1)]
				if x == y:
					continue
				# maak x een prefix van y
				var wy := str(bad[y])
				if wy.length() < 2:
					continue
				bad[x] = wy.substr(0, rng.randi_range(1, wy.length() - 1))
				if not ScReference.is_prefix_code(bad) and not bads.has(_code_txt(bad)):
					bads.append(_code_txt(bad))
			if bads.size() < 2:
				return {}
			opts = [_code_txt(good), bads[0], bads[1]]
			return {"fig": "drie codes voor a, b, c, d\n(zie de knoppen)", "q": "Welke code is een prefixcode?",
				"options": opts, "correct": [0],
				"explain": "In [code]%s[/code] is geen codewoord het begin van een ander. In de andere wel: dan weet de lezer niet waar een letter stopt (Definitie 20)." % _code_txt(good)}
		"duiventil":
			var n := rng.randi_range(2, 6)
			var right2 := (1 << n) - 1
			return {"fig": "berichten van %d bits: 2^%d = %d" % [n, n, 1 << n], "q": "Hoeveel bitstrings zijn er die korter zijn dan %d bits (het lege woord meegeteld)?" % n,
				"options": _opts(str(right2), [str(1 << n), str(1 << (n - 1)), str(right2 - 1)]), "correct": [0],
				"explain": "1 + 2 + … + 2^%d = 2^%d − 1 = %d < %d: niet elk bericht van %d bits kan korter." % [n - 1, n, right2, 1 << n, n]}
		"huffman":
			var ws := _rand_weights(rng, "abcde".substr(0, rng.randi_range(4, 5)), 1, 7)
			var h := ScReference.huffman(ws)
			var cost := int(h.cost)
			var fixed := ScLevels._ceil_log2(ws.size()) * _sum_w(ws)
			var steps := PackedStringArray()
			for st in h.steps:
				steps.append(str(st.w))
			var wtxt := PackedStringArray()
			for x in ws:
				wtxt.append("a(%s) = %d" % [x[0], int(x[1])])
			return {"fig": ", ".join(wtxt), "q": "Hoeveel bits telt de tekst met de Huffman-code (Σ a(x)·l(x))?",
				"options": _opts(str(cost), [str(fixed), str(cost + 1), str(cost - 1), str(cost + 2)]), "correct": [0],
				"explain": "Bind telkens de twee lichtste; de bundels wegen %s. Samen %d bits." % [" + ".join(steps), cost]}
		"planken":
			var ws2 := _rand_weights(rng, "abcde", 1, 6)
			var a_l: Array = ws2.duplicate()
			a_l.sort_custom(func(p, q): return int(p[1]) < int(q[1]))
			var b_l: Array = []
			var step := rng.randi_range(1, 3)
			var pick := ""
			var state_txt := ""
			var cands: Array = []
			for s in step + 1:
				var tk: Array = []
				if s == step:
					state_txt = "plank A: %s\nplank B: %s" % [_shelf_txt(a_l), _shelf_txt(b_l)]
					var fr: Array = []
					for l in [a_l, b_l]:
						for q in mini(2, (l as Array).size()):
							fr.append(int(l[q][1]))
					for x in fr:
						for y in fr:
							cands.append("%d en %d" % [mini(x, y), maxi(x, y)])
				for _k in 2:
					var use_b := not b_l.is_empty() and (a_l.is_empty() or int(b_l[0][1]) <= int(a_l[0][1]))
					tk.append(b_l.pop_front() if use_b else a_l.pop_front())
				b_l.append(["(" + str(tk[0][0]) + str(tk[1][0]) + ")", int(tk[0][1]) + int(tk[1][1])])
				if s == step:
					pick = "%d en %d" % [mini(int(tk[0][1]), int(tk[1][1])), maxi(int(tk[0][1]), int(tk[1][1]))]
			return {"fig": state_txt, "q": "Welke twee gewichten bind je nu?",
				"options": _opts(pick, cands), "correct": [0],
				"explain": "Kies 2 keer het kleinste van wat vooraan staat (A of B); vooraan staat telkens het lichtste van elke plank: %s." % pick}
		"fgk_klim", "fgk_ouder":
			for _k in 40:
				var tx := _rs(rng, "abc", rng.randi_range(2, 4))
				var tr: ScTree = ScReference.adaptive_encode(tx).tree
				var leaves := tr.leaves()
				var cands: Array = []
				for lf in leaves:
					if tr.sym(lf) != ScCodes.NNG:
						cands.append(lf)
				if cands.is_empty():
					continue
				var lf2: int = cands[rng.randi_range(0, cands.size() - 1)]
				var ts := ScReference.adaptive_tstar(tr, lf2)
				var is_par := ts == tr.parent(lf2) and ts != lf2
				if (id == "fgk_ouder") != is_par:
					continue
				var right3 := "niet wisselen" if (ts == lf2 or is_par) else "wissel met nummer %d" % tr.num(ts)
				var others: Array = ["niet wisselen"]
				for x in tr.ids():
					if x != lf2 and x != ts:
						others.append("wissel met nummer %d" % tr.num(x))
				return {"fig": "%s\n\nteken %s komt nog eens" % [_tree_table(tr), tr.sym(lf2)],
					"q": "Het blad van %s is t (nummer %d). Wat doe je eerst?" % [tr.sym(lf2), tr.num(lf2)],
					"options": _opts(right3, others), "correct": [0],
					"explain": "t′ = de top met gewicht %d en het hoogste nummer: nummer %d.%s" % [tr.w(lf2), tr.num(ts),
						" Dat is de ouder van t: niet wisselen (p. 95)." if is_par else (" Dat is t zelf: niet wisselen." if ts == lf2 else " Wissel t en t′.")]}
			return {}
		"fgk_nieuw":
			var tx2 := _rs(rng, "abc", rng.randi_range(3, 4))
			var k := rng.randi_range(1, tx2.length() - 1)
			var enc := ScReference.adaptive_encode(tx2)
			var right4 := toks_txt(enc.steps[k].tokens)
			var before: ScTree = ScReference.adaptive_encode(tx2.substr(0, k)).tree
			var cands2: Array = []
			for lf in before.leaves():
				var c := before.code(lf)
				cands2.append(c + ("\"%s\"" % tx2[k] if before.sym(lf) == ScCodes.NNG else ""))
			cands2.append("\"%s\"" % tx2[k])
			return {"fig": "%s\n\n(boom na %s)" % [_tree_table(before), tx2.substr(0, k)],
				"q": "Wat schrijft de afzender voor het volgende teken %s?" % ch(tx2[k]), "options": _opts(right4, cands2), "correct": [0],
				"explain": "%s Juist: %s." % ["Nieuw teken: code(nng) en dan de letter ruw." if str(enc.steps[k].kind) == "new" else "Gekend teken: het pad naar zijn blad in de boom van nu.", code(right4)]}
		"fgk_lezen":
			var tx3 := _rs(rng, "ab", rng.randi_range(4, 5))
			var toks: Array = ScReference.adaptive_encode(tx3).tokens
			var cands3: Array = []
			for _k in 10:
				cands3.append(_rs(rng, "ab", tx3.length()))
			return {"fig": "stroom: %s\n(begin met de lege boom: enkel nng)" % ScReference.tokens_to_string(toks),
				"q": "Wat staat er?", "options": _opts(tx3, cands3), "correct": [0],
				"explain": "Lees tot een blad (nng: de letter erna is ruw) en werk de boom bij zoals de afzender: %s." % ch(tx3)}
		"arit_interval", "arit_bits", "arit_lezen":
			var models := [ScLevels.XYZ, ScLevels.ACGT, MODEL_ABC]
			var md: Array = models[rng.randi_range(0, models.size() - 1)]
			var syms := ScReference.model_syms(md)
			var tx4 := str(syms[rng.randi_range(0, syms.size() - 1)]) + str(syms[rng.randi_range(0, syms.size() - 1)])
			var ivl := ScReference.get_interval(tx4, md)
			var mtxt := PackedStringArray()
			for m in md:
				mtxt.append("p(%s) = %s" % [m[0], str(m[1]).replace(".", ",")])
			var bits2 := str(ScReference.get_bitstring(ivl.low, ivl.up).bits)
			if id == "arit_interval":
				var cands4: Array = []
				for s1 in syms:
					for s2 in syms:
						var o := ScReference.get_interval(str(s1) + str(s2), md)
						cands4.append("[%s; %s)" % [d(o.low), d(o.up)])
				var right5 := "[%s; %s)" % [d(ivl.low), d(ivl.up)]
				return {"fig": "model: %s\ntekst: %s" % [", ".join(mtxt), tx4], "q": "Welk interval [links, links+lengte) krijgt %s?" % ch(tx4),
					"options": _opts(right5, cands4), "correct": [0],
					"explain": "Algoritme 12: na %s is links = %s en lengte = %s." % [ch(tx4), d(ivl.low), d(ivl.len)]}
			if id == "arit_bits":
				var cands5: Array = [bits2 + "1", bits2.substr(0, maxi(1, bits2.length() - 1)), bits2 + "0"]
				var flip := bits2.substr(0, bits2.length() - 1) + ("0" if bits2.ends_with("1") else "1")
				cands5.append(flip)
				return {"fig": "interval [low, up) = [%s; %s)" % [d(ivl.low), d(ivl.up)], "q": "Welke bitstring geeft Algoritme 13?",
					"options": _opts(bits2, cands5), "correct": [0],
					"explain": "getal = 0, next = 0,5: een 1 enkel als getal + next < up, stop zodra getal ≥ low: %s = %s." % [code(bits2), d(ScDec.from_bits(bits2))]}
			var dec := str(ScReference.arith_decode(bits2, 2, md).text)
			var cands6: Array = []
			for s1 in syms:
				for s2 in syms:
					cands6.append(str(s1) + str(s2))
			return {"fig": "model: %s\nbits: %s  (n = 2)" % [", ".join(mtxt), bits2], "q": "Welke tekst van 2 tekens is dit?",
				"options": _opts(dec, cands6), "correct": [0],
				"explain": "r = %s: kies telkens het vak [lb]lo, hi) dat r bevat (onderrand dicht, bovenrand open): %s." % [d(ScDec.from_bits(bits2)), ch(dec)]}
		"lz77_zend", "lz77_register":
			var G: int = -1 if id == "lz77_register" else [4, 6][rng.randi_range(0, 1)]
			var tx5 := _rs(rng, "abn", rng.randi_range(8, 10))
			var enc5: Array = ScReference.lz77_encode(tx5, G).triples
			var right6 := _trip_list(enc5)
			var cands7: Array = []
			for G2 in [2, 3, 4, 6, -1]:
				if G2 != G:
					cands7.append(_trip_list(ScReference.lz77_encode(tx5, G2).triples))
			for q in enc5.size():
				var alt := (enc5.duplicate(true) as Array)
				if int(alt[q][1]) > 0:
					alt[q] = [int(alt[q][0]) + 1, int(alt[q][1]), alt[q][2]]
					cands7.append(_trip_list(alt))
			return {"fig": "tekst: %s\nG = %s" % [tx5, str(G) if G > 0 else "∞ (geen sliding window)"],
				"q": "Welke drietallen (p, l, x) schrijft LZ77?", "options": _opts(right6, cands7), "correct": [0],
				"explain": "Telkens de langste match die in het raam begint (posities vanaf 0 links): %s." % right6}
		"lz77_lees":
			var G3: int = [4, 6][rng.randi_range(0, 1)]
			var tx6 := _rs(rng, "abn", rng.randi_range(7, 9))
			var trs: Array = ScReference.lz77_encode(tx6, G3).triples
			var cands8: Array = []
			for _k in 10:
				var c := tx6
				var q := rng.randi_range(0, c.length() - 1)
				c = c.substr(0, q) + "abn"[rng.randi_range(0, 2)] + c.substr(q + 1)
				cands8.append(c)
			return {"fig": "G = %d\n%s" % [G3, _trip_list(trs)], "q": "Wat staat er?", "options": _opts(tx6, cands8), "correct": [0],
				"explain": "Kopieer bij (p, l, x) l letters vanaf positie p van het raam (de laatste %d tekens), één voor één, dan x: %s." % [G3, ch(tx6)]}
		"lzw_zend":
			var tx7 := _rs(rng, "ab", rng.randi_range(6, 8))
			var codes: Array = ScReference.lzw_encode(tx7).codes
			var right7 := _join(codes)
			var cands9: Array = []
			for _k in 8:
				var c2: Array = codes.duplicate()
				var q2 := rng.randi_range(0, c2.size() - 1)
				c2[q2] = int(c2[q2]) + [1, -1, 2][rng.randi_range(0, 2)]
				cands9.append(_join(c2))
			cands9.append(_join(ScReference.lzw_encode(tx7.substr(0, tx7.length() - 1)).codes))
			var adds := PackedStringArray()
			for ad in ScReference.lzw_encode(tx7).adds:
				adds.append("%d = %s" % [int(ad[0]), str(ad[1])])
			return {"fig": "tekst: %s\n(a = 97, b = 98; nieuwe codes vanaf 256)" % tx7, "q": "Welke codes schrijft LZW?",
				"options": _opts(right7, cands9), "correct": [0], "explain": "Nieuw: %s. Uitvoer: %s." % [", ".join(adds), right7]}
		"lzw_lees":
			for _k in 30:
				var tx8 := _rs(rng, "ab", rng.randi_range(6, 9))
				var cds: Array = ScReference.lzw_encode(tx8).codes
				var dec2 := ScReference.lzw_decode(cds)
				if (dec2.special as Array).is_empty():
					continue
				var cands10: Array = []
				for _j in 10:
					var c3 := tx8
					var q3 := rng.randi_range(0, c3.length() - 1)
					c3 = c3.substr(0, q3) + ("a" if c3[q3] == "b" else "b") + c3.substr(q3 + 1)
					cands10.append(c3)
				return {"fig": "codes: %s\n(a = 97, b = 98; nieuwe codes vanaf 256)" % _join(cds), "q": "Wat staat er?",
					"options": _opts(tx8, cands10), "correct": [0],
					"explain": "Na elke code: vorig woord + eerste letter van het nieuwe. Code %d was nog leeg: w + w[lb]0]. Tekst: %s." % [int(cds[int((dec2.special as Array)[0])]), ch(tx8)]}
			return {}
		"bwt_zend", "bwt_terug":
			for _k in 30:
				var tx9 := _rs(rng, "aben", rng.randi_range(4, 6))
				if not _distinct_rots(tx9):
					continue
				var b := ScReference.bwt(tx9)
				if id == "bwt_zend":
					var right8 := "(%d, %s)" % [int(b.p), str(b.c)]
					var cands11: Array = ["(%d, %s)" % [(int(b.p) + 1) % tx9.length(), str(b.c)], "(%d, %s)" % [int(b.p), ScReference.sorted_chars(str(b.c))],
						"(%d, %s)" % [int(b.p), str(b.c).reverse()], "(%d, %s)" % [maxi(0, int(b.p) - 1), str(b.c)]]
					return {"fig": "tekst: %s" % tx9, "q": "Wat is de uitvoer (p, laatste kolom)?", "options": _opts(right8, cands11), "correct": [0],
						"explain": "Gesorteerd: %s. p = de rij waar de eerste letter %s van de tekst op de laatste plaats staat: de rotatie %s (die één letter verder begint) staat in rij %d." % [" / ".join(b.rows), ch(tx9[0]), code(ScReference.rotation(tx9, 1)), int(b.p)]}
				var cands12: Array = []
				for r in range(1, tx9.length()):
					cands12.append(ScReference.rotation(tx9, r))
				cands12.append(tx9.reverse())
				return {"fig": "p = %d, c = %s" % [int(b.p), str(b.c)], "q": "Welke tekst geeft de terugweg?", "options": _opts(tx9, cands12),
					"correct": [0], "explain": "e = %s (c gesorteerd). Begin bij rij p; de k-de x in e is de k-de x in c: %s." % [ScReference.sorted_chars(str(b.c)), ch(tx9)]}
			return {}
		"mtf":
			var lst: Array = ["a", "b", "e", "n"]
			for i in range(lst.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var tmp = lst[i]
				lst[i] = lst[j]
				lst[j] = tmp
			var tx10 := _rs(rng, "aben", 5)
			var nums: Array = ScReference.mtf_encode(tx10, lst).nums
			var cands13: Array = []
			var plain: Array = []
			for c4 in tx10:
				plain.append(lst.find(c4))
			cands13.append(_join(plain))
			for _k in 6:
				var c5: Array = nums.duplicate()
				var q4 := rng.randi_range(0, c5.size() - 1)
				c5[q4] = (int(c5[q4]) + rng.randi_range(1, 3)) % 4
				cands13.append(_join(c5))
			return {"fig": "lijst: %s\ntekst: %s" % [list_txt(lst), tx10], "q": "Welke getallen schrijft move-to-front?",
				"options": _opts(_join(nums), cands13), "correct": [0],
				"explain": "Positie in de lijst zoals ze NU is (vanaf 0), dan vooraan: %s. (Zonder vooraan zetten: %s.)" % [_join(nums), _join(plain)]}
	return {}


static func _shelf_txt(l: Array) -> String:
	var out := PackedStringArray()
	for x in l:
		out.append("%s %d" % [x[0], int(x[1])])
	return " · ".join(out) if not out.is_empty() else "(leeg)"


static func _trip_list(trs: Array) -> String:
	var out := PackedStringArray()
	for tr in trs:
		out.append("(%d,%d,%s)" % [int(tr[0]), int(tr[1]), str(tr[2])])
	return " ".join(out)


static func _distinct_rots(s: String) -> bool:
	var seen := {}
	for i in s.length():
		var r := ScReference.rotation(s, i)
		if seen.has(r):
			return false
		seen[r] = true
	return true
