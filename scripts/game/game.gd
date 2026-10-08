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
var cmd := {}                 # command-line opties na "--": --day=2 --bot --quit-after-day --autostart
var settings := {"music": 0.8, "sfx": 0.9, "shake": 1.0, "fullscreen": false}


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
	var d := save_dict()
	var st = d.get("stars", {})
	if st is Dictionary:
		return int(st.get(str(day), st.get(day, 0)))
	if st is Array and day < st.size():
		return int(st[day])
	return 0


func record_stars(day: int, stars: int) -> void:
	if stars > stars_of(day):
		SaveData.set_stars(day, stars)


func is_unlocked(day: int) -> bool:
	if cmd.has("unlock"):
		return true
	if day == 1:
		return true
	if day == 0:
		return stars_of(5) >= 1
	return stars_of(day - 1) >= 1


func goto_day(day: int) -> void:
	current_day = day
	Transition.goto(SCENE_DEPOT)
