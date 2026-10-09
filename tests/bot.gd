class_name DayBot extends RefCounted
## Bot die een dag speelt via de DayDirector en ExtHashModel.correct_move() (perfect spel), optioneel met fouten.
## Eén actie per step() (zoals een speler per frame).

## Foutmodus: "" = perfect; "double_first" = bij elke vastloper eerst (onnodig) verdubbelen (A6);
## "misroute_first" = het eerste pakje door een luik van een andere emmer; "wrong_side" = eerste verdeling verkeerd;
## "idle_block" = niets doen als er iets vastzit (burst); "no_dump" = klonen niet in de bak;
## "ignore_customers" = klanten negeren; "dump_healthy" = eerste pakje in de overloopbak.
var mistake_mode: String = ""
var _done_once: bool = false
var _did_wrong_double: Dictionary = {}  # parcel_id -> true
var delay: float = 0.0  # denktijd (echte tijd) na elke actie, om een tragere speler na te bootsen
var _cool: float = 0.0


func step(dd: DayDirector) -> bool:
	var model := dd.model
	if mistake_mode != "ignore_customers":
		for c in dd.customers():
			if model.is_findable(int(c.hv)):
				dd.serve(int(c.id), model.index_of(int(c.hv)))
				return true
	var front: Parcel = null
	var belt := dd.belt()
	if not belt.is_empty():
		front = belt[0]
	if mistake_mode == "idle_block" and model.is_alarm():
		return false
	var m := model.correct_move(front)
	if mistake_mode == "no_dump" and m.action == "dump":
		model.allow_dump = false  # bot "ziet" de klonen niet
		m = model.correct_move(front)
		model.allow_dump = true
	match m.action:
		"none":
			return false
		"assign":
			var side := int(m.side)
			if mistake_mode == "wrong_side" and not _done_once:
				side = 1 - side
				_done_once = true
			model.assign(int(m.parcel_id), side)
		"finish":
			model.finish_split()
		"split":
			var pid := (model.blocked[0].parcel as Parcel).id
			if mistake_mode == "double_first" and not _did_wrong_double.has(pid) and model.can_double():
				_did_wrong_double[pid] = true
				model.double_dir()
			else:
				model.begin_split(int(m.bucket_id))
		"double":
			if not model.blocked.is_empty():
				_did_wrong_double[(model.blocked[0].parcel as Parcel).id] = true
			model.double_dir()
		"fail":
			model.double_dir()  # ramt de eindaanslag; de director laat de buis barsten
		"retry":
			model.retry_blocked()
		"dump":
			var target: Parcel = null
			for e in model.blocked:
				if (e.parcel as Parcel).id == int(m.parcel_id):
					target = e.parcel
			if target == null:
				target = dd.take(int(m.parcel_id))
			if target != null:
				model.dump(target)
		"drop":
			var p := dd.take_front()
			if mistake_mode == "dump_healthy" and not _done_once:
				_done_once = true
				model.dump(p)
				return true
			var idx := int(m.dir_index)
			if mistake_mode == "misroute_first" and not _done_once:
				_done_once = true
				for j in model.dir.size():
					if model.dir[j] != model.dir[idx]:
						idx = j
						break
			model.drop(p, idx)
	return true


## Speelt een hele dag (alle fasen) via de director. -> rapport van de laatste day_finished.
## on_step(dd) wordt na elke tick aangeroepen (voor invariant-checks).
func play(dd: DayDirector, spec: DaySpec, dt: float = 0.1, max_time: float = 900.0, on_step: Callable = Callable()) -> Dictionary:
	var reports: Array = []
	var cb := func(r): reports.append(r)
	dd.day_finished.connect(cb)
	dd.start(spec)
	var t := 0.0
	while t < max_time:
		if dd.finished:
			if dd.has_next_phase():
				dd.next_phase()
			else:
				break
		_cool -= dt
		if _cool <= 0.0 and step(dd):
			_cool = delay
		dd.tick(dt * dd.world_time_scale(), dt)
		if on_step.is_valid():
			on_step.call(dd)
		t += dt
	dd.day_finished.disconnect(cb)
	if reports.is_empty():
		return {}
	var last: Dictionary = reports[-1]
	last["all_reports"] = reports
	return last
