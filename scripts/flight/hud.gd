extends Control
## 飞行 HUD：遥测、轨道、目标、缩放与操作。

signal exit_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const MapView := preload("res://scripts/flight/map_view.gd")

var view = null

var _alt: Label
var _spd: Label
var _vs: Label
var _fuel: Label
var _apo: Label
var _peri: Label
var _warp: Label

var _objective: Label
var _thr_fill: ColorRect
var _status: Label
var _map = null
var _map_buttons: Control
var _panel = null
var _held: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func bind(v) -> void:
	view = v
	if _map != null:
		_map.view = v


func _build() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	UI.at(left, Vector2(32, 24), Vector2(300, 150))
	add_child(left)
	_alt = _row(left, "高度", "0.0 km")
	_spd = _row(left, "速度", "0 m/s")
	_vs = _row(left, "垂直", "0 m/s")
	_fuel = _row(left, "燃料", "100%")

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -320.0
	right.offset_top = 24.0
	right.offset_right = -32.0
	right.offset_bottom = 120.0
	add_child(right)
	_apo = _row_right(right, "远地点", "---")
	_peri = _row_right(right, "近地点", "---")

	_objective = UI.label("", 15, UI.GOLD)
	_objective.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_objective.offset_left = -320.0
	_objective.offset_top = 26.0
	_objective.offset_right = 320.0
	_objective.offset_bottom = 52.0
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_objective)

	_status = UI.label("", 20, UI.GOLD)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_left = -300.0
	_status.offset_top = 172.0
	_status.offset_right = 300.0
	_status.offset_bottom = 204.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)

	# 顶部右侧小按钮
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.alignment = BoxContainer.ALIGNMENT_END
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top.offset_left = -300.0
	top.offset_top = 130.0
	top.offset_right = -32.0
	top.offset_bottom = 168.0
	add_child(top)
	top.add_child(_tap("加速", _on_warp, 82, 38))
	top.add_child(_tap("设置", _on_options, 82, 38))
	top.add_child(_tap("返回", _on_back, 82, 38))

	# 左下油门
	var thr := VBoxContainer.new()
	thr.add_theme_constant_override("separation", 6)
	thr.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	thr.offset_left = 32.0
	thr.offset_top = -76.0
	thr.offset_right = 320.0
	thr.offset_bottom = -24.0
	add_child(thr)
	thr.add_child(UI.label("油门", 12, UI.DIM))

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.10)
	track.custom_minimum_size = Vector2(280, 10)
	track.size = Vector2(280, 10)
	thr.add_child(track)

	_thr_fill = ColorRect.new()
	_thr_fill.color = UI.GOLD
	_thr_fill.position = Vector2.ZERO
	_thr_fill.size = Vector2(0, 10)
	track.add_child(_thr_fill)

	# 右下操作网格 3x3
	var pad := VBoxContainer.new()
	pad.add_theme_constant_override("separation", 8)
	UI.at_bottom_right(pad, Vector2(24, 20), Vector2(268, 164))
	add_child(pad)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.add_child(_tap("缩小", _on_zoom_out, 84, 48))
	row1.add_child(_tap("放大", _on_zoom_in, 84, 48))
	row1.add_child(_tap("地图", _on_map, 84, 48))
	pad.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.add_child(_hold("左转", "yaw_left", 84, 48))
	row2.add_child(_hold("右转", "yaw_right", 84, 48))
	row2.add_child(_tap("分离", _on_separate, 84, 48))
	pad.add_child(row2)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	row3.add_child(_hold("推力-", "throttle_down", 84, 48))
	row3.add_child(_hold("推力+", "throttle_up", 84, 48))
	row3.add_child(_tap("全推", _on_full, 84, 48))
	pad.add_child(row3)

	_map = MapView.new()
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.visible = false
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)

	_map_buttons = HBoxContainer.new()
	_map_buttons.add_theme_constant_override("separation", 8)
	_map_buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_map_buttons.offset_left = -220.0
	_map_buttons.offset_top = 24.0
	_map_buttons.offset_right = -32.0
	_map_buttons.offset_bottom = 64.0
	_map_buttons.visible = false
	add_child(_map_buttons)

	var full := _tap("全图", _on_full_map, 84, 40)
	full.add_theme_font_size_override("font_size", 14)
	_map_buttons.add_child(full)

	var close := _tap("关闭", _on_map, 84, 40)
	close.add_theme_font_size_override("font_size", 14)
	_map_buttons.add_child(close)


func _row(parent: Node, key: String, value: String) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var k := UI.label(key, 13, UI.DIM)
	k.custom_minimum_size = Vector2(44, 0)
	var v := UI.label(value, 17, UI.TEXT)
	v.custom_minimum_size = Vector2(150, 0)
	h.add_child(k)
	h.add_child(v)
	parent.add_child(h)
	return v


func _row_right(parent: Node, key: String, value: String) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_END
	var k := UI.label(key, 13, UI.DIM)
	k.custom_minimum_size = Vector2(60, 0)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var v := UI.label(value, 17, UI.TEXT)
	v.custom_minimum_size = Vector2(150, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(k)
	h.add_child(v)
	parent.add_child(h)
	return v


func _tap(text: String, cb: Callable, w: int, h: int) -> Button:
	var b := UI.pad_button(text, 15)
	b.custom_minimum_size = Vector2(w, h)
	b.size = Vector2(w, h)
	b.pressed.connect(cb)
	return b


func _hold(text: String, action: String, w: int, h: int) -> Button:
	var b := UI.pad_button(text, 15)
	b.custom_minimum_size = Vector2(w, h)
	b.size = Vector2(w, h)
	b.button_down.connect(_press.bind(action))
	b.button_up.connect(_release.bind(action))
	return b


func _press(action: String) -> void:
	if not _held.has(action):
		_held.append(action)
	Input.action_press(action)


func _release(action: String) -> void:
	Input.action_release(action)
	_held.erase(action)


func _process(_delta: float) -> void:
	if view == null:
		return

	var dom: Dictionary = view.dominant_body()
	_alt.text = "%.1f km" % (view.altitude() / 1000.0)
	_spd.text = "%.0f m/s" % view.speed()
	_vs.text = "%+.0f m/s" % view.radial_speed()

	var fuel_now: float = view.vehicle.current_fuel()
	var fuel_max: float = view.vehicle.current_fuel_max()
	_fuel.text = "%.0f%%" % (fuel_now / fuel_max * 100.0)

	var el: Dictionary = view.orbit_el
	var radius: float = float(dom["radius"])
	if is_finite(float(el.get("apo", INF))):
		_apo.text = "%.0f km" % ((float(el["apo"]) - radius) / 1000.0)
	else:
		_apo.text = "逃逸"

	var peri_r: float = float(el.get("peri", 0.0))
	if peri_r <= 0.0:
		_peri.text = "---"
	elif peri_r < radius:
		_peri.text = "撞地"
	else:
		_peri.text = "%.0f km" % ((peri_r - radius) / 1000.0)

	_objective.text = "目标  ·  %s" % view.current_objective()
	_status.text = view.status_text if view.alive else "箭体损毁"
	_thr_fill.size = Vector2(280.0 * clampf(view.throttle, 0.0, 1.0), 10.0)

	_map.visible = view.map_visible
	_map_buttons.visible = view.map_visible
	if view.map_visible:
		_map.queue_redraw()


func _on_separate() -> void:
	view.do_separate()


func _on_full() -> void:
	view.toggle_full_throttle()


func _on_map() -> void:
	view.toggle_map()


func _on_full_map() -> void:
	_map.toggle_scale()


func _on_zoom_in() -> void:
	view.zoom_in()


func _on_zoom_out() -> void:
	view.zoom_out()


func _on_warp() -> void:
	view.cycle_warp()


func _on_options() -> void:
	if _panel != null:
		return
	_panel = SettingsPanel.new()
	add_child(_panel)
	_panel.tree_exited.connect(_on_panel_closed)


func _on_panel_closed() -> void:
	_panel = null


func _on_back() -> void:
	exit_requested.emit()


func _exit_tree() -> void:
	for action in _held:
		Input.action_release(action)
	_held.clear()