extends Control
## 地图：局部 SOI 视图 / 太阳系全图；点击天体可设为导航目标。

const OrbitMath := preload("res://scripts/orbit.gd")

var view = null
var global_view := false
var _marks: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


func toggle_scale() -> void:
	global_view = not global_view


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_pick(event.position)


func _pick(at: Vector2) -> void:
	if view == null:
		return
	for m in _marks:
		if (at - m["p"]).length() < maxf(26.0, float(m["r"]) + 16.0):
			view.set_target(String(m["id"]))
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.018, 0.024, 1.0), true)
	_marks.clear()
	if view == null:
		return

	var font := get_theme_default_font()
	var center := size * 0.5
	var dom: Dictionary = view.dominant_body()
	var dom_pos: Vector2 = dom["pos"]

	if global_view:
		var span := 1.0
		for b in view.bodies:
			span = maxf(span, float(b["orbit_r"]) + float(b["radius"]))
		var sg: float = minf(size.x, size.y) * 0.44 / span

		for b in view.bodies:
			var orbit_r: float = float(b["orbit_r"])
			var parent: String = String(b["parent"])
			if orbit_r > 0.0 and parent == "sun":
				draw_arc(center, orbit_r * sg, 0.0, TAU, 128, Color(1, 1, 1, 0.10), 1.0, true)

		for b in view.bodies:
			var p: Vector2 = center + Vector2(b["pos"]) * sg
			var r: float = maxf(3.0, float(b["radius"]) * sg * 8.0)
			var col: Color = b["color"]
			if String(b["id"]) == view.target_id:
				draw_arc(p, r + 8.0, 0.0, TAU, 24, Color(0.55, 0.88, 0.72, 0.9), 2.0, true)
			draw_circle(p, r, col)
			draw_string(font, p + Vector2(r + 5.0, 4.0), String(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.76, 0.78))
			_marks.append({"id": String(b["id"]), "p": p, "r": r})

		var ship_p: Vector2 = center + Vector2(dom_pos + view.pos - Vector2(dom["pos"])) * sg
		draw_circle(ship_p, 3.5, Color(1.0, 0.86, 0.45))
		draw_string(font, Vector2(26, 38), "太阳系", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.96, 0.70, 0.30))
	else:
		var soi: float = float(dom["soi"])
		if soi <= 0.0:
			soi = 16000000.0
		var apo: float = float(view.orbit_el.get("apo", 0.0))
		if not is_finite(apo) or apo <= 0.0:
			apo = float(dom["radius"]) * 2.0
		var span2: float = maxf(maxf(apo * 1.15, float(dom["radius"]) * 1.9), soi * 0.55)
		var sl: float = minf(size.x, size.y) * 0.44 / span2

		# 本天体
		var r_dom: float = float(dom["radius"]) * sl
		if String(dom["id"]) == view.target_id:
			draw_arc(center, r_dom + 8.0, 0.0, TAU, 40, Color(0.55, 0.88, 0.72, 0.9), 2.0, true)
		draw_circle(center, r_dom, dom["color"])
		_marks.append({"id": String(dom["id"]), "p": center, "r": r_dom})
		draw_string(font, center + Vector2(r_dom + 8.0, 4.0), String(dom["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.76, 0.78))

		# 其他天体（相对本天体）
		for b in view.bodies:
			if String(b["id"]) == String(dom["id"]):
				continue
			var rel: Vector2 = Vector2(b["pos"]) - dom_pos
			var bp: Vector2 = center + rel * sl
			if bp.x < -150.0 or bp.x > size.x + 150.0 or bp.y < -150.0 or bp.y > size.y + 150.0:
				continue
			var br: float = maxf(2.5, float(b["radius"]) * sl * 6.0)
			if String(b["id"]) == view.target_id:
				draw_arc(bp, br + 7.0, 0.0, TAU, 20, Color(0.55, 0.88, 0.72, 0.9), 2.0, true)
			draw_circle(bp, br, b["color"])
			draw_string(font, bp + Vector2(br + 6.0, 4.0), String(b["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.70, 0.74, 0.76))
			_marks.append({"id": String(b["id"]), "p": bp, "r": br})

		# 轨道
		var pts: PackedVector2Array = OrbitMath.sample(view.orbit_el, 200)
		if pts.size() > 2:
			var screen_pts := PackedVector2Array()
			for p in pts:
				screen_pts.append(center + p * sl)
			draw_polyline(screen_pts, Color(0.96, 0.66, 0.26, 0.9), 1.6, true)

		# 飞船
		var ship: Vector2 = center + view.pos * sl
		draw_circle(ship, 4.5, Color(0.95, 0.96, 1.0))
		draw_arc(ship, 10.0, 0.0, TAU, 24, Color(0.95, 0.96, 1.0, 0.45), 1.0, true)

		# 到目标的连线
		if not view.target_id.is_empty():
			for m in _marks:
				if String(m["id"]) == view.target_id:
					draw_dashed_line(ship, m["p"], Color(0.55, 0.88, 0.72, 0.45), 1.0, 6.0)
					break

		draw_string(font, Vector2(26, 38), "%s SOI" % String(dom["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.96, 0.70, 0.30))

	draw_string(font, Vector2(26, size.y - 22.0), "点天体设为目标 · 「全图」切换太阳系", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.48, 0.52, 0.54))