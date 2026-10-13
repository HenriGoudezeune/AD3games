class_name HubRegistry
extends Object
## Alle games van de AD3-speelhal. Een nieuwe game toevoegen = één entry hier.
## Een kaart verschijnt pas in de hub als `scene` bestaat, zodat halfafgewerkte games niet zichtbaar zijn.

const HUB_SCENE := "res://scenes/hub.tscn"

const GAMES := [
	{
		"id": "hash_dash",
		"title": "Hash & Dash",
		"topic": "Extendible hashing",
		"section": "§2.1.1",
		"blurb": "Run een pakjesdepot: sorteer pakjes op hun eerste bits, splits rekken en verdubbel de sorteermuur.",
		"scene": "res://scenes/title.tscn",
		"color": Color("#E0A96D"),
		"glyph": "#",
	},
	{
		"id": "trietuin",
		"title": "Trietuin",
		"topic": "Tries & suffixbomen",
		"section": "§3.1–3.3",
		"blurb": "Laat een boom vol woorden groeien, snoei hem tot een Patricia-trie en ontmasker sporen met suffixbomen.",
		"scene": "res://games/trietuin/scenes/title.tscn",
		"color": Color("#7BC96F"),
		"glyph": "T",
	},
	{
		"id": "telex",
		"title": "TELEX",
		"topic": "String matching",
		"section": "§3.4–3.5",
		"blurb": "Luisterpost 1961: bedien de zoekmachines (KMP, Boyer-Moore-Horspool, shift-AND, ...) en vind de codewoorden in het lint.",
		"scene": "res://games/telex/scenes/title.tscn",
		"color": Color("#E8B04A"),
		"glyph": "Z",
	},
	{
		"id": "scriptorium",
		"title": "Kortschrift",
		"topic": "Compressie",
		"section": "H4",
		"blurb": "Perkament is duur: bind codebomen, stempel woorden en draai de trommel, zonder één letter te verliezen.",
		"scene": "res://games/scriptorium/scenes/title.tscn",
		"color": Color("#C77DFF"),
		"glyph": "K",
	},
]


static func available() -> Array:
	var out := []
	for g in GAMES:
		if ResourceLoader.exists(g.scene):
			out.append(g)
	return out
