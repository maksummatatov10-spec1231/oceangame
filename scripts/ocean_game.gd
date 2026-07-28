extends Node3D

const OCEAN_SCENE := preload("res://Scenes/Ocean.tscn")
const SUNSET_PANORAMA := preload("res://Resources/AllSkyFree_Sky_EpicBlueSunset_Equirect.png")
const MAX_SPEED := 18.0
const REVERSE_SPEED := 6.0
const ACCELERATION := 4.5
const TURN_SPEED := 1.35

var ship: RigidBody3D
var ocean: Node3D
var sailor: Node3D
var camera: Camera3D
var elapsed := 0.0
var treasures: Array[Node3D] = []
var collected := 0
var speed_label: Label
var objective_label: Label
var message_label: Label
var message_time := 5.0
var environment: Environment
var sun: DirectionalLight3D
var weather_strength := 0.72
var weather_target := 0.72
var weather_chop := 0.75
var weather_chop_target := 0.75
var weather_turn := 0.08
var weather_turn_target := 0.08
var weather_name := "Лёгкий ветер"
var weather_label: Label
var rain: GPUParticles3D
var storm_clouds: Array[MeshInstance3D] = []
var cloud_material: StandardMaterial3D

func _ready() -> void:
    _create_environment()
    _create_ocean()
    _create_islands()
    _create_ship()
    _create_treasures()
    _create_interface()

func _create_environment() -> void:
    # This panorama is supplied in ассеты2.zip and is now used by the game.
    var sky_material := PanoramaSkyMaterial.new()
    sky_material.panorama = SUNSET_PANORAMA
    var sky := Sky.new()
    sky.sky_material = sky_material
    environment = Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.65
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.75
    environment.fog_enabled = true
    environment.fog_light_color = Color("6b8da6")
    environment.fog_density = 0.006
    environment.fog_sky_affect = 0.7
    var world := WorldEnvironment.new()
    world.environment = environment
    add_child(world)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -32, 0)
    sun.light_color = Color("ffd1a0")
    sun.light_energy = 2.0
    sun.shadow_enabled = true
    add_child(sun)
    rain = GPUParticles3D.new()
    rain.amount = 1400
    rain.lifetime = 1.3
    rain.visibility_aabb = AABB(Vector3(-28, -8, -28), Vector3(56, 30, 56))
    var rain_process := ParticleProcessMaterial.new()
    rain_process.direction = Vector3(0, -1, 0)
    rain_process.spread = 7.0
    rain_process.initial_velocity_min = 16.0
    rain_process.initial_velocity_max = 23.0
    rain_process.gravity = Vector3(0, -8, 0)
    rain_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    rain_process.emission_box_extents = Vector3(28, 0.2, 28)
    var rain_drop := QuadMesh.new()
    rain_drop.size = Vector2(0.025, 0.65)
    var rain_material := StandardMaterial3D.new()
    rain_material.albedo_color = Color(0.67, 0.82, 0.96, 0.48)
    rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    rain_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    rain_drop.material = rain_material
    rain.process_material = rain_process
    rain.draw_pass_1 = rain_drop
    rain.amount_ratio = 0.0
    rain.emitting = true
    rain.local_coords = false
    add_child(rain)
    # A moving layered cloud deck gives the panorama sky an actual storm state.
    cloud_material = StandardMaterial3D.new()
    cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cloud_material.albedo_color = Color(0.16, 0.20, 0.27, 0.0)
    cloud_material.roughness = 1.0
    cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    for offset in [Vector3(-48, 28, -35), Vector3(26, 32, -52), Vector3(0, 25, 35)]:
        var cloud := MeshInstance3D.new()
        var cloud_mesh := SphereMesh.new()
        cloud_mesh.radial_segments = 32
        cloud_mesh.rings = 12
        cloud.mesh = cloud_mesh
        cloud.material_override = cloud_material
        cloud.scale = Vector3(68, 7, 48)
        cloud.position = offset
        add_child(cloud)
        storm_clouds.append(cloud)

func _create_ocean() -> void:
    # Keeps the original 17-tile infinite LOD layout from ассеты1.zip, now
    # rendering with the high-detail Realistic Water texture set supplied later.
    ocean = OCEAN_SCENE.instantiate()
    ocean.name = "AssetOcean"
    # Ocean uses a uniform, camera-centred grid. Unlike the source demo's
    # mixed LOD ring, it has no moving subdivision seam around the ship.
    add_child(ocean)

func _create_ship() -> void:
    ship = RigidBody3D.new()
    ship.set_script(preload("res://scripts/boat_physics.gd"))
    ship.name = "PlayerShip"
    ship.position = Vector3(0, 1.5, 10)
    ship.set("ocean", self)
    add_child(ship)
    var hull_collision := CollisionShape3D.new()
    var hull_shape := BoxShape3D.new()
    hull_shape.size = Vector3(3.2, 1.35, 7.6)
    hull_collision.shape = hull_shape
    hull_collision.position = Vector3(0, -0.35, 0)
    ship.add_child(hull_collision)
    var wood := _material(Color("4b2417"), 0.78)
    var dark_wood := _material(Color("24100c"), 0.82)
    var trim := _material(Color("d49a48"), 0.5, 0.15)
    # A layered hull reads well from the camera and keeps the silhouette ship-like.
    _mesh(ship, BoxMesh.new(), wood, Vector3(0, -0.15, 0), Vector3(3.6, 0.7, 8.6))
    _mesh(ship, BoxMesh.new(), dark_wood, Vector3(0, -0.7, 0.2), Vector3(2.45, 0.65, 6.5))
    _mesh(ship, BoxMesh.new(), trim, Vector3(0, 0.25, 0), Vector3(3.85, 0.18, 8.75))
    _mesh(ship, BoxMesh.new(), wood, Vector3(0, 0.65, 2.6), Vector3(2.8, 0.65, 2.4))
    var mast := CylinderMesh.new()
    mast.top_radius = 0.12; mast.bottom_radius = 0.16; mast.height = 6.4
    _mesh(ship, mast, dark_wood, Vector3(0, 3.1, -0.35))
    var sail_mat := _material(Color("f4d9a1"), 0.92)
    var sail := QuadMesh.new()
    sail.size = Vector2(3.5, 4.1)
    _mesh(ship, sail, sail_mat, Vector3(0.05, 3.7, -0.42), Vector3.ONE)
    var flag := QuadMesh.new()
    flag.size = Vector2(1.1, 0.65)
    _mesh(ship, flag, _material(Color("cf3e35"), 0.7), Vector3(0.62, 6.05, -0.35))
    sailor = Node3D.new()
    sailor.name = "Sailor"
    sailor.position = Vector3(0, 0.75, 1.35)
    ship.add_child(sailor)
    _create_sailor(sailor)
    camera = Camera3D.new()
    camera.fov = 67.0
    camera.current = true
    add_child(camera)
    camera.position = ship.position + Vector3(0, 7, 14)

func _create_sailor(parent: Node3D) -> void:
    var shirt := _material(Color("2e7592"), 0.8)
    var skin := _material(Color("c9825b"), 0.85)
    var navy := _material(Color("162b49"), 0.8)
    var body := CapsuleMesh.new()
    body.radius = 0.34; body.height = 1.15
    _mesh(parent, body, shirt, Vector3(0, 0.58, 0))
    var head := SphereMesh.new()
    head.radius = 0.31; head.height = 0.62
    _mesh(parent, head, skin, Vector3(0, 1.35, 0))
    var hat := CylinderMesh.new()
    hat.top_radius = 0.37; hat.bottom_radius = 0.4; hat.height = 0.16
    _mesh(parent, hat, navy, Vector3(0, 1.68, 0))

func _create_islands() -> void:
    for data in [Vector3(-65, 0, -92), Vector3(92, 0, -130), Vector3(-145, 0, 78), Vector3(153, 0, 58)]:
        var island := Node3D.new()
        island.position = data
        add_child(island)
        var sand := CylinderMesh.new()
        sand.top_radius = 13.0; sand.bottom_radius = 15.0; sand.height = 1.2; sand.radial_segments = 32
        _mesh(island, sand, _material(Color("d9b46e"), 1.0), Vector3(0, -0.45, 0))
        for i in 5:
            var palm := CylinderMesh.new()
            palm.top_radius = 0.13; palm.bottom_radius = 0.2; palm.height = 4.0
            var angle := float(i) * 1.26
            _mesh(island, palm, _material(Color("6b4022"), 0.9), Vector3(cos(angle) * 5.0, 1.7, sin(angle) * 5.0))
            var leaves := SphereMesh.new()
            leaves.radius = 1.25; leaves.height = 1.1
            _mesh(island, leaves, _material(Color("1e633d"), 0.95), Vector3(cos(angle) * 5.0, 4.0, sin(angle) * 5.0))

func _create_treasures() -> void:
    for point in [Vector3(-65, 1.1, -80), Vector3(92, 1.1, -118), Vector3(-135, 1.1, 78), Vector3(143, 1.1, 58)]:
        var beacon := Node3D.new()
        beacon.position = point
        add_child(beacon)
        var ring := TorusMesh.new()
        ring.inner_radius = 0.65; ring.outer_radius = 0.92
        _mesh(beacon, ring, _material(Color("ffd45c"), 0.25, 0.85), Vector3.ZERO)
        var light := OmniLight3D.new()
        light.light_color = Color("ffd45c"); light.light_energy = 2.5; light.omni_range = 9.0
        beacon.add_child(light)
        treasures.append(beacon)

func _create_interface() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var title := Label.new()
    title.text = "OCEAN VOYAGE"
    title.position = Vector2(28, 22)
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("ffe4ab"))
    layer.add_child(title)
    objective_label = Label.new()
    objective_label.position = Vector2(30, 62)
    objective_label.add_theme_font_size_override("font_size", 17)
    layer.add_child(objective_label)
    speed_label = Label.new()
    speed_label.position = Vector2(30, 91)
    speed_label.add_theme_font_size_override("font_size", 16)
    layer.add_child(speed_label)
    weather_label = Label.new()
    weather_label.position = Vector2(30, 118)
    weather_label.add_theme_font_size_override("font_size", 16)
    weather_label.add_theme_color_override("font_color", Color("d5e8f5"))
    layer.add_child(weather_label)
    var controls := Label.new()
    controls.text = "W/S — ход   A/D — штурвал   Shift — полный ход   1 — штиль   2 — ветер   3 — шторм   R — заново"
    controls.position = Vector2(30, 680)
    controls.add_theme_font_size_override("font_size", 15)
    controls.add_theme_color_override("font_color", Color("d5e8f5"))
    layer.add_child(controls)
    message_label = Label.new()
    message_label.text = "Найдите золотые морские маяки у островов."
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message_label.position.y = 25
    message_label.size.x = 600
    message_label.add_theme_font_size_override("font_size", 20)
    message_label.add_theme_color_override("font_color", Color("fff1c5"))
    layer.add_child(message_label)


func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1 or event.physical_keycode == KEY_1:
            _select_weather("Штиль", 0.28, 0.05, 0.0)
        elif event.keycode == KEY_2 or event.physical_keycode == KEY_2:
            _select_weather("Лёгкий ветер", 0.72, 0.75, 0.08)
        elif event.keycode == KEY_3 or event.physical_keycode == KEY_3:
            _select_weather("Шторм", 1.35, 1.70, -0.18)

func _physics_process(delta: float) -> void:
    elapsed += delta
    if Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()
    if Input.is_action_just_pressed("weather_calm"):
        _select_weather("Штиль", 0.28, 0.05, 0.0)
    elif Input.is_action_just_pressed("weather_breeze"):
        _select_weather("Лёгкий ветер", 0.72, 0.75, 0.08)
    elif Input.is_action_just_pressed("weather_storm"):
        _select_weather("Шторм", 1.35, 1.70, -0.18)
    # The three wave-profile values, light, fog and rain blend continuously.
    weather_strength = move_toward(weather_strength, weather_target, delta * 0.13)
    weather_chop = move_toward(weather_chop, weather_chop_target, delta * 0.17)
    weather_turn = move_toward(weather_turn, weather_turn_target, delta * 0.06)
    _apply_weather()
    ocean.global_position = Vector3(ship.global_position.x, 0.0, ship.global_position.z)
    _update_camera(delta)
    _check_treasures()
    objective_label.text = "МАЯКИ: %d / %d" % [collected, treasures.size()]
    speed_label.text = "СКОРОСТЬ: %02d узлов" % round(float(ship.get("speed_knots")))
    weather_label.text = "ПОГОДА: %s" % weather_name
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0:
            message_label.text = ""

func _select_weather(title: String, strength: float, chop: float, turn: float) -> void:
    weather_name = title
    weather_target = strength
    weather_chop_target = chop
    weather_turn_target = turn
    message_time = 3.0
    message_label.text = "Погода меняется: %s" % title

func _apply_weather() -> void:
    var storm_ratio := inverse_lerp(0.28, 1.35, weather_strength)
    environment.fog_density = lerp(0.004, 0.018, storm_ratio)
    environment.fog_light_color = Color("6b8da6").lerp(Color("43566c"), storm_ratio)
    environment.ambient_light_energy = lerp(0.78, 0.34, storm_ratio)
    sun.light_energy = lerp(2.0, 0.65, storm_ratio)
    sun.light_color = Color("ffd1a0").lerp(Color("a7b7ce"), storm_ratio)
    rain.global_position = ship.global_position + Vector3(0, 13, 0)
    rain.amount_ratio = smoothstep(0.38, 0.86, storm_ratio)
    cloud_material.albedo_color = Color(0.16, 0.20, 0.27, lerp(0.0, 0.86, storm_ratio))
    for cloud_index in storm_clouds.size():
        var cloud := storm_clouds[cloud_index]
        var offsets := [Vector3(-48, 28, -35), Vector3(26, 32, -52), Vector3(0, 25, 35)]
        cloud.global_position = ship.global_position + offsets[cloud_index]
    for tile in ocean.get_children():
        if tile is MeshInstance3D:
            var water_material := (tile as MeshInstance3D).get_active_material(0) as ShaderMaterial
            if water_material != null:
                water_material.set_shader_parameter("wave_strength", weather_strength)
                water_material.set_shader_parameter("chop_strength", weather_chop)
                water_material.set_shader_parameter("wind_turn", weather_turn)

func get_water_sample(world_position: Vector3) -> Dictionary:
    return OceanModel.sample(world_position, elapsed, weather_strength, weather_chop, weather_turn)

func _update_camera(delta: float) -> void:
    var desired := ship.global_position + ship.global_transform.basis.z * 13.5 + Vector3(0, 7.5, 0)
    camera.global_position = camera.global_position.lerp(desired, min(delta * 3.0, 1.0))
    camera.look_at(ship.global_position + Vector3(0, 1.8, 0), Vector3.UP)

func _check_treasures() -> void:
    for beacon in treasures:
        if is_instance_valid(beacon) and ship.global_position.distance_to(beacon.global_position) < 7.0:
            beacon.queue_free()
            collected += 1
            message_time = 3.0
            message_label.text = "Маяк найден! Осталось: %d" % (treasures.size() - collected)
            if collected == treasures.size():
                message_label.text = "Все маяки найдены — океан ваш, капитан!"
                message_time = 99.0

func _material(color: Color, roughness: float = 0.75, emission_energy: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_energy
    return material

func _mesh(parent: Node3D, mesh: Mesh, material: Material, location: Vector3, mesh_scale := Vector3.ONE) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.position = location
    instance.scale = mesh_scale
    parent.add_child(instance)
    return instance
