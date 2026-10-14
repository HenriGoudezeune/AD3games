class_name ScTextGen extends RefCounted
## Nachtwake-generator (GDD §5.10): ronde r (0, 1, …): k = min(4 + r, 12) stapels met letters uit LETTERS (in die
## volgorde), gewichten w = 1 + ⌊u² · (2 + 2r)⌋ met u uniform in [0, 1), rij in willekeurige volgorde. Elke 4e ronde
## (r = 3, 7, …) een leesstrook van 8 letters (gewogen getrokken). Deterministisch per (seed, r).

const LETTERS := "eanrtoidslgkvmuhjbpwzcf"
const READ_LEN := 8

var seed_: int = 0


func _init(seed_value: int = 0) -> void:
	seed_ = seed_value


func _rng(r: int, salt: int) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash([seed_, r, salt])
	return g


static func is_read_round(r: int) -> bool:
	return r % 4 == 3


## → {letters:Array[String], weights:Array[int], read_text:String ("" behalve elke 4e ronde)}
func wake_round(r: int) -> Dictionary:
	var g := _rng(r, 1)
	var k := mini(4 + r, 12)
	var letters: Array[String] = []
	for q in k:
		letters.append(LETTERS[q])
	for q in range(k - 1, 0, -1):
		var j := g.randi_range(0, q)
		var tmp := letters[q]
		letters[q] = letters[j]
		letters[j] = tmp
	var weights: Array[int] = []
	for q in k:
		var u := g.randf()
		weights.append(1 + int(floor(u * u * float(2 + 2 * r))))
	var read_text := ""
	if is_read_round(r):
		var tot := 0
		for w in weights:
			tot += w
		var g2 := _rng(r, 2)
		for q in READ_LEN:
			var x := g2.randi_range(1, tot)
			var acc := 0
			for i in k:
				acc += weights[i]
				if x <= acc:
					read_text += letters[i]
					break
	return {"letters": letters, "weights": weights, "read_text": read_text}


## Rondetijd (GDD §5.10): max(1,2; 2,5 − 0,08·r) s per binding × (k − 1) + 4 s.
static func round_time(r: int, k: int) -> float:
	return maxf(1.2, 2.5 - 0.08 * float(r)) * float(k - 1) + 4.0
