class_name TxEditBoard extends TxMachine
## Schakelbord (editeerafstand, Algoritme 7) en zoeklicht (Algoritme 8); GDD §3.7–3.8.
## Rijen = a (lengte ra), kolommen = b (lengte cb); tab[i][j] met lengtes als index zoals de notas.
## FILL: {"act":"fill","dir":"diag"|"up"|"left"} voor de cursorcel (rij per rij, links → rechts).
## PICK_END (approx): {"act":"pick_end","j":j}. TRACE: {"act":"step","dir":…} terug langs stroomvoerende draadjes.
## TRACE_DONE: {"act":"trace_again"} of {"act":"finish"}. stage "want": aantal verschillende reeksen/matches dat het
## orakel zoekt (−1 = alle).

var a: String = ""
var b: String = ""
var ra: int = 0
var cb: int = 0
var approx: bool = false
var want: int = 1
var tab: Array = []              # spelerswaarden, −1 = leeg
var dirs: Array = []             # gekozen ingang per cel ("" = rand/leeg)
var true_tab: Array = []
var ci: int = 1                  # FILL-cursor
var cj: int = 1
var ti: int = 0                  # spoorpositie
var tj: int = 0
var end_j: int = -1
var trace_steps: Array = []      # [{dir, i, j}] in terugwaartse volgorde
var found_keys: Array = []       # sleutels van gevonden reeksen (Alg. 7) of matches "start:end_col" (Alg. 8)
var sequences: Array = []        # gevonden bewerkingsreeksen (Alg. 7) / [{start, end_col, ops}] (Alg. 8)
var best_true: int = 0


func _setup() -> void:
	kind = TxCodes.Machine.EDIT
	a = str(stage.get("a", ""))
	b = str(stage.get("b", ""))
	approx = bool(stage.get("approx", false))
	want = int(stage.get("want", 1))
	z = a
	t = b
	m = a.length()
	n = b.length()
	ra = a.length()
	cb = b.length()
	front = n
	true_tab = TxReference.approx_table(a, b) if approx else TxReference.edit_table(a, b)
	best_true = int(TxReference.approx_best(a, b).best) if approx else int(true_tab[ra][cb])
	tab = []
	dirs = []
	for i in ra + 1:
		var row: Array[int] = []
		var drow: Array[String] = []
		for j in cb + 1:
			row.append(-1)
			drow.append("")
		tab.append(row)
		dirs.append(drow)
	for i in ra + 1:
		tab[i][0] = i
		if i > 0:
			dirs[i][0] = "up"
	for j in cb + 1:
		tab[0][j] = 0 if approx else j
		if j > 0 and not approx:
			dirs[0][j] = "left"
	var pr := int(stage.get("prefill_rows", 0))
	for i in range(1, mini(pr, ra) + 1):
		for j in range(1, cb + 1):
			tab[i][j] = int(true_tab[i][j])
			var ar := TxReference.arrows(true_tab, a, b, i, j)
			dirs[i][j] = ar[0] if not ar.is_empty() else ""
	ci = mini(pr, ra) + 1
	cj = 1
	ti = ra
	tj = cb
	end_j = -1
	trace_steps = []
	found_keys = []
	sequences = []


func _make_truth() -> Array[Dictionary]:
	if stage.has("truth"):
		return super._make_truth()
	var out: Array[Dictionary] = []
	if not approx:
		return out
	var seen := {}
	for mm in TxReference.approx_matches(a, b):
		var key := "%d:%d" % [int(mm.start), int(mm.end_col)]
		if seen.has(key):
			continue
		seen[key] = true
		out.append({"start": int(mm.start), "end": int(mm.end_col) - 1, "level": best_true})
	return out


func _begin() -> void:
	if ci > ra:
		_after_fill()
	else:
		phase = P.FILL


func _after_fill() -> void:
	if approx:
		phase = P.PICK_END
	else:
		_start_trace(ra, cb)


func _start_trace(i: int, j: int) -> void:
	ti = i
	tj = j
	trace_steps = []
	phase = P.TRACE


func cost(dir: String, i: int, j: int) -> int:
	return TxReference.step_cost(dir, a, b, i, j)


func _fill_values(i: int, j: int) -> Dictionary:
	var c := cost("diag", i, j)
	var d := int(tab[i - 1][j - 1])
	var u := int(tab[i - 1][j])
	var l := int(tab[i][j - 1])
	return {"a": d, "c": c, "b": u, "d": l, "v": mini(d + c, mini(u + 1, l + 1)),
		"diag": d + c, "up": u + 1, "left": l + 1}


func carries(i: int, j: int, dir: String) -> bool:
	var p := TxReference.pred(dir, i, j)
	if p.x < 0 or p.y < 0:
		return false
	return int(tab[i][j]) == int(tab[p.x][p.y]) + cost(dir, i, j)


func trace_finished() -> bool:
	return ti == 0 and (approx or tj == 0)


func row_min() -> int:
	var best := TxCodes.INF
	for j in range(0, cb + 1):
		if int(tab[ra][j]) >= 0:
			best = mini(best, int(tab[ra][j]))
	return best


func min_cols() -> Array[int]:
	var out: Array[int] = []
	var mn := row_min()
	for j in range(0, cb + 1):
		if int(tab[ra][j]) == mn:
			out.append(j)
	return out


func _judge(move: Dictionary) -> Dictionary:
	match str(move.get("act", "")):
		"fill":
			if phase != P.FILL:
				return {"ok": false, "reason": "wrong_phase"}
			var dir := str(move.get("dir", ""))
			if not dir in ["diag", "up", "left"]:
				return {"ok": false, "reason": "unknown_act"}
			var fv := _fill_values(ci, cj)
			var val := int(fv[dir])
			var data := fv.duplicate()
			data.erase("diag")
			data.erase("up")
			data.erase("left")
			data.merge({"i": ci, "j": cj, "x": val, "dir": dir})
			return {"ok": true, "verdict": V.OK if val == int(fv.v) else V.WRONG_MIN, "type": "FILL", "data": data,
				"val": val}
		"pick_end":
			if phase != P.PICK_END:
				return {"ok": false, "reason": "wrong_phase"}
			var j := int(move.get("j", -1))
			if j < 0 or j > cb:
				return {"ok": false, "reason": "range", "at": j}
			var ok := int(tab[ra][j]) == row_min()
			return {"ok": true, "verdict": V.OK if ok else V.WRONG_END, "type": "PICK_END",
				"data": {"j": j, "v": row_min(), "cols": str(min_cols()).trim_prefix("[").trim_suffix("]"),
					"got": int(tab[ra][j])}}
		"step":
			if phase != P.TRACE:
				return {"ok": false, "reason": "wrong_phase"}
			var dir2 := str(move.get("dir", ""))
			if not dir2 in ["diag", "up", "left"]:
				return {"ok": false, "reason": "unknown_act"}
			var p := TxReference.pred(dir2, ti, tj)
			if p.x < 0 or p.y < 0:
				return {"ok": false, "reason": "range", "at": [ti, tj]}
			if not carries(ti, tj, dir2):
				return {"ok": false, "reason": "no_current", "at": [ti, tj]}
			return {"ok": true, "verdict": V.OK, "type": "STEP", "data": {"i": ti, "j": tj, "dir": dir2}}
		"trace_again":
			if phase != P.TRACE_DONE:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "TRACE_AGAIN"}
		"finish":
			if phase != P.TRACE_DONE:
				return {"ok": false, "reason": "wrong_phase"}
			return {"ok": true, "verdict": V.OK, "type": "FINISH"}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, jd: Dictionary, _e: Dictionary) -> void:
	match str(move.act):
		"fill":
			var val := int(jd.val)
			tab[ci][cj] = val
			dirs[ci][cj] = str(move.dir)
			counters.relays = int(counters.relays) + 1
			_fx.append({"fx": "cell", "i": ci, "j": cj, "v": val, "dir": str(move.dir), "cost": cost(str(move.dir), ci, cj),
				"warm": int(jd.verdict) != V.OK})
			cj += 1
			if cj > cb:
				cj = 1
				ci += 1
			if ci > ra:
				_after_fill()
		"pick_end":
			end_j = int(move.j)
			_fx.append({"fx": "end_pick", "j": end_j, "v": int(tab[ra][end_j])})
			_start_trace(ra, end_j)
		"step":
			var dir := str(move.dir)
			var st := {"dir": dir, "i": ti, "j": tj}
			trace_steps.append(st)
			var op := {}
			if dir == "diag" and a[ti - 1] != b[tj - 1]:
				op = {"op": "vervang", "from": a[ti - 1], "to": b[tj - 1]}
			elif dir == "up":
				op = {"op": "verwijder", "from": a[ti - 1], "to": ""}
			elif dir == "left":
				op = {"op": "voegtoe", "from": "", "to": b[tj - 1]}
			_fx.append({"fx": "trace_step", "i": ti, "j": tj, "dir": dir, "op": op})
			var p := TxReference.pred(dir, ti, tj)
			ti = p.x
			tj = p.y
			if trace_finished():
				_trace_end()
		"trace_again":
			if approx:
				phase = P.PICK_END
				end_j = -1
			else:
				_start_trace(ra, cb)
		"finish":
			if approx and found_count() == 0:
				for o in truth:
					if not _occ_missed(o):
						_mark_missed(o)
			_finish_stage()


func _forward_path() -> Array:
	var out: Array = []
	for q in range(trace_steps.size() - 1, -1, -1):
		out.append(trace_steps[q])
	return out


func _trace_end() -> void:
	var path := _forward_path()
	var start_col := TxReference.path_start_col(path) if approx else 0
	var ops := TxReference.ops_of_path(path, a, b, start_col)
	var endc := end_j if approx else cb
	var result := TxReference.apply_ops(a, ops)
	_fx.append({"fx": "print_ops", "ops": ops, "result": result, "start": start_col, "end": endc - 1})
	var key := ("%d:%d" % [start_col, endc]) if approx else TxReference.ops_key(ops)
	if not found_keys.has(key):
		found_keys.append(key)
		if approx:
			sequences.append({"start": start_col, "end_col": endc, "ops": ops})
		else:
			sequences.append(ops)
	if approx:
		var dist := TxReference.edit_distance(a, b.substr(start_col, endc - start_col))
		var real := dist == best_true
		if stage.has("truth"):
			real = real and _is_true(start_col, endc - 1)
		var h := _report(start_col, endc - 1, int(tab[ra][endc]), real, {"ops": ops})
		if not real:
			_false_alarm(h, {"machine": "edit", "dist": dist, "best": best_true})
	phase = P.TRACE_DONE


## Alle stroomvoerende voltooiingen vanaf de huidige spoorcel, als volledige voorwaartse paden.
func _completions(i: int, j: int, prefix_fwd: Array) -> Array:
	var out: Array = []
	for p in TxReference.all_paths(tab, a, b, i, j, approx):
		var full: Array = (p as Array).duplicate()
		full.append_array(prefix_fwd)
		out.append(full)
	return out


func _key_of(path: Array, endc: int) -> String:
	if approx:
		return "%d:%d" % [TxReference.path_start_col(path), endc]
	return TxReference.ops_key(TxReference.ops_of_path(path, a, b))


## Alle verschillende sleutels die met de huidige (speler)tabel bereikbaar zijn.
func available_keys() -> Array:
	var keys: Array = []
	var ends: Array = min_cols() if approx else [cb]
	for e in ends:
		for p in TxReference.all_paths(tab, a, b, ra, int(e), approx):
			var kk := _key_of(p, int(e))
			if not keys.has(kk):
				keys.append(kk)
	return keys


func _goal_reached() -> bool:
	var avail := available_keys()
	var target := avail.size() if want < 0 else mini(want, avail.size())
	return found_keys.size() >= target


func _correct() -> Dictionary:
	match phase:
		P.FILL:
			var fv := _fill_values(ci, cj)
			for dir in ["diag", "up", "left"]:
				if int(fv[dir]) == int(fv.v):
					return {"act": "fill", "dir": dir}
		P.PICK_END:
			var cols := min_cols()
			for e in cols:
				for p in TxReference.all_paths(tab, a, b, ra, e, true):
					if not found_keys.has(_key_of(p, e)):
						return {"act": "pick_end", "j": e}
			return {"act": "pick_end", "j": cols[0]}
		P.TRACE:
			var prefix := _forward_path()
			var endc := end_j if approx else cb
			var first := ""
			for dir in TxReference.arrows(tab, a, b, ti, tj):
				if first == "":
					first = dir
				var p2 := TxReference.pred(dir, ti, tj)
				var pre2: Array = [{"dir": dir, "i": ti, "j": tj}]
				pre2.append_array(prefix)
				for full in _completions(p2.x, p2.y, pre2):
					if not found_keys.has(_key_of(full, endc)):
						return {"act": "step", "dir": dir}
			if first != "":
				return {"act": "step", "dir": first}
		P.TRACE_DONE:
			if _goal_reached():
				return {"act": "finish"}
			return {"act": "trace_again"}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.FILL:
			var fv := _fill_values(ci, cj)
			for dir in ["up", "left", "diag"]:
				if int(fv[dir]) != int(fv.v):
					out.append({"act": "fill", "dir": dir})
					break
		P.PICK_END:
			var mn := row_min()
			for j in range(0, cb + 1):
				if int(tab[ra][j]) != mn:
					out.append({"act": "pick_end", "j": j})
					break
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.FILL:
			out.append({"act": "step", "dir": "up"})
			out.append({"act": "pick_end", "j": 1})
			out.append({"act": "fill", "dir": "nergens"})
		P.PICK_END:
			out.append({"act": "pick_end", "j": -1})
			out.append({"act": "pick_end", "j": cb + 1})
			out.append({"act": "fill", "dir": "diag"})
		P.TRACE:
			for dir in ["diag", "up", "left"]:
				if not carries(ti, tj, dir):
					out.append({"act": "step", "dir": dir})
			out.append({"act": "finish"})
		P.TRACE_DONE:
			out.append({"act": "step", "dir": "up"})
			out.append({"act": "fill", "dir": "diag"})
	return out


func distinct_sequences() -> Array:
	return sequences.duplicate(true)


func true_table() -> Array:
	return true_tab.duplicate(true)


func matches_found() -> Array:
	var out: Array = []
	if approx:
		for s in sequences:
			out.append({"start": int(s.start), "end": int(s.end_col) - 1})
	return out


func cursor() -> Dictionary:
	var i := ci
	var j := cj
	if phase == P.TRACE or phase == P.TRACE_DONE:
		i = ti
		j = tj
	return {"phase": phase, "i": i, "j": j, "end_j": end_j, "sequences_found": found_keys.size(),
		"matches_found": matches_found(), "approx": approx}


func _render_extra() -> Dictionary:
	return {"tab": tab.duplicate(true), "dirs": dirs.duplicate(true), "true_tab": true_tab.duplicate(true),
		"trace": trace_steps.duplicate(true), "a": a, "b": b, "best": best_true}


func tables() -> Dictionary:
	return {"kind": "table", "yours": tab.duplicate(true), "correct": true_tab.duplicate(true), "dirs": dirs.duplicate(true),
		"a": a, "b": b, "approx": approx}


func _snap() -> Dictionary:
	var tb: Array = []
	for r in tab:
		tb.append(_ints(r))
	var dr: Array = []
	for r in dirs:
		var rr: Array = []
		for x in r:
			rr.append(str(x))
		dr.append(rr)
	return {"tab": tb, "dirs": dr, "ci": ci, "cj": cj, "ti": ti, "tj": tj, "end_j": end_j,
		"trace": trace_steps.duplicate(true), "keys": found_keys.duplicate(), "seqs": sequences.duplicate(true)}


func _restore(d: Dictionary) -> void:
	tab = []
	for r in d.get("tab", []):
		tab.append(_ints(r))
	dirs = []
	for r in d.get("dirs", []):
		var rr: Array[String] = []
		for x in r:
			rr.append(str(x))
		dirs.append(rr)
	ci = int(d.get("ci", 1))
	cj = int(d.get("cj", 1))
	ti = int(d.get("ti", ra))
	tj = int(d.get("tj", cb))
	end_j = int(d.get("end_j", -1))
	trace_steps = []
	for s in d.get("trace", []):
		trace_steps.append({"dir": str(s.dir), "i": int(s.i), "j": int(s.j)})
	found_keys = []
	for kk in d.get("keys", []):
		found_keys.append(str(kk))
	sequences = []
	for s in d.get("seqs", []):
		sequences.append(_fix_seq(s))


static func _fix_op(o: Dictionary) -> Dictionary:
	return {"op": str(o.op), "pos": int(o.pos), "from": str(o.from), "to": str(o.to)}


func _fix_seq(s) -> Variant:
	if s is Dictionary:
		var ops: Array = []
		for o in s.ops:
			ops.append(_fix_op(o))
		return {"start": int(s.start), "end_col": int(s.end_col), "ops": ops}
	var out: Array = []
	for o in s:
		out.append(_fix_op(o))
	return out


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for i in ra + 1:
		for j in cb + 1:
			var v := int(tab[i][j])
			if v < 0:
				continue
			if i == 0 or j == 0:
				var want_v := i if j == 0 else (0 if approx else j)
				if v != want_v:
					e.append("rand (%d,%d) = %d" % [i, j, v])
				continue
			var dr := str(dirs[i][j])
			if dr == "" or not carries(i, j, dr):
				e.append("cel (%d,%d) = %d niet gedragen door %s" % [i, j, v, dr])
			if v < int(true_tab[i][j]):
				e.append("cel (%d,%d) = %d < echte waarde %d" % [i, j, v, int(true_tab[i][j])])
	if phase == P.FILL and int(tab[ci][cj]) != -1:
		e.append("cursor op een gevulde cel")
	return e
