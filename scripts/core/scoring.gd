class_name Scoring extends RefCounted
## Munten, combo, reputatie en sterren (GDD §6). Luistert zelf naar het model (bind).

signal coins_changed(coins: int, delta: int, reason: String)
signal combo_changed(combo: int)  # 1..5
signal dash()                     # combo bereikt 5
signal reputation_changed(rep: int)

const COMBO_WINDOW := 3.0
const COMBO_MAX := 5
const V := ExtHashModel.Verdict

var coins: int = 0
var combo: int = 1
var rep: int = 5
var rep_max: int = 5

# --- aanvullingen ---
var rep_regen_every: int = 0      # endless: +1 ♥ per zoveel correcte pakjes op rij (0 = uit)
var placed_ok: int = 0            # correct geplaatste pakjes
var placed_total: int = 0         # alle geplaatste pakjes (ook verdwaald)
var lost_count: int = 0
var customers_ok: int = 0
var customers_total: int = 0
var streak: int = 0               # correcte pakjes op rij (voor rep_regen)
var totals: Dictionary = {}       # reden -> som (voor de breakdown)

var _model: ExtHashModel
var _since: float = 0.0           # echte tijd sinds de laatste correcte plaatsing
var _has_last: bool = false
var _last_r: int = 0
var _last_w: int = 0


func bind(model: ExtHashModel) -> void:
	_model = model
	_last_r = model.reads
	_last_w = model.writes
	model.event_logged.connect(_on_event)
	model.io_changed.connect(_on_io)


func _add(delta: int, reason: String) -> void:
	if delta == 0:
		return
	coins += delta
	totals[reason] = int(totals.get(reason, 0)) + delta
	coins_changed.emit(coins, delta, reason)


func _set_combo(c: int) -> void:
	if c == combo:
		return
	combo = c
	combo_changed.emit(combo)
	if combo == COMBO_MAX:
		dash.emit()


func _break_combo() -> void:
	_has_last = false
	_since = 0.0
	_set_combo(1)


func _set_rep(r: int) -> void:
	r = clampi(r, 0, rep_max)
	if r == rep:
		return
	rep = r
	reputation_changed.emit(rep)


func _correct_placement() -> void:
	placed_ok += 1
	placed_total += 1
	if _has_last and _since < COMBO_WINDOW:
		_set_combo(mini(combo + 1, COMBO_MAX))
	elif not _has_last:
		_set_combo(1)
	_add(10 * combo, "pakjes")
	_has_last = true
	_since = 0.0
	streak += 1
	if rep_regen_every > 0 and streak % rep_regen_every == 0 and rep < rep_max:
		_set_rep(rep + 1)


func _lost(reason: String) -> void:
	lost_count += 1
	streak = 0
	_add(-5, "kwijt")
	_set_rep(rep - 1)
	_break_combo()


func _on_event(e: Dictionary) -> void:
	var d: Dictionary = e.data
	var v := int(e.verdict)
	match e.type:
		"DROP":
			if v != V.OK:
				streak = 0
				_break_combo()
				if int(d.status) == ExtHashModel.Drop.PLACED:
					placed_total += 1
			elif int(d.status) == ExtHashModel.Drop.PLACED:
				_correct_placement()
		"RETRY":
			if bool(d.get("placed", false)):
				if bool(d.get("misrouted", false)):
					placed_total += 1
				else:
					_correct_placement()
		"ASSIGN":
			if v != V.OK:
				streak = 0
				_break_combo()
		"LOST":
			_lost(str(d.get("reason", "")))
		"DUMP":
			if v == V.OK:
				_add(5, "klonen herkend")
			else:
				_add(-5, "bakkosten")
				_lost("dump_healthy")


func _on_io(r: int, w: int) -> void:
	var delta := (r - _last_r) + (w - _last_w)
	_last_r = r
	_last_w = w
	if delta > 0:
		_add(-delta, "ritten")


func on_loupe_used() -> void:
	_break_combo()


## Klant vertrekt: blij (+15 + fooi 0..10 lineair met resterend geduld) of boos (−1 ♥).
func on_customer(happy: bool, patience_frac: float) -> void:
	customers_total += 1
	if happy:
		customers_ok += 1
		_add(15 + int(round(10.0 * clampf(patience_frac, 0.0, 1.0))), "klanten")
	else:
		_set_rep(rep - 1)


## Combo-timeout in echte tijd; gepauzeerd tijdens een alarm (vastloper/split).
func tick_real(dt: float) -> void:
	if _model != null and _model.is_alarm():
		return
	if not _has_last:
		return
	_since += dt
	if _since >= COMBO_WINDOW and combo > 1:
		_set_combo(1)


## Huur aan het einde van de dag: muur −0,5 per luik (2^a, naar boven afgerond), rek −1 per rek.
static func rent(model: ExtHashModel) -> Dictionary:
	return {"wall": -int(ceil(0.5 * (1 << model.a))), "racks": -model.buckets.size()}


## Klopt de eindtoestand met spec.expect_end (a + per rek label en inhoud, volgorde in het rek telt niet)?
static func end_state_ok(model: ExtHashModel, spec: DaySpec) -> bool:
	var ee: Dictionary = spec.expect_end
	if ee.is_empty():
		return true
	if model.a != int(ee.a):
		return false
	var lay := model.layout()
	var want: Array = ee.layout
	if lay.size() != want.size():
		return false
	for i in lay.size():
		if lay[i].label != want[i].label:
			return false
		var got := []
		for p in model.buckets[int(lay[i].bucket_id)].parcels:
			got.append(HashUtil.bits(p.hv, model.n))
		var w: Array = want[i].hvs.duplicate()
		got.sort()
		w.sort()
		if got != w:
			return false
	return true


## {stars:[bool,bool,bool], coins, breakdown:[{label, amount}], reads, writes, opt:{...}, mistakes:[entry],
##  parcels, customers_ok, customers_total, + time, failed, rent, end_state_ok, coach:[{seq, t, line}]}
## Sterren zijn cumulatief (★★ vereist ★). Muteert niets (huur zit enkel in "coins" van het rapport).
func final_report(model: ExtHashModel, spec: DaySpec, time_s: float) -> Dictionary:
	var opt := Days.optimum(spec)
	var mistakes := model.log.mistakes()
	var r := rent(model)
	var stars := [false, false, false]
	var conds := []
	for s in spec.stars:
		conds.append(_star_ok(s, model, spec, opt, mistakes, time_s))
	var prev := true
	for i in mini(conds.size(), 3):
		stars[i] = prev and bool(conds[i])
		prev = stars[i]
	if spec.no_stars or spec.stars.is_empty():
		stars = [false, false, false]
	var breakdown := []
	for k in ["pakjes", "klanten", "klonen herkend", "ritten", "kwijt", "bakkosten"]:
		if totals.has(k):
			breakdown.append({"label": k, "amount": int(totals[k])})
	breakdown.append({"label": "muurhuur", "amount": r.wall})
	breakdown.append({"label": "rekhuur", "amount": r.racks})
	var coach := []
	for e in mistakes:
		coach.append({"seq": e.seq, "t": e.t, "type": e.type, "line": model.log.coach_line(e)})
	return {
		"stars": stars, "star_count": stars.count(true), "coins": coins + r.wall + r.racks, "breakdown": breakdown,
		"reads": model.reads, "writes": model.writes, "opt": opt, "mistakes": mistakes, "parcels": placed_total,
		"parcels_ok": placed_ok, "lost": lost_count, "customers_ok": customers_ok, "customers_total": customers_total,
		"time": time_s, "failed": rep <= 0, "rent": r, "end_state_ok": end_state_ok(model, spec), "coach": coach,
		"doubles": model.doubles, "splits": model.splits, "a": model.a, "day": spec.day_number, "spec_id": spec.id,
	}


func _star_ok(s: Dictionary, model: ExtHashModel, spec: DaySpec, opt: Dictionary, mistakes: Array, time_s: float) -> bool:
	var io_ok := model.reads <= int(opt.get("reads", 0)) + customers_total and model.writes <= int(opt.get("writes", 0))
	match str(s.get("kind", "")):
		"done":
			return rep > 0
		"no_mistakes":
			if not mistakes.is_empty():
				return false
			if bool(s.get("all_customers", false)):
				return customers_ok == customers_total and customers_total >= spec.customers.size()
			return true
		"io_optimal":
			return io_ok
		"no_doubles":
			return model.doubles == 0 and io_ok
		"time":
			return time_s <= float(s.get("max", 0.0))
		"end_state":
			return end_state_ok(model, spec)
	return false
