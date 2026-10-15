extends RefCounted
## Gedeelde helpers voor de Kortschrift-suites.


static func mk(stage: Dictionary, carry := {}) -> ScTool:
	var t := ScLevels.make_tool(stage, carry)
	t.begin()
	return t


## Stage i van level id, met de carry van een perfect gespeelde vorige stage.
static func mk_stage(id: String, i: int) -> ScTool:
	var spec := ScLevels.get_spec(id)
	var carry := {}
	for q in i:
		var p := mk(spec.stages[q], carry)
		p.auto_finish()
		carry = p.output()
	return mk(spec.stages[i], carry)


## snapshot → JSON → restore → snapshot is identiek.
static func snap_roundtrip(t: ScTool) -> bool:
	var s1 := t.snapshot()
	var js = JSON.parse_string(JSON.stringify(s1))
	t.restore(js)
	var s2 := t.snapshot()
	return JSON.stringify(ScTool.norm(s1)) == JSON.stringify(ScTool.norm(s2))


## Speelt de stage verder met het orakel. bad = [aantal problemen, eerste melding].
static func play(t: ScTool, bad: Array, snap := true, max_moves := 100000) -> int:
	var moves := 0
	while not t.is_done() and moves < max_moves:
		if snap and not snap_roundtrip(t):
			_bad(bad, "snapshot-roundtrip faalt in fase %s" % ScCodes.phase_name(t.phase))
		var mv := t.correct_move()
		if str(mv.get("act", "none")) == "none":
			_bad(bad, "orakel zegt none in fase %s" % ScCodes.phase_name(t.phase))
			break
		var r := t.apply(mv)
		moves += 1
		if not bool(r.ok) or int(r.verdict) != ScCodes.Verdict.OK:
			_bad(bad, "orakelzet %s → %s" % [str(mv), str(r)])
			break
		var inv := t.invariants()
		if not inv.is_empty():
			_bad(bad, "invariant na %s: %s" % [str(mv), str(inv)])
	return moves


static func _bad(bad: Array, msg: String) -> void:
	bad[0] = int(bad[0]) + 1
	if bad.size() < 2:
		bad.append(msg)


## Verzamelt fx van een werktuig.
static func record(t: ScTool) -> Array:
	var rec: Array = []
	t.changed.connect(func(fx: Dictionary) -> void: rec.append(fx))
	return rec


static func fx_names(rec: Array) -> Array:
	var out: Array = []
	for f in rec:
		out.append(str(f.fx))
	return out


## Wat Letterlijk van de uitvoer van een zendwerktuig leest.
static func read_of(t: ScTool) -> String:
	var o := t.output()
	match str(o.get("kind", "")):
		"bits":
			if t is ScRuler:
				return str(ScReader.read("arith", o).text)
			return str(ScReader.read("huffman", o).text)
		"tokens":
			return str(ScReader.read("adaptive", o).text)
		"triples":
			return str(ScReader.read("lz77", o).text)
		"codes":
			return str(ScReader.read("lzw", o).text)
		"bwt":
			return str(ScReader.read("bwt", o).text)
		"numbers":
			return str(ScReader.read("mtf", o).text)
	return t.copy()


## De rijindex van een stapel met label lab in de binderij.
static func row_index(b: ScBindery, lab: String) -> int:
	for q in b.row.size():
		if b.label(b.row[q]) == lab:
			return q
	return -1


## Het id van de top met dit label ("g[1,6]" of "*[2,6]") in een levende boom.
static func node_by_label(lt: ScLivingTree, lab: String) -> int:
	for x in lt.tree.ids():
		if lt.tree.label(x) == lab:
			return x
	return -1
