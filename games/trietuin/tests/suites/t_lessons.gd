extends RefCounted
## Leerpad (scripts/game/tt_lessons.gd, design/LEARNING_PATH.md): elke les (Kijk en Samen) speelt uit met het orakel;
## de verteltekst, de tips en de voorspelvragen zijn consistent met correct_move() en met het model ná de stap;
## Samen-foutuitleg bestaat voor de foute zetten; Check-vragen (25 nieuwe voorbeelden per deel) hebben één juist
## antwoord dat een onafhankelijke referentie (TtReference / naïef rekenen) bevestigt; voortgang, badges en de
## verplichte volgorde vóór elk level.

const NT := TtNode.Type
const CK := TtCodes.CardKind


func run(t) -> void:
	_structure(t)
	_play(t)
	_checks(t)
	_progress(t)


func _structure(t) -> void:
	t.section("leerpad: structuur")
	var ids := TtLessons.ids()
	t.ok(ids.size() >= 14, "%d delen" % ids.size())
	var order: Array = Array(TtLevels.IDS)
	var last := -1
	for p in TtLessons.all_parts():
		t.ok(str(p.rule) != "" and str(p.title) != "" and str(p.page) != "", "%s: regel/titel/pagina" % p.id)
		var gate := order.find(str(p.levels[0]))
		t.ok(gate >= 0, "%s: Zelf-level %s bestaat" % [p.id, p.levels[0]])
		t.ok(gate >= last, "%s: volgorde volgt de levels" % p.id)
		last = gate
		for ph in ["kijk", "samen"]:
			var s := TtLessons.spec(p.id, ph)
			t.ok(s != null and s.cards.size() > 0, "%s/%s: spec met kaarten" % [p.id, ph])
	# elk level met een nieuwe mechaniek heeft vóór zich een deel (niets gevraagd dat niet getoond is)
	for lv in ["1-1", "1-2", "2-1", "2-3", "3-1", "3-2", "4-1", "4-2", "4-3", "4-5", "5-1"]:
		t.ok(not TtLessons.parts_for_level(lv).is_empty(), "level %s heeft een leerpaddeel" % lv)
	for lv in TtLevels.IDS:
		t.ok(not TtLessons.report_parts(lv).is_empty(), "level %s heeft Check-vragen" % lv)


## Speelt een les uit met het orakel. -> {model, steps, asks: {q: aantal gesteld}}
func _run_lesson(t, id: String, ph: String) -> Dictionary:
	var cfg := TtLessons.cfg(id, ph)
	var spec := TtLessons.spec(id, ph)
	var m := TtLevels.make_model(spec)
	var from_it := int(cfg.get("from_it", 0))
	var until_it := int(cfg.get("until_it", 0))
	var counts := {}
	var asked := {}
	var steps := 0
	var tag := "%s/%s" % [id, ph]
	var stop := false
	for c in TtLevels.make_cards(spec):
		if stop:
			break
		m.begin(c)
		var g := 0
		while m.card != null and g < 500:
			g += 1
			var mv := m.correct_move()
			if str(mv.get("act", "none")) == "none":
				break
			if m is TtUkkonen:
				if from_it > 0 and (m as TtUkkonen).it < from_it:
					m.apply(mv)
					continue
				if until_it > 0 and (m as TtUkkonen).it > until_it:
					stop = true
					break
			var act := str(mv.act)
			counts[act] = int(counts.get(act, 0)) + 1
			steps += 1
			var n := TtLessons.narrate(m, mv)
			if not t.ok(str(n.what) != "" and str(n.why) != "" and not str(n.what).contains("%") and not str(n.why).contains("%"),
					"%s: verteltekst voor %s" % [tag, act]):
				return {}
			if steps <= 2:
				t.ok(TtLessons.state_line(m) != "", "%s: toestand" % tag)
			if int(counts[act]) == 1:
				t.ok(TtLessons.tip(m, mv) != "", "%s: tip voor %s" % [tag, act])
			# voorspelvragen: juist antwoord = wat het orakel doet
			var qs: Array = []
			for a in cfg.get("ask", []):
				if str(a.on) == act and int(a.nth) == int(counts[act]):
					qs.append(str(a.q))
			var before := m.snapshot()
			var sap0 := m.sap_used()
			for qk in qs:
				var q := TtLessons.predict(m, qk, mv)
				if not t.ok(not q.is_empty() and (q.correct as Array).size() == 1, "%s: voorspelvraag %s past" % [tag, qk]):
					continue
				asked[qk] = true
				t.ok((q.options as Array).size() >= 2, "%s: %s heeft ≥ 2 opties" % [tag, qk])
				_check_predict(t, tag, qk, m, mv, str(q.options[int(q.correct[0])]))
			# Samen: elke foute zet heeft een uitleg (op een kopie van het model)
			if ph == "samen" and int(counts[act]) <= 2:
				for wm in m.wrong_moves().slice(0, 2):
					var tr := TtLevels.make_model(spec)
					tr.restore(before)
					if tr is TtTernary:
						(tr as TtTernary).word_order = (m as TtTernary).word_order
					var n0 := tr.log.entries.size()
					var r := tr.apply(wm)
					if bool(r.get("ok", false)) and int(r.verdict) == TtCodes.Verdict.OK:
						continue
					var e: Dictionary = tr.log.entries[-1] if tr.log.entries.size() > n0 else {}
					t.ok(TtLessons.explain_wrong(tr, e, mv) != "", "%s: uitleg bij foute %s" % [tag, str(wm.get("act", ""))])
			var res := m.apply(mv)
			if not t.ok(bool(res.get("ok", false)), "%s: orakelzet %s aanvaard" % [tag, str(mv)]):
				return {}
			for qk in qs:
				_check_after(t, tag, qk, m, mv, before, sap0)
		t.ok(m.card == null or stop, "%s: kaart %d eindigt" % [tag, c.id])
	t.eq(m.invariants().size(), 0, "%s: invarianten" % tag)
	for a in cfg.get("ask", []):
		t.ok(asked.has(str(a.q)), "%s: voorspelvraag %s wordt gesteld" % [tag, a.q])
	return {"model": m, "steps": steps}


## Juist antwoord van een voorspelvraag tegen de zet zelf.
func _check_predict(t, tag: String, qk: String, m: TtTreeModel, mv: Dictionary, ans: String) -> void:
	var c := m.cursor()
	match qk:
		"letter":
			t.eq(ans, str(mv.letter), "%s: letter = s_d" % tag)
			t.eq(ans, str(c.word)[int(c.depth)], "%s: letter = woord[d]" % tag)
		"answer":
			t.eq(ans.begins_with("Ja"), m.node(int(c.leaf)).label == str(c.word), "%s: gevonden ⇔ label = woord" % tag)
		"j":
			var l := str(c.label)
			var w := str(c.word)
			var j := 0 if m.kind == TtCodes.Kind.PATRICIA else int(c.depth)
			while j < mini(l.length(), w.length()) and l[j] == w[j]:
				j += 1
			t.eq(int(ans), j, "%s: j = eerste verschil (naïef)" % tag)
		"tops":
			t.eq(int(ans), int(mv.j) - int(c.depth) + 1, "%s: j − d + 1" % tag)
		"cut":
			t.eq(ans.trim_prefix("onder "), TtLessons._u(TtLessons._pstr(m, m.node(int(mv.node)).parent)), "%s: knip onder de ouder" % tag)
		"pos":
			t.eq(int(ans), int(c.next) + int(c.skip), "%s: next + skip" % tag)
		"dir":
			var dmap := {"kleiner (links)": "lo", "gelijk (midden)": "eq", "groter (rechts)": "hi"}
			t.eq(str(dmap.get(ans, "")), str(mv.dir), "%s: richting" % tag)
		"attach":
			var sm := m as TtSuffixTree
			var suf := sm.text.substr(int(c.j))
			# naïef: langste prefix van σ_j dat al een prefix is van een eerder suffix
			var best := 0
			for k in int(c.j):
				var o := sm.text.substr(k)
				var L := 0
				while L < mini(o.length(), suf.length()) and o[L] == suf[L]:
					L += 1
				best = maxi(best, L)
			t.eq(ans, TtLessons._u(suf.substr(0, best)), "%s: afwijkpunt (naïef)" % tag)
		"b":
			t.eq(int(ans), (m as TtSuffixTree).display_pos(int(c.j) + int(c.l)), "%s: b = j + l" % tag)
		"where":
			var sm2 := m as TtSuffixTree
			var occ := TtReference.occurrences(sm2.text, str(c.z))
			t.ok(occ.has(int(ans) - sm2.pos_base), "%s: b − l_t is een voorkomen" % tag)
			t.eq(int(ans) - sm2.pos_base, occ[0], "%s: b − l_t = eerste voorkomen (Oef. 28a)" % tag)
		"count":
			t.eq(int(ans), TtReference.occurrences((m as TtSuffixTree).text, str(c.z)).size(), "%s: aantal voorkomens (naïef)" % tag)
		"owner":
			var sm3 := m as TtSuffixTree
			var names: Array = []
			for k in sm3.owner_names.size():
				var o: Dictionary = TtLessons.cfg(tag.get_slice("/", 0), tag.get_slice("/", 1)).owners_spec[k]
				var tx := sm3.text.substr(int(o.from), int(o.to) - int(o.from) + 1)
				if tx.contains(str(c.z)):
					names.append(sm3.owner_names[k])
			t.eq(ans, " en ".join(names), "%s: eigenaars (naïef)" % tag)
		"rule":
			var um := m as TtUkkonen
			var sig := um.text.substr(um.j - 1, um.it - um.j + 1)
			var present := um.text.substr(0, um.it - 1).contains(sig)
			t.eq(ans.begins_with("(a)"), present, "%s: stop ⇔ σ zit al in s_1…s_{i−1}" % tag)
		"hop":
			t.ok(ans.begins_with("Springen"), "%s: springen" % tag)
		"follow":
			var um2 := m as TtUkkonen
			t.eq(ans.begins_with("x − 1"), um2.p == um2.root, "%s: x − 1 ⇔ p = wortel" % tag)
		"link":
			var um3 := m as TtUkkonen
			var fr := um3.node_string(um3.pending)
			t.eq(ans, TtLessons._u(fr.substr(1)), "%s: link = zonder eerste letter" % tag)


## Na de stap: wat de vraag beloofde, is ook gebeurd.
func _check_after(t, tag: String, qk: String, m: TtTreeModel, mv: Dictionary, before: Dictionary, sap0: int) -> void:
	match qk:
		"tops":
			var tops := int(mv.j) - int(before.st.get("d", 0)) + 1
			t.eq(m.sap_used() - sap0, tops * m.alphabet.cost_size, "%s: sap stijgt met (j − d + 1)·|A|" % tag)
		"skip":
			var kid := -1
			for nd in before.nodes:
				if int(nd.get("parent", -2)) == int(mv.node):
					kid = int(nd.id)
			if kid >= 0 and m.nodes.has(kid) and m.node(kid).type == NT.INNER:
				var old_kid_skip := 0
				var old_top_skip := 0
				for nd in before.nodes:
					if int(nd.id) == kid:
						old_kid_skip = int(nd.get("skip", 0))
					if int(nd.id) == int(mv.node):
						old_top_skip = int(nd.get("skip", 0))
				t.eq(m.node(kid).skip, old_kid_skip + old_top_skip + 1, "%s: nieuwe skip" % tag)


func _play(t) -> void:
	t.section("leerpad: lessen spelen uit")
	for p in TtLessons.all_parts():
		for ph in ["kijk", "samen"]:
			var r := _run_lesson(t, p.id, ph)
			t.ok(not r.is_empty() and int(r.steps) >= 3, "%s/%s: les heeft stappen (%d)" % [p.id, ph, int(r.get("steps", 0))])
	# Kijk-voorbeelden uit de notas: eindbomen
	var fig14 := _run_lesson(t, "toevoegen", "kijk")
	t.ok(str(fig14.model.serialize()).contains("G{C[AAGCGA_] T[AAGTT_]}"), "toevoegen/kijk: Figuur 13 + AAGCGA_ = Figuur 14")
	var f15 := _run_lesson(t, "snoeien", "kijk")
	t.eq(f15.model.serialize(), TtLevels.F15P, "snoeien/kijk: Figuur 15 als Patricia trie")
	var f16 := _run_lesson(t, "ternary", "kijk")
	t.ok(str(f16.model.serialize()).begins_with("(G (C"), "ternary/kijk: Figuur 16 (G bovenaan, C links)")


func _checks(t) -> void:
	t.section("leerpad: Check-vragen (nieuw voorbeeld) kloppen met een referentie")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for p in TtLessons.all_parts():
		var n := 0
		for k in 25:
			var q := TtLessons.check_question(p.id, rng)
			if not t.ok(not q.is_empty(), "%s: check %d bestaat" % [p.id, k]):
				continue
			var opts: Array = q.options
			t.ok((q.correct as Array).size() == 1 and opts.size() >= 2, "%s: één juist antwoord, ≥ 2 opties" % p.id)
			var uniq := {}
			for o in opts:
				uniq[str(o)] = true
			t.eq(uniq.size(), opts.size(), "%s: opties verschillen" % p.id)
			t.ok(str(q.get("explain", "")) != "" and not (q.fig.rn as Array).is_empty(), "%s: uitleg + figuur" % p.id)
			if _verify(t, p.id, q, str(opts[int(q.correct[0])])):
				n += 1
		t.eq(n, 25, "%s: 25 Check-antwoorden onafhankelijk bevestigd" % p.id)


func _walk(d: Dictionary, w: String) -> Dictionary:
	var cur := d
	var dep := 0
	var path: Array = [d]
	while not cur.has("leaf"):
		var c := w[dep] if dep < w.length() else ""
		if not cur.kids.has(c):
			return {"end": "null", "depth": dep, "path": path}
		cur = cur.kids[c]
		path.append(cur)
		dep += 1
	return {"end": "leaf", "leaf": str(cur.leaf), "depth": dep, "path": path}


func _count_inner(d: Dictionary) -> int:
	if d.has("leaf"):
		return 0
	var n := 1
	for k in d.kids:
		n += _count_inner(d.kids[k])
	return n


## Onafhankelijke controle van het juiste antwoord. -> true als bevestigd.
func _verify(t, id: String, q: Dictionary, ans: String) -> bool:
	var d: Dictionary = q.get("data", {})
	var dna := TtAlphabet.dna()
	match id:
		"zoeken":
			var r := _walk(TtReference.trie_dict(d.words), str(d.w))
			var want := 0 if (r.end == "leaf" and r.leaf == str(d.w)) else (1 if r.end == "null" else 2)
			return t.eq(int(d.outcome), want, "zoeken: afloop (referentie)")
		"toevoegen":
			var r2 := _walk(TtReference.trie_dict(d.words), str(d.w))
			var l := str(r2.get("leaf", ""))
			var j := int(r2.depth)
			while j < mini(l.length(), str(d.w).length()) and l[j] == str(d.w)[j]:
				j += 1
			return t.eq(int(ans), j, "toevoegen: j (referentie)")
		"geheugen":
			var before := _count_inner(TtReference.trie_dict(d.words))
			var after := _count_inner(TtReference.trie_dict(d.words + [d.w]))
			return t.eq(int(ans), (after - before) * 5, "geheugen: nieuwe toppen × |A| (referentie)")
		"verwijderen":
			var r3 := _walk(TtReference.trie_dict(d.words), str(d.w))
			var last := 0
			for i in (r3.path as Array).size() - 1:
				var nd: Dictionary = r3.path[i]
				if nd.has("kids") and (nd.kids as Dictionary).size() >= 2:
					last = i
			return t.eq(ans, "onder " + TtLessons._u(str(d.w).substr(0, last)), "verwijderen: laatste top met ≥ 2 kinderen (referentie)")
		"snoeien":
			return t.eq(int(ans), _count_inner(TtReference.patricia_dict(TtReference.trie_dict(d.words))), "snoeien: interne toppen (referentie)")
		"pzoeken":
			var z := TtReference.zoek_patricia(TtReference.patricia_dict(TtReference.trie_dict(d.words)), str(d.w))
			var ps: Array = []
			for x in z.reads:
				ps.append(str(x))
			return t.eq(ans, ", ".join(ps), "pzoeken: leesposities (referentie Algoritme 1)")
		"enten":
			var l2 := str(d.label)
			var j2 := 0
			while j2 < mini(l2.length(), str(d.w).length()) and l2[j2] == str(d.w)[j2]:
				j2 += 1
			var leaves := TtReference.trie_dict(d.words)
			t.ok(_has_leaf(leaves, l2), "enten: de vrucht bestaat")
			return t.eq(int(ans), j2, "enten: j vanaf 0 (naïef)")
		"ternary":
			var td := {}
			for w in d.words:
				td = TtReference.ternary_insert(td, str(w), dna)
			return t.eq(ans.split(" ").size(), TtReference.ternary_comparisons(td, str(d.w), dna), "ternary: aantal vergelijkingen (referentie)")
		"ttoevoegen":
			var a := TtReference.ternary_of(d.words, dna).count("(")
			var b := TtReference.ternary_of(d.words + [d.w], dna).count("(")
			return t.eq(int(ans), b - a, "ttoevoegen: nieuwe bollen (referentie)")
		"suffixboom", "labels":
			var tx := str(d.text)
			var j3 := int(d.j)
			var suf := tx.substr(j3)
			var best := 0
			for k in j3:
				var o := tx.substr(k)
				var L := 0
				while L < mini(o.length(), suf.length()) and o[L] == suf[L]:
					L += 1
				best = maxi(best, L)
			if id == "suffixboom":
				return t.eq(ans, TtLessons._u(suf.substr(0, best)), "suffixboom: afwijkpunt (naïef)")
			return t.eq(ans, "(%d,%d)" % [j3 + best, tx.length() - 1], "labels: (j + l, n) (naïef)")
		"szoeken":
			var occ := TtReference.occurrences(str(d.text), str(d.z))
			if str(d.kind) == "count":
				return t.eq(int(ans), occ.size(), "szoeken: aantal (naïef)")
			return t.eq(int(ans), occ[0], "szoeken: b − l_t = eerste voorkomen (naïef)")
		"veralg":
			var in1 := (str(d.t1) + "1").contains(str(d.z))
			var in2 := (str(d.t2) + "2").contains(str(d.z))
			var want2 := "Mol en Merel" if in1 and in2 else ("Mol" if in1 else "Merel")
			return t.eq(ans, want2, "veralg: eigenaars (naïef)")
		"ukk_regels":
			var tx2 := str(d.text)
			var sig := tx2.substr(int(d.j) - 1, int(d.it) - int(d.j) + 1)
			return t.eq(ans.begins_with("(a)"), tx2.substr(0, int(d.it) - 1).contains(sig), "ukk_regels: stop ⇔ al deelstring (naïef)")
		"ukk_wijzer":
			return t.eq(ans.begins_with("x̄ = x − 1"), bool(d.root), "ukk_wijzer: x − 1 ⇔ p = wortel")
		"ukk_links":
			return t.eq(ans, TtLessons._u(str(d.from).substr(1)), "ukk_links: zonder eerste letter")
	return t.ok(false, "%s: geen controle" % id)


func _has_leaf(d: Dictionary, l: String) -> bool:
	if d.has("leaf"):
		return str(d.leaf) == l
	for k in d.kids:
		if _has_leaf(d.kids[k], l):
			return true
	return false


func _progress(t) -> void:
	t.section("leerpad: voortgang, badges en verplichte volgorde")
	var old := TtSave.path
	TtSave.path = "user://trietuin_lessons_test_save.json"
	TtLessons.reset_progress()
	var p11 := TtLessons.pending_for_level("1-1")
	t.eq(p11.size(), 4, "1-1: zoeken + toevoegen, Kijk en Samen")
	t.eq(str(p11[0].part) + "/" + str(p11[0].phase), "zoeken/kijk", "1-1: eerst de demo van zoeken")
	var p51 := TtLessons.pending_for_level("5-1")
	t.eq(p51.size(), TtLessons.all_parts().size() * 2, "5-1 zonder voortgang: alle delen vooraf")
	TtLessons.mark("zoeken", "kijk")
	t.eq(TtLessons.level("zoeken"), 1, "badge amber na Kijk")
	t.eq(TtLessons.pending_for_level("1-1").size(), 3, "Kijk gedaan: enkel Samen van zoeken nog")
	TtLessons.mark("zoeken", "samen")
	t.eq(TtLessons.level("zoeken"), 2, "badge blauw na Samen")
	TtLessons.mark("zoeken", "check")
	t.eq(TtLessons.level("zoeken"), 3, "badge groen (begrepen) na Check")
	t.eq(TtLessons.pending_for_level("1-1").size(), 2, "zoeken klaar: enkel toevoegen nog")
	t.eq(TtLessons.pending_for_level("endless").size(), 2, "vrije tuin vraagt toevoegen")
	TtLessons.reset_progress()
	t.eq(TtLessons.level("zoeken"), 0, "reset wist de voortgang")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TtSave.path))
	TtSave.path = old
