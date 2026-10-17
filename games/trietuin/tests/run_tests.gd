extends SceneTree
## Headless testrunner voor games/trietuin/scripts/core/.
## Godot --headless --path . --script res://games/trietuin/tests/run_tests.gd
## Optioneel filter: ... --script res://games/trietuin/tests/run_tests.gd -- trie   (enkel suites waarvan het pad "trie" bevat)

const SUITES := [
	"res://games/trietuin/tests/suites/t_basics.gd",
	"res://games/trietuin/tests/suites/t_trie.gd",
	"res://games/trietuin/tests/suites/t_patricia.gd",
	"res://games/trietuin/tests/suites/t_ternary.gd",
	"res://games/trietuin/tests/suites/t_suffix.gd",
	"res://games/trietuin/tests/suites/t_ukkonen.gd",
	"res://games/trietuin/tests/suites/t_levels.gd",
	"res://games/trietuin/tests/suites/t_properties.gd",
	"res://games/trietuin/tests/suites/t_meta.gd",
	"res://games/trietuin/tests/suites/t_lessons.gd",
]

var passed := 0
var failed := 0
var failures: PackedStringArray = []
var _section := ""


func _init() -> void:
	var filt := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filt = args[0]
	var only := filt.split(",") if filt.contains(",") else PackedStringArray()
	var t0 := Time.get_ticks_msec()
	for path in SUITES:
		if filt != "" and only.is_empty() and not path.get_file().contains(filt):
			continue
		if not only.is_empty() and not only.has(path.get_file().get_basename()):
			continue
		if not ResourceLoader.exists(path):
			continue
		var scr = load(path)
		if scr == null or not scr.can_instantiate():
			section(path.get_file())
			_fail("kan suite niet laden/compileren: " + path)
			continue
		var suite = scr.new()
		print("== ", path.get_file())
		var p0 := passed
		var f0 := failed
		var ts := Time.get_ticks_msec()
		suite.run(self)
		print("   %d ok, %d fout (%d ms)" % [passed - p0, failed - f0, Time.get_ticks_msec() - ts])
	print("")
	for f in failures:
		print("FAIL: ", f)
	print("asserts geslaagd: %d, gefaald: %d (%d ms)" % [passed, failed, Time.get_ticks_msec() - t0])
	print("RESULTAAT: ", "OK" if failed == 0 and passed > 0 else "GEFAALD")
	quit(0 if failed == 0 and passed > 0 else 1)


func section(name: String) -> void:
	_section = name


func _fail(msg: String) -> void:
	failed += 1
	if failures.size() < 400:
		failures.append("[%s] %s" % [_section, msg])


func ok(cond: bool, msg: String = "") -> bool:
	if cond:
		passed += 1
	else:
		_fail(msg)
	return cond


func eq(got, want, msg: String = "") -> bool:
	var same: bool = typeof(got) == typeof(want) and got == want
	if not same and (typeof(got) in [TYPE_INT, TYPE_FLOAT]) and (typeof(want) in [TYPE_INT, TYPE_FLOAT]):
		same = is_equal_approx(float(got), float(want))
	if not same and (got is Array or got is PackedStringArray or got is PackedInt32Array) and \
			(want is Array or want is PackedStringArray or want is PackedInt32Array):
		same = Array(got) == Array(want)
	if same:
		passed += 1
	else:
		_fail("%s: kreeg %s, verwacht %s" % [msg, str(got), str(want)])
	return same


## Vergelijkt notaties zonder spaties.
func notation(got: String, want: String, msg: String = "") -> bool:
	return eq(TtNotation.normalize(got), TtNotation.normalize(want), msg)
