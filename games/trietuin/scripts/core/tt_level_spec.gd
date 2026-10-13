class_name TtLevelSpec extends RefCounted
## Leveldata (GDD §5, §8.9). Alles is data; TtLevels vult de specs, TtDirector speelt ze.

var id: String = ""
var season: String = ""            # "lente" | "zomer" | "herfst" | "winter" | "finale" | "vrij"
var title: String = ""
var intro: String = ""             # één zin van de Uil
var notes_ref: String = ""         # bv. "Figuur 15 · notas p. 30"
var priority: String = "P0"        # "P0"|"P1"|"P2"
var kind: int = TtCodes.Kind.TRIE
var alphabet: String = "dna"
var start: String = "{}"           # notatie (in pos_base bij suffixbomen); "" = lege boom
var start_format: String = ""      # "" = notatie van kind; "trie" = gewone trie laden (snoeien/omzetten);
                                   # "built" = suffixboom opbouwen uit text (4-5)
var text: String = ""
var pos_base: int = 0
var labels: String = "pointers"
var owners_spec: Array = []        # [{name, from, to}] (veralgemeend; posities 0-gebaseerd, inclusief)
var mode: int = TtCodes.Mode.CALM
var letter_hint: int = TtCodes.Hint.FULL
var hint_full_cards: int = 0       # 3-2: de eerste k kaarten FULL, daarna letter_hint
var sap_budget: int = 0            # 0 = onbeperkt
var count_bumps: bool = false
var cards: Array[Dictionary] = []
var bloom_present: PackedStringArray = []
var bloom_absent: PackedStringArray = []
var stars: Array[Dictionary] = []  # 3 voorwaarden (★, ★★, ★★★); {"kind":"all","of":[…]} combineert
var expect_end: String = ""        # notatie van de optimale eindboom ("" = niet vastgelegd)
var optimum: Dictionary = {}       # {sap, comparisons, time_par} uit de GDD (TtLevels.optimum() rekent na)
var ghost: Dictionary = {}         # vergelijkingsgeest: {"label":"gewone trie","sap":48}
var hints_allowed: bool = true
var tutorial: Array[Dictionary] = []   # [{"trigger":"first_compare","ghost":{…},"text":"…"}]
var timeline: Array[Dictionary] = []   # [{"after_card":3,"event":"badges"}]
var generator: Dictionary = {}     # vrije tuin (§5.7)
var endless: bool = false
var extra: Dictionary = {}         # levelspecifieke weetjes voor de terugblik (bv. "did_you_know")


func owners_array() -> PackedInt32Array:
	var out := PackedInt32Array()
	if owners_spec.is_empty():
		return out
	out.resize(text.length())
	for i in text.length():
		out[i] = 0
	for k in owners_spec.size():
		var o: Dictionary = owners_spec[k]
		for i in range(int(o.from), int(o.to) + 1):
			if i < out.size():
				out[i] = k + 1
	return out


func owner_names() -> PackedStringArray:
	var out := PackedStringArray()
	for o in owners_spec:
		out.append(str(o.name))
	return out


## Letterhulp voor kaart k (0-gebaseerd).
func hint_for_card(k: int) -> int:
	if hint_full_cards > 0 and k < hint_full_cards:
		return TtCodes.Hint.FULL
	return letter_hint


func to_dict() -> Dictionary:
	return {"id": id, "season": season, "title": title, "intro": intro, "notes_ref": notes_ref, "priority": priority,
		"kind": kind, "alphabet": alphabet, "start": start, "start_format": start_format, "text": text,
		"pos_base": pos_base, "labels": labels, "owners_spec": owners_spec, "mode": mode, "letter_hint": letter_hint,
		"sap_budget": sap_budget, "count_bumps": count_bumps, "cards": cards, "bloom_present": Array(bloom_present),
		"bloom_absent": Array(bloom_absent), "stars": stars, "expect_end": expect_end, "optimum": optimum,
		"ghost": ghost, "hints_allowed": hints_allowed, "endless": endless}
