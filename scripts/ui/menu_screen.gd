extends Control
## Title screen. Cold-war mission-control console, freedom mode only for now.

signal start_flight

const UI := preload("res://scripts/ui/ui_kit.gd")
const Globe := preload("res://scripts/ui/globe_backdrop.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")

var _cheat_row: Label
var _assist_row: Label
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

	var corner := UI.label("BUREAU 12  /  FLIGHT DYNAMICS SECTION", 11, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.65))
	UI.at(corner, Vector2(88, 30), Vector2(680, 20))
	add_child(corner)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	UI.at(header, Vector2(88, 92), Vector2(780, 210))
	add_child(header)
	header.add_child(UI.label("SPUTNIK", 78, UI.AMBER))
	header.add_child(UI.label(UI.spaced("MOMENT"), 28, UI.AMBER_SOFT))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	header.add_child(gap)
	header.add_child(UI.rule(430, Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.4)))

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	header.add_child(gap2)
	header.add_child(UI.label("ORBITAL FLIGHT PROGRAM  ·  ANNEX 1967", 13, UI.STEEL))

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	UI.at(menu, Vector2(88, 330), Vector2(470, 260))
	add_child(menu)
	menu.add_child(_item(1, "FREEDOM FLIGHT", true, _on_start))
	menu.add_child(_item(2, "STORY ARCHIVE", false, Callable()))
	menu.add_child(_item(3, "OPTIONS", true, _on_options))

	var status := VBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -470.0
	status.offset_top = 120.0
	status.offset_right = -88.0
	status.offset_bottom = 300.0
	add_child(status)

	status.add_child(UI.label(UI.spaced("SESSION TELEMETRY"), 11, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.7)))
	status.add_child(UI.rule(300, Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.25)))

	_cheat_row = UI.label("", 14, UI.AMBER_SOFT)
	status.add_child(_cheat_row)
	_assist_row = UI.label("", 14, UI.AMBER_SOFT)
	status.add_child(_assist_row)

	var note := UI.label("STORY ARCHIVE REMAINS SEALED", 12, Color(UI.RED.r, UI.RED.g, UI.RED.b, 0.75))
	status.add_child(note)

	var footer := UI.label("BUILD 0.1.0-TEST   ·   FREEDOM MODE ONLY   ·   GODOT", 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.55))
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
		b.text = "%02d   %s    [ SEALED ]" % [idx, title]
	return b


func _refresh_status() -> void:
	if _cheat_row != null:
		_cheat_row.text = "CHEAT CIRCUIT   %s" % _state_word(Game.active_cheats())
	if _assist_row != null:
		_assist_row.text = "AUTOMATION      %s" % _state_word(Game.active_assists())


func _state_word(n: int) -> String:
	if n == 0:
		return "NOMINAL / OFF"
	return "%d ENGAGED" % n


func _on_start() -> void:
	start_flight.emit()


func _on_options() -> void:
	if _panel != null:
		return
	_panel = SettingsPanel.new()
	add_child(_panel)
	_panel.tree_exited.connect(_on_panel_closed)


func _on_panel_closed() -> void:
	_panel = null