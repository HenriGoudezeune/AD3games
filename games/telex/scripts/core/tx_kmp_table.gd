class_name TxKmpTable extends TxMachine
## Ponsbank (GDD §3.3): de verschuivingstabel V[] ponsen.
##   method "def11" (spiegel, 3-2): {"act":"punch","j":j,"v":v} per vakje, {"act":"done"}.
##   method "alg5"  (spiegelrit, 3-3): Algoritme 5 letterlijk. De naald zoekt z in zichzelf (voorbij het einde
##   staat EOL); de speler ponst {"act":"punch_to","to":b,"v":v} en verschuift {"act":"shift","s":s}/{"act":"strip"}.
## V[0] = V[1] = 1 zijn voorgeponst. cells "m-1" = vakjes 0..m−1, "m" = ook V[m] (ALL-levels).

var method: String = "def11"
var cells_n: int = 0          # aantal te vullen vakjes (m of m+1)
var strip: Array[int] = []
var vv: Array[int] = []       # Definitie 11 uitgebreid
var start: int = 1
var gel: int = 0
var em: int = -1


func _setup() -> void:
	kind = TxCodes.Machine.KMP_TABLE
	method = str(stage.get("method", "def11"))
	cells_n = m + 1 if str(stage.get("cells", "m-1")) == "m" else m
	vv = TxReference.v_def(z, true)
	var size := cells_n if method == "def11" else maxi(cells_n, m + 1)
	strip = []
	strip.resize(size)
	strip.fill(EMPTY)
	if size > 0:
		strip[0] = 1
	if size > 1:
		strip[1] = 1
	start = 1
	gel = 0
	em = -1


func _make_truth() -> Array[Dictionary]:
	return []


func _begin() -> void:
	if method == "alg5":
		_mirror_run()
	else:
		_to_cells()


func first_empty() -> int:
	for j in cells_n:
		if strip[j] == EMPTY:
			return j
	return -1


func empties() -> Array[int]:
	var out: Array[int] = []
	for j in cells_n:
		if strip[j] == EMPTY:
			out.append(j)
	return out


func _to_cells() -> void:
	if first_empty() < 0:
		_finish_stage()
	else:
		phase = P.PUNCH_CELL


## Spiegelrit: zolang start + gel < m − 1 loopt de naald (Algoritme 5), anders klaar of herstel.
func _mirror_run() -> void:
	if start + gel < m - 1:
		var r := TxReference.vergelijk_strings(z, z, start, gel)
		em = int(r.em)
		var steps: Array = []
		for i in range(gel, em + 1):
			if i >= m:
				break
			var tc := z[start + i] if start + i < m else TxCodes.EOL
			steps.append({"zi": i, "ti": start + i, "eq": z[i] == tc})
		counters.ticks = int(counters.ticks) + int(r.cmp)
		counters.alignments = int(counters.alignments) + 1
		_fx.append({"fx": "needle", "steps": steps, "result": "mismatch" if em < m else "match", "em": em,
			"dir": "ltr", "mirror": true, "start": start})
		phase = P.MIRROR_PUNCH
	else:
		_to_cells()


## Eerste nieuwe vakje van deze stop (Algoritme 5: start + gel + 1; bij em = 0: start + 1).
func punch_from() -> int:
	return start + gel + 1


func correct_punch() -> Vector2i:
	if em == 0:
		return Vector2i(start + 1, start + 1)
	return Vector2i(start + em, start)


func _punch_ok(j: int, v: int) -> bool:
	return v >= 1 and v <= j and TxReference.mesh(z, j, v)


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"punch":
			if phase != P.PUNCH_CELL:
				return {"ok": false, "reason": "wrong_phase"}
			var j := int(move.get("j", -1))
			var v := int(move.get("v", 0))
			if j < 0 or j >= cells_n:
				return {"ok": false, "reason": "range", "at": j}
			if strip[j] != EMPTY:
				return {"ok": false, "reason": "filled", "at": j}
			if v < 1 or v > j:
				return {"ok": false, "reason": "range", "at": j}
			if not TxReference.mesh(z, j, v):
				return {"ok": false, "reason": "no_mesh", "at": j, "data": {"j": j, "s": v}}
			return {"ok": true, "verdict": V.OK if v == vv[j] else V.PUNCH_LONG, "type": "PUNCH",
				"data": {"j": j, "v": vv[j], "s": v}}
		"done":
			if phase != P.PUNCH_CELL:
				return {"ok": false, "reason": "wrong_phase"}
			var em_list := empties()
			return {"ok": true, "verdict": V.OK if em_list.is_empty() else V.PUNCH_SHORT, "type": "DONE",
				"data": {"empty": em_list}}
		"punch_to":
			if phase != P.MIRROR_PUNCH:
				return {"ok": false, "reason": "wrong_phase"}
			var b := int(move.get("to", -1))
			var v2 := int(move.get("v", 0))
			var a := punch_from()
			if b < a - 1 or b > strip.size() - 1:
				return {"ok": false, "reason": "range", "at": b}
			for q in range(a, b + 1):
				if strip[q] != EMPTY:
					return {"ok": false, "reason": "filled", "at": q}
			for q in range(a, b + 1):
				if not _punch_ok(q, v2):
					return {"ok": false, "reason": "no_mesh", "at": q,
						"data": {"j": q, "s": v2, "mirror_zero": em == 0, "v": start + 1}}
			var cp := correct_punch()
			var verdict := V.OK
			var data := {"a": a, "b": cp.x, "v": cp.y, "to": b, "s": v2}
			if b < cp.x:
				verdict = V.PUNCH_SHORT
			else:
				for q in range(a, b + 1):
					if q < vv.size() and v2 != vv[q]:
						verdict = V.PUNCH_LONG
						data["j"] = q
						data["v"] = vv[q]
						break
			return {"ok": true, "verdict": verdict, "type": "PUNCH_TO", "data": data}
		"shift", "strip":
			if phase != P.MIRROR_SHIFT:
				return {"ok": false, "reason": "wrong_phase"}
			var s := int(move.get("s", 0))
			var type := "SHIFT"
			if str(move.act) == "strip":
				s = strip[em] if em < strip.size() else EMPTY
				type = "STRIP"
				if s < 1:
					return {"ok": false, "reason": "hole", "at": em}
			if s < 1:
				return {"ok": false, "reason": "zero", "at": start}
			if s < em and not TxReference.mesh(z, em, s):
				return {"ok": false, "reason": "no_mesh", "at": start + s, "data": {"j": em, "s": s}}
			return {"ok": true, "verdict": V.OK if s == vv[em] else V.SHIFT_LONG, "type": type, "s": s,
				"data": {"s": s, "j": em, "v": vv[em]}}
	return {"ok": false, "reason": "unknown_act"}


func preview(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	if act == "punch":
		var j := int(move.get("j", -1))
		var v := int(move.get("v", 0))
		var ok := j >= 0 and j < cells_n and _punch_ok(j, v)
		return {"fx": "ghost", "ok": ok, "mesh": ok, "s": v, "j": j}
	if act == "shift" and phase == P.MIRROR_SHIFT:
		var s := int(move.get("s", 0))
		var ok2 := s >= 1 and (s >= em or TxReference.mesh(z, em, s))
		return {"fx": "ghost", "ok": ok2, "mesh": ok2, "s": s}
	return super.preview(move)


func _exec(move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	match str(move.act):
		"punch":
			var q := int(move.j)
			strip[q] = int(move.v)
			_fx.append({"fx": "punch", "cells": [{"j": q, "v": int(move.v)}]})
			if first_empty() < 0:
				_finish_stage()
		"done":
			_finish_stage()
		"punch_to":
			var a := punch_from()
			var b := int(move.to)
			var cells: Array = []
			for q in range(a, b + 1):
				strip[q] = int(move.v)
				cells.append({"j": q, "v": int(move.v)})
			_fx.append({"fx": "punch", "cells": cells})
			phase = P.MIRROR_SHIFT
		"shift", "strip":
			var s := int(j.s)
			var old := start
			start += s
			gel = 0 if (em == 0 or s >= em) else em - s
			_fx.append({"fx": "stencil", "from": old, "to": start, "auto": false, "mirror": true})
			em = -1
			_mirror_run()


func _correct() -> Dictionary:
	match phase:
		P.PUNCH_CELL:
			var j := first_empty()
			if j < 0:
				return {"act": "done"}
			return {"act": "punch", "j": j, "v": vv[j]}
		P.MIRROR_PUNCH:
			var cp := correct_punch()
			return {"act": "punch_to", "to": cp.x, "v": cp.y}
		P.MIRROR_SHIFT:
			return {"act": "shift", "s": vv[em]}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.PUNCH_CELL:
			var j := first_empty()
			if j >= 0:
				for v in range(vv[j] + 1, j + 1):
					if _punch_ok(j, v):
						out.append({"act": "punch", "j": j, "v": v})
						break
				out.append({"act": "done"})
		P.MIRROR_PUNCH:
			var cp := correct_punch()
			var a := punch_from()
			if cp.x - 1 >= a - 1 and cp.x - 1 < cp.x:
				out.append({"act": "punch_to", "to": cp.x - 1, "v": cp.y})
			if a == cp.x:
				for v in range(cp.y + 1, cp.x + 1):
					if _punch_ok(cp.x, v) and (cp.x >= vv.size() or v != vv[cp.x]):
						out.append({"act": "punch_to", "to": cp.x, "v": v})
						break
		P.MIRROR_SHIFT:
			for s in range(vv[em] + 1, em + 2):
				if s >= em or TxReference.mesh(z, em, s):
					out.append({"act": "shift", "s": s})
					break
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.PUNCH_CELL:
			var j := first_empty()
			out.append({"act": "punch", "j": 0, "v": 1})
			if j >= 0:
				out.append({"act": "punch", "j": j, "v": 0})
			out.append({"act": "shift", "s": 1})
		P.MIRROR_PUNCH:
			out.append({"act": "punch_to", "to": strip.size(), "v": start})
			out.append({"act": "shift", "s": 1})
			var cp := correct_punch()
			for v in range(1, cp.x + 1):
				if not _punch_ok(cp.x, v):
					out.append({"act": "punch_to", "to": cp.x, "v": v})
					break
		P.MIRROR_SHIFT:
			out.append({"act": "shift", "s": 0})
			out.append({"act": "punch_to", "to": start + 1, "v": start})
	return out


func cursor() -> Dictionary:
	return {"phase": phase, "method": method, "j": first_empty() if phase == P.PUNCH_CELL else -1, "start": start,
		"gel": gel, "em": em, "punch_from": punch_from() if phase == P.MIRROR_PUNCH else -1, "strip": strip.duplicate(),
		"cells": cells_n}


func tables() -> Dictionary:
	return {"kind": "strip", "yours": strip.duplicate(), "correct": vv.slice(0, strip.size()),
		"alg5": TxReference.bereken_v(z).v if method == "alg5" else []}


func _output() -> Dictionary:
	return {"strip": strip.duplicate()}


func _snap() -> Dictionary:
	return {"strip": strip.duplicate(), "start": start, "gel": gel, "em": em}


func _restore(d: Dictionary) -> void:
	strip = _ints(d.get("strip", []))
	start = int(d.get("start", 1))
	gel = int(d.get("gel", 0))
	em = int(d.get("em", -1))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for j in strip.size():
		var v := strip[j]
		if v == EMPTY:
			continue
		if v < 1 or (j >= 1 and v > j) or not TxReference.mesh(z, j, v) and j > 0:
			e.append("vakje %d = %d past niet (Definitie 11)" % [j, v])
	if method == "alg5" and (phase == P.MIRROR_PUNCH or phase == P.MIRROR_SHIFT) and start + gel >= m - 1:
		e.append("spiegelrit voorbij de lusvoorwaarde")
	return e
