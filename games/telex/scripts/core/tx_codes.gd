class_name TxCodes
## Telex: gedeelde enums en constanten (GDD §8.2). Pure data, geen nodes.

enum Machine { BRUTE, RABIN_KARP, KMP_TABLE, KMP, BMH, SHIFT_AND, EDIT, SABOTAGE }
enum Mode { CALM, LIVE }
enum Find { FIRST, ALL }
enum Phase { IDLE, READY, NEEDLE, WAIT_TAPE, DECIDE,                 # naaldmachines
		W_CALC, HORNER, ROLL, ALARM,                                 # Vingerafdruk
		PUNCH_CELL, MIRROR_PUNCH, MIRROR_SHIFT,                      # Ponsbank (spiegel / spiegelrit)
		CARDS, WIRE, LEVER, CARD, CHOOSE,                            # Springer-kaarten / lampenbord
		FILL, PICK_END, TRACE, TRACE_DONE,                           # schakelbord / zoeklicht
		COMPOSE, DONE }
enum Verdict { OK, BUMP, SHIFT_LONG, PUNCH_LONG, PUNCH_SHORT, WRONG_HASH, WRONG_HORNER, UNVERIFIED, SKIPPED_CHECK,
		FALSE_ALARM, WRONG_KEY, WRONG_CARDS, JUMP_LONG, JUMP_SHORT, WRONG_HOLES, NO_SHIFT, WRONG_CARD,
		WRONG_WIRE, WRONG_MIN, WRONG_END, WRONG_PICK, MISSED, TEAR, LATE }

const EOL := "\n"            # end_of_line-teken van Algoritme 5 (weergave ⏎)
const STRIP_EMPTY := -1      # leeg vakje in de ponsstrook
const STRIP_BURNT := -2      # verbrand vakje (3-5)
const INF := 1 << 30         # "oneindig" (mismatches_ending als j < m−1)

const MACHINE_NAMES := ["brute", "rk", "kmp_table", "kmp", "bmh", "shift_and", "edit", "sabotage"]
## Stekkers van het ruisbord (GDD §3.6): oud ↓ (correct), oud, nieuw ↓, nieuw.
const PLUGS := ["old_shift", "old", "new_shift", "new"]


static func verdict_name(v: int) -> String:
	return Verdict.keys()[v] if v >= 0 and v < Verdict.size() else "?"


static func phase_name(p: int) -> String:
	return Phase.keys()[p] if p >= 0 and p < Phase.size() else "?"


static func machine_name(k: int) -> String:
	return MACHINE_NAMES[k] if k >= 0 and k < MACHINE_NAMES.size() else "?"


## "brute" | "rk" | … → TxCodes.Machine (−1 als onbekend).
static func machine_of(s: String) -> int:
	return MACHINE_NAMES.find(s)
