extends RefCounted
## STUB (tijdelijk) van core SaveData (user://save.json).

const PATH := "user://save.json"


static func load_data() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {"stars": {}, "highscores": []}
	var d = JSON.parse_string(FileAccess.open(PATH, FileAccess.READ).get_as_text())
	return d if d is Dictionary else {"stars": {}, "highscores": []}


static func save_data(d: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


static func set_stars(day: int, stars: int) -> void:
	var d := load_data()
	if not d.has("stars"):
		d.stars = {}
	d.stars[str(day)] = maxi(stars, int(d.stars.get(str(day), 0)))
	save_data(d)


static func add_highscore(score: int, name_: String) -> void:
	var d := load_data()
	var hs: Array = d.get("highscores", [])
	hs.append({"score": score, "name": name_, "date": Time.get_date_string_from_system()})
	hs.sort_custom(func(x, y): return x.score > y.score)
	d.highscores = hs.slice(0, 10)
	save_data(d)
