extends Node2D
## 飞行中的火箭实体：多级零件栈、燃料、推力与推进剂消耗。

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


func dry_mass() -> float:
	var m := 0.0
	for item in items:
		m += float(Parts.get_def(String(item["id"]))["dry"])
	return m


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
	var need := thrust / ve * dt * throttle
	if Game.is_cheat("infinite_fuel"):
		return
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


## 抛弃当前级，返回该级的几何信息用于残骸。
func separate() -> Array:
	var r := current_range()
	if r.is_empty():
		return []
	var removed: Array = []
	for i in range(int(r[0]), int(r[1]) + 1):
		var def: Dictionary = Parts.get_def(String(items[i]["id"]))
		removed.append({"w": float(def["w"]), "h": float(def["h"]), "color": def["color"]})
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
		var col: Color = def["color"]
		var rect := Rect2(-w * 0.5, -(cursor + h), w, h)
		var kind := String(def["kind"])

		if kind == "engine":
			draw_rect(rect, col, true)
			var nw := w * 0.78
			draw_colored_polygon(PackedVector2Array([
				Vector2(-nw * 0.5, -cursor + 0.1),
				Vector2(nw * 0.5, -cursor + 0.1),
				Vector2(nw * 0.34, -cursor + h * 0.42),
				Vector2(-nw * 0.34, -cursor + h * 0.42),
			]), Color(0.20, 0.21, 0.21))
			if throttle > 0.02:
				var flame := h * (0.9 + throttle * 1.6) * (0.85 + 0.15 * sin(_t * 46.0))
				draw_colored_polygon(PackedVector2Array([
					Vector2(-nw * 0.40, -cursor + 0.2),
					Vector2(nw * 0.40, -cursor + 0.2),
					Vector2(0.0, -cursor + flame),
				]), Color(1.0, 0.72, 0.30, 0.85))
			draw_rect(rect, Color(0.05, 0.06, 0.06, 0.9), false, 1.0)
		elif kind == "sep":
			draw_rect(rect, Color(col.r, col.g, col.b, 0.9), true)
			draw_rect(rect, Color(0.10, 0.08, 0.04, 0.9), false, 1.0)
		elif kind == "pod":
			draw_rect(rect, col, true)
			draw_rect(Rect2(rect.position + Vector2(w * 0.30, h * 0.22), Vector2(w * 0.40, h * 0.22)), Color(0.22, 0.40, 0.48), true)
			draw_rect(rect, Color(0.05, 0.06, 0.06, 0.9), false, 1.0)
		elif kind == "chute":
			draw_rect(rect, col, true)
			draw_line(Vector2(0.0, -cursor), Vector2(0.0, -cursor - h * 3.0), Color(0.78, 0.30, 0.24), 1.0)
			draw_arc(Vector2(0.0, -cursor - h * 3.0), h * 1.6, PI, TAU, 16, Color(0.78, 0.30, 0.24), 1.5, true)
		elif kind == "legs":
			var lw: float = w * 0.5
			draw_line(Vector2(-lw, -cursor), Vector2(-lw * 1.35, -cursor - h * 1.2), col, 2.0)
			draw_line(Vector2(lw, -cursor), Vector2(lw * 1.35, -cursor - h * 1.2), col, 2.0)
		else:
			draw_rect(rect, col, true)
			var yy: float = rect.position.y + 1.6
			while yy < rect.end.y - 1.0:
				draw_line(Vector2(rect.position.x + 0.2, yy), Vector2(rect.end.x - 0.2, yy), Color(0.0, 0.0, 0.0, 0.20), 0.7)
				yy += 1.8

		cursor += h