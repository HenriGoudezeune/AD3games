class_name HDLessons
extends Object
## Leerpad van Hash & Dash (design/LEARNING_PATH_hashdash.md, design/LEARNING.md): de delen in volgorde, per deel
## een Kijk- en een Samen-voorbeeld, de verteltekst per stap (uit het orakel), voorspelvragen en de Check-vragen
## voor het rapport (op een nieuw, willekeurig voorbeeld; antwoord altijd berekend met de core).
## Pure logica + data: geen nodes (ook bruikbaar in tests/suites/t_lessons.gd).

const SAVE_KEY := "learning"     # SaveData settings: {"luik": {"kijk": true, "samen": true, "check": true}, ...}
const AB := "a[font_size=17]b[/font_size]"

## Delen in volgorde (= volgorde van de dagen). "day" = de dag die de Zelf-fase is.
## kijk/samen: n, g, a, layout (Days.layout_from), keys, customers (hashwaarden), overflow.
## ask: voorspelvragen in de Kijk-fase: {on: actie van het orakel, nth: hoeveelste keer, q: soort}.
const PARTS := [
	{"id": "luik", "title": "Het juiste luik", "day": 1, "page": "p. 6–7",
		"rule": "Luik = (h(r))|a: de eerste a bits van de hashwaarde.",
		"kijk": {"g": 3, "a": 1, "layout": "0{} 1{}", "keys": "10110 00101 01110 11001",
			"ask": [{"on": "drop", "nth": 3, "q": "luik"}]},
		"samen": {"g": 3, "a": 2, "layout": "00{} 01{} 10{} 11{}", "keys": "11010 01001 10011 00110 11100"}},
	{"id": "splitsen", "title": "Splitsen", "day": 2, "page": "p. 7–8",
		"rule": "Vol rek met %s < a: zaag (splitsen) en verdeel op bit %s + 1." % [AB, AB],
		"kijk": {"g": 2, "a": 3, "layout": "0{00100,01111} 10{10010,10111} 110{11000} 111{11100}", "keys": "01010 10100",
			"ask": [{"on": "split", "nth": 2, "q": "zet"}, {"on": "assign", "nth": 3, "q": "kant"}]},
		"samen": {"g": 2, "a": 2, "layout": "0{00011,01100} 10{10001,10110} 11{11010}", "keys": "11000 01001 00110"}},
	{"id": "verdubbelen", "title": "Verdubbelen", "day": 2, "page": "p. 7 (Figuur 2–4)",
		"rule": "Vol rek met %s = a (één luik): eerst de hendel (verdubbelen), dan zagen." % AB,
		"kijk": {"g": 2, "a": 1, "layout": "0{00100,01111} 1{10010,11100}", "keys": "11111 00010",
			"ask": [{"on": "split", "nth": 1, "q": "zet"}, {"on": "split", "nth": 2, "q": "zet"}]},
		"samen": {"g": 2, "a": 1, "layout": "0{00101,01110} 1{10011,11001}", "keys": "00001 10111"}},
	{"id": "kost", "title": "Ritten tellen (L en S)", "day": 3, "page": "p. 9",
		"rule": "Pakje plaatsen: 1 L + 1 S. Met splitsen: 1 L + 2 S. Verdubbelen: 0 (geheugen).",
		"kijk": {"g": 2, "a": 2, "layout": "0{00100} 10{10010,10111} 11{11100}", "keys": "01000 10001 00011", "cost": true,
			"ask": [{"on": "drop", "nth": 3, "q": "kost"}]},
		"samen": {"g": 2, "a": 1, "layout": "0{00110} 1{10101,11011}", "keys": "01100 11110 00011", "cost": true,
			"ask_each": "kost"}},
	{"id": "opzoeken", "title": "Opzoeken (klanten)", "day": 4, "page": "p. 7",
		"rule": "Opzoeken = zelfde regel: luik (h(r))|a, dan dat ene rek lezen (1 L).",
		"kijk": {"g": 2, "a": 2, "layout": "0{00100,01111} 10{10010} 11{11100,11111}", "keys": "",
			"customers": "10010 01111 11100", "ask": [{"on": "serve", "nth": 3, "q": "zoek"}]},
		"samen": {"g": 2, "a": 3, "layout": "00{00011,00110} 01{01101} 100{10001} 101{10100,10110} 11{11010,11100}",
			"keys": "", "customers": "01101 10110 11100 00110"}},
	{"id": "opnieuw", "title": "Nog eens verdubbelen", "day": 5, "page": "p. 8 (Figuur 5)",
		"rule": "Blijft één kant leeg en het rek vol? Dan opnieuw: hendel of zaag, tot het past.",
		"kijk": {"g": 2, "a": 2, "layout": "0{00100,01111} 10{10010} 11{11100,11111}", "keys": "11110",
			"ask": [{"on": "double", "nth": 2, "q": "zet"}]},
		"samen": {"g": 2, "a": 1, "layout": "0{00100,00011} 1{10101}", "keys": "00001 11011"}},
	{"id": "faalt", "title": "Wanneer het faalt", "day": 7, "page": "p. 8–9 · Oefening 4",
		"rule": "Meer dan g identieke hashwaarden: geen bits meer, de methode faalt.",
		"kijk": {"g": 2, "a": 3, "layout": "0{00100,01001} 100{} 101{10110,10110} 11{11000}", "keys": "10110",
			"ask": [{"on": "double", "nth": 2, "q": "helpt"}]},
		"samen": {"g": 2, "a": 1, "layout": "0{} 1{}", "keys": "11010 00111 11010 10001 11010", "overflow": true}},
]


# ======================================================================
#  delen en voortgang
# ======================================================================

static func part(id: String) -> Dictionary:
	for p in PARTS:
		if p.id == id:
			return p
	return {}


static func index_of_part(id: String) -> int:
	for i in PARTS.size():
		if PARTS[i].id == id:
			return i
	return -1


static func parts_for_day(day: int) -> Array:
	var out := []
	for p in PARTS:
		if int(p.day) == day:
			out.append(p.id)
	return out


static func progress(id: String) -> Dictionary:
	var d = SaveData.get_setting(SAVE_KEY, {})
	if d is Dictionary and (d as Dictionary).get(id) is Dictionary:
		return d[id]
	return {}


static func mark(id: String, key: String, value := true) -> void:
	var d = SaveData.get_setting(SAVE_KEY, {})
	if not d is Dictionary:
		d = {}
	var e: Dictionary = d.get(id, {}) if d.get(id) is Dictionary else {}
	e[key] = value
	d[id] = e
	SaveData.set_setting(SAVE_KEY, d)


static func reset_progress() -> void:
	SaveData.set_setting(SAVE_KEY, {})


static func is_done(id: String, phase: String) -> bool:
	return bool(progress(id).get(phase, false))


## 0 = nog niets, 1 = demo bekeken, 2 = samen geoefend, 3 = begrepen (check juist).
static func level(id: String) -> int:
	var p := progress(id)
	if bool(p.get("check", false)) and bool(p.get("samen", false)):
		return 3
	if bool(p.get("samen", false)):
		return 2
	if bool(p.get("kijk", false)):
		return 1
	return 0


## Lessen die vóór dag `day` nog moeten (eerste keer verplicht): elk deel met dag <= day waarvan Samen nog niet
## gedaan is -> [{part, phase}] (kijk dan samen, in volgorde van het leerpad).
static func pending_for_day(day: int) -> Array:
	var out := []
	if day <= 0:
		return out
	for p in PARTS:
		if int(p.day) > day or is_done(p.id, "samen"):
			continue
		if not is_done(p.id, "kijk"):
			out.append({"part": p.id, "phase": "kijk"})
		out.append({"part": p.id, "phase": "samen"})
	return out


# ======================================================================
#  DaySpec voor een les
# ======================================================================

static func spec(id: String, phase: String) -> DaySpec:
	var p := part(id)
	if p.is_empty():
		return null
	var c: Dictionary = p[phase]
	var s := DaySpec.new()
	s.id = "les_%s_%s" % [id, phase]
	s.day_number = int(p.day)
	s.title = "Deel %d · %s" % [index_of_part(id) + 1, p.title]
	s.n = int(c.get("n", 5))
	s.g = int(c.g)
	s.a0 = int(c.a)
	s.start_layout = Days.layout_from(str(c.layout))
	var keys: Array[Dictionary] = []
	for k in str(c.get("keys", "")).split(" ", false):
		keys.append({"hv": k, "label": "", "clone": false})
	s.keys = keys
	s.mode = DaySpec.Mode.CALM
	s.bit_hint = DaySpec.BitHint.FULL if phase == "kijk" else DaySpec.BitHint.COLORS
	s.spawn_interval = 1.0
	s.belt_time = 3.5
	s.overflow_bin = bool(c.get("overflow", false))
	var t := 0.4
	for h in str(c.get("customers", "")).split(" ", false):
		s.customers.append({"t": t, "hv": h, "patience": 9999.0})
		t += 0.6
	s.intro = ("Kijk: " if phase == "kijk" else "Samen: ") + str(p.title)
	s.icon = "book"
	return s


# ======================================================================
#  verteltekst (Kijk) en uitleg (Samen) — altijd afgeleid van het model, dus altijd juist
# ======================================================================

static func code(s: String) -> String:
	return "[code]%s[/code]" % s


static func bitstr(m: ExtHashModel, hv: int) -> String:
	return HashUtil.bits(hv, m.n)


## Bits met de eerste k bits vet/oranje (het luik).
static func code_prefix(s: String, k: int) -> String:
	if k <= 0:
		return code(s)
	return "[code][color=#FFB020][b]%s[/b][/color]%s[/code]" % [s.substr(0, k), s.substr(k)]


## Bits met bit nummer pos (1-gebaseerd) gemarkeerd.
static func code_bit(s: String, pos: int) -> String:
	return "[code]%s[color=#FFB020][b]%s[/b][/color]%s[/code]" % [s.substr(0, pos - 1), s.substr(pos - 1, 1), s.substr(pos)]


static func rack(m: ExtHashModel, bid: int) -> String:
	return "rek " + code(m.label_of(bid))


static func rack_cap(m: ExtHashModel, bid: int) -> String:
	return "Rek " + code(m.label_of(bid))


static func _bits_word(k: int) -> String:
	return "bit" if k == 1 else "bits"


## "de eerste a = 2 bits zijn 10" of (a = 1) "het eerste bit (a = 1) is 1".
static func first_bits(a: int, pre: String) -> String:
	if a == 1:
		return "het eerste bit (a = 1) is %s" % code(pre)
	return "de eerste a = %d bits zijn %s" % [a, code(pre)]


## Verteltekst voor zet `mv` (correct_move-formaat, plus "serve"). ctx: {parcel: Parcel, hv: int, cost: bool}.
## -> {what, why} (BBCode, max. 2 zinnen elk).
static func narrate(m: ExtHashModel, mv: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var cost: bool = bool(ctx.get("cost", false))
	match str(mv.get("action", "")):
		"drop":
			var p: Parcel = ctx.get("parcel")
			var s := bitstr(m, p.hv)
			var pre := s.substr(0, m.a)
			var idx := int(mv.dir_index)
			var bid := m.dir[idx]
			var b := m.buckets[bid]
			var what := "Pakje %s: %s, dus luik %s." % [code_prefix(s, m.a), first_bits(m.a, pre), code(pre)]
			var why := ""
			if b.is_full(m.g):
				why = "Maar %s is vol (g = %d): het pakje blijft in de buis steken." % [rack(m, bid), m.g]
				if cost:
					why += " Kost: 1 L (het volle rek lezen)."
			else:
				why = "Luik %s wijst naar %s; daar is nog plaats (%d/%d)." % [code(pre), rack(m, bid), b.parcels.size(), m.g]
				if m.span(bid) > 1:
					why = "Luik %s wijst naar %s (%s = %d, dus %d luiken delen die buis); er is plaats." % [code(pre), rack(m, bid), AB, b.ab, m.span(bid)]
				if cost:
					why += " Kost: 1 L (rek lezen) + 1 S (rek schrijven)."
			return {"what": what, "why": why}
		"double":
			var bid := _blocked_bucket(m)
			var b := m.buckets[bid]
			var what := "%s is vol en %s = a = %d: er wijst maar één luik naar. Dus: de hendel (verdubbelen)." % [rack_cap(m, bid), AB, m.a]
			var why := "a wordt %d en elk luik wordt er twee die naar hetzelfde rek wijzen. Dat gebeurt in het geheugen: 0 ritten." % (m.a + 1)
			if b.ab < m.a:
				what = "%s is vol. Dus: de hendel (verdubbelen)." % rack_cap(m, bid)
			if not m.blocked.is_empty() and m.splits > 0 and _just_split(m, bid):
				what = "Pech: %s is nog altijd vol (alle pakjes gingen naar dezelfde kant) en %s = a = %d. Dus opnieuw de hendel." % [rack(m, bid), AB, m.a]
			return {"what": what, "why": why}
		"split":
			var bid := int(mv.bucket_id)
			var b := m.buckets[bid]
			var what := "%s is vol, maar %s = %d < a = %d: er wijzen %d luiken naar. Dus: de zaag (splitsen)." % [rack_cap(m, bid), AB, b.ab, m.a, m.span(bid)]
			var why := "Er komt een nieuw rek bij; de pakjes worden verdeeld op bit %s + 1 = %d." % [AB, b.ab + 1]
			if cost:
				why += " Straks: S + 2 (oud en nieuw rek wegschrijven), geen extra L."
			return {"what": what, "why": why}
		"assign":
			var p: Parcel = _pending(m, int(mv.parcel_id))
			var pos := int(m.splitting.bit_pos)
			var s := bitstr(m, p.hv)
			var side := int(mv.side)
			var lab := m.label_of(int(m.splitting.new_bucket_id) if side == 1 else int(m.splitting.bucket_id))
			var what := "%s: bit %d is %s, dus %s (rek %s)." % [code_bit(s, pos), pos, code(s[pos - 1]), "rechts" if side == 1 else "links", code(lab)]
			var why := "Bit %s + 1 = %d beslist: 0 blijft in het oude rek, 1 gaat naar het nieuwe." % [AB, pos]
			return {"what": what, "why": why}
		"serve":
			var hv := int(ctx.get("hv", 0))
			var s := bitstr(m, hv)
			var pre := s.substr(0, m.a)
			var bid := m.dir[m.index_of(hv)]
			var what := "Klant zoekt %s: %s, dus luik %s." % [code_prefix(s, m.a), first_bits(m.a, pre), code(pre)]
			var why := "Opzoeken gaat met dezelfde regel als toevoegen. Luik %s wijst naar %s: dat ene rek lezen = 1 L." % [code(pre), rack(m, bid)]
			if m.span(bid) > 1:
				why = "Zelfde regel als toevoegen. Luik %s wijst naar %s (%d luiken delen die buis): dat rek lezen = 1 L." % [code(pre), rack(m, bid), m.span(bid)]
			return {"what": what, "why": why}
		"dump":
			var hv := int(ctx.get("hv", 0))
			var bid := m.dir[m.index_of(hv)]
			var what := "Weer %s, en in %s liggen al g = %d pakjes met precies die waarde. Dus: de overloopbak." % [code(bitstr(m, hv)), rack(m, bid), m.g]
			var why := "Identieke hashwaarden hebben altijd dezelfde bits: geen enkele splitsing haalt ze uit elkaar."
			return {"what": what, "why": why}
		"fail":
			var bid := _blocked_bucket(m)
			var what := "%s is vol en a = n = %d: er zijn geen bits meer om te verdubbelen." % [rack_cap(m, bid), m.n]
			var why := "Meer dan g identieke hashwaarden: de methode faalt (notas p. 8). De hendel slaat op de eindaanslag."
			return {"what": what, "why": why}
		"retry":
			return {"what": "Het vastzittende pakje probeert opnieuw.", "why": ""}
	return {"what": "", "why": ""}


## Is rek bid net ontstaan of gesplitst (het vastzittende pakje zat al vóór de laatste splitsing vast)?
static func _just_split(m: ExtHashModel, bid: int) -> bool:
	for i in range(m.log.entries.size() - 1, -1, -1):
		var e: Dictionary = m.log.entries[i]
		if e.type == "SPLIT_END":
			return int(e.data.get("bucket_id", -1)) == bid or int(e.data.get("new_bucket_id", -1)) == bid
		if e.type in ["DROP", "DOUBLE"]:
			return false
	return false


## Opties in willekeurige volgorde (correct-indices mee omgezet).
static func shuffled(q: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var opts: Array = q.get("options", [])
	var idx := range(opts.size())
	for i in range(idx.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = idx[i]
		idx[i] = idx[j]
		idx[j] = t
	var out := q.duplicate()
	out.options = idx.map(func(k): return opts[k])
	out.correct = []
	for k in idx.size():
		if (q.correct as Array).has(idx[k]):
			out.correct.append(k)
	return out


static func _blocked_bucket(m: ExtHashModel) -> int:
	if m.blocked.is_empty():
		return 0
	return m.dir[int(m.blocked[0].via_index)]


static func _pending(m: ExtHashModel, pid: int) -> Parcel:
	if m.splitting.is_empty():
		return null
	for q in m.splitting.pending:
		if (q as Parcel).id == pid:
			return q
	return null


## Korte regel (tip) voor Samen vóór een stap: zegt de regel, niet het antwoord.
static func tip(m: ExtHashModel, mv: Dictionary, ctx: Dictionary = {}) -> String:
	match str(mv.get("action", "")):
		"drop":
			return "Lees de eerste a = %d %s van het pakje: dat is het luik. Sleep het erheen of typ de bits." % [m.a, _bits_word(m.a)]
		"double", "split", "fail":
			var bid := _blocked_bucket(m)
			return "%s is vol. Kijk naar %s op het rek: %s = a = %d? Hendel (D). %s < a? Zaag (S)." % [rack_cap(m, bid), AB, AB, m.a, AB]
		"assign":
			return "Kijk naar bit %s + 1 = %d van het pakje: 0 = links, 1 = rechts (of druk 0 / 1)." % [AB, int(m.splitting.get("bit_pos", 1))]
		"serve":
			return "Klik het luik van de eerste a = %d %s van wat de klant zoekt (of Tab + bits)." % [m.a, _bits_word(m.a)]
		"dump":
			return "Kijk naar de hashwaarden in het volle rek. Helpt splitsen nog? Zo niet: sleep naar de bak (K)."
	return ""


## Uitleg bij een foute zet in Samen. kind: "drop" | "double" | "split" | "assign" | "serve" | "dump".
static func explain_wrong(m: ExtHashModel, kind: String, data: Dictionary, mv: Dictionary) -> String:
	var act := str(mv.get("action", ""))
	match kind:
		"drop":
			if act in ["double", "split", "fail", "dump", "assign", "finish", "retry"]:
				return "Er zit eerst nog iets vast (of de sorteertafel is open). Los dat eerst op."
			var p: Parcel = data.get("parcel")
			if p == null:
				return "Dat pakje kan nu niet."
			if act == "dump" or (m.allow_dump and m.is_clone_overflow(p.hv)):
				return "Dit pakje past nooit meer: er liggen al g identieke. Sleep het naar de overloopbak."
			var s := bitstr(m, p.hv)
			var pre := s.substr(0, m.a)
			var got := HashUtil.bits(int(data.idx), m.a)
			return "Niet luik %s. Bij %s: %s, dus luik %s." % [code(got), code_prefix(s, m.a), first_bits(m.a, pre), code(pre)]
		"double":
			if act == "split":
				var b := m.buckets[int(mv.bucket_id)]
				return "Niet nodig: %s = %d < a = %d, er wijzen al %d luiken naar dit rek. Gebruik de zaag." % [AB, b.ab, m.a, m.span(int(mv.bucket_id))]
			if act == "drop" or act == "none":
				return "Er zit niets vast: verdubbelen is nu niet nodig."
			if act == "dump":
				return "Verdubbelen helpt hier niet: identieke pakjes blijven altijd samen. Sleep het naar de bak."
			return "Eerst de sorteertafel afwerken."
		"split":
			if act == "double":
				return "Dit rek heeft %s = a = %d: er wijst maar één luik naar. Eerst de hendel (verdubbelen)." % [AB, m.a]
			if act == "split":
				return "Niet dit rek: %s zit vast. Zaag dat rek." % rack(m, int(mv.bucket_id))
			if act == "dump":
				return "Zagen helpt hier niet: identieke pakjes blijven altijd samen. Sleep het naar de bak."
			return "Er zit niets vast: zagen is nu niet nodig."
		"assign":
			var p: Parcel = data.get("parcel")
			var pos := int(m.splitting.get("bit_pos", 1))
			var s := bitstr(m, p.hv)
			var bit := s[pos - 1]
			return "Kijk naar bit %d van %s: dat is %s, dus %s." % [pos, code_bit(s, pos), code(bit), "rechts (nieuw rek)" if bit == "1" else "links (oud rek)"]
		"serve":
			var hv := int(data.get("hv", 0))
			var s := bitstr(m, hv)
			var pre := s.substr(0, m.a)
			var got := HashUtil.bits(int(data.idx), m.a)
			return "Luik %s wijst naar een ander rek. De klant zoekt %s: %s." % [code(got), code_prefix(s, m.a), first_bits(m.a, pre)]
		"dump":
			return "Dit pakje kan nog gewoon in de tabel (eventueel na verdubbelen/zagen). De bak is enkel voor een (g+1)-de identiek pakje."
	return "Dat klopt niet."


# ======================================================================
#  voorspelvragen (Check in de wereld, vóór de game het toont)
# ======================================================================

## -> {q, options: [String], correct: [int], right, wrong} of {} als de vraag hier niet past.
static func predict(m: ExtHashModel, kind: String, mv: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	match kind:
		"luik", "zoek":
			var hv: int = (ctx.get("parcel") as Parcel).hv if ctx.get("parcel") != null else int(ctx.get("hv", 0))
			var s := bitstr(m, hv)
			var ci := m.index_of(hv)
			var opts := []
			var corr := []
			var order := range(m.dir.size())
			# correct luik + andere luiken naar andere rekken (max. 4), in pointervolgorde
			var pick := [ci]
			for i in order:
				if pick.size() >= 4:
					break
				if i == ci or m.dir[i] == m.dir[ci]:
					continue
				var dup := false
				for j in pick:
					if m.dir[j] == m.dir[i]:
						dup = true
				if not dup:
					pick.append(i)
			pick.sort()
			for i in pick:
				opts.append("luik " + HashUtil.bits(i, m.a))
				if m.dir[i] == m.dir[ci]:
					corr.append(opts.size() - 1)
			var pre := s.substr(0, m.a)
			var who := "het pakje" if kind == "luik" else "de klant"
			return {"q": "Voorspel: door welk luik moet %s %s?" % [who, code(s)], "options": opts, "correct": corr,
				"right": "Juist: %s." % first_bits(m.a, pre),
				"wrong": "Niet helemaal: kijk enkel naar de eerste a = %d %s van %s: %s." % [m.a, _bits_word(m.a), code(s), code(pre)]}
		"zet":
			var bid := _blocked_bucket(m)
			var b := m.buckets[bid]
			var dbl := str(mv.action) == "double"
			return {"q": "Voorspel: %s is vol (%s = %d, a = %d). Wat moet er nu gebeuren?" % [rack(m, bid), AB, b.ab, m.a],
				"options": ["Hendel: verdubbelen", "Zaag: splitsen"], "correct": [0 if dbl else 1],
				"right": "Juist!", "wrong": ("Nee: %s = a, er wijst maar één luik naar. Eerst verdubbelen." % AB) if dbl else ("Nee: %s < a, er wijzen al %d luiken naar. Verdubbelen is niet nodig." % [AB, m.span(bid)])}
		"kant":
			var p: Parcel = _pending(m, int(mv.parcel_id))
			var pos := int(m.splitting.bit_pos)
			var s := bitstr(m, p.hv)
			var side := int(mv.side)
			return {"q": "Voorspel: naar welke kant gaat %s?" % code(s), "options": ["Links (oud rek %s)" % m.label_of(int(m.splitting.bucket_id)), "Rechts (nieuw rek %s)" % m.label_of(int(m.splitting.new_bucket_id))],
				"correct": [side], "right": "Juist: bit %d is %s." % [pos, code(s[pos - 1])],
				"wrong": "Nee: kijk naar bit %s + 1 = %d van %s: dat is %s." % [AB, pos, code_bit(s, pos), code(s[pos - 1])]}
		"kost":
			var p: Parcel = ctx.get("parcel")
			var r := sim_insert(m, p.hv)
			var right := cost_label(int(r.reads), int(r.writes))
			var opts := cost_options(right)
			var corr := [opts.find(right)]
			return {"q": "Voorspel: hoeveel ritten kost het om %s toe te voegen?" % code(bitstr(m, p.hv)), "options": opts, "correct": corr,
				"right": "Juist: %s." % right, "wrong": "Nee: %s. %s" % [right, cost_reason(r)]}
		"helpt":
			return {"q": "Voorspel: het rek zit weer vol met dezelfde waarde. Helpt nog een keer verdubbelen en zagen?",
				"options": ["Ja: dan komen ze uit elkaar", "Nee: ze hebben dezelfde bits"], "correct": [1],
				"right": "Juist: identieke bits blijven altijd samen. Kijk wat het algoritme toch doet.",
				"wrong": "Nee: identieke hashwaarden hebben dezelfde bits, dus elke splitsing stuurt ze naar dezelfde kant."}
	return {}


static func cost_label(r: int, w: int) -> String:
	return "%d L + %d S" % [r, w]


static func cost_options(right: String) -> Array:
	var pool := ["1 L + 1 S", "1 L + 2 S", "1 L + 3 S", "2 L + 2 S", "0 L + 1 S"]
	var out := [right]
	for c in pool:
		if out.size() >= 4:
			break
		if c != right:
			out.append(c)
	out.sort()
	return out


static func cost_reason(r: Dictionary) -> String:
	if int(r.splits) == 0:
		return "Eén rek lezen en schrijven."
	var t := "1 L voor het volle rek; elke splitsing schrijft een rek weg, en het pakje zelf nog 1 S."
	if int(r.doubles) > 0:
		t += " Verdubbelen kost niets."
	return t


## Voegt hv toe aan een kopie van m met het orakel. -> {result, reads, writes, doubles, splits, model}
static func sim_insert(m: ExtHashModel, hv: int) -> Dictionary:
	var c := ExtHashModel.new()
	c.setup(m.n, m.g, 1)
	c.restore(m.snapshot())
	var r0 := c.reads
	var w0 := c.writes
	var d0 := c.doubles
	var s0 := c.splits
	var res := c.auto_insert(c.new_parcel(hv))
	return {"result": res, "reads": c.reads - r0, "writes": c.writes - w0, "doubles": c.doubles - d0, "splits": c.splits - s0, "model": c}


# ======================================================================
#  Check-vragen voor het rapport (nieuw voorbeeld, willekeurig, antwoord via de core)
# ======================================================================

## Vragen voor het rapport van dag `day`: 1–2 stuks over de delen van die dag (dag 6: examenmix).
static func report_parts(day: int) -> Array:
	var ps := parts_for_day(day)
	if day == 6:
		return ["verdubbelen", "kost"]
	if ps.size() == 1:
		ps = [ps[0], ps[0]] if ps[0] in ["luik", "splitsen"] else ps
	return ps.slice(0, 2)


## Een Check-vraag over deel `id` op een nieuw voorbeeld.
## -> {part, q, options, correct: [int], explain, fig: {snapshot, title}}
static func check_question(id: String, rng: RandomNumberGenerator) -> Dictionary:
	for attempt in 400:
		var q := _try_question(id, rng)
		if not q.is_empty():
			q["part"] = id
			return q
	return {}


static func _random_model(rng: RandomNumberGenerator, inserts: int, g := 2) -> ExtHashModel:
	var m := ExtHashModel.new()
	m.setup(5, g, 1)
	var used := {}
	for i in inserts:
		var hv := rng.randi_range(0, 31)
		if used.has(hv):
			continue
		used[hv] = true
		if m.auto_insert(m.new_parcel(hv)) != "ok":
			return null
	return m


static func _fresh_hv(m: ExtHashModel, rng: RandomNumberGenerator) -> int:
	for k in 64:
		var hv := rng.randi_range(0, 31)
		var dup := false
		for p in m.all_parcels():
			if p.hv == hv:
				dup = true
		if not dup:
			return hv
	return -1


static func _fig(m: ExtHashModel, title: String) -> Dictionary:
	return {"snapshot": m.snapshot(), "title": title}


static func _try_question(id: String, rng: RandomNumberGenerator) -> Dictionary:
	match id:
		"luik":
			var m := _random_model(rng, rng.randi_range(4, 7))
			if m == null or m.a < 2 or m.a > 3:
				return {}
			var hv := _fresh_hv(m, rng)
			if hv < 0:
				return {}
			var pq := predict(m, "luik", {"action": "drop"}, {"hv": hv})
			if (pq.options as Array).size() < 3:
				return {}
			var s := bitstr(m, hv)
			return {"hv": hv, "q": "Door welk luik gaat een nieuw pakje %s?" % code(s), "options": pq.options, "correct": pq.correct,
				"explain": "(h(r))|a = de eerste a = %d %s van %s = %s." % [m.a, _bits_word(m.a), code(s), code(s.substr(0, m.a))],
				"fig": _fig(m, "a = %d, g = 2" % m.a)}
		"splitsen", "verdubbelen":
			var m := _random_model(rng, rng.randi_range(4, 8))
			if m == null:
				return {}
			var hv := _fresh_hv(m, rng)
			if hv < 0:
				return {}
			var steps := m.simulate_insert(hv)
			var first := str(steps[0].act)
			var want := "split" if id == "splitsen" else "double"
			if steps.size() != (2 if want == "split" else 3) or str(steps[-1].act) != "place":
				return {}
			if first != want:
				return {}
			var s := bitstr(m, hv)
			var bid := int(steps[0].bucket_id)
			var b := m.buckets[bid]
			if id == "splitsen" and rng.randf() < 0.5:
				# variant: verdelen op bit ab + 1
				var others: Array = b.parcels.map(func(q): return q.hv)
				var y: int = others[rng.randi_range(0, others.size() - 1)]
				var ys := bitstr(m, y)
				var lab := m.label_of(bid)
				var bit := HashUtil.bit_at(y, m.n, b.ab + 1)
				return {"q": "Je voegt %s toe en zaagt %s (%s = %d). Naar welk rek gaat %s?" % [code(s), rack(m, bid), AB, b.ab, code(ys)],
					"options": ["rek " + lab + "0", "rek " + lab + "1"], "correct": [bit],
					"explain": "Verdelen op bit %s + 1 = %d: van %s is dat %s." % [AB, b.ab + 1, code_bit(ys, b.ab + 1), code(str(bit))],
					"fig": _fig(m, "a = %d, g = 2" % m.a)}
			var opts := ["Gewoon plaatsen", "Zaag: splitsen", "Hendel: eerst verdubbelen"]
			var corr := [1 if want == "split" else 2]
			var ex := ("Luik %s wijst naar %s: vol, en %s = %d < a = %d (%d luiken). Dus meteen splitsen." % [code(s.substr(0, m.a)), rack(m, bid), AB, b.ab, m.a, m.span(bid)]) if want == "split" \
				else ("Luik %s wijst naar %s: vol, en %s = a = %d (één luik). Dus eerst verdubbelen, dan splitsen." % [code(s.substr(0, m.a)), rack(m, bid), AB, m.a])
			return {"hv": hv, "q": "Je voegt %s toe. Wat moet er eerst gebeuren?" % code(s), "options": opts, "correct": corr, "explain": ex,
				"fig": _fig(m, "a = %d, g = 2" % m.a)}
		"kost":
			var m := _random_model(rng, rng.randi_range(3, 7))
			if m == null:
				return {}
			var hv := _fresh_hv(m, rng)
			if hv < 0:
				return {}
			var r := sim_insert(m, hv)
			if str(r.result) != "ok" or int(r.splits) > 1 or (int(r.splits) == 0 and rng.randf() < 0.6):
				return {}
			var right := cost_label(int(r.reads), int(r.writes))
			var opts := cost_options(right)
			return {"hv": hv, "q": "Hoeveel lees- (L) en schrijfoperaties (S) kost het toevoegen van %s?" % code(bitstr(m, hv)), "options": opts,
				"correct": [opts.find(right)], "explain": "%s. %s" % [right, cost_reason(r)], "fig": _fig(m, "a = %d, g = 2" % m.a)}
		"opzoeken":
			var m := _random_model(rng, rng.randi_range(4, 8))
			if m == null or m.a < 2:
				return {}
			var all := m.all_parcels()
			var y: int = all[rng.randi_range(0, all.size() - 1)].hv
			var s := bitstr(m, y)
			var ci := m.index_of(y)
			var other := -1
			for i in m.dir.size():
				if m.dir[i] != m.dir[ci]:
					other = i
					break
			if other < 0:
				return {}
			var pre := s.substr(0, m.a)
			var ot := HashUtil.bits(other, m.a)
			var opts := ["luik %s, 1 L" % pre, "luik %s, 0 L" % pre, "luik %s, 2 L" % pre, "luik %s, 1 L" % ot]
			return {"q": "Een klant zoekt %s. Door welk luik, en hoeveel leesoperaties kost dat?" % code(s), "options": opts, "correct": [0],
				"explain": "Luik (h(r))|a = %s; de pointerarray zit in het geheugen, dus enkel het rek lezen: 1 L." % code(pre),
				"fig": _fig(m, "a = %d, g = 2" % m.a)}
		"opnieuw":
			var m := _random_model(rng, rng.randi_range(3, 6))
			if m == null:
				return {}
			var hv := _fresh_hv(m, rng)
			if hv < 0:
				return {}
			var r := sim_insert(m, hv)
			if str(r.result) != "ok" or int(r.splits) < 2 or int(r.doubles) > 3:
				return {}
			var opts := ["0 keer", "1 keer", "2 keer", "3 keer"]
			return {"hv": hv, "q": "Hoe vaak moet de muur verdubbelen om %s toe te voegen?" % code(bitstr(m, hv)), "options": opts,
				"correct": [int(r.doubles)], "explain": "%d keer: na een splitsing kan één kant leeg blijven en het rek nog vol; dan opnieuw (%d keer zagen in totaal)." % [int(r.doubles), int(r.splits)],
				"fig": _fig(m, "a = %d, g = 2" % m.a)}
		"faalt":
			var m := ExtHashModel.new()
			m.setup(5, 2, 1)
			var y := rng.randi_range(0, 31)
			var variant := rng.randi_range(0, 1)
			var y2 := y if variant == 0 else (y ^ 1)
			for h in [y, y2]:
				m.auto_insert(m.new_parcel(h))
			var other := _fresh_hv(m, rng)
			if other < 0 or other == y or other == y2:
				return {}
			m.auto_insert(m.new_parcel(other))
			var r := sim_insert(m, y)
			var ok := str(r.result) == "ok"
			var ys := bitstr(m, y)
			var opts := ["Ja, na genoeg keer verdubbelen en zagen", "Nee, nooit: de methode faalt"]
			var ex := ("Het lukt pas bij a = %d: %s en %s verschillen enkel in het laatste bit." % [int(r.model.a), code(ys), code(bitstr(m, y2))]) if ok \
				else ("Drie keer %s met g = 2: welke bits je ook bekijkt, ze blijven samen. Na a = n = 5 zijn er geen bits meer." % code(ys))
			return {"hv": y, "q": "g = 2. Je voegt nog een %s toe. Lukt dat ooit?" % code(ys), "options": opts, "correct": [0 if ok else 1],
				"explain": ex, "fig": _fig(m, "a = %d, g = 2" % m.a)}
	return {}
