extends Control
## Full-screen CRT treatment: scanlines, vignette and film grain.

const CRT_MASK := preload("res://shaders/crt_mask.gdshader")
const CRT_GRAIN := preload("res://shaders/crt_grain.gdshader")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mask := ColorRect.new()
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.color = Color(1, 1, 1, 1)
	var mask_mat := ShaderMaterial.new()
	mask_mat.shader = CRT_MASK
	mask.material = mask_mat
	add_child(mask)

	var grain := ColorRect.new()
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.color = Color(1, 1, 1, 1)
	var grain_mat := ShaderMaterial.new()
	grain_mat.shader = CRT_GRAIN
	grain.material = grain_mat
	add_child(grain)