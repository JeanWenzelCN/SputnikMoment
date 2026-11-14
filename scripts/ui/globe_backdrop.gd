extends Control
## Mission-control backdrop: star field, plotting grid and a wireframe globe.

const UI := preload("res://scripts/ui/ui_kit.gd")

var _t := 0.0
var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 1967
	_seed_stars()


func _seed_stars() -> void:
	_stars.clear()
	for i in range(190):
		_stars.append({
			"p": Vector2(_rng.randf(), _rng.randf()),
			"r": _rng.randf_range(0.5, 1.7),
			"a": _rng.randf_range(0.10, 0.75),
			"ph": _rng.randf_range(0.0, TAU),
			"sp": _rng.randf_range(0.3, 1.2),
		})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UI.INK, true)
	_draw_grid(s)

	for st in _stars:
		var p: Vector2 = st["p"] * s
		var tw: float = 0.62 + 0.38 * sin(_t * float(st["sp"]) + float(st["ph"]))
		draw_circle(p, float(st["r"]), Color(0.86, 0.88, 0.90, float(st["a"]) * tw))

	var c := Vector2(s.x * 0.755, s.y * 0.50)
	var r: float = minf(s.x, s.y) * 0.395
	_draw_globe(c, r)


func _draw_grid(s: Vector2) -> void:
	var col := Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.032)
	var x := 0.0
	while x < s.x:
		draw_line(Vector2(x, 0.0), Vector2(x, s.y), col, 1.0)
		x += 96.0
	var y := 0.0
	while y < s.y:
		draw_line(Vector2(0.0, y), Vector2(s.x, y), col, 1.0)
		y += 96.0


func _draw_globe(c: Vector2, r: float) -> void:
	var rim := Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.30)
	var line := Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.105)

	draw_circle(c, r, Color(1.0, 0.72, 0.30, 0.045))

	for i in range(3):
		var rr: float = r * (1.045 + float(i) * 0.075)
		draw_arc(c, rr, 0.0, TAU, 144, Color(line.r, line.g, line.b, line.a * 0.75), 1.0, true)

	for i in range(1, 9):
		var lat: float = (float(i) / 9.0 - 0.5) * PI
		var yy: float = c.y - r * sin(lat)
		var rx: float = r * cos(lat)
		_draw_ellipse(Vector2(c.x, yy), rx, rx * 0.22, line)

	for i in range(6):
		var ang: float = (float(i) / 6.0) * PI + _t * 0.045
		var rx: float = absf(r * cos(ang))
		_draw_ellipse(c, rx, r, line)

	var sweep: float = fmod(_t * 0.33, TAU)
	var tip := c + Vector2(cos(sweep), sin(sweep)) * r
	draw_line(c, tip, Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.26), 1.0, true)
	draw_arc(c, r, sweep - 0.30, sweep, 24, Color(1.0, 0.75, 0.35, 0.16), 2.0, true)

	draw_arc(c, r, 0.0, TAU, 160, rim, 1.0, true)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx < 0.6:
		return
	var pts := PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, color, 1.0, true)