extends SceneTree
## Headless testrunner voor scripts/core/.
## "C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/run_tests.gd
## Optioneel filter: ... --script res://tests/run_tests.gd -- model   (enkel suites waarvan de naam "model" bevat)

const SUITES := [
	"res://tests/suites/t_hash_util.gd",
	"res://tests/suites/t_model.gd",
	"res://tests/suites/t_js_reference.gd",
	"res://tests/suites/t_properties.gd",
	"res://tests/suites/t_scoring.gd",
	"res://tests/suites/t_days.gd",
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
	var t0 := Time.get_ticks_msec()
	for path in SUITES:
		if filt != "" and not path.contains(filt):
			continue
		var scr = load(path)
		if scr == null:
			_fail("kan suite niet laden: " + path)
			continue
		var suite = scr.new()
		print("== ", path.get_file())
		suite.run(self)
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
	if same:
		passed += 1
	else:
		_fail("%s: kreeg %s, verwacht %s" % [msg, str(got), str(want)])
	return same
