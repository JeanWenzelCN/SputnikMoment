extends Node2D
## 飞行场景：600 km 半径行星、大气、多级火箭、轨道与时间加速。

signal exit_requested

const Vehicle := preload("res://scripts/flight/vehicle.gd")
const HudScript := preload("res://scripts/flight/hud.gd")
const Debris := preload("res://scripts/flight/debris.gd")
const Orbit := preload("res://scripts/orbit.gd")
const PlanetShader := preload("res://shaders/planet.gdshader")
const StarfieldShader := preload("res://shaders/starfield.gdshader")

const R := 600000.0
const MU := 9.80665 * 600000.0 * 600000.0
const ATMO := 70000.0
const PAD := 6.0
const WARPS := [1, 5, 20, 100]

var vehicle = null
var camera: Camera2D
var hud = null
var planet: Sprite2D

var pos := Vector2(0.0, -(R + PAD))
var vel := Vector2.ZERO
var rot := 0.0
var angv := 0.0
var throttle := 0.0
var elapsed := 0.0
var alive := true
var landed := false
var warp_index := 0
var map_visible := false
var orbit_el := {}
var status_text := ""

var _orbit_timer := 0.0


func _ready() -> void:
	_build_backdrop()
	_build_planet()

	vehicle = Vehicle.new()
	vehicle.z_index = 3
	add_child(vehicle)
	vehicle.setup(Game.design)
	vehicle.position = pos
	vehicle.throttle = 0.0

	camera = Camera2D.new()
	camera.position = pos
	camera.zoom = Vector2(6.0, 6.0)
	add_child(camera)
	camera.make_current()

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = HudScript.new()
	hud_layer.add_child(hud)
	hud.bind(self)
	hud.exit_requested.connect(_on_exit)

	orbit_el = Orbit.elements(pos, vel)


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var void_rect := ColorRect.new()
	void_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	void_rect.color = Color(0.017, 0.022, 0.026, 1.0)
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
	planet.scale = Vector2(R * 1.4, R * 1.4)
	planet.z_index = -2
	var mat := ShaderMaterial.new()
	mat.shader = PlanetShader
	planet.material = mat
	add_child(planet)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_on_exit()
	elif event.is_action_pressed("stage"):
		do_separate()
	elif event.is_action_pressed("warp"):
		cycle_warp()
	elif event.is_action_pressed("map"):
		toggle_map()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_handle_input(delta)
	vehicle.throttle = throttle

	var warp: int = int(WARPS[warp_index])
	if altitude() < ATMO and warp > 5:
		warp = 5
	var total := delta * float(warp)
	var steps := clampi(int(ceil(total / 0.04)), 1, 90)
	var dt := total / float(steps)
	for i in range(steps):
		_step(dt)
	elapsed += total

	if pos.length() > R + PAD + 0.6:
		landed = false

	vehicle.position = pos
	vehicle.rotation = rot

	_update_camera(delta)
	queue_redraw()

	_orbit_timer += delta
	if _orbit_timer >= 0.2:
		_orbit_timer = 0.0
		orbit_el = Orbit.elements(pos, vel)


func _handle_input(delta: float) -> void:
	var up := Input.is_action_pressed("throttle_up")
	var down := Input.is_action_pressed("throttle_down")
	if up:
		throttle = minf(1.0, throttle + delta * 1.3)
	elif down:
		throttle = maxf(0.0, throttle - delta * 2.2)

	if not Game.is_cheat("infinite_fuel") and vehicle.current_fuel() <= 0.0:
		throttle = 0.0

	var torque := 0.0
	if Input.is_action_pressed("yaw_left"):
		torque -= 3.2
	if Input.is_action_pressed("yaw_right"):
		torque += 3.2
	angv += torque * delta
	if absf(torque) < 0.001 and Game.is_assist("gyro"):
		angv = lerpf(angv, 0.0, clampf(delta * 2.0, 0.0, 1.0))
	angv = clampf(angv, -1.7, 1.7)
	rot += angv * delta


func _step(dt: float) -> void:
	var r: float = maxf(R + 1.0, pos.length())
	var accel: Vector2 = -pos.normalized() * (MU / (r * r))

	var thrust: float = vehicle.current_thrust()
	var fuel: float = vehicle.current_fuel()
	var fuel_ok: bool = Game.is_cheat("infinite_fuel") or fuel > 0.0
	if throttle > 0.01 and thrust > 0.0 and fuel_ok:
		var force: float = thrust * throttle
		if Game.is_cheat("overdrive"):
			force *= 2.4
		accel += Vector2.UP.rotated(rot) * (force / vehicle.mass())
		vehicle.burn(dt)

	var alt: float = r - R
	if alt < ATMO and alt > 0.0:
		var rho: float = 1.225 * exp(-alt / 8500.0)
		var spd: float = vel.length()
		if spd > 0.4:
			var drag: float = 0.5 * rho * spd * spd * 0.45 * vehicle.ref_area()
			accel += -vel.normalized() * (drag / vehicle.mass())

	vel += accel * dt
	pos += vel * dt
	_check_ground()


func _check_ground() -> void:
	var floor_r: float = R + PAD
	if pos.length() >= floor_r:
		return
	var nrm: Vector2 = pos.normalized()
	var radial: float = vel.dot(nrm)
	if radial < -13.0 and not Game.is_cheat("hull"):
		_crash()
		return
	pos = nrm * floor_r
	vel -= nrm * radial
	if radial < -1.0:
		landed = true
		status_text = "着陆成功"
	elif vel.length() < 2.0:
		landed = true


func _crash() -> void:
	alive = false
	throttle = 0.0
	angv = 0.0
	vehicle.visible = false
	status_text = "任务失败：箭体损毁"


func _update_camera(delta: float) -> void:
	var alt: float = maxf(altitude(), 0.0)
	var fov: float = clampf(140.0 + alt * 1.15, 140.0, 2400000.0)
	var target: float = 720.0 / fov
	camera.zoom = camera.zoom.lerp(Vector2(target, target), clampf(delta * 3.0, 0.0, 1.0))
	camera.position = pos


func planet_radius() -> float:
	return R


func altitude() -> float:
	return pos.length() - R - PAD


func radial_speed() -> float:
	return vel.dot(pos.normalized())


func speed() -> float:
	return vel.length()


func do_separate() -> void:
	if not alive or landed:
		return
	var geometry: Array = vehicle.separate()
	if geometry.is_empty():
		return
	var d = Debris.new()
	d.setup(geometry, vel + pos.normalized() * -1.5, randf_range(-0.6, 0.6))
	d.position = pos
	d.z_index = 2
	add_child(d)
	status_text = "级间分离"


func cycle_warp() -> void:
	warp_index = (warp_index + 1) % WARPS.size()


func warp_text() -> String:
	return "x%d" % int(WARPS[warp_index])


func toggle_map() -> void:
	map_visible = not map_visible


func set_throttle_level(value: float) -> void:
	throttle = clampf(value, 0.0, 1.0)


func toggle_full_throttle() -> void:
	if throttle > 0.9:
		throttle = 0.0
	else:
		throttle = 1.0


func _on_exit() -> void:
	exit_requested.emit()


func _draw() -> void:
	if altitude() > 4000.0:
		return
	var up: Vector2 = pos.normalized()
	var right := Vector2(-up.y, up.x)
	var col := Color(0.62, 0.78, 0.62, 0.14)
	var span := 2500.0
	for i in range(-24, 25):
		var off: Vector2 = right * (float(i) * 100.0)
		draw_line(pos + off - up * span, pos + off + up * span, col, 1.0)
	for i in range(-12, 13):
		var off2: Vector2 = up * (float(i) * 100.0)
		draw_line(pos + off2 - right * span, pos + off2 + right * span, col, 1.0)