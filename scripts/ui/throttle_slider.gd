extends Control
## 竖直油门滑块，拖到不同高度即设置油门。

signal value_changed(v: float)

var value := 0.0
var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_active = event.pressed
		if _active:
			_set_from(event.position.y)
	elif event is InputEventScreenDrag:
		if _active:
			_set_from(event.position.y)
	elif event is InputEventMouseButton:
		_active = event.pressed
		if _active:
			_set_from(event.position.y)
	elif event is InputEventMouseMotion:
		if _active:
			_set_from(event.position.y)


func _set_from(y: float) -> void:
	value = clampf(1.0 - y / maxf(size.y, 1.0), 0.0, 1.0)
	emit_signal("value_changed", value)
	queue_redraw()


func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var bar_w := 18.0
	var x: float = size.x * 0.5 - bar_w * 0.5
	draw_rect(Rect2(x, 0.0, bar_w, size.y), Color(1, 1, 1, 0.08), true)
	draw_rect(Rect2(x, 0.0, bar_w, size.y), Color(1, 1, 1, 0.14), false, 1.0)

	var h: float = size.y * value
	draw_rect(Rect2(x, size.y - h, bar_w, h), Color(0.851, 0.639, 0.251, 0.85), true)

	var knob_y: float = size.y - h
	draw_line(Vector2(x - 8.0, knob_y), Vector2(x + bar_w + 8.0, knob_y), Color(0.96, 0.93, 0.86, 0.95), 2.0)
	draw_circle(Vector2(size.x * 0.5, knob_y), 5.0, Color(0.96, 0.93, 0.86, 0.95))