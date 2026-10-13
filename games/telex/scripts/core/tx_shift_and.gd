class_name TxShiftAnd extends TxMachine
## Lampenbord en ruisbord (shift-AND, Definitie 13/14, Algoritme 6; GDD §3.5–3.6). k = 0: lampenbord; k ≥ 1: M⁰..M^k.
## CARDS: {"act":"hole","x":x,"i":r} (gat aan/uit), {"act":"cards_done"}.
## WIRE:  {"act":"plug","l":l,"src":"old_shift"|"old"|"new_shift"|"new"}, {"act":"wire_done"}.
## Doorloop per teken t[j]: {"act":"lever"} (shift¹ van elke kolom) en {"act":"card","x":x} (x = letter van z of ""
## = blanco; AND met C_x, OF-poorten voor l ≥ 1). Onderste lamp van kolom l aan → melding (level l).
## CHOOSE (6-2): {"act":"choose","start":p}. Start = "kolom −1" = nullen (p. 68).

var k: int = 0
var cards: Dictionary = {}       # letter -> Array[int] (gaten)
var wiring: Dictionary = {}      # l (int) -> stekker
var prev: Array = []             # kolommen van j−1 (k+1 stuks, ongeschoven)
var j: int = 0
var lever_pulled: bool = false
var do_run: bool = true
var do_choose: bool = false
var auto_lever: bool = false
var c_true: Dictionary = {}
var true_cols: Array = []        # [j][l] -> Array (correcte M^l met stekker old_shift)
var drift_seq: int = -1
var cards_seq: int = -1          # cards_done met foute gaten
var wire_seq: int = -1           # wire_done met foute bedrading
var col_cause: Dictionary = {}   # j -> drift_seq na kolom j
var chosen: int = -1


func _setup() -> void:
	kind = TxCodes.Machine.SHIFT_AND
	k = int(stage.get("k", 0))
	c_true = TxReference.c_vectors(z)
	do_run = bool(stage.get("run", true)) and t != ""
	do_choose = bool(stage.get("choose", false))
	auto_lever = bool(stage.get("auto_lever", false))
	match str(stage.get("cards", "punch")):
		"carry":
			cards = _card_dict(carry_in.get("c", {}))
		"prefilled":
			cards = _card_dict(c_true)
		_:
			cards = {}
			for x in c_true:
				cards[x] = TxReference.zeros(m)
	for x in c_true:
		if not cards.has(x):
			cards[x] = TxReference.zeros(m)
	wiring = {}
	match str(stage.get("wiring", "plug" if k > 0 else "prefilled")):
		"carry":
			wiring = _wire_dict(carry_in.get("wiring", {}))
		"prefilled":
			for l in range(1, k + 1):
				wiring[l] = "old_shift"
		_:
			pass
	prev = []
	for l in k + 1:
		prev.append(TxReference.zeros(m))
	j = 0
	lever_pulled = false
	true_cols = TxReference.shift_and_k(z, t, k).cols if t != "" else []
	drift_seq = -1
	var seqs: Dictionary = carry_in.get("seqs", {})
	cards_seq = int(seqs.get("cards", -1)) if str(stage.get("cards", "punch")) == "carry" else -1
	wire_seq = int(seqs.get("wire", -1)) if str(stage.get("wiring", "")) == "carry" else -1
	col_cause = {}
	chosen = -1


static func _card_dict(d) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for x in d:
			out[str(x)] = _ints(d[x])
	return out


static func _wire_dict(d) -> Dictionary:
	var out := {}
	if d is Dictionary:
		for l in d:
			out[int(l)] = str(d[l])
	return out


func _make_truth() -> Array[Dictionary]:
	if stage.has("truth"):
		return super._make_truth()
	var out: Array[Dictionary] = []
	for jj in range(m - 1, n):
		var mis := TxReference.mismatches_ending(z, t, jj)
		if mis <= k:
			out.append({"start": jj - m + 1, "end": jj, "level": mis})
	return out


func _hit_real(h: Dictionary) -> bool:
	if stage.has("truth"):
		return super._hit_real(h)
	return int(h.start) >= 0 and TxReference.mismatches_ending(z, t, int(h.end)) <= int(h.level)


func _passed(occ: Dictionary) -> bool:
	return int(occ.end) < j


func plugs() -> Array:
	var out: Array = []
	for l in range(1, k + 1):
		out.append(str(wiring.get(l, "")))
	return out


func cards_correct() -> bool:
	for x in c_true:
		if _ints(cards.get(x, [])) != _ints(c_true[x]):
			return false
	return true


func wiring_correct() -> bool:
	for l in range(1, k + 1):
		if str(wiring.get(l, "")) != "old_shift":
			return false
	return true


## Kolommen zoals ze nu op het bord staan (na de hendel: geschoven).
func shown_cols() -> Array:
	if not lever_pulled:
		return prev.duplicate(true)
	var out: Array = []
	for c in prev:
		out.append(TxReference.shift1(c))
	return out


func expected_card() -> String:
	if j >= n:
		return ""
	return t[j] if c_true.has(t[j]) else ""


func _begin() -> void:
	_next_phase(P.IDLE)


func _next_phase(from: int) -> void:
	if from == P.IDLE and str(stage.get("cards", "punch")) == "punch":
		phase = P.CARDS
		return
	if from in [P.IDLE, P.CARDS] and k > 0 and str(stage.get("wiring", "plug")) == "plug":
		phase = P.WIRE
		return
	if from in [P.IDLE, P.CARDS, P.WIRE] and do_run:
		phase = P.LEVER
		j = 0
		_fx.append({"fx": "ready", "start": 0})
		return
	if do_choose and t != "":
		phase = P.CHOOSE
		return
	_finish_stage()


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"hole":
			if phase != P.CARDS:
				return {"ok": false, "reason": "wrong_phase"}
			var x := str(move.get("x", ""))
			if not c_true.has(x):
				return {"ok": false, "reason": "no_card"}
			var r := int(move.get("i", -1))
			if r < 0 or r >= m:
				return {"ok": false, "reason": "range", "at": r}
			return {"ok": true, "verdict": V.OK, "type": "HOLE", "data": {"x": x, "i": r}}
		"cards_done":
			if phase != P.CARDS:
				return {"ok": false, "reason": "wrong_phase"}
			if cards_correct():
				return {"ok": true, "verdict": V.OK, "type": "CARDS_DONE"}
			var wd := {}
			for x in c_true:
				if _ints(cards.get(x, [])) != _ints(c_true[x]):
					var rows := PackedStringArray()
					for r in m:
						if z[r] == x:
							rows.append(str(r))
					wd = {"x": x, "rows": ", ".join(rows)}
					break
			return {"ok": true, "verdict": V.WRONG_HOLES, "type": "CARDS_DONE", "data": wd}
		"plug":
			if phase != P.WIRE:
				return {"ok": false, "reason": "wrong_phase"}
			var l := int(move.get("l", 0))
			var src := str(move.get("src", ""))
			if l < 1 or l > k or not TxCodes.PLUGS.has(src):
				return {"ok": false, "reason": "range", "at": l}
			return {"ok": true, "verdict": V.OK, "type": "PLUG", "data": {"l": l, "src": src}}
		"wire_done":
			if phase != P.WIRE:
				return {"ok": false, "reason": "wrong_phase"}
			if wiring_correct():
				return {"ok": true, "verdict": V.OK, "type": "WIRE_DONE"}
			var bl := 1
			for l in range(1, k + 1):
				if str(wiring.get(l, "")) != "old_shift":
					bl = l
					break
			return {"ok": true, "verdict": V.WRONG_WIRE, "type": "WIRE_DONE",
				"data": {"l": bl, "src": str(wiring.get(bl, ""))}}
		"lever":
			if phase == P.CARD:
				return {"ok": false, "reason": "already"}
			if phase != P.LEVER:
				return {"ok": false, "reason": "wrong_phase"}
			if j >= front:
				return {"ok": false, "reason": "not_now"}
			return {"ok": true, "verdict": V.OK, "type": "LEVER", "data": {"j": j}}
		"card":
			if phase != P.LEVER and phase != P.CARD:
				return {"ok": false, "reason": "wrong_phase"}
			var x2 := str(move.get("x", ""))
			if x2 != "" and not c_true.has(x2):
				return {"ok": false, "reason": "no_card"}
			var xs := expected_card()
			var vd := V.OK
			if not lever_pulled:
				vd = V.NO_SHIFT
			elif x2 != xs:
				vd = V.LATE if bool(move.get("late", false)) else V.WRONG_CARD
			return {"ok": true, "verdict": vd, "type": "CARD",
				"data": {"j": j, "x": t[j], "card": xs if xs != "" else "blanco", "given": x2}}
		"choose":
			if phase != P.CHOOSE:
				return {"ok": false, "reason": "wrong_phase"}
			var p := int(move.get("start", -1))
			if p < 0 or p > n - m:
				return {"ok": false, "reason": "range", "at": p}
			var exact := TxReference.mismatches_ending(z, t, p + m - 1) == 0
			return {"ok": true, "verdict": V.OK if exact else V.WRONG_PICK, "type": "CHOOSE",
				"data": {"start": p, "z": z}}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, jd: Dictionary, e: Dictionary) -> void:
	match str(move.act):
		"hole":
			var x := str(move.x)
			var r := int(move.i)
			var col: Array[int] = _ints(cards[x])
			col[r] = 1 - col[r]
			cards[x] = col
			_fx.append({"fx": "hole", "x": x, "i": r, "on": col[r] == 1})
		"cards_done":
			cards_seq = -1 if int(jd.verdict) == V.OK else int(e.seq)
			_next_phase(P.CARDS)
		"plug":
			wiring[int(move.l)] = str(move.src)
			_fx.append({"fx": "plug", "l": int(move.l), "src": str(move.src)})
		"wire_done":
			wire_seq = -1 if int(jd.verdict) == V.OK else int(e.seq)
			_next_phase(P.WIRE)
		"lever":
			lever_pulled = true
			_fx.append({"fx": "lever", "cols": shown_cols(), "j": j})
			phase = P.CARD
		"card":
			_card(str(move.x), int(jd.verdict), e)
		"choose":
			var p := int(move.start)
			chosen = p
			_fx.append({"fx": "choose", "start": p, "real": int(jd.verdict) == V.OK})
			if int(jd.verdict) != V.OK:
				_false_alarm({"start": p, "end": p + m - 1, "level": 0}, {"machine": "shift_and", "end": p + m - 1},
						false)
			_finish_stage()


func _card(x: String, verdict: int, e: Dictionary) -> void:
	var cx: Array = cards.get(x, TxReference.zeros(m)) if x != "" else TxReference.zeros(m)
	var cur := TxReference.mk_step(prev, cx, plugs(), lever_pulled)
	counters.lamps = int(counters.lamps) + 1
	_fx.append({"fx": "card", "x": x, "j": j, "cols": cur.duplicate(true)})
	_fx.append({"fx": "column", "j": j, "cols": cur.duplicate(true)})
	# oorzaakketen: wijkt het bord af van de echte M^l?
	var tc: Array = true_cols[j] if j < true_cols.size() else []
	if _same_cols(cur, tc):
		drift_seq = -1
	elif drift_seq < 0:
		if verdict != V.OK:
			drift_seq = int(e.seq)
		elif wire_seq >= 0:
			drift_seq = wire_seq
		elif cards_seq >= 0:
			drift_seq = cards_seq
		else:
			drift_seq = int(e.seq)
	col_cause[j] = drift_seq
	prev = cur
	lever_pulled = false
	for l in k + 1:
		if int(cur[l][m - 1]) == 1:
			var st := j - m + 1
			var real := st >= 0 and TxReference.mismatches_ending(z, t, j) <= l
			if stage.has("truth"):
				real = _is_true(maxi(0, st), j)
			var h := _report(maxi(0, st), j, l, real)
			if not real:
				_false_alarm(h, {"machine": "shift_and", "end": j}, true, drift_seq if drift_seq >= 0 else _cause)
	j += 1
	_check_passed()
	if j >= n:
		_next_phase(P.LEVER)
	else:
		phase = P.LEVER


static func _same_cols(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for l in a.size():
		if _ints(a[l]) != _ints(b[l]):
			return false
	return true


func _cause_for(occ: Dictionary) -> int:
	var c := int(col_cause.get(int(occ.end), -1))
	return c if c >= 0 else _cause


func need() -> int:
	return -1 if _done or phase in [P.CARDS, P.WIRE, P.CHOOSE] else j


func _miss_line() -> int:
	return j


func _force(s: int) -> void:
	prev = []
	for l in k + 1:
		prev.append(TxReference.zeros(m))
	lever_pulled = false
	j = s
	drift_seq = _cause
	_fx.append({"fx": "column", "j": j, "cols": prev.duplicate(true), "reset": true})
	_check_passed()
	if j >= n:
		_next_phase(P.LEVER)
	else:
		phase = P.LEVER


func exact_starts() -> Array[int]:
	var out: Array[int] = []
	for o in truth:
		if int(o.level) == 0:
			out.append(int(o.start))
	return out


func _correct() -> Dictionary:
	match phase:
		P.CARDS:
			for x in c_true:
				var have: Array[int] = _ints(cards.get(x, []))
				var want: Array[int] = _ints(c_true[x])
				for r in m:
					if r >= have.size() or have[r] != want[r]:
						return {"act": "hole", "x": x, "i": r}
			return {"act": "cards_done"}
		P.WIRE:
			for l in range(1, k + 1):
				if str(wiring.get(l, "")) != "old_shift":
					return {"act": "plug", "l": l, "src": "old_shift"}
			return {"act": "wire_done"}
		P.LEVER:
			if j >= front:
				return {"act": "none"}
			return {"act": "lever"}
		P.CARD:
			return {"act": "card", "x": expected_card()}
		P.CHOOSE:
			var ex := exact_starts()
			if not ex.is_empty():
				return {"act": "choose", "start": ex[0]}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CARDS:
			if not cards_correct():
				out.append({"act": "cards_done"})
		P.WIRE:
			if not wiring_correct():
				out.append({"act": "wire_done"})
		P.LEVER:
			out.append({"act": "card", "x": expected_card()})
		P.CARD:
			var xs := expected_card()
			if xs == "":
				out.append({"act": "card", "x": str(c_true.keys()[0])})
			else:
				out.append({"act": "card", "x": ""})
		P.CHOOSE:
			var ex := exact_starts()
			for o in truth:
				if int(o.level) > 0 and not ex.has(int(o.start)):
					out.append({"act": "choose", "start": int(o.start)})
					break
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.CARDS:
			out.append({"act": "hole", "x": "#", "i": 0})
			out.append({"act": "hole", "x": str(c_true.keys()[0]), "i": m})
			out.append({"act": "lever"})
		P.WIRE:
			out.append({"act": "plug", "l": k + 1, "src": "old_shift"})
			out.append({"act": "plug", "l": 1, "src": "nergens"})
			out.append({"act": "card", "x": ""})
		P.LEVER:
			out.append({"act": "card", "x": "#"})
			out.append({"act": "plug", "l": 1, "src": "old_shift"})
		P.CARD:
			out.append({"act": "lever"})
			out.append({"act": "card", "x": "#"})
		P.CHOOSE:
			out.append({"act": "lever"})
			out.append({"act": "choose", "start": n})
	return out


func cursor() -> Dictionary:
	var c := {"phase": phase, "j": j, "ch": t[j] if j < n else "", "lever_pulled": lever_pulled,
		"cols": shown_cols(), "cards": _cards_copy(), "wiring": wiring.duplicate(), "k": k}
	if bool(stage.get("tutorial", false)) and (phase == P.LEVER or phase == P.CARD):
		c["expected_card"] = expected_card()
	return c


func _cards_copy() -> Dictionary:
	var out := {}
	for x in cards:
		out[x] = _ints(cards[x])
	return out


func _render_extra() -> Dictionary:
	return {"c_true": c_true.duplicate(true), "chosen": chosen}


func tables() -> Dictionary:
	var wt := {}
	for l in range(1, k + 1):
		wt[l] = "old_shift"
	return {"kind": "c", "yours": _cards_copy(), "correct": c_true.duplicate(true), "wiring": wiring.duplicate(),
		"wiring_correct": wt}


func _output() -> Dictionary:
	var w := {}
	for l in wiring:
		w[l] = wiring[l]
	var seqs: Dictionary = (carry_in.get("seqs", {}) as Dictionary).duplicate()
	if cards_seq >= 0:
		seqs["cards"] = cards_seq
	elif phase != P.CARDS and str(stage.get("cards", "")) == "punch":
		seqs.erase("cards")
	if wire_seq >= 0:
		seqs["wire"] = wire_seq
	elif k > 0 and str(stage.get("wiring", "")) == "plug":
		seqs.erase("wire")
	return {"c": _cards_copy(), "wiring": w, "seqs": seqs}


func _snap() -> Dictionary:
	var w := {}
	for l in wiring:
		w[str(l)] = wiring[l]
	var cc := {}
	for kk in col_cause:
		cc[str(kk)] = col_cause[kk]
	var pv: Array = []
	for c in prev:
		pv.append(_ints(c))
	return {"cards": _cards_copy(), "wiring": w, "prev": pv, "j": j, "lever": lever_pulled, "drift_seq": drift_seq,
		"cards_seq": cards_seq, "wire_seq": wire_seq, "col_cause": cc, "chosen": chosen}


func _restore(d: Dictionary) -> void:
	cards = _card_dict(d.get("cards", {}))
	wiring = _wire_dict(d.get("wiring", {}))
	prev = []
	for c in d.get("prev", []):
		prev.append(_ints(c))
	j = int(d.get("j", 0))
	lever_pulled = bool(d.get("lever", false))
	drift_seq = int(d.get("drift_seq", -1))
	cards_seq = int(d.get("cards_seq", -1))
	wire_seq = int(d.get("wire_seq", -1))
	col_cause = {}
	var cc: Dictionary = d.get("col_cause", {})
	for kk in cc:
		col_cause[int(kk)] = int(cc[kk])
	chosen = int(d.get("chosen", -1))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	if prev.size() != k + 1:
		e.append("aantal kolommen %d ≠ k+1" % prev.size())
	for c in prev:
		if (c as Array).size() != m:
			e.append("kolomlengte ≠ m")
			break
	for l in range(1, k + 1):
		if j > 0 and int(prev[l][0]) != 1:
			e.append("voedingslamp van M^%d brandt niet" % l)
	if phase in [P.LEVER, P.CARD] and (j < 0 or j >= n):
		e.append("doorloop met j = %d" % j)
	# zolang het bord correct is bedraad en geponst en er geen foute kaart viel, is het bord = Definitie 14
	if drift_seq < 0 and j > 0 and j <= true_cols.size() and not _same_cols(prev, true_cols[j - 1]):
		e.append("bord wijkt af van Definitie 14 zonder oorzaak")
	return e
