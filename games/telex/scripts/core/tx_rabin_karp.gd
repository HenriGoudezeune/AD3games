class_name TxRabinKarp extends TxMachine
## Vingerafdruk (Algoritme 3, Rabin-Karp met bitstrings; GDD §3.2).
## Het hashwiel rekent mod q. Fasen: W_CALC (gewicht w = 2^m mod q: wiel op 1, m× ×2, commit), HORNER (h(z), venster 0
## of een signaal: per bit ×2 (+1), next_bit), ROLL (×2, −w als het uitgaande bit 1 is, +1 als het inkomende bit 1 is,
## slide), ALARM (wiel == inkeping h(z): verify / report / ignore).
## Oordeel per stap relatief aan de vorige wielstand (één fout = één misstap); de foute waarde loopt wel door.

var q: int = 7
var w: int = -1              # geijkt gewicht (spelerswaarde), −1 = nog niet geijkt
var w_true: int = 0
var hz: int = -1             # rode inkeping (spelerswaarde), −1 = nog niet gezet
var hz_true: int = 0
var wheel: int = 0
var part: String = ""        # "w" | "z" | "window" | "signal" | "roll"
var bits: String = ""        # bitstring van de lopende Horner-reeks
var bit_k: int = 0
var wb: int = 0              # wielstand vóór deze stap (bit of rolstap)
var did_double: bool = false
var did_minus: bool = false
var doubles: int = 0         # W_CALC
var i: int = 0               # huidig venster (tekstmodus)
var signals: Array = []      # signaalmodus (2-1 stage C)
var si: int = 0              # huidig signaal
var queue: Array = []        # resterende ijkstappen ("w", "hz")
var hist: Array = []         # [{i, wheel, true}] bij elke afgewerkte vensterwaarde
var drift_seq: int = -1      # event dat het wiel van de waarheid deed afwijken (−1 = in sync)
var notch_seq: int = -1      # event dat de inkeping verkeerd zette
var w_seq: int = -1          # commit van een verkeerde w
var horner_err: int = -1     # eerste foute bit in de lopende Horner-reeks
var win_cause: Dictionary = {}   # venster -> drift_seq op dat moment
var ignored: Dictionary = {}     # venster -> seq van Negeer


func _setup() -> void:
	kind = TxCodes.Machine.RABIN_KARP
	q = int(stage.get("q", 7))
	w_true = TxReference.weight(m, q)
	hz_true = TxReference.h(z, q)
	signals = []
	for s in stage.get("signals", []):
		signals.append(str(s))
	var prefill: Dictionary = stage.get("prefill", {})
	w = int(prefill.get("w", -1))
	hz = int(prefill.get("hz", -1))
	queue = []
	for p in stage.get("prep", ["w", "hz"]):
		var ps := str(p)
		if ps == "w" and w < 0:
			queue.append("w")
		elif ps == "hz" and hz < 0:
			queue.append("hz")
	if w < 0 and not queue.has("w"):
		w = w_true
	if hz < 0 and not queue.has("hz"):
		hz = hz_true
	wheel = 0
	part = ""
	bits = ""
	bit_k = 0
	wb = 0
	did_double = false
	did_minus = false
	doubles = 0
	i = 0
	si = 0
	hist = []
	drift_seq = -1
	notch_seq = -1
	w_seq = -1
	horner_err = -1
	win_cause = {}
	ignored = {}


func signal_mode() -> bool:
	return not signals.is_empty()


func _make_truth() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if signal_mode():
		for k2 in signals.size():
			if str(signals[k2]) == z:
				out.append({"start": k2, "end": k2, "level": 0})
		return out
	return super._make_truth()


func true_hash(win: int) -> int:
	if signal_mode():
		return TxReference.h(str(signals[win]), q) if win >= 0 and win < signals.size() else -1
	if win < 0 or win > n - m:
		return -1
	return TxReference.h(t.substr(win, m), q)


func window_bits(win: int) -> String:
	if signal_mode():
		return str(signals[win]) if win >= 0 and win < signals.size() else ""
	return t.substr(win, m)


func history() -> Array:
	return hist.duplicate(true)


func _begin() -> void:
	if hz >= 0:
		_fx.append({"fx": "notch", "value": hz})
	_next_prep()


func _set_wheel(v: int) -> void:
	_fx.append({"fx": "wheel", "op": "set", "from": wheel, "to": v, "q": q})
	wheel = v


func _next_prep() -> void:
	if queue.has("w"):
		queue.erase("w")
		part = "w"
		phase = P.W_CALC
		doubles = 0
		did_double = false
		_set_wheel(1 % q)
		return
	if queue.has("hz"):
		queue.erase("hz")
		_start_horner("z", z)
		return
	if signal_mode():
		si = 0
		_start_horner("signal", str(signals[0]))
	else:
		i = 0
		if n < m:
			_finish_stage()
			return
		_start_horner("window", t.substr(0, m))


func _start_horner(p: String, b: String) -> void:
	part = p
	bits = b
	bit_k = 0
	wb = 0
	did_double = false
	did_minus = false
	horner_err = -1
	if p == "signal":
		drift_seq = -1
	phase = P.HORNER
	_set_wheel(0)


func cur_bit() -> int:
	return 1 if bit_k < bits.length() and bits[bit_k] == "1" else 0


func out_bit() -> int:
	return 1 if i < n and t[i] == "1" else 0


func in_bit() -> int:
	return 1 if i + m < n and t[i + m] == "1" else 0


func step_target() -> int:
	match phase:
		P.HORNER:
			return posmod(2 * wb + cur_bit(), q)
		P.ROLL:
			return posmod(2 * wb - out_bit() * w + in_bit(), q)
		P.W_CALC:
			return w_true
	return -1


func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"wheel":
			if not phase in [P.W_CALC, P.HORNER, P.ROLL]:
				return {"ok": false, "reason": "wrong_phase"}
			var op := str(move.get("op", ""))
			match op:
				"double":
					pass
				"minus_w":
					if phase == P.W_CALC or phase == P.HORNER:
						return {"ok": false, "reason": "not_now"}
					if w < 0:
						return {"ok": false, "reason": "no_w"}
				"plus1":
					if phase == P.W_CALC:
						return {"ok": false, "reason": "not_now"}
				_:
					return {"ok": false, "reason": "unknown_act"}
			return {"ok": true, "verdict": V.OK, "type": "WHEEL", "data": {"op": op, "from": wheel}}
		"commit":
			if phase != P.W_CALC:
				return {"ok": false, "reason": "wrong_phase"}
			var okw := wheel == w_true
			return {"ok": true, "verdict": V.OK if okw else V.WRONG_HASH, "type": "COMMIT",
				"data": {"part": "w", "m": m, "x": w_true, "y": wheel, "q": q}}
		"next_bit":
			if phase != P.HORNER:
				return {"ok": false, "reason": "wrong_phase"}
			var tg := step_target()
			return {"ok": true, "verdict": V.OK if wheel == tg else V.WRONG_HORNER, "type": "BIT",
				"data": {"k": bit_k + 1, "bit": cur_bit(), "plus": cur_bit() == 1, "x": tg, "y": wheel, "q": q,
					"part": part}}
		"slide":
			if phase != P.ROLL:
				return {"ok": false, "reason": "wrong_phase"}
			var tg2 := step_target()
			return {"ok": true, "verdict": V.OK if wheel == tg2 else V.WRONG_HASH, "type": "SLIDE",
				"data": {"i": i + 1, "h": wb, "w": w, "minus": out_bit() == 1, "plus": in_bit() == 1, "q": q, "x": tg2,
					"y": wheel}}
		"verify", "report", "ignore":
			if phase != P.ALARM:
				return {"ok": false, "reason": "no_alarm"}
			var win := si if signal_mode() else i
			var equal := window_bits(win) == z
			var vd := V.OK
			if act == "report":
				vd = V.UNVERIFIED if equal else V.FALSE_ALARM
			elif act == "ignore":
				vd = V.SKIPPED_CHECK
			return {"ok": true, "verdict": vd, "type": act.to_upper(),
				"data": {"i": win, "equal": equal, "hz": hz, "q": q, "w": window_bits(win), "machine": "rk"}}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, j: Dictionary, e: Dictionary) -> void:
	var act := str(move.act)
	match act:
		"wheel":
			counters.wheel = int(counters.wheel) + 1
			var old := wheel
			match str(move.op):
				"double":
					wheel = posmod(2 * wheel, q)
					did_double = true
					if phase == P.W_CALC:
						doubles += 1
				"minus_w":
					wheel = posmod(wheel - w, q)
					did_minus = true
				"plus1":
					wheel = posmod(wheel + 1, q)
			_fx.append({"fx": "wheel", "op": str(move.op), "from": old, "to": wheel, "q": q})
		"commit":
			w = wheel
			w_seq = -1 if int(j.verdict) == V.OK else int(e.seq)
			_fx.append({"fx": "bit", "which": "w", "k": doubles, "value": w, "ok": int(j.verdict) == V.OK})
			_next_prep()
		"next_bit":
			var okb := int(j.verdict) == V.OK
			if not okb and horner_err < 0:
				horner_err = int(e.seq)
			_fx.append({"fx": "bit", "which": part, "k": bit_k, "value": wheel, "ok": okb})
			bit_k += 1
			wb = wheel
			did_double = false
			did_minus = false
			if bit_k >= bits.length():
				_horner_done(e)
		"slide":
			i += 1
			var okr := int(j.verdict) == V.OK
			_fx.append({"fx": "window", "i": i, "out_bit": t[i - 1], "in_bit": t[i + m - 1]})
			_track(okr, e)
			_check_passed()
			_alarm_check()
		"verify":
			var win := si if signal_mode() else i
			var wb_bits := window_bits(win)
			var steps: Array = []
			var equal := true
			for kk in m:
				counters.ticks = int(counters.ticks) + 1
				var eq := z[kk] == wb_bits[kk]
				steps.append({"zi": kk, "ti": (win + kk) if not signal_mode() else kk, "eq": eq})
				if not eq:
					equal = false
					break
			counters.alignments = int(counters.alignments) + 1
			_fx.append({"fx": "verify", "i": win, "steps": steps, "equal": equal})
			if equal:
				_report_window(win)
				if _done:
					return
			_after_window()
		"report":
			var win2 := si if signal_mode() else i
			var hit := _report_window(win2)
			if not bool(hit.real):
				_false_alarm(hit, {}, false)
			if _done:
				return
			_after_window()
		"ignore":
			var win3 := si if signal_mode() else i
			ignored[win3] = int(e.seq)
			if bool(j.data.equal):
				for o in truth:
					if int(o.start) == win3 and not _occ_found(o) and not _occ_missed(o):
						_mark_missed(o)
			_after_window()


func _report_window(win: int) -> Dictionary:
	var h: Dictionary
	if signal_mode():
		h = _report(win, win, 0)
	else:
		h = _report(win, win + m - 1, 0)
	if bool(h.real) and find == TxCodes.Find.FIRST:
		_finish_stage()
	return h


## Bijhouden of het wiel nog met de waarheid overeenkomt (oorzaakketen voor de debrief).
func _track(step_ok: bool, e: Dictionary) -> void:
	var win := si if signal_mode() else i
	var tr := true_hash(win)
	hist.append({"i": win, "wheel": wheel, "true": tr, "part": part})
	if wheel == tr:
		drift_seq = -1
	elif drift_seq < 0:
		if horner_err >= 0 and (part == "window" or part == "signal"):
			drift_seq = horner_err
		elif not step_ok:
			drift_seq = int(e.seq)
		elif w_seq >= 0:
			drift_seq = w_seq
		else:
			drift_seq = int(e.seq)
	win_cause[win] = drift_seq


func _horner_done(e: Dictionary) -> void:
	match part:
		"z":
			hz = wheel
			notch_seq = -1 if hz == hz_true else (horner_err if horner_err >= 0 else int(e.seq))
			_fx.append({"fx": "notch", "value": hz})
			_next_prep()
		"window", "signal":
			_track(horner_err < 0, e)
			_alarm_check()


func _alarm_check() -> void:
	if wheel == hz:
		phase = P.ALARM
		_fx.append({"fx": "alarm", "i": si if signal_mode() else i})
		return
	_after_window()


func _after_window() -> void:
	if signal_mode():
		si += 1
		_check_passed()
		if si >= signals.size():
			_finish_stage()
		else:
			_start_horner("signal", str(signals[si]))
		return
	if i >= n - m:
		i = n - m + 1
		_check_passed()
		i = n - m
		_finish_stage()
		return
	part = "roll"
	phase = P.ROLL
	wb = wheel
	did_double = false
	did_minus = false


func _cause_for(occ: Dictionary) -> int:
	var st := int(occ.start)
	if ignored.has(st):
		return int(ignored[st])
	if notch_seq >= 0:
		return notch_seq
	var c := int(win_cause.get(st, -1))
	if c >= 0:
		return c
	return _cause


func need() -> int:
	return -1 if _done else (si if signal_mode() else i)


func _miss_line() -> int:
	return si if signal_mode() else i


func _correct() -> Dictionary:
	match phase:
		P.W_CALC:
			if doubles < m or wheel != w_true:
				return {"act": "wheel", "op": "double"}
			return {"act": "commit"}
		P.HORNER:
			if not did_double:
				return {"act": "wheel", "op": "double"}
			if wheel != step_target():
				return {"act": "wheel", "op": "plus1"}
			return {"act": "next_bit"}
		P.ROLL:
			if not did_double:
				return {"act": "wheel", "op": "double"}
			if out_bit() == 1 and not did_minus:
				return {"act": "wheel", "op": "minus_w"}
			if wheel != step_target():
				return {"act": "wheel", "op": "plus1"}
			return {"act": "slide"}
		P.ALARM:
			return {"act": "verify"}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.W_CALC:
			if wheel != w_true:
				out.append({"act": "commit"})
		P.HORNER:
			if wheel != step_target():
				out.append({"act": "next_bit"})
		P.ROLL:
			if wheel != step_target():
				out.append({"act": "slide"})
		P.ALARM:
			out.append({"act": "report"})
			out.append({"act": "ignore"})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.W_CALC:
			out.append({"act": "wheel", "op": "minus_w"})
			out.append({"act": "wheel", "op": "plus1"})
			out.append({"act": "next_bit"})
			out.append({"act": "verify"})
		P.HORNER:
			out.append({"act": "wheel", "op": "minus_w"})
			out.append({"act": "commit"})
			out.append({"act": "slide"})
			out.append({"act": "ignore"})
		P.ROLL:
			out.append({"act": "verify"})
			out.append({"act": "report"})
			out.append({"act": "commit"})
			out.append({"act": "next_bit"})
		P.ALARM:
			out.append({"act": "wheel", "op": "double"})
			out.append({"act": "slide"})
	return out


func cursor() -> Dictionary:
	var pp := part
	if phase == P.ROLL:
		pp = "roll"
	return {"phase": phase, "phase_part": pp, "wheel": wheel, "w": w, "notch": hz, "i": i, "bit_k": bit_k,
		"bits": bits, "out_bit": t[i] if phase == P.ROLL and i < n else "",
		"in_bit": t[i + m] if phase == P.ROLL and i + m < n else "", "signal_index": si, "q": q,
		"did_double": did_double, "did_minus": did_minus}


func _render_extra() -> Dictionary:
	return {"history": hist.duplicate(true), "w_true": w_true, "hz_true": hz_true}


func tables() -> Dictionary:
	var rows: Array = []
	for h in hist:
		rows.append({"i": int(h.i), "yours": int(h.wheel), "correct": int(h["true"])})
	return {"kind": "wheel", "yours": rows, "correct": [], "w": [w, w_true], "hz": [hz, hz_true], "q": q}


func _snap() -> Dictionary:
	var wc := {}
	for kk in win_cause:
		wc[str(kk)] = win_cause[kk]
	var ig := {}
	for kk in ignored:
		ig[str(kk)] = ignored[kk]
	return {"w": w, "hz": hz, "wheel": wheel, "part": part, "bits": bits, "bit_k": bit_k, "wb": wb,
		"did_double": did_double, "did_minus": did_minus, "doubles": doubles, "i": i, "si": si,
		"queue": queue.duplicate(), "hist": hist.duplicate(true), "drift_seq": drift_seq, "notch_seq": notch_seq,
		"w_seq": w_seq, "horner_err": horner_err, "win_cause": wc, "ignored": ig}


func _restore(d: Dictionary) -> void:
	w = int(d.get("w", -1))
	hz = int(d.get("hz", -1))
	wheel = int(d.get("wheel", 0))
	part = str(d.get("part", ""))
	bits = str(d.get("bits", ""))
	bit_k = int(d.get("bit_k", 0))
	wb = int(d.get("wb", 0))
	did_double = bool(d.get("did_double", false))
	did_minus = bool(d.get("did_minus", false))
	doubles = int(d.get("doubles", 0))
	i = int(d.get("i", 0))
	si = int(d.get("si", 0))
	queue = []
	for x in d.get("queue", []):
		queue.append(str(x))
	hist = []
	for h in d.get("hist", []):
		var hd: Dictionary = _norm(h)
		hd["part"] = str(hd.get("part", ""))
		hist.append(hd)
	drift_seq = int(d.get("drift_seq", -1))
	notch_seq = int(d.get("notch_seq", -1))
	w_seq = int(d.get("w_seq", -1))
	horner_err = int(d.get("horner_err", -1))
	win_cause = {}
	var wc: Dictionary = d.get("win_cause", {})
	for kk in wc:
		win_cause[str(kk)] = int(wc[kk])
	ignored = {}
	var ig: Dictionary = d.get("ignored", {})
	for kk in ig:
		ignored[str(kk)] = int(ig[kk])
	_rekey()


## win_cause/ignored gebruiken int-sleutels; snapshot bewaart ze als strings (JSON).
func _rekey() -> void:
	var wc := {}
	for kk in win_cause:
		wc[int(kk)] = win_cause[kk]
	win_cause = wc
	var ig := {}
	for kk in ignored:
		ig[int(kk)] = ignored[kk]
	ignored = ig


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if wheel < 0 or wheel >= q:
		e.append("wiel %d buiten [0, q)" % wheel)
	if phase == P.ROLL and (i < 0 or i >= n - m):
		e.append("ROLL met venster %d" % i)
	for h in hist:
		if int(h["true"]) != true_hash(int(h.i)):
			e.append("historiek klopt niet")
			break
	return e
