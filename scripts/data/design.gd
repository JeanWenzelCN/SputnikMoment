extends RefCounted
## 一份火箭设计：自下而上的零件栈，级与级之间由分离器划分。

const Parts := preload("res://scripts/data/parts.gd")

var items: Array = []


func add(id: String) -> void:
	var def: Dictionary = Parts.get_def(id)
	items.append({"id": id, "fuel": float(def["fuel"])})


func remove_last() -> void:
	if items.size() > 0:
		items.pop_back()


func pop_last() -> Dictionary:
	if items.is_empty():
		return {}
	return items.pop_back()


func clear() -> void:
	items.clear()


func size() -> int:
	return items.size()


func dry_mass() -> float:
	var m := 0.0
	for item in items:
		m += float(Parts.get_def(String(item["id"]))["dry"])
	return m


func fuel_mass() -> float:
	var m := 0.0
	for item in items:
		m += float(item["fuel"])
	return m


func total_mass() -> float:
	return dry_mass() + fuel_mass()


func height() -> float:
	var h := 0.0
	for item in items:
		h += float(Parts.get_def(String(item["id"]))["h"])
	return h


func max_width() -> float:
	var w := 0.5
	for item in items:
		w = maxf(w, float(Parts.get_def(String(item["id"]))["w"]))
	return w


## 自下而上的分级：返回 [[起始索引, 结束索引], ...]，不含分离器本身。
func stage_ranges() -> Array:
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


func stage_count() -> int:
	return maxi(1, stage_ranges().size())


## 最下面一级（当前工作级）的推力总和。
func current_thrust() -> float:
	var ranges := stage_ranges()
	if ranges.is_empty():
		return 0.0
	var r: Array = ranges[0]
	var t := 0.0
	for i in range(int(r[0]), int(r[1]) + 1):
		var def: Dictionary = Parts.get_def(String(items[i]["id"]))
		t += float(def["thrust"])
	return t


func total_thrust() -> float:
	var t := 0.0
	for item in items:
		t += float(Parts.get_def(String(item["id"]))["thrust"])
	return t


## 分级 Δv 之和（从顶到底累积质量）。
func delta_v() -> float:
	var ranges := stage_ranges()
	if ranges.is_empty():
		return 0.0
	var above_mass := 0.0
	var dv_total := 0.0
	for idx in range(ranges.size() - 1, -1, -1):
		var r: Array = ranges[idx]
		var dry := 0.0
		var fuel := 0.0
		var thrust := 0.0
		var ve := 0.0
		for i in range(int(r[0]), int(r[1]) + 1):
			var item: Dictionary = items[i]
			var def: Dictionary = Parts.get_def(String(item["id"]))
			dry += float(def["dry"])
			fuel += float(item["fuel"])
			var t := float(def["thrust"])
			if t > 0.0:
				thrust += t
				ve = float(def["isp"]) * 9.80665
		var m_full := above_mass + dry + fuel
		var m_dry := above_mass + dry
		if thrust > 0.0 and fuel > 0.0 and m_dry > 0.0 and m_full > m_dry:
			dv_total += ve * log(m_full / m_dry)
		above_mass = m_full
	return dv_total


func pad_thrust_to_weight() -> float:
	var t := current_thrust()
	var m := total_mass()
	if m <= 0.0:
		return 0.0
	return t / (m * 9.80665)


func to_dict() -> Dictionary:
	var ids: Array = []
	for item in items:
		ids.append(String(item["id"]))
	return {"version": 1, "parts": ids}


func from_dict(data: Dictionary) -> void:
	items.clear()
	var list: Array = data.get("parts", [])
	for id in list:
		if Parts.DEFS.has(String(id)):
			add(String(id))


func default_design() -> void:
	clear()
	add("eng_m")
	add("tank_m")
	add("tank_m")
	add("sep")
	add("eng_s")
	add("tank_s")
	add("pod")
	add("chute")
