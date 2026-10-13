class_name TtCard extends RefCounted
## Eén kaart uit de windrij (GDD §8.9).

var id: int = 0
var kind: int = TtCodes.CardKind.SEED
var word: String = ""          # SEED/BEE/PRUNE; ASK: de zoekstring z
var wasp: bool = false         # BEE: afwezig woord in een Patricia-level (wesp)
var q: String = ""             # ASK: "exists"|"where"|"count"|"all"|"owner"
var j: int = -1                # SUFFIX: suffix-start (0-gebaseerd)
var t: float = 0.0             # SWARM: aankomsttijd
var patience: float = 0.0      # SWARM: geduld (s); 0 = onbeperkt
var state: String = "waiting"  # waiting|active|done|expired
var outcome: Dictionary = {}
var beds: Array = []           # BEDS: [{alphabet, words, budget, …}]
var started_at: float = -1.0
var finished_at: float = -1.0


static func from_spec(id_: int, d: Dictionary) -> TtCard:
	var c := TtCard.new()
	c.id = id_
	c.kind = TtCodes.card_kind_of(str(d.get("kind", "seed")))
	c.word = str(d.get("word", d.get("z", "")))
	c.wasp = bool(d.get("wasp", false))
	c.q = str(d.get("q", ""))
	c.j = int(d.get("j", -1))
	c.t = float(d.get("t", 0.0))
	c.patience = float(d.get("patience", 0.0))
	c.beds = d.get("beds", []).duplicate(true)
	return c


func to_dict() -> Dictionary:
	return {"id": id, "kind": kind, "word": word, "wasp": wasp, "q": q, "j": j, "t": t, "patience": patience,
		"state": state, "outcome": outcome.duplicate(true), "beds": beds.duplicate(true),
		"started_at": started_at, "finished_at": finished_at}


func load_dict(d: Dictionary) -> void:
	id = int(d.get("id", 0))
	kind = int(d.get("kind", 0))
	word = str(d.get("word", ""))
	wasp = bool(d.get("wasp", false))
	q = str(d.get("q", ""))
	j = int(d.get("j", -1))
	t = float(d.get("t", 0.0))
	patience = float(d.get("patience", 0.0))
	state = str(d.get("state", "waiting"))
	outcome = d.get("outcome", {}).duplicate(true)
	beds = d.get("beds", []).duplicate(true)
	started_at = float(d.get("started_at", -1.0))
	finished_at = float(d.get("finished_at", -1.0))


static func from_dict(d: Dictionary) -> TtCard:
	var c := TtCard.new()
	c.load_dict(d)
	return c


func kind_name() -> String:
	return TtCodes.card_name(kind)


## Korte omschrijving voor logs/QA: "seed TGG_", "bee* BBBB_" (wesp), "ask where cac".
func describe() -> String:
	match kind:
		TtCodes.CardKind.BEE:
			return ("wesp " if wasp else "bee ") + word
		TtCodes.CardKind.ASK:
			return "ask %s %s" % [q, word]
		TtCodes.CardKind.SUFFIX:
			return "suffix %d" % j
	return (kind_name() + " " + word).strip_edges()
