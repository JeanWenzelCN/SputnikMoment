extends Node2D
## 分离后的残骸：受重力下落，若干秒后消失。

const Parts := preload("res://scripts/data/parts.gd")

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
	if life <= 0.0 or r < 600000.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var cursor := 0.0
	for id in segs:
		var def: Dictionary = Parts.get_def(String(id))
		var w: float = float(def["w"])
		var h: float = float(def["h"])
		var tex := Parts.texture(String(id))
		if tex != null:
			draw_texture_rect(tex, Rect2(-w * 0.5, -cursor - h, w, h), false)
		cursor += h