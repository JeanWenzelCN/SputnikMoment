extends Control
## 主菜单。

signal launch_requested
signal builder_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const Globe := preload("res://scripts/ui/globe_backdrop.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")

var _cheat_row: Label
var _assist_row: Label
var _craft_row: Label
var _panel: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Game.settings_changed.connect(_refresh_status)
	_build()
	_refresh_status()


func _build() -> void:
	add_child(Globe.new())

	var top_rule := ColorRect.new()
	top_rule.color = Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.22)
	UI.at(top_rule, Vector2(88, 56), Vector2(1104, 1))
	add_child(top_rule)

	var corner := UI.label("第十二设计局  /  飞行力学组", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.7))
	UI.at(corner, Vector2(88, 30), Vector2(680, 20))
	add_child(corner)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	UI.at(header, Vector2(88, 90), Vector2(780, 210))
	add_child(header)
	header.add_child(UI.label("卫星时刻", 72, UI.AMBER))
	header.add_child(UI.label("S P U T N I K   M O M E N T", 22, UI.AMBER_SOFT))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	header.add_child(gap)
	header.add_child(UI.rule(430, Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.4)))

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	header.add_child(gap2)
	header.add_child(UI.label("轨道飞行计划  ·  附件 1967", 13, UI.STEEL))

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	UI.at(menu, Vector2(88, 330), Vector2(470, 260))
	add_child(menu)
	menu.add_child(_item(1, "发射任务", true, _on_launch))
	menu.add_child(_item(2, "火箭设计台", true, _on_builder))
	menu.add_child(_item(3, "选项", true, _on_options))
	menu.add_child(_item(4, "剧情模式", false, Callable()))

	var status := VBoxContainer.new()
	status.add_theme_constant_override("separation", 5)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -470.0
	status.offset_top = 120.0
	status.offset_right = -88.0
	status.offset_bottom = 320.0
	add_child(status)

	status.add_child(UI.label("当前载具", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.75)))
	status.add_child(UI.rule(300, Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.25)))

	_craft_row = UI.label("", 14, UI.AMBER_SOFT)
	status.add_child(_craft_row)
	_cheat_row = UI.label("", 14, UI.AMBER_SOFT)
	status.add_child(_cheat_row)
	_assist_row = UI.label("", 14, UI.AMBER_SOFT)
	status.add_child(_assist_row)

	status.add_child(UI.label("剧情模式暂未开放", 12, Color(UI.RED.r, UI.RED.g, UI.RED.b, 0.75)))

	var footer := UI.label("自由模式  ·  Godot 4  ·  自动构建", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.55))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 88.0
	footer.offset_top = -52.0
	footer.offset_right = 900.0
	footer.offset_bottom = -28.0
	add_child(footer)


func _item(idx: int, title: String, enabled: bool, cb: Callable) -> Button:
	var b := UI.button("%02d   %s" % [idx, title], 21)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(470, 46)
	b.disabled = not enabled
	if enabled:
		b.pressed.connect(cb)
	else:
		b.text = "%02d   %s    [ 封闭 ]" % [idx, title]
	return b


func _refresh_status() -> void:
	var d = Game.design
	if _craft_row != null:
		if d == null or d.size() == 0:
			_craft_row.text = "载具    未设计"
		else:
			_craft_row.text = "载具    %.1f t · %d 级 · Δv %.0f" % [d.total_mass() / 1000.0, d.stage_count(), d.delta_v()]
	if _cheat_row != null:
		_cheat_row.text = "作弊    %s" % ("无" if Game.active_cheats() == 0 else "%d 项启用" % Game.active_cheats())
	if _assist_row != null:
		_assist_row.text = "辅助    %d 项启用" % Game.active_assists()


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