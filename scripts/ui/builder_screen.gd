extends Control
## 设计台：左侧零件栏拖到中间装配，右侧实时给出质量、推重比与 Δv。

signal launch_requested
signal back_requested

const UI := preload("res://scripts/ui/ui_kit.gd")
const Parts := preload("res://scripts/data/parts.gd")
const Preview := preload("res://scripts/ui/build_preview.gd")
const PartIcon := preload("res://scripts/ui/part_icon.gd")
const Backdrop := preload("res://scripts/ui/globe_backdrop.gd")

var design = null
var _preview = null
var _mass: Label
var _twr: Label
var _dv: Label
var _warn: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	design = Game.design
	_build()
	_refresh()


func _build() -> void:
	add_child(Backdrop.new())

	var title := UI.label("火箭设计", 28, UI.TEXT)
	UI.at(title, Vector2(48, 30), Vector2(300, 36))
	add_child(title)

	var hint := UI.label("拖动左侧零件到装配区", 12, UI.DIM)
	UI.at(hint, Vector2(48, 66), Vector2(300, 20))
	add_child(hint)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	UI.at(list, Vector2(48, 96), Vector2(300, 470))
	add_child(list)

	for id in Parts.PALETTE_ORDER:
		var icon := PartIcon.new()
		icon.setup(String(id))
		list.add_child(icon)

	_preview = Preview.new()
	UI.at(_preview, Vector2(376, 96), Vector2(520, 470))
	add_child(_preview)
	_preview.design = design
	_preview.design_changed.connect(_refresh)
	_preview.recenter()

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 16)
	UI.at(stats, Vector2(920, 104), Vector2(300, 300))
	add_child(stats)

	var block_mass := _stat_block("总质量", "0.0 吨")
	stats.add_child(block_mass[0])
	_mass = block_mass[1]

	var block_twr := _stat_block("推重比", "0.00")
	stats.add_child(block_twr[0])
	_twr = block_twr[1]

	var block_dv := _stat_block("Δv", "0 m/s")
	stats.add_child(block_dv[0])
	_dv = block_dv[1]

	_warn = UI.label("", 13, UI.RED)
	_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.at(_warn, Vector2(920, 424), Vector2(300, 90))
	add_child(_warn)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.offset_left = -640.0
	bar.offset_top = -72.0
	bar.offset_right = -48.0
	bar.offset_bottom = -26.0
	add_child(bar)

	var undo := UI.pad_button("撤销", 16)
	undo.custom_minimum_size = Vector2(88, 44)
	undo.pressed.connect(_on_undo)
	bar.add_child(undo)

	var clear := UI.pad_button("清空", 16)
	clear.custom_minimum_size = Vector2(88, 44)
	clear.pressed.connect(_on_clear)
	bar.add_child(clear)

	var zoom_in := UI.pad_button("放大", 16)
	zoom_in.custom_minimum_size = Vector2(88, 44)
	zoom_in.pressed.connect(_on_zoom_in)
	bar.add_child(zoom_in)

	var zoom_out := UI.pad_button("缩小", 16)
	zoom_out.custom_minimum_size = Vector2(88, 44)
	zoom_out.pressed.connect(_on_zoom_out)
	bar.add_child(zoom_out)

	var fit := UI.pad_button("居中", 16)
	fit.custom_minimum_size = Vector2(88, 44)
	fit.pressed.connect(_on_fit)
	bar.add_child(fit)

	var back := UI.pad_button("返回", 16)
	back.custom_minimum_size = Vector2(88, 44)
	back.pressed.connect(_on_back)
	bar.add_child(back)

	var go := UI.primary_button("发射", 18)
	go.custom_minimum_size = Vector2(140, 44)
	go.pressed.connect(_on_launch)
	bar.add_child(go)


func _stat_block(key: String, value: String) -> Array:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(UI.label(key, 12, UI.DIM))
	var value_label := UI.label(value, 28, UI.TEXT)
	v.add_child(value_label)
	return [v, value_label]


func _on_undo() -> void:
	design.remove_last()
	_refresh()


func _on_zoom_in() -> void:
	_preview.zoom_by(1.25)


func _on_zoom_out() -> void:
	_preview.zoom_by(0.8)


func _on_fit() -> void:
	_preview.recenter()


func _on_clear() -> void:
	design.clear()
	_refresh()


func _on_sample() -> void:
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
	if _mass == null:
		return

	_mass.text = "%.1f 吨" % (design.total_mass() / 1000.0)
	_twr.text = "%.2f" % design.pad_thrust_to_weight()
	_dv.text = "%.0f m/s" % design.delta_v()

	var problem := ""
	if design.size() == 0:
		problem = "还没有零件"
	elif String(design.items[design.size() - 1]["id"]) != "pod":
		problem = "顶部缺少指令舱"
	elif design.pad_thrust_to_weight() < 1.0:
		problem = "推重比不足 1，无法离地"
	elif design.stage_count() < 2:
		problem = "单级难以入轨，加个分离器"
	_warn.text = problem


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_on_back()