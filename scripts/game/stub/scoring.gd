extends RefCounted
## STUB (tijdelijk) van core Scoring (GDD §6, §10.7).

signal coins_changed(coins: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal dash()
signal reputation_changed(rep: int)

var coins := 0
var combo := 1
var rep := 5
var _since := 99.0
var _model: ExtHashModel
var _last_r := 0
var _last_w := 0
var placed := 0
var lost := 0


func bind(m: ExtHashModel) -> void:
	_model = m
	m.event_logged.connect(_on_event)
	m.io_changed.connect(_on_io)


func _add(d: int, why: String) -> void:
	coins += d
	coins_changed.emit(coins, d, why)


func _on_io(r: int, w: int) -> void:
	var d := (r - _last_r) + (w - _last_w)
	_last_r = r
	_last_w = w
	if d > 0:
		_add(-d, "trip")


func _on_event(e: Dictionary) -> void:
	match e.type:
		"DROP", "RETRY":
			var ok := int(e.verdict) == 0 and not bool(e.data.get("misrouted", false))
			var is_placed: bool = e.type == "RETRY" and bool(e.data.get("placed", false)) or e.type == "DROP" and int(e.data.get("status", 1)) == 0
			if e.type == "DROP" and int(e.verdict) != 0:
				_set_combo(1)
			if is_placed and ok:
				placed += 1
				if e.type == "DROP":
					if _since < 3.0:
						_set_combo(mini(combo + 1, 5))
					_since = 0.0
				_add(10 * combo, "placed")
		"LOST":
			lost += 1
			_set_combo(1)
			_add(-5, "lost")
			rep = maxi(0, rep - 1)
			reputation_changed.emit(rep)


func _set_combo(c: int) -> void:
	if c == combo:
		return
	combo = c
	combo_changed.emit(c)
	if c == 5:
		dash.emit()


func on_loupe_used() -> void:
	_set_combo(1)


func on_customer(_happy: bool, _f: float) -> void:
	pass


func tick_real(dt: float) -> void:
	if _model and _model.is_alarm():
		return
	_since += dt
	if _since > 3.0 and combo > 1:
		_set_combo(1)


func final_report(model: ExtHashModel, spec, time_s: float) -> Dictionary:
	var opt: Dictionary = preload("res://scripts/game/stub/days.gd").optimum(spec)
	var mistakes := model.log.mistakes()
	var st := [rep > 0, mistakes.is_empty(), false]
	var third: Dictionary = spec.stars[2] if spec.stars.size() > 2 else {}
	match third.get("kind", ""):
		"time":
			st[2] = time_s <= float(third.max)
		"no_doubles":
			st[2] = model.doubles == 0 and model.reads <= opt.reads and model.writes <= opt.writes
		_:
			st[2] = model.reads <= opt.reads and model.writes <= opt.writes
	var wall := -int(0.5 * (1 << model.a))
	var rack := -model.buckets.size()
	var breakdown := [{"label": "pakjes & combo", "amount": coins - wall - rack}, {"label": "muurhuur", "amount": wall}, {"label": "rekhuur", "amount": rack}]
	return {"stars": st, "coins": coins + wall + rack, "breakdown": breakdown, "reads": model.reads, "writes": model.writes,
		"opt": opt, "mistakes": mistakes, "parcels": placed, "customers_ok": 0, "customers_total": 0}
