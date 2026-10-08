class_name SaveData
## Opslag in user://save.json (GDD §10.7). Formaat:
## {"version":1, "stars":{"1":3, "2":1, ...}, "highscores":[{"score":245, "name":"HEN", "date":"2026-10-08"}], "settings":{}}

const MAX_HIGHSCORES := 10
static var path: String = "user://save.json"   # tests zetten dit naar een ander bestand


static func _default() -> Dictionary:
	return {"version": 1, "stars": {}, "highscores": [], "settings": {}}


static func load_data() -> Dictionary:
	var d := _default()
	if not FileAccess.file_exists(path):
		return d
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return d
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return d
	for k in d.keys():
		if parsed.has(k) and typeof(parsed[k]) == typeof(d[k]):
			d[k] = parsed[k]
	# JSON maakt van ints floats
	var st := {}
	for k in d.stars.keys():
		st[str(k)] = int(d.stars[k])
	d.stars = st
	for h in d.highscores:
		h.score = int(h.get("score", 0))
	return d


static func save_data(d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveData: kan %s niet schrijven" % path)
		return
	f.store_string(JSON.stringify(d, "  "))
	f.close()


## Bewaart enkel als het beter is dan wat er al stond.
static func set_stars(day: int, stars: int) -> void:
	var d := load_data()
	var k := str(day)
	if stars > int(d.stars.get(k, 0)):
		d.stars[k] = stars
		save_data(d)


static func get_stars(day: int) -> int:
	return int(load_data().stars.get(str(day), 0))


## Dag 1 altijd; dag i als dag i−1 ≥ 1 ster heeft; endless (0) na dag 5 met ≥ 1 ster.
static func is_unlocked(day: int) -> bool:
	if day == 1:
		return true
	if day == 0:
		return get_stars(5) >= 1
	return get_stars(day - 1) >= 1


## Voegt een score toe aan de lokale top-10 (met datum). -> plaats (0-gebaseerd) of -1 als niet in de top-10.
static func add_highscore(score: int, name: String) -> int:
	var d := load_data()
	var entry := {"score": score, "name": name.substr(0, 3).to_upper(), "date": Time.get_date_string_from_system()}
	var hs: Array = d.highscores
	var pos := hs.size()
	for i in hs.size():
		if score > int(hs[i].score):
			pos = i
			break
	if pos >= MAX_HIGHSCORES:
		return -1
	hs.insert(pos, entry)
	while hs.size() > MAX_HIGHSCORES:
		hs.pop_back()
	d.highscores = hs
	save_data(d)
	return pos


static func highscores() -> Array:
	return load_data().highscores


static func is_highscore(score: int) -> bool:
	var hs := highscores()
	return hs.size() < MAX_HIGHSCORES or score > int(hs[-1].score)


static func set_setting(key: String, value) -> void:
	var d := load_data()
	d.settings[key] = value
	save_data(d)


static func get_setting(key: String, default = null):
	return load_data().settings.get(key, default)
