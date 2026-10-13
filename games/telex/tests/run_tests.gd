extends SceneTree
## Headless testrunner voor games/telex/scripts/core/ (GDD §9).
## Godot --headless --path . --script res://games/telex/tests/run_tests.gd
## Optioneel filter: ... --script res://games/telex/tests/run_tests.gd -- reference   (suites waarvan de naam
## "reference" bevat), of een kommalijst van exacte suitenamen (t_reference,t_machines).

const SUITES := [
	"res://games/telex/tests/suites/t_reference.gd",
	"res://games/telex/tests/suites/t_properties.gd",
	"res://games/telex/tests/suites/t_machines.gd",
	"res://games/telex/tests/suites/t_machines2.gd",
	"res://games/telex/tests/suites/t_levels.gd",
	"res://games/telex/tests/suites/t_meta.gd",
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


## Gelijkheid; arrays (ook getypeerde/packed) worden elementsgewijs vergeleken, int == float als de waarde gelijk is.
func eq(got, want, msg: String = "") -> bool:
	var same := _same(got, want)
	if same:
		passed += 1
	else:
		_fail("%s: kreeg %s, verwacht %s" % [msg, str(got), str(want)])
	return same


func _same(a, b) -> bool:
	if (typeof(a) in [TYPE_INT, TYPE_FLOAT]) and (typeof(b) in [TYPE_INT, TYPE_FLOAT]):
		return is_equal_approx(float(a), float(b))
	var arr_a := a is Array or a is PackedStringArray or a is PackedInt32Array or a is PackedInt64Array
	var arr_b := b is Array or b is PackedStringArray or b is PackedInt32Array or b is PackedInt64Array
	if arr_a and arr_b:
		var x := Array(a)
		var y := Array(b)
		if x.size() != y.size():
			return false
		for i in x.size():
			if not _same(x[i], y[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if (a as Dictionary).size() != (b as Dictionary).size():
			return false
		for k in a:
			if not (b as Dictionary).has(k) or not _same(a[k], b[k]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b
