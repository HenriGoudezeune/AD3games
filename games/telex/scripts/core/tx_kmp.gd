class_name TxKmp extends TxMachine
## Doorloper (Algoritme 4, Knuth-Morris-Pratt; GDD §3.3), met V[m] na een treffer bij ALL (Oef. 41).
## Zetten (fase DECIDE): {"act":"shift","s":s} · {"act":"strip"} (s = strip[em]); READY: {"act":"go"}.
## Tanden: 1 ≤ s < em past enkel als t[start+s..start+em−1] == z[0..em−1−s] (Definitie 11), anders klem no_mesh.
## Na het schuiven blijft de leeskop staan: gel = em − s (0 als em = 0 of s ≥ em). auto_zero / auto_strip voert
## de machine zelf uit (gelogd met auto = true).

var start: int = 0
var gel: int = 0           # gelijke_tekens waarmee vergelijk_strings() werd opgeroepen
var k: int = 0             # volgende te vergelijken sjabloonpositie (tijdens de naaldloop)
var em: int = -1           # eerste_mismatch van de laatste oproep (m = treffer), −1 = nog niet bepaald
var head: int = 0          # absolute positie van de leeskop
var strip: Array[int] = [] # ponsstrook (EMPTY/BURNT = leeg/verbrand); leeg = geen strook
var auto_zero: bool = false
var auto_strip: bool = false
var vv: Array[int] = []    # Definitie 11, uitgebreid tot j = m
var _open := false


func _setup() -> void:
	kind = TxCodes.Machine.KMP
	vv = TxReference.v_def(z, true)
	var sp = stage.get("strip", "none")
	strip = []
	if sp is Array:
		strip = _ints(sp)
	elif str(sp) == "carry":
		strip = _ints(carry_in.get("strip", []))
	auto_zero = bool(stage.get("auto_zero", false))
	auto_strip = bool(stage.get("auto_strip", false)) and not strip.is_empty()
	start = 0
	gel = 0
	k = 0
	em = -1
	head = 0
	_open = false


func _begin() -> void:
	phase = P.READY
	_fx.append({"fx": "ready", "start": start})
	if n - m < 0:
		_finish_stage()


func strip_cell(j: int) -> int:
	return strip[j] if j >= 0 and j < strip.size() else EMPTY


## Tanden tegen het al gelezen lint: botsende kolommen (absolute posities) voor verschuiving s na mismatch em.
func clash(s: int) -> Array[int]:
	var out: Array[int] = []
	for q in range(s, em):
		var pos := start + q
		if pos < 0 or pos >= n or t[pos] != z[q - s]:
			out.append(pos)
	return out


func _shift_judge(s: int, type: String) -> Dictionary:
	if s < 1:
		return {"ok": false, "reason": "zero", "at": start}
	if s < em and not clash(s).is_empty():
		return {"ok": false, "reason": "no_mesh", "at": start + s, "data": {"clash": clash(s), "s": s, "j": em}}
	var v: int = vv[em]
	return {"ok": true, "verdict": V.OK if s == v else V.SHIFT_LONG, "type": type, "s": s,
		"data": {"s": s, "j": em, "v": v}}


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"go":
			if phase != P.READY:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "GO"}
		"shift":
			if phase != P.DECIDE:
				return {"ok": false, "reason": "wrong_phase"}
			return _shift_judge(int(move.get("s", 0)), "SHIFT")
		"strip":
			if phase != P.DECIDE:
				return {"ok": false, "reason": "wrong_phase"}
			var c := strip_cell(em)
			if c < 1:
				return {"ok": false, "reason": "hole", "at": em, "data": {"j": em, "cell": c}}
			return _shift_judge(c, "STRIP")
	return {"ok": false, "reason": "unknown_act"}


func preview(move: Dictionary) -> Dictionary:
	if str(move.get("act", "")) in ["shift", "strip"] and phase == P.DECIDE:
		var s := int(move.get("s", 0)) if str(move.act) == "shift" else strip_cell(em)
		var cl := clash(s) if s >= 1 else ([] as Array[int])
		return {"fx": "ghost", "ok": s >= 1 and cl.is_empty(), "mesh": s >= 1 and cl.is_empty(), "s": s, "clash": cl,
			"verdict": (V.OK if s == vv[em] else V.SHIFT_LONG) if s >= 1 and cl.is_empty() else V.BUMP}
	return super.preview(move)


func _exec(move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	match str(move.act):
		"go":
			_run()
		"shift", "strip":
			_do_shift(int(j.s), false)
			if not _done:
				_run()


## Naald + automatische vervolgstappen tot een beslissing van de speler, een wachttoestand of het einde.
func _run() -> void:
	var guard := 0
	while not _done and guard < 100000:
		guard += 1
		if not _needle():
			return                     # WAIT_TAPE
		if em == m:
			_report(start, start + m - 1, 0)
			if find == TxCodes.Find.FIRST:
				_finish_stage()
				return
		phase = P.DECIDE
		var s := 0
		var type := ""
		if em == 0 and auto_zero:
			s = 1
			type = "SHIFT"
		elif auto_strip and strip_cell(em) >= 1 and (em == 0 or strip_cell(em) >= em or clash(strip_cell(em)).is_empty()):
			s = strip_cell(em)
			type = "STRIP"
		if s == 0:
			if auto_strip and strip_cell(em) == BURNT:
				_fx.append({"fx": "bump", "reason": "hole", "at": em, "burnt": true})
			elif auto_strip and strip_cell(em) == EMPTY:
				_fx.append({"fx": "bump", "reason": "hole", "at": em, "burnt": false})
			return                     # DECIDE: de speler is aan zet
		var v: int = vv[em]
		var e := _log(type, {"s": s, "j": em, "v": v, "move": {"act": "shift" if type == "SHIFT" else "strip", "s": s}},
				V.OK if s == v else V.SHIFT_LONG, true, {}, {}, true)
		var pc := _cause
		_cause = int(e.seq)
		_do_shift(s, true)
		_cause = pc


## vergelijk_strings vanaf k. -> false als de naald moet wachten op tekens (WAIT_TAPE).
func _needle() -> bool:
	phase = P.NEEDLE
	if not _open:
		_open = true
		k = gel
		em = -1
		counters.alignments = int(counters.alignments) + 1
	var steps: Array = []
	while k < m:
		var pos := start + k
		if pos >= front:
			phase = P.WAIT_TAPE
			head = pos
			_fx.append({"fx": "needle", "steps": steps, "result": "wait", "em": k, "dir": "ltr", "start": start, "gel": gel})
			return false
		counters.ticks = int(counters.ticks) + 1
		var eq := z[k] == t[pos]
		steps.append({"zi": k, "ti": pos, "eq": eq})
		head = pos
		if not eq:
			em = k
			_open = false
			_fx.append({"fx": "needle", "steps": steps, "result": "mismatch", "em": em, "dir": "ltr", "start": start, "gel": gel})
			return true
		k += 1
	em = m
	_open = false
	_fx.append({"fx": "needle", "steps": steps, "result": "match", "em": m, "dir": "ltr", "start": start, "gel": gel})
	return true


func _do_shift(s: int, auto: bool) -> void:
	var old_start := start
	var old_head := start + em
	start += s
	gel = 0 if (em == 0 or s >= em) else em - s
	k = gel
	_open = false
	head = start + gel
	_fx.append({"fx": "stencil", "from": old_start, "to": start, "auto": auto})
	_fx.append({"fx": "head", "from": old_head, "to": head, "rewind": false})
	phase = P.NEEDLE
	_check_passed()
	if start > n - m:
		_finish_stage()


func _resume() -> void:
	_run()


func _force(s: int) -> void:
	var old := start
	start = s
	gel = 0
	k = 0
	em = -1
	_open = false
	head = s
	_fx.append({"fx": "stencil", "from": old, "to": start, "auto": true})
	_check_passed()
	if start > n - m:
		_finish_stage()
	else:
		_run()


func need() -> int:
	if _done:
		return -1
	if phase == P.DECIDE:
		return start + em
	if phase == P.READY:
		return 0
	return start + k


func _miss_line() -> int:
	return start


func _correct() -> Dictionary:
	match phase:
		P.READY:
			return {"act": "go"}
		P.DECIDE:
			return {"act": "shift", "s": vv[em]}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase != P.DECIDE:
		return out
	var v: int = vv[em]
	for s in range(v + 1, maxi(em, v) + 2):
		if s >= em or clash(s).is_empty():
			out.append({"act": "shift", "s": s})
			break
	var c := strip_cell(em)
	if c > v and (c >= em or clash(c).is_empty()):
		out.append({"act": "strip"})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.READY:
			out.append({"act": "shift", "s": 1})
		P.DECIDE:
			out.append({"act": "go"})
			out.append({"act": "shift", "s": 0})
			if vv[em] > 1:
				out.append({"act": "shift", "s": 1})
			if strip_cell(em) < 1:
				out.append({"act": "strip"})
	return out


func cursor() -> Dictionary:
	var ok_arr: Array[bool] = []
	var green := em if phase == P.DECIDE else k
	for i in m:
		ok_arr.append(i < green)
	var c := {"phase": phase, "start": start, "gel": gel, "k": k, "em": em, "head": head, "strip": strip.duplicate(),
		"window_ok": ok_arr}
	if bool(stage.get("v_hint", false)) and phase == P.DECIDE:
		c["v_hint"] = vv[em]
	return c


func _output() -> Dictionary:
	return {"strip": strip.duplicate()}


func _snap() -> Dictionary:
	return {"start": start, "gel": gel, "k": k, "em": em, "head": head, "strip": strip.duplicate(), "open": _open}


func _restore(d: Dictionary) -> void:
	start = int(d.get("start", 0))
	gel = int(d.get("gel", 0))
	k = int(d.get("k", 0))
	em = int(d.get("em", -1))
	head = int(d.get("head", 0))
	strip = _ints(d.get("strip", []))
	_open = bool(d.get("open", false))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if not _done and start > n - m:
		e.append("start %d > n−m" % start)
	if gel < 0 or gel > m:
		e.append("gel %d buiten [0, m]" % gel)
	if phase == P.DECIDE and (em < 0 or em > m):
		e.append("DECIDE zonder em")
	# Stelling 12: de verificatie klopt — z[0..k−1] staat onder t[start..]
	var upto := em if phase == P.DECIDE else k
	for q in mini(upto, m):
		if start + q < n and z[q] != t[start + q]:
			e.append("z[%d] staat niet gelijk onder t[%d]" % [q, start + q])
			break
	return e
