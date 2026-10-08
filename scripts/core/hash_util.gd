class_name HashUtil
## Bit-hulpfuncties in de notatie van de notas (§2.1.1).
## Bitposities zijn 1-gebaseerd vanaf de meest significante bit. x|k = eerste k bits van x.


## bits(2, 5) == "00010"; w <= 0 -> "".
static func bits(x: int, w: int) -> String:
	if w <= 0:
		return ""
	var s := ""
	for i in range(w - 1, -1, -1):
		s += "1" if (x >> i) & 1 else "0"
	return s


## x|k: het getal gevormd door de eerste k bits van x (x heeft n bits).
## prefix(0b010011, 6, 3) == 2.
static func prefix(x: int, n: int, k: int) -> int:
	if k <= 0:
		return 0
	if k >= n:
		return x
	return x >> (n - k)


## Bit nummer pos (1..n, vanaf de MSB) van x.
static func bit_at(x: int, n: int, pos: int) -> int:
	if pos < 1 or pos > n:
		return 0
	return (x >> (n - pos)) & 1


## "00010" -> 2. Negeert alles behalve 0/1.
static func from_bits(s: String) -> int:
	var v := 0
	for c in s:
		if c == "0":
			v = v << 1
		elif c == "1":
			v = (v << 1) | 1
	return v
