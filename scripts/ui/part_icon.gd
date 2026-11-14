extends Control
## 零件栏条目，可直接拖到装配区。

const UI := preload("res://scripts/ui/ui_kit.gd")
const Parts := preload("res://scripts/data/parts.gd")

var part_id := ""
var _hover := false
var _accent := false


func setup(id: String, accent: bool = false) -> void:
	part_id = id
	_accent = accent
	custom_minimum_size = Vector2(300, 44)
	size = Vector2(300, 44)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "拖到右侧装配区"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	resized.connect(queue_redraw)


func _on_enter() -> void:
	_hover = true
	queue_redraw()


func _on_exit() -> void:
	_hover = false
	queue_redraw()


func _draw() -> void:
	var bg := Color(1, 1, 1, 0.035)
	if _hover:
		bg = Color(0.851, 0.639, 0.251, 0.12)
	draw_rect(Rect2(Vector2.ZERO, size), bg, true)
	draw_rect(Rect2(Vector2.ZERO, size), UI.GOLD if _hover else Color(1, 1, 1, 0.09), false, 1.0)

	var tex := Parts.texture(part_id)
	if tex != null:
		var ts := tex.get_size()
		var box := Rect2(9.0, 4.0, 38.0, size.y - 8.0)
		var k: float = minf(box.size.x / maxf(ts.x, 1.0), box.size.y / maxf(ts.y, 1.0))
		var dw: float = ts.x * k
		var dh: float = ts.y * k
		var dst := Rect2(box.position.x + (box.size.x - dw) * 0.5, box.position.y + (box.size.y - dh) * 0.5, dw, dh)
		draw_texture_rect(tex, dst, false)

	var def: Dictionary = Parts.get_def(part_id)
	var font := get_theme_default_font()
	var name_color: Color = UI.TEXT if not _accent else UI.GOLD
	draw_string(font, Vector2(58, size.y * 0.5 - 1.0), String(def["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, name_color)
	var mass_text := "%.1f 吨" % (float(def["dry"]) / 1000.0)
	if float(def["fuel"]) > 0.0:
		mass_text += "  ·  燃料 %.1f 吨" % (float(def["fuel"]) / 1000.0)
	draw_string(font, Vector2(58, size.y * 0.5 + 13.0), mass_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UI.DIM)


func _get_drag_data(_at_position: Vector2):
	var tex := Parts.texture(part_id)
	if tex != null:
		var preview := TextureRect.new()
		preview.texture = tex
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.size = Vector2(80, 80)
		preview.modulate = Color(1, 1, 1, 0.85)
		set_drag_preview(preview)
	return {"part": part_id}