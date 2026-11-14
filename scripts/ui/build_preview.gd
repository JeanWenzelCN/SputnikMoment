extends Control
## 设计台中央的火箭预览，按米制尺寸等比缩放绘制。

const Parts := preload("res://scripts/data/parts.gd")

var design = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.031, 0.039, 0.043, 0.55), true)

	var grid := Color(0.55, 0.42, 0.18, 0.10)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid, 1.0)
		x += 48.0
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid, 1.0)
		y += 48.0

	if design == null or design.size() == 0:
		return

	var total_h: float = maxf(design.height(), 1.0)
	var max_w: float = maxf(design.max_width(), 1.0)
	var scale: float = minf((size.y - 90.0) / total_h, (size.x - 140.0) / max_w)
	scale = clampf(scale, 0.5, 46.0)

	var cx := size.x * 0.5
	var base_y := size.y * 0.5 + total_h * scale * 0.5
	var cursor := base_y

	for item in design.items:
		var def: Dictionary = Parts.get_def(String(item["id"]))
		var w: float = float(def["w"]) * scale
		var h: float = float(def["h"]) * scale
		var rect := Rect2(cx - w * 0.5, cursor - h, w, h)
		var col: Color = def["color"]
		draw_rect(rect, col, true)
		draw_rect(rect, Color(0.04, 0.05, 0.05, 0.85), false, 1.2)

		var kind := String(def["kind"])
		if kind == "tank":
			var yy: float = rect.position.y + 3.0
			while yy < rect.end.y - 2.0:
				draw_line(Vector2(rect.position.x + 1.0, yy), Vector2(rect.end.x - 1.0, yy), Color(0.0, 0.0, 0.0, 0.18), 1.0)
				yy += 7.0
		elif kind == "engine":
			var nw := w * 0.72
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - nw * 0.5, rect.end.y - 1.0),
				Vector2(cx + nw * 0.5, rect.end.y - 1.0),
				Vector2(cx + nw * 0.36, rect.end.y + h * 0.28),
				Vector2(cx - nw * 0.36, rect.end.y + h * 0.28),
			]), Color(0.22, 0.23, 0.23))
		elif kind == "sep":
			draw_rect(rect, Color(0.90, 0.55, 0.16, 0.85), true)
		elif kind == "pod":
			draw_rect(Rect2(rect.position + Vector2(w * 0.30, h * 0.25), Vector2(w * 0.40, h * 0.22)), Color(0.24, 0.42, 0.50), true)
		elif kind == "chute":
			draw_line(Vector2(cx, rect.position.y), Vector2(cx, rect.position.y - h * 0.9), Color(0.78, 0.30, 0.24), 2.0)
			draw_arc(Vector2(cx, rect.position.y - h * 0.9), h * 0.55, PI, TAU, 18, Color(0.78, 0.30, 0.24), 2.0, true)
		elif kind == "legs":
			draw_line(Vector2(rect.position.x, rect.end.y - 1.0), Vector2(rect.position.x - w * 0.16, rect.end.y + h * 0.5), col, 2.0)
			draw_line(Vector2(rect.end.x, rect.end.y - 1.0), Vector2(rect.end.x + w * 0.16, rect.end.y + h * 0.5), col, 2.0)

		cursor -= h

	# 基准线
	draw_line(Vector2(cx - max_w * scale * 0.85, base_y), Vector2(cx + max_w * scale * 0.85, base_y), Color(0.90, 0.62, 0.22, 0.55), 1.5)