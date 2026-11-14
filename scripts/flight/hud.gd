extends Control
## Flight telemetry console: instruments, touch controls, loss-of-vehicle banner.

signal exit_requested
signal restart_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")

var view = null

var _alt_value: Label
var _vel_value: Label
var _prop_value: Label
var _clock_value: Label
var _thr_fill: ColorRect
var _status: Label
var _banner: Control
var _held: Array = []
var _panel: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func bind(v: Node) -> void:
	view = v


func _build() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 9)
	UI.at(left, Vector2(38, 22), Vector2(340, 240))
	add_child(left)
	_alt_value = _block(left, "ALTITUDE", "0.000 KM")
	_vel_value = _block(left, "VELOCITY", "0.0 M/S")
	_prop_value = _block(left, "PROPELLANT", "100.0 %")
	_clock_value = _block(left, "T+ ELAPSED", "00:00.0")

	_status = UI.label("", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.92))
	_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_status.offset_left = -460.0
	_status.offset_top = 22.0
	_status.offset_right = -38.0
	_status.offset_bottom = 120.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_status)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_row.offset_left = -330.0
	top_row.offset_top = 92.0
	top_row.offset_right = -38.0
	top_row.offset_bottom = 130.0
	add_child(top_row)

	var opt_btn := UI.pad_button("OPTIONS", 14)
	opt_btn.custom_minimum_size = Vector2(130, 38)
	opt_btn.pressed.connect(_open_options)
	top_row.add_child(opt_btn)

	var back_btn := UI.pad_button("CONSOLE", 14)
	back_btn.custom_minimum_size = Vector2(130, 38)
	back_btn.pressed.connect(_on_back)
	top_row.add_child(back_btn)

	var thr_box := VBoxContainer.new()
	thr_box.add_theme_constant_override("separation", 5)
	thr_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	thr_box.offset_left = 38.0
	thr_box.offset_top = -96.0
	thr_box.offset_right = 380.0
	thr_box.offset_bottom = -26.0
	add_child(thr_box)
	thr_box.add_child(UI.label(UI.spaced("THROTTLE"), 11, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.8)))

	var track := ColorRect.new()
	track.color = Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.14)
	track.custom_minimum_size = Vector2(300, 12)
	track.size = Vector2(300, 12)
	thr_box.add_child(track)

	_thr_fill = ColorRect.new()
	_thr_fill.color = UI.AMBER
	_thr_fill.position = Vector2.ZERO
	_thr_fill.size = Vector2(0, 12)
	track.add_child(_thr_fill)

	var pad := VBoxContainer.new()
	pad.add_theme_constant_override("separation", 8)
	UI.at_bottom_right(pad, Vector2(34, 26), Vector2(420, 152))
	add_child(pad)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.add_child(_hold_button("YAW  L", "yaw_left"))
	row1.add_child(_hold_button("YAW  R", "yaw_right"))
	pad.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.add_child(_hold_button("THR  -", "throttle_down"))
	row2.add_child(_hold_button("THR  +", "throttle_up"))
	pad.add_child(row2)

	_build_banner()


func _build_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.add_theme_constant_override("separation", 10)
	_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.offset_left = -320.0
	_banner.offset_top = -80.0
	_banner.offset_right = 320.0
	_banner.offset_bottom = 80.0
	add_child(_banner)

	var head := UI.label("VEHICLE LOST", 40, UI.RED)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(head)

	var sub := UI.label("IMPACT VELOCITY EXCEEDED STRUCTURAL LIMIT", 12, UI.STEEL)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(sub)

	var rebuild := UI.button("REBUILD TEST ARTICLE", 17)
	rebuild.custom_minimum_size = Vector2(320, 48)
	rebuild.pressed.connect(_on_rebuild)
	_banner.add_child(rebuild)

	_banner.visible = false


func _block(parent: Node, key: String, value: String) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(UI.label(UI.spaced(key), 10, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.75)))
	var value_label := UI.label(value, 25, UI.AMBER_SOFT)
	value_label.custom_minimum_size = Vector2(300, 0)
	box.add_child(value_label)
	parent.add_child(box)
	return value_label


func _hold_button(text: String, action: String) -> Button:
	var b := UI.pad_button(text, 18)
	b.custom_minimum_size = Vector2(200, 70)
	b.button_down.connect(_press_action.bind(action))
	b.button_up.connect(_release_action.bind(action))
	return b


func _press_action(action: String) -> void:
	if not _held.has(action):
		_held.append(action)
	Input.action_press(action)


func _release_action(action: String) -> void:
	Input.action_release(action)
	_held.erase(action)


func _process(_delta: float) -> void:
	if view == null:
		return

	_alt_value.text = "%8.3f KM" % (view.altitude() / 1000.0)
	_vel_value.text = "%8.1f M/S" % view.speed()
	_prop_value.text = "%8.1f %%" % (view.fuel_fraction() * 100.0)
	_clock_value.text = _stamp(view.elapsed)
	_thr_fill.size = Vector2(300.0 * clampf(view.throttle, 0.0, 1.0), 12.0)
	_status.text = _status_text()
	_banner.visible = not view.alive


func _stamp(t: float) -> String:
	var total := int(t)
	var mm := total / 60
	var ss := total % 60
	var tenths := int((t - float(total)) * 10.0)
	return "%02d:%02d.%d" % [mm, ss, tenths]


func _status_text() -> String:
	var parts: Array = []
	if Game.is_assist("gyro"):
		parts.append("GYRO")
	if Game.is_assist("telemetry"):
		parts.append("TELEM")
	if Game.is_assist("predictor"):
		parts.append("PLOT")

	var assist_line := "AUTO: NONE"
	if parts.size() > 0:
		assist_line = "AUTO: "
		for i in range(parts.size()):
			if i > 0:
				assist_line += ", "
			assist_line += str(parts[i])

	var cheat_line := "CHEATS: NONE"
	if Game.active_cheats() > 0:
		cheat_line = "CHEATS: %d ENGAGED" % Game.active_cheats()

	var text := "%s\n%s" % [assist_line, cheat_line]
	if Game.is_assist("telemetry") and view.alive:
		text += "\nIMPACT EST: %5.1f M/S" % view.impact_estimate()
	return text


func _open_options() -> void:
	if _panel != null:
		return
	_panel = SettingsPanel.new()
	add_child(_panel)
	_panel.tree_exited.connect(_on_panel_closed)


func _on_panel_closed() -> void:
	_panel = null


func _on_back() -> void:
	exit_requested.emit()


func _on_rebuild() -> void:
	restart_requested.emit()


func _exit_tree() -> void:
	for action in _held:
		Input.action_release(action)
	_held.clear()