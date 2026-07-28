extends Node3D

const OCEAN_SCENE := preload("res://Scenes/Ocean.tscn")
const SUNSET_PANORAMA := preload("res://Resources/AllSkyFree_Sky_EpicBlueSunset_Equirect.png")
const MAX_SPEED := 18.0
const REVERSE_SPEED := 6.0
const ACCELERATION := 4.5
const TURN_SPEED := 1.35

var ship: Node3D
var ocean: Node3D
var sailor: Node3D
var camera: Camera3D
var speed := 0.0
var heading := 0.0
var elapsed := 0.0
var heave_velocity := 0.0
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
    # This panorama is supplied in ассеты2.zip and is now used by the game.
    var sky_material := PanoramaSkyMaterial.new()
    sky_material.panorama = SUNSET_PANORAMA
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
    # Uses the original 17-tile infinite ocean, WaterPlane scene and Water shader
    # extracted from ассеты1.zip. Ocean.gd updates the ocean_pos shader global.
    ocean = OCEAN_SCENE.instantiate()
    ocean.name = "AssetOcean"
    # OceanMap from the supplied demo scaled the tile layout by six. Retaining
    # that scale prevents the high-detail centre tile from looking like a tiny
    # disc around the ship and keeps the LOD rings far beyond the camera.
    ocean.scale = Vector3(6.0, 1.0, 6.0)
    add_child(ocean)

func _create_ship() -> void:
    ship = Node3D.new()
    ship.name = "PlayerShip"
    ship.position = Vector3(0, 1.35, 10)
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
    # Movement is calculated from yaw only: the visible pitch/roll below must
    # never steer the ship upward or sideways.
    var forward := Vector3(-sin(heading), 0.0, -cos(heading))
    ship.position += forward * speed * delta
    ocean.global_position = Vector3(ship.global_position.x, 0.0, ship.global_position.z)
    _apply_buoyancy(delta, forward)
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

# Must mirror large_waves() in shaders/Water.gdshader. Sampling the same
# mathematical surface at bow, stern and both sides gives stable buoyancy.
func _wave_height(x: float, z: float) -> float:
    var wave_a := 1.80 * sin((x * 0.95 + z * 0.31) * TAU / 21.0 - elapsed * 1.50)
    var wave_b := 1.15 * sin((x * -0.38 + z * 0.925) * TAU / 13.0 - elapsed * 2.10)
    var wave_c := 0.75 * sin((x * 0.72 + z * -0.694) * TAU / 7.0 - elapsed * 2.80)
    var wave_d := 0.30 * sin((x * -0.16 + z * 0.987) * TAU / 3.5 - elapsed * 4.00)
    return wave_a + wave_b + wave_c + wave_d

func _apply_buoyancy(delta: float, forward: Vector3) -> void:
    var right := Vector3(cos(heading), 0.0, -sin(heading))
    var center := ship.global_position
    var bow_height := _wave_height(center.x + forward.x * 3.7, center.z + forward.z * 3.7)
    var stern_height := _wave_height(center.x - forward.x * 3.7, center.z - forward.z * 3.7)
    var right_height := _wave_height(center.x + right.x * 1.65, center.z + right.z * 1.65)
    var left_height := _wave_height(center.x - right.x * 1.65, center.z - right.z * 1.65)
    var target_height := (bow_height + stern_height + right_height + left_height) * 0.25 + 0.72
    # A critically damped-ish spring adds believable delayed heave rather than
    # teleporting the hull to every crest.
    heave_velocity += (target_height - ship.position.y) * 30.0 * delta
    heave_velocity *= exp(-5.2 * delta)
    ship.position.y += heave_velocity * delta
    var target_pitch := atan2(bow_height - stern_height, 7.4)
    var target_roll := atan2(right_height - left_height, 3.3)
    var rotation_blend := 1.0 - exp(-5.5 * delta)
    ship.rotation = Vector3(
        lerp_angle(ship.rotation.x, target_pitch, rotation_blend),
        heading,
        lerp_angle(ship.rotation.z, target_roll, rotation_blend)
    )

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
