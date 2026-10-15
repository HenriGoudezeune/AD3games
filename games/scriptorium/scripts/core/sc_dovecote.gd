class_name ScDovecote extends ScTool
## Duiventil (GDD §3.10, P1): geen algoritme comprimeert alles (Oef. 76/77). 2^b duiven (alle berichten van b bits),
## korte hokken = alle bitstrings korter dan b (2^b − 1 stuks, ε inbegrepen), zolder = de hokken van b + 1 bits.
## Fase ROOST: {"act":"roost","pigeon":m,"hole":h} (klem taken, not_shorter, range). Fase DECREE:
## {"act":"decree","which":1|2,"answer":"impossible"|"true"|"false"} (WRONG_DECREE). Juist: 1 → impossible, 2 → true.

const ANSWERS := {1: "impossible", 2: "true"}

var bits: int = 3
var pigeons: Array[String] = []
var short_holes: Array[String] = []
var attic: Array[String] = []
var roost: Dictionary = {}      # pigeon index (str) → hole
var decrees: Dictionary = {}    # "1"/"2" → answer


func _setup() -> void:
	tool = ScCodes.Tool.DOVECOTE
	bits = int(stage.get("bits", 3))
	pigeons = _all(bits)
	short_holes = []
	for l in bits:
		short_holes.append_array(_all(l))
	attic = _all(bits + 1)
	roost = {}
	decrees = {}


static func _all(l: int) -> Array[String]:
	var out: Array[String] = []
	if l == 0:
		out.append("")
		return out
	for v in 1 << l:
		var s := ""
		for q in range(l - 1, -1, -1):
			s += "1" if (v >> q) & 1 else "0"
		out.append(s)
	return out


func _begin() -> void:
	phase = P.ROOST


func _taken(h: String) -> bool:
	for k in roost:
		if str(roost[k]) == h:
			return true
	return false


func _free_short() -> String:
	for h in short_holes:
		if not _taken(h):
			return h
	return "#none"


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"roost":
			if phase != P.ROOST:
				return {"ok": false, "reason": "wrong_phase"}
			var m := int(move.get("pigeon", -1))
			var h := str(move.get("hole", "#"))
			if m < 0 or m >= pigeons.size() or roost.has(str(m)) or not (short_holes.has(h) or attic.has(h)):
				return {"ok": false, "reason": "range"}
			if _taken(h):
				return {"ok": false, "reason": "taken"}
			if attic.has(h) and _free_short() != "#none":
				return {"ok": false, "reason": "not_shorter"}
			return {"ok": true, "verdict": V.OK, "type": "ROOST", "data": {"pigeon": m, "hole": h}}
		"decree":
			if phase != P.DECREE:
				return {"ok": false, "reason": "wrong_phase"}
			var w := int(move.get("which", 0))
			var a := str(move.get("answer", ""))
			if not ANSWERS.has(w) or decrees.has(str(w)) or not a in ["impossible", "true", "false"]:
				return {"ok": false, "reason": "range"}
			return {"ok": true, "verdict": V.OK if a == ANSWERS[w] else V.WRONG_DECREE, "type": "DECREE",
				"data": {"which": w, "answer": a}}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, _j: Dictionary, _e: Dictionary) -> void:
	if str(move.act) == "roost":
		roost[str(int(move.pigeon))] = str(move.hole)
		_fx.append({"fx": "roost", "pigeon": int(move.pigeon), "hole": str(move.hole)})
		if roost.size() == pigeons.size():
			phase = P.DECREE
	else:
		decrees[str(int(move.which))] = str(move.answer)
		if decrees.size() == ANSWERS.size():
			_finish()


func _correct() -> Dictionary:
	if phase == P.ROOST:
		for m in pigeons.size():
			if not roost.has(str(m)):
				var h := _free_short()
				if h == "#none":
					for a in attic:
						if not _taken(a):
							h = a
							break
				return {"act": "roost", "pigeon": m, "hole": h}
	if phase == P.DECREE:
		for w in ANSWERS:
			if not decrees.has(str(w)):
				return {"act": "decree", "which": w, "answer": ANSWERS[w]}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase == P.DECREE:
		for w in ANSWERS:
			if not decrees.has(str(w)):
				for a in ["impossible", "true", "false"]:
					if a != ANSWERS[w]:
						out.append({"act": "decree", "which": w, "answer": a})
				break
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase == P.ROOST:
		var m := int(_correct().pigeon)
		if _free_short() != "#none":
			out.append({"act": "roost", "pigeon": m, "hole": attic[0]})
		for k in roost:
			out.append({"act": "roost", "pigeon": m, "hole": str(roost[k])})
			break
		out.append({"act": "roost", "pigeon": pigeons.size(), "hole": ""})
	return out


func decrees_ok() -> bool:
	for w in ANSWERS:
		if str(decrees.get(str(w), "")) != ANSWERS[w]:
			return false
	return true


func _output() -> Dictionary:
	return {"kind": "dovecote", "roost": roost.duplicate(), "decrees": decrees.duplicate()}


func structure() -> Dictionary:
	return {"roost": roost.duplicate(), "decrees": decrees.duplicate()}


func _cursor() -> Dictionary:
	return {"pigeons": Array(pigeons), "short_holes": Array(short_holes), "attic": Array(attic),
		"roost": roost.duplicate(), "decrees": decrees.duplicate(), "free_short": _free_short() != "#none"}


func _snap() -> Dictionary:
	return {"roost": roost.duplicate(), "decrees": decrees.duplicate()}


func _restore(d: Dictionary) -> void:
	roost = {}
	var r: Dictionary = d.get("roost", {})
	for k in r:
		roost[str(k)] = str(r[k])
	decrees = {}
	var dc: Dictionary = d.get("decrees", {})
	for k in dc:
		decrees[str(k)] = str(dc[k])


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	var seen := {}
	for k in roost:
		if seen.has(roost[k]):
			e.append("twee duiven in hok %s" % roost[k])
		seen[roost[k]] = true
	return e
