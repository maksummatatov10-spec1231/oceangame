class_name OceanModel
extends RefCounted

# Shared CPU wave field. The vertex shader has this same train and applies the
# same weather factors, so buoyancy is the collision/query representation of
# the rendered dynamic water surface.
const WAVES := [
    {"direction": Vector2(0.94, 0.34), "amplitude": 0.62, "wavelength": 18.0, "speed": 1.65, "octave": 0.0},
    {"direction": Vector2(0.98, 0.20), "amplitude": 0.46, "wavelength": 13.0, "speed": 2.05, "octave": 0.15},
    {"direction": Vector2(0.90, 0.44), "amplitude": 0.36, "wavelength": 10.0, "speed": 2.45, "octave": 0.30},
    {"direction": Vector2(0.99, 0.08), "amplitude": 0.28, "wavelength": 7.5, "speed": 2.90, "octave": 0.50},
    {"direction": Vector2(0.86, 0.51), "amplitude": 0.22, "wavelength": 5.5, "speed": 3.40, "octave": 0.66},
    {"direction": Vector2(0.96, 0.28), "amplitude": 0.16, "wavelength": 4.0, "speed": 3.90, "octave": 0.80},
    {"direction": Vector2(0.82, 0.57), "amplitude": 0.12, "wavelength": 3.0, "speed": 4.35, "octave": 0.92},
    {"direction": Vector2(1.0, -0.05), "amplitude": 0.08, "wavelength": 2.2, "speed": 4.85, "octave": 1.0},
]

static func sample(position: Vector3, time: float, swell_strength: float, chop_strength: float, wind_turn: float) -> Dictionary:
    var height := 0.0
    var vertical_speed := 0.0
    var slope := Vector2.ZERO
    for wave: Dictionary in WAVES:
        var direction: Vector2 = wave.direction.rotated(wind_turn).normalized()
        var layer_strength := lerp(swell_strength, chop_strength, float(wave.octave))
        var amplitude: float = wave.amplitude * layer_strength
        var wavelength: float = wave.wavelength
        var phase_speed: float = wave.speed * lerp(0.82, 1.18, chop_strength / 1.7)
        var wave_number := TAU / wavelength
        var phase := wave_number * direction.dot(Vector2(position.x, position.z)) - time * phase_speed
        height += amplitude * sin(phase)
        vertical_speed += -amplitude * phase_speed * cos(phase)
        slope += direction * amplitude * wave_number * cos(phase)
    var normal := Vector3(-slope.x, 1.0, -slope.y).normalized()
    return {"height": height, "normal": normal, "vertical_velocity": vertical_speed}
