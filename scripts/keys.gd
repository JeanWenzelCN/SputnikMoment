extends Node
## 运行时注册输入动作，键盘与触屏按钮共用同一套动作。

const ACTIONS := {
	"throttle_up": [KEY_W, KEY_UP],
	"throttle_down": [KEY_S, KEY_DOWN],
	"yaw_left": [KEY_A, KEY_LEFT],
	"yaw_right": [KEY_D, KEY_RIGHT],
	"stage": [KEY_SPACE],
	"warp": [KEY_T],
	"map": [KEY_M],
	"back": [KEY_ESCAPE],
}


func _ready() -> void:
	for action_name in ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for keycode in ACTIONS[action_name]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)