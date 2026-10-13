class_name TtSession
extends Object
## Trietuin: gedeelde toestand tussen scènes (geen autoload nodig: static vars blijven bestaan bij een scènewissel)
## en de commandoregel-opties voor QA (na `--`):
##   level=1-2        start meteen dat level (titel/kaart worden overgeslagen als de scène title.tscn is)
##   bot=perfect|errors|random   laat de bot spelen (perfect = orakel; errors = vaste foutmodi; random = 25 % fout)
##   speed=2.0        Engine.time_scale (bots)
##   intro=0          geen titelkaart-intro
##   report=1         toon na de Bloei het rapport en blijf staan (standaard)
##   replay=1         rapport: open meteen de eerste misstap
##   map=1 / title=1  open de kaart / titel
##   season=0..3      kaart: scroll naar dat seizoen
##   notes=1          rapport: open de notas-weergave
##   pause=1          open het pauzemenu na 2 s; sheet=1 opent het spiekbriefje
##   seed=N           vrije tuin: vaste seed
##   shots=<map> shot_every=2.0 quit_at=60   QA: schermafdrukken om de N s (echte tijd) en stoppen na T s

const SCENE_TITLE := "res://games/trietuin/scenes/title.tscn"
const SCENE_MAP := "res://games/trietuin/scenes/season_map.tscn"
const SCENE_GARDEN := "res://games/trietuin/scenes/garden.tscn"

static var level_id := "1-1"
static var from_map := false
static var map_focus := ""          # level dat op de kaart net een ster kreeg (animatie)
static var map_stars_before := {}   # sterren vóór het laatste level (kaart-animatie)
static var _args := {}
static var _parsed := false


static func args() -> Dictionary:
	if not _parsed:
		_parsed = true
		for a in OS.get_cmdline_user_args():
			var s: String = a.trim_prefix("--")
			if s.contains("="):
				_args[s.get_slice("=", 0)] = s.substr(s.find("=") + 1)
			else:
				_args[s] = "1"
	return _args


static func arg(k: String, def := "") -> String:
	return str(args().get(k, def))


static func has(k: String) -> bool:
	return args().has(k)


## Eenmalige args (level=, bot=) gelden enkel voor de eerste scène die ze opeist.
static func consume(k: String) -> String:
	var v := arg(k)
	args().erase(k)
	return v


static func season_of(id: String) -> int:
	if id == "endless" or id.begins_with("free"):
		return 0
	var s := int(id.get_slice("-", 0)) - 1
	return clampi(s, 0, 4)


## Seizoen voor kleuren/achtergrond (finale = winter).
static func art_season(id: String) -> int:
	return mini(season_of(id), 3)


static func season_name(s: int) -> String:
	return ["Lente", "Zomer", "Herfst", "Winter", "Finale"][clampi(s, 0, 4)]


## QA-schermafdrukken (sneller dan --write-movie): elke `shot_every` s een PNG in `shots`, stoppen na `quit_at` s.
static var _shot_t := 0.0
static var _shot_n := 0
static var _run_t := 0.0


static func qa_tick(node: Node, delta: float) -> void:
	if not has("shots") and not has("quit_at"):
		return
	var real := delta / maxf(Engine.time_scale, 0.001)
	_run_t += real
	_shot_t += real
	if has("shots") and _shot_t >= float(arg("shot_every", "2.0")):
		_shot_t = 0.0
		var img := node.get_viewport().get_texture().get_image()
		img.save_png("%s/s%04d.png" % [arg("shots"), _shot_n])
		_shot_n += 1
	if has("quit_at") and _run_t >= float(arg("quit_at")):
		node.get_tree().quit()
