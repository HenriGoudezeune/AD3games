class_name DaySpec extends RefCounted
## Configuratie van één dag (of fase), GDD §5 en §10.5.

enum Mode { CALM, REALTIME }
enum BitHint { FULL, COLORS, NONE }

var id: String = ""
var title: String = ""
var n: int = 5
var g: int = 2
var a0: int = 1
var start_layout: Array = []          # formaat van ExtHashModel.load_layout; [] = leeg (setup)
var keys: Array[Dictionary] = []      # [{"hv":"11110", "label":"", "clone":false}]; leeg -> generator
var generator: Dictionary = {}        # endless: {seed, clone_after, clone_every}
var mode: int = Mode.CALM
var bit_hint: int = BitHint.FULL
var loupe_allowed: bool = false
var overflow_bin: bool = false
var spawn_interval: float = 2.5
var belt_time: float = 14.0
var burst_time: float = 0.0           # <= 0: geen burst
var customers: Array[Dictionary] = [] # [{"t":20.0, "hv":"01101", "patience":15.0}]
var customer_gen: Dictionary = {}     # {start, every, patience, seed} of {}
var reputation: int = 5
## [{"kind":"done"}, {"kind":"no_mistakes"[, "all_customers":true]}, {"kind":"io_optimal"} | {"kind":"time","max":40}
##  | {"kind":"no_doubles"} (= 0 verdubbelingen én ritten <= optimum) | {"kind":"end_state"}]. [] = geen sterren.
var stars: Array[Dictionary] = []
var hints: Array[Dictionary] = []     # [{"trigger":"first_block", "anchor":"lever", "ghost":"drag_lever", "text":"..."}]
var phases: Array[DaySpec] = []       # dag 7: ochtend + middag
var expect_end: Dictionary = {}       # acceptatie (§11): {a, layout:[{label, hvs}], reads, writes, doubles, splits, dumped}

# --- aanvullingen (wensen front-end) ---
var intro: String = ""                # één zin voor de dagintro (<= 8 woorden)
var icon: String = ""                 # hatch|lever|saw|desk|storm|book|clones|endless
var show_keys: bool = false           # dag 6: pakjes tonen sleutel (#45) én hashwaarde
var endless: bool = false
var day_number: int = 0               # 1..7, 0 = endless
var no_stars: bool = false            # dag 7 ochtend: verplicht, geen sterreneffect


func is_realtime() -> bool:
	return mode == Mode.REALTIME


func has_customers() -> bool:
	return not customers.is_empty() or not customer_gen.is_empty()


## Sleutels als ints.
func key_hvs() -> Array[int]:
	var out: Array[int] = []
	for k in keys:
		out.append(HashUtil.from_bits(str(k.hv)))
	return out
