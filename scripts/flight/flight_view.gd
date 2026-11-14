extends Node2D
## Freedom flight: one planet, one rocket, radial gravity, generous assists.

signal exit_requested

const RocketScript := preload("res://scripts/flight/rocket.gd")
const HudScript := preload("res://scripts/flight/hud.gd")
const PlanetShader := preload("res://shaders/planet.gdshader")
const StarfieldShader := preload("res://shaders/starfield.gdshader")

const PLANET_RADIUS := 2400.0
const SURFACE_G := 9.8
const THRUST := 26.0
const OVERDRIVE := 72.0
const ROT_SPEED := 1.5
const ROT_ACCEL := 4.0
const FUEL_BURN := 5.0
const START_ALT := 90.0
const HALO := 1.4
const HULL_OFFSET := 26.0

var rocket = null
var camera: Camera2D
var hud = null
var planet: Sprite2D
var plot: Line2D

var elapsed := 0.0
var throttle := 0.0
var ang_vel := 0.0
var alive := true

var _plot_timer := 0.0
var _impact_timer := 0.0
var _impact_cache := 0.0


func _ready() -> void:
	_build_backdrop()
	_build_planet()

	rocket = RocketScript.new()
	rocket.z_index = 2
	add_child(rocket)
	rocket.position = Vector2(0.0, -(PLANET_RADIUS + START_ALT))

	plot = Line2D.new()
	plot.width = 2.0
	plot.default_color = Color(1.0, 0.72, 0.30, 0.55)
	plot.z_index = 1
	add_child(plot)

	camera = Camera2D.new()
	camera.position = rocket.position
	camera.zoom = Vector2(0.92, 0.92)
	add_child(camera)
	camera.make_current()

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = HudScript.new()
	hud_layer.add_child(hud)
	hud.bind(self)
	hud.exit_requested.connect(_on_exit)
	hud.restart_requested.connect(restart)


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var void_rect := ColorRect.new()
	void_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	void_rect.color = Color(0.020, 0.026, 0.029, 1.0)
	void_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(void_rect)

	var stars := ColorRect.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.color = Color(1, 1, 1, 1)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = StarfieldShader
	stars.material = mat
	layer.add_child(stars)


func _build_planet() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var tex := ImageTexture.create_from_image(img)

	planet = Sprite2D.new()
	planet.texture = tex
	planet.centered = true
	planet.position = Vector2.ZERO
	planet.scale = Vector2(PLANET_RADIUS * HALO, PLANET_RADIUS * HALO)
	planet.z_index = -2
	var mat := ShaderMaterial.new()
	mat.shader = PlanetShader
	planet.material = mat
	add_child(planet)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_on_exit()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	elapsed += delta
	_handle_input(delta)
	_step(delta)
	_update_camera(delta)

	_plot_timer += delta
	if _plot_timer >= 0.10:
		_plot_timer = 0.0
		_update_plot()

	_impact_timer += delta
	if _impact_timer >= 0.30:
		_impact_timer = 0.0
		_impact_cache = _simulate_impact()


func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		throttle = minf(1.0, throttle + delta * 1.7)
	elif Input.is_action_pressed("throttle_down"):
		throttle = maxf(0.0, throttle - delta * 2.6)

	var torque := 0.0
	if Input.is_action_pressed("yaw_left"):
		torque -= ROT_ACCEL
	if Input.is_action_pressed("yaw_right"):
		torque += ROT_ACCEL
	ang_vel += torque * delta

	if absf(torque) < 0.001 and Game.is_assist("gyro"):
		ang_vel = lerpf(ang_vel, 0.0, clampf(delta * 2.2, 0.0, 1.0))

	ang_vel = clampf(ang_vel, -ROT_SPEED, ROT_SPEED)
	rocket.rotation += ang_vel * delta

	if not Game.is_cheat("infinite_fuel") and rocket.fuel <= 0.0:
		throttle = 0.0
	rocket.throttle_vis = throttle


func _step(delta: float) -> void:
	var pos: Vector2 = rocket.position
	var r: float = maxf(1.0, pos.length())
	var up: Vector2 = -pos / r
	var g: float = SURFACE_G * pow(PLANET_RADIUS / r, 2.0)
	var accel: Vector2 = -up * g

	if Game.is_cheat("zero_g"):
		accel = Vector2.ZERO

	var fuel_ok: bool = Game.is_cheat("infinite_fuel") or rocket.fuel > 0.0
	if throttle > 0.01 and fuel_ok:
		var t: float = OVERDRIVE if Game.is_cheat("overdrive") else THRUST
		accel += Vector2.UP.rotated(rocket.rotation) * (t * throttle)
		if not Game.is_cheat("infinite_fuel"):
			rocket.fuel = maxf(0.0, rocket.fuel - FUEL_BURN * throttle * delta)

	rocket.velocity += accel * delta
	rocket.position += rocket.velocity * delta
	_check_surface()


func _check_surface() -> void:
	var floor_r: float = PLANET_RADIUS + HULL_OFFSET
	if rocket.position.length() > floor_r:
		return

	var nrm: Vector2 = rocket.position.normalized()
	var radial: float = rocket.velocity.dot(nrm)

	if radial < -22.0 and not Game.is_cheat("hull"):
		_crash()
		return

	rocket.position = nrm * floor_r
	var tangential: Vector2 = rocket.velocity - nrm * radial
	rocket.velocity = tangential * 0.72
	throttle = minf(throttle, 0.3)


func _crash() -> void:
	alive = false
	throttle = 0.0
	ang_vel = 0.0
	rocket.throttle_vis = 0.0
	rocket.visible = false
	plot.points = PackedVector2Array()


func restart() -> void:
	alive = true
	elapsed = 0.0
	throttle = 0.0
	ang_vel = 0.0

	rocket.visible = true
	rocket.position = Vector2(0.0, -(PLANET_RADIUS + START_ALT))
	rocket.velocity = Vector2.ZERO
	rocket.rotation = 0.0
	rocket.fuel = rocket.fuel_max
	rocket.throttle_vis = 0.0

	camera.position = rocket.position
	camera.zoom = Vector2(0.92, 0.92)
	plot.points = PackedVector2Array()


func _update_camera(delta: float) -> void:
	var target: float = clampf(1.05 - altitude() / 4200.0, 0.18, 1.05)
	camera.zoom = camera.zoom.lerp(Vector2(target, target), clampf(delta * 1.6, 0.0, 1.0))
	camera.position = camera.position.lerp(rocket.position, clampf(delta * 7.0, 0.0, 1.0))


func _update_plot() -> void:
	if not Game.is_assist("predictor") or not alive:
		plot.points = PackedVector2Array()
		return

	var p: Vector2 = rocket.position
	var v: Vector2 = rocket.velocity
	var dt := 0.06
	var pts := PackedVector2Array()

	for i in range(150):
		var r: float = maxf(1.0, p.length())
		var up: Vector2 = -p / r
		var accel: Vector2 = -up * (SURFACE_G * pow(PLANET_RADIUS / r, 2.0))
		if Game.is_cheat("zero_g"):
			accel = Vector2.ZERO
		v += accel * dt
		p += v * dt
		pts.append(p)
		if p.length() <= PLANET_RADIUS:
			break

	plot.points = pts


func _simulate_impact() -> float:
	var p: Vector2 = rocket.position
	var v: Vector2 = rocket.velocity
	var dt := 0.05
	for i in range(2400):
		var r: float = maxf(1.0, p.length())
		var up: Vector2 = -p / r
		v += (-up * (SURFACE_G * pow(PLANET_RADIUS / r, 2.0))) * dt
		p += v * dt
		if p.length() <= PLANET_RADIUS + HULL_OFFSET:
			return v.length()
	return v.length()


func altitude() -> float:
	return rocket.position.length() - PLANET_RADIUS - HULL_OFFSET


func speed() -> float:
	return rocket.velocity.length()


func fuel_fraction() -> float:
	return clampf(rocket.fuel / rocket.fuel_max, 0.0, 1.0)


func impact_estimate() -> float:
	return _impact_cache


func _on_exit() -> void:
	exit_requested.emit()