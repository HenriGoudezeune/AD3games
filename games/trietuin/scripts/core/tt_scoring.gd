class_name TtScoring extends RefCounted
## Honing, combo, sterren en rapport (GDD §6). Luistert naar model.event_logged/card_finished (via bind).

signal honey_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal bee_dance()

const V := TtCodes.Verdict
const CK := TtCodes.CardKind
const COMBO_WINDOW := 6.0

var honey: int = 0
var combo: int = 0
var max_combo: int = 0
var breakdown: Dictionary = {}     # label -> bedrag
var time: float = 0.0
var swarm: bool = false
var hints: int = 0
var _last_ok: float = -1000.0
var _ask_bonus_patience: bool = false


func bind(director: TtDirector) -> void:
	swarm = director.spec.mode == TtCodes.Mode.SWARM
	var m := director.model
	if not m.event_logged.is_connected(_on_event):
		m.event_logged.connect(_on_event)
	if not m.card_finished.is_connected(_on_card_finished):
		m.card_finished.connect(_on_card_finished)


func tick_real(dt: float) -> void:
	time += dt
	if combo > 0 and time - _last_ok > COMBO_WINDOW:
		combo = 0
		combo_changed.emit(combo)


func _add(amount: int, label: String) -> void:
	if amount == 0:
		return
	honey += amount
	breakdown[label] = int(breakdown.get(label, 0)) + amount
	honey_changed.emit(honey, amount, label)


func _mult() -> int:
	return maxi(combo, 1) if swarm else 1


func _good_card() -> void:
	if not swarm:
		return
	if time - _last_ok <= COMBO_WINDOW:
		combo = mini(combo + 1, 5)
	else:
		combo = 1
	_last_ok = time
	max_combo = maxi(max_combo, combo)
	combo_changed.emit(combo)
	if combo == 5:
		bee_dance.emit()


func break_combo() -> void:
	if combo != 0:
		combo = 0
		combo_changed.emit(combo)


func on_hint() -> void:
	hints += 1
	break_combo()


## Bestelling geslaagd? (alle stappen OK én de uitkomst klopt met wat de tuin had moeten hebben)
static func bee_success(card: TtCard) -> bool:
	var o := card.outcome
	if card.state == "expired" or not bool(o.get("all_ok", false)):
		return false
	var r := str(o.get("result", ""))
	if r in ["found", "wasp_caught"]:
		return true
	if r in ["not_found", "rejected"]:
		return card.expect != 1
	return false


func _on_event(e: Dictionary) -> void:
	if not bool(e.get("ok", true)) or int(e.verdict) != V.OK:
		if int(e.verdict) != V.OK and (bool(e.get("ok", true)) or int(e.verdict) != V.BUMP):
			break_combo()
		return
	match str(e.type):
		"PRUNE":
			_add(10, "snoeien")
		"ATTACH":
			_add(10, "suffixen aangehecht")
		"LABEL":
			_add(5, "bordjes")
		"HOP", "RULE", "LINK", "FOLLOW":
			_add(5, "Ukkonen-beslissingen")
		"WHERE":
			if bool(e.data.get("formula", false)):
				_add(10, "b − l_t")


func _on_card_finished(card: TtCard, o: Dictionary) -> void:
	var ok := bool(o.get("all_ok", false))
	var r := str(o.get("result", ""))
	match card.kind:
		CK.SEED:
			if ok and r in ["planted", "same"]:
				_good_card()
				_add(10 * _mult(), "zaadjes")
			else:
				break_combo()
		CK.BEE:
			if r == "wrong_honey":
				_add(-10, "verkeerde honing")
			elif r == "stolen":
				_add(-20, "gestolen vruchten")
			if bee_success(card):
				_good_card()
				if r == "wasp_caught":
					_add(20 * _mult(), "wespen ontmaskerd")
				else:
					_add(15 * _mult(), "bestellingen")
			else:
				break_combo()
		CK.PRUNE:
			if ok and r == "cut":
				_add(10, "knippen")
		CK.TERNARIFY:
			if r == "converted":
				var balls := 0
				for v in o.get("verdicts", []):
					balls += 1
				_add(5 * balls, "rankknopen")
				if int(o.get("comparisons", -1)) == int(o.get("optimum", -2)):
					_add(20, "kortste vluchten")
		CK.ASK:
			if ok and r == "answered":
				_add(20, "inspecteur")
				if card.patience > 0.0 and card.started_at >= 0.0:
					_add(maxi(0, int(card.patience - (card.finished_at - card.started_at))), "geduld over")
		_:
			pass


func on_bloom(results: Array) -> void:
	var n := 0
	for r in results:
		if bool(r.ok):
			n += 1
	_add(5 * n, "Bloei")


func on_level_end(model: TtTreeModel, ukk_bonus: int) -> void:
	if model.sap_budget < (1 << 29):
		_add(maxi(0, model.sap_budget - model.sap_used()) / 2, "overgebleven sap")
	_add(ukk_bonus, "iteraties zonder misstap")


func state() -> Dictionary:
	return {"honey": honey, "combo": combo, "max_combo": max_combo, "breakdown": breakdown.duplicate(), "hints": hints,
		"last_ok": _last_ok}


func restore_state(d: Dictionary) -> void:
	var delta := int(d.honey) - honey
	honey = int(d.honey)
	combo = int(d.combo)
	max_combo = int(d.max_combo)
	breakdown = (d.breakdown as Dictionary).duplicate()
	_last_ok = float(d.last_ok)
	if delta != 0:
		honey_changed.emit(honey, delta, "terugspoelen")
	combo_changed.emit(combo)


# ------------------------------------------------------------------ sterren en rapport

static func _ctx(director: TtDirector) -> Dictionary:
	var m := director.model
	var spec := director.spec
	var mistakes := director.mistakes()
	var asks := 0
	var asks_ok := 0
	var ask_time := 0.0
	var missed := 0
	var resolved := true
	var expired := 0
	for c in director.cards:
		if c.state != "done" and c.state != "expired":
			resolved = false
		if c.state == "expired":
			expired += 1
		if c.kind == CK.ASK:
			asks += 1
			if c.state == "done" and bool(c.outcome.get("all_ok", false)) and str(c.outcome.get("result", "")) == "answered":
				asks_ok += 1
			if c.started_at >= 0.0 and c.finished_at >= 0.0:
				ask_time += c.finished_at - c.started_at
		if c.kind == CK.BEE and not bee_success(c):
			missed += 1
	var cmp := 0
	var cmp_opt := 0
	if m is TtTernary:
		cmp = (m as TtTernary).comparisons(spec.bloom_present)
		cmp_opt = int(spec.optimum.get("comparisons", 0))
	var beds_bloom := false
	var first_choice := false
	if m is TtBeds:
		beds_bloom = (m as TtBeds).all_bloom()
		first_choice = (m as TtBeds).first_choice_ok()
	return {"resolved": resolved, "expired": expired, "bloom": TtBloom.ratio(director.bloom), "mistakes": mistakes.size(),
		"hints": director.hints, "rewinds": director.rewinds, "sap": m.sap_used(), "time": director.time,
		"end_exact": spec.expect_end != "" and TtNotation.normalize(m.serialize()) == TtNotation.normalize(spec.expect_end),
		"comparisons": cmp, "comparisons_opt": cmp_opt, "asks_ok": asks_ok, "asks": asks,
		"avg_ask": ask_time / maxf(asks, 1), "missed": missed, "max_combo": director.scoring.max_combo,
		"honey": director.scoring.honey, "beds_bloom": beds_bloom, "first_choice": first_choice}


static func eval_star(cond: Dictionary, x: Dictionary) -> bool:
	match str(cond.get("kind", "")):
		"done":
			return bool(x.resolved) and float(x.bloom) >= 0.7
		"no_mistakes":
			return bool(x.resolved) and int(x.mistakes) == 0 and int(x.expired) == 0 and float(x.bloom) >= 1.0
		"no_help":
			return int(x.hints) == 0 and int(x.rewinds) == 0
		"sap_le":
			return int(x.sap) <= int(cond.max)
		"time_le":
			return float(x.time) <= float(cond.s)
		"exact_end":
			return bool(x.end_exact)
		"cmp_le":
			return int(x.comparisons) <= int(cond.max)
		"correct_ge":
			return int(x.asks_ok) >= int(cond.n)
		"max_mistakes":
			return bool(x.resolved) and int(x.mistakes) <= int(cond.n)
		"combo":
			return int(x.max_combo) >= int(cond.n) and int(x.honey) >= int(cond.get("honey", 0))
		"first_choice":
			return bool(x.first_choice)
		"missed_le":
			return bool(x.resolved) and int(x.missed) <= int(cond.n)
		"avg_time_le":
			return float(x.avg_ask) <= float(cond.s)
		"beds_bloom":
			return bool(x.beds_bloom)
		"all":
			for c in cond.get("of", []):
				if not eval_star(c, x):
					return false
			return true
	return false


static func star_label(cond: Dictionary) -> String:
	match str(cond.get("kind", "")):
		"done":
			return "level uitgespeeld, Bloei ≥ 70 %"
		"no_mistakes":
			return "0 misstappen"
		"no_help":
			return "zonder hint of terugspoelen"
		"sap_le":
			return "sap ≤ %d" % int(cond.max)
		"time_le":
			return "binnen %d s" % int(cond.s)
		"exact_end":
			return "eindboom exact zoals de oplossing"
		"cmp_le":
			return "vluchtlengte ≤ %d" % int(cond.max)
		"correct_ge":
			return "≥ %d vragen goed" % int(cond.n)
		"max_mistakes":
			return "0 misstappen" if int(cond.n) == 0 else "≤ %d misstappen" % int(cond.n)
		"combo":
			return "combo ×%d en ≥ %d honing" % [int(cond.n), int(cond.get("honey", 0))]
		"first_choice":
			return "beide keuzes meteen juist"
		"missed_le":
			return "geen bij gemist" if int(cond.n) == 0 else "≤ %d bijen gemist" % int(cond.n)
		"avg_time_le":
			return "gemiddeld ≤ %d s per vraag" % int(cond.s)
		"beds_bloom":
			return "beide bedden bloeien"
		"all":
			var parts := PackedStringArray()
			for c in cond.get("of", []):
				parts.append(star_label(c))
			return " en ".join(parts)
	return ""


func final_report(director: TtDirector) -> Dictionary:
	var spec := director.spec
	var x := _ctx(director)
	var stars := [false, false, false]
	var labels := ["", "", ""]
	for i in mini(3, spec.stars.size()):
		labels[i] = star_label(spec.stars[i])
		stars[i] = eval_star(spec.stars[i], x) and (i == 0 or stars[i - 1])
	var bd: Array = []
	for k in breakdown.keys():
		bd.append({"label": k, "amount": int(breakdown[k])})
	var n_stars := 0
	for s in stars:
		if s:
			n_stars += 1
	return {"stars": stars, "n_stars": n_stars, "star_labels": labels, "honey": honey, "breakdown": bd,
		"sap_used": int(x.sap), "sap_optimum": int(spec.optimum.get("sap", -1)), "sap_budget": spec.sap_budget,
		"sap_peak": director.peak_sap, "ghost": spec.ghost, "comparisons": int(x.comparisons),
		"comparisons_opt": int(x.comparisons_opt), "bloom": director.bloom, "bloom_ratio": float(x.bloom),
		"mistakes": director.mistakes(), "time_s": director.time, "hints": director.hints, "rewinds": director.rewinds,
		"end_exact": bool(x.end_exact), "end": director.model.serialize(), "expect_end": spec.expect_end,
		"asks_ok": int(x.asks_ok), "asks": int(x.asks), "missed": int(x.missed), "max_combo": max_combo,
		"level": spec.id, "title": spec.title, "notes_ref": spec.notes_ref, "extra": spec.extra}
