class_name ScLevelSpec extends RefCounted
## Leveldata (GDD §5, §8.8). Alles is data; ScLevels vult de specs, ScDirector speelt ze.

var id: String = ""
var chapter: int = 0                        # 0 = proloog, 1..6, 7 = Allerheiligen (Codex), −1 = Nachtwake
var title: String = ""
var intro: String = ""                      # één zin van Zeno
var notes_ref: String = ""                  # bv. "Oefening 80 · notas p. 86"
var priority: String = "P0"                 # "P0"|"P1"|"P2"
var stages: Array[Dictionary] = []          # GDD §8.5
var stars: Array[Dictionary] = []           # drie voorwaarden (★, ★★, ★★★); {"kind":"all","of":[…]} combineert
var optimum: Dictionary = {}                # {"ink":22, "twine":22, "search":12, …} (ScLevels.optimum rekent na)
var ghosts: Dictionary = {}                 # {"plain":72, "fixed":27, "huffman":53}
var hints_allowed: bool = true
var tutorial: Array[Dictionary] = []        # [{"trigger":"first_climb","text":"…"}]
var story: Dictionary = {}                  # {"house":…, "zeno_intro":…, "debrief_extra":…, "crate":…, "stage_intros":[…]}
var endless: bool = false
var round_index: int = 0                    # Nachtwake
var seed_: int = 0                          # Nachtwake
var expect: Dictionary = {}                 # verwachte uitkomst (tests/QA): {"read":…, "ink":…, …}


func tool_names() -> PackedStringArray:
	var out := PackedStringArray()
	for s in stages:
		out.append(str(s.get("tool", "")))
	return out


func to_dict() -> Dictionary:
	return {"id": id, "chapter": chapter, "title": title, "intro": intro, "notes_ref": notes_ref,
		"priority": priority, "stages": stages, "stars": stars, "optimum": optimum, "ghosts": ghosts,
		"hints_allowed": hints_allowed, "tutorial": tutorial, "story": story, "endless": endless,
		"round_index": round_index, "seed": seed_, "expect": expect}
