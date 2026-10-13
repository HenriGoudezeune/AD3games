class_name TxSave
## Opslag in user://telex_save.json (GDD §8.8). Formaat:
## {"version":1, "stars":{"3-1":3}, "best":{"3-1":points}, "highscores":[{name,score,date}], "settings":{…}}
## Tests (en QA) zetten TxSave.path naar een ander bestand.

const MAX_HIGHSCORES := 10
static var path: String = "user://telex_save.json"


static func _default() -> Dictionary:
	return {"version": 1, "stars": {}, "best": {}, "highscores": [], "settings": {}}


static func load_data() -> Dictionary:
	var d := _default()
	if not FileAccess.file_exists(path):
		return d
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return d
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK or not json.data is Dictionary:
		return d
	var parsed: Dictionary = json.data
	for k in d.keys():
		if parsed.has(k) and typeof(parsed[k]) == typeof(d[k]):
			d[k] = parsed[k]
	d.version = 1
	var st := {}
	for k in (d.stars as Dictionary).keys():
		st[str(k)] = clampi(int(d.stars[k]), 0, 3)
	d.stars = st
	var be := {}
	for k in (d.best as Dictionary).keys():
		be[str(k)] = int(d.best[k])
	d.best = be
	var hs: Array = []
	for h in d.highscores:
		if h is Dictionary:
			hs.append({"name": str(h.get("name", "???")), "score": int(h.get("score", 0)), "date": str(h.get("date", ""))})
	d.highscores = hs
	return d


static func save_data(d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("TxSave: kan %s niet schrijven" % path)
		return
	f.store_string(JSON.stringify(d, "  "))
	f.close()


## Houdt het maximum.
static func set_stars(id: String, n: int) -> void:
	var d := load_data()
	if n > int(d.stars.get(id, 0)):
		d.stars[id] = clampi(n, 0, 3)
		save_data(d)


static func get_stars(id: String) -> int:
	return int(load_data().stars.get(id, 0))


static func all_stars() -> Dictionary:
	return load_data().stars


## Beste punten per level. -> true als het een nieuw record is.
static func set_best(id: String, points: int) -> bool:
	var d := load_data()
	if not d.best.has(id) or points > int(d.best[id]):
		d.best[id] = points
		save_data(d)
		return true
	return false


static func get_best(id: String) -> int:
	return int(load_data().best.get(id, 0))


## Rapport van een level (TxScoring.final_report) wegschrijven: sterren (max) en beste punten.
static func record(id: String, report: Dictionary) -> void:
	set_stars(id, int(report.get("n_stars", 0)))
	set_best(id, int(report.get("points", 0)))


static func is_unlocked(id: String) -> bool:
	return TxLevels.is_unlocked(id, all_stars())


## Voegt een score toe aan de lokale top-10. -> rang (1..10) of 0 als niet in de top-10.
static func add_highscore(score: int, name: String, date: String) -> int:
	var d := load_data()
	var entry := {"name": name.substr(0, 3).to_upper(), "score": score, "date": date}
	var hs: Array = d.highscores
	var pos := hs.size()
	for i in hs.size():
		if score > int(hs[i].score):
			pos = i
			break
	if pos >= MAX_HIGHSCORES:
		return 0
	hs.insert(pos, entry)
	while hs.size() > MAX_HIGHSCORES:
		hs.pop_back()
	d.highscores = hs
	save_data(d)
	return pos + 1


static func highscores() -> Array:
	return load_data().highscores


static func is_highscore(score: int) -> bool:
	var hs := highscores()
	return hs.size() < MAX_HIGHSCORES or score > int(hs[-1].score)


static func setting(k: String, default_value = null) -> Variant:
	return load_data().settings.get(k, default_value)


static func set_setting(k: String, v) -> void:
	var d := load_data()
	d.settings[k] = v
	save_data(d)


static func reset() -> void:
	save_data(_default())
