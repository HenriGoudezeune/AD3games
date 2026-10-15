extends SceneTree
## QA-muistest: speelt een level enkel met echte muisklikken (Input.warp_mouse + push_input, zoals een mens). Voor
## elke zet vraagt hij het orakel wát er moet gebeuren en klikt op de plek die de tuin daarvoor toont
## (`move_screen_point`: knop op de knoestkrans, kolom van het lint, letter, bol-richting, boogpunt, parel, knop …),
## met een slordige afwijking van `sloppy` px. Daarna controleert hij dat precies die zet (verdict OK) gespeeld werd.
## Gebruik (echte renderer nodig voor de muispositie):
##   xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --audio-driver Dummy \
##     --resolution 1920x1080 --script res://games/trietuin/tests/qa_mouse.gd -- level=2-3 intro=0 sloppy=8
## Uitvoer: "MOUSE …" per zet en "MOUSE_RESULT level=… clicks=… ok=… wrong=… geen_punt=… state=…".

var g: Node
var clicks := 0
var ok := 0
var wrong := 0
var nopoint := 0
var sloppy := 0.0
var rng := RandomNumberGenerator.new()


func _init() -> void:
	await process_frame
	var lvl := TtSession.arg("level", "1-1")
	sloppy = float(TtSession.arg("sloppy", "6"))
	rng.seed = 11
	var max_moves := int(TtSession.arg("moves", "400"))
	g = load(TtSession.SCENE_GARDEN).instantiate()
	root.add_child(g)
	var t0 := Time.get_ticks_msec()
	var moves := 0
	while moves < max_moves and (Time.get_ticks_msec() - t0) < 600000:
		await process_frame
		if str(g.state) in ["bloom", "report"]:
			break
		if str(g.state) != "play" or g.busy or g.model.card == null:
			continue
		var mv: Dictionary = g.model.correct_move()
		if mv.is_empty() or str(mv.get("act", "none")) == "none":
			continue
		await _wait(0.25)
		if g.busy or g.model.card == null:
			continue
		mv = g.model.correct_move()
		var n0: int = g.model.log.entries.size()
		await _play(mv)
		await _wait(0.35)
		moves += 1
		var e: Dictionary = _last_move_entry(n0)
		if e.is_empty():
			wrong += 1
			print("MOUSE ✗ %s: klik deed niets" % str(mv))
		elif int(e.verdict) != TtCodes.Verdict.OK:
			wrong += 1
			print("MOUSE ✗ %s → %s %s" % [str(mv), e.type, TtCodes.verdict_name(int(e.verdict))])
		else:
			ok += 1
	print("MOUSE_RESULT level=%s clicks=%d ok=%d wrong=%d geen_punt=%d state=%s" % [lvl, clicks, ok, wrong, nopoint, g.state])
	quit(0 if wrong == 0 and nopoint == 0 else 1)


func _last_move_entry(n0: int) -> Dictionary:
	var es: Array = g.model.log.entries
	for i in range(es.size() - 1, n0 - 1, -1):
		if not str(es[i].type) in ["CARD_START", "CARD_END", "HINT", "ITERATION", "BLOOM", "LEVEL_END"]:
			return es[i]
	return {}


func _play(mv: Dictionary) -> void:
	match str(mv.act):
		"count":
			for ch in str(int(mv.n)):
				await _click(_cell("num", int(ch)), "cijfer " + ch)
			await _click(_btn("num_ok"), "num_ok")
		"pick":
			for id in mv.leaves:
				await _click(g._w2s(g.view.fruit_center(int(id))), "vrucht %d" % int(id))
			await _click(_btn("pick_ok"), "pick_ok")
		"owner":
			for k in mv.texts:
				await _click(_btn("owner_%d" % int(k)), "eigenaar %d" % int(k))
			await _click(_btn("owner_ok"), "owner_ok")
		_:
			var p: Vector2 = g.move_screen_point(mv)
			if p.x < 0:
				nopoint += 1
				print("MOUSE geen klikpunt voor %s: zet via code" % str(mv))
				g.do_move(mv)
				return
			await _click(p, str(mv))


func _cell(row: String, i: int) -> Vector2:
	for c in g.bench._cells:
		if c.row == row and int(c.i) == i:
			return (c.rect as Rect2).get_center()
	return Vector2(-1, -1)


func _btn(id: String) -> Vector2:
	var b: Button = g.bench.button(id)
	if b == null:
		return Vector2(-1, -1)
	return b.get_global_rect().get_center()


func _click(cp: Vector2, what: String) -> void:
	if cp.x < 0:
		nopoint += 1
		print("MOUSE geen klikpunt: " + what)
		return
	cp += Vector2(rng.randf_range(-sloppy, sloppy), rng.randf_range(-sloppy, sloppy))
	var p: Vector2 = root.get_final_transform() * cp
	Input.warp_mouse(p)
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	root.push_input(mm)
	await _wait(0.12)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		root.push_input(e)
		await _wait(0.06)
	clicks += 1


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout
