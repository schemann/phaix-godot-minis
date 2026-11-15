extends SceneTree
## The proof of the last step of the video (Anything that must survive the change, like a score, has to live outside the rooms, for example in an autoload):
## `godot --headless --path tests/autoload_proof -s res://run_tests.gd`. Exit code 0 when everything holds; `tests/run_tests.gd` of the lesson's project runs it too.
## A value in an autoload is still there after `change_scene_to_file`; a value on a node of the old room is gone with the room.

var failures := 0

func _init() -> void:
	# a proof that waits for a frame that never comes must fail, not hang
	create_timer(20.0).timeout.connect(func() -> void:
		printerr("FAIL: the proof did not finish in 20 seconds")
		quit(1))
	await process_frame
	# the autoload is Godot's own: a setting of the project, a node under the root that the engine added before any scene
	_check(str(ProjectSettings.get_setting("autoload/Score", "")) == "*res://score.gd", "project.godot registers res://score.gd as the autoload Score")
	var score := root.get_node_or_null("Score")
	_check(score != null and score.get_parent() == root, "Score is a child of the root, next to the current scene")
	if score == null:
		print("FAIL, %d failures" % (failures))
		quit(1)
		return
	var room_a := (load("res://room_a.tscn") as PackedScene).instantiate()
	root.add_child(room_a)
	current_scene = room_a
	score.set("points", 7)
	room_a.set("coins", 3)
	_check(score.get("points") == 7 and room_a.get("coins") == 3, "before the change: the score is 7 and the coins on the room are 3")

	# the same call as the door in the lesson: deferred, and the change happens at the end of the frame
	change_scene_to_file.call_deferred("res://room_b.tscn")
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.name == "RoomB", "the current scene is room B now")
	_check(not is_instance_valid(room_a), "room A is gone, and the value on its node went with it")
	var kept: bool = is_instance_valid(score) and root.get_node_or_null("Score") == score and score.get("points") == 7
	_check(kept, "after the change: the same Score node is still under the root and the score is still 7")
	_check(current_scene != null and current_scene.get("coins") == 0, "the new room starts fresh: its coins are 0")

	# and back: the old room loads new, the score is still the one set before the first change
	change_scene_to_file.call_deferred("res://room_a.tscn")
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.name == "RoomA" and current_scene.get("coins") == 0, "back in room A the coins are 0 again, the old 3 did not come back")
	_check(is_instance_valid(score) and score.get("points") == 7, "after the second change the score is still 7")

	print("PASS, 0 failures" if failures == 0 else "FAIL, %d failures" % failures)
	quit(1 if failures > 0 else 0)

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
