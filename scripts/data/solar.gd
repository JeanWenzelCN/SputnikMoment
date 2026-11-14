extends RefCounted
## 太阳系天体表（缩比尺度，单位米）。地球在原点，其余按圆轨道绕地球运行。

const G := 9.80665

const BODIES := [
	{
		"id": "earth", "name": "地球",
		"radius": 600000.0, "g0": 9.80665, "atmo": 70000.0,
		"orbit_r": 0.0, "orbit_period": 0.0,
		"color": Color(0.32, 0.50, 0.60),
	},
	{
		"id": "moon", "name": "月球",
		"radius": 160000.0, "g0": 1.62, "atmo": 0.0,
		"orbit_r": 12000000.0, "orbit_period": 900.0,
		"color": Color(0.62, 0.64, 0.64),
	},
	{
		"id": "mars", "name": "火星",
		"radius": 340000.0, "g0": 3.71, "atmo": 40000.0,
		"orbit_r": 34000000.0, "orbit_period": 2400.0,
		"color": Color(0.62, 0.36, 0.26),
	},
	{
		"id": "venus", "name": "金星",
		"radius": 580000.0, "g0": 8.87, "atmo": 90000.0,
		"orbit_r": 22000000.0, "orbit_period": 1800.0,
		"color": Color(0.68, 0.60, 0.42),
	},
]


static func build() -> Array:
	var out: Array = []
	for b in BODIES:
		var body: Dictionary = b.duplicate()
		body["mu"] = float(b["g0"]) * float(b["radius"]) * float(b["radius"])
		body["angle"] = 0.0
		body["pos"] = Vector2.ZERO
		out.append(body)
	return out


static func update_positions(bodies: Array, t: float) -> void:
	for body in bodies:
		var period: float = float(body["orbit_period"])
		if period <= 0.0:
			body["angle"] = 0.0
			body["pos"] = Vector2.ZERO
		else:
			var ang: float = TAU * t / period
			body["angle"] = ang
			body["pos"] = Vector2(cos(ang), sin(ang)) * float(body["orbit_r"])


static func nearest(bodies: Array, p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := INF
	for body in bodies:
		var d: float = (p - Vector2(body["pos"])).length()
		if d < best_dist:
			best_dist = d
			best = body
	return best


## 主导天体：引力加速度最大的那个（Hill 球近似）。
static func dominant(bodies: Array, p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_force := -1.0
	for body in bodies:
		var d: Vector2 = p - Vector2(body["pos"])
		var dist: float = maxf(d.length(), float(body["radius"]) * 0.35)
		var f: float = float(body["mu"]) / (dist * dist)
		if f > best_force:
			best_force = f
			best = body
	return best
