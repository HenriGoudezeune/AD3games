extends RefCounted
## Meta: zuiverheid van de core, class_names, coachzinnen voor elke misstap, klemredenen, signaalvolgorde, teksten.

const H := preload("res://games/telex/tests/suites/tx_helpers.gd")
const VD := TxCodes.Verdict
const CORE := "res://games/telex/scripts/core/"
const REASONS := ["no_mesh", "zero", "hole", "filled", "range", "last_pos", "out_of_window", "already", "no_w",
	"not_now", "no_current", "no_card", "wrong_phase", "unknown_act", "no_alarm"]


func _files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if d.current_is_dir():
			if not f.begins_with("."):
				out.append_array(_files(dir.path_join(f)))
		elif f.ends_with(".gd"):
			out.append(dir.path_join(f))
		f = d.get_next()
	return out


func _words(s: String) -> int:
	return s.split(" ", false).size()


func run(t) -> void:
	t.section("Zuiverheid en class_names")
	var bad_pure := PackedStringArray()
	var names := {}
	for p in _files(CORE):
		var src := FileAccess.get_file_as_string(p)
		for forbidden in ["Engine.", "Time.", "OS.", "Input.", "get_tree", "extends Node", "await "]:
			if src.contains(forbidden):
				bad_pure.append("%s: %s" % [p.get_file(), forbidden])
		for line in src.split("\n"):
			if line.begins_with("class_name "):
				var cn := line.substr(11).split(" ")[0]
				names[cn] = p
				if not cn.begins_with("Tx"):
					bad_pure.append("%s: class_name %s zonder Tx" % [p.get_file(), cn])
	t.eq(bad_pure, PackedStringArray(), "geen Engine/Time/OS/nodes in de core; alle class_names Tx*")
	t.eq(names.size(), 18, "18 core-klassen (GDD §8.1)")
	var dup := PackedStringArray()
	var seen := {}
	for p in _files("res://"):
		if p.contains("/.godot/") or p.contains("/addons/"):
			continue
		var src2 := FileAccess.get_file_as_string(p)
		for line in src2.split("\n"):
			if line.begins_with("class_name "):
				var cn2 := line.substr(11).split(" ")[0]
				if seen.has(cn2) and seen[cn2] != p:
					dup.append("%s: %s en %s" % [cn2, seen[cn2], p])
				seen[cn2] = p
	t.eq(dup, PackedStringArray(), "geen dubbele class_names in het project")

	t.section("Teksten")
	for id in TxLevels.ids():
		var s := TxLevels.get_spec(id)
		t.ok(_words(s.intro) <= 12, "%s: Chef-zin ≤ 12 woorden (%d)" % [id, _words(s.intro)])
		t.ok(s.title != "" and s.notes_ref != "", "%s: titel en notasverwijzing" % id)

	t.section("Coachzin + notasverwijzing voor elke misstap")
	var got := {}
	var bad_line := PackedStringArray()
	var reasons := {}
	for id in TxLevels.ids():
		if id == "F":
			continue
		for md in ["every", "random", "bump"]:
			for sd in [1, 2, 3, 4]:
				var bot := TxBot.new(md, sd)
				bot.p = 0.4
				var dd := TxDirector.new()
				dd.start(TxLevels.get_spec(id))
				bot.run(dd, 0.05, 1500.0)
				for e in dd.log.entries:
					var v := int(e.verdict)
					if v == VD.OK:
						continue
					got[v] = true
					var line := dd.log.coach_line(e)
					var ref := dd.log.notes_ref(e)
					if line == "" or (ref == "" and v != VD.BUMP) or _words(line) > 20:
						bad_line.append("%s %s: '%s' / '%s'" % [id, TxCodes.verdict_name(v), line, ref])
					if v == VD.BUMP:
						reasons[str(e.data.get("reason", ""))] = true
				dd.dispose()
	# misstappen die enkel met een gerichte zet ontstaan
	_extra_verdicts(got, bad_line)
	t.eq(bad_line, PackedStringArray(), "elke misstap heeft een coachzin (≤ 20 woorden) en een notasverwijzing")
	var missing := PackedStringArray()
	for v in TxCodes.Verdict.values():
		if v != VD.OK and not got.has(v):
			missing.append(TxCodes.verdict_name(v))
	t.eq(missing, PackedStringArray(), "alle verdicts komen voor in het spel")
	var bad_reason := PackedStringArray()
	for r in reasons:
		if not REASONS.has(r):
			bad_reason.append(r)
	t.eq(bad_reason, PackedStringArray(), "klemredenen ⊆ contract (%s)" % str(reasons.keys()))

	t.section("Signaalvolgorde per zet (§8.4)")
	var order: Array = []
	var k := TxLevels.make_machine({"machine": "kmp", "z": "tata", "t": "tatatata", "find": "first", "strip": "none"})
	k.changed.connect(func(_f: Dictionary) -> void: order.append("changed"))
	k.counters_changed.connect(func(_c: Dictionary) -> void: order.append("counters"))
	k.reported.connect(func(_h: Dictionary) -> void: order.append("reported"))
	k.consequence.connect(func(_c: Dictionary) -> void: order.append("consequence"))
	k.event_logged.connect(func(_e: Dictionary) -> void: order.append("logged"))
	k.phase_changed.connect(func(_p: int, _c: Dictionary) -> void: order.append("phase"))
	k.stage_done.connect(func(_r: Dictionary) -> void: order.append("done"))
	k.begin()
	order.clear()
	k.apply({"act": "go"})
	var compact: Array = []
	for o in order:
		if compact.is_empty() or compact[-1] != o:
			compact.append(o)
	t.eq(compact, ["changed", "counters", "reported", "logged", "phase", "done"], "changed → counters → reported → logged → phase → done")
	H.unhook(k)
	var k2 := TxLevels.make_machine({"machine": "kmp", "z": "tata", "t": "tatatata", "find": "all", "strip": "none"})
	k2.begin()
	k2.apply({"act": "go"})
	var o2: Array = []
	k2.consequence.connect(func(_c: Dictionary) -> void: o2.append("consequence"))
	k2.event_logged.connect(func(_e: Dictionary) -> void: o2.append("logged"))
	k2.phase_changed.connect(func(_p: int, _c: Dictionary) -> void: o2.append("phase"))
	k2.apply({"act": "shift", "s": 4})
	t.eq([o2[0], o2.has("phase"), o2[-1]], ["consequence", true, "phase"], "consequence vóór event_logged, phase_changed als laatste")
	H.unhook(k2)

	t.section("Klem verandert niets (behalve log en klemteller), elke machine")
	var bad_bump := 0
	for id in TxLevels.ids():
		if id == "F":
			continue
		var spec := TxLevels.get_spec(id)
		var carry := {}
		for i in spec.stages.size():
			var mc := TxLevels.make_machine(spec.stages[i], carry)
			mc.begin()
			var g := 0
			while not mc.is_done() and g < 3000:
				g += 1
				for im in mc.impossible_moves():
					var s0 := mc.snapshot()
					mc.apply(im)
					var s1 := mc.snapshot()
					s0.erase("log_len")
					s1.erase("log_len")
					(s1.counters as Dictionary).bumps = int(s0.counters.bumps)
					if var_to_str(s0) != var_to_str(s1):
						bad_bump += 1
				mc.apply(mc.correct_move())
			carry = mc.output()
	t.eq(bad_bump, 0, "klemmen laten de toestand ongemoeid")


## Verdicts die de bots niet vanzelf maken: gericht uitlokken.
func _extra_verdicts(got: Dictionary, bad: PackedStringArray) -> void:
	var cases: Array = []
	# TEAR (3-5, te traag)
	var dd := TxDirector.new()
	dd.start(TxLevels.get_spec("3-5"))
	var slow := TxBot.new("", 1)
	slow.think = 8.0
	slow.run(dd, 0.05, 300.0)
	cases.append(dd.log)
	# LATE (5-3, niets doen)
	var dr := TxDirector.new()
	dr.start(TxLevels.get_spec("5-3"))
	TxBot.new("idle").run(dr, 0.05, 100.0)
	cases.append(dr.log)
	# WRONG_PICK (6-2), WRONG_WIRE (6-1)
	var rp := TxDirector.new()
	rp.start(TxLevels.get_spec("6-1"))
	TxBot.new("plug:old").run(rp, 0.05, 300.0)
	cases.append(rp.log)
	var mc := H.mk({"machine": "shift_and", "z": "zender", "t": "zonder_zender_zander_zinder", "k": 1,
		"cards": "prefilled", "wiring": "prefilled", "find": "all", "choose": true})
	var g := 0
	while mc.phase != TxCodes.Phase.CHOOSE and g < 200:
		g += 1
		mc.apply(mc.correct_move())
	mc.apply({"act": "choose", "start": 0})
	cases.append(mc.log)
	# UNVERIFIED (2-3, report bij de echte treffer)
	var rk := H.mk({"machine": "rk", "z": "00101", "q": 13, "t": "1101110010001010", "find": "first",
		"prep": ["w", "hz", "h0"]})
	g = 0
	while not rk.is_done() and g < 500:
		g += 1
		if rk.phase == TxCodes.Phase.ALARM and (rk as TxRabinKarp).i == 10:
			rk.apply({"act": "report"})
		else:
			rk.apply(rk.correct_move())
	cases.append(rk.log)
	for lg in cases:
		for e in lg.entries:
			var v := int(e.verdict)
			if v == VD.OK:
				continue
			got[v] = true
			if lg.coach_line(e) == "" or (lg.notes_ref(e) == "" and v != VD.BUMP):
				bad.append("%s: '%s'" % [TxCodes.verdict_name(v), lg.coach_line(e)])
	dd.dispose()
	dr.dispose()
	rp.dispose()
