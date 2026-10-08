extends RefCounted


func run(t) -> void:
	t.section("A1 HashUtil")
	t.eq(HashUtil.prefix(0b010011, 6, 3), 2, "prefix(010011,6,3)")
	t.eq(HashUtil.bits(2, 5), "00010", "bits(2,5)")
	t.eq(HashUtil.bits(5, 0), "", "bits w=0")
	t.eq(HashUtil.bits(0, 3), "000", "bits(0,3)")
	t.eq(HashUtil.prefix(0b10110, 5, 0), 0, "prefix k=0")
	t.eq(HashUtil.prefix(0b10110, 5, 5), 0b10110, "prefix k=n")
	t.eq(HashUtil.prefix(0b10110, 5, 3), 0b101, "prefix 10110|3")
	t.eq(HashUtil.bit_at(0b10110, 5, 1), 1, "bit 1")
	t.eq(HashUtil.bit_at(0b10110, 5, 2), 0, "bit 2")
	t.eq(HashUtil.bit_at(0b10110, 5, 5), 0, "bit 5")
	t.eq(HashUtil.bit_at(0b10110, 5, 4), 1, "bit 4")
	t.eq(HashUtil.from_bits("00010"), 2, "from_bits")
	t.eq(HashUtil.from_bits(""), 0, "from_bits leeg")
	for x in 64:
		t.eq(HashUtil.from_bits(HashUtil.bits(x, 6)), x, "roundtrip %d" % x)
