class_name TtNode extends RefCounted
## Eén top/blad/bol/rankknoop voor alle structuren (GDD §8.4). Ongebruikte velden houden hun default.

enum Type { INNER, LEAF, BALL, PACK }   # BALL = ternary letterbol, PACK = rankknoop (container van bollen)

var id: int = -1
var type: int = Type.INNER
## trie/Patricia/suffix: ouder-top; BALL: ouder-bol of -1 (wortelbol van zijn PACK);
## PACK: de BALL waarvan hij de gelijk-tak is (-1 = wortel); LEAF bij ternary: de BALL
var parent: int = -1
var via: String = ""        # letter van de inkomende tak (trie, Patricia); suffix: eerste teken van de inkomende boog
var depth: int = 0          # trie/ternary: letterdiepte (wortel 0, blad = diepte waarop bereikt); suffix: stringdiepte l_t
var kids: Dictionary = {}   # INNER: letter -> kind-id (enkel niet-lege kinderen)
var label: String = ""      # LEAF (tries): opgeslagen woord
var skip: int = 0           # Patricia
var pos: int = 0            # Patricia: leespositie = pos(ouder) + skip + 1; wortel: skip (door het model bijgehouden)
var ch: String = ""         # BALL
var lo: int = -1            # BALL: kleiner-bol
var eq: int = -1            # BALL: PACK (volgende rankknoop) of LEAF
var hi: int = -1            # BALL: groter-bol
var pack: int = -1          # BALL: id van zijn PACK
var ball_root: int = -1     # PACK: wortelbol (-1 = leeg)
var b: int = -1             # suffix: label van de boog NAAR deze top, 0-gebaseerd, inclusief
var e: int = -1             # suffix: idem; TtCodes.OPEN = "it"
var start: int = -1         # suffix-LEAF: beginpositie j van het suffix
var link: int = -1          # suffix link (Ukkonen); wortel.link == wortel.id
var owner: int = 0          # veralgemeend: index van de tekst (1..k) van een suffix-LEAF


static func make(id_: int, type_: int) -> TtNode:
	var n := TtNode.new()
	n.id = id_
	n.type = type_
	return n


func is_leaf() -> bool:
	return type == Type.LEAF


func is_inner() -> bool:
	return type == Type.INNER


func to_dict() -> Dictionary:
	return {
		"id": id, "type": type, "parent": parent, "via": via, "depth": depth, "kids": kids.duplicate(),
		"label": label, "skip": skip, "pos": pos, "ch": ch, "lo": lo, "eq": eq, "hi": hi, "pack": pack,
		"ball_root": ball_root, "b": b, "e": e, "start": start, "link": link, "owner": owner,
	}


static func from_dict(d: Dictionary) -> TtNode:
	var n := TtNode.new()
	n.id = int(d.get("id", -1))
	n.type = int(d.get("type", Type.INNER))
	n.parent = int(d.get("parent", -1))
	n.via = str(d.get("via", ""))
	n.depth = int(d.get("depth", 0))
	var k: Dictionary = d.get("kids", {})
	for key in k.keys():
		n.kids[str(key)] = int(k[key])
	n.label = str(d.get("label", ""))
	n.skip = int(d.get("skip", 0))
	n.pos = int(d.get("pos", 0))
	n.ch = str(d.get("ch", ""))
	n.lo = int(d.get("lo", -1))
	n.eq = int(d.get("eq", -1))
	n.hi = int(d.get("hi", -1))
	n.pack = int(d.get("pack", -1))
	n.ball_root = int(d.get("ball_root", -1))
	n.b = int(d.get("b", -1))
	n.e = int(d.get("e", -1))
	n.start = int(d.get("start", -1))
	n.link = int(d.get("link", -1))
	n.owner = int(d.get("owner", 0))
	return n
