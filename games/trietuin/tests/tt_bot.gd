class_name TtLevelBot extends RefCounted
## Bot die een Trietuin-level speelt via TtDirector + het orakel (model.correct_move()), perfect of met foutmodi.
## Eén actie per step() (zoals een speler per frame). Bruikbaar door tests, QA en de front-end (attract-boom, --bot=…).
##
## Foutmodi (mode):
##   ""          perfect spel
##   "first"     de eerste beslissing waar een foute zet bestaat, fout spelen (één keer)
##   "every"     de eerste beslissing van elke kaart fout spelen (als er een foute zet bestaat)
##   "random"    elke beslissing met kans p fout (seed)
##   "act:<act>" de eerste keer dat de juiste zet act <act> heeft (bv. "split", "answer", "go", "read", "attach",
##               "label", "rule", "place", "cut", "where"), een foute zet met dezelfde act (of een andere) spelen
##   "bump"      één keer een fysiek onmogelijke zet proberen (klonk), daarna perfect
##   "hint"      één keer de hint vragen (kost ★★★), daarna perfect
##   "rewind"    na de eerste afgewerkte kaart één keer terugspoelen (CALM), daarna perfect
##   "idle"      niets doen (SWARM: alles verloopt; vrije tuin: game over)
##   "pluck_wasp" bij elke wesp "Pluk" kiezen (de wesp steelt)

var mode: String = ""
var p: float = 0.25
var rng := RandomNumberGenerator.new()
var think: float = 0.0            # SWARM: denktijd (spelseconden) tussen twee acties
var log_moves: bool = false
var moves: Array = []             # gespeelde zetten [{card, move, ok, verdict}]
var _once_done: bool = false
var _cards_wrong: Dictionary = {}
var _cool: float = 0.0


func _init(mode_: String = "", seed_: int = 1) -> void:
	mode = mode_
	rng.seed = seed_


## Doet één actie. -> true als er iets gebeurde.
func step(dd: TtDirector, dt: float = 0.0) -> bool:
	if dd.finished or mode == "idle":
		return false
	if _cool > 0.0:
		_cool -= dt
		return false
	var m := dd.model
	if m.card == null:
		if mode == "rewind" and not _once_done and _finished_cards(dd) >= 1:
			_once_done = true
			return dd.rewind()
		var c := dd.next_card()
		return c != null
	var mv := m.correct_move()
	if str(mv.get("act", "none")) == "none":
		return false
	var cid := m.card.id
	match mode:
		"hint":
			if not _once_done:
				_once_done = true
				var hm := dd.hint()
				if not hm.is_empty():
					mv = hm
		"bump":
			if not _once_done:
				var im := m.impossible_moves()
				if not im.is_empty():
					_once_done = true
					mv = im[0]
		"first":
			if not _once_done:
				var w := m.wrong_moves()
				if not w.is_empty():
					_once_done = true
					mv = w[0]
		"every":
			if not _cards_wrong.has(cid):
				var w2 := m.wrong_moves()
				if not w2.is_empty():
					_cards_wrong[cid] = true
					mv = w2[0]
		"random":
			if rng.randf() < p:
				var w3 := m.wrong_moves()
				if not w3.is_empty():
					mv = w3[rng.randi_range(0, w3.size() - 1)]
		"pluck_wasp":
			if m.card.wasp and str(mv.act) == "answer":
				mv = {"act": "answer", "found": true}
		_:
			if mode.begins_with("act:") and not _once_done and str(mv.act) == mode.substr(4):
				var w4 := m.wrong_moves()
				if not w4.is_empty():
					_once_done = true
					var pick: Dictionary = w4[0]
					for x in w4:
						if str(x.act) == str(mv.act):
							pick = x
							break
					mv = pick
	var r := m.apply(mv)
	if log_moves:
		moves.append({"card": cid, "move": mv, "ok": r.ok, "verdict": r.verdict})
	_cool = think
	return true


func _finished_cards(dd: TtDirector) -> int:
	var n := 0
	for c in dd.cards:
		if c.state == "done" or c.state == "expired":
			n += 1
	return n


## Speelt een volledig level. on_step(dd) wordt na elke actie opgeroepen (invariants, snapshots…).
## -> rapport (TtScoring.final_report) of {} als het level niet eindigde binnen max_time spelseconden.
func play(spec: TtLevelSpec, dt: float = 0.1, max_time: float = 900.0, on_step: Callable = Callable(),
		seed_: int = 0) -> Dictionary:
	var dd := TtDirector.new()
	dd.start(spec, seed_)
	var rep := run(dd, dt, max_time, on_step)
	dd.dispose()
	return rep


func run(dd: TtDirector, dt: float = 0.1, max_time: float = 900.0, on_step: Callable = Callable()) -> Dictionary:
	var guard := 0
	while not dd.finished and dd.time < max_time and guard < 200000:
		guard += 1
		var did := step(dd, dt)
		if did and on_step.is_valid():
			on_step.call(dd)
		if dd.all_done() and not dd.spec.endless:
			return dd.finish()
		if not did or dd.spec.mode == TtCodes.Mode.SWARM:
			dd.tick(dt)
		else:
			dd.tick(dt * 0.1)
	if dd.finished:
		return dd.report
	return {}
