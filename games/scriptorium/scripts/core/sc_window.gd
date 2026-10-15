class_name ScWindow extends ScTool
## Leesraam (GDD §3.6): LZ77, Algoritme 14, zenden en ontvangen, met optioneel register (§4.3.1).
## Zenden (fase PICK): {"act":"start","p":p} (raampositie, vanaf 0 links) of {"act":"literal"} (geen match → (0,0,x));
## met register ook {"act":"register"} (wandeling, telt zoekwerk). De match begint in het raam maar mag erbuiten lopen.
## Ontvangen (fase PICK): {"act":"start","p":p} voor elk zegel met l > 0; zegels met l = 0 gaan automatisch.
## stage {"tool":"window","side":"send","text":"banaan-baan","G":6,"register":false}   (G = −1: oneindig)
##       {"tool":"window","side":"receive","triples":[[0,0,"a"],…],"G":6,"expect":"aanvaardbaar"}

var G: int = -1
var text: String = ""
var register: bool = false
var k: int = 0
var triples: Array = []         # zenden: uitvoer; ontvangen: invoer
var written: String = ""        # ontvangen: de kopie
var idx: int = 0                # ontvangen: index van het zegel in behandeling
var reg_used: bool = false
var reg_walk: Dictionary = {}
var expect: String = ""


func _setup() -> void:
	tool = ScCodes.Tool.WINDOW
	G = int(stage.get("G", -1))
	text = str(stage.get("text", ""))
	register = bool(stage.get("register", false))
	expect = str(stage.get("expect", ""))
	k = 0
	idx = 0
	written = ""
	reg_used = false
	reg_walk = {}
	triples = []
	if side == ScCodes.Side.RECEIVE:
		for tr in stage.get("triples", []):
			triples.append([int(tr[0]), int(tr[1]), str(tr[2])])


func _begin() -> void:
	phase = P.PICK
	if side == ScCodes.Side.SEND:
		if text == "":
			_finish()
	else:
		_auto_literals()


func ws() -> int:
	return ScReference.window_start(k if side == ScCodes.Side.SEND else written.length(), G)


func window() -> String:
	if side == ScCodes.Side.SEND:
		return text.substr(ws(), k - ws())
	return written.substr(ws())


# ------------------------------------------------------------------ beoordelen

func _judge(move: Dictionary) -> Dictionary:
	if phase != P.PICK:
		return {"ok": false, "reason": "wrong_phase"}
	var act := str(move.get("act", ""))
	if side == ScCodes.Side.RECEIVE:
		if act != "start":
			return {"ok": false, "reason": "unknown_act"}
		var p := int(move.get("p", -1))
		if p < 0 or p >= window().length():
			return {"ok": false, "reason": "out_of_window", "at": p}
		var tr: Array = triples[idx]
		return {"ok": true, "verdict": V.OK if p == int(tr[0]) else V.WRONG_POS, "type": "START",
			"data": {"p": int(tr[0]), "chosen": p, "triple": tr.duplicate()}}
	var b := ScReference.lz77_best(text, k, G)
	var best := int(b.best)
	var alts: Array = b.alts
	match act:
		"start":
			var p2 := int(move.get("p", -1))
			if p2 < 0 or p2 >= k - ws():
				return {"ok": false, "reason": "out_of_window", "at": p2}
			if text[ws() + p2] != text[k]:
				return {"ok": false, "reason": "no_match", "at": p2}
			var l := ScReference.match_len(text, ws() + p2, k)
			return {"ok": true, "verdict": V.OK if l == best else V.SHORT_MATCH, "type": "START",
				"data": {"p": int(alts[0]) if not alts.is_empty() else 0, "l": best, "l2": l, "chosen": p2}}
		"literal":
			return {"ok": true, "verdict": V.OK if best == 0 else V.SHORT_MATCH, "type": "LITERAL",
				"data": {"p": int(alts[0]) if not alts.is_empty() else 0, "l": best, "l2": 0}}
		"register":
			if not register:
				return {"ok": false, "reason": "unknown_act"}
			return {"ok": true, "verdict": V.OK, "type": "REGISTER", "decision": false, "data": {}}
	return {"ok": false, "reason": "unknown_act"}


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, j: Dictionary, e: Dictionary) -> void:
	var act := str(move.get("act", ""))
	if side == ScCodes.Side.RECEIVE:
		_copy_triple(int(move.p))
		idx += 1
		_auto_literals()
		return
	if act == "register":
		reg_walk = ScRegister.walk(text, k, ws())
		_fx.append({"fx": "register_walk", "steps": reg_walk.steps, "p": int(reg_walk.p), "l": int(reg_walk.l)})
		if not reg_used:
			counters.search = int(counters.search) + int(reg_walk.cost)
		reg_used = true
		e.data["p"] = int(reg_walk.p)
		e.data["l"] = int(reg_walk.l)
		return
	if not reg_used:
		counters.search = int(counters.search) + ScReference.lz77_scan_cost(text, k, G)
	var p := 0
	var l := 0
	if act == "start":
		p = int(move.p)
		l = ScReference.match_len(text, ws() + p, k)
		var src := ws() + p
		var steps: Array = []
		var overlap := -1
		for q in l:
			steps.append(src + q)
			if overlap < 0 and src + q >= k:
				overlap = q
		_fx.append({"fx": "thread", "from": src, "to": k, "steps": steps, "overlap_from": overlap})
	var x: String = text[k + l] if k + l < text.length() else ScCodes.EOF
	var tr := [p, l, x]
	triples.append(tr)
	e.data["triple"] = tr.duplicate()
	_add_ink(1)
	_fx.append({"fx": "seal", "triple": tr.duplicate()})
	k += l + 1
	reg_used = false
	reg_walk = {}
	_fx.append({"fx": "slide", "ws": ws()})
	if k >= text.length():
		_finish()


func _copy_triple(p: int) -> void:
	var tr: Array = triples[idx]
	var l := int(tr[1])
	var start := ws() + p
	var src: Array = []
	var letters := ""
	for q in l:
		src.append(start + q)
		var c := written[start + q]
		written += c
		letters += c
	if str(tr[2]) != ScCodes.EOF:
		written += str(tr[2])
	_copy_dirty = true
	if l > 0:
		_fx.append({"fx": "copy_letters", "src": src, "letters": letters})
	_fx.append({"fx": "seal", "triple": tr.duplicate()})
	_fx.append({"fx": "slide", "ws": ws()})


## Ontvangen: zegels met l = 0 automatisch; klaar na het laatste zegel.
func _auto_literals() -> void:
	while idx < triples.size() and int(triples[idx][1]) == 0:
		_copy_triple(0)
		_log("START", {"triple": (triples[idx] as Array).duplicate(), "p": 0}, V.OK, true, {}, {}, true)
		idx += 1
	if idx >= triples.size():
		_finish()


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	if phase != P.PICK:
		return {"act": "none"}
	if side == ScCodes.Side.RECEIVE:
		return {"act": "start", "p": int(triples[idx][0])}
	if register and not reg_used:
		return {"act": "register"}
	var b := ScReference.lz77_best(text, k, G)
	if int(b.best) == 0:
		return {"act": "literal"}
	return {"act": "start", "p": int((b.alts as Array)[0])}


func best_alts() -> Array:
	if side == ScCodes.Side.SEND and phase == P.PICK:
		return Array(ScReference.lz77_best(text, k, G).alts)
	return []


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase != P.PICK:
		return out
	if side == ScCodes.Side.RECEIVE:
		for p in window().length():
			if p != int(triples[idx][0]):
				out.append({"act": "start", "p": p})
		return out
	var b := ScReference.lz77_best(text, k, G)
	if int(b.best) > 0:
		out.append({"act": "literal"})
	for p in k - ws():
		if text[ws() + p] == text[k] and ScReference.match_len(text, ws() + p, k) < int(b.best):
			out.append({"act": "start", "p": p})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase != P.PICK:
		return out
	out.append({"act": "start", "p": window().length()})
	out.append({"act": "start", "p": -1})
	if side == ScCodes.Side.SEND:
		for p in k - ws():
			if text[ws() + p] != text[k]:
				out.append({"act": "start", "p": p})
		if not register:
			out.append({"act": "register"})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return k if side == ScCodes.Side.SEND else written.length()


func copy() -> String:
	return written if side == ScCodes.Side.RECEIVE else ""


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": written}
	return {"kind": "triples", "triples": triples.duplicate(true), "G": G, "ink": triples.size()}


func structure() -> Dictionary:
	return {"triples": triples.duplicate(true)} if side == ScCodes.Side.SEND else {"copy": written}


func _cursor() -> Dictionary:
	var c := {"k": _at(), "ws": ws(), "window": window(), "triples": triples.duplicate(true), "G": G, "side": side,
		"register": register, "reg_walk": reg_walk.duplicate(true)}
	if side == ScCodes.Side.SEND:
		c["rest"] = text.substr(k)
		c["written"] = text.substr(0, k)
	else:
		c["triple"] = (triples[idx] as Array).duplicate() if idx < triples.size() else []
		c["idx"] = idx
		c["written"] = written
		c["copy"] = written
	return c


func _snap() -> Dictionary:
	return {"k": k, "triples": triples.duplicate(true), "written": written, "idx": idx, "reg_used": reg_used,
		"reg_walk": reg_walk.duplicate(true)}


func _restore(d: Dictionary) -> void:
	k = int(d.get("k", 0))
	triples = []
	for tr in d.get("triples", []):
		triples.append([int(tr[0]), int(tr[1]), str(tr[2])])
	written = str(d.get("written", ""))
	idx = int(d.get("idx", 0))
	reg_used = bool(d.get("reg_used", false))
	reg_walk = d.get("reg_walk", {})


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if side == ScCodes.Side.SEND:
		var dec := ScReference.lz77_decode(triples, G)
		if dec != text.substr(0, k):
			e.append("zegels lezen %s, niet %s" % [dec, text.substr(0, k)])
		if triples.size() != int(counters.ink):
			e.append("inkt ≠ aantal zegels")
	return e
