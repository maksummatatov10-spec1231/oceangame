extends Node3D

const OCEAN_TILE := preload("res://Scenes/WaterPlane.tscn")
const SPAWN_INFO := preload("res://Resources/GridSpawnInfo.tres")

# Builds the 17-tile LOD layout supplied with the original ocean asset.
func _ready() -> void:
    create_ocean_tiles()

func create_ocean_tiles() -> void:
    for child in get_children():
        child.queue_free()
    # GridSpawnInfo is a scripted Resource; get() keeps this scene independent
    # from editor load order while retaining the source asset's exact layout.
    var spawn_points: Array = SPAWN_INFO.get("spawnPoints")
    var subdivision_levels: Array = SPAWN_INFO.get("subdivision")
    var tile_scales: Array = SPAWN_INFO.get("scale")
    for index in spawn_points.size():
        var spawn_location: Vector2 = spawn_points[index]
        var subdivisions: int = subdivision_levels[index]
        var tile_scale: int = tile_scales[index]
        var tile: MeshInstance3D = OCEAN_TILE.instantiate() as MeshInstance3D
        var plane: PlaneMesh = tile.mesh as PlaneMesh
        add_child(tile)
        tile.position = Vector3(spawn_location.x, 0.0, spawn_location.y) * 10.05
        plane.subdivide_width = subdivisions
        plane.subdivide_depth = subdivisions
        tile.scale = Vector3(tile_scale, 1.0, tile_scale)

func _process(_delta: float) -> void:
    RenderingServer.global_shader_parameter_set("ocean_pos", global_position)
