extends RefCounted
## Contract-tests (GDD §8): signaalvolgorde, preview, fx-namen, coachzinnen, layout, leveldata, bots met foutmodi.

const H := preload("res://games/scriptorium/tests/suites/sc_helpers.gd")
const V := ScCodes.Verdict
const FX := ["bump", "read_path", "cut", "reading_done", "place", "bind", "codebook", "write", "grow", "lantern", "swap",
	"weight", "stumble", "segment", "needle", "needle_reset", "pin", "thread", "seal", "slide", "copy_letters",
	"register_walk", "zetstok", "stamp", "drawer", "carve", "rotation", "insert", "mark", "walk", "shelf_move", "number",
	"roost", "overkant", "stage", "snap", "trial_read", "restore"]
const REASONS := ["not_leaf", "no_path", "no_word", "need_more", "taken", "range", "incomplete", "same", "not_front",
	"empty", "ancestor", "self", "no_pin", "out_of_window", "no_match", "no_stamp", "letter", "not_shorter",
	"wrong_phase", "unknown_act", "unknown"]
const ORDER := {"changed": 0, "counters_changed": 1, "output_changed": 2, "copy_changed": 2, "overkant_changed": 3,
	"event_logged": 4, "phase_changed": 5, "stage_done": 6}


func run(t) -> void:
	_signals_and_contract(t)
	_coach(t)
	_layout(t)
	_leveldata(t)
	_bots(t)


func _signals_and_contract(t) -> void:
	t.section("signaalvolgorde, preview, fx")
	var bad_order := [0]
	var bad_preview := [0]
	var bad_fx := [0]
	var bad_phase := [0]
	var bad_undo := [0]
	for id in ScLevels.ids():
		var spec := ScLevels.get_spec(id)
		var carry := {}
		for st in spec.stages:
			var tl := ScLevels.make_tool(st, carry)
			var seq: Array = []
			for sig in ORDER:
				var nm: String = sig
				tl.connect(nm, func(_a = null, _b = null) -> void: seq.append(nm))
			tl.changed.connect(func(fx: Dictionary) -> void:
				if not FX.has(str(fx.get("fx", ""))):
					H._bad(bad_fx, "%s: fx %s" % [id, str(fx.get("fx", ""))]))
			tl.begin()
			var g := 0
			while not tl.is_done() and g < 3000:
				g += 1
				var mv := tl.correct_move()
				var s0 := JSON.stringify(ScTool.norm(tl.snapshot()))
				var pv := tl.preview(mv)
				if JSON.stringify(ScTool.norm(tl.snapshot())) != s0 or pv.keys().size() != 2 or not bool(pv.ok):
					H._bad(bad_preview, "%s: preview %s → %s" % [id, str(mv), str(pv)])
				seq.clear()
				tl.apply(mv)
				var last := -1
				for nm in seq:
					var o := int(ORDER[nm])
					if o < last:
						H._bad(bad_order, "%s: %s" % [id, str(seq)])
						break
					last = o
				if not seq.has("phase_changed"):
					H._bad(bad_phase, "%s: geen phase_changed na %s" % [id, str(mv)])
				# terugnemen via snapshot herstelt exact
				var s1 := JSON.stringify(ScTool.norm(tl.snapshot()))
				var w := tl.wrong_moves()
				if not w.is_empty():
					var snap := tl.snapshot()
					tl.apply(w[0])
					tl.restore(snap)
					if JSON.stringify(ScTool.norm(tl.snapshot())) != s1:
						H._bad(bad_undo, "%s: restore na %s" % [id, str(w[0])])
			carry = tl.output()
	t.eq(bad_order, [0], "signaalvolgorde changed → counters → output/copy → overkant → event → phase → done")
	t.eq(bad_preview, [0], "preview muteert niets en toont enkel ok/reason")
	t.eq(bad_fx, [0], "enkel gedocumenteerde fx")
	t.eq(bad_phase, [0], "phase_changed na elke zet")
	t.eq(bad_undo, [0], "restore(snapshot) na een foute zet herstelt exact")
	# klem: phase_changed en BUMP-entry
	var pr := H.mk_stage("0-1", 0)
	var seq2: Array = []
	pr.phase_changed.connect(func(_p, _c) -> void: seq2.append("phase"))
	pr.event_logged.connect(func(e: Dictionary) -> void: seq2.append(str(e.type)))
	pr.apply({"act": "read", "leaf": pr.tree.root})
	t.eq(seq2, ["BUMP", "phase"], "klem: BUMP + phase_changed")


func _coach(t) -> void:
	t.section("coachzinnen en verwijzingen")
	var seen := {}
	var bad := [0]
	var reasons := {}
	for id in ScLevels.ids():
		var spec := ScLevels.get_spec(id)
		var carry := {}
		for st in spec.stages:
			var tl := H.mk(st, carry)
			var g := 0
			while not tl.is_done() and g < 3000:
				g += 1
				var snap := tl.snapshot()
				for m in tl.wrong_moves().slice(0, 3):
					tl.apply(m)
					var e := tl.log.mistakes().back() as Dictionary
					var line := tl.log.coach_line(e)
					var ref := tl.log.notes_ref(e)
					seen[ScCodes.verdict_name(int(e.verdict))] = true
					if line == "" or ref == "" or line.split(" ").size() > 20:
						H._bad(bad, "%s %s: '%s' / '%s'" % [id, ScCodes.verdict_name(int(e.verdict)), line, ref])
					tl.restore(snap)
				for m in tl.impossible_moves():
					var r := tl.apply(m)
					reasons[str(r.reason)] = true
					if not REASONS.has(str(r.reason)):
						H._bad(bad, "%s: onbekende klem %s" % [id, str(r.reason)])
					tl.restore(snap)
				tl.apply(tl.correct_move())
			carry = tl.output()
	t.eq(bad, [0], "elke misstap heeft een coachzin (≤ 20 woorden) en een notasverwijzing")
	for vn in ["WRONG_PAIR", "WRONG_LEAF", "MISSED_SWAP", "WRONG_SWAP", "WRONG_SEGMENT", "OVERSHOOT", "LONG_BITS",
			"WRONG_EDGE", "SHORT_MATCH", "WRONG_POS", "EARLY_STAMP", "WRONG_CARVE", "WRONG_ORDER", "WRONG_P", "WRONG_RANK",
			"WRONG_INDEX", "WRONG_DECREE"]:
		t.ok(seen.has(vn), "verdict %s komt voor in de foute zetten" % vn)
	for rs in ["not_leaf", "no_path", "no_word", "need_more", "same", "ancestor", "self", "no_pin", "out_of_window",
			"no_match", "no_stamp", "letter", "not_shorter", "taken", "range"]:
		t.ok(reasons.has(rs), "klem %s komt voor" % rs)
		t.ok(ScEventLog.bump_line(rs) != "Klem.", "klemzin voor " + rs)
	var lg := ScEventLog.new()
	for v in [V.NOT_PREFIX, V.LONG_CODE, V.UNREACHABLE, V.GARBLED, V.TWO_PIGEONS]:
		t.ok(lg.coach_line({"verdict": v, "data": {}}) != "", "coachzin " + ScCodes.verdict_name(v))


func _layout(t) -> void:
	t.section("ScTreeLayout")
	for tr in [ScReference.p90_tree(), ScReference.adaptive_encode("voordeel").tree,
			ScReference.huffman(ScReference.freqs_in_order("zaken_nemen_geen_keer")).tree]:
		var r: Dictionary = (tr as ScTree).render()
		var pos := ScTreeLayout.layout(r, 1000.0, 600.0)
		t.eq(pos.size(), (r.nodes as Array).size(), "elke top een positie")
		var inside := true
		for id in pos:
			var p: Vector2 = pos[id]
			inside = inside and p.x >= 0.0 and p.x <= 1000.0 and p.y >= 0.0 and p.y <= 600.0
		t.ok(inside, "binnen het kader")
		var lv := (tr as ScTree).leaves()
		var incr := true
		for q in lv.size() - 1:
			incr = incr and (pos[lv[q]] as Vector2).x < (pos[lv[q + 1]] as Vector2).x
		t.ok(incr, "bladeren van links naar rechts")
		var down := true
		for nd in r.nodes:
			if int(nd.p) >= 0:
				down = down and (pos[int(nd.p)] as Vector2).y < (pos[int(nd.id)] as Vector2).y
		t.ok(down, "ouder boven kind")


func _leveldata(t) -> void:
	t.section("leveldata")
	for id in ScLevels.ids():
		var s := ScLevels.get_spec(id)
		t.ok(s.title != "" and s.notes_ref != "" and s.intro != "", id + ": titel, verwijzing, intro")
		t.ok(s.intro.split(" ").size() <= 12, id + ": Zeno ≤ 12 woorden: " + s.intro)
		t.eq(s.stars.size(), 3, id + ": drie sterren")
		t.ok(s.stages.size() >= 1 and s.stages.size() <= 4, id + ": 1..4 stages")
		for st in s.stages:
			t.ok(ScCodes.tool_of(str(st.tool)) >= 0, id + ": werktuig " + str(st.tool))
		t.ok(str(s.story.get("house", "")) != "", id + ": huis")
		t.eq(JSON.stringify(ScLevels.get_spec(id).to_dict()), JSON.stringify(s.to_dict()), id + ": deterministisch")
	t.eq(ScLevels.get_spec("1-1").ghosts, {"plain": 72, "fixed": 27}, "geesten 1-1")
	t.eq(ScLevels.get_spec("0-2").ghosts.fixed, 42, "vaste lengte 0-2")
	t.eq(ScLevels.get_spec("3-4").ghosts.huffman, 53, "3-4: Huffman 53")
	t.eq(ScLevels.get_spec("4-6").optimum.search, 22, "4-6: zoekwerk 22")
	t.eq(ScLevels.get_spec("1-5").optimum.search, 12, "1-5: zoekwerk 12")
	t.ok(ScLevels.get_spec("bestaat-niet") == null, "onbekend id → null")


func _bots(t) -> void:
	t.section("bots: perfect ≥ elke foutmodus (alle P0-levels)")
	var bad := [0]
	var mist := 0
	for id in ScLevels.ids():
		if ScLevels.priority_of(id) != "P0":
			continue
		var perfect := ScLevelBot.new("").play(ScLevels.get_spec(id))
		var again := ScLevelBot.new("").play(ScLevels.get_spec(id))
		if int(perfect.points) != int(again.points) or JSON.stringify(perfect.readings) != JSON.stringify(again.readings):
			H._bad(bad, id + ": niet deterministisch")
		for mode in ["first", "every", "random"]:
			for sd in [1, 2]:
				var r := ScLevelBot.new(mode, sd).play(ScLevels.get_spec(id))
				if r.is_empty():
					H._bad(bad, "%s %s: eindigt niet" % [id, mode])
					continue
				if int(r.points) > int(perfect.points) or int(r.n_stars) > int(perfect.n_stars):
					H._bad(bad, "%s %s: %d > %d" % [id, mode, int(r.points), int(perfect.points)])
				if not (r.mistakes as Array).is_empty():
					mist += 1
					if int(r.n_stars) >= 2:
						H._bad(bad, "%s %s: misstap maar ★★" % [id, mode])
	t.eq(bad, [0], "perfect spel ≥ elke foutmodus, deterministisch")
	t.ok(mist > 40, "foutmodi maken echt misstappen (%d runs)" % mist)
