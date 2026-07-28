extends Node3D

const OCEAN_SHADER := preload("res://shaders/ocean.gdshader")
const MAX_SPEED := 18.0
const REVERSE_SPEED := 6.0
const ACCELERATION := 4.5
const TURN_SPEED := 1.35

var ship: Node3D
var sailor: Node3D
var camera: Camera3D
var speed := 0.0
var heading := 0.0
var elapsed := 0.0
var treasures: Array[Node3D] = []
var collected := 0
var speed_label: Label
var objective_label: Label
var message_label: Label
var message_time := 5.0

func _ready() -> void:
    _create_environment()
    _create_ocean()
    _create_islands()
    _create_ship()
    _create_treasures()
    _create_interface()

func _create_environment() -> void:
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("091d45")
    sky_material.sky_horizon_color = Color("f19a70")
    sky_material.ground_bottom_color = Color("061226")
    sky_material.ground_horizon_color = Color("4c7197")
    var sky := Sky.new()
    sky.sky_material = sky_material
    var environment := Environment.new()
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
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -32, 0)
    sun.light_color = Color("ffd1a0")
    sun.light_energy = 2.0
    sun.shadow_enabled = true
    add_child(sun)

func _create_ocean() -> void:
    var material := ShaderMaterial.new()
    material.shader = OCEAN_SHADER
    for x in range(-2, 3):
        for z in range(-2, 3):
            var water := MeshInstance3D.new()
            var plane := PlaneMesh.new()
            plane.size = Vector2(150.0, 150.0)
            plane.subdivide_width = 32
            plane.subdivide_depth = 32
            water.mesh = plane
            water.material_override = material
            water.position = Vector3(x * 149.0, 0, z * 149.0)
            add_child(water)

func _create_ship() -> void:
    ship = Node3D.new()
    ship.name = "PlayerShip"
    ship.position = Vector3(0, 0.65, 10)
    add_child(ship)
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
    var controls := Label.new()
    controls.text = "W / S — ход     A / D — штурвал     Shift — полный парус     R — заново"
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

func _physics_process(delta: float) -> void:
    elapsed += delta
    if Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()
    var target_speed := 0.0
    if Input.is_action_pressed("throttle"):
        target_speed = MAX_SPEED * (1.35 if Input.is_action_pressed("boost") else 1.0)
    elif Input.is_action_pressed("reverse"):
        target_speed = -REVERSE_SPEED
    speed = move_toward(speed, target_speed, ACCELERATION * delta)
    var steering := Input.get_axis("turn_left", "turn_right")
    if abs(speed) > 0.1:
        heading -= steering * TURN_SPEED * delta * clamp(abs(speed) / 5.0, 0.25, 1.4) * sign(speed)
    ship.rotation.y = heading
    var forward := -ship.global_transform.basis.z
    ship.position += forward * speed * delta
    ship.position.y = 0.72 + _wave_height(ship.position.x, ship.position.z) * 0.28
    ship.rotation.x = sin(elapsed * 1.3 + ship.position.z * 0.06) * 0.045
    ship.rotation.z = sin(elapsed * 1.1 + ship.position.x * 0.05) * 0.055
    sailor.position.y = 0.75 + sin(elapsed * 2.2) * 0.025
    _update_camera(delta)
    _check_treasures()
    objective_label.text = "МАЯКИ: %d / %d" % [collected, treasures.size()]
    speed_label.text = "СКОРОСТЬ: %02d узлов" % round(abs(speed) * 2.1)
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0:
            message_label.text = ""

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

func _wave_height(x: float, z: float) -> float:
    return sin(x * 0.115 + elapsed * 0.8) * 0.52 + sin(z * 0.1575 - elapsed * 0.624) * 0.29 + sin((x + z) * 0.0713 + elapsed) * 0.19

func _material(color: Color, roughness: float = 0.75, emission_energy: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_energy
    return material

func _mesh(parent: Node3D, mesh: Mesh, material: Material, location: Vector3, scale := Vector3.ONE) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.position = location
    instance.scale = scale
    parent.add_child(instance)
    return instance
