extends Node2D
## Test article 01: a small two-stage sounding rocket, purely visual + state.

var velocity := Vector2.ZERO
var fuel := 100.0
var fuel_max := 100.0
var throttle_vis := 0.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if throttle_vis > 0.03:
		_draw_flame()

	var hull := Color(0.80, 0.81, 0.78)
	var shade := Color(0.52, 0.54, 0.53)
	var accent := Color(0.63, 0.17, 0.13)
	var dark := Color(0.28, 0.30, 0.30)

	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.5, 8.0), Vector2(-15.5, 26.0), Vector2(-13.0, 29.0), Vector2(-4.5, 21.0)
	]), accent)
	draw_colored_polygon(PackedVector2Array([
		Vector2(4.5, 8.0), Vector2(15.5, 26.0), Vector2(13.0, 29.0), Vector2(4.5, 21.0)
	]), accent)

	var body := PackedVector2Array([
		Vector2(0.0, -26.0), Vector2(4.6, -16.0), Vector2(5.2, -4.0),
		Vector2(5.2, 20.0), Vector2(3.6, 23.0), Vector2(-3.6, 23.0),
		Vector2(-5.2, 20.0), Vector2(-5.2, -4.0), Vector2(-4.6, -16.0)
	])
	draw_colored_polygon(body, hull)

	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, shade, 1.0, true)

	draw_line(Vector2(-2.6, -18.0), Vector2(-2.6, 18.0), Color(1.0, 1.0, 1.0, 0.30), 1.0, true)
	draw_line(Vector2(-5.2, 14.0), Vector2(5.2, 14.0), dark, 1.2, true)
	draw_line(Vector2(-5.2, 6.0), Vector2(5.2, 6.0), Color(dark.r, dark.g, dark.b, 0.6), 1.0, true)

	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -26.0), Vector2(4.2, -17.5), Vector2(-4.2, -17.5)
	]), accent)

	draw_circle(Vector2(0.0, -9.0), 2.7, Color(0.30, 0.55, 0.66))
	draw_arc(Vector2(0.0, -9.0), 2.7, 0.0, TAU, 20, Color(0.80, 0.82, 0.80, 0.9), 0.8, true)

	for i in range(5):
		draw_circle(Vector2(0.0, -14.0 + float(i) * 6.6), 0.75, shade)


func _draw_flame() -> void:
	var l := 15.0 + 11.0 * throttle_vis + sin(_t * 44.0) * 3.0
	var w := 3.2 + 1.1 * throttle_vis
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 1.7, 23.0), Vector2(w * 1.7, 23.0), Vector2(0.0, 23.0 + l * 1.30)
	]), Color(1.0, 0.44, 0.12, 0.5))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, 23.0), Vector2(w, 23.0), Vector2(0.0, 23.0 + l)
	]), Color(1.0, 0.86, 0.46, 0.92))