class_name TxLevels
## Leveldata (GDD §5) en de machinefabriek (GDD §8.8). Alle teksten, zoekwoorden en verwachte uitkomsten letterlijk
## uit de GDD; TxLevels.optimum(spec) speelt elke stage met het orakel en rekent de tellers na.

const IDS := ["1-1", "1-2", "1-3", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4", "3-5", "4-1", "4-2",
	"4-3", "4-4", "5-1", "5-2", "5-3", "6-1", "6-2", "7-1", "7-2", "8-1", "8-2", "8-3", "F"]

const DOSSIERS := ["", "Het lint", "Vingerafdrukken", "De Doorloper", "De Springer", "Het lampenbord",
	"Ruis op de lijn", "Het schakelbord", "Het zoeklicht", "Operatie Ekster"]

const MACHINE_LABELS := {"brute": "Sjabloon", "rk": "Vingerafdruk", "kmp_table": "Ponsbank", "kmp": "Doorloper",
	"bmh": "Springer", "shift_and": "Lampenbord", "shift_and_k": "Ruisbord", "edit": "Zoeklicht",
	"sabotage": "Tegenzet"}

const CODEWORDS := ["ekster", "kever", "radar", "morse", "baken", "kompas", "zender", "telex", "sleutel", "kluis",
	"schaduw", "nevel", "haven", "koerier", "sein", "duin", "golf", "lantaarn", "vuurtoren", "ponskaart", "signaal",
	"antenne", "kristal", "relais", "spoel", "wiel", "naald", "lint", "stempel", "dossier"]

const S_DONE := {"kind": "done"}
const S_NOMIS := {"kind": "no_mistakes"}
const S_HELP := {"kind": "no_help"}
const S_BUMPS := {"kind": "no_bumps"}


## Campagnevolgorde "1-1" … "8-3", "F".
static func ids() -> PackedStringArray:
	return PackedStringArray(IDS)


static func has_level(id: String) -> bool:
	return IDS.has(id)


static func dossier_of(id: String) -> int:
	if id == "F":
		return 9
	if id == "N":
		return 0
	return int(id.split("-")[0])


static func priority_of(id: String) -> String:
	return str(_data(id).get("priority", "P0"))


static func ids_in_dossier(d: int) -> PackedStringArray:
	var out := PackedStringArray()
	for id in IDS:
		if dossier_of(id) == d:
			out.append(id)
	return out


## Ontgrendeling (GDD §4.2): het volgende level opent met ≥ 1 ★ op het vorige P0-level van het dossier; een dossier
## opent als alle P0-levels van het vorige dossier ≥ 1 ★ hebben; de finale als alle P0-levels ≥ 1 ★ hebben;
## de Nachtdienst ("N") met 4-1 ≥ 1 ★. P1/P2-levels sluiten nooit iets af.
static func is_unlocked(id: String, stars: Dictionary) -> bool:
	if id == "N":
		return int(stars.get("4-1", 0)) >= 1
	if id == "F":
		for x in IDS:
			if x != "F" and priority_of(x) == "P0" and int(stars.get(x, 0)) < 1:
				return false
		return true
	if not IDS.has(id):
		return false
	var d := dossier_of(id)
	if d > 1:
		for x in ids_in_dossier(d - 1):
			if priority_of(x) == "P0" and int(stars.get(x, 0)) < 1:
				return false
	var inside := ids_in_dossier(d)
	var idx := inside.find(id)
	for k in range(idx - 1, -1, -1):
		if priority_of(inside[k]) == "P0":
			return int(stars.get(inside[k], 0)) >= 1
	return true


static func get_spec(id: String) -> TxLevelSpec:
	var d := _data(id)
	if d.is_empty():
		push_error("TxLevels.get_spec: onbekend level %s" % id)
		return null
	var s := TxLevelSpec.new()
	s.id = id
	s.dossier = dossier_of(id)
	s.title = str(d.get("title", ""))
	s.intro = str(d.get("intro", ""))
	s.notes_ref = str(d.get("notes_ref", ""))
	s.priority = str(d.get("priority", "P0"))
	s.mode = TxCodes.Mode.LIVE if str(d.get("mode", "calm")) == "live" else TxCodes.Mode.CALM
	for st in d.get("stages", []):
		s.stages.append((st as Dictionary).duplicate(true))
	s.live = (d.get("live", {}) as Dictionary).duplicate(true)
	for st in d.get("stars", []):
		s.stars.append((st as Dictionary).duplicate(true))
	s.optimum = (d.get("optimum", {}) as Dictionary).duplicate(true)
	s.ghost = _ghost(s)
	for tu in d.get("tutorial", []):
		s.tutorial.append((tu as Dictionary).duplicate(true))
	s.story = (d.get("story", {}) as Dictionary).duplicate(true)
	s.expect = (d.get("expect", {}) as Dictionary).duplicate(true)
	return s


## Geest "brute kracht": tikken van Algoritme 2 op hetzelfde lint in dezelfde modus (som over de stages met een lint).
static func _ghost(s: TxLevelSpec) -> Dictionary:
	var total := 0
	var any := false
	for st in s.stages:
		var mach := str(st.get("machine", ""))
		if mach in ["edit", "sabotage", "kmp_table"]:
			continue
		if mach == "rk" and st.has("signals"):
			for sig in st.signals:
				total += int(TxReference.brute(str(st.z), str(sig), true).cmp)
				any = true
			continue
		var z := str(st.get("z", ""))
		var t := str(st.get("t", ""))
		if z == "" or t == "":
			continue
		total += int(TxReference.brute(z, t, str(st.get("find", "first")) == "all", str(st.get("joker", ""))).cmp)
		any = true
	return {"brute_ticks": total} if any else {}


## Nachtdienst (GDD §5.11): lint k met de Springer zonder kaartenbak, LIVE. variant "kmp" (P1): de Doorloper met
## een strook waarin 2 vakjes (≥ 2) verbrand zijn; daar verschuif je met de hand.
static func endless_spec(tape_index: int, seed_: int, variant := "bmh") -> TxLevelSpec:
	var gen := TxTextGen.new(seed_)
	var tp := gen.tape(tape_index)
	var s := TxLevelSpec.new()
	s.id = "N"
	s.dossier = 0
	s.title = "Nachtdienst · lint %d" % (tape_index + 1)
	s.intro = "Geen kaartenbak vannacht. Spring uit het hoofd."
	s.notes_ref = "Boyer-Moore-Horspool · notas p. 63–66"
	s.priority = "P0"
	s.mode = TxCodes.Mode.LIVE
	s.endless = true
	s.tape_index = tape_index
	s.seed_ = seed_
	var m := str(tp.z).length()
	s.variant = variant
	if variant == "kmp":
		s.title = "Nachtdienst (Doorloper) · lint %d" % (tape_index + 1)
		s.intro = "Verbrande vakjes vannacht. Verschuif daar met de hand."
		s.notes_ref = "Knuth-Morris-Pratt · notas p. 55–62"
		var strip := TxReference.v_def(str(tp.z), true)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed_, tape_index, "burn"])
		var cells: Array = range(2, m + 1)
		for _b in mini(2, cells.size()):
			var c: int = cells.pop_at(rng.randi_range(0, cells.size() - 1))
			strip[c] = TxCodes.STRIP_BURNT
		s.stages = [{"machine": "kmp", "z": str(tp.z), "t": str(tp.t), "find": "all", "strip": strip,
			"auto_zero": true, "auto_strip": true}]
	else:
		s.stages = [{"machine": "bmh", "z": str(tp.z), "t": str(tp.t), "find": "all", "cards": "none", "key_hint": false}]
	s.live = {"v": minf(1.2 + 0.15 * tape_index, 4.0), "B": m + 3}
	s.stars = [S_DONE, S_NOMIS, S_HELP]
	s.ghost = _ghost(s)
	s.expect = {"plants": tp.plants, "decoys": tp.decoys}
	return s


## Maakt de machine voor een stage-spec (GDD §8.5). live = {"B": int} voor LIVE-stages met een lint.
static func make_machine(stage: Dictionary, carry: Dictionary = {}, mode: int = TxCodes.Mode.CALM,
		live: Dictionary = {}) -> TxMachine:
	var mc: TxMachine
	match str(stage.get("machine", "")):
		"brute":
			mc = TxBrute.new()
		"kmp":
			mc = TxKmp.new()
		"kmp_table":
			mc = TxKmpTable.new()
		"bmh":
			mc = TxBmh.new()
		"rk":
			mc = TxRabinKarp.new()
		"shift_and":
			mc = TxShiftAnd.new()
		"edit":
			mc = TxEditBoard.new()
		"sabotage":
			mc = TxSabotage.new()
		_:
			push_error("TxLevels.make_machine: onbekende machine %s" % str(stage.get("machine", "")))
			mc = TxBrute.new()
	var streams := str(stage.get("t", "")) != "" and not str(stage.get("machine", "")) in ["edit", "sabotage", "rk"]
	var lv := live.duplicate()
	if lv.is_empty():
		lv = {"B": -1}
	mc.setup(stage, carry, lv if mode == TxCodes.Mode.LIVE and streams else {})
	return mc


## Speelt alle stages met correct_move() (CALM) en telt de tellers op:
## {ticks, wheel, lamps, relays, rewind, alignments, hits}.
static func optimum(spec: TxLevelSpec) -> Dictionary:
	var tot := {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "rewind": 0, "alignments": 0, "hits": 0,
		"decisions": 0, "machine_time": 0}
	var carry := {}
	var log := TxEventLog.new()
	var list: Array[Dictionary] = []
	for st in spec.stages:
		if str(st.get("machine", "")) == "choice":
			list.append_array(choice_stages(st, str(st.get("best", ""))))
		else:
			list.append(st)
	for i in list.size():
		var st: Dictionary = list[i]
		if str(st.get("tape", "")) != "" and i > 0 and str(list[i - 1].get("tape", "")) != str(st.tape):
			carry = {}
		var mc := make_machine(st, carry, TxCodes.Mode.CALM)
		mc.log = log
		mc.stage_index = i
		mc.begin()
		mc.auto_finish()
		for k in ["ticks", "wheel", "lamps", "relays", "rewind", "alignments"]:
			tot[k] = int(tot[k]) + int(mc.counters[k])
		tot.hits = int(tot.hits) + mc.found_count()
		if bool(st.get("autoplay", false)):
			tot.machine_time = int(tot.machine_time) + mc.machine_time()
		else:
			for e in log.entries:
				if int(e.stage) == i and not bool(e.auto) and bool(e.ok) and int(e.verdict) == TxCodes.Verdict.OK \
						and TxScoring.DECISIONS.has(str(e.type)):
					tot.decisions = int(tot.decisions) + 1
		carry = mc.output()
	return tot


## Finale: de stages die een keuze uit het rek oplevert (voorbereiding door de speler, doorloop automatisch).
static func choice_stages(choice: Dictionary, pick: String) -> Array[Dictionary]:
	var z := str(choice.get("z", ""))
	var t := str(choice.get("t", ""))
	var find := str(choice.get("find", "all"))
	var k := int(choice.get("k", 1))
	var budget := int(choice.get("budget", 0))
	var tag := {"tape": str(choice.get("tape", "")), "budget": budget, "autoplay": true,
		"calm": bool(choice.get("calm", false))}
	if choice.has("truth"):
		tag["truth"] = (choice.truth as Array).duplicate(true)
		tag["match_end"] = true
	var out: Array[Dictionary] = []
	match pick:
		"kmp":
			out.append({"machine": "kmp_table", "z": z, "method": "alg5", "cells": "m", "tape": tag.tape})
			var r := {"machine": "kmp", "z": z, "t": t, "find": find, "strip": "carry", "auto_zero": true,
				"auto_strip": true}
			r.merge(tag)
			out.append(r)
		"bmh":
			out.append({"machine": "bmh", "z": z, "cards": "stamp", "tape": tag.tape})
			var r2 := {"machine": "bmh", "z": z, "t": t, "find": find, "cards": "carry", "auto_jump": true}
			r2.merge(tag)
			out.append(r2)
		"shift_and":
			out.append({"machine": "shift_and", "z": z, "k": 0, "cards": "punch", "run": false, "tape": tag.tape})
			var r3 := {"machine": "shift_and", "z": z, "t": t, "k": 0, "cards": "carry", "find": find}
			r3.merge(tag)
			out.append(r3)
		"shift_and_k":
			out.append({"machine": "shift_and", "z": z, "k": 0, "cards": "punch", "run": false, "tape": tag.tape})
			out.append({"machine": "shift_and", "z": z, "k": k, "cards": "carry", "wiring": "plug", "run": false,
				"tape": tag.tape})
			var r4 := {"machine": "shift_and", "z": z, "t": t, "k": k, "cards": "carry", "wiring": "carry",
				"find": find}
			r4.merge(tag)
			out.append(r4)
		"edit":
			var r6 := {"machine": "edit", "a": z, "b": t, "approx": true, "want": -1}
			r6.merge(tag)
			r6.erase("autoplay")
			out.append(r6)
		_:
			var r5 := {"machine": "brute", "z": z, "t": t, "find": find}
			r5.merge(tag)
			out.append(r5)
	return out


# ------------------------------------------------------------------ leveldata (GDD §5)

static func _all(of: Array) -> Dictionary:
	return {"kind": "all", "of": of}


static func _hits(n: int) -> Dictionary:
	return {"kind": "hits_ge", "n": n}


static func _data(id: String) -> Dictionary:
	match id:
		"1-1":
			return {"title": "Eerste dienst", "priority": "P0", "notes_ref": "Algoritme 2 · notas p. 50–51",
				"intro": "Schuif het sjabloon. De naald doet de rest.",
				"stages": [{"machine": "brute", "z": "kerk", "t": "de_kerker_bij_de_kerk", "find": "all"}],
				"stars": [S_DONE, S_NOMIS, _all([S_HELP, {"kind": "time_le", "s": 60}])],
				"optimum": {"ticks": 27, "wheel": 0, "lamps": 0, "relays": 0, "rewind": 4, "time_par": 60},
				"tutorial": [{"trigger": "first_ready", "ghost": {"act": "go"}, "text": "Schuif het sjabloon. De naald doet de rest."},
					{"trigger": "first_hit", "text": "In `kerker` zit ook een `kerk`."}],
				"story": {"chef_intro": "Schuif het sjabloon. De naald doet de rest.",
					"debrief_extra": "27 tikken voor 21 tekens. Waarom las de kop sommige letters twee keer?",
					"teaser": "Morgen komt er een machine die nooit terugspoelt.", "crate": "A-2"},
				"expect": {"hits": [3, 17]}}
		"1-2":
			return {"title": "Oefening 32: Stoorzender", "priority": "P0", "notes_ref": "Oefening 32 · notas p. 51",
				"intro": "Laat hun machine stikken. Elke uitlijning moet tot het einde tikken.",
				"stages": [{"machine": "sabotage", "target": "brute", "n": 12, "m": 4, "alphabet": "ab",
						"example": {"z": "aaab", "t": "aaaaaaaaaaaa"}, "optimum": 36},
					{"machine": "sabotage", "target": "brute", "n": 16, "m": 8, "alphabet": "ab",
						"example": {"z": "aaaaaaab", "t": "aaaaaaaaaaaaaaaa"}, "optimum": 72}],
				"stars": [_all([{"kind": "metric_ge", "stage": 0, "v": 27}, {"kind": "metric_ge", "stage": 1, "v": 54}]),
					{"kind": "any", "of": [{"kind": "metric_eq_opt", "stage": 0}, {"kind": "metric_eq_opt", "stage": 1}]},
					_all([{"kind": "metric_eq_opt", "stage": 0}, {"kind": "metric_eq_opt", "stage": 1}])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "metric": [36, 72]},
				"story": {"chef_intro": "Laat hun machine stikken. Elke uitlijning moet tot het einde tikken.",
					"debrief_extra": "z = a…ab, t = a…a: elke start kost m tikken en er is geen treffer, dus (n − m + 1)·m; met m = n/2 is dat Θ(n²).",
					"graph": "brute_family"}}
		"1-3":
			return {"title": "Oefening 33: Jokers", "priority": "P2", "notes_ref": "Oefening 33 · notas p. 51",
				"intro": "Het vraagteken past op elke letter.",
				"stages": [{"machine": "brute", "z": "?uizen", "t": "de_huizen_en_buizen", "find": "all", "joker": "?"}],
				"stars": [S_DONE, S_NOMIS, S_HELP],
				"optimum": {"ticks": 36, "wheel": 0, "lamps": 0, "relays": 0},
				"expect": {"hits": [3, 13]}}
		"2-1":
			return {"title": "Het wiel", "priority": "P0", "notes_ref": "Algoritme 3 · notas p. 52–54",
				"intro": "Het wiel kent maar zeven standen. Daar zit de modulo in.",
				"stages": [{"machine": "rk", "z": "1011", "q": 7, "signals": ["0100", "1011", "1110"],
					"prep": ["w", "hz"], "find": "all"}],
				"stars": [S_DONE, S_NOMIS, S_HELP],
				"optimum": {"ticks": 5, "wheel": 30, "lamps": 0, "relays": 0},
				"tutorial": [{"trigger": "first_alarm", "ghost": {"act": "verify"}, "text": "Zelfde vingerafdruk? Controleer het woord."}],
				"story": {"chef_intro": "Het wiel kent maar zeven standen. Daar zit de modulo in.", "crate": "R-K · q"},
				"expect": {"hits": [1]}}
		"2-2":
			return {"title": "Rollen", "priority": "P0", "notes_ref": "rollende hash · notas p. 53",
				"intro": "Wat links wegvalt, moet eruit: −w als dat bit 1 was.",
				"stages": [{"machine": "rk", "z": "1011", "q": 7, "t": "1010010110110100", "find": "all",
					"prep": ["w", "hz", "h0"], "prefill": {"w": 2, "hz": 4}}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 10, "wheel": 31, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Wat links wegvalt, moet eruit: −w als dat bit 1 was."},
				"expect": {"hits": [5, 8]}}
		"2-3":
			return {"title": "Oefening 34", "priority": "P0", "notes_ref": "Oefening 34 · notas p. 54",
				"intro": "Dertien tanden, vijf bits.",
				"stages": [{"machine": "rk", "z": "00101", "q": 13, "t": "1101110010001010", "find": "first",
					"prep": ["w", "hz", "h0"]}],
				"stars": [_hits(1), S_NOMIS, _all([S_HELP, {"kind": "time_le", "s": 150}])],
				"optimum": {"ticks": 6, "wheel": 41, "lamps": 0, "relays": 0, "time_par": 150},
				"story": {"chef_intro": "Dertien tanden, vijf bits.", "title_card": "Oefening 34 — lesnotas p. 54",
					"debrief_extra": "Venster 5: 10010 = 18 ≡ 5 (mod 13): een hashbotsing."},
				"expect": {"hits": [10]}}
		"2-4":
			return {"title": "Oefening 34b: Botsingsregen", "priority": "P1", "notes_ref": "Oefening 34 · notas p. 54",
				"intro": "Laat hun Vingerafdruk zo vaak mogelijk controleren.",
				"stages": [{"machine": "sabotage", "target": "rk_calls", "n": 16, "m": 5, "alphabet": "01",
					"z_fixed": "00101", "q": 13, "example": {"z": "00101", "t": "1111111111111111"}, "optimum": 12}],
				"stars": [{"kind": "metric_ge", "stage": 0, "v": 6}, {"kind": "metric_ge", "stage": 0, "v": 10},
					{"kind": "metric_ge", "stage": 0, "v": 12}],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "metric": [12]},
				"story": {"debrief_extra": "Elke 11111 botst: 31 = 2·13 + 5. Opmerking 10: in het slechtste geval blijft het O((n − m + 1)·m)."}}
		"3-1":
			return {"title": "Barbados", "priority": "P0", "notes_ref": "Definitie 11, Algoritme 4 · notas p. 56–59",
				"intro": "Wat je al las, moet blijven kloppen. De kleinste sprong die past.",
				"stages": [{"machine": "kmp", "z": "barbados", "t": "barbaarse_barbecue_in_barbados", "find": "first",
					"strip": "none", "auto_zero": true}],
				"stars": [_hits(1), S_NOMIS, _all([S_BUMPS, S_HELP])],
				"optimum": {"ticks": 34, "wheel": 0, "lamps": 0, "relays": 0, "rewind": 0},
				"tutorial": [{"trigger": "first_decide", "ghost": {"act": "shift", "s": 3}, "demo": [1, 2, 3],
					"text": "Wat je al las, moet blijven kloppen. De kleinste sprong die past."}],
				"story": {"chef_intro": "Wat je al las, moet blijven kloppen. De kleinste sprong die past.",
					"debrief_extra": "Jouw sprongen 3, 2, 3, 1 staan in de tabel van p. 56: V[5] = 3, V[2] = 2, V[4] = 3, V[1] = 1.",
					"crate": "K-M-P 1977"},
				"expect": {"hits": [22], "shifts": [3, 2, 3, 1]}}
		"3-2":
			return {"title": "De spiegel — Oefening 40", "priority": "P0", "notes_ref": "Oefening 40 · notas p. 62",
				"intro": "Pons de strook. Wat zou je doen bij elke mismatch?",
				"stages": [{"machine": "kmp_table", "z": "ananas", "method": "def11", "cells": "m-1"},
					{"machine": "kmp", "z": "ananas", "t": "bananen_in_ra'ananas'_centrum", "find": "first",
						"strip": "carry", "auto_zero": true, "auto_strip": true}],
				"stars": [_hits(1), S_NOMIS, _all([S_BUMPS, S_HELP])],
				"optimum": {"ticks": 23, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Pons de strook. Wat zou je doen bij elke mismatch?",
					"debrief_extra": "Oefening 40: V = 1 1 2 2 2 2. Met V[4] = 4 (past ook!) had de Doorloper op start 1 te ver gesprongen."},
				"expect": {"hits": [14], "strip": [1, 1, 2, 2, 2, 2]}}
		"3-3":
			return {"title": "Spiegelrit — Oefening 39", "priority": "P0", "notes_ref": "Algoritme 5, Oefening 39 · notas p. 61–62",
				"intro": "Zoek het woord in zichzelf. Wat je onderweg leert, pons je.",
				"stages": [{"machine": "kmp_table", "z": "volvoert", "method": "alg5", "cells": "m-1"},
					{"machine": "kmp", "z": "volvoert", "t": "volvo_vol_vogels_volvoert_kunststukje", "find": "first",
						"strip": "carry", "auto_zero": true, "auto_strip": true}],
				"stars": [_hits(1), S_NOMIS, _all([S_HELP, {"kind": "time_le", "s": 180}])],
				"optimum": {"ticks": 36, "wheel": 0, "lamps": 0, "relays": 0, "time_par": 180},
				"story": {"chef_intro": "Zoek het woord in zichzelf. Wat je onderweg leert, pons je.",
					"title_card": "Oefening 39 — p. 62",
					"debrief_extra": "Dezelfde strook als `barbados` (p. 56): V hangt enkel af van hoe z op zichzelf past."},
				"expect": {"hits": [17], "strip": [1, 1, 2, 3, 3, 3, 6, 7]}}
		"3-4":
			return {"title": "Oefening 41: Alle voorkomens", "priority": "P1", "notes_ref": "Oefening 41 · notas p. 62",
				"intro": "Na een treffer niet stoppen. Hoe ver mag je dan?",
				"stages": [{"machine": "kmp_table", "z": "tata", "method": "alg5", "cells": "m"},
					{"machine": "kmp", "z": "tata", "t": "tatatata_zei_de_telex_tatata", "find": "all",
						"strip": "carry", "auto_zero": true, "auto_strip": true}],
				"stars": [_hits(3), S_NOMIS, S_HELP],
				"optimum": {"ticks": 34, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Na een treffer niet stoppen. Hoe ver mag je dan?",
					"debrief_extra": "Oefening 41: na een treffer verschuif je met V[m] (Definitie 11 voor j = m). Algoritme 4 zelf stopt bij de eerste treffer."},
				"expect": {"hits": [0, 2, 4, 22, 24], "strip": [1, 1, 2, 2, 2]}}
		"3-5":
			return {"title": "Nachtstroom", "priority": "P1", "notes_ref": "geschikt voor streams · notas p. 50, Stelling 12 p. 59",
				"intro": "Zij moet terug. Jij niet.", "mode": "live",
				"stages": [{"machine": "kmp", "z": "kokos", "t": "kokokokos_in_de_kokoskokosnoot", "find": "all",
					"strip": [1, 1, 2, 2, TxCodes.STRIP_BURNT, TxCodes.STRIP_BURNT], "auto_zero": true, "auto_strip": true}],
				"live": {"v": 0.8, "B": 4, "rival": true},
				"stars": [_hits(2), _all([_hits(3), S_NOMIS]), _all([{"kind": "no_tear"}, S_HELP])],
				"optimum": {"ticks": 28, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Zij moet terug. Jij niet."},
				"expect": {"hits": [4, 16, 21], "rival_tears": [5, 7, 9, 21, 26]}}
		"4-1":
			return {"title": "Barbara", "priority": "P0", "notes_ref": "Boyer-Moore-Horspool · notas p. 63–65",
				"intro": "Kijk onder de laatste letter. Spring zo ver als het mag.",
				"stages": [{"machine": "bmh", "z": "barbara", "cards": "stamp"},
					{"machine": "bmh", "z": "barbara", "t": "barbados_zoekt_barbara", "find": "first", "cards": "carry",
						"key_hint": true}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 10, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Kijk onder de laatste letter. Spring zo ver als het mag.", "crate": "B-M-H 1980"},
				"expect": {"hits": [15], "cards": {"a": 2, "b": 3, "r": 1}}}
		"4-2":
			return {"title": "Oefening 48", "priority": "P0", "notes_ref": "Oefening 48 · notas p. 66",
				"intro": "Ananas, maar dan springend.",
				"stages": [{"machine": "bmh", "z": "ananas", "cards": "stamp"},
					{"machine": "bmh", "z": "ananas", "t": "de_spa_in_ra'ananas'", "find": "first", "cards": "carry",
						"key_hint": true}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 9, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"title_card": "Oefening 48 — p. 66"},
				"expect": {"hits": [13], "cards": {"a": 1, "n": 2}}}
		"4-3":
			return {"title": "Walsalsa", "priority": "P0", "notes_ref": "is_contained_BMH · notas p. 65",
				"intro": "Het teken waar het misging? Nee: kijk onder de laatste letter.",
				"stages": [{"machine": "bmh", "z": "salsa", "cards": "stamp"},
					{"machine": "bmh", "z": "salsa", "t": "de_band_speelt_walsalsa_en_salsa", "find": "all",
						"cards": "carry", "key_hint": false}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 22, "wheel": 0, "lamps": 0, "relays": 0},
				"story": {"chef_intro": "Het teken waar het misging? Nee: kijk onder de laatste letter."},
				"expect": {"hits": [18, 27], "cards": {"a": 3, "l": 2, "s": 1}}}
		"4-4":
			return {"title": "Oefening 50: Vliegen en kruipen", "priority": "P1", "notes_ref": "Oefening 50 · notas p. 66–67",
				"intro": "Laat de Springer eerst vliegen, dan kruipen.",
				"stages": [{"machine": "sabotage", "target": "bmh_min", "n": 16, "m": 4, "alphabet": "ab",
						"example": {"z": "bbbb", "t": "aaaaaaaaaaaaaaaa"}, "optimum": 4},
					{"machine": "sabotage", "target": "bmh_max", "n": 16, "m": 4, "alphabet": "ab",
						"example": {"z": "baaa", "t": "aaaaaaaaaaaaaaaa"}, "optimum": 52}],
				"stars": [_all([{"kind": "metric_le", "stage": 0, "v": 6}, {"kind": "metric_ge", "stage": 1, "v": 40}]),
					{"kind": "any", "of": [{"kind": "metric_eq_opt", "stage": 0}, {"kind": "metric_eq_opt", "stage": 1}]},
					_all([{"kind": "metric_eq_opt", "stage": 0}, {"kind": "metric_eq_opt", "stage": 1}])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "metric": [4, 52]},
				"story": {"debrief_extra": "Beste geval Θ(n/m) (z = bbbb, t = a…a); slechtste geval Θ(n·m) (z = baaa, t = a…a)."}}
		"5-1":
			return {"title": "Ana", "priority": "P0", "notes_ref": "Figuur 23 · notas p. 67–69",
				"intro": "Omlaag, bovenste aan, kaart erin. Licht onderaan? Bel!",
				"stages": [{"machine": "shift_and", "z": "ana", "k": 0, "cards": "punch", "run": false},
					{"machine": "shift_and", "z": "ana", "t": "ananas", "k": 0, "cards": "carry", "find": "all"}],
				"stars": [S_DONE, S_NOMIS, S_HELP],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 6, "relays": 0},
				"story": {"chef_intro": "Omlaag, bovenste aan, kaart erin. Licht onderaan? Bel!", "crate": "B-Y/G"},
				"expect": {"hits": [0, 2]}}
		"5-2":
			return {"title": "Oefening 54", "priority": "P0", "notes_ref": "Oefening 54 · notas p. 69",
				"intro": "Letters die niet in `zoeken` staan? Blanco.",
				"stages": [{"machine": "shift_and", "z": "zoeken", "k": 0, "cards": "punch", "run": false},
					{"machine": "shift_and", "z": "zoeken", "t": "iets_zoets_zoeken", "k": 0, "cards": "carry",
						"find": "all"}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 17, "relays": 0},
				"story": {"chef_intro": "Letters die niet in `zoeken` staan? Blanco.", "title_card": "Oefening 54 — p. 69"},
				"expect": {"hits": [11]}}
		"5-3":
			return {"title": "Tiktak", "priority": "P1", "notes_ref": "shift-AND · notas p. 67", "mode": "live",
				"intro": "Op de tel: t, i of k. Al de rest is blanco.",
				"stages": [{"machine": "shift_and", "z": "tik", "t": "tiktak_tiktiktak_tik_taktik_tikkertje_tiktik",
					"k": 0, "cards": "prefilled", "find": "all", "auto_lever": true}],
				"live": {"bpm": 100, "strak": 0.2},
				"stars": [_hits(6), _all([_hits(8), S_NOMIS]), {"kind": "strak_ge", "n": 24}],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 44, "relays": 0},
				"expect": {"hits": [0, 7, 10, 17, 24, 28, 38, 41], "cards_needed": 32}}
		"6-1":
			return {"title": "Oefening 60", "priority": "P0", "notes_ref": "Definitie 14, Oefening 60 · notas p. 70–71",
				"intro": "Eén fout mag. Waar komt die fout vandaan?",
				"stages": [{"machine": "shift_and", "z": "dank", "k": 0, "cards": "punch", "run": false},
					{"machine": "shift_and", "z": "dank", "k": 1, "cards": "carry", "wiring": "plug", "run": false},
					{"machine": "shift_and", "z": "dank", "t": "een_dansfeest", "k": 1, "cards": "carry",
						"wiring": "carry", "find": "all"}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 13, "relays": 0},
				"story": {"chef_intro": "Eén fout mag. Waar komt die fout vandaan?", "title_card": "Oefening 60 — p. 71",
					"crate": "W-M 1992",
					"wire_effects": {"old": "geen bel: dans gemist", "new_shift": "bel op j = 6: vals alarm, dans gemist",
						"new": "geen bel: dans gemist"}},
				"expect": {"hits": [4]}}
		"6-2":
			return {"title": "Zender of zonder?", "priority": "P1", "notes_ref": "Definitie 14 · notas p. 70",
				"intro": "Vier kandidaten. Eén is echt.",
				"stages": [{"machine": "shift_and", "z": "zender", "k": 0, "cards": "punch", "run": false},
					{"machine": "shift_and", "z": "zender", "k": 1, "cards": "carry", "wiring": "plug", "run": false},
					{"machine": "shift_and", "z": "zender", "t": "zonder_zender_zander_zinder", "k": 1, "cards": "carry",
						"wiring": "carry", "find": "all", "choose": true}],
				"stars": [{"kind": "pick_ok"}, S_NOMIS, S_HELP],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 27, "relays": 0},
				"expect": {"hits": [0, 7, 14, 21], "pick": 7}}
		"7-1":
			return {"title": "Lessen → feesten", "priority": "P0", "notes_ref": "Definitie 15, Algoritme 7 · notas p. 72–76",
				"intro": "De stroom neemt altijd de kortste weg. Jij ook.",
				"stages": [{"machine": "edit", "a": "lessen", "b": "feesten", "approx": false, "want": 2}],
				"stars": [S_DONE, S_NOMIS, _all([S_HELP, {"kind": "sequences_ge", "n": 2}])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 42},
				"story": {"chef_intro": "De stroom neemt altijd de kortste weg. Jij ook.", "crate": "L",
					"notes_order": "Notas p. 72: vervang l door f · vervang s op positie 3 door t · voeg e toe op positie 1."},
				"expect": {"distance": 3, "sequences": 4}}
		"7-2":
			return {"title": "Oefening 62", "priority": "P0", "notes_ref": "Oefening 62 · notas p. 76",
				"intro": "Toon hoe elk getal ontstond.",
				"stages": [{"machine": "edit", "a": "roestig", "b": "oesters", "approx": false, "want": -1}],
				"stars": [S_DONE, S_NOMIS, _all([S_HELP, {"kind": "sequences_ge", "n": 3}])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 49},
				"story": {"chef_intro": "Toon hoe elk getal ontstond.", "title_card": "Oefening 62 — p. 76"},
				"expect": {"distance": 4, "sequences": 3}}
		"8-1":
			return {"title": "Examen", "priority": "P0", "notes_ref": "Algoritme 8 · notas p. 77–79",
				"intro": "Nu mag de stroom overal instappen. Waar komt ze het goedkoopst uit?",
				"stages": [{"machine": "edit", "a": "examen", "b": "de_armen_vouwen", "approx": true, "prefill_rows": 3,
					"want": 1}],
				"stars": [_hits(1), S_NOMIS, S_HELP],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 45},
				"story": {"chef_intro": "Nu mag de stroom overal instappen. Waar komt ze het goedkoopst uit?", "crate": "L-8"},
				"expect": {"hits": [1], "best": 2}}
		"8-2":
			return {"title": "Oefening 70", "priority": "P0", "notes_ref": "Oefening 70 · notas p. 79",
				"intro": "Zoek zoeken in de koekjes.",
				"stages": [{"machine": "edit", "a": "zoeken", "b": "koekjes_kweken", "approx": true, "want": -1}],
				"stars": [_hits(1), S_NOMIS, _all([S_HELP, {"kind": "starts_all"}])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 84},
				"story": {"title_card": "Oefening 70 — p. 79"},
				"expect": {"hits": [8, 9, 10], "best": 2}}
		"8-3":
			return {"title": "Oefening 71", "priority": "P0", "notes_ref": "Oefening 71 · notas p. 79",
				"intro": "Drie plekken, één test.",
				"stages": [{"machine": "edit", "a": "test", "b": "beste_tekst", "approx": true, "want": -1}],
				"stars": [_hits(1), _all([{"kind": "ends_all"}, S_NOMIS]), _all([{"kind": "matches_all"}, S_HELP])],
				"optimum": {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 44},
				"expect": {"hits": [0, 1, 3, 6], "best": 1}}
		"F":
			return {"title": "Operatie Ekster", "priority": "P1", "notes_ref": "§3.4–3.5", "mode": "live",
				"intro": "Drie linten, één nacht. Kies je machine.",
				"stages": [
					{"machine": "choice", "tape": "F-1", "z": "ekster",
						"t": "kom_naar_de_ekster_want_de_eksters_eten_ekster_brood", "find": "all",
						"options": ["kmp", "shift_and", "bmh", "brute"], "best": "kmp"},
					{"machine": "choice", "tape": "F-2", "z": "ekster", "t": "de_ekstar_zag_de_akster_op_het_dak",
						"find": "all", "k": 1, "calm": true,
						"truth": [{"start": 3, "end": 8, "level": 1}, {"start": 17, "end": 22, "level": 1}],
						"options": ["shift_and_k", "edit", "kmp", "bmh", "brute", "shift_and"], "best": "shift_and_k"},
					{"machine": "choice", "tape": "F-3", "z": "vuurtoren",
						"t": "de_wachter_van_de_vuurtoren_ziet_om_middernacht_een_boot_zonder_licht_en_seint_naar_de_tweede_vuurtoren_aan_de_haven",
						"find": "all", "budget": 60, "calm": true, "options": ["bmh", "kmp", "shift_and", "brute"],
						"best": "bmh"}],
				"live": {"v": 2.0, "B": 1},
				"stars": [_hits(5), _all([_hits(7), {"kind": "no_false_alarms"}]), {"kind": "budget_le", "v": 120}],
				"optimum": {"machine_time": 118},
				"story": {"chef_intro": "Drie linten, één nacht.", "outro": "Goed gelezen, lintlezer.",
					"debrief_extra": "Machinetijd (tik = lampslag = relais = 1) is een spelvereenvoudiging om machines te vergelijken."},
				"expect": {"hits": 7, "machine_time": {"F-1": 51, "F-2": 34, "F-3": 33}}}
	return {}
