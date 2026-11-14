extends Control
## 设计台：选零件堆叠成火箭，实时算质量、推重比与 Δv。

signal launch_requested
signal back_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const Parts := preload("res://scripts/data/parts.gd")
const Preview := preload("res://scripts/ui/build_preview.gd")
const Globe := preload("res://scripts/ui/globe_backdrop.gd")

var design = null
var _preview = null
var _stats: Label
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	design = Game.design
	_build()
	_refresh()


func _build() -> void:
	add_child(Globe.new())

	var title := UI.label("火箭设计台", 34, UI.AMBER)
	UI.at(title, Vector2(56, 34), Vector2(400, 44))
	add_child(title)

	var sub := UI.label("自下而上堆叠零件 · 级间放置分离器", 13, UI.STEEL)
	UI.at(sub, Vector2(56, 78), Vector2(500, 22))
	add_child(sub)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	UI.at(left, Vector2(56, 118), Vector2(300, 470))
	add_child(left)

	left.add_child(UI.label("零件库", 13, UI.STEEL))
	for id in Parts.PALETTE_ORDER:
		var def: Dictionary = Parts.get_def(String(id))
		var b := UI.pad_button("%s    %.0f t" % [String(def["name"]), float(def["dry"]) / 1000.0], 15)
		b.custom_minimum_size = Vector2(300, 38)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_add.bind(String(id)))
		left.add_child(b)

	_preview = Preview.new()
	UI.at(_preview, Vector2(384, 118), Vector2(500, 470))
	add_child(_preview)
	_preview.design = design

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	UI.at(right, Vector2(912, 118), Vector2(312, 470))
	add_child(right)

	right.add_child(UI.label("性能估算", 13, UI.STEEL))
	_stats = UI.label("", 15, UI.AMBER_SOFT)
	_stats.custom_minimum_size = Vector2(312, 220)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_stats)

	_hint = UI.label("", 12, UI.STEEL)
	_hint.custom_minimum_size = Vector2(312, 120)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_hint)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.offset_left = -700.0
	bar.offset_top = -76.0
	bar.offset_right = -56.0
	bar.offset_bottom = -26.0
	add_child(bar)

	var undo := UI.pad_button("撤销一步", 16)
	undo.custom_minimum_size = Vector2(140, 44)
	undo.pressed.connect(_on_undo)
	bar.add_child(undo)

	var clear := UI.pad_button("清空", 16)
	clear.custom_minimum_size = Vector2(100, 44)
	clear.pressed.connect(_on_clear)
	bar.add_child(clear)

	var preset := UI.pad_button("参考设计", 16)
	preset.custom_minimum_size = Vector2(130, 44)
	preset.pressed.connect(_on_preset)
	bar.add_child(preset)

	var back := UI.pad_button("返回", 16)
	back.custom_minimum_size = Vector2(100, 44)
	back.pressed.connect(_on_back)
	bar.add_child(back)

	var go := UI.pad_button("发射", 18)
	go.custom_minimum_size = Vector2(150, 44)
	go.pressed.connect(_on_launch)
	bar.add_child(go)


func _on_add(id: String) -> void:
	design.add(id)
	_refresh()


func _on_undo() -> void:
	design.remove_last()
	_refresh()


func _on_clear() -> void:
	design.clear()
	_refresh()


func _on_preset() -> void:
	design.default_design()
	_refresh()


func _on_back() -> void:
	Game.save_design()
	back_requested.emit()


func _on_launch() -> void:
	if design.size() == 0:
		return
	Game.save_design()
	launch_requested.emit()


func _refresh() -> void:
	if _preview != null:
		_preview.queue_redraw()

	var mass_t: float = design.total_mass() / 1000.0
	var dry_t: float = design.dry_mass() / 1000.0
	var tw: float = design.pad_thrust_to_weight()
	var dv: float = design.delta_v()
	var stages: int = design.stage_count()

	_stats.text = "总质量    %.2f t\n干重      %.2f t\n高度      %.1f m\n级数      %d\n起飞推重比 %.2f\nΔv 估算   %.0f m/s" % [
		mass_t, dry_t, design.height(), stages, tw, dv
	]

	var lines: Array = []
	if tw < 1.0:
		lines.append("推重比不足 1，无法离地。")
	if dv < 2400.0:
		lines.append("Δv 低于入轨所需的约 2400 m/s。")
	if stages < 2:
		lines.append("单级火箭难以入轨，试试加入级间分离器。")
	if design.size() > 0 and String(design.items[design.size() - 1]["id"]) != "pod":
		lines.append("顶端还没有指令舱。")
	if lines.is_empty():
		lines.append("结构看起来可行，可以发射。")
	var text := ""
	for i in range(lines.size()):
		if i > 0:
			text += "\n"
		text += str(lines[i])
	_hint.text = text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_on_back()