class_name ScScoring extends RefCounted
## Punten, combo, sterren en het eindrapport (GDD §6). Campagne: de punten worden altijd uit de log herberekend (zo
## kloppen ze ook na terugnemen en hernemen). Nachtwake: live, met combo (§6.6).
## Punten (§6.3): correcte beslissing +10 (ten hoogste zoveel als bij perfect spel) · voorlezing/kopie exact +200 ·
## bespaard t.o.v. gewoon schrift +1 per bit, +5 per teken (zegels, stempels) · misstap −20 · klem −5 ·
## anders gelezen letter −10 · tweede duif −50.

signal points_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal full_flame()

const V := ScCodes.Verdict
const DECISIONS := ["READ", "CUT", "DONE", "SEND", "BIND", "WRITE", "SWAP", "KEEP", "SEGMENT", "BIT", "START", "LITERAL",
	"EXTEND", "STAMP", "CARVE", "INSERT", "MARK", "FIND", "NUMBER", "PICK", "ROOST", "DECREE"]
const COMBO_WINDOW := 2.5

var points: int = 0
var combo: int = 1
var streak: int = 0
var since: float = 999.0
var breakdown: Dictionary = {}
var director: ScDirector = null
var decision_cap: int = -1


func bind(d: ScDirector) -> void:
	director = d


func attach(t: ScTool) -> void:
	t.event_logged.connect(_on_event)


func _endless() -> bool:
	return director != null and director.spec != null and director.spec.endless


func _on_event(e: Dictionary) -> void:
	if _endless():
		_live(e)
	else:
		refresh("zet")


## Herberekent de punten uit de log (campagne) en meldt een verschil.
func refresh(reason := "") -> void:
	if director == null or _endless():
		return
	var old := points
	var r := compute(director)
	points = int(r.points)
	breakdown = r.breakdown
	if points != old:
		points_changed.emit(points, points - old, reason)


func compute(d: ScDirector) -> Dictionary:
	var bd := {}
	var dec := 0
	var cap := decision_cap
	for e in d.log.entries:
		if not bool(e.ok):
			_add(bd, "klemmen", -5)
			continue
		var v := int(e.verdict)
		var typ := str(e.type)
		if typ == "READING":
			var rd: Dictionary = e.data
			if bool(rd.get("demo", false)):
				continue
			if bool(rd.get("equal", false)):
				_add(bd, "verliesloos", 200)
			_add(bd, "anders gelezen letters", -10 * int(rd.get("diff", 0)))
			_add(bd, "bespaarde inkt", int(rd.get("saved_points", 0)))
			if int(rd.get("pigeons", 1)) > 1:
				_add(bd, "tweede duif", -50)
			continue
		if bool(e.auto) or not DECISIONS.has(typ):
			continue
		if v == V.OK:
			if cap < 0 or dec < cap:
				dec += 1
				_add(bd, "correcte beslissingen", 10)
		elif v != V.BUMP and not ScCodes.CONSEQUENCES.has(v):
			_add(bd, "misstappen", -20)
	var tot := 0
	for k in bd:
		tot += int(bd[k])
	return {"points": tot, "breakdown": bd}


static func _add(bd: Dictionary, label: String, amount: int) -> void:
	if amount == 0:
		return
	bd[label] = int(bd.get(label, 0)) + amount


# ------------------------------------------------------------------ Nachtwake (live)

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


func tick_real(dt: float) -> void:
	since += dt
	if since > COMBO_WINDOW and streak > 0:
		break_combo()


func _live(e: Dictionary) -> void:
	if not bool(e.ok) or bool(e.auto):
		return
	var v := int(e.verdict)
	var typ := str(e.type)
	if v != V.OK:
		break_combo()
		return
	if typ != "BIND" and typ != "READ":
		return
	streak = streak + 1 if since <= COMBO_WINDOW or streak == 0 else 1
	since = 0.0
	var nc := 1
	if streak >= 10:
		nc = 4
	elif streak >= 6:
		nc = 3
	elif streak >= 3:
		nc = 2
	if nc != combo:
		combo = nc
		combo_changed.emit(combo)
		if combo == 4:
			full_flame.emit()
	add(10 * combo, "paren" if typ == "BIND" else "gelezen letters")


## Nachtwake: einde van een ronde: +50 + 5 × resterende hele seconden.
func round_bonus(seconds_left: float) -> void:
	add(50 + 5 * maxi(0, int(floor(seconds_left))), "rondes")


# ------------------------------------------------------------------ sterren

func eval_star(c: Dictionary, d: ScDirector) -> bool:
	match str(c.get("kind", "")):
		"done":
			return d.completed
		"all":
			for x in c.get("of", []):
				if not eval_star(x, d):
					return false
			return true
		"lossless":
			if not d.completed:
				return false
			for r in d.readings:
				if not bool(r.get("demo", false)) and not bool(r.equal):
					return false
			return true
		"no_mistakes":
			return d.log.mistakes().is_empty()
		"no_help":
			return d.hints == 0 and d.undos == 0 and d.resumes == 0 and not d.assisted
		"no_bumps":
			return d.log.bumps().is_empty()
		"time_le":
			return d.time <= float(c.s)
		"readings_all":
			for t in d.tools:
				if t is ScCodeBoard and (t as ScCodeBoard).mode == "cuts":
					return (t as ScCodeBoard).readings.size() >= (t as ScCodeBoard).parses.size()
			return false
		"search_le":
			return d.completed and int(d.total_counters().search) <= int(c.v)
		"decrees_ok":
			for t in d.tools:
				if t is ScDovecote:
					return (t as ScDovecote).decrees_ok()
			return false
	return false


static func star_label(c: Dictionary) -> String:
	match str(c.get("kind", "")):
		"done":
			return "Voltooid"
		"all":
			var parts := PackedStringArray()
			for x in c.get("of", []):
				parts.append(star_label(x))
			return " + ".join(parts)
		"lossless":
			return "Verliesloos"
		"no_mistakes":
			return "Geen misstappen"
		"no_help":
			return "Zonder hulp"
		"no_bumps":
			return "Geen klemmen"
		"time_le":
			return "Binnen %d s" % int(c.s)
		"readings_all":
			return "Alle lezingen"
		"search_le":
			return "Zoekwerk ≤ %d" % int(c.v)
		"decrees_ok":
			return "Beide decreten juist"
	return str(c.get("kind", ""))


# ------------------------------------------------------------------ rapport

## GDD §8.8.
func final_report(d: ScDirector) -> Dictionary:
	if not _endless():
		var r := compute(d)
		points = int(r.points)
		breakdown = r.breakdown
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
			"verdict": int(e.verdict), "verdict_name": ScCodes.verdict_name(int(e.verdict)), "coach": d.log.coach_line(e),
			"ref": d.log.notes_ref(e), "hint": e.hint, "affects": e.affects, "at": int((e.data as Dictionary).get("at", 0)),
			"move": (e.data as Dictionary).get("move", {})})
	var main := {}
	for r2 in d.readings:
		if not bool(r2.get("demo", false)):
			main = r2
	var pigeons := 1
	for r3 in d.readings:
		pigeons = maxi(pigeons, int(r3.get("pigeons", 1)))
	return {"id": spec.id, "stars": st, "n_stars": n_stars, "star_labels": labels, "points": points, "breakdown": bd,
		"counters": d.total_counters(), "optimum": spec.optimum.duplicate(true), "ghosts": spec.ghosts.duplicate(true),
		"original": str(main.get("original", "")), "read": str(main.get("read", "")), "marks": main.get("marks", []),
		"pigeons": pigeons, "readings": d.readings.duplicate(true), "mistakes": mistakes, "bumps": d.log.bumps().size(),
		"hints": d.hints, "undos": d.undos, "resumes": d.resumes, "time_s": d.time, "structures": d.structures(),
		"completed": d.completed, "rounds": d.rounds, "lives": d.lives}
