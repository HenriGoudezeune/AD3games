extends RefCounted
## Leerpad (games/scriptorium/design/LEARNING_PATH.md): elke les headless uitgespeeld zoals de coach dat doet
## (ScLessons.kijk_group / narrate_group / predict / tip / accepts / explain_wrong), de voorspelantwoorden van het
## leerpad nagerekend, foute zetten geweigerd met uitleg, Check-vragen (30 nieuwe voorbeelden per deel) nagerekend met
## een eigen, onafhankelijke berekening, en voortgang/wachtrij (eerste keer verplicht).

const PH := ScCodes.Phase

## Voorspelantwoorden zoals in LEARNING_PATH.md: "deel/fase#n" → tekst van het (eerste) juiste antwoord.
const EXPECT := {
	"prefix_lezen/kijk#1": "u (010)", "prefix_lezen/samen#1": "o (00)",
	"prefix_def/kijk#1": "4", "prefix_def/samen#1": "6",
	"duiventil/kijk#1": "7", "duiventil/samen#1": "waar",
	"huffman/kijk#2": "22", "huffman/samen#2": "16",
	"planken/kijk#1": "plank B en plank B", "planken/samen#1": "plank A en plank B",
	"fgk_klim/kijk#1": "wissel met r[1,4]", "fgk_klim/samen#1": "wissel met e[2,7]",
	"fgk_nieuw/kijk#1": "nng: 0 + de letter ruw",
	"fgk_ouder/kijk#1": "niet wisselen (t′ is de ouder)", "fgk_ouder/samen#1": "niet wisselen (t′ is de ouder)",
	"arit_interval/kijk#1": "[0,34; 0,83)", "arit_interval/samen#1": "[0,62; 0,7)",
	"arit_bits/kijk#1": "1 (stap)", "arit_bits/samen#1": "0 (blijf)",
	"arit_lezen/kijk#1": "vak z", "arit_lezen/samen#1": "vak c",
	"lz77_zend/kijk#1": "(1, 3, EOF)", "lz77_zend/samen#1": "(2, 3, s)",
	"lz77_lees/kijk#1": "aar (vanaf positie 1)", "lz77_lees/samen#1": "ka (vanaf positie 1)",
	"lz77_register/kijk#1": "(0, 4, o)", "lz77_register/samen#1": "(1, 3, a)",
	"lzw_zend/kijk#1": "verleng (w = an)", "lzw_zend/samen#1": "verleng (w = ba)",
	"lzw_lees/kijk#1": "258 = ana", "lzw_lees/samen#1": "258 = aba",
	"bwt_zend/kijk#1": "rij 1 (een␣loong)", "bwt_zend/samen#1": "rij 1 (anaanb)",
	"mtf/kijk#1": "7", "mtf/samen#1": "a (plaats 1)",
}

var _seen_answers := {}


func run(t) -> void:
	var old_path := ScSave.path
	ScSave.path = "user://scriptorium_test_lessons.json"
	ScSave.reset()
	t.section("leerpad: structuur")
	var ids := ScLessons.ids()
	t.eq(ids.size(), 20, "20 delen")
	var seen := {}
	for p in ScLessons.all_parts():
		t.ok(not seen.has(p.id), "uniek id %s" % p.id)
		seen[p.id] = true
		for k in ["title", "rule", "idea", "page", "levels", "kijk", "samen"]:
			t.ok(p.has(k), "%s heeft %s" % [p.id, k])
		for lv in p.levels:
			t.ok(ScLevels.has(str(lv)), "%s: level %s bestaat" % [p.id, lv])
	var last := -1
	for p in ScLessons.all_parts():
		var gi := Array(ScLevels.ORDER).find(str(p.levels[0]))
		t.ok(gi >= last, "%s: poort %s niet vóór de vorige" % [p.id, p.levels[0]])
		last = gi
	# elk level (behalve de Codex en Oefening 105) wordt door minstens één deel geoefend
	for id in ScLevels.ids():
		if id != "C" and id != "6-5":
			t.ok(not ScLessons.parts_of_level(id).is_empty(), "level %s heeft een leerpaddeel" % id)
	# elk werktuig van een level komt voor in een les met poort ≤ dat level (volgorde = opbouw)
	for id in ScLevels.ids():
		if id == "6-5":
			continue
		var tools := {}
		var li := Array(ScLevels.ORDER).find(id)
		for p in ScLessons.all_parts():
			if Array(ScLevels.ORDER).find(str(p.levels[0])) <= li:
				for ph in ["kijk", "samen"]:
					for st in p[ph].stages:
						tools[_tool_key(st)] = true
		for st in ScLevels.get_spec(id).stages:
			t.ok(tools.has(_tool_key(st)), "level %s: %s zat al in een les" % [id, _tool_key(st)])
	for id in ids:
		for ph in ["kijk", "samen"]:
			_play(t, id, ph)
	t.section("leerpad: voorspelantwoorden (LEARNING_PATH.md)")
	for k in EXPECT:
		t.eq(str(_seen_answers.get(k, "<geen vraag>")), str(EXPECT[k]), k)
	_checks(t)
	_progress(t)
	ScSave.reset()
	ScSave.path = old_path


static func _tool_key(st: Dictionary) -> String:
	var k := "%s/%s" % [str(st.get("tool", "")), str(st.get("side", "send"))]
	if str(st.get("tool", "")) == "code_board":
		k += "/" + str(st.get("mode", ""))
	if str(st.get("tool", "")) == "bindery":
		k += "/" + str(st.get("mode", "row"))
	if bool(st.get("register", false)):
		k += "/register"
	return k


## Speelt één les uit met de logica van de coach.
func _play(t, id: String, ph: String) -> void:
	t.section("les %s/%s" % [id, ph])
	var cfg := ScLessons.cfg(id, ph)
	var sp := ScLessons.spec(id, ph)
	t.ok(sp != null and not sp.stages.is_empty(), "spec")
	var dd := ScDirector.new()
	dd.start(sp)
	var count := {}
	var asked := 0
	var steps := 0
	var bad := 0
	var guard := 0
	while not dd.finished and guard < 400:
		guard += 1
		var tl: ScTool = dd.tool
		if cfg.has("until_phase") and tl.phase == int(cfg.until_phase):
			break
		var mv := dd.correct_move()
		if str(mv.get("act", "none")) == "none":
			break
		var group: Array = ScLessons.kijk_group(tl) if ph == "kijk" else [{"mv": mv, "t": ScLessons.copy(tl)}]
		if group.is_empty():
			t.ok(false, "lege stap")
			break
		for g in group:
			var act := ScLessons.act_key(g.t, g.mv)
			count[act] = int(count.get(act, 0)) + 1
			for a in cfg.get("ask", []):
				if str(a.on) == act and int(a.nth) == int(count[act]):
					var q := ScLessons.predict(g.t, str(a.q), g.mv)
					asked += 1
					if t.ok(not q.is_empty() and not (q.correct as Array).is_empty(), "%s/%s: vraag %s #%d" % [id, ph, act, count[act]]):
						_seen_answers["%s/%s#%d" % [id, ph, asked]] = str(q.options[int(q.correct[0])])
						var opts: Array = q.options
						var uniq := {}
						for o in opts:
							uniq[str(o)] = true
						t.eq(uniq.size(), opts.size(), "%s/%s: opties uniek %s" % [id, ph, str(opts)])
						t.ok(str(q.q) != "" and str(q.right) != "", "%s/%s: vraag + uitleg" % [id, ph])
		if ph == "kijk":
			var n := ScLessons.narrate_group(group)
			t.ok(str(n.what) != "" and str(n.why) != "", "%s/kijk: vertelling %s" % [id, str(group[0].mv)])
			t.ok(ScLessons.state(tl) != "" or tl is ScDovecote, "%s/kijk: toestand" % id)
			for g in group:
				var r := dd.apply(g.mv)
				if not bool(r.ok) or int(r.verdict) != ScCodes.Verdict.OK:
					bad += 1
				steps += 1
		else:
			t.ok(ScLessons.tip(tl, mv) != "", "%s/samen: tip" % id)
			# één foute zet per stap: geweigerd met uitleg
			var wr: Array = tl.wrong_moves()
			wr.append_array(tl.impossible_moves().slice(0, 1))
			for w in wr.slice(0, 2):
				var acc := ScLessons.accepts(tl, w)
				if not bool(acc.ok):
					t.ok(ScLessons.explain_wrong(tl, w, acc) != "", "%s/samen: foutuitleg bij %s" % [id, str(w)])
			var acc2 := ScLessons.accepts(tl, mv)
			t.ok(bool(acc2.ok), "%s/samen: orakelzet aanvaard %s" % [id, str(mv)])
			var r2 := dd.apply(mv)
			if not bool(r2.ok):
				bad += 1
			steps += 1
	t.ok(dd.finished or (cfg.has("until_phase") and dd.tool.phase == int(cfg.until_phase)), "%s/%s: les speelt tot het einde (%d stappen)" % [id, ph, steps])
	t.eq(bad, 0, "%s/%s: alle orakelzetten OK" % [id, ph])
	t.eq(asked, (cfg.get("ask", []) as Array).size(), "%s/%s: alle voorspelvragen gesteld" % [id, ph])
	if dd.finished and dd.tool != null:
		var st0: Dictionary = sp.stages[0]
		if st0.has("expect"):
			t.eq(dd.tool.copy(), str(st0.expect), "%s/%s: kopie" % [id, ph])


# ---------------------------------------------------------------- Check-vragen (onafhankelijk nagerekend)

func _checks(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for id in ScLessons.ids():
		t.section("check %s" % id)
		var bad := 0
		var bad_indep := 0
		var n_ind := 0
		for k in 30:
			var q := ScLessons.check_question(id, rng)
			if q.is_empty():
				bad += 1
				continue
			var opts: Array = q.options
			var uniq := {}
			for o in opts:
				uniq[str(o)] = true
			if uniq.size() != opts.size() or opts.size() < 2 or (q.correct as Array) != [0] or str(q.explain) == "" or str(q.q) == "":
				bad += 1
			var ind := _indep(id, q)
			if ind != "":
				n_ind += 1
			if ind != "" and ind != str(opts[0]):
				bad_indep += 1
				if bad_indep < 3:
					print("   indep %s: %s vs %s (%s)" % [id, ind, str(opts[0]), str(q.fig)])
			var sh := ScLessons.shuffled(q, rng)
			if str(sh.options[int(sh.correct[0])]) != str(opts[0]):
				bad += 1
		t.eq(bad, 0, "%s: 30 Check-vragen geldig" % id)
		t.eq(bad_indep, 0, "%s: antwoorden onafhankelijk nagerekend" % id)
		t.eq(n_ind, 30, "%s: elke Check-vraag nagerekend" % id)


## Eigen berekening van het antwoord uit de figuur ("" = niet onafhankelijk na te rekenen).
func _indep(id: String, q: Dictionary) -> String:
	var fig := str(q.fig)
	var lines := fig.split("\n")
	match id:
		"duiventil":
			var n := int(fig.get_slice("van ", 1).get_slice(" bits", 0))
			var s := 0
			for l in n:
				s += 1 << l
			return str(s)
		"prefix_lezen":
			var cd := _parse_code(lines[0].trim_prefix("code: "))
			var bits := lines[1].trim_prefix("strook: ")
			var out := ""
			var cur := ""
			for b in bits:
				cur += b
				for k in cd:
					if cd[k] == cur:
						out += k
						cur = ""
			return out
		"prefix_def":
			for o in q.options:
				var cd2 := _parse_code(str(o))
				var ok := true
				for a in cd2:
					for b in cd2:
						if a != b and str(cd2[b]).begins_with(str(cd2[a])):
							ok = false
				if ok:
					return str(o)
			return "?"
		"huffman":
			var ws: Array = []
			for part in fig.split(", "):
				ws.append(int(part.get_slice("= ", 1)))
			var tot := 0
			while ws.size() > 1:
				ws.sort()
				var z: int = ws[0] + ws[1]
				tot += z
				ws = ws.slice(2)
				ws.append(z)
			return str(tot)
		"planken":
			var ws2: Array = []
			var re2 := RegEx.create_from_string(" (\\d+)")
			for m in re2.search_all(fig):
				ws2.append(int(m.get_string(1)))
			ws2.sort()
			return "%d en %d" % [ws2[0], ws2[1]]
		"fgk_klim", "fgk_ouder":
			var rows := {}
			for l in lines.slice(1):
				var cols := l.split(" ", false)
				if cols.size() >= 4 and cols[0].is_valid_int():
					rows[int(cols[0])] = {"w": int(cols[1]), "par": cols[cols.size() - 1]}
			var nr := int(str(q.q).get_slice("(nummer ", 1).get_slice(")", 0))
			var best := nr
			for k4 in rows:
				if int(rows[k4].w) == int(rows[nr].w) and int(k4) > best:
					best = int(k4)
			if best == nr or str(best) == str(rows[nr].par):
				return "niet wisselen"
			return "wissel met nummer %d" % best
		"mtf":
			var lst: Array = []
			for x in lines[0].trim_prefix("lijst: (").trim_suffix(")").split(","):
				lst.append(x)
			var out2 := PackedStringArray()
			for c in lines[1].trim_prefix("tekst: "):
				var k := lst.find(c)
				out2.append(str(k))
				lst.remove_at(k)
				lst.insert(0, c)
			return " ".join(out2)
		"bwt_zend":
			var s2 := lines[0].trim_prefix("tekst: ")
			var rots: Array = []
			for i in s2.length():
				rots.append(s2.substr(i) + s2.substr(0, i))
			var srt := rots.duplicate()
			srt.sort()
			var c := ""
			for r in srt:
				c += str(r)[s2.length() - 1]
			return "(%d, %s)" % [srt.find(rots[1]), c]
		"bwt_terug":
			var p := int(fig.get_slice("p = ", 1).get_slice(",", 0))
			var cc := fig.get_slice("c = ", 1)
			# alle rotaties van de kandidaten: de tekst waarvan de BWT (p, c) is
			for o in q.options:
				var s3 := str(o)
				var rots2: Array = []
				for i in s3.length():
					rots2.append(s3.substr(i) + s3.substr(0, i))
				var srt2 := rots2.duplicate()
				srt2.sort()
				var c2 := ""
				for r in srt2:
					c2 += str(r)[s3.length() - 1]
				if c2 == cc and srt2.find(rots2[1]) == p:
					return s3
			return "?"
		"lzw_zend":
			var s4 := lines[0].trim_prefix("tekst: ")
			var dict := {"a": 97, "b": 98}
			var nx := 256
			var w := ""
			var out3 := PackedStringArray()
			for k2 in s4:
				if dict.has(w + k2):
					w += k2
				else:
					out3.append(str(dict[w]))
					dict[w + k2] = nx
					nx += 1
					w = k2
			out3.append(str(dict[w]))
			return " ".join(out3)
		"lzw_lees":
			var cds := lines[0].trim_prefix("codes: ").split(" ")
			var words := {97: "a", 98: "b"}
			var nx2 := 256
			var w2 := str(words[int(cds[0])])
			var out4 := w2
			for i in range(1, cds.size()):
				var cdi := int(cds[i])
				var nw: String = words[cdi] if words.has(cdi) else w2 + w2[0]
				words[nx2] = w2 + nw[0]
				nx2 += 1
				out4 += nw
				w2 = nw
			return out4
		"lz77_lees":
			var G := int(lines[0].trim_prefix("G = "))
			var out5 := ""
			for tr in lines[1].split(" "):
				var parts := tr.trim_prefix("(").trim_suffix(")").split(",")
				var st := maxi(0, out5.length() - G)
				for k3 in int(parts[1]):
					out5 += out5[st + int(parts[0]) + k3]
				if parts[2] != "EOF":
					out5 += parts[2]
			return out5
		"arit_interval":
			var md := _parse_model(lines[0].trim_prefix("model: "))
			var tx := lines[1].trim_prefix("tekst: ")
			var lo := 0.0
			var ln := 1.0
			for c3 in tx:
				lo += float(md[c3][0]) * ln
				ln *= float(md[c3][1])
			# vergelijk als getallen (afronding)
			var o0 := str(q.options[0]).trim_prefix("[").trim_suffix(")").split("; ")
			if absf(float(o0[0].replace(",", ".")) - lo) < 1e-9 and absf(float(o0[1].replace(",", ".")) - (lo + ln)) < 1e-9:
				return str(q.options[0])
			return "?"
		"arit_bits":
			var ab := lines[0].get_slice("= [", 1).trim_suffix(")").split("; ")
			var low := float(ab[0].replace(",", "."))
			var up := float(ab[1].replace(",", "."))
			if low == 0.0:
				return "0"
			var g := 0.0
			var nxt := 0.5
			var bits2 := ""
			while bits2.length() < 60:
				if g + nxt < up - 1e-12:
					bits2 += "1"
					g += nxt
					if g >= low - 1e-12:
						break
				else:
					bits2 += "0"
				nxt /= 2.0
			return bits2
		"arit_lezen":
			var md2 := _parse_model(lines[0].trim_prefix("model: "))
			var bits3 := lines[1].trim_prefix("bits: ").get_slice(" ", 0)
			var r := 0.0
			var f := 0.5
			for b in bits3:
				if b == "1":
					r += f
				f /= 2.0
			var lo2 := 0.0
			var ln2 := 1.0
			var out6 := ""
			for _k in 2:
				for sym in md2.keys():
					var a: float = lo2 + float(md2[sym][0]) * ln2
					var bnd: float = a + float(md2[sym][1]) * ln2
					if a <= r + 1e-12 and r < bnd - 1e-12:
						out6 += sym
						lo2 = a
						ln2 = bnd - a
						break
			return out6
		"lz77_zend", "lz77_register":
			# eigen brute-force LZ77: langste match die in het raam begint (bij gelijke lengte de meest linkse)
			var tx := lines[0].trim_prefix("tekst: ")
			var G2 := -1 if lines[1].contains("∞") else int(lines[1].trim_prefix("G = "))
			var outs: Array = []
			var k4 := 0
			while k4 < tx.length():
				var ws := 0 if G2 < 0 else maxi(0, k4 - G2)
				var bp := 0
				var bl := 0
				for p4 in range(ws, k4):
					var l4 := 0
					while k4 + l4 < tx.length() and tx[p4 + l4] == tx[k4 + l4]:
						l4 += 1
					if l4 > bl:
						bl = l4
						bp = p4 - ws
				var x4: String = tx[k4 + bl] if k4 + bl < tx.length() else "EOF"
				outs.append("(%d,%d,%s)" % [bp, bl, x4])
				k4 += bl + 1
			return " ".join(outs)
		"fgk_nieuw":
			# orakel (ScReference): de tokens van het laatste teken = verschil van de twee uitvoerstromen
			var pre := lines[lines.size() - 1].get_slice("boom na ", 1).trim_suffix(")")
			var c5 := str(q.q).get_slice("[b]", 1).get_slice("[/b]", 0)
			var full := ScReference.tokens_to_string(ScReference.adaptive_encode(pre + c5).tokens)
			var head := ScReference.tokens_to_string(ScReference.adaptive_encode(pre).tokens)
			return full.substr(head.length())
		"fgk_lezen":
			var strm := lines[0].trim_prefix("stroom: ")
			return str(ScReference.adaptive_decode(ScReference.tokens_from_string(strm)).text)
	return ""


static func _parse_code(s: String) -> Dictionary:
	var cd := {}
	for part in s.split(", "):
		cd[part.get_slice(" = ", 0)] = part.get_slice(" = ", 1)
	return cd


## "p(x) = 0,2, p(y) = 0,7, …" → {sym: [f, p]} in volgorde.
static func _parse_model(s: String) -> Dictionary:
	var out := {}
	var acc := 0.0
	var re := RegEx.create_from_string("p\\((.)\\) = ([0-9,]+)")
	for m in re.search_all(s):
		var p := float(m.get_string(2).replace(",", "."))
		out[m.get_string(1)] = [acc, p]
		acc += p
	return out


# ---------------------------------------------------------------- voortgang

func _progress(t) -> void:
	t.section("leerpad: voortgang en wachtrij")
	ScLessons.reset_progress()
	t.eq(ScLessons.level("huffman"), 0, "begin: niets")
	var pend := ScLessons.pending_for_level("1-1")
	t.eq(pend.size(), 8, "vóór 1-1: 4 delen × Kijk + Samen")
	t.eq(str(pend[0].part), "prefix_lezen", "eerst prefix_lezen")
	t.eq(str(pend[0].phase), "kijk", "eerst Kijk")
	ScLessons.mark("huffman", "kijk")
	t.eq(ScLessons.level("huffman"), 1, "demo bekeken")
	ScLessons.mark("huffman", "samen")
	t.eq(ScLessons.level("huffman"), 2, "samen geoefend")
	ScLessons.mark("huffman", "check")
	t.eq(ScLessons.level("huffman"), 3, "begrepen")
	for id in ["prefix_lezen", "prefix_def", "duiventil"]:
		ScLessons.mark(id, "kijk")
		ScLessons.mark(id, "samen")
	t.eq(ScLessons.pending_for_level("1-1").size(), 0, "na Samen: niets meer verplicht vóór 1-1")
	t.eq(ScLessons.pending_for_level("1-2").size(), 0, "1-2 oefent enkel huffman")
	t.eq(ScLessons.pending_for_level("1-5").size(), 2, "vóór 1-5: planken")
	t.eq(ScLessons.pending_for_level("C").size(), 0, "de Codex: geen les")
	t.eq(ScLessons.report_parts("3-1"), ["arit_interval", "arit_bits"], "Check na 3-1: de eerste twee nieuwe delen")
	t.eq(ScLessons.parts_for_level("6-1"), ["bwt_zend", "mtf"], "poort 6-1")
	ScLessons.reset_progress()
	t.eq(ScLessons.level("huffman"), 0, "reset_learning")
