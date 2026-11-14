extends Control
## 飞行 HUD：遥测、轨道数据、油门与触摸操作。

signal exit_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const MapView := preload("res://scripts/flight/map_view.gd")

var view = null

var _alt: Label
var _spd: Label
var _vs: Label
var _fuel: Label
var _stages: Label
var _apo: Label
var _peri: Label
var _period: Label
var _warp: Label
var _thr_fill: ColorRect
var _status: Label
var _map = null
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
	left.add_theme_constant_override("separation", 3)
	UI.at(left, Vector2(32, 20), Vector2(400, 200))
	add_child(left)

	_alt = UI.label("高度      0.0 km", 17, UI.AMBER_SOFT)
	_spd = UI.label("速度      0.0 m/s", 17, UI.AMBER_SOFT)
	_vs = UI.label("垂直速度  +0.0 m/s", 17, UI.AMBER_SOFT)
	_fuel = UI.label("燃料      100%", 17, UI.AMBER_SOFT)
	_stages = UI.label("剩余级数  1", 17, UI.AMBER_SOFT)
	left.add_child(_alt)
	left.add_child(_spd)
	left.add_child(_vs)
	left.add_child(_fuel)
	left.add_child(_stages)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -420.0
	right.offset_top = 20.0
	right.offset_right = -32.0
	right.offset_bottom = 200.0
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(right)

	var orbit_title := UI.label("轨道要素", 13, UI.STEEL)
	orbit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(orbit_title)

	_apo = UI.label("远地点  ---", 16, UI.PHOSPHOR)
	_apo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_apo)

	_peri = UI.label("近地点  ---", 16, UI.PHOSPHOR)
	_peri.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_peri)

	_period = UI.label("周期    ---", 16, UI.PHOSPHOR)
	_period.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_period)

	_warp = UI.label("时间加速  x1", 16, UI.AMBER)
	_warp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_warp)

	_status = UI.label("", 22, UI.AMBER)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_left = -300.0
	_status.offset_top = 210.0
	_status.offset_right = 300.0
	_status.offset_bottom = 250.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)

	var thr_box := VBoxContainer.new()
	thr_box.add_theme_constant_override("separation", 5)
	thr_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	thr_box.offset_left = 32.0
	thr_box.offset_top = -92.0
	thr_box.offset_right = 360.0
	thr_box.offset_bottom = -26.0
	add_child(thr_box)

	thr_box.add_child(UI.label("油门", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.8)))

	var track := ColorRect.new()
	track.color = Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.14)
	track.custom_minimum_size = Vector2(300, 14)
	track.size = Vector2(300, 14)
	thr_box.add_child(track)

	_thr_fill = ColorRect.new()
	_thr_fill.color = UI.AMBER
	_thr_fill.position = Vector2.ZERO
	_thr_fill.size = Vector2(0, 14)
	track.add_child(_thr_fill)

	var pad := VBoxContainer.new()
	pad.add_theme_constant_override("separation", 8)
	UI.at_bottom_right(pad, Vector2(30, 24), Vector2(582, 96))
	add_child(pad)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.add_child(_tap("分离", _on_separate))
	row1.add_child(_hold("油门 -", "throttle_down"))
	row1.add_child(_hold("油门 +", "throttle_up"))
	row1.add_child(_hold("左转", "yaw_left"))
	row1.add_child(_hold("右转", "yaw_right"))
	pad.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.add_child(_tap("全油门", _on_full))
	row2.add_child(_tap("地图", _on_map))
	row2.add_child(_tap("加速", _on_warp))
	row2.add_child(_tap("选项", _on_options))
	row2.add_child(_tap("返回", _on_back))
	pad.add_child(row2)

	_map = MapView.new()
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.visible = false
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)


func _tap(text: String, cb: Callable) -> Button:
	var b := UI.pad_button(text, 15)
	b.custom_minimum_size = Vector2(110, 44)
	b.pressed.connect(cb)
	return b


func _hold(text: String, action: String) -> Button:
	var b := UI.pad_button(text, 15)
	b.custom_minimum_size = Vector2(110, 44)
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

	_alt.text = "高度      %7.1f km" % (view.altitude() / 1000.0)
	_spd.text = "速度      %7.1f m/s" % view.speed()
	_vs.text = "垂直速度  %+7.1f m/s" % view.radial_speed()

	var fuel_now: float = view.vehicle.current_fuel()
	var fuel_max: float = view.vehicle.current_fuel_max()
	_fuel.text = "燃料      %5.1f %%" % (fuel_now / fuel_max * 100.0)
	_stages.text = "剩余级数  %d" % view.vehicle.stage_count()

	var el: Dictionary = view.orbit_el
	var radius: float = view.planet_radius()
	if el.has("apo") and is_finite(float(el["apo"])):
		_apo.text = "远地点  %6.1f km" % ((float(el["apo"]) - radius) / 1000.0)
	else:
		_apo.text = "远地点  逃逸轨道"

	var peri_r: float = float(el.get("peri", 0.0))
	if peri_r > 0.0:
		var peri_alt: float = (peri_r - radius) / 1000.0
		if peri_alt < 0.0:
			_peri.text = "近地点  撞地"
		else:
			_peri.text = "近地点  %6.1f km" % peri_alt
	else:
		_peri.text = "近地点  ---"

	var period: float = float(el.get("period", 0.0))
	if period > 0.0:
		_period.text = "周期    %5.1f 分" % (period / 60.0)
	else:
		_period.text = "周期    ---"

	_warp.text = "时间加速  %s" % view.warp_text()
	_thr_fill.size = Vector2(300.0 * clampf(view.throttle, 0.0, 1.0), 14.0)

	if view.alive and view.status_text != "":
		_status.text = view.status_text
	else:
		_status.text = ""

	_map.visible = view.map_visible
	_map.queue_redraw()


func _on_separate() -> void:
	view.do_separate()


func _on_full() -> void:
	view.toggle_full_throttle()


func _on_map() -> void:
	view.toggle_map()


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