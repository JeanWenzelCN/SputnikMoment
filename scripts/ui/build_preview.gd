extends Control
## 设计台的火箭预览。

const Parts := preload("res://scripts/data/parts.gd")

var design = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.052, 0.064, 0.072, 0.9), true)
	_draw_grid()

	if design == null or design.size() == 0:
		var font := get_theme_default_font()
		draw_string(font, Vector2(size.x * 0.5 - 64.0, size.y * 0.5), "选择零件开始搭建", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.40, 0.44, 0.46))
		return

	var total_h: float = maxf(design.height(), 1.0)
	var max_w: float = maxf(design.max_width(), 1.0)
	var s: float = minf((size.y - 80.0) / total_h, (size.x - 120.0) / max_w)
	s = clampf(s, 0.5, 34.0)

	var cx := size.x * 0.5
	var cursor := size.y * 0.5 + total_h * s * 0.5
	var ground := cursor

	for item in design.items:
		var def: Dictionary = Parts.get_def(String(item["id"]))
		var w: float = float(def["w"]) * s
		var h: float = float(def["h"]) * s
		var rect := Rect2(cx - w * 0.5, cursor - h, w, h)
		var col: Color = def["color"]
		var kind := String(def["kind"])

		if kind == "sep":
			col = Color(0.86, 0.55, 0.16)

		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(int(maxf(1.0, s * 0.10)))
		draw_style_box(sb, rect)

		draw_rect(Rect2(rect.position, Vector2(w * 0.16, h)), Color(1.0, 1.0, 1.0, 0.10))
		draw_rect(Rect2(rect.position + Vector2(w * 0.85, 0.0), Vector2(w * 0.15, h)), Color(0.0, 0.0, 0.0, 0.14))
		draw_line(Vector2(rect.position.x, rect.end.y - 0.5), Vector2(rect.end.x, rect.end.y - 0.5), Color(0.0, 0.0, 0.0, 0.28), 1.0)

		if kind == "engine":
			var nw := w * 0.66
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - nw * 0.5, rect.end.y - 1.0),
				Vector2(cx + nw * 0.5, rect.end.y - 1.0),
				Vector2(cx + nw * 0.34, rect.end.y + h * 0.34),
				Vector2(cx - nw * 0.34, rect.end.y + h * 0.34),
			]), Color(0.17, 0.18, 0.19))
		elif kind == "pod":
			var win := Rect2(rect.position + Vector2(w * 0.28, h * 0.22), Vector2(w * 0.44, h * 0.24))
			draw_rect(win, Color(0.20, 0.38, 0.46), true)
			draw_rect(win, Color(0.0, 0.0, 0.0, 0.35), false, 1.0)
		elif kind == "chute":
			var top := Vector2(cx, rect.position.y)
			draw_line(top, top + Vector2(0.0, -h * 1.1), Color(0.80, 0.32, 0.26), maxf(1.0, s * 0.12))
			draw_arc(top + Vector2(0.0, -h * 1.1), h * 0.6, PI, TAU, 16, Color(0.80, 0.32, 0.26), maxf(1.0, s * 0.10), true)
		elif kind == "legs":
			var lw: float = w * 0.5
			draw_line(Vector2(cx - lw, cursor), Vector2(cx - lw * 1.35, cursor + h * 1.1), col, maxf(1.0, s * 0.14))
			draw_line(Vector2(cx + lw, cursor), Vector2(cx + lw * 1.35, cursor + h * 1.1), col, maxf(1.0, s * 0.14))

		cursor -= h

	draw_line(Vector2(cx - max_w * s * 0.95, ground), Vector2(cx + max_w * s * 0.95, ground), Color(0.85, 0.64, 0.25, 0.5), 1.5)


func _draw_grid() -> void:
	var col := Color(1.0, 1.0, 1.0, 0.025)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.0)
		x += 40.0
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.0)
		y += 40.0