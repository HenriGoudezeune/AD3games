class_name TxWheelPanel
extends TxPanel
## Vingerafdruk (Rabin-Karp, Algoritme 3; GDD §3.2, §4.4): het hashwiel met q tanden rekent mod q door te draaien.
## Hendels ×2 (D), −w (W), +1 (1); Enter = gewicht vastzetten / volgend bit / schuif; alarm C / M / N.

const WC := Vector2(230, 300)
const WR := 122.0
const LEV := Vector2(450, 104)
const ALARM := Vector2(1190, 70)
const BITS := Vector2(700, 300)

var q := 7
var wheel_pos := 0.0
var notch := -1
var w := -1
var part := ""
var bits := ""
var bit_k := 0
var win := 0
var out_b := ""
var in_b := ""
var did_double := false
var did_minus := false
var alarm_on := false
var pulls := {"×2": 0.0, "−w": 0.0, "+1": 0.0}
var gear_eng := 0.0
var gear_spin := 0.0
var slide := 1.0
var sig_i := 0
var signal_mode := false


func _setup() -> void:
	var rk := mc as TxRabinKarp
	q = rk.q
	signal_mode = rk.signal_mode()
	tape.stencils = []
	tape.strip_vals = []
	tape.labels = []
	tape.arc = {}
	tape.punch = {}
	tape.head_on = true
	tape.show_positions = true
	tape.setup_text(mc.t if mc.t != "" else z)
	tape.cell = 44.0
	tape.fsize = 44
	notch = rk.hz
	w = rk.w
	wheel_pos = float(rk.wheel)


func plate() -> Array:
	return ["MODEL  R-K · q = %d" % q, "VINGERAFDRUK"]


func unit() -> Array:
	return ["WIELSLAGEN", "wheel"]


func chef_anchor() -> Vector2:
	return Vector2(1500, 650)


func fx(f: Dictionary) -> float:
	match str(f.fx):
		"wheel":
			return _wheel_fx(f)
		"notch":
			notch = int(f.value)
			TxSnd.play("stamp", -4.0, 1.2)
			TxFx.ink(con.fx_layer, global_position + WC + Vector2(0, -WR - 10), TxPal.STAMP_RED, 6)
			return d(0.2)
		"bit":
			var ok := bool(f.get("ok", true))
			TxSnd.play("relay", -6.0, 1.1)
			if str(f.which) == "w":
				w = int(f.value)
				gear_eng = 1.0
				create_tween().tween_property(self, "gear_eng", 0.0, d(0.5))
				TxFx.floater(con.fx_layer, global_position + Vector2(420, 420), "w = %d" % w, TxPal.STEEL_HI, 24)
			if not ok:
				pass
			return d(0.15)
		"window":
			out_b = str(f.out_bit)
			in_b = str(f.in_bit)
			slide = 0.0
			create_tween().tween_property(self, "slide", 1.0, d(0.25))
			TxSnd.play("strip_slide", -8.0, 1.3)
			win = int(f.i)
			tape.states = {}
			tape.frame = [win, win + m - 1]
			tape.follow = float(win)
			tape.follow_hi = float(win + m)
			return d(0.25)
		"alarm":
			alarm_on = true
			TxSnd.loop("alarm", "alarm_loop", true, -10.0)
			TxSnd.layer(true)
			TxFx.shake(2.0, 0.1)
			return d(0.3)
		"verify":
			TxSnd.loop("alarm", "alarm_loop", false)
			alarm_on = false
			var steps: Array = f.get("steps", [])
			var dur := needle({"steps": steps, "result": "match" if bool(f.equal) else "mismatch"}, 99)
			if not bool(f.equal):
				var tw := create_tween()
				tw.tween_interval(dur)
				tw.tween_callback(func():
					TxSnd.play("false_alarm", -12.0, 1.5)
					TxFx.floater(con.fx_layer, tape.char_pos(float(win) + m / 2.0) + Vector2(0, -60), "hashbotsing", TxPal.SIG_GREY, 24))
			return dur + d(0.2)
		"hit", "false_alarm":
			TxSnd.loop("alarm", "alarm_loop", false)
			alarm_on = false
	return 0.0


func _wheel_fx(f: Dictionary) -> float:
	var op := str(f.op)
	var from := int(f.from)
	var to := int(f.to)
	var teeth := 0
	match op:
		"double":
			teeth = from
			_pull("×2")
		"minus_w":
			teeth = -posmod(from - to, q)
			_pull("−w")
			gear_eng = 1.0
			create_tween().tween_property(self, "gear_eng", 0.0, d(0.4)).set_delay(d(0.2))
			TxSnd.play("gear_engage", -4.0)
		"plus1":
			teeth = 1
			_pull("+1")
			TxSnd.play("plus_one", -6.0)
		"set":
			wheel_pos = float(to)
			return 0.0
	var start := wheel_pos
	var total := float(teeth)
	var n := absi(teeth)
	var per := d(0.012 if n > 6 else 0.035)
	var dur := maxf(d(0.08), per * n)
	var tw := create_tween()
	var last := [int(round(start))]
	tw.tween_method(func(v: float):
		wheel_pos = start + v
		gear_spin = -v * 0.6
		var cur := int(floor(start + v))
		if cur != last[0]:
			last[0] = cur
			TxSnd.play("wheel_tooth", -12.0, 1.0 + 0.02 * posmod(cur, q), false), 0.0, total, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): wheel_pos = float(to))
	# wijzer veert na
	return dur + d(0.04)


func _pull(nm: String) -> void:
	pulls[nm] = 1.0
	TxSnd.play("lever", -8.0, 1.2)
	var tw := create_tween()
	tw.tween_method(func(v: float): pulls[nm] = v, 1.0, 0.0, d(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	var np := str(c.get("phase_part", ""))
	bits = str(c.get("bits", ""))
	bit_k = int(c.get("bit_k", 0))
	win = int(c.get("i", 0))
	sig_i = int(c.get("signal_index", 0))
	did_double = bool(c.get("did_double", false))
	did_minus = bool(c.get("did_minus", false))
	notch = int(c.get("notch", -1))
	w = int(c.get("w", -1))
	if ph != P.ALARM and alarm_on:
		alarm_on = false
		TxSnd.loop("alarm", "alarm_loop", false)
	if ph != P.ALARM:
		TxSnd.layer(false)
	part = np
	match np:
		"w", "z":
			if tape.text != z:
				tape.setup_text(z)
			tape.frame = [0, m - 1]
			tape.head_col = float(clampi(bit_k, 0, m - 1)) if np == "z" else 0.0
			tape.head_on = np == "z"
		"signal":
			if tape.text != bits:
				tape.setup_text(bits)
			tape.frame = [0, m - 1]
			tape.head_on = true
			tape.head_col = float(clampi(bit_k, 0, m - 1))
		"window":
			if tape.text != mc.t:
				tape.setup_text(mc.t)
			tape.frame = [0, m - 1]
			tape.head_on = true
			tape.head_col = float(clampi(bit_k, 0, m - 1))
		"roll":
			if tape.text != mc.t:
				tape.setup_text(mc.t)
			tape.frame = [win, win + m - 1]
			tape.head_on = true
			tape.head_col = float(mini(win + m, mc.n - 1))
			out_b = str(c.get("out_bit", ""))
			in_b = str(c.get("in_bit", ""))
	tape.follow = tape.head_col
	if ph == P.DONE:
		TxSnd.loop("alarm", "alarm_loop", false)


func rebuild() -> void:
	var rk := mc as TxRabinKarp
	wheel_pos = float(rk.wheel)
	sync(mc.phase, mc.cursor())


func _enter() -> void:
	match phase:
		P.W_CALC:
			move({"act": "commit"})
		P.HORNER:
			move({"act": "next_bit"})
		P.ROLL:
			move({"act": "slide"})


func key(e: InputEventKey) -> bool:
	match e.keycode:
		KEY_D:
			move({"act": "wheel", "op": "double"})
			return true
		KEY_W:
			move({"act": "wheel", "op": "minus_w"})
			return true
		KEY_1, KEY_KP_1, KEY_EQUAL, KEY_KP_ADD:
			move({"act": "wheel", "op": "plus1"})
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_enter()
			return true
		KEY_C:
			move({"act": "verify"})
			return true
		KEY_M:
			move({"act": "report"})
			return true
		KEY_N:
			move({"act": "ignore"})
			return true
	return false


func _gui_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or not con.can_act():
		return
	var p: Vector2 = e.position
	var ops := ["double", "minus_w", "plus1"]
	for i in 3:
		var r := Rect2(LEV.x + i * 92 - 30, LEV.y - 10, 60, 190)
		if r.has_point(p):
			move({"act": "wheel", "op": ops[i]})
			accept_event()
			return
	if alarm_on:
		var acts := ["verify", "report", "ignore"]
		for i in 3:
			var br := Rect2(ALARM.x + 12, ALARM.y + 152 + i * 58, 146, 48)
			if br.has_point(p):
				move({"act": acts[i]})
				accept_event()
				return
	if Rect2(WC - Vector2(WR, WR), Vector2(WR, WR) * 2).has_point(p):
		_enter()
		accept_event()


func buttons() -> Array:
	if phase == P.ALARM:
		return [{"text": "Controleer", "key": "C", "kind": "brass", "enabled": true, "call": func(): move({"act": "verify"})},
			{"text": "Meld meteen", "key": "M", "kind": "red", "enabled": true, "call": func(): move({"act": "report"})},
			{"text": "Negeer", "key": "N", "kind": "key", "enabled": true, "call": func(): move({"act": "ignore"})}]
	var conf := "Vastzetten" if phase == P.W_CALC else ("Volgend bit" if phase == P.HORNER else "Schuif")
	return [{"text": "×2", "key": "D", "kind": "key", "enabled": true, "call": func(): move({"act": "wheel", "op": "double"})},
		{"text": "−w", "key": "W", "kind": "key", "enabled": phase == P.ROLL, "call": func(): move({"act": "wheel", "op": "minus_w"})},
		{"text": "+1", "key": "1", "kind": "key", "enabled": phase != P.W_CALC, "call": func(): move({"act": "wheel", "op": "plus1"})},
		{"text": conf, "key": "Enter", "kind": "brass", "enabled": true, "call": _enter}]


func hint(mv: Dictionary) -> Vector2:
	match str(mv.get("act", "")):
		"wheel":
			var i := ["double", "minus_w", "plus1"].find(str(mv.op))
			return global_position + LEV + Vector2(i * 92, 40)
		"verify", "report", "ignore":
			return global_position + ALARM + Vector2(60, 170)
	return con.button_pos(3)


func hit_origin(_f: Dictionary) -> Vector2:
	return tape.char_pos(float(win) + (m - 1) / 2.0)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	TxPal.brass_plate(self, Vector2(180, 40), pl[0], 20, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, Vector2(360, 42), pl[1], 28, TxPal.TEXT)
	var blink := (0.5 + 0.5 * signf(sin(t * TAU * 3.0))) if alarm_on else 0.0
	TxDrawMachines.wheel(self, WC, WR, q, wheel_pos, notch, blink)
	if w >= 0:
		TxDrawMachines.minus_w_gear(self, WC + Vector2(-WR - 10, WR - 6), w, gear_spin, gear_eng)
	var dis := {"−w": phase != P.ROLL, "+1": phase == P.W_CALC}
	TxDrawMachines.wheel_levers(self, LEV, pulls, dis)
	# stappenlampjes (wat heb je in dit venster al gedaan)
	if phase == P.ROLL or phase == P.HORNER:
		TxPal.lamp(self, LEV + Vector2(0, -26), 7, TxPal.SIG_EQ, 1.0 if did_double else 0.0)
		TxPal.lamp(self, LEV + Vector2(92, -26), 7, TxPal.SIG_EQ, 1.0 if did_minus else 0.0)
	# uitleg + formule
	var x := 730.0
	var y := 104.0
	var lines: Array = []
	match phase:
		P.W_CALC:
			lines = ["Gewicht w = 2^%d mod %d." % [m, q], "Het wiel staat op 1: druk %d keer ×2," % m, "dan Enter (vastzetten)."]
		P.HORNER:
			var b := bits[bit_k] if bit_k < bits.length() else "?"
			var what: String = {"z": "h(z) ijken", "window": "venster 0 (Horner)", "signal": "signaal %d" % (sig_i + 1)}.get(part, "")
			lines = ["%s — bit %d van %d is %s." % [what, bit_k + 1, bits.length(), b], "×2, en +1 als het bit 1 is.", "Enter = volgend bit."]
		P.ROLL:
			lines = ["Rollen naar venster %d:" % (win + 1), "×2,  −w als het uitgaande bit 1 is (%s)," % out_b, "+1 als het inkomende bit 1 is (%s), dan Enter." % in_b]
		P.ALARM:
			lines = ["Wijzer op de rode inkeping h(z) = %d!" % notch, "Zelfde vingerafdruk ≠ zelfde woord.", "Controleer · Meld meteen · Negeer"]
		_:
			lines = ["Algoritme 3: vingerafdruk mod q."]
	for l in lines:
		TxPal.text_l(self, TxPal.UI, Vector2(x, y), str(l), 21, TxPal.TEXT)
		y += 32
	TxPal.text_l(self, TxPal.TAPE, Vector2(x, y + 8), "q = %d   w = %s   h(z) = %s" % [q, str(w) if w >= 0 else "?", str(notch) if notch >= 0 else "?"], 22, TxPal.BRASS_HI)
	TxPal.text_l(self, TxPal.UI, Vector2(x, y + 44), "tikken in controles: %d" % int(mc.counters.get("ticks", 0)), 18, TxPal.TEXT_DIM)
	# bitvenster
	var bw := bits if phase != P.ROLL else mc.t.substr(win, m)
	if phase == P.ALARM:
		bw = mc.t.substr(win, m) if not signal_mode else bits
	if bw != "":
		TxDrawMachines.bit_window(self, BITS, bw, out_b if phase == P.ROLL else "", in_b if phase == P.ROLL else "", slide)
	TxDrawMachines.alarm_panel(self, ALARM, blink, true)
	if not alarm_on:
		draw_rect(Rect2(ALARM + Vector2(8, 146), Vector2(154, 180)), Color(TxPal.CONSOLE_HI, 0.55))
