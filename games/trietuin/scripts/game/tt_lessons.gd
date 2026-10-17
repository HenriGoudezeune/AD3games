class_name TtLessons
extends Object
## Leerpad van Trietuin (games/trietuin/design/LEARNING_PATH.md, design/LEARNING.md): de delen in volgorde, per
## deel een Kijk- en een Samen-voorbeeld (als kleine TtLevelSpec), de verteltekst per stap (afgeleid van het
## orakel correct_move(), dus altijd juist), tips/foutuitleg voor Samen, voorspelvragen (Check in de wereld) en
## Check-vragen voor de terugblik op een nieuw, willekeurig voorbeeld (antwoord altijd berekend met de core).
## Pure logica + data: geen nodes (ook gebruikt in tests/suites/t_lessons.gd en tests/tt_lesson_trace.gd).

const SAVE_KEY := "learning"     # TtSave setting: {"zoeken": {"kijk": true, "samen": true, "check": true}, ...}
const K := TtCodes.Kind
const CK := TtCodes.CardKind
const P := TtCodes.Phase
const NT := TtNode.Type

const F14 := "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
const W16 := ["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"]
const T_SAMEN := "{A{C[AC_] G[AG_]} C[C_] G{A[GA_] T[GT_]}}"
const W_TSAMEN := ["GA_", "AC_", "C_", "AG_", "GT_"]
const KSD := "k[font_size=17]s[font_size=13]d[/font_size][/font_size]"

static func _seed(w: String) -> Dictionary:
	return {"kind": "seed", "word": w}


static func _bee(w: String) -> Dictionary:
	return {"kind": "bee", "word": w}


static func _prune(w: String) -> Dictionary:
	return {"kind": "prune", "word": w}


static func _suf(n: int) -> Array:
	var out := []
	for j in n:
		out.append({"kind": "suffix", "j": j})
	return out


static func _ask(z: String, q: String) -> Dictionary:
	return {"kind": "ask", "z": z, "q": q}


## Delen in volgorde. "levels" = de levels die de Zelf-fase zijn (het eerste level is de poort: vóór dat level moet
## het deel gedaan zijn). kijk/samen: velden voor de lesspec (kind, alphabet, start, start_format, text, labels,
## pos_base, owners_spec, cards, bloom_present) + lesopties: ask (voorspelvragen {on: act, nth, q}),
## auto (Samen: deze zetten doet de Uil zelf), from_it / until_it (Ukkonen: vooruitspoelen / stoppen).
static func parts() -> Array:
	return [
		{"id": "zoeken", "title": "Opzoeken in een trie", "levels": ["1-1"], "page": "Definitie 1 · p. 26–27",
			"rule": "Op diepte d volg je kind " + KSD + ". Een lege knop (NULL) = niet gevonden. Een vrucht = vergelijk het hele woord.",
			"idea": "Elke knoppenkrans is een interne top: één pointer per letter van A = {A, C, G, T, _}. Grijs knopje = NULL. Een vrucht is een blad met het woord als label. De wortel stelt ∅ voor.",
			"kijk": {"kind": K.TRIE, "alphabet": "dna", "start": TtLevels.F13, "cards": [_bee("TGG_"), _bee("ACCA_"), _bee("GA_")],
				"ask": [{"on": "move", "nth": 2, "q": "letter"}, {"on": "answer", "nth": 2, "q": "answer"}], "fig": "Figuur 13"},
			"samen": {"kind": K.TRIE, "alphabet": "dna", "start": F14, "cards": [_bee("TGCGAAA_"), _bee("AACT_"), _bee("TGGA_")], "fig": "Figuur 14"}},
		{"id": "toevoegen", "title": "Toevoegen: het eerste verschil j", "levels": ["1-1"], "page": "p. 27 · Figuur 13 → 14",
			"rule": "Lege knop: hang de vrucht daar. Vrucht l op diepte d: j = min{i ≥ d | l_i ≠ s_i}; groei een pad tot diepte j en hang beide vruchten.",
			"idea": "Toevoegen begint zoals opzoeken. Posities tellen vanaf 0: s = s_0 s_1 … s_k.",
			"kijk": {"kind": K.TRIE, "alphabet": "dna", "start": TtLevels.F13, "cards": [_seed("AAGCGA_"), _seed("GAT_")],
				"ask": [{"on": "split", "nth": 1, "q": "j"}], "fig": "Figuur 13 → 14"},
			"samen": {"kind": K.TRIE, "alphabet": "dna", "start": F14, "cards": [_seed("TGCGAAG_"), _seed("CAT_"), _seed("TAC_")], "fig": "Figuur 14"}},
		{"id": "verwijderen", "title": "Verwijderen (knippen)", "levels": ["1-2"], "page": "p. 27 · Oefening 17",
			"rule": "Zoek het blad op. Knip alle toppen op het pad weg na de laatste top met ten minste twee niet-lege kinderen.",
			"idea": "Te hoog knippen gooit andere woorden weg; te laag laat kale toppen staan (dood hout). Een top met nog één vrucht mag blijven staan: verwijderen schuift niets op (enkel als alleen de wortel overblijft, wordt die een blad met ∅).",
			"kijk": {"kind": K.TRIE, "alphabet": "dna", "start": F14, "cards": [_prune("TGCGAAA_"), _prune("AAGCGA_")],
				"ask": [{"on": "cut", "nth": 1, "q": "cut"}], "fig": "Figuur 14"},
			"samen": {"kind": K.TRIE, "alphabet": "dna", "start": TtLevels.F13, "cards": [_prune("TA_"), _prune("ACGT_")], "fig": "Figuur 13"}},
		{"id": "geheugen", "title": "Geheugen: lege pointers", "levels": ["1-3"], "page": "p. 27–28 · Oefening 18",
			"rule": "Elke interne top is een array van |A| pointers, ook de lege. Een late j laat j − d + 1 nieuwe toppen groeien.",
			"idea": "Sap = geheugen: elke knoppenkrans kost |A| = 5 pointers, hoeveel er ook leeg (NULL) zijn.",
			"kijk": {"kind": K.TRIE, "alphabet": "dna", "start": "{}", "cards": [_seed("ACGTA_"), _seed("ACGTC_"), _seed("AG_")],
				"ask": [{"on": "split", "nth": 1, "q": "tops"}]},
			"samen": {"kind": K.TRIE, "alphabet": "dna", "start": "{}", "cards": [_seed("GATTACA_"), _seed("GATTAG_"), _seed("GAC_")]}},
		{"id": "snoeien", "title": "Patricia: snoeien en skip", "levels": ["2-1", "2-4"], "page": "p. 28–30 · Figuur 15",
			"rule": "Een top met maar één kind mag weg. Is zijn kind een top, dan krijgt die skip = skip(kind) + skip(top) + 1.",
			"idea": "Patricia: elke interne top vertakt; het getal skip op de jaarring zegt hoeveel letters je daar overslaat.",
			"kijk": {"kind": K.PATRICIA, "alphabet": "dna", "start": TtLevels.F15, "start_format": "trie", "cards": [{"kind": "patricify"}],
				"ask": [{"on": "prune", "nth": 1, "q": "skip"}], "fig": "Figuur 15"},
			"samen": {"kind": K.PATRICIA, "alphabet": "dna", "start": "{A{C{G{A[ACGA_] T[ACGT_]}}} G[GA_] T{T{A[TTA_] C[TTC_]}}}",
				"start_format": "trie", "cards": [{"kind": "patricify"}]}},
		{"id": "pzoeken", "title": "Patricia: zoeken (Algoritme 1)", "levels": ["2-1", "2-2", "2-4"], "page": "p. 29 · Algoritme 1",
			"rule": "next = next + skip + 1; lees s[next − 1]. Is next + skip > m: te kort. In de vrucht: vergelijk het hele woord.",
			"idea": "m = index van de laatste letter (s = s_0 … s_m). Overgeslagen letters controleer je pas in het blad.",
			"kijk": {"kind": K.PATRICIA, "alphabet": "dna", "start": TtLevels.F15P, "cards": [_bee("CGCGAA_"), _bee("CACCCT_"), _bee("GG_")],
				"ask": [{"on": "read", "nth": 2, "q": "pos"}, {"on": "answer", "nth": 2, "q": "answer"}], "fig": "Figuur 15 (Patricia)"},
			"samen": {"kind": K.PATRICIA, "alphabet": "dna", "start": TtLevels.F17P, "cards": [_bee("GGCGTA_"), _bee("CTACCC_"), _bee("G_")]}},
		{"id": "enten", "title": "Patricia: toevoegen (enten)", "levels": ["2-3"], "page": "p. 29",
			"rule": "Daal af met Algoritme 1. Stop je (lege knop, te kort, vrucht), kies een vrucht eronder, vergelijk vanaf 0: op diepte j ent je.",
			"idea": "Alle vruchten onder een top delen de overgeslagen letters: daarmee reconstrueer je ze.",
			"kijk": {"kind": K.PATRICIA, "alphabet": "dna", "start": TtLevels.F15P, "cards": [_seed("CGTA_"), _seed("GGCA_")],
				"ask": [{"on": "split", "nth": 1, "q": "j"}], "fig": "Figuur 15 (Patricia)"},
			"samen": {"kind": K.PATRICIA, "alphabet": "dna", "start": TtLevels.F15P, "cards": [_seed("CA_"), _seed("GAT_"), _seed("CGCCCA_")]}},
		{"id": "ternary", "title": "Ternary trie: rankknopen", "levels": ["3-1", "3-3"], "page": "p. 30–31 · Figuur 16",
			"rule": "Vergelijk s_d met de bol: kleiner = links, groter = rechts (zelfde top); gelijk = midden naar het kind en d + 1.",
			"idea": "Elke top wordt een klein zoekboompje van letterbollen: enkel letters die echt gebruikt worden. Wie eerst geplant wordt, staat bovenaan.",
			"kijk": {"kind": K.TERNARY, "alphabet": "dna", "start": TtLevels.F16, "start_format": "trie",
				"cards": [{"kind": "ternarify"}, _bee("CGGA_"), _bee("TA_")], "bloom_present": W16,
				"ask": [{"on": "go", "nth": 2, "q": "dir"}], "fig": "Figuur 16"},
			"samen": {"kind": K.TERNARY, "alphabet": "dna", "start": T_SAMEN, "start_format": "trie",
				"cards": [{"kind": "ternarify"}, _bee("GT_"), _bee("AT_")], "bloom_present": W_TSAMEN}},
		{"id": "ttoevoegen", "title": "Ternary trie: toevoegen", "levels": ["3-2", "3-4"], "page": "p. 31–32 · Oefening 20",
			"rule": "Zoek zoals opzoeken. Eindigt het bij een lege rank, dan groeit daar een nieuwe bol. Elke bol kost 3 pointers.",
			"idea": "Groot alfabet (a–z): een gewone top zou 27 pointers kosten, een bol maar 3.",
			"kijk": {"kind": K.TERNARY, "alphabet": "az", "start": "", "cards": [_seed("kip_"), _seed("kat_"), _seed("ree_"), _seed("kar_"), _bee("kar_")],
				"ask": [{"on": "go", "nth": 3, "q": "dir"}]},
			"samen": {"kind": K.TERNARY, "alphabet": "az", "start": "", "cards": [_seed("mol_"), _seed("das_"), _seed("mus_"), _seed("muis_"), _bee("mus_")]}},
		{"id": "suffixboom", "title": "Suffixboom: alle suffixen", "levels": ["4-1"], "page": "§3.2 · p. 32–33 · Figuur 18",
			"rule": "Volg suffix σ_j vanaf de wortel tot waar het afwijkt. Op een top: nieuwe tak. Midden in een boog: splits de boog.",
			"idea": "De suffixboom bevat alle suffixen van de tekst (afgesloten met _) en niets anders. Zoals Patricia: geen toppen met één kind; de strings staan aan de bogen.",
			"kijk": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "acacacgt_", "labels": "strings", "cards": _suf(6),
				"ask": [{"on": "attach", "nth": 3, "q": "attach"}], "fig": "Figuur 18"},
			"samen": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "catcat_", "labels": "strings", "cards": _suf(7)}},
		{"id": "labels", "title": "Suffixboom: (b,e)-labels", "levels": ["4-2"], "page": "p. 33–34 · Figuur 19",
			"rule": "Een boog bewaart enkel (b,e): begin- en eindpositie in de tekst. Nieuwe bladboog vanuit diepte l voor σ_j: b = j + l, e = n.",
			"idea": "Strings aan de bogen kosten Θ(n²) geheugen; twee getallen per boog maar Θ(n).",
			"kijk": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "acacacgt_", "labels": "pointers", "cards": _suf(6),
				"ask": [{"on": "label", "nth": 3, "q": "b"}], "fig": "Figuur 19"},
			"samen": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "catcat_", "labels": "pointers", "cards": _suf(7)}},
		{"id": "szoeken", "title": "Suffixboom: zoeken, tellen, positie b − l_t", "levels": ["4-3", "4-4"], "page": "§3.3 · p. 48–49 · Oef. 28–29",
			"rule": "Volg z vanaf de wortel (O(m)). Positie = b − l_t (boog met het laatste teken van z, top t erboven). Aantal = vruchten eronder.",
			"idea": "l_t = lengte van de string van top t (de toppen tonen hun diepte). Ukkonen kiest b altijd direct na de string van t.",
			"kijk": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "acacacgt_", "labels": "pointers", "start": TtLevels.F19U,
				"cards": [_ask("aca", "where"), _ask("ca", "count"), _ask("cg", "where"), _ask("acc", "exists")],
				"ask": [{"on": "where", "nth": 2, "q": "where"}, {"on": "count", "nth": 1, "q": "count"}], "fig": "Figuur 19"},
			"samen": {"kind": K.SUFFIX, "alphabet": "dna_lower", "text": "catcat_", "labels": "pointers", "start_format": "built",
				"cards": [_ask("tca", "where"), _ask("at", "count"), _ask("cg", "exists"), _ask("t", "all")]}},
		{"id": "veralg", "title": "Veralgemeende suffixboom", "levels": ["4-5"], "page": "p. 49",
			"rule": "Teksten achter elkaar, elk met een eigen afsluitteken. Volg z; de eigenaars van de vruchten eronder zijn de teksten waarin z staat.",
			"idea": "De onechte veralgemeende suffixboom bevat ook suffixen met een afsluitteken in het midden, maar daar zoek je nooit naar.",
			"kijk": {"kind": K.SUFFIX, "alphabet": "dna_lower_multi3", "text": "gatca1tcag2", "labels": "pointers", "start_format": "built",
				"owners_spec": [{"name": "Mol", "from": 0, "to": 5}, {"name": "Merel", "from": 6, "to": 10}],
				"cards": [_ask("atc", "owner"), _ask("ca", "owner"), _ask("cag", "owner")],
				"ask": [{"on": "owner", "nth": 2, "q": "owner"}]},
			"samen": {"kind": K.SUFFIX, "alphabet": "dna_lower_multi3", "text": "tagc1gcat2", "labels": "pointers", "start_format": "built",
				"owners_spec": [{"name": "Mol", "from": 0, "to": 4}, {"name": "Merel", "from": 5, "to": 9}],
				"cards": [_ask("gc", "owner"), _ask("ag", "owner"), _ask("cat", "owner")]}},
		{"id": "ukk_regels", "title": "Ukkonen: S(1,i) en de regels", "levels": ["5-1"], "page": "§3.2.1 · p. 34–39, 43–45",
			"rule": "Iteratie i voegt s_i toe aan elk suffix σ_j. Bladeren groeien vanzelf (e = it). Na σ: geen vervolg met s_i → (ii) nieuw blad of (iii) boog splitsen; zit het er al → (a)/(b): stop de iteratie.",
			"idea": "S(1,i) = boom van alle deelstrings van s_1 … s_i. Eens blad, altijd blad; na een stop zitten ook alle kortere suffixen er al in (Lemma 5).",
			"kijk": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abacabc_", "pos_base": 1, "cards": [{"kind": "ukkonen"}],
				"until_it": 5, "ask": [{"on": "rule", "nth": 3, "q": "rule"}, {"on": "rule", "nth": 4, "q": "rule"}], "fig": "abacabc_, p. 44–45"},
			"samen": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abab_", "pos_base": 1, "cards": [{"kind": "ukkonen"}],
				"auto": ["follow", "link", "hop"]}},
		{"id": "ukk_wijzer", "title": "Ukkonen: de wijzer (p̄, x̄)", "levels": ["5-1"], "page": "p. 40–42",
			"rule": "Na een nieuw blad: is p de wortel, dan x̄ = x − 1; anders p̄ = l(p), x̄ = x. Is x̄ ≥ de lengte van de boog: spring naar de top eronder.",
			"idea": "De wijzer (p̄, x̄) staat op het einde van σ_{j,i}: top p̄ en nog x̄ tekens verder. Na een stop blijft p en wordt x̄ = x + 1.",
			"kijk": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abacabc_", "pos_base": 1, "cards": [{"kind": "ukkonen"}],
				"from_it": 6, "ask": [{"on": "hop", "nth": 1, "q": "hop"}, {"on": "follow", "nth": 1, "q": "follow"}], "fig": "abacabc_, p. 46–48"},
			"samen": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abaab_", "pos_base": 1, "cards": [{"kind": "ukkonen"}],
				"auto": ["link"]}},
		{"id": "ukk_links", "title": "Ukkonen: suffix links", "levels": ["5-1", "5-2", "5-3"], "page": "p. 40, 43",
			"rule": "Een nieuwe interne top voor s_j … s_i krijgt een suffix link naar de top van s_{j+1} … s_i (zonder de eerste letter); die vind je in de volgende extensie.",
			"idea": "Zo spring je in O(1) naar het volgende suffix in plaats van opnieuw vanaf de wortel te zoeken.",
			"kijk": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abcabca_", "pos_base": 1, "cards": [{"kind": "ukkonen"}],
				"from_it": 8, "ask": [{"on": "link", "nth": 2, "q": "link"}]},
			"samen": {"kind": K.UKKONEN, "alphabet": "abc_lower", "text": "abbab_", "pos_base": 1, "cards": [{"kind": "ukkonen"}]}},
	]


static var _parts_cache: Array = []


static func all_parts() -> Array:
	if _parts_cache.is_empty():
		_parts_cache = parts()
	return _parts_cache


static func part(id: String) -> Dictionary:
	for p in all_parts():
		if p.id == id:
			return p
	return {}


static func index_of_part(id: String) -> int:
	var ps := all_parts()
	for i in ps.size():
		if ps[i].id == id:
			return i
	return -1


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for p in all_parts():
		out.append(str(p.id))
	return out


## Delen waarvan `level` het eerste Zelf-level (de poort) is.
static func parts_for_level(level: String) -> Array:
	var out := []
	for p in all_parts():
		if (p.levels as Array).size() > 0 and str(p.levels[0]) == level:
			out.append(p.id)
	return out


## Delen die bij `level` horen (eerste of latere Zelf-level): badges op de kaart, Check in de terugblik.
static func parts_of_level(level: String) -> Array:
	var out := []
	for p in all_parts():
		if (p.levels as Array).has(level):
			out.append(p.id)
	return out


## Check in de terugblik van `level`: 1–2 delen (de nieuwe delen van dat level, anders de delen die het oefent).
static func report_parts(level: String) -> Array:
	var ps := parts_for_level(level)
	if ps.is_empty():
		ps = parts_of_level(level)
	if ps.is_empty() and level == "1-4":
		ps = ["zoeken"]
	if ps.size() > 2:
		ps = ps.slice(ps.size() - 2)
	return ps


## Lessen die vóór `level` nog moeten (eerste keer verplicht): elk deel waarvan de poort ≤ level ligt en Samen nog
## niet gedaan is -> [{part, phase}] (kijk dan samen, in volgorde van het leerpad).
static func pending_for_level(level: String) -> Array:
	var order: Array = Array(TtLevels.IDS)
	var li := order.find(level)
	if level == "endless":
		li = order.find("1-1")
	if li < 0:
		return []
	var out := []
	for p in all_parts():
		var gate: int = order.find(str(p.levels[0]))
		if gate < 0 or gate > li:
			continue
		if is_done(p.id, "samen"):
			continue
		if not is_done(p.id, "kijk"):
			out.append({"part": p.id, "phase": "kijk"})
		out.append({"part": p.id, "phase": "samen"})
	return out


# ======================================================================
#  voortgang (TtSave setting "learning")
# ======================================================================

static func progress(id: String) -> Dictionary:
	var d = TtSave.setting(SAVE_KEY, {})
	if d is Dictionary and (d as Dictionary).get(id) is Dictionary:
		return d[id]
	return {}


static func mark(id: String, key: String, value := true) -> void:
	var d = TtSave.setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	var e: Dictionary = d.get(id, {}) if d.get(id) is Dictionary else {}
	e[key] = value
	d[id] = e
	TtSave.set_setting(SAVE_KEY, d)


static func reset_progress() -> void:
	TtSave.set_setting(SAVE_KEY, {})


static func is_done(id: String, phase: String) -> bool:
	return bool(progress(id).get(phase, false))


## 0 = nog niets, 1 = demo bekeken, 2 = samen geoefend, 3 = begrepen (samen + check juist).
static func level(id: String) -> int:
	var p := progress(id)
	if bool(p.get("check", false)) and bool(p.get("samen", false)):
		return 3
	if bool(p.get("samen", false)):
		return 2
	if bool(p.get("kijk", false)):
		return 1
	return 0


# ======================================================================
#  lesspec
# ======================================================================

static func cfg(id: String, phase: String) -> Dictionary:
	return part(id).get(phase, {})


static func spec(id: String, phase: String) -> TtLevelSpec:
	var p := part(id)
	if p.is_empty():
		return null
	var c: Dictionary = p.get(phase, {})
	var lvl := str(p.levels[0])
	var gate := TtLevels.get_spec(lvl)
	var d := {"id": "les:%s:%s" % [id, phase], "season": gate.season if gate else "lente",
		"title": "%s · %s" % ["Kijk" if phase == "kijk" else "Samen", p.title], "priority": "P0",
		"notes_ref": "lesnotas " + str(p.page), "kind": int(c.kind), "alphabet": str(c.alphabet),
		"start": str(c.get("start", "{}")), "start_format": str(c.get("start_format", "")), "text": str(c.get("text", "")),
		"pos_base": int(c.get("pos_base", 0)), "labels": str(c.get("labels", "pointers")),
		"owners_spec": c.get("owners_spec", []), "mode": TtCodes.Mode.CALM,
		"letter_hint": TtCodes.Hint.FULL if phase == "kijk" else TtCodes.Hint.CURSOR, "sap_budget": 0,
		"cards": c.cards, "stars": [TtLevels.S_DONE], "bloom_present": c.get("bloom_present", []), "bloom_absent": []}
	if int(c.kind) == K.SUFFIX and str(c.get("start", "")) == "" and str(c.get("start_format", "")) == "":
		d["start"] = "{}"
	return TtLevels._spec(d)


## Model zoals de les start (kaarten nog niet begonnen), voor tests en de trace.
static func make_model(id: String, phase: String) -> TtTreeModel:
	return TtLevels.make_model(spec(id, phase))


# ======================================================================
#  opmaak
# ======================================================================

static func code(s: String) -> String:
	return "[code]%s[/code]" % (s if s != "" else "∅")


static func sub(s: String) -> String:
	return "[font_size=17]%s[/font_size]" % s


static var _sub_re: RegEx = null


## Schrijfwijze l_i, s_{j+1}, σ_j, l_t in de teksten -> echte (kleine) indices zoals in de notas.
static func subs(s: String) -> String:
	if not s.contains("_"):
		return s
	if _sub_re == null:
		_sub_re = RegEx.create_from_string("(?<![A-Za-z0-9_\\]])([a-zσ])_(\\{[^}]*\\}|[a-z0-9]{1,2})(?![A-Za-z0-9_])")
	var out := ""
	var at := 0
	for m in _sub_re.search_all(s):
		out += s.substr(at, m.get_start() - at) + m.get_string(1) + sub(m.get_string(2).trim_prefix("{").trim_suffix("}"))
		at = m.get_end()
	return out + s.substr(at)


## Woord met letter op index i oranje gemarkeerd.
static func mark_at(s: String, i: int) -> String:
	if i < 0 or i >= s.length():
		return code(s)
	return "[code]%s[color=#FFB020][b]%s[/b][/color]%s[/code]" % [s.substr(0, i), s[i], s.substr(i + 1)]


static func _u(s: String) -> String:
	return "∅" if s == "" else s


static func _pstr(m: TtTreeModel, id: int) -> String:
	if id < 0:
		return ""
	if m.has_method("path_string"):
		return str(m.call("path_string", id))
	return ""


static func _top(m: TtTreeModel, id: int) -> String:
	if id == m.root:
		return "de wortel (∅)"
	return "top " + code(_pstr(m, id))


static func _disp(m: TtTreeModel, p: int) -> int:
	if m.has_method("display_pos"):
		return int(m.call("display_pos", p))
	return p


# ======================================================================
#  toestand zoals op het examen (één regel, notatie van de notas)
# ======================================================================

static func state_line(m: TtTreeModel) -> String:
	var c := m.cursor()
	var cd := m.card
	match m.kind:
		K.TRIE:
			var s := ""
			if cd != null and m.phase in [P.WALK, P.COMPARE, P.AT_LEAF, P.CUT]:
				var verb: String = {CK.SEED: "voeg toe", CK.BEE: "zoek", CK.PRUNE: "verwijder"}.get(cd.kind, "")
				s = "%s s = %s · d = %d · " % [verb, code(str(c.word)), int(c.depth)]
			var tops := m.count_type(NT.INNER)
			var a := m.alphabet.letters.size()
			return s + "%d interne toppen × |A| = %d pointers (%d niet-NULL)" % [tops, tops * a, m.nodes.size() - 1]
		K.PATRICIA:
			if cd != null and m.phase in [P.WALK, P.COMPARE, P.AT_LEAF, P.PICK_LEAF]:
				var s2 := "s = %s, m = %d · next = %d" % [code(str(c.word)), int(c.m), int(c.next)]
				if m.phase == P.WALK:
					s2 += " · skip = %d" % int(c.skip)
				return s2
			return "%d interne toppen (elk |A| pointers + skip)" % m.count_type(NT.INNER)
		K.TERNARY:
			if cd != null and m.phase in [P.WALK, P.COMPARE, P.AT_LEAF]:
				var w := str(c.word)
				var d := int(c.depth)
				return "s = %s · d = %d (s%s = %s) · %d bollen × 3 pointers" % [code(w), d, sub(str(d)),
					code(w[d] if d < w.length() else ""), m.count_type(NT.BALL)]
			return "%d letterbollen × 3 pointers = %d" % [m.count_type(NT.BALL), m.count_type(NT.BALL) * 3]
		K.SUFFIX:
			var sm := m as TtSuffixTree
			var t := "t = %s" % code(sm.text)
			if cd != null and cd.kind == CK.SUFFIX:
				var j := int(c.j)
				t += " · suffix σ%s = %s (j = %d)" % [sub(str(sm.display_pos(j))), code(sm.text.substr(j)), sm.display_pos(j)]
				if m.phase == P.LABEL:
					t += " · afwijkpunt op diepte l = %d" % int(c.l)
			elif cd != null and cd.kind == CK.ASK:
				t += " · z = %s (m = %d)" % [code(str(c.z)), str(c.z).length()]
			return t
		K.UKKONEN:
			var um := m as TtUkkonen
			if um.finished or cd == null:
				return "suffixboom van %s klaar" % code(um.text)
			var it := um.it
			var sig := um.text.substr(um.j - 1, it - um.j)
			return "it = %d (s%s = %s) · S(1,%d) → S(1,%d) · extensie j = %d: σ%s = %s + %s · wijzer (p̄, x̄) = (%s, %d)" % [
				it, sub(str(it)), code(um.text[it - 1]), it - 1, it, um.j, sub("%d,%d" % [um.j, it - 1]), code(sig),
				code(um.text[it - 1]), code(_u(um.node_string(um.p))), um.x]
	return ""


# ======================================================================
#  verteltekst (Kijk) — afgeleid van het model, dus altijd juist. -> {what, why} (BBCode, max. 2 zinnen elk)
# ======================================================================

static func narrate(m: TtTreeModel, mv: Dictionary) -> Dictionary:
	var act := str(mv.get("act", ""))
	var c := m.cursor()
	match act:
		"move":
			return _n_move(m, mv, c)
		"split":
			return _n_split(m, mv, c)
		"same":
			return {"what": "%s zit er al in de boom." % code(str(c.word)), "why": "Hetzelfde woord: niets toevoegen."}
		"answer":
			var lf := m.node(int(c.leaf))
			var w := str(c.word)
			if bool(mv.found):
				return {"what": "Vrucht %s = %s: gevonden. Pluk!" % [code(lf.label), code(w)],
					"why": "In het blad vergelijk je het hele woord met het label."}
			var j0 := TtTrie.first_diff(lf.label, w, 0)
			return {"what": "Vrucht %s ≠ %s (verschil op positie %d): niet gevonden." % [mark_at(lf.label, j0), mark_at(w, j0), j0],
				"why": "Een vrucht bereiken is nog niet vinden: het label moet exact gelijk zijn." + (" Patricia sloeg letters over zonder ze te bekijken." if m.kind == K.PATRICIA else "")}
		"cut":
			var cut := int(mv.node)
			var par := m.node(cut).parent
			var u := _pstr(m, par)
			return {"what": "Knip net onder %s: de tak naar %s met alles eronder valt weg." % [_top(m, par), code(_pstr(m, cut))],
				"why": "Na %s (de laatste top met ten minste twee niet-lege kinderen) hangt enkel nog dit woord. De andere vruchten blijven waar ze hangen: er wordt niets naar boven geschoven." % code(_u(u))}
		"read":
			return _n_read(m, mv, c)
		"short":
			var tp := m.node(int(c.node))
			var why_s := "Alle woorden die je vanaf hier bereikt zijn langer: niet gevonden (Algoritme 1)."
			if m.card != null and m.card.kind == CK.SEED:
				why_s = "Toevoegen: stop met afdalen. Het nieuwe woord hoort hier of hoger; kies een vrucht om j te vinden."
			return {"what": "next + skip = %d + %d = %d > m = %d: het woord is te kort." % [int(c.next), tp.skip, int(c.next) + tp.skip, int(c.m)],
				"why": why_s}
		"pick_leaf":
			var lf2 := m.node(int(mv.leaf))
			return {"what": "Kies een vrucht onder %s, bv. %s, om de overgeslagen letters te lezen." % [_top(m, int(c.node)), code(lf2.label)],
				"why": "Alle vruchten onder deze top delen de letters die Patricia oversloeg (notas p. 29)."}
		"prune":
			var u2 := int(mv.node)
			var kids := m.children(u2)
			var t := "Top %s heeft maar één kind: snoei hem weg." % code(_pstr(m, u2))
			if kids.size() == 1 and m.node(kids[0]).type == NT.INNER:
				var kn := m.node(kids[0])
				t += " Zijn kind krijgt skip = %d + %d + 1 = %d." % [kn.skip, m.node(u2).skip, kn.skip + m.node(u2).skip + 1]
			return {"what": t, "why": "In een Patricia trie vertakt elke interne top; skip telt de letters zonder vertakking."}
		"prune_done":
			return {"what": "Geen enkele top met maar één kind meer: klaar met snoeien.", "why": "Dit is de Patricia trie: elke top vertakt."}
		"go":
			return _n_go(m, mv, c)
		"place":
			var pn := int(c.get("placing_node", -1))
			var rem: PackedStringArray = c.get("remaining", PackedStringArray())
			var ptxt := _pstr(m, pn) if pn >= 0 else ""
			return {"what": "Rankknoop van top %s: plant %s (nog te planten: %s)." % [code(_u(ptxt)), code(str(mv.letter)), " ".join(rem)],
				"why": "Wie eerst geplant wordt, staat bovenaan; de rest gaat links (kleiner) of rechts (groter). Deze volgorde geeft de minste vergelijkingen."}
		"attach":
			return _n_attach(m, mv, c)
		"label":
			var sm := m as TtSuffixTree
			var j := int(c.j)
			var l := int(c.l)
			var b := int(mv.b)
			return {"what": "Nieuwe bladboog vanuit diepte l = %d voor σ%s: b = j + l = %d + %d = %d, e = %d → (%d,%d) = %s." % [
				l, sub(str(sm.display_pos(j))), sm.display_pos(j), l, sm.display_pos(b), sm.display_pos(sm.n), sm.display_pos(b), sm.display_pos(sm.n), code(sm.text.substr(b))],
				"why": "Het suffix begint op j; de eerste l tekens zitten al in de boom, dus de boog begint op j + l."}
		"locate":
			var sm2 := m as TtSuffixTree
			var z := str(c.z)
			var pt := sm2.canon({"node": int(mv.node), "off": int(mv.get("off", 0))})
			var where := "op een top" if int(pt.off) == 0 else "midden in een boog"
			return {"what": "Volg z = %s vanaf de wortel: het eindigt %s." % [code(z), where],
				"why": "Zoeken in een suffixboom = de tekens van z volgen: O(m), onafhankelijk van de tekstlengte."}
		"absent":
			var sm3 := m as TtSuffixTree
			var z2 := str(c.z)
			var lw := sm3.walk(z2)
			var u3 := z2.substr(0, int(lw.matched))
			var nx := str(lw.x)
			var after := "volgt in de boom %s, niet %s" % [code(nx), code(str(lw.c))]
			if nx == "":
				var ks: Array = []
				for kk in sm3.alphabet.sorted(sm3.node(int(lw.node)).kids.keys()):
					ks.append(str(kk))
				after = "beginnen de takken met %s, geen met %s" % ["/".join(ks), code(str(lw.c))]
			return {"what": "Na %s %s: z = %s komt niet voor." % [code(_u(u3)), after, code(z2)],
				"why": "Elke deelstring van de tekst is een prefix van een suffix: kom je niet verder, dan staat z nergens."}
		"where":
			var sm4 := m as TtSuffixTree
			var loc := sm4.locate_auto(str(c.z))
			if str(c.q) == "first":
				return {"what": "Eerste voorkomen van %s: positie %d." % [code(str(c.z)), sm4.display_pos(int(mv.pos))], "why": "Ukkonen kiest b altijd zo dat b − l_t het eerste voorkomen is (Oef. 28a)."}
			return {"what": "Het laatste teken van %s zit in de boog (%d,%d) onder een top met l_t = %d: positie b − l_t = %d − %d = %d." % [
				code(str(c.z)), sm4.display_pos(int(loc.b)), sm4.display_pos(int(loc.e)), int(loc.l_t), sm4.display_pos(int(loc.b)), int(loc.l_t), sm4.display_pos(int(loc.pos))],
				"why": "Op positie b − l_t begint een kopie van de string van t, gevolgd door de tekens van de boog (notas p. 48)."}
		"count":
			return {"what": "Onder het punt hang%s %d vrucht%s: %s komt %d keer voor." % ["t" if int(mv.n) == 1 else "en", int(mv.n), "" if int(mv.n) == 1 else "en", code(str(c.z)), int(mv.n)],
				"why": "Elke vrucht eronder is een suffix dat met z begint = één voorkomen (Oef. 29)."}
		"pick":
			var sm5 := m as TtSuffixTree
			var loc2 := sm5.locate_auto(str(c.z))
			var ps: Array = []
			for s in loc2.starts:
				ps.append(str(sm5.display_pos(int(s))))
			return {"what": "Alle vruchten onder het punt: %s staat op posities %s." % [code(str(c.z)), ", ".join(ps)],
				"why": "k voorkomens = k bladeren onder het punt: O(m + k) (Oef. 28b)."}
		"owner":
			var sm6 := m as TtSuffixTree
			var names: Array = []
			for k in mv.texts:
				names.append(sm6.owner_name(int(k)))
			return {"what": "De vruchten onder het punt horen bij: %s." % ", ".join(names),
				"why": "Elk blad weet van welke tekst zijn suffix is; die teksten bevatten z."}
		"rule":
			return _n_rule(m, mv)
		"hop":
			var um := m as TtUkkonen
			var k := int(mv.node)
			var L := um.edge_len(k)
			return {"what": "x̄ = %d ≥ lengte %d van de boog %s: spring naar top %s, x̄ = %d − %d = %d." % [um.x, L, code(um.edge_string(k)), code(um.node_string(k)), um.x, L, um.x - L],
				"why": "De wijzer moet op de laatste top vóór de positie staan. Je kijkt enkel naar het eerste teken en de lengte van de boog."}
		"follow":
			var um2 := m as TtUkkonen
			if str(mv.mode) == "minus":
				return {"what": "p = de wortel: x̄ = x − 1 = %d. Volgende extensie j = %d." % [um2.x - 1, um2.j + 1],
					"why": "σ%s is σ%s zonder de eerste letter; aan de wortel valt die letter weg uit het x-deel." % [sub("j+1"), sub("j")]}
			var ln := um2.node(um2.p).link
			return {"what": "Volg de suffix link: p̄ = l(%s) = %s, x̄ = x = %d. Volgende extensie j = %d." % [code(um2.node_string(um2.p)), code(_u(um2.node_string(ln))), um2.x, um2.j + 1],
				"why": "l(p) stelt de string van p zonder de eerste letter voor: zo vind je σ%s zonder van de wortel te zoeken." % sub("j+1")}
		"link":
			var um3 := m as TtUkkonen
			var fr := um3.node_string(um3.pending)
			var to := um3.node_string(int(mv.node))
			return {"what": "De nieuwe top %s krijgt een suffix link naar %s." % [code(fr), code(_u(to))],
				"why": "Suffix link: van s_j … s_i naar s_{j+1} … s_i, dezelfde string zonder de eerste letter."}
		"bed":
			return {"what": "Bed %d: %s." % [int(mv.bed) + 1, "array van pointers" if str(mv.choice) == "array" else "ternary trie"], "why": "Tel de pointers: |A| per top tegen 3 per bol."}
	return {"what": str(mv), "why": ""}


static func _n_move(m: TtTreeModel, mv: Dictionary, c: Dictionary) -> Dictionary:
	var d := int(c.depth)
	var w := str(c.word)
	var nid := int(c.node)
	var letter := str(mv.letter)
	var n := m.node(nid)
	var kid := int(n.kids.get(letter, -1))
	var what := "Diepte d = %d: s%s = %s, volg knop %s van %s." % [d, sub(str(d)), code(letter), code(letter), _top(m, nid)]
	var why := "Op diepte d volg je kind %s: de vertakking hangt af van de letter (Definitie 1)." % KSD
	var ck := m.card.kind if m.card != null else CK.BEE
	if kid < 0:
		what = "Diepte d = %d: s%s = %s, maar knop %s van %s is leeg (NULL)." % [d, sub(str(d)), code(letter), code(letter), _top(m, nid)]
		if ck == CK.SEED:
			why = "Toevoegen: is %s NULL, dan hang je daar een nieuw blad met label %s." % [KSD, code(w)]
		else:
			why = "Opzoeken stopt bij een NULL-pointer: %s zit niet in de trie." % code(w)
	elif m.node(kid).type == NT.LEAF:
		what += " Daar hangt de vrucht %s." % code(m.node(kid).label)
		if ck == CK.SEED:
			why = "Een blad op diepte %d: vergelijk %s met %s om j te vinden." % [d + 1, code(m.node(kid).label), code(w)]
		elif ck == CK.PRUNE:
			why = "Dat is het blad van %s: nu kies je waar je knipt." % code(w)
		else:
			why = "Een blad bereiken is nog niet vinden: vergelijk het hele woord met het label."
	return {"what": what, "why": why}


static func _n_split(m: TtTreeModel, mv: Dictionary, c: Dictionary) -> Dictionary:
	var l := str(c.get("label", ""))
	var w := str(c.word)
	var j := int(mv.j)
	if m.kind == K.PATRICIA:
		return {"what": "Vergelijk %s met de vrucht %s vanaf positie 0: eerste verschil op j = %d (%s tegen %s)." % [mark_at(w, j), mark_at(l, j), j, code(w[j]), code(l[j])],
			"why": "Tot j zijn ze gelijk, ook in de overgeslagen letters. Op diepte j komt een nieuwe top; de skips worden herrekend."}
	var d := int(c.depth)
	var tops := j - d + 1
	var why := "j = min{i ≥ d | l_i ≠ s_i}. Het blad wordt een top en er groeit een pad tot diepte j: %d nieuwe top%s." % [tops, "" if tops == 1 else "pen"]
	if m.kind == K.TRIE:
		why += " Dat kost %d × |A| = %d pointers." % [tops, tops * m.alphabet.letters.size()]
	elif m.kind == K.TERNARY:
		why = "j = min{i ≥ d | l_i ≠ s_i}. Tot diepte j groeien rankknopen met één bol; op diepte j komen twee bollen (eerst l_j, dan s_j) met elk een vrucht." 
	return {"what": "Vergelijk %s met %s vanaf d = %d: eerste verschil op j = %d (l%s = %s, s%s = %s)." % [mark_at(l, j), mark_at(w, j), d, j,
		sub(str(j)), code(l[j]), sub(str(j)), code(w[j])], "why": why}


static func _n_read(m: TtTreeModel, mv: Dictionary, c: Dictionary) -> Dictionary:
	var tp := m.node(int(c.node))
	var nxt := int(c.next)
	var pos := int(mv.pos)
	var w := str(c.word)
	var ch := w[pos]
	var what := "Top met skip = %d: next = %d + %d + 1 = %d; lees s[next − 1] = s%s = %s." % [tp.skip, nxt, tp.skip, pos + 1, sub(str(pos)), code(ch)]
	var kid := int(tp.kids.get(ch, -1))
	var why := "Algoritme 1: de skip letters sla je over; enkel waar vertakt wordt, lees je één letter."
	if kid < 0:
		why = "Knop %s is leeg (NULL): %s." % [code(ch), "niet gevonden" if m.card.kind == CK.BEE else "hier moet het woord bij"]
	elif m.node(kid).type == NT.LEAF:
		why = "Knop %s leidt naar de vrucht %s: vergelijk daar het hele woord." % [code(ch), code(m.node(kid).label)]
	if tp.skip > 0:
		why = "De %d overgeslagen letter%s bekijk je niet. " % [tp.skip, "" if tp.skip == 1 else "s"] + why
	return {"what": what, "why": why}


static func _n_go(m: TtTreeModel, mv: Dictionary, c: Dictionary) -> Dictionary:
	var ball := m.node(int(c.ball))
	var d := int(c.depth)
	var w := str(c.word)
	var ch := w[d] if d < w.length() else ""
	var dir := str(mv.dir)
	var target: int = {"lo": ball.lo, "eq": ball.eq, "hi": ball.hi}.get(dir, -1)
	var what := ""
	match dir:
		"lo":
			what = "s%s = %s < bol %s: kleiner, naar links." % [sub(str(d)), code(ch), code(ball.ch)]
		"hi":
			what = "s%s = %s > bol %s: groter, naar rechts." % [sub(str(d)), code(ch), code(ball.ch)]
		_:
			what = "s%s = %s = bol %s: gelijk, rechtdoor naar het kind (diepte %d)." % [sub(str(d)), code(ch), code(ball.ch), d + 1]
	var why := "Kleiner en groter blijven in dezelfde top (het zoekboompje): de letter blijft s%s." % sub(str(d)) if dir != "eq" \
		else "De gelijk-pointer is de pointer naar het kind in de trie: daarna vergelijk je de volgende letter."
	if target < 0:
		if m.card != null and m.card.kind == CK.SEED:
			why = "Die rank is leeg: daar groeit een nieuwe bol %s met de vrucht %s." % [code(ch), code(w)]
		else:
			why = "Die rank is leeg (NULL): %s zit niet in de trie." % code(w)
	elif m.node(target).type == NT.LEAF:
		why = "Daar hangt de vrucht %s: vergelijk het hele woord." % code(m.node(target).label)
	return {"what": what, "why": why}


static func _n_attach(m: TtTreeModel, mv: Dictionary, c: Dictionary) -> Dictionary:
	var sm := m as TtSuffixTree
	var j := int(c.j)
	var pt := sm.canon({"node": int(mv.node), "off": int(mv.get("off", 0))})
	var u := sm.point_string(pt)
	var suf := sm.text.substr(j)
	var what := "Suffix σ%s = %s. Het zit al in de boom tot %s (diepte l = %d); daarna wijkt het af." % [sub(str(sm.display_pos(j))), mark_at(suf, u.length()), code(_u(u)), u.length()]
	if u == "":
		what = "Suffix σ%s = %s: geen enkele boog uit de wortel begint met %s." % [sub(str(sm.display_pos(j))), code(suf), code(suf[0])]
	var why := "Dat punt is een top: er komt een nieuwe tak naar een nieuw blad."
	if int(pt.off) > 0:
		why = "Het punt ligt midden in een boog: die wordt gesplitst in een nieuwe top met twee kinderen."
	return {"what": what, "why": why}


static func rule_name(um: TtUkkonen, grow: bool) -> String:
	if grow:
		return "(ii)" if um.x == 0 else "(iii)"
	return "(a)" if um.x == 0 else "(b)"


static func _n_rule(m: TtTreeModel, mv: Dictionary) -> Dictionary:
	var um := m as TtUkkonen
	var it := um.it
	var ch := um.text[it - 1]
	var sig := um.text.substr(um.j - 1, it - um.j)
	var nxt := ""
	if um.x == 0:
		var ks: Array = []
		for kk in um.alphabet.sorted(um.node(um.p).kids.keys()):
			ks.append(str(kk))
		nxt = ("vertrekken takken met " + "/".join(ks)) if not ks.is_empty() else "vertrekt nog geen tak"
	else:
		var kid := int(um.node(um.p).kids.get(um.text[it - um.x - 1], -1))
		nxt = "volgt in de boog %s" % code(um.text[um.node(kid).b + um.x])
	var what := "σ%s = %s + %s. Na %s %s: " % [sub("%d,%d" % [um.j, it]), code(_u(sig)), code(ch), code(_u(sig)), nxt]
	var why := ""
	if bool(mv.grow):
		if um.x == 0:
			what += "regel (ii), nieuw blad."
			why = "Geen tak met %s: een nieuwe tak naar een blad met label (%d, it). Eens blad, altijd blad." % [code(ch), it]
		else:
			what += "regel (iii), splits de boog."
			why = "Het volgende teken is niet %s: nieuwe interne top %s + nieuw blad (%d, it)." % [code(ch), code(sig), it]
	else:
		what += "%s zit er al, regel %s: stop." % [code(sig + ch), rule_name(um, false)]
		why = "Zit σ%s er al, dan ook alle kortere suffixen (Lemma 5): stop de iteratie, x̄ = x + 1." % sub("j,i")
	return {"what": what, "why": why}


## Eerste stap van een nieuwe iteratie (Ukkonen): korte inleiding.
static func iteration_intro(um: TtUkkonen) -> String:
	var it := um.it
	var leaves := um.j - 1
	var t := "Iteratie %d: s%s = %s. " % [it, sub(str(it)), code(um.text[it - 1])]
	if leaves > 0:
		t += "De %d blad%s groei%s vanzelf mee (e = it); " % [leaves, "" if leaves == 1 else "eren", "t" if leaves == 1 else "en"]
	t += "begin bij σ%s." % sub("%d,%d" % [um.j, it])
	return t


# ======================================================================
#  Samen: tip vóór een stap (regel + hoe, niet het antwoord) en uitleg bij een fout
# ======================================================================

static func tip(m: TtTreeModel, mv: Dictionary) -> String:
	var c := m.cursor()
	match str(mv.get("act", "")):
		"move":
			return "Welke letter lees je op diepte d = %d? Volg die knop (klik hem of typ de letter)." % int(c.depth)
		"split":
			return "Vergelijk de twee woorden letter per letter%s: klik op het lint de kolom van het eerste verschil j." % ("" if m.kind == K.PATRICIA else " vanaf d = %d" % int(c.depth))
		"same":
			return "Zelfde woord? Kies Zit er al (Z)."
		"answer":
			return "Vergelijk het hele woord met het label: Pluk (Enter) of Niet hier (N)."
		"cut":
			return "Zoek op het pad de laatste top met ten minste twee niet-lege kinderen; knip de tak eronder (klik de tak, of ↑/↓ en S)."
		"read":
			return "next = next + skip + 1: welke letter lees je? Klik die letter op het hoplint (of ←/→ en Enter)."
		"short":
			return "Vergelijk next + skip met m."
		"pick_leaf":
			return "Kies een vrucht onder de huidige top (klik een glanzende vrucht)."
		"prune", "prune_done":
			return "Zoek een top met maar één kind en klik hem (of Tab en S). Geen meer? Klaar (Enter)."
		"go":
			return "Vergelijk s%s met de letter op de bol: kleiner ←, gelijk ↑ (of Enter), groter →." % sub(str(int(c.depth)))
		"place":
			return "Typ of klik de letter die je eerst plant in deze rankknoop."
		"attach":
			return "Volg het suffix letter per letter vanaf de wortel en klik waar het afwijkt (een top of een punt in een boog)."
		"label":
			return "b = j + l: j = begin van het suffix, l = diepte van het afwijkpunt. Klik die parel op de slinger."
		"locate", "absent":
			return "Volg z vanaf de wortel en klik waar het eindigt. Kom je niet verder: Komt niet voor (X)."
		"where":
			return "b − l_t: b van de boog met het laatste teken van z, l_t = diepte van de top erboven. Klik die parel."
		"count":
			return "Tel de vruchten onder het punt; typ het aantal en Enter."
		"pick":
			return "Klik alle vruchten onder het punt aan, dan Klaar (Enter)."
		"owner":
			return "Kijk naar de kleuren van de vruchten onder het punt en klik de eigenaar(s), dan Klaar."
		"rule":
			return "Staat na σ al het teken s_i in de boom? Ja: Zit er al (Z). Nee: Groei! (G)."
		"hop":
			return "Is x̄ ≥ de lengte van de boog onder het vuurvliegje? Spring (H of klik de top)."
		"follow":
			return "Is p de wortel? Dan x − 1 (W). Anders: Volg link (V)."
		"link":
			return "Klik de top die dezelfde string voorstelt zonder de eerste letter."
	return "Jouw beurt."


## Uitleg bij een foute zet in Samen. entry = de logentry van de zet op een kopie van het model.
static func explain_wrong(m: TtTreeModel, entry: Dictionary, right: Dictionary) -> String:
	var line := m.log.coach_line(entry) if not entry.is_empty() else ""
	if line == "":
		var reason := str(entry.get("data", {}).get("reason", ""))
		match reason:
			"wrong_phase":
				line = "Dat is nu niet aan de beurt. %s" % tip(m, right)
			"occupied", "bad_target", "past_end", "duplicate_first":
				line = "Dat kan hier niet. %s" % tip(m, right)
			"before_d":
				line = "De bij hopt nooit terug: lees verder, op next + skip."
			_:
				line = "Niet juist. %s" % tip(m, right)
	return line.replace("`", "")


# ======================================================================
#  voorspelvragen (Check in de wereld, vóór de game de stap toont)
# ======================================================================

## -> {q, options: [String], correct: [int], right, wrong} of {} als de vraag hier niet past.
static func predict(m: TtTreeModel, kind: String, mv: Dictionary) -> Dictionary:
	var c := m.cursor()
	var act := str(mv.get("act", ""))
	match kind:
		"letter":
			if act != "move":
				return {}
			var opts: Array = Array(m.alphabet.letters)
			var ci := opts.find(str(mv.letter))
			return {"q": "Voorspel: welke knop volg je op diepte d = %d?" % int(c.depth), "options": opts, "correct": [ci],
				"right": "Juist: s%s = %s." % [sub(str(int(c.depth))), code(str(mv.letter))],
				"wrong": "Op diepte d lees je s%s: tel vanaf 0 in %s." % [sub(str(int(c.depth))), mark_at(str(c.word), int(c.depth))]}
		"answer":
			if act != "answer":
				return {}
			var f := bool(mv.found)
			return {"q": "Voorspel: de bij is bij de vrucht %s. Gevonden?" % code(m.node(int(c.leaf)).label),
				"options": ["Ja: pluk", "Nee: niet hier"], "correct": [0 if f else 1],
				"right": "Juist: vergelijk altijd het hele woord.", "wrong": "Vergelijk letter per letter: %s tegen %s." % [code(m.node(int(c.leaf)).label), code(str(c.word))]}
		"j":
			if act != "split":
				return {}
			var j := int(mv.j)
			var lo := int(c.get("j_min", 0)) if m.kind != K.PATRICIA else 0
			var cand := [j - 1, j, j + 1, j + 2]
			var opts2: Array = []
			for x in cand:
				if x >= lo and x < str(c.word).length() and not opts2.has(str(x)):
					opts2.append(str(x))
			opts2.sort_custom(func(a, b): return int(a) < int(b))
			return {"q": "Voorspel: %s tegen %s. Wat is j?" % [code(str(c.label)), code(str(c.word))], "options": opts2,
				"correct": [opts2.find(str(j))], "right": "Juist: j = %d is het eerste verschil." % j,
				"wrong": "j = %d: daar verschillen ze voor het eerst (%s tegen %s)." % [j, mark_at(str(c.label), j), mark_at(str(c.word), j)]}
		"tops":
			if act != "split" or m.kind != K.TRIE:
				return {}
			var n := int(mv.j) - int(c.depth) + 1
			var opts3: Array = []
			for x in [1, n - 1, n, n + 1]:
				if x >= 1 and not opts3.has(str(x)):
					opts3.append(str(x))
			opts3.sort_custom(func(a, b): return int(a) < int(b))
			return {"q": "Voorspel: j = %d en het blad zit op diepte d = %d. Hoeveel nieuwe interne toppen groeien er?" % [int(mv.j), int(c.depth)],
				"options": opts3, "correct": [opts3.find(str(n))], "right": "Juist: j − d + 1 = %d toppen, elk %d pointers." % [n, m.alphabet.letters.size()],
				"wrong": "Het blad wordt een top (1) en er komt een top bij op elke diepte d+1 … j: j − d + 1 = %d." % n}
		"cut":
			if act != "cut":
				return {}
			var cut := int(mv.node)
			var right_top := m.node(cut).parent
			var path := m.path_to(int(c.leaf))
			var opts4: Array = []
			var corr := -1
			for id in path:
				if m.node(id).type == NT.LEAF:
					continue
				if id == right_top:
					corr = opts4.size()
				opts4.append("onder " + _u(_pstr(m, id)))
			return {"q": "Voorspel: je verwijdert %s. Onder welke top knip je?" % code(str(c.word)), "options": opts4, "correct": [corr],
				"right": "Juist: %s is de laatste top met twee niet-lege kinderen." % code(_u(_pstr(m, right_top))),
				"wrong": "Knip onder %s: dat is de laatste top op het pad met ten minste twee niet-lege kinderen." % code(_u(_pstr(m, right_top)))}
		"skip":
			if act != "prune":
				return {}
			var u := int(mv.node)
			var kids := m.children(u)
			if kids.size() != 1 or m.node(kids[0]).type != NT.INNER:
				return {}
			var kn := m.node(kids[0])
			var ns := kn.skip + m.node(u).skip + 1
			var opts5: Array = []
			for x in [ns - 1, ns, ns + 1]:
				if x >= 0:
					opts5.append(str(x))
			return {"q": "Voorspel: top %s (skip %d) heeft één kind, een top met skip %d. Welke skip krijgt dat kind na het snoeien?" % [code(_pstr(m, u)), m.node(u).skip, kn.skip],
				"options": opts5, "correct": [opts5.find(str(ns))], "right": "Juist: %d + %d + 1 = %d." % [kn.skip, m.node(u).skip, ns],
				"wrong": "skip(kind) + skip(top) + 1 = %d + %d + 1 = %d: ook de letter van de geknipte top wordt overgeslagen." % [kn.skip, m.node(u).skip, ns]}
		"pos":
			if act != "read":
				return {}
			var pos := int(mv.pos)
			var opts6: Array = []
			for x in [int(c.next), pos, pos + 1]:
				if not opts6.has(str(x)):
					opts6.append(str(x))
			opts6.sort_custom(func(a, b): return int(a) < int(b))
			return {"q": "Voorspel: next = %d, skip = %d. Welke positie s[…] lees je?" % [int(c.next), int(c.skip)], "options": opts6,
				"correct": [opts6.find(str(pos))], "right": "Juist: next wordt %d, je leest s[%d]." % [pos + 1, pos],
				"wrong": "next = next + skip + 1 = %d, en je leest s[next − 1] = s[%d]." % [pos + 1, pos]}
		"dir":
			if act != "go":
				return {}
			var dirs := ["lo", "eq", "hi"]
			var ball := m.node(int(c.ball))
			var d := int(c.depth)
			var w := str(c.word)
			return {"q": "Voorspel: s%s = %s, de bol is %s. Welke rank?" % [sub(str(d)), code(w[d] if d < w.length() else ""), code(ball.ch)],
				"options": ["kleiner (links)", "gelijk (midden)", "groter (rechts)"], "correct": [dirs.find(str(mv.dir))],
				"right": "Juist.", "wrong": "Vergelijk in de volgorde van het alfabet %s: %s tegen %s." % [" ".join(m.alphabet.letters).substr(0, 40), code(w[d] if d < w.length() else ""), code(ball.ch)]}
		"attach":
			if act != "attach":
				return {}
			var sm := m as TtSuffixTree
			var u2 := sm.point_string({"node": int(mv.node), "off": int(mv.get("off", 0))})
			var suf := sm.text.substr(int(c.j))
			var opts7: Array = []
			for k in [u2.length() - 1, u2.length(), u2.length() + 1]:
				if k >= 0 and k < suf.length():
					opts7.append(_u(suf.substr(0, k)))
			return {"q": "Voorspel: tot waar zit %s al in de boom?" % code(suf), "options": opts7, "correct": [opts7.find(_u(u2))],
				"right": "Juist: na %s wijkt het af." % code(_u(u2)), "wrong": "Volg letter per letter: %s zit er al, de volgende letter niet." % code(_u(u2))}
		"b":
			if act != "label":
				return {}
			var sm2 := m as TtSuffixTree
			var b := int(mv.b)
			var opts8: Array = []
			for x in [int(c.j), b - 1, b, b + 1]:
				if x >= 0 and x <= sm2.n and not opts8.has(str(sm2.display_pos(x))):
					opts8.append(str(sm2.display_pos(x)))
			opts8.sort_custom(func(a, bb): return int(a) < int(bb))
			return {"q": "Voorspel: σ%s wijkt af op diepte l = %d. Welke b krijgt de nieuwe bladboog?" % [sub(str(sm2.display_pos(int(c.j)))), int(c.l)],
				"options": opts8, "correct": [opts8.find(str(sm2.display_pos(b)))], "right": "Juist: b = j + l = %d." % sm2.display_pos(b),
				"wrong": "b = j + l = %d + %d = %d: de eerste l tekens van het suffix zitten al in de boom." % [sm2.display_pos(int(c.j)), int(c.l), sm2.display_pos(b)]}
		"where":
			if act != "where":
				return {}
			var sm3 := m as TtSuffixTree
			var loc := sm3.locate_auto(str(c.z))
			var p := sm3.display_pos(int(mv.pos))
			var opts9: Array = []
			for x in [p, sm3.display_pos(int(loc.b)), p + 1, p - 1]:
				if x >= sm3.pos_base and not opts9.has(str(x)):
					opts9.append(str(x))
			opts9.sort_custom(func(a, bb): return int(a) < int(bb))
			return {"q": "Voorspel: z = %s eindigt in de boog (%d,%d) onder een top met l_t = %d. Op welke positie begint z?" % [code(str(c.z)), sm3.display_pos(int(loc.b)), sm3.display_pos(int(loc.e)), int(loc.l_t)],
				"options": opts9, "correct": [opts9.find(str(p))], "right": "Juist: b − l_t = %d." % p,
				"wrong": "b − l_t = %d − %d = %d (b alleen is het begin van de boog, niet van z)." % [sm3.display_pos(int(loc.b)), int(loc.l_t), p]}
		"count":
			if act != "count":
				return {}
			var n2 := int(mv.n)
			var opts10: Array = []
			for x in [n2 - 1, n2, n2 + 1]:
				if x >= 1:
					opts10.append(str(x))
			return {"q": "Voorspel: hoe vaak komt %s voor?" % code(str(c.z)), "options": opts10, "correct": [opts10.find(str(n2))],
				"right": "Juist: %d vruchten onder het punt." % n2, "wrong": "Tel de vruchten onder het punt: %d." % n2}
		"owner":
			if act != "owner":
				return {}
			var sm4 := m as TtSuffixTree
			var ow: Array = mv.texts
			var opts11: Array = []
			var corr2 := -1
			for combo in [[1], [2], [1, 2]]:
				var nm: Array = []
				for k in combo:
					nm.append(sm4.owner_name(k))
				if combo == ow:
					corr2 = opts11.size()
				opts11.append(" en ".join(nm))
			return {"q": "Voorspel: van wie is het spoor %s?" % code(str(c.z)), "options": opts11, "correct": [corr2],
				"right": "Juist.", "wrong": "Kijk naar de eigenaarskleuren van alle vruchten onder het punt."}
		"rule":
			if act != "rule":
				return {}
			var um := m as TtUkkonen
			var r := 2 if not bool(mv.grow) else (0 if um.x == 0 else 1)
			return {"q": "Voorspel: σ%s = %s + %s. Wat gebeurt er?" % [sub("%d,%d" % [um.j, um.it]), code(_u(um.text.substr(um.j - 1, um.it - um.j))), code(um.text[um.it - 1])],
				"options": ["(ii) nieuw blad aan een top", "(iii) boog splitsen + nieuw blad", "(a)/(b) zit er al: stop"], "correct": [r],
				"right": "Juist: %s." % ["regel (ii)", "regel (iii)", "zit er al, stop"][r],
				"wrong": "Kijk wat er in de boom na σ komt: %s." % _n_rule(m, mv).what.get_slice(": ", 1)}
		"hop":
			if act != "hop":
				return {}
			var um2 := m as TtUkkonen
			var L := um2.edge_len(int(mv.node))
			return {"q": "Voorspel: x̄ = %d en de boog onder het vuurvliegje is %d lang. Wat doe je eerst?" % [um2.x, L],
				"options": ["Springen naar de top eronder", "Meteen de regel kiezen"], "correct": [0],
				"right": "Juist: x̄ ≥ lengte, dus eerst springen (x̄ = %d)." % (um2.x - L), "wrong": "x̄ = %d ≥ %d: de positie ligt voorbij die top, dus eerst springen." % [um2.x, L]}
		"follow":
			if act != "follow":
				return {}
			var um3 := m as TtUkkonen
			var minus := str(mv.mode) == "minus"
			return {"q": "Voorspel: p = %s. Hoe vind je het volgende suffix?" % code(_u(um3.node_string(um3.p))),
				"options": ["Volg de suffix link (x̄ = x)", "x − 1 vanaf de wortel"], "correct": [1 if minus else 0],
				"right": "Juist.", "wrong": "p = wortel → x − 1; anders volg je de suffix link en blijft x."}
		"link":
			if act != "link":
				return {}
			var um4 := m as TtUkkonen
			var fr := um4.node_string(um4.pending)
			var to := _u(um4.node_string(int(mv.node)))
			var opts12: Array = [to]
			for cand2 in [fr, fr.substr(0, fr.length() - 1), "∅", fr.substr(2)]:
				var cs := _u(str(cand2))
				if not opts12.has(cs) and opts12.size() < 3:
					opts12.append(cs)
			opts12.sort()
			return {"q": "Voorspel: de nieuwe top %s: waar gaat zijn suffix link naartoe?" % code(fr), "options": opts12, "correct": [opts12.find(to)],
				"right": "Juist: %s zonder de eerste letter = %s." % [code(fr), code(to)], "wrong": "Een suffix link laat de eerste letter weg: %s → %s." % [code(fr), code(to)]}
	return {}


## Opties in willekeurige volgorde (correct-indices mee omgezet).
static func shuffled(q: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if q.is_empty():
		return q
	var opts: Array = q.options
	var idx := range(opts.size())
	for i in range(idx.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = idx[i]
		idx[i] = idx[k]
		idx[k] = tmp
	var out := q.duplicate()
	out.options = []
	out.correct = []
	for i in idx.size():
		out.options.append(opts[idx[i]])
		if (q.correct as Array).has(idx[i]):
			out.correct.append(i)
	return out


# ======================================================================
#  Check-vragen voor de terugblik (nieuw voorbeeld, willekeurig, antwoord via de core)
# ======================================================================

## -> {part, q, options, correct: [int], explain, fig: {kind, rn, letters, pos_base, text, title}}
static func check_question(id: String, rng: RandomNumberGenerator) -> Dictionary:
	for _try in 300:
		var q := finalize(_check(id, rng))
		if not q.is_empty() and not (q.correct as Array).is_empty() and (q.options as Array).size() >= 2:
			q["part"] = id
			return q
	return {}


static func _words(rng: RandomNumberGenerator, n: int, alpha := "ACGT", lo := 2, hi := 5) -> Array:
	var out := []
	var guard := 0
	while out.size() < n and guard < 500:
		guard += 1
		var w := ""
		for i in rng.randi_range(lo, hi):
			w += alpha[rng.randi_range(0, alpha.length() - 1)]
		w += "_"
		if not out.has(w):
			out.append(w)
	return out


## Woorden met gedeelde prefixen (interessantere bomen): elk nieuw woord = prefix van een vorig woord + 1–3 letters.
static func _stem_words(rng: RandomNumberGenerator, n: int, lo := 3, hi := 6, alpha := "ACGT") -> Array:
	var out: Array = []
	var guard := 0
	while out.size() < n and guard < 500:
		guard += 1
		var w := ""
		if out.is_empty() or rng.randf() < 0.2:
			for i in rng.randi_range(lo, hi):
				w += alpha[rng.randi_range(0, alpha.length() - 1)]
		else:
			var base: String = str(out[rng.randi_range(0, out.size() - 1)]).trim_suffix("_")
			w = base.substr(0, rng.randi_range(1, maxi(1, base.length() - 1)))
			for i in rng.randi_range(1, 3):
				w += alpha[rng.randi_range(0, alpha.length() - 1)]
		w += "_"
		if not out.has(w):
			out.append(w)
	return out


## Een zoekwoord: een opgeslagen woord, of een variant ervan (één letter anders of een stuk eraf/erbij).
static func _query(rng: RandomNumberGenerator, ws: Array, alpha := "ACGT") -> String:
	var w: String = str(ws[rng.randi_range(0, ws.size() - 1)]).trim_suffix("_")
	var r := rng.randf()
	if r < 0.34:
		return w + "_"
	if r < 0.67 and w.length() > 1:
		var i := rng.randi_range(1, w.length() - 1)
		var ch := alpha[rng.randi_range(0, alpha.length() - 1)]
		return w.substr(0, i) + ch + w.substr(i + 1) + "_"
	return w.substr(0, rng.randi_range(1, w.length())) + alpha[rng.randi_range(0, alpha.length() - 1)] + "_"


static func _trie(words: Array) -> TtTrie:
	var t := TtTrie.new().setup(TtAlphabet.dna(), "{}")
	for w in words:
		t.insert_auto(str(w))
	return t


static func _fig(m: TtTreeModel, title: String, pos_base := 0, text := "") -> Dictionary:
	return {"kind": m.kind, "rn": m.render_nodes(), "letters": "".join(m.alphabet.letters), "pos_base": pos_base, "text": text, "title": title}


static func _num_opts(right: int, cands: Array, lo := 0) -> Array:
	var out: Array = []
	for x in cands:
		if int(x) >= lo and not out.has(str(x)):
			out.append(str(x))
	if not out.has(str(right)):
		out.append(str(right))
	out.sort_custom(func(a, b): return int(a) < int(b))
	return out


static func _check(id: String, rng: RandomNumberGenerator) -> Dictionary:
	match id:
		"zoeken":
			var ws := _stem_words(rng, 5)
			var t := _trie(ws)
			var w := _query(rng, ws)
			var r := t.lookup_auto(w)
			var opts := ["Gevonden in de vrucht %s" % w, "Lege knop (NULL): niet gevonden", "Een andere vrucht bereikt: niet gevonden"]
			var corr := 0 if r.found else (1 if r.reason == "null" else 2)
			if r.reason == "short":
				return {}
			var ex := "Volg de letters: "
			if r.found:
				ex += "je komt in de vrucht %s en die is gelijk." % code(w)
			elif r.reason == "null":
				ex += "na %s is knop %s leeg (NULL)." % [code(_u(w.substr(0, int(r.depth)))), code(str(r.letter))]
			else:
				ex += "je komt in de vrucht %s ≠ %s." % [code(t.node(int(r.end)).label), code(w)]
			return {"q": "Een bij zoekt %s in deze trie. Hoe eindigt de zoektocht?" % code(w), "options": opts, "correct": [corr], "explain": ex,
				"data": {"words": ws, "w": w, "outcome": corr},
				"fig": _fig(t, "trie met %s" % ", ".join(ws))}
		"toevoegen", "geheugen":
			var ws2 := _stem_words(rng, 4)
			var t2 := _trie(ws2)
			var w2 := _query(rng, ws2)
			var r2 := t2.lookup_auto(w2)
			if r2.reason != "leaf_mismatch":
				return {}
			var lf := t2.node(int(r2.end))
			var d := lf.depth
			var j := TtTrie.first_diff(lf.label, w2, d)
			if j <= d:
				return {}
			if id == "toevoegen":
				return {"q": "Je voegt %s toe en komt bij de vrucht %s op diepte d = %d. Wat is j?" % [code(w2), code(lf.label), d],
					"options": _num_opts(j, [d, j - 1, j + 1, j + 2], d), "correct_val": str(j), "data": {"words": ws2, "w": w2, "label": lf.label, "d": d},
					"explain": "j = min{i ≥ d | l_i ≠ s_i} = %d: %s tegen %s." % [j, mark_at(lf.label, j), mark_at(w2, j)],
					"fig": _fig(t2, "trie met %s" % ", ".join(ws2))}
			var before := t2.inner_count()
			var t3 := _trie(ws2)
			t3.insert_auto(w2)
			var n := t3.inner_count() - before
			return {"q": "Je voegt %s toe (vrucht %s op diepte d = %d). Hoeveel pointers (sap) kosten de nieuwe toppen, met |A| = 5?" % [code(w2), code(lf.label), d],
				"options": _num_opts(n * 5, [5, (n - 1) * 5, (n + 1) * 5, n], 1), "correct_val": str(n * 5), "data": {"words": ws2, "w": w2},
				"explain": "j = %d, dus j − d + 1 = %d nieuwe interne toppen × 5 pointers = %d (ook de NULL-pointers kosten geheugen)." % [j, n, n * 5],
				"fig": _fig(t2, "trie met %s" % ", ".join(ws2))}
		"verwijderen":
			var ws4 := _stem_words(rng, 5)
			var t4 := _trie(ws4)
			var w4: String = ws4[rng.randi_range(0, ws4.size() - 1)]
			var r4 := t4.lookup_auto(w4)
			var cut := t4.correct_cut(int(r4.end))
			var top := t4.node(cut).parent
			var opts4: Array = []
			for pid in r4.path:
				if t4.node(int(pid)).type != NT.LEAF:
					opts4.append("onder " + _u(t4.path_string(int(pid))))
			if opts4.size() < 3:
				return {}
			return {"q": "Je verwijdert %s. Onder welke top knip je?" % code(w4), "options": opts4, "correct_val": "onder " + _u(t4.path_string(top)),
				"data": {"words": ws4, "w": w4},
				"explain": "%s is de laatste top op het pad met ten minste twee niet-lege kinderen." % code(_u(t4.path_string(top))),
				"fig": _fig(t4, "trie met %s" % ", ".join(ws4))}
		"snoeien":
			var ws5 := _stem_words(rng, 4)
			var t5 := _trie(ws5)
			var pm := TtPatricia.new().setup(TtAlphabet.dna())
			pm.load_trie(t5.serialize())
			var c5 := TtCard.new()
			c5.id = 1
			c5.kind = CK.PATRICIFY
			pm.begin(c5)
			pm.auto_finish_card()
			var n5 := pm.count_type(NT.INNER)
			var before5 := t5.inner_count()
			if before5 == n5:
				return {}
			return {"q": "Je zet deze trie om naar een Patricia trie. Hoeveel interne toppen blijven er over?", "options": _num_opts(n5, [n5 - 1, n5 + 1, before5], 1),
				"correct_val": str(n5), "data": {"words": ws5}, "explain": "Enkel de wortel en de toppen met ten minste twee kinderen blijven: %d (de gewone trie had er %d). Patricia: %s" % [n5, before5, code(pm.serialize())],
				"fig": _fig(t5, "gewone trie met %s" % ", ".join(ws5))}
		"pzoeken":
			var ws6 := _stem_words(rng, 5)
			var pm6 := TtPatricia.new().setup(TtAlphabet.dna())
			pm6.load_trie(_trie(ws6).serialize())
			var c6 := TtCard.new()
			c6.id = 1
			c6.kind = CK.PATRICIFY
			pm6.begin(c6)
			pm6.auto_finish_card()
			var w6 := _query(rng, ws6)
			var z := pm6.zoek(w6)
			var ps: Array = []
			for s in z.steps:
				ps.append(str(int(s.pos)))
			if ps.size() < 2:
				return {}
			var right := ", ".join(ps)
			var alt1: Array = []
			for i in ps.size():
				alt1.append(str(i))
			var alt2: Array = []
			for s in ps:
				alt2.append(str(int(s) + 1))
			if right == ", ".join(alt1):
				return {}
			var alt3: Array = []
			for s in z.steps:
				alt3.append(str(int(s.pos) - 1 if int(s.pos) > 0 else 0))
			var opts6: Array = [right]
			for a in [", ".join(alt1), ", ".join(alt2), ", ".join(alt3)]:
				if not opts6.has(a):
					opts6.append(a)
			var res: String = "gevonden" if z.found else ("niet gevonden (" + {"short": "te kort", "null": "lege knop", "leaf": "andere vrucht"}.get(str(z.end), "") + ")")
			return {"q": "Algoritme 1 zoekt %s in deze Patricia trie. Welke posities s[…] lees je?" % code(w6), "options": opts6, "correct_val": right,
				"data": {"words": ws6, "w": w6},
				"explain": "next = next + skip + 1, lees s[next − 1]: posities %s; resultaat: %s." % [right, res],
				"fig": _fig(pm6, "Patricia trie")}
		"enten":
			var pm7 := TtPatricia.new().setup(TtAlphabet.dna())
			var ws7 := _stem_words(rng, 4)
			pm7.load_trie(_trie(ws7).serialize())
			var c7 := TtCard.new()
			c7.id = 1
			c7.kind = CK.PATRICIFY
			pm7.begin(c7)
			pm7.auto_finish_card()
			var w7 := _query(rng, ws7)
			if ws7.has(w7):
				return {}
			var c8 := TtCard.new()
			c8.id = 2
			c8.kind = CK.SEED
			c8.word = w7
			var fig := _fig(pm7, "Patricia trie")
			pm7.begin(c8)
			var g := 0
			while pm7.card != null and pm7.phase != P.COMPARE and g < 50:
				g += 1
				pm7.apply(pm7.correct_move())
			if pm7.phase != P.COMPARE:
				return {}
			var cur := pm7.cursor()
			var lab := str(cur.label)
			var j7 := TtTrie.first_diff(lab, w7, 0)
			if j7 < 1:
				return {}
			return {"q": "Je voegt %s toe; Algoritme 1 brengt je bij de vrucht %s. Op welke diepte j ent je?" % [code(w7), code(lab)],
				"options": _num_opts(j7, [0, j7 - 1, j7 + 1, j7 + 2], 0), "correct_val": str(j7), "data": {"words": ws7, "w": w7, "label": lab},
				"explain": "Vergelijk vanaf positie 0 (ook de overgeslagen letters): eerste verschil op j = %d (%s tegen %s)." % [j7, mark_at(w7, j7), mark_at(lab, j7)],
				"fig": fig}
		"ternary":
			var ws9 := _stem_words(rng, 6, 2, 4)
			var tm := TtTernary.new().setup(TtAlphabet.dna())
			for w in ws9:
				tm.insert_auto(str(w))
			var w9: String = ws9[rng.randi_range(0, ws9.size() - 1)]
			var steps := _ternary_steps(tm, w9)
			if steps.size() < 3 or steps.size() > 6 or (steps.count("kleiner") + steps.count("groter")) == 0:
				return {}
			var right9 := " ".join(steps)
			var opts9: Array = [right9]
			var alt := steps.duplicate()
			alt[0] = {"kleiner": "groter", "groter": "kleiner", "gelijk": "groter"}.get(alt[0], "gelijk")
			opts9.append(" ".join(alt))
			var alt3: Array = []
			for s in steps:
				if s == "gelijk":
					alt3.append(s)
			opts9.append(" ".join(alt3) if not alt3.is_empty() and " ".join(alt3) != right9 else " ".join(steps.slice(0, steps.size() - 1)))
			return {"q": "Een bij zoekt %s in deze ternary trie. Welke ranken volgt ze, in volgorde?" % code(w9), "options": opts9, "correct_val": right9,
				"data": {"words": ws9, "w": w9},
				"explain": "Vergelijk s_d met elke bol: kleiner/groter blijven in de top, gelijk gaat naar het kind: %s." % right9,
				"fig": _fig(tm, "ternary trie (woorden in deze volgorde: %s)" % ", ".join(ws9))}
		"ttoevoegen":
			var ws10 := _stem_words(rng, 4, 2, 4)
			var tm2 := TtTernary.new().setup(TtAlphabet.dna())
			for w in ws10:
				tm2.insert_auto(str(w))
			var w10 := _query(rng, ws10)
			if ws10.has(w10):
				return {}
			var b0 := tm2.balls()
			var fig10 := _fig(tm2, "ternary trie")
			tm2.insert_auto(w10)
			var nb := tm2.balls() - b0
			return {"q": "Je voegt %s toe aan deze ternary trie. Hoeveel nieuwe letterbollen groeien er?" % code(w10),
				"options": _num_opts(nb, [nb - 1, nb + 1, nb + 2], 0), "correct_val": str(nb), "data": {"words": ws10, "w": w10},
				"explain": "Volg het woord; vanaf de lege rank groeit een bol per letter tot de woorden verschillen: %d bol%s (× 3 pointers)." % [nb, "" if nb == 1 else "len"],
				"fig": fig10}
		"suffixboom", "labels":
			var tx := _text(rng, 5, 7)
			var sm := TtSuffixTree.new().setup(TtAlphabet.dna_lower(), tx, 0, "pointers")
			var j := rng.randi_range(2, tx.length() - 2)
			for k in j:
				sm.insert_suffix_auto(k)
			var pt := sm.attach_point(j)
			var u := sm.point_string(pt)
			var fig11 := _fig(sm, "S van %s: suffixen 0 … %d" % [tx, j - 1], 0, tx)
			if id == "suffixboom":
				var suf := tx.substr(j)
				var opts11: Array = []
				for k in [u.length() - 1, u.length(), u.length() + 1]:
					if k >= 0 and k < suf.length():
						opts11.append(_u(suf.substr(0, k)))
				return {"q": "Tekst %s (posities vanaf 0). Je hecht σ%s = %s aan. Tot waar zit het al in de boom?" % [code(tx), sub(str(j)), code(suf)],
					"options": opts11, "correct_val": _u(u), "data": {"text": tx, "j": j}, "explain": "Volg het suffix vanaf de wortel: %s zit er al, daarna wijkt het af." % code(_u(u)), "fig": fig11}
			var b := j + u.length()
			var n := tx.length() - 1
			var opts12: Array = []
			for x in [b, j, b - 1, b + 1]:
				if x >= 0 and x <= n:
					var s := "(%d,%d)" % [x, n]
					if not opts12.has(s):
						opts12.append(s)
			return {"q": "Tekst %s. σ%s wijkt af na %s (diepte l = %d). Welk label (b,e) krijgt de nieuwe bladboog?" % [code(tx), sub(str(j)), code(_u(u)), u.length()],
				"options": opts12, "correct_val": "(%d,%d)" % [b, n], "data": {"text": tx, "j": j}, "explain": "b = j + l = %d + %d = %d en e = n = %d." % [j, u.length(), b, n], "fig": fig11}
		"szoeken":
			var tx2 := _text(rng, 6, 8)
			var sm2 := TtSuffixTree.new().setup(TtAlphabet.dna_lower(), tx2, 0, "pointers")
			var uk := TtUkkonen.new().setup_text(TtAlphabet.dna_lower(), tx2, 0)
			uk.run_all()
			sm2.load_notation(uk.serialize())
			var a := rng.randi_range(0, tx2.length() - 3)
			var z2 := tx2.substr(a, rng.randi_range(1, 3))
			if z2.contains("_"):
				return {}
			var loc := sm2.locate_auto(z2)
			if not loc.found:
				return {}
			var fig13 := _fig(sm2, "suffixboom van %s (Ukkonen)" % tx2, 0, tx2)
			if rng.randf() < 0.5:
				var nn := (loc.leaves as Array).size()
				return {"q": "Hoe vaak komt %s voor in %s?" % [code(z2), code(tx2)], "options": _num_opts(nn, [nn - 1, nn + 1, nn + 2], 1),
					"correct_val": str(nn), "data": {"text": tx2, "z": z2, "kind": "count"}, "explain": "Volg %s vanaf de wortel: onder dat punt hang%s %d vrucht%s." % [code(z2), "t" if nn == 1 else "en", nn, "" if nn == 1 else "en"], "fig": fig13}
			var p := int(loc.pos)
			return {"q": "Volg %s in deze suffixboom: welke positie geeft b − l_t?" % code(z2), "options": _num_opts(p, [int(loc.b), p + 1, p - 1], 0),
				"correct_val": str(p), "data": {"text": tx2, "z": z2, "kind": "pos"}, "explain": "Het laatste teken zit in de boog (%d,%d), de top erboven heeft l_t = %d: %d − %d = %d." % [int(loc.b), int(loc.e), int(loc.l_t), int(loc.b), int(loc.l_t), p],
				"fig": fig13}
		"veralg":
			var t1 := _text(rng, 3, 4).trim_suffix("_")
			var t2 := _text(rng, 3, 4).trim_suffix("_")
			var tx3 := t1 + "1" + t2 + "2"
			var al := TtAlphabet.by_name("dna_lower_multi3")
			var owners := PackedInt32Array()
			for i in tx3.length():
				owners.append(1 if i <= t1.length() else 2)
			var uk2 := TtUkkonen.new().setup_text(al, tx3, 0, owners)
			uk2.run_all()
			var sm3 := TtSuffixTree.new().setup(al, tx3, 0, "pointers", owners)
			sm3.owner_names = PackedStringArray(["Mol", "Merel"])
			sm3.load_notation(uk2.serialize())
			var src := t1 if rng.randf() < 0.5 else t2
			var a2 := rng.randi_range(0, src.length() - 2)
			var z3 := src.substr(a2, 2)
			var loc3 := sm3.locate_auto(z3)
			if not loc3.found:
				return {}
			var ow: Array = loc3.owners
			var right3 := "Mol en Merel" if ow.size() == 2 else ("Mol" if int(ow[0]) == 1 else "Merel")
			return {"q": "Mol = %s, Merel = %s. Van wie is het spoor %s?" % [code(t1 + "1"), code(t2 + "2"), code(z3)], "options": ["Mol", "Merel", "Mol en Merel"],
				"correct_val": right3, "data": {"t1": t1, "t2": t2, "z": z3}, "explain": "De vruchten onder het einde van %s horen bij: %s." % [code(z3), right3], "fig": _fig(sm3, "veralgemeende suffixboom", 0, tx3)}
		"ukk_regels", "ukk_wijzer", "ukk_links":
			var tx4 := _text(rng, 5, 7, "ab")
			var um := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), tx4, 1)
			var c9 := TtCard.new()
			c9.id = 1
			c9.kind = CK.UKKONEN
			um.begin(c9)
			var want: String = {"ukk_regels": "rule", "ukk_wijzer": "follow", "ukk_links": "link"}[id]
			var stops: Array = []
			var g2 := 0
			while um.card != null and g2 < 200:
				g2 += 1
				var mv := um.correct_move()
				if str(mv.act) == want and um.it >= 3:
					stops.append(g2)
				um.apply(mv)
			if stops.is_empty():
				return {}
			var at: int = stops[rng.randi_range(0, stops.size() - 1)]
			var um2 := TtUkkonen.new().setup_text(TtAlphabet.abc_lower(), tx4, 1)
			var c10 := TtCard.new()
			c10.id = 1
			c10.kind = CK.UKKONEN
			um2.begin(c10)
			for k in at - 1:
				um2.apply(um2.correct_move())
			var mv2 := um2.correct_move()
			var fig14 := _fig(um2, "S(1,%d) van %s, tijdens iteratie %d" % [um2.it - 1, tx4, um2.it], 1, tx4)
			var head := "Ukkonen op %s (posities vanaf 1), iteratie %d, extensie j = %d, wijzer (p̄, x̄) = (%s, %d). " % [code(tx4), um2.it, um2.j, code(_u(um2.node_string(um2.p))), um2.x]
			if want == "rule":
				var r9 := 2 if not bool(mv2.grow) else (0 if um2.x == 0 else 1)
				var opts14 := ["(ii) nieuw blad aan een top", "(iii) boog splitsen + nieuw blad", "(a)/(b) zit er al: stop"]
				return {"q": head + "σ%s = %s + %s: welke regel?" % [sub("%d,%d" % [um2.j, um2.it]), code(_u(tx4.substr(um2.j - 1, um2.it - um2.j))), code(tx4[um2.it - 1])],
					"options": opts14, "correct_val": opts14[r9], "data": {"text": tx4, "it": um2.it, "j": um2.j}, "explain": str(_n_rule(um2, mv2).what), "fig": fig14}
			if want == "follow":
				var minus := str(mv2.mode) == "minus"
				var opts15 := ["Volg de suffix link van p, x̄ = x", "x̄ = x − 1 vanaf de wortel", "Opnieuw vanaf de wortel zoeken met x̄ = 0"]
				return {"q": head + "Er kwam net een nieuw blad. Hoe vind je σ%s?" % sub("%d,%d" % [um2.j + 1, um2.it]), "options": opts15,
					"correct_val": opts15[1 if minus else 0], "data": {"root": um2.p == um2.root}, "explain": str(narrate(um2, mv2).what), "fig": fig14}
			var fr := um2.node_string(um2.pending)
			var to := _u(um2.node_string(int(mv2.node)))
			var opts16: Array = [to]
			for cand in [fr, "∅", fr.substr(0, fr.length() - 1), fr.substr(2)]:
				var cs := _u(str(cand))
				if not opts16.has(cs) and opts16.size() < 3:
					opts16.append(cs)
			return {"q": head + "De nieuwe top %s: naar welke top gaat zijn suffix link?" % code(fr), "options": opts16, "correct_val": to,
				"data": {"from": fr},
				"explain": "Een suffix link laat de eerste letter weg: %s → %s." % [code(fr), code(to)], "fig": fig14}
	return {}


static func _text(rng: RandomNumberGenerator, lo: int, hi: int, alpha := "acgt") -> String:
	var s := ""
	for i in rng.randi_range(lo, hi):
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s + "_"


## Richtingen die een zoektocht in een ternary trie volgt (kleiner/gelijk/groter per bol).
static func _ternary_steps(tm: TtTernary, w: String) -> Array:
	var out: Array = []
	var ball := tm.node(tm.root).ball_root
	var d := 0
	var g := 0
	while ball >= 0 and g < 60:
		g += 1
		var bn := tm.node(ball)
		var dir := "lo" if d >= w.length() else ("lo" if tm.alphabet.compare(w[d], bn.ch) < 0 else ("hi" if tm.alphabet.compare(w[d], bn.ch) > 0 else "eq"))
		out.append({"lo": "kleiner", "eq": "gelijk", "hi": "groter"}[dir])
		var nx: int = {"lo": bn.lo, "eq": bn.eq, "hi": bn.hi}[dir]
		if nx < 0:
			break
		var nn := tm.node(nx)
		if nn.type == NT.LEAF:
			break
		if nn.type == NT.PACK:
			d += 1
			ball = nn.ball_root
		else:
			ball = nx
	return out


## Zet "correct_val" om naar een index in options (na het genereren).
static func finalize(q: Dictionary) -> Dictionary:
	if q.has("correct_val"):
		var i := (q.options as Array).find(str(q.correct_val))
		q["correct"] = [i] if i >= 0 else []
	return q
