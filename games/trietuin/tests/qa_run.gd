extends SceneTree
## QA-runner (headless): speelt één level in de echte tuin-scène met de front-end-bot en drukt het rapport af.
## Gebruik: $G --headless --path . --script res://games/trietuin/tests/qa_run.gd -- level=2-2 bot=errors speed=8
## Uitvoer: één regel "QA_RESULT level=… bot=… stars=… honey=… mistakes=… bloom=… t=…" (+ coachzinnen per misstap).
## Exitcode 0 = rapport bereikt, 1 = time-out (vastloper).

var garden: Node


func _init() -> void:
	await process_frame
	var lvl := TtSession.arg("level", "1-1")
	var botm := TtSession.arg("bot", "perfect")
	var limit := float(TtSession.arg("limit", "900"))
	garden = load(TtSession.SCENE_GARDEN).instantiate()
	root.add_child(garden)
	var t0 := Time.get_ticks_msec()
	while str(garden.state) != "report":
		await process_frame
		if (Time.get_ticks_msec() - t0) / 1000.0 > limit:
			print("QA_RESULT level=%s bot=%s TIMEOUT state=%s card=%s" % [lvl, botm, garden.state,
				str(garden.model.card.word) if garden.model.card else "-"])
			quit(1)
			return
	await create_timer(0.5).timeout
	var rep: Dictionary = garden.director.report if garden.director.get("report") != null else {}
	if rep.is_empty() and garden._report:
		rep = garden._report.rep
	var log: TtEventLog = garden.model.log
	var mis := log.mistakes(garden.spec.count_bumps)
	var bl: Array = rep.get("bloom", [])
	var nok := 0
	for b in bl:
		if bool(b.get("ok", true)):
			nok += 1
	print("QA_RESULT level=%s bot=%s stars=%s honey=%d mistakes=%d bloom=%d/%d sap=%d t=%.0f" % [lvl, botm,
		str(rep.get("stars", [])), int(rep.get("honey", 0)), mis.size(), nok, bl.size(), int(rep.get("sap_used", -1)),
		float(rep.get("time", -1.0))])
	for e in mis:
		print("  MIS %s %s | %s | %s" % [e.type, TtCodes.verdict_name(int(e.verdict)), log.coach_line(e), log.notes_ref(e)])
	for b in bl:
		if not bool(b.get("ok", true)):
			print("  BLOOM_FAIL %s cause_seq=%s" % [str(b.get("word", "")), str(b.get("cause_seq", -1))])
	quit(0)
