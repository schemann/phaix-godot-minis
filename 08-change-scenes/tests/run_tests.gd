extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	var one: Node = (load("res://room_one.tscn") as PackedScene).instantiate()
	root.add_child(one)
	current_scene = one
	await physics_frame
	await physics_frame
	_check(current_scene == one, "nothing changes the scene on its own: the knight and the walls do not touch the door")

	# the knight is an AnimatedSprite2D with idle and walk (mini 02's animation), never the still Sprite2D
	var player := one.get_node("Player") as CharacterBody2D
	var knight := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk"), "the knight is an AnimatedSprite2D with idle and walk")

	# the wall stops the knight below the door's wall: his shape reaches 20 above his position, the wall's foot is at y 64
	for x: float in [-200.0, 0.0, 300.0, 500.0]:
		player.position = Vector2(x, 116.0)
		await _hold(["ui_up"], 120)
		_check(current_scene == one and absf(player.position.y - 84.0) < 1.5, "the wall stops the knight at y 84 at x %.0f, got %.1f" % [x, player.position.y])

	# the shapes, the draw order and the doors follow the pictures of both rooms
	_check_room(one, 92, 180)
	var second: Node = (load("res://room_two.tscn") as PackedScene).instantiate()
	_check_room(second, -164, -76)
	second.free()
	_check(FileAccess.get_file_as_string("res://door.gd").contains(".call_deferred(target)"), "the door defers the scene change: a physics callback may not remove the door that is calling")

	# the door in room one sends the knight to room two, the door in room two back to room one
	var door := one.get_node("Door") as Area2D
	_check(door.target == "res://room_two.tscn", "the door in room one leads to room two")
	player.position = Vector2(door.position.x, 116.0)
	await _hold_until_changed(one, 90)
	var two := current_scene
	_check(two != null and two.name == "RoomTwo" and two != one, "walking into the door loads room two")
	_check(not is_instance_valid(one) or one.is_queued_for_deletion() or one.get_parent() == null, "room one is gone")
	var back := two.get_node("Door") as Area2D
	_check(back.target == "res://room_one.tscn", "the door in room two leads back to room one")
	var other := two.get_node("Player") as CharacterBody2D
	other.position = Vector2(back.position.x, 116.0)
	await _hold_until_changed(two, 90)
	_check(current_scene != null and current_scene.name == "RoomOne", "walking into the door in room two loads room one again")
	_check(current_scene.get_node("Player").position == Vector2(-200.0, 116.0), "the knight in the new room one starts where the scene puts him")

	# the last step of the video: a value in an autoload survives the change, a value on a node of the old room does not. `tests/autoload_proof` is a project of its own with the one
	# autoload Score (this project has none), run by a second Godot; its cache folder is removed again so nothing of it is left in the tree.
	var proof_output: Array = []
	var proof_path := ProjectSettings.globalize_path("res://tests/autoload_proof")
	var proof_code := OS.execute(OS.get_executable_path(), ["--headless", "--path", proof_path, "-s", "res://run_tests.gd"], proof_output, true)
	_remove_dir(proof_path.path_join(".godot"))
	_check(proof_code == 0 and "\n".join(proof_output).contains("PASS, 0 failures"), "the autoload proof holds (a value in the autoload survives change_scene_to_file, a value on the old room's node is gone): exit %d, %s" % [proof_code, "\n".join(proof_output).strip_edges().right(400)])

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

## The shapes follow what the picture shows (the walls stop at the doorway's edges, the door's zone lies in the opening and touches no wall) and the wall and the arch sort at the
## foot of the wall less the knight's feet (series rule 65). `hole_left` and `hole_right` are the opening's edges in world pixels.
func _check_room(room: Node, hole_left: int, hole_right: int) -> void:
	var picture := ((room.get_node("Picture") as Sprite2D).texture as Texture2D).get_image()
	var dark := Color8(34, 32, 36)
	var y := 320 + 20
	_check(picture.get_pixel(640 + hole_left + 2, y).is_equal_approx(dark) and not picture.get_pixel(640 + hole_left - 2, y).is_equal_approx(dark), "%s: the opening starts at x %d in the picture" % [room.name, hole_left])
	_check(picture.get_pixel(640 + hole_right - 2, y).is_equal_approx(dark) and not picture.get_pixel(640 + hole_right + 2, y).is_equal_approx(dark), "%s: the opening ends at x %d in the picture" % [room.name, hole_right])
	var left := _rect(room.get_node("Walls/ShapeWallLeft") as CollisionShape2D, Vector2.ZERO)
	var right := _rect(room.get_node("Walls/ShapeWallRight") as CollisionShape2D, Vector2.ZERO)
	_check(is_equal_approx(left.end.x, hole_left) and is_equal_approx(right.position.x, hole_right), "%s: the wall shapes stop at the opening's edges" % room.name)
	var door := room.get_node("Door") as Area2D
	var zone := _rect(door.get_node("CollisionShape2D") as CollisionShape2D, door.position)
	_check(zone.position.x > hole_left and zone.end.x < hole_right, "%s: the door's zone lies inside the opening" % room.name)
	for wall: Node in room.get_node("Walls").get_children():
		_check(not zone.intersects(_rect(wall as CollisionShape2D, Vector2.ZERO)), "%s: the door's zone touches no wall (%s): an Area2D reports a StaticBody2D it overlaps at once" % [room.name, wall.name])
	var front := room.get_node("WallFront") as Sprite2D
	var arch := room.get_node("Arch") as Sprite2D
	_check((room as Node2D).y_sort_enabled and room.get_node("Picture").z_index < 0, "%s: the room sorts its children by y and its picture is below the knight" % room.name)
	_check(is_equal_approx(front.position.y, 20.0) and is_equal_approx(front.position.y + front.offset.y, 0.0), "%s: the wall front sorts at the foot of the wall less the knight's feet and is drawn where the picture has it" % room.name)
	_check(is_equal_approx(arch.position.y, 20.0) and is_equal_approx(arch.position.y + arch.offset.y, -70.0) and is_equal_approx(arch.position.x, (hole_left + hole_right) / 2.0 - 8.0), "%s: the arch sorts with the wall and stands over the door" % room.name)

func _rect(shape: CollisionShape2D, offset: Vector2) -> Rect2:
	var size := (shape.shape as RectangleShape2D).size
	return Rect2(offset + shape.position - size / 2.0, size)

## Holds the actions for `ticks` physics frames.
func _hold(actions: Array[String], ticks: int) -> void:
	for action in actions:
		Input.action_press(action)
	for i in ticks:
		await physics_frame
	for action in actions:
		Input.action_release(action)

## Holds up until the scene is not `old` any more (the change happens at the end of a frame), then lets go at once.
func _hold_until_changed(old: Node, ticks: int) -> void:
	Input.action_press("ui_up")
	for i in ticks:
		await physics_frame
		if current_scene != old:
			break
	Input.action_release("ui_up")
	await physics_frame

## Removes a folder and everything in it (the cache of the autoload proof's project).
func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for entry in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(entry))
	for entry in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(entry))
	DirAccess.remove_absolute(path)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
