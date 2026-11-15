extends SceneTree
## The check of the Short's demo (short/): `godot --headless --path . -s tests/run_short_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	Input.use_accumulated_input = false

	# short/player_bug.gd is player.gd without the clamp line and nothing else
	var real := FileAccess.get_file_as_string("res://player.gd")
	var bug := FileAccess.get_file_as_string("res://short/player_bug.gd")
	var clamp := "\t\tcamera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))\n"
	_check(real.contains(clamp) and real.replace(clamp, "") == bug, "short/player_bug.gd is player.gd without the clampf line")

	# the bug: the pitch keeps adding up past 90 degrees and the view is upside down
	var world: Node = (load("res://short/bug.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var player := world.get_node("Player") as CharacterBody3D
	var camera := player.get_node("Camera3D") as Camera3D
	var readout := world.get_node("Readout")
	_check(player.get_script().resource_path == "res://short/player_bug.gd", "the bug scene's Player runs the script without the clamp")
	for i in 30:
		_mouse(Vector2(0.0, -10.0))
	await _frames()
	_check(absf(camera.rotation_degrees.x - 51.57) < 0.1, "300 pixels up tilt the camera by 300 x sensitivity, about 51.6 degrees, got %.2f" % camera.rotation_degrees.x)
	_check(camera.global_transform.basis.y.y > 0.0, "the view is still upright below 90 degrees")
	for i in 40:
		_mouse(Vector2(0.0, -10.0))
	await _frames()
	_check(camera.rotation_degrees.x > 100.0 and camera.global_transform.basis.y.y < 0.0, "without the clamp the pitch passes 90 degrees and the view is upside down, got %.1f" % camera.rotation_degrees.x)
	var pitch_label := readout.get("_pitch") as Label
	_check(pitch_label.text.begins_with("+") and pitch_label.text.to_float() > 100.0, "the readout shows the real pitch, got " + pitch_label.text)
	_check(pitch_label.get_theme_color("font_color").r > 0.9 and pitch_label.get_theme_color("font_color").g < 0.5, "the pitch is red while the view is upside down")
	world.free()
	await process_frame

	# the fix: the project's own player stops at 80 degrees and the view stays upright
	var fixed: Node = (load("res://short/clamp.tscn") as PackedScene).instantiate()
	root.add_child(fixed)
	await physics_frame
	await physics_frame
	var fixed_player := fixed.get_node("Player") as CharacterBody3D
	var fixed_camera := fixed_player.get_node("Camera3D") as Camera3D
	_check(fixed_player.get_script().resource_path == "res://player.gd", "the clamp scene's Player runs the project's own script")
	for i in 150:
		_mouse(Vector2(0.0, -10.0))
	await _frames()
	_check(absf(fixed_camera.rotation_degrees.x - 80.0) < 0.001 and fixed_camera.global_transform.basis.y.y > 0.0, "with the clamp the pitch stops at 80 and the view stays upright, got %.3f" % fixed_camera.rotation_degrees.x)
	_check((fixed.get_node("Readout").get("_pitch") as Label).text == "+80.0°", "the readout shows +80.0 at the limit, got " + (fixed.get_node("Readout").get("_pitch") as Label).text)
	fixed.free()

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _frames() -> void:
	await process_frame
	await process_frame

func _mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.screen_relative = relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
