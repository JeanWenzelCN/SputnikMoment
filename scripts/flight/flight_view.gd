extends Node2D
## 飞行场景：太阳系多天体、固定缩放 + 手动缩放、级间分离特效、目标清单。

signal exit_requested

const Vehicle := preload("res://scripts/flight/vehicle.gd")
const HudScript := preload("res://scripts/flight/hud.gd")
const Debris := preload("res://scripts/flight/debris.gd")
const Orbit := preload("res://scripts/orbit.gd")
const Solar := preload("res://scripts/data/solar.gd")
const PlanetShader := preload("res://shaders/planet.gdshader")
const StarfieldShader := preload("res://shaders/starfield.gdshader")

const PAD := 8.0
const WARPS := [1, 5, 20, 100]
const START_BODY := "earth"

var bodies: Array = []
var planet_nodes: Array = []
var vehicle = null
var hud = null

var pos := Vector2(0.0, -608008.0)
var vel := Vector2.ZERO
var rot := 0.0
var angv := 0.0
var throttle := 0.0
var elapsed := 0.0
var alive := true
var landed := true
var warp_index := 0
var map_visible := false
var orbit_el := {}
var status_text := ""
var current_body_id := START_BODY

var zoom_level := 8.0
var ship_height := 20.0
var shake := 0.0
var flashes: Array = []
var yaw_input := 0.0

var objectives: Array = []
var _orbit_timer := 0.0


func _ready() -> void:
	Game.ensure_design()
	bodies = Solar.build()
	Solar.update_positions(bodies, 0.0)

	_build_backdrop()
	_build_planets()

	vehicle = Vehicle.new()
	vehicle.z_index = 5
	add_child(vehicle)
	vehicle.setup(Game.design)
	vehicle.position = pos

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = HudScript.new()
	hud_layer.add_child(hud)
	hud.bind(self)
	hud.exit_requested.connect(_on_exit)

	ship_height = maxf(vehicle.total_height(), 6.0)
	zoom_level = 720.0 / (ship_height * 3.2)

	objectives = [
		{"text": "离开地面 1 km", "done": false},
		{"text": "到达 100 km 高度", "done": false},
		{"text": "建立环绕轨道", "done": false},
		{"text": "接近月球", "done": false},
		{"text": "在其他天体着陆", "done": false},
	]

	orbit_el = Orbit.elements(pos - body_pos(START_BODY), vel, body_mu(START_BODY))
	_update_view(1.0)


func body_pos(id: String) -> Vector2:
	for b in bodies:
		if String(b["id"]) == id:
			return b["pos"]
	return Vector2.ZERO


func body_mu(id: String) -> float:
	for b in bodies:
		if String(b["id"]) == id:
			return float(b["mu"])
	return 1.0


func get_body(id: String) -> Dictionary:
	for b in bodies:
		if String(b["id"]) == id:
			return b
	return {}


func dominant_body() -> Dictionary:
	return Solar.dominant(bodies, pos)


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)

	var stars := ColorRect.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.color = Color(1, 1, 1, 1)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = StarfieldShader
	stars.material = mat
	layer.add_child(stars)


func _build_planets() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var tex := ImageTexture.create_from_image(img)

	for b in bodies:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.centered = true
		var radius: float = float(b["radius"])
		sprite.scale = Vector2(radius * 1.4, radius * 1.4)
		sprite.z_index = -2
		var mat := ShaderMaterial.new()
		mat.shader = PlanetShader
		var col: Color = b["color"]
		mat.set_shader_parameter("surface_tint", Vector3(col.r, col.g, col.b))
		sprite.material = mat
		add_child(sprite)
		planet_nodes.append(sprite)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		zoom_level = clampf(zoom_level * float(event.factor), 0.00002, 80.0)
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			return
	if event.is_action_pressed("back"):
		_on_exit()
	elif event.is_action_pressed("stage"):
		do_separate()
	elif event.is_action_pressed("warp"):
		cycle_warp()
	elif event.is_action_pressed("map"):
		toggle_map()


func zoom_in() -> void:
	zoom_level = clampf(zoom_level * 1.6, 0.00002, 80.0)


func zoom_out() -> void:
	zoom_level = clampf(zoom_level / 1.6, 0.00002, 80.0)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_handle_input(delta)
	vehicle.throttle = throttle

	var warp: int = int(WARPS[warp_index])
	var total: float = delta * float(warp)
	var steps: int = clampi(int(ceil(total / 0.04)), 1, 90)
	var dt: float = total / float(steps)
	for i in range(steps):
		_step(dt)
	elapsed += total

	Solar.update_positions(bodies, elapsed)
	for i in range(bodies.size()):
		planet_nodes[i].position = Vector2(bodies[i]["pos"])

	if distance_to_surface() > 1.0:
		landed = false

	vehicle.position = pos
	vehicle.rotation = rot

	_update_view(delta)

	_orbit_timer += delta
	if _orbit_timer >= 0.2:
		_orbit_timer = 0.0
		_refresh_orbit()
		_check_objectives()

	queue_redraw()


func _refresh_orbit() -> void:
	var dom: Dictionary = dominant_body()
	current_body_id = String(dom["id"])
	orbit_el = Orbit.elements(pos - Vector2(dom["pos"]), vel, float(dom["mu"]))


func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		throttle = minf(1.0, throttle + delta * 1.3)
	elif Input.is_action_pressed("throttle_down"):
		throttle = maxf(0.0, throttle - delta * 2.2)

	if not Game.is_cheat("infinite_fuel") and vehicle.current_fuel() <= 0.0:
		throttle = 0.0

	var torque := 0.0
	if Input.is_action_pressed("yaw_left"):
		torque -= 3.2
	if Input.is_action_pressed("yaw_right"):
		torque += 3.2
	torque += clampf(yaw_input, -1.0, 1.0) * 3.8
	angv += torque * delta
	if absf(torque) < 0.001 and Game.is_assist("gyro"):
		angv = lerpf(angv, 0.0, clampf(delta * 2.0, 0.0, 1.0))
	angv = clampf(angv, -1.7, 1.7)
	rot += angv * delta


func _step(dt: float) -> void:
	var dom: Dictionary = dominant_body()
	var center: Vector2 = dom["pos"]
	var radius: float = float(dom["radius"])
	var rel: Vector2 = pos - center
	var r: float = maxf(rel.length(), radius * 0.3)
	var accel: Vector2 = -rel.normalized() * (float(dom["mu"]) / (r * r))

	var thrust: float = vehicle.current_thrust()
	var fuel_ok: bool = Game.is_cheat("infinite_fuel") or vehicle.current_fuel() > 0.0
	if throttle > 0.01 and thrust > 0.0 and fuel_ok:
		var force: float = thrust * throttle
		if Game.is_cheat("overdrive"):
			force *= 2.4
		accel += Vector2.UP.rotated(rot) * (force / vehicle.mass())
		vehicle.burn(dt)

	var alt: float = rel.length() - radius
	var atmo: float = float(dom["atmo"])
	if atmo > 0.0 and alt < atmo and alt > 0.0:
		var rho: float = 1.225 * exp(-alt / 8500.0)
		var spd: float = vel.length()
		if spd > 0.4:
			var drag: float = 0.5 * rho * spd * spd * 0.45 * vehicle.ref_area()
			accel += -vel.normalized() * (drag / vehicle.mass())

	vel += accel * dt
	pos += vel * dt
	_check_surface()


func distance_to_surface() -> float:
	var dom: Dictionary = dominant_body()
	return (pos - Vector2(dom["pos"])).length() - float(dom["radius"]) - PAD


func altitude() -> float:
	return distance_to_surface()


func radial_speed() -> float:
	return vel.dot(pos.normalized())


func speed() -> float:
	return vel.length()


func _check_surface() -> void:
	for b in bodies:
		var center: Vector2 = b["pos"]
		var rel: Vector2 = pos - center
		var dist: float = rel.length()
		var floor_r: float = float(b["radius"]) + PAD
		if dist >= floor_r:
			continue
		var nrm: Vector2 = rel.normalized()
		var radial: float = vel.dot(nrm)
		if radial < -13.0 and not Game.is_cheat("hull"):
			_crash()
			return
		pos = center + nrm * floor_r
		vel -= nrm * radial
		if radial < -1.0:
			landed = true
			status_text = "在%s着陆" % String(b["name"])
		elif vel.length() < 2.0:
			landed = true
		return


func _crash() -> void:
	alive = false
	throttle = 0.0
	angv = 0.0
	vehicle.visible = false
	status_text = "箭体损毁"


func _update_view(delta: float) -> void:
	var vp := get_viewport_rect().size
	var anchor := Vector2(vp.x * 0.5, vp.y * 0.56)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 1.8)
		var amp: float = shake * 16.0
		anchor += Vector2(randf_range(-amp, amp), randf_range(-amp, amp))

	position = anchor - pos * zoom_level
	scale = Vector2(zoom_level, zoom_level)


func do_separate() -> void:
	if not alive:
		return
	var geometry: Array = vehicle.separate()
	if geometry.is_empty():
		return
	var d = Debris.new()
	d.setup(geometry, vel + pos.normalized() * -1.5, randf_range(-0.8, 0.8))
	d.position = pos
	d.z_index = 3
	add_child(d)
	ship_height = maxf(vehicle.total_height(), 6.0)
	shake = 0.5
	flashes.append({"pos": pos, "t": 0.0, "life": 0.5})
	status_text = "级间分离"


func cycle_warp() -> void:
	warp_index = (warp_index + 1) % WARPS.size()


func warp_text() -> String:
	return "x%d" % int(WARPS[warp_index])


func toggle_map() -> void:
	map_visible = not map_visible


func toggle_full_throttle() -> void:
	if throttle > 0.9:
		throttle = 0.0
	else:
		throttle = 1.0


func current_objective() -> String:
	for o in objectives:
		if not bool(o["done"]):
			return String(o["text"])
	return "全部完成"


func _check_objectives() -> void:
	var dom: Dictionary = dominant_body()
	var alt: float = altitude()

	if not bool(objectives[0]["done"]) and alt > 1000.0:
		objectives[0]["done"] = true
		status_text = "目标完成：离开地面"

	if not bool(objectives[1]["done"]) and alt > 100000.0:
		objectives[1]["done"] = true
		status_text = "目标完成：到达 100 km"

	if not bool(objectives[2]["done"]):
		var peri: float = float(orbit_el.get("peri", 0.0))
		var e: float = float(orbit_el.get("e", 2.0))
		if e < 1.0 and peri - float(dom["radius"]) > 70000.0:
			objectives[2]["done"] = true
			status_text = "目标完成：进入轨道"

	if not bool(objectives[3]["done"]):
		var moon: Dictionary = get_body("moon")
		if not moon.is_empty():
			if (pos - Vector2(moon["pos"])).length() < 1500000.0:
				objectives[3]["done"] = true
				status_text = "目标完成：接近月球"

	if not bool(objectives[4]["done"]) and landed and String(dom["id"]) != START_BODY:
		objectives[4]["done"] = true
		status_text = "目标完成：异地着陆"


func _on_exit() -> void:
	exit_requested.emit()


func _draw() -> void:
	# 级间分离闪光
	var i := flashes.size() - 1
	while i >= 0:
		var f: Dictionary = flashes[i]
		var t: float = float(f["t"]) + 0.016
		if t > float(f["life"]):
			flashes.remove_at(i)
			i -= 1
			continue
		flashes[i]["t"] = t
		var k: float = t / float(f["life"])
		var origin: Vector2 = f["pos"]
		var rad: float = (2.0 + k * 26.0) / maxf(zoom_level, 0.0001)
		draw_arc(origin, rad, 0.0, TAU, 28, Color(1.0, 0.86, 0.55, (1.0 - k) * 0.85), 2.0 / maxf(zoom_level, 0.0001), true)
		draw_circle(origin, rad * 0.55, Color(1.0, 0.72, 0.32, (1.0 - k) * 0.35))
		i -= 1

	# 发射台
	if altitude() < 400.0:
		var base := Vector2(0.0, -(R + PAD))
		var up: Vector2 = base.normalized()
		var right := Vector2(-up.y, up.x)
		var p0: Vector2 = base + right * 9.0 - up * 0.5
		var p1: Vector2 = base - right * 9.0 - up * 0.5
		var p2: Vector2 = base - right * 9.0 - up * 3.5
		var p3: Vector2 = base + right * 9.0 - up * 3.5
		draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(0.19, 0.20, 0.20))
		draw_line(p0, p1, Color(0.85, 0.64, 0.25, 0.55), 1.2)
		draw_line(p1, p2, Color(0.10, 0.11, 0.11), 1.0)
		draw_line(p3, p2, Color(0.10, 0.11, 0.11), 1.0)

	# 地面网格（只在低空）
	if altitude() < 3000.0:
		var up: Vector2 = (pos - Vector2(dominant_body()["pos"])).normalized()
		var right := Vector2(-up.y, up.x)
		var col := Color(0.60, 0.72, 0.62, 0.13)
		var span := 2500.0
		for n in range(-20, 21):
			var off: Vector2 = right * (float(n) * 100.0)
			draw_line(pos + off - up * span, pos + off + up * span, col, 1.0)
		for n in range(-10, 11):
			var off2: Vector2 = up * (float(n) * 100.0)
			draw_line(pos + off2 - right * span, pos + off2 + right * span, col, 1.0)

	# 缩得太小时的飞船定位标记
	if zoom_level * 12.0 < 10.0:
		var rr: float = 10.0 / zoom_level
		var lw: float = 1.4 / zoom_level
		draw_arc(pos, rr, 0.0, TAU, 24, Color(0.92, 0.94, 0.96, 0.85), lw, true)
		draw_line(pos - Vector2(rr * 1.7, 0.0), pos - Vector2(rr * 0.6, 0.0), Color(0.92, 0.94, 0.96, 0.85), lw)
		draw_line(pos + Vector2(rr * 0.6, 0.0), pos + Vector2(rr * 1.7, 0.0), Color(0.92, 0.94, 0.96, 0.85), lw)