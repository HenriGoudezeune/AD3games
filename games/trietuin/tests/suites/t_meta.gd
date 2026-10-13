extends RefCounted
## Meta: de core is puur (geen nodes/Engine/Time) en elke class_name begint met Tt.

func run(t) -> void:
	t.section("core is puur")
	var d := DirAccess.open("res://games/trietuin/scripts/core")
	var files := 0
	for f in d.get_files():
		if not f.ends_with(".gd"):
			continue
		files += 1
		var src := FileAccess.get_file_as_string("res://games/trietuin/scripts/core/" + f)
		t.ok(not src.contains("extends Node") and not src.contains("extends Control"), f + ": geen nodes")
		t.ok(not src.contains("Engine.") and not src.contains("Time."), f + ": geen Engine/Time")
		var cn := src.get_slice("class_name ", 1).get_slice(" ", 0).get_slice("\n", 0)
		t.ok(cn.begins_with("Tt"), f + ": class_name %s begint met Tt" % cn)
		var s = load("res://games/trietuin/scripts/core/" + f)
		t.ok(s != null and s.can_instantiate(), f + ": compileert")
	t.ok(files >= 22, "%d core-bestanden" % files)
