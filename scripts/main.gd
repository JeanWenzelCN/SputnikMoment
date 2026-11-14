extends Node
## Root shell: owns the canvas layers and swaps between menu and flight.

const MenuScreen := preload("res://scripts/ui/menu_screen.gd")
const FlightView := preload("res://scripts/flight/flight_view.gd")
const CrtOverlay := preload("res://scripts/ui/crt_overlay.gd")

var world_layer: CanvasLayer
var ui_layer: CanvasLayer
var crt_layer: CanvasLayer


func _ready() -> void:
	Engine.max_fps = 60

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

	if OS.get_cmdline_user_args().has("--flight"):
		show_flight()
	else:
		show_menu()


func clear_layer(layer: CanvasLayer) -> void:
	for child in layer.get_children():
		child.queue_free()


func show_menu() -> void:
	clear_layer(world_layer)
	clear_layer(ui_layer)
	var menu := MenuScreen.new()
	menu.start_flight.connect(show_flight)
	ui_layer.add_child(menu)


func show_flight() -> void:
	clear_layer(world_layer)
	clear_layer(ui_layer)
	var view := FlightView.new()
	view.exit_requested.connect(show_menu)
	world_layer.add_child(view)
