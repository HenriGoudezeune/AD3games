class_name ScCodeBoard extends ScTool
## Codebord (GDD §3.2). Twee modi:
##  mode "cuts"  (fase CUTS): de speler knipt een strook van een niet-prefixcode in codewoorden; elke volledige lezing
##               komt op de lijst. {"act":"cut","at":i} · {"act":"reset"} · {"act":"done"} (klem need_more).
##  mode "design" (fase DESIGN): letters aan knopen hangen (pad = codewoord, diepte ≤ max_depth) en verzenden.
##               {"act":"place","sym":x,"path":p} · {"act":"remove","sym":x} · {"act":"send"}.
## send: geen prefixcode → NOT_PREFIX (proeflezing, stage blijft open); prefix maar duurder dan optimaal → LONG_CODE
## (stage klaar); anders OK.

var mode: String = "cuts"
# cuts
var code: Dictionary = {}
var bits: String = ""
var need: int = 1
var intended: String = ""
var parses: Array = []          # [{text, cuts}]
var start: int = 0
var cuts: Array[int] = []
var readings: Array[String] = []
# design
var text: String = ""
var freqs: Array = []
var max_depth: int = 3
var placed: Dictionary = {}     # sym → path
var target: Dictionary = {}     # optimale code (ScReference.huffman)
var optimum: int = 0
var sent_bits: String = ""
var sent_code: Dictionary = {}
var trials: Array = []          # proeflezingen [{text, code}]


func _setup() -> void:
	tool = ScCodes.Tool.CODE_BOARD
	mode = str(stage.get("mode", "cuts"))
	if mode == "cuts":
		code = stage.get("code", {})
		bits = str(stage.get("bits", ""))
		need = int(stage.get("need", 1))
		intended = str(stage.get("intended", ""))
		parses = ScReference.all_parses_cuts(code, bits)
		start = 0
		cuts = []
		readings = []
	else:
		text = str(stage.get("text", ""))
		max_depth = int(stage.get("max_depth", 3))
		freqs = ScReference.freqs_in_order(text)
		var h := ScReference.huffman(freqs)
		target = h.codes
		optimum = int(h.cost)
		placed = {}
		sent_bits = ""
		sent_code = {}
		trials = []


func _begin() -> void:
	phase = P.CUTS if mode == "cuts" else P.DESIGN


func symbols() -> Array:
	var out: Array = []
	for f in freqs:
		out.append(str(f[0]))
	return out


# ------------------------------------------------------------------ beoordelen

func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	if mode == "cuts":
		match act:
			"cut":
				var i := int(move.get("at", -1))
				if i <= start or i > bits.length():
					return {"ok": false, "reason": "range", "at": i}
				var wd := bits.substr(start, i - start)
				if not ScReference.inverse(code).has(wd):
					return {"ok": false, "reason": "no_word", "at": i}
				return {"ok": true, "verdict": V.OK, "type": "CUT", "data": {"at": i, "word": wd}}
			"reset":
				return {"ok": true, "verdict": V.OK, "type": "RESET", "decision": false}
			"done":
				if readings.size() < need:
					return {"ok": false, "reason": "need_more"}
				return {"ok": true, "verdict": V.OK, "type": "DONE"}
		return {"ok": false, "reason": "unknown_act"}
	match act:
		"place":
			var s := str(move.get("sym", ""))
			var p := str(move.get("path", ""))
			if not symbols().has(s):
				return {"ok": false, "reason": "unknown"}
			if p.length() == 0 or p.length() > max_depth or not _is_bits(p):
				return {"ok": false, "reason": "range"}
			for k in placed:
				if k != s and str(placed[k]) == p:
					return {"ok": false, "reason": "taken"}
			return {"ok": true, "verdict": V.OK, "type": "PLACE", "data": {"sym": s, "path": p}, "decision": false}
		"remove":
			var s2 := str(move.get("sym", ""))
			if not placed.has(s2):
				return {"ok": false, "reason": "unknown"}
			return {"ok": true, "verdict": V.OK, "type": "REMOVE", "data": {"sym": s2}, "decision": false}
		"send":
			if placed.size() < symbols().size():
				return {"ok": false, "reason": "incomplete"}
			var pc := placed.duplicate()
			if not ScReference.is_prefix_code(pc):
				var ab := _prefix_pair(pc)
				return {"ok": true, "verdict": V.NOT_PREFIX, "type": "SEND", "data": {"a": ab[0], "b": ab[1]}}
			var cost := ScReference.code_cost(pc, freqs)
			if cost > optimum:
				var xy := _long_pair(pc)
				return {"ok": true, "verdict": V.LONG_CODE, "type": "SEND", "data": {"ink": cost, "opt": optimum,
					"x": xy[0], "ax": xy[1], "y": xy[2]}}
			return {"ok": true, "verdict": V.OK, "type": "SEND", "data": {"ink": cost}}
	return {"ok": false, "reason": "unknown_act"}


static func _is_bits(p: String) -> bool:
	for ch in p:
		if ch != "0" and ch != "1":
			return false
	return true


## Twee woorden waarvan het ene het begin van het andere is.
static func _prefix_pair(pc: Dictionary) -> Array:
	for a in pc:
		for b in pc:
			if a != b and str(pc[b]).begins_with(str(pc[a])):
				return [pc[a], pc[b]]
	return ["", ""]


## Een frequentere letter x met een langer woord dan een minder frequente y: [x, a(x), y].
func _long_pair(pc: Dictionary) -> Array:
	for fx in freqs:
		for fy in freqs:
			if int(fx[1]) > int(fy[1]) and str(pc[fx[0]]).length() > str(pc[fy[0]]).length():
				return [fx[0], int(fx[1]), fy[0]]
	for fx in freqs:
		if str(pc[fx[0]]).length() > str(target[fx[0]]).length():
			return [fx[0], int(fx[1]), fx[0]]
	return ["", 0, ""]


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, j: Dictionary, e: Dictionary) -> void:
	var act := str(move.get("act", ""))
	match act:
		"cut":
			var i := int(j.data.at)
			cuts.append(i)
			_fx.append({"fx": "cut", "at": i, "ch": str(ScReference.inverse(code)[str(j.data.word)])})
			start = i
			if start >= bits.length():
				var t := _current_text()
				var is_new := not readings.has(t)
				if is_new:
					readings.append(t)
				_fx.append({"fx": "reading_done", "text": t, "new": is_new})
				e.data["reading"] = t
				e.data["new"] = is_new
				start = 0
				cuts = []
		"reset":
			start = 0
			cuts = []
		"done":
			_fx.append({"fx": "reading_done", "text": ScReference.greedy_read(code, bits), "new": false, "demo": true})
			_finish()
		"place":
			var s := str(j.data.sym)
			_fx.append({"fx": "place", "sym": s, "path": str(j.data.path), "from": str(placed.get(s, ""))})
			placed[s] = str(j.data.path)
			counters.ink = ScReference.code_cost(placed, freqs)
		"remove":
			var s2 := str(j.data.sym)
			_fx.append({"fx": "place", "sym": s2, "path": "", "from": str(placed[s2])})
			placed.erase(s2)
			counters.ink = ScReference.code_cost(placed, freqs)
		"send":
			var pc := placed.duplicate()
			var b := ScReference.encode_with(pc, text)
			if int(j.verdict) == V.NOT_PREFIX:
				var rd := ScReference.greedy_read(pc, b)
				trials.append({"text": rd, "code": pc})
				e.data["read"] = rd
				_fx.append({"fx": "trial_read", "text": rd, "original": text, "marks": ScReader.compare(text, rd).marks})
			else:
				sent_bits = b
				sent_code = pc
				counters.ink = b.length()
				_out_dirty = true
				_fx.append({"fx": "write", "tokens": [{"b": b}]})
				_finish()


func _current_text() -> String:
	var inv := ScReference.inverse(code)
	var t := ""
	var s := 0
	for c in cuts:
		t += str(inv[bits.substr(s, c - s)])
		s = c
	return t


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	if mode == "cuts":
		var any_open := false
		for p in parses:
			if readings.has(str(p.text)):
				continue
			any_open = true
			var pc: Array = p.cuts
			if cuts.size() < pc.size():
				var okp := true
				for q in cuts.size():
					if int(pc[q]) != cuts[q]:
						okp = false
						break
				if okp:
					return {"act": "cut", "at": int(pc[cuts.size()])}
		if any_open or not cuts.is_empty():
			return {"act": "reset"}
		return {"act": "done"}
	for s in symbols():
		var tp := str(target[s])
		if str(placed.get(s, "")) == tp:
			continue
		for k in placed:
			if k != s and (str(placed[k]) == tp):
				return {"act": "remove", "sym": k}
		return {"act": "place", "sym": s, "path": tp}
	return {"act": "send"}


func _wrong() -> Array[Dictionary]:
	return []


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mode == "cuts":
		out.append({"act": "cut", "at": start})
		out.append({"act": "cut", "at": bits.length() + 1})
		for i in range(start + 1, bits.length() + 1):
			if not ScReference.inverse(code).has(bits.substr(start, i - start)):
				out.append({"act": "cut", "at": i})
		if readings.size() < need:
			out.append({"act": "done"})
	else:
		out.append({"act": "place", "sym": "#", "path": "0"})
		out.append({"act": "place", "sym": str(symbols()[0]), "path": "0".repeat(max_depth + 1)})
		if placed.size() < symbols().size():
			out.append({"act": "send"})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return 0


func _output() -> Dictionary:
	if mode == "cuts":
		return {"kind": "readings", "readings": readings.duplicate(), "bits": bits, "code": code}
	return {"kind": "bits", "bits": sent_bits, "code": sent_code, "ink": sent_bits.length()}


func structure() -> Dictionary:
	if mode == "cuts":
		return {"readings": readings.duplicate()}
	return {"code": sent_code if not sent_code.is_empty() else placed.duplicate()}


func all_readings() -> Array:
	var out: Array = []
	for p in parses:
		out.append(str(p.text))
	return out


func _cursor() -> Dictionary:
	if mode == "cuts":
		var parts: Array = []
		var s := 0
		for c in cuts:
			parts.append(bits.substr(s, c - s))
			s = c
		return {"mode": mode, "start": start, "parts": parts, "readings": readings.duplicate(), "total": parses.size(),
			"bits": bits, "need": need}
	var pc := placed.duplicate()
	return {"mode": mode, "placed": pc, "ink": ScReference.code_cost(pc, freqs),
		"prefix_ok": pc.size() == symbols().size() and ScReference.is_prefix_code(pc), "freqs": freqs,
		"max_depth": max_depth, "optimum": optimum}


func _snap() -> Dictionary:
	return {"start": start, "cuts": cuts.duplicate(), "readings": readings.duplicate(), "placed": placed.duplicate(),
		"sent_bits": sent_bits, "sent_code": sent_code.duplicate(), "trials": trials.duplicate(true)}


func _restore(d: Dictionary) -> void:
	start = int(d.get("start", 0))
	cuts = ints(d.get("cuts", []))
	readings = strs(d.get("readings", []))
	placed = {}
	var pd: Dictionary = d.get("placed", {})
	for k in pd:
		placed[str(k)] = str(pd[k])
	sent_bits = str(d.get("sent_bits", ""))
	sent_code = {}
	var sc: Dictionary = d.get("sent_code", {})
	for k in sc:
		sent_code[str(k)] = str(sc[k])
	trials = d.get("trials", [])


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if mode == "cuts":
		for r in readings:
			if not all_readings().has(r):
				e.append("lezing %s bestaat niet" % r)
	return e
