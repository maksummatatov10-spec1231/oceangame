# Audit: `godot-realistic-water-4.zip`

## Verification

- Archive from `main`: **25,475,454 bytes** compressed; archive header commit/reference `fa0fc4785a009e99db96015cb8512d232565aae1`.
- Extracted successfully; the payload has **75 files**. Binary image and Godot resource files were enumerated by path and byte size; all readable text sources were inspected.
- It is a Godot 4 project (`config_version=5`, feature `4.0`, Double Precision) whose README still contains an obsolete Godot 3.4 usage sentence. The water source itself is Godot 4 syntax (`MODEL_MATRIX`, `hint_depth_texture`, `hint_screen_texture`).

## Integration decision

The project uses the supplied water texture set directly:

- `Water_N_A.png` and `Water_N_B.png`: two scrolling normal maps.
- `Water_UV.png`: distortion / de-tiling map.
- `Foam.png`: crest foam mask.
- `Caustic.png`: retained with the asset set, but not sampled because the upstream shader expects a 16-layer `Texture2DArray`, while this ZIP supplies one PNG rather than that generated array. Sampling it as a 2D array would create a missing-resource or black-caustic error.

`shaders/RealisticOcean.gdshader` is a Godot 4 integration based on the supplied MIT shader and texture design. It replaces the old repetitive surface shader. It uses six differently directed Gerstner waves, analytic wave slopes, moving dual normals, UV distortion, and foam at tall crests. The exact large-wave height function is duplicated in `scripts/ocean_game.gd` for four-point boat buoyancy. The original 17-tile infinite LOD layout remains in `Scenes/Ocean.gd`.

The downloaded boat, ground, rock and seaweed demo assets are not instantiated: they are a separate static shoreline demo and would conflict with the game's custom ship, islands and endless-world model. Their source files were nevertheless inspected below. MIT attribution has been copied to `ThirdParty/realistic-water/`.

## Every file in the archive

| File | Bytes | Analysis / disposition |
| --- | ---: | --- |
| `.gitignore` | 151 | Upstream Git ignore rules; not merged. |
| `AUTHORS.md` | 650 | Attribution — copied into ThirdParty attribution. |
| `LICENSE.md` | 1,207 | MIT licence — copied into ThirdParty attribution. |
| `README.md` | 638 | Usage/creator notes — analyzed and copied into ThirdParty attribution. |
| `Realistic Water Shader.jpg` | 1,300,288 | Archive metadata/content file — analyzed. |
| `Realistic Water Shader.jpg.import` | 800 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `export_presets.cfg` | 710 | Export preset metadata for the upstream demo; not merged. |
| `icon.png` | 680 | Project/icon/screenshot image — analyzed, not runtime-relevant. |
| `icon.png.import` | 795 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `project.godot` | 3,175 | Godot 4 project settings; analyzed, not merged to preserve Ocean Voyage input/render setup. |
| `realistic_water_shader/art/boat/Boat.material` | 780 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/boat/Boat.obj` | 35,985 | Imported mesh source; analyzed, not used in the game world. |
| `realistic_water_shader/art/boat/Boat.obj.import` | 583 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/boat/Boat_B.png` | 919,821 | Boat PBR texture (base/metal/normal/roughness) — analyzed, not used; game retains its sailor ship. |
| `realistic_water_shader/art/boat/Boat_B.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/boat/Boat_M.png` | 67,488 | Boat PBR texture (base/metal/normal/roughness) — analyzed, not used; game retains its sailor ship. |
| `realistic_water_shader/art/boat/Boat_M.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/boat/Boat_N.png` | 1,081,548 | Boat PBR texture (base/metal/normal/roughness) — analyzed, not used; game retains its sailor ship. |
| `realistic_water_shader/art/boat/Boat_N.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/boat/Boat_R.png` | 752,092 | Boat PBR texture (base/metal/normal/roughness) — analyzed, not used; game retains its sailor ship. |
| `realistic_water_shader/art/boat/Boat_R.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/ground/Ground.material` | 814 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/ground/Ground_B.png` | 2,430,066 | Ground PBR texture — analyzed, not used; static demo shoreline is unsuitable for moving infinite ocean. |
| `realistic_water_shader/art/ground/Ground_B.png.import` | 840 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/ground/Ground_N.png` | 3,094,393 | Ground PBR texture — analyzed, not used; static demo shoreline is unsuitable for moving infinite ocean. |
| `realistic_water_shader/art/ground/Ground_N.png.import` | 839 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/ground/Ground_R.png` | 2,676,951 | Ground PBR texture — analyzed, not used; static demo shoreline is unsuitable for moving infinite ocean. |
| `realistic_water_shader/art/ground/Ground_R.png.import` | 840 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/rock/Rock.material` | 1,100 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/rock/Rock.obj` | 11,598 | Imported mesh source; analyzed, not used in the game world. |
| `realistic_water_shader/art/rock/Rock.obj.import` | 589 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/rock/Rock_B.png` | 1,541,204 | Rock PBR texture — analyzed, not used; static demo content. |
| `realistic_water_shader/art/rock/Rock_B.png.import` | 831 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/rock/Rock_N.png` | 5,861,335 | Rock PBR texture — analyzed, not used; static demo content. |
| `realistic_water_shader/art/rock/Rock_N.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/rock/Rock_R.png` | 535,385 | Rock PBR texture — analyzed, not used; static demo content. |
| `realistic_water_shader/art/rock/Rock_R.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/seaweed/Noise.png` | 365,053 | Seaweed texture/noise — analyzed, not used; demo particle system relies on a static height map. |
| `realistic_water_shader/art/seaweed/Noise.png.import` | 832 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/seaweed/Seaweed.gdshader` | 1,282 | Readable shader source; water shader is adapted into the project. Seaweed sources analyzed but not used (static demo particles). |
| `realistic_water_shader/art/seaweed/Seaweed.material` | 429 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/seaweed/Seaweed.obj` | 2,268 | Imported mesh source; analyzed, not used in the game world. |
| `realistic_water_shader/art/seaweed/Seaweed.obj.import` | 600 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/seaweed/Seaweed_B.png` | 247,531 | Seaweed texture/noise — analyzed, not used; demo particle system relies on a static height map. |
| `realistic_water_shader/art/seaweed/Seaweed_B.png.import` | 843 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/seaweed/Seaweed_N.png` | 235,548 | Seaweed texture/noise — analyzed, not used; demo particle system relies on a static height map. |
| `realistic_water_shader/art/seaweed/Seaweed_N.png.import` | 843 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/seaweed/Seaweed_Process.gdshader` | 1,379 | Readable shader source; water shader is adapted into the project. Seaweed sources analyzed but not used (static demo particles). |
| `realistic_water_shader/art/seaweed/Seaweed_Process.material` | 751 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/seaweed/Seaweed_R.png` | 55,773 | Seaweed texture/noise — analyzed, not used; demo particle system relies on a static height map. |
| `realistic_water_shader/art/seaweed/Seaweed_R.png.import` | 844 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/water/Caustic.png` | 611,398 | Caustic image — copied but not sampled; upstream needs Texture2DArray with 16 slices. |
| `realistic_water_shader/art/water/Caustic.png.import` | 639 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/water/Foam.png` | 44,868 | Water foam mask — copied and used. |
| `realistic_water_shader/art/water/Foam.png.import` | 827 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/water/Water.gdshader` | 7,943 | Readable shader source; water shader is adapted into the project. Seaweed sources analyzed but not used (static demo particles). |
| `realistic_water_shader/art/water/Water.material` | 758 | Binary Godot serialized material (`RSCC`); referenced by the supplied demo scene and inspected by its scene references, not directly reusable as text. |
| `realistic_water_shader/art/water/Water_N_A.png` | 434,018 | Water normal map A — copied and used. |
| `realistic_water_shader/art/water/Water_N_A.png.import` | 842 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/water/Water_N_B.png` | 2,567,980 | Water normal map B — copied and used. |
| `realistic_water_shader/art/water/Water_N_B.png.import` | 843 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/art/water/Water_UV.png` | 552,163 | Water UV distortion texture — copied and used. |
| `realistic_water_shader/art/water/Water_UV.png.import` | 839 | Godot import-cache metadata; intentionally not copied because Godot 4.3 regenerates it for this project. |
| `realistic_water_shader/core/camera.gd` | 1,676 | Readable free-camera controller for the supplied demo; analyzed, not used because the game has a ship-follow camera. |
| `realistic_water_shader/main.tscn` | 6,853 | Supplied static demo scene; analyzed for mesh subdivision, texture wiring, light and environment setup. |
| `realistic_water_shader/water_env.tres` | 663 | Supplied WorldEnvironment resource; analyzed as Godot 4 environment configuration. |

## Godot 4.3 hotfix

Godot 4.3 exposes `TAU` as a built-in shader constant. The first integration accidentally declared it a second time, producing `Redefinition of 'TAU'` and causing the material compiler to fall back instead of rendering water. `RealisticOcean.gdshader` now uses the built-in directly and does not redeclare it.
