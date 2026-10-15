class_name ScLevelBot extends RefCounted
## Bot die een Kortschrift-level speelt via ScDirector + het orakel (correct_move), perfect of met foutmodi.
## Eén actie per step() (zoals een speler per klik). Van de core; bruikbaar door tests, QA en de front-end
## (attract-modus op de titel, --bot=…). GDD §8.1.
##
## Foutmodi (mode):
##   ""            perfect spel
##   "first"       de eerste beslissing waar een foute zet bestaat, fout spelen (één keer)
##   "every"       in elke stage de eerste beslissing waar een foute zet bestaat, fout spelen
##   "random"      elke beslissing met kans p fout (seed)
##   "act:<act>"   de eerste keer dat de juiste zet act <act> heeft (bv. "keep", "swap", "bit", "bind", "stamp",
##                 "carve", "insert", "mark", "find", "number", "pick", "start"), een foute zet spelen (bij voorkeur
##                 met dezelfde act)
##   "bump"        één keer een onmogelijke zet proberen (klem), daarna perfect
##   "hint"        één keer de hint vragen (kost ★★★), daarna perfect
##   "undo"        na de eerste zet één keer terugnemen, daarna perfect
##   "resume"      "first", en na het einde hernemen vanaf vóór de misstap, daarna perfect
##   "idle"        niets doen (Nachtwake: de kaars brandt op)
## think: denktijd (spelseconden) tussen twee acties (Nachtwake: de kaars brandt intussen).

var mode: String = ""
var p: float = 0.25
var rng := RandomNumberGenerator.new()
var think: float = 0.0
var log_moves: bool = false
var moves: Array = []              # [{stage, move, ok, verdict}]
var _once_done: bool = false
var _resumed: bool = false
var _stage_wrong: Dictionary = {}
var _cool: float = 0.0
var _moved: int = 0
var _fails: int = 0                # opeenvolgende klemmen (beveiliging tegen lussen)


func _init(mode_: String = "", seed_: int = 1) -> void:
	mode = mode_
	rng.seed = seed_


## Doet één actie. → true als er iets gebeurde.
func step(dd: ScDirector, dt: float = 0.0) -> bool:
	if mode == "resume" and dd.finished and not _resumed:
		_resumed = true
		var ms := dd.log.mistakes()
		if not ms.is_empty():
			return dd.resume_from(int(ms[0].seq))
		return false
	if dd.finished or mode == "idle":
		return false
	if _cool > 0.0:
		_cool -= dt
		return false
	if mode == "undo" and not _once_done and _moved >= 1 and dd.can_undo():
		_once_done = true
		return dd.undo()
	var mv := dd.correct_move()
	if str(mv.get("act", "none")) == "none":
		return false
	var si := dd.stage_index
	match mode:
		"hint":
			if not _once_done:
				_once_done = true
				var hm := dd.hint()
				if not hm.is_empty():
					mv = hm
		"bump":
			if not _once_done:
				var im := dd.impossible_moves()
				if not im.is_empty():
					_once_done = true
					mv = im[0]
		"first", "resume":
			if not _once_done:
				var w := dd.wrong_moves()
				if not w.is_empty():
					_once_done = true
					mv = w[0]
		"every":
			if not _stage_wrong.has(si):
				var w2 := dd.wrong_moves()
				if not w2.is_empty():
					_stage_wrong[si] = true
					mv = w2[0]
		"random":
			if rng.randf() < p:
				var w3 := dd.wrong_moves()
				if not w3.is_empty():
					mv = w3[rng.randi_range(0, w3.size() - 1)]
		_:
			if mode.begins_with("act:") and not _once_done and str(mv.act) == mode.substr(4):
				var w4 := dd.wrong_moves()
				if not w4.is_empty():
					_once_done = true
					var pick: Dictionary = w4[0]
					for x in w4:
						if str(x.act) == str(mv.act):
							pick = x
							break
					mv = pick
	var r := dd.apply(mv)
	_moved += 1
	_fails = 0 if bool(r.ok) else _fails + 1
	if log_moves:
		moves.append({"stage": si, "move": mv, "ok": r.ok, "verdict": r.verdict})
	_cool = think
	return true


## Speelt een volledig level. on_step(dd) wordt na elke actie opgeroepen (invarianten, snapshots…).
## → rapport (ScScoring.final_report) of {} als het level niet eindigde.
func play(spec: ScLevelSpec, dt: float = 0.05, max_time: float = 3600.0, on_step: Callable = Callable()) -> Dictionary:
	var dd := ScDirector.new()
	dd.start(spec)
	var rep := run(dd, dt, max_time, on_step)
	dd.dispose()
	return rep


func run(dd: ScDirector, dt: float = 0.05, max_time: float = 3600.0, on_step: Callable = Callable()) -> Dictionary:
	var guard := 0
	while (not dd.finished or (mode == "resume" and not _resumed)) and dd.time < max_time and guard < 400000:
		guard += 1
		var did := step(dd, dt)
		if did and on_step.is_valid():
			on_step.call(dd)
		if dd.finished and not (mode == "resume" and not _resumed):
			break
		if _fails > 50:
			push_warning("ScLevelBot: 50 klemmen op rij, gestopt")
			break
		dd.tick(dt if not did or think > 0.0 or dd.spec.endless else dt * 0.1)
	if dd.finished:
		return dd.report
	return {}


## Nachtwake: speelt tot er rounds rondes af zijn (of de dageraad), en stopt dan. → rapport.
func play_wake(seed_: int, rounds: int, dt: float = 0.05) -> Dictionary:
	var dd := ScDirector.new()
	dd.start(ScLevels.endless_spec(0, seed_))
	var guard := 0
	while not dd.finished and dd.rounds < rounds and guard < 400000:
		guard += 1
		step(dd, dt)
		dd.tick(dt)
	var rep := dd.finish()
	dd.dispose()
	return rep
