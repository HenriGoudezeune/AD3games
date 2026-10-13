class_name TtAlphabet extends RefCounted
## Alfabet met vaste volgorde (weergave- én vergelijkingsvolgorde) en sapgrootte |A| (GDD §8.3).
## "_" en de afsluittekens "1","2","3" staan altijd achteraan (zoals de knoppenrij A C G T _ in de figuren).

var name: String = ""
var letters: PackedStringArray = []
var cost_size: int = 0       # |A| voor sap (meestal letters.size(); ASCII-storm: 256)
var _idx: Dictionary = {}


static func make(n: String, ls: PackedStringArray, cost: int = -1) -> TtAlphabet:
	var a := TtAlphabet.new()
	a.name = n
	a.letters = ls
	a.cost_size = ls.size() if cost < 0 else cost
	for i in ls.size():
		a._idx[ls[i]] = i
	return a


static func dna() -> TtAlphabet:
	return make("dna", PackedStringArray(["A", "C", "G", "T", "_"]))


static func dna_lower() -> TtAlphabet:
	return make("dna_lower", PackedStringArray(["a", "c", "g", "t", "_"]))


static func abc() -> TtAlphabet:
	return make("abc", PackedStringArray(["A", "B", "C", "_"]))


## a b c _ (Ukkonen-voorbeelden abacabc_ en aabbabc_; aanvulling op GDD §8.3)
static func abc_lower() -> TtAlphabet:
	return make("abc_lower", PackedStringArray(["a", "b", "c", "_"]))


## Alfabet met precies de letters van een tekst: letters gesorteerd, "_" en cijfers (afsluittekens) achteraan.
static func for_text(text: String) -> TtAlphabet:
	var seen := {}
	for i in text.length():
		seen[text[i]] = true
	var ls: Array = seen.keys()
	ls.sort_custom(func(x, y):
		var sx: bool = (x == "_" or (x >= "0" and x <= "9"))
		var sy: bool = (y == "_" or (y >= "0" and y <= "9"))
		if sx != sy:
			return sy
		return x < y)
	return make("text", PackedStringArray(ls))


static func az() -> TtAlphabet:
	var ls := PackedStringArray()
	for c in range(97, 123):
		ls.append(String.chr(c))
	ls.append("_")
	return make("az", ls)


## a c g t 1 … k (veralgemeende suffixboom; "k" = afsluitteken _k)
static func dna_lower_multi(k: int) -> TtAlphabet:
	var ls := PackedStringArray(["a", "c", "g", "t"])
	for i in range(1, k + 1):
		ls.append(str(i))
	return make("dna_lower_multi", ls)


## "dna", "dna_lower", "abc", "abc_lower", "az", "dna_lower_multi3"/"dna_lower_multi" (=3); achtervoegsel "@256" zet cost_size.
static func by_name(n: String) -> TtAlphabet:
	var base := n
	var cost := -1
	if n.contains("@"):
		base = n.get_slice("@", 0)
		cost = int(n.get_slice("@", 1))
	var a: TtAlphabet = null
	match base:
		"dna":
			a = dna()
		"dna_lower":
			a = dna_lower()
		"abc":
			a = abc()
		"az":
			a = az()
		"abc_lower":
			a = abc_lower()
		_:
			if base.begins_with("dna_lower_multi"):
				var k := 3
				var rest := base.trim_prefix("dna_lower_multi")
				if rest != "":
					k = int(rest)
				a = dna_lower_multi(k)
	if a == null:
		push_warning("TtAlphabet: onbekend alfabet " + n)
		a = dna()
	if cost > 0:
		a.cost_size = cost
	return a


## Kopie met een andere sapgrootte (ASCII-storm: with_cost(256)).
func with_cost(n: int) -> TtAlphabet:
	var a := TtAlphabet.make(name, letters, n)
	return a


func size() -> int:
	return letters.size()


func has(ch: String) -> bool:
	return _idx.has(ch)


func index_of(ch: String) -> int:
	return int(_idx.get(ch, -1))


func compare(a: String, b: String) -> int:
	var ia := index_of(a)
	var ib := index_of(b)
	if ia < ib:
		return -1
	if ia > ib:
		return 1
	return 0


## Letters (of sleutels) gesorteerd in alfabetvolgorde.
func sorted(keys: Array) -> Array:
	var out := keys.duplicate()
	out.sort_custom(func(x, y): return index_of(str(x)) < index_of(str(y)))
	return out


func display(ch: String) -> String:
	if ch.length() == 1 and ch >= "1" and ch <= "9":
		return "_" + ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"][int(ch)]
	return ch


func display_word(w: String) -> String:
	var s := ""
	for i in w.length():
		s += display(w[i])
	return s
