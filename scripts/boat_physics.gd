class_name BoatPhysics
extends RigidBody3D

# Twelve hull contact points form the dynamic collision field against the ocean.
const PROBES: Array[Vector3] = [
    Vector3(-1.30, -0.70, -3.55), Vector3(0, -0.75, -3.65), Vector3(1.30, -0.70, -3.55),
    Vector3(-1.55, -0.73, -1.30), Vector3(0, -0.78, -1.25), Vector3(1.55, -0.73, -1.30),
    Vector3(-1.55, -0.73, 1.25), Vector3(0, -0.78, 1.25), Vector3(1.55, -0.73, 1.25),
    Vector3(-1.30, -0.70, 3.35), Vector3(0, -0.75, 3.48), Vector3(1.30, -0.70, 3.35),
]

var ocean: Node
var throttle_input: float = 0.0
var steering_input: float = 0.0
var boost_input: bool = false
var speed_knots: float = 0.0
var submerged_fraction: float = 0.0

@export var buoyancy_stiffness: float = 560.0
@export var buoyancy_damping: float = 155.0
@export var linear_water_drag: float = 28.0
@export var quadratic_water_drag: float = 22.0
@export var angular_water_drag: float = 95.0
@export var engine_force: float = 680.0
@export var rudder_force: float = 310.0
@export var slam_coefficient: float = 105.0

func _ready() -> void:
    mass = 145.0
    gravity_scale = 1.0
    linear_damp = 0.05
    angular_damp = 0.12
    can_sleep = false

func _physics_process(_delta: float) -> void:
    throttle_input = Input.get_axis("reverse", "throttle")
    steering_input = Input.get_axis("turn_right", "turn_left")
    boost_input = Input.is_action_pressed("boost")
    if ocean == null:
        return

    var submerged_count: int = 0
    for probe: Vector3 in PROBES:
        var world_probe: Vector3 = to_global(probe)
        var water: Dictionary = ocean.get_water_sample(world_probe) as Dictionary
        var water_height: float = float(water["height"])
        var water_vertical_velocity: float = float(water["vertical_velocity"])
        var depth: float = water_height - world_probe.y
        if depth <= 0.0:
            continue
        submerged_count += 1
        depth = minf(depth, 1.25)
        var lever_velocity: Vector3 = linear_velocity + angular_velocity.cross(global_transform.basis * probe)
        var relative_vertical: float = water_vertical_velocity - lever_velocity.y
        # Archimedes-like restoring force plus a velocity term prevents bouncing.
        var lift: float = depth * buoyancy_stiffness + relative_vertical * buoyancy_damping
        var buoyancy: Vector3 = Vector3.UP * maxf(lift, 0.0)
        # A fast downward hull impact produces extra upward slamming force.
        var impact_speed: float = maxf(relative_vertical, 0.0)
        var slam: Vector3 = Vector3.UP * impact_speed * impact_speed * slam_coefficient
        apply_force(buoyancy + slam, probe)

        # Hydrodynamic resistance opposes relative water velocity. The quadratic
        # component makes high-speed motion through waves much more expensive.
        var relative_velocity: Vector3 = lever_velocity - Vector3(0.0, water_vertical_velocity, 0.0)
        var drag: Vector3 = -relative_velocity * linear_water_drag
        drag += -relative_velocity * relative_velocity.length() * quadratic_water_drag
        apply_force(drag / float(PROBES.size()), probe)

    submerged_fraction = float(submerged_count) / float(PROBES.size())
    if submerged_count > 0:
        var forward: Vector3 = -global_transform.basis.z.normalized()
        var forward_speed: float = linear_velocity.dot(forward)
        var thrust_scale: float = 1.45 if boost_input and throttle_input > 0.0 else 1.0
        # Propeller thrust is applied low and aft; it pitches the bow subtly at speed.
        apply_force(forward * throttle_input * engine_force * thrust_scale, Vector3(0.0, -0.35, 3.0))
        # A rudder only bites when water flows past it. This avoids arcade turns at rest.
        var rudder_bite: float = clampf(absf(forward_speed) / 5.0, 0.0, 1.0)
        var side: Vector3 = global_transform.basis.x.normalized()
        apply_force(side * steering_input * rudder_force * rudder_bite * signf(forward_speed), Vector3(0.0, -0.45, 3.65))
        apply_torque(-angular_velocity * angular_water_drag * submerged_fraction)

    speed_knots = linear_velocity.length() * 1.94384
