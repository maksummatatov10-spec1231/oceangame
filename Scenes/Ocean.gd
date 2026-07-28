extends Node3D

const OCEAN_TILE := preload("res://Scenes/RealisticWaterPlane.tscn")
# A uniform near-field grid avoids the visible LOD ring produced when very tall
# vertex waves meet the low-subdivision outer tiles of the original demo.
const TILE_SIZE := 80.0
const TILES_PER_AXIS := 3
const TILE_SUBDIVISIONS := 128
const HALF_GRID := 1

func _ready() -> void:
    create_ocean_tiles()

# An endless, camera-centred ocean: every tile has identical geometry density,
# so the shader displacement is continuous across each seam.
func create_ocean_tiles() -> void:
    for child in get_children():
        child.queue_free()
    for grid_x in range(-HALF_GRID, HALF_GRID + 1):
        for grid_z in range(-HALF_GRID, HALF_GRID + 1):
            var tile: MeshInstance3D = OCEAN_TILE.instantiate() as MeshInstance3D
            var plane: PlaneMesh = tile.mesh as PlaneMesh
            plane.size = Vector2(TILE_SIZE, TILE_SIZE)
            plane.subdivide_width = TILE_SUBDIVISIONS
            plane.subdivide_depth = TILE_SUBDIVISIONS
            tile.position = Vector3(grid_x * TILE_SIZE, 0.0, grid_z * TILE_SIZE)
            add_child(tile)

func _process(_delta: float) -> void:
    # Preserved for compatibility with the original extracted ocean shader.
    RenderingServer.global_shader_parameter_set("ocean_pos", global_position)
