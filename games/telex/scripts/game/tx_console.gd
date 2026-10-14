class_name TxConsole
extends Node2D
## De console (scenes/console.tscn): één scène voor alle levels en de Nachtdienst. Bouwt alles in code: HUD, lint
## (TxTapeView), versnipperaar/inlaat, machinepaneel (TxPanel-subklasse per machine), Chef, onderbalk met dossierkaart,
## kokers, contextknoppen en kustkaartje. Speelt de animatiebeschrijvingen van de core één voor één af (wachtrij),
## zodat elke vergelijking, sprong en lamp zichtbaar en hoorbaar is. GDD §2.2, §4, §7, §8.

const PANELS := {
	TxCodes.Machine.BRUTE: "res://games/telex/scripts/game/tx_needle_panel.gd",
	TxCodes.Machine.KMP: "res://games/telex/scripts/game/tx_needle_panel.gd",
	TxCodes.Machine.BMH: "res://games/telex/scripts/game/tx_needle_panel.gd",
	TxCodes.Machine.KMP_TABLE: "res://games/telex/scripts/game/tx_pons_panel.gd",
	TxCodes.Machine.RABIN_KARP: "res://games/telex/scripts/game/tx_wheel_panel.gd",
	TxCodes.Machine.SHIFT_AND: "res://games/telex/scripts/game/tx_lamp_panel.gd",
	TxCodes.Machine.EDIT: "res://games/telex/scripts/game/tx_board_panel.gd",
	TxCodes.Machine.SABOTAGE: "res://games/telex/scripts/game/tx_sabotage_panel.gd",
}
const MAP_STATION := Vector2(634, 403)
const MAP_CITIES := [Vector2(124, 584), Vector2(219, 543), Vector2(342, 492), Vector2(454, 438), Vector2(566, 383),
	Vector2(695, 326), Vector2(802, 278), Vector2(908, 234), Vector2(1026, 176), Vector2(869, 462)]
const TUBE := Rect2(1700, 410, 196, 430)
const MAP_R := Rect2(1560, 884, 330, 170)

var spec: TxLevelSpec
var dd: TxDirector
var mc: TxMachine
var panel: TxPanel
var tape: TxTapeView
var chef: TxChef
var fx_layer: Node2D
var ui: CanvasLayer
var ui_root: Control
var cam: Camera2D
var back: Node2D
var sides: Node2D
var hud: Node2D
var bottom: Node2D
var btn_box: HBoxContainer
var overlay: Control = null            # briefing / pauze / debrief / keuze
var bot: TxBot = null
var bot_cool := 0.0
var key_bot := false
var key_bot_sent := 0
var key_bot_last := {}
var key_bot_log := -1

var q: Array = []
var busy_t := 0.0
var pending: InputEvent = null
var started := false
var ended := false
var report: Dictionary = {}
var t := 0.0

# HUD-toestand
var ticks_shown := 0.0
var ticks_target := 0
var unit_label := "TIKKEN"
var unit_key := "ticks"
var counters := {}
var rewind_shown := 0
var rewind_flash := 0.0
var trust := 3
var trust_fade := 0.0
var points := 0
var stars_possible := 3
var combo := 1
var found: Array = []                  # labels van kokers
var tube_u := -1.0
var tube_label := ""
var shred_spin := 0.0
var shred_red := 0.0
var shred_fill := 0.15
var inlet_hammer := 0.0
var inlet_roll := 0.0
var warn := 0.0
var front_f := 0.0
var map_events: Array = []             # [{kind, to: Vector2, u, life}]
var full_tape := true
var hint_hand := {}                    # {pos, life}
var _tutorial_done := {}
var _idle := 0.0
var _hint_nudged := false
var _last_front := 0
var _stage_n := 0
var _panel_slide := 0.0


func _ready() -> void:
	TxSession.apply_all()
	var id := TxSession.level_id
	if id == "":
		id = TxSession.arg("level", "1-1")
	TxSession.level_id = id
	if id.begins_with("N"):
		var variant := "kmp" if id.ends_with("kmp") else "bmh"
		TxSession.endless_variant = variant
		var seed_ := int(TxSession.arg("seed", str(int(Time.get_unix_time_from_system()) % 100000)))
		spec = TxLevels.endless_spec(0, seed_, variant)
	else:
		spec = TxLevels.get_spec(id)
		if spec == null:
			spec = TxLevels.get_spec("1-1")
	TxPanel.spd = TxSession.anim_speed()
	_build()
	if TxSession.bot_mode() == "keys":
		key_bot = true
	elif TxSession.bot_mode() != "":
		var bm := TxSession.bot_mode()
		bot = TxBot.new("" if bm == "perfect" else bm, int(TxSession.arg("seed", "1")))
		bot.think = 0.0
	if TxSession.has("skip_brief") or ((bot != null or key_bot) and not TxSession.has("brief")):
		_begin()
	else:
		_show_briefing()
	TxSnd.music("live" if spec.mode == TxCodes.Mode.LIVE else "calm")
	if spec.live.has("bpm"):
		TxSnd.music("rhythm")


func _exit_tree() -> void:
	if dd != null:
		dd.dispose()
	TxSnd.loop("shred", "shredder_loop", false)
	TxSnd.loop("alarm", "alarm_loop", false)
	TxSnd.loop("hum", "lamp_hum_loop", false)
	TxSnd.lowpass(false)
	Engine.time_scale = 1.0


# ================================================================ opbouw
func _build() -> void:
	cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(cam)
	cam.make_current()
	var j := TxSession._node("Juice")
	if j != null:
		j.set("camera", cam)
	back = Node2D.new()
	back.draw.connect(_draw_back)
	add_child(back)
	tape = TxTapeView.new()
	add_child(tape)
	sides = Node2D.new()
	sides.draw.connect(_draw_sides)
	add_child(sides)
	chef = TxChef.new()
	add_child(chef)
	bottom = Node2D.new()
	bottom.draw.connect(_draw_bottom)
	add_child(bottom)
	btn_box = HBoxContainer.new()
	btn_box.position = Vector2(470, 924)
	btn_box.add_theme_constant_override("separation", 14)
	add_child(btn_box)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud)
	add_child(hud)
	fx_layer = Node2D.new()
	fx_layer.z_index = 20
	add_child(fx_layer)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	ui_root = Control.new()
	ui_root.size = Vector2(1920, 1080)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = TxPal.theme()
	ui.add_child(ui_root)
	TxUi.overlay(self, 60)


func _begin() -> void:
	if started:
		return
	started = true
	dd = TxDirector.new()
	dd.stage_started.connect(_on_stage_started)
	dd.level_finished.connect(func(r): q.append({"k": "finish", "report": r}))
	dd.choice_needed.connect(func(i, opts, st): q.append({"k": "choice", "options": opts, "stage": st}))
	dd.live_warning.connect(_on_live_warning)
	dd.lives_changed.connect(func(l): q.append({"k": "lives", "lives": l}))
	dd.tape_started.connect(func(i, s): q.append({"k": "tape", "index": i, "spec": s}))
	dd.beat.connect(_on_beat)
	if bool(TxSession.setting("tempo80")) and spec.mode == TxCodes.Mode.LIVE:
		dd.tempo = 0.8
		dd.assisted = true
	dd.start(spec)
	dd.scoring.points_changed.connect(_on_points)
	dd.scoring.combo_changed.connect(func(c): combo = c)
	dd.scoring.full_power.connect(_full_power)
	if spec.story.has("chef_intro") or spec.intro != "":
		var line := str(spec.story.get("chef_intro", spec.intro))
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_callback(func(): chef.say(line, 5.0))


func _on_stage_started(i: int, machine: TxMachine) -> void:
	machine.changed.connect(func(f): _enqueue_fx(f))
	machine.counters_changed.connect(func(c): q.append({"k": "counters", "c": c}))
	machine.consequence.connect(func(ev): q.append({"k": "conseq", "ev": ev}))
	machine.event_logged.connect(func(e): q.append({"k": "event", "e": e}))
	machine.phase_changed.connect(func(ph, c): q.append({"k": "phase", "phase": ph, "cur": c}))
	q.append({"k": "stage", "mc": machine, "i": i})


func _enqueue_fx(f: Dictionary) -> void:
	match str(f.fx):
		"front":
			_last_front = int(f.to)
			tape.front = int(f.to)
			inlet_hammer = 1.0
			TxSnd.tak(-14.0)
			return
		"shred":
			tape.shred = int(f.upto)
			TxFx.snippets(fx_layer, Vector2(150, 150), 5)
			return
	q.append({"k": "fx", "f": f})


# ================================================================ wachtrij
func is_busy() -> bool:
	return busy_t > 0.0 or not q.is_empty()


func can_act() -> bool:
	return not input_locked() and (not is_busy() or spec.mode == TxCodes.Mode.LIVE)


func input_locked() -> bool:
	return overlay != null or not started or ended or dd == null or not dd.pending_choice.is_empty()


func _process(dt: float) -> void:
	t += dt
	var real_dt := dt / maxf(Engine.time_scale, 0.001)
	# director-klok (LIVE en tijdsterren); niet tijdens briefing/pauze
	if started and not ended and overlay == null and dd != null:
		dd.tick(dt)
		front_f = dd.front_f
	# wachtrij afspelen
	var spd := 1.0
	if pending != null or q.size() > 24:
		spd = 3.0
	if spec.mode == TxCodes.Mode.LIVE:
		spd = maxf(spd, 2.2 if q.size() < 8 else 4.0)
	busy_t -= dt * spd
	var guard := 0
	while busy_t <= 0.0 and not q.is_empty() and guard < 200:
		guard += 1
		var it: Dictionary = q.pop_front()
		busy_t += _dispatch(it) / spd
	if busy_t < 0.0:
		busy_t = 0.0
	if not is_busy() and pending != null:
		var e := pending
		pending = null
		_route_input(e)
	# invoer-bot (bot=keys): speelt de juiste zet via gesimuleerde toetsen (test de echte invoerpaden)
	if key_bot and started and not ended and dd != null and not dd.finished and pending == null:
		bot_cool -= dt
		if bot_cool <= 0.0 and (not is_busy() or spec.mode == TxCodes.Mode.LIVE):
			bot_cool = 0.3 / TxPanel.spd
			if spec.mode == TxCodes.Mode.LIVE:
				bot_cool = 0.5
			if overlay == null or overlay is TxChoice:
				_key_bot_step()
	# bot
	if bot != null and started and not ended and overlay == null and (not is_busy() or spec.mode == TxCodes.Mode.LIVE) and dd != null and not dd.finished:
		bot_cool -= dt
		if bot_cool <= 0.0:
			var did := bot.step(dd, dt)
			bot_cool = 0.32 / TxPanel.spd if did else 0.05
			if spec.mode == TxCodes.Mode.LIVE:
				bot_cool = 0.6 if did else 0.02
	# idle-hint (eerste keer na 6 s niets doen)
	if started and not ended and overlay == null and bot == null and not is_busy():
		_idle += dt
		if _idle > 7.0 and not _hint_nudged and dd != null and spec.hints_allowed:
			_hint_nudged = true
			chef.say("Vast? F1 toont de juiste zet (kost ★★★).", 4.0)
	# animatievelden
	if panel != null and panel.has_method("hud_value"):
		ticks_target = int(panel.hud_value())
		ticks_shown = panel.hud_value()
	ticks_shown = move_toward(ticks_shown, float(ticks_target), real_dt * maxf(8.0, absf(ticks_target - ticks_shown) * 6.0))
	rewind_flash = maxf(0.0, rewind_flash - real_dt * 1.5)
	trust_fade = maxf(0.0, trust_fade - real_dt * 2.0)
	shred_red = maxf(0.0, shred_red - real_dt * 1.2)
	inlet_hammer = maxf(0.0, inlet_hammer - real_dt * 8.0)
	var live_run := spec.mode == TxCodes.Mode.LIVE and started and not ended
	shred_spin += real_dt * (6.0 if live_run else 0.6)
	inlet_roll -= real_dt * (3.0 if live_run else 0.0)
	warn = maxf(0.0, warn - real_dt * 0.8)
	if warn <= 0.0:
		TxSnd.lowpass(false)
	for e in map_events:
		e.u = minf(1.0, float(e.u) + real_dt * 0.5)
	if not hint_hand.is_empty():
		hint_hand.life = float(hint_hand.life) - real_dt
		if float(hint_hand.life) <= 0.0:
			hint_hand = {}
			tape.ghost_hand = {}
	back.queue_redraw()
	sides.queue_redraw()
	hud.queue_redraw()
	bottom.queue_redraw()
	_refresh_buttons_state()


func _dispatch(it: Dictionary) -> float:
	match str(it.k):
		"stage":
			return _set_stage(it.mc, int(it.i))
		"fx":
			return _fx(it.f)
		"phase":
			if panel != null:
				panel.sync(int(it.phase), it.cur)
			_rebuild_buttons()
			_tutorial(int(it.phase))
			return 0.0
		"counters":
			counters = it.c
			ticks_target = int(counters.get(unit_key, 0))
			if absf(ticks_shown - ticks_target) > 30:
				ticks_shown = float(ticks_target)
			rewind_shown = int(counters.get("rewind", 0))
			return 0.0
		"conseq":
			return _conseq(it.ev)
		"event":
			_event(it.e)
			return 0.0
		"finish":
			_finish(it.report)
			return 0.0
		"choice":
			_show_choice(it.options, it.stage)
			return 0.0
		"lives":
			trust = int(it.lives)
			return 0.0
		"tape":
			chef.say("Nieuw lint: %s." % str((it.spec as TxLevelSpec).stages[0].z), 2.5)
			TxSnd.play("morse_telex", -6.0)
			return 0.3
	return 0.0


func _set_stage(machine: TxMachine, i: int) -> float:
	mc = machine
	_stage_n += 1
	var old := panel
	var path: String = PANELS.get(machine.kind, PANELS[TxCodes.Machine.BRUTE])
	var scr: Script = load(path) if ResourceLoader.exists(path) else load(PANELS[TxCodes.Machine.BRUTE])
	var np: TxPanel = scr.new()
	panel = np
	add_child(np)
	move_child(np, sides.get_index() + 1)
	np.setup(self, machine)
	full_tape = np.uses_tape()
	tape.visible = full_tape
	sides.visible = full_tape
	var un: Array = np.unit()
	unit_label = str(un[0])
	unit_key = str(un[1])
	ticks_target = int(machine.counters.get(unit_key, 0))
	ticks_shown = float(ticks_target)
	var anchor := np.chef_anchor()
	if anchor == Vector2.INF:
		chef.anchor = Vector2(1830, 800)
		chef.small = true
		chef.balloon_up = true
	else:
		chef.anchor = anchor
		chef.small = false
		chef.balloon_up = np.has_method("balloon_up")
	_rebuild_buttons()
	if old != null:
		var tw := old.create_tween()
		tw.tween_property(old, "modulate:a", 0.0, TxPanel.d(0.25))
		tw.tween_callback(old.queue_free)
		np.modulate.a = 0.0
		np.position.y += 40
		var tw2 := np.create_tween().set_parallel(true)
		tw2.tween_property(np, "modulate:a", 1.0, TxPanel.d(0.35)).set_delay(TxPanel.d(0.15))
		tw2.tween_property(np, "position:y", np.position.y - 40, TxPanel.d(0.4)).set_delay(TxPanel.d(0.15)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		TxSnd.play("relay", -4.0)
		TxSnd.play("strip_slide", -8.0, 0.8)
		return TxPanel.d(0.45)
	return 0.0


# ================================================================ fx
func _fx(f: Dictionary) -> float:
	var dur := 0.0
	if panel != null:
		dur = panel.fx(f)
	match str(f.fx):
		"hit":
			dur = maxf(dur, _hit_fx(f))
		"missed":
			dur = maxf(dur, _missed_fx(f))
		"false_alarm":
			dur = maxf(dur, _false_fx(f))
		"tear":
			TxSnd.play("tear", 0.0)
			TxFx.splinters(fx_layer, Vector2(200, 150), 16)
			TxFx.shake(5.0, 0.25)
			shred_red = 0.5
			dur = maxf(dur, TxPanel.d(0.35))
		"restore":
			if panel != null:
				panel.rebuild()
			TxSnd.play("rewind", -6.0, 1.3)
		"abort":
			chef.say("Machinetijd op. De rest blijft onverwerkt.", 3.5, true)
			TxSnd.play("missed", -4.0, 0.8)
			dur = maxf(dur, TxPanel.d(0.4))
	return dur


func _hit_fx(f: Dictionary) -> float:
	var real := bool(f.get("real", true))
	var a := int(f.start)
	var b := int(f.end)
	if not real:
		return 0.0
	if full_tape and tape.text.length() > b:
		tape.hits.append([a, b])
	var label := "%s @%d" % [mc.z if mc != null else "?", a]
	if mc is TxEditBoard:
		label = "%s @%d" % [mc.t.substr(a, b - a + 1), a]
	if mc is TxRabinKarp and (mc as TxRabinKarp).signal_mode():
		label = "%s ✓" % mc.z
	var from := tape.char_pos((a + b) / 2.0) if full_tape else Vector2(900, 300)
	if panel != null and panel.has_method("hit_origin"):
		from = panel.hit_origin(f)
	_fly_capsule(from, label)
	TxSnd.play("bell", -2.0, 1.0 - 0.06 * int(f.get("level", 0)), false)
	TxFx.ring(fx_layer, from, TxPal.SIG_EQ, 0.3, 3.0, 0.5)
	TxFx.floater(fx_layer, from + Vector2(0, -60), "+100", TxPal.SIG_EQ, 34)
	TxFx.punch(0.012)
	TxFx.hitstop(0.05)
	if not _tutorial_done.has("first_hit"):
		_tutorial_done["first_hit"] = true
		for tu in spec.tutorial:
			if str(tu.get("trigger", "")) == "first_hit":
				chef.say(str(tu.text), 4.0)
	return TxPanel.d(0.55)


func _fly_capsule(from: Vector2, label: String) -> void:
	var fl := Node2D.new()
	fl.z_index = 30
	fx_layer.add_child(fl)
	var st := {"p": from, "ang": 0.0, "s": 0.6}
	fl.draw.connect(func(): TxDraw.capsule(fl, st.p, st.ang, label, st.s))
	var to := Vector2(TUBE.get_center().x, TUBE.end.y - 110)
	var tw := fl.create_tween()
	tw.tween_method(func(u: float):
		st.p = from.lerp(to, u) + Vector2(0, -260 * u * (1.0 - u))
		st.ang = lerpf(0.0, PI / 2, u)
		st.s = lerpf(0.7, 0.85, u)
		fl.queue_redraw(), 0.0, 1.0, TxPanel.d(0.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		fl.queue_free()
		TxSnd.play("tube_fwoop", -2.0)
		TxSnd.play("stamp", -8.0)
		tube_label = label
		found.append(label))
	tw.tween_method(func(u: float): tube_u = u, 0.0, 1.0, TxPanel.d(0.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): tube_u = -1.0)


func _missed_fx(f: Dictionary) -> float:
	var a := int(f.start)
	var b := int(f.end)
	if full_tape and tape.text.length() > b:
		tape.missed.append([a, b])
	shred_red = 1.0
	TxFx.snippets(fx_layer, Vector2(150, 200), 18, true)
	TxSnd.play("missed", -2.0)
	TxFx.shake(4.0, 0.25)
	return TxPanel.d(0.5)


func _false_fx(f: Dictionary) -> float:
	var a := int(f.start)
	var b := int(f.end)
	if full_tape and tape.text.length() > b and a >= 0:
		tape.falses.append([a, b])
	TxSnd.play("false_alarm", -3.0)
	TxFx.shake(3.0, 0.2)
	return TxPanel.d(0.45)


func _conseq(ev: Dictionary) -> float:
	match str(ev.kind):
		"missed":
			if not spec.endless:
				trust = maxi(0, trust - 1)
			trust_fade = 1.0
			map_events.append({"kind": "courier", "to": MAP_CITIES[randi() % MAP_CITIES.size()], "u": 0.0})
			chef.say("Die is weg. De koerier vertrekt.", 3.0, true)
		"false_alarm":
			if not spec.endless:
				trust = maxi(0, trust - 1)
			trust_fade = 1.0
			map_events.append({"kind": "car", "to": MAP_CITIES[randi() % MAP_CITIES.size()], "u": 0.0})
			chef.say("Vals alarm. De ploeg rijdt naar een verkeerd adres.", 3.0, true)
		"tear":
			chef.say("Het lint scheurt! Sneller beslissen.", 2.5, true)
	return 0.0


func _event(e: Dictionary) -> void:
	if not bool(e.ok) or bool(e.auto):
		return
	_idle = 0.0
	var v := int(e.verdict)
	if v != TxCodes.Verdict.OK and v != TxCodes.Verdict.BUMP:
		stars_possible = mini(stars_possible, 1)


func _on_points(total: int, delta: int, reason: String) -> void:
	points = total
	if delta == 10 or delta == 20 or delta == 30 or delta == 40:
		var p := tape.head_pos() + Vector2(46, 30) if full_tape else Vector2(1700, 120)
		TxFx.floater(fx_layer, p, "+%d" % delta, TxPal.BRASS_HI, 20, 30, 0.55)


func _full_power() -> void:
	TxSnd.play("combo", 0.0)
	TxFx.hitstop(0.08)
	chef.say("Volle stroom!", 1.8)
	TxFx.ring(fx_layer, Vector2(960, 200), TxPal.SIG_AMBER, 0.5, 6.0, 0.6)


func _on_live_warning(secs: float) -> void:
	if warn < 0.5:
		TxSnd.play("heartbeat", -6.0, 1.0, false, 400)
	warn = 1.0
	TxSnd.lowpass(true)


func _on_beat(_j: int) -> void:
	if panel != null and panel.has_method("beat"):
		panel.beat()


func live_v() -> float:
	return float(spec.live.get("v", 0.0)) * (dd.tempo if dd != null else 1.0)


func tick_counter(n: int) -> void:
	if unit_key == "ticks":
		ticks_shown = floor(ticks_shown) + n
		ticks_target = maxi(ticks_target, int(ticks_shown))
	if int(ticks_shown) % 10 == 0:
		TxSnd.play("counter_klak", -12.0)
	else:
		TxSnd.play("counter_click", -18.0)


func flash_rewind(n: int) -> void:
	rewind_flash = 1.0
	rewind_shown += maxi(0, n)


# ================================================================ zetten, invoer
func move(mv: Dictionary) -> void:
	if input_locked() or dd == null:
		return
	_idle = 0.0
	tape.ghost_hand = {}
	hint_hand = {}
	var r := dd.apply(mv)
	if not bool(r.get("ok", false)):
		if str(r.get("reason", "")) != "no_mesh":
			pass


func do_hint() -> void:
	if input_locked() or dd == null or not spec.hints_allowed:
		return
	var mv := dd.hint()
	if mv.is_empty():
		return
	stars_possible = mini(stars_possible, 2)
	TxSnd.play("plus_one", -6.0, 0.8)
	_show_ghost(mv, 4.0)
	chef.say(_hint_text(mv), 3.5)


func _show_ghost(mv: Dictionary, secs: float) -> void:
	if panel == null:
		return
	var p := panel.hint(mv)
	if p != Vector2.INF:
		hint_hand = {"pos": p, "life": secs}


func _hint_text(mv: Dictionary) -> String:
	match str(mv.get("act", "")):
		"shift":
			return "Verschuif %d." % int(mv.s)
		"jump":
			return "Spring %d." % int(mv.s)
		"key":
			return "Trek de kaart van t[%d]." % int(mv.pos)
		"stamp":
			return "Stempel positie %d." % int(mv.i)
		"strip":
			return "Gebruik de strook."
		"punch":
			return "Pons %d in vakje %d." % [int(mv.v), int(mv.j)]
		"punch_to":
			return "Pons tot vakje %d met waarde %d." % [int(mv.to), int(mv.v)]
		"wheel":
			return {"double": "Eerst ×2.", "minus_w": "Nu −w: het uitgaande bit is 1.", "plus1": "+1: dat bit is 1."}.get(str(mv.op), "Draai het wiel.")
		"next_bit", "commit", "slide":
			return "De stand klopt: bevestig."
		"verify":
			return "Controleer het woord."
		"lever":
			return "Eerst de hendel: alles één omlaag."
		"card":
			return "Kaart %s." % (str(mv.x) if str(mv.x) != "" else "blanco")
		"hole":
			return "Kaart %s: gat op rij %d." % [str(mv.x), int(mv.i)]
		"plug":
			return "Kabel in oud ↓."
		"fill":
			return {"diag": "Neem ↖.", "up": "Neem ↑.", "left": "Neem ←."}.get(str(mv.dir), "")
		"step":
			return {"diag": "Terug langs ↖.", "up": "Terug langs ↑.", "left": "Terug langs ←."}.get(str(mv.dir), "")
		"pick_end":
			return "Het minimum staat in kolom %d." % int(mv.j)
		"set":
			return "Zet %s[%d] op %s." % [str(mv.which), int(mv.i), str(mv.ch)]
		"send":
			return "Verstuur het lint."
		"finish":
			return "Klaar: rond af."
		"choose":
			return "Stuur de ploeg naar @%d." % int(mv.start)
		"pick_machine":
			return "Neem de %s." % str(TxLevels.MACHINE_LABELS.get(str(mv.machine), mv.machine))
	return "Kijk naar de knop die oplicht."


func do_undo() -> void:
	if input_locked() or dd == null:
		return
	if dd.undo():
		stars_possible = mini(stars_possible, 2)
	else:
		TxSnd.play("bump", -10.0, 0.7)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if overlay != null:
			if overlay.has_method("key") and overlay.key(e):
				get_viewport().set_input_as_handled()
			return
		if e.keycode == KEY_ESCAPE:
			if panel != null and panel.key(e):
				get_viewport().set_input_as_handled()
				return
			_show_pause()
			get_viewport().set_input_as_handled()
			return
		if is_busy() and spec.mode != TxCodes.Mode.LIVE:
			pending = e
			get_viewport().set_input_as_handled()
			return
		_route_input(e)
		get_viewport().set_input_as_handled()


func _route_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or input_locked():
		return
	var k := e as InputEventKey
	if k.keycode == KEY_F1:
		do_hint()
		return
	if k.keycode == KEY_Z and k.ctrl_pressed:
		do_undo()
		return
	if panel != null and panel.key(k):
		_idle = 0.0
		return


# ================================================================ knoppen
var _btns: Array = []


func _rebuild_buttons() -> void:
	for c in btn_box.get_children():
		c.queue_free()
	_btns = []
	if panel == null:
		return
	var defs: Array = panel.buttons()
	for bd in defs:
		var b := TxUi.key_button(str(bd.text), str(bd.key), str(bd.get("kind", "key")), 230.0 if defs.size() < 4 else 190.0, 24)
		var cb: Callable = bd.call
		b.pressed.connect(func():
			if can_act():
				cb.call())
		b.disabled = not bool(bd.get("enabled", true))
		btn_box.add_child(b)
		_btns.append(b)
	if spec.mode == TxCodes.Mode.CALM:
		var u := TxUi.key_button("Terugnemen", "Ctrl+Z", "key", 190.0, 22)
		u.pressed.connect(do_undo)
		u.set_meta("undo", true)
		btn_box.add_child(u)
	var h := TxUi.key_button("Hint", "F1", "flat", 130.0, 22)
	h.pressed.connect(do_hint)
	btn_box.add_child(h)


func _refresh_buttons_state() -> void:
	for c in btn_box.get_children():
		if c is Button and c.has_meta("undo"):
			(c as Button).disabled = dd == null or not dd.can_undo()


func button_pos(i: int) -> Vector2:
	if i < _btns.size() and is_instance_valid(_btns[i]):
		var b: Button = _btns[i]
		return b.global_position + Vector2(b.size.x * 0.5, 20)
	return Vector2(600, 950)


# ================================================================ tutorial
func _tutorial(ph: int) -> void:
	if bot != null:
		return
	for tu in spec.tutorial:
		var trig := str(tu.get("trigger", ""))
		if _tutorial_done.has(trig):
			continue
		var fire := false
		if trig == "first_ready" and ph == TxCodes.Phase.READY:
			fire = true
		elif trig == "first_decide" and ph == TxCodes.Phase.DECIDE:
			fire = true
		if fire:
			_tutorial_done[trig] = true
			if tu.has("text"):
				chef.say(str(tu.text), 5.0)
			if tu.has("ghost"):
				_show_ghost(tu.ghost, 5.0)


# ================================================================ tekenen
func _draw_back() -> void:
	TxUi.draw_bunker(back, 0.0)
	if full_tape:
		TxPal.panel(back, Rect2(8, 62, 1904, 326), TxPal.CONSOLE, true, 12)
		TxPal.well(back, Rect2(150, 76, 1620, 304), TxPal.CONSOLE_LO, 8)
	TxPal.panel(back, Rect2(8, 866, 1904, 208), TxPal.CONSOLE_HI, true, 12)


func _draw_sides() -> void:
	TxDraw.shredder(sides, 166, TxPal.Y_TAPE, shred_spin, shred_red, shred_fill + 0.02 * float(tape.shred if tape.shred > 0 else 0))
	TxDraw.inlet(sides, 1714, TxPal.Y_TAPE, inlet_hammer, inlet_roll)
	if not hint_hand.is_empty():
		var p: Vector2 = hint_hand.pos
		TxPal.ghost_hand(sides, p + Vector2(0, sin(t * 6.0) * 6.0), 1.1, TxPal.SIG_BLUE, 0.9)


func _draw_hud() -> void:
	var c := hud
	TxDraw.hud_bar(c, 1920, 58)
	TxDraw.keycap(c, Vector2(14, 12), "II", 18)
	var dn := "NACHTDIENST" if spec.endless else ("FINALE" if spec.dossier == 9 else "DOSSIER %d" % spec.dossier)
	var x := TxPal.text_l(c, TxPal.STENCIL, Vector2(64, 29), dn, 22, TxPal.BRASS) + 78
	var ttl := spec.title if spec.endless else "%s  %s" % [spec.id, spec.title]
	x += TxPal.text_l(c, TxPal.UI_BOLD, Vector2(x, 29), ttl, 24, TxPal.TEXT) + 22
	var zs := mc.z if mc != null else str(spec.stages[0].get("z", spec.stages[0].get("a", "")))
	if zs != "" and x < 860:
		TxPal.text_l(c, TxPal.UI, Vector2(x, 29), "z =", 20, TxPal.TEXT_DIM)
		var chip := TxDraw.word_chip(c, Vector2(x + 38, 11), zs if zs.length() <= 12 else zs.substr(0, 11) + "…", 22)
		x = chip.end.x + 14
		if mc != null and mc.t != "" and not (mc is TxEditBoard) and not (mc is TxSabotage) and x < 900:
			TxPal.text_l(c, TxPal.UI, Vector2(x, 29), "alle voorkomens" if mc.find == TxCodes.Find.ALL else "eerste voorkomen", 18, TxPal.TEXT_DIM)
	if spec.mode == TxCodes.Mode.LIVE:
		TxPal.text_l(c, TxPal.UI_BOLD, Vector2(1010, 29), "LIVE", 18, TxPal.SIG_AMBER)
		TxPal.lamp(c, Vector2(1074, 29), 7, TxPal.SIG_AMBER, 0.5 + 0.5 * sin(t * 6.0))
		if combo > 1:
			TxPal.text_l(c, TxPal.UI_BOLD, Vector2(960, 29), "×%d" % combo, 22, TxPal.SIG_EQ)
	TxDraw.counter(c, Vector2(1240, 4), ticks_shown, 4, unit_label, 24, 36)
	var g := int(spec.ghost.get("brute_ticks", -1))
	if g > 0 and unit_key in ["ticks", "lamps"] and not spec.endless:
		TxDraw.ghost_bar(c, Rect2(1390, 14, 200, 30), ticks_shown, g)
	TxDraw.trust(c, Vector2(1620, 29), trust, trust_fade)
	TxDraw.stars(c, Vector2(1730, 29), stars_possible, 22)
	TxPal.text_r(c, TxPal.MONO, Vector2(1906, 29), "%d" % points, 18, TxPal.BRASS_HI)
	if warn > 0.0:
		c.draw_rect(Rect2(0, 58, 1920, 4), Color(TxPal.SIG_AMBER, warn * (0.5 + 0.5 * sin(t * 18.0))))


func _draw_bottom() -> void:
	var c := bottom
	if panel != null and panel.chef_anchor() != Vector2.INF and full_tape:
		TxDraw.tube(c, TUBE, tube_u, tube_label)
	var st: Dictionary = mc.stage if mc != null else spec.stages[0]
	var fields: Array = []
	if st.has("z") and str(st.z) != "":
		fields.append(["z =", str(st.z)])
	if st.has("a"):
		fields.append(["rijen:", str(st.a)])
		fields.append(["kolommen:", str(st.b)])
	if st.has("q"):
		fields.append(["q =", str(st.q)])
	if int(st.get("k", 0)) > 0:
		fields.append(["k =", str(st.k)])
	if st.has("t") and str(st.t) != "":
		fields.append(["lint:", "%d tekens" % str(st.t).length()])
	if mc != null and mc.t != "" and not (mc is TxEditBoard) and not (mc is TxSabotage):
		fields.append(["modus:", "alle voorkomens" if mc.find == TxCodes.Find.ALL else "eerste voorkomen"])
	while fields.size() > 4:
		fields.pop_back()
	TxDraw.dossier_card(c, Rect2(24, 880, 400, 180), "OPDRACHT  %s" % (spec.id if not spec.endless else "N"), fields, spec.notes_ref)
	TxPal.text_l(c, TxPal.STENCIL, Vector2(452, 896), "GEVONDEN", 18, TxPal.TEXT_DIM)
	var fx0 := 560.0
	var shown := 0
	for i in range(maxi(0, found.size() - 3), found.size()):
		TxPal.text_l(c, TxPal.TAPE, Vector2(fx0 + shown * 0.0, 896), "", 1, TxPal.TEXT)
		shown += 1
	var lbl := " · ".join(found.slice(maxi(0, found.size() - 4))) if not found.is_empty() else "nog geen kokers"
	TxPal.text_l(c, TxPal.TAPE, Vector2(560, 896), lbl, 17, TxPal.SIG_BLUE.lightened(0.3) if not found.is_empty() else TxPal.TEXT_DIM)
	# kustkaartje met spelden, koeriers en de ploeg
	var pins: Array = [[MAP_STATION, TxPal.BRASS]]
	for e in map_events:
		var to: Vector2 = e.to
		pins.append([MAP_STATION.lerp(to, float(e.u)), TxPal.SIG_NE if str(e.kind) == "courier" else TxPal.SIG_GREY])
	TxDraw.mini_map(c, MAP_R, pins)
	for e in map_events:
		var to2: Vector2 = e.to
		var mp := MAP_STATION.lerp(to2, float(e.u))
		var q2 := MAP_R.position + (mp - Vector2(300, 150)) / Vector2(700, 440) * MAP_R.size
		if str(e.kind) == "courier":
			TxDraw.courier(c, q2 + Vector2(0, -6), 0.42, Color("#121416"), t * 6.0)
		else:
			TxDraw.car(c, q2 + Vector2(0, -4), 0.5, 0.5 + 0.5 * sin(t * 10.0))


# ================================================================ schermen
func _show_briefing() -> void:
	var b := TxBriefing.new()
	b.setup(spec)
	overlay = b
	ui_root.add_child(b)
	b.closed.connect(func():
		overlay = null
		_begin())


func _show_pause() -> void:
	if overlay != null or ended:
		return
	var p := TxPause.new()
	p.setup(self)
	overlay = p
	ui_root.add_child(p)
	get_tree().paused = false
	TxSnd.duck(true)
	p.closed.connect(func():
		overlay = null
		TxSnd.duck(false))


func restart() -> void:
	Transition.goto(TxSession.SCENE_CONSOLE)


func to_map() -> void:
	Transition.goto(TxSession.SCENE_MAP)


func _show_choice(options: PackedStringArray, st: Dictionary) -> void:
	if bot != null:
		return
	if overlay != null:
		return
	var ch := TxChoice.new()
	ch.setup(self, options, st)
	overlay = ch
	ui_root.add_child(ch)
	ch.picked.connect(func(machine: String):
		overlay = null
		dd.apply({"act": "pick_machine", "machine": machine}))


func _finish(r: Dictionary) -> void:
	if ended:
		return
	ended = true
	report = r
	if not spec.endless and not TxSession.has("nosave"):
		TxSave.record(spec.id, r)
	if TxSession.has("print_report"):
		var mis := PackedStringArray()
		for x in r.get("mistakes", []):
			mis.append(str(x.verdict_name))
		print("TXREPORT %s stars=%d points=%d found=%d missed=%d false=%d bumps=%d counters=%s mistakes=%s time=%.1f" % [
			spec.id, int(r.n_stars), int(r.points), int(r.found), (r.missed as Array).size(), (r.false_alarms as Array).size(),
			int(r.bumps), str(r.counters), ",".join(mis), float(r.time_s)])
	if TxSession.has("autoquit"):
		var tq := create_tween()
		tq.tween_interval(2.5)
		tq.tween_callback(func(): get_tree().quit())
	TxSnd.lowpass(false)
	TxSnd.loop("alarm", "alarm_loop", false)
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		var db := TxDebrief.new()
		db.setup(self, r)
		overlay = db
		ui_root.add_child(db))


# ================================================================ invoer-bot (QA)
func _kev(code: int, uni := 0) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.unicode = uni
	e.pressed = true
	return e


func _send(code: int, uni := 0) -> void:
	Input.parse_input_event(_kev(code, uni))
	key_bot_sent += 1


func _key_bot_step() -> void:
	var mv := dd.correct_move()
	var act := str(mv.get("act", "none"))
	if act == "none":
		return
	if mv == key_bot_last and key_bot_sent > 0 and dd.log.size() == key_bot_log:
		key_bot_last = {}
		push_warning("TELEX keys-bot: zet herhaald (invoer werkte niet?): %s" % str(mv))
		print("KEYBOT-STUCK %s %s" % [spec.id, str(mv)])
	key_bot_last = mv.duplicate()
	key_bot_log = dd.log.size()
	var p := panel
	match act:
		"pick_machine":
			var ch := overlay as TxChoice
			if ch != null:
				var i := ch.options.find(str(mv.machine))
				_send(KEY_1 + i)
		"go", "next":
			_send(KEY_SPACE)
		"shift":
			if p is TxPonsPanel:
				_send(KEY_0 + int(mv.s))
				_send(KEY_ENTER)
			else:
				_send(KEY_0 + int(mv.s))
				_send(KEY_ENTER)
		"strip":
			_send(KEY_V)
		"jump":
			if str(p.stage.get("cards", "")) == "none":
				var s_: int = int(mv.s)
				if s_ == p.m:
					_send(KEY_SPACE)
				else:
					var ch2: String = p.z[p.m - 1 - s_]
					_send(KEY_A, ch2.unicode_at(0))
			else:
				for k in int(mv.s):
					_send(KEY_RIGHT)
				_send(KEY_ENTER)
		"key":
			if int(mv.pos) == (p as TxNeedlePanel).bmh_i:
				_send(KEY_K)
			else:
				(p as TxNeedlePanel).key_sel = int(mv.pos)
				_send(KEY_ENTER)
		"stamp":
			(p as TxNeedlePanel).stamp_sel = int(mv.i)
			_send(KEY_ENTER)
		"cards_done", "wire_done", "done":
			_send(KEY_D)
		"punch":
			_send(KEY_0 + int(mv.v))
			_send(KEY_P)
		"punch_to":
			var pp := p as TxPonsPanel
			pp.b_sel = int(mv.to)
			pp.v_sel = int(mv.v)
			pp._upd_punch()
			_send(KEY_P)
		"wheel":
			_send({"double": KEY_D, "minus_w": KEY_W, "plus1": KEY_1}[str(mv.op)])
		"commit", "next_bit", "slide":
			_send(KEY_ENTER)
		"verify":
			_send(KEY_C)
		"hole":
			var lp := p as TxLampPanel
			lp.card_sel = lp.letters.find(str(mv.x))
			lp.row_sel = int(mv.i)
			_send(KEY_SPACE)
		"plug":
			_send(KEY_1 + TxCodes.PLUGS.find(str(mv.src)))
		"lever":
			_send(KEY_S)
		"card":
			var x := str(mv.x)
			if x == "":
				_send(KEY_SPACE)
			else:
				_send(KEY_A, x.unicode_at(0))
		"choose":
			var lp2 := p as TxLampPanel
			_send(KEY_1 + lp2.choose_starts.find(int(mv.start)))
		"fill", "step":
			_send({"diag": KEY_Q, "up": KEY_W, "left": KEY_A}[str(mv.dir)])
		"pick_end":
			(p as TxBoardPanel).end_sel = int(mv.j)
			_send(KEY_ENTER)
		"trace_again":
			_send(KEY_R)
		"finish":
			if p is TxSabotagePanel:
				_send(KEY_F)
			else:
				_send(KEY_ENTER)
		"set":
			var sp := p as TxSabotagePanel
			sp.row = 0 if str(mv.which) == "z" else 1
			sp.col = int(mv.i)
			var c2 := str(mv.ch)
			_send(KEY_A, c2.unicode_at(0))
		"send":
			_send(KEY_ENTER)
		_:
			print("KEYBOT-UNKNOWN %s" % str(mv))
