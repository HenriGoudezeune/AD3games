class_name TxLessons
extends Object
## Leerpad van TELEX (games/telex/design/LEARNING_PATH.md, design/LEARNING.md): de delen in volgorde, per deel een
## Kijk- en een Samen-voorbeeld (kleine stages voor TxDirector), de verteltekst per stap (afgeleid van het orakel
## correct_move() en een proefkopie van de machine, dus altijd juist), tips/foutuitleg voor Samen, de toestand zoals
## je ze op het examen noteert (V[], V_H, C_x, kolommen van M, d[i][j]), voorspelvragen (Check in de wereld) en
## Check-vragen voor de terugblik op een NIEUW willekeurig voorbeeld (antwoord altijd berekend met TxReference).
## Pure logica + data: geen nodes (ook gebruikt in tests/suites/t_lessons.gd).

const SAVE_KEY := "learning"     # TxSave setting: {"brute": {"kijk": true, "samen": true, "check": true}, ...}
const V := TxCodes.Verdict
const P := TxCodes.Phase
const C_DIM := "#96A39C"
const C_OK := "#3FE6A6"
const C_ERR := "#FF6A4A"
const C_HL := "#FFB23E"
const LEVEL_TXT := ["nog niet gezien", "demo bekeken", "samen geoefend", "begrepen"]

static var _mem := {}            # voortgang zonder save (nosave)
static var _parts_cache: Array = []


# ======================================================================
#  de delen (volgorde = opbouw)
# ======================================================================

## Elk deel: id, title, levels (Zelf; het eerste is de poort), page, rule, idea, kijk/samen: {stages, ask, auto, fig}.
## ask = voorspelvragen [{on: act, nth: n, q: soort}] (nth telt de zetten met die act in de les).
static func parts() -> Array:
	return [
		{"id": "brute", "title": "Brute kracht: elke start, tikken tellen", "levels": ["1-1", "1-2", "1-3"],
			"page": "Algoritme 2 · p. 50–51",
			"rule": "Probeer elke start i = 0 … n − m. strings_gelijk vergelijkt z[0], z[1], … met t[i], t[i+1], … en stopt bij het eerste verschil. Eén vergelijking = één tik.",
			"idea": "z = zoekwoord (lengte m), t = tekst (lengte n), posities vanaf 0. Na een verschil schuift het sjabloon 1 op en begint de naald opnieuw bij z[0]: de kop spoelt terug. Slechtste geval: (n − m + 1)·m tikken (Opmerking 9).",
			"kijk": {"stages": [{"machine": "brute", "z": "kerk", "t": "de_kerker", "find": "all"}],
				"ask": [{"on": "next", "nth": 3, "q": "ticks"}], "fig": "Algoritme 2, p. 50"},
			"samen": {"stages": [{"machine": "brute", "z": "nat", "t": "na_de_natte", "find": "all"}],
				"ask": [{"on": "go", "nth": 1, "q": "ticks"}, {"on": "next", "nth": 6, "q": "ticks"}]}},
		{"id": "rk_hash", "title": "Rabin-Karp: de hashwaarde h(s)", "levels": ["2-1"], "page": "Algoritme 3 · p. 52–54",
			"rule": "h(s) = g(s) mod q: lees de bits als binair getal. Met Horner per bit: ×2, en +1 als het bit 1 is; altijd mod q. Gelijke h → controleer de string (strings_gelijk).",
			"idea": "Het wiel kent enkel 0 … q − 1: dat is de modulo. Je mag na elke stap mod q nemen: (a·b) mod q = (a·(b mod q)) mod q.",
			"kijk": {"stages": [{"machine": "rk", "z": "00101", "q": 13, "signals": ["11011", "00101"], "prep": ["hz"], "find": "all"}],
				"ask": [{"on": "next_bit", "nth": 4, "q": "wheel"}], "fig": "Oefening 34 (z = 00101, q = 13)"},
			"samen": {"stages": [{"machine": "rk", "z": "110", "q": 5, "signals": ["011", "110"], "prep": ["hz"], "find": "all"}],
				"ask": [{"on": "next_bit", "nth": 5, "q": "wheel"}]}},
		{"id": "rk_rollen", "title": "Rabin-Karp: rollend bijwerken", "levels": ["2-2"], "page": "p. 53",
			"rule": "h(t_{p+1}…t_{p+m}) = (2·h(t_p…t_{p+m−1}) − t_p·2^m + t_{p+m}) mod q. Dus: ×2, −w als het bit dat links wegvalt 1 is (w = 2^m mod q), +1 als het nieuwe bit rechts 1 is.",
			"idea": "w reken je één keer vooraf uit: begin op 1 en verdubbel m keer (mod q). Daarna kost elk nieuw venster maar O(1) werk.",
			"kijk": {"stages": [{"machine": "rk", "z": "1011", "q": 7, "t": "0101101", "find": "all", "prep": ["w", "h0"], "prefill": {"hz": 4}}],
				"ask": [{"on": "minus_w", "nth": 1, "q": "minus"}, {"on": "slide", "nth": 3, "q": "wheel"}], "fig": "p. 53 (formule)"},
			"samen": {"stages": [{"machine": "rk", "z": "110", "q": 5, "t": "011010", "find": "all", "prep": ["w", "h0"], "prefill": {"hz": 1}}]}},
		{"id": "rk_vals", "title": "Rabin-Karp: alarm en valse treffer", "levels": ["2-3", "2-4"], "page": "p. 53–54 · Oefening 34",
			"rule": "Is h(venster) = h(z), dan gaat het alarm. Algoritme 3 roept dan nog strings_gelijk op: verschillen de strings toch, dan is het een valse treffer (hashbotsing).",
			"idea": "Verschillende strings kunnen dezelfde rest mod q hebben (bv. 10010 = 18 en 00101 = 5: allebei 5 mod 13). Daarom blijft het slechtste geval O((n − m + 1)·m) (Opmerking 10).",
			"kijk": {"stages": [{"machine": "rk", "z": "00101", "q": 13, "t": "100100101", "find": "all", "prep": ["h0"], "prefill": {"w": 6, "hz": 5}}],
				"ask": [{"on": "verify", "nth": 1, "q": "real"}, {"on": "verify", "nth": 3, "q": "real"}], "fig": "Oefening 34"},
			"samen": {"stages": [{"machine": "rk", "z": "110", "q": 5, "t": "0011100", "find": "all", "prep": ["h0"], "prefill": {"w": 3, "hz": 1}}],
				"ask": [{"on": "verify", "nth": 1, "q": "real"}]}},
		{"id": "kmp_idee", "title": "KMP: verschuiven zonder terug te lezen", "levels": ["3-1"], "page": "Definitie 11, Algoritme 4 · p. 55–59",
			"rule": "Mismatch op z[j]: schuif de kleinste s > 0 op waarbij z nog past op wat je al las (z[0..j−1−s] = z[s..j−1]); past niets, dan s = j. Dat is V[j]. Mismatch op z[0]: schuif 1.",
			"idea": "De leeskop in t gaat nooit terug: na het schuiven zijn de eerste j − s tekens al gelijk (gelijke_tekens) en vergelijkt de naald verder bij hetzelfde teken van t.",
			"kijk": {"stages": [{"machine": "kmp", "z": "barbados", "t": "barbaarse_barbecue_in_barbados", "find": "first", "strip": "none", "auto_zero": true}],
				"ask": [{"on": "shift", "nth": 1, "q": "shift"}, {"on": "shift", "nth": 3, "q": "gel"}], "fig": "p. 58 (barbados)"},
			"samen": {"stages": [{"machine": "kmp", "z": "kakao", "t": "kaka_kakakao", "find": "first", "strip": "none", "auto_zero": true}]}},
		{"id": "kmp_def11", "title": "KMP: de tabel V[] (Definitie 11)", "levels": ["3-2"], "page": "Definitie 11 · p. 56 · Oefening 40",
			"rule": "V[0] = 1. Voor j > 0: V[j] = de kleinste s met 0 < s < j en z[0..j−1−s] = z[s..j−1]; bestaat die niet, dan V[j] = j.",
			"idea": "V[j] hangt enkel af van z, niet van t: je weet bij een mismatch op j dat z[0..j−1] gelezen is. Probeer s = 1, 2, … tot de kopie op dat stuk past.",
			"kijk": {"stages": [{"machine": "kmp_table", "z": "barbados", "method": "def11", "cells": "m-1"}],
				"ask": [{"on": "punch", "nth": 4, "q": "v"}], "fig": "tabel p. 56 (barbados)"},
			"samen": {"stages": [{"machine": "kmp_table", "z": "kakao", "method": "def11", "cells": "m-1"}],
				"ask": [{"on": "punch", "nth": 3, "q": "v"}]}},
		{"id": "kmp_alg5", "title": "KMP: V[] met Algoritme 5 (z in zichzelf)", "levels": ["3-3"], "page": "Algoritme 5 · p. 60–62 · Oefening 39",
			"rule": "Zoek z in zichzelf vanaf start = 1 (gelijke_tekens = 0). eerste_mismatch = em. em = 0: V[start+1] = start+1. Anders: V[start+i] = start voor i = gelijke_tekens+1 … em. Dan start += V[em], gelijke_tekens = em − V[em] (0 als em = 0).",
			"idea": "V[0] = V[1] = 1 liggen vast. Wat de kopie onderweg leert, pons je meteen: zo kost de hele tabel O(m). Voorbij het einde staat ⏎ (past op niets).",
			"kijk": {"stages": [{"machine": "kmp_table", "z": "barbados", "method": "alg5", "cells": "m-1"}],
				"ask": [{"on": "punch_to", "nth": 3, "q": "fill"}, {"on": "shift", "nth": 3, "q": "start"}], "fig": "p. 61–62 (barbados)"},
			"samen": {"stages": [{"machine": "kmp_table", "z": "kokos", "method": "alg5", "cells": "m-1"}]}},
		{"id": "kmp_loop", "title": "KMP: de doorloop met de strook", "levels": ["3-4", "3-5"], "page": "Algoritme 4 · Stelling 12 · Oefening 41",
			"rule": "Mismatch op z[j]: lees V[j] op de strook, schuif V[j] op, gelijke_tekens = j − V[j]. Treffer en je zoekt alle voorkomens: schuif V[m] (Oefening 41).",
			"idea": "start + gelijke_tekens daalt nooit: elk teken van t wordt hoogstens één keer gelijk bevonden, plus ten hoogste n − m mislukte vergelijkingen: O(n).",
			"kijk": {"stages": [{"machine": "kmp", "z": "tata", "t": "tatata_tat", "find": "all", "strip": [1, 1, 2, 2, 2], "auto_zero": true}],
				"ask": [{"on": "shift", "nth": 1, "q": "shift"}], "fig": "Oefening 41"},
			"samen": {"stages": [{"machine": "kmp", "z": "kokos", "t": "kokokos_kokos", "find": "all", "strip": [1, 1, 2, 2, 2, 5], "auto_zero": true}]}},
		{"id": "bmh_tabel", "title": "Boyer-Moore-Horspool: de tabel V_H", "levels": ["4-1"], "page": "vul_VH · p. 63–65",
			"rule": "Eerst krijgt elk teken m. Dan voor i = 0 … m − 2: V_H(z[i]) = m − 1 − i. Een latere (meer rechtse) positie overschrijft. De laatste letter z[m−1] telt niet mee.",
			"idea": "V_H(x) = hoe ver je mag springen als x onder de laatste positie van het sjabloon staat: tot de laatste vorige x in z eronder komt.",
			"kijk": {"stages": [{"machine": "bmh", "z": "barbara", "cards": "stamp"}],
				"ask": [{"on": "stamp", "nth": 4, "q": "vh"}], "fig": "p. 65 (barbara)"},
			"samen": {"stages": [{"machine": "bmh", "z": "nonnen", "cards": "stamp"}]}},
		{"id": "bmh_loop", "title": "Boyer-Moore-Horspool: van rechts en springen", "levels": ["4-1", "4-2", "4-3", "4-4"], "page": "is_contained_BMH · p. 64–66",
			"rule": "i = m − 1 (positie in t onder de laatste letter). Vergelijk van rechts naar links. Daarna, treffer of niet: i = i + V_H(t[i]). Het sleutelteken is t[i], NIET het teken waar het misging.",
			"idea": "Staat t[i] niet in z (of enkel als laatste letter), dan spring je meteen m verder: bij lange woorden lees je zo veel tekens nooit.",
			"kijk": {"stages": [{"machine": "bmh", "z": "barbara", "t": "barbados_zoekt_barbara", "find": "first", "cards": "prefilled", "key_hint": true}],
				"ask": [{"on": "key", "nth": 2, "q": "jump"}], "fig": "p. 64–65"},
			"samen": {"stages": [{"machine": "bmh", "z": "nonnen", "t": "de_non_kent_nonnen", "find": "first", "cards": "prefilled", "key_hint": false}],
				"ask": [{"on": "key", "nth": 2, "q": "jump"}]}},
		{"id": "sa_cx", "title": "shift-AND: de vectoren C_x", "levels": ["5-1"], "page": "Definitie 13 · p. 67–68",
			"rule": "C_x[i] = 1 als z[i] = x, anders 0. Eén kaart per letter van z; elke andere letter = blanco (alles 0).",
			"idea": "Rij i van de kaart hoort bij positie i van z (rij 0 = bovenaan). Een gat = 1.",
			"kijk": {"stages": [{"machine": "shift_and", "z": "ana", "k": 0, "cards": "punch", "run": false}], "fig": "Figuur 23 (ana)"},
			"samen": {"stages": [{"machine": "shift_and", "z": "kaak", "k": 0, "cards": "punch", "run": false}]}},
		{"id": "sa_col", "title": "shift-AND: kolom M[][j] en de bel", "levels": ["5-1", "5-2", "5-3"], "page": "Definitie 13, Algoritme 6 · p. 67–69",
			"rule": "M[][j] = shift¹(M[][j−1]) & C_{t[j]}. shift¹ = elke 1 één rij omlaag en rij 0 aan (hendel); & = de kaart erin. Brandt de onderste lamp M[m−1][j], dan eindigt een treffer op j.",
			"idea": "M[i][j] = 1 betekent: z[0..i] past op het stuk van t dat op j eindigt. Je bewaart maar één kolom; de start (kolom −1) is overal 0.",
			"kijk": {"stages": [{"machine": "shift_and", "z": "ana", "t": "ananas", "k": 0, "cards": "prefilled", "find": "all"}],
				"ask": [{"on": "card", "nth": 3, "q": "col"}, {"on": "lever", "nth": 4, "q": "lever"}], "fig": "Figuur 23 (ana, ananas)"},
			"samen": {"stages": [{"machine": "shift_and", "z": "kaak", "t": "kakaak", "k": 0, "cards": "prefilled", "find": "all"}],
				"ask": [{"on": "card", "nth": 5, "q": "col"}]}},
		{"id": "sa_k", "title": "M^k: matches met k fouten", "levels": ["6-1", "6-2"], "page": "Definitie 14 · p. 70–71 · Oefening 60",
			"rule": "M^l[][j] = (1,0,…,0) | shift(M^(l−1)[][j−1]) | (shift(M^l[][j−1]) & C_{t[j]}). De foutkabel = shift(M^(l−1)[][j−1]): de oude kolom van het bord erboven, één rij omlaag; daar mag t[j] fout zijn.",
			"idea": "M^l[i][j] = 1: z[0..i] past met ten hoogste l mismatches op het stuk dat op j eindigt. Rij 0 van M^l (l > 0) is altijd 1: één teken mag altijd fout zijn.",
			"kijk": {"stages": [{"machine": "shift_and", "z": "ana", "t": "abana", "k": 1, "cards": "prefilled", "wiring": "plug", "find": "all"}],
				"ask": [{"on": "card", "nth": 3, "q": "col"}], "fig": "Definitie 14"},
			"samen": {"stages": [{"machine": "shift_and", "z": "kat", "t": "kot_kat", "k": 1, "cards": "prefilled", "wiring": "plug", "find": "all"}]}},
		{"id": "ed_fill", "title": "Editeerafstand: d[i][j] invullen", "levels": ["7-1", "7-2"], "page": "Definitie 15, Algoritme 7 · p. 71–76",
			"rule": "d[i][0] = i, d[0][j] = j. d[i][j] = min( d[i−1][j−1] + (0 als t[i−1] = t′[j−1], anders 1), d[i−1][j] + 1, d[i][j−1] + 1 ).",
			"idea": "d[i][j] = editeerafstand tussen de eerste i tekens van t en de eerste j tekens van t′. ↖ = vervangen (of gelijk: gratis), ↑ = verwijderen, ← = toevoegen. Rij per rij, van links naar rechts.",
			"kijk": {"stages": [{"machine": "edit", "a": "kat", "b": "kast", "approx": false, "want": 1}],
				"ask": [{"on": "fill", "nth": 6, "q": "cell"}], "until_phase": P.TRACE, "fig": "Algoritme 7"},
			"samen": {"stages": [{"machine": "edit", "a": "roos", "b": "rots", "approx": false, "want": 1}], "until_phase": P.TRACE}},
		{"id": "ed_trace", "title": "Editeerafstand: teruglopen naar de bewerkingen", "levels": ["7-1", "7-2"], "page": "Lemma 17 · p. 72–76",
			"rule": "Begin rechtsonder in d[|t|][|t′|]. Stap enkel naar een buur waaruit de waarde kwam (waarde = buur + kost). ↖ gelijk = niets, ↖ anders = vervang, ↑ = verwijder t[i−1], ← = voeg t′[j−1] toe.",
			"idea": "Het pad van (0,0) naar rechtsonder is een kortste reeks bewerkingen; er kunnen er meerdere zijn. In stijgende volgorde opgeschreven (Lemma 17) kloppen de posities meteen.",
			"kijk": {"stages": [{"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": 1, "prefill_rows": 6}],
				"ask": [{"on": "step", "nth": 3, "q": "op"}], "fig": "p. 72, 76 (lessen → feesten)"},
			"samen": {"stages": [{"machine": "edit", "a": "kat", "b": "kast", "approx": false, "want": 1, "prefill_rows": 3}]}},
		{"id": "alg8", "title": "Algoritme 8: de beste benaderende match", "levels": ["8-1", "8-2", "8-3"], "page": "Algoritme 8 · p. 77–80",
			"rule": "Zelfde regel als Algoritme 7, maar D[0][j] = 0 (overal instappen in t). Het antwoord is de kleinste waarde in de onderste rij; loop vandaar terug tot rij 0.",
			"idea": "D[i][j] = kleinste editeerafstand tussen z[0..i−1] en een deelwoord van t dat op t[j−1] eindigt. Waar het pad rij 0 bereikt, begint de match.",
			"kijk": {"stages": [{"machine": "edit", "a": "kat", "b": "de_kast", "approx": true, "want": 1, "prefill_rows": 1}],
				"ask": [{"on": "pick_end", "nth": 1, "q": "end"}], "fig": "Algoritme 8"},
			"samen": {"stages": [{"machine": "edit", "a": "tak", "b": "de_tas", "approx": true, "want": 1}]}},
	]


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


static func cfg(id: String, phase: String) -> Dictionary:
	return part(id).get(phase, {})


## Delen waarvan `level` de poort is (het eerste Zelf-level): badges op de missiekaart.
static func parts_for_level(level: String) -> Array:
	var out := []
	for p in all_parts():
		if str(p.levels[0]) == level:
			out.append(p.id)
	return out


## Delen die `level` oefent (poort of later).
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
	if ps.size() > 2:
		ps = ps.slice(ps.size() - 2)
	return ps


## Lessen die vóór `level` nog moeten (eerste keer verplicht): elk deel met poort ≤ level waarvan Samen nog niet
## gedaan is -> [{part, phase}] (Kijk dan Samen, in volgorde van het leerpad). De finale/Nachtdienst: niets.
static func pending_for_level(level: String) -> Array:
	var order: Array = Array(TxLevels.IDS)
	var li := order.find(level)
	if li < 0 or level == "F":
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
#  voortgang (TxSave setting "learning")
# ======================================================================

static func progress(id: String) -> Dictionary:
	var d = _mem if TxSession.has("nosave") else TxSave.setting(SAVE_KEY, {})
	if d is Dictionary and (d as Dictionary).get(id) is Dictionary:
		return d[id]
	return {}


static func mark(id: String, key: String, value := true) -> void:
	var d = _mem if TxSession.has("nosave") else TxSave.setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	var e: Dictionary = (d.get(id) as Dictionary).duplicate() if d.get(id) is Dictionary else {}
	e[key] = value
	d[id] = e
	if TxSession.has("nosave"):
		_mem = d
	else:
		TxSave.set_setting(SAVE_KEY, d)


static func reset_progress() -> void:
	_mem = {}
	if not TxSession.has("nosave"):
		TxSave.set_setting(SAVE_KEY, {})


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

static func spec(id: String, phase: String) -> TxLevelSpec:
	var p := part(id)
	if p.is_empty():
		return null
	var c: Dictionary = p.get(phase, {})
	var s := TxLevelSpec.new()
	s.id = "LES"
	s.dossier = TxLevels.dossier_of(str(p.levels[0]))
	s.title = "%s · %s" % ["Kijk" if phase == "kijk" else "Samen", p.title]
	s.intro = ""
	s.notes_ref = "lesnotas " + str(p.page)
	s.priority = "P0"
	s.mode = TxCodes.Mode.CALM
	for st in c.get("stages", []):
		s.stages.append((st as Dictionary).duplicate(true))
	s.stars = [TxLevels.S_DONE, TxLevels.S_NOMIS, TxLevels.S_HELP]
	s.hints_allowed = true
	return s


## Director zoals de les start (tests en de coach).
static func make_director(id: String, phase: String) -> TxDirector:
	var dd := TxDirector.new()
	dd.start(spec(id, phase))
	return dd


# ======================================================================
#  opmaak
# ======================================================================

static func code(s: String) -> String:
	return "[code]%s[/code]" % s.replace("[", "[lb]")


static func sub(base: String, idx: String) -> String:
	return "%s[font_size=16]%s[/font_size]" % [base, idx]


## Haken van indices ontsnappen ([lb]) en symbolen die Fredoka niet heeft in het monolettertype zetten.
static func bb(s: String) -> String:
	var re := RegEx.create_from_string("\\[(?!/?(b|code|color|font_size|lb|rb)[\\]=])")
	var out := re.sub(s, "[lb]", true)
	out = RegEx.create_from_string("([A-Za-z])_\\{([^}]*)\\}").sub(out, "$1[font_size=16]$2[/font_size]", true)
	out = RegEx.create_from_string("\\b([A-Za-z])_([a-z0-9])\\b").sub(out, "$1[font_size=16]$2[/font_size]", true)
	for sym in ["≠", "≡", "↖", "↑", "←", "→", "✓", "✗", "≤", "≥", "⏎", "∅"]:
		out = out.replace(sym, "[code]%s[/code]" % sym)
	return out


static func bits(a) -> String:
	var s := ""
	for x in a:
		s += str(int(x))
	return s


static func _join(a: Array, sep := " ") -> String:
	var out := PackedStringArray()
	for x in a:
		out.append(str(x))
	return sep.join(out)


static func _strip_txt(strip: Array, n: int) -> String:
	var out := PackedStringArray()
	for j in n:
		var v := int(strip[j]) if j < strip.size() else -1
		out.append(str(v) if v > 0 else ("#" if v == TxCodes.STRIP_BURNT else "_"))
	return " ".join(out)


static func _arrow(dir: String) -> String:
	return {"diag": "↖", "up": "↑", "left": "←"}.get(dir, "?")


## Proefkopie van een machine (zelfde stage, carry en toestand).
static func copy(mc: TxMachine) -> TxMachine:
	var m2 := TxLevels.make_machine(mc.stage, mc.carry_in, TxCodes.Mode.CALM)
	m2.restore(mc.snapshot())
	return m2


## Speelt mv op een kopie: {mc: kopie na de zet, r: resultaat, entries: logregels van deze zet (ook automatische)}.
static func trial(mc: TxMachine, mv: Dictionary) -> Dictionary:
	var m2 := copy(mc)
	var before := m2.log.size()
	var r := m2.apply(mv)
	var es: Array = []
	for k in range(before, m2.log.size()):
		es.append(m2.log.entry(k))
	return {"mc": m2, "r": r, "entries": es}


# ======================================================================
#  toestand (zoals op het examen)
# ======================================================================

## Mono-tabel: rijen [label, cellen...] met gelijke kolombreedte.
static func table(rows: Array) -> String:
	var w := 1
	var lw := 1
	for r in rows:
		lw = maxi(lw, str(r[0]).length())
		for k in range(1, r.size()):
			w = maxi(w, str(r[k]).length())
	var lines := PackedStringArray()
	for r in rows:
		var l := str(r[0]).rpad(lw + 1)
		for k in range(1, r.size()):
			l += str(r[k]).lpad(w) + " "
		lines.append(l.strip_edges(false, true))
	return "[code]%s[/code]" % "\n".join(lines).replace("[", "[lb]")


static func state(mc: TxMachine) -> String:
	if mc == null:
		return ""
	if mc is TxBrute:
		var b := mc as TxBrute
		return "start i = %d · tikken = %d · startposities n − m + 1 = %d − %d + 1 = %d" % [b.start, int(b.counters.ticks), b.n, b.m, b.n - b.m + 1]
	if mc is TxRabinKarp:
		var r := mc as TxRabinKarp
		var s := "q = %d · w = 2^m mod q = %s · h(z) = %s · wiel = %d" % [r.q, str(r.w) if r.w >= 0 else "?", str(r.hz) if r.hz >= 0 else "?", r.wheel]
		if r.phase == P.HORNER:
			s += "\nHorner op %s: bit %d (s_%d = %s), bits 0 … %d" % [r.bits, r.bit_k, r.bit_k, r.bits[r.bit_k] if r.bit_k < r.bits.length() else "", r.bits.length() - 1]
		elif r.phase == P.ROLL:
			s += "\nvenster p = %d: %s → p + 1 = %d (uit: %s, in: %s)" % [r.i, r.window_bits(r.i), r.i + 1, r.t[r.i], r.t[r.i + r.m] if r.i + r.m < r.n else "–"]
		elif r.phase == P.ALARM:
			s += "\nalarm bij venster %s" % r.window_bits(r.si if r.signal_mode() else r.i)
		return s
	if mc is TxKmpTable:
		var kt := mc as TxKmpTable
		var hdr: Array = ["j"]
		var zr: Array = ["z[j]"]
		var vr: Array = ["V[j]"]
		for j in kt.strip.size():
			if j >= kt.cells_n:
				break
			hdr.append(j)
			zr.append(kt.z[j] if j < kt.m else "")
			vr.append(str(kt.strip[j]) if int(kt.strip[j]) > 0 else "_")
		var s2 := table([hdr, zr, vr])
		if kt.method == "alg5" and kt.phase != P.DONE and not kt.is_done():
			s2 += "\nstart = %d · gelijke_tekens = %d%s" % [kt.start, kt.gel, (" · eerste_mismatch = %d" % kt.em) if kt.em >= 0 else ""]
		return s2
	if mc is TxKmp:
		var km := mc as TxKmp
		var s3 := ""
		if not km.strip.is_empty():
			var hdr2: Array = ["j"]
			var vr2: Array = ["V[j]"]
			for j in km.strip.size():
				hdr2.append(j)
				vr2.append(str(km.strip[j]) if int(km.strip[j]) > 0 else "_")
			s3 = table([hdr2, vr2]) + "\n"
		s3 += "start = %d · gelijke_tekens = %d · tikken = %d" % [km.start, km.gel, int(km.counters.ticks)]
		if km.phase == P.DECIDE and km.em >= 0:
			s3 += " · eerste_mismatch = %d" % km.em
		return s3
	if mc is TxBmh:
		var bm := mc as TxBmh
		var keys: Array = bm.vh.keys()
		var hdr3: Array = ["x"]
		var vr3: Array = ["V_H(x)"]
		for x in keys:
			hdr3.append(x)
			vr3.append(str(bm.cards[x]) if bm.cards.has(x) else "_")
		hdr3.append("anders")
		vr3.append(bm.m)
		var s4 := table([hdr3, vr3])
		if bm.t != "" and bm.phase != P.CARDS:
			s4 += "\ni = %d (start %d) · tikken = %d" % [bm.i, bm.i - bm.m + 1, int(bm.counters.ticks)]
		return s4
	if mc is TxShiftAnd:
		var sa := mc as TxShiftAnd
		var rows: Array = [["i"], ["z[i]"]]
		for i in sa.m:
			rows[0].append(i)
			rows[1].append(sa.z[i])
		for x in sa.c_true:
			var r2: Array = ["C_" + str(x)]
			for i in sa.m:
				r2.append(int(sa.cards[x][i]))
			rows.append(r2)
		if sa.t != "" and sa.phase != P.CARDS:
			var cols: Array = sa.shown_cols()
			for l in sa.k + 1:
				var lb := ("M" if l == 0 else "M^%d" % l) + "[][%d]" % (sa.j - 1)
				var r3: Array = ["shift¹ " + lb if sa.lever_pulled else lb]
				for i in sa.m:
					r3.append(int(cols[l][i]))
				rows.append(r3)
		var s5 := table(rows)
		if sa.t != "" and sa.phase in [P.LEVER, P.CARD]:
			s5 += "\nj = %d · t[j] = %s · %s" % [sa.j, sa.t[sa.j] if sa.j < sa.n else "", "hendel getrokken" if sa.lever_pulled else "hendel nog niet getrokken"]
		return s5
	if mc is TxEditBoard:
		var eb := mc as TxEditBoard
		var c := eb.cursor()
		var nm := "D" if eb.approx else "d"
		if eb.phase == P.FILL:
			var fv := eb._fill_values(eb.ci, eb.cj)
			var sa_ := "z" if eb.approx else "t"
			var sb_ := "t" if eb.approx else "t′"
			return "%s[%d][%d] = min(↖ %d + %d, ↑ %d + 1, ← %d + 1)\n%s[%d] = %s, %s[%d] = %s" % [nm, eb.ci, eb.cj, int(fv.a), int(fv.c),
				int(fv.b), int(fv.d), sa_, eb.ci - 1, eb.a[eb.ci - 1], sb_, eb.cj - 1, eb.b[eb.cj - 1]]
		if eb.phase == P.PICK_END:
			return "onderste rij D[%d][]: %s · minimum = %d" % [eb.ra, _join(eb.tab[eb.ra]), eb.row_min()]
		var path := PackedStringArray()
		for st in eb.trace_steps:
			path.append(_arrow(str(st.dir)))
		return "%s(%s, %s) = %d · cel (%d, %d) · pad terug: %s" % [nm, "z" if eb.approx else "t", "t" if eb.approx else "t′",
			eb.best_true, int(c.i), int(c.j), " ".join(path) if not path.is_empty() else "–"]
	return ""


# ======================================================================
#  verteltekst per stap (Kijk) — wat + waarom; resultaten uit een proefkopie
# ======================================================================

static func _brute_res(z: String, t: String, i: int) -> String:
	var m := z.length()
	var res := m
	for k in m:
		if z[k] != t[i + k]:
			res = k
			break
	if res == m:
		return "alle %d tekens gelijk: [color=%s]treffer op %d[/color], %d tikken" % [m, C_OK, i, m]
	if res == 0:
		return "z[0] = %s ≠ t[%d] = %s: meteen verschil, 1 tik" % [code(z[0]), i, code(t[i])]
	return "z[0..%d] = %s gelijk, z[%d] = %s ≠ t[%d] = %s: %d tikken" % [res - 1, code(z.substr(0, res)), res, code(z[res]),
		i + res, code(t[i + res]), res + 1]


static func _brute_ticks(z: String, t: String, i: int) -> int:
	var m := z.length()
	for k in m:
		if z[k] != t[i + k]:
			return k + 1
	return m


## Samenvatting van wat de machine na de zet vanzelf deed (automatische zetten in de log).
static func auto_note(entries: Array) -> String:
	var zero := PackedStringArray()
	for e in entries:
		if not bool(e.get("auto", false)):
			continue
		var ty := str(e.get("type", ""))
		var d: Dictionary = e.get("data", {})
		if ty in ["SHIFT", "STRIP"] and int(d.get("j", -1)) == 0:
			zero.append(str(int(d.get("s", 1))))
	if zero.is_empty():
		return ""
	return "Daarna vanzelf: %d× mismatch al op z[0] → telkens 1 opschuiven (V[0] = 1)." % zero.size()


static func narrate(mc: TxMachine, mv: Dictionary) -> Dictionary:
	var act := str(mv.get("act", ""))
	var tr := trial(mc, mv)
	var m2: TxMachine = tr.mc
	var out := {"what": "", "why": "", "after": auto_note(tr.entries)}
	if mc is TxBrute:
		var i := 0 if act == "go" else (mc as TxBrute).start + 1
		if i > mc.n - mc.m:
			out.what = "Start %d > n − m = %d: er past geen sjabloon meer. Klaar." % [i, mc.n - mc.m]
			out.why = "Totaal: %d tikken voor %d startposities (slechtste geval (n − m + 1)·m = %d)." % [int(mc.counters.ticks), mc.n - mc.m + 1, (mc.n - mc.m + 1) * mc.m]
			return out
		out.what = "Start %d: %s." % [i, _brute_res(mc.z, mc.t, i)]
		out.why = "De naald begint bij z[0] en vergelijkt van links naar rechts tot het eerste verschil." if act == "go" \
			else "Brute kracht probeert élke start: schuif 1 op en begin opnieuw bij z[0] (de kop spoelt terug naar t[%d])." % i
		if i == mc.n - mc.m:
			out.why += " Dit is de laatste start: n − m = %d." % (mc.n - mc.m)
	elif mc is TxRabinKarp:
		_n_rk(mc as TxRabinKarp, m2 as TxRabinKarp, mv, out)
	elif mc is TxKmpTable:
		_n_table(mc as TxKmpTable, m2 as TxKmpTable, mv, out)
	elif mc is TxKmp:
		_n_kmp(mc as TxKmp, m2 as TxKmp, mv, out)
	elif mc is TxBmh:
		_n_bmh(mc as TxBmh, m2 as TxBmh, mv, out)
	elif mc is TxShiftAnd:
		_n_sa(mc as TxShiftAnd, m2 as TxShiftAnd, mv, out)
	elif mc is TxEditBoard:
		_n_edit(mc as TxEditBoard, m2 as TxEditBoard, mv, out)
	return out


static func _n_rk(r: TxRabinKarp, r2: TxRabinKarp, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	var op := str(mv.get("op", ""))
	match r.phase:
		P.W_CALC:
			if act == "wheel":
				out.what = "×2: wiel %d → 2·%d mod %d = %d." % [r.wheel, r.wheel, r.q, r2.wheel]
				out.why = "w = 2^m mod q: begin op 1 en verdubbel m = %d keer (dit is keer %d)." % [r.m, r.doubles + 1]
			else:
				out.what = "w = %d vastzetten: 2^%d = %d en %d mod %d = %d." % [r.wheel, r.m, 1 << r.m, 1 << r.m, r.q, r.w_true]
				out.why = "Die waarde trek je bij het rollen af als het bit dat links wegvalt 1 is."
		P.HORNER:
			var b := r.bits[r.bit_k]
			var what_s := "h(z)" if r.part == "z" else ("venster 0" if r.part == "window" else "signaal %s" % r.bits)
			if act == "wheel" and op == "double":
				out.what = "Bit %d van %s (= %s): eerst ×2: %d → %d." % [r.bit_k, what_s, b, r.wheel, r2.wheel]
				out.why = "Horner: g(s_0…s_k) = 2·g(s_0…s_{k−1}) + s_k. Mod q mag tussendoor: het wiel toont meteen de rest."
			elif act == "wheel":
				out.what = "Het bit is 1: +1: %d → %d." % [r.wheel, r2.wheel]
				out.why = "+ s_k met s_k = 1 (bij een 0 doe je niets)."
			else:
				var pre := r.bits.substr(0, r.bit_k + 1)
				var g := pre.bin_to_int()
				out.what = "Bit %d klaar: g(%s) = %d en %d mod %d = %d: het wiel toont %d." % [r.bit_k, pre, g, g, r.q, g % r.q, r.wheel]
				if r.bit_k == r.bits.length() - 1:
					if r.part == "z":
						out.why = "Klaar: h(z) = %d. Dat is de rode inkeping op het wiel: elk venster met dezelfde stand geeft alarm." % r.wheel
					elif r.part == "window":
						out.why = "Klaar: h(venster 0) = h(t_0…t_{m−1}) = %d%s. Vanaf nu rol je: elk volgend venster kost O(1)." % [r.wheel, (" = h(z): [color=%s]alarm![/color]" % C_HL) if r.wheel == r.hz else ""]
					else:
						out.why = "Klaar: h(%s) = %d%s." % [r.bits, r.wheel, " = h(z): alarm!" if r.wheel == r.hz else " ≠ h(z) = %d: zeker geen treffer, de string hoeft niet vergeleken" % r.hz]
				else:
					out.why = ""
		P.ROLL:
			var p := r.i
			var ob := r.t[p]
			var ib := r.t[p + r.m] if p + r.m < r.n else "0"
			if act == "wheel" and op == "double":
				out.what = "Rollen van venster %d (%s) naar %d (%s): ×2: %d → %d." % [p, r.window_bits(p), p + 1, r.window_bits(p + 1), r.wheel, r2.wheel]
				out.why = "h_{p+1} = (2·h_p − t_p·2^m + t_{p+m}) mod q: alle bits schuiven één plaats op."
			elif act == "wheel" and op == "minus_w":
				out.what = "t_%d = 1 valt links weg: −w = −%d: %d → %d." % [p, r.w, r.wheel, r2.wheel]
				out.why = "Na ×2 staat dat bit op plaats 2^m: −t_p·2^m, en 2^m mod q = w = %d." % r.w
			elif act == "wheel":
				out.what = "t_%d = 1 komt rechts binnen: +1: %d → %d." % [p + r.m, r.wheel, r2.wheel]
				out.why = "+ t_{p+m}."
			else:
				var hv := r.window_bits(p + 1).bin_to_int()
				out.what = "Venster %d = %s: h = %d (controle: %d mod %d = %d)%s." % [p + 1, r.window_bits(p + 1), r.wheel, hv, r.q, hv % r.q,
					(" — [color=%s]= h(z): alarm![/color]" % C_HL) if r.wheel == r.hz else ""]
				var parts_s := "2·h"
				if ob == "1":
					parts_s += " − w"
				if ib == "1":
					parts_s += " + 1"
				out.why = "Uit = %s, in = %s: %s, mod %d." % [ob, ib, parts_s, r.q]
		P.ALARM:
			var win := r.window_bits(r.si if r.signal_mode() else r.i)
			var real := win == r.z
			var k := 0
			while k < r.m and win[k] == r.z[k]:
				k += 1
			if real:
				out.what = "Alarm: h = %d = h(z). Controleer met strings_gelijk: %s = %s: [color=%s]echte treffer[/color] (%d tikken)." % [r.hz, code(win), code(r.z), C_OK, r.m]
			else:
				out.what = "Alarm: h = %d = h(z). Controleer met strings_gelijk: %s en %s verschillen op positie %d: [color=%s]valse treffer[/color] (%d tik%s)." % [r.hz, code(win), code(r.z), k, C_ERR, k + 1, "" if k == 0 else "ken"]
			out.why = "Gelijke hash ≠ gelijke string: Algoritme 3 roept na een gelijke hash nog strings_gelijk op (p. 53)."


static func _gel_txt(j: int, s: int) -> String:
	return "gelijke_tekens = %d − %d = %d" % [j, s, j - s] if s < j else "gelijke_tekens = 0"


static func why_v(z: String, j: int) -> String:
	if j == 0:
		return "V[0] = 1 (Definitie 11)."
	var read := z.substr(0, j)
	var tries := PackedStringArray()
	for s in range(1, j):
		if TxReference.mesh(z, j, s):
			tries.append("s = %d ✓ (%s = %s)" % [s, code(z.substr(0, j - s)), code(z.substr(s, j - s))])
			return "Gelezen z[0..%d] = %s. %s → V[%d] = %d." % [j - 1, code(read), ", ".join(tries), j, s]
		tries.append("s = %d ✗" % s)
	return "Gelezen z[0..%d] = %s. %sgeen 0 < s < %d past → V[%d] = %d." % [j - 1, code(read), (", ".join(tries) + ": ") if not tries.is_empty() else "",
		j, j, j]


static func _n_kmp(k: TxKmp, k2: TxKmp, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	if act == "go":
		var em := k2.em if k2.phase == P.DECIDE else -1
		out.what = "Start 0: de naald vergelijkt z met t vanaf z[0]."
		out.why = "Algoritme 4 = brute kracht, maar na een mismatch springt het sjabloon slimmer en leest de kop nooit terug."
		if em == k2.m:
			out.after = "[color=%s]Treffer op start %d.[/color]" % [C_OK, k2.start]
		elif em >= 0:
			out.after = "Eerste stop: start %d, mismatch op z[%d]. %s" % [k2.start, em, str(out.after)]
		return
	var j := k.em
	var s := int(mv.get("s", k.strip_cell(j)))
	var v := int(k.vv[j])
	if j == k.m:
		out.what = "[color=%s]Treffer op start %d.[/color] Alle voorkomens: schuif V[m] = V[%d] = %d op (Oefening 41)." % [C_OK, k.start, j, v]
		out.why = "V[m] volgt uit Definitie 11 met j = m: z[0..%d] = %s is helemaal gelezen. %s. Nieuwe start = %d." % [j - 1, code(k.z),
			_gel_txt(j, s), k.start + s]
	else:
		var tc := k.t[k.start + j] if k.start + j < k.n else "⏎"
		out.what = "Mismatch op z[%d] = %s ≠ t[%d] = %s. Schuif V[%d] = %d op: start %d → %d; %s." % [j, code(k.z[j]), k.start + j, code(tc),
			j, s, k.start, k.start + s, _gel_txt(j, s)]
		out.why = why_v(k.z, j)
		if s < j:
			out.why += " De naald gaat verder bij z[%d] onder dezelfde t[%d]: de leeskop gaat niet terug." % [j - s, k.start + j]
	if k2.hits.size() > k.hits.size():
		out.after = "[color=%s]Treffer op start %d.[/color] %s" % [C_OK, int(k2.hits[k2.hits.size() - 1].start), str(out.after)]


static func _n_table(kt: TxKmpTable, k2: TxKmpTable, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	if act == "punch":
		var j := int(mv.j)
		out.what = "Vakje j = %d: V[%d] = %d." % [j, j, int(mv.v)]
		out.why = why_v(kt.z, j)
		return
	if act == "done":
		out.what = "Klaar: alle vakjes geponst."
		return
	if act == "punch_to":
		var a := kt.punch_from()
		var b := int(mv.to)
		var em := kt.em
		var mis := ""
		if em < kt.m:
			var tc := kt.z[kt.start + em] if kt.start + em < kt.m else "⏎"
			mis = "z[%d] = %s ≠ z[%d] = %s" % [em, code(kt.z[em]), kt.start + em, code(tc)]
		out.what = "start = %d, gelijke_tekens = %d: eerste_mismatch = %d (%s)." % [kt.start, kt.gel, em, mis]
		if em == 0:
			out.what += " Dus V[%d] = start + 1 = %d." % [kt.start + 1, kt.start + 1]
			out.why = "em = 0: zelfs z[0] past niet op start %d, dus ook bij een mismatch op %d moet je %d opschuiven." % [kt.start, kt.start + 1, kt.start + 1]
		else:
			out.what += " Dus V[%s] = start = %d." % [("%d" % a) if a == b else "%d..%d" % [a, b], kt.start]
			out.why = "Tot positie %d past de kopie (start %d): voor een mismatch op i = %d … %d is verschuiving %d de kleinste die past." % [kt.start + em - 1,
				kt.start, a, b, kt.start]
		return
	var em2 := kt.em
	var sh := int(mv.get("s", 1))
	out.what = "Schuif de kopie V[eerste_mismatch] = V[%d] = %d op: start %d → %d; gelijke_tekens = %s." % [em2, sh, kt.start, kt.start + sh,
		("0 (em = 0)" if em2 == 0 else "%d − %d = %d" % [em2, sh, em2 - sh])]
	out.why = "Zoals in Algoritme 4. V[%d] staat al op de strook: em ≤ start, en alles tot start is al ingevuld." % em2
	if k2.is_done():
		out.after = "start + gelijke_tekens = %d ≥ m − 1 = %d: de tabel is klaar." % [k2.start + k2.gel, k2.m - 1]


static func _bmh_cmp(b: TxBmh, i: int) -> String:
	var m := b.m
	var k := 0
	while k < m and b.z[m - 1 - k] == b.t[i - k]:
		k += 1
	if k == m:
		return "alle %d gelijk: [color=%s]treffer op start %d[/color]" % [m, C_OK, i - m + 1]
	return "z[%d] = %s ≠ t[%d] = %s na %d gelijk (%d tik%s)" % [m - 1 - k, code(b.z[m - 1 - k]), i - k, code(b.t[i - k]), k, k + 1, "" if k == 0 else "ken"]


static func _n_bmh(b: TxBmh, b2: TxBmh, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	match act:
		"stamp":
			var p := int(mv.i)
			var x := b.z[p]
			var old := int(b.cards.get(x, -1))
			out.what = "z[%d] = %s: V_H(%s) = m − 1 − %d = %d − 1 − %d = %d%s." % [p, code(x), code(x), p, b.m, p, b.m - 1 - p,
				(" (overschrijft %d)" % old) if old > 0 else ""]
			out.why = "Van links naar rechts: zo blijft de meest rechtse positie vóór de laatste letter staan."
			if p == b.m - 2:
				out.why += " z[%d] (de laatste letter) stempel je niet." % (b.m - 1)
		"cards_done":
			out.what = "Klaar. Elke andere letter (ook een die enkel als laatste letter in z staat) krijgt m = %d." % b.m
			out.why = "Staat x niet links van de laatste positie in z, dan kan geen voorkomen x onder de laatste positie hebben vóór m sprongen."
		"go":
			out.what = "Start: i = m − 1 = %d (t[i] onder de laatste letter). Van rechts naar links: %s." % [b.m - 1, _bmh_cmp(b, b.m - 1)]
			out.why = "strings_gelijk_invers begint achteraan in z."
		_:
			var key := b.t[b.i]
			var s := TxReference.vh_of(b.vh, key, b.m)
			var mis := ""
			if b.mis_z >= 0 and b.t[b.i - (b.m - 1 - b.mis_z)] != key:
				mis = " (niet het mismatchteken %s)" % code(b.t[b.i - (b.m - 1 - b.mis_z)])
			out.what = "Sleutelteken t[%d] = %s%s: V_H(%s) = %d → i = %d + %d = %d." % [b.i, code(key), mis, code(key), s, b.i, s, b.i + s]
			if b.vh.has(key):
				out.why = "De laatste %s vóór het einde van z staat op positie %d: na %d plaatsen staat die onder t[%d]." % [code(key), b.m - 1 - s, s, b.i]
			else:
				out.why = "%s staat niet in z[0..%d]: geen enkele start die t[%d] bevat kan passen, dus de volle sprong m = %d." % [code(key), b.m - 2, b.i, b.m]
			if b2.phase == P.DECIDE or b2.hits.size() > b.hits.size():
				out.after = "Nieuwe uitlijning i = %d: %s." % [b.i + s, _bmh_cmp(b, b.i + s)] if b.i + s < b.n else ""
			elif b.i + s >= b.n:
				out.after = "i = %d ≥ n = %d: einde van het lint." % [b.i + s, b.n]


## Sleutel voor tellen (voorspelvragen, afbouwende tips): de act, of bij het wiel de bewerking (double, minus_w, plus1).
static func act_key(mv: Dictionary) -> String:
	var act := str(mv.get("act", ""))
	return str(mv.get("op", act)) if act == "wheel" else act


static func mname(l: int) -> String:
	return "M" if l == 0 else ("M¹" if l == 1 else "M^%d" % l)


## Kijk: de zetten die samen één vertelde stap vormen ([{mv, mc}], mc = toestand vlak vóór die zet; kopieën).
## Rabin-Karp: ×2/−w/+1 horen bij het bit of venster dat ze afsluiten (next_bit, slide, commit); de rest: één zet.
static func kijk_group(mc: TxMachine) -> Array:
	var mv := mc.correct_move()
	if not mc is TxRabinKarp or str(mv.get("act", "")) != "wheel":
		return [{"mv": mv, "mc": mc}]
	var out: Array = []
	var cur := mc
	var guard := 0
	while guard < 40:
		guard += 1
		var m2 := cur.correct_move()
		out.append({"mv": m2, "mc": cur})
		if str(m2.get("act", "")) != "wheel":
			break
		var nx := copy(cur)
		nx.apply(m2)
		cur = nx
	return out


static func narrate_group(group: Array) -> Dictionary:
	if group.size() == 1:
		return narrate(group[0].mc, group[0].mv)
	var first: TxMachine = group[0].mc
	if first is TxRabinKarp and first.phase == P.W_CALC:
		var r := first as TxRabinKarp
		var vals := PackedStringArray([str(r.wheel)])
		var v := r.wheel
		for k in r.m:
			v = (2 * v) % r.q
			vals.append(str(v))
		return {"what": "w = 2^m mod q: begin op 1 en verdubbel m = %d keer (mod %d): %s. Zet w = %d vast." % [r.m, r.q, " → ".join(vals), r.w_true],
			"why": "Controle: 2^%d = %d en %d mod %d = %d. Die waarde trek je bij het rollen af als het bit dat links wegvalt 1 is." % [r.m, 1 << r.m, 1 << r.m, r.q, r.w_true],
			"after": ""}
	var whats := PackedStringArray()
	var why := ""
	var first_why := ""
	var after := ""
	for it in group:
		var n := narrate(it.mc, it.mv)
		whats.append(str(n.what))
		if first_why == "":
			first_why = str(n.why)
		if str(n.why) != "" and str(it.mv.get("act", "")) != "wheel":
			why = str(n.why)
		after = str(n.after)
	return {"what": " ".join(whats), "why": why if why != "" else first_why, "after": after}


static func col_txt(col: Array) -> String:
	return bits(col)


static func _n_sa(s: TxShiftAnd, s2: TxShiftAnd, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	match act:
		"hole":
			var x := str(mv.x)
			var i := int(mv.i)
			out.what = "z[%d] = %s: gat in kaart %s op rij %d (%s[%d] = 1)." % [i, code(x), code(x), i, sub("C", x), i]
			out.why = "%s[i] = 1 precies waar z[i] = %s." % [sub("C", x), code(x)]
		"cards_done":
			var parts_s := PackedStringArray()
			for x in s.c_true:
				parts_s.append("%s = %s" % [sub("C", x), bits(s.c_true[x])])
			out.what = "Kaarten klaar: %s; blanco = %s." % [", ".join(parts_s), bits(TxReference.zeros(s.m))]
			out.why = "Lees een kaart van boven (rij 0) naar onder (rij m − 1)."
		"plug":
			out.what = "Foutkabel van %s naar %s in [b]oud ↓[/b]: shift(%s[][j−1])." % [mname(int(mv.l) - 1), mname(int(mv.l)), mname(int(mv.l) - 1)]
			out.why = "M^l[i][j] = 1 als z[0..i−1] met ≤ l − 1 fouten op j − 1 eindigt: dan mag t[j] fout zijn (Definitie 14, eerste reden)."
		"wire_done":
			out.what = "Bedrading klaar."
			out.why = "De tweede reden (t[j] = z[i]) loopt via de eigen hendel en kaart van elk bord."
		"lever":
			var before: Array = s.shown_cols()
			var after: Array = s2.shown_cols()
			if s.k == 0:
				out.what = "j = %d: hendel = shift¹(M[][%d]) = shift¹(%s) = %s." % [s.j, s.j - 1, bits(before[0]), bits(after[0])]
			else:
				var ps := PackedStringArray()
				for l in s.k + 1:
					ps.append("%s: %s → %s" % [mname(l), bits(before[l]), bits(after[l])])
				out.what = "j = %d: hendel (shift¹ op elk bord): %s." % [s.j, " · ".join(ps)]
			out.why = "Elke 1 schuift één rij omlaag (z[0..i−1] past → misschien ook z[0..i]) en rij 0 gaat aan: op elke plaats kan een match beginnen."
		"card":
			var x2 := str(mv.x)
			var cx: Array = s.c_true[x2] if x2 != "" else TxReference.zeros(s.m)
			var nm := sub("C", x2) if x2 != "" else "blanco"
			var after2: Array = s2.prev
			var shifted: Array = s.shown_cols()
			if s.k == 0:
				out.what = "t[%d] = %s → kaart %s = %s: %s & %s = M[][%d] = %s." % [s.j, code(s.t[s.j]), nm, bits(cx), bits(shifted[0]), bits(cx), s.j, bits(after2[0])]
			else:
				var own := TxReference.and_cols(shifted[1], cx)
				var fault := TxReference.shift1(s.prev[0])
				out.what = "t[%d] = %s → kaart %s = %s. M[][%d] = %s & %s = %s. M¹[][%d] = %s | shift(M[][%d]) %s | (%s & %s) %s = %s." % [s.j,
					code(s.t[s.j]), nm, bits(cx), s.j, bits(shifted[0]), bits(cx), bits(after2[0]), s.j, bits(TxReference.unit(s.m)),
					s.j - 1, bits(fault), bits(shifted[1]), bits(cx), bits(own), bits(after2[1])]
			if x2 == "":
				out.why = "%s staat niet in z: blanco kaart, alle lampen van M uit." % code(s.t[s.j])
			else:
				out.why = "AND: lamp i blijft enkel aan als z[i] = t[j] = %s." % code(x2)
			var bells := PackedStringArray()
			for l in s.k + 1:
				if int(after2[l][s.m - 1]) == 1:
					bells.append("%s: z past%s op t[%d..%d]" % [mname(l), "" if l == 0 else " met ≤ %d fout" % l, s.j - s.m + 1, s.j])
			if not bells.is_empty():
				out.after = "[color=%s]Onderste lamp aan → bel![/color] %s." % [C_OK, "; ".join(bells)]


static func _op_txt(eb: TxEditBoard, dir: String, i: int, j: int) -> String:
	var a := eb.a
	var b := eb.b
	match dir:
		"diag":
			if a[i - 1] == b[j - 1]:
				return "%s = %s: gelijk, niets te doen (+0)" % [code(a[i - 1]), code(b[j - 1])]
			return "vervang %s door %s (+1)" % [code(a[i - 1]), code(b[j - 1])]
		"up":
			return "verwijder %s (+1)" % code(a[i - 1])
		"left":
			return "voeg %s toe (+1)" % code(b[j - 1])
	return ""


static func _n_edit(eb: TxEditBoard, e2: TxEditBoard, mv: Dictionary, out: Dictionary) -> void:
	var act := str(mv.act)
	var nm := "D" if eb.approx else "d"
	match act:
		"fill":
			var i := eb.ci
			var j := eb.cj
			var fv := eb._fill_values(i, j)
			var same := eb.a[i - 1] == eb.b[j - 1]
			var dir := str(mv.dir)
			out.what = "%s[%d][%d] = min(↖ %d + %d, ↑ %d + 1, ← %d + 1) = min(%d, %d, %d) = %d (via %s)." % [nm, i, j, int(fv.a), int(fv.c),
				int(fv.b), int(fv.d), int(fv.diag), int(fv.up), int(fv.left), int(fv.v), _arrow(dir)]
			out.why = "%s[%d] = %s en %s[%d] = %s: %s. %s." % ["z" if eb.approx else "t", i - 1, code(eb.a[i - 1]), "t" if eb.approx else "t′", j - 1,
				code(eb.b[j - 1]), "gelijk, dus ↖ kost 0" if same else "verschillend, dus ↖ kost 1 (vervangen)",
				{"diag": "↖ = vervangen/gelijk", "up": "↑ = verwijder %s" % code(eb.a[i - 1]), "left": "← = voeg %s toe" % code(eb.b[j - 1])}[dir]]
			if j == eb.cb and i < eb.ra:
				out.after = "Rij %d is vol; verder met rij %d." % [i, i + 1]
			elif e2.phase != P.FILL:
				out.after = ("Tabel vol: d(t, t′) = d[%d][%d] = %d." % [eb.ra, eb.cb, int(e2.tab[eb.ra][eb.cb])]) if not eb.approx else \
					"Tabel vol. Zoek nu de kleinste waarde in de onderste rij."
		"pick_end":
			var j2 := int(mv.j)
			out.what = "Onderste rij: kleinste waarde = %d in kolom %d (t[%d] = %s)." % [eb.row_min(), j2, j2 - 1, code(eb.b[j2 - 1]) if j2 > 0 else "–"]
			var others := PackedStringArray()
			for c in eb.min_cols():
				if c != j2:
					others.append(str(c))
			if not others.is_empty():
				out.what += " (Ook in kolom %s: ook daar eindigt een beste match.)" % ", ".join(others)
			out.why = "D[m][j] = beste afstand van z tot een deelwoord van t dat op t[j−1] eindigt; het minimum over alle j is het antwoord van Algoritme 8."
		"step":
			var dir2 := str(mv.dir)
			var p := TxReference.pred(dir2, eb.ti, eb.tj)
			out.what = "Van (%d, %d) %s naar (%d, %d): %s." % [eb.ti, eb.tj, _arrow(dir2), p.x, p.y, _op_txt(eb, dir2, eb.ti, eb.tj)]
			out.why = "%s[%d][%d] = %d = %s[%d][%d] + %d: de waarde kwam van die buur." % [nm, eb.ti, eb.tj, int(eb.tab[eb.ti][eb.tj]), nm, p.x, p.y,
				TxReference.step_cost(dir2, eb.a, eb.b, eb.ti, eb.tj)]
			if e2.phase == P.TRACE_DONE or e2.trace_finished():
				out.after = ops_summary(e2)
		"trace_again":
			out.what = "Nog een reeks: er is nog een ander kortste pad."
			out.why = "Waar een cel meer dragende buren heeft, splitst het pad."
		"finish":
			out.what = "Klaar."
			out.why = "Afstand %d: elk pad terug geeft een kortste reeks bewerkingen." % eb.best_true


## Bewerkingen van het laatst gelopen pad, in stijgende volgorde (Lemma 17).
static func ops_summary(eb: TxEditBoard) -> String:
	if eb.sequences.is_empty():
		return ""
	var last = eb.sequences[eb.sequences.size() - 1]
	var ops: Array = last.get("ops", []) if last is Dictionary else last
	var ps := PackedStringArray()
	for o in ops:
		match str(o.op):
			"vervang":
				ps.append("vervang %s op positie %d door %s" % [code(str(o.from)), int(o.pos), code(str(o.to))])
			"verwijder":
				ps.append("verwijder %s op positie %d" % [code(str(o.from)), int(o.pos)])
			"voegtoe":
				ps.append("voeg %s toe op positie %d" % [code(str(o.to)), int(o.pos)])
	if eb.approx and last is Dictionary:
		var mt := eb.b.substr(int(last.start), int(last.end_col) - int(last.start))
		return "Het pad bereikt rij 0 in kolom %d: match t[%d..%d] = %s. Van z = %s naar %s: %s." % [int(last.start), int(last.start), int(last.end_col) - 1,
			code(mt), code(eb.a), code(mt), "; ".join(ps) if not ps.is_empty() else "exact gelijk"]
	return "Reeks (stijgende volgorde): %s." % ("; ".join(ps) if not ps.is_empty() else "niets")


# ======================================================================
#  Samen: tips, aanvaarden, foutuitleg
# ======================================================================

static func tip(mc: TxMachine, mv: Dictionary) -> String:
	var act := str(mv.get("act", ""))
	if mc is TxBrute:
		return "Klik [b]Naald[/b] / [b]Volgende[/b] (Spatie): het sjabloon schuift 1 op."
	if mc is TxRabinKarp:
		var r := mc as TxRabinKarp
		match act:
			"wheel":
				match str(mv.op):
					"double":
						return "Elke stap begint met [b]×2[/b] (D)."
					"minus_w":
						return "Het bit dat links wegvalt (t_%d) is 1: [b]−w[/b] (W)." % r.i
					_:
						return "Het nieuwe bit is 1: [b]+1[/b] (toets 1)."
			"commit":
				return "%d keer verdubbeld: zet w vast (klik het wiel / Enter)." % r.m
			"next_bit":
				return "Klaar met dit bit (een 0 voegt niets toe): [b]Volgend bit[/b] (Enter)."
			"slide":
				return "Het venster is bijgewerkt: [b]schuif[/b] (Enter)."
			"verify":
				return "Gelijke hash: [b]Controleer[/b] (C) de string."
	if mc is TxKmp:
		var k := mc as TxKmp
		if act == "go":
			return "Start de [b]Naald[/b] (Spatie)."
		if not k.strip.is_empty():
			return "Mismatch op z[%d]: lees V[%d] op de strook (klik het vakje of V) en schuif zoveel op." % [k.em, k.em]
		return "Mismatch op z[%d]: welke kleinste verschuiving laat het gelezen stuk %s nog passen? Sleep het sjabloon of typ het getal + Enter." % [k.em, code(k.z.substr(0, k.em))]
	if mc is TxKmpTable:
		var kt := mc as TxKmpTable
		match act:
			"punch":
				return "Vakje j = %d: probeer s = 1, 2, …: past z[0..%d − s] op z[s..%d]? Sleep de kopie tot de tanden haken en klik het vakje." % [int(mv.j), int(mv.j) - 1, int(mv.j) - 1]
			"punch_to":
				if kt.em == 0:
					return "eerste_mismatch = 0: pons enkel vakje %d met waarde start + 1 = %d." % [kt.start + 1, kt.start + 1]
				return "eerste_mismatch = %d: pons de vakjes %d … %d met waarde start = %d (klik het laatste vakje, kies de waarde, Pons)." % [kt.em, kt.punch_from(), kt.start + kt.em, kt.start]
			"shift":
				return "Schuif de kopie V[%d] op (die waarde staat al op de strook)." % kt.em
	if mc is TxBmh:
		var b := mc as TxBmh
		match act:
			"stamp":
				return "Stempel van links naar rechts: z[%d] = %s (klik die letter van het sjabloon)." % [int(mv.i), code(b.z[int(mv.i)])]
			"cards_done":
				return "Alle posities 0 … m − 2 gestempeld: [b]Kaarten klaar[/b] (D)."
			"go":
				return "Start de [b]Naald[/b] (Spatie)."
			_:
				return "Kijk naar het teken van het lint onder de [b]laatste[/b] letter van het sjabloon (t[%d]) en trek die kaart (klik het, of K)." % b.i
	if mc is TxShiftAnd:
		var s := mc as TxShiftAnd
		match act:
			"hole":
				return "z[%d] = %s: kaart %s heeft een gat op rij %d." % [int(mv.i), code(str(mv.x)), code(str(mv.x)), int(mv.i)]
			"cards_done":
				return "Alle gaten staan goed: [b]Kaarten klaar[/b] (D)."
			"plug":
				return "De foutkabel hoort in [b]oud ↓[/b]: de vorige kolom van het bord erboven, één rij omlaag."
			"wire_done":
				return "[b]Bedrading klaar[/b] (D)."
			"lever":
				return "Nieuw teken t[%d] = %s: eerst de [b]hendel[/b] (S): alles één omlaag, rij 0 aan." % [s.j, code(s.t[s.j])]
			"card":
				var x := str(mv.x)
				return ("Steek kaart %s in (AND)." % code(x)) if x != "" else ("%s staat niet in z: de [b]blanco[/b] kaart (Spatie)." % code(s.t[s.j]))
	if mc is TxEditBoard:
		var eb := mc as TxEditBoard
		match act:
			"fill":
				var fv := eb._fill_values(eb.ci, eb.cj)
				return "Reken de drie buren uit: ↖ %d + %d, ↑ %d + 1, ← %d + 1. Kies de kleinste (Q/W/A of klik het driehoekje)." % [int(fv.a), int(fv.c), int(fv.b), int(fv.d)]
			"pick_end":
				return "Zoek de kleinste waarde in de onderste rij en klik die kolom."
			"step":
				return "Stap terug naar een buur waaruit deze waarde kwam (waarde = buur + kost)."
			"trace_again":
				return "Er is nog een andere kortste reeks: [b]Nog een reeks[/b] (R)."
			"finish":
				return "[b]Klaar[/b] (Enter)."
	return "Volg de oplichtende knop."


## Aanvaardt de les deze zet? Samen: zetten die pas later beoordeeld worden (wiel, gaatjes, stempels, stekker) moeten
## overeenkomen met het orakel; de rest via een proefzet (geldig en verdict OK).
static func accepts(mc: TxMachine, mv: Dictionary, right: Dictionary) -> Dictionary:
	var act := str(mv.get("act", ""))
	var ract := str(right.get("act", ""))
	var tr := trial(mc, mv)
	var r: Dictionary = tr.r
	var ok := bool(r.get("ok", false)) and int(r.get("verdict", V.BUMP)) == V.OK
	match act:
		"wheel":
			ok = ok and ract == "wheel" and str(mv.op) == str(right.op)
		"hole":
			var sa := mc as TxShiftAnd
			ok = ok and int(sa.cards[str(mv.x)][int(mv.i)]) != int(sa.c_true[str(mv.x)][int(mv.i)])
		"stamp":
			ok = ok and ract == "stamp" and int(mv.i) == int(right.i)
		"plug":
			ok = ok and str(mv.get("src", "")) == "old_shift"
	return {"ok": ok, "r": r}


static func explain_wrong(mc: TxMachine, mv: Dictionary, right: Dictionary, r: Dictionary) -> String:
	var act := str(mv.get("act", ""))
	var reason := str(r.get("reason", ""))
	if not bool(r.get("ok", true)):
		match reason:
			"no_mesh":
				return "Die verschuiving botst: de tanden haken niet. Wat je al las, moet blijven kloppen."
			"wrong_phase", "already", "not_now":
				return "Dat kan nu niet. %s" % tip(mc, right)
			"last_pos":
				return "De laatste letter z[m−1] stempel je niet: die telt niet mee voor V_H."
			"hole":
				return "Dat vakje van de strook is leeg."
			"zero":
				return "Verschuif minstens 1."
		return "Dat gaat niet. %s" % tip(mc, right)
	if mc is TxRabinKarp:
		var rk := mc as TxRabinKarp
		match act:
			"wheel":
				match str(mv.op):
					"plus1":
						return "+1 enkel als het bit dat erbij komt 1 is; dit bit is 0." if rk.phase != P.W_CALC else "Voor w verdubbel je enkel (×2)."
					"minus_w":
						return "−w enkel als het bit dat links wegvalt 1 is."
					"double":
						return "Je verdubbelde al voor deze stap." if rk.phase != P.W_CALC else "Je verdubbelde al m = %d keer." % rk.m
			"next_bit", "slide":
				return "De stand klopt nog niet: het wiel zou %d moeten tonen. %s" % [rk.step_target(), tip(mc, right)]
			"commit":
				return "Nog niet: verdubbel m = %d keer vanaf 1 (nu %d keer)." % [rk.m, rk.doubles]
			"report":
				return "Niet zomaar melden: gelijke hash kan een valse treffer zijn. Controleer eerst (strings_gelijk)."
			"ignore":
				return "Negeren mag niet: de hash is gelijk, dus het kán een treffer zijn. Controleer."
	if mc is TxKmp:
		var k := mc as TxKmp
		var s := int(mv.get("s", k.strip_cell(k.em)))
		return "%d past wel, maar is niet de kleinste: met %d sla je mogelijk een voorkomen over. %s" % [s, s, why_v(k.z, k.em)]
	if mc is TxKmpTable:
		var kt := mc as TxKmpTable
		match act:
			"punch":
				return "%d past, maar er is een kleinere: %s" % [int(mv.v), why_v(kt.z, int(mv.j))]
			"done":
				return "Er zijn nog lege vakjes."
			"punch_to":
				var cp := kt.correct_punch()
				if int(mv.to) < cp.x:
					return "Te weinig: Algoritme 5 vult alle vakjes %d … %d in." % [kt.punch_from(), cp.x]
				return "Verkeerde waarde of te ver: vakjes %d … %d krijgen %d." % [kt.punch_from(), cp.x, cp.y]
			"shift", "strip":
				return "Schuif V[eerste_mismatch] = V[%d] = %d (niet meer)." % [kt.em, int(kt.vv[kt.em])]
	if mc is TxBmh:
		var b := mc as TxBmh
		match act:
			"stamp":
				return "Stempel in volgorde van links naar rechts (nu z[%d]): zo overschrijft de meest rechtse positie." % int(right.get("i", 0))
			"cards_done":
				return "Nog niet alle posities 0 … m − 2 gestempeld."
			"key":
				return "Dat is niet het sleutelteken. Horspool kijkt altijd naar t[i] onder de [b]laatste[/b] letter (t[%d] = %s), niet naar het teken waar het misging." % [b.i, code(b.t[b.i])]
			"jump":
				return "Spring V_H(t[%d]) = V_H(%s) = %d." % [b.i, code(b.t[b.i]), TxReference.vh_of(b.vh, b.t[b.i], b.m)]
	if mc is TxShiftAnd:
		var sa := mc as TxShiftAnd
		match act:
			"hole":
				return "Niet daar: kaart %s krijgt gaten precies waar z[i] = %s." % [code(str(mv.x)), code(str(mv.x))]
			"cards_done":
				return "Nog niet alle gaten juist. %s" % tip(mc, right)
			"plug":
				return "Niet die aansluiting: M¹[i][j] gebruikt M[i−1][j−1] (de [b]oude[/b] kolom, [b]één rij omlaag[/b])."
			"card":
				if not sa.lever_pulled:
					return "Eerst de hendel (shift¹), anders schuift de kolom niet op."
				return "Kaart van t[%d] = %s: %s." % [sa.j, code(sa.t[sa.j]), ("kaart " + code(sa.t[sa.j])) if sa.c_true.has(sa.t[sa.j]) else "blanco (letter niet in z)"]
	if mc is TxEditBoard:
		var eb := mc as TxEditBoard
		match act:
			"fill":
				var fv := eb._fill_values(eb.ci, eb.cj)
				return "Via %s krijg je %d, maar het minimum is %d (↖ %d, ↑ %d, ← %d)." % [_arrow(str(mv.dir)), int(fv[str(mv.dir)]), int(fv.v),
					int(fv.diag), int(fv.up), int(fv.left)]
			"pick_end":
				return "Daar staat %d; het minimum van de onderste rij is %d." % [int(eb.tab[eb.ra][int(mv.j)]), eb.row_min()]
	return "Niet juist. %s" % tip(mc, right)


# ======================================================================
#  voorspelvragen (Kijk/Samen) — {q, options, correct: [i], right, wrong}
# ======================================================================

static func _num_q(q: String, right: int, cands: Array, why: String, lo := 0) -> Dictionary:
	var opts: Array = [right]
	for c in cands:
		if int(c) >= lo and not opts.has(int(c)) and opts.size() < 4:
			opts.append(int(c))
	var d := 1
	while opts.size() < 4 and d < 40:
		for c in [right + d, right - d]:
			if c >= lo and not opts.has(c) and opts.size() < 4:
				opts.append(c)
		d += 1
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


static func predict(mc: TxMachine, kind: String, mv: Dictionary) -> Dictionary:
	var tr := trial(mc, mv)
	var m2: TxMachine = tr.mc
	match kind:
		"ticks":
			var b := mc as TxBrute
			var i := b.start + 1 if str(mv.act) == "next" else 0
			var tk := _brute_ticks(b.z, b.t, i)
			return _num_q("Start %d: hoeveel tikken kost deze uitlijning?" % i, tk, [b.m, 1, tk + 1],
				"Start %d: %s." % [i, _brute_res(b.z, b.t, i)], 1)
		"wheel":
			var r2 := m2 as TxRabinKarp
			var r := mc as TxRabinKarp
			var right := r2.wheel if str(mv.act) != "slide" else r.wheel
			if str(mv.act) == "next_bit":
				var pre := r.bits.substr(0, r.bit_k + 1)
				return _num_q("Welke stand toont het wiel na bit %d (h(%s))?" % [r.bit_k, pre], r.wheel, [pre.bin_to_int(), r.wheel + 1],
					"g(%s) = %d en %d mod %d = %d." % [pre, pre.bin_to_int(), pre.bin_to_int(), r.q, r.wheel])
			var wb := r.window_bits(r.i + 1)
			return _num_q("Welke hashwaarde heeft venster %d (%s)?" % [r.i + 1, wb], right, [wb.bin_to_int(), right + r.w],
				"%s = %d en %d mod %d = %d (gerold: 2·h − t_p·w + t_{p+m})." % [wb, wb.bin_to_int(), wb.bin_to_int(), r.q, right])
		"minus":
			var r3 := mc as TxRabinKarp
			return {"q": "Venster %d → %d: het bit t_%d = %s valt links weg. Moet je −w doen?" % [r3.i, r3.i + 1, r3.i, r3.t[r3.i]],
				"options": ["ja, want t_p = 1", "nee, want t_p = 0", "altijd", "nooit"], "correct": [0 if r3.t[r3.i] == "1" else 1],
				"right": "−t_p·2^m: enkel als dat bit 1 is, en 2^m mod q = w.", "wrong": "−w hoort enkel bij t_p = 1 (−t_p·2^m)."}
		"real":
			var r4 := mc as TxRabinKarp
			var win := r4.window_bits(r4.si if r4.signal_mode() else r4.i)
			var real := win == r4.z
			return {"q": "Alarm: venster %s heeft h = %d = h(z). Echte treffer?" % [win, r4.hz], "options": ["ja, echte treffer", "nee, valse treffer"],
				"correct": [0 if real else 1], "right": "Vergelijk %s met z = %s teken per teken." % [win, r4.z],
				"wrong": "Vergelijk %s met z = %s: %s." % [win, r4.z, "gelijk" if real else "ze verschillen (zelfde rest mod %d)" % r4.q]}
		"shift":
			var k := mc as TxKmp
			var j := k.em
			var v := int(k.vv[j])
			var qs := ("Treffer! Je zoekt alle voorkomens. Hoeveel schuift het sjabloon op (V[m])?") if j == k.m else ("Mismatch op z[%d]. Hoeveel schuift het sjabloon op?" % j)
			return _num_q(qs, v, [j, v + 1, 1, maxi(1, j - 1)], why_v(k.z, j), 1)
		"gel":
			var k2 := mc as TxKmp
			var j2 := k2.em
			var v2 := int(k2.vv[j2])
			var g := j2 - v2 if v2 < j2 else 0
			return _num_q("Na de sprong van %d: vanaf welke positie van z vergelijkt de naald verder?" % v2, g, [0, j2, 1],
				"gelijke_tekens = %d − V[%d] = %d − %d = %d: z[0..%d] ligt al juist." % [j2, j2, j2, v2, g, g - 1] if g > 0 else "gelijke_tekens = 0.")
		"v":
			var kt := mc as TxKmpTable
			var jj := int(mv.j)
			return _num_q("V[%d] = ?" % jj, int(kt.vv[jj]), [jj, int(kt.vv[jj]) + 1, 1], why_v(kt.z, jj), 1)
		"fill":
			var kt2 := mc as TxKmpTable
			var cp := kt2.correct_punch()
			var a := kt2.punch_from()
			var rs := "V[%s] = %d" % [("%d" % a) if a == cp.x else "%d..%d" % [a, cp.x], cp.y]
			var c1 := "V[%d] = %d" % [cp.x, cp.x]
			var c2 := "V[%d..%d] = %d" % [a, cp.x + 1, cp.y]
			var c3 := "V[%d] = %d" % [a, cp.y + 1]
			return _str_q("start = %d, gelijke_tekens = %d, eerste_mismatch = %d. Welke vakjes vul je in?" % [kt2.start, kt2.gel, kt2.em], rs, [c1, c2, c3],
				"em = 0 → V[start+1] = start+1; anders V[start+gel+1 .. start+em] = start.")
		"start":
			var kt3 := mc as TxKmpTable
			var sh := int(kt3.vv[kt3.em])
			return _num_q("Nieuwe start na het schuiven?", kt3.start + sh, [kt3.start + 1, kt3.start + kt3.em, kt3.start + sh + 1],
				"start += V[eerste_mismatch] = V[%d] = %d." % [kt3.em, sh], 1)
		"vh":
			var bm := mc as TxBmh
			var p := int(mv.i)
			return _num_q("Welke waarde stempel je voor z[%d] = %s?" % [p, bm.z[p]], bm.m - 1 - p, [p, bm.m, bm.m - p],
				"V_H(%s) = m − 1 − %d = %d − 1 − %d." % [bm.z[p], p, bm.m, p])
		"jump":
			var bm2 := mc as TxBmh
			var key := bm2.t[bm2.i]
			var s := TxReference.vh_of(bm2.vh, key, bm2.m)
			var cands: Array = [bm2.m, 1]
			if bm2.mis_z >= 0:
				cands.push_front(TxReference.vh_of(bm2.vh, bm2.t[bm2.i - (bm2.m - 1 - bm2.mis_z)], bm2.m))
			return _num_q("Hoe ver springt de Springer nu?", s, cands, "Sleutelteken t[%d] = %s: V_H(%s) = %d." % [bm2.i, key, key, s], 1)
		"col":
			var sa := mc as TxShiftAnd
			var s2 := m2 as TxShiftAnd
			var l := sa.k
			var rc := bits(s2.prev[l])
			var cands2: Array = [bits(sa.shown_cols()[l]), bits(sa.c_true[str(mv.x)]) if str(mv.x) != "" else bits(TxReference.zeros(sa.m)),
				bits(TxReference.zeros(sa.m)), bits(TxReference.unit(sa.m))]
			var nm := "M¹" if l == 1 else "M"
			var ex := "shift¹(%s[][%d]) = %s, & %s = %s." % [nm, sa.j - 1, bits(sa.shown_cols()[l]), "C_" + str(mv.x) if str(mv.x) != "" else "blanco",
				bits(sa.c_true[str(mv.x)]) if str(mv.x) != "" else bits(TxReference.zeros(sa.m))]
			if l == 1:
				ex = "M¹[][%d] = 100… | shift(M[][%d]) | (shift(M¹[][%d]) & C) = %s." % [sa.j, sa.j - 1, sa.j - 1, rc]
			return _str_q("Welke kolom %s[][%d] krijg je (rij 0 → %d)?" % [nm, sa.j, sa.m - 1], rc, cands2, ex)
		"lever":
			var sa2 := mc as TxShiftAnd
			var s3 := m2 as TxShiftAnd
			var rc2 := bits(s3.shown_cols()[0])
			return _str_q("j = %d: wat geeft shift¹(M[][%d]) = shift¹(%s)?" % [sa2.j, sa2.j - 1, bits(sa2.shown_cols()[0])], rc2,
				[bits(sa2.shown_cols()[0]), bits(TxReference.unit(sa2.m)), bits(TxReference.zeros(sa2.m))], "Elke 1 één rij omlaag, rij 0 wordt 1.")
		"cell":
			var eb := mc as TxEditBoard
			var fv := eb._fill_values(eb.ci, eb.cj)
			return _num_q("%s[%d][%d] = ?" % ["D" if eb.approx else "d", eb.ci, eb.cj], int(fv.v), [int(fv.diag), int(fv.up), int(fv.left)],
				"min(↖ %d, ↑ %d, ← %d) = %d." % [int(fv.diag), int(fv.up), int(fv.left), int(fv.v)])
		"op":
			var eb2 := mc as TxEditBoard
			var dir := str(mv.dir)
			var ops := ["niets (gelijke letters)", "vervangen", "verwijderen", "toevoegen"]
			var ri := 2 if dir == "up" else (3 if dir == "left" else (0 if eb2.a[eb2.ti - 1] == eb2.b[eb2.tj - 1] else 1))
			return {"q": "Deze stap gaat %s. Welke bewerking is dat?" % _arrow(dir), "options": ops, "correct": [ri],
				"right": _op_txt(eb2, dir, eb2.ti, eb2.tj) + ".", "wrong": "%s: %s." % [_arrow(dir), _op_txt(eb2, dir, eb2.ti, eb2.tj)]}
		"end":
			var eb3 := mc as TxEditBoard
			return _num_q("In welke kolom j staat het minimum van de onderste rij?", int(mv.j), [eb3.cb, 0, maxi(1, int(mv.j) - 1)],
				"D[%d][%d] = %d is de kleinste waarde in de onderste rij." % [eb3.ra, int(mv.j), eb3.row_min()])
	return {}


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
#  Check-vragen in de terugblik: nieuw willekeurig voorbeeld (antwoord uit TxReference)
#  {q, options, correct, explain, fig (mono-tekst zoals op het examen)}
# ======================================================================

static func _rs(rng: RandomNumberGenerator, alpha: String, n: int) -> String:
	var s := ""
	for i in n:
		s += alpha[rng.randi_range(0, alpha.length() - 1)]
	return s


static func check_question(id: String, rng: RandomNumberGenerator) -> Dictionary:
	for _try in 40:
		var q := _check(id, rng)
		if not q.is_empty() and (q.options as Array).size() >= 2:
			return q
	return {}


static func _check(id: String, rng: RandomNumberGenerator) -> Dictionary:
	match id:
		"brute":
			var m := rng.randi_range(2, 3)
			var z := _rs(rng, "ab", m)
			var t := _rs(rng, "ab", rng.randi_range(6, 8))
			var r := TxReference.brute(z, t, true)
			var per := PackedStringArray()
			for x in r.trace:
				per.append(str(int(x.cmp)))
			var q := _num_q("Brute kracht, alle voorkomens: hoeveel tekenvergelijkingen (tikken) in totaal?", int(r.cmp),
				[(t.length() - m + 1) * m, t.length() - m + 1, int(r.cmp) + 1], "")
			q["explain"] = "Per start i = 0 … %d: %s tikken = %d (stop bij het eerste verschil; een treffer kost m)." % [t.length() - m, " + ".join(per), int(r.cmp)]
			q["fig"] = "z = %s   (m = %d)\nt = %s   (n = %d)\n    %s" % [z, m, t, t.length(), _idx(t.length())]
			q["data"] = {"z": z, "t": t}
			return q
		"rk_hash":
			var qq: int = [5, 7, 11, 13][rng.randi_range(0, 3)]
			var z2 := _rs(rng, "01", rng.randi_range(4, 6))
			var hv := TxReference.h(z2, qq)
			var steps := PackedStringArray()
			for v in TxReference.horner_prefixes(z2, qq):
				steps.append(str(v))
			var q2 := _num_q("h(z) = ?", hv, [z2.bin_to_int(), (hv + 1) % qq, posmod(hv - 1, qq)], "")
			q2["explain"] = "g(%s) = %d en %d mod %d = %d. Met Horner (×2, +bit, mod q) per bit: %s." % [z2, z2.bin_to_int(), z2.bin_to_int(), qq, hv, " → ".join(steps)]
			q2["fig"] = "z = %s\nq = %d" % [z2, qq]
			q2["data"] = {"z": z2, "q": qq}
			return q2
		"rk_rollen":
			var q3: int = [5, 7, 11, 13][rng.randi_range(0, 3)]
			var m3 := rng.randi_range(3, 5)
			var t3 := _rs(rng, "01", m3 + 1)
			var h0 := TxReference.h(t3.substr(0, m3), q3)
			var h1 := TxReference.h(t3.substr(1, m3), q3)
			var w := TxReference.weight(m3, q3)
			var wrong_nw := posmod(2 * h0 + int(t3[m3]), q3)
			var q4 := _num_q("w = 2^%d mod %d = %d. Venster 0 = %s heeft h = %d. Wat is h van venster 1 = %s?" % [m3, q3, w, t3.substr(0, m3), h0, t3.substr(1, m3)],
				h1, [wrong_nw, posmod(2 * h0 - w, q3), t3.substr(1, m3).bin_to_int()], "")
			q4["explain"] = "(2·%d − %s·%d + %s) mod %d = %d. Controle: %s = %d ≡ %d." % [h0, t3[0], w, t3[m3], q3, h1, t3.substr(1, m3), t3.substr(1, m3).bin_to_int(), h1]
			q4["fig"] = "t = %s   (m = %d, q = %d)\n    %s" % [t3, m3, q3, _idx(t3.length())]
			q4["data"] = {"t": t3, "m": m3, "q": q3}
			return q4
		"rk_vals":
			var q5 := 5
			var z5 := _rs(rng, "01", 3)
			var t5 := _rs(rng, "01", 8)
			var r5 := TxReference.rk(z5, t5, q5, true)
			var fh: Array = r5.get("false_hits", [])
			if (r5.get("calls", []) as Array).is_empty():
				return {}
			var q6 := _num_q("z = %s, q = %d. Hoeveel valse treffers (gelijke hash, andere string) geeft Rabin-Karp op t?" % [z5, q5], fh.size(), [0, 1, 2, 3], "")
			var hs := PackedStringArray()
			for i in t5.length() - 2:
				hs.append("%s→%d" % [t5.substr(i, 3), TxReference.h(t5.substr(i, 3), q5)])
			q6["explain"] = "h(z) = %d. Vensters: %s. Valse treffers op %s." % [TxReference.h(z5, q5), ", ".join(hs), str(fh) if not fh.is_empty() else "geen enkele positie"]
			q6["fig"] = "z = %s   q = %d\nt = %s\n    %s" % [z5, q5, t5, _idx(t5.length())]
			q6["data"] = {"z": z5, "t": t5, "q": q5}
			return q6
		"kmp_idee", "kmp_def11":
			var z7 := _rs(rng, "ab", rng.randi_range(5, 7))
			var vv := TxReference.v_def(z7, false)
			var j7 := rng.randi_range(2, z7.length() - 1)
			if vv[j7] == j7 and rng.randf() < 0.6:
				return {}
			var qt := ("Mismatch op z[%d]. Hoeveel schuif je op (de kleinste verschuiving die past)?" % j7) if id == "kmp_idee" else ("V[%d] = ?" % j7)
			var q7 := _num_q(qt, vv[j7], [j7, vv[j7] + 1, 1], "", 1)
			q7["explain"] = why_v(z7, j7) + " (hele tabel: V = %s)" % _join(vv)
			q7["fig"] = "z = %s\n    %s" % [z7, _idx(z7.length())]
			q7["data"] = {"z": z7, "j": j7}
			return q7
		"kmp_alg5":
			var z8 := _rs(rng, "ab", rng.randi_range(5, 7))
			var bv := TxReference.bereken_v(z8)
			var steps8: Array = bv.steps
			if steps8.size() < 2:
				return {}
			var st: Dictionary = steps8[rng.randi_range(0, steps8.size() - 1)]
			var fl: Array = st.filled
			if fl.is_empty():
				return {}
			var a := int(fl[0][0])
			var b := int(fl[fl.size() - 1][0])
			var vv8 := int(fl[0][1])
			var rs := "V[%s] = %d" % [("%d" % a) if a == b else "%d..%d" % [a, b], vv8]
			var q8 := _str_q("Algoritme 5 op z: start = %d, gelijke_tekens = %d, eerste_mismatch = %d. Welke vakjes worden ingevuld?" % [int(st.start), int(st.gel), int(st.em)],
				rs, ["V[%d] = %d" % [b + 1, vv8], "V[%d] = %d" % [a, int(st.start) + 1], "V[%d..%d] = %d" % [a, b + 1, vv8], "V[%d] = %d" % [b, b]], "")
			q8["explain"] = ("em = 0: V[start + 1] = start + 1." if int(st.em) == 0 else "V[start + i] = start voor i = gelijke_tekens + 1 … em.") + " Hele tabel: V = %s." % _join(TxReference.v_def(z8, false))
			q8["fig"] = "z = %s\n    %s" % [z8, _idx(z8.length())]
			q8["data"] = {"z": z8, "start": int(st.start), "gel": int(st.gel), "em": int(st.em), "a": a, "b": b, "v": vv8}
			return q8
		"kmp_loop":
			var z9 := _rs(rng, "ab", rng.randi_range(3, 4))
			var t9 := _rs(rng, "ab", rng.randi_range(7, 9))
			var v9 := TxReference.v_def(z9, true)
			var r9 := TxReference.kmp(z9, t9, v9, true)
			var br := TxReference.brute(z9, t9, true)
			var q9 := _num_q("KMP (alle voorkomens, met V[m]): hoeveel tekenvergelijkingen?", int(r9.cmp), [int(br.cmp), int(r9.cmp) + 1, t9.length()], "", 1)
			var tr9 := PackedStringArray()
			for x in r9.trace:
				tr9.append("start %d: %d" % [int(x.start), int(x.cmp)])
			q9["explain"] = "V = %s. %s → %d (brute kracht: %d)." % [_join(v9), ", ".join(tr9), int(r9.cmp), int(br.cmp)]
			q9["fig"] = "z = %s\nt = %s\n    %s" % [z9, t9, _idx(t9.length())]
			q9["data"] = {"z": z9, "t": t9}
			return q9
		"bmh_tabel":
			var z10 := _rs(rng, "abcd", rng.randi_range(4, 6))
			var vh := TxReference.vul_vh(z10)
			var xs := "abcd"
			var x := xs[rng.randi_range(0, 3)]
			var rv := TxReference.vh_of(vh, x, z10.length())
			var first := z10.find(x)
			var q10 := _num_q("V_H(%s) = ?" % x, rv, [z10.length(), (z10.length() - 1 - first) if first >= 0 else 1, maxi(1, rv - 1)], "", 1)
			q10["explain"] = "V_H: %s, anders m = %d (laatste positie vóór z[m−1] telt)." % [_vh_txt(vh), z10.length()]
			q10["fig"] = "z = %s\n    %s" % [z10, _idx(z10.length())]
			q10["data"] = {"z": z10, "x": x}
			return q10
		"bmh_loop":
			var z11 := _rs(rng, "abc", 3)
			var t11 := _rs(rng, "abcd", 9)
			var r11 := TxReference.bmh(z11, t11, true)
			var q11 := _num_q("Boyer-Moore-Horspool, alle voorkomens: hoeveel uitlijningen (sleutels) bekijkt het?", int(r11.alignments),
				[t11.length() - 2, int(r11.alignments) + 1, maxi(1, int(r11.alignments) - 1)], "", 1)
			var ii := PackedStringArray()
			for x2 in r11.trace:
				ii.append("i=%d(%s→%d)" % [int(x2.i), str(x2.key), int(x2.shift)])
			q11["explain"] = "V_H: %s, anders 3. %s." % [_vh_txt(r11.vh), " ".join(ii)]
			q11["fig"] = "z = %s\nt = %s\n    %s" % [z11, t11, _idx(t11.length())]
			q11["data"] = {"z": z11, "t": t11}
			return q11
		"sa_cx":
			var z12 := _rs(rng, "abc", rng.randi_range(4, 5))
			var cv := TxReference.c_vectors(z12)
			var keys: Array = cv.keys()
			var x3: String = keys[rng.randi_range(0, keys.size() - 1)]
			var rc := bits(cv[x3])
			var cands: Array = []
			for y in keys:
				if y != x3:
					cands.append(bits(cv[y]))
			cands.append(rc.reverse())
			cands.append(bits(TxReference.zeros(z12.length())))
			var q12 := _str_q("C_%s = ? (rij 0 → %d)" % [x3, z12.length() - 1], rc, cands, "")
			q12["explain"] = "Een 1 waar z[i] = %s: posities %s." % [x3, str(_positions(z12, x3))]
			q12["fig"] = "z = %s\n    %s" % [z12, _idx(z12.length())]
			q12["data"] = {"z": z12, "x": x3}
			return q12
		"sa_col":
			var z13 := _rs(rng, "ab", 3)
			var t13 := _rs(rng, "ab", 6)
			var r13 := TxReference.shift_and(z13, t13)
			var j13 := rng.randi_range(2, 5)
			var prev: Array = r13.cols[j13 - 1]
			var cur: Array = r13.cols[j13]
			var cx: Array = r13.c.get(t13[j13], TxReference.zeros(3))
			var q13 := _str_q("M[][%d] = %s en t[%d] = %s. M[][%d] = ? (rij 0 → 2)" % [j13 - 1, bits(prev), j13, t13[j13], j13], bits(cur),
				[bits(TxReference.shift1(prev)), bits(TxReference.and_cols(prev, cx)), bits(cx), "000"], "")
			q13["explain"] = "shift¹(%s) = %s; & C_%s = %s → %s." % [bits(prev), bits(TxReference.shift1(prev)), t13[j13], bits(cx), bits(cur)]
			q13["fig"] = "z = %s\nt = %s\n    %s" % [z13, t13, _idx(t13.length())]
			q13["data"] = {"z": z13, "t": t13, "j": j13}
			return q13
		"sa_k":
			var z14 := _rs(rng, "ab", 3)
			var t14 := _rs(rng, "ab", 6)
			var r14 := TxReference.shift_and_k(z14, t14, 1)
			var j14 := rng.randi_range(2, 5)
			var p0: Array = r14.cols[j14 - 1][0]
			var p1: Array = r14.cols[j14 - 1][1]
			var c1: Array = r14.cols[j14][1]
			var cx2: Array = r14.c.get(t14[j14], TxReference.zeros(3))
			var own := TxReference.and_cols(TxReference.shift1(p1), cx2)
			var q14 := _str_q("M[][%d] = %s, M¹[][%d] = %s, t[%d] = %s. M¹[][%d] = ? (rij 0 → 2)" % [j14 - 1, bits(p0), j14 - 1, bits(p1), j14, t14[j14], j14],
				bits(c1), [bits(own), bits(TxReference.shift1(p0)), bits(r14.cols[j14][0]), "111"], "")
			q14["explain"] = "100 | shift(M[][%d]) %s | (shift(M¹[][%d]) & C) %s = %s." % [j14 - 1, bits(TxReference.shift1(p0)), j14 - 1, bits(own), bits(c1)]
			q14["fig"] = "z = %s   k = 1\nt = %s\n    %s" % [z14, t14, _idx(t14.length())]
			q14["data"] = {"z": z14, "t": t14, "j": j14}
			return q14
		"ed_fill":
			var a15 := _rs(rng, "abc", 3)
			var b15 := _rs(rng, "abc", 3)
			var tb := TxReference.edit_table(a15, b15)
			var i15 := rng.randi_range(1, 3)
			var j15 := rng.randi_range(1, 3)
			var c15 := 0 if a15[i15 - 1] == b15[j15 - 1] else 1
			var dv := int(tb[i15 - 1][j15 - 1]) + c15
			var uv := int(tb[i15 - 1][j15]) + 1
			var lv := int(tb[i15][j15 - 1]) + 1
			var q15 := _num_q("d[%d][%d] = ?  (↖ = %d, ↑ = %d, ← = %d)" % [i15, j15, int(tb[i15 - 1][j15 - 1]), int(tb[i15 - 1][j15]), int(tb[i15][j15 - 1])],
				int(tb[i15][j15]), [dv, uv, lv, int(tb[i15 - 1][j15 - 1])], "")
			q15["explain"] = "t[%d] = %s, t′[%d] = %s → ↖ kost %d. min(%d, %d, %d) = %d." % [i15 - 1, a15[i15 - 1], j15 - 1, b15[j15 - 1], c15, dv, uv, lv, int(tb[i15][j15])]
			q15["fig"] = "t  = %s\nt′ = %s\n\n%s" % [a15, b15, _edit_fig(tb, a15, b15, i15, j15)]
			q15["data"] = {"a": a15, "b": b15, "i": i15, "j": j15}
			return q15
		"ed_trace":
			var a16 := _rs(rng, "abc", rng.randi_range(3, 4))
			var b16 := _rs(rng, "abc", rng.randi_range(3, 4))
			var d16 := TxReference.edit_distance(a16, b16)
			var q16 := _num_q("d(t, t′) = ? (het kleinste aantal bewerkingen)", d16, [absi(a16.length() - b16.length()), maxi(a16.length(), b16.length()), d16 + 1], "")
			var seqs := TxReference.distinct_sequences(a16, b16)
			var ex := ""
			if not seqs.is_empty():
				var ps := PackedStringArray()
				for o in seqs[0]:
					ps.append("%s %s" % [str(o.op), str(o.to) if str(o.op) != "verwijder" else str(o.from)])
				ex = " Bv.: %s." % (", ".join(ps) if not ps.is_empty() else "niets")
			q16["explain"] = "d[%d][%d] = %d.%s" % [a16.length(), b16.length(), d16, ex]
			q16["fig"] = "t  = %s\nt′ = %s\n\n(vul zelf de tabel d[i][j] in)" % [a16, b16]
			q16["data"] = {"a": a16, "b": b16}
			return q16
		"alg8":
			var z17 := _rs(rng, "ab", 3)
			var t17 := _rs(rng, "ab", 6)
			var ab := TxReference.approx_best(z17, t17)
			var q17 := _num_q("Algoritme 8: kleinste editeerafstand van z tot een deelwoord van t?", int(ab.best), [TxReference.edit_distance(z17, t17), int(ab.best) + 1, 3], "")
			var row: Array = TxReference.approx_table(z17, t17)[3]
			q17["explain"] = "Onderste rij D[3][] = %s: minimum %d (kolom %s)." % [_join(row), int(ab.best), str(ab.end_cols)]
			q17["fig"] = "z = %s\nt = %s\n    %s" % [z17, t17, _idx(t17.length())]
			q17["data"] = {"z": z17, "t": t17}
			return q17
	return {}


static func _idx(n: int) -> String:
	var s := ""
	for i in n:
		s += str(i % 10)
	return s + "   (posities mod 10)"


static func _positions(z: String, x: String) -> Array:
	var out := []
	for i in z.length():
		if z[i] == x:
			out.append(i)
	return out


static func _vh_txt(vh: Dictionary) -> String:
	var ps := PackedStringArray()
	for x in vh:
		ps.append("%s = %d" % [x, int(vh[x])])
	return ", ".join(ps)


## Tabel d[][] als monotekst; (hi, hj) = de gevraagde cel (?).
static func _edit_fig(tb: Array, a: String, b: String, hi: int, hj: int) -> String:
	var lines := PackedStringArray()
	var head := "     "
	for j in b.length():
		head += " " + b[j]
	lines.append(head)
	for i in a.length() + 1:
		var l := ("  " if i == 0 else " " + a[i - 1]) + " "
		for j in b.length() + 1:
			if i == hi and j == hj:
				l += " ?"
			elif hi >= 0 and (i > hi or (i == hi and j > hj)):
				l += " ."
			else:
				l += " " + str(int(tb[i][j]))
		lines.append(l)
	return "\n".join(lines)
