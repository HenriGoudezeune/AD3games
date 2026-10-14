class_name ScEventLog extends RefCounted
## Chronologische log van een level (terugblik, herbeleving, oorzaakketens; GDD §8.9, §6.5).
## entry = {seq, t, stage, type, data (incl. move, at = tekstpositie), verdict, ok, auto, hint, affects, before}
##   ok      = false bij een klem (de staat veranderde niet)
##   hint    = correct_move() vóór de zet ({} bij automatische events)
##   affects = posities in de tekst die hierdoor anders gelezen werden (de director vult dit na de voorlezing)
##   before  = snapshot() vóór de zet; enkel bij verdict ≠ OK, bij klemmen en bij de eerste zet van elke stage
## Types: STAGE_START READ CUT RESET DONE PLACE REMOVE SEND BIND CODEBOOK COPY WRITE GROW SWAP KEEP SEGMENT BIT START
## LITERAL REGISTER EXTEND STAMP CARVE INSERT MARK FIND NUMBER PICK ROOST DECREE READING GARBLED TWO_PIGEONS BUMP HINT
## UNDO RESUME STAGE_END LEVEL_END (+ AUTO_CUT, SLOT, UNREADABLE, ROUND, CANDLE in de Nachtwake / automatische stappen)

const V := ScCodes.Verdict

var entries: Array[Dictionary] = []
var now: float = 0.0
var stage: int = 0


func add(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary,
		auto := false) -> Dictionary:
	var e := {"seq": entries.size(), "t": now, "stage": stage, "type": type, "data": data, "verdict": verdict, "ok": ok,
		"auto": auto, "hint": hint, "affects": [], "before": before}
	entries.append(e)
	return e


func clear() -> void:
	entries.clear()


func size() -> int:
	return entries.size()


func truncate(n: int) -> void:
	if n >= 0 and n < entries.size():
		entries.resize(n)


func entry(seq: int) -> Dictionary:
	return entries[seq] if seq >= 0 and seq < entries.size() else {}


## Misstappen: beslissingen met verdict ∉ {OK, BUMP}. Gevolgen (GARBLED, TWO_PIGEONS) tellen niet mee.
func mistakes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		var v := int(e.verdict)
		if v != V.OK and v != V.BUMP and not ScCodes.CONSEQUENCES.has(v):
			out.append(e)
	return out


func bumps() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if not bool(e.ok):
			out.append(e)
	return out


func consequences() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if ScCodes.CONSEQUENCES.has(int(e.verdict)):
			out.append(e)
	return out


func of_type(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if e.type == type:
			out.append(e)
	return out


func count_type(type: String) -> int:
	return of_type(type).size()


func of_verdict(v: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if int(e.verdict) == v:
			out.append(e)
	return out


## De misstap die positie pos van de voorlezing/kopie anders liet lezen: de laatste misstap (in die stage, of in de
## keten van stages ≤ stage_index) met tekstpositie `at` ≤ pos; {} als er geen is.
func cause_of(pos: int, stage_index := -1) -> Dictionary:
	var ms := mistakes()
	for i in range(ms.size() - 1, -1, -1):
		var e: Dictionary = ms[i]
		if stage_index >= 0 and int(e.stage) > stage_index:
			continue
		var at := int((e.data as Dictionary).get("at", 0))
		if at <= pos:
			return e
	return {}


static func _q(s) -> String:
	return "`" + ScCodes.show_text(str(s)) + "`"


static func _d(e: Dictionary) -> Dictionary:
	return e.get("data", {})


## Eén coachzin (≤ 16 woorden; GDD §6.5). "" als er niets te zeggen valt.
func coach_line(e: Dictionary) -> String:
	var d := _d(e)
	var v := int(e.get("verdict", V.OK))
	match v:
		V.NOT_PREFIX:
			return "%s is het begin van %s: de lezer weet niet waar de letter stopt." % [_q(d.get("a", "")),
				_q(d.get("b", ""))]
		V.LONG_CODE:
			return "Frequente letters hoger hangen: %s (%d×) verdient een korter woord dan %s." % [_q(d.get("x", "")),
				int(d.get("ax", 0)), _q(d.get("y", ""))]
		V.WRONG_PAIR:
			return "De twee lichtste waren %d en %d, niet %d en %d." % [int(d.get("w1", 0)), int(d.get("w2", 0)),
				int(d.get("v1", 0)), int(d.get("v2", 0))]
		V.WRONG_LEAF:
			if bool(d.get("new", false)):
				return "%s is nieuw: eerst de code van nng, dan de letter." % _q(d.get("x", ""))
			return "Schrijf %s met de boom zoals hij nu is: %s." % [_q(d.get("x", "")), str(d.get("code", ""))]
		V.MISSED_SWAP:
			return "Gewicht %d: %s staat verder in de processie (%d > %d). Wissel." % [int(d.get("w", 0)),
				str(d.get("t2", "")), int(d.get("o2", 0)), int(d.get("o1", 0))]
		V.WRONG_SWAP:
			if bool(d.get("should_keep", false)):
				return "Niemand met gewicht %d staat verder (of het is je ouder): blijf staan." % int(d.get("w", 0))
			return "Wissel met de top met gewicht %d en het hoogste nummer: %s." % [int(d.get("w", 0)), str(d.get("t2", ""))]
		V.WRONG_SEGMENT:
			return "Het volgende teken is %s: knip het vak [%s; %s)." % [_q(d.get("x", "")), str(d.get("lo", "")),
				str(d.get("hi", ""))]
		V.OVERSHOOT:
			return "%s + %s ≥ %s: die stap valt boven het interval. Schrijf 0." % [str(d.get("g", "")),
				str(d.get("nx", "")), str(d.get("up", ""))]
		V.LONG_BITS:
			return "%s + %s lag al in [%s; %s): stap en je bent klaar." % [str(d.get("g", "")), str(d.get("nx", "")),
				str(d.get("low", "")), str(d.get("up", ""))]
		V.UNREACHABLE:
			return "Zonder die stap haal je %s nooit meer: de rest is samen maar %s." % [str(d.get("low", "")),
				str(d.get("nx", ""))]
		V.WRONG_EDGE:
			return "[a, b) bevat b niet: %s hoort bij %s." % [str(d.get("r", "")), _q(d.get("x", ""))]
		V.SHORT_MATCH:
			return "Vanaf positie %d loopt de match %d letters ver, niet %d." % [int(d.get("p", 0)), int(d.get("l", 0)),
				int(d.get("l2", 0))]
		V.WRONG_POS:
			return "Positie %d telt vanaf de linkerrand van het raam, de eerste is 0." % int(d.get("p", 0))
		V.EARLY_STAMP:
			return "%s zat al in de kast: eerst verlengen." % _q(d.get("wk", ""))
		V.WRONG_CARVE:
			if bool(d.get("special", false)):
				return "Code %d bestaat nog niet: %s + %s." % [int(d.get("c", 0)), _q(d.get("w", "")), _q(d.get("w0", ""))]
			return "Nieuwe stempel = %s + de eerste letter van %s." % [_q(d.get("w", "")), _q(d.get("next", ""))]
		V.WRONG_ORDER:
			return "%s komt vóór %s: vergelijk letter per letter, de spatie is het kleinst." % [_q(d.get("a", "")),
				_q(d.get("b", ""))]
		V.WRONG_P:
			return "p is de rij die eindigt op het eerste teken %s: rij %d." % [_q(d.get("s0", "")), int(d.get("p", 0))]
		V.WRONG_RANK:
			return "Dit is de %de %s in e, dus de %de %s in c: rij %d." % [int(d.get("k", 0)), _q(d.get("x", "")),
				int(d.get("k", 0)), _q(d.get("x", "")), int(d.get("i", 0))]
		V.WRONG_INDEX:
			return "%s staat op plaats %d van de lijst zoals ze nu is (vanaf 0)." % [_q(d.get("x", "")), int(d.get("k", 0))]
		V.WRONG_DECREE:
			return "Minder bits, minder hokken: wie iets korter maakt, maakt iets anders langer."
		V.GARBLED:
			return "Hier las de overkant %s in plaats van %s: zie %s." % [_q(d.get("read", "")), _q(d.get("orig", "")),
				str(d.get("cause", "de laatste misstap"))]
		V.TWO_PIGEONS:
			return "%d druppels voor een koker van %d: er moest een tweede duif mee." % [int(d.get("ink", 0)),
				int(d.get("opt", 0))]
		V.BUMP:
			return bump_line(str(d.get("reason", "")))
	return ""


static func bump_line(reason: String) -> String:
	match reason:
		"not_leaf":
			return "Letters hangen enkel aan bladeren."
		"no_path":
			return "Daar leiden de bits niet naartoe."
		"no_word":
			return "Dat stuk is geen codewoord."
		"need_more":
			return "Zoek eerst nog een lezing."
		"taken":
			return "Die plaats is al bezet."
		"range":
			return "Daar kan het gereedschap niet bij."
		"incomplete":
			return "Eerst moeten alle letters hangen."
		"same":
			return "Een stapel kan je niet met zichzelf binden."
		"not_front":
			return "Neem enkel van de voorkant van een plank."
		"empty":
			return "Die plank is leeg."
		"ancestor":
			return "Je ouder is de verste? Dan blijf je staan."
		"self":
			return "Klik de lantaarn om te blijven staan."
		"no_pin":
			return "De speld zit niet in dat vak."
		"out_of_window":
			return "Een match begint in het raam."
		"no_match":
			return "Die letter is niet de volgende letter."
		"no_stamp":
			return "Die stempel bestaat nog niet: stempel eerst."
		"letter":
			return "Zoek dezelfde letter in kolom c."
		"not_shorter":
			return "Er is nog een korter hok vrij."
		"unreadable":
			return "De strook is onleesbaar geworden."
		"wrong_phase":
			return "Dat kan nu niet."
	return "Klem."


## Notasverwijzing bij een event (GDD §6.5).
func notes_ref(e: Dictionary) -> String:
	var v := int(e.get("verdict", V.OK))
	match v:
		V.NOT_PREFIX:
			return "Definitie 20 · notas p. 83"
		V.LONG_CODE:
			return "notas p. 84"
		V.WRONG_PAIR:
			return "Algoritme 9 · notas p. 84"
		V.WRONG_LEAF:
			return "notas p. 94–95" if bool(_d(e).get("new", false)) else "notas p. 92"
		V.MISSED_SWAP, V.WRONG_SWAP:
			return "Algoritme 11 · notas p. 95"
		V.WRONG_SEGMENT:
			return "Algoritme 12 · notas p. 101"
		V.OVERSHOOT, V.LONG_BITS, V.UNREACHABLE:
			return "Algoritme 13 · notas p. 102"
		V.WRONG_EDGE:
			return "notas p. 99"
		V.SHORT_MATCH:
			return "Algoritme 14 · notas p. 105"
		V.WRONG_POS:
			return "notas p. 106"
		V.EARLY_STAMP:
			return "LZW · notas p. 111"
		V.WRONG_CARVE:
			return "LZW-decoderen · notas p. 113"
		V.WRONG_ORDER:
			return "notas p. 116"
		V.WRONG_P:
			return "notas p. 117"
		V.WRONG_RANK:
			return "notas p. 118"
		V.WRONG_INDEX:
			return "move-to-front · notas p. 121"
		V.WRONG_DECREE:
			return "Oefening 76 · notas p. 81"
		V.GARBLED:
			var c := entry(int(_d(e).get("cause_seq", -1)))
			return notes_ref(c) if not c.is_empty() and int(c.verdict) != V.GARBLED else ""
		V.BUMP:
			match str(_d(e).get("reason", "")):
				"ancestor":
					return "Algoritme 11 · notas p. 95"
				"not_leaf", "no_path":
					return "notas p. 83"
				"no_pin":
					return "notas p. 99"
				"out_of_window", "no_match":
					return "notas p. 105"
				"no_stamp":
					return "LZW · notas p. 111"
				"letter":
					return "notas p. 118"
				"not_front":
					return "Oefening 85 · notas p. 88"
	return ""
