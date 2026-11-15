extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

var failures := 0

func _init() -> void:
	await process_frame
	Input.use_accumulated_input = false
	var world: Node = (load("res://world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame

	# the Player is a CharacterBody3D with a capsule 1.8 m tall and the camera at eye height, standing on the floor
	var player := world.get_node("Player") as CharacterBody3D
	var camera := player.get_node("Camera3D") as Camera3D
	var capsule := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	_check(player != null and camera != null and capsule != null, "the Player is a CharacterBody3D with a Camera3D and a capsule")
	_check(is_equal_approx(capsule.height, 1.8) and is_equal_approx(capsule.radius, 0.4), "the capsule is 1.8 m tall and 0.4 m wide")
	_check(is_equal_approx(camera.position.y, 1.6), "the camera sits at the height of the eyes, 1.6 m")
	_check(is_equal_approx(player.position.y, 0.0) and is_equal_approx((player.get_node("CollisionShape3D") as Node3D).position.y - capsule.height / 2.0, 0.0), "the capsule stands on the floor, whose top is at y 0")
	_check(FileAccess.get_file_as_string("res://player.gd").contains("Input.mouse_mode = Input.MOUSE_MODE_CAPTURED"), "_ready captures the mouse (a headless run has no mouse to read back)")

	# the mouse turns the whole Player left and right (yaw) and only the camera up and down (pitch)
	var start := player.rotation.y
	_mouse(Vector2(100.0, 0.0))
	_check(absf((player.rotation.y - start) + 100.0 * player.sensitivity) < 0.0001, "100 pixels to the right turn the Player by 100 x sensitivity, clockwise from above")
	_check(is_zero_approx(camera.rotation.x) and is_zero_approx(camera.rotation.y), "a sideways move leaves the camera alone")
	var yaw := player.rotation.y
	_mouse(Vector2(0.0, -100.0))
	_check(is_equal_approx(player.rotation.y, yaw), "an up and down move leaves the Player's yaw alone")
	_check(absf(camera.rotation.x - 100.0 * player.sensitivity) < 0.0001, "100 pixels up tilt the camera up by 100 x sensitivity")

	# the pitch is clamped at 80 degrees, up and down, in small steps and in one big one
	for i in 400:
		_mouse(Vector2(0.0, -20.0))
	_check(absf(camera.rotation_degrees.x - 80.0) < 0.001, "looking up stops at 80 degrees, got %.3f" % camera.rotation_degrees.x)
	for i in 800:
		_mouse(Vector2(0.0, 20.0))
	_check(absf(camera.rotation_degrees.x + 80.0) < 0.001, "looking down stops at minus 80 degrees, got %.3f" % camera.rotation_degrees.x)
	_mouse(Vector2(0.0, -2000.0))
	_check(camera.global_transform.basis.y.y > 0.0, "a flick of 2000 pixels leaves the view upright")
	_check(is_zero_approx(player.rotation.x) and is_zero_approx(player.rotation.z), "the body never tips over, only the camera tilts (the voice says so)")

	# W moves along the direction the Player faces, A and D to its sides
	player.position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	await _hold("move_forward", 30)
	_check(player.position.z < -1.0 and absf(player.position.x) < 0.001, "W walks away along minus Z when the Player faces minus Z, now at z %.2f" % player.position.z)
	player.position = Vector3.ZERO
	player.rotation.y = deg_to_rad(90.0)
	await _hold("move_forward", 30)
	_check(player.position.x < -1.0 and absf(player.position.z) < 0.001, "after a quarter turn to the left, W walks along minus X, now at x %.2f" % player.position.x)
	player.position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	await _hold("move_right", 30)
	_check(player.position.x > 1.0, "D walks to the right")
	player.position = Vector3.ZERO
	await _hold("move_left", 30)
	_check(player.position.x < -1.0, "A walks to the left")
	player.position = Vector3.ZERO
	await _hold("move_back", 30)
	_check(player.position.z > 1.0, "S walks backwards")
	_check(absf(player.position.y) < 0.01, "the Player stays on the floor, y %.4f" % player.position.y)

	# the voice says: get_vector never returns more than one, so walking diagonally is not faster, also when the Player faces any way
	for facing in [0.0, 37.0, 90.0, 215.0]:
		player.position = Vector3.ZERO
		player.rotation = Vector3(0.0, deg_to_rad(facing), 0.0)
		var straight := await _speed_while_holding(player, ["move_forward"])
		var diagonal := await _speed_while_holding(player, ["move_forward", "move_right"])
		_check(absf(straight - player.speed) < 0.001, "W alone walks at the speed, %.4f at %.0f degrees" % [straight, facing])
		_check(absf(diagonal - player.speed) < 0.001, "W and D together walk at the same speed, %.4f at %.0f degrees" % [diagonal, facing])
	# the voice says: there is no gravity in this script, so it is made for a flat floor (the vertical velocity is always 0 and a Player in the air stays there)
	player.position = Vector3(0.0, 3.0, 0.0)
	player.rotation = Vector3.ZERO
	var vertical := absf(await _speed_while_holding(player, ["move_forward", "move_right"], true))
	for i in 60:
		await physics_frame
	_check(vertical == 0.0 and absf(player.velocity.y) == 0.0, "velocity.y is 0 while walking and standing")
	_check(absf(player.position.y - 3.0) < 0.0001, "a Player 3 m above the floor does not fall, y %.4f" % player.position.y)

	# a box stops the Player
	player.position = Vector3(4.5, 0.0, 0.0)
	player.rotation = Vector3.ZERO
	await _hold("move_forward", 150)
	_check(absf(player.position.z - (-9.0 + 0.6 + 0.4)) < 0.1, "the crate at z minus 9 stops the Player at its face plus the capsule's radius, now at z %.2f" % player.position.z)

	# the voice says: move_and_slide slides along walls instead of sticking to them. W and D together into the crate's face (z minus 8.4, x 3.9 to 5.1): the
	# Player stays in front of the face and keeps moving along it to the right. A body that stopped dead at the face would stay at the x where it touched.
	player.position = Vector3(4.0, 0.0, -7.8)
	player.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	Input.action_press("move_right")
	for i in 16:
		await physics_frame
	var along := player.velocity
	Input.action_release("move_forward")
	Input.action_release("move_right")
	await physics_frame
	_check(player.position.z > -8.01, "the crate stops the Player in front of its face, z %.3f" % player.position.z)
	_check(player.position.x > 4.8, "walking diagonally into the crate, the Player slides along its face to x %.3f (it touched at x 4.2)" % player.position.x)
	_check(absf(along.x) > 3.0 and absf(along.z) < 0.5, "while it slides, the velocity runs along the face, (%.2f, %.2f)" % [along.x, along.z])

	_check(FileAccess.get_file_as_string("res://player.gd").split("\n").size() == 22, "player.gd is 21 lines (the voice says so): " + str(FileAccess.get_file_as_string("res://player.gd").split("\n").size() - 1))

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

## One mouse event as the player gets it.
func _mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.screen_relative = relative
	Input.parse_input_event(event)
	Input.flush_buffered_events()

## Holds an action for `ticks` physics frames.
func _hold(action: String, ticks: int) -> void:
	Input.action_press(action)
	for i in ticks:
		await physics_frame
	Input.action_release(action)
	await physics_frame

## Holds the actions for 10 physics frames and returns the Player's speed on the floor plane (or its vertical speed) at the end.
func _speed_while_holding(player: CharacterBody3D, actions: Array, vertical := false) -> float:
	for a in actions:
		Input.action_press(a)
	for i in 10:
		await physics_frame
	var v := player.velocity
	for a in actions:
		Input.action_release(a)
	await physics_frame
	return v.y if vertical else Vector2(v.x, v.z).length()

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
