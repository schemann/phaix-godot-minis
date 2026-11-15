extends Node2D

const FLOOR := Vector2i(1, 0)
const WALL := Vector2i(0, 0)

@onready var tiles: TileMapLayer = $Tiles
@onready var player: CharacterBody2D = $Player

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var cell := tiles.local_to_map(player.position) + Vector2i(2, 0)
		if tiles.get_cell_atlas_coords(cell) == FLOOR:
			tiles.set_cell(cell, 0, WALL)
