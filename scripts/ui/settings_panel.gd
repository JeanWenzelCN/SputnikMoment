extends Control
## Right-hand slide-in panel for cheats and automation assists.

const UI := preload("res://scripts/ui/ui_kit.gd")

var _rows := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_sync()
	modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.16)


func _build() -> void:
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	var panel := Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -620.0
	add_child(panel)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.043, 0.050, 0.053, 0.98)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(bg)

	var edge := ColorRect.new()
	edge.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	edge.offset_right = 2.0
	edge.color = Color(UI.AMBER.r, UI.AMBER.g, UI.AMBER.b, 0.5)
	panel.add_child(edge)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	list.offset_left = 34.0
	list.offset_top = 54.0
	list.offset_right = -34.0
	list.offset_bottom = -96.0
	panel.add_child(list)

	list.add_child(UI.label("选项", 34, UI.AMBER))
	list.add_child(UI.label("作弊回路  /  自动化", 12, UI.STEEL))
	list.add_child(_spacer(14))

	list.add_child(_section("作弊 · 仅自由模式"))
	for key in Game.CHEATS:
		list.add_child(_row(key, String(Game.CHEATS[key]), "cheat"))

	list.add_child(_spacer(12))
	list.add_child(_section("自动化辅助"))
	for key in Game.ASSISTS:
		list.add_child(_row(key, String(Game.ASSISTS[key]), "assist"))

	var close := UI.button("返回", 19)
	close.alignment = HORIZONTAL_ALIGNMENT_LEFT
	close.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	close.offset_left = 34.0
	close.offset_top = -78.0
	close.offset_right = 294.0
	close.offset_bottom = -30.0
	close.pressed.connect(_close)
	panel.add_child(close)


func _section(text: String) -> Label:
	return UI.label(text, 12, Color(UI.STEEL.r, UI.STEEL.g, UI.STEEL.b, 0.8))


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _row(key: String, display: String, kind: String) -> Button:
	var b := UI.button("", 16)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(520, 42)
	b.pressed.connect(_on_toggle.bind(key, kind))
	_rows[key] = {"button": b, "label": display, "kind": kind}
	return b


func _sync() -> void:
	for key in _rows:
		var data: Dictionary = _rows[key]
		var on := false
		if String(data["kind"]) == "cheat":
			on = Game.is_cheat(key)
		else:
			on = Game.is_assist(key)
		var state := "启用" if on else "关闭"
		var button: Button = data["button"]
		button.text = "%s        [ %s ]" % [String(data["label"]), state]


func _on_toggle(key: String, kind: String) -> void:
	if kind == "cheat":
		Game.toggle_cheat(key)
	else:
		Game.toggle_assist(key)
	_sync()


func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.12)
	tw.tween_callback(queue_free)