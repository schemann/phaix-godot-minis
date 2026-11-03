extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var player: CharacterBody2D = main.get_node("Player")
	await physics_frame

	var start := player.position
	await _hold(["ui_right"], 30)
	_check(absf(player.position.x - start.x - 150.0) < 20.0, "half a second to the right covers half of speed, got %.1f" % (player.position.x - start.x))
	await _hold([], 2)
	var stopped := player.position
	await _hold([], 10)
	_check(player.position == stopped, "it stops when the keys are let go")

	start = player.position
	await _hold(["ui_right", "ui_down"], 30)
	_check(absf((player.position - start).length() - 150.0) < 20.0, "a diagonal is not faster, got %.1f" % (player.position - start).length())

	player.position = Vector2(740.0, 0.0)
	await _hold(["ui_right", "ui_down"], 30)
	_check(player.position.x <= 757.0 and player.position.y > 50.0, "against the wall it slides along it, got %s" % player.position)

	var camera: Camera2D = player.get_node("Camera2D")
	player.position = Vector2(740.0, 390.0)
	await _hold([], 120)
	var seen := camera.get_screen_center_position() + Vector2(640.0, 360.0) / camera.zoom
	_check(seen.x <= 812.5 and seen.y <= 512.5, "the picture stops at the walls, it reaches %s" % seen)

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

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
