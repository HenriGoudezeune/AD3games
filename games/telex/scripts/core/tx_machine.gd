class_name TxMachine extends RefCounted
## Basisklasse van alle Telex-machines (GDD §8.4): lint/stroom, tellers, waarheid, gevolgen, log, snapshot,
## apply/orakel. Pure logica: geen nodes, geen Engine/Time-calls. Subklassen implementeren de _-methodes.
##
## apply(move) -> {"ok": bool, "verdict": int, "reason": String, "done": bool}
##   ok = false: klem (fysiek onmogelijk); de staat verandert niet, er volgt changed({"fx":"bump"}) + logentry BUMP.
##   ok = true: uitgevoerd; verdict wordt vóór het uitvoeren bepaald. Automatische vervolgstappen (naald, auto_zero,
##   auto_strip, …) gebeuren in dezelfde oproep en worden gelogd met auto = true.
## Signaalvolgorde per zet: alle changed(fx) → counters_changed → reported → consequence → event_logged →
## phase_changed → eventueel stage_done.

signal changed(fx: Dictionary)
signal phase_changed(phase: int, cursor: Dictionary)
signal counters_changed(c: Dictionary)
signal reported(hit: Dictionary)
signal consequence(ev: Dictionary)
signal event_logged(entry: Dictionary)
signal stage_done(result: Dictionary)

const V := TxCodes.Verdict
const P := TxCodes.Phase
const EMPTY := TxCodes.STRIP_EMPTY
const BURNT := TxCodes.STRIP_BURNT

var kind: int = -1                 # TxCodes.Machine
var stage: Dictionary = {}         # stage-spec (GDD §8.5)
var carry_in: Dictionary = {}
var z: String = ""
var t: String = ""
var n: int = 0
var m: int = 0
var find: int = TxCodes.Find.FIRST
var mode: int = TxCodes.Mode.CALM
var front: int = 0                 # binnengekomen tekens (CALM: n)
var shred: int = 0                 # posities < shred zijn vernietigd
var buffer: int = -1               # B (LIVE), −1 = onbeperkt
var phase: int = P.IDLE
var counters: Dictionary = {}
var truth: Array[Dictionary] = []  # echte voorkomens [{start, end, level}]
var hits: Array[Dictionary] = []   # gemelde [{start, end, level, real}]
var missed: Array[Dictionary] = [] # [{start, end, level, cause_seq}]
var false_alarms: Array[Dictionary] = []
var log: TxEventLog = TxEventLog.new()
var now: float = 0.0
var stage_index: int = 0

var _fx: Array[Dictionary] = []
var _reports: Array[Dictionary] = []
var _conseq: Array[Dictionary] = []
var _logged: Array[Dictionary] = []
var _in_batch := false
var _c0: Dictionary = {}
var _phase0: int = -1
var _done := false
var _done_sent := false
var _moves := 0
var _cause := -1                   # seq van het event dat nu verwerkt wordt (oorzaak van gevolgen)


# ------------------------------------------------------------------ opzet

## live = {"B": int} voor LIVE-stages (front start op 0); leeg = CALM (front = n).
func setup(stage_spec: Dictionary, carry := {}, live := {}) -> void:
	stage = stage_spec.duplicate(true)
	carry_in = carry.duplicate(true)
	z = str(stage.get("z", ""))
	t = str(stage.get("t", ""))
	n = t.length()
	m = z.length()
	find = TxCodes.Find.ALL if str(stage.get("find", "first")) == "all" else TxCodes.Find.FIRST
	if live.is_empty():
		mode = TxCodes.Mode.CALM
		front = n
		buffer = -1
	else:
		mode = TxCodes.Mode.LIVE
		front = 0
		buffer = int(live.get("B", -1))
	shred = 0
	phase = P.IDLE
	counters = {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "rewind": 0, "alignments": 0, "bumps": 0}
	hits = []
	missed = []
	false_alarms = []
	_done = false
	_done_sent = false
	_moves = 0
	_setup()
	truth = _make_truth()


func _setup() -> void:
	pass


func _make_truth() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if stage.has("truth"):
		for o in stage.truth:
			out.append({"start": int(o.start), "end": int(o.end), "level": int(o.get("level", 0))})
		return out
	if m == 0 or n == 0:
		return out
	for p in TxReference.occurrences(z, t, str(stage.get("joker", ""))):
		out.append({"start": p, "end": p + m - 1, "level": 0})
	return out


## Start de stage: fase READY (naaldmachines) of de eerste voorbereidingsfase. Logt STAGE_START.
func begin() -> void:
	log.now = now
	log.stage = stage_index
	_batch_start()
	var before := snapshot()
	_log("STAGE_START", {"machine": TxCodes.machine_name(kind), "z": z, "t": t, "index": stage_index}, V.OK, true,
			{}, before, true)
	_fx.append({"fx": "stage", "index": stage_index, "machine": kind})
	_begin()
	_batch_end(true)


func _begin() -> void:
	pass


# ------------------------------------------------------------------ zetten

func apply(move: Dictionary) -> Dictionary:
	log.now = now
	log.stage = stage_index
	var hint := correct_move() if not bool(move.get("auto", false)) else {}
	var before := snapshot()
	_batch_start()
	var j: Dictionary = {"ok": false, "reason": "wrong_phase"} if _done else _judge(move)
	if not bool(j.get("ok", false)):
		var reason := str(j.get("reason", "bump"))
		counters.bumps = int(counters.bumps) + 1
		_fx.append({"fx": "bump", "reason": reason, "at": j.get("at", -1)})
		var bd: Dictionary = (j.get("data", {}) as Dictionary).duplicate(true)
		bd["reason"] = reason
		bd["move"] = move.duplicate(true)
		_log("BUMP", bd, V.BUMP, false, hint, before)
		_batch_end(false)
		return {"ok": false, "verdict": V.BUMP, "reason": reason, "done": _done}
	var verdict := int(j.get("verdict", V.OK))
	var data: Dictionary = (j.get("data", {}) as Dictionary).duplicate(true)
	data["move"] = move.duplicate(true)
	var keep := verdict != V.OK or _moves == 0
	var e := _log(str(j.get("type", "MOVE")), data, verdict, true, hint, before if keep else {},
			bool(move.get("auto", false)))
	_moves += 1
	var pc := _cause
	_cause = int(e.seq)
	_exec(move, j, e)
	if not _done and over_budget():
		abort("budget")
	_cause = pc
	_batch_end(true)
	return {"ok": true, "verdict": verdict, "reason": "", "done": _done}


## Beoordeelt een zet zonder iets te wijzigen: {ok, reason, verdict, type, data, at, …}.
func _judge(_move: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "unknown_act"}


## Voert een beoordeelde zet uit (incl. automatische vervolgstappen).
func _exec(_move: Dictionary, _j: Dictionary, _entry: Dictionary) -> void:
	pass


## Muteert niets: {ok, reason, mesh, s, …} (slepen, tanden, sprongdoel).
func preview(move: Dictionary) -> Dictionary:
	var j := _judge(move)
	return {"ok": bool(j.get("ok", false)), "reason": str(j.get("reason", "")), "verdict": int(j.get("verdict", V.OK))}


## Het orakel: de juiste volgende zet, of {"act":"none"}.
func correct_move() -> Dictionary:
	if _done:
		return {"act": "none"}
	return _correct()


func _correct() -> Dictionary:
	return {"act": "none"}


## Plausibele foute zetten met ok = true en verdict ≠ OK (bots, QA). Kan leeg zijn.
func wrong_moves() -> Array[Dictionary]:
	if _done:
		return []
	return _wrong()


func _wrong() -> Array[Dictionary]:
	return []


## Zetten die ok = false geven (kliktests).
func impossible_moves() -> Array[Dictionary]:
	if _done:
		return [{"act": "go"}]
	var out := _impossible()
	out.append({"act": "__onbekend__"})
	return out


func _impossible() -> Array[Dictionary]:
	return []


## Speelt de stage verder met correct_move().
func auto_finish() -> void:
	var guard := 0
	while not _done and guard < 100000:
		guard += 1
		var mv := correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		var r := apply(mv)
		if not bool(r.ok):
			push_warning("TxMachine.auto_finish: orakelzet geweigerd: %s %s" % [str(mv), str(r)])
			break


func is_done() -> bool:
	return _done


# ------------------------------------------------------------------ stroom (LIVE, GDD §2.5)

## De kleinste positie die de machine nog nodig heeft (−1 = niet van toepassing).
func need() -> int:
	return -1


## Voorkomens met start < _miss_line() zijn voorbij (gemist als ze niet gemeld werden).
func _miss_line() -> int:
	return -1


## LIVE: nieuwe tekens. f mag voorbij n gaan (het lint loopt door, de versnipperaar ook): front blijft ≤ n,
## shred = max(0, f − B). Laat een wachtende naald verder lopen en controleert op een scheur.
func set_front(f: int) -> void:
	if mode != TxCodes.Mode.LIVE or _done:
		return
	var nf := clampi(f, front, n)
	var ns := shred
	if buffer >= 0:
		ns = clampi(f - buffer, shred, n)
	if nf == front and ns == shred:
		return
	log.now = now
	log.stage = stage_index
	var own := not _in_batch
	if own:
		_batch_start()
	if nf != front:
		front = nf
		_fx.append({"fx": "front", "to": front})
	if ns != shred:
		shred = ns
		_fx.append({"fx": "shred", "upto": shred})
	_tear_check()
	if phase == P.WAIT_TAPE and not _done:
		_resume()
	_tear_check()
	if own:
		_batch_end(false)


func _resume() -> void:
	pass


func _tear_check() -> void:
	var guard := 0
	while buffer >= 0 and not _done and guard < 1000:
		guard += 1
		var nd := need()
		if nd < 0 or shred <= nd:
			return
		force_to(shred)


## Scheur (GDD §2.5): logt TEAR, verplaatst de machine naar s, markeert gemiste voorkomens.
func force_to(s: int) -> void:
	var own := not _in_batch
	if own:
		_batch_start()
	var old := need()
	var e := _log("TEAR", {"from": old, "to": s}, V.TEAR, true, {}, {}, true)
	_conseq.append({"kind": "tear", "start": old, "end": s, "cause_seq": int(e.seq)})
	_fx.append({"fx": "tear", "from": old, "to": s})
	var pc := _cause
	_cause = int(e.seq)
	_force(s)
	_check_passed()
	_cause = pc
	if own:
		_batch_end(false)


func _force(_s: int) -> void:
	pass


# ------------------------------------------------------------------ waarheid, meldingen, gevolgen

## stage "match_end": een melding vindt een voorkomen als het einde klopt (finale F-2: verminkte codewoorden).
func match_end() -> bool:
	return bool(stage.get("match_end", false))


func _occ_found(occ: Dictionary) -> bool:
	for h in hits:
		if bool(h.real) and int(h.end) == int(occ.end) and (match_end() or int(h.start) == int(occ.start)):
			return true
	return false


func _occ_missed(occ: Dictionary) -> bool:
	for x in missed:
		if int(x.start) == int(occ.start) and int(x.end) == int(occ.end):
			return true
	return false


## Is (start, end) een echt voorkomen?
func _is_true(start: int, end: int) -> bool:
	for o in truth:
		if int(o.end) == end and (match_end() or int(o.start) == start):
			return true
	return false


## Echte voorkomens die nog niet gemeld of gemist zijn.
func open_truth() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in truth:
		if not _occ_found(o) and not _occ_missed(o):
			out.append(o)
	return out


func found_count() -> int:
	var c := 0
	for o in truth:
		if _occ_found(o):
			c += 1
	return c


## Melding (bel + koker). real = null: bepaald door de waarheid.
func _report(start: int, end: int, level: int = 0, real = null, extra := {}) -> Dictionary:
	var is_real: bool = _is_true(start, end) if real == null else bool(real)
	var hit := {"start": start, "end": end, "level": level, "real": is_real}
	hits.append(hit)
	_reports.append(hit)
	_fx.append({"fx": "hit", "start": start, "end": end, "level": level, "real": is_real})
	var d := {"start": start, "end": end, "level": level, "real": is_real}
	d.merge(extra)
	_log("HIT", d, V.OK, true, {}, {}, true)
	return hit


## Vals alarm (ploeg vertrekt). log_entry = false als de zet zelf al verdict FALSE_ALARM kreeg.
func _false_alarm(hit: Dictionary, data := {}, log_entry := true, cause := -2) -> void:
	var c := _cause if cause == -2 else cause
	false_alarms.append({"start": int(hit.start), "end": int(hit.end), "level": int(hit.get("level", 0)),
		"cause_seq": c})
	_conseq.append({"kind": "false_alarm", "start": int(hit.start), "end": int(hit.end), "cause_seq": c})
	_fx.append({"fx": "false_alarm", "start": int(hit.start), "end": int(hit.end)})
	_affect(c, int(hit.start))
	if log_entry:
		var d := {"start": int(hit.start), "end": int(hit.end), "cause_seq": c, "z": z}
		d.merge(data)
		_log("FALSE_ALARM", d, V.FALSE_ALARM, true, {}, {}, true)


## Voorkomens die de machine voorbij is zonder melding → gemist.
func _check_passed() -> void:
	for o in truth:
		if _occ_found(o) or _occ_missed(o):
			continue
		if _passed(o):
			_mark_missed(o)


func _passed(occ: Dictionary) -> bool:
	return int(occ.start) < _miss_line()


## Oorzaak van een gemist voorkomen (subklassen: bv. de eerste foute wielstand).
func _cause_for(_occ: Dictionary) -> int:
	return _cause


func _mark_missed(occ: Dictionary) -> void:
	var c := _cause_for(occ)
	missed.append({"start": int(occ.start), "end": int(occ.end), "level": int(occ.get("level", 0)), "cause_seq": c})
	_conseq.append({"kind": "missed", "start": int(occ.start), "end": int(occ.end), "cause_seq": c})
	_fx.append({"fx": "missed", "start": int(occ.start), "end": int(occ.end)})
	_affect(c, int(occ.start))
	_log("MISSED", {"start": int(occ.start), "end": int(occ.end), "z": z, "cause_seq": c,
		"cause": describe(log.entry(c))}, V.MISSED, true, {}, {}, true)


func _affect(seq: int, start: int) -> void:
	var e := log.entry(seq)
	if e.is_empty():
		return
	var aff: Array = e.affects
	if not aff.has(start):
		aff.append(start)


## Korte beschrijving van een event (oorzaak in coachzinnen).
static func describe(e: Dictionary) -> String:
	if e.is_empty():
		return "de laatste zet"
	var d: Dictionary = e.get("data", {})
	var mv: Dictionary = d.get("move", {})
	var w := ""
	match str(e.type):
		"SHIFT", "STRIP":
			w = "de verschuiving %d" % int(d.get("s", mv.get("s", 0)))
		"KEY":
			w = "het sleutelteken"
		"JUMP":
			w = "de sprong %d" % int(d.get("s", mv.get("s", 0)))
		"SLIDE":
			w = "venster %d" % int(d.get("i", 0))
		"BIT", "COMMIT":
			w = "het ijken"
		"IGNORE":
			w = "Negeer bij venster %d" % int(d.get("i", 0))
		"CARD":
			w = "de kaart op %d" % int(d.get("j", 0))
		"LEVER":
			w = "de hendel op %d" % int(d.get("j", 0))
		"CARDS_DONE":
			w = "de kaarten"
		"WIRE_DONE":
			w = "de bedrading"
		"TEAR":
			w = "de scheur"
		"PICK_END":
			w = "het gekozen einde"
		_:
			w = str(e.type).to_lower()
	var vn := TxCodes.verdict_name(int(e.verdict))
	if int(e.verdict) != V.OK:
		return "%s (%s, zet %d)" % [w, vn, int(e.seq)]
	return "%s (zet %d)" % [w, int(e.seq)]


# ------------------------------------------------------------------ stage-einde

func _finish_stage() -> void:
	if _done:
		return
	_done = true
	phase = P.DONE
	_log("STAGE_END", {"hits": hits.size(), "missed": missed.size(), "false_alarms": false_alarms.size()}, V.OK,
			true, {}, {}, true)


## Machinetijd (finale): tik = lampslag = relais = wielslag = 1.
func machine_time() -> int:
	return int(counters.ticks) + int(counters.lamps) + int(counters.relays) + int(counters.wheel)


func budget() -> int:
	return int(stage.get("budget", 0))


func over_budget() -> bool:
	return budget() > 0 and machine_time() >= budget()


## Breekt de stage af (budget op, director): alle open echte voorkomens zijn gemist (oorzaak: dit event).
func abort(reason: String) -> void:
	if _done:
		return
	var own := not _in_batch
	if own:
		_batch_start()
	var e := _log("ABORT", {"reason": reason, "machine_time": machine_time()}, V.OK, true, {}, {}, true)
	_fx.append({"fx": "abort", "reason": reason})
	var pc := _cause
	_cause = int(e.seq)
	for o in open_truth():
		_mark_missed(o)
	_cause = pc
	_finish_stage()
	if own:
		_batch_end(false)


## Jouw tabel naast de juiste (debrief): {kind, yours, correct, …} of {}.
func tables() -> Dictionary:
	return {}


## carry voor de volgende stage (cumulatief: bevat ook de ontvangen carry).
func output() -> Dictionary:
	var out := carry_in.duplicate(true)
	out.merge(_output(), true)
	return out


func _output() -> Dictionary:
	return {}


# ------------------------------------------------------------------ batch / signalen

func _batch_start() -> void:
	_in_batch = true
	_fx.clear()
	_reports.clear()
	_conseq.clear()
	_logged.clear()
	_c0 = counters.duplicate()
	_phase0 = phase


func _batch_end(executed: bool) -> void:
	_in_batch = false
	var fx := _fx.duplicate()
	var rep := _reports.duplicate()
	var con := _conseq.duplicate()
	var lg := _logged.duplicate()
	_fx.clear()
	_reports.clear()
	_conseq.clear()
	_logged.clear()
	for f in fx:
		changed.emit(f)
	if counters != _c0:
		counters_changed.emit(counters.duplicate())
	for h in rep:
		reported.emit(h)
	for c in con:
		consequence.emit(c)
	for e in lg:
		event_logged.emit(e)
	if executed or phase != _phase0:
		phase_changed.emit(phase, cursor())
	if _done and not _done_sent:
		_done_sent = true
		stage_done.emit({"ok": true, "output": output(), "hits": hits.duplicate(true),
			"missed": missed.duplicate(true), "false_alarms": false_alarms.duplicate(true)})


func _log(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary,
		auto := false) -> Dictionary:
	log.now = now
	log.stage = stage_index
	var e := log.add(type, data, verdict, ok, hint, before, auto)
	_logged.append(e)
	return e


# ------------------------------------------------------------------ weergave

## Wat de UI moet tonen/markeren (per subklasse uitgebreid; GDD §8.7).
func cursor() -> Dictionary:
	return {"phase": phase}


## Volledige tekenstaat.
func render() -> Dictionary:
	var r := cursor()
	r.merge({"kind": kind, "z": z, "t": t, "n": n, "m": m, "find": find, "mode": mode, "front": front,
		"shred": shred, "buffer": buffer, "counters": counters.duplicate(), "hits": hits.duplicate(true),
		"missed": missed.duplicate(true), "false_alarms": false_alarms.duplicate(true), "need": need(),
		"done": _done}, true)
	r.merge(_render_extra(), true)
	return r


func _render_extra() -> Dictionary:
	return {}


# ------------------------------------------------------------------ snapshot

func snapshot() -> Dictionary:
	return {
		"kind": kind, "phase": phase, "front": front, "shred": shred, "buffer": buffer,
		"counters": counters.duplicate(), "hits": hits.duplicate(true), "missed": missed.duplicate(true),
		"false_alarms": false_alarms.duplicate(true), "log_len": log.size(), "moves": _moves, "done": _done,
		"done_sent": _done_sent, "x": _snap(),
	}


func restore(d: Dictionary) -> void:
	phase = int(d.get("phase", P.IDLE))
	front = int(d.get("front", n))
	shred = int(d.get("shred", 0))
	buffer = int(d.get("buffer", -1))
	var c: Dictionary = d.get("counters", {})
	for k in ["ticks", "wheel", "lamps", "relays", "rewind", "alignments", "bumps"]:
		counters[k] = int(c.get(k, 0))
	hits = _dicts(d.get("hits", []))
	missed = _dicts(d.get("missed", []))
	false_alarms = _dicts(d.get("false_alarms", []))
	log.truncate(int(d.get("log_len", log.size())))
	_moves = int(d.get("moves", 0))
	_done = bool(d.get("done", false))
	_done_sent = bool(d.get("done_sent", false))
	_cause = -1
	_restore(d.get("x", {}))


func _snap() -> Dictionary:
	return {}


func _restore(_d: Dictionary) -> void:
	pass


## JSON-veilige conversies (JSON maakt van ints floats).
static func _ints(a) -> Array[int]:
	var out: Array[int] = []
	if a is Array or a is PackedInt32Array or a is PackedInt64Array:
		for x in a:
			out.append(int(x))
	return out


static func _dicts(a) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if a is Array:
		for x in a:
			if x is Dictionary:
				out.append(_norm(x))
	return out


## Zet floats met gehele waarde om naar int (recursief).
static func _norm(v):
	if v is float and is_equal_approx(v, round(v)):
		return int(v)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _norm(v[k])
		return d
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(_norm(x))
		return a
	return v


# ------------------------------------------------------------------ invarianten

func invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	if front < 0 or front > n:
		errs.append("front %d buiten [0, %d]" % [front, n])
	if shred < 0 or shred > front:
		errs.append("shred %d buiten [0, front=%d]" % [shred, front])
	for k in counters:
		if int(counters[k]) < 0:
			errs.append("teller %s < 0" % k)
	for h in hits:
		if bool(h.real) != _hit_real(h):
			errs.append("melding %s: real klopt niet" % str(h))
	for x in missed:
		if _occ_found(x):
			errs.append("voorkomen @%d zowel gevonden als gemist" % int(x.start))
	if _done != (phase == P.DONE):
		errs.append("done %s maar fase %s" % [str(_done), TxCodes.phase_name(phase)])
	errs.append_array(_invariants())
	return errs


func _hit_real(h: Dictionary) -> bool:
	return _is_true(int(h.start), int(h.end))


func _invariants() -> PackedStringArray:
	return PackedStringArray()
