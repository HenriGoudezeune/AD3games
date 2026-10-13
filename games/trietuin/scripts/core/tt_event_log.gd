class_name TtEventLog extends RefCounted
## Chronologische log van een level (terugblik, herbeleving, oorzaakketens; GDD §8.10, §6.5).
## entry = {seq, t, card, type, data, verdict, ok, hint, before}
##   ok     = false bij een fysieke weigering ("klonk"); de staat veranderde niet
##   hint   = correct_move() vóór de zet ({} als niet van toepassing)
##   before = snapshot() vóór de zet; enkel bij verdict != OK en bij de eerste zet van elke kaart, anders {}
##   data.affects = woorden waarvan de vrucht door dit event misplaatst/gestolen/weggeknipt/weggewaaid werd
## Types: CARD_START MOVE SPLIT SAME ANSWER CUT READ SHORT PICK PRUNE PRUNE_DONE GO PLACE ATTACH LABEL LOCATE ABSENT
##        WHERE COUNT PICKSET OWNER BED ITERATION HOP RULE LINK FOLLOW BUMP HINT REWIND CARD_END EXPIRE BLOOM LEVEL_END

const V := TtCodes.Verdict

var entries: Array[Dictionary] = []
var now: float = 0.0   # tijdstempel voor de volgende add(); het model/de director zet dit


func add(type: String, data: Dictionary, verdict: int, hint: Dictionary, before: Dictionary, card_id: int = -1,
		ok: bool = true) -> Dictionary:
	var e := {
		"seq": entries.size(),
		"t": now,
		"card": card_id,
		"type": type,
		"data": data,
		"verdict": verdict,
		"ok": ok,
		"hint": hint,
		"before": before,
	}
	entries.append(e)
	return e


func clear() -> void:
	entries.clear()


## Misstappen: verdict != OK. Fysieke weigeringen (ok = false) tellen enkel als count_bumps (Ukkonen-levels).
func mistakes(count_bumps := false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if int(e.verdict) == V.OK:
			continue
		if not bool(e.get("ok", true)) and not count_bumps:
			continue
		if int(e.verdict) == V.BUMP and not count_bumps:
			continue
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


## Het (laatste) event waar de vrucht van dit woord misplaatst/gestolen/weggeknipt/weggewaaid werd, of {}.
func cause_of_word(word: String) -> Dictionary:
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		var aff = e.data.get("affects", [])
		if aff is Array or aff is PackedStringArray:
			for w in aff:
				if str(w) == word:
					return e
	return {}


static func _q(s) -> String:
	return "`" + str(s) + "`"


## Eén coachzin (≤ 16 woorden), uit data + hint. "" als er niets te zeggen valt (GDD §6.5).
func coach_line(entry: Dictionary) -> String:
	var d: Dictionary = entry.get("data", {})
	var v := int(entry.get("verdict", V.OK))
	match v:
		V.WRONG_LETTER:
			return "Op diepte %d lees je letter %d: %s. Knop %s, niet %s." % [int(d.get("d", 0)), int(d.get("d", 0)),
				_q(d.get("c", "")), str(d.get("c", "")), str(d.get("x", ""))]
		V.WRONG_KNOP:
			return "Lege knop? De vrucht hoort aan knop %s = s_%d." % [_q(d.get("c", "")), int(d.get("d", 0))]
		V.J_LATE:
			return "%s en %s verschillen al op positie %d, niet pas op %d." % [_q(d.get("l", "")), _q(d.get("s", "")),
				int(d.get("j", 0)), int(d.get("x", 0))]
		V.WRONG_SAME:
			return "%s ≠ %s: vergelijk het hele woord." % [_q(d.get("l", "")), _q(d.get("s", ""))]
		V.WRONG_ANSWER:
			if bool(d.get("found", false)):
				return "Een vrucht bereiken is niet vinden: %s ≠ %s." % [_q(d.get("l", "")), _q(d.get("s", ""))]
			return "%s hing hier wel: label = gezochte string." % _q(d.get("s", ""))
		V.CUT_TOO_HIGH:
			return "Knip net onder %s: de laatste top met twee kinderen." % _q(_u(d.get("u", "")))
		V.CUT_TOO_LOW:
			return "Alles na %s mag weg; er bleef dood hout." % _q(_u(d.get("u", "")))
		V.WRONG_POS:
			return "skip = %d: sla %d letters over en lees positie %d." % [int(d.get("k", 0)), int(d.get("k", 0)),
				int(d.get("p", 0))]
		V.WRONG_SHORT:
			return "next + skip = %d ≤ m = %d: het lint is lang genoeg." % [int(d.get("a", 0)), int(d.get("m", 0))]
		V.UNPRUNED:
			return "Top %s had maar één kind: die mocht weg." % _q(_u(d.get("u", "")))
		V.WRONG_DIR:
			return "%s %s %s → %s." % [_q(d.get("c", "")), str(d.get("rel", "?")), _q(d.get("k", "")),
				str(d.get("dir_name", ""))]
		V.WRONG_POINT:
			return "%s volgt de boom tot %s en wijkt daar pas af." % [_q(d.get("sigma", "")), _q(_u(d.get("u", "")))]
		V.WRONG_B:
			return "Nieuwe boog vanuit diepte %d: b = %d + %d = %d." % [int(d.get("l", 0)), int(d.get("j", 0)),
				int(d.get("l", 0)), int(d.get("b", 0))]
		V.WRONG_WHERE:
			return "Boog (%d,%d) vanuit diepte %d: positie = %d − %d = %d." % [int(d.get("b", 0)), int(d.get("e", 0)),
				int(d.get("l", 0)), int(d.get("b", 0)), int(d.get("l", 0)), int(d.get("p", 0))]
		V.WRONG_COUNT, V.WRONG_PICK:
			return "Onder het punt hangen %d vruchten: zoveel voorkomens." % int(d.get("n", 0))
		V.WRONG_ABSENT:
			if bool(d.get("present", false)):
				return "%s loopt tot het einde door: het komt voor." % _q(d.get("z", ""))
			return "Na %s volgt %s, niet %s." % [_q(_u(d.get("u", ""))), _q(d.get("x", "niets")), _q(d.get("c", ""))]
		V.WRONG_OWNER:
			return "De kleuren onder het punt: %s." % str(d.get("names", ""))
		V.WRONG_BED:
			return "|A| = %d, %s kinderen gemiddeld: %d pointers vs. %d." % [int(d.get("a", 0)), str(d.get("k", "2")),
				int(d.get("pa", 0)), int(d.get("pt", 0))]
		V.WRONG_RULE:
			if bool(d.get("grow", false)):
				return "%s zit er al in: stop de iteratie, x + 1." % _q(str(d.get("sigma", "")) + str(d.get("c", "")))
			return "Na %s komt in de boom %s, niet %s: uitbreiden (%s)." % [_q(_u(d.get("sigma", ""))),
				_q(d.get("x", "niets")), _q(d.get("c", "")), str(d.get("r", ""))]
		V.WRONG_HOP:
			var ge := int(d.get("x", 0)) >= int(d.get("L", 0))
			return "x̄ = %d %s lengte %d: %s." % [int(d.get("x", 0)), "≥" if ge else "<", int(d.get("L", 0)),
				"spring" if ge else "blijf"]
		V.WRONG_LINK:
			return "%s linkt naar %s: zonder de eerste letter." % [_q(_u(d.get("u", ""))), _q(_u(d.get("u2", "")))]
		V.WRONG_FOLLOW:
			return "p = wortel → x − 1; anders volg je de link en blijft x."
		V.LOST:
			return "Dit zaadje waaide weg: %s." % str(d.get("why", "te lang gewacht"))
		V.TIMEOUT:
			return "De bij wachtte te lang en vloog boos weg."
	return ""


## Lege string = wortel (∅).
static func _u(s) -> String:
	var x := str(s)
	return "∅" if x == "" else x


## Notasverwijzing bij een event (GDD §6.5).
func notes_ref(entry: Dictionary) -> String:
	var v := int(entry.get("verdict", V.OK))
	var d: Dictionary = entry.get("data", {})
	match v:
		V.WRONG_LETTER:
			return "notas p. 27 · opzoeken"
		V.WRONG_KNOP:
			return "notas p. 27 · toevoegen"
		V.J_LATE:
			return "notas p. 27 · j = min{i ≥ d | l_i ≠ s_i}"
		V.WRONG_SAME:
			return "notas p. 27 · toevoegen"
		V.WRONG_ANSWER:
			if bool(d.get("found", false)):
				return "notas p. 27 · Algoritme 1, p. 29"
			return "notas p. 27 · opzoeken"
		V.CUT_TOO_HIGH, V.CUT_TOO_LOW:
			return "notas p. 27 · verwijderen"
		V.WRONG_POS, V.WRONG_SHORT:
			return "notas p. 29 · Algoritme 1"
		V.UNPRUNED:
			return "notas p. 28–29 · Patricia"
		V.WRONG_DIR:
			return "notas p. 31 · ternary tries"
		V.WRONG_POINT:
			return "notas p. 33 · suffixbomen"
		V.WRONG_B, V.WRONG_WHERE:
			return "notas p. 48 · b − l_t"
		V.WRONG_COUNT, V.WRONG_PICK:
			return "notas p. 49 · Oef. 28–29"
		V.WRONG_ABSENT:
			return "notas p. 48 · zoeken in O(m)"
		V.WRONG_OWNER:
			return "notas p. 49 · veralgemeende suffixboom"
		V.WRONG_BED:
			return "notas p. 32 · Oef. 20"
		V.WRONG_RULE:
			return "notas p. 39 · (a)/(b): stop" if bool(d.get("grow", false)) else "notas p. 38 · regels (ii)/(iii)"
		V.WRONG_HOP:
			return "notas p. 41–42 · springen"
		V.WRONG_LINK:
			return "notas p. 40, 43 · suffix links"
		V.WRONG_FOLLOW:
			return "notas p. 41 · volgende wijzer"
	return ""
