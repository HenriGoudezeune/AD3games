class_name TxTextGen extends RefCounted
## Nachtdienst-generator (GDD §5.11): codewoord z, een lint t van 60–90 tekens met 1–3 ingeplante z (nooit
## overlappend) en 2–4 lokwoorden (zelfde laatste letter als z, minstens 2 andere letters van z). Deterministisch:
## tape(k) hangt enkel af van de seed en k.

const WORDS := [
	"de", "het", "een", "en", "van", "in", "op", "met", "aan", "voor", "naar", "over", "onder", "bij", "uit", "door",
	"dag", "nacht", "zee", "duin", "strand", "wind", "regen", "zon", "maan", "ster", "licht", "boot", "schip",
	"haven", "kade", "brug", "weg", "straat", "huis", "dak", "deur", "raam", "kamer", "tafel", "stoel", "kast",
	"boek", "brief", "pen", "papier", "draad", "kabel", "radio", "toren", "kerk", "school", "markt", "winkel",
	"bakker", "brood", "kaas", "melk", "koffie", "thee", "water", "vis", "vogel", "kat", "hond", "paard", "koe",
	"schaap", "boer", "veld", "bos", "boom", "blad", "bloem", "gras", "zand", "steen", "rots", "berg", "dal",
	"rivier", "meer", "kanaal", "dijk", "polder", "molen", "fiets", "trein", "tram", "bus", "auto", "perron", "plan",
	"geheim", "spion", "agent", "kantoor", "bureau", "lamp", "knop", "hendel", "rood", "blauw", "groen", "geel",
	"zwart", "wit", "grijs", "oud", "nieuw", "groot", "klein", "lang", "kort", "snel", "traag", "warm", "koud", "nat",
	"droog", "stil", "luid", "vroeg", "laat", "morgen", "avond", "week", "maand", "jaar", "uur", "tijd", "klok",
	"deel", "stuk", "woord", "zin", "taal", "stem", "lied", "muziek", "dans", "feest", "spel", "kaartje", "munt",
	"geld", "bank", "post", "zegel", "pakje", "doos", "zak", "tas", "jas", "hoed", "muts", "sjaal", "schoen", "laars",
	"hand", "voet", "arm", "been", "hoofd", "oog", "oor", "mond", "neus", "haar", "hart", "hoofdstad", "dorp", "stad",
	"land", "grens", "kust", "eiland", "golfslag", "meeuw", "reiger", "kraai", "uil", "vos", "haas", "konijn", "muis",
	"rat", "egel", "mol", "slak", "worm", "mier", "wesp", "vlieg", "mug", "spin", "kreeft", "krab", "mossel",
	"garnaal", "haring", "kabeljauw", "paling", "zalm", "tong", "schol", "aardappel", "wortel", "prei", "ui",
	"knoflook", "appel", "peer", "kers", "pruim", "druif", "citroen", "sinaasappel", "banaan", "meloen", "noot",
	"suiker", "zout", "peper", "olie", "boter", "ei", "soep", "saus", "taart", "koek", "wafel", "pannenkoek",
	"frieten", "worst", "ham", "spek", "kip", "eend", "gans", "zwaan", "duif", "mus", "merel", "specht", "wagen",
	"kar", "kist", "ton", "vat", "emmer", "schop", "hark", "zeis", "bijl", "hamer", "zaag", "spijker", "schroef",
	"plank", "balk", "muur", "vloer", "plafond", "trap", "kelder", "zolder", "tuin", "hek", "poort", "pad", "steeg",
	"plein", "park", "vijver", "fontein", "beeld", "museum", "theater", "bioscoop"
]

var seed_: int = 0


func _init(seed_value: int = 0) -> void:
	seed_ = seed_value


## Lengte van z voor lint k: max(4, min(9, 4 + ⌊k/3⌋)).
static func z_length(index: int) -> int:
	return maxi(4, mini(9, 4 + int(index / 3.0)))


static func codewords_of_length(L: int) -> PackedStringArray:
	var out := PackedStringArray()
	for w in TxLevels.CODEWORDS:
		if str(w).length() == L:
			out.append(str(w))
	return out


## Lokwoord: eindigt op de laatste letter van z en bevat minstens 2 andere letters van z; nooit z zelf.
static func is_decoy(w: String, z: String) -> bool:
	if w == z or w.length() < 2 or w[w.length() - 1] != z[z.length() - 1] or w.contains(z):
		return false
	var others := {}
	for i in z.length() - 1:
		if z[i] != z[z.length() - 1]:
			others[z[i]] = true
	var cnt := 0
	for c in others:
		if w.left(w.length() - 1).contains(c):
			cnt += 1
	return cnt >= 2


## {z, t, plants:Array[int], decoys:Array[int]}
func tape(index: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_, index, "telex"])
	var cands := codewords_of_length(z_length(index))
	var z: String = cands[rng.randi_range(0, cands.size() - 1)]
	var n_plants := rng.randi_range(1, 3)
	var n_decoys := rng.randi_range(2, 4)
	var pool: Array = []
	for w in WORDS:
		if is_decoy(str(w), z):
			pool.append(str(w))
	var decoys: Array = []
	for _d in n_decoys:
		if not pool.is_empty() and rng.randf() < 0.5:
			decoys.append(pool[rng.randi_range(0, pool.size() - 1)])
		else:
			decoys.append(_mutate(z, rng))
	var fillers: Array = []
	for w in WORDS:
		if not str(w).contains(z):
			fillers.append(str(w))
	var target := rng.randi_range(60, 90)
	var tokens: Array = []    # [{w, kind}]
	for _p in n_plants:
		tokens.append({"w": z, "kind": "plant"})
	for d in decoys:
		tokens.append({"w": d, "kind": "decoy"})
	var guard := 0
	while _joined_len(tokens) < target - 6 and guard < 200:
		guard += 1
		tokens.append({"w": fillers[rng.randi_range(0, fillers.size() - 1)], "kind": "fill"})
	_shuffle(tokens, rng)
	# lengte binnen [60, 90]: vullers weghalen of toevoegen
	guard = 0
	while _joined_len(tokens) > 90 and guard < 200:
		guard += 1
		for i in tokens.size():
			if str(tokens[i].kind) == "fill":
				tokens.remove_at(i)
				break
	guard = 0
	while _joined_len(tokens) < 60 and guard < 200:
		guard += 1
		var short: Array = []
		for w in fillers:
			if _joined_len(tokens) + 1 + str(w).length() <= 90:
				short.append(w)
		tokens.insert(rng.randi_range(0, tokens.size()), {"w": short[rng.randi_range(0, short.size() - 1)], "kind": "fill"})
	var t := ""
	var plants: Array[int] = []
	var decoy_pos: Array[int] = []
	for i in tokens.size():
		if i > 0:
			t += "_"
		if str(tokens[i].kind) == "plant":
			plants.append(t.length())
		elif str(tokens[i].kind) == "decoy":
			decoy_pos.append(t.length())
		t += str(tokens[i].w)
	return {"z": z, "t": t, "plants": plants, "decoys": decoy_pos}


static func _joined_len(tokens: Array) -> int:
	var L := 0
	for tk in tokens:
		L += str(tk.w).length()
	return L + maxi(0, tokens.size() - 1)


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


## Lokwoord door één letter van z (niet de laatste) te vervangen.
static func _mutate(z: String, rng: RandomNumberGenerator) -> String:
	var letters := "abdeiklmnoprstuvz"
	var guard := 0
	while guard < 50:
		guard += 1
		var p := rng.randi_range(0, z.length() - 2)
		var c := letters[rng.randi_range(0, letters.length() - 1)]
		if c != z[p]:
			var w := z.substr(0, p) + c + z.substr(p + 1)
			if w != z:
				return w
	return z.substr(1) + z[z.length() - 1]
