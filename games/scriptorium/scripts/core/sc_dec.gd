class_name ScDec extends RefCounted
## Exacte decimale getallen van willekeurige precisie (GDD §8.3): waarde = (−1)^neg · mag · 10^(−scale), met mag een
## natuurlijk getal in limbs van 10^9 (little-endian). Altijd genormaliseerd (geen nullen achteraan als scale > 0),
## zodat gelijke waarden gelijke voorstellingen hebben. Onveranderlijk: elke bewerking geeft een nieuw object.

const BASE := 1000000000
const BASE_DIGITS := 9

var mag: Array[int] = []      # [] = 0
var neg: bool = false
var scale: int = 0


# ------------------------------------------------------------------ constructie

static func zero() -> ScDec:
	return ScDec.new()


static func one() -> ScDec:
	return from_int(1)


static func from_int(v: int) -> ScDec:
	var d := ScDec.new()
	d.neg = v < 0
	var x := absi(v)
	while x > 0:
		d.mag.append(x % BASE)
		x = x / BASE
	if d.mag.is_empty():
		d.neg = false
	return d


## "0.2", "0,034", "1", "0", "-0.5". Ongeldige invoer → 0.
static func from_string(s: String) -> ScDec:
	var t := s.strip_edges().replace(",", ".")
	var d := ScDec.new()
	if t.begins_with("-"):
		d.neg = true
		t = t.substr(1)
	var parts := t.split(".")
	var ip := parts[0] if parts.size() > 0 else "0"
	var fp := parts[1] if parts.size() > 1 else ""
	var digits := ip + fp
	for ch in digits:
		if not ch in "0123456789":
			return ScDec.new()
	d.scale = fp.length()
	d.mag = _from_digits(digits)
	d._normalize()
	return d


## num / 2^pow2, exact (num · 5^pow2 · 10^(−pow2)).
static func dyadic(num: int, pow2: int) -> ScDec:
	var d := from_int(num)
	for i in pow2:
		d.mag = _mul_small(d.mag, 5)
	d.scale = pow2
	d._normalize()
	return d


## Waarde van een bitstring b1…bk = Σ bi·2^(−i) (p. 101).
static func from_bits(bits: String) -> ScDec:
	var v := ScDec.zero()
	var step := ScDec.one().half()
	for ch in bits:
		if ch == "1":
			v = v.add(step)
		step = step.half()
	return v


func copy() -> ScDec:
	var d := ScDec.new()
	d.mag = mag.duplicate()
	d.neg = neg
	d.scale = scale
	return d


# ------------------------------------------------------------------ rekenen

func add(o: ScDec) -> ScDec:
	var s := maxi(scale, o.scale)
	var a := _shift(mag, s - scale)
	var b := _shift(o.mag, s - o.scale)
	var r := ScDec.new()
	r.scale = s
	if neg == o.neg:
		r.mag = _add_mag(a, b)
		r.neg = neg
	else:
		var c := _cmp_mag(a, b)
		if c == 0:
			return ScDec.zero()
		if c > 0:
			r.mag = _sub_mag(a, b)
			r.neg = neg
		else:
			r.mag = _sub_mag(b, a)
			r.neg = o.neg
	r._normalize()
	return r


func sub(o: ScDec) -> ScDec:
	return add(o.negated())


func negated() -> ScDec:
	var d := copy()
	if not d.mag.is_empty():
		d.neg = not d.neg
	return d


func mul(o: ScDec) -> ScDec:
	var r := ScDec.new()
	r.mag = _mul_mag(mag, o.mag)
	r.scale = scale + o.scale
	r.neg = (neg != o.neg) and not r.mag.is_empty()
	r._normalize()
	return r


func half() -> ScDec:
	var r := ScDec.new()
	r.mag = _mul_small(mag, 5)
	r.scale = scale + 1
	r.neg = neg
	r._normalize()
	return r


func cmp(o: ScDec) -> int:
	if neg != o.neg:
		if is_zero() and o.is_zero():
			return 0
		return -1 if neg else 1
	var s := maxi(scale, o.scale)
	var c := _cmp_mag(_shift(mag, s - scale), _shift(o.mag, s - o.scale))
	return -c if neg else c


func lt(o: ScDec) -> bool:
	return cmp(o) < 0


func le(o: ScDec) -> bool:
	return cmp(o) <= 0


func gt(o: ScDec) -> bool:
	return cmp(o) > 0


func ge(o: ScDec) -> bool:
	return cmp(o) >= 0


func eq(o: ScDec) -> bool:
	return cmp(o) == 0


func is_zero() -> bool:
	return mag.is_empty()


# ------------------------------------------------------------------ weergave

## Alle cijfers met een punt: "0.34", "1", "0", "-0.5".
func to_full_string() -> String:
	var dg := _digits(mag)
	if scale > 0:
		while dg.length() <= scale:
			dg = "0" + dg
		dg = dg.substr(0, dg.length() - scale) + "." + dg.substr(dg.length() - scale)
	return ("-" if neg else "") + dg


func _to_string() -> String:
	return to_full_string()


## Voor de UI: komma als decimaalteken, ten hoogste max_sig beduidende cijfers, "…" bij afkapping.
func to_string_sig(max_sig := 12) -> String:
	var full := to_full_string()
	var sign := ""
	if full.begins_with("-"):
		sign = "-"
		full = full.substr(1)
	var dot := full.find(".")
	if dot < 0:
		return sign + full
	var ip := full.substr(0, dot)
	var fp := full.substr(dot + 1)
	var sig := 0 if ip == "0" else ip.length()
	var out := ""
	var started := ip != "0"
	var cut := false
	for i in fp.length():
		if sig >= max_sig:
			cut = true
			break
		var ch := fp[i]
		out += ch
		if ch != "0":
			started = true
		if started:
			sig += 1
	return sign + ip + "," + out + ("…" if cut else "")


func to_float() -> float:
	return to_full_string().to_float()


# ------------------------------------------------------------------ intern: normalisatie

func _normalize() -> void:
	mag = _trim(mag)
	while scale > 0 and not mag.is_empty() and mag[0] % 10 == 0:
		mag = _div_small(mag, 10)
		scale -= 1
	if mag.is_empty():
		neg = false
		scale = 0


# ------------------------------------------------------------------ intern: natuurlijke getallen (limbs)

static func _trim(a: Array[int]) -> Array[int]:
	var r := a.duplicate()
	while not r.is_empty() and r[r.size() - 1] == 0:
		r.pop_back()
	return r


static func _from_digits(digits: String) -> Array[int]:
	var r: Array[int] = []
	var i := digits.length()
	while i > 0:
		var j := maxi(0, i - BASE_DIGITS)
		r.append(digits.substr(j, i - j).to_int())
		i = j
	return _trim(r)


static func _digits(a: Array[int]) -> String:
	if a.is_empty():
		return "0"
	var s := str(a[a.size() - 1])
	for i in range(a.size() - 2, -1, -1):
		s += str(a[i]).pad_zeros(BASE_DIGITS)
	return s


static func _cmp_mag(a: Array[int], b: Array[int]) -> int:
	if a.size() != b.size():
		return 1 if a.size() > b.size() else -1
	for i in range(a.size() - 1, -1, -1):
		if a[i] != b[i]:
			return 1 if a[i] > b[i] else -1
	return 0


static func _add_mag(a: Array[int], b: Array[int]) -> Array[int]:
	var r: Array[int] = []
	var carry := 0
	for i in maxi(a.size(), b.size()):
		var s: int = carry + (a[i] if i < a.size() else 0) + (b[i] if i < b.size() else 0)
		r.append(s % BASE)
		carry = s / BASE
	if carry > 0:
		r.append(carry)
	return _trim(r)


## a − b met a ≥ b.
static func _sub_mag(a: Array[int], b: Array[int]) -> Array[int]:
	var r: Array[int] = []
	var borrow := 0
	for i in a.size():
		var s: int = a[i] - borrow - (b[i] if i < b.size() else 0)
		if s < 0:
			s += BASE
			borrow = 1
		else:
			borrow = 0
		r.append(s)
	return _trim(r)


static func _mul_small(a: Array[int], k: int) -> Array[int]:
	var r: Array[int] = []
	var carry := 0
	for x in a:
		var s: int = x * k + carry
		r.append(s % BASE)
		carry = s / BASE
	while carry > 0:
		r.append(carry % BASE)
		carry = carry / BASE
	return _trim(r)


static func _div_small(a: Array[int], k: int) -> Array[int]:
	var r: Array[int] = []
	r.resize(a.size())
	var rem := 0
	for i in range(a.size() - 1, -1, -1):
		var cur: int = rem * BASE + a[i]
		r[i] = cur / k
		rem = cur % k
	return _trim(r)


static func _mul_mag(a: Array[int], b: Array[int]) -> Array[int]:
	if a.is_empty() or b.is_empty():
		return []
	var r: Array[int] = []
	r.resize(a.size() + b.size())
	r.fill(0)
	for i in a.size():
		var carry := 0
		var ai: int = a[i]
		for j in b.size():
			var cur: int = r[i + j] + ai * b[j] + carry
			r[i + j] = cur % BASE
			carry = cur / BASE
		var k := i + b.size()
		while carry > 0:
			var cur2: int = r[k] + carry
			r[k] = cur2 % BASE
			carry = cur2 / BASE
			k += 1
	return _trim(r)


## a · 10^k
static func _shift(a: Array[int], k: int) -> Array[int]:
	var r := a.duplicate()
	var left := k
	while left > 0:
		var step := mini(left, BASE_DIGITS - 1)
		var f := 1
		for i in step:
			f *= 10
		r = _mul_small(r, f)
		left -= step
	return r
