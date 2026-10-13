class_name TxScoring extends RefCounted
## Punten, combo, sterren en het eindrapport (GDD §6). Luistert naar de machines van de director.
## Punten (§6.3): echte treffer +100 · correcte beslissing +10 (× combo in LIVE) · bespaarde tik t.o.v. brute kracht +2 ·
## vals alarm −50 · gemist −100 · klem −5 · tegenzet 10 × metriek · strakke kaart +5.
## Combo (enkel LIVE): correcte beslissingen binnen 4 s na elkaar → ×2 na 4, ×3 na 8, ×4 na 12 ("Volle stroom").

signal points_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal full_power()

const V := TxCodes.Verdict
const DECISIONS := ["SHIFT", "STRIP", "PUNCH", "PUNCH_TO", "CARDS_DONE", "KEY", "JUMP", "COMMIT", "BIT", "SLIDE",
	"VERIFY", "REPORT", "IGNORE", "CARD", "WIRE_DONE", "FILL", "STEP", "PICK_END", "CHOOSE"]
const COMBO_WINDOW := 4.0

var points: int = 0
var combo: int = 1
var streak: int = 0
var since: float = 0.0
var strak: int = 0
var breakdown: Dictionary = {}     # label -> bedrag
var director: TxDirector = null
var _found: Dictionary = {}        # "stage:start:end" -> true
var _end_done: bool = false
var decision_cap: int = -1         # max. aantal beloonde beslissingen (= perfect spel); −1 = onbeperkt
var decisions: int = 0


## Toestand voor terugnemen (CALM).
func state() -> Dictionary:
	return {"points": points, "breakdown": breakdown.duplicate(), "found": _found.duplicate(), "decisions": decisions,
		"strak": strak}


func set_state(s: Dictionary) -> void:
	var old := points
	points = int(s.points)
	breakdown = (s.breakdown as Dictionary).duplicate()
	_found = (s.found as Dictionary).duplicate()
	decisions = int(s.decisions)
	strak = int(s.strak)
	if points != old:
		points_changed.emit(points, points - old, "terugnemen")


func bind(d: TxDirector) -> void:
	director = d


func attach(mc: TxMachine) -> void:
	mc.event_logged.connect(_on_event)
	mc.consequence.connect(_on_conseq)
	mc.reported.connect(_on_report.bind(mc))
	mc.stage_done.connect(_on_stage_done.bind(mc))


func _live() -> bool:
	return director != null and director.spec != null and director.spec.mode == TxCodes.Mode.LIVE


func add(amount: int, label: String) -> void:
	if amount == 0:
		return
	points += amount
	breakdown[label] = int(breakdown.get(label, 0)) + amount
	points_changed.emit(points, amount, label)


func break_combo() -> void:
	if streak != 0 or combo != 1:
		streak = 0
		combo = 1
		combo_changed.emit(combo)


func add_strak() -> void:
	strak += 1
	add(5, "strak ritme")


func tick_real(dt: float) -> void:
	since += dt
	if since > COMBO_WINDOW and streak > 0:
		break_combo()


func _on_event(e: Dictionary) -> void:
	var v := int(e.verdict)
	if not bool(e.ok):
		add(-5, "klemmen")
		return
	if bool(e.auto):
		return
	if v != V.OK and v != V.BUMP:
		break_combo()
		return
	if not DECISIONS.has(str(e.type)):
		return
	var mult := combo if _live() else 1
	if decision_cap < 0 or decisions < decision_cap:
		decisions += 1
		add(10 * mult, "correcte beslissingen")
	if _live():
		streak = streak + 1 if since <= COMBO_WINDOW or streak == 0 else 1
		since = 0.0
		var nc := mini(4, 1 + int(streak / 4.0))
		if nc != combo:
			combo = nc
			combo_changed.emit(combo)
			if combo == 4:
				full_power.emit()


func _on_report(hit: Dictionary, mc: TxMachine) -> void:
	if not bool(hit.real):
		return
	var key := "%d:%d:%d" % [mc.stage_index, int(hit.start), int(hit.end)]
	if _found.has(key):
		return
	_found[key] = true
	var mult := combo if director != null and director.spec != null and director.spec.endless else 1
	add(100 * mult, "codewoorden gevonden")


func _on_conseq(ev: Dictionary) -> void:
	match str(ev.kind):
		"missed":
			add(-100, "gemiste codewoorden")
			break_combo()
		"false_alarm":
			add(-50, "vals alarm")
			break_combo()
		"tear":
			break_combo()


func _on_stage_done(_result: Dictionary, mc: TxMachine) -> void:
	if mc is TxSabotage:
		var sb := mc as TxSabotage
		if sb.best >= 0:
			var amount := 10 * maxi(0, sb.n - sb.best) if sb.minimize() else 10 * sb.best
			add(amount, "tegenzet")


## Eindbonus: +2 per bespaarde tik t.o.v. brute kracht (enkel als positief).
func apply_end_bonus(d: TxDirector) -> void:
	if _end_done:
		return
	_end_done = true
	if d.spec.endless:
		return
	var ghost := int(d.spec.ghost.get("brute_ticks", -1))
	if ghost < 0:
		return
	var c := d.total_counters()
	var cost := int(c.ticks) + int(c.lamps)
	# nooit meer dan bij perfect spel (wie te ver springt, bespaart geen punten)
	var opt := int(d.spec.optimum.get("ticks", 0)) + int(d.spec.optimum.get("lamps", 0))
	cost = maxi(cost, opt)
	if cost > 0 and ghost > cost:
		add(2 * (ghost - cost), "bespaarde tikken")


## Nachtdienst: per lint 2 × (brute kracht − jouw tikken).
func tape_bonus(brute_ticks: int, ticks: int) -> void:
	if brute_ticks > ticks:
		add(2 * (brute_ticks - ticks), "lintbonus")


# ------------------------------------------------------------------ sterren

func eval_star(c: Dictionary, d: TxDirector) -> bool:
	match str(c.get("kind", "")):
		"done":
			return d.completed
		"all":
			for x in c.get("of", []):
				if not eval_star(x, d):
					return false
			return true
		"any":
			for x in c.get("of", []):
				if eval_star(x, d):
					return true
			return false
		"hits_ge":
			return d.found_total() >= int(c.n)
		"no_mistakes":
			return d.log.mistakes().is_empty()
		"no_help":
			return d.hints == 0 and d.undos == 0 and not d.assisted
		"no_bumps":
			return d.log.bumps().is_empty()
		"time_le":
			return d.time <= float(c.s)
		"sequences_ge":
			var eb := d.last_machine_of(TxEditBoard) as TxEditBoard
			return eb != null and eb.distinct_sequences().size() >= int(c.n)
		"matches_all", "starts_all", "ends_all":
			var eb2 := d.last_machine_of(TxEditBoard) as TxEditBoard
			if eb2 == null:
				return false
			var key := str(c.kind).trim_suffix("_all")
			return _distinct(eb2.matches_found(), key) >= _distinct(_truth_matches(eb2), key)
		"metric_ge", "metric_le", "metric_eq_opt":
			var sb := d.machine_at(int(c.get("stage", 0))) as TxSabotage
			if sb == null or sb.best < 0:
				return false
			if str(c.kind) == "metric_ge":
				return sb.best >= int(c.v)
			if str(c.kind) == "metric_le":
				return sb.best <= int(c.v)
			return sb.best == sb.optimum
		"strak_ge":
			return strak >= int(c.n)
		"no_tear":
			return d.log.count_type("TEAR") == 0
		"budget_le":
			return d.completed and d.run_machine_time() <= int(c.v)
		"pick_ok":
			var sa := d.last_machine_of(TxShiftAnd) as TxShiftAnd
			return sa != null and sa.chosen >= 0 and sa.exact_starts().has(sa.chosen)
		"no_false_alarms":
			return d.log.count_type("FALSE_ALARM") == 0 and d.log.of_verdict(V.FALSE_ALARM).is_empty() \
					and d.log.of_verdict(V.WRONG_PICK).is_empty() and _no_false(d)
	return false


func _no_false(d: TxDirector) -> bool:
	for mc in d.machines:
		if not mc.false_alarms.is_empty():
			return false
	return true


static func _truth_matches(eb: TxEditBoard) -> Array:
	var out: Array = []
	for o in eb.truth:
		out.append({"start": int(o.start), "end": int(o.end)})
	return out


static func _distinct(list: Array, key: String) -> int:
	var seen := {}
	for x in list:
		var k := ""
		match key:
			"starts":
				k = str(int(x.start))
			"ends":
				k = str(int(x.end))
			_:
				k = "%d:%d" % [int(x.start), int(x.end)]
		seen[k] = true
	return seen.size()


static func star_label(c: Dictionary) -> String:
	match str(c.get("kind", "")):
		"done":
			return "Missie volbracht"
		"all":
			var parts := PackedStringArray()
			for x in c.get("of", []):
				parts.append(star_label(x))
			return " + ".join(parts)
		"any":
			var parts2 := PackedStringArray()
			for x in c.get("of", []):
				parts2.append(star_label(x))
			return " of ".join(parts2)
		"hits_ge":
			return "Codewoord gevonden" if int(c.n) == 1 else "≥ %d codewoorden gevonden" % int(c.n)
		"no_mistakes":
			return "Geen misstappen"
		"no_help":
			return "Zonder hint of terugnemen"
		"no_bumps":
			return "Geen klemmen"
		"time_le":
			return "Binnen %d s" % int(c.s)
		"sequences_ge":
			return "%d verschillende kortste reeksen" % int(c.n)
		"matches_all":
			return "Alle beste matches"
		"starts_all":
			return "Alle beginposities"
		"ends_all":
			return "Alle eindes gemeld"
		"metric_ge":
			return "Tegenzet %d: ≥ %d" % [int(c.stage) + 1, int(c.v)]
		"metric_le":
			return "Tegenzet %d: ≤ %d" % [int(c.stage) + 1, int(c.v)]
		"metric_eq_opt":
			return "Tegenzet %d optimaal" % (int(c.stage) + 1)
		"strak_ge":
			return "≥ %d kaarten strak op de tel" % int(c.n)
		"no_tear":
			return "Geen scheur"
		"budget_le":
			return "Machinetijd ≤ %d" % int(c.v)
		"pick_ok":
			return "Ploeg naar de echte zender"
		"no_false_alarms":
			return "Geen vals alarm"
	return str(c.get("kind", ""))


## Eindrapport (GDD §8.8): sterren, punten met uitsplitsing, tellers vs optimum/geest, lintverslag, misstappen
## (met coachzin + notasverwijzing), tabellen (jouw vs juist), tegenzet.
func final_report(d: TxDirector) -> Dictionary:
	apply_end_bonus(d)
	var spec := d.spec
	var st := [false, false, false]
	var labels := ["", "", ""]
	for i in 3:
		if i < spec.stars.size():
			labels[i] = star_label(spec.stars[i])
			st[i] = eval_star(spec.stars[i], d) and (i == 0 or st[i - 1])
	var n_stars := 0
	for b in st:
		if b:
			n_stars += 1
	var bd: Array = []
	for k in breakdown:
		bd.append({"label": k, "amount": int(breakdown[k])})
	var mistakes: Array = []
	for e in d.log.mistakes():
		mistakes.append({"seq": int(e.seq), "t": float(e.t), "stage": int(e.stage), "type": str(e.type),
			"verdict": int(e.verdict), "verdict_name": TxCodes.verdict_name(int(e.verdict)), "auto": bool(e.auto),
			"coach": d.log.coach_line(e), "ref": d.log.notes_ref(e), "hint": e.hint, "affects": e.affects})
	var hits: Array = []
	var missed: Array = []
	var fa: Array = []
	var tables: Array = []
	var sab: Array = []
	for mc in d.machines:
		for h in mc.hits:
			var hh: Dictionary = h.duplicate()
			hh["stage"] = mc.stage_index
			hits.append(hh)
		for x in mc.missed:
			var xx: Dictionary = x.duplicate()
			xx["stage"] = mc.stage_index
			missed.append(xx)
		for x in mc.false_alarms:
			var ff: Dictionary = x.duplicate()
			ff["stage"] = mc.stage_index
			fa.append(ff)
		var tb := mc.tables()
		if not tb.is_empty():
			tb["stage"] = mc.stage_index
			tables.append(tb)
		if mc is TxSabotage:
			var sb := mc as TxSabotage
			sab.append({"stage": mc.stage_index, "target": sb.target, "best": sb.best, "optimum": sb.optimum,
				"z": sb.zt, "t": sb.tt})
	return {"id": spec.id, "stars": st, "n_stars": n_stars, "star_labels": labels, "points": points,
		"breakdown": bd, "counters": d.total_counters(), "optimum": spec.optimum.duplicate(true),
		"ghost": spec.ghost.duplicate(true), "hits": hits, "missed": missed, "false_alarms": fa,
		"found": d.found_total(), "mistakes": mistakes, "bumps": d.log.bumps().size(), "hints": d.hints,
		"undos": d.undos, "time_s": d.time, "tables": tables, "sabotage": sab, "strak": strak,
		"completed": d.completed, "machine_time": d.run_machine_time(), "choices": d.choices.duplicate(),
		"tapes": d.tapes.duplicate(true), "lives": d.lives, "rival": d.rival() if d.has_rival() else {}}
