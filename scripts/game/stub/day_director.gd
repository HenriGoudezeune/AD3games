extends RefCounted
## STUB (tijdelijk) van core DayDirector (GDD §10.6). Enkel RUSTIGE dagen (geen klanten/burst).

signal parcel_spawned(parcel: Parcel)
signal parcel_fell_off(parcel: Parcel)
signal customer_arrived(c: Dictionary)
signal customer_left(c: Dictionary, happy: bool)
signal burst(parcel: Parcel)
signal day_finished(report: Dictionary)

var model: ExtHashModel
var scoring
var spec
var _belt: Array = []
var _next := 0
var _timer := 0.0
var _time := 0.0
var _done := false


func start(s) -> void:
	spec = s
	model = ExtHashModel.new()
	model.setup(spec.n, spec.g, spec.a0)
	model.load_layout(spec.start_layout)
	scoring = preload("res://scripts/game/stub/scoring.gd").new()
	scoring.rep = spec.reputation
	scoring.bind(model)
	_timer = spec.spawn_interval - 0.8


func tick(dt_world: float, dt_real: float) -> void:
	if _done:
		return
	_time += dt_world
	model.now = _time
	scoring.tick_real(dt_real)
	_timer += dt_world
	if _next < spec.keys.size() and _timer >= spec.spawn_interval and _belt.size() < 5:
		_timer = 0.0
		var k: Dictionary = spec.keys[_next]
		_next += 1
		var p := model.new_parcel(HashUtil.from_bits(k.hv), str(k.get("label", "")))
		_belt.append(p)
		parcel_spawned.emit(p)
	if _next >= spec.keys.size() and _belt.is_empty() and not model.is_alarm():
		_done = true
		day_finished.emit(scoring.final_report(model, spec, _time))


func world_time_scale() -> float:
	return 0.35 if model.is_alarm() else 1.0


func belt() -> Array:
	return _belt


func take_front() -> Parcel:
	return _belt.pop_front() if not _belt.is_empty() else null


func take(parcel_id: int) -> Parcel:
	for i in _belt.size():
		if _belt[i].id == parcel_id:
			var p: Parcel = _belt[i]
			_belt.remove_at(i)
			return p
	return null


func serve(_customer_id: int, _dir_index: int) -> Dictionary:
	return {}
