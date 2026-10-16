class_name TxNeedlePanel
extends TxPanel
## Naaldmachines op het lint: Sjabloon (brute kracht), Doorloper (KMP) en Springer (BMH, ook kaarten stempelen en
## de Nachtdienst zonder kaartenbak). GDD §3.1, §3.3, §3.4, §4.1.

var kind := TxCodes.Machine.BRUTE
var s_prev := 1               # voorvertoning van de verschuiving / sprong (Doorloper/Springer)
var preview_on := false
var preview_res := {}
var key_sel := -1             # Springer: gekozen sleutelpositie (toetsenbord)
var stamp_sel := 0            # Springer kaarten: gekozen sjabloonpositie
var cards := {}               # Springer: getoonde kaarten (letter -> waarde)
var card_old := {}            # letter -> doorgestreepte vorige waarde
var card_strike := {}         # letter -> 0..1
var card_hl := ""             # laatst gestempelde/getrokken kaart
var pulled := -1
var pull := 0.0
var space_held := 0.0
var rewind_total := 0
var start := 0
var em := -1
var bmh_i := 0
var stamping := false
var _press_glow := 0.0


func _setup() -> void:
	kind = mc.kind
	tape.setup_text(mc.t)
	tape.stencils = []
	tape.strip_vals = []
	tape.arc = {}
	tape.punch = {}
	tape.labels = []
	tape.head_on = mc.t != ""
	tape.show_positions = mc.t != ""
	tape.add_stencil(z, 0.0)
	tape.head_col = 0.0
	tape.follow = 0.0
	tape.follow_hi = float(m)
	tape.scroll = 0.0
	tape.scroll_target = 0.0
	if kind == TxCodes.Machine.BMH:
		cards = (mc as TxBmh).cards.duplicate()
		var st0 := 0.0 if mc.t == "" else 0.0
		tape.stencils[0].start = st0
		stamping = str(stage.get("cards", "")) == "stamp"
		if mc.t == "":
			tape.head_on = false
	if kind == TxCodes.Machine.KMP:
		var km := mc as TxKmp
		if not km.strip.is_empty():
			tape.strip_vals = _strip_view(km.strip)
			tape.strip_extra = tape.strip_vals.size() > m
			tape.strip_col = 0.0
	if mc.mode == TxCodes.Mode.LIVE:
		tape.front = 0
		tape.front_f = 0.0
	tape.stencil_drag.connect(_on_drag)
	tape.tape_clicked.connect(_on_tape_click)
	tape.stencil_clicked.connect(_on_stencil_click)
	tape.strip_clicked.connect(_on_strip_click)
	tape.hover_changed.connect(func(_p): pass)


## Bij "eerste voorkomen" is het vakje V[m] niet nodig (Algoritme 5 kan het wel invullen): niet tonen.
func _strip_view(a: Array) -> Array:
	var out := a.duplicate()
	if mc.find != TxCodes.Find.ALL and out.size() > m:
		out.resize(m)
	return out


func plate() -> Array:
	match kind:
		TxCodes.Machine.KMP:
			return ["MODEL  K-M-P  1977", "DOORLOPER"]
		TxCodes.Machine.BMH:
			return ["MODEL  B-M-H  1980", "SPRINGER"]
	return ["MODEL  A-2", "SJABLOON"]


# ---------------------------------------------------------------- fx
func fx(f: Dictionary) -> float:
	match str(f.fx):
		"ready":
			var s := float(f.get("start", 0))
			tape.stencils[0].start = s
			tape.head_col = s if kind != TxCodes.Machine.BMH else s + m - 1
			tape.follow = s
			tape.follow_hi = s + m
			return 0.0
		"needle":
			if kind == TxCodes.Machine.BMH and str(f.result) != "wait":
				for p in tape.states.keys():
					if int(p) < int(tape.stencils[0].start):
						tape.states.erase(p)
			return needle(f)
		"stencil":
			var keep := kind == TxCodes.Machine.KMP
			var to := float(f.to)
			var dur := move_stencil(0, float(f.from), to, bool(f.get("auto", false)), keep)
			if kind == TxCodes.Machine.KMP and not tape.strip_vals.is_empty():
				var tw := create_tween()
				tw.tween_property(tape, "strip_col", to, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			if not bool(f.get("auto", false)):
				TxFx.floater(con.fx_layer, tape.stencil_pos(0, -0.6) + Vector2(0, -10), "+%d" % int(to - float(f.from)), TxPal.SIG_BLUE, 22, 30, 0.6)
			return dur
		"head":
			return move_head(float(f.from), float(f.to), bool(f.get("rewind", false)))
		"strip_move":
			tape.strip_vals = _strip_view(f.get("strip", []))
			tape.strip_extra = tape.strip_vals.size() > m
			tape.strip_dy = -260.0
			tape.strip_a = 1.0
			var tw2 := create_tween()
			tw2.tween_property(tape, "strip_dy", 0.0, d(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			TxSnd.play("strip_slide", -4.0)
			tw2.tween_callback(func():
				TxSnd.play("teeth_in", -6.0)
				TxFx.dust(con.fx_layer, tape.strip_pos(0), 6))
			return d(0.65)
		"bump":
			return _bump(f)
		"key":
			return _key_fx(f)
		"jump":
			return _jump_fx(f)
		"stamp":
			return _stamp_fx(f)
	return 0.0


func _bump(f: Dictionary) -> float:
	var reason := str(f.get("reason", ""))
	if reason == "hole":
		# Doorloper stuit op een leeg/verbrand vakje: "tok"
		var j := int(f.get("at", 0))
		TxSnd.play("bump", -10.0, 0.6)
		if not tape.strip_vals.is_empty():
			tape.strip_hl = j
			var tw := create_tween()
			tw.tween_interval(d(0.5))
			tw.tween_callback(func(): tape.strip_hl = -1)
			if bool(f.get("burnt", false)):
				TxFx.smoke(con.fx_layer, tape.strip_pos(j), 3)
		return d(0.15)
	var at := tape.stencil_pos(0, float(maxi(0, em)))
	if kind == TxCodes.Machine.KMP and f.has("at") and reason == "no_mesh":
		at = tape.char_pos(float(f.at)) + Vector2(0, 70)
	bump_at(at, 8)
	# elastisch terugveren van het sjabloon
	var s0 := float(start) if kind != TxCodes.Machine.BMH else float(bmh_i - m + 1)
	var tw := tape.tween_stencil(0, "start", s0, d(0.3), Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	tw.finished.connect(func(): _clear_preview())
	return d(0.12)


func _key_fx(f: Dictionary) -> float:
	var pos := int(f.pos)
	var ch := str(f.ch)
	tape.key_pos = pos
	var idx := _card_index(ch)
	pulled = idx
	card_hl = ch if cards.has(ch) else "overige"
	TxSnd.play("card_in", -4.0, 1.2)
	var tw := create_tween()
	tw.tween_property(self, "pull", 1.0, d(0.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(d(0.25))
	tw.tween_property(self, "pull", 0.0, d(0.2))
	tw.tween_callback(func(): pulled = -1)
	return d(0.22)


func _jump_fx(f: Dictionary) -> float:
	var from := float(f.from)
	var to := float(f.to)
	var s := int(f.s)
	bmh_i = int(to)
	var a := from - m + 1
	var b := to - m + 1
	var dur := d(clampf(0.08 * absf(to - from), 0.18, 0.5))
	tape.arc = {"from": from, "to": to, "u": 0.0, "label": "+%d" % s}
	tape.key_pos = -1
	_clear_preview()
	TxSnd.play("jump", -4.0, 1.0 + 0.05 * (8 - mini(s, 8)))
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float):
		if not tape.arc.is_empty():
			tape.arc["u"] = v, 0.0, 1.0, dur)
	tw.tween_method(func(v: float):
		tape.set_stencil(0, "start", v)
		tape.set_stencil(0, "dy", -sin(clampf((v - a) / maxf(0.001, b - a), 0.0, 1.0) * PI) * minf(70.0, 12.0 + 8.0 * absf(b - a))), a, b, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(func():
		tape.set_stencil(0, "dy", 0.0)
		TxSnd.play("land", -5.0)
		TxFx.dust(con.fx_layer, tape.stencil_pos(0, m / 2.0) + Vector2(0, 34), 6))
	tw.chain().tween_method(func(v: float): tape.set_stencil(0, "sq", v), 0.86, 1.0, d(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(d(0.25))
	tw.chain().tween_callback(func(): tape.arc = {})
	tape.states = {}
	tape.stencils[0].marks = {}
	tape.head_col = to
	tape.follow = b
	tape.follow_hi = to + 1
	return dur + d(0.12)


func _stamp_fx(f: Dictionary) -> float:
	var x := str(f.x)
	var v := int(f.v)
	var old := int(f.get("old", -1))
	if old >= 0 and old != v:
		card_old[x] = old
		card_strike[x] = 0.0
		create_tween().tween_method(func(u: float): card_strike[x] = u, 0.0, 1.0, d(0.2))
	else:
		card_old.erase(x)
	cards[x] = v
	card_hl = x
	TxSnd.play("stamp", -3.0)
	var cp := _card_rect(_card_index(x)).get_center() + position
	TxFx.ink(con.fx_layer, cp, TxPal.STAMP_RED, 6)
	TxFx.punch(0.006)
	tape.stencils[0].marks = {int(f.i): "eq"}
	return d(0.2)


# ---------------------------------------------------------------- toestand
func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	match kind:
		TxCodes.Machine.BRUTE:
			start = int(c.get("start", 0))
		TxCodes.Machine.KMP:
			start = int(c.get("start", 0))
			em = int(c.get("em", -1))
			if c.has("strip") and not (c.strip as Array).is_empty():
				tape.strip_vals = _strip_view(c.strip)
		TxCodes.Machine.BMH:
			bmh_i = int(c.get("i", m - 1))
			start = bmh_i - m + 1
			em = int(c.get("mis_z", -1))
			cards = (c.get("cards", {}) as Dictionary).duplicate()
			tape.key_pos = int(c.get("key_pos", -1)) if ph == P.DECIDE else -1
			var deciding := ph == P.DECIDE
			tape.hover_enabled = deciding and str(stage.get("cards", "")) != "none"
			tape.window_lo = start if deciding else -1
			tape.window_hi = bmh_i if deciding else -1
			if ph == P.DECIDE and key_sel < 0:
				key_sel = bmh_i
	tape.drag_enabled = ph == P.DECIDE and kind != TxCodes.Machine.BRUTE
	_clear_preview()
	if ph == P.DECIDE:
		s_prev = 1
		key_sel = bmh_i if kind == TxCodes.Machine.BMH else -1


func rebuild() -> void:
	var r := mc.render()
	tape.states = {}
	tape.arc = {}
	tape.stencils[0].marks = {}
	tape.stencils[0].dy = 0.0
	tape.stencils[0].sq = 1.0
	match kind:
		TxCodes.Machine.BMH:
			tape.stencils[0].start = float(int(r.i) - m + 1)
			tape.head_col = float(r.i)
		_:
			tape.stencils[0].start = float(r.start)
			tape.head_col = float(r.head)
			if kind == TxCodes.Machine.KMP:
				tape.strip_col = float(r.start)
				var ok: Array = r.get("window_ok", [])
				for q in ok.size():
					if ok[q]:
						tape.states[int(r.start) + q] = "eq"
						tape.stencils[0].marks[q] = "eq"
	_sync_hits(r)
	sync(int(r.phase), mc.cursor())


func _sync_hits(r: Dictionary) -> void:
	tape.hits = []
	for h in r.get("hits", []):
		if bool(h.real):
			tape.hits.append([int(h.start), int(h.end)])
	tape.missed = []
	for x in r.get("missed", []):
		tape.missed.append([int(x.start), int(x.end)])


func _clear_preview() -> void:
	preview_on = false
	preview_res = {}
	if tape.stencils.size() > 1:
		tape.stencils.resize(1)
	if not tape.stencils.is_empty():
		tape.stencils[0].teeth = {}
	tape.labels = []


## Voorvertoning van verschuiving s (Doorloper) of sprong s (Springer): sjabloon schuift, tanden tonen of het past.
func _preview(s: int) -> void:
	if phase != P.DECIDE:
		return
	s = clampi(s, 0, m + 2)
	s_prev = s
	preview_on = true
	if tape.stencils.size() < 2:
		var gi := tape.add_stencil(z, float(start), true)
		tape.stencils[gi].ghost = true
	tape.stencils[1].start = float(start)
	var to := float(start + s)
	tape.tween_stencil(0, "start", to, d(0.04))
	var teeth := {}
	var col := TxPal.SIG_EQ
	var txt := ""
	if kind == TxCodes.Machine.KMP:
		var pr := mc.preview({"act": "shift", "s": s}) if s >= 1 else {"mesh": false, "clash": []}
		preview_res = pr
		var clash: Array = pr.get("clash", [])
		for q in range(0, maxi(0, em - s)):
			var pos := start + s + q
			teeth[q] = "clash" if clash.has(pos) else "mesh"
		if s < 1:
			txt = "s = 0"
			col = TxPal.SIG_NE
		elif bool(pr.get("mesh", false)):
			txt = "s = %d  ✓ past" % s
		else:
			txt = "s = %d  ✕ botst" % s
			col = TxPal.SIG_NE
		if s >= 1 and bool(pr.get("mesh", false)) and em > s:
			TxSnd.play("teeth_in", -18.0, 1.6, true, 60)
		elif s >= 1 and not bool(pr.get("mesh", false)):
			TxSnd.play("bump", -20.0, 1.5, true, 60)
	else:
		txt = "sprong %d" % s if s >= 1 else "sprong 0"
		col = TxPal.SIG_AMBER if s >= 1 else TxPal.SIG_NE
	tape.stencils[0].teeth = teeth
	tape.labels = [{"col": float(start + s + m) + 0.6, "y": YS_LABEL, "text": txt, "color": col, "size": 24}]


const YS_LABEL := TxTapeView.YS + 40


func _commit_preview() -> void:
	if phase != P.DECIDE or not preview_on:
		return
	var s := s_prev
	if kind == TxCodes.Machine.KMP:
		move({"act": "shift", "s": s})
	elif kind == TxCodes.Machine.BMH:
		move({"act": "jump", "s": s})


# ---------------------------------------------------------------- invoer
func _on_drag(cols: int, released: bool) -> void:
	if phase != P.DECIDE or con.input_locked():
		return
	if not released:
		_preview(cols)
	else:
		if cols >= 1:
			_preview(cols)
			_commit_preview()
		else:
			_clear_preview()
			tape.tween_stencil(0, "start", float(start), d(0.2), Tween.TRANS_BACK)


func _on_tape_click(pos: int) -> void:
	if con.input_locked():
		return
	if kind == TxCodes.Machine.BMH and phase == P.DECIDE and str(stage.get("cards", "")) != "none":
		move({"act": "key", "pos": pos})
	elif kind == TxCodes.Machine.BRUTE:
		_needle_button()


func _on_stencil_click(i: int) -> void:
	if con.input_locked():
		return
	if kind == TxCodes.Machine.BMH:
		if phase == P.CARDS:
			stamp_sel = i
			move({"act": "stamp", "i": i})
		elif phase == P.DECIDE and str(stage.get("cards", "")) == "none":
			move({"act": "jump", "s": m - 1 - i if i < m - 1 else m})


func _on_strip_click(j: int) -> void:
	if con.input_locked():
		return
	if kind == TxCodes.Machine.KMP and phase == P.DECIDE:
		move({"act": "strip"})


func tape_clickable(kind_: String, _i: int) -> bool:
	if con.input_locked():
		return false
	match kind_:
		"tape":
			if kind == TxCodes.Machine.BMH:
				return phase == P.DECIDE and str(stage.get("cards", "")) != "none"
			return kind == TxCodes.Machine.BRUTE and (phase == P.READY or phase == P.DECIDE)
		"stencil":
			return kind == TxCodes.Machine.BMH and (phase == P.CARDS or (phase == P.DECIDE and str(stage.get("cards", "")) == "none"))
		"strip":
			return kind == TxCodes.Machine.KMP and phase == P.DECIDE
	return false


func _needle_button() -> void:
	if phase == P.READY:
		move({"act": "go"})
	elif phase == P.DECIDE and kind == TxCodes.Machine.BRUTE:
		move({"act": "next"})
	elif phase == P.READY or (phase == P.DECIDE and kind != TxCodes.Machine.BRUTE):
		pass


func key(e: InputEventKey) -> bool:
	var k := e.keycode
	if phase == P.READY and (k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER):
		move({"act": "go"})
		return true
	match kind:
		TxCodes.Machine.BRUTE:
			if k == KEY_SPACE and phase == P.DECIDE:
				move({"act": "next"})
				return true
		TxCodes.Machine.KMP:
			if phase == P.DECIDE:
				if k == KEY_RIGHT:
					_preview((s_prev + 1) if preview_on else 1)
					return true
				if k == KEY_LEFT:
					_preview(maxi(1, s_prev - 1) if preview_on else 1)
					return true
				if k >= KEY_1 and k <= KEY_9:
					_preview(k - KEY_0)
					return true
				if k == KEY_ENTER or k == KEY_KP_ENTER:
					if not preview_on:
						_preview(1)
					_commit_preview()
					return true
				if k == KEY_V:
					move({"act": "strip"})
					return true
				if k == KEY_ESCAPE and preview_on:
					_clear_preview()
					tape.tween_stencil(0, "start", float(start), d(0.15))
					return true
		TxCodes.Machine.BMH:
			if phase == P.CARDS:
				if k == KEY_RIGHT:
					stamp_sel = mini(m - 1, stamp_sel + 1)
					_mark_stamp_sel()
					return true
				if k == KEY_LEFT:
					stamp_sel = maxi(0, stamp_sel - 1)
					_mark_stamp_sel()
					return true
				if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
					move({"act": "stamp", "i": stamp_sel})
					return true
				if k == KEY_D:
					move({"act": "cards_done"})
					return true
			elif phase == P.DECIDE:
				var nocards := str(stage.get("cards", "")) == "none"
				if nocards:
					if k == KEY_SPACE:
						move({"act": "jump", "s": m})
						return true
					if k == KEY_RIGHT:
						_preview((s_prev + 1) if preview_on else 1)
						return true
					if k == KEY_LEFT:
						_preview(maxi(1, s_prev - 1) if preview_on else 1)
						return true
					if k == KEY_ENTER or k == KEY_KP_ENTER:
						if preview_on:
							_commit_preview()
						return true
					# letter typen = die sjabloonletter (meest rechtse vóór de laatste) onder het sleutelteken
					var ch := char(e.unicode).to_lower() if e.unicode > 0 else ""
					if ch != "" and z.contains(ch):
						var p := z.substr(0, m - 1).rfind(ch)
						move({"act": "jump", "s": m - 1 - p if p >= 0 else m})
						return true
				else:
					if k == KEY_K and not bool(stage.get("key_hint", false)):
						move({"act": "key", "pos": bmh_i})
						return true
					if k == KEY_K:
						move({"act": "key", "pos": bmh_i})
						return true
					if k == KEY_LEFT:
						key_sel = clampi(key_sel - 1, start, bmh_i)
						tape.hover_pos = key_sel
						return true
					if k == KEY_RIGHT:
						key_sel = clampi(key_sel + 1, start, bmh_i)
						tape.hover_pos = key_sel
						return true
					if k == KEY_ENTER or k == KEY_KP_ENTER:
						move({"act": "key", "pos": key_sel})
						return true
	return false


func _mark_stamp_sel() -> void:
	tape.stencils[0].cur = stamp_sel


func _process(dt: float) -> void:
	super._process(dt)
	# Spatie ingedrukt houden = 3× sneller (brute kracht)
	if kind == TxCodes.Machine.BRUTE and Input.is_key_pressed(KEY_SPACE) and not con.input_locked() and phase == P.DECIDE \
			and not con.is_busy():
		space_held += dt
		if space_held > 0.25:
			move({"act": "next"})
			space_held = 0.18
	elif not Input.is_key_pressed(KEY_SPACE):
		space_held = 0.0
	_press_glow = maxf(0.0, _press_glow - dt * 2.0)


func buttons() -> Array:
	var out: Array = []
	match kind:
		TxCodes.Machine.BRUTE:
			out.append({"text": "Naald" if phase == P.READY else "Volgende", "key": "Spatie", "kind": "brass",
				"enabled": phase == P.READY or phase == P.DECIDE, "call": _needle_button})
		TxCodes.Machine.KMP:
			if phase == P.READY:
				out.append({"text": "Naald", "key": "Spatie", "kind": "brass", "enabled": true, "call": func(): move({"act": "go"})})
			else:
				out.append({"text": "Vastzetten", "key": "Enter", "kind": "brass", "enabled": phase == P.DECIDE,
					"call": func():
						if not preview_on:
							_preview(1)
						_commit_preview()})
				if not tape.strip_vals.is_empty():
					out.append({"text": "Strook", "key": "V", "kind": "key", "enabled": phase == P.DECIDE,
						"call": func(): move({"act": "strip"})})
		TxCodes.Machine.BMH:
			if phase == P.CARDS:
				out.append({"text": "Kaarten klaar", "key": "D", "kind": "brass", "enabled": true,
					"call": func(): move({"act": "cards_done"})})
			elif phase == P.READY:
				out.append({"text": "Naald", "key": "Spatie", "kind": "brass", "enabled": true, "call": func(): move({"act": "go"})})
			elif str(stage.get("cards", "")) == "none":
				out.append({"text": "Volle sprong m", "key": "Spatie", "kind": "brass", "enabled": phase == P.DECIDE,
					"call": func(): move({"act": "jump", "s": m})})
			else:
				out.append({"text": "Sleutel trekken", "key": "K" if not bool(stage.get("key_hint", false)) else "klik",
					"kind": "brass", "enabled": phase == P.DECIDE and key_sel >= 0,
					"call": func(): move({"act": "key", "pos": key_sel if key_sel >= 0 else bmh_i})})
	return out


func hint(mv: Dictionary) -> Vector2:
	match str(mv.get("act", "")):
		"shift":
			_preview(int(mv.s))
			return tape.stencil_pos(0, 0) + Vector2(0, 40)
		"jump":
			_preview(int(mv.s))
			return tape.stencil_pos(0, m - 1) + Vector2(0, 40)
		"key":
			return tape.char_pos(int(mv.pos)) + Vector2(-10, 30)
		"stamp":
			return tape.stencil_pos(0, int(mv.i)) + Vector2(-10, 30)
		"strip":
			return tape.strip_pos(em) + Vector2(-10, 20)
		"go", "next":
			return con.button_pos(0)
		"cards_done":
			return con.button_pos(0)
	return Vector2.INF


# ---------------------------------------------------------------- tekenen
func _card_list() -> Array:
	var letters: Array = []
	for i in m:
		var x := z[i]
		if not letters.has(x) and (i < m - 1 or z.substr(0, m - 1).contains(x)):
			letters.append(x)
	letters.sort()
	var out: Array = []
	for x in letters:
		out.append([x, cards.get(x, null)])
	out.append(["overige", m])
	return out


func _card_index(x: String) -> int:
	var l := _card_list()
	for i in l.size():
		if l[i][0] == x:
			return i
	return l.size() - 1


func _card_rect(i: int) -> Rect2:
	var l := _card_list()
	var box := _box_rect()
	var cw := minf(86.0, (box.size.x - 40) / maxf(l.size(), 1) - 10)
	return Rect2(box.position.x + 20 + i * (cw + 10), box.position.y + 14, cw, 92)


func _box_rect() -> Rect2:
	return Rect2(560, 70, 560, 220)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	TxPal.brass_plate(self, Vector2(200, 42), pl[0], 20, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, Vector2(28, 92), pl[1], 30, TxPal.TEXT)
	var y := 140.0
	match kind:
		TxCodes.Machine.BRUTE:
			_draw_brute(y)
		TxCodes.Machine.KMP:
			_draw_kmp(y)
		TxCodes.Machine.BMH:
			_draw_bmh(y)


func _lines(y: float, lines: Array) -> float:
	for l in lines:
		TxPal.text_l(self, TxPal.UI, Vector2(30, y), str(l), 20, TxPal.TEXT_DIM)
		y += 30
	return y


func _draw_brute(y: float) -> void:
	y = _lines(y, ["Algoritme 2: vergelijk z met t[start..] van links naar rechts.",
		"Stop bij de eerste mismatch, schuif dan precies 1 op.", "Er is geen keuze: de machine is de maatstaf."])
	y += 16
	TxDraw.keycap(self, Vector2(30, y), "Spatie", 20)
	TxPal.text_l(self, TxPal.UI, Vector2(120, y + 16), "naald / volgende   (ingedrukt houden = sneller)", 20, TxPal.TEXT)
	# spoelmeter
	var rr := Rect2(600, 70, 360, 210)
	TxPal.well(self, rr, TxPal.CONSOLE_LO, 10)
	TxPal.text_c(self, TxPal.STENCIL, Vector2(rr.get_center().x, rr.position.y + 26), "SPOELMETER", 20, TxPal.BRASS)
	TxDraw.counter(self, Vector2(rr.get_center().x - 74, rr.position.y + 52), float(con.rewind_shown), 4, "", 30, 44)
	TxPal.text_c(self, TxPal.UI, Vector2(rr.get_center().x, rr.position.y + 140), "posities die de leeskop", 18, TxPal.TEXT_DIM)
	TxPal.text_c(self, TxPal.UI, Vector2(rr.get_center().x, rr.position.y + 164), "terug moest (opnieuw lezen)", 18, TxPal.TEXT_DIM)
	if con.rewind_flash > 0.0:
		TxPal.glow(self, rr.get_center(), 300, TxPal.SIG_AMBER, 0.3 * con.rewind_flash)
	_draw_live(Rect2(600, 300, 360, 150))


func _draw_kmp(y: float) -> void:
	if phase == P.DECIDE:
		y = _lines(y, ["Mismatch op sjabloonpositie %d. Sleep het sjabloon naar rechts:" % em,
			"het past enkel als wat je al las (groen) blijft kloppen."])
	else:
		y = _lines(y, ["De naald vergelijkt vanaf de leeskop; de kop gaat nooit terug.",
			"Na een mismatch kies jij de verschuiving (Definitie 11)."])
	y += 10
	# s-kiezer
	for i in mini(m + 1, 9):
		var s := i + 1
		var kr := Rect2(30 + i * 62, y, 54, 54)
		var on := preview_on and s == s_prev
		TxPal.box(self, Rect2(kr.position + Vector2(0, 5), kr.size), TxPal.BAKELITE_LO, 8)
		TxPal.box(self, kr, TxPal.BRASS if on else TxPal.BAKELITE_HI, 8)
		TxPal.text_c(self, TxPal.MONO, kr.get_center(), str(s), 26, TxPal.TEXT_ON_BRASS if on else TxPal.TEXT)
	y += 80
	TxPal.text_l(self, TxPal.UI, Vector2(30, y), "tanden:", 20, TxPal.TEXT_DIM)
	TxPal.lamp(self, Vector2(124, y), 9, TxPal.SIG_EQ, 1.0, "ok")
	TxPal.text_l(self, TxPal.UI, Vector2(142, y), "haken in", 20, TxPal.TEXT)
	TxPal.lamp(self, Vector2(256, y), 9, TxPal.SIG_NE, 1.0, "ne")
	TxPal.text_l(self, TxPal.UI, Vector2(274, y), "botsen (klem)", 20, TxPal.TEXT)
	y += 40
	var kx := 30.0
	for kc in ["←", "→", "Enter"]:
		kx = TxDraw.keycap(self, Vector2(kx, y), kc, 18).end.x + 8
	TxPal.text_l(self, TxPal.UI, Vector2(kx + 6, y + 15), "verschuiven / vastzetten", 18, TxPal.TEXT_DIM)
	if not tape.strip_vals.is_empty():
		var vr := TxDraw.keycap(self, Vector2(430, y), "V", 18)
		TxPal.text_l(self, TxPal.UI, Vector2(vr.end.x + 10, y + 15), "= strook V[em]", 18, TxPal.TEXT_DIM)
	_draw_live(Rect2(640, 60, 360, 220))


func _draw_bmh(y: float) -> void:
	var nocards := str(stage.get("cards", "")) == "none"
	if phase == P.CARDS:
		y = _lines(y, ["vul_VH: klik de sjabloonletters 0..m−2,", "van links naar rechts.",
			"Elke stempel schrijft m−1−i op de kaart van z[i];", "een latere stempel overschrijft. De laatste letter klemt."])
	elif nocards:
		y = _lines(y, ["Geen kaartenbak: klik de sjabloonletter die onder", "het sleutelteken t[i] moet komen (meest rechtse vóór de laatste).",
			"Spatie = staat er niet in → sprong m."])
	else:
		y = _lines(y, ["De naald vergelijkt van rechts naar links.", "Sleutelteken = t[i] onder de LAATSTE letter:",
			"klik het op het lint; de kaart geeft de sprong."])
	if not nocards:
		TxDrawMachines.card_box(self, _box_rect(), _card_list(), pulled, pull)
		# doorgestreepte vorige waarde
		var l := _card_list()
		for i in l.size():
			var x: String = l[i][0]
			if card_old.has(x) and pulled != i:
				TxDrawMachines.index_card(self, _card_rect(i), x, l[i][1], int(card_old[x]), float(card_strike.get(x, 1.0)), x == card_hl)
			elif x == card_hl and pulled != i and phase == P.CARDS:
				TxPal.ring(self, _card_rect(i).grow(3), TxPal.SIG_AMBER, 4, 3)
	y += 10
	if phase == P.CARDS:
		var kx := 30.0
		for kc in ["←", "→", "Enter"]:
			kx = TxDraw.keycap(self, Vector2(kx, y), kc, 18).end.x + 8
		TxPal.text_l(self, TxPal.UI, Vector2(kx + 6, y + 15), "stempelen ·  D = kaarten klaar", 18, TxPal.TEXT_DIM)
	elif phase == P.DECIDE and not nocards:
		var kx2 := 30.0
		for kc in (["K"] if not bool(stage.get("key_hint", false)) else ["←", "→", "Enter"]):
			kx2 = TxDraw.keycap(self, Vector2(kx2, y), kc, 18).end.x + 8
		TxPal.text_l(self, TxPal.UI, Vector2(kx2 + 6, y + 15), "sleutelteken  ·  of sleep het sjabloon", 18, TxPal.TEXT_DIM)
	_draw_live(Rect2(560, 300, 560, 140) if not nocards else Rect2(640, 60, 380, 220))


func _draw_live(r: Rect2) -> void:
	if mc.mode != TxCodes.Mode.LIVE or mc.buffer < 0:
		return
	var nd := mc.need()
	var used := 0.0
	if nd >= 0:
		used = clampf(con.front_f - float(nd), 0.0, float(mc.buffer))
	TxDraw.loop_bin(self, r, mc.buffer, used, con.warn)
	TxPal.text_l(self, TxPal.UI, Vector2(r.position.x + 4, r.end.y + 18), "lusbak B = %d · lint aan %.1f teken/s" % [mc.buffer, con.live_v()], 17, TxPal.TEXT_DIM)
