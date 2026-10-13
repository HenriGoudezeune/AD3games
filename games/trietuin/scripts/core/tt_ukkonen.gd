class_name TtUkkonen extends TtSuffixTree
## Stapsgewijze Ukkonen (notas §3.2.1, p. 34–48; GDD §3.5, §8.7). Bouwt S(1,1) … S(1,n+1).
## Notas-notatie: iteratie it (1-gebaseerd) voegt s_it = text[it−1] toe; extensie j voegt σ_{j,it} toe;
## de wijzer (p, x) staat op σ_{j,it−1}. Open bladbogen hebben e = TtCodes.OPEN ("it").
## Zetten: {"act":"hop","node":id} · {"act":"rule","grow":b} · {"act":"link","node":id} · {"act":"follow","mode":"link"|"minus"}
## Foute keuzes worden geweigerd (ok = false) met een eigen verdict (WRONG_HOP/RULE/LINK/FOLLOW); ze tellen als
## misstap als count_bumps (Ukkonen-levels).

var it: int = 0          # huidige iteratie (0 = nog niet begonnen)
var j: int = 1           # huidige extensie (1-gebaseerd) = b(i): eerste suffix dat geen blad is
var p: int = -1          # wijzer: top
var x: int = 0           # wijzer: aantal tekens verder
var pending: int = -1    # nieuwe interne top die op zijn suffix link wacht
var link_target: int = -1
var link_cont: String = ""   # "grow" | "stop": wat er na het vasthechten van de link gebeurt
var new_pending: int = -1
var hops: int = 0        # sprongen in de huidige extensie
var finished: bool = false
var _trace: Array = []


func _init() -> void:
	kind = TtCodes.Kind.UKKONEN
	count_bumps = true


func setup_text(alpha: TtAlphabet, text_: String, pos_base_: int = 1,
		owners_: PackedInt32Array = PackedInt32Array()) -> TtUkkonen:
	setup(alpha, text_, pos_base_, "pointers", owners_)
	_ustate_reset()
	return self


func _ustate_reset() -> void:
	it = 0
	j = 1
	p = root
	x = 0
	pending = -1
	link_target = -1
	link_cont = ""
	new_pending = -1
	hops = 0
	finished = false
	_trace = []


func _reset() -> void:
	super._reset()
	_ustate_reset()


func _open_end() -> int:
	if finished:
		return n
	return maxi(it - 1, 0)


## Totaal aantal tekens N = n + 1 (incl. afsluitteken).
func total() -> int:
	return text.length()


# ------------------------------------------------------------------ orakel-hulpen

func _first_char_index() -> int:
	return it - x - 1


## Het kind van p waarlangs de x tekens lopen (of -1).
func _edge_kid() -> int:
	if x <= 0:
		return -1
	return int(node(p).kids.get(text[_first_char_index()], -1))


func _needs_hop() -> bool:
	var k := _edge_kid()
	if k < 0:
		return false
	if node(k).type == NT.LEAF:
		return false
	return x >= edge_len(k)


## Zit σ_{j,it} er al in? (teken s_it na het punt (p, x))
func _present() -> bool:
	var ch := text[it - 1]
	if x == 0:
		return node(p).kids.has(ch)
	var k := _edge_kid()
	return text[node(k).b + x] == ch


func _set_phase_for_extension() -> void:
	phase = P.U_CANON if _needs_hop() else P.U_RULE


func _start_iteration() -> void:
	it += 1
	hops = 0
	_fx_add({"fx": "iteration", "i": it, "ch": text[it - 1]})
	_fx_add({"fx": "leaf_grow", "it": it})
	_fx_add({"fx": "firefly", "p": p, "x": x})
	_set_phase_for_extension()


func _end_iteration_after_stop() -> void:
	x += 1
	_fx_add({"fx": "firefly", "p": p, "x": x})
	_next_iteration()


func _next_iteration() -> void:
	if it >= total():
		_close()
		return
	_start_iteration()


func _close() -> void:
	finished = true
	for id in nodes.keys():
		var nd: TtNode = nodes[id]
		if nd.e == TtCodes.OPEN:
			nd.e = n
			_fx_add({"fx": "label", "node": nd.id, "b": nd.b, "e": n})
	phase = P.DONE
	_finish("built")


# ------------------------------------------------------------------ kaart

func _begin_other(c: TtCard) -> void:
	if c.kind != CK.UKKONEN:
		super._begin_other(c)
		return
	if finished:
		_finish("built")
		return
	st = {"uk": true}
	if it == 0:
		_start_iteration()
	else:
		_set_phase_for_extension()


func run_all() -> void:
	if finished:
		return
	if card == null:
		var c := TtCard.new()
		c.id = -1
		c.kind = CK.UKKONEN
		begin(c)
	auto_finish_card()


func _correct() -> Dictionary:
	match phase:
		P.U_CANON:
			return {"act": "hop", "node": _edge_kid()}
		P.U_RULE:
			return {"act": "rule", "grow": not _present()}
		P.U_LINK:
			return {"act": "link", "node": link_target}
		P.U_FOLLOW:
			return {"act": "follow", "mode": "minus" if p == root else "link"}
	return super._correct()


func active() -> Dictionary:
	return {"p": p, "x": x, "j": j, "i": it - 1, "it": it, "ch": text[it - 1] if it >= 1 and it <= total() else "",
		"pending": pending, "b_i": j, "j0": j - 1, "i0": it - 1, "link_target": link_target if phase == P.U_LINK else -1,
		"edge": _edge_kid(), "finished": finished}


func sigmas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in range(1, it + 1):
		out.append({"j": k, "leaf": k < j, "current": k == j and not finished})
	return out


func trace() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in _trace:
		out.append(r)
	return out


func cursor() -> Dictionary:
	if card != null and card.kind != CK.UKKONEN:
		return super.cursor()
	var c := active()
	c["phase"] = phase
	return c


func _bump_at() -> int:
	return p


func _apply_other(move: Dictionary, hint: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	match act:
		"hop":
			return _do_hop(int(move.get("node", -1)))
		"rule":
			return _do_rule(bool(move.get("grow", false)))
		"link":
			return _do_link(int(move.get("node", -1)))
		"follow":
			return _do_follow(str(move.get("mode", "")))
	return super._apply_other(move, hint)


func _ubump(reason: String, verdict: int, data: Dictionary = {}) -> Dictionary:
	return {"ok": false, "verdict": verdict, "reason": reason, "type": "BUMP", "data": data, "at": p}


func _do_hop(id: int) -> Dictionary:
	if phase != P.U_CANON and phase != P.U_RULE:
		return _bump("wrong_phase")
	var k := _edge_kid()
	var L := edge_len(k) if k >= 0 else 0
	var data := {"x": x, "L": L, "node": id}
	if phase == P.U_RULE:
		return _ubump("short_edge", V.WRONG_HOP, data)
	if id != k:
		return _ubump("wrong_edge", V.WRONG_HOP, data)
	var from := p
	p = k
	x -= L
	hops += 1
	_fx_add({"fx": "hop", "from": from, "to": p, "x": x})
	_fx_add({"fx": "firefly", "p": p, "x": x})
	_set_phase_for_extension()
	return {"ok": true, "verdict": V.OK, "type": "HOP", "data": data}


func _do_rule(grow: bool) -> Dictionary:
	if phase == P.U_CANON:
		var k := _edge_kid()
		return _ubump("not_canonical", V.WRONG_HOP, {"x": x, "L": edge_len(k)})
	if phase != P.U_RULE:
		return _bump("wrong_phase")
	var present := _present()
	var ch := text[it - 1]
	var sigma := text.substr(j - 1, it - j)
	if grow == present:
		var nxt := ""
		if x == 0:
			nxt = "" if not present else ch
		else:
			nxt = text[node(_edge_kid()).b + x]
		var r := "ii" if x == 0 else "iii"
		return _ubump("already_there" if grow else "missing", V.WRONG_RULE,
				{"grow": grow, "sigma": sigma, "c": ch, "x": nxt if nxt != "" else "niets", "r": r})
	var rec := {"it": it, "j": j, "rule": "", "hops": hops, "p_before": p, "x_before": x, "link_from": -1, "link_to": -1}
	var data := {"grow": grow, "sigma": sigma, "c": ch, "j": j, "it": it}
	if not grow:
		rec.rule = "a" if x == 0 else "b"
		_trace.append(rec)
		data["rule"] = rec.rule
		if pending >= 0:
			link_target = p
			link_cont = "stop"
			new_pending = -1
			phase = P.U_LINK
		else:
			_end_iteration_after_stop()
		return {"ok": true, "verdict": V.OK, "type": "RULE", "data": data}
	var created := -1
	var parent := p
	if x == 0:
		rec.rule = "ii"
	else:
		rec.rule = "iii"
		var k := _edge_kid()
		created = _split_edge(k, x)
		parent = created
		_fx_add({"fx": "split_edge", "upper": p, "new_node": created, "lower": k, "k": x})
		_fx_add({"fx": "label", "node": created, "b": node(created).b, "e": node(created).e})
		_fx_add({"fx": "label", "node": k, "b": node(k).b, "e": node(k).e})
	var lf := _add_leaf(parent, it - 1, TtCodes.OPEN, j - 1)
	_fx_add({"fx": "attach", "leaf": lf, "at": parent, "off": 0})
	_fx_add({"fx": "label", "node": lf, "b": it - 1, "e": TtCodes.OPEN})
	_trace.append(rec)
	data["rule"] = rec.rule
	data["leaf"] = lf
	if pending >= 0:
		link_target = created if created >= 0 else p
		link_cont = "grow"
		new_pending = created
		phase = P.U_LINK
	else:
		pending = created
		_after_grow()
	return {"ok": true, "verdict": V.OK, "type": "RULE", "data": data}


func _after_grow() -> void:
	if j < it:
		phase = P.U_FOLLOW
	else:
		j = it + 1
		p = root
		x = 0
		_fx_add({"fx": "firefly", "p": p, "x": x})
		_next_iteration()


func _do_link(id: int) -> Dictionary:
	if phase != P.U_LINK:
		return _bump("wrong_phase")
	var data := {"u": node_string(pending), "u2": node_string(link_target), "node": id}
	if id != link_target:
		return _ubump("bad_target", V.WRONG_LINK, data)
	node(pending).link = link_target
	_fx_add({"fx": "link", "from": pending, "to": link_target})
	if not _trace.is_empty():
		_trace[-1].link_from = pending
		_trace[-1].link_to = link_target
	link_target = -1
	if link_cont == "stop":
		pending = -1
		_end_iteration_after_stop()
	else:
		pending = new_pending
		_after_grow()
	link_cont = ""
	return {"ok": true, "verdict": V.OK, "type": "LINK", "data": data}


func _do_follow(mode: String) -> Dictionary:
	if phase != P.U_FOLLOW:
		return _bump("wrong_phase")
	var cm := "minus" if p == root else "link"
	if mode != cm:
		return _ubump("bad_target", V.WRONG_FOLLOW, {"mode": mode})
	if mode == "minus":
		x -= 1
	else:
		p = node(p).link
	j += 1
	hops = 0
	_fx_add({"fx": "firefly", "p": p, "x": x})
	_set_phase_for_extension()
	return {"ok": true, "verdict": V.OK, "type": "FOLLOW", "data": {"mode": mode}}


func wrong_moves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match phase:
		P.U_CANON:
			out.append({"act": "rule", "grow": true})
		P.U_RULE:
			out.append({"act": "rule", "grow": _present()})
			if x > 0:
				out.append({"act": "hop", "node": _edge_kid()})
		P.U_LINK:
			for id in subtree(root):
				if node(id).type == NT.INNER and id != link_target:
					out.append({"act": "link", "node": id})
					break
		P.U_FOLLOW:
			out.append({"act": "follow", "mode": "link" if p == root else "minus"})
	if phase in [P.U_CANON, P.U_RULE, P.U_LINK, P.U_FOLLOW]:
		return out
	return super.wrong_moves()


## In Ukkonen zijn foute zetten weigeringen: impossible_moves == wrong_moves.
func impossible_moves() -> Array[Dictionary]:
	if phase in [P.U_CANON, P.U_RULE, P.U_LINK, P.U_FOLLOW]:
		return wrong_moves()
	return super.impossible_moves()


func _snapshot_extra() -> Dictionary:
	return {"it": it, "j": j, "p": p, "x": x, "pending": pending, "link_target": link_target, "link_cont": link_cont,
		"new_pending": new_pending, "hops": hops, "finished": finished, "trace": _trace.duplicate(true)}


func _restore_extra(d: Dictionary) -> void:
	it = int(d.get("it", 0))
	j = int(d.get("j", 1))
	p = int(d.get("p", root))
	x = int(d.get("x", 0))
	pending = int(d.get("pending", -1))
	link_target = int(d.get("link_target", -1))
	link_cont = str(d.get("link_cont", ""))
	new_pending = int(d.get("new_pending", -1))
	hops = int(d.get("hops", 0))
	finished = bool(d.get("finished", false))
	_trace = []
	for r in d.get("trace", []):
		var rr := {}
		for k in r.keys():
			rr[k] = r[k] if r[k] is String else int(r[k])
		_trace.append(rr)


func _invariants() -> PackedStringArray:
	var errs := PackedStringArray()
	# tijdens een iteratie is het een stringboom: interne toppen mogen tijdelijk niet bestaan zonder 2 kinderen? nee:
	# (iii) maakt de top meteen met 2 kinderen, dus de algemene controle geldt altijd.
	errs.append_array(super._invariants())
	if node(root).link != root:
		errs.append("wortel linkt niet naar zichzelf")
	for id in nodes.keys():
		var nd: TtNode = nodes[id]
		if nd.type == NT.INNER and nd.link >= 0 and int(id) != root:
			var a := node_string(nd.id)
			var b := node_string(nd.link)
			if a.substr(1) != b:
				errs.append("suffix link %s → %s klopt niet" % [a, b])
	return errs
