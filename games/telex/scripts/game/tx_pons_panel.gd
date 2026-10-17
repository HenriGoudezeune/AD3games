class_name TxPonsPanel
extends TxPanel
## Ponsbank (GDD §3.3): de verschuivingstabel V[] ponsen.
##  - spiegel (Definitie 11, 3-2): per vakje j staat z[0..j−1] groen en op j een "?". Sleep de spookkopie tot de tanden
##    inklikken en pons die verschuiving (P/Enter). Een verschuiving die niet past, klemt.
##  - spiegelrit (Algoritme 5, 3-3/3-4): z loopt als tekst (met ⏎) onder een kopie van zichzelf; na elke stop pons je
##    de vakjes tot en met de mismatch (ponskop + draaiknop) en verschuif je.

var method := "def11"
var j := -1                   # PUNCH_CELL: vakje
var s_sel := 1                # spiegel: verschuiving / spiegelrit: verschuiving
var b_sel := 0                # spiegelrit: laatste vakje
var v_sel := 1                # spiegelrit: waarde (draaiknop)
var start := 1
var gel := 0
var em := -1
var a_from := 0
var hit := 0.0
var knob_ang := 0.0


func _setup() -> void:
	method = str(stage.get("method", "def11"))
	tape.stencils = []
	tape.labels = []
	tape.arc = {}
	tape.punch = {}
	tape.head_on = method == "alg5"
	tape.show_positions = true
	var km := mc as TxKmpTable
	tape.strip_vals = km.strip.duplicate()
	tape.strip_col = 0.0
	tape.strip_extra = false
	tape.strip_label = "V"
	tape.strip_dy = 0.0
	if method == "alg5":
		tape.setup_text(z + "⏎")
		tape.cell = 44.0
		tape.fsize = 44
		tape.add_stencil(z, 1.0)
	else:
		tape.setup_text(z)
		tape.add_stencil(z, 1.0)
	tape.follow = 0.0
	tape.follow_hi = float(m + 2)
	tape.scroll = 0.0
	tape.scroll_target = 0.0
	tape.stencil_drag.connect(_on_drag)
	tape.strip_clicked.connect(_on_strip)


func plate() -> Array:
	return ["MODEL  K-M-P  1977", "PONSBANK" + ("  ·  SPIEGELRIT" if method == "alg5" else "  ·  SPIEGEL")]


func fx(f: Dictionary) -> float:
	match str(f.fx):
		"needle":
			# spiegelnaald: posities zijn plaatsen in z (tekst), sjabloon = de kopie op start
			tape.states = {}
			if not tape.stencils.is_empty():
				tape.stencils[0].marks = {}
			return needle(f)
		"punch":
			var cells: Array = f.get("cells", [])
			hit = 1.0
			var tw := create_tween()
			tw.tween_property(self, "hit", 0.0, d(0.25))
			TxSnd.play("punch", -2.0)
			for c in cells:
				var jj := int(c.j)
				if jj < tape.strip_vals.size():
					tape.strip_vals[jj] = int(c.v)
				TxFx.punch_dots(con.fx_layer, tape.strip_pos(jj), 5)
			TxFx.punch(0.006)
			if not cells.is_empty():
				TxFx.floater(con.fx_layer, tape.strip_pos(int(cells[0].j)) + Vector2(0, -50), "V = %d" % int(cells[0].v), TxPal.MANILA, 22, 30, 0.6)
			return d(0.25)
		"stencil":
			return move_stencil(0, float(f.from), float(f.to), false, false)
		"bump":
			var at := tape.strip_pos(maxi(0, j if j >= 0 else b_sel))
			bump_at(at, 7)
			if not tape.stencils.is_empty():
				var back := float(start) if method == "alg5" else 0.0
				tape.tween_stencil(0, "start", back, d(0.3), Tween.TRANS_ELASTIC, Tween.EASE_OUT)
			return d(0.12)
	return 0.0


func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	tape.strip_vals = (c.get("strip", []) as Array).duplicate()
	start = int(c.get("start", 1))
	gel = int(c.get("gel", 0))
	em = int(c.get("em", -1))
	tape.punch = {}
	tape.labels = []
	match ph:
		P.PUNCH_CELL:
			j = int(c.get("j", -1))
			s_sel = 1
			tape.setup_text(z.substr(0, j) + "?" if j >= 0 else z, true)
			for q in maxi(0, j):
				tape.states[q] = "eq"
			tape.states[maxi(0, j)] = "ne"
			tape.head_on = false
			if tape.stencils.is_empty():
				tape.add_stencil(z, 0.0)
			tape.stencils[0].start = 0.0
			tape.stencils[0].ghost = false
			tape.stencils[0].marks = {}
			tape.strip_hl = j
			tape.drag_enabled = true
			_preview_cell(1)
		P.MIRROR_PUNCH:
			a_from = int(c.get("punch_from", start + gel + 1))
			if em == 0:
				a_from = start + 1
			b_sel = a_from
			v_sel = start
			tape.drag_enabled = false
			tape.strip_hl = -1
			_upd_punch()
		P.MIRROR_SHIFT:
			s_sel = 1
			tape.drag_enabled = true
			tape.strip_hl = em
		_:
			tape.drag_enabled = false
			tape.strip_hl = -1


func rebuild() -> void:
	sync(mc.phase, mc.cursor())
	if method == "alg5" and not tape.stencils.is_empty():
		tape.stencils[0].start = float(start)


# ---------------------------------------------------------------- spiegel (Definitie 11)
func _preview_cell(s: int) -> void:
	if phase != P.PUNCH_CELL or j < 0:
		return
	s = clampi(s, 1, maxi(1, j))
	s_sel = s
	tape.tween_stencil(0, "start", float(s), d(0.05))
	var teeth := {}
	for q in range(0, maxi(0, j - s)):
		teeth[q] = "mesh" if z[q] == z[s + q] else "clash"
	tape.stencils[0].teeth = teeth
	var ok := TxReference.mesh(z, j, s)
	tape.labels = [{"col": float(s + m) + 0.6, "y": TxTapeView.YS + 40, "text": ("V[%d] = %d  ✓ past" if ok else "V[%d] = %d  ✕ botst") % [j, s],
		"color": TxPal.SIG_EQ if ok else TxPal.SIG_NE, "size": 24}]


# ---------------------------------------------------------------- spiegelrit (Algoritme 5)
func _upd_punch() -> void:
	var smax := tape.strip_vals.size() - 1
	b_sel = clampi(b_sel, a_from - 1, smax)
	v_sel = clampi(v_sel, 1, smax)
	tape.punch = {"a": a_from, "b": maxi(a_from, b_sel), "v": v_sel, "hit": hit}
	knob_ang = -PI / 2 + v_sel * 0.5
	if b_sel < a_from:
		tape.labels = [{"col": float(a_from) + 0.2, "y": TxTapeView.YV - 34, "text": "niets ponsen", "color": TxPal.TEXT_DIM, "size": 20}]
	else:
		tape.labels = []


func _preview_shift(s: int) -> void:
	if phase != P.MIRROR_SHIFT:
		return
	s = clampi(s, 1, m + 1)
	s_sel = s
	tape.tween_stencil(0, "start", float(start + s), d(0.05))
	var teeth := {}
	for q in range(0, maxi(0, em - s)):
		var pos := start + s + q
		var tc := z[pos] if pos < m else "⏎"
		teeth[q] = "mesh" if tc == z[q] else "clash"
	tape.stencils[0].teeth = teeth
	var pr := mc.preview({"act": "shift", "s": s})
	var ok := bool(pr.get("mesh", false))
	tape.labels = [{"col": float(start + s + m) + 0.6, "y": TxTapeView.YS + 40, "text": ("s = %d  ✓ past" if ok else "s = %d  ✕ botst") % s,
		"color": TxPal.SIG_EQ if ok else TxPal.SIG_NE, "size": 24}]


func _on_drag(cols: int, released: bool) -> void:
	if con.input_locked():
		return
	if phase == P.PUNCH_CELL:
		_preview_cell(cols)
		if released:
			pass
	elif phase == P.MIRROR_SHIFT:
		if not released:
			_preview_shift(cols)
		elif cols >= 1:
			_preview_shift(cols)
			move({"act": "shift", "s": s_sel})
		else:
			tape.tween_stencil(0, "start", float(start), d(0.2), Tween.TRANS_BACK)


func tape_clickable(kind_: String, jj: int) -> bool:
	if kind_ != "strip" or con.input_locked():
		return false
	return phase == P.MIRROR_PUNCH or (phase == P.MIRROR_SHIFT and jj == em) or (phase == P.PUNCH_CELL and jj == j)


func _on_strip(jj: int) -> void:
	if con.input_locked():
		return
	if phase == P.MIRROR_PUNCH:
		b_sel = jj
		_upd_punch()
		TxSnd.play("ui_switch", -8.0)
	elif phase == P.MIRROR_SHIFT and jj == em:
		move({"act": "strip"})
	elif phase == P.PUNCH_CELL and jj == j:
		move({"act": "punch", "j": j, "v": s_sel})


func key(e: InputEventKey) -> bool:
	var k := e.keycode
	match phase:
		P.PUNCH_CELL:
			if k == KEY_RIGHT:
				_preview_cell(s_sel + 1)
				return true
			if k == KEY_LEFT:
				_preview_cell(s_sel - 1)
				return true
			if k >= KEY_1 and k <= KEY_9:
				_preview_cell(k - KEY_0)
				return true
			if k == KEY_P or k == KEY_ENTER or k == KEY_KP_ENTER:
				move({"act": "punch", "j": j, "v": s_sel})
				return true
			if k == KEY_D:
				move({"act": "done"})
				return true
		P.MIRROR_PUNCH:
			if k == KEY_RIGHT:
				b_sel += 1
				_upd_punch()
				return true
			if k == KEY_LEFT:
				b_sel -= 1
				_upd_punch()
				return true
			if k == KEY_UP:
				v_sel += 1
				_upd_punch()
				TxSnd.play("gear_engage", -14.0, 1.6)
				return true
			if k == KEY_DOWN:
				v_sel -= 1
				_upd_punch()
				TxSnd.play("gear_engage", -14.0, 1.4)
				return true
			if k == KEY_P or k == KEY_ENTER or k == KEY_KP_ENTER:
				move({"act": "punch_to", "to": b_sel, "v": v_sel})
				return true
		P.MIRROR_SHIFT:
			if k == KEY_RIGHT:
				_preview_shift(s_sel + 1)
				return true
			if k == KEY_LEFT:
				_preview_shift(s_sel - 1)
				return true
			if k >= KEY_1 and k <= KEY_9:
				_preview_shift(k - KEY_0)
				return true
			if k == KEY_ENTER or k == KEY_KP_ENTER:
				move({"act": "shift", "s": s_sel})
				return true
			if k == KEY_V:
				move({"act": "strip"})
				return true
	return false


func buttons() -> Array:
	match phase:
		P.PUNCH_CELL:
			return [{"text": "Pons", "key": "P", "kind": "brass", "enabled": true, "call": func(): move({"act": "punch", "j": j, "v": s_sel})},
				{"text": "Klaar", "key": "D", "kind": "key", "enabled": true, "call": func(): move({"act": "done"})}]
		P.MIRROR_PUNCH:
			return [{"text": "Pons", "key": "P", "kind": "brass", "enabled": true, "call": func(): move({"act": "punch_to", "to": b_sel, "v": v_sel})},
				{"text": "Waarde −", "key": "↓", "kind": "key", "enabled": true, "call": func():
					v_sel -= 1
					_upd_punch()},
				{"text": "Waarde +", "key": "↑", "kind": "key", "enabled": true, "call": func():
					v_sel += 1
					_upd_punch()}]
		P.MIRROR_SHIFT:
			return [{"text": "Verschuif", "key": "Enter", "kind": "brass", "enabled": true, "call": func(): move({"act": "shift", "s": s_sel})},
				{"text": "Strook", "key": "V", "kind": "key", "enabled": true, "call": func(): move({"act": "strip"})}]
	return []


func hint(mv: Dictionary) -> Vector2:
	match str(mv.get("act", "")):
		"punch":
			_preview_cell(int(mv.v))
			return tape.strip_pos(int(mv.j)) + Vector2(-10, 20)
		"punch_to":
			b_sel = int(mv.to)
			v_sel = int(mv.v)
			_upd_punch()
			return tape.strip_pos(int(mv.to)) + Vector2(-10, 20)
		"shift":
			_preview_shift(int(mv.s))
			return tape.stencil_pos(0, 0) + Vector2(0, 40)
		"done":
			return con.button_pos(1)
	return Vector2.INF


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	TxPal.brass_plate(self, Vector2(200, 42), pl[0], 20, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, Vector2(28, 92), pl[1], 30, TxPal.TEXT)
	var y := 140.0
	var lines: Array = []
	match phase:
		P.PUNCH_CELL:
			lines = ["Vakje %d: je las z[0..%d] (groen); op %d ging het mis." % [j, j - 1, j],
				"Sleep de kopie naar rechts tot de tanden inklikken.", "De kleinste verschuiving die past = V[%d]. Pons die." % j]
		P.MIRROR_PUNCH:
			if em == 0:
				lines = ["Meteen mismatch (em = 0): V[start+1] = start+1.", "Pons vakje %d met waarde %d." % [start + 1, start + 1] if false else "Kies het vakje en de waarde, pons (P)."]
			else:
				lines = ["De naald stopte op em = %d (start = %d)." % [em, start], "Pons tot en met de mismatch: vakjes %d .. start+em." % a_from,
					"De waarde is de huidige verschuiving (start)."]
		P.MIRROR_SHIFT:
			lines = ["Verschuif de kopie (tandenregel), of V = strookwaarde V[em].", "Algoritme 5: start += V[em]."]
		_:
			lines = ["Algoritme 5: zoek z in zichzelf." if method == "alg5" else "Definitie 11: pons de verschuivingstabel."]
	for l in lines:
		TxPal.text_l(self, TxPal.UI, Vector2(30, y), str(l), 20, TxPal.TEXT_DIM)
		y += 30
	y += 16
	var keys: Array = []
	match phase:
		P.PUNCH_CELL:
			keys = [["←", "→"], "verschuiving", ["P"], "ponsen", ["D"], "klaar"]
		P.MIRROR_PUNCH:
			keys = [["←", "→"], "vakje", ["↑", "↓"], "waarde", ["P"], "ponsen"]
		P.MIRROR_SHIFT:
			keys = [["←", "→", "Enter"], "verschuiven", ["V"], "strook"]
	var kx := 30.0
	for it in keys:
		if it is Array:
			for kc in it:
				kx = TxDraw.keycap(self, Vector2(kx, y), str(kc), 18).end.x + 6
		else:
			kx += TxPal.text_l(self, TxPal.UI, Vector2(kx + 4, y + 15), str(it), 18, TxPal.TEXT_DIM) + 24
	# draaiknop (spiegelrit) of tabelstand
	if method == "alg5" and phase == P.MIRROR_PUNCH:
		TxPal.knob(self, Vector2(760, 160), 48, knob_ang, "waarde = %d" % v_sel)
		TxPal.text_l(self, TxPal.TAPE, Vector2(840, 150), "vakjes %d..%d = %d" % [a_from, maxi(a_from, b_sel), v_sel] if b_sel >= a_from else "niets ponsen", 26, TxPal.TEXT)
	# overzicht: de strook tot nu toe
	var sx := 700.0
	var sy := 300.0
	TxPal.text_l(self, TxPal.STENCIL, Vector2(sx, sy - 30), "STROOK", 18, TxPal.BRASS)
	for q in tape.strip_vals.size():
		var cr := Rect2(sx + q * 52, sy, 46, 46)
		draw_rect(cr, TxPal.MANILA)
		var v := int(tape.strip_vals[q])
		TxPal.text_c(self, TxPal.MONO, cr.position + Vector2(23, -12), str(q), 13, TxPal.TEXT_DIM)
		TxPal.text_c(self, TxPal.TAPE, cr.get_center(), str(v) if v > 0 else "·", 26, TxPal.INK)
		if q == j or (phase == P.MIRROR_PUNCH and q >= a_from and q <= b_sel):
			draw_rect(cr.grow(2), TxPal.SIG_AMBER, false, 3.0)
