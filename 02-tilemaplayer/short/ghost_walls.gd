extends "res://main.gd"
## The Short's scene: the same level, switched between its Tile Set and a copy whose physics layer is removed, as before step one.

var _solid: TileSet
var _ghost: TileSet

func _ready() -> void:
	_solid = tiles.tile_set
	_ghost = _solid.duplicate(true)
	_ghost.remove_physics_layer(0)

func ghost() -> void:
	tiles.tile_set = _ghost

func solid() -> void:
	tiles.tile_set = _solid
