class_name TxSession
extends Object
## Toestand tussen scènes + commandoregel-opties (na `--`) + instellingen toepassen.
##
## Opties (QA / opnames):
##   level=3-1        start meteen dit level (titel → console). "N" = Nachtdienst, "N:kmp" = Doorloper-variant.
##   bot=perfect      de console speelt zelf met TxBot (perfect | first | every | random | act:<act> | plug:<src> |
##                    bump | hint | undo | idle)
##   seed=7           seed voor bot=random en de Nachtdienst
##   speed=2          animatiesnelheid (bots)
##   skip_brief       briefing overslaan
##   debrief=auto     na het level de debrief automatisch doorlopen (herbeleving van de eerste misstap)
##   map              start op de missiekaart
##   screen=settings|notes   open meteen dat scherm (titel)
##   unlock           alle levels open (enkel deze sessie)
##   quit_after_level na de debrief afsluiten
## Leerpad (design/LEARNING_PATH.md):
##   lesson=<deel> [phase=kijk|samen]   speel die les (zonder phase: Kijk en dan Samen); daarna naar level= of de kaart
##   reset_learning     wis de leerpadvoortgang (alle lessen weer "eerste keer": verplicht)
##   no_lessons         geen automatische lessen vóór een level (ook: elke bot=…)
##   autoplay           Kijk speelt zelf af · auto_answer = voorspel-/checkvragen juist beantwoorden
##   lesson_demo        Samen: een gesimuleerde speler (eerst een foute zet per soort, dan juist)
##   lesson_log         regels LESSON_STEP/LESSON_SAY/LESSON_STATE op stdout · lesson_shots=<map>: screenshot bij elke coachtekst
##   check=<level>      (missiekaart): de Check-vragen van dat level · guide_page=<tab>:<n> (console): gids meteen open

const SCENE_TITLE := "res://games/telex/scenes/title.tscn"
const SCENE_MAP := "res://games/telex/scenes/map.tscn"
const SCENE_CONSOLE := "res://games/telex/scenes/console.tscn"

static var level_id := ""
static var endless_variant := "bmh"
static var from_map_dossier := -1        # map: welke dossiermap stond open
static var _args := {}
static var _parsed := false
static var _consumed := {}
static var unlock_all := false
static var lesson_queue: Array = []      # [{part, phase}] (leerpad)
static var lesson_return := "map"        # "level" | "map" | "quit"
static var _lesson_boot := false


static func _parse() -> void:
	if _parsed:
		return
	_parsed = true
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var eq := s.find("=")
		if eq > 0:
			_args[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			_args[s] = "1"
	unlock_all = _args.has("unlock")


static func has(k: String) -> bool:
	_parse()
	return _args.has(k)


static func arg(k: String, def := "") -> String:
	_parse()
	return str(_args.get(k, def))


## Eenmalige optie (bv. level= bij de eerste titelstart): true de eerste keer.
static func take(k: String) -> bool:
	_parse()
	if _args.has(k) and not _consumed.has(k):
		_consumed[k] = true
		return true
	return false


static func bot_mode() -> String:
	return arg("bot", "")


static func anim_speed() -> float:
	return maxf(0.25, float(arg("speed", "1")))


# ---------------------------------------------------------------- instellingen
const DEFAULTS := {
	"music": 0.8, "sfx": 0.9, "shake": 1.0, "text": 1.0, "fast_needle": false, "tempo80": false,
	"colorblind": false, "fullscreen": false,
}


static var _cache := {}


static func setting(k: String):
	if not _cache.has(k):
		_cache[k] = TxSave.setting(k, DEFAULTS.get(k))
	return _cache[k]


static func set_setting(k: String, v) -> void:
	TxSave.set_setting(k, v)
	_cache[k] = v
	apply_all()


static func apply_all() -> void:
	var sfx := _sfx_node()
	if sfx != null:
		sfx.set("music_volume", float(setting("music")))
		sfx.set("sfx_volume", float(setting("sfx")))
	var j := _node("Juice")
	if j != null:
		j.set("shake_scale", float(setting("shake")))
	if not DisplayServer.get_name().to_lower().contains("headless"):
		var fs := bool(setting("fullscreen"))
		var cur := DisplayServer.window_get_mode()
		var is_fs := cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if fs != is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)


static func colorblind() -> bool:
	return bool(setting("colorblind"))


static func text_scale() -> float:
	return float(setting("text"))


static func _node(n: String) -> Node:
	var ml := Engine.get_main_loop() as SceneTree
	return ml.root.get_node_or_null(n) if ml != null else null


static func _sfx_node() -> Node:
	return _node("Sfx")


static func stars() -> Dictionary:
	_parse()
	if unlock_all:
		var d := TxSave.all_stars().duplicate()
		return d
	return TxSave.all_stars()


static func unlocked(id: String) -> bool:
	_parse()
	if unlock_all:
		return true
	return TxLevels.is_unlocked(id, TxSave.all_stars())


# ---------------------------------------------------------------- leerpad (TxLessons, TxLessonCoach)

## Eén keer per run: reset_learning en lesson=<deel> van de commandoregel verwerken.
static func lesson_boot() -> void:
	if _lesson_boot:
		return
	_lesson_boot = true
	if has("reset_learning"):
		TxLessons.reset_progress()
	if has("lesson") and bot_mode() == "":
		queue_lesson(arg("lesson"), arg("phase", ""))
		lesson_return = "level" if has("level") else ("quit" if has("autoquit") else "map")


static func queue_lesson(part: String, phase: String) -> void:
	lesson_queue.clear()
	if TxLessons.part(part).is_empty():
		push_warning("TxSession: onbekend leerpaddeel %s" % part)
		return
	for ph in (["kijk", "samen"] if phase == "" else [phase]):
		lesson_queue.append({"part": part, "phase": ph})


## Vóór een level: de nog niet gedane delen (eerste keer verplicht). Niet met een bot of no_lessons.
static func queue_for_level(id: String) -> void:
	if bot_mode() != "" or has("no_lessons"):
		return
	lesson_queue = TxLessons.pending_for_level(id)
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
	_goto(SCENE_CONSOLE)


## De coach is klaar met een les: volgende les, het level, de kaart of afsluiten.
static func lesson_done() -> void:
	if not lesson_queue.is_empty():
		lesson_queue.pop_front()
	if not lesson_queue.is_empty() or lesson_return == "level":
		_goto(SCENE_CONSOLE)
	elif lesson_return == "quit":
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.quit()
	else:
		_goto(SCENE_MAP)


static func _goto(path: String) -> void:
	var tr := _node("Transition")
	if tr != null:
		tr.call("goto", path)
	else:
		(Engine.get_main_loop() as SceneTree).change_scene_to_file(path)
