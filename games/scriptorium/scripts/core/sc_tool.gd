class_name ScTool extends RefCounted
## Basisklasse van alle werktuigen (GDD §8.4). Pure logica: geen nodes, geen Engine/Time-calls.
##
## apply(move) → {"ok": bool, "verdict": int, "reason": String, "done": bool}
##   ok = false: klem; de staat verandert niet; changed({"fx":"bump"}) + logentry BUMP + phase_changed.
##   ok = true: uitgevoerd; verdict wordt vóór het uitvoeren bepaald (vergelijking met correct_move() in de toestand
##   van de speler). Automatische vervolgstappen gebeuren in dezelfde oproep (gelogd met auto = true).
## Signaalvolgorde per zet: changed(fx)… → counters_changed → output_changed / copy_changed → overkant_changed →
## event_logged… → phase_changed → eventueel stage_done.
## Subklassen implementeren _setup, _begin, _judge, _exec, _correct, _wrong, _impossible, _snap, _restore, _cursor,
## _output, _at, _invariants, structure.

signal changed(fx: Dictionary)
signal phase_changed(phase: int, cursor: Dictionary)
signal counters_changed(c: Dictionary)
signal output_changed(out: Dictionary)
signal copy_changed(copy: String)
signal overkant_changed(state: Dictionary)
signal event_logged(entry: Dictionary)
signal stage_done(result: Dictionary)

const V := ScCodes.Verdict
const P := ScCodes.Phase
const COUNTER_KEYS := ["ink", "twine", "search", "decisions", "bumps", "wasted", "zeros"]

var tool: int = -1
var side: int = ScCodes.Side.SEND
var stage: Dictionary = {}
var carry_in: Dictionary = {}
var phase: int = P.IDLE
var counters: Dictionary = {}
var log: ScEventLog = ScEventLog.new()
var stage_index: int = 0
var now: float = 0.0

var _fx: Array[Dictionary] = []
var _logged: Array[Dictionary] = []
var _in_batch := false
var _c0: Dictionary = {}
var _phase0: int = -1
var _out_dirty := false
var _copy_dirty := false
var _overkant_dirty := false
var _done := false
var _done_sent := false
var _moves := 0


# ------------------------------------------------------------------ opzet

func setup(stage_spec: Dictionary, carry := {}) -> void:
	stage = stage_spec.duplicate(true)
	carry_in = carry.duplicate(true)
	side = ScCodes.side_of(str(stage.get("side", "send")))
	phase = P.IDLE
	counters = {}
	for k in COUNTER_KEYS:
		counters[k] = 0
	_done = false
	_done_sent = false
	_moves = 0
	_setup()


func _setup() -> void:
	pass


## Eerste fase; voert automatische beginstappen uit. Logt STAGE_START (met snapshot).
func begin() -> void:
	log.now = now
	log.stage = stage_index
	_batch_start()
	_log("STAGE_START", {"tool": ScCodes.tool_name(tool), "side": "receive" if side == ScCodes.Side.RECEIVE else "send",
		"index": stage_index}, V.OK, true, {}, snapshot(), true)
	_fx.append({"fx": "stage", "index": stage_index, "tool": tool})
	_begin()
	_batch_end(true)


func _begin() -> void:
	pass


# ------------------------------------------------------------------ zetten

func apply(move: Dictionary) -> Dictionary:
	log.now = now
	log.stage = stage_index
	var is_auto := bool(move.get("auto", false))
	var hint := correct_move() if not is_auto else {}
	var before := snapshot()
	_batch_start()
	var j: Dictionary = {"ok": false, "reason": "wrong_phase"} if _done else _judge(move)
	if not bool(j.get("ok", false)):
		var reason := str(j.get("reason", "unknown"))
		counters.bumps = int(counters.bumps) + 1
		_fx.append({"fx": "bump", "reason": reason, "at": j.get("at", -1)})
		var bd: Dictionary = (j.get("data", {}) as Dictionary).duplicate(true)
		bd["reason"] = reason
		bd["move"] = move.duplicate(true)
		bd["at"] = _at()
		_log("BUMP", bd, V.BUMP, false, hint, before)
		_batch_end(true)
		return {"ok": false, "verdict": V.BUMP, "reason": reason, "done": _done}
	var verdict := int(j.get("verdict", V.OK))
	var data: Dictionary = (j.get("data", {}) as Dictionary).duplicate(true)
	data["move"] = move.duplicate(true)
	if not data.has("at"):
		data["at"] = _at()
	var keep := verdict != V.OK or _moves == 0
	if not is_auto and bool(j.get("decision", true)):
		counters.decisions = int(counters.decisions) + 1
	var e := _log(str(j.get("type", "MOVE")), data, verdict, true, hint, before if keep else {}, is_auto)
	_moves += 1
	_exec(move, j, e)
	_batch_end(true)
	return {"ok": true, "verdict": verdict, "reason": "", "done": _done}


## Beoordeelt een zet zonder iets te wijzigen: {ok, reason, verdict, type, data, decision}.
func _judge(_move: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "unknown_act"}


func _exec(_move: Dictionary, _j: Dictionary, _entry: Dictionary) -> void:
	pass


## Hover: muteert niets; toont nooit het verdict of de matchlengte.
func preview(move: Dictionary) -> Dictionary:
	if _done:
		return {"ok": false, "reason": "wrong_phase"}
	var j := _judge(move)
	return {"ok": bool(j.get("ok", false)), "reason": str(j.get("reason", ""))}


## Het orakel: de juiste volgende zet (relatief aan de toestand van de speler), of {"act":"none"}.
func correct_move() -> Dictionary:
	if _done:
		return {"act": "none"}
	return _correct()


func _correct() -> Dictionary:
	return {"act": "none"}


## Plausibele foute zetten met ok = true en verdict ≠ OK. Kan leeg zijn.
func wrong_moves() -> Array[Dictionary]:
	if _done:
		return []
	var out: Array[Dictionary] = []
	for m in _wrong():
		var j := _judge(m)
		if bool(j.get("ok", false)) and int(j.get("verdict", V.OK)) != V.OK:
			out.append(m)
	return out


func _wrong() -> Array[Dictionary]:
	return []


## Zetten die ok = false geven (kliktests).
func impossible_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _done:
		for m in _impossible():
			if not bool(_judge(m).get("ok", false)):
				out.append(m)
	out.append({"act": "__onbekend__"})
	return out


func _impossible() -> Array[Dictionary]:
	return []


func auto_finish() -> void:
	var guard := 0
	while not _done and guard < 100000:
		guard += 1
		var mv := correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		var r := apply(mv)
		if not bool(r.ok):
			push_warning("ScTool.auto_finish: orakelzet geweigerd: %s %s" % [str(mv), str(r)])
			break


func is_done() -> bool:
	return _done


## Huidige tekstpositie (voor oorzaakketens: entry.data.at).
func _at() -> int:
	return 0


# ------------------------------------------------------------------ uitvoer

func output() -> Dictionary:
	return _output()


func _output() -> Dictionary:
	return {}


func copy() -> String:
	return ""


func overkant() -> Dictionary:
	return {}


## Vergelijkbare structuur voor de terugblik (jouw werk naast het juiste).
func structure() -> Dictionary:
	return {}


# ------------------------------------------------------------------ stage-einde

func _finish() -> void:
	if _done:
		return
	_done = true
	phase = P.DONE
	_log("STAGE_END", {"output": output()}, V.OK, true, {}, {}, true)


# ------------------------------------------------------------------ batch / signalen

func _batch_start() -> void:
	_in_batch = true
	_fx.clear()
	_logged.clear()
	_c0 = counters.duplicate()
	_phase0 = phase
	_out_dirty = false
	_copy_dirty = false
	_overkant_dirty = false


func _batch_end(executed: bool) -> void:
	_in_batch = false
	var fx := _fx.duplicate()
	var lg := _logged.duplicate()
	_fx.clear()
	_logged.clear()
	for f in fx:
		changed.emit(f)
	if counters != _c0:
		counters_changed.emit(counters.duplicate())
	if _out_dirty:
		output_changed.emit(output())
	if _copy_dirty:
		copy_changed.emit(copy())
	if _overkant_dirty:
		overkant_changed.emit(overkant())
	for e in lg:
		event_logged.emit(e)
	if executed or phase != _phase0:
		phase_changed.emit(phase, cursor())
	if _done and not _done_sent:
		_done_sent = true
		stage_done.emit({"output": output(), "copy": copy(), "ink": int(counters.ink)})


func _log(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary,
		auto := false) -> Dictionary:
	log.now = now
	log.stage = stage_index
	if not data.has("at"):
		data["at"] = _at()
	var e := log.add(type, data, verdict, ok, hint, before, auto)
	_logged.append(e)
	return e


## Automatische stap: fx + logentry (auto = true).
func _auto(type: String, data: Dictionary, fx := {}) -> void:
	if not fx.is_empty():
		_fx.append(fx)
	_log(type, data, V.OK, true, {}, {}, true)


func _add_ink(n: int) -> void:
	counters.ink = int(counters.ink) + n
	_out_dirty = true


# ------------------------------------------------------------------ weergave

func cursor() -> Dictionary:
	var c := _cursor()
	c["phase"] = phase
	c["phase_name"] = ScCodes.phase_name(phase)
	return c


func _cursor() -> Dictionary:
	return {}


func render() -> Dictionary:
	var r := cursor()
	r.merge({"tool": tool, "side": side, "counters": counters.duplicate(), "done": _done, "output": output(),
		"copy": copy()}, true)
	r.merge(_render_extra(), true)
	return r


func _render_extra() -> Dictionary:
	return {}


# ------------------------------------------------------------------ snapshot

func snapshot() -> Dictionary:
	return {"tool": tool, "phase": phase, "counters": counters.duplicate(), "log_len": log.size(), "moves": _moves,
		"done": _done, "done_sent": _done_sent, "x": _snap()}


func restore(d: Dictionary) -> void:
	var dd: Dictionary = norm(d)
	phase = int(dd.get("phase", P.IDLE))
	var c: Dictionary = dd.get("counters", {})
	for k in COUNTER_KEYS:
		counters[k] = int(c.get(k, 0))
	log.truncate(int(dd.get("log_len", log.size())))
	_moves = int(dd.get("moves", 0))
	_done = bool(dd.get("done", false))
	_done_sent = bool(dd.get("done_sent", false))
	_restore(dd.get("x", {}))


func _snap() -> Dictionary:
	return {}


func _restore(_d: Dictionary) -> void:
	pass


## JSON-veilig: floats met gehele waarde → int (recursief).
static func norm(v):
	if v is float and is_equal_approx(v, round(v)) and absf(v) < 9.0e15:
		return int(v)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = norm(v[k])
		return d
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(norm(x))
		return a
	return v


static func ints(a) -> Array[int]:
	var out: Array[int] = []
	if a is Array or a is PackedInt32Array or a is PackedInt64Array:
		for x in a:
			out.append(int(x))
	return out


static func strs(a) -> Array[String]:
	var out: Array[String] = []
	if a is Array or a is PackedStringArray:
		for x in a:
			out.append(str(x))
	return out


# ------------------------------------------------------------------ invarianten

func invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	for k in counters:
		if int(counters[k]) < 0:
			errs.append("teller %s < 0" % k)
	if _done != (phase == P.DONE):
		errs.append("done %s maar fase %s" % [str(_done), ScCodes.phase_name(phase)])
	errs.append_array(_invariants())
	return errs


func _invariants() -> PackedStringArray:
	return PackedStringArray()
