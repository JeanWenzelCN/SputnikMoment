extends Node2D
## 分离后的残骸：受重力下落，若干秒后淡出。

const MU := 9.80665 * 600000.0 * 600000.0

var segs: Array = []
var velocity := Vector2.ZERO
var spin := 0.0
var life := 22.0


func setup(geometry: Array, start_vel: Vector2, start_spin: float) -> void:
	segs = geometry
	velocity = start_vel
	spin = start_spin


func _process(delta: float) -> void:
	var r: float = maxf(1.0, position.length())
	var g: float = MU / (r * r)
	velocity += -position.normalized() * g * delta
	position += velocity * delta
	rotation += spin * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if r < 600000.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(life / 4.0, 0.0, 1.0)
	var cursor := 0.0
	for seg in segs:
		var w := float(seg["w"])
		var h := float(seg["h"])
		var col: Color = seg["color"]
		draw_rect(Rect2(-w * 0.5, -cursor - h, w, h), Color(col.r, col.g, col.b, fade), true)
		draw_rect(Rect2(-w * 0.5, -cursor - h, w, h), Color(0.05, 0.05, 0.05, fade * 0.8), false, 0.6)
		cursor += h