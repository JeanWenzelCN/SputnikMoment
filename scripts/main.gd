extends Node
## 根节点：画布分层、中文字体主题、场景路由。

const MenuScreen := preload("res://scripts/ui/menu_screen.gd")
const BuilderScreen := preload("res://scripts/ui/builder_screen.gd")
const FlightView := preload("res://scripts/flight/flight_view.gd")
const CrtOverlay := preload("res://scripts/ui/crt_overlay.gd")
const ThemeSetup := preload("res://scripts/ui/theme_setup.gd")

var world_layer: CanvasLayer
var ui_layer: CanvasLayer
var crt_layer: CanvasLayer


func _ready() -> void:
	Engine.max_fps = 60
	get_tree().root.theme = ThemeSetup.make_theme()

	world_layer = CanvasLayer.new()
	world_layer.layer = 0
	add_child(world_layer)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	add_child(ui_layer)

	crt_layer = CanvasLayer.new()
	crt_layer.layer = 120
	add_child(crt_layer)
	crt_layer.add_child(CrtOverlay.new())

	var args := OS.get_cmdline_user_args()
	if args.has("--flight"):
		show_flight()
	elif args.has("--builder"):
		show_builder()
	else:
		show_menu()


func clear_layer(layer: CanvasLayer) -> void:
	for child in layer.get_children():
		child.queue_free()


func show_menu() -> void:
	clear_layer(world_layer)
	clear_layer(ui_layer)
	var menu := MenuScreen.new()
	menu.launch_requested.connect(show_flight)
	menu.builder_requested.connect(show_builder)
	ui_layer.add_child(menu)


func show_builder() -> void:
	clear_layer(world_layer)
	clear_layer(ui_layer)
	var builder := BuilderScreen.new()
	builder.launch_requested.connect(show_flight)
	builder.back_requested.connect(show_menu)
	ui_layer.add_child(builder)


func show_flight() -> void:
	clear_layer(world_layer)
	clear_layer(ui_layer)
	var view := FlightView.new()
	view.exit_requested.connect(show_menu)
	world_layer.add_child(view)