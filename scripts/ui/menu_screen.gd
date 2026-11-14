extends Control
## 主菜单。

signal launch_requested
signal builder_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const Backdrop := preload("res://scripts/ui/globe_backdrop.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")

var _craft: Label
var _panel = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Game.settings_changed.connect(_refresh)
	_build()
	_refresh()


func _build() -> void:
	add_child(Backdrop.new())

	var title := UI.label("卫星时刻", 56, UI.TEXT)
	UI.at(title, Vector2(96, 96), Vector2(600, 70))
	add_child(title)

	var sub := UI.label("SPUTNIK MOMENT", 15, UI.DIM)
	UI.at(sub, Vector2(100, 168), Vector2(400, 24))
	add_child(sub)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	UI.at(menu, Vector2(96, 248), Vector2(300, 300))
	add_child(menu)

	var go := UI.primary_button("开始飞行", 20)
	go.custom_minimum_size = Vector2(300, 54)
	go.pressed.connect(_on_launch)
	menu.add_child(go)

	var build := UI.button("火箭设计", 17)
	build.custom_minimum_size = Vector2(300, 46)
	build.pressed.connect(_on_builder)
	menu.add_child(build)

	var options := UI.button("选项", 17)
	options.custom_minimum_size = Vector2(300, 46)
	options.pressed.connect(_on_options)
	menu.add_child(options)

	var story := UI.button("剧情模式", 17)
	story.custom_minimum_size = Vector2(300, 46)
	story.disabled = true
	menu.add_child(story)

	_craft = UI.label("", 13, UI.DIM)
	UI.at(_craft, Vector2(96, 566), Vector2(520, 24))
	add_child(_craft)

	var version := UI.label("v0.2  ·  自由模式", 12, Color(0.38, 0.41, 0.43))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -260.0
	version.offset_top = -44.0
	version.offset_right = -40.0
	version.offset_bottom = -24.0
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


func _refresh() -> void:
	if _craft == null:
		return
	var d = Game.design
	if d == null or d.size() == 0:
		_craft.text = "当前载具：未设计"
	else:
		_craft.text = "当前载具：%.1f 吨 · %d 级 · Δv %.0f m/s" % [d.total_mass() / 1000.0, d.stage_count(), d.delta_v()]


func _on_launch() -> void:
	launch_requested.emit()


func _on_builder() -> void:
	builder_requested.emit()


func _on_options() -> void:
	if _panel != null:
		return
	_panel = SettingsPanel.new()
	add_child(_panel)
	_panel.tree_exited.connect(_on_panel_closed)


func _on_panel_closed() -> void:
	_panel = null