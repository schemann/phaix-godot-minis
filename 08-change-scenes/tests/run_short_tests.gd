extends SceneTree
## The check of the Short's demo (series rule 50): `godot --headless --path . -s tests/run_short_tests.gd`. Exit code 0 when everything holds.
## A door that calls change_scene_to_file inside body_entered takes its room out of the tree before the signal has reached the next listener and the engine prints
## its error; a door that defers the call finishes the signal first and prints nothing. The readout shows exactly that, taken from the real signals and the real Logger.

var failures := 0

func _init() -> void:
	await process_frame
	await _crossing("res://short/bug_one.tscn", "RoomTwo", "the bug door")
	var bug_rows := _rows()
	print("bug rows: ", bug_rows)
	_check(bug_rows.size() == 3, "the bug door's group has three lines, got %s" % [bug_rows])
	_check(bug_rows.size() == 3 and bug_rows[0].begins_with("ERROR: Removing a CollisionObject node during a physics callback is not allowed"), "first: the engine's error, printed while the door is being removed")
	_check(bug_rows.size() == 3 and bug_rows[1] == "RoomOne.tree_exiting", "second: the room leaves the tree")
	_check(bug_rows.size() == 3 and bug_rows[2] == "Door.body_entered(Player)", "last: the signal reaches the next listener, after all of that")
	await _crossing("res://short/fix_one.tscn", "RoomTwo", "the fixed door")
	var fix_rows := _rows()
	_check(fix_rows == ["Door.body_entered(Player)", "RoomOne.tree_exiting"], "the fixed door: the signal first, then the room leaves, no error, got %s" % [fix_rows])
	print("PASS, 0 failures" if failures == 0 else "FAIL, %d failures" % failures)
	quit(1 if failures > 0 else 0)

## Plays the first door of `scene` (the knight stands under it) until the scene is `expected` and lets the next frames pass.
func _crossing(scene: String, expected: String, what: String) -> void:
	for child in root.get_children():
		if child.name == "DemoConsole":
			continue
		if child != root and child is Node2D:
			child.queue_free()
	await process_frame
	var room: Node = (load(scene) as PackedScene).instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	await process_frame
	var player := room.get_node("Player") as CharacterBody2D
	var door := room.get_node("Door") as Area2D
	player.position = Vector2(door.position.x, 86.0)
	Input.action_press("ui_up")
	for _i in 120:
		await physics_frame
		if current_scene != room:
			break
	Input.action_release("ui_up")
	for _i in 3:
		await physics_frame
		await process_frame
	_check(current_scene != null and current_scene.name == expected, "%s: the scene is %s" % [what, expected])

func _rows() -> Array[String]:
	var console := root.get_node("DemoConsole")
	return console.get("rows")

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", text)
