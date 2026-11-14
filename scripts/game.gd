extends Node
## Global session state: cheat toggles, assists, persistence.

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

const CHEATS := {
	"infinite_fuel": "INFINITE PROPELLANT",
	"zero_g": "NULL GRAVITY",
	"overdrive": "OVERDRIVE THRUST",
	"hull": "HULL INTEGRITY",
}

const ASSISTS := {
	"gyro": "GYRO STABILIZER",
	"telemetry": "LANDING TELEMETRY",
	"predictor": "TRAJECTORY PLOT",
}

var cheats := {}
var assists := {}


func _ready() -> void:
	for key in CHEATS:
		cheats[key] = false
	for key in ASSISTS:
		assists[key] = true
	load_settings()


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