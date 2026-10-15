class_name ScDirector extends RefCounted
## Speelt een level (GDD §8.8): stages en carry, De Voorlezing (ScReader), hint, terugnemen, hernemen, de Nachtwake
## (kaars, levens, rondes) en het eindrapport. Puur: geen nodes. De front-end roept tick(dt) per frame en apply(move)
## voor zetten; luistert naar stage_started (verbindt dan de signalen van het werktuig; begin() volgt meteen daarna),
## reading_started en level_finished. Opslaan (ScSave.record) doet de front-end met het rapport.
##
## Voorlezing: een zendstage waarvan de uitvoer niet door de volgende stage gebruikt wordt, krijgt aan haar einde een
## voorlezing (ScReader.read of read_chain over de keten). Ontvangstages vergelijken copy() met expect. Het codebord in
## mode "cuts" krijgt een demovoorlezing (gulzig; telt niet). pigeons = 2 als de inkt van de keten > het optimum.

signal stage_started(index: int, tool: ScTool)
signal reading_started(result: Dictionary)   # {stage, original, read, marks, equal, pigeons, demo, receive, ink, opt}
signal level_finished(report: Dictionary)
signal candle_changed(lives: int, burn: float)   # Nachtwake: levens en resterende rondetijd (s)
signal round_started(r: int, stage: Dictionary)  # Nachtwake

const V := ScCodes.Verdict
const KIND_OF := {"living_tree": "adaptive", "ruler": "arith", "window": "lz77", "stampcase": "lzw", "drum": "bwt",
	"shelf": "mtf", "bindery": "huffman", "code_board": "prefix"}

var spec: ScLevelSpec
var tool: ScTool = null
var tools: Array[ScTool] = []
var stage_index: int = -1
var stages: Array[Dictionary] = []
var scoring: ScScoring
var log: ScEventLog
var time: float = 0.0
var finished: bool = false
var completed: bool = false
var hints: int = 0
var undos: int = 0
var resumes: int = 0
var assisted: bool = false            # hulplijnen aan (telt als hulp)
var report: Dictionary = {}
var readings: Array[Dictionary] = []
var carry: Dictionary = {}
var optimum: Dictionary = {}
# Nachtwake
var lives: int = 3
var rounds: int = 0                   # afgewerkte rondes
var round_index: int = 0
var burn: float = 0.0                 # resterende tijd van de huidige stage (s)
var flawless: int = 0                 # foutloze rondes op rij
var _round_mistake := false

var _carries: Dictionary = {}         # stage → carry bij de start
var _undo: Array = []


func start(s: ScLevelSpec) -> void:
	spec = s
	log = ScEventLog.new()
	scoring = ScScoring.new()
	scoring.bind(self)
	time = 0.0
	finished = false
	completed = false
	hints = 0
	undos = 0
	resumes = 0
	report = {}
	readings = []
	tools = []
	stages = []
	for st in s.stages:
		stages.append((st as Dictionary).duplicate(true))
	carry = {}
	_carries = {}
	_undo = []
	lives = 3
	rounds = 0
	round_index = s.round_index
	flawless = 0
	_round_mistake = false
	optimum = ScLevels.optimum(s)
	if not s.endless:
		scoring.decision_cap = int(optimum.get("decisions", -1))
	_start_stage(0)


## Verbreekt alle signaalverbindingen (oproepen bij het verlaten van een level).
func dispose() -> void:
	var objs: Array = [self, scoring]
	objs.append_array(tools)
	for obj in objs:
		if obj == null:
			continue
		for sig in obj.get_signal_list():
			for c in obj.get_signal_connection_list(sig.name):
				obj.disconnect(sig.name, c.callable)
	if scoring != null:
		scoring.director = null


func _start_stage(i: int) -> void:
	stage_index = i
	_undo.clear()
	log.stage = i
	log.now = time
	var st: Dictionary = stages[i]
	_carries[i] = carry.duplicate(true)
	var t := ScLevels.make_tool(st, carry)
	t.log = log
	t.stage_index = i
	t.now = time
	t.stage_done.connect(_on_stage_done.bind(t))
	t.event_logged.connect(_on_event)
	tool = t
	tools.append(t)
	scoring.attach(t)
	if spec.endless:
		burn = float(st.get("time", 10.0))
		if str(st.get("tool", "")) == "bindery":
			_round_mistake = false
			round_started.emit(round_index, st)
		candle_changed.emit(lives, burn)
	stage_started.emit(i, t)
	t.begin()


func current_stage() -> Dictionary:
	return stages[stage_index] if stage_index >= 0 and stage_index < stages.size() else {}


func _on_event(e: Dictionary) -> void:
	if spec.endless and bool(e.ok) and not bool(e.auto) and int(e.verdict) == V.WRONG_PAIR:
		_round_mistake = true
		_lose_life("touw")


func _on_stage_done(_result: Dictionary, t: ScTool) -> void:
	if t != tool:
		return
	carry = t.output()
	_reading_for(stage_index)
	if spec.endless:
		_endless_next()
		return
	if stage_index + 1 < stages.size():
		_start_stage(stage_index + 1)
	else:
		completed = true
		_finish()


# ------------------------------------------------------------------ voorlezing

static func feeds(stage_a: Dictionary, stage_b: Dictionary) -> bool:
	if str(stage_a.get("side", "send")) == "receive":
		return false
	return str(stage_b.get("input", "")) == "carry" or str(stage_b.get("symbols", "")) == "carry" \
			or (str(stage_b.get("tool", "")) == "prefix_read" and not stage_b.has("code"))


## Begin van de keten die in stage i eindigt.
func chain_start(i: int) -> int:
	var s := i
	while s > 0 and feeds(stages[s - 1], stages[s]):
		s -= 1
	return s


func _reading_for(i: int) -> void:
	var st: Dictionary = stages[i]
	var t: ScTool = tools[tools.size() - 1]
	if i + 1 < stages.size() and feeds(st, stages[i + 1]):
		return
	var res := {}
	var tl := str(st.get("tool", ""))
	if t.side == ScCodes.Side.RECEIVE:
		if not st.has("expect") and not st.has("text"):
			return
		var exp := str(st.get("expect", st.get("text", "")))
		res = {"original": exp, "read": t.copy(), "receive": true, "demo": false, "pigeons": 1}
	elif tl == "code_board" and str(st.get("mode", "")) == "cuts":
		res = {"original": str(st.get("intended", "")), "read": ScReference.greedy_read(st.code, str(st.bits)),
			"receive": false, "demo": true, "pigeons": 1}
	elif tl == "dovecote" or (tl == "bindery" and st.has("weights")):
		return
	else:
		var s0 := chain_start(i)
		var outs: Array = []
		var kinds: Array = []
		var params: Array = []
		var chain_tools := tools.slice(tools.size() - 1 - (i - s0))
		for q in range(s0, i + 1):
			var ct: ScTool = chain_tools[q - s0]
			outs.append(ct.output())
			kinds.append(KIND_OF.get(str(stages[q].get("tool", "")), "prefix"))
			params.append({})
		var rd: Dictionary
		if outs.size() == 1:
			rd = ScReader.read(str(kinds[0]), outs[0], {})
		else:
			rd = ScReader.read_chain(outs, kinds, params)
		var orig := _original(s0)
		var ink := int(t.counters.ink)
		var opt := int((optimum.stages[i] as Dictionary).ink) if i < (optimum.get("stages", []) as Array).size() else ink
		res = {"original": orig, "read": str(rd.text), "receive": false, "demo": false,
			"pigeons": 2 if ink > opt and ink > 0 else 1, "ink": ink, "opt": opt, "chain": [s0, i]}
		res["saved_points"] = _saved_points(s0, i, ink)
	var cmp := ScReader.compare(str(res.original), str(res.read))
	res["stage"] = i
	res["marks"] = cmp.marks
	res["equal"] = cmp.equal
	res["first_diff"] = cmp.first_diff
	var diff := 0
	for m in cmp.marks:
		if not m:
			diff += 1
	res["diff"] = 0 if bool(res.demo) else diff
	if not res.has("chain"):
		res["chain"] = [i, i]
	readings.append(res)
	log.now = time
	log.stage = i
	log.add("READING", res.duplicate(true), V.OK, true, {}, {}, true)
	if not bool(res.demo) and not bool(cmp.equal):
		var cause := _cause(int(cmp.first_diff), int(res.chain[0]), i)
		if not cause.is_empty():
			var aff: Array = cause.affects
			for p in cmp.marks.size():
				if not cmp.marks[p] and not aff.has(p):
					aff.append(p)
		var fd := int(cmp.first_diff)
		log.add("GARBLED", {"pos": fd, "read": str(res.read).substr(fd, 1), "orig": str(res.original).substr(fd, 1),
			"cause_seq": int(cause.get("seq", -1)), "cause": _describe(cause), "at": fd}, V.GARBLED, true, {}, {}, true)
	if int(res.pigeons) > 1:
		log.add("TWO_PIGEONS", {"ink": int(res.ink), "opt": int(res.opt)}, V.TWO_PIGEONS, true, {}, {}, true)
	scoring.refresh("voorlezing")
	reading_started.emit(res)


func _original(s0: int) -> String:
	var st: Dictionary = stages[s0]
	if st.has("text"):
		return str(st.text)
	if st.has("input") and str(st.input) != "carry":
		return str(st.input)
	return ""


## +1 per bespaarde bit, +5 per bespaard teken (zegels, stempels); enkel als positief.
func _saved_points(s0: int, i: int, ink: int) -> int:
	var tl := str(stages[i].get("tool", ""))
	var n := _original(s0).length()
	if tl in ["window", "stampcase"]:
		return 5 * maxi(0, n - ink)
	if tl in ["drum", "shelf"]:
		return 0
	return maxi(0, 8 * n - ink)


## De misstap die de voorlezing deed afwijken: de laatste misstap in de keten met tekstpositie ≤ pos (anders de laatste
## misstap van de keten).
func _cause(pos: int, s0: int, s1: int) -> Dictionary:
	var ms := log.mistakes()
	var fallback := {}
	for q in range(ms.size() - 1, -1, -1):
		var e: Dictionary = ms[q]
		if int(e.stage) < s0 or int(e.stage) > s1:
			continue
		if fallback.is_empty():
			fallback = e
		if int((e.data as Dictionary).get("at", 0)) <= pos:
			return e
	return fallback


static func _describe(e: Dictionary) -> String:
	if e.is_empty():
		return "een eerdere zet"
	var vn := ScCodes.verdict_name(int(e.verdict))
	return "%s bij positie %d (zet %d, %s)" % [str(e.type).to_lower(), int((e.data as Dictionary).get("at", 0)),
		int(e.seq), vn]


# ------------------------------------------------------------------ zetten

func apply(move: Dictionary) -> Dictionary:
	if finished or tool == null:
		return {"ok": false, "verdict": V.BUMP, "reason": "finished", "done": true}
	tool.now = time
	log.now = time
	var si := stage_index
	if not spec.endless:
		_undo.append({"stage": si, "snap": tool.snapshot()})
	var r := tool.apply(move)
	if not bool(r.ok) and not _undo.is_empty():
		_undo.pop_back()
	r["stage_changed"] = stage_index != si
	return r


func correct_move() -> Dictionary:
	if finished or tool == null:
		return {"act": "none"}
	return tool.correct_move()


func wrong_moves() -> Array[Dictionary]:
	if finished or tool == null:
		return []
	return tool.wrong_moves()


func impossible_moves() -> Array[Dictionary]:
	if finished or tool == null:
		return []
	return tool.impossible_moves()


## Zeno's inkthand: de juiste zet (kost ★★★). Logt HINT.
func hint() -> Dictionary:
	var mv := correct_move()
	if str(mv.get("act", "none")) == "none":
		return {}
	hints += 1
	log.now = time
	log.add("HINT", {"move": mv.duplicate()}, V.OK, true, mv.duplicate(), {})
	scoring.break_combo()
	return mv


func can_undo() -> bool:
	return not spec.endless and not finished and not _undo.is_empty() and int(_undo.back().stage) == stage_index


## Herstelt de toestand van vóór de laatste zet in deze stage (kost ★★★). Logt UNDO.
func undo() -> bool:
	if not can_undo():
		return false
	var top: Dictionary = _undo.pop_back()
	tool.restore(top.snap)
	undos += 1
	log.now = time
	log.add("UNDO", {"stage": stage_index}, V.OK, true, {}, {})
	_after_restore()
	return true


## "Herneem vanaf hier": restore(entry.before); de log wordt afgekapt (telt als hulp). Logt RESUME.
func resume_from(seq: int) -> bool:
	if spec.endless:
		return false
	var e := log.entry(seq)
	if e.is_empty() or (e.before as Dictionary).is_empty():
		return false
	var si := int(e.stage)
	if si < 0 or si >= stages.size():
		return false
	if si != stage_index or tool == null:
		# het werktuig van die stage opnieuw maken met de carry van toen
		while tools.size() > si:
			tools.pop_back()
		carry = (_carries.get(si, {}) as Dictionary).duplicate(true)
		stage_index = si
		var t := ScLevels.make_tool(stages[si], carry)
		t.log = log
		t.stage_index = si
		t.now = time
		t.stage_done.connect(_on_stage_done.bind(t))
		t.event_logged.connect(_on_event)
		tool = t
		tools.append(t)
		scoring.attach(t)
		stage_started.emit(si, t)
	var keep: Array[Dictionary] = []
	for r in readings:
		if int(r.stage) < si:
			keep.append(r)
	readings = keep
	tool.restore(e.before)
	finished = false
	completed = false
	report = {}
	_undo.clear()
	resumes += 1
	log.now = time
	log.stage = si
	log.add("RESUME", {"seq": seq, "stage": si}, V.OK, true, {}, {})
	_after_restore()
	return true


func _after_restore() -> void:
	scoring.refresh("terugnemen")
	tool.changed.emit({"fx": "restore"})
	tool.counters_changed.emit(tool.counters.duplicate())
	tool.output_changed.emit(tool.output())
	tool.copy_changed.emit(tool.copy())
	tool.phase_changed.emit(tool.phase, tool.cursor())


# ------------------------------------------------------------------ klok

func tick(dt: float) -> void:
	if finished:
		return
	time += dt
	log.now = time
	scoring.tick_real(dt)
	if tool != null:
		tool.now = time
	if spec.endless and tool != null and not tool.is_done():
		burn -= dt
		if burn <= 0.0:
			_burnt()
		else:
			candle_changed.emit(lives, burn)


func _lose_life(reason: String) -> void:
	lives = maxi(0, lives - 1)
	flawless = 0
	scoring.break_combo()
	log.add("CANDLE", {"reason": reason, "lives": lives}, V.OK, true, {}, {}, true)
	candle_changed.emit(lives, burn)
	if lives <= 0:
		completed = true
		_finish()


## De kaars is op: een leven minder; Zeno werkt de stage af (automatisch).
func _burnt() -> void:
	burn = 0.0
	_round_mistake = true
	_lose_life("kaars")
	if finished:
		return
	var t := tool
	var guard := 0
	while t == tool and not t.is_done() and guard < 1000:
		guard += 1
		var mv := t.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		mv["auto"] = true
		t.apply(mv)


func _endless_next() -> void:
	if finished:
		return
	var st: Dictionary = stages[stage_index]
	if stage_index + 1 < stages.size():
		_start_stage(stage_index + 1)
		return
	# ronde af
	rounds += 1
	if not _round_mistake:
		scoring.round_bonus(burn)
		flawless += 1
		if flawless % 5 == 0 and lives < 3:
			lives += 1
			candle_changed.emit(lives, burn)
	round_index = int(st.get("round", round_index)) + 1
	var nxt := ScLevels.endless_spec(round_index, spec.seed_)
	spec.round_index = round_index
	spec.title = nxt.title
	spec.optimum = nxt.optimum
	stages.append_array(nxt.stages)
	carry = {}
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


## Beëindigt het level (ook vroegtijdig, bv. de Nachtwake stoppen) en geeft ScScoring.final_report.
func finish() -> Dictionary:
	if not finished:
		_finish()
	return report


func total_counters() -> Dictionary:
	var c := {}
	for k in ScTool.COUNTER_KEYS:
		c[k] = 0
	for t in tools:
		for k in c:
			c[k] = int(c[k]) + int(t.counters.get(k, 0))
	return c


## Jouw werk naast het juiste, per stage: [{stage, tool, yours, correct}].
func structures() -> Array:
	var out: Array = []
	var opt_stages: Array = optimum.get("stages", [])
	for q in tools.size():
		var t := tools[q]
		var si := t.stage_index
		if si >= stages.size():
			continue
		var cc: Dictionary = {}
		if si > 0 and si - 1 < opt_stages.size():
			cc = (opt_stages[si - 1] as Dictionary).get("output", {})
		var fresh := ScLevels.make_tool(stages[si], cc)
		fresh.begin()
		fresh.auto_finish()
		out.append({"stage": si, "tool": ScCodes.tool_name(t.tool), "yours": t.structure(), "correct": fresh.structure()})
	return out


func tool_at(stage_i: int) -> ScTool:
	for t in tools:
		if t.stage_index == stage_i:
			return t
	return null
