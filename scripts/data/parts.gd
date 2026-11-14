extends RefCounted
## 零件表：质量单位 kg，推力单位 N，比冲单位 s，尺寸单位 m。

const DEFS := {
	"pod": {
		"name": "指令舱", "short": "舱",
		"dry": 900.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 2.0, "kind": "pod",
		"color": Color(0.83, 0.84, 0.80),
	},
	"tank_s": {
		"name": "燃料罐·小", "short": "小罐",
		"dry": 260.0, "fuel": 1800.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 2.4, "kind": "tank",
		"color": Color(0.74, 0.76, 0.72),
	},
	"tank_m": {
		"name": "燃料罐·中", "short": "中罐",
		"dry": 520.0, "fuel": 4200.0, "thrust": 0.0, "isp": 0.0,
		"w": 2.4, "h": 4.0, "kind": "tank",
		"color": Color(0.72, 0.74, 0.70),
	},
	"tank_l": {
		"name": "燃料罐·大", "short": "大罐",
		"dry": 980.0, "fuel": 8600.0, "thrust": 0.0, "isp": 0.0,
		"w": 3.2, "h": 6.2, "kind": "tank",
		"color": Color(0.70, 0.72, 0.68),
	},
	"eng_s": {
		"name": "引擎·小型", "short": "小引擎",
		"dry": 210.0, "fuel": 0.0, "thrust": 62000.0, "isp": 250.0,
		"w": 1.4, "h": 1.4, "kind": "engine",
		"color": Color(0.55, 0.57, 0.56),
	},
	"eng_m": {
		"name": "引擎·中型", "short": "中引擎",
		"dry": 470.0, "fuel": 0.0, "thrust": 215000.0, "isp": 285.0,
		"w": 2.0, "h": 1.8, "kind": "engine",
		"color": Color(0.52, 0.54, 0.53),
	},
	"eng_l": {
		"name": "引擎·重型", "short": "重引擎",
		"dry": 1350.0, "fuel": 0.0, "thrust": 690000.0, "isp": 305.0,
		"w": 2.8, "h": 2.4, "kind": "engine",
		"color": Color(0.49, 0.51, 0.50),
	},
	"sep": {
		"name": "级间分离器", "short": "分离器",
		"dry": 70.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.8, "h": 0.5, "kind": "sep",
		"color": Color(0.86, 0.55, 0.16),
	},
	"chute": {
		"name": "降落伞", "short": "伞",
		"dry": 90.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 1.6, "h": 0.7, "kind": "chute",
		"color": Color(0.78, 0.30, 0.24),
	},
	"legs": {
		"name": "着陆支架", "short": "支架",
		"dry": 120.0, "fuel": 0.0, "thrust": 0.0, "isp": 0.0,
		"w": 2.6, "h": 0.8, "kind": "legs",
		"color": Color(0.46, 0.48, 0.47),
	},
}

const PALETTE_ORDER := ["pod", "tank_s", "tank_m", "tank_l", "eng_s", "eng_m", "eng_l", "sep", "chute", "legs"]


static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["tank_s"])


static func display_name(id: String) -> String:
	return String(get_def(id)["name"])
