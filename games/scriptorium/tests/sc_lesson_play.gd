extends SceneTree
## QA-script (Kortschrift, leerpad): speelt ALLE lessen (20 delen × Kijk + Samen) in de echte werkbank uit, zoals een
## tester met `lesson=<deel> phase=… autoplay auto_answer` (Kijk) en `lesson_demo` (Samen: eerst één foute zet per
## soort, dan juist). Per les: de coach verschijnt, de les eindigt (LESSON_DONE) en het deel staat daarna als gedaan.
##
## Gebruik (vanuit de projectmap; headless kan, xvfb-run voor beelden):
##   $G --headless --path . --script res://games/scriptorium/tests/sc_lesson_play.gd -- [parts=huffman,mtf] [speed=6]
## Uitvoer: regels "SCLESSON ..." en een slotregel "SC_LESSON_PLAY ok=<n> fail=<n>". Exitcode 1 bij een fout.

var fails := 0
var oks := 0


func _init() -> void:
	var only := PackedStringArray()
	var spd := 6.0
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("parts="):
			only = s.substr(6).split(",")
		elif s.begins_with("speed="):
			spd = float(s.substr(6))
	var args := ScSession.args()
	args["nosave"] = "1"
	args["auto_answer"] = "1"
	args["save"] = "qa"
	Engine.time_scale = spd
	ScLessons.reset_progress()
	await _frames(2)
	for id in ScLessons.ids():
		if not only.is_empty() and not only.has(id):
			continue
		for ph in ["kijk", "samen"]:
			await _lesson(str(id), ph)
	print("SC_LESSON_PLAY ok=%d fail=%d" % [oks, fails])
	Engine.time_scale = 1.0
	quit(1 if fails > 0 else 0)


func _lesson(id: String, ph: String) -> void:
	var args := ScSession.args()
	args.erase("autoplay")
	args.erase("lesson_demo")
	args[("autoplay" if ph == "kijk" else "lesson_demo")] = "1"
	ScSession.queue_lesson(id, ph)
	ScSession.lesson_return = "map"
	change_scene_to_file(ScSession.SCENE_BENCH)
	await _frames(4)
	var wb = current_scene
	_check(wb != null and wb.get("coach") != null, "%s/%s: werkbank met coach" % [id, ph])
	if wb == null or wb.get("coach") == null:
		return
	var coach: ScLessonCoach = wb.coach
	var t0 := Time.get_ticks_msec()
	var left := false
	# de tutorial van een nieuw werktuig: dicht klikken (die pauzeert de les)
	while Time.get_ticks_msec() - t0 < 120000:
		await _frames(2)
		if not is_instance_valid(coach) or coach._state == "left":
			left = true
			break
		var g := _find_guide(root)
		if g != null:
			g.call("close")
	_check(left, "%s/%s: les speelt tot het einde (%.1f s)" % [id, ph, (Time.get_ticks_msec() - t0) / 1000.0])
	_check(ScLessons.is_done(id, ph), "%s/%s: deel gemarkeerd" % [id, ph])
	# de overgang naar het getijdenboek afwachten (anders vervangt ze de volgende les)
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 8000 and (current_scene == null or current_scene.scene_file_path != ScSession.SCENE_MAP):
		await _frames(2)
	await _frames(10)


func _find_guide(n: Node) -> HubGuide:
	if n is HubGuide and not (n as HubGuide)._closing:
		return n
	for c in n.get_children():
		var r := _find_guide(c)
		if r != null:
			return r
	return null


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(cond: bool, msg: String) -> void:
	if cond:
		oks += 1
		print("SCLESSON ok " + msg)
	else:
		fails += 1
		print("SCLESSON FAIL " + msg)
