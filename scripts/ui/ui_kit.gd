extends RefCounted
## 界面基元：克制的工业配色与控件工厂。

const BG := Color(0.043, 0.055, 0.063)
const PANEL := Color(0.075, 0.090, 0.100)
const TEXT := Color(0.910, 0.900, 0.870)
const DIM := Color(0.470, 0.510, 0.535)
const GOLD := Color(0.851, 0.639, 0.251)
const RED := Color(0.760, 0.320, 0.250)
const GREEN := Color(0.560, 0.780, 0.620)

# 兼容旧名
const AMBER := GOLD
const AMBER_SOFT := Color(0.945, 0.870, 0.700)
const STEEL := DIM
const INK := BG
const PHOSPHOR := GREEN
const PAPER := TEXT


static func label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func spaced(text: String) -> String:
	var out := ""
	var n := text.length()
	for i in range(n):
		out += text[i]
		if i < n - 1:
			out += " "
	return out


static func box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func left_box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = width
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.86))
	b.add_theme_color_override("font_pressed_color", BG)
	b.add_theme_color_override("font_disabled_color", Color(0.33, 0.36, 0.37))
	b.add_theme_stylebox_override("normal", box(Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.10), 1))
	b.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.07), GOLD, 1))
	b.add_theme_stylebox_override("pressed", box(GOLD, GOLD, 1))
	b.add_theme_stylebox_override("disabled", box(Color(1, 1, 1, 0.015), Color(1, 1, 1, 0.05), 1))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	return b


static func primary_button(text: String, size: int) -> Button:
	var b := button(text, size)
	b.add_theme_color_override("font_color", Color(0.09, 0.10, 0.10))
	b.add_theme_color_override("font_hover_color", Color(0.09, 0.10, 0.10))
	b.add_theme_color_override("font_pressed_color", Color(0.09, 0.10, 0.10))
	b.add_theme_stylebox_override("normal", box(GOLD, GOLD, 1))
	b.add_theme_stylebox_override("hover", box(Color(1.0, 0.78, 0.38), Color(1.0, 0.78, 0.38), 1))
	b.add_theme_stylebox_override("pressed", box(Color(0.72, 0.54, 0.21), GOLD, 1))
	return b


static func pad_button(text: String, size: int) -> Button:
	var b := button(text, size)
	b.add_theme_stylebox_override("normal", box(PANEL, Color(1, 1, 1, 0.12), 1))
	b.add_theme_stylebox_override("hover", box(Color(0.13, 0.15, 0.16), GOLD, 1))
	b.add_theme_stylebox_override("pressed", box(GOLD, GOLD, 1))
	return b


static func at(node: Control, pos: Vector2, size: Vector2) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = pos
	node.size = size


static func at_bottom_right(node: Control, margin: Vector2, size: Vector2) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	node.offset_left = -size.x - margin.x
	node.offset_top = -size.y - margin.y
	node.offset_right = -margin.x
	node.offset_bottom = -margin.y


static func rule(width: float, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.custom_minimum_size = Vector2(width, 1)
	c.size = Vector2(width, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func panel_rect(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	return sb