extends RefCounted
## Shared palette and widget helpers for the cold-war console look.

const AMBER := Color(1.0, 0.702, 0.235)
const AMBER_SOFT := Color(1.0, 0.8, 0.46)
const AMBER_DIM := Color(0.42, 0.3, 0.12)
const PHOSPHOR := Color(0.56, 0.86, 0.68)
const INK := Color(0.031, 0.039, 0.043)
const INK_SOFT := Color(0.063, 0.075, 0.078)
const STEEL := Color(0.56, 0.61, 0.62)
const RED := Color(0.83, 0.26, 0.19)
const PAPER := Color(0.85, 0.82, 0.73)


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
	sb.set_corner_radius_all(0)
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
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 16
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", AMBER)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.72))
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", AMBER_DIM)
	b.add_theme_stylebox_override("normal", left_box(Color(0.0, 0.0, 0.0, 0.0), AMBER_DIM, 2))
	b.add_theme_stylebox_override("hover", left_box(Color(0.9, 0.55, 0.15, 0.14), AMBER, 3))
	b.add_theme_stylebox_override("pressed", left_box(AMBER, AMBER, 3))
	b.add_theme_stylebox_override("disabled", left_box(Color(0.0, 0.0, 0.0, 0.0), Color(0.2, 0.18, 0.14), 2))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	return b


static func pad_button(text: String, size: int) -> Button:
	var b := button(text, size)
	b.add_theme_stylebox_override("normal", box(Color(0.05, 0.06, 0.06, 0.72), AMBER_DIM, 1))
	b.add_theme_stylebox_override("hover", box(Color(0.9, 0.55, 0.15, 0.2), AMBER, 1))
	b.add_theme_stylebox_override("pressed", box(Color(0.9, 0.55, 0.15, 0.55), AMBER, 1))
	b.add_theme_stylebox_override("disabled", box(Color(0.05, 0.06, 0.06, 0.4), Color(0.2, 0.18, 0.14), 1))
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
