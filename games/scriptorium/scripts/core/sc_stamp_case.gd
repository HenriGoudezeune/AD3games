class_name ScStampCase extends ScTool
## Stempelkast (GDD §3.7): LZW, zenden en ontvangen (met het speciale geval van de lege lade).
## Zenden (fase DECIDE): {"act":"extend"} (klem no_stamp als wk niet in de kast zit) of {"act":"stamp"} (EARLY_STAMP
## als wk al in de kast zat: de else-tak, met een dubbele lade). Het eerste teken en de slotstempel gaan vanzelf.
## Ontvangen (fase CARVE): {"act":"carve","i":j}: nieuwe stempel = w + volgend[j] (gewoon) of, bij een lege lade,
## volgend = w + w[j] (speciaal geval). Correct is altijd j = 0. Bestaande laden openen vanzelf; een volgend woord van
## één letter wordt vanzelf gesneden.
## stage {"tool":"stampcase","side":"send","text":"banaanaanval"} · {"side":"receive","codes":[97,…],"expect":…}

var text: String = ""
var codes_in: Array[int] = []
var expect: String = ""
var entries: Array = []         # nieuwe laden [[code, word, dup]]
var next_code: int = ScCodes.LZW_FIRST
var w: String = ""
var i: int = 0                  # zenden: index van k
var out: Array[int] = []
var cpos: int = 0               # ontvangen: index van de code in behandeling
var volgend: String = ""
var special: bool = false
var copy_text: String = ""


func _setup() -> void:
	tool = ScCodes.Tool.STAMPCASE
	text = str(stage.get("text", ""))
	expect = str(stage.get("expect", ""))
	codes_in = []
	for c in stage.get("codes", []):
		codes_in.append(int(c) if not (c is String and not str(c).is_valid_int()) else str(c).unicode_at(0))
	entries = []
	next_code = ScCodes.LZW_FIRST
	w = ""
	i = 0
	out = []
	cpos = 0
	volgend = ""
	special = false
	copy_text = ""


## Code van een woord (laagste bij dubbele laden), −1 als het niet in de kast zit.
func code_of(word: String) -> int:
	if word.length() == 1:
		return word.unicode_at(0)
	for e in entries:
		if str(e[1]) == word:
			return int(e[0])
	return -1


func word_of(c: int) -> String:
	if c < ScCodes.LZW_FIRST:
		return char(c)
	for e in entries:
		if int(e[0]) == c:
			return str(e[1])
	return ""


func in_case(word: String) -> bool:
	return code_of(word) >= 0


func _begin() -> void:
	if side == ScCodes.Side.SEND:
		if text == "":
			_finish()
			return
		w = text[0]
		i = 1
		_fx.append({"fx": "zetstok", "w": w, "k": text[1] if i < text.length() else "", "in_case": true})
		_check_end()
	else:
		if codes_in.is_empty():
			_finish()
			return
		var c0 := codes_in[0]
		w = word_of(c0) if c0 < next_code else ""
		if w == "":
			_unreadable()
			return
		copy_text = w
		_copy_dirty = true
		_fx.append({"fx": "drawer", "code": c0, "word": w, "empty": false})
		cpos = 1
		_next_code()


func _k() -> String:
	return text[i] if i < text.length() else ""


func _check_end() -> void:
	if i >= text.length():
		var c := code_of(w)
		out.append(c)
		_add_ink(1)
		_auto("STAMP", {"w": w, "code": c, "final": true}, {"fx": "stamp", "code": c, "new_code": -1, "word": w,
			"dup": false})
		_finish()
	else:
		phase = P.DECIDE


## Ontvangen: de volgende code verwerken (lade openen) tot er een snijkeuze is.
func _next_code() -> void:
	while cpos < codes_in.size():
		var c := codes_in[cpos]
		if c < next_code and word_of(c) != "":
			volgend = word_of(c)
			special = false
			_fx.append({"fx": "drawer", "code": c, "word": volgend, "empty": false})
			if volgend.length() == 1:
				_carve_with(0)
				continue
			phase = P.CARVE
			return
		elif c == next_code:
			volgend = ""
			special = true
			_fx.append({"fx": "drawer", "code": c, "word": "", "empty": true})
			phase = P.CARVE
			return
		else:
			_unreadable()
			return
	_finish()


func _unreadable() -> void:
	copy_text += ScCodes.STUCK
	_copy_dirty = true
	_auto("UNREADABLE", {"cpos": cpos}, {"fx": "bump", "reason": "unreadable", "at": cpos})
	_finish()


## Snijden met letterkeuze j (gewoon: volgend[j]; speciaal: volgend = w + w[j]); daarna copy += volgend, w = volgend.
func _carve_with(j: int, is_auto := true) -> void:
	var c := codes_in[cpos]
	if special:
		volgend = w + w[j]
	var word := w + volgend[0] if special else w + volgend[j]
	entries.append([next_code, word, in_case(word)])
	_fx.append({"fx": "carve", "code": next_code, "word": word})
	if is_auto:
		_log("CARVE", {"code": next_code, "word": word, "c": c}, V.OK, true, {}, {}, true)
	next_code += 1
	copy_text += volgend
	_copy_dirty = true
	w = volgend
	volgend = ""
	special = false
	cpos += 1


# ------------------------------------------------------------------ beoordelen

func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	if side == ScCodes.Side.SEND:
		if phase != P.DECIDE:
			return {"ok": false, "reason": "wrong_phase"}
		var wk := w + _k()
		match act:
			"extend":
				if not in_case(wk):
					return {"ok": false, "reason": "no_stamp"}
				return {"ok": true, "verdict": V.OK, "type": "EXTEND", "data": {"wk": wk}}
			"stamp":
				return {"ok": true, "verdict": V.EARLY_STAMP if in_case(wk) else V.OK, "type": "STAMP",
					"data": {"wk": wk, "w": w, "code": code_of(w)}}
		return {"ok": false, "reason": "unknown_act"}
	if act != "carve":
		return {"ok": false, "reason": "unknown_act"}
	if phase != P.CARVE:
		return {"ok": false, "reason": "wrong_phase"}
	var j := int(move.get("i", -1))
	var lim := w.length() if special else volgend.length()
	if j < 0 or j >= lim:
		return {"ok": false, "reason": "range", "at": j}
	return {"ok": true, "verdict": V.OK if j == 0 else V.WRONG_CARVE, "type": "CARVE",
		"data": {"special": special, "c": codes_in[cpos], "w": w, "w0": w[0], "next": volgend, "j": j}}


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, j: Dictionary, e: Dictionary) -> void:
	var act := str(move.get("act", ""))
	if side == ScCodes.Side.RECEIVE:
		_carve_with(int(move.i), false)
		e.data["word"] = str(entries[entries.size() - 1][1])
		_next_code()
		return
	var k := _k()
	var wk := w + k
	if act == "extend":
		w = wk
		i += 1
		_fx.append({"fx": "zetstok", "w": w, "k": _k(), "in_case": in_case(w + _k()) if _k() != "" else false})
		_check_end()
		return
	var c := code_of(w)
	var dup := in_case(wk)
	out.append(c)
	_add_ink(1)
	entries.append([next_code, wk, dup])
	_fx.append({"fx": "stamp", "code": c, "new_code": next_code, "word": wk, "dup": dup})
	e.data["new_code"] = next_code
	next_code += 1
	w = k
	i += 1
	_fx.append({"fx": "zetstok", "w": w, "k": _k(), "in_case": in_case(w + _k()) if _k() != "" else false})
	_check_end()


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	if side == ScCodes.Side.SEND:
		if phase != P.DECIDE:
			return {"act": "none"}
		return {"act": "extend"} if in_case(w + _k()) else {"act": "stamp"}
	if phase != P.CARVE:
		return {"act": "none"}
	return {"act": "carve", "i": 0}


func _wrong() -> Array[Dictionary]:
	var out2: Array[Dictionary] = []
	if side == ScCodes.Side.SEND:
		if phase == P.DECIDE and in_case(w + _k()):
			out2.append({"act": "stamp"})
	elif phase == P.CARVE:
		var lim := w.length() if special else volgend.length()
		for j in range(1, lim):
			out2.append({"act": "carve", "i": j})
	return out2


func _impossible() -> Array[Dictionary]:
	var out2: Array[Dictionary] = []
	if side == ScCodes.Side.SEND:
		if phase == P.DECIDE and not in_case(w + _k()):
			out2.append({"act": "extend"})
		out2.append({"act": "carve", "i": 0})
	elif phase == P.CARVE:
		out2.append({"act": "carve", "i": w.length() if special else volgend.length()})
		out2.append({"act": "carve", "i": -1})
		out2.append({"act": "stamp"})
	return out2


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return i if side == ScCodes.Side.SEND else copy_text.length()


func copy() -> String:
	return copy_text if side == ScCodes.Side.RECEIVE else ""


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": copy_text}
	return {"kind": "codes", "codes": out.duplicate(), "ink": out.size()}


func words() -> Array:
	var r: Array = []
	for e in entries:
		r.append(str(e[1]))
	return r


func structure() -> Dictionary:
	return {"words": words(), "codes": out.duplicate()}


func _cursor() -> Dictionary:
	var en: Array = []
	for e in entries:
		en.append({"code": int(e[0]), "word": str(e[1]), "dup": bool(e[2])})
	var base: Array = []
	var seen := {}
	var src := text if side == ScCodes.Side.SEND else (expect if expect != "" else copy_text)
	for ch in src:
		if not seen.has(ch) and ch != "…":
			seen[ch] = true
			base.append({"code": ch.unicode_at(0), "word": ch})
	base.sort_custom(func(a, b) -> bool: return int(a.code) < int(b.code))
	return {"w": w, "k": _k() if side == ScCodes.Side.SEND else "", "i": i, "entries_new": en, "base": base,
		"out": out.duplicate(), "codes": codes_in.duplicate(), "cpos": cpos, "volgend": volgend, "special": special,
		"copy": copy_text, "next_code": next_code, "side": side,
		"in_case": in_case(w + _k()) if side == ScCodes.Side.SEND and _k() != "" else false}


func _snap() -> Dictionary:
	return {"entries": entries.duplicate(true), "next_code": next_code, "w": w, "i": i, "out": out.duplicate(),
		"cpos": cpos, "volgend": volgend, "special": special, "copy": copy_text}


func _restore(d: Dictionary) -> void:
	entries = []
	for e in d.get("entries", []):
		entries.append([int(e[0]), str(e[1]), bool(e[2])])
	next_code = int(d.get("next_code", ScCodes.LZW_FIRST))
	w = str(d.get("w", ""))
	i = int(d.get("i", 0))
	out = ints(d.get("out", []))
	cpos = int(d.get("cpos", 0))
	volgend = str(d.get("volgend", ""))
	special = bool(d.get("special", false))
	copy_text = str(d.get("copy", ""))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for q in entries.size():
		if int(entries[q][0]) != ScCodes.LZW_FIRST + q:
			e.append("lade %d heeft nummer %d" % [q, int(entries[q][0])])
	if side == ScCodes.Side.RECEIVE:
		for c in codes_in:
			if c > ScCodes.LZW_FIRST + codes_in.size():
				e.append("code %d kan nooit bestaan" % c)
	elif out.size() != int(counters.ink):
		e.append("inkt ≠ aantal stempels")
	return e
