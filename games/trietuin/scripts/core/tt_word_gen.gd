class_name TtWordGen extends RefCounted
## Woordgenerator voor de vrije tuin (GDD §5.7): woorden van 2–7 letters + "_"; 50 % start met een prefix (1–4) van
## een woord dat al in de boom zit; 5 % duplicaat ("Zit er al"). Deterministisch per seed.

var rng := RandomNumberGenerator.new()
var alpha: TtAlphabet
var letters: PackedStringArray = []


func _init(seed_: int, alpha_: TtAlphabet) -> void:
	rng.seed = seed_
	alpha = alpha_
	for l in alpha.letters:
		if l != "_" and not (l >= "0" and l <= "9"):
			letters.append(l)


func _rand_letter() -> String:
	return letters[rng.randi_range(0, letters.size() - 1)]


func next_word(existing: PackedStringArray) -> String:
	if not existing.is_empty() and rng.randf() < 0.05:
		return existing[rng.randi_range(0, existing.size() - 1)]
	var total := rng.randi_range(2, 7)
	var w := ""
	if not existing.is_empty() and rng.randf() < 0.5:
		var base := existing[rng.randi_range(0, existing.size() - 1)].trim_suffix("_")
		var pl := mini(rng.randi_range(1, 4), base.length())
		w = base.substr(0, pl)
	while w.length() < total:
		w += _rand_letter()
	return w + "_"


## Een woord dat niet in existing zit.
func absent_word(existing: PackedStringArray) -> String:
	for i in 50:
		var w := next_word(existing)
		if not existing.has(w):
			return w
	return "".join([_rand_letter(), _rand_letter(), _rand_letter(), _rand_letter(), _rand_letter(), _rand_letter(), _rand_letter()]) + "_"


## Bestelling: 25 % een afwezig woord. -> {"word", "present"}
func next_query(existing: PackedStringArray, absent_p: float = 0.25) -> Dictionary:
	if existing.is_empty() or rng.randf() < absent_p:
		return {"word": absent_word(existing), "present": false}
	return {"word": existing[rng.randi_range(0, existing.size() - 1)], "present": true}


func randf() -> float:
	return rng.randf()


func pick(existing: PackedStringArray) -> String:
	return existing[rng.randi_range(0, existing.size() - 1)] if not existing.is_empty() else ""
