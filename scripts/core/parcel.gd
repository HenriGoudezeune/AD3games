class_name Parcel extends RefCounted
## Een pakje = een record met hashwaarde hv (n bits).

var id: int
var hv: int
var key_label: String = ""  # "45" op dag 6 (sleutel naast de hashwaarde)
var is_clone: bool = false  # spelinfo: dit pakje is een "te veel" identiek exemplaar


static func make(id_: int, hv_: int, key_label_: String = "", is_clone_: bool = false) -> Parcel:
	var p := Parcel.new()
	p.id = id_
	p.hv = hv_
	p.key_label = key_label_
	p.is_clone = is_clone_
	return p


func to_dict() -> Dictionary:
	return {"id": id, "hv": hv, "key_label": key_label, "is_clone": is_clone}


static func from_dict(d: Dictionary) -> Parcel:
	return make(int(d.get("id", 0)), int(d.get("hv", 0)), str(d.get("key_label", "")), bool(d.get("is_clone", false)))
