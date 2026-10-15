class_name ScReader
## Broeder Letterlijk (GDD §8.4.1): de referentie-decoder. Leest de uitvoer van de speler exact volgens de regels van
## de notas (ScReference). Raadt nooit, verbetert nooit. Static en puur.
##
## read(kind, output, params) → {text, stuck, structure, symbols?}
##   kind ∈ "prefix", "prefix_greedy", "huffman", "adaptive", "arith", "lz77", "lzw", "bwt", "mtf"
##   output = ScTool.output() (of een gelijkaardige dictionary); params vult aan (code, model, n, G, list, start).


static func read(kind: String, output: Dictionary, params := {}) -> Dictionary:
	var o := output.duplicate()
	o.merge(params, false)
	match kind:
		"prefix", "huffman":
			var code: Dictionary = o.get("code", {})
			var d := ScReference.decode_prefix(code, str(o.get("bits", "")))
			var stuck := str(d.rest) != ""
			return {"text": str(d.text) + (ScCodes.STUCK if stuck else ""), "stuck": stuck, "symbols": d.symbols,
				"structure": {"code": code}}
		"prefix_greedy":
			var code2: Dictionary = o.get("code", {})
			var t := ScReference.greedy_read(code2, str(o.get("bits", "")))
			return {"text": t, "stuck": t.ends_with(ScCodes.STUCK), "structure": {"code": code2},
				"readings": Array(ScReference.all_parses(code2, str(o.get("bits", ""))))}
		"adaptive":
			var d2 := ScReference.adaptive_decode(o.get("tokens", []), str(o.get("start", "empty")))
			var tr: ScTree = d2.tree
			return {"text": d2.text, "stuck": d2.stuck, "structure": {"tree": tr.render(), "show": tr.show()}}
		"arith":
			var d3 := ScReference.arith_decode(str(o.get("bits", "")), int(o.get("n", 0)), o.get("model", []))
			return {"text": d3.text, "stuck": d3.stuck, "structure": {}}
		"lz77":
			var d4 := ScReference.lz77_decode_full(o.get("triples", []), int(o.get("G", -1)))
			return {"text": d4.text, "stuck": d4.stuck, "structure": {"windows": d4.windows}}
		"lzw":
			var d5 := ScReference.lzw_decode(o.get("codes", []))
			return {"text": d5.text, "stuck": d5.stuck, "structure": {"adds": d5.adds, "special": d5.special}}
		"bwt":
			var p := int(o.get("p", 0))
			var c := str(o.get("c", ""))
			var d6 := ScReference.inverse_bwt(p, c)
			return {"text": d6.text, "stuck": false, "structure": {"e": d6.e, "walk": d6.walk}}
		"mtf":
			var d7 := ScReference.mtf_decode(o.get("nums", []), o.get("list", []))
			return {"text": d7.text, "stuck": d7.stuck, "structure": {"lists": d7.lists}}
	return {"text": "", "stuck": true, "structure": {}}


## Leest een keten in omgekeerde volgorde (bv. 6-1: bwt → mtf; Codex: bwt → mtf → huffman). outputs/kinds/params in
## de volgorde van de zendstages. De uitvoer van een latere lezing is de invoer van de vorige: huffman → symbolen
## (getallen), mtf → tekst "p␣c", bwt → de tekst. → {text, stuck, steps:[{kind, text}]}
static func read_chain(outputs: Array, kinds: Array, params: Array) -> Dictionary:
	var steps: Array = []
	var carry: Variant = null
	var stuck := false
	for idx in range(kinds.size() - 1, -1, -1):
		var kind := str(kinds[idx])
		var o: Dictionary = (outputs[idx] as Dictionary).duplicate()
		var pr: Dictionary = params[idx] if idx < params.size() else {}
		if carry != null:
			match kind:
				"mtf":
					var nums: Array = []
					for s in carry:
						if not str(s).is_valid_int():
							stuck = true
							break
						nums.append(int(str(s)))
					o["nums"] = nums
				"bwt":
					var sp := ScReference.split_bwt_text(str(carry))
					if not bool(sp.ok):
						stuck = true
					o["p"] = int(sp.p)
					o["c"] = str(sp.c)
		var r := read(kind, o, pr)
		if bool(r.stuck):
			stuck = true
		steps.append({"kind": kind, "text": r.text})
		if kind in ["huffman", "prefix"]:
			carry = r.get("symbols", [])
		else:
			carry = str(r.text).trim_suffix(ScCodes.STUCK)
		if stuck:
			return {"text": str(r.text) if str(r.text).ends_with(ScCodes.STUCK) else str(r.text) + ScCodes.STUCK,
				"stuck": true, "steps": steps}
	var text := str(carry) if not carry is Array else "".join(PackedStringArray(carry))
	return {"text": text, "stuck": false, "steps": steps}


## {equal, marks (per positie van de langste van de twee: true = gelijk), first_diff (−1 als gelijk)}
static func compare(original: String, read_text: String) -> Dictionary:
	var n := maxi(original.length(), read_text.length())
	var marks: Array[bool] = []
	var first := -1
	for i in n:
		var same := i < original.length() and i < read_text.length() and original[i] == read_text[i]
		marks.append(same)
		if not same and first < 0:
			first = i
	return {"equal": original == read_text, "marks": marks, "first_diff": first}


## Incrementeel voor De Overkant: state = {tokens, start}. → {state, text, tree (render), show, stuck}
static func adaptive_feed(state: Dictionary, new_tokens: Array) -> Dictionary:
	var toks: Array = (state.get("tokens", []) as Array).duplicate(true)
	toks.append_array(new_tokens)
	var start := str(state.get("start", "empty"))
	var d := ScReference.adaptive_decode(toks, start)
	var tr: ScTree = d.tree
	return {"state": {"tokens": toks, "start": start}, "text": d.text, "tree": tr.render(), "show": tr.show(),
		"stuck": d.stuck}
