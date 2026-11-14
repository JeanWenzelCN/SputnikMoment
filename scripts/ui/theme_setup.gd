extends RefCounted
## 全局字体与主题：中文优先走系统 CJK 字体。

static func make_font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Noto Sans CJK SC",
		"Noto Sans SC",
		"Source Han Sans SC",
		"Noto Sans CJK",
		"Droid Sans Fallback",
		"Roboto",
		"sans-serif",
	])
	f.allow_system_fallback = true
	return f


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = make_font()
	th.default_font_size = 16
	return th