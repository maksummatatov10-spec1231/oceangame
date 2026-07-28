class_name OceanModel
extends RefCounted

# Deep-water directional wave train. The same values are mirrored in
# shaders/RealisticOcean.gdshader. A broad swell plus progressively smaller
# wind waves avoids the repeated, equally sized sine-wave look.
const WAVES := [
    {"direction": Vector2(0.94, 0.34), "amplitude": 0.62, "wavelength": 18.0, "speed": 1.65},
    {"direction": Vector2(0.98, 0.20), "amplitude": 0.46, "wavelength": 13.0, "speed": 2.05},
    {"direction": Vector2(0.90, 0.44), "amplitude": 0.36, "wavelength": 10.0, "speed": 2.45},
    {"direction": Vector2(0.99, 0.08), "amplitude": 0.28, "wavelength": 7.5, "speed": 2.90},
    {"direction": Vector2(0.86, 0.51), "amplitude": 0.22, "wavelength": 5.5, "speed": 3.40},
    {"direction": Vector2(0.96, 0.28), "amplitude": 0.16, "wavelength": 4.0, "speed": 3.90},
    {"direction": Vector2(0.82, 0.57), "amplitude": 0.12, "wavelength": 3.0, "speed": 4.35},
    {"direction": Vector2(1.0, -0.05), "amplitude": 0.08, "wavelength": 2.2, "speed": 4.85},
]

static func sample(position: Vector3, time: float, strength: float) -> Dictionary:
    var height := 0.0
    var vertical_speed := 0.0
    var slope := Vector2.ZERO
    for wave: Dictionary in WAVES:
        var direction: Vector2 = wave.direction.normalized()
        var amplitude: float = wave.amplitude * strength
        var wavelength: float = wave.wavelength
        var phase_speed: float = wave.speed
        var wave_number := TAU / wavelength
        var phase := wave_number * direction.dot(Vector2(position.x, position.z)) - time * phase_speed
        height += amplitude * sin(phase)
        vertical_speed += -amplitude * phase_speed * cos(phase)
        slope += direction * amplitude * wave_number * cos(phase)
    var normal := Vector3(-slope.x, 1.0, -slope.y).normalized()
    return {
        "height": height,
        "normal": normal,
        "vertical_velocity": vertical_speed,
    }
