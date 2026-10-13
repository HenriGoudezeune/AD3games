extends RefCounted
## Gedeelde helpers voor de Telex-suites.


static func mk(stage: Dictionary, carry := {}, live := {}, log: TxEventLog = null) -> TxMachine:
	var mc := TxLevels.make_machine(stage, carry, TxCodes.Mode.LIVE if not live.is_empty() else TxCodes.Mode.CALM,
			live)
	if log != null:
		mc.log = log
	mc.begin()
	return mc


## snapshot → JSON → restore → snapshot is identiek (en de staat blijft dezelfde).
static func snap_roundtrip(mc: TxMachine) -> bool:
	var s1 := mc.snapshot()
	var js = JSON.parse_string(JSON.stringify(s1))
	mc.restore(js)
	var s2 := mc.snapshot()
	return var_to_str(s1) == var_to_str(s2)


## Speelt de stage perfect met het orakel. bad = [aantal problemen, eerste melding].
static func play(mc: TxMachine, bad: Array, snap := true, max_moves := 100000) -> int:
	var moves := 0
	while not mc.is_done() and moves < max_moves:
		if snap and not snap_roundtrip(mc):
			_bad(bad, "snapshot-roundtrip faalt in fase %s" % TxCodes.phase_name(mc.phase))
		var mv := mc.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		var r := mc.apply(mv)
		moves += 1
		if not bool(r.ok) or int(r.verdict) != TxCodes.Verdict.OK:
			_bad(bad, "orakelzet %s → %s" % [str(mv), str(r)])
			break
		var inv := mc.invariants()
		if not inv.is_empty():
			_bad(bad, "invariant na %s: %s" % [str(mv), str(inv)])
	return moves


static func _bad(bad: Array, msg: String) -> void:
	bad[0] = int(bad[0]) + 1
	if bad.size() < 2:
		bad.append(msg)


## Het spoor (start, gel, em) van een KMP-doorloop uit de log/fx: verzamelt via changed-signaal.
static func record(mc: TxMachine) -> Array:
	var rec: Array = []
	mc.changed.connect(func(fx: Dictionary) -> void: rec.append(fx))
	return rec


static func unhook(obj: Object) -> void:
	for sig in obj.get_signal_list():
		for c in obj.get_signal_connection_list(sig.name):
			obj.disconnect(sig.name, c.callable)


static func hit_starts(mc: TxMachine, only_real := true) -> Array:
	var out: Array = []
	for h in mc.hits:
		if not only_real or bool(h.real):
			out.append(int(h.start))
	return out


static func missed_starts(mc: TxMachine) -> Array:
	var out: Array = []
	for x in mc.missed:
		out.append(int(x.start))
	return out
