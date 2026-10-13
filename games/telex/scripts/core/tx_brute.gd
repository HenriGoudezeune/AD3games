class_name TxBrute extends TxMachine
## Sjabloon (Algoritme 2, brute kracht; GDD §3.1), ook met joker `?` (Oef. 33).
## Zetten: {"act":"go"} (READY) · {"act":"next"} (DECIDE: start += 1, de kop springt terug, de naald loopt).
## Er is geen keuze: elke uitgevoerde zet is OK. Tik = één tekenvergelijking in strings_gelijk().

var start: int = 0
var k: int = 0          # volgende te vergelijken sjabloonpositie (tijdens de naaldloop)
var res: int = -1       # mismatchpositie of m (treffer) van de laatste uitlijning; −1 = nog niet bepaald
var head: int = 0       # absolute positie van de leeskop
var joker: String = ""
var _open := false      # een oproep van strings_gelijk() is bezig (ook tijdens WAIT_TAPE)


func _setup() -> void:
	kind = TxCodes.Machine.BRUTE
	joker = str(stage.get("joker", ""))
	start = 0
	k = 0
	res = -1
	head = 0
	_open = false


func _begin() -> void:
	phase = P.READY
	_fx.append({"fx": "ready", "start": start})
	if n - m < 0:
		_finish_stage()


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"go":
			if phase != P.READY:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "GO"}
		"next":
			if phase != P.DECIDE:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "SHIFT", "data": {"s": 1}}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, _j: Dictionary, _e: Dictionary) -> void:
	match str(move.act):
		"go":
			_needle()
		"next":
			var last := start + (res if res < m else m - 1)
			var old := start
			start += 1
			k = 0
			res = -1
			var back := maxi(0, last - start) if start <= n - m else 0
			counters.rewind = int(counters.rewind) + back
			_fx.append({"fx": "stencil", "from": old, "to": start, "auto": false})
			_fx.append({"fx": "head", "from": last, "to": start, "rewind": back > 0})
			head = start
			_check_passed()
			if start > n - m:
				_finish_stage()
			else:
				_needle()


func _needle() -> void:
	phase = P.NEEDLE
	if not _open:
		_open = true
		counters.alignments = int(counters.alignments) + 1
	var steps: Array = []
	while k < m:
		var pos := start + k
		if pos >= front:
			phase = P.WAIT_TAPE
			head = pos
			_fx.append({"fx": "needle", "steps": steps, "result": "wait", "em": k, "dir": "ltr", "start": start})
			return
		counters.ticks = int(counters.ticks) + 1
		var eq := z[k] == t[pos] or (joker != "" and z[k] == joker)
		steps.append({"zi": k, "ti": pos, "eq": eq})
		head = pos
		if not eq:
			res = k
			_open = false
			_fx.append({"fx": "needle", "steps": steps, "result": "mismatch", "em": k, "dir": "ltr", "start": start})
			phase = P.DECIDE
			return
		k += 1
	res = m
	_open = false
	_fx.append({"fx": "needle", "steps": steps, "result": "match", "em": m, "dir": "ltr", "start": start})
	_report(start, start + m - 1, 0)
	if find == TxCodes.Find.FIRST:
		_finish_stage()
	else:
		phase = P.DECIDE


func _resume() -> void:
	_needle()


func _force(s: int) -> void:
	var old := start
	start = s
	k = 0
	res = -1
	_open = false
	head = s
	_fx.append({"fx": "stencil", "from": old, "to": start, "auto": true})
	if start > n - m:
		start = maxi(start, n - m + 1)
		_check_passed()
		_finish_stage()
	else:
		_check_passed()
		_needle()


func need() -> int:
	if _done:
		return -1
	return start


func _miss_line() -> int:
	return start


func _correct() -> Dictionary:
	match phase:
		P.READY:
			return {"act": "go"}
		P.DECIDE:
			return {"act": "next"}
	return {"act": "none"}


func _impossible() -> Array[Dictionary]:
	match phase:
		P.READY:
			return [{"act": "next"}]
		P.DECIDE:
			return [{"act": "go"}]
	return []


func cursor() -> Dictionary:
	var kk := k
	if res >= 0:
		kk = mini(res, m - 1)
	return {"phase": phase, "start": start, "k": kk, "res": res, "head": head}


func _snap() -> Dictionary:
	return {"start": start, "k": k, "res": res, "head": head, "open": _open}


func _restore(d: Dictionary) -> void:
	start = int(d.get("start", 0))
	k = int(d.get("k", 0))
	res = int(d.get("res", -1))
	head = int(d.get("head", 0))
	_open = bool(d.get("open", false))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if not _done and (start < 0 or start > n - m):
		e.append("start %d buiten [0, n−m]" % start)
	if k < 0 or k > m:
		e.append("k %d buiten [0, m]" % k)
	return e
