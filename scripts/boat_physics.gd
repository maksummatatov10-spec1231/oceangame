class_name BoatPhysics
extends RigidBody3D

# Eight pontoons sample the same CPU mirror of the shader wave function.
# Applying each force at its local point naturally produces pitch and roll.
const PROBES := [
    Vector3(-1.30, -0.70, -3.55), Vector3(0, -0.75, -3.65), Vector3(1.30, -0.70, -3.55),
    Vector3(-1.55, -0.73, -1.30), Vector3(0, -0.78, -1.25), Vector3(1.55, -0.73, -1.30),
    Vector3(-1.55, -0.73, 1.25), Vector3(0, -0.78, 1.25), Vector3(1.55, -0.73, 1.25),
    Vector3(-1.30, -0.70, 3.35), Vector3(0, -0.75, 3.48), Vector3(1.30, -0.70, 3.35),
]

var ocean: Node
var throttle_input := 0.0
var steering_input := 0.0
var boost_input := false
var speed_knots := 0.0
var submerged_fraction := 0.0

@export var buoyancy_stiffness := 560.0
@export var buoyancy_damping := 155.0
@export var linear_water_drag := 28.0
@export var quadratic_water_drag := 22.0
@export var angular_water_drag := 95.0
@export var engine_force := 680.0
@export var rudder_force := 310.0
@export var slam_coefficient := 105.0

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

    var submerged_count := 0
    for probe in PROBES:
        var world_probe := to_global(probe)
        var water: Dictionary = ocean.get_water_sample(world_probe)
        var depth: float = water.height - world_probe.y
        if depth <= 0.0:
            continue
        submerged_count += 1
        depth = min(depth, 1.25)
        var lever_velocity := linear_velocity + angular_velocity.cross(global_transform.basis * probe)
        var relative_vertical := water.vertical_velocity - lever_velocity.y
        # Archimedes-like restoring force plus a velocity term prevents bouncing.
        var lift := depth * buoyancy_stiffness + relative_vertical * buoyancy_damping
        var buoyancy := Vector3.UP * max(lift, 0.0)
        # A fast downward hull impact produces extra upward slamming force.
        var slam := Vector3.UP * max(relative_vertical, 0.0) * max(relative_vertical, 0.0) * slam_coefficient
        apply_force(buoyancy + slam, probe)

        # Hydrodynamic resistance opposes relative water velocity. The quadratic
        # component makes high-speed motion through waves much more expensive.
        var relative_velocity := lever_velocity - Vector3(0.0, water.vertical_velocity, 0.0)
        var drag := -relative_velocity * linear_water_drag
        drag += -relative_velocity * relative_velocity.length() * quadratic_water_drag
        apply_force(drag / PROBES.size(), probe)

    submerged_fraction = float(submerged_count) / float(PROBES.size())
    if submerged_count > 0:
        var forward := -global_transform.basis.z.normalized()
        var forward_speed := linear_velocity.dot(forward)
        var thrust_scale := 1.45 if boost_input and throttle_input > 0.0 else 1.0
        # Propeller thrust is applied low and aft; it pitches the bow subtly at speed.
        apply_force(forward * throttle_input * engine_force * thrust_scale, Vector3(0.0, -0.35, 3.0))
        # A rudder only bites when water flows past it. This avoids arcade turns at rest.
        var rudder_bite := clamp(abs(forward_speed) / 5.0, 0.0, 1.0)
        var side := global_transform.basis.x.normalized()
        apply_force(side * steering_input * rudder_force * rudder_bite * sign(forward_speed), Vector3(0.0, -0.45, 3.65))
        apply_torque(-angular_velocity * angular_water_drag * submerged_fraction)

    speed_knots = linear_velocity.length() * 1.94384
