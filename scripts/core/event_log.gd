class_name EventLog extends RefCounted
## Chronologische log van alle events van een dag (voor dagrapport, herbeleving, oorzaakketens).
## entry = {seq, t, type, data, verdict, hint, before}
##   hint   = correct_move() vóór de actie ({} als niet van toepassing)
##   before = snapshot() vóór de actie; enkel bij verdict != OK en bij DOUBLE / SPLIT_BEGIN, anders {}
## Types: SPAWN DROP BLOCK DOUBLE DOUBLE_REFUSED SPLIT_BEGIN SPLIT_REFUSED ASSIGN SPLIT_END RETRY LOOKUP
##        LOST DUMP CUSTOMER_IN CUSTOMER_OK CUSTOMER_ANGRY DAY_END

const OK := 0  # == ExtHashModel.Verdict.OK

var entries: Array[Dictionary] = []
var now: float = 0.0  # tijdstempel voor de volgende add(); het model zet dit
var n: int = 5        # aantal bits (voor coach_line)


func add(type: String, data: Dictionary, verdict: int, hint: Dictionary, before: Dictionary) -> Dictionary:
	var e := {
		"seq": entries.size(),
		"t": now,
		"type": type,
		"data": data,
		"verdict": verdict,
		"hint": hint,
		"before": before,
	}
	entries.append(e)
	return e


func clear() -> void:
	entries.clear()


## Alle entries met verdict != OK (behalve als data.excused: de juiste actie faalde zelf, bv. a == n).
func mistakes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if int(e.verdict) != OK and not bool(e.data.get("excused", false)):
			out.append(e)
	return out


func of_type(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries:
		if e.type == type:
			out.append(e)
	return out


## Het event waar dit pakje verdwaalde (fout luik, verkeerde kant), of {}.
func cause_of(parcel_id: int) -> Dictionary:
	for e in entries:
		if int(e.verdict) == OK:
			continue
		if (e.type == "DROP" or e.type == "ASSIGN") and int(e.data.get("parcel_id", -1)) == parcel_id:
			return e
	return {}


## Zelfde als cause_of, maar op hashwaarde (eerste verdwaalde pakje met die hv), of {}.
func cause_of_hv(hv: int) -> Dictionary:
	for e in entries:
		if int(e.verdict) == OK:
			continue
		if (e.type == "DROP" or e.type == "ASSIGN") and int(e.data.get("hv", -1)) == hv:
			return e
	return {}


func _b(x: int, w: int) -> String:
	return "`" + HashUtil.bits(x, w) + "`"


## Eén zin van de depotchef (max. ~12 woorden), uit data + hint. "" als er niets te zeggen valt.
func coach_line(entry: Dictionary) -> String:
	var d: Dictionary = entry.get("data", {})
	var h: Dictionary = entry.get("hint", {})
	var v := int(entry.get("verdict", OK))
	var nn := int(d.get("n", n))
	match entry.get("type", ""):
		"DROP":
			var hv := int(d.get("hv", 0))
			var a := int(d.get("a", 0))
			if v != OK:
				return "%s begint met %s. Luik %s, niet %s." % [_b(hv, nn), _b(int(d.correct_index), a), _b(int(d.correct_index), a), _b(int(d.dir_index), a)]
			if int(d.get("status", 0)) == 1:
				return "Rek vol. Tel de buizen: één → hendel, meer → zaag."
			return "%s begint met %s. Juist luik." % [_b(hv, nn), _b(int(d.dir_index), a)]
		"DOUBLE":
			if v == OK:
				return "Eén buis naar het volle rek → hendel. Goed."
			if h.get("action", "") == "split":
				var span := int(h.get("span", 2))
				if span == 2:
					return "Twee buizen naar dit rek → zagen volstond. Hendel was niet nodig."
				return "%d buizen naar dit rek → zagen volstond. Hendel was niet nodig." % span
			if h.get("action", "") == "assign":
				return "Eerst de pakjes verdelen. Hendel was niet nodig."
			if h.get("action", "") == "dump":
				return "Een kloon te veel → overloopbak, niet de hendel."
			return "Niets zat vast. De hendel was niet nodig."
		"DOUBLE_REFUSED":
			return "Geen bits meer. Dit lost hendel noch zaag op."
		"SPLIT_REFUSED":
			return "Eén buis kun je niet zagen. Eerst de hendel."
		"SPLIT_BEGIN":
			if v == OK:
				if bool(d.get("left_empty", false)):
					return "Rek bleef leeg en het pakje zat nog vast → nog eens de hendel."
				return "Meerdere buizen naar het volle rek → zagen. Goed."
			if h.get("action", "") == "double":
				return "Dit rek zat niet vast. Het volle rek had één buis: hendel."
			return "Hier zat niets vast. Zagen kostte drie ritten."
		"ASSIGN":
			var hv2 := int(d.get("hv", 0))
			var pos := int(d.get("bit_pos", 1))
			var cs := int(d.get("correct_side", 0))
			if v != OK:
				return "Bit %d van %s is `%d` → %s." % [pos, _b(hv2, nn), cs, "rechts, naar het nieuwe rek" if cs == 1 else "links, in het oude rek"]
			return "Bit %d van %s is `%d`. Juist." % [pos, _b(hv2, nn), cs]
		"RETRY":
			if not bool(d.get("placed", false)):
				return "Rek bleef leeg en het pakje zat nog vast → nog eens de hendel." if int(d.get("ab", 0)) == int(d.get("a", -1)) else "Pakje zit nog vast. Kijk opnieuw naar de buizen."
			return ""
		"LOOKUP":
			var w := int(d.get("wanted_hv", 0))
			var a2 := int(d.get("a", 0))
			if v != OK:
				return "%s begint met %s. Luik %s, niet %s." % [_b(w, nn), _b(int(d.correct_index), a2), _b(int(d.correct_index), a2), _b(int(d.dir_index), a2)]
			if not bool(d.get("found", false)):
				return "Juist luik, maar het pakje was eerder verdwaald."
			return ""
		"LOST":
			match d.get("reason", ""):
				"belt":
					return "Pakje viel van de band. Sneller sorteren."
				"burst":
					if bool(d.get("excused", false)):
						return "Geen bits meer: identieke pakjes passen nooit in één rek."
					return "Het pakje zat te lang vast. Hendel of zaag, op tijd."
				"dump_healthy":
					return "%s was geen kloon. Dat pakje mocht in het rek." % _b(int(d.get("hv", 0)), nn)
			return "Pakje kwijt."
		"DUMP":
			if v != OK:
				return "%s was geen kloon. Dat pakje mocht in het rek." % _b(int(d.get("hv", 0)), nn)
			return "Te veel identieke pakjes → overloopbak. Goed gezien."
		"CUSTOMER_ANGRY":
			return "Klant wachtte te lang voor %s." % _b(int(d.get("hv", 0)), nn)
	return ""
