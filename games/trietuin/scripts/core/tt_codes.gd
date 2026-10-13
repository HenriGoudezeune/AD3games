class_name TtCodes
## Trietuin: gedeelde enums (GDD §8.2). Pure data, geen nodes.

enum Kind { TRIE, PATRICIA, TERNARY, SUFFIX, UKKONEN }
enum Mode { CALM, SWARM }
enum Hint { FULL, CURSOR, NONE }
## wesp = BEE met card.wasp = true
enum CardKind { SEED, BEE, PRUNE, PATRICIFY, TERNARIFY, BEDS, SUFFIX, ASK, UKKONEN }
enum Phase { IDLE, WALK, COMPARE, AT_LEAF, PICK_LEAF, CUT, PRUNING, PLACING, ATTACH, LABEL, LOCATE, ANSWER,
		U_CANON, U_RULE, U_LINK, U_FOLLOW, DONE, BED }
enum Verdict { OK, BUMP, WRONG_LETTER, WRONG_KNOP, J_LATE, WRONG_SAME, WRONG_ANSWER, CUT_TOO_HIGH, CUT_TOO_LOW,
		WRONG_POS, WRONG_SHORT, UNPRUNED, WRONG_DIR, WRONG_POINT, WRONG_B, WRONG_ABSENT, WRONG_WHERE,
		WRONG_COUNT, WRONG_PICK, WRONG_OWNER, WRONG_BED, WRONG_RULE, WRONG_HOP, WRONG_LINK, WRONG_FOLLOW,
		LOST, TIMEOUT }

const OPEN := -2   # eindlabel "it" van een open Ukkonen-bladboog

const CARD_NAMES := ["seed", "bee", "prune", "patricify", "ternarify", "beds", "suffix", "ask", "ukkonen"]


static func card_kind_of(s: String) -> int:
	return CARD_NAMES.find(s)


static func card_name(k: int) -> String:
	return CARD_NAMES[k] if k >= 0 and k < CARD_NAMES.size() else "?"


static func verdict_name(v: int) -> String:
	return Verdict.keys()[v] if v >= 0 and v < Verdict.size() else "?"


static func phase_name(p: int) -> String:
	return Phase.keys()[p] if p >= 0 and p < Phase.size() else "?"
