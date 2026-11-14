extends Control
## 轨道地图：显示行星、当前轨道、远/近地点与飞船位置。

const OrbitMath := preload("res://scripts/orbit.gd")

var view = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.016, 0.9), true)
	if view == null:
		return

	var planet_r: float = view.planet_radius()
	var el: Dictionary = view.orbit_el
	var center: Vector2 = size * 0.5

	var apo: float = 0.0
	if el.has("apo") and is_finite(float(el["apo"])):
		apo = float(el["apo"])
	var span: float = maxf(maxf(apo, planet_r * 1.6) * 2.2, planet_r * 2.4)
	var scale: float = minf(size.x, size.y) * 0.46 / span

	var font := get_theme_default_font()

	draw_circle(center, planet_r * scale, Color(0.10, 0.17, 0.19))
	draw_arc(center, planet_r * scale, 0.0, TAU, 96, Color(0.38, 0.60, 0.68, 0.55), 1.0, true)
	draw_arc(center, (planet_r + 70000.0) * scale, 0.0, TAU, 96, Color(0.38, 0.60, 0.68, 0.18), 1.0, true)
	draw_circle(center, 2.5, Color(0.75, 0.82, 0.85))

	var pts: PackedVector2Array = OrbitMath.sample(el, 200)
	if pts.size() > 2:
		var screen_pts := PackedVector2Array()
		for p in pts:
			screen_pts.append(center + p * scale)
		draw_polyline(screen_pts, Color(0.96, 0.66, 0.26, 0.85), 1.6, true)

	var ship: Vector2 = center + view.pos * scale
	draw_circle(ship, 4.5, Color(0.92, 0.96, 1.0))
	draw_arc(ship, 9.0, 0.0, TAU, 24, Color(0.92, 0.96, 1.0, 0.45), 1.0, true)

	if el.has("peri_dir"):
		var dir: Vector2 = el["peri_dir"]
		var apo_r: float = float(el["apo"]) if is_finite(float(el["apo"])) else planet_r * 3.0
		var peri_r: float = float(el["peri"])
		var ap_p: Vector2 = center - dir * apo_r * scale
		var pe_p: Vector2 = center + dir * peri_r * scale
		draw_circle(ap_p, 3.5, Color(0.55, 0.85, 0.70))
		draw_circle(pe_p, 3.5, Color(0.95, 0.55, 0.40))
		draw_string(font, ap_p + Vector2(8, -6), "Ap", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.85, 0.70))
		draw_string(font, pe_p + Vector2(8, 16), "Pe", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.55, 0.40))

	draw_string(font, Vector2(24, 32), "轨道视图", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.96, 0.70, 0.30))
	draw_string(font, Vector2(24, 56), "按「地图」返回飞行视角", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.56, 0.61, 0.62))