extends RefCounted
## 真实比例太阳系 + 双精度轨道数学。所有位置单位米，速度 m/s，时间 s。
## 状态用 GDScript float（64 位）存储，绝不用 Vector2（32 位）。

const G := 6.67430e-11
const AU := 1.496e11

const BODIES := [
	{
		"id": "sun", "name": "太阳", "parent": "",
		"radius": 6.957e8, "mu": 1.32712440018e20, "soi": 1.0e15,
		"atmo": 0.0, "H": 0.0, "rho0": 0.0,
		"orbit_r": 0.0, "period": 0.0,
		"color": Color(1.0, 0.78, 0.35),
	},
	{
		"id": "earth", "name": "地球", "parent": "sun",
		"radius": 6.371e6, "mu": 3.986004418e14, "soi": 9.24e8,
		"atmo": 1.0e5, "H": 8500.0, "rho0": 1.225,
		"orbit_r": 1.496e11, "period": 3.15576e7,
		"color": Color(0.34, 0.52, 0.62),
	},
	{
		"id": "moon", "name": "月球", "parent": "earth",
		"radius": 1.7374e6, "mu": 4.9028e12, "soi": 6.6e7,
		"atmo": 0.0, "H": 0.0, "rho0": 0.0,
		"orbit_r": 3.844e8, "period": 2.3606e6,
		"color": Color(0.63, 0.64, 0.64),
	},
	{
		"id": "venus", "name": "金星", "parent": "sun",
		"radius": 6.0518e6, "mu": 3.24859e14, "soi": 6.1e8,
		"atmo": 2.5e5, "H": 15900.0, "rho0": 65.0,
		"orbit_r": 1.0821e11, "period": 1.9414e7,
		"color": Color(0.70, 0.62, 0.44),
	},
	{
		"id": "mars", "name": "火星", "parent": "sun",
		"radius": 3.3895e6, "mu": 4.282837e13, "soi": 5.7e8,
		"atmo": 1.2e5, "H": 11100.0, "rho0": 0.020,
		"orbit_r": 2.2792e11, "period": 5.9355e7,
		"color": Color(0.64, 0.38, 0.28),
	},
]


static func build() -> Array:
	var out: Array = []
	for b in BODIES:
		var body: Dictionary = b.duplicate()
		body["px"] = 0.0
		body["py"] = 0.0
		body["vx"] = 0.0
		body["vy"] = 0.0
		out.append(body)
	return out


static func find(bodies: Array, id: String) -> Dictionary:
	for b in bodies:
		if String(b["id"]) == id:
			return b
	return {}


## 解析位置传播（圆轨道，父天体已更新）。
static func update_positions(bodies: Array, t: float) -> void:
	for body in bodies:
		var parent_id := String(body["parent"])
		if parent_id.is_empty():
			body["px"] = 0.0
			body["py"] = 0.0
			body["vx"] = 0.0
			body["vy"] = 0.0
			continue
		var parent: Dictionary = find(bodies, parent_id)
		var r: float = float(body["orbit_r"])
		var period: float = maxf(float(body["period"]), 1.0)
		var w: float = TAU / period
		var a: float = w * t
		body["px"] = float(parent["px"]) + cos(a) * r
		body["py"] = float(parent["py"]) + sin(a) * r
		body["vx"] = float(parent["vx"]) - sin(a) * r * w
		body["vy"] = float(parent["vy"]) + cos(a) * r * w


## 最小包含 SOI 的天体。
static func ref_body(bodies: Array, x: float, y: float) -> Dictionary:
	var best: Dictionary = {}
	var best_soi := INF
	for b in bodies:
		var soi: float = float(b["soi"])
		if soi <= 0.0:
			continue
		var dx: float = x - float(b["px"])
		var dy: float = y - float(b["py"])
		var d: float = sqrt(dx * dx + dy * dy)
		if d < soi and soi < best_soi:
			best_soi = soi
			best = b
	if best.is_empty():
		return find(bodies, "sun")
	return best


# ── 轨道要素（相对参考天体）────────────────────────────────
static func elements(rx: float, ry: float, vx: float, vy: float, mu: float) -> Dictionary:
	var r: float = sqrt(rx * rx + ry * ry)
	if r < 1.0:
		r = 1.0
	var v2: float = vx * vx + vy * vy
	var energy: float = v2 * 0.5 - mu / r
	var h: float = rx * vy - ry * vx
	var a: float = INF
	if absf(energy) > 1e-12:
		a = -mu / (2.0 * energy)
	var e: float = sqrt(maxf(0.0, 1.0 + 2.0 * energy * h * h / (mu * mu)))
	var out := {
		"r": r, "speed": sqrt(v2), "a": a, "e": e,
		"apo": INF, "peri": 0.0, "period": 0.0,
		"escape": energy >= 0.0,
		"peri_x": 1.0, "peri_y": 0.0,
	}
	var ex: float = ((v2 - mu / r) * rx - (rx * vx + ry * vy) * vx) / mu
	var ey: float = ((v2 - mu / r) * ry - (rx * vx + ry * vy) * vy) / mu
	var el: float = sqrt(ex * ex + ey * ey)
	if el > 1e-12:
		out["peri_x"] = ex / el
		out["peri_y"] = ey / el
	if is_finite(a) and a > 0.0:
		out["apo"] = a * (1.0 + e)
		out["peri"] = a * (1.0 - e)
		out["period"] = TAU * sqrt(a * a * a / mu)
	return out


## 由要素求状态（on-rails 传播用）。
static func state_from_elements(el: Dictionary, mu: float) -> Array:
	var a: float = float(el["a"])
	var e: float = float(el["e"])
	if not is_finite(a) or a <= 0.0 or e >= 1.0:
		return [0.0, 0.0, 0.0, 0.0]
	var p: float = a * (1.0 - e * e)
	var nu: float = float(el.get("nu", 0.0))
	var r: float = p / (1.0 + e * cos(nu))
	var dirx: float = float(el["peri_x"])
	var diry: float = float(el["peri_y"])
	var cx: float = cos(nu)
	var sy: float = sin(nu)
	var rx: float = (dirx * cx - diry * sy) * r
	var ry: float = (dirx * sy + diry * cx) * r
	var vf: float = sqrt(mu / p)
	var vx: float = (-dirx * sy - diry * cx) * vf
	var vy: float = (-diry * sy + dirx * cx) * vf
	return [rx, ry, vx, vy]


## 轨道传播：给定要素与时间增量，返回新状态。
static func propagate(el: Dictionary, dt: float, mu: float) -> Array:
	var a: float = float(el["a"])
	var e: float = float(el["e"])
	if not is_finite(a) or a <= 0.0 or e >= 1.0:
		return [0.0, 0.0, 0.0, 0.0]
	var n: float = sqrt(mu / (a * a * a))
	var nu0: float = float(el.get("nu", 0.0))
	# 由真近点角求偏近点角
	var E0: float = 2.0 * atan2(sqrt(1.0 - e) * sin(nu0 * 0.5), sqrt(1.0 + e) * cos(nu0 * 0.5))
	var M0: float = E0 - e * sin(E0)
	var M: float = M0 + n * dt
	M = fposmod(M, TAU)
	var E: float = M
	for i in range(8):
		E = E - (E - e * sin(E) - M) / (1.0 - e * cos(E))
	var nu: float = 2.0 * atan2(sqrt(1.0 + e) * sin(E * 0.5), sqrt(1.0 - e) * cos(E * 0.5))
	var out: Dictionary = el.duplicate()
	out["nu"] = nu
	return state_from_elements(out, mu)


## 由状态求当前真近点角（用于保存要素）。
static func true_anomaly(el: Dictionary, rx: float, ry: float) -> float:
	var dirx: float = float(el["peri_x"])
	var diry: float = float(el["peri_y"])
	var along: float = rx * dirx + ry * diry
	var across: float = -rx * diry + ry * dirx
	return atan2(across, along)