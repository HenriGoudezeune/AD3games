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
## Leerpad (design/LEARNING_PATH.md):
##   lesson=<deel> [phase=kijk|samen]   speel die les (zonder phase: Kijk en dan Samen); daarna naar level= of de kaart
##   reset_learning=1   wis de leerpadvoortgang (badges, "eerste keer verplicht")
##   no_lessons=1       geen automatische lessen vóór een level (ook: bot=…; bij level=… ook intro=0)
##   autoplay=1         Kijk speelt vanzelf door · auto_answer=1  voorspel-/checkvragen vanzelf juist beantwoorden
##   lesson_demo=1      Samen: een gesimuleerde speler (eerst een foute zet per soort, dan juist)
##   check=<level>      open de Check-vragen van dat level op de kaart (bv. check=2-1)

const SCENE_TITLE := "res://games/trietuin/scenes/title.tscn"
const SCENE_MAP := "res://games/trietuin/scenes/season_map.tscn"
const SCENE_GARDEN := "res://games/trietuin/scenes/garden.tscn"

static var level_id := "1-1"
static var from_map := false
static var map_focus := ""          # level dat op de kaart net een ster kreeg (animatie)
static var map_stars_before := {}   # sterren vóór het laatste level (kaart-animatie)
static var _args := {}
static var _parsed := false
static var cli_bot := false          # er stond bot=… op de commandoregel (blijft waar na consume)
## Leerpad: lessen die de tuin eerst speelt [{part, phase}], en waarheen daarna: "level" (level_id) | "map" | "title"
static var lesson_queue: Array = []
static var lesson_return := "map"
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
		cli_bot = _args.has("bot")
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


# ======================================================================
#  leerpad: lessenwachtrij
# ======================================================================

## Eén keer per run: reset_learning=1 en lesson=<deel> van de commandoregel verwerken. -> true als er net een
## les van de commandoregel klaarstaat (titel/kaart gaan dan meteen naar de tuin).
static func lesson_boot() -> bool:
	if _lesson_boot:
		return false
	_lesson_boot = true
	if has("reset_learning"):
		TtLessons.reset_progress()
	if has("lesson") and not cli_bot:
		queue_lesson(arg("lesson"), arg("phase", ""))
		lesson_return = "level" if has("level") else "map"
		return not lesson_queue.is_empty()
	return false


static func queue_lesson(part: String, phase: String) -> void:
	lesson_queue.clear()
	if TtLessons.part(part).is_empty():
		push_warning("Trietuin: onbekend deel van het leerpad: " + part)
		return
	for ph in (["kijk", "samen"] if phase == "" else [phase]):
		lesson_queue.append({"part": part, "phase": ph})


## Vóór een level: de nog niet gedane delen (eerste keer verplicht). Niet met de bot of no_lessons=1.
static func queue_for_level(id: String) -> void:
	lesson_queue.clear()
	if cli_bot or has("no_lessons"):
		return
	lesson_queue = TtLessons.pending_for_level(id)
	lesson_return = "level"


## Gids: "Bekijk de demo opnieuw" / "Oefen dit opnieuw". `in_level`: daarna terug naar het level.
static func play_lesson(part: String, phase: String, in_level: bool) -> void:
	queue_lesson(part, phase)
	lesson_return = "level" if in_level else "map"
	Engine.time_scale = 1.0
	Transition.goto(SCENE_GARDEN)


## De huidige les is klaar (of overgeslagen): volgende les, of het level / de kaart.
static func lesson_done() -> void:
	if not lesson_queue.is_empty():
		lesson_queue.pop_front()
	Engine.time_scale = 1.0
	if not lesson_queue.is_empty() or lesson_return == "level":
		Transition.goto(SCENE_GARDEN)
	else:
		Transition.goto(SCENE_MAP)
