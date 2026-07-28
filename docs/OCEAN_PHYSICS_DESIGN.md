# Ocean, boat and weather design

## Research used

The implementation follows three practical conclusions from research:

1. The GPU water and CPU boat must evaluate the same wave function; otherwise the hull will visibly clip through a shader-only sea. This is the central point in [Interactive Ocean Physics](https://salivity.github.io/game-development/article/interactive-ocean-physics-vertex-shaders-and-buoyancy) and the Godot 4 [Gerstner Waves + Buoyancy example](https://www.seacreaturegame.com/blog/gerstner-waves-with-buoyancy-godot).
2. Buoyancy should be applied at several hull points, with depth-proportional lift and damping. Applying forces at the probe positions produces roll and pitch as torque rather than faking rotations. The same multi-probe / spring-and-damping approach is described in the [Godot boat physics article](https://gameidea.org/2024/08/29/making-boat-physics-in-godot/) and the [Godot RigidBody3D API](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html).
3. A convincing game ocean layers broad directional swells with shorter wind waves and moving normal maps. Gerstner waves are an efficient real-time model; higher-end ocean systems combine them with spectral/FFT detail, as summarized by [Oceanology](https://galidar.com/oceanology-nextgen) and the [ocean rendering overview](https://maythaswang.github.io/posts/002_fishies_ocean/).

## Implemented system

- `scripts/ocean_model.gd` is the single CPU model: eight directional waves provide height, vertical water velocity and analytic surface normal.
- `shaders/RealisticOcean.gdshader` mirrors the same eight height/slope components and adds the supplied dual normal maps, UV distortion and foam.
- `scripts/boat_physics.gd` is a `RigidBody3D`, not a transform-following visual approximation. Eight pontoons apply restoring lift, vertical damping and linear/quadratic water drag at their own hull positions. The engine is aft; the rudder force increases with forward water speed, preventing arcade-style turns at rest.
- Weather changes are interpolated, not switched: wave strength, fog, ambient light, sun colour/intensity and rain all blend continuously. `1` selects calm, `2` breeze and `3` storm.

This is still a real-time approximation, not CFD/FFT naval simulation. It deliberately favors deterministic, inexpensive Godot 4.3 gameplay physics while keeping the visible water and boat samples synchronized.
