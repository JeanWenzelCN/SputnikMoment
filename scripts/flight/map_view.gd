extends Control
## 地图：局部轨道视图 / 太阳系全图两档。

const OrbitMath := preload("res://scripts/orbit.gd")

var view = null
var global_view := false


func _process(_delta: float) -> void:
	queue_redraw()


func toggle_scale() -> void:
	global_view = not global_view


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.016, 0.94), true)
	if view == null:
		return

	var font := get_theme_default_font()
	var center := size * 0.5

	if global_view:
		var span := 1.0
		for b in view.bodies:
			span = maxf(span, float(b["orbit_r"]) + float(b["radius"]))
		var scale_g: float = minf(size.x, size.y) * 0.44 / span

		for b in view.bodies:
			var orbit_r: float = float(b["orbit_r"])
			if orbit_r > 0.0:
				draw_arc(center, orbit_r * scale_g, 0.0, TAU, 128, Color(1, 1, 1, 0.10), 1.0, true)

		for b in view.bodies:
			var p: Vector2 = center + Vector2(b["pos"]) * scale_g
			var r: float = maxf(3.0, float(b["radius"]) * scale_g * 6.0)
			draw_circle(p, r, b["color"])
			draw_string(font, p + Vector2(r + 4.0, 4.0), String(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.72, 0.76, 0.78))

		var ship_p: Vector2 = center + view.pos * scale_g
		draw_circle(ship_p, 3.5, Color(1.0, 0.86, 0.45))
		draw_arc(ship_p, 8.0, 0.0, TAU, 20, Color(1.0, 0.86, 0.45, 0.5), 1.0, true)
		draw_string(font, Vector2(28, 40), "太阳系", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.96, 0.70, 0.30))
	else:
		var dom: Dictionary = view.dominant_body()
		var dom_r: float = float(dom["radius"])
		var apo: float = float(view.orbit_el.get("apo", dom_r * 2.0))
		if not is_finite(apo):
			apo = dom_r * 4.0
		var span2: float = maxf(apo, dom_r * 1.8)
		var scale_l: float = minf(size.x, size.y) * 0.42 / span2

		draw_circle(center, dom_r * scale_l, dom["color"])
		if float(dom["atmo"]) > 0.0:
			draw_arc(center, (dom_r + float(dom["atmo"])) * scale_l, 0.0, TAU, 96, Color(0.45, 0.68, 0.80, 0.35), 1.0, true)

		var pts: PackedVector2Array = OrbitMath.sample(view.orbit_el, 220)
		if pts.size() > 2:
			var screen_pts := PackedVector2Array()
			for p in pts:
				screen_pts.append(center + p * scale_l)
			draw_polyline(screen_pts, Color(0.96, 0.66, 0.26, 0.9), 1.6, true)

		var rel: Vector2 = view.pos - Vector2(dom["pos"])
		var ship: Vector2 = center + rel * scale_l
		draw_circle(ship, 4.5, Color(0.95, 0.96, 1.0))
		draw_arc(ship, 10.0, 0.0, TAU, 24, Color(0.95, 0.96, 1.0, 0.45), 1.0, true)

		# 其他天体（若在视野内）
		for b in view.bodies:
			if String(b["id"]) == String(dom["id"]):
				continue
			var bp: Vector2 = center + (Vector2(b["pos"]) - Vector2(dom["pos"])) * scale_l
			if bp.x < -200.0 or bp.x > size.x + 200.0 or bp.y < -200.0 or bp.y > size.y + 200.0:
				continue
			draw_circle(bp, maxf(2.0, float(b["radius"]) * scale_l * 5.0), b["color"])
			draw_string(font, bp + Vector2(8.0, 4.0), String(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.70, 0.74, 0.76))

		draw_string(font, Vector2(28, 40), "%s 轨道" % String(dom["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.96, 0.70, 0.30))

	draw_string(font, Vector2(28, size.y - 24.0), "点「全图」切换太阳系视图", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.48, 0.52, 0.54))