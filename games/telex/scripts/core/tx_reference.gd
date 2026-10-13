class_name TxReference
## Onafhankelijke referentie-implementaties van Algoritme 2–8 en Definitie 11/13/14/15 (GDD §8.3), letterlijk
## volgens de pseudocode van de lesnotas AD3 2026 §3.4–3.5. Statisch en puur: bron voor orakel, waarheid,
## geesten en tests. Posities zijn 0-gebaseerd; editeertabellen gebruiken lengtes als index (d[i][j]).

const EOL := TxCodes.EOL
const INF := TxCodes.INF


# ------------------------------------------------------------------ Algoritme 2 (brute kracht)

## {cmp, hits, trace:[{start, res, cmp}], rewind, alignments}
## res = eerste mismatchpositie in z, of m bij een treffer. rewind = Σ max(0, laatst vergeleken − volgende start).
## joker: dat teken in z matcht elk teken van t (Oef. 33).
static func brute(z: String, t: String, find_all: bool, joker := "") -> Dictionary:
	var m := z.length()
	var n := t.length()
	var trace: Array = []
	var hits: Array[int] = []
	var cmp := 0
	for i in range(0, n - m + 1):
		var c := 0
		var res := m
		for k in m:
			c += 1
			if not _eq(z[k], t[i + k], joker):
				res = k
				break
		trace.append({"start": i, "res": res, "cmp": c})
		cmp += c
		if res == m:
			hits.append(i)
			if not find_all:
				break
	var rew := 0
	for a in range(trace.size() - 1):
		var last: int = int(trace[a].start) + (int(trace[a].res) if int(trace[a].res) < m else m - 1)
		var first: int = int(trace[a + 1].start)
		if last > first:
			rew += last - first
	return {"cmp": cmp, "hits": hits, "trace": trace, "rewind": rew, "alignments": trace.size()}


static func _eq(zc: String, tc: String, joker: String) -> bool:
	return zc == tc or (joker != "" and zc == joker)


## Echte voorkomens van z in t (naïef, eventueel met joker): beginposities.
static func occurrences(z: String, t: String, joker := "") -> Array[int]:
	var out: Array[int] = []
	var m := z.length()
	for i in range(0, t.length() - m + 1):
		var ok := true
		for k in m:
			if not _eq(z[k], t[i + k], joker):
				ok = false
				break
		if ok:
			out.append(i)
	return out


# ------------------------------------------------------------------ Algoritme 3 (Rabin-Karp, bitstrings)

## h(s) = (Σ s_i 2^(m−1−i)) mod q
static func h(bits: String, q: int) -> int:
	var v := 0
	for c in bits:
		v = (2 * v + (1 if c == "1" else 0)) % q
	return v


## Waarde na elk bit (Horner, mod q).
static func horner_prefixes(bits: String, q: int) -> Array[int]:
	var out: Array[int] = []
	var v := 0
	for c in bits:
		v = (2 * v + (1 if c == "1" else 0)) % q
		out.append(v)
	return out


## 2^m mod q (het gewicht w).
static func weight(m: int, q: int) -> int:
	var v := 1 % q
	for _k in m:
		v = (2 * v) % q
	return v


static func ones(bits: String) -> int:
	return bits.count("1")


## {hz, w, hs (per verwerkt venster, rollend), calls:[{i, equal, cmp}], cmp, hits, false_hits, wheel_ops, windows}
## wheel_ops = m (w) + (m + #1(z)) + (m + #1(venster 0)) + Σ_i (1 + t[i−1] + t[i+m−1]) tot het laatste venster.
static func rk(z: String, t: String, q: int, find_all: bool) -> Dictionary:
	var m := z.length()
	var n := t.length()
	var hz := h(z, q)
	var w := weight(m, q)
	var hs: Array[int] = []
	var calls: Array = []
	var hits: Array[int] = []
	var false_hits: Array[int] = []
	var cmp := 0
	var ops := m + m + ones(z)
	var hv := 0
	for i in range(0, n - m + 1):
		if i == 0:
			hv = h(t.substr(0, m), q)
			ops += m + ones(t.substr(0, m))
		else:
			var outb := 1 if t[i - 1] == "1" else 0
			var inb := 1 if t[i + m - 1] == "1" else 0
			hv = posmod(2 * hv - outb * w + inb, q)
			ops += 1 + outb + inb
		hs.append(hv)
		if hv == hz:
			var c := 0
			var ok := true
			for k in m:
				c += 1
				if z[k] != t[i + k]:
					ok = false
					break
			calls.append({"i": i, "equal": ok, "cmp": c})
			cmp += c
			if ok:
				hits.append(i)
				if not find_all:
					break
			else:
				false_hits.append(i)
	return {"hz": hz, "w": w, "hs": hs, "calls": calls, "cmp": cmp, "hits": hits, "false_hits": false_hits,
		"wheel_ops": ops, "windows": hs.size()}


# ------------------------------------------------------------------ Knuth-Morris-Pratt

## Definitie 11: V[0] = 1; V[j] = min{s | 0<s<j en z[0..j−1−s] = z[s..j−1], of s = j}.
## extended: ook V[m] (Oef. 41, bindende beslissing 1 van de lead).
static func v_def(z: String, extended := true) -> Array[int]:
	var m := z.length()
	var v: Array[int] = [1]
	var top := m + (1 if extended else 0)
	for j in range(1, top):
		var best := j
		for s in range(1, j):
			if mesh(z, j, s):
				best = s
				break
		v.append(best)
	return v


## De "tanden": verschuiving s (≥ 1) na een mismatch op positie em past als s ≥ em of z[0..em−1−s] == z[s..em−1].
static func mesh(z: String, em: int, s: int) -> bool:
	if s < 1:
		return false
	if s >= em:
		return true
	for k in range(0, em - s):
		if z[k] != z[s + k]:
			return false
	return true


## Algoritme 4: vergelijk_strings. Voorbij het einde van t staat EOL (matcht niets). {em, cmp}
static func vergelijk_strings(z: String, t: String, start: int, gel: int) -> Dictionary:
	var c := 0
	var m := z.length()
	for i in range(gel, m):
		c += 1
		var tc := t[start + i] if start + i < t.length() else EOL
		if z[i] != tc:
			return {"em": i, "cmp": c}
	return {"em": m, "cmp": c}


## Algoritme 5 letterlijk: {v: Array[int] (lengte m+1, −1 = niet ingevuld), steps:[{start, gel, em, cmp, filled:[[pos,val]], shift}]}
static func bereken_v(z: String) -> Dictionary:
	var m := z.length()
	var v: Array[int] = []
	v.resize(m + 1)
	v.fill(-1)
	v[0] = 1
	if m >= 1:
		v[1] = 1
	var steps: Array = []
	var start := 1
	var gel := 0
	var guard := 0
	while start + gel < m - 1 and guard < 10000:
		guard += 1
		var r := vergelijk_strings(z, z, start, gel)
		var em: int = r.em
		var filled: Array = []
		if em == 0:
			v[start + 1] = start + 1
			filled.append([start + 1, start + 1])
		else:
			for i in range(gel + 1, em + 1):
				v[start + i] = start
				filled.append([start + i, start])
		var sh: int = v[em]
		steps.append({"start": start, "gel": gel, "em": em, "cmp": int(r.cmp), "filled": filled, "shift": sh})
		start += sh
		gel = 0 if em == 0 else em - sh
	return {"v": v, "steps": steps}


## Algoritme 4 (KMP). v moet lengte m+1 hebben bij find_all (V[m] na een treffer).
## {cmp, hits, trace:[{start, gel, em, cmp}], alignments}
static func kmp(z: String, t: String, v: Array, find_all: bool) -> Dictionary:
	var m := z.length()
	var n := t.length()
	var vv: Array = v
	if find_all and vv.size() < m + 1:
		vv = v_def(z, true)
	var start := 0
	var gel := 0
	var trace: Array = []
	var hits: Array[int] = []
	var cmp := 0
	while start <= n - m:
		var r := vergelijk_strings(z, t, start, gel)
		var em: int = r.em
		trace.append({"start": start, "gel": gel, "em": em, "cmp": int(r.cmp)})
		cmp += int(r.cmp)
		if em == m:
			hits.append(start)
			if not find_all:
				break
		var s: int = int(vv[em])
		start += s
		gel = 0 if em == 0 else em - s
	return {"cmp": cmp, "hits": hits, "trace": trace, "alignments": trace.size()}


# ------------------------------------------------------------------ Boyer-Moore-Horspool

## vul_VH: letter -> waarde voor letters van z[0..m−2]; alle andere tekens: m.
static func vul_vh(z: String) -> Dictionary:
	var m := z.length()
	var vh := {}
	for i in range(0, m - 1):
		vh[z[i]] = m - i - 1
	return vh


static func vh_of(vh: Dictionary, x: String, m: int) -> int:
	return int(vh.get(x, m))


## {cmp, hits, trace:[{i, start, ok, cmp, key, shift, mis_z}], vh, alignments}
static func bmh(z: String, t: String, find_all: bool) -> Dictionary:
	var m := z.length()
	var n := t.length()
	var vh := vul_vh(z)
	var i := m - 1
	var trace: Array = []
	var hits: Array[int] = []
	var cmp := 0
	while i < n:
		var c := 0
		var ok := true
		var mis := -1
		for k in m:
			c += 1
			if z[m - 1 - k] != t[i - k]:
				ok = false
				mis = m - 1 - k
				break
		var sh := vh_of(vh, t[i], m)
		trace.append({"i": i, "start": i - m + 1, "ok": ok, "cmp": c, "key": t[i], "shift": sh, "mis_z": mis})
		cmp += c
		if ok:
			hits.append(i - m + 1)
			if not find_all:
				break
		i += sh
	return {"cmp": cmp, "hits": hits, "trace": trace, "vh": vh, "alignments": trace.size()}


# ------------------------------------------------------------------ shift-AND (Definitie 13/14, Algoritme 6)

## C_x voor elke letter van z: letter -> Array[int] (lengte m).
static func c_vectors(z: String) -> Dictionary:
	var m := z.length()
	var c := {}
	for x in z:
		if c.has(x):
			continue
		var col: Array[int] = []
		for i in m:
			col.append(1 if z[i] == x else 0)
		c[x] = col
	return c


static func zeros(m: int) -> Array[int]:
	var a: Array[int] = []
	a.resize(m)
	a.fill(0)
	return a


## shift¹: bit i−1 naar i, nieuw bit 0 = 1 (p. 68).
static func shift1(col: Array) -> Array[int]:
	var out: Array[int] = [1]
	for i in range(0, col.size() - 1):
		out.append(int(col[i]))
	return out


static func and_cols(a: Array, b: Array) -> Array[int]:
	var out: Array[int] = []
	for i in a.size():
		out.append(int(a[i]) & int(b[i]))
	return out


static func or_cols(a: Array, b: Array) -> Array[int]:
	var out: Array[int] = []
	for i in a.size():
		out.append(int(a[i]) | int(b[i]))
	return out


static func unit(m: int) -> Array[int]:
	var e := zeros(m)
	if m > 0:
		e[0] = 1
	return e


## Algoritme 6 met "kolom −1" = nullen (p. 68), zonder te stoppen. {c, cols:Array (per j), hits:Array[int] (begin), ends}
static func shift_and(z: String, t: String) -> Dictionary:
	var m := z.length()
	var c := c_vectors(z)
	var zero := zeros(m)
	var col := zeros(m)
	var cols: Array = []
	var hits: Array[int] = []
	var ends: Array[int] = []
	for j in t.length():
		col = and_cols(shift1(col), c.get(t[j], zero))
		cols.append(col)
		if col[m - 1] == 1:
			hits.append(j - m + 1)
			ends.append(j)
	return {"c": c, "cols": cols, "hits": hits, "ends": ends}


## Eén kolomstap van M^0..M^k (p. 71) met een stekker voor de foutkabel.
## prev = kolommen j−1 (k+1 stuks), cx = C[t[j]]; plug ∈ PLUGS of "" (geen kabel). own_shift = false: de AND gebeurt
## op de ongeschoven kolom (NO_SHIFT).
static func mk_step(prev: Array, cx: Array, plugs: Array, own_shift := true) -> Array:
	var k1 := prev.size()
	var m: int = (prev[0] as Array).size()
	var cur: Array = []
	for l in k1:
		var base: Array = prev[l]
		if own_shift:
			base = shift1(prev[l])
		var own := and_cols(base, cx)
		if l == 0:
			cur.append(own)
			continue
		var src := str(plugs[l - 1]) if l - 1 < plugs.size() else "old_shift"
		var fault: Array
		match src:
			"old_shift":
				fault = shift1(prev[l - 1])
			"old":
				fault = (prev[l - 1] as Array).duplicate()
			"new_shift":
				fault = shift1(cur[l - 1])
			"new":
				fault = (cur[l - 1] as Array).duplicate()
			_:
				fault = zeros(m)
		cur.append(or_cols(or_cols(unit(m), fault), own))
	return cur


## M^0..M^k, start = "kolom −1" = nullen. {c, cols:[j][l] -> Array, ends_by_level:{l: Array[int]}}
static func shift_and_k(z: String, t: String, k: int, plug := "old_shift") -> Dictionary:
	var m := z.length()
	var c := c_vectors(z)
	var zero := zeros(m)
	var prev: Array = []
	for l in k + 1:
		prev.append(zeros(m))
	var plugs: Array = []
	for l in k:
		plugs.append(plug)
	var cols: Array = []
	var ends := {}
	for l in k + 1:
		var e: Array[int] = []
		ends[l] = e
	for j in t.length():
		var cur := mk_step(prev, c.get(t[j], zero), plugs)
		cols.append(cur)
		for l in k + 1:
			if int(cur[l][m - 1]) == 1:
				var arr: Array = ends[l]
				arr.append(j)
		prev = cur
	return {"c": c, "cols": cols, "ends_by_level": ends}


## Definitie 14 rechtstreeks: M^l[i][j] (0/1).
static func mk_def(z: String, t: String, l: int, i: int, j: int) -> int:
	if i > j:
		return 0
	var mis := 0
	for kk in i + 1:
		if z[kk] != t[j - i + kk]:
			mis += 1
	return 1 if mis <= l else 0


## Aantal mismatches van z tegen t[j−m+1..j] (INF als j < m−1 of j ≥ n).
static func mismatches_ending(z: String, t: String, j: int) -> int:
	var m := z.length()
	if j < m - 1 or j >= t.length():
		return INF
	var mis := 0
	for kk in m:
		if z[kk] != t[j - m + 1 + kk]:
			mis += 1
	return mis


# ------------------------------------------------------------------ editeerafstand (Algoritme 7 en 8)

static func _new_table(rows: int, cols: int) -> Array:
	var tab: Array = []
	for i in rows:
		var row: Array[int] = []
		row.resize(cols)
		row.fill(0)
		tab.append(row)
	return tab


## Algoritme 7: d[i][j] tussen prefix van lengte i van a en prefix van lengte j van b.
static func edit_table(a: String, b: String) -> Array:
	var n := a.length()
	var m := b.length()
	var d := _new_table(n + 1, m + 1)
	for i in n + 1:
		d[i][0] = i
	for j in m + 1:
		d[0][j] = j
	for i in range(1, n + 1):
		for j in range(1, m + 1):
			var w := 0 if a[i - 1] == b[j - 1] else 1
			d[i][j] = mini(d[i - 1][j - 1] + w, mini(d[i - 1][j] + 1, d[i][j - 1] + 1))
	return d


static func edit_distance(a: String, b: String) -> int:
	var d := edit_table(a, b)
	return int(d[a.length()][b.length()])


## Algoritme 8: D[i][j] = min over l van d(z[0..i−1], t[l..j−1]); D[i][0] = i, D[0][j] = 0.
static func approx_table(z: String, t: String) -> Array:
	var mz := z.length()
	var n := t.length()
	var d := _new_table(mz + 1, n + 1)
	for i in mz + 1:
		d[i][0] = i
	for j in n + 1:
		d[0][j] = 0
	for i in range(1, mz + 1):
		for j in range(1, n + 1):
			var w := 0 if z[i - 1] == t[j - 1] else 1
			d[i][j] = mini(d[i - 1][j - 1] + w, mini(d[i - 1][j] + 1, d[i][j - 1] + 1))
	return d


## {best, end_cols:Array[int]} (kleinste waarde in de laatste rij en de kolommen waar ze staat).
static func approx_best(z: String, t: String) -> Dictionary:
	var d := approx_table(z, t)
	var row: Array = d[z.length()]
	var best := INF
	for j in row.size():
		best = mini(best, int(row[j]))
	var ends: Array[int] = []
	for j in row.size():
		if int(row[j]) == best:
			ends.append(j)
	return {"best": best, "end_cols": ends}


## Voorganger van (i, j) via dir.
static func pred(dir: String, i: int, j: int) -> Vector2i:
	match dir:
		"diag":
			return Vector2i(i - 1, j - 1)
		"up":
			return Vector2i(i - 1, j)
		"left":
			return Vector2i(i, j - 1)
	return Vector2i(-1, -1)


## Kost van de stap (i, j) via dir: diag 0/1 (wisselkost), up/left 1.
static func step_cost(dir: String, a: String, b: String, i: int, j: int) -> int:
	if dir == "diag":
		return 0 if a[i - 1] == b[j - 1] else 1
	return 1


## Dragende ingangen van cel (i, j): "diag", "up", "left" waarvoor tab[i][j] == tab[pred] + kost.
static func arrows(tab: Array, a: String, b: String, i: int, j: int) -> PackedStringArray:
	var out := PackedStringArray()
	for dir in ["diag", "up", "left"]:
		var p := pred(dir, i, j)
		if p.x < 0 or p.y < 0:
			continue
		if int(tab[i][j]) == int(tab[p.x][p.y]) + step_cost(dir, a, b, i, j):
			out.append(dir)
	return out


## Alle stroomvoerende paden van (i, j) terug naar (0,0) (Algoritme 7) of naar rij 0 (stop_row0, Algoritme 8).
## Elk pad = [{dir, i, j}] in voorwaartse volgorde (van de rand naar (i, j)); (i, j) = de cel die de stap verlaat
## in terugwaartse richting.
static func all_paths(tab: Array, a: String, b: String, i: int, j: int, stop_row0: bool) -> Array:
	if i == 0 and (stop_row0 or j == 0):
		return [[]]
	var out: Array = []
	for dir in arrows(tab, a, b, i, j):
		var p := pred(dir, i, j)
		for sub in all_paths(tab, a, b, p.x, p.y, stop_row0):
			var path: Array = (sub as Array).duplicate()
			path.append({"dir": dir, "i": i, "j": j})
			out.append(path)
	return out


## Beginkolom van een Algoritme 8-pad (de kolom waar het de rail op rij 0 verlaat).
static func path_start_col(path: Array) -> int:
	if path.is_empty():
		return 0
	var first: Dictionary = path[0]
	var p := pred(str(first.dir), int(first.i), int(first.j))
	return p.y


## Bewerkingen van een pad in stijgende volgorde (Lemma 17), posities in de string van dat moment (GDD §5.8).
## [{op:"vervang"|"verwijder"|"voegtoe", pos, from, to}]. start_col: beginkolom bij Algoritme 8 (b = de hele tekst).
static func ops_of_path(path: Array, a: String, b: String, start_col := 0) -> Array:
	var ops: Array = []
	for st in path:
		var dir := str(st.dir)
		var i := int(st.i)
		var j := int(st.j)
		var jr := j - start_col
		match dir:
			"diag":
				if a[i - 1] != b[j - 1]:
					ops.append({"op": "vervang", "pos": jr - 1, "from": a[i - 1], "to": b[j - 1]})
			"up":
				ops.append({"op": "verwijder", "pos": jr, "from": a[i - 1], "to": ""})
			"left":
				ops.append({"op": "voegtoe", "pos": jr - 1, "from": "", "to": b[j - 1]})
	return ops


## Past een reeks bewerkingen toe op s (controle: geeft het doel terug).
static func apply_ops(s: String, ops: Array) -> String:
	var cur := s
	for o in ops:
		var pos := int(o.pos)
		match str(o.op):
			"vervang":
				cur = cur.substr(0, pos) + str(o.to) + cur.substr(pos + 1)
			"verwijder":
				cur = cur.substr(0, pos) + cur.substr(pos + 1)
			"voegtoe":
				cur = cur.substr(0, pos) + str(o.to) + cur.substr(pos)
	return cur


## Unieke sleutel van een bewerkingsreeks.
static func ops_key(ops: Array) -> String:
	var parts := PackedStringArray()
	for o in ops:
		parts.append("%s:%d:%s:%s" % [str(o.op), int(o.pos), str(o.from), str(o.to)])
	return "|".join(parts)


## Verschillende kortste bewerkingsreeksen van a naar b (Algoritme 7).
static func distinct_sequences(a: String, b: String) -> Array:
	var d := edit_table(a, b)
	var seen := {}
	var out: Array = []
	for p in all_paths(d, a, b, a.length(), b.length(), false):
		var ops := ops_of_path(p, a, b)
		var key := ops_key(ops)
		if not seen.has(key):
			seen[key] = true
			out.append(ops)
	return out


## Alle beste matches van z in t (Algoritme 8): [{start, end (laatste index), end_col, ops}], uniek per (start, end_col, ops).
static func approx_matches(z: String, t: String) -> Array:
	var d := approx_table(z, t)
	var best := approx_best(z, t)
	var out: Array = []
	var seen := {}
	for jc in best.end_cols:
		for p in all_paths(d, z, t, z.length(), int(jc), true):
			var st := path_start_col(p)
			var ops := ops_of_path(p, z, t, st)
			var key := "%d:%d:%s" % [st, int(jc), ops_key(ops)]
			if seen.has(key):
				continue
			seen[key] = true
			out.append({"start": st, "end": int(jc) - 1, "end_col": int(jc), "ops": ops})
	return out
