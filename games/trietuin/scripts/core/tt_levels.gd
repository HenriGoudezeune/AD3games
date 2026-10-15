class_name TtLevels
## Alle levels van de campagne (GDD §5) + vrije tuin. Woorden, figuren en verwachte eindbomen exact uit de GDD/notas.

const K := TtCodes.Kind
const M := TtCodes.Mode
const HN := TtCodes.Hint

const IDS := ["1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4",
	"4-1", "4-2", "4-3", "4-4", "4-5", "5-1", "5-2", "5-3"]
const SEASONS := ["lente", "zomer", "herfst", "winter", "finale"]
const SEASON_TITLES := {"lente": "Lente", "zomer": "Zomer", "herfst": "Herfst", "winter": "Winter",
	"finale": "De eeuwige slinger", "vrij": "Vrije tuin"}

const F13 := "{A{A[AAGTT_] C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}"
const F15 := "{C{G{C{C{C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]}}} G{A[GA_] G{C{C[GGCC_] G[GGCGG_]}}}}"
const F15P := "{0|C{2|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} G{0|A[GA_] G{1|C[GGCC_] G[GGCGG_]}}}"
const F16 := "{C{A[CA_] G[CGGA_]} G{G[GGGG_]} T{A[TAC_] C[TCCA_]}}"
const F16T := "(G (C . (G (A . [CA_] .) [CGGA_] .) .) (G . [GGGG_] .) (T . (A . [TAC_] (C . [TCCA_] .)) .))"
const F17 := "{C{G{A{C{C[CGACCC_] T[CGACTAA_]}} T[CGTAAT_]}} G{G{A[GGA_] C{G{A[GGCGAA_] T[GGCGTA_]}} G{G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}}"
const F17P := "{0|C{1|A{1|C[CGACCC_] T[CGACTAA_]} T[CGTAAT_]} G{1|A[GGA_] C{1|A[GGCGAA_] T[GGCGTA_]} G{0|G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}"
const F19U := "{(0,1){(2,3){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(2,3){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}"
const F19 := "{(0,1){(0,1){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(0,1){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}"
const MIST := "{(2,2){(3,3){(4,5){(15,16)#11 (6,16)#2} (9,16)#7} (16,16)#15} (1,1){(2,3){(4,5){(15,16)#10 (6,16)#1} (9,16)#6} (5,5){(15,16)#13 (6,16)#4}} (0,0){(15,16)#14 (1,3){(4,5){(15,16)#9 (6,16)#0} (9,16)#5}} (3,3){(4,5){(15,16)#12 (6,16)#3} (9,16)#8} (16,16)#16}"
const W14 := ["TAG_", "TACT_", "GCA_", "GCGT_", "TAGA_", "AT_", "ATTC_", "CC_", "GCGA_", "TT_"]
const W32 := ["mier_", "bij_", "roos_", "bijen_", "tak_", "blad_", "bloem_", "zaad_", "sap_", "tuin_", "bes_", "rank_"]

const S_DONE := {"kind": "done"}
const S_NOMIS := {"kind": "no_mistakes"}
const S_NOHELP := {"kind": "no_help"}


static func ids(max_priority: String = "P2") -> PackedStringArray:
	var out := PackedStringArray()
	for id in IDS:
		if get_spec(id).priority <= max_priority:
			out.append(id)
	return out


static func season_ids(season: String, max_priority: String = "P2") -> PackedStringArray:
	var out := PackedStringArray()
	for id in ids(max_priority):
		if get_spec(id).season == season:
			out.append(id)
	return out


static func _c(kind: String, word: String = "", extra: Dictionary = {}) -> Dictionary:
	var d := {"kind": kind}
	if word != "":
		d["word"] = word
	d.merge(extra)
	return d


static func _seeds(ws: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w in ws:
		out.append(_c("seed", w))
	return out


static func _spec(d: Dictionary) -> TtLevelSpec:
	var s := TtLevelSpec.new()
	for k in d.keys():
		if k == "cards":
			var cs: Array[Dictionary] = []
			for c in d.cards:
				cs.append(c)
			s.cards = cs
		elif k == "stars":
			var ss: Array[Dictionary] = []
			for c in d.stars:
				ss.append(c)
			s.stars = ss
		elif k == "tutorial":
			var ts: Array[Dictionary] = []
			for c in d.tutorial:
				ts.append(c)
			s.tutorial = ts
		elif k == "timeline":
			var tl: Array[Dictionary] = []
			for c in d.timeline:
				tl.append(c)
			s.timeline = tl
		elif k == "bloom_present" or k == "bloom_absent":
			s.set(k, PackedStringArray(d[k]))
		else:
			s.set(k, d[k])
	return s


static func get_spec(id: String) -> TtLevelSpec:
	match id:
		"1-1":
			var cards := _seeds(["TGG_", "ACGT_", "TA_"])
			cards.append(_c("bee", "TGG_"))
			cards.append_array(_seeds(["AAGTT_", "TGCGAAA_"]))
			cards.append_array([_c("bee", "TA_"), _c("bee", "GA_"), _c("bee", "TGA_")])
			return _spec({"id": id, "season": "lente", "title": "Eerste kiem", "priority": "P0",
				"intro": "Volg de letters. Een lege knop? Hang je vrucht.",
				"notes_ref": "Definitie 1 · notas p. 26–27", "kind": K.TRIE, "alphabet": "dna", "start": "{}",
				"sap_budget": 30, "mode": M.CALM, "letter_hint": HN.FULL, "cards": cards,
				"bloom_present": ["TGG_", "ACGT_", "TA_", "AAGTT_", "TGCGAAA_"], "bloom_absent": ["GA_", "TGA_"],
				"stars": [S_DONE, S_NOMIS, S_NOHELP],
				"expect_end": "{A{A[AAGTT_] C[ACGT_]} T{A[TA_] G{C[TGCGAAA_] G[TGG_]}}}", "optimum": {"sap": 20},
				"ghost": {"label": "Figuur 13", "sap": 30, "nodes": 6},
				"tutorial": [{"trigger": "first_card", "text": "Volg de letters. Een lege knop? Hang je vrucht."},
					{"trigger": "first_compare", "ghost": {"act": "split", "j": 1}, "text": "Waar verschillen ze het eerst?"}],
				"extra": {"report": "Dezelfde vijf woorden als Figuur 13 (6 toppen). Beide zijn tries volgens Definitie 1, maar de figuur hangt TA_ en TGCGAAA_ een top dieper dan nodig."}})
		"1-2":
			return _spec({"id": id, "season": "lente", "title": "De tuin van de professor", "priority": "P0",
				"intro": "De tuin uit de notas. Plant er netjes bij.",
				"notes_ref": "Figuur 13 → 14 · Oefening 17 · notas p. 26–28", "kind": K.TRIE, "alphabet": "dna",
				"start": F13, "sap_budget": 60, "mode": M.CALM, "letter_hint": HN.FULL,
				"cards": [_c("bee", "TA_"), _c("seed", "AAGCGA_"), _c("bee", "AAGTT_"), _c("seed", "TGCGAAG_"),
					_c("prune", "TA_"), _c("bee", "TGCGAAG_"), _c("bee", "TA_")],
				"bloom_present": ["AAGCGA_", "AAGTT_", "ACGT_", "TGCGAAA_", "TGCGAAG_", "TGG_"], "bloom_absent": ["TA_"],
				"stars": [S_DONE, S_NOMIS, {"kind": "all", "of": [{"kind": "exact_end"}, S_NOHELP]}],
				"expect_end": "{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}",
				"optimum": {"sap": 50, "peak": 55},
				"timeline": [{"after_card": 1, "event": "stamp", "text": "Figuur 14 ✓"}],
				"tutorial": [{"trigger": "first_cut", "text": "Knip net onder de laatste top met twee kinderen."}]})
		"1-3":
			var cards3: Array[Dictionary] = []
			cards3.append_array(_seeds(["GATTACA_", "GATTAGA_", "CAT_", "GATC_"]))
			cards3.append(_c("bee", "GATTACA_"))
			cards3.append(_c("seed", "CATTAG_"))
			cards3.append(_c("bee", "GATTA_"))
			cards3.append_array(_seeds(["ACGTACGT_", "ACGTTT_"]))
			cards3.append_array([_c("bee", "CATT_"), _c("bee", "ACGTAC_"), _c("bee", "CAT_")])
			return _spec({"id": id, "season": "lente", "title": "Lange wortels", "priority": "P0",
				"intro": "Lange gemeenschappelijke stukken. Kies j zorgvuldig: sap is krap.",
				"notes_ref": "toevoegen, j = min{i ≥ d | l_i ≠ s_i} · notas p. 27", "kind": K.TRIE, "alphabet": "dna",
				"start": "{}", "sap_budget": 70, "mode": M.CALM, "letter_hint": HN.CURSOR, "cards": cards3,
				"bloom_present": ["GATTACA_", "GATTAGA_", "CAT_", "GATC_", "CATTAG_", "ACGTACGT_", "ACGTTT_"],
				"bloom_absent": ["GATTA_", "CATT_", "ACGTAC_"],
				"stars": [S_DONE, S_NOMIS, {"kind": "all", "of": [{"kind": "sap_le", "max": 65}, {"kind": "time_le", "s": 150}]}],
				"expect_end": "{A{C{G{T{A[ACGTACGT_] T[ACGTTT_]}}}} C{A{T{T[CATTAG_] _[CAT_]}}} G{A{T{C[GATC_] T{A{C[GATTACA_] G[GATTAGA_]}}}}}}",
				"optimum": {"sap": 65, "time_par": 150},
				"ghost": {"label": "Patricia", "nodes": 5, "unary": 8},
				"extra": {"report": "In deze boom vertakken 8 van de 13 toppen niet. Dat moet zuiniger kunnen… (zomer: Patricia, 5 toppen)"}})
		"1-4":
			var seeds_t := [[0, "TAG_"], [6, "TACT_"], [12, "GCA_"], [18, "GCGT_"], [26, "TAGA_"], [34, "AT_"],
				[42, "ATTC_"], [50, "CC_"], [58, "GCGA_"], [66, "TT_"]]
			var bees_t := [[10, "TAG_"], [22, "GCA_"], [30, "TACT_"], [38, "TAGA_"], [46, "GG_"], [54, "ATT_"],
				[62, "CC_"], [70, "TAGT_"], [74, "GCGA_"]]
			var all_c := []
			for st in seeds_t:
				all_c.append(_c("seed", st[1], {"t": float(st[0])}))
			for bt in bees_t:
				all_c.append(_c("bee", bt[1], {"t": float(bt[0]), "patience": 14.0}))
			all_c.sort_custom(func(a, b): return float(a.t) < float(b.t))
			return _spec({"id": id, "season": "lente", "title": "Zoemavond", "priority": "P1",
				"intro": "De bijen wachten niet. Plant en bedien vlot.",
				"notes_ref": "opzoeken in O(m) · notas p. 26–27", "kind": K.TRIE, "alphabet": "dna", "start": "{}",
				"sap_budget": 55, "mode": M.SWARM, "letter_hint": HN.NONE, "cards": all_c,
				"bloom_present": W14, "bloom_absent": ["GG_", "ATT_", "TAGT_"],
				"stars": [{"kind": "missed_le", "n": 2}, {"kind": "all", "of": [S_NOMIS, {"kind": "missed_le", "n": 0}]},
					{"kind": "combo", "n": 5, "honey": 250}],
				"expect_end": "{A{T{T[ATTC_] _[AT_]}} C[CC_] G{C{A[GCA_] G{A[GCGA_] T[GCGT_]}}} T{A{C[TACT_] G{A[TAGA_] _[TAG_]}} T[TT_]}}",
				"optimum": {"sap": 45}})
		"2-1":
			return _spec({"id": id, "season": "zomer", "title": "Snoeien", "priority": "P0",
				"intro": "Takken zonder vertakking? Knip ze. Tel de ringen.",
				"notes_ref": "Figuur 15 · Algoritme 1 · notas p. 29–30", "kind": K.PATRICIA, "alphabet": "dna",
				"start": F15, "start_format": "trie", "sap_budget": 60, "mode": M.CALM, "letter_hint": HN.FULL,
				"cards": [_c("patricify"), _c("bee", "GGCGG_"), _c("bee", "CGCGAA_"), _c("bee", "GGC_"),
					_c("bee", "CA_"), _c("bee", "CGCCTT_"), _c("bee", "GACC_")],
				"bloom_present": ["CGCCCT_", "CGCCTT_", "CGCGAA_", "GA_", "GGCC_", "GGCGG_"],
				"bloom_absent": ["GGC_", "CA_", "GACC_"],
				"stars": [S_DONE, S_NOMIS, S_NOHELP], "expect_end": F15P, "optimum": {"sap": 30, "start_sap": 48},
				"ghost": {"label": "gewone trie", "sap": 48},
				"tutorial": [{"trigger": "first_prune", "ghost": {"act": "prune", "path": "C"}, "text": "Takken zonder vertakking? Knip ze. Tel de ringen."}]})
		"2-2":
			return _spec({"id": id, "season": "zomer", "title": "Het wespenbedrog", "priority": "P0",
				"intro": "Patricia kijkt niet naar overgeslagen letters…",
				"notes_ref": "AAAAABAAAAABC_ · Algoritme 1 · notas p. 29", "kind": K.PATRICIA, "alphabet": "abc",
				"start": "{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}", "sap_budget": 10,
				"mode": M.CALM, "letter_hint": HN.CURSOR,
				"cards": [_c("bee", "AAAAABAAAAABC_"), _c("bee", "AAAAACA_"), _c("bee", "BBBBBBBBBBBBB_", {"wasp": true}),
					_c("bee", "AAAAAC_"), _c("bee", "CCCCCBCCCCCBC_", {"wasp": true}), _c("bee", "AAAAABAAAAAC_"),
					_c("bee", "AAAAABAAAAABC_")],
				"bloom_present": ["AAAAABAAAAABC_", "AAAAABAAAAAC_", "AAAAACA_"],
				"bloom_absent": ["BBBBBBBBBBBBB_", "CCCCCBCCCCCBC_", "AAAAAC_"],
				"stars": [S_DONE, S_NOMIS, S_NOHELP],
				"expect_end": "{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}", "optimum": {"sap": 10},
				"ghost": {"label": "gewone trie", "sap": 48, "nodes": 12}})
		"2-3":
			return _spec({"id": id, "season": "zomer", "title": "Enten", "priority": "P0",
				"intro": "Toevoegen: zoek eerst een vrucht om de overgeslagen letters te lezen.",
				"notes_ref": "toevoegen in een Patricia trie · notas p. 29", "kind": K.PATRICIA, "alphabet": "dna",
				"start": F15P, "sap_budget": 54, "mode": M.CALM, "letter_hint": HN.NONE,
				"cards": [_c("seed", "GT_"), _c("seed", "CGTA_"), _c("seed", "GGCGT_"), _c("seed", "C_"),
					_c("bee", "CGTA_"), _c("bee", "C_"), _c("bee", "GGCGT_"), _c("bee", "GGCC_"),
					_c("bee", "CGTT_", {"wasp": true}), _c("bee", "GTA_", {"wasp": true})],
				"bloom_present": ["CGCCCT_", "CGCCTT_", "CGCGAA_", "GA_", "GGCC_", "GGCGG_", "GT_", "CGTA_", "GGCGT_", "C_"],
				"bloom_absent": ["CGTT_", "GTA_"],
				"stars": [S_DONE, S_NOMIS, {"kind": "all", "of": [S_NOHELP, {"kind": "time_le", "s": 240}]}],
				"expect_end": "{0|C{0|G{0|C{0|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} T[CGTA_]} _[C_]} G{0|A[GA_] G{1|C[GGCC_] G{0|G[GGCGG_] T[GGCGT_]}} T[GT_]}}",
				"optimum": {"sap": 48, "time_par": 240},
				"extra": {"report": "Alle skip-winst van de C-tak is weg: Patricia wint het meest in dunne tries."}})
		"2-4":
			return _spec({"id": id, "season": "zomer", "title": "Oefening 19a", "priority": "P0",
				"intro": "Oefening 19 — lesnotas p. 32. Geen hints.",
				"notes_ref": "Oefening 19a · Figuur 17 · notas p. 32", "kind": K.PATRICIA, "alphabet": "dna",
				"start": F17, "start_format": "trie", "sap_budget": 60, "mode": M.CALM, "letter_hint": HN.NONE,
				"hints_allowed": false,
				"cards": [_c("patricify"), _c("bee", "GGCGTA_"), _c("bee", "CGACTAA_"), _c("bee", "GGGTTT_"),
					_c("bee", "GTGGGG_", {"wasp": true}), _c("bee", "CCAT_"), _c("bee", "GGTT_"), _c("bee", "CGTAAT_")],
				"bloom_present": ["CGACCC_", "CGACTAA_", "CGTAAT_", "GGA_", "GGCGAA_", "GGCGTA_", "GGGGG_", "GGGTTT_", "GGTT_"],
				"bloom_absent": ["GTGGGG_", "CCAT_"],
				"stars": [S_DONE, {"kind": "exact_end"}, S_NOMIS], "expect_end": F17P, "optimum": {"sap": 36},
				"ghost": {"label": "gewone trie", "sap": 60}, "extra": {"notes_view": true}})
		"3-1":
			return _spec({"id": id, "season": "herfst", "title": "Rankknopen", "priority": "P0",
				"intro": "Elke top wordt een klein zoekboompje: kleiner, gelijk, groter.",
				"notes_ref": "Figuur 16 · notas p. 31", "kind": K.TERNARY, "alphabet": "dna",
				"start": F16, "start_format": "trie", "sap_budget": 0, "mode": M.CALM, "letter_hint": HN.FULL,
				"cards": [_c("ternarify"), _c("bee", "CA_"), _c("bee", "TCCA_"), _c("bee", "GGGG_"), _c("bee", "TA_")],
				"bloom_present": ["GGGG_", "CGGA_", "CA_", "TAC_", "TCCA_"], "bloom_absent": ["TA_"],
				"stars": [S_DONE, S_NOMIS, {"kind": "cmp_le", "max": 16}], "expect_end": F16T,
				"optimum": {"sap": 24, "comparisons": 16}, "ghost": {"label": "gewone trie", "sap": 20, "ascii_sap": 1024},
				"timeline": [{"after_card": 4, "event": "ascii_storm", "text": "Wat als het alfabet alle 256 tekens telt?"}],
				"extra": {"rule": "Volgorde-afspraak van deze game: _ staat achteraan (zoals de knoppenrij A C G T _); bij een nieuwe vertakking plant je eerst de oude letter l_j, dan s_j."}})
		"3-2":
			var cards32: Array[Dictionary] = _seeds(W32)
			for w in ["bloem_", "tuin_", "blos_", "zon_", "kip_", "bij_"]:
				cards32.append(_c("bee", w))
			return _spec({"id": id, "season": "herfst", "title": "Woordenrank", "priority": "P0",
				"intro": "Een groot alfabet: rankknopen besparen sap.",
				"notes_ref": "ternary tries · notas p. 31–32", "kind": K.TERNARY, "alphabet": "az", "start": "",
				"sap_budget": 70, "mode": M.CALM, "letter_hint": HN.CURSOR, "hint_full_cards": 3, "cards": cards32,
				"bloom_present": W32, "bloom_absent": ["blos_", "zon_", "kip_"],
				"stars": [S_DONE, S_NOMIS, {"kind": "all", "of": [{"kind": "sap_le", "max": 54}, {"kind": "time_le", "s": 240}]}],
				"expect_end": "(m (b . (i (e . [bes_] .) (j . (_ (e . [bijen_] .) [bij_] .) .) (l . (a . [blad_] (o . [bloem_] .)) .)) .) [mier_] (r . (o (a . [rank_] .) [roos_] .) (t (s . [sap_] .) (a . [tak_] (u . [tuin_] .)) (z . [zaad_] .))))",
				"optimum": {"sap": 54, "time_par": 240}, "ghost": {"label": "gewone trie", "sap": 189, "nodes": 7}})
		"3-3":
			var w17 := ["CGACCC_", "CGACTAA_", "CGTAAT_", "GGA_", "GGCGAA_", "GGCGTA_", "GGGGG_", "GGGTTT_", "GGTT_"]
			var cards33: Array[Dictionary] = [_c("ternarify")]
			for w in w17:
				cards33.append(_c("bee", w))
			return _spec({"id": id, "season": "herfst", "title": "Oefening 19b", "priority": "P2",
				"intro": "Oefening 19b: Figuur 17 als ternary trie.",
				"notes_ref": "Oefening 19b · Figuur 17 · notas p. 32", "kind": K.TERNARY, "alphabet": "dna",
				"start": F17, "start_format": "trie", "sap_budget": 0, "mode": M.CALM, "letter_hint": HN.NONE,
				"cards": cards33, "bloom_present": w17, "bloom_absent": [],
				"stars": [S_DONE, S_NOMIS, {"kind": "cmp_le", "max": 49}],
				"expect_end": "(G (C . (G . (A . (C . (C . [CGACCC_] (T . [CGACTAA_] .)) .) (T . [CGTAAT_] .)) .) .) (G . (C (A . [GGA_] .) (G . (A . [GGCGAA_] (T . [GGCGTA_] .)) .) (G . (G . [GGGGG_] (T . [GGGTTT_] .)) (T . [GGTT_] .))) .) .)",
				"optimum": {"sap": 54, "comparisons": 49}})
		"3-4":
			var lw := []
			for w in W14:
				lw.append(str(w).to_lower())
			return _spec({"id": id, "season": "herfst", "title": "Oefening 20: welke boom plant je?", "priority": "P1",
				"intro": "Twee tuinbedden. Welke boomsoort past bij elk bed?",
				"notes_ref": "Oefening 20 · notas p. 32", "kind": K.TRIE, "alphabet": "dna_lower", "start": "{}",
				"start_format": "beds", "sap_budget": 0, "mode": M.CALM, "letter_hint": HN.NONE,
				"cards": [_c("beds", "", {"beds": [
					{"name": "A", "alphabet": "dna_lower", "words": lw, "budget": 48},
					{"name": "B", "alphabet": "az", "words": W32, "budget": 60}]})],
				"bloom_present": [], "bloom_absent": [],
				"stars": [{"kind": "beds_bloom"}, {"kind": "first_choice"}, {"kind": "time_le", "s": 30}],
				"optimum": {"beds": [{"array": 45, "ternary": 54, "best": "array"}, {"array": 189, "ternary": 54, "best": "ternary"}]},
				"extra": {"report": "|A| = 5, 2 kinderen: 5 pointers tegen 2 × 3. Oefening 20."}})
		"4-1":
			var c41: Array[Dictionary] = []
			for jj in 9:
				c41.append(_c("suffix", "", {"j": jj}))
			return _spec({"id": id, "season": "winter", "title": "De slinger", "priority": "P0",
				"intro": "Hang elk staartje van de slinger in de boom.",
				"notes_ref": "Figuur 18 · notas p. 33", "kind": K.SUFFIX, "alphabet": "dna_lower", "text": "acacacgt_",
				"start": "{}", "pos_base": 0, "labels": "strings", "sap_budget": 90, "mode": M.CALM, "cards": c41,
				"stars": [S_DONE, S_NOMIS, S_NOHELP], "expect_end": F19U, "optimum": {"sap": 80},
				"tutorial": [{"trigger": "card", "card": 2, "ghost": {"act": "attach", "path": "acac"}, "text": "Volg het staartje tot het afwijkt."}]})
		"4-2":
			var c42: Array[Dictionary] = []
			for jj in 9:
				c42.append(_c("suffix", "", {"j": jj}))
			return _spec({"id": id, "season": "winter", "title": "Wijzers", "priority": "P0",
				"intro": "Strings drinken te veel sap. Wijs gewoon naar de slinger.",
				"notes_ref": "Figuur 19 · notas p. 34, 48", "kind": K.SUFFIX, "alphabet": "dna_lower", "text": "acacacgt_",
				"start": "{}", "pos_base": 0, "labels": "pointers", "sap_budget": 50, "mode": M.CALM, "cards": c42,
				"stars": [S_DONE, S_NOMIS, {"kind": "all", "of": [{"kind": "sap_le", "max": 44}, S_NOHELP]}],
				"expect_end": F19U, "optimum": {"sap": 44}, "ghost": {"label": "strings", "sap": 80},
				"extra": {"did_you_know": "Figuur 19 schrijft voor de twee interne ac-bogen (0,1); jouw boom (2,3). Beide spellen ac. De figuur kiest een ander voorkomen van ac; Ukkonen kiest altijd de positie direct na s_t, daarom werkt b − l_t (2 − 2 = 0: daar begint echt acac).",
					"figure": F19}})
		"4-3":
			return _spec({"id": id, "season": "winter", "title": "Inspecteur Egel", "priority": "P0",
				"intro": "Vraag de boom, niet de slinger.",
				"notes_ref": "§3.3 · Oef. 28/29 · notas p. 48–49", "kind": K.SUFFIX, "alphabet": "dna_lower",
				"text": "acacacgt_", "start": F19U, "pos_base": 0, "labels": "pointers", "mode": M.CALM,
				"cards": [_c("ask", "", {"z": "cac", "q": "where"}), _c("ask", "", {"z": "ac", "q": "count"}),
					_c("ask", "", {"z": "cat", "q": "exists"}), _c("ask", "", {"z": "acg", "q": "where"}),
					_c("ask", "", {"z": "a", "q": "all"}), _c("ask", "", {"z": "c", "q": "count"}),
					_c("ask", "", {"z": "caca", "q": "where"})],
				"stars": [{"kind": "correct_ge", "n": 5}, {"kind": "correct_ge", "n": 7},
					{"kind": "all", "of": [{"kind": "correct_ge", "n": 7}, {"kind": "time_le", "s": 120}]}],
				"expect_end": F19U, "optimum": {"sap": 44}})
		"4-4":
			return _spec({"id": id, "season": "winter", "title": "Mist over de slinger", "priority": "P0",
				"intro": "De slinger is verdwenen in de mist. Lees de bordjes: b − l_t.",
				"notes_ref": "b − l_t · Oef. 28/29 · notas p. 48–49", "kind": K.SUFFIX, "alphabet": "dna_lower",
				"text": "gcatcgcatgcatcga_", "start": MIST, "pos_base": 0, "labels": "pointers", "mode": M.CALM,
				"cards": [_c("ask", "", {"z": "cat", "q": "first", "patience": 25.0}),
					_c("ask", "", {"z": "gcat", "q": "count", "patience": 25.0}),
					_c("ask", "", {"z": "atg", "q": "where", "patience": 25.0}),
					_c("ask", "", {"z": "ttt", "q": "exists", "patience": 25.0}),
					_c("ask", "", {"z": "tcg", "q": "count", "patience": 25.0}),
					_c("ask", "", {"z": "cga", "q": "where", "patience": 25.0}),
					_c("ask", "", {"z": "catc", "q": "all", "patience": 25.0})],
				"stars": [{"kind": "correct_ge", "n": 5}, {"kind": "correct_ge", "n": 7},
					{"kind": "all", "of": [{"kind": "correct_ge", "n": 7}, {"kind": "avg_time_le", "s": 10}]}],
				"expect_end": MIST,
				"timeline": [{"after_card": 3, "event": "badges", "text": "Tel één keer alle bladeren per top. Dan weet je het meteen."}],
				"extra": {"fog": true, "oef28a": "Oef. 28a: is b − l_t altijd de eerste positie? Ja: elke b komt van het blad dat Ukkonen in iteratie i voor suffix j aanmaakte; regel (ii)/(iii) zegt dat s_j…s_i daarvóór nog niet voorkwam, dus j is het eerste voorkomen. Splitsen behoudt b − l_t."}})
		"4-5":
			return _spec({"id": id, "season": "winter", "title": "Wiens spoor?", "priority": "P0",
				"intro": "Drie verdachten, één boom. Van wie is dit spoor?",
				"notes_ref": "veralgemeende suffixboom · notas p. 49", "kind": K.SUFFIX, "alphabet": "dna_lower_multi3",
				"text": "gatcga1tcgatt2atcgg3", "start": "", "start_format": "built", "pos_base": 0, "labels": "pointers",
				"owners_spec": [{"name": "Mol", "from": 0, "to": 6}, {"name": "Merel", "from": 7, "to": 13},
					{"name": "Muis", "from": 14, "to": 19}], "mode": M.CALM,
				"cards": [_c("ask", "", {"z": "gatt", "q": "owner"}), _c("ask", "", {"z": "tcgg", "q": "owner"}),
					_c("ask", "", {"z": "cga", "q": "owner"}), _c("ask", "", {"z": "atc", "q": "owner"}),
					_c("ask", "", {"z": "ggg", "q": "owner"}), _c("ask", "", {"z": "cgat", "q": "owner"})],
				"stars": [{"kind": "correct_ge", "n": 4}, {"kind": "correct_ge", "n": 6},
					{"kind": "all", "of": [{"kind": "correct_ge", "n": 6}, {"kind": "time_le", "s": 90}]}]})
		"5-1":
			return _spec({"id": id, "season": "finale", "title": "Ukkonen aan het werk", "priority": "P0",
				"intro": "Eén parel per keer. Bladeren groeien vanzelf.",
				"notes_ref": "Ukkonen · abacabc_ · notas p. 43–48", "kind": K.UKKONEN, "alphabet": "abc_lower",
				"text": "abacabc_", "start": "", "pos_base": 1, "mode": M.CALM, "count_bumps": true,
				"cards": [_c("ukkonen")],
				"stars": [S_DONE, {"kind": "max_mistakes", "n": 2}, {"kind": "max_mistakes", "n": 0}],
				"expect_end": "{(1,1){(2,2){(3,8)#1 (7,8)#5} (4,8)#3} (2,2){(3,8)#2 (7,8)#6} (4,4){(5,8)#4 (8,8)#7} (8,8)#8}",
				"tutorial": [{"trigger": "ghost_iterations", "until_it": 4, "text": "Kijk eerst: iteraties 1–4 doet de Uil voor."}],
				"extra": {"links": "[a]→w, [ab]→[b], [b]→w, [c]→w", "link_order": "De notas tekenen het nieuwe blad pas na de link; in het spel kies je eerst de regel, dan de link. Het resultaat is identiek."}})
		"5-2":
			return _spec({"id": id, "season": "finale", "title": "Oefening 27", "priority": "P0",
				"intro": "Oefening 27: bouw de suffixboom van aabbabc_ met Ukkonen.",
				"notes_ref": "Oefening 27 · notas p. 48", "kind": K.UKKONEN, "alphabet": "abc_lower",
				"text": "aabbabc_", "start": "", "pos_base": 1, "mode": M.CALM, "count_bumps": true,
				"cards": [_c("ukkonen")],
				"stars": [S_DONE, {"kind": "max_mistakes", "n": 2}, {"kind": "max_mistakes", "n": 0}],
				"expect_end": "{(1,1){(2,8)#1 (3,3){(4,8)#2 (7,8)#5}} (3,3){(5,8)#4 (4,8)#3 (7,8)#6} (7,8)#7 (8,8)#8}"})
		"5-3":
			return _spec({"id": id, "season": "finale", "title": "Figuur 18 herboren", "priority": "P1",
				"intro": "De slinger van Figuur 18, nu parel per parel.",
				"notes_ref": "Figuur 18/19 · Ukkonen · notas p. 33–34, 38–43", "kind": K.UKKONEN, "alphabet": "dna_lower",
				"text": "acacacgt_", "start": "", "pos_base": 0, "mode": M.CALM, "count_bumps": true,
				"cards": [_c("ukkonen")],
				"stars": [S_DONE, {"kind": "max_mistakes", "n": 2}, {"kind": "max_mistakes", "n": 0}],
				"expect_end": F19U, "extra": {"figure": F19, "did_you_know": "De twee ac-borden tonen (2,3) naast (0,1) van Figuur 19: de figuur kiest een ander voorkomen van ac; Ukkonen kiest altijd de positie direct na s_t, daarom werkt b − l_t."}})
	return null


## Vrije tuin "Bijenkoorts" (§5.7).
static func endless() -> TtLevelSpec:
	return _spec({"id": "vrij", "season": "vrij", "title": "Bijenkoorts", "priority": "P0",
		"intro": "Plant, bedien, overleef. Drie missers en de tuin sluit.",
		"notes_ref": "gewone trie · notas p. 26–27", "kind": K.TRIE, "alphabet": "dna", "start": "{}",
		"sap_budget": 60, "mode": M.SWARM, "letter_hint": HN.NONE, "endless": true, "cards": [],
		"stars": [], "generator": {"sap_start": 60, "sap_cap": 120, "sap_regen_s": 3.0, "misses": 3,
			"absent_p": 0.25, "prune_from": 120.0, "prune_every": 45.0}})


## Juiste subklasse, start geladen, budget/bumps uit de spec.
static func make_model(spec: TtLevelSpec) -> TtTreeModel:
	var a := TtAlphabet.by_name(spec.alphabet)
	var m: TtTreeModel = null
	match spec.kind:
		K.TRIE:
			if spec.start_format == "beds":
				m = TtBeds.new().setup(a)
			else:
				m = TtTrie.new().setup(a, spec.start if spec.start != "" else "{}")
		K.PATRICIA:
			var pm := TtPatricia.new().setup(a)
			if spec.start_format == "trie":
				pm.load_trie(spec.start)
			else:
				pm.load_notation(spec.start if spec.start != "" else "{0|}")
			m = pm
		K.TERNARY:
			var tm := TtTernary.new().setup(a)
			if spec.start_format == "trie":
				tm.load_trie(spec.start)
			else:
				tm.load_notation(spec.start)
			tm.word_order = spec.bloom_present
			m = tm
		K.SUFFIX:
			var sm := TtSuffixTree.new().setup(a, spec.text, spec.pos_base, spec.labels, spec.owners_array())
			sm.owner_names = spec.owner_names()
			if spec.start_format == "built":
				var uk := TtUkkonen.new().setup_text(a, spec.text, 0, spec.owners_array())
				uk.run_all()
				sm.load_notation(_rebase(uk.serialize(), 0, spec.pos_base, spec.text, a))
			elif spec.start != "" and spec.start != "{}":
				sm.load_notation(spec.start)
			m = sm
		K.UKKONEN:
			var um := TtUkkonen.new().setup_text(a, spec.text, spec.pos_base, spec.owners_array())
			um.owner_names = spec.owner_names()
			m = um
	if m == null:
		return null
	m.sap_budget = spec.sap_budget if spec.sap_budget > 0 else (1 << 30)
	m.count_bumps = spec.count_bumps or spec.kind == K.UKKONEN
	return m


static func _rebase(s: String, from_base: int, to_base: int, text: String, a: TtAlphabet) -> String:
	if from_base == to_base:
		return s
	return TtNotation.serialize_suffix(TtNotation.parse_suffix(s, from_base), to_base, text, a)


## Maakt de kaarten van een spec (ids 1…).
static func make_cards(spec: TtLevelSpec) -> Array[TtCard]:
	var out: Array[TtCard] = []
	var i := 1
	for d in spec.cards:
		out.append(TtCard.from_spec(i, d))
		i += 1
	return out


## Speelt alle kaarten met correct_move(): {sap, comparisons, end, peak}.
static func optimum(spec: TtLevelSpec) -> Dictionary:
	var m := make_model(spec)
	var peak := m.sap_used()
	for c in make_cards(spec):
		m.begin(c)
		var guard := 0
		while m.card != null and guard < 10000:
			guard += 1
			var mv := m.correct_move()
			if str(mv.get("act", "none")) == "none":
				break
			m.apply(mv)
			peak = maxi(peak, m.sap_used())
	var cmp := 0
	if m is TtTernary:
		cmp = (m as TtTernary).comparisons(spec.bloom_present)
	return {"sap": m.sap_used(), "comparisons": cmp, "end": m.serialize(), "peak": peak}


## Ontgrendeling (GDD §4.2): volgend level met ≥ 1 ster op het vorige; een seizoen als alle P0-levels van het vorige
## seizoen ≥ 1 ster hebben; vrije tuin na 1-4 (of 1-3 als 1-4 niet beschikbaar is).
static func is_unlocked(id: String, stars: Dictionary, available: PackedStringArray = PackedStringArray()) -> bool:
	var avail := available if not available.is_empty() else PackedStringArray(IDS)
	if id == "vrij":
		var gate := "1-4" if avail.has("1-4") else "1-3"
		return int(stars.get(gate, 0)) >= 1
	if id == "1-1":
		return true
	var spec := get_spec(id)
	if spec == null:
		return false
	var in_season := PackedStringArray()
	for x in IDS:
		if avail.has(x) and get_spec(x).season == spec.season:
			in_season.append(x)
	var k := in_season.find(id)
	if k > 0:
		return int(stars.get(in_season[k - 1], 0)) >= 1
	var si := SEASONS.find(spec.season)
	if si <= 0:
		return true
	for x in IDS:
		var sx := get_spec(x)
		if sx.season == SEASONS[si - 1] and sx.priority == "P0" and int(stars.get(x, 0)) < 1:
			return false
	return true


static func next_id(id: String, available: PackedStringArray = PackedStringArray()) -> String:
	var avail := available if not available.is_empty() else PackedStringArray(IDS)
	var k := avail.find(id)
	if k >= 0 and k + 1 < avail.size():
		return avail[k + 1]
	return ""
