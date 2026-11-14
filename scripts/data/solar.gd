extends RefCounted
## 日心太阳系：太阳在原点，行星绕太阳，月球绕地球。带 SOI 参考系切换。

const BODIES := [
	{
		"id": "sun", "name": "太阳", "parent": "",
		"radius": 2000000.0, "g0": 274.0, "soi": 0.0, "atmo": 0.0,
		"orbit_r": 0.0, "orbit_period": 0.0,
		"color": Color(1.0, 0.78, 0.35),
	},
	{
		"id": "earth", "name": "地球", "parent": "sun",
		"radius": 600000.0, "g0": 9.80665, "soi": 5000000.0, "atmo": 70000.0,
		"orbit_r": 8000000.0, "orbit_period": 300.0,
		"color": Color(0.34, 0.52, 0.62),
	},
	{
		"id": "moon", "name": "月球", "parent": "earth",
		"radius": 160000.0, "g0": 1.62, "soi": 600000.0, "atmo": 0.0,
		"orbit_r": 1600000.0, "orbit_period": 120.0,
		"color": Color(0.63, 0.64, 0.64),
	},
	{
		"id": "venus", "name": "金星", "parent": "sun",
		"radius": 580000.0, "g0": 8.87, "soi": 3500000.0, "atmo": 90000.0,
		"orbit_r": 4500000.0, "orbit_period": 220.0,
		"color": Color(0.70, 0.62, 0.44),
	},
	{
		"id": "mars", "name": "火星", "parent": "sun",
		"radius": 340000.0, "g0": 3.71, "soi": 3000000.0, "atmo": 40000.0,
		"orbit_r": 14000000.0, "orbit_period": 600.0,
		"color": Color(0.64, 0.38, 0.28),
	},
]


static func build() -> Array:
	var out: Array = []
	for b in BODIES:
		var body: Dictionary = b.duplicate()
		body["mu"] = float(b["g0"]) * float(b["radius"]) * float(b["radius"])
		body["pos"] = Vector2.ZERO
		body["vel"] = Vector2.ZERO
		body["angle"] = 0.0
		out.append(body)
	return out


static func update_positions(bodies: Array, t: float) -> void:
	for body in bodies:
		var parent_id := String(body["parent"])
		if parent_id.is_empty():
			body["pos"] = Vector2.ZERO
			body["vel"] = Vector2.ZERO
			body["angle"] = 0.0
			continue
		var parent: Dictionary = find_body(bodies, parent_id)
		var r: float = float(body["orbit_r"])
		var period: float = maxf(float(body["orbit_period"]), 0.001)
		var omega: float = TAU / period
		var ang: float = omega * t
		body["angle"] = ang
		body["pos"] = Vector2(parent["pos"]) + Vector2(cos(ang), sin(ang)) * r
		body["vel"] = Vector2(parent["vel"]) + Vector2(-sin(ang), cos(ang)) * (r * omega)


static func find_body(bodies: Array, id: String) -> Dictionary:
	for b in bodies:
		if String(b["id"]) == id:
			return b
	return {}


## 返回包含该世界坐标的最小 SOI 天体；都不在则返回太阳。
static func ref_body(bodies: Array, world_pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_soi := INF
	for b in bodies:
		var soi: float = float(b["soi"])
		if soi <= 0.0:
			continue
		if (world_pos - Vector2(b["pos"])).length() < soi and soi < best_soi:
			best_soi = soi
			best = b
	if best.is_empty():
		return find_body(bodies, "sun")
	return best