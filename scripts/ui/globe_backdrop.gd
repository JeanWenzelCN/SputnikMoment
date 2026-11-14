extends Control
## 静态星空背景：只做一层极淡的星点，不干扰界面。

const UI := preload("res://scripts/ui/ui_kit.gd")

var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 1967
	for i in range(140):
		_stars.append({
			"p": Vector2(_rng.randf(), _rng.randf()),
			"r": _rng.randf_range(0.6, 1.5),
			"a": _rng.randf_range(0.08, 0.42),
		})


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UI.BG, true)
	for st in _stars:
		var p: Vector2 = st["p"] * s
		draw_circle(p, float(st["r"]), Color(0.86, 0.88, 0.92, float(st["a"])))