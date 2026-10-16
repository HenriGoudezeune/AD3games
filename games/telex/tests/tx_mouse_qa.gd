extends SceneTree
## QA-script (telex): speelt levels ENKEL MET DE MUIS (echte InputEventMouseButton/Motion via Viewport.push_input),
## zoals een student. Standaard via Input.parse_input_event in venstercoördinaten (de echte
## route van het besturingssysteem; draai bij voorkeur zonder --headless onder xvfb-run): klik waar de spookhand (panel.hint) wijst, sleep het sjabloon voor verschuivingen/sprongen,
## en klik knoppen op hun echte plek. Controleert na elke klik dat de director de verwachte zet kreeg.
## Optioneel ook de schermroute titel → kaart → level → debrief → notas → kaart → titel → hub (tour).
##
## Gebruik (vanuit de projectmap):
##   $G --headless --path . --fixed-fps 30 --script res://games/telex/tests/tx_mouse_qa.gd -- levels=3-1,4-1,5-1,7-1 nosave
##   $G --headless --path . --fixed-fps 30 --script res://games/telex/tests/tx_mouse_qa.gd -- tour tourlevel=3-1
## Uitvoer: regels "MOUSE <level> ..." en een slotregel "MOUSE_QA ok=<n> fail=<n>". Exitcode 1 bij een fout.

var fails := 0
var oks := 0
var shots := ""
var every := 5
var nmoves := 0
var verbose := false
const EAGER_ACTS := ["next", "wheel", "next_bit", "card", "lever", "fill", "step", "set", "hole"]
var eager_clicks := 0
var eager := false       # "eager": klik ook tijdens animaties (zoals een ongeduldige speler); test de klikbuffer
var push_mode := false   # "push": oude route via Viewport.push_input (omzeilt Input en venstertransformatie)


func _init() -> void:
	var levels := PackedStringArray()
	var tour := false
	var tour_level := "1-1"
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("levels="):
			levels = s.substr(7).split(",")
		elif s == "eager":
			eager = true
		elif s == "verbose":
			verbose = true
		elif s == "push":
			push_mode = true
		elif s == "tour":
			tour = true
		elif s.begins_with("tourlevel="):
			tour_level = s.substr(10)
		elif s.begins_with("shots="):
			shots = s.substr(6)
		elif s.begins_with("every="):
			every = maxi(1, int(s.substr(6)))
	await _frames(2)
	if tour:
		await _tour(tour_level)
	for id in levels:
		await _play_level(id)
	if hover_ok + hover_bad > 0:
		print("MOUSE hover-feedback op %d/%d klikdoelen" % [hover_ok, hover_ok + hover_bad])
		_check(hover_bad == 0, "elk klikdoel toont hover-feedback (%d zonder)" % hover_bad)
	print("MOUSE_QA ok=%d fail=%d" % [oks, fails])
	quit(1 if fails > 0 else 0)


# ---------------------------------------------------------------- hulpjes
func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(sec: float) -> void:
	var t0 := Time.get_ticks_msec()
	var f := int(sec * 30.0)
	await _frames(maxi(1, f))


func _scene() -> Node:
	return current_scene


## Canvascoördinaat (1920×1080) → venstercoördinaat, zoals het besturingssysteem ze aanlevert.
func _win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


func _send(ev: InputEvent) -> void:
	if push_mode:
		root.push_input(ev, true)
		return
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _motion(p: Vector2, rel := Vector2.ZERO, pressed := false) -> void:
	var m := InputEventMouseMotion.new()
	var w := p if push_mode else _win(p)
	m.position = w
	m.global_position = w
	m.relative = rel
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_send(m)


func _button(p: Vector2, pressed: bool) -> void:
	var b := InputEventMouseButton.new()
	var w := p if push_mode else _win(p)
	b.position = w
	b.global_position = w
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pressed
	b.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	_send(b)


## Hover-controle: wijst de muis op p naar iets dat er klikbaar uitziet (handcursor of sleepcursor)?
var hover_ok := 0
var hover_bad := 0


func _hover_feedback() -> bool:
	var c := root.gui_get_hovered_control()
	while c != null:
		if c.mouse_default_cursor_shape in [Control.CURSOR_POINTING_HAND, Control.CURSOR_DRAG]:
			return true
		if c.mouse_filter != Control.MOUSE_FILTER_PASS:
			break
		c = c.get_parent() as Control
	return false


func click(p: Vector2, check_hover := false) -> void:
	_motion(p + Vector2(3, 0))
	await _frames(1)
	_motion(p, Vector2(-3, 0))
	await _frames(2)
	if check_hover:
		if _hover_feedback():
			hover_ok += 1
		else:
			hover_bad += 1
			var hc := root.gui_get_hovered_control()
			print("MOUSE geen hover-feedback op (%d, %d): %s" % [int(p.x), int(p.y), str(hc.get_path()) if hc else "niets"])
	_button(p, true)
	await _frames(2)
	_button(p, false)
	await _frames(2)


func drag(from: Vector2, to: Vector2, steps := 12) -> void:
	_motion(from)
	await _frames(1)
	_button(from, true)
	await _frames(1)
	var last := from
	for i in steps:
		var p := from.lerp(to, float(i + 1) / steps)
		_motion(p, p - last, true)
		last = p
		await _frames(1)
	await _frames(2)
	_button(to, false)
	await _frames(2)


func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).visible and (n as Button).text.contains(text):
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null


func click_button(text: String) -> bool:
	var b := _find_button(root, text)
	if b == null:
		print("MOUSE knop '%s' niet gevonden" % text)
		return false
	await click(b.get_global_rect().get_center())
	return true


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(shots.path_join(name + ".png"))


func _check(cond: bool, msg: String) -> void:
	if cond:
		oks += 1
	else:
		fails += 1
		print("MOUSE FAIL " + msg)


func _find_guide(n: Node) -> HubGuide:
	if n is HubGuide and not (n as HubGuide)._closing:
		return n
	for c in n.get_children():
		var r := _find_guide(c)
		if r != null:
			return r
	return null


func _guide_open() -> HubGuide:
	return _find_guide(root)


## Tutorial/gids sluiten zoals een speler: klik "Aan de slag!" (laatste kaartje) of "Sluiten".
var guides_closed := 0


func _close_guide_by_mouse() -> void:
	var g := _guide_open()
	if g == null:
		return
	await _wait(0.3)
	var b := _find_button(g, "Aan de slag")
	if b == null:
		b = _find_button(g, "Sluiten")
	_check(b != null, "gids heeft een klikbare sluitknop")
	if b != null:
		await click(b.get_global_rect().get_center(), true)
	await _wait(0.4)
	_check(_guide_open() == null, "gids sluit met een muisklik")
	guides_closed += 1


# ---------------------------------------------------------------- schermroute
func _tour(id: String) -> void:
	change_scene_to_file("res://scenes/hub.tscn")
	await _wait(1.5)
	_check(_scene() != null and _scene().scene_file_path == "res://scenes/hub.tscn", "hub geladen")
	# kaart TELEX in de hub (kaarten zijn knoppen zonder tekst, in de volgorde van HubRegistry.available())
	var idx := -1
	var av := HubRegistry.available()
	for i in av.size():
		if str(av[i].id) == "telex":
			idx = i
	var hc: Array = _scene().get("_cards")
	_check(idx >= 0 and idx < hc.size(), "TELEX-kaart in de hub")
	await click((hc[idx] as Control).get_global_rect().get_center())
	await _wait(2.5)
	_check(_scene().scene_file_path.ends_with("telex/scenes/title.tscn"), "hub → titel (%s)" % _scene().scene_file_path)
	await _shot("tour_title")
	_check(await click_button("Theorie"), "knop Theorie op de titel")
	await _wait(0.6)
	_check(_guide_open() != null, "Theorie op de titel opent de gids")
	await _shot("tour_title_theory")
	await _close_guide_by_mouse()
	await click_button("Diensten")
	await _wait(1.5)
	_check(_scene().scene_file_path.ends_with("map.tscn"), "titel → kaart via klik op Diensten")
	await _shot("tour_map")
	_check(await click_button("Theorie"), "knop Theorie op de missiekaart")
	await _wait(0.6)
	_check(_guide_open() != null, "Theorie op de kaart opent de gids")
	await _close_guide_by_mouse()
	var mp := _scene()
	var d := TxLevels.dossier_of(id)
	mp.call("_open", d)
	await _wait(0.6)
	var cards: Array = mp.get("_cards")
	var target := Vector2.INF
	for c in cards:
		if str(c.id) == id:
			target = (c.rect as Rect2).get_center()
	_check(target != Vector2.INF, "kaartje %s zichtbaar op de kaart" % id)
	await click(target)
	await _wait(1.5)
	_check(_scene().scene_file_path.ends_with("console.tscn"), "kaart → console via klik op kaartje")
	await _shot("tour_briefing")
	if shots != "":
		await _wait(0.6)
		await _shot("%s_brief" % id)
	await click_button("Start dienst")
	await _wait(0.5)
	# eerste keer deze machine: tutorial (kaartjes) → sluiten met de muis
	await _shot("tour_tutorial")
	await _close_guide_by_mouse()
	# "?" in de HUD opent de gids
	_check(await click_button("?"), "knop ? in de HUD")
	await _wait(0.5)
	_check(_guide_open() != null, "klik op ? opent de gids")
	await _shot("tour_guide")
	await _close_guide_by_mouse()
	# pauze met de muis: knop II in de HUD, dan "Verder"
	var con0 = _scene()
	_check(await click_button("II"), "pauzeknop II in de HUD")
	await _wait(0.4)
	_check(con0.overlay != null and str(con0.overlay.get_script().resource_path).ends_with("tx_pause.gd"), "klik op II opent de pauze")
	await _shot("tour_pause")
	_check(await click_button("Uitleg & theorie"), "pauze: knop Uitleg & theorie")
	await _wait(0.5)
	_check(_guide_open() != null, "pauze → gids")
	await _close_guide_by_mouse()
	_check(_find_button(root, "Naar levelkeuze") != null and _find_button(root, "Naar speelhal") != null, "pauze: Naar levelkeuze + Naar speelhal")
	await click_button("Verder")
	await _wait(0.4)
	_check(con0.overlay == null, "klik op Verder sluit de pauze")
	nmoves = 0
	await _play_current(id)
	if shots != "":
		await _wait(4.0)
		await _shot("%s_debrief" % id)
		if await click_button("Notas-weergave"):
			await _wait(0.8)
			await _shot("%s_notes" % id)
	await _wait(3.0)
	await _shot("tour_debrief")
	var okn := await click_button("Notas-weergave")
	_check(okn, "knop Notas-weergave")
	await _wait(0.8)
	await _shot("tour_notes")
	await click_button("Sluiten")
	await _wait(0.4)
	await click_button("Missiekaart")
	await _wait(1.5)
	_check(_scene().scene_file_path.ends_with("map.tscn"), "debrief → kaart via Missiekaart")
	var k := InputEventKey.new()
	k.keycode = KEY_ESCAPE
	k.pressed = true
	_send(k)
	await _wait(1.5)
	_check(_scene().scene_file_path.ends_with("title.tscn"), "kaart → titel via Esc")
	await click_button("Alle games")
	await _wait(1.5)
	_check(_scene().scene_file_path == "res://scenes/hub.tscn", "titel → hub via ← Alle games")


# ---------------------------------------------------------------- level met de muis
func _play_level(id: String) -> void:
	TxSession.level_id = id
	change_scene_to_file("res://games/telex/scenes/console.tscn")
	await _wait(1.0)
	if shots != "":
		await _wait(0.6)
		await _shot("%s_brief" % id)
	await click_button("Start dienst")
	await _wait(0.5)
	nmoves = 0
	await _play_current(id)
	if shots != "":
		await _wait(4.0)
		await _shot("%s_debrief" % id)
		if await click_button("Notas-weergave"):
			await _wait(0.8)
			await _shot("%s_notes" % id)


func _play_current(id: String) -> void:
	var con = _scene()
	var guard := 0
	var stuck := 0
	var acts := {}
	while is_instance_valid(con) and not bool(con.get("ended")) and guard < 600:
		guard += 1
		await _frames(1)
		if not con.started or con.dd == null:
			continue
		if _guide_open() != null:
			await _close_guide_by_mouse()
			continue
		if con.overlay != null and not (con.overlay is TxChoice):
			continue
		if con.overlay == null and con.is_busy() and not eager:
			continue
		var dd: TxDirector = con.dd
		if dd.finished:
			break
		var mv: Dictionary = dd.correct_move()
		var act := str(mv.get("act", "none"))
		if act == "none":
			await _frames(3)
			continue
		if con.is_busy() and not (act in EAGER_ACTS):
			continue
		if con.is_busy():
			eager_clicks += 1
		var before := dd.log.size()
		if shots != "" and nmoves % every == 0:
			await _shot("%s_%03d" % [id, nmoves])
		nmoves += 1
		var how := await _do_mouse(con, mv)
		if verbose:
			print("MOUSE %s #%d %s via %s" % [id, nmoves, str(mv), how])
		await _frames(6)
		if eager:
			while not (con.get("_mouse_q") as Array).is_empty() or (dd.log.size() <= before and con.is_busy()):
				await _frames(1)
		else:
			while con.is_busy():
				await _frames(1)
		var got := dd.log.entry(before) if dd.log.size() > before else {}
		var got_act := str(got.get("data", {}).get("move", {}).get("act", got.get("type", ""))) if not got.is_empty() else ""
		var ok := not got.is_empty() and int(got.verdict) == TxCodes.Verdict.OK and bool(got.ok)
		if not ok:
			stuck += 1
			print("MOUSE %s zet %s via %s → %s" % [id, str(mv), how,
				"niets gebeurd" if got.is_empty() else "%s verdict=%s" % [str(got.type), TxCodes.verdict_name(int(got.verdict))]])
			if stuck >= 3:
				_check(false, "%s: muis kan zet %s niet uitvoeren (%s)" % [id, str(mv), how])
				# terugvallen op de director zodat de rest getest wordt
				dd.apply(mv)
				stuck = 0
		else:
			stuck = 0
			acts[act] = int(acts.get(act, 0)) + 1
	var wr := 0
	while is_instance_valid(con) and (con.get("report") as Dictionary).is_empty() and wr < 600:
		wr += 1
		await _frames(1)
	if eager:
		print("MOUSE %s: %d klikken tijdens een animatie (gebufferd)" % [id, eager_clicks])
	var rep: Dictionary = con.get("report") if is_instance_valid(con) else {}
	print("MOUSE %s klaar: zetten %s, sterren %d" % [id, str(acts), int(rep.get("n_stars", -1))])
	if verbose and not rep.is_empty():
		var mis := PackedStringArray()
		for x in rep.get("mistakes", []):
			mis.append(str(x.get("verdict_name", x)))
		print("MOUSE %s rapport: bumps=%d fouten=%s sterren=%s" % [id, int(rep.get("bumps", 0)), ",".join(mis), str(rep.get("stars", ""))])
	_check(not rep.is_empty(), "%s eindigt met een rapport" % id)
	if eager:
		# ongeduldig klikken mag trager uitvallen (tijdster), maar nooit tot fouten of botsingen leiden
		_check((rep.get("mistakes", [1]) as Array).is_empty() and int(rep.get("bumps", 1)) == 0,
			"%s: gebufferde klikken geven geen fouten/botsingen" % id)
	else:
		_check(int(rep.get("n_stars", 0)) == 3 or id == "5-3", "%s: muisspel geeft 3 sterren (kreeg %d)" % [id, int(rep.get("n_stars", 0))])


## Voert één zet uit met de muis. -> beschrijving van wat er geklikt werd.
func _do_mouse(con, mv: Dictionary) -> String:
	var p: TxPanel = con.panel
	var tape: TxTapeView = con.tape
	var act := str(mv.act)
	if act == "pick_machine":
		var lab := str(TxLevels.MACHINE_LABELS.get(str(mv.machine), mv.machine))
		var bt := _find_button(con.overlay if con.overlay != null else root, lab)
		if bt == null:
			return "keuze: knop %s niet gevonden" % lab
		await click(bt.get_global_rect().get_center(), true)
		return "keuze: klik %s" % lab
	# sjabloon slepen: verschuiving (Doorloper, spiegelrit) en sprong (Springer met kaartenbak)
	if (act == "shift" and (p is TxNeedlePanel or p is TxPonsPanel)) or (act == "jump" and p is TxNeedlePanel):
		var s := int(mv.s)
		var from := tape.stencil_pos(0, 0) + Vector2(tape.cell * 0.5, 30)
		await drag(from, from + Vector2(s * tape.cell, 0))
		return "sleep sjabloon %d kolommen" % s
	if act == "punch" and p is TxPonsPanel:
		var v := int(mv.v)
		var from2 := tape.stencil_pos(0, 0) + Vector2(tape.cell * 0.5, 30)
		await drag(from2, from2 + Vector2(v * tape.cell, 0))
		await click(tape.strip_pos(int(mv.j)) + Vector2(0, 10), true)
		return "sleep kopie %d + klik vakje %d" % [v, int(mv.j)]
	if act == "punch_to" and p is TxPonsPanel:
		var pp := p as TxPonsPanel
		await click(tape.strip_pos(int(mv.to)) + Vector2(0, 10), true)
		var g := 0
		while pp.v_sel != int(mv.v) and g < 12:
			g += 1
			await click_button("Waarde +" if pp.v_sel < int(mv.v) else "Waarde −")
		await click_button("Pons")
		return "klik vakje %d, waarde %d, Pons" % [int(mv.to), int(mv.v)]
	var h: Vector2 = p.hint(mv)
	if h == Vector2.INF:
		return "geen hint-punt"
	# valt het punt op een contextknop? dan klikken we die knop (zoals een speler die de spookhand volgt)
	await click(h, true)
	return "klik spookhand (%d, %d)" % [int(h.x), int(h.y)]
