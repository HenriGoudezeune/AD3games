class_name TxLevelSpec extends RefCounted
## Leveldata (GDD §5, §8.8). Alles is data; TxLevels vult de specs, TxDirector speelt ze.

var id: String = ""
var dossier: int = 0                      # 1..8; 9 = finale; 0 = Nachtdienst
var title: String = ""
var intro: String = ""                    # één zin van de Chef
var notes_ref: String = ""                # bv. "Oefening 39 · notas p. 62"
var priority: String = "P0"               # "P0"|"P1"|"P2"
var mode: int = TxCodes.Mode.CALM
var stages: Array[Dictionary] = []        # GDD §8.5
var live: Dictionary = {}                 # {"v":0.8, "B":4, "rival":true} | ritme: {"bpm":100, "strak":0.2}
var stars: Array[Dictionary] = []         # drie voorwaarden (★, ★★, ★★★); {"kind":"all"/"any","of":[…]} combineert
var optimum: Dictionary = {}              # {ticks, wheel, lamps, relays, time_par} (GDD §5; TxLevels.optimum rekent na)
var ghost: Dictionary = {}                # {"brute_ticks":42}
var hints_allowed: bool = true
var tutorial: Array[Dictionary] = []      # [{"trigger":"first_decide","ghost":{…},"text":"…"}]
var story: Dictionary = {}                # {"chef_intro":"…", "debrief_extra":"…", "crate":"K-M-P 1977", "title_card":"…"}
var endless: bool = false
var tape_index: int = 0                   # Nachtdienst: lintnummer
var seed_: int = 0                        # Nachtdienst (generator-seed)
var expect: Dictionary = {}               # verwachte uitkomst (tests/QA): {"hits":[…], "sequences":n, …}


func machine_names() -> PackedStringArray:
	var out := PackedStringArray()
	for s in stages:
		out.append(str(s.get("machine", "")))
	return out


func to_dict() -> Dictionary:
	return {"id": id, "dossier": dossier, "title": title, "intro": intro, "notes_ref": notes_ref,
		"priority": priority, "mode": mode, "stages": stages, "live": live, "stars": stars, "optimum": optimum,
		"ghost": ghost, "hints_allowed": hints_allowed, "tutorial": tutorial, "story": story, "endless": endless,
		"tape_index": tape_index, "seed": seed_, "expect": expect}
