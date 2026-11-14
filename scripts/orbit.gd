extends RefCounted
## 二维二体轨道要素。

const MU := 9.80665 * 600000.0 * 600000.0


static func elements(pos: Vector2, vel: Vector2, mu: float = MU) -> Dictionary:
	var r := pos.length()
	if r < 1.0:
		r = 1.0
	var v2 := vel.length_squared()
	var energy := v2 * 0.5 - mu / r
	var h := pos.x * vel.y - pos.y * vel.x
	var out := {
		"r": r,
		"speed": sqrt(v2),
		"energy": energy,
		"a": INF,
		"e": 0.0,
		"apo": INF,
		"peri": 0.0,
		"period": 0.0,
		"escape": energy >= 0.0,
		"peri_dir": Vector2.RIGHT,
	}
	var a := INF
	if absf(energy) > 1e-9:
		a = -mu / (2.0 * energy)
	out["a"] = a

	var e := sqrt(maxf(0.0, 1.0 + 2.0 * energy * h * h / (mu * mu)))
	out["e"] = e

	# 近地点方向：e_vec = ((v² - μ/r)·r - (r·v)·v) / μ
	var e_vec: Vector2 = ((v2 - mu / r) * pos - pos.dot(vel) * vel) / mu
	if e_vec.length() > 1e-6:
		out["peri_dir"] = e_vec.normalized()

	if is_finite(a) and a > 0.0:
		out["apo"] = a * (1.0 + e)
		out["peri"] = a * (1.0 - e)
		out["period"] = TAU * sqrt(a * a * a / mu)
	return out


## 轨道上的一点，ν 为真近点角（相对于近地点方向）。
static func point_at(el: Dictionary, nu: float) -> Vector2:
	var a: float = el["a"]
	var e: float = el["e"]
	if not is_finite(a) or a <= 0.0:
		return Vector2.ZERO
	var p := a * (1.0 - e * e)
	var r := p / (1.0 + e * cos(nu))
	var dir: Vector2 = el["peri_dir"]
	return dir.rotated(nu) * r


static func sample(el: Dictionary, count: int = 160) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if not is_finite(float(el["a"])) or float(el["a"]) <= 0.0:
		return pts
	for i in range(count + 1):
		pts.append(point_at(el, TAU * float(i) / float(count)))
	return pts
