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


static func setting(k: String):
	return TxSave.setting(k, DEFAULTS.get(k))


static func set_setting(k: String, v) -> void:
	TxSave.set_setting(k, v)
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
	if unlock_all:
		var d := TxSave.all_stars().duplicate()
		return d
	return TxSave.all_stars()


static func unlocked(id: String) -> bool:
	if unlock_all:
		return true
	return TxLevels.is_unlocked(id, TxSave.all_stars())
