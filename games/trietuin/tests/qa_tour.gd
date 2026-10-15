extends SceneTree
## QA-rondleiding met echte muis-/toetsinvoer (root.push_input): hub → Trietuin-kaart → titel → Spelen →
## seizoenkaart → pot 1-1 → intro-kaart → tuin → Esc (pauze) → Seizoenkaart → Notas (spiekbriefje) → Esc → titel →
## Esc → hub. Elke stap controleert de actieve scène. Gebruik:
##   xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --audio-driver Dummy \
##     --resolution 1920x1080 --script res://games/trietuin/tests/qa_tour.gd
## (niet --headless: daar is het venster 64×64 en hebben ankers-volle overlays geen grootte)
## Exitcode 0 = alle stappen OK.

var fails := 0


func _init() -> void:
	await process_frame
	change_scene_to_file("res://scenes/hub.tscn")
	await _wait(2.0)
	_check("hub", "hub.tscn")
	var card := _find_button(func(b: Button) -> bool:
		for c in b.get_children():
			if c is Label and (c as Label).text.contains("Patricia"):
				return true
		return false)
	await _click_control(card, "hub: Trietuin-kaart")
	await _wait(2.6)
	_check("titel", "trietuin/scenes/title.tscn")
	await _click_control(_find_button(func(b: Button) -> bool: return b.text == "Spelen"), "titel: Spelen")
	await _wait(1.6)
	_check("kaart", "season_map.tscn")
	var map: Node = current_scene
	await _click_at(map.pots["1-1"], "kaart: pot 1-1")
	await _wait(1.6)
	_check("tuin", "garden.tscn")
	var g: Node = current_scene
	print("TOUR tuin state=%s (intro verwacht)" % g.state)
	await _click_at(Vector2(960, 600), "intro-kaart wegklikken")
	await _wait(1.5)
	print("TOUR tuin state=%s (play verwacht)" % g.state)
	if str(g.state) != "play":
		fails += 1
	await _key(KEY_ESCAPE, "tuin: Esc")
	await _wait(0.8)
	print("TOUR pauzemenu open: %s" % str(g._pause_menu != null))
	if g._pause_menu == null:
		fails += 1
	await _click_control(_find_button(func(b: Button) -> bool: return b.text == "Seizoenkaart"), "pauze: Seizoenkaart")
	await _wait(2.0)
	_check("kaart (na pauze)", "season_map.tscn")
	await _click_control(_find_button(func(b: Button) -> bool: return b.text == "Notas"), "kaart: Notas")
	await _wait(1.0)
	print("TOUR spiekbriefje open: %s" % str(current_scene._sheet != null))
	await _key(KEY_ESCAPE, "spiekbriefje: Esc")
	await _wait(1.0)
	print("TOUR spiekbriefje dicht: %s" % str(current_scene._sheet == null))
	await _key(KEY_ESCAPE, "kaart: Esc")
	await _wait(2.6)
	_check("titel (Esc)", "trietuin/scenes/title.tscn")
	await _key(KEY_ESCAPE, "titel: Esc")
	await _wait(1.6)
	_check("hub (Esc)", "hub.tscn")
	print("TOUR_RESULT fails=%d" % fails)
	quit(1 if fails > 0 else 0)


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _check(what: String, path_part: String) -> void:
	var p := current_scene.scene_file_path if current_scene else "<geen>"
	var ok := p.contains(path_part)
	if not ok:
		fails += 1
	print("TOUR %-22s %s  (%s)" % [what, "OK" if ok else "FOUT", p])


func _find_button(pred: Callable) -> Button:
	for n in root.find_children("*", "Button", true, false):
		var b := n as Button
		if b.is_visible_in_tree() and pred.call(b):
			return b
	return null


func _click_control(c: Control, what: String) -> void:
	if c == null:
		fails += 1
		print("TOUR knop niet gevonden: " + what)
		return
	await _click_at(c.get_global_rect().get_center(), what)


func _click_at(cp: Vector2, what: String) -> void:
	var p: Vector2 = root.get_final_transform() * cp   # canvas (1920×1080) → venstercoördinaten
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	root.push_input(mm)
	await _wait(0.15)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		root.push_input(e)
		await _wait(0.08)
	print("TOUR klik %s @ %s" % [what, str(cp)])


func _key(k: int, what: String) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = pressed
		root.push_input(e)
		await _wait(0.05)
	print("TOUR toets %s" % what)
