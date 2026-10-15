class_name ScShelf extends ScTool
## Letterplank (GDD §3.9): move-to-front, zenden en ontvangen. Posities vanaf 0 (p. 121).
## Zenden (fase NUMBER): {"act":"number","k":k}: de positie van het volgende teken in de lijst zoals ze nu is.
##   Jouw plank zet het echte teken vooraan; de plank van Letterlijk (mirror) zet list′[k] vooraan.
## Ontvangen (fase PICK_BLOCK): {"act":"pick","k":k}: het blokje op positie k.
## stage {"tool":"shelf","side":"send","input":"carry"|"1 ngen eool","list":[…]}
##       {"tool":"shelf","side":"receive","nums":[1,1,7,…],"list":[…],"expect":"1 ngen eool"}

var input: String = ""
var nums: Array[int] = []
var start_list: Array = []
var list: Array = []
var mirror: Array = []
var i: int = 0
var out: Array[int] = []
var copy_text: String = ""
var expect: String = ""
var show_positions: bool = false
var extended: Array = []          # tekens die achteraan bijgezet werden (niet in de lijst van de opgave)


func _setup() -> void:
	tool = ScCodes.Tool.SHELF
	expect = str(stage.get("expect", ""))
	show_positions = bool(stage.get("positions", false))
	start_list = []
	for x in stage.get("list", []):
		start_list.append(str(x))
	list = start_list.duplicate()
	mirror = start_list.duplicate()
	if side == ScCodes.Side.SEND:
		var inp = stage.get("input", "")
		input = str(carry_in.get("text", "")) if str(inp) == "carry" else str(inp)
		# een teken dat niet op de plank staat (bv. een andere p na een fout rek): achteraan bijzetten
		extended = []
		for ch in input:
			if not start_list.has(ch):
				start_list.append(ch)
				extended.append(ch)
		list = start_list.duplicate()
		mirror = start_list.duplicate()
	else:
		nums = ints(stage.get("nums", []))
	i = 0
	out = []
	copy_text = ""


func _begin() -> void:
	if side == ScCodes.Side.SEND:
		phase = P.NUMBER
		if input == "":
			_finish()
	else:
		phase = P.PICK_BLOCK
		if nums.is_empty():
			_finish()


static func _front(l: Array, k: int) -> void:
	var x = l[k]
	l.remove_at(k)
	l.insert(0, x)


func _judge(move: Dictionary) -> Dictionary:
	var act := str(move.get("act", ""))
	var k := int(move.get("k", -1))
	if side == ScCodes.Side.SEND:
		if act != "number":
			return {"ok": false, "reason": "unknown_act"}
		if phase != P.NUMBER:
			return {"ok": false, "reason": "wrong_phase"}
		if k < 0 or k >= list.size():
			return {"ok": false, "reason": "range", "at": k}
		var want := list.find(input[i])
		return {"ok": true, "verdict": V.OK if k == want else V.WRONG_INDEX, "type": "NUMBER",
			"data": {"x": input[i], "k": want, "chosen": k}}
	if act != "pick":
		return {"ok": false, "reason": "unknown_act"}
	if phase != P.PICK_BLOCK:
		return {"ok": false, "reason": "wrong_phase"}
	if k < 0 or k >= list.size():
		return {"ok": false, "reason": "range", "at": k}
	return {"ok": true, "verdict": V.OK if k == nums[i] else V.WRONG_INDEX, "type": "PICK",
		"data": {"x": str(list[nums[i]]) if nums[i] < list.size() else "?", "k": nums[i], "chosen": k}}


func _exec(move: Dictionary, _j: Dictionary, _e: Dictionary) -> void:
	var k := int(move.k)
	if side == ScCodes.Side.SEND:
		out.append(k)
		if k == 0:
			counters.zeros = int(counters.zeros) + 1
		_fx.append({"fx": "number", "k": k})
		var real := list.find(input[i])
		_front(list, real)
		_front(mirror, k)
		_fx.append({"fx": "shelf_move", "k": real, "ch": input[i], "list": list.duplicate()})
		_out_dirty = true
		_overkant_dirty = true
		i += 1
		if i >= input.length():
			_finish()
	else:
		var ch := str(list[k])
		copy_text += ch
		_copy_dirty = true
		_front(list, k)
		_fx.append({"fx": "shelf_move", "k": k, "ch": ch, "list": list.duplicate()})
		i += 1
		if i >= nums.size():
			_finish()


func _correct() -> Dictionary:
	if side == ScCodes.Side.SEND:
		if phase != P.NUMBER or list.find(input[i]) < 0:
			return {"act": "none"}
		return {"act": "number", "k": list.find(input[i])}
	return {"act": "pick", "k": nums[i]} if phase == P.PICK_BLOCK else {"act": "none"}


func _wrong() -> Array[Dictionary]:
	var o: Array[Dictionary] = []
	if phase != P.NUMBER and phase != P.PICK_BLOCK:
		return o
	var good := int(_correct().k)
	var act := "number" if side == ScCodes.Side.SEND else "pick"
	for k in [good + 1, good - 1]:
		if k >= 0 and k < list.size():
			o.append({"act": act, "k": k})
	return o


func _impossible() -> Array[Dictionary]:
	var act := "number" if side == ScCodes.Side.SEND else "pick"
	return [{"act": act, "k": list.size()}, {"act": act, "k": -1}]


func _at() -> int:
	return i


func copy() -> String:
	return copy_text if side == ScCodes.Side.RECEIVE else ""


func overkant() -> Dictionary:
	return {"list": mirror.duplicate()} if side == ScCodes.Side.SEND else {}


func _output() -> Dictionary:
	if side == ScCodes.Side.RECEIVE:
		return {"kind": "copy", "text": copy_text}
	var syms: Array = []
	for x in out:
		syms.append(str(x))
	return {"kind": "numbers", "nums": out.duplicate(), "list": start_list.duplicate(), "symbols": syms,
		"zeros": int(counters.zeros)}


func structure() -> Dictionary:
	return {"nums": out.duplicate(), "list": list.duplicate()} if side == ScCodes.Side.SEND \
			else {"copy": copy_text, "list": list.duplicate()}


func _cursor() -> Dictionary:
	var c := {"list": list.duplicate(), "i": i, "show_positions": show_positions, "side": side,
		"start_list": start_list.duplicate(), "extended": extended.duplicate()}
	if side == ScCodes.Side.SEND:
		c["input"] = input
		c["out"] = out.duplicate()
		c["mirror"] = mirror.duplicate()
		c["ch"] = input[i] if i < input.length() else ""
	else:
		c["nums"] = nums.duplicate()
		c["copy"] = copy_text
	return c


func _snap() -> Dictionary:
	return {"list": list.duplicate(), "mirror": mirror.duplicate(), "i": i, "out": out.duplicate(), "copy": copy_text}


func _restore(d: Dictionary) -> void:
	list = []
	for x in d.get("list", []):
		list.append(str(x))
	mirror = []
	for x in d.get("mirror", []):
		mirror.append(str(x))
	i = int(d.get("i", 0))
	out = ints(d.get("out", []))
	copy_text = str(d.get("copy", ""))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	var a := list.duplicate()
	var b := start_list.duplicate()
	a.sort()
	b.sort()
	if a != b:
		e.append("de plank verloor blokjes")
	if side == ScCodes.Side.SEND and out.count(0) != int(counters.zeros):
		e.append("nullen-teller klopt niet")
	return e
