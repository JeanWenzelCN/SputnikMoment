extends Node
## 全局状态：作弊/辅助开关、当前火箭设计、存档。

signal settings_changed

const Design := preload("res://scripts/data/design.gd")

const SAVE_PATH := "user://settings.cfg"
const DESIGN_PATH := "user://design.json"

const CHEATS := {
	"infinite_fuel": "无限燃料",
	"zero_g": "零重力",
	"overdrive": "超载推力",
	"hull": "机体加固",
}

const ASSISTS := {
	"gyro": "陀螺自稳",
	"telemetry": "着陆遥测",
	"predictor": "弹道预测",
}

var cheats := {}
var assists := {}
var design = null


func _ready() -> void:
	for key in CHEATS:
		cheats[key] = false
	for key in ASSISTS:
		assists[key] = true
	design = Design.new()
	design.default_design()
	load_settings()
	load_design()


func is_cheat(key: String) -> bool:
	return bool(cheats.get(key, false))


func is_assist(key: String) -> bool:
	return bool(assists.get(key, true))


func toggle_cheat(key: String) -> void:
	if not cheats.has(key):
		return
	cheats[key] = not bool(cheats[key])
	save_settings()
	settings_changed.emit()


func toggle_assist(key: String) -> void:
	if not assists.has(key):
		return
	assists[key] = not bool(assists[key])
	save_settings()
	settings_changed.emit()


func active_cheats() -> int:
	var n := 0
	for key in cheats:
		if bool(cheats[key]):
			n += 1
	return n


func active_assists() -> int:
	var n := 0
	for key in assists:
		if bool(assists[key]):
			n += 1
	return n


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in cheats:
		cfg.set_value("cheats", key, cheats[key])
	for key in assists:
		cfg.set_value("assists", key, assists[key])
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in cheats:
		if cfg.has_section_key("cheats", key):
			cheats[key] = cfg.get_value("cheats", key)
	for key in assists:
		if cfg.has_section_key("assists", key):
			assists[key] = cfg.get_value("assists", key)


func save_design() -> void:
	if design == null:
		return
	var f := FileAccess.open(DESIGN_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(design.to_dict()))
	f.close()


func load_design() -> void:
	if not FileAccess.file_exists(DESIGN_PATH):
		return
	var f := FileAccess.open(DESIGN_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var loaded = Design.new()
	loaded.from_dict(data)
	if loaded.size() > 0:
		design = loaded