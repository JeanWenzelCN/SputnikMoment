extends RefCounted
## 零件表：质量 kg，推力 N，比冲 s，尺寸 m；美术走 SVG。

const DEFS := {
	"pod": {
		"name": "指令舱",
		"dry": 900.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 2.0, "kind": "pod",
		"tex": "res://assets/parts/pod.svg",
	},
	"tank_s": {
		"name": "燃料罐·小",
		"dry": 260.0, "fuel": 1800.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 2.4, "kind": "tank",
		"tex": "res://assets/parts/tank_s.svg",
	},
	"tank_m": {
		"name": "燃料罐·中",
		"dry": 520.0, "fuel": 4200.0, "thrust": 0.0, "isp": 0.0,
		"w": 2.4, "h": 4.0, "kind": "tank",
		"tex": "res://assets/parts/tank_m.svg",
	},
	"tank_l": {
		"name": "燃料罐·大",
		"dry": 980.0, "fuel": 8600.0, "thrust": 0.0, "isp": 0.0,
		"w": 3.2, "h": 6.2, "kind": "tank",
		"tex": "res://assets/parts/tank_l.svg",
	},
	"eng_s": {
		"name": "引擎·小型",
		"dry": 210.0, "fuel": 0.0, "thrust": 62000.0, "isp": 250.0,
		"w": 1.4, "h": 1.4, "kind": "engine",
		"tex": "res://assets/parts/eng_s.svg",
	},
	"eng_m": {
		"name": "引擎·中型",
		"dry": 470.0, "fuel": 0.0, "thrust": 215000.0, "isp": 285.0,
		"w": 2.0, "h": 1.8, "kind": "engine",
		"tex": "res://assets/parts/eng_m.svg",
	},
	"eng_l": {
		"name": "引擎·重型",
		"dry": 1350.0, "fuel": 0.0, "thrust": 690000.0, "isp": 305.0,
		"w": 2.8, "h": 2.4, "kind": "engine",
		"tex": "res://assets/parts/eng_l.svg",
	},
	"sep": {
		"name": "级间分离器",
		"dry": 70.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 0.5, "kind": "sep",
		"tex": "res://assets/parts/sep.svg",
	},
	"chute": {
		"name": "降落伞",
		"dry": 90.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.6, "h": 0.7, "kind": "chute",
		"tex": "res://assets/parts/chute.svg",
	},
	"legs": {
		"name": "着陆支架",
		"dry": 120.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 2.6, "h": 0.8, "kind": "legs",
		"tex": "res://assets/parts/legs.svg",
	},
}

const PALETTE_ORDER := ["pod", "tank_s", "tank_m", "tank_l", "eng_s", "eng_m", "eng_l", "sep", "chute", "legs"]

static var _texture_cache := {}


static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["tank_s"])


static func display_name(id: String) -> String:
	return String(get_def(id)["name"])


static func texture(id: String) -> Texture2D:
	if _texture_cache.has(id):
		return _texture_cache[id]
	var tex = load(String(get_def(id)["tex"]))
	_texture_cache[id] = tex
	return tex