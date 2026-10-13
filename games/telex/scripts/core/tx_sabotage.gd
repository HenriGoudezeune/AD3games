class_name TxSabotage extends TxMachine
## Tegenzet-missies (Oef. 32, 34b, 50; GDD §3.9): de speler schrijft z en t, de vijandige machine (TxReference)
## draait en de metriek telt.
## COMPOSE: {"act":"set","which":"z"|"t","i":i,"ch":c} · {"act":"send"} · {"act":"finish"}.
## target: "brute" (tikken Alg. 2, FIRST) · "rk_calls" (oproepen strings_gelijk, FIRST) · "bmh_min" (tikken BMH,
## z ∉ t verplicht, zo weinig mogelijk) · "bmh_max" (tikken BMH, zo veel mogelijk).

var target: String = "brute"
var alphabet: String = "ab"
var z_fixed: String = ""
var q: int = 0
var zt: String = ""
var tt: String = ""
var best: int = -1
var last: int = -1
var last_valid: bool = false
var sent_current: bool = false
var sends: int = 0
var optimum: int = -1
var example: Dictionary = {}


func _setup() -> void:
	kind = TxCodes.Machine.SABOTAGE
	target = str(stage.get("target", "brute"))
	alphabet = str(stage.get("alphabet", "ab"))
	z_fixed = str(stage.get("z_fixed", ""))
	q = int(stage.get("q", 0))
	var nn := int(stage.get("n", 12))
	var mm := int(stage.get("m", 4))
	zt = z_fixed if z_fixed != "" else alphabet[0].repeat(mm)
	tt = alphabet[0].repeat(nn)
	z = zt
	t = tt
	m = zt.length()
	n = tt.length()
	front = n
	best = -1
	last = -1
	last_valid = false
	sent_current = false
	sends = 0
	optimum = int(stage.get("optimum", -1))
	example = stage.get("example", {})


func _make_truth() -> Array[Dictionary]:
	return []


func minimize() -> bool:
	return target == "bmh_min"


func _begin() -> void:
	phase = P.COMPOSE


## Metriek van de vijandige machine voor (z, t): {metric, valid, trace}.
func enemy(zz: String, tx: String) -> Dictionary:
	match target:
		"brute":
			var r := TxReference.brute(zz, tx, false)
			return {"metric": int(r.cmp), "valid": true, "trace": r.trace}
		"rk_calls":
			var r2 := TxReference.rk(zz, tx, q, false)
			return {"metric": r2.calls.size(), "valid": true, "trace": r2.calls}
		"bmh_min", "bmh_max":
			var r3 := TxReference.bmh(zz, tx, false)
			var valid := target == "bmh_max" or not tx.contains(zz)
			return {"metric": int(r3.cmp), "valid": valid, "trace": r3.trace}
	return {"metric": 0, "valid": false, "trace": []}


func _judge(move: Dictionary) -> Dictionary:
	if phase != P.COMPOSE:
		return {"ok": false, "reason": "wrong_phase"}
	match str(move.get("act", "")):
		"set":
			var which := str(move.get("which", ""))
			var idx := int(move.get("i", -1))
			var ch := str(move.get("ch", ""))
			if which == "z" and z_fixed != "":
				return {"ok": false, "reason": "not_now"}
			var s := zt if which == "z" else (tt if which == "t" else "")
			if s == "" or idx < 0 or idx >= s.length() or ch.length() != 1 or not alphabet.contains(ch):
				return {"ok": false, "reason": "range", "at": idx}
			return {"ok": true, "verdict": V.OK, "type": "SET", "data": {"which": which, "i": idx, "ch": ch}}
		"send":
			return {"ok": true, "verdict": V.OK, "type": "SEND", "data": {"z": zt, "t": tt}}
		"finish":
			if best < 0:
				return {"ok": false, "reason": "not_now"}
			return {"ok": true, "verdict": V.OK, "type": "FINISH", "data": {"best": best}}
	return {"ok": false, "reason": "unknown_act"}


func _exec(move: Dictionary, _j: Dictionary, e: Dictionary) -> void:
	match str(move.act):
		"set":
			var idx := int(move.i)
			var ch := str(move.ch)
			if str(move.which) == "z":
				zt = zt.substr(0, idx) + ch + zt.substr(idx + 1)
				z = zt
			else:
				tt = tt.substr(0, idx) + ch + tt.substr(idx + 1)
				t = tt
			sent_current = false
			_fx.append({"fx": "compose", "which": str(move.which), "i": idx, "ch": ch})
		"send":
			var r := enemy(zt, tt)
			last = int(r.metric)
			last_valid = bool(r.valid)
			sent_current = true
			sends += 1
			if last_valid and (best < 0 or (last < best if minimize() else last > best)):
				best = last
			e.data["metric"] = last
			e.data["valid"] = last_valid
			_fx.append({"fx": "enemy_run", "metric": last, "trace": r.trace, "valid": last_valid})
		"finish":
			_finish_stage()


func _correct() -> Dictionary:
	if phase != P.COMPOSE:
		return {"act": "none"}
	var ez := str(example.get("z", zt))
	var et := str(example.get("t", tt))
	for idx in zt.length():
		if idx < ez.length() and zt[idx] != ez[idx] and z_fixed == "":
			return {"act": "set", "which": "z", "i": idx, "ch": ez[idx]}
	for idx in tt.length():
		if idx < et.length() and tt[idx] != et[idx]:
			return {"act": "set", "which": "t", "i": idx, "ch": et[idx]}
	if not sent_current:
		return {"act": "send"}
	return {"act": "finish"}


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if phase == P.COMPOSE:
		out.append({"act": "set", "which": "t", "i": -1, "ch": alphabet[0]})
		out.append({"act": "set", "which": "t", "i": 0, "ch": "#"})
		if z_fixed != "":
			out.append({"act": "set", "which": "z", "i": 0, "ch": alphabet[0]})
		if best < 0:
			out.append({"act": "finish"})
	return out


func cursor() -> Dictionary:
	return {"phase": phase, "z": zt, "t": tt, "best": best, "last": last, "last_valid": last_valid,
		"optimum": optimum, "target": target, "alphabet": alphabet, "z_fixed": z_fixed != "", "sends": sends}


func _output() -> Dictionary:
	return {"sabotage": {"target": target, "best": best, "optimum": optimum, "z": zt, "t": tt}}


func _snap() -> Dictionary:
	return {"zt": zt, "tt": tt, "best": best, "last": last, "last_valid": last_valid, "sent": sent_current,
		"sends": sends}


func _restore(d: Dictionary) -> void:
	zt = str(d.get("zt", zt))
	tt = str(d.get("tt", tt))
	z = zt
	t = tt
	best = int(d.get("best", -1))
	last = int(d.get("last", -1))
	last_valid = bool(d.get("last_valid", false))
	sent_current = bool(d.get("sent", false))
	sends = int(d.get("sends", 0))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	for c in zt + tt:
		if not alphabet.contains(c):
			e.append("teken %s buiten het alfabet" % c)
			break
	if z_fixed != "" and zt != z_fixed:
		e.append("vaste z gewijzigd")
	return e
