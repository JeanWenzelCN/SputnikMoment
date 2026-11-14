extends Node2D
## 飞行中的火箭实体：多级零件栈、燃料、推力、尾焰。

const Parts := preload("res://scripts/data/parts.gd")

var items: Array = []
var throttle := 0.0

var _t := 0.0


func setup(source) -> void:
	items.clear()
	for it in source.items:
		items.append({"id": String(it["id"]), "fuel": float(it["fuel"])})


func is_empty() -> bool:
	return items.is_empty()


func ranges() -> Array:
	var out: Array = []
	var start := 0
	for i in range(items.size()):
		if String(items[i]["id"]) == "sep":
			if i > start:
				out.append([start, i - 1])
			start = i + 1
	if start < items.size():
		out.append([start, items.size() - 1])
	if out.is_empty() and items.size() > 0:
		out.append([0, items.size() - 1])
	return out


func current_range() -> Array:
	var r := ranges()
	if r.is_empty():
		return []
	return r[0]


func stage_count() -> int:
	return maxi(1, ranges().size())


func mass() -> float:
	var m := 0.0
	for item in items:
		m += float(Parts.get_def(String(item["id"]))["dry"]) + float(item["fuel"])
	return maxf(m, 1.0)


func current_thrust() -> float:
	var r := current_range()
	if r.is_empty():
		return 0.0
	var t := 0.0
	for i in range(int(r[0]), int(r[1]) + 1):
		t += float(Parts.get_def(String(items[i]["id"]))["thrust"])
	return t


func current_ve() -> float:
	var r := current_range()
	if r.is_empty():
		return 0.0
	for i in range(int(r[0]), int(r[1]) + 1):
		var def: Dictionary = Parts.get_def(String(items[i]["id"]))
		if float(def["isp"]) > 0.0:
			return float(def["isp"]) * 9.80665
	return 0.0


func current_fuel() -> float:
	var r := current_range()
	if r.is_empty():
		return 0.0
	var f := 0.0
	for i in range(int(r[0]), int(r[1]) + 1):
		f += float(items[i]["fuel"])
	return f


func current_fuel_max() -> float:
	var r := current_range()
	if r.is_empty():
		return 0.0
	var f := 0.0
	for i in range(int(r[0]), int(r[1]) + 1):
		f += float(Parts.get_def(String(items[i]["id"]))["fuel"])
	return maxf(f, 1.0)


func burn(dt: float) -> void:
	var ve := current_ve()
	var thrust := current_thrust()
	if ve <= 0.0 or thrust <= 0.0:
		return
	if Game.is_cheat("infinite_fuel"):
		return
	var need := thrust / ve * dt * throttle
	var r := current_range()
	for i in range(int(r[0]), int(r[1]) + 1):
		if need <= 0.0:
			break
		var have := float(items[i]["fuel"])
		if have <= 0.0:
			continue
		var take: float = minf(have, need)
		items[i]["fuel"] = have - take
		need -= take


## 抛弃当前级，返回被抛弃零件的 id 列表。
func separate() -> Array:
	var r := current_range()
	if r.is_empty():
		return []
	var removed: Array = []
	for i in range(int(r[0]), int(r[1]) + 1):
		removed.append(String(items[i]["id"]))
	var cut: int = int(r[1])
	if cut + 1 < items.size() and String(items[cut + 1]["id"]) == "sep":
		cut += 1
	if cut + 1 >= items.size():
		return []
	items = items.slice(cut + 1)
	return removed


func total_height() -> float:
	var h := 0.0
	for item in items:
		h += float(Parts.get_def(String(item["id"]))["h"])
	return h


func ref_area() -> float:
	var w := 1.0
	for item in items:
		w = maxf(w, float(Parts.get_def(String(item["id"]))["w"]))
	return w * 2.4


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var cursor := 0.0
	for item in items:
		var id := String(item["id"])
		var def: Dictionary = Parts.get_def(id)
		var w := float(def["w"])
		var h := float(def["h"])
		var rect := Rect2(-w * 0.5, -(cursor + h), w, h)
		var tex := Parts.texture(id)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		else:
			draw_rect(rect, Color(0.72, 0.74, 0.72), true)

		if String(def["kind"]) == "engine" and throttle > 0.02:
			_draw_flame(-cursor, w, h)

		cursor += h


func _draw_flame(base: float, w: float, h: float) -> void:
	var flick: float = 0.85 + 0.15 * sin(_t * 43.0) + 0.05 * sin(_t * 27.0)
	var length: float = h * (2.0 + throttle * 3.6) * flick
	var half: float = w * 0.33

	# 外围辉光
	for i in range(3):
		var rad: float = w * (0.45 + 0.30 * float(i))
		draw_circle(Vector2(0.0, base + h * 0.22), rad, Color(1.0, 0.52, 0.16, 0.055))

	# 外焰
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half * 1.30, base),
		Vector2(half * 1.30, base),
		Vector2(half * 0.55, base + length * 0.52),
		Vector2(0.0, base + length),
		Vector2(-half * 0.55, base + length * 0.52),
	]), Color(1.0, 0.44, 0.10, 0.55))

	# 中焰
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half, base),
		Vector2(half, base),
		Vector2(half * 0.42, base + length * 0.45),
		Vector2(0.0, base + length * 0.74),
		Vector2(-half * 0.42, base + length * 0.45),
	]), Color(1.0, 0.72, 0.26, 0.88))

	# 内焰
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half * 0.55, base),
		Vector2(half * 0.55, base),
		Vector2(0.0, base + length * 0.38),
	]), Color(1.0, 0.97, 0.84, 0.95))

	# 分离面亮线
	draw_line(Vector2(-half * 1.1, base), Vector2(half * 1.1, base), Color(1.0, 0.95, 0.8, 0.55), maxf(0.2, w * 0.05))