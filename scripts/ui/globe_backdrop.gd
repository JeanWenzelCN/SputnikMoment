extends Control
## 菜单背景：星点 + 缓慢转动的线框地球。

const UI := preload("res://scripts/ui/ui_kit.gd")

var _t := 0.0
var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 1967
	for i in range(170):
		_stars.append({
			"p": Vector2(_rng.randf(), _rng.randf()),
			"r": _rng.randf_range(0.5, 1.6),
			"a": _rng.randf_range(0.10, 0.70),
			"ph": _rng.randf_range(0.0, TAU),
			"sp": _rng.randf_range(0.3, 1.1),
		})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UI.BG, true)

	for st in _stars:
		var p: Vector2 = st["p"] * s
		var tw: float = 0.66 + 0.34 * sin(_t * float(st["sp"]) + float(st["ph"]))
		draw_circle(p, float(st["r"]), Color(0.86, 0.88, 0.92, float(st["a"]) * tw))

	var c := Vector2(s.x * 0.74, s.y * 0.52)
	var r: float = minf(s.x, s.y) * 0.40
	_draw_globe(c, r)


func _draw_globe(c: Vector2, r: float) -> void:
	var rim := Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.42)
	var line := Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.13)

	# 球体
	draw_circle(c, r, Color(0.055, 0.075, 0.085, 0.85))
	draw_circle(c, r, Color(1.0, 0.72, 0.30, 0.03))

	# 外环
	for i in range(2):
		var rr: float = r * (1.06 + float(i) * 0.09)
		draw_arc(c, rr, 0.0, TAU, 144, Color(line.r, line.g, line.b, line.a * 0.7), 1.0, true)

	# 纬线
	for i in range(1, 9):
		var lat: float = (float(i) / 9.0 - 0.5) * PI
		var yy: float = c.y - r * sin(lat)
		var rx: float = r * cos(lat)
		_draw_ellipse(Vector2(c.x, yy), rx, rx * 0.24, line)

	# 经线（缓慢转动）
	for i in range(7):
		var ang: float = (float(i) / 7.0) * PI + _t * 0.05
		var rx: float = absf(r * cos(ang))
		_draw_ellipse(c, rx, r, line)

	# 扫描线
	var sweep: float = fmod(_t * 0.3, TAU)
	var tip := c + Vector2(cos(sweep), sin(sweep)) * r
	draw_line(c, tip, Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.22), 1.0, true)
	draw_arc(c, r, sweep - 0.28, sweep, 24, Color(1.0, 0.78, 0.38, 0.14), 2.0, true)

	# 轮廓
	draw_arc(c, r, 0.0, TAU, 160, rim, 1.2, true)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx < 0.6:
		return
	var pts := PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, color, 1.0, true)