class_name TxEventLog extends RefCounted
## Chronologische log van een level (debrief, herbeleving, oorzaakketens; GDD §8.9, §6.5).
## entry = {seq, t, stage, type, data (incl. move), verdict, ok, auto, hint, affects, before}
##   ok      = false bij een klem (fysiek onmogelijke zet; de staat veranderde niet)
##   hint    = correct_move() vóór de zet ({} bij automatische events)
##   affects = beginposities van voorkomens die door dit event gemist of vals gemeld werden
##   before  = snapshot() vóór de zet; enkel bij verdict ≠ OK, bij klemmen en bij de eerste zet van elke stage
## Types: STAGE_START GO NEEDLE SHIFT STRIP PUNCH PUNCH_TO DONE WHEEL COMMIT BIT SLIDE VERIFY REPORT IGNORE STAMP
##        CARDS_DONE KEY JUMP HOLE PLUG WIRE_DONE LEVER CARD CHOOSE FILL PICK_END STEP TRACE_AGAIN FINISH SET SEND
##        HIT MISSED FALSE_ALARM TEAR BUMP HINT UNDO STAGE_END LEVEL_END

const V := TxCodes.Verdict

var entries: Array[Dictionary] = []
var now: float = 0.0     # tijdstempel voor de volgende add(); machine/director zetten dit
var stage: int = 0       # stage-index voor de volgende add(); de director zet dit


func add(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary,
		auto := false) -> Dictionary:
	var e := {
		"seq": entries.size(),
		"t": now,
		"stage": stage,
		"type": type,
		"data": data,
		"verdict": verdict,
		"ok": ok,
		"auto": auto,
		"hint": hint,
		"affects": [],
		"before": before,
	}
	entries.append(e)
	return e


func clear() -> void:
	entries.clear()


func size() -> int:
	return entries.size()


## Kapt de log af op n entries (terugnemen).
func truncate(n: int) -> void:
	if n >= 0 and n < entries.size():
		entries.resize(n)


func entry(seq: int) -> Dictionary:
	return entries[seq] if seq >= 0 and seq < entries.size() else {}


## Misstappen: verdict ∉ {OK, BUMP} (GDD §5.1).
func mistakes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		var v := int(e.verdict)
		if v != V.OK and v != V.BUMP:
			out.append(e)
	return out


func bumps() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if not bool(e.ok) or int(e.verdict) == V.BUMP:
			out.append(e)
	return out


func of_type(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if e.type == type:
			out.append(e)
	return out


func count_type(type: String) -> int:
	var n := 0
	for e in entries:
		if e.type == type:
			n += 1
	return n


func of_verdict(v: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if int(e.verdict) == v:
			out.append(e)
	return out


## Het event dat voorkomen @start deed missen of vals melden (het laatste met start in affects), of {}.
func cause_of(start: int, stage_index := -1) -> Dictionary:
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		if stage_index >= 0 and int(e.stage) != stage_index:
			continue
		for a in e.affects:
			if int(a) == start:
				return e
	return {}


static func _q(s) -> String:
	return "`" + str(s) + "`"


static func _d(e: Dictionary) -> Dictionary:
	return e.get("data", {})


## Eén coachzin (≤ 16 woorden; GDD §6.5). "" als er niets te zeggen valt.
func coach_line(e: Dictionary) -> String:
	var d := _d(e)
	var v := int(e.get("verdict", V.OK))
	match v:
		V.SHIFT_LONG:
			return "Na een mismatch op %d past al %d plaatsen: V[%d] = %d, niet %d." % [int(d.get("j", 0)),
				int(d.get("v", 0)), int(d.get("j", 0)), int(d.get("v", 0)), int(d.get("s", 0))]
		V.PUNCH_LONG:
			return "Vakje %d: de kleinste passende verschuiving is %d." % [int(d.get("j", 0)), int(d.get("v", 0))]
		V.PUNCH_SHORT:
			if d.has("a"):
				return "Pons tot en met de mismatch: vakjes %d t.e.m. %d krijgen %d." % [int(d.get("a", 0)),
					int(d.get("b", 0)), int(d.get("v", 0))]
			return "Er bleven vakjes leeg: %s." % str(d.get("empty", []))
		V.LATE:
			return "t[%d] = %s staat in z: kaart %s vóór de volgende tel." % [int(d.get("j", 0)), _q(d.get("x", "")),
				str(d.get("x", ""))]
		V.WRONG_HASH:
			if str(d.get("part", "")) == "w":
				return "Gewicht: zet het wiel op 1 en verdubbel %d keer: w = %d." % [int(d.get("m", 0)), int(d.get("x", 0))]
			return "Venster %d: 2·%d%s%s mod %d = %d, niet %d." % [int(d.get("i", 0)), int(d.get("h", 0)),
				" − %d" % int(d.get("w", 0)) if bool(d.get("minus", false)) else "",
				" + 1" if bool(d.get("plus", false)) else "", int(d.get("q", 0)), int(d.get("x", 0)), int(d.get("y", 0))]
		V.WRONG_HORNER:
			return "Bit %d: ×2%s geeft %d (mod %d)." % [int(d.get("k", 0)), ", +1" if bool(d.get("plus", false)) else "",
				int(d.get("x", 0)), int(d.get("q", 0))]
		V.UNVERIFIED:
			return "Gelijke hash is geen bewijs: Algoritme 3 roept dan nog strings_gelijk() op."
		V.SKIPPED_CHECK:
			return "Wijzer op h(z) = %d: altijd strings_gelijk() oproepen." % int(d.get("hz", 0))
		V.FALSE_ALARM:
			match str(d.get("machine", "")):
				"rk":
					return "%s ≡ %d (mod %d), maar %s ≠ z: een hashbotsing." % [str(d.get("w", "")), int(d.get("hz", 0)),
						int(d.get("q", 0)), str(d.get("w", ""))]
				"shift_and":
					return "De bel ging op %d, maar daar eindigt geen %s." % [int(d.get("end", 0)), _q(d.get("z", ""))]
				"edit":
					return "Dat stuk lint heeft afstand %d, niet de kleinste %d." % [int(d.get("dist", 0)),
						int(d.get("best", 0))]
			return "Vals alarm: daar stond geen codewoord."
		V.WRONG_KEY:
			return "Kijk naar t[i] = %s onder de laatste letter, niet naar %s." % [_q(d.get("x", "")), _q(d.get("y", ""))]
		V.WRONG_CARDS:
			if int(d.get("p", -1)) < 0:
				return "V_H[%s] = %d: %s staat niet vóór positie %d." % [_q(d.get("x", "")), int(d.get("v", 0)),
					_q(d.get("x", "")), int(d.get("m1", 0))]
			return "V_H[%s] = %d: de laatste %s vóór positie %d staat op %d." % [_q(d.get("x", "")), int(d.get("v", 0)),
				_q(d.get("x", "")), int(d.get("m1", 0)), int(d.get("p", 0))]
		V.JUMP_LONG, V.JUMP_SHORT:
			return "V_H[%s] = %d: spring %d, niet %d." % [_q(d.get("x", "")), int(d.get("v", 0)), int(d.get("v", 0)),
				int(d.get("s", 0))]
		V.WRONG_HOLES:
			return "Kaart %s: gaten waar z[i] = %s, dus op rij %s." % [_q(d.get("x", "")), _q(d.get("x", "")),
				str(d.get("rows", ""))]
		V.NO_SHIFT:
			return "Eerst schuiven (bit i−1 → i, bovenste aan), dan AND."
		V.WRONG_CARD:
			return "t[%d] = %s: kaart %s." % [int(d.get("j", 0)), _q(d.get("x", "")), str(d.get("card", ""))]
		V.WRONG_WIRE:
			return "Een fout op j bouwt verder op M^%d van kolom j−1, geschoven." % maxi(0, int(d.get("l", 1)) - 1)
		V.WRONG_MIN:
			return "min(%d+%d, %d+1, %d+1) = %d, niet %d." % [int(d.get("a", 0)), int(d.get("c", 0)), int(d.get("b", 0)),
				int(d.get("d", 0)), int(d.get("v", 0)), int(d.get("x", 0))]
		V.WRONG_END:
			return "De kleinste waarde onderaan is %d, in kolom %s." % [int(d.get("v", 0)), str(d.get("cols", ""))]
		V.WRONG_PICK:
			return "Enkel M⁰ belde: daar is %s exact." % _q(d.get("z", ""))
		V.MISSED:
			return "%s @%d glipte erdoor: zie %s." % [_q(d.get("z", "")), int(d.get("start", 0)),
				str(d.get("cause", "de laatste zet"))]
		V.TEAR:
			return "Te lang gewacht: de lusbak liep vol, het lint scheurde."
		V.BUMP:
			return _bump_line(str(d.get("reason", "")), d)
	return ""


func _bump_line(reason: String, d: Dictionary) -> String:
	match reason:
		"no_mesh":
			if bool(d.get("mirror_zero", false)):
				return "Meteen mismatch: V[start+1] = start+1 = %d." % int(d.get("v", 0))
			return "Die tanden passen niet: wat je al las, moet blijven kloppen."
		"zero":
			return "Een sprong van 0 komt nergens: minstens 1."
		"hole":
			return "Dat vakje is leeg of verbrand: verschuif met de hand."
		"filled":
			return "Dat vakje is al geponst."
		"range":
			return "Daar kan de machine niet bij."
		"last_pos":
			return "De lus van vul_VH stopt bij |z|−2: de laatste letter krijgt geen stempel."
		"out_of_window":
			return "Het sleutelteken staat onder het sjabloon."
		"already":
			return "De hendel staat al onderaan: eerst een kaart."
		"no_w":
			return "Het gewicht w is nog niet geijkt."
		"not_now":
			return "Die hendel hoort niet bij deze stap."
		"no_current":
			return "Langs dat draadje loopt geen stroom: waarde ≠ buur + kost."
		"no_card":
			return "Die kaart bestaat niet."
		"no_alarm":
			return "Het alarmlampje brandt niet."
		"wrong_phase":
			return "Dat kan nu niet."
	return "Klem."


## Notasverwijzing bij een event (GDD §6.5).
func notes_ref(e: Dictionary) -> String:
	var v := int(e.get("verdict", V.OK))
	var d := _d(e)
	match v:
		V.SHIFT_LONG, V.PUNCH_LONG:
			return "Definitie 11 · notas p. 56"
		V.PUNCH_SHORT:
			return "Algoritme 5 · notas p. 61"
		V.LATE, V.NO_SHIFT, V.WRONG_CARD:
			return "Algoritme 6 · notas p. 68"
		V.WRONG_HASH:
			return "rollende hash · notas p. 53"
		V.WRONG_HORNER:
			return "h(s) · notas p. 52"
		V.UNVERIFIED:
			return "Algoritme 3, valse treffers · notas p. 52–54"
		V.SKIPPED_CHECK:
			return "Algoritme 3 · notas p. 54"
		V.FALSE_ALARM:
			match str(d.get("machine", "")):
				"rk":
					return "Opmerking 10 · notas p. 54"
				"shift_and":
					return "Definitie 14 · notas p. 70"
				"edit":
					return "Algoritme 8 · notas p. 79"
			return ""
		V.WRONG_KEY:
			return "is_contained_BMH · notas p. 65"
		V.WRONG_CARDS:
			return "vul_VH · notas p. 65"
		V.JUMP_LONG, V.JUMP_SHORT:
			return "V_H · notas p. 65"
		V.WRONG_HOLES:
			return "C_x · notas p. 67"
		V.WRONG_WIRE:
			return "Definitie 14 · notas p. 71"
		V.WRONG_MIN:
			return "Algoritme 7 · notas p. 75"
		V.WRONG_END:
			return "Algoritme 8 · notas p. 79"
		V.WRONG_PICK:
			return "Definitie 14 · notas p. 70"
		V.MISSED:
			var c := entry(int(d.get("cause_seq", -1)))
			if not c.is_empty() and int(c.verdict) != V.MISSED:
				var r := notes_ref(c)
				if r != "":
					return r
			return "notas p. 50"
		V.TEAR:
			return "streams · notas p. 50"
		V.BUMP:
			match str(d.get("reason", "")):
				"no_mesh", "zero":
					return "Definitie 11 · notas p. 56"
				"last_pos":
					return "vul_VH · notas p. 65"
				"no_current":
					return "Algoritme 7 · notas p. 75"
			return ""
	return ""
