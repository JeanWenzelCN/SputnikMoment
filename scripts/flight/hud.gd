extends Control
## 飞行 HUD：左侧姿态摇杆、右侧油门滑块、顶部遥测与操作。

signal exit_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const MapView := preload("res://scripts/flight/map_view.gd")
const Stick := preload("res://scripts/ui/virtual_stick.gd")
const ThrottleBar := preload("res://scripts/ui/throttle_slider.gd")

var view = null

var _alt: Label
var _spd: Label
var _vs: Label
var _fuel: Label
var _apo: Label
var _peri: Label
var _objective: Label
var _target: Label
var _status: Label
var _stick = null
var _slider = null
var _map = null
var _sas_btn = null
var _map_buttons: Control
var _panel = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func bind(v) -> void:
	view = v
	if _map != null:
		_map.view = v


func _build() -> void:
	# 左上遥测
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	UI.at(left, Vector2(30, 22), Vector2(300, 140))
	add_child(left)
	_alt = _row(left, "高度", "0.0 km")
	_spd = _row(left, "速度", "0 m/s")
	_vs = _row(left, "垂直", "0 m/s")
	_fuel = _row(left, "燃料", "100%")

	# 右上轨道
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -300.0
	right.offset_top = 22.0
	right.offset_right = -30.0
	right.offset_bottom = 96.0
	add_child(right)
	_apo = _row_right(right, "远地点", "---")
	_peri = _row_right(right, "近地点", "---")

	# 顶部小按钮
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.alignment = BoxContainer.ALIGNMENT_END
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top.offset_left = -280.0
	top.offset_top = 100.0
	top.offset_right = -30.0
	top.offset_bottom = 136.0
	add_child(top)
	top.add_child(_tap("地图", _on_map, 78, 36))
	top.add_child(_tap("缩小", _on_zoom_out, 78, 36))
	top.add_child(_tap("放大", _on_zoom_in, 78, 36))

	# 目标
	_objective = UI.label("", 15, UI.GOLD)
	_objective.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_objective.offset_left = -320.0
	_objective.offset_top = 24.0
	_objective.offset_right = 320.0
	_objective.offset_bottom = 50.0
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_objective)

	# 导航目标
	_target = UI.label("", 13, UI.GREEN)
	UI.at(_target, Vector2(30, 112), Vector2(460, 22))
	add_child(_target)

	# 状态提示
	_status = UI.label("", 19, UI.GOLD)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_left = -300.0
	_status.offset_top = 150.0
	_status.offset_right = 300.0
	_status.offset_bottom = 180.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status)

	# 左下姿态摇杆
	_stick = Stick.new()
	_stick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_stick.offset_left = 24.0
	_stick.offset_top = -276.0
	_stick.offset_right = 264.0
	_stick.offset_bottom = -36.0
	add_child(_stick)
	_stick.vector_changed.connect(_on_stick)

	# 右下油门滑块
	_slider = ThrottleBar.new()
	_slider.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_slider.offset_left = -118.0
	_slider.offset_top = -300.0
	_slider.offset_right = -40.0
	_slider.offset_bottom = -40.0
	add_child(_slider)
	_slider.value_changed.connect(_on_throttle)

	# 分离按钮（底部中间）
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	mid.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	mid.offset_left = -150.0
	mid.offset_top = -78.0
	mid.offset_right = 150.0
	mid.offset_bottom = -28.0
	add_child(mid)

	_sas_btn = UI.pad_button("SAS 关闭", 15)
	_sas_btn.custom_minimum_size = Vector2(146, 50)
	_sas_btn.pressed.connect(_on_sas)
	mid.add_child(_sas_btn)

	var sep := UI.pad_button("分离", 17)
	sep.custom_minimum_size = Vector2(146, 50)
	sep.pressed.connect(_on_separate)
	mid.add_child(sep)

	# 右上角设置/返回/加速
	var top2 := HBoxContainer.new()
	top2.add_theme_constant_override("separation", 6)
	top2.alignment = BoxContainer.ALIGNMENT_END
	top2.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top2.offset_left = -212.0
	top2.offset_top = 142.0
	top2.offset_right = -30.0
	top2.offset_bottom = 176.0
	add_child(top2)
	top2.add_child(_tap("加速", _on_warp, 56, 34))
	top2.add_child(_tap("设置", _on_options, 56, 34))
	top2.add_child(_tap("返回", _on_back, 56, 34))

	_map = MapView.new()
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.visible = false
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.z_index = 10
	add_child(_map)

	_map_buttons = HBoxContainer.new()
	_map_buttons.add_theme_constant_override("separation", 8)
	_map_buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_map_buttons.offset_left = -212.0
	_map_buttons.offset_top = 22.0
	_map_buttons.offset_right = -30.0
	_map_buttons.offset_bottom = 62.0
	_map_buttons.visible = false
	_map_buttons.z_index = 11
	add_child(_map_buttons)

	var full := _tap("全图", _on_full_map, 84, 40)
	_map_buttons.add_child(full)
	var close := _tap("关闭", _on_map, 84, 40)
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
	var b := UI.pad_button(text, 14)
	b.custom_minimum_size = Vector2(w, h)
	b.size = Vector2(w, h)
	b.pressed.connect(cb)
	return b


func _on_stick(v: Vector2) -> void:
	if view != null:
		view.yaw_input = v.x


func _on_throttle(v: float) -> void:
	if view != null:
		view.throttle = v


func _process(_delta: float) -> void:
	if view == null:
		return

	var dom: Dictionary = view.dominant_body()
	var altm: float = view.altitude()
	if altm < 10000.0:
		_alt.text = "%.0f m" % altm
	else:
		_alt.text = "%.1f km" % (altm / 1000.0)
	_spd.text = "%.2f km/s" % (view.speed() / 1000.0)
	_vs.text = "%+.0f m/s" % view.radial_speed()

	var fuel_now: float = view.vehicle.current_fuel()
	var fuel_max: float = view.vehicle.current_fuel_max()
	_fuel.text = "%.0f%%" % (fuel_now / fuel_max * 100.0)

	var el: Dictionary = view.orbit_el
	var radius: float = float(dom["radius"])
	if is_finite(float(el.get("apo", INF))):
		var apo_alt: float = (float(el["apo"]) - radius) / 1000.0
		_apo.text = "%.0f km" % apo_alt if apo_alt < 100000.0 else "%.0f 千km" % (apo_alt / 1000.0)
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
	_slider.set_value(view.throttle)
	_sas_btn.text = view.sas_text()

	if String(view.target_id) == "":
		_target.text = ""
	else:
		var tb: Dictionary = view.get_body(String(view.target_id))
		if tb.is_empty():
			_target.text = ""
		else:
			var line := "导航：%s   %.0f km   %.0f m/s" % [String(tb["name"]), view.target_distance() / 1000.0, view.target_rel_speed()]
			var dv: float = view.transfer_dv()
			if dv > 0.0:
				line += "   转移 Δv %.0f" % dv
			_target.text = line

	_map.visible = view.map_visible
	_map_buttons.visible = view.map_visible
	if view.map_visible:
		_map.queue_redraw()


func _on_separate() -> void:
	view.do_separate()


func _on_sas() -> void:
	view.cycle_sas()


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