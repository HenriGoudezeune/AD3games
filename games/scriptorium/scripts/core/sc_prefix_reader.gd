class_name ScPrefixReader extends ScTool
## Codeboom (GDD §3.1): de speler klikt het blad waar de volgende bits naartoe leiden. Enkel klemmen, geen misstappen.
## stage {"tool":"prefix_read", "code":{…}, "bits":"00010011", "expect":"oud"}
## Zet: {"act":"read","leaf":id} — klem not_leaf, no_path, range.

var code: Dictionary = {}
var bits: String = ""
var expect: String = ""
var tree: ScTree
var pos: int = 0
var copy_text: String = ""


func _setup() -> void:
	tool = ScCodes.Tool.PREFIX_READ
	side = ScCodes.Side.RECEIVE
	code = stage.get("code", carry_in.get("code", {}))
	bits = str(stage.get("bits", ""))
	if bits == "" and stage.has("text"):
		bits = ScReference.encode_with(code, str(stage.text))
	expect = str(stage.get("expect", stage.get("text", "")))
	tree = ScTree.from_code(code)
	pos = 0
	copy_text = ""


func _begin() -> void:
	phase = P.READ
	if bits == "":
		_finish()


func rest() -> String:
	return bits.substr(pos)


func _judge(move: Dictionary) -> Dictionary:
	if str(move.get("act", "")) != "read":
		return {"ok": false, "reason": "unknown_act"}
	if phase != P.READ:
		return {"ok": false, "reason": "wrong_phase"}
	var id := int(move.get("leaf", -1))
	if not tree.alive(id):
		return {"ok": false, "reason": "range"}
	if not tree.is_leaf(id):
		return {"ok": false, "reason": "not_leaf", "at": id}
	var c := tree.code(id)
	if not rest().begins_with(c):
		return {"ok": false, "reason": "no_path", "at": id}
	return {"ok": true, "verdict": V.OK, "type": "READ", "data": {"leaf": id, "bits": c, "ch": tree.sym(id)}}


func _exec(_move: Dictionary, j: Dictionary, _e: Dictionary) -> void:
	var id := int(j.data.leaf)
	var c := tree.code(id)
	var path: Array[int] = tree.path(id)
	pos += c.length()
	copy_text += tree.sym(id)
	_copy_dirty = true
	_fx.append({"fx": "read_path", "leaf": id, "path": path, "bits": c, "ch": tree.sym(id)})
	if pos >= bits.length():
		_finish()


func _correct() -> Dictionary:
	for x in tree.leaves():
		if rest().begins_with(tree.code(x)):
			return {"act": "read", "leaf": x}
	return {"act": "none"}


func _impossible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for x in tree.ids():
		if not tree.is_leaf(x) or not rest().begins_with(tree.code(x)):
			out.append({"act": "read", "leaf": x})
	out.append({"act": "read", "leaf": 999})
	return out


func _at() -> int:
	return copy_text.length()


func copy() -> String:
	return copy_text


func _output() -> Dictionary:
	return {"kind": "copy", "text": copy_text}


func structure() -> Dictionary:
	return {"copy": copy_text}


func _cursor() -> Dictionary:
	return {"pos": pos, "rest": rest(), "copy": copy_text, "tree": tree.render(), "bits": bits}


func _snap() -> Dictionary:
	return {"pos": pos, "copy": copy_text}


func _restore(d: Dictionary) -> void:
	pos = int(d.get("pos", 0))
	copy_text = str(d.get("copy", ""))


func _invariants() -> PackedStringArray:
	var e := PackedStringArray()
	var dec := ScReference.decode_prefix(code, bits.substr(0, pos))
	if str(dec.text) != copy_text:
		e.append("kopie %s past niet bij de gelezen bits" % copy_text)
	return e
