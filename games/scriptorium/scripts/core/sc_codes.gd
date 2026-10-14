class_name ScCodes
## Kortschrift: gedeelde enums en constanten (GDD §8.2). Pure data, geen nodes.

enum Tool { PREFIX_READ, CODE_BOARD, BINDERY, LIVING_TREE, RULER, WINDOW, STAMPCASE, DRUM, SHELF, DOVECOTE }
enum Side { SEND, RECEIVE }
enum Phase { IDLE, READ, CUTS, DESIGN, BIND, COPY, WRITE, GROW, CLIMB, CUT, NEEDLE, PICK, DECIDE, CARVE,
		INSERT, MARK, WALK, NUMBER, PICK_BLOCK, ROOST, DECREE, DONE }
enum Verdict { OK, BUMP, NOT_PREFIX, LONG_CODE, WRONG_PAIR, WRONG_LEAF, MISSED_SWAP, WRONG_SWAP, WRONG_SEGMENT,
		OVERSHOOT, LONG_BITS, UNREACHABLE, WRONG_EDGE, SHORT_MATCH, WRONG_POS, EARLY_STAMP, WRONG_CARVE,
		WRONG_ORDER, WRONG_P, WRONG_RANK, WRONG_INDEX, WRONG_DECREE, GARBLED, TWO_PIGEONS }

const NNG := "nng"          # symbool van de nng-top (kan niet botsen met een teken van lengte 1)
const EOF := "EOF"          # derde element van een drietal na het laatste teken
const RAW_BITS := 8         # kost van een ruwe letter (p. 94)
const LZW_BITS := 12        # bits per LZW-code in de terugblik (p. 110)
const LZW_FIRST := 256      # eerste nieuwe LZW-code (p. 111)
const STUCK := "…"          # einde van een onleesbare strook

const TOOL_NAMES := ["prefix_read", "code_board", "bindery", "living_tree", "ruler", "window", "stampcase", "drum",
	"shelf", "dovecote"]
## Verdicts die gevolgen zijn (geen beslissing van de speler): tellen niet als misstap in ScEventLog.mistakes().
const CONSEQUENCES := [Verdict.GARBLED, Verdict.TWO_PIGEONS]


static func verdict_name(v: int) -> String:
	return Verdict.keys()[v] if v >= 0 and v < Verdict.size() else "?"


static func phase_name(p: int) -> String:
	return Phase.keys()[p] if p >= 0 and p < Phase.size() else "?"


static func tool_name(t: int) -> String:
	return TOOL_NAMES[t] if t >= 0 and t < TOOL_NAMES.size() else "?"


## "bindery" | … → ScCodes.Tool (−1 als onbekend).
static func tool_of(s: String) -> int:
	return TOOL_NAMES.find(s)


static func side_of(s: String) -> int:
	return Side.RECEIVE if s == "receive" else Side.SEND


## Weergave van één teken (spatie → ␣).
static func show_char(ch: String) -> String:
	return "␣" if ch == " " else ch


static func show_text(s: String) -> String:
	return s.replace(" ", "␣")
