extends Node2D
## 真实比例飞行核心：双精度状态 + RK4 + on-rails 传播 + 浮动原点渲染。

signal exit_requested

const Vehicle := preload("res://scripts/flight/vehicle.gd")
const HudScript := preload("res://scripts/flight/hud.gd")
const Astro := preload("res://scripts/core/astro.gd")
const PlanetShader := preload("res://shaders/planet.gdshader")
const StarfieldShader := preload("res://shaders/starfield.gdshader")

const WARPS := [1, 2, 5, 10, 50, 100, 1000, 10000, 100000, 1000000, 10000000]
const SUB_DT := 0.05

var bodies: Array = []
var planet_nodes: Array = []
var ref: Dictionary = {}
var vehicle = null
var hud = null

var rx := 0.0
var ry := 0.0
var vx := 0.0
var vy := 0.0
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
var status_timer := 0.0
var target_id := ""
var yaw_input := 0.0
var sas_index := 0
var sas_hold := 0.0
var zoom_level := 8.0
var ship_height := 20.0

var _orbit_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Game.ensure_design()
	bodies = Astro.build()
	Astro.update_positions(bodies, 0.0)
	ref = Astro.find(bodies, "earth")
	rx = 0.0
	ry = -(float(ref["radius"]) + 6.0)

	_build_backdrop()
	_build_planets()

	vehicle = Vehicle.new()
	vehicle.z_index = 5
	add_child(vehicle)
	vehicle.setup(Game.design)

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	hud = HudScript.new()
	hud_layer.add_child(hud)
	hud.bind(self)
	hud.exit_requested.connect(_on_exit)

	ship_height = maxf(vehicle.total_height(), 6.0)
	zoom_level = 700.0 / (ship_height * 3.2)
	_refresh_orbit()
	_update_view()


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var stars := ColorRect.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.color = Color(0.02, 0.024, 0.028, 1.0)
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
		sprite.z_index = -2
		var mat := ShaderMaterial.new()
		mat.shader = PlanetShader
		var col: Color = b["color"]
		mat.set_shader_parameter("surface_tint", Vector3(col.r, col.g, col.b))
		if String(b["id"]) == "sun":
			mat.set_shader_parameter("smooth", 1.0)
		sprite.material = mat
		add_child(sprite)
		planet_nodes.append(sprite)


func get_body(id: String) -> Dictionary:
	return Astro.find(bodies, id)


func dominant_body() -> Dictionary:
	return ref


func world_x() -> float:
	return float(ref["px"]) + rx


func world_y() -> float:
	return float(ref["py"]) + ry


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_handle_input(delta)

	# 天体位置先按当前时刻刷新，保证引力中心准确
	Astro.update_positions(bodies, elapsed)

	var warp: int = int(WARPS[warp_index])
	var total: float = delta * float(warp)

	if warp >= 100 and throttle < 0.01:
		_advance_on_rails(total)
	else:
		var steps: int = clampi(int(ceil(total / SUB_DT)), 1, 40)
		var dt: float = total / float(steps)
		for i in range(steps):
			_step(dt)

	elapsed += total
	Astro.update_positions(bodies, elapsed)
	_update_ref()

	var alt: float = altitude()
	if alt > 1.0:
		landed = false

	if status_text != "":
		status_timer -= delta
		if status_timer <= 0.0:
			status_text = ""

	vehicle.position = Vector2.ZERO
	vehicle.rotation = rot
	_update_view()

	_orbit_timer += delta
	if _orbit_timer >= 0.15:
		_orbit_timer = 0.0
		_refresh_orbit()


func _advance_on_rails(dt: float) -> void:
	var el: Dictionary = Astro.elements(rx, ry, vx, vy, float(ref["mu"]))
	if not is_finite(float(el["a"])) or float(el["e"]) >= 1.0:
		var steps: int = clampi(int(ceil(dt / SUB_DT)), 1, 40)
		var sub: float = dt / float(steps)
		for i in range(steps):
			_step(sub)
		return
	el["nu"] = Astro.true_anomaly(el, rx, ry)
	var st: Array = Astro.propagate(el, dt, float(ref["mu"]))
	rx = float(st[0])
	ry = float(st[1])
	vx = float(st[2])
	vy = float(st[3])


func _accel(px: float, py: float, pvx: float, pvy: float) -> Array:
	var r2: float = px * px + py * py
	var r: float = sqrt(r2)
	if r < 1.0:
		r = 1.0
	var k: float = -float(ref["mu"]) / (r2 * r)
	var ax: float = k * px
	var ay: float = k * py

	var thrust: float = vehicle.current_thrust()
	var fuel_ok: bool = Game.is_cheat("infinite_fuel") or vehicle.current_fuel() > 0.0
	if throttle > 0.005 and thrust > 0.0 and fuel_ok:
		var force: float = thrust * throttle
		if Game.is_cheat("overdrive"):
			force *= 2.4
		var a: float = force / vehicle.mass()
		var ux: float = sin(rot)
		var uy: float = -cos(rot)
		ax += ux * a
		ay += uy * a

	var alt: float = r - float(ref["radius"])
	if alt < float(ref["atmo"]) and alt > 0.0:
		var rho: float = float(ref["rho0"]) * exp(-alt / float(ref["H"]))
		var v: float = sqrt(pvx * pvx + pvy * pvy)
		if v > 0.1:
			var drag: float = 0.5 * rho * v * v * 0.45 * vehicle.ref_area()
			var da: float = drag / vehicle.mass()
			ax -= pvx / v * da
			ay -= pvy / v * da

	return [ax, ay]


func _step(dt: float) -> void:
	var k1: Array = _accel(rx, ry, vx, vy)

	var ax2: float = rx + vx * dt * 0.5
	var ay2: float = ry + vy * dt * 0.5
	var vx2: float = vx + float(k1[0]) * dt * 0.5
	var vy2: float = vy + float(k1[1]) * dt * 0.5
	var k2: Array = _accel(ax2, ay2, vx2, vy2)

	var ax3: float = rx + vx2 * dt * 0.5
	var ay3: float = ry + vy2 * dt * 0.5
	var vx3: float = vx + float(k2[0]) * dt * 0.5
	var vy3: float = vy + float(k2[1]) * dt * 0.5
	var k3: Array = _accel(ax3, ay3, vx3, vy3)

	var ax4: float = rx + vx3 * dt
	var ay4: float = ry + vy3 * dt
	var vx4: float = vx + float(k3[0]) * dt
	var vy4: float = vy + float(k3[1]) * dt
	var k4: Array = _accel(ax4, ay4, vx4, vy4)

	rx += dt / 6.0 * (vx + 2.0 * vx2 + 2.0 * vx3 + vx4)
	ry += dt / 6.0 * (vy + 2.0 * vy2 + 2.0 * vy3 + vy4)
	vx += dt / 6.0 * (float(k1[0]) + 2.0 * float(k2[0]) + 2.0 * float(k3[0]) + float(k4[0]))
	vy += dt / 6.0 * (float(k1[1]) + 2.0 * float(k2[1]) + 2.0 * float(k3[1]) + float(k4[1]))

	vehicle.burn(dt)
	_check_surface()


func _check_surface() -> void:
	var r: float = sqrt(rx * rx + ry * ry)
	var floor_r: float = float(ref["radius"]) + 4.0
	if r >= floor_r:
		return
	var nrm_x: float = rx / r
	var nrm_y: float = ry / r
	var radial: float = vx * nrm_x + vy * nrm_y
	if radial < -12.0 and not Game.is_cheat("hull"):
		_crash()
		return
	rx = nrm_x * floor_r
	ry = nrm_y * floor_r
	vx -= nrm_x * radial
	vy -= nrm_y * radial
	if radial < -0.5:
		if not landed:
			status_text = "在%s着陆" % String(ref["name"])
			status_timer = 3.0
		landed = true
	elif sqrt(vx * vx + vy * vy) < 1.0:
		landed = true


func _crash() -> void:
	alive = false
	throttle = 0.0
	angv = 0.0
	vehicle.visible = false
	status_text = "箭体损毁"
	status_timer = 999.0


func _update_ref() -> void:
	var nb: Dictionary = Astro.ref_body(bodies, world_x(), world_y())
	if String(nb["id"]) == String(ref["id"]):
		return
	var wx: float = world_x()
	var wy: float = world_y()
	var wvx: float = float(ref["vx"]) + vx
	var wvy: float = float(ref["vy"]) + vy
	rx = wx - float(nb["px"])
	ry = wy - float(nb["py"])
	vx = wvx - float(nb["vx"])
	vy = wvy - float(nb["vy"])
	ref = nb
	status_text = "进入%s引力范围" % String(nb["name"])
	status_timer = 3.0


func _refresh_orbit() -> void:
	orbit_el = Astro.elements(rx, ry, vx, vy, float(ref["mu"]))


func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		throttle = minf(1.0, throttle + delta * 0.9)
	elif Input.is_action_pressed("throttle_down"):
		throttle = maxf(0.0, throttle - delta * 1.6)

	if not Game.is_cheat("infinite_fuel") and vehicle.current_fuel() <= 0.0:
		throttle = 0.0

	var torque := 0.0
	var manual := false
	if Input.is_action_pressed("yaw_left"):
		torque -= 2.4
		manual = true
	if Input.is_action_pressed("yaw_right"):
		torque += 2.4
		manual = true
	if absf(yaw_input) > 0.04:
		torque += clampf(yaw_input, -1.0, 1.0) * 2.8
		manual = true

	if manual:
		angv += torque * delta
	elif sas_index > 0:
		var diff: float = wrapf(sas_target_angle() - rot, -PI, PI)
		angv = lerpf(angv, clampf(diff * 2.2, -1.2, 1.2), clampf(delta * 6.0, 0.0, 1.0))
	elif Game.is_assist("gyro"):
		angv = lerpf(angv, 0.0, clampf(delta * 2.0, 0.0, 1.0))

	angv = clampf(angv, -1.2, 1.2)
	if landed and throttle < 0.01:
		angv = 0.0
	else:
		rot += angv * delta


func sas_target_angle() -> float:
	var sp: float = sqrt(vx * vx + vy * vy)
	match sas_index:
		1:
			if sp > 0.5:
				return atan2(vx, -vy)
		2:
			if sp > 0.5:
				return atan2(-vx, vy)
		3:
			return atan2(rx, -ry)
		4:
			return sas_hold
	return rot


func cycle_sas() -> void:
	sas_index = (sas_index + 1) % 5
	if sas_index == 4:
		sas_hold = rot


func sas_text() -> String:
	return "SAS %s" % ["关闭", "顺行", "逆行", "径向", "固定"][sas_index]


func _update_view() -> void:
	var vp := get_viewport_rect().size
	var anchor := Vector2(vp.x * 0.5, vp.y * 0.56)
	position = anchor
	scale = Vector2(zoom_level, zoom_level)

	var sx: float = world_x()
	var sy: float = world_y()
	for i in range(bodies.size()):
		var b: Dictionary = bodies[i]
		var dx: float = float(b["px"]) - sx
		var dy: float = float(b["py"]) - sy
		var sprite: Sprite2D = planet_nodes[i]
		var radius: float = float(b["radius"])
		var screen_r: float = radius * zoom_level
		if screen_r < 0.3 or screen_r > 4.0e5:
			sprite.visible = false
			continue
		sprite.visible = true
		sprite.position = Vector2(dx, dy)
		sprite.scale = Vector2(radius * 1.4, radius * 1.4)


func altitude() -> float:
	return sqrt(rx * rx + ry * ry) - float(ref["radius"])


func radial_speed() -> float:
	var r: float = maxf(sqrt(rx * rx + ry * ry), 1.0)
	return (vx * rx + vy * ry) / r


func speed() -> float:
	return sqrt(vx * vx + vy * vy)


func do_separate() -> void:
	if not alive:
		return
	var geometry: Array = vehicle.separate()
	if geometry.is_empty():
		return
	ship_height = maxf(vehicle.total_height(), 6.0)
	status_text = "级间分离"
	status_timer = 2.5


func cycle_warp() -> void:
	warp_index = (warp_index + 1) % WARPS.size()


func warp_text() -> String:
	var w: int = int(WARPS[warp_index])
	if w >= 1000:
		return "x%dK" % int(w / 1000) if w < 1000000 else "x%dM" % int(w / 1000000)
	return "x%d" % w


func toggle_map() -> void:
	map_visible = not map_visible


func toggle_full_throttle() -> void:
	throttle = 0.0 if throttle > 0.9 else 1.0


func set_target(id: String) -> void:
	target_id = "" if String(ref["id"]) == id else id


func target_distance() -> float:
	if target_id.is_empty():
		return 0.0
	var tb: Dictionary = get_body(target_id)
	if tb.is_empty():
		return 0.0
	var dx: float = world_x() - float(tb["px"])
	var dy: float = world_y() - float(tb["py"])
	return sqrt(dx * dx + dy * dy)


func target_rel_speed() -> float:
	if target_id.is_empty():
		return 0.0
	var tb: Dictionary = get_body(target_id)
	if tb.is_empty():
		return 0.0
	var ax: float = float(ref["vx"]) + vx - float(tb["vx"])
	var ay: float = float(ref["vy"]) + vy - float(tb["vy"])
	return sqrt(ax * ax + ay * ay)


func transfer_dv() -> float:
	if target_id.is_empty():
		return -1.0
	var tb: Dictionary = get_body(target_id)
	if tb.is_empty():
		return -1.0
	var r1: float = sqrt(rx * rx + ry * ry)
	var dx: float = float(tb["px"]) - float(ref["px"])
	var dy: float = float(tb["py"]) - float(ref["py"])
	var r2: float = sqrt(dx * dx + dy * dy)
	if r1 <= 0.0 or r2 <= 0.0:
		return -1.0
	var mu: float = float(ref["mu"])
	return sqrt(mu / r1) * (sqrt(2.0 * r2 / (r1 + r2)) - 1.0)


func current_objective() -> String:
	var alt: float = altitude()
	if alt < 1.0:
		return "点火升空"
	var sp: float = speed()
	if alt < 1.0e5:
		return "爬升（%.1f/100 km）" % (alt / 1000.0)
	var el: Dictionary = orbit_el
	if float(el.get("peri", 0.0)) > float(ref["atmo"]) and float(el.get("e", 2.0)) < 1.0:
		return "已入轨 · 速度 %.2f km/s" % (sp / 1000.0)
	return "抬高近地点（%.1f km/s，需 7.8）" % (sp / 1000.0)


func _on_exit() -> void:
	exit_requested.emit()


func _draw() -> void:
	# 局部地面（近地时用切平面表现，避免超大星球 quad）
	var alt: float = altitude()
	if alt < 60000.0:
		var r: float = maxf(sqrt(rx * rx + ry * ry), 1.0)
		var ux: float = rx / r
		var uy: float = ry / r
		var tx: float = -uy
		var ty: float = ux
		var surf_x: float = ux * float(ref["radius"]) - rx
		var surf_y: float = uy * float(ref["radius"]) - ry
		var half: float = maxf(300.0, alt * 3.0 + 500.0)
		var p0 := Vector2(surf_x - tx * half, surf_y - ty * half)
		var p1 := Vector2(surf_x + tx * half, surf_y + ty * half)
		var p2 := Vector2(surf_x + tx * half - ux * half * 0.05, surf_y + ty * half - uy * half * 0.05)
		var p3 := Vector2(surf_x - tx * half - ux * half * 0.05, surf_y - ty * half - uy * half * 0.05)
		draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(0.11, 0.10, 0.09))

		var gcol := Color(0.55, 0.42, 0.22, 0.22)
		var step: float = 100.0
		while step * zoom_level < 26.0:
			step *= 5.0
		var k := -20
		while k <= 20:
			var off: float = float(k) * step
			draw_line(Vector2(surf_x + tx * off, surf_y + ty * off),
				Vector2(surf_x + tx * off - ux * half * 0.05, surf_y + ty * off - uy * half * 0.05), gcol, 1.0)
			k += 1
		var m := -4
		while m <= 4:
			var d: float = float(m) * step
			var bx: float = surf_x - ux * d
			var by: float = surf_y - uy * d
			draw_line(Vector2(bx - tx * half, by - ty * half), Vector2(bx + tx * half, by + ty * half),
				Color(0.55, 0.42, 0.22, 0.12), 1.0)
			m += 1

	# 缩得太小时的飞船定位环（飞船在原点）
	if zoom_level * 12.0 < 10.0:
		var rr: float = 10.0 / zoom_level
		var lw: float = 1.4 / zoom_level
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 24, Color(0.92, 0.94, 0.96, 0.8), lw, true)

	# 目标方向指示
	if not target_id.is_empty() and alive:
		var tb: Dictionary = get_body(target_id)
		if not tb.is_empty():
			var dx: float = float(tb["px"]) - world_x()
			var dy: float = float(tb["py"]) - world_y()
			var d: float = sqrt(dx * dx + dy * dy)
			if d > 1.0:
				var m2: float = 60.0 / zoom_level
				var ux2: float = dx / d
				var uy2: float = dy / d
				var a := Vector2(ux2 * m2, uy2 * m2)
				var b2 := Vector2(ux2 * m2 * 0.8, uy2 * m2 * 0.8)
				var side := Vector2(-uy2, ux2) * (m2 * 0.12)
				draw_colored_polygon(PackedVector2Array([a, b2 + side, b2 - side]), Color(0.55, 0.88, 0.72, 0.9))