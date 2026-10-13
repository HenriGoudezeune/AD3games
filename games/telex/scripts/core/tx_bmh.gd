class_name TxBmh extends TxMachine
## Springer (Boyer-Moore-Horspool; GDD §3.4): kaarten stempelen (vul_VH) + doorloop (is_contained_BMH).
## CARDS: {"act":"stamp","i":p} (cards[z[p]] := m−1−p; p = m−1 klemt), {"act":"cards_done"}.
## READY: {"act":"go"}. DECIDE: {"act":"key","pos":p} (kaart van t[p] trekken) of {"act":"jump","s":s} (hand).
## De naald vergelijkt van rechts naar links (strings_gelijk_invers); sleutelteken = t[i] onder de laatste positie.
## cards: "stamp" | "carry" | "prefilled" | "none" (geen kaartenbak: enkel handsprongen, Nachtdienst).

var i: int = 0              # positie in t onder de laatste sjabloonpositie
var k: int = 0              # aantal al vergeleken tekens in deze uitlijning (naald)
var mis_z: int = -1         # mismatchpositie in z van de laatste uitlijning (−1 = geen / treffer)
var ok_last: bool = false   # laatste uitlijning was een treffer
var cards: Dictionary = {}  # letter -> waarde (ontbrekend = "overige" = m)
var cards_mode: String = "stamp"
var key_hint: bool = false
var auto_jump: bool = false # finale: de machine trekt zelf de kaart (met de spelerskaarten)
var vh: Dictionary = {}     # echte V_H
var next_stamp: int = 0     # orakel: volgende positie in de volgorde 0..m−2
var _open := false


func _setup() -> void:
	kind = TxCodes.Machine.BMH
	vh = TxReference.vul_vh(z)
	cards_mode = str(stage.get("cards", "stamp"))
	key_hint = bool(stage.get("key_hint", false))
	auto_jump = bool(stage.get("auto_jump", false))
	match cards_mode:
		"carry":
			cards = _card_dict(carry_in.get("cards", {}))
		"prefilled":
			cards = vh.duplicate()
		_:
			cards = {}
	i = m - 1
	k = 0
	mis_z = -1
	ok_last = false
	next_stamp = 0
	_open = false


static func _card_dict(d) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for x in d:
			out[str(x)] = int(d[x])
	return out


func card_value(x: String) -> int:
	return int(cards.get(x, m))


func true_shift(x: String) -> int:
	return TxReference.vh_of(vh, x, m)


func cards_correct() -> bool:
	for x in vh:
		if card_value(x) != int(vh[x]):
			return false
	for x in cards:
		if int(cards[x]) != true_shift(x):
			return false
	return true


func _begin() -> void:
	if cards_mode == "stamp":
		phase = P.CARDS
	else:
		_to_run()


func _to_run() -> void:
	if t == "":
		_finish_stage()
		return
	phase = P.READY
	_fx.append({"fx": "ready", "start": i - m + 1})
	if n < m:
		_finish_stage()


func _wrong_card_data() -> Dictionary:
	for x in vh:
		if card_value(x) != int(vh[x]):
			return {"x": x, "v": int(vh[x]), "m1": m - 1, "p": m - 1 - int(vh[x]), "got": card_value(x)}
	for x in cards:
		if int(cards[x]) != true_shift(x):
			return {"x": x, "v": m, "m1": m - 1, "p": -1, "got": int(cards[x])}
	return {}


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"stamp":
			if phase != P.CARDS:
				return {"ok": false, "reason": "wrong_phase"}
			var p := int(move.get("i", -1))
			if p < 0 or p >= m:
				return {"ok": false, "reason": "range", "at": p}
			if p == m - 1:
				return {"ok": false, "reason": "last_pos", "at": p}
			return {"ok": true, "verdict": V.OK, "type": "STAMP",
				"data": {"i": p, "x": z[p], "v": m - 1 - p, "old": int(cards.get(z[p], -1))}}
		"cards_done":
			if phase != P.CARDS:
				return {"ok": false, "reason": "wrong_phase"}
			var ok := cards_correct()
			var d := {} if ok else _wrong_card_data()
			return {"ok": true, "verdict": V.OK if ok else V.WRONG_CARDS, "type": "CARDS_DONE", "data": d}
		"go":
			if phase != P.READY:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "GO"}
		"key":
			if phase != P.DECIDE:
				return {"ok": false, "reason": "wrong_phase"}
			if cards_mode == "none":
				return {"ok": false, "reason": "no_card"}
			var pos := int(move.get("pos", -1))
			if pos < i - m + 1 or pos > i or pos < 0 or pos >= n:
				return {"ok": false, "reason": "out_of_window", "at": pos}
			var s := card_value(t[pos])
			var v := true_shift(t[i])
			var verdict := V.OK
			if pos != i:
				verdict = V.WRONG_KEY
			elif s != v:
				verdict = V.JUMP_LONG if s > v else V.JUMP_SHORT
			return {"ok": true, "verdict": verdict, "type": "KEY", "s": s,
				"data": {"pos": pos, "x": t[i], "y": t[pos], "v": v, "s": s, "i": i}}
		"jump":
			if phase != P.DECIDE:
				return {"ok": false, "reason": "wrong_phase"}
			var s2 := int(move.get("s", 0))
			if s2 < 1:
				return {"ok": false, "reason": "zero", "at": i}
			var v2 := true_shift(t[i])
			var vd := V.OK
			if s2 != v2:
				vd = V.JUMP_LONG if s2 > v2 else V.JUMP_SHORT
			return {"ok": true, "verdict": vd, "type": "JUMP", "s": s2,
				"data": {"x": t[i], "v": v2, "s": s2, "i": i}}
	return {"ok": false, "reason": "unknown_act"}


func preview(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	if phase == P.DECIDE and (act == "jump" or act == "key"):
		var j := _judge(move)
		var s := int(j.get("s", 0))
		return {"fx": "ghost", "ok": bool(j.get("ok", false)), "reason": str(j.get("reason", "")), "s": s,
			"to": i + s, "verdict": int(j.get("verdict", V.BUMP)), "mesh": bool(j.get("ok", false))}
	return super.preview(move)


func _exec(move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	match str(move.act):
		"stamp":
			var p := int(move.i)
			var old := int(cards.get(z[p], -1))
			cards[z[p]] = m - 1 - p
			_fx.append({"fx": "stamp", "i": p, "x": z[p], "v": m - 1 - p, "old": old})
			if p == next_stamp:
				next_stamp += 1
			else:
				next_stamp = -1
		"cards_done":
			_to_run()
		"go":
			_run()
		"key":
			var pos := int(move.pos)
			_fx.append({"fx": "key", "pos": pos, "ch": t[pos], "v": int(j.s)})
			_jump(int(j.s))
		"jump":
			_jump(int(j.s))


func _jump(s: int) -> void:
	var old := i
	i += s
	k = 0
	mis_z = -1
	ok_last = false
	_open = false
	_fx.append({"fx": "jump", "from": old, "to": i, "s": s})
	_check_passed()
	if i >= n:
		_finish_stage()
	else:
		_run()


func _run() -> void:
	var guard := 0
	while not _done and guard < 100000:
		guard += 1
		if not _needle():
			return
		if ok_last:
			_report(i - m + 1, i, 0)
			if find == TxCodes.Find.FIRST:
				_finish_stage()
				return
		phase = P.DECIDE
		if not auto_jump:
			return
		var s := card_value(t[i]) if cards_mode != "none" else true_shift(t[i])
		var v := true_shift(t[i])
		var vd := V.OK
		if s != v:
			vd = V.JUMP_LONG if s > v else V.JUMP_SHORT
		var e := _log("KEY", {"pos": i, "x": t[i], "y": t[i], "v": v, "s": s, "i": i,
			"move": {"act": "key", "pos": i}}, vd, true, {}, {}, true)
		var pc := _cause
		_cause = int(e.seq)
		_fx.append({"fx": "key", "pos": i, "ch": t[i], "v": s})
		var old := i
		i += s
		k = 0
		mis_z = -1
		ok_last = false
		_fx.append({"fx": "jump", "from": old, "to": i, "s": s})
		_check_passed()
		_cause = pc
		if i >= n:
			_finish_stage()
			return


## strings_gelijk_invers vanaf k. -> false als de naald moet wachten (WAIT_TAPE).
func _needle() -> bool:
	phase = P.NEEDLE
	if not _open:
		_open = true
		k = 0
		counters.alignments = int(counters.alignments) + 1
	if i >= front:
		phase = P.WAIT_TAPE
		_fx.append({"fx": "needle", "steps": [], "result": "wait", "em": m - 1 - k, "dir": "rtl", "i": i})
		return false
	var steps: Array = []
	while k < m:
		var pos := i - k
		if over_budget():
			abort("budget")
			return false
		counters.ticks = int(counters.ticks) + 1
		var eq := z[m - 1 - k] == t[pos]
		steps.append({"zi": m - 1 - k, "ti": pos, "eq": eq})
		if not eq:
			mis_z = m - 1 - k
			ok_last = false
			_open = false
			_fx.append({"fx": "needle", "steps": steps, "result": "mismatch", "em": mis_z, "dir": "rtl", "i": i})
			return true
		k += 1
	mis_z = -1
	ok_last = true
	_open = false
	_fx.append({"fx": "needle", "steps": steps, "result": "match", "em": -1, "dir": "rtl", "i": i})
	return true


func _resume() -> void:
	_run()


func _force(s: int) -> void:
	var old := i
	i = s + m - 1
	k = 0
	mis_z = -1
	ok_last = false
	_open = false
	_fx.append({"fx": "jump", "from": old, "to": i, "s": i - old, "auto": true})
	_check_passed()
	if i >= n:
		_finish_stage()
	else:
		_run()


func need() -> int:
	if _done or phase == P.CARDS:
		return -1
	return i - m + 1


func _miss_line() -> int:
	return i - m + 1


func _correct() -> Dictionary:
	match phase:
		P.CARDS:
			if cards_correct():
				return {"act": "cards_done"}
			if next_stamp >= 0 and next_stamp <= m - 2:
				return {"act": "stamp", "i": next_stamp}
			var wd := _wrong_card_data()
			var p := int(wd.get("p", -1))
			if p >= 0:
				return {"act": "stamp", "i": p}
			return {"act": "cards_done"}
		P.READY:
			return {"act": "go"}
		P.DECIDE:
			var v := true_shift(t[i])
			if cards_mode != "none" and card_value(t[i]) == v:
				return {"act": "key", "pos": i}
			return {"act": "jump", "s": v}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CARDS:
			if not cards_correct():
				out.append({"act": "cards_done"})
		P.DECIDE:
			var v := true_shift(t[i])
			if cards_mode != "none":
				# de typische fout: het mismatchteken (of een ander teken in het venster) als sleutel
				var alt := -1
				if mis_z >= 0:
					alt = i - (m - 1 - mis_z)
				if alt == i or alt < 0:
					alt = i - 1 if i - 1 >= i - m + 1 and m > 1 else -1
				if alt >= 0 and alt != i:
					out.append({"act": "key", "pos": alt})
			out.append({"act": "jump", "s": v + 1})
			if v > 1:
				out.append({"act": "jump", "s": v - 1})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CARDS:
			out.append({"act": "stamp", "i": m - 1})
			out.append({"act": "stamp", "i": m})
			out.append({"act": "go"})
		P.READY:
			out.append({"act": "jump", "s": 1})
		P.DECIDE:
			out.append({"act": "jump", "s": 0})
			out.append({"act": "key", "pos": i + 1})
			out.append({"act": "key", "pos": i - m})
			out.append({"act": "stamp", "i": 0})
	return out


func cursor() -> Dictionary:
	var c := {"phase": phase, "i": i, "start": i - m + 1, "mis_z": mis_z, "cards": cards.duplicate(), "k": k,
		"key_pos": i if key_hint and phase == P.DECIDE else -1}
	return c


func tables() -> Dictionary:
	if cards_mode == "none":
		return {}
	return {"kind": "cards", "yours": cards.duplicate(), "correct": vh.duplicate(), "other": m}


func _output() -> Dictionary:
	return {"cards": cards.duplicate()}


func _snap() -> Dictionary:
	return {"i": i, "k": k, "mis_z": mis_z, "ok_last": ok_last, "cards": cards.duplicate(), "next_stamp": next_stamp,
		"open": _open}


func _restore(d: Dictionary) -> void:
	i = int(d.get("i", m - 1))
	k = int(d.get("k", 0))
	mis_z = int(d.get("mis_z", -1))
	ok_last = bool(d.get("ok_last", false))
	cards = _card_dict(d.get("cards", {}))
	next_stamp = int(d.get("next_stamp", 0))
	_open = bool(d.get("open", false))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for x in cards:
		var v := int(cards[x])
		if v < 1 or v > m:
			e.append("kaart %s = %d buiten [1, m]" % [x, v])
	if phase == P.DECIDE and (i < m - 1 or i >= n):
		e.append("DECIDE met i = %d buiten het lint" % i)
	return e
