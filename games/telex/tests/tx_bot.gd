class_name TxBot extends RefCounted
## Bot die een Telex-level speelt via TxDirector + het orakel (correct_move), perfect of met foutmodi.
## Eén actie per step() (zoals een speler per frame). Van de core; bruikbaar door tests, QA en de front-end
## (attract-lint op de titel, --bot=…). GDD §8.1.
##
## Foutmodi (mode):
##   ""            perfect spel
##   "first"       de eerste beslissing waar een foute zet bestaat, fout spelen (één keer)
##   "every"       in elke stage de eerste beslissing waar een foute zet bestaat, fout spelen
##   "random"      elke beslissing met kans p fout (seed)
##   "act:<act>"   de eerste keer dat de juiste zet act <act> heeft (bv. "shift", "punch_to", "slide", "key",
##                 "card", "fill", "pick_end"), een foute zet met dezelfde act (of een andere) spelen
##   "plug:<src>"  ruisbord: de foutkabel in <src> steken (old, new_shift, new) en zo bevestigen
##   "bump"        één keer een fysiek onmogelijke zet proberen (klem), daarna perfect
##   "hint"        één keer de hint vragen (kost ★★★), daarna perfect
##   "undo"        na de eerste zet één keer terugnemen (CALM), daarna perfect
##   "idle"        niets doen (LIVE: het lint scheurt; CALM: niets gebeurt)
## think: LIVE-denktijd (spelseconden) tussen twee acties (0 = meteen).

var mode: String = ""
var p: float = 0.25
var rng := RandomNumberGenerator.new()
var think: float = 0.0
var log_moves: bool = false
var moves: Array = []              # [{stage, move, ok, verdict}]
var _once_done: bool = false
var _stage_wrong: Dictionary = {}
var _cool: float = 0.0
var _moved: int = 0


func _init(mode_: String = "", seed_: int = 1) -> void:
	mode = mode_
	rng.seed = seed_


## Doet één actie. -> true als er iets gebeurde.
func step(dd: TxDirector, dt: float = 0.0) -> bool:
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
		"first":
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
			elif mode.begins_with("plug:") and str(mv.act) in ["plug", "wire_done"] and dd.machine != null \
					and dd.machine.phase == TxCodes.Phase.WIRE:
				var src := mode.substr(5)
				var sa := dd.machine as TxShiftAnd
				var all_set := true
				for l in range(1, sa.k + 1):
					if str(sa.wiring.get(l, "")) != src:
						all_set = false
						mv = {"act": "plug", "l": l, "src": src}
						break
				if all_set:
					mv = {"act": "wire_done"}
	var r := dd.apply(mv)
	_moved += 1
	if log_moves:
		moves.append({"stage": si, "move": mv, "ok": r.ok, "verdict": r.verdict})
	_cool = think if dd.is_live() else 0.0
	return true


## Speelt een volledig level. on_step(dd) wordt na elke actie opgeroepen (invarianten, snapshots…).
## -> rapport (TxScoring.final_report) of {} als het level niet eindigde binnen max_time spelseconden.
func play(spec: TxLevelSpec, dt: float = 0.05, max_time: float = 900.0, on_step: Callable = Callable()) -> Dictionary:
	var dd := TxDirector.new()
	dd.start(spec)
	var rep := run(dd, dt, max_time, on_step)
	dd.dispose()
	return rep


func run(dd: TxDirector, dt: float = 0.05, max_time: float = 900.0, on_step: Callable = Callable()) -> Dictionary:
	var guard := 0
	while not dd.finished and dd.time < max_time and guard < 400000:
		guard += 1
		var did := step(dd, dt)
		if did and on_step.is_valid():
			on_step.call(dd)
		if dd.finished:
			break
		if not did:
			dd.tick(dt)
		elif not dd.is_live():
			dd.tick(dt * 0.1)
	if dd.finished:
		return dd.report
	return {}
