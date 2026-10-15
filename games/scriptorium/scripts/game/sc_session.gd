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
