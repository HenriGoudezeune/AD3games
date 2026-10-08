class_name Bucket extends RefCounted
## Een emmer (rek) met capaciteit g en lokale diepte ab.

var id: int
var ab: int
var parcels: Array[Parcel] = []


static func make(id_: int, ab_: int) -> Bucket:
	var b := Bucket.new()
	b.id = id_
	b.ab = ab_
	return b


func is_full(g: int) -> bool:
	return parcels.size() >= g


func count_hv(hv: int) -> int:
	var c := 0
	for p in parcels:
		if p.hv == hv:
			c += 1
	return c


func find(parcel_id: int) -> Parcel:
	for p in parcels:
		if p.id == parcel_id:
			return p
	return null


func has_hv(hv: int) -> bool:
	return count_hv(hv) > 0
