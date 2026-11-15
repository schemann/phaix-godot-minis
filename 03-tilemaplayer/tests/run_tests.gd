extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0
var main: Node2D
var tiles: TileMapLayer
var player: CharacterBody2D

func _init() -> void:
	await process_frame
	await _load_level()

	# the knight is an AnimatedSprite2D with idle and walk (mini 02's animation), never the still Sprite2D
	var knight := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk"), "the knight is an AnimatedSprite2D with idle and walk")
	_check(player.get_node_or_null("Sprite2D") == null, "the player has no still Sprite2D")

	# The TileSet: one physics layer, a polygon on the wall tile and none on the floor tile.
	var tile_set: TileSet = tiles.tile_set
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	_check(tile_set.get_physics_layers_count() == 1, "the TileSet has a physics layer")
	_check(atlas.get_tile_data(Vector2i(0, 0), 0).get_collision_polygons_count(0) == 1, "the wall tile has a collision polygon")
	_check(atlas.get_tile_data(Vector2i(1, 0), 0).get_collision_polygons_count(0) == 0, "the floor tile has none")
	_check(atlas.get_tile_data(Vector2i(3, 0), 0).get_collision_polygon_points(0, 0)[2].x == 12.0, "the side piece's polygon is as wide as its strip")

	# The painted level: the ring is wall, the room inside is floor.
	_check(tiles.get_cell_atlas_coords(Vector2i(0, 0)) == Vector2i(4, 0) and tiles.get_cell_atlas_coords(Vector2i(15, 8)) == Vector2i(2, 1), "the corners are the pack's corner tiles")
	_check(tiles.get_cell_atlas_coords(Vector2i(2, 2)) == Vector2i(1, 0), "the room is floor")
	_check(tiles.get_cell_source_id(Vector2i(40, 40)) == -1, "a cell nobody painted has source id -1")

	# The player stops at a painted wall: along row 1 to the right, the east wall's strip begins at x = 980. Its shape sits at the knight's feet, 16 px below the origin.
	player.position = Vector2(160.0, 100.0)
	await _hold(["ui_right"], 300)
	_check(absf(player.position.x - 948.0) < 2.0, "it stops at the east wall, got %.1f" % player.position.x)

	# ... and at a wall in the middle of the room: down from row 1 onto the bar in row 3.
	player.position = Vector2(480.0, 96.0)
	await _hold(["ui_down"], 120)
	_check(absf(player.position.y - 148.0) < 2.0, "it stops on top of the bar, got %.1f" % player.position.y)

	# A tile placed from code: two cells to the right of the player, and it blocks like a painted one.
	await _load_level()
	var before := tiles.get_cell_atlas_coords(Vector2i(4, 2))
	_check(before == Vector2i(1, 0), "cell (4, 2) is floor before")
	await _press("ui_accept")
	_check(tiles.get_cell_atlas_coords(Vector2i(4, 2)) == Vector2i(0, 0), "cell (4, 2) is a wall tile after Space")
	await _hold(["ui_right"], 120)
	_check(absf(player.position.x - 224.0) < 2.0, "it stops at the placed tile, got %.1f" % player.position.x)

	# The Short's scene: with its Tile Set's physics layer removed the player walks through the wall, with its own Tile Set it stops again.
	main.queue_free()
	main = null
	await process_frame
	_check(ResourceLoader.exists("res://short/ghost_walls.tscn"), "the Short's scene short/ghost_walls.tscn exists")
	if ResourceLoader.exists("res://short/ghost_walls.tscn"):
		var ghost_walls: Node = (load("res://short/ghost_walls.tscn") as PackedScene).instantiate()
		root.add_child(ghost_walls)
		var ghost_tiles: TileMapLayer = ghost_walls.get_node("Tiles")
		var ghost_player: CharacterBody2D = ghost_walls.get_node("Player")
		await physics_frame
		ghost_walls.call("ghost")
		_check(ghost_tiles.tile_set.get_physics_layers_count() == 0 and ghost_tiles.collision_enabled, "the Short's Tile Set has no physics layer while it is a ghost, and the layer's collision stays on")
		ghost_player.position = Vector2(160.0, 100.0)
		await _hold(["ui_right"], 300)
		_check(ghost_player.position.x > 960.0, "without the physics layer it walks through the east wall, got %.1f" % ghost_player.position.x)
		ghost_walls.call("solid")
		_check(ghost_tiles.tile_set.get_physics_layers_count() == 1, "the Short's own Tile Set has its physics layer back")
		ghost_player.position = Vector2(160.0, 100.0)
		await _hold(["ui_right"], 300)
		_check(absf(ghost_player.position.x - 948.0) < 2.0, "with its physics layer back it stops at the east wall, got %.1f" % ghost_player.position.x)
		ghost_walls.queue_free()
		await process_frame

	# The trick of the Short: a tile without a collision polygon does not block.
	await _load_level()
	atlas = (tiles.tile_set as TileSet).get_source(0) as TileSetAtlasSource
	for index in atlas.get_tiles_count():
		atlas.get_tile_data(atlas.get_tile_id(index), 0).set_collision_polygons_count(0, 0)
	await physics_frame
	await physics_frame
	await _hold(["ui_right"], 300)
	_check(player.position.x > 960.0, "without the polygon it walks through the wall, got %.1f" % player.position.x)

	var camera: Camera2D = player.get_node("Camera2D")
	player.position = Vector2(930.0, 500.0)
	for i in 120:
		await physics_frame
	var seen := camera.get_screen_center_position() + Vector2(640.0, 360.0) / camera.zoom
	_check(seen.x <= 1024.5 and seen.y <= 576.5, "the picture stops at the walls, it reaches %s" % seen)

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _load_level() -> void:
	if main != null:
		main.queue_free()
		await process_frame
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	tiles = main.get_node("Tiles")
	player = main.get_node("Player")
	await physics_frame
	await physics_frame

func _press(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await physics_frame
		await process_frame

func _hold(actions: Array, ticks: int) -> void:
	for action: String in actions:
		Input.action_press(action)
	for i in ticks:
		await physics_frame
	for action: String in actions:
		Input.action_release(action)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
