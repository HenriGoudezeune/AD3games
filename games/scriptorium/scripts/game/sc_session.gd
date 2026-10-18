class_name ScSession
extends Object
## Kortschrift: gedeelde toestand tussen scènes (static vars blijven bestaan bij een scènewissel), instellingen en de
## commandoregel-opties voor QA (na `--`):
##   level=2-2          start meteen dat level (vanaf title.tscn of workbench.tscn)
##   wake=1             start meteen de Nachtwake (seed=N voor een vaste seed)
##   map=1              open meteen het getijdenboek
##   bot=perfect|first|every|random|act:keep|bump|hint|undo|resume|idle   de core-bot (ScLevelBot) speelt
##   speed=2.0          Engine.time_scale
##   brief=0            geen brief bij de start van een level
##   review=0           geen Kapittel na het level (bots: meteen stoppen)
##   replay=1           Kapittel: open meteen de eerste misstap
##   notes=1            Kapittel: open de notas-weergave
##   pause=1 / sheet=1 / settings=1   open dat scherm na 2 s
##   save=qa            gebruik user://scriptorium_qa.json (raakt de echte opslag niet)
##   unlock=1           alles open (kaart)
##   quit_at=N          stop na N s (echte tijd)
## Leerpad (design/LEARNING_PATH.md):
##   lesson=<deel> [phase=kijk|samen]   speel die les (zonder phase: Kijk en dan Samen); daarna naar level= of de kaart
##   reset_learning     wis de leerpadvoortgang (alle lessen weer "eerste keer": verplicht)
##   no_lessons         geen automatische lessen vóór een level (ook: elke bot=…, de Nachtwake)
##   autoplay           Kijk speelt zelf af · auto_answer: voorspel- en Check-vragen juist beantwoorden
##   lesson_demo        Samen: een gesimuleerde speler (eerst een foute zet per soort, dan juist)
##   lesson_log         regels LESSON_STEP/LESSON_SAY/LESSON_STATE op stdout · lesson_shots=<map>: screenshot bij elke coachtekst
##   guide_page=<tab>:<n>  gids meteen open op die pagina · nosave: leerpadvoortgang enkel in het geheugen
##   check=<level> [check_seed=<n>]  (kaart) open meteen de Check-vragen van dat level · autoquit: afsluiten na de les

const SCENE_TITLE := "res://games/scriptorium/scenes/title.tscn"
const SCENE_MAP := "res://games/scriptorium/scenes/book.tscn"
const SCENE_BENCH := "res://games/scriptorium/scenes/workbench.tscn"

const VIEW_SCRIPTS := {
	"prefix_read": "res://games/scriptorium/scripts/game/sc_view_prefix.gd",
	"code_board": "res://games/scriptorium/scripts/game/sc_view_board.gd",
	"bindery": "res://games/scriptorium/scripts/game/sc_view_bindery.gd",
	"living_tree": "res://games/scriptorium/scripts/game/sc_view_living.gd",
	"ruler": "res://games/scriptorium/scripts/game/sc_view_ruler.gd",
	"window": "res://games/scriptorium/scripts/game/sc_view_window.gd",
	"stampcase": "res://games/scriptorium/scripts/game/sc_view_stamps.gd",
	"drum": "res://games/scriptorium/scripts/game/sc_view_drum.gd",
	"shelf": "res://games/scriptorium/scripts/game/sc_view_shelf.gd",
	"dovecote": "res://games/scriptorium/scripts/game/sc_view_dovecote.gd",
}
const DEFAULTS := {"music": 0.8, "sfx": 0.9, "shake": 1.0, "text": 1.0, "speed": 0, "colorblind": false,
	"guides": false, "fullscreen": false}

static var level_id := "1-1"
static var wake := false
static var map_focus := ""
static var map_stars_before := {}
static var _args := {}
static var _parsed := false
static var _real := 0.0
static var lesson_queue: Array = []      # [{part, phase}] (leerpad)
static var lesson_return := "map"        # "level" | "map" | "quit"
static var _lesson_boot := false


static func args() -> Dictionary:
	if not _parsed:
		_parsed = true
		for a in OS.get_cmdline_user_args():
			var s: String = a.trim_prefix("--")
			if s.contains("="):
				_args[s.get_slice("=", 0)] = s.substr(s.find("=") + 1)
			else:
				_args[s] = "1"
		if _args.has("save"):
			ScSave.path = "user://scriptorium_%s.json" % str(_args.save)
		if _args.has("speed"):
			Engine.time_scale = clampf(float(_args.speed), 0.1, 20.0)
	return _args


static func arg(k: String, def := "") -> String:
	return str(args().get(k, def))


static func has(k: String) -> bool:
	return args().has(k)


static func consume(k: String) -> String:
	var v := arg(k)
	args().erase(k)
	return v


# ------------------------------------------------------------------ instellingen

static func setting(k: String):
	return ScSave.setting(k, DEFAULTS.get(k))


static func set_setting(k: String, v) -> void:
	ScSave.set_setting(k, v)
	apply_all()


static func apply_all() -> void:
	args()
	var ml := Engine.get_main_loop() as SceneTree
	if ml == null:
		return
	var sfx = ml.root.get_node_or_null("Sfx")
	if sfx:
		sfx.music_volume = float(setting("music"))
		sfx.sfx_volume = float(setting("sfx"))
	var juice = ml.root.get_node_or_null("Juice")
	if juice:
		juice.shake_scale = float(setting("shake"))
	if not DisplayServer.get_name().begins_with("headless"):
		var fs := bool(setting("fullscreen"))
		var cur := DisplayServer.window_get_mode()
		var is_fs := cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if fs != is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)


static func shake_scale() -> float:
	return float(setting("shake"))


## Kopiistsnelheid: 1 = normaal, 0,4 = snel.
static func copyist() -> float:
	return 0.4 if int(setting("speed")) == 1 else 1.0


static func guides() -> bool:
	return bool(setting("guides"))


static func colorblind() -> bool:
	return bool(setting("colorblind"))


# ------------------------------------------------------------------ QA

## Stop na quit_at s echte tijd (frame-opnames, bots).
static func qa_tick(delta: float) -> void:
	_real += delta / maxf(Engine.time_scale, 0.001)
	if has("quit_at") and _real >= float(arg("quit_at")):
		var ml := Engine.get_main_loop() as SceneTree
		if ml:
			ml.quit()


static func unlocked(id: String) -> bool:
	if has("unlock"):
		return true
	return ScLevels.is_unlocked(id, ScSave.all_stars())


static func chapter_title(ch: int) -> String:
	if ch < 0:
		return "Nachtwake"
	return ScLevels.CHAPTERS[clampi(ch, 0, 7)]


static func house(ch: int) -> String:
	if ch < 0:
		return "Zuinigem"
	return ScLevels.HOUSES[clampi(ch, 0, 7)]


## Werktuigicoon voor ScDraw.tool_icon.
static func tool_icon(tool_name: String) -> String:
	match tool_name:
		"prefix_read":
			return "codeboom"
		"code_board":
			return "codebord"
		"bindery":
			return "binderij"
		"living_tree":
			return "levende_boom"
		"ruler":
			return "meetlat"
		"window":
			return "leesraam"
		"stampcase":
			return "stempelkast"
		"drum":
			return "draaitrommel"
		"shelf":
			return "letterplank"
		"dovecote":
			return "duiventil"
	return "codex"


static func tool_title(tool_name: String) -> String:
	match tool_name:
		"prefix_read":
			return "De codeboom"
		"code_board":
			return "Het codebord"
		"bindery":
			return "De binderij"
		"living_tree":
			return "De levende boom"
		"ruler":
			return "De meetlat"
		"window":
			return "Het leesraam"
		"stampcase":
			return "De stempelkast"
		"drum":
			return "De draaitrommel"
		"shelf":
			return "De letterplank"
		"dovecote":
			return "De duiventil"
	return ""


# ------------------------------------------------------------------ leerpad (ScLessons, ScLessonCoach)

static func bot_mode() -> String:
	return arg("bot")


## Eén keer per run: reset_learning en lesson=<deel> van de commandoregel verwerken.
static func lesson_boot() -> void:
	if _lesson_boot:
		return
	_lesson_boot = true
	if has("reset_learning"):
		ScLessons.reset_progress()
	if has("lesson") and bot_mode() == "":
		queue_lesson(arg("lesson"), arg("phase", ""))
		lesson_return = "level" if has("level") else ("quit" if has("autoquit") else "map")


static func queue_lesson(part: String, phase: String) -> void:
	lesson_queue.clear()
	if ScLessons.part(part).is_empty():
		push_warning("ScSession: onbekend leerpaddeel %s" % part)
		return
	for ph in (["kijk", "samen"] if phase == "" else [phase]):
		lesson_queue.append({"part": part, "phase": ph})


## Vóór een level: de nog niet gedane delen (eerste keer verplicht). Niet met een bot, de Nachtwake of no_lessons.
static func queue_for_level(id: String) -> void:
	if bot_mode() != "" or has("no_lessons") or wake:
		return
	lesson_queue = ScLessons.pending_for_level(id)
	lesson_return = "level"


static func lessons_on() -> bool:
	return bot_mode() == "" and not lesson_queue.is_empty()


## Gids: "Bekijk de demo opnieuw" / "Oefen dit opnieuw". in_level: daarna terug naar het level van nu.
static func play_lesson(part: String, phase: String, in_level: bool) -> void:
	queue_lesson(part, phase)
	lesson_return = "level" if in_level else "map"
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
	wake = false
	_goto(SCENE_BENCH)


## De coach is klaar met een les: volgende les, het level, de kaart of afsluiten.
static func lesson_done() -> void:
	if not lesson_queue.is_empty():
		lesson_queue.pop_front()
	if not lesson_queue.is_empty() or lesson_return == "level":
		_goto(SCENE_BENCH)
	elif lesson_return == "quit":
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.quit()
	else:
		_goto(SCENE_MAP)


static func _goto(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var tr := tree.root.get_node_or_null("Transition")
	if tr != null:
		tr.call("goto", path)
	else:
		tree.change_scene_to_file(path)
