class_name TxDirector extends RefCounted
## Speelt een level (GDD §8.8): stages en carry, LIVE-klok (front, lusbak, waarschuwing), ritme (hendel op de tel,
## blanco na de tel), rivaal (3-5), automatische doorloop (finale), hint, terugnemen, Nachtdienst, einde + rapport.
## Puur: geen nodes. De front-end roept tick(dt) per frame en apply(move) voor zetten; luistert naar stage_started
## (verbindt dan de signalen van de machine; begin() volgt meteen daarna) en level_finished.
## Opslaan (TxSave.record) doet de front-end met het rapport.

signal stage_started(index: int, machine: TxMachine)
signal beat(j: int)
signal live_warning(seconds_to_tear: float)
signal level_finished(report: Dictionary)
signal choice_needed(index: int, options: PackedStringArray, stage: Dictionary)   # finale: kies een machine
signal tape_started(index: int, spec: TxLevelSpec)                               # Nachtdienst: nieuw lint
signal lives_changed(lives: int)                                                 # Nachtdienst

const V := TxCodes.Verdict
const P := TxCodes.Phase
const AUTO_DT := 0.12            # automatische doorloop (CALM): één zet per AUTO_DT

var spec: TxLevelSpec
var machine: TxMachine = null
var stage_index: int = -1
var scoring: TxScoring
var log: TxEventLog
var time: float = 0.0
var finished: bool = false
var completed: bool = false       # alle stages normaal afgewerkt
var hints: int = 0
var undos: int = 0
var assisted: bool = false        # live-tempo 80 % (toegankelijkheid) telt als hulp
var tempo: float = 1.0
var report: Dictionary = {}
var machines: Array[TxMachine] = []
var stages: Array[Dictionary] = [] # werklijst (keuzes uit het rek worden uitgeklapt)
var carry: Dictionary = {}
var front_f: float = 0.0
var pending_choice: Dictionary = {}
var choices: Dictionary = {}      # tape -> gekozen machine
var lives: int = 3
var tapes: Array = []             # Nachtdienst: [{index, z, found, missed, ticks, brute}]
var _undo: Array = []
var _rival: TxBrute = null
var _rival_tears: Array = []
var _beat_next: float = 0.0
var _beat_j: int = 0
var _lever_time: float = -1.0
var _auto_acc: float = 0.0


func start(s: TxLevelSpec, _seed := 0) -> void:
	spec = s
	log = TxEventLog.new()
	scoring = TxScoring.new()
	scoring.bind(self)
	time = 0.0
	finished = false
	completed = false
	hints = 0
	undos = 0
	report = {}
	machines = []
	stages = []
	for st in s.stages:
		stages.append((st as Dictionary).duplicate(true))
	carry = {}
	pending_choice = {}
	choices = {}
	lives = 3
	tapes = []
	_undo = []
	_rival = null
	_rival_tears = []
	if not s.endless:
		scoring.decision_cap = int(TxLevels.optimum(s).decisions)
	if bool(s.live.get("rival", false)):
		_make_rival()
	_start_stage(0)


## Verbreekt alle signaalverbindingen (oproepen bij het verlaten van een level).
func dispose() -> void:
	var objs: Array = [self, scoring]
	objs.append_array(machines)
	if _rival != null:
		objs.append(_rival)
	for obj in objs:
		if obj == null:
			continue
		for sig in obj.get_signal_list():
			for c in obj.get_signal_connection_list(sig.name):
				obj.disconnect(sig.name, c.callable)
	if scoring != null:
		scoring.director = null


func is_live() -> bool:
	return spec.mode == TxCodes.Mode.LIVE


func is_rhythm() -> bool:
	return spec.live.has("bpm")


func _stage_streams(st: Dictionary) -> bool:
	return is_live() and spec.live.has("B") and not bool(st.get("calm", false)) and str(st.get("t", "")) != "" \
			and not str(st.get("machine", "")) in ["edit", "sabotage", "rk", "kmp_table"]


func _start_stage(i: int) -> void:
	stage_index = i
	_undo.clear()
	_auto_acc = 0.0
	log.stage = i
	log.now = time
	var st: Dictionary = stages[i]
	if str(st.get("machine", "")) == "choice":
		machine = null
		pending_choice = {"index": i, "options": PackedStringArray(st.get("options", [])), "stage": st.duplicate(true)}
		log.add("STAGE_START", {"machine": "choice", "tape": str(st.get("tape", "")), "options": st.get("options", [])},
				V.OK, true, {}, {}, true)
		choice_needed.emit(i, pending_choice.options, st)
		return
	var live := {}
	var mode := TxCodes.Mode.CALM
	if _stage_streams(st):
		mode = TxCodes.Mode.LIVE
		live = {"B": int(spec.live.get("B", -1))}
	var mc := TxLevels.make_machine(st, carry, mode, live)
	mc.log = log
	mc.stage_index = i
	mc.now = time
	mc.stage_done.connect(_on_stage_done.bind(mc))
	machine = mc
	machines.append(mc)
	front_f = 0.0
	_beat_j = 0
	_beat_next = time + _beat_interval()
	_lever_time = -1.0
	scoring.attach(mc)
	stage_started.emit(i, mc)
	mc.begin()


func _beat_interval() -> float:
	return 60.0 / float(spec.live.get("bpm", 100)) / maxf(0.1, tempo)


func _on_stage_done(_result: Dictionary, mc: TxMachine) -> void:
	if mc != machine:
		return
	carry = mc.output()
	if spec.endless:
		_tape_done(mc)
		return
	if stage_index + 1 < stages.size():
		_start_stage(stage_index + 1)
	else:
		completed = true
		_finish()


## Huidige stage-spec.
func current_stage() -> Dictionary:
	return stages[stage_index] if stage_index >= 0 and stage_index < stages.size() else {}


func is_autoplay() -> bool:
	return bool(current_stage().get("autoplay", false))


# ------------------------------------------------------------------ zetten

## Zet van de speler (of bot). Finale: {"act":"pick_machine","machine":…} als er een keuze open staat.
func apply(move: Dictionary) -> Dictionary:
	if finished:
		return {"ok": false, "verdict": V.BUMP, "reason": "finished", "done": true}
	if not pending_choice.is_empty():
		return _pick(move)
	if machine == null:
		return {"ok": false, "verdict": V.BUMP, "reason": "no_machine", "done": false}
	machine.now = time
	var si := stage_index
	if not is_live():
		_undo.append({"stage": si, "snap": machine.snapshot(), "score": scoring.state()})
	if is_rhythm() and str(move.get("act", "")) == "card" and not bool(move.get("auto", false)) \
			and machine.phase == P.CARD and str(move.get("x", "")) != "" \
			and str(move.get("x", "")) == (machine as TxShiftAnd).expected_card() \
			and _lever_time >= 0.0 and time - _lever_time <= float(spec.live.get("strak", 0.2)) + 1e-6:
		scoring.add_strak()
	var r := machine.apply(move)
	if not bool(r.ok) and not is_live() and not _undo.is_empty():
		_undo.pop_back()
	r["stage_changed"] = stage_index != si
	return r


func _pick(move: Dictionary) -> Dictionary:
	if str(move.get("act", "")) != "pick_machine":
		return {"ok": false, "verdict": V.BUMP, "reason": "wrong_phase", "done": false}
	var pick := str(move.get("machine", ""))
	var st: Dictionary = pending_choice.stage
	if not (pending_choice.options as PackedStringArray).has(pick):
		log.add("BUMP", {"reason": "no_card", "move": move.duplicate()}, V.BUMP, false, {}, {})
		return {"ok": false, "verdict": V.BUMP, "reason": "no_card", "done": false}
	var i := int(pending_choice.index)
	choices[str(st.get("tape", str(i)))] = pick
	log.add("PICK_MACHINE", {"tape": str(st.get("tape", "")), "machine": pick, "move": move.duplicate()}, V.OK, true,
			{}, {})
	var expanded := TxLevels.choice_stages(st, pick)
	stages.remove_at(i)
	for k in expanded.size():
		stages.insert(i + k, expanded[k])
	pending_choice = {}
	carry = {}
	_start_stage(i)
	return {"ok": true, "verdict": V.OK, "reason": "", "done": false, "stage_changed": true}


## Het orakel op levelniveau (bots): de juiste zet, of {"act":"none"} als de director of de klok aan zet is.
func correct_move() -> Dictionary:
	if finished:
		return {"act": "none"}
	if not pending_choice.is_empty():
		return {"act": "pick_machine", "machine": str(pending_choice.stage.get("best", pending_choice.options[0]))}
	if machine == null or is_autoplay():
		return {"act": "none"}
	if is_rhythm() and bool(current_stage().get("auto_lever", false)):
		if machine.phase == P.LEVER:
			return {"act": "none"}
		if machine.phase == P.CARD and (machine as TxShiftAnd).expected_card() == "":
			return {"act": "none"}
	return machine.correct_move()


func wrong_moves() -> Array[Dictionary]:
	if finished or machine == null or not pending_choice.is_empty() or is_autoplay():
		return []
	var out := machine.wrong_moves()
	if is_rhythm() and bool(current_stage().get("auto_lever", false)):
		var keep: Array[Dictionary] = []
		for w in out:
			if str(w.get("act", "")) == "card" and machine.phase == P.CARD:
				keep.append(w)
		return keep
	return out


func impossible_moves() -> Array[Dictionary]:
	if finished or machine == null or not pending_choice.is_empty():
		return []
	return machine.impossible_moves()


## De Chef toont de juiste zet (kost ★★★). Logt HINT.
func hint() -> Dictionary:
	var mv := correct_move()
	if str(mv.get("act", "none")) == "none":
		return {}
	hints += 1
	log.now = time
	log.add("HINT", {"move": mv.duplicate()}, V.OK, true, mv.duplicate(), {})
	scoring.break_combo()
	return mv


## CALM: herstelt de toestand van vóór de laatste zet in deze stage (kost ★★★). Logt UNDO.
func undo() -> bool:
	if is_live() or finished or _undo.is_empty() or machine == null:
		return false
	var top: Dictionary = _undo.back()
	if int(top.stage) != stage_index:
		return false
	_undo.pop_back()
	machine.restore(top.snap)
	scoring.set_state(top.score)
	undos += 1
	log.now = time
	log.add("UNDO", {"stage": stage_index}, V.OK, true, {}, {})
	scoring.break_combo()
	machine.changed.emit({"fx": "restore"})
	machine.phase_changed.emit(machine.phase, machine.cursor())
	machine.counters_changed.emit(machine.counters.duplicate())
	return true


func can_undo() -> bool:
	return not is_live() and not finished and not _undo.is_empty() and int(_undo.back().stage) == stage_index


# ------------------------------------------------------------------ klok

func tick(dt: float) -> void:
	if finished:
		return
	time += dt
	log.now = time
	scoring.tick_real(dt)
	if machine == null:
		return
	machine.now = time
	if is_live() and spec.live.has("v") and machine.mode == TxCodes.Mode.LIVE:
		var v := float(spec.live.v) * tempo
		front_f += v * dt
		machine.set_front(int(front_f))
		if _rival != null:
			_rival_step(int(front_f))
		if machine != null and not machine.is_done():
			var nd := machine.need()
			if nd >= 0 and machine.buffer >= 0:
				var f_tear := float(nd + machine.buffer + 1)
				var secs := (f_tear - front_f) / maxf(0.001, v)
				if secs < 1.5:
					live_warning.emit(secs)
	if machine != null and is_rhythm() and bool(current_stage().get("auto_lever", false)):
		_rhythm()
	if machine != null and is_autoplay() and not machine.is_done():
		_autoplay(dt)


func _rhythm() -> void:
	var guard := 0
	while machine != null and not machine.is_done() and time + 1e-9 >= _beat_next and guard < 100:
		guard += 1
		var mc := machine
		if mc.phase == P.CARD:
			mc.apply({"act": "card", "x": "", "auto": true, "late": true})
		if mc.is_done() or mc != machine:
			return
		if mc.phase == P.LEVER:
			mc.apply({"act": "lever", "auto": true})
			_lever_time = _beat_next
			beat.emit((mc as TxShiftAnd).j)
		_beat_next += _beat_interval()


## Automatische doorloop (finale): de machine speelt zelf met de tabellen van de speler.
func _autoplay(dt: float) -> void:
	_auto_acc += dt
	var guard := 0
	while machine != null and not machine.is_done() and guard < 400:
		if machine.mode != TxCodes.Mode.LIVE:
			if _auto_acc < AUTO_DT:
				return
			_auto_acc -= AUTO_DT
		guard += 1
		var mc := machine
		var mv := mc.correct_move()
		if str(mv.get("act", "none")) == "none":
			return
		mv["auto"] = true
		var r := mc.apply(mv)
		if not bool(r.ok):
			return
		if mc != machine:
			return


## Speelt een automatische stage meteen helemaal af (CALM; tests, "doorspoelen").
func run_autoplay() -> void:
	var guard := 0
	while machine != null and is_autoplay() and not machine.is_done() and guard < 100000:
		guard += 1
		if machine.mode == TxCodes.Mode.LIVE:
			tick(0.05)
			continue
		var mc := machine
		var mv := mc.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		mv["auto"] = true
		mc.apply(mv)


# ------------------------------------------------------------------ rivaal (3-5)

func _make_rival() -> void:
	var st: Dictionary = spec.stages[0]
	_rival = TxBrute.new()
	_rival.setup({"machine": "brute", "z": str(st.z), "t": str(st.t), "find": "all"}, {},
			{"B": int(spec.live.get("B", -1))})
	_rival.log = TxEventLog.new()
	_rival.consequence.connect(_on_rival_conseq)
	_rival.begin()


func _on_rival_conseq(ev: Dictionary) -> void:
	if str(ev.kind) == "tear":
		_rival_tears.append(_rival.front)


func _rival_step(f: int) -> void:
	_rival.set_front(f)
	var guard := 0
	while not _rival.is_done() and guard < 1000:
		guard += 1
		var mv := _rival.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		mv["auto"] = true
		_rival.apply(mv)


func has_rival() -> bool:
	return _rival != null


## 3-5: {start, hits, tears, tear_fronts, done}
func rival() -> Dictionary:
	if _rival == null:
		return {}
	var hs: Array = []
	for h in _rival.hits:
		hs.append(int(h.start))
	return {"start": _rival.start, "hits": hs, "tears": _rival_tears.size(), "tear_fronts": _rival_tears.duplicate(),
		"done": _rival.is_done(), "front": _rival.front}


func rival_machine() -> TxBrute:
	return _rival


# ------------------------------------------------------------------ Nachtdienst

func _tape_done(mc: TxMachine) -> void:
	var brute := int(TxReference.brute(mc.z, mc.t, true).cmp)
	var info := {"index": spec.tape_index, "z": mc.z, "found": mc.found_count(), "missed": mc.missed.size(),
		"ticks": int(mc.counters.ticks), "brute": brute}
	tapes.append(info)
	scoring.tape_bonus(brute, int(mc.counters.ticks))
	var mist := 0
	for e in log.mistakes():
		if int(e.stage) == stage_index:
			mist += 1
	if mc.missed.size() > 0:
		lives = maxi(0, lives - mc.missed.size())
		lives_changed.emit(lives)
	elif mist == 0 and lives < 3:
		lives += 1
		lives_changed.emit(lives)
	if lives <= 0:
		completed = true
		_finish()
		return
	var nxt := TxLevels.endless_spec(spec.tape_index + 1, spec.seed_, spec.variant)
	spec.tape_index = nxt.tape_index
	spec.live = nxt.live
	spec.title = nxt.title
	spec.ghost = nxt.ghost
	spec.expect = nxt.expect
	stages.append(nxt.stages[0])
	carry = {}
	tape_started.emit(nxt.tape_index, nxt)
	_start_stage(stage_index + 1)


# ------------------------------------------------------------------ einde en rapport

func _finish() -> void:
	if finished:
		return
	finished = true
	log.now = time
	log.add("LEVEL_END", {"completed": completed}, V.OK, true, {}, {}, true)
	report = scoring.final_report(self)
	level_finished.emit(report)


## Beëindigt het level (ook vroegtijdig, bv. de Nachtdienst stoppen) en geeft TxScoring.final_report.
func finish() -> Dictionary:
	if not finished:
		_finish()
	return report


func total_counters() -> Dictionary:
	var c := {"ticks": 0, "wheel": 0, "lamps": 0, "relays": 0, "rewind": 0, "alignments": 0, "bumps": 0}
	for mc in machines:
		for k in c:
			c[k] = int(c[k]) + int(mc.counters.get(k, 0))
	return c


## Aantal echte, gevonden voorkomens over alle stages.
func found_total() -> int:
	var n := 0
	for mc in machines:
		n += mc.found_count()
	return n


## Machinetijd van de automatische doorloop-stages (finale).
func run_machine_time() -> int:
	var t := 0
	for mc in machines:
		if bool(mc.stage.get("autoplay", false)):
			t += mc.machine_time()
	return t


func machine_at(stage_i: int) -> TxMachine:
	for mc in machines:
		if mc.stage_index == stage_i:
			return mc
	return null


func last_machine_of(cls) -> TxMachine:
	for i in range(machines.size() - 1, -1, -1):
		if is_instance_of(machines[i], cls):
			return machines[i]
	return null
