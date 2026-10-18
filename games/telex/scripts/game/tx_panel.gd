class_name TxPanel
extends Control
## Basis van een machinepaneel in de console. Een paneel tekent zijn machine in het paneelvlak (y 392..860, of het hele
## werkvlak als uses_tape() false is), stuurt het lint (TxTapeView) aan, speelt de animatiebeschrijvingen (fx) af en
## vertaalt muis/toetsen naar zetten (con.move(...)).
##
## De console speelt fx één voor één af: fx(d) geeft de duur (seconden, vóór snelheidsfactor) terug.

const P := TxCodes.Phase
const AREA := Rect2(8, 392, 1904, 470)
const AREA_FULL := Rect2(8, 62, 1904, 800)

static var spd := 1.0                 # animatiesnelheid (console zet dit)

var con: Node                          # TxConsole
var mc: TxMachine
var tape: TxTapeView
var stage: Dictionary = {}
var phase := P.IDLE
var cur: Dictionary = {}
var t := 0.0
var z := ""
var m := 0
var tick_dt := 0.07
var hover_rect := Rect2()              # lokaal klikbaar element onder de muis (oplichtende rand)
var _hov: Control = null
var _mouse_in := false
var _last_mp := Vector2.ZERO


## Glansstreep over een typeplaatje: elke 5 s één keer (binnen de plaat).
static func sheen(tt: float) -> float:
	var u := fmod(tt * 0.3, 1.6)
	return 0.15 + 0.7 * u if u < 1.0 else -1.0


## Duur geschaald met de animatiesnelheid.
static func d(x: float) -> float:
	return x / maxf(0.05, spd)


func setup(console: Node, machine: TxMachine) -> void:
	con = console
	mc = machine
	tape = con.tape
	stage = mc.stage
	z = mc.z
	m = mc.m
	tick_dt = 0.03 if bool(TxSession.setting("fast_needle")) else 0.07
	var full := not uses_tape()
	var r := AREA_FULL if full else AREA
	position = r.position
	size = r.size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_hov = Control.new()
	_hov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hov.size = size
	_hov.draw.connect(_draw_hover)
	add_child(_hov)
	mouse_entered.connect(func(): _mouse_in = true)
	mouse_exited.connect(func():
		_mouse_in = false
		_set_hover({}))
	tape.click_query = tape_clickable
	_setup()


func _setup() -> void:
	pass


func uses_tape() -> bool:
	return true


## Messing typeplaatje + naam.
func plate() -> Array:
	return ["MODEL", "MACHINE"]


## Teller-eenheid in de HUD: ["TIKKEN", "ticks"].
func unit() -> Array:
	return ["TIKKEN", "ticks"]


## Waar de Chef staat (globaal), of Vector2.INF = klein in de hoek.
func chef_anchor() -> Vector2:
	return Vector2(1150, 600)


func _process(dt: float) -> void:
	t += dt
	queue_redraw()
	if _hov != null:
		_hov.queue_redraw()
		if _mouse_in:
			_set_hover(_hot_now(_last_mp), false)


# ---------------------------------------------------------------- muis: klikbare plekken + hover
## Klikbaar element onder het lokale punt p: {"rect": Rect2 (lokaal), "call": Callable} of {} (niets).
## Subklassen beschrijven hier hun hendels, wielen, kaarten, … ; klik en hover gebruiken dezelfde test.
func hot(_p: Vector2) -> Dictionary:
	return {}


## Is een klik op het lint zinvol? kind: "tape" (teken pos), "stencil" (sjabloonletter), "strip" (ponsstrookvakje).
func tape_clickable(_kind: String, _i: int) -> bool:
	return false


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_last_mp = e.position
		_mouse_in = true
		_set_hover(_hot_now(e.position))
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if con == null or not con.can_act():
			return
		var h := hot(e.position)
		if h.has("call"):
			(h.call as Callable).call()
			accept_event()
			_set_hover.call_deferred(_hot_now(e.position))


func _hot_now(p: Vector2) -> Dictionary:
	if con == null or con.input_locked():
		return {}
	return hot(p)


func _set_hover(h: Dictionary, snd := true) -> void:
	var r: Rect2 = h.get("rect", Rect2())
	if snd and r != hover_rect and r.has_area():
		TxSnd.ui("hover")
	hover_rect = r
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if r.has_area() else Control.CURSOR_ARROW


func _draw_hover() -> void:
	if not hover_rect.has_area() or con == null or con.input_locked():
		return
	var a := 0.55 + 0.35 * sin(t * 7.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(TxPal.BRASS_HI, 0.10)
	sb.border_color = Color(TxPal.BRASS_HI, a)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	_hov.draw_style_box(sb, hover_rect.grow(4))


## Een animatiebeschrijving afspelen. -> duur (s, ongeschaald).
func fx(f: Dictionary) -> float:
	match str(f.fx):
		"needle":
			return needle(f)
	return 0.0


func sync(ph: int, c: Dictionary) -> void:
	phase = ph
	cur = c


## Na terugnemen: alles opnieuw opbouwen uit mc.render().
func rebuild() -> void:
	sync(mc.phase, mc.cursor())


func key(_e: InputEventKey) -> bool:
	return false


## Contextknoppen: [{text, key, kind, enabled, call}]
func buttons() -> Array:
	return []


## Toon de juiste zet (hint / tutorial). Geeft een globaal punt voor de spookhand of Vector2.INF.
func hint(_mv: Dictionary) -> Vector2:
	return Vector2.INF


func busy_input() -> bool:
	return false


func move(mv: Dictionary) -> void:
	con.move(mv)


# ---------------------------------------------------------------- gemeenschappelijke naald-animatie
## fx "needle": de naald tikt per stap (head → kolom, slag, lampje, inkt op het lint en het sjabloon).
## si = sjabloon-index op het lint. Geeft de duur.
func needle(f: Dictionary, si := 0) -> float:
	var steps: Array = f.get("steps", [])
	if steps.is_empty():
		return 0.0
	var tw := create_tween()
	var dt := d(tick_dt)
	for s in steps:
		var ti := int(s.ti)
		var zi := int(s.zi)
		var eq := bool(s.eq)
		tw.tween_callback(func():
			tape.head_col = float(ti)
			tape.head_strike = 1.0
			tape.head_lit = "eq" if eq else "ne"
			tape.states[ti] = "eq" if eq else "ne"
			tape.follow = float(ti)
			if si < tape.stencils.size():
				tape.stencils[si].marks[zi] = "eq" if eq else "ne"
				tape.stencils[si].cur = zi
			TxSnd.needle(eq, -6.0 if eq else -3.0)
			con.tick_counter(1)
			if not eq:
				TxFx.sparks(con.fx_layer, tape.char_pos(ti) + Vector2(0, -40), 4)
				TxFx.flash(con.fx_layer, tape.char_pos(ti), TxPal.SIG_NE, 0.6, 0.25))
		tw.tween_method(func(v: float): tape.head_strike = v, 1.0, 0.0, dt)
	if steps.is_empty():
		return 0.0
	match str(f.result):
		"match":
			var n := steps.size()
			tw.tween_callback(func(): _match_wave(steps))
			return dt * n + d(0.25)
		"mismatch":
			tw.tween_callback(func():
				if si < tape.stencils.size():
					tape.stencils[si].cur = -1)
			return dt * steps.size() + d(0.12)
	return dt * steps.size()


func _match_wave(steps: Array) -> void:
	var k := 0
	for s in steps:
		var ti := int(s.ti)
		var tw := create_tween()
		tw.tween_interval(d(0.03 * k))
		tw.tween_callback(func(): TxFx.glints(con.fx_layer, tape.char_pos(ti), TxPal.SIG_EQ, 4))
		k += 1
	var g := create_tween()
	g.tween_method(func(v: float): tape.glow = v, 1.0, 0.0, d(0.6))


## Sjabloon schuift (fx "stencil"): tween start, klak + squash. keep_eq: groene tekens die onder het nieuwe sjabloon
## blijven, behouden (Doorloper: de leeskop gaat niet terug).
func move_stencil(si: int, from: float, to: float, auto: bool, keep_eq := true) -> float:
	var dur := d(0.12 if auto else 0.22)
	if absf(to - from) > 3:
		dur = d(0.28)
	tape.tween_stencil(si, "start", to, dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	var newst := {}
	if keep_eq:
		for p in tape.states:
			if int(p) >= int(to) and tape.states[p] == "eq":
				newst[p] = "eq"
	tape.states = newst
	if si < tape.stencils.size():
		var mk := {}
		if keep_eq:
			for p in newst:
				var zi := int(p) - int(to)
				if zi >= 0 and zi < m:
					mk[zi] = "eq"
		tape.stencils[si].marks = mk
		tape.stencils[si].teeth = {}
	tape.follow = to
	tape.follow_hi = to + m
	var tw := create_tween()
	tw.tween_interval(dur * 0.8)
	tw.tween_callback(func():
		if not auto:
			TxSnd.play("teeth_in", -6.0)
			TxFx.dust(con.fx_layer, tape.stencil_pos(si, 0) + Vector2(-20, 30), 4)
		else:
			TxSnd.play("strip_slide", -16.0, 1.4))
	tw.tween_method(func(v: float): tape.set_stencil(si, "sq", v), 0.92, 1.0, d(0.18)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return dur + (0.0 if auto else d(0.06))


## Leeskop verplaatsen (fx "head"). rewind = terugspoelen (brute kracht).
func move_head(from: float, to: float, rewind: bool) -> float:
	tape.head_lit = ""
	if rewind:
		TxSnd.play("rewind", -8.0, 1.0 + 0.04 * (from - to))
		var tw := create_tween()
		tw.tween_method(func(v: float): tape.head_col = v, from, to, d(0.22)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tape.head_streak = 1.0
		create_tween().tween_property(tape, "head_streak", 0.0, d(0.4))
		con.flash_rewind(int(from - to))
		return d(0.22)
	var tw2 := create_tween()
	tw2.tween_method(func(v: float): tape.head_col = v, from, to, d(0.12))
	if to <= from + 0.01:
		# blijft staan: gloeit warm ("hij gaat niet terug")
		tape.head_warm = 1.0
		create_tween().tween_property(tape, "head_warm", 0.0, d(0.7))
	return d(0.08)


func bump_at(gpos: Vector2, amount := 6) -> void:
	TxSnd.play("bump", -3.0)
	TxFx.sparks(con.fx_layer, gpos, amount)
	TxFx.shake(3.0, 0.12)


## Spookhand op een globaal punt.
func ghost_at(gpos: Vector2) -> Vector2:
	return gpos
