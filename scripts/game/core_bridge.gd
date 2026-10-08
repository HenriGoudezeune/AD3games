class_name CoreBridge
extends Object
## Tijdelijke dunne adapter: laadt scripts/core/<naam>.gd als die bestaat, anders scripts/game/stub/<naam>.gd.
## Zodra de core volledig is (STATUS.md "core-API beschikbaar") kan stub/ weg.

static var _cache := {}


static func cls(name_: String) -> GDScript:
	if _cache.has(name_):
		return _cache[name_]
	var p := "res://scripts/core/%s.gd" % name_
	var s: GDScript = null
	if core_complete():
		s = load(p)
	else:
		s = load("res://scripts/game/stub/%s.gd" % name_)
		print("CoreBridge: stub voor ", name_)
	_cache[name_] = s
	return s


## Core pas gebruiken als de hele set er is (gemengd stub/core kan botsen) en niet geforceerd met --stub.
static func core_complete() -> bool:
	if OS.get_cmdline_user_args().has("--stub"):
		return false
	for n in ["day_spec", "days", "day_director", "scoring", "save_data"]:
		if not ResourceLoader.exists("res://scripts/core/%s.gd" % n):
			return false
	return true


static func days() -> GDScript:
	return cls("days")


static func using_stub(name_: String) -> bool:
	return not core_complete()
