extends Control
## 装配区：接收零件栏拖入的零件，按落点插入到火箭相应位置。

signal design_changed

const Parts := preload("res://scripts/data/parts.gd")

var design = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _metrics() -> Dictionary:
	var total_h: float = maxf(design.height(), 1.0)
	var max_w: float = maxf(design.max_width(), 1.0)
	var s: float = minf((size.y - 110.0) / total_h, (size.x - 150.0) / max_w)
	s = clampf(s, 0.5, 30.0)
	return {"s": s, "base": size.y * 0.5 + total_h * s * 0.5}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.058, 0.070, 0.078, 0.95), true)
	draw_grid()

	var font := get_theme_default_font()
	if design == null or design.size() == 0:
		draw_string(font, Vector2(size.x * 0.5 - 72.0, size.y * 0.5), "把零件拖到这里", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.40, 0.44, 0.46))
		return

	var m := _metrics()
	var s: float = float(m["s"])
	var base: float = float(m["base"])
	var cx := size.x * 0.5
	var cursor := base

	# 发射台基准
	draw_line(Vector2(cx - 120.0, base), Vector2(cx + 120.0, base), Color(0.851, 0.639, 0.251, 0.65), 2.0)
	for i in range(9):
		var gx := cx - 96.0 + float(i) * 24.0
		draw_line(Vector2(gx, base), Vector2(gx - 10.0, base + 14.0), Color(0.851, 0.639, 0.251, 0.22), 1.0)

	for item in design.items:
		var id := String(item["id"])
		var def: Dictionary = Parts.get_def(id)
		var w: float = float(def["w"]) * s
		var h: float = float(def["h"]) * s
		var rect := Rect2(cx - w * 0.5, cursor - h, w, h)
		var tex := Parts.texture(id)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		cursor -= h


func _draw_grid() -> void:
	var col := Color(1.0, 1.0, 1.0, 0.022)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.0)
		x += 40.0
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.0)
		y += 40.0


func _index_at(y: float) -> int:
	if design == null:
		return 0
	var m := _metrics()
	var s: float = float(m["s"])
	var cursor: float = float(m["base"])
	for i in range(design.items.size()):
		var def: Dictionary = Parts.get_def(String(design.items[i]["id"]))
		var h: float = float(def["h"]) * s
		if y > cursor - h * 0.5:
			return i
		cursor -= h
	return design.items.size()


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("part") and design != null


func _drop_data(at_position: Vector2, data) -> void:
	design.insert(_index_at(at_position.y), String(data["part"]))
	design_changed.emit()
	queue_redraw()