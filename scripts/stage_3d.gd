extends Node3D

## Tilted camera looking down into a dark void. Floating spheres only — no path.

var mode := "combat"

var _cam: Camera3D
var _core: MeshInstance3D
var _core_light: OmniLight3D
var _anomaly: MeshInstance3D
var _beam: MeshInstance3D
var _pulse: MeshInstance3D
var _stars: Array[MeshInstance3D] = []
var _relics: Array[MeshInstance3D] = []
var _markers: Array[MeshInstance3D] = []
var _t := 0.0
var _vis := ""
var _mats: Dictionary = {}


func _ready() -> void:
	_env()
	_cam = Camera3D.new()
	_cam.current = true
	_cam.fov = 46.0
	_cam.near = 0.08
	_cam.far = 80.0
	add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 30.0, 0.0)
	sun.light_energy = 0.55
	add_child(sun)
	_make_stars()
	_core = _mesh(_sphere(0.42), _cached_emit("core_cyan", Color(0.35, 0.85, 1.0), 3.2))
	add_child(_core)
	_core_light = OmniLight3D.new()
	_core_light.light_color = Color(0.45, 0.85, 1.0)
	_core_light.light_energy = 2.4
	_core_light.omni_range = 8.0
	add_child(_core_light)
	_anomaly = _mesh(_sphere(0.65), _cached_emit("anomaly_alive", Color(0.55, 0.72, 0.88), 1.4))
	add_child(_anomaly)
	_beam = _mesh(_beam_mesh(), _cached_emit("beam", Color(0.7, 0.95, 1.0), 4.0))
	_beam.visible = false
	add_child(_beam)
	_pulse = _mesh(_sphere(0.08, 8, 4), _cached_emit("pulse", Color(0.8, 0.98, 1.0), 5.0))
	_pulse.visible = false
	add_child(_pulse)
	_make_relics()
	_make_markers()
	set_mode("combat")


func set_mode(m: String) -> void:
	mode = m


func _process(dt: float) -> void:
	_t += dt
	_apply_camera(dt)
	_sync_core()
	_sync_anomaly()
	_sync_beam()
	_sync_pulse()
	_sync_relics()
	_sync_markers()


func _apply_camera(dt: float) -> void:
	var pos := Vector3(0.0, 2.6, 6.4)
	var rot := Vector3(-21.0, 0.0, 0.0)
	var fov := 46.0
	match mode:
		"core", "relics":
			pos = Vector3(0.0, 2.15, 4.15)
			rot = Vector3(-14.0, 0.0, 0.0)
			fov = 40.0
		"space":
			pos = Vector3(0.0, 7.2, 9.5)
			rot = Vector3(-40.0, 0.0, 0.0)
			fov = 50.0
		"archive":
			pos = Vector3(0.0, 2.4, 5.0)
			rot = Vector3(-18.0, 18.0, 0.0)
			fov = 42.0
	var k := clampf(dt * 5.5, 0.0, 1.0)
	_cam.position = _cam.position.lerp(pos, k)
	_cam.rotation_degrees = _cam.rotation_degrees.lerp(rot, k)
	_cam.fov = lerpf(_cam.fov, fov, k)


func _sync_core() -> void:
	var y := 1.72 + sin(_t * 1.15) * 0.07
	_core.position = Vector3(0.0, y, 3.35)
	_core_light.position = _core.position + Vector3(0.0, 0.3, 0.4)
	var col := Color(0.35, 0.85, 1.0)
	var key := "core_cyan"
	match str(Game.tier):
		"violet":
			col = Color(0.78, 0.28, 1.0)
			key = "core_violet"
		"amber":
			col = Color(1.0, 0.55, 0.12)
			key = "core_amber"
		"red":
			col = Color(1.0, 0.2, 0.16)
			key = "core_red"
		"white":
			col = Color(0.92, 0.94, 1.0)
			key = "core_white"
	var dens := 0.7 + Game.lv_prod * 0.08
	var mat := _cached_emit(key, col, 2.2 + dens)
	mat.emission_energy_multiplier = 2.2 + dens
	_core.material_override = mat
	_core_light.light_color = col
	_core_light.light_energy = 1.8 + dens * 0.4
	_core.rotate_y(0.35 * get_process_delta_time())


func _sync_anomaly() -> void:
	var show := mode == "combat" or mode == "space"
	_anomaly.visible = show and not Game.front_cleared
	if not _anomaly.visible:
		return
	var e: Dictionary = Game.current_enemy()
	var vis := str(e.get("visual", "shard"))
	if vis != _vis:
		_vis = vis
		_anomaly.mesh = _anomaly_mesh(vis)
	var max_hp := maxf(float(e.get("max_integrity", 1.0)), 1.0)
	var u := 0.0 if max_hp <= 0.0 else clampf(Game.integrity / max_hp, 0.0, 1.0)
	var z := lerpf(-3.2, -11.5, 1.0 - Game.erosion)
	if not Game.alive:
		z = -14.0
	var y := 1.68 + sin(_t * 0.9 + 0.8) * 0.05
	_anomaly.position = Vector3(0.0, y, z)
	var s := 0.85 + (1.0 - u) * 0.2
	if vis == "compress":
		s *= 1.0 - Game.compression() * 0.45
	_anomaly.scale = Vector3.ONE * s
	_anomaly.rotate_y(0.55 * get_process_delta_time())
	_anomaly.rotate_x(0.18 * get_process_delta_time())
	var emit := _anomaly_emit(vis)
	if Game.alive:
		_anomaly.material_override = _cached_emit("anomaly_" + vis, Color(0.55, 0.72, 0.88), emit)
	else:
		_anomaly.material_override = _cached_emit("anomaly_dead", Color(0.3, 0.35, 0.4), 0.4)


func _sync_beam() -> void:
	var on := mode == "combat" and Game.beam_on and Game.alive and not Game.front_cleared
	_beam.visible = on
	if not on:
		return
	var a := _core.position
	var b := _anomaly.position
	var len := a.distance_to(b)
	if len < 0.001:
		_beam.visible = false
		return
	_beam.position = (a + b) * 0.5
	_beam.scale = Vector3.ONE
	_beam.look_at(b, Vector3.UP)
	_beam.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	var h := 2.0
	if _beam.mesh is CylinderMesh:
		h = maxf((_beam.mesh as CylinderMesh).height, 0.001)
	_beam.scale = Vector3(1.0, len / h, 1.0)


func _sync_pulse() -> void:
	var on := mode == "combat" and Game.pulse_cd > 0.28 and Game.alive and not Game.front_cleared
	_pulse.visible = on
	if not on:
		return
	var u := 1.0 - Game.pulse_cd / 0.38
	_pulse.position = _core.position.lerp(_anomaly.position, clampf(u, 0.0, 1.0))


func _sync_relics() -> void:
	var eq: Array[String] = Game.equipped
	var passives: Dictionary = Data.passives()
	for i in _relics.size():
		var node := _relics[i]
		if i >= eq.size():
			node.visible = false
			continue
		node.visible = mode != "space"
		var vis := "spark"
		if passives.has(eq[i]):
			vis = str(passives[eq[i]].get("visual", "spark"))
		var a := _t * 0.9 + TAU * float(i) / 4.0
		var r := 0.85
		node.position = _core.position + Vector3(cos(a) * r, 0.12 + sin(a * 1.3) * 0.08, sin(a) * r * 0.7)
		node.material_override = _cached_emit("relic_" + vis, _relic_color(vis), 2.0)


func _sync_markers() -> void:
	var show := mode == "space"
	var order: Array[String] = Data.enemy_order()
	for i in _markers.size():
		var node := _markers[i]
		node.visible = show
		if not show or i >= order.size():
			continue
		var id := order[i]
		var z := 2.5 - float(i) * 3.4
		var y := 1.62 + sin(float(i) * 1.17) * 0.38
		node.position = Vector3(sin(float(i) * 0.7) * 0.55, y, z)
		if id in Game.archived:
			node.material_override = _cached_emit("marker_archived", Color(0.35, 0.8, 0.65), 0.7)
		elif id == Game.enemy_id and not Game.front_cleared:
			node.material_override = _cached_emit("marker_current", Color(0.5, 0.9, 1.0), 1.6)
		else:
			node.material_override = _cached_emit("marker_idle", Color(0.25, 0.3, 0.38), 0.7)


func _env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.015, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.16, 0.22)
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.18
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)


func _make_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	var mat := _cached_emit("star", Color(0.85, 0.92, 1.0), 1.2)
	for i in 70:
		var s := _mesh(_sphere(rng.randf_range(0.02, 0.06), 8, 4), mat)
		s.position = Vector3(
			rng.randf_range(-14.0, 14.0),
			rng.randf_range(-2.0, 12.0),
			rng.randf_range(-30.0, 8.0)
		)
		add_child(s)
		_stars.append(s)


func _make_relics() -> void:
	var mat := _cached_emit("relic_spark", Color(0.6, 0.9, 1.0), 2.0)
	for i in 4:
		var n := _mesh(_sphere(0.09), mat)
		n.visible = false
		add_child(n)
		_relics.append(n)


func _make_markers() -> void:
	var mat := _cached_emit("marker_idle", Color(0.25, 0.3, 0.38), 0.7)
	for i in 9:
		var n := _mesh(_sphere(0.2, 12, 6), mat)
		n.visible = false
		add_child(n)
		_markers.append(n)


func _anomaly_mesh(vis: String) -> Mesh:
	match vis:
		"shard":
			return _sphere(0.52)
		"regen", "heal", "heal_boss":
			return _sphere(0.7)
		"boss":
			return _sphere(0.88)
		"shell":
			return _sphere(0.82)
		"fragment":
			return _sphere(0.58)
		"recurse":
			return _sphere(0.5)
		"compress":
			return _sphere(0.48)
		_:
			return _sphere(0.65)


func _anomaly_emit(vis: String) -> float:
	match vis:
		"boss":
			return 1.85
		"shell":
			return 1.6
		"regen", "heal", "heal_boss":
			return 1.7
		"compress":
			return 1.15
		"fragment":
			return 1.25
		_:
			return 1.4


func _relic_color(vis: String) -> Color:
	match vis:
		"ring":
			return Color(0.45, 0.95, 1.0)
		"core":
			return Color(0.7, 0.85, 1.0)
		"conduit":
			return Color(0.4, 0.7, 1.0)
		"dust":
			return Color(0.85, 0.7, 0.4)
		"shard":
			return Color(0.9, 0.95, 1.0)
		"flare":
			return Color(1.0, 0.85, 0.4)
		"wake":
			return Color(0.6, 1.0, 0.85)
		_:
			return Color(0.6, 0.9, 1.0)


func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	return n


func _sphere(r: float, radial: int = 16, rings: int = 8) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = radial
	m.rings = rings
	return m


func _beam_mesh() -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.04
	m.bottom_radius = 0.07
	m.height = 2.0
	m.radial_segments = 8
	return m


func _cached_emit(key: String, col: Color, energy: float) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := _emit(col, energy)
	_mats[key] = m
	return m


func _emit(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col.darkened(0.35)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.45
	m.metallic = 0.05
	return m
