extends Control
## 装配区：可自由缩放与平移，蓝图长度不设上限；接收零件栏拖入。

signal design_changed

const Parts := preload("res://scripts/data/parts.gd")

var design = null
var view_zoom := 20.0
var pan := Vector2(0.0, 4.0)
var _panning := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func world_to_screen(world: Vector2) -> Vector2:
	return size * 0.5 + (world - pan) * view_zoom


func screen_to_world(p: Vector2) -> Vector2:
	return (p - size * 0.5) / view_zoom + pan


func zoom_by(factor: float) -> void:
	view_zoom = clampf(view_zoom * factor, 2.0, 120.0)
	queue_redraw()


func recenter() -> void:
	if design == null or design.size() == 0:
		view_zoom = 20.0
		pan = Vector2(0.0, 4.0)
		queue_redraw()
		return
	var h: float = maxf(design.height(), 2.0)
	var w: float = maxf(design.max_width(), 2.0)
	view_zoom = clampf(minf((size.y - 90.0) / h, (size.x - 140.0) / w), 2.0, 60.0)
	pan = Vector2(0.0, h * 0.5)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		zoom_by(float(event.factor))
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1.15)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 1.15)
			return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pan -= event.relative / view_zoom
		queue_redraw()
		return
	if event is InputEventScreenDrag:
		pan -= event.relative / view_zoom
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.058, 0.070, 0.078, 0.95), true)
	_draw_grid()

	if design == null or design.size() == 0:
		var font := get_theme_default_font()
		draw_string(font, Vector2(size.x * 0.5 - 72.0, size.y * 0.5), "把零件拖到这里", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.40, 0.44, 0.46))
		return

	# 地面
	var ground := world_to_screen(Vector2.ZERO)
	draw_line(Vector2(0.0, ground.y), Vector2(size.x, ground.y), Color(0.851, 0.639, 0.251, 0.55), 2.0)

	var cx := world_to_screen(Vector2.ZERO).x
	var cursor := 0.0
	for item in design.items:
		var id := String(item["id"])
		var def: Dictionary = Parts.get_def(id)
		var w: float = float(def["w"])
		var h: float = float(def["h"])
		var top_left := world_to_screen(Vector2(-w * 0.5, cursor + h))
		var rect := Rect2(top_left, Vector2(w * view_zoom, h * view_zoom))
		var tex := Parts.texture(id)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		cursor += h

	# 轴线
	draw_line(Vector2(cx, 0.0), Vector2(cx, size.y), Color(1, 1, 1, 0.06), 1.0)


func _draw_grid() -> void:
	var step := 1.0
	while step * view_zoom < 26.0:
		step *= 5.0
	var px: float = step * view_zoom
	var origin := world_to_screen(Vector2.ZERO)
	var col := Color(1.0, 1.0, 1.0, 0.028)

	var x: float = fmod(origin.x, px)
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), col, 1.0)
		x += px

	var y: float = fmod(origin.y, px)
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), col, 1.0)
		y += px


func _index_at(screen_y: float) -> int:
	if design == null:
		return 0
	var world_y: float = screen_to_world(Vector2(0.0, screen_y)).y
	var cursor := 0.0
	for i in range(design.items.size()):
		var def: Dictionary = Parts.get_def(String(design.items[i]["id"]))
		var h: float = float(def["h"])
		if world_y < cursor + h * 0.5:
			return i
		cursor += h
	return design.items.size()


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("part") and design != null


func _drop_data(at_position: Vector2, data) -> void:
	design.insert(_index_at(at_position.y), String(data["part"]))
	design_changed.emit()
	queue_redraw()