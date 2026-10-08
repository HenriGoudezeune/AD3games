class_name DayDirector extends RefCounted
## Headless tijdlijn van een dag (GDD §10.6): spawns, band, klanten, burst-timers, slow-mo-status, dageinde.
## tick(dt_world, dt_real)-gedreven; geen nodes. dt_world is al geschaald met world_time_scale().

signal parcel_spawned(parcel: Parcel)
signal parcel_fell_off(parcel: Parcel)        # band-einde (REALTIME) -> model.lose(parcel, "belt")
signal customer_arrived(c: Dictionary)        # {id, hv, patience, patience_left, parcel_id}
signal customer_left(c: Dictionary, happy: bool)
signal burst(parcel: Parcel)
signal day_finished(report: Dictionary)
signal phase_started(index: int, spec: DaySpec)  # aanvulling: dag 7 (ochtend = 0, middag = 1)

const SLOW_MO := 0.35
const BELT_CAPACITY := 6         # RUSTIG: band stopt met spawnen als er zoveel pakjes op liggen
const BELT_SPACING := 0.16       # minimale afstand (in progress-eenheden) tussen pakjes die aanschuiven
const PATIENCE_PENALTY := 0.25   # klant: fout luik / niet gevonden kost 25 % geduld

var model: ExtHashModel
var scoring: Scoring
var spec: DaySpec                # huidige (fase-)spec
var parent_spec: DaySpec = null  # dag 7: de ouder met phases
var phase_index: int = 0
var time: float = 0.0            # speltijd (wereld)
var time_real: float = 0.0
var finished: bool = false

var _belt: Array[Parcel] = []
var _age: Dictionary = {}        # parcel_id -> wereldtijd op de band
var _len: Dictionary = {}        # parcel_id -> band-looptijd voor dit pakje
var _held: Dictionary = {}       # parcel_id -> true (speler sleept)
var _in_hand: Dictionary = {}    # parcel_id -> Parcel (genomen, nog niet gedropt)
var _next_key: int = 0
var _spawn_timer: float = 0.0
var _customers: Array[Dictionary] = []
var _cust_script: Array[Dictionary] = []
var _cust_next_t: float = INF
var _cust_id: int = 1
var _burst_t: Dictionary = {}    # parcel_id -> wereldtijd vastgezeten
var _rng := RandomNumberGenerator.new()
var _cust_rng := RandomNumberGenerator.new()
var _clone_queue: Array[int] = []
var _next_clone_t: float = INF


# ======================================================================
#  start
# ======================================================================

## Start een dag. Een spec met phases (dag 7) start fase 0; daarna next_phase() na day_finished.
func start(spec_: DaySpec) -> void:
	if not spec_.phases.is_empty():
		parent_spec = spec_
		phase_index = 0
		_start_phase(spec_.phases[0])
	else:
		parent_spec = null
		phase_index = 0
		_start_phase(spec_)


func has_next_phase() -> bool:
	return parent_spec != null and phase_index + 1 < parent_spec.phases.size()


## Start de volgende fase (dag 7 middag). false als er geen is.
func next_phase() -> bool:
	if not has_next_phase():
		return false
	phase_index += 1
	_start_phase(parent_spec.phases[phase_index])
	return true


func _start_phase(s: DaySpec) -> void:
	spec = s
	model = ExtHashModel.new()
	model.setup(s.n, s.g, s.a0)
	model.load_layout(s.start_layout)
	model.allow_dump = s.overflow_bin
	model.double_refused.connect(_on_double_refused)
	model.parcel_placed.connect(func(p, _b, _i, _v): _in_hand.erase(p.id))
	model.parcel_blocked.connect(func(p, _b, _i): _in_hand.erase(p.id))
	model.parcel_dumped.connect(func(p, _v): _in_hand.erase(p.id))
	model.parcel_lost.connect(func(p, _r): _in_hand.erase(p.id))
	scoring = Scoring.new()
	scoring.rep = s.reputation
	scoring.rep_max = s.reputation
	scoring.rep_regen_every = 25 if s.endless else 0
	scoring.bind(model)
	time = 0.0
	time_real = 0.0
	finished = false
	_belt.clear()
	_age.clear()
	_len.clear()
	_held.clear()
	_in_hand.clear()
	_next_key = 0
	_spawn_timer = s.spawn_interval  # eerste pakje meteen
	_customers.clear()
	_cust_script.clear()
	for c in s.customers:
		_cust_script.append(c)
	_cust_script.sort_custom(func(x, y): return float(x.t) < float(y.t))
	_cust_id = 1
	_burst_t.clear()
	_clone_queue.clear()
	var gen := s.generator
	_rng.seed = int(gen.get("seed", 1))
	_next_clone_t = float(gen.get("clone_after", INF)) if not gen.is_empty() else INF
	_cust_next_t = INF
	if not s.customer_gen.is_empty():
		_cust_rng.seed = int(s.customer_gen.get("seed", 0))
		_cust_next_t = float(s.customer_gen.get("start", 30.0))
	phase_started.emit(phase_index, spec)


# ======================================================================
#  tijd
# ======================================================================

## 0.35 als er iets vastzit of een split bezig is (alarm), anders 1.0. Gameplay past dit toe op de wereld.
func world_time_scale() -> float:
	return SLOW_MO if model.is_alarm() else 1.0


func tick(dt_world: float, dt_real: float) -> void:
	if finished or spec == null:
		return
	time += dt_world
	time_real += dt_real
	model.now = time
	scoring.tick_real(dt_real)
	_tick_spawn(dt_world)
	_tick_belt(dt_world)
	_tick_burst(dt_world)
	_tick_customers(dt_world)
	_check_end()


func _belt_time_now() -> float:
	if spec.endless:
		return float(Days.endless_tempo(time).belt_time)
	return spec.belt_time if spec.belt_time > 0 else 14.0


func _spawn_interval_now() -> float:
	if spec.endless:
		return float(Days.endless_tempo(time).spawn_interval)
	return spec.spawn_interval


func _keys_left() -> bool:
	return spec.endless or _next_key < spec.keys.size()


func _tick_spawn(dt: float) -> void:
	if not _keys_left():
		return
	_spawn_timer += dt
	if _spawn_timer < _spawn_interval_now():
		return
	if not spec.is_realtime() and _belt.size() >= BELT_CAPACITY:
		return
	_spawn_timer = 0.0
	var p: Parcel
	if spec.endless:
		p = _gen_parcel()
	else:
		var k: Dictionary = spec.keys[_next_key]
		_next_key += 1
		p = model.new_parcel(HashUtil.from_bits(str(k.hv)), str(k.get("label", "")), bool(k.get("clone", false)))
	_belt.append(p)
	_age[p.id] = 0.0
	_len[p.id] = _belt_time_now()
	model.log_event("SPAWN", {"parcel_id": p.id, "hv": p.hv, "clone": p.is_clone})
	parcel_spawned.emit(p)


## Aantal pakjes met deze hv in het depot (rekken, blocked, band, hand, sorteertafel).
func count_existing(hv: int) -> int:
	var c := 0
	for b in model.buckets:
		c += b.count_hv(hv)
	for e in model.blocked:
		if (e.parcel as Parcel).hv == hv:
			c += 1
	if not model.splitting.is_empty():
		for q in model.splitting.pending:
			if (q as Parcel).hv == hv:
				c += 1
	for q in _belt:
		if q.hv == hv:
			c += 1
	for q in _in_hand.values():
		if (q as Parcel).hv == hv:
			c += 1
	return c


## Endless-generator (GDD §5.2): uniform n-bit; vóór clone_after herrold bij >= g identieke;
## daarna elke clone_every een kloonburst (een waarde die het vaakst voorkomt, aangevuld tot g + 1..2).
func _gen_parcel() -> Parcel:
	var gen := spec.generator
	var maxv := (1 << spec.n) - 1
	if _clone_queue.is_empty() and time >= _next_clone_t:
		_next_clone_t = time + float(gen.get("clone_every", 40.0))
		var best := -1
		var best_c := 0
		for p in model.all_parcels():
			var c := count_existing(p.hv)
			if c > best_c:
				best_c = c
				best = p.hv
		if best >= 0:
			for i in maxi(spec.g - best_c, 0) + _rng.randi_range(1, 2):
				_clone_queue.append(best)
	var hv: int
	if not _clone_queue.is_empty():
		hv = _clone_queue.pop_front()
	else:
		hv = _rng.randi_range(0, maxv)
		if time < float(gen.get("clone_after", 180.0)):
			for i in 64:
				if count_existing(hv) + 1 < spec.g:
					break
				hv = _rng.randi_range(0, maxv)
	return model.new_parcel(hv, "", count_existing(hv) >= spec.g)


func _tick_belt(dt: float) -> void:
	var i := 0
	var slot := 0
	while i < _belt.size():
		var p: Parcel = _belt[i]
		if _held.has(p.id):
			i += 1
			continue
		_age[p.id] = float(_age[p.id]) + dt
		var L := float(_len[p.id])
		if spec.is_realtime():
			if float(_age[p.id]) >= L:
				_belt.remove_at(i)
				_age.erase(p.id)
				parcel_fell_off.emit(p)
				model.lose(p, "belt")
				continue
		else:
			# RUSTIG: aanschuiven tot het einde, niet vallen
			var cap := maxf(0.0, 1.0 - slot * BELT_SPACING)
			_age[p.id] = minf(float(_age[p.id]), cap * L)
		slot += 1
		i += 1


func _tick_burst(dt: float) -> void:
	if not spec.is_realtime() or spec.burst_time <= 0.0:
		_burst_t.clear()
		return
	var alive := {}
	for e in model.blocked:
		alive[(e.parcel as Parcel).id] = true
	for k in _burst_t.keys():
		if not alive.has(k):
			_burst_t.erase(k)
	if not model.splitting.is_empty():
		return  # de speler is bezig: timers pauzeren tijdens het verdelen
	for e in model.blocked.duplicate():
		var p: Parcel = e.parcel
		_burst_t[p.id] = float(_burst_t.get(p.id, 0.0)) + dt
		if float(_burst_t[p.id]) >= spec.burst_time:
			_burst_t.erase(p.id)
			burst.emit(p)
			model.lose(p, "burst")


func _on_double_refused() -> void:
	# hendel op de eindaanslag terwijl het algoritme echt faalt (identieke hv, a == n): de buis barst (dag 7)
	var m := model.correct_move()
	if m.action == "fail":
		for e in model.blocked:
			if (e.parcel as Parcel).id == int(m.parcel_id):
				var p: Parcel = e.parcel
				_burst_t.erase(p.id)
				burst.emit(p)
				model.lose(p, "burst", true)
				return


# ======================================================================
#  klanten
# ======================================================================

func _tick_customers(dt: float) -> void:
	while not _cust_script.is_empty() and time >= float(_cust_script[0].t):
		var c: Dictionary = _cust_script.pop_front()
		_arrive(HashUtil.from_bits(str(c.hv)), float(c.get("patience", 15.0)), -1)
	if time >= _cust_next_t:
		var cg := spec.customer_gen
		var every := float(cg.get("every", 10.0))
		var pat := float(cg.get("patience", 15.0))
		if spec.endless:
			var tempo := Days.endless_tempo(time)
			every = float(tempo.customer_every)
			pat = float(tempo.patience)
		_cust_next_t = time + every
		var stored := model.all_parcels()
		if not stored.is_empty() and (spec.endless or _keys_left() or not _belt.is_empty() or model.is_alarm()):
			var p: Parcel = stored[_cust_rng.randi_range(0, stored.size() - 1)]
			_arrive(p.hv, pat, p.id)
	for c in _customers.duplicate():
		c.patience_left = float(c.patience_left) - dt
		if float(c.patience_left) <= 0.0:
			_leave(c, false)


func _arrive(hv: int, patience: float, parcel_id: int) -> void:
	var c := {"id": _cust_id, "hv": hv, "patience": patience, "patience_left": patience, "parcel_id": parcel_id, "t": time}
	_cust_id += 1
	_customers.append(c)
	model.log_event("CUSTOMER_IN", {"customer_id": c.id, "hv": hv})
	customer_arrived.emit(c)


func _leave(c: Dictionary, happy: bool) -> void:
	_customers.erase(c)
	var frac := clampf(float(c.patience_left) / maxf(float(c.patience), 0.001), 0.0, 1.0)
	scoring.on_customer(happy, frac)
	if happy:
		model.log_event("CUSTOMER_OK", {"customer_id": c.id, "hv": c.hv, "patience_frac": frac})
	else:
		var data := {"customer_id": c.id, "hv": c.hv}
		var cause := model.log.cause_of(int(c.parcel_id)) if int(c.parcel_id) >= 0 else model.log.cause_of_hv(int(c.hv))
		if not cause.is_empty():
			data["cause_seq"] = cause.seq
		model.log_event("CUSTOMER_ANGRY", data, ExtHashModel.Verdict.LOST)
	customer_left.emit(c, happy)


## Wachtende klanten in volgorde van aankomst: [{id, hv, patience, patience_left, parcel_id, t}].
func customers() -> Array[Dictionary]:
	return _customers.duplicate()


## Help klant via luik dir_index (roept model.lookup). -> lookup-resultaat + {happy, customer_id}.
## Niet gevonden -> klant verliest 25 % geduld (en loopt boos weg als het op is).
func serve(customer_id: int, dir_index: int) -> Dictionary:
	var c := {}
	for x in _customers:
		if int(x.id) == customer_id:
			c = x
	if c.is_empty():
		return {}
	var r := model.lookup(dir_index, int(c.hv))
	r["customer_id"] = customer_id
	r["happy"] = bool(r.found)
	if r.found:
		_leave(c, true)
	else:
		c.patience_left = float(c.patience_left) - PATIENCE_PENALTY * float(c.patience)
		if float(c.patience_left) <= 0.0:
			_leave(c, false)
	return r


# ======================================================================
#  band
# ======================================================================

## Pakjes op de band, voorste eerst (inclusief vastgehouden pakjes).
func belt() -> Array[Parcel]:
	return _belt.duplicate()


## 0 = net gespawnd, 1 = einde band. -1 als het pakje niet op de band ligt.
func belt_progress(parcel_id: int) -> float:
	if not _age.has(parcel_id):
		return -1.0
	return clampf(float(_age[parcel_id]) / maxf(float(_len[parcel_id]), 0.001), 0.0, 1.0)


## Speler sleept dit pakje: het schuift niet op en valt niet. Loslaten naast een luik -> set_held(id, false).
func set_held(parcel_id: int, held: bool) -> void:
	if held:
		_held[parcel_id] = true
	else:
		_held.erase(parcel_id)


func take_front() -> Parcel:
	if _belt.is_empty():
		return null
	return take(_belt[0].id)


## Neem een pakje van de band (de speler dropt het daarna via model.drop of model.dump).
func take(parcel_id: int) -> Parcel:
	for i in _belt.size():
		if _belt[i].id == parcel_id:
			var p: Parcel = _belt[i]
			_belt.remove_at(i)
			_age.erase(parcel_id)
			_len.erase(parcel_id)
			_held.erase(parcel_id)
			_in_hand[parcel_id] = p
			return p
	return null


## Resterende speltijd tot de buis van dit vastzittende pakje barst; -1 als er geen burst is.
func burst_left(parcel_id: int) -> float:
	if not spec.is_realtime() or spec.burst_time <= 0.0:
		return -1.0
	var found := false
	for e in model.blocked:
		if (e.parcel as Parcel).id == parcel_id:
			found = true
	if not found:
		return -1.0
	return maxf(0.0, spec.burst_time - float(_burst_t.get(parcel_id, 0.0)))


# ======================================================================
#  einde
# ======================================================================

func _check_end() -> void:
	if finished:
		return
	if scoring.rep <= 0:
		_finish()
		return
	if spec.endless:
		return
	if _keys_left() or not _belt.is_empty() or not _in_hand.is_empty() or model.is_alarm():
		return
	if not _customers.is_empty() or not _cust_script.is_empty():
		return
	_finish()


## Beëindig de dag nu (bv. "Stoppen" in endless). Emit day_finished(report).
func finish_now() -> void:
	if not finished:
		_finish()


func _finish() -> void:
	finished = true
	model.log_event("DAY_END", {"time": time, "rep": scoring.rep})
	var report := scoring.final_report(model, spec, time)
	report["phase_index"] = phase_index
	report["has_next_phase"] = has_next_phase()
	report["endless"] = spec.endless
	report["end_snapshot"] = model.snapshot()
	day_finished.emit(report)
