class_name TtTreeModel extends RefCounted
## Basisklasse van alle Trietuin-modellen (GDD §8.5): toppen, sap, kaart-operatie, log, snapshot, apply/orakel.
## Pure logica: geen nodes, geen Engine/Time-calls. Subklassen implementeren de _-methodes.
##
## apply(move) -> {"ok": bool, "verdict": int, "reason": String, "done": bool}
##   ok = false: fysiek onmogelijk ("klonk"); de staat verandert niet (uitz.: reason "no_sap" laat het zaadje
##   wegwaaien = de kaart eindigt met result "no_sap"). Er volgt changed({"fx":"bump"}) en een logentry (ok=false).
##   ok = true: uitgevoerd. Volgorde van signalen: alle changed(fx) → sap_changed (als sap wijzigde) → event_logged →
##   phase_changed (na elke uitgevoerde zet) → card_finished (als done).

signal changed(fx: Dictionary)
signal phase_changed(phase: int, cursor: Dictionary)
signal card_started(card: TtCard)
signal card_finished(card: TtCard, outcome: Dictionary)
signal sap_changed(used: int, delta: int)
signal event_logged(entry: Dictionary)

const V := TtCodes.Verdict
const P := TtCodes.Phase
const CK := TtCodes.CardKind
const NT := TtNode.Type

var kind: int = TtCodes.Kind.TRIE
var alphabet: TtAlphabet
var nodes: Dictionary = {}          # id -> TtNode
var root: int = -1
var next_id: int = 0
var sap_budget: int = 1 << 30
var card: TtCard = null             # actieve kaart of null
var phase: int = TtCodes.Phase.IDLE
var log: TtEventLog = TtEventLog.new()
var now: float = 0.0                # gameplay zet dit elke frame (tijdstempel voor de log)
var count_bumps := false            # uit de levelspec (Ukkonen: true)
var st: Dictionary = {}             # toestand van de actieve kaart-operatie (JSON-serialiseerbaar)

var _fx: Array[Dictionary] = []
var _finish_req: Dictionary = {}    # {result, extra} als de kaart na deze zet af is
var _verdicts: Array = []           # verdicts binnen de actieve kaart
var _moves: int = 0                 # zetten binnen de actieve kaart


# ------------------------------------------------------------------ toppen

func node(id: int) -> TtNode:
	return nodes.get(id, null)


func _new_node(type: int) -> TtNode:
	var n := TtNode.make(next_id, type)
	next_id += 1
	nodes[n.id] = n
	return n


func _clear_nodes() -> void:
	nodes.clear()
	next_id = 0
	root = -1


## Alle ids in de deelboom onder id (incl. id), pre-order.
func subtree(id: int) -> Array[int]:
	var out: Array[int] = []
	var stack: Array[int] = [id]
	while not stack.is_empty():
		var x: int = stack.pop_back()
		var n := node(x)
		if n == null:
			continue
		out.append(x)
		var ch := _children(n)
		for i in range(ch.size() - 1, -1, -1):
			stack.append(ch[i])
	return out


## Kinderen van een top in weergavevolgorde (subklassen mogen overschrijven).
func _children(n: TtNode) -> Array[int]:
	var out: Array[int] = []
	for k in alphabet.sorted(n.kids.keys()):
		out.append(int(n.kids[k]))
	return out


func children(id: int) -> Array[int]:
	var n := node(id)
	if n == null:
		return []
	return _children(n)


func leaves_under(id: int) -> Array[int]:
	var out: Array[int] = []
	for x in subtree(id):
		if node(x).type == NT.LEAF:
			out.append(x)
	return out


func count_type(t: int) -> int:
	var c := 0
	for n in nodes.values():
		if (n as TtNode).type == t:
			c += 1
	return c


## Pad van de wortel naar id (incl. beide).
func path_to(id: int) -> Array[int]:
	var out: Array[int] = []
	var x := id
	var guard := 0
	while x != -1 and guard < 100000:
		out.push_front(x)
		x = _parent_of(x)
		guard += 1
	return out


func _parent_of(id: int) -> int:
	var n := node(id)
	return -1 if n == null else n.parent


# ------------------------------------------------------------------ sap

func sap_used() -> int:
	return 0


func can_afford(cost: int) -> bool:
	return sap_used() + cost <= sap_budget


# ------------------------------------------------------------------ weergave

func render_nodes() -> Array[Dictionary]:
	var ids := nodes.keys()
	ids.sort()
	var out: Array[Dictionary] = []
	var extra := _render_flags()
	for id in ids:
		var d := (nodes[id] as TtNode).to_dict()
		d["dead"] = extra.get("dead", {}).has(id)
		d["misplaced"] = extra.get("misplaced", {}).has(id)
		_decorate(d)
		out.append(d)
	return out


## {"dead": {id:true}, "misplaced": {id:true}}
func _render_flags() -> Dictionary:
	return {}


func _decorate(_d: Dictionary) -> void:
	pass


# ------------------------------------------------------------------ kaarten

func begin(c: TtCard) -> void:
	if card != null:
		push_warning("TtTreeModel.begin: kaart %d nog actief, wordt vervangen" % card.id)
	log.now = now
	var before := snapshot()
	card = c
	c.state = "active"
	c.started_at = now
	st = {}
	_fx.clear()
	_finish_req = {}
	_verdicts = []
	_moves = 0
	_begin(c)
	var entry := log.add("CARD_START", {"kind": c.kind_name(), "word": c.word, "q": c.q, "j": c.j, "wasp": c.wasp},
			V.OK, {}, before, c.id)
	card_started.emit(c)
	_flush_fx()
	event_logged.emit(entry)
	phase_changed.emit(phase, cursor())
	if not _finish_req.is_empty():
		_finish_card()


func _begin(_c: TtCard) -> void:
	pass


## Subklassen: de kaart is na deze zet af.
func _finish(result: String, extra: Dictionary = {}) -> void:
	_finish_req = {"result": result, "extra": extra}


func _finish_card() -> void:
	var c := card
	var req := _finish_req
	_finish_req = {}
	var all_ok := true
	for v in _verdicts:
		if int(v) != V.OK:
			all_ok = false
	var outcome := {"all_ok": all_ok, "verdicts": _verdicts.duplicate(), "result": str(req.get("result", ""))}
	outcome.merge(req.get("extra", {}))
	card = null
	phase = P.IDLE
	st = {}
	if c == null:
		return
	c.state = "expired" if outcome.result == "no_sap" else "done"
	c.finished_at = now
	c.outcome = outcome
	var entry := log.add("CARD_END", {"result": outcome.result, "all_ok": all_ok}, V.OK, {}, {}, c.id)
	event_logged.emit(entry)
	card_finished.emit(c, outcome)


## Breekt de actieve kaart af (verlopen geduld, weggewaaid). Logt EXPIRE.
func abandon_card(reason: String, verdict: int = V.LOST) -> void:
	if card == null:
		return
	var c := card
	var aff: Array = []
	if c.kind == CK.SEED and c.word != "":
		aff = [c.word]
	var entry := log.add("EXPIRE", {"why": reason, "word": c.word, "affects": aff}, verdict, {}, {}, c.id)
	event_logged.emit(entry)
	_verdicts.append(verdict)
	_finish_req = {"result": reason, "extra": {}}
	_finish_card()
	c.state = "expired"


func cursor() -> Dictionary:
	return {"phase": phase}


func correct_move() -> Dictionary:
	if card == null:
		return {"act": "none"}
	return _correct()


func _correct() -> Dictionary:
	return {"act": "none"}


## Plausibele foute (maar uitvoerbare) zetten in de huidige fase, voor bots/QA. Kan leeg zijn.
func wrong_moves() -> Array[Dictionary]:
	return []


## Fysiek onmogelijke zetten in de huidige fase (voor bump-tests). Kan leeg zijn.
func impossible_moves() -> Array[Dictionary]:
	return []


func apply(move: Dictionary) -> Dictionary:
	if card == null:
		return {"ok": false, "verdict": V.BUMP, "reason": "no_card", "done": false}
	log.now = now
	var hint := correct_move()
	var before := snapshot()
	var sap0 := sap_used()
	_fx.clear()
	_finish_req = {}
	var r: Dictionary = _apply(move, hint)
	if not bool(r.get("ok", false)):
		var v := int(r.get("verdict", V.BUMP))
		var reason := str(r.get("reason", "bump"))
		_fx.push_front({"fx": "bump", "at": int(r.get("at", _bump_at())), "reason": reason})
		_flush_fx()
		var bd: Dictionary = r.get("data", {})
		bd["reason"] = reason
		bd["move"] = move.duplicate()
		var entry := log.add(str(r.get("type", "BUMP")), bd, v, hint, before if v != V.OK else {},
				card.id, false)
		if count_bumps or v != V.BUMP:
			if count_bumps:
				_verdicts.append(v)
		event_logged.emit(entry)
		if not _finish_req.is_empty():
			_finish_card()
			return {"ok": false, "verdict": v, "reason": reason, "done": true}
		return {"ok": false, "verdict": v, "reason": reason, "done": false}
	var verdict := int(r.get("verdict", V.OK))
	_verdicts.append(verdict)
	_flush_fx()
	var sap1 := sap_used()
	if sap1 != sap0:
		sap_changed.emit(sap1, sap1 - sap0)
	var keep_before := verdict != V.OK or _moves == 0
	_moves += 1
	var data: Dictionary = r.get("data", {})
	data["move"] = move.duplicate()
	var entry2 := log.add(str(r.get("type", "MOVE")), data, verdict, hint, before if keep_before else {}, card.id)
	event_logged.emit(entry2)
	phase_changed.emit(phase, cursor())
	var done := not _finish_req.is_empty()
	if done:
		_finish_card()
	return {"ok": true, "verdict": verdict, "reason": "", "done": done}


func _apply(_move: Dictionary, _hint: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "wrong_phase"}


func _bump_at() -> int:
	return int(st.get("node", root))


func _fx_add(d: Dictionary) -> void:
	_fx.append(d)


func _flush_fx() -> void:
	var list := _fx.duplicate()
	_fx.clear()
	for f in list:
		changed.emit(f)


func _bump(reason: String, extra: Dictionary = {}) -> Dictionary:
	var r := {"ok": false, "verdict": V.BUMP, "reason": reason}
	r.merge(extra)
	return r


## Speelt de rest van de actieve kaart met correct_move() (bots, "doorspoelen").
func auto_finish_card() -> void:
	var guard := 0
	while card != null and guard < 100000:
		guard += 1
		var m := correct_move()
		if str(m.get("act", "none")) == "none":
			break
		var r := apply(m)
		if not bool(r.ok) and not bool(r.done):
			push_warning("auto_finish_card: orakelzet geweigerd: %s %s" % [str(m), str(r)])
			break


# ------------------------------------------------------------------ algoritmen (subklassen)

func lookup_auto(_word: String) -> Dictionary:
	return {"found": false, "path": [], "end": -1, "reason": "n/a"}


func insert_auto(_word: String) -> void:
	pass


func serialize() -> String:
	return ""


func load_notation(_s: String) -> void:
	pass


# ------------------------------------------------------------------ snapshot

func snapshot() -> Dictionary:
	var ids := nodes.keys()
	ids.sort()
	var ns: Array = []
	for id in ids:
		ns.append((nodes[id] as TtNode).to_dict())
	return {
		"kind": kind, "nodes": ns, "root": root, "next_id": next_id, "sap_budget": sap_budget,
		"card": card.to_dict() if card != null else null, "phase": phase, "st": st.duplicate(true),
		"verdicts": _verdicts.duplicate(), "moves": _moves, "extra": _snapshot_extra(),
	}


func restore(d: Dictionary) -> void:
	nodes.clear()
	for nd in d.get("nodes", []):
		var n := TtNode.from_dict(nd)
		nodes[n.id] = n
	root = int(d.get("root", -1))
	next_id = int(d.get("next_id", 0))
	sap_budget = int(d.get("sap_budget", sap_budget))
	var cd = d.get("card", null)
	if cd == null:
		card = null
	elif card != null and card.id == int(cd.get("id", -2)):
		card.load_dict(cd)
	else:
		card = TtCard.from_dict(cd)
	phase = int(d.get("phase", P.IDLE))
	st = _restore_st(d.get("st", {}))
	_verdicts = []
	for v in d.get("verdicts", []):
		_verdicts.append(int(v))
	_moves = int(d.get("moves", 0))
	_fx.clear()
	_finish_req = {}
	_restore_extra(d.get("extra", {}))


## JSON maakt van ints floats: subklassen zetten hier hun st-velden terug naar int.
func _restore_st(s: Dictionary) -> Dictionary:
	var out := s.duplicate(true)
	for k in out.keys():
		if out[k] is float and is_equal_approx(out[k], round(out[k])):
			out[k] = int(out[k])
	return out


func _snapshot_extra() -> Dictionary:
	return {}


func _restore_extra(_d: Dictionary) -> void:
	pass


# ------------------------------------------------------------------ invarianten

func invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	if not nodes.has(root):
		errs.append("wortel %d bestaat niet" % root)
		return errs
	for id in nodes.keys():
		var n: TtNode = nodes[id]
		if n.id != int(id):
			errs.append("id-sleutel %s ≠ node.id %d" % [str(id), n.id])
		if n.id >= next_id:
			errs.append("id %d ≥ next_id %d" % [n.id, next_id])
	errs.append_array(_invariants())
	return errs


func _invariants() -> PackedStringArray:
	return PackedStringArray()


## Generieke controle voor toppen met kids (trie/Patricia/suffix): ouder/kind-links, bereikbaarheid.
func _check_kids_tree() -> PackedStringArray:
	var errs := PackedStringArray()
	var seen := {}
	for id in subtree(root):
		if seen.has(id):
			errs.append("top %d twee keer bereikt" % id)
		seen[id] = true
		var n := node(id)
		for k in n.kids.keys():
			var c := node(int(n.kids[k]))
			if c == null:
				errs.append("top %d: kind %s = %d bestaat niet" % [id, str(k), int(n.kids[k])])
				continue
			if c.parent != id:
				errs.append("kind %d van %d heeft ouder %d" % [c.id, id, c.parent])
			if n.type == NT.LEAF:
				errs.append("blad %d heeft kinderen" % id)
	if seen.size() != nodes.size():
		errs.append("%d toppen niet bereikbaar vanuit de wortel" % (nodes.size() - seen.size()))
	if node(root) != null and node(root).parent != -1:
		errs.append("wortel heeft een ouder")
	return errs
