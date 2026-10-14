extends SceneTree
var passed := 0
var failed := 0
func section(_n): pass
func ok(c, m := ""):
	if c: passed += 1
	else:
		failed += 1
		print("FAIL ", m)
	return c
func eq(a, b, m := ""):
	return ok(JSON.stringify(a) == JSON.stringify(b) or str(a) == str(b), m + ": " + str(a) + " vs " + str(b))
func _init() -> void:
	var s = load("res://games/scriptorium/tests/suites/t_levels.gd").new()
	for f in ["_t33_t34", "_t35", "_t36", "_t37", "_t38", "_director", "_unlock", "_wake"]:
		var t0 := Time.get_ticks_msec()
		s.call(f, self)
		print(f, " ", Time.get_ticks_msec() - t0, " ms  ok ", passed, " fail ", failed)
	quit(0)
