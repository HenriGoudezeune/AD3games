extends Node
## Autoload "Game": huidige dag, laatste rapport, instellingen, opslag-glue (core SaveData als die er is).

const SCENE_TITLE := "res://scenes/title.tscn"
const SCENE_MAP := "res://scenes/day_map.tscn"
const SCENE_DEPOT := "res://scenes/depot.tscn"
const SCENE_REPORT := "res://scenes/report.tscn"
const SETTINGS_PATH := "user://settings.json"

var current_day := 1          # 1..7, 0 = endless
var last_report: Dictionary = {}
var last_log: Array = []      # EventLog.entries van de laatste dag
var last_model_snapshot: Dictionary = {}
var last_spec = null          # DaySpec
var last_time := 0.0
var last_title := ""
var cmd := {}                 # command-line opties na "--": --day=2 --bot --quit-after-day --autostart
var settings := {"music": 0.8, "sfx": 0.9, "shake": 1.0, "fullscreen": false}
## Leerpad (design/LEARNING_PATH_hashdash.md): lessen die het depot eerst speelt, [{part, phase}].
var lesson_queue: Array = []
var lesson_return := "day"    # na de laatste les: "day" (dag current_day starten) of "map"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var s: String = a.trim_prefix("--")
		var kv := s.split("=", true, 1)
		cmd[kv[0]] = kv[1] if kv.size() > 1 else true
	_load_settings()
	apply_settings()
	if cmd.has("day"):
		current_day = int(cmd["day"])
	if cmd.has("reset-learning"):
		HDLessons.reset_progress()
	if cmd.has("lesson") and not cmd.has("bot"):
		_queue_lesson(str(cmd["lesson"]), str(cmd.get("phase", "")))
		lesson_return = "day" if cmd.has("day") else "map"


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			settings[k] = d[k]


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
	apply_settings()


func apply_settings() -> void:
	Sfx.music_volume = float(settings.music)
	Sfx.sfx_volume = float(settings.sfx)
	Juice.shake_scale = float(settings.shake)
	if not cmd.has("bot"):
		var fs: bool = bool(settings.fullscreen)
		var cur := DisplayServer.window_get_mode()
		var is_fs := cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if fs != is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED)


# ---------------------------------------------------------------- opslag (via core SaveData)
func save_dict() -> Dictionary:
	return SaveData.load_data()


func stars_of(day: int) -> int:
	return SaveData.get_stars(day)


func record_stars(day: int, stars: int) -> void:
	if stars > stars_of(day):
		SaveData.set_stars(day, stars)


func is_unlocked(day: int) -> bool:
	if cmd.has("unlock"):
		return true
	return SaveData.is_unlocked(day)


## Start dag `day`. De eerste keer gaan de nog niet geoefende delen van het leerpad voor (Kijk, dan Samen).
func goto_day(day: int) -> void:
	current_day = day
	lesson_queue.clear()
	if not cmd.has("bot") and not cmd.has("no-lessons"):
		lesson_queue = HDLessons.pending_for_day(day)
	lesson_return = "day"
	Transition.goto(SCENE_DEPOT)


func _queue_lesson(part: String, phase: String) -> void:
	lesson_queue.clear()
	for ph in (["kijk", "samen"] if phase == "" else [phase]):
		lesson_queue.append({"part": part, "phase": ph})


## Gids "Bekijk de demo opnieuw" / "Oefen dit opnieuw": speel die les, daarna terug naar de dag of de kaart.
func play_lesson(part: String, phase: String) -> void:
	var cur := get_tree().current_scene
	var in_day: bool = cur != null and cur.scene_file_path == SCENE_DEPOT and lesson_queue.is_empty()
	_queue_lesson(part, phase)
	lesson_return = "day" if in_day else "map"
	get_tree().paused = false
	Transition.goto(SCENE_DEPOT)


## De huidige les is klaar (of overgeslagen): volgende les, of de dag / de kaart.
func lesson_done() -> void:
	if not lesson_queue.is_empty():
		lesson_queue.pop_front()
	if not lesson_queue.is_empty() or lesson_return == "day":
		Transition.goto(SCENE_DEPOT)
	else:
		Transition.goto(SCENE_MAP)
