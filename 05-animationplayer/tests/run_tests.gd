extends SceneTree
## The project's check: `godot --headless --path . -s tests/run_tests.gd`. Exit code 0 when everything holds.

const CLOSED := Color(0.949, 0.549, 0.157)
const OPEN := Color(0.3, 0.85, 0.45)

var failures := 0

func _init() -> void:
	await process_frame
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	var gate: AnimatableBody2D = main.get_node("Doorway/Gate")
	var player: CharacterBody2D = main.get_node("Player")
	var animation_player: AnimationPlayer = gate.get_node("AnimationPlayer")

	var animation := animation_player.get_animation("open")
	_check(animation != null and animation.get_track_count() == 2, "the animation open has two tracks")
	_check(animation.track_get_path(0) == NodePath(".:position") and animation.track_get_key_count(0) == 2, "track 0 is the position with two keyframes")
	_check(animation.track_get_path(1) == NodePath(".:modulate") and animation.track_get_key_count(1) == 2, "track 1 is the colour with two keyframes")
	_check(animation.track_get_key_time(0, 0) == 0.0 and is_equal_approx(animation.track_get_key_time(0, 1), animation.length), "the keys sit at 0 s and at the end")
	_check(is_equal_approx(animation.length, 1.0), "the animation is one second long")
	_check(absf(animation.track_get_key_value(0, 1).y + 96.0) < 0.01, "the position key at the end is 96 up")
	_check(gate.position == Vector2.ZERO and _same(gate.modulate, CLOSED), "the gate starts closed and orange")

	# the knight is an AnimatedSprite2D with idle and walk (mini 02's animation), never the still Sprite2D
	var knight := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(knight != null and knight.sprite_frames.has_animation("idle") and knight.sprite_frames.has_animation("walk"), "the knight is an AnimatedSprite2D with idle and walk")

	# the wall across the room and the one behind it run into the side walls, in the picture and in the shapes: cap stone next to each side wall's strip, no gap
	var picture := (load("res://art/room_gate.png") as Texture2D).get_image()
	for face_y: int in [64, 112]:
		for x: int in [12, 305]:
			var seen := picture.get_pixel(x * 4 + 2, (face_y - 2) * 4 + 2)
			_check(seen.is_equal_approx(Color8(170, 141, 122)), "the wall with its face at y %d runs into the side wall: cap stone expected at x %d, got %s" % [face_y, x, seen])
	var walls: Node = main.get_node("Room/Walls")
	var side_left: CollisionShape2D = walls.get_node("ShapeLeft")
	var side_right: CollisionShape2D = walls.get_node("ShapeRight")
	var door_left: CollisionShape2D = walls.get_node("ShapeWallLeft")
	var door_right: CollisionShape2D = walls.get_node("ShapeWallRight")
	var strip_left := side_left.position.x + (side_left.shape as RectangleShape2D).size.x / 2.0
	var strip_right := side_right.position.x - (side_right.shape as RectangleShape2D).size.x / 2.0
	_check(is_equal_approx(door_left.position.x - (door_left.shape as RectangleShape2D).size.x / 2.0, strip_left), "the shape left of the door starts at the left side wall's strip (%.0f), got %.0f" % [strip_left, door_left.position.x - (door_left.shape as RectangleShape2D).size.x / 2.0])
	_check(is_equal_approx(door_right.position.x + (door_right.shape as RectangleShape2D).size.x / 2.0, strip_right), "the shape right of the door ends at the right side wall's strip (%.0f), got %.0f" % [strip_right, door_right.position.x + (door_right.shape as RectangleShape2D).size.x / 2.0])

	# draw order (rule 41): the main scene and the room sort their children by y, and the wall in front of the knight and the arch sort at the foot of the wall (y 64)
	# less the 44 px between his position and his feet, so a knight whose feet are north of the wall is drawn behind its cap and the arch, a knight south of it in front
	var room: Node2D = main.get_node("Room")
	var front: Sprite2D = room.get_node("WallFront")
	var arch: Sprite2D = room.get_node("Arch")
	_check(main.y_sort_enabled and room.y_sort_enabled, "the main scene and the room sort their children by y")
	_check(is_equal_approx(front.position.y, 64.0 - 44.0) and is_equal_approx(arch.position.y, front.position.y), "the wall front and the arch sort at the foot of the wall less the knight's feet (y 20), got %.0f and %.0f" % [front.position.y, arch.position.y])
	_check(front.z_index == player.z_index and arch.z_index == player.z_index and room.get_node("Picture").z_index < player.z_index, "the picture is below the knight, the wall front and the arch sort with him")
	_check(is_equal_approx(front.position.y + front.offset.y, 0.0) and is_equal_approx(arch.position.y + arch.offset.y, -70.0), "the offsets keep the wall front and the arch where they were drawn")
	# the raised gate is in front of the knight in the doorway (Daniel, 2026-11-04, godot-mini-05 review point 1 at 9.0 s: "das gate sollte vor dem spieler sein und nicht dahinter, z sort problem"):
	# the gate sits in a mask of the opening that sorts at y 0, so a knight whose position is north of it is drawn behind the green bar, one south of it (waiting at the closed gate) in front of the door
	var doorway := main.get_node("Doorway") as Polygon2D
	_check(gate.get_parent() == doorway and doorway.clip_children == CanvasItem.CLIP_CHILDREN_ONLY, "the gate sits in the doorway's mask, clipped to the opening")
	_check(is_equal_approx(doorway.position.y, 0.0) and gate.z_index == player.z_index and doorway.z_index == player.z_index, "the doorway sorts at y 0 with the knight and the gate draws with him, not behind the picture")
	var hole_left := doorway.polygon[0].x
	var hole_right := doorway.polygon[1].x
	_check(picture.get_pixel(640 + int(hole_left) + 2, 448 - 20).a == 0.0 and picture.get_pixel(640 + int(hole_left) - 2, 448 - 20).a > 0.99, "the mask's left edge is the opening's left edge in the picture")
	_check(picture.get_pixel(640 + int(hole_right) - 2, 448 - 20).a == 0.0 and picture.get_pixel(640 + int(hole_right) + 2, 448 - 20).a > 0.99, "the mask's right edge is the opening's right edge in the picture")
	var wall_image := front.texture.get_image()
	_check(wall_image.get_pixel(200, 500).is_equal_approx(picture.get_pixel(200, 500)) and wall_image.get_pixel(200, 500).a > 0.99, "the wall front is the picture's wall pixel for pixel (x 200, y 500)")
	_check(wall_image.get_pixel(200, 100).a == 0.0 and picture.get_pixel(200, 100).a > 0.99, "the wall front has no floor: it is clear where the picture shows floor (x 200, y 100)")
	_check(wall_image.get_pixel(648, 460).a == 0.0 and picture.get_pixel(648, 460).a == 0.0, "the door's hole stays clear in the wall front (x 648, y 460)")

	# the wall left and right of the door stops the player below it: his shape reaches 20 above his position, the wall's foot is at y 64
	for x: float in [-200.0, 200.0]:
		player.position = Vector2(x, 110.0)
		await _hold(["ui_up"], 120)
		_check(absf(player.position.y - 84.0) < 1.5, "the wall stops the player at y 84 at x %.0f, got %.1f" % [x, player.position.y])

	# the closed gate stops him from the south in the door, his feet on the sill: the gate's shape ends at y -4, his shape starts 20 above him
	player.position = Vector2(8.0, 110.0)
	await _hold(["ui_up"], 180)
	_check(absf(player.position.y - 16.0) < 0.5 and absf(player.position.x - 8.0) < 1.0, "the closed gate stops the player at the door (8, 16), got %s" % player.position)

	# the corridor behind the wall, gate closed: walking down stops on the gate and on the wall at the same y, his shape's foot on y -12
	var stops: Array[float] = []
	for x: float in [8.0, 200.0]:
		player.position = Vector2(x, -70.0)
		await _hold(["ui_down"], 60)
		stops.append(player.position.y)
		_check(absf(player.position.y + 56.0) < 0.5, "the closed gate and the wall stop the player at y -56 at x %.0f, got %.1f" % [x, player.position.y])
	_check(absf(stops[0] - stops[1]) < 0.01, "the closed gate and the wall stop him at the same y, got %.3f and %.3f" % [stops[0], stops[1]])

	# the walk along the corridor at y -66 passes the door column without stopping, the gate closed
	await _walk_across(player, -66.0, "the gate closed")

	await _press("ui_accept")
	_check(animation_player.current_animation == "open" and animation_player.get_playing_speed() > 0.0, "the first press plays open forwards")
	await create_timer(0.5).timeout
	_check(gate.position.y < -24.0 and gate.position.y > -72.0, "halfway the gate is halfway up, got %.1f" % gate.position.y)
	_check(not _same(gate.modulate, CLOSED) and not _same(gate.modulate, OPEN), "halfway the colour is in between")
	await create_timer(0.8).timeout
	_check(gate.position.is_equal_approx(Vector2(0.0, -96.0)) and _same(gate.modulate, OPEN), "the gate slid up and turned green, got %s" % gate.position)

	# the corridor, gate raised: walking up stops under the back wall and under the raised gate at the same y, his shape's top on y -100
	stops.clear()
	for x: float in [8.0, 200.0]:
		player.position = Vector2(x, -66.0)
		await _hold(["ui_up"], 60)
		stops.append(player.position.y)
		_check(absf(player.position.y + 80.0) < 0.5, "the back wall and the raised gate stop the player at y -80 at x %.0f, got %.1f" % [x, player.position.y])
	_check(absf(stops[0] - stops[1]) < 0.01, "the back wall and the raised gate stop him at the same y, got %.3f and %.3f" % [stops[0], stops[1]])

	# and the walk along the corridor passes the door column with the gate raised
	await _walk_across(player, -66.0, "the gate raised")

	# through the door, up into the corridor behind the wall and out to the right of the arch
	player.position = Vector2(8.0, 16.0)
	await _hold(["ui_up"], 60)
	_check(player.position.y < -56.0, "the player walks up through the open gate, got %.1f" % player.position.y)
	await _hold(["ui_right"], 120)
	_check(player.position.x > 128.0 and player.position.y < -56.0, "the player ends in the corridor right of the door, got %s" % player.position)

	await _press("ui_accept")
	_check(animation_player.get_playing_speed() < 0.0, "the second press plays open backwards")
	await create_timer(1.3).timeout
	_check(gate.position.is_equal_approx(Vector2.ZERO) and _same(gate.modulate, CLOSED), "the gate slid back and turned orange, got %s" % gate.position)

	print("%s, %d failures" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

## From x -100 to x 200 along the corridor, one tick at a time: every tick moves on by speed / 60, nowhere does the player stop.
func _walk_across(player: CharacterBody2D, y: float, state: String) -> void:
	player.position = Vector2(-100.0, y)
	await physics_frame
	var slowest := 99.0
	Input.action_press("ui_right")
	for i in 240:
		var before := player.position.x
		await physics_frame
		if before < 195.0:
			slowest = minf(slowest, player.position.x - before)
	Input.action_release("ui_right")
	_check(player.position.x > 199.0, "the player walks the corridor from x -100 to x 200 with %s, got %.1f" % [state, player.position.x])
	_check(slowest > 1.4, "the player does not stop on the way along the corridor with %s, slowest tick %.2f px" % [state, slowest])

func _hold(actions: Array, ticks: int) -> void:
	for action: String in actions:
		Input.action_press(action)
	for i in ticks:
		await physics_frame
	for action: String in actions:
		Input.action_release(action)

func _press(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await physics_frame

func _same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.02 and absf(a.g - b.g) < 0.02 and absf(a.b - b.b) < 0.02

func _check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + text)
