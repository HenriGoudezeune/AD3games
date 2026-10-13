class_name TtDirector extends RefCounted
## Kaartenstroom van een level (GDD §8.9): windrij, klok (SWARM), geduld, hint, terugspoelen, Bloei, rapport.
## Puur: geen nodes. De front-end roept tick(dt) per frame, next_card()/take() om kaarten te starten,
## model.apply(move) voor zetten, en run_bloom() + finish() als all_done().
## Opslaan (TtSave) doet de front-end met report.n_stars / report.honey.

signal card_queued(card: TtCard)                    # verschijnt in de windrij (bij start: alle kaarten)
signal card_arrived(card: TtCard)                   # SWARM: kaart is aangekomen (wacht om gestart te worden)
signal card_started(card: TtCard)
signal card_done(card: TtCard, outcome: Dictionary)
signal card_expired(card: TtCard, reason: String)   # "patience" | "blown" (4e zaadje) | "no_sap"
signal timeline_event(event: Dictionary)            # spec.timeline (bv. stempel, ASCII-storm, telbadges)
signal budget_changed(budget: int)                  # vrije tuin: sap groeit aan
signal bloom_started(results: Array)
signal level_finished(report: Dictionary)

const CK := TtCodes.CardKind
const V := TtCodes.Verdict
const SWARM := TtCodes.Mode.SWARM
const MAX_WAITING_SEEDS := 3

var spec: TtLevelSpec
var model: TtTreeModel
var scoring: TtScoring
var time: float = 0.0
var finished: bool = false
var cards: Array[TtCard] = []
var qi: int = 0                       # CALM: index van de volgende kaart
var arrived: Array[TtCard] = []       # SWARM: aangekomen, nog niet gestart
var hints: int = 0
var rewinds: int = 0
var bloom: Array[Dictionary] = []
var bloom_done: bool = false
var report: Dictionary = {}
var peak_sap: int = 0
var misses: int = 0                   # vrije tuin
var gen: TtWordGen = null
var _rewind: Array = []
var _next_id: int = 1
var _gen_next_seed: float = 0.0
var _gen_next_bee: float = 3.0
var _gen_next_prune: float = 120.0
var _last_card: TtCard = null


func start(s: TtLevelSpec, seed_: int = 0) -> void:
	spec = s
	model = TtLevels.make_model(s)
	scoring = TtScoring.new()
	time = 0.0
	finished = false
	qi = 0
	arrived = []
	hints = 0
	rewinds = 0
	bloom = []
	bloom_done = false
	report = {}
	misses = 0
	_rewind = []
	cards = TtLevels.make_cards(s)
	_next_id = cards.size() + 1
	var present := {}
	for w in s.bloom_present:
		present[w] = true
	for c in cards:
		if c.kind == CK.BEE:
			c.expect = 1 if present.has(c.word) else 0
	peak_sap = model.sap_used()
	model.card_finished.connect(_on_card_finished)
	model.sap_changed.connect(_on_sap)
	scoring.bind(self)
	if s.endless:
		gen = TtWordGen.new(seed_, model.alphabet)
		model.sap_budget = int(s.generator.get("sap_start", s.sap_budget))
	for c in cards:
		card_queued.emit(c)
	if s.mode == SWARM:
		_arrivals()


## Verbreekt alle signaalverbindingen (oproepen bij het verlaten van een level; vermijdt cycli met lambdas).
func dispose() -> void:
	for obj in [self, model, scoring]:
		if obj == null:
			continue
		for sig in obj.get_signal_list():
			for c in obj.get_signal_connection_list(sig.name):
				obj.disconnect(sig.name, c.callable)


func _on_sap(used: int, _delta: int) -> void:
	peak_sap = maxi(peak_sap, used)


func tick(dt: float) -> void:
	if finished:
		return
	time += dt
	model.now = time
	model.log.now = time
	scoring.tick_real(dt)
	if spec.endless:
		_endless_tick()
	if spec.mode == SWARM:
		_arrivals()
	_patience()


func _arrivals() -> void:
	for c in cards:
		if c.state == "waiting" and not arrived.has(c) and c.t <= time:
			arrived.append(c)
			card_arrived.emit(c)
	# een vierde wachtend zaadje blaast het oudste weg
	var seeds: Array[TtCard] = []
	for c in arrived:
		if c.kind == CK.SEED and c.state == "waiting":
			seeds.append(c)
	while seeds.size() > MAX_WAITING_SEEDS:
		var old: TtCard = seeds.pop_front()
		_expire(old, "blown")


func _patience() -> void:
	var act := model.card
	if act != null and act.patience > 0.0:
		var since := act.t if spec.mode == SWARM else act.started_at
		if time - since > act.patience:
			model.abandon_card("patience", V.TIMEOUT)
			act.state = "expired"
			_after_expire(act, "patience")
	if spec.mode == SWARM:
		for c in arrived.duplicate():
			if c.state == "waiting" and c.patience > 0.0 and time - c.t > c.patience:
				_expire(c, "patience")


func _expire(c: TtCard, reason: String) -> void:
	c.state = "expired"
	c.finished_at = time
	arrived.erase(c)
	var aff: Array = [c.word] if c.kind == CK.SEED else []
	var e := model.log.add("EXPIRE", {"why": reason, "word": c.word, "affects": aff},
			V.TIMEOUT if reason == "patience" else V.LOST, {}, {}, c.id)
	model.event_logged.emit(e)
	scoring.break_combo()
	_after_expire(c, reason)


func _after_expire(c: TtCard, reason: String) -> void:
	arrived.erase(c)
	card_expired.emit(c, reason)
	if spec.endless:
		_miss()


func queue() -> Array[TtCard]:
	var out: Array[TtCard] = []
	for c in cards:
		if c.state == "waiting" and not arrived.has(c):
			out.append(c)
	return out


func waiting() -> Array[TtCard]:
	var out: Array[TtCard] = []
	for c in arrived:
		if c.state == "waiting":
			out.append(c)
	return out


func active() -> TtCard:
	return model.card


func next_card() -> TtCard:
	if finished:
		return null
	if model.card != null:
		return model.card
	if spec.mode == SWARM:
		var w := waiting()
		if w.is_empty():
			return null
		return _start_card(w[0])
	while qi < cards.size() and cards[qi].state != "waiting":
		qi += 1
	if qi >= cards.size():
		return null
	var c := cards[qi]
	qi += 1
	return _start_card(c)


func take(card_id: int) -> void:
	if model.card != null:
		return
	for c in waiting():
		if c.id == card_id:
			_start_card(c)
			return


func _start_card(c: TtCard) -> TtCard:
	if spec.mode != SWARM:
		_rewind.append({"snap": model.snapshot(), "qi": qi - 1, "scoring": scoring.state(),
			"seq": model.log.entries.size(), "cards": _card_states(), "time": time})
	arrived.erase(c)
	_last_card = c
	card_started.emit(c)
	model.begin(c)
	return c


func _card_states() -> Array:
	var out := []
	for c in cards:
		out.append(c.to_dict())
	return out


## Leeshulp voor de actieve (of laatst gestarte) kaart (3-2: de eerste kaarten FULL).
func letter_hint() -> int:
	var c := model.card if model.card != null else _last_card
	if c == null:
		return spec.hint_for_card(0)
	return spec.hint_for_card(c.id - 1)


func _on_card_finished(card: TtCard, outcome: Dictionary) -> void:
	if str(outcome.get("result", "")) == "no_sap":
		card_expired.emit(card, "no_sap")
		if spec.endless:
			_miss()
	elif str(outcome.get("result", "")) in ["patience"]:
		pass
	else:
		card_done.emit(card, outcome)
		if spec.endless and _is_miss(card, outcome):
			_miss()
	for ev in spec.timeline:
		if int(ev.get("after_card", -1)) == card.id - 1:
			timeline_event.emit(ev)


func _is_miss(card: TtCard, outcome: Dictionary) -> bool:
	match card.kind:
		CK.BEE:
			return not TtScoring.bee_success(card)
		CK.SEED:
			return str(outcome.get("result", "")) in ["blown", "no_sap"]
	return false


func all_done() -> bool:
	if spec.endless:
		return finished
	if model.card != null:
		return false
	for c in cards:
		if c.state != "done" and c.state != "expired":
			return false
	return true


## Het orakel als hint (kost ★★★, breekt de combo). {} als hints niet mogen.
func hint() -> Dictionary:
	if not spec.hints_allowed or model.card == null:
		return {}
	var m := model.correct_move()
	hints += 1
	var e := model.log.add("HINT", {"move": m}, V.OK, m, {}, model.card.id)
	model.event_logged.emit(e)
	scoring.on_hint()
	return m


## CALM: zet de tuin terug naar vóór de laatste (of de actieve) kaart. Misstappen daarin vervallen.
func rewind() -> bool:
	if spec.mode == SWARM or _rewind.is_empty() or finished:
		return false
	var r: Dictionary = _rewind.pop_back()
	var active_card := model.card
	model.restore(r.snap)
	model.card = null
	for i in cards.size():
		cards[i].load_dict(r.cards[i])
	if active_card != null:
		active_card.state = "waiting"
	qi = int(r.qi)
	scoring.restore_state(r.scoring)
	for k in range(int(r.seq), model.log.entries.size()):
		model.log.entries[k]["rewound"] = true
	rewinds += 1
	var e := model.log.add("REWIND", {"to_card": qi + 1}, V.OK, {}, {}, -1)
	model.event_logged.emit(e)
	return true


## Misstappen van dit level (zonder teruggespoelde events).
func mistakes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in model.log.mistakes(model.count_bumps):
		if not bool(e.get("rewound", false)):
			out.append(e)
	return out


func run_bloom() -> Array[Dictionary]:
	if bloom_done:
		return bloom
	bloom = TtBloom.run(model, spec.bloom_present, spec.bloom_absent)
	bloom_done = true
	scoring.on_bloom(bloom)
	var ok := 0
	for b in bloom:
		if bool(b.ok):
			ok += 1
	var e := model.log.add("BLOOM", {"ok": ok, "total": bloom.size()}, V.OK, {}, {}, -1)
	model.event_logged.emit(e)
	bloom_started.emit(bloom)
	return bloom


func finish() -> Dictionary:
	if not report.is_empty():
		return report
	if not spec.endless:
		run_bloom()
	scoring.on_level_end(model, _ukkonen_bonus())
	report = scoring.final_report(self)
	finished = true
	var e := model.log.add("LEVEL_END", {"stars": report.n_stars, "honey": report.honey}, V.OK, {}, {}, -1)
	model.event_logged.emit(e)
	level_finished.emit(report)
	return report


## +10 per Ukkonen-iteratie zonder misstap.
func _ukkonen_bonus() -> int:
	if not (model is TtUkkonen):
		return 0
	var uk := model as TtUkkonen
	var bad := {}
	for e in mistakes():
		bad[int(e.data.get("it", -1))] = true
	var n := 0
	for i in range(1, uk.it + 1):
		if not bad.has(i):
			n += 1
	return 10 * n


# ------------------------------------------------------------------ vrije tuin

func _endless_tick() -> void:
	var g: Dictionary = spec.generator
	var k := int(time / 30.0)
	var cap := int(g.get("sap_cap", 120))
	var nb := mini(cap, int(g.get("sap_start", 60)) + int(time / float(g.get("sap_regen_s", 3.0))))
	if nb != model.sap_budget:
		model.sap_budget = nb
		budget_changed.emit(nb)
	var ws := _words()
	if time >= _gen_next_seed:
		_gen_next_seed = time + maxf(3.0, 8.0 - 0.5 * k)
		_add_card({"kind": "seed", "word": gen.next_word(ws), "t": time})
	if time >= _gen_next_bee:
		_gen_next_bee = time + maxf(2.5, 7.0 - 0.4 * k)
		var q := gen.next_query(ws, float(g.get("absent_p", 0.25)))
		_add_card({"kind": "bee", "word": q.word, "t": time, "patience": maxf(8.0, 16.0 - 0.6 * k)}, 1 if q.present else 0)
	if time >= float(g.get("prune_from", 120.0)) and time >= _gen_next_prune:
		_gen_next_prune = time + float(g.get("prune_every", 45.0))
		if not ws.is_empty():
			_add_card({"kind": "prune", "word": gen.pick(ws), "t": time})


func _words() -> PackedStringArray:
	if model is TtTrie:
		return (model as TtTrie).words()
	return PackedStringArray()


func _add_card(d: Dictionary, expect: int = -1) -> void:
	var c := TtCard.from_spec(_next_id, d)
	_next_id += 1
	c.expect = expect
	cards.append(c)
	card_queued.emit(c)


func _miss() -> void:
	misses += 1
	if spec.endless and misses >= int(spec.generator.get("misses", 3)) and not finished:
		if model.card != null:
			model.abandon_card("game_over")
		finish()
