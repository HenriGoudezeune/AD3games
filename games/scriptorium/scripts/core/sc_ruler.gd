class_name ScRuler extends ScTool
## Meetlat + binaire naald (GDD §3.5): aritmetisch coderen, Algoritme 12/13, exact met ScDec.
## Zenden: fase CUT ({"act":"cut","sym":x}), daarna NEEDLE ({"act":"bit","b":1|0}). low = 0 → "0" automatisch.
## Ontvangen: fase CUT met een speld (bits of "pin"): het vak waarin de speld zit; op de open bovenrand → WRONG_EDGE.
## stage {"tool":"ruler","side":"send","model":[["x","0.2"],…],"text":"yy","auto_after":-1}
##       {"tool":"ruler","side":"receive","model":[…],"bits":"0010011","n":3,"expect":"act"} (of "pin":"0.9")

var model: Array = []
var text: String = ""
var n: int = 0
var auto_after: int = -1
var low: ScDec = ScDec.zero()
var lengte: ScDec = ScDec.one()
var i: int = 0
var book: Array = []            # [{i, sym, links, lengte}] (strings)
var getal: ScDec = ScDec.zero()
var nxt: ScDec = ScDec.one().half()
var bits: String = ""
var pin: ScDec = ScDec.zero()
var pin_src: String = ""
var copy_text: String = ""
var expect: String = ""


func _setup() -> void:
	tool = ScCodes.Tool.RULER
	model = stage.get("model", [])
	text = str(stage.get("text", ""))
	expect = str(stage.get("expect", ""))
	auto_after = int(stage.get("auto_after", -1))
	if side == ScCodes.Side.RECEIVE:
		n = int(stage.get("n", 0))
		if stage.has("pin"):
			pin_src = str(stage.pin)
			pin = ScDec.from_string(pin_src)
		else:
			pin_src = str(stage.get("bits", ""))
			pin = ScDec.from_bits(pin_src)
	else:
		n = text.length()
	low = ScDec.zero()
	lengte = ScDec.one()
	i = 0
	book = []
	getal = ScDec.zero()
	nxt = ScDec.one().half()
	bits = ""
	copy_text = ""


func up() -> ScDec:
	return low.add(lengte)


func _begin() -> void:
	phase = P.CUT
	if side == ScCodes.Side.RECEIVE:
		_fx.append({"fx": "pin", "value": pin.to_full_string()})
		if n <= 0:
			_finish()
	elif n == 0:
		_finish()
	elif auto_after == 0:
		_auto_cuts()


func segs() -> Array:
	return ScReference.segments(low, lengte, model)


func _seg(sym: String) -> Dictionary:
	for s in segs():
		if str(s.sym) == sym:
			return s
	return {}


## Ontvangen: het vak dat de speld bevat.
func _pin_seg() -> Dictionary:
	for s in segs():
		if (s.lo as ScDec).le(pin) and pin.lt(s.hi):
			return s
	return {}


# ------------------------------------------------------------------ beoordelen

func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"cut":
			if phase != P.CUT:
				return {"ok": false, "reason": "wrong_phase"}
			var sym := str(move.get("sym", ""))
			var sg := _seg(sym)
			if sg.is_empty():
				return {"ok": false, "reason": "unknown"}
			var lo: ScDec = sg.lo
			var hi: ScDec = sg.hi
			if side == ScCodes.Side.SEND:
				var want := text[i]
				var ws := _seg(want)
				return {"ok": true, "verdict": V.OK if sym == want else V.WRONG_SEGMENT, "type": "SEGMENT",
					"data": {"sym": sym, "x": want, "lo": (ws.lo as ScDec).to_string_sig(),
					"hi": (ws.hi as ScDec).to_string_sig()}}
			if pin.lt(lo) or pin.gt(hi):
				return {"ok": false, "reason": "no_pin"}
			if pin.eq(hi):
				var ps := _pin_seg()
				return {"ok": true, "verdict": V.WRONG_EDGE, "type": "SEGMENT",
					"data": {"sym": sym, "r": pin.to_string_sig(), "x": str(ps.get("sym", ""))}}
			return {"ok": true, "verdict": V.OK, "type": "SEGMENT", "data": {"sym": sym}}
		"bit":
			if phase != P.NEEDLE:
				return {"ok": false, "reason": "wrong_phase"}
			var b := int(move.get("b", -1))
			if b != 0 and b != 1:
				return {"ok": false, "reason": "range"}
			var u := up()
			var step := getal.add(nxt)
			var bstar := 1 if step.lt(u) else 0
			var data := {"b": b, "g": getal.to_string_sig(), "nx": nxt.to_string_sig(), "up": u.to_string_sig(),
				"low": low.to_string_sig()}
			var v := V.OK
			if b != bstar:
				if b == 1:
					v = V.OVERSHOOT
				elif step.gt(low):
					v = V.LONG_BITS
				else:
					v = V.UNREACHABLE
			return {"ok": true, "verdict": v, "type": "BIT", "data": data}
	return {"ok": false, "reason": "unknown_act"}


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	match str(move.get("act", "")):
		"cut":
			if side == ScCodes.Side.SEND:
				_cut(str(j.data.sym), false)
			else:
				var sym := str(j.data.sym)
				_zoom(sym, false)
				copy_text += sym
				_copy_dirty = true
				if int(j.verdict) == V.WRONG_EDGE:
					# de speld hangt nu aan de open bovenrand: elk volgend vak leest het bovenste teken
					var last := str(model[model.size() - 1][0])
					while copy_text.length() < n:
						_zoom(last, true)
						copy_text += last
					_finish()
				elif copy_text.length() >= n:
					_finish()
		"bit":
			var b := int(move.b)
			var v := int(j.verdict)
			if v == V.UNREACHABLE:
				counters.wasted = int(counters.wasted) + bits.length() + 1
				_add_ink(1)
				bits = ""
				getal = ScDec.zero()
				nxt = ScDec.one().half()
				_fx.append({"fx": "needle_reset"})
				_out_dirty = true
				return
			_add_ink(1)
			bits += str(b)
			var inside := false
			var over := false
			if b == 1:
				getal = getal.add(nxt)
				over = getal.ge(up())
				inside = getal.ge(low) and not over
			_fx.append({"fx": "needle", "bit": b, "getal": getal.to_full_string(), "next": nxt.to_full_string(),
				"inside": inside, "overshoot": over})
			nxt = nxt.half()
			if b == 1 and getal.ge(low):
				_finish()


## Zenden: Algoritme 12 met teken sym; na het laatste teken naar de naald (of "0" als low = 0).
func _cut(sym: String, is_auto: bool) -> void:
	_zoom(sym, is_auto)
	i += 1
	if i >= n:
		if low.is_zero():
			bits = "0"
			_add_ink(1)
			_auto("BIT", {"b": 0, "low0": true}, {"fx": "needle", "bit": 0, "getal": "0", "next": "0.5", "inside": true,
				"overshoot": false})
			_finish()
		else:
			phase = P.NEEDLE
	elif auto_after >= 0 and i >= auto_after and not is_auto:
		_auto_cuts()


func _auto_cuts() -> void:
	while i < n and phase == P.CUT:
		_cut(text[i], true)


func _zoom(sym: String, is_auto: bool) -> void:
	var sg := _seg(sym)
	low = sg.lo
	lengte = (sg.hi as ScDec).sub(sg.lo)
	var row := {"i": book.size(), "sym": sym, "links": low.to_full_string(), "lengte": lengte.to_full_string()}
	book.append(row)
	_fx.append({"fx": "segment", "sym": sym, "lo": low.to_full_string(), "hi": up().to_full_string(), "book_row": row,
		"auto": is_auto})
	if is_auto:
		_log("AUTO_CUT", {"sym": sym}, V.OK, true, {}, {}, true)


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	match phase:
		P.CUT:
			if side == ScCodes.Side.SEND:
				return {"act": "cut", "sym": text[i]}
			var ps := _pin_seg()
			return {"act": "cut", "sym": str(ps.sym)} if not ps.is_empty() else {"act": "none"}
		P.NEEDLE:
			return {"act": "bit", "b": 1 if getal.add(nxt).lt(up()) else 0}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CUT:
			if side == ScCodes.Side.SEND:
				for m in model:
					if str(m[0]) != text[i]:
						out.append({"act": "cut", "sym": str(m[0])})
			else:
				for s in segs():
					if pin.eq(s.hi):
						out.append({"act": "cut", "sym": str(s.sym)})
		P.NEEDLE:
			var c := _correct()
			out.append({"act": "bit", "b": 1 - int(c.b)})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CUT:
			out.append({"act": "cut", "sym": "#"})
			if side == ScCodes.Side.RECEIVE:
				for s in segs():
					if pin.lt(s.lo) or pin.gt(s.hi):
						out.append({"act": "cut", "sym": str(s.sym)})
			out.append({"act": "bit", "b": 1})
		P.NEEDLE:
			out.append({"act": "bit", "b": 2})
			out.append({"act": "cut", "sym": str(model[0][0])})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return i if side == ScCodes.Side.SEND else copy_text.length()


func copy() -> String:
	return copy_text


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": copy_text}
	return {"kind": "bits", "bits": bits, "n": n, "model": model.duplicate(true), "ink": int(counters.ink)}


func structure() -> Dictionary:
	return {"book": book.duplicate(true), "bits": bits, "low": low.to_full_string(), "up": up().to_full_string()}


func _cursor() -> Dictionary:
	var sg: Array = []
	for s in segs():
		sg.append({"sym": s.sym, "lo": (s.lo as ScDec).to_full_string(), "hi": (s.hi as ScDec).to_full_string(),
			"lo_f": (s.lo as ScDec).to_float(), "hi_f": (s.hi as ScDec).to_float(),
			"lo_s": (s.lo as ScDec).to_string_sig(), "hi_s": (s.hi as ScDec).to_string_sig()})
	return {"i": i, "low": low.to_full_string(), "up": up().to_full_string(), "len": lengte.to_full_string(),
		"low_f": low.to_float(), "up_f": up().to_float(), "segs": sg, "book": book.duplicate(true),
		"getal": getal.to_full_string(), "next": nxt.to_full_string(), "getal_f": getal.to_float(),
		"next_f": nxt.to_float(), "bits": bits, "pin": pin.to_full_string(), "pin_f": pin.to_float(),
		"copy": copy_text, "n": n, "side": side}


func _snap() -> Dictionary:
	return {"low": low.to_full_string(), "len": lengte.to_full_string(), "i": i, "book": book.duplicate(true),
		"getal": getal.to_full_string(), "next": nxt.to_full_string(), "bits": bits, "copy": copy_text}


func _restore(d: Dictionary) -> void:
	low = ScDec.from_string(str(d.get("low", "0")))
	lengte = ScDec.from_string(str(d.get("len", "1")))
	i = int(d.get("i", 0))
	book = d.get("book", [])
	for r in book:
		r["links"] = str(r.links)
		r["lengte"] = str(r.lengte)
		r["sym"] = str(r.sym)
	getal = ScDec.from_string(str(d.get("getal", "0")))
	nxt = ScDec.from_string(str(d.get("next", "0.5")))
	bits = str(d.get("bits", ""))
	copy_text = str(d.get("copy", ""))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if side == ScCodes.Side.SEND:
		if bits.length() + int(counters.wasted) != int(counters.ink):
			e.append("inkt %d ≠ bits %d + verspild %d" % [int(counters.ink), bits.length(), int(counters.wasted)])
		if not ScDec.from_bits(bits).eq(getal) and not (bits == "0" and low.is_zero()):
			e.append("naald %s ≠ waarde van %s" % [getal.to_full_string(), bits])
	if low.lt(ScDec.zero()) or up().gt(ScDec.one()):
		e.append("interval buiten [0, 1)")
	return e
