class_name ScLevels
## Alle levels van Kortschrift (GDD §5), de Nachtwake-spec, de werktuigfabriek en het optimum (perfect spel).

const FIG25 := {"o": "00", "u": "010", "d": "011", "f": "10", "t": "11"}
const BEN := {"e": "0", "n": "1", "b": "10"}
const XYZ := [["x", "0.2"], ["y", "0.7"], ["z", "0.1"]]
const ACGT := [["a", "0.3"], ["c", "0.2"], ["g", "0.4"], ["t", "0.1"]]
const S40 := "yyyxzxxzyyyxyyyyxyyyzxyxyyyyxxyyyyyyxyyy"
const LIST61 := [" ", "1", "a", "b", "e", "f", "g", "n", "o", "l"]
const LIST63 := [" ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "g", "m", "n", "o", "t"]
const LIST105 := ["7", "a", "e", "i", "o", "u", "b", "c", "n", "t", "w", " "]
const LISTC := [" ", "2", "a", "c", "n", "s", "t", "u"]

const ORDER := ["0-1", "0-2", "0-3", "1-1", "1-2", "1-3", "1-4", "1-5", "2-1", "2-2", "2-3", "2-4", "2-5", "3-1",
	"3-2", "3-3", "3-4", "4-1", "4-2", "4-3", "4-4", "4-5", "4-6", "5-1", "5-2", "5-3", "5-4", "5-5", "6-1", "6-2",
	"6-3", "6-4", "6-5", "C"]
const CHAPTERS := ["Advent", "Kerstmis", "Vasten", "Pasen", "Pinksteren", "Hooimaand", "Wijnmaand", "Allerheiligen"]
const HOUSES := ["Zuinigem", "Priorij Bindervoort", "Klooster Groeiendonk", "Kartuis Meetendaal", "Priorij Zoalsboven",
	"Abdij Stempelrode", "Kluis Ter Rolle", "de hele orde"]
const CRATES := ["codeboom", "binderij", "levende boom", "meetlat", "leesraam", "stempelkast", "draaitrommel", "Codex"]
const NACHTWAKE_UNLOCK := "1-2"

static var _opt_cache: Dictionary = {}


static func ids() -> PackedStringArray:
	return PackedStringArray(ORDER)


static func has(id: String) -> bool:
	return ORDER.has(id)


# ------------------------------------------------------------------ sterren

static func _st(extra3: Array = [], first := "lossless", second := "no_mistakes") -> Array[Dictionary]:
	var third: Array = [{"kind": "no_help"}]
	third.append_array(extra3)
	return [{"kind": first}, {"kind": second}, {"kind": "all", "of": third}]


# ------------------------------------------------------------------ levels

static func get_spec(id: String) -> ScLevelSpec:
	var s := ScLevelSpec.new()
	s.id = id
	s.chapter = 7 if id == "C" else int(id.substr(0, 1))
	s.stars = _st()
	match id:
		"0-1":
			_meta(s, "Oud en fout", "Figuur 25 en Oefening 79 · notas p. 83–84", "Volg de takken tot een blad. Dan begin je opnieuw.")
			s.stages = [
				{"tool": "prefix_read", "code": FIG25, "bits": "00010011", "expect": "oud"},
				{"tool": "prefix_read", "code": FIG25, "bits": "100001011", "expect": "fout"}]
			s.stars = _st([], "lossless", "no_bumps")
			s.story["stage_intros"] = ["Volg de takken tot een blad. Dan begin je opnieuw.",
				"Fout? Nee hoor. Dat is het juiste antwoord."]
			s.story["debrief_extra"] = "Oefening 79: 100001011 = f·o·u·t."
			s.story["crate"] = "codeboom"
		"0-2":
			_meta(s, "Neeen!", "Definitie 20 · notas p. 82–83", "Waar stopt een letter? Dat moet de lezer altijd weten.")
			s.stages = [
				{"tool": "code_board", "mode": "cuts", "code": BEN, "bits": "100101", "need": 2, "intended": "benen"},
				{"tool": "code_board", "mode": "design", "text": "een been en een benen", "max_depth": 3}]
			s.stars = _st([{"kind": "readings_all"}])
			s.story["stage_intros"] = ["Waar stopt een letter? Dat moet de lezer altijd weten.",
				"Hang letters enkel aan bladeren."]
			s.story["debrief_extra"] = "Elk blad is een letter, geen letter heeft kinderen."
		"0-3":
			_meta(s, "Het duiventil", "Oefening 76/77 · notas p. 81–82", "Elke duif een eigen, korter hok.")
			s.priority = "P1"
			s.stages = [{"tool": "dovecote", "bits": 3}]
			s.stars = _st([], "done", "decrees_ok")
			s.story["debrief_extra"] = "1 + 2 + 4 = 7 < 8 = 2³. Voor bytes: (256^(n+1) − 1)/255 hokken."
		"1-1":
			_meta(s, "Boosdoeer", "Algoritme 9 · notas p. 84–85", "Bind de twee lichtste stapels. Herhaal tot er één boom is.")
			s.stages = [{"tool": "bindery", "mode": "row", "text": "boosdoeer", "row": "boesdr"}]
			s.stars = _st([{"kind": "time_le", "s": 60}])
			s.story["debrief_extra"] = "Touw = bits: 2 + 2 + 4 + 5 + 9 = 22."
			s.story["crate"] = "binderij"
		"1-2":
			_meta(s, "Oefening 80: bananenboom", "Oefening 80 · notas p. 86", "Twee keer gewicht één. Begin daar.")
			s.stages = [{"tool": "bindery", "mode": "row", "text": "bananenboom"}]
		"1-3":
			_meta(s, "Oefening 81: zaken nemen geen keer", "Oefening 81 · notas p. 87", "Bind de twee lichtste. Ook bij negen stapels.")
			s.stages = [{"tool": "bindery", "mode": "row", "text": "zaken_nemen_geen_keer"}]
			s.stars = _st([{"kind": "time_le", "s": 120}])
		"1-4":
			_meta(s, "De registers van de kelner", "Oefening 86 (en 83) · notas p. 87–88", "Samenvoegen kost de som. Bind de lichtste eerst.")
			s.priority = "P1"
			s.stages = [{"tool": "bindery", "mode": "row", "weights": [["A", 8], ["B", 3], ["C", 5], ["D", 2], ["E", 9]]}]
			s.stars = _st([], "done")
			s.story["debrief_extra"] = "Dit is Huffman: de kost is Σ gewicht × diepte (Stelling 21). Van links naar rechts: 72."
		"1-5":
			_meta(s, "Twee planken", "Oefening 85 · notas p. 88", "Neem telkens vooraan het lichtste. Bij gelijk: plank B.")
			s.priority = "P1"
			s.stages = [{"tool": "bindery", "mode": "shelves", "text": "de kok kookt koolsoep"}]
			s.story["debrief_extra"] = "Na het sorteren: O(n). Nieuwe bundels worden nooit lichter (Oef. 85)."
		"2-1":
			_meta(s, "Nog een e, nog een s", "Lemma 22 en Algoritme 10 · notas p. 89–93", "Zelfde gewicht, verste plaats in de processie. Wissel met die.")
			s.stages = [
				{"tool": "living_tree", "side": "send", "text": "e", "start": "p90"},
				{"tool": "living_tree", "side": "send", "text": "s", "start": "p90"}]
			s.stars = _st([{"kind": "no_bumps"}])
			s.story["stage_intros"] = ["Nog een e. Wie moet er wisselen?", "Nog een s. Zelfde gewicht, verste plaats."]
			s.story["debrief_extra"] = "Wie bij de s nooit wisselt, krijgt de boom onderaan p. 91: die schendt (b)."
			s.story["crate"] = "levende boom"
		"2-2":
			_meta(s, "Graag", "Algoritme 11 · notas p. 96–98", "Eerst schrijven met de oude boom. Dan pas groeien.")
			s.stages = [{"tool": "living_tree", "side": "send", "text": "graag", "start": "empty"}]
		"2-3":
			_meta(s, "Eetzaal", "Algoritme 11, het speciale geval · notas p. 95", "Soms is de verste monnik je eigen ouder. Dan blijf je.")
			s.stages = [{"tool": "living_tree", "side": "send", "text": "eetzaal", "start": "empty"}]
			s.stars = _st([{"kind": "no_bumps"}])
		"2-4":
			_meta(s, "Oefening 90: voordeel", "Oefening 90 · notas p. 98", "Korte teksten winnen niets. Lange wel.")
			s.stages = [{"tool": "living_tree", "side": "send", "text": "voordeel", "start": "empty"}]
			s.stars = _st([{"kind": "time_le", "s": 240}])
		"2-5":
			_meta(s, "Oefening 91: de ontvanger", "Oefening 91 · notas p. 98", "Lees met jouw boom. Werk hem bij zoals de afzender.")
			s.stages = [{"tool": "living_tree", "side": "receive", "tokens": "\"n\"0\"o\"0100\"d\"001100\"a\"100111",
				"expect": "nooddaad"}]
		"3-1":
			_meta(s, "x, y en z", "Algoritme 12/13 · notas p. 99–101", "Knip het vak van de letter. Het interval wordt je nieuwe lat.")
			s.stages = [
				{"tool": "ruler", "side": "send", "model": XYZ, "text": "yy", "auto_after": -1},
				{"tool": "ruler", "side": "receive", "model": XYZ, "bits": "1", "n": 2, "expect": "yy"},
				{"tool": "ruler", "side": "receive", "model": XYZ, "bits": "1101", "n": 2, "expect": "yy"},
				{"tool": "ruler", "side": "receive", "model": XYZ, "pin": "0.9", "n": 2, "expect": "zx"}]
			s.stars = _st([{"kind": "no_bumps"}])
			s.story["stage_intros"] = ["Knip het vak van de letter.", "De speld staat op 0,5. Welk vak?",
				"Binair 1101 = 0,8125.", "0,9: onderrand dicht, bovenrand open."]
			s.story["crate"] = "meetlat"
		"3-2":
			_meta(s, "Oefening 93: cag", "Oefening 93 · notas p. 102", "Nooit boven de bovengrens stappen.")
			s.stages = [{"tool": "ruler", "side": "send", "model": ACGT, "text": "cag", "auto_after": -1}]
		"3-3":
			_meta(s, "Oefening 95: 0010011", "Oefening 95 · notas p. 102", "Onderrand dicht, bovenrand open.")
			s.stages = [
				{"tool": "ruler", "side": "receive", "model": ACGT, "bits": "0010011", "n": 3, "expect": "act"},
				{"tool": "ruler", "side": "receive", "model": ACGT, "bits": "1", "n": 2, "expect": "ga"}]
			s.stars = _st([{"kind": "no_bumps"}])
		"3-4":
			_meta(s, "Veertig letters, één bit", "notas p. 101", "Veertig letters. Kijk hoe klein het interval wordt.")
			s.stages = [{"tool": "ruler", "side": "send", "model": XYZ, "text": S40, "auto_after": 5}]
			s.ghosts = {"huffman": 53, "lemma24": 48}
			s.story["debrief_extra"] = "Met gewone kommagetallen krijg je ongeveer de waarden van de notas; precies dat is probleem (b) op p. 103."
		"4-1":
			_meta(s, "Banaan-baan", "Algoritme 14 · notas p. 106–107", "Zoek het langste stuk dat al geschreven staat. Begin in het raam.")
			s.stages = [{"tool": "window", "side": "send", "text": "banaan-baan", "G": 6, "register": false}]
			s.stars = _st([{"kind": "no_bumps"}])
			s.story["crate"] = "leesraam"
		"4-2":
			_meta(s, "Aanvaardbaar", "LZ77 decoderen · notas p. 108", "Tel vanaf de linkerrand van het raam. De eerste is nul.")
			s.stages = [{"tool": "window", "side": "receive", "G": 6, "expect": "aanvaardbaar", "triples": [[0, 0, "a"],
				[0, 1, "n"], [0, 0, "v"], [0, 2, "r"], [0, 0, "d"], [0, 0, "b"], [1, 3, "EOF"]]}]
		"4-3":
			_meta(s, "Oefening 97: swiss miss", "Oefening 97 · notas p. 108", "Een match mag buiten het raam eindigen.")
			s.stages = [{"tool": "window", "side": "send", "text": "swiss_miss_missing", "G": 8, "register": false}]
		"4-4":
			_meta(s, "Oefening 98: eendenbende en blablabla", "Oefening 98 · notas p. 108", "Iets raars? Dat kan.")
			s.stages = [
				{"tool": "window", "side": "receive", "G": 6, "expect": "eendenbende",
					"triples": [[0, 0, "e"], [0, 1, "n"], [0, 0, "d"], [1, 2, "b"], [0, 4, "EOF"]]},
				{"tool": "window", "side": "receive", "G": 6, "expect": "blablablabla",
					"triples": [[0, 0, "b"], [0, 0, "l"], [0, 0, "a"], [0, 9, "EOF"]]}]
		"4-5":
			_meta(s, "Oefening 97: de rest", "Oefening 97 · notas p. 108", "Drie brieven. Telkens de langste match.")
			s.priority = "P1"
			s.stages = [
				{"tool": "window", "side": "send", "text": "een_benen_been", "G": 8, "register": false},
				{"tool": "window", "side": "send", "text": "ananas-kanaal", "G": 8, "register": false},
				{"tool": "window", "side": "send", "text": "een_been_beet_hebben", "G": 8, "register": false}]
		"4-6":
			_meta(s, "Het register", "§4.3.1 en Oefening 100 · notas p. 109–110", "Laat het register zoeken. Eén blik per letter.")
			s.priority = "P1"
			s.stages = [{"tool": "window", "side": "send", "text": "abracadabra_simsalabim", "G": -1, "register": true}]
			s.stars = _st([{"kind": "search_le", "v": 30}])
			s.ghosts = {"search_plain": 146}
		"5-1":
			_meta(s, "Banaanaanval", "LZW · notas p. 111–112", "Zit het woord met de volgende letter al in de kast? Verleng.")
			s.stages = [{"tool": "stampcase", "side": "send", "text": "banaanaanval"}]
			s.stars = _st([{"kind": "no_bumps"}])
			s.story["crate"] = "stempelkast"
		"5-2":
			_meta(s, "Anananas", "LZW decoderen · notas p. 112–114", "De lade is nog leeg? Dan begint het woord zoals het vorige.")
			s.stages = [
				{"tool": "stampcase", "side": "receive", "codes": [97, 110, 256, 258, 115], "expect": "anananas"},
				{"tool": "stampcase", "side": "send", "text": "aaaaaaaa"}]
		"5-3":
			_meta(s, "Oefening 101: swiss miss", "Oefening 101 · notas p. 114", "Verleng zolang het woord in de kast zit.")
			s.stages = [{"tool": "stampcase", "side": "send", "text": "swiss_miss_missing"}]
		"5-4":
			_meta(s, "Oefening 102", "Oefening 102 · notas p. 114–115", "Niet zinnig? Dat zegt de oefening zelf.")
			s.stages = [{"tool": "stampcase", "side": "receive", "codes": [97, 256, 98, 99, 97, 98, 257, 260],
				"expect": "aaabcabaabab"}]
			s.stars = _st([], "lossless", "no_mistakes")
		"5-5":
			_meta(s, "Oefening 101: de rest", "Oefening 101 · notas p. 114", "Twee brieven voor de stempelkast.")
			s.priority = "P1"
			s.stages = [
				{"tool": "stampcase", "side": "send", "text": "een_beenen_been"},
				{"tool": "stampcase", "side": "send", "text": "ananas-kanaal"}]
		"6-1":
			_meta(s, "Geen loon", "Burrows-Wheeler en move-to-front · notas p. 115–117, 121", "Rol de tekst rond. Elke strook begint één letter verder.")
			s.stages = [
				{"tool": "drum", "side": "send", "text": "geen loon", "auto_sort": false},
				{"tool": "shelf", "side": "send", "input": "carry", "list": LIST61, "positions": true}]
			s.story["stage_intros"] = ["Rol de tekst rond. Elke strook begint één letter verder.",
				"Schrijf de plaats, vanaf nul. Dan naar voren."]
			s.story["crate"] = "draaitrommel"
		"6-2":
			_meta(s, "Terug naar geen loon", "BWT terug · notas p. 117–119, 121–122", "De derde o bovenaan is de derde o onderaan.")
			s.stages = [
				{"tool": "shelf", "side": "receive", "nums": [1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9], "list": LIST61,
					"expect": "1 ngen eool", "positions": true},
				{"tool": "drum", "side": "receive", "p": 1, "c": "ngen eool", "ranks": true, "expect": "geen loon"}]
		"6-3":
			_meta(s, "Oefening 104: toon gaat", "Oefening 104 · notas p. 122", "Eerst de trommel, dan de plank.")
			s.stages = [
				{"tool": "drum", "side": "send", "text": "toon gaat", "auto_sort": false},
				{"tool": "shelf", "side": "send", "input": "carry", "list": LIST63}]
			s.story["debrief_extra"] = "De lijst van de oefening heeft geen d en geen r: de tekst is toon gaat."
		"6-4":
			_meta(s, "Figuur 26: aacaacaac", "Figuur 26 · notas p. 119–120", "Gelijke stroken mogen in elke volgorde.")
			s.priority = "P1"
			s.stages = [
				{"tool": "drum", "side": "send", "text": "aacaacaac", "auto_sort": false},
				{"tool": "drum", "side": "receive", "p": 3, "c": "cccaaaaaa", "ranks": false, "expect": "aacaacaac"}]
		"6-5":
			_meta(s, "Oefening 105", "Oefening 105 · notas p. 122", "Enkel de letterplank: lees de getallen.")
			s.priority = "P2"
			s.stages = [{"tool": "shelf", "side": "receive", "nums": [0, 11, 10, 10, 7, 0, 6, 1, 0, 9, 11, 4, 6, 1],
				"list": LIST105, "expect": "7 tnooeoobwn n"}]
			s.story["debrief_extra"] = "Deze code geeft geen geldige BWT-uitvoer — vraag het na bij de assistenten."
		"C":
			_meta(s, "De Codex", "BWT → move-to-front → Huffman · notas p. 122", "Drie werktuigen. Het Sanctus, zo kort als het kan.")
			s.priority = "P1"
			s.stages = [
				{"tool": "drum", "side": "send", "text": "sanctus sanctus sanctus", "auto_sort": true},
				{"tool": "shelf", "side": "send", "input": "carry", "list": LISTC},
				{"tool": "bindery", "mode": "row", "symbols": "carry"}]
			s.ghosts = {"huffman": 63}
			s.story["crate"] = "Codex"
		_:
			return null
	s.story["house"] = HOUSES[s.chapter]
	s.story["chapter_name"] = CHAPTERS[s.chapter]
	if not s.story.has("zeno_intro"):
		s.story["zeno_intro"] = s.intro
	s.ghosts.merge(_ghosts(s), false)
	s.optimum = optimum(s)
	s.expect = _expect(s)
	return s


static func _meta(s: ScLevelSpec, title: String, ref: String, intro: String) -> void:
	s.title = title
	s.notes_ref = ref
	s.intro = intro


## Geesten: gewoon schrift (8 bits per teken; bij zegels/stempels: aantal tekens) en vaste lengte (Huffman).
static func _ghosts(s: ScLevelSpec) -> Dictionary:
	var g := {}
	var plain := 0
	var fixed := 0
	for st in s.stages:
		var tl := str(st.get("tool", ""))
		if str(st.get("side", "send")) == "receive":
			continue
		var tx := str(st.get("text", ""))
		match tl:
			"window", "stampcase":
				plain += tx.length()
			"bindery", "code_board":
				if tx != "":
					plain += 8 * tx.length()
					var k := ScReference.freqs_in_order(tx).size()
					fixed += _ceil_log2(k) * tx.length()
			"living_tree", "ruler":
				plain += 8 * tx.length()
	if s.id == "C":
		plain = 8 * 23
	if plain > 0:
		g["plain"] = plain
	if fixed > 0:
		g["fixed"] = fixed
	return g


static func _ceil_log2(k: int) -> int:
	var b := 0
	while (1 << b) < k:
		b += 1
	return maxi(1, b)


static func _expect(s: ScLevelSpec) -> Dictionary:
	var e := {}
	var reads: Array = []
	for st in s.stages:
		if st.has("expect"):
			reads.append(str(st.expect))
	e["copies"] = reads
	return e


# ------------------------------------------------------------------ fabriek

static func make_tool(stage: Dictionary, carry: Dictionary = {}) -> ScTool:
	var t: ScTool
	match str(stage.get("tool", "")):
		"prefix_read":
			t = ScPrefixReader.new()
		"code_board":
			t = ScCodeBoard.new()
		"bindery":
			t = ScBindery.new()
		"living_tree":
			t = ScLivingTree.new()
		"ruler":
			t = ScRuler.new()
		"window":
			t = ScWindow.new()
		"stampcase":
			t = ScStampCase.new()
		"drum":
			t = ScDrum.new()
		"shelf":
			t = ScShelf.new()
		"dovecote":
			t = ScDovecote.new()
		_:
			push_error("ScLevels.make_tool: onbekend werktuig %s" % str(stage.get("tool", "")))
			return null
	t.setup(stage, carry)
	return t


## Speelt alle stages met correct_move(). → {ink, twine, search, zeros, decisions, stages:[{ink, twine, search, zeros,
## decisions, output}]}. Gecachet per level-id (niet voor de Nachtwake).
static func optimum(spec: ScLevelSpec) -> Dictionary:
	if not spec.endless and _opt_cache.has(spec.id):
		return (_opt_cache[spec.id] as Dictionary).duplicate(true)
	var tot := {"ink": 0, "twine": 0, "search": 0, "zeros": 0, "decisions": 0, "stages": []}
	var carry := {}
	for st in spec.stages:
		var t := make_tool(st, carry)
		if t == null:
			continue
		t.begin()
		t.auto_finish()
		var c := t.counters
		for k in ["ink", "twine", "search", "zeros", "decisions"]:
			tot[k] = int(tot[k]) + int(c.get(k, 0))
		tot.stages.append({"ink": int(c.ink), "twine": int(c.twine), "search": int(c.search), "zeros": int(c.zeros),
			"decisions": int(c.decisions), "output": t.output(), "copy": t.copy()})
		carry = t.output()
	if not spec.endless:
		_opt_cache[spec.id] = tot.duplicate(true)
	return tot


# ------------------------------------------------------------------ ontsluiten

## Volgend level open met ≥ 1 ★ op het vorige P0-level van het hoofdstuk; een hoofdstuk open als alle P0-levels van het
## vorige hoofdstuk ≥ 1 ★ hebben; de Codex als alle P0-levels ≥ 1 ★ hebben. P1/P2 sluiten nooit iets af.
static func is_unlocked(id: String, stars: Dictionary) -> bool:
	if id == "nachtwake":
		return int(stars.get(NACHTWAKE_UNLOCK, 0)) >= 1
	if not ORDER.has(id):
		return false
	var spec_ch := 7 if id == "C" else int(id.substr(0, 1))
	if spec_ch == 7:
		for x in ORDER:
			if x != "C" and priority_of(x) == "P0" and int(stars.get(x, 0)) < 1:
				return false
		return true
	if spec_ch > 0:
		for x in ORDER:
			if x != "C" and int(x.substr(0, 1)) == spec_ch - 1 and priority_of(x) == "P0" and int(stars.get(x, 0)) < 1:
				return false
	var idx := ORDER.find(id)
	for q in range(idx - 1, -1, -1):
		var x: String = ORDER[q]
		if x == "C" or int(x.substr(0, 1)) != spec_ch:
			break
		if priority_of(x) == "P0":
			return int(stars.get(x, 0)) >= 1
	return true


static func priority_of(id: String) -> String:
	match id:
		"0-3", "1-4", "1-5", "4-5", "4-6", "5-5", "6-4", "C":
			return "P1"
		"6-5":
			return "P2"
	return "P0"


static func chapter_of(id: String) -> int:
	return 7 if id == "C" else int(id.substr(0, 1))


static func chapter_ids(ch: int) -> PackedStringArray:
	var out := PackedStringArray()
	for x in ORDER:
		if chapter_of(x) == ch:
			out.append(x)
	return out


# ------------------------------------------------------------------ Nachtwake

## Ronde r van de Nachtwake: de binderij (strikt: een fout paar knapt het touw) en elke 4e ronde een leesstrook.
static func endless_spec(round_index: int, seed_value: int) -> ScLevelSpec:
	var s := ScLevelSpec.new()
	s.id = "nachtwake"
	s.chapter = -1
	s.endless = true
	s.round_index = round_index
	s.seed_ = seed_value
	s.title = "Nachtwake · ronde %d" % (round_index + 1)
	s.intro = "Bind voor de kaars opbrandt."
	s.notes_ref = "Algoritme 9 · notas p. 84"
	var g := ScTextGen.new(seed_value).wake_round(round_index)
	var ws: Array = []
	for q in (g.letters as Array).size():
		ws.append([str(g.letters[q]), int(g.weights[q])])
	s.stages = [{"tool": "bindery", "mode": "row", "weights": ws, "strict": true, "round": round_index,
		"time": ScTextGen.round_time(round_index, ws.size())}]
	if str(g.read_text) != "":
		s.stages.append({"tool": "prefix_read", "text": str(g.read_text), "round": round_index,
			"time": 1.5 * float(str(g.read_text).length())})
	s.stars = []
	s.optimum = {"twine": ScReference.huffman_cost(ws)}
	return s
