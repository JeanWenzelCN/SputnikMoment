extends Control
## 姿态摇杆：按下拖动，输出 -1..1 的横向量。

signal vector_changed(v: Vector2)

var radius := 74.0
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob = _center


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		if not _active:
			_knob = _center
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_active = true
			_center = event.position
			_knob = event.position
			queue_redraw()
		else:
			_reset()
	elif event is InputEventScreenDrag:
		if _active:
			_update(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			_active = true
			_center = event.position
			_knob = event.position
			queue_redraw()
		else:
			_reset()
	elif event is InputEventMouseMotion:
		if _active:
			_update(event.position)


func _reset() -> void:
	_active = false
	_center = size * 0.5
	_knob = _center
	emit_signal("vector_changed", Vector2.ZERO)
	queue_redraw()


func _update(at: Vector2) -> void:
	var d: Vector2 = at - _center
	if d.length() > radius:
		d = d.normalized() * radius
	_knob = _center + d
	emit_signal("vector_changed", d / radius)
	queue_redraw()


func _draw() -> void:
	draw_circle(_center, radius, Color(0.35, 0.55, 0.75, 0.07))
	draw_arc(_center, radius, 0.0, TAU, 48, Color(0.45, 0.62, 0.80, 0.28), 1.5, true)
	draw_line(_center - Vector2(radius * 0.5, 0.0), _center + Vector2(radius * 0.5, 0.0), Color(0.45, 0.62, 0.80, 0.14), 1.0)
	draw_line(_center - Vector2(0.0, radius * 0.5), _center + Vector2(0.0, radius * 0.5), Color(0.45, 0.62, 0.80, 0.14), 1.0)
	draw_circle(_knob, 26.0, Color(0.40, 0.62, 0.82, 0.30))
	draw_arc(_knob, 26.0, 0.0, TAU, 32, Color(0.55, 0.75, 0.92, 0.75), 1.6, true)