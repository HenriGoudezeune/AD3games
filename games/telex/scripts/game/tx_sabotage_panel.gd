class_name TxSabotagePanel
extends TxPanel
## Tegenzet-missies (Oef. 32, 34b, 50; GDD §3.9): je schrijft zelf z en t; de vijandige machine draait en tikt.
## Klik een tegel (lint of sjabloon) om de letter te wisselen, of Tab (rij) + ←/→ + letter/Spatie. Enter = verstuur,
## F = klaar (de beste poging telt).

const TARGETS := {
	"brute": ["Laat de Sjabloon van de vijand zoveel mogelijk tikken.", "tikken (Algoritme 2, stop bij de eerste treffer)", true],
	"rk_calls": ["Laat de Vingerafdruk zo vaak mogelijk controleren.", "oproepen van strings_gelijk (q = 13)", true],
	"bmh_min": ["Laat de Springer vliegen: zo weinig mogelijk tikken. z mag niet in t staan.", "tikken (BMH)", false],
	"bmh_max": ["Laat de Springer kruipen: zo veel mogelijk tikken.", "tikken (BMH)", true],
}

var target := "brute"
var alphabet := "ab"
var zt := ""
var tt := ""
var row := 1                 # 0 = z, 1 = t
var col := 0
var enemy := 0.0
var last := -1
var best := -1
var last_valid := true
var running := false
var z_fixed := false


func _setup() -> void:
	var sb := mc as TxSabotage
	target = sb.target
	alphabet = sb.alphabet
	zt = sb.zt
	tt = sb.tt
	z_fixed = sb.z_fixed != ""
	row = 1 if z_fixed else 0
	tape.stencils = []
	tape.strip_vals = []
	tape.labels = []
	tape.arc = {}
	tape.punch = {}
	tape.setup_text(tt)
	tape.head_on = true
	tape.show_positions = true
	tape.add_stencil(zt, 0.0)
	tape.head_col = 0.0
	tape.hover_enabled = true
	tape.follow = 0.0
	tape.follow_hi = -1
	tape.scroll = 0.0
	tape.scroll_target = 0.0
	tape.tape_clicked.connect(func(p: int): _toggle(1, p))
	tape.stencil_clicked.connect(func(i: int): _toggle(0, i))


func plate() -> Array:
	return ["MODEL  VIJAND", "TEGENZET"]


func unit() -> Array:
	return ["VIJAND", "enemy"]


func hud_value() -> float:
	return enemy


func fx(f: Dictionary) -> float:
	match str(f.fx):
		"compose":
			var w := str(f.which)
			var i := int(f.i)
			var ch := str(f.ch)
			if w == "z":
				zt = zt.substr(0, i) + ch + zt.substr(i + 1)
				tape.stencils[0].z = zt
			else:
				tt = tt.substr(0, i) + ch + tt.substr(i + 1)
				tape.text = tt
			TxSnd.play("typewriter", -6.0)
			TxSnd.tak(-10.0)
			return d(0.04)
		"enemy_run":
			return _run(f)
	return 0.0


func _run(f: Dictionary) -> float:
	var trace: Array = f.get("trace", [])
	var metric := int(f.metric)
	last_valid = bool(f.get("valid", true))
	running = true
	enemy = 0.0
	TxSnd.play("morse_telex", -6.0)
	var tw := create_tween()
	var step := d(clampf(2.2 / maxf(1, trace.size()), 0.05, 0.25))
	var acc := [0]
	for s in trace:
		var st := 0
		var cmp := int(s.get("cmp", 1))
		match target:
			"brute":
				st = int(s.start)
			"rk_calls":
				st = int(s.i)
			_:
				st = int(s.get("start", int(s.get("i", 0)) - zt.length() + 1))
		tw.tween_callback(func():
			tape.tween_stencil(0, "start", float(st), step * 0.6)
			tape.head_col = float(st)
			acc[0] += cmp
			enemy = float(acc[0]) if target != "rk_calls" else enemy + 1.0
			for k in mini(cmp, 4):
				TxSnd.play("needle_eq", -14.0, 1.0 + 0.05 * k, true)
			con.tick_counter(0))
		tw.tween_interval(step)
	tw.tween_callback(func():
		enemy = float(metric)
		last = metric
		running = false
		if last_valid:
			var better := best < 0 or (metric > best if bool(TARGETS[target][2]) else metric < best)
			if better:
				best = metric
				TxSnd.play("bell", -4.0)
				TxFx.floater(con.fx_layer, global_position + Vector2(700, 160), "nieuw record: %d" % metric, TxPal.SIG_EQ, 30)
			else:
				TxSnd.play("counter_klak", -4.0)
		else:
			TxSnd.play("false_alarm", -6.0)
			TxFx.floater(con.fx_layer, global_position + Vector2(700, 160), "ongeldig: z staat in t", TxPal.SIG_NE, 26)
		tape.tween_stencil(0, "start", 0.0, d(0.3)))
	return step * trace.size() + d(0.4)


func sync(ph: int, c: Dictionary) -> void:
	super.sync(ph, c)
	zt = str(c.get("z", zt))
	tt = str(c.get("t", tt))
	best = int(c.get("best", -1))
	last = int(c.get("last", -1))
	if tape.text != tt:
		tape.text = tt
	if not tape.stencils.is_empty():
		tape.stencils[0].z = zt
	_mark()


func rebuild() -> void:
	sync(mc.phase, mc.cursor())


func _mark() -> void:
	tape.hover_pos = col if row == 1 else -1
	if not tape.stencils.is_empty():
		tape.stencils[0].cur = col if row == 0 else -1


func _toggle(r: int, i: int) -> void:
	if phase != P.COMPOSE or con.input_locked() or running:
		return
	if r == 0 and z_fixed:
		TxSnd.play("bump", -10.0)
		return
	var s := zt if r == 0 else tt
	if i < 0 or i >= s.length():
		return
	row = r
	col = i
	var idx := alphabet.find(s[i])
	var ch := alphabet[(idx + 1) % alphabet.length()]
	move({"act": "set", "which": "z" if r == 0 else "t", "i": i, "ch": ch})
	_mark()


func key(e: InputEventKey) -> bool:
	if phase != P.COMPOSE or running:
		return false
	var kc := e.keycode
	var s := zt if row == 0 else tt
	match kc:
		KEY_TAB:
			row = 1 if row == 0 or z_fixed else 0
			col = mini(col, (zt if row == 0 else tt).length() - 1)
			_mark()
			return true
		KEY_UP:
			if not z_fixed:
				row = 0
				col = mini(col, zt.length() - 1)
				_mark()
			return true
		KEY_DOWN:
			row = 1
			_mark()
			return true
		KEY_RIGHT:
			col = mini(s.length() - 1, col + 1)
			_mark()
			return true
		KEY_LEFT:
			col = maxi(0, col - 1)
			_mark()
			return true
		KEY_SPACE:
			_toggle(row, col)
			return true
		KEY_ENTER, KEY_KP_ENTER:
			move({"act": "send"})
			return true
		KEY_F:
			move({"act": "finish"})
			return true
	var ch := char(e.unicode).to_lower() if e.unicode > 0 else ""
	if ch != "" and alphabet.contains(ch):
		if row == 0 and z_fixed:
			return true
		move({"act": "set", "which": "z" if row == 0 else "t", "i": col, "ch": ch})
		col = mini(s.length() - 1, col + 1)
		_mark()
		return true
	return false


func buttons() -> Array:
	return [{"text": "Verstuur", "key": "Enter", "kind": "brass", "enabled": phase == P.COMPOSE, "call": func(): move({"act": "send"})},
		{"text": "Klaar", "key": "F", "kind": "key", "enabled": best >= 0, "call": func(): move({"act": "finish"})}]


func hint(mv: Dictionary) -> Vector2:
	match str(mv.get("act", "")):
		"set":
			if str(mv.which) == "z":
				return tape.stencil_pos(0, int(mv.i)) + Vector2(0, 30)
			return tape.char_pos(int(mv.i)) + Vector2(0, 30)
		"send":
			return con.button_pos(0)
		"finish":
			return con.button_pos(1)
	return Vector2.INF


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	TxPal.panel(self, r, TxPal.CONSOLE, true, 12)
	var pl := plate()
	TxPal.brass_plate(self, Vector2(180, 42), pl[0], 20, TxPal.STENCIL, TxPanel.sheen(t))
	TxPal.text_l(self, TxPal.STENCIL, Vector2(340, 42), pl[1], 28, TxPal.TEXT)
	var info: Array = TARGETS.get(target, ["", "", true])
	var y := 100.0
	TxPal.text_l(self, TxPal.UI_BOLD, Vector2(30, y), str(info[0]), 24, TxPal.SIG_AMBER)
	y += 40
	var lines := ["Klik een tegel op het lint of het sjabloon om de letter te wisselen.",
		"Tab = rij · ← → = tegel · letter of Spatie = zetten · Enter = verstuur · F = klaar.",
		"m = %d, n = %d, alfabet {%s}%s" % [zt.length(), tt.length(), ", ".join(alphabet.split("")), "  ·  z ligt vast" if z_fixed else ""]]
	for l in lines:
		TxPal.text_l(self, TxPal.UI, Vector2(30, y), l, 20, TxPal.TEXT_DIM)
		y += 30
	# vijandteller
	var cr := Rect2(760, 200, 400, 230)
	TxPal.well(self, cr, TxPal.CONSOLE_LO, 10)
	TxPal.text_c(self, TxPal.STENCIL, Vector2(cr.get_center().x, cr.position.y + 26), "VIJANDIGE MACHINE", 18, TxPal.BRASS)
	TxDraw.counter(self, Vector2(cr.get_center().x - 74, cr.position.y + 50), enemy, 4, "", 30, 44)
	TxPal.text_c(self, TxPal.UI, Vector2(cr.get_center().x, cr.position.y + 130), str(info[1]), 18, TxPal.TEXT_DIM)
	TxPal.text_c(self, TxPal.UI_BOLD, Vector2(cr.get_center().x, cr.position.y + 170), "beste poging: %s" % (str(best) if best >= 0 else "–"), 24, TxPal.SIG_EQ if best >= 0 else TxPal.TEXT_DIM)
	if last >= 0 and not running:
		TxPal.text_c(self, TxPal.UI, Vector2(cr.get_center().x, cr.position.y + 204), "laatste: %d%s" % [last, "" if last_valid else " (ongeldig)"], 18, TxPal.TEXT_DIM)
	# huidige z en t als tegels
	var ty := 330.0
	TxPal.text_l(self, TxPal.TAPE, Vector2(30, ty), "z = " + zt, 26, TxPal.TEXT)
	TxPal.text_l(self, TxPal.TAPE, Vector2(30, ty + 40), "t = " + tt, 26, TxPal.TEXT)
