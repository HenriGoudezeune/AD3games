class_name ScDrum extends ScTool
## Draaitrommel (GDD §3.8): Burrows-Wheeler, zenden (rotaties invoegen in het rek, rij p markeren) en ontvangen
## (de terugweg met rangen). p = de rij die eindigt op s[0] (p. 117); uitvoer "p␣c".
## Zenden: fase INSERT {"act":"insert","gap":g} (0 = bovenaan), fase MARK {"act":"mark","row":r}.
## Ontvangen: fase WALK {"act":"find","i":i}: de rij in kolom c met dezelfde letter en dezelfde rang als x.
## stage {"tool":"drum","side":"send","text":"geen loon","auto_sort":false}
##       {"tool":"drum","side":"receive","p":1,"c":"ngen eool","ranks":true,"expect":"geen loon"}

var s: String = ""
var n: int = 0
var auto_sort: bool = false
var rack: Array[int] = []       # rotatie-indices in rekvolgorde
var pending: int = 0            # volgende rotatie
var p_out: int = -1
var c_out: String = ""
# ontvangen
var p: int = 0
var c: String = ""
var e: String = ""
var rc: Array[int] = []
var re: Array[int] = []
var ranks_visible: bool = false
var x_ch: String = ""
var x_rank: int = 0
var x_row: int = -1             # rij van x in e
var step: int = 0               # aantal keuzes gedaan
var walk: Array = []            # [{from_row, to_row, ch, rank}]
var copy_text: String = ""
var expect: String = ""


func _setup() -> void:
	tool = ScCodes.Tool.DRUM
	expect = str(stage.get("expect", ""))
	if side == ScCodes.Side.SEND:
		s = str(stage.get("text", carry_in.get("text", "")))
		n = s.length()
		auto_sort = bool(stage.get("auto_sort", false))
	else:
		p = int(stage.get("p", 0))
		c = str(stage.get("c", ""))
		n = c.length()
		e = ScReference.sorted_chars(c)
		rc = ScReference.ranks(c)
		re = ScReference.ranks(e)
		ranks_visible = bool(stage.get("ranks", false))
	rack = []
	pending = 0
	p_out = -1
	c_out = ""
	step = 0
	walk = []
	copy_text = ""


func rot(r: int) -> String:
	return ScReference.rotation(s, r)


func _begin() -> void:
	if side == ScCodes.Side.SEND:
		if n == 0:
			_finish()
			return
		_fx.append({"fx": "rotation", "r": 0, "text": rot(0)})
		rack = [0]
		_fx.append({"fx": "insert", "r": 0, "gap": 0})
		pending = 1
		if auto_sort:
			while pending < n:
				var g := _gap_lo(pending)
				_fx.append({"fx": "rotation", "r": pending, "text": rot(pending)})
				rack.insert(g, pending)
				_fx.append({"fx": "insert", "r": pending, "gap": g, "auto": true})
				pending += 1
			_log("INSERT", {"auto_sort": true}, V.OK, true, {}, {}, true)
		_next_insert()
	else:
		if n == 0:
			_finish()
			return
		copy_text = c[p]
		_copy_dirty = true
		x_row = p
		x_ch = e[p]
		x_rank = re[p]
		_fx.append({"fx": "walk", "from_row": p, "to_row": p, "ch": c[p], "rank": rc[p], "closed": false, "auto": true})
		if n == 1:
			_finish()
			return
		copy_text += x_ch
		phase = P.WALK


func _next_insert() -> void:
	if pending >= n:
		phase = P.MARK
		return
	phase = P.INSERT
	_fx.append({"fx": "rotation", "r": pending, "text": rot(pending)})


## [lo, hi] voor rotatie r in het huidige rek.
func _gap_lo(r: int) -> int:
	return int(_gaps(r)[0])


func _gaps(r: int) -> Array:
	var rr := rot(r)
	var lo := 0
	var hi := 0
	for q in rack:
		var cm := ScReference.str_cmp(rot(q), rr)
		if cm < 0:
			lo += 1
		if cm <= 0:
			hi += 1
	return [lo, hi]


func rows() -> Array[String]:
	var out: Array[String] = []
	for q in rack:
		out.append(rot(q))
	return out


func last_column() -> String:
	var out := ""
	for q in rack:
		out += rot(q)[n - 1]
	return out


# ------------------------------------------------------------------ beoordelen

func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"insert":
			if phase != P.INSERT:
				return {"ok": false, "reason": "wrong_phase"}
			var g := int(move.get("gap", -1))
			if g < 0 or g > rack.size():
				return {"ok": false, "reason": "range", "at": g}
			var gp := _gaps(pending)
			var ok := g >= int(gp[0]) and g <= int(gp[1])
			var data := {"gap": g, "lo": gp[0], "hi": gp[1], "r": pending}
			if not ok:
				# een buur die verkeerd ligt: a hoort vóór b
				if g > int(gp[1]):
					data["a"] = rot(pending)
					data["b"] = rot(rack[g - 1])
				else:
					data["a"] = rot(rack[g])
					data["b"] = rot(pending)
			return {"ok": true, "verdict": V.OK if ok else V.WRONG_ORDER, "type": "INSERT", "data": data}
		"mark":
			if phase != P.MARK:
				return {"ok": false, "reason": "wrong_phase"}
			var r := int(move.get("row", -1))
			if r < 0 or r >= rack.size():
				return {"ok": false, "reason": "range", "at": r}
			var want := rot(1 % n)
			var good := -1
			for q in rack.size():
				if rot(rack[q]) == want:
					good = q
					break
			return {"ok": true, "verdict": V.OK if rot(rack[r]) == want else V.WRONG_P, "type": "MARK",
				"data": {"row": r, "p": good, "s0": s[0]}}
		"find":
			if phase != P.WALK:
				return {"ok": false, "reason": "wrong_phase"}
			var i := int(move.get("i", -1))
			if i < 0 or i >= n:
				return {"ok": false, "reason": "range", "at": i}
			if c[i] != x_ch:
				return {"ok": false, "reason": "letter", "at": i}
			var good_i := ScReference.index_of_rank(c, x_ch, x_rank)
			return {"ok": true, "verdict": V.OK if rc[i] == x_rank else V.WRONG_RANK, "type": "FIND",
				"data": {"i": good_i, "chosen": i, "x": x_ch, "k": x_rank}}
	return {"ok": false, "reason": "unknown_act"}


# ------------------------------------------------------------------ uitvoeren

func _exec(move: Dictionary, _j: Dictionary, _e: Dictionary) -> void:
	match str(move.get("act", "")):
		"insert":
			var g := int(move.gap)
			rack.insert(g, pending)
			_fx.append({"fx": "insert", "r": pending, "gap": g})
			pending += 1
			_next_insert()
		"mark":
			p_out = int(move.row)
			c_out = last_column()
			_out_dirty = true
			_fx.append({"fx": "mark", "row": p_out, "out": ScReference.bwt_text(p_out, c_out)})
			_finish()
		"find":
			var i := int(move.i)
			step += 1
			var from := x_row
			x_row = i
			x_ch = e[i]
			x_rank = re[i]
			var closed := step >= n - 1
			walk.append({"from_row": from, "to_row": i, "ch": c[i], "rank": rc[i]})
			_fx.append({"fx": "walk", "from_row": from, "to_row": i, "ch": c[i], "rank": rc[i],
				"closed": closed and x_ch == c[p] and x_rank == rc[p]})
			if closed:
				_finish()
			else:
				copy_text += x_ch
				_copy_dirty = true


# ------------------------------------------------------------------ orakel

func _correct() -> Dictionary:
	match phase:
		P.INSERT:
			return {"act": "insert", "gap": _gap_lo(pending)}
		P.MARK:
			var want := rot(1 % n)
			for q in rack.size():
				if rot(rack[q]) == want:
					return {"act": "mark", "row": q}
		P.WALK:
			return {"act": "find", "i": ScReference.index_of_rank(c, x_ch, x_rank)}
	return {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.INSERT:
			var gp := _gaps(pending)
			for g in rack.size() + 1:
				if g < int(gp[0]) or g > int(gp[1]):
					out.append({"act": "insert", "gap": g})
		P.MARK:
			var want := rot(1 % n)
			for q in rack.size():
				if rot(rack[q]) != want:
					out.append({"act": "mark", "row": q})
		P.WALK:
			for i in n:
				if c[i] == x_ch and rc[i] != x_rank:
					out.append({"act": "find", "i": i})
	return out


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.INSERT:
			out.append({"act": "insert", "gap": rack.size() + 1})
			out.append({"act": "mark", "row": 0})
		P.MARK:
			out.append({"act": "mark", "row": rack.size()})
		P.WALK:
			for i in n:
				if c[i] != x_ch:
					out.append({"act": "find", "i": i})
			out.append({"act": "find", "i": n})
	return out


# ------------------------------------------------------------------ uitvoer, weergave, snapshot

func _at() -> int:
	return 0 if side == ScCodes.Side.SEND else copy_text.length()


func copy() -> String:
	return copy_text if side == ScCodes.Side.RECEIVE else ""


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": copy_text}
	return {"kind": "bwt", "p": p_out, "c": c_out, "text": ScReference.bwt_text(p_out, c_out) if p_out >= 0 else ""}


func structure() -> Dictionary:
	if side == ScCodes.Side.SEND:
		return {"rows": Array(rows()), "p": p_out, "c": c_out}
	return {"copy": copy_text, "walk": walk.duplicate(true)}


func _cursor() -> Dictionary:
	if side == ScCodes.Side.SEND:
		return {"rack": Array(rows()), "rack_rot": rack.duplicate(), "pending": rot(pending) if pending < n else "",
			"pending_r": pending, "row_count": rack.size(), "first_col": _col(0), "last_col": last_column(), "n": n,
			"side": side}
	return {"p": p, "c": c, "e": e, "ranks_c": rc.duplicate(), "ranks_e": re.duplicate(), "ranks_visible": ranks_visible,
		"x": {"ch": x_ch, "rank": x_rank, "row": x_row}, "step": step, "copy": copy_text, "n": n, "side": side,
		"walk": walk.duplicate(true)}


func _col(q: int) -> String:
	var out := ""
	for r in rack:
		out += rot(r)[q]
	return out


func _snap() -> Dictionary:
	return {"rack": rack.duplicate(), "pending": pending, "p_out": p_out, "c_out": c_out, "x_ch": x_ch,
		"x_rank": x_rank, "x_row": x_row, "step": step, "walk": walk.duplicate(true), "copy": copy_text}


func _restore(d: Dictionary) -> void:
	rack = ints(d.get("rack", []))
	pending = int(d.get("pending", 0))
	p_out = int(d.get("p_out", -1))
	c_out = str(d.get("c_out", ""))
	x_ch = str(d.get("x_ch", ""))
	x_rank = int(d.get("x_rank", 0))
	x_row = int(d.get("x_row", -1))
	step = int(d.get("step", 0))
	walk = d.get("walk", [])
	copy_text = str(d.get("copy", ""))


func _invariants() -> PackedStringArray:
	var er := PackedStringArray()
	if side == ScCodes.Side.SEND:
		if rack.size() != mini(pending, n) and phase != P.DONE:
			er.append("rek %d stroken, verwacht %d" % [rack.size(), pending])
	elif copy_text.length() > n:
		er.append("kopie langer dan n")
	return er
