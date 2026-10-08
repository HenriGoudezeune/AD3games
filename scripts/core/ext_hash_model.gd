class_name ExtHashModel extends RefCounted
## Extendible hashing volgens de lesnotas AD3 §2.1.1, als spelmodel (GDD §10.3).
## Puur: geen nodes, geen Engine-calls. Gameplay roept methodes aan en luistert naar signalen.
##
## Ritten (GDD §6.2): drop L+1 (+S1 als geplaatst); herpoging na split plaatst met S+1 (geen extra L);
## juiste split S+1 bij finish; onnodige split L+1 bij begin en S+2 bij finish; verdubbelen 0; lookup L+1.

enum Verdict { OK, MISROUTED, UNNEEDED_DOUBLE, UNNEEDED_SPLIT, WRONG_SIDE, WRONG_LOOKUP, UNNEEDED_DUMP, LOST }
enum Drop { PLACED, BLOCKED }

signal parcel_placed(parcel: Parcel, bucket_id: int, dir_index: int, verdict: int)
signal parcel_blocked(parcel: Parcel, bucket_id: int, dir_index: int)
signal still_blocked(parcel: Parcel, bucket_id: int)
signal directory_doubled(old_a: int, new_a: int, verdict: int)
signal double_refused()
signal split_started(bucket_id: int, new_bucket_id: int, bit_pos: int, changed: PackedInt32Array, to_sort: Array[Parcel], verdict: int)
signal split_refused(bucket_id: int)
signal parcel_assigned(parcel: Parcel, side: int, verdict: int)
signal split_finished(bucket_id: int, new_bucket_id: int)
signal lookup_done(dir_index: int, bucket_id: int, wanted_hv: int, found: bool, verdict: int)
signal parcel_lost(parcel: Parcel, reason: String)
signal parcel_dumped(parcel: Parcel, verdict: int)
signal io_changed(reads: int, writes: int)
signal event_logged(entry: Dictionary)

var n: int = 5
var g: int = 2
var a: int = 1
var buckets: Array[Bucket] = []   # index == bucket id; ids worden nooit hergebruikt
var dir: PackedInt32Array = PackedInt32Array()  # grootte 2^a, waarden = bucket id
var blocked: Array[Dictionary] = []  # FIFO: {parcel: Parcel, bucket_id: int, via_index: int}
var splitting: Dictionary = {}       # {} of {bucket_id, new_bucket_id, bit_pos, pending: Array[Parcel], verdict}
var reads: int = 0
var writes: int = 0
var now: float = 0.0
var log: EventLog = EventLog.new()

# --- uitbreidingen t.o.v. GDD §10.3 (zie STATUS.md "API-afwijkingen") ---
var allow_dump: bool = false        # overloopbak beschikbaar (dag 7 middag, endless) -> orakel kan "dump" zeggen
var dumped: Array[Parcel] = []      # inhoud van de overloopbak
var lost: Array[Parcel] = []        # kwijtgeraakte pakjes
var next_parcel_id: int = 1
var doubles: int = 0                # aantal uitgevoerde verdubbelingen
var splits: int = 0                 # aantal begonnen splitsingen


# ======================================================================
#  opbouw
# ======================================================================

## 2^a lege emmers, elk met ab = a.
func setup(n_: int, g_: int, a_: int) -> void:
	n = n_
	g = g_
	a = a_
	buckets.clear()
	dir = PackedInt32Array()
	var size := 1 << a
	dir.resize(size)
	for i in size:
		buckets.append(Bucket.make(i, a))
		dir[i] = i
	blocked.clear()
	splitting = {}
	reads = 0
	writes = 0
	now = 0.0
	log = EventLog.new()
	log.n = n
	dumped.clear()
	lost.clear()
	next_parcel_id = 1
	doubles = 0
	splits = 0


## Laadt een starttoestand. spec = [{"label":"0","hvs":["00100","01111"]}, ...] in dir-volgorde.
## Gebruikt de huidige n, g, a (eerst setup()). ab = len(label). Lege spec -> setup-toestand blijft.
func load_layout(spec: Array) -> void:
	if spec.is_empty():
		return
	buckets.clear()
	dir = PackedInt32Array()
	dir.resize(1 << a)
	dir.fill(-1)
	for entry in spec:
		var label: String = str(entry.get("label", ""))
		var ab := label.length()
		var b := Bucket.make(buckets.size(), ab)
		buckets.append(b)
		var span := 1 << (a - ab)
		var start := HashUtil.from_bits(label) << (a - ab)
		for i in range(start, start + span):
			dir[i] = b.id
		for s in entry.get("hvs", []):
			var hv: int = HashUtil.from_bits(str(s)) if s is String else int(s)
			b.parcels.append(new_parcel(hv))


## Maakt een pakje met een uniek id (de director gebruikt dit ook).
func new_parcel(hv: int, key_label: String = "", is_clone: bool = false) -> Parcel:
	var p := Parcel.make(next_parcel_id, hv, key_label, is_clone)
	next_parcel_id += 1
	return p


# ======================================================================
#  queries
# ======================================================================

func index_of(hv: int) -> int:
	return HashUtil.prefix(hv, n, a)


func bucket_at(dir_index: int) -> Bucket:
	if dir_index < 0 or dir_index >= dir.size():
		return null
	return buckets[dir[dir_index]]


func span(bucket_id: int) -> int:
	return 1 << (a - buckets[bucket_id].ab)


## (start, count) van het aaneengesloten blok pointers naar deze emmer.
func dir_range(bucket_id: int) -> Vector2i:
	for i in dir.size():
		if dir[i] == bucket_id:
			var c := 0
			while i + c < dir.size() and dir[i + c] == bucket_id:
				c += 1
			return Vector2i(i, c)
	return Vector2i(-1, 0)


## Eerste ab bits (het bordje van het rek).
func label_of(bucket_id: int) -> String:
	var ab := buckets[bucket_id].ab
	var r := dir_range(bucket_id)
	if r.x < 0:
		return ""
	return HashUtil.bits(HashUtil.prefix(r.x, a, ab), ab)


## Emmers in pointerarray-volgorde: [{bucket_id, start, span, ab, label}].
func layout() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i := 0
	while i < dir.size():
		var b := dir[i]
		var ab := buckets[b].ab
		var sp := 1 << (a - ab)
		out.append({"bucket_id": b, "start": i, "span": sp, "ab": ab, "label": HashUtil.bits(HashUtil.prefix(i, a, ab), ab)})
		i += maxi(sp, 1)
	return out


## Ligt dit pakje in een emmer waar het niet bereikbaar is via zijn eigen pointer?
func is_misplaced(parcel: Parcel, bucket_id: int) -> bool:
	return dir[index_of(parcel.hv)] != bucket_id


## Alle verdwaalde pakjes: [{parcel, bucket_id}].
func misplaced() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in buckets:
		for p in b.parcels:
			if is_misplaced(p, b.id):
				out.append({"parcel": p, "bucket_id": b.id})
	return out


## Emmer-id waarin dit pakje nu zou moeten liggen.
func bucket_of_hv(hv: int) -> int:
	return dir[index_of(hv)]


## Is er een opgeslagen pakje met deze hv bereikbaar via zijn pointer?
func is_findable(hv: int) -> bool:
	return buckets[dir[index_of(hv)]].has_hv(hv)


func all_parcels() -> Array[Parcel]:
	var out: Array[Parcel] = []
	for b in buckets:
		out.append_array(b.parcels)
	return out


func is_alarm() -> bool:
	return not blocked.is_empty() or not splitting.is_empty()


func _is_splitting_bucket(bucket_id: int) -> bool:
	return not splitting.is_empty() and (int(splitting.bucket_id) == bucket_id or int(splitting.new_bucket_id) == bucket_id)


func _blocked_index(parcel: Parcel) -> int:
	for i in blocked.size():
		if blocked[i].parcel == parcel or (blocked[i].parcel as Parcel).id == parcel.id:
			return i
	return -1


## Zou dit pakje een kloon te veel zijn? (>= g identieke in de emmer waar het hoort)
func is_clone_overflow(hv: int) -> bool:
	return buckets[dir[index_of(hv)]].count_hv(hv) >= g


# ======================================================================
#  acties
# ======================================================================

func _io() -> void:
	io_changed.emit(reads, writes)


func _log(type: String, data: Dictionary, verdict: int, hint: Dictionary, before: Dictionary) -> Dictionary:
	log.now = now
	log.n = n
	data["a"] = data.get("a", a)
	var e := log.add(type, data, verdict, hint, before)
	event_logged.emit(e)
	return e


## Logt een event van buiten het model (director: SPAWN, CUSTOMER_*, DAY_END). Emit event_logged.
func log_event(type: String, data: Dictionary, verdict: int = Verdict.OK) -> Dictionary:
	return _log(type, data, verdict, {}, {})


## Pakje door luik dir_index. -> {status: Drop, bucket_id, verdict, correct_index}. L += 1; bij PLACED ook S += 1.
## Tijdens een split naar het splitsende rek (oud of nieuw): altijd BLOCKED.
func drop(parcel: Parcel, dir_index: int) -> Dictionary:
	var hint := correct_move(parcel)
	var ci := index_of(parcel.hv)
	var bid := dir[dir_index]
	# verdwaald = in een andere emmer dan waar het hoort (een luik dat dezelfde buis deelt is geen fout)
	var verdict: int = Verdict.OK if bid == dir[ci] else Verdict.MISROUTED
	var before := {} if verdict == Verdict.OK else snapshot()
	reads += 1
	var b := buckets[bid]
	var status: int
	if b.is_full(g) or _is_splitting_bucket(bid):
		status = Drop.BLOCKED
		blocked.append({"parcel": parcel, "bucket_id": bid, "via_index": dir_index})
	else:
		status = Drop.PLACED
		b.parcels.append(parcel)
		writes += 1
	_io()
	var data := {"parcel_id": parcel.id, "hv": parcel.hv, "dir_index": dir_index, "bucket_id": bid,
		"correct_index": ci, "status": status, "clone": parcel.is_clone}
	_log("DROP", data, verdict, hint, before)
	if status == Drop.PLACED:
		parcel_placed.emit(parcel, bid, dir_index, verdict)
	else:
		_log("BLOCK", {"parcel_id": parcel.id, "hv": parcel.hv, "bucket_id": bid, "dir_index": dir_index}, Verdict.OK, {}, {})
		parcel_blocked.emit(parcel, bid, dir_index)
	return {"status": status, "bucket_id": bid, "verdict": verdict, "correct_index": ci}


func can_double() -> bool:
	return a < n


func _double_is_needed() -> bool:
	if blocked.is_empty():
		return false
	var b := buckets[dir[int(blocked[0].via_index)]]
	return b.is_full(g) and b.ab == a


## Verdubbel de pointerarray: pn[i] = po[i >> 1], a += 1. false + double_refused als a == n.
func double_dir() -> bool:
	var hint := correct_move()
	if not can_double():
		_log("DOUBLE_REFUSED", {}, Verdict.OK, hint, {})
		double_refused.emit()
		return false
	var verdict: int = Verdict.OK if _double_is_needed() else Verdict.UNNEEDED_DOUBLE
	var before := snapshot()
	var old_a := a
	var nd := PackedInt32Array()
	nd.resize(dir.size() * 2)
	for i in nd.size():
		nd[i] = dir[i >> 1]
	dir = nd
	a += 1
	doubles += 1
	for e in blocked:
		var p: Parcel = e.parcel
		e.via_index = (int(e.via_index) << 1) | HashUtil.bit_at(p.hv, n, a)
	_log("DOUBLE", {"old_a": old_a, "new_a": a, "a": a}, verdict, hint, before)
	directory_doubled.emit(old_a, a, verdict)
	return true


## ab < a en geen andere split bezig.
func can_split(bucket_id: int) -> bool:
	return splitting.is_empty() and bucket_id >= 0 and bucket_id < buckets.size() and buckets[bucket_id].ab < a


func _has_blocked_in(bucket_id: int) -> bool:
	for e in blocked:
		if dir[int(e.via_index)] == bucket_id:
			return true
	return false


## Maakt b', zet de pointers om (onderste helft van het blok), ab = ab' = ab + 1 en haalt alle pakjes uit b
## naar splitting.pending (de sorteertafel). false als ab == a (split_refused) of als er al een split bezig is.
func begin_split(bucket_id: int) -> bool:
	if not splitting.is_empty() or bucket_id < 0 or bucket_id >= buckets.size():
		return false
	var hint := correct_move()
	var b := buckets[bucket_id]
	if b.ab >= a:
		_log("SPLIT_REFUSED", {"bucket_id": bucket_id}, Verdict.OK, hint, {})
		split_refused.emit(bucket_id)
		return false
	var verdict: int = Verdict.OK if _has_blocked_in(bucket_id) else Verdict.UNNEEDED_SPLIT
	var before := snapshot()
	var ab := b.ab
	var r := dir_range(bucket_id)
	var p := HashUtil.prefix(r.x, a, ab)  # = h(r)|ab
	var nb := Bucket.make(buckets.size(), ab + 1)
	buckets.append(nb)
	var changed := PackedInt32Array()
	for i in range(r.x, r.x + r.y):
		if HashUtil.prefix(i, a, ab + 1) == 2 * p + 1:
			dir[i] = nb.id
			changed.append(i)
	b.ab = ab + 1
	var pending: Array[Parcel] = []
	pending.assign(b.parcels)
	b.parcels.clear()
	splits += 1
	if verdict != Verdict.OK:
		reads += 1
		_io()
	splitting = {"bucket_id": bucket_id, "new_bucket_id": nb.id, "bit_pos": ab + 1, "pending": pending, "verdict": verdict}
	var to_sort: Array[Parcel] = []
	to_sort.assign(pending)
	_log("SPLIT_BEGIN", {"bucket_id": bucket_id, "new_bucket_id": nb.id, "bit_pos": ab + 1, "ab": ab,
		"changed": Array(changed), "parcel_ids": to_sort.map(func(q): return q.id), "span": r.y}, verdict, hint, before)
	split_started.emit(bucket_id, nb.id, ab + 1, changed, to_sort, verdict)
	if pending.is_empty():
		finish_split()
	return true


## bit_at(hv, n, ab_oud + 1): 0 = blijft in oude emmer (links), 1 = nieuwe emmer (rechts).
func correct_side(parcel: Parcel) -> int:
	var pos: int = int(splitting.bit_pos) if not splitting.is_empty() else 1
	return HashUtil.bit_at(parcel.hv, n, pos)


## Verdeel één pakje van de sorteertafel. -> verdict (of -1 als het pakje niet op de tafel ligt).
## Als de tafel leeg is -> finish_split().
func assign(parcel_id: int, side: int) -> int:
	if splitting.is_empty():
		return -1
	var pending: Array[Parcel] = splitting.pending
	var idx := -1
	for i in pending.size():
		if pending[i].id == parcel_id:
			idx = i
			break
	if idx < 0:
		return -1
	var p: Parcel = pending[idx]
	var hint := correct_move()
	var cs := correct_side(p)
	var verdict: int = Verdict.OK if side == cs else Verdict.WRONG_SIDE
	var before := {} if verdict == Verdict.OK else snapshot()
	pending.remove_at(idx)
	var target: int = int(splitting.new_bucket_id) if side == 1 else int(splitting.bucket_id)
	buckets[target].parcels.append(p)
	_log("ASSIGN", {"parcel_id": p.id, "hv": p.hv, "side": side, "correct_side": cs, "bit_pos": int(splitting.bit_pos),
		"bucket_id": target}, verdict, hint, before)
	parcel_assigned.emit(p, side, verdict)
	if pending.is_empty():
		finish_split()
	return verdict


## Verdeel alle resterende pakjes correct (bots, "Doorspoelen").
func auto_assign_rest() -> void:
	while not splitting.is_empty():
		var pending: Array[Parcel] = splitting.pending
		if pending.is_empty():
			finish_split()
			return
		var p: Parcel = pending[0]
		assign(p.id, correct_side(p))


## Sluit de split af: schrijft ritten (S+1 bij juiste split, S+2 bij onnodige), daarna retry_blocked().
## Liggen er nog pakjes op de tafel, dan worden die eerst correct verdeeld.
func finish_split() -> void:
	if splitting.is_empty():
		return
	var pending: Array[Parcel] = splitting.pending
	if not pending.is_empty():
		auto_assign_rest()
		return
	var bid := int(splitting.bucket_id)
	var nbid := int(splitting.new_bucket_id)
	var verdict := int(splitting.verdict)
	writes += 1 if verdict == Verdict.OK else 2
	splitting = {}
	_io()
	_log("SPLIT_END", {"bucket_id": bid, "new_bucket_id": nbid, "old_count": buckets[bid].parcels.size(),
		"new_count": buckets[nbid].parcels.size()}, Verdict.OK, {}, {})
	split_finished.emit(bid, nbid)
	retry_blocked()


## FIFO: elk vastzittend pakje probeert opnieuw via dir[via_index]. Ruimte -> geplaatst (S+1), anders still_blocked.
func retry_blocked() -> void:
	if not splitting.is_empty():
		return
	var i := 0
	while i < blocked.size():
		var e: Dictionary = blocked[i]
		var p: Parcel = e.parcel
		var via := int(e.via_index)
		var bid := dir[via]
		var b := buckets[bid]
		if not b.is_full(g):
			blocked.remove_at(i)
			b.parcels.append(p)
			writes += 1
			_io()
			var mis := dir[index_of(p.hv)] != bid
			_log("RETRY", {"parcel_id": p.id, "hv": p.hv, "bucket_id": bid, "dir_index": via, "placed": true,
				"misrouted": mis}, Verdict.OK, {}, {})
			parcel_placed.emit(p, bid, via, Verdict.MISROUTED if mis else Verdict.OK)
		else:
			e.bucket_id = bid
			_log("RETRY", {"parcel_id": p.id, "hv": p.hv, "bucket_id": bid, "dir_index": via, "placed": false,
				"ab": b.ab}, Verdict.OK, {}, {})
			still_blocked.emit(p, bid)
			i += 1


## Klant: zoek wanted_hv via luik dir_index. -> {bucket_id, found, verdict, correct_index}. L += 1.
func lookup(dir_index: int, wanted_hv: int) -> Dictionary:
	var hint := {"action": "lookup", "dir_index": index_of(wanted_hv)}
	var ci := index_of(wanted_hv)
	var bid := dir[dir_index]
	var verdict: int = Verdict.OK if bid == dir[ci] else Verdict.WRONG_LOOKUP
	var before := {} if verdict == Verdict.OK else snapshot()
	reads += 1
	_io()
	var found := buckets[bid].has_hv(wanted_hv)
	if not found and _is_splitting_bucket(bid):
		for q in splitting.pending:
			if (q as Parcel).hv == wanted_hv:
				found = true
	var data := {"dir_index": dir_index, "bucket_id": bid, "wanted_hv": wanted_hv, "found": found, "correct_index": ci}
	if verdict == Verdict.OK and not found:
		var c := log.cause_of_hv(wanted_hv)
		if not c.is_empty():
			data["cause_seq"] = c.seq
	_log("LOOKUP", data, verdict, hint, before)
	lookup_done.emit(dir_index, bid, wanted_hv, found, verdict)
	return {"bucket_id": bid, "found": found, "verdict": verdict, "correct_index": ci}


## Overloopbak: pakje uit blocked of van de band. -> verdict (OK of UNNEEDED_DUMP; dan telt het als kwijt).
func dump(parcel: Parcel) -> int:
	var bi := _blocked_index(parcel)
	var hint := correct_move(null if bi >= 0 else parcel)
	if bi >= 0:
		blocked.remove_at(bi)
	var verdict: int = Verdict.OK if is_clone_overflow(parcel.hv) else Verdict.UNNEEDED_DUMP
	var before := {} if verdict == Verdict.OK else snapshot()
	dumped.append(parcel)
	_log("DUMP", {"parcel_id": parcel.id, "hv": parcel.hv, "from_blocked": bi >= 0}, verdict, hint, before)
	parcel_dumped.emit(parcel, verdict)
	if verdict != Verdict.OK:
		parcel_lost.emit(parcel, "dump_healthy")
		lost.append(parcel)
	retry_blocked()
	return verdict


## Pakje kwijt: reason = "belt" | "burst" | "dump_healthy". excused = de juiste actie faalde zelf (a == n).
func lose(parcel: Parcel, reason: String, excused: bool = false) -> void:
	var bi := _blocked_index(parcel)
	if bi >= 0:
		blocked.remove_at(bi)
	lost.append(parcel)
	_log("LOST", {"parcel_id": parcel.id, "hv": parcel.hv, "reason": reason, "excused": excused}, Verdict.LOST, {}, {})
	parcel_lost.emit(parcel, reason)
	retry_blocked()


# ======================================================================
#  orakel
# ======================================================================

## De juiste zet nu. Prioriteit:
##   split bezig -> {action:"assign", parcel_id, side}
##   blocked     -> {action:"dump", parcel_id} (enkel met allow_dump, >= g identieke in dat rek)
##                  {action:"split", bucket_id, span} als ab < a
##                  {action:"double"} als a < n, anders {action:"fail", parcel_id}
##   front       -> {action:"dump", parcel_id} (allow_dump en kloon te veel) of {action:"drop", dir_index}
##   anders      -> {action:"none"}
func correct_move(front: Parcel = null) -> Dictionary:
	if not splitting.is_empty():
		var pending: Array[Parcel] = splitting.pending
		if pending.is_empty():
			return {"action": "finish"}
		var p: Parcel = pending[0]
		return {"action": "assign", "parcel_id": p.id, "side": correct_side(p)}
	if not blocked.is_empty():
		var e: Dictionary = blocked[0]
		var bp: Parcel = e.parcel
		var b := buckets[dir[int(e.via_index)]]
		if allow_dump and b.count_hv(bp.hv) >= g:
			return {"action": "dump", "parcel_id": bp.id}
		if not b.is_full(g):
			return {"action": "retry"}
		if b.ab < a:
			return {"action": "split", "bucket_id": b.id, "span": 1 << (a - b.ab)}
		if a < n:
			return {"action": "double"}
		return {"action": "fail", "parcel_id": bp.id}
	if front != null:
		if allow_dump and is_clone_overflow(front.hv):
			return {"action": "dump", "parcel_id": front.id}
		return {"action": "drop", "dir_index": index_of(front.hv)}
	return {"action": "none"}


## Speelt correct_move() tot er niets meer vastzit (bots, "Doorspoelen"). -> "ok" | "fail" (a == n, rek nog vol).
## Bij "fail" blijft het pakje in blocked; de director laat dan de buis barsten.
func auto_resolve() -> String:
	for guard in 10000:
		var m := correct_move()
		match m.action:
			"none":
				return "ok"
			"assign":
				assign(int(m.parcel_id), int(m.side))
			"finish":
				finish_split()
			"split":
				begin_split(int(m.bucket_id))
			"double":
				double_dir()
			"retry":
				retry_blocked()
			"dump":
				for e in blocked:
					if (e.parcel as Parcel).id == int(m.parcel_id):
						dump(e.parcel)
						break
			"fail":
				return "fail"
	return "fail"


## Voegt één pakje perfect toe (drop via het juiste luik of overloopbak, dan auto_resolve). -> "ok" | "dump" | "fail".
func auto_insert(parcel: Parcel) -> String:
	var m := correct_move(parcel)
	if m.action == "dump":
		dump(parcel)
		return "dump"
	if m.action != "drop":
		var r := auto_resolve()
		if r != "ok":
			return r
		m = correct_move(parcel)
		if m.action == "dump":
			dump(parcel)
			return "dump"
	drop(parcel, int(m.dir_index))
	return auto_resolve()


## Niet-muterend: de stappen die het algoritme van de notas zou zetten om hv toe te voegen (zoals JS insert()).
## stappen: {act:"place"|"double"|"split"|"fail", idx, a, bucket_id, ab, stay, move, changed}
## (stay/move: hashwaarden; changed: pointer-indices; enkel bij split.) Veronderstelt dat er geen split bezig is.
func simulate_insert(hv: int) -> Array[Dictionary]:
	var sa := a
	var sdir := dir.duplicate()
	var sab: Array[int] = []
	var skeys: Array = []
	for b in buckets:
		sab.append(b.ab)
		skeys.append(b.parcels.map(func(q): return q.hv))
	var steps: Array[Dictionary] = []
	for guard in 200:
		var idx := HashUtil.prefix(hv, n, sa)
		var bid := sdir[idx]
		var keys: Array = skeys[bid]
		var st := {"act": "", "idx": idx, "a": sa, "bucket_id": bid, "ab": sab[bid], "stay": [], "move": [], "changed": []}
		steps.append(st)
		if keys.size() < g:
			st.act = "place"
			keys.append(hv)
			break
		if sab[bid] < sa:
			st.act = "split"
			var ab: int = sab[bid]
			var start := sdir.find(bid)
			var p := HashUtil.prefix(start, sa, ab)
			var nb := sab.size()
			var stay := []
			var move := []
			for k in keys:
				if HashUtil.bit_at(k, n, ab + 1) == 1:
					move.append(k)
				else:
					stay.append(k)
			skeys[bid] = stay
			skeys.append(move)
			sab[bid] = ab + 1
			sab.append(ab + 1)
			var changed := []
			for i in sdir.size():
				if HashUtil.prefix(i, sa, ab + 1) == 2 * p + 1:
					sdir[i] = nb
					changed.append(i)
			st.stay = stay.duplicate()
			st.move = move.duplicate()
			st.changed = changed
		elif sa < n:
			st.act = "double"
			var nd := PackedInt32Array()
			nd.resize(sdir.size() * 2)
			for i in nd.size():
				nd[i] = sdir[i >> 1]
			sdir = nd
			sa += 1
		else:
			st.act = "fail"
			break
	return steps


## Controleert de structuur (zoals JS invariants()). Leeg = ok. Verdwaalde pakjes: zie misplaced().
func invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	if dir.size() != (1 << a):
		errs.append("dir-lengte %d != 2^%d" % [dir.size(), a])
		return errs
	if a > n:
		errs.append("a > n")
	var seen := {}
	var total := 0
	var i := 0
	while i < dir.size():
		var bid := dir[i]
		if bid < 0 or bid >= buckets.size():
			errs.append("pointer %d naar onbestaande emmer %d" % [i, bid])
			return errs
		var b := buckets[bid]
		if seen.has(bid):
			errs.append("emmer %d niet aaneengesloten" % bid)
		seen[bid] = true
		if b.ab > a or b.ab < 0:
			errs.append("emmer %d: ab %d > a %d" % [bid, b.ab, a])
			return errs
		var sp := 1 << (a - b.ab)
		if i % sp != 0:
			errs.append("emmer %d: blok niet uitgelijnd" % bid)
		for j in range(i, mini(i + sp, dir.size())):
			if dir[j] != bid:
				errs.append("pointer %d (2^(a-ab)-blok van emmer %d)" % [j, bid])
		if b.parcels.size() > g:
			errs.append("overvol %d" % bid)
		total += sp
		i += sp
	if total != dir.size():
		errs.append("spans")
	for b in buckets:
		if not seen.has(b.id):
			errs.append("emmer %d onbereikbaar" % b.id)
	# elk pakje maximaal één keer
	var ids := {}
	for b in buckets:
		for p in b.parcels:
			if ids.has(p.id):
				errs.append("pakje %d dubbel" % p.id)
			ids[p.id] = true
	return errs


# ======================================================================
#  snapshot / restore
# ======================================================================

func _pl(arr: Array) -> Array:
	return arr.map(func(q): return q.to_dict())


## Volledige toestand, JSON-serialiseerbaar (zonder de log).
func snapshot() -> Dictionary:
	var bs := []
	for b in buckets:
		bs.append({"id": b.id, "ab": b.ab, "parcels": _pl(b.parcels)})
	var bl := []
	for e in blocked:
		bl.append({"parcel": (e.parcel as Parcel).to_dict(), "bucket_id": int(e.bucket_id), "via_index": int(e.via_index)})
	var sp := {}
	if not splitting.is_empty():
		sp = {"bucket_id": int(splitting.bucket_id), "new_bucket_id": int(splitting.new_bucket_id),
			"bit_pos": int(splitting.bit_pos), "verdict": int(splitting.verdict), "pending": _pl(splitting.pending)}
	return {
		"n": n, "g": g, "a": a, "dir": Array(dir), "buckets": bs, "blocked": bl, "splitting": sp,
		"reads": reads, "writes": writes, "now": now, "allow_dump": allow_dump,
		"dumped": _pl(dumped), "lost": _pl(lost), "next_parcel_id": next_parcel_id,
		"doubles": doubles, "splits": splits,
	}


func _parcels_from(arr: Array) -> Array[Parcel]:
	var out: Array[Parcel] = []
	for d in arr:
		out.append(Parcel.from_dict(d))
	return out


## Herstelt een snapshot (ook na JSON-roundtrip: getallen worden naar int gezet). De log blijft ongemoeid.
func restore(d: Dictionary) -> void:
	n = int(d.n)
	g = int(d.g)
	a = int(d.a)
	dir = PackedInt32Array()
	for x in d.dir:
		dir.append(int(x))
	buckets.clear()
	for bd in d.buckets:
		var b := Bucket.make(int(bd.id), int(bd.ab))
		b.parcels = _parcels_from(bd.parcels)
		buckets.append(b)
	blocked.clear()
	for e in d.blocked:
		blocked.append({"parcel": Parcel.from_dict(e.parcel), "bucket_id": int(e.bucket_id), "via_index": int(e.via_index)})
	splitting = {}
	var sp: Dictionary = d.get("splitting", {})
	if not sp.is_empty():
		splitting = {"bucket_id": int(sp.bucket_id), "new_bucket_id": int(sp.new_bucket_id), "bit_pos": int(sp.bit_pos),
			"verdict": int(sp.verdict), "pending": _parcels_from(sp.pending)}
	reads = int(d.reads)
	writes = int(d.writes)
	now = float(d.get("now", 0.0))
	allow_dump = bool(d.get("allow_dump", false))
	dumped = _parcels_from(d.get("dumped", []))
	lost = _parcels_from(d.get("lost", []))
	next_parcel_id = int(d.get("next_parcel_id", 1))
	doubles = int(d.get("doubles", 0))
	splits = int(d.get("splits", 0))
	log.n = n


## Compacte beschrijving zoals in de GDD: "0{00100,01111} 10{10010}" (dir-volgorde).
func describe() -> String:
	var parts := PackedStringArray()
	for L in layout():
		var b := buckets[int(L.bucket_id)]
		var hs := PackedStringArray()
		for p in b.parcels:
			hs.append(HashUtil.bits(p.hv, n))
		parts.append("%s{%s}" % [L.label, ",".join(hs)])
	return " ".join(parts)
